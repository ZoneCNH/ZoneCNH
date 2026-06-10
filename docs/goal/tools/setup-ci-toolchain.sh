#!/usr/bin/env bash
set -euo pipefail

tool_cache="${RUNNER_TOOL_CACHE:-.goal-runner-tool-cache}"
agent_tools="${AGENT_TOOLSDIRECTORY:-$tool_cache}"
venv_dir="${GOAL_CI_VENV:-.goal-ci-venv}"
deps_dir="${GOAL_CI_PYTHON_TARGET:-.goal-ci-python}"
bin_dir="${GOAL_CI_BIN_DIR:-.goal-ci-bin}"
python_bin="${GOAL_CI_PYTHON:-python3}"

absolute_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s\n' "$PWD/$1" ;;
  esac
}

tool_cache="$(absolute_path "$tool_cache")"
agent_tools="$(absolute_path "$agent_tools")"

mkdir -p "$tool_cache" "$agent_tools"

add_github_path() {
  if [ -n "${GITHUB_PATH:-}" ]; then
    printf '%s\n' "$1" >> "$GITHUB_PATH"
  fi
}

add_github_env() {
  if [ -n "${GITHUB_ENV:-}" ]; then
    printf '%s\n' "$1" >> "$GITHUB_ENV"
  fi
}

setup_with_venv() {
  local abs_venv
  abs_venv="$(absolute_path "$venv_dir")"

  "$python_bin" -m venv "$abs_venv" || return 1
  "$abs_venv/bin/python" -m pip install --upgrade pip || return 1
  "$abs_venv/bin/python" -m pip install pyyaml yamllint || return 1
  add_github_path "$abs_venv/bin"
}

setup_with_target() {
  local abs_deps abs_bin
  abs_deps="$(absolute_path "$deps_dir")"
  abs_bin="$(absolute_path "$bin_dir")"

  if ! "$python_bin" -m pip --version >/dev/null 2>&1; then
    echo "::error::python3 pip is required when python3-venv/ensurepip is unavailable on the self-hosted runner."
    return 1
  fi

  mkdir -p "$abs_deps" "$abs_bin"
  "$python_bin" -m pip install --upgrade --target "$abs_deps" pyyaml yamllint

  cat >"$abs_bin/yamllint" <<SH
#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="$abs_deps\${PYTHONPATH:+:\$PYTHONPATH}"
exec "$python_bin" -m yamllint "\$@"
SH
  chmod +x "$abs_bin/yamllint"

  add_github_path "$abs_bin"
  add_github_env "PYTHONPATH=$abs_deps${PYTHONPATH:+:$PYTHONPATH}"
}

if [ "${GOAL_CI_FORCE_TARGET_INSTALL:-0}" = "1" ]; then
  setup_with_target
elif ! setup_with_venv; then
  echo "::warning::python3 venv is unavailable; falling back to workspace-local pip target install."
  setup_with_target
fi
