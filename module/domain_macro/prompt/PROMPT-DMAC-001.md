# PROMPT-DMAC-001

- Task：[../tasks/](../tasks/)
- Trace：[../TRACEABILITY.md](../TRACEABILITY.md)
- Spec：[../SPEC.md](../SPEC.md)

## 任务

实现 domain_macro 宏观领域模型：MacroPoint（三时间+revision）、MacroInformationSet、IsVisibleAt no-lookahead gate。

## 关联需求

FR-MAC-001~008（时间语义/revision/visibility/info-set/precision/state/provider-dto）。

## 要点

1. MacroPoint.ObservedAt/ReleasedAt/AvailableAt 三类时间
2. IsVisibleAt fail-closed（AvailableAt 缺失=不可见）
3. MacroInformationSet copy-on-write + deterministic
4. 公共 API 不暴露 provider DTO
