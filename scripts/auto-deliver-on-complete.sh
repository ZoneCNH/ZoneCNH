#!/usr/bin/env bash

set -u

HOOK_MODE=0
DRY_RUN="${AUTO_DELIVERY_DRY_RUN:-0}"

for arg in "$@"; do
  case "$arg" in
    --hook)
      HOOK_MODE=1
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --help|-h)
      cat <<'USAGE'
Usage:
  scripts/auto-deliver-on-complete.sh [--hook] [--dry-run]

Environment:
  AUTO_DELIVERY_FORCE=1                  Bypass task-complete detection.
  AUTO_DELIVERY_REQUIRE_TASK_COMPLETE=0  Run on every Stop hook.
  AUTO_DELIVERY_MERGE=0                  Commit only, do not merge to main.
  AUTO_DELIVERY_RETRY_MERGE=0            Do not retry merge on a clean feature branch.
  AUTO_DELIVERY_PUSH=1                   Push main after a successful merge.
  AUTO_DELIVERY_CLEANUP=0                Keep the feature worktree and branch.
  AUTO_DELIVERY_VERIFY_CMD='...'         Override validation command.
  AUTO_DELIVERY_COMMIT_SUBJECT='...'     Override generated Lore subject.
USAGE
      exit 0
      ;;
  esac
done

repo_root=""
git_common_dir=""
state_dir=""
log_file=""
status_file=""
payload_file=""

json_escape() {
  AUTO_DELIVERY_TEXT="$1" python3 - <<'PY'
import json
import os

print(json.dumps(os.environ.get("AUTO_DELIVERY_TEXT", ""), ensure_ascii=False))
PY
}

init_repo_context() {
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -z "$repo_root" ]; then
    return 1
  fi

  cd "$repo_root" || return 1
  git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null || true)"
  if [ -z "$git_common_dir" ]; then
    return 1
  fi

  case "$git_common_dir" in
    /*) ;;
    *) git_common_dir="$repo_root/$git_common_dir" ;;
  esac

  state_dir="$git_common_dir/auto-delivery"
  log_file="$state_dir/auto-delivery.log"
  status_file="$state_dir/status.json"
  payload_file="$state_dir/hook-payload.json"
  mkdir -p "$state_dir"
  return 0
}

log_line() {
  if [ -n "${log_file:-}" ]; then
    printf '%s\t%s\n' "$(date -Is)" "$*" >> "$log_file"
  fi
}

write_status() {
  status="$1"
  blocker="$2"
  details="$3"

  if [ -z "${status_file:-}" ]; then
    return 0
  fi

  AUTO_DELIVERY_STATUS="$status" \
  AUTO_DELIVERY_BLOCKER="$blocker" \
  AUTO_DELIVERY_DETAILS="$details" \
  AUTO_DELIVERY_REPO="$repo_root" \
  AUTO_DELIVERY_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || true)" \
  python3 - <<'PY' > "$status_file"
import json
import os
from datetime import datetime, timezone

print(json.dumps({
    "status": os.environ.get("AUTO_DELIVERY_STATUS", ""),
    "blocker": os.environ.get("AUTO_DELIVERY_BLOCKER", ""),
    "details": os.environ.get("AUTO_DELIVERY_DETAILS", ""),
    "repo": os.environ.get("AUTO_DELIVERY_REPO", ""),
    "branch": os.environ.get("AUTO_DELIVERY_BRANCH", ""),
    "updated_at": datetime.now(timezone.utc).isoformat(),
}, ensure_ascii=False, indent=2))
PY
}

finish() {
  status="$1"
  message="$2"
  code="${3:-0}"

  log_line "$status: $message"
  write_status "$status" "$message" ""

  if [ "$HOOK_MODE" -eq 1 ]; then
    AUTO_DELIVERY_HOOK_STATUS="$status" \
    AUTO_DELIVERY_HOOK_MESSAGE="$message" \
    python3 - <<'PY'
import json
import os

status = os.environ.get("AUTO_DELIVERY_HOOK_STATUS", "")
message = os.environ.get("AUTO_DELIVERY_HOOK_MESSAGE", "")
print(json.dumps({
    "continue": True,
    "stopReason": f"auto-delivery: {status} - {message}",
}, ensure_ascii=False))
PY
    exit 0
  fi

  if [ "$code" -eq 0 ]; then
    printf '%s\n' "$message"
  else
    printf '%s\n' "$message" >&2
  fi
  exit "$code"
}

queue_cleanup() {
  cleanup_main_worktree="$1"
  cleanup_repo_root="$2"
  cleanup_branch="$3"
  cleanup_log="$4"
  cleanup_slug="$(printf '%s' "$cleanup_branch" | tr -c 'A-Za-z0-9._-' '_')"
  cleanup_script="$state_dir/cleanup-$cleanup_slug-$$.sh"

  cat > "$cleanup_script" <<'CLEANUP'
#!/usr/bin/env bash
set -u

main_worktree="$1"
repo_root="$2"
branch="$3"
log_file="$4"
cleanup_script="$5"

cd / || exit 0
sleep 2
{
  printf "%s\tcleanup: start for %s\n" "$(date -Is)" "$branch"

  if git -C "$main_worktree" worktree list --porcelain | grep -Fx "worktree $repo_root" >/dev/null; then
    git -C "$main_worktree" worktree remove "$repo_root"
  else
    printf "%s\tcleanup: worktree already absent %s\n" "$(date -Is)" "$repo_root"
  fi

  if git -C "$main_worktree" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$main_worktree" branch -d "$branch"
  else
    printf "%s\tcleanup: branch already absent %s\n" "$(date -Is)" "$branch"
  fi

  printf "%s\tcleanup: complete for %s\n" "$(date -Is)" "$branch"
  rm -f "$cleanup_script"
} >> "$log_file" 2>&1
CLEANUP
  chmod 700 "$cleanup_script"
  log_line "cleanup: queued script $cleanup_script"

  if command -v setsid >/dev/null 2>&1; then
    setsid "$cleanup_script" "$cleanup_main_worktree" "$cleanup_repo_root" "$cleanup_branch" "$cleanup_log" "$cleanup_script" \
      >/dev/null 2>&1 < /dev/null &
  else
    nohup "$cleanup_script" "$cleanup_main_worktree" "$cleanup_repo_root" "$cleanup_branch" "$cleanup_log" "$cleanup_script" \
      >/dev/null 2>&1 < /dev/null &
  fi
}

capture_hook_payload() {
  if [ "$HOOK_MODE" -ne 1 ]; then
    printf '{}' > "$payload_file"
    return 0
  fi

  cat > "$payload_file" || printf '{}' > "$payload_file"
}

task_complete_detected() {
  if [ "${AUTO_DELIVERY_FORCE:-0}" = "1" ]; then
    return 0
  fi

  if [ "${AUTO_DELIVERY_REQUIRE_TASK_COMPLETE:-1}" = "0" ]; then
    return 0
  fi

  python3 - "$payload_file" "$repo_root" <<'PY'
import json
import os
import pathlib
import sys

payload_path = pathlib.Path(sys.argv[1])
repo_root = sys.argv[2]

def load_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}

def contains_task_complete(value):
    if isinstance(value, dict):
        event_type = value.get("type") or value.get("event_type") or value.get("name")
        if event_type == "task_complete":
            return True
        for key in ("event", "event_msg", "payload", "message", "data"):
            if contains_task_complete(value.get(key)):
                return True
        return any(contains_task_complete(v) for v in value.values())
    if isinstance(value, list):
        return any(contains_task_complete(v) for v in value)
    return False

def collect_paths(value, out):
    if isinstance(value, dict):
        for key, item in value.items():
            if key in {
                "transcript_path",
                "transcriptPath",
                "session_path",
                "sessionPath",
                "conversation_path",
                "conversationPath",
                "log_path",
                "logPath",
                "path",
            } and isinstance(item, str):
                out.append(item)
            else:
                collect_paths(item, out)
    elif isinstance(value, list):
        for item in value:
            collect_paths(item, out)

def session_contains_complete(path):
    p = pathlib.Path(path).expanduser()
    if not p.exists() or not p.is_file():
        return False
    try:
        text = p.read_text(encoding="utf-8", errors="ignore")[-524288:]
    except Exception:
        return False
    if "task_complete" not in text:
        return False
    if repo_root not in text and os.environ.get("AUTO_DELIVERY_ALLOW_SESSION_WITHOUT_REPO", "0") != "1":
        return False
    for line in text.splitlines()[-1200:]:
        try:
            if contains_task_complete(json.loads(line)):
                return True
        except Exception:
            continue
    return '"task_complete"' in text

payload = load_json(payload_path)
if contains_task_complete(payload):
    raise SystemExit(0)

candidates = []
if os.environ.get("AUTO_DELIVERY_ALLOW_SESSION_ENV", "0") == "1":
    for name in ("CODEX_SESSION_FILE", "CODEX_SESSION_PATH", "OMX_SESSION_FILE", "OMX_SESSION_PATH"):
        value = os.environ.get(name)
        if value:
            candidates.append(value)
collect_paths(payload, candidates)

for candidate in candidates:
    if session_contains_complete(candidate):
        raise SystemExit(0)

raise SystemExit(1)
PY
}

current_branch() {
  git symbolic-ref --short HEAD 2>/dev/null || true
}

working_tree_has_changes() {
  [ -n "$(git status --porcelain)" ]
}

assert_safe_branch() {
  branch="$(current_branch)"
  if [ -z "$branch" ]; then
    finish "blocked" "detached HEAD 不允许自动交付" 2
  fi
  if [ "$branch" = "main" ]; then
    if [ "$HOOK_MODE" -eq 1 ]; then
      finish "skipped" "当前位于 main，跳过自动交付以遵守 CONSTITUTION.md 第零条" 0
    fi
    finish "blocked" "当前位于 main，CONSTITUTION.md 第零条禁止自动提交" 2
  fi
}

stage_and_scan() {
  git add -A >> "$log_file" 2>&1

  if git diff --cached --quiet; then
    finish "skipped" "没有可提交的 staged 变更" 0
  fi

  changed_files="$(git diff --cached --name-only)"
  if printf '%s\n' "$changed_files" | grep -E '(^|/)(\.env|\.env\..*|id_rsa|id_dsa|id_ed25519|.*\.pem|.*\.key|credentials?|secrets?)(/|$)' >/dev/null; then
    finish "blocked" "检测到疑似凭证或密钥文件，已阻止自动提交" 2
  fi

  secret_pattern='BEGIN (RSA |DSA |EC |OPENSSH |PRIVATE )?KEY|AWS_SECRET_ACCESS_KEY|SECRET(_KEY)?[[:space:]]*=|API[_-]?KEY[[:space:]]*=|TOKEN[[:space:]]*=|PASSWORD[[:space:]]*='
  if command -v rg >/dev/null 2>&1; then
    if git diff --cached -U0 | grep -v 'secret_pattern=' | rg -n "$secret_pattern" >/dev/null; then
      finish "blocked" "检测到疑似密钥内容，已阻止自动提交" 2
    fi
  elif git diff --cached -U0 | grep -v 'secret_pattern=' | grep -Ei "$secret_pattern" >/dev/null; then
    finish "blocked" "检测到疑似密钥内容，已阻止自动提交" 2
  fi
}

run_validation() {
  verify_cmd="${AUTO_DELIVERY_VERIFY_CMD:-git diff --check && git diff --cached --check}"
  log_line "verify: $verify_cmd"
  if ! sh -c "$verify_cmd" >> "$log_file" 2>&1; then
    finish "blocked" "验证命令失败：$verify_cmd" 2
  fi
}

create_commit() {
  verify_cmd="${AUTO_DELIVERY_VERIFY_CMD:-git diff --check && git diff --cached --check}"
  subject="${AUTO_DELIVERY_COMMIT_SUBJECT:-保存已验证变更以完成自动交付闭环}"
  tested="${AUTO_DELIVERY_TESTED:-$verify_cmd}"
  not_tested="${AUTO_DELIVERY_NOT_TESTED:-远端 CI / PR 检查未在本地 hook 中执行}"

  git commit \
    -m "$subject" \
    -m "Constraint: 仅允许在非 main 分支、敏感内容扫描通过、验证命令通过后自动提交。
Rejected: 直接在 main 提交 | 违反 CONSTITUTION.md 第零条。
Rejected: 强制合并或强制清理 | 只能在 fast-forward 合并成功且 worktree 干净时清理。
Rejected: 使用 message-file 或编辑器消息入口 | 会触发当前 OMX 提交守卫。
Confidence: medium
Scope-risk: moderate
Directive: main 未同步、main 不干净、验证失败或发现敏感内容时必须阻断合并。
Tested: $tested
Not-tested: $not_tested

Co-authored-by: OmX <omx@oh-my-codex.dev>" >> "$log_file" 2>&1
}

find_main_worktree() {
  git worktree list --porcelain | python3 -c '
import sys

records = []
current = {}
for raw in sys.stdin:
    line = raw.rstrip("\n")
    if line.startswith("worktree "):
        if current:
            records.append(current)
        current = {"worktree": line.split(" ", 1)[1]}
    elif line.startswith("branch "):
        current["branch"] = line.split(" ", 1)[1]
if current:
    records.append(current)
for record in records:
    if record.get("branch") == "refs/heads/main":
        print(record["worktree"])
        break
'
}

assert_main_ready() {
  main_worktree="$1"
  if [ -z "$main_worktree" ]; then
    finish "blocked" "未找到 main worktree，无法自动合并" 2
  fi

  if [ -n "$(git -C "$main_worktree" status --porcelain)" ]; then
    finish "blocked" "main worktree 不干净，必须人工处理后才能自动合并" 2
  fi

  if git -C "$main_worktree" rev-parse --verify origin/main >/dev/null 2>&1; then
    main_sha="$(git -C "$main_worktree" rev-parse main)"
    origin_sha="$(git -C "$main_worktree" rev-parse origin/main)"
    if [ "$main_sha" != "$origin_sha" ]; then
      finish "blocked" "main 与 origin/main 不一致，必须先同步后才能自动合并" 2
    fi
  fi
}

merge_to_main() {
  ready_status="${1:-committed}"
  ready_message="${2:-已自动提交}"

  if [ "${AUTO_DELIVERY_MERGE:-1}" != "1" ]; then
    finish "$ready_status" "$ready_message；AUTO_DELIVERY_MERGE=0，跳过合并" 0
  fi

  branch="$(current_branch)"
  main_worktree="$(find_main_worktree)"
  assert_main_ready "$main_worktree"

  git -C "$main_worktree" merge --ff-only "$branch" >> "$log_file" 2>&1 || \
    finish "blocked" "fast-forward 合并失败，需人工处理分歧" 2

  if [ "${AUTO_DELIVERY_PUSH:-0}" = "1" ]; then
    git -C "$main_worktree" push origin main >> "$log_file" 2>&1 || \
      finish "blocked" "main 合并成功，但 push origin main 失败" 2
  fi

  if [ "${AUTO_DELIVERY_CLEANUP:-1}" = "1" ] && [ "$repo_root" != "$main_worktree" ]; then
    queue_cleanup "$main_worktree" "$repo_root" "$branch" "$log_file"
    finish "merged" "已 fast-forward 合并到 main；worktree 和分支清理已排队" 0
  fi

  finish "merged" "已 fast-forward 合并到 main；按配置保留 worktree/分支" 0
}

main() {
  if ! init_repo_context; then
    if [ "$HOOK_MODE" -eq 1 ]; then
      printf '{"continue":true,"stopReason":"auto-delivery: skipped - not a git repo"}\n'
      exit 0
    fi
    printf '%s\n' "not a git repo" >&2
    exit 2
  fi

  capture_hook_payload
  log_line "start hook_mode=$HOOK_MODE dry_run=$DRY_RUN repo=$repo_root branch=$(current_branch)"

  if [ "$HOOK_MODE" -eq 1 ] && ! task_complete_detected; then
    finish "skipped" "未检测到 task_complete 事件" 0
  fi

  if [ "$DRY_RUN" = "1" ]; then
    verify_cmd="${AUTO_DELIVERY_VERIFY_CMD:-git diff --check}"
    log_line "dry-run verify: $verify_cmd"
    sh -c "$verify_cmd" >> "$log_file" 2>&1 || finish "blocked" "dry-run 验证失败：$verify_cmd" 2

    branch="$(current_branch)"
    if [ -z "$branch" ]; then
      finish "dry-run" "检测到 detached HEAD；非 dry-run 模式会阻断自动交付" 0
    fi
    if ! working_tree_has_changes; then
      finish "dry-run" "工作区没有变更；非 dry-run 模式会执行分支门禁后按配置尝试重试合并" 0
    fi
    finish "dry-run" "检测到变更；当前分支 $branch；非 dry-run 模式会执行分支门禁后再交付" 0
  fi

  assert_safe_branch

  if ! working_tree_has_changes; then
    if [ "${AUTO_DELIVERY_RETRY_MERGE:-1}" = "1" ]; then
      log_line "no worktree changes; retrying merge path"
      merge_to_main "ready" "工作区没有变更，尝试重试合并"
    fi
    finish "skipped" "工作区没有变更" 0
  fi

  stage_and_scan
  run_validation
  create_commit
  merge_to_main "committed" "已自动提交"
}

main
