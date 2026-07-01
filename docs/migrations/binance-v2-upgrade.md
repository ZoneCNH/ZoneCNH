# Binance v2 distributed C/S upgrade migration (#894)

- Date: 2026-06-23
- Owner surface: `module/binance`
- Status: docs anchor for the v2 migration; runtime closure remains gated by
  fresh `/home/workspace/binance` verification evidence.
- Related issues: #869, #893, #894

## Purpose

This note is the migration index for the Binance v2 move from the historical
same-process C/S shape to the required distributed C/S architecture.

Normative constraints live in `module/binance/SPEC.md` §4.1. Historical
rationale and the code-state audit are consolidated here so
`module/binance/DEEP-ANALYSIS.md` §0 and §12 can remain archive stubs without
becoming a second SSOT.

## Source evidence

| Source | Why it matters |
|---|---|
| `module/binance/SPEC.md` §4.1 | Normative distributed constraints: independent client/server processes, natsx JetStream as the only client→server channel, no same-process bridge. |
| `module/binance/DEEP-ANALYSIS.md` §0 | Archive stub pointing to SPEC §4.1 and this migration note. |
| `module/binance/DEEP-ANALYSIS.md` §12 | Archive stub pointing to this historical code-state evidence index. |
| `docs/migrations/binance-v2-upgrade.md` | Migration contract plus historical evidence index for distributed C/S migration. |
| `report/binance/deep-analysis-20260622.md` | Review record recommending §0 promotion into SPEC §4 and §12 migration into `docs/migrations/`. |
| `report/binance/deep-analysis-20260622-v2.md` | Follow-up review record confirming the same migration split. |

## Migration contract

1. `binance-client` and `binance-server` are independently deployable runtime
   processes.
2. Client-to-server market data crosses the network through natsx JetStream;
   direct Go interface calls are not a valid runtime path.
3. NATS JetStream is external platform infrastructure configured by address,
   not embedded by either Binance process.
4. `internal/cs` may appear only as historical context during migration and
   must not be a runtime dependency.
5. Release closure requires fresh runtime evidence, not docs-only assertions.

## Runtime closure checklist

Run from `/home/workspace/binance` on the runtime implementation branch:

```bash
git status --short --branch
./scripts/boundary-gates.sh
go test ./...
go vet ./...
go test ./... -race -count=1
golangci-lint run
```

The migration is ready for release only when those checks are clean and any
remaining smoke/deployment checks required by `module/binance/STANDARD.md` are
recorded.

## Current gap handling

- #893: SPEC §4.1 is the normative home for distributed runtime constraints.
  DEEP §0/§12 are stubs that point here and back to SPEC rather than carrying
  duplicate SSOT text.
- #894: this file plus `docs/migrations/README.md` and the SPEC migration table
  provide the migration index wiring. This file carries the historical evidence
  index; DEEP §0/§12 are reduced to pointers.
- #869: docs can record evidence, but runtime closure remains implementation
  gated until the command set above is fresh and clean.
