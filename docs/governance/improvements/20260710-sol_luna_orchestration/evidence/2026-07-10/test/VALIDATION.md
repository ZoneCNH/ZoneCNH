# Sol/Luna 编排候选验证证据

- **日期**：2026-07-10 `[COMPUTED, HIGH]`
- **候选分支**：`feat/sol_luna_orchestration` `[COMPUTED, HIGH]`
- **最终 Synthetic run ID**：`20260710T035455Z-453f9c66` `[COMPUTED, HIGH]`

## 验收结论

| AC | 结果 | 证据 |
|----|------|------|
| AC-001 | PASS `[COMPUTED, HIGH]` | strict config 的 `config.load=ok`，加载模型为 `gpt-5.6-sol`；没有未知键错误 |
| AC-002 | PASS `[COMPUTED, HIGH]` | probe 返回 Sol=true、Luna=true、effort=`xhigh`、accepted=true |
| AC-003 | PASS `[COMPUTED, HIGH]` | 定向测试 87 passed；`py_compile` 通过 |
| AC-004 | PASS `[COMPUTED, HIGH]` | 回归测试证明 integration fail 时父 apply=0，pass 时父 apply=1 |
| AC-005 | PASS `[COMPUTED, HIGH]` | 回归测试证明 task 与 integration 的显式 fail 后均先调用第二次 Luna |
| AC-006 | PASS `[COMPUTED, HIGH]` | changed-file allowlist 检查无 §14.1 保护路径 |
| AC-007 | PASS `[COMPUTED, HIGH]` | synthetic E2E：1 Sol + 3 Luna、cheap gate accept、global check pass、combined patch 应用成功 |
| AC-008 | PASS `[COMPUTED, HIGH]` | `AGENTS.md` 与 `docs/workflow/README.md` 已记录入口和边界；`git diff --check` 通过 |

## 定向 cheap gates

```text
python3 -m pytest scripts/tests/test_sol_luna_orchestrator.py -q
87 passed in 0.12s

python3 -m py_compile scripts/sol_luna_orchestrator.py scripts/tests/test_sol_luna_orchestrator.py
exit 0

git diff --check
exit 0

python3 scripts/sol_luna_orchestrator.py probe
{"accepted": true, "command": "probe", "effort": "xhigh", "models": {"gpt-5.6-luna": true, "gpt-5.6-sol": true}, "returncode": 0, "stderr": ""}
```

## Strict config

[COMPUTED, HIGH] `codex --strict-config doctor --json` 的配置检查为 `ok`，并显示 `model: gpt-5.6-sol`。

[COMPUTED, HIGH] Doctor 总状态为 `fail` 的唯一失败项是非交互环境 `TERM=dumb`；auth、config、MCP、网络、runtime 和 thread inventory 均为 `ok`。该终端能力失败不影响本候选的配置解析结论。

[COMPUTED, HIGH] 一次未传 `-m` 或 `-c model_reasoning_effort` 的 `codex exec` 配置探针返回 0，其启动头显示 `model: gpt-5.6-sol`、`reasoning effort: xhigh`，最终输出 `OK`。启动时同时出现既有 shell snapshot 语法告警，但没有改变模型/档位或退出码。

## 真实 Sol + 3 Luna smoke

[COMPUTED, HIGH] 最终 smoke 在 `/tmp/sol_luna_smoke.1Ied0o` 的独立 `feat/smoke` worktree 运行，不读写 ZoneCNH 候选 worktree。

[COMPUTED, HIGH] 四次模型调用均返回 0；三个 Luna 调用的开始时间相差 1.707 毫秒，构成实际并行启动证据：

```jsonl
{"kind":"sol-plan","model":"gpt-5.6-sol","effort":"xhigh","returncode":0,"started_at":"2026-07-10T03:54:55.079488+00:00"}
{"kind":"luna-smoke2-delta-attempt-1","model":"gpt-5.6-luna","effort":"xhigh","returncode":0,"started_at":"2026-07-10T03:55:04.966382+00:00"}
{"kind":"luna-smoke2-zeta-attempt-1","model":"gpt-5.6-luna","effort":"xhigh","returncode":0,"started_at":"2026-07-10T03:55:04.967606+00:00"}
{"kind":"luna-smoke2-epsilon-attempt-1","model":"gpt-5.6-luna","effort":"xhigh","returncode":0,"started_at":"2026-07-10T03:55:04.965899+00:00"}
```

[COMPUTED, HIGH] smoke summary 的 `cheap_gate.verdict=accept`，task checks 与 global `git diff --check` 全部返回 0，integration 在首次全局检查后直接生成 combined patch，没有调用 Sol escalation。

[COMPUTED, HIGH] 最终 run 相对其 clean HEAD 只新增 `smoke2/delta.txt`、`smoke2/epsilon.txt`、`smoke2/zeta.txt`；逐字节内容分别为 `delta\n`、`epsilon\n`、`zeta\n`。

[COMPUTED, HIGH] cleanup 记录显示 integration 与三个 task worktree 的 `worktree remove --force` 全部返回 0，`worktree prune --dry-run` 返回 0；最终 worktree list 只剩 primary 与 `feat/smoke`。

## 仓库级回归与基线隔离

[COMPUTED, HIGH] `python3 -m pytest scripts/tests -q` 结果为 152 passed、1 failed。唯一失败是 `test_audit_status_full_mode_runs_clean_for_current_projection`，其输出为 README URL count 72、同步表 total 71。

[COMPUTED, HIGH] 同一测试在 main checkout、README 无本地 diff 时仍稳定失败，因此它是既有基线缺陷，不是本候选引入；后续 Beads 为 `ZoneCNH-ndnv`。

[COMPUTED, HIGH] outer-metrics 与目录化 Spec 布局不兼容的独立治理缺陷登记为 `ZoneCNH-4cs7`，未混入本候选改动。

## 未声明事项

[COMPUTED, HIGH] 本次没有修改 outer metrics，也没有执行 §14 评分系统 A/B，因为 changed-file 检查证明本候选未触碰 §14.1 保护文件。

[INFERRED, MED] 该路由可能减少不必要的 Sol 二次审稿，但本次没有可靠的对照成本数据，因此不声明 token 或费用节省比例。
