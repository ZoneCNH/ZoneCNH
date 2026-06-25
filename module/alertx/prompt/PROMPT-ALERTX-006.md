# TASK-ALERTX-006 开发 Prompt

> 双订阅：observex 导出流 + 业务事件订阅 + 事件归一化

- 上游 Task：[TASK-ALERTX-006.md](../tasks/TASK-ALERTX-006.md) | Spec：[SPEC.md#5](../SPEC.md) | ADR：[ADR-001 D2](../ADR-001-foundations.md)

## 任务

实现双订阅架构（ADR-001 D2）：订阅 observex Exporter + 订阅业务 contracts.AlertEvent，归一化为统一评估输入。

## 关联需求

| 类型 | 编号 | AC | TC |
| --- | --- | --- | --- |
| FR | FR-001（输入侧） | — | TC-014 |
| EC | EC-005 | — | TC-012 |
| EC | EC-007 | — | TC-014 |

## 依赖

- 上游：TASK-002（RuleEvaluator.Evaluate 接受归一化 Event）
- observex：Exporter 接口（ExportLogs/ExportMetrics/ExportSpans）+ LogEntry/MetricPoint/SpanData 类型
- contracts：AlertEvent envelope（业务侧订阅）

## 实现要点

1. `internal/subscribe/observex_subscriber.go`：实现 observex Exporter 接口
   - ExportLogs/ExportMetrics/ExportSpans 接收数据，转 Event 推入评估通道
   - observex 中断时 health 标 degraded，业务侧订阅继续（EC-007/TC-014）
2. `internal/subscribe/business_subscriber.go`：订阅业务 contracts.AlertEvent
   - 通过 channel/Event envelope 接收业务域 emit 的告警事件
3. `internal/subscribe/normalizer.go`：归一化
   - observex LogEntry/MetricPoint/SpanData + 业务 AlertEvent → 统一 `Event`（评估输入）
   - Event 携带 Source/Subject/Value/TraceID/原始类型，供 RuleEvaluator.Evaluate 匹配 Condition
   - 未知 metric 引用：运行时该规则不匹配（EC-005/TC-012）

## 验证

```bash
cd /home/alertx && GOWORK=off go test ./internal/subscribe/... -run TestNormalizer -race -v
```

## 关键测试

- `TestNormalizer_MetricPoint`：MetricPoint → Event（metric name/value 正确映射）
- `TestNormalizer_BusinessAlert`：AlertEvent → Event（保留 severity/source）
- `TestSubscribe_ObservexInterrupt`：EC-007，observex 中断 → health degraded
- `TestRuleEvaluator_UnknownMetric`：EC-005，未知 metric 运行时不匹配
