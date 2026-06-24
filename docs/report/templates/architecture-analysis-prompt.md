# 架构深度分析提示词模板（文档枢纽定制版）

> 模板用途：生成 `docs/report/architecture-structural-analysis-{YYYYMMDD}-v{N}.md` 类报告。
> 适用仓库：ZoneCNH 文档枢纽（非代码仓；目标系统源码在独立 GitHub 仓库）。
> 定制依据：`AGENTS.md` 专家沟通规则、`docs/constitution/20-epistemic-standards.md`、
> `docs/report/INDEX.md` 命名约定、历史报告评分基线。
>
> **使用方式**：复制下方「提示词正文」整段投给 AI，按需替换 `{占位符}`。占位符说明见文末。

---

## 提示词正文

```markdown
# 任务：仓库架构深度分析（文档枢纽定制版）

## 角色
你是 ZoneCNH 文档枢纽仓库的资深架构审计员。本仓库不是代码仓——它是 65 个模块
的规格/治理文档中心，目标系统源码在独立 GitHub 仓库。你必须始终区分"文档描述的
目标架构"与"目标系统的实际实现"，这是本仓库最高认识论风险（[FRAME]→REALITY）。

## 认识论前置（强制，违反即红线）
- 每个事实性声明必须附证据标签：[KNOWN] 仓库已记录 / [COMPUTED] 本会话实测 /
  [INFERRED] 推断 / [FRAME] 治理状态投影 / [GUESS] 无依据猜测。
- 置信度必须显式写出：HIGH ≥80% / MED 50-80% / LOW 20-50% / VERY LOW <20% / UNKNOWN。
- [FRAME] 外推和 [GUESS] 的置信度上限为 LOW。
- 管线评分 100 ≠ 代码正确或生产稳定，必须反复声明此风险。

## 分析步骤（按序执行）
1. **事实基线校准**：读 `CONSTITUTION.md`、`docs/constitution/20-epistemic-standards.md`、
   `AGENTS.md` 治理条款、`module/FOUNDATION-DEPS.yaml`、
   `.foundationx/status/index.json`、`STATUS.md`；跑 `scripts/audit-status.py`
   （如存在）取实测数据。
2. **文档架构分析**：`README` ↔ `ARCHITECTURE` ↔ `docs/architecture/*` ↔
   `module/*/SPEC.md` 的一致性；分层（kernel→primitives→storage→domain→business→
   composer）是否自洽；依赖方向是否只向下；owner 声明（owned/not-owned）是否完整。
3. **规格可追溯性**：抽样 {SAMPLE_N} 个 module，校验 SPEC→TRACEABILITY→goal.md
   链条；统计 AC 覆盖率、TC 覆盖率、evidence 完整度（历史报告的长期低位项）。
4. **治理框架成熟度**：CI workflow + 本仓 hook + 4 套评分源（claude/codex/copilot/
   rules）+ xlibgate 门禁是否实际运行；`FOUNDATION-DEPS` 是否被硬门禁引用。
5. **跨文档一致性**：`STATUS.md` / `ARCHITECTURE.md` / `README` 的状态字段、版本号、
   release tag 是否同步；区分"事实字段"（release/CI/覆盖率，只来自权威仓库）与
   "投影字段"（阶段/factory 版本/治理状态）。
6. **历史报告复核**：对比 `docs/report/` 下最近 {HISTORY_N} 份同类报告，标注本次
   新增/缓解/恶化项，不得重复已归档结论。

## 评分维度（文档枢纽版，非代码仓版）
| 维度 | 权重 | 评分锚点 |
|------|:----:|----------|
| A · 架构完整性（文档分层/依赖方向/owner） | 20% | 历史基线 78，看命名统一与分层是否进步 |
| B · 规格质量（AC/TC/evidence 覆盖率） | 20% | 历史长期 58，重点看是否突破 60 |
| C · 管线覆盖（tasks/plan/prompt 完成度） | 20% | 历史长期 44，是最弱项 |
| D · 治理成熟度（CI/hook/评分源/门禁） | 15% | 历史高位 88 |
| E · 文档一致性（跨文档口径同步） | 15% | 历史高位 82 |
| F · 交付健康度（基座 factory-ready/blocker） | 10% | 历史高位 84 |

等级：S≥90 卓越 / A≥80 良好 / B≥70 合格 / C≥60 需改进 / D<60 危险。
加权综合分必须可独立复算（贡献 = 得分 × 权重，综合 = Σ 贡献）。

## 输出要求
- **文件**：`docs/report/architecture-structural-analysis-{YYYYMMDD}-v{N}.md`
  （先查 `docs/report/INDEX.md` 确定本次是 v 几；不放进 `docs/report/arch/` 子目录，
  那是单模块报告位）。
- **首部必须含**：生成时间、release 基线、分支合规声明（从 main HEAD 派生）、
  分析范围（module 数/SPEC 数/CI 数/commit 窗口）、证据标签图例、
  Supersedes/并存关系（标注替代了哪份历史报告）。
- **结构**：
  0. 认识论前置声明（FRAME→REALITY 风险提示）
  1. 综合评分卡（加权表 + 等级 + 一句话判断）
  2. 架构问题分析（设计优势 ✅ + 问题 🔴）
  3. 关键问题清单（P0/P1/P2 排序，每条含：位置/现状/风险/修复方案）
  4. 与历史报告的 delta（新增/缓解/恶化）
  5. 优化路线图（短期/中期/长期）
- **每个问题四要素**：文件路径 + 现状（带证据标签）+ 风险 + 可执行修复方案。
- **完成后**：更新 `docs/report/INDEX.md` 权威报告表 + 变更历史。

## 约束（红线）
- 基于实际仓库内容，禁止臆测；无证据的判断标 [GUESS] 并降置信度。
- 问题必须可定位（文件路径/章节/字段），建议必须可执行（给具体 grep/diff/编辑动作）。
- 不得在 main 分支直接编辑；从 main HEAD 派生 feature branch。
- 回复末尾附 `[RULES I BROKE]：...`，无违反写 `无`。

## 本次分析参数
- 分析窗口：{WINDOW}（如"近 7 天"/"全量"/"v1.12.9 至今"）
- 抽样模块数：{SAMPLE_N}（建议 8-12）
- 对照历史报告数：{HISTORY_N}（建议 3）
- 重点关注：{FOCUS}（如"无"/"业务域三链路 AC 覆盖"/"binance 解耦"）
```

---

## 占位符说明

| 占位符 | 含义 | 示例值 | 默认值 |
|--------|------|--------|--------|
| `{SAMPLE_N}` | 步骤 3 抽样校验的模块数 | `10` | `10` |
| `{HISTORY_N}` | 步骤 6 对照的历史报告数 | `3` | `3` |
| `{WINDOW}` | 分析时间窗口 | `近 7 天` / `全量` / `v1.12.9 至今` | `全量` |
| `{FOCUS}` | 本次重点关注的主题 | `业务域三链路 AC 覆盖` / `binance 解耦` / `无` | `无` |

## 三种典型用法

### 1. 全量季度审计（默认）
直接用所有默认值，产出标准六维度加权报告。

### 2. 周度增量审计
```
{WINDOW} = 近 7 天
{SAMPLE_N} = 5
{FOCUS} = 本周新增债务
```
报告标题加 `-weekly` 后缀：`architecture-structural-analysis-{YYYYMMDD}-v{N}-weekly.md`，
避免与全量分析混淆。

### 3. 单模块深挖
切换到 `docs/report/arch/` 子目录格式（参考
`docs/report/arch/binance-module-decoupling-architecture-20260624.md`）：
owner 表 + 依赖图 + 治理证据基线表，而非全仓六维度评分。
此时 `{FOCUS}` = 模块名（如 `binance`），`{WINDOW}` = 该模块近期变更窗口。

## 相对通用代码仓模板的差异

| 维度 | 通用代码仓模板 | 本模板（文档枢纽） |
|------|----------------|--------------------|
| 分析对象 | 源码（.go/.py/.ts） | 规格/治理文档（SPEC/TRACEABILITY/goal.md） |
| 评分维度 | 循环依赖/上帝类/重复代码 | 架构完整性/规格质量/管线覆盖/治理成熟度 |
| 证据规范 | 无 | 强制 `[KNOWN]/[COMPUTED]/...` + 置信度 |
| 打分制 | 1-10 主观 | 100 分加权六维度 + 历史基线锚点 |
| 输出路径 | `docs/report/arch/` | `docs/report/` 根（遵循 INDEX.md 约定） |
| 认识论警示 | 无 | FRAME→REALITY（管线分 ≠ 生产真相） |

## 维护

- 本模板的历史评分基线（A:78/B:58/C:44/D:88/E:82/F:84）来自
  `docs/report/architecture-structural-analysis-20260622-v2.md`（69.9 分），
  每次产出新报告后应回填本表的"历史基线"列以保持纵向可比。
- 模板自身的改进需作为治理制品走 `docs/governance/improvements/` 流程，
  遵守 `CONSTITUTION.md` 第十四条，不得直接在 main 编辑。
