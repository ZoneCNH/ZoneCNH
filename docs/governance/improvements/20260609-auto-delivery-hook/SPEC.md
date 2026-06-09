# 自动化提交合并 Hook 改进规格

Status: Draft

## 1. 背景

当前任务完成后仍依赖人工提交、合并和清理 worktree，容易遗漏 `main` 同步检查、Lore 提交信息、合并后清理和运行证据记录。

## 2. 问题陈述

需要在 Codex 任务完成时自动完成本地交付闭环，但不能违反 `CONSTITUTION.md` 第零条分支纪律，也不能绕过第十四条对工作流自身改进的治理要求。

## 3. 目标

- 在 Stop hook 检测到 `task_complete` 后触发自动交付。
- 在非 `main` 分支自动提交已验证变更。
- 在 `main` 干净且同步时自动 fast-forward 合并。
- 合并成功后自动清理 feature worktree 和已合并分支。
- 失败时保留可诊断日志和状态，不破坏 Codex 会话。

## 4. 非目标

- 不自动解决 merge conflict。
- 不强制 push。
- 不在 `main` 上自动提交。
- 不绕过 Spec -> Code 四源评分和第十四条治理流程。
- 不替代 CI、PR 审查或人类批准。

## 5. 范围

新增仓库级 hook 配置、自动交付脚本、治理说明文档和本元级改进规格。

## 6. 约束

- `main` 上禁止直接开发和提交。
- 自动合并只允许 fast-forward。
- `main` 必须干净且与 `origin/main` 一致。
- 敏感文件和疑似密钥内容必须阻断自动提交。
- Hook 失败必须 fail-open，不能中断 Codex Stop 流程。

## 7. 功能需求

| 编号 | 需求 |
|------|------|
| FR-1 | Stop hook 能调用仓库内交付脚本 |
| FR-2 | 脚本能识别 `task_complete` 或通过显式环境变量强制触发 |
| FR-3 | 脚本能阻止 `main` 分支自动提交 |
| FR-4 | 脚本能 stage、扫描、验证并生成 Lore 提交 |
| FR-5 | 脚本能在 `main` 干净且同步时 fast-forward 合并 |
| FR-6 | 脚本能在合并成功后清理 worktree 和分支 |
| FR-7 | 脚本能把状态和日志写入非版本控制路径 |

## 8. 行为需求

| 编号 | 行为 |
|------|------|
| BR-1 | 未检测到完成事件时跳过 |
| BR-2 | 任何门禁失败时停止后续提交或合并 |
| BR-3 | Hook 模式下所有结果都返回 `continue: true` |
| BR-4 | dry-run 模式不得修改 index、提交或合并 |

## 9. 验收标准

| 编号 | 验收标准 |
|------|----------|
| AC-1 | `AUTO_DELIVERY_FORCE=1 AUTO_DELIVERY_DRY_RUN=1 ... --hook` 能完成 dry-run |
| AC-2 | `git diff --check` 通过 |
| AC-3 | `python3 -m pytest scripts/tests` 通过 |
| AC-4 | 当前 `main` 不干净或不同步时自动合并被阻断 |
| AC-5 | 新文档明确说明第零条和第十四条约束 |

## 10. 追溯矩阵

| FR | BR | AC |
|----|----|----|
| FR-1 | BR-1, BR-3 | AC-1 |
| FR-2 | BR-1 | AC-1 |
| FR-3 | BR-2 | AC-4 |
| FR-4 | BR-2, BR-4 | AC-1, AC-2 |
| FR-5 | BR-2 | AC-4 |
| FR-6 | BR-2 | AC-4 |
| FR-7 | BR-3 | AC-1 |

## 11. 设计

采用一个 Bash 脚本作为唯一执行入口，repo-local `.codex/hooks.json` 只负责调用脚本。脚本内部执行门禁、提交、合并和清理，运行状态写入 `.git/auto-delivery/`。

## 12. 数据与状态

运行态文件不进入仓库：

```text
.git/auto-delivery/status.json
.git/auto-delivery/auto-delivery.log
.git/auto-delivery/commit-message.txt
.git/auto-delivery/hook-payload.json
```

## 13. 安全

脚本阻止 `.env`、私钥、凭证、密钥文件名，以及 staged diff 中常见 secret 赋值模式自动提交。

## 14. 分支纪律

脚本在 detached HEAD 或 `main` 上阻断提交；合并前检查 `main` worktree 是否干净，且在存在 `origin/main` 时要求 `main == origin/main`。

## 15. 提交规范

自动提交使用 Lore 协议 trailers，记录约束、被拒绝方案、风险范围、测试和未测试项。

## 16. 同步策略

默认只合并本地 `main`，不 push。需要推送时由 `AUTO_DELIVERY_PUSH=1` 显式开启。

## 17. 清理策略

默认在 fast-forward 合并成功后后台执行 `git worktree remove <feature-worktree>` 和 `git branch -d <branch>`。任何合并失败都不会清理。

## 18. 失败模式

| 失败 | 处理 |
|------|------|
| 未完成事件 | skip |
| 当前为 `main` | block |
| 敏感内容 | block |
| 验证失败 | block |
| `main` 不干净 | block |
| `main` 未同步 | block |
| 非 fast-forward | block |

## 19. 测试计划

- dry-run hook 调用。
- `git diff --check`。
- 既有 Python 测试套件。
- 人工检查自动合并阻断条件。

## 20. 文档计划

新增 `docs/governance/AUTOMATED-DELIVERY-WORKFLOW.md`，并在 `docs/governance/README.md` 增加索引。

## 21. 迁移计划

合入后 repo-local hook 生效。首次执行可能需要 Codex hook trust 确认；确认后使用仓库内脚本，不修改个人全局 hook。

## 22. 风险

- Codex Stop payload 结构变化可能导致完成事件检测失败。保留 `AUTO_DELIVERY_FORCE` 和 `AUTO_DELIVERY_REQUIRE_TASK_COMPLETE=0` 作为显式运行开关。
- 自动合并可能与人类本地工作冲突。脚本以 `main` 干净和同步为硬门禁。

## 23. 开放问题

- 是否把 `AUTO_DELIVERY_PUSH=1` 作为团队默认值，需要由维护者根据远端权限和 CI 策略决定。
- 是否将完整自动交付纳入 Spec -> Code 管线的官方阶段，需要完成第十四条要求的后续评审。
