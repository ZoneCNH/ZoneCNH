# TASK-ASM-004 Test Suite & Quality Gates

## Objective

补全 `assembly_test.go` 测试覆盖，运行全部质量门禁。

## Scope

- ServerDeps validate 测试（全 nil/部分 nil/全 valid）
- Assemble 测试（无中间件/有中间件/nil 中间件/多中间件顺序）
- Build 测试（成功/失败路径）
- NopMiddleware 接口合规测试

## Covers

- NFR-ASM-002 (dependency boundary)

## Deliverables

- `assembly_test.go` 含全部覆盖路径
- 覆盖率 >= 80%
- Dependency boundary check 通过

## Acceptance Criteria

1. `go test ./... -count=1` → PASS
2. `go test ./... -cover` → >= 80%
3. `go vet ./...` → 零警告
4. `go list -deps ./... | grep -v std | grep -v runtime-patches` → 仅 binance + binancex

## Dependencies

- TASK-ASM-001, TASK-ASM-002, TASK-ASM-003
