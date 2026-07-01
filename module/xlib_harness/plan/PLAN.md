# xlib_harness Implementation Plan

> Module: `xlib_harness`
> Version: v0.1.6
> Last-Updated: 2026-06-30
> Implementation-Baseline: `/home/workspace/xlib-harness@d90b35124701`

## Delivery Strategy

`xlib_harness` is delivered as a standalone Go CLI and library API. The runtime remains stdlib-only; external trust tooling is invoked only from CI/CD workflows and local verification commands.

## Implementation Tasks

| Task | Scope | Files | Status |
| --- | --- | --- | --- |
| `TASK-XLIBHARNESS-001` | CLI generation path and ten-asset output | `/home/workspace/xlib-harness/main.go`, `/home/workspace/xlib-harness/internal/harness/harness.go` | Completed |
| `TASK-XLIBHARNESS-002` | 23-section spec template and spec profile checks | `/home/workspace/xlib-harness/internal/harness/harness.go`, compliant fixture | Completed |
| `TASK-XLIBHARNESS-003` | Runtime dependency boundary checks for `go.mod` and Go imports | `/home/workspace/xlib-harness/internal/harness/harness.go`, bad-dependency fixture | Completed |
| `TASK-XLIBHARNESS-004` | Makefile and CI/CD reference gates | `/home/workspace/xlib-harness/Makefile`, `.github/workflows/ci.yml`, `.github/workflows/release.yml` | Completed |
| `TASK-XLIBHARNESS-005` | Markdown format checks | `/home/workspace/xlib-harness/internal/harness/harness.go`, unit tests | Completed |
| `TASK-XLIBHARNESS-006` | FR/AC/TC trace closure checks | `/home/workspace/xlib-harness/internal/harness/harness.go`, broken-trace fixture | Completed |
| `TASK-XLIBHARNESS-007` | Code-repository feature and acceptance docs plus license-free secret scan | `/home/workspace/xlib-harness/FEATURES.md`, `/home/workspace/xlib-harness/ACCEPTANCE.md`, `.github/workflows/ci.yml`, `.github/workflows/release.yml` | Completed |

## Boundary Rules

The harness rejects runtime references to:

- `observex`
- `configx`
- `resiliencx`
- `schedulex`
- `testkitx`
- `xlib_standard`

The implementation checks both `go.mod` module references and parsed Go imports. CI may call external tools such as `xlibgate`, but the shipped Go runtime stays on the standard library.

## Validation Plan

Run the following before release or merge:

```bash
cd /home/workspace/xlib-harness
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

1. Keep feature work on branch `xlib_harness`.
2. Validate local gates with `make ci`, coverage, benchmark, secret scan, and diff hygiene.
3. Commit implementation using Lore trailers.
4. Tag the module release as `v0.1.6`.
5. Merge `xlib_harness` to module `main`.
6. Merge root documentation branch `xlib_harness` to root `main`.

## Current Evidence

- `/home/workspace/xlib-harness@d90b35124701`
- `make ci`: PASS
- `go test -bench=. ./...`: PASS
- coverage total: 100.0%
- `git diff --check`: PASS
- `xlibgate@v1.0.0` imports/gomod/baseline: PASS
- pinned open-source `gitleaks` CLI secret scan: PASS
- release tag: `v0.1.6`
- GitHub Actions Release run `27855366871`: PASS
- GitHub Actions main CI run `27855396013`: PASS
- GitHub Release: <https://github.com/ZoneCNH/xlib_harness/releases/tag/v0.1.6>
