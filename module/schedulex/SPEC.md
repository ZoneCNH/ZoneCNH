# schedulex 规格

Status: Approved
- Spec-Version: v1.1.0
- Last-Updated: 2026-06-18
- Layer: L1 基础能力
- Version: v1.0.0
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`

> 公开投影 caveat：Status=Review 与矩阵覆盖证据不等同于 factory-grade；四源评分通过前机器事实层保持 factory=false。

---

## 1. 摘要

`schedulex` 是调度运行时，负责可靠地在指定时间触发任务，并管理并发、错过执行和停机语义。支持 cron/interval/delay 三种触发方式，提供 overlap 和 misfire 策略，可选分布式锁。

---

## 2. 问题与背景

量化交易系统有多种定时任务（行情拉取、因子计算、风控检查、报表生成），没有统一调度器会导致：

- 各模块自行使用 `time.Ticker`，时区处理不一致
- 任务错过执行（misfire）无策略，数据缺失
- 任务重叠执行（overlap）导致重复下单或数据竞争
- 优雅停机时任务未完成就被杀死
- 单节点和分布式部署的调度逻辑不统一

---

## 3. 目标

- 统一 cron / interval / delay 任务调度
- 明确的 overlap 策略：Skip / Queue / Replace
- 明确的 misfire 策略：Skip / RunOnce / CatchUp
- 支持 timezone 规则和 DST 切换
- 可选分布式锁，防止多实例重复执行
- 可注入时钟，支持测试确定性
- job event hook 用于可观测集成

---

## 4. 非目标

- 不负责业务为什么触发（不内置策略调仓、行情拉取等逻辑）
- 不替代 Kafka/NATS 等消息队列
- 不实现业务工作流
- 不决定策略何时调仓

---

## 5. 消费者

| 消费者           | 使用方式                             |
| ---------------- | ------------------------------------ |
| `x.go`（组合根） | 创建 Scheduler，注册 job，调用 Start |
| `market-data`    | 定时拉取行情数据                     |
| `factor-engine`  | 定时计算因子                         |
| `risk-engine`    | 定时执行风控检查                     |
| `report-engine`  | 定时生成报表                         |
| 业务域模块       | 通过 Scheduler.Schedule 注册定时任务 |

---

## 6. 功能需求

### FR-001: Schedule

WHEN 调用 `AddJob(job Job, trigger Trigger, opts ...JobOption)` 且 trigger 合法
THEN 注册 job，返回 nil（job 标识为 `Job.Name()`）

WHEN 调用 `AddJob(...)` 且 cron 语法错误 / trigger 不合法
THEN 返回 `ErrInvalidJob`

WHEN 调用 `AddJob(...)` 且 interval <= 0
THEN 返回 `ErrInvalidJob`

WHEN 调用 `AddJob(...)` 且 Job name 已存在
THEN 返回 `ErrJobExists`

> AC: AC-001, AC-002, AC-003, AC-004

### FR-002: Trigger

WHEN job 使用 cron 触发且到达调度时间
THEN 调用 `Job.Run(ctx)`

WHEN job 使用 interval 触发且间隔到期
THEN 调用 `Job.Run(ctx)`

WHEN job 设置 Delay 首次延迟
THEN 等待 Delay 后首次触发

> AC: AC-005, AC-006, AC-007
> 注：运行时无独立 `Delay` 字段（见 §8.2b），需用 `Once`/`DailyAt` 表达；AC-007 为 v1.1 缺口（§22 OQ-010 关联）。

### FR-003: Overlap Policy

WHEN OverlapPolicy = Skip 且上次执行未完成
THEN 跳过本次触发

WHEN OverlapPolicy = QueueOne 且上次执行未完成
THEN 至多排队一个，等上次完成后执行

WHEN OverlapPolicy = Replace 且上次执行未完成
THEN 取消旧的执行，启动新的

> AC: AC-008, AC-009, AC-010
> 注：运行时仅实现 Skip/QueueOne/Allow，无 `Allow` 之外的并发策略与 `Replace`（见 §22 OQ-006）；AC-010 (Replace) 为 v1.1 缺口。

### FR-004: Misfire Policy

WHEN MisfirePolicy = Skip 且触发被错过
THEN 跳过本次，等待下一个调度周期

WHEN MisfirePolicy = RunOnce 且触发被错过
THEN 补执行一次

WHEN MisfirePolicy = CatchUp 且触发被错过
THEN 补执行所有错过的次数

> AC: AC-011, AC-012, AC-013

### FR-005: Cancel

WHEN 调用 `Cancel(id)` 且 job 存在
THEN 取消 job，返回 nil

WHEN 调用 `Cancel(id)` 且 job 不存在
THEN 返回 `ErrJobNotFound`

> AC: AC-014, AC-015
> **运行时未实现**：v1.0.0 无 `Cancel` 方法（见 §8.1、§22 OQ-005）。AC-014/015 为 v1.1 缺口。

### FR-006: Stop

WHEN 调用 `Shutdown(ctx)`
THEN 等待正在执行的 job 完成，直到 ctx 超时

WHEN Shutdown 期间 job 超过 ctx deadline
THEN 强制取消，返回 `ctx.Err()`

> AC: AC-016, AC-017
> 注：运行时方法名为 `Shutdown`（非 `Stop`），超时返回 `ctx.Err()`，**无 `ErrShutdownTimeout`**（见 §22 OQ-007）。AC-017 (专属超时错误) 为 v1.1 缺口。

### FR-007: EventSink

WHEN job 触发、开始、完成、失败或 misfire
THEN 调用注册的 EventSink.OnEvent 回调（见 §8.4）

> AC: AC-018

### FR-008: Locker

WHEN 分布式锁获取成功
THEN 执行 job

WHEN 分布式锁获取失败
THEN 跳过本次执行，等待下一个调度周期

WHEN lock TTL < job 最大执行时间
THEN 返回配置错误

> AC: AC-019, AC-020, AC-021

### FR-009: Clock

WHEN 注入 StaticClock（NewStaticClock）
THEN 所有调度基于 StaticClock，不调用 time.Now（测试确定性）

> AC: AC-022

---

## 7. 行为约束

| 编号   | 规则                                                         | 违反后果                                       |
| ------ | ------------------------------------------------------------ | ---------------------------------------------- |
| BR-001 | Schedule 必须校验 trigger 合法性（cron 语法 / interval > 0） | 非法 trigger 被接受，运行时 panic 或行为不确定 |
| BR-002 | 同一 Job name 重复注册返回 ErrJobExists                       | 同名 job 被覆盖，旧任务丢失，调度混乱          |
| BR-003 | Stop 必须等待正在执行的 job 完成或超时                       | job 被强杀，数据不一致或资源泄漏               |
| BR-004 | overlap 行为由 OverlapPolicy 决定，不内置隐式策略            | 行为不可预测，不同部署表现不一致               |
| BR-005 | job panic 被 catch，不影响其他 job                           | panic 传播导致调度器崩溃，所有 job 停止        |
| BR-006 | lock TTL > job 最大执行时间，防止锁提前释放导致重复执行      | 锁提前释放，多实例重复执行                     |
| BR-007 | DST 切换时触发时间必须正确（不能跳过或重复触发）             | 触发时间偏移，任务提前/延迟/重复触发           |
| BR-008 | job handler 必须接受 context.Context，支持取消传播           | 无法取消，goroutine 泄漏，停机超时             |

---


### Acceptance Criteria Registry

| AC ID | FR/BR Ref | Criterion |
|-------|-----------|----------|
| AC-001 | FR-001 | 合法 job 经 AddJob 返回 nil |
| AC-002 | FR-001 | trigger 不合法 → ErrInvalidJob |
| AC-004 | FR-001 | 重复 Job name → ErrJobExists |
| AC-005 | FR-002 | cron 到达调度时间调用 Job.Run |
| AC-006 | FR-002 | interval 到期调用 Job.Run |
| AC-007 | FR-002 | Delay 后首次触发（v1.1 缺口） |
| AC-008 | FR-003 | Skip → 上次未完成时跳过 |
| AC-009 | FR-003 | QueueOne → 至多排队一个 |
| AC-010 | FR-003 | Replace → 取消旧的启动新的（v1.1 缺口） |
| AC-011 | FR-004 | Skip → 跳过错过的触发 |
| AC-012 | FR-004 | RunOnce → 补执行一次 |
| AC-013 | FR-004 | CatchUp → 补执行所有错过次数 |
| AC-014 | FR-005 | 存在的 job 取消返回 nil（v1.1 缺口） |
| AC-015 | FR-005 | 不存在返回错误（v1.1 缺口） |
| AC-016 | FR-006 | Shutdown 等待正在执行的 job 完成 |
| AC-017 | FR-006 | 超时返回 ctx.Err()（v1.1：专属 ErrShutdownTimeout） |
| AC-018 | FR-007 | scheduled/started/succeeded/failed/misfire 等事件输出到 EventSink |
| AC-019 | FR-008 | 锁获取成功 → 执行 job |
| AC-020 | FR-008 | 锁获取失败 → 跳过本次 |
| AC-022 | FR-009 | StaticClock 注入后调度基于 StaticClock |

## 8. 接口契约

### 8.1 Scheduler

```go
func NewScheduler(opts ...Option) (*Scheduler, error)

method (*Scheduler).AddJob(job Job, trigger Trigger, opts ...JobOption) error
method (*Scheduler).Start(ctx context.Context) error
method (*Scheduler).Shutdown(ctx context.Context) error
method (*Scheduler).Snapshot() Snapshot
```

- `Scheduler` 是具体类型（非 interface），由 `NewScheduler(opts ...Option)` 构造。
- 注册方法叫 `AddJob`，返回 `error`（**不**返回 `(JobID, error)`）。
- **无独立 `JobID` 类型**——job 标识用 `Job.Name()`。
- **无 `Cancel`、无 `List`**：单 job 取消未实现（见 §22 OQ-005）；查询用 `Snapshot()`；全局停机用 `Shutdown(ctx)`。
- `Stop` 实际名为 `Shutdown`，超时返回 `ctx.Err()`，**无 `ErrShutdownTimeout`**（见 §22 OQ-007）。

### 8.2 Job

```go
type Job interface {
    Name() string
    Run(context.Context) error
}

// JobFunc 是把普通函数适配为 Job 的便捷类型。
type JobFunc struct {
    NameValue string
    RunFunc   func(context.Context) error
}
func (j JobFunc) Name() string
func (j JobFunc) Run(ctx context.Context) error
```

- Job 是 **interface**（非 struct）。**无独立 `JobHandler` 类型**——执行函数即 `Job.Run`。
- 无 `ID / Trigger / Handler / Timeout / MaxRetries / Overlap / Misfire` 字段；这些通过 `AddJob(job, trigger, opts ...JobOption)` 参数与 `JobOption` 传入（见 §9）。

#### Policy 枚举（string，非 iota int）

```go
type OverlapPolicy string
const (
    OverlapSkip     OverlapPolicy = "skip"      // 上次未完成 → 跳过本次
    OverlapQueueOne OverlapPolicy = "queue_one" // 上次未完成 → 至多排队一个
    OverlapAllow    OverlapPolicy = "allow"     // 允许并发执行
)

type MisfirePolicy string
const (
    MisfireSkip    MisfirePolicy = "skip"     // 错过触发 → 跳过
    MisfireRunOnce MisfirePolicy = "run_once" // 错过触发 → 补执行一次
    MisfireCatchUp MisfirePolicy = "catch_up" // 错过触发 → 补执行所有错过的
)
```

- 策略载体是 **string**，不是 `int`/`iota`。
- Overlap 运行时只有 `Skip / QueueOne / Allow`；旧草案的 `Replace` **未实现**（见 §22 OQ-006）。
- `Queue` → `QueueOne`（最多排一个）；`Allow` = 允许并发。

### 8.2b Trigger

```go
type Trigger interface {
    Next(after time.Time) (time.Time, bool)
}

func Once(at time.Time) Trigger
func Every(d time.Duration, opts ...TriggerOption) Trigger
func DailyAt(hour, minute int, loc *time.Location, opts ...TriggerOption) Trigger
func Cron(expr string, loc *time.Location, opts ...TriggerOption) (Trigger, error)
```

- Trigger 是 **interface**（非 `struct{Cron string; Interval; Delay}`）。调度器通过 `Next(after)` 询问下一次触发时间，第二个返回值 `false` 表示无更多触发。
- 构造器覆盖三种触发模式：`Once`（一次性）、`Every`（固定间隔）、`DailyAt`（每日定时，带时区）、`Cron`（cron 表达式，带时区）。
- **Delay 首次延迟未实现**——用 `Once` 或 `DailyAt` 表达“首次延迟”语义（见 §22；对应旧 FR-002 Delay 缺口）。
- `Cron` 仅支持 **5 字段** 表达式；minute/hour 支持 `*`、`*/N`、固定整数；**day/month/week 必须为 `*`**。非法表达式返回 `error`。

### 8.3 JobStatus / Snapshot

```go
type Snapshot struct {
    Version string
    Now     time.Time
    Started, Running, Closed, Shutdown bool
    JobCount int
    Jobs     []JobSnapshot
}

type JobSnapshot struct {
    ID, Name       string
    Next           time.Time
    HasNext        bool
    MisfirePolicy  MisfirePolicy
    OverlapPolicy  OverlapPolicy
    Running, Queued bool
}
```

- 查询视图是 `Snapshot`（调度器级）/ `JobSnapshot`（单 job），通过 `Scheduler.Snapshot()` 获取，**替代旧 `List() []JobStatus`**。
- **无 `JobState` 枚举**（pending/running/completed/failed/cancelled）；**无 `RunCount / ErrorCount / LastError / LastRun`** 字段。
- 运行态只能从 `Running` / `Queued` 两个 bool 推断；历史执行统计未实现（见 §22 OQ-008）。查询能力弱于原草案。

### 8.4 EventSink

```go
type EventSink interface {
    OnEvent(context.Context, Event)
}
type EventSinkFunc func(context.Context, Event)
func (f EventSinkFunc) OnEvent(ctx context.Context, e Event)

type EventType string
const (
    EventScheduled   EventType = "scheduled"
    EventStarted     EventType = "started"
    EventSucceeded   EventType = "succeeded"
    EventFailed      EventType = "failed"
    EventSkipped     EventType = "skipped"
    EventShutdown    EventType = "shutdown"
    EventMisfire     EventType = "misfire"
    EventLockSkipped EventType = "lock_skipped"
    EventLockFailed  EventType = "lock_failed"
)

type Event struct {
    Type                                   EventType
    JobID, JobName                         string
    At, ScheduledAt, StartedAt, FinishedAt time.Time
    Lag, Duration                          time.Duration
    Attempt                                int
    Reason, Err                            string
    Attributes                             map[string]string
}
```

- EventSink 是 **interface**（非 `func(JobEventData)`）；`EventSinkFunc` 提供函数适配。
- EventType 共 **9 个**：基础生命周期 `scheduled/started/succeeded/failed/skipped`、系统 `shutdown`、misfire `misfire`、锁 `lock_skipped/lock_failed`。
- 旧草案的 `Triggered/Completed/Misfired` 在运行时分别对应 `Scheduled/Succeeded/Misfire`。
- EventSink 通过 `WithEventSink`（scheduler 级）或 `WithJobEventSink`（per-job）注入（见 §9）。

### 8.5 Locker

```go
type Locker interface {
    TryLock(ctx context.Context, key string, ttl time.Duration) (Lease, error)
}
type Lease interface {
    Release(ctx context.Context) error
}
```

- 锁 SPI 为 `TryLock(...) (Lease, error)`，成功返回 `Lease` 对象（由调用方 `Release(ctx)`），**非** `Acquire(...) (bool, error)` + `Release(ctx, key)`。
- 锁失败语义：
  - 返回 `ErrLockUnavailable` → emit `EventLockSkipped`（跳过本次，等下一周期）。
  - 返回其他 `error` → emit `EventLockFailed`。
- Locker 通过 per-job option `WithLocker` / `WithLockKey` / `WithLockTTL` 注入（见 §9）。

### 8.6 公共错误

```go
var (
    ErrSchedulerClosed = errors.New("schedulex: scheduler closed")
    ErrJobExists       = errors.New("schedulex: job already exists")
    ErrInvalidJob      = errors.New("schedulex: job name and trigger are required")
    ErrInvalidOption   = errors.New("schedulex: invalid option")
    ErrLockUnavailable = errors.New("schedulex: lock unavailable")
)
```

**下游迁移映射（旧 SPEC 名 → 运行时实际）：**

| 旧 SPEC 名 | 运行时实际 | 说明 |
| --- | --- | --- |
| `ErrDuplicateJob` | `ErrJobExists` | 重命名 |
| `ErrInvalidTrigger` | `ErrInvalidJob` | trigger/Job 校验合并 |
| `ErrJobNotFound` | **不存在** | 无 `Cancel`，无此错误（见 §22 OQ-005） |
| `ErrShutdownTimeout` | **不存在** | `Shutdown` 返回 `ctx.Err()`（见 §22 OQ-007） |
| `ErrLockAcquire` | `ErrLockUnavailable` | 重命名 |

---

## 9. 数据模型

### 9.1 配置方式（functional options）

运行时**无 `SchedulerConfig` struct、无 YAML 解析**。所有配置通过 functional options 传入 `NewScheduler` 与 `AddJob`。

```go
// Scheduler 级 Option
func WithClock(Clock) Option          // 注入时钟（测试确定性）
func WithEventSink(EventSink) Option  // 全局事件回调
func WithMaxConcurrent(int) Option    // 最大并发 job 数

// Per-job JobOption
func WithMisfirePolicy(MisfirePolicy) JobOption
func WithOverlapPolicy(OverlapPolicy) JobOption
func WithJitter(JitterPolicy) JobOption
func WithLocker(Locker) JobOption
func WithLockKey(string) JobOption
func WithLockTTL(time.Duration) JobOption
func WithJobEventSink(EventSink) JobOption

type JitterPolicy struct {
    Max  time.Duration
    Seed int64
}
```

- `Clock` 接口为可注入时钟（`NewRealClock` / `NewStaticClock`），`WithClock` 用于测试确定性。
- 锁相关 option（`WithLocker/WithLockKey/WithLockTTL`）对应 §8.5 Locker SPI。

---

## 10. 配置模式

> **运行时无 YAML 解析。** 下游编排若使用 YAML，仅为部署/组合层的约定，不由 schedulex 自身消费；schedulex 在代码层通过 functional options 构造。YAML→option 的桥接属 v1.1 路线（见 §22 OQ-010）。

```go
s, err := schedulex.NewScheduler(
    schedulex.WithClock(schedulex.NewRealClock()),
    schedulex.WithEventSink(schedulex.EventSinkFunc(mySink)),
    schedulex.WithMaxConcurrent(10),
)
if err != nil { /* ... */ }

trigger, err := schedulex.Cron("*/5 * * * *", time.UTC)
if err != nil { /* ... */ }

err = s.AddJob(
    schedulex.JobFunc{NameValue: "market-data", RunFunc: pullMarketData},
    trigger,
    schedulex.WithOverlapPolicy(schedulex.OverlapSkip),
    schedulex.WithMisfirePolicy(schedulex.MisfireRunOnce),
    schedulex.WithLocker(myRedisLocker),
    schedulex.WithLockKey("market-data"),
    schedulex.WithLockTTL(30*time.Second),
)
if err != nil { /* ... */ }

if err := s.Start(ctx); err != nil { /* ... */ }
defer s.Shutdown(ctx)
```

---

## 11. 错误处理

| 错误 | 调用方处理 |
| --- | --- |
| `ErrSchedulerClosed` | 调度器已停机，停止注册新 job / 不再 `Start` |
| `ErrJobExists` | job name 已注册（`AddJob` 幂等性拒绝），改名或先停机 |
| `ErrInvalidJob` | job name 或 trigger 为空 / trigger 不合法，检查 `Job.Name()` 与 trigger 构造 |
| `ErrInvalidOption` | functional option 参数非法（如负 MaxConcurrent），修正 option 入参 |
| `ErrLockUnavailable` | 分布式锁被占用（正常竞争），Locker 会 emit `lock_skipped`，等下一周期 |

**错误消息格式：** `"schedulex: <operation>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 12. 边界情况

| 场景                        | 预期行为                              |
| --------------------------- | ------------------------------------- |
| cron 表达式语法错误         | 返回 ErrInvalidJob（trigger 校验），不注册 job |
| interval = 0                | 返回 ErrInvalidJob                |
| DST 切换（春/秋）           | 触发时间正确，不跳过或重复            |
| job panic                   | catch panic，记录日志，不影响其他 job |
| 停机时 job 正在执行         | 等待完成或超时后 force cancel         |
| 分布式锁获取失败            | 跳过本次，等待下一个调度周期          |
| lock TTL < job 执行时间     | 返回配置错误（v1.1：运行时尚未校验）  |
| 0 个 job 注册后 Start       | 正常启动，等待 Shutdown              |
| 时区为 UTC+0 与本地时区差异 | 按构造器传入 loc 计算触发时间        |
| 并发 AddJob + Shutdown      | 需要加锁，保证并发安全                |

---

## 13. 目录结构

```text
schedulex/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── schedulex.go                # Scheduler / Job / JobID 顶层导出
├── errors.go
├── options.go
├── cron/
│   └── cron.go                 # cron 表达式解析
├── trigger/
│   └── trigger.go              # Trigger 构造和验证
├── overlap.go                  # OverlapPolicy 实现
├── misfire.go                  # MisfirePolicy 实现
├── lock/
│   ├── lock.go                 # Locker 接口
│   ├── redis/                  # Redis 实现
│   └── memory/                 # 单节点实现
├── event.go                    # JobEvent hook
├── clock.go                    # 可注入时钟（测试用）
├── internal/
│   ├── queue/                  # 调度队列
│   └── wheel/                  # 时间轮实现
├── testdata/
│   └── *.golden
├── example_test.go
├── benchmark_test.go
└── integration_test.go
```text

---

## 14. 依赖

### 14.1 go.mod

```text
module github.com/ZoneCNH/schedulex

go 1.23
```text

### 14.2 依赖方向

| 可以依赖                        | 禁止依赖            |
| ------------------------------- | ------------------- |
| kernel（L0 原语）               | configx             |
| observex（interface-only）      | testkitx（仅 test） |
| resiliencx（可选，job wrapper） | 所有业务域实现      |
| stdlib                          |                     |


---

## 15. AC 注册表

| 编号   | 描述                                    | 关联 FR   | 验证方式   |
| ------ | --------------------------------------- | --------- | ---------- |
| AC-001 | AddJob 注册合法 job 返回 nil            | FR-001    | TC-001     |
| AC-002 | trigger 不合法返回 ErrInvalidJob        | FR-001    | Unit       |
| AC-003 | interval <= 0 返回 ErrInvalidJob        | FR-001    | Unit       |
| AC-004 | 重复 Job name 返回 ErrJobExists         | FR-001    | TC-009     |
| AC-005 | cron 触发时调用 Job.Run                 | FR-002    | TC-001     |
| AC-006 | interval 触发时调用 Job.Run             | FR-002    | Unit       |
| AC-007 | Delay 首次延迟后触发（v1.1 缺口）       | FR-002    | Unit       |
| AC-008 | Overlap Skip 跳过本次触发               | FR-003    | TC-002     |
| AC-009 | Overlap QueueOne 至多排队一个           | FR-003    | Unit       |
| AC-010 | Overlap Replace 取消旧的执行新的（v1.1 缺口） | FR-003    | Unit       |
| AC-011 | Misfire Skip 跳过本次                   | FR-004    | Unit       |
| AC-012 | Misfire RunOnce 补执行一次              | FR-004    | TC-003     |
| AC-013 | Misfire CatchUp 补执行所有              | FR-004    | Unit       |
| AC-014 | Cancel 已存在 job 返回 nil（v1.1 缺口） | FR-005    | TC-005     |
| AC-015 | Cancel 不存在 job 返回错误（v1.1 缺口） | FR-005    | Unit       |
| AC-016 | Shutdown 等待正在执行的 job 完成        | FR-006    | TC-006     |
| AC-017 | Shutdown 超时返回 ctx.Err()（v1.1：专属 ErrShutdownTimeout） | FR-006    | Unit       |
| AC-018 | EventSink 收到生命周期事件              | FR-007    | TC-007     |
| AC-019 | 锁获取成功执行 job                      | FR-008    | Unit       |
| AC-020 | 锁获取失败跳过本次                      | FR-008    | TC-004     |
| AC-021 | lock TTL < job 最大执行时间返回配置错误（v1.1 缺口） | FR-008    | Unit       |
| AC-022 | StaticClock 注入后调度基于 StaticClock  | FR-009    | TC-008     |

---

## 16. 测试

### 16.1 单元测试

| 测试场景         | 验证点                              |
| ---------------- | ----------------------------------- |
| cron 触发        | `*/1 * * * *` → 每分钟触发          |
| interval 触发    | `Interval: 1s` → 每秒触发           |
| overlap skip     | 上次未完成 → 跳过本次               |
| overlap queue    | 上次未完成 → 排队等待               |
| overlap replace  | 上次未完成 → 取消旧的，执行新的     |
| misfire skip     | 错过触发 → 跳过                     |
| misfire run_once | 错过触发 → 补执行一次               |
| misfire catch_up | 错过触发 → 补执行所有               |
| 并发限制         | 超过 max_concurrency → 等待         |
| 停机等待         | `Stop` 等待正在执行的 job           |
| 停机超时         | job 超时 → force cancel             |
| job panic 隔离   | panic 被 catch → 不影响其他 job     |
| trigger 验证     | cron 语法错误 → `ErrInvalidJob`     |
| 重复注册         | 同一 Job name → `ErrJobExists`      |
| DST 切换         | 夏令时切换时触发时间正确            |
| 触发确定性       | 相同 StaticClock → 相同 next time   |
| event hook       | 事件正确输出到 EventSink            |

### 16.2 Given/When/Then 用例

**TC-001: 正常 cron 触发**
Given 注册 cron job `*/1 * * * *`
When StaticClock 推进到下一分钟
Then Job.Run 被调用一次

**TC-002: OverlapSkip 跳过**
Given OverlapPolicy = Skip，job 执行需 10s
When 第二次触发在 5s 时到来
Then 第二次触发被跳过

**TC-003: MisfireRunOnce 补执行**
Given MisfirePolicy = RunOnce，调度间隔 1s
When StaticClock 推进 5s（跳过 5 次触发）
Then 补执行 1 次

**TC-004: 分布式锁失败跳过**
Given Locker.TryLock 返回 ErrLockUnavailable
When 到达触发时间
Then 跳过本次执行，等待下一个调度周期

**TC-005: Cancel job（v1.1 缺口）**
Given 已注册 Job name `daily`
When 调用 Cancel("daily")
Then 后续触发周期不再执行该 job

**TC-006: Shutdown 等待与 panic 隔离**
Given job 正在执行且另一个 job panic
When 调用 Shutdown
Then panic 被捕获，Shutdown 等待运行中 job 结束或 ctx 超时

**TC-007: EventSink 输出**
Given 配置了 EventSink
When job 触发、成功或失败
Then EventSink 收到对应生命周期事件

**TC-008: Clock 与 DST**
Given StaticClock 位于 DST 切换边界
When 计算下一次触发时间
Then 结果符合目标时区的 cron 语义

**TC-009: 重复 Job name**
Given Job name `daily` 已注册
When 再次注册同名 job
Then 返回 ErrJobExists

### 16.3 Benchmark

| 场景             | 目标   |
| ---------------- | ------ |
| 1000 个 job 内存 | < 10MB |
| job 触发延迟     | < 10ms |

### 16.4 集成测试

| 场景                   | 验证点                                           |
| ---------------------- | ------------------------------------------------ |
| 分布式锁               | 锁获取失败 → skip                                |
| job 触发延迟           | < 10ms                                           |
| schedulex + resiliencx | job 失败 → retry → breaker open → 后续 fail-fast |

---

## 17. 性能预算

| 操作                   | 目标             | 测量方式         |
| ---------------------- | ---------------- | ---------------- |
| job 触发延迟           | < 10ms（单节点） | integration test |
| 1000 个 job 的内存占用 | < 10MB           | profiling        |
| 常驻内存               | < 5MB            | profiling        |

---

## 18. 可观测性

> **运行时现状（v1.0.0）：尚未内置 metrics 输出、结构化日志和 trace span。** 当前可观测能力完全通过 `EventSink` 回调（§8.4）暴露，下游可基于 Event 自行聚合 metrics/log/trace。下表为**规划目标**，实际 metrics/log/span 集成在 v1.1 路线（见 §22 OQ-009）。
>
> **NFR-O01 当前状态 = 缺口**：metrics/log/span 三类信号在运行时均未实现，仅 Event 回调可用。

| 类型   | 名称                      | 说明                                                   |
| ------ | ------------------------- | ------------------------------------------------------ |
| metric | `schedulex.job.triggered` | counter，job 触发次数，label: job_id                   |
| metric | `schedulex.job.duration`  | histogram，job 执行耗时，label: job_id                 |
| metric | `schedulex.job.errors`    | counter，job 执行失败次数，label: job_id, error_type   |
| metric | `schedulex.job.misfired`  | counter，misfire 次数，label: job_id, policy           |
| metric | `schedulex.job.running`   | gauge，当前正在执行的 job 数                           |
| metric | `schedulex.queue.size`    | gauge，等待执行的 job 数                               |
| log    | `schedulex.job.scheduled` | info，job 被注册，含 job_id + cron/interval + next_run |
| log    | `schedulex.job.started`   | info，job 开始执行                                     |
| log    | `schedulex.job.completed` | info，job 执行完成，含 duration                        |
| log    | `schedulex.job.failed`    | error，job 执行失败，含 error + job_id                 |
| log    | `schedulex.job.misfired`  | warn，job 发生 misfire，含 policy applied              |
| log    | `schedulex.job.skipped`   | info，job 因 overlap 被跳过                            |
| log    | `schedulex.lock.acquired` | debug，分布式锁获取成功                                |
| log    | `schedulex.lock.released` | debug，分布式锁释放                                    |
| span   | `schedulex.job`           | job 执行 span，attribute: job_id, trigger_type         |

---

## 19. 安全

| 要求                  | 实现方式                                                |
| --------------------- | ------------------------------------------------------- |
| distributed lock 安全 | lock TTL > job 最大执行时间，防止锁提前释放导致重复执行 |
| job 回调隔离          | job panic 不传播到调度器，不泄露内部堆栈到业务层        |

---

## 20. CI 门禁

### 20.1 通用 Gate

| Gate        | 命令                                                                                                               | 阻塞条件                 |
| ----------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------ |
| 编译        | `go build ./...`                                                                                                   | 编译失败                 |
| 测试        | `go test ./... -race -count=1`                                                                                     | 任何测试失败或 data race |
| 覆盖率      | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 < 80%           |
| vet         | `go vet ./...`                                                                                                     | 任何 vet 错误            |
| lint        | `golangci-lint run`                                                                                                | 任何 lint 错误           |
| 依赖检查    | `go mod tidy && git diff --exit-code go.mod go.sum`                                                                | go.mod 不整洁            |
| Secret 扫描 | `gitleaks detect --no-git`                                                                                         | 泄露 secret              |
| Benchmark   | `go test -bench=. -benchmem -count=3 ./...`                                                                        | 结果附在 PR comment      |

### 20.2 schedulex 专属 Gate

| Gate                | 命令                                        | 阻塞条件                   |
| ------------------- | ------------------------------------------- | -------------------------- |
| DST/timezone golden | `go test -run TestDST ./...`                | 时区切换行为不正确         |
| misfire contract    | `go test -run TestMisfireContract ./...`    | misfire 策略行为不符合规范 |
| overlap contract    | `go test -run TestOverlapContract ./...`    | overlap 策略行为不符合规范 |
| shutdown leak       | `go test -run TestShutdownLeak ./...`       | 停机后有 goroutine 泄漏    |
| shutdown race       | `go test -race -run TestShutdownRace ./...` | 停机过程有 data race       |

---

## 21. 发布 DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、配置说明、API 概览
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] DST/timezone golden 测试通过
- [ ] misfire contract 测试通过
- [ ] overlap contract 测试通过
- [ ] shutdown leak 测试通过
- [ ] shutdown race 测试通过
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更（或已 bump major）
- [ ] 所有 Functional Requirements 有对应测试
- [ ] 所有 Edge Cases 有对应测试

---

---

## 22. 待解决问题

### Non-blocking

| ID | 问题 | 状态 |
| --- | --- | --- |
| OQ-001 | 是否需要支持动态添加/移除 job（运行时 Schedule/Cancel）的并发安全保证级别？ | 待评估 |
| OQ-002 | 是否需要支持 job 优先级（高优先级 job 可抢占低优先级的执行槽）？ | 待评估 |
| OQ-003 | 分布式锁是否需要支持 Redis 以外的后端（PostgreSQL Advisory Lock）？ | 待评估 |
| OQ-004 | misfire CatchUp 策略是否有上限（最多补执行 N 次）？ | 待评估 |
| OQ-005 | `Cancel(id)` 单 job 取消 API（FR-005 缺失，运行时无单 job 取消，仅全局 `Shutdown`） | v1.1 候选 |
| OQ-006 | `OverlapPolicy = Replace` 策略（FR-003 第三策略，运行时仅 Skip/QueueOne/Allow） | v1.1 候选 |
| OQ-007 | `ErrShutdownTimeout` 专属停机超时错误（运行时 `Shutdown` 返回 `ctx.Err()`） | v1.1 候选 |
| OQ-008 | `JobState` 枚举与 `RunCount/ErrorCount/LastError` 完整 JobStatus（运行时仅 Snapshot） | v1.1 候选 |
| OQ-009 | metrics（含 log/trace）集成（§18 规划目标，运行时仅 EventSink 回调） | v1.1 候选 |
| OQ-010 | YAML `SchedulerConfig` 与运行时 functional option 桥接（运行时无 YAML 解析） | v1.1 候选 |


## 23. 变更历史

| 日期       | 版本   | 变更内容   | 作者    |
| ---------- | ------ | ---------- | ------- |
| 2026-06-07 | v1.0.0 | 初始版本   | ZoneCNH |
| 2026-06-18 | v1.0.1 | 接口契约章节（§8–§11、§18、§22）反向对齐运行时 v1.0.0 canonical API | Agent A |

---

## Appendix A: Upgrade Compatibility

| 变更类型                           | 版本升级              |
| ---------------------------------- | --------------------- |
| Scheduler / Job interface 变更     | **major**             |
| OverlapPolicy / MisfirePolicy 变更 | **major**             |
| 新增可选配置字段                   | patch / minor         |
| 新增必填配置字段                   | **minor**（带默认值） |
| 修复 bug                           | **patch**             |