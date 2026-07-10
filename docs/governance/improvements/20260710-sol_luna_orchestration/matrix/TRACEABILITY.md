# Sol/Luna 编排改进追溯矩阵

[COMPUTED, HIGH] 本矩阵把 `SPEC.md` 的 FR、AC、Task、实现路径和验证证据闭合；最终命令结果记录在 `evidence/2026-07-10/test/VALIDATION.md`。

## FR 总览

| FR | AC | Task | 实现 | 验证 |
|----|----|------|------|------|
| FR-001 | AC-001 | TASK-003 | `.codex/config.toml` | `codex --strict-config doctor --json` |
| FR-002 | AC-002, AC-003, AC-007 | TASK-001 | Sol plan schema、`ThreadPoolExecutor`、显式模型参数 | probe、unit、E2E smoke |
| FR-003 | AC-003, AC-006 | TASK-001 | scope 校验、primary-root runtime worktree | unit、受保护路径检查 |
| FR-004 | AC-003, AC-005 | TASK-001, TASK-002 | `_batch_details`、task/integration retry、`_sol_escalation` | unit |
| FR-005 | AC-004, AC-007 | TASK-001, TASK-002 | `_integration_repair`、combined patch | unit、E2E smoke |
| FR-006 | AC-004 | TASK-001, TASK-002 | `_workspace_info`、`_assert_parent_unchanged` | unit |
| FR-007 | AC-002, AC-003, AC-007 | TASK-001 | `.omx/state/orchestration/<run_id>/` 证据包 | probe、unit、E2E smoke |
| FR-001–FR-007 | AC-008 | TASK-003 | `AGENTS.md`、`docs/workflow/README.md`、本目录 | `git diff --check`、人工可读审查 |

## M-edge 细化追溯

[FRAME, HIGH] 每次 `run` 必须提供 workspace 内真实的 `--spec-ref`、对应 canonical `--matrix-ref`、一个或多个存在于该 Matrix 的 `--matrix-edge` 和至少一个非空全局 `--check`；规范化后的引用必须进入 Sol、Luna task/repair、integration repair 与 Sol escalation Prompt。§14.1 完整保护集是 `docs/governance/scoring/RUBRIC-*.md`、`docs/governance/STRUCTURAL-SCORING.md`、`docs/governance/scoring/ARBITER-PROTOCOL.md`、`.claude/agents/`、`.codex/agents/`、`.copilot/agents/`、`.claude/commands/spec-code-pipeline.md`、`.codex/skills/spec-code-pipeline/`、`.copilot/commands/spec-code-pipeline.md`、`.omc/state/outer-metrics/`、`.omx/state/outer-metrics/`、`.copilot/state/outer-metrics/` 和 `CONSTITUTION.md`；`.git`、保护集本身、`.`、祖先目录、通配符/glob 或其他覆盖保护集的宽 scope、危险 loader/exec flag、sandbox/ignored fail-closed 和声明↔diff 一致性规则均属于以下边的验收语义。

| Edge ID | FR | 需求 | 实现任务 | 验收标准 | 测试证据 |
|---------|----|------|----------|----------|----------|
| M-001 | FR-002 | `run` 强制真实 `spec-ref`、canonical `matrix-ref`、至少一个真实 `matrix-edge` 和至少一个全局 check | TASK-001 | AC-003、AC-007 | `scripts/tests/test_sol_luna_orchestrator.py`：CLI、文件归属、edge 存在性与全局 check 回归；隔离 E2E |
| M-002 | FR-002 | 规范化后的 `spec-ref`/`matrix-ref`/`matrix-edge` 进入 Sol、Luna task/repair、integration 和 escalation Prompt | TASK-001 | AC-003、AC-007 | `scripts/tests/test_sol_luna_orchestrator.py`：四类 Prompt 内容断言；`.omx/state/orchestration/<run_id>/` 证据包 |
| M-003 | FR-003 | 拒绝 §14.1 全部保护路径、`.git`，以及 `.`、保护路径祖先、通配符/glob 或其他宽 scope | TASK-001 | AC-003、AC-006 | `scripts/tests/test_sol_luna_orchestrator.py`：完整保护集、Git 元数据、祖先/宽 scope、rename 与 scope overlap 回归 |
| M-004 | FR-003 | 拒绝危险 argv；所有 checks 在 `prlimit + bwrap` 无网络、clean-env、空根、worktree/Git 只读沙箱运行 | TASK-001、TASK-002 | AC-003 | `scripts/tests/test_sol_luna_orchestrator.py`：argv allowlist 与真实宿主/环境/元数据/资源/输出隔离；coverage 测试覆盖安全分支 |
| M-005 | FR-004 | 模型前后审计 ignored，仅豁免本 run 制品；声明 `changed_files` 与机械 diff 冲突时回 Sol | TASK-001、TASK-002 | AC-003、AC-005 | `scripts/tests/test_sol_luna_orchestrator.py`：真实 ignored/RM parser、审计日志、声明冲突与 Luna retry |
| M-006 | FR-005 | integration repair 在 checks 后重新抓取 status、diff、scope，只有全局 gate 与 scope 均安全才捕获 combined patch | TASK-001、TASK-002 | AC-004、AC-005、AC-007 | `scripts/tests/test_sol_luna_orchestrator.py`：repair 后重新抓取与父 apply 次数；隔离 E2E |
| M-007 | FR-006 | 最终应用前维持父 worktree clean、HEAD 未变，并拒绝任何越界或部分 patch | TASK-001、TASK-002 | AC-004、AC-006 | `scripts/tests/test_sol_luna_orchestrator.py`：parent unchanged、失败路径零次 apply、scope 回归 |
| M-008 | FR-007 | 记录 trace refs、sandbox check、ignored 审计、scope、retry、patch、gate 和 token；Sol 仅接收失败摘要与通过 patch receipt | TASK-001、TASK-003 | AC-003、AC-007、AC-008 | `scripts/tests/test_sol_luna_orchestrator.py`：摘要压缩、SHA-256、token/ignored 日志与 Prompt 元数据断言；`git diff --check` |

[COMPUTED, HIGH] FR-002 至 FR-007 均至少有一个 M-edge，并分别闭合到实现任务、AC 和测试证据；M-edge 集合仅为 `M-001` 至 `M-008`。
