# 03 模块负责人机制 — Module Ownership

- Module-Version: v1.1.0
- Last-Updated: 2026-07-10
- 上级：[MODULE-GOVERNANCE.md](../MODULE-GOVERNANCE.md)
- 关联：[`.github/CODEOWNERS`](../../../.github/CODEOWNERS)、[`SPEC-TEMPLATE.md`](../SPEC-TEMPLATE.md) §1 Metadata Owner

> 本专题定义模块负责人（owner）的登记、CODEOWNERS 细分与交接规则，闭合"Owner 字段形同虚设、CODEOWNERS 未按模块细分"缺口。

---

## §1 缺口与目标

**初始缺口**：SPEC.md Metadata 的 `Owner:` 字段未与 registry 稳定同步；CODEOWNERS 未按模块路径细分；`.foundationx/status/index.json` 无 owner 字段；无 owner 登记/变更/交接规则。

**目标**：以 registry.yaml `owner` 字段为治理负责方 SSOT，逐步细化 CODEOWNERS 审查委托，并与仓库托管 owner 和 Go module identity 分离。

---

## §2 owner 字段语义

### §2.1 owner 值层级【软】

owner 字段允许三类值，优先级从高到低：

| 类型 | 格式 | 适用场景 |
| --- | --- | --- |
| 个人 | `@github-username` | 模块有明确个人负责人 |
| 团队 | `@github/team-slug` | 团队负责 |
| 组织 | `xhyperium` / `ZoneCNH` | 组织承担治理责任；不要求与 `repo` 中的托管 owner 相同 |

### §2.2 当前过渡期【软】

registry 当前同时存在 `xhyperium` 与 `ZoneCNH` 组织级治理 owner。托管到 `xhyperium` 的基座/L2.5 模块保留 `owner: xhyperium` 的治理意图；由于当前没有可用的 xhyperium GitHub team，CODEOWNERS 暂委托 `@ZoneCNH` 执行审查。

1. **Phase 1**（当前）：组织级 owner 可为 `xhyperium` 或 `ZoneCNH`；SPEC Owner 必须与 registry 一致
2. **Phase 2**（后续）：活跃模块（active/maintained）逐步指定可用的个人/团队 owner，并同步 CODEOWNERS
3. **Phase 3**（目标）：全部 active 模块有可直接触达的具体 owner/team

> 组织级 owner 与 CODEOWNERS 委托不同：委托 `@ZoneCNH` 不表示 registry owner 回退为 `ZoneCNH`。

### §2.3 与其他身份的边界【硬】

- `registry.repo` 的 GitHub owner 是托管路由，不是治理 owner。
- `FOUNDATION-DEPS.yaml modules.*.path` 与 runtime `go.mod` 是 Go module identity，仓库 transfer 不得自动改写。
- `.github/CODEOWNERS` 是审查委托；委托人可以在 owner 没有可用 GitHub team 时代为请求审查，但不改变 registry owner SSOT。

### §2.4 owner 职责【软】

模块 owner 负责：
- SPEC 变更的最终批准（或委托）
- 依赖变更审查（FOUNDATION-DEPS 涉及该模块时）
- release 账本维护（[04](04-module-release-ledger.md)）
- 退役决策发起或响应
- 健康度红区的 remediation 响应（[05](05-module-health.md)）

---

## §3 CODEOWNERS 按模块细分

### §3.1 目标布局【软】

`.github/CODEOWNERS` 应按模块路径细分，每模块至少一行可用审查人/团队：

```
# 模块规格
module/kernel/spec/SPEC.md           @owner-kernel
module/configx/spec/SPEC.md          @owner-configx
module/binance/spec/SPEC.md     @owner-binance
# ...
```

### §3.2 过渡期规则【硬】

1. `module/*/spec/SPEC.md` 全部由至少一个可用 GitHub 审查人/团队覆盖
2. registry owner 没有可用 GitHub team 时，必须在 CODEOWNERS 显式记录 review delegate；当前 `owner=xhyperium` 的模块委托 `@ZoneCNH`
3. registry.yaml owner 字段细化为可用个人/团队后，CODEOWNERS 同步细化对应行
4. 禁止 CODEOWNERS 出现 registry.yaml 未登记的模块路径

### §3.3 治理文件 CODEOWNERS【硬】

`docs/governance/module-governance/**` 和 `module/registry.yaml` 须由 `@ZoneCNH` 覆盖（治理文件，组织级审查）。

---

## §4 owner 变更与交接

### §4.1 owner 变更流程【硬】

owner 变更（个人/团队/组织间）须：

1. 提 PR 更新 registry.yaml `owner` 字段
2. 同步更新 SPEC.md Metadata Owner（投影）
3. 同步更新 CODEOWNERS 对应行，或在 owner 无可用 GitHub team 时明确 review delegate
4. PR 描述附：变更理由 + 新 owner 确认（评论或 commit co-author）

### §4.2 交接检查清单【软】

owner 交接时建议完成：
- [ ] 新 owner 确认接收
- [ ] 交接模块当前状态（lifecycle / 健康度 / open blockers）
- [ ] 交接进行中的 SPEC 变更 / PR
- [ ] 更新 registry + SPEC + CODEOWNERS

### §4.3 owner 缺位兜底【硬】

若 owner 字段为空或 owner 不活跃（无响应 ≥30 天）：

1. 保留 registry 中已确认的组织级 owner，禁止仅因 CODEOWNERS team 缺失自动改写 owner
2. CODEOWNERS 回退到已登记的可用 review delegate（当前为 `@ZoneCNH`）
3. 治理审计标记该模块为"owner 联络人缺位"
4. 健康度 `dependency_health` 维度扣分（[05](05-module-health.md)）
5. 如确需更换治理 owner，按 §4.1 完成显式交接，不得以委托变更代替

---

## §5 与 SPEC.md Metadata Owner 的关系

**规则【硬】**：registry.yaml `owner` 是 SSOT；SPEC.md Metadata `Owner:` 是投影。

- 新建 SPEC.md 时，Owner 字段从 registry.yaml 复制
- registry owner 变更时，对应 SPEC.md Owner 须同 PR 同步
- SPEC.md Owner 与 registry.yaml owner 不一致时，以 registry.yaml 为准，SPEC.md 须修正
- CODEOWNERS review delegate 不投影到 SPEC Owner；SPEC Owner 始终投影 registry owner

---

## §6 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-07-10 | v1.1.0 | 明确 `xhyperium` 治理 owner、`@ZoneCNH` 审查委托与 repo/Go module identity 分离 | ZoneCNH |
| 2026-06-25 | v1.0.0 | 首次定义 owner 字词语义、CODEOWNERS 细分规则、交接流程与缺位兜底 | ZoneCNH |
