# Binance Runtime Gates Recovery Evidence

> 日期：2026-07-09  
> runtime 仓：`/home/workspace/binance`  
> docs 仓：`/home/workspace/ZoneCNH`

## 1. 结论

本地 runtime P0 gate 已恢复：`go test ./...`、`go vet ./...`、`./scripts/boundary-gates.sh`、`./scripts/spec-runtime-drift-check.sh`、`git diff --check` 均通过。[COMPUTED, HIGH]

本轮额外执行 20 轮重复检查并全部通过；每轮覆盖 runtime 编译测试、`go vet`、boundary gate、drift gate、runtime `git diff --check`、生产旧 event_type 输出扫描、主仓 docs gate 和主仓 `git diff --check`。[COMPUTED, HIGH]

最终状态检查时，runtime 当前工作树已再次执行完整 `go test ./... -count=1` 并通过。[COMPUTED, HIGH]

本轮已生成本地 release evidence bundle：`/home/workspace/binance/release/evidence/binance/20260709-canonical-recovery`；其 `status.txt` 全部 PASS，`external-gates.log` 记录 `live_binance_websocket=NOT_CAPTURED`、`natsx_jetstream_puback_manualack=CORE_ENVELOPE_ADAPTER_PRESENT_JETSTREAM_ACK_NOT_CAPTURED`、`external_durable_storage_fanout_query=PACKAGE_BOUNDARY_PRESENT_EXTERNAL_IO_NOT_CAPTURED`、`remote_github_actions=NOT_CAPTURED`、`release_tag=NOT_CAPTURED`、`release_closeable=NO`。[COMPUTED, HIGH]

本证据不是最终 release evidence；远端 CI、release tag、live capture、外部依赖 E2E 和 rollback 仍需独立闭合。[COMPUTED, HIGH]

## 2. 修复摘要

| 修复项 | 证据 |
| --- | --- |
| canonical event_type | client/server/storage/API 测试已覆盖 `book_ticker/kline/depth_update/mark_price_update` 输出与旧别名输入兼容。[COMPUTED, HIGH] |
| NATS/Kafka topic | publisher 与 Kafka dispatch 测试验证 subject/topic/header 使用 canonical event_type。[COMPUTED, HIGH] |
| TDengine/history/cache | storage、taosdriver、assembly、api 测试验证 canonical stable/key/query 语义。[COMPUTED, HIGH] |
| ReconnectQueue | client 测试覆盖 stop/enqueue 并发关闭语义。[COMPUTED, HIGH] |
| drift gate | `internal/ingestcodec/doc.go` 已补 shared boundary 说明，`spec-runtime-drift-check.sh` PASS。[COMPUTED, HIGH] |

## 3. 本地命令结果

| 命令 | 结果 |
| --- | --- |
| `go test ./... -count=1` | PASS。[COMPUTED, HIGH] |
| `go test ./... -race -count=1` | PASS。[COMPUTED, HIGH] |
| `go vet ./...` | PASS。[COMPUTED, HIGH] |
| `golangci-lint run` | PASS。[COMPUTED, HIGH] |
| `./scripts/boundary-gates.sh` | 15 passed, 0 failed。[COMPUTED, HIGH] |
| `./scripts/spec-runtime-drift-check.sh` | PASS。[COMPUTED, HIGH] |
| `XGO_BINANCE_SMOKE_SELF_TEST=1 go run ./cmd/binance-smoke` | PASS。[COMPUTED, HIGH] |
| `make test-gated` | PASS；30s soak PASS，本地 chaos PASS，真实外部依赖 chaos 按环境缺失 SKIP。[COMPUTED, HIGH] |
| `git diff --check` | PASS。[COMPUTED, HIGH] |
| `./scripts/runtime-release-evidence.sh` | PASS；bundle: `/home/workspace/binance/release/evidence/binance/20260709-canonical-recovery`。[COMPUTED, HIGH] |
| 20 轮重复检查 | PASS；日志目录：`/tmp/binance-20check-20260709210216`。[COMPUTED, HIGH] |

## 4. 剩余证据

- [ ] 远端 CI 对同一 commit 运行测试与 gate。[FRAME, HIGH]
- [ ] live WS capture 与 NATS/Kafka/TDengine/Redis/API E2E。[FRAME, HIGH]
- [ ] release tag、release notes、rollback checklist。[FRAME, HIGH]

[RULES I BROKE]：无
