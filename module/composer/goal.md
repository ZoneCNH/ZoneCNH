# composer Goal

| 字段 | 值 |
| --- | --- |
| 模块 | `composer` |
| 层级 | 入口 · 组合根（Composition Root） |
| 仓库 | <https://github.com/ZoneCNH/composer> |
| 当前版本 | v0.1.0 |
| 目标版本 | v0.2.0 |
| 状态 | Draft — 占位规格，完整 23 节 SPEC 待进入 Spec-Code 管线时补齐 |
| 最后更新 | 2026-06-29 |

## 目标

`composer` 是整个系统的运行时组合根（Composition Root）。读取配置、创建依赖、连接模块、管理生命周期，编排数据域->分析域->决策域->执行域的全链路 25 进程。composer 只做组装，不承载业务语义。

## 非目标

- 不实现因子计算（-> factor_engine）
- 不实现信号生成（-> signal_factory）
- 不实现风控判断（-> riskx）
- 不实现订单路由（-> orderx）
- composer 只做组装，不参与业务链路计算

## 核心组件

| 组件 | 职责 |
| --- | --- |
| RegimeCoordinator | dispatch->regime->engine->signal_factory 全链路状态协调 |
| SinkPort 适配器 | MarketRegimeSink / MacroRegimeSink（域间事件接收） |
| Docker Compose | 25 进程编排与服务发现 |
| HTTP health | 健康检查与就绪探针 |

## 当前阻塞

| 优先级 | 阻塞项 | 处理方向 |
| --- | --- | --- |
| P0 | SPEC 仍为 Draft 占位规格 | 补齐 23 节完整 SPEC |
| P0 | composer 与 bootstrap 职责边界 | 明确进程组装 vs 编排分工 |
| P1 | 25 进程清单与依赖拓扑 | 完整登记所有进程和依赖关系 |
| P2 | 无 TRACEABILITY 矩阵 | SPEC 补全后创建 |
