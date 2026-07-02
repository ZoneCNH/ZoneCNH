# resiliencx

> 弹性容错运行时库 — Timeout/Retry/CircuitBreaker/Bulkhead/RateLimiter/Fallback、Compose、InstrumentStrategy

| 字段 | 值 |
| --- | --- |
| 仓库 | https://github.com/ZoneCNH/resiliencx |
| 层级 | L1 primitives |
| Spec 版本 | v1.1.0 |
| 依赖 | kernel（观测通过本地接口或 adapter） |
| 规格 | [module/resiliencx/SPEC.md](module/resiliencx/SPEC.md) |

## 概述

弹性容错运行时库 — Timeout/Retry/CircuitBreaker/Bulkhead/RateLimiter/Fallback、Compose、InstrumentStrategy

## 架构边界

- 层级：L1 primitives
- 允许依赖：kernel（观测通过本地接口或 adapter）
- 禁止：反向依赖上层模块、业务域模块

## 相关文档

- [规格](module/resiliencx/SPEC.md)
- [依赖矩阵](../FOUNDATION-DEPS.yaml)
- [注册表](../registry.yaml)
