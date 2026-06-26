#!/usr/bin/env bash
# migrate-module.sh — 将扁平模块迁移到目录化管线结构
# 用法: bash docs/goal/tools/migrate-module.sh <module-name> [--dry-run]
set -euo pipefail

MODULE_NAME="${1:-}"
DRY_RUN=false
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN=true

if [[ -z "$MODULE_NAME" ]]; then
  echo "用法: bash docs/goal/tools/migrate-module.sh <module-name> [--dry-run]"
  echo "示例: bash docs/goal/tools/migrate-module.sh redisx"
  echo "      bash docs/goal/tools/migrate-module.sh redisx --dry-run"
  exit 1
fi

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
MODULE_DIR="$ROOT/module/$MODULE_NAME"

if [[ ! -d "$MODULE_DIR" ]]; then
  echo "错误: 模块目录不存在: $MODULE_DIR"
  exit 1
fi

# ── 文件映射表 ──────────────────────────────────────────────
# 格式: "源路径|目标路径"
declare -a FILE_MAP=(
  # S1 Goal
  "goal.md|goal/goal.md"

  # S2 Spec
  "SPEC.md|spec/SPEC.md"
  "FEATURES.md|spec/FEATURES.md"
  "ACCEPTANCE.md|spec/ACCEPTANCE.md"
  "DATA-LIFECYCLE.md|spec/DATA-LIFECYCLE.md"
  "DATA-QUALITY-SLA.md|spec/DATA-QUALITY-SLA.md"
  "NAMING.md|spec/NAMING.md"
  "ENDPOINTS.md|spec/ENDPOINTS.md"
  "SPEC-*.md|spec/"                    # SPEC-exchangeinfo-sync.md 等

  # S3 Design
  "DESIGN.md|design/DESIGN.md"
  "DEEP-ANALYSIS*.md|design/"
  "DEEP-ANALYSIS-*.md|design/"
  "ADR-*.md|design/"
  "ARCHITECTURE-DRIFT-WATCHLIST.md|design/ARCHITECTURE-DRIFT-WATCHLIST.md"
  "RUNTIME-MAPPING.md|design/RUNTIME-MAPPING.md"
  "PERSISTENCE-WIRING.md|design/PERSISTENCE-WIRING.md"

  # S4 Plan
  "IMPLEMENTATION-PLAN.md|plan/PLAN.md"
  "PLAN.md|plan/PLAN.md"

  # S5 Tasks (keep in place)
  # "tasks/|tasks/" — 原地不动

  # S6 Prompt
  # 按需创建

  # Matrix (横切)
  "TRACEABILITY.md|matrix/TRACEABILITY.md"

  # Gate (横切)
  "BOUNDARY-GATES.md|gate/BOUNDARY-GATES.md"
  "RULES.md|gate/RULES.md"
  "STANDARD.md|gate/STANDARD.md"
  "SECURITY.md|gate/SECURITY.md"
  "OBSERVABILITY.md|gate/OBSERVABILITY.md"
  "OPERATIONS.md|gate/OPERATIONS.md"

  # Sub-module: client
  "client/SPEC.md|spec/client/SPEC.md"
  "client/README.md|spec/client/README.md"
  "client/TRACEABILITY.md|matrix/client/TRACEABILITY.md"
  "client/IMPLEMENTATION-PLAN.md|plan/client/PLAN.md"

  # Sub-module: server
  "server/SPEC.md|spec/server/SPEC.md"
  "server/README.md|spec/server/README.md"
  "server/TRACEABILITY.md|matrix/server/TRACEABILITY.md"
  "server/IMPLEMENTATION-PLAN.md|plan/server/PLAN.md"
)

# ── 目录创建 ────────────────────────────────────────────────
DIRS=(
  "goal"
  "spec"      "spec/client"   "spec/server"
  "design"    "design/client" "design/server"
  "plan"      "plan/client"   "plan/server"
  "tasks"     "tasks/client"  "tasks/server"
  "prompt"
  "matrix"    "matrix/client" "matrix/server"
  "gate"
  "schema"
  "evidence"
)

echo "==> 模块: $MODULE_NAME"
echo "==> 模式: $([ "$DRY_RUN" = true ] && echo 'DRY RUN' || echo 'EXECUTE')"
echo ""

# ── 创建目录 ────────────────────────────────────────────────
echo "── 创建目录 ──"
for d in "${DIRS[@]}"; do
  target="$MODULE_DIR/$d"
  if [[ -d "$target" ]]; then
    echo "  跳过: $d/ (已存在)"
  else
    if [[ "$DRY_RUN" = true ]]; then
      echo "  [DRY] mkdir $d/"
    else
      mkdir -p "$target"
      echo "  创建: $d/"
    fi
  fi
done

# ── 创建 evidence 日期目录 ──────────────────────────────────
TODAY=$(date +%Y-%m-%d)
EVID_DIR="$MODULE_DIR/evidence/$TODAY"
for sd in test review release retrospective; do
  if [[ ! -d "$EVID_DIR/$sd" ]]; then
    if [[ "$DRY_RUN" = true ]]; then
      echo "  [DRY] mkdir evidence/$TODAY/$sd/"
    else
      mkdir -p "$EVID_DIR/$sd"
    fi
  fi
done

echo ""
echo "── 迁移文件 ──"

# ── 迁移文件 ────────────────────────────────────────────────
moved=0
skipped=0

for entry in "${FILE_MAP[@]}"; do
  src_rel="${entry%%|*}"
  dst_rel="${entry##*|}"

  # 处理通配符
  if [[ "$src_rel" == *"*"* ]]; then
    # 找到所有匹配文件
    while IFS= read -r -d '' src_path; do
      src_name="$(basename "$src_path")"
      if [[ "$dst_rel" == */ ]]; then
        dst_path="$MODULE_DIR/${dst_rel}${src_name}"
      else
        dst_path="$MODULE_DIR/$dst_rel"
      fi

      if [[ -f "$dst_path" ]]; then
        echo "  跳过: $src_name → ${dst_rel}${src_name} (目标已存在)"
        ((skipped++)) || true
      else
        if [[ "$DRY_RUN" = true ]]; then
          echo "  [DRY] mv $src_name → ${dst_rel}${src_name}"
        else
          git mv "$src_path" "$dst_path" 2>/dev/null || mv "$src_path" "$dst_path"
          echo "  移动: $src_name → ${dst_rel}${src_name}"
        fi
        ((moved++)) || true
      fi
    done < <(find "$MODULE_DIR" -maxdepth 1 -name "$src_rel" -print0 2>/dev/null)
  else
    src_path="$MODULE_DIR/$src_rel"
    dst_path="$MODULE_DIR/$dst_rel"

    if [[ ! -f "$src_path" ]]; then
      continue  # 文件不存在，静默跳过
    fi

    if [[ -f "$dst_path" ]]; then
      echo "  跳过: $src_rel (目标已存在)"
      ((skipped++)) || true
    else
      if [[ "$DRY_RUN" = true ]]; then
        echo "  [DRY] mv $src_rel → $dst_rel"
      else
        git mv "$src_path" "$dst_path" 2>/dev/null || mv "$src_path" "$dst_path"
        echo "  移动: $src_rel → $dst_rel"
      fi
      ((moved++)) || true
    fi
  fi
done

# ── 迁移 client/server tasks ─────────────────────────────────
for sub in client server; do
  src_tasks="$MODULE_DIR/$sub/tasks"
  dst_tasks="$MODULE_DIR/tasks/$sub"
  if [[ -d "$src_tasks" ]]; then
    while IFS= read -r -d '' f; do
      fname="$(basename "$f")"
      if [[ ! -f "$dst_tasks/$fname" ]]; then
        if [[ "$DRY_RUN" = true ]]; then
          echo "  [DRY] mv $sub/tasks/$fname → tasks/$sub/"
        else
          git mv "$f" "$dst_tasks/$fname" 2>/dev/null || mv "$f" "$dst_tasks/$fname"
          echo "  移动: $sub/tasks/$fname → tasks/$sub/"
        fi
        ((moved++)) || true
      fi
    done < <(find "$src_tasks" -maxdepth 1 -type f -print0 2>/dev/null)
    # 清理空目录
    rmdir "$src_tasks" 2>/dev/null || true
  fi
done

# ── 清理旧子模块目录 ────────────────────────────────────────
for sub in client server; do
  sub_dir="$MODULE_DIR/$sub"
  if [[ -d "$sub_dir" ]] && [[ -z "$(ls -A "$sub_dir" 2>/dev/null)" ]]; then
    if [[ "$DRY_RUN" = true ]]; then
      echo "  [DRY] rmdir $sub/"
    else
      rmdir "$sub_dir" 2>/dev/null && echo "  清理: $sub/ (空目录)"
    fi
  fi
done

echo ""
echo "── 结果 ──"
echo "  移动: $moved 文件"
echo "  跳过: $skipped 文件"
echo "  模块: $MODULE_NAME"

if [[ "$DRY_RUN" = true ]]; then
  echo ""
  echo "  ⚠️  DRY RUN — 未实际修改文件。去掉 --dry-run 执行迁移。"
else
  echo ""
  echo "  下一步:"
  echo "    1. 检查迁移结果:   find module/$MODULE_NAME -type d | sort"
  echo "    2. 更新引用路径:   检查模块内交叉引用是否指向旧路径"
  echo "    3. git add -A && git commit"
fi
