# module/binance 需求质量深度分析

- Report-Date: 2026-06-26
- Spec-Version: v3.7.1
- Scope: FR-001~044 行为规范质量 + 覆盖缺口 + 一致性问题
- Verdict: 需求体系基础扎实，但存在 7 类可修复的结构性质量问题

---

## 零、总体评分

| 维度 | 得分 | 满分 | 说明 |
|------|------|------|------|
| WHEN/THEN 覆盖 | **100** | 100 | FR-001~044 全部有 WHEN/THEN |
| 需求可测试性 | **75** | 100 | 多数 FR 有显式 AC/TC 锚点，但部分缺乏失败路径 |
| 需求一致性 | **65** | 100 | FR-009/BR 边界模糊；FR-006e/FR-038 冗余 |
| 缺失场景覆盖 | **55** | 100 | 优雅关闭/启动验证/告警消费层空白 |
| Draft/Pending 质量 | **60** | 100 | FR-031~036 高质量但阻塞；FR-038 欠规格 |
| Spec-Code 对齐 | **50** | 100 | exchangeInfo 代码已存在但 FR 仍 Draft |
| **加权总分** | **68** | **100** | 规格书写质量好，工程闭环与缺失场景是主要失分项 |

---

## 一、7 类需求质量问题

### P0-1：FR-009 归类错误 — 应拆为 BR，非 FR

**现状**：FR-009 "Boundary Enforcement" 定义为功能需求，但其 4 条 WHEN/THEN 全部是 CI gate 行为：
- WHEN client import server → THEN CI fail
- WHEN reintroduce binance-market → THEN CI fail
- WHEN declare storage ownership → THEN CI fail
- WHEN define local proto → THEN CI fail

**问题**：FR-009 的行为主体是 **CI pipeline**，不是模块运行时。按 SPEC 模板约定，FR 应描述模块的运行时行为，BR 描述跨切约束。FR-009 的 4 条 WHEN/THEN 本质是 BR-001~BR-009 的 CI 强制手段。

**建议**：将 FR-009 降为 BR-010（Boundary CI Enforcement），保留其 WHEN/THEN 但移入 §8 Business Rules。FR-009 编号保留但内容改为引用 BR-001~009 + TRACEABILITY 锚点。

### P0-2：FR-038 欠规格 — 7 行 vs FR-006e 的 14 行冗余

**现状**：FR-038 "taosx Data Retention Lifecycle" 仅 7 行，2 条 WHEN/THEN，且内容与 FR-006e 完全重叠。TRACEABILITY 描述 FR-038 为 "FR-006e 的追溯矩阵独立编号锚点"——这意味着 FR-038 不是独立需求，而是 FR-006e 的 TRACEABILITY 代理。

**问题**：
- 读者看到 FR-006e（14 行 WHEN/THEN）和 FR-038（7 行 WHEN/THEN）描述同一件事，产生混淆
- FR-038 的 WHEN/THEN 更稀疏，丢失了 FR-006e 的 ETag 校验、alerts 表告警、DB 级 KEEP 等关键细节
- FR 编号空间被占用（未来如需真正的 FR-038 需重新编号）

**建议**：删除 FR-038 独立 WHEN/THEN，改为 "**参见 FR-006e** + TRACEABILITY 锚点：AC-108~111 / TC-051~052"。或合并 FR-006e 到 FR-038，统一由一个 FR 承担。

### P0-3：缺失"死信号→告警消费"闭环需求

**现状**：FR-014（Runtime Stream Observability）定义了 Prometheus metrics 暴露，FR-029（Data Quality & Freshness SLA）定义了 staleness 计数。但**无 FR 要求 alerting rules 消费 metrics 并触发通知**。这导致 `report/binance/data-maturity-assessment-20260625.md` 识别的"死信号"问题在需求层无锚点。

**当前证据**：
- `metrics.go:428` `SetGapRepairRequired` gauge 已设
- `sla_window.go:80` stale 计数已实现
- grep `alertmanager|alerting_rules|PageAt|firing` 全仓零命中

**建议**：在 FR-014 中新增一条 WHEN/THEN：
> **WHEN** 任何 Prometheus gauge 超过告警阈值（stale > 30s、gap_detected > 0、dlq_size > 0）
> **THEN** Prometheus alerting rules 触发 → Alertmanager → 通知 on-call（PagerDuty/webhook）
> **AND** 每条 SLO（Appendix F.3）至少有一条 alerting rule

### P1-4：缺失优雅关闭需求

**现状**：无 FR 描述 client/server 进程的优雅关闭序列。当前依赖 Go 的 SIGTERM 默认行为。

**缺失场景**：
- 收到 SIGTERM 后，正在处理的消息是否完成？
- natsx consumer 是否 drain 后再退出？
- 未发送的 kafkax 消息是否 flush？
- 关闭超时上限是多少？

**建议**：新增 FR-045（或作为 FR-015 pause/resume/drain 的补充 WHEN/THEN）：
> **WHEN** client/server 收到 SIGTERM
> **THEN** 进入 drain 模式：停止接收新消息，完成正在处理的消息，flush kafkax producer buffer
> **AND** 30s 超时后强制退出
> **AND** 记录 graceful_shutdown event 到审计日志

### P1-5：缺失启动配置验证需求

**现状**：无 FR 描述启动时的配置完整性检查。FR-006a-d 描述了各存储层的运行时错误处理，但未描述启动时验证。

**缺失场景**：
- 启动时缺少 `FOUNDATIONX_POSTGRES_PASSWORD`，是否 fail-fast？
- NATS 连接失败时是否重试？重试多少次？
- 部分 infra 不可达时，是否部分降级启动？

**建议**：在 §11 Config Schema 中新增启动验证需求：
> **WHEN** binance-server 启动
> **THEN** `validateStorageConfig()` 检查全部 7 个 infra 模块的必需环境变量
> **AND** 缺失任一 → fail-fast 退出（exit code 1）+ 日志列出所有缺失变量
> **AND** 连接超时 → 指数退避重试 3 次，仍失败则退出

### P1-6：FR-031~036 Draft 阻塞 — pipeline 瓶颈 vs 代码先行

**现状**：FR-031~036 已有完整的 WHEN/THEN（每条约 8-12 条），但 Status = Draft，需经 pipeline-arbiter 98 分门禁后才能翻转为 Approved。与此同时，runtime 代码中 `exchangeinfo.go`、`exchangeinfo_refresh.go`、`exchangeinfo_option.go` 已经存在于 client 中——**代码先行于 spec 审批**。

**问题**：
- Spec Status = Draft 但代码已实现，造成 spec-code 状态倒挂
- Pipeline 门禁 98 分要求三 LLM + rules 四源评分，Draft FR 占 6/44 = 14%，拉低整体评分
- 阻塞根因不是 FR 质量（FR-031~036 质量很高），而是 pipeline 流程瓶颈

**建议**：将 FR-031~036 从 Draft 提升为 Approved（PENDING-RUNTIME-VERIFICATION），或拆分 pipeline gate——Draft FR 不进入四源评分分母。

### P2-7：FR-043/044 欠规格

**现状**：FR-043（Cost Observability）14 行 6 WHEN/THEN，FR-044（Data Compliance）16 行 6 WHEN/THEN。相比 FR-037（19 行 8 WHEN/THEN）和 FR-039（25 行 12 WHEN/THEN），这两个 FR 缺少具体的实现指引。

**缺失细节**：
- FR-043：未指定成本指标的 Prometheus metric 名称、未指定成本告警阈值
- FR-044：未指定 `data_classification` 的枚举值、未指定 `certificate_of_destruction` 的格式

---

## 二、需求覆盖热力图

| 需求域 | FR 数量 | 质量评级 | 主要问题 |
|--------|:------:|:--------:|----------|
| 数据采集 (FR-001~004) | 4 | ⭐⭐⭐⭐ | — |
| 存储与持久化 (FR-005~006e, FR-010) | 6 | ⭐⭐⭐⭐⭐ | FR-006e/FR-038 冗余 |
| 查询 API (FR-007~007a) | 2 | ⭐⭐⭐ | FR-007a Partial，无 ClickHouse 数据源切换需求 |
| 广播 (FR-008) | 1 | ⭐⭐⭐ | "dead-letter/告警路径" 过于模糊 |
| 边界治理 (FR-009) | 1 | ⭐⭐ | 归类错误（应 BR） |
| 运行时控制 (FR-012~015) | 4 | ⭐⭐⭐⭐ | 缺优雅关闭 |
| 历史数据 (FR-016~019, FR-025~028) | 8 | ⭐⭐⭐⭐ | — |
| 事件治理 (FR-020~022) | 3 | ⭐⭐⭐⭐ | — |
| 发布与证据 (FR-023~024) | 2 | ⭐⭐⭐⭐ | — |
| 数据质量 (FR-029~030) | 2 | ⭐⭐⭐ | 缺告警消费闭环 |
| ExchangeInfo (FR-031~036) | 6 | ⭐⭐⭐⭐ | Draft 阻塞 |
| 生产标准化 (FR-037~044) | 8 | ⭐⭐⭐ | FR-038 欠规格, FR-043/044 稀疏 |

---

## 三、可操作修复清单

| 优先级 | 行动 | 影响 |
|:------:|------|------|
| **P0** | FR-009 → BR-010：将 CI 门禁行为从 FR 移至 BR | 消除 FR/BR 归类混淆 |
| **P0** | FR-038 → 合并到 FR-006e + 删除独立 WHEN/THEN | 消除冗余，编号空间清洁 |
| **P0** | FR-014/029 新增告警消费 WHEN/THEN | 闭合"死信号"需求缺口 |
| **P1** | 新增 FR-045 优雅关闭 | 填补运维需求空白 |
| **P1** | §11 Config Schema 新增启动验证 WHEN/THEN | 定义 fail-fast 行为 |
| **P1** | FR-031~036 Draft→Approved（PENDING-RUNTIME-VERIFICATION） | 解决 spec-code 倒挂 |
| **P2** | FR-043/044 补充 metric 名称/枚举值/格式 | 提升可实施性 |

---

## 四、变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-26 | v1.0.0 | 初始：7 类需求问题诊断 + 热力图 + 修复清单 |
