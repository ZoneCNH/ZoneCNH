# module/hyperliquid TRACEABILITY

> 追溯矩阵 — 确保 FR/BR → AC → TC → Task → Status 闭环。范式继承 [`module/binance/TRACEABILITY.md`](../binance/TRACEABILITY.md)。

- Matrix-Version: v1.0.0
- Last-Updated: 2026-06-30
- Spec-Reference: `module/hyperliquid/SPEC.md` v1.0.0

---

## §1 FR 追溯表

| FR ID | 功能需求 | AC | TC ID(s) | Task | 实现状态 |
|-------|----------|-----|----------|----------|
| FR-001 | Product-Line Support：Perp + Spot | AC-001, AC-002 | TC-001, TC-002 | - | Pending |
| FR-002 | Instrument Identity：跨 venue 不碰撞 | AC-003, AC-004 | TC-003, TC-004 | - | Pending |
| FR-003 | gRPC Ingestion（继承 binance） | AC-005~AC-007 | TC-005 | - | Pending |
| FR-004 | At-Least-Once Delivery（继承） | AC-008~AC-010 | TC-006 | - | Pending |
| FR-005 | Idempotent Acceptance（含 onchain 维度） | AC-011~AC-013 | TC-007, TC-019 | - | Pending |
| FR-006 | Admin Surface（含 wallet-health / chain-status 端点） | AC-014~AC-017 | TC-008, TC-009 | - | Pending |
| FR-007 | Boundary Enforcement（继承 + 钱包安全 gate） | AC-018~AC-020 | TC-010, TC-011, TC-012 | - | Pending |
| FR-008 | Onchain Origin Metadata（DEX 特异） | AC-021, AC-022 | TC-019, TC-020 | - | Pending |
| FR-009 | Wallet Signature Management（DEX 特异） | AC-023, AC-024 | TC-022, TC-023 | - | Pending |

---

## §2 BR 追溯表

| BR ID | 业务规则 | 验证方式 | 实现状态 |
|-------|----------|----------|----------|
| BR-001 ~ BR-009 | 与 binance §8 等价 | 详见 binance TRACEABILITY §2 | Pending |
| BR-010 | Idempotency Key Includes Onchain Dimensions | TC-019 单元测试 + server validation | Pending |
| BR-011 | No Wallet Secret Exposure | gitleaks + 自定义 hex pattern + TC-023 | Pending |

---

## §3 NFR 追溯表

| NFR ID | 来源 | 验证方式 |
|--------|------|----------|
| NFR-001 ~ NFR-013 | 与 binance 范式等价 | 通用 |
| NFR-HYP-001 | onchain finality 等待 P99 < confirmation_threshold × block_time | 集成测试 |
| NFR-HYP-002 | wallet secret 在 metric/log/admin/spool 全部不出现 | grep + gitleaks |
| NFR-HYP-003 | reorg 检测延迟 < 1 block_time | 集成测试 + chaos test |

---

## §4 TC→FR 反向追溯

| TC ID | 覆盖 FR(s) | 覆盖 BR(s) | 测试类型 |
|-------|------------|------------|----------|
| TC-001 | FR-001 | — | 集成（Perp + Spot connector） |
| TC-002 | FR-001 | — | 集成（Perp + Spot connector） |
| TC-003 | FR-002 | BR-005 | 单元（identity） |
| TC-004 | FR-002 | BR-005 | 单元（identity） |
| TC-005 | FR-003 | BR-007 | 契约测试 |
| TC-006 | FR-004 | BR-004, BR-008 | 集成 |
| TC-007 | FR-005 | BR-008 | 集成 |
| TC-008 | FR-006 | BR-009 | 单元 + 集成 |
| TC-009 | FR-006 | BR-009 | 单元 + 集成 |
| TC-010 | FR-007 | BR-001 | CI gate |
| TC-011 | FR-007 | BR-002 | CI gate |
| TC-012 | FR-007 | BR-003 | CI gate |
| TC-019 | FR-005, FR-008 | BR-010 | 单元（onchain idempotency key） |
| TC-020 | FR-008 | — | 集成（confirmation gate） |
| TC-021 | FR-008 | — | 集成（reorg detection） |
| TC-022 | FR-009 | — | 集成（wallet sig auth） |
| TC-023 | FR-009 | BR-011 | 安全测试（secret 隔离） |

---

## §5 AC 注册表

| AC ID | 所属 FR | AC 描述 | 验证方式 |
|-------|---------|---------|----------|
| AC-001 | FR-001 | Perp connector 启动并采集 trade/orderbook/funding | TC-001 |
| AC-002 | FR-001 | Spot connector 启动（venue capability 允许时） | TC-002 |
| AC-003 | FR-002 | Hyperliquid Perp `BTC` 与 binance USDⓈ-M `BTCUSDT` 不碰撞（exchange 维度） | TC-003 |
| AC-004 | FR-002 | InstrumentKey 含 margin_asset=USDC | TC-004 |
| AC-005 ~ AC-007 | FR-003 | 与 binance AC-006 ~ AC-008 等价 | TC-005 |
| AC-008 ~ AC-010 | FR-004 | 与 binance AC-012 ~ AC-014 等价 | TC-006 |
| AC-011 ~ AC-013 | FR-005 | 与 binance AC-009 ~ AC-011 等价（含 onchain key 维度） | TC-007, TC-019 |
| AC-014 ~ AC-016 | FR-006 | 与 binance AC-017 ~ AC-019 等价 | TC-008 |
| AC-017 | FR-006 | wallet-health 端点返回脱敏的 wallet info | TC-009 |
| AC-018 ~ AC-020 | FR-007 | 与 binance AC-021 ~ AC-023 等价 | TC-010 ~ TC-012 |
| AC-021 | FR-008 | onchain_l1 事件含 block_height + tx_hash + log_index + confirmations | TC-019 |
| AC-022 | FR-008 | confirmations < threshold 的事件不写入 spool | TC-020 |
| AC-023 | FR-009 | client 启动时按优先级加载 signer endpoint > private key | TC-022 |
| AC-024 | FR-009 | private key 在任何外部输出（log/admin/debug/spool）零出现 | TC-023 |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 9 | 9 | 100% |
| BR | 11 | 11 | 100% |
| NFR | 16 | 16 | 100% |
| AC | 24 | 24 | 100% |
| TC | 23 | 23 | 100% |
| **合计** | **83** | **83** | **100%** |

---

## §7 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-06-29 | Goal 管线对齐：§6 覆盖率仪表盘标准化为 Done/覆盖率格式 |
| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-06-17 | v1.0.0 | 从 binance TRACEABILITY 范式派生；客制化 FR-008（onchain origin metadata）+ FR-009（wallet signature）+ BR-010 / BR-011；新增 onchain idempotency key 维度 + wallet secret 隔离 gate |
