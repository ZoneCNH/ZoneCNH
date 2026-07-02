# observex

> 可观测性语义契约库 — Logger/Meter/Tracer/Exporter、Redaction、Label Policy、Health（vendor-neutral）

| 字段 | 值 |
| --- | --- |
| 仓库 | https://github.com/ZoneCNH/observex |
| 层级 | L1 primitives |
| Spec 版本 | v1.1.0 |
| 依赖 | kernel |
| 规格 | [module/observex/SPEC.md](module/observex/SPEC.md) |

## 概述

可观测性语义契约库 — Logger/Meter/Tracer/Exporter、Redaction、Label Policy、Health（vendor-neutral）

## 架构边界

- 层级：L1 primitives
- 允许依赖：kernel
- 禁止：反向依赖上层模块、业务域模块

## 相关文档

- [规格](module/observex/SPEC.md)
- [依赖矩阵](../FOUNDATION-DEPS.yaml)
- [注册表](../registry.yaml)
