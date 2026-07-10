# TASK-002：建立便宜验收与回归测试

- **目标**：`[FRAME, HIGH]` 用无模型调用的确定性测试覆盖路由、隔离、schema、timeout、重试和事务边界。
- **写范围**：`scripts/tests/test_sol_luna_orchestrator.py`、`scripts/tests/test_sol_luna_orchestrator_coverage.py` `[FRAME, HIGH]`
- **依赖**：TASK-001 的公开函数契约 `[FRAME, HIGH]`
- **覆盖**：AC-003–AC-005、AC-007 `[FRAME, HIGH]`

## 验收

- `[FRAME, HIGH]` 测试不得真实调用模型。
- `[FRAME, HIGH]` 失败路径断言父 apply 为零次；成功路径断言为一次。
- `[FRAME, HIGH]` 结构化 `fail` 后 `pass` 必须证明 Luna 被调用两次。
- `[FRAME, HIGH]` 真实 Git fixture 必须覆盖 rename/copy 双路径、ignored、反斜杠/空白路径、Git metadata symlink、HEAD 跟踪的 Spec/Matrix 与声明↔机械 diff 冲突。
- `[FRAME, HIGH]` 真实 sandbox fixture 必须证明宿主 home/`/opt` secret/`/run` socket/环境/stdin 不可见，worktree 与 Git metadata 只读，资源和父进程输出有界。
