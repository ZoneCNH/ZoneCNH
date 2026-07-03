# yahoo Goal

## 元数据

| 字段 | 值 |
| ---- | -- |
| Module | `yahoo` |
| Domain | 数据域 · 宏观 |
| Goal-ID | `GOAL-YAHOO-001` |
| Status | Draft |
| Owner | 数据域 |
| Last-Updated | 2026-07-04 |
| Source-Code | `/home/workspace/yahoo/` |

## 目标陈述

把 `yahoo` 建设为数据域 · 宏观的独立 C/S 服务：通过共享基座组件和 `domain_macro` 领域共享层接入 Yahoo 宏观相关数据，具备完整持久化、事件发布、查询服务、回放能力和 no-lookahead 语义，供 `macro_data` 及分析域消费。

## 成功标准

| ID | 成功标准 |
| -- | -------- |
| G-SC-001 | `yahoo` 可作为独立双服务运行，服务端不依赖 `macro_data` 进程内实现。 |
| G-SC-002 | 配置由 `sre/secrets/env/dev.md` 经 `configx` 映射，文档和代码不写密钥值。 |
| G-SC-003 | Yahoo 数据统一归一化为 `domain_macro` 兼容模型。 |
| G-SC-004 | 完成 `taos`、`kafka`、`postgres`、`Redis`、`oss`、`nats`、`clickhouse` 职责分配。 |
| G-SC-005 | 下游只依赖服务 API、事件契约或领域共享层，不依赖 provider DTO。 |
| G-SC-006 | 同步、回补、修订、幂等、no-lookahead 有可验证证据。 |

## 非目标

| ID | 非目标 |
| -- | ------ |
| G-NG-001 | 不在 `yahoo` 内实现跨 provider 聚合；聚合属于 `macro_data`。 |
| G-NG-002 | 不把 Yahoo 原始字段暴露为长期公共契约。 |
| G-NG-003 | 不在文档、测试 fixture 或源码中提交 secret 原值。 |
| G-NG-004 | 不绕过共享基座直连基础设施。 |

