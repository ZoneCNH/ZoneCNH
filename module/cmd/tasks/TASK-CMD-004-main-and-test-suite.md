# TASK-CMD-004 main() & Test Suite

## Objective

实现 `main()` 进程入口（仅 os.Exit）和完整测试覆盖。

## Scope

- `main()`: LoadConfig → ServerDeps → Run → os.Exit(1) on error
- 可测试性：所有依赖注入，测试提供 mock
- Test suite: Run() 各阶段和错误路径

## Covers

- FR-CMD-006 (main only os.Exit)
- BR-CMD-001 (dependency injection)

## Deliverables

- `main()` 3 行核心逻辑
- `main_test.go` 含 Run() 测试（mock deps）
- `go vet ./...` 零警告

## Acceptance Criteria

1. main() 仅 LoadConfig + ServerDeps + Run + os.Exit
2. Run() 返回 error → os.Exit(1)
3. Run() 返回 nil → os.Exit(0)（隐式）
4. `go test ./... -count=1` → PASS（mock 覆盖）
5. `go vet ./...` → 零警告
6. 生产 main() 不含测试逻辑或 mock 路径

## Dependencies

- TASK-CMD-001, TASK-CMD-002, TASK-CMD-003
- `runtime-patches/binancecfg` (LoadConfig)
- `runtime-patches/assembly` (ServerDeps)
