# binance 生产就绪收尾 + FoundationX 解耦隐患修复执行计划（Plan 007）

> **面向 AI 代理的工作者：** 必需子技能：使用 `superpowers:subagent-driven-development`（推荐）或 `superpowers:executing-plans` 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 闭合两份复核报告发现的全部缺口——Report1（生产就绪）的 G1~G6 / R1~R8 与 Report2（解耦架构）的 §7.1~§7.7——使 `module/binance` 达到「可发布、可验证」的生产级别，并消除跨仓库潜伏工程炸弹（transportx module name bug / domain_* path 分叉）。

**架构：** 双轨并行。
- **Track A（功能就绪）** 针对 `/home/binance` runtime + 本仓库 `module/binance` 规格；
- **Track B（架构卫生）** 针对 `/home/{transportx,domain*,binance}` 跨仓库。
- 两轨无强阻塞耦合（已核实），可由不同工程师并行推进；仅在 Phase 8 验收阶段汇合。

**技术栈：** Go 1.x · natsx JetStream · taosx/postgresx/redisx/ossx/clickhousex/kafkax · Gin · Binance REST+WebSocket · GitHub Actions · configx

**证据基线：**
- Report1：[`docs/report/binance/production-readiness-recheck-20260624.md`](../../docs/report/binance/production-readiness-recheck-20260624.md)（runtime HEAD `8290dc9`）
- Report2：[`docs/report/arch/foundationx-binance-decoupling-architecture-20260624.md`](../../docs/report/arch/foundationx-binance-decoupling-architecture-20260624.md)
- 代码锚点已 **8/8 独立核实**（见 §1.3，全部 ✅ 一致）
- 前序 Plan006：49/49 DONE（本计划是其复核勘误后的**增量**，不重复其工作）

---

## 0. 与 Plan006 的关系（避免重复劳动）

| 项 | Plan006（已 DONE） | Plan007（本计划） |
|---|---|---|
| 基线 | HEAD `4fa920b` → 前序 gap-analysis 报告 | HEAD `8290dc9`（PR#73 之后）→ 两份复核报告 |
| 范围 | 架构重写 + 30 FR 实现 + 部署/CI/安全/运维 | Plan006 未覆盖的**收尾缺口** + **跨仓库工程隐患** |
| 核心结论 | 「架构分裂是 P0」 | 架构分裂**已解决**（PR#73 修复）；P0 转为历史回填 stub + 真实集成证据 |
| 工作量口径 | 4.8~9 人月 | 0.8~1.8 人月（增量） |

**本计划只做 Plan006 未覆盖的增量。** Report1 §0 明确：Plan006/前序报告的 22 FR 已实现、架构已迁移到 natsx，剩余是 G1~G6 收尾；Report2 §0 明确：解耦在代码层已成立，剩余是 3 个工程隐患 + 过渡态收口。

---

## 1. 10 遍深度分析记录（honors「重复分析 10 遍，不得有遗漏」）

> 本节使分析过程可审计。每遍聚焦一个维度，逐遍收敛缺口清单。

### Pass 1 — Report1 缺口清单（G1~G6 / R1~R8）

| 编号 | 缺口 | 优先级 | 阻断发布 | 报告定位 |
|---|---|:---:|:---:|---|
| A1 / G1 / R1 | 历史回填未接真实 REST（`history_fetcher.go` stub） | **P0** | ✅ | Report1 §0/§3.3/§7.1 |
| A2 / G2 / R2 | 真实外部集成证据缺失（testnet live 默认 skip；无真实 broker e2e） | **P0** | ✅ | Report1 §0/§4.1/§7.1 |
| A3 / G3 / R3 | NakWithDelay + DLQ 写入侧未实现（FR-004） | P1 | ✅ | Report1 §0/§3.3/§7.2 |
| A4 / G4 / R4 | 跨产品线碰撞测试缺失（FR-002 / TC-003） | P1 | ✅ | Report1 §0/§3.3/§7.2 |
| A5 / G5 / R5 | Release artifact 实际产出未验证 | P1 | ✅ | Report1 §0/§4.1/§7.2 |
| A6 / R6 | 压测与 SLO 报告缺失（NFR-001~004） | P1 | ✅ | Report1 §6.1/§7.2 |
| A7 / R8 | options 结构化 parser 未实现（FR-030） | P1 | ✅ | Report1 §3.3/§7.2 |
| A8 / G6 / R7 | 规格端一致性残留（SHA/FR-006a/AC 缺号/状态刷新） | P2 | ⚠️ | Report1 §5/§7.3 |
| A9 | §12.10/§12.11 待复核（bar 多周期 / depth update_id 拼合） | P2 | ⚠️ | Report1 §4.1/§7.3 |
| A10 | FR-024 全量 config hot reload（当前仅 symbol catalog reload） | P2 | ⚠️ | Report1 §3.3 |

### Pass 2 — Report2 隐患清单（§7.1~§7.7 + §6/§8 gate）

| 编号 | 隐患 | 严重度 | 报告定位 |
|---|---|:---:|---|
| B1 | transportx module name bug（go.mod 误声明为 xlib_standard） | **高** | Report2 §7.1 |
| B2 | domain_* module path 下划线 vs 连字符分叉 | **高** | Report2 §7.2 |
| B3 | domainx 主目录无 go.mod | 中 | Report2 §7.3 |
| B4 | binance `internal/client/runtime.go` assembly 越界（`natsx.New` 在 core 包） | 中 | Report2 §7.4 |
| B5 | binance `internal/wire` 自包含契约未迁移到 contracts（ADR-002 过渡态） | 中 | Report2 §7.5 |
| B6 | bootstrap 分层定位需明确（装配层 vs 基座核心层） | 低 | Report2 §7.6 |
| B7 | domain_exchange/macro main 落后 worktree/v100 | 低 | Report2 §7.7 |
| B8 | §6 gate 推广（boundary-gates.sh 模板固化到所有模块） | 低 | Report2 §6/§8 |

### Pass 3 — 双轨交叉依赖图（确认可并行）

```
Track B 高优炸弹（B1/B2）──┐
   （跨仓库，不阻塞 binance 当前构建）   ├──→ Phase 8 验收汇合
Track A P0 功能（A1/A2）────┘
   （binance runtime 内部，独立）

弱依赖链：
  B1（transportx name 修复）─→ 解锁未来 binance import transportx（B5 的延伸，非硬阻塞）
  B2（domain path 统一）─→ 消除 binance go.mod replace 错配（CI 一致性）
  B3（domainx go.mod）─→ B2 的前置（domainx 作为 domain_exchange 依赖需 main 可用）
  A1（回填）─→ A2 集成测试可含真实回填路径（软序，A2 可先跑现有路径）
```

**结论**：两轨可完全并行；B3 应先于 B2（domainx go.mod 就位后再统一 path）；其余无硬阻塞。

### Pass 4 — 代码锚点独立核实（8/8 ✅，见 §1.3 证据表）

### Pass 5 — FR / AC / TC 覆盖映射（每个缺口阻断哪些验收）

| 缺口 | 阻断的 FR | 阻断的 AC/TC | 阻断的 DoD 项 |
|---|---|---|---|
| A1 | FR-016（cold-start backfill）/ FR-017（gap-fill）/ FR-026（daily reconciliation） | 对应 AC | 「所有 FR implemented」 |
| A2 | —（横切） | Release DoD live/release evidence | 「Runtime test evidence（CI+live+release）」 |
| A3 | FR-004（At-Least-Once） | TC-006 | 「所有 TC passed」 |
| A4 | FR-002（Instrument Identity） | TC-003 / AC-BNC-002 | 「所有 AC passed」 |
| A7 | FR-030（Options raw field） | 对应 AC | 「所有 FR implemented」 |
| A8 | —（规格治理） | TRACEABILITY/ACCEPTANCE 状态准确性 | 「可发布状态评审可信度」 |

### Pass 6 — 优先级与排序（P0→P1→P2，双轨交织）

P0：A1、A2、B1、B2（B3 前置 B2）
P1：A3、A4、A5、A6、A7、B4、B5
P2：A8、A9、A10、B6、B7、B8

### Pass 7 — 风险与回滚（每任务含 rollback，见 §4 各任务步骤）

### Pass 8 — 工作量交叉核对

Report1 §6.2 给出合计 **0.8~1.8 人月**（1 名全职 Go 工程师）。本计划按 Phase 拆分后估算与之吻合（见附录工作量汇总）。

### Pass 9 — 对照两份报告 §9 验收清单自审

- Report1 §9：架构结论可复现 ✅、FR 闭合度有 file:line ✅、工作量 ±50% ✅、不修改 runtime/spec（本计划是其执行化）✅
- Report2 §9：20 基座 + 5 领域 + binance 全覆盖 ✅、7 隐患均有代码证据 ✅、四硬门禁 PASS ✅

### Pass 10 — 最终遗漏扫描（gap→task 全映射）

逐条核对 Pass 1 的 10 项 + Pass 2 的 8 项 = 18 项缺口，**全部映射到 §4 任务**（见附录追溯矩阵）。额外捕获 Report1 内部不一致：§0/§3.1 称「8 部分实现 FR」但 §3.3 仅列 7 行，差额 1 → 纳入 A8 任务核实。

### 1.3 代码锚点核实证据（2026-06-24 独立 grep/Read）

| 锚点 | 命令 | 结果 | 判定 |
|---|---|---|:---:|
| transportx go.mod | `head -1 /home/transportx/go.mod` | `module github.com/ZoneCNH/xlib_standard`（remote=transportx） | ✅ |
| transportx 孤岛 | `rg -l 'ZoneCNH/transportx' /home --type go \| wc -l` | `0` | ✅ |
| domain_* main path | `head -1 /home/domain-{market,macro,exchange}/go.mod` | 全下划线 `domain_market/macro/exchange` | ✅ |
| binance require domain | `grep domain /home/binance/go.mod` | 连字符 `domain-exchange v1.0.0`/`domain-market v1.1.0`（错配） | ✅ |
| domainx 主目录 | `ls /home/domainx/go.mod` | 不存在（仅 worktree/v100 有） | ✅ |
| runtime.go:172 | `grep -n 'natsx.New' runtime.go` | `172: client, err := natsx.New(ctx, natsx.Config{` | ✅ |
| history_fetcher stub | `grep -n ErrNotConnected history_fetcher.go` | `64-65: return nil, ErrNotConnected`（66 行文件） | ✅ |
| consumer Nak | `grep -n '.Nak()\|NakWithDelay' consumer.go` | `195: msg.Nak()`；NakWithDelay=0；dead-letter=9（读端点） | ✅ |
| release.yml | `ls release.yml` + `grep softprops` | 存在，softprops=1；tag v0.1.0/v0.1.1 在；release/ 无 artifact | ✅ |

---

## 2. 统一缺口清单（双轨 + 交叉映射）

### Track A — 功能就绪（runtime `/home/binance` + 本仓库 `module/binance`）

| ID | 标题 | 优先级 | 依赖 | Phase |
|---|---|:---:|---|:---:|
| A1 | 历史回填接真实 Binance REST（替换 fetcher stub） | P0 | — | 1 |
| A2 | 真实外部集成测试 + evidence 归档 | P0 | A1（软） | 3 |
| A3 | NakWithDelay(5s) + DLQ 写入侧（FR-004） | P1 | — | 4 |
| A4 | 跨产品线碰撞测试（FR-002 / TC-003） | P1 | — | 4 |
| A7 | options 结构化 parser（FR-030） | P1 | — | 4 |
| A5 | Release artifact 实际产出验证（v0.2.0 tag） | P1 | A1/A2/A3 验证后 | 6 |
| A6 | 压测与 SLO 报告（NFR-001~004） | P1 | A2 infra 可用 | 6 |
| A8 | 规格端一致性收尾（SHA/FR-006a/AC/状态） | P2 | 各功能完成后 | 7 |
| A9 | §12.10/§12.11 代码级复核 | P2 | — | 7 |
| A10 | FR-024 全量 config hot reload | P2 | — | 7 |

### Track B — 架构卫生（跨仓库 `/home/*`）

| ID | 标题 | 优先级 | 依赖 | Phase |
|---|---|:---:|---|:---:|
| B3 | domainx 主目录补 go.mod | 中 | — | 2 |
| B2 | domain_* module path 统一为 snake_case | 高 | B3 | 2 |
| B1 | transportx module name bug 修复 | 高 | — | 2 |
| B4 | binance client assembly 下沉到 cmd | 中 | — | 5 |
| B5 | wire → contracts 迁移（ADR-002 收口） | 中 | B1（软） | 5 |
| B6 | bootstrap 分层文档单列「装配层」 | 低 | — | 7 |
| B7 | main ↔ worktree/v100 同步 | 低 | B2 | 7 |
| B8 | gate 推广（boundary-gates.sh 模板固化） | 低 | — | 7 |

---

## 3. 文件结构（将创建/修改的文件，按仓库分组）

### `/home/binance`（runtime 仓库，Track A + B4/B5）
- 修改：`internal/client/history_fetcher.go`（A1：替换 ExchangeHistoryFetcher stub）
- 创建：`internal/client/history_rest.go`（A1：真实 REST 客户端 + 限流/分页/重试）
- 创建：`internal/client/history_rest_test.go`（A1：TDD 测试）
- 修改：`internal/server/consumer/consumer.go:195`（A3：Nak→NakWithDelay）
- 创建：`internal/server/deadletter/`（A3：DLQ 写入侧持久化）
- 修改：`internal/client/instrumentkey_test.go`（A4：补四线碰撞断言）
- 修改：`internal/server/ingest.go` 或 normalize 逻辑文件（A7：补 options 分支）
- 修改：`internal/client/runtime.go:172` + `cmd/binance-client/main.go`（B4：assembly 下沉）
- 修改：`internal/wire/*` → 迁移到 `/home/contracts`（B5）
- 修改：`go.mod`（B5：require contracts）
- 修改：`release/evidence/binance/{date}/`（A2/A5：归档证据）

### `/home/transportx`（B1）
- 修改：`go.mod:1`（`xlib_standard` → `transportx`）
- 全仓替换：internal import path（`xlib_standard/...` → `transportx/...`）

### `/home/domainx`（B3）
- 创建：主目录 `go.mod`（从 worktree/v100 提升或新建）

### `/home/domain-market` `/home/domain-macro` `/home/domain-exchange`（B2/B7）
- 同步：main go.mod 与 worktree/v100 的 module path（统一 snake_case）+ 版本号

### `/home/bootstrap`（B6，仅文档）
- 文档：分层定位说明（如无 README 则在 ARCHITECTURE 注明）

### 本仓库 `/home/ZoneCNH`（A8/A9 + gate 推广文档）
- 修改：`module/binance/TRACEABILITY.md`（A8：SHA→8290dc9、FR-006a 补齐、状态刷新）
- 修改：`module/binance/ACCEPTANCE.md`（A8：DoD/状态刷新）
- 修改：`module/binance/SPEC.md`（A8：Spec-Version 视情况 bump）
- 创建/修改：`module/binance/BOUNDARY-GATES.md`（B8：gate 推广模板）
- 修改：`plans/binance/README.md`（索引加 Plan007）

---

## 4. 任务分解（按 Phase，test-first 原则）

### Phase 0：基线与残留复核

#### Task 0.1：确认两份报告锚点无漂移
- [ ] **步骤 1**：在 `/home/binance` 跑 `git log --oneline -3`，确认 HEAD 仍为 `8290dc9`（或更新则记录新 SHA）
- [ ] **步骤 2**：重跑 §1.3 的 9 条核实命令，确认锚点未漂移；若漂移，更新本计划 file:line
- [ ] **步骤 3**：`cd /home/binance && go test ./internal/... ./cmd/... ./pkg/... -count=1 -short`，确认基线全绿（Report1 §1.2 验证 6）
- [ ] **步骤 4**：`bash /home/binance/scripts/boundary-gates.sh`，确认 13 gates PASS
- [ ] **提交**：无（基线确认，不改文件；结果记入执行对齐文档）

---

### Phase 1 [P0 · Track A]：A1 历史回填接真实 REST

> 替换 `history_fetcher.go` 的 `ExchangeHistoryFetcher` stub，接 Binance REST klines/aggTrades/historicalTrades，含 weight 限流、分页、重试。

#### Task A1.1：编写失败的回填测试（TDD-RED）
**文件：**
- 创建：`/home/binance/internal/client/history_rest_test.go`

- [ ] **步骤 1：编写失败测试**

```go
package client

import (
	"context"
	"testing"
	"time"
)

// 验证真实 REST fetcher 在 stub 替换后能对 spot klines 端点产出非空结果。
// 使用 httptest.Server 模拟 Binance REST，避免依赖外网。
func TestExchangeHistoryFetcher_RealREST_SpotKlines(t *testing.T) {
	// Arrange: httptest 返回固定 kline JSON
	// Act: fetcher.FetchHistorical(ctx, "BTCUSDT", "kline", from, to)
	// Assert: 结果非空、时间范围落在 [from,to]、无 ErrNotConnected
}

// 验证 weight 限流：连续请求触发 Binance 429 时退避重试而非硬失败
func TestExchangeHistoryFetcher_RateLimit_BackoffRetry(t *testing.T) {
	// Arrange: httptest 前两次返回 429，第三次返回 200
	// Assert: 最终成功，且发生了重试（请求计数 >= 3）
}

// 验证分页：超过单页 limit 的范围被正确翻页聚合
func TestExchangeHistoryFetcher_Pagination_Aggregation(t *testing.T) {
	// Assert: 多页结果按时间合并去重
}
```

- [ ] **步骤 2：运行测试验证失败**
  运行：`cd /home/binance && go test ./internal/client/ -run TestExchangeHistoryFetcher -v`
  预期：FAIL（`ExchangeHistoryFetcher` 仍返回 ErrNotConnected）

#### Task A1.2：实现真实 REST fetcher（TDD-GREEN）
**文件：**
- 创建：`/home/binance/internal/client/history_rest.go`
- 修改：`/home/binance/internal/client/history_fetcher.go:55-65`（替换 stub body）

- [ ] **步骤 1：实现 REST 客户端骨架**（复用 `resiliencx`/`controlplane/reliability.go` WeightGate 做限流；`net/http` + JSON decode）
- [ ] **步骤 2：实现 spot klines 端点** `GET /api/v3/klines`（testnet: testnet.binance.vision）
- [ ] **步骤 3：实现 um/cm 合约端点** `GET /fapi/v1/klines`、`GET /dapi/v1/klines`（按 productLine 路由）
- [ ] **步骤 4：实现 weight 限流**（复用 `controlplane/reliability.go:80,225` RetryBudget + WeightGate）
- [ ] **步骤 5：实现分页**（按 startTime/endTime 翻页，limit=1000，去重合并）
- [ ] **步骤 6：运行测试验证通过**
  运行：`go test ./internal/client/ -run TestExchangeHistoryFetcher -v`
  预期：PASS
- [ ] **步骤 7：接入记账层**——确认 `history_lifecycle.go:207 RequestBackfill`、`archive_manifest.go:89 GetMissingRanges`、`cron_reconcile.go:66` 现在能驱动真实 fetcher（而非 stub）
- [ ] **步骤 8：回归** `go test ./internal/... ./cmd/... ./pkg/... -count=1 -short`，全绿
- [ ] **回滚**：`git revert`；stub 是安全降级（返回 ErrNotConnected，记账层已容忍）

#### Task A1.3：提交
- [ ] **步骤 1**：`git add internal/client/history_rest.go internal/client/history_rest_test.go internal/client/history_fetcher.go`
- [ ] **步骤 2**：`git commit -m "feat(binance): 接真实 Binance REST 历史回填 (FR-016/017/026)"`
- [ ] **步骤 3**：更新 `module/binance/TRACEABILITY.md` FR-016/017/026 状态（Partial→Implemented，附 runtime SHA + 测试命令 URL）

---

### Phase 2 [P0 · Track B]：跨仓库炸弹拆除（B1/B2/B3）

> 三任务可在不同仓库并行。B3 应先于 B2 完成（domainx go.mod 就位后统一 path）。

#### Task B3：domainx 主目录补 go.mod（前置 B2）
**文件：** 创建 `/home/domainx/go.mod`
- [ ] **步骤 1**：`git -C /home/domainx log --oneline -3` + `ls /home/domainx/.worktree/workspaces/v100/`，确认 canonical 源
- [ ] **步骤 2**：若 worktree/v100 是 canonical，复制其 go.mod 到主目录（保留 `module github.com/ZoneCNH/domainx` + require decimalx）
- [ ] **步骤 3**：`cd /home/domainx && go build ./...`，确认主目录可独立 build
- [ ] **步骤 4**：`git add go.mod && git commit -m "fix(domainx): 主目录补 go.mod (Report2 §7.3)"`

#### Task B2：domain_* module path 统一为 snake_case
**文件：** `/home/domain-{market,macro,exchange}/go.mod`（main）+ 对应 worktree/v100
- [ ] **步骤 1：核实当前分叉**（已确认 main=下划线，worktree/v100=连字符，binance require=连字符）
- [ ] **步骤 2：决策**——本仓库 AGENTS.md 强制 snake_case，**统一为下划线**（domain_market/macro/exchange）
- [ ] **步骤 3：改 worktree/v100 go.mod** 的 module 行为下划线（3 个仓库）
- [ ] **步骤 4：全仓替换 worktree internal import path**（`domain-market` → `domain_market` 等）
- [ ] **步骤 5：改 binance `/home/binance/go.mod`** require + replace 为下划线（`domain-exchange`→`domain_exchange`、`domain-market`→`domain_market`）
- [ ] **步骤 6：验证** `cd /home/binance && go build ./...`，确认编译通过（无 unknown import path）
- [ ] **步骤 7：回滚**：`git revert` go.mod + replace；分叉恢复（不破坏当前 worktree 路径构建）
- [ ] **步骤 8：提交**（各仓库独立 commit）：`fix(domain_*): 统一 module path 为 snake_case (Report2 §7.2)`

#### Task B1：transportx module name bug 修复
**文件：** `/home/transportx/go.mod` + 全仓 import path
- [ ] **步骤 1：确认 bug**（已确认 go.mod=`xlib_standard`，remote=transportx，孤岛 0 import）
- [ ] **步骤 2：改 go.mod:1** 为 `module github.com/ZoneCNH/transportx`
- [ ] **步骤 3：全仓替换** `rg -l 'github.com/ZoneCNH/xlib_standard' /home/transportx --type go` 命中文件的 import path
- [ ] **步骤 4：验证** `cd /home/transportx && go build ./... && go test ./...`
- [ ] **步骤 5：验证 import 可达**——临时在 binance 加 `import "github.com/ZoneCNH/transportx/..."` 跑 build 后回退（确认定时炸弹已拆除）
- [ ] **步骤 6：回滚**：`git revert` go.mod + import path；恢复孤岛态（当前无人 import，回滚安全）
- [ ] **步骤 7：提交**：`fix(transportx): 修正 module name (xlib_standard→transportx, Report2 §7.1)`

---

### Phase 3 [P0 · Track A]：A2 真实外部集成测试 + evidence

#### Task A2.1：启用 testnet live 测试
- [ ] **步骤 1**：`cd /home/binance && BINANCE_TESTNET_LIVE=1 go test ./test/e2e -run TestTestnetLive -v`（spot 公开 testnet.binance.vision）
- [ ] **步骤 2**：配置合约 testnet 凭据后启用 um/cm/options
- [ ] **步骤 3**：捕获输出到 `release/evidence/binance/{date}/testnet-live.txt`

#### Task A2.2：真实 infra e2e（client→natsx→server→全存储）
- [ ] **步骤 1**：`docker-compose up`（已声明 external NATS/PG/Redis/Kafka/Taos/CH/OSS）
- [ ] **步骤 2**：跑全链路 e2e：client publish → natsx → server consume → taosx/pg/redis/oss/kafka/clickhouse 落地
- [ ] **步骤 3**：验证各存储真实写入（非 stub）
- [ ] **步骤 4**：归档 evidence 到 `release/evidence/binance/{date}/infra-e2e/`
- [ ] **提交**：evidence artifact commit

---

### Phase 4 [P1 · Track A]：功能质量收尾（A3/A4/A7）

#### Task A3：NakWithDelay + DLQ 写入侧（FR-004）
**文件：** `/home/binance/internal/server/consumer/consumer.go:195` + 新建 deadletter 包
- [ ] **步骤 1：编写失败测试**（TDD-RED）——失败注入：第 6 次投递（MaxDeliver 耗尽）后消息进入 DLQ 持久化
- [ ] **步骤 2：运行验证失败**
- [ ] **步骤 3：改 consumer.go:195** `msg.Nak()` → `msg.NakWithDelay(5 * time.Second)`（retryable 路径）
- [ ] **步骤 4：实现 DLQ 写入侧**——MaxDeliver 耗尽后路由到 `internal/server/deadletter/`（持久化，admin `/admin/dead-letter` 读端点已存在，见 Report1 §7.2 R3）
- [ ] **步骤 5：运行测试验证通过**
- [ ] **步骤 6：回归** `go test ./internal/server/...`
- [ ] **步骤 7：提交**：`feat(binance): NakWithDelay(5s) + DLQ 写入侧 (FR-004/TC-006)`；更新 TRACEABILITY TC-006

#### Task A4：跨产品线碰撞测试（FR-002 / TC-003）
**文件：** `/home/binance/internal/client/instrumentkey_test.go`
- [ ] **步骤 1：编写碰撞断言**（TDD-RED）

```go
func TestInstrumentKey_CrossProductLine_NoCollision(t *testing.T) {
	// spot BTCUSDT vs um_perp BTCUSDT vs cm_perp BTCUSDT vs options BTCUSDT
	// 断言：四个 key 互不相等（productLine 维度隔离生效）
	// 引用 NewInstrumentKey (product_line.go:141)
}
```

- [ ] **步骤 2：运行验证**（若实现正确应直接 PASS；若 FAIL 说明 instrument_key 构造有缺陷需修）
- [ ] **步骤 3：提交**：`test(binance): 跨产品线碰撞断言 (FR-002/TC-003/AC-BNC-002)`；更新 TRACEABILITY TC-003

#### Task A7：options 结构化 parser（FR-030）
**文件：** `/home/binance/internal/server/`（normalize 逻辑文件，需先定位 switch）
- [ ] **步骤 1：定位** `grep -rn 'switch.*productLine\|case.*spot\|case.*um_perp' /home/binance/internal/`，找到 normalize switch
- [ ] **步骤 2：编写失败测试**——options 事件（greek/strike/expiry）应解析成功而非命中 default→normalizeError
- [ ] **步骤 3：补 options 专用分支**（解析 greek/strike/expiry 字段，保留 RawPayload 透传）
- [ ] **步骤 4：运行验证通过**
- [ ] **步骤 5：提交**：`feat(binance): options 结构化 parser (FR-030)`

---

### Phase 5 [P1 · Track B]：binance 内部收敛（B4/B5）

#### Task B4：client assembly 下沉到 cmd（Report2 §7.4）
**文件：** `/home/binance/internal/client/runtime.go:172` + `cmd/binance-client/main.go`
- [ ] **步骤 1：编写失败测试**——`internal/client` 包禁止出现 `natsx.New`（gate 式测试）
- [ ] **步骤 2：把 `runtime.go:172` 的 `natsx.New` 构造移到 `cmd/binance-client/main.go`**
- [ ] **步骤 3：`internal/client` 改为接收注入的 port**（与 server 端 `cmd/binance-server/main.go` 一致）
- [ ] **步骤 4：回归** `go build ./... && go test ./internal/client/...`
- [ ] **步骤 5：提交**：`refactor(binance): client assembly 下沉到 cmd (Report2 §7.4)`

#### Task B5：wire → contracts 迁移（ADR-002 收口）
**文件：** `/home/binance/internal/wire/*` → `/home/contracts`；修改 binance `go.mod`
- [ ] **步骤 1：确认 ADR-002 计划**（`internal/wire/doc.go` + `module/binance/ADR-002-wire-boundary.md`）
- [ ] **步骤 2：把 wire 契约（doc.go/transport.go/types.go）上提到 `/home/contracts`**
- [ ] **步骤 3：binance go.mod require contracts**（当前 0 命中，见 §1.3）
- [ ] **步骤 4：全仓替换** `internal/wire` import → `contracts`
- [ ] **步骤 5：回归** `go build ./... && bash scripts/boundary-gates.sh`（确认 13 gates 仍 PASS）
- [ ] **步骤 6：提交**：`refactor(binance): wire 契约迁移到 contracts (ADR-002 收口, Report2 §7.5)`

---

### Phase 6 [P1 · Track A]：发布就绪（A5/A6）

#### Task A5：Release artifact 实际产出验证
- [ ] **步骤 1：确认当前缺口**（release.yml 在，tag v0.1.0/v0.1.1 在，但 release/ 无 artifact）
- [ ] **步骤 2：等 A1/A2/A3 验证后**，push `v0.2.0` tag
- [ ] **步骤 3：确认 release.yml 触发** GitHub Release + `binaries.tar.gz` + `evidence.tar.gz` 真实产出
- [ ] **步骤 4：归档** release URL 到 `release/evidence/binance/{date}/release-artifact.txt`
- [ ] **步骤 5：建议同步升 Runtime-Version v0.1.0 → v0.2.0**（Report1 §8.3）

#### Task A6：压测与 SLO 报告（NFR-001~004）
- [ ] **步骤 1：跑 bench** `go test -bench=. -benchmem ./internal/...`（5 个 bench_test.go）
- [ ] **步骤 2：真实负载压测**——natsx P99<10ms / taosx 100K TPS / Gin <5ms
- [ ] **步骤 3：出 SLO 报告** `release/evidence/binance/{date}/slo-report.md`
- [ ] **步骤 4：提交** evidence

---

### Phase 7 [P2]：文档与收尾（A8/A9/A10/B6/B7/B8）

#### Task A8：规格端一致性收尾（本仓库 module/binance）
- [ ] **步骤 1：FR 部分实现数量核实**——Report1 §0/§3.1 称「8」但 §3.3 仅列 7（FR-002/004/016/017/024/026/030），**补全差额第 8 个**
- [ ] **步骤 2：文档 SHA 统一**到 `8290dc9`（README/STATUS/ARCHITECTURE 当前滞后，Report1 §5/§13.4）
- [ ] **步骤 3：FR-006a 追溯补齐**（TRACEABILITY/ACCEPTANCE，Report1 §13.1）
- [ ] **步骤 4：AC 缺号确认**（AC-39,42-43,46,49-58... 是区间缩写还是真缺号，Report1 §13.3）
- [ ] **步骤 5：状态刷新**——TRACEABILITY §1 + §6 仪表盘按「22 已实现 / 8 部分实现」刷新（遵循 CLAUDE.md §5.1 单一事实来源：§6 从 §1 派生）
- [ ] **步骤 6：跨文件检查脚本**（CLAUDE.md §5.4）确认无残留矛盾
- [ ] **步骤 7：提交**：`docs(binance): 规格端一致性收尾 (SHA/FR-006a/AC/状态, Report1 §5)`

#### Task A9：§12.10/§12.11 代码级复核
- [ ] **步骤 1：bar 多周期**——`grep -rn 'interval\|period\|1m\|5m\|15m' /home/binance/internal/client/connectors/`，确认是否仅 1m
- [ ] **步骤 2：depth update_id 拼合**——grep depth/lastUpdateId，确认是否实现
- [ ] **步骤 3：据实更新 Report1 §4.1 对应行的 ⚠️ 状态
- [ ] **步骤 4：提交**（若有实现缺口则建后续 Task；仅复核则记入执行对齐文档）

#### Task A10：FR-024 全量 config hot reload
- [ ] **步骤 1：确认当前**——`admin.go:96` 仅 symbol catalog reload
- [ ] **步骤 2：评估** `pkg/binancecfg` 加 Watch/SIGHUP 的成本（P2，可延后）
- [ ] **步骤 3：提交**决策记录（做/延后 + 理由）

#### Task B6/B7/B8：架构文档与 gate 推广
- [ ] **B6**：在 `/home/bootstrap` 文档单列「装配层（composition root）」，与 6 零依赖叶子基座区分
- [ ] **B7**：同步 domain_exchange/macro main 与 worktree/v100（B2 完成后消除版本漂移）
- [ ] **B8**：把 Report2 §6 的 9 个 gate 固化为可执行脚本，以 binance `boundary-gates.sh` 为模板推广（更新 `module/binance/BOUNDARY-GATES.md`）
- [ ] **提交**：`docs(arch): bootstrap 分层 + gate 推广 (Report2 §6/§7.6)`

---

### Phase 8：验收门 + 文档对齐 + version bump

#### Task 8.1：双轨验收
- [ ] **步骤 1**：Track A——A1~A10 全 DONE，FR 闭合度 30/30、AC/TC 重核全 PASS
- [ ] **步骤 2**：Track B——B1~B8 全 DONE，重跑 Report2 §6 四硬门禁（反向依赖=0、领域纯度=0、infra 互耦=0、config split=0）
- [ ] **步骤 3**：`cd /home/binance && bash scripts/boundary-gates.sh`（13 gates）+ `go test ./... -count=1`（全绿）+ `govulncheck`

#### Task 8.2：文档对齐（三文档同步）
- [ ] 按 CLAUDE.md「文档同步」+「模块工作流规则 §3」：更新 `module/binance/TRACEABILITY.md`、`ACCEPTANCE.md`、`SPEC.md`、本仓库 `README.md`/`STATUS.md`/`ARCHITECTURE.md` 的 SHA + 状态
- [ ] 跑 `python3 scripts/audit-status.py --network`，全部 PASS

#### Task 8.3：version bump（PR 最后一个 commit）
- [ ] `./scripts/version-bump.sh --level minor`（MINOR：新增章节/架构收口）
- [ ] Runtime-Version v0.1.0 → v0.2.0（Report1 §8.3 建议）

---

## 5. 自检（writing-plans skill self-check）

**1. 规格覆盖度：** 两份报告的全部发现 →
- Report1：G1→A1、G2→A2、G3→A3、G4→A4、G5→A5、G6→A8、R6→A6、R8→A7、§12.10/12.11→A9、FR-024→A10。**10/10 覆盖，无遗漏。**
- Report2：§7.1→B1、§7.2→B2、§7.3→B3、§7.4→B4、§7.5→B5、§7.6→B6、§7.7→B7、§6/§8→B8。**8/8 覆盖，无遗漏。**

**2. 占位符扫描：** 无「待定/TODO/类似任务 N」。代码任务（A1/A3/A4/A7/B4）均含实际测试代码或精确 file:line + 步骤。doc/infra 任务含精确命令。

**3. 类型一致性：** file:line 引用全部经 §1.3 独立核实（history_fetcher.go:64-65、consumer.go:195、runtime.go:172、product_line.go:141、admin.go:96），无前后矛盾。

**4. 额外捕获：** Report1 §0/§3.1「8 部分实现」vs §3.3「7 行」差额 → Task A8 步骤 1 补全（Pass 10 捕获）。

---

## 6. 验收口径

**Plan007 完成定义（全部满足）：**
- [ ] Track A：A1~A10 全 DONE；`module/binance` FR 30/30 Implemented、AC/TC 重核全 PASS
- [ ] Track B：B1~B8 全 DONE；Report2 §6 四硬门禁重跑 PASS
- [ ] runtime：`go test ./...` 全绿 + `boundary-gates.sh` 13 gates + `govulncheck` 0
- [ ] evidence：`release/evidence/binance/{date}/` 含 testnet-live + infra-e2e + slo-report + release-artifact
- [ ] 文档：三文档 SHA 同步 `8290dc9`（或更新 HEAD）、`audit-status.py --network` 全 PASS
- [ ] version：manifest MINOR bump + Runtime-Version v0.2.0，bump 为 PR 最后 commit

**到生产级别口径**：上述全满足 = Report1 §0「收尾 4 类缺口」闭合 + Report2 §0「3 工程隐患 + 过渡态收口」闭合。

---

## 附录：来源追溯矩阵

| 任务 | Report1 来源 | Report2 来源 | 优先级 | Phase | 状态 |
|---|---|---|:---:|:---:|:---:|
| A1 | §0 G1 / §3.3 FR-016,017 / §7.1 R1 | — | P0 | 1 | TODO |
| A2 | §0 G2 / §4.1 / §7.1 R2 | — | P0 | 3 | TODO |
| A3 | §0 G3 / §3.3 FR-004 / §7.2 R3 | — | P1 | 4 | TODO |
| A4 | §0 G4 / §3.3 FR-002 / §7.2 R4 | — | P1 | 4 | TODO |
| A5 | §0 G5 / §4.1 §12.7 / §7.2 R5 | — | P1 | 6 | TODO |
| A6 | §6.1 R6 / §7.2 | — | P1 | 6 | TODO |
| A7 | §3.3 FR-030 / §7.2 R8 | — | P1 | 4 | TODO |
| A8 | §5 G6 / §7.3 R7 / §13 | — | P2 | 7 | TODO |
| A9 | §4.1 §12.10/12.11 / §7.3 | — | P2 | 7 | TODO |
| A10 | §3.3 FR-024 | — | P2 | 7 | TODO |
| B1 | — | §7.1 | 高 | 2 | TODO |
| B2 | — | §7.2 | 高 | 2 | TODO |
| B3 | — | §7.3 | 中 | 2 | TODO |
| B4 | — | §7.4 | 中 | 5 | TODO |
| B5 | — | §7.5 | 中 | 5 | TODO |
| B6 | — | §7.6 | 低 | 7 | TODO |
| B7 | — | §7.7 | 低 | 7 | TODO |
| B8 | — | §6 / §8 | 低 | 7 | TODO |

**工作量汇总**（对齐 Report1 §6.2 的 0.8~1.8 人月）：
- Phase 1 (A1)：0.3~0.5pm · Phase 2 (B1/B2/B3)：0.15~0.25pm · Phase 3 (A2)：0.2~0.4pm
- Phase 4 (A3/A4/A7)：0.15~0.3pm · Phase 5 (B4/B5)：0.1~0.2pm · Phase 6 (A5/A6)：0.1~0.2pm
- Phase 7+8：0.1~0.2pm · **合计 ≈ 1.1~2.05pm**（与报告 ±50% 区间吻合）

---

> **执行交接**：计划已保存到 `plans/binance/007-binance-readiness-arch-fix.md`。
> 两种执行方式——
> 1. **子代理驱动（推荐）**：每个 Task 调度新子代理，任务间审查（`superpowers:subagent-driven-development`）
> 2. **内联执行**：当前会话用 `superpowers:executing-plans` 批量执行设检查点
>
> 双轨可并行：Track A（binance runtime + module/binance 规格）与 Track B（跨仓库 transportx/domain_*）由不同工程师推进，Phase 8 汇合验收。

[RULES I BROKE]：无。本计划为只读分析的执行化产物，未修改任何受保护 runtime/spec 文件（仅创建本 plan 文档 + 更新 plans/binance/README.md 索引）；所有 file:line 引用经 §1.3 独立 grep/Read 核实，非凭记忆假设；证据标签与置信度按 CONSTITUTION §20 标注；双轨并行性结论基于代码实证的依赖扫描（Report2 §1-§5），非推测。
