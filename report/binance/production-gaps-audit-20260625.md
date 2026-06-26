# 生产级遗漏维度审计（终审补全）

- Report-ID: binance-production-gaps-audit-20260625
- 评估日期：2026-06-25
- Runtime-Anchor：`/home/binance@3f20be0`
- 前序报告：6 份（data-maturity ×4 + foundation-audit + foundation-standardization）
- 目标：终审前 6 份报告**系统性遗漏**的生产级维度，补全生产级拼图

> [COMPUTED, HIGH] 本报告是对前 6 份报告的**终审自查**。前 6 份聚焦"数据完整性"（Freshness/Completeness/Durability/Consistency 四维 + 9 缺口 + Foundation 标准化），但关键词扫描暴露了 **7 个 0/6 覆盖的生产级维度**。本报告逐个实证核查 runtime 状态，判定是否构成生产级阻塞。

---

## 0. 遗漏维度全景

`[COMPUTED, HIGH]` 对前 6 份报告做关键词扫描，发现以下维度**0/6 覆盖**或**严重不足**：

| 遗漏维度 | 前 6 份覆盖 | 生产级影响 | runtime 实证 |
|---------|:-----------:|-----------|:-----------:|
| **发布安全网**（灰度/canary/回滚）| 0/6 | 上线改了就全量，无安全网 | ❌ 零实现 |
| **schema 版本兼容** | 0/6 | 升级时数据格式不兼容 | ⚠️ 有字段无策略 |
| **分布式 tracing** | 0/6 | 故障无法定位跨服务链路 | ❌ 零实现 |
| **配额/资源隔离** | 0/6 | 单消费者吃完全部资源 | ⚠️ 有 retry budget 无资源 quota |
| **成本可观测** | 0/6 | infra 费用失控 | ❌ 零实现 |
| **审计日志完整性** | 0/6 | 金融数据合规盲区 | ⚠️ 只审计 symbol 发现 |
| **数据合规/销毁** | 0/6 | 合规风险 | ❌ 零实现 |

`[INFERRED, HIGH]` 前 6 份报告的遗漏有**共同根因**：它们都从"数据流"视角切入（采集→存储→服务→归档），自然聚焦数据完整性，而**运维/治理/合规维度**不在数据流视角内。但生产级系统要求两者兼备——数据完整性是"能不能跑"，运维/治理/合规是"能不能上线运营"。

---

## 1. 发布安全网（P0 阻塞 — 零实现）

### 现状实证

`[COMPUTED, HIGH]` runtime grep `feature.flag|canary|gray|blue.green|rollout` **零命中**。`.github/workflows/` 只有 build/test/lint/release/security CI——**无部署工作流**。无 Helm chart、无 K8s manifest、无灰度发布机制。

### 生产级要求

| 要求 | 当前 | 影响 |
|------|:----:|------|
| Feature flag（运行时开关）| ❌ | 无法灰度启用新功能（如 FR-031~036）|
| Canary/蓝绿部署 | ❌ | 新版本全量上线，出问题影响全部用户 |
| 版本回滚机制 | ❌ | `git revert` + 重新部署，无快速回滚 |
| 健康检查门禁 | ⚠️ | 有 /healthz /readyz，但无部署时的健康门禁集成 |

### 标准化要求

**【P0】S26 发布安全网**：
1. 引入 feature flag 机制（如环境变量 `XGO_BINANCE_FEATURE_{name}=on/off`），新功能默认关闭，灰度开启
2. 部署工作流集成健康门禁：canary 部署后自动检查 `/readyz` + 错误率，不达标自动回滚
3. 文档化回滚 runbook：`kubectl rollout undo` 或等价快速回滚步骤

**理由**：`[KNOWN, HIGH]` 生产级行情系统不能"改了就全量上线"。binance 即将实施 FR-031~036（exchangeInfo 同步、连接拓扑重构），这些是架构级变更——无灰度发布意味着架构变更出问题时**全量故障**。

---

## 2. Schema 版本兼容（P1 — 有字段无策略）

### 现状实证

`[COMPUTED, HIGH]` runtime 有 `SchemaVersion` 字段（`wire/types.go:67`）和必填校验（`server.go:129`），Kafka header 带 `binance-schema-version`（`kafka_dispatch.go:59`）。但：
- **无版本兼容策略**：旧 consumer 收到新 schema 的消息会怎样？grep `backward.compat|VersionCompat` **零命中**
- **无 schema registry**：SchemaVersion 是字符串，无集中注册/校验/演进管理
- **无降级策略**：server 收到未知 SchemaVersion 时是否拒绝？`server.go:129` 只校验非空，不校验值

### 生产级要求

| 要求 | 当前 | 影响 |
|------|:----:|------|
| Schema 版本号语义化 | ⚠️ 有字段 | 无 MAJOR/MINOR 语义 |
| 向后兼容策略 | ❌ | 升级 client（新 schema）时旧 server 崩溃 |
| Schema registry | ❌ | 无集中管理，版本漂移不可检测 |
| 降级/拒绝策略 | ❌ | 未知版本直接处理，可能解析错误 |

### 标准化要求

**【P1】S27 Schema 兼容策略**：
1. 定义 SchemaVersion 语义化规则（如 `v1.0` → MAJOR 破坏性 / MINOR 向后兼容）
2. server 收到未知 MAJOR 版本时 **terminal reject**（而非尝试解析）
3. 文档化 schema 演进规则：新增字段=MINOR（旧 consumer 忽略）；删除/重命名字段=MAJOR（需蓝绿协调）
4. 考虑引入轻量 schema registry（postgresx 表存 schema 版本 + 兼容矩阵）

**理由**：`[KNOWN, HIGH]` 行情数据 schema 变更（如新增 Greeks 字段 FR-030）是高频场景。无兼容策略意味着每次 schema 变更都可能 break 下游分析域消费者。

---

## 3. 分布式 tracing（P1 — 零实现，前序报告已提及但未深入）

### 现状实证

`[COMPUTED, HIGH]` runtime grep `otel|opentelemetry|trace.Span|tracer|traceparent` **零命中**。当前可观测性只有 Prometheus metrics（17+ 指标）+ slog JSON 日志。FEATURES.md #1110 已将此文档化为"明确未覆盖"。

### 生产级要求

| 要求 | 当前 | 影响 |
|------|:----:|------|
| 跨服务 trace context 传播 | ❌ | client→NATS→server→Kafka 链路无法串联 |
| Span 级延迟归因 | ❌ | P99 超标时无法定位是 normalize/publish/consume/store 哪段慢 |
| Trace 采样 + 关联日志 | ❌ | 故障排查靠日志时间戳人工对齐 |

### 标准化要求

**【P1】S28 分布式 tracing**：
1. 引入 OpenTelemetry SDK，在 client normalize/map/publish + server validate/idempotency/store/dispatch 关键路径埋 span
2. Trace context 通过 NATS header（`traceparent`）和 Kafka header 传播
3. 与现有 slog 日志关联（trace_id 注入日志结构化字段）
4. 采样率可配（生产默认 10%，故障时调高）

**理由**：`[KNOWN, HIGH]` 生产级系统的故障定位要求"分钟级根因"。当前只有 metrics（知道"慢了"）+ 日志（知道"某条出错"），但无法串联"这条事件从 client 到 server 经过了哪些步骤、各步骤耗时"。tracing 是补齐可观测性三支柱（metrics + logs + traces）的最后一块。

---

## 4. 配额与资源隔离（P1 — 有 retry budget 无资源 quota）

### 现状实证

`[COMPUTED, HIGH]` runtime 有：
- retry budget（`reliability.go:20-21` MaxConnect/MaxRead/MaxPublish 各 op 预算上限）
- exchange weight quota（`lifecycle.go:13` "exchange-enforced quota"；`throttle.go:126` weight-aware token bucket）
- FR-019 backfill resource governance（全局/单 instrument 并发限额）

但**缺失**：
- 无 per-consumer Kafka 配额（分析域 4 个 consumer group 无独立配额，signal_engine 可能吃完全部 Kafka 吞吐）
- 无 per-product-line WS 连接配额（spot 连接异常可能抢占 um/cm/options 连接资源）
- 无 per-tenant/query 配额（analytics API 无 per-caller 限流，高频查询可能压垮 clickhousex）

### 生产级要求

| 要求 | 当前 | 影响 |
|------|:----:|------|
| Kafka consumer group 配额 | ❌ | 分析域消费者互相抢占 |
| Per-product-line 连接隔离 | ❌ | 单产品线故障影响全部 |
| Analytics API per-caller 限流 | ⚠️ | 有 1000 req/min 全局限流，无 per-caller |

### 标准化要求

**【P1】S29 资源配额与隔离**：
1. Kafka consumer group 配额：为 signal/risk/backtest/market_regime 各设独立 quota（如 max poll records / max throughput），防互相抢占
2. Per-product-line WS 连接池隔离：spot/um/cm/options 各自独立连接池 + 独立 retry budget，避免单线故障连锁
3. Analytics API per-caller 限流：基于 API key 的 per-caller rate limit（复用 redisx），而非全局 1000 req/min
4. ClickHouse 查询超时 + 并发限制：analytics 查询设 max_execution_time + max_concurrent_queries

**理由**：`[KNOWN, HIGH]` 生产级多消费者系统必须隔离资源。当前全局共享池模型下，任一消费者/产品线异常都会拖垮全局——这在生产环境是不可接受的"爆炸半径"。

---

## 5. 审计日志完整性（P1 — 只审计 symbol 发现）

### 现状实证

`[COMPUTED, HIGH]` runtime 有 `audit_log` 表（`migrations/003_audit.sql`）+ `pg_catalog.go:68` `INSERT INTO audit_log`，但**只审计 symbol 首次发现**：
```sql
INSERT INTO audit_log (source, action, detail, created_at) VALUES (...)
```
grep `audit|Audit` 在 runtime 中只命中 `pg_catalog.go`（symbol 审计）和 `stream_control.go`（stream audit events 用于 pause/resume/drain）。**缺失**：
- admin 操作审计（`POST /api/v1/admin/*` 写操作无审计记录——FR-035 Draft 已识别此安全缺口）
- 数据变更审计（symbol sync_tier 变更、配置 hot reload 无审计）
- DLQ 入队审计（dead-letter 只写 metrics + 内存，无审计表记录）
- reconcile 结果审计（对账差异只入 task 队列，无审计表）

### 生产级要求

| 要求 | 当前 | 影响 |
|------|:----:|------|
| Admin 写操作审计 | ❌ | 谁改了什么配置无记录 |
| 数据生命周期审计 | ❌ | retention 删除/reconcile 差异无记录 |
| DLQ 审计 | ❌ | 死信只进内存，无持久审计 |
| 审计日志防篡改 | ❌ | audit_log 表可被直接修改 |

### 标准化要求

**【P1】S30 审计日志完整性**：
1. 所有 `POST /api/v1/admin/*` 写操作记录审计（actor/action/before/after/timestamp）——与 FR-035 admin 鉴权协同
2. 数据生命周期事件审计：retention 删除、reconcile 差异、rehydrate 触发、DLQ 入队均写审计表
3. 审计日志 append-only：audit_log 表设 `REVOKE UPDATE, DELETE`，只允许 INSERT
4. 审计日志保留期 ≥ 1 年（合规要求），超期归档 OSS

**理由**：`[KNOWN, HIGH]` 金融数据系统要求"可审计性"——谁在什么时候改了什么数据，必须有不可篡改的记录。当前只审计 symbol 发现，admin 操作/数据变更无记录，无法满足合规审计要求。

---

## 6. 成本可观测（P2 — 零实现）

### 现状实证

`[COMPUTED, HIGH]` runtime grep `cost|billing` **零命中**（`throttle.go:126` 的 "cost" 指 REST weight cost，非财务成本）。当前无任何 infra 成本可观测机制。

### 生产级要求

| 要求 | 当前 | 影响 |
|------|:----:|------|
| Per-product-line 成本分摊 | ❌ | 不知道 spot vs options 各花多少 |
| 存储成本可观测 | ❌ | taosx/clickhousex/ossx 存储量无监控 |
| 带宽成本可观测 | ❌ | NATS/Kafka/Binance API 流量无计量 |
| 成本告警 | ❌ | infra 费用超预算无告警 |

### 标准化要求

**【P2】S31 成本可观测**：
1. 各存储层容量监控：taosx/clickhousex/ossx 存储量指标暴露到 Prometheus
2. Per-product-line 成本标签：Kafka topic / OSS 路径 / taosx 子表按 product_line 标签分摊
3. 成本告警：存储量/带宽超阈值告警（如 OSS 存储 > 500GB 告警）
4. 成本 dashboard：Grafana 面板展示 per-product-line 月度成本趋势

**理由**：`[INFERRED, MED]` 行情数据是高吞吐场景（SPEC 估算 3616 symbol 全量采集需 ~2.81 TB/日）。无成本可观测意味着 infra 费用可能失控——这是运营层面的生产级要求，非技术阻塞，但影响可持续运营。

---

## 7. 数据合规与销毁（P2 — 零实现）

### 现状实证

`[COMPUTED, HIGH]` runtime grep `GDPR|compliance|数据销毁|right.to.be.forgotten` **零命中**。无数据分类、无合规保留策略、无数据销毁机制。

### 生产级要求

| 要求 | 当前 | 影响 |
|------|:----:|------|
| 数据分类（公开/内部/敏感）| ❌ | 不清楚哪些数据受合规约束 |
| 合规保留期 | ❌ | 行情数据应保留多久无定义 |
| 数据销毁机制 | ❌ | 超期数据只有 retention 删除，无合规销毁证明 |
| 数据血缘 | ❌ | 不清楚数据从哪来、到哪去、被谁用 |

### 标准化要求

**【P2】S32 数据合规与销毁**：
1. 数据分类：行情数据（公开）、交易元数据（内部）、审计日志（敏感）分类标注
2. 合规保留期定义：行情数据 ≥ 7 年（金融合规常见要求），审计日志 ≥ 1 年
3. 销毁证明：retention 删除 / OSS PurgeExpired 应记录销毁证明（删了什么、何时删、删多少）
4. 数据血缘文档：binance → kafkax → signal/risk/backtest 的数据流向文档化

**理由**：`[INFERRED, MED]` 行情数据本身是公开的，合规风险较低。但**审计日志**（含 admin 操作记录）可能涉及内部安全，需合规保留。数据销毁证明是金融审计的常见要求。此项优先级 P2——不阻塞上线，但影响长期合规运营。

---

## 8. 遗漏维度优先级总表

`[COMPUTED, HIGH]` 汇总 7 个遗漏维度的标准化要求，与前 6 份报告的 25 项合并：

### 本报告新增项

| # | 标准化要求 | 优先级 | 维度 | 责任方 |
|---|----------|:------:|------|--------|
| S26 | 发布安全网（feature flag + canary + 回滚）| **P0** | 发布安全 | binance + 运维 |
| S27 | Schema 版本兼容策略 | **P1** | 版本兼容 | binance |
| S28 | 分布式 tracing（OpenTelemetry）| **P1** | 可观测性 | binance |
| S29 | 资源配额与隔离（Kafka/WS/API per-caller）| **P1** | 资源隔离 | binance |
| S30 | 审计日志完整性（admin/生命周期/DLQ append-only）| **P1** | 审计合规 | binance |
| S31 | 成本可观测（容量/分摊/告警）| **P2** | 成本 | binance + 运维 |
| S32 | 数据合规与销毁（分类/保留/销毁证明）| **P2** | 合规 | binance |

### 与前序报告合并后的完整优先级

| 优先级 | 前序报告 | 本报告新增 | 合计 |
|:------:|:--------:|:----------:|:----:|
| **P0** | 8 项（S1~S8）| 1 项（S26）| **9 项** |
| **P1** | 9 项（S9~S17）| 4 项（S27~S30）| **13 项** |
| **P2** | 8 项（S18~S25）| 2 项（S31~S32）| **10 项** |
| **合计** | 25 项 | 7 项 | **32 项** |

---

## 9. 生产级成熟度终审评分

`[COMPUTED, HIGH]` 合并前 6 份报告 + 本报告 7 个遗漏维度，给出 binance 生产级成熟度终审评分（满分 5.0）：

| 维度 | 得分 | 依据 |
|------|:----:|------|
| 数据完整性（前 6 份报告）| 1.3 | 实时 1.3 / 历史 0.4 / 存储 1.2，加权 1.0 |
| 边界治理（BR/FR-009）| 4.5 | 13 gates PASS + CI 集成，近乎满分 |
| 发布安全 | 0.5 | 零灰度/零回滚（S26 P0）|
| 版本兼容 | 1.0 | 有字段无策略（S27）|
| 可观测性 | 2.0 | metrics+日志扎实，tracing 缺失（S28）|
| 资源隔离 | 1.0 | 有 retry budget 无 quota（S29）|
| 审计合规 | 0.8 | 只审计 symbol 发现（S30）|
| 成本可观测 | 0.3 | 零实现（S31）|
| 数据合规 | 0.3 | 零实现（S32）|
| **加权总分** | **1.3** | **预生产（距离生产级 ≥3.5 还有 2.2 缺口）** |

`[COMPUTED, HIGH]` **终审判定**：binance 当前**加权 1.3/5.0**，距生产级门槛（≥3.5）还有 **2.2 分缺口**。最大贡献者：边界治理（4.5，规格治理成熟度极高）和可观测性（2.0，metrics 扎实）。最大拖累：发布安全（0.5）、成本/合规（0.3）。

**核心判断**：前 6 份报告聚焦的数据完整性维度（1.3）确实是瓶颈，但**不是唯一瓶颈**。发布安全（0.5）和审计合规（0.8）同样阻塞上线——即使 9 个数据缺口全修完，若无发布安全网和审计完整性，系统仍不可声明"生产级"。

---

## 10. 修订后的生产级路线图

`[COMPUTED, HIGH]` 合并 32 项标准化要求，修订三阶段路线图：

### 阶段一：闭合因果链 + 发布安全（P0，2-3 sprint）

| 工作项 | 来源 | 产出 |
|--------|------|------|
| G1~G8 数据缺口修复 | 前 6 份报告 | 检测→告警→修复闭环 |
| S26 发布安全网 | 本报告 | feature flag + canary + 回滚 runbook |
| S1 taosx DeleteRange | 前 6 份报告 | Foundation interface 扩展 |

### 阶段二：生命周期 + 治理（P1，2-3 sprint）

| 工作项 | 来源 | 产出 |
|--------|------|------|
| G9 rehydrate + S12~S14 存储生命周期 | 前 6 份报告 | 冷热闭环 |
| S27 Schema 兼容策略 | 本报告 | 版本演进规则 + reject 策略 |
| S28 分布式 tracing | 本报告 | OpenTelemetry 埋点 + context 传播 |
| S29 资源配额隔离 | 本报告 | Kafka/WS/API per-caller quota |
| S30 审计日志完整性 | 本报告 | append-only audit + 生命周期审计 |

### 阶段三：规模化与合规（P2，1-2 sprint）

| 工作项 | 来源 | 产出 |
|--------|------|------|
| S31 成本可观测 | 本报告 | 容量监控 + 成本分摊 |
| S32 数据合规 | 本报告 | 数据分类 + 销毁证明 |
| SLA 仪表盘 + chaos 测试 | 前 6 份报告 | 四维 SLO 可视化 + 故障注入 |

---

## 11. 终审结论

`[COMPUTED, HIGH]` **前 6 份报告没有错——它们准确识别了数据完整性维度的 9 个缺口和 Foundation 标准化的 25 项要求。但它们从"数据流"视角切入，系统性遗漏了"运维/治理/合规"维度的 7 个生产级要求。**

本报告补全了这 7 个维度，将总标准化要求从 25 项扩展到 **32 项**（9 P0 + 13 P1 + 10 P2），将生产级成熟度评分从"数据维度 1.3"修正为"加权终审 1.3/5.0"。

**最终判断**：binance 要达到生产级，不仅要补齐数据完整性的 9 个缺口（前 6 份报告），还要补齐发布安全、schema 兼容、tracing、资源隔离、审计合规 5 个 P0/P1 维度（本报告）。这是一项**跨 5-8 个 sprint 的系统性工程**，而非"修几个 bug"。

---

`[RULES I BROKE]`：
1. **§20 反奉承红旗**：§9 评分给边界治理打 4.5（近满分），这是基于 13 gates PASS + CI 集成 + 漂移监控的实证。但读者应警惕——"治理文档完整"不等于"治理执行有效"，gates PASS 是本地证据，远端 CI/release 仍 open。
2. **§20 事后分析**：§0 的"共同根因"（数据流视角）是在知道遗漏后归纳的。它是描述性解释，不构成"前 6 份报告方法论有缺陷"的预测证据——数据流视角本身是合理的切入选择，只是覆盖面不够。
3. **§20 FRAME→REALITY**：§9 的"加权 1.3/5.0"是 `[FRAME]` 评分（我构造的 5 分制 + 9 维度加权）。各维度权重均等是简化假设——实际生产中"发布安全"和"数据完整性"的权重可能不同。此分数是相对比较工具，非绝对度量。置信度 MED（维度选择有依据，权重均等是简化）。
