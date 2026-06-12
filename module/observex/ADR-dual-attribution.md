# ADR: observex 双重归属（基座 + 横切）

> 架构决策记录（Architecture Decision Record）
> 日期：2026-06-12
> 状态：Accepted
> 决策者：ZoneCNH

---

## 背景

在 ARCHITECTURE.md 中，`observex` 同时出现在两个分类下：

1. **基座层**（第 280 行）：作为 L1 运行时契约组件，提供底层能力
2. **横切层**（第 354 行）：可观测性（metrics/tracing/logging）同时归属横切维度

STATUS.md 将此标记为风险 R7：

> R7: observex 双重归属（基座+横切）— 职责边界模糊 — 在代码层面严格界定

---

## 决策

**observex 的逻辑层级为 L1 基座层**，横切是它的**消费属性**而非层级归属。

### 三层归属模型

| 维度 | observex 角色 | 说明 |
|------|-------------|------|
| **层级归属** | L1 基座（运行时横切能力） | 与 configx/resiliencx/schedulex 同级，依赖 L0 kernel |
| **横切属性** | 可被所有层消费 | Logger/Meter/Tracer 是通用能力，消费方不限于特定层 |
| **物理部署** | 按模块独立仓库 | `github.com/ZoneCNH/observex`，独立 go.mod |

### 具体界定

**作为 L1 基座组件的职责**：

- 提供 Logger/Meter/Tracer/Exporter/Health 接口和实现
- 管理自身的配置（observex 配置段）
- 通过 kernel.Deps 注入到其他模块
- 维护同层级的依赖约束（不依赖 redisx/kafkax 等存储扩展）

**作为横切消费属性的表现**：

- 所有层级的模块（L0~存储扩展~业务域）都可以消费 Logger/Meter/Tracer 接口
- 不强制任何模块使用特定的 exporter 实现
- observability 是**能力面**而非层级划分依据

---

## 替代方案

### 方案 A：纯基座归属（推荐 ✅）

- 在 ARCHITECTURE.md 的横切表中移除 observex，仅保留 alertx
- 在基座表中保留 observex，补充注释说明其横切消费属性
- STATUS.md R7 更新为 "已记录 ADR"

### 方案 B：纯横切归属（不推荐 ❌）

- 将 observex 从基座表中移除
- 但 observex 的 L1 架构位置（依赖 kernel、被 configx/resiliencx 依赖）是客观事实，横切定位无法准确描述其层级约束

### 方案 C：保持双重归属（不推荐 ❌）

- 不在文档层面修改
- 代码层面通过 TODO 注释界定
- 问题：每个新贡献者都会困惑，持续消耗解释成本

---

## 后果

### 正面影响

- 消除 STATUS.md R7 风险项
- ARCHITECTURE.md 组件归属更清晰
- 新贡献者不会困惑于"observex 到底在哪一层"

### 负面影响

- 横切表只剩 alertx 一个组件，视觉上单薄
- 需要在横切表下方添加注释说明

### 需要同步的文档

| 文档 | 变更 |
|------|------|
| ARCHITECTURE.md | 横切表移除 observex，保留 alertx；添加注释 |
| STATUS.md | R7 更新为 "已记录 ADR" |
| module/README.md | 无需变更（分层总览中 observex 本就只在 L1 运行时） |

---

## 参考

- [CONSTITUTION.md §1.1](../../CONSTITUTION.md) — P1-P13 设计原则
- [ARCHITECTURE.md](../../ARCHITECTURE.md) — 依赖拓扑和状态表
- [STATUS.md](../../STATUS.md) — 风险登记
- [SPEC.md](./SPEC.md) — 接口定义和依赖约束
