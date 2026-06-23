# module/binance RULES.md — 模块治理规则

- Module-Version: v3.3.0
- Last-Updated: 2026-06-23
- 适用范围：`module/binance/` 全部规格文档 + `github.com/ZoneCNH/binance` runtime 仓
- 优先级：本文 > 子规格 > task；与 `CONSTITUTION.md` §0-§20 冲突时以 `CONSTITUTION.md` 为准
- 强制级别：每条规则标注【硬】（违反即治理违规）/【软】（推荐）/【开】（仅验证存在性）

> 本文件源自 2026-06-22 治理审计复盘。审计发现 4 套命名漂移、Options depth 缺口、状态口径不一致、子规格版本漂移、归档 task 未物理隔离等 5 类系统性问题，本文将其转化为可执行规则。

---

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

**BR-001 边界声明豁免**：`README.md`、`FEATURES.md`、`CHANGELOG.md`、`IMPLEMENTATION-PLAN.md`、`client/README.md`、`server/IMPLEMENTATION-PLAN.md` 中以 `binance-market` 为对象的引用，若语境是 BR-001 "已移除 / 禁止恢复 / 禁止路径" 边界声明（非描述性历史叙事），视为合法边界 gate 证据，不构成 R1 漂移。描述性"取代 binance-market"冗余叙事应压缩到 `SPEC.md` §3 + `docs/migrations/remove-binance-market.md` 单一入口。

**修复义务**：发现漂移 → 当个 PR 内修复 → bump SPEC PATCH 版本 → 更新 NAMING.md 变更历史

---

## R2【硬】4 × 4 对称矩阵无缺口

**规则**：`module/binance/` 的 product_line（spot/um_perp/cm_perp/options）× event_type（tick/trade/bar/depth）构成 16 个组合，全部组合必须在以下 5 个层面对称存在：

1. natsx subject（`SPEC.md` §9 + `RUNTIME-MAPPING.md`）
2. Kafka topic（`binance.{product_line}.{event_type}.v1`；`TASK-BINANCE-SERVER-014-kafkax-dispatch.md`）
3. TDengine 子表（`TASK-BINANCE-SERVER-013-taosx-storage.md`）
4. ossx 归档路径（`TASK-BINANCE-SERVER-016-ossx-archiver.md`）
5. Gin REST API（`TASK-BINANCE-SERVER-015-gin-market-api.md`）

**违规**：缺失任一组合（例如缺 `binance.market.options.depth`）

**检测**：
```bash
bash scripts/check-binance-docs.sh
```

**例外**：暂不实现的组合必须显式标注 `[POSTPONED <task-id>]`，且 PR 描述说明推迟理由

**修复义务**：发现缺口 → 同 PR 补全或显式 POSTPONED → bump SPEC MINOR 版本

---

## R3【硬】版本 bump 触发器

**规则**：bump 触发器、版本字段名统一、Spec-Version/Runtime-Version 分层遵循 [`CONSTITUTION.md` §10.4](../../docs/constitution/10-change-management.md)（跨模块统一规则）。本节仅补充 binance 模块特有约束。

**CONSTITUTION §10.4 要点**（引用，不重复）：
- Spec-Version 只反映接口契约演进；文档治理变更仅更新 `Last-Updated`，不 bump
- 版本字段名：`Spec-Version`（SPEC.md）/ `Module-Version`（治理文档，== root SPEC）/ `Runtime-Version`（runtime 版本）
- 版本号只能升不能降；bump 必须是 PR 最后一个 commit

**binance 模块特有约束**：
- 子规格版本（client/SPEC.md、server/SPEC.md）独立 bump，但根 SPEC.md bump 时所有引用根 SPEC 的子追溯矩阵 `Spec-Reference` 字段必须同步更新
- 子规格 bump 时，对应 `TRACEABILITY.md` 的 `Module-Version` + `Spec-Reference` 必须同 commit 同步（见 R6）

> [COMPUTED, HIGH] 2026-06-23 收紧：此前 v3.1.0/v3.2.0/v3.3.0 三次 bump 中，v3.1.0（issue 闭环 + 版本同步）、v3.3.0（版本号统一）属文档治理类，按 CONSTITUTION §10.4 无需 bump。spec 版本通胀根因即是把文档治理当契约 bump。收紧后规则已上提至 CONSTITUTION §10.4，本节为模块级引用。

**违规**：契约变更未 bump、或文档治理变更错误触发 bump、或 bump 级别错误、或子规格 bump 未同步 TRACEABILITY

**检测**：PR 描述必须显式声明 bump 级别 + 触发理由（契约变更）或"无需 bump（文档治理）"；CI gate `version-bump-check.sh` + `scripts/check-binance-docs.sh` 验证

---

## R4【硬】状态 L1/L2 分层一致

**规则**：FR/BR/AC 的实现状态必须按 L1/L2 分层同步，不得用 boundary gate 证据替代功能验收：

1. **L1 Boundary/Governance Gate**：只覆盖 FR-009 / BR-005 / BR-009 等边界治理约束，可用 runtime SHA + CI workflow URL + boundary-gates.sh PASS 标记 `Implemented`。
2. **L2 Functional Runtime FR**：FR-001~FR-008、FR-010 及后续功能 FR 只能在 runtime feature tests / integration tests / reproducible commit SHA 同时存在时标记 `Implemented`。
3. **报告**（`docs/report/binance/**`）的 [COMPUTED] 标签必须区分 L1 boundary evidence 与 L2 functional evidence。

**违规**：用 boundary gate PASS 推导 FR-001~FR-008/FR-010 已实现；根矩阵 "Implemented" 但 runtime 仓未推送对应代码；或报告称 Pending 但矩阵称 Implemented。

**检测**：
```bash
bash scripts/check-binance-docs.sh
```

**修复义务**：
- 同步 L1 状态时必须附 boundary-gate 输出或 git SHA 证据
- 同步 L2 状态时必须附对应 feature test / integration test 输出和 runtime git SHA
- 不可仅凭 "已写代码" 主观判断，必须 CI gate PASS
- runtime 仓未推送时，所有 L2 FR 实现状态默认 `Pending — 以 runtime 仓为准`

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

## R6【硬】模块版本统一与元数据同步

**规则**：`module/binance/` 版本字段名与版本号必须统一：

1. **字段名收敛**：仅允许 2 种版本字段名
   - `Spec-Version`：仅 root/client/server 的 `SPEC.md`
   - `Module-Version`：所有其他治理文档（ACCEPTANCE / FEATURES / IMPLEMENTATION-PLAN / TRACEABILITY / CHANGELOG / NAMING / RULES / DATA-LIFECYCLE / STANDARD / ARCHITECTURE-DRIFT-WATCHLIST / README）
   - `Runtime-Version`：仅 SPEC.md 的 runtime 版本（与 Spec-Version 语义区分，独立不 bump）
   - **禁止** `Doc-Version` / `Matrix-Version` / `Version` 等异名字段
2. **顶层版本号统一**：所有顶层治理文档的 `Module-Version` 必须 == root `SPEC.md` 的 `Spec-Version`
3. **子规格版本独立**：`client/SPEC.md` / `server/SPEC.md` 的 `Spec-Version` 独立 bump（见 R3）；其 `TRACEABILITY.md` 的 `Module-Version` 必须等于对应子规格的 `Spec-Version`
4. **Spec-Reference 闭环**：所有 `Spec-Reference` 字段必须指向正确的 SPEC + 版本号

**违规**：使用异名字段名；顶层 Module-Version 与 root SPEC Spec-Version 不一致；子规格 TRACEABILITY Module-Version 与子 SPEC Spec-Version 不一致；Spec-Reference 指向错误版本

**检测**：
```bash
bash scripts/check-binance-docs.sh   # 含 R6 全量版本统一校验
```

**修复义务**：SPEC bump 时同 commit 更新所有顶层 Module-Version + Spec-Reference；子规格 bump 时同 commit 更新对应 TRACEABILITY

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
| `BOUNDARY-GATES.md` | CI gate 定义 |
| `NAMING.md` | 命名 SSOT |
| `RULES.md` | 治理规则（本文） |
| `ARCHITECTURE-DRIFT-WATCHLIST.md` | 漂移监控点 |
| `CHANGELOG.md` | 模块变更历史 |
| `client/SPEC.md` + `client/TRACEABILITY.md` | 客户端子规格 |
| `server/SPEC.md` + `server/TRACEABILITY.md` | 服务端子规格 |
| `{client,server}/tasks/archive/README.md` | 归档映射 |
| `STANDARD.md` | 模块标准入口（runtime control + evidence 薄层索引） |
| `DATA-LIFECYCLE.md` | 数据生命周期讨论稿（FR-012~024 落点规划） |
| `scripts/check-binance-docs.sh` | binance 文档漂移 CI gate（仓库脚本） |

**检测**：
```bash
for f in SPEC.md TRACEABILITY.md ACCEPTANCE.md FEATURES.md IMPLEMENTATION-PLAN.md \
         RUNTIME-MAPPING.md BOUNDARY-GATES.md NAMING.md RULES.md \
         ARCHITECTURE-DRIFT-WATCHLIST.md CHANGELOG.md; do
  [ -f "module/binance/$f" ] && echo "✓ $f" || echo "✗ $f MISSING"
done
test -x scripts/check-binance-docs.sh
```

---

## R10【开】CI gate 引用

**规则**：BOUNDARY-GATES.md 的 12 个 gate 必须有 boundary-gates.sh 在 runtime 仓的对应实现：

- §1-§4 基础边界（C/S 进程隔离 + import 检查）
- §5 No cs Package（BR-005）
- §6 No Same-Process Adapter
- §7 Server Owns Storage（BR-006）
- §8 Wire Contract Externality（BR-008）
- §9 No Domain Ownership（BR-007）
- §10 Reserved
- §11 go.mod Dependency Compliance（BR-009）
- §12 Reserved

**检测**：根 TRACEABILITY.md FR-009 实现状态以 boundary-gates.sh 输出为唯一证据

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

**升级条件**：连续 3 次同类违规 → 在 RULES.md 新增对应硬约束 / 加 CI gate

---

## 12. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|---|---|---|---|
| 2026-06-22 | v1.0.1 | 接入 `scripts/check-binance-docs.sh`，明确 Kafka topic canonical v1 格式，并将状态一致性规则拆分为 L1 boundary gate 与 L2 functional runtime FR | ZoneCNH |
| 2026-06-22 | v1.0.0 | 首次建立。整合 2026-06-22 治理审计复盘 + binance/SPEC.md §11 NFR 治理章节 + CLAUDE.md 编辑纪律，规则 R1-R10 全部可机器检测 | ZoneCNH |
