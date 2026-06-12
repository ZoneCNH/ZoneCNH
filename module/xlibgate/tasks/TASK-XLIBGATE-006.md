# TASK-XLIBGATE-006

> check all 实现 + 输出格式

---

```yaml
task_id: TASK-XLIBGATE-006
module: xlibgate
scope: "实现 check all 命令（聚合所有子检查）和统一输出格式"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-005"
  - "module/xlibgate/SPEC.md#FR-006"
  - "module/xlibgate/SPEC.md#BR-001"
  - "module/xlibgate/SPEC.md#BR-005"
  - "module/xlibgate/SPEC.md#BR-006"
  - "module/xlibgate/SPEC.md#BR-007"
files:
  - "check_all.go"
  - "output.go"
  - "check_all_test.go"
acceptance_criteria:
  - "AC-005: 全部 pass → exit 0；任一 fail 且无 error → exit 1；任一 error → exit 2"
  - "AC-005: checks[] 含全部 5 个子检查条目（含 pass 项，非仅失败项）"
  - "AC-006: 默认 human-readable（含颜色），--output json 含 status/checks[]/summary"
  - "AC-006: --artifact <path> 写入文件"
  - "AC-007: exit code 映射：pass→0, fail→1, error→2（error 优先于 fail）"
  - "AC-009: gitleaks 可用→执行扫描，命中→fail（含文件路径/行号/规则），不可用→error"
depends_on:
  - "TASK-XLIBGATE-002"
  - "TASK-XLIBGATE-003"
  - "TASK-XLIBGATE-004"
  - "TASK-XLIBGATE-005"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-005 | check all：聚合所有子检查 | 3 个 WHEN/THEN 场景 |
| FR-006 | 输出格式：统一 JSON/text | 格式化输出 |
| BR-001 | 标准化 exit code：0=pass, 1=fail, 2=error | exit code 映射 |
| BR-005 | secret 扫描使用 gitleaks | gitleaks 集成调用 |
| BR-006 | check all 必须执行所有子检查 | 部分失败后继续 |
| BR-007 | JSON 输出含 machine-readable status 字段 | JSON 字段完整性 |

## Non-scope

- 不实现配置文件热更新
- 不实现子检查并行执行（顺序执行，BR-006 要求完整覆盖）
- 不实现 gitleaks 深度定制（使用默认配置，BR-005 委托）
- 不实现 HTML/PDF 输出格式（仅 JSON + human-readable text）
- 不实现输出结果缓存或增量检查

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-004 | Unit | 全部通过：exit 0 |
| TC-004 | Unit | 任一失败：exit 1（部分失败后继续） |
| TC-005 | Unit | 内部错误：exit 2（error 后继续，error 优先 fail） |
| TC-007 | Unit | JSON 输出含 status/checks[]/summary 字段 |
| TC-008 | Unit | gitleaks 检测 secret → fail（含文件路径/行号/规则） |
| NFR-001 | Benchmark | `BenchmarkCheckAll` — 50 模块 < 30s |
| NFR-005 | Benchmark | `BenchmarkReportJSON` — < 100ms |
| NFR-006 | Profiling | `go test -memprofile` — < 100MB |
| NFR-007 | CI Gate | `go tool cover -func` ≥ 80% |
| NFR-008 | CI Gate | `gitleaks detect --no-git` 零命中 |
| NFR-009 | Review | 错误消息仅含文件路径和行号，不含敏感数据 |

## Implementation Notes

- `check_all` 依次调用 imports/gomod/baseline/release/secret_scan
- `output.go` 统一格式化输出
- BR-006：任一子检查失败不中断，继续执行所有子检查
- SPEC §18 日志事件（xlibgate.check.*）在本 Task 中输出

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现 `check_all.go`：聚合所有子检查 | `check_all.go` | TC-004, TC-005 全部通过 |
| 2 | 实现 `output.go`：统一输出格式（JSON + text） | `output.go` | TC-007 通过 |
| 3 | 实现 gitleaks 集成 | `check_all.go` | TC-008 通过 |
| 4 | 实现 --artifact 文件写入 | `output.go` | artifact 文件内容正确 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| 子检查执行顺序 | Low | Low | 顺序执行，继续执行所有子检查（BR-006） |
| gitleaks 不可用 | Medium | Medium | 降级为 error（exit 2），不阻塞门禁 |
