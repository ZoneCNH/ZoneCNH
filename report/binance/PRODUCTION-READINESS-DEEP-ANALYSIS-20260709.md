# Binance 模块生产级可发布深度分析

> 日期：2026-07-09  
> 分析对象：`module/binance/` 与运行时仓 `/home/workspace/binance`  
> 当前结论：本地 runtime P0 gate 已闭合；最终 release Go 仍需远端 CI、tag、live capture 和部署证据。[COMPUTED, HIGH]  
> 证据边界：本报告基于当前本地工作区和本地命令输出，不等同于 GitHub Release 或生产部署裁决。[COMPUTED, HIGH]

## 0. 反结论先行

本轮已修复此前阻断发布的本地 runtime 问题：canonical event_type 迁移、`ReconnectQueue` 停止竞态、spec/runtime drift 文档缺口，以及对应测试/golden fixture 漂移。[COMPUTED, HIGH]

`/home/workspace/binance` 当前本地验证结果为：`go test ./...` PASS、`go vet ./...` PASS、`./scripts/boundary-gates.sh` 15/15 PASS、`./scripts/spec-runtime-drift-check.sh` PASS、`git diff --check` PASS。[COMPUTED, HIGH]

本轮额外完成 20 轮重复检查并全部 PASS；每轮覆盖 runtime 编译测试、`go vet`、boundary gate、drift gate、runtime `git diff --check`、生产旧 event_type 输出扫描、主仓 docs gate 和主仓 `git diff --check`。[COMPUTED, HIGH]

本轮继续补齐本地 release evidence：`go test ./... -race -count=1` PASS、`golangci-lint run` PASS、binance smoke self-test PASS、`make test-gated` PASS，并生成 `/home/workspace/binance/release/evidence/binance/20260709-canonical-recovery`。[COMPUTED, HIGH]

仍不能直接宣布生产发布 Go，因为本轮没有证明远端 CI、release tag、release notes、回滚路径、live WS capture、NATS/Kafka/TDengine/Redis/API 实盘 E2E；runtime evidence bundle 也把这些外部项记录为 `NOT_CAPTURED`。[COMPUTED, HIGH]

## 1. 本次修复与验证

| 维度 | 修复内容 | 验证 |
| --- | --- | --- |
| canonical event_type | client normalize 输出 `book_ticker/kline/depth_update/mark_price_update`；旧 `tick/bar/depth/mark_price` 保留为输入 alias。[COMPUTED, HIGH] | `go test ./internal/client ./internal/client/publisher` PASS。[COMPUTED, HIGH] |
| wire contract | `BuildIngestRequest`、幂等键、Cleanse schema、mapper、NATS subject、Kafka topic/header 统一 canonical。[COMPUTED, HIGH] | `go test ./internal/server ./internal/server/api` PASS。[COMPUTED, HIGH] |
| storage/query | TDengine writer/history reader/retention config 与 hot cache fixture 使用 canonical stable/key。[COMPUTED, HIGH] | `go test ./internal/server/storage ./internal/server/storage/taosdriver ./internal/server/assembly` PASS。[COMPUTED, HIGH] |
| order book 派生事件 | TopN、incremental、rebuild 事件使用 `eventtypes` 常量。[COMPUTED, HIGH] | `go test ./internal/client/orderbook ./internal/client` PASS。[COMPUTED, HIGH] |
| ReconnectQueue | `Stop()` 可重复调用；停止后拒绝新入队；等待 slot/backoff 的 goroutine 可释放。[COMPUTED, HIGH] | ReconnectQueue 相关 client 测试随 `go test ./internal/client` 通过。[COMPUTED, HIGH] |
| drift gate | `internal/ingestcodec/doc.go` 补充 shared boundary 角色说明。[COMPUTED, HIGH] | `./scripts/spec-runtime-drift-check.sh` PASS。[COMPUTED, HIGH] |

## 2. 数据流架构图

```mermaid
flowchart LR
  BX[Binance Official Public APIs<br/>WS + REST] --> C1[binance-client]
  C1 --> C2[ExchangeInfo catalog]
  C2 --> C3[symbol tier + whitelist]
  C1 --> P1[parser + normalize]
  P1 --> M1[event mapper]
  M1 --> Q1[client quality cleanse]
  Q1 --> N1[NATS JetStream<br/>binance.market.product_line.event_type.v1]
  N1 --> S1[binance-server consumer]
  S1 --> V1[validation]
  V1 --> I1[idempotency<br/>redisx + pg log]
  I1 --> D1[durable processing]
  D1 --> T1[taosx raw time-series]
  D1 --> P2[postgresx metadata + audit + whitelist]
  D1 --> R1[redisx hot cache]
  D1 --> K1[kafkax downstream fanout]
  D1 --> O1[ossx cold archive]
  T1 --> C4[clickhousex OLAP]
  R1 --> API[Gin REST/Admin API]
  T1 --> API
  P2 --> API
```

该目标流与 C/S 分离设计一致：client 只连接 Binance 并发布，server 消费、校验、幂等、持久化、查询和 fanout。[INFERRED, HIGH]

## 3. 业务类型覆盖矩阵

| 业务类型 | 当前覆盖 | 发布口径 |
| --- | --- | --- |
| 现货 Spot | trade、book_ticker、kline、depth_update 标准化与下游测试通过。[COMPUTED, HIGH] | 公共行情覆盖；下单、账户、私有流不在 scope。[INFERRED, HIGH] |
| USDⓈ-M 合约 | mark_price_update、funding_rate、kline、depth_update、history routing 本地测试通过。[COMPUTED, HIGH] | 需要 live capture 和生产端点证据。[FRAME, HIGH] |
| COIN-M 合约 | CM product_line、kline/depth/mark/funding 代码路径与 fixture 测试通过。[COMPUTED, HIGH] | 交割合约 subtype 仍需 release evidence 复核。[INFERRED, MED] |
| Options | optionTicker、options depth normalize fixture 通过；options order book 仍按 Phase 2 管控。[COMPUTED, HIGH] | 不宣称 options order book 已完成。[INFERRED, HIGH] |
| Order Book | spot/UM/CM 本地状态机、TopN/增量派生事件和主路径测试通过。[COMPUTED, HIGH] | 需要 live depth snapshot + stream alignment evidence。[FRAME, HIGH] |
| 订单/账户/用户私有流 | SPEC 明确排除。[COMPUTED, HIGH] | 发布说明必须继续排除。[INFERRED, HIGH] |

## 4. 仍需补充的发布证据

| 证据 | 当前状态 | 风险 |
| --- | --- | --- |
| 远端 CI | 本轮未验证。[COMPUTED, HIGH] | 本地 PASS 不能替代远端 clean runner。[COMMON, HIGH] |
| release tag/release notes | 本轮未生成。[COMPUTED, HIGH] | 无法证明用户安装的是已验证 commit。[INFERRED, HIGH] |
| race/soak/chaos | `go test ./... -race -count=1` PASS；`make test-gated` 中 30s soak PASS，本地 chaos PASS，真实外部依赖 chaos SKIP。[COMPUTED, HIGH] | 真实 NATS/Redis/TDengine/Kafka 与 sudo 级 live chaos 仍需环境证据。[INFERRED, HIGH] |
| live WS capture | 本轮未执行。[COMPUTED, HIGH] | Binance 真实 payload 与 test fixture 仍可能漂移。[INFERRED, MED] |
| NATS/Kafka/TDengine/Redis/API E2E | 本轮只验证本地单元/集成测试。[COMPUTED, HIGH] | 外部依赖、凭证、网络、schema 权限仍需部署前证据。[INFERRED, HIGH] |
| 回滚路径 | 本轮未验证。[COMPUTED, HIGH] | 发布失败时无法证明可恢复。[INFERRED, HIGH] |

## 5. 模块规则与标准

需要保留并继续升级模块标准，不是从零建立。[INFERRED, HIGH]

当前已同步的规则与标准包括：`module/binance/gate/STANDARD.md` 覆盖业务边界、产品线矩阵、canonical event_type、合约身份、options、order book、Foundation 依赖、发布证据和 gate 职责；`module/binance/gate/RULES.md` 指向 goal-driven `spec/NAMING.md` 与 `gate/STANDARD.md`，并禁止 docs gate 因旧根 SPEC 缺失而 SKIP。[COMPUTED, HIGH]

后续必须把 runtime commit、CI run、release tag、evidence bundle 链接写入 release packet，避免规格 closeable 与运行时证据脱钩。[INFERRED, HIGH]

## 6. 迭代路线

### R0 Release Evidence

1. 在远端 CI 对同一 commit 跑 `go test ./...`、`go vet ./...`、boundary gates、drift gates。[FRAME, HIGH]
2. 生成 live WS capture 与 NATS/Kafka/storage/query E2E evidence。[FRAME, HIGH]
3. 生成 release tag、release notes、rollback checklist。[FRAME, HIGH]

### R1 业务能力补齐

1. 补 `ticker`、`open_interest`、`contract_info`、`index_reference`。[INFERRED, MED]
2. 对 `force_order` 单独建事件型数据流，不与状态型 ticker/book_ticker 混用。[INFERRED, MED]

### R2 Options 与 Order Book Phase 2

1. 建立 options depth 官方 payload capture 套件。[INFERRED, HIGH]
2. 明确 options order book 的订阅上限、underlying 维度、moneyness 策略与 fail-open/fail-closed 策略。[INFERRED, HIGH]
3. 再决定是否把 options 纳入 FR-052~061 的 Done 口径。[INFERRED, HIGH]

## 7. 关联证据

- [`module/binance/todo.md`](../../module/binance/todo.md)
- [`module/binance/evidence/2026-07-09/test/runtime-gates-recovery.md`](../../module/binance/evidence/2026-07-09/test/runtime-gates-recovery.md)
- [`module/binance/gate/STANDARD.md`](../../module/binance/gate/STANDARD.md)
- [`module/binance/gate/RULES.md`](../../module/binance/gate/RULES.md)
- [`module/binance/spec/NAMING.md`](../../module/binance/spec/NAMING.md)

## 8. 最终判断

`binance` 的本地 runtime P0 已从 No-Go 修复到 local gates PASS。[COMPUTED, HIGH]

生产发布仍应保持条件式 Go：只有当远端 CI、release tag、live capture、外部依赖 E2E、长时 soak、live chaos 与 rollback 证据补齐后，才能把本地 PASS 转为正式 release Go。[INFERRED, HIGH]

[RULES I BROKE]：无
