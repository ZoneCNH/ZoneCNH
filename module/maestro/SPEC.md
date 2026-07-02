# maestro 规格

- Status: Spec Approved / Tasks Pending
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-30
- Layer: 决策域 · 工作流编排
- Version: v0.1.0-draft
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `strategyx`, `riskx`, `orderx`

> 公开投影 caveat：Status=Review 与矩阵覆盖证据不等同于 factory-grade；四源评分通过前机器事实层保持 factory=false。

---

## 1. 摘要

`maestro` 是决策域的工作流编排引擎，负责定义和执行多阶段交易工作流。它将分析域（因子）、决策域（策略生成信号）和执行域（风控 → 订单）编排为可组合、可观测、可恢复的 DAG 工作流。maestro 是策略执行的"指挥家"，不计算因子、不判断信号、不下达订单——它只协调这些步骤的执行顺序、错误处理和状态管理。

定位三角：

```text
strategyx 定义"做什么决策"
maestro 定义"怎么编排决策流程"
backtestx 验证"决策是否正确"
```

---

## 2. 问题与背景

量化交易系统中有多个独立模块（factor_engine、strategyx、riskx、orderx、positionx），但缺少统一的编排层：

- 各模块调用顺序硬编码在启动脚本中，无法灵活组合
- 工作流错误处理散落在各模块，无统一重试/回滚策略
- 长运行工作流（如日内策略）缺少状态管理和断点恢复
- 多策略并行运行时缺乏协调和资源分配
- 工作流执行过程不可观测，故障排查困难

---

## 3. 目标

- DAG 工作流定义：节点（Task）和边（依赖关系）
- 任务类型：Strategy（策略信号）、Risk（风控检查）、Order（订单提交）、Wait（等待）、Condition（条件分支）、Parallel（并行执行）
- 状态机：PENDING → RUNNING → SUCCEEDED / FAILED / CANCELLED
- 错误恢复：Retry（带退避）、Fallback（降级路径）、Rollback（回滚已执行节点）
- 断点恢复：工作流中断后从最后成功节点恢复
- 多租户：多个工作流实例并发执行，资源隔离
- 全链路可观测：每个节点的输入/输出/耗时/状态

---

## 4. 非目标

- 不做因子计算（→ factor_engine）
- 不做策略决策（→ strategyx）
- 不做风控（→ riskx）
- 不做订单管理（→ orderx）
- 不做仓位计算（→ positionx）
- 不做分布式工作流调度（单进程内编排）

---

## 5. 消费者

| 消费者       | 使用方式                              | 数据流向 |
| ------------ | ------------------------------------- | -------- |
| x.go         | 启动时加载工作流定义并注入到 maestro  | x.go → maestro（配置注入） |
| strategyx    | 作为 Task 节点被 maestro **调用**      | strategyx → maestro（策略信号作为 Task 返回值流回 maestro） |
| riskx        | 作为 Task 节点被 maestro **调用**      | maestro → riskx → 风控结果 |
| orderx       | 作为 Task 节点被 maestro **调用**      | maestro → orderx → 成交回报 |
| observex     | 消费工作流 metrics 和 traces          | maestro → observex（指标推送） |

> **代码依赖 vs 数据流**：上表"消费者"表示谁**调用/依赖** maestro。数据流方向与之相反——例如 strategyx 被 maestro 调用（代码依赖 maestro → strategyx），但策略信号从 strategyx **流回** maestro（数据流 strategyx → maestro）。ARCHITECTURE.md 业务流图使用数据流箭头，不表示代码依赖。

---

## 6. 功能需求

### FR-001: Workflow DAG

WHEN 定义 Workflow
THEN 包含 Nodes（Task 列表）和 Edges（依赖关系）
AND DAG 必须有且仅有一个 Start 节点和一个 End 节点
AND DAG 不得包含循环依赖（拓扑排序检测，创建时报错）
AND 每个 Node 定义：name, type, config, retryPolicy, timeout

### FR-002: Task Types

WHEN 定义 Node
THEN 支持以下 Task 类型：
  - STRATEGY：调用 strategyx 生成信号
  - RISK_CHECK：调用 riskx.CheckOrder 执行风控
  - ORDER_SUBMIT：调用 orderx.Submit 提交订单
  - WAIT：等待指定时间或条件
  - CONDITION：条件分支（if/else）
  - PARALLEL：并行执行多个子节点（fan-out → fan-in）

### FR-003: Workflow Execution

WHEN 执行 Workflow(ctx, input)
THEN 按拓扑排序依次执行节点
AND 每个节点执行前验证依赖节点的输出
AND 节点执行超时时按 timeout 策略处理（RETRY/FAIL/CONTINUE）
AND 执行完成后返回 WorkflowResult：status, nodeResults[], totalDuration, error

### FR-004: State Machine

WHEN Workflow 运行
THEN 状态转换：
```text
PENDING → RUNNING
RUNNING → SUCCEEDED
RUNNING → FAILED
RUNNING → CANCELLED
FAILED → RETRYING（如果配置了 retry）
RETRYING → RUNNING
任何状态 → CANCELLED（外部取消）
```
AND 每次状态变更 emit workflow.state_change 事件

### FR-005: Error Recovery

WHEN 节点执行失败
THEN 按 retryPolicy 重试（maxAttempts, backoff: fixed/exponential）
AND 重试耗尽后按 fallback 策略处理：
  - FAIL_WORKFLOW：终止整个工作流
  - SKIP_NODE：跳过该节点继续执行
  - RUN_FALLBACK：执行备用节点
WHEN 工作流失败
THEN 回滚已执行的节点（逆拓扑顺序调用 Rollback）
AND 仅回滚标注了 compensable=true 的节点

### FR-006: Checkpoint and Resume

WHEN 工作流执行到 Checkpoint 节点
THEN 保存当前状态到持久存储：completedNodes[], intermediateOutputs, timestamp
WHEN 工作流中断后恢复
THEN 从最后一个 Checkpoint 恢复执行
AND 已完成节点不重复执行（幂等）

### FR-007: Conditional Branching

WHEN 节点类型为 CONDITION
THEN 评估 condition 表达式（如 `signal.confidence > 0.7`）
AND true 时走 thenBranch，false 时走 elseBranch
AND 两条分支最终汇聚到同一节点或 End 节点

### FR-008: Parallel Execution

WHEN 节点类型为 PARALLEL
THEN 并发执行所有子节点（goroutine pool）
AND 等待所有子节点完成（或任一失败 + failFast=true）
AND 收集子节点输出合并为 fan-in 结果
AND 并发数通过 maxConcurrency 限制

### FR-009: Workflow Registry

WHEN 注册 Workflow(name, definition)
THEN 名称全局唯一
AND 支持运行时注册、更新（新实例使用新定义，旧实例不受影响）
AND 注册表支持 List、Get、Delete

---

### FR-010: Module Identity

WHEN downstream consumer reads `maestro` `README.md`
THEN the H1 heading MUST be `# maestro`
AND MUST NOT be `# xlib_standard`

WHEN module documentation references the `maestro` Go module path
THEN it MUST use `github.com/ZoneCNH/maestro`
AND MUST NOT use `github.com/ZoneCNH/xlib_standard`

WHEN `go.mod` declares the module name
THEN it MUST be `module github.com/ZoneCNH/maestro`

### Acceptance Criteria

| AC 编号 | 对应 FR | 验收条件 |
| ------- | ------- | -------- |
| AC-MAE-001 | FR-001 | Workflow DAG 创建时检测循环依赖并报错；必须包含且仅包含一个 Start 和一个 End 节点 |
| AC-MAE-002 | FR-001 | 每个 Node 定义包含 name, type, config, retryPolicy, timeout 五个字段 |
| AC-MAE-003 | FR-002 | 支持全部 6 种 Task 类型（STRATEGY, RISK_CHECK, ORDER_SUBMIT, WAIT, CONDITION, PARALLEL），未支持的类型创建失败 |
| AC-MAE-004 | FR-003 | Workflow 按拓扑排序执行节点；节点超时时按策略（RETRY/FAIL/CONTINUE）处理；返回 WorkflowResult 含 status, nodeResults, totalDuration, error |
| AC-MAE-005 | FR-004 | 状态机转换遵循 PENDING→RUNNING→SUCCEEDED/FAILED/CANCELLED，FAILED→RETRYING→RUNNING；每次变更 emit workflow.state_change 事件 |
| AC-MAE-006 | FR-005 | 节点失败按 retryPolicy 重试；重试耗尽后执行 fallback（FAIL_WORKFLOW/SKIP_NODE/RUN_FALLBACK）；工作流失败时逆拓扑回滚 compensable 节点 |
| AC-MAE-007 | FR-006 | Checkpoint 持久化 completedNodes, intermediateOutputs, timestamp；恢复时从最后 Checkpoint 继续，已完成节点不重复执行 |
| AC-MAE-008 | FR-007 | CONDITION 节点评估表达式后走 thenBranch 或 elseBranch；两条分支汇聚到同一节点或 End |
| AC-MAE-009 | FR-008 | PARALLEL 节点并发执行子节点，收集 fan-in 结果；failFast=true 时任一失败立即终止；并发数不超过 maxConcurrency |
| AC-MAE-010 | FR-009 | Workflow 注册名称全局唯一；运行时注册/更新不影响已运行实例；List/Get/Delete 操作正确返回 |
| AC-MAE-011 | FR-010 | README H1 为 `# maestro`；Go module path 为 `github.com/ZoneCNH/maestro`；go.mod 声明 `module github.com/ZoneCNH/maestro` |

## 7. 行为约束

| 编号   | 规则                                   | 违反后果 |
| ------ | -------------------------------------- | -------- |
| BR-001 | DAG 必须有且仅有一个 Start 和一个 End   | 创建失败 |
| BR-002 | DAG 不得包含循环依赖                   | 创建失败 + 返回环路径 |
| BR-003 | 节点重试耗尽后必须执行 fallback 策略   | 工作流状态卡在 RETRYING |
| BR-004 | Checkpoint 必须持久化（不可仅内存）     | 重启后无法恢复 |
| BR-005 | 回滚仅适用于 compensable 节点          | 非补偿节点跳过回滚 |
| BR-006 | 工作流定义变更不影响已运行实例         | 用旧定义完成，新实例用新定义 |

---

## 8. 接口契约

```go
type Orchestrator interface {
    Register(ctx context.Context, wf WorkflowDef) error
    Execute(ctx context.Context, name string, input WorkflowInput) (*WorkflowResult, error)
    Cancel(ctx context.Context, instanceID string) error
    Status(ctx context.Context, instanceID string) (*WorkflowStatus, error)
    Resume(ctx context.Context, instanceID string) (*WorkflowResult, error)
    List(ctx context.Context) ([]WorkflowDef, error)
}

type Task func(ctx context.Context, input TaskInput) (TaskOutput, error)
type RollbackTask func(ctx context.Context, input TaskOutput) error

type Node struct {
    Name         string
    Type         NodeType
    Task         Task
    Rollback     RollbackTask
    Compensable  bool
    RetryPolicy  RetryPolicy
    Timeout      time.Duration
    DependsOn    []string
}

type WorkflowResult struct {
    InstanceID    string
    Status        WorkflowStatus
    NodeResults   []NodeResult
    TotalDuration time.Duration
    Error         string
}
```

---

## 9. 数据模型

| 模型              | 字段 |
| ----------------- | ---- |
| WorkflowDef       | name, version, nodes[], edges[], startNode, endNode |
| Node              | name, type(NodeType), task, timeout, retryPolicy, dependsOn[], compensable |
| NodeType          | enum: STRATEGY, RISK_CHECK, ORDER_SUBMIT, WAIT, CONDITION, PARALLEL |
| WorkflowStatus    | enum: PENDING, RUNNING, SUCCEEDED, FAILED, CANCELLED, RETRYING |
| RetryPolicy       | maxAttempts, backoff(FIXED/EXPONENTIAL), initialDelay, maxDelay |
| FallbackPolicy    | enum: FAIL_WORKFLOW, SKIP_NODE, RUN_FALLBACK |
| NodeResult        | nodeName, status, input, output, durationMs, attempts, error |
| WorkflowInput     | map[string]any — 工作流启动参数 |
| Checkpoint        | instanceID, completedNodes[], intermediateOutputs, timestamp |

---

## 10. 配置模式

```yaml
maestro:
  execution:
    default_timeout: 300s
    max_concurrency: 10
    max_instances: 50
  retry:
    default_max_attempts: 3
    default_backoff: exponential
    default_initial_delay: 1s
    default_max_delay: 30s
  checkpoint:
    enabled: true
    storage: redisx  # redisx / postgresx
    interval: 10s
```

---

## 11. 错误处理

| 错误                  | 处理方式                           |
| --------------------- | ---------------------------------- |
| DAG 循环依赖           | 创建时返回错误 + 环路径            |
| 节点执行超时           | 按 retryPolicy 处理                |
| 所有重试耗尽           | 按 fallbackPolicy 处理             |
| Checkpoint 写入失败    | 记录错误 + 继续执行（best-effort）  |
| 工作流取消             | 等待当前节点完成 → 标记 CANCELLED  |
| Rollback 失败          | 记录错误 + 继续回滚下一节点        |

---

## 12. 边界情况

| 场景                       | 预期行为                           |
| -------------------------- | ---------------------------------- |
| 并行节点中某子节点失败      | failFast=true 时立即取消其他子节点 |
| Checkpoint 后节点全部成功   | 下一个 Checkpoint 覆盖前一个       |
| 恢复时 DAG 已变更           | 使用原 DAG 定义完成执行            |
| 并发执行同一工作流定义       | 每个实例独立，通过 instanceID 区分 |
| Start 和 End 之间无节点     | 空工作流，直接标记 SUCCEEDED       |

---

## 13. 目录结构

```text
maestro/
├── go.mod
├── go.sum
├── README.md
├── orchestrator.go    # Orchestrator 接口和实现
├── workflow.go        # Workflow 定义和 DAG 校验
├── executor.go        # 工作流执行引擎
├── node.go            # Node 类型定义
├── dag.go             # DAG 拓扑排序和环检测
├── checkpoint.go      # Checkpoint/Resume
├── retry.go           # 重试策略
├── fallback.go        # 降级策略
├── rollback.go        # 回滚逻辑
├── parallel.go        # 并行执行
├── condition.go       # 条件分支
├── registry.go        # Workflow 注册表
├── errors.go          # 错误定义
├── internal/
│   └── store/         # Checkpoint 存储后端
└── example_test.go
```

---

## 14. 依赖

| 可以依赖                             | 禁止依赖                     |
| ------------------------------------ | ---------------------------- |
| kernel, configx, observex, contracts | 因子计算（→ factor_engine） |
| strategyx (Strategy 接口)            | 具体策略实现               |
| riskx (CheckOrder 接口)              |                            |
| orderx (Submit 接口)                 |                            |
| redisx / postgresx (checkpoint 存储) |                            |
| stdlib                               |                            |

---

## 15. 测试

| 测试场景            | 验证点                           |
| ------------------- | -------------------------------- |
| DAG 校验             | 循环依赖检测正确                 |
| 简单线性工作流       | 节点按序执行，输出传递正确       |
| 条件分支             | true/false 路径均正确           |
| 并行执行             | fan-out/fan-in 正确，failFast    |
| 节点重试             | 退避时间，maxAttempts 耗尽       |
| 回滚                 | 逆序补偿，非 compensable 跳过   |
| Checkpoint/Resume    | 从中断点恢复，已执行节点不重复   |

---

## 16. 性能预算

| 操作                      | 目标     |
| ------------------------- | -------- |
| DAG 校验 (50 节点)        | < 10ms   |
| 节点调度延迟              | < 1ms    |
| Checkpoint 写入           | < 50ms   |
| 工作流恢复                | < 100ms  |

---

## 17. 可观测性

| 信号   | 指标                                    |
| ------ | --------------------------------------- |
| Metric | maestro.workflow.instances.active       |
| Metric | maestro.workflow.duration_ms            |
| Metric | maestro.node.duration_ms (by node_name) |
| Metric | maestro.node.retry.count               |
| Trace  | workflow_id → node_name → duration      |
| Log    | workflow lifecycle, node start/end/error |

---

## 18. 安全

| 要求               | 实现方式                         |
| ------------------ | -------------------------------- |
| 工作流定义不可篡改 | 注册后只读（更新=新建版本）      |
| 节点输入脱敏       | 日志中不记录完整 TaskInput       |

---

## 19. CI 门禁

| Gate   | 命令                               | 阻塞条件       |
| ------ | ---------------------------------- | -------------- |
| 编译   | `go build ./...`                   | 编译失败       |
| 测试   | `go test ./... -race -count=1`     | 测试失败       |
| 覆盖率 | `go test -coverprofile=...`        | < 80%          |
| vet    | `go vet ./...`                     | vet 错误       |

---

## 20. 升级兼容性

| 变更类型             | 版本升级 |
| -------------------- | -------- |
| 新增 Node 类型       | minor    |
| 新增 Task 接口方法   | major    |
| WorkflowDef schema 变更 | major |

---

## 21. 发布 DoD

- [ ] Orchestrator 接口完整实现
- [ ] 全部 6 种 Node 类型实现并测试
- [ ] DAG 环检测正确
- [ ] Checkpoint/Resume 端到端验证
- [ ] 回滚逻辑完整
- [ ] 覆盖率 ≥ 80%

---

## 22. 待解决问题

- 是否需要支持子工作流（SubWorkflow Node）？
- 是否需要可视化 DAG 编辑器？
- 工作流定义是否支持 YAML/JSON 声明式加载？
- 是否需要定时触发器（cron workflow）？


## 23. 变更历史

| 日期       | 版本         | 变更内容 | 作者    |
| ---------- | ------------ | -------- | ------- |
| 2026-06-14 | v0.1.0-draft | 初始版本 | ZoneCNH |
| 2026-06-14 | v0.1.0-draft | FR-010 Module Identity (README H1 + go.mod 校验) | ZoneCNH |