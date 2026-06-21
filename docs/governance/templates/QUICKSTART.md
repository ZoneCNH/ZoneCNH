# FoundationX 模块全管线快速启动套件

> 目标：让一个全新 agent 在 5 分钟内进入可交付状态。
> 基于 xlibgate Trust Alignment 全管线交付 session（$55.84 / 21 PRs）复盘优化。

---

## 前置条件（Agent 自动执行）

```bash
MODULE=new-module
DATE=$(date +%Y-%m-%d)

# 1. 实例化骨架
mkdir -p module/$MODULE/tasks
for tmpl in SPEC DESIGN PLAN TRACEABILITY; do
  sed "s/{MODULE}/$MODULE/g; s/{DATE}/$DATE/g" \
    docs/governance/templates/module/$tmpl.md.skeleton > module/$MODULE/$tmpl.md
done

# 2. 创建独立 worktree（每个管线阶段一个，路径与分支同名）
for agent in spec design plan tasks matrix prompt; do
  git worktree add /home/$MODULE/.worktree/workspaces/feat/$MODULE-$agent -b feat/$MODULE-$agent origin/main
done
```

## 管线四阶段（Agent 并行执行）

### Phase 1: SPEC + DESIGN + PLAN（3 agents 并行）

| Agent | 产出 | 验证 |
|-------|------|------|
| A: spec-writer | `SPEC.md` — FR/BR/TC/Edge/Error/JSON | `rule-scorer.py spec $MODULE` |
| B: designer | `DESIGN.md` — 架构图/组件/ADR | (无 scoring) |
| C: planner | `PLAN.md` — DAG/Phases/Risks | `rule-scorer.py plan $MODULE` |

### Phase 2: TASKS + MATRIX + PROMPT（3 agents 并行）

| Agent | 产出 | 验证 |
|-------|------|------|
| D: task-splitter | `tasks/TASK-*.md` (N 个) | `rule-scorer.py tasks $MODULE` |
| E: matrix-builder | `TRACEABILITY.md` | `rule-scorer.py matrix $MODULE` |
| F: prompt-builder | `tasks/TASK-*-PROMPT.md` (1 个 consolidated) | `rule-scorer.py prompt $MODULE` |

### Phase 3: CODE（Go 仓库，1 agent）

```
Agent G: go-coder
  工作目录: /home/$MODULE
  输入: PROMPT + SPEC §9.3 (JSON schema)
  产出: internal/*/*.go + *_test.go
  验证: go build + go vet + go test -race
```

### Phase 4: VERIFY + META（2 agents 并行）

| Agent | 产出 |
|-------|------|
| H: lint-verifier | 全管线 100/100 验证 + fix PR |
| I: meta-syncer | ARCHITECTURE + README + STATUS + CHANGELOG |

---

## 关键规则（Agent 必须遵守）

| 规则 | 来源 | 说明 |
|------|------|------|
| **Atomic Write** | CLAUDE.md §成本控制 | 大节 (>20行) 用 Write 不用 Edit |
| **Edit Guard** | .claude/hooks/edit-guard.mjs | >3 Edits 同文件 → 警告 |
| **Consolidated PROMPT** | CLAUDE.md §PROMPT合并 | 同模块多 task → 1 个文件 |
| **Pre-verify sections** | CLAUDE.md §scorer源码 | 读 rule-scorer.py 确认 required sections |
| **YAML 拼接** | CLAUDE.md §测试夹具 | `"key: " + val + "\n"` 不用 raw literal |
| **Trust lint** | CLAUDE.md §信任lint | 100分后不重跑 |
| **Worktree isolation** | CONSTITUTION §0.2 | 每 agent 独立 worktree |
| **Branch check** | CLAUDE.md §分支检查 | commit 前验证 branch + ancestry |
| **Skeleton pre-load** | templates/ | 从骨架实例化，不编辑空文件 |

---

## 成本预期

| 策略 | 成本/模块 |
|------|-----------|
| 串行（无模板，多 Edit） | $50-80 |
| 并行 + 骨架 + Atomic Write | **$8-20** |

---

## 模板文件

```
docs/governance/templates/
├── QUICKSTART.md                   ← 本文件（Agent 入口）
├── module/
│   ├── SPEC.md.skeleton            ← 23 节标准 SPEC 模板
│   ├── DESIGN.md.skeleton          ← 11 节设计模板
│   ├── PLAN.md.skeleton            ← 8 节计划模板
│   └── TRACEABILITY.md.skeleton    ← 7 节追溯矩阵模板
└── orchestration/
    └── PIPELINE-AGENTS.md           ← 详细多 Agent 编排指南
```
