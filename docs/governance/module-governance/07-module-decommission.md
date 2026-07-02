# 07 模块退役/迁移流程 — Module Decommission

- Module-Version: v1.0.0
- Last-Updated: 2026-06-25
- 上级：[MODULE-GOVERNANCE.md](../MODULE-GOVERNANCE.md)
- 关联：[`docs/constitution/10-change-management.md`](../../constitution/10-change-management.md) §10.3 Breaking Change、[`LIFECYCLE.md`](../LIFECYCLE.md) §6.4 废弃 Spec
- 模板：[`templates/ADR-MODULE-DECOMMISSION.md`](templates/ADR-MODULE-DECOMMISSION.md)

> 本专题定义模块废弃/合并/拆分/重命名的标准流程，闭合"无 sunset/EOL 流程、仅 4 占位模块删除先例"缺口。

---

## §1 缺口与目标

**缺口**：无模块退役/EOL/合并/拆分/重命名标准流程；唯一先例是 4 个历史占位模块物理删除（无 ADR、无退役检查清单、无迁移指南）；LIFECYCLE §6.4 只管 Spec Status 改 Deprecated，不涉及代码仓 archive/下游通知/迁移。

**目标**：定义退役七步流程 + archive/delete 决策矩阵 + 同步检查清单。

---

## §2 退役类型

| 类型 | 描述 | lifecycle 影响 | 代码仓处理 |
| --- | --- | --- | --- |
| 废弃（deprecate） | 模块不再维护，进入迁移期 | active/maintained → deprecated → archived | 最终 archive |
| 合并 | 模块职责并入另一模块 | 被合并方 → deprecated → archived；接收方正常 | 被合并方 archive |
| 拆分 | 模块拆为多个新模块 | 原模块 → deprecated → archived；新模块走准入 | 原模块 archive |
| 重命名 | 模块改名 | 原名 → archived；新名走准入（或同条目改名） | 视情况 |

---

## §3 退役七步流程

```
Step 1: 退役 ADR
  ↓ 门禁：ADR Accepted
Step 2: 下游消费者影响分析
  ↓ 门禁：影响清单完整
Step 3: 迁移指南
  ↓ 门禁：指南发布
Step 4: 迁移期（≥1 MINOR）
  ↓ 门禁：迁移期结束
Step 5: 下游迁移验证
  ↓ 门禁：下游已迁移或已确认无影响
Step 6: 代码仓 archive
  ↓ 门禁：代码仓 archived
Step 7: registry 归档
  ↓ 门禁：registry lifecycle=archived
```

### §3.1 Step 1 — 退役 ADR【硬】

提退役 ADR（模板见 [`templates/ADR-MODULE-DECOMMISSION.md`](templates/ADR-MODULE-DECOMMISSION.md)），包含：

1. 退役类型（§2）
2. 退役理由（技术债/职责重叠/替代方案/不再需要）
3. 下游影响（哪些模块/消费者依赖该模块）
4. 迁移方案（迁移目标 + 迁移期 + 迁移指南位置）
5. archive/delete 决策（§4）

**门禁**：ADR Accepted。

### §3.2 Step 2 — 下游影响分析【硬】

分析所有依赖该模块的下游：

1. 查 FOUNDATION-DEPS.yaml reverse deps（基座/L2.5）
2. 查业务域依赖（[08](08-business-domain-deps.md)，若已登记）
3. 查 x.go 组合根引用
4. 列出下游清单 + 每个下游的迁移工作量评估

**门禁**：下游清单完整；遗漏下游导致迁移期问题是治理违规。

### §3.3 Step 3 — 迁移指南【硬】

发布迁移指南（`module/{module}/MIGRATION.md` 或 `docs/migrations/{module}-retirement.md`），包含：

1. 退役时间线（deprecated 日期 → 迁移期 → archived 日期）
2. 替代方案（迁移到哪个模块/接口）
3. 迁移步骤（代码改动 + 配置改动 + 数据迁移）
4. 兼容期承诺（deprecated 期间保留但不再新增功能）

### §3.4 Step 4 — 迁移期【硬】

遵循宪法 §10.3 Breaking Change 流程：

1. 标记 `DEPRECATED`（SPEC + 代码）
2. 发布迁移指南
3. **保留至少 1 个 MINOR 版本**的兼容期
4. 兼容期结束后下一个 MAJOR 版本移除

**门禁**：迁移期 ≥1 MINOR；不得跳过迁移期直接移除（破坏下游）。

### §3.5 Step 5 — 下游迁移验证【硬】

迁移期结束前验证：

1. 全部已知下游已迁移到替代方案，或
2. 下游确认无影响（不使用该模块），或
3. 下游拒绝迁移 → 升级处理（协商 / 强制 / 延长迁移期）

**门禁**：全部下游已迁移或已确认无影响。

### §3.6 Step 6 — 代码仓 archive【硬】

1. 模块代码仓 `github.com/ZoneCNH/{module}` 设置 archived（GitHub archive）
2. README 添加归档说明 + 指向迁移指南
3. 禁止后续 push

### §3.7 Step 7 — registry 归档【硬】

1. registry.yaml `lifecycle: archived`
2. SPEC.md Status 保持 `Deprecated`（不删除，保留历史）
3. FOUNDATION-DEPS.yaml：从 `modules` 段移除（若曾登记），在注释中标注归档
4. .foundationx/status：保留条目但标记 archived
5. module/README.md：标注"已归档"

---

## §4 archive vs delete 决策矩阵

| 条件 | archive | delete |
| --- | --- | --- |
| 曾发布 release | ✅ | ❌ |
| 有下游曾依赖 | ✅ | ❌ |
| 仅占位模块（无 release 无下游） | ✅（推荐） | ✅（可） |
| 法律/合规要求删除 | — | ✅ |

**默认【硬】**：退役模块默认 archive（保留历史 + 可回溯）；仅占位模块（无 release 无下游）可物理删除。物理删除须在退役 ADR 中明确论证。

**历史先例**：2026-06-22 物理删除 4 个占位模块（backtest_engine/risk_engine/order_engine/portfolio_engine）属"仅占位"删除，符合本规则。

---

## §5 同步检查清单

退役完成时须确认以下全部同步【硬】：

| 文件 | 同步动作 |
| --- | --- |
| `module/registry.yaml` | lifecycle=archived |
| `module/{module}/spec/SPEC.md` | Status=Deprecated |
| `module/{module}/MIGRATION.md` | 已发布 |
| `module/FOUNDATION-DEPS.yaml` | 从 modules 段移除（若曾登记） |
| `.foundationx/status/index.json` | 标记 archived |
| `.github/CODEOWNERS` | 移除该模块路径规则（若已细分） |
| `module/README.md` | 标注"已归档" |
| `README.md`（根） | 移除或标注（公开投影） |
| `STATUS.md` | 标注退役 |
| 代码仓 | GitHub archived |

---

## §6 与 LIFECYCLE §6.4 的关系

`LIFECYCLE.md` §6.4 "废弃 Spec" 只定义把 SPEC Status 改 Deprecated。本专题在此基础上增加**模块级**退役流程：

| 层级 | 文档 | 动作 |
| --- | --- | --- |
| Spec 级 | LIFECYCLE §6.4 | SPEC Status → Deprecated |
| 模块级（本专题） | 退役七步 | lifecycle → deprecated → archived + 代码仓 archive + 下游通知 |

**规则【硬】**：模块退役时，Spec 级与模块级同步进行；不可只改 Spec Status 而不处理模块仓与下游。

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-25 | v1.0.0 | 首次定义退役七步流程、archive/delete 决策矩阵与同步检查清单 | ZoneCNH |
