# RSI 改进规格：Worktree 工具链行为增强

- **日期**: 2026-06-19
- **来源**: worktree 流程深度分析（7 活跃 worktree、孤儿 GC 复盘、§0 分支纪律核查）
- **影响文件**: `.claude/hooks/session-context.mjs`、`.claude/hooks/pre-tool-check.mjs`、`CLAUDE.md` §工作区 GC（交付流程工具，走 §19 CRI）
- **状态**: 提议

---

## 问题与理想状态

**问题**：对当前 7 个活跃 worktree 的深度分析暴露两个工具链缺口：

1. **孤儿 GC 盲区**：`session-context.mjs` 的 Worktree 孤儿 GC 段（L119–L192）只能识别「已 `git worktree forget` 的孤儿目录」（不在 `git worktree list` 中）。当前 `registered` 集合只用 `worktree` 行、丢弃 `branch` 行，`classify` 函数把「分支已合入 main 但 worktree 仍注册」的半残留态归入 `self` 而**完全跳过**。实测证据：`redisx-v1.0.3-dev-integration` worktree 的分支 `docs/redisx-v1.0.3-20260619` 已通过 `git merge-base --is-ancestor` 确认合入 main，但 worktree 仍存在且 GC 扫不到（`git merge-base` 退出码 0 = MERGED）。

2. **分支命名无前置拦截**：`CONSTITUTION.md` §0.2.2 要求分支命名遵循 `{type}/{module}-{description}`，但无 hook 在创建时拦截违规名。实测证据：当前本地 24 条非 main 分支中 4 条违规（`taosx`/`redisx`/`postgresx`/`clickhousex`，裸模块名无 `type/` 前缀），违规率 16.7%。`pre-tool-check.mjs` 已实现 `git push --force`/`rm -rf` 拦截范式可复用，但当前未覆盖 `git checkout -b`/`worktree add -b`/`switch -c`。

**理想状态**：

1. GC 能精确识别「分支已合入 main 但 worktree 未清理」的半残留态，默认报告并提供 `git worktree remove` 提示；现有 ORPHAN/dry-run/TTL/白名单保守契约行为不变。
2. 创建分支时若命名违规，pre-tool-check hook 拦截并给出建议改名；4 条历史违规裸分支的处置定性由人类决定，不自动改名。

## 不做什么

- 不把「已合入」类别并入 ORPHAN 的 `rmSync` 删除流——两者正交。已合入的 worktree 仍被 `git worktree list` 管理，裸删目录会留下需 `git worktree prune` 才能清理的元数据残留。
- 不让新类别受 `TTL_MS`（24h）约束——「分支已合入 main」是比 mtime 强得多的信号，合入即可报告，无需等待。
- 不自动改名 4 条历史违规裸分支——它们可能是模块长期主干分支（需 §0 增补例外条款）或真违规（需 `git branch -m`），属人类决策范畴，本提案仅记录待定夺。
- 不拦截人类在终端直接执行的 `git checkout -b`——hook 只覆盖 agent 发起的 Bash 调用；全覆盖需另配 git 原生 `reference-transaction` hook 或 CI 校验，超出本提案范围。
- 不改 §0.2.2 规范文本本身——若 4 条裸分支被定性为合法长期主干，需另起 §14.3 提案修 CONSTITUTION 增补例外。

## 约束

- 修改文件（交付流程工具，§19 CRI，不在 §14.1 受保护清单）：
  - `.claude/hooks/session-context.mjs`（GC 段新增「已合入可清理」类别）
  - `.claude/hooks/pre-tool-check.mjs`（新增分支命名 lint，复用现有 `block:true` 范式）
  - `CLAUDE.md` §工作区 GC（同步声明新类别，保持文档与代码对齐）
- **§14 vs §19 归属判定**：`.claude/hooks/` 不在 §14.1 明文清单（清单为 `.claude/agents/`、命令入口、RUBRIC、STRUCTURAL-SCORING、ARBITER-PROTOCOL、outer-metrics、CONSTITUTION.md）。hooks 属交付流程工具，按 §14.7 归 §19 CRI。**此判定基于 §14.1 清单字面含义；若人类维护者认为 hooks 应属 §14.3，本提案需升级为完整五步 RSI。**
- 保守契约红线：dry-run 默认、`WORKTREE_GC_CLEAN=1` 才真删、PROTECT 白名单（`note.md`/`v2.md`）、主 worktree 路径前缀排除——全部保留不动。

## 验收标准（ISC）

- [ ] ISC-1: `session-context.mjs` GC 段新增「已合入可清理」类别——复用已有的 `git worktree list --porcelain` 调用，额外解析 `branch refs/heads/<name>` 行（需 `replace(/^refs\/heads\//, "")`），按 worktree 块聚合为 `path → branch` 映射
- [ ] ISC-2: 对每个非主、非 detached 的注册 worktree 跑 `git merge-base --is-ancestor <branch> main`，命中即归入新类别。默认只报告（给出 `git worktree remove <path>` 提示）；`WORKTREE_GC_CLEAN=1` 时调用 `git worktree remove --force <path>`（**非 `rmSync`**，避免破坏 git 元数据）
- [ ] ISC-3: 正确处理 3 个坑——(a) 主 worktree 过滤 `if (path === projectRoot) continue`（与现有 `regSub` 同款过滤，避免 `main` 自祖先误报）；(b) detached HEAD 跳过（无 `branch` 行的块，避免 `undefined` 分支名）；(c) shell 注入防护（分支名作为单参数传 `git merge-base` 或用 `execFileSync`，**禁止字符串拼接**，防止 `;rm -rf` 类恶意分支名）
- [ ] ISC-4: 新类别不受 `TTL_MS` 约束（合入即报告），但尊重 PROTECT 白名单保持一致；输出与 ORPHAN 段视觉区分（不同 emoji/标题，避免混淆两类清理）
- [ ] ISC-5: `pre-tool-check.mjs` 新增分支命名 lint——提取 `git (checkout -b|worktree add .* -b|switch -c)\s+(\S+)` 的分支名，校验 `^(docs|feat|feature|fix|test|refactor|chore|governance|benchmark)/`，违规时 `block:true` 并在 reason 给出建议改名（如 `taosx` → `docs/taosx-<desc>`）。lint 不受 tweak/design 模式豁免（放在现有 `if (!isTweak && !isDesign)` 块**之外**）
- [ ] ISC-6: `node --check` 两脚本通过；dry-run 等价逻辑精确捕获已知半残留态 `redisx-v1.0.3-dev-integration`（`git merge-base` exit=0）且不误报 6 个活跃 worktree；现有 ORPHAN/dry-run/TTL/白名单契约行为回归不变

## 测试策略

| ISC     | 验证方法                                                                                          |
| ------- | ------------------------------------------------------------------------------------------------- |
| ISC-1   | `git diff` 确认 GC 段新增 branch 行解析与 `path → branch` 映射                                    |
| ISC-2   | 等价 dry-run 逻辑对 7 个 worktree 跑一遍：仅 `redisx-v1.0.3-dev-integration` 命中「已合入」类别 |
| ISC-3   | 构造 detached HEAD worktree 场景验证跳过；验证分支名通过参数传递而非字符串拼接（代码审查）        |
| ISC-4   | 对含 `note.md` 的已合入 worktree 验证白名单保护生效；确认输出与 ORPHAN 段视觉区分                |
| ISC-5   | 用合规名（`docs/foo-bar`）和违规名（`foo`）各跑一次拦截验证；确认 tweak/design 模式下仍拦截       |
| ISC-6   | `node --check .claude/hooks/session-context.mjs && node --check .claude/hooks/pre-tool-check.mjs` |

## CRI 路径（§19）

本提案涉及交付流程工具（hooks），走 §19 CRI 分级审批。

| CRI 步骤 | 状态 | 说明                                                                                                                                                              |
| --------- | ---- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 提案登记  | 本文件 | `docs/governance/improvements/20260619-worktree-tooling/SPEC.md`                                                                                                |
| 风险分级  | 待定 | 建议 R2（工程 Owner 审批）：hooks 行为变更，影响所有会话启动与命令拦截，但默认 dry-run 保守、可回退。lint 为新增拦截，可能误拦合规命令，需 Owner 确认 type 白名单。 |
| A/B       | 降级 | 见「外层指标（诚实降级）」                                                                                                                                        |
| Outer 验证 | 降级 | 见「外层指标（诚实降级）」                                                                                                                                        |
| 人类批准  | 待   | 最终门                                                                                                                                                            |
| 实施      | 待   | 批准后另起 task 执行 ISC-1~6                                                                                                                                      |

## 外层指标（诚实降级）

§14.3/§19 要求以 outer-metrics 真实指标评判，不以 scorer 自身分数评判。**本仓库 outer-metrics 现状（诚实记录）**：

- 18 个模块文件中**仅 3 个字段非 null**（`rework_commit_count`/`rework_loc_ratio`/`developer_override_count`，由 `scripts/outer-metrics-from-git.sh` 采集）；其余 8 个字段（bug 数、CI 失败率、事故、安全公告、回滚、延迟、flake）全 null（Issues/CI/Dependabot/监控/部署系统均未接入）。
- `correlation.json` 全 null，无相关系数基线。
- CI runner 自 2026-06-18 下线，`outer-metrics.yml` 仅剩手动 dispatch，自动采集已停。
- **本仓库至今没有完整、合规地走过一次 §14.3 五步 RSI**；唯一合并的先例（`20260614-spec-ref-substance-over-form`）明文跳过了 A/B 和 Outer 验证。

**A/B 降级方案**（参照 spec-ref 先例 L44-45「跳过 + 理由」格式）：

| 步骤 | 处理 | 理由 |
| ---- | ---- | ---- |
| A/B | 降级为代理指标 | 对 natsx/redisx/xlibgate 3 个有 worktree 活动的模块，对比改动前后 `rework_commit_count` 增量作为代理信号。非统计显著，仅作辅助参考。 |
| Outer 验证 | 降级 | `correlation.json` 全 null 无基线可供比对；CI runner 下线无法采集新数据。改动为工具行为补强（非评分算法变更），outer-metric 本非强相关场景。 |
| 人类批准 | **保留为最终门** | hooks 影响所有会话，必须人类确认保守契约不被破坏、lint type 白名单合理。 |

> 此降级理由已记录，不掩饰 outer-metrics 瘫痪事实。若后续 CI runner 恢复并积累 ≥3 模块基线，应回补完整 Outer 验证。

## 决策记录

| 日期       | 决策                            | 理由                                                                                                    |
| ---------- | ------------------------------- | ------------------------------------------------------------------------------------------------------- |
| 2026-06-19 | 创建本规格                      | worktree 流程深度分析暴露 GC 半残留态盲区与命名无拦截两个工具缺口                                       |
| 2026-06-19 | 归属 §19 CRI 而非 §14.3 RSI     | `.claude/hooks/` 不在 §14.1 明文清单（清单为 `.claude/agents/` 等），属交付流程工具；见「约束」节法律判定 |
| 2026-06-19 | 已合入类别用 `git worktree remove` 而非 `rmSync` | 已合入 worktree 仍被 `git worktree list` 管理，裸删目录留元数据残留                                    |
| 2026-06-19 | 4 条历史违规裸分支不在本提案处置 | taosx/redisx/postgresx/clickhousex 可能是模块长期主干，需 §0 增补例外或人工改名，属独立决策             |
| 待         | taosx 等裸分支定性              | 需人类确认是长期主干（→§14.3 修 CONSTITUTION）还是真违规（→`git branch -m`）                            |

## 变更日志

| 日期       | 变更内容 |
| ---------- | -------- |
| 2026-06-19 | 初始版本 |

## 待办

- [ ] 人类维护者确认 §14 vs §19 归属判定（hooks 是否需升级为 §14.3 RSI）
- [ ] 人类维护者定性 4 条历史违规裸分支
- [ ] 批准后实施 ISC-1~6（另起 task，按 §0 在 feature branch 执行）
