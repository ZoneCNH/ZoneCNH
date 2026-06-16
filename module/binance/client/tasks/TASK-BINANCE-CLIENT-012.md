---
task_id: TASK-BINANCE-CLIENT-012
related_requirements:
  - FR-001
  - FR-002
  - FR-003
  - FR-004
  - FR-005
  - FR-006
  - FR-007
  - FR-008
  - FR-009
  - FR-010
scope: >
  Client-specific gates:
acceptance_criteria:
  - "CI fails when client imports server internals."
  - "CI fails when client references `binance-market` outside allowlist."
  - "CI fails when client owns storage/query/strategy."
  - "CI allows contracts/domain-market imports."
  - "gate does not require `rg`; POSIX `grep` is sufficient."
---
# TASK-BINANCE-CLIENT-012 Boundary Gates

## Objective

Ensure client boundaries are enforceable in CI.

## Scope

Client-specific gates:

- no server internal import
- no `binance-market`
- no storage/query/strategy ownership
- no domain canonical type ownership
- no local proto ownership


## Non-scope

- Does not change behavior outside `module/binance/client`.
- Does not define canonical domain source of truth or server persistence semantics.

## Deliverables

- CI script additions
- documentation of allowed/forbidden imports
- negative fixtures if applicable

## Acceptance Criteria

- CI fails when client imports server internals.
- CI fails when client references `binance-market` outside allowlist.
- CI fails when client owns storage/query/strategy.
- CI allows contracts/domain-market imports.
- gate does not require `rg`; POSIX `grep` is sufficient.
