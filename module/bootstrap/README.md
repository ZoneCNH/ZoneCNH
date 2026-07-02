# bootstrap

> L1 Assembly 通用进程组装层 — 统一组装 configx/observex/resiliencx/lifecycx + 可选存储 adapter（StoreSet 位掩码）

| 字段 | 值 |
| --- | --- |
| 仓库 | https://github.com/ZoneCNH/bootstrap |
| 层级 | L1 Assembly |
| Spec 版本 | v0.2.0 |
| 依赖 | kernel, configx, observex, resiliencx + 7 存储 adapter |
| 规格 | [module/bootstrap/SPEC.md](module/bootstrap/SPEC.md) |

## 概述

L1 Assembly 通用进程组装层 — 统一组装 configx/observex/resiliencx/lifecycx + 可选存储 adapter（StoreSet 位掩码）

## 架构边界

- 层级：L1 Assembly
- 允许依赖：kernel, configx, observex, resiliencx + 7 存储 adapter
- 禁止：反向依赖上层模块、业务域模块

## 相关文档

- [规格](module/bootstrap/SPEC.md)
- [依赖矩阵](../FOUNDATION-DEPS.yaml)
- [注册表](../registry.yaml)
