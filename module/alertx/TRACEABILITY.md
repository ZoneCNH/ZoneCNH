# alertx 需求追溯矩阵

> 更新：2026-06-26
> 来源：module/alertx/SPEC.md v1.0.0（Status: Approved）
> 规范：docs/governance/TRACEABILITY.md
> 状态约定：⏳ = 已定义待实现（S8 Code 阶段验证）；✅ = 已实现并通过验证

---

## §1 功能需求追溯（FR）

| FR ID | Requirement | AC ID(s) | TC ID(s) | Task ID(s) | Verification | Status |
| ----- | ----------- | -------- | -------- | ---------- | ------------ | ------ |
| FR-001 | 规则引擎 — 加载 YAML DSL 规则，评估输入事件匹配规则产出 AlertEvent；非法 DSL 阻塞启动 | AC-001 | TC-001, TC-002, TC-003 | TASK-002 | `go test ./... -run TestRuleEvaluator` | ⏳ |
| FR-002 | 去重抑制 — 同 DedupKey 在 SuppressWindow 内抑制；空 DedupKey 派生 | AC-002 | TC-004 | TASK-003 | `go test ./... -run TestDeduper` | ⏳ |
| FR-003 | 分级 — critical 路由 paging 渠道；warning 通知不 paging；info 仅日志 | AC-003 | TC-005 | TASK-004 | `go test ./... -run TestSeverityRouting` | ⏳ |
| FR-004 | 通知路由 — 按 severity 路由；失败指数退避 3 次；通知幂等；未知 channel 阻塞启动 | AC-004 | TC-006, TC-011 | TASK-005, TASK-008 | `go test ./... -run TestNotifier` | ⏳ |
| FR-005 | 生命周期 — firing→suppressed→resolved 状态机；抖动 pending 窗口；ResolvedAt 记录 | AC-005 | TC-007 | TASK-004 | `go test ./... -run TestLifecycle` | ⏳ |
| FR-006 | 健康导出 — health.JSON 四字段 schema；渠道不可达 component live=false 不 panic；自观测指标 | AC-006 | TC-018 | TASK-007 | `go test ./... -run TestHealth` | ⏳ |
| FR-007 | 规则热加载 — 文件变更触发重载；校验通过原子替换；校验失败保留旧规则 | AC-007 | TC-015, TC-019 | TASK-002 | `go test ./... -run TestRuleReload` | ⏳ |

---

## §2 业务规则追溯（BR）

| BR ID | Rule | TC ID(s) | Verification | Status |
| ----- | ---- | -------- | ------------ | ------ |
| BR-001 | 告警不丢失：评估产出的 AlertEvent 必须进入去重/通知流程，不得静默丢弃 | TC-020 | CI gate `alert-no-loss-check` 阻塞；递增 `foundationx_alertx_alerts_dropped` counter | ⏳ |
| BR-002 | 通知幂等：同一 DedupKey + event.ID 的通知最多发送一次 | TC-020 | CI gate `notify-idempotent-check` 阻塞 | ⏳ |
| BR-003 | SuppressWindow 强制：规则未设时用全局默认（非零），零窗口规则被拒绝 | TC-004 | 返回 `ErrSuppressWindowZero`，启动阻塞 | ⏳ |
| BR-004 | 规则 DSL 校验失败必须阻塞启动 | TC-002 | 返回 `ErrRuleInvalid`，退出码非零 | ⏳ |
| BR-005 | 通知渠道配置必须完整：规则引用的 channel ID 必须已定义 | TC-006 | 返回 `ErrChannelUnknown`，启动阻塞 | ⏳ |
| BR-006 | severity 映射不可降级：critical 必须尝试 paging 渠道 | TC-005 | 降级行为记 error，CI gate 阻塞 | ⏳ |
| BR-007 | 自观测指标命名符合 `foundationx_alertx_<measure>` | TC-018 | CI gate `metrics-contract-check` 阻塞 | ⏳ |

---

## §3 非功能需求追溯（NFR）

| NFR ID | Category | Requirement | Verification | Status |
| ------ | -------- | ----------- | ------------ | ------ |
| NFR-001 | 性能 | 规则评估（单事件，100 条规则）< 1ms | Benchmark | ⏳ |
| NFR-002 | 性能 | 告警端到端（评估→通知，单 webhook）< 100ms | 集成测试计时 | ⏳ |
| NFR-003 | 性能 | 通知重试退避指数 1s/2s/4s | 单元测试 | ⏳ |
| NFR-004 | 性能 | 内存占用（10k 活跃告警）< 100MB | Soak | ⏳ |
| NFR-005 | 质量 | 单元测试覆盖率 >= 80% | `go tool cover` | ⏳ |
| NFR-006 | 安全 | race 检测通过（零 data race） | `go test -race` | ⏳ |
| NFR-007 | 质量 | vet 检查通过（零警告） | `go vet` | ⏳ |
| NFR-008 | 质量 | lint 检查通过（零错误） | `golangci-lint` | ⏳ |
| NFR-009 | 安全 | Secret 扫描通过（零命中） | `gitleaks` | ⏳ |
| NFR-010 | 架构 | 无反向依赖（observex/contracts/kernel 不依赖 alertx） | boundary check | ⏳ |

---

## §4 TC → FR 反向追溯

| TC ID | Covers FR(s)/BR(s) | Command |
| ----- | ------------------ | ------- |
| TC-001 | FR-001 | `go test ./... -run TestRuleEvaluator_LoadValid` |
| TC-002 | FR-001, BR-004 | `go test ./... -run TestRuleEvaluator_LoadInvalid` |
| TC-003 | FR-001 | `go test ./... -run TestRuleEvaluator_EvaluateMatch` |
| TC-004 | FR-002, BR-003 | `go test ./... -run TestDeduper_SuppressWindow` |
| TC-005 | FR-003, BR-006 | `go test ./... -run TestSeverityRouting_CriticalPages` |
| TC-006 | FR-004, BR-005 | `go test ./... -run TestNotifier_RetryAndIdempotent` |
| TC-007 | FR-005 | `go test ./... -run TestLifecycle_FiringToResolved` |
| TC-008 | EC-001 | `go test ./... -run TestRuleEvaluator_EmptyRules` |
| TC-009 | EC-002 | `go test ./... -run TestRuleEvaluator_EvalTimeout` |
| TC-010 | EC-003 | `go test ./... -run TestDeduper_ConcurrentSameKey` |
| TC-011 | EC-004, FR-004 | `go test ./... -run TestNotifier_ChannelFailure` |
| TC-012 | EC-005 | `go test ./... -run TestRuleEvaluator_UnknownMetric` |
| TC-013 | EC-006 | `go test ./... -run TestAlertStore_MemoryExhaustion` |
| TC-014 | EC-007 | `go test ./... -run TestSubscribe_ObservexInterrupt` |
| TC-015 | EC-008, FR-007 | `go test ./... -run TestRuleReload_ConcurrentWithEval` |
| TC-016 | EC-009 | `go test ./... -run TestDeduper_MissingTraceID` |
| TC-017 | EC-010 | `go test ./... -run TestMain_GracefulShutdown` |
| TC-018 | FR-006, BR-007 | `go test ./... -run TestHealth_JSONSchema` |
| TC-019 | FR-007 | `go test ./... -run TestRuleReload_HotReload` |
| TC-020 | BR-001, BR-002 | `go test -tags integration ./... -run TestAT007_CrossCutting` |

---

## §5 全局 AC 注册表

| AC ID | FR/BR Ref | Criterion | Verification | Status |
| ----- | --------- | --------- | ------------ | ------ |
| AC-001 | FR-001 | 合法 YAML 加载为 AlertRule；非法 DSL 返回 ErrRuleInvalid 阻塞启动；事件匹配产出 AlertEvent | TC-001, TC-002, TC-003 | ⏳ |
| AC-002 | FR-002 | 同 DedupKey 在 SuppressWindow 内抑制；空 DedupKey 由 alertx 派生 | TC-004 | ⏳ |
| AC-003 | FR-003 | critical→paging；warning→通知不 paging；info→仅日志 | TC-005 | ⏳ |
| AC-004 | FR-004 | 通知按 severity 路由；失败退避重试 3 次；通知幂等 | TC-006, TC-011 | ⏳ |
| AC-005 | FR-005 | firing→suppressed→resolved 流转；抖动 pending 生效；ResolvedAt 记录 | TC-007 | ⏳ |
| AC-006 | FR-006 | health.JSON 四字段；渠道不可达 component live=false 不 panic；指标命名 | TC-018 | ⏳ |
| AC-007 | FR-007 | 文件变更触发重载；校验通过原子替换；校验失败保留旧规则 | TC-015, TC-019 | ⏳ |
| AC-008 | BR-001 | AlertEvent 不丢失；CI alert-no-loss-check 通过 | TC-020 | ⏳ |
| AC-009 | BR-002 | 通知幂等；CI notify-idempotent-check 通过 | TC-020 | ⏳ |
| AC-010 | BR-003 | 零 SuppressWindow 规则被拒绝（用全局默认） | TC-004 | ⏳ |
| AC-011 | BR-004 | DSL 校验失败阻塞启动（退出码非零） | TC-002 | ⏳ |
| AC-012 | BR-005 | 未定义 channel 启动时返回 ErrChannelUnknown 阻塞 | TC-006 | ⏳ |
| AC-013 | BR-006 | critical 必须尝试 paging，不因渠道失败降级 | TC-005 | ⏳ |
| AC-014 | BR-007 | 指标命名符合 foundationx_alertx_\<measure\>；CI metrics-contract-check 通过 | TC-018 | ⏳ |
| AC-015 | EC-010 | SIGTERM 优雅关闭：flush 通知，关闭 AlertStore，干净退出 | TC-017 | ⏳ |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | 有 AC 覆盖 | 有 TC 覆盖 | 覆盖率 |
| ---- | ---- | ---------- | ---------- | ------ |
| FR | 7 | 7 | 7 | 100% |
| BR | 7 | 7 | 7 | 100% |
| NFR | 10 | — | 10 | 100% |
| AC | 15 | — | 15 | 100% |
| TC | 20 | — | — | 100% |
| EC | 10 | — | 10 | 100% |

> 所有 FR/BR/NFR/AC/EC 均有 TC 映射，无孤儿需求。S8 Code 阶段实现后，Status 从 ⏳ 翻转为 ✅，覆盖率仪表盘保持 100%。

---

## §7 变更历史

| 日期 | 变更 | 来源 |
| ---- | ---- | ---- |
| 2026-06-26 | 初始追溯矩阵建立（FR-001~007 / BR-001~007 / NFR-001~010 / AC-001~015 / TC-001~020） | S4 Matrix 阶段，SPEC v1.0.0 Approved |
