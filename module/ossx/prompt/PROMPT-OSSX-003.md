# Prompt for TASK-OSSX-003: Multipart lifecycle

You are implementing `TASK-OSSX-003` for `module/ossx`.

## Scope

Implement multipart initiate, part upload, list, complete, abort, and stale cleanup semantics.

## Required references

- `module/ossx/goal.md`
- `module/ossx/SPEC.md`
- `module/ossx/TRACEABILITY.md`
- `module/ossx/tasks/TASK-OSSX-003.md`

## Constraints

- Keep changes inside `module/ossx` unless the task is explicitly widened by maintainers.
- Do not import `configx` from ossx packages.
- Do not expose provider SDK types in public ossx APIs.
- Prefer small tests that prove the acceptance criteria before broad implementation.

## Done when

- Acceptance criteria in `tasks/TASK-OSSX-003.md` pass.
- Traceability rows linked to TASK-OSSX-003 remain current.
- Validation output is appended under `module/ossx/evidence/`.
