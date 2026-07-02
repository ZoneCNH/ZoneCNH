# redisx

> Redis L2 adapter — KV/TTL/Hash/List/Pipeline/Cache-aside/Lock/RateLimit/Pool

| 字段 | 值 |
| --- | --- |
| 仓库 | https://github.com/ZoneCNH/redisx |
| 层级 | 存储扩展 |
| Spec 版本 | v1.3.0 |
| 依赖 | kernel, observex |
| 规格 | [module/redisx/SPEC.md](module/redisx/SPEC.md) |

## 概述

Redis L2 adapter — KV/TTL/Hash/List/Pipeline/Cache-aside/Lock/RateLimit/Pool

## 架构边界

- 层级：存储扩展
- 允许依赖：kernel, observex
- 禁止：反向依赖上层模块、业务域模块

## 相关文档

- [规格](module/redisx/SPEC.md)
- [依赖矩阵](../FOUNDATION-DEPS.yaml)
- [注册表](../registry.yaml)
