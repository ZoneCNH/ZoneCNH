# ossx Implementation Plan

## Objective

Close the ossx documentation and implementation handoff chain so Goal -> Spec -> Matrix -> Tasks -> Prompts -> Evidence is explicit and dependency-safe.

## Constraints

- Scope is `module/ossx`.
- ossx must not directly depend on `configx`.
- ossx may depend on `kernel` and observex interface contracts only.
- Other storage extensions and unrelated worktrees are out of scope.

## Slices

1. `TASK-OSSX-000` — module skeleton and dependency guard.
2. `TASK-OSSX-001` — object identity, metadata, checksum, lifecycle policy model.
3. `TASK-OSSX-002` — BlobStore basic and streaming operations.
4. `TASK-OSSX-003` — multipart lifecycle.
5. `TASK-OSSX-004` — presigned URL policy and audit masking.
6. `TASK-OSSX-005` — adapter SPI and S3-compatible adapter boundary.
7. `TASK-OSSX-006` — observability, health, release evidence, and examples.

## Validation Strategy

- Structural docs: `bash .github/ci/spec-lint.sh`.
- Traceability: `TRACEABILITY_STRICT=1 bash .github/ci/traceability-check.sh`.
- Task metadata: `bash .github/ci/task-spec-validate.sh`.
- Dependency guard after implementation: `go list -deps ./module/ossx/... | grep -v configx` plus dedicated import tests.
- Unit and contract tests per task once implementation code exists.

## Handoff Notes

Implement tasks in numeric order unless a later adapter task is split into a separate branch. Preserve public API names only after contract tests are added; before then, update this plan and traceability if naming changes.
