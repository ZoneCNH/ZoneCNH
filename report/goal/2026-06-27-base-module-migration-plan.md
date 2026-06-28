# 基座模块 Goal 驱动交付管线迁移执行方案

> 生成日期：2026-06-27
> 范围：20 个基座（Foundation）模块
> 数据来源：`module/registry.yaml`、`module/FOUNDATION-DEPS.yaml`、`rubric-score.py` 批量评分、文件系统扫描
> 方法：依赖拓扑排序 + 差距分析 + 分批迁移
> 修订依据：2026-06-27/28 agent team 复核（文件系统扫描 + registry/deps + Gate 文档校验）

> 口径说明：本方案的 20 个基座模块不包含 `domainx`。`domainx` 可出现在 `FOUNDATION-DEPS.yaml` 的治理依赖语境中，但不计入本次 foundation 迁移批次。

---

## 一、迁移目标

将 20 个基座模块从当前"核心入口平铺 + 目录化制品不完整 + 不完整 SPEC + 无完整 Goal Gate 证据"状态，迁移到 Goal 驱动交付管线标准：

| 维度        | 当前状态                           | 目标状态                                                                     |
| ----------- | ---------------------------------- | ---------------------------------------------------------------------------- |
| 目录结构    | 核心入口文件仍平铺；辅助目录部分已存在 | 20/20 嵌套（goal/spec/design/plan/tasks/prompt/evidence/matrix/gate/schema） |
| SPEC 质量   | 0/20 通过（composite=0，红线触发） | ≥17/20 达到模块修复下限（rubric composite≥85）；Release PASS 另需四源 composite_score≥98 + Gate PASS |
| Goal 制品   | 0/20 有 goal/goal.md               | 20/20 有 goal/goal.md                                                        |
| Matrix      | 1/20 有 matrix/（无 matrix/TRACEABILITY.md） | 20/20 有 matrix/matrix.yaml；matrix/TRACEABILITY.md 仅作兼容投影              |
| Gate        | 0/20 有 gate/                      | 20/20 有 gate/                                                               |
| CHANGELOG   | 1/20 有                            | 20/20 有                                                                     |
| CI 工作流   | 20/20 有 ci-workflow.yaml          | 20/20 有                                                                     |
| rubric 评分 | 0/20 PASS                          | ≥17/20 达到模块修复下限（rubric composite≥85）；Release PASS 以 pipeline-arbiter 为准 |

> 注：`matrix/` 当前只统计目录存在；本次迁移的可验收追溯 SSOT 是 `matrix/matrix.yaml`。若评分工具仍读取旧路径，可生成 `matrix/TRACEABILITY.md` 兼容投影，但不得与 SSOT 冲突。
> 验收口径：本表“目标状态”不是当前事实；任何 `20/20`、`PASS` 或 Release 结论只能在对应批次证据、四源仲裁和 G10 Release Bundle 通过后勾选。

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

Assembly 特殊尾批（registry 层级为 L1 Assembly，执行顺序按依赖拓扑后置）:
  bootstrap → kernel + configx + observex + resiliencx + taosx + postgresx + redisx + kafkax + natsx + ossx + clickhousex
```

> `bootstrap` 依赖清单按 `module/FOUNDATION-DEPS.yaml` 的 `allowed_deps.bootstrap` 固定；不包含 `schedulex`、`contracts`、`transportx`、`domainx`。

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
| plan/ 目录       | 2/20  | 18   |
| tasks/ 目录      | 19/20 | 1    |
| prompt/ 目录     | 5/20  | 15   |
| evidence/ 目录   | 2/20  | 18   |
| matrix/ 目录     | 1/20  | 19   |
| gate/ 目录       | 0/20  | 20   |
| schema/ 目录     | 0/20  | 20   |
| README.md        | 2/20  | 18   |
| CHANGELOG.md     | 1/20  | 19   |
| ci-workflow.yaml | 20/20 | 0    |

---

## 三、分批迁移方案

### 迁移原则

1. **M0 兼容先行**：先让 CI、治理脚本、索引文档和 CODEOWNERS 同时兼容平铺路径与嵌套路径，再开始模块级迁移
2. **依赖优先**：先迁移被依赖的模块（Layer 0 → 1 → 2 → Assembly 特殊尾批），确保下游迁移时上游制品已就绪
3. **先结构后内容，但不让占位通过**：目录迁移可先行，生成制品若未完成只能标 `Draft`/`BLOCKED`；进入 Gate/PASS 前，`goal/`、`spec/`、`design/`、`gate/`、`matrix/`、`schema/` 与 `ci-workflow.yaml` 必须清除 `Draft` 与占位文本，不得用 `TBD` 占位满足 Gate
4. **机械化优先**：Metadata + Open Questions 是批量操作，优先执行
5. **一个模块一个 PR**：每个模块的目录迁移 + SPEC 修复 + 制品创建 = 1 个 PR；分支必须从 `main` HEAD 创建，不直接编辑 `main`。PR train 仅表示排队顺序，不得把多个模块合成一个 PR
6. **评分与 Gate 双验收**：`rubric-score.py` 的 composite ≥85 只是模块修复下限；Release PASS 必须由 pipeline-arbiter 四源 composite_score≥98、Goal Gate G6/G10 verdict 和证据包共同裁决

### Batch 0：兼容预检（全局，1 批）

> 依赖：无。该批次不迁移模块内容，只消除 flat → nested 期间的工具链断裂风险。

| 序号 | 工作项                  | 产出/检查点                                                       | 预计工时 | 优先级 |
| ---- | ----------------------- | ----------------------------------------------------------------- | -------- | ------ |
| 0.1  | 路径兼容审计            | CI、governance scripts、README/索引、CODEOWNERS 不只假设平铺路径 | 0.75h    | P0     |
| 0.2  | 20 模块口径锁定         | 确认 foundation 批次清单；`domainx` 明确排除                     | 0.25h    | P0     |
| 0.3  | 目录/制品基线重扫       | 记录 20 模块当前目录、SPEC、Gate、Matrix、CI 工作流状态          | 0.5h     | P0     |
| 0.4  | 分支/worktree 纪律检查  | 确认后续每个模块 PR 均从 `main` HEAD 创建                         | 0.5h     | P0     |

**预计总工时**：2h
**验收标准**：迁移工具链能同时识别 flat 与 nested 路径；20 模块清单固定；本批次不产生模块内容迁移。

### 批次推进与 Release 语义

- **模块修复下限**：模块目录结构齐全，`rubric-score.py` composite ≥85，且该模块的 Gate verdict、Risk Register、证据入口已记录。
- **批次可推进**：下一批直接依赖的模块必须达到模块修复下限；高风险模块若为 `BLOCKED`，只能在不被下一批直接消费时作为批次内例外继续排队。
- **高风险例外**：`xlibgate`、`ossx`、`bootstrap` 等可在批次内以 `BLOCKED` 暂停，但必须有 Gate verdict + Risk Register；例外不得计入 PASS，不得解锁 Release，且 direct dependency 为 `BLOCKED` 时不得启动依赖它的模块。
- **G5 Matrix 最低门槛**：不得只以文件存在放行；`matrix/matrix.yaml` 必须包含非空 canonical edges，覆盖 Goal→Spec、Spec→Task/Test/Decision、P0/P1 AC→Test+Evidence；release-critical edge 必须有 `status` 和 `evidence_id`；Dropped edge 必须有 `drop_reason`。
- **G10 Release 必备证据**：strict validator、Matrix check-only、Evidence Bundle `validation_summary`、Release Manifest、Risk Register 摘要、rollback validation、Agent protocol evidence、G10 verdict。Release Manifest 必须引用 `risk_register`。
- **Agent protocol evidence**：每个模块 Release 必须证明单任务/单 writer、独立 branch/worktree 或等价隔离、Context Package 含 branch/commit/allowed files/forbidden scope、writer/reviewer/verifier 分离；缺任一项则 G10 `BLOCKED`。
- **Release PASS**：必须满足 pipeline-arbiter 四源 `composite_score >= 98`、Gate verdict 为 PASS、G6/G10 无 `PASS_WITH_RISK`、无 open/escalated `release_blocking` 风险、Matrix 非空且闭合、Risk Register 已纳入 Release Manifest、G10 证据齐全。

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
  git mv IMPLEMENTATION-PLAN.md plan/IMPLEMENTATION-PLAN.md  (如存在)
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
  - 创建 design/DESIGN.md（最小设计决策；未完成时标 Draft/BLOCKED 和原因）
  - 创建 gate/gate-checklist.md（映射 G0-G11；未完成项不得算 PASS）
  - 创建 schema/ 目录（无 schema 时写明 N/A 原因）

Step 5: 验收
  - python3 docs/governance/scoring/rubric-score.py spec module/{mod}/spec/SPEC.md → composite ≥ 85，作为模块修复下限；Release PASS 不以该值单独判定
  - pipeline-arbiter 四源 composite_score ≥98
  - Goal Gate verdict（PASS/PASS_WITH_RISK/FAIL/BLOCKED）已记录；PASS_WITH_RISK 不得越过 G6/G10/P0/P1 红线
  - G5 Matrix 通过：canonical edges 非空，覆盖 Goal→Spec、Spec→Task/Test/Decision、P0/P1 AC→Test+Evidence；release-critical edge 有非空 `status` + `evidence_id`；Dropped edge 有 `drop_reason`
  - G10 Release 证据齐全：strict validator、Matrix check-only、Evidence Bundle validation_summary、Release Manifest、Risk Register、rollback validation、Agent protocol evidence、G10 verdict
  - 确认 13 个标准目录/文件全部存在
  - 更新 module/registry.yaml spec_ref 路径
  - 确认旧平铺文件无残留
```

**预计总工时**：7.5h
**验收标准**：6/6 模块达到 rubric 修复下限（composite ≥85），目录结构 100% 嵌套；Release PASS 另按 G10 与四源评分裁决

### Batch 2：Layer 1 原语与存储（11 模块）

> 依赖：`kernel` 达到批次可推进状态。若 `xlibgate` 作为高风险例外 `BLOCKED`，必须确认其风险不阻断 Batch 2 直接依赖；该 `BLOCKED` 仍阻断 M5/Release PASS。

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

**执行拆分**：该批次按 3 条 PR train 排队推进：核心原语（configx/observex/resiliencx/schedulex/redisx/clickhousex）、消息与存储适配（kafkax/natsx/postgresx）、高风险重写（taosx/ossx）。train 只表示执行 lane；每个模块仍独立 branch/worktree/PR。

**验收标准**：11/11 模块目录结构 100% 嵌套；高风险模块若无法达到 composite ≥85，必须进入暂停/BLOCKED，并记录 Goal Gate verdict + Risk Register，不得用 PASS_WITH_RISK 绕过 G6/G10/P0/P1 红线；Release PASS 另按 G10 与四源评分裁决

### Batch 3：Layer 2 测试与传输（2 模块）

> 依赖：`kernel + configx + observex + resiliencx + schedulex + contracts` 达到批次可推进状态。Batch 2 中与本批无直接依赖的高风险 `BLOCKED` 不得阻断本批，但仍阻断 M5/Release PASS。

| 序号 | 模块       | 维度分 | 主要缺口                  | 预计工时 | 优先级 |
| ---- | ---------- | ------ | ------------------------- | -------- | ------ |
| 3.1  | testkitx   | 81     | Metadata + Open Questions | 1h       | P0     |
| 3.2  | transportx | 85     | Metadata + Open Questions | 1h       | P0     |

**预计总工时**：2h
**验收标准**：2/2 模块达到 rubric 修复下限（composite ≥85），目录结构 100% 嵌套；Release PASS 另按 G10 与四源评分裁决

### Batch 4：Assembly 特殊尾批（1 模块）

> 依赖：`kernel + configx + observex + resiliencx + taosx + postgresx + redisx + kafkax + natsx + ossx + clickhousex` 全部达到批次可推进状态。`bootstrap` 在 registry 中为 `L1 Assembly`，但执行顺序按依赖拓扑后置，必须最后执行。

| 序号 | 模块      | 维度分 | 主要缺口    | 预计工时 | 优先级 |
| ---- | --------- | ------ | ----------- | -------- | ------ |
| 4.1  | bootstrap | 18     | 23 章节全缺 | 6h       | P1     |

**预计总工时**：6h
**验收标准**：优先达到 composite ≥85；若暂无法达标，必须进入暂停/BLOCKED，并记录 Goal Gate verdict + Risk Register，不计入 PASS

---

## 四、迁移里程碑

| 里程碑 | 内容                        | 模块数 | 预计工时 | 累计  |
| ------ | --------------------------- | ------ | -------- | ----- |
| M0     | Batch 0: 兼容预检           | —      | 2h       | 2h    |
| M1     | Batch 1: Layer 0 基座       | 6      | 7.5h     | 9.5h  |
| M2     | Batch 2: Layer 1 原语与存储 | 11     | 18h      | 27.5h |
| M3     | Batch 3: Layer 2 测试与传输 | 2      | 2h       | 29.5h |
| M4     | Batch 4: Assembly 特殊尾批  | 1      | 6h       | 35.5h |
| M5     | 全局验收 + registry 更新    | —      | 2h       | 37.5h |

**总计**：至少 37.5 小时（含验收；不含高风险模块重写返工缓冲）

---

## 五、单模块迁移检查清单

每个模块迁移时，必须按以下检查清单逐项确认：

### 5.1 目录结构迁移

- [ ] `goal/goal.md` 存在（从 `goal.md` 迁移或新建）
- [ ] `spec/SPEC.md` 存在（从 `SPEC.md` 迁移）
- [ ] `design/` 目录存在（创建最小 DESIGN.md；未完成项标 Draft/BLOCKED 和原因）
- [ ] `plan/` 目录存在（从 `PLAN.md`/`IMPLEMENTATION-PLAN.md` 迁移）
- [ ] `tasks/` 目录存在（保留现有或创建）
- [ ] `prompt/` 目录存在（保留现有或创建）
- [ ] `evidence/` 目录存在（创建）
- [ ] `matrix/` 目录存在（从 `TRACEABILITY.md` 迁移或创建）
- [ ] `gate/` 目录存在（创建 gate-checklist.md，覆盖 G0-G11）
- [ ] `schema/` 目录存在（创建；无 schema 时写明 N/A 原因）
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
- [ ] `python3 docs/governance/scoring/rubric-score.py spec module/{MODULE}/spec/SPEC.md` composite ≥85，作为修复下限；PASS 仍需四源 composite_score ≥98

### 5.3 Goal 管线制品

- [ ] `goal/goal.md` 包含模块定位、1.0 发布标准、non-goals
- [ ] `matrix/matrix.yaml` 存在且 canonical edges 非空，覆盖 Goal→Spec、Spec→Task/Test/Decision、P0/P1 AC→Test+Evidence；release-critical edge 有 `status` + `evidence_id`，Dropped edge 有 `drop_reason`；`matrix/TRACEABILITY.md` 如存在仅为兼容投影，内容不得与 SSOT 冲突
- [ ] `gate/gate-checklist.md` 存在（从 CI 和 Goal Gate 提取检查项，覆盖 G0-G11）
- [ ] Goal Gate verdict 存在；暂停/BLOCKED/PASS_WITH_RISK 必须说明阻断原因和风险处置
- [ ] Risk Register 作为 G10 必备输入存在；High/Critical 或 `release_blocking` 风险必须记录 Risk ID、Goal ID、Task ID、Type、Description、Probability、Impact、Severity、Trigger、Mitigation、Owner、Status、Linked Gates、Linked Evidence、Release Blocking、Residual Risk、Acceptance、Review Cadence；不得存在 open/escalated `release_blocking` 风险
- [ ] Agent protocol evidence 存在：单任务/单 writer、独立 branch/worktree 或等价隔离、Context Package branch/commit/allowed files/forbidden scope、writer/reviewer/verifier 分离
- [ ] `registry.yaml` 中 `spec_ref` 路径更新为 `module/{mod}/spec/SPEC.md`

### 5.4 验收命令

```bash
# 1. 目录结构检查
python3 - <<'PY'
from pathlib import Path
mod = Path("module/{MODULE}")
required = ['goal/goal.md','spec/SPEC.md','design','plan','tasks','prompt',
            'evidence','matrix','gate','schema','README.md','CHANGELOG.md','ci-workflow.yaml']
missing = []
for r in required:
    p = mod / r
    if not p.exists():
        missing.append(r)
    print(f"  {'OK' if p.exists() else 'MISSING'}  {r}")
if missing:
    raise SystemExit(f"FAIL: missing required artifacts: {', '.join(missing)}")
PY

# 2. Matrix 最低门槛（正式结论以 Goal Matrix check-only 为准）
python3 - <<'PY'
from pathlib import Path

try:
    import yaml
except ImportError as exc:
    raise SystemExit("FAIL: PyYAML is required for matrix structural validation") from exc


def fail(message):
    raise SystemExit(f"FAIL: {message}")


def flatten(value):
    if isinstance(value, dict):
        for key, item in value.items():
            yield str(key)
            yield from flatten(item)
    elif isinstance(value, list):
        for item in value:
            yield from flatten(item)
    elif value is not None:
        yield str(value)


def present(value):
    return value not in (None, "", [], {})


matrix = Path("module/{MODULE}/matrix/matrix.yaml")
if not matrix.is_file() or matrix.stat().st_size == 0:
    fail(f"{matrix} missing or empty")

with matrix.open(encoding="utf-8") as fh:
    data = yaml.safe_load(fh)

if not isinstance(data, dict):
    fail("matrix root must be a mapping")
edges = data.get("edges")
if not isinstance(edges, list) or not edges:
    fail("canonical edges must be a non-empty list")

corpus = "\n".join(flatten(data)).lower()
required_tokens = {
    "goal": "Goal",
    "spec": "Spec",
    "task": "Task",
    "test": "Test",
    "decision": "Decision",
    "evidence": "Evidence",
}
missing_tokens = [label for token, label in required_tokens.items() if token not in corpus]
if missing_tokens:
    fail("missing traceability coverage tokens: " + ", ".join(missing_tokens))

for edge in edges:
    if not isinstance(edge, dict):
        fail("each edge must be a mapping")
    if not present(edge.get("id")):
        fail("edge id missing")
    edge_text = "\n".join(flatten(edge)).lower()
    release_critical = (
        edge.get("release_critical") is True
        or edge.get("releaseCritical") is True
        or "release_critical" in edge_text
        or "release-critical" in edge_text
    )
    if release_critical:
        if not present(edge.get("status")):
            fail(f"release-critical edge {edge.get('id')} missing status")
        if not present(edge.get("evidence_id")) and not present(edge.get("evidenceId")):
            fail(f"release-critical edge {edge.get('id')} missing evidence_id")
    dropped = str(edge.get("status", "")).lower() == "dropped" or edge.get("dropped") is True
    if dropped and not present(edge.get("drop_reason")) and not present(edge.get("dropReason")):
        fail(f"Dropped edge {edge.get('id')} missing drop_reason")

for token in ("p0", "p1", "ac", "test", "evidence"):
    if token not in corpus:
        fail("P0/P1 AC -> Test/Evidence coverage token missing: " + token)

print("OK: matrix structural minimum passed")
PY
PROJECTION="module/{MODULE}/matrix/TRACEABILITY.md"
if [ -f "$PROJECTION" ]; then
  test -s "$PROJECTION"
  rg -n "matrix/matrix.yaml|SSOT|canonical|兼容投影" "$PROJECTION" >/dev/null
fi

# 3. SPEC 评分
python3 docs/governance/scoring/rubric-score.py spec module/{MODULE}/spec/SPEC.md

# 4. 旧平铺文件检查（应无残留）
python3 - <<'PY'
from pathlib import Path
mod = Path("module/{MODULE}")
flat = ["goal.md", "SPEC.md", "TRACEABILITY.md", "PLAN.md", "IMPLEMENTATION-PLAN.md", "ACCEPTANCE.md", "FEATURES.md"]
residual = [name for name in flat if (mod / name).exists()]
if residual:
    raise SystemExit(f"FAIL: 平铺文件残留: {', '.join(residual)}")
print("OK: 无平铺残留")
PY

# 5. 禁止占位文本误通过
python3 - <<'PY'
import re
from pathlib import Path

mod = Path("module/{MODULE}")
roots = [mod / name for name in ("goal", "spec", "design", "gate", "matrix", "schema")]
missing = [str(path.relative_to(mod)) for path in roots if not path.exists()]
if missing:
    raise SystemExit(f"FAIL: 缺少待扫描目录: {', '.join(missing)}")

pattern = re.compile(r"TBD|TODO|Draft|草稿|待补|占位|脚手架|scaffold|seed", re.IGNORECASE)
hits = []
for root in roots:
    for path in root.rglob("*"):
        if path.is_file() and pattern.search(path.read_text(encoding="utf-8", errors="ignore")):
            hits.append(str(path))
for path in [mod / "ci-workflow.yaml"]:
    if path.is_file() and pattern.search(path.read_text(encoding="utf-8", errors="ignore")):
        hits.append(str(path))
if hits:
    raise SystemExit("FAIL: 仍有占位文本: " + ", ".join(hits))
print("OK: 无占位文本")
PY

# 6. 批次级 CI/Gate 脚本（统一用 bash 调用，避免执行位差异）
bash .github/ci/spec-lint.sh
bash .github/ci/spec-drift-guard.sh
bash .github/ci/status-consistency-check.sh
bash .github/ci/traceability-check.sh
bash .github/ci/task-spec-validate.sh
bash .github/ci/four-source-check.sh

# 7. 四源仲裁/Gate fail-fast（artifact path 由 pipeline-arbiter 产出）
ARBITER_VERDICT="${ARBITER_VERDICT:?set ARBITER_VERDICT to pipeline-arbiter verdict json}"
python3 - "$ARBITER_VERDICT" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    data = json.load(fh)

def number(value, label):
    try:
        return float(value)
    except (TypeError, ValueError):
        raise SystemExit(f"FAIL: {label} must be numeric: {value!r}")


def present(value, label):
    if value is None or value == "" or value == [] or value == {} or isinstance(value, bool):
        raise SystemExit(f"FAIL: {label} missing or placeholder")
    return value

score = number(data.get("composite_score"), "composite_score")
verdict = str(data.get("verdict", data.get("gate", ""))).upper()
scores = data.get("scores") or {}
redlines = data.get("redlines") or []
score_range = data.get("score_range") or {}
heterogeneous_divergence = number(data.get("heterogeneous_divergence"), "heterogeneous_divergence")
gates = data.get("gates", {})
risks = data.get("risks", [])
release_manifest = data.get("release_manifest") or {}
evidence = data.get("evidence") or {}

required_sources = {"claude", "codex", "copilot", "rules"}
if not isinstance(scores, dict):
    raise SystemExit("FAIL: scores must be an object")
if not isinstance(score_range, dict):
    raise SystemExit("FAIL: score_range must be an object")
missing_sources = sorted(required_sources - set(scores))
if missing_sources:
    raise SystemExit(f"FAIL: missing four-source scores: {', '.join(missing_sources)}")
source_scores = []
for source in sorted(required_sources):
    item = scores[source]
    if isinstance(item, dict):
        source_scores.append(number(item.get("score"), f"{source}.score"))
        if item.get("redline") is True:
            raise SystemExit(f"FAIL: redline from {source}")
        if source in {"claude", "codex", "copilot"} and str(item.get("confidence", "")).lower() == "low":
            raise SystemExit(f"FAIL: low confidence from {source}")
    else:
        source_scores.append(number(item, f"{source}.score"))
if score < 98:
    raise SystemExit(f"FAIL: pipeline-arbiter composite_score < 98: {score}")
if abs(min(source_scores) - score) > 1e-6:
    raise SystemExit(f"FAIL: composite_score must equal min(four-source scores): {score} vs {source_scores}")
if verdict != "PASS":
    raise SystemExit(f"FAIL: pipeline-arbiter verdict is not PASS: {verdict or '<missing>'}")
if redlines:
    raise SystemExit(f"FAIL: redlines present: {redlines}")
llm_spread = number(score_range.get("llm_spread"), "score_range.llm_spread")
if llm_spread > 5:
    raise SystemExit(f"FAIL: LLM score spread too high: {llm_spread}")
if heterogeneous_divergence > 15:
    raise SystemExit(f"FAIL: heterogeneous divergence too high or missing: {heterogeneous_divergence}")
if not isinstance(release_manifest, dict):
    raise SystemExit("FAIL: release_manifest must be an object")
if not isinstance(evidence, dict):
    raise SystemExit("FAIL: evidence must be an object")
present(release_manifest.get("risk_register"), "Release Manifest risk_register")
required_evidence = {
    "Evidence strict_validator": evidence.get("strict_validator"),
    "Evidence matrix_check_only": evidence.get("matrix_check_only"),
    "Evidence validation_summary": evidence.get("validation_summary") or release_manifest.get("validation_summary"),
    "Evidence release_manifest": evidence.get("release_manifest") or release_manifest,
    "Evidence risk_register_summary": evidence.get("risk_register_summary"),
    "Evidence rollback_validation": evidence.get("rollback_validation") or release_manifest.get("rollback_validation"),
    "Evidence g10_verdict": evidence.get("g10_verdict") or release_manifest.get("g10_verdict"),
}
for label, value in required_evidence.items():
    present(value, label)
agent_protocol = evidence.get("agent_protocol")
if not isinstance(agent_protocol, dict):
    raise SystemExit("FAIL: Agent protocol evidence must be an object")
for field in ("single_task", "single_writer", "isolation", "writer_reviewer_verifier_separation"):
    present(agent_protocol.get(field), f"Agent protocol {field}")
context_package = agent_protocol.get("context_package")
if not isinstance(context_package, dict):
    raise SystemExit("FAIL: Agent protocol context_package must be an object")
for field in ("branch", "commit", "allowed_files", "forbidden_scope"):
    present(context_package.get(field), f"Agent protocol context_package.{field}")
for gate in ("G6", "G10"):
    if str(gates.get(gate, "")).upper() == "PASS_WITH_RISK":
        raise SystemExit(f"FAIL: {gate} must not PASS_WITH_RISK")

blocked = [
    r for r in risks
    if r.get("release_blocking") is True and str(r.get("status", "")).lower() in {"open", "escalated"}
]
if blocked:
    raise SystemExit(f"FAIL: open/escalated release_blocking risk: {blocked}")
print("OK: pipeline-arbiter/Gate verdict can release")
PY
```

---

## 六、风险评估与缓解

Risk Register 是每个 G10 Release 的必备输入，不是失败时才创建的附属文件。每条风险必须能映射到 `Risk ID`、`Goal ID`、`Task ID`、`Type`、`Description`、`Probability`、`Impact`、`Severity`、`Trigger`、`Mitigation`、`Owner`、`Status`、`Linked Gates`、`Linked Evidence`、`Release Blocking`、`Residual Risk`、`Acceptance`、`Review Cadence`。High/Critical 或 `release_blocking` 风险必须有 owner、mitigation、linked gate/evidence、residual risk；存在 open/escalated `release_blocking` 风险时不得 Release PASS。下表只是迁移总览摘要，不替代每个模块/每次 Release 的 Risk Register 本体；正式 Register 必须保留上段完整字段，并由 Release Manifest 引用。

| 风险                                 | Status | Severity | Release Blocking | Trigger / Review Cadence | Owner | 关联 Gate/Evidence | 缓解措施 | 残余风险/接受条件 |
| ------------------------------------ | ------ | -------- | ---------------- | ------------------------ | ----- | ------------------ | -------- | ------------------ |
| 路径引用断裂（CI 脚本、README 索引） | Open | High | true | reference scan 命中；每 PR 复核 | Migration owner | G0/G8；Batch 0 evidence | Batch 0 先做双路径兼容，再迁移模块 | Batch 0 双路径验证通过后关闭；open/escalated 时不可 Release PASS |
| registry.yaml spec_ref 未同步        | Open | High | true | `spec_ref` 指向平铺路径；每模块迁移后复核 | Module owner | G4；validation_summary | 每个模块迁移后立即更新 spec_ref，并用结构化检查确认 | `spec_ref` 全量指向 nested 路径后关闭 |
| SPEC 内容补齐引入语义错误            | Open | Medium | false | goal-reviewer 发现 P0/P1；每模块 Gate 前复核 | Module owner + goal-reviewer | G6；spec-review evidence | 补齐后由 goal-reviewer 审查，问题闭环后再进入 Release Gate | 无 P0/P1 open finding 后可接受 |
| xlibgate/ossx/bootstrap SPEC 差距过大无法达标 | Open | Critical | true | rubric composite <85 或 P0/P1 未闭环；G6/G10 前复核 | Module owner | G6/G10；Risk Register | 进入暂停/BLOCKED，附 Gate verdict 和 Risk Register | open/escalated release_blocking 不可 release |
| 占位制品误判通过                     | Open | Critical | true | placeholder scan 命中；每 PR 复核 | Migration owner | G6/G10；placeholder scan | 禁止 TBD/TODO/Draft/草稿/脚手架/scaffold/seed/待补/占位满足 Gate，验收时扫描并失败退出 | 扫描无命中后关闭 |
| 迁移期间其他模块引用旧路径           | Open | Medium | false | old path scan 命中；Batch 0 + 每批复核 | Migration owner | G0/G8；reference scan | Batch 0 双路径兼容 + 一个模块一个 PR | 旧路径引用仅保留兼容层且有淘汰计划后可接受 |
| Agent/PR 协议证据缺失                | Open | High | true | Release Manifest 缺 agent_protocol；G10 前复核 | Migration owner | G10；Agent protocol evidence | 每个模块 Release Manifest 附单任务/单 writer、branch/worktree、Context Package、writer/reviewer/verifier 分离证据 | 任一证据缺失即 G10 BLOCKED |
| CHANGELOG 历史丢失                   | Open | Low | false | Release Manifest 缺首版历史范围；G10 前复核 | Module owner | G10；Release Manifest | 从 git log 生成初始 CHANGELOG，并在 Release Manifest 记录范围 | Release Manifest 覆盖首版历史后可接受 |

---

## 七、全局验收标准

迁移完成后，以下条件必须全部满足：

- [ ] 20/20 模块目录结构为嵌套式（`goal/goal.md`、`spec/SPEC.md` 等）
- [ ] 17/20 以上模块 `python3 docs/governance/scoring/rubric-score.py spec module/{mod}/spec/SPEC.md` composite ≥85；未达标模块必须暂停/BLOCKED 且有 Gate verdict + Risk Register
- [ ] 批次/Release 级 PASS 由 pipeline-arbiter 裁决，四源 composite_score ≥98
- [ ] G5 Matrix 通过：20/20 模块 `matrix/matrix.yaml` 有非空 canonical edges，覆盖 Goal→Spec、Spec→Task/Test/Decision、P0/P1 AC→Test+Evidence；release-critical edge 有 `status` + `evidence_id`，Dropped edge 有 `drop_reason`
- [ ] G10 Release 证据齐全：strict validator、Matrix check-only、Evidence Bundle validation_summary、Release Manifest、Risk Register、rollback validation、Agent protocol evidence、G10 verdict
- [ ] Release Manifest 引用 `risk_register`；无 open/escalated `release_blocking` 风险
- [ ] 20/20 模块 `registry.yaml` spec_ref 指向 `module/{mod}/spec/SPEC.md`
- [ ] 20/20 模块有 `CHANGELOG.md` 和 `ci-workflow.yaml`
- [ ] 20/20 模块有 `goal/goal.md`、`matrix/`、`gate/`
- [ ] `bash .github/ci/spec-lint.sh`、`bash .github/ci/spec-drift-guard.sh`、`bash .github/ci/status-consistency-check.sh`、`bash .github/ci/traceability-check.sh`、`bash .github/ci/task-spec-validate.sh` 全绿
- [ ] `bash .github/ci/four-source-check.sh` 无新增 force_override，且结果进入 pipeline-arbiter
- [ ] passing 模块的 `goal/`、`spec/`、`design/`、`gate/`、`matrix/`、`schema/` 与 `ci-workflow.yaml` 无 `TBD`/`TODO`/`Draft`/`草稿`/`脚手架`/`scaffold`/`seed`/`占位` 文本
- [ ] 无平铺文件残留（`module/*/goal.md`、`module/*/SPEC.md` 不存在）

---

## 八、执行顺序总览

```
Week 0: Batch 0 (兼容预检, 2h)
  └── 路径兼容审计 → 20 模块口径锁定 → 基线重扫 → 分支/worktree 纪律检查

Week 1: Batch 1 (Layer 0, 6 模块, 7.5h)
  ├── kernel → contracts → xlib_standard（P0, 2.5h）
  └── xlib_harness → xlib_evidence → xlibgate（P1, 5h）

Week 2: Batch 2 (Layer 1, 11 模块, 18h)
  ├── 核心原语: configx → observex → resiliencx → schedulex → redisx → clickhousex
  ├── 消息与存储适配: kafkax → natsx → postgresx
  └── 高风险重写: taosx → ossx

Week 3: Batch 3 + Assembly 特殊尾批 (3 模块, 8h)
  ├── testkitx → transportx（P0, 2h）
  └── bootstrap（P1, 6h）

Week 3: M5 全局验收（2h）
```

> Batch 1/2/3 的 `→` 在执行总览中只表示 PR train 排队 lane，不表示模块依赖；模块依赖以 2.1 拓扑和批次依赖说明为准。每个模块仍必须单独 branch/worktree/PR。

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
| 验收目标 | 修复下限 composite ≥85；建议争取 ≥90；最终 Release PASS 以 pipeline-arbiter composite_score ≥98 + G6/G10 PASS + Evidence Bundle 为准 |

### 9.2 contracts

| 字段     | 值                                                             |
| -------- | -------------------------------------------------------------- |
| 层级     | L0                                                             |
| 依赖     | 无                                                             |
| 维度分   | 74                                                             |
| 缺失章节 | Open Questions                                                 |
| 已有制品 | tasks/, plan/, prompt/, ci-workflow.yaml                       |
| 迁移步骤 | 目录迁移 → 补 Open Questions → 创建 goal/matrix/gate/CHANGELOG |
| 预计工时 | 1h                                                             |
| 验收目标 | 修复下限 composite ≥85；建议争取 ≥90；最终 Release PASS 以 pipeline-arbiter composite_score ≥98 + G6/G10 PASS + Evidence Bundle 为准 |

### 9.3 xlib_standard

| 字段     | 值                                                       |
| -------- | -------------------------------------------------------- |
| 层级     | L0                                                       |
| 依赖     | 无                                                       |
| 维度分   | 96                                                       |
| 缺失章节 | Metadata（红线触发）                                     |
| 已有制品 | tasks/, ci-workflow.yaml                                 |
| 迁移步骤 | 目录迁移 → 补 Metadata → 创建 goal/matrix/gate/CHANGELOG |
| 预计工时 | 0.5h                                                     |
| 验收目标 | rubric/four-source 候选达标；最终 PASS 以 pipeline-arbiter composite_score ≥98 + G6/G10 PASS + Evidence Bundle 为准 |

### 9.4 xlibgate

| 字段     | 值                                                                                                                                                                                                                            |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 层级     | L0                                                                                                                                                                                                                            |
| 依赖     | 无                                                                                                                                                                                                                            |
| 维度分   | 35                                                                                                                                                                                                                            |
| 缺失章节 | 20 章节缺失（几乎全部）                                                                                                                                                                                                       |
| 已有制品 | prompt/, tasks/, ADR                                                                                                                                                                                                          |
| 迁移步骤 | 目录迁移 → SPEC 大幅补齐（Problem, Goals, Non-goals, FR, BR, Interface, Data Model, Config, Error, Edge, Dir, Deps, Testing, Perf, Obs, Security, CI, Upgrade, Release DoD, Open Questions）→ 创建 goal/matrix/gate/CHANGELOG |
| 预计工时 | 4h                                                                                                                                                                                                                            |
| 验收目标 | 优先 composite ≥85；若无法达标，进入暂停/BLOCKED，记录 Gate verdict + Risk Register，不计入 PASS                                                                                                                              |

### 9.5 ossx

| 字段     | 值                                                         |
| -------- | ---------------------------------------------------------- |
| 层级     | L1                                                         |
| 依赖     | kernel                                                     |
| 维度分   | 38                                                         |
| 缺失章节 | 14 章节缺失                                                |
| 已有制品 | tasks/, ci-workflow.yaml                                   |
| 迁移步骤 | 目录迁移 → SPEC 中度补齐 → 创建 goal/matrix/gate/CHANGELOG |
| 预计工时 | 5h                                                         |
| 验收目标 | 优先 composite ≥85；若无法达标，进入暂停/BLOCKED，记录 Gate verdict + Risk Register，不计入 PASS |

### 9.6 bootstrap

| 字段     | 值                                                    |
| -------- | ----------------------------------------------------- |
| 层级     | L1 Assembly                                           |
| 依赖     | kernel + configx + observex + resiliencx + taosx + postgresx + redisx + kafkax + natsx + ossx + clickhousex |
| 维度分   | 18                                                    |
| 缺失章节 | 23 章节全缺                                           |
| 已有制品 | ci-workflow.yaml                                      |
| 迁移步骤 | 目录迁移 → SPEC 全面重写 → 创建全部制品               |
| 预计工时 | 6h                                                    |
| 验收目标 | 优先 composite ≥85；若无法达标，进入暂停/BLOCKED，记录 Gate verdict + Risk Register，不计入 PASS |

---

## 十、附录：批量迁移脚本模板

> 该脚本只生成迁移脚手架；生成的 `Draft` 状态会被 5.4 对 `goal/`、`spec/`、`design/`、`gate/`、`matrix/`、`schema/` 与 `ci-workflow.yaml` 的占位扫描拦截，必须补齐并清除后才能进入 Gate/PASS。

```bash
#!/usr/bin/env bash
# migrate-module.sh — 单模块目录迁移脚本
# 用法: bash migrate-module.sh <module_name>
set -euo pipefail

MOD="$1"
MOD_DIR="module/$MOD"
ROOT_DIR="$(pwd -P)"

if ! GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "ERROR: run from repository root inside a git worktree"
  exit 1
fi

if [ "$(cd "$GIT_ROOT" && pwd -P)" != "$ROOT_DIR" ]; then
  echo "ERROR: run from repository root: $GIT_ROOT"
  exit 1
fi

CURRENT_BRANCH="$(git branch --show-current)"
if [ -z "$CURRENT_BRANCH" ]; then
  echo "ERROR: detached HEAD; create a module branch/worktree before migration"
  exit 1
fi

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
[ -f IMPLEMENTATION-PLAN.md ] && git mv IMPLEMENTATION-PLAN.md plan/IMPLEMENTATION-PLAN.md
[ -f ACCEPTANCE.md ] && git mv ACCEPTANCE.md spec/ACCEPTANCE.md
[ -f FEATURES.md ] && git mv FEATURES.md spec/FEATURES.md

# 3. 创建缺失制品
[ ! -f CHANGELOG.md ] && printf "# Changelog\n\n## Unreleased\n\n- Initial nested Goal pipeline migration.\n" > CHANGELOG.md
[ ! -f ci-workflow.yaml ] && printf "# CI workflow\n# Status: Draft. Fill required CI gates before PASS.\n" > ci-workflow.yaml
[ ! -f goal/goal.md ] && printf "# Goal\n\nStatus: Draft\n\n## Target\n\n- Migrate %s to nested Goal pipeline layout.\n" "$MOD" > goal/goal.md
if [ ! -f matrix/matrix.yaml ]; then
  cat > matrix/matrix.yaml <<MATRIX
module: $MOD
status: Draft
edges:
  - id: ${MOD}-goal-spec-draft
    from: goal/goal.md
    to: spec/SPEC.md
    type: goal_to_spec
    status: Draft
    release_critical: true
    evidence_id: null
MATRIX
fi
[ ! -f design/DESIGN.md ] && printf "# Design\n\nStatus: Draft\n\n## Decisions\n\n- Nested Goal pipeline layout adopted.\n" > design/DESIGN.md
[ ! -f gate/gate-checklist.md ] && printf "# Gate Checklist\n\nStatus: Draft\n\n- [ ] G0-G11 mapped to CI and Goal Gate evidence.\n" > gate/gate-checklist.md

# 4. 清理旧目录（如 analysis/）
[ -d analysis ] && git mv analysis/ evidence/analysis-archive/

echo "Migration complete for $MOD"
echo "Next steps:"
echo "  1. 补齐 spec/SPEC.md 的 Metadata + Open Questions"
echo "  2. 补齐 goal/goal.md"
echo "  3. 补齐 matrix/matrix.yaml 的非空 canonical edges、release-critical evidence_id、Dropped drop_reason"
echo "  4. 创建/更新 Risk Register；High/Critical 或 release_blocking 风险必须含 Risk ID/Goal ID/Task ID/Type/Description/Probability/Impact/Severity/Trigger/Mitigation/Owner/Status/Linked Gates/Linked Evidence/Release Blocking/Residual Risk/Acceptance/Review Cadence"
echo "  5. 运行: cd \"$ROOT_DIR\" && python3 docs/governance/scoring/rubric-score.py spec $MOD_DIR/spec/SPEC.md"
echo "  6. 运行四源评分并确认 pipeline-arbiter composite_score ≥98 后才可声明 Release PASS"
echo "  7. 更新 module/registry.yaml spec_ref 路径"
echo "  8. 在 Release Manifest 附 Agent protocol evidence"
```

---

_方案生成时间：2026-06-27_
_数据来源：registry.yaml、FOUNDATION-DEPS.yaml、rubric-score.py 批量评分、文件系统扫描_
_复核：Codex native agent team（OMX team 因工作区已有修改未创建 worktree）_
