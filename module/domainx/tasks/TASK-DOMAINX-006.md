# TASK-DOMAINX-006

> CI 门禁 + Benchmark + 文档 + go.mod

---

```yaml
task_id: TASK-DOMAINX-006
module: domainx
scope: "配置 go.mod、Benchmark 测试、CI 门禁、README、CHANGELOG、godoc"
spec_ref:
  - "module/domainx/SPEC.md#NFR-001"
  - "module/domainx/SPEC.md#NFR-002"
  - "module/domainx/SPEC.md#NFR-003"
  - "module/domainx/SPEC.md#NFR-004"
  - "module/domainx/SPEC.md#NFR-005"
  - "module/domainx/SPEC.md#NFR-006"
  - "module/domainx/SPEC.md#NFR-007"
  - "module/domainx/SPEC.md#NFR-008"
  - "module/domainx/SPEC.md#NFR-009"
  - "module/domainx/SPEC.md#NFR-010"
files:
  - "go.mod"
  - "go.sum"
  - "benchmark_test.go"
  - "doc.go"
  - "README.md"
  - "CHANGELOG.md"
  - "LICENSE"
acceptance_criteria:
  - "NFR-001: BenchmarkNewOrder < 500ns"
  - "NFR-002: BenchmarkMarketValue < 100ns"
  - "NFR-003: BenchmarkJSONRoundTrip < 1µs"
  - "NFR-004: 覆盖率 ≥ 80%"
  - "NFR-005: go build ./... 零错误"
  - "NFR-006: go test -race 零 data race"
  - "NFR-007: go vet 零警告"
  - "NFR-008: golangci-lint 零错误"
  - "NFR-009: gitleaks 零命中"
  - "NFR-010: Benchmark 零 allocs（栈分配）"
depends_on:
  - "TASK-DOMAINX-001"
  - "TASK-DOMAINX-002"
  - "TASK-DOMAINX-003"
  - "TASK-DOMAINX-004"
  - "TASK-DOMAINX-005"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Verification |
|-------------|-------------|-------------|
| NFR-001 | Order 构造 < 500ns | BenchmarkNewOrder |
| NFR-002 | MarketValue < 100ns | BenchmarkMarketValue |
| NFR-003 | JSON round-trip < 1µs | BenchmarkJSONRoundTrip |
| NFR-004 | 覆盖率 ≥ 80% | go tool cover |
| NFR-005 | 编译通过 | go build |
| NFR-006 | 零 data race | go test -race |
| NFR-007 | 零 vet 警告 | go vet |
| NFR-008 | 零 lint 错误 | golangci-lint |
| NFR-009 | 零 secret 泄露 | gitleaks |
| NFR-010 | 零 allocs | go test -benchmem |

## Non-scope

- 不编写 example_test.go（后续 Task 或 P2）

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| — | Benchmark | BenchmarkNewOrder: 单次 Order 构造 |
| — | Benchmark | BenchmarkNewFill: 单次 Fill 构造 |
| — | Benchmark | BenchmarkMarketValue: Position.MarketValue() |
| — | Benchmark | BenchmarkJSONRoundTrip: Order Marshal+Unmarshal |
| — | CI | go test -race ./... |
| — | CI | go vet ./... |
| — | CI | golangci-lint run |

## Implementation Notes

- go.mod 只依赖 stdlib + decimalx（L2.5 约束）
- doc.go 包含包级 godoc 注释
- README.md 包含：模块定位、类型概览（Order/Fill/Position/Exposure）、快速开始、API 参考
- CHANGELOG.md 记录 v1.0.0 初始发布
