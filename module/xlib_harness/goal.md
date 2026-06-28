# xlib_harness Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `xlib_harness` |
| 层级 | 基座 · 治理工具 |
| 仓库 | <https://github.com/ZoneCNH/xlib_harness> |
| 状态 | Approved |

## 目标

`xlib_harness` 提供 FoundationX 自动化治理管线：Spec 生成器、门禁检查、评分管线调度、CI/CD 集成适配。作为 OMC 代理运维层与 CI 基础设施之间的胶水层。

## 非目标

- 不承载业务语义（纯治理工具）
- 不替代 x.go CLI（x.go = 开发者入口，xlib_harness = 自动化后端）

## 架构类型

治理工具 — Go module + scripts，驱动 spec-lint、traceability-check、status-consistency-check 等 CI gate
