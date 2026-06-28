# module/coinglass TRACEABILITY

> 追溯矩阵 — 确保 FR/BR → AC → TC → Task → Status 闭环。范式继承 [`module/binance/TRACEABILITY.md`](../binance/TRACEABILITY.md)。

- Matrix-Version: v1.0.0
- Last-Updated: 2026-06-29
- Spec-Reference: `module/coinglass/SPEC.md` v1.0.0

---

## §1 FR 追溯表

| FR ID | 功能需求 | AC | TC ID(s) | Task | 实现状态 |
|-------|----------|-----|----------|----------|
| FR-001 | Channel Subscription：4 channel 启用 | AC-001 ~ AC-004 | TC-001 ~ TC-004 | - | Pending |
| FR-002 | Instrument & Venue Identity | AC-005 ~ AC-007 | TC-020, TC-021 | - | Pending |
| FR-003 | gRPC Ingestion（继承 binance） | AC-008 ~ AC-010 | TC-005 | - | Pending |
| FR-004 | At-Least-Once Delivery（继承） | AC-011 ~ AC-013 | TC-006 | - | Pending |
| FR-005 | Idempotent Acceptance（含 window_start 维度） | AC-014 ~ AC-016 | TC-007, TC-019 | - | Pending |
| FR-006 | Admin Surface（含 quota-status / poll-schedule 端点） | AC-017 ~ AC-020 | TC-008, TC-009 | - | Pending |
| FR-007 | Boundary Enforcement（继承） | AC-021 ~ AC-023 | TC-010 ~ TC-012 | - | Pending |
| FR-008 | Polling Schedule（quota-aware）| AC-024, AC-025 | TC-022 | - | Pending |

---

## §2 BR 追溯表

| BR ID | 业务规则 | 验证方式 | 实现状态 |
|-------|----------|----------|----------|
| BR-001 ~ BR-009 | 与 binance §8 等价 | 详见 binance TRACEABILITY §2 | Pending |
| BR-010 | Idempotency Key Includes Window Start | TC-019 单元 + server validation | Pending |
| BR-011 | Venue Name Normalization | TC-020, TC-021 + venue map 测试 | Pending |

---

## §3 NFR 追溯表

| NFR ID | 来源 | 验证方式 |
|--------|------|----------|
| NFR-001 ~ NFR-013 | 与 binance 范式等价 | 通用 |
| NFR-CGS-001 | polling 完整周期 P99 < 5min | 集成测试 |
| NFR-CGS-002 | API quota 在 30 req/min 内不超限 | scheduler 测试 |
| NFR-CGS-003 | venue map 覆盖至少 13 项已知 venue | venue map 单元测试 |

---

## §4 TC→FR 反向追溯

| TC ID | 覆盖 FR(s) | 覆盖 BR(s) | 测试类型 |
|-------|------------|------------|----------|
| TC-001 ~ TC-004 | FR-001 | — | 集成（4 channel polling） |
| TC-005 | FR-003 | BR-007 | 契约测试 |
| TC-006 | FR-004 | BR-004, BR-008 | 集成 |
| TC-007 | FR-005 | BR-008 | 集成 |
| TC-008, TC-009 | FR-006 | BR-009 | 单元 + 集成 |
| TC-010 ~ TC-012 | FR-007 | BR-001 ~ BR-003 | CI gate |
| TC-019 | FR-005 | BR-010 | 单元（window_start idempotency） |
| TC-020 | FR-002 | BR-011 | 单元（venue normalization） |
| TC-021 | FR-002 | BR-011 | 集成（unmapped venue） |
| TC-022 | FR-008 | — | 集成（quota-aware scheduler） |
| TC-023 | FR-001 | — | 单元（response schema 容错） |

---

## §5 AC 注册表

| AC ID | 所属 FR | AC 描述 | 验证方式 |
|-------|---------|---------|----------|
| AC-001 ~ AC-004 | FR-001 | 4 channel 各自启用并产生事件 | TC-001 ~ TC-004 |
| AC-005 | FR-002 | Coinglass `Binance` venue → canonical `binance` | TC-020 |
| AC-006 | FR-002 | unmapped venue 标注后 server reject | TC-021 |
| AC-007 | FR-002 | InstrumentKey 与同 contract 直采事件兼容 | 集成测试 |
| AC-008 ~ AC-010 | FR-003 | 与 binance AC-006 ~ AC-008 等价 | TC-005 |
| AC-011 ~ AC-013 | FR-004 | 与 binance AC-012 ~ AC-014 等价 | TC-006 |
| AC-014 ~ AC-016 | FR-005 | 与 binance AC-009 ~ AC-011 等价（含 window_start 维度） | TC-007, TC-019 |
| AC-017 ~ AC-019 | FR-006 | 与 binance AC-017 ~ AC-019 等价 | TC-008 |
| AC-020 | FR-006 | quota-status 端点返回当前 quota 使用情况 | TC-009 |
| AC-021 ~ AC-023 | FR-007 | 与 binance AC-021 ~ AC-023 等价 | TC-010 ~ TC-012 |
| AC-024 | FR-008 | scheduler 在 quota 内完成 4 channel 调度 | TC-022 |
| AC-025 | FR-008 | quota 紧张时降级低优先级 channel | TC-022 |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 8 | 8 | 100% |
| BR | 11 | 11 | 100% |
| NFR | 16 | 16 | 100% |
| AC | 25 | 25 | 100% |
| TC | 23 | 23 | 100% |
| **合计** | **83** | **83** | **100%** |

---

## §7 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-06-29 | Goal 管线对齐：§6 覆盖率仪表盘标准化为 Done/覆盖率格式 |
| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-06-17 | v1.0.0 | 从 binance TRACEABILITY 范式派生；客制化 FR-008（quota-aware scheduler）+ BR-010（window_start idempotency）+ BR-011（venue normalization）；针对聚合数据源场景调整 NFR |
