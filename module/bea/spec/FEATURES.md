# bea 完整实现清单

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Generated from current module SSOT |
| Last-Updated | 2026-07-04 |
| Module-Version | v0.2.0 |
| Module-State | Production Target（Planned） |
| Layer | 数据域 · 宏观 |
| Runtime-Repo | `/home/workspace/bea` |
| Sources | `goal/goal.md`、`spec/SPEC.md`、`matrix/TRACEABILITY.md`、`plan/PLAN.md` |

本文档是 `module/bea/` 当前规格资产的功能投影，描述目标能力与剩余闭合面。运行时验收以 `spec/ACCEPTANCE.md` 为准。

## 模块边界

| 维度 | 定义 |
| --- | --- |
| 服务形态 | 多数据集子模块均为独立 C/S 服务单元，可独立部署与扩容。 |
| 领域共享层 | 对外语义统一为 `domain_macro`，禁止暴露 BEA provider DTO。 |
| 共享基座 | 配置、日志、指标、追踪、弹性与基础设施适配器全部复用共享组件。 |
| 持久化与消息 | `taos`、`kafka`、`postgres`、`Redis`、`oss`、`nats`、`clickhouse` 均在目标边界内。 |
| 禁止所有权 | 不承载策略、交易、风控、跨 provider 仲裁。 |

## 分层采集能力投影

| 层级 | 数据集 | 状态 | 剩余实现面 |
| --- | --- | --- | --- |
| 第一层（必采） | NIPA、GDPbyIndustry、Regional | Planned | 数据集枚举、参数矩阵、发布窗口调度 |
| 第二层（推荐） | ITA、IIP、IntlServTrade | Planned | 国际账户口径映射、修订跟踪 |
| 第三层（按需） | FixedAssets、InputOutput、MNE、UnderlyingGDPbyIndustry | Planned | 深化分析字段标准化与窗口回补 |

## 技术实现能力投影

| ID | 能力 | 状态 | 剩余实现面 |
| --- | --- | --- | --- |
| FEAT-BEA-001 | 参数驱动采集（dataset/parameter/value） | Planned | API 编排与参数缓存 |
| FEAT-BEA-002 | 限流与错误熔断（100 req/min, 100MB/min, 30 errors/min） | Planned | 令牌桶、熔断、封禁保护模式 |
| FEAT-BEA-003 | Raw-First（OSS 原始载荷归档） | Planned | hash 路径与回放入口 |
| FEAT-BEA-004 | 七介质链路闭合 | Planned | 多存储事务与重放恢复 |
| FEAT-BEA-005 | 增量/全量/Re-sync 同步模型 | Planned | 游标推进、月度全量对账、手动重跑 |
| FEAT-BEA-006 | 版本修订管理（version/released_at/fetched_at/vintage_at） | Planned | revision diff 与五年修订流程 |
| FEAT-BEA-007 | 发布日历触发优先 | Planned | 日历驱动调度器与轮询兜底 |
| FEAT-BEA-008 | 数据质量校验（完整性/一致性/异常值/修订） | Planned | 规则引擎与阈值告警 |
| FEAT-BEA-009 | 自动报告链路（仪表盘 + PDF + 告警） | Planned | 报告模板与预警通道 |

## 分析框架能力投影

| 分析模块 | 输入数据 | 输出产品 | 状态 |
| --- | --- | --- | --- |
| 经济周期监测 | NIPA | 增长轨迹图、周期阶段判断 | Planned |
| 产业结构分析 | GDPbyIndustry | 行业贡献率与结构迁移图 | Planned |
| 区域经济画像 | Regional | 热力图、区域排名 | Planned |
| 需求侧拆解 | NIPA | 三驾马车贡献率 | Planned |
| 外部脆弱性 | ITA、IIP | 经常账户趋势、外部头寸评估 | Planned |

## 当前缺口

1. `/home/workspace/bea` 运行时服务骨架与边界脚本尚未完成。
2. 三层数据集尚未形成全量参数目录与同步证据。
3. 七介质链路缺少集成测试与回放证据。
4. 自动报告与异常预警仍在设计态。

