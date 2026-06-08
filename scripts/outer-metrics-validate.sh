#!/usr/bin/env bash
# outer-metrics-validate.sh
#
# CI 守卫：拒绝 LLM agent 对三套运行时 outer-metrics 目录的写入。
# 根据宪法 §14.2，本目录仅允许 CI / 生产观测 / git 历史脚本 / 人类维护者写入。
#
# 触发：PR 检查（在 docs-ci.yml 中调用）
# 退出码：0=通过，1=违反宪法 §14.2

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"

cd "$ROOT"

# 获取 PR 中变更的受保护目录文件
if [[ -n "${GITHUB_BASE_REF:-}" ]]; then
  base="origin/${GITHUB_BASE_REF}"
  git fetch origin "$GITHUB_BASE_REF" --depth=1 >/dev/null 2>&1 || true
else
  base="HEAD~1"
fi

changed_files=$(git diff --name-only "$base"...HEAD 2>/dev/null \
  | grep -E '^(\.omc/state/outer-metrics|\.omx/state/outer-metrics|\.copilot/state/outer-metrics)/' || true)

if [[ -z "$changed_files" ]]; then
  echo "✓ outer-metrics 目录未变更"
  exit 0
fi

echo "检测到 outer-metrics 目录变更："
echo "$changed_files"
echo

# 检查 commit 作者：必须是 CI bot 或 codeowner 中的人类
violations=()
while IFS= read -r f; do
  # 检查最后一次修改该文件的 commit 是否来自授权来源
  last_author_email=$(git log -1 --format='%ae' -- "$f" 2>/dev/null || echo "unknown")
  last_commit_msg=$(git log -1 --format='%s' -- "$f" 2>/dev/null || echo "")

  # 授权来源白名单
  is_authorized=false

  # 1. GitHub Actions bot
  if [[ "$last_author_email" == *"github-actions[bot]"* ]] || \
     [[ "$last_author_email" == *"users.noreply.github.com"* && "$last_commit_msg" == *"[outer-metrics]"* ]]; then
    is_authorized=true
  fi

  # 2. Commit 标记为人工维护
  if [[ "$last_commit_msg" == *"[outer-metrics:manual]"* ]]; then
    is_authorized=true
  fi

  # 3. 由白名单脚本生成（commit message 含脚本名）
  for script in outer-metrics-from-git.sh outer-metrics-eval.sh; do
    if [[ "$last_commit_msg" == *"$script"* ]]; then
      is_authorized=true
      break
    fi
  done

  # 4. 拒绝任何 LLM agent commit 标志
  if [[ "$last_commit_msg" == *"Co-authored-by: Claude"* ]] || \
     [[ "$last_commit_msg" == *"Co-authored-by: Codex"* ]] || \
     [[ "$last_commit_msg" == *"Co-authored-by: Copilot"* ]] || \
     [[ "$last_commit_msg" == *"task-executor"* ]]; then
    is_authorized=false
    violations+=("$f: LLM agent commit detected ($last_author_email)")
    continue
  fi

  if ! $is_authorized; then
    violations+=("$f: unauthorized author $last_author_email; commit: $last_commit_msg")
  fi
done <<< "$changed_files"

if [[ ${#violations[@]} -gt 0 ]]; then
  echo "✗ 违反宪法 §14.2：outer-metrics 仅允许 CI / 脚本 / 人类维护者写入"
  printf '  - %s\n' "${violations[@]}"
  echo
  echo "授权方式："
  echo "  - CI workflow: 由 .github/workflows/outer-metrics.yml 自动写入"
  echo "  - 脚本: scripts/outer-metrics-{from-git,eval}.sh"
  echo "  - 人工: commit message 包含 [outer-metrics:manual]"
  exit 1
fi

echo "✓ 所有变更均来自授权来源"
exit 0
