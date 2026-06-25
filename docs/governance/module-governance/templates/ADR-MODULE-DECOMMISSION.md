# ADR-MODULE-DECOMMISSION-NNN: [模块名] 退役决策

> 状态：[Proposed | Accepted | Rejected | Superseded by ADR-XXX]
> 日期：YYYY-MM-DD
> 决策者：[姓名/团队]
> 关联：[相关 issue、spec 或文档链接]
> 模板来源：[`module-governance/templates/ADR-MODULE-DECOMMISSION.md`](ADR-MODULE-DECOMMISSION.md)（基于 [`module/ADR-TEMPLATE.md`](../../../../module/ADR-TEMPLATE.md)）

> 本 ADR 是模块退役/合并/拆分/重命名的门禁产物。通过后模块进入 `deprecated` 生命周期。退役流程详见 [`07-module-decommission.md`](../07-module-decommission.md)。

---

## 1. 退役类型

> 来源：[`07-module-decommission.md`](../07-module-decommission.md) §2。勾选一项。

- [ ] 废弃（deprecate）：模块不再维护，进入迁移期后 archive
- [ ] 合并：职责并入另一模块
- [ ] 拆分：拆为多个新模块
- [ ] 重命名：模块改名

---

## 2. 退役理由

[为什么退役？]

- 技术债：
- 职责重叠（与哪些模块重叠）：
- 替代方案（迁移到哪个模块/接口）：
- 不再需要（业务下线）：

---

## 3. 下游消费者影响分析

> 来源：[`07-module-decommission.md`](../07-module-decommission.md) §3.2。

### 3.1 下游清单

[必答] 列出全部依赖该模块的下游：

| 下游模块/消费者 | 依赖方式（go.mod / 事件 / API） | 迁移工作量 |
| --- | --- | --- |
| ... | ... | 高/中/低 |

### 3.2 影响评估

- [必答] 影响范围（单模块 / 跨域 / 跨仓库）：
- [必答] 是否有生产环境依赖？
- [必答] 是否有外部消费者（非本组织仓库）？

---

## 4. 迁移方案

### 4.1 替代方案

[必答] 迁移目标（模块/接口）：

### 4.2 迁移步骤

[必答] 下游迁移的代码/配置/数据改动：

1.
2.
3.

### 4.3 迁移指南位置

[必答] 迁移指南发布位置（`module/{module}/MIGRATION.md` 或 `docs/migrations/{module}-retirement.md`）：

---

## 5. 迁移期

> 来源：[`CONSTITUTION.md` §10.3](../../../../docs/constitution/10-change-management.md) Breaking Change 流程 + [`07-module-decommission.md`](../07-module-decommission.md) §3.4。

- [必答] deprecated 日期：
- [必答] 迁移期长度（≥1 MINOR）：
- [必答] 预计 archived 日期：
- [必答] 兼容期承诺（deprecated 期间保留但不再新增功能）：

---

## 6. archive vs delete 决策

> 来源：[`07-module-decommission.md`](../07-module-decommission.md) §4。

### 6.1 决策

- [ ] archive（默认；保留历史 + 可回溯）
- [ ] delete（仅占位模块：无 release 无下游；须论证）

### 6.2 论证（若选 delete）

[必答，若选 delete] 论证为何可物理删除：
- 曾发布 release？须为否
- 有下游曾依赖？须为否
- 法律/合规要求？

---

## 7. 后果

### 正面影响

-

### 负面影响

-

### 风险与缓解

| 风险 | 概率 | 影响 | 缓解措施 |
| --- | --- | --- | --- |
| 下游未及时迁移 | 高/中/低 | 高/中/低 | 迁移期 + 通知 + 验证 |
| ... | ... | ... | ... |

---

## 8. 同步检查清单

> 来源：[`07-module-decommission.md`](../07-module-decommission.md) §5。退役完成时须全部确认。

- [ ] `module/registry.yaml` lifecycle=archived
- [ ] `module/{module}/SPEC.md` Status=Deprecated
- [ ] `module/{module}/MIGRATION.md` 已发布
- [ ] `module/FOUNDATION-DEPS.yaml` 从 modules 段移除（若曾登记）
- [ ] `.foundationx/status/index.json` 标记 archived
- [ ] `.github/CODEOWNERS` 移除该模块路径规则（若已细分）
- [ ] `module/README.md` 标注"已归档"
- [ ] `README.md`（根）移除或标注
- [ ] `STATUS.md` 标注退役
- [ ] 代码仓 GitHub archived

---

## 9. 实施计划

| 里程碑 | 目标 | 验收 |
| --- | --- | --- |
| 退役 ADR Accepted | 本 ADR 状态=Accepted | ADR 状态翻转 |
| lifecycle→deprecated | registry + SPEC 同步 | [02](../02-module-lifecycle.md) §3.1 门禁 |
| 迁移指南发布 | MIGRATION.md 存在 | 文档评审通过 |
| 迁移期结束 | ≥1 MINOR 过去 | git tag 历史 |
| 下游迁移验证 | 全部下游已迁移/确认无影响 | §3.1 清单全部 ✅ |
| 代码仓 archive | GitHub archived | 仓库 archived 状态 |
| registry→archived | 同步检查清单全部 ✅ | [07](../07-module-decommission.md) §5 |

---

## 10. 约束

- [约束 1]
- [约束 2]

---

## 11. 参考

- [`MODULE-GOVERNANCE.md`](../../MODULE-GOVERNANCE.md)
- [`07-module-decommission.md`](../07-module-decommission.md) 退役流程
- [`02-module-lifecycle.md`](../02-module-lifecycle.md) 生命周期状态机
- [`CONSTITUTION.md` §10.3](../../../../docs/constitution/10-change-management.md) Breaking Change 流程
- [`LIFECYCLE.md` §6.4](../../LIFECYCLE.md) 废弃 Spec
