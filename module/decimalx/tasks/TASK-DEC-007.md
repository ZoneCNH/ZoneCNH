# TASK-DEC-007: CI gate + golden/benchmark

| 字段 | 值 |
|------|-----|
| 模块 | decimalx |
| 目标版本 | v1.0.0 |
| 关联 FR | §5 发布门禁 + §20 CI Gate |
| 关联 AC | AC-DEC-008 (golden snapshot) |
| 关联 TC | TC-DEC-008 |
| 状态 | Pending |

## 目标

建立完整的 CI 门禁和 golden/benchmark 基础设施，确保 v1.0.0 行为可审计、可复现。

## 验收标准

- CI 全部 gate 通过（单元测试、race、fuzz/property、staticcheck、govulncheck）
- v1 behavior snapshot 固化（golden files）
- Benchmark 基线建立

## 实现要点

- CI Gate 命令：
  - `GOWORK=off go test ./...`
  - `GOWORK=off go test -race ./...`
  - `GOWORK=off go test ./... -fuzz=Fuzz -fuzztime=30s`
  - `GOWORK=off go test ./... -bench=. -run '^$'`
  - `staticcheck ./...`
  - `govulncheck ./...`
- Golden files：`testdata/v1/*.golden`
- Benchmark 目标：
  - Parse（10 位数字）< 1μs
  - String 输出 < 500ns
  - Add/Mul < 500ns
  - JSON Marshal/Unmarshal < 2μs
  - QuoScale < 1μs

## 测试要求

- 所有 fuzz 测试：`FuzzParseRoundTrip`、`FuzzJSONRoundTrip`、`FuzzAddSubInvariant`、`FuzzQuantizeRescale`
- Race 测试：并发读取同一 Decimal/Money
- Golden snapshot 行为一致
- Benchmark 基线达标
