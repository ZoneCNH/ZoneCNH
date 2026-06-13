# TASK-CLICKHOUSEX-007

> 仓库初始化：go.mod、CI、README、CHANGELOG、DoD

---

```yaml
task_id: TASK-CLICKHOUSEX-007
module: clickhousex
scope: "初始化仓库结构：go.mod、CI Gate 配置、README、CHANGELOG、Release DoD"
spec_ref:
  - "module/clickhousex/SPEC.md#20"
  - "module/clickhousex/SPEC.md#22"
files:
  - "go.mod"
  - "go.sum"
  - "README.md"
  - "CHANGELOG.md"
  - "LICENSE"
  - "doc.go"
  - ".github/workflows/ci.yml"
  - "benchmark_test.go"
  - "example_test.go"
acceptance_criteria:
  - "NFR-008: 测试覆盖率 ≥ 80%"
  - "NFR-009: go build 通过"
  - "NFR-010: go test -race 通过"
  - "NFR-011: go vet 通过"
  - "NFR-012: golangci-lint 通过"
  - "NFR-013: gitleaks 零命中"
  - "NFR-015: 无直接依赖 configx"
  - "NFR-018: 集成测试 ClickHouse 不可达时 skip"
depends_on:
  - "TASK-CLICKHOUSEX-001"
  - "TASK-CLICKHOUSEX-002"
  - "TASK-CLICKHOUSEX-003"
  - "TASK-CLICKHOUSEX-004"
  - "TASK-CLICKHOUSEX-005"
  - "TASK-CLICKHOUSEX-006"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|-------------|-------------|---------------------|
| §20 CI Gate | 编译/测试/覆盖率/vet/lint/secret/benchmark | NFR-008~NFR-015 |
| §22 Release DoD | godoc/示例/CHANGELOG/README/覆盖率/race/vet/lint/AC/Edge Case | 全部 15 项检查 |
| NFR-018 | 集成测试条件执行 | CI gate |

## Non-scope

- 不发布到 pkg.go.dev（由 CI 自动触发）
- 不配置 Docker 环境
- 不编写 Helm chart

## Test Plan

| Test Case | Type | Description |
|-----------|------|-------------|
| — | CI | `go build ./...` 通过 |
| — | CI | `go test ./... -race -count=1` 通过 |
| — | CI | `go test ./... -coverprofile=.coverage/cover.out` ≥ 80% |
| — | CI | `go vet ./...` 无警告 |
| — | CI | `golangci-lint run` 无错误 |
| — | CI | `gitleaks detect --no-git` 零命中 |
| — | CI | `go list -deps ./... | grep configx` 空 |
| — | CI | `go test -tags=integration ./...` 无 CH 时 skip |
| — | Unit | example_test.go 可执行 |
| — | Benchmark | benchmark_test.go 可运行 |

## Implementation Notes

- go.mod module 路径：`github.com/ZoneCNH/clickhousex`
- Go 版本：1.23
- 依赖：`github.com/ClickHouse/clickhouse-go/v2`、`github.com/shopspring/decimal`
- CI 使用 GitHub Actions，参考 kernel 的 ci.yml 模板
- README 包含：模块定位、快速开始、配置说明、API 概览
- CHANGELOG 记录 v1.0.1 变更
- doc.go 包含包级 godoc 注释
