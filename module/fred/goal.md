# fred Goal

## 元数据

| 字段 | 值 |
| ---- | -- |
| Module | `fred` |
| Domain | 数据域 · 宏观 |
| Goal-ID | `GOAL-FRED-001` |
| Status | Draft |
| Owner | 数据域 |
| Last-Updated | 2026-06-22 |
| Source-Code | `/home/fred/` |

## 目标陈述

把 `fred` 建设为数据域 · 宏观的独立 C/S 服务：它通过共享基座组件和 `domain_macro` 领域共享层接入 FRED 数据源，拥有完整持久化、事件发布、查询服务、回放能力和 no-lookahead 语义，供 `macro_data` 聚合器及下游分析系统消费。

## 成功标准

| ID | 成功标准 |
| -- | -------- |
| G-SC-001 | `fred` 可作为独立进程启动，服务端不依赖 `macro_data` 进程内实现。 |
| G-SC-002 | 所有运行配置从 `sre/secrets/env/dev.md` 映射进入 `configx`，模块文档和源码不复制密钥值。 |
| G-SC-003 | FRED series / observation / release / revision 数据被归一化为 `domain_macro` 兼容模型。 |
| G-SC-004 | 按目标介质完成 `taos`、`kafka`、`postgres`、`Redis`、`oss`、`nats`、`clickhouse` 的职责分配。 |
| G-SC-005 | 下游只依赖服务 API、事件契约或领域共享层，不读取 `fred` provider 内部 DTO。 |
| G-SC-006 | 回放、重试、幂等、修订版本和 no-lookahead 语义有测试或验证证据。 |

## 非目标

| ID | 非目标 |
| -- | ------ |
| G-NG-001 | 不在 `fred` 内实现宏观多 provider 聚合；聚合属于 `macro_data`。 |
| G-NG-002 | 不让下游直接依赖 FRED 原始 JSON 字段作为长期契约。 |
| G-NG-003 | 不在文档、测试 fixture 或源码中提交 `sre/secrets/env/dev.md` 的密钥值。 |
| G-NG-004 | 不绕过共享基座直接手写存储、消息队列或配置客户端。 |

## 边界原则

| ID | 原则 |
| -- | ---- |
| G-BD-001 | `fred` 是 provider 专属服务，负责 FRED 接入、修订管理和 provider 级持久化。 |
| G-BD-002 | `domain_macro` 是宏观领域语义和 no-lookahead 信息集的共享层。 |
| G-BD-003 | `macro_data` 通过事件、查询 API 或领域契约消费 `fred`，不得反向拥有 FRED provider 逻辑。 |
| G-BD-004 | 共享基座组件负责横切能力，业务代码只编排基座能力，不复制基座实现。 |

## 风险

| ID | 风险 | 控制 |
| -- | ---- | ---- |
| G-R-001 | 旧零存储适配器门禁与目标持久化服务冲突 | 在实施首阶段更新边界脚本与架构说明 |
| G-R-002 | FRED 修订数据被误用为事前可见数据 | 强制记录 `observed_at`、`released_at`、`available_at`、`vintage_at` |
| G-R-003 | 多存储双写导致不一致 | 使用幂等键、outbox、检查点和重放校验 |
| G-R-004 | dev secrets 被误写入模块文档 | 只引用配置路径和键类别，验证敏感值模式 |
