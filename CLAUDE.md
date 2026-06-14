# Claude 工作指南

本文件说明 Claude Code 在本仓库中工作时应遵循的约束。

## 最高指令源

当本文件与 `CONSTITUTION.md` 冲突时，以 `CONSTITUTION.md` 为准。`CONSTITUTION.md` 是系统级最高治理文件，定义了模块实现（§1-§14）和交付管线（§15-§19）的技术标准。本文件仅规定仓库级操作约定（文档同步、提交格式、安全红线）。

## 本仓库定位

本仓库是 ZoneCNH 的 `FoundationX` 量化交易基础设施文档枢纽，也是 `ZoneCNH/ZoneCNH` GitHub 个人主页仓库，其中 `README.md` 会渲染到个人主页。

本仓库不包含应用代码，核心内容是 Markdown 文档：

- `README.md`：个人主页、技术栈、分层架构摘要和组件仓库索引。
- `ARCHITECTURE.md`：依赖拓扑、领域职责、设计原则和状态表的权威文档。
- `CONSTITUTION.md`：模块宪法 — §0-§19 治理条款（含分支纪律、十三条设计原则、交付管线、CRI），AI 代理和人类贡献者的最高权威参考。
- `AGENTS.md` / `CLAUDE.md`：面向自动化代理和贡献者的工作指南。
- `docs/goal/`：Goal 驱动交付体系规范，权威入口见 `docs/goal/00-quickstart.md`。

实际实现位于 `github.com/ZoneCNH` 下约 70 个独立仓库，例如 `kernel`、`binance`、`factor-engine`、`risk-engine`、`x.go`。本仓库只描述和链接这些模块，不承载它们的源码。

这里没有构建、lint 或测试步骤；主要工作是编辑 Markdown。

## 保持文档同步

`README.md` 和 `ARCHITECTURE.md` 从不同角度描述同一套系统，因此一个文件的架构变化通常需要同步到另一个文件：

- 新增或移除组件时，同时更新 `README.md` 的目录表，以及 `ARCHITECTURE.md` 的状态表和依赖图。
- 修改组件所属领域或分组时，同步更新两个文件中的 ASCII 依赖图，以及“各域说明”“数据域子模块明细”等相关章节。
- 图中的组件数量，例如 `market-data (19)`、`macro-data (10)`，必须与实际列出的表格行数一致。

`ARCHITECTURE.md` 的状态表是组件版本、状态和进度的事实来源。组件状态变化时，应优先更新该表。

## 模块-仓库强制对应（2026-06-14 审计复盘）

> 审计发现 xlib-harness、xlib-evidence、domainx 三个模块在文档中链接了不存在的 GitHub 仓库（404）。
> 此规则为预防性门禁。

- **每个在 STATUS.md 和 ARCHITECTURE.md 状态表中列出 GitHub 链接的模块，必须有对应的公开仓库。**
- 新增模块时，必须同时创建对应 GitHub 仓库（至少含 README.md + 模块说明）。
- 文档中的 GitHub 链接（`https://github.com/ZoneCNH/<module>`）禁止指向 404。
- CI 检查 `repo-existence-check.sh` 会扫描状态表中的所有链接，验证 HTTP 200。
- 已知例外：`contracts` / `transportx` / `xlib-harness` / `xlib-evidence` 共享 `xlib-standard` 的 Go module（`module github.com/ZoneCNH/xlib-standard`），但它们各自拥有独立仓库，只是代码物理上位于 xlib-standard monorepo。

## 当前架构模型

系统采用分层领域模型，而不是编号层级。依赖按数据流方向向下，同一领域内模块平级协作：

```text
基座 → 数据域 → 分析域 ⇄ 决策域 → 执行域 → x.go
```text

- **基座**：生命周期、依赖注入、配置、可观测、存储和契约，包括 `kernel`、`configx`、`observex`、`contracts`、`redisx`、`kafkax` 等；同时包含 L2.5 领域共享层 `decimalx`、`domain-market`、`domain-exchange`、`domain-macro`。
- **数据域**：market-data、macro-data、alternative-data 采集器，按交易所或数据源拆分。
- **分析域 ⇄ 决策域**：唯一双向关系；因子驱动信号生成，回测结果反馈到因子评估。
- **横切**：`alertx` 和 `observex` 贯穿所有领域。

编辑时必须保留 `ARCHITECTURE.md` 中九条核心设计原则的意图：策略只能通过 `risk-engine` 提交订单；回测与实盘共享因子、信号和风控代码；`contracts` 定义跨域接口；数据不跨域；`order-engine` 抽象交易所差异；`x.go` 只做编排；域内模块平级协作；反馈通过事件表达；领域语义沉到 L2.5。

## 分支纪律（最高优先级）

> 详见 `CONSTITUTION.md` 第零条。本条优先级高于以下所有条款。

- **禁止**在 `main` 分支上直接编辑文件或提交变更。
- **所有分支必须从 `main` HEAD 创建**。创建前必须先 `git fetch origin && git rebase origin/main` 确保本地 main 为最新。禁止从其他 feature branch 或旧 commit 拉取新分支。
- 所有开发工作必须通过 `git worktree` 或 feature branch 进行。
- 工作完成后通过 PR 或 merge 合入 main，随后清理 worktree。
- 仅 `git merge`/`git rebase`/`git pull` 和紧急 hotfix 允许在 main 上执行。

## 工作流效率规则（2026-06-12 会话复盘）

> 基于 14 PR / 46 提交 / $89 成本的会话复盘，制定以下规则减少浪费。

### Plan-first 原则

- **分析阶段读完所有相关文件后再编辑**——禁止边读边改
- **列出完整变更清单后再动手**——同一文件所有修改一次性完成
- **同模块相关变更聚合为一个 PR**——禁止每个小修改单独 PR

### 编辑策略

- **同一文件只编辑一次**：列出该文件所有需要变更的行，一次性完成
- **优先 `Write` 替代多次 `Edit`**：当文件变更 > 30% 时，直接重写
- **批量 sed/python 替代多次 Edit 调用**

### PR 聚合规则

- **同一模块的所有文档修复 → 1 个 PR**
- **跨文档同步 → 1 个 PR**（STATUS + ARCHITECTURE + 对齐文档同步）
- **禁止 1 行变更的 PR**（如单个错字或单行更新）

### 成本控制

- 限制 `sequential-thinking`：仅在需要多假设推理时使用，常规分析直接输出
- 批量并行读取：`for f in a b c; do read $f & done`
- 会话中期检查成本：超过 $30 时主动与用户确认是否继续

## 模块工作流规则（自动分支 + 对齐同步 + PR 闭环）

> 处理 `module/{模块名}/` 下任何文件时，自动执行端到端工作流闭环。
> 本条规则将现有的"分支纪律""文档同步""PR 聚合"三条独立规则合并为一条可执行管线。

### 1. 自动分支创建

**触发条件**：需要编辑 `module/{module-name}/` 下的任何文件时。

**操作**：

1. `git fetch origin && git branch -f main origin/main` — 确保本地 main 指针最新
2. 从 `main` HEAD 创建分支，命名规则：
   - `docs/{module-name}-{描述}` — 文档/规格/linter 变更（最常用）
   - `feat/{module-name}-{描述}` — 功能/新模块
   - `fix/{module-name}-{描述}` — 修复
3. 如已存在同名分支且未合并，直接切换到该分支继续工作

**示例**：

```text
编辑 module/kernel/SPEC.md      → docs/kernel-spec-update
编辑 module/redisx/tasks/       → docs/redisx-tasks-add
编辑 module/xlib-standard/      → docs/xlib-standard-ac-fix
```

**检查点**：创建分支后验证 `git merge-base --is-ancestor main HEAD` 返回 0。

### 2. 编辑纪律

- **列出该模块所有需要变更的文件清单后再动手** — 禁止边读边改
- **同一文件只编辑一次** — 所有修改一次性完成
- **同模块文档修复 → 1 个 commit → 1 个 PR** — 不拆碎

### 3. 自动对齐文档同步（commit 前必检）

**强制检查清单**。模块文档变更完成后，逐项检查以下对齐文档是否需要同步更新：

| 对齐文档                       | 何时需要更新                         |
| ------------------------------ | ------------------------------------ |
| `ARCHITECTURE.md`              | 模块状态、依赖关系、设计原则描述变更 |
| `module/README.md`             | 模块列表、层级归属、职责描述变更     |
| `module/FOUNDATION-TRACKER.md` | Issue/PR 进度状态变更                |
| `README.md`                    | 组件数量、架构图、索引链接变更       |
| `STATUS.md`                    | 模块版本/状态变更                    |

**检查命令**：

```bash
# 快速扫描本次变更是否涉及关键字段
git diff HEAD -- module/ | grep -E '(Status|依赖|依赖图|状态|count|数量|Responsible|Core)' || echo "无需对齐"
```

**操作**：如上述任何文档需要更新，在同一分支上同步修改，作为同一 PR 的一部分提交。

### 4. 自动 PR 创建 + 合并 + 清理

**触发条件**：commit 完成且对齐文档检查通过后。

**完整管线**：

```bash
# 1. 推送分支
git push -u origin HEAD

# 2. 创建 PR（使用 gh CLI）
gh pr create \
  --title "docs: {变更摘要}" \
  --body "[模块: {module-name}]

{详细说明}" \
  --base main

# 3. 等待 CI 通过后合并（squash merge）
gh pr merge --squash --delete-branch

# 4. 切回 main 并同步
git checkout main && git pull origin main
```

**PR 标题格式**：遵循 Conventional Commits，格式为 `<type>: <描述>`（不含模块名）。模块名放在 PR body 首行：`[模块: {module-name}]`。

**PR 标题长度**：不超过 50 字符。如果加上 `(#NNN)` 后超过 50 字符，缩短描述部分，不要省略前置标识词（如"新增""修复""移除"）。

**合并策略**：squash merge，PR 标题作为 squash commit 的提交信息。

**清理**：merge 时自动删除远程分支；确认合并后删除本地分支 `git branch -d <branch-name>`。

### 5. 完整会话示例

```text
用户：修改 module/kernel/SPEC.md，更新 FR-003 的描述

Claude 执行：
1. git fetch origin && git branch -f main origin/main
2. git checkout -b docs/kernel-fr003-update
3. 修改 module/kernel/SPEC.md
4. 检查对齐文档：ARCHITECTURE.md（无变更）、module/README.md（无变更）、README.md（无变更）
5. git add + git commit
6. git push -u origin HEAD
7. gh pr create --title "docs: FR-003 描述更新" --body "[模块: kernel]

更新 SPEC.md 中 FR-003 的...
8. gh pr merge --squash --delete-branch
9. git checkout main && git pull origin main
10. 报告：PR #N created → merged → branch deleted ✓
```

## 评分纪律（2026-06-12 xlibgate matrix 复盘）

> 基于一次从 90+红线到 100 的 10 轮自我纠错会话提取。
> 详细规则见 `~/.claude/rules/ecc/matrix-scoring-rules.md`。
> 受保护 agent 文件的正式修改走 `docs/governance/improvements/20260612-matrix-scoring-methodology/SPEC.md`（RSI 流程）。

### 评分前置步骤

任何结构评分 agent（matrix/tasks/plan/prompt/code）在进入维度打分前，必须完成：

1. **措辞强度分级**：逐条读 rubric 和对应 spec 原文，标注硬/软/开三级。只对含"必须/不得/禁止/触发"的【硬】约束扣分。"优先/推荐/建议"等【软】约束不满足不扣分。"等/可/允许"等【开】约束只验证存在性。

2. **全链路跨表走查**：验证链不限于单个表。矩阵评分必须遍历 §1-§5 全部表的验证列，不只查反向追溯表。路径存在即闭合，不论穿过哪个表。

3. **辅助元数据排除**：覆盖率仪表盘、变更历史等辅助摘要不参与评分。只评追溯结构（FR/BR/NFR→AC/TC/Task 的闭链）。

### 评分前检查管道交汇

评分前运行 `git log --oneline --since="1 hour ago" -- module/{module}/`。如果最近 1 小时内有其他管道的修复提交已合入 main：确认评分的是最新版本；已修复的问题不重复扣分；如果修复解决了本会扣分的问题，在报告中注明"已被 #XX 管道修复"。

### 评分成本自觉

单模块单阶段评分超过 5 轮仍未收敛时，暂停自我纠错。先把当前结论和争议点写入报告，让 arbiter 做多源裁决——不要一个 scorer 在内部模拟多源收敛。

## 约定

- **语言**：Claude 的所有回复、文档和提交信息默认使用中文，英文保留给仓库名、模块名、命令和标准技术术语。
- **提交**：使用 Conventional Commits 前缀和中文描述，例如 `docs:`、`feat:`、`refactor:`、`fix:`。
- **链接**：引用组件时，使用既有表格风格的 `https://github.com/ZoneCNH/<repo>` 链接。
- **规格标准**：模块规格遵循 `CONSTITUTION.md` 第四条，采用 23 节结构（行为规格 WHEN/THEN、接口契约、业务规则、错误处理、边界场景、验收标准等）。模板见 `module/README.md`。追溯矩阵规范见 `docs/governance/TRACEABILITY.md`，具体矩阵位于 `module/{module}/TRACEABILITY.md`。
- **Goal 文档**：修改 `docs/goal/` 后需同步 `CHANGELOG.md`；涉及 schema 或状态变更时同步更新评分账本（`24-standard-unification-analysis.md`）和对应 YAML schema 文件。提交前运行 `lint-goal.sh && lint-goal.sh --spec`。
- **安全**：不要提交凭证、API key、账户 ID、私有端点或实盘交易配置。

# Harness 自动化（Harness Starter）

本项目已集成 Harness Starter 三层自动化体系（安全/感知/审查）。

## Hook 生命周期

每次对话中，以下 Hook 自动触发：

| Hook | 时机 | 职责 |
|------|------|------|
| **PreToolUse** | 工具执行前 | 安全拦截：`.env` 保护、危险命令阻止（`rm -rf`、`git push --force`） |
| **PostToolUse** | 编辑完成后 | 自动格式化（检测项目格式化工具，无匹配时静默跳过） |
| **PreCompact** | 上下文压缩前 | 保存会话关键状态 + Loop 进度 |
| **SessionStart** | 新对话开始 | 注入 git 状态 + Harness 状态 + 最近审查记录 |
| **Stop** | 每次响应后 | 审查变更范围、调试残留、依赖一致性，生成报告至 `.claude/reviews/` |

## 工作流模式与阶段

通过 `.claude/.harness-state` 控制审查严格度：

| 命令 | 效果 |
|------|------|
| `/harness-mode full` | 完整检查，所有规则生效（默认） |
| `/harness-mode hotfix` | 紧急修复，跳过行数/文件数检查 |
| `/harness-mode tweak` | 微调模式，仅 `.env` 保护 |
| `/harness-phase design` | 设计阶段，宽松审查，不检查调试残留 |
| `/harness-phase build` | 构建阶段，正常审查（默认） |
| `/harness-phase fix` | 修复阶段，>5 个文件变更即告警 |

查看当前状态：`/harness-status`

## GC Agent（可选）

定期扫描项目健康状态（8 个维度），手动触发：

```bash
node scripts/gc-scan.mjs          # 标准输出
node scripts/gc-scan.mjs --json   # JSON 输出
```

## 健康检查

```bash
node scripts/check.mjs            # 验证 Harness 配置完整性
```

## 成熟度路线图

| 级别 | 名称 | 指标 | 状态 |
|:---:|------|------|:---:|
| L0 | 裸用 | 无 CLAUDE.md | — |
| L1 | 规则层 | CLAUDE.md + 行为准则 | ✅ |
| L2 | 反馈回路 | PreToolUse + SessionStart + Stop 已激活 | ✅ |
| L3 | 自动修正 | PostToolUse + PreCompact 已激活 + 审查报告 ≥5 份 | 🔧 |
| L4 | 自治系统 | GC Agent 连续 3 次 0 critical | ⬜ |
