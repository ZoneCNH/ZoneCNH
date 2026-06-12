# Prompt for TASK-OSSX-002: BlobStore basic and streaming operations

You are implementing `TASK-OSSX-002` for `module/ossx`.

## Scope

Implement core BlobStore operations, streaming semantics, and typed error mapping.

## Required references

- `module/ossx/goal.md`
- `module/ossx/SPEC.md`
- `module/ossx/TRACEABILITY.md`
- `module/ossx/tasks/TASK-OSSX-002.md`

## Constraints

- Keep changes inside `module/ossx` unless the task is explicitly widened by maintainers.
- Do not import `configx` from ossx packages.
- Do not expose provider SDK types in public ossx APIs.
- Prefer small tests that prove the acceptance criteria before broad implementation.

## Done when

- Acceptance criteria in `tasks/TASK-OSSX-002.md` pass.
- Traceability rows linked to TASK-OSSX-002 remain current.
- Validation output is appended under `module/ossx/evidence/`.
