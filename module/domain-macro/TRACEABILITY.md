# domain-macro 需求追溯矩阵

> 更新：2026-06-16
> 来源：module/domain-macro/SPEC.md v1.0.0
> 规范：docs/governance/TRACEABILITY.md

---

## §1 功能需求追溯（FR）

| FR | Description | WHEN | THEN | AC | TC | Task | Status |
|----|-------------|------|------|----|----|------|--------|
| FR-MAC-001 | macropoint-time | 构造 MacroPoint | ObservedAt/ReleasedAt/AvailableAt 三类时间语义固定；AvailableAt 缺失时 Validate 失败 | AC-MAC-001 | TC-MAC-001 | - | 🔲 |
| FR-MAC-002 | macropoint-revision | 同一 SeriesCode+ObservedAt 存在多个 revision | RevisionVersion >= 0 且用于 deterministic ordering；preliminary/final 标识可追溯 | AC-MAC-002 | TC-MAC-003 | - | 🔲 |
| FR-MAC-003 | visibility | 调用 IsVisibleAt(decisionTime) | ObservedAt/ReleasedAt/AvailableAt 任一晚于 decisionTime 则不可见；AvailableAt 缺失时不可见 | AC-MAC-003 | TC-MAC-001, TC-MAC-002, TC-MAC-005 | - | 🔲 |
| FR-MAC-004 | information-set | 构造 MacroInformationSet | Points 只含 IsVisibleAt(DecisionTime) 为 true 的数据；copy-on-write 防止外部修改 | AC-MAC-004 | TC-MAC-004, TC-MAC-006 | - | 🔲 |
| FR-MAC-005 | revision-selection | 同一 SeriesCode+ObservedAt 有多版本可见 | 选择最高 RevisionVersion；preliminary 不得覆盖 final 除非 revision 更高且可见 | AC-MAC-005 | TC-MAC-003, TC-MAC-005 | - | 🔲 |
| FR-MAC-006 | macrostate | 构造 MacroState | 枚举 recovery/expansion/slowdown/contraction 稳定；IsValid() 可校验 | AC-MAC-006 | TC-MAC-003 | - | 🔲 |
| FR-MAC-007 | precision | 宏观值精度决策 | 推荐采用 decimalx.Decimal；若保留 float64 须标为派生/convenience 并保留 decimal 原始值 | AC-MAC-007 | - | - | 🔲 |
| FR-MAC-008 | provider-dto | provider DTO 边界 | yahoo_models 等 DTO 须迁入 internal 或 infra；公共 API 仅暴露中立模型 | AC-MAC-008 | TC-MAC-007 | - | 🔲 |

---

## §2 业务规则追溯（BR）

| BR | Rule | 违反后果 | Verification Method | Task | Status |
|----|------|----------|---------------------|------|--------|
| BR-MAC-001 | IsVisibleAt 必须 fail-closed：缺失 AvailableAt 的点不可见 | 前视偏差，回测结果不可信 | TC-MAC-001 缺失 AvailableAt 拒绝断言；TC-MAC-002 IsVisibleAt 返回 false | - | 🔲 |
| BR-MAC-002 | FilterMacroPointsForBacktest 必须拒绝缺失 AvailableAt 的点，避免前视偏差 | 回测引入未来信息，策略评估失真 | TC-MAC-001 Validate 失败拒绝；Property 测试随机时间组合验证 | - | 🔲 |
| BR-MAC-003 | MacroInformationSet 构造器 copy-on-write：getter 返回 slice 副本 | 外部修改污染内部状态，信息集不再 deterministic | TC-MAC-004 copy-on-write 断言；Race 测试并发读取 | - | 🔲 |
| BR-MAC-004 | 同一 DecisionTime + 同一输入数据 → MacroInformationSet 输出 deterministic | 回测不可重现 | Fuzz 测试随机 MacroPoint 集合验证确定性；TC-MAC-003 revision selection 确定性 | - | 🔲 |
| BR-MAC-005 | DataFreshnessSec 规则：无可见点时返回 -1 或特殊值；未来数据拒绝 | freshness 指标不可靠 | TC-MAC-001/TC-MAC-002 无可见点时返回 -1 | - | 🔲 |
| BR-MAC-006 | provider DTO 不得污染 domain Public API | 领域模型与 provider 耦合，升级 provider 时公共 API 破坏 | TC-MAC-007 provider DTO 边界检查；lint：domain 原始值不暴露外键 DTO | - | 🔲 |

---

## §3 非功能需求追溯（NFR）

| NFR | Category | Requirement | Verification | Task | Status |
|-----|----------|-------------|--------------|------|--------|
| NFR-MAC-001 | 回测安全 | 任何不可见数据默认拒绝，禁止 look-ahead | TC-MAC-002 IsVisibleAt fail-closed；Property 测试随机时间组合不泄露未来数据 | - | 🔲 |
| NFR-MAC-002 | 可审计 | 来源、修订、初值/终值和 freshness 指标可追溯 | TC-MAC-001 时间字段完整性；TC-MAC-003 revision 可追溯；Metrics 输出 JSON 证据报告 | - | 🔲 |
| NFR-MAC-003 | 领域纯净 | 公共模型不包含 provider DTO 或 transport schema | TC-MAC-007 provider DTO 不在公共 API 泄漏；`staticcheck ./...` 无 DTO 污染 | - | 🔲 |
| NFR-MAC-004 | 性能 | IsVisibleAt 延迟 < 100ns | Benchmark `BenchmarkIsVisibleAt` | - | 🔲 |
| NFR-MAC-005 | 性能 | FilterMacroPointsForBacktest（1000 点）< 1ms | Benchmark `BenchmarkFilterMacroPoints` | - | 🔲 |
| NFR-MAC-006 | 性能 | MacroInformationSet 构造（copy-on-write）< 500μs | Benchmark `BenchmarkMacroInformationSet` | - | 🔲 |

---

## §4 TC → FR 反向追溯

| TC | Covers FR(s) | Scenario | Command |
|----|-------------|----------|---------|
| TC-MAC-001 | FR-MAC-001, FR-MAC-003, BR-MAC-001, BR-MAC-002, BR-MAC-005 | 缺失 AvailableAt 的 MacroPoint → Validate 失败 | `GOWORK=off go test ./... -run TestMacroPointValidate` |
| TC-MAC-002 | FR-MAC-003, BR-MAC-001, BR-MAC-005 | DecisionTime 之后 AvailableAt 的点 → IsVisibleAt 返回 false | `GOWORK=off go test ./... -run TestIsVisibleAt` |
| TC-MAC-003 | FR-MAC-002, FR-MAC-005, FR-MAC-006, BR-MAC-004 | 同一 SeriesCode+ObservedAt 多 revision → 选择最高可见版本 | `GOWORK=off go test ./... -run TestRevisionSelection` |
| TC-MAC-004 | FR-MAC-004, BR-MAC-003 | MacroInformationSet 不暴露可变内部 slice（copy-on-write） | `GOWORK=off go test ./... -run TestCopyOnWrite` |
| TC-MAC-005 | FR-MAC-003, FR-MAC-005 | 未来修订版本不可见 | `GOWORK=off go test ./... -run TestFutureRevision` |
| TC-MAC-006 | FR-MAC-004 | 并发读取 MacroInformationSet 无 data race | `GOWORK=off go test -race ./...` |
| TC-MAC-007 | FR-MAC-008, BR-MAC-006 | provider DTO 不在 domain Public API 泄漏 | `GOWORK=off go test ./... -run TestProviderDTOBoundary` |

---

## §5 全局 AC 注册表

| AC | 所属 FR/BR | 验收条件摘要 | Verification |
|----|-----------|-------------|--------------|
| AC-MAC-001 | FR-MAC-001 | 三类时间字段含义稳定：ObservedAt 统计观测时间、ReleasedAt 数据发布时间、AvailableAt 数据可用时间；AvailableAt 缺失时 Validate 失败 | TC-MAC-001 time invariant tests |
| AC-MAC-002 | FR-MAC-002 | revision/preliminary/source 可审计：RevisionVersion >= 0、IsPreliminary 标识、Source 来源可追溯 | TC-MAC-003 revision ordering + Golden 测试 |
| AC-MAC-003 | FR-MAC-003 | IsVisibleAt fail-closed：AvailableAt 缺失或晚于 decisionTime 时不可见；DecisionTime 恰好等于 AvailableAt 时可见（含边界） | TC-MAC-001/TC-MAC-002 visibility table tests + Property 测试 |
| AC-MAC-004 | FR-MAC-004 | AsOf/构造仅返回可见数据并 copy-on-write：Points 只含 IsVisibleAt(DecisionTime)=true 的数据；getter 返回 slice 副本 | TC-MAC-004 information set tests + TC-MAC-006 race tests |
| AC-MAC-005 | FR-MAC-005 | RevisionVersion 非负且排序确定：选择最高可见 RevisionVersion；preliminary 不得覆盖 final 除非 revision 更高 | TC-MAC-003 revision selection + TC-MAC-005 future revision tests |
| AC-MAC-006 | FR-MAC-006 | MacroState/MacroRegimeCard validate 稳定：枚举 recovery/expansion/slowdown/contraction 稳定；IsValid() 返回正确 | TC-MAC-003 enum validation tests |
| AC-MAC-007 | FR-MAC-007 | 精度 ADR 与迁移测试完成：decimalx.Decimal 采纳或 float64 兼容退出路线明确；float64 须标为派生/convenience 并保留 decimal 原始值 | `GOWORK=off make adoption-check` + ADR 文档 |
| AC-MAC-008 | FR-MAC-008, BR-MAC-006 | provider DTO 不污染 domain Public API：yahoo_models 等 DTO 已迁入 internal 或 infra 层；公共 API 仅暴露中立模型 | TC-MAC-007 DTO 边界检查 + lint 扫描 |

---

## §6 覆盖率仪表盘

| 指标 | 数值 | 说明 |
|------|------|------|
| FR 总数 | 8 | FR-MAC-001 ~ FR-MAC-008 |
| FR 有 AC 覆盖 | 8/8 (100%) | |
| FR 有 TC 覆盖 | 7/8 (87.5%) | FR-MAC-007 精度 ADR 由 adoption-check 验证，非传统 TC |
| BR 总数 | 6 | BR-MAC-001 ~ BR-MAC-006 |
| BR 有验证机制 | 6/6 (100%) | |
| NFR 总数 | 6 | NFR-MAC-001 ~ NFR-MAC-006 |
| AC 总数 | 8 | AC-MAC-001 ~ AC-MAC-008 |
| TC 总数 | 7 | TC-MAC-001 ~ TC-MAC-007 |

---

## §7 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-16 | v1.1 | 重构为 5 节标准结构：§1 FR 追溯 / §2 BR 追溯 / §3 NFR 追溯 / §4 TC→FR 反向 / §5 AC 注册表；新增 FR-MAC-008 AC-MAC-008 |
| 2026-06-15 | v1.0 | 初始版本：7 FR + 6 BR + 7 TC + 7 AC |
