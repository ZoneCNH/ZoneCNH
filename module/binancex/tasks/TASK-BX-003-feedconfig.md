# TASK-BX-003 FeedConfig & Validation

## Objective

实现 `FeedConfig` 传输层配置、`DefaultFeedConfig()` 默认值和 `Validate()` 校验。

## Scope

- `FeedConfig`: 9 字段传输层配置
- `DefaultFeedConfig()`: 生产安全默认值
- `Validate()`: 拒绝空 Endpoint、非正 ReadTimeout/PingInterval/EventBufferSize
- `FeedConfigError`: 结构化配置错误类型

## Covers

- FR-BX-003 (FeedConfig)
- FR-BX-005 (DefaultFeedConfig)
- FR-BX-006 (Validate)
- BR-BX-003 (reject invalid values)

## Deliverables

- `FeedConfig` 结构体含全部 9 字段
- `DefaultFeedConfig()` 返回非零默认值
- `Validate()` 拒绝 4 种非法配置
- `FeedConfigError` 含 Field/Message 字段

## Acceptance Criteria

1. FeedConfig 含 Endpoint/ReconnectBackoff/MaxReconnectBackoff/MaxReconnectAttempts/ReadTimeout/WriteTimeout/PingInterval/EventBufferSize/ErrorBufferSize
2. DefaultFeedConfig 所有字段为正数
3. Validate(Endpoint="") → error 含 "Endpoint"
4. Validate(ReadTimeout=0) → error 含 "ReadTimeout"
5. Validate(PingInterval=0) → error 含 "PingInterval"
6. Validate(EventBufferSize=0) → error 含 "EventBufferSize"

## Dependencies

- TASK-BX-002 (data types)
