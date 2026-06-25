# 06 新模块准入流程 — Module Onboarding

- Module-Version: v1.0.0
- Last-Updated: 2026-06-25
- 上级：[MODULE-GOVERNANCE.md](../MODULE-GOVERNANCE.md)
- 关联：[`docs/constitution/02-module-boundaries.md`](../../constitution/02-module-boundaries.md) §2.1/§2.5、[`docs/constitution/03-dependency-direction.md`](../../constitution/03-dependency-direction.md) §3、[`docs/constitution/07-naming-conventions.md`](../../constitution/07-naming-conventions.md) §7.2、[`DEFINITION-OF-READY.md`](../DEFINITION-OF-READY.md)
- 模板：[`templates/ADR-MODULE-ONBOARDING.md`](templates/ADR-MODULE-ONBOARDING.md)

> 本专题将宪法 §2.5 奥卡姆剃刀三条件操作化为新模块准入流程门禁，闭合"§2.5 有原则无流程、无立项 ADR"缺口。

---

## §1 缺口与目标

**缺口**：CONSTITUTION §2.5 有模块增殖约束（必要性/唯一性/净收益三条件）但无配套准入流程；新建模块散落在"复制 SPEC-TEMPLATE + 选模板"操作层面，无立项 ADR、边界论证、依赖审查、命名审批门禁；DEFINITION-OF-READY 是 Spec 进入开发的条件，不是新模块准入条件。

**目标**：定义准入五步流程，每步有明确门禁与产物，§2.5 三条件转化为 ADR 必答项。

---

## §2 准入五步流程

```
Step 1: 立项 ADR
  ↓ 门禁：ADR Accepted
Step 2: 边界论证（§2.1 拥有/不拥有）
  ↓ 门禁：边界声明完整
Step 3: 依赖审查（§3 拓扑）
  ↓ 门禁：依赖方向合规
Step 4: 命名审批（§7.2 模式）
  ↓ 门禁：命名匹配模式
Step 5: 初始登记（registry + SPEC Draft）
  ↓ 门禁：registry lifecycle=proposed
```

### §2.1 Step 1 — 立项 ADR【硬】

新建模块须先提准入 ADR（模板见 [`templates/ADR-MODULE-ONBOARDING.md`](templates/ADR-MODULE-ONBOARDING.md)），包含：

1. **问题陈述**：为什么需要新模块？现有模块为何不能满足？
2. **奥卡姆三条件必答**（§2.5 操作化）：
   - 必要性：不新增该模块会导致什么问题？
   - 唯一性：现有模块能否承担该职责？为何不能复用/扩展？
   - 净收益：新增带来的收益是否 > 模块增殖成本（维护/认知/依赖复杂度）？
3. **替代方案**：至少 2 个（含"不新增"方案）
4. **架构类型选择**（见 §3）

**门禁**：ADR 状态须达 `Accepted`。未提 ADR 或 ADR 未 Accepted 不得进入 Step 2。

### §2.2 Step 2 — 边界论证【硬】

按宪法 §2.1，SPEC.md 须声明"拥有/不拥有"：

- **拥有**：该模块负责的职责（FR 级别）
- **不拥有**：明确排除的职责 + 委派方（命名具体模块）

**门禁**：边界声明须完整（拥有 + 不拥有 + 委派方），缺一不可。边界违规判定矩阵见 §2.2。

### §2.3 Step 3 — 依赖审查【硬】

按宪法 §3 拓扑规则审查新模块依赖：

1. 依赖方向须单向下行（§3.2）
2. 不得形成循环依赖（§3.2）
3. 须登记到 FOUNDATION-DEPS.yaml（基座/L2.5 模块）或在业务域依赖矩阵中声明（[08](08-business-domain-deps.md)）
4. 禁止依赖矩阵检查（§3.4）

**门禁**：依赖方向合规，无禁止依赖。

### §2.4 Step 4 — 命名审批【硬】

按宪法 §7.2 命名模式审批：

| 模式 | 适用 | 示例 |
| --- | --- | --- |
| `<name>x` | 基座扩展 | redisx, configx |
| `domain-<name>` | L2.5 领域模型 | domain_market |
| `<name>-engine` | 分析引擎（决策/执行域已淘汰） | — |
| `<exchange>` | 数据域采集器 | binance, okx |

**门禁**：模块名匹配 §7.2 模式；snake_case 仓库命名（AGENTS.md 强制规则）；例外仅 x.go / binance.rs。

### §2.5 Step 5 — 初始登记【硬】

通过 Step 1-4 后，初始登记：

1. 创建 `module/{module}/SPEC.md`（至少 Draft，使用 [`SPEC-TEMPLATE.md`](../SPEC-TEMPLATE.md)）
2. 在 `module/registry.yaml` 新增条目，`lifecycle: proposed`（见 [01](01-module-registry.md) §4.1）
3. 选架构类型对应模板创建目录结构（见 §3）

**门禁**：registry.yaml 条目存在 + SPEC.md 至少 Draft。

---

## §3 架构类型选择

| arch_type | 适用场景 | 目录模板 | 产物要求 |
| --- | --- | --- | --- |
| `library` | Go 库模块（基座/L2.5/业务域库） | `module/_template/` | SPEC + TRACEABILITY |
| `cs_module` | C/S 进程模块（数据域采集器） | `module/data_cs_module/` | SPEC + client/ + server/ + BOUNDARY-GATES + RUNTIME-MAPPING |
| `independent_process` | 独立进程（分析/聚合） | `module/data_independent_process/` | SPEC + 部署配置 |
| `cli` | CLI 工具 | 无固定模板 | SPEC + 命令文档 |
| `contract` | 契约定义 | 无固定模板 | SPEC + 接口定义 |

**规则【硬】**：arch_type 须在 ADR 中声明并论证；cs_module 须额外满足 [`boundary-gates-cross-module-promotion.md`](../boundary-gates-cross-module-promotion.md) 的边界门禁要求。

---

## §4 proposed → active 毕业门禁

模块登记为 `proposed` 后，须满足以下条件才可转 `active`（见 [02](02-module-lifecycle.md) §2）：

### §4.1 毕业条件【硬】

1. **SPEC Approved**：SPEC.md Status 达 `Approved`（经 arbiter pass 翻转，见 `LIFECYCLE.md`）
2. **首次实现 CI pass**：模块代码仓 main 分支 CI 全绿
3. **首次 release**：达成 L3 Release Done（§18），至少一个 GitHub Release
4. **registry 同步**：registry.yaml `lifecycle` 翻转为 `active`，`release` 块填充

### §4.2 毕业流程【硬】

1. 提 PR：registry.yaml lifecycle `proposed → active` + release 块填充
2. PR 描述附：SPEC Approved 证据 + CI pass 链接 + release 链接
3. 合入后模块正式 `active`

### §4.3 长期 proposed 处理【软】

模块停留在 proposed 超过 90 天无进展 → 治理审计评估：
- 继续推进：更新 ADR 时间线
- 撤销：删除 registry 条目 + 清理 SPEC.md（[02](02-module-lifecycle.md) §3.3）

---

## §5 与 DEFINITION-OF-READY 的关系

| 门禁 | 层级 | 时机 |
| --- | --- | --- |
| 准入流程（本专题） | 模块级 | 新模块加入本仓库索引前 |
| DEFINITION-OF-READY | Spec 级 | 准入通过后，SPEC 进入开发前 |

**规则【硬】**：准入通过是 DoR 的前置条件。未通过准入的模块不得进入 DoR 流程。

---

## §6 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-25 | v1.0.0 | 首次定义准入五步流程、奥卡姆三条件操作化、架构类型选择与毕业门禁 | ZoneCNH |
