# TASK-BINANCE-ROOT-001 Root Module Documentation

## Objective

Establish the root-level documentation for `module/binance`, defining the client/server split and the module's place in the FoundationX architecture.

## Scope

Create all root-level documentation files that form the entry point for the binance module. These docs define the module's scope, boundaries, and runtime mapping without claiming ownership of storage, query, or strategy concerns.

## Deliverables

- `module/binance/goal.md`
- `module/binance/README.md`
- `module/binance/SPEC.md`
- `module/binance/TRACEABILITY.md`
- `module/binance/BOUNDARY-GATES.md`
- `module/binance/RUNTIME-MAPPING.md`
- `module/binance/IMPLEMENTATION-PLAN.md`

## Acceptance Criteria

1. Root documentation clearly defines the client/server split.
2. No storage, query, or strategy ownership appears in the root docs.
3. No legacy Provider path remains anywhere in the root docs.
4. `goal.md` states the module's purpose in the FoundationX ecosystem.
5. `BOUNDARY-GATES.md` defines gates that enforce the client/server boundary.
6. `RUNTIME-MAPPING.md` maps the module to runtime artifacts (binaries, configs).

## Dependencies

- PR-000 (binance-market removed before establishing new module root).
