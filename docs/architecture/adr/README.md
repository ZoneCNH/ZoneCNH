# 📋 架构决策记录（ADR）索引

> ADR 源文件位于 `module/` 目录，本文件提供集中导航入口。
>
> ADR 模板：[`module/ADR-TEMPLATE.md`](../../../module/ADR-TEMPLATE.md)

---

## 已记录的 ADR

| 编号 | 标题 | 状态 | 文件 |
| ---- | ---- | ---- | ---- |
| ADR-001 | foundationx 兼容退出计划 | Accepted | [module/ADR-foundationx-exit.md](../../../module/ADR-foundationx-exit.md) |
| ADR-002 | domainx 基础层归属 | Accepted | [module/ADR-domainx-base-attribution.md](../../../module/ADR-domainx-base-attribution.md) |
| ADR-003 | 版本计数包含 Draft | Accepted | [module/ADR-version-count-includes-draft.md](../../../module/ADR-version-count-includes-draft.md) |
| ADR-004 | 预防门禁：Block 而非 Warn | Accepted | [module/ADR-prevention-gates-block-not-warn.md](../../../module/ADR-prevention-gates-block-not-warn.md) |
| ADR-005 | 404 合规策略移除 | Accepted | [module/ADR-404-compliance-strategies-removal.md](../../../module/ADR-404-compliance-strategies-removal.md) |

---

## 新增 ADR 流程

1. 复制 `module/ADR-TEMPLATE.md`
2. 命名为 `module/ADR-{kebab-slug}.md`
3. 填写 Context / Decision / Consequences
4. 在本索引添加一行
5. 通过 PR 合入 main
