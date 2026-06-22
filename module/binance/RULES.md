# module/binance RULES.md — 模块治理规则

- Doc-Version: v2.0.0
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

**修复义务**：发现漂移 → 当个 PR 内修复 → bump SPEC PATCH 版本 → 更新 NAMING.md 变更历史

---

## R2【硬】4 × 6 对称命名矩阵无缺口

**规则**：`module/binance/` 的 product_line（spot/um_perp/cm_perp/options）× event_type（tick/trade/bar/depth/funding_rate/mark_price）构成 24 个命名组合，全部组合必须在以下 5 个合同层面对称存在：

1. natsx subject（`SPEC.md` §9 + `RUNTIME-MAPPING.md`）
2. Kafka topic（`TASK-BINANCE-SERVER-014-kafkax-dispatch.md`）
3. TDengine 子表（`TASK-BINANCE-SERVER-013-taosx-storage.md`）
4. ossx 归档路径（`TASK-BINANCE-SERVER-016-ossx-archiver.md`）
5. Gin REST API（`TASK-BINANCE-SERVER-015-gin-market-api.md`）

**违规**：缺失任一组合（例如缺 `binance.market.options.depth`）

**能力例外**：R2 约束的是命名层与合同层的可寻址性，不等价于交易所已经对所有 24 个组合提供数据。runtime 可对暂不支持的组合显式返回 capability/status，不得用缺失命名来表达不支持。

**检测**：
```bash
# 期望返回 24 × 5 = 120 行（每层 24 个组合）
for layer in "binance\.market\." "binance\." "binance_market_" "binance/" "/api/v1/market/"; do
  echo "=== $layer ==="
  grep -rE "$layer" module/binance/ --include="*.md" | wc -l
done
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
| 状态字段修正 / 文档错字 / 链接修复 | PATCH | Pending → Implemented |
| 追溯矩阵新增 TC/AC | PATCH | TC-029 新增 |
| 治理体系重构（如废弃 TRACEABILITY） | MAJOR | — |

**违规**：变更未 bump 或 bump 级别错误

**检测**：PR 描述必须显式声明 bump 级别 + 触发理由，CI gate `version-bump-check.sh` 验证

**强制约束**：
- 版本号只能升不能降
- bump 必须是 PR 最后一个 commit
- 子规格版本（client/SPEC.md、server/SPEC.md）独立 bump，但根 SPEC.md bump 时所有引用根 SPEC 的子追溯矩阵 `Spec-Reference` 字段必须同步更新

---

## R4【硬】状态三层一致

**规则**：FR/BR/AC 的实现状态必须在三个层面一致：

1. **追溯矩阵**（`TRACEABILITY.md`、`{client,server}/TRACEABILITY.md`）"实现状态" 列
2. **runtime 仓** 实际代码与 CI gate 证据（`gh api repos/ZoneCNH/binance`）
3. **报告**（`docs/report/binance/**`）的 [COMPUTED] 标签

**违规**：根矩阵 "Implemented" 但 runtime 仓未推送对应代码；或报告称 Pending 但矩阵称 Implemented

**检测**：
```bash
# 1. 根 TRACEABILITY Implemented 数量
grep -cE "\| \*\*Implemented\*\*" module/binance/TRACEABILITY.md
# 2. boundary-gates.sh 实际 PASS 数量（在 /home/binance）
cd /home/binance && bash scripts/boundary-gates.sh 2>&1 | grep -c "PASS"
# 3. 期望：两数相等
```

**修复义务**：
- 同步状态时必须附 boundary-gate 输出或 git SHA 证据
- 不可仅凭 "已写代码" 主观判断，必须 CI gate PASS
- runtime 仓未推送时，所有 FR 实现状态默认 `Pending — 以 runtime 仓为准`

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
| `STANDARD.md` | 模块标准入口与权威顺序 |
| `SPEC.md` | 23 节模块规格 |
| `TRACEABILITY.md` | FR/BR/NFR/TC/AC 追溯矩阵 |
| `ACCEPTANCE.md` | 验收清单 |
| `FEATURES.md` | 功能特性总览 |
| `DATA-LIFECYCLE.md` | 历史/实时数据生命周期草案与 FR-012~FR-024 讨论稿 |
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

**检测**：
```bash
for f in STANDARD.md SPEC.md TRACEABILITY.md ACCEPTANCE.md FEATURES.md DATA-LIFECYCLE.md IMPLEMENTATION-PLAN.md \
         RUNTIME-MAPPING.md BOUNDARY-GATES.md NAMING.md RULES.md \
         ARCHITECTURE-DRIFT-WATCHLIST.md CHANGELOG.md; do
  [ -f "module/binance/$f" ] && echo "✓ $f" || echo "✗ $f MISSING"
done
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
| 2026-06-23 | v1.0.2 | R9 文档存在性新增 `DATA-LIFECYCLE.md`，并要求脚本覆盖 `STANDARD.md` / `DATA-LIFECYCLE.md` 两个入口。 | ZoneCNH |
| 2026-06-23 | v1.0.1 | R9 文档存在性新增 `STANDARD.md`，对齐 #871 模块标准入口。 | ZoneCNH |
| 2026-06-22 | v1.0.0 | 首次建立。整合 2026-06-22 治理审计复盘 + binance/SPEC.md §11 NFR 治理章节 + CLAUDE.md 编辑纪律，规则 R1-R10 全部可机器检测 | ZoneCNH |
