# module/binance BOUNDARY GATES

> 版本：v2.2.5
> Module-Version: v4.1.0
> 更新日期：2026-07-10
> Runtime 仓库：`/home/workspace/binance`
> Runtime 契约：`/home/workspace/binance/BOUNDARY-GATES.md`
> Runtime 脚本：`/home/workspace/binance/scripts/boundary-gates.sh`
> Runtime 证据：以 runtime 仓最终 release packet 指向的版本化 bundle 为准；旧 `20260623/20260625` 目录仅作历史证据。
> Runtime evidence commit：本轮 implementation commit 为 `3f6366728b635c32d73565874965d40c20a92caf`；ledger 已重新执行并绑定该 SHA，但 tag、CI URL、release notes 与 rollback 尚未齐全。[COMPUTED, HIGH]
> Historical verified source commit：`3f6366728b635c32d73565874965d40c20a92caf`；[COMPUTED, HIGH] 当前审计基线为 `b20f6d44f8b246149c7a9f9c06a4dc27bc7b49ef`，旧 gate evidence 不自动继承到当前 RC。

## 1. 目的

本文档是 docs 侧边界投影；可执行事实以 runtime 仓库为准。边界门禁证明 FR-009 / BR-001~BR-009 的结构治理，不替代 FR-003~FR-008、FR-010+ 的功能验收。

2026-06-24 本地 worker 验证补充：`bash -n scripts/runtime-release-evidence.sh scripts/boundary-gates.sh scripts/readiness-audit.sh`、`make fmt-check boundary-gates build test vet readiness-audit`、`go test ./... -race -count=1`、`git diff --check` 均 PASS；`boundary-gates.sh` 输出 `13 passed, 0 failed`。该补充不替代 live/remote/release evidence。

2026-06-25 Plan007 JetStream 证据闭合（更新前序 2026-06-24 声明）：Plan007 A3 (`1ec9d26`) 已实现 `NakWithDelay(5s)` + MaxDeliver=5 + deadletter 包；`release/evidence/binance/20260625/testnet-live.txt` 归档本地 NATS JetStream gated 测试 PASS（PubAck/duplicate/Nak/MaxDeliver 语义全验证）。前序声明「独立 client/server 进程、`NakWithDelay(5s)`、dead-letter/parking 仍不能标记 PASS」已被推翻——BR-004 提升为 Done。剩余 Pending：真实 Kafka broker fanout、production topic/ACL、跨进程 live Binance 链路。

2026-06-24 kafkax fanout 本地子集补充：local kafkax adapter 与 strict handoff unit subset 已验证，包含 topic/key、dispatch failure retryable `BNC-008` before durable/Ack 与 `plan006_task_4_7_repeat_checks=100`；真实 Kafka broker fanout、production topic/ACL 与 release evidence 仍不能标记为 PASS。

> **2026-06-30 G0 存储装配状态更新**：StorageWriter 已设置（非 nil），buildStorage() 创建真实 Redis/taos/pg/clickhouse/oss 连接，memory idempotency 仅为 fallback。G0 存储装配断层已修复。

| 验证面 | 命令 | 通过条件 |
| --- | --- | --- |
| 脚本语法 | `cd /home/workspace/binance && bash -n scripts/boundary-gates.sh` | shell 语法通过 |
| 边界门禁 | `cd /home/workspace/binance && ./scripts/boundary-gates.sh` | 15/15 PASS |
| 证据包 | `cd /home/workspace/binance && sed -n '1,160p' release/evidence/binance/20260623/SUMMARY.md` | 记录 evidence commit、verified source commit、测试命令与已知缺口 |

## 2. Gate: No Legacy binance-market

禁止 active runtime 或 docs 投影重新引入旧 `binance-market` 模块、仓库或服务文档引用。历史迁移、变更日志、报告和 `module/binance` 自引用文本不作为 active architecture 回流。

关闭规则：`/home/workspace/binance/scripts/boundary-gates.sh` 必须输出 `PASS: No legacy binance-market reference outside docs`.

## 3. Gate: Client Must Not Import Server Internals

`internal/client` 与 `cmd/binance-client` 禁止导入 `internal/server` 或 server-only package。Client 只通过网络 wire contract 发布事实，不通过 Go import 触达 Server 内部。

关闭规则：runtime gate 必须证明 client 侧无 server internals import。

## 4. Gate: Server Must Not Import Client Internals

`internal/server` 与 `cmd/binance-server` 禁止导入 `internal/client` 或 client-only package。Server 只消费 wire contract，不复用 Client connector/parser 内部实现。

关闭规则：runtime gate 必须证明 server 侧无 client internals import。

## 5. Gate: No `cs` Package as Runtime Dependency

`internal/cs` 曾代表同进程 C/S 桥接；当前 runtime 禁止任何 client/server/cmd 运行时代码导入该包。合法共享 C/S contract 是 `contracts` canonical（`pkg/contracts/ingestion.go`，ADR-007），binance 经 `internal/ingestcodec` boundary 引用。

关闭规则：runtime gate 必须证明没有 `github.com/ZoneCNH/binance/internal/cs` import。

## 6. Gate: No Same-Process C/S Communication

Client 与 Server 必须通过外部 wire contract 通信，禁止 Go interface 直调、共享内存或同进程组合运行。`cmd/binance-smoke` 是唯一允许的本地 smoke/self-test 例外。

关闭规则：runtime gate 必须证明生产 cmd 与 internal runtime 无同进程 C/S wiring。

## 7. Gate: Binance Server Owns Binance-Specific Storage Only

Server 可以拥有 Binance-specific 的时序、元数据、热缓存、归档、OLAP 与 fanout 持久化；禁止上移为 exchange-neutral market data engine、策略、下单、组合或风控存储。

关闭规则：runtime gate 必须证明 storage ownership 未漂移到通用 market_data 或非数据域职责。

## 8. Gate: Wire Contract Externality

Binance 模块不定义本地 `.proto` / gRPC ingest schema，也不拥有 canonical market domain。C/S 共享契约由 `contracts` canonical 承载（`pkg/contracts/ingestion.go`，ADR-007）；binance 在 `internal/ingestcodec` 仅保留 boundary 序列化与私有码映射，不定义 DTO。canonical 语义仍来自 `domain_market`。

关闭规则：runtime gate 必须证明没有本地 ingest proto/gRPC schema，wire contract 不回退为同进程 cs。

## 9. Gate: Domain-Market Semantic Source

Binance 只能消费 `domain_market` 语义，禁止在本模块内重新定义 canonical product line、event type、market fact 或 cross-exchange identity。

关闭规则：runtime gate 必须证明没有本地 canonical domain 枚举或替代模型。

## 10. Gate: Admin Surface Boundary

Server admin surface 可以暴露健康、就绪、stream stats、drain、dead letters 与 HTTP JSON `/ingest`，但不得成为跨模块通用 control plane，也不得让 Client 通过 server internals 变相同进程调用。

关闭规则：runtime gate 必须证明 admin 入口保持在 Server 边界内，且不破坏 C/S import 与进程边界。

## 11. Gate: `go.mod` Dependency Compliance

Runtime `go.mod` 必须保留边界所需 direct dependencies，不得通过依赖删除或替换绕开 `domain_market`、`natsx`、`redisx`、`postgresx`、`taosx`、`clickhousex`、`kafkax`、`ossx`、`gin` 等契约面。

关闭规则：runtime gate 必须证明 `go.mod` 中的边界依赖集合合规。

## 12. 状态口径

| 项 | 状态 |
| --- | --- |
| BR-001 | Done：Gate §2 已由 runtime 13/13 PASS 证明 |
| BR-002 | Done：Gate §3 已由 runtime 13/13 PASS 证明 |
| BR-003 | Done：Gate §4 已由 runtime 13/13 PASS 证明 |
| BR-004 | Done：Plan007 A3 (`1ec9d26`) NakWithDelay(5s) + MaxDeliver=5 + deadletter 包已实现；本地 NATS JetStream gated 测试验证 PubAck/duplicate/Nak/MaxDeliver 语义（`release/evidence/binance/20260625/testnet-live.txt`） |
| BR-005 | Done：Gate §5 与 §6 已由 runtime 13/13 PASS 证明 |
| BR-006 | Done：Gate §7 已由 runtime 13/13 PASS 证明 |
| BR-007 | Done：Gate §9 已由 runtime 13/13 PASS 证明 |
| BR-008 | Done：Gate §8 已由 runtime 13/13 PASS 证明 |
| BR-009 | Done：Gate §11 已由 runtime 13/13 PASS 证明 |
| Release | 规格投影 Done；runtime `release_closeable_runtime=NO`。本轮 local runtime tests/boundary 已通过，但 external durable/fanout/query、正式 tag/release notes、部署前检查与真实 rollback 仍需外部证据；不得把历史 CI/infra 声明继承为本轮发布 PASS。 |

---

> §20 Gate 推广模板已迁移至 [`docs/governance/boundary-gates-template.md`](../../../docs/governance/boundary-gates-template.md)（2026-06-28）。
