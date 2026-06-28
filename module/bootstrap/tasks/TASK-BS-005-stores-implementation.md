# TASK-BS-005 Stores Implementation (v0.2.0)

## Objective

实现非 None Stores 构造：Spec.Stores 位掩码控制存储构造，TD/PG 组合与其他非 None 位组合接入。清理 foundationx 遗留依赖（OQ-004）。

## Scope

- Spec.Stores 位掩码解析与存储构造
- Stores=All、TD/PG 组合路径
- foundationx 遗留依赖清零（OQ-004）
- v0.2.0 准入项

## Covers

- FR-004 stores 可选构造（非 None 部分）
- BR-006 仅聚合层可使用非 None Stores
- AC-006 foundationx 遗留依赖按 OQ-004 清零

## Acceptance Criteria

1. Stores=All 端到端构造通过
2. TD/PG 组合存储适配器接入
3. foundationx 遗留 import 清零（go list -deps 验证）
4. boundary gate 通过

## Dependencies

- TASK-BS-001 (Stores=None baseline)
- kernel / configx / observex
