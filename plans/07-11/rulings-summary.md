# 治理裁决汇总

**生成日期**: 2026-07-11
**来源分析**: `/home/workspace/ZoneCNH/report/07-11/07-11-analysis.md`
**裁决者**: FoundationX Governance

---

## 裁决总览

| 编号       | 裁决主题               | 状态    | 裁决结果              | 关联工作包                | 分析来源           |
| ---------- | ---------------------- | ------- | --------------------- | ------------------------- | ------------------ |
| RULING-001 | goalcli 归属           | FINAL   | 并入 xlib_harness     | XLS-002, XLG-001, XLH-009 | §2.2 矛盾 1, §P0-1 |
| RULING-002 | transportx module path | FINAL   | `/v1` (无 `/v2` 后缀) | TRN-001                   | §2.2 矛盾 2, §P0-2 |
| RULING-003 | contracts 版本         | PENDING | 等待 lineage 审计     | CTR-001                   | §2.2 矛盾 3, §P0-3 |

## 裁决文件

| 裁决编号   | 文件路径                                       |
| ---------- | ---------------------------------------------- |
| RULING-001 | [`ruling-goalcli.md`](ruling-goalcli.md)       |
| RULING-002 | [`ruling-transportx.md`](ruling-transportx.md) |
| RULING-003 | [`ruling-contracts.md`](ruling-contracts.md)   |

## 状态说明

- **FINAL**: 裁决已确定，进入实施阶段。回退仅可在满足裁决文档中定义的回退条件时触发。
- **PENDING**: 等待前置条件（lineage 审计）完成后给出最终裁决。此状态下不可作为生产决策依据。

## 下一步行动

| 行动                                     | 负责人                  | 依赖       |
| ---------------------------------------- | ----------------------- | ---------- |
| 创建 xlib_harness OWNERSHIP-GOALCLI.yaml | xlib_harness maintainer | RULING-001 |
| 新增 XLH-009 工作包                      | pipeline-coordinator    | RULING-001 |
| 批量更新 21 agent prompt goalcli 引用    | pipeline-coordinator    | RULING-001 |
| 修改 transportx go.mod module path       | transportx maintainer   | RULING-002 |
| 执行 contracts-lineage-audit.sh          | contracts maintainer    | RULING-003 |
| 根据审计结果更新 RULING-003              | FoundationX Governance  | 审计完成   |
