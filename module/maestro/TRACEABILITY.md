# maestro 需求追溯矩阵

> 更新：2026-06-15
> 来源：module/maestro/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

---

## 1. 功能需求追溯（FR）

| FR | Description | Acceptance Criteria | Test Case | Task | Status |
|----|-------------|---------------------|-----------|------|--------|
| FR-001 | Workflow DAG：Nodes + Edges 定义；唯一 Start/End 节点；循环检测 | AC-MAE-001, AC-MAE-002 | TC-MAE-001, TC-MAE-002 | - | ✅ |
| FR-002 | Task Types：STRATEGY/RISK_CHECK/ORDER_SUBMIT/WAIT/CONDITION/PARALLEL 6 种 | AC-MAE-003 | TC-MAE-003 | - | ✅ |
| FR-003 | Workflow Execution：拓扑排序执行；超时策略；返回 WorkflowResult | AC-MAE-004 | TC-MAE-004 | - | ✅ |
| FR-004 | State Machine：PENDING→RUNNING→SUCCEEDED/FAILED/CANCELLED；FAILED→RETRYING→RUNNING；状态变更 emit 事件 | AC-MAE-005 | TC-MAE-005 | - | ✅ |
| FR-005 | Error Recovery：retryPolicy 重试；fallback 策略（FAIL_WORKFLOW/SKIP_NODE/RUN_FALLBACK）；逆拓扑回滚 compensable 节点 | AC-MAE-006 | TC-MAE-006 | - | ✅ |
| FR-006 | Checkpoint and Resume：持久化 completedNodes/intermediateOutputs/timestamp；从最后 Checkpoint 恢复；已完成节点不重复 | AC-MAE-007 | TC-MAE-007 | - | ✅ |
| FR-007 | Conditional Branching：CONDITION 节点评估表达式走 thenBranch/elseBranch；分支汇聚 | AC-MAE-008 | TC-MAE-008 | - | ✅ |
| FR-008 | Parallel Execution：并发执行子节点；failFast 立即终止；maxConcurrency 限制 | AC-MAE-009 | TC-MAE-009 | - | ✅ |
| FR-009 | Workflow Registry：名称全局唯一；运行时注册/更新不影响已运行实例；List/Get/Delete | AC-MAE-010 | TC-MAE-010 | - | ✅ |
| FR-010 | Module Identity：README H1 为 `# maestro`；Go module path 为 `github.com/ZoneCNH/maestro` | AC-MAE-011 | TC-MAE-011 | - | ✅ |

---

## 2. 业务规则追溯（BR）

| BR | Description | 违反后果 | 验证方式 | Task | Status |
|----|-------------|----------|----------|------|--------|
| BR-001 | DAG 必须有且仅有一个 Start 和一个 End | TC-MAE-001 | TC-MAE-001 Start/End 唯一性断言 | ✅ | |
| BR-002 | DAG 不得包含循环依赖 | TC-MAE-001 | TC-MAE-001 循环检测断言 | ✅ | |
| BR-003 | 节点重试耗尽后必须执行 fallback 策略 | TC-MAE-006 | TC-MAE-006 fallback 执行验证 | ✅ | |
| BR-004 | Checkpoint 必须持久化（不可仅内存） | TC-MAE-007 | TC-MAE-007 持久化验证 | ✅ | |
| BR-005 | 回滚仅适用于 compensable 节点 | TC-MAE-006 | TC-MAE-006 compensable 过滤断言 | ✅ | |
| BR-006 | 工作流定义变更不影响已运行实例 | TC-MAE-010 | TC-MAE-010 运行时注册/更新不影响已运行实例 | ✅ | |

---

## 3. 非功能需求追溯（NFR）

| NFR | Description | 目标值 | 验证方式 | Task | Status |
|-----|-------------|--------|----------|------|--------|
| NFR-001 | DAG 校验 (50 节点) 性能 | < 10ms | Benchmark | - | ✅ |
| NFR-002 | 节点调度延迟 | < 1ms | Benchmark | - | ✅ |
| NFR-003 | Checkpoint 写入延迟 | < 50ms | Benchmark | - | ✅ |
| NFR-004 | 工作流恢复延迟 | < 100ms | Benchmark | - | ✅ |
| NFR-005 | 测试覆盖率 | >= 80% | `go tool cover -func` | - | ✅ |
| NFR-006 | 无硬编码密钥 | 全仓扫描零命中 | `gitleaks detect --no-git` | - | ✅ |

---

## 4. TC → FR 反向追溯

| TC | FR/BR | Given/When/Then 场景 |
|----|-------|---------------------|
| TC-MAE-001 | FR-001, BR-001, BR-002 | Workflow DAG 创建：唯一 Start/End 节点；循环依赖检测报错 |
| TC-MAE-002 | FR-001 | Node 定义包含 name/type/config/retryPolicy/timeout 五个字段 |
| TC-MAE-003 | FR-002 | 支持 6 种 Task 类型；未支持的类型创建失败 |
| TC-MAE-004 | FR-003 | Workflow 按拓扑排序执行；节点超时按策略处理；返回 WorkflowResult |
| TC-MAE-005 | FR-004 | 状态机转换正确；每次状态变更 emit workflow.state_change 事件 |
| TC-MAE-006 | FR-005, BR-003, BR-005 | 节点失败按 retryPolicy 重试；fallback 执行；逆拓扑回滚 compensable 节点 |
| TC-MAE-007 | FR-006, BR-004 | Checkpoint 持久化 completedNodes/intermediateOutputs/timestamp；恢复从最后 Checkpoint 继续；已完成节点不重复 |
| TC-MAE-008 | FR-007 | CONDITION 节点评估表达式走 thenBranch/elseBranch；分支汇聚 |
| TC-MAE-009 | FR-008 | PARALLEL 并发执行子节点；failFast 任一失败终止；maxConcurrency 限制 |
| TC-MAE-010 | FR-009, BR-006 | Workflow 注册名称全局唯一；运行时注册/更新不影响已运行实例；List/Get/Delete |
| TC-MAE-011 | FR-010 | README H1 为 `# maestro`；go.mod 声明 `module github.com/ZoneCNH/maestro` |

---

## 5. 全局 AC 注册表

| AC | 所属 FR/BR | 验收条件摘要 |
|----|-----------|-------------|
| AC-MAE-001 | FR-001 | DAG 循环依赖检测报错；唯一 Start 和 End 节点 |
| AC-MAE-002 | FR-001 | 每个 Node 定义含 name/type/config/retryPolicy/timeout |
| AC-MAE-003 | FR-002 | 支持 6 种 Task 类型；未支持类型创建失败 |
| AC-MAE-004 | FR-003 | 拓扑排序执行；超时按策略处理；返回 WorkflowResult |
| AC-MAE-005 | FR-004 | 状态机转换正确；每次变更 emit 事件 |
| AC-MAE-006 | FR-005 | 重试+fallback+逆拓扑回滚 compensable 节点 |
| AC-MAE-007 | FR-006 | Checkpoint 持久化；恢复从最后 Checkpoint 继续；不重复执行 |
| AC-MAE-008 | FR-007 | CONDITION 评估表达式走 then/else 分支；分支汇聚 |
| AC-MAE-009 | FR-008 | PARALLEL 并发执行；failFast；maxConcurrency |
| AC-MAE-010 | FR-009 | 注册名称全局唯一；运行时更新不影响已运行实例；List/Get/Delete |
| AC-MAE-011 | FR-010 | README H1 为 `# maestro`；go.mod 声明 `module github.com/ZoneCNH/maestro` |

---

## 6. 覆盖率仪表盘

| 指标 | 数值 | 说明 |
|------|------|------|
| FR 总数 | 10 | FR-001 ~ FR-010 |
| FR 有 AC 覆盖 | 10/10 (100%) | FR-001 有 2 条 AC |
| FR 有 TC 覆盖 | 10/10 (100%) | |
| BR 总数 | 6 | BR-001 ~ BR-006 |
| BR 有 TC 覆盖 | 6/6 (100%) | |
| NFR 总数 | 6 | NFR-001 ~ NFR-006 |
| AC 总数 | 11 | AC-MAE-001 ~ AC-MAE-011 |
| TC 总数 | 11 | TC-MAE-001 ~ TC-MAE-011 |

---

## 7. 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-15 | v1.0 | 初始版本：10 FR + 6 BR + 6 NFR + 11 TC + 11 AC |
