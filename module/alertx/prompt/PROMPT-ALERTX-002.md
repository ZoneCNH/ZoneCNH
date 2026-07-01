# TASK-ALERTX-002 开发 Prompt

> 规则引擎核心：YAML DSL 解析 + 评估器 + 热加载

- 上游 Task：[TASK-ALERTX-002.md](../tasks/TASK-ALERTX-002.md) | Spec：[SPEC.md#FR-001](../SPEC.md) | ADR：[ADR-001 D3](../ADR-001-foundations.md)

## 任务

实现规则 DSL 解析器（`metric:op:value` 三段式 + AND 组合）、RuleEvaluator 接口、RuleStore 热加载。

## 关联需求

| 类型 | 编号 | AC | TC |
| --- | --- | --- | --- |
| FR | FR-001 | AC-001 | TC-001, TC-002, TC-003 |
| FR | FR-007 | AC-007 | TC-015, TC-019 |
| BR | BR-003 | AC-010 | TC-004 |
| BR | BR-004 | AC-011 | TC-002 |

## 依赖

- 上游：TASK-001（errors.go 的 ErrRuleInvalid/ErrSuppressWindowZero/ErrRuleLoadFailed）
- contracts：`contracts.AlertRule`（ID/Name/Source/Severity/Condition/DedupKey/SuppressWindow/Channels/Enabled）

## 实现要点

1. `internal/config/rule_parser.go`：解析 YAML → `[]contracts.AlertRule`
   - Condition DSL：`metric:<name> <op> <value>`（op: >, <, >=, <=, ==, !=），多条件用 ` AND ` 连接
   - 校验：必填字段（ID/Source/Severity/Condition）、Severity 合法、SuppressWindow 非零（零则用全局默认，BR-003）、Channel ID 已定义（BR-005）
   - 非法 → `ErrRuleInvalid`（阻塞启动，BR-004）
2. `pkg/alertx/rule.go`：RuleStore 实现（contracts.AlertRuleStore），内存 `[]AlertRule` + `sync.RWMutex`
   - `Load(ctx)` 返回当前规则快照
   - 热加载：轮询 `reload_interval`，校验通过原子替换，失败保留旧规则集（FR-007）
3. `pkg/alertx/evaluator.go`：RuleEvaluator 实现
   - `Evaluate(ctx, input)`：遍历规则，匹配 Condition，产出 `[]contracts.AlertEvent`
   - input 是归一化 Event（TASK-006 定义，本 task 用占位 interface）

## 验证

```bash
cd /home/workspace/alertx && GOWORK=off go test ./internal/config/... -run TestRuleParser -v
GOWORK=off go test ./pkg/alertx/... -run 'TestRuleEvaluator|TestRuleReload' -race -v
```

## 关键测试

- `TestRuleEvaluator_LoadValid`：合法 YAML → rules_loaded gauge 正确
- `TestRuleEvaluator_LoadInvalid`：缺字段/未知 op/零窗口 → ErrRuleInvalid
- `TestRuleEvaluator_EvaluateMatch`：事件匹配 → AlertEvent
- `TestRuleReload_HotReload`：文件变更 → 原子替换
- `TestRuleReload_ConcurrentWithEval`：-race，热加载与评估并发
