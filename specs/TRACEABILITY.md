# Traceability Matrix

> 需求追踪表：确保每个需求有验收标准、测试用例和实现。

最后更新：2026-06-07

---

## 使用方法

1. **防漏功能**：每个 FR/BR 必须有 AC 和 TC
2. **防做多**：每个实现必须有 spec 支持
3. **防测试盲区**：每个 AC 必须有 TC 覆盖
4. **方便 review**：reviewer 可以按编号逐条检查
5. **方便验收**：验收时按 AC 逐条确认

---

## kernel

| Requirement | Description            | Acceptance Criteria | Test Case              | Status |
| ----------- | ---------------------- | ------------------- | ---------------------- | ------ |
| FR-001      | Register 模块注册      | AC-001              | TC-001, TC-008         | ⬜     |
| FR-002      | Run 启动               | AC-002, AC-003      | TC-001, TC-002, TC-003 | ⬜     |
| FR-003      | Shutdown 停机          | AC-004              | TC-004                 | ⬜     |
| FR-004      | ModuleHealth 健康查询  | AC-005              | TC-009                 | ⬜     |
| FR-005      | DependencyGraph 依赖图 | AC-006              | TC-010                 | ⬜     |
| BR-001      | 依赖图不允许环         | AC-002              | TC-002                 | ⬜     |
| BR-002      | 拓扑序启动             | AC-003              | TC-001                 | ⬜     |
| BR-003      | 反序停止               | AC-004              | TC-004                 | ⬜     |
| BR-006      | Stop 超时 force        | AC-007              | TC-004                 | ⬜     |
| BR-008      | stdlib-only            | -                   | CI Gate                | ⬜     |

---

## configx

| Requirement | Description                  | Acceptance Criteria | Test Case | Status |
| ----------- | ---------------------------- | ------------------- | --------- | ------ |
| FR-001      | Load 文件加载                | AC-001              | TC-001    | ⬜     |
| FR-002      | WithEnvOverride 环境变量覆盖 | AC-002              | TC-001    | ⬜     |
| FR-003      | Validate 校验                | AC-003              | TC-002    | ⬜     |
| FR-004      | Get 读取                     | AC-004              | TC-003    | ⬜     |
| FR-005      | Watch 配置监听（可选）       | AC-005              | TC-004    | ⬜     |
| BR-001      | 覆盖优先级                   | AC-002              | TC-001    | ⬜     |
| BR-002      | 启动时 fail-fast             | AC-003              | TC-002    | ⬜     |
| BR-005      | Reader 只读                  | AC-005              | TC-005    | ⬜     |

---

## resiliencx

| Requirement | Description    | Acceptance Criteria | Test Case      | Status |
| ----------- | -------------- | ------------------- | -------------- | ------ |
| FR-001      | Timeout        | AC-001              | TC-001         | ⬜     |
| FR-002      | Retry          | AC-002              | TC-001         | ⬜     |
| FR-003      | CircuitBreaker | AC-003, AC-004      | TC-002, TC-003 | ⬜     |
| FR-004      | Bulkhead       | AC-005              | TC-004         | ⬜     |
| FR-005      | RateLimiter    | AC-006              | TC-005         | ⬜     |
| FR-006      | Fallback       | AC-007              | TC-006         | ⬜     |
| BR-004      | 熔断器并发安全 | -                   | -race test     | ⬜     |

---

## observex

| Requirement | Description      | Acceptance Criteria         | Test Case  | Status |
| ----------- | ---------------- | --------------------------- | ---------- | ------ |
| FR-001      | Logger           | DoD: 所有 FR 有测试         | TC-001     | ⬜     |
| FR-002      | Meter            | DoD: label policy check     | TC-002     | ⬜     |
| FR-003      | Tracer           | DoD: 所有 FR 有测试         | TC-003     | ⬜     |
| FR-004      | Exporter         | DoD: 所有 FR 有测试         | TC-004     | ⬜     |
| FR-005      | Redaction        | DoD: redaction leak check   | TC-005     | ⬜     |
| FR-006      | Label Policy     | DoD: label policy check     | TC-002     | ⬜     |
| FR-007      | Health           | DoD: 所有 FR 有测试         | TC-006     | ⬜     |
| BR-001      | Logger 并发安全  | -                           | -race test | ⬜     |
| BR-005      | With 不变性      | -                           | TC-001     | ⬜     |
| BR-006      | 指标命名规范     | DoD: metrics contract check | TC-007     | ⬜     |
| BR-007      | 日志 secret 脱敏 | DoD: redaction leak check   | TC-005     | ⬜     |

---

## schedulex

| Requirement | Description                     | Acceptance Criteria           | Test Case | Status |
| ----------- | ------------------------------- | ----------------------------- | --------- | ------ |
| FR-001      | Schedule                        | DoD: 所有 FR 有测试           | TC-001    | ⬜     |
| FR-002      | Trigger                         | DoD: DST/timezone golden 测试 | TC-001    | ⬜     |
| FR-003      | Overlap Policy                  | DoD: overlap contract 测试    | TC-002    | ⬜     |
| FR-004      | Misfire Policy                  | DoD: misfire contract 测试    | TC-003    | ⬜     |
| FR-005      | Cancel                          | DoD: 所有 FR 有测试           | TC-005    | ⬜     |
| FR-006      | Stop                            | DoD: shutdown leak/race 测试  | TC-006    | ⬜     |
| FR-007      | EventSink                       | DoD: 所有 FR 有测试           | TC-007    | ⬜     |
| FR-008      | Locker                          | DoD: 所有 FR 有测试           | TC-004    | ⬜     |
| FR-009      | Clock                           | DoD: DST/timezone golden 测试 | TC-008    | ⬜     |
| BR-002      | 重复 JobID 返回 ErrDuplicateJob | -                             | TC-009    | ⬜     |
| BR-005      | job panic 被 catch              | DoD: shutdown race 测试       | TC-006    | ⬜     |
| BR-007      | DST 切换触发正确                | DoD: DST/timezone golden 测试 | TC-008    | ⬜     |

---

## testkitx

| Requirement | Description             | Acceptance Criteria          | Test Case     | Status |
| ----------- | ----------------------- | ---------------------------- | ------------- | ------ |
| FR-001      | FakeConfig              | DoD: 所有 FR 有测试          | TC-001        | ⬜     |
| FR-002      | FakeLogger              | DoD: 编译期接口检查          | TC-002        | ⬜     |
| FR-003      | FakeMeter               | DoD: 编译期接口检查          | TC-003        | ⬜     |
| FR-004      | FakeTracer              | DoD: 编译期接口检查          | TC-004        | ⬜     |
| FR-005      | FakeClock               | DoD: 确定性 fake             | TC-005        | ⬜     |
| FR-006      | FakeBreaker             | DoD: 编译期接口检查          | TC-006        | ⬜     |
| FR-007      | Eventually              | DoD: 所有 FR 有测试          | TC-007        | ⬜     |
| FR-008      | GoldenUpdate            | DoD: GOLDEN_UPDATE 环境变量  | TC-008        | ⬜     |
| FR-009      | BoundaryCheck           | DoD: 生产 import 无 testkitx | TC-009        | ⬜     |
| FR-010      | GoroutineLeakCheck      | DoD: 所有 FR 有测试          | TC-010        | ⬜     |
| BR-001      | 编译期接口检查          | -                            | CI Gate       | ⬜     |
| BR-002      | fake 确定性             | -                            | CI Gate       | ⬜     |
| BR-005      | 生产 import 无 testkitx | -                            | boundary-test | ⬜     |

---

## xlibgate

| Requirement | Description              | Acceptance Criteria | Test Case      | Status |
| ----------- | ------------------------ | ------------------- | -------------- | ------ |
| FR-001      | check imports            | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-002      | check gomod              | DoD: 所有 FR 有测试 | TC-002         | ⬜     |
| FR-003      | check baseline           | DoD: 所有 FR 有测试 | TC-003         | ⬜     |
| FR-004      | check release            | DoD: 所有 FR 有测试 | TC-006         | ⬜     |
| FR-005      | check all                | DoD: 所有 FR 有测试 | TC-004, TC-005 | ⬜     |
| FR-006      | 输出格式                 | DoD: 所有 FR 有测试 | TC-007         | ⬜     |
| BR-001      | 标准化 exit code         | -                   | TC-004, TC-005 | ⬜     |
| BR-006      | check all 执行所有子检查 | -                   | TC-004         | ⬜     |

---

## xlib-standard

| Requirement | Description                        | Acceptance Criteria                                                           | Test Case                                                       | Status |
| ----------- | ---------------------------------- | ----------------------------------------------------------------------------- | --------------------------------------------------------------- | ------ |
| FR-001      | 定义 419 条 RULE-\* 规则           | DoD: registry.yaml 机器可读                                                   | `internal/xlibfacts/facts_test.go`                              | ⬜     |
| FR-002      | 7 类技术债治理规则                 | DoD: ARCH/DEP/DOMAIN/DOCS/TEST/IMPL/SEC 全覆盖                                | `internal/debtcheck/debtcheck_test.go`                          | ⬜     |
| FR-003      | 10 条 Git 治理规则和 5 层执行链    | DoD: 执行链可验证                                                             | `contracts/contracts_test.go`                                   | ⬜     |
| FR-004      | L0-L6 层级依赖模型                 | DoD: 依赖方向可机器检查                                                       | -                                                               | ⬜     |
| FR-005      | 8 个仓库治理 REQ                   | DoD: worktree/hooks/Makefile/CI/ruleset/evidence/audit/no-false-adopted       | -                                                               | ⬜     |
| FR-006      | 采纳状态机（8 状态，6 个禁止转换） | DoD: 状态机可机器验证                                                         | `internal/goalruntime/goalruntime_test.go`                      | ⬜     |
| FR-007      | 15 条基本真理                      | DoD: TRUTH-001~015 全部有 enforcer                                            | `internal/xlibfacts/facts_test.go`                              | ⬜     |
| FR-008      | 9 个正式 ADR                       | DoD: ADR 状态为 Accepted                                                      | `cmd/goalcli/audit_goal_test.go`                                | ⬜     |
| FR-009      | 公共 API 模板                      | DoD: Config/Validate/Sanitize/New/Close/HealthCheck/Error/Metrics/Version     | `pkg/templatex/client_test.go`                                  | ⬜     |
| FR-010      | 9 种 ErrorKind                     | DoD: 9 种类型全覆盖                                                           | `pkg/templatex/errors_test.go`                                  | ⬜     |
| FR-011      | 9 个最小 metrics                   | DoD: metrics 注册可验证                                                       | `pkg/templatex/metrics_test.go`                                 | ⬜     |
| FR-012      | HealthCheck JSON schema            | DoD: 符合 health.schema.json                                                  | `pkg/templatex/health_test.go`, `health_golden_test.go`         | ⬜     |
| FR-013      | 配置显式传入                       | DoD: 禁止隐式读取生产密钥                                                     | `pkg/templatex/config_test.go`                                  | ⬜     |
| FR-014      | 配置 Validate 和 Sanitize          | DoD: 无效配置被拒绝                                                           | `internal/sanitize/sanitize_test.go`, `config_property_test.go` | ⬜     |
| FR-015      | render_template.sh 渲染            | DoD: 渲染后可编译                                                             | `scripts/render_template_test.go`                               | ⬜     |
| FR-016      | 渲染范围全覆盖                     | DoD: Go/JSON/shell/Makefile/CI/文档                                           | `pkg/templatex/config_fuzz_test.go`                             | ⬜     |
| FR-017      | Repository Governance Pack         | DoD: --enable-governance 生效                                                 | -                                                               | ⬜     |
| FR-018      | make integration                   | DoD: kernel/configx/redisx 渲染验证                                           | `scripts/run_integration_test.go`                               | ⬜     |
| FR-019      | Docker Toolchain Runtime 模板继承  | DoD: Docker 构建可验证                                                        | `internal/tools/releasemanifest/docker_test.go`                 | ⬜     |
| FR-020      | 66 个 Required Gates               | DoD: gate 全部可执行                                                          | `internal/goalruntime/goalruntime_test.go`                      | ⬜     |
| FR-021      | 4 个 Context Profiles              | DoD: local/release/downstream/docker                                          | `cmd/goalcli/schema_check_test.go`                              | ⬜     |
| FR-022      | P0 Gate 失败阻断发布               | DoD: gate 失败时发布被阻止                                                    | `cmd/goalcli/audit_goal_test.go`                                | ⬜     |
| FR-023      | Gate 结果归档为 Evidence           | DoD: evidence ledger 有记录                                                   | `cmd/goalcli/traceability_test.go`                              | ⬜     |
| FR-024      | Release Scorecard（阈值 9.8）      | DoD: score < 9.8 阻断发布                                                     | `internal/releasequality/score_test.go`                         | ⬜     |
| FR-025      | Debt Governance Gate               | DoD: make debt + min-score 9.8                                                | `internal/debtcheck/debtcheck_test.go`                          | ⬜     |
| FR-026      | Evidence Ledger                    | DoD: .agent/evidence/ledger.jsonl 存在                                        | `cmd/goalcli/traceability_test.go`                              | ⬜     |
| FR-027      | Release Manifest（20+ 字段）       | DoD: latest.json schema 通过                                                  | `internal/tools/releasemanifest/main_test.go`                   | ⬜     |
| FR-028      | DONE with evidence 格式            | DoD: 唯一完成声明格式                                                         | `cmd/goalcli/selfimproving_test.go`                             | ⬜     |
| FR-029      | 禁止无证据的 tests pass            | DoD: 命令输出必须支撑声明                                                     | `internal/validation/validation_test.go`                        | ⬜     |
| FR-030      | 禁止 skipped gate 记为 passed      | DoD: gate 状态一致性                                                          | `internal/validation/validation_test.go`                        | ⬜     |
| FR-031      | 禁止 dirty workspace release       | DoD: workspace 干净才可发布                                                   | `scripts/check_release_preflight_test.go`                       | ⬜     |
| FR-032      | 禁止删除失败 Evidence              | DoD: evidence append-only                                                     | `cmd/goalcli/traceability_test.go`                              | ⬜     |
| FR-033      | ARCH 类技术债规则                  | DoD: NO_XGO_IMPORT 等 5 条                                                    | `internal/debtcheck/debtcheck_test.go`                          | ⬜     |
| FR-034      | DEP 类技术债规则                   | DoD: GOVULNCHECK 等 10 条                                                     | `scripts/check_dependency_diff_test.go`                         | ⬜     |
| FR-035      | DOMAIN 类技术债规则                | DoD: FORBIDDEN_BUSINESS_TERM 等 2 条                                          | `internal/debtcheck/debtcheck_test.go`                          | ⬜     |
| FR-036      | DOCS 类技术债规则                  | DoD: MISSING_REQUIRED_ADR 等 5 条                                             | `scripts/check_standard_impact_test.go`                         | ⬜     |
| FR-037      | TEST 类技术债规则                  | DoD: MISSING_CRITICAL_BEHAVIOR 等 6 条                                        | `internal/validation/validation_test.go`                        | ⬜     |
| FR-038      | IMPL 类技术债规则                  | DoD: PANIC_RUNTIME 等                                                         | `internal/debtcheck/debtcheck_test.go`                          | ⬜     |
| FR-039      | SEC 类技术债规则                   | DoD: 安全合规全覆盖                                                           | `internal/debtcheck/debtcheck_test.go`                          | ⬜     |
| FR-040      | Goal Kernel（8 个核心对象）        | DoD: Goal/Spec/Design/Plan/Task/Test/Evidence/Review                          | `internal/goalruntime/goalruntime_test.go`                      | ⬜     |
| FR-041      | Harness Runtime                    | DoD: Mode Router/Gate Registry/Command Registry/Blocking Policy               | `internal/goalruntime/goalruntime_test.go`                      | ⬜     |
| FR-042      | goalcli 唯一执行面                 | DoD: cmd/goalcli 可执行                                                       | `cmd/goalcli/main_test.go`                                      | ⬜     |
| FR-043      | 6 个 MVA Gate                      | DoD: goal-acceptance/delivery/handover/downstream-adopt/certify/runtime-final | `cmd/goalcli/audit_goal_test.go`                                | ⬜     |
| FR-044      | 4-Plane 架构                       | DoD: Spec/Execution/Proof/Automation 分离                                     | -                                                               | ⬜     |
| FR-045      | 10 个 REQ-PROOF                    | DoD: Facts SSOT/GateReport/Evidence Replay 等                                 | `cmd/goalcli/audit_goal_test.go`                                | ⬜     |
| FR-046      | 28 个 PR 执行包                    | DoD: Phase 1~5 全部有 plan                                                    | -                                                               | ⬜     |
| FR-047      | 5 层执行链                         | DoD: 标准源→生成器→hooks→CI→ruleset                                           | `internal/xlibfacts/facts_test.go`                              | ⬜     |
| FR-048      | 禁止 main 开发                     | DoD: pre-commit + pre-push + goalcli main-guard                               | `cmd/goalcli/main_test.go`                                      | ⬜     |
| FR-049      | 必须使用 git worktree              | DoD: goalcli worktree-guard 生效                                              | `cmd/goalcli/main_test.go`                                      | ⬜     |
| FR-050      | 采纳状态机（8 状态）               | DoD: 状态转换可机器验证                                                       | `internal/goalruntime/goalruntime_test.go`                      | ⬜     |
| FR-051      | 6 个禁止状态转换                   | DoD: 禁止转换被阻止                                                           | `internal/goalruntime/goalruntime_test.go`                      | ⬜     |
| FR-052      | 下游同步治理（20 PR）              | DoD: 同步计划可执行                                                           | `cmd/goalcli/downstream_sync_plan_test.go`                      | ⬜     |
| BR-001      | 唯一标准来源                       | -                                                                             | `internal/xlibfacts/facts_test.go`                              | ⬜     |
| BR-004      | Reference Template 可编译          | -                                                                             | `pkg/templatex/config_test.go`                                  | ⬜     |
| BR-011      | latest.json 不提交                 | -                                                                             | `scripts/check_release_preflight_test.go`                       | ⬜     |
| BR-014      | proof_depth 不升级                 | -                                                                             | `cmd/goalcli/schema_check_test.go`                              | ⬜     |

---

## redisx

| Requirement | Description        | Acceptance Criteria | Test Case | Status |
| ----------- | ------------------ | ------------------- | --------- | ------ |
| FR-001      | Get                | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-002      | Set                | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-003      | Del                | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-004      | Exists             | DoD: 所有 FR 有测试 | TC-005    | ⬜     |
| FR-005      | Expire             | DoD: 所有 FR 有测试 | TC-005    | ⬜     |
| FR-006      | HGet / HSet        | DoD: 所有 FR 有测试 | TC-006    | ⬜     |
| FR-007      | LPush / LRange     | DoD: 所有 FR 有测试 | TC-007    | ⬜     |
| FR-008      | Subscribe          | DoD: 所有 FR 有测试 | TC-008    | ⬜     |
| FR-009      | Pipeline           | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-010      | Locker.Acquire     | DoD: 所有 FR 有测试 | TC-002    | ⬜     |
| FR-011      | Locker.Release     | DoD: 所有 FR 有测试 | TC-002    | ⬜     |
| FR-012      | Health             | DoD: 所有 FR 有测试 | TC-009    | ⬜     |
| BR-004      | 分布式锁唯一持有者 | -                   | TC-002    | ⬜     |
| BR-006      | Pipeline 原子性    | -                   | TC-003    | ⬜     |

---

## kafkax

| Requirement | Description                | Acceptance Criteria | Test Case | Status |
| ----------- | -------------------------- | ------------------- | --------- | ------ |
| FR-001      | Producer.Send              | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-002      | Producer.SendBatch         | DoD: 所有 FR 有测试 | TC-002    | ⬜     |
| FR-003      | Consumer.Subscribe         | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-004      | Consumer.Poll              | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-005      | Consumer.Commit            | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-006      | Health                     | DoD: 所有 FR 有测试 | TC-005    | ⬜     |
| BR-001      | Producer 同步发送 acks=all | -                   | TC-001    | ⬜     |
| BR-002      | Consumer 手动 offset       | -                   | TC-003    | ⬜     |
| BR-005      | Producer 重试可配置        | -                   | TC-004    | ⬜     |

---

## natsx

| Requirement | Description             | Acceptance Criteria | Test Case | Status |
| ----------- | ----------------------- | ------------------- | --------- | ------ |
| FR-001      | Publish（Core NATS）    | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-002      | Subscribe（Core NATS）  | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-003      | Request（Core NATS）    | DoD: 所有 FR 有测试 | TC-002    | ⬜     |
| FR-004      | JetStream.Publish       | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-005      | JetStream.Subscribe     | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-006      | JetStream.AddStream     | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-007      | JetStream.AddConsumer   | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| FR-008      | Health                  | DoD: 所有 FR 有测试 | TC-005    | ⬜     |
| BR-001      | Core NATS at-most-once  | -                   | TC-001    | ⬜     |
| BR-002      | JetStream at-least-once | -                   | TC-003    | ⬜     |
| BR-005      | 自动重连指数退避        | -                   | TC-004    | ⬜     |

---

## postgresx

| Requirement | Description              | Acceptance Criteria | Test Case      | Status |
| ----------- | ------------------------ | ------------------- | -------------- | ------ |
| FR-001      | Query                    | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-002      | QueryRow                 | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-003      | Exec                     | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-004      | Tx                       | DoD: 所有 FR 有测试 | TC-002, TC-003 | ⬜     |
| FR-005      | Health                   | DoD: 所有 FR 有测试 | TC-005         | ⬜     |
| FR-006      | Migration                | DoD: 所有 FR 有测试 | TC-004         | ⬜     |
| BR-001      | 参数化查询防 SQL 注入    | -                   | TC-001         | ⬜     |
| BR-003      | 事务自动 commit/rollback | -                   | TC-002         | ⬜     |
| BR-004      | 事务 panic 自动 rollback | -                   | TC-003         | ⬜     |
| BR-007      | 迁移脚本幂等             | -                   | TC-004         | ⬜     |

---

## taosx

| Requirement | Description           | Acceptance Criteria | Test Case      | Status |
| ----------- | --------------------- | ------------------- | -------------- | ------ |
| FR-001      | NewClient             | DoD: 所有 FR 有测试 | TC-004         | ⬜     |
| FR-002      | Exec                  | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-003      | Query                 | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-004      | InsertBatch           | DoD: 所有 FR 有测试 | TC-001, TC-003 | ⬜     |
| FR-005      | Health                | DoD: 所有 FR 有测试 | TC-005         | ⬜     |
| FR-006      | Close                 | DoD: 所有 FR 有测试 | TC-006         | ⬜     |
| FR-007      | Rows.Next/Scan/Close  | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| BR-002      | STMT 批量写入         | -                   | TC-003         | ⬜     |
| BR-003      | 参数化绑定防 SQL 拼接 | -                   | TC-001         | ⬜     |
| BR-004      | 连接断开自动重试      | -                   | TC-002         | ⬜     |

---

## ossx

| Requirement | Description                 | Acceptance Criteria | Test Case | Status |
| ----------- | --------------------------- | ------------------- | --------- | ------ |
| FR-001      | NewClient                   | DoD: 所有 FR 有测试 | TC-005    | ⬜     |
| FR-002      | Put                         | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-003      | Get                         | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-004      | Delete                      | DoD: 所有 FR 有测试 | TC-006    | ⬜     |
| FR-005      | List                        | DoD: 所有 FR 有测试 | TC-007    | ⬜     |
| FR-006      | PresignURL                  | DoD: 所有 FR 有测试 | TC-008    | ⬜     |
| FR-007      | Health                      | DoD: 所有 FR 有测试 | TC-009    | ⬜     |
| FR-008      | Close                       | DoD: 所有 FR 有测试 | TC-010    | ⬜     |
| BR-001      | key 非空且不以 / 开头       | -                   | TC-005    | ⬜     |
| BR-002      | multipart upload 阈值 100MB | -                   | TC-002    | ⬜     |
| BR-008      | Delete 幂等                 | -                   | TC-006    | ⬜     |

---

## clickhousex

| Requirement | Description            | Acceptance Criteria | Test Case      | Status |
| ----------- | ---------------------- | ------------------- | -------------- | ------ |
| FR-001      | NewClient              | DoD: 所有 FR 有测试 | TC-005         | ⬜     |
| FR-002      | Exec                   | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-003      | Query                  | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-004      | InsertBatch            | DoD: 所有 FR 有测试 | TC-001, TC-003 | ⬜     |
| FR-005      | Health                 | DoD: 所有 FR 有测试 | TC-006         | ⬜     |
| FR-006      | Close                  | DoD: 所有 FR 有测试 | TC-007         | ⬜     |
| FR-007      | Rows.Next/Scan/Close   | DoD: 所有 FR 有测试 | TC-001         | ⬜     |
| FR-008      | Rows.ColumnTypes       | DoD: 所有 FR 有测试 | TC-004         | ⬜     |
| BR-002      | 原生 batch insert 协议 | -                   | TC-003         | ⬜     |
| BR-003      | 参数化绑定防 SQL 拼接  | -                   | TC-001         | ⬜     |
| BR-004      | 连接断开自动重试       | -                   | TC-002         | ⬜     |
| BR-011      | Nullable 映射 Go 指针  | -                   | TC-004         | ⬜     |

---

## xgo

| Requirement | Description          | Acceptance Criteria | Test Case    | Status |
| ----------- | -------------------- | ------------------- | ------------ | ------ |
| FR-001      | Compose 模块组装     | AC-001              | TC-001       | ⬜     |
| FR-002      | Run 启动             | AC-002              | TC-002       | ⬜     |
| FR-003      | Shutdown 停机        | AC-003              | TC-003       | ⬜     |
| FR-004      | Health 健康检查      | AC-004              | TC-004       | ⬜     |
| FR-005      | Signal 信号处理      | AC-005              | TC-005       | ⬜     |
| FR-006      | Config 配置加载      | AC-006              | TC-006       | ⬜     |
| BR-001      | 组合根不包含业务逻辑 | -                   | import check | ⬜     |
| BR-003      | 只编排不实现         | -                   | code review  | ⬜     |
| BR-005      | 单进程运行           | AC-002              | TC-002       | ⬜     |

---

## contracts

| Requirement | Description                | Acceptance Criteria | Test Case | Status |
| ----------- | -------------------------- | ------------------- | --------- | ------ |
| FR-001      | MarketDataProvider         | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-002      | MacroDataProvider          | DoD: 所有 FR 有测试 | TC-001    | ⬜     |
| FR-003      | Event 接口                 | DoD: 所有 FR 有测试 | TC-005    | ⬜     |
| FR-004      | Topic 常量                 | DoD: 所有 FR 有测试 | TC-004    | ⬜     |
| FR-005      | DTO 契约                   | DoD: 所有 FR 有测试 | TC-002    | ⬜     |
| FR-006      | Breaking Change 检测       | DoD: 所有 FR 有测试 | TC-003    | ⬜     |
| BR-003      | breaking change 需版本升级 | -                   | TC-003    | ⬜     |
| BR-004      | 端口接口 3-5 方法          | -                   | TC-006    | ⬜     |
| BR-005      | 事件 DTO 不可变            | -                   | TC-007    | ⬜     |
| BR-006      | Topic 全局唯一点分命名     | -                   | TC-004    | ⬜     |

---

## 状态说明

| 符号 | 含义     |
| ---- | -------- |
| ⬜   | 未开始   |
| 🔵   | 开发中   |
| ✅   | 已完成   |
| ❌   | 验收失败 |
| ⏭️   | 推迟     |

---

## 使用 Prompt

```markdown
请根据 Traceability Matrix 检查当前实现。

要求：

- 找出未实现的 Requirement（Status = ⬜ 但应该已实现的）
- 找出没有测试覆盖的 Requirement（Test Case = -）
- 找出实现了但没有 Spec 支持的功能（scope creep）
- 不要修改代码，只输出分析结果
```text
