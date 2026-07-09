# Binance TODO Closure Review — 2026-07-10

> [COMPUTED, HIGH] 本文件记录 `module/binance/todo.md` 本轮 closure audit 的可复核结果；它是 dated evidence，不替代 runtime release packet 或 GitHub Release。

## 绑定版本

| 项目 | 值 |
| --- | --- |
| Zone feature branch | `fix/binance-todo-closure-20260710` |
| Runtime implementation commit | `3f6366728b635c32d73565874965d40c20a92caf` |
| Runtime evidence commit | `660a3701589cc15fa95c7859fae02fad4863e1ad`（ledger runner 仍绑定 implementation commit） |
| Last published runtime tag | `v0.15.1` @ `fc967053d7d8c21dba3c4e93962effbbbba0a70c` |
| Runtime evidence | `/home/workspace/binance/release/evidence/binance/20260710` |
| External ledger | `release/evidence/binance/20260710/external-gates.tsv` |

## 实现闭合

[COMPUTED, HIGH] 本轮 runtime 已完成 `ticker`、`open_interest`、`index_reference`、`contract_info` 的 normalize → mapper → allowlist/API → history/hot-cache → TDengine stable/driver/DDL → reconcile/retention 本地链路；`force_order` 为独立 opt-in scaffold，Options depth 为 fixture/capture 能力，OrderBookManager 仍 excluded/postponed。

[COMPUTED, HIGH] connector 已支持数组 payload 展开与全局 `!contractInfo` stream；`force_order` 订阅 symbol 与嵌套订单 symbol 不一致时拒绝。新增 release notes candidate、packet template/validator、external gate runner、Options depth official fixtures 与 public opt-in capture。

## 验证结果

| 检查 | 结果 |
| --- | --- |
| `env GOROOT=/usr/local/go GOWORK=off go test ./... -count=1` | PASS |
| `env GOROOT=/usr/local/go GOWORK=off go test ./... -race -count=1` | PASS |
| `env GOROOT=/usr/local/go GOWORK=off go build ./...` | PASS |
| `env GOROOT=/usr/local/go GOWORK=off go vet ./...` | PASS |
| `./scripts/boundary-gates.sh` | 15/15 PASS |
| `./scripts/spec-runtime-drift-check.sh` | PASS |
| `go test -tags=e2e ./test/e2e -count=1` | PASS；未配置的 live tests 明确 SKIP |
| `BINANCE_OPTIONS_DEPTH_LIVE=1 ... TestOptionsDepthLiveCapture` | PASS；partial/diff 各 3 条，单侧 diff 按设计拒绝 normalize |
| `BINANCE_NATSX_INTEGRATION=1 ... TestNATSXIntegrationJetStreamSemantics` | PASS；local ephemeral NATS，不替代远端证据 |
| release scripts `bash -n` | PASS |
| Zone docs/version/reference gates | PASS |

## 20 轮结果

[COMPUTED, HIGH] 执行 [`scripts/binance-final-20-check.sh`](../../../../../scripts/binance-final-20-check.sh)，日志根目录为 `/tmp/binance-final-20check-20260710-final2`；`SUMMARY.tsv` 记录 `round=01` 至 `round=20` 全部 PASS，脚本 exit 0。

[COMPUTED, HIGH] 每轮重复执行完整 `go test ./... -count=1`、build、vet、boundary、drift、Options/e2e fixture、脚本语法、runtime diff、external ledger 绑定/形状、packet validator 预期阻断、Zone diff、docs、version、reference 与 todo anchors；没有遗漏轮次。

## 尚未完成的真实外部门禁

[COMPUTED, HIGH] `scripts/run-external-gates.sh` 的最终 ledger 为 `PASS=0 BLOCKED=5 SKIP=0 ERROR=0`。五项为远端 NATS PubAck/ManualAck、Kafka fanout、TDengine latest/range、Redis latest/range、部署 API latest/range；原因是所需目标环境/凭证未提供。不得将 local fake、fixture 或本地 NATS 结果升格为这些 gate 的 PASS。

[COMPUTED, HIGH] `scripts/validate-release-packet.sh --packet docs/release/release-packet.template.yaml --runtime-root .` 返回 11 blockers；本轮未创建新 tag、未执行真实部署或 rollback，也未写入任何凭证。

[RULES I BROKE]：无
