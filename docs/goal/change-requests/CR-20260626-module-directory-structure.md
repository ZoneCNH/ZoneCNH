# CR-20260626: 模块目录化结构治理规则变更

- **Date**: 2026-06-26
- **Owner**: ZoneCNH
- **Status**: Approved
- **Type**: 治理规则变更（受保护资产）

## Evidence

模块规格制品从扁平文件（`goal.md`、`SPEC.md`、`TRACEABILITY.md` 等散落在模块根目录）升级为管线层级目录化结构，对齐 Goal 驱动交付体系的 11 层管线模型。

## Impact

### 受影响的 SSOT 文件（已同步）

| 文件 | 变更内容 |
|------|---------|
| `AGENTS.md` | "模块级 Goal 文档命名规则" → "模块目录结构规则"；定义 10 层目录结构 |
| `docs/goal/README.md` | 同步表格行 + 模块级目录结构说明 |
| `module/README.md` | Goal 文档路径 `goal.md` → `goal/goal.md`；目录化结构说明 |
| `module/AGENTS.md` | 移除 `goal/` 目录禁止陷阱项；更新注意项 |
| `docs/goal/00-authority-map.md` | §4 配置边界表新增 10 行模块目录，澄清模块级 vs `.config/goal/` SSOT 边界 |
| `.config/goal/schema/rules.yaml` | `canonical_path_pattern` → `module/{module}/goal/goal.md`；移除 `goal/` 目录禁止，保留多文件槽位禁止 |

### 模块目录结构（最终确定）

```text
module/{module}/
├── goal/          ← Goal 层：目标定义（goal.md）
├── spec/          ← Spec 层：需求规格（SPEC.md）
├── design/        ← Design 层：设计方案（DESIGN.md）
├── plan/          ← Plan 层：执行计划（PLAN.md）
├── tasks/         ← Tasks 层：任务清单
├── prompt/        ← Prompt 层：Context Package
├── matrix/        ← Matrix：模块级追溯视图
├── gate/          ← Gate：模块级门禁定义与检查清单
├── evidence/      ← Evidence：模块级交付证据
└── registry/      ← Registry：模块级注册投影
```

### `.config/goal/` 控制面边界（不变）

`.config/goal/` 仍为 Registry、Matrix canonical edge、Gate 状态、Evidence Bundle 和 Pipeline 状态的跨模块控制面 SSOT。模块级 `matrix/`、`gate/`、`evidence/`、`registry/` 为本地投影。

## Proposed Patch

1. 更新 6 个 SSOT 文件（已完成）
2. 以 `module/binance` 为首个目标模块，创建目录化结构并迁移现有文件
3. 后续按需迁移其他模块

## Validation Command

```bash
bash docs/goal/tools/goal-workflow.sh validate
```

## Rollback Plan

恢复 6 个 SSOT 文件的旧版本（git revert），移除模块目录结构，恢复扁平文件。

## Approval Requirement

Human Approval（受保护资产变更：AGENTS.md、docs/goal/README.md、module/README.md、module/AGENTS.md、docs/goal/00-authority-map.md、.config/goal/schema/rules.yaml）
