---
scope: "TASK-KAFKAX-005: Consumer 配置校验 max_poll_records/session_timeout/heartbeat_interval"
acceptance_criteria: []
---

# TASK-KAFKAX-005: Consumer 配置校验

- **Module**: kafkax
- **BR_ref**: module/kafkax/SPEC.md#BR-006
- **Phase**: Health + Observability (Phase 3)
- **Priority**: P1
- **Dependencies**: none
- **Status**: Done

## Scope

实现 Consumer 配置校验：max_poll_records/session_timeout/heartbeat_interval

## Non-Scope

Does NOT implement Kafka broker deployment, topic auto-creation, or Kafka Connect integration. Does NOT implement business event semantics or domain DTOs.

## Files

- `/home/workspace/kafkax/pkg/kafkax/config.go:39` — `Config.Validate()`
- `/home/workspace/kafkax/pkg/kafkax/config.go:51` — `SessionTimeout < 0` 校验
- `/home/workspace/kafkax/pkg/kafkax/config.go:114-118` — `ConsumerConfig{GroupID, SessionTimeout, HeartbeatInterval, MaxPollRecords, StartOffset}`
- `/home/workspace/kafkax/pkg/kafkax/kafkago/consumer.go:33-35` — SessionTimeout 透传 ReaderConfig
- `/home/workspace/kafkax/pkg/kafkax/kafkago/consumer.go:36-38` — HeartbeatInterval 透传 ReaderConfig
- `/home/workspace/kafkax/pkg/kafkax/config_test.go` — `TestConfigValidateRejectsNegativeHeartbeatInterval` / `...MaxPollRecords`

## Acceptance

- [x] BR-006 verified — `go test -race -run="Config" ./pkg/kafkax/...`

## Evidence

- 校验：`Config.Validate()` 拒绝 `SessionTimeout<0`、`HeartbeatInterval<0`、`MaxPollRecords<0`，返回 `ErrorKindValidation`（BR-006）
- 配置补齐 commit：`3277b71 feat(kafkax): ConsumerConfig 暴露 HeartbeatInterval/MaxPollRecords 并加校验`（kafkax 仓库 `fix/kafkax-consumer-config-and-readme-version` 分支）
- MaxPollRecords 偏差说明：`segmentio/kafka-go` Reader 按 `ReadMessage` 单条消费，无原生 per-poll 记录上限；该字段在 Config 层校验合法性，实际批次粒度由调用方 Poll 循环控制（driver 注释已说明）
- 测试：`go test ./pkg/kafkax/` ✅
- 追溯：TRACEABILITY.md BR-006 ✅

## Non-scope

- 不涉及本 Task 范围外的功能
