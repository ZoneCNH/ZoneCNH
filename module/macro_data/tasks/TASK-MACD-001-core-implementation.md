# TASK-MACD-001 Core Implementation

## Objective

实现 macro_data 宏观数据接收侧：dispatch port、幂等判定、revision 排序、no-lookahead gate、MacroDataProvider。

## Covers

- FR-MACD-001 dispatch-port
- FR-MACD-002 canonical-input
- FR-MACD-003 idempotency
- FR-MACD-004 revision-ordering
- FR-MACD-005 no-lookahead-gate
- FR-MACD-006 quality-gate
- FR-MACD-007 retry-classification
- FR-MACD-008 batch-semantics
- FR-MACD-009 observability
- FR-MACD-010 downstream-port

## Acceptance Criteria

1. Contract Gate 通过 (MacroDataProvider 已定义)
2. No-lookahead gate fail-closed 测试覆盖
3. 镜像 market_data 接收侧设计

## Dependencies

- domain_macro (MacroPoint canonical)
- contracts (MacroDataProvider)
- market_data (镜像参考)
