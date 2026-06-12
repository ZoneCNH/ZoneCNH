# schedulex 完整规格

> Foundation L1 运行时调度。cron/interval/delay job、misfire、overlap、jitter、并发控制和优雅停机。

最后更新：2026-06-07

---

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-07
- Owner: ZoneCNH
- Layer: L1 基础能力
- Version: v0.7.3
- Repository: [github.com/ZoneCNH/schedulex](https://github.com/ZoneCNH/schedulex)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |

## 2. Summary

`schedulex` 是调度运行时，负责可靠地在指定时间触发任务，并管理并发、错过执行和停机语义。支持 cron/interval/delay 三种触发方式，提供 overlap 和 misfire 策略，可选分布式锁。

---

## 3. Problem

量化交易系统有多种定时任务（行情拉取、因子计算、风控检查、报表生成），没有统一调度器会导致：

- 各模块自行使用 `time.Ticker`，时区处理不一致
- 任务错过执行（misfire）无策略，数据缺失
- 任务重叠执行（overlap）导致重复下单或数据竞争
- 优雅停机时任务未完成就被杀死
- 单节点和分布式部署的调度逻辑不统一

---

## 4. Goals

- 统一 cron / interval / delay 任务调度
- 明确的 overlap 策略：Skip / Queue / Replace
- 明确的 misfire 策略：Skip / RunOnce / CatchUp
- 支持 timezone 规则和 DST 切换
- 可选分布式锁，防止多实例重复执行
- 可注入时钟，支持测试确定性
- job event hook 用于可观测集成

---

## 5. Non-goals

- 不负责业务为什么触发（不内置策略调仓、行情拉取等逻辑）
- 不替代 Kafka/NATS 等消息队列
- 不实现业务工作流
- 不决定策略何时调仓

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| `x.go`（组合根） | 创建 Scheduler，注册 job，调用 Start |
| `market-data` | 定时拉取行情数据 |
| `factor-engine` | 定时计算因子 |
| `risk-engine` | 定时执行风控检查 |
| `report-engine` | 定时生成报表 |
| 业务域模块 | 通过 Scheduler.Schedule 注册定时任务 |

---

## 7. Functional Requirements

### FR-001: Schedule

WHEN 调用 `Schedule(job Job)` 且 trigger 合法
THEN 注册 job，返回 JobID

WHEN 调用 `Schedule(job Job)` 且 cron 语法错误
THEN 返回 `ErrInvalidTrigger`

WHEN 调用 `Schedule(job Job)` 且 interval <= 0
THEN 返回 `ErrInvalidTrigger`

WHEN 调用 `Schedule(job Job)` 且 JobID 已存在
THEN 返回 `ErrDuplicateJob`

> AC: AC-001, AC-002, AC-003, AC-004

### FR-002: Trigger

WHEN job 使用 cron 触发且到达调度时间
THEN 调用 JobHandler

WHEN job 使用 interval 触发且间隔到期
THEN 调用 JobHandler

WHEN job 设置 Delay 首次延迟
THEN 等待 Delay 后首次触发

> AC: AC-005, AC-006, AC-007

### FR-003: Overlap Policy

WHEN OverlapPolicy = Skip 且上次执行未完成
THEN 跳过本次触发

WHEN OverlapPolicy = Queue 且上次执行未完成
THEN 排队等待上次完成后执行

WHEN OverlapPolicy = Replace 且上次执行未完成
THEN 取消旧的执行，启动新的

> AC: AC-008, AC-009, AC-010

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

### FR-006: Stop

WHEN 调用 `Stop(ctx)`
THEN 等待正在执行的 job 完成或超时

WHEN Stop 期间 job 超过 deadline
THEN 强制取消，返回 `ErrShutdownTimeout`

> AC: AC-016, AC-017

### FR-007: EventSink

WHEN job 触发、开始、完成、失败或 misfire
THEN 调用注册的 JobEvent 回调

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

WHEN 注入 FakeClock
THEN 所有调度基于 FakeClock，不调用 time.Now（测试确定性）

> AC: AC-022

---

## 8. Business Rules

| 编号 | 规则 | 违反后果 |
|------|------|----------|
| BR-001 | Schedule 必须校验 trigger 合法性（cron 语法 / interval > 0） | 非法 trigger 被接受，运行时 panic 或行为不确定 |
| BR-002 | 同一 JobID 重复注册返回 ErrDuplicateJob | 同名 job 被覆盖，旧任务丢失，调度混乱 |
| BR-003 | Stop 必须等待正在执行的 job 完成或超时 | job 被强杀，数据不一致或资源泄漏 |
| BR-004 | overlap 行为由 OverlapPolicy 决定，不内置隐式策略 | 行为不可预测，不同部署表现不一致 |
| BR-005 | job panic 被 catch，不影响其他 job | panic 传播导致调度器崩溃，所有 job 停止 |
| BR-006 | lock TTL > job 最大执行时间，防止锁提前释放导致重复执行 | 锁提前释放，多实例重复执行 |
| BR-007 | DST 切换时触发时间必须正确（不能跳过或重复触发） | 触发时间偏移，任务提前/延迟/重复触发 |
| BR-008 | job handler 必须接受 context.Context，支持取消传播 | 无法取消，goroutine 泄漏，停机超时 |

---

## 9. Interface Contract

### 9.1 Scheduler

```go
type Scheduler interface {
    Schedule(job Job) (JobID, error)
    Cancel(id JobID) error
    List() []JobStatus
    Start(ctx context.Context) error
    Stop(ctx context.Context) error
}

type JobID string
```text

### 9.2 Job

```go
type Job struct {
    ID         JobID
    Name       string
    Trigger    Trigger
    Handler    JobHandler
    Timeout    time.Duration
    MaxRetries int
    Overlap    OverlapPolicy
    Misfire    MisfirePolicy
}

type JobHandler func(ctx context.Context) error

type Trigger struct {
    Cron     string        // cron 表达式（与 Interval 二选一）
    Interval time.Duration // 固定间隔
    Delay    time.Duration // 首次延迟
}

type OverlapPolicy int
const (
    OverlapSkip    OverlapPolicy = iota // 上次未完成 → 跳过本次
    OverlapQueue                        // 上次未完成 → 排队等待
    OverlapReplace                      // 上次未完成 → 取消旧的，执行新的
)

type MisfirePolicy int
const (
    MisfireSkip    MisfirePolicy = iota // 错过触发 → 跳过
    MisfireRunOnce                      // 错过触发 → 补执行一次
    MisfireCatchUp                      // 错过触发 → 补执行所有错过的
)
```text

### 9.3 JobStatus

```go
type JobStatus struct {
    ID         JobID
    Name       string
    State      JobState
    LastRun    time.Time
    NextRun    time.Time
    RunCount   int64
    ErrorCount int64
    LastError  string
}

type JobState int
const (
    JobPending   JobState = iota
    JobRunning
    JobCompleted
    JobFailed
    JobCancelled
)
```text

### 9.4 EventSink

```go
type JobEvent func(event JobEventData)

type JobEventData struct {
    ID        JobID
    Type      JobEventType
    Timestamp time.Time
    Duration  time.Duration
    Error     error
}

type JobEventType int
const (
    EventTriggered  JobEventType = iota
    EventStarted
    EventCompleted
    EventFailed
    EventMisfired
    EventSkipped
)
```text

### 9.5 Locker

```go
type Locker interface {
    Acquire(ctx context.Context, key string, ttl time.Duration) (bool, error)
    Release(ctx context.Context, key string) error
}
```text

### 9.6 公共错误

```go
var (
    ErrDuplicateJob    = errors.New("schedulex: duplicate job ID")
    ErrInvalidTrigger  = errors.New("schedulex: invalid trigger")
    ErrJobNotFound     = errors.New("schedulex: job not found")
    ErrShutdownTimeout = errors.New("schedulex: shutdown timeout")
    ErrLockAcquire     = errors.New("schedulex: lock acquire failed")
)
```text

---

## 10. Data Model

### 10.1 配置结构

```go
type SchedulerConfig struct {
    Timezone        string        `yaml:"timezone"`
    OverlapPolicy   OverlapPolicy `yaml:"overlap_policy"`
    MisfirePolicy   MisfirePolicy `yaml:"misfire_policy"`
    MaxConcurrency  int           `yaml:"max_concurrency"`
    DefaultTimeout  time.Duration `yaml:"default_timeout"`
    ShutdownTimeout time.Duration `yaml:"shutdown_timeout"`
}
```text

---

## 11. Config Schema

```yaml
schedulex:
  timezone: UTC
  overlap_policy: skip        # skip / queue / replace
  misfire_policy: skip        # skip / run_once / catch_up
  max_concurrency: 10
  default_timeout: 5m
  shutdown_timeout: 30s
  distributed_lock:
    enabled: false
    backend: redis             # redis / postgres
    ttl: 30s
  jitter:
    enabled: true
    max: 5s
```text

---

## 12. Error Handling

| 错误 | 调用方处理 |
|------|-----------|
| `ErrDuplicateJob` | 检查 JobID 是否重复，使用不同 ID |
| `ErrInvalidTrigger` | 检查 cron 语法或 interval 值 |
| `ErrJobNotFound` | 检查 JobID 拼写，确认 job 已注册 |
| `ErrShutdownTimeout` | 增加 shutdown_timeout 或检查 job 是否阻塞 |
| `ErrLockAcquire` | 检查锁后端连通性，等待下一个调度周期 |

**错误消息格式：** `"schedulex: <operation>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| cron 表达式语法错误 | 返回 ErrInvalidTrigger，不注册 job |
| interval = 0 | 返回 ErrInvalidTrigger |
| DST 切换（春/秋） | 触发时间正确，不跳过或重复 |
| job panic | catch panic，记录日志，不影响其他 job |
| 停机时 job 正在执行 | 等待完成或超时后 force cancel |
| 分布式锁获取失败 | 跳过本次，等待下一个调度周期 |
| lock TTL < job 执行时间 | 返回配置错误 |
| 0 个 job 注册后 Start | 正常启动，等待 Stop |
| 时区为 UTC+0 与本地时区差异 | 按配置时区计算触发时间 |
| 并发 Schedule + Cancel | 需要加锁，保证并发安全 |

---

## 14. Directory Structure

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

## 15. Dependencies

### 15.1 go.mod

```text
module github.com/ZoneCNH/schedulex

go 1.23
```text

### 15.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| kernel（L0 原语） | configx |
| observex（interface-only） | testkitx（仅 test） |
| resiliencx（可选，job wrapper） | 所有业务域实现 |
| stdlib | |


---

## 16. Acceptance Criteria Registry

| 编号 | 描述 | 关联 FR | 验证方式 |
|------|------|---------|----------|
| AC-001 | Schedule 注册合法 job 返回 JobID | FR-001 | TC-001 |
| AC-002 | cron 语法错误返回 ErrInvalidTrigger | FR-001 | Unit |
| AC-003 | interval <= 0 返回 ErrInvalidTrigger | FR-001 | Unit |
| AC-004 | 重复 JobID 返回 ErrDuplicateJob | FR-001 | TC-009 |
| AC-005 | cron 触发时调用 JobHandler | FR-002 | TC-001 |
| AC-006 | interval 触发时调用 JobHandler | FR-002 | Unit |
| AC-007 | Delay 首次延迟后触发 | FR-002 | Unit |
| AC-008 | Overlap Skip 跳过本次触发 | FR-003 | TC-002 |
| AC-009 | Overlap Queue 排队等待 | FR-003 | Unit |
| AC-010 | Overlap Replace 取消旧的执行新的 | FR-003 | Unit |
| AC-011 | Misfire Skip 跳过本次 | FR-004 | Unit |
| AC-012 | Misfire RunOnce 补执行一次 | FR-004 | TC-003 |
| AC-013 | Misfire CatchUp 补执行所有 | FR-004 | Unit |
| AC-014 | Cancel 已存在 job 返回 nil | FR-005 | TC-005 |
| AC-015 | Cancel 不存在 job 返回 ErrJobNotFound | FR-005 | Unit |
| AC-016 | Stop 等待正在执行的 job 完成或超时 | FR-006 | TC-006 |
| AC-017 | Stop 超时返回 ErrShutdownTimeout | FR-006 | Unit |
| AC-018 | EventSink 收到生命周期事件 | FR-007 | TC-007 |
| AC-019 | 锁获取成功执行 job | FR-008 | Unit |
| AC-020 | 锁获取失败跳过本次 | FR-008 | TC-004 |
| AC-021 | lock TTL < job 最大执行时间返回配置错误 | FR-008 | Unit |
| AC-022 | FakeClock 注入后调度基于 FakeClock | FR-009 | TC-008 |

---

## 17. Testing

### 18.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| cron 触发 | `*/1 * * * *` → 每分钟触发 |
| interval 触发 | `Interval: 1s` → 每秒触发 |
| overlap skip | 上次未完成 → 跳过本次 |
| overlap queue | 上次未完成 → 排队等待 |
| overlap replace | 上次未完成 → 取消旧的，执行新的 |
| misfire skip | 错过触发 → 跳过 |
| misfire run_once | 错过触发 → 补执行一次 |
| misfire catch_up | 错过触发 → 补执行所有 |
| 并发限制 | 超过 max_concurrency → 等待 |
| 停机等待 | `Stop` 等待正在执行的 job |
| 停机超时 | job 超时 → force cancel |
| job panic 隔离 | panic 被 catch → 不影响其他 job |
| trigger 验证 | cron 语法错误 → `ErrInvalidTrigger` |
| 重复注册 | 同一 JobID → `ErrDuplicateJob` |
| DST 切换 | 夏令时切换时触发时间正确 |
| 触发确定性 | 相同 FakeClock → 相同 next time |
| event hook | 事件正确输出到 hook |

### 17.2 Given/When/Then 用例

**TC-001: 正常 cron 触发**
Given 注册 cron job `*/1 * * * *`
When FakeClock 推进到下一分钟
Then JobHandler 被调用一次

**TC-002: OverlapSkip 跳过**
Given OverlapPolicy = Skip，job 执行需 10s
When 第二次触发在 5s 时到来
Then 第二次触发被跳过

**TC-003: MisfireRunOnce 补执行**
Given MisfirePolicy = RunOnce，调度间隔 1s
When FakeClock 推进 5s（跳过 5 次触发）
Then 补执行 1 次

**TC-004: 分布式锁失败跳过**
Given Locker.Acquire 返回 false
When 到达触发时间
Then 跳过本次执行，等待下一个调度周期

**TC-005: Cancel job**
Given 已注册 JobID `daily`
When 调用 Cancel("daily")
Then 后续触发周期不再执行该 job

**TC-006: Stop 等待与 panic 隔离**
Given job 正在执行且另一个 job panic
When 调用 Stop
Then panic 被捕获，Stop 等待运行中 job 结束或超时

**TC-007: EventSink 输出**
Given 配置了 EventSink
When job 触发、成功或失败
Then EventSink 收到对应生命周期事件

**TC-008: Clock 与 DST**
Given FakeClock 位于 DST 切换边界
When 计算下一次触发时间
Then 结果符合目标时区的 cron 语义

**TC-009: 重复 JobID**
Given JobID `daily` 已注册
When 再次注册同名 job
Then 返回 ErrDuplicateJob

### 17.3 Benchmark

| 场景 | 目标 |
|------|------|
| 1000 个 job 内存 | < 10MB |
| job 触发延迟 | < 10ms |

### 17.4 集成测试

| 场景 | 验证点 |
|------|--------|
| 分布式锁 | 锁获取失败 → skip |
| job 触发延迟 | < 10ms |
| schedulex + resiliencx | job 失败 → retry → breaker open → 后续 fail-fast |

---

## 18. Performance Budget

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| job 触发延迟 | < 10ms（单节点） | integration test |
| 1000 个 job 的内存占用 | < 10MB | profiling |
| 常驻内存 | < 5MB | profiling |

---

## 19. Observability

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `schedulex.job.triggered` | counter，job 触发次数，label: job_id |
| metric | `schedulex.job.duration` | histogram，job 执行耗时，label: job_id |
| metric | `schedulex.job.errors` | counter，job 执行失败次数，label: job_id, error_type |
| metric | `schedulex.job.misfired` | counter，misfire 次数，label: job_id, policy |
| metric | `schedulex.job.running` | gauge，当前正在执行的 job 数 |
| metric | `schedulex.queue.size` | gauge，等待执行的 job 数 |
| log | `schedulex.job.scheduled` | info，job 被注册，含 job_id + cron/interval + next_run |
| log | `schedulex.job.started` | info，job 开始执行 |
| log | `schedulex.job.completed` | info，job 执行完成，含 duration |
| log | `schedulex.job.failed` | error，job 执行失败，含 error + job_id |
| log | `schedulex.job.misfired` | warn，job 发生 misfire，含 policy applied |
| log | `schedulex.job.skipped` | info，job 因 overlap 被跳过 |
| log | `schedulex.lock.acquired` | debug，分布式锁获取成功 |
| log | `schedulex.lock.released` | debug，分布式锁释放 |
| span | `schedulex.job` | job 执行 span，attribute: job_id, trigger_type |

---

## 20. Security

| 要求 | 实现方式 |
|------|----------|
| distributed lock 安全 | lock TTL > job 最大执行时间，防止锁提前释放导致重复执行 |
| job 回调隔离 | job panic 不传播到调度器，不泄露内部堆栈到业务层 |

---

## 21. CI Gate

### 21.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 < 80% |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment |

### 21.2 schedulex 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| DST/timezone golden | `go test -run TestDST ./...` | 时区切换行为不正确 |
| misfire contract | `go test -run TestMisfireContract ./...` | misfire 策略行为不符合规范 |
| overlap contract | `go test -run TestOverlapContract ./...` | overlap 策略行为不符合规范 |
| shutdown leak | `go test -run TestShutdownLeak ./...` | 停机后有 goroutine 泄漏 |
| shutdown race | `go test -race -run TestShutdownRace ./...` | 停机过程有 data race |

---

## 22. Upgrade Compatibility

| 变更类型 | 版本升级 |
|----------|----------|
| Scheduler / Job interface 变更 | **major** |
| OverlapPolicy / MisfirePolicy 变更 | **major** |
| 新增可选配置字段 | patch / minor |
| 新增必填配置字段 | **minor**（带默认值） |
| 修复 bug | **patch** |

---

## 23. Release DoD

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

## 24. Open Questions

- 是否需要支持动态添加/移除 job（运行时 Schedule/Cancel）的并发安全保证级别？
- 是否需要支持 job 优先级（高优先级 job 可抢占低优先级的执行槽）？
- 分布式锁是否需要支持 Redis 以外的后端（PostgreSQL Advisory Lock）？
- misfire CatchUp 策略是否有上限（最多补执行 N 次）？
