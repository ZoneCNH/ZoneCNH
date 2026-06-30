# strategyx 需求追溯矩阵

> 更新：2026-06-29
> 来源：module/strategyx/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

本矩阵追踪 strategyx v1.0.0 规格中所有功能需求、行为约束、非功能需求与测试用例/验收标准之间的完整追溯链路。

Last-Updated: 2026-06-30
---

## §1 FR 功能需求追溯

| FR ID | Requirement | AC ID(s) | TC ID(s) | Task | Verification | Status |
| ----- | ----------- | -------- | -------- | ---- | ------------ | ------ |
| FR-001 | Strategy Interface：Name/Version/Init/OnSignal 四方法；Signal 含 symbol/side/qty/confidence/reason | AC-STX-001 | TC-STX-001 | - | `go test ./... -race -count=1` | ✅ |
| FR-002 | Strategy Registry：Register 名称全局唯一；List 返回 (name,version,status)；支持运行时注册和卸载 | AC-STX-002 | TC-STX-002 | - | `go test ./... -race -count=1` | ✅ |
| FR-003 | Parameter Management：configx 注入不可变快照；参数描述含 name/type/default/min/max/description；热更新仅对新信号生效；变更记录 audit log | AC-STX-003 | TC-STX-003 | - | `go test ./... -race -count=1` | ✅ |
| FR-004 | Strategy Versioning：semver（major=信号逻辑改变，minor=参数新增，patch=修复）；旧版本不退市；backtestx 可回放指定版本 | AC-STX-004 | TC-STX-004 | - | `go test ./... -race -count=1` | ✅ |
| FR-005 | Signal Output：Signal 含 signalID(全局唯一)/strategy/timestamp/symbol/side/qty/confidence/reason；confidence < threshold 标记 WEAK | AC-STX-005 | TC-STX-005 | - | `go test ./... -race -count=1` | ✅ |
| FR-006 | Strategy Composition：信号合并 PRIORITY/WEIGHTED/UNANIMOUS；资金分配 EQUAL/PROPORTIONAL/KELLY；冲突解决+日志 | AC-STX-006 | TC-STX-006 | - | `go test ./... -race -count=1` | ✅ |
| FR-007 | Strategy Warm-up：WarmUp 完成后 Ready 状态；WarmUp 超时标记 Degraded | AC-STX-007 | TC-STX-007 | - | `go test ./... -race -count=1` | ✅ |
| FR-008 | Module Identity：README H1 为 `# strategyx`；Go module path 为 `github.com/ZoneCNH/strategyx` | AC-STX-008 | TC-STX-008 | - | `go test ./... -race -count=1` + `grep '^# strategyx' README.md` + `grep 'module github.com/ZoneCNH/strategyx' go.mod` | ✅ |

---

## §2 BR 行为约束追溯

| BR ID | Rule | TC ID(s) | Task | Verification | Status |
| ----- | ---- | -------- | ---- | ------------ | ------ |
| BR-001 | 策略名称全局唯一 | TC-STX-002 | - | 重复注册报错断言 | ✅ |
| BR-002 | 信号 confidence 必须为 0.0-1.0 | TC-STX-005 | - | confidence 范围断言 | ✅ |
| BR-003 | 策略未完成 WarmUp 前不得生成信号 | TC-STX-007 | - | WarmUp 前信号拦截断言 | ✅ |
| BR-004 | 资金分配比例之和必须为 1.0 | TC-STX-006 | - | 分配比例和断言 | ✅ |
| BR-005 | Strategy 接口变更时需要 major 版本升级 | TC-STX-004 | - | 接口变更版本断言 | ✅ |

---

## §3 NFR 非功能需求追溯

| NFR ID | Category | Requirement | Task | Verification | Status |
| ------ | -------- | ----------- | ---- | ------------ | ------ |
| NFR-001 | Performance | OnSignal 调用延迟 < 10ms | - | Benchmark | ✅ |
| NFR-002 | Performance | Compose (10 信号) 延迟 < 1ms | - | Benchmark | ✅ |
| NFR-003 | Performance | Registry.List 延迟 < 100μs | - | Benchmark | ✅ |
| NFR-004 | Quality | 测试覆盖率 >= 80% | - | `go test -coverprofile=/tmp/strategyx.cover ./... && go tool cover -func=/tmp/strategyx.cover` | ✅ |
| NFR-005 | Security | 无硬编码密钥 | - | `gitleaks detect --no-git` | ✅ |

---

## §4 TC→FR 反向追溯

| TC ID | Covers FR(s) | Command |
| ----- | ------------ | ------- |
| TC-STX-001 | FR-001 | `go test ./... -run 'TestStrategy' -race -count=1` |
| TC-STX-002 | FR-002, BR-001 | `go test ./... -run 'TestRegistry' -race -count=1` |
| TC-STX-003 | FR-003 | `go test ./... -run 'TestParam' -race -count=1` |
| TC-STX-004 | FR-004, BR-005 | `go test ./... -run 'TestVersion' -race -count=1` |
| TC-STX-005 | FR-005, BR-002 | `go test ./... -run 'TestSignal' -race -count=1` |
| TC-STX-006 | FR-006, BR-004 | `go test ./... -run 'TestCompos' -race -count=1` |
| TC-STX-007 | FR-007, BR-003 | `go test ./... -run 'TestWarmUp' -race -count=1` |
| TC-STX-008 | FR-008 | `go test ./... -run 'TestModule' -race -count=1`

---

## §5 AC 验收标准注册表

| AC ID | FR/BR Ref | Criterion | Verification | Status |
| ----- | --------- | --------- | ------------ | ------ |
| AC-STX-001 | FR-001 | Strategy 接口实现 Name/Version/Init/OnSignal 四个方法；Signal 包含 symbol/side/qty/confidence/reason；confidence 范围 0-1 | `go test ./... -run 'TestStrategy' -race -count=1` | ✅ |
| AC-STX-002 | FR-002 | strategy.Register 注册策略名称全局唯一，重复注册报错；registry.List 返回 (name, version, status)；支持运行时注册和卸载 | `go test ./... -run 'TestRegistry' -race -count=1` | ✅ |
| AC-STX-003 | FR-003 | 参数通过 configx 注入（不可变快照）；参数描述含 name/type/default/min/max/description；热更新仅对新信号生效；变更记录 audit log | `go test ./... -run 'TestParam' -race -count=1` | ✅ |
| AC-STX-004 | FR-004 | 策略版本遵循 semver（major=信号逻辑改变，minor=参数新增，patch=修复）；旧版本不退市；backtestx 可通过 version 参数回放指定版本 | `go test ./... -run 'TestVersion' -race -count=1` | ✅ |
| AC-STX-005 | FR-005 | Signal 包含 signalID(全局唯一)/strategy/timestamp/symbol/side/qty/confidence/reason；confidence < threshold 标记 WEAK | `go test ./... -run 'TestSignal' -race -count=1` | ✅ |
| AC-STX-006 | FR-006 | 信号合并策略 PRIORITY/WEIGHTED/UNANIMOUS 正确执行；资金分配 EQUAL/PROPORTIONAL/KELLY 正确计算；冲突信号按策略解决并记录日志 | `go test ./... -run 'TestCompos' -race -count=1` | ✅ |
| AC-STX-007 | FR-007 | WarmUp 完成后进入 Ready 状态；WarmUp 超时标记为 Degraded | `go test ./... -run 'TestWarmUp' -race -count=1` | ✅ |
| AC-STX-008 | FR-008 | README H1 为 `# strategyx`；Go module path 为 `github.com/ZoneCNH/strategyx`；go.mod 声明 `module github.com/ZoneCNH/strategyx` | `go test ./... -run 'TestModule' -race -count=1` | ✅ |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 8 | 8 | 100% |
| BR | 5 | 5 | 100% |
| NFR | 5 | 5 | 100% |
| AC | 8 | 8 | 100% |
| TC | 8 | 8 | 100% |
| **合计** | **34** | **34** | **100%** |

---

## §7 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-06-29 | Goal 管线对齐：§6 覆盖率仪表盘标准化为 Done/覆盖率格式 |
| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-16 | v1.1 | 列标准化：§1 新增 Verification 列；§2 新增 违反后果/Task/Status 列；§4 标准化为 TC ID/Covers FR(s)/Command（增强 -race -count=1）；§5 新增 Verification 列；§1/§4/§5 移除空 Task/Status 列 |
| 2026-06-15 | v1.0 | 初始版本：8 FR + 5 BR + 5 NFR + 8 TC + 8 AC |
