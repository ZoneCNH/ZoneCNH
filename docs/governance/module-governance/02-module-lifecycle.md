# 02 模块生命周期 — Module Lifecycle

- Module-Version: v1.0.0
- Last-Updated: 2026-06-25
- 上级：[MODULE-GOVERNANCE.md](../MODULE-GOVERNANCE.md)
- 关联：[`LIFECYCLE.md`](../LIFECYCLE.md)（Spec 六态）、[`docs/constitution/18-artifact-completion.md`](../../constitution/18-artifact-completion.md)（制品完成层级）

> 本专题定义**模块本身**（作为可独立发布单元）的生命周期状态机，区别于 `LIFECYCLE.md` 管的 Spec 文档状态机。

---

## §1 缺口与目标

**缺口**：只有 Spec 六态（Draft→Review→Approved→Implemented→Changed→Deprecated），无模块自身的状态枚举。模块作为可发布单元没有 proposed→active→maintained→deprecated→archived 状态定义与流转门禁。STATUS.md 的成熟度维度是评估投影，不是治理状态机。

**目标**：定义模块级五态状态机，与 Spec 六态映射，驱动 registry.yaml `lifecycle` 字段。

---

## §2 五态定义

| 状态 | 含义 | 进入条件 | 退出条件 |
| --- | --- | --- | --- |
| `proposed` | 已通过准入 ADR，SPEC 处 Draft/Review，尚未首次 release | 准入 ADR Accepted（[06](06-module-onboarding.md)） | SPEC Approved + 首次 CI pass |
| `active` | 首次 release 已发布，正在积极开发 | proposed 毕业门禁通过 | 标记 maintained 或 deprecated |
| `maintained` | 功能稳定，仅维护性变更（bugfix/security），无新功能 | 维护者主动标记 | 重新激活或 deprecated |
| `deprecated` | 已废弃，禁止新增依赖；进入退役迁移期 | 退役 ADR Accepted（[07](07-module-decommission.md)） | 迁移完成 → archived |
| `archived` | 代码仓已 archive，registry 保留历史条目 | 退役完成 | 终态，不流转 |

---

## §3 合法流转表

```
proposed ──毕业──▶ active ◀──重新激活── maintained
                      │                      │
                      └──deprecated◀─────────┘
                            │
                            ▼
                        archived（终态）
```

### §3.1 合法流转【硬】

| 起点 → 终点 | 触发 | 门禁 |
| --- | --- | --- |
| proposed → active | 准入毕业 | SPEC Approved + 首次实现 CI pass + registry 同步 |
| active → maintained | 维护者主动标记 | PR 说明理由；无阻塞 blocker |
| maintained → active | 重新激活 | PR 说明理由；SPEC 未 Deprecated |
| active → deprecated | 退役 ADR | 退役 ADR Accepted + 迁移指南 + 下游通知 |
| maintained → deprecated | 退役 ADR | 同上 |
| deprecated → archived | 退役完成 | 迁移期结束 + 下游迁移验证 + 代码仓 archive |

### §3.2 禁止流转【硬】

| 流转 | 原因 |
| --- | --- |
| archived → 任何 | archived 是终态，代码仓已 archive |
| proposed → deprecated | 跳过 active 直接废弃不合理；应先毕业或直接撤销（删除 registry 条目） |
| active → archived | 跳过 deprecated 迁移期会破坏下游消费者 |
| 任何 → proposed | 不可逆降级；新模块走准入流程新建条目 |

### §3.3 proposed 模块的撤销【软】

proposed 模块若决定不推进，可直接删除 registry 条目（不走退役流程），但须在删除 PR 说明理由并清理已创建的 SPEC.md。

---

## §4 与 Spec 生命周期（六态）的映射

模块态（本体系）与 Spec 态（`LIFECYCLE.md`）是**两个粒度**，模块态驱动 Spec 态：

| 模块 lifecycle | 允许的 SPEC Status | 说明 |
| --- | --- | --- |
| proposed | Draft / Review / Approved | SPEC 可先于模块毕业 |
| active | Approved / Implemented / Changed | SPEC 须至少 Approved |
| maintained | Implemented / Changed | 仅维护性变更 |
| deprecated | Deprecated | 模块废弃 → SPEC 强制 Deprecated |
| archived | Deprecated | 终态；SPEC 保留为历史 |

**规则【硬】**：模块转 `deprecated` 时，同 PR 将 SPEC Status 改为 `Deprecated`。模块 `archived` 时 SPEC 保持 `Deprecated`（不删除，保留历史）。

---

## §5 与制品完成层级（§18 L1-L4 Done）的关系

宪法 §18 定义四级 Done（L1 Code Done / L2 Test Done / L3 Release Done / L4 Goal Done）。模块 lifecycle 与 Done 层级的关系：

| 模块 lifecycle | 最低 Done 要求 |
| --- | --- |
| proposed | 无（开发中） |
| active | L3 Release Done（首次 release 已发布） |
| maintained | L3 Release Done（维护性 release） |
| deprecated | 最后一次 release 须 L3 Release Done |
| archived | 不要求（已停止） |

**规则【硬】**：模块 `active` 须至少达成一次 L3 Release Done；proposed→active 毕业门禁含此检查。

---

## §6 registry.yaml lifecycle 字段同步

### §6.1 同步义务【硬】

lifecycle 变更须同 PR 更新：
1. `module/registry.yaml` 的 `lifecycle` 字段
2. `module/{module}/spec/SPEC.md` Metadata Status（若涉及 deprecated）
3. `module/README.md` 投影（标注状态）
4. 退役类变更额外同步 FOUNDATION-DEPS / .foundationx/status / CODEOWNERS（见 [07](07-module-decommission.md) §5）

### §6.2 lifecycle 字段校验【开】

registry.yaml 的 lifecycle 值须在本专题 §2 五态枚举内；非法值视为治理违规。

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-25 | v1.0.0 | 首次定义模块五态状态机、流转门禁、与 Spec 六态和 §18 Done 的映射 | ZoneCNH |
