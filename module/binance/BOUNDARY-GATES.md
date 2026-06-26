# module/binance BOUNDARY GATES

> 版本：v2.2.5
> Module-Version: v3.7.1
> 更新日期：2026-06-25
> Runtime 仓库：`/home/binance`
> Runtime 契约：`/home/binance/BOUNDARY-GATES.md`
> Runtime 脚本：`/home/binance/scripts/boundary-gates.sh`
> Runtime 证据：`/home/binance/release/evidence/binance/20260623/` + `/home/binance/release/evidence/binance/20260625/`
> Runtime evidence commit：`71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`（2026-06-23 归档证据）；2026-06-25 Plan007 证据见 `release/evidence/binance/20260625/`（runtime HEAD `e02b190`）
> Verified source commit：`e02b190`（runtime HEAD，2026-06-25，Plan007 A1~A10 + B1~B8 已执行）

## 1. 目的

本文档是 docs 侧边界投影；可执行事实以 runtime 仓库为准。边界门禁证明 FR-009 / BR-001~BR-009 的结构治理，不替代 FR-003~FR-008、FR-010+ 的功能验收。

2026-06-24 本地 worker 验证补充：`bash -n scripts/runtime-release-evidence.sh scripts/boundary-gates.sh scripts/readiness-audit.sh`、`make fmt-check boundary-gates build test vet readiness-audit`、`go test ./... -race -count=1`、`git diff --check` 均 PASS；`boundary-gates.sh` 输出 `13 passed, 0 failed`。该补充不替代 live/remote/release evidence。

2026-06-25 Plan007 JetStream 证据闭合（更新前序 2026-06-24 声明）：Plan007 A3 (`1ec9d26`) 已实现 `NakWithDelay(5s)` + MaxDeliver=5 + deadletter 包；`release/evidence/binance/20260625/testnet-live.txt` 归档本地 NATS JetStream gated 测试 PASS（PubAck/duplicate/Nak/MaxDeliver 语义全验证）。前序声明「独立 client/server 进程、`NakWithDelay(5s)`、dead-letter/parking 仍不能标记 PASS」已被推翻——BR-004 提升为 Done。剩余 Pending：真实 Kafka broker fanout、production topic/ACL、跨进程 live Binance 链路。

2026-06-24 kafkax fanout 本地子集补充：local kafkax adapter 与 strict handoff unit subset 已验证，包含 topic/key、dispatch failure retryable `BNC-008` before durable/Ack 与 `plan006_task_4_7_repeat_checks=100`；真实 Kafka broker fanout、production topic/ACL 与 release evidence 仍不能标记为 PASS。

> **2026-06-25 G0 存储装配断层声明**：boundary-gates 的 §12 natsx presence / §13 storage presence / §14 gin presence gate 证明的是「runtime 代码中存在调用」，**不证明 `cmd/binance-server/main.go` 装配了真实实例**。实测 main.go 用 `bootstrap.Spec{Stores: bootstrap.None}` + `NewMemoryIdempotencyStore` + `StorageWriter=nil`，9 存储类 FR（FR-005/006a-d/007/007a/010/011）runtime 永不执行。详见 `report/binance/production-readiness-assessment-20260625.md` §4.1 G0。

| 验证面 | 命令 | 通过条件 |
| --- | --- | --- |
| 脚本语法 | `cd /home/binance && bash -n scripts/boundary-gates.sh` | shell 语法通过 |
| 边界门禁 | `cd /home/binance && ./scripts/boundary-gates.sh` | 13/13 PASS |
| 证据包 | `cd /home/binance && sed -n '1,160p' release/evidence/binance/20260623/SUMMARY.md` | 记录 evidence commit、verified source commit、测试命令与已知缺口 |

## 2. Gate: No Legacy binance-market

禁止 active runtime 或 docs 投影重新引入旧 `binance-market` 模块、仓库或服务文档引用。历史迁移、变更日志、报告和 `module/binance` 自引用文本不作为 active architecture 回流。

关闭规则：`/home/binance/scripts/boundary-gates.sh` 必须输出 `PASS: No legacy binance-market reference outside docs`.

## 3. Gate: Client Must Not Import Server Internals

`internal/client` 与 `cmd/binance-client` 禁止导入 `internal/server` 或 server-only package。Client 只通过网络 wire contract 发布事实，不通过 Go import 触达 Server 内部。

关闭规则：runtime gate 必须证明 client 侧无 server internals import。

## 4. Gate: Server Must Not Import Client Internals

`internal/server` 与 `cmd/binance-server` 禁止导入 `internal/client` 或 client-only package。Server 只消费 wire contract，不复用 Client connector/parser 内部实现。

关闭规则：runtime gate 必须证明 server 侧无 client internals import。

## 5. Gate: No `cs` Package as Runtime Dependency

`internal/cs` 曾代表同进程 C/S 桥接；当前 runtime 禁止任何 client/server/cmd 运行时代码导入该包。合法共享 C/S contract 是 `internal/wire` 的外部化消息结构。

关闭规则：runtime gate 必须证明没有 `github.com/ZoneCNH/binance/internal/cs` import。

## 6. Gate: No Same-Process C/S Communication

Client 与 Server 必须通过外部 wire contract 通信，禁止 Go interface 直调、共享内存或同进程组合运行。`cmd/binance-smoke` 是唯一允许的本地 smoke/self-test 例外。

关闭规则：runtime gate 必须证明生产 cmd 与 internal runtime 无同进程 C/S wiring。

## 7. Gate: Binance Server Owns Binance-Specific Storage Only

Server 可以拥有 Binance-specific 的时序、元数据、热缓存、归档、OLAP 与 fanout 持久化；禁止上移为 exchange-neutral market data engine、策略、下单、组合或风控存储。

关闭规则：runtime gate 必须证明 storage ownership 未漂移到通用 market_data 或非数据域职责。

## 8. Gate: Wire Contract Externality

Binance 模块不定义本地 `.proto` / gRPC ingest schema，也不拥有 canonical market domain。当前 runtime skeleton 允许 `internal/wire` 保存 HTTP JSON `/ingest` 与后续 natsx/domain envelope 适配所需的本模块消息边界；canonical 语义仍来自 `domain_market`。

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
| Release | Not Done：远端 CI、release tag、live websocket（合约/期权 testnet 凭据）、真实 Kafka broker fanout、**G0 存储装配闭合**（9 存储类 FR main.go 未装配实例，runtime 永不落盘，详见 `report/binance/production-readiness-assessment-20260625.md` §4.1）、完整 JetStream TC-004/TC-006 跨进程证据仍按 Release DoD 单独验收 |

---

## §20 Gate 推广模板（Plan007 B8）

> 本节以 binance `boundary-gates.sh`（13 gates）为参考模板，提供跨模块 gate 推广指南。
> 各模块按实际依赖裁剪 gate 列表；完整说明见 `plans/binance/007-execution-alignment.md`。

### 模块适配矩阵

| 模块 | 保留 gates | 移除 gates | 备注 |
|:-----|:-----------|:-----------|:-----|
| `binance` | 全部 13 | — | 参考实现 |
| `bootstrap` | §2/§5/§11 | §3/§4/§6-§10/§12-§14（无 C/S 架构） | 已就位 (6 gates) |
| `natsx` | §11（go.mod 合规） | 其余 | 待创建 |
| `contracts` | §11 + §20.5（无 infra 依赖） | 其余 | 待创建 |
| `domain_*` | §9/§11 | 其余 | 待创建（纯度门禁：零 infra import） |
| `transportx` | §11 | 其余 | 待创建 |

### 实施状态

- ✅ `binance`：13 gates 完整实现 + CI 集成 (`.github/workflows/boundary-gates.yml`)
- ✅ `bootstrap`：6 gates 已就位（含 foundationx 零命中 `§20.5`）
- ⬜ `contracts`：待创建 `scripts/boundary-gates.sh`
- ⬜ `natsx`：待创建
- ⬜ `domain-market/macro/exchange`：待创建（纯度门禁：rg 验证零 infra/binance import）
- ⬜ `transportx`：待创建

### 模板创建命令

```bash
# 以 binance 为模板，逐模块复制并裁剪：
cp /home/binance/scripts/boundary-gates.sh /home/<module>/scripts/
# 编辑 gate 列表，移除不适用项，添加模块专属规则
```
