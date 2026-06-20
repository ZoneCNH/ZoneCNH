# xlib-harness Acceptance

> Module: `xlib-harness`
> Version: v0.1.4
> Last-Updated: 2026-06-20
> Implementation-Baseline: `/home/xlib-harness@fb097be5eff4`

## Acceptance Matrix

| AC ID | Requirement | Command | Expected | Evidence |
| --- | --- | --- | --- | --- |
| AC-001 | 生成 10 个模块资产 | `go run . generate /tmp/xlib-harness-smoke --force` | 生成 README、SPEC、TRACEABILITY、goal、IMPLEMENTATION-PLAN、ACCEPTANCE、FEATURES、TASK-001、Makefile、CI workflow | PASS |
| AC-002 | 规格结构门禁通过 compliant fixture | `go run . check fixtures/compliant-module --profile spec` | 所有 spec checks 通过 | PASS |
| AC-003 | 运行时边界门禁拒绝禁止依赖 | `go run . check fixtures/module-with-bad-dep --profile boundary` | 命令非零退出并报告 forbidden dependency | PASS |
| AC-004 | CI/CD 引用门禁通过 compliant fixture | `go run . check fixtures/compliant-module --profile full` | full profile 所有检查通过 | PASS |
| AC-005 | Markdown 格式问题被发现 | 格式 fixture / 单元测试 | trailing whitespace、空链接、表格列漂移被发现 | PASS |
| AC-006 | 追踪矩阵断链被发现 | `go run . check fixtures/broken-trace --profile full` | 命令非零退出并报告 trace closure failure | PASS |

## Required Local Gates

| Gate | Command | Result |
| --- | --- | --- |
| Build | `cd /home/xlib-harness && go build ./...` | PASS |
| Unit | `cd /home/xlib-harness && go test ./...` | PASS |
| Race | `cd /home/xlib-harness && go test ./... -race -count=1` | PASS |
| Vet | `cd /home/xlib-harness && go vet ./...` | PASS |
| Coverage | `cd /home/xlib-harness && go test ./... -coverprofile=coverage.out -covermode=count && go tool cover -func=coverage.out` | PASS, total 100.0% |
| CI Bundle | `cd /home/xlib-harness && make ci` | PASS |
| Benchmark | `cd /home/xlib-harness && go test -bench=. ./...` | PASS |
| Diff Hygiene | `cd /home/xlib-harness && git diff --check` | PASS |

## Coverage Evidence

`go tool cover -func=coverage.out` reported total 100.0%. Every function in `main.go` and `internal/harness/harness.go` is covered at 100.0%.

## Benchmark Evidence

```text
BenchmarkGenerate-16             2799    439979 ns/op      25831 B/op       226 allocs/op
BenchmarkCheckFullProfile-16      342   4802818 ns/op     630851 B/op      5576 allocs/op
```

## CI/CD Evidence

- `.github/workflows/ci.yml` runs docs contract, Go validation via `make ci`, `xlibgate@v1.0.0` imports/gomod/baseline trust checks, and gitleaks secret scan.
- `.github/workflows/release.yml` runs `make ci`, trust checks, and GitHub Release creation on `v*` tags.
- Local tag `v0.1.4` points at `/home/xlib-harness@fb097be5eff4`.
- GitHub Actions Release run `27854835195` completed successfully for `fb097be5eff4cae70ee77f0330e044f27317d92d`: <https://github.com/ZoneCNH/xlib-harness/actions/runs/27854835195>.
- GitHub Release `v0.1.4` is published as a non-draft, non-prerelease release: <https://github.com/ZoneCNH/xlib-harness/releases/tag/v0.1.4>.

## Security Evidence

Local secret pattern scan found no credential, private key, account ID, exchange key, or live trading configuration. Matches were limited to documentation words such as "Secret scan" and internal `token` variable names.
