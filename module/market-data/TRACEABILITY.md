# module/market-data TRACEABILITY

- Spec-Version: v0.1.0
- Last-Updated: 2026-06-17
- Status: Docs Baseline Published

Status semantics: `Baseline Published` 表示文档中的 dispatch/receiving contract 已对齐且可被下游引用；runtime 实现和测试为 Pending。

---

## §1 FR 追溯表

| FR ID | 功能需求 | AC | TC ID(s) | 实现状态 |
| --- | --- | --- | --- | --- |
| FR-MD-001 | dispatch-port：Binance adapter 完成事件归一化后提交事件 | AC-MD-001 | TC-MD-001 | Baseline Published |
| FR-MD-002 | canonical-input：接收侧输入必须引用 domain-market canonical 语义 | AC-MD-002 | TC-MD-002 | Baseline Published |
| FR-MD-003 | idempotency：同一 idempotencyKey 的重复提交确定 outcome | AC-MD-003 | TC-MD-003 | Baseline Published |
| FR-MD-004 | ordering：同一 orderingKey 下检测 sequence 倒退、跳跃和重复 | AC-MD-003 | TC-MD-004 | Baseline Published |
| FR-MD-005 | quality-gate：eventTime/receivedAt/quality 不合法时 fail-closed | AC-MD-004 | TC-MD-005 | Baseline Published |
| FR-MD-006 | retry-classification：区分不可重试 reject 与可重试 failure | AC-MD-004 | TC-MD-006 | Baseline Published |
| FR-MD-007 | batch-semantics：批量提交逐条返回 outcome | AC-MD-005 | TC-MD-007 | Baseline Published |
| FR-MD-008 | observability：dispatch outcome 可按关键维度统计 | AC-MD-005 | TC-MD-008 | Baseline Published |

## §2 BR 追溯表

| BR ID | 业务规则 | 验证方式 | 实现状态 |
| --- | --- | --- | --- |
| BR-MD-001 | adapter 不得绕过 dispatch port 直写下游 | CI import check | Baseline Published |
| BR-MD-002 | dispatch 输入必须是 domain-market MarketFactEnvelope | CI type/lint check | Baseline Published |
| BR-MD-003 | dispatch port 不定义 vendor DTO 或 wire schema | spec lint | Baseline Published |
| BR-MD-004 | stale/future/dirty 数据必须 fail-closed | 测试用例 | Baseline Published |
| BR-MD-005 | adapter 不得将 DispatchFailure 当作成功 | 测试用例 | Baseline Published |
| BR-MD-006 | 本次任务只更新 markdown 文档 | 文件变更审计 | Baseline Published |

## §3 NFR 追溯表

| NFR ID | 非功能需求 | 来源(SPEC §) | 验证方式 |
| --- | --- | --- | --- |
| NFR-MD-001 | dispatch 延迟 < 100us（不含 I/O） | §17 | benchmark |
| NFR-MD-002 | 批量 dispatch(100) < 1ms（不含 I/O） | §17 | benchmark |
| NFR-MD-003 | metrics 按 venue/productLine/channel/outcome/reason 维度暴露 | §18 | metrics 检查 |

## §4 TC→FR 反向追溯

| TC ID | 覆盖 FR(s) | 测试类型 | 状态 |
| --- | --- | --- | --- |
| TC-MD-001 | FR-MD-001 | 文档引用检查 | Baseline Published |
| TC-MD-002 | FR-MD-002 | 边界扫描 | Baseline Published |
| TC-MD-003 | FR-MD-003, FR-MD-004 | 任务基线检查 | Baseline Published |
| TC-MD-004 | FR-MD-003, FR-MD-004 | 任务基线检查 | Baseline Published |
| TC-MD-005 | FR-MD-005 | TRACEABILITY 检查 | Baseline Published |
| TC-MD-006 | FR-MD-006 | TRACEABILITY 检查 | Baseline Published |
| TC-MD-007 | FR-MD-007 | TRACEABILITY 检查 | Baseline Published |
| TC-MD-008 | FR-MD-008 | TRACEABILITY 检查 | Baseline Published |
| TC-MD-009 | BR-MD-006 | 文件变更审计 | Baseline Published |

## §5 AC 注册表

| AC ID | 所属 FR/BR | AC 描述 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| AC-MD-001 | FR-MD-001, BR-MD-001 | Binance SPEC 可明确以 downstream dispatch port 作为行情事件交付边界，禁止直写下游 | 文档引用检查 | Baseline Published |
| AC-MD-002 | FR-MD-002, BR-MD-002, BR-MD-003 | 输入仅引用 ProductLine、InstrumentKey、MarketFactEnvelope canonical 语义 | 边界扫描 | Baseline Published |
| AC-MD-003 | FR-MD-003, FR-MD-004 | 幂等与排序规则可直接转化为测试 | TC-MD-003, TC-MD-004 | Baseline Published |
| AC-MD-004 | FR-MD-005, FR-MD-006, BR-MD-004, BR-MD-005 | reject/failure 分类与 retryable 语义明确 | TC-MD-005, TC-MD-006 | Baseline Published |
| AC-MD-005 | FR-MD-007, FR-MD-008, NFR-MD-001, NFR-MD-003 | 批量 outcome 与观测维度完整 | TC-MD-007, TC-MD-008 | Baseline Published |
| AC-MD-006 | BR-MD-006 | 本次任务只更新 markdown 文档，无运行时代码或依赖 | TC-MD-009 | Baseline Published |

## §6 覆盖率仪表盘

| 指标 | 数量 |
| --- | --- |
| 总 FR | 8 |
| 总 BR | 6 |
| 总 NFR | 3 |
| 总 TC | 9 |
| 总 AC | 6 |
| FR 覆盖率 | 100% (8/8) |
| BR 覆盖率 | 100% (6/6) |

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0 | 初始 docs baseline：全部 FR/BR/NFR/TC/AC 定义 | ZoneCNH |
