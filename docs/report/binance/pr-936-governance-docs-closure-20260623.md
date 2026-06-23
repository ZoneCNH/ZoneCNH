# Binance PR #936 governance/docs closure audit — #925/#930/#931

- Date: 2026-06-23
- Scope: local governance/docs closure after PR #936 merge for GitHub issues #925/#930/#931.
- Source boundary: repo-local docs/search only; no external GitHub authority was used in this worker lane.
- Outcome: stale PR #910 projections are quarantined as historical, and the exact local docs patch set is recorded below.

## 1. File-level findings

| ID | File / local anchor | Stale projection or gap | Patch applied |
| --- | --- | --- | --- |
| F1 | `docs/report/binance/INDEX.md` closure table | Closure index ended at PR #910/#896 reports and had no post-PR #936 entry for #925/#930/#931. | Added this PR #936 closure audit to the index. |
| F2 | `docs/report/binance/issues-full-closure-20260623.md`, `goal-execution-plan-20260622.md`, and `iteration-plan-20260622.md` PR #910 projection notes | PR #910 reports read as full/current closure artifacts while their scope is #866~#896 against v3.1.0; residual FR-025~028 text no longer matches current module docs. | Marked the reports as historical PR #910 baselines, linked this audit, and annotated FR-025~028 residual rows as superseded by later module docs. |
| F3 | `module/binance/DATA-LIFECYCLE.md` §7 | §7 still says FR-025~028 are not folded into `SPEC.md` / `TRACEABILITY.md`, although current docs record v3.2.0 folds and v3.5.0 FR-029/030. | Added a post-PR #936 supersession note while preserving the discussion-draft provenance. |
| F4 | repo-wide search for `#925`, `#930`, `#931`, `#936`, `PR #936` | No authoritative local issue/PR anchors exist for #925/#930/#931/#936. | Kept closure language scoped to repo-local governance/docs evidence; external GitHub issue/PR metadata remains an explicit validation dependency. |

## 2. Current local projection evidence

- `module/binance/CHANGELOG.md` v3.2.0 records FR-025~FR-028 folded into SPEC/TRACEABILITY/NAMING.
- `module/binance/CHANGELOG.md` v3.5.0 records FR-029 Data Quality & Freshness SLA and FR-030 Options Chain Raw Field Pass-through.
- `module/binance/TRACEABILITY.md` v3.5.0 lists FR-025~FR-030, AC-087~AC-104, and TC-043~TC-049 as Pending runtime capabilities.
- `module/binance/server/SPEC.md` contains FR-025~FR-028 sections.
- `module/binance/SPEC.md` contains v3.5.0 freshness SLA references for FR-029.

## 3. Exact minimal patch set

1. `docs/report/binance/INDEX.md`
   - Add `pr-936-governance-docs-closure-20260623.md` to closure/audit reports.
   - Update the DATA-LIFECYCLE index note so §7 is not presented as current pending work.
2. `docs/report/binance/issues-full-closure-20260623.md`
   - Add a post-PR #936 note that PR #910 closes only #866~#896.
   - Annotate §3 residual actions and §5 known gaps as PR #910 historical projections superseded by later module docs.
3. `docs/report/binance/goal-execution-plan-20260622.md` and `docs/report/binance/iteration-plan-20260622.md`
   - Annotate the top closure notes so FR-025~FR-028 "not folded" language is historical, not current backlog.
4. `module/binance/DATA-LIFECYCLE.md`
   - Add a supersession note to §7 documenting that FR-025~FR-028 are now folded and FR-029/030 are present.
5. `docs/report/binance/pr-936-governance-docs-closure-20260623.md`
   - Record the findings, patch set, validation commands, and remaining external evidence dependency.

## 4. Validation commands

```bash
rg -n "#925|#930|#931|#936|PR #936" . --glob '!node_modules' --glob '!.git' --glob '!.omx/logs/**'
rg -n "PR #936|#925|#930|#931|FR-025|FR-029|FR-030|historical|supersession" docs/report/binance module/binance/DATA-LIFECYCLE.md module/binance/CHANGELOG.md module/binance/TRACEABILITY.md
bash scripts/check-binance-docs.sh
python3 scripts/audit-status.py
python3 - <<'PYCHECK'
from pathlib import Path
for path in [
    'docs/report/binance/pr-936-governance-docs-closure-20260623.md',
    'docs/report/binance/INDEX.md',
    'docs/report/binance/issues-full-closure-20260623.md',
    'module/binance/DATA-LIFECYCLE.md',
]:
    assert Path(path).exists(), path
PYCHECK
```

## 5. Remaining risk

- External GitHub metadata for PR #936 and issues #925/#930/#931 is not present in the local repo. Do not claim release/issue closure from this local patch alone; use `gh pr view 936` / `gh issue view 925 930 931` or the leader-owned audit source before final external closure.
- FR-025~FR-030 remain `Pending` runtime capabilities in `TRACEABILITY.md`; this audit only fixes governance/docs projection drift.
