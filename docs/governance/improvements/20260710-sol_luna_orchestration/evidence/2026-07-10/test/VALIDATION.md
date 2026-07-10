# Sol/Luna 编排候选验证证据

- **日期**：2026-07-10 `[COMPUTED, HIGH]`
- **候选分支**：`feat/sol_luna_orchestration` `[COMPUTED, HIGH]`
- **最新 exact-model dogfood run ID**：`20260710T043240Z-ce0fd5a6` `[COMPUTED, HIGH]`
- **当前 revision 验证边界**：exact Sol/Luna 路由沿用 dogfood 证据；后续安全修复全部由无模型的真实 Git/sandbox 回归验证，未为重复审稿再支付模型调用 `[COMPUTED, HIGH]`

## 验收结论

| AC | 结果 | 证据 |
|----|------|------|
| AC-001 | PASS `[COMPUTED, HIGH]` | strict config 的 `config.load=ok`，加载模型为 `gpt-5.6-sol`；没有未知键错误 |
| AC-002 | PASS `[COMPUTED, HIGH]` | probe 返回 Sol=true、Luna=true、effort=`xhigh`、accepted=true |
| AC-003 | PASS `[COMPUTED, HIGH]` | 定向测试 269 passed；标准库 trace 为 88%；`py_compile` 通过 |
| AC-004 | PASS `[COMPUTED, HIGH]` | 回归测试证明 integration fail 时父 apply=0，pass 时父 apply=1 |
| AC-005 | PASS `[COMPUTED, HIGH]` | 回归测试证明 task 与 integration 的显式 fail 后均先调用第二次 Luna |
| AC-006 | PASS `[COMPUTED, HIGH]` | changed-file allowlist 检查无 §14.1 保护路径 |
| AC-007 | PASS `[COMPUTED, HIGH]` | 两轮 dogfood：1 Sol + 3 Luna 并行；明确 integration 失败由 Luna 修复后重跑，最终 combined patch 一次应用 |
| AC-008 | PASS `[COMPUTED, HIGH]` | `AGENTS.md` 与 `docs/workflow/README.md` 已记录入口和边界；`git diff --check` 通过 |

## 定向 cheap gates

```text
python3 -m pytest -q scripts/tests/test_sol_luna_orchestrator.py scripts/tests/test_sol_luna_orchestrator_coverage.py
269 passed in 5.32s

python3 -m py_compile scripts/sol_luna_orchestrator.py scripts/tests/test_sol_luna_orchestrator.py scripts/tests/test_sol_luna_orchestrator_coverage.py
exit 0

python3 -m trace --count --missing --summary --module pytest ...
scripts.sol_luna_orchestrator: 2405 executable lines, 88%

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

## Dogfood 升级闸门与返工路由

[COMPUTED, HIGH] run `20260710T041617Z-c13519d9` 中 T1/T3 通过，T2 产生写范围外 ignored coverage 制品；cheap gate 判定 `escalate_sol`，父 worktree apply 次数为零，证明证据不足路径 fail closed。

[COMPUTED, HIGH] run `20260710T043240Z-ce0fd5a6` 复用上一轮已验证补丁后，三个 task gate 均通过；integration 首轮出现 17 个确定性测试失败，编排器只调用 Luna integration repair，修复后 219 tests 和 `git diff --check` 通过，没有把明确失败送回 Sol。

[COMPUTED, HIGH] 一次独立 Luna/xhigh 复审在 stderr 报告 `tokens used = 97,509`；当前实现已从 stderr 解析该计数，并在 summary 汇总 `sol_tokens`、`luna_tokens`、`total_tokens` 与 `unknown_token_calls`。历史运行在解析修复前产生，因此旧日志仍为未知计量，未事后编造数字。

[COMPUTED, HIGH] Sol escalation 的 task 上下文现只包含失败/冲突任务摘要；通过任务缩为 ID、changed files 与 patch SHA-256 receipt。当前版本没有 `--resume-run`，跨 run patch 复用尚未自动化，后续 Beads 单独跟踪。

[COMPUTED, HIGH] 当前 revision 的最小 exact-model 重验 `20260710T052949Z-835cf4a6` 在 Sol plan 阶段收到 CLI 明确的 `usage limit`，未进入 Luna；该外部额度阻塞不构成 E2E PASS。该次运行还暴露“Sol 失败后再次调用 Sol”的无效成本，随后实现已改为分类 `usage_limit` 并直接 `blocked`，由六类 model-failure 单元回归验证；因额度尚未恢复，没有伪造修复后的模型实跑结果。

## 对抗性安全验收

[COMPUTED, HIGH] 真实临时 Git 仓回归覆盖：`RM` rename 双路径、rename source 名为 `?? decoy`、ignored baseline、字面反斜杠文件名、首尾空白拒绝、`.git`/nested `.git`、symlink Git alias、HEAD 未跟踪 Spec/Matrix、fenced ghost M-edge、Matrix→SPEC FR 闭合、task/integration 声明↔机械 diff 冲突。

[COMPUTED, HIGH] 真实 `prlimit + bwrap` fixture 使用空根文件系统；断言当前 worktree 与 Git metadata 只读、宿主 sibling 不落盘、`OPENAI_API_KEY`/stdin 不进入子进程、`/opt/binance/secrets/prod.env` 与 `/run/docker.sock` 不可见。允许的 `python3 -m pytest` 在同一 sandbox 返回 0。

[COMPUTED, HIGH] sandbox 资源证据为：RLIMIT_AS=4 GiB、RLIMIT_FSIZE=16 MiB、RLIMIT_NPROC=2048、RLIMIT_CPU=600 秒、tmpfs=512 MiB；父进程最多读取 2 MiB stdout/stderr，超出部分标记截断。

[COMPUTED, HIGH] 最终独立复审进一步确认：Cargo 仅暴露 `bin/registry/git` 且 `CARGO_HOME=/tmp/cargo-home`，不挂载宿主 credentials；Spec/Matrix 拒绝 symlink，并排除顶层、list、blockquote 的反引号/波浪线 fence、缩进 code 和 prose/comment ghost FR；invalid Sol plan 不二次调用 Sol；integration escalation 仅发送失败摘要和通过 task receipts。复审最后报告上述 blocker 已关闭。

## 仓库级回归与基线隔离

[COMPUTED, HIGH] `python3 -m pytest scripts/tests -q` 结果为 334 passed、1 failed。唯一失败是 `test_audit_status_full_mode_runs_clean_for_current_projection`，其输出为 README URL count 72、同步表 total 71。

[COMPUTED, HIGH] 同一测试在 main checkout、README 无本地 diff 时仍稳定失败，因此它是既有基线缺陷，不是本候选引入；后续 Beads 为 `ZoneCNH-ndnv`。

[COMPUTED, HIGH] outer-metrics 与目录化 Spec 布局不兼容的独立治理缺陷登记为 `ZoneCNH-4cs7`，未混入本候选改动。

[COMPUTED, HIGH] PR #1761 的 GitHub checks 持续处于 queued 且 runner_id=0；仓库可用 runner labels 与 workflow 请求的 `sre/foundation-l0/l1` 不匹配，独立 Beads 为 `ZoneCNH-nfx0`。该外部队列问题不被写成代码测试 PASS。

## 未声明事项

[COMPUTED, HIGH] 本次没有修改 outer metrics，也没有执行 §14 评分系统 A/B，因为 changed-file 检查证明本候选未触碰 §14.1 保护文件。

[INFERRED, MED] 该路由可能减少不必要的 Sol 二次审稿，但本次没有可靠的对照成本数据，因此不声明 token 或费用节省比例。
