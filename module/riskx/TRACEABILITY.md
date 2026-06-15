# riskx 需求追溯矩阵

> 更新：2026-06-15
> 来源：module/riskx/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

---

## 1. 功能需求追溯（FR）

| FR | Description | Acceptance Criteria | Test Case | Task | Status |
|----|-------------|---------------------|-----------|------|--------|
| FR-001 | Pre-Trade Risk Check：CheckOrder 短路求值（maxOrderValue/maxPositionSize/maxDailyOrders/maxDailyVolume/禁止列表） | AC-RSK-001 | TC-RSK-001 | - | 🔲 |
| FR-002 | Drawdown Control：回撤超过 maxDrawdown 拒绝新订单并 emit 事件；降至 maxDrawdown*0.5 以下恢复 | AC-RSK-002 | TC-RSK-002 | - | 🔲 |
| FR-003 | Kill Switch：立即取消所有挂单+拒绝新订单；状态持久化重启后仍生效；Resume 恢复 | AC-RSK-003 | TC-RSK-003 | - | 🔲 |
| FR-004 | Rate Limiting：订单频率超 maxOrderRate 拒绝并返回 RATE_LIMITED；滑动窗口计数 | AC-RSK-004 | TC-RSK-004 | - | 🔲 |
| FR-005 | Concentration Control：单 symbol 仓位占比超 maxConcentration 拒绝新增仓位；减仓不受限制 | AC-RSK-005 | TC-RSK-005 | - | 🔲 |
| FR-006 | Risk Metrics：输出 VaR(95%/99%)、Sharpe、MaxDrawdown、Calmar、Volatility；计算周期可配置 | AC-RSK-006 | TC-RSK-006 | - | 🔲 |
| FR-007 | Risk Event Audit：PASS/REJECT 均记录审计事件；审计事件不可删除 | AC-RSK-007 | TC-RSK-007 | - | 🔲 |
| FR-008 | Module Identity：README H1 为 `# riskx`；Go module path 为 `github.com/ZoneCNH/riskx` | AC-RSK-008 | TC-RSK-008 | - | 🔲 |

---

## 2. 业务规则追溯（BR）

| BR | Description | 违反后果 | 验证方式 | Task | Status |
|----|-------------|----------|----------|------|--------|
| BR-001 | 所有订单必须通过 riskx 检查后才能提交交易所 | orderx 拒绝下单 | TC-RSK-001 风控调用链路断言 | - | 🔲 |
| BR-002 | KillSwitch 状态必须持久化 | 重启后恢复风控状态 | TC-RSK-003 持久化+重启恢复断言 | - | 🔲 |
| BR-003 | 回撤熔断有滞后恢复阈值（0.5x maxDrawdown） | 避免反复触发 | TC-RSK-002 滞后恢复断言 | - | 🔲 |
| BR-004 | 风控规则优先级：KillSwitch > Drawdown > PositionLimit > RateLimit | 保证最关键规则先执行 | TC-RSK-008 规则优先级断言 | - | 🔲 |
| BR-005 | 减仓不受集中度限制 | 风控不阻止降风险操作 | TC-RSK-005 减仓豁免断言 | - | 🔲 |

---

## 3. 非功能需求追溯（NFR）

| NFR | Description | 目标值 | 验证方式 | Task | Status |
|-----|-------------|--------|----------|------|--------|
| NFR-001 | CheckOrder 延迟 | < 1ms | Benchmark | - | 🔲 |
| NFR-002 | RiskMetrics 计算延迟 | < 100ms | Benchmark | - | 🔲 |
| NFR-003 | KillSwitch 切换延迟 | < 10ms | Benchmark | - | 🔲 |
| NFR-004 | 测试覆盖率 | >= 80% | `go tool cover -func` | - | 🔲 |
| NFR-005 | 无硬编码密钥 | 全仓扫描零命中 | `gitleaks detect --no-git` | - | 🔲 |

---

## 4. TC → FR 反向追溯

| TC | FR/BR | Given/When/Then 场景 |
|----|-------|---------------------|
| TC-RSK-001 | FR-001, BR-001 | CheckOrder 短路求值，首个规则失败即拒绝；全部规则逐项校验 |
| TC-RSK-002 | FR-002, BR-003 | 回撤超过 maxDrawdown 拒绝新订单+emit 事件；降至 0.5x 以下恢复 |
| TC-RSK-003 | FR-003, BR-002 | KillSwitch 立即取消挂单+拒绝新订单；状态持久化重启后仍生效；Resume 恢复 |
| TC-RSK-004 | FR-004 | 订单频率超 maxOrderRate 拒绝+返回 RATE_LIMITED；滑动窗口计数 |
| TC-RSK-005 | FR-005, BR-005 | 单 symbol 仓位占比超 maxConcentration 拒绝新增；减仓不受限制 |
| TC-RSK-006 | FR-006 | 风险指标输出 VaR(95%/99%)/Sharpe/MaxDrawdown/Calmar/Volatility；计算周期可配置 |
| TC-RSK-007 | FR-007 | 风控 PASS/REJECT 均记录审计事件；审计事件不可删除 |
| TC-RSK-008 | FR-008, BR-004 | README H1 为 `# riskx`；go.mod 声明 `module github.com/ZoneCNH/riskx`；规则优先级正确 |

---

## 5. 全局 AC 注册表

| AC | 所属 FR/BR | 验收条件摘要 |
|----|-----------|-------------|
| AC-RSK-001 | FR-001 | CheckOrder 短路求值，首个失败即拒绝；全部规则逐项校验 |
| AC-RSK-002 | FR-002 | 回撤超 maxDrawdown 拒绝+emit 事件；降至 0.5x 以下恢复 |
| AC-RSK-003 | FR-003 | KillSwitch 取消挂单+拒绝新订单；持久化重启后生效；Resume 恢复 |
| AC-RSK-004 | FR-004 | 频率超限拒绝+RATE_LIMITED 错误；滑动窗口计数 |
| AC-RSK-005 | FR-005 | 集中度超限拒绝新增；减仓不受限制 |
| AC-RSK-006 | FR-006 | VaR(95%/99%)/Sharpe/MaxDrawdown/Calmar/Volatility；周期可配置 |
| AC-RSK-007 | FR-007 | PASS/REJECT 记录审计事件；不可删除 |
| AC-RSK-008 | FR-008 | README H1 为 `# riskx`；go.mod 声明 `module github.com/ZoneCNH/riskx` |

---

## 6. 覆盖率仪表盘

| 指标 | 数值 | 说明 |
|------|------|------|
| FR 总数 | 8 | FR-001 ~ FR-008 |
| FR 有 AC 覆盖 | 8/8 (100%) | |
| FR 有 TC 覆盖 | 8/8 (100%) | |
| BR 总数 | 5 | BR-001 ~ BR-005 |
| BR 有 TC 覆盖 | 5/5 (100%) | |
| NFR 总数 | 5 | NFR-001 ~ NFR-005 |
| AC 总数 | 8 | AC-RSK-001 ~ AC-RSK-008 |
| TC 总数 | 8 | TC-RSK-001 ~ TC-RSK-008 |

---

## 7. 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-15 | v1.0 | 初始版本：8 FR + 5 BR + 5 NFR + 8 TC + 8 AC |
