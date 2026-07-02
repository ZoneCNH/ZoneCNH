# 架构

> ⚠️ **内容已迁移** → [`docs/architecture/`](./docs/architecture/)
>
> 本文件保留为向后兼容存根，所有链接与引用可继续使用。

---

## 快速跳转

| 子文档 | 内容 |
| ------ | ---- |
| [分层架构总览](./docs/architecture/01-overview.md) | 代码依赖拓扑、业务流、运行时组装、域间关系 |
| [域层级定义](./docs/architecture/02-domain-layers.md) | 基座 / L2.5 / 数据域 / 分析域 / 决策域 / 执行域 / 入口 / 横切 |
| [模块边界](./docs/architecture/03-boundaries.md) | 域间关系、依赖守卫表、禁止依赖边 |
| [设计原则](./docs/architecture/04-principles.md) | 13 条不变量 P1-P13 |
| [Foundation 详解](./docs/architecture/05-foundation.md) | 基座 20 模块规格、依赖矩阵、边界职责 |
| [数据流架构](./docs/architecture/06-dataflow.md) | 数据域 → L2.5 → 分析域 → 决策域 → 执行域全景 |
| [三引擎规格](./docs/architecture/07-three-engines.md) | market_engine(→S) / macro_engine(→M) / regime_engine + M×S 矩阵 |
| [契约固化清单](./docs/architecture/08-contracts.md) | P0-P2 契约优先级、三引擎实现路径 |
| [ADR 目录](./docs/architecture/adr/) | 架构决策记录 |

> 📊 实时状态与成熟度 → **[STATUS.md](./STATUS.md)**（公开投影，机器事实源 `.foundationx/status/index.json`、`.foundationx/blockers.json`）
>
> release/factory 投影以机器事实源为准；domainx 归入 L2.5 锚点；factory-grade 见 `.foundationx/status/index.json` summary。
>
> 🗺️ 交付路线图 → **[ROADMAP.md](./ROADMAP.md)**
>
> 📦 模块规格索引 → **[module/README.md](./module/README.md)**
