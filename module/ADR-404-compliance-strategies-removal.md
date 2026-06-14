# ADR-003: strategies 404 合规删除

> 状态：Accepted
> 日期：2026-06-15
> 决策者：ZoneCNH (audit session)
> 关联：PR #393; CLAUDE.md §模块-仓库强制对应

---

## 背景

`https://github.com/ZoneCNH/strategies` 返回 HTTP 404。CLAUDE.md 规定：文档中的 GitHub 链接禁止指向 404。strategies 此前在 STATUS.md、ARCHITECTURE.md、README.md 中被引用为决策域模块（60% 进度，3.5MB/746 项）。

三文档审计中发现该仓库不存在，违反 no-404 规则。

---

## 决策

**strategies 全文件删除，不保留纯文本引用或"已移除"标注。**

删除范围：
- STATUS.md 决策域组件表行
- ARCHITECTURE.md 状态总览表行 + 各域说明表枚举
- README.md 决策域链路条目 + ASCII 图引用
- ROADMAP.md 任务项（标记为已完成并注明原因）
- FOUNDATION-DEPS.yaml 依赖条目
- 风险清单 R6
- 所有间接引用（域健康度、仪表盘、同步检查表）

---

## 替代方案

### 方案 A：保留纯文本（不链接）

将 `[strategies](...)` 改为纯文本 `strategies`，保留描述但移除链接。

- 未选择原因：纯文本引用仍会误导读者以为仓库存在。保留描述无实际价值（60% 进度的判断依据是仓库内容，仓库不存在则进度不可信）。

### 方案 B：标注"已移除"

在原有位置标注"（已移除，404）"。

- 未选择原因：增加维护负担（所有后续审计都需解释该标注）。删除是最简洁的合规路径。

---

## 后果

### 正面

- 三文档 0 404，满足 CLAUDE.md 强制约束
- 决策域 7→6，所有关联计数自动一致
- audit-status.py check 5 永久监控新 strategies 引用

### 负面

- 丢失了"60% 进度参考库"的历史记录
- ROADMAP 原定 strategies 定位梳理任务取消

### 风险

| 风险 | 概率 | 影响 | 缓解 |
|------|:---:|:---:|------|
| strategies 仓库日后创建，需重新添加 | 低 | 低 | 按模块新增流程，需同步三文档 + DEPS + ROADMAP |
| 审计闭合后有人误加 strategies 引用 | 低 | 低 | audit-status.py check 5 检出 |

---

## 约束

- 不删除 `strategyx`（合法仓库，名称相似但独立）
- ROADMAP 已勾销任务保留为已完成状态

---

## 参考

- CLAUDE.md §模块-仓库强制对应
- PR #393, #395, #419
- `docs/solutions/three-doc-audit-20260615-ISA.md` §11
