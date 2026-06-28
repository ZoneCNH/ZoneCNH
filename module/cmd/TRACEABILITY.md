# cmd 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-29
Source: `patches/cmd/main.go`
Runtime: `github.com/ZoneCNH/runtime-patches/cmd`

---

## §1 功能需求追溯（FR）

| FR ID | Requirement | TC ID(s) | Task | Verification | Status |
| ----- | ----------- | -------- | ---- | ------------ | ------ |
| FR-CMD-001 | Run() — 可测试入口点：验证配置 → 组装依赖 → 构造 server → 连接 feed → 阻塞等待信号 → 优雅关闭 | TC-CMD-001 | TASK-CMD-001 | `go test ./... -run TestRun` | ✅ |
| FR-CMD-002 | 配置验证作为第一步，无效配置立即返回错误 | TC-CMD-002 | TASK-CMD-002 | `go test ./... -run TestRunInvalidConfig` | ✅ |
| FR-CMD-003 | assembly.Assemble 注入中间件后构造 IngestServer | TC-CMD-003 | TASK-CMD-003 | `go test ./... -run TestRunAssembly` | ✅ |
| FR-CMD-004 | 信号处理：SIGINT/SIGTERM 触发优雅关闭 | TC-CMD-004 | TASK-CMD-004 | `go test ./... -run TestSignalHandling` | ✅ |
| FR-CMD-005 | 优雅关闭：context 取消后等待 DrainTimeout，defer Feed.Close() | TC-CMD-005 | TASK-CMD-005 | `go test ./... -run TestGracefulShutdown` | ✅ |
| FR-CMD-006 | main() 只处理 os.Exit(1)，所有逻辑委托给 Run() | TC-CMD-006 | TASK-CMD-006 | `go test ./... -run TestMainLogic` | ✅ |

---

## §2 业务规则追溯（BR）

| BR ID | Rule | TC ID(s) | Task | Verification | Status |
| ----- | ---- | -------- | ---- | ------------ | ------ |
| BR-CMD-001 | 所有依赖注入：Feed/Validator/Idempotency/Dispatcher 通过 assembly.ServerDeps 注入，测试提供 mock | TC-CMD-001 | TASK-CMD-007 | injectable deps test | ✅ |
| BR-CMD-002 | Feed.Connect 失败立即返回错误，不进入 serve loop | TC-CMD-001 | TASK-CMD-008 | connect failure test | ✅ |
| BR-CMD-003 | Feed.Errors() channel 收到非 nil 错误时触发 shutdown | TC-CMD-004 | TASK-CMD-009 | feed error shutdown test | ✅ |
| BR-CMD-004 | ShutdownTimeout 通过 context.WithTimeout 强制执行，不无限等待 | TC-CMD-005 | TASK-CMD-010 | shutdown timeout test | ✅ |

---

## §3 非功能需求追溯（NFR）

| NFR ID | Category | Requirement | Task | Verification | Status |
| ------ | -------- | ----------- | ---- | ------------ | ------ |
| NFR-CMD-001 | 可观测性 | 结构化日志通过 slog，含 component 标签，启动/停止/错误均记录 | TASK-CMD-011 | log output check | ✅ |
| NFR-CMD-002 | 错误上下文 | 所有错误用 fmt.Errorf wrapping 保留调用链（"cmd: invalid config: %w" / "cmd: feed connect failed: %w"） | TASK-CMD-012 | error wrapping test | ✅ |

---

## §4 TC -> FR 反向追溯

| TC ID | Covers FR(s) | Command |
| ----- | ------------ | ------- |
| TC-CMD-001 | FR-CMD-001, BR-CMD-001, BR-CMD-002 | `go test ./... -run TestRun` |
| TC-CMD-002 | FR-CMD-002 | `go test ./... -run TestRunInvalidConfig` |
| TC-CMD-003 | FR-CMD-003 | `go test ./... -run TestRunAssembly` |
| TC-CMD-004 | FR-CMD-004, BR-CMD-003 | `go test ./... -run TestSignalHandling` |
| TC-CMD-005 | FR-CMD-005, BR-CMD-004 | `go test ./... -run TestGracefulShutdown` |
| TC-CMD-006 | FR-CMD-006 | `go test ./... -run TestMainLogic` |

---

## §5 全局 AC 注册表

| AC ID | FR/BR Ref | Criterion | Verification | Status |
| ----- | --------- | --------- | ------------ | ------ |
| AC-CMD-001 | FR-CMD-001 | Run() 6 阶段有序执行：validate → assemble → construct → connect → serve → drain | TC-CMD-001 | ✅ |
| AC-CMD-002 | FR-CMD-002, BR-CMD-002 | cfg.Validate() 失败 → Run() 返回 wrapped error，Feed.Connect 不执行 | TC-CMD-002 | ✅ |
| AC-CMD-003 | FR-CMD-003 | assembly.Assemble 成功 → IngestServer 构造成功 | TC-CMD-003 | ✅ |
| AC-CMD-004 | FR-CMD-004~005, BR-CMD-003~004 | SIGINT/SIGTERM/Feed error 触发 cancel → drainCtx 超时强制返回 → Feed.Close() 执行 | TC-CMD-004, TC-CMD-005 | ✅ |
| AC-CMD-005 | FR-CMD-006 | main() 仅 3 行：LoadConfig → ServerDeps → Run，Run 失败 os.Exit(1) | TC-CMD-006 | ✅ |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 6 | 6 | 100% |
| BR (业务规则) | 4 | 4 | 100% |


| NFR (非功能需求) | 2 | 2 | 100% |
| AC (验收标准) | 5 | 5 | 100% |
| TC (测试用例) | 6 | 6 | 100% |
| **合计** | **23** | **23** | **100%** |

---

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-06-29 | Goal 管线初始化：从 `patches/cmd/main.go` 提取 FR/BR/NFR，创建完整 §1-§7 追溯矩阵 |
