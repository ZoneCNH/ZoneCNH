# fred 模块索引

`fred` 是 **数据域 · 宏观** 下的独立 C/S 模块和独立服务，面向 FRED 宏观经济时间序列的采集、修订管理、领域归一化、持久化、事件发布和查询服务。

## 文档入口

| 文档 | 用途 |
| ---- | ---- |
| [goal.md](goal.md) | 业务目标、边界、成功指标 |
| [SPEC.md](SPEC.md) | 完整模块规格、领域边界、接口与验收 |
| [TRACEABILITY.md](TRACEABILITY.md) | Goal / FR / BR / AC / TC 追踪矩阵 |
| [IMPLEMENTATION-PLAN.md](IMPLEMENTATION-PLAN.md) | 从当前仓库状态迁移到目标 C/S 服务的实施计划 |

## 目标边界

| 维度 | 约束 |
| ---- | ---- |
| 所属域 | 数据域 · 宏观 |
| 模块类型 | 独立 C/S 模块，独立服务 |
| 代码仓库 | `github.com/ZoneCNH/fred` |
| 本地代码路径 | `/home/fred/` |
| 共享基座 | `bootstrap`、`configx`、`observex`、`resiliencx`、`transportx`、`contracts`、存储适配器 |
| 领域共享层 | `domain_macro`、`decimalx`、宏观发布日历与 no-lookahead 语义 |
| 配置来源 | `sre/secrets/env/dev.md`，只引用配置项类别，不复制密钥值 |
| 持久化目标 | `taos`、`kafka`、`postgres`、`Redis`、`oss`、`nats`、`clickhouse` |

## 服务职责

1. 从 FRED 拉取 series、observation、release、revision / vintage 相关数据。
2. 将 provider DTO 转换为 `domain_macro` 共享领域模型，保留发布时间、可见时间与修订版本。
3. 通过共享基座组件完成配置、观测、生命周期、限流、重试、存储、传输和契约校验。
4. 将原始载荷、规范化时间序列、元数据、事件流、缓存和分析读模型分别落到对应持久化介质。
5. 对 `macro_data`、分析域、SRE 工具和回放作业提供稳定的服务端 API 与事件契约。

## 当前迁移提示

`/home/fred` 当前已有 Go 模块、`cmd/fred-server`、`pkg/fredx` 和边界脚本骨架；目标规格要求从旧的“adapter 零存储”口径迁移为独立服务拥有的完整持久化与事件边界。实施时必须同步更新代码边界门禁，避免旧的 `Stores=None` 约束继续阻止目标架构落地。
