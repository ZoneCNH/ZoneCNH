# Claude 工作指南

本文件说明 Claude Code 在本仓库中工作时应遵循的约束。

## 最高指令源

当本文件与 `CONSTITUTION.md` 冲突时，以 `CONSTITUTION.md` 为准。`CONSTITUTION.md` 是系统级最高治理文件，定义了模块实现（§1-§14）和交付管线（§15-§19）的技术标准。本文件仅规定仓库级操作约定。

## 本仓库定位

ZoneCNH 的 `FoundationX` 量化交易基础设施文档枢纽，也是 `ZoneCNH/ZoneCNH` GitHub 个人主页仓库。核心内容是 Markdown 文档，不含应用代码：

- `README.md`：个人主页、技术栈、架构摘要和组件索引
- `ARCHITECTURE.md`：依赖拓扑、领域职责、设计原则和状态表（权威来源）
- `CONSTITUTION.md`：模块宪法 §0-§19（最高权威）
- `AGENTS.md` / `CLAUDE.md`：自动化代理和贡献者工作指南
- `docs/goal/`：Goal 驱动交付体系规范

实际实现位于 `github.com/ZoneCNH` 下约 70 个独立仓库。本仓库只描述和链接模块，不承载源码。没有构建/lint/测试步骤。

## 文档同步

`README.md`、`ARCHITECTURE.md`、`STATUS.md` 从不同视角描述同一套系统，必须保持一致：

- **模块归属变更必须三文档同步**：更新所有 ASCII 架构图、各域说明表、组件明细表、按域统计表及包含该模块数量引用的所有行
- **版本号变更必须同步**更新 `ARCHITECTURE.md` 状态表和 `STATUS.md` 组件明细表。先确认 GitHub 实际 release 再改文档
- **组件增删必须同步**更新三文档的表格、域统计、仪表盘进度分布、域健康度描述、风险清单、同步检查表
- **`STATUS.md` 文档同步检查表**是交叉验证的快速入口，其自身计数也必须与实际一致
- 图中组件数量（如 `market-data (18)`）必须与实际表格行数一致。`ARCHITECTURE.md` 状态表是版本/状态/进度的事实来源

## 模块-仓库强制对应

- **每个列出 GitHub 链接的模块，必须有对应的公开仓库。** 新增模块时必须同时创建对应仓库。文档链接禁止指向 404
- **全量 404 扫描**：`grep -oPh 'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+' STATUS.md README.md ARCHITECTURE.md | sort -u | while read u; do repo=${u#ZoneCNH/}; gh api "repos/ZoneCNH/$repo" >/dev/null 2>&1 || echo "404: $repo"; done`
- CI 检查 `repo-existence-check.sh` 验证 HTTP 200
- 例外：`contracts` / `transportx` / `xlib-harness` / `xlib-evidence` 共享 `xlib-standard` Go module，但各自拥有独立仓库

## 当前架构模型

```text
基座 → 数据域 → 分析域 ⇄ 决策域 → 执行域 → x.go
```

- **基座**：`kernel`、`configx`、`observex`、`contracts`、`redisx`、`kafkax` 等 + L2.5 共享层 `decimalx`、`domain-market`、`domain-exchange`、`domain-macro`
- **数据域**：market-data、macro-data、alternative-data 采集器
- **分析域 ⇄ 决策域**：唯一双向关系；因子驱动信号生成，回测反馈因子评估
- **横切**：`alertx` 和 `observex` 贯穿所有领域

编辑时必须保留九条核心设计原则：策略只通过 `risk-engine` 提交订单；回测与实盘共享因子/信号/风控代码；`contracts` 定义跨域接口；数据不跨域；`order-engine` 抽象交易所差异；`x.go` 只做编排；域内模块平级协作；反馈通过事件表达；领域语义沉到 L2.5。

## 分支纪律（最高优先级）

> 详见 `CONSTITUTION.md` 第零条。本条优先级高于以下所有条款。

- **禁止**在 `main` 分支上直接编辑或提交
- **所有分支必须从 `main` HEAD 创建**，创建前 `git fetch origin && git rebase origin/main`
- 所有开发通过 `git worktree` 或 feature branch 进行
- 工作完成后通过 PR 合入 main，随后清理 worktree 和 feature branch

### 分支保护（> 取代: 2026-06-14 分支纪律 §自动删除）

- **禁止自动删除未合并分支**。Stop/SessionEnd hook 切换 main 前必须验证：`git log origin/main..HEAD --oneline | wc -l`（>0 则禁止删除）或 PR 已合并
- **分支恢复**：误删时 `git reflog` 定位 SHA → `git checkout -b <branch> <sha>`

### 工作区 GC

- **`.worktree/` 临时文件 TTL = 24h**。PreCompact/PostToolUse hook 自动清理超 24h 的 stale 文件
- OMX team worker 子目录在下一个 SessionStart 时自动 `rm -rf`
- 例外：`note.md`、`v2.md` 不自动清理

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

## 核心原则

- **消除信息差**：编辑前验证基线，禁止凭记忆假设
- **Simplicity First**：最小变更集，不做超出范围的修改
- **Surgical Changes**：精准修改，不波及无关文件
- **Goal-Driven**：所有变更必须追溯到明确目标

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
| L3 | 自动修正 | PostToolUse + PreCompact + 审查报告 ≥5 | 🔧 |
| L4 | 自治系统 | GC Agent 连续 3 次 0 critical | ⬜ |
