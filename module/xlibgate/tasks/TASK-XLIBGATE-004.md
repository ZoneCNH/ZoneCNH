# TASK-XLIBGATE-004

> check baseline 实现

---

```yaml
task_id: TASK-XLIBGATE-004
module: xlibgate
scope: "实现 check baseline 命令：检查所有模块 Go 版本一致性"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-003"
  - "module/xlibgate/SPEC.md#BR-003"
files:
  - "check_baseline.go"
  - "check_baseline_test.go"
acceptance_criteria:
  - "AC-003: 版本一致 → pass，exit 0"
  - "AC-003: 版本不匹配 → 输出模块列表和版本差异，exit 1"
  - "AC-003: 无 --expected → error，exit 2"
depends_on:
  - "TASK-XLIBGATE-001"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                                     | Acceptance Criteria |
| ----------- | ----------------------------------------------- | ------------------- |
| FR-003      | check baseline：Go 版本一致性                   | 3 个 WHEN/THEN 场景 |
| BR-003      | baseline 从配置或 --expected 参数获取，不硬编码 | 参数和配置 fallback |

## Non-scope

- 不实现自动升级 go 版本（只读检查）
- 不检查 go.mod 其他指令（require/replace/exclude）
- 不实现跨仓库版本比较
- 不处理 vendor 目录中的 go.mod

## Test Plan

| Test Case | Type      | Description                             |
| --------- | --------- | --------------------------------------- |
| TC-003    | Unit      | 版本一致：exit 0                        |
| TC-003    | Unit      | 版本不匹配：exit 1，输出模块列表        |
| TC-003    | Unit      | 无 --expected：exit 2                   |
| NFR-004   | Benchmark | `BenchmarkCheckBaseline` — 50 模块 < 5s |

## Implementation Notes

- 遍历目录查找所有 `go.mod`，提取 `go` 指令版本
- 与 `--expected` 参数比较
- BR-003 要求 expected 值从配置或参数获取，不硬编码

## Implementation Plan

| Step | Description                                             | Deliverables        | Verification    |
| ---- | ------------------------------------------------------- | ------------------- | --------------- |
| 1    | 实现 `check_baseline.go`：遍历 go.mod → 提取版本 → 比较 | `check_baseline.go` | TC-003 全部通过 |

### Risk Assessment

| Risk            | Probability | Impact | Mitigation |
| --------------- | ----------- | ------ | ---------- |
| go.mod 解析错误 | Low         | Low    | 标准库解析 |
