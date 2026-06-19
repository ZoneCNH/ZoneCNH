# schedulex

## 1. 模块定位
schedulex 是 FoundationX 调度运行时（L1 调度基座），负责可靠地在指定时间触发任务，管理并发（overlap）、错过执行（misfire）和停机（shutdown）语义。支持 Once / Every / Cron（5-field）/ DailyAt 四种触发方式，提供 overlap 和 misfire 策略，可选分布式锁。当前 Spec-Version v1.0.1、Module-Version v1.0.0（本地发布验收通过，score=10.0）。

## 2. 生产职责
- FR-001 Schedule：`AddJob(job, trigger, opts...)` 注册 job，job 标识为 Job.Name()
- FR-002 Trigger：Once / Every / Cron / DailyAt，支持 WithTriggerStartAt / WithTriggerEndAt
- FR-003 Overlap Policy：Skip / QueueOne / Allow（Replace 为 v1.1 缺口）
- FR-004 Misfire Policy：Skip / RunOnce / CatchUp
- FR-005 Cancel：**v1.0.0 未实现**（仅 Shutdown 全局停机，v1.1 候选）
- FR-006 Stop：`Shutdown(ctx)` 等待运行中 job 或 ctx 超时
- FR-007 EventSink：scheduled/started/succeeded/failed/skipped/shutdown/misfire/lock_skipped/lock_failed 九类事件
- FR-008 Locker：TryLock(...) (Lease, error) 接口，锁失败 emit lock_skipped
- FR-009 Clock：可注入时钟（NewRealClock / NewStaticClock），测试确定性

## 3. 边界定义
- BR-001：Schedule 必须校验 trigger 合法性（cron 语法 / interval > 0）
- BR-002：同一 Job name 重复注册返回 ErrJobExists
- BR-003：Shutdown 必须等待正在执行的 job 完成或超时
- BR-004：overlap 行为由 OverlapPolicy 决定，不内置隐式策略
- BR-005：job panic 被 catch，不影响其他 job
- BR-006：lock TTL > job 最大执行时间，防止锁提前释放导致重复执行
- BR-007：DST 切换时触发时间必须正确（不跳过或重复触发）
- BR-008：job handler 必须接受 context.Context，支持取消传播

## 4. 不负责什么
- 不负责业务为什么触发（不内置策略调仓、行情拉取等逻辑）
- 不替代 Kafka/NATS 等消息队列
- 不实现业务工作流
- 不决定策略何时调仓
- v1.0.0 不提供单 job Cancel / List / Stop（用 Shutdown + Snapshot 替代）
- v1.0.0 不内置 metrics/log/trace exporter（仅 EventSink 回调）
- v1.0.0 不绑定具体分布式锁后端（只提供 Locker 接口）

## 5. 架构位置
L1 调度基座（SPEC §3 标注 L1 基础能力）。运行时依赖标准库 only；SPEC 许可依赖 kernel / observex（interface-only）/ resiliencx（可选 job wrapper），禁止依赖 configx / testkitx（仅 test）/ 所有业务域实现。消费者：x.go（组合根，创建 Scheduler 注册 job 调用 Start）、market-data（定时拉取行情）、factor-engine（定时计算因子）、risk-engine（定时风控检查）、report-engine（定时报表）。

## 6. 生命周期
- NewScheduler(opts) → Scheduler 实例
- AddJob(job, trigger, opts...) 注册（重复 name 返回 ErrJobExists，已关闭返回 ErrSchedulerClosed）
- Start(ctx) 启动调度循环
- 运行中：Trigger.Next(after) 询问下一次触发，按 Overlap/Misfire 策略执行 Job.Run
- Shutdown(ctx)：等待正在执行的 job 完成，ctx 超时强制取消返回 ctx.Err()（无专属 ErrShutdownTimeout）
- 0 个 job 注册后 Start 正常启动，等待 Shutdown

## 7. 标准目录结构
```text
schedulex/                          # github.com/ZoneCNH/schedulex
├── schedulex.go                    # Scheduler / Job / Trigger 顶层导出
├── errors.go / options.go / event.go / clock.go
├── overlap.go / misfire.go         # OverlapPolicy / MisfirePolicy 实现
├── cron/cron.go                    # cron 表达式解析（5-field）
├── trigger/trigger.go              # Trigger 构造和验证
├── lock/{lock.go, redis/, memory/} # Locker 接口 + 实现
├── internal/{queue/, wheel/}       # 调度队列 / 时间轮
├── testdata/*.golden
├── example_test.go / benchmark_test.go / integration_test.go
```

## 8. 配置规范
运行时**无 SchedulerConfig struct、无 YAML 解析**。所有配置通过 functional options 传入 NewScheduler 与 AddJob。Scheduler 级 Option：WithClock / WithEventSink / WithMaxConcurrent。Per-job JobOption：WithMisfirePolicy / WithOverlapPolicy / WithJitter / WithLocker / WithLockKey / WithLockTTL / WithJobEventSink。YAML→option 桥接属 v1.1 路线（OQ-010）。

## 9. 错误模型
sentinel errors：`ErrSchedulerClosed`（调度器已停机）、`ErrJobExists`（job name 已注册）、`ErrInvalidJob`（job name/trigger 为空或不合法）、`ErrInvalidOption`（functional option 参数非法）、`ErrLockUnavailable`（分布式锁被占用）。错误消息格式 `"schedulex: <operation>: <detail>"`，使用 `%w` 包装。旧 SPEC 名映射：ErrDuplicateJob→ErrJobExists、ErrInvalidTrigger→ErrInvalidJob、ErrLockAcquire→ErrLockUnavailable；ErrJobNotFound / ErrShutdownTimeout 在运行时不存在。

## 10. 日志规范
schedulex v1.0.0 **不内置结构化日志输出**（NFR-O01 缺口，OQ-009 v1.1 候选）。当前可观测能力完全通过 EventSink 回调暴露，下游基于 Event 自行聚合日志。规划日志事件：schedulex.job.scheduled / started / completed / failed / misfired / skipped / lock.acquired / lock.released，含 job_id + trigger + next_run + duration + error。EventSink 通过 WithEventSink（scheduler 级）或 WithJobEventSink（per-job）注入。

## 11. Metrics
v1.0.0 **不内置 metrics 输出**（NFR-O01 缺口）。规划 metric（OQ-009 v1.1 候选）：`schedulex.job.triggered`(counter, label: job_id)、`schedulex.job.duration`(histogram)、`schedulex.job.errors`(counter, label: job_id, error_type)、`schedulex.job.misfired`(counter, label: job_id, policy)、`schedulex.job.running`(gauge)、`schedulex.queue.size`(gauge)。当前通过 EventSink 回调由下游聚合。

## 12. Tracing
v1.0.0 **不内置 trace span**（NFR-O01 缺口）。规划 span（OQ-009 v1.1 候选）：`schedulex.job`（attribute: job_id, trigger_type）。当前 job 执行跨度通过 Event{StartedAt, FinishedAt, Duration} 暴露，下游基于 EventSink 在 span adapter 中创建 span。Clock 注入保证测试确定性，不依赖真实时间。

## 13. Reliability
- overlap 治理：Skip（上次未完成跳过）/ QueueOne（至多排队一个）/ Allow（允许并发）
- misfire 治理：Skip（错过跳过）/ RunOnce（补执行一次）/ CatchUp（补执行所有错过次数）
- job panic 隔离：catch panic 不影响其他 job（BR-005）
- Shutdown 语义：等待运行中 job 完成，ctx 超时强制取消（BR-003）
- 可选 resiliencx 集成：job 失败 → retry → breaker open → 后续 fail-fast（SPEC 许可，运行时 job wrapper 由调用方组装）
- job handler 必须接受 context.Context 支持取消传播（BR-008）

## 14. Security
- distributed lock 安全：lock TTL > job 最大执行时间，防止锁提前释放导致多实例重复执行（BR-006）
- job 回调隔离：job panic 不传播到调度器，不泄露内部堆栈到业务层
- 标准库 only：无上层域依赖、无 secret、无代码可达漏洞（FR-009 / AC-011）
- 锁失败语义：ErrLockUnavailable → emit EventLockSkipped 跳过；其他 error → emit EventLockFailed
- 时区安全：DST 切换时触发时间正确，不跳过或重复（BR-007，timezone-dst-golden-check CI Gate）

## 15. Performance SLO
| 操作 | 目标 | 测量方式 |
|------|------|----------|
| job 触发延迟 | < 10ms（单节点） | integration test |
| 1000 个 job 内存占用 | < 10MB | profiling |
| 常驻内存 | < 5MB | profiling |

## 16. 测试标准
- 单元测试覆盖率 ≥ 80%
- -race 测试零 data race（scheduler-race-check、shutdown-race）
- TC-001 cron/interval 触发、TC-002 overlap 三类策略、TC-003 misfire 三类策略、TC-004 Locker 失败路径、TC-005 Snapshot 可审计状态、TC-006 Shutdown/panic 隔离/leak/race、TC-007 EventSink 生命周期事件、TC-008 Clock 注入与 DST、TC-009 重复 job 检测、TC-010 downstream/rendered template smoke
- Benchmark：1000 个 job 内存 < 10MB、job 触发延迟 < 10ms
- 集成测试：分布式锁失败 skip、schedulex + resiliencx 组合（retry → breaker）

## 17. Chaos
schedulex 本身治理 chaos 场景：
- misfire 注入：StaticClock 大步推进模拟错过多次触发，验证 Skip/RunOnce/CatchUp 策略（misfire-contract-check）
- overlap 注入：job 执行需 10s，第二次触发在 5s 时到来，验证 Skip/QueueOne/Allow（overlap-contract-check）
- DST 切换注入：StaticClock 位于 DST 边界，验证触发时间不跳不重（timezone-dst-golden-check）
- panic 注入：job panic 被 catch 不影响其他 job（BR-005）
- 分布式锁竞争注入：Locker.TryLock 返回 ErrLockUnavailable，验证跳过本次（TC-004）
- Shutdown 压力注入：停机时 job 正在执行，验证等待或超时 force cancel

## 18. Contract
`NewScheduler(opts) → *Scheduler`（具体类型非 interface）。`AddJob(job Job, trigger Trigger, opts ...JobOption) error`（返回 error 非 (JobID, error)）。`Start(ctx) / Shutdown(ctx) / Snapshot() error`。Job interface{Name() string; Run(ctx) error}，JobFunc 适配器。Trigger interface{Next(after) (time, bool)}，构造器 Once/Every/DailyAt/Cron。OverlapPolicy/MisfirePolicy 为 string 枚举。Locker interface{TryLock(ctx, key, ttl) (Lease, error)}，Lease interface{Release(ctx) error}。

## 19. CI Gate
通用：`go build ./...`、`go test ./... -race -count=1`、覆盖率 < 80% 阻塞、`go vet ./...`、`golangci-lint run`、`go mod tidy && git diff --exit-code`、`gitleaks detect --no-git`、Benchmark 附 PR comment。schedulex 专属：`go test -run TestDST`（时区切换）、`go test -run TestMisfireContract`（misfire 行为）、`go test -run TestOverlapContract`（overlap 行为）、`go test -run TestShutdownLeak`（停机 goroutine 泄漏）、`go test -race -run TestShutdownRace`（停机 data race）。Release：`GOWORK=off make release-check VERSION=v1.0.0`。

## 20. Release Gate
DoD 清单：公共接口有 godoc、CHANGELOG.md 更新、README 含定位/快速开始/API、覆盖率 ≥ 80%、-race 通过、Benchmark 无 > 10% 回退、vet/lint 零警告、DST/timezone golden 测试通过、misfire contract 测试通过、overlap contract 测试通过、shutdown leak 测试通过、shutdown race 测试通过、Secret 扫描通过、API 无破坏性变更、所有 FR/EC 有对应测试。v1.0.0 本地发布验收通过（score=10.0，min=9.8），required checks 全闭合。

## 21. Versioning
semver。当前 Spec-Version v1.0.1 / Module-Version v1.0.0。Scheduler / Job interface 变更 → major；OverlapPolicy / MisfirePolicy 变更 → major；新增可选配置字段 → patch/minor；新增必填配置字段 → minor（带默认值）；bug 修复 → patch。v1.0.1 SPEC §8-§11/§18/§22 已反向对齐运行时 v1.0.0 canonical API（AddJob 非 Schedule、Shutdown 非 Stop、Snapshot 非 List、无 Cancel/JobID/ErrShutdownTimeout）。

## 22. 兼容性策略
- Scheduler / Job interface 变更：major
- OverlapPolicy / MisfirePolicy 变更：major
- 新增可选配置字段：patch / minor
- 新增必填配置字段：minor（带默认值）
- bug 修复：patch
- 边界情况 EC：cron 语法错误（ErrInvalidJob）、interval=0（ErrInvalidJob）、DST 切换（触发正确）、job panic（catch 不影响其他）、停机 job 执行中（等待或超时 force cancel）、锁失败（跳过等下周期）、lock TTL < job 执行时间（v1.1 运行时尚未校验）、0 job Start（正常启动）、时区差异（按 loc 计算）、并发 AddJob + Shutdown（加锁并发安全）

## 23. Failover
- 分布式锁获取失败：跳过本次执行，emit EventLockSkipped，等待下一个调度周期（FR-008）
- 锁非 ErrLockUnavailable 错误：emit EventLockFailed 上报
- job panic：catch 不传播，不影响调度器与其他 job（BR-005）
- Shutdown 期间 job 超时：ctx 超时强制取消返回 ctx.Err()
- misfire 补偿：RunOnce 补执行一次 / CatchUp 补执行所有错过次数（FR-004）
- 单节点 vs 分布式：通过 Locker 接口统一，分布式部署注入 Redis/PG 锁后端防重复执行

## 24. Backpressure
- OverlapSkip：上次未完成时跳过本次触发，防止 job 堆积（FR-003）
- OverlapQueueOne：至多排队一个，防止队列无限增长
- WithMaxConcurrent：调度器级最大并发 job 数，超过等待
- MisfireSkip：错过触发跳过，防止补执行风暴
- MisfireCatchUp：补执行所有错过次数（OQ-004 评估是否有上限）
- bounded queue 通过 Overlap 策略 + MaxConcurrent 实现 overload protection

## 25. 审计要求
- Snapshot 可审计状态：Snapshot{Version, Now, Started, Running, Closed, Shutdown, JobCount, Jobs[]} + JobSnapshot{ID, Name, Next, HasNext, MisfirePolicy, OverlapPolicy, Running, Queued}（FR-008 / AC-008）
- EventSink 事件审计：9 类 EventType 覆盖生命周期/misfire/lock/shutdown（FR-007 / AC-018）
- Locker 审计：TryLock 成功/失败通过 EventLockSkipped/EventLockFailed 上报（AC-019/020）
- 触发确定性审计：trigger-determinism-check + timezone-dst-golden-check 保证可复验
- 发布证据审计：release/manifest/latest.json + 校验和 + score gate + release preflight

## 26. 熵减规则
全局 Entropy Rules + 模块特有禁项：
- 禁止 util dumping（cron/trigger/overlap/misfire/lock 子包职责分离）
- 禁止 hidden abstraction（Overlap/Misfire 策略显式 string 枚举，不内置隐式策略 BR-004）
- 禁止 cyclic dependency（标准库 only，不依赖业务域）
- 禁止 job panic 传播（BR-005 catch 隔离）
- 禁止内置具体锁后端（v1.0.0 只提供 Locker 接口）

## 27. AI Constraints
全局 AI Constraints + 模块特有约束：
- 不新增未注册模块（cron/trigger/overlap/misfire/lock 子包固定）
- 不绕过 contracts（必须通过 AddJob/Trigger/Option API，不直接操作 internal queue/wheel）
- 不动态扩展目录（子包结构固定）
- 不内置业务触发逻辑（不内置策略调仓、行情拉取）
- 不绑定具体分布式锁后端（只实现 Locker 接口）
- 不在 v1.0.0 引入 Cancel/List/JobID/ErrShutdownTimeout（已由 AddJob+Shutdown+Snapshot 替代）

## 28. Forbidden Patterns
- AddJob 不校验 trigger（违反 BR-001，非法 trigger 运行时 panic）
- 同一 Job name 重复注册被覆盖（违反 BR-002，应返回 ErrJobExists）
- Shutdown 不等待运行中 job（违反 BR-003，job 被强杀数据不一致）
- overlap 行为内置隐式策略（违反 BR-004，行为不可预测）
- job panic 传播到调度器（违反 BR-005，所有 job 停止）
- lock TTL ≤ job 最大执行时间（违反 BR-006，多实例重复执行）
- DST 切换触发时间偏移（违反 BR-007，任务提前/延迟/重复）
- job handler 不接受 context.Context（违反 BR-008，无法取消 goroutine 泄漏）

## 29. Production Ready Checklist
- [x] observability ready（EventSink 9 类事件 + Snapshot 可审计状态；metrics/log/trace 集成待 v1.1）
- [x] resilience ready（overlap/misfire 策略 + job panic 隔离 + Shutdown 等待）
- [x] replay ready（StaticClock 注入 + trigger-determinism-check + DST golden 可复验）
- [x] audit ready（Snapshot + EventSink + Locker 事件三重审计）
- [x] rollback ready（v1.0.0 本地发布验收通过，score=10.0）
- [x] release-check / integration / governance p1+p2 / score / release-preflight 全链路通过
- [ ] tag 发布后外部网络 downstream smoke（等待 v1.0.0 对外可解析后执行）
- [ ] factory-grade（四源评分通过前机器事实层 factory=false）

## 30. Roadmap
- OQ-005 v1.1 Cancel(id) 单 job 取消 API
- OQ-006 v1.1 OverlapPolicy = Replace 策略
- OQ-007 v1.1 ErrShutdownTimeout 专属停机超时错误
- OQ-008 v1.1 JobState 枚举与 RunCount/ErrorCount/LastError 完整 JobStatus
- OQ-009 v1.1 metrics/log/trace 集成（当前仅 EventSink 回调）
- OQ-010 v1.1 YAML SchedulerConfig 与 functional option 桥接
- OQ-001 评估动态添加/移除 job 并发安全级别
- OQ-002 评估 job 优先级（高优先级抢占低优先级执行槽）
- OQ-003 评估 Redis 以外的分布式锁后端（PostgreSQL Advisory Lock）
- OQ-004 评估 misfire CatchUp 策略补执行上限
