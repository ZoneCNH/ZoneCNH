# Prompt for TASK-OSSX-004: Presigned URL policy and audit masking

You are implementing `TASK-OSSX-004` for `module/ossx`.

## Scope

Implement presigned GET/PUT policy enforcement and audit-safe output.

## Required references

- `module/ossx/goal.md`
- `module/ossx/SPEC.md`
- `module/ossx/TRACEABILITY.md`
- `module/ossx/tasks/TASK-OSSX-004.md`

## Constraints

- Keep changes inside `module/ossx` unless the task is explicitly widened by maintainers.
- Do not import `configx` from ossx packages.
- Do not expose provider SDK types in public ossx APIs.
- Prefer small tests that prove the acceptance criteria before broad implementation.

## Done when

- Acceptance criteria in `tasks/TASK-OSSX-004.md` pass.
- Traceability rows linked to TASK-OSSX-004 remain current.
- Validation output is appended under `module/ossx/evidence/`.
