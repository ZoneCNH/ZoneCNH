# goalctl 完整规格（Spec）

- Spec ID: `SPEC-goalctl-v1`
- Status: Draft for review
- Date: 2026-06-09
- Owner: OMX team task `home-zonecnh-worktree-6c1b0874/task-3`
- Scope: define the complete `goalctl` command, validation, reporting, evidence, and acceptance contract from `docs/goal` and `.config/goal`.
- Non-scope: this document does not change `docs/goal` authority rules and does not implement a runtime binary.

## 1. Purpose and success metrics

`goalctl` is the CLI adapter for the Goal control plane. It reads Goal authority documents and projected config, validates drift, reports traceability, and prepares machine-readable evidence for operators and CI.

Success is measurable by these metrics:

1. 100% of normative `goalctl` commands, data fields, and error semantics in this spec cite an authoritative source path in Section 2.
2. 100% of acceptance criteria in Section 12 map to at least one `REQ-SPEC-goalctl-v1-*` requirement.
3. Matrix coverage checks use the configured `95%` threshold from `.config/goal/schema/rules.yaml`.
4. All Goal state checks use the four-axis model: `pipeline_state`, `current_phase`, `phase_status`, and `workflow_step`.

## 2. Source map and authority hierarchy

`goalctl` MUST treat `docs/goal` as the system of record and `.config/goal` as a projected control-plane/config surface. It MUST NOT invent new state enums, Gate IDs, Registry files, Matrix relations, Evidence IDs, or authority boundaries.

| Contract area | Authoritative source | Projection / check source | `goalctl` obligation |
| --- | --- | --- | --- |
| Authority hierarchy | `docs/goal/00-authority-map.md:3-10`, `docs/goal/00-authority-map.md:45-61` | `.config/goal/README.md:44-54` | Report any value defined in projection but not sourced from `docs/goal` as authority drift. |
| Four-axis state | `docs/goal/00-authority-map.md:30-39`, `docs/goal/03-pipeline.md:37-46` | `.config/goal/pipeline/state.yaml`, `.config/goal/schema/rules.yaml:200-207` | Validate all four axes independently; never collapse them into one `status`. |
| Pipeline and Matrix traceability | `docs/goal/03-pipeline.md:31`, `docs/goal/03-pipeline.md:87-118` | `.config/goal/schema/rules.yaml:101-150` | Check the chain Goal → Spec → Requirement → AC → Task → Prompt → Code → Test → Evidence. |
| Gate IDs and semantics | `docs/goal/04-gates.md:5-6`, `docs/goal/04-gates.md:33-48`, `docs/goal/04-gates.md:80-96` | `.config/goal/schema/rules.yaml:174-190` | Validate G0-G11, blocking semantics, and `PASS_WITH_RISK` vs `BLOCKED` waiver mapping. |
| Goal object | `docs/goal/02-goal-standard.md:34-45`, `docs/goal/02-goal-standard.md:51-100`, `docs/goal/02-goal-standard.md:134-186` | `.config/goal/schema/rules.yaml:34-43` | Validate minimum Goal fields and ID patterns; flag unresolved alias drift. |
| Registry boundary | `docs/goal/15-registry.md:7-23`, `docs/goal/15-registry.md:108-110` | `.config/goal/README.md:36-40`, `.config/goal/schema/rules.yaml:50-57` | Treat only six YAML files as Registry; treat schema/matrix/gates/pipeline/evidence/prompts as sidecars. |
| Evidence protocol | `docs/goal/13-runtime-engine.md:115-123`, `docs/goal/20-metrics-evidence.md:9-12`, `docs/goal/20-metrics-evidence.md:111-123` | `.config/goal/schema/rules.yaml:153-168` | Enforce Evidence ID, Task ID, Test ID, Goal ID, reproducibility, and No Evidence No Done. |
| Runtime/config boundary | `.config/goal/README.md:3-6`, `.config/goal/README.md:60-72`, `.config/goal/README.md:80-107` | .config/goal ignore rules | Prevent credentials, private endpoints, account IDs, trading config, local paths, cache/log/temp/lock artifacts. |
| Known standard gaps | `docs/goal/24-standard-unification-analysis.md:17-25`, `docs/goal/24-standard-unification-analysis.md:50-168`, `docs/goal/24-standard-unification-analysis.md:215-223` | N/A | Report current schema/term/status drift explicitly; do not silently normalize it away. |

Authority order:

1. docs/goal authority files authoritative SSOT documents.
2. `.config/goal/schema/rules.yaml` and .config/goal sidecar directories as projections/checkable sidecars.
3. `.omx/` and local runtime/cache/log/temp files as non-authoritative execution state.

## 3. Canonical terms and migration aliases

`goalctl` MUST expose canonical names in machine-readable output. Aliases MAY be accepted for reporting and migration warnings only.

| Canonical term | Accepted aliases for detection | Rule |
| --- | --- | --- |
| `goal.id` | `goal_id`, `goalId`, YAML `id` under a Goal object | Canonical output MUST be `goal.id`; invalid pattern emits `GOALCTL-ID-001`. |
| `goal.name` | `title`, YAML `name` | Output SHOULD keep `goal.name`; conflicting `name`/`title` emits `GOALCTL-TERM-001`. |
| `goal.objective` | `north_star`, `objective` | `objective` is canonical for Goal spec output; `north_star` is a drift alias. |
| `goal.success_metrics` | `success_criteria`, `metric_targets` | Metrics must stay measurable; criteria belong to AC objects. |
| `lifecycle_status` | plain `status` on Goal lifecycle records | Lifecycle status is separate from pipeline/gate/metric status. |
| `pipeline_state` | legacy execution/control tokens | Must use Pipeline enum from `03-pipeline`; legacy one-field states are illegal. |
| `current_phase` | `phase` | Must be validated as a separate axis. |
| `phase_status` | `phaseState` | Must be validated as a separate axis. |
| `workflow_step` | `step`, `current_step` | Must not reuse `pipeline_state` enum names. |
| `gate_result` | `gate_status`, `status` in Gate context | `WAIVED` is not a final Gate result; map to `PASS_WITH_RISK` or `BLOCKED`. |
| `metric_conclusion` | `metric_status` | Metric conclusion must not redefine Gate or Pipeline statuses. |

Known drift in `docs/goal/24-standard-unification-analysis.md` is a validation target for `goalctl doctor`; it is not a license to redefine authority in this spec.

## 4. CLI surface

All commands support `--repo-root <path>` with default current working directory, `--json`, and deterministic exit codes. Human output MAY be localized, but JSON field names MUST remain stable.

### 4.1 `goalctl status`

Usage:

```bash
goalctl status [--goal GOAL-ID] [--json]
```

Behavior:

- Reads `.config/goal/pipeline/state.yaml` and the matching Goal/Matrix/Evidence sidecars.
- Prints four-axis state: `pipeline_state`, `current_phase`, `phase_status`, `workflow_step`.
- Reports stale or missing projection files as warnings unless `--strict` is supplied through CI wrapper.

### 4.2 `goalctl validate`

Usage:

```bash
goalctl validate [--all|--registry|--matrix|--gates|--pipeline|--evidence|--references] [--strict] [--json]
```

Behavior:

- `--references`: validates every source path/reference used by specs and sidecars.
- `--registry`: validates the six Registry files only.
- `--matrix`: validates Matrix schema, relation enum, statuses, required fields, and 95% threshold.
- `--gates`: validates G0-G11, order, blocking semantics, and waiver mapping.
- `--pipeline`: validates four-axis state fields and legal transitions.
- `--evidence`: validates Evidence ID, path, required fields, status, and reproducibility.
- `--all`: runs every validator and aggregates failures.

### 4.3 `goalctl registry`

Usage:

```bash
goalctl registry list [--json]
goalctl registry get --type goals|specs|features|issues|tasks|agents --id ID [--json]
goalctl registry lint [--json]
```

Rules:

- Registry scope is limited to the six YAML files listed by `.config/goal/README.md` and `.config/goal/schema/rules.yaml`.
- Pipeline, Gate, Matrix, Evidence, schema, and prompt files are sidecars, not Registry members.
- Exceptional Issue statuses reuse Pipeline exceptional states; Registry cannot define local exceptional states.

### 4.4 `goalctl matrix`

Usage:

```bash
goalctl matrix check [--goal GOAL-ID] [--min-coverage 95] [--json]
goalctl matrix trace --goal GOAL-ID [--json]
```

Rules:

- Validates `source_id`, `target_id`, `relation`, `status`, `evidence_id`, `gate_id`, `owner`, and `updated_at`.
- Valid relations are sourced from `.config/goal/schema/rules.yaml`.
- Trace command must render Goal → Spec → Requirement → AC → Task → Prompt → Code → Test → Evidence.
- Missing links, stale links, and drifted links must be reported as separate findings.

### 4.5 `goalctl gate`

Usage:

```bash
goalctl gate list [--json]
goalctl gate check --gate G0|G1|G2|G3|G4|G5|G6|G7|G8|G9|G10|G11 [--goal GOAL-ID] [--json]
```

Rules:

- Valid Gate IDs are exactly G0 through G11.
- G2 Spec Gate must verify completeness, testability, normal paths, error paths, boundary paths, security, performance, and non-goals.
- `WAIVED` is an input policy/decision note, not a final Gate result. Final JSON must use `PASS`, `PASS_WITH_RISK`, or `BLOCKED` as applicable.

### 4.6 `goalctl pipeline`

Usage:

```bash
goalctl pipeline get --goal GOAL-ID [--json]
goalctl pipeline transition --goal GOAL-ID \
  --pipeline-state STATE \
  --current-phase PHASE \
  --phase-status STATUS \
  --workflow-step STEP \
  [--json]
```

Rules:

- Transition proposals must be validated before write.
- `workflow_step` must not use `pipeline_state` enum values.
- Legacy single-field `status` cannot be accepted as a Pipeline transition request.
- Failed transition validation must be non-destructive.

### 4.7 `goalctl evidence`

Usage:

```bash
goalctl evidence verify --task TASK-ID --test TEST-ID --goal GOAL-ID [--json]
goalctl evidence collect --task TASK-ID --test TEST-ID --goal GOAL-ID --from PATH [--json]
```

Rules:

- `verify` checks Evidence ID, Task ID, Test ID, Goal ID, status, reproducibility, and trace link.
- `collect` must not store credentials, account IDs, private endpoints, trading config, or local personal paths.
- Evidence is required before Done: if evidence is absent, emit `GOALCTL-EVID-001` and return non-zero.

### 4.8 `goalctl doctor`

Usage:

```bash
goalctl doctor [--json]
```

Behavior:

- Runs reference, authority, projection, Registry, Matrix, Gate, Pipeline, Evidence, and config-boundary checks.
- Reports standard gaps from `docs/goal/24-standard-unification-analysis.md` as known drift until the SSOT repair package is applied.

### 4.9 `goalctl report acceptance`

Usage:

```bash
goalctl report acceptance --spec SPEC-goalctl-v1 [--json]
```

Behavior:

- Emits the Section 12 acceptance checklist with pass/fail/blocked status.
- Includes the validation command, timestamp, input file, and evidence references for every checklist item.

## 5. Configuration and runtime model

`goalctl` MUST respect these write boundaries:

1. Read docs/goal authority files as authority; do not mutate authority files during validation/report commands.
2. Read `.config/goal/schema/rules.yaml` as the auditable projection of rules.
3. Read/write only permitted `.config/goal` sidecar files when a command explicitly performs a checked update.
4. Treat `.omx`, local caches, logs, temp files, and lock files as runtime artifacts, never as authority.
5. Reject or redact credentials, credential keys, account IDs, private endpoints, trading configuration, and local personal paths in committed `.config/goal` content.

Boundary and error handling:

- Missing `.config/goal` projection: warning in audit mode; error in strict mode.
- Projection defines values absent from `docs/goal`: authority drift error.
- `docs/goal` source changed but projection not synchronized: sync drift warning in audit mode; error in strict mode.
- Runtime cache/log/temp file present under committed config paths: config-boundary error.

## 6. Data contracts

### 6.1 IDs

`goalctl` MUST use regex patterns from `.config/goal/schema/rules.yaml` for Goal and Evidence IDs. Invalid IDs emit `GOALCTL-ID-001`.

### 6.2 Registry

The Registry consists only of:

1. `goals.yaml`
2. `specs.yaml`
3. `features.yaml`
4. `issues.yaml`
5. `tasks.yaml`
6. `agents.yaml`

No command may add a seventh Registry file without an authority update in `docs/goal/15-registry.md` and synchronized projection.

### 6.3 Matrix

A Matrix row MUST include:

- `source_id`
- `target_id`
- `relation`
- `status`
- `evidence_id`
- `gate_id`
- `owner`
- `updated_at`

The default coverage threshold is 95%. Boundary cases include missing edge, duplicate edge, unsupported relation, stale link, drifted link, and evidence-free verified status.

### 6.4 Gate

Gate IDs are `G0` through `G11`. Gate output MUST include:

- `gate_id`
- `goal_id` when applicable
- `result`
- `blocking`
- `evidence`
- `risks`
- `checked_at`

### 6.5 Pipeline state

Pipeline output MUST include the four axes:

- `pipeline_state`
- `current_phase`
- `phase_status`
- `workflow_step`

A plain `status` field MAY appear only as a lifecycle status outside Pipeline state. `workflow_step` names MUST NOT equal `pipeline_state` enum names.

### 6.6 Evidence

Evidence output MUST include:

- `evidence_id`
- `task_id`
- `test_id`
- `goal_id`
- `status`
- `reproduce_command`
- `artifact_path`
- `created_at`

No Evidence No Done is mandatory: a Done/Verified claim without linked evidence is invalid.

## 7. JSON output contract

All JSON commands MUST return this top-level shape:

```json
{
  "tool": "goalctl",
  "command": "validate",
  "repo_root": "/repo",
  "rules_version": "from .config/goal/schema/rules.yaml when available",
  "inputs": [],
  "checks": [],
  "result": "pass|warn|fail|blocked",
  "errors": [],
  "warnings": [],
  "evidence": [],
  "generated_at": "RFC3339 timestamp",
  "exit_code": 0
}
```

Error entries MUST include:

```json
{
  "code": "GOALCTL-PIPE-001",
  "severity": "error|warning|info",
  "message": "human-readable summary",
  "source": "path:line-range when known",
  "expected": "contract expected by authority",
  "actual": "observed value",
  "remediation": "specific next action"
}
```

## 8. Error model

| Code | Severity | Meaning | Boundary / edge case |
| --- | --- | --- | --- |
| `GOALCTL-SSOT-001` | error | Projection/config defines authority not present in `docs/goal`. | `.config/goal` creates new enum, Gate ID, or Registry file. |
| `GOALCTL-REF-001` | error | Cited source path or line anchor is missing/stale. | A spec references a deleted `docs/goal` file. |
| `GOALCTL-ID-001` | error | ID does not match the configured pattern. | `goalId` alias has unsupported casing or prefix. |
| `GOALCTL-TERM-001` | warning/error | Alias conflicts with canonical term. | Both `name` and `title` exist with different values. |
| `GOALCTL-REG-001` | error | Registry shape violates six-file boundary. | Seventh Registry YAML or sidecar treated as Registry. |
| `GOALCTL-MATRIX-001` | error | Matrix schema, relation, status, or coverage is invalid. | Coverage below 95%, stale link, missing evidence edge. |
| `GOALCTL-GATE-001` | error | Gate ID/status/waiver semantics are invalid. | Final result is `WAIVED` instead of `PASS_WITH_RISK` or `BLOCKED`. |
| `GOALCTL-PIPE-001` | error | Pipeline four-axis state or transition is invalid. | `workflow_step` reuses a `pipeline_state` value. |
| `GOALCTL-EVID-001` | error | Evidence ID/path/required fields/reproducibility invalid. | Done claim has no linked Evidence ID. |
| `GOALCTL-SECRET-001` | error | Committed config/evidence contains prohibited secret/local data. | API key, account ID, private endpoint, trading config, local personal path. |

## 9. Verification plan

Typecheck/build:

- `test ! -f tsconfig.json && test ! -f package.json && echo "PASS: no TypeScript project/typecheck equivalent in docs-only worktree"`

Diagnostics and tests:

- `bash docs/goal/tools/lint-goal.sh docs/spec/goalctl-spec.md`
- `bash docs/goal/tools/self-test.sh`
- `python3 docs/goal/tools/goal-validate.py --root . --mode audit --format json`
- `python3 docs/goal/tools/rule-drift-check.py --root . --quiet`
- Custom Python verifier over `docs/spec/goalctl-spec.md`.

Runtime E2E note:

- A `goalctl` binary is not present in this repository at this task stage. End-to-end execution for this task is therefore spec-level: the verifier proves that the command surface, JSON contract, error model, data contracts, and acceptance checklist required for a future implementation are present and source-backed.

## 10. Reference consistency checklist

- [ ] Every source path in Section 2 exists.
- [ ] All state terms use four-axis Pipeline naming.
- [ ] Gate IDs are exactly G0-G11.
- [ ] `WAIVED` is not documented as a final Gate result.
- [ ] Registry contains exactly six YAML files.
- [ ] Matrix relations/status/required fields are sourced from `.config/goal/schema/rules.yaml`.
- [ ] Evidence fields include Evidence ID, Task ID, Test ID, and Goal ID.
- [ ] `.config/goal` boundary excludes credentials, account IDs, private endpoints, trading config, local personal paths, cache, logs, temp, and lock artifacts.
- [ ] Known standard gaps are referenced through `docs/goal/24-standard-unification-analysis.md`.
- [ ] The trace chain Goal → Spec → Requirement → AC → Task → Prompt → Code → Test → Evidence appears in CLI and acceptance requirements.

## 11. Acceptance checklist

| Checklist ID | Required evidence | Status rule |
| --- | --- | --- |
| `CHECK-SPEC-goalctl-v1-001` | `docs/spec/goalctl-spec.md` exists. | PASS only if file exists. |
| `CHECK-SPEC-goalctl-v1-002` | `git diff --name-only` contains only `docs/spec/goalctl-spec.md` before commit. | PASS only if no `docs/goal` files changed. |
| `CHECK-SPEC-goalctl-v1-003` | Source paths from Section 2 exist. | PASS only if every path exists. |
| `CHECK-SPEC-goalctl-v1-004` | `REQ-SPEC-goalctl-v1-*` IDs and their acceptance IDs are present. | PASS only if all 8 requirement groups have AC coverage. |
| `CHECK-SPEC-goalctl-v1-005` | CLI surface includes status, validate, registry, matrix, gate, pipeline, evidence, doctor, and acceptance report. | PASS only if all command groups are present. |
| `CHECK-SPEC-goalctl-v1-006` | Error model includes `GOALCTL-SSOT-001`, `GOALCTL-REF-001`, `GOALCTL-ID-001`, `GOALCTL-REG-001`, `GOALCTL-MATRIX-001`, `GOALCTL-GATE-001`, `GOALCTL-PIPE-001`, `GOALCTL-EVID-001`, and `GOALCTL-SECRET-001`. | PASS only if all codes are documented. |
| `CHECK-SPEC-goalctl-v1-007` | Four-axis fields and G0-G11 are present. | PASS only if no single-field Pipeline status is normative. |
| `CHECK-SPEC-goalctl-v1-008` | Validation commands in Section 10 run with PASS/N/A evidence. | PASS only after fresh local verification. |

## 12. Assumptions and open implementation notes

- This is a specification deliverable for `goalctl`; a runtime executable is out of scope for task 3.
- `goalctl` implementation should reuse existing validators where possible before adding new logic.
- Standard-gap remediation should be performed by updating `docs/goal` authority docs first, then synchronizing `.config/goal` projections.
- This document intentionally records alias drift rather than hiding it, because the current authority set documents those drift risks as unresolved.

## 13. Requirements and 验收标准

This section is the explicit acceptance.criteria / 验收标准 block for `SPEC-goalctl-v1`. It includes normal, 边界, 异常, and 错误处理 coverage.


### REQ-SPEC-goalctl-v1-001 — Authority and reference integrity

`goalctl` MUST validate that every normative rule, reference, and projection is traceable to `docs/goal` or an allowed `.config/goal` projection.

Acceptance Criteria:

- `AC-REQ-SPEC-goalctl-v1-001-001`: Given a valid source map, `goalctl validate --references --json` returns `result=pass` and zero `GOALCTL-REF-001` errors.
- `AC-REQ-SPEC-goalctl-v1-001-002`: Given a missing or stale source path, the command emits `GOALCTL-REF-001` with the broken path and remediation.
- `AC-REQ-SPEC-goalctl-v1-001-003`: Given a projection-only enum, the command emits `GOALCTL-SSOT-001`.

### REQ-SPEC-goalctl-v1-002 — CLI completeness

`goalctl` MUST provide status, validate, registry, matrix, gate, pipeline, evidence, doctor, and acceptance report commands.

Acceptance Criteria:

- `AC-REQ-SPEC-goalctl-v1-002-001`: `goalctl --help` lists all command groups in Section 4.
- `AC-REQ-SPEC-goalctl-v1-002-002`: Every command supports `--repo-root` and `--json`.
- `AC-REQ-SPEC-goalctl-v1-002-003`: Unknown commands return non-zero and produce a JSON error when `--json` is supplied.

### REQ-SPEC-goalctl-v1-003 — Config/runtime boundary

`goalctl` MUST keep authority, projection, and runtime artifacts separate.

Acceptance Criteria:

- `AC-REQ-SPEC-goalctl-v1-003-001`: Validation rejects Registry files outside the six-file boundary.
- `AC-REQ-SPEC-goalctl-v1-003-002`: Validation rejects credentials, credential keys, account IDs, private endpoints, trading config, and local personal paths in committed `.config/goal` content.
- `AC-REQ-SPEC-goalctl-v1-003-003`: Runtime cache/log/temp/lock files are ignored or flagged according to `.config/goal` boundary rules and never treated as authority.

### REQ-SPEC-goalctl-v1-004 — Four-axis Pipeline and Gate semantics

`goalctl` MUST validate Pipeline and Gate state without collapsing independent status categories.

Acceptance Criteria:

- `AC-REQ-SPEC-goalctl-v1-004-001`: A Pipeline record missing any of `pipeline_state`, `current_phase`, `phase_status`, or `workflow_step` emits `GOALCTL-PIPE-001`.
- `AC-REQ-SPEC-goalctl-v1-004-002`: A `workflow_step` equal to a `pipeline_state` enum emits `GOALCTL-PIPE-001`.
- `AC-REQ-SPEC-goalctl-v1-004-003`: A final Gate result of `WAIVED` emits `GOALCTL-GATE-001` and recommends `PASS_WITH_RISK` or `BLOCKED`.
- `AC-REQ-SPEC-goalctl-v1-004-004`: G2 checks spec completeness, testability, normal, error, boundary, security, performance, and non-goal coverage.

### REQ-SPEC-goalctl-v1-005 — Registry, Matrix, and Evidence contracts

`goalctl` MUST validate Registry membership, Matrix edges, and Evidence records using projected rules.

Acceptance Criteria:

- `AC-REQ-SPEC-goalctl-v1-005-001`: Registry validation passes only when the six YAML files are present and no sidecar is counted as Registry.
- `AC-REQ-SPEC-goalctl-v1-005-002`: Matrix validation checks required fields, legal relation, legal status, evidence link, owner, updated timestamp, and 95% coverage.
- `AC-REQ-SPEC-goalctl-v1-005-003`: Evidence validation checks Evidence ID, Task ID, Test ID, Goal ID, status, reproducibility, and artifact path.
- `AC-REQ-SPEC-goalctl-v1-005-004`: Done/Verified claims without evidence emit `GOALCTL-EVID-001`.

### REQ-SPEC-goalctl-v1-006 — Deterministic output and error model

`goalctl` MUST emit stable JSON and deterministic error codes.

Acceptance Criteria:

- `AC-REQ-SPEC-goalctl-v1-006-001`: JSON output matches Section 7 top-level shape.
- `AC-REQ-SPEC-goalctl-v1-006-002`: Every failed check includes `code`, `severity`, `message`, `source`, `expected`, `actual`, and `remediation` when known.
- `AC-REQ-SPEC-goalctl-v1-006-003`: The same invalid input produces the same code and exit status across repeated runs.

### REQ-SPEC-goalctl-v1-007 — Traceability and reporting

`goalctl` MUST report traceability from Goal to Evidence.

Acceptance Criteria:

- `AC-REQ-SPEC-goalctl-v1-007-001`: `goalctl matrix trace --goal GOAL-ID --json` renders Goal → Spec → Requirement → AC → Task → Prompt → Code → Test → Evidence.
- `AC-REQ-SPEC-goalctl-v1-007-002`: Missing, stale, drifted, blocked, and changed links are distinct statuses in output.
- `AC-REQ-SPEC-goalctl-v1-007-003`: Acceptance reports include command, timestamp, source input, result, errors, warnings, and evidence references.

### REQ-SPEC-goalctl-v1-008 — Spec-level validation and acceptance checklist

This spec MUST be self-checkable by repo-local validators and a references/checklist verifier.

Acceptance Criteria:

- `AC-REQ-SPEC-goalctl-v1-008-001`: `docs/spec/goalctl-spec.md` exists and is the only modified file for worker-3 task output.
- `AC-REQ-SPEC-goalctl-v1-008-002`: `bash docs/goal/tools/lint-goal.sh docs/spec/goalctl-spec.md` exits 0.
- `AC-REQ-SPEC-goalctl-v1-008-003`: `python3 docs/goal/tools/goal-validate.py --root . --mode audit --format json` exits 0.
- `AC-REQ-SPEC-goalctl-v1-008-004`: A custom verifier confirms required source paths, command groups, error codes, state fields, Gate IDs, trace chain, and acceptance checklist terms.

