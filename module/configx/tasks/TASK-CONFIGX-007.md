# TASK-CONFIGX-007

> Watch 文件监控、变更回调、并发安全 — ✅ **v1.1.0 已交付**（2026-06-18）

> ✅ **交付状态戳（2026-06-18 v1.1.0 校准）**：本任务原标记"可选"且"v1.0 推迟到 v1.1"。v1.1.0 已通过 `pkg/configx/snapshot.go` + `watch.go` 完整实现，超出原任务范围（额外提供 SnapshotStore、ConfigChangeEvent、Rollback、History、SuccessListener/RejectionListener）。原 fsnotify 方案改为周期性 ticker + Loader.Reload 抽象，保持 stdlib-only。详见 SPEC.md FR-017/FR-018、TRACEABILITY.md v3.1 TC-013/TC-014。

---

```yaml
task_id: TASK-CONFIGX-007
module: configx
scope: "实现 Watch(key, callback) 方法，监控配置文件变更并触发回调"
spec_ref:
  - "module/configx/SPEC.md#FR-005"
  - "module/configx/SPEC.md#FR-017"
  - "module/configx/SPEC.md#FR-018"
files:
  - "watch.go"
  - "watch_test.go"
  - "snapshot.go"
  - "snapshot_test.go"
acceptance_criteria:
  - "文件变更且通过校验时触发 callback"
  - "Watch 的 key 不存在时返回错误"
  - "并发 Get + Watch 无 data race"
depends_on:
  - "TASK-CONFIGX-005"
  - "TASK-CONFIGX-006"
estimated_effort: "2h"
priority: P1
status: completed
delivered_in: v1.1.0
```

---

## Requirements Covered

| Requirement | Description                                           | Acceptance Criteria              |
| ----------- | ----------------------------------------------------- | -------------------------------- |
| FR-017      | ConfigSnapshot/ChangeEvent/Rollback (v1.1.0)          | TC-013：SnapshotStore.Publish/Current/Subscribe/Rollback；no-op fast path（BR-012） |
| FR-018      | Watcher 热更新 + DocGen (v1.1.0)                      | TC-014：Watcher.Start/Stop/Reload/Rollback/History；周期 ticker；reject 保留旧快照 |

## Test Plan

| Test Case | Type | Description                                  | 状态 |
| --------- | ---- | -------------------------------------------- | --- |
| TC-013    | Unit | SnapshotStore.Publish/Current/Subscribe/Rollback；ConfigDiff Add/Remove/Modify；no-op fast path | ✅ 7 用例 |
| TC-014    | Unit | Watcher.Start 同步 Reload + 周期 ticker；Rejection 保留旧快照；Rollback 用 history | ✅ 10 用例 |

## Non-scope

- 不做配置加载（→ TASK-002）
- 不做 schema 校验（校验在变更时复用 TASK-005）
- 不做 fsnotify 文件监控（v1.1.0 改用 ticker + Loader.Reload，保持 stdlib-only；fsnotify 可由调用方驱动 Reload 接入）

## Implementation Notes (v1.1.0 实际实现)

- `pkg/configx/snapshot.go` (212 行)：`SnapshotStore` 基于 `atomic.Pointer[ConfigSnapshot]` 提供并发安全；同 hash 的 reload 不推进版本（no-op fast path，BR-012）；Subscribe 返回幂等 Subscription；Rollback 推进新版本号以便审计。
- `pkg/configx/watch.go` (299 行)：`Watcher` 周期性轮询 + 首次同步 Reload；`WithWatchInterval/History`；`WithRejectionListener/SuccessListener`；reject 保留旧快照；Rollback 复用 history。
- `cmd/configdoc/main.go` + `pkg/configx/docgen.go`：配置文档自动生成（FR-018）。

## Implementation Plan (历史，v1.1.0 实际偏离)

| Step | Description                                                     | Deliverables                          | Verification                              |
| ---- | --------------------------------------------------------------- | ------------------------------------- | ----------------------------------------- |
| 1    | ~~使用 fsnotify 或轮询检测文件变更~~ → v1.1.0 改用 ticker + Loader.Reload | `watch.go`                            | `go build ./...` 通过 ✅                  |
| 2    | 实现变更处理：Reload → Publish → ChangeEvent → Listeners        | `watch.go` + `snapshot.go`            | TC-013/TC-014 通过 ✅                     |
| 3    | 实现 callback 触发和 Stop/History/Rollback                      | `watch.go`                            | TC-014 通过 ✅                            |
| 4    | 并发安全验证                                                    | `watch_test.go` + `snapshot_test.go`  | `go test -race ./...` 通过 ✅             |

### Risk Assessment (v1.1.0 闭环)

| Risk              | Probability | Impact | Mitigation                       | v1.1.0 实际                |
| ----------------- | ----------- | ------ | -------------------------------- | -------------------------- |
| fsnotify 依赖引入 | Medium      | Low    | 可用轮询替代                     | ✅ 用 ticker，无外部依赖   |
| Watch 回调阻塞    | Low         | Medium | callback 在独立 goroutine 中执行 | ✅ 监听器在 store mutex 外执行 |
