# module/binance RULES.md — 模块治理规则

- Doc-Version: v1.0.1
- Last-Updated: 2026-06-23
- 适用范围：`module/binance/` 全部规格文档 + `github.com/ZoneCNH/binance` runtime 仓
- 优先级：`CONSTITUTION.md` > `module/binance/SPEC.md` > `module/binance/STANDARD.md` > `module/binance/DATA-LIFECYCLE.md` > 本文 > 子规格 > task
- 强制级别：每条规则标注【硬】（违反即治理违规）/【软】（推荐）/【开】（仅验证存在性）

> 本文件源自 2026-06-22 治理审计复盘，并在 2026-06-23 对齐 v2.2.3 L1/L2 evidence 语义。审计发现 4 套命名漂移、Options depth 缺口、状态口径不一致、子规格版本漂移、归档 task 未物理隔离等 5 类系统性问题，本文将其转化为可执行规则。

---

## R0【硬】证据层级语义

**规则**：`module/binance/` 所有完成状态必须显式绑定证据层级，禁止无层级的完成断言。

| 层级 | 含义 | 可接受证据 |
| --- | --- | --- |
| L1 | 文档、追溯矩阵、验收矩阵、任务命名和权威链一致。 | `module/binance` 文档差异与本规则集检查。 |
| L2 | `/home/binance` 本地 runtime 证据可复核。 | Runtime SHA `f30322e00794f9f0af7353c4f8e1cd2b6cc398b3`，且仅以下命令可作为当前 L2 完成证据：`boundary-gates 10/10 PASS`、`go test ./... PASS`、`XGO_BINANCE_SMOKE_SELF_TEST=1 go run ./cmd/binance-smoke PASS`。 |
| L3 | live Binance、production credentials、GitHub CI、release evidence。 | 直接的 live / production / CI / release 证据；未取得前必须写 `Blocked` 或 `Pending`。 |

**违规**：把 L1/L2 证据外推为 live Binance、production credentials、GitHub CI 或 release 完成；或使用没有 L1/L2/L3 前缀的完成状态。

**检测**：
```bash
rg -n "PASS" module/binance/ | rg "live Binance|production credentials|GitHub CI"
rg -n "release 完成|release ready|live production complete" module/binance/
rg -n "\| \*\*[A-Za-z ]+\*\*" module/binance/TRACEABILITY.md
```

**修复义务**：所有完成状态改写为 `L1/L2 PASS`、`L3 PASS`、`Pending` 或 `Blocked`，并附 runtime SHA 与对应命令证据。

## R1【硬】命名一致性 — Naming SSOT 不可漂移

**规则**：`module/binance/` 全部文档与 runtime 代码的 `product_line`、`event_type`、natsx subject、Kafka topic、TDengine stable/tag、Redis key、ossx 路径、Gin API、Go 文件名、环境变量必须 100% 匹配 `module/binance/NAMING.md` §1-§10。

**违规**：使用 `usdm_futures`、`coinm_futures`、`futures_usdt`、`futures_coin`、`option`、`opts` 等历史别名

**检测**：`NAMING.md` §11 给出 4 条 grep 命令，期望全部 0 行命中

**例外**：以下文件允许引用历史别名（仅作为漂移证据保留）：
- `NAMING.md`（"历史别名" 列）
- `RULES.md`（本文 "违规" 示例）
- `ARCHITECTURE-DRIFT-WATCHLIST.md`（漂移历史）
- `docs/report/binance/**`（治理审计报告）
- `module/binance/{client,server}/tasks/archive/**`（归档 task）

**修复义务**：发现漂移 → 当个 PR 内修复 → bump SPEC PATCH 版本 → 更新 NAMING.md 变更历史

---

## R2【硬】4 × 4 对称矩阵无缺口

**规则**：`module/binance/` 的 product_line（spot/um_perp/cm_perp/options）× event_type（tick/trade/bar/depth）构成 16 个组合，全部组合必须在以下 5 个层面对称存在：

1. natsx subject（`SPEC.md` §9 + `RUNTIME-MAPPING.md`）
2. Kafka topic（`TASK-BINANCE-SERVER-014-kafkax-dispatch.md`）
3. TDengine 子表（`TASK-BINANCE-SERVER-013-taosx-storage.md`）
4. ossx 归档路径（`TASK-BINANCE-SERVER-016-ossx-archiver.md`）
5. Gin REST API（`TASK-BINANCE-SERVER-015-gin-market-api.md`）

**Kafka topic 规则**：Kafka topic 必须使用 `binance.{product_line}.{event_type}.v1`。

`binance.market.*` 仅允许用于 natsx subject 语义，不得作为 downstream namespace。

**违规**：缺失任一组合；Kafka topic 缺少 `.v1` 版本后缀；或把 natsx subject 与 Kafka topic namespace 混用。

**检测**：
```bash
# 期望返回 16 × 5 = 80 行（每层 16 个组合）
for layer in "nats:binance\.market\." "kafka:binance\.(spot|um_perp|cm_perp|options)\.(tick|trade|bar|depth)\.v1" "binance_market_" "binance/" "/api/v1/market/"; do
  echo "=== $layer ==="
  rg -n "$layer" module/binance/ --glob "*.md" | wc -l
done
forbidden_ns="binance\\.market"
rg -n "$forbidden_ns" module/binance/ | rg "Kafka|kafkax|topic"
```

**例外**：暂不实现的组合必须显式标注 `[POSTPONED <task-id>]`，且 PR 描述说明推迟理由

**修复义务**：发现缺口 → 同 PR 补全或显式 POSTPONED → bump SPEC MINOR 版本

---

## R3【硬】版本 bump 触发器

**规则**：以下变更必须对应 SPEC 版本号 bump：

| 变更类型 | bump 级别 | 示例 |
|---|---|---|
| FR/BR/NFR 接口/契约变更 | MINOR | 新增 FR、修改 AC 语义 |
| 命名收敛 / subject/topic/key 重命名 | MINOR | um_perp 命名统一 |
| product_line / event_type 枚举变更 | MAJOR | 新增 USDⓈ-M Delivery |
| 状态字段修正 / 文档错字 / 链接修复 | PATCH | Pending → L1/L2 PASS |
| 追溯矩阵新增 TC/AC | PATCH | TC-029 新增 |
| 治理体系重构（如废弃 TRACEABILITY） | MAJOR | — |

**违规**：变更未 bump 或 bump 级别错误

**检测**：PR 描述必须显式声明 bump 级别 + 触发理由，由本地 rules gate `version-bump-check.sh` 验证

**强制约束**：
- 版本号只能升不能降
- bump 必须是 PR 最后一个 commit
- 子规格版本（client/SPEC.md、server/SPEC.md）独立 bump，但根 SPEC.md bump 时所有引用根 SPEC 的子追溯矩阵 `Spec-Reference` 字段必须同步更新

---

## R4【硬】状态三层一致

**规则**：FR/BR/AC 的实现状态必须在三个层面一致，并遵守 R0 证据层级：

1. **追溯矩阵**（`TRACEABILITY.md`、`{client,server}/TRACEABILITY.md`）"实现状态" 列与证据层级
2. **runtime 仓** 实际代码与 L2 命令证据（`/home/binance`）
3. **报告**（`docs/report/binance/**`）的 [COMPUTED] 标签

**违规**：根矩阵使用无层级完成状态；L2 PASS 缺 runtime SHA 或命令证据；报告称 Pending 但矩阵称 L1/L2 PASS；或 L3 claim 缺 live / production / CI / release 证据。

**检测**：
```bash
rg -n "\| \*\*[A-Za-z ]+\*\*" module/binance/TRACEABILITY.md
rg -n "f30322e00794f9f0af7353c4f8e1cd2b6cc398b3|boundary-gates 10/10 PASS|go test \./\.\.\. PASS|XGO_BINANCE_SMOKE_SELF_TEST=1 go run \./cmd/binance-smoke PASS" module/binance/
cd /home/binance && bash scripts/boundary-gates.sh
```

**修复义务**：
- 同步状态时必须附 runtime SHA 与命令证据。
- 不可仅凭 "已写代码" 主观判断。
- runtime 仓证据缺失时，所有 FR/BR/AC/TC 默认 `Pending — 以 runtime 仓为准`。

---

## R5【硬】归档物理隔离

**规则**：被新方案替代的 task / 规格文件必须物理移到 `archive/` 子目录，并附 `archive/README.md` 说明替代映射：

```
{client,server}/tasks/archive/
├── README.md              # 替代映射表（Archived → 替代 task → 替代原因）
├── TASK-OLD-001.md        # 被归档的原 task
└── TASK-OLD-002.md
```

**违规**：原地保留 + 加 `[ARCHIVED]` 标记（视觉污染 + 索引混淆）

**检测**：
```bash
# 期望 0 行命中（除 DEEP-ANALYSIS.md 的历史快照外）
grep -lE "^\> \[ARCHIVED" module/binance/ --include="*.md" -r | grep -v "DEEP-ANALYSIS\|archive/"
```

**修复义务**：
- 归档时使用 `git mv`（保留 history）
- `archive/README.md` 必须列出每个文件的 "替代 task ID + 架构变更原因 + 归档日期"
- 根 TRACEABILITY.md 的 Task 列引用归档 task 时，必须改引用替代 task

---

## R6【硬】ACCEPTANCE 元数据同步

**规则**：`module/binance/ACCEPTANCE.md` 顶部的 `Module-Version` 字段必须与 `module/binance/SPEC.md` 的 `Spec-Version` 同步。

**违规**：ACCEPTANCE Module-Version 落后于 SPEC Spec-Version

**检测**：
```bash
SPEC=$(grep -oP "Spec-Version: \Kv[0-9.]+" module/binance/SPEC.md)
ACC=$(grep -oP "Module-Version: \Kv[0-9.]+" module/binance/ACCEPTANCE.md)
[ "$SPEC" = "$ACC" ] && echo PASS || echo "FAIL: SPEC=$SPEC ACC=$ACC"
```

**修复义务**：SPEC bump 时同 commit 更新 ACCEPTANCE.md

**关联同步**：FEATURES.md / IMPLEMENTATION-PLAN.md 引用版本号的位置也需检查

---

## R7【软】证据标签强制

**规则**：`module/binance/` 内任何包含判断、推断、事实断言的文档段落，按宪法 §20 标注证据标签 + 置信度：

- `[KNOWN]` / `[COMPUTED]` / `[INFERRED]` / `[COMMON]` / `[FRAME]` / `[GUESS]`
- 置信度：HIGH ≥80% / MED 50-80% / LOW 20-50% / VERY LOW <20% / UNKNOWN
- `[FRAME]` 和 `[GUESS]` 上限 LOW
- 禁止 `[FRAME] → REALITY`（管线评分 / 治理状态 ≠ 代码正确）

**违规**：单纯陈述性段落（如 SPEC §背景）可豁免，分析/审查类文档（如 DEEP-ANALYSIS、报告）必须标注

**检测**：人工 + agent review，不阻断 CI

---

## R8【软】PR 聚合纪律

**规则**：
- 同模块文档修复 → 1 个 PR
- 跨文档同步（如 SPEC bump 触发 ACCEPTANCE 同步）→ 1 个 PR
- 禁止 1 行变更的 PR
- 同逻辑变更聚合为 1 个 commit
- 版本 bump 必须是 PR 最后一个 commit

**违规**：commit 粒度过细（如每个 Edit 后立即 commit）

**修复义务**：amend / rebase 合并相邻 commit

---

## R9【开】文档存在性

**规则**：`module/binance/` 必须存在以下文件（缺失即视为治理不完整）：

| 文件 | 用途 |
|---|---|
| `SPEC.md` | 23 节模块规格 |
| `TRACEABILITY.md` | FR/BR/NFR/TC/AC 追溯矩阵 |
| `ACCEPTANCE.md` | 验收清单 |
| `FEATURES.md` | 功能特性总览 |
| `IMPLEMENTATION-PLAN.md` | 实现计划 |
| `RUNTIME-MAPPING.md` | runtime 仓映射 |
| `BOUNDARY-GATES.md` | Boundary gate 定义 |
| `NAMING.md` | 命名 SSOT |
| `RULES.md` | 治理规则（本文） |
| `ARCHITECTURE-DRIFT-WATCHLIST.md` | 漂移监控点 |
| `CHANGELOG.md` | 模块变更历史 |
| `client/SPEC.md` + `client/TRACEABILITY.md` | 客户端子规格 |
| `server/SPEC.md` + `server/TRACEABILITY.md` | 服务端子规格 |
| `{client,server}/tasks/archive/README.md` | 归档映射 |

**检测**：
```bash
for f in SPEC.md TRACEABILITY.md ACCEPTANCE.md FEATURES.md IMPLEMENTATION-PLAN.md \
         RUNTIME-MAPPING.md BOUNDARY-GATES.md NAMING.md RULES.md \
         ARCHITECTURE-DRIFT-WATCHLIST.md CHANGELOG.md; do
  [ -f "module/binance/$f" ] && echo "✓ $f" || echo "✗ $f MISSING"
done
```

---

## R10【开】boundary gate 引用

**规则**：BOUNDARY-GATES.md 的 10 个可执行 gate 必须有 boundary-gates.sh 在 runtime 仓的对应实现：

- §1 C/S process boundary
- §2 No `binance-market` active dependency
- §3 Client must not import server internals
- §4 Server must not import client internals
- §5 No `internal/cs`
- §6 No same-process adapter
- §7 Server owns storage
- §8 Wire contract externality
- §9 No domain ownership
- §10 Dependency compliance（`go.mod` direct deps；BR-009）

**检测**：根 `TRACEABILITY.md` FR-009 的 L1/L2 PASS 必须以 runtime SHA `f30322e00794f9f0af7353c4f8e1cd2b6cc398b3` 和 `boundary-gates 10/10 PASS` 为证据；不得把该证据外推为 L3。

---

## 11. 规则违规处理流程

```
发现违规
  ↓
1. 评估影响范围（单文件 / 跨模块 / 跨仓库）
  ↓
2. 创建分支 fix/binance-rules-{Rx}-{描述}
  ↓
3. 同 PR 内修复 + 更新 NAMING/RULES/CHANGELOG（如需）
  ↓
4. bump SPEC PATCH/MINOR
  ↓
5. PR 描述附检测命令输出（修复前 vs 修复后）
  ↓
6. squash merge + 删除分支
```

**升级条件**：连续 3 次同类违规 → 在 RULES.md 新增对应硬约束 / 加本地 boundary gate

---

## 12. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|---|---|---|---|
| 2026-06-23 | v1.0.1 | 对齐 v2.2.3 L1/L2/L3 证据语义；修正 kafkax/ossx task 文件名；R10 改为 10 个可执行 gate；加入 STANDARD.md、DATA-LIFECYCLE.md 权威链 | ZoneCNH |
| 2026-06-22 | v1.0.0 | 首次建立。整合 2026-06-22 治理审计复盘 + binance/SPEC.md §11 NFR 治理章节 + CLAUDE.md 编辑纪律，规则 R1-R10 全部可机器检测 | ZoneCNH |
