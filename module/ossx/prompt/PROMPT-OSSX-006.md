# Prompt for TASK-OSSX-006: Observability health and release gates

You are implementing `TASK-OSSX-006` for `module/ossx`.

## Scope

Implement observability hooks, health, examples, and release evidence closure.

## Required references

- `module/ossx/goal.md`
- `module/ossx/SPEC.md`
- `module/ossx/TRACEABILITY.md`
- `module/ossx/tasks/TASK-OSSX-006.md`

## Constraints

- Keep changes inside `module/ossx` unless the task is explicitly widened by maintainers.
- Do not import `configx` from ossx packages.
- Do not expose provider SDK types in public ossx APIs.
- Prefer small tests that prove the acceptance criteria before broad implementation.

## Done when

- Acceptance criteria in `tasks/TASK-OSSX-006.md` pass.
- Traceability rows linked to TASK-OSSX-006 remain current.
- Validation output is appended under `module/ossx/evidence/`.
