---
task_id: TASK-BINANCE-SERVER-008
related_requirements:
  - FR-001
  - FR-002
  - FR-003
  - FR-004
  - FR-005
  - FR-006
  - FR-007
  - FR-008
scope: >
  Server-specific gates:
acceptance_criteria:
  - "CI fails when server imports client internals."
  - "CI fails when server references `binance-market` outside allowlist."
  - "CI fails when server owns exchange connector code."
  - "CI fails when server owns storage/query/strategy."
  - "CI allows contracts/domain-market/market-data downstream port dependencies."
  - "gate does not require `rg`; POSIX `grep` is sufficient."
---
# TASK-BINANCE-SERVER-008 Boundary Gates

## Objective

Ensure server boundaries are enforceable in CI.

## Scope

Server-specific gates:

- no client internal import
- no `binance-market`
- no storage/query/strategy ownership
- no exchange connector ownership
- no local proto ownership


## Non-scope

- Does not change behavior outside `module/binance/server`.
- Does not import or modify client internals.

## Deliverables

- CI script additions
- allowed/forbidden import documentation
- negative fixtures if applicable

## Acceptance Criteria

- CI fails when server imports client internals.
- CI fails when server references `binance-market` outside allowlist.
- CI fails when server owns exchange connector code.
- CI fails when server owns storage/query/strategy.
- CI allows contracts/domain-market/market-data downstream port dependencies.
- gate does not require `rg`; POSIX `grep` is sufficient.
