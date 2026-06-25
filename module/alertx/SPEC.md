# alertx 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-26
- Layer: 横切 · 告警
- Version: v0.1.0-draft
- Repository: [github.com/ZoneCNH/alertx](https://github.com/ZoneCNH/alertx)
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/observex`, `module/contracts`

> 占位规格（Draft）。alertx 是告警引擎，属横切层。架构类型为独立进程。完整 23 节规格待进入 Spec→Code 管线时补齐。

---

## 1. 摘要

`module/alertx` 是横切层的告警引擎，订阅 observex 的指标/日志/追踪事件与业务域的状态变更，按规则评估并触发告警（去重、分级、路由到通知渠道）。alertx 是横切关注点，不属于任何业务域。

```text
observex (metrics/logs/traces) + 业务域状态事件
  ↓
module/alertx (规则评估 + 去重 + 分级)
  ↓
通知渠道（webhook / email / pagerduty）
```

---

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 告警规则定义与评估、告警去重与抑制、告警分级（critical/warning/info）、通知路由、告警生命周期管理 |
| Depends on | `module/observex`（指标/日志/追踪数据源）、`module/contracts`（事件契约）、基座层 |
| Consumed by | 运维/监控（告警通知）、各业务域（订阅自身健康状态） |
| Excludes | 指标采集与导出（→ observex）、业务决策（alertx 只告警不决策）、自动修复（→ 各模块自身弹性策略） |

> 边界约束来源：[`docs/architecture/03-boundaries.md`](../../docs/architecture/03-boundaries.md) §横切边界（"observex/alertx：指标、追踪、日志、告警事件"）。

---

## 3. 与 observex 的边界

alertx 与 observex 同属横切层，但职责分离：

| 模块 | 职责 | 数据流 |
| --- | --- | --- |
| observex | 指标/日志/追踪的采集、脱敏、导出 | 生产者 → observex → exporter |
| alertx | 告警规则评估、去重、通知 | observex 输出 → alertx → 通知渠道 |

---

## Open Questions

- [ ] alertx 是订阅 observex 还是直接订阅业务事件（或两者）？
- [ ] 告警规则的定义方式（配置文件 DSL / 代码规则 / 矩阵）？
- [ ] 完整 23 节规格进入 Spec→Code 管线的优先级？
