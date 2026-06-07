# schedulex 完整规格

> Foundation L1 运行时调度。cron/interval/delay job、misfire、overlap、jitter、并发控制和优雅停机。

最后更新：2026-06-07

---

## 1. 定位

`schedulex` 是调度运行时，负责可靠地在指定时间触发任务，并管理并发、错过执行和停机语义。

### 核心职责

- cron / interval / delay job
- timezone 规则
- jitter
- overlap policy（Skip / Queue / Replace）
- misfire policy（Skip / RunOnce / CatchUp）
- max concurrency
- graceful shutdown
- distributed lock 可选适配
- job event hook
- 与 `observex` 和 `resiliencx` 集成

### 明确不做

- 不负责业务为什么触发
- 不应内置策略调仓、行情拉取或订单逻辑
- 不替代 Kafka/NATS 等消息队列
- 不实现业务工作流
- 不决定策略何时调仓

---

## 2. 接口契约

### 2.1 Scheduler

```go
type Scheduler interface {
    Schedule(job Job) (JobID, error)
    Cancel(id JobID) error
    List() []JobStatus
    Start(ctx context.Context) error
    Stop(ctx context.Context) error
}

type JobID string
```

### 2.2 Job

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
```

### 2.3 JobStatus

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
```

### 2.4 事件 Hook

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
```

### 2.5 Locker（分布式锁）

```go
type Locker interface {
    Acquire(ctx context.Context, key string, ttl time.Duration) (bool, error)
    Release(ctx context.Context, key string) error
}
```

### 2.6 契约约束

- `Schedule` 必须校验 trigger 合法性（cron 语法 / interval > 0）
- 同一 `JobID` 重复注册返回 `ErrDuplicateJob`
- `Stop` 必须等待正在执行的 job 完成或超时
- overlap 行为由 `OverlapPolicy` 决定，不内置隐式策略
- job panic 被 catch → 不影响其他 job
- lock TTL > job 最大执行时间，防止锁提前释放导致重复执行

### 2.7 公共错误

```go
var (
    ErrDuplicateJob    = errors.New("schedulex: duplicate job ID")
    ErrInvalidTrigger  = errors.New("schedulex: invalid trigger")
    ErrJobNotFound     = errors.New("schedulex: job not found")
    ErrShutdownTimeout = errors.New("schedulex: shutdown timeout")
    ErrLockAcquire     = errors.New("schedulex: lock acquire failed")
)
```

---

## 3. 目录结构

```
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
```

---

## 4. 依赖

### 4.1 go.mod

```
module github.com/ZoneCNH/schedulex

go 1.23
```

### 4.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| kernel（L0 原语） | configx |
| observex（interface-only） | |
| resiliencx（可选，job wrapper） | testkitx（仅 test） |
| stdlib | 所有业务域实现 |

---

## 5. CI Gate

### 5.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `go test ./... -coverprofile=cover.out && go tool cover -func=cover.out` | 总覆盖率 < 80% |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment |

### 5.2 schedulex 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| DST/timezone golden | `go test -run TestDST ./...` | 时区切换行为不正确 |
| misfire contract | `go test -run TestMisfireContract ./...` | misfire 策略行为不符合规范 |
| overlap contract | `go test -run TestOverlapContract ./...` | overlap 策略行为不符合规范 |
| shutdown leak | `go test -run TestShutdownLeak ./...` | 停机后有 goroutine 泄漏 |
| shutdown race | `go test -race -run TestShutdownRace ./...` | 停机过程有 data race |

---

## 6. 测试矩阵

### 6.1 单元测试

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
| 触发确定性 | 相同 clock → 相同 next time |
| event hook | 事件正确输出到 hook |

### 6.2 集成测试

| 场景 | 验证点 |
|------|--------|
| 分布式锁 | 锁获取失败 → skip |
| job 触发延迟 | < 10ms |
| schedulex + resiliencx | job 失败 → retry → breaker open → 后续 fail-fast |

### 6.3 Benchmark

| 场景 | 目标 |
|------|------|
| 1000 个 job 内存 | < 10MB |
| job 触发延迟 | < 10ms |

---

## 7. 性能预算

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| job 触发延迟 | < 10ms（单节点） | integration test |
| 1000 个 job 的内存占用 | < 10MB | profiling |
| 常驻内存 | < 5MB | profiling |

---

## 8. 可观测输出

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

## 9. 故障模式

| 故障场景 | 降级行为 | 是否阻塞启动 |
|----------|----------|--------------|
| job 执行 panic | **隔离 + 记录**：catch panic，记录 job ID 和堆栈，不影响其他 job | 否 |
| misfire | **按策略处理**：skip / run once / catch up，由配置决定 | 否 |
| 分布式锁获取失败 | **skip 本次执行**：记录日志，等待下一个调度周期 | 否 |
| 停机超时 | **force cancel**：超过 deadline 后强制取消正在执行的 job | 否（运行时） |

---

## 10. 安全要求

| 要求 | 实现方式 |
|------|----------|
| distributed lock 安全 | lock TTL > job 最大执行时间，防止锁提前释放导致重复执行 |
| job 回调隔离 | job panic 不传播到调度器，不泄露内部堆栈到业务层 |

---

## 11. 配置 schema

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
```

---

## 12. 升级兼容

| 变更类型 | 版本升级 |
|----------|----------|
| Scheduler / Job interface 变更 | **major** |
| OverlapPolicy / MisfirePolicy 变更 | **major** |
| 新增可选配置字段 | patch / minor |
| 新增必填配置字段 | **minor**（带默认值） |
| 修复 bug | **patch** |

---

## 13. 发布 DoD

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
