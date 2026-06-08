# TASK-CONFIGX-007

> Watch（可选）：文件监控、变更回调、并发安全

---

```yaml
task_id: TASK-CONFIGX-007
module: configx
scope: "实现 Watch(key, callback) 方法，监控配置文件变更并触发回调"
spec_ref:
  - "specs/configx/SPEC.md#FR-005"
files:
  - "watch.go"
  - "watch_test.go"
acceptance_criteria:
  - "文件变更且通过校验时触发 callback"
  - "Watch 的 key 不存在时返回错误"
  - "并发 Get + Watch 无 data race"
depends_on:
  - "TASK-CONFIGX-005"
  - "TASK-CONFIGX-006"
estimated_effort: "2h"
priority: P1
status: pending
```

---

## Requirements Covered

| Requirement | Description | Acceptance Criteria |
|---|---|---|
| FR-005 | Watch：配置变更→callback，key 不存在→错误 | 2 个 WHEN/THEN 场景 |

## Test Plan

| Test Case | Type | Description |
|---|---|---|
| TC-004 | Unit | Watch 配置监听：文件变更触发 callback |
| — | Unit | Watch key 不存在：返回错误 |
| — | Unit | 并发 Get + Watch：无 data race |

## Implementation Notes

- 使用 fsnotify 或轮询方式监控文件变更
- 文件变更后重新加载 → 校验 → 更新 data → 触发 callback
- 提供 `StopWatch()` 方法关闭监控

## Implementation Plan

| Step | Description | Deliverables | Verification |
|---|---|---|---|
| 1 | 实现文件监控：使用 fsnotify 或轮询检测文件变更 | `watch.go` | `go build ./...` 通过 |
| 2 | 实现变更处理：文件变更 → 重新加载 → 校验 → 更新 data | `watch.go` | `go test ./... -run TestWatchReload` 通过 |
| 3 | 实现 callback 触发和 `StopWatch()` | `watch.go` | TC-004 通过 |
| 4 | 并发安全验证 | `watch_test.go` | `go test -race ./... -run TestWatch` 通过 |

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| fsnotify 依赖引入 | Medium | Low | 可用轮询替代 |
| Watch 回调阻塞 | Low | Medium | callback 在独立 goroutine 中执行 |
