# module/okx TRACEABILITY

> 追溯矩阵 — 确保 FR/BR → AC → TC → Task → Status 闭环可追溯。
>
> 规范来源：`docs/governance/TRACEABILITY.md`。范式继承 [`module/binance/TRACEABILITY.md`](../binance/TRACEABILITY.md)。

- Matrix-Version: v1.0.0
- Last-Updated: 2026-06-17
- Spec-Reference: `module/okx/SPEC.md` v1.0.0

---

## §1 FR 追溯表

| FR ID | 功能需求 | AC | TC ID(s) | 实现状态 |
|-------|----------|-----|----------|----------|
| FR-001 | Product-Line Support：5 条产品线（Spot/Margin/USDⓈ-M/Coin-M/Options） | AC-001~AC-005 | TC-001 ~ TC-005 | Pending |
| FR-002 | Instrument Identity：5 product line canonical identity 不碰撞 | AC-006~AC-008 | TC-019, TC-002 ~ TC-006 | Pending |
| FR-003 | gRPC Ingestion（继承 binance FR-003） | AC-009~AC-011 | TC-007 | Pending |
| FR-004 | At-Least-Once Delivery（继承 binance FR-004） | AC-012~AC-014 | TC-008 | Pending |
| FR-005 | Idempotent Acceptance（继承 binance FR-005） | AC-015~AC-017 | TC-009, TC-010 | Pending |
| FR-006 | Admin Surface（继承 binance FR-006） | AC-018~AC-021 | TC-011, TC-012 | Pending |
| FR-007 | Boundary Enforcement（继承 binance FR-007） | AC-022~AC-024 | TC-013 ~ TC-015 | Pending |
| FR-008 | Simulated Endpoint Isolation（OKX 特异） | AC-025, AC-026 | TC-020, TC-021 | Pending |

---

## §2 BR 追溯表

| BR ID | 业务规则 | 验证方式 | 实现状态 |
|-------|----------|----------|----------|
| BR-001 ~ BR-009 | 与 binance §8 BR-001 ~ BR-009 等价 | 详见 [`module/binance/TRACEABILITY.md`](../binance/TRACEABILITY.md) §2 | Pending |
| BR-010 | Environment Isolation：simulated/production 不共存（OKX 特异） | TC-020 + 配置静态校验脚本 | Pending |

---

## §3 NFR 追溯表

| NFR ID | 来源 | 验证方式 |
|--------|------|----------|
| NFR-001 ~ NFR-013 | 与 binance §17/§18/§19 等价 | 范式一致；OKX event normalization P99 上调到 < 2ms |
| NFR-OKX-001 | source_metadata 4 字段全填且字段值合法 | 单元测试 + server validation |

---

## §4 TC→FR 反向追溯

| TC ID | 覆盖 FR(s) | 覆盖 BR(s) | 测试类型 |
|-------|------------|------------|----------|
| TC-001 ~ TC-005 | FR-001 | — | 集成（5 product line connector） |
| TC-006 ~ TC-008 | FR-002 | BR-005 | 单元（identity dimensions） |
| TC-009, TC-010 | FR-005 | BR-008 | 集成（idempotency） |
| TC-011, TC-012 | FR-006 | BR-009 | 单元（admin） |
| TC-013 ~ TC-015 | FR-007 | BR-001 ~ BR-003 | CI gate |
| TC-019 | FR-002 | BR-005 | 单元（Spot/Margin 同 symbol） |
| TC-020, TC-021 | FR-008 | BR-010 | 集成（environment isolation） |

---

## §5 AC 注册表

| AC ID | 所属 FR | AC 描述 | 验证方式 |
|-------|---------|---------|----------|
| AC-001 ~ AC-005 | FR-001 | 5 product line 各自的 connector 启动并采集 | TC-001 ~ TC-005 |
| AC-006 | FR-002 | Spot `BTC-USDT` 与 Margin `BTC-USDT` 不碰撞 | TC-019 |
| AC-007 | FR-002 | USDⓈ-M Perp `BTC-USDT-SWAP` 含 contract_code | TC-002 |
| AC-008 | FR-002 | Options `BTC-USD-240628-50000-C` 含 expiry+strike+option_type | TC-006 |
| AC-009 ~ AC-011 | FR-003 | 与 binance AC-006 ~ AC-008 等价 | TC-007 |
| AC-012 ~ AC-014 | FR-004 | 与 binance AC-012 ~ AC-014 等价 | TC-008 |
| AC-015 ~ AC-017 | FR-005 | 与 binance AC-009 ~ AC-011 等价 | TC-009, TC-010 |
| AC-018 ~ AC-021 | FR-006 | 与 binance AC-017 ~ AC-020 等价 | TC-011, TC-012 |
| AC-022 ~ AC-024 | FR-007 | 与 binance AC-021 ~ AC-023 等价 | TC-013 ~ TC-015 |
| AC-025 | FR-008 | client 同时配置 simulated 与 production → 启动失败 | TC-020 |
| AC-026 | FR-008 | event environment 与 client config 不一致 → reject + stream 关闭 | TC-021 |

---

## §6 覆盖率仪表盘

| 指标 | 总数 | 已覆盖 | 覆盖率 |
|------|------|--------|--------|
| FR | 8 | 8 | 100% |
| BR | 10 | 10 | 100%（BR-001 ~ 009 继承 binance + BR-010 OKX 特异） |
| NFR | 14 | 14 | 100%（13 继承 + 1 OKX 特异） |
| TC | 21 | 21 | 100%（TC-001 ~ 015 继承范式 + TC-019 ~ 021 OKX 特异） |
| AC | 26 | 26 | 100% |
| 实现状态 | — | 0/8 FR | 0%（Pending） |

---

## §7 变更历史

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-06-17 | v1.0.0 | 从 binance TRACEABILITY 范式派生；客制化 FR-008 + BR-010（simulated/production isolation）；新增 AC-025/026 + TC-019/020/021 |
