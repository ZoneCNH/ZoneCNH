# Context Packet: TASK-DOMAINX-006

## Current Task

**TASK-DOMAINX-006**: CI 门禁 + Benchmark + 文档 + go.mod

## Related Spec

`module/domainx/SPEC.md` §15 Dependencies, §16 Testing（Benchmark）, §17 Performance, §18-20（Observability/Security/CI）, §22 Release DoD

## Related Requirements

### NFRs（全部 10 项）
- NFR-001: BenchmarkNewOrder < 500ns
- NFR-002: BenchmarkMarketValue < 100ns
- NFR-003: BenchmarkJSONRoundTrip < 1μs
- NFR-004: 覆盖率 ≥ 80%
- NFR-005: go build 零错误
- NFR-006: go test -race 零 data race
- NFR-007: go vet 零警告
- NFR-008: golangci-lint 零错误
- NFR-009: gitleaks 零命中
- NFR-010: Benchmark 零 allocs（栈分配）

## Project Rules
- go.mod 只依赖 stdlib + `github.com/ZoneCNH/decimalx`
- 禁止依赖 L1 运行时模块
- doc.go 含包级 godoc
- README 含：定位、类型概览、快速开始、API 参考

## Scope

只实现：
- `go.mod` + `go.sum`
- `benchmark_test.go`：4 项 Benchmark
- `doc.go`：包级文档
- `README.md`：模块完整文档
- `CHANGELOG.md`：v1.0.0 初始发布
- `LICENSE`：MIT

## Out of Scope
- 不编写 example_test.go（后续 Task）
- 不配置 CI workflow 文件（由仓库级 CI 覆盖）
- 不做集成测试（无外部依赖）

## Files to Modify

| 文件 | 操作 | 说明 |
|------|------|------|
| `go.mod` | 新增 | module + decimalx 依赖 |
| `go.sum` | 新增 | go mod tidy 自动生成 |
| `benchmark_test.go` | 新增 | 4 项 Benchmark |
| `doc.go` | 新增 | 包级 godoc |
| `README.md` | 新增 | 模块文档 |
| `CHANGELOG.md` | 新增 | v1.0.0 |
| `LICENSE` | 新增 | MIT |

## Implementation Notes

- go.mod：`module github.com/ZoneCNH/domainx` + `go 1.23` + `require github.com/ZoneCNH/decimalx v1.0.0`
- Benchmark 命名：`BenchmarkNewOrder`, `BenchmarkNewFill`, `BenchmarkMarketValue`, `BenchmarkJSONRoundTrip`
- Benchmark 使用 `b.ReportAllocs()` 验证零分配
- README 参考 clickhousex/README.md 格式

## Acceptance Criteria

- [ ] go build ./... 通过
- [ ] go test ./... -race 通过
- [ ] 覆盖率 ≥ 80%
- [ ] go vet 零警告
- [ ] golangci-lint run 零错误
- [ ] gitleaks detect 零命中
- [ ] Benchmark 在预算内
- [ ] go test -benchmem 零 allocs

## Validation Commands

```bash
cd /home/workspace/domainx
go mod tidy
go build ./...
go test ./... -race -count=1
go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out
go vet ./...
golangci-lint run
gitleaks detect --no-git
go test -bench=. -benchmem -count=3 ./...
```

## Required Output

1. CI Gate 全部通过证据
2. Benchmark 结果对比预算
3. 覆盖率报告
4. README 完整性检查
