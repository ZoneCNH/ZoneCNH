# yield_curve 完整实现清单

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Generated from current module SSOT |
| Last-Updated | 2026-07-03 |
| Module-Version | v0.1.0 |
| Module-State | Production Target（Planned） |
| Layer | 数据域 · 宏观 |
| Module-Type | 独立 C/S Module（`nominal/real/inflation/ois/blc`） |
| Runtime-Repo | `/home/workspace/yield_curve` |
| Sources | `goal/goal.md`、`spec/SPEC.md`、`matrix/TRACEABILITY.md`、`plan/PLAN.md` |

本文档是 `module/yield_curve/` 当前规格资产的功能投影，说明目标能力与剩余闭合面。运行时通过证明以 `spec/ACCEPTANCE.md` 为准。

## 模块边界

| 维度 | 定义 |
| --- | --- |
| 服务形态 | 五类曲线子模块均为独立 C/S 服务单元，可独立部署。 |
| 领域共享层 | 对外语义统一为 `domain_macro`，下游不依赖 provider DTO。 |
| 共享基座 | 配置、日志、指标、追踪、弹性与基础设施适配器全部复用共享基座组件。 |
| 持久化/消息 | `taos`、`kafka`、`postgres`、`Redis`、`oss`、`nats`、`clickhouse` 均在目标边界内。 |
| 禁止所有权 | 不承载策略决策、交易执行、风险控制。 |

## 功能投影

| ID | 功能 | 当前状态 | 剩余实现面 |
| --- | --- | --- | --- |
| FR-YC-001 | 五子模块 client/server 独立启动 | Planned | runtime 双服务入口与生命周期证据 |
| FR-YC-002 | 配置通过共享组件加载且不泄密 | Planned | config schema + redaction 测试 |
| FR-YC-003 | 五类曲线采集覆盖 | Planned | nominal/real/inflation/ois/blc 端点覆盖 |
| FR-YC-004 | spot/forward + standard/short 双维度 | Planned | 指标/期限段映射与校验 |
| FR-YC-005 | daily/monthly 双频输出 | Planned | 频率策略与一致性校验 |
| FR-YC-006 | latest 路径采集 | Planned | latest ZIP 拉取与解析 |
| FR-YC-007 | archive 路径采集 | Planned | 条件切换与历史拉取 |
| FR-YC-008 | BLC 归档强制路由 | Planned | 路由规则与回归测试 |
| FR-YC-009 | source/source_url/fetched_at 审计 | Planned | 审计字段完整性 |
| FR-YC-010 | 多工作簿拼接 | Planned | 分段文件拼接与连续性校验 |
| FR-YC-011 | 旧版布局兼容解析 | Planned | 期限行检测策略 |
| FR-YC-012 | raw-first + taos/postgres 写入 | Planned | raw 路径、哈希、失败恢复 |
| FR-YC-013 | NATS/Kafka 双总线分层 | Planned | handoff/control vs durable event |
| FR-YC-014 | Redis 缓存（24h/30d）与协调 | Planned | TTL、锁、限流桶 |
| FR-YC-015 | ClickHouse 分析读模型与查询 API | Planned | 可重建宽表与查询契约 |
| FR-YC-016 | 增量/全量/重同步 + 缺口重采 | Planned | 审计报表、重采任务、证据闭合 |

## 业务规则

| ID | 规则 | 状态 |
| --- | --- | --- |
| BR-YC-001 | 子模块保持独立 C/S 边界 | Planned |
| BR-YC-002 | `available_at` 是 no-lookahead 判定依据 | Planned |
| BR-YC-003 | 同键写入必须幂等 | Planned |
| BR-YC-004 | NATS 与 Kafka 分层不可混用 | Planned |
| BR-YC-005 | checkpoint 先于 completed | Planned |
| BR-YC-006 | Redis/ClickHouse 仅可重建层 | Planned |
| BR-YC-007 | OSS raw 路径含 hash 与作业元数据 | Planned |
| BR-YC-008 | 下游只依赖 API/Kafka/domain_macro | Planned |
| BR-YC-009 | latest/archive/BLC 路由可审计 | Planned |
| BR-YC-010 | 历史起点、缓存 TTL、同步模式可审计 | Planned |

## 当前缺口

1. `/home/workspace/yield_curve` 运行时服务骨架与边界脚本尚待落地。
2. latest/archive/BLC 三类路由与多工作簿拼接仍处于规格态。
3. 七类介质链路缺少 runtime 集成证据与回放验证。
4. 宏观分析补充项（政策联动、跨市场、质量治理）需在 API/事件层补齐。

