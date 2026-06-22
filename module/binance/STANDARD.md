# module/binance STANDARD.md — 模块标准入口

- Doc-Version: v0.1.0
- Last-Updated: 2026-06-23
- Issue: #871
- Scope: `module/binance/` governance entrypoint + `github.com/ZoneCNH/binance` runtime evidence pointers

> 本文件是薄入口（thin index），只声明权威顺序与必查入口；具体规则仍以被引用文档为准，避免复制粘贴导致二次漂移。

---

## 1. Authority order

当文档、task、runtime 证据互相冲突时，按以下顺序裁决：

1. Repository `CONSTITUTION.md`（尤其 §20 证据与验收纪律）
2. `module/binance/STANDARD.md`（本文，入口与优先级）
3. `module/binance/{RULES,SPEC,BOUNDARY-GATES,NAMING,ACCEPTANCE,TRACEABILITY}.md`
4. `module/binance/{client,server}/SPEC.md` 与 `{client,server}/TRACEABILITY.md`
5. `module/binance/{client,server}/tasks/**`、`docs/report/binance/**` 与临时审计报告
6. Runtime 仓 `github.com/ZoneCNH/binance` 的 fresh command output（用于证明实现状态，不替代规格权威）

---

## 2. Mandatory entrypoints

| Concern | Mandatory source | Notes |
|---|---|---|
| Naming / products / event types | `module/binance/NAMING.md` §1-§11 | 历史别名只允许出现在 RULES 例外清单与治理报告中。 |
| Boundary gates | `module/binance/BOUNDARY-GATES.md` + `/home/binance/scripts/boundary-gates.sh` | #869 runtime 证据必须记录 fresh command output。 |
| Documentation sync | `module/binance/RULES.md` R3 / R6 / R9 | 版本、状态、文档存在性必须同步。 |
| Acceptance | `module/binance/ACCEPTANCE.md` | 验收口径以 acceptance + traceability 双向一致为准。 |
| Evidence | `CONSTITUTION.md` §20 + runtime command output | 文档断言不能替代运行证据。 |
| Forbidden patterns | `module/binance/RULES.md` R1 / R2 / R5 + `module/binance/SPEC.md` BR-001 | 包括 legacy name、跨边界 import、未归档旧 task。 |

---

## 3. Required local checks

Run the narrowest check set that can prove the claim being made:

```bash
git diff --check
test -f module/binance/STANDARD.md
rg -n "#869|#871|#893|#894|#895|#896" module/binance docs/report/binance
```

When present, the repo-local doc gate is authoritative for documentation checks:

```bash
scripts/check-binance-docs.sh
```

As of 2026-06-23 in this worker worktree, `scripts/check-binance-docs.sh` is absent and remains in the P0/check-script ownership slice (#870). Do not mark #871 fully integrated until that gate includes this file or an equivalent check.

For #869 runtime evidence, run from `/home/binance` and capture exit code + output:

```bash
./scripts/boundary-gates.sh
go test ./...
go test ./... -race -count=1
go vet ./...
golangci-lint run
```

A clean runtime repository is part of the evidence chain. Untracked files, local changes, missing lint tool, or omitted smoke/e2e commands must be recorded as gaps instead of treated as PASS.

---

## 4. Closure guardrails for open governance issues

- #869 is runtime-evidence gated. It cannot be closed by docs-only edits.
- #871 is satisfied only when this thin entrance exists, `RULES.md` R9 knows about it, and the doc check script covers it.
- #893-#895 are migration/compression work items; reports may document current state, but closure requires the named document moves/compressions.
- #896 requires a commit coverage matrix plus authoritative PR/head metadata before “no omitted change reaches main” can be claimed.

---

## 5. Change history

| Date | Version | Change | Author |
|---|---|---|---|
| 2026-06-23 | v0.1.0 | Established thin standard entrypoint for #871 and recorded #869 evidence guardrails. | ZoneCNH |
