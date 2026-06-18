# Prompt for TASK-OSSX-005: Aliyun OSS adapter

You are implementing `TASK-OSSX-005` for `module/ossx`.

## Scope

Implement the Aliyun OSS adapter that isolates the Aliyun OSS SDK behind ossx typed contracts.

## Required references

- `module/ossx/goal.md`
- `module/ossx/SPEC.md`
- `module/ossx/TRACEABILITY.md`
- `module/ossx/tasks/TASK-OSSX-005.md`

## Constraints

- Keep changes inside `module/ossx` unless the task is explicitly widened by maintainers.
- Do not import `configx` from ossx packages.
- Do not expose Aliyun OSS SDK types in public ossx APIs.
- Prefer small tests that prove the acceptance criteria before broad implementation.

## Done when

- Acceptance criteria in `tasks/TASK-OSSX-005.md` pass.
- Traceability rows linked to TASK-OSSX-005 remain current.
- Validation output is appended under `module/ossx/evidence/`.
