# Context Package：Sol/Luna 分层编排

## 不变量

- `[FRAME, HIGH]` Orchestrator：`gpt-5.6-sol`，reasoning `xhigh`。
- `[FRAME, HIGH]` Executors：`gpt-5.6-luna`，reasoning `xhigh`，3–5 路。
- `[FRAME, HIGH]` 每个 executor 只有互斥写范围；不得创建子 agent。
- `[FRAME, HIGH]` cheap tests/scripts 优先；明确失败先 Luna 修复。
- `[FRAME, HIGH]` 只有 evidence missing/conflict、scope overlap、retry exhausted 回 Sol。
- `[FRAME, HIGH]` 父 worktree 最终一次性接收 combined patch。
- `[FRAME, HIGH]` 不修改 §14.1 保护文件，不替代正式四源 Gate。

## Run 输入契约与安全闸门

- `[FRAME, HIGH]` `run` 必须带 workspace 内真实的 `--spec-ref`、对应 canonical `--matrix-ref`、至少一个存在于该 Matrix 的 `--matrix-edge`（例如 `M-001`）和至少一个非空全局 `--check`。规范化后的引用必须进入 Sol plan、每个 Luna task/repair、integration repair 和 Sol escalation Prompt；输入缺失、空值、越界、Matrix 不匹配或 edge 不存在立即 fail closed。
- `[FRAME, HIGH]` scope 必须为明确的工作区相对路径，并拒绝 §14.1 全部保护路径：`docs/governance/scoring/RUBRIC-*.md`、`docs/governance/STRUCTURAL-SCORING.md`、`docs/governance/scoring/ARBITER-PROTOCOL.md`、`.claude/agents/`、`.codex/agents/`、`.copilot/agents/`、`.claude/commands/spec-code-pipeline.md`、`.codex/skills/spec-code-pipeline/`、`.copilot/commands/spec-code-pipeline.md`、`.omc/state/outer-metrics/`、`.omx/state/outer-metrics/`、`.copilot/state/outer-metrics/`、`CONSTITUTION.md`；`.git` 及其子路径也不可声明。`.`、保护路径的祖先目录、通配符/glob 及其他能够覆盖保护集的宽 scope 也必须拒绝；`option=value` 右值中的绝对路径不得绕过校验。
- `[FRAME, HIGH]` 全局 check 使用安全 argv allowlist；pytest 插件/override、Go exec/tool、Node loader/setup 等危险执行 flag 必须拒绝。所有 cheap checks 通过 `prlimit + bwrap` 在无网络、clean-env、空根沙箱中执行；当前 worktree 与 `.git`/common-dir 均只读，只有有界 tmpfs 可写；沙箱或资源限制器不可用即 fail closed。
- `[FRAME, HIGH]` 模型调用前后检测新增 ignored 文件，仅当前 run 自有 `.omx/state/orchestration/<run_id>/` 制品可豁免；其他新增 ignored、检测报错或证据不完整均 fail closed。Luna 声明的 `changed_files` 必须与机械 diff 一致，否则按 evidence conflict 回 Sol。
- `[FRAME, HIGH]` Sol escalation 只接收失败/冲突摘要；通过任务只提供 patch hash receipt。运行 summary 记录 Sol/Luna/总 token 和未知 token 调用。当前版本不提供跨 run resume。
- `[FRAME, HIGH]` integration Luna repair 在全局 checks 后重新抓取 status、diff 和 scope；只有重新抓取无越界且 checks 全部通过时，才允许捕获 combined patch 并交给父 worktree 一次性应用。

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
