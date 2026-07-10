# Binance Runtime Release Evidence

> 日期：2026-07-10。[COMPUTED, HIGH]
> runtime 仓：`/home/workspace/binance/.worktree/workspaces/fix/binance-production-readiness-20260710`。[COMPUTED, HIGH]
> docs 仓：`/home/workspace/ZoneCNH`。[COMPUTED, HIGH]

## 1. 结论

本轮 `scripts/runtime-release-evidence.sh` 已按当前 toolchain 成功生成本地证据目录，但没有获得真实外部 E2E、正式 tag、release notes 或 rollback 闭环，因此 `release_closeable=NO`，不能把本轮状态解释为可发布。[COMPUTED, HIGH]

`BINANCE_EXTERNAL_GATES_OFFLINE=1` 时，`run-external-gates.sh` 生成的 `external-gates.tsv` 为五项 `BLOCKED/NOT_RUN`，这与“没有凭证、没有批准外部命令、没有外部 proof marker”一致。[COMPUTED, HIGH]

## 2. 本轮证据摘要

| 证据 | 结果 |
| --- | --- |
| `gofmt -l cmd internal pkg test tools` | PASS。[COMPUTED, HIGH] |
| `go build ./...` | PASS。[COMPUTED, HIGH] |
| `go test ./internal/client -run TestHistoryRuntimePersistsAndRestoresState -count=1 -v` | PASS。[COMPUTED, HIGH] |
| `go test ./internal/client -run TestPostgresHistoryStateStoreSaveLoadAndSchema -count=1 -v` | PASS。[COMPUTED, HIGH] |
| `go test ./internal/server -run TestAdminDeadLetterReplayEndpointReplaysOnce -count=1 -v` | PASS。[COMPUTED, HIGH] |
| `go test ./internal/server -run TestAdminDeadLetterReplayEndpointReadsConfiguredFile -count=1 -v` | PASS。[COMPUTED, HIGH] |
| `go test ./internal/server -run TestAdminDeadLetterReplayEndpointPersistsFileReplayAcrossRestart -count=1 -v` | PASS。[COMPUTED, HIGH] |
| `go test ./internal/server -run TestAppendDeadLetterWritesConfiguredFileWriter -count=1 -v` | PASS。[COMPUTED, HIGH] |
| `go test ./internal/server/deadletter -run TestReadFile -count=1 -v` | PASS。[COMPUTED, HIGH] |
| `./scripts/boundary-gates.sh` | FAIL，仍卡在 §17 `CICD-001 self-hosted runner pool`。[COMPUTED, HIGH] |
| `go test ./... -count=1` | FAIL，`internal/client` 与 `test` 中仍有既有失败。[COMPUTED, HIGH] |
| `go test ./... -race -count=1` | FAIL，继续暴露既有失败与构建缺口。[COMPUTED, HIGH] |
| `go vet ./...` | FAIL，`internal/client/orderbook` 仍有测试/类型不匹配。[COMPUTED, HIGH] |
| `golangci-lint run` | FAIL，当前 lint 二进制与目标 Go 版本不匹配。[COMPUTED, HIGH] |
| `XGO_BINANCE_SMOKE_SELF_TEST=1 go run ./cmd/binance-smoke` | PASS。[COMPUTED, HIGH] |
| `retired HTTP ingest transport guard` | FAIL，当前证据包仍记录为失败项。[COMPUTED, HIGH] |
| `external gates runner` | BLOCKED/NOT_RUN，五个 gate 全部缺少外部命令或凭证。[COMPUTED, HIGH] |
| `release_closeable` | NO。[COMPUTED, HIGH] |

## 3. 语义边界

- 这份证据只证明本地门禁与证据生成语义，不证明真实外部 release 已闭合。[COMPUTED, HIGH]
- 真实外部 JetStream PubAck/ManualAck、Kafka fanout、TDengine latest/range、Redis latest/range、API latest/range 仍然需要 operator 提供短期凭证和批准命令。[COMPUTED, HIGH]
- 正式 tag、release notes 和 rollback 仍属于发布系统或人工操作层，不应由本地脚本伪造。[COMPUTED, HIGH]

[RULES I BROKE]：无
