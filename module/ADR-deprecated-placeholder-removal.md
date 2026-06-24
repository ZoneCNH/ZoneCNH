# ADR-009: 废弃占位移除

> 状态：Accepted
> 日期：2026-06-25
> 决策者：ZoneCNH
> 关联：PR #842, STATUS.md

---

## 背景

module/ 曾有 4 个历史占位模块（`risk_engine`/`order_engine`/`portfolio_engine`/`backtest_engine`），对应新名（riskx/orderx/positionx/backtestx）已创建。占位与新模块并存导致文档需反复标注废弃关系，外部消费者无法判断依赖哪个。

---

## 决策

2026-06-22 通过 PR #842 从 `module/` 物理移除 4 个占位：

1. `risk_engine` → `riskx`
2. `order_engine` → `orderx`
3. `portfolio_engine` → `positionx`（职责更精确——跨账户仓位管理）
4. `backtest_engine` → `backtestx`

决策域 6→5，执行域 7→4，总计 77→73。

---

## 替代方案

### 方案 A：保留占位 + DEPRECATED 标记

- 优点：历史可追溯
- 缺点：SPEC 仍显示 Approved 状态，AI 代理可能基于废弃规格开发
- 未选择：标记未传导至 SPEC 层

---

## 后果

### 正面影响

- 消除命名双轨残留
- 决策域/执行域计数准确
- STATUS.md 多维表保留行作档案标注"已移除"

### 负面影响

- 历史引用可能断链

### 风险与缓解

| 风险 | 概率 | 影响 | 缓解 |
| --- | --- | --- | --- |
| 断链 | 低 | 低 | ARCHITECTURE.md 保留 ~~删除线~~ 标注 |

---

## 实施计划

| 里程碑 | 目标 | 验收 |
| --- | --- | --- |
| PR #842 | 4 占位移除 | ✅ |
| 文档同步 | STATUS/ARCHITECTURE 更新 | ✅ |

---

## 参考

- PR #842
- STATUS.md §历史占位移除说明
