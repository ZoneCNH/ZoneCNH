# 架构审计未完成项 Issue 索引

> 来源：`docs/report/architecture-structural-analysis-20260625-v1.md` 路线图 12 项盘点
> 创建：2026-06-25
> 10 项未完成，已拆解为 beads issues + GitHub issues 双轨跟踪

## Issue 清单

| # | GitHub Issue | 优先级 | 主题 | beads ID | 类别 |
|---|---|:---:|---|---|---|
| 1 | [#1086](https://github.com/ZoneCNH/ZoneCNH/issues/1086) | P0 | 业务域 tasks=0/17 管线 S3-S6 空跑 | ZoneCNH-ao3 | 中期 |
| 2 | [#1087](https://github.com/ZoneCNH/ZoneCNH/issues/1087) | P0 | 管线 S4-S6 补洞 plan4%/prompt10%/evidence4% | ZoneCNH-qy8 | 中期 |
| 3 | [#1088](https://github.com/ZoneCNH/ZoneCNH/issues/1088) | P0 | 报告 rebase 遗留未对齐 1429→1454 | ZoneCNH-a1t | 短期残留 |
| 4 | [#1089](https://github.com/ZoneCNH/ZoneCNH/issues/1089) | P1 | 事实层 generated_at 仍06-17 需fleet-status迁移 | ZoneCNH-gke | 短期残留 |
| 5 | [#1090](https://github.com/ZoneCNH/ZoneCNH/issues/1090) | P1 | 5模块TRACEABILITY §4 TC Status 22处⬜待归档 | ZoneCNH-jrw | 短期残留 |
| 6 | [#1091](https://github.com/ZoneCNH/ZoneCNH/issues/1091) | P1 | 6模块存根SPEC补全至23节完整结构 | ZoneCNH-4jw | 中期 |
| 7 | [#1092](https://github.com/ZoneCNH/ZoneCNH/issues/1092) | P1 | ADR补录 6/73→≥10 关键架构决策 | ZoneCNH-2cn | 中期 |
| 8 | [#1093](https://github.com/ZoneCNH/ZoneCNH/issues/1093) | P2 | 核心交易闭环跑通 live_integration 7→15+ | ZoneCNH-8lb | 长期 |
| 9 | [#1094](https://github.com/ZoneCNH/ZoneCNH/issues/1094) | P2 | 管线右段CI gate 缺plan/prompt/evidence阻断 | ZoneCNH-ehk | 长期 |
| 10 | [#1095](https://github.com/ZoneCNH/ZoneCNH/issues/1095) | P2 | 投影层机器生成 业务域补入index.json | ZoneCNH-n3h | 长期 |

## 依赖关系

```text
#1088 报告对齐（独立可做）
#1089 generated_at 刷新（独立可做）
#1090 TC evidence 归档（依赖外部仓库 CI）
#1091 存根SPEC补全（独立可做）
#1092 ADR补录（独立可做）
  │
  ├─► #1086 业务域 tasks 拆分（依赖 #1091 存根SPEC补全）
  │     │
  │     ├─► #1087 管线 S4-S6 补洞（依赖 #1086 tasks）
  │     │     │
  │     │     └─► #1094 管线右段 CI gate（依赖 #1087）
  │     │
  │     └─► #1093 核心交易闭环（依赖 #1086 + #1087）
  │
  └─► #1095 投影层机器生成（独立可做，但受益于 #1086 后业务域有事实源）
```

## 优先级说明

- **P0（3 项）**：#1086 #1087 #1088 — 核心链路解锁 + 报告对齐
- **P1（4 项）**：#1089 #1090 #1091 #1092 — 短期残留 + 中期补全
- **P2（3 项）**：#1093 #1094 #1095 — 长期实现推进

## 验证

10 轮检查（bd list × gh issue list 交叉核对）：**10/10 PASS**，无遗漏。
