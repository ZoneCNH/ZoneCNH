# kafkax

> Kafka L2 adapter — 消息队列、事件流（driver-neutral API + kafka-go 生产驱动）

| 字段 | 值 |
| --- | --- |
| 仓库 | https://github.com/ZoneCNH/kafkax |
| 层级 | 存储扩展 |
| Spec 版本 | v1.2.0 |
| 依赖 | kernel, observex |
| 规格 | [module/kafkax/SPEC.md](module/kafkax/SPEC.md) |

## 概述

Kafka L2 adapter — 消息队列、事件流（driver-neutral API + kafka-go 生产驱动）

## 架构边界

- 层级：存储扩展
- 允许依赖：kernel, observex
- 禁止：反向依赖上层模块、业务域模块

## 相关文档

- [规格](module/kafkax/SPEC.md)
- [依赖矩阵](../FOUNDATION-DEPS.yaml)
- [注册表](../registry.yaml)
