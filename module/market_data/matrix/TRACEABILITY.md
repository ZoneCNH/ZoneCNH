# market_data 需求追溯矩阵

- Spec-Version: v1.0.0
- Last-Updated: 2026-06-30
- Status: Approved (SPEC v1.0.0-spec)

Status semantics: `Approved` 表示 SPEC 已通过审计、跨模块契约引用链闭合；`Runtime Pending` 表示 Go 实现与 TC-MD-003~008 测试未执行。

---

## §1 FR 追溯表

| FR ID | 功能需求 | AC | TC ID(s) | Task | 实现状态 |
| --- | --- | --- | --- | --- | --- |
| FR-MD-001 | dispatch-port：Binance adapter 完成事件归一化后提交事件 | AC-MD-001 | TC-MD-001 | TASK-MD-001 | Approved |
| FR-MD-002 | canonical-input：接收侧输入必须引用 domain_market canonical `MarketFactEnvelope` 语义，不允许 Binance 原始 DTO 泄漏 | AC-MD-002 | TC-MD-002 | TASK-MD-002 | Approved |
| FR-MD-003 | idempotency：同一 idempotencyKey 相同 payload 返回幂等 ack，不同 payload 返回 reject | AC-MD-003 | TC-MD-003 | TASK-MD-003 | Approved |
| FR-MD-004 | ordering：同一 orderingKey 下检测 sequence 倒退、跳跃和重复 | AC-MD-003 | TC-MD-004 | TASK-MD-004 | Approved |
| FR-MD-005 | quality-gate：eventTime/receivedAt/quality 不合法时 fail-closed | AC-MD-004 | TC-MD-005 | TASK-MD-005 | Approved |
| FR-MD-006 | retry-classification：区分不可重试 reject 与可重试 failure | AC-MD-004 | TC-MD-006 | TASK-MD-006 | Approved |
| FR-MD-007 | batch-semantics：批量提交逐条返回 outcome | AC-MD-005 | TC-MD-007 | TASK-MD-007 | Approved |
| FR-MD-008 | observability：dispatch outcome 可按 venue/productLine/channel/outcome/reason 统计 | AC-MD-005 | TC-MD-008 | TASK-MD-008 | Approved |

## §2 BR 追溯表

| BR ID | 业务规则 | 验证方式 | Task | 实现状态 |
| --- | --- | --- | --- | --- |
| BR-MD-001 | 不拥有交易所 adapter；Binance 原始响应只能停留在 `module/binance` adapter 边界内 | CI import check + spec boundary scan | TASK-MD-009 | Approved |
| BR-MD-002 | 不拥有 canonical market entity；领域语义归 `module/domain_market` | CI type/lint check | TASK-MD-010 | Approved |
| BR-MD-003 | 不拥有跨进程 wire schema；protobuf/gRPC/REST schema 归 `module/contracts` | spec lint | TASK-MD-011 | Approved |
| BR-MD-004 | 接收侧对 contract、quality、idempotency 与 ordering 问题 fail-closed，不做静默修正 | 测试用例 | TASK-MD-012 | Approved |
| BR-MD-005 | adapter 不得将 DispatchFailure 当作成功；必须按 retry policy 或上游 backpressure 处理 | 测试用例 | TASK-MD-013 | Approved |
| BR-MD-006 | 文档批准前不得新增运行时代码、依赖、存储表或队列 topic | 文件变更审计 | TASK-MD-014 | Approved |

## §3 NFR 追溯表

| NFR ID | 非功能需求 | 来源(SPEC §) | Task | 验证方式 |
| --- | --- | --- | --- | --- |
| NFR-MD-001 | 可审计性：每个 outcome 必须包含 outcome、reason、idempotencyKey、orderingKey 与 retryable 分类 | §7 | TASK-MD-015 | 审计日志检查 |
| NFR-MD-002 | 稳定性：v0.1.0 后 outcome 分类与幂等语义不得破坏性变更；变更需迁移说明 | §7 | TASK-MD-016 | version diff check |
| NFR-MD-003 | 可观测性：指标维度至少包含 venue、productLine、channel、outcome、reason | §7 | TASK-MD-017 | metrics 检查 |
| NFR-MD-004 | 边界纯净：本模块文档与后续 public API 不得暴露 vendor DTO、transport tag 或 storage tag | §7 | TASK-MD-018 | spec lint + API lint |

## §4 TC->FR 反向追溯

| TC ID | 覆盖 FR(s) | 测试类型 | 状态 |
| --- | --- | --- | --- |
| TC-MD-001 | FR-MD-001 | 文档引用检查 | Approved |
| TC-MD-002 | FR-MD-002 | 边界扫描 | Approved |
| TC-MD-003 | FR-MD-003, FR-MD-004 | 任务基线检查 | Approved |
| TC-MD-004 | FR-MD-003, FR-MD-004 | 任务基线检查 | Approved |
| TC-MD-005 | FR-MD-005 | TRACEABILITY 检查 | Approved |
| TC-MD-006 | FR-MD-006 | TRACEABILITY 检查 | Approved |
| TC-MD-007 | FR-MD-007 | TRACEABILITY 检查 | Approved |
| TC-MD-008 | FR-MD-008 | TRACEABILITY 检查 | Approved |
| TC-MD-009 | BR-MD-006 | 文件变更审计 | Approved |

## §5 AC 注册表

| AC ID | 所属 FR/BR | AC 描述 | 验证方式 | 状态 |
| --- | --- | --- | --- | --- |
| AC-MD-001 | FR-MD-001, BR-MD-001 | Binance SPEC 可明确以 downstream dispatch port 作为行情事件交付边界，禁止直写下游 | 文档引用检查 | Approved |
| AC-MD-002 | FR-MD-002, BR-MD-002 | 接收侧输入字段只引用 `ProductLine`、`InstrumentKey`、`MarketFactEnvelope` canonical 语义，不包含 Binance DTO 名称或原始响应字段 | 边界扫描 | Approved |
| AC-MD-003 | FR-MD-003, FR-MD-004 | 幂等键与排序键规则已形成后续单元测试基线 | TC-MD-003, TC-MD-004 | Approved |
| AC-MD-004 | FR-MD-005, FR-MD-006, BR-MD-004 | reject/failure 分类清晰区分 retryable | TC-MD-005, TC-MD-006 | Approved |
| AC-MD-005 | FR-MD-007, FR-MD-008, NFR-MD-001, NFR-MD-003 | 批量 outcome 与观测维度覆盖 venue/productLine/channel/outcome/reason | TC-MD-007, TC-MD-008 | Approved |
| AC-MD-006 | BR-MD-006 | 本次闭环只更新 markdown 文档，不新增运行时代码或依赖 | TC-MD-009 | Approved |

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 8 | 8 | 100% |
| BR (业务规则) | 6 | 6 | 100% |


| NFR (非功能需求) | 4 | 4 | 100% |
| AC (验收标准) | 6 | 6 | 100% |
| TC (测试用例) | 9 | 9 | 100% |
| **合计** | **33** | **33** | **100%** |

> 说明：全部 FR/BR/NFR/AC/TC 状态均为 Approved（SPEC 已通过审计，跨模块契约引用链闭合）。Task 总数 = TASK-MD-001~018 共 18 项。Runtime Pending 表示 TC-MD-003~008 对应 Go 实现未执行。

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-29 | v0.2.0 | Goal 管线对齐：§1 FR 表新增 Task 列（TASK-MD-001~008）；§2 BR 表新增 Task 列（TASK-MD-009~014）；§3 NFR 表新增 Task 列（TASK-MD-015~018）；§6 覆盖率仪表盘标准化为 Done/覆盖率列格式 | ZoneCNH |
| 2026-06-17 | v0.1.1 | 对齐 SPEC v0.1.1 audit fix：NFR 从 3 条性能/观测维度改为 4 条可审计性/稳定性/可观测性/边界纯净（匹配 SPEC §7 重构）；BR/FR/AC 描述与 SPEC §5-§8 对齐；§6 仪表盘 NFR 计数 3->4 | ZoneCNH |
| 2026-06-17 | v0.1.0 | 初始 docs baseline：全部 FR/BR/NFR/TC/AC 定义（基于 SPEC v0.1.0 23-section 格式） | ZoneCNH |
