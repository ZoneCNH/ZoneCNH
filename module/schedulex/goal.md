# schedulex 发布版本 1.0 Goal 定位与实现标准

| 字段 | 内容 |
| --- | --- |
| 模块名 | `schedulex` |
| 发布版本 | 1.0.0 |
| 所属层级 | L1 运行时横切能力 / 调度与异步任务 |
| 稳定级别 | Public API Stable；SPI Stable；Internal 可演进 |
| 文档状态 | 1.0 发布基线文档（v1.0.1 对齐 SPEC.md v1.0.1） |
| 发布日期基准 | 2026-06-09 |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 1.0 发布判定原则

1. **稳定优先**：公开 API、配置项、错误码、指标名一旦进入 1.0，默认需要向后兼容。
2. **边界清晰**：模块只能解决自身层级的问题，不能向上侵入业务，也不能横向替代其他模块。
3. **证据完整**：每个 MUST 能力都必须有单元测试、关键路径集成测试或契约测试证明。
4. **可观测**：所有运行时模块必须输出最小可诊断信息，包括错误、耗时、调用量和关键状态。
5. **可演进**：1.0 允许保留扩展点，但不得把未稳定能力包装成稳定承诺。

## 1. Goal 定位

`schedulex` 的 Goal 是提供统一任务调度运行时，支持 cron/interval/delay 三种触发方式、overlap 和 misfire 策略、可选分布式锁、job 事件 hook 和可注入时钟。它解决的是"任务如何可靠被调度和观测"，不承载具体业务任务逻辑。

### 1.1 为什么需要这个模块

- 业务系统普遍存在周期清理、延迟处理、补偿、同步、报表生成等任务，若各自实现会产生重复和不可靠。
- 多实例部署下任务容易重复执行，必须有分布式锁防止并发。
- 任务失败如果没有状态和证据，会造成隐性数据不一致。
- 调度任务属于后台运行路径，同样需要观测、超时和降级策略。

### 1.2 1.0 要解决的问题

- 统一任务定义（Job）、触发器（Trigger）和执行器（JobHandler）抽象。
- 支持 cron、interval、delay 三种触发方式。
- 支持 overlap 策略（Skip / Queue / Replace）和 misfire 策略（Skip / RunOnce / CatchUp）。
- 支持可选分布式锁（Locker），防止多实例重复执行。
- 统一任务运行日志、指标和 Trace。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 提供 Scheduler、Job、Trigger、JobHandler、EventSink、Locker 抽象。
- MUST 支持单节点调度 + 可选分布式锁（Locker）。
- MUST 明确执行语义：默认 at-least-once，不承诺 exactly-once。业务侧如需 exactly-once 需自行实现幂等。
- MUST 支持任务状态：pending、running、completed、failed、cancelled。
- MAY 可选集成 observex、resiliencx（job wrapper）。

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| 周期任务 | 每天凌晨清理过期对象 | 按 cron 触发并记录执行历史 |
| 延迟任务 | 订单超时关闭或消息延迟补偿 | 到期触发，通过 EventSink 记录 |
| 分布式任务 | 服务多副本部署但任务只允许一个实例执行 | 通过 Locker 避免并发执行 |
| 失败排查 | 后台任务失败但无用户请求上下文 | 任务执行日志、状态和 EventSink 可追踪 |
| 集群 Failover | 调度节点宕机，任务需转移到其他节点 | 通过 Locker TTL 到期自动释放，其他节点接管任务 |

## 4. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| 任务定义 | Job：ID、Name、Trigger、Handler、Timeout、MaxRetries、Overlap、Misfire | 定义校验测试通过 |
| 触发器 | cron、interval、delay | 触发计算测试通过 |
| 执行器 | JobHandler(ctx) error，并发控制（MaxConcurrency），取消传播 | 执行生命周期测试通过 |
| Overlap 策略 | Skip / Queue / Replace | Overlap contract 测试通过 |
| Misfire 策略 | Skip / RunOnce / CatchUp | Misfire contract 测试通过 |
| 分布式锁 | Locker：Acquire / Release，TTL 约束 | 多实例测试通过 |
| 时钟注入 | FakeClock 实现确定性测试 | 时钟注入测试通过 |
| 调度观测 | 日志、指标、EventSink、Span | 观测测试通过 |

## 5. 职责边界

### 5.1 模块内职责

- 提供任务调度和执行框架（Scheduler + Job）。
- 提供任务状态、overlap / misfire 策略和观测。
- 提供可插拔锁实现 SPI（Locker 接口）。
- 支持 Schedule / Cancel / List / Start / Stop 生命周期。

### 5.2 明确非目标

- 不替代完整工作流/BPM 引擎。
- 不处理人工审批、多步骤编排、长事务 Saga 的业务语义。
- 不承诺 exactly-once 执行。
- 不直接实现业务任务内容。
- 不负责业务任务执行结果的持久化和查询（仅通过 List() 暴露当前调度状态）。
- 不提供暂停/恢复（pause/resume）、手动触发（triggerNow）、幂等 key（idempotencyKey）——这些是 1.0 后演进方向。
- 不提供 TaskStore / 状态存储 SPI。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 上游依赖 | 依赖 kernel（L0 原语）、stdlib。 |
| 下游依赖 | 业务任务和部分模块维护任务可以使用 schedulex。 |
| 可选依赖 | Locker 可由 redisx 或 postgresx 适配，但核心模块只依赖 Locker SPI。observex（interface-only）、resiliencx（可选 job wrapper）。 |
| 契约依赖 | MUST 向 contracts 登记 Public API 契约和错误码契约。 |

## 7. 对外契约

### 7.1 公开能力面

| 契约 | 定位 | 1.0 稳定承诺 |
| --- | --- | --- |
| Scheduler | 任务注册、取消、列表、启停 | 核心生命周期稳定 |
| Job | 任务元数据和执行策略 | 字段语义稳定 |
| Trigger | 触发时间计算（cron / interval / delay） | cron 和延迟语义稳定 |
| JobHandler | 业务执行接口 `func(ctx context.Context) error` | 输入输出和错误语义稳定 |
| EventSink | 生命周期事件回调 | 事件类型稳定 |
| Locker | 分布式锁扩展点（Acquire / Release） | TTL 语义稳定 |

### 7.2 1.0 逻辑接口基线

```text
Scheduler
  Schedule(job Job) (JobID, error)
  Cancel(id JobID) error
  List() []JobStatus
  Start(ctx context.Context) error
  Stop(ctx context.Context) error

Job
  ID, Name, Trigger, Handler, Timeout, MaxRetries
  Overlap (Skip / Queue / Replace)
  Misfire (Skip / RunOnce / CatchUp)

Trigger
  Cron string | Interval time.Duration | Delay time.Duration

JobHandler
  func(ctx context.Context) error

EventSink
  func(JobEventData)
  // EventTriggered | EventStarted | EventCompleted
  // EventFailed | EventMisfired | EventSkipped

Locker
  Acquire(ctx, key, ttl) (bool, error)
  Release(ctx, key) error
```

## 8. 配置契约

| 配置项 | 含义 | 默认值 / 要求 | 稳定性 |
| --- | --- | --- | --- |
| schedulex.timezone | 调度时区 | UTC | Stable |
| schedulex.overlap_policy | 重叠执行策略 | skip / queue / replace | Stable |
| schedulex.misfire_policy | 错过触发策略 | skip / run_once / catch_up | Stable |
| schedulex.max_concurrency | 最大并发 job 数 | 10 | Stable |
| schedulex.default_timeout | 默认 job 超时 | 5m | Stable |
| schedulex.shutdown_timeout | 停机等待超时 | 30s | Stable |
| schedulex.distributed_lock.enabled | 是否启用分布式锁 | false | Stable |
| schedulex.distributed_lock.backend | 锁后端 | redis / postgres | Stable |
| schedulex.distributed_lock.ttl | 锁租约 | 30s | Stable |
| schedulex.jitter.enabled | 是否启用抖动 | true | Stable |
| schedulex.jitter.max | 最大抖动时间 | 5s | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 输出 job 注册、触发、开始、结束、失败、跳过。
- MUST 包含 job_id、trigger_type、duration、error。
- SHOULD 对 misfire、锁竞争失败输出诊断日志。

### 9.2 指标

| 指标名 | 类型 | 标签 | 说明 |
| --- | --- | --- | --- |
| schedulex_job_triggered | Counter | job_id | job 触发次数 |
| schedulex_job_duration | Histogram | job_id | job 执行耗时 |
| schedulex_job_errors | Counter | job_id, error_type | job 执行失败次数 |
| schedulex_job_misfired | Counter | job_id, policy | misfire 次数 |
| schedulex_job_running | Gauge | | 当前正在执行的 job 数 |
| schedulex_queue_size | Gauge | | 等待执行的 job 数 |

### 9.3 Trace / 诊断事件

- MUST 接收并传播上游 trace context，不得无故丢失 requestId / traceId。
- MUST 为每次 job 执行创建 span，attribute: job_id, trigger_type。
- SHOULD 输出 misfired、skipped、lock_acquired、lock_released 诊断事件。

## 10. 错误模型与失败策略

| 错误类别 | 典型原因 | 1.0 处理策略 |
| --- | --- | --- |
| ErrInvalidTrigger | cron 语法错误或 interval <= 0 | 返回不可重试错误 |
| ErrDuplicateJob | 重复 JobID 注册 | 返回不可重试错误 |
| ErrJobNotFound | Cancel 不存在的 job | 返回不可重试错误 |
| ErrShutdownTimeout | job 执行超过 shutdown_timeout | 强制取消并返回超时错误 |
| ErrLockAcquire | 分布式锁获取失败 | 跳过本次执行，等待下一个调度周期 |
| Job Panic | handler 内部 panic | catch panic，记录日志，不影响其他 job |

## 11. 安全、稳定性与兼容性要求

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的异常不会泄漏内部凭据、主机隐私或完整连接串。
- MUST 为所有网络和外部依赖调用设置超时边界。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容 | 发布门禁 |
| --- | --- | --- |
| 单元测试 | 触发时间计算、overlap 策略、misfire 策略、DST 切换、trigger 验证 | MUST 通过 |
| 集成测试 | 分布式锁、job 生命周期、EventSink | MUST 通过 |
| 并发测试 | 多实例抢锁、Schedule + Cancel 并发安全 | MUST 通过 |
| 故障测试 | 锁获取失败、handler 超时、handler panic | MUST 通过 |
| 观测测试 | 日志、指标、EventSink | MUST 通过 |

## 13. 1.0 发布验收清单

- 支持 cron、interval、delay 三类触发。
- 多实例部署下单任务不会并发执行（通过 Locker），除非未启用分布式锁。
- 任务失败有状态、日志、指标和可追踪错误码。
- 业务任务接入不需要直接处理调度线程和锁细节。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

- 支持任务分片和批量调度。
- 支持更复杂的 DAG 编排，但保持与工作流引擎边界。
- 支持任务管理 UI 的查询 API。
- 支持暂停/恢复（pause/resume）和手动触发（triggerNow）。
- 支持幂等 key（idempotencyKey）。
- 支持 TaskStore SPI 实现状态持久化。
