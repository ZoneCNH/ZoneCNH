# configx

> 配置加载、合并、解码、校验、脱敏 — Client/Loader/Source 模式、多源合并（YAML/TOML/JSON/.env/Env/Map）、StrictDecode、SecretString 脱敏、Provenance、HealthCheck

| 字段 | 值 |
| --- | --- |
| 仓库 | https://github.com/ZoneCNH/configx |
| 层级 | L1 primitives |
| Spec 版本 | v1.2.0 |
| 依赖 | kernel |
| 规格 | [module/configx/SPEC.md](module/configx/SPEC.md) |

## 概述

配置加载、合并、解码、校验、脱敏 — Client/Loader/Source 模式、多源合并（YAML/TOML/JSON/.env/Env/Map）、StrictDecode、SecretString 脱敏、Provenance、HealthCheck

## 架构边界

- 层级：L1 primitives
- 允许依赖：kernel
- 禁止：反向依赖上层模块、业务域模块

## 相关文档

- [规格](module/configx/SPEC.md)
- [依赖矩阵](../FOUNDATION-DEPS.yaml)
- [注册表](../registry.yaml)
