# bea 模块索引

`bea` 是数据域 · 宏观的独立 C/S 模块，按 **client/server 双服务** 运行，面向 BEA（美国经济分析局）数据采集、归一化、持久化、事件发布、分析与报告。

## 文档入口

| 文档 | 用途 |
| ---- | ---- |
| [goal/goal.md](goal/goal.md) | 模块目标、边界与成功标准 |
| [spec/SPEC.md](spec/SPEC.md) | 生产目标规格（采集清单、频率、同步策略） |
| [spec/FEATURES.md](spec/FEATURES.md) | 完整实现清单与当前缺口 |
| [spec/ACCEPTANCE.md](spec/ACCEPTANCE.md) | 完整验收清单与发布阻断条件 |
| [matrix/TRACEABILITY.md](matrix/TRACEABILITY.md) | FR/BR/AC/TC 追溯矩阵 |
| [plan/PLAN.md](plan/PLAN.md) | 分阶段实施计划 |
| [tasks/README.md](tasks/README.md) | 可执行任务清单 |
| [CHANGELOG.md](CHANGELOG.md) | 变更记录 |

## 核心约束

1. `bea-client` 与 `bea-server` 必须独立部署与扩缩容。
2. 必须复用共享基座组件（`bootstrap/configx/observex/resiliencx` + 基础设施适配器）。
3. 必须通过 `domain_macro` 输出领域语义，禁止暴露 BEA 原始 DTO。
4. 必须完整落地 `taos + kafka + postgres + Redis + oss + nats + clickhouse`。

## 当前规划范围（v0.2.0）

- 三层采集清单：核心宏观、国际与投资、深化分析。
- 技术实现：参数驱动采集、限流与退避、版本修订管理、发布日历触发。
- 分析框架：指标体系、模块化分析、跨源一致性校验、自动报告与预警。
