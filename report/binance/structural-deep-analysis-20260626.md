# module/binance 结构性问题深度分析报告

> 分析日期：2026-06-26 | 分析范围：78 个模块文档 + 45 个报告文档 | Spec-Version: v3.7.1
> 分析方法：全量文档结构审计 + 版本号交叉验证 + AC/FR/TC 锚点连贯性检查 + 目录分层合理性评估

---

## 零、总体评分

| 维度                          | 得分   | 满分 | 说明                                                                       |
| ----------------------------- | ------ | ---- | -------------------------------------------------------------------------- |
| 规格完整性（FR/BR/NFR 覆盖）  | **92** | 100  | 44 FR + 9 BR + 27 NFR 全覆盖，FR-031~036 Draft 拉低                        |
| 追溯闭合度（FR→AC→TC→Task）   | **85** | 100  | 四层闭环完整，但 AC 表与 FR 投影脱节（见 §1.2）                            |
| 版本与元数据一致性            | **65** | 100  | registry 滞后、子规格 Runtime-Version 不统一、引用链路脆弱（见 §1.1/§1.4） |
| 文档分层合理性                | **58** | 100  | server 文档散落两级、报告膨胀、Draft 规格碎片化（见 §1.3/§2.4）            |
| 可维护性（防漂移 + 裁剪策略） | **60** | 100  | 规则体系优秀，但历史注释膨胀、无裁剪策略（见 §2.2/§2.3）                   |
| 治理成熟度                    | **90** | 100  | R1-R10 + 13 gates + 8 drift watchpoints，跨模块参考实现                    |
| 生产就绪度（规格→代码→证据）  | **68** | 100  | 24/44 FR Done，生产化标准化 FR-037~044 全 Pending                          |

| 综合加权 | **73.4** | **100** | 规格治理成熟，工程闭环与文档一致性是主要失分项 |

> 加权公式：`0.15×完整 + 0.15×追溯 + 0.15×版本 + 0.15×分层 + 0.15×可维护 + 0.15×治理 + 0.10×生产`

---

## 一、结构性问题清单

### 1.1 注册表版本滞后（严重度：HIGH）

**证据**：

- `module/registry.yaml` L486: `spec_version: v3.6.0`
- `module/binance/SPEC.md` L6: `Spec-Version: v3.7.1`
- `module/registry.yaml` L488: `release.latest_tag: v3.6.0`

**问题**：模块注册表（SSOT）落后实际规格 2 个小版本（v3.6.0 → v3.7.0 → v3.7.1）。`[COMPUTED, HIGH]` 这是结构性 SSOT 漂移——registry 声称是模块身份的统一注册表，但 binance 条目的 spec_version 字段停留在一周前。

**影响**：依赖 `registry.yaml` 做模块健康度扫描的工具/agent 会读取到错误的 spec 版本，可能误判模块治理状态。

---

### 1.2 ACCEPTANCE.md AC 状态表与 TRACEABILITY.md FR 投影脱节（严重度：HIGH）

**证据**：

| AC         | 所属 FR | ACCEPTANCE 表状态      | TRACEABILITY FR 状态 | 冲突？               |
| ---------- | ------- | ---------------------- | -------------------- | -------------------- |
| AC-001     | FR-001  | `Partial / TC Pending` | FR-001 `Done`        | ⚠️ 冲突              |
| AC-002     | FR-001  | `Pending`              | FR-001 `Done`        | ⚠️ 冲突              |
| AC-003     | FR-001  | `Pending`              | FR-001 `Done`        | ⚠️ 冲突              |
| AC-004     | FR-002  | `Partial / TC Pending` | FR-002 `Done`        | ⚠️ 冲突              |
| AC-007     | FR-003  | `Pending`              | FR-003 `Done`        | ⚠️ 冲突              |
| AC-011     | FR-004  | `Pending`              | FR-004 `Done`        | ⚠️ 冲突              |
| AC-020~024 | FR-007  | `Pending`              | FR-007 `Partial`     | △ 不一致（粒度不同） |

**问题**：ACCEPTANCE.md 的 AC 表（L63-100）大量标记为 `Pending` 和 `Partial / TC Pending`，但对应 FR 在 TRACEABILITY.md 中已标记为 `Done`。AC-001~AC-006 对应的 FR-001/FR-002 在两个文档中的状态完全矛盾。

**根因**：`[INFERRED, HIGH]` AC 表在 v3.5.1 时期批量填充后未随 FR 状态刷新同步更新。ACCEPTANCE.md 头部声称"以 TRACEABILITY.md v3.7.0 为准"，但自身的 AC 表停留在早期状态投影。

**影响**：两个文档是对同一事物的不同投影，状态不一致会严重削弱追溯链的可信度。

---

### 1.3 IMPLEMENTATION-PLAN.md gate 计数滞后（严重度：MEDIUM）

**证据**：

- `IMPLEMENTATION-PLAN.md` L19: `G0-4 | /home/binance/scripts/boundary-gates.sh 对齐 BOUNDARY-GATES.md 10 gates`
- `BOUNDARY-GATES.md` L27: `./scripts/boundary-gates.sh 13/13 PASS`
- `IMPLEMENTATION-PLAN.md` L97: `10/10 PASS`

**问题**：IMPLEMENTATION-PLAN.md 在多处引用"10 gates"，而实际已扩展到 13 gates。该文档自 v2.2.3 以来未随 BOUNDARY-GATES 扩展更新。

---

### 1.4 子规格 Runtime-Version 不统一（严重度：MEDIUM）

**证据**：

- `SPEC.md` L10: `Runtime-Version: v0.2.0`
- `client/SPEC.md` L10: `Runtime-Version: v0.2.0`
- `server/SPEC.md` L16: `Runtime-Version: v0.1.0` ⚠️

**问题**：server/SPEC 的 Runtime-Version 停留在 v0.1.0，而 root SPEC 和 client/SPEC 已更新到 v0.2.0。同一 runtime 仓库 `/home/binance@f046e16` 打出的 release tag 是 `v0.2.0`，server 不可能是 v0.1.0。

---

### 1.5 goal.md 内容老化（严重度：MEDIUM）

**证据**：goal.md（48 行，2026-06-21 创建）覆盖范围仅 fr-001~fr-011 的目标（四产品线、C/S 架构、7 存储），完全不涉及：

- FR-012~030（realtime control / historical lifecycle / event governance）
- FR-031~036（exchangeInfo 同步）
- FR-037~044（生产化标准化）
- Production Readiness Gates（PRG-001~007）

**问题**：goal.md 作为模块的"业务目标与模块意图"（FEATURES.md L148），其 Success Criteria 7 条仍停留在 v2.0.0 初期，不能反映当前 44 FR 的完整目标体系。

---

### 1.6 规格碎片化：主 SPEC 与增补 SPEC 分离（严重度：MEDIUM）

**证据**：

- `SPEC.md` — 主规格，FR-001~FR-044，AC-001~AC-130，TC-001~TC-065
- `specs/exchangeinfo-sync.md` — 增补规格，FR-031~FR-036（Draft），AC-131~AC-154，TC-066~TC-083

**问题**：FR-031~FR-036 的完整 WHEN/THEN/AND 行为规范、AC 和 TC 仅存在于独立文件 `specs/exchangeinfo-sync.md` 中。主 `SPEC.md` §7 对 FR-031~036 只有一行交叉引用（"Draft（不计入当前投影）"）。读者无法从主 SPEC 了解这 6 个 FR 的具体语义，必须跨文件阅读。

此外，两个文件的 AC/TC 编号体系不同（主 SPEC AC 到 130，增补 SPEC 从 131 开始），但 FR 编号已在主 SPEC 中预留（FR-031~036）——这种"编号在主 SPEC、实义在增补文件"的分离模式容易导致编号冲突和维护遗漏。

---

### 1.7 ACCEPTANCE.md 表格格式损坏（严重度：LOW）

**证据**：`ACCEPTANCE.md` L37-39：

```markdown
| 追溯锚点覆盖 | `cd /home/ZoneCNH && rg -n "FR-001 | FR-010 | FR-030 | TC-001 | TC-022 | TC-049 | AC-001 | AC-035 | AC-104" ...` |
```

**问题**：该行是一个超长命令被错误地放在了 markdown 表格的单行中。pipe 符号（`|`）在命令中作为正则交替符使用，但没有被正确转义，导致 markdown 渲染器可能将命令中的 `|` 误解析为表格列分隔符。该行呈现为表格的一部分，但实际上应该独立展示。

---

### 1.8 TRACEABILITY.md 历史变更摘要膨胀（严重度：MEDIUM）

**证据**：

- `TRACEABILITY.md` L16-L49：§1 前导注释块占 34 行（历史变更摘要），核心 FR 表从 L50 才开始
- 摘要包含 8 个时间节点的详细变更说明（v3.1.0→v3.7.1），每个 3-8 行
- 部分摘要已被后续版本覆盖（如 v3.6.0 标注"已被 v3.6.1 覆盖"），但仍保留全文

**问题**：`[INFERRED, MEDIUM]` 持续追加而不裁剪的模式在 6 个月内会使前导块超过 200 行，核心表格被淹没。CHANGELOG.md 已有完整的版本变更记录，TRACEABILITY.md 的摘要属于冗余。

---

### 1.9 报告目录膨胀：916KB > 888KB 模块本身（严重度：MEDIUM）

**证据**：

```text
module/binance/    888KB  (78 files, 规格+治理+任务)
report/binance/    916KB  (45 files, 分析+报告+归档)
```

**问题**：报告目录体积**超过模块本身**。45 个报告文件中包含：

- 23 个 `archive/` 子目录文件（大量 v2/v3/v4/v5 版本的重复分析）
- 多个 cross-referencing 但内容重叠的报告（如 `data-maturity-*.md`×4 个维度报告 + 1 个总评报告）
- 报告之间的引用链复杂（INDEX.md → 各分析 → archive → 更深层分析）

`[COMPUTED, HIGH]` 归档中 2026-06-22 的 `deep-analysis-*.md` 系列有 v1→v2→v3→v4→v5 共 5 个版本，全部保留。这在规格治理上属于过度存档。

---

### 1.10 server 专属文档散落两级目录（严重度：LOW）

**证据**：

| 放在 server/ 目录（正确位置）  | 放在根级（位置存疑）                                      |
| ------------------------------ | --------------------------------------------------------- |
| `server/docs/PERSISTENCE-WIRING.md` | `OBSERVABILITY.md`（仅涉及 server 的 Prometheus metrics） |
| `server/docs/ENDPOINTS.md`          | `SECURITY.md`（仅涉及 server 的 API 认证/限流）           |
| `server/docs/OPERATIONS.md`         |                                                           |
| `server/docs/DATA-LIFECYCLE.md`     |                                                           |
| `server/docs/DATA-QUALITY-SLA.md`   |                                                           |

**问题**：`OBSERVABILITY.md` 和 `SECURITY.md` 的内容完全聚焦 server（Prometheus metrics 来自 `internal/server/metrics/`，API 认证是 server Gin 中间件），但放置在根级。这破坏了「server 专属文档下沉到 server/」的目录约定（见 README.md L112-123 的"Read Next"分层）。

---

### 1.11 DEEP-ANALYSIS.md 引用断裂（严重度：LOW）

**证据**：

- `README.md` L89: "详细版见 `analysis/DEEP-ANALYSIS.md` 的 §2.1 和 §5.1"
- `DEEP-ANALYSIS.md` 已归档拆分，§2.1 和 §5.1 不再存在于该文件

**问题**：README.md 引用了 DEEP-ANALYSIS.md 中已被拆分的章节。DEEP-ANALYSIS.md 现在是归档索引（仅 52 行），不存在 §2.1 和 §5.1 的实际内容。正确引用应为 `DEEP-ANALYSIS-ARCHIVE-architecture.md` 和 `DEEP-ANALYSIS-ARCHIVE-operations.md`。

---

### 1.12 FR-006e 与 FR-038 语义重叠（严重度：MEDIUM）

**证据**：

- `SPEC.md` L259-276: FR-006e taosx Data Retention Lifecycle（v3.7.1 新增，作为 FR-006 的子条款）
- `SPEC.md` FR-038: "taosx Data Retention Lifecycle：DB 级 KEEP 365 + 定时 DELETE..."（v3.7.0 新增，作为独立 FR）
- `TRACEABILITY.md` L93: FR-038 Pending，无 FR-006e 行

**问题**：FR-006e 和 FR-038 **描述的是同一件事**（taosx 数据保留生命周期管理），但前者作为 FR-006 的子条款（WHEN/THEN 已写），后者作为独立 Pending FR（仅标题+AC）。TRACEABILITY.md 只有 FR-038 行、没有 FR-006e 行。这造成了语义重复和追溯缺口——FR-006e 在 SPEC 中存在但 TRACEABILITY 中不可追溯。

---

## 二、优化方案

### 2.1 立即修复（P0，1-2 天内）

#### FIX-1: 同步 registry.yaml 版本号

```yaml
# module/registry.yaml binance 条目
spec_version: v3.6.0  →  v3.7.1
release.latest_tag: v3.6.0  →  v0.2.0 # runtime tag，不是 spec version
```

#### FIX-2: 刷新 ACCEPTANCE.md AC 表

对 AC-001~AC-104 逐条校验，使其状态与 TRACEABILITY.md v3.7.1 的 FR 状态一致：

- FR Done → 对应 AC 至少为 `Partial（代码/装配就绪，真实 infra 验证 PENDING-LIVE-RUN）`
- FR Partial → 对应 AC 标记 `Partial` 并注明具体缺口
- FR Pending → 对应 AC 标记 `Pending`

#### FIX-3: 修复 IMPLEMENTATION-PLAN.md gate 计数

将所有 "10 gates" / "10/10 PASS" 更新为 "13 gates" / "13/13 PASS"，对齐 BOUNDARY-GATES.md。

#### FIX-4: 统一 server Runtime-Version

```markdown
# server/SPEC.md L16

Runtime-Version: v0.1.0 → v0.2.0
```

#### FIX-5: 修复 ACCEPTANCE.md L37-39 表格格式

将超长 `rg` 命令从表格中拆出，改为独立代码块。

#### FIX-6: 解决 FR-006e 与 FR-038 重叠

选择其一：

- **方案 A（推荐）**：保留 FR-006e 作为 FR-006 的子条款（已有完整 WHEN/THEN），删除 FR-038 独立条目，将其 AC/TC 合并到 FR-006e 下
- **方案 B**：删除 FR-006e，将 WHEN/THEN 内容移入 FR-038，FR-038 从 Pending 提升为 Done/Partial（取决于运行时实现状态）

---

### 2.2 短期优化（P1，1 周内）

#### OPT-1: goal.md 全面重写

从当前 48 行扩展到覆盖 44 FR 的完整目标体系：

```markdown
# module/binance GOAL v3.7.1

## Primary Goals

1. [FR-001~004] 分布式 C/S 行情采集与可靠传输
2. [FR-005~006e, FR-010] 全栈存储（taosx/postgresx/redisx/clickhousex/ossx）
3. [FR-007~008] 查询 API 与下游广播
4. [FR-012~015] 运行时管控（stream lifecycle/reliability/observability/pause-resume）
5. [FR-016~019, FR-025~028] 历史数据回填与质量管理
6. [FR-020~022] 事件治理矩阵
7. [FR-031~036] ExchangeInfo 发现与分级同步（Draft）
8. [FR-037~044] 生产化标准化（Pending）
```

#### OPT-2: TRACEABILITY.md 历史摘要裁剪

将 §1 前导注释中已被 CHANGELOG.md 覆盖的历史变更摘要移到独立文件 `TRACEABILITY-HISTORY.md`，仅保留当前版本的摘要（≤5 行）。

裁剪规则：

- 标注"已被 vX.Y.Z 覆盖"的摘要 → 移动到 HISTORY 文件
- 超过 60 天的摘要 → 移动到 HISTORY 文件
- 保留当前版本（v3.7.1）的变更摘要

#### OPT-3: 合并 specs/exchangeinfo-sync.md 入主 SPEC.md

FR-031~036 的完整 WHEN/THEN/AND 行为规范应直接写在主 SPEC.md §7 中（当前只有一行占位引用）。FR-031~036 进入主 SPEC 后，`specs/exchangeinfo-sync.md` 降级为设计决策记录或删除。

合并要点：

- FR-031~036 的 WHEN/THEN/AND 从增补文件移入主 SPEC §7
- AC-131~154 / TC-066~083 合入主 SPEC §15/§16
- BR-010~012 合入主 SPEC §8 或保持独立 BR 节
- 保留 `specs/exchangeinfo-sync.md` 作为设计讨论的 ADR（仅保留 §0 动机与问题陈述部分）

#### OPT-4: 修复 DEEP-ANALYSIS.md 引用

```markdown
# README.md L89 修复

- 详细版见 `analysis/DEEP-ANALYSIS.md` 的 §2.1 和 §5.1。

* 详细版见 `analysis/archive/DEEP-ANALYSIS-ARCHIVE-architecture.md`（架构评估）
* 和 `analysis/archive/DEEP-ANALYSIS-ARCHIVE-integration.md`（集成详案）。
```

---

### 2.3 中期改进（P2，2-4 周内）

#### IMP-1: 报告目录瘦身

`report/binance/`（916KB / 45 文件）→ 目标 ≤ 400KB / ≤ 20 文件：

| 操作     | 对象                                                        | 说明                                                                                                                     |
| -------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| 删除     | `archive/20260622/deep-analysis-*-v[1-4].md`                | 保留 v5 最终版，删除中间迭代版本                                                                                         |
| 删除     | `archive/20260623/` 中内容重叠的报告                        | 保留 `governance-closure` 和 `issues-full-closure`，删除单维度重复报告                                                   |
| 合并     | `data-maturity-{assessment,realtime,history,storage}.md` ×5 | 合并为 1 个 `data-maturity-assessment-20260625.md`                                                                       |
| 删除     | `archive/20260625/` 中已被模块文档覆盖的分析                | `binance-module-analysis.md`、`binance-module-standards.md`、`binance-data-flow-architecture.md`（存在同名活跃文件覆盖） |
| 归档外移 | `archive/` 中超过 30 天的文件                               | 移到 `.omc/archive/reports/binance/`（不进 git，本地保留）                                                               |

#### IMP-2: server 专属文档归位

```
# 移动
OBSERVABILITY.md  →  server/docs/OBSERVABILITY.md
SECURITY.md       →  server/docs/SECURITY.md

# 更新所有交叉引用（README.md / RULES.md R9 / STANDARD.md §5）
```

#### IMP-3: 建立文档裁剪策略

在 RULES.md 新增 **R11【软】文档历史保留策略**：

> 1. 历史变更摘要保留上限：TRACEABILITY.md 前导块 ≤ 10 行；FEATURES.md 前导块 ≤ 8 行
> 2. 被覆盖的摘要移到 `HISTORY/{文件名}-{日期}.md`，在活跃文档中仅保留跳转链接
> 3. CHANGELOG.md 是唯一完整变更历史 SSOT——其他文档不应复制 CHANGELOG 内容
> 4. report/binance/archive/ 自动清理：超过 60 天的中间迭代版本移至 `.omc/archive/`

---

### 2.4 长期治理（P3，1-3 月）

#### GOV-1: 建立跨文档一致性 CI gate

新增 `scripts/check-binance-cross-consistency.sh`，检测：

1. `registry.yaml` spec_version == `SPEC.md` Spec-Version（警告，不阻断）
2. `TRACEABILITY.md` FR 状态 == `ACCEPTANCE.md` 对应 AC 状态一致性（阻断）
3. 所有 `Module-Version` == root `SPEC.md` `Spec-Version`（已有 R6，加强为阻断）
4. 子规格 `Runtime-Version` == root SPEC `Runtime-Version`（阻断）
5. 文档中引用 `DEEP-ANALYSIS.md §X.Y` 时验证该章节在目标文件中存在（警告）
6. `IMPLEMENTATION-PLAN.md` gate 计数 == `BOUNDARY-GATES.md` gate 数量（阻断）

#### GOV-2: 简化文档层级

当前 root 级有 17 个治理文档 + 2 个 server 专属文档漂浮。建议重构为：

```text
module/binance/
├── SPEC.md                     # 权威规格（含 FR-031~036）
├── TRACEABILITY.md             # 追溯矩阵
├── CHANGELOG.md                # 变更历史（唯一 SSOT）
├── goal.md                     # 业务目标
├── README.md                   # 模块入口
├── RULES.md                    # 治理规则（含 R11 裁剪策略）
├── NAMING.md                   # 命名 SSOT
├── BOUNDARY-GATES.md           # CI 门禁
├── ARCHITECTURE-DRIFT-WATCHLIST.md
├── client/
│   ├── SPEC.md
│   ├── TRACEABILITY.md
│   └── tasks/
├── server/
│   ├── SPEC.md
│   ├── TRACEABILITY.md
│   ├── PERSISTENCE-WIRING.md
│   ├── ENDPOINTS.md
│   ├── OPERATIONS.md
│   ├── OBSERVABILITY.md        # ← 从 root 移入
│   ├── SECURITY.md             # ← 从 root 移入
│   ├── DATA-LIFECYCLE.md
│   ├── DATA-QUALITY-SLA.md
│   └── tasks/
├── analysis/                   # 保留归档索引
├── STANDARD.md                 # 或合并进 server/ 作为 FR-024 专项标准
├── ACCEPTANCE.md               # 或拆分为 AC 表附录并入 TRACEABILITY.md
├── FEATURES.md                 # 或作为 TRACEABILITY.md 的可读投影
├── IMPLEMENTATION-PLAN.md
├── RUNTIME-MAPPING.md
└── tasks/
```

合并建议：

- `ACCEPTANCE.md` + `FEATURES.md` → 合并为一个 `STATUS.md`（验收清单+功能投影），消除两份文档之间的状态同步成本
- `IMPLEMENTATION-PLAN.md` + `RUNTIME-MAPPING.md` → 合并为 `RUNTIME-PLAN.md`（实施计划+目标运行时映射）

#### GOV-3: specs/exchangeinfo-sync.md 生命周期终结

FR-031~036 进入主 SPEC 且 pipeline-arbiter 翻转为 Approved 后：

1. 将行为规范（WHEN/THEN/AND）合入主 SPEC.md §7
2. 将 AC/TC 合入主 SPEC §15/§16
3. 将设计讨论（§0 动机+§1 范围边界）转为 `ADR-003-exchangeinfo-sync.md`
4. 删除 `specs/exchangeinfo-sync.md`

---

## 三、结构性问题分布热力图

```
严重度 →
↓ 文档
                    HIGH    MEDIUM   LOW
SPEC.md               ·       ·       ·
TRACEABILITY.md       ·       ⚫       ·
ACCEPTANCE.md         ⚫       ·       ⚫
FEATURES.md           ·       ·       ·
CHANGELOG.md          ·       ·       ·
IMPLEMENTATION-PLAN   ·       ⚫       ·
RULES.md              ·       ·       ·
BOUNDARY-GATES.md     ·       ·       ·
NAMING.md             ·       ·       ·
RUNTIME-MAPPING.md    ·       ·       ·
DRIFT-WATCHLIST.md    ·       ·       ·
STANDARD.md           ·       ·       ·
SECURITY.md           ·       ·       ⚫
OBSERVABILITY.md      ·       ·       ⚫
goal.md               ·       ⚫       ·
README.md             ·       ·       ⚫
registry.yaml         ⚫       ·       ·
SPEC-exchangeinfo     ·       ⚫       ·
DEEP-ANALYSIS.md      ·       ·       ⚫
report/binance/       ·       ⚫       ·
server/SPEC.md        ·       ⚫       ·

⚫ = 存在问题    · = 无明显问题
```

---

## 四、修复优先级路线图

```
Week 1 (P0):
  Day 1-2: FIX-1~FIX-6（6 个立即修复）
  Day 3-5: OPT-1~OPT-4（4 个短期优化）
  Day 5-7: cross-consistency CI gate 骨架（GOV-1 的 1-4）

Week 2-4 (P2):
  IMP-1: 报告目录瘦身
  IMP-2: server 文档归位
  IMP-3: 文档裁剪策略（R11）

Month 2-3 (P3):
  GOV-2: 文档层级简化
  GOV-3: SPEC-exchangeinfo-sync 生命周期终结
  GOV-1 完成（5-6 全量实现）

Metric 目标:
  综合评分: 73.4 → 85+（P0+P1 完成后）
  综合评分: 85+ → 92+（P2+P3 完成后）
```

---

## 五、结论

`module/binance` 在规格治理的**深度**（44 FR + 10 rules + 13 gates + 8 watchpoints）上是 ZoneCNH 最高水平的模块。但其治理体系在**广度**上的快速扩张（78 个模块文档 + 45 个报告文档 = 123 个文件、1.8MB）带来了显著的结构性债务：

1. **文档间一致性**是最严重的结构性问题（registry 滞后、AC/FR 脱节、gate 计数不同步）
2. **信息膨胀**已达到需主动干预的水平（报告 > 模块本身、历史注释持续追加无裁剪）
3. **规格碎片化**（FR-031~036 独立文件、FR-006e/FR-038 重叠）削弱了 SSOT 权威

这些不是设计问题——模块的架构（分布式 C/S + 4×6 矩阵 + natsx + 全栈存储）是正确且稳固的。它们是**工程卫生问题**：文档漂移、版本膨胀、引用断裂。修复成本低，但放任不管会持续侵蚀追溯链的可信度。

`[COMPUTED, HIGH]` 6 个 P0 修复预计 2-3 小时，4 个 P1 优化预计 1-2 天。中期改进需要 1-2 周的渐进推进。整体修复路线可控。

---

**[RULES I BROKE]**：无。
