# Claude 工作指南

本文件说明 Claude Code 在本仓库中工作时应遵循的约束。

## 最高指令源

当本文件与 `CONSTITUTION.md` 冲突时，以 `CONSTITUTION.md` 为准。`CONSTITUTION.md` 是系统级最高治理文件，定义了模块实现（§1-§14）、交付管线（§15-§19）和认识论标准（§20）的技术要求。本文件仅规定仓库级操作约定。

## 本仓库定位

ZoneCNH 的 `FoundationX` 量化交易基础设施文档枢纽，也是 `ZoneCNH/ZoneCNH` GitHub 个人主页仓库。核心内容是 Markdown 文档，不含应用代码：

- `README.md`：个人主页、技术栈、架构摘要和组件索引
- `ARCHITECTURE.md`：依赖拓扑、领域职责、设计原则和状态表（权威来源）
- `CONSTITUTION.md`：模块宪法 §0-§20（最高权威，向后兼容存根；章节视图见 `docs/constitution/`）
- `AGENTS.md` / `CLAUDE.md`：自动化代理和贡献者工作指南
- `docs/goal/`：Goal 驱动交付体系规范

实际实现位于 `github.com/ZoneCNH` 下约 70 个独立仓库。本仓库只描述和链接模块，不承载源码。没有构建/lint/测试步骤。

## 文档同步

`README.md`、`ARCHITECTURE.md`、`STATUS.md` 从不同视角描述同一套系统，必须保持一致：

- **模块归属变更必须三文档同步**：更新所有 ASCII 架构图、各域说明表、组件明细表、按域统计表及包含该模块数量引用的所有行
- **版本号变更必须同步**更新 `ARCHITECTURE.md` 状态表和 `STATUS.md` 组件明细表。先确认 GitHub 实际 release 再改文档
- **组件增删必须同步**更新三文档的表格、域统计、仪表盘进度分布、域健康度描述、风险清单、同步检查表
- **`STATUS.md` 文档同步检查表**是交叉验证的快速入口，其自身计数也必须与实际一致
- 图中组件数量（如 `market_data (18)`）必须与实际表格行数一致。`ARCHITECTURE.md` 状态表是版本/状态/进度的事实来源

## 模块-仓库强制对应

- **每个列出 GitHub 链接的模块，必须有对应的公开仓库。** 新增模块时必须同时创建对应仓库。文档链接禁止指向 404
- **全量 404 扫描**：`grep -oPh 'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+' STATUS.md README.md ARCHITECTURE.md | sort -u | while read u; do repo=${u#ZoneCNH/}; gh api "repos/ZoneCNH/$repo" >/dev/null 2>&1 || echo "404: $repo"; done`
- CI 检查 `repo-existence-check.sh` 验证 HTTP 200
- 例外：`contracts` / `transportx` / `xlib_harness` / `xlib_evidence` 共享 `xlib_standard` Go module，但各自拥有独立仓库

## 当前架构模型

```text
基座 → 数据域 → 分析域 ⇄ 决策域 → 执行域 → x.go
```

- **基座**：`kernel`、`configx`、`observex`、`contracts`、`redisx`、`kafkax` 等 + L2.5 共享层 `decimalx`、`domain_market`、`domain_exchange`、`domain_macro`
- **数据域**：market_data、macro_data、alternative_data 采集器
- **分析域 ⇄ 决策域**：唯一双向关系；因子驱动信号生成，回测反馈因子评估
- **横切**：`alertx` 和 `observex` 贯穿所有领域

编辑时必须保留九条核心设计原则：策略只通过 `riskx` 提交订单；回测与实盘共享因子/信号/风控代码；`contracts` 定义跨域接口；数据不跨域；`orderx` 抽象交易所差异；`x.go` 只做编排；域内模块平级协作；反馈通过事件表达；领域语义沉到 L2.5。

## 分支纪律（最高优先级）

> 详见 `CONSTITUTION.md` 第零条。本条优先级高于以下所有条款。

- **禁止**在 `main` 分支上直接编辑或提交
- **所有分支必须从 `main` HEAD 创建**，创建前 `git fetch origin && git rebase origin/main`
- 所有开发通过 `git worktree` 或 feature branch 进行
- 工作完成后通过 PR 合入 main，随后清理 worktree 和 feature branch

### 分支保护（> 取代: 2026-06-14 分支纪律 §自动删除）

- **禁止自动删除未合并分支**。Stop/SessionEnd hook 切换 main 前必须验证：`git log origin/main..HEAD --oneline | wc -l`（>0 则禁止删除）或 PR 已合并
- **分支恢复**：误删时 `git reflog` 定位 SHA → `git checkout -b <branch> <sha>`

### 工作区 GC（> 取代: 2026-06-19 §空头 GC 文档）

- **`.worktree/` 孤儿目录 TTL = 24h**。SessionStart hook（`.claude/hooks/session-context.mjs`）扫描 `.worktree/` 下已被 `git worktree forget` 的孤儿目录（不在 `git worktree list` 中）
- **默认 dry-run**：仅报告 >24h 孤儿，不删除。设 `WORKTREE_GC_CLEAN=1` 才真删
- **真删护栏**：`WORKTREE_GC_CLEAN=1` 时跳过含 worktree 残骸（`.git` 文件）的孤儿目录，保护其工作区未提交改动（已 commit 的提交在分支 ref 上不丢，仅未提交改动会丢）；dry-run 透明标记受保护孤儿
- **已合入可清理**：GC 段额外识别「分支已合入 main 但 worktree 未清理」的半残留态（`git merge-base --is-ancestor <branch> main` 命中）。合入即报告，不受 24h TTL 约束；尊重 note.md/v2.md 白名单；`WORKTREE_GC_CLEAN=1` 时用 `git worktree remove --force`（非裸删目录，避免 `.git/worktrees/<name>` 元数据残留）。与 ORPHAN 孤儿正交，独立报告
- **白名单**：直接含 `note.md` 或 `v2.md` 的目录不清理；活跃 worktree 及其祖先/内部目录不清理
- git 元数据清理用 `git worktree prune`（仅清 `.git/worktrees/<name>`，不清文件系统目录）
- **detached HEAD worktree GC（轨道 C）**：`.worktree/omx-team/*/worker-*` 等 detached HEAD worktree（porcelain 输出 `detached` 而非 `branch`）取其 HEAD SHA，`is-ancestor <sha> main` 命中即报告/清理；复用 dirty/白名单护栏
- **Stash GC**：OmX 自动 stash（`auto-safety-stash-before/after-*`）TTL 3 天（> 取代: 第一轮的 7 天，自动 stash 为短期切换产物，3 天足够保险），总 stash 上限 30；超限时最旧 stash 一并 drop（与 expired 合并去重）；`WORKTREE_GC_CLEAN=1`/`WORKTREE_GC_AUTO=1` 时 drop 自动 stash（无 TTL 约束）+ 手动 stash（需超 3 天）且当前分支非来源分支
- **自动清理（WORKTREE_GC_AUTO=1）**：worktree >15 或 stash >30 时，SessionStart 自动按 CLEAN 逻辑清理已合入的 detached/merged worktree 与过期/超量 stash，无需手动设 `WORKTREE_GC_CLEAN`；阈值未超仍 dry-run；护栏不变
- **stash pop 跨基线告警**：PreToolUse hook 检测 `git stash pop/apply`，若当前分支不在 stash 来源分支祖先链上，stderr 告警不阻塞（信息护栏，与分支保护同策略）
- **主 worktree 落后 main 告警**：SessionStart 检测主 worktree 在 feature 分支且落后 origin/main 时，输出醒目告警（hook/脚本改进未生效），建议 push 保命后切 main 同步；信息护栏，不阻塞
- **僵尸 dirty worktree 告警**：分支已合入 main 但工作区有未提交改动的 worktree，GC 跳过保护并输出 🧟 告警，提示人工 commit/discard 后才能清理；信息护栏
- **长期未活动 feature worktree 告警**：未合入 main 的 feature worktree，HEAD commit 超 7 天无活动，输出 💤 提醒；信息护栏，不清理

### 提交批处理

- **同一逻辑变更聚合为 1 个 commit**。禁止每个 `Edit`/`Write` 后立即 commit
- 批处理窗口：连续编辑后，待所有变更完成并 audit PASS 后一次性 `git add` + `git commit`
- **版本 bump 必须在 PR 最后**
- OMX team auto-checkpoint 不得打断批处理窗口

### OMX Team 分支隔离

- **OMX team worker 必须使用子分支**：`{parent-branch}/worker-{N}`，禁止直接 commit 到 parent branch
- 主 session 持 parent branch，worker 完成后通过 PR 或 cherry-pick 合入

### Team 技能复杂度门槛

- **少于 5 个独立文件变更 → 直接执行，跳过 Team 管线**
- 仅跨模块重构（≥5 文件）、安全审计、多仓库同步、多视角对抗验证触发 Team
- 简单任务时降级为并行 Agent 调用

## 工作流规则

### 数量验证门禁

- **涉及 STATUS.md / README.md / ARCHITECTURE.md 中数量/百分比/合计/版本计数的变更，必须实际统计，禁止凭记忆编造**
- 统计方法必须可复现（shell one-liner 或 `python3` 脚本），优先用 `python3` 避免 zsh/BSD 差异
- 有版本号 + 无版本号 = 组件总数（`awk -F'|'` 逐行验证）
- 同步检查表三列必须与各文档 `grep -oP 'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+' | sort -u | wc -l` 实际数一致
- Dashboard 按域统计表合计行变更时，必须同步更新仪表盘计数与百分比
- **跨维度交叉验证**：单表自洽不足以防漂移，必须交叉验证不同章节/文档中描述同一事实的数字。`scripts/audit-status.py` check 8 已实现 RELEASE/FACTORY 跨维度检查
- **CountGuard hook**（`.claude/hooks/count-guard.mjs`）：BLOCK 级（组件总数/平均进度/有版本号），WARN 级（分数/百分比/已有/已创建）。告警不可忽略
- **审计闭合前必须跑 `python3 scripts/audit-status.py --network`**，全部 PASS 方可声称"无残余问题"

### 编辑纪律（> 取代: 2026-06-14 编辑策略 §原子写入优先）

- **读完所有相关文件后再编辑**——禁止边读边改。`git log --oneline -5` + `Read` 确认基线
- **列出完整变更清单后再动手**。同一文件所有修改一次性完成
- 优先 `Write` 替代多次 `Edit`（变更 > 30% 时）。禁止 Edit 循环
- **声称"已完成"前必须核对源码**——禁止凭常识假设

### PR 聚合规则

- 同一模块所有文档修复 → 1 个 PR；跨文档同步 → 1 个 PR
- **禁止 1 行变更的 PR**
- 同逻辑变更聚合为 1 个 commit，版本 bump 放 PR 最后

### 成本纪律

- 校验命令（`git log`/`grep`/`head`/`ls`）不受成本约束
- `sequential-thinking` 仅在多假设推理时使用
- 会话成本超 $30 时主动与用户确认
- 信任确定性工具：100 分后不重复跑相同 stage

### 版本号自动递增

> **核心规则：每次更新迭代，版本号都要 +1。**

| 版本号 | 位置 | 触发递增 |
|--------|------|----------|
| 文档发布版本 | `release/manifest/latest.json` | 任何追踪文件变更 |
| 信任规则版本 | `.repo-contract.yaml` → `trust_hardening.ruleset` | 信任加固规则变更 |

**Bump 策略**：PATCH = 错字/链接修复；MINOR = 新增模块/章节/架构变更；MAJOR = 治理体系重构

**触发文件**：`STATUS.md`、`README.md`、`ARCHITECTURE.md`、`module/README.md`、`module/*/SPEC.md`、`.repo-contract.yaml`、`.foundationx/repo-contract.json`、`.foundationx/status/index.json`、`.foundationx/blockers.json`、`foundation-bom.yaml`

**工具**：`./scripts/version-bump.sh`（默认 patch）、`--level minor/major`、`--target trust`、`--dry-run`

**门禁**：VersionGuard Stop Hook 自动检查。版本递增是会话收尾强制步骤。版本号只能升不能降。bump 必须是 PR 最后一个 commit。Stop hook 发现版本落后时自动补 bump。

> **适用范围区分**：本节"每次迭代+1"针对**仓库 release manifest 版本**（`release/manifest/latest.json`）。**模块 spec 版本**（`module/*/SPEC.md` 的 `Spec-Version`）遵循 [`CONSTITUTION.md` §10.4](docs/constitution/10-change-management.md)——只反映接口契约演进，文档治理变更不触发 bump。二者独立，不可混用。

## 核心原则

- **消除信息差**：编辑前验证基线，禁止凭记忆假设
- **Simplicity First**：最小变更集，不做超出范围的修改
- **Surgical Changes**：精准修改，不波及无关文件
- **Goal-Driven**：所有变更必须追溯到明确目标

## 认识论标准

> **权威来源：** [`docs/constitution/20-epistemic-standards.md`](docs/constitution/20-epistemic-standards.md)（宪法 §20）。适用于所有判断、审查、推断和断言。

- 证据标签强制：`[KNOWN]` / `[COMPUTED]` / `[INFERRED]` / `[COMMON]` / `[FRAME]` / `[GUESS]`
- 置信度显式写出：`HIGH` ≥80% · `MED` 50–80% · `LOW` 20–50% · `VERY LOW` <20% · `UNKNOWN`
- `[FRAME]` 和 `[GUESS]` 置信度上限为 `LOW`
- 禁止 `FRAME → REALITY`：管线评分、治理状态 ≠ 代码正确或生产稳定
- 反奉承红旗触发时：切掉具体细节 → 改标 `[GUESS]` → 或写"我不知道。"
- 不知道时第一行必须写：`我不知道。`
- 涉及判断、推断或事实断言的输出末尾必须附：`[RULES I BROKE]：...`

## 模块工作流规则（自动分支 + 对齐同步 + PR 闭环）

> 处理 `module/{模块名}/` 下任何文件时，自动执行端到端闭环。

### 1. 自动分支创建

触发：编辑 `module/{module-name}/` 下任何文件时。从 `main` HEAD 创建分支：`docs/{module}-{描述}` / `feat/{module}-{描述}` / `fix/{module}-{描述}`。创建后验证 `git merge-base --is-ancestor main HEAD` 返回 0。

### 2. 编辑纪律

- 列出该模块所有需变更的文件清单后再动手，禁止边读边改
- 同一文件只编辑一次，同模块文档修复 → 1 个 commit → 1 个 PR

### 3. 自动对齐文档同步（commit 前必检）

| 对齐文档 | 何时更新 |
|----------|----------|
| `ARCHITECTURE.md` | 模块状态/依赖/设计原则变更 |
| `module/README.md` | 模块列表/层级/职责变更 |
| `module/FOUNDATION-TRACKER.md` | Issue/PR 进度变更 |
| `README.md` | 组件数量/架构图/索引变更 |
| `STATUS.md` | 模块版本/状态变更 |

快速扫描：`git diff HEAD -- module/ | grep -E '(Status|依赖|状态|count|数量|Core)' || echo "无需对齐"`

### 4. 自动 PR 创建 + 合并 + 清理

```bash
git push -u origin HEAD
gh pr create --title "<type>: <描述>" --body "[模块: {module}]

{说明}" --base main
gh pr merge --squash --delete-branch
git checkout main && git pull origin main
```

PR 标题遵循 Conventional Commits（不含模块名，模块名放 body 首行），不超过 50 字符。合并策略：squash merge。确认合并后删除本地分支。

### 5. 模块内部一致性规则（> 新增: 2026-06-23 binance 审计复盘）

> 以下规则从 `module/binance/` 跨文件审计的 13 项矛盾中提炼，适用于所有模块。

#### 5.1 单一事实来源

- **TRACEABILITY.md §6 仪表盘禁止独立维护 FR 实现状态**。仪表盘的"实现状态"行必须从 §1 FR 表的 `实现状态` 列派生（grep/awk 自动统计），不得手写。二者出现差异时以 §1 为准。
- **FR 状态以 TRACEABILITY.md §1 为权威来源**。`ACCEPTANCE.md`、`SPEC.md` Appendix D、`FEATURES.md` 等文件可引用或汇总，但不得独立声明 FR 级别的 Done/Pending/Pending 状态。AC 粒度状态以 `ACCEPTANCE.md §2` 为准。

#### 5.2 附录版本同步

- **SPEC.md 的 Appendix 不得冻结为历史快照而不声明**。若 Appendix 仅覆盖部分 FR（如 Appendix D 仅覆盖 FR-001~FR-011 而模块已扩展至 FR-030），必须：(a) 在 Appendix 顶部添加弃用声明，标明"已冻结，权威来源见 XXX"；(b) 提供新旧编号映射（如有）；(c) 声明其 Status 列的含义（如"Approved=已批准纳入规格，不代表 runtime 已实现"）。
- **FR 总数变更时必须扫描** SPEC.md 所有 Appendix、TRACEABILITY.md 所有汇总行、ACCEPTANCE.md 覆盖矩阵，确保无遗漏更新。

#### 5.3 DoD 与验收清单交叉验证

- **SPEC.md §22 Release DoD 的勾选状态必须与 ACCEPTANCE.md §5 一致**。DoD 中的可验证项（如"TRACEABILITY 完成"、"Boundary gates 文档化"）在 ACCEPTANCE.md §5 中标记为 Done 时，DoD checkbox 必须同步勾选。反之，DoD 中未勾选的运行时项（如"所有 FR 实现完成"）必须在 ACCEPTANCE.md §5 中标记为 Not Done。
- **DoD 标题版本号必须与 SPEC.md §1 Spec-Version 一致**。版本 bump 时 DoD 标题同步更新。

#### 5.4 跨文件 PR/commit 前检查

编辑 `module/{module}/` 下任一文件后，commit 前执行：
```bash
# 检查 TRACEABILITY §1 vs §6 仪表盘 FR 状态一致性
diff <(grep -P '^\| FR-\d+' module/{module}/TRACEABILITY.md | awk -F'|' '{print $2, $7}') \
     <(grep 'FR-.*Partial\|FR-.*Pending\|FR-.*Done' module/{module}/TRACEABILITY.md | grep -v '^\| FR' | head -30)
# 若不一致 → 以 §1 为准修正 §6

# 检查 SPEC.md Appendix D 是否有弃用声明（若 FR 总数 > 附录覆盖数）
spec_fr=$(grep -c '^### FR-' module/{module}/SPEC.md)
appendix_ac=$(grep -c 'AC-BNC-' module/{module}/SPEC.md)
if [ "$appendix_ac" -gt 0 ] && [ "$spec_fr" -gt 11 ]; then
  grep -q '弃用声明\|历史遗物\|已冻结' module/{module}/SPEC.md || echo "WARNING: SPEC.md Appendix D 可能过期，需添加弃用声明"
fi

# 检查 SPEC §22 DoD 版本号 vs SPEC §1 Spec-Version
dod_ver=$(grep -oP 'v\d+\.\d+\.\d+' module/{module}/SPEC.md | head -1)
spec_ver=$(grep -oP 'Spec-Version:\s*v\d+\.\d+\.\d+' module/{module}/SPEC.md | grep -oP 'v\d+\.\d+\.\d+')
[ "$dod_ver" = "$spec_ver" ] || echo "WARNING: SPEC §22 DoD 标题版本 ($dod_ver) ≠ Spec-Version ($spec_ver)"
```

> 本规则受 `~/.claude/rules/ecc/matrix-scoring-rules.md` 的 R1（跨表走查）原则约束。冲突时以 CONSTITUTION.md 为准。

## 评分纪律

> 详细规则见 `~/.claude/rules/ecc/matrix-scoring-rules.md`。受保护文件修改走 RSI 流程。

**评分前置步骤**：
1. **措辞强度分级**：只对【硬】约束（必须/不得/禁止/触发）扣分；【软】（优先/推荐）不扣分；【开】（等/可/允许）只验证存在性
2. **全链路跨表走查**：遍历 §1-§5 全部验证列，路径存在即闭合
3. **辅助元数据排除**：覆盖率仪表盘/变更历史不参与评分

评分前检查管道交汇：`git log --oneline --since="1 hour ago" -- module/{module}/`，已修复问题不重复扣分。单模块评分超 5 轮未收敛时暂停，交 arbiter 裁决。

## 复盘元规则

- **新增规则必须声明 `supersedes`**，引用被取代的规则编号
- **规则 TTL**：复盘来源超过 90 天自动降级为"参考"，除非标注 `[永久]`
- **重复合并**：新增前检查是否与现有规则重叠，重叠则合并
- **年度瘦身**：每季度检查，合并/删除已内化的规则。目标 < 350 行

## 通用约定

- **语言**：回复/文档/提交信息默认中文，英文保留给仓库名、模块名、命令和技术术语
- **提交**：Conventional Commits 前缀 + 中文描述。末尾必须追加 `Co-Authored-By: Claude <noreply@anthropic.com>`。`gh pr create` body 末尾同样包含
- **链接**：组件引用使用 `https://github.com/ZoneCNH/<repo>` 链接
- **规格标准**：模块规格遵循 `CONSTITUTION.md` 第四条，23 节结构。模板见 `module/README.md`。追溯矩阵规范见 `docs/governance/TRACEABILITY.md`
- **Goal 文档**：修改 `docs/goal/` 后同步 `CHANGELOG.md`；提交前运行 `lint-goal.sh && lint-goal.sh --spec`
- **安全**：禁止提交凭证/API key/账户 ID/私有端点/实盘交易配置

## 仓库命名规则（全局强制）

> 所有 ZoneCNH 仓库统一使用 **snake_case**（下划线）命名，禁止 kebab-case（连字符）、PascalCase 和 camelCase。

| 模式 | 示例 | 状态 |
|---|---|---|
| `snake_case` | `market_data`、`domain_market`、`xlib_standard` | ✅ 唯一合法格式 |
| `kebab-case` | `market_data`、`domain_market` | ❌ 禁止 |
| `PascalCase` | `MarketData` | ❌ 禁止 |
| `camelCase` | `marketData` | ❌ 禁止 |

**例外（仅限以下两个特殊仓库）**：
- `x.go`（Composition Root，点号为设计标识）
- `binance.rs`（Rust 实现，语言后缀惯例）

**Go module 路径同步规则**：新建或重命名仓库时，`go.mod` 中的 `module` 声明必须与仓库名保持一致，即 `module github.com/ZoneCNH/{snake_case_name}`。

**新建仓库时**：命名必须符合 snake_case，否则 AI agent 应拒绝创建并提示修正。

# Harness 自动化

三层自动化体系（安全/感知/审查）。

**Hook 生命周期**：PreToolUse（安全拦截）→ PostToolUse（自动格式化）→ PreCompact（保存状态）→ SessionStart（注入状态）→ Stop（审查变更+调试残留）

**模式控制**（`.claude/.harness-state`）：`/harness-mode full|hotfix|tweak`，`/harness-phase design|build|fix`，`/harness-status` 查看状态

**GC Agent**：`node scripts/gc-scan.mjs [--json]` 定期扫描 8 维健康状态

**健康检查**：`node scripts/check.mjs`

## 待办基础设施优化

| # | 项 | 方案 |
|:---:|------|------|
| O5 | CI diff 感知 | job 增加 `if: steps.filter.outputs.module == 'true'` |
| O8 | CI 死锁 | docs-only PR reduce 到 3 个必须 job |
| O10 | Hook 合并 | edit-guard + count-guard → `pre-edit-check.mjs` |
| O6 | 自动影响分析 | `git diff --name-only` → 需同步的对齐文档列表 |

## 成熟度路线图

| 级别 | 名称 | 指标 | 状态 |
|:---:|------|------|:---:|
| L0 | 裸用 | 无 CLAUDE.md | — |
| L1 | 规则层 | CLAUDE.md + 行为准则 | ✅ |
| L2 | 反馈回路 | PreToolUse + SessionStart + Stop | ✅ |
| L3 | 自动修正 | PostToolUse + PreCompact + 审查报告 ≥5 | ✅ |
| L4 | 自治系统 | GC Agent 连续 3 次 0 critical | ✅ |
| L5 | 自治执行 | Agent 70%+ Task 自动化 + 人类介入<30% | 🔧 |


<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:6cd5cc61 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->

<!-- BEGIN BEADS REPO OVERRIDE — 本仓库覆盖声明（非 bd 生成，勿自动覆盖） -->
## Beads 与本仓库治理的优先级（覆盖 beads prime 注入）

`bd prime` / SessionStart hook 注入的 beads 指令含通用规则，部分与本仓库定位冲突，以下条款**覆盖** beads 注入内容：

1. **本仓库是 Markdown 文档枢纽，非代码仓**。beads 的 "Do NOT use markdown files for task tracking" 不适用——本仓库的 `module/*/SPEC.md`、`TRACEABILITY.md`、`docs/goal/` 等 markdown 制品是核心交付物，继续按 `CONSTITUTION.md` 维护。
2. **OMC TaskCreate/TaskUpdate 仍可使用**。beads 的 "Prohibited: Do NOT use TodoWrite, TaskCreate" 仅指代 beads 自己的任务追踪场景；OMC 编排、Team 协调、进度跟踪继续用 Task 工具，二者不互斥。
3. **MEMORY.md / `.omc/` / notepad 体系保留**。beads 的 "Do NOT use MEMORY.md files" 不适用——本仓库用 OMC notepad/project-memory/wiki 做跨会话记忆，beads 的 `bd remember` 是补充而非替代。
4. **stealth 模式**：beads 数据不进 git（`.beads/` 本地），不参与本仓库的 PR/commit 流程；issue 追踪是本地辅助，不影响 `CONSTITUTION.md` §0 分支纪律与数量验证门禁。
5. **冲突时优先级**：`CONSTITUTION.md` > 本仓库 `CLAUDE.md`/`AGENTS.md` 治理条款 > beads prime 注入。beads block 自身已声明 "Explicit user or orchestrator instructions override"，本段即该 override。
<!-- END BEADS REPO OVERRIDE -->
