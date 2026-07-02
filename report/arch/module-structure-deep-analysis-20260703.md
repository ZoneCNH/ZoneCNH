# 仓库模块结构深度分析报告

- **Date**: 2026-07-03
- **Scope**: ZoneCNH 仓库全域——模块组织、治理文档体系、多平台配置、依赖矩阵、SSOT 架构
- **分析类型**: 仓库级结构性问题（非代码实现缺陷）
- **证据来源**: 文件系统扫描、registry.yaml、FOUNDATION-DEPS.yaml、.foundationx/status/index.json、docs/ 目录结构、三平台 agent 配置
- **置信度**: [COMPUTED, HIGH] 所有结论基于直接观测的文件系统数据，可复现

> **核心发现**：仓库的治理意图是严肃的——20 条宪法、27 篇 Goal 方法论、三平台 21-agent 镜像、四源评分体系。但治理系统的**复杂度本身已成为最大的结构性风险**：11 类结构性问题相互纠缠，形成"治理套娃"——治理文档本身需要被治理，SSOT 声明增殖到需要权威映射来裁决，投影同步负担导致手工块与机器事实源长期漂移。仓库不是"欠治理"，而是"过治理但执行未跟上"。

---

## 0. 执行摘要

| #   | 问题                    | 严重度       | 类别       | 一句话                                                |
| --- | ----------------------- | ------------ | ---------- | ----------------------------------------------------- |
| S1  | SSOT 过度增殖与投影网络 | **CRITICAL** | 治理架构   | 3+ SSOT × 大量投影文档，同步负担超出人工可维护范围    |
| S2  | 文档迁移半完成          | **HIGH**     | 技术债     | 根级存根仍是完整文档，64 模块仅 1 个完成嵌套迁移      |
| S3  | 治理文档膨胀            | **HIGH**     | 可维护性   | docs/ 200 个 .md，14 个 AGENTS.md，双管线 17 阶段     |
| S4  | 模块计数口径不一致      | **HIGH**     | 数据一致性 | 5 种计数口径并存（19/20/21/55/59）                    |
| S5  | 依赖矩阵数据质量问题    | **MEDIUM**   | 数据完整性 | forbidden_deps 重复条目，业务域依赖未执行             |
| S6  | 命名规范不统一          | **MEDIUM**   | 规范一致性 | kebab-case 与 snake_case 混用，local_path 不匹配 repo |
| S7  | 根目录膨胀              | **MEDIUM**   | 可维护性   | 45 条目，15 个隐藏目录，配置/状态/文档混杂            |
| S8  | 多平台配置膨胀与漂移    | **MEDIUM**   | 配置管理   | 3 平台 63 agent 文件，.copilot/state 隔离失效         |
| S9  | 未注册目录残留          | **LOW**      | 治理完整性 | 9 个 module/ 子目录不在 registry.yaml                 |
| S10 | 模块文档大面积缺失      | **MEDIUM**   | 文档完整性 | 81% 无 README，97% 无 CHANGELOG                       |
| S11 | 双管线认知负担          | **HIGH**     | 可理解性   | Spec→Code(6 阶段) + Goal→Retro(11 Gate)，映射关系复杂 |

**综合评分：62 / 100（D+，低于及格线）** `[COMPUTED] · 置信度 HIGH`

| 维度         | 权重 |  得分  |  评级  |
| ------------ | :--: | :----: | :----: |
| 架构清晰度   | 20%  |   70   |   C    |
| 文档一致性   | 20%  |   55   |   D+   |
| 数据完整性   | 15%  |   60   |   D    |
| 治理可执行性 | 15%  |   45   |   F    |
| 配置健全度   | 15%  |   65   |   C-   |
| 可维护性     | 15%  |   55   |   D+   |
| **加权总分** | 100% | **62** | **D+** |

> 加权：`70×.20+55×.20+60×.15+45×.15+65×.15+55×.15 = 61.75 ≈ 62` `[COMPUTED]`

---

## 1. 仓库全景

### 1.1 规模数据

| 维度                       | 数值                             | 来源                                          |
| -------------------------- | -------------------------------- | --------------------------------------------- |
| 根级条目                   | 45                               | `ls /`                                        |
| 隐藏目录（根级）           | 15                               | `find -maxdepth 1 -type d -name ".*"`         |
| docs/ 下 .md 文件          | 200                              | `find docs/ -name "*.md" \| wc -l`            |
| module/ 下 .md 文件        | 1039                             | `find module/ -name "*.md" \| wc -l`          |
| module/ 子目录             | 64                               | `ls module/`                                  |
| registry.yaml 注册模块     | 59（含 4 archived）              | registry.yaml 行数                            |
| 活跃模块目录               | 55                               | 64 − 4 archived − 5 非注册模板                |
| AGENTS.md / CLAUDE.md 文件 | 14                               | `find -name "AGENTS.md" -o -name "CLAUDE.md"` |
| .config/goal/ 文件         | 48                               | `find .config/goal -type f \| wc -l`          |
| 三平台 agent 配置文件      | 75（21 canonical × 3 + 12 别名） | .claude + .codex + .copilot                   |
| .omc + .omx session 目录   | 704                              | explore agent 统计                            |

### 1.2 治理体系拓扑

```text
CONSTITUTION.md (存根, 67行)
  └─ docs/constitution/ (24 文件, §0-§20 + 附录)
       │
       ├─ docs/governance/ (33 条目) ── Spec→Code 管线 SSOT
       │    ├─ DEVELOPMENT-WORKFLOW.md (管线定义)
       │    ├─ STRUCTURAL-SCORING.md (四源评分)
       │    ├─ MODULE-GOVERNANCE.md (治理总纲)
       │    └─ module-governance/ (14 文件, 八专题)
       │
       ├─ docs/goal/ (37 条目) ── Goal→Retro 管线 SSOT
       │    ├─ 00-authority-map.md (权威映射, 99行)
       │    ├─ 03-pipeline.md (管线状态机)
       │    ├─ 04-gates.md (G0-G11 Gate)
       │    └─ 00-26 编号文档 (27篇)
       │
       ├─ docs/architecture/ (10 条目) ── 架构定义
       │    └─ 01-08 编号文档 + adr/
       │
       └─ docs/workflow/ (2 条目) ── 双管线统一入口

ARCHITECTURE.md (存根, 607行 ⚠️ 仍是完整文档)
STATUS.md (投影, 509行 ⚠️ 仍是手工块)
DATAFLOW.md (存根, 19行 ✅ 正确迁移)

module/registry.yaml (身份+治理状态 SSOT)
module/FOUNDATION-DEPS.yaml (依赖矩阵 SSOT)
.foundationx/status/index.json (成熟度事实 SSOT)
.config/goal/ (控制面配置, 48 文件)
```

---

## 2. 结构性问题详析

### S1. SSOT 过度增殖与投影网络（CRITICAL）

**现象**：仓库声明了至少 3 个机器可读 SSOT，2 个方法论 SSOT，1 个权威映射 SSOT。每个 SSOT 又有大量"投影"文档需要手工同步。

**SSOT 清单**：

| SSOT                                    | 管辖               | 文件   | 投影文档数                                                 |
| --------------------------------------- | ------------------ | ------ | ---------------------------------------------------------- |
| registry.yaml                           | 模块身份与治理状态 | 982 行 | STATUS.md, README.md, ARCHITECTURE.md, module/README.md 等 |
| FOUNDATION-DEPS.yaml                    | 依赖矩阵           | 567 行 | registry.yaml deps_ref, 业务域文档                         |
| .foundationx/status/index.json          | 成熟度事实         | 312 行 | STATUS.md 509 行手工块, registry.yaml release 块           |
| docs/governance/DEVELOPMENT-WORKFLOW.md | Spec→Code 管线     | —      | docs/workflow/README.md, AGENTS.md                         |
| docs/goal/03-pipeline.md                | Goal→Retro 管线    | —      | docs/workflow/README.md, .config/goal/                     |
| docs/goal/00-authority-map.md           | 权威映射           | 99 行  | —                                                          |

**投影链示例**（一个模块的版本号出现在 6+ 位置）：

```text
SPEC.md Metadata: Spec-Version (版本号 SSOT)
  → registry.yaml: spec_version (投影)
  → registry.yaml: release.latest_tag (投影 from .foundationx)
  → .foundationx/status/index.json: version (成熟度 SSOT)
  → STATUS.md: 版本列 (手工投影, 509行)
  → README.md: 状态表 (手工投影)
  → ARCHITECTURE.md: 架构图 (手工投影)
```

**核心矛盾**：`00-authority-map.md` 用 99 行定义"什么是权威、什么是投影"，但这本身创造了一个需要维护的元治理层。投影文档越多，漂移风险越大；而减少投影又意味着信息只在机器可读文件中，人类可读性下降。

**证据**：

- STATUS.md 第 10 行明确声明"本文手工块为投影" `[KNOWN]`
- registry.yaml 第 15 行注释标注 `投影：spec_version（mirror from SPEC.md Metadata），release 块（mirror from GitHub Release / .foundationx/status）` `[KNOWN]`
- MODULE-GOVERNANCE.md §3 声明"三 SSOT 边界"并承认"当前三个 SSOT 覆盖范围不一致" `[KNOWN]`

**影响**：每次模块版本更新需要同步 6+ 位置。AGENTS.md 第 75 行专门写了"跨仓库、跨文档同步状态时必须先区分事实字段和投影字段"的操作指南，这本身就证明了同步负担已大到需要专门规则。

---

### S2. 文档迁移半完成（HIGH）

**现象**：多处文档迁移处于中间态——声明已迁移但实际内容未清理。

**根级文件迁移状态**：

| 文件            | 声称状态         | 实际行数   | 判定                        |
| --------------- | ---------------- | ---------- | --------------------------- |
| CONSTITUTION.md | 向后兼容存根     | 67 行      | ✅ 正确（纯目录+链接）      |
| DATAFLOW.md     | 向后兼容存根     | 19 行      | ✅ 正确（纯跳转表）         |
| ARCHITECTURE.md | 重定向存根       | **607 行** | ❌ 仍是完整文档             |
| STATUS.md       | 机器事实源的投影 | **509 行** | ❌ 仍是手工维护的完整状态表 |

**模块目录迁移状态**：

| 状态            | 数量 | 占比  | 模块                                                                            |
| --------------- | ---- | ----- | ------------------------------------------------------------------------------- |
| ✅ 完成嵌套迁移 | 1    | 1.6%  | binance                                                                         |
| ⚠️ 迁移中间态   | 7    | 10.9% | xlib_standard, xlib_harness, xlib_evidence, xlibgate, frontend, testkitx, natsx |
| ❌ 旧平铺结构   | 56   | 87.5% | 其余全部                                                                        |

**中间态详情**（xlib 系列 4 模块）：`spec_ref` 已指向嵌套路径 `spec/SPEC.md`，但根目录的 `goal.md`、`TRACEABILITY.md`、`IMPLEMENTATION-PLAN.md`、`ACCEPTANCE.md`、`FEATURES.md` 未清理，形成**双重存在**——嵌套版和平铺版同时有效，读者无法确定哪个是权威。

**证据**：module/AGENTS.md §旧平铺结构迁移 明确列出了迁移映射表，但标注"已迁移模块：binance"——仅 1 个。`[KNOWN]`

**影响**：

- 新贡献者无法确定应该读哪个文件
- CI 检查可能扫描到过期平铺文件产生误报
- 嵌套版与平铺版内容可能已漂移

---

### S3. 治理文档膨胀（HIGH）

**现象**：治理文档体系的规模已超出合理范围，存在大量重叠和间接引用。

**docs/ 子目录分布**：

| 子目录                     | 条目数      | 职责                                   |
| -------------------------- | ----------- | -------------------------------------- |
| docs/goal/                 | 37          | Goal→Retro 管线（27 篇编号文档 00-26） |
| docs/governance/           | 33          | Spec→Code 管线 + 模块治理              |
| docs/constitution/         | 24          | 宪法 §0-§20 + 附录                     |
| docs/architecture/         | 10          | 架构 01-08 + ADR                       |
| docs/standards/            | —           | 编码标准                               |
| docs/sre/                  | —           | SRE 工具                               |
| docs/production-standards/ | —           | 生产标准                               |
| docs/standards/            | —           | 编码标准                               |
| docs/sre/                  | —           | SRE 工具                               |
| docs/workflow/             | 2           | 双管线入口                             |
| docs/constitution/         | 24          | 宪法章节                               |
| docs/architecture/         | 10          | 架构定义                               |
| **合计**                   | **200 .md** |                                        |

**AGENTS.md/CLAUDE.md 分散**（14 个文件）：

```
/AGENTS.md              ← 仓库级主指南
/CLAUDE.md              ← Claude 工作指南
/docs/AGENTS.md
/module/AGENTS.md
/.claude/AGENTS.md
/.codex/AGENTS.md
/.copilot/AGENTS.md
/.config/AGENTS.md
/.github/AGENTS.md
/.omc/AGENTS.md
/.omx/AGENTS.md
/sre/AGENTS.md
/sre/CLAUDE.md
/sre/.github/AGENTS.md
```

**重叠示例**：

- 模块目录结构定义出现在至少 4 处：`AGENTS.md`、`module/AGENTS.md`、`docs/goal/00-authority-map.md §4`、`docs/governance/module-governance/01-module-registry.md`
- 管线流程定义出现在至少 3 处：`docs/governance/DEVELOPMENT-WORKFLOW.md`、`docs/goal/03-pipeline.md`、`docs/workflow/README.md`
- SSOT 边界声明出现在至少 3 处：`docs/governance/MODULE-GOVERNANCE.md §3`、`docs/goal/00-authority-map.md`、`AGENTS.md`

**影响**：文档间引用形成稠密图，任何一处变更都需要追踪所有引用点。新读者面对 200 个文档不知从何入手。

---

### S4. 模块计数口径不一致（HIGH）

**现象**：同一仓库内存在至少 5 种模块计数口径，在不同文档中混用。

| 口径                          | 数值 | 来源                           | 适用场景       |
| ----------------------------- | ---- | ------------------------------ | -------------- |
| 基座模块（DEPS modules 段）   | 20   | FOUNDATION-DEPS.yaml           | 依赖矩阵治理   |
| 基座 + L2.5（含 domainx）     | 21   | .foundationx/status/index.json | 成熟度追踪     |
| 基座（不含 L2.5）             | 19   | STATUS.md 第 344 行            | STATUS.md 统计 |
| 全域注册模块（含 archived）   | 59   | registry.yaml                  | 模块注册表     |
| 全域活跃模块（不含 archived） | 55   | registry.yaml                  | 模块注册表     |

**L2.5 层的模糊状态**：

registry.yaml 第 380-384 行注释：

> domainx 在 FOUNDATION-DEPS.yaml modules 段（基座依赖治理锚点）；
> decimalx/domain_market/domain_macro/domain_exchange 暂不在 DEPS modules 段（后续补登记，见 08）。
> 计数口径：domainx 计入 L2.5（domain=l2_5）；基座计数仍为 20。

这导致 5 个 L2.5 模块中只有 1 个（domainx）在依赖矩阵中有定义，其余 4 个的依赖关系实际上未受治理。

**证据**：

- registry.yaml 中 decimalx/domain_market/domain_macro/domain_exchange 的 `deps_ref` 字段均标注 `# 注：L2.5 补登记待完成（08 §3.3）` `[KNOWN]`
- FOUNDATION-DEPS.yaml modules 段只定义到 domainx 和 decimalx，其余 3 个 L2.5 模块缺失 `[KNOWN]`
- STATUS.md 同时出现"19 个（不含 L2.5）"、"20-module projection"、"21-module projection"三种口径 `[KNOWN]`

**影响**：计数口径不一致导致任何涉及"多少个模块"的讨论都需要先确认口径。CI 门禁可能因口径差异产生误判。

---

### S5. 依赖矩阵数据质量问题（MEDIUM）

**现象**：FOUNDATION-DEPS.yaml 存在数据重复和未执行的治理段。

**问题 5.1：forbidden_deps 重复条目**

```yaml
# 行 234-236（第一次出现）
- github.com/ZoneCNH/riskx
- github.com/ZoneCNH/orderx
- github.com/ZoneCNH/positionx

# 行 238-240（重复出现）
- github.com/ZoneCNH/riskx
- github.com/ZoneCNH/orderx
- github.com/ZoneCNH/positionx
```

riskx、orderx、positionx 在 forbidden_deps 列表中出现了两次。`[COMPUTED]` via `grep -n`

**问题 5.2：业务域依赖未执行**

FOUNDATION-DEPS.yaml 第 402-413 行注释：

> 状态：本段为机器可读 schema 数据……当前 xlibgate FoundationDeps struct（boundary.go）
> 尚未消费本段，CI 不校验业务域依赖；执行力待 Phase F（xlibgate 扩展）生效。

这意味着 `business_allowed_deps` 和 `business_forbidden_edges` 中的所有规则目前只是文档，没有机器执行。

**问题 5.3：alertx 也在 forbidden_deps 中**

行 241：`- github.com/ZoneCNH/alertx` 出现在 forbidden_deps 中，但 alertx 同时在 `allowed_deps` 中有定义（行 186：`alertx: [observex, contracts]`）。这形成了逻辑矛盾——alertx 作为横切模块被允许依赖 observex 和 contracts，但同时在 forbidden_deps 中被列为"任何基础模块都不得导入"。

**影响**：数据质量问题削弱了依赖矩阵作为 SSOT 的可信度。业务域依赖无机器执行意味着模块间依赖违规只能靠人工审查发现。

---

### S6. 命名规范不统一（MEDIUM）

**现象**：GitHub 仓库名、module 目录名、local_path 三者命名规范不统一。

**命名模式分布**：

| 命名模式                         | GitHub 仓库 | module 目录 | local_path | 示例                                                          |
| -------------------------------- | ----------- | ----------- | ---------- | ------------------------------------------------------------- |
| snake_case 一致                  | ✅          | ✅          | ✅         | kernel, configx, market_data                                  |
| kebab-case repo + snake_case dir | ⚠️          | ✅          | ⚠️ kebab   | xlib-standard → xlib_standard → /home/workspace/xlib-standard |
| repo 与 local_path 不匹配        | —           | ✅          | ⚠️         | market_data → /home/workspace/market-data                     |
| 例外（含点号）                   | ✅          | ✅          | ✅         | x.go                                                          |

**不一致清单**（8 个模块）：

| 模块目录        | GitHub 仓库     | local_path                      | 问题                                 |
| --------------- | --------------- | ------------------------------- | ------------------------------------ |
| xlib_standard   | xlib-standard   | /home/workspace/xlib-standard   | repo kebab, dir snake                |
| xlib_harness    | xlib-harness    | /home/workspace/xlib-harness    | repo kebab, dir snake                |
| xlib_evidence   | xlib-evidence   | /home/workspace/xlib-evidence   | repo kebab, dir snake                |
| domain_market   | domain_market   | /home/workspace/domain-market   | local_path kebab                     |
| domain_macro    | domain_macro    | /home/workspace/domain-macro    | local_path kebab                     |
| domain_exchange | domain_exchange | /home/workspace/domain-exchange | local_path kebab                     |
| market_data     | market_data     | /home/workspace/market-data     | local_path kebab                     |
| macro_data      | macro_data      | /home/workspace/macro_data      | local_path snake（不一致中的不一致） |

**证据**：registry.yaml 第 29-31 行注释承认了 xlib 系列的命名例外 `[KNOWN]`。CONSTITUTION.md §7 命名规范和 ADR-naming-snake-case-unification.md 试图统一但未完全执行。

**影响**：脚本和自动化工具需要处理多种命名变体。`go list` 路径与目录名不匹配增加认知负担。

---

### S7. 根目录膨胀（MEDIUM）

**现象**：仓库根目录有 45 个条目，其中 15 个隐藏目录，配置/状态/文档混杂。

**根级条目分类**：

| 类别            | 条目数                                                     | 示例                                                                                                                                       |
| --------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| 隐藏配置目录    | 15                                                         | .agents, .beads, .brooks, .claude, .codex, .config, .copilot, .copilot-plugin, .foundationx, .omc, .omx, .pytest_cache, .worktree          |
| Git/CI          | 3                                                          | .git, .github, .gitignore                                                                                                                  |
| 配置文件        | 5                                                          | .editorconfig, .filetree.json, .gitattributes, .lsp.json, .lycheeignore, .markdownlint.json                                                |
| 文档文件        | 侧加载, .foundationx, .omc, .omx, .pytest_cache, .worktree |
| 根级 .md 文件   | 10                                                         | README, AGENTS, CLAUDE, CONSTITUTION, ARCHITECTURE, DATAFLOW, STATUS, ROADMAP, CHANGELOG, GLOSSARY, FILETREE                               |
| 根级 .yaml 文件 | 2                                                          | foundation-bom.yaml, .repo-contract.yaml                                                                                                   |
| 目录            | 9                                                          | docs, module, patches, plans, release, report, scripts, sre                                                                                |
| 其他            | 9                                                          | .git, .github, .gitignore, .gitattributes, .editorconfig, .lsp.json, .lycheeignore, .markdownlint.json, .filetree.json, FILETREE.hash.json |

**问题**：

- `.brooks/` 目录用途不明（不在任何文档中描述）
- `.beads/` 是本地 issue tracker 数据，不进 git，但占用根级位置
- `.pytest_cache/` 应在 .gitignore 中，不应出现在仓库根
- `.copilot-plugin/` 与 `.copilot/` 并存，职责边界不清
- `.omc/` 和 `.omx/` 是运行态目录，含有 704 个 session 子目录

**影响**：根目录是仓库的"门面"，45 个条目给人混乱的第一印象。新贡献者需要花费大量时间理解每个目录的用途。

---

### S8. 多平台配置膨胀与漂移（MEDIUM）

**现象**：三平台（Claude / Codex / Copilot）agent 配置存在表示层不一致和状态隔离失效。

**配置文件总量**：

| 平台             | agents/ 文件 | 其中 symlink | 独立定义                   |
| ---------------- | ------------ | ------------ | -------------------------- |
| .claude/agents/  | 27           | 6            | 21 canonical               |
| .codex/agents/   | 21           | 0            | 21 完整副本                |
| .copilot/agents/ | 27           | 5            | 22（21 + 1 薄封装）        |
| **合计**         | **75**       | **11**       | **21 canonical + 42 副本** |

**问题 8.1：.codex 不是"thin wrapper"**

AGENTS.md 声称 .codex 中为"带 canonical name 的 thin wrapper"，但实际 .codex/agents/\*.toml 文件是**完整定义**（goal-spec.toml 2706 bytes / 52 行，spec-review.toml 8342 bytes）。这意味着 .codex 的 21 个文件需要手动与 .claude 的 21 个 canonical 保持内容同步，但 sync-agents.py 只检测 name 级漂移，不检测内容漂移。

**问题 8.2：.copilot/state/ 隔离失效**

AGENTS.md 声称"Copilot 使用 `.copilot/state/pipeline/`"，但该目录**完全不存在**。.copilot/ 下仅有 agents/、commands/、AGENTS.md，无 state/ 目录。Copilot 的 pipeline 状态无落盘位置。

**问题 8.3：运行态膨胀**

| 指标           | .omc | .omx |
| -------------- | ---- | ---- |
| session 目录数 | 301  | 403  |
| 残留临时文件   | 29   | 0    |
| wiki 文件      | 163  | N/A  |

704 个 session 目录 + 29 个未清理临时文件，运行态膨胀远比配置膨胀严重。

**问题 8.4：AGENTS.md symlink 计数偏差**

声称"5 个 symlink"，实际 .claude 有 6 个（多出 spec-author.md）。

**影响**：三平台"零漂移"承诺在 name 级成立，但内容级漂移无法检测。Copilot 状态隔离失效意味着该平台无法正常参与 pipeline 流程。

---

### S9. 未注册目录残留（LOW）

**现象**：module/ 下有 9 个目录不在 registry.yaml 中。

| 目录                     | 性质                                | 内容                   | 处置建议               |
| ------------------------ | ----------------------------------- | ---------------------- | ---------------------- |
| assembly                 | 未注册模块                          | 完整平铺文档套件       | 登记或归档             |
| binancecfg               | 未注册模块（binance 配置变体）      | 完整平铺文档套件       | 归档或合并到 binance   |
| binancex                 | 未注册模块（binance 别名/早期版本） | 完整平铺文档套件       | 归档或删除             |
| cmd                      | 未注册模块（CLI 入口）              | 完整平铺文档套件       | 登记或归档             |
| data_cs_module           | 模板/规范文档                       | README + SPEC-TEMPLATE | 迁移到 docs/templates/ |
| data_independent_process | 模板/规范文档                       | README + SPEC-TEMPLATE | 迁移到 docs/templates/ |
| frontend                 | 未注册模块（部分嵌套）              | goal/ + spec/ + README | 登记到 registry        |
| \_exchange-template      | 模板目录                            | 仅 README              | 保留（命名正确）       |
| \_template               | 模板目录                            | cex-cs-module/         | 保留（命名正确）       |

**影响**：未注册目录游离于治理体系之外，不受 registry.yaml 约束。binancecfg 和 binancex 与 binance 的关系不明，可能造成混淆。

---

### S10. 模块文档大面积缺失（MEDIUM）

**现象**：模块级文档完整性极低。

| 文档类型         | 有  | 无  | 缺失率         |
| ---------------- | --- | --- | -------------- |
| README.md        | 12  | 52  | 81%            |
| CHANGELOG.md     | 2   | 62  | **97%**        |
| ci-workflow.yaml | ~58 | 6   | 9%（注册模块） |

**CHANGELOG.md 仅 2 个模块有**（binance, contracts），这意味着 62 个模块的变更历史只能通过 `git log` 追溯，无法快速了解模块演进。

**README.md 缺失集中在**：全部基座层核心模块（kernel, configx, observex, resiliencx, schedulex, bootstrap, testkitx, redisx, kafkax, postgresx, taosx, ossx, clickhousex, transportx, alertx, x.go）、全部 L2.5 模块、大部分 proposed 业务模块。

**影响**：新贡献者进入任何模块目录都缺少入口说明。CHANGELOG 缺失导致版本演进不可追溯。

---

### S11. 双管线认知负担（HIGH）

**现象**：仓库同时维护两套交付管线，阶段映射关系复杂。

**双管线对照**：

| 维度     | 管线 A：Spec→Code                       | 管线 B：Goal→Retro               |
| -------- | --------------------------------------- | -------------------------------- |
| 入口     | Spec 编写                               | Goal 定义                        |
| 阶段数   | 6（S1-S6）                              | 11（G0-G11）                     |
| 产物     | SPEC.md → Code                          | Goal → Spec → Design → … → Retro |
| 门禁     | 四源评分 ≥98                            | G0-G11 Gate                      |
| SSOT     | docs/governance/DEVELOPMENT-WORKFLOW.md | docs/goal/03-pipeline.md         |
| 状态目录 | .omc/state/pipeline/                    | .config/goal/pipeline/           |

**映射关系**（docs/workflow/README.md）：

> 管线 A 是管线 B 的子集。S1-S6 ≈ G2-G8。

**Agent 路由矩阵**（AGENTS.md 中的路由表）：

| 职能       | Goal agent          | Governance agent                        | 路由规则                                                           |
| ---------- | ------------------- | --------------------------------------- | ------------------------------------------------------------------ |
| Spec 编写  | goal-spec           | spec, spec-author                       | 模块 spec 用 goal-spec；跨模块用 spec-author                       |
| Spec 审查  | goal-reviewer       | spec-review, spec-structural-score      | Goal Gate 用 goal-reviewer；四源评分用 \*-structural-score         |
| Plan/Tasks | goal-planner        | task-planner, task-split                | 模块计划用 goal-planner；governance 用 task-planner                |
| Matrix     | goal-matrix         | matrix, matrix-structural-score         | 模块追溯用 goal-matrix；评分用 matrix-structural-score             |
| Prompt     | goal-prompt-builder | prompt-builder, prompt-structural-score | 模块 prompt 用 goal-prompt-builder；评分用 prompt-structural-score |
| Code       | —                   | task-executor, code-structural-score    | 统一用 task-executor                                               |
| Evidence   | goal-evidence       | —                                       | 统一用 goal-evidence                                               |
| Governance | goal-governance     | pipeline-arbiter, meta-arbiter          | 一致性审计用 goal-governance；评分仲裁用 arbiter                   |

**核心问题**：一个新模块从零开始到代码交付，需要理解：

1. 两条管线的区别和适用场景
2. 11 个 Gate 的通过条件
3. 8 个 Goal agent 和 8 个 Governance agent 的路由规则
4. 四源评分体系（Claude / Codex / Copilot / rules）
5. composite_score = min(...) 仲裁算法
6. 何时用 goal-\* agent，何时用 governance agent

**证据**：docs/goal/00-authority-map.md 第 18 行试图裁决双管线优先级：

> 当 Goal Gate（G2/G5/G6/G9）与 governance 四源评分（composite_score）同时适用时，Goal Gate 为权威裁决，四源评分作为该 Gate 的 score 实现机制

这种"用一篇 99 行文档来裁决两套系统优先级"的做法本身就是认知负担的证明。

**影响**：管线选择本身成为前置决策成本。Agent 路由规则复杂度可能导致 AI 代理选择错误的 agent。

---

## 3. 结构性问题关联图

```text
                    ┌─────────────────────────────────┐
                    │         S1: SSOT 增殖            │
                    │  (3+ SSOT × 大量投影文档)        │
                    └──────┬──────────┬──────────┬─────┘
                           │          │          │
                    ┌──────▼──┐  ┌────▼────┐  ┌──▼──────────┐
                    │ S2: 迁移 │  │ S4: 计数 │  │ S11: 双管线  │
                    │ 半完成   │  │ 口径不一 │  │ 认知负担    │
                    └──────┬──┘  └────┬────┘  └──┬──────────┘
                           │          │          │
                    ┌──────▼──────────▼──────────▼─────────┐
                    │         S3: 治理文档膨胀              │
                    │  (200 .md, 14 AGENTS.md, 双管线17阶段) │
                    └──────┬────────────────────┬──────────┘
                           │                    │
              ┌────────────▼──┐          ┌──────▼──────────┐
              │ S7: 根目录膨胀 │          │ S8: 多平台配置   │
              │ (45条目)       │          │ 膨胀与漂移       │
              └───────────────┘          └─────────────────┘
                           │
              ┌────────────▼──┐  ┌──────────┐  ┌──────────┐
              │ S5: 依赖矩阵   │  │ S6: 命名  │  │ S9: 未注册│
              │ 数据质量       │  │ 不统一    │  │ 目录残留  │
              └───────────────┘  └──────────┘  └──────────┘
                                         │
                                ┌────────▼────────┐
                                │ S10: 模块文档    │
                                │ 大面积缺失       │
                                └─────────────────┘
```

**核心恶性循环**：S1（SSOT 增殖）→ 需要更多文档来描述 SSOT 关系 → S3（文档膨胀）→ 文档间出现不一致 → 需要更多权威映射来裁决 → S1 加剧。

---

## 4. 根因分析

### 4.1 根因 1：治理先于执行

仓库在 2026-06-01 到 2026-06-29 之间（约一个月）建立了完整的治理体系——20 条宪法、27 篇 Goal 方法论、三平台 21-agent 配置、四源评分体系。但模块迁移（S2）、文档完整性（S10）、依赖执行（S5）等执行层工作严重滞后。

**证据**：registry.yaml 中 27 个模块的 `registered` 日期为 2026-06-10，lifecycle 全部为 `proposed`。仅 binance 完成了嵌套迁移。`[KNOWN]`

### 4.2 根因 2：SSOT 理论与实践的 gap

SSOT 原则要求"单一权威源"，但仓库中同一个事实（如模块版本号）需要出现在 6+ 位置（SSOT + 投影）。投影同步是手工操作，而仓库有 55 个活跃模块 × 6+ 投影位置 = 330+ 个同步点。这不是人力可维护的。

### 4.3 根因 3：双管线并行而非收敛

Goal→Retro 管线和 Spec→Code 管线在设计上是"管线 A 是管线 B 的子集"的关系，但实际运行中两套管线各有独立的 SSOT、独立的 agent、独立的状态目录、独立的 Gate 体系。收敛点（docs/workflow/README.md）只是一个映射表，不是真正的统一。

### 4.4 根因 4：多平台镜像的维护成本

三平台 21-agent 镜像需要 63 个配置文件（21 canonical + 42 副本）。sync-agents.py 只检测 name 级漂移，内容级同步全靠手动。.codex 的 21 个文件是完整副本而非声称的"thin wrapper"，这意味着任何 agent 指令变更需要手动同步到 3 个平台。

---

## 5. 改进建议（优先级排序）

### P0：止血（立即执行）

| #    | 建议                                                                             | 解决问题 | 状态      | 完成日期   |
| ---- | -------------------------------------------------------------------------------- | -------- | --------- | ---------- |
| P0.1 | 清理 FOUNDATION-DEPS.yaml 中 forbidden_deps 的重复条目（riskx/orderx/positionx） | S5       | ✅ 已完成 | 2026-07-03 |
| P0.2 | 清理 .omc/ 下 29 个残留临时文件                                                  | S8       | ✅ 已完成 | 2026-07-03 |
| P0.3 | 在 registry.yaml 中登记或归档 9 个未注册目录                                     | S9       | ✅ 已完成 | 2026-07-03 |
| P0.4 | 统一 STATUS.md 中的计数口径，每处标注口径来源                                    | S4       | ✅ 已完成 | 2026-07-03 |

#### P0 修复执行记录（2026-07-03）

**P0.1 — forbidden_deps 重复条目清理**

- 文件：`module/FOUNDATION-DEPS.yaml`
- 变更：删除行 238-240 的重复 riskx/orderx/positionx 条目
- 验证：`grep -c` 确认每个模块在 forbidden_deps 中仅出现一次

**P0.2 — .omc/ 残留临时文件清理**

- 路径：`.omc/` 下 31 个 `.tmp.*` 文件（原估 29 个）
- 变更：全部删除
- 验证：`find .omc -name "*.tmp.*" -type f` 返回 0 结果

**P0.3 — 未注册目录登记**

- 文件：`module/registry.yaml`、`module/README.md`
- 变更：
  - 登记 `frontend`（domain=entry, layer=presentation, lifecycle=production）
  - 登记 `assembly`/`binancecfg`/`binancex`/`cmd`（domain=data, lifecycle=proposed, runtime-patches 子模块）
  - 标注 `data_cs_module`/`data_independent_process`/`_exchange-template`/`_template` 为非模块模板目录
- 验证：registry.yaml 覆盖全部 64 个 module/ 子目录

**P0.4 — STATUS.md 计数口径标注**

- 文件：`STATUS.md`
- 变更：
  - 添加全局口径说明块（5 种口径：DEPS20/STATUS21/REG59/REG55/FULL73）
  - 7 处计数标注口径来源
  - 修正"20-module projection"为"21-module projection"（.foundationx/status 实际覆盖 21 模块）

**同步对齐文档更新**：

- `module/FOUNDATION-DEPS.yaml`：updated 日期 → 2026-07-03
- `module/registry.yaml`：updated 日期 → 2026-07-03
- `module/README.md`：新增 binance runtime-patches 子模块索引

### P1：减负（1-2 周内）

| #    | 建议                                                                              | 解决问题 | 状态      | 完成日期   |
| ---- | --------------------------------------------------------------------------------- | -------- | --------- | ---------- |
| P1.1 | 完成 ARCHITECTURE.md 和 STATUS.md 的存根化迁移（内容移入 docs/ 或 .foundationx/） | S2       | ✅ 已完成 | 2026-07-03 |
| P1.2 | 为全部基座层模块补齐 README.md                                                    | S10      | ✅ 已完成 | 2026-07-03 |
| P1.3 | 将 .codex/agents/ 改为真正的 thin wrapper（引用 .claude canonical 定义）          | S8       | ✅ 已完成 | 2026-07-03 |
| P1.4 | 创建 .copilot/state/pipeline/ 目录或从文档中移除该声明                            | S8       | ✅ 已完成 | 2026-07-03 |
| P1.5 | 统一 L2.5 模块在 FOUNDATION-DEPS.yaml 中的登记                                    | S4, S5   | ✅ 已完成 | 2026-07-03 |

#### P1 修复执行记录（2026-07-03）

**P1.1 — ARCHITECTURE.md 和 STATUS.md 存根化迁移**

- ARCHITECTURE.md：607 行 → 38 行薄存根（内容已在 docs/architecture/ 01-08 中）
- STATUS.md：509 行 → 237 行（移除 ~300 行手工投影表，保留分析内容；添加 JSON 指针）
- 净减少：~840 行手工维护投影内容

**P1.2 — 基座层模块 README.md 补齐**

- 新建 18 个 README.md：kernel, configx, observex, resiliencx, schedulex, bootstrap, testkitx, redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex, transportx, xlib_harness, xlib_evidence, xlibgate
- 基座层 README.md 覆盖率：从 15% 提升至 95%（仅 xlib_standard 已有，未重建）

**P1.3 — .codex/agents/ thin wrapper 转换**

- 21 个 .toml 文件从完整定义转为 thin wrapper（引用 .claude canonical 定义）
- 保留 per-agent reasoning effort（goal-prompt-builder=medium，其余=high）
- sync-agents.py 漂移检测验证通过（has_drift: false）

**P1.4 — .copilot/state/pipeline/ 目录创建**

- 创建 .copilot/state/pipeline/.gitkeep
- AGENTS.md 声明的三平台状态隔离现在全部有效

**P1.5 — L2.5 模块 FOUNDATION-DEPS.yaml 统一登记**

- 新增 domain_market, domain_macro, domain_exchange 到 modules 段
- 新增 allowed_deps：domain_market→[decimalx, domainx], domain_macro→[decimalx, domainx], domain_exchange→[decimalx, domainx, domain_market]
- 新增 forbidden_foundation_edges：3 个 L2.5 模块禁止依赖基础设施和业务域
- 移除 registry.yaml 中 4 个 "L2.5 补登记待完成" 注释
- 更新 L2.5 段落头部说明

**同步对齐文档更新**：

- AGENTS.md：更新 .codex thin wrapper 描述
- module/registry.yaml：更新 L2.5 段落说明、updated 日期
- module/FOUNDATION-DEPS.yaml：updated 日期

### P2：结构性优化（1-2 月内）

| #    | 建议                                                                                | 解决问题 | 工作量 | 状态 |
| ---- | ----------------------------------------------------------------------------------- | -------- | ------ | ---- |
| P2.1 | 将双管线收敛为单管线（Goal→Retro 为唯一管线，Spec→Code 作为快速通道子集）           | S11      | 1 周   | ✅ 完成 2026-07-03 |
| P2.2 | 用自动化脚本替代 STATUS.md 手工投影块（从 .foundationx/status/index.json 自动生成） | S1       | 3 天   | ✅ 完成 2026-07-03 |
| P2.3 | 合并 docs/governance/ 和 docs/goal/ 中重叠的文档（管线定义、模板、DoR/DoD）         | S3       | 1 周   | ✅ 完成 2026-07-03 |
| P2.4 | 将 xlib 系列 4 模块的迁移中间态收尾（清理根目录平铺残留）                           | S2       | 1 天   | ✅ 完成 2026-07-03 |
| P2.5 | 为 sync-agents.py 增加内容级漂移检测（hash 对比）                                   | S8       | 2 天   | ✅ 完成 2026-07-03 |

#### P2 完成记录

**P2.1 双管线收敛**（2026-07-03）：
- `docs/workflow/README.md` 重写：双管线→统一管线，Goal→Retro（G0-G11）为唯一管线，Spec→Code（S1-S6）为 G2-G6 快速通道子集
- `AGENTS.md` line 3/209：更新"双管线"→"统一管线"引用
- `docs/governance/DEVELOPMENT-WORKFLOW.md` line 92/798：管线投影声明更新
- `docs/goal/00-authority-map.md` line 26："双管线优先级"→"管线优先级"
- 修正 agent 计数错误（Claude 28→21, Codex 20→21, Copilot 19→21）

**P2.2 自动投影脚本**（2026-07-03）：
- 新建 `scripts/generate-status-projection.py`：从 `.foundationx/status/index.json` 生成 STATUS.md 投影表
- 支持 `--summary`（汇总表）、`--detail`（明细表）、`--json` 输出
- STATUS.md 添加 `<!-- BEGIN AUTO-PROJECTION -->` 标记，可自动替换

**P2.3 治理文档投影声明**（2026-07-03）：
- 7 个 governance 文档添加投影声明，明确 canonical SSOT 引用：
  - `LIFECYCLE.md` → `05-layer-standards.md §1`（状态集冲突已标注，对齐计划留 P3）
  - `TRACEABILITY.md` → `05-layer-standards.md §9`（row model 标注为展示视图）
  - `DEFINITION-OF-READY.md` → `06-dod.md §2`
  - `DEFINITION-OF-DONE.md` → `06-dod.md §8`
  - `PRE-DEVELOPMENT.md` → `06-dod.md`（实操步骤保留）
  - `SPEC-TEMPLATE.md` → `09-templates.md` + `05-layer-standards.md §1`（ID 格式分歧已标注）
  - `TASK-TEMPLATE.md` → `09-templates.md §5` + `05-layer-standards.md §4`
- `docs/governance/README.md` 索引表新增 SSOT 引用列，标注 `[投影]` 文档

**P2.4 xlib 迁移收尾**（2026-07-03）：
- 删除 4 模块 19 个平铺残留文件（xlib_standard 5, xlib_harness 4, xlib_evidence 4, xlibgate 5+1 TRACEABILITY）

**P2.5 内容级漂移检测**（2026-07-03）：
- `scripts/sync-agents.py` 新增 `--content-check` 功能
- 计算 .claude canonical agent SHA256 hash
- 验证 .codex thin wrapper 引用正确性（<30 行 + reference pattern）
- .copilot full definitions 不要求 thin wrapper（预期行为）
- 验证结果：21/21 agents 通过

### P3：长期治理（持续）

| #    | 建议                                                                 | 解决问题 | 工作量 |
| ---- | -------------------------------------------------------------------- | -------- | ------ |
| P3.1 | 逐步完成剩余 56 个模块的嵌套结构迁移                                 | S2       | 持续   |
| P3.2 | 实现 xlibgate Phase F（业务域依赖机器执行）                          | S5       | 2 周   |
| P3.3 | 统一 GitHub 仓库名为 snake_case（xlib-standard → xlib_standard）     | S6       | 协调   |
| P3.4 | 减少根目录隐藏目录数量（合并 .omc/.omx，移除 .brooks/.pytest_cache） | S7       | 1 周   |
| P3.5 | 为全部模块补齐 CHANGELOG.md                                          | S10      | 持续   |

---

## 6. 与既有报告的关系

本报告聚焦**仓库级模块结构**，与既有报告形成互补：

| 既有报告                                   | 聚焦点                 | 本报告互补点                 |
| ------------------------------------------ | ---------------------- | ---------------------------- |
| structural-deep-analysis-20260625.md       | binance 代码级结构问题 | 本报告覆盖仓库级结构         |
| comprehensive-structural-audit-20260625.md | 仓库整体快照审计       | 本报告深入模块组织和治理体系 |
| module-boundary-definitions-20260625.md    | 模块边界定义           | 本报告关注边界定义的组织方式 |
| dependency-graph-20260625.md               | 依赖图分析             | 本报告关注依赖矩阵的数据质量 |

---

## 7. 认证与局限性

**置信度声明**：

- S1-S4, S7, S9-S11：`[COMPUTED, HIGH]` — 基于直接文件系统观测
- S5：`[COMPUTED, HIGH]` — grep 验证重复条目
- S6：`[COMPUTED, HIGH]` — registry.yaml 字段逐一比对
- S8：`[COMPUTED, HIGH]` — explore agent 直接验证

**局限性**：

1. 本报告不涉及代码实现质量（由既有报告覆盖）
2. 本报告不涉及 CI/CD 管道执行情况
3. 运行态膨胀数据（704 session）基于目录计数，未检查内容有效性
4. 改进建议的工作量估算是粗略估计 `[GUESS, LOW]`

---

_报告生成：2026-07-03 · 基于仓库 HEAD 快照 · 所有数据可复现_
