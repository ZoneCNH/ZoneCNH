# Pipeline Multi-Agent Orchestration Guide

> 从本会话 xlibgate Trust Alignment 全管线交付中提取的最佳实践。
> 适用：FoundationX 模块的全管线交付（SPEC → DESIGN → PLAN → TASKS → MATRIX → PROMPT → CODE → TEST → CI → META）。

---

## 前置准备

### 1. 从骨架模板实例化模块

```bash
MODULE=new-module
mkdir -p module/$MODULE/tasks
for f in SPEC.md DESIGN.md PLAN.md TRACEABILITY.md; do
  sed "s/{MODULE}/$MODULE/g; s/{DATE}/$(date +%Y-%m-%d)/g" \
    docs/governance/templates/module/$f.skeleton > module/$MODULE/$f
done
```

### 2. 为每个 Agent 创建独立 worktree

```bash
for agent in spec design plan tasks matrix prompt code lint meta; do
  git worktree add .claude/worktrees/$MODULE-$agent main
done
```

---

## Phase 1: SPEC + DESIGN + PLAN（并行，1 轮）

### Agent A: spec-writer
```
工作目录: .claude/worktrees/$MODULE-spec
输入: goal.md, SPEC.md 骨架
Prompt 要点:
  - 读 CONSTITUTION.md §4.4 (WHEN/THEN 格式)
  - 读 module/$MODULE/goal.md 了解目标
  - 写 FR (WHEN/THEN), BR (约束+违反时), TC (Given/When/Then)
  - 每 FR 至少 2 个 WHEN/THEN
  - 读 rule-scorer.py spec 阶段逻辑, 确保 required 节存在
输出: module/$MODULE/SPEC.md v1.0
验证: python3 scripts/rule-scorer.py spec $MODULE
```

### Agent B: designer
```
工作目录: .claude/worktrees/$MODULE-design
输入: SPEC.md (只读), DESIGN.md 骨架
Prompt 要点:
  - 读 SPEC.md 了解模块功能
  - 画 ASCII 架构图
  - 写组件设计、数据流、ADR、技术风险
  - 不重复 SPEC 中的 FR/BR（引用即可）
输出: module/$MODULE/DESIGN.md v1
```

### Agent C: planner
```
工作目录: .claude/worktrees/$MODULE-plan
输入: SPEC.md (只读), PLAN.md 骨架
Prompt 要点:
  - 读 SPEC.md FR 列表
  - 拆分为独立 Task（无依赖的 → 可并行）
  - 画 DAG
  - 估算工时、识别风险、定义里程碑
输出: module/$MODULE/PLAN.md v1
验证: python3 scripts/rule-scorer.py plan $MODULE
```

---

## Phase 2: TASKS + MATRIX + PROMPT（并行，1 轮）

### Agent D: task-splitter
```
工作目录: .claude/worktrees/$MODULE-tasks
输入: SPEC.md + PLAN.md (只读)
Prompt 要点:
  - 读 SPEC.md AC/TC
  - 读 TASK-XLIBGATE-002.md 作为格式参考
  - 每个 Task 包含: yaml header + Requirements + Non-scope + Test Plan + Implementation Notes
  - 参考 CONSTITUTION.md §17.1 (Prompt 质量标准)
输出: module/$MODULE/tasks/TASK-*.md (N 个)
验证: python3 scripts/rule-scorer.py tasks $MODULE
```

### Agent E: matrix-builder
```
工作目录: .claude/worktrees/$MODULE-matrix
输入: SPEC.md + TASK-*.md (只读)
Prompt 要点:
  - 读 SPEC.md FR/BR/NFR/TC
  - 读 TRACEABILITY.md 现有格式
  - 构建 FR→AC→TC→Task 映射
  - 更新覆盖率仪表盘
输出: module/$MODULE/TRACEABILITY.md v1
验证: python3 scripts/rule-scorer.py matrix $MODULE
```

### Agent F: prompt-builder
```
工作目录: .claude/worktrees/$MODULE-prompt
输入: SPEC.md + TASK-*.md (只读)
Prompt 要点:
  - 读 SPEC.md §9.3 (JSON schema) 和 §7 (FR)
  - 读 TASK-*.md 了解每个 task 的 scope/non-scope/AC
  - **合并为一个 consolidated PROMPT 文件**（节省 token，避免 10 个独立文件）
  - 读 rule-scorer.py prompt 阶段: required sections = [Context, Scope, Non-scope, Acceptance, Validation]
  - 共享部分去重，每 Task 仅保留 Scope + AC + Non-scope 摘要
输出: module/$MODULE/tasks/TASK-$MODULE-TRUST-PROMPT.md (1 个)
验证: python3 scripts/rule-scorer.py prompt $MODULE
```

---

## Phase 3: CODE + TEST（Go 仓库，并行，1-2 轮）

### Agent G: go-coder
```
工作目录: /home/$MODULE (独立仓库)
输入: PROMPT + SPEC.md §9.3 (JSON schema)
Prompt 要点:
  - 读 SPEC.md §7 (FR), §9.3 (JSON schema), §10 (Data Model)
  - 读 internal/trust/common.go 了解现有类型（如适用）
  - 用 go/parser + go/ast (stdlib) 实现 checker
  - 每个 checker 返回统一 Result 类型
  - 三态错误: pass/fail/error (对应 exit 0/1/2)
  - YAML 测试夹具用 fmt.Sprintf 构建，不用 raw string literal
  - 立即执行 go build + go vet
输出: internal/trust/*.go (checkers) + internal/trust/*_test.go (tests)
验证: go build ./... && go vet ./... && go test ./... -race -count=1
```

### Agent H: cli-integrator
```
工作目录: /home/$MODULE (独立仓库)
输入: SPEC.md §9.1 (CLI 命令)
Prompt 要点:
  - 读 cmd/xlibgate/main.go 了解现有 CLI 模式
  - 注册 trust 父命令到 root dispatcher
  - 实现 runTrust + 8 子命令函数
  - 每个子命令: flag 定义 → 参数校验 → checker 调用 → 输出
  - 更新 usage 常量
输出: cmd/xlibgate/main.go (修改)
验证: go build && $BIN trust --help
```

---

## Phase 4: REVIEW + CI + META（并行，1 轮）

### Agent I: lint-verifier
```
任务: 运行全管线 lint → 修复扣分项 → 验证
命令序列:
  for stage in spec matrix tasks plan prompt; do
    python3 scripts/rule-scorer.py $stage $MODULE
  done
  → 任一 < 100: 读错误消息, 修复, 重跑
  → 全部 100: 提交 lint-fix PR
输出: fix PR(如需要)
```

### Agent J: meta-syncer
```
工作目录: .claude/worktrees/$MODULE-meta
输入: SPEC.md (只读)
任务:
  1. STATUS.md: 更新模块版本/进度/描述
  2. ARCHITECTURE.md: 更新描述行 + STATUS 表
  3. README.md: 更新模块描述
  4. CHANGELOG.md: 添加项目结项条目
输出: PR with meta-doc sync
```

---

## 关键规则

| 规则 | 出处 | 说明 |
|------|------|------|
| Atomic Write | Session §1 | 大节改动用 Write 不用 Edit，避免 linter 增量回退 |
| Worktree isolation | CONSTITUTION §0.2 | 每个 agent 独立 worktree，无分支冲突 |
| Consolidated PROMPT | Session §3 | 同模块多 task → 1 个 PROMPT 文件 |
| YAML 拼接 | Session §4 | 测试夹具用 fmt.Sprintf，不用 raw literal |
| Pre-verify section names | Session §5 | 读 rule-scorer.py 源码确认 required sections |
| Code-in-own-repo | CONSTITUTION §2.4 | Go 代码在 /home/$MODULE 仓库，不在 docs repo |
| 不重复验证 | Session §7 | 信任已通过的 lint 结果 |

---

## 预期收益

| 指标 | 串行 (本会话) | 并行 (本指南) |
|------|-------------|-------------|
| Agent 数量 | 1 | 6-8 |
| 轮次 | 53 steps | 4 phases (~5 cycles) |
| 效率 | ~40% 创作 | ~70%+ 创作 |
| Linter 冲突 | 8+ cycles | ~0 (Write + worktree) |
| Git 问题 | 3+ incidents | ~0 (worktree isolation) |
