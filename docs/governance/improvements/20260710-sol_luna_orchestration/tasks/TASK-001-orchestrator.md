# TASK-001：实现外层编排器

- **目标**：`[FRAME, HIGH]` 实现 Sol 规划、3–5 Luna 并行、cheap gate、升级闸门和事务式集成。
- **写范围**：`scripts/sol_luna_orchestrator.py` `[FRAME, HIGH]`
- **依赖**：无 `[FRAME, HIGH]`
- **覆盖**：FR-002–FR-007、AC-002–AC-007 `[FRAME, HIGH]`

## 验收

- `[FRAME, HIGH]` exact model 为 `gpt-5.6-sol` / `gpt-5.6-luna`，effort 为 `xhigh`。
- `[FRAME, HIGH]` worker 只接受 3–5；scope 重叠、不安全 check 或无效 schema 在执行前拒绝。
- `[FRAME, HIGH]` Spec/Matrix 必须由 HEAD 跟踪且 M-edge/FR 闭合；scope 必须保持 POSIX 路径精确并拒绝 symlink/Git metadata。
- `[FRAME, HIGH]` cheap checks 必须在空根、无网络、clean-env、只读 worktree 的 `prlimit + bwrap` 沙箱内运行，stdin、tmpfs、资源和输出有界。
- `[FRAME, HIGH]` 明确失败先重试 Luna；四类证据问题才升级 Sol。
- `[FRAME, HIGH]` task/integration 声明与机械 diff 冲突必须升级；Sol 上下文只含失败摘要与通过 patch receipt，并输出 token 汇总。
- `[FRAME, HIGH]` 任一失败路径都不向父 worktree 留下部分 patch。
