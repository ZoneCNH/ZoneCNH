# clickhousex

> ClickHouse L2 adapter — OLAP 查询、批量写入

| 字段 | 值 |
| --- | --- |
| 仓库 | https://github.com/ZoneCNH/clickhousex |
| 层级 | 存储扩展 |
| Spec 版本 | v1.1.0 |
| 依赖 | kernel, observex |
| 规格 | [module/clickhousex/SPEC.md](module/clickhousex/SPEC.md) |

## 概述

ClickHouse L2 adapter — OLAP 查询、批量写入

## 架构边界

- 层级：存储扩展
- 允许依赖：kernel, observex
- 禁止：反向依赖上层模块、业务域模块

## 相关文档

- [规格](module/clickhousex/SPEC.md)
- [依赖矩阵](../FOUNDATION-DEPS.yaml)
- [注册表](../registry.yaml)
