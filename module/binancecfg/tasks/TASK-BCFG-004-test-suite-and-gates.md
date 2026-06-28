# TASK-BCFG-004 Test Suite & Quality Gates

## Objective

补全 `config_test.go` 测试覆盖，运行全部质量门禁。

## Scope

- 单元测试覆盖所有 FR/BR 路径
- `go test ./... -count=1 -cover` 通过
- `go vet ./...` 零警告
- `go list -deps` 验证依赖边界

## Covers

- NFR-BCFG-001 (独立可测试)
- NFR-BCFG-002 (依赖边界：仅 stdlib + binance + binancex)

## Deliverables

- `config_test.go` 含 LoadConfig/DefaultConfig/Validate/ServerConfig/FeedConfig/parseEnv 测试
- 覆盖率 >= 80%
- Dependency boundary check 通过

## Acceptance Criteria

1. `go test ./... -count=1` → PASS
2. `go test ./... -cover` → >= 80%
3. `go vet ./...` → 零警告
4. `go list -deps ./... | grep -v std | grep -v runtime-patches` → 仅 binance + binancex

## Dependencies

- TASK-BCFG-001, TASK-BCFG-002, TASK-BCFG-003
