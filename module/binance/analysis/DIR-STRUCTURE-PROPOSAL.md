# module/binance 治理目录结构优化提案

- Proposal-ID: binance-dir-structure-20260626
- Status: Proposal（待讨论审批）
- Created: 2026-06-26
- Trigger: 数据域 CS 架构 module/binance 的治理结构是否需要优化？→ **需要 — 6 项目录级结构调整**
- Related: `GOVERNANCE-TIER-PROPOSAL.md`（分层治理）、`structural-architecture-analysis-20260626.md`（代码架构）

---

## 零、现状：82 个文件，6 层目录

```
module/binance/                   17 文件（14 .md + 1 .yaml + 1 ADR + specs/exchangeinfo-sync.md）
├── client/                       19 文件（4 治理 + 14 tasks + 1 archive）
├── server/                       29 文件（10 治理 + 2 spec + 16 tasks + 1 archive）
├── tasks/                         8 文件（7 root tasks + 1 TASK-ROOT-007）
├── analysis/                      8 文件（4 archive + 1 active eval + 1 proposal + 2 index）
└── HISTORY/                       1 文件
```

## 一、七项结构张力诊断

### T1【HIGH】SPEC 碎片化 — 根级双 SPEC

`SPEC.md`（2176 行）和 `specs/exchangeinfo-sync.md`（525 行）并列为根级 spec 文件。`specs/exchangeinfo-sync.md` 自称"增补章节"但独立成文件——形成事实上的分裂 spec。任何工具或 agent 扫描 `module/binance/*.md` 时会看到两个 spec 文件，无法判断哪个是主入口。

**建议**：`specs/exchangeinfo-sync.md` → `specs/exchangeinfo-sync.md`，根 README 引用"增补规格见 `specs/`"。

### T2【MEDIUM】ADR 孤岛 — 无 adr/ 目录，编号断层

`adr/ADR-002-wire-boundary.md` 是唯一的 ADR，孤悬在根目录。无 `adr/` 目录，无 ADR-001。与 `ADR-TEMPLATE.md` 的 `module/{模块}/ADR-NNN-*.md` 约定一致，但缺少容器目录。

**建议**：创建 `adr/README.md` + 移入 `adr/adr/ADR-002-wire-boundary.md`。

### T3【HIGH】三层 tasks 分散 — 37 个 task 跨 3 个目录

```
tasks/                          7 个 root task
tasks/client/                  14 个 client task
tasks/server/                  16 个 server task
```

当一个 task 引用另一个 task 时（如 `TASK-BINANCE-ROOT-001 → CLIENT-001`），路径是不明确的——是 `../tasks/client/` 还是 `../tasks/client/`？agent 遍历 task 时需要搜索 3 个目录。

**建议**：整合为单一 `tasks/` 树：
```
tasks/
├── README.md
├── root/        ← 原 tasks/
│   ├── TASK-BINANCE-ROOT-*.md
│   └── archive/
├── client/      ← 原 tasks/client/
│   ├── TASK-BINANCE-CLIENT-*.md
│   └── archive/
└── server/      ← 原 tasks/server/
    ├── TASK-BINANCE-SERVER-*.md
    └── archive/
```

### T4【MEDIUM】server/ 治理文档散落 — 10 个顶层文件

server/ 根目录混杂了 SPEC/TRACEABILITY（核心 spec）与 7 个 L3 治理文档（PERSISTENCE-WIRING、ENDPOINTS、OPERATIONS、SECURITY、OBSERVABILITY、DATA-LIFECYCLE、DATA-QUALITY-SLA）。核心 spec 被治理文档淹没。

**建议**：7 个 L3 文档下沉到 `server/docs/`：

```
server/
├── README.md
├── SPEC.md
├── TRACEABILITY.md
└── docs/                    ← 7 个 L3 治理文档
    ├── PERSISTENCE-WIRING.md
    ├── ENDPOINTS.md
    ├── DATA-LIFECYCLE.md
    ├── DATA-QUALITY-SLA.md
    ├── OPERATIONS.md
    ├── OBSERVABILITY.md
    └── SECURITY.md
```

### T5【LOW】analysis/ 混合归档与活跃提案

`analysis/` 目录同时包含：
- 4 个已归档的 DEEP-ANALYSIS-ARCHIVE-*（只读历史快照）
- 1 个活跃评估（A10-FR024-HOT-RELOAD-EVAL.md）
- 1 个活跃提案（GOVERNANCE-TIER-PROPOSAL.md）
- 2 个索引文件

活跃提案被误认为"已归档的深度分析"的风险存在。

**建议**：拆分为 `analysis/archive/`（历史快照）和 `analysis/`（活跃分析+索引）：

```
analysis/
├── README.md
├── DEEP-ANALYSIS.md               # 归档索引
├── DEEP-ANALYSIS-INDEX.md         # 快速跳转
├── A10-FR024-HOT-RELOAD-EVAL.md   # 活跃评估
├── GOVERNANCE-TIER-PROPOSAL.md    # 活跃提案
└── archive/                       # 历史快照
    ├── DEEP-ANALYSIS-ARCHIVE-architecture.md
    ├── DEEP-ANALYSIS-ARCHIVE-integration.md
    └── DEEP-ANALYSIS-ARCHIVE-operations.md
```

### T6【MEDIUM】ci-workflow.yaml 位于模块根

`ci-workflow.yaml` 引用 runtime 仓库的 GitHub Actions（`github.com/ZoneCNH/binance/actions/workflows/boundary-gates.yml`），但位于 spec 仓库的模块目录中。这是"spec 侧 CI 触发配置"还是"runtime CI 的 spec 投影"？当前语义不明确。

**建议**：保留但加注释说明其角色（spec 侧触发 runtime CI 的 gate 配置），或移动到 `.github/workflows/` 仓库级别。

### T7【LOW】IMPLEMENTATION-PLAN.md 三层各有一份

根级（113 行）、client/（53 行）、server/（67 行）各有一份 IMPLEMENTATION-PLAN.md。内容独立无重复（根=跨切+gate+PR顺序，client=catalog→publisher，server=consumer→storage），但读者需要理解"哪份是主入口"。

**建议**：保留三份（内容独立有价值），但在根 README.md 的 Read Next 中明确引用路径。

---

## 二、优化后的目标布局

```
module/binance/                         # L3 全量治理参考实现
│
├── README.md                           # 模块入口（SSOT 声明 + 子模块索引）
├── goal.md                             # 业务目标
├── SPEC.md                             # 根规格（C/S 边界契约，2176 行）
├── TRACEABILITY.md                     # 根追溯矩阵
├── ACCEPTANCE.md                       # 验收清单
├── FEATURES.md                         # 功能特性总览
├── CHANGELOG.md                        # 变更历史
├── NAMING.md                           # 命名 SSOT
├── RULES.md                            # 治理规则（R1-R11）
├── STANDARD.md                         # Runtime control standard
├── BOUNDARY-GATES.md                   # CI gate 定义
├── RUNTIME-MAPPING.md                  # Runtime 仓映射
├── IMPLEMENTATION-PLAN.md              # 主实现计划（跨切 + gate + PR 顺序）
├── ARCHITECTURE-DRIFT-WATCHLIST.md     # 漂移监控
├── ci-workflow.yaml                    # CI 触发配置（spec→runtime gate）
│
├── adr/                                # ★ 架构决策记录
│   ├── README.md
│   └── adr/ADR-002-wire-boundary.md
│
├── specs/                              # ★ 增补规格
│   └── exchangeinfo-sync.md            # FR-031~036（原 specs/exchangeinfo-sync.md）
│
├── client/                             # 客户端子模块
│   ├── README.md
│   ├── SPEC.md
│   ├── TRACEABILITY.md
│   └── IMPLEMENTATION-PLAN.md
│
├── server/                             # 服务端子模块
│   ├── README.md
│   ├── SPEC.md
│   ├── TRACEABILITY.md
│   ├── IMPLEMENTATION-PLAN.md
│   └── docs/                           # ★ server 专属治理文档（原散落在 server/ 根）
│       ├── PERSISTENCE-WIRING.md
│       ├── ENDPOINTS.md
│       ├── DATA-LIFECYCLE.md
│       ├── DATA-QUALITY-SLA.md
│       ├── OPERATIONS.md
│       ├── OBSERVABILITY.md
│       └── SECURITY.md
│
├── tasks/                              # ★ 整合所有 task
│   ├── README.md
│   ├── root/                           # ← 原 tasks/
│   │   ├── TASK-BINANCE-ROOT-*.md
│   │   └── archive/
│   ├── client/                         # ← 原 tasks/client/
│   │   ├── TASK-BINANCE-CLIENT-*.md (active: 001-007, 010-014)
│   │   └── archive/ (008-grpc-sender, 009-spool-checkpoint)
│   └── server/                         # ← 原 tasks/server/
│       ├── TASK-BINANCE-SERVER-*.md (active: 002-003, 006-017)
│       └── archive/ (001-grpc-ingest, 004-ingest-ack, 005-downstream-dispatch)
│
├── analysis/                           # 深度分析
│   ├── README.md
│   ├── DEEP-ANALYSIS.md                # 归档索引
│   ├── DEEP-ANALYSIS-INDEX.md          # 快速跳转
│   ├── A10-FR024-HOT-RELOAD-EVAL.md    # 活跃评估
│   ├── GOVERNANCE-TIER-PROPOSAL.md     # 活跃提案
│   └── archive/                        # ★ 历史快照（原 analysis/ 根）
│       ├── DEEP-ANALYSIS-ARCHIVE-architecture.md
│       ├── DEEP-ANALYSIS-ARCHIVE-integration.md
│       └── DEEP-ANALYSIS-ARCHIVE-operations.md
│
└── HISTORY/                            # 文档历史摘要
    └── TRACEABILITY-HISTORY.md
```

### 变更统计

| 操作 | 数量 | 说明 |
|------|------|------|
| 新建目录 | 5 | `adr/` `specs/` `server/docs/` `tasks/root/` `analysis/archive/` |
| 移动文件 | 20 | SPEC-exchangeinfo-sync → specs/; ADR-002 → adr/; 7 server docs → server/docs/; 14 client tasks → tasks/client/; 16 server tasks → tasks/server/; 7 root tasks → tasks/root/; 3 analysis archives → analysis/archive/ |
| 更新引用 | ~80 | 所有文档中的相对路径引用 |
| 删除文件 | 0 | 无删除；所有内容保留 |

---

## 三、影响评估

### 收益

1. **SPEC 入口唯一化** — `SPEC.md` 是唯一的主 spec 文件，增补 spec 在 `specs/`，消除歧义
2. **ADR 规范化** — `adr/` 目录提供明确位置，后续 ADR-003+ 自然归位
3. **Task 统一遍历** — agent 和开发者只需搜索 `tasks/` 一棵树
4. **server/ 治理降噪** — 核心 spec（SPEC/TRACEABILITY）不再被 7 个治理文档淹没
5. **analysis/ 语义清晰** — `archive/` vs 活跃文件边界明确，不会误读历史快照为当前建议
6. **C/S 模板更清晰** — okx/hyperliquid 可以直接参考这个布局搭建

### 风险和缓解

| 风险 | 缓解 |
|------|------|
| 大量相对路径引用断裂 | 全量 grep + sed 批量更新路径；`check-binance-docs.sh` 验证 |
| agent/自动化依赖旧路径 | 先建新目录 + 移动文件 + 更新引用，最后删旧路径 |
| 子模块 IMPLEMENTATION-PLAN 路径变化 | client/ 和 server/ 的 IMPLEMENTATION-PLAN 不移动（保持在子模块根） |

---

## 四、执行顺序

| Phase | 行动 | 影响文件 |
|-------|------|----------|
| D1 | 创建 5 个新目录 | 0（仅 mkdir） |
| D2 | 移动 7 个 server 治理文档 → `server/docs/` | 7 moves |
| D3 | 整合 tasks → 3 个子目录 | 37 moves |
| D4 | 移动 SPEC-exchangeinfo-sync → `specs/` | 1 move |
| D5 | 移动 ADR-002 → `adr/` + 创建 adr/README.md | 1 move + 1 new |
| D6 | 移动 3 个 analysis archive → `analysis/archive/` | 3 moves |
| D7 | 全量引用路径更新 | ~80 files |
| D8 | `check-binance-docs.sh` 验证 + git diff | — |

---

## 五、变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-26 | v1.0.0-draft | 初始提案：6 项目录结构调整 + 目标布局 + 执行计划 |
