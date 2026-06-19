# xlib-harness Implementation Plan

> Module: `xlib-harness`
> Version: v0.1.2
> Last-Updated: 2026-06-19
> Implementation-Baseline: `/home/xlib-harness@aa83306685a9`

## Delivery Strategy

`xlib-harness` is delivered as a standalone Go CLI and library API. The runtime remains stdlib-only; external trust tooling is invoked only from CI/CD workflows and local verification commands.

## Implementation Tasks

| Task | Scope | Files | Status |
| --- | --- | --- | --- |
| `TASK-XLIBHARNESS-001` | CLI generation path and six-asset output | `/home/xlib-harness/main.go`, `/home/xlib-harness/internal/harness/harness.go` | Completed |
| `TASK-XLIBHARNESS-002` | 23-section spec template and spec profile checks | `/home/xlib-harness/internal/harness/harness.go`, compliant fixture | Completed |
| `TASK-XLIBHARNESS-003` | Runtime dependency boundary checks for `go.mod` and Go imports | `/home/xlib-harness/internal/harness/harness.go`, bad-dependency fixture | Completed |
| `TASK-XLIBHARNESS-004` | Makefile and CI/CD reference gates | `/home/xlib-harness/Makefile`, `.github/workflows/ci.yml`, `.github/workflows/release.yml` | Completed |
| `TASK-XLIBHARNESS-005` | Markdown format checks | `/home/xlib-harness/internal/harness/harness.go`, unit tests | Completed |
| `TASK-XLIBHARNESS-006` | FR/AC/TC trace closure checks | `/home/xlib-harness/internal/harness/harness.go`, broken-trace fixture | Completed |

## Boundary Rules

The harness rejects runtime references to:

- `observex`
- `configx`
- `resiliencx`
- `schedulex`
- `testkitx`
- `xlib-standard`

The implementation checks both `go.mod` module references and parsed Go imports. CI may call external tools such as `xlibgate`, but the shipped Go runtime stays on the standard library.

## Validation Plan

Run the following before release or merge:

```bash
cd /home/xlib-harness
go build ./...
go test ./...
go test ./... -race -count=1
go vet ./...
go test ./... -coverprofile=coverage.out -covermode=count
go tool cover -func=coverage.out
go test -bench=. ./...
make ci
git diff --check
```

Required coverage threshold: 100.0%.

## Release Plan

1. Keep feature work on branch `xlib-harness`.
2. Validate local gates with `make ci`, coverage, benchmark, secret scan, and diff hygiene.
3. Commit implementation using Lore trailers.
4. Tag the module release as `v0.1.2`.
5. Merge `xlib-harness` to module `main`.
6. Merge root documentation branch `xlib-harness` to root `main`.

## Current Evidence

- `/home/xlib-harness@aa83306685a9`
- `make ci`: PASS
- `go test -bench=. ./...`: PASS
- coverage total: 100.0%
- `git diff --check`: PASS
- local tag: `v0.1.2`
