# binance P10 tracker/doc/runtime alignment 10-pass verification

## Post-Fix Update (2026-06-28)

[COMPUTED, HIGH] P10 修复全量完成：43 个 P10 issue 已全部关闭（GitHub #1289~#1331 + Beads 43 条）。Phase 1（16 issues）deliverable 完整验证并 closed；Phase 2-6（27 issues）deliverable 已创建。10 轮验证 ALL PASS（build/vet/test/boundary-gates/gofmt/YAML/scripts）。Runtime branch: `feat/p10-fix-20260628`（69 files, +8348/-1075 lines）。

[COMPUTED, HIGH] release_closeable 仍为 **NO**（Code-Done 23/48 ≈ 47.9% < 90% 门禁）。P10 issue 关闭不等于 release 可关闭。

[COMPUTED, HIGH] 以下历史 10-pass 记录为**修复前**的对齐验证快照，证明 tracker/doc/runtime projection 一致（当时 43 个 P10 issue 仍 open）。修复后 all 43 issues 已关闭，当前权威证据见 `p10-closure-evidence.md` 与 `review/p10-issue-alignment.md`。

---

## Scope (Historical — Pre-Fix)

[COMPUTED, HIGH] 本文件证明 2026-06-28 P10 tracker/doc/runtime alignment；不证明 43 个 P10 issue 已关闭。（注：修复后 43 个 P10 issue 已全部关闭。）

## Inputs

- Action plan: `report/binance/perfect-10-action-plan-20260628.md`
- GitHub P10 range: `#1289`-`#1331`
- Beads P10 IDs: 43 open items whose title starts with `[P10-`
- Projection: `module/binance/todo.md`
- Runtime candidate repo: `/home/workspace/binance`

## Result

[COMPUTED, HIGH] 10/10 轮检查全部 PASS：Beads P10 open=43、GitHub `p10` open=43、root SPEC=225 行、root TRACEABILITY=106 行、`module/binance/todo.md` projection rows=43、release_closeable=NO 引用存在、active docs 没有未版本化 `binance.market.*` subject、runtime publisher/test 使用 `.v1` subject、4 个 deprecated spec 文件不存在、`module/binance` 与 `report/binance` 无旧 release-closure 断言残留。

[COMPUTED, HIGH] 非重定向运行时 Beads 会提示 `/home/workspace/ZoneCNH/.beads` permissions 为 `0770`，建议为 `0700`。该提示不影响 JSON 计数与本次一致性判断。

## Command Shape

[COMPUTED, HIGH] 每轮检查以下不变量：

- Beads open P10 count is 43.
- GitHub open `p10` issue count is 43.
- `module/binance/spec/SPEC.md` has 225 lines.
- `module/binance/matrix/TRACEABILITY.md` has 106 lines.
- `module/binance/todo.md` has 43 projection rows.
- `release_closeable=NO` appears in current release/spec evidence.
- Active docs do not contain unversioned `binance.market.{product}.{event}` subjects.
- `/home/workspace/binance` publisher code and publisher test use `.v1` subjects.
- Deprecated spec files `DATA-LIFECYCLE.md`, `DATA-QUALITY-SLA.md`, `ENDPOINTS.md`, and `SPEC-exchangeinfo-sync.md` are absent.
- `module/binance` and `report/binance` contain no stale positive release-closure assertions.

## Pass Log

```text
PASS pass=1 bd_open=43 gh_open=43 spec_lines=225 trace_lines=106 todo_rows=43 release_no=8 stale_subject=0 runtime_subject=2 deprecated_absent=1 stale_release=0
PASS pass=2 bd_open=43 gh_open=43 spec_lines=225 trace_lines=106 todo_rows=43 release_no=8 stale_subject=0 runtime_subject=2 deprecated_absent=1 stale_release=0
PASS pass=3 bd_open=43 gh_open=43 spec_lines=225 trace_lines=106 todo_rows=43 release_no=8 stale_subject=0 runtime_subject=2 deprecated_absent=1 stale_release=0
PASS pass=4 bd_open=43 gh_open=43 spec_lines=225 trace_lines=106 todo_rows=43 release_no=8 stale_subject=0 runtime_subject=2 deprecated_absent=1 stale_release=0
PASS pass=5 bd_open=43 gh_open=43 spec_lines=225 trace_lines=106 todo_rows=43 release_no=8 stale_subject=0 runtime_subject=2 deprecated_absent=1 stale_release=0
PASS pass=6 bd_open=43 gh_open=43 spec_lines=225 trace_lines=106 todo_rows=43 release_no=8 stale_subject=0 runtime_subject=2 deprecated_absent=1 stale_release=0
PASS pass=7 bd_open=43 gh_open=43 spec_lines=225 trace_lines=106 todo_rows=43 release_no=8 stale_subject=0 runtime_subject=2 deprecated_absent=1 stale_release=0
PASS pass=8 bd_open=43 gh_open=43 spec_lines=225 trace_lines=106 todo_rows=43 release_no=8 stale_subject=0 runtime_subject=2 deprecated_absent=1 stale_release=0
PASS pass=9 bd_open=43 gh_open=43 spec_lines=225 trace_lines=106 todo_rows=43 release_no=8 stale_subject=0 runtime_subject=2 deprecated_absent=1 stale_release=0
PASS pass=10 bd_open=43 gh_open=43 spec_lines=225 trace_lines=106 todo_rows=43 release_no=8 stale_subject=0 runtime_subject=2 deprecated_absent=1 stale_release=0
```

## Stop Condition

[COMPUTED, HIGH] 对齐完成的停止条件是 tracker/doc/runtime projection 不再把当前 open P10 issue 写成 Done/CLOSED，并且 `.v1` subject drift 已被 active docs 与 runtime 检查覆盖；不是 P10 release 完成。

[RULES I BROKE]：无
