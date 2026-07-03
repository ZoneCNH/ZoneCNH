# TASK-FRED-SERVER-002 Query + Admin API

## Objective

实现 `fred-server` 查询与管理接口（含覆盖审计接口），并输出 `ms_brain` 所需的最小契约能力。

## Covers

- FR-S008, FR-S009, FR-S011
- FR-015 / BR-009（根规格）

## Acceptance Criteria

1. Query API 支持 as-of/no-lookahead 查询。
2. Admin API 具备鉴权、审计和 NATS control 联动。
3. `ms_brain` fixture 可消费初始序列锚点与发布/修订事件。
4. 覆盖审计 API 可返回六域覆盖率与缺口分片。

## Dependencies

- `contracts`, `transportx`
- `domain_macro`
