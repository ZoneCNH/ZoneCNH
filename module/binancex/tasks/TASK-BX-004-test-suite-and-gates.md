# TASK-BX-004 Test Suite & Quality Gates

## Objective

补全 `adapter_test.go` 测试覆盖，实现 mock MarketDataFeed，运行全部质量门禁。

## Scope

- Mock MarketDataFeed 实现
- 接口契约测试（所有方法签名、channel 方向）
- 类型校验测试
- 依赖边界检查

## Covers

- NFR-BX-001 (mock-based testing)
- NFR-BX-002 (dependency boundary)

## Deliverables

- `adapter_test.go` 含 mock feed + 接口合规测试 + 类型测试
- 覆盖率 >= 80%
- Dependency boundary check 通过

## Acceptance Criteria

1. Mock MarketDataFeed 实现全部 6 个方法
2. `go test ./... -count=1` → PASS
3. `go vet ./...` → 零警告
4. `go list -deps ./... | grep -v std | grep -v runtime-patches` → 仅 domain-market
5. 接口编译期合规（`var _ MarketDataFeed = (*mockFeed)(nil)`）

## Dependencies

- TASK-BX-001, TASK-BX-002, TASK-BX-003
