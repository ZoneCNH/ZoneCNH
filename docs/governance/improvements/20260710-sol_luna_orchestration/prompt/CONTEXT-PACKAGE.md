# Context Package：Sol/Luna 分层编排

## 不变量

- `[FRAME, HIGH]` Orchestrator：`gpt-5.6-sol`，reasoning `xhigh`。
- `[FRAME, HIGH]` Executors：`gpt-5.6-luna`，reasoning `xhigh`，3–5 路。
- `[FRAME, HIGH]` 每个 executor 只有互斥写范围；不得创建子 agent。
- `[FRAME, HIGH]` cheap tests/scripts 优先；明确失败先 Luna 修复。
- `[FRAME, HIGH]` 只有 evidence missing/conflict、scope overlap、retry exhausted 回 Sol。
- `[FRAME, HIGH]` 父 worktree 最终一次性接收 combined patch。
- `[FRAME, HIGH]` 不修改 §14.1 保护文件，不替代正式四源 Gate。

## Executor 输出契约

```json
{
  "status": "pass",
  "summary": "完成内容与机械证据摘要",
  "changed_files": ["workspace/relative/path"]
}
```

[FRAME, HIGH] 输出必须符合严格 JSON Schema；模型文本不覆盖机械检查、实际 diff 或 scope 检测结果。

## 验证命令

```bash
python3 -m pytest scripts/tests/test_sol_luna_orchestrator.py -q
python3 -m py_compile scripts/sol_luna_orchestrator.py
python3 scripts/sol_luna_orchestrator.py probe
codex --strict-config doctor --json
git diff --check
```
