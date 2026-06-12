# TASK-OSSX-000: Module skeleton and dependency guard

```yaml
task_id: TASK-OSSX-000
title: Module skeleton and dependency guard
module: ossx
status: pending
priority: high
scope: Create ossx package skeleton and enforce forbidden dependency boundaries.
spec_ref:
  - module/ossx/SPEC.md#FR-001
  - module/ossx/SPEC.md#BR-002
  - module/ossx/SPEC.md#BR-012
depends_on:
  - none
files:
  - module/ossx/go.mod
  - module/ossx/README.md
  - module/ossx/doc.go
  - module/ossx/internal/dependency_guard_test.go
  - module/ossx/Makefile
acceptance_criteria:
  - ossx package compiles with module-owned Config placeholder.
  - Dependency guard fails on direct configx or other storage extension imports.
  - README links goal, spec, traceability, plan, tasks, prompts, and evidence.
validation:
  - go test ./module/ossx/...
  - go list -deps ./module/ossx/... | grep -v configx
```

## Prompt

Use `module/ossx/prompt/PROMPT-OSSX-000.md` for the implementation handoff.
