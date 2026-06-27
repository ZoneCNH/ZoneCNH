# 季度治理剪枝审计

- Module-Version: v1.0.0
- Last-Updated: 2026-06-27
- Scope: `docs/governance/`、`module/*/` 规格制品、模块治理模板与投影文档
- Cadence: quarterly

## §1 目标

`[COMPUTED, HIGH]` 本专题定义 R9 文档存在性之后的长期维护机制：保留有用文档，合并重复文档，归档过时文档，防止 governance 文档无限增长。

`[COMPUTED, HIGH]` 剪枝审计只处理文档治理状态，不直接删除 runtime 代码，不关闭需要 live/production evidence 的 issue。

## §2 审计对象

| 对象 | 示例 | 审计重点 |
| --- | --- | --- |
| governance 总纲 | `docs/governance/MODULE-GOVERNANCE.md` | 是否仍为索引与效力入口 |
| governance 专题 | `docs/governance/module-governance/*.md` | 是否被索引引用，是否有重复专题 |
| 模块规格 | `module/{module}/spec/SPEC.md` | 是否与 lifecycle/registry 状态一致 |
| 模块 gate | `module/{module}/gate/*.md` | 是否与 runtime gate script 对齐 |
| evidence | `module/{module}/evidence/YYYY-MM-DD/` | 是否可复核、可脱敏、可追溯 issue |
| templates | `docs/governance/module-governance/templates/*.md` | 是否仍被新模块复用 |

## §3 触发条件

季度审计每 90 天至少运行一次；任一条件成立时也可提前触发：

1. 同一主题出现两个以上并行治理文档。
2. 文档 90 天以上无引用、无更新、无 owner。
3. issue 关闭依赖的证据路径发生迁移。
4. 模块 lifecycle 进入 deprecated 或 archived。
5. runtime gate 数量变化但 governance 文档未同步。

## §4 判定动作

| 动作 | 使用条件 | 要求 |
| --- | --- | --- |
| keep | 文档仍被引用且内容有效 | 更新 Last-Updated 仅在实质变更时执行 |
| merge | 多文档表达同一规则 | 保留一个入口，旧文档改为指针或归档 |
| archive | 历史证据或旧决策仍有审计价值 | 移入 archive 或 evidence，保留来源与日期 |
| decommission | 文档不再适用且无引用 | 需要 owner 批准；不得静默删除 |

## §5 审计步骤

1. 列出目标范围：

```bash
rg --files docs/governance module | sort
```

2. 查找引用：

```bash
rg -n "目标文件名|目标主题" docs module README.md
```

3. 查找最近更新：

```bash
git log --follow --date=short --pretty=format:'%ad %h %s' -- path/to/file
```

4. 对每个候选文档记录：`keep` / `merge` / `archive` / `decommission`、依据、owner、后续 issue。
5. 对涉及 issue 关闭的文档，确认对应 evidence 文件仍存在且内容可复核。

## §6 审计记录模板

```markdown
# Quarterly Governance Pruning Audit — YYYY-QN

- Date:
- Auditor:
- Scope:
- Related Issues:

| Path | Action | Evidence | Owner | Follow-up |
| --- | --- | --- | --- | --- |
| docs/... | keep/merge/archive/decommission | rg/git log/evidence path | owner | issue id |

## Decision Notes

- ...
```

## §7 安全边界

1. 不得因为文档无引用就直接删除；先归档或建立替代入口。
2. 不得删除 issue 关闭证据。
3. 不得把 Evidence-Pending 改为 Evidence-Done。
4. 不得把 runtime 仓的代码/测试结果复制进本仓作为源码。
5. 不得在 runtime 仓 `module/` 目录新增 spec 制品。

## §8 当前闭环

`[COMPUTED, HIGH]` 2026-06-27 起，季度剪枝机制以本专题为 durable 入口，后续审计记录应落在 `module/{module}/evidence/YYYY-MM-DD/review/` 或 governance 专题索引明确指向的位置。
