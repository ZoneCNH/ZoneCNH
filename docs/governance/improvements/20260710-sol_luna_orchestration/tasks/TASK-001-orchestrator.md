# TASK-001：实现外层编排器

- **目标**：`[FRAME, HIGH]` 实现 Sol 规划、3–5 Luna 并行、cheap gate、升级闸门和事务式集成。
- **写范围**：`scripts/sol_luna_orchestrator.py` `[FRAME, HIGH]`
- **依赖**：无 `[FRAME, HIGH]`
- **覆盖**：FR-002–FR-007、AC-002–AC-007 `[FRAME, HIGH]`

## 验收

- `[FRAME, HIGH]` exact model 为 `gpt-5.6-sol` / `gpt-5.6-luna`，effort 为 `xhigh`。
- `[FRAME, HIGH]` worker 只接受 3–5；scope 重叠、不安全 check 或无效 schema 在执行前拒绝。
- `[FRAME, HIGH]` 明确失败先重试 Luna；四类证据问题才升级 Sol。
- `[FRAME, HIGH]` 任一失败路径都不向父 worktree 留下部分 patch。
