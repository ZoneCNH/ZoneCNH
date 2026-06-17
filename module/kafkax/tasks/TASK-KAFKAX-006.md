---
scope: "TASK-KAFKAX-006: go.mod + 单元/集成测试 + benchmark + README + CHANGELOG"
acceptance_criteria: []
---

# TASK-KAFKAX-006: CI + Release 基线

- **Module**: kafkax
- **Phase**: CI + Release (Phase 4)
- **Priority**: P2
- **Dependencies**: none
- **Status**: Done

## Scope

配置 go.mod、单元测试、集成测试、benchmark、README、CHANGELOG

## Non-Scope

Does NOT implement Kafka broker deployment, topic auto-creation, or Kafka Connect integration. Does NOT implement business event semantics or domain DTOs.

## Files

- `/home/kafkax/go.mod` / `go.sum` — `module github.com/ZoneCNH/kafkax`, go 1.23, `segmentio/kafka-go v0.4.51`
- `/home/kafkax/Makefile` — `make ci` / `make ci-extended` / `make evidence` gate 链
- `/home/kafkax/README.md` — API 参考、Kafka 语义、Driver-Neutral、配置、健康检查、Metrics、错误模型（v0.4.13）
- `/home/kafkax/CHANGELOG.md` — 版本历史，最新 `v0.4.13`
- `/home/kafkax/pkg/kafkax/version.go` — `Version = "v0.4.13"`
- `/home/kafkax/testkit/` — `KafkaFake` fake runtime、golden 断言
- `/home/kafkax/cmd/goalcli/` — goal 治理 CLI + 版本一致性测试
- `/home/kafkax/scripts/` — CI gate 与 evidence 脚本

## Acceptance

- [x] CI gate + benchmark + docs verified

## Evidence

- go build：`go build ./...` ✅ 零错误
- go test：`go test ./...` ✅ 全包通过（pkg/kafkax, internal/*, examples, testkit, contracts, cmd/goalcli, scripts）
- 版本一致性：`TestVersionConstantsTrackChangelogRelease` ✅（README 补 v0.4.13 后通过，commit `ba851eb`）
- README 版本同步修复：`ba851eb docs: kafkax README 补 v0.4.13 版本声明`（kafkax 仓库 `fix/kafkax-consumer-config-and-readme-version` 分支）
- DoD：godoc / examples / CHANGELOG / README / coverage / vet / secret 扫描由 Makefile gate 链覆盖

## Non-scope

- 不涉及本 Task 范围外的功能
