# schedulex 发布版本 1.0 Goal 定位与实现标准

| 字段 | 内容 |
| --- | --- |
| 模块名 | `schedulex` |
| 发布版本 | 1.0.0 |
| 所属层级 | L1 运行时横切能力 / 调度与异步任务 |
| 稳定级别 | Public API Stable；SPI Stable；Internal 可演进 |
| 文档状态 | 1.0 发布基线文档 |
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

`schedulex` 的 Goal 是提供统一任务调度和异步任务执行能力，支持周期任务、延迟任务、一次性任务、分布式单实例执行、幂等、重试、超时、状态追踪和调度观测。它解决的是“任务如何可靠被调度和追踪”，不承载具体业务任务逻辑。

### 1.1 为什么需要这个模块

- 业务系统普遍存在周期清理、延迟处理、补偿、同步、报表生成等任务，若各自实现会产生重复和不可靠。
- 多实例部署下任务容易重复执行，必须有分布式锁、租约和幂等约束。
- 任务失败如果没有状态和证据，会造成隐性数据不一致。
- 调度任务属于后台运行路径，同样需要观测、超时、重试和降级策略。

### 1.2 1.0 要解决的问题

- 统一任务定义、触发器、执行器、状态存储和锁抽象。
- 支持 cron、fixed-rate、fixed-delay、delayed、one-shot。
- 支持分布式锁、租约续期、任务幂等和重复执行防护。
- 支持任务重试、超时、失败记录、人工触发和禁用。
- 统一任务运行日志、指标和 Trace。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 提供 TaskDefinition、Trigger、TaskHandler、Scheduler、TaskStore、LockProvider 抽象。
- MUST 支持单机和分布式两种运行模式。
- MUST 明确执行语义：默认 at-least-once，不承诺 exactly-once，业务必须通过幂等保证安全。
- MUST 支持任务状态：scheduled、running、succeeded、failed、skipped、timeout、cancelled。
- MUST 接入 configx、observex、resiliencx。

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| 周期任务 | 每天凌晨清理过期对象 | 按 cron 触发并记录执行历史 |
| 延迟任务 | 订单超时关闭或消息延迟补偿 | 到期触发，失败可重试 |
| 分布式任务 | 服务多副本部署但任务只允许一个实例执行 | 通过 LockProvider 和租约避免并发执行 |
| 失败排查 | 后台任务失败但无用户请求上下文 | 任务执行日志、状态和诊断事件可追踪 |
| 集群 Failover | 调度节点宕机，任务需转移到其他节点 | 通过 LockProvider 租约到期自动释放，其他节点接管任务 |

## 4. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| 任务定义 | 任务名称、版本、参数 schema、幂等 key、超时、重试策略 | 定义校验测试通过 |
| 触发器 | cron、fixed-rate、fixed-delay、delayed、one-shot | 触发计算测试通过 |
| 执行器 | 同步/异步 handler、并发控制、取消、deadline | 执行生命周期测试通过 |
| 分布式锁 | 锁获取、租约、续期、释放、过期恢复 | 多实例测试通过 |
| 状态存储 | 任务实例、运行历史、失败原因、下一次触发时间 | 状态迁移测试通过 |
| 幂等控制 | idempotencyKey、重复触发检测、执行去重 | 重复触发测试通过 |
| 调度观测 | 日志、指标、Trace、诊断事件 | 观测测试通过 |

## 5. 职责边界

### 5.1 模块内职责

- 提供任务调度和执行框架。
- 提供任务状态、锁、幂等、重试、超时和观测。
- 提供可插拔存储和锁实现 SPI。
- 支持人工触发、禁用、暂停和恢复任务。

### 5.2 明确非目标

- 不替代完整工作流/BPM 引擎。
- 不处理人工审批、多步骤编排、长事务 Saga 的业务语义。
- 不承诺 exactly-once 执行。
- 不直接实现业务任务内容。
- 不负责业务任务执行结果的持久化和查询，只管理调度状态和执行历史。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 上游依赖 | 依赖 kernel、configx、observex、resiliencx。 |
| 下游依赖 | 业务任务和部分模块维护任务可以使用 schedulex。 |
| 可选依赖 | LockProvider/TaskStore 可由 redisx 或 postgresx 适配，但核心模块只依赖 SPI。 |

| 契约依赖 | MUST 向 contracts 登记 Public API 契约和错误码契约。 |
## 7. 对外契约

### 7.1 公开能力面

| 契约 | 定位 | 1.0 稳定承诺 |
| --- | --- | --- |
| Scheduler | 任务注册、启动、暂停、触发 | 核心生命周期稳定 |
| TaskDefinition | 任务元数据和执行策略 | 字段语义稳定 |
| Trigger | 触发时间计算 | cron 和延迟语义稳定 |
| TaskHandler | 业务执行接口 | 输入输出和错误语义稳定 |
| TaskStore SPI | 状态存储扩展点 | 状态迁移语义稳定 |
| LockProvider SPI | 分布式锁扩展点 | 租约语义稳定 |

### 7.2 1.0 逻辑接口基线

```text
Scheduler
  register(TaskDefinition, TaskHandler)
  start()
  pause(taskName)
  resume(taskName)
  triggerNow(taskName, params): TaskInstanceId

TaskDefinition
  name
  version
  trigger
  timeout
  retryPolicy
  idempotencyKeyExpression
  maxConcurrency

TaskHandler
  handle(TaskContext, TaskInput): TaskResult

LockProvider
  tryAcquire(lockKey, ttl): LockLease
  renew(lease, ttl)
  release(lease)
```

## 8. 配置契约

| 配置项 | 含义 | 默认值 / 要求 | 稳定性 |
| --- | --- | --- | --- |
| foundationx.schedule.enabled | 是否启用调度 | true | Stable |
| foundationx.schedule.mode | 运行模式 | local / distributed | Stable |
| foundationx.schedule.thread-pool-size | 任务线程池大小 | CPU 或配置默认 | Stable |
| foundationx.schedule.default-timeout | 默认任务超时 | 30m | Stable |
| foundationx.schedule.misfire-policy | 错过触发策略 | skip / fire-once / fire-all | Stable |
| foundationx.schedule.lock.ttl | 分布式锁租约 | 60s | Stable |
| foundationx.schedule.history.retention | 任务历史保留时间 | 30d | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 输出任务注册、触发、开始、结束、失败、跳过、超时。
- MUST 包含 taskName、taskVersion、instanceId、triggerType、durationMs、attempt、errorCode、traceId。
- SHOULD 对 misfire、锁竞争失败、重复触发输出诊断日志。

### 9.2 指标

| 指标名 | 类型 | 标签 | 说明 |
| --- | --- | --- | --- |
| foundationx_schedule_trigger_total | Counter | task,triggerType,status | 任务触发次数 |
| foundationx_schedule_execution_total | Counter | task,status | 任务执行次数 |
| foundationx_schedule_execution_duration_ms | Timer | task,status | 任务执行耗时 |
| foundationx_schedule_running_tasks | Gauge | task | 当前运行任务数 |
| foundationx_schedule_lock_acquire_total | Counter | task,status | 锁获取次数 |
| foundationx_schedule_misfire_total | Counter | task,policy | 错过触发次数 |

### 9.3 Trace / 诊断事件

- MUST 接收并传播上游 trace context，不得无故丢失 requestId / traceId。
- MUST 为每次任务执行创建新的 root span 或从触发上下文恢复 span。
- MUST 将 taskName、instanceId、attempt 写入 span 属性。
- SHOULD 输出 TASK_FAILED、TASK_TIMEOUT、TASK_MISFIRED、TASK_LOCK_SKIPPED 诊断事件。

## 10. 错误模型与失败策略

| 错误类别 | 典型原因 | 1.0 处理策略 |
| --- | --- | --- |
| SCHEDULE_TASK_NOT_FOUND | 触发未注册任务 | 返回不可重试错误 |
| SCHEDULE_LOCK_FAILED | 分布式锁获取失败 | 跳过本次执行并记录状态 |
| SCHEDULE_TASK_TIMEOUT | 任务超过执行超时 | 取消任务并按策略重试或失败 |
| SCHEDULE_HANDLER_FAILED | 业务 handler 抛错 | 记录失败并按 retryPolicy 处理 |
| SCHEDULE_STORE_UNAVAILABLE | 状态存储不可用 | 停止调度或降级为本地模式需显式配置 |

## 11. 安全、稳定性与兼容性要求

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的异常不会泄漏内部凭据、主机隐私或完整连接串。
- MUST 为所有网络和外部依赖调用设置超时边界。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。
- MUST 对人工触发和任务参数记录审计事件。
- MUST 对任务参数进行 schema 校验，避免任意参数注入。
- SHOULD 支持任务级权限校验扩展点。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容 | 发布门禁 |
| --- | --- | --- |
| 单元测试 | 触发时间计算、状态迁移、幂等 key、misfire 策略 | MUST 通过 |
| 集成测试 | 本地模式、分布式锁、状态存储、任务重试 | MUST 通过 |
| 并发测试 | 多实例抢锁、租约续期、重复触发 | MUST 通过 |
| 故障测试 | 存储不可用、锁过期、handler 超时 | MUST 通过 |
| 观测测试 | 任务日志、指标、Trace 和诊断事件 | MUST 通过 |

## 13. 1.0 发布验收清单

- 支持至少 cron、fixed-delay、one-shot 三类触发。
- 多实例部署下单任务不会并发执行，除非明确允许。
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
