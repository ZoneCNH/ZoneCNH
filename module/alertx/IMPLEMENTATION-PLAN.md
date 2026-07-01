# alertx 实现计划

> 来源：module/alertx/SPEC.md v1.0.0（Approved）+ TRACEABILITY.md + tasks/TASK-ALERTX-001~008
> 创建：2026-06-26（S6 Plan 阶段）
> 规范：docs/governance/DEVELOPMENT-WORKFLOW.md

---

## 1. 实现步骤与依赖图

```text
TASK-001 契约骨架
  │
  ├─▶ TASK-002 规则引擎（DSL+评估+热加载）[关键路径]
  │     │
  │     ├─▶ TASK-003 去重抑制
  │     │     │
  │     │     └─▶ TASK-004 分级+生命周期
  │     │           │
  │     │           └─▶ TASK-005 通知路由（webhook）
  │     │                 │
  │     │                 └─▶ TASK-007 健康导出+入口 ──▶ TASK-008 渠道+Soak+CI
  │     │
  │     └─▶ TASK-006 双订阅（P1，可与 003-005 并行）
  │             │
  │             └─────────────────────────────────▶ TASK-007
```

**关键路径**：001 → 002 → 003 → 004 → 005 → 007 → 008（7 步串行）
**并行机会**：TASK-006（双订阅）在 002 完成后可与 003-005 并行，汇入 007

---

## 2. Task 实现明细

| Task | scope | files | 验证命令 | depends | effort |
| ---- | ----- | ----- | -------- | ------- | ------ |
| 001 | 契约骨架（go.mod/version/errors/options） | 4 | `go build ./... && go vet ./...` | — | 1h |
| 002 | 规则引擎（DSL 解析+评估器+热加载） | 4 | `go test ./internal/config/... -run TestRuleParser` | 001 | 4h |
| 003 | 去重抑制（DedupKey+窗口） | 2 | `go test ./pkg/alertx/... -run TestDeduper -race` | 002 | 2h |
| 004 | 分级+生命周期+内存 AlertStore | 4 | `go test ./... -run 'TestSeverity|TestLifecycle|TestAlertStore'` | 003 | 3h |
| 005 | 通知路由（Notifier+webhook+重试幂等） | 3 | `go test ./internal/channel/... -run TestWebhook` | 004 | 3h |
| 006 | 双订阅（observex+业务事件归一化） | 4 | `go test ./internal/subscribe/... -run TestNormalizer -race` | 002 | 3h |
| 007 | 健康导出+指标+cmd 入口+Dockerfile | 4 | `go build ./cmd/alertx && go test ./... -run TestHealth` | 005,006 | 3h |
| 008 | email/pagerduty+Soak+AT-007+CI+Makefile | 6 | `go test -tags integration ./... -run TestAT007` | 007 | 5h |

**文件归属（无冲突）**：
- TASK-001 独占：go.mod, pkg/alertx/{version,errors,options}.go
- TASK-002 独占：pkg/alertx/{evaluator,rule}.go, internal/config/rule_parser.go
- TASK-003 独占：pkg/alertx/dedup.go
- TASK-004 独占：pkg/alertx/{severity,lifecycle}.go, internal/store/memory_store.go
- TASK-005 独占：pkg/alertx/notifier.go, internal/channel/webhook.go
- TASK-006 独占：internal/subscribe/{observex,business}_subscriber.go + normalizer.go
- TASK-007 独占：pkg/alertx/{health,labels}.go, cmd/alertx/main.go, Dockerfile
- TASK-008 独占：internal/channel/{email,pagerduty}.go, testkit/soak_harness.go, test/at007, .github/workflows, Makefile

> 所有 task 文件列表无重叠（垂直切分），可安全并行/串行无冲突。

---

## 3. 技术决策

| 决策 | 选择 | 理由 |
| ---- | ---- | ---- |
| 规则 DSL 解析 | 手写递归下降 + yaml.v3 | DSL 简单（metric:comparison:value），避免引入复杂表达式引擎 |
| 热加载机制 | 轮询（reload_interval）+ fsnotify 可选 | 轮询跨平台稳定，fsnotify 作为优化后续加 |
| 并发模型 | sync.RWMutex（规则集）+ channel（事件流） | 规则评估读多写少用 RWMutex；事件流用 channel |
| AlertStore 首版 | 内存（map[DedupKey]AlertEvent） | 首版无需持久化，Soak 后按 NFR-004 决定是否加 Redis |
| 通知重试 | resiliencx 退避 + 内存幂等表 | 复用基座 resiliencx，幂等表 (DedupKey+event.ID) map |

---

## 4. 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
| ---- | ---- | ---- | ---- |
| contracts v1.6.0 未正式发布，go.mod 依赖本地 replace | 高 | 中 | TASK-001 用 replace 指向 /home/workspace/contracts（feat branch），contracts 合并发 tag 后改 require |
| 规则 DSL 表达力不足（复杂条件无法表达） | 中 | 中 | 首版支持 metric:op:value 三段式 + AND 组合；复杂聚合列为 Future |
| observex Exporter 接口与 alertx 订阅假设不符 | 中 | 高 | TASK-006 先验证 observex Exporter 签名，不符则调整 normalizer；SPEC §15 已锁 observex v0.3.1+ |
| Soak 发现内存泄漏 | 低 | 中 | TASK-008 Soak harness 监控，泄漏则修复后重跑 |
| webhook 集成测试需真实 HTTP server | 中 | 低 | 用 httptest.Server 构造 mock，不依赖外部服务 |

---

## 5. 验证里程碑

| 里程碑 | 完成条件 | 对应 Task |
| ------ | -------- | --------- |
| M1 骨架编译 | `go build ./...` 通过 | 001 |
| M2 规则引擎可用 | 规则加载+评估+热加载测试通过 | 002 |
| M3 告警链路通 | 评估→去重→分级→状态机 通过 | 003,004 |
| M4 通知可达 | webhook 通知+重试幂等 通过 | 005 |
| M5 双订阅落地 | observex+业务事件归一化 通过 | 006 |
| M6 进程可运行 | cmd/alertx 启动+health+优雅关闭 | 007 |
| M7 生产就绪 | AT-007+Soak+CI+Makefile 全绿 | 008 |
| **M8 Release v1.0.0** | release-final-check + manifest + GitHub Release | S9 |

---

## 6. 回滚与降级策略（Rollback）

| 场景 | 回滚动作 | 触发条件 |
| ---- | -------- | -------- |
| 规则热加载引入错误规则 | 保留旧规则集（FR-007 已支持：校验失败不替换），记 error + reload_failed counter | 热加载校验失败 |
| 通知渠道全面故障 | 降级为日志记录（severity 不降级，BR-006），通知入 AlertStore 待重试 | 所有渠道 retry 耗尽 |
| alertx 进程崩溃 | composer 重启（resiliencx 监控），告警状态从 AlertStore 恢复（首版内存则丢失活跃告警，可接受） | 进程 panic/exit |
| Release v1.0.0 发现严重缺陷 | 回退到上一 commit + 重新发版（首版无前一 tag，回退 = 紧急修复重发 v1.0.1） | 发布后 P0 缺陷 |

> 回滚原则：alertx 故障不得影响业务域正常运行（AT-007 Then：「告警不影响业务模块的正常运行」）。alertx 宕机时业务继续，仅告警中断。

---

## 7. 完成定义（DoD 摘要）

每个 task 完成需满足：
- 所有 acceptance_criteria 的 AC 对应测试 PASS
- `go build && go vet && go test -race` 通过
- gofmt 格式化、golangci-lint 零错误
- TRACEABILITY.md 对应 FR/BR 的 Status 翻 ⏳ → ✅

全部 8 task 完成后进入 S9 验收（DoD 全清单 + Release）。
