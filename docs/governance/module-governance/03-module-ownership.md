# 03 模块负责人机制 — Module Ownership

- Module-Version: v1.0.0
- Last-Updated: 2026-06-25
- 上级：[MODULE-GOVERNANCE.md](../MODULE-GOVERNANCE.md)
- 关联：[`.github/CODEOWNERS`](../../../.github/CODEOWNERS)、[`SPEC-TEMPLATE.md`](../SPEC-TEMPLATE.md) §1 Metadata Owner

> 本专题定义模块负责人（owner）的登记、CODEOWNERS 细分与交接规则，闭合"Owner 字段形同虚设、CODEOWNERS 未按模块细分"缺口。

---

## §1 缺口与目标

**缺口**：SPEC.md Metadata 有 `Owner:` 字段但恒为 `ZoneCNH`（组织名），不是具体负责人；`.github/CODEOWNERS` 仅 5 行粗粒度规则，未按模块路径细分；`.foundationx/status/index.json` 无 owner 字段；无 owner 登记/变更/交接规则。

**目标**：以 registry.yaml `owner` 字段为 SSOT，逐步细化 CODEOWNERS 按模块路径细分，定义交接流程。

---

## §2 owner 字段语义

### §2.1 owner 值层级【软】

owner 字段允许三类值，优先级从高到低：

| 类型 | 格式 | 适用场景 |
| --- | --- | --- |
| 个人 | `@github-username` | 模块有明确个人负责人 |
| 团队 | `@github/team-slug` | 团队负责 |
| 组织 | `ZoneCNH` | 过渡默认；无明确负责人时兜底 |

### §2.2 当前过渡期【软】

当前全部模块 owner 为 `ZoneCNH`（组织默认）。本体系建立后，逐步细化：

1. **Phase 1**（本体系建立）：registry.yaml 记录 `ZoneCNH`，标记为过渡期
2. **Phase 2**（后续）：活跃模块（active/maintained）逐步指定个人/团队 owner
3. **Phase 3**（目标）：全部 active 模块有具体 owner

> 过渡期未指定具体 owner 不构成治理违规；但新增模块准入时建议指定（[06](06-module-onboarding.md) §3）。

### §2.3 owner 职责【软】

模块 owner 负责：
- SPEC 变更的最终批准（或委托）
- 依赖变更审查（FOUNDATION-DEPS 涉及该模块时）
- release 账本维护（[04](04-module-release-ledger.md)）
- 退役决策发起或响应
- 健康度红区的 remediation 响应（[05](05-module-health.md)）

---

## §3 CODEOWNERS 按模块细分

### §3.1 目标布局【软】

`.github/CODEOWNERS` 应按模块路径细分，每模块至少一行：

```
# 模块规格
module/kernel/SPEC.md           @owner-kernel
module/configx/SPEC.md          @owner-configx
module/binance/SPEC.md          @owner-binance
# ...
```

### §3.2 过渡期规则【硬】

过渡期（owner=ZoneCNH）CODEOWNERS 保留现有粗粒度规则，但须满足：

1. `module/*/SPEC.md` 全部由 `@ZoneCNH` 覆盖（现状已满足）
2. registry.yaml owner 字段细化后，CODEOWNERS 同步细化对应行
3. 禁止 CODEOWNERS 出现 registry.yaml 未登记的模块路径

### §3.3 治理文件 CODEOWNERS【硬】

`docs/governance/module-governance/**` 和 `module/registry.yaml` 须由 `@ZoneCNH` 覆盖（治理文件，组织级审查）。

---

## §4 owner 变更与交接

### §4.1 owner 变更流程【硬】

owner 变更（个人/团队/组织间）须：

1. 提 PR 更新 registry.yaml `owner` 字段
2. 同步更新 SPEC.md Metadata Owner（投影）
3. 同步更新 CODEOWNERS 对应行（若已细分）
4. PR 描述附：变更理由 + 新 owner 确认（评论或 commit co-author）

### §4.2 交接检查清单【软】

owner 交接时建议完成：
- [ ] 新 owner 确认接收
- [ ] 交接模块当前状态（lifecycle / 健康度 / open blockers）
- [ ] 交接进行中的 SPEC 变更 / PR
- [ ] 更新 registry + SPEC + CODEOWNERS

### §4.3 owner 缺位兜底【硬】

若 owner 字段为空或 owner 不活跃（无响应 ≥30 天）：

1. registry.yaml owner 回退为 `ZoneCNH`（组织兜底）
2. 治理审计标记该模块为"owner 缺位"
3. 健康度 `dependency_health` 维度扣分（[05](05-module-health.md)）

---

## §5 与 SPEC.md Metadata Owner 的关系

**规则【硬】**：registry.yaml `owner` 是 SSOT；SPEC.md Metadata `Owner:` 是投影。

- 新建 SPEC.md 时，Owner 字段从 registry.yaml 复制
- registry owner 变更时，对应 SPEC.md Owner 须同 PR 同步
- SPEC.md Owner 与 registry.yaml owner 不一致时，以 registry.yaml 为准，SPEC.md 须修正

---

## §6 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-25 | v1.0.0 | 首次定义 owner 字词语义、CODEOWNERS 细分规则、交接流程与缺位兜底 | ZoneCNH |
