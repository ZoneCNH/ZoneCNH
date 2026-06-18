# Prompt for TASK-OSSX-000: Module skeleton and dependency guard

You are implementing `TASK-OSSX-000` for `module/ossx`.

## Scope

Create ossx package skeleton and enforce forbidden dependency boundaries.

## Required references

- `module/ossx/goal.md`
- `module/ossx/SPEC.md`
- `module/ossx/TRACEABILITY.md`
- `module/ossx/tasks/TASK-OSSX-000.md`

## Constraints

- Keep changes inside `module/ossx` unless the task is explicitly widened by maintainers.
- Do not import `configx` from ossx packages.
- Do not expose Aliyun OSS SDK types in public ossx APIs.
- Prefer small tests that prove the acceptance criteria before broad implementation.

## Done when

- Acceptance criteria in `tasks/TASK-OSSX-000.md` pass.
- Traceability rows linked to TASK-OSSX-000 remain current.
- Validation output is appended under `module/ossx/evidence/`.
