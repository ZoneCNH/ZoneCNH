# ADR-006: L2.5 领域共享层设计

> 状态：Accepted
> 日期：2026-06-25
> 决策者：ZoneCNH
> 关联：ARCHITECTURE.md, module/FOUNDATION-DEPS.yaml

---

## 背景

数据域、分析域、决策域、执行域均需 Price/Qty/Tick/Quote/MacroPoint 等领域值对象。若各域各自定义，会导致类型不兼容、重复代码、维护成本高。

---

## 决策

新增 L2.5 领域共享层，包含 5 个纯值对象库：

1. `decimalx` — 高精度十进制（Decimal/Price/Qty/Ratio/Money）
2. `domainx` — 领域共享值对象（Order/Position/Trade/Portfolio/ExecutionReport）
3. `domain_market` — 市场数据域模型（Tick/Quote/Bar + canonical 类型）
4. `domain_macro` — 宏观经济域模型（MacroPoint/MacroState）
5. `domain_exchange` — 交易域模型（VenueAdapter 13 方法接口）

---

## 替代方案

### 方案 A：各域自定义

- 优点：无跨域依赖
- 缺点：类型不兼容、重复代码
- 未选择：维护成本高

### 方案 B：放入 contracts

- 优点：集中管理
- 缺点：contracts 职责膨胀，违反"只定义跨域稳定契约"原则
- 未选择：职责边界模糊

---

## 后果

### 正面影响

- 5/5 已发布 v1.0.0+，factory grade
- 上层统一依赖，避免重复定义
- live/soak N/A（纯值对象库，无运行时服务）

### 负面影响

- L2.5 层变更需同步多域
- 新增依赖层增加复杂度

### 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
| --- | --- | --- | --- |
| L2.5 膨胀 | 低 | 中 | 仅放多域共享值对象 |

---

## 实施计划

| 里程碑 | 目标 | 验收 |
| --- | --- | --- |
| Phase 0 | 5 模块创建 + 发布 | ✅ 完成（v1.0.0+） |
| Phase 1 | 上游依赖切换 | ✅ 完成 |

---

## 参考

- ARCHITECTURE.md §L2.5
- module/FOUNDATION-DEPS.yaml
