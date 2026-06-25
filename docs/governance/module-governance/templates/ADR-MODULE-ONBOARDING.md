# ADR-MODULE-ONBOARDING-NNN: [模块名] 准入决策

> 状态：[Proposed | Accepted | Rejected | Superseded by ADR-XXX]
> 日期：YYYY-MM-DD
> 决策者：[姓名/团队]
> 关联：[相关 issue、spec 或文档链接]
> 模板来源：[`module-governance/templates/ADR-MODULE-ONBOARDING.md`](ADR-MODULE-ONBOARDING.md)（基于 [`module/ADR-TEMPLATE.md`](../../../../module/ADR-TEMPLATE.md)）

> 本 ADR 是新模块加入本仓库索引的门禁产物。通过后模块进入 `proposed` 生命周期。准入流程详见 [`06-module-onboarding.md`](../06-module-onboarding.md)。

---

## 1. 问题陈述

[为什么需要这个新模块？描述当前状态、面临的问题或机会。]

- 当前的技术或架构约束：
- 触发决策的事件或需求：
- 相关的利益方和影响范围：

---

## 2. 奥卡姆剃刀三条件（必答）

> 来源：[`CONSTITUTION.md` §2.5](../../../../docs/constitution/02-module-boundaries.md) 模块增殖约束。三条件全部满足才可新增模块。

### 2.1 必要性

> 不新增该模块会导致什么问题？

- [必答] 若不新增，现有架构如何承担该职责？有什么代价？

### 2.2 唯一性

> 现有模块能否承担该职责？为何不能复用/扩展？

- [必答] 逐个评估可复用的现有模块，说明为何不能复用：

| 现有模块 | 为何不能复用 |
| --- | --- |
| ... | ... |

### 2.3 净收益

> 新增带来的收益是否 > 模块增殖成本（维护/认知/依赖复杂度）？

- [必答] 收益：
- [必答] 成本（维护 + 认知 + 依赖复杂度）：
- [必答] 净收益判断：

---

## 3. 边界声明

> 来源：[`CONSTITUTION.md` §2.1](../../../../docs/constitution/02-module-boundaries.md)。拥有/不拥有须完整声明。

### 3.1 拥有（该模块负责的职责）

- [必答] FR 级别职责列表：

### 3.2 不拥有（明确排除的职责 + 委派方）

- [必答] 排除的职责 + 委派给哪个模块：

| 排除职责 | 委派方 |
| --- | --- |
| ... | ... |

---

## 4. 依赖审查

> 来源：[`CONSTITUTION.md` §3](../../../../docs/constitution/03-dependency-direction.md) 依赖方向。

### 4.1 依赖方向

- [必答] 该模块依赖哪些模块？（须单向下行）

| 依赖目标 | 层级 | 方向合规？ |
| --- | --- | --- |
| ... | ... | ✅/❌ |

### 4.2 禁止依赖检查

- [必答] 该模块是否出现在 §3.4 禁止依赖矩阵中？若是，论证例外：
- [必答] 是否形成循环依赖？（须为否）

### 4.3 登记计划

- [必答] 该模块将登记到 `FOUNDATION-DEPS.yaml`（基座/L2.5）还是业务域依赖矩阵（[08](../08-business-domain-deps.md)）？

---

## 5. 命名审批

> 来源：[`CONSTITUTION.md` §7.2](../../../../docs/constitution/07-naming-conventions.md) 模块命名模式。

### 5.1 命名模式匹配

- [必答] 模块名：
- [必答] 匹配的 §7.2 模式（`<name>x` / `domain-<name>` / `<exchange>` / 其他）：
- [必答] snake_case 仓库命名合规？（AGENTS.md 强制规则）
- [必答] 例外情况（x.go / binance.rs）？（若无写"无"）

### 5.2 重命名检查

- [必答] 是否与已删除的历史模块名冲突？（查 registry.yaml archived 条目）

---

## 6. 架构类型选择

> 来源：[`06-module-onboarding.md`](../06-module-onboarding.md) §3。

- [必答] arch_type（library / cs_module / independent_process / cli / contract）：
- [必答] 选择理由：
- [必答] 对应目录模板（`module/_template/` / `module/data_cs_module/` / `module/data_independent_process/`）：
- [若 cs_module] boundary-gates 要求（见 [`boundary-gates-cross-module-promotion.md`](../../boundary-gates-cross-module-promotion.md)）：

---

## 7. 替代方案

### 方案 A：不新增模块（复用/扩展现有）

[描述]

- 优点：
- 缺点：
- 未选择原因：

### 方案 B：[其他方案]

[描述]

- 优点：
- 缺点：
- 未选择原因：

---

## 8. 后果

### 正面影响

-

### 负面影响

-

### 风险与缓解

| 风险 | 概率 | 影响 | 缓解措施 |
| --- | --- | --- | --- |
| ... | 高/中/低 | 高/中/低 | ... |

---

## 9. 实施计划

| 里程碑 | 目标 | 验收 |
| --- | --- | --- |
| 创建 SPEC.md Draft | 23 节结构完整 | spec-lint pass |
| registry.yaml 登记 | lifecycle=proposed | registry 条目存在 |
| SPEC Approved | arbiter pass | SPEC Status=Approved |
| 首次 CI pass | 模块仓 main CI 绿 | CI 链接 |
| 首次 release | L3 Release Done | GitHub Release 链接 |
| proposed→active 毕业 | registry lifecycle=active | [02](../02-module-lifecycle.md) §4.1 门禁通过 |

---

## 10. 约束

- [约束 1]
- [约束 2]

---

## 11. 参考

- [`MODULE-GOVERNANCE.md`](../../MODULE-GOVERNANCE.md)
- [`06-module-onboarding.md`](../06-module-onboarding.md) 准入流程
- [`01-module-registry.md`](../01-module-registry.md) 注册表 schema
- [`CONSTITUTION.md` §2.5](../../../../docs/constitution/02-module-boundaries.md) 奥卡姆剃刀
- [`CONSTITUTION.md` §3](../../../../docs/constitution/03-dependency-direction.md) 依赖方向
- [`CONSTITUTION.md` §7.2](../../../../docs/constitution/07-naming-conventions.md) 命名模式
