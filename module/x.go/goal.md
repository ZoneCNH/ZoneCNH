# x.go Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `x.go` |
| 层级 | 横切 · 治理/工具 CLI |
| 仓库 | <https://github.com/ZoneCNH/x.go> |
| 当前版本 | v0.1.0-draft |
| 目标版本 | v0.1.0 |
| 状态 | Draft — 占位规格，x.go 是开发期工具 CLI |
| 最后更新 | 2026-06-29 |

## 目标

`x.go` 是治理与工具 CLI，提供 goalcli（Goal 驱动交付工作流命令行）与 templatex（模板生成与管理）能力。x.go 是开发期工具，不参与运行时进程组装——运行时 Composition Root 职责由 composer 承担。

## 非目标

- 不参与运行时进程组装（-> composer）
- 不承载业务语义（x.go 是工具，非业务模块）
- 不替代 xlib_harness（生成器/门禁）的职责

## 核心组件

| 组件 | 职责 |
| --- | --- |
| goalcli | Goal 驱动交付工作流命令行（preflight/validate/gate/release/ci） |
| templatex | 模板生成、脚手架、spec-lint 等治理工具 |

## 命名例外

x.go 是仓库命名 snake_case 规则的唯一例外之一（含点号，`CONSTITUTION.md` §7.2）。

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | x.go 是否需要完整 23 节 SPEC？ | 工具文档（README/man page）可能更合适 |
| P1 | goalcli 与 templatex 是否应拆为独立模块？ | 评估独立性 |
| P2 | x.go 与 xlib_harness 职责边界 | 明确 CLI 入口 vs 生成器/门禁 |
