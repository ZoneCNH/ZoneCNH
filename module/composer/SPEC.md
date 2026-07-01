# composer 规格

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-30
- Layer: 入口 · 组合根
- Version: v0.2.0
- Repository: [github.com/ZoneCNH/composer](https://github.com/ZoneCNH/composer)
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/bootstrap`, `module/configx`, `module/observex`

> 占位规格（Draft）。composer 是运行时组合根（Composition Root），负责 25 进程编排、HTTP health、Docker Compose 与 RegimeCoordinator（dispatch→regime→engine→signal_factory 全链路）。架构类型为独立进程。完整 23 节规格待进入 Spec→Code 管线时补齐。

---

## 1. 摘要

`module/composer` 是整个系统的运行时组合根（Composition Root）。它读取配置、创建依赖、连接模块、管理生命周期，编排数据域→分析域→决策域→执行域的全链路进程。composer 只做组装，不承载业务语义。

```text
配置加载 → composer.Build()
  ↓
编排 25 进程：market_data → factor_engine → regime_engine → signal_factory → riskx → orderx
  ↓
HTTP health + Docker Compose + RegimeCoordinator
```

---

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | 进程编排、依赖注入与生命周期管理、配置加载与分发、HTTP health endpoint、Docker Compose 编排、RegimeCoordinator 全链路协调 |
| Depends on | `module/bootstrap`（进程组装）、基座层（configx/observex/resiliencx）、各业务域模块的 wiring 接口 |
| Consumed by | 运维/部署（Docker Compose 启动）、监控系统（health endpoint） |
| Excludes | 因子计算（→ factor_engine）、信号生成（→ signal_factory）、风控判断（→ riskx）、订单路由（→ orderx）——composer 只做组装，不参与业务链路计算 |

> 边界约束来源：[`docs/architecture/03-boundaries.md`](../../docs/architecture/03-boundaries.md) §依赖守卫表 composer 行（"入口包只出现 wiring / lifecycle 测试"）。

---

## 3. 核心组件（占位）

| 组件 | 职责 |
| --- | --- |
| RegimeCoordinator | dispatch→regime→engine→signal_factory 全链路状态协调 |
| SinkPort 适配器 | MarketRegimeSink / MacroRegimeSink（域间事件接收） |
| Docker Compose | 25 进程编排与服务发现 |
| HTTP health | 健康检查与就绪探针 |

---

## Appendix A: Open Questions

- [ ] composer 与 bootstrap 的职责边界（bootstrap=进程组装、composer=编排）是否完全清晰？
- [ ] 25 进程清单与依赖拓扑的完整登记？
- [ ] 完整 23 节规格进入 Spec→Code 管线的优先级？
