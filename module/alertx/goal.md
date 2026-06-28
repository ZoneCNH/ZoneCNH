# alertx Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `alertx` |
| 层级 | 横切 · 告警与通知 |
| 仓库 | <https://github.com/ZoneCNH/alertx> |
| 当前版本 | v1.0.0-spec |
| 目标版本 | v1.0.0 |
| 状态 | SPEC Approved — FR-001~007 已定义，S8 Code 阶段待实现 |
| 最后更新 | 2026-06-29 |

## 目标

`alertx` 是 Foundation 横切告警与通知模块。加载 YAML DSL 规则，评估输入事件匹配规则产出 AlertEvent，经去重抑制、severity 分级后通过通知渠道（paging/webhook/log）路由分发。支持规则热加载、firing->suppressed->resolved 生命周期状态机和健康导出。

## 非目标

- 不实现监控数据采集（由 observex 负责）
- 不替代 PagerDuty/Opsgenie 等外部告警平台
- 不实现告警聚合/关联分析（单模块职责）
- 不持有业务数据或策略状态

## 核心能力

| 能力 | 说明 |
| --- | --- |
| 规则引擎 | YAML DSL 加载，事件匹配，非法 DSL 阻塞启动 |
| 去重抑制 | DedupKey + SuppressWindow 内抑制重复告警 |
| 分级路由 | critical->paging, warning->通知, info->日志 |
| 通知渠道 | 按 severity 路由，失败退避重试 3 次，通知幂等 |
| 生命周期 | firing->suppressed->resolved 状态机 + pending 抖动窗口 |
| 规则热加载 | 文件变更触发重载，校验通过原子替换，失败保留旧规则 |
| 健康导出 | health.JSON 四字段 + 自观测指标 |

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | S8 Code 阶段所有 FR 状态为 ⏳ | 实现 FR-001~007 全部功能 |
| P1 | 通知渠道集成（webhook/paging） | 确定具体渠道实现 |
| P2 | 集成测试（10k 活跃告警 soak） | SPEC 已定义 NFR 性能基线 |
