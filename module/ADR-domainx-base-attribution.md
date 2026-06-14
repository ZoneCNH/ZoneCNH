# ADR-002: domainx 归属基座

> 状态：Accepted
> 日期：2026-06-15
> 决策者：ZoneCNH (audit session)
> 关联：PR #392, #388; ARCHITECTURE.md 各域说明表; `docs/solutions/three-doc-audit-20260615-ISA.md`

---

## 背景

domainx 提供执行域共享值对象（Order/Position/Trade/Portfolio/ExecutionReport 枚举与类型），语义上属于 L2.5 领域共享层。在 2026-06-15 三文档审计之前，其归属在三文档中不一致：

- `ARCHITECTURE.md` 各域说明表：列于基座行末尾
- `STATUS.md` 组件明细表：列于 L2.5 段（标题"5 个"）
- `STATUS.md` 按域统计表：L2.5=4（domainx 未计入 L2.5）
- `README.md`：列于 L2.5 段

归属分歧导致三文档中基座和 L2.5 的计数互不一致，同步检查表失效，agent 在编辑时容易引入新的计数漂移。

---

## 决策

**domainx 归入基座，三文档统一。**

1. `STATUS.md` 组件明细表：domainx 从 L2.5 段移至基座段（transportx 之后）
2. `STATUS.md` 按域统计表：基座 19→20，L2.5 5→4
3. `ARCHITECTURE.md`：保持不变（已列于基座行）
4. `README.md`：domainx 从 L2.5 段移至基座契约段，ASCII 图同步
5. 所有标注域计数的描述文本（域健康度、版本注记、同步检查表）同步更新

---

## 替代方案

### 方案 A：domainx 归入 L2.5

将 ARCHITECTURE.md 的 domainx 从基座行移除，归入 L2.5 行，三文档统一为 L2.5=5。

- 优点：与 domainx 的语义定位一致（L2.5 领域共享层）
- 缺点：需改 ARCHITECTURE.md 各域说明表及 ASCII 图；与 ARCH 状态总览表的历史归属冲突
- 未选择原因：ARCHITECTURE.md 是本仓库的架构权威来源。最小改动原则下，让两文档对齐 ARCH 已有的归属比修改 ARCH 更合理。

### 方案 B：domainx 维持双归属（基座管理 + L2.5 语义）

在各文档中标注 domainx 的双重属性，计数时选择一种口径但注明差异。

- 优点：不丢失语义信息
- 缺点：增加文档复杂度；同步检查表和域统计的计数逻辑更复杂；agent 更容易出错
- 未选择原因：三文档审计的根本目标是简化计数路径、消除歧义。双归属方案与目标冲突。

---

## 后果

### 正面影响

- 三文档 L2.5 统一为 4（decimalx, domain-market, domain-exchange, domain-macro），基座统一为 20
- 同步检查表 L2.5 行从 ⚠️ 变为 ✅
- 域统计表、域健康度、仪表盘进度分布等所有引用基座/L2.5 计数的地方自动闭合
- 后续新增领域共享模块有清晰的归属规则：语义属于 L2.5 ⇏ 文档归属必须是 L2.5

### 负面影响

- domainx 在基座组件表中与 kernel、redisx 等基础设施模块并列，初次阅读可能困惑
- 组件表基座行 "执行域共享值对象" 的描述与 "基座" 分类标签存在语义张力

### 风险与缓解

| 风险 | 概率 | 影响 | 缓解措施 |
|------|:---:|:---:|------|
| 后续审计误将 domainx 移回 L2.5 | 中 | 低：单行移动，audit-status.py check 1 检出 | ADR 记录为权威参照 |
| 新增领域共享模块时归属标准不清 | 中 | 中：再次分裂 | 此 ADR 确立规则：核心归属以 ARCHITECTURE.md 各域说明表为准 |

---

## 实施计划

| 里程碑 | 目标 | 验收 |
|--------|------|------|
| PR #392 | STATUS.md 组件表、域统计、版本注记同步 | `grep domainx STATUS.md` 在基座表内 |
| PR #388 | README.md 链路列表 + ASCII 图同步 | `grep domainx README.md` 在 L2.5 段之前 |
| audit | 跨文档一致性 | `python3 scripts/audit-status.py` check 1 全 PASS |

---

## 约束

- 不改变 domainx 仓库的实际代码或 go.mod（仅文档归属调整）
- L2.5 领域共享层的语义定位不变——domainx 之所以例外，是因为 ARCHITECTURE.md 的既有归属

---

## 参考

- `docs/solutions/three-doc-audit-20260615-ISA.md` §11 决策记录
- `ARCHITECTURE.md` §各域说明表（L130）
- PR #392, #388

---

## 后续

- 新增领域共享模块时，先确定 ARCHITECTURE.md 各域说明表的归属，再同步 STATUS.md 和 README.md
- 与 ADR-001 (foundationx-exit) 无直接交互
