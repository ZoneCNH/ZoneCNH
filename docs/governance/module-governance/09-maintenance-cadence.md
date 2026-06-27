# 模块治理维护节奏

- Module-Governance-Topic: 09
- Last-Updated: 2026-06-27
- Status: Active
- Related-Beads: `ZoneCNH-wbyc`

本专题定义模块治理体系的季度维护节奏，用于避免 registry、生命周期、owner、release、health 与 dependency 投影长期漂移。

## §1 季度维护窗口【软】

每季度至少执行一次模块治理复盘。复盘范围覆盖：

| 检查项 | 权威来源 | 输出 |
| --- | --- | --- |
| 模块登记完整性 | `module/registry.yaml` | 缺失/重复/路径漂移清单 |
| 生命周期状态 | `02-module-lifecycle.md` + registry `lifecycle` | 需推进或降级的模块列表 |
| Owner 有效性 | `03-module-ownership.md` + CODEOWNERS | 未登记、无备份、需交接项 |
| Release 投影 | `04-module-release-ledger.md` + goal releases registry | 版本/发布日期/发布证据漂移 |
| 健康度阈值 | `05-module-health.md` | 红线、黄线、豁免与整改项 |
| 依赖矩阵 | `FOUNDATION-DEPS.yaml` + `08-business-domain-deps.md` | 新增边、禁止边、未登记边 |

## §2 复盘输出【硬】

季度复盘必须产出一个 review 记录，使用 [`templates/MODULE-GOVERNANCE-REVIEW.md`](templates/MODULE-GOVERNANCE-REVIEW.md)。

最小字段：

| 字段 | 要求 |
| --- | --- |
| Review-Date | 实际复盘日期 |
| Scope | 覆盖模块或模块集合 |
| Findings | 按 registry/lifecycle/owner/release/health/deps 分类 |
| Required Follow-ups | 后续 issue、ADR、PR 或显式无需行动 |
| Evidence | 执行过的命令、检查结果或人工审查依据 |

## §3 复盘关闭规则【硬】

季度复盘项可以关闭的条件：

1. 发现项均已转化为明确 issue、ADR、PR、豁免或无需行动记录。
2. 不得把“复盘已记录”写成“运行时生产证据已完成”。
3. 若复盘需要 commit/PR/merge，但当前会话禁止 git 操作，则复盘项只能标记为 blocked，不得关闭提交类任务。

## §4 与模块等级的关系【软】

L2/L3 模块的季度复盘必须额外检查 [`10-governance-levels.md`](10-governance-levels.md) 中的等级义务；L1 模块可使用轻量复盘，但仍需保留结论记录。
