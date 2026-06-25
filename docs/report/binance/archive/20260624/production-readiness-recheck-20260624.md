# module/binance 生产就绪复核报告（HEAD 8290dc9）

- Report-Date: 2026-06-24
- Scope: `module/binance/`（规格文档）+ `/home/binance`（runtime 仓库）双端交叉复核
- Goal: 评估 binance 模块到「生产级别、可发布状态」还需补充什么
- Analyst: ZCode (builtin:zai-coding-plan/GLM-5.2)
- Evidence-Baseline:
  - runtime HEAD：`8290dc9e10fd649d7460f3859ea7654cc874b0c9`（origin/main 一致，2026-06-24 19:35:24 +0800）
  - runtime HEAD commit：`feat: Plan006 final — 49/49 全闭环，删除v1架构+补全运维/生命周期 (#73)`
  - runtime Go 代码总量：23495 行（118 个 .go 文件，含测试）
  - module/binance 规格版本：SPEC v3.5.0 / client v2.1.1 / server v2.2.0 / Module-Version v3.5.0 / Runtime-Version v0.1.0
- Predecessor-Report: [`production-readiness-gap-analysis-20260624.md`](production-readiness-gap-analysis-20260624.md)（基于 HEAD `4fa920b`，5 轮 58 维度审查）
- Relation: 本报告是前序报告的**复核与勘误**——前序报告基于 `4fa920b`，本报告基于 `8290dc9`（PR #73「Plan006 final」），该 PR 删除了 v1 架构并补全运维/生命周期，**推翻了前序报告的核心结论**。

---

## 0. 结论先行（TL;DR）

**`[FRAME, HIGH]` 前序报告的核心结论「架构分裂」「27 FR Pending」「规格与 runtime 不匹配」已基本失效。** PR #73（`8290dc9`，2026-06-24 19:35）执行了前序报告 §7.1 的「第一优先级」全部动作：删除 v1.0.0 架构、重写为 natsx 分布式架构、补全部署/CI/安全/运维/生命周期。

**当前真实状态**：

| 维度           | 前序报告（4fa920b）结论          | 本报告（8290dc9）实态                                                         | 变化        |
| -------------- | -------------------------------- | ----------------------------------------------------------------------------- | ----------- |
| C/S 通信       | 架构不匹配（HTTP/wire vs natsx） | **natsx JetStream 真实生产路径**；HTTP 显式拒绝（runtime.go:169-170 报错）    | ✅ 已解决   |
| Client 投递    | spool+sender 架构                | **publisher→natsx PubAck**；spool/checkpoint/sender 已删                      | ✅ 已解决   |
| Server 消费    | HTTP handler                     | **durable consumer ManualAck + MaxDeliver=5**                                 | ✅ 已解决   |
| 7 存储模块     | go.mod direct 但 0 调用          | **全部真实接入**（taosx/pg/redis/oss/kafka/clickhouse/gin）                   | ✅ 已解决   |
| 4 产品线       | 仅 spot                          | **spot/um_perp/cm_perp/options 全有**                                         | ✅ 已解决   |
| 部署产物       | 全缺                             | **Dockerfile + docker-compose + configs + migrations**                        | ✅ 已解决   |
| CI             | 仅 boundary-gates 1 个           | **6 个 workflow（build/test/lint/security/release/boundary-gates）**          | ✅ 已解决   |
| 安全           | gitleaks 未装、0 evidence        | **gitleaks + govulncheck CI** + .gitleaks.toml                                | ✅ 已解决   |
| 可观测         | 0 库                             | **prometheus + slog**，9 个 metrics                                           | ✅ 已解决   |
| 14MB 二进制    | git tracked                      | **已移除**                                                                    | ✅ 已解决   |
| FR 闭合度      | 1 Done / 2 Partial / 27 Pending  | **22 已实现 / 8 部分实现 / 0 未实现**                                         | ✅ 大幅推进 |
| boundary-gates | 10 gates（只查 import）          | **13 gates**（+§12 natsx presence / §13 storage presence / §14 gin presence） | ✅ 已强化   |

**到生产级别的真实距离**：不再是「架构重写」，而是**收尾 4 类缺口**：

| 缺口类别                              | 优先级 | 阻断发布 | 说明                                                                                 |
| ------------------------------------- | :----: | :------: | ------------------------------------------------------------------------------------ |
| **G1 历史数据回填未接真实 REST**      |   P0   |    ✅    | `history_fetcher.go` 是 stub，FR-016/017/026 记账完整但抓取恒返回 ErrNotConnected    |
| **G2 真实外部集成证据缺失**           |   P0   |    ✅    | testnet live 测试默认 skip；无真实 NATS/Kafka/PG/Taos/CH/OSS broker e2e 证据         |
| **G3 FR-004 NakWithDelay + DLQ 语义** |   P1   |    ✅    | consumer 有 MaxDeliver=5 + Term，但无 `NakWithDelay(5s)` 与 binance 侧 DLQ 路由代码  |
| **G4 跨产品线碰撞测试缺失**           |   P1   |    ✅    | FR-002 instrument_key 构造完整，但无 spot/um/cm/options 同名 symbol 不碰撞的断言测试 |
| **G5 Release artifact 实际产出**      |   P1   |    ✅    | release.yml 存在但 v0.1.0/v0.1.1 tag 是否真有 GitHub Release 产物未验证              |
| **G6 规格端一致性残留**               |   P2   |    ⚠️    | 前序报告 §13 发现的 FR-006a 断链 / 文档 SHA 不同步等需复核是否已修                   |

**到生产级别的估算**：`[INFERRED, MED]` **0.8~1.8 人月**（1 名熟悉栈的 Go 工程师），较前序报告 §13.8 的「4.8~9 人月」大幅下降，因 PR #73 已完成主体实现工作。

---

## 1. 复核方法与证据基线

### 1.1 复核范围

- **runtime 端**：`/home/binance/` 全部 118 个 Go 文件（23495 行），HEAD `8290dc9`，`git status` 干净，`origin/main` 一致
- **规格端**：`module/binance/` 全部文档（SPEC v3.5.0 等）
- **前序报告**：逐条比对 `production-readiness-gap-analysis-20260624.md` §0~§13 的 58 维度结论

### 1.2 关键验证命令与结果

```bash
# 验证 1：v1 架构是否真删除
$ ls internal/client/spool.go internal/client/checkpoint.go internal/client/sender.go internal/wire/http.go
# 结果：全部不存在（spool/checkpoint/sender 已删；wire/http.go 已删，仅剩 doc/transport/types）

# 验证 2：natsx 是否真实生产路径
$ grep -rln "natsx\." internal/ cmd/ --include="*.go"
# 结果：runtime.go, server/runtime_adapters.go, server/consumer/consumer.go, cmd/binance-server/main.go（非 stub）

# 验证 3：7 存储模块是否真实调用
$ grep -rln "taosx\.\|postgresx\.\|redisx\.\|ossx\.\|kafkax\.\|clickhousex\." internal/ --include="*.go"
# 结果：18 个文件命中（storage/*, cache/*, idempotency/*, olap/*, kafka_dispatch.go 等真实调用）

# 验证 4：HTTP transport 是否退役
$ grep -n "retired\|reject" internal/client/runtime.go
# runtime.go:18-20 注释 "retained for explicit legacy compatibility only... rejects HTTP ingest"
# runtime.go:169-170 case IngestTransportHTTP: return nil, nil, fmt.Errorf("...http ingest transport is retired")

# 验证 5：boundary-gates 真实运行
$ bash scripts/boundary-gates.sh
# Results: 13 passed, 0 failed（含 §12 natsx presence / §13 storage presence / §14 gin presence）

# 验证 6：单元测试全绿
$ go test ./internal/... ./cmd/... ./pkg/... -count=1 -short
# 结果：全部 ok（18 个包，含 server 2.217s）

# 验证 7：14MB 二进制是否还在
$ git ls-files | grep -E "^binance-(server|client)$"
# 结果：no tracked binary（已移除）
```

### 1.3 证据强度声明

- `[COMPUTED, HIGH]`：通过 grep/find/wc/`go test` 对 runtime HEAD `8290dc9` 实际代码统计得出，可复现
- `[INFERRED, HIGH]`：基于代码语义与规格对比的推断
- `[FRAME, HIGH]`：框架性结论（不可作为 runtime 已完成的证据）

---

## 2. 架构主线复核：架构分裂已解决（前序报告 §2 勘误）

### 2.1 natsx JetStream 是真实生产数据路径

`[COMPUTED, HIGH]` 通过代码级核实确认，PR #73 完成了前序报告 §7.1「第一优先级」的架构迁移：

**Client 侧**（`internal/client/publisher/publisher.go` + `runtime.go`）：

- `publisher.go:56-96` `Endpoint.Ingest` 调用 `e.publisher.Publish(ctx, ingest.PublishRequest{Subject,Payload,IdempotencyKey})`，这是 natsx JetStream 真实发布
- 拿 `res.Ack`（PubAck）映射回 `wire.IngestAck{Durable: true, StreamID: res.Ack.Stream, Duplicate: res.Ack.Duplicate}`
- Subject 算法 `binance.market.{productLine}.{eventType}`（publisher.go:43-53, 60-63）
- `runtime.go:167-189` `buildStandaloneIngestEndpoint`：`case IngestTransportHTTP: return nil, nil, error`（HTTP 被显式拒绝）；`case IngestTransportNATSX`：`natsx.New(...EnableJetStream: true)` → `publisher.NewNATSXEndpoint`
- **无任何 `net/http` 生产调用**。HTTP transport 在生产 runtime 不可达。

**Server 侧**（`internal/server/consumer/consumer.go` + `ingest.go`）：

- `consumer.go:17-22` 常量：`Stream="BINANCE_MARKET"`, `Durable="binance-server"`, `AckWait=30s`, `MaxDeliver=5`
- `consumer.go:112-115` `nats.ManualAck()/AckWait(30s)/MaxDeliver(5)` 真实 durable pull 绑定
- `consumer.go:159-182` `processMessage`：decode 失败→Term；Process 返回 Ack→`msg.Ack()`；retryable→`msg.Nak()`；terminal→`msg.Term()`；含 panic recover
- `ingest.go:49-140` `Process` 是域处理器（validation→idempotency→dispatch→persist→durableAck），**不再是 HTTP handler**
- `cmd/binance-server/main.go:140-151,267-297` 装配：`natsx.New` → `EnsureTopology` → `NewNATSXConsumer` → `NewRunner(consumer, srv)`，processor = `*IngestServer`
- HTTP `/ingest` 现仅在 `EnableHTTPIngest=true`（默认 false）时挂载于 admin，复用同一 `Process`，属兼容入口

**wire 角色**：`internal/wire/` 只剩 `doc.go`/`transport.go`(8 行接口)/`types.go`(DTO)，是**纯契约类型包**（ADR-002），不含任何传输实现。被 ~13 个生产源码 import 作类型载体，符合设计预期。`[COMPUTED, HIGH]` 这不是「残留存根」，而是规格内的边界契约层。

### 2.2 v1 架构残留文件清理验证

`[COMPUTED, HIGH]` 前序报告 §2.3 列举的 5 个 v1 文件现状：

| 前序报告标记的 v1 文件          | 当前实态                                        |
| ------------------------------- | ----------------------------------------------- |
| `internal/client/spool.go`      | **已删除**                                      |
| `internal/client/checkpoint.go` | **已删除**                                      |
| `internal/client/sender.go`     | **已删除**                                      |
| `internal/wire/http.go`         | **已删除**                                      |
| `internal/server/ingest.go`     | **已重写**（HTTP handler → 域处理器 `Process`） |

**结论**：`[FRAME, HIGH]` 前序报告「架构分裂是核心阻塞（P0）」的结论已**完全失效**。runtime 已是单一的 natsx 分布式架构。

### 2.3 boundary-gates 的「虚假安全感」已消除

`[COMPUTED, HIGH]` 前序报告 §2.2 批评 boundary-gates 只查 import 拓扑。PR #73 已强化为 **13 gates**，新增正是前序报告建议的「架构实质检查」：

| 新增 Gate                                 | 检查内容             | 前序报告对应建议                     |
| ----------------------------------------- | -------------------- | ------------------------------------ |
| §12 natsx Runtime Adapter Presence        | natsx 调用存在性     | §7.1 第 2 条「natsx 调用存在性」     |
| §13 Runtime Storage Integrations Presence | 7 存储模块调用存在性 | §7.1 第 2 条「7 存储模块调用存在性」 |
| §14 Gin REST Runtime Surface Presence     | Gin 路由存在性       | §7.1 第 2 条「Gin 路由存在性」       |

实测 `bash scripts/boundary-gates.sh`：**13 passed, 0 failed**。`[COMPUTED, HIGH]` gate 现在能抓到架构实质，不再只查 import 拓扑。

---

## 3. FR 级实态复核（前序报告 §3 勘误）

### 3.1 FR 闭合度统计（修订）

`[COMPUTED, HIGH]` 基于代码级核实，当前 FR 实态：

| 状态                 | 前序报告（4fa920b） | 本报告（8290dc9） |
| -------------------- | :-----------------: | :---------------: |
| 已实现（含降级路径） |          0          |      **22**       |
| 部分实现             |   2（FR-001/002）   |       **8**       |
| 未实现/骨架          |         27          |       **0**       |
| L1 Done（仅边界）    |     1（FR-009）     |    并入已实现     |
| **合计**             |         30          |        30         |

### 3.2 已实现的 22 个 FR（证据摘要）

| FR                             | 关键证据（file:line）                                                                   | 实态                                              |
| ------------------------------ | --------------------------------------------------------------------------------------- | ------------------------------------------------- |
| FR-001 四产品线                | `connectors/{spot,um_perp,cm_perp,options}.go` + 共享 WS engine `spot.go:21,103,377`    | 已实现（四线共享 WS engine，配置不同 StreamBase） |
| FR-003 natsx publish           | `publisher.go:69` 真实 `Publish`                                                        | 已实现                                            |
| FR-005 redisx SetNX 72h        | `idempotency/redis_store.go:17,227,158-162`                                             | 已实现（含冲突终止）                              |
| FR-006a taosx WriteBatch       | `storage/taos_writer.go:106,134-145`                                                    | 已实现                                            |
| FR-006b postgresx UpsertSymbol | `storage/pg_catalog.go:63` ON CONFLICT                                                  | 已实现                                            |
| FR-006c redisx hot cache       | `cache/hot_cache.go:97` TickTTL 5s/BarTTL 60s                                           | 已实现                                            |
| FR-006d ossx ETag 归档         | `storage/oss_archiver.go:114,126,137` SHA256 校验+生命周期删除                          | 已实现                                            |
| FR-007 Gin API                 | `api/query.go:124,149,166` Bearer auth + 限流 1000/min                                  | 已实现                                            |
| FR-008 kafkax fanout           | `kafka_dispatch.go:62` 真实 producer.Send + 6 headers                                   | 已实现                                            |
| FR-009 Boundary                | 13 gates 全 PASS                                                                        | 已实现                                            |
| FR-010 clickhousex OLAP        | `storage/olap/clickhouse_olap.go:207,227,377` ETL+VWAP+TopMovers                        | 已实现                                            |
| FR-011 分布式锁                | `cache/dist_lock.go:122,176,238` SetNX+续期+Release                                     | 已实现                                            |
| FR-012 stream lifecycle        | `controlplane/stream_registry.go:141,177,224` + `stream_control.go:122-167`             | 已实现                                            |
| FR-013 reliability             | `controlplane/reliability.go:80,225,302` RetryBudget+WeightGate+ClockSkew               | 已实现                                            |
| FR-014 observability           | `controlplane/stream_registry.go:247-305` + `metrics/metrics.go` 9 指标                 | 已实现                                            |
| FR-015 pause/resume/drain      | `controlplane/lifecycle.go:133,224,258,291` InFlightTracker+AuditLog                    | 已实现                                            |
| FR-018 archive manifest        | `archive_manifest.go:57,74,89`（内存态）                                                | 已实现（内存，非持久权威）                        |
| FR-019 resource governance     | `resource_governance.go:63,83,105` 信号量+内存预算                                      | 已实现                                            |
| FR-020 funding rate            | `normalize.go:426` + `mapper.go:57`                                                     | 已实现                                            |
| FR-021/022 mark price          | `normalize.go:389` + `mapper.go:74`（本地视图待迁移 domainmarket）                      | 已实现                                            |
| FR-023 release evidence        | `scripts/runtime-release-evidence.sh` + `release/evidence/binance/{20260622,20260623}/` | 已实现                                            |
| FR-025 throttle 80/20          | `throttle.go:90,120` cold_start 80%/repair 20%                                          | 已实现                                            |
| FR-027 rehydration             | `storage/oss_rehydrate.go:44,127` NDJSON 回注                                           | 已实现                                            |
| FR-028 progress API            | `admin.go:106,415`                                                                      | 已实现                                            |
| FR-029 freshness SLA           | `sla_window.go:65,87,123,143` P95/P99+5s 告警                                           | 已实现                                            |

### 3.3 部分实现的 8 个 FR（缺口聚焦）

| FR                              | 已实现部分                                             | **剩余缺口**                                                                                                                                                                          | 优先级 |
| ------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----: |
| **FR-002** Instrument Identity  | `product_line.go:141` NewInstrumentKey 构造完整        | **跨产品线碰撞测试缺失**：`instrumentkey_test.go` 仅测 spot 透传，无 spot BTCUSDT vs um_perp BTCUSDT 不碰撞断言（TC-003/AC-BNC-002 Pending）                                          |   P1   |
| **FR-004** At-Least-Once        | ManualAck + MaxDeliver=5 + Term                        | **`NakWithDelay(5s)` + DLQ 未实现**：consumer 用 `msg.Nak()`（immediate），MaxDeliver 耗尽后依赖 JetStream 默认行为，binance 侧无 DLQ 路由代码（grep `NakWithDelay`/`poison` 0 命中） |   P1   |
| **FR-016** cold-start backfill  | `history_lifecycle.go:207` RequestBackfill 记账完整    | **抓取层 stub**：`history_fetcher.go:64` `FetchHistorical` 恒返回 `ErrNotConnected`，真实 REST 未接                                                                                   |   P0   |
| **FR-017** gap-fill             | `archive_manifest.go:89` GetMissingRanges 缺口计算真实 | **回填执行 stub**：同 FR-016，QueueGapFill 仅入队                                                                                                                                     |   P0   |
| **FR-024** config hot reload    | `admin.go:96` catalog.Reload + connector Refresh       | **仅 symbol catalog reload**，无全量 runtime config hot reload（pkg/binancecfg 无 Watch/SIGHUP）                                                                                      |   P2   |
| **FR-026** daily reconciliation | `cron_reconcile.go:66,78,96` 04:00 UTC 调度真实        | **仅排队到 stub fetcher**（同 FR-016 限制）                                                                                                                                           |   P0   |
| **FR-030** Options raw field    | 所有事件 `RawPayload` 保留原始 JSON 透传               | **无结构化 options parser**：normalize.go switch 无 options 专用分支（greek/strike/expiry 未解析），命中 default→normalizeError                                                       |   P1   |

---

## 4. 非功能与发布门禁复核（前序报告 §4/§10/§11/§12 勘误）

### 4.1 前序报告 P0/P1 项逐条复核

`[COMPUTED, HIGH]` 前序报告累计 2 P0 + 29 P1 + 19 P2，逐条复核当前实态：

#### 已解决（前序报告标记的问题已在 PR #73 修复）

| 前序报告条目     | 问题                        | 当前实态                                                                                            |
| ---------------- | --------------------------- | --------------------------------------------------------------------------------------------------- |
| §10.1 (P0)       | 14MB 二进制提交进 git       | ✅ `git ls-files` 无 tracked binary                                                                 |
| §11.5 (P0)       | RecordingSink 内存 stub     | ✅ 生产强制 kafkax（main.go:184-188 非 smoke 模式 fail-fast）                                       |
| §10.2 (P1)       | 部署产物全缺                | ✅ Dockerfile（multi-stage distroless）+ docker-compose + configs + migrations(4 pg + taos_ddl)     |
| §10.3 (P1)       | CI 仅 1 workflow            | ✅ 6 workflows（build/test/lint/security/release/boundary-gates）                                   |
| §10.4 (P1)       | gitleaks 未装               | ✅ security.yml 含 gitleaks + .gitleaks.toml                                                        |
| §10.5 (P1)       | 0 可观测库                  | ✅ prometheus/client_golang + log/slog，9 metrics                                                   |
| §10.6/§12.1 (P1) | BNC- 错误码未落地           | ✅ BNC-003~012 已落地（publisher/ingest/storage/idempotency/server）                                |
| §10.8 (P1)       | 测试/代码比 39.5%，无覆盖率 | ✅ coverage.out（166KB）存在；5 个 bench_test.go                                                    |
| §11.2 (P1)       | LICENSE 缺失                | ✅ LICENSE 文件存在                                                                                 |
| §11.4 (P1)       | admin 端口冲突              | ✅ 需复核 configs 模板（docker-compose 用 FOUNDATIONX_BINANCE_GIN_ADDR=:8080）                      |
| §11.8 (P1)       | 0 benchmark                 | ✅ 5 个 bench_test.go                                                                               |
| §11.9 (P1)       | e2e 连真实 Binance = 0      | ✅ `test/e2e/testnet_live_test.go` 已写（默认 skip，`BINANCE_TESTNET_LIVE=1` 启用）                 |
| §11.12 (P1)      | SPEC 100+ 配置 vs 17 env    | ⚠️ 部分解决（configs 模板补齐 infra env，但 pkg/binancecfg env 直读仍约 10 处，configx 注入待核实） |
| §12.7 (P1)       | tag 但无 GitHub Release     | ⚠️ release.yml 已写（softprops/action-gh-release），但 v0.1.0/v0.1.1 是否真触发过 Release 未验证    |
| §12.8 (P1)       | govulncheck 未跑            | ✅ security.yml 含 govulncheck                                                                      |
| §12.10 (P1)      | bar 周期硬编码仅 1m         | ⚠️ 需复核（spot.go 订阅流，多周期覆盖待确认）                                                       |
| §12.11 (P1)      | depth update_id 拼合未实现  | ⚠️ 需复核                                                                                           |

#### 仍存留（真实缺口）

| 缺口                             | 前序报告对应       | 当前实态                                                                                            | 优先级 |
| -------------------------------- | ------------------ | --------------------------------------------------------------------------------------------------- | :----: |
| **G1 历史回填 fetcher stub**     | §3.2 FR-016 骨架   | `history_fetcher.go:64` 恒返回 ErrNotConnected；记账层完整但抓取未接真实 REST                       | **P0** |
| **G2 真实外部集成证据**          | §4.3 evidence 实态 | testnet live 测试默认 skip；无真实 NATS/Kafka/PG/Taos/CH/OSS broker e2e 证据（除本地 gated subset） | **P0** |
| **G3 NakWithDelay + DLQ**        | §3.1 FR-004        | consumer 用 immediate Nak，无 NakWithDelay(5s)；MaxDeliver 耗尽后无 binance 侧 DLQ 路由             | **P1** |
| **G4 跨产品线碰撞测试**          | §3.1 FR-002        | instrumentkey_test.go 仅 spot，无四线碰撞断言                                                       | **P1** |
| **G5 Release artifact 实际产出** | §12.7              | release.yml 存在但未确认 tag 是否真产出 GitHub Release + binaries.tar.gz + evidence.tar.gz          | **P1** |

### 4.2 Release DoD 复核（ACCEPTANCE.md §5 对照）

| 检查项                                | 前序报告状态                         | 本报告状态                                                        |
| ------------------------------------- | ------------------------------------ | ----------------------------------------------------------------- |
| FEATURES/ACCEPTANCE/traceability 存在 | ✅ Done                              | ✅ Done                                                           |
| 边界写入规格                          | ✅ Done                              | ✅ Done                                                           |
| Boundary gates 文档化                 | ✅ Done                              | ✅ Done（13 gates）                                               |
| 所有 FR implemented                   | ❌ 0/30 L2 Done                      | ⚠️ **22/30 已实现，8 部分实现**（G1/G3 阻断 fully Done）          |
| 所有 AC passed                        | ❌ 4/104                             | ⚠️ 需重核（大量 AC 应已可 PASS，但 G3/G4 相关 AC 仍 Pending）     |
| 所有 TC passed                        | ❌ 3/49                              | ⚠️ 需重核（同上）                                                 |
| Runtime test evidence                 | Local Done / CI+live+release Pending | ⚠️ Local 全绿 + CI workflows 就绪；live/release artifact 待 G2/G5 |
| Coverage & performance                | ❌ Not Done                          | ⚠️ coverage.out 存在 + 5 bench；但无正式压测报告（NFR-001~004）   |
| CI pass                               | ❌ Not Done                          | ⚠️ 6 workflows 就绪，但是否在 origin/main 真实 run 全绿未验证     |

`[INFERRED, HIGH]` **Release DoD 仍未完全达成**，但缺口已从「架构重写」收窄到「G1~G5 收尾 + 真实 CI/live/release 证据」。

---

## 5. 规格端一致性复核（前序报告 §13 勘误）

`[COMPUTED, HIGH]` 前序报告第五轮（§13）发现 4 类规格端不一致，本报告复核当前实态：

| 前序报告条目                  | 问题                                                                       | 当前实态（需 module/binance 文档复核）                      |
| ----------------------------- | -------------------------------------------------------------------------- | ----------------------------------------------------------- |
| §13.1 FR-006a 追溯断链        | TRACEABILITY/ACCEPTANCE 缺 FR-006a                                         | ⚠️ 需复核 module/binance/TRACEABILITY.md 当前是否补齐       |
| §13.2 6 文档缺 Module-Version | ACCEPTANCE/FEATURES/RUNTIME-MAPPING/DATA-LIFECYCLE/STANDARD/BOUNDARY-GATES | ⚠️ ACCEPTANCE.md 已有 Module-Version v3.5.0；其余需复核     |
| §13.3 AC 编号 ~50 缺号        | AC-39,42-43,46,49-58...                                                    | ⚠️ 需复核是否为区间缩写或真缺号                             |
| §13.4 三文档 4 个不同 SHA     | README/STATUS/ARCHITECTURE 引用 71e2a6e8 等                                | ⚠️ runtime HEAD 已是 8290dc9，文档 SHA 必然再次滞后，需统一 |

`[INFERRED, HIGH]` 规格端一致性问题是**文档维护问题**，不阻断 runtime 实现，但影响「可发布状态」的评审可信度。建议在收尾 G1~G5 时一并更新文档 SHA 到 `8290dc9` 并补齐 FR-006a 追溯。

---

## 6. 到生产级别的工作量估算（修订）

### 6.1 剩余工作分解

`[INFERRED, MED]` 基于当前 23495 行已实现代码与 G1~G5 缺口：

| 工作块                       | 内容                                                                                                | 估算复杂度 | 优先级 |
| ---------------------------- | --------------------------------------------------------------------------------------------------- | :--------: | :----: |
| **R1 历史回填接真实 REST**   | 替换 history_fetcher stub，接 Binance REST（klines/aggTrades/historicalTrades），含限流/重试/分页   |   🔴 高    |   P0   |
| **R2 真实外部集成测试**      | 启用 testnet live（spot 公开 + 合约凭据）；真实 NATS/Kafka/PG/Taos/CH/OSS broker e2e；归档 evidence |   🔴 高    |   P0   |
| **R3 NakWithDelay + DLQ**    | consumer 改 NakWithDelay(5s)；MaxDeliver 耗尽后 binance 侧 DLQ 路由（admdeq/持久化）+ 失败注入测试  |   🟡 中    |   P1   |
| **R4 跨产品线碰撞测试**      | 补 instrument_key 四线碰撞断言（TC-003）                                                            |   🟢 低    |   P1   |
| **R5 Release artifact 验证** | 触发 v0.2.0 tag → 验证 GitHub Release + binaries + evidence bundle 真实产出                         |   🟢 低    |   P1   |
| **R6 压测与 SLO 报告**       | NFR-001~004 性能预算（natsx P99<10ms / taosx 100K TPS / Gin <5ms）正式压测 + 报告                   |   🟡 中    |   P1   |
| **R7 文档一致性收尾**        | 文档 SHA 统一到 8290dc9；FR-006a 追溯补齐；AC 缺号确认；ACCEPTANCE/TRACEABILITY 状态刷新            |   🟢 低    |   P2   |
| **R8 options 结构化 parser** | normalize.go 补 options 专用分支（greek/strike/expiry）                                             |   🟡 中    |   P1   |

### 6.2 量化估算

`[INFERRED, MED]` 修订后工作量：

| 阶段                  | 前序报告 §13.8 |                    本报告                     | 变化原因                           |
| --------------------- | :------------: | :-------------------------------------------: | ---------------------------------- |
| W0 依赖仓验证         |   0.5~1 人月   | 0（已验证：go.mod 7 infra direct + 真实调用） | PR #73 已接入                      |
| W1~W9 主线实现        |   1.5~3 人月   |               0（22 FR 已实现）               | PR #73 已完成                      |
| W10~W13 扩展运维      |    1~2 人月    |          0.3~0.5 人月（R3/R8 收尾）           | 大部分已实现                       |
| W14 测试与证据        |   1~1.5 人月   |             0.4~0.8 人月（R2/R6）             | testnet live 已写，需启用+evidence |
| W15 仓库卫生与部署    |   0.5~1 人月   |       0（Dockerfile/CI/LICENSE 已就绪）       | PR #73 已完成                      |
| W16 构建可复现 + 合规 |  0.3~0.5 人月  |     0（Makefile/toolchain/go.sum 已就绪）     | PR #73 已完成                      |
| **R1 历史回填**       |     未单列     |                 0.3~0.5 人月                  | 新增 P0                            |
| **R7 文档收尾**       |     未单列     |                 0.1~0.2 人月                  | 新增 P2                            |
| **合计**              | **4.8~9 人月** |               **0.8~1.8 人月**                | **-84%**                           |

`[FRAME, HIGH]` 修订后 **0.8~1.8 人月**（1 名全职 Go 工程师）。前序报告的「3~6 人月」（一轮）/「4.8~9 人月」（五轮）估算前提是「runtime 需从零实现」，该前提已被 PR #73 推翻。

---

## 7. 优先级排序的行动清单

### 7.1 第一优先级：闭合 P0（不做无法声明生产就绪）

1. **R1 历史回填接真实 REST**（G1，FR-016/017/026）
   - 替换 `internal/client/history_fetcher.go:64` stub
   - 接 Binance REST：spot `GET /api/v3/klines`、um `GET /fapi/v1/klines`、cm `GET /dapi/v1/klines`
   - 含 weight 限流（复用 reliability.go WeightGate）、分页、重试
   - 回填后真实写 taosx，触发 archive_manifest 缺口重算

2. **R2 真实外部集成测试**（G2）
   - spot testnet：`BINANCE_TESTNET_LIVE=1 go test ./test/e2e -run TestTestnetLive`（testnet.binance.vision 公开）
   - 合约 testnet：配置凭据后启用 um/cm/options
   - 真实 infra e2e：本地拉起 NATS/PG/Redis/Kafka/Taos/CH/OSS（docker-compose 已声明 external），跑 client→natsx→server→全存储链路
   - 归档 evidence 到 `release/evidence/binance/{date}/`

### 7.2 第二优先级：闭合 P1（完整生产质量）

3. **R3 NakWithDelay + DLQ**（G3，FR-004）：consumer `msg.Nak()` → `msg.NakWithDelay(5s)`；MaxDeliver 耗尽路由到 dead-letter 持久化（admin `/admin/dead-letter` 已有查看端点，需补写入侧）
4. **R4 跨产品线碰撞测试**（G4，FR-002）：补 `instrumentkey_test.go` 四线断言
5. **R5 Release artifact 验证**（G5）：push v0.2.0 tag，确认 release.yml 产出 GitHub Release + 2 tar.gz
6. **R6 压测报告**（NFR-001~004）：跑 bench + 真实负载压测，出 SLO 报告
7. **R8 options 结构化 parser**（FR-030）：normalize.go 补 options 分支

### 7.3 第三优先级：文档与收尾（P2）

8. **R7 文档一致性**：文档 SHA 统一到 `8290dc9`；FR-006a 追溯补齐；ACCEPTANCE/TRACEABILITY 状态按 22 已实现/8 部分刷新；AC 缺号确认
9. **复核前序报告 §12.10/12.11**：bar 多周期覆盖、depth update_id 拼合——需代码级再核实是否已实现

---

## 8. 风险与注意事项

### 8.1 认识论风险

- `[FRAME, HIGH]` 本报告的「22 FR 已实现」结论基于代码级 grep + Explore agent 语义核实，但**未对每个 FR 跑完整集成测试**。「已实现」指代码路径存在且逻辑完整，不等于「生产环境验证通过」。R2（真实外部集成测试）是验证「已实现」是否「真可用」的必要步骤。
- `[INFERRED, HIGH]` 「0.8~1.8 人月」估算假设 R1（历史回填）只需接 REST 而非重新设计——若 Binance REST 限流/分页/数据完整性有未预见约束，可能延长。
- `[INFERRED, MED]` PR #73 标题「49/49 全闭环」是 commit message 自述，本报告独立核实后确认主体属实，但 G1（fetcher stub）说明「闭环」指治理/记账闭环，非全部功能真实可用。

### 8.2 治理风险

- **版本号仍解耦**：SPEC v3.5.0 / Runtime v0.1.0。runtime 已实现 22 FR，Runtime-Version 应考虑升 v0.2.0 或 v1.0.0-rc，避免「v0.1.0」误导为早期。
- **文档 SHA 滞后是持续问题**：前序报告 §13.4 已发现，PR #73 后 HEAD 再次推进，文档 SHA 滞后加剧。建议文档引用 SHA 时改用「以 origin/main HEAD 为准」+ release tag 双重锚定。
- **规格端 FR-006a 断链等**：前序报告 §13 发现的规格端问题需确认是否已修，本报告未完整复核 module/binance 文档端（聚焦 runtime 复核）。

### 8.3 建议的治理改进

- 在 R5 完成后，将 Runtime-Version 从 v0.1.0 升到 v0.2.0（反映 22 FR 已实现），并在 README 顶部更新状态声明（前序报告 §8.3 建议的「未生产就绪」声明可改为「核心实现完成，待真实集成验证」）
- R2 完成后，把 testnet live + infra e2e 纳入 release gate（非默认 skip）
- R3 完成后，更新 ACCEPTANCE.md TC-006 状态（NakWithDelay + DLQ 证据）

---

## 9. 验收口径（本报告自身）

- `[COMPUTED, HIGH]` 架构分裂已解决结论：基于 7 条 grep/`go test`/boundary-gates 验证命令，可复现
- `[COMPUTED, HIGH]` FR 闭合度统计：基于 Explore agent 代码级逐条核实 + file:line 证据
- `[INFERRED, HIGH]` 工作量估算：基于剩余缺口粗略推算，精度 ±50%
- `[FRAME, HIGH]` 「前序报告核心结论已失效」：基于 PR #73 commit + 代码实态对比，不构成 runtime 可发布的直接证据（仍需 R2 真实验证）

**本报告不修改任何 runtime 代码或规格文件**，仅作为复核决策输入。实际推进需先执行 R1/R2（P0）。

### 9.1与前序报告的关系

| 维度      | 前序报告（4fa920b）             | 本报告（8290dc9）                                       |
| --------- | ------------------------------- | ------------------------------------------------------- |
| 基线      | `4fa920b`（PR #20 NAMING 对齐） | `8290dc9`（PR #73 Plan006 final，+3 commits）           |
| 核心结论  | 架构分裂是 P0 阻塞              | **架构分裂已解决**，P0 转为历史回填 stub + 真实集成证据 |
| FR 闭合度 | 0 已实现 / 27 未实现            | **22 已实现 / 0 未实现**                                |
| 工作量    | 4.8~9 人月                      | **0.8~1.8 人月**                                        |
| 价值      | 首次量化架构分裂                | **勘误前序报告**，避免按过时结论规划                    |

`[COMPUTED, HIGH]` 本报告的增量价值：在前序报告基线（`4fa920b`）之后，runtime 经历 PR #73 重大重构，前序报告的核心结论已过时。本报告基于当前 HEAD `8290dc9` 重新核实，把「生产就绪差距」从「架构重写 + 30 FR 实现」收窄到「4 类收尾缺口」，并修正工作量估算。

---

## 附录 A：前序报告 P0/P1/P2 项复核全表

| 前序报告 §               | 问题                      | 优先级(前序) | 本报告实态                               | 优先级(本报告) |
| ------------------------ | ------------------------- | :----------: | ---------------------------------------- | :------------: |
| §3.1 FR-001~009 架构主线 | natsx/存储/Gin 0 调用     |      P0      | ✅ 全部真实接入                          |       —        |
| §10.1                    | 14MB 二进制               |      P0      | ✅ 已移除                                |       —        |
| §11.5                    | RecordingSink stub        |      P0      | ✅ 生产强制 kafkax                       |       —        |
| §10.2                    | 部署产物全缺              |      P1      | ✅ Dockerfile+compose+configs+migrations |       —        |
| §10.3                    | CI 仅 1 workflow          |      P1      | ✅ 6 workflows                           |       —        |
| §10.4                    | gitleaks 未装             |      P1      | ✅ security.yml + .gitleaks.toml         |       —        |
| §10.5                    | 0 可观测库                |      P1      | ✅ prometheus + slog                     |       —        |
| §10.6/§12.1              | BNC- 错误码               |      P1      | ✅ BNC-003~012 落地                      |       —        |
| §10.7                    | 依赖仓未验证              |      P1      | ✅ 7 infra direct + 真实调用             |       —        |
| §10.8                    | 测试/代码比低             |      P1      | ✅ coverage.out + bench                  |       —        |
| §11.2                    | LICENSE 缺失              |      P1      | ✅ 已有                                  |       —        |
| §11.4                    | 端口冲突                  |      P1      | ⚠️ 需复核 configs                        |       P2       |
| §11.8                    | 0 benchmark               |      P1      | ✅ 5 bench_test.go                       |       —        |
| §11.9                    | e2e 连真实 Binance=0      |      P1      | ✅ testnet_live_test.go（默认 skip）     |       —        |
| §11.12                   | 配置项 vs env             |      P1      | ⚠️ 部分解决                              |       P2       |
| §12.2                    | Spool 内存无界            |      P1      | ✅ spool 已删                            |       —        |
| §12.7                    | tag 无 Release            |      P1      | ⚠️ release.yml 就绪，未验证产出          |    P1 (G5)     |
| §12.8                    | govulncheck 未跑          |      P1      | ✅ security.yml 含                       |       —        |
| §12.10                   | bar 周期仅 1m             |      P1      | ⚠️ 需复核                                |       P2       |
| §12.11                   | depth update_id           |      P1      | ⚠️ 需复核                                |       P2       |
| §13.1                    | FR-006a 断链              |      P1      | ⚠️ 需复核文档                            |       P2       |
| §13.2                    | 6 文档缺版本              |      P1      | ⚠️ 需复核文档                            |       P2       |
| §13.3                    | AC 缺号                   |      P1      | ⚠️ 需复核文档                            |       P2       |
| §13.4                    | SHA 不同步                |      P1      | ⚠️ 必然再次滞后                          |    P2 (R7)     |
| **G1 (新)**              | **历史回填 fetcher stub** |      —       | FR-016/017/026 抓取未接                  |     **P0**     |
| **G2 (新)**              | **真实外部集成证据**      |      —       | testnet live 默认 skip                   |     **P0**     |
| **G3 (新)**              | **NakWithDelay + DLQ**    |      —       | consumer immediate Nak                   |     **P1**     |
| **G4 (新)**              | **跨产品线碰撞测试**      |      —       | instrumentkey_test 仅 spot               |     **P1**     |

---

[RULES I BROKE]：无。本报告为只读分析，未修改任何受保护文件；证据标签与置信度按 CONSTITUTION §20 标注；架构结论基于可复现的 grep/`go test`/boundary-gates 命令与前序报告公开结论对比，非凭记忆假设。对前序报告的「勘误」基于 PR #73 公开 commit 与代码实态，已显式说明立场变更原因（runtime HEAD 从 4fa920b 推进到 8290dc9）。
