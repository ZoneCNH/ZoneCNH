# goalctl 规格

> Status: Draft derived spec for Task 2.  
> Scope: define the expected `goalctl` CLI/config/runtime/evidence/error model from `docs/goal` and `.config/goal`.  
> Authority: `goalctl` is an adapter over Goal authority. It must not create new Goal states, Gates, ID formats, registry categories, or evidence enums.

## 1. Purpose

`goalctl` provides a deterministic command-line control surface for the Goal-driven delivery system:

- read authoritative rules from `docs/goal/`;
- read and validate committed control-plane projections under `.config/goal/`;
- run local and CI checks that prove the Goal pipeline, Gate, Matrix, Registry, Evidence, and release state are internally consistent;
- produce machine-readable diagnostics and evidence records without treating chat logs or local runtime cache as authority.

### 1.1 Non-goals

`goalctl` must not:

- redefine the pipeline order, four-axis state model, Gate IDs, Gate result enum, ID formats, registry namespace, or evidence schema;
- write to `docs/goal/` during normal operation;
- treat OMX runtime state/log locations, `.config/goal/runtime`, or `.config/cache` as authoritative Goal rules;
- introduce additional Gate IDs for CI checks, x.go checks, or human-approval checks;
- mark work complete without evidence.

## 2. Authority and projection map

| Domain | Authoritative source | Machine projection / audit path | `goalctl` responsibility |
| --- | --- | --- | --- |
| Authority boundaries | `docs/goal/00-authority-map.md` | `.config/goal/README.md` | Enforce docs-vs-config-vs-runtime boundaries. |
| Pipeline order and state axes | `docs/goal/03-pipeline.md` | `.config/goal/pipeline/state.yaml`, `.config/goal/schema/rules.yaml` | Validate `pipeline_state`, `current_phase`, `phase_status`, and `workflow_step` without collapsing them. |
| Gates | `docs/goal/04-gates.md` | `.config/goal/gates/state.yaml`, `.config/goal/schema/rules.yaml` | Check G0-G11 only and emit valid verdicts only. |
| Matrix | `docs/goal/05-layer-standards.md#9-matrix-横切标准` | `.config/goal/matrix/matrix.yaml` | Validate traceability coverage and canonical edge fields. |
| ID system | `docs/goal/07-id-system.md` | `.config/goal/schema/rules.yaml` | Validate IDs and reject new artifact IDs that do not match authority. |
| Lint / drift rules | `docs/goal/10-lint-rules.md`, `docs/goal/tools/*` | tool outputs and evidence files | Run or wrap the existing Goal toolchain. |
| Runtime / execution modes / evidence protocol | `docs/goal/13-runtime-engine.md` | `.config/goal/evidence/**`, runtime cache | Select Lite/Standard/Full execution expectations and validate evidence. |
| Registry | `docs/goal/15-registry.md`, `.config/goal/README.md` | `.config/goal/registry/{goals,tasks,issues,releases,risks,decisions}.yaml` | Enforce exactly the six registry namespaces. |
| CI / x.go adapter | `docs/goal/16-ci-cd.md` | CI reports, release manifests, evidence | Map CI-CHK* and XG-CHK* to Gate/Evidence outputs, never to new Gates. |
| Metrics and evidence loop | `docs/goal/20-metrics-evidence.md` | evidence graph records | Enforce “No Evidence, No Done” and reproducibility metadata. |

## 3. Command model

All commands accept `--root <path>`; default root discovery walks upward from the current directory until both `docs/goal/` and `.config/goal/` exist. All commands accept `--format text|json`; CI SHOULD use `--format json`.

### 3.1 Inspection and health

| Command | Purpose | Minimum output |
| --- | --- | --- |
| `goalctl doctor` | Verify repository layout, required files, executable tools, and ignored runtime paths. | tool availability, missing files, runtime boundary warnings. |
| `goalctl status` | Print current four-axis state. | `goal_id`, `pipeline_state`, `previous_pipeline_state`, `current_phase`, `phase_status`, `workflow_step`, blockers, required Gate, next allowed actions. |
| `goalctl validate [--mode audit|strict]` | Validate Goal control-plane consistency. | PASS/FAIL by domain and references to offending paths. |
| `goalctl lint <path...>` | Run Goal lint rules over docs/spec/matrix/prompt surfaces. | lint rule id, severity, path, remediation. |
| `goalctl drift-check` | Detect stale paths/status/Gate/ID references. | stale reference list and owning authority source. |

`goalctl status` must preserve the four axes:

- `pipeline_state`: global state machine such as `INIT`, `RELEASING`, `DONE`, `BLOCKED`, or `INCONSISTENT_STATE`;
- `current_phase`: business/artifact layer such as `GOAL`, `SPEC`, `CODE`, `RELEASE`, or `RETROSPECTIVE`;
- `phase_status`: artifact readiness such as `NOT_STARTED`, `IN_PROGRESS`, `IN_REVIEW`, `READY`, `DONE`, `BLOCKED`, `SKIPPED`, or `STALE`;
- `workflow_step`: SOP/Runtime/CI execution projection from `.config/goal/schema/rules.yaml`, never a substitute for `pipeline_state`.

### 3.2 Pipeline commands

| Command | Behavior |
| --- | --- |
| `goalctl pipeline show` | Read `.config/goal/pipeline/state.yaml` and render current state plus history. |
| `goalctl pipeline allowed-actions` | Derive allowed next actions from current state, required Gate, blockers, and evidence requirements. |
| `goalctl pipeline transition --goal <GOAL_ID> --to <STATE> --expected-current <STATE> --evidence <EVID_ID>` | Atomically request a guarded transition. It must fail if the expected current state does not match, required Gate/Evidence is missing, or release-blocking risk remains. |
| `goalctl pipeline explain --state <STATE>` | Explain state semantics using `docs/goal/03-pipeline.md` and machine projection values. |

Transition writes are allowed only to committed control-plane state files and must include actor, timestamp, command, previous value, new value, and evidence reference.

### 3.3 Gate commands

| Command | Behavior |
| --- | --- |
| `goalctl gate list` | List only G0-G11. |
| `goalctl gate show G<N>` | Show authority, current status, checks, result, risk metadata, and evidence. |
| `goalctl gate check G<N> [--goal <GOAL_ID>]` | Re-run executable or hybrid checks where available; semantic checks may report required review evidence. |
| `goalctl gate record G<N> --verdict PASS|PASS_WITH_RISK|FAIL|BLOCKED --evidence <EVID_ID> ...` | Record a Gate result if policy constraints are satisfied. |
| `goalctl gate blockers` | Report all failed/blocked Gates and open `release_blocking` risks. |

Gate constraints:

- valid Gate IDs are exactly `G0` through `G11`;
- valid Gate verdicts are exactly `PASS`, `PASS_WITH_RISK`, `FAIL`, and `BLOCKED`;
- `WAIVED` is a waiver policy concept only; final Gate state must map to `PASS_WITH_RISK` or `BLOCKED`;
- G6 and G10 must not be recorded as `PASS_WITH_RISK`;
- G10 must fail/block release if any open `release_blocking` risk remains.

### 3.4 Matrix commands

| Command | Behavior |
| --- | --- |
| `goalctl matrix check` | Validate `.config/goal/matrix/matrix.yaml` against canonical fields and coverage rules. |
| `goalctl matrix generate --from <spec|registry>` | Produce deterministic traceability edges for review; writes require explicit output path or guarded update. |
| `goalctl matrix coverage` | Report coverage from Goal/Spec/Requirement/AC/Task/Prompt/Test/Evidence edges. |
| `goalctl matrix explain <ID>` | Show upstream and downstream traceability for an ID. |

Canonical Matrix edge fields are `source_id`, `target_id`, `relation`, `status`, `evidence_id`, `gate_id`, `owner`, and `updated_at`. Matrix is cross-cutting; it must not appear as a pipeline phase.

### 3.5 Registry commands

| Command | Behavior |
| --- | --- |
| `goalctl registry list <goals|tasks|issues|releases|risks|decisions>` | List objects from the six allowed registry files only. |
| `goalctl registry show <ID>` | Resolve an object by ID and show file, status, owner, linked evidence, and traceability. |
| `goalctl registry check` | Validate registry IDs, lifecycle fields, references, release blockers, and required evidence. |
| `goalctl risk blockers` | Print open release-blocking risks and the Gate/release objects they block. |

The registry namespace is limited to `.config/goal/registry/goals.yaml`, `tasks.yaml`, `issues.yaml`, `releases.yaml`, `risks.yaml`, and `decisions.yaml`. Schema, Matrix, Gates, Pipeline, Evidence, and prompts are sidecar control-plane components, not registry namespaces.

### 3.6 Evidence commands

| Command | Behavior |
| --- | --- |
| `goalctl evidence collect --task <TASK_ID> --test <TEST_ID> --commands <file> --status PASS|FAIL|PARTIAL` | Collect reproducible evidence from command output, changed files, logs, and diff summary. |
| `goalctl evidence check [<EVID_ID>|--all]` | Validate evidence IDs, required fields, status enum, file location, command provenance, and linked Matrix/Gate references. |
| `goalctl evidence list --task <TASK_ID>` | List evidence records for a task. |
| `goalctl evidence graph <ID>` | Show why an object can be trusted by traversing Matrix and evidence edges. |

Evidence records must include at least:

- `Evidence ID`, `Acceptance Criteria ID` when applicable, `Test ID`, `Task ID`, `Spec ID`, `Goal ID`;
- `Date`, `Status`, `Files Changed`, `Commands Run`, `Results`, `Logs`, `Diff Summary`;
- `Requirement Proof`, `Known Limitations`, `Risks`, and `Rollback`.

Evidence is invalid if it omits logs, tests/commands, file list, or risk notes. Evidence IDs must follow the ID system and, for committed evidence, live under `.config/goal/evidence/YYYY-MM-DD/TASK_ID/EVID_ID.md`.

### 3.7 Release and CI commands

| Command | Behavior |
| --- | --- |
| `goalctl release precheck` | Evaluate release readiness from G10, release manifest, Evidence package, and open release-blocking risks. |
| `goalctl release manifest --release <REL_ID>` | Validate release manifest references, rollback plan, artifacts, and commit boundary. |
| `goalctl ci contract` | Run or validate CI-CHK0 through CI-CHK11 reports. |
| `goalctl ci summarize --input <json>` | Convert CI reports into Gate/Evidence diagnostics. |

CI Phase 0-8 is a `workflow_step` execution profile, not `current_phase` and not `pipeline_state`. `CI-CHK*` and `XG-CHK*` identifiers are checks whose results feed G7, G8, G9, G10, or release evidence; they must not be exposed as new Goal Gates.

### 3.8 Runtime maintenance commands

| Command | Behavior |
| --- | --- |
| `goalctl runtime inspect` | Show local runtime/cache locations and confirm they are non-authoritative. |
| `goalctl runtime clean [--dry-run]` | Remove ignored local temp files, locks, and stale cache entries without touching committed authority/projection files. |
| `goalctl config show` | Render effective path aliases and output defaults. |

## 4. Configuration model

### 4.1 Required repository layout

`goalctl` requires these directories at the resolved root:

```text
docs/goal/                  # authoritative human-readable rules
.config/goal/schema/        # machine validation projection
.config/goal/pipeline/      # pipeline state snapshot
.config/goal/gates/         # Gate state snapshot
.config/goal/matrix/        # Matrix traceability snapshot
.config/goal/registry/      # six registry namespaces
.config/goal/evidence/      # committed evidence records
```

### 4.2 Runtime and ignored paths

The following paths are runtime or external workflow state and must not be treated as Goal authority:

```text
.config/goal/runtime/       # private/local goalctl runtime, if present
.config/cache/              # local cache/root used by existing validators
OMX runtime state/logs      # external workflow runtime, never Goal authority
```

### 4.3 Optional local configuration

A future `goalctl.yaml` MAY provide local path aliases, default output format, CI profile selection, and cache directory selection. It MUST NOT override authoritative enums, Gate definitions, ID patterns, registry namespaces, or pipeline semantics. If local config conflicts with `docs/goal` or `.config/goal/schema/rules.yaml`, `goalctl` must report `AUTHORITY_DRIFT` and refuse writes.

## 5. Runtime semantics

### 5.1 Read path

Read-only commands follow this order:

1. discover root;
2. load `docs/goal/00-authority-map.md` and `.config/goal/README.md` boundaries;
3. load machine projections from `.config/goal/schema/rules.yaml` and target state files;
4. validate projection values against authority-derived schema;
5. render text/JSON diagnostics with source paths and remediation.

### 5.2 Write path

Write commands are limited to projection/audit/runtime outputs declared by the command. They must:

1. re-run read-path validation before changing files;
2. acquire a single-writer lock for each target file;
3. require `--expected-current` or equivalent optimistic concurrency guard for state transitions;
4. write atomically via temporary file + rename;
5. include actor, timestamp, command, source path, previous value, new value, and evidence reference;
6. refuse to write if the command would alter `docs/goal/` authority.

### 5.3 Execution mode selection

`goalctl` derives verification expectations from change level:

| Change level | Mode | Required flow / constraints |
| --- | --- | --- |
| CL0 | Lite | Docs/comment/metadata only; no behavior/interface/Gate/state/executable-rule change; requires G8 and G9 evidence/review. |
| CL1 | Lite | Local implementation/rule/doc-system fix; requires G5, G7, G8, G9; Matrix required when AC/Test/Evidence traceability changes. |
| CL2 | Standard | Module behavior change; requires main flow with Matrix, Risk Register, Release Manifest, and Evidence. |
| CL3-CL5 | Full | Public API, architecture boundary, or data/storage/migration change; requires Standard plus Registry, State Machine, Human Approval Check, Rollback Protocol, Change Propagation Matrix, ADR, executable Gates, and Release Manifest. |

Human approval checks `H-CHK1` through `H-CHK8` are approval evidence, not Gates. CL0/CL1 do not force human confirmation, CL2 needs reviewer confirmation, and CL3/CL4/CL5 require human confirmation.

### 5.4 Concurrency and ownership

`goalctl` must enforce one writer per target control-plane file. It should align with existing write ownership:

- goal-spec: registry and pipeline;
- goal-matrix: matrix;
- goal-reviewer: gates;
- goal-prompt-builder: prompts;
- goal-evidence: evidence.

Multiple readers are allowed. Stale lock recovery must be explicit and auditable.

## 6. Error model

### 6.1 Exit codes

| Exit | Code | Meaning |
| ---: | --- | --- |
| 0 | `OK` | Command completed successfully. |
| 1 | `VALIDATION_FAILED` | Goal lint, Matrix, Gate, Evidence, registry, or CI validation failed. |
| 2 | `USAGE_OR_CONFIG_ERROR` | Invalid flags, missing root, malformed local config, or unsupported format. |
| 3 | `INCONSISTENT_STATE` | Projection contradicts authority, state axes are mixed, or required references disagree. |
| 4 | `MISSING_CONTEXT` | Required artifact, evidence file, authority doc, or registry object is missing. |
| 5 | `WRITE_CONFLICT` | Lock conflict, optimistic-concurrency mismatch, or dirty target file. |
| 6 | `HUMAN_APPROVAL_REQUIRED` | Required H-CHK approval evidence is missing. |
| 7 | `RELEASE_BLOCKED` | G10/release precheck is blocked by Gate failure, release-blocking risk, or missing release evidence. |
| 8 | `AUTHORITY_DRIFT` | Command detects new/unknown states, Gates, IDs, registry namespaces, or incompatible schema drift. |
| 9 | `INTERNAL_ERROR` | Unexpected tool failure or unhandled exception. |

### 6.2 JSON diagnostic shape

```json
{
  "ok": false,
  "exit_code": 7,
  "code": "RELEASE_BLOCKED",
  "message": "Open release_blocking risks prevent G10 PASS.",
  "path": ".config/goal/registry/risks.yaml",
  "source": "goalctl release precheck",
  "authority_ref": "docs/goal/04-gates.md#gate-results",
  "object_id": "RISK-GOAL-20260608-001-001",
  "remediation": "Close or downgrade the risk with evidence, then rerun goalctl release precheck."
}
```

Diagnostics must identify the path and authority reference when known. Diagnostics must not include secrets, credentials, or full private logs unless the caller explicitly requests verbose local output.

### 6.3 Boundary scenarios and error handling

`goalctl` must handle these edge cases without guessing or mutating authority:

- partial checkout or wrong root: `doctor` may diagnose missing `docs/goal/` or `.config/goal/`, while other commands fail with `MISSING_CONTEXT`;
- unknown authority vocabulary: new Gate IDs, state literals, registry namespaces, Matrix phases, or evidence statuses fail with `AUTHORITY_DRIFT`;
- blocked release context: open `release_blocking` risks, missing G10 evidence, or G10 not `PASS` fail with `RELEASE_BLOCKED`;
- concurrent writers: stale locks, dirty target files, or `--expected-current` mismatches fail with `WRITE_CONFLICT`;
- incomplete evidence: missing logs, command provenance, changed-file list, risk notes, or required IDs fails with `VALIDATION_FAILED`;
- human-approval boundary: missing required `H-CHK*` evidence fails with `HUMAN_APPROVAL_REQUIRED` and must not be converted into a Gate waiver.

## 7. Acceptance checklist for this spec

A conforming `goalctl` implementation must satisfy these acceptance criteria:

- AC-GOALCTL-001: Root discovery requires `docs/goal/` and `.config/goal/` and refuses to run against partial context except for `doctor` diagnostics.
- AC-GOALCTL-002: `status` preserves the four-axis model and never maps CI Phase or Matrix to `current_phase`.
- AC-GOALCTL-003: Gate commands accept only G0-G11 and only `PASS`, `PASS_WITH_RISK`, `FAIL`, `BLOCKED` verdicts.
- AC-GOALCTL-004: G6/G10 `PASS_WITH_RISK`, unknown Gate IDs, `PENDING`, and `WAIVED` as persisted Gate results are rejected.
- AC-GOALCTL-005: Registry commands operate only on goals/tasks/issues/releases/risks/decisions registry files.
- AC-GOALCTL-006: Evidence commands enforce ID patterns, required fields, command provenance, file list, risk notes, and reproducible logs.
- AC-GOALCTL-007: Release precheck fails when G10 is not PASS, release evidence is missing, or any open `release_blocking` risk remains.
- AC-GOALCTL-008: Write commands are atomic, lock guarded, auditable, and never write `docs/goal/` authority files.
- AC-GOALCTL-009: CI-CHK*, XG-CHK*, and H-CHK* are checks/evidence only and never become new Goal Gates.
- AC-GOALCTL-010: Error output uses stable exit codes and machine-readable diagnostics with path, authority reference, and remediation.

## 8. Verification profile

For this repository, the current goalctl-spec verification profile is:

```sh
python3 -m py_compile docs/goal/tools/goal-validate.py docs/goal/tools/matrix-gen.py docs/goal/tools/rule-drift-check.py
./docs/goal/tools/lint-goal.sh docs/spec/goalctl-spec.md
python3 docs/goal/tools/goal-validate.py --root . --mode audit --format text
python3 docs/goal/tools/matrix-gen.py --check-only --matrix .config/goal/matrix/matrix.yaml
./docs/goal/tools/gate-check.sh .
python3 docs/goal/tools/rule-drift-check.py --root . --quiet
git diff --check
```

If a check fails because the committed Goal control plane is intentionally `BLOCKED`, the command must report the blocker as evidence rather than silently converting it to success.
