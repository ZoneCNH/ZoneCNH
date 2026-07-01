# schedulex 设计方案

> Design ID: DESIGN-schedulex-v1
> Source Spec: [SPEC.md](./SPEC.md) v1.1.0
> Source Goal: [goal.md](./goal.md) 1.0 发布基线
> 生成日期：2026-06-29
> 状态：已发布（对齐运行时仓库 `/home/workspace/schedulex`）

## 1. 架构概述

`schedulex` 是统一任务调度运行时，负责在指定时间可靠触发任务，管理并发、错过执行和停机语义。支持 cron/interval/delay 三种触发方式，提供 overlap 和 misfire 策略，可选分布式锁。它解决"任务如何可靠被调度和观测"，不承载具体业务任务逻辑。

### 1.1 设计原则

1. **执行语义清晰**：默认 at-least-once，不承诺 exactly-once（业务侧自行实现幂等）。
2. **可注入时钟**：所有时间依赖通过 Clock 接口注入，支持测试确定性。
3. **策略可组合**：overlap/misfire/distributed lock 按 job 独立配置。
4. **优雅停机**：停止调度器时等待运行中任务完成（受 grace period 控制）。
5. **可观测内置**：job 生命周期事件通过 EventSink 暴露，由调用方注入 observex adapter。

### 1.2 与 goal.md 的版本映射

| 能力 | goal.md MUST | 运行时状态 |
|------|------------|----------|
| Scheduler + Job + Trigger + JobHandler 抽象 | ✅ MUST | ✅ 已交付 |
| cron 触发 | ✅ MUST | ✅ 已交付 |
| interval 触发 | ✅ MUST | ✅ 已交付 |
| delay (Once/DailyAt) 触发 | ✅ MUST | ✅ 已交付 |
| OverlapPolicy (Skip/QueueOne/Allow) | ✅ MUST | ✅ 已交付 |
| MisfirePolicy (Skip/RunOnce) | ✅ MUST | ✅ 已交付 |
| 可选分布式锁 (Locker) | ✅ MUST | ✅ 已交付 |
| EventSink (job 事件 hook) | ✅ MUST | ✅ 已交付 |
| 可注入时钟 | ✅ MUST | ✅ 已交付 |
| Job 状态 (pending/running/completed/failed/cancelled) | ✅ MUST | ✅ 已交付 |
| MisfirePolicy CatchUp | MAY | 🔜 推迟 |
| OverlapPolicy Replace | MAY | 🔜 推迟 |

## 2. 核心组件设计

### 2.1 Scheduler — 调度器

```go
type Scheduler struct { ... }
func New(opts ...SchedulerOption) *Scheduler
func (s *Scheduler) AddJob(job Job, trigger Trigger, opts ...JobOption) error
func (s *Scheduler) Start(ctx context.Context) error
func (s *Scheduler) Stop(ctx context.Context) error
```

- 单节点调度 + 可选分布式锁
- `Start` 后开始轮询，`Stop` 等待运行中 job 完成
- 所有 job 在 `Start` 前注册

### 2.2 Job — 任务定义

```go
type Job interface {
    Name() string
    Run(ctx context.Context) error
}
```

- `Name()` 返回唯一标识，重复注册返回 `ErrJobExists`
- `Run(ctx)` 接收调度器 context，支持取消传播
- 业务方实现 Job 接口，schedulex 不承载业务逻辑

### 2.3 Trigger — 触发器

```go
type Trigger struct {
    Cron     string        // cron 表达式
    Interval time.Duration // 固定间隔
    Once     time.Time     // 一次性触发
    DailyAt  string        // 每日固定时间（"09:30"）
}
```

- 支持 `timezone` 规则（通过 `JobOption` 指定 `*time.Location`）
- DST 切换：按 wall clock 触发

### 2.4 OverlapPolicy — 重叠策略

```go
type OverlapPolicy int
const (
    OverlapSkip    OverlapPolicy = iota // 跳过本次
    OverlapQueueOne                     // 至多排队一个
    OverlapAllow                        // 允许并发（默认）
)
```

- `Skip`：上次未完成 → 跳过，记录 misfire 事件
- `QueueOne`：上次未完成 → 排队一个（至多一个）
- `Allow`：允许并发执行（无保护）

### 2.5 MisfirePolicy — 错过策略

```go
type MisfirePolicy int
const (
    MisfireSkip    MisfirePolicy = iota // 跳过
    MisfireRunOnce                       // 补执行一次
)
```

- `Skip`：错过 → 等待下一个周期
- `RunOnce`：错过 → 立即补执行一次

### 2.6 Locker — 分布式锁

```go
type Locker interface {
    Lock(ctx context.Context, key string, ttl time.Duration) (Unlocker, error)
}
type Unlocker interface {
    Unlock(ctx context.Context) error
}
```

- 可选注入，不注入时单节点运行
- `key` 使用 `Job.Name()`
- 锁获取失败 → job 不执行（不报错，仅记录事件）

### 2.7 EventSink — 事件钩子

```go
type EventSink interface {
    OnJobStarted(ctx context.Context, job Job, trigger Trigger)
    OnJobCompleted(ctx context.Context, job Job, trigger Trigger, err error)
    OnJobSkipped(ctx context.Context, job Job, reason string)
    OnJobMisfired(ctx context.Context, job Job, reason string)
}
```

- 所有 job 生命周期事件通过 EventSink 暴露
- 调用方注入 observex adapter 实现日志/指标/追踪
- 默认 noop 实现

### 2.8 Clock — 可注入时钟

```go
type Clock interface {
    Now() time.Time
    NewTicker(d time.Duration) *time.Ticker
}
```

- 生产环境使用 `RealClock`
- 测试环境使用 `FakeClock`（来自 testkitx）
- 所有时间判断通过 Clock，不直接调用 `time.Now()`

## 3. 内部依赖图

```
schedulex/
├── scheduler.go       → 调度主循环
├── job.go             → Job interface
├── trigger.go         → Trigger + cron 解析
├── overlap.go         → OverlapPolicy
├── misfire.go         → MisfirePolicy
├── locker.go          → Locker interface
├── events.go          → EventSink interface
├── clock.go           → Clock interface
├── job_state.go       → JobStatus (pending/running/completed/failed/cancelled)
└── doc.go             → package doc
```

- 核心循环：`scheduler.run()` → 检查 Trigger → 检查 Locker → 检查 Overlap → 执行 Job → 发送 EventSink
- 所有时间判断通过 Clock interface
- EventSink 调用在 job goroutine 内

## 4. 关键架构决策（ADR）

### ADR-001: at-least-once 执行语义

**决策**：默认 at-least-once，不承诺 exactly-once。业务侧如需 exactly-once 需自行实现幂等。

**理由**：分布式场景下 exactly-once 需要两阶段提交或事务性 outbox，schedulex 作为调度库不应耦合存储方案；at-least-once + 业务幂等是成熟的分布式模式。

### ADR-002: 单节点调度 + 可选分布式锁

**决策**：调度器自身只管理单节点 job 队列，分布式互斥通过可选 Locker 接口实现。

**理由**：单节点部署不需要分布式锁依赖；多节点场景通过注入 Redis/etcd Locker 实现；关注点分离：调度逻辑与锁实现解耦。

### ADR-003: 可注入时钟

**决策**：所有时间判断通过 Clock interface，不直接调用 `time.Now()` 或 `time.NewTicker`。

**理由**：测试必须可复现（FakeClock 控制时间推进）；DST 和时区测试需要可控时钟；与其他 xlib 模块一致的设计模式。

### ADR-004: EventSink 异步不阻塞调度

**决策**：EventSink 调用在 job goroutine 内，不在调度主循环内。

**理由**：调度主循环不应被慢速 EventSink 阻塞；job goroutine 有独立 context 和超时保护。

### ADR-005: 静态注册

**决策**：`Start()` 后不允许动态 Add/Remove job。

**理由**：简化并发模型（不需要 job 列表的读写锁）；生产环境中调度配置在启动时确定。

## 5. 依赖关系

| 方向 | 模块 | 关系 |
|------|------|------|
| 消费 | kernel | 使用 kernel/contextx、kernel/timex.Clock |
| 被消费 | x.go | 创建 Scheduler，注册 job，调用 Start |
| 被消费 | observex | 通过 EventSink 注入观测 |
| 被消费 | resiliencx | 消费者在 Job.Run 内包装 timeout/retry |

## 6. 技术风险

| 风险 | 影响 | 缓解 |
|------|------|------|
| cron 解析精度 | 秒级调度不准 | cron 库支持秒级；Clock 注入确保测试覆盖 |
| goroutine 泄漏 | 内存泄漏 | Stop 有 grace period + force kill |
| 分布式锁死锁 | job 永久不执行 | Locker TTL 自动过期 |
| 高并发 job 竞争 | 调度延迟 | 每个 job 独立 goroutine + OverlapPolicy |

## 7. 设计约束

- **stdlib-only**：不引入第三方消息队列或工作流引擎
- **context 传播**：所有 job 通过 context 接收取消信号
- **panic 恢复**：job panic 不崩溃调度器
- **时区感知**：cron 支持 `CRON_TZ` 或 `JobOption` 指定时区

## 8. Mock 策略

### 8.1 单元测试

- 使用 FakeClock 控制时间推进
- 使用 FakeLocker 模拟锁获取/失败
- 使用 FakeEventSink 验证事件序列
- Table-driven test 覆盖所有 overlap/misfire 组合

### 8.2 集成测试

- 真实 cron ticker + FakeClock 控制时间
- 验证 job 执行时序和并发行为
- 优雅停机场景

## 9. 可扩展性与演进

### 9.1 v1.1+ 规划

- MisfirePolicy CatchUp（累积补执行）
- OverlapPolicy Replace（取消旧执行）
- Job 动态增删（运行时 Add/Remove）
- Job 依赖 DAG（job B 在 job A 完成后触发）

### 9.2 设计不阻塞的演进方向

- 分布式调度（多节点协调）
- 持久化 job 状态（外部存储）
- Web UI / admin API
