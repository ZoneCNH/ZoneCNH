# Binance 模块未修复问题清单

> **来源**：`report/binance/00-summary.md` ~ `04-test-report.md` 深度分析（2026-07-05）
> **验证日期**：2026-07-05（已对 `/home/workspace/binance` 当前 HEAD 逐一核实）
> **修复分支**：`fix/report-followup`（worktree: `.worktree/workspaces/fix/report-followup`）
> **已移除/已修复项**：adapter.go 交易适配器整体移除（ADR-009）→ 原 #1/#4/#5/#7 自动消解；saveSnapshot 忽略已修复；soak 测试已加 env skip 守卫。

## 状态图例

- `[x]` 已修复（20 轮交叉检查验证通过）
- `[~]` 修复中
- `[ ]` 未修复
- `[—]` accepted risk

---

## P1 — 高优先级（限频/控制面未接线）

### TODO-01 ThrottleManager.Allow() 未接入实际请求路径 — `[x]`

- **严重度**：🟠 高
- **位置**：`internal/client/throttle.go` + `runtime.go:229` + `history_rest.go` fetchPage + `exchangeinfo_fetch.go`
- **修复**：新增 `awaitThrottle(ctx, throttle, kind, weight)` nil-safe 辅助函数；fetchPage 调用 `awaitThrottle(ColdStart)` + `RecordSuccess`/`RecordBackoff`；exchangeinfo_fetch 调用 `awaitThrottle(Repair)` + `RecordSuccess`/`RecordBackoff`；runtime.go 通过 `ThrottleInjector` 接口 + 类型断言注入 throttle 到 HistoryFetcher。
- **验证**：R1-R5 确认 Allow/RecordSuccess/RecordBackoff 在非测试代码命中。

### TODO-02 WeightGate / RetryBudget / ClockSkewDetector 未装配 — `[x]`

- **严重度**：🟠 高
- **位置**：`internal/server/assembly/assemble.go:133-160`
- **修复**：构造 `NewRetryBudget`/`NewWeightGate`/`NewClockSkewDetector` 并注入 `ControlPlaneBindings`（Retry/Weight/Skew 非 nil）。
- **验证**：R6-R8 确认构造函数调用 + bindings 注入 + 无 nil。

### TODO-03 AIMD 退避无上限恢复时间 — `[x]`

- **严重度**：🟡 中
- **位置**：`internal/client/throttle.go:39-47,188,256,292-310`
- **修复**：新增 `aimdRecoveryWindow=60s` + `lastBackoffAt` 字段 + `maybeTimeRecover` 方法；Allow 时检查，超 60s 无 backoff 则按 10% 比例向 targetRate 回升。
- **验证**：R9 确认 maybeTimeRecover + lastBackoffAt 存在。

---

## P2 — 中优先级（HTTP 限频/重连/解析）

### TODO-04 429 不读 Retry-After 头 — `[x]`

- **严重度**：🟡 中
- **位置**：`internal/client/history_rest.go:255-261`
- **修复**：解析 `resp.Header.Get("Retry-After")`，成功则按该秒数 sleep，否则指数退避。
- **验证**：R10 确认 Retry-After 解析。

### TODO-05 418（IP 自动封禁）全仓零处理 — `[x]`

- **严重度**：🟡 中
- **位置**：`internal/client/history_rest.go:21-22,243-252`
- **修复**：新增 `ErrIPBanned` 哨兵错误；418 时 `slog.Error` + 立即返回不重试。
- **验证**：R11 确认 ErrIPBanned + 418 处理。

### TODO-06 WebSocket 重连退避无 jitter — `[x]`

- **严重度**：🟡 中
- **位置**：`internal/client/spot.go:421-425`
- **修复**：`jittered := time.Duration(float64(backoff) * (0.8 + 0.4*rand.Float64()))`。
- **验证**：R12 确认 jitter 公式。

### TODO-07 exchangeinfo_option strike 解析失败默认 0 — `[x]`

- **严重度**：🟡 中
- **位置**：`internal/client/exchangeinfo_option.go:80-85`
- **修复**：解析失败时 `slog.Warn` + `continue` 跳过。
- **验证**：R13 确认 error 检查 + slog.Warn。

### TODO-08 kline 数组解析 len(row)<12 静默跳过 — `[x]`

- **严重度**：🟡 中
- **位置**：`internal/client/history_rest.go:318-319`
- **修复**：`slog.Warn` 记录跳过的坏行 + 字段数。
- **验证**：R14 确认 slog.Warn。

### TODO-09 wsActiveConns 全局而非 per-connector — `[x]`

- **严重度**：🟡 中
- **位置**：`internal/client/spot.go:244` + `internal/client/stream_control.go`
- **修复**：`wsActiveConns`/`wsConnRejected` 改为 `SpotConnector` 实例字段（per-instance）；删除包级全局变量；`Snapshot()` 读实例字段。
- **验证**：R15 确认实例字段。

### TODO-10 fan-in goroutine 依赖 connector 退出关闭 channel — `[x]`

- **严重度**：🟡 中
- **位置**：`internal/client/runtime.go:352-423`
- **修复**：fan-in goroutine 改为 select on `ctx.Done()` + ch；`sync.Once` 保护 close(merged)；`context.AfterFunc` 5s grace period 后强制 close。
- **验证**：R16 确认 closeOnce + AfterFunc + grace period。

---

## P3 — 低优先级（错误忽略/告警）

### TODO-11 http_ingest_endpoint 编码错误被忽略 — `[x]`

- **修复**：`internal/client/http_ingest_endpoint.go:47` 检查 Encode error 返回。
- **验证**：R17。

### TODO-12 catalog.go Add 错误被忽略 — `[x]`

- **修复**：`internal/client/catalog.go:82-83,97-98` 检查 `c.Add(e)` + `slog.Warn`。
- **验证**：R17b。

### TODO-13 spot.go collect 事件丢弃无回压告警阈值 — `[x]`

- **修复**：`internal/client/stream_control.go` `noteBackpressureDrop` 中累计 drops 每 1000 倍数触发 `slog.Error`。
- **验证**：R18 确认 backpressureDropAlertThreshold + slog.Error。

### TODO-14 CSRF token 与 Admin token 同值 — `[—]`

- **状态**：accepted risk（machine-to-machine admin 场景，已用 `subtle.ConstantTimeCompare` 防时序攻击）。

---

## 测试修复

### TODO-15 e2e TestE2E_ConflictingPayload_Reject 测试逻辑缺陷 — `[x]`

- **位置**：`test/e2e/e2e_test.go:115-116`
- **修复**：修改 `req2.Payload` 内容（而非仅改 PayloadHash 字段），使 server 重算后 hash 不同 → 触发 terminal_conflict。
- **验证**：R19 + `go test -tags=e2e` PASS。

### TODO-16 whitelistclient 覆盖率不足 — `[x]`

- **修复**：新增 11 个测试函数覆盖 refreshFull/refreshIncremental 错误分支。
- **覆盖率提升**：refreshFull 77.8%→100%，refreshIncremental 69.6%→95.7%，包整体 80.2%→85.4%。
- **验证**：R20 确认 11 个新测试函数。

---

## 验证总结

| 维度 | 结果 |
|------|------|
| `go build ./...` | ✅ 通过 |
| `go vet ./...` | ✅ 零告警 |
| `go test ./...` | ✅ 全部 PASS（含 client 85s） |
| `go test -tags=e2e` | ✅ PASS（原失败已修复） |
| `go test -tags=depth` | ✅ PASS |
| `go test -tags=chaos` | ✅ PASS |
| `go test -tags=security` | ✅ PASS |
| `go test -race`（核心包） | ✅ 无数据竞争 |
| 20 轮交叉检查 | ✅ 16/16 TODO 验证通过 |
