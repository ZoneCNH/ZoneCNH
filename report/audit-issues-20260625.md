# 架构审计未完成项 Issue 状态总表

> 来源：`report/architecture-structural-analysis-20260625-v1.md` 路线图 12 项
> 创建：2026-06-25（PR #1096 索引）；更新：2026-06-25（PR #1098 修复落地后对齐）
> 10 项未完成 → 9 项已关闭 + 1 项长期 open

## 状态总表

| # | GitHub | 优先级 | 主题 | 状态 | 修复 PR |
|---|---|:---:|---|---|---|
| 1 | #1086 | P0 | 业务域 tasks=0/17 | ✅ Closed | #1098 |
| 2 | #1087 | P0 | 管线 S4-S6 补洞 | ✅ Closed | #1098 |
| 3 | #1088 | P0 | 报告 rebase 遗留未对齐 | ✅ Closed | #1098 |
| 4 | #1089 | P1 | generated_at 刷新 | ✅ Closed | #1098 |
| 5 | #1090 | P1 | TC Status 22处⬜待归档 | ✅ Closed | #1098 |
| 6 | #1091 | P1 | 6模块存根SPEC补全 | ✅ Closed | #1098 |
| 7 | #1092 | P1 | ADR补录 6→≥10 | ✅ Closed | #1098 |
| 8 | #1093 | P2 | 核心交易闭环跑通 | 🟡 Open（长期） | — |
| 9 | #1094 | P2 | 管线右段CI gate | ✅ Closed | #1098 |
| 10 | #1095 | P2 | 投影层机器生成 | ✅ Closed | #1098 |

## 修复落地清单（PR #1098）

| Issue | 修复制品 | 残留 |
|---|---|---|
| #1088 | 报告 1429→1454 + 路线图 5 项✅ | — |
| #1086 | 3 模块 tasks/TASK-*.md | 14 模块仍待拆 |
| #1087 | 3 模块 PLAN.md | S4 覆盖率 4%→10%，仍低 |
| #1089 | audit-status.py 告警（WARN） | generated_at 仍 06-17（schema 迁移待定） |
| #1090 | 5 模块 §4 ⬜→⬜→§8 | 待外部 CI run id 归档后 ✅ |
| #1091 | regime_engine SPEC 87→305 行 | 5 模块仍存根 |
| #1092 | 4 份新 ADR（6→10） | — |
| #1094 | pipeline-right-segment-check.sh | WARN 非阻断，未来升 FAIL |
| #1095 | PROJECTION-AUTOMATION-PLAN.md | 实现阶段 2-3 待实施 |
| #1093 | CORE-LOOP-MILESTONES.md | M1-M4 全 ⬜（依赖跨仓库实现） |

## 验证

- `audit-status.py --network` 52/52 PASS
- 10 轮检查 10/10（每项 fix 制品存在性）
- 9 GitHub issues Closed + 9 beads issues Closed
- #1093 GitHub + beads 均 Open（长期跟踪）
