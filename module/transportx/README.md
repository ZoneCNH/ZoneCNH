# transportx

> 跨 runtime / adapter 传输契约 — Envelope/Endpoint、ServiceIdentity、QoS、Codec、RPC、EventBus、Stream

| 字段 | 值 |
| --- | --- |
| 仓库 | https://github.com/ZoneCNH/transportx |
| 层级 | 契约/传输 |
| Spec 版本 | v1.3.0 |
| 依赖 | contracts, configx, observex, resiliencx |
| 规格 | [module/transportx/SPEC.md](module/transportx/SPEC.md) |

## 概述

跨 runtime / adapter 传输契约 — Envelope/Endpoint、ServiceIdentity、QoS、Codec、RPC、EventBus、Stream

## 架构边界

- 层级：契约/传输
- 允许依赖：contracts, configx, observex, resiliencx
- 禁止：反向依赖上层模块、业务域模块

## 相关文档

- [规格](module/transportx/SPEC.md)
- [依赖矩阵](../FOUNDATION-DEPS.yaml)
- [注册表](../registry.yaml)
