# xlib_evidence Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `xlib_evidence` |
| 层级 | 基座 · 治理工具 |
| 仓库 | <https://github.com/ZoneCNH/xlib_evidence> |
| 状态 | Approved |

## 目标

`xlib_evidence` 提供 FoundationX 证据收集与验证能力：CI artifact 取证、四源评分证据归档、release gate 证据链闭合。作为 `xlib_standard` 的证据层，确保所有模块发布有可审计的机器事实支撑。

## 非目标

- 不替代 CI pipeline 本身（只消费 CI 产物）
- 不实现评分逻辑（→ matrix-structural-score / pipeline-arbiter）

## 架构类型

治理工具 — Go module，消费 CI artifacts、STATUS.md 投影、`.foundationx/status/index.json`
