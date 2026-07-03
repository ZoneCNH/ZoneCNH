# TASK-FRED-CLIENT-002 domain_macro Mapping

## Objective

实现 FRED DTO 到 `domain_macro` 的稳定映射，并确保 observation + catalog（category/tag/source）所需字段完整且可追溯。

## Covers

- FR-C004, FR-C007, FR-C008
- BR-C001, BR-C003

## Acceptance Criteria

1. 映射结果包含 `released_at/available_at/vintage_at/observed_at`。
2. 不输出 provider DTO 作为外部契约。
3. category/tag/source 元数据映射具备单测覆盖。
4. 映射与可见性规则具备单测覆盖。

## Dependencies

- `domain_macro`
- `pkg/fredx`
