# schedulex

> 确定性调度器 — cron/interval/delay trigger、OverlapPolicy、MisfirePolicy、EventSink、Locker、Clock 注入

| 字段 | 值 |
| --- | --- |
| 仓库 | https://github.com/ZoneCNH/schedulex |
| 层级 | L1 primitives |
| Spec 版本 | v1.1.0 |
| 依赖 | kernel |
| 规格 | [module/schedulex/SPEC.md](module/schedulex/SPEC.md) |

## 概述

确定性调度器 — cron/interval/delay trigger、OverlapPolicy、MisfirePolicy、EventSink、Locker、Clock 注入

## 架构边界

- 层级：L1 primitives
- 允许依赖：kernel
- 禁止：反向依赖上层模块、业务域模块

## 相关文档

- [规格](module/schedulex/SPEC.md)
- [依赖矩阵](../FOUNDATION-DEPS.yaml)
- [注册表](../registry.yaml)
