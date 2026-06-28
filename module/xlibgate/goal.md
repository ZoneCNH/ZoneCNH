# xlibgate Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `xlibgate` |
| 层级 | 基座 · 治理门禁 |
| 仓库 | <https://github.com/ZoneCNH/xlibgate> |
| 状态 | Approved |

## 目标

`xlibgate` 提供 FoundationX 治理门禁检查能力：Secret 扫描（gitleaks 集成）、依赖边界检查、覆盖率门禁、fleet-status 投影生成。作为 CI pipeline 的关键门禁节点，确保所有模块发布前通过治理基线。

## 非目标

- 不实现评分逻辑（→ pipeline-arbiter / matrix-structural-score）
- 不替代 xlib_harness（harness = 管线调度，xlibgate = 门禁执行）

## 架构类型

治理工具 — Go module，驱动 `fleet-status` 生成 `.foundationx/status/index.json`，执行边界/安全/覆盖率门禁
