# strategyx 需求追溯矩阵

> 更新：2026-06-15
> 来源：module/strategyx/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

---

## 1. 功能需求追溯（FR）

| FR | Description | Acceptance Criteria | Test Case | Task | Status |
|----|-------------|---------------------|-----------|------|--------|
| FR-001 | Strategy Interface：Name/Version/Init/OnSignal 四方法；Signal 含 symbol/side/qty/confidence/reason | AC-STX-001 | TC-STX-001 | - | 🔲 |
| FR-002 | Strategy Registry：Register 名称全局唯一；List 返回 (name,version,status)；支持运行时注册和卸载 | AC-STX-002 | TC-STX-002 | - | 🔲 |
| FR-003 | Parameter Management：configx 注入不可变快照；参数描述含 name/type/default/min/max/description；热更新仅对新信号生效；变更记录 audit log | AC-STX-003 | TC-STX-003 | - | 🔲 |
| FR-004 | Strategy Versioning：semver（major=信号逻辑改变，minor=参数新增，patch=修复）；旧版本不退市；backtestx 可回放指定版本 | AC-STX-004 | TC-STX-004 | - | 🔲 |
| FR-005 | Signal Output：Signal 含 signalID(全局唯一)/strategy/timestamp/symbol/side/qty/confidence/reason；confidence < threshold 标记 WEAK | AC-STX-005 | TC-STX-005 | - | 🔲 |
| FR-006 | Strategy Composition：信号合并 PRIORITY/WEIGHTED/UNANIMOUS；资金分配 EQUAL/PROPORTIONAL/KELLY；冲突解决+日志 | AC-STX-006 | TC-STX-006 | - | 🔲 |
| FR-007 | Strategy Warm-up：WarmUp 完成后 Ready 状态；WarmUp 超时标记 Degraded | AC-STX-007 | TC-STX-007 | - | 🔲 |
| FR-008 | Module Identity：README H1 为 `# strategyx`；Go module path 为 `github.com/ZoneCNH/strategyx` | AC-STX-008 | TC-STX-008 | - | 🔲 |

---

## 2. 业务规则追溯（BR）

| BR | Description | 违反后果 | 验证方式 | Task | Status |
|----|-------------|----------|----------|------|--------|
| BR-001 | 策略名称全局唯一 | 注册失败 | TC-STX-002 重复注册报错断言 | - | 🔲 |
| BR-002 | 信号 confidence 必须为 0.0-1.0 | 拒绝信号 | TC-STX-005 confidence 范围断言 | - | 🔲 |
| BR-003 | 策略未完成 WarmUp 前不得生成信号 | 跳过策略 | TC-STX-007 WarmUp 前信号拦截断言 | - | 🔲 |
| BR-004 | 资金分配比例之和必须为 1.0 | 拒绝分配 | TC-STX-006 分配比例和断言 | - | 🔲 |
| BR-005 | Strategy 接口变更时需要 major 版本升级 | 旧版本不可用 | TC-STX-004 接口变更版本断言 | - | 🔲 |

---

## 3. 非功能需求追溯（NFR）

| NFR | Description | 目标值 | 验证方式 | Task | Status |
|-----|-------------|--------|----------|------|--------|
| NFR-001 | OnSignal 调用延迟 | < 10ms | Benchmark | - | 🔲 |
| NFR-002 | Compose (10 信号) 延迟 | < 1ms | Benchmark | - | 🔲 |
| NFR-003 | Registry.List 延迟 | < 100μs | Benchmark | - | 🔲 |
| NFR-004 | 测试覆盖率 | >= 80% | `go tool cover -func` | - | 🔲 |
| NFR-005 | 无硬编码密钥 | 全仓扫描零命中 | `gitleaks detect --no-git` | - | 🔲 |

---

## 4. TC → FR 反向追溯

| TC | FR/BR | Given/When/Then 场景 |
|----|-------|---------------------|
| TC-STX-001 | FR-001 | Strategy 接口实现 Name/Version/Init/OnSignal；Signal 包含完整字段；confidence 0-1 |
| TC-STX-002 | FR-002, BR-001 | Register 注册成功；重名报错；List 返回 (name,version,status)；支持运行时注册和卸载 |
| TC-STX-003 | FR-003 | 参数通过 configx 注入（不可变快照）；参数描述完整；热更新仅对新信号生效；变更记录 audit log |
| TC-STX-004 | FR-004, BR-005 | 策略版本遵循 semver；旧版本不退市；backtestx 可通过 version 回放 |
| TC-STX-005 | FR-005, BR-002 | Signal 含 signalID(全局唯一)/strategy/timestamp/symbol/side/qty/confidence/reason；confidence < threshold 标记 WEAK |
| TC-STX-006 | FR-006, BR-004 | 信号合并 PRIORITY/WEIGHTED/UNANIMOUS 正确；资金分配 EQUAL/PROPORTIONAL/KELLY 正确；冲突解决+日志；分配比例和为 1 |
| TC-STX-007 | FR-007, BR-003 | WarmUp 完成后 Ready；WarmUp 超时 Degraded；未完成 WarmUp 前不生成信号 |
| TC-STX-008 | FR-008 | README H1 为 `# strategyx`；go.mod 声明 `module github.com/ZoneCNH/strategyx` |

---

## 5. 全局 AC 注册表

| AC | 所属 FR/BR | 验收条件摘要 |
|----|-----------|-------------|
| AC-STX-001 | FR-001 | Strategy 接口四方法；Signal 包含完整字段；confidence 0-1 |
| AC-STX-002 | FR-002 | Register 名称唯一；List 返回信息；运行时注册/卸载 |
| AC-STX-003 | FR-003 | 参数不可变快照；描述完整；热更新仅对新信号生效；audit log |
| AC-STX-004 | FR-004 | semver 版本；旧版本不退市；backtestx 可回放指定版本 |
| AC-STX-005 | FR-005 | Signal 含 signalID(全局唯一)/strategy/timestamp/symbol/side/qty/confidence/reason；WEAK 标记 |
| AC-STX-006 | FR-006 | 合并策略+分配策略正确；冲突解决+日志；分配比例和为 1 |
| AC-STX-007 | FR-007 | WarmUp→Ready；超时→Degraded |
| AC-STX-008 | FR-008 | README H1 为 `# strategyx`；go.mod 声明 `module github.com/ZoneCNH/strategyx` |

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
| AC 总数 | 8 | AC-STX-001 ~ AC-STX-008 |
| TC 总数 | 8 | TC-STX-001 ~ TC-STX-008 |

---

## 7. 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-15 | v1.0 | 初始版本：8 FR + 5 BR + 5 NFR + 8 TC + 8 AC |
