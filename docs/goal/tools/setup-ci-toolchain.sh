#!/usr/bin/env bash
set -euo pipefail

tool_cache="${RUNNER_TOOL_CACHE:-$PWD/.goal-runner-tool-cache}"
agent_tools="${AGENT_TOOLSDIRECTORY:-$tool_cache}"
venv_dir="${GOAL_CI_VENV:-.goal-ci-venv}"

mkdir -p "$tool_cache" "$agent_tools"

python3 -m venv "$venv_dir"
"$venv_dir/bin/python" -m pip install --upgrade pip
"$venv_dir/bin/python" -m pip install pyyaml yamllint

if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$PWD/$venv_dir/bin" >> "$GITHUB_PATH"
fi
