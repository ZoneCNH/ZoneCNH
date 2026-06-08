#!/usr/bin/env bash
# task-spec-validate.sh — 校验 Task Spec 的结构和一致性
#
# 校验规则（来源：docs/governance/TASK-TEMPLATE.md）：
#   1. ID 唯一性：TASK-{MODULE}-{NNN} 格式，同模块内不重复
#   2. spec_ref 有效：引用的 module/*/SPEC.md#FR-xxx 存在
#   3. AC 覆盖：每个 task 至少有 1 条 acceptance_criteria
#   4. 依赖无环：depends_on 不形成循环依赖
#   5. 文件不冲突：同模块内不同 in_progress task 的 files 列表无交集
#   6. 粒度合规：files ≤ 5，FR ≤ 3，scope ≤ 200 字符

set -euo pipefail

FAIL=0
WARN=0
REPO_ROOT="$(git rev-parse --show-toplevel)"
SPEC_DIR="$REPO_ROOT/module"
TASK_DATA_DIR="$SPEC_DIR/TASKS"

echo "=== Task Spec Validate ==="
echo ""

# ── 前置检查：是否存在 task 数据 ────────────────────────────────

shopt -s nullglob
TASK_FILES=("$TASK_DATA_DIR"/*.md "$TASK_DATA_DIR"/*.yml "$TASK_DATA_DIR"/*.yaml)
shopt -u nullglob

if [[ ${#TASK_FILES[@]} -eq 0 ]]; then
  echo "  ℹ️  无 task 数据（$TASK_DATA_DIR 为空或不存在），跳过校验"
  echo ""
  echo "=== 结果 ==="
  echo "✅ Task Spec Validate 跳过（无数据）"
  exit 0
fi

echo "  扫描目录: $TASK_DATA_DIR"
echo "  发现文件: ${#TASK_FILES[@]}"
echo ""

# ── 数据结构 ──────────────────────────────────────────────────
declare -A TASK_MODULE       # id → module
declare -A TASK_SCOPE        # id → scope
declare -A TASK_STATUS       # id → status
declare -A TASK_PRIORITY     # id → priority
declare -A TASK_AC_COUNT     # id → AC 数量
declare -A TASK_FR_COUNT     # id → FR 引用数量
declare -A TASK_FILE_COUNT   # id → files 数量
declare -A TASK_SCOPE_LEN    # id → scope 长度

declare -A TASK_SPECREFS     # id → spec_ref 行（换行分隔）
declare -A TASK_FILES_LIST   # id → files 行（换行分隔）
declare -A TASK_DEPENDS      # id → depends_on 行（换行分隔）

ALL_IDS=()
ERRORS=()
WARNINGS=()

add_error() { ERRORS+=("$1"); FAIL=1; }
add_warning() { WARNINGS+=("$1"); WARN=1; }

# ── 1. 解析 task 数据 ─────────────────────────────────────────

parse_tasks() {
  local task_file="$1"
  local current_id=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    # 匹配 task ID 行：TASK-{MODULE}-{NNN}:
    if [[ "$line" =~ ^(TASK-[A-Z]+-[0-9]+): ]]; then
      current_id="${BASH_REMATCH[1]}"
      ALL_IDS+=("$current_id")
      TASK_AC_COUNT["$current_id"]=0
      TASK_FR_COUNT["$current_id"]=0
      TASK_FILE_COUNT["$current_id"]=0
      TASK_SCOPE_LEN["$current_id"]=0
      TASK_SPECREFS["$current_id"]=""
      TASK_FILES_LIST["$current_id"]=""
      TASK_DEPENDS["$current_id"]=""
      continue
    fi

    [[ -z "$current_id" ]] && continue

    # 解析字段
    if [[ "$line" =~ ^[[:space:]]+module:[[:space:]]*(.+) ]]; then
      TASK_MODULE["$current_id"]="${BASH_REMATCH[1]// /}"
    elif [[ "$line" =~ ^[[:space:]]+scope:[[:space:]]*\"(.+)\" ]]; then
      local scope="${BASH_REMATCH[1]}"
      TASK_SCOPE["$current_id"]="$scope"
      TASK_SCOPE_LEN["$current_id"]=${#scope}
    elif [[ "$line" =~ ^[[:space:]]+priority:[[:space:]]*(.+) ]]; then
      TASK_PRIORITY["$current_id"]="${BASH_REMATCH[1]// /}"
    elif [[ "$line" =~ ^[[:space:]]+status:[[:space:]]*(.+) ]]; then
      TASK_STATUS["$current_id"]="${BASH_REMATCH[1]// /}"
    elif [[ "$line" =~ ^[[:space:]]+-[[:space:]]+\"?(module/.+)\"?$ ]]; then
      local ref="${BASH_REMATCH[1]//\"/}"
      TASK_SPECREFS["$current_id"]+="$ref"$'\n'
      TASK_FR_COUNT["$current_id"]=$(( ${TASK_FR_COUNT["$current_id"]} + 1 ))
    elif [[ "$line" =~ ^[[:space:]]+-[[:space:]]+\"?(.+\.(go|ts|py|rs|md|yml|yaml|json|toml|test\.go|_test\.go))\"?$ ]]; then
      local file="${BASH_REMATCH[1]//\"/}"
      TASK_FILES_LIST["$current_id"]+="$file"$'\n'
      TASK_FILE_COUNT["$current_id"]=$(( ${TASK_FILE_COUNT["$current_id"]} + 1 ))
    elif [[ "$line" =~ ^[[:space:]]+-[[:space:]]+\"?(AC-|BR-) ]]; then
      TASK_AC_COUNT["$current_id"]=$(( ${TASK_AC_COUNT["$current_id"]} + 1 ))
    elif [[ "$line" =~ ^[[:space:]]+-[[:space:]]+\"?(TASK-[A-Z]+-[0-9]+)\"?$ ]]; then
      TASK_DEPENDS["$current_id"]+="${BASH_REMATCH[1]}"$'\n'
    fi
  done < "$task_file"
}

for task_file in "${TASK_FILES[@]}"; do
  parse_tasks "$task_file"
done

if [[ ${#ALL_IDS[@]} -eq 0 ]]; then
  echo "  ℹ️  未解析到任何 task（文件格式可能不含 TASK-xxx: 结构），跳过校验"
  echo ""
  echo "=== 结果 ==="
  echo "✅ Task Spec Validate 跳过（无有效 task 数据）"
  exit 0
fi

echo "  解析到 ${#ALL_IDS[@]} 个 task"
echo ""

# ── 2. 校验规则实现 ───────────────────────────────────────────

# 规则 1：ID 唯一性
echo "--- Rule 1: ID 唯一性 ---"
declare -A ID_SEEN
for id in "${ALL_IDS[@]}"; do
  if [[ -n "${ID_SEEN[$id]+x}" ]]; then
    add_error "ID 重复: $id"
  else
    ID_SEEN["$id"]=1
  fi
  # 检查 ID 格式
  if [[ ! "$id" =~ ^TASK-[A-Z]+-[0-9]{3}$ ]]; then
    add_warning "ID 格式不规范: $id（期望 TASK-{MODULE}-{NNN}，NNN 为三位数字）"
  fi
done
echo "  检查 ${#ALL_IDS[@]} 个 ID"

# 规则 2：spec_ref 有效
echo "--- Rule 2: spec_ref 有效 ---"
for id in "${ALL_IDS[@]}"; do
  task_refs="${TASK_SPECREFS[$id]}"
  [[ -z "$task_refs" ]] && continue
  while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    # 解析 spec_ref 格式: module/{module}/SPEC.md#FR-NNN
    if [[ "$ref" =~ ^(module/[^/]+/SPEC\.md)(#.*)?$ ]]; then
      spec_path="${REPO_ROOT}/${BASH_REMATCH[1]}"
      if [[ ! -f "$spec_path" ]]; then
        add_error "spec_ref 文件不存在: $ref ($id)"
      elif [[ -n "${BASH_REMATCH[2]}" ]]; then
        anchor="${BASH_REMATCH[2]#\#}"
        if ! grep -q "$anchor" "$spec_path" 2>/dev/null; then
          add_warning "spec_ref 锚点未找到: $ref ($id)"
        fi
      fi
    else
      add_warning "spec_ref 格式不规范: $ref ($id)"
    fi
  done <<< "$task_refs"
done
echo "  检查所有 spec_ref 引用"

# 规则 3：AC 覆盖
echo "--- Rule 3: AC 覆盖 ---"
for id in "${ALL_IDS[@]}"; do
  local_ac="${TASK_AC_COUNT[$id]}"
  if [[ "$local_ac" -eq 0 ]]; then
    add_error "缺少 acceptance_criteria: $id"
  fi
done
echo "  检查 ${#ALL_IDS[@]} 个 task 的 AC"

# 规则 4：依赖无环
echo "--- Rule 4: 依赖无环 ---"
declare -A IN_DEGREE
declare -A ADJ_LIST

for id in "${ALL_IDS[@]}"; do
  IN_DEGREE["$id"]=0
  ADJ_LIST["$id"]=""
done

for id in "${ALL_IDS[@]}"; do
  local_deps="${TASK_DEPENDS[$id]}"
  [[ -z "$local_deps" ]] && continue
  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue
    if [[ -z "${IN_DEGREE[$dep]+x}" ]]; then
      add_warning "依赖的 task 不存在: $dep (被 $id 引用)"
    else
      IN_DEGREE["$id"]=$(( ${IN_DEGREE["$id"]} + 1 ))
      ADJ_LIST["$dep"]+="$id "
    fi
  done <<< "$local_deps"
done

# Kahn 拓扑排序
QUEUE=()
for id in "${ALL_IDS[@]}"; do
  if [[ "${IN_DEGREE[$id]}" -eq 0 ]]; then
    QUEUE+=("$id")
  fi
done

SORTED_COUNT=0
while [[ ${#QUEUE[@]} -gt 0 ]]; do
  current="${QUEUE[0]}"
  QUEUE=("${QUEUE[@]:1}")
  SORTED_COUNT=$((SORTED_COUNT + 1))
  for neighbor in ${ADJ_LIST[$current]}; do
    IN_DEGREE["$neighbor"]=$(( ${IN_DEGREE["$neighbor"]} - 1 ))
    if [[ "${IN_DEGREE[$neighbor]}" -eq 0 ]]; then
      QUEUE+=("$neighbor")
    fi
  done
done

if [[ $SORTED_COUNT -lt ${#ALL_IDS[@]} ]]; then
  CYCLE_NODES=""
  for id in "${ALL_IDS[@]}"; do
    if [[ "${IN_DEGREE[$id]}" -gt 0 ]]; then
      CYCLE_NODES+="$id "
    fi
  done
  add_error "依赖存在循环: $CYCLE_NODES"
fi
echo "  拓扑排序: $SORTED_COUNT/${#ALL_IDS[@]} 个 task 可排序"

# 规则 5：文件不冲突
echo "--- Rule 5: 文件不冲突（同模块内 in_progress task）---"
declare -A FILE_OWNER_MAP  # "module:file" → "id1 id2 ..."

for id in "${ALL_IDS[@]}"; do
  status="${TASK_STATUS[$id]:-pending}"
  [[ "$status" != "in_progress" ]] && continue
  module="${TASK_MODULE[$id]:-unknown}"
  local_files="${TASK_FILES_LIST[$id]}"
  [[ -z "$local_files" ]] && continue
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    key="$module:$file"
    if [[ -n "${FILE_OWNER_MAP[$key]+x}" ]]; then
      FILE_OWNER_MAP["$key"]+=" $id"
    else
      FILE_OWNER_MAP["$key"]="$id"
    fi
  done <<< "$local_files"
done

for key in "${!FILE_OWNER_MAP[@]}"; do
  owners="${FILE_OWNER_MAP[$key]}"
  count=$(echo "$owners" | wc -w)
  if [[ "$count" -gt 1 ]]; then
    add_error "文件冲突: $key 被多个 in_progress task 引用: $owners"
  fi
done
echo "  检查文件冲突"

# 规则 6：粒度合规
echo "--- Rule 6: 粒度合规 ---"
for id in "${ALL_IDS[@]}"; do
  # files ≤ 5
  if [[ "${TASK_FILE_COUNT[$id]}" -gt 5 ]]; then
    add_error "文件数超标: $id 有 ${TASK_FILE_COUNT[$id]} 个文件（上限 5）"
  fi
  # FR ≤ 3
  if [[ "${TASK_FR_COUNT[$id]}" -gt 3 ]]; then
    add_error "FR 数超标: $id 引用了 ${TASK_FR_COUNT[$id]} 个 FR（上限 3）"
  fi
  # scope 长度检查（上限 200 字符）
  if [[ "${TASK_SCOPE_LEN[$id]}" -gt 200 ]]; then
    add_warning "scope 过长: $id 有 ${TASK_SCOPE_LEN[$id]} 字符（建议 ≤ 200）"
  fi
done
echo "  检查粒度约束"

# ── 输出结果 ──────────────────────────────────────────────────

echo ""
echo "=== 结果 ==="

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo ""
  echo "❌ 错误 (${#ERRORS[@]}):"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
fi

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo ""
  echo "⚠️  警告 (${#WARNINGS[@]}):"
  for warn in "${WARNINGS[@]}"; do
    echo "  - $warn"
  done
fi

echo ""
if [[ $FAIL -ne 0 ]]; then
  echo "❌ Task Spec Validate 失败 — 请修复上述错误"
  exit 1
elif [[ $WARN -ne 0 ]]; then
  echo "⚠️  Task Spec Validate 通过（有警告）"
  exit 0
else
  echo "✅ Task Spec Validate 全部通过（${#ALL_IDS[@]} 个 task）"
  exit 0
fi
