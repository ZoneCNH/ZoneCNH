# riskx 需求追溯矩阵

> 更新：2026-06-16
> 来源：module/riskx/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

---

## §1 功能需求追溯（FR）

| FR | Description | WHEN | THEN | AC | TC | Task | Status |
|----|-------------|------|------|----|----|------|--------|
| FR-001 | Pre-Trade Risk Check | orderx 调用 CheckOrder(ctx, order, position) | 依次检查规则（短路求值，首个失败即拒绝）：order.qty*price ≤ maxOrderValue；netQty+order.qty ≤ maxPositionSize；dailyOrders+1 ≤ maxDailyOrders；dailyVolume+order.qty*price ≤ maxDailyVolume；symbol 不在禁止交易列表 | AC-RSK-001 | TC-RSK-001 | - | ⬜→§8 |
| FR-002 | Drawdown Control | 账户回撤超过 maxDrawdown | 拒绝所有该账户新订单；emit drawdown_circuit_breaker 事件；恢复条件：回撤降至 maxDrawdown*0.5 以下（滞后阈值） | AC-RSK-002 | TC-RSK-002 | - | ⬜→§8 |
| FR-003 | Kill Switch | 管理员发出 KillSwitch(account) | 立即取消该账户所有挂单（通过 orderx CancelAll）；拒绝所有新订单；状态持久化（重启后仍生效）；Resume(account) 恢复下单能力 | AC-RSK-003 | TC-RSK-003 | - | ⬜→§8 |
| FR-004 | Rate Limiting | 单账户订单频率超过 maxOrderRate（orders/sec） | 拒绝超出部分并返回 RATE_LIMITED 错误；使用滑动窗口计数 | AC-RSK-004 | TC-RSK-004 | - | ⬜→§8 |
| FR-005 | Concentration Control | 单 symbol 仓位占总仓位比例超过 maxConcentration | 拒绝该 symbol 的新增仓位；减仓不受此限制 | AC-RSK-005 | TC-RSK-005 | - | ⬜→§8 |
| FR-006 | Risk Metrics | 定时计算风险指标 | 输出 VaR（95%/99%）、Sharpe Ratio、Max Drawdown、Calmar Ratio、Volatility（annualized）；计算周期可配置（默认 5 min） | AC-RSK-006 | TC-RSK-006 | - | ⬜→§8 |
| FR-007 | Risk Event Audit | 风控检查通过（PASS）或被拒绝（REJECT） | 记录审计事件（timestamp/account/symbol/side/qty/price/result/reason/rule_id）；审计事件不可删除 | AC-RSK-007 | TC-RSK-007 | - | ⬜→§8 |
| FR-008 | Module Identity | downstream consumer 读取 README.md | H1 为 `# riskx`；Go module path 为 `github.com/ZoneCNH/riskx`；go.mod 声明 `module github.com/ZoneCNH/riskx` | AC-RSK-008 | TC-RSK-008 | - | ⬜→§8 |

---


| BR | Rule | 违反后果 | TC ID(s) | Task | Status |
|----|------|----------|---------------------|------|--------|
| BR-001 | 所有订单必须通过 riskx 检查后才能提交交易所 | orderx 拒绝下单 | TC-RSK-001 风控调用链路断言 | - | ⬜→§8 |
| BR-002 | KillSwitch 状态必须持久化 | 重启后恢复风控状态 | TC-RSK-003 持久化+重启恢复断言 | - | ⬜→§8 |
| BR-003 | 回撤熔断有滞后恢复阈值（0.5x maxDrawdown） | 避免反复触发 | TC-RSK-002 滞后恢复断言 | - | ⬜→§8 |
| BR-004 | 风控规则优先级：KillSwitch > Drawdown > PositionLimit > RateLimit | 保证最关键规则先执行 | TC-RSK-008 规则优先级断言 | - | ⬜→§8 |
| BR-005 | 减仓不受集中度限制 | 风控不阻止降风险操作 | TC-RSK-005 减仓豁免断言 | - | ⬜→§8 |

---

## §3 非功能需求追溯（NFR）

| NFR | Category | Requirement | Verification | Task | Status |
|-----|----------|-------------|--------------|------|--------|
| NFR-001 | 性能 | CheckOrder 延迟 < 1ms | Benchmark `BenchmarkCheckOrder` | - | ⬜→§8 |
| NFR-002 | 性能 | RiskMetrics 计算延迟 < 100ms | Benchmark `BenchmarkRiskMetrics` | - | ⬜→§8 |
| NFR-003 | 性能 | KillSwitch 切换延迟 < 10ms | Benchmark `BenchmarkKillSwitch` | - | ⬜→§8 |
| NFR-004 | 质量 | 测试覆盖率 >= 80% | `go tool cover -func` | - | ⬜→§8 |
| NFR-005 | 安全 | 无硬编码密钥 | `gitleaks detect --no-git` | - | ⬜→§8 |

---

## §4 TC → FR 反向追溯

| TC | Covers FR(s) | Scenario | Command |
|----|-------------|----------|---------|
| TC-RSK-001 | FR-001, BR-001 | CheckOrder 短路求值，首个规则失败即拒绝；全部规则逐项校验 | `go test ./... -run TestCheckOrder` |
| TC-RSK-002 | FR-002, BR-003 | 回撤超过 maxDrawdown 拒绝新订单+emit 事件；降至 0.5x 以下恢复 | `go test ./... -run TestDrawdownControl` |
| TC-RSK-003 | FR-003, BR-002 | KillSwitch 立即取消挂单+拒绝新订单；状态持久化重启后仍生效；Resume 恢复 | `go test ./... -run TestKillSwitch` |
| TC-RSK-004 | FR-004 | 订单频率超 maxOrderRate 拒绝+返回 RATE_LIMITED；滑动窗口计数 | `go test ./... -run TestRateLimiting` |
| TC-RSK-005 | FR-005, BR-005 | 单 symbol 仓位占比超 maxConcentration 拒绝新增；减仓不受限制 | `go test ./... -run TestConcentration` |
| TC-RSK-006 | FR-006 | 风险指标输出 VaR(95%/99%)/Sharpe/MaxDrawdown/Calmar/Volatility；计算周期可配置 | `go test ./... -run TestRiskMetrics` |
| TC-RSK-007 | FR-007 | 风控 PASS/REJECT 均记录审计事件；审计事件不可删除 | `go test ./... -run TestRiskAudit` |
| TC-RSK-008 | FR-008, BR-004 | README H1 为 `# riskx`；go.mod 声明 `module github.com/ZoneCNH/riskx`；规则优先级正确 | `go test ./... -run TestModuleIdentity` |

---

## §5 全局 AC 注册表

| AC | 所属 FR/BR | 验收条件摘要 | Verification |
|----|-----------|-------------|--------------|
| AC-RSK-001 | FR-001 | CheckOrder 短路求值，首个失败即拒绝；全部规则逐项校验 | TC-RSK-001 |
| AC-RSK-002 | FR-002 | 回撤超 maxDrawdown 拒绝+emit 事件；降至 0.5x 以下恢复 | TC-RSK-002 |
| AC-RSK-003 | FR-003 | KillSwitch 取消挂单+拒绝新订单；持久化重启后生效；Resume 恢复 | TC-RSK-003 |
| AC-RSK-004 | FR-004 | 频率超限拒绝+RATE_LIMITED 错误；滑动窗口计数 | TC-RSK-004 |
| AC-RSK-005 | FR-005 | 集中度超限拒绝新增；减仓不受限制 | TC-RSK-005 |
| AC-RSK-006 | FR-006 | VaR(95%/99%)/Sharpe/MaxDrawdown/Calmar/Volatility；周期可配置 | TC-RSK-006 |
| AC-RSK-007 | FR-007 | PASS/REJECT 记录审计事件；不可删除 | TC-RSK-007 |
| AC-RSK-008 | FR-008 | README H1 为 `# riskx`；go.mod 声明 `module github.com/ZoneCNH/riskx` | TC-RSK-008 |

---

## §6 覆盖率仪表盘

| 指标 | 数值 | 说明 |
|------|------|------|
| FR 总数 | 8 | FR-001 ~ FR-008 |
| FR 有 AC 覆盖 | 8/8 (100%) | |
| FR 有 TC 覆盖 | 8/8 (100%) | |
| BR 总数 | 5 | BR-001 ~ BR-005 |
| BR 有验证机制 | 5/5 (100%) | |
| NFR 总数 | 5 | NFR-001 ~ NFR-005 |
| AC 总数 | 8 | AC-RSK-001 ~ AC-RSK-008 |
| TC 总数 | 8 | TC-RSK-001 ~ TC-RSK-008 |

---

## §7 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-25 | v1.2 | 新增 §8 Evidence 投影：对齐 STATUS.md 外部 CI 声明 |
| 2026-06-16 | v1.1 | 标准化为 §1-§7 结构；FR 表增加 WHEN/THEN 列；TC 表增加 Command 列；AC 表增加 Verification 列 |
| 2026-06-15 | v1.0 | 初始版本：8 FR + 5 BR + 5 NFR + 8 TC + 8 AC |

---

## §8 Evidence 投影（外部仓库 CI）

> 来源：`STATUS.md` 执行域明细表 `[KNOWN]`
> 认识论声明：以下为 STATUS.md 文档投影，非本会话独立验证；具体 TC↔test 文件映射与 CI run id 待外部仓库 evidence 归档。

| 投影项 | 数值 | 来源 | evidence 状态 |
|--------|------|------|---------------|
| riskx tests PASS | 7 | STATUS.md "7 tests PASS" | ⬜ 待归档（外部仓库 CI run id / test 文件路径） |
| 实现进度 | 40% | STATUS.md "████░ 40%" | `[FRAME]` 投影 |
| 最小实现范围 | 仓位上限/最大持仓/熔断门禁 | STATUS.md "最小实现（仓位上限/最大持仓/熔断门禁）" | ⬜ 待归档 |
| contracts 消费 | SignalIntent P1 DTO | STATUS.md "消费 contracts.SignalIntent P1 DTO" | ⬜ 待归档 |
| SPEC 状态 | Spec Approved / Tasks Pending | SPEC.md Metadata | `[KNOWN]` |

> **未闭合项**：7 tests 对应 §4 的 8 TC 中哪些尚未确认（7 tests 可能覆盖 8 TC 中的 7 个，或为不同粒度）；§4 TC 表已有 `go test ./... -run TestXxx` Command 列，evidence 归档时应填入实际 PASS 的 CI run id 与 test 输出路径。
