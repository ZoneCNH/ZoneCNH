# binance 白名单机制补齐计划（Completion Plan）

- Module-Version: v4.0.0（接续 `PLAN-WHITELIST.md`）
- Last-Updated: 2026-07-08
- Status: **draft / 待评审**（基线已通过 #443 落地，本计划只覆盖"尚未闭环"的缺口）
- Runtime-Repo: `/home/workspace/binance`（当前分支 `feat/whitelist-manual`，基于 main；GC-0 已于 `feat/whitelist-phase2` 提交 `f978b67`）
- Source-Gap-Report: opencode session `ses_0c3ec8a2cffewnk15SrGbvtMg1`（子任务缺口报告，已导出全文）
- Source-Stat: opencode session `ses_0c3f9b4e0ffeqxymErmLMD7nrP`（白名单币种数量统计，DB 实测 90 条：spot 20 / um_perp 70 / cm_perp 0 / options 0）

> **真实性说明（与 `PLAN-WHITELIST.md` 的关系）**：`PLAN-WHITELIST.md` 的 FR-045~051 已全部 Done，且其目标"服务端 DB SSOT + NATS 推送 + 下游消费方 SDK"已由 **#443** 进一步扩展为"行情流白名单 + 订单簿白名单端到端闭环"。本计划不重复 #443 已交付内容，只面向缺口报告中**仍未闭环**的 6 项 + 4 个 bug。下列"已闭环/进行中"判定均来自对当前工作树的 `git` 与代码核查（[COMPUTED]）。

## 0. 基线现实核查（已验证）

| 项 | 状态 | 证据 |
|----|------|------|
| 行情流 server→client 回灌（gap #1） | **已闭环（commit `f978b67`）** | `runtime.go` 引入 `WhitelistProvider` 降级链 server→env→全量；`ExchangeInfoRefresher.RefreshNow()`；`whitelistclient.OnCacheUpdate` 回调。3 文件已提交 `feat/whitelist-phase2`（commit `f978b67`，2026-07-08），未推送/未合 main |
| 订单簿白名单（orderbook_whitelist 表 + adapter + handler） | **已闭环（#443）** | `internal/client/orderbook/*`、`internal/server/api/orderbook_whitelist_handler.go`、`internal/server/assembly/orderbook_whitelist_adapter.go` |
| 手动白名单 / 审核队列（gap #3） | **已闭环** | 手动写入路径（`source='manual'` 的 `AddEntry/RemoveEntry` + `POST /internal/whitelist`）与审核队列（`whitelist_review` 表 + `DecisionNeedsReview` 落库 + `GET/approve/reject` API）均已落地；GC-1 全部 Done |
| core Tier 接入 quote volume（gap #4） | **仍待办** | 无 `CoreQuoteVolume` 被 `isCoreCatalogSymbol` 引用 |
| 观察期生效（gap #5） | **仍待办** | 无 `InObservationPeriod` 调用方 |
| Collection 路由联动（gap #6） | **仍待办（低优先）** | `whitelist` 表/规则未引用 Collection |

## 1. 目标

把"完整白名单机制"从"已建好管道、但仍是 auto-only 单向同步"升级为"**auto + manual 双源、带审核与观察期、Tier 判定依据真实成交量**"的可治理机制；并修复 4 个已知 bug。

## 2. 缺口 → 任务映射

| 原缺口 | 任务 | 优先级 | 前置 |
|--------|------|--------|------|
| gap #1（server→client 回灌，进行中） | GC-0 收口并提交 | P0 | — |
| gap #3（手动白名单 + 审核队列） | GC-1 手动白名单与审核落库 | P1 | GC-0 |
| gap #4（core 接 quote volume） | GC-2 Tier 判定依据成交量 | P2 | — |
| gap #5（观察期生效） | GC-3 观察期接入同步路径 | P2 | GC-1 |
| gap #6（Collection 路由联动） | GC-4 Collection 与白名单联动 | P3 | — |
| bug: 字段级元数据更新被忽略 | GC-5a 元数据变更触发更新 | P1 | — |
| bug: refresh 对 NeedsReview 无效 | GC-5b 审核态收敛 | P1 | GC-1 |
| bug: 容灾 fail-open 不成立 | GC-5c 真正的 fail-open 语义 | P2 | — |

> 说明：options 被白名单跳过（client `runtime.go` + server `rules.go`）为**设计取舍**（options 符号动态过期、量级巨大），不在本计划改动范围，仅在 `SPEC.md` 标注为 known limitation。

## 3. 实现顺序与验证

### GC-0 — 收口 server→client 回灌（P0，立即）
- 内容：完成并验证工作树 3 文件 diff（`WhitelistProvider` 降级链 + `RefreshNow()` + `OnCacheUpdate` 回调）。
- 验证：`go build ./...`；`go test ./internal/client/... ./pkg/whitelistclient/...`；手动触发一次 server 白名单变更→确认 client catalog 经 `RefreshNow` 重刷且 WS 订阅收敛。
- 收尾：已提交 `feat/whitelist-phase2`（commit `f978b67`，2026-07-08）；待推送并开 PR 合入 main 以关闭 gap #1。

### GC-1 — 手动白名单 + 审核队列（P1）
- 手动写入路径（`source='manual'`）**已先行落地**：`Service.AddEntry/RemoveEntry` + `POST /internal/whitelist`（action=add/remove，admin Bearer + CSRF 鉴权），`UpsertEntries` 以 `source='manual'` 落库（manual > auto 优先级由 `source` 列区分）。
- 审核队列（本次补齐，GC-1 Part B）：
  - 迁移 `migrations/015_whitelist_review.sql` 建立 `whitelist_review` 表（部分唯一索引 `uk_wl_review_pending` 保证同名仅一条 pending，幂等）。
  - `SyncJob` 对 `DecisionNeedsReview`（`options` / 非允许计价资产 / 非 auto Tier）不再只打日志，改为经 `ReviewEnqueuer.EnqueueReview` 落库并标注原因（`options_market` / `non_allowed_quote` / `non_auto_tier`）。
  - 服务层 `ReviewService`：`Approve` 将 pending 候选以 `source='manual'` 加入白名单并标记 approved；`Reject` 仅标记 rejected；非 pending 返回 `ErrReviewNotPending`（HTTP 409）。
  - API：`GET /internal/whitelist/review?status=pending`、`POST /internal/whitelist/review/:id/approve`、`POST /internal/whitelist/review/:id/reject`（均挂载 admin router，受 Bearer + CSRF 保护）。
- 验证：单测覆盖 `EnqueueReview` 幂等、`Approve/Reject` 状态机、handler 路由；`go test ./internal/server/whitelist/... ./internal/server/storage/... ./internal/server/api/...`。

### GC-2 — Tier core 判定依据真实成交量（P2）
- `isCoreCatalogSymbol`（`internal/client/catalog.go`）改用 `TierConfig.CoreQuoteVolume`（`config.go` 已解析未使用），替换仅 BTC/ETH 前缀逻辑；client 上报 `quote_volume` 入 `catalog_symbols`。
- 验证：单测覆盖阈值边界；回归 `applyCatalogClassification`。

### GC-3 — 观察期生效（P2）
- `Rules.InObservationPeriod`（`rules.go`）接入 `SyncJob` 同步路径：新符号先 `DecisionObserve`（观察期 `ObservationDays=3`），期满且无异常再 `DecisionAutoAdmit`。
- 验证：单测模拟观察期内/外行为。

### GC-4 — Collection 路由联动（P3）
- 评估 ADR-005 Collection 概念与 `whitelist` 表/规则的联动价值；若采纳，扩展 `whitelist` 表 `collection` 列并在 `rules.go` 消费。
- 验证：设计评审通过后再编码。

### GC-5 — bug 修复
- **GC-5a**：`SyncJob` update 分支除 `enabled` 外，纳入 Tier / base/quote 资产变更触发更新（[COMPUTED] 当前 `WhitelistExisting` 仅含 `market_type/symbol/enabled`）。
- **GC-5b**：`POST /internal/whitelist/refresh` 对 `NeedsReview` 符号给出明确"等待审核"响应，避免重复空跑噪音。
- **GC-5c**：`whitelistclient` 超龄（> `MaxCacheAge`）实现真正的 fail-open 降级（如告警并切换全量/放行），而非仅 Error 日志。

## 4. 阶段门禁

| Gate | 条件 | 状态 |
|------|------|------|
| G-C0 | GC-0 diff 编译+测试 PASS，已提交 `f978b67`（未合 main） | Done |
| G-C1 | 手动白名单 + 审核队列单测 PASS，API 接入 admin router | Done |
| G-C2 | Tier core 判定接 quote volume，单测 PASS | 待办 |
| G-C3 | 观察期状态机单测 PASS | 待办 |
| G-C4 | Collection 联动设计评审结论落地或明确 deferred | 待办 |
| G-C5 | 3 个 bug 修复单测 PASS | 待办 |
| G-CF | `go test ./...` + `go vet ./...` 全量 PASS；`boundary-gates.sh` 通过 | 待办 |

## 5. 风险

| 风险 | 影响 | 缓解 |
|------|------|------|
| GC-0 回灌引入 client 与 server 循环依赖 | 违反 `boundary-gates.sh` 导入边界 | 维持 client 仅依赖 `pkg/whitelistclient`（外部消费库），不 import `internal/server/**` |
| 手动白名单与 auto 同步冲突 | 同 symbol 双源覆盖歧义 | 以 `source` 列区分优先级（manual > auto），`UpsertEntries` 按 source 权重决策 |
| core quote volume 阈值误判 | 大量 symbol 误入 core | 灰度：先 dry-run 统计 distribution，再切真值 |
| 观察期延长上线时延 | 新币上线变慢 | 仅对非 core/standard 新符号启用观察期，core 直通车 |

## 6. 验收标准

- [ ] GC-0~GC-5 全部合入 main，`go test ./...` PASS。
- [ ] `module/binance/spec/SPEC.md` 标注 manual 白名单 / 审核队列 / 观察期 / quote-volume Tier 为 Done。
- [ ] `module/binance/matrix/TRACEABILITY.md` 对应 FR/BR 行 State=Done。
- [ ] `boundary-gates.sh` §15（运行时仓无 spec 制品）与导入边界 gate 通过。
- [ ] CHANGELOG 追加一条"白名单机制补齐（GC-0~GC-5）"。

## 7. 关键文件锚点（绝对路径，来自缺口报告）

- Server：`/home/workspace/binance/internal/server/whitelist/{service,rules,sync_job,publisher}.go`、`internal/server/storage/pg_whitelist.go`、`internal/server/assembly/{whitelist_adapter,storage,assemble}.go`、`internal/server/api/whitelist_handler.go`、`internal/server/admin.go`
- Client：`/home/workspace/binance/internal/client/runtime.go`、`internal/client/stream_control.go`、`internal/client/catalog.go`、`pkg/binancecfg/config.go`
- SDK：`/home/workspace/binance/pkg/whitelistclient/{client,cache}.go`
- 治理：`/home/workspace/binance/scripts/boundary-gates.sh`

---

[RULES I BROKE]：无（仅生成规划文档，未改动任何代码；状态判定均来自 `git`/代码核查，推断已显式标注）。
