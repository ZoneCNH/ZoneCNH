---
description: ZoneCNH 工作流统一入口 — 预检、评分、仲裁、仪表盘、快速通道一站完成。
argument-hint: <command> [module] [options]
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# ZoneCNH 工作流

## 快速命令

```bash
# 预检 — 验证工具链是否正常
/workflow preflight

# 评分 — 对模块运行规则评分
/workflow score <module>              # 全 6 阶段
/workflow score <module> --stage spec # 单阶段

# 仲裁 — 运行确定性仲裁器
/workflow arbitrate <module>            # 全 6 阶段
/workflow arbitrate <module> --force    # 缺源不阻塞

# 仪表盘 — 生成/查看模块健康度
/workflow dashboard

# 状态 — 查看模块管线进度
/workflow status <module>

# 快速通道 — 检查模块是否满足快速通道条件
/workflow fast-track <module>
```

## 完整流程

### 1. 首次使用：运行预检

```bash
bash docs/goal/tools/goal-workflow.sh preflight
```

通过标准：Python 编译 3/3 ✅ + Shell 语法 6/6 ✅ + 规则漂移 0 FAIL + Lint 0 ERROR。

### 2. 模块评分

```bash
python3 scripts/rule-scorer.py <stage> <module> --runtime claude
```

六阶段：`spec` `matrix` `tasks` `plan` `prompt` `code`

输出写入 `.omc/state/pipeline/{module}/{stage}/scores/rules.json`。

### 3. 仲裁

```bash
python3 scripts/arbiter.py <module> <stage> --force
```

判定算法（严格按 ARBITER-PROTOCOL.md）：
1. 四源齐全 → 2. 无红线 → 3. composite≥98 → 4. 置信度 high → 5. 分差≤5 → 6. 异构分歧≤15

输出 `verdict.json` + `attempts.json`。

### 4. 仪表盘

```bash
python3 scripts/pipeline-dashboard.py
cat docs/workflow/DASHBOARD.md
```

双源合并 `.foundationx/status/index.json` + `.omc/state/pipeline/`，生成 23 模块可视化仪表盘。

### 5. 快速通道

小型模块（≤3 方法、无内部依赖、纯 library）可声明 `Fast-Track: true`：
- 跳过 Design 阶段
- 单源评分（rules only）
- 门禁 90（正常 98）

详见 `docs/governance/DEVELOPMENT-WORKFLOW.md` §快速通道。

## 门禁公式

```text
composite_score = min(claude.score, codex.score, copilot.score, rules.score) ≥ 98
+ 无红线 + 置信度全 high + LLM 分差 ≤5 + |rules - median(LLM)| ≤15
```

失败上限：同阶段 3 次 / 全链路 18 次。耗尽 → `pipeline_blocked`。

## 管线全景

```
管线 A (Spec→Code):  Spec → Matrix → Tasks → Plan → Prompt → Code
管线 B (Goal→Retro): G0→G1→G2→G3→G4→G5→G6→G7→G8→G9→G10→G11

管线 A ⊂ 管线 B（S1-S6 ≈ G2-G8）
Matrix 为横切制品，贯穿两管线
```

## 关键文档

| 文档 | 用途 |
|------|------|
| `docs/workflow/README.md` | 工作流统一入口 |
| `docs/workflow/DASHBOARD.md` | 模块健康度仪表盘 |
| `docs/governance/DEVELOPMENT-WORKFLOW.md` | 管线定义 SSOT（含快速通道） |
| `docs/governance/STRUCTURAL-SCORING.md` | 四源评分方法论 |
| `docs/governance/scoring/ARBITER-PROTOCOL.md` | 仲裁算法 |
| `docs/goal/03-pipeline.md` | Goal 管线 + 四轴状态模型 |
| `docs/goal/04-gates.md` | G0-G11 Gate 详解 |
| `AGENTS.md` | Agent 矩阵总表 |
| `CONSTITUTION.md` | 最高治理权威 |

## 实现步骤

收到 `/workflow <command>` 后：

1. **preflight**: 运行 `bash docs/goal/tools/goal-workflow.sh preflight`，报告结果。
2. **score**: 对每个阶段运行 `python3 scripts/rule-scorer.py`，汇总评分/红线/置信度。
3. **arbitrate**: 运行 `python3 scripts/arbiter.py`（`--force` 缺源时不阻塞），输出 gate + next_action。
4. **dashboard**: 运行 `python3 scripts/pipeline-dashboard.py`，展示关键指标。
5. **status**: 从 `.omc/state/pipeline/{module}/` 读取各阶段 verdict，生成进度摘要。
6. **fast-track**: 检查 `SPEC.md` 中的 `Fast-Track` 标记 + 3 准入条件，报告是否满足。
