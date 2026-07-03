# yield_curve 规格

- Status: Planned（Production Target）
- Spec-Version: v0.1.0
- Last-Updated: 2026-07-03
- Layer: 数据域 · 宏观
- Module-Type: 独立 C/S Module（多子模块双服务）
- Runtime-Service: `yc-{nominal,real,inflation,ois,blc}-{client,server}`
- Goal: [goal/goal.md](../goal/goal.md)
- Traceability: [matrix/TRACEABILITY.md](../matrix/TRACEABILITY.md)
- Implementation-Plan: [plan/PLAN.md](../plan/PLAN.md)
- Features: [FEATURES.md](FEATURES.md)
- Acceptance: [ACCEPTANCE.md](ACCEPTANCE.md)
- Runtime-Repo: `/home/workspace/yield_curve`
- Template-Reference: `module/binance`

> 本规格定义 `yield_curve` 的生产目标状态。运行时实现与证据以 `/home/workspace/yield_curve` 为准。  
> 数据口径参考公开 `boe` 包文档与 BoE 官方收益率曲线发布规则。

---

## 1. 摘要

`yield_curve` 面向 BoE Anderson-Sleath 收益率曲线，覆盖五类曲线（nominal/real/implied inflation/OIS/BLC）、两类指标（spot/forward）、两类期限段（standard/short）与日频/月频双频输出。模块以独立 C/S 形态部署，复用共享基座，使用 `domain_macro` 领域共享层，落地七类持久化与消息介质。

---

## 2. 目标

- 建立 `yield_curve` 生产级规格与追溯闭环。
- 明确采集清单、更新频率、同步周期、历史起点、采集策略。
- 提供可回放、可审计、可对账的收益率曲线数据产品。
- 为 `macro_data`、`macro_regime`、`factor_engine` 提供稳定契约。

---

## 3. 非目标

- 不实现跨央行或跨 provider 聚合仲裁。
- 不实现交易策略、仓位、风控决策逻辑。
- 不将原始 Excel 表结构作为长期外部契约。
- 不在文档、日志、代码中提交 secret 值。

---

## 4. 用户与消费者

| 消费者 | 使用方式 | 边界 |
| ------ | -------- | ---- |
| `macro_data` | 通过 API/Kafka/domain_macro 消费曲线事实 | 不依赖 `yield_curve/internal/*` |
| `macro_regime` / `factor_engine` | 使用期限利差、通胀预期、曲率特征 | 不依赖 provider DTO |
| 运维治理 | 使用 admin API + NATS 控制面管理作业 | 不写业务事实表 |
| 审计回放 | 读取 OSS raw 与 Postgres checkpoint | 不绕过幂等账本 |

---

## 5. 功能需求

| ID | WHEN | THEN |
| -- | ---- | ---- |
| FR-YC-001 | WHEN 任一曲线子模块启动 | THEN 必须以独立 client/server 双服务运行并暴露 health/readiness/version。 |
| FR-YC-002 | WHEN 服务加载配置 | THEN 必须经共享配置组件加载，且只使用 secret reference。 |
| FR-YC-003 | WHEN 采集 BoE 曲线 | THEN 必须覆盖 nominal、real、implied inflation、OIS、BLC 五类曲线。 |
| FR-YC-004 | WHEN 处理曲线指标与期限段 | THEN 必须支持 spot/forward 与 standard/short 双维度输出。 |
| FR-YC-005 | WHEN 选择频率 | THEN 必须支持 daily 与 monthly，且保持语义一致。 |
| FR-YC-006 | WHEN 执行 latest 路径采集 | THEN 默认从 `latest-yield-curve-data.zip` 拉取最新月份日度数据。 |
| FR-YC-007 | WHEN 指定 `from/to` 或 `frequency=monthly` | THEN 必须自动切换 archive 路径拉取历史归档。 |
| FR-YC-008 | WHEN 请求 BLC 曲线 | THEN 必须强制路由到 archive 数据源。 |
| FR-YC-009 | WHEN 完成采集 | THEN 结果必须记录 `source`（latest/archive）、`source_url`、`fetched_at`。 |
| FR-YC-010 | WHEN 解析归档 ZIP | THEN 必须支持多工作簿透明拼接（1970-2015/2016-2024/2025+）。 |
| FR-YC-011 | WHEN 遇到旧版布局 | THEN 必须通过内容驱动期限行检测完成兼容解析。 |
| FR-YC-012 | WHEN 收到原始响应 | THEN 必须先写 OSS raw，再执行归一化并写入 taos/postgres。 |
| FR-YC-013 | WHEN client 输出 handoff/control 或业务事件 | THEN NATS 仅 ingest/control，Kafka 仅 durable event。 |
| FR-YC-014 | WHEN 执行缓存与协调 | THEN Redis latest 缓存 TTL=24h，archive TTL=30d，并提供锁与限流能力。 |
| FR-YC-015 | WHEN 提供查询能力 | THEN 必须在 ClickHouse 维护分析读模型并提供查询/API。 |
| FR-YC-016 | WHEN 执行增量/全量/重同步与治理审计 | THEN 必须输出覆盖率报告并支持缺口重采与手动重同步。 |

### 5.1 模块采集清单

| 采集维度 | 具体内容 |
| -------- | -------- |
| 曲线类型 | nominal gilt、real gilt、implied inflation、OIS、BLC |
| 指标类型 | spot、forward |
| 期限分段 | standard（0.5Y 步长，0.5Y-25Y/40Y）、short（1M 步长，1M-5Y） |
| 数据粒度 | daily、monthly |
| 来源标识 | `source` + `source_url` + `fetched_at` |

### 5.2 定时更新频率与同步周期

| 曲线类型 | 默认调度频率 | 增量同步周期 | 全量对账周期 | 缓存策略 | 目标单轮耗时 |
| -------- | ------------ | ------------ | ------------ | -------- | ------------ |
| nominal | 日频 + 月末归档 | 1h | 每月 | latest 24h / archive 30d | `<=30min` |
| real | 日频 + 月末归档 | 1h | 每月 | latest 24h / archive 30d | `<=30min` |
| implied inflation | 日频 + 月末归档 | 1h | 每月 | latest 24h / archive 30d | `<=30min` |
| OIS | 日频 + 月末归档 | 1h | 每月 | latest 24h / archive 30d | `<=30min` |
| BLC | 月频归档为主 | 24h | 每月 | archive 30d | `<=30min` |

频率语义：
- `daily`：返回“最新已发布月份”的全量日度点位；
- `monthly`：从 archive 提取月末点位，适合长期序列分析。

归档稳定性：archive 数据通常稳定，仅在方法论变更或历史修订时更新。

### 5.3 历史数据同步启点

| 曲线类型 | 默认历史起点 | 规则 |
| -------- | ------------ | ---- |
| nominal | `1979-01-01` | 若源站更晚，则以最早可用日期为准 |
| real | `1985-01-01` | 同上 |
| implied inflation | `1985-01-01` | 与 real/nominal 联动回补 |
| OIS | `2009-01-01` | 仅在 OIS 可用区间回补 |
| BLC | `2000-01-01` | 强制 archive 路由，按月回补 |

历史窗口支持 `StartBackfill` 指定起始日期和曲线类型范围。

短端（short）历史窗口与对应曲线类型同步；nominal short 默认可追溯至 `1979-01-01`。

### 5.4 采集策略

| 策略 | 规则 |
| ---- | ---- |
| Open ZIP Pull | 默认通过公开 ZIP 端点拉取，无需私有密钥。 |
| Dual Path | 默认 latest；指定时间窗或月频自动切换 archive。 |
| BLC Special Route | BLC 请求强制 archive。 |
| Source Audit | 每次查询记录 `source/source_url/fetched_at`。 |
| Workbook Stitching | archive 多工作簿自动拼接并做连续性校验。 |
| Legacy Layout Compat | 使用期限行内容检测兼容旧版布局。 |
| Raw-First | 先 OSS raw，再归一化、持久化、事件发布。 |
| Incremental + Full Re-sync | 日常增量；初始化/迁移/修复支持全量与手动重同步。 |
| ETL/ELT 分层 | 采集先入 staging，再加载贴源层/整合层。 |
| Tiered Storage | staging 保留近 1 个月；贴源层保留全量历史 + 最新快照。 |
| Dual-Bus | NATS ingest/control；Kafka durable event。 |
| Gap Replay | 覆盖率审计发现缺口后自动生成重采任务。 |

### 5.5 同步方式与重同步策略

| 模式 | 触发条件 | 说明 |
| ---- | -------- | ---- |
| 增量同步 | 定时调度 | 仅拉取游标后变更，作为默认主路径。 |
| 全量同步（Full Sync） | 初始化、迁移、修复、月度兜底 | 拉取完整窗口并重建校验基线。 |
| 手动重同步（Re-sync） | 运维/API 手动触发 | 支持按曲线类型、日期范围、指标类型重跑。 |

---

## 6. 行为约束

| ID | 规则 |
| -- | ---- |
| BR-YC-001 | 各曲线子模块保持独立 C/S 边界。 |
| BR-YC-002 | `available_at` 是 no-lookahead 判定依据，缺失不得出域。 |
| BR-YC-003 | 同一 curve/tenor/date/source 的写入必须幂等。 |
| BR-YC-004 | NATS 与 Kafka 分层不可混用。 |
| BR-YC-005 | Postgres checkpoint 先于 completed。 |
| BR-YC-006 | Redis 与 ClickHouse 仅可重建层。 |
| BR-YC-007 | OSS raw 路径需包含 curve_type、source、date、job_id、hash。 |
| BR-YC-008 | 下游只依赖 API/Kafka/`domain_macro`，不得依赖内部 DTO。 |
| BR-YC-009 | latest/archive 路由规则必须可审计与回放。 |
| BR-YC-010 | 历史起点、缓存 TTL、同步模式必须版本化可审计。 |

---

## 7. 非功能需求

| ID | 类别 | 要求 |
| -- | ---- | ---- |
| NFR-YC-001 | Freshness | daily 滞后 `<24h`；monthly 滞后 `<72h`。 |
| NFR-YC-002 | Latency | 单轮同步目标 `<=30min`。 |
| NFR-YC-003 | Throughput | 支持多曲线并行回补且互不阻塞。 |
| NFR-YC-004 | Reliability | 任一存储写入失败不得推进 checkpoint。 |
| NFR-YC-005 | Observability | 完整暴露 source/path/cache hit/replay 指标。 |
| NFR-YC-006 | Security | secret redaction、最小权限与日志脱敏。 |
| NFR-YC-007 | Governance | 覆盖率、缺口任务、重同步证据可追溯。 |

---

## 8. Acceptance Criteria Registry

| AC | 验收摘要 | 覆盖需求 |
| -- | -------- | -------- |
| AC-YC-001 | 五类曲线子模块可独立双服务启动 | FR-YC-001 |
| AC-YC-002 | 配置不泄密且只用 secret reference | FR-YC-002, NFR-YC-006 |
| AC-YC-003 | 采集清单覆盖五类曲线、双指标、双期限段 | FR-YC-003~005 |
| AC-YC-004 | latest/archive/BLC 路由行为正确 | FR-YC-006~008, BR-YC-009 |
| AC-YC-005 | source/source_url/fetched_at 审计字段完整 | FR-YC-009 |
| AC-YC-006 | 多工作簿拼接与旧版兼容解析通过 | FR-YC-010, FR-YC-011 |
| AC-YC-007 | raw-first + 七类介质链路闭合 | FR-YC-012~015 |
| AC-YC-008 | 增量/全量/重同步可用，缺口重采闭环 | FR-YC-016 |
| AC-YC-009 | 边界门禁阻断绕过共享基座直连 | BR-YC-001, BR-YC-008 |
| AC-YC-010 | 宏观分析补充项可用且可解释 | NFR-YC-007, §21 |

---

## 9. 追溯与测试门禁

追溯矩阵见 [matrix/TRACEABILITY.md](../matrix/TRACEABILITY.md)。FR/BR/NFR/AC/TC 变更必须同步矩阵与验收文档。

---

## 10. 版本记录

| 日期 | 版本 | 变更 | 作者 |
| ---- | ---- | ---- | ---- |
| 2026-07-03 | v0.1.0 | 初始化生产目标规格（采集清单、频率、周期、起点、策略、宏观分析补充） | ZoneCNH |

---

## 11. 错误处理

| 错误类 | 服务行为 | 证据 |
| ------ | -------- | ---- |
| latest 端点不可用 | 自动降级 archive 或重试，不推进 checkpoint | retry + source logs |
| archive ZIP 分片缺失 | 标记缺口并生成重采任务 | coverage gap report |
| 旧版布局解析失败 | 进入兼容解析分支并隔离异常批次 | parser fallback logs |
| 多工作簿拼接冲突 | 不推进 completed，输出连续性告警 | continuity check report |
| 缓存异常污染 | 失效缓存并强制源站重拉 | cache invalidation logs |
| 写入失败 | 保留 checkpoint，进入重放队列 | replay backlog metrics |

---

## 12. 边界情况

| 场景 | 处理 |
| ---- | ---- |
| BLC 在 latest 路径被请求 | 强制路由 archive 并记录原因 |
| 同日期多版本归档 | 以 `source_url + fetched_at` 区分版本链 |
| tenor 缺失或变形 | 用内容检测与插值策略，标记质量等级 |
| monthly 与 daily 冲突 | monthly 走 archive 口径，daily 走 latest 口径 |
| archive 仅在方法更新时修订 | 保留 revision 事件并触发对账 |

---

## 13. 目录结构

| 路径 | 目标职责 |
| ---- | -------- |
| `cmd/yc-nominal-client/` | nominal 采集入口 |
| `cmd/yc-nominal-server/` | nominal 消费/查询入口 |
| `cmd/yc-real-client/` | real 采集入口 |
| `cmd/yc-real-server/` | real 消费/查询入口 |
| `cmd/yc-inflation-client/` | implied inflation 采集入口 |
| `cmd/yc-inflation-server/` | implied inflation 消费/查询入口 |
| `cmd/yc-ois-client/` | OIS 采集入口 |
| `cmd/yc-ois-server/` | OIS 消费/查询入口 |
| `cmd/yc-blc-client/` | BLC 采集入口 |
| `cmd/yc-blc-server/` | BLC 消费/查询入口 |
| `internal/client/` | provider client、路由、解析、归一化 |
| `internal/server/` | consumer、存储编排、API |
| `internal/cs/` | 契约、错误码、版本协商 |
| `pkg/yieldcurvex/` | 对外稳定 Go client |
| `scripts/` | boundary gate、lint、集成校验 |

---

## 14. 依赖

| 依赖 | 用途 | 边界 |
| ---- | ---- | ---- |
| `bootstrap` | 生命周期装配 | 必须作为入口编排层 |
| `configx` | 配置映射与校验 | 仅引用 secret reference |
| `observex` | 日志、指标、trace | job 全链路带 correlation id |
| `resiliencx` | 重试、熔断、限流 | client 强制接入 |
| `contracts` / `transportx` | API 与事件契约版本化 | 公共契约必须可校验 |
| `domain_macro` | 领域共享语义与 no-lookahead | 对外模型必须来自该层 |
| `taosx/kafkax/postgresx/redisx/ossx/natsx/clickhousex` | 七类基础设施访问 | 只能经共享基座访问 |

---

## 15. 测试

| TC | 覆盖对象 | 关联需求 |
| -- | -------- | -------- |
| TC-YC-001 | 五类曲线采集覆盖测试 | FR-YC-003~005 |
| TC-YC-002 | latest/archive/BLC 路由测试 | FR-YC-006~008 |
| TC-YC-003 | source 审计字段完整性测试 | FR-YC-009 |
| TC-YC-004 | 多工作簿拼接与连续性测试 | FR-YC-010 |
| TC-YC-005 | 旧版布局兼容解析测试 | FR-YC-011 |
| TC-YC-006 | raw-first + 多存储链路集成测试 | FR-YC-012~015 |
| TC-YC-007 | NATS/Kafka 分层边界测试 | FR-YC-013, BR-YC-004 |
| TC-YC-008 | 缓存 TTL 与重建测试 | FR-YC-014, BR-YC-006 |
| TC-YC-009 | 增量/全量/重同步与缺口重采测试 | FR-YC-016 |
| TC-YC-010 | no-lookahead 与宏观分析衍生字段测试 | BR-YC-002, AC-YC-010 |

---

## 16. 性能预算

| 指标 | 预算 |
| ---- | ---- |
| 单轮同步耗时 | `<=30min` |
| API 热点查询 P95 | `<300ms` |
| Kafka publish lag | `<10s` |
| ClickHouse read model lag | `<60s` |
| latest 缓存命中率 | `>=90%` |
| daily freshness | `<24h` |

---

## 17. 可观测性

| 类型 | 指标或字段 |
| ---- | ---------- |
| Logs | curve_type、source、source_url、job_id、error_class |
| Metrics | ingest_count、cache_hit_ratio、stitch_error_count、publish_lag |
| Traces | fetch、unzip、parse、normalize、store_write、publish |
| Health | source connectivity、storage readiness、bus readiness |
| Audit | source/source_url/fetched_at、hash、checkpoint version |

---

## 18. 安全

| 控制点 | 要求 |
| ------ | ---- |
| Secret handling | 仅 secret reference，不输出密钥值 |
| Access control | admin API 鉴权、审计、限流 |
| Raw payload | OSS 最小权限访问，路径含 hash |
| Event payload | 不包含凭证和私有端点 |
| Log redaction | 错误日志脱敏 |

---

## 19. CI 门禁

| Gate | 命令或检查 |
| ---- | ---------- |
| Markdown patch | `git diff --check` |
| Spec structure | `.github/ci/spec-lint.sh` |
| Traceability | `.github/ci/traceability-check.sh` |
| Boundary | `bash scripts/boundary-gates.sh` |
| Go checks | `go test ./...`、`go vet ./...` |
| Secret scan | `gitleaks detect --no-git`（runtime 仓） |

---

## 20. 升级兼容性

| 变更 | 兼容策略 |
| ---- | -------- |
| BoE 布局变更 | 增加解析器版本与回退策略 |
| API 升级 | 通过 `internal/cs` 与 `pkg/yieldcurvex` 协商版本 |
| 事件 schema 升级 | Kafka event 强制 schema version 与兼容读者 |
| 缓存 key 升级 | Redis namespace version + TTL 迁移 |
| 历史回补策略变更 | 记录 migration 版本并可回放审计 |

---

## 21. 做宏观分析还需补充项

| 补充项 | 目的 | 最小交付 |
| ------ | ---- | -------- |
| 货币政策联动（Bank Rate/MPC） | 建立政策传导解释链 | Bank Rate + MPC 决议事件表 |
| 宏观指标联动（GDP/CPI/RPI/就业） | 定位经济周期与通胀驱动 | 跨指标联动视图 |
| 跨市场比较（UST/Euro AAA） | 识别相对价值与资本流向 | 美英 10Y 利差 + G7 比较面板 |
| 期限利差指标（10Y-2Y/10Y-3M） | 经济衰退预警 | slope/inversion 时长序列 |
| 5y5y 远期通胀预期 | 市场通胀预期跟踪 | 5y5y 特征字段 |
| 名义-实际利差 | 盈亏平衡通胀分析 | breakeven inflation 曲线 |
| 高频补充（期货/互换） | 提升时效与预警敏感度 | intraday 特征表 |
| 数据血缘与口径治理 | 防止口径漂移 | 字段字典、血缘图、方法变更记录 |
| 数据质量监控 | 保证完整性/一致性/及时性 | completeness/timeliness/anomaly 评分 |
| 货币与信贷数据补充 | 提升流动性与信用周期解释力 | Broad Money/Credit 指标联动视图 |
| 住房市场指标补充 | 强化实体经济传导观测 | 房价/成交/按揭成本联动视图 |
| 汇率维度补充 | 评估外部冲击与通胀传导 | GBP 主要货币对与收益率联动特征 |
| 生产与沙箱隔离 | 防止测试数据污染分析 | prod/sandbox 隔离规则与审计 |

---

## 22. 运行时边界

| 组件 | 职责 | 禁止事项 |
| ---- | ---- | -------- |
| `*-client` | 采集、路由、解析、NATS 发布 | 不直接写业务权威存储 |
| `*-server` | 消费、持久化、查询 API、Kafka 事件 | 不直接抓源站 ZIP |
| `internal/cs` | 契约、错误码、版本协商 | 不承载业务策略 |
| `pkg/yieldcurvex` | 对外 Go client | 不泄漏传输实现细节 |
| `scripts/boundary-gates.sh` | 边界门禁 | 不允许直连基础设施绕过基座 |

---

## 23. 变更历史

| 日期 | 版本 | 变更 | 作者 |
| ---- | ---- | ---- | ---- |
| 2026-07-03 | v0.1.0 | 初始化生产目标规格（采集清单、频率、周期、起点、策略、宏观分析补充） | ZoneCNH |
