# macro_data 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-30
Source: [SPEC.md](./SPEC.md) v0.1.0
Status: Docs Baseline — SPEC 已定义 FR/BR/NFR/AC，Runtime Pending

> 本模块严格镜像 `module/market_data` 的接收侧设计。

---

## §1 功能需求追溯（FR）

| FR ID | Requirement | AC | TC ID(s) | Task | Status |
| ----- | ----------- | --- | -------- | --- | ------ |
| FR-MACD-001 | dispatch-port — provider adapter 完成事件归一化后提交事件 | AC-MACD-001 | TC-MACD-001 | TASK-MACD-001 | Baseline |
| FR-MACD-002 | canonical-input — 载荷引用 domain_macro canonical MacroPoint 语义 | AC-MACD-002 | TC-MACD-002 | TASK-MACD-002 | Baseline |
| FR-MACD-003 | idempotency — 同 idempotency_key 相同 payload 幂等 ack | AC-MACD-003 | TC-MACD-003 | TASK-MACD-003 | Baseline |
| FR-MACD-004 | revision-ordering — 检测 revision_version 倒退/跳跃/重复 | AC-MACD-003 | TC-MACD-004 | TASK-MACD-004 | Baseline |
| FR-MACD-005 | no-lookahead-gate — available_at 缺失/为零/未来 → fail-closed | AC-MACD-004 | TC-MACD-005 | TASK-MACD-005 | Baseline |
| FR-MACD-006 | quality-gate — observed_at/released_at/value 不合法 → fail-closed | AC-MACD-004 | TC-MACD-006 | TASK-MACD-006 | Baseline |
| FR-MACD-007 | retry-classification — 区分不可重试 reject 与可重试 failure | AC-MACD-004 | TC-MACD-007 | TASK-MACD-007 | Baseline |
| FR-MACD-008 | batch-semantics — 批量提交逐条返回 outcome | AC-MACD-005 | TC-MACD-008 | TASK-MACD-008 | Baseline |
| FR-MACD-009 | observability — 按 provider/series_code/outcome/reason 统计 | AC-MACD-005 | TC-MACD-009 | TASK-MACD-009 | Baseline |
| FR-MACD-010 | downstream-port — 实现 contracts.MacroDataProvider | AC-MACD-006 | TC-MACD-010 | TASK-MACD-010 | Baseline |

---

## §2 业务规则追溯（BR）

| BR ID | Rule | TC ID(s) | Task | Status |
| ----- | ---- | -------- | --- | ------ |
| BR-MACD-001 | macro_data 不拥有 provider adapter | TC-MACD-001 | TASK-MACD-011 | Baseline |
| BR-MACD-002 | macro_data 不拥有 canonical macro entity | TC-MACD-002 | TASK-MACD-012 | Baseline |
| BR-MACD-003 | macro_data 不拥有跨进程 wire schema | -- | TASK-MACD-013 | Baseline |
| BR-MACD-004 | fail-closed: contract/quality/no-lookahead/idempotency/ordering | TC-MACD-005, TC-MACD-006 | TASK-MACD-014 | Baseline |
| BR-MACD-005 | adapter 不得将 DispatchFailure 当作成功 | TC-MACD-007 | TASK-MACD-015 | Baseline |
| BR-MACD-006 | 文档批准前不新增运行时代码 | TC-MACD-011 | TASK-MACD-016 | Baseline |
| BR-MACD-007 | no-lookahead 是宏观第一安全门禁 | TC-MACD-005 | TASK-MACD-005 | Baseline |

---

## §3 非功能需求追溯（NFR）

| NFR ID | Category | Requirement | Task | Status |
| ------ | -------- | ----------- | --- | ------ |
| NFR-MACD-001 | 可审计性 | 每个 outcome 含 outcome/reason/idempotency_key/ordering_key/revision/retryable | TASK-MACD-017 | Baseline |
| NFR-MACD-002 | 稳定性 | outcome 分类/幂等/no-lookahead 规则不破坏性变更 | TASK-MACD-018 | Baseline |
| NFR-MACD-003 | 可观测性 | 指标维度 >= provider/series_code/outcome/reason | TASK-MACD-019 | Baseline |
| NFR-MACD-004 | 边界纯净 | public API 不暴露 vendor DTO/transport tag/storage tag | TASK-MACD-020 | Baseline |
| NFR-MACD-005 | 回测安全 | no-lookahead gate 独立测试覆盖全部边界 case | TASK-MACD-005 | Baseline |

---

## §4 TC -> FR 反向追溯

| TC ID | Covers FR(s) | Type |
| ----- | ------------ | ---- |
| TC-MACD-001 | FR-MACD-001, BR-MACD-001 | 文档引用检查 |
| TC-MACD-002 | FR-MACD-002, BR-MACD-002 | 边界扫描 |
| TC-MACD-003 | FR-MACD-003 | 任务基线检查 |
| TC-MACD-004 | FR-MACD-004 | 任务基线检查 |
| TC-MACD-005 | FR-MACD-005, BR-MACD-004, BR-MACD-007, NFR-MACD-005 | TRACEABILITY 检查 |
| TC-MACD-006 | FR-MACD-006, BR-MACD-004 | TRACEABILITY 检查 |
| TC-MACD-007 | FR-MACD-007, BR-MACD-005 | TRACEABILITY 检查 |
| TC-MACD-008 | FR-MACD-008 | TRACEABILITY 检查 |
| TC-MACD-009 | FR-MACD-009 | TRACEABILITY 检查 |
| TC-MACD-010 | FR-MACD-010 | 编译期接口检查 |
| TC-MACD-011 | BR-MACD-006 | 文件变更审计 |

---

## §5 全局 AC 注册表

| AC ID | FR/BR Ref | Criterion | Status |
| ----- | --------- | --------- | ------ |
| AC-MACD-001 | FR-MACD-001, BR-MACD-001 | fred SPEC 明确以 dispatch port 为交付边界 | Baseline |
| AC-MACD-002 | FR-MACD-002, BR-MACD-002 | 接收侧只引用 MacroPoint canonical 语义 | Baseline |
| AC-MACD-003 | FR-MACD-003, FR-MACD-004 | 幂等键 + revision 排序键规则形成测试基线 | Baseline |
| AC-MACD-004 | FR-MACD-005, FR-MACD-006, BR-MACD-004, BR-MACD-007 | reject/failure 分类 + no-lookahead gate 可测 | Baseline |
| AC-MACD-005 | FR-MACD-008, FR-MACD-009, NFR-MACD-001, NFR-MACD-003 | 批量 outcome + 观测维度覆盖 | Baseline |
| AC-MACD-006 | FR-MACD-010 | macro_data 是 MacroDataProvider 唯一实现者 | Baseline |
| AC-MACD-007 | BR-MACD-006 | 本次只更新 markdown，不新增运行时 | Baseline |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 10 | 0 | 0% |
| BR (业务规则) | 7 | 0 | 0% |
| NFR (非功能需求) | 5 | 0 | 0% |
| AC (验收标准) | 7 | 0 | 0% |
| TC (测试用例) | 11 | 0 | 0% |

> 说明：全部 FR/BR/NFR/AC/TC 状态为 Baseline（SPEC 已定义，Runtime Pending）。覆盖率 0%（无运行时代码实现）。Task 总数 = TASK-MACD-001~020 共 20 项。

---

## §7 变更历史

| 日期 | 变更内容 |
| ---- | -------- |
| 2026-06-29 | Goal 管线初始化：从 SPEC.md v0.1.0 提取 FR/BR/NFR/AC/TC 创建完整 §1-§7 追溯矩阵 |
| 2026-06-17 | SPEC.md v0.1.0 初始文档基线 |
