# Binance Runtime Gates Recovery Evidence

> 日期：2026-07-09  
> runtime 仓：`/home/workspace/binance`  
> docs 仓：`/home/workspace/ZoneCNH`
> runtime merged fix commit：`cc51916b9c7686128433465844cf436330260f8c`（PR #486）

## 1. 结论

本地 runtime P0 gate 已恢复：`go test ./...`、`go vet ./...`、`./scripts/boundary-gates.sh`、`./scripts/spec-runtime-drift-check.sh`、`git diff --check` 均通过。[COMPUTED, HIGH]

本轮额外执行最终 20 轮重复检查并全部通过；每轮覆盖 runtime targeted tests、boundary gate、readiness audit、legacy contract scan、runtime `git diff --check`、主仓 docs gate、版本一致性、引用完整性和主仓 `git diff --check`；日志目录为 `/tmp/binance-final-20check-20260709221859`。[COMPUTED, HIGH]

最终状态检查时，runtime 当前工作树已再次执行 `GOTOOLCHAIN=go1.26.5+auto scripts/run-full-validation.sh --skip-health` 并通过；该入口覆盖 build、vet、全量测试、race、boundary、专项测试、版本一致性和引用完整性。[COMPUTED, HIGH]

本轮 release evidence bundle 位于 `/home/workspace/binance/release/evidence/binance/20260709`；PR #486 已把后续 gate 修复和 evidence 日志合入 runtime `main`，merge commit 为 `cc51916b9c7686128433465844cf436330260f8c`。[COMPUTED, HIGH]

当前 `external-gates.log` 记录 `live_binance_websocket=CAPTURED_MAINNET_FOUR_PRODUCT_LINES`、`external_durable_storage_fanout_query=FAILED_CLICKHOUSE_AUTH_REDACTED`、`remote_github_actions=NOT_CAPTURED`、`release_tag=NOT_CAPTURED`、`release_closeable=NO`。[COMPUTED, HIGH]

本轮安全扫描记录在 runtime evidence bundle 的 `vuln-scan.log`：`govulncheck` 报告可达漏洞 0；`gitleaks` 8.30.1 扫描无泄漏。[COMPUTED, HIGH]

PR #486 远端 checks 已通过 Build/Vet、Unit Test & Race & Cover、golangci-lint、Security/gitleaks/govulncheck、Status Consistency、Boundary Gates、Benchmark Regression、Live E2E、Soak+Chaos；workflow 条件控制的 Integration/Gated/E2E jobs 为 SKIPPED。[COMPUTED, HIGH]

本证据不是最终 release evidence；release tag、release notes、外部 durable storage/fanout/query E2E 和 rollback 仍需独立闭合。[COMPUTED, HIGH]

## 2. 修复摘要

| 修复项 | 证据 |
| --- | --- |
| canonical event_type | client/server/storage/API 测试已覆盖 `book_ticker/kline/depth_update/mark_price_update` 输出与旧别名输入兼容。[COMPUTED, HIGH] |
| NATS/Kafka topic | publisher 与 Kafka dispatch 测试验证 subject/topic/header 使用 canonical event_type。[COMPUTED, HIGH] |
| TDengine/history/cache | storage、taosdriver、assembly、api 测试验证 canonical stable/key/query 语义。[COMPUTED, HIGH] |
| ReconnectQueue | client 测试覆盖 stop/enqueue 并发关闭语义。[COMPUTED, HIGH] |
| drift gate | `internal/ingestcodec/doc.go` 已补 shared boundary 说明，`spec-runtime-drift-check.sh` PASS。[COMPUTED, HIGH] |
| TDengine DDL | `migrations/taos_ddl.sql` 已对齐 `StableSpecs()` canonical stable；新增 DDL stable name drift 测试。[COMPUTED, HIGH] |
| server allowlist | `DefaultValidator` 已拒绝 planned/unknown event_type，允许 implemented canonical 与 legacy 输入 alias。[COMPUTED, HIGH] |

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
| `SOAK_DURATION=30s go test -tags=soak ./test/soak/ -run TestSoak_ServerStability -count=1 -timeout 5m` | PASS。[COMPUTED, HIGH] |
| `GOTOOLCHAIN=go1.26.5+auto make vuln-scan` | PASS；可达漏洞 0，`gitleaks` 无泄漏。[COMPUTED, HIGH] |
| `GOTOOLCHAIN=go1.26.5+auto BINANCE_MAINNET_LIVE=1 go test -tags=e2e ./test/e2e -run 'TestMainnetLive_' -count=1 -v -timeout 3m` | PASS；四产品线 mainnet WS capture 已生成。[COMPUTED, HIGH] |
| `GOTOOLCHAIN=go1.26.5+auto bash scripts/benchmark-regression.sh --threshold 20` | PASS；24 个 release-critical benchmark 无 regression。[COMPUTED, HIGH] |
| PR #486 remote checks | PASS/condition-skipped；关键 gate SUCCESS，Integration/Gated/E2E 条件 job SKIPPED。[COMPUTED, HIGH] |
| `git diff --check` | PASS。[COMPUTED, HIGH] |
| `./scripts/runtime-release-evidence.sh` | PASS；bundle: `/home/workspace/binance/release/evidence/binance/20260709`。[COMPUTED, HIGH] |
| 20 轮重复检查 | PASS；日志目录：`/tmp/binance-final-20check-20260709221859`。[COMPUTED, HIGH] |

## 4. 剩余证据

- [x] 远端 CI 对 PR #486 运行测试与 gate。[COMPUTED, HIGH]
- [x] live WS capture。[COMPUTED, HIGH]
- [ ] NATS/Kafka/TDengine/Redis/API 外部 durable E2E；当前被 ClickHouse 认证失败阻断。[COMPUTED, HIGH]
- [ ] release tag、release notes、rollback checklist；最新 release 仍为 `v0.15.1`，未覆盖 `cc51916b9c7686128433465844cf436330260f8c`。[COMPUTED, HIGH]

[RULES I BROKE]：无
