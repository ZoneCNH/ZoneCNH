# testkitx

> 测试专用能力库 — FakeConfig/FakeLogger/FakeMeter/FakeTracer/FakeClock、Golden、Contract、Boundary、GoroutineLeak 检查。生产禁止 import

| 字段 | 值 |
| --- | --- |
| 仓库 | https://github.com/ZoneCNH/testkitx |
| 层级 | L1 测试 |
| Spec 版本 | v1.1.0 |
| 依赖 | kernel, configx, observex, resiliencx, schedulex |
| 规格 | [module/testkitx/SPEC.md](module/testkitx/SPEC.md) |

## 概述

测试专用能力库 — FakeConfig/FakeLogger/FakeMeter/FakeTracer/FakeClock、Golden、Contract、Boundary、GoroutineLeak 检查。生产禁止 import

## 架构边界

- 层级：L1 测试
- 允许依赖：kernel, configx, observex, resiliencx, schedulex
- 禁止：反向依赖上层模块、业务域模块

## 相关文档

- [规格](module/testkitx/SPEC.md)
- [依赖矩阵](../FOUNDATION-DEPS.yaml)
- [注册表](../registry.yaml)
