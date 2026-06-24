# 🏗️ 架构文档中心

> FoundationX 量化交易基础设施架构文档索引
>
> 原根目录 `DATAFLOW.md` 的内容已并入此目录；`ARCHITECTURE.md` 保留兼容入口。活跃事实层请以 `01-overview.md` 与 `08-contracts.md` 为准。
>
> 权威机器事实源：`.foundationx/status/index.json` + `.foundationx/blockers.json`

---

## 文档列表

| 文档 | 内容摘要 |
| ---- | -------- |
| [01-overview.md](./01-overview.md) | 架构视图：代码依赖拓扑、业务流与反馈、运行时组装 |
| [02-domain-layers.md](./02-domain-layers.md) | 业务域模块化决策、命名约定（X 后缀）、各域说明 |
| [03-boundaries.md](./03-boundaries.md) | 边界与接口职责、域间关系、依赖守卫表、契约固化优先级 |
| [04-principles.md](./04-principles.md) | 14 条核心设计原则、进度校准标准（5%→100% 定义） |
| [05-foundation.md](./05-foundation.md) | Foundation 规格投影、第一阶段闭环、依赖矩阵、状态总览、建议实现顺序 |
| [06-dataflow.md](./06-dataflow.md) | 历史投影 / 兼容层：全景数据流 ASCII 全图（保留 market_engine / macro_engine / regime_engine 历史名） |
| [07-three-engines.md](./07-three-engines.md) | 历史投影 / 兼容层：三引擎详细规格（market_engine(S) / macro_engine(M) / regime_engine(DecisionCard)） |
| [08-contracts.md](./08-contracts.md) | 契约固化清单（P0/P1/P2）、三引擎实现路径 |
| [adr/](./adr/) | 架构决策记录（ADR）索引 |

---

## 快速导航

### 依赖关系
```text
x.go（治理/工具 CLI）→ composer（Composition Root）→ 基座(L0/L1) → L2.5(域共享) → 数据域 → 分析域 ↔ 决策域 → 执行域
```
→ 详见 [01-overview.md](./01-overview.md)

### 三引擎数据流
```text
market_data → market_engine → S State ─┐
macro_data  → macro_engine  → M State  ├─► regime_engine → DecisionCard
```
> 注：上图保留 market_engine / macro_engine / regime_engine 历史投影名；活跃事实链路见 [01-overview.md](./01-overview.md)、[README.md](../README.md) 与 [08-contracts.md](./08-contracts.md)。[06-dataflow.md](./06-dataflow.md) / [07-three-engines.md](./07-three-engines.md) 仅作投影与迁移对照。
→ 详见 [06-dataflow.md](./06-dataflow.md) · [07-three-engines.md](./07-three-engines.md)

### Foundation 状态
- 21/21 Release ✅ · 20/21 Factory ✅ · 0 Open Blockers
→ 详见 [05-foundation.md](./05-foundation.md)

### 设计原则（14 条）
→ 详见 [04-principles.md](./04-principles.md)

---

## 相关文档

| 文档 | 说明 |
| ---- | ---- |
| [`/ROADMAP.md`](../../ROADMAP.md) | 六阶段交付路线图 |
| [`/STATUS.md`](../../STATUS.md) | 项目状态监控（release/factory 权威来源） |
| [`/CONSTITUTION.md`](../../CONSTITUTION.md) | 系统宪法（AI 代理最高治理文件） |
| [`/GLOSSARY.md`](../../GLOSSARY.md) | 术语表 |
| [`/module/README.md`](../../module/README.md) | 模块规格库索引 |
| [`/docs/governance/`](../governance/) | Spec 治理规范 |
