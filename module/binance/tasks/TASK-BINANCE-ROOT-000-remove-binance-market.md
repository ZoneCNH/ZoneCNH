# TASK-BINANCE-ROOT-000 Remove binance-market

## Objective

Remove `binance-market` from the active architecture and status documents, replacing all references with `module/binance/client` and `module/binance/server`.

## Scope

This is a cleanup task that removes the old `binance-market` module from all active documentation and adds a migration gate to prevent legacy references from reappearing.

## Deliverables

- Removal of `binance-market` from active architecture documents
- Removal of `docs/services/binance-market-client-svc.md`
- Migration note placed outside this module
- No-legacy gate added to BOUNDARY-GATES.md

## Acceptance Criteria

1. No active document says `binance-market` is current.
2. All new Binance work points to `module/binance/client` and `module/binance/server`.
3. Old Provider references are removed or marked as deprecated.
4. Migration note is present and outside the binance module directory.
5. No-legacy gate is active (gate rejects any reintroduction of `binance-market` references).

## Dependencies

- None (no module dependency required for removal).
