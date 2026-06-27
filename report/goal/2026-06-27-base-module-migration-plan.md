# 基座模块 Goal 驱动交付管线迁移执行方案

> 生成日期：2026-06-27
> 范围：20 个基座（Foundation）模块
> 数据来源：`module/registry.yaml`、`module/FOUNDATION-DEPS.yaml`、`rubric-score.py` 批量评分、文件系统扫描
> 方法：依赖拓扑排序 + 差距分析 + 分批迁移

---

## 一、迁移目标

将 20 个基座模块从当前"平铺目录 + 不完整 SPEC + 无 Goal 管线制品"状态，迁移到 Goal 驱动交付管线标准：

| 维度        | 当前状态                           | 目标状态                                                                     |
| ----------- | ---------------------------------- | ---------------------------------------------------------------------------- |
| 目录结构    | 20/20 平铺                         | 20/20 嵌套（goal/spec/design/plan/tasks/prompt/evidence/matrix/gate/schema） |
| SPEC 质量   | 0/20 通过（composite=0，红线触发） | ≥17/20 通过（composite≥85），≤3 标注暂停                                     |
| Goal 制品   | 0/20 有 goal/goal.md               | 20/20 有 goal/goal.md                                                        |
| Matrix      | 3/20 有 matrix/                    | 20/20 有 matrix/                                                             |
| Gate        | 0/20 有 gate/                      | 20/20 有 gate/                                                               |
| CHANGELOG   | 0/20 有                            | 20/20 有                                                                     |
| CI 工作流   | 15/20 有 ci-workflow.yaml          | 20/20 有                                                                     |
| rubric 评分 | 0/20 PASS                          | ≥17/20 PASS 或 PASS_WITH_RISK                                                |

---

## 二、现状概览

### 2.1 模块清单与依赖拓扑

```
Layer 0（无依赖）:
  kernel, contracts, xlib_standard, xlib_harness, xlib_evidence, xlibgate

Layer 1（依赖 kernel）:
  configx, observex, resiliencx, schedulex
  redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex

Layer 2（依赖 L1）:
  testkitx → kernel + configx + observex + resiliencx + schedulex
  transportx → contracts + configx + observex + resiliencx

Layer 3（依赖 L1+L2）:
  bootstrap → kernel + configx + observex + resiliencx + 全部存储层
```

### 2.2 SPEC 质量分布

| 维度分数 | 模块数 | 模块                                                                                                                       |
| -------- | ------ | -------------------------------------------------------------------------------------------------------------------------- |
| ≥ 90     | 1      | xlib_standard (96)                                                                                                         |
| 80-89    | 12     | observex, schedulex, kafkax, kernel, clickhousex, natsx, transportx, redisx, postgresx, xlib_harness, resiliencx, testkitx |
| 60-79    | 4      | xlib_evidence (75), configx (74), contracts (74), taosx (63)                                                               |
| < 60     | 3      | ossx (38), xlibgate (35), bootstrap (18)                                                                                   |

### 2.3 最普遍缺口

| 缺口                    | 模块数 | 说明                                                         |
| ----------------------- | ------ | ------------------------------------------------------------ |
| 缺 Metadata 章节        | 19/20  | Owner/Repository/Status/Spec-Version 未在 §1 Metadata 中声明 |
| 缺 Open Questions       | 19/20  | §23 Open Questions 章节缺失                                  |
| 缺 Dependencies 章节    | 1/20   | redisx                                                       |
| 缺 Interface/Data Model | 1/20   | taosx                                                        |
| 缺 10+ 章节             | 3/20   | ossx, xlibgate, bootstrap                                    |

### 2.4 目录结构差距

| 制品             | 已有  | 缺失 |
| ---------------- | ----- | ---- |
| goal/ 目录       | 0/20  | 20   |
| spec/ 目录       | 0/20  | 20   |
| design/ 目录     | 0/20  | 20   |
| plan/ 目录       | 1/20  | 19   |
| tasks/ 目录      | 15/20 | 5    |
| prompt/ 目录     | 2/20  | 18   |
| evidence/ 目录   | 0/20  | 20   |
| matrix/ 目录     | 2/20  | 18   |
| gate/ 目录       | 0/20  | 20   |
| schema/ 目录     | 0/20  | 20   |
| CHANGELOG.md     | 0/20  | 20   |
| ci-workflow.yaml | 15/20 | 5    |

---

## 三、分批迁移方案

### 迁移原则

1. **依赖优先**：先迁移被依赖的模块（Layer 0 → 1 → 2 → 3），确保下游迁移时上游制品已就绪
2. **先结构后内容**：先完成目录迁移（flat → nested），再补 SPEC 内容
3. **机械化优先**：Metadata + Open Questions 是批量操作，优先执行
4. **一个模块一个 PR**：每个模块的目录迁移 + SPEC 修复 + 制品创建 = 1 个 PR
5. **评分驱动验收**：每个模块迁移完成后必须通过 `rubric-score.py spec` 验收

### Batch 1：Layer 0 基座（6 模块）

> 依赖：无。这是整个依赖树的根，必须最先迁移。

| 序号 | 模块          | 维度分 | 主要缺口                  | 预计工时 | 优先级 |
| ---- | ------------- | ------ | ------------------------- | -------- | ------ |
| 1.1  | kernel        | 87     | Metadata + Open Questions | 1h       | P0     |
| 1.2  | contracts     | 74     | Open Questions            | 1h       | P0     |
| 1.3  | xlib_standard | 96     | Metadata（红线）          | 0.5h     | P0     |
| 1.4  | xlib_harness  | 81     | Metadata + Open Questions | 1h       | P1     |
| 1.5  | xlib_evidence | 75     | Metadata + Open Questions | 1h       | P1     |
| 1.6  | xlibgate      | 35     | 10+ 章节缺失              | 4h       | P1     |

**每个模块的迁移步骤**：

```
Step 1: 目录迁移（flat → nested）
  mkdir -p goal spec design plan tasks prompt evidence matrix gate schema
  git mv goal.md goal/goal.md        (如存在)
  git mv SPEC.md spec/SPEC.md
  git mv TRACEABILITY.md matrix/TRACEABILITY.md  (如存在)
  git mv PLAN.md plan/PLAN.md        (如存在)
  git mv IMPLEMENTATION-PLAN.md plan/PLAN.md  (如存在)
  git mv ACCEPTANCE.md spec/ACCEPTANCE.md  (如存在)
  git mv FEATURES.md spec/FEATURES.md  (如存在)
  # tasks/ prompt/ plan/ 如已存在则保留

Step 2: SPEC 内容补齐
  - 添加 §1 Metadata（Owner, Repository, Status, Spec-Version, Last-Updated）
  - 添加 §23 Open Questions（即使为空也标注 "当前无开放问题"）
  - 修复其他缺失章节（按 rubric 报告）

Step 3: Goal 制品创建
  - 创建 goal/goal.md（从现有 goal.md 迁移或新建）
  - 创建 matrix/matrix.yaml（从 TRACEABILITY.md 转换或新建）
  - 创建 gate/gate-checklist.md（从 ci-workflow.yaml 提取）

Step 4: 补齐缺失制品
  - 创建 CHANGELOG.md（如不存在）
  - 创建 ci-workflow.yaml（如不存在）
  - 创建 design/DESIGN.md（占位，标注 "TBD"）
  - 创建 schema/ 目录（占位）

Step 5: 验收
  - rubric-score.py spec module/{mod}/spec/SPEC.md → composite ≥ 85
  - 确认 13 个标准目录/文件全部存在
  - 更新 module/registry.yaml spec_ref 路径
```

**预计总工时**：7.5h
**验收标准**：6/6 模块 composite ≥ 85，目录结构 100% 嵌套

### Batch 2：Layer 1 原语与存储（11 模块）

> 依赖：kernel。必须在 Batch 1 完成后执行。

| 序号 | 模块        | 维度分 | 主要缺口                                                                   | 预计工时 | 优先级 |
| ---- | ----------- | ------ | -------------------------------------------------------------------------- | -------- | ------ |
| 2.1  | configx     | 74     | Metadata + Open Questions                                                  | 1.5h     | P0     |
| 2.2  | observex    | 89     | Metadata + Open Questions                                                  | 1h       | P0     |
| 2.3  | resiliencx  | 81     | Metadata + Open Questions                                                  | 1h       | P0     |
| 2.4  | schedulex   | 89     | Metadata + Open Questions                                                  | 1h       | P0     |
| 2.5  | redisx      | 84     | Metadata + Dependencies + Open Questions                                   | 1.5h     | P0     |
| 2.6  | kafkax      | 89     | Metadata + Open Questions                                                  | 1h       | P1     |
| 2.7  | natsx       | 85     | Metadata + Open Questions                                                  | 1h       | P1     |
| 2.8  | postgresx   | 82     | Metadata + Open Questions                                                  | 1h       | P1     |
| 2.9  | taosx       | 63     | Metadata + Interface + Data Model + Error Handling + Upgrade + Release DoD | 3h       | P1     |
| 2.10 | ossx        | 38     | 14 章节缺失                                                                | 5h       | P2     |
| 2.11 | clickhousex | 87     | Metadata + Open Questions                                                  | 1h       | P0     |

**预计总工时**：18h
**验收标准**：11/11 模块 composite ≥ 85（ossx 可标 PASS_WITH_RISK），目录结构 100% 嵌套

### Batch 3：Layer 2 测试与传输（2 模块）

> 依赖：kernel + configx + observex + resiliencx + schedulex + contracts。必须在 Batch 2 完成后执行。

| 序号 | 模块       | 维度分 | 主要缺口                  | 预计工时 | 优先级 |
| ---- | ---------- | ------ | ------------------------- | -------- | ------ |
| 3.1  | testkitx   | 81     | Metadata + Open Questions | 1h       | P0     |
| 3.2  | transportx | 85     | Metadata + Open Questions | 1h       | P0     |

**预计总工时**：2h
**验收标准**：2/2 模块 composite ≥ 85，目录结构 100% 嵌套

### Batch 4：Layer 3 组装层（1 模块）

> 依赖：全部 Layer 0-2。必须最后执行。

| 序号 | 模块      | 维度分 | 主要缺口    | 预计工时 | 优先级 |
| ---- | --------- | ------ | ----------- | -------- | ------ |
| 4.1  | bootstrap | 18     | 23 章节全缺 | 6h       | P1     |

**预计总工时**：6h
**验收标准**：composite ≥ 60 或标注 "spec 重写中" 暂停状态

---

## 四、迁移里程碑

| 里程碑 | 内容                        | 模块数 | 预计工时 | 累计  |
| ------ | --------------------------- | ------ | -------- | ----- |
| M1     | Batch 1: Layer 0 基座       | 6      | 7.5h     | 7.5h  |
| M2     | Batch 2: Layer 1 原语与存储 | 11     | 18h      | 25.5h |
| M3     | Batch 3: Layer 2 测试与传输 | 2      | 2h       | 27.5h |
| M4     | Batch 4: Layer 3 组装层     | 1      | 6h       | 33.5h |
| M5     | 全局验收 + registry 更新    | —      | 2h       | 35.5h |

**总计**：约 35.5 小时（含验收）

---

## 五、单模块迁移检查清单

每个模块迁移时，必须按以下检查清单逐项确认：

### 5.1 目录结构迁移

- [ ] `goal/goal.md` 存在（从 `goal.md` 迁移或新建）
- [ ] `spec/SPEC.md` 存在（从 `SPEC.md` 迁移）
- [ ] `design/` 目录存在（创建 DESIGN.md 占位）
- [ ] `plan/` 目录存在（从 `PLAN.md`/`IMPLEMENTATION-PLAN.md` 迁移）
- [ ] `tasks/` 目录存在（保留现有或创建）
- [ ] `prompt/` 目录存在（保留现有或创建）
- [ ] `evidence/` 目录存在（创建）
- [ ] `matrix/` 目录存在（从 `TRACEABILITY.md` 迁移或创建）
- [ ] `gate/` 目录存在（创建 gate-checklist.md）
- [ ] `schema/` 目录存在（创建）
- [ ] `README.md` 存在（保留或创建）
- [ ] `CHANGELOG.md` 存在（创建）
- [ ] `ci-workflow.yaml` 存在（保留或创建）
- [ ] 旧平铺文件已移除（`goal.md`、`SPEC.md`、`TRACEABILITY.md` 等）

### 5.2 SPEC 内容补齐

- [ ] §1 Metadata 完整（Owner, Repository, Status, Spec-Version, Last-Updated）
- [ ] §23 Open Questions 存在（即使为空）
- [ ] 所有 23 节标题存在（空壳章节标注 "N/A — 原因说明"）
- [ ] FR 使用 WHEN/THEN 格式
- [ ] BR 有违反后果
- [ ] Non-goals ≥ 3 条
- [ ] Edge Cases ≥ 5 条
- [ ] `rubric-score.py spec` composite ≥ 85

### 5.3 Goal 管线制品

- [ ] `goal/goal.md` 包含模块定位、1.0 发布标准、non-goals
- [ ] `matrix/matrix.yaml` 或 `matrix/TRACEABILITY.md` 存在（FR→AC→TC→Evidence）
- [ ] `gate/gate-checklist.md` 存在（从 CI 提取检查项）
- [ ] `registry.yaml` 中 `spec_ref` 路径更新为 `module/{mod}/spec/SPEC.md`

### 5.4 验收命令

```bash
# 1. 目录结构检查
python3 -c "
from pathlib import Path
mod = 'module/{MODULE}'
required = ['goal/goal.md','spec/SPEC.md','design','plan','tasks','prompt',
            'evidence','matrix','gate','schema','README.md','CHANGELOG.md','ci-workflow.yaml']
for r in required:
    p = Path(mod) / r
    status = 'OK' if p.exists() else 'MISSING'
    print(f'  {status}  {r}')
"

# 2. SPEC 评分
python3 docs/governance/scoring/rubric-score.py spec module/{MODULE}/spec/SPEC.md

# 3. 旧平铺文件检查（应无残留）
ls module/{MODULE}/goal.md module/{MODULE}/SPEC.md 2>/dev/null && echo "FAIL: 平铺文件残留" || echo "OK: 无平铺残留"
```

---

## 六、风险评估与缓解

| 风险                                 | 概率 | 影响 | 缓解措施                                |
| ------------------------------------ | ---- | ---- | --------------------------------------- |
| 路径引用断裂（CI 脚本、README 索引） | 高   | 中   | 迁移后全局 grep 旧路径，逐一修复        |
| registry.yaml spec_ref 未同步        | 中   | 高   | 每个模块迁移后立即更新 spec_ref         |
| SPEC 内容补齐引入语义错误            | 中   | 中   | 补齐后由 goal-reviewer 审查             |
| ossx/bootstrap SPEC 差距过大无法达标 | 高   | 低   | 标注 "spec 重写中" 暂停，不阻塞其他模块 |
| 迁移期间其他模块引用旧路径           | 低   | 中   | 一个模块一个 PR，快速合并减少窗口期     |
| CHANGELOG 历史丢失                   | 低   | 低   | 从 git log 生成初始 CHANGELOG           |

---

## 七、全局验收标准

迁移完成后，以下条件必须全部满足：

- [ ] 20/20 模块目录结构为嵌套式（`goal/goal.md`、`spec/SPEC.md` 等）
- [ ] 20/20 模块 `rubric-score.py spec` composite ≥ 85（bootstrap 可豁免至 ≥ 60）
- [ ] 20/20 模块 `registry.yaml` spec_ref 指向 `module/{mod}/spec/SPEC.md`
- [ ] 20/20 模块有 `CHANGELOG.md` 和 `ci-workflow.yaml`
- [ ] 20/20 模块有 `goal/goal.md`、`matrix/`、`gate/`
- [ ] `goal-workflow.sh validate` 全绿
- [ ] `.github/ci/four-source-check.sh` 无新增 force_override
- [ ] 无平铺文件残留（`module/*/goal.md`、`module/*/SPEC.md` 不存在）

---

## 八、执行顺序总览

```
Week 1: Batch 1 (Layer 0, 6 模块, 7.5h)
  ├── kernel → contracts → xlib_standard（P0, 2.5h）
  └── xlib_harness → xlib_evidence → xlibgate（P1, 5h）

Week 2: Batch 2 (Layer 1, 11 模块, 18h)
  ├── configx → observex → resiliencx → schedulex（P0, 4.5h）
  ├── redisx → clickhousex → postgresx（P0, 3.5h）
  ├── kafkax → natsx（P1, 2h）
  └── taosx → ossx（P1/P2, 8h）

Week 3: Batch 3+4 (Layer 2+3, 3 模块, 8h)
  ├── testkitx → transportx（P0, 2h）
  └── bootstrap（P1, 6h）

Week 3: M5 全局验收（2h）
```

---

## 九、模块迁移详情卡

### 9.1 kernel

| 字段     | 值                                                                        |
| -------- | ------------------------------------------------------------------------- |
| 层级     | L0                                                                        |
| 依赖     | 无                                                                        |
| 维度分   | 87                                                                        |
| 缺失章节 | Metadata, Open Questions                                                  |
| 已有制品 | tasks/, plan/, ci-workflow.yaml                                           |
| 迁移步骤 | 目录迁移 → 补 Metadata + Open Questions → 创建 goal/matrix/gate/CHANGELOG |
| 预计工时 | 1h                                                                        |
| 验收目标 | composite ≥ 90                                                            |

### 9.2 contracts

| 字段     | 值                                                             |
| -------- | -------------------------------------------------------------- |
| 层级     | contracts                                                      |
| 依赖     | 无                                                             |
| 维度分   | 74                                                             |
| 缺失章节 | Open Questions                                                 |
| 已有制品 | tasks/, plan/, prompt/, ci-workflow.yaml                       |
| 迁移步骤 | 目录迁移 → 补 Open Questions → 创建 goal/matrix/gate/CHANGELOG |
| 预计工时 | 1h                                                             |
| 验收目标 | composite ≥ 90                                                 |

### 9.3 xlib_standard

| 字段     | 值                                                       |
| -------- | -------------------------------------------------------- |
| 层级     | standard-source                                          |
| 依赖     | 无                                                       |
| 维度分   | 96                                                       |
| 缺失章节 | Metadata（红线触发）                                     |
| 已有制品 | tasks/, ci-workflow.yaml                                 |
| 迁移步骤 | 目录迁移 → 补 Metadata → 创建 goal/matrix/gate/CHANGELOG |
| 预计工时 | 0.5h                                                     |
| 验收目标 | composite ≥ 98（PASS）                                   |

### 9.4 xlibgate

| 字段     | 值                                                                                                                                                                                                                            |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 层级     | gate                                                                                                                                                                                                                          |
| 依赖     | 无                                                                                                                                                                                                                            |
| 维度分   | 35                                                                                                                                                                                                                            |
| 缺失章节 | 20 章节缺失（几乎全部）                                                                                                                                                                                                       |
| 已有制品 | prompt/, tasks/, ADR                                                                                                                                                                                                          |
| 迁移步骤 | 目录迁移 → SPEC 大幅补齐（Problem, Goals, Non-goals, FR, BR, Interface, Data Model, Config, Error, Edge, Dir, Deps, Testing, Perf, Obs, Security, CI, Upgrade, Release DoD, Open Questions）→ 创建 goal/matrix/gate/CHANGELOG |
| 预计工时 | 4h                                                                                                                                                                                                                            |
| 验收目标 | composite ≥ 60 或标注暂停                                                                                                                                                                                                     |

### 9.5 ossx

| 字段     | 值                                                         |
| -------- | ---------------------------------------------------------- |
| 层级     | storage                                                    |
| 依赖     | kernel                                                     |
| 维度分   | 38                                                         |
| 缺失章节 | 14 章节缺失                                                |
| 已有制品 | tasks/, ci-workflow.yaml                                   |
| 迁移步骤 | 目录迁移 → SPEC 中度补齐 → 创建 goal/matrix/gate/CHANGELOG |
| 预计工时 | 5h                                                         |
| 验收目标 | composite ≥ 60 或标注暂停                                  |

### 9.6 bootstrap

| 字段     | 值                                                    |
| -------- | ----------------------------------------------------- |
| 层级     | L1 Assembly                                           |
| 依赖     | kernel + configx + observex + resiliencx + 全部存储层 |
| 维度分   | 18                                                    |
| 缺失章节 | 23 章节全缺                                           |
| 已有制品 | ci-workflow.yaml                                      |
| 迁移步骤 | 目录迁移 → SPEC 全面重写 → 创建全部制品               |
| 预计工时 | 6h                                                    |
| 验收目标 | composite ≥ 60 或标注 "spec 重写中" 暂停              |

---

## 十、附录：批量迁移脚本模板

```bash
#!/usr/bin/env bash
# migrate-module.sh — 单模块目录迁移脚本
# 用法: bash migrate-module.sh <module_name>
set -euo pipefail

MOD="$1"
MOD_DIR="module/$MOD"

if [ ! -d "$MOD_DIR" ]; then
  echo "ERROR: $MOD_DIR not found"
  exit 1
fi

cd "$MOD_DIR"

# 1. 创建嵌套目录
mkdir -p goal spec design plan tasks prompt evidence matrix gate schema

# 2. 迁移文件
[ -f goal.md ] && git mv goal.md goal/goal.md
[ -f SPEC.md ] && git mv SPEC.md spec/SPEC.md
[ -f TRACEABILITY.md ] && git mv TRACEABILITY.md matrix/TRACEABILITY.md
[ -f PLAN.md ] && git mv PLAN.md plan/PLAN.md
[ -f IMPLEMENTATION-PLAN.md ] && git mv IMPLEMENTATION-PLAN.md plan/PLAN.md
[ -f ACCEPTANCE.md ] && git mv ACCEPTANCE.md spec/ACCEPTANCE.md
[ -f FEATURES.md ] && git mv FEATURES.md spec/FEATURES.md

# 3. 创建缺失制品
[ ! -f CHANGELOG.md ] && echo "# Changelog\n" > CHANGELOG.md
[ ! -f ci-workflow.yaml ] && echo "# CI workflow TBD" > ci-workflow.yaml
[ ! -f design/DESIGN.md ] && echo "# Design — TBD" > design/DESIGN.md
[ ! -f gate/gate-checklist.md ] && echo "# Gate Checklist — TBD" > gate/gate-checklist.md

# 4. 清理旧目录（如 analysis/）
[ -d analysis ] && git mv analysis/ evidence/analysis-archive/

echo "Migration complete for $MOD"
echo "Next steps:"
echo "  1. 补齐 spec/SPEC.md 的 Metadata + Open Questions"
echo "  2. 创建 goal/goal.md"
echo "  3. 创建 matrix/matrix.yaml"
echo "  4. 运行: python3 docs/governance/scoring/rubric-score.py spec $MOD_DIR/spec/SPEC.md"
echo "  5. 更新 module/registry.yaml spec_ref 路径"
```

---

_方案生成时间：2026-06-27_
_数据来源：registry.yaml、FOUNDATION-DEPS.yaml、rubric-score.py 批量评分、文件系统扫描_
_分析师：GLM-5.2_
