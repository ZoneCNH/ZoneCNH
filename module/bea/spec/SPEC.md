# bea 规格

- Status: Planned（Production Target）
- Spec-Version: v0.2.0
- Last-Updated: 2026-07-04
- Layer: 数据域 · 宏观
- Module-Type: 独立 C/S Module（多子模块双服务）
- Runtime-Service: `bea-{nipa,gdp_industry,regional,ita,iip,intl_serv_trade,fixed_assets,input_output,mne,underlying_industry}-{client,server}`
- Goal: [goal/goal.md](../goal/goal.md)
- Traceability: [matrix/TRACEABILITY.md](../matrix/TRACEABILITY.md)
- Implementation-Plan: [plan/PLAN.md](../plan/PLAN.md)
- Runtime-Repo: `/home/workspace/bea`
- Template-Reference: `module/binance`

> 基于 BEA 官方数据架构，定义 `bea` 的完整宏观分析规划，覆盖数据采集、技术实现、分析框架三层。

---

## 1. 摘要

`bea` 是 BEA 宏观数据的独立 C/S 服务，不是单一脚本采集器。模块按数据集族拆分为多子模块并保持 client/server 独立部署。

全部子模块必须遵循：

1. **共享基座**：统一经 `bootstrap/configx/observex/resiliencx` 与基础设施适配层接入。
2. **领域共享层**：统一经 `domain_macro` 输出语义（`observed_at/released_at/available_at/vintage_at`）。
3. **七介质落地**：`taos + kafka + postgres + Redis + oss + nats + clickhouse`。

---

## 2. 目标

- 建立 BEA 全链路可追溯采集与发布能力（采集 → 清洗 → 计算 → 可视化 → 报告）。
- 建立统一同步策略：增量主路径 + 发布日历触发 + 周期性全量对账 + 手动重同步。
- 为 `macro_data`、`macro_regime`、`factor_engine` 提供稳定契约与分析输入。
- 对齐 `module/binance` 的 C/S 边界、追溯与门禁写法。

---

## 3. 非目标

- 不在 `bea` 内做跨 provider 决策融合。
- 不在 `bea` 内做策略、信号、交易和风控。
- 不把 BEA 原始 DTO 或临时字段暴露给下游。
- 不在文档、代码、日志保存 secret 明文值。

---

## 4. 用户与消费者

| 消费者 | 使用方式 | 边界 |
| ------ | -------- | ---- |
| `macro_data` | API/Kafka/`domain_macro` 消费 | 不依赖 `bea/internal/*` |
| `macro_regime` / `factor_engine` | 使用 GDP、PCE、收入、贸易、地区指标 | 不依赖 provider DTO |
| 运维治理 | Admin API + NATS 控制作业 | 不直写业务事实表 |
| 审计回放 | 读取 OSS raw 与 Postgres checkpoint | 不绕过幂等账本 |

---

## 5. 数据采集清单（优先级分层）

> BEA 官方数据集以 API `GetDataSetList` 动态枚举；本模块按宏观分析优先级分层采集。

### 5.1 第一层：核心宏观数据（必采）

| 数据集 | 核心内容 | 宏观分析用途 |
| ------ | -------- | ------------ |
| NIPA | GDP 总量与构成、个人收入与支出、企业利润、政府收支、储蓄与投资 | 经济总量、增长周期、需求结构 |
| GDPbyIndustry | 各行业增加值、总产出、中间投入、KLEMS | 产业结构变迁、行业景气 |
| Regional | 州/县/都市区 GDP、收入、就业、价格平价 | 区域分化、都市圈分析 |

### 5.2 第二层：国际与投资数据（推荐）

| 数据集 | 核心内容 | 宏观分析用途 |
| ------ | -------- | ------------ |
| ITA | 经常账户、资本账户、金融账户 | 外部失衡、汇率影响 |
| IIP | 海外资产与在美负债 | 对外金融脆弱性 |
| IntlServTrade | 服务贸易按类型/方向/国家 | 服务竞争力分析 |

### 5.3 第三层：深化分析数据（按需）

| 数据集 | 核心内容 | 宏观分析用途 |
| ------ | -------- | ------------ |
| FixedAssets | 固定资本存量、折旧、耐用品 | 资本深化、投资效率 |
| InputOutput | 供给使用表、需求系数 | 产业链传导、乘数效应 |
| MNE | 跨国企业活动与投资 | 全球化与供应链分析 |
| UnderlyingGDPbyIndustry | 行业底层细目 | 精细行业分析 |

---

## 6. 技术实现与采集策略

### 6.1 技术栈

| 层 | 方案 |
| -- | ---- |
| 官方 SDK | Python `beaapi`（主）/ R `bea.R`（对照） |
| 服务架构 | `bea-client` + `bea-server` 独立进程 |
| 共享基座 | `bootstrap/configx/observex/resiliencx` |
| 领域层 | `domain_macro` |
| 存储与消息 | `taos + kafka + postgres + Redis + oss + nats + clickhouse` |

### 6.2 API 限制与应对

| 限制 | 规则 | 工程应对 |
| ---- | ---- | -------- |
| 请求速率 | 100 req/min | SDK 限流 + 令牌桶 + 分片调度 |
| 数据量 | 100 MB/min | 按数据集分批 + 时间窗切片 |
| 错误数 | 30 errors/min | 错误分级熔断 + 自动退避 |
| 封禁 | 超限可封禁 1h | 触发保护模式，暂停高频任务 |

### 6.3 同步频率、周期与历史起点

| 数据层 | 默认调度频率 | 增量周期 | 全量周期 | 历史起点 |
| ------ | ------------ | -------- | -------- | -------- |
| 第一层 | 发布窗口 6h；非窗口 24h | 24h | 每月 | `1990-01-01` |
| 第二层 | 发布窗口 12h；非窗口 24h | 24h | 每月 | `1999-01-01` |
| 第三层 | 周频 | 7d | 每月/季度 | `1987-01-01` |

### 6.4 同步模式

| 模式 | 触发条件 | 说明 |
| ---- | -------- | ---- |
| 增量同步 | 定时 + 发布日历触发 | 默认主路径 |
| 全量同步 | 初始化/迁移/月度兜底 | 刷新完整窗口 |
| 手动重同步 | API/运维触发 | 按数据集/区间重跑 |

### 6.5 数据版本管理

| 要求 | 规则 |
| ---- | ---- |
| 版本字段 | 记录 `version`、`released_at`、`fetched_at`、`vintage_at` |
| 修订跟踪 | 对关键表记录 revision diff |
| 周期修订 | 五年方法论修订时执行全量刷新与口径迁移 |

### 6.6 数据质量校验

| 校验类型 | 规则 |
| -------- | ---- |
| 完整性 | 关键指标缺失率阈值告警 |
| 一致性 | 支出法 GDP 与收入法 GDI 偏差监测 |
| 异常值 | 环比/同比超阈值异常检测 |
| 修订追踪 | 对比上期与本期修订幅度 |

---

## 7. 宏观分析框架

### 7.1 指标体系

| 维度 | 指标 |
| ---- | ---- |
| 总量与增长 | 实际 GDP 同比、环比折年率；GDP/GDI；人均 GDP/收入 |
| 需求结构 | 消费、投资、政府、净出口占比与贡献率；储蓄率 |
| 供给结构 | 行业增加值占比；行业劳动生产率 |
| 区域维度 | 州/都市区 GDP 增速排名；收入差距 |
| 外部均衡 | 经常账户/GDP；净国际投资头寸 |

### 7.2 分析模块

| 模块 | 所需数据集 | 输出 |
| ---- | ---------- | ---- |
| 经济周期监测 | NIPA | 增长轨迹与阶段判断 |
| 产业结构分析 | GDPbyIndustry | 行业贡献率与结构迁移图 |
| 区域经济画像 | Regional | 区域热力图与排名 |
| 需求侧拆解 | NIPA | 三驾马车贡献率 |
| 外部脆弱性 | ITA、IIP | 外部资产负债趋势 |

---

## 8. 行为约束

| ID | 规则 |
| -- | ---- |
| BR-BEA-001 | 每个子模块必须保持独立 C/S 服务边界。 |
| BR-BEA-002 | 必须复用共享基座，不得绕过基座直连基础设施。 |
| BR-BEA-003 | 出域语义必须是 `domain_macro`，不暴露 BEA DTO。 |
| BR-BEA-004 | NATS 与 Kafka 必须严格分层。 |
| BR-BEA-005 | Postgres checkpoint 未推进前，作业不得标记 completed。 |
| BR-BEA-006 | Redis 与 ClickHouse 仅为可重建派生层。 |
| BR-BEA-007 | `available_at` 缺失或未来时间必须 fail-closed。 |
| BR-BEA-008 | 同步策略、历史起点、修订窗口必须版本化可审计。 |
| BR-BEA-009 | 采集侧必须同步元数据与数据字典。 |
| BR-BEA-010 | 发布日历触发优先于被动轮询。 |
| BR-BEA-011 | 跨源整合（BLS/FRED/Census/Fed/市场）按统一字段映射。 |

---

## 9. 非功能需求

| ID | 类别 | 要求 |
| -- | ---- | ---- |
| NFR-BEA-001 | Freshness | 发布窗口内滞后 `<24h`，非窗口期 `<72h`。 |
| NFR-BEA-002 | Latency | 单轮同步目标 `<=30min`。 |
| NFR-BEA-003 | Reliability | 任一权威存储写入失败不得推进 checkpoint。 |
| NFR-BEA-004 | Observability | dataset/job_id/error_class/store_lag 指标齐全。 |
| NFR-BEA-005 | Security | 文档/日志不泄露 secret 值。 |
| NFR-BEA-006 | Governance | 覆盖率、缺口、重采证据可追溯。 |
| NFR-BEA-007 | Quality | 自动完整性/一致性/异常值/修订监测。 |
| NFR-BEA-008 | Reporting | 自动化仪表盘、PDF 报告与异常预警。 |

---

## 10. Acceptance Criteria Registry

| AC | 验收摘要 | 覆盖需求 |
| -- | -------- | -------- |
| AC-BEA-001 | 各子模块 client/server 可独立启动并通过 health/readiness。 | BR-BEA-001 |
| AC-BEA-002 | 配置仅使用 secret reference，且通过脱敏扫描。 | BR-BEA-002, NFR-BEA-005 |
| AC-BEA-003 | 三层采集清单覆盖并通过参数枚举校验。 | §5 |
| AC-BEA-004 | Raw-First + 七介质链路闭合。 | §6 |
| AC-BEA-005 | 增量/全量/Re-sync 与 API 管理能力可用。 | §6.4 |
| AC-BEA-006 | no-lookahead 与修订链可见性验证通过。 | BR-BEA-007 |
| AC-BEA-007 | 发布日历自动触发采集任务。 | BR-BEA-010 |
| AC-BEA-008 | 自动质检（完整性/一致性/异常值/修订）通过。 | NFR-BEA-007 |
| AC-BEA-009 | 仪表盘、周期报告、异常预警闭环可运行。 | NFR-BEA-008 |

---

## 11. 还需补充项（跨源与分析增强）

1. 跨源整合：BLS（通胀/就业）、Census（人口/住房）、Fed（利率/货币）、市场数据。
2. 元数据与数据字典：同步采集描述、单位、口径、发布时间。
3. 质量评分层：缺失率、延迟、修订频度、稳定性评分。
4. 特征工程层：同比/环比、3MMA、扩散指数、领先/同步/滞后标签。
5. 自动化报告层：实时仪表盘 + 定时 PDF + 阈值预警。

---

## 12. 实施路线图（8 周）

| 阶段 | 周期 | 任务 |
| ---- | ---- | ---- |
| 第一阶段 | 第 1-2 周 | 注册 API Key，搭建采集框架，拉取 NIPA 全量历史 |
| 第二阶段 | 第 3-4 周 | 接入 GDPbyIndustry、Regional，建立基础指标体系 |
| 第三阶段 | 第 5-6 周 | 接入 ITA、IIP、IntlServTrade，完善外部模块 |
| 第四阶段 | 第 7-8 周 | 建立增量同步、质量校验、可视化仪表盘与报告 |
| 持续运营 | 长期 | 发布日历自动采集、修订追踪、指标体系迭代 |

---

## 13. 版本记录

| 日期 | 版本 | 变更 | 作者 |
| ---- | ---- | ---- | ---- |
| 2026-07-04 | v0.2.0 | 基于 BEA 官方架构升级：三层采集清单、技术实现、分析框架、质检与 8 周路线图 | ZoneCNH |
