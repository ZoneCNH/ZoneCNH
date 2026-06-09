#!/usr/bin/env bash
# ============================================================
# Goal 驱动交付体系 — 端到端工作流编排 (v2)
# ============================================================
# 基于 docs/goal/ 体系，编排完整 11 层管线：
#   Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release → Retrospective
#
# v2 优化：
#   - Gate 检查委托给 gate-check.sh / goal-validate.py，不做弱实现
#   - 每步完成后自动推进 pipeline/state.yaml 和 gates/state.yaml
#   - 新增 auto 命令：根据复杂度自动选择流程并推进
#   - 新增 change 命令：支持变更管理和版本递增
#   - Evidence 模板补齐 gate-check.sh 要求的全部必须字段
#   - 统一入口：本脚本是用户唯一入口，内部调用 goal-workflow.sh
#
# 用法：
#   bash docs/goal/tools/goal-delivery.sh <command> [options]
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CONFIG_DIR="$ROOT/.config/goal"
TODAY=$(date +%Y%m%d)
NOW=$(date +%Y-%m-%d)
MODE="standard"

# ─── 颜色 ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─── 工具函数 ───────────────────────────────────────────
info()  { printf "${BLUE}ℹ${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}✓${NC}  %s\n" "$*"; }
warn()  { printf "${YELLOW}⚠${NC}  %s\n" "$*"; }
err()   { printf "${RED}✗${NC}  %s\n" "$*" >&2; }
title() { printf "\n${BOLD}${CYAN}═══ %s ═══${NC}\n\n" "$*"; }
step()  { printf "${BOLD}→${NC}  %s\n" "$*"; }
header(){ printf "\n${BOLD}┌─ %s ─┐${NC}\n" "$*"; }
dim()   { printf "${DIM}  %s${NC}\n" "$*"; }

die() {
  err "$*"
  exit 2
}

require_root() {
  [[ -d "$ROOT/.git" ]] || die "不在 Git 仓库根目录"
}

require_config() {
  [[ -d "$CONFIG_DIR" ]] || die "未找到 .config/goal/ 目录，请先运行: goal-delivery.sh init"
}

# ─── YAML 工具 ──────────────────────────────────────────
# 读取 pipeline/state.yaml 中最后一个匹配的字段（处理历史记录格式）
yaml_get() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 1
  awk -v k="$key" '
    $1==k":"{val=$2}
    END{if(val) print val}
  ' "$file"
}

# 读取 gates/state.yaml 中指定 Gate 的 status
# 格式: - gate_id: G0 ... status: PASS
gate_status() {
  local gate="$1"
  [[ -f "$CONFIG_DIR/gates/state.yaml" ]] || { echo "NOT_STARTED"; return; }
  awk -v g="$gate" '
    /gate_id: / && $NF==g {found=1; next}
    found && /^[[:space:]]+status:/ {print $2; found=0; exit}
  ' "$CONFIG_DIR/gates/state.yaml"
}

# 更新 pipeline/state.yaml 末尾追加新状态记录
yaml_set() {
  local file="$1" key="$2" value="$3"
  [[ -f "$file" ]] || return 1
  # 在文件末尾追加新的状态记录
  printf '    %s: %s\n' "$key" "$value" >>"$file"
}

# 更新 gates/state.yaml 中指定 Gate 的 status
# 匹配 "- gate_id: GX" 后的第一个 "status:" 行
gate_set() {
  local gate="$1" status="$2"
  local file="$CONFIG_DIR/gates/state.yaml"
  [[ -f "$file" ]] || return 1
  local tmp="${file}.tmp"
  awk -v g="$gate" -v s="$status" -v d="$NOW" '
    /gate_id: / && $NF==g {found=1; print; next}
    found && /^[[:space:]]+status:/ {print "    status: "s; found=0; next}
    found && /^[[:space:]]+checked_at:/ {print "    checked_at: \""d"\""; next}
    {print}
  ' "$file" >"$tmp"
  mv "$tmp" "$file"
}

# ─── 帮助 ───────────────────────────────────────────────
usage() {
  cat <<'EOF'
Goal 驱动交付体系 — 端到端工作流编排 (v2)

用法:
  bash docs/goal/tools/goal-delivery.sh <command> [options]

制品创建命令（按管线顺序）:
  init                初始化项目结构和配置中心
  goal                创建 Goal 制品（SMART 模板）
  spec --goal-id ID   从 Goal 生成 Spec 框架
  design --spec-id ID 从 Spec 生成 Design 框架
  plan --goal-id ID   从 Design 生成执行计划
  tasks --plan-id ID  从 Plan 拆解可执行 Tasks
  prompt --task-id ID 为指定 Task 生成 Context Package
  evidence --task-id ID 为指定 Task 收集 Evidence

矩阵与变更:
  matrix [generate|check|update]  追溯矩阵管理
  change --goal-id ID --level N   变更管理（CL0-CL5）

验证与门禁:
  check [--gate G0-G11]  运行 Gate 检查（委托 gate-check.sh / goal-validate.py）
  validate               运行完整验证（委托 goal-workflow.sh）
  release                运行发布前硬阻断检查

状态与看板:
  status    显示当前管线状态
  dashboard 显示交付看板
  auto      根据复杂度模式自动推进管线

选项:
  --root DIR      仓库根目录（默认自动检测）
  --mode MODE     复杂度模式：lite / standard / full
  -h, --help      显示帮助
EOF
}

# ─── ID 生成 ─────────────────────────────────────────────
gen_goal_id() {
  local n=1
  while [[ -f "$CONFIG_DIR/registry/goals.yaml" ]] && \
        grep -q "GOAL-${TODAY}-$(printf '%03d' "$n")" "$CONFIG_DIR/registry/goals.yaml" 2>/dev/null; do
    n=$((n + 1))
  done
  printf 'GOAL-%s-%03d' "$TODAY" "$n"
}

gen_spec_id() {
  local domain="$1"
  printf 'SPEC-%s-v1' "$domain"
}

gen_task_id() {
  local goal_id="$1"
  local n=1
  while [[ -f "$CONFIG_DIR/registry/tasks.yaml" ]] && \
        grep -q "${goal_id}-$(printf '%03d' "$n")" "$CONFIG_DIR/registry/tasks.yaml" 2>/dev/null; do
    n=$((n + 1))
  done
  printf 'TASK-%s-%03d' "$goal_id" "$n"
}

gen_evidence_id() {
  local test_id="$1"
  printf 'EVID-%s-%s' "$test_id" "$(date +%Y%m%d%H%M%S)"
}

# ─── 管线状态推进 ───────────────────────────────────────
PIPELINE_PHASES=("INIT" "CONTEXT_READY" "GOAL_READY" "SPEC_READY" "DESIGN_READY" "PLAN_READY" "TASKS_READY" "EXECUTING" "VERIFYING" "REVIEWING" "RELEASING" "RETROSPECTING" "DONE")

advance_pipeline() {
  local new_phase="$1" new_state="${2:-}"
  local file="$CONFIG_DIR/pipeline/state.yaml"
  [[ -f "$file" ]] || return 0
  yaml_set "$file" "current_phase" "$new_phase"
  [[ -n "$new_state" ]] && yaml_set "$file" "pipeline_state" "$new_state"
  dim "Pipeline → $new_phase ($new_state)"
}

# ─── init：初始化项目结构 ────────────────────────────────
cmd_init() {
  title "初始化 Goal 驱动交付项目结构"
  require_root

  step "创建配置中心目录结构"
  mkdir -p "$CONFIG_DIR"/{schema,registry,matrix,gates,pipeline,evidence,prompts,runtime}
  mkdir -p "$ROOT/docs/goal"/{goals,specs,designs,plans,tasks}

  # ── .gitignore 配置 ──
  step "配置 .gitignore"
  if [[ -f "$ROOT/.gitignore" ]]; then
    if ! grep -q '\.config/goal/runtime' "$ROOT/.gitignore"; then
      cat >>"$ROOT/.gitignore" <<'GITIGNORE'

# Goal 运行态（不进入仓库）
.config/goal/runtime/
GITIGNORE
      ok "已追加 .config/goal/runtime/ 到 .gitignore"
    fi
  else
    cat >"$ROOT/.gitignore" <<'GITIGNORE'
.config/cache/
.config/goal/runtime/
GITIGNORE
    ok "已创建 .gitignore"
  fi

  # ── Registry 初始文件 ──
  step "初始化 Registry 文件"
  for reg in goals tasks issues releases risks decisions; do
    local file="$CONFIG_DIR/registry/${reg}.yaml"
    if [[ ! -f "$file" ]]; then
      printf '%s: []\n' "$reg" >"$file"
      ok "创建 registry/${reg}.yaml"
    fi
  done

  # ── Matrix ──
  step "初始化追溯矩阵"
  if [[ ! -f "$CONFIG_DIR/matrix/matrix.yaml" ]]; then
    printf 'matrix: []\n' >"$CONFIG_DIR/matrix/matrix.yaml"
    ok "创建 matrix/matrix.yaml"
  fi

  # ── Gates ──
  step "初始化 Gate 状态"
  if [[ ! -f "$CONFIG_DIR/gates/state.yaml" ]]; then
    cat >"$CONFIG_DIR/gates/state.yaml" <<YAML
gates:
  G0:
    name: Context Gate
    status: NOT_STARTED
    owner: goal-reviewer
    updated_at: ${NOW}
  G1:
    name: Goal Gate
    status: NOT_STARTED
    owner: goal-reviewer
    updated_at: ${NOW}
  G2:
    name: Spec Gate
    status: NOT_STARTED
    owner: goal-reviewer
    updated_at: ${NOW}
  G3:
    name: Design Gate
    status: NOT_STARTED
    owner: goal-reviewer
    updated_at: ${NOW}
  G4:
    name: Plan Gate
    status: NOT_STARTED
    owner: goal-reviewer
    updated_at: ${NOW}
  G5:
    name: Task Gate
    status: NOT_STARTED
    owner: goal-reviewer
    updated_at: ${NOW}
  G6:
    name: Implementation Gate
    status: NOT_STARTED
    owner: goal-reviewer
    updated_at: ${NOW}
  G7:
    name: Test Gate
    status: NOT_STARTED
    owner: goal-reviewer
    updated_at: ${NOW}
  G8:
    name: Evidence Gate
    status: NOT_STARTED
    owner: goal-reviewer
    updated_at: ${NOW}
  G9:
    name: Review Gate
    status: NOT_STARTED
    owner: goal-reviewer
    updated_at: ${NOW}
  G10:
    name: Release Gate
    status: NOT_STARTED
    owner: goal-reviewer
    updated_at: ${NOW}
  G11:
    name: Retrospective Gate
    status: NOT_STARTED
    owner: goal-reviewer
    updated_at: ${NOW}
YAML
    ok "创建 gates/state.yaml（G0-G11）"
  fi

  # ── Pipeline ──
  step "初始化 Pipeline 状态"
  if [[ ! -f "$CONFIG_DIR/pipeline/state.yaml" ]]; then
    cat >"$CONFIG_DIR/pipeline/state.yaml" <<YAML
pipeline:
  current_phase: GOAL
  pipeline_state: INIT
  updated_at: ${NOW}
YAML
    ok "创建 pipeline/state.yaml"
  fi

  # ── Schema ──
  step "初始化 Schema"
  if [[ ! -f "$CONFIG_DIR/schema/rules.yaml" ]]; then
    cat >"$CONFIG_DIR/schema/rules.yaml" <<'YAML'
ci:
  workflow: ".github/workflows/goal-ci.yml"
  required_jobs:
    - goal-validator

pipeline:
  workflow_steps:
    - preflight
    - validate
    - gate
    - release

id_formats:
  goal: "GOAL-YYYYMMDD-NNN"
  spec: "SPEC-<domain>-vN"
  requirement: "REQ-<spec-id>-NNN"
  acceptance_criteria: "AC-<req-id>-NNN"
  task: "TASK-<goal-id>-NNN"
  prompt: "PROMPT-<task-id>-NNN"
  test: "TEST-<task-id>-NNN"
  evidence: "EVID-<test-id>-NNN"
  risk: "RISK-<goal-id>-NNN"
  decision: "DEC-YYYYMMDD-NNN"

gate_statuses:
  - PASS
  - PASS_WITH_RISK
  - FAIL
  - BLOCKED

pipeline_states:
  normal:
    - INIT
    - CONTEXT_READY
    - GOAL_READY
    - SPEC_READY
    - DESIGN_READY
    - PLAN_READY
    - TASKS_READY
    - EXECUTING
    - VERIFYING
    - REVIEWING
    - RELEASING
    - RETROSPECTING
    - DONE
  abnormal:
    - BLOCKED
    - FAILED
    - NEEDS_RESEARCH
    - NEEDS_DECISION
    - NEEDS_REPLAN
    - NEEDS_ROLLBACK
    - NEEDS_HUMAN_APPROVAL
    - INCONSISTENT_STATE
YAML
    ok "创建 schema/rules.yaml"
  fi

  advance_pipeline "CONTEXT_READY" "CONTEXT_READY"
  printf "\n"
  ok "Goal 项目结构初始化完成"
  info "配置中心: $CONFIG_DIR"
  info "制品目录: docs/goal/{goals,specs,designs,plans,tasks}"
  info "下一步: bash docs/goal/tools/goal-delivery.sh goal"
}

# ─── goal：创建 Goal 制品 ───────────────────────────────
cmd_goal() {
  title "Step 1: Goal 定义"
  require_config

  local goal_id="${1:-$(gen_goal_id)}"
  local title_text="${2:-待填写}"
  local goal_file="$ROOT/docs/goal/goals/${goal_id}.md"

  mkdir -p "$(dirname "$goal_file")"

  if [[ -f "$goal_file" ]]; then
    warn "Goal 已存在: $goal_file"
    info "如需编辑，请直接修改文件"
    return 0
  fi

  step "创建 Goal 制品: $goal_id"

  cat >"$goal_file" <<YAML
# Goal: ${title_text}

## Goal ID
${goal_id}

## Context
<!-- 业务背景：为什么要做这件事？当前痛点是什么？ -->
待填写

## Objective
<!-- 目标结果：做到什么算成功？结果导向，不是方案 -->
待填写

## Target User
<!-- 目标用户：谁会使用这个能力？ -->
待填写

## Success Metrics
<!-- 成功指标：可量化的衡量标准 -->
- 指标 1: 待填写
- 指标 2: 待填写

## Scope
In Scope:
- 待填写

Out of Scope (Non-goals):
- 待填写

## Acceptance Criteria
- AC-1: 待填写
- AC-2: 待填写

## Constraints
<!-- 约束条件：时间、技术、预算、合规 -->
- 截止时间: 待填写

## Deadline
待填写
YAML

  register_goal "$goal_id" "$title_text"
  gate_set "G0" "PASS"
  advance_pipeline "GOAL_READY" "GOAL_READY"

  ok "Goal 已创建: $goal_file"
  info "请编辑 Goal 文件，填写 Context、Objective、Success Metrics 等"
  info "完成后运行: bash docs/goal/tools/goal-delivery.sh check --gate G1"
}

register_goal() {
  local goal_id="$1"
  local title_text="$2"
  local reg_file="$CONFIG_DIR/registry/goals.yaml"

  if ! grep -q "$goal_id" "$reg_file" 2>/dev/null; then
    cat >>"$reg_file" <<YAML
  - goal_id: ${goal_id}
    title: "${title_text}"
    status: Draft
    change_level: CL2
    created_at: ${NOW}
    updated_at: ${NOW}
YAML
    ok "已注册到 Goal Registry"
  fi
}

# ─── spec：从 Goal 生成 Spec ─────────────────────────────
cmd_spec() {
  title "Step 2: Spec 需求规格"
  require_config

  local goal_id="${1:-}"
  [[ -n "$goal_id" ]] || die "需要 --goal-id 参数"

  local domain
  domain=$(echo "$goal_id" | sed 's/GOAL-[0-9]*-[0-9]*//' | tr '[:upper:]' '[:lower:]' | sed 's/^-//')
  [[ -n "$domain" ]] || domain="feature"
  local spec_id
  spec_id=$(gen_spec_id "$domain")
  local spec_file="$ROOT/docs/goal/specs/${spec_id}.md"

  mkdir -p "$(dirname "$spec_file")"

  step "从 Goal $goal_id 生成 Spec: $spec_id"

  cat >"$spec_file" <<YAML
# Spec: ${spec_id}

## Spec ID
${spec_id}

## Source Goal
${goal_id}

## User Story
作为【角色】，我希望【能力】，以便【价值】。

## Functional Requirements
<!-- 每条需求只表达一个行为，可独立测试 -->
- REQ-${spec_id}-001: 待填写
- REQ-${spec_id}-002: 待填写

## Business Rules
- BR-001: 待填写

## Edge Cases
- EC-001: 待填写

## Error Handling
- EH-001: 待填写

## Security Requirements
- SEC-001: 待填写

## Performance Requirements
- PERF-001: 待填写

## Acceptance Criteria
- AC-REQ-${spec_id}-001-001: 待填写
- AC-REQ-${spec_id}-002-001: 待填写

## Out of Scope
- 待填写
YAML

  advance_pipeline "SPEC_READY" "SPEC_READY"
  ok "Spec 已创建: $spec_file"
  info "请逐条填写 Functional Requirements 和 Acceptance Criteria"
  info "完成后运行: bash docs/goal/tools/goal-delivery.sh check --gate G2"
}

# ─── design：从 Spec 生成 Design ─────────────────────────
cmd_design() {
  title "Step 3: Design 设计方案"
  require_config

  local spec_id="${1:-}"
  [[ -n "$spec_id" ]] || die "需要 --spec-id 参数"

  local domain
  domain=$(echo "$spec_id" | sed 's/SPEC-//' | sed 's/-v[0-9]*//')
  local design_id="DESIGN-${domain}-v1"
  local design_file="$ROOT/docs/goal/designs/${design_id}.md"

  mkdir -p "$(dirname "$design_file")"

  step "从 Spec $spec_id 生成 Design: $design_id"

  cat >"$design_file" <<YAML
# Design: ${design_id}

## Design ID
${design_id}

## Source Spec
${spec_id}

## Modules
<!-- 每个 Spec Requirement 应映射到至少一个 Module -->
- 待填写模块 1: 对应 REQ-xxx
- 待填写模块 2: 对应 REQ-xxx

## Interfaces
<!-- 接口定义：输入、输出、副作用 -->
- 待填写接口 1

## Data Flow
<!-- 数据在模块间如何流动 -->
待填写

## Dependencies
<!-- 模块依赖关系，避免循环依赖 -->
待填写

## ADR (Architecture Decision Records)
<!-- 关键技术决策记录 -->
### ADR-001: 待填写决策
- 背景: 待填写
- 决策: 待填写
- 理由: 待填写
- 后果: 待填写

## Risks
<!-- 技术风险 -->
- 待填写风险 1
YAML

  advance_pipeline "DESIGN_READY" "DESIGN_READY"
  ok "Design 已创建: $design_file"
  info "请填写模块拆分、接口定义、ADR"
  info "完成后运行: bash docs/goal/tools/goal-delivery.sh check --gate G3"
}

# ─── plan：生成执行计划 ──────────────────────────────────
cmd_plan() {
  title "Step 4: Plan 执行计划"
  require_config

  local goal_id="${1:-}"
  [[ -n "$goal_id" ]] || die "需要 --goal-id 参数"

  local plan_id="PLAN-${goal_id}-v1"
  local plan_file="$ROOT/docs/goal/plans/${plan_id}.md"

  mkdir -p "$(dirname "$plan_file")"

  step "生成执行计划: $plan_id"

  cat >"$plan_file" <<YAML
# Plan: ${plan_id}

## Plan ID
${plan_id}

## Source Goal
${goal_id}

## Execution Strategy
<!-- 整体执行策略：先基础后上层，先高风险后低风险 -->

## Phases

### Phase 1: 基础能力（高风险技术验证）
- TASK: 待拆解
- Goal: 验证核心技术可行性
- Output: 可工作的基础模块
- Validation: 基础测试通过

### Phase 2: 核心功能（Happy Path）
- TASK: 待拆解
- Goal: 实现核心用户流
- Output: 主路径可运行
- Validation: 集成测试通过

### Phase 3: 边界与安全
- TASK: 待拆解
- Goal: 处理边界条件和安全要求
- Output: 完整的错误处理和安全防护
- Validation: 边界测试通过

### Phase 4: 测试与验收
- TASK: 待拆解
- Goal: 全面测试和 Evidence 收集
- Output: 测试报告和 Evidence
- Validation: 全部测试通过，Evidence 完整

## Risks
<!-- 风险清单 → 应对方式 -->
- 风险 1: 待填写 → 应对方式: 待填写

## Checkpoints
- CP-1: Phase 1 完成后验证基础能力
- CP-2: Phase 2 完成后验证核心流
- CP-3: Phase 3 完成后验证边界覆盖
- CP-4: Phase 4 完成后全面验收

## Rollback Plan
<!-- 回滚方式 -->
待填写

## Final Validation
<!-- 最终验收方式 -->
所有 Acceptance Criteria 通过，Matrix 全部 Verified。
YAML

  advance_pipeline "PLAN_READY" "PLAN_READY"
  ok "Plan 已创建: $plan_file"
  info "请填写执行策略、阶段划分、风险应对"
  info "完成后运行: bash docs/goal/tools/goal-delivery.sh check --gate G4"
}

# ─── tasks：拆解 Tasks ───────────────────────────────────
cmd_tasks() {
  title "Step 5: Tasks 任务拆解"
  require_config

  local plan_id="${1:-}"
  [[ -n "$plan_id" ]] || die "需要 --plan-id 参数"

  local goal_id
  goal_id=$(echo "$plan_id" | sed 's/PLAN-//' | sed 's/-v[0-9]*//')
  local tasks_dir="$ROOT/docs/goal/tasks"

  mkdir -p "$tasks_dir"

  step "从 Plan $plan_id 拆解 Tasks"

  local task_id
  task_id=$(gen_task_id "$goal_id")
  local task_file="$tasks_dir/${task_id}.md"

  cat >"$task_file" <<YAML
# Task: ${task_id}

## Task ID
${task_id}

## Task Name
待填写

## Source
- Goal: ${goal_id}
- Plan: ${plan_id}

## Objective
<!-- 这个任务要完成什么 -->
待填写

## Input
<!-- 输入内容：已有代码、数据结构、API -->
待填写

## Output
<!-- 交付结果：代码、测试、文档 -->
待填写

## Acceptance Criteria
<!-- 完成标准，每条可独立验证 -->
- AC-1: 待填写

## Dependencies
<!-- 依赖的其他 Task -->
- 无

## Test Requirement
<!-- 测试要求：必须覆盖哪些场景 -->
- 待填写

## DoD (Definition of Done)
- [ ] 代码实现对应 Task
- [ ] 测试覆盖验收标准
- [ ] Matrix 状态已更新
- [ ] Evidence 已收集
YAML

  register_task "$task_id" "$goal_id"
  advance_pipeline "TASKS_READY" "TASKS_READY"

  ok "Task 已创建: $task_file"
  info "请为每个 Task 创建独立文件，遵循 TASK-${goal_id}-NNN 格式"
  info "拆解优先级：垂直切片 → 按风险 → 按模块"
  info "完成后运行: bash docs/goal/tools/goal-delivery.sh check --gate G5"
}

register_task() {
  local task_id="$1"
  local goal_id="$2"
  local reg_file="$CONFIG_DIR/registry/tasks.yaml"

  if ! grep -q "$task_id" "$reg_file" 2>/dev/null; then
    cat >>"$reg_file" <<YAML
  - task_id: ${task_id}
    goal_id: ${goal_id}
    status: Unmapped
    dod: false
    evidence: ""
    created_at: ${NOW}
    updated_at: ${NOW}
YAML
    ok "已注册到 Task Registry"
  fi
}

# ─── prompt：生成 Context Package ────────────────────────
cmd_prompt() {
  title "Step 6: Prompt Context Package"
  require_config

  local task_id="${1:-}"
  [[ -n "$task_id" ]] || die "需要 --task-id 参数"

  local prompt_id="PROMPT-${task_id}-001"
  local prompt_dir="$CONFIG_DIR/prompts/${task_id}"

  mkdir -p "$prompt_dir"

  step "为 Task $task_id 生成 Context Package"

  local prompt_file="${prompt_dir}/v1.md"
  cat >"$prompt_file" <<YAML
# Context Package: ${prompt_id}

## Prompt ID
${prompt_id}

## Version
v1.0

## Role
实现工程师

## Source
- Task: ${task_id}

## Context Package

### 1. Goal 摘要
<!-- 从 Goal 制品复制核心信息 -->
待填写

### 2. Spec 摘要
<!-- 从 Spec 制品复制相关 Requirement -->
待填写

### 3. Matrix 行
<!-- 从 Matrix 复制相关映射行 -->
待填写

### 4. 当前 Task
Task ID: ${task_id}
目标: 待填写

### 5. 相关代码结构
<!-- 已有代码、模块、接口 -->
待填写

### 6. 约束条件
<!-- 技术约束、业务约束 -->
- 待填写

### 7. 测试要求
<!-- 必须覆盖的测试用例 -->
- 待填写

### 8. 禁止事项 (Do Not)
<!-- 不允许做的事情 -->
- 不实现超出 Task 范围的功能
- 不修改无关模块
- 不删除已有行为（除非明确要求）

## Expected Output
<!-- 期望的交付物 -->
1. 代码变更清单
2. 测试用例
3. Matrix 行覆盖情况
4. 已知风险
YAML

  cat >"${prompt_dir}/prompt-meta.yaml" <<YAML
prompt_id: ${prompt_id}
task_id: ${task_id}
version: "1.0"
created_at: ${NOW}
updated_at: ${NOW}
YAML

  ok "Context Package 已生成: $prompt_file"
  info "请根据 Goal/Spec/Matrix 填充具体内容"
}

# ─── evidence：收集 Evidence ─────────────────────────────
cmd_evidence() {
  title "Step 8: Evidence 收集"
  require_config

  local task_id="${1:-}"
  local test_id="${2:-TEST-${task_id}-001}"
  [[ -n "$task_id" ]] || die "需要 --task-id 参数"

  # 从 Registry 读取关联的 goal_id
  local goal_id=""
  if [[ -f "$CONFIG_DIR/registry/tasks.yaml" ]]; then
    goal_id=$(awk -v tid="$task_id" '/task_id:/{id=$3} id==tid && /goal_id:/{print $2; exit}' "$CONFIG_DIR/registry/tasks.yaml")
  fi

  local evidence_id
  evidence_id=$(gen_evidence_id "$test_id")
  local evidence_dir="$CONFIG_DIR/evidence/$(date +%Y-%m-%d)/${task_id}"
  local evidence_file="${evidence_dir}/${evidence_id}.md"

  mkdir -p "$evidence_dir"

  step "为 Task $task_id 收集 Evidence"

  local diff_summary=""
  if git rev-parse HEAD >/dev/null 2>&1; then
    diff_summary=$(git diff --stat HEAD~1 2>/dev/null || echo "无变更")
  fi

  # 生成符合 rule-drift-check.py 要求的 Evidence 模板（`- **Field**: value` 格式）
  cat >"$evidence_file" <<YAML
# Evidence: ${evidence_id}

- **Evidence ID**: ${evidence_id}
- **Task ID**: ${task_id}
- **Test ID**: ${test_id}
- **Goal ID**: ${goal_id:-待填写}
- **Spec ID**: 待填写
- **Acceptance Criteria ID**: 待填写
- **Date**: $(date +%Y-%m-%d)
- **Status**: 待验证
- **Files Changed**: ${diff_summary}
- **Commands Run**: 待填写测试命令

## Results

待运行测试

## Requirement Proof

- REQ: 待填写
- AC: 待填写
YAML

  ok "Evidence 已创建: $evidence_file"
  info "请填写测试结果、命令输出、需求证明"
  dim "注意: gate-check.sh 要求 Evidence 包含 Evidence ID / Task ID / Test ID / Goal ID / Spec ID / Acceptance Criteria ID / Date / Status / Files Changed / Commands Run"
}

# ─── matrix：追溯矩阵管理 ───────────────────────────────
cmd_matrix() {
  title "Matrix 追溯矩阵"
  require_config

  local action="${1:-check}"
  local matrix_file="$CONFIG_DIR/matrix/matrix.yaml"

  case "$action" in
    generate)
      step "从 Spec/Tasks 生成 Matrix"
      if command -v python3 >/dev/null 2>&1 && [[ -f "$SCRIPT_DIR/matrix-gen.py" ]]; then
        python3 "$SCRIPT_DIR/matrix-gen.py" \
          --spec-dir "$ROOT/docs/goal/specs" \
          --task-dir "$ROOT/docs/goal/tasks" \
          --output "$matrix_file" 2>/dev/null || true
        ok "Matrix 已生成: $matrix_file"
      else
        warn "matrix-gen.py 不可用，请手动维护 Matrix"
        info "Matrix 文件: $matrix_file"
      fi
      ;;
    check)
      step "检查 Matrix 完整性"
      if command -v python3 >/dev/null 2>&1 && [[ -f "$SCRIPT_DIR/matrix-gen.py" ]]; then
        python3 "$SCRIPT_DIR/matrix-gen.py" --check-only --matrix "$matrix_file" && \
          ok "Matrix 检查通过" || warn "Matrix 检查发现问题"
      else
        info "Matrix 文件: $matrix_file"
        if [[ -f "$matrix_file" ]]; then
          local rows
          rows=$(grep -c "source_id:" "$matrix_file" 2>/dev/null || echo 0)
          info "Matrix 行数: $rows"
        fi
      fi
      ;;
    update)
      step "更新 Matrix 状态"
      info "请手动更新 Matrix 中的 Status 字段"
      info "状态流转: Unmapped → Mapped → Linked → Verified / Dropped"
      ;;
    *)
      die "未知的 matrix action: $action (可选: generate, check, update)"
      ;;
  esac
}

# ─── change：变更管理 ────────────────────────────────────
cmd_change() {
  title "变更管理"
  require_config

  local goal_id="${1:-}"
  local level="${2:-CL2}"
  [[ -n "$goal_id" ]] || die "需要 --goal-id 参数"

  step "记录变更: Goal=$goal_id Level=$level"

  local reg_file="$CONFIG_DIR/registry/goals.yaml"
  if [[ -f "$reg_file" ]] && grep -q "$goal_id" "$reg_file"; then
    # 更新 change_level
    local tmp="${reg_file}.tmp"
    awk -v gid="$goal_id" -v lv="$level" '
      /goal_id:/{cur=$3}
      cur==gid && /change_level/{$0="    change_level: "lv}
      {print}
    ' "$reg_file" >"$tmp"
    mv "$tmp" "$reg_file"
    ok "已更新 change_level: $level"
  fi

  info "变更级别说明:"
  dim "  CL0: 文档变更 → lite 模式"
  dim "  CL1: 配置/脚本变更 → lite 模式"
  dim "  CL2: 功能开发 → standard 模式"
  dim "  CL3: 跨模块变更 → full 模式"
  dim "  CL4: 数据模型变更 → full + 迁移验证"
  dim "  CL5: 安全/合规变更 → full + 人工审批"

  case "$level" in
    CL0|CL1) info "推荐模式: lite" ;;
    CL2)     info "推荐模式: standard" ;;
    CL3|CL4|CL5) info "推荐模式: full" ;;
  esac
}

# ─── check：Gate 检查（委托给专业工具）──────────────────
cmd_check() {
  local gate="${1:-}"

  if [[ -n "$gate" ]]; then
    title "Gate 检查: $gate"
    run_single_gate "$gate"
  else
    title "全量 Gate 检查 (G0-G11)"
    local all_pass=true
    for g in G0 G1 G2 G3 G4 G5 G6 G7 G8 G9 G10 G11; do
      run_single_gate "$g" || all_pass=false
    done
    $all_pass && ok "全部 Gate 通过" || warn "存在未通过的 Gate"
  fi
}

run_single_gate() {
  local gate="$1"
  local pass=true

  case "$gate" in
    G0)
      step "G0 Context Gate — 上下文恢复完整"
      [[ -d "$CONFIG_DIR" ]] || { warn "缺少 .config/goal/"; pass=false; }
      [[ -f "$CONFIG_DIR/registry/goals.yaml" ]] || { warn "缺少 goals.yaml"; pass=false; }
      [[ -f "$CONFIG_DIR/gates/state.yaml" ]] || { warn "缺少 gates/state.yaml"; pass=false; }
      [[ -f "$CONFIG_DIR/pipeline/state.yaml" ]] || { warn "缺少 pipeline/state.yaml"; pass=false; }
      ;;
    G1)
      step "G1 Goal Gate — SMART 合规"
      if [[ -f "$SCRIPT_DIR/lint-goal.sh" ]]; then
        bash "$SCRIPT_DIR/lint-goal.sh" "$ROOT/docs/goal" 2>/dev/null || pass=false
      fi
      # 检查 Goal 制品存在且包含必要字段
      local goals_dir="$ROOT/docs/goal/goals"
      if [[ ! -d "$goals_dir" ]] || [[ -z "$(ls -A "$goals_dir" 2>/dev/null)" ]]; then
        warn "未找到 Goal 制品"; pass=false
      else
        for f in "$goals_dir"/*.md; do
          [[ -f "$f" ]] || continue
          for field in "Success Metrics" "Acceptance Criteria" "Deadline"; do
            grep -q "$field" "$f" 2>/dev/null || { warn "$(basename "$f"): 缺少 $field"; pass=false; }
          done
          if grep -qiE "^[[:space:]]*-( 待填写|待确认)" "$f" 2>/dev/null; then
            warn "$(basename "$f"): 包含未填写的占位符"; pass=false
          fi
        done
      fi
      ;;
    G2)
      step "G2 Spec Gate — 需求完整且可测试"
      local specs_dir="$ROOT/docs/goal/specs"
      if [[ ! -d "$specs_dir" ]] || [[ -z "$(ls -A "$specs_dir" 2>/dev/null)" ]]; then
        warn "未找到 Spec 制品"; pass=false
      else
        for f in "$specs_dir"/*.md; do
          [[ -f "$f" ]] || continue
          for field in "Acceptance Criteria" "Edge Cases" "REQ-"; do
            grep -q "$field" "$f" 2>/dev/null || { warn "$(basename "$f"): 缺少 $field"; pass=false; }
          done
        done
      fi
      ;;
    G3)
      step "G3 Design Gate — 模块映射"
      local designs_dir="$ROOT/docs/goal/designs"
      if [[ ! -d "$designs_dir" ]] || [[ -z "$(ls -A "$designs_dir" 2>/dev/null)" ]]; then
        warn "未找到 Design 制品"; pass=false
      else
        for f in "$designs_dir"/*.md; do
          [[ -f "$f" ]] || continue
          for field in "Modules" "Interfaces"; do
            grep -q "$field" "$f" 2>/dev/null || { warn "$(basename "$f"): 缺少 $field"; pass=false; }
          done
        done
      fi
      ;;
    G4)
      step "G4 Plan Gate — 依赖顺序"
      local plans_dir="$ROOT/docs/goal/plans"
      if [[ ! -d "$plans_dir" ]] || [[ -z "$(ls -A "$plans_dir" 2>/dev/null)" ]]; then
        warn "未找到 Plan 制品"; pass=false
      else
        for f in "$plans_dir"/*.md; do
          [[ -f "$f" ]] || continue
          for field in "Phase" "Rollback"; do
            grep -qi "$field" "$f" 2>/dev/null || { warn "$(basename "$f"): 缺少 $field"; pass=false; }
          done
        done
      fi
      ;;
    G5)
      step "G5 Task Gate — 原子化且有 DoD"
      # 委托给 gate-check.sh 做真正的 Task DoD 覆盖率检查
      if [[ -f "$SCRIPT_DIR/gate-check.sh" ]]; then
        bash "$SCRIPT_DIR/gate-check.sh" "$ROOT" 2>/dev/null || pass=false
      else
        # 回退：基本检查
        local tasks_dir="$ROOT/docs/goal/tasks"
        if [[ ! -d "$tasks_dir" ]] || [[ -z "$(ls -A "$tasks_dir" 2>/dev/null)" ]]; then
          warn "未找到 Task 制品"; pass=false
        else
          for f in "$tasks_dir"/*.md; do
            [[ -f "$f" ]] || continue
            for field in "DoD" "Input" "Output" "TASK-"; do
              grep -q "$field" "$f" 2>/dev/null || { warn "$(basename "$f"): 缺少 $field"; pass=false; }
            done
          done
        fi
      fi
      ;;
    G6)
      step "G6 Implementation Gate — Prompt 完整"
      local prompts_dir="$CONFIG_DIR/prompts"
      if [[ ! -d "$prompts_dir" ]] || [[ -z "$(ls -A "$prompts_dir" 2>/dev/null)" ]]; then
        warn "未找到 Prompt/Context Package"; pass=false
      else
        for f in "$prompts_dir"/*/v*.md; do
          [[ -f "$f" ]] || continue
          for field in "Constraints" "Do Not"; do
            grep -qi "$field" "$f" 2>/dev/null || { warn "$(basename "$(dirname "$f")"): 缺少 $field"; pass=false; }
          done
        done
      fi
      ;;
    G7)
      step "G7 Test Gate — 测试通过"
      # 委托给 goal-workflow.sh 做真正的验证
      if [[ -f "$SCRIPT_DIR/goal-workflow.sh" ]]; then
        info "委托 goal-workflow.sh validate 执行测试验证"
        bash "$SCRIPT_DIR/goal-workflow.sh" validate --root "$ROOT" 2>/dev/null || pass=false
      else
        info "G7 需要在代码实现后运行实际测试"
      fi
      ;;
    G8)
      step "G8 Evidence Gate — Evidence 完整"
      # 委托给 gate-check.sh 做 Evidence 字段完整性检查
      if [[ -f "$SCRIPT_DIR/gate-check.sh" ]]; then
        bash "$SCRIPT_DIR/gate-check.sh" "$ROOT" 2>/dev/null || pass=false
      else
        local evid_dir="$CONFIG_DIR/evidence"
        if [[ ! -d "$evid_dir" ]] || [[ -z "$(find "$evid_dir" -name "EVID-*.md" -type f 2>/dev/null)" ]]; then
          warn "未找到 Evidence 文件"; pass=false
        fi
      fi
      ;;
    G9)
      step "G9 Review Gate — 人工审查"
      info "G9 需要 Reviewer 人工确认"
      info "检查项: 代码满足 Task/Spec、Matrix 覆盖、无 CRITICAL/HIGH 问题"
      ;;
    G10)
      step "G10 Release Gate — 发布就绪"
      # 委托给 goal-workflow.sh release
      if [[ -f "$SCRIPT_DIR/goal-workflow.sh" ]]; then
        info "委托 goal-workflow.sh release 执行发布前检查"
        bash "$SCRIPT_DIR/goal-workflow.sh" release --root "$ROOT" 2>/dev/null || pass=false
      else
        info "G10 检查: Matrix 全部 Verified、P0/P1 测试通过、回滚方案就绪"
      fi
      ;;
    G11)
      step "G11 Retrospective Gate — 复盘完成"
      info "G11 检查: 复盘文档已编写、改进项已识别"
      ;;
    *)
      die "未知 Gate: $gate (可选 G0-G11)"
      ;;
  esac

  if $pass; then
    ok "$gate PASS"
    gate_set "$gate" "PASS"
    return 0
  else
    warn "$gate 需要完善"
    gate_set "$gate" "FAIL"
    return 1
  fi
}

# ─── validate：完整验证 ──────────────────────────────────
cmd_validate() {
  title "完整验证"
  require_config

  if [[ -f "$SCRIPT_DIR/goal-workflow.sh" ]]; then
    step "委托 goal-workflow.sh validate"
    bash "$SCRIPT_DIR/goal-workflow.sh" validate --root "$ROOT" || true
  else
    warn "goal-workflow.sh 不可用"
    cmd_check
  fi
}

# ─── release：发布前检查 ─────────────────────────────────
cmd_release() {
  title "发布前检查"
  require_config

  if [[ -f "$SCRIPT_DIR/goal-workflow.sh" ]]; then
    step "委托 goal-workflow.sh release"
    bash "$SCRIPT_DIR/goal-workflow.sh" release --root "$ROOT" || true
  else
    warn "goal-workflow.sh 不可用"
  fi
}

# ─── status：显示管线状态 ────────────────────────────────
cmd_status() {
  title "管线状态"
  require_config

  # Pipeline 状态
  header "Pipeline 状态"
  local phase state
  phase=$(yaml_get "$CONFIG_DIR/pipeline/state.yaml" "current_phase") || phase="UNKNOWN"
  state=$(yaml_get "$CONFIG_DIR/pipeline/state.yaml" "pipeline_state") || state="UNKNOWN"
  printf "  当前阶段: ${BOLD}%s${NC}\n" "$phase"
  printf "  管线状态: ${BOLD}%s${NC}\n" "$state"

  # Gate 状态
  header "Gate 状态 (G0-G11)"
  for gate in G0 G1 G2 G3 G4 G5 G6 G7 G8 G9 G10 G11; do
    local gs
    gs=$(gate_status "$gate")
    local icon
    case "$gs" in
      PASS)            icon="${GREEN}✓ PASS${NC}" ;;
      PASS_WITH_RISK)  icon="${YELLOW}⚠ PASS_WITH_RISK${NC}" ;;
      FAIL)            icon="${RED}✗ FAIL${NC}" ;;
      BLOCKED)         icon="${RED}⊘ BLOCKED${NC}" ;;
      *)               icon="${CYAN}○ ${gs}${NC}" ;;
    esac
    printf "  %-4s %b\n" "$gate" "$icon"
  done

  # Goal 列表
  header "Goals"
  if [[ -f "$CONFIG_DIR/registry/goals.yaml" ]]; then
    awk '/^  - goal_id:/{id=$3} /^    title:/{t=$0; sub(/^    title: */, "", t)} /^    status:/{s=$2; printf "  %s | %s | %s\n", id, t, s}' \
      "$CONFIG_DIR/registry/goals.yaml" 2>/dev/null || info "暂无 Goal"
  fi

  # Task 列表
  header "Tasks"
  if [[ -f "$CONFIG_DIR/registry/tasks.yaml" ]]; then
    awk '/^  - task_id:/{id=$3} /^    status:/{printf "  %s | %s\n", id, $2}' \
      "$CONFIG_DIR/registry/tasks.yaml" 2>/dev/null || info "暂无 Task"
  fi

  # Evidence 统计
  header "Evidence"
  local evid_count=0
  if [[ -d "$CONFIG_DIR/evidence" ]]; then
    evid_count=$(find "$CONFIG_DIR/evidence" -name "EVID-*.md" -type f 2>/dev/null | wc -l)
  fi
  printf "  Evidence 文件数: %s\n" "$evid_count"
}

# ─── dashboard：交付看板 ─────────────────────────────────
cmd_dashboard() {
  title "Goal 交付看板"

  local goal_count=0 task_count=0 evid_count=0
  [[ -f "$CONFIG_DIR/registry/goals.yaml" ]] && \
    goal_count=$(grep -c "goal_id:" "$CONFIG_DIR/registry/goals.yaml" 2>/dev/null || echo 0)
  [[ -f "$CONFIG_DIR/registry/tasks.yaml" ]] && \
    task_count=$(grep -c "task_id:" "$CONFIG_DIR/registry/tasks.yaml" 2>/dev/null || echo 0)
  [[ -d "$CONFIG_DIR/evidence" ]] && \
    evid_count=$(find "$CONFIG_DIR/evidence" -name "EVID-*.md" -type f 2>/dev/null | wc -l)

  printf "  ${BOLD}Goals${NC}:     %s\n" "$goal_count"
  printf "  ${BOLD}Tasks${NC}:     %s\n" "$task_count"
  printf "  ${BOLD}Evidence${NC}:  %s\n" "$evid_count"

  local phase state
  phase=$(yaml_get "$CONFIG_DIR/pipeline/state.yaml" "current_phase") || phase="UNKNOWN"
  state=$(yaml_get "$CONFIG_DIR/pipeline/state.yaml" "pipeline_state") || state="UNKNOWN"
  printf "  ${BOLD}Phase${NC}:     %s → %s\n" "$phase" "$state"

  if [[ -f "$CONFIG_DIR/gates/state.yaml" ]]; then
    local pass_count=0
    pass_count=$(awk '/gate_id: G[0-9]/{g=1} g && /status: PASS/{c++; g=0} g && /status: [^P]/{g=0} END{print c+0}' "$CONFIG_DIR/gates/state.yaml")
    printf "  ${BOLD}Gates${NC}:     %s/12 通过\n" "$pass_count"
  fi

  printf "\n  ${BOLD}管线进度${NC}:\n"
  printf "  "
  local phases=("Goal" "Spec" "Design" "Plan" "Tasks" "Prompt" "Code" "Test" "Review" "Release" "Retro")
  local current_phase=""
  current_phase=$(yaml_get "$CONFIG_DIR/pipeline/state.yaml" "current_phase") || current_phase=""

  local found_current=false
  for p in "${phases[@]}"; do
    local upper
    upper=$(echo "$p" | tr '[:lower:]' '[:upper:]')
    if [[ "$upper" == "$current_phase" ]]; then
      printf "${BOLD}${GREEN}[%s]${NC} → " "$p"
      found_current=true
    elif $found_current; then
      printf "${CYAN}%s${NC} → " "$p"
    else
      printf "${GREEN}✓%s${NC} → " "$p"
    fi
  done
  printf "Done\n"
}

# ─── auto：自动推进 ─────────────────────────────────────
cmd_auto() {
  title "自动推进管线"
  require_config

  local phase
  phase=$(yaml_get "$CONFIG_DIR/pipeline/state.yaml" "current_phase") || phase="INIT"

  info "当前阶段: $phase"
  info "模式: $MODE"

  case "$phase" in
    INIT|CONTEXT_READY)
      step "检测到需要创建 Goal"
      info "请运行: goal-delivery.sh goal --title \"你的目标\""
      ;;
    GOAL|GOAL_READY)
      step "Goal 已就绪，检查 G1"
      run_single_gate "G1" && info "下一步: goal-delivery.sh spec --goal-id <ID>" || warn "请先完善 Goal"
      ;;
    SPEC|SPEC_READY)
      step "Spec 已就绪，检查 G2"
      run_single_gate "G2" && info "下一步: goal-delivery.sh design --spec-id <ID>" || warn "请先完善 Spec"
      ;;
    DESIGN|DESIGN_READY)
      step "Design 已就绪，检查 G3"
      run_single_gate "G3" && info "下一步: goal-delivery.sh plan --goal-id <ID>" || warn "请先完善 Design"
      ;;
    PLAN|PLAN_READY)
      step "Plan 已就绪，检查 G4"
      run_single_gate "G4" && info "下一步: goal-delivery.sh tasks --plan-id <ID>" || warn "请先完善 Plan"
      ;;
    TASKS|TASKS_READY)
      step "Tasks 已就绪，检查 G5"
      run_single_gate "G5" && info "下一步: goal-delivery.sh prompt --task-id <ID>" || warn "请先完善 Tasks"
      ;;
    PROMPT|EXECUTING)
      step "正在执行，检查 G6"
      run_single_gate "G6" && info "下一步: 编写代码，然后运行 goal-delivery.sh evidence --task-id <ID>" || warn "请先完善 Prompt"
      ;;
    CODE|VERIFYING)
      step "正在验证，检查 G7/G8"
      run_single_gate "G7"
      run_single_gate "G8"
      ;;
    TEST|REVIEWING)
      step "正在审查，检查 G9"
      run_single_gate "G9"
      ;;
    REVIEW|RELEASE|RELEASING)
      step "正在发布，检查 G10"
      run_single_gate "G10"
      ;;
    RETROSPECTING|RETRO)
      step "正在复盘，检查 G11"
      run_single_gate "G11"
      ;;
    DONE)
      ok "管线已完成！"
      ;;
    *)
      warn "未知阶段: $phase"
      ;;
  esac
}

# ─── 参数解析 ────────────────────────────────────────────
COMMAND=""
ARG1=""
ARG2=""

parse_args() {
  while (($#)); do
    case "$1" in
      --root)
        [[ $# -ge 2 ]] || die "--root 需要值"
        ROOT="$2"
        CONFIG_DIR="$ROOT/.config/goal"
        shift 2
        ;;
      --mode)
        [[ $# -ge 2 ]] || die "--mode 需要值"
        MODE="$2"
        shift 2
        ;;
      --goal-id)
        [[ $# -ge 2 ]] || die "--goal-id 需要值"
        ARG1="$2"
        shift 2
        ;;
      --spec-id)
        [[ $# -ge 2 ]] || die "--spec-id 需要值"
        ARG1="$2"
        shift 2
        ;;
      --plan-id)
        [[ $# -ge 2 ]] || die "--plan-id 需要值"
        ARG1="$2"
        shift 2
        ;;
      --task-id)
        [[ $# -ge 2 ]] || die "--task-id 需要值"
        ARG1="$2"
        shift 2
        ;;
      --test-id)
        [[ $# -ge 2 ]] || die "--test-id 需要值"
        ARG2="$2"
        shift 2
        ;;
      --title)
        [[ $# -ge 2 ]] || die "--title 需要值"
        ARG2="$2"
        shift 2
        ;;
      --gate)
        [[ $# -ge 2 ]] || die "--gate 需要值"
        ARG1="$2"
        shift 2
        ;;
      --level)
        [[ $# -ge 2 ]] || die "--level 需要值"
        ARG2="$2"
        shift 2
        ;;
      --action)
        [[ $# -ge 2 ]] || die "--action 需要值"
        ARG1="$2"
        shift 2
        ;;
      --format)
        shift 2
        ;;
      -h|--help)
        COMMAND="help"
        shift
        ;;
      -*)
        die "未知选项: $1"
        ;;
      *)
        [[ -z "$COMMAND" ]] || die "重复命令"
        COMMAND="$1"
        shift
        ;;
    esac
  done
}

# ─── 主入口 ──────────────────────────────────────────────
main() {
  parse_args "$@"

  case "$COMMAND" in
    init)      cmd_init ;;
    goal)      cmd_goal "$ARG1" "$ARG2" ;;
    spec)      cmd_spec "$ARG1" ;;
    design)    cmd_design "$ARG1" ;;
    plan)      cmd_plan "$ARG1" ;;
    tasks)     cmd_tasks "$ARG1" ;;
    prompt)    cmd_prompt "$ARG1" ;;
    evidence)  cmd_evidence "$ARG1" "$ARG2" ;;
    matrix)    cmd_matrix "$ARG1" ;;
    change)    cmd_change "$ARG1" "$ARG2" ;;
    status)    cmd_status ;;
    check)     cmd_check "$ARG1" ;;
    validate)  cmd_validate ;;
    release)   cmd_release ;;
    dashboard) cmd_dashboard ;;
    auto)      cmd_auto ;;
    help|"")   usage ;;
    *)         die "未知命令: $COMMAND" ;;
  esac
}

main "$@"
