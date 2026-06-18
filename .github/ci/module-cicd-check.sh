#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

failures=0

required_jobs=(
  "ci-preflight"
  "build"
  "test"
  "lint"
  "boundary"
  "integration"
  "secret-scan"
  "evidence"
  "release-preflight"
  "release-publish"
  "post-release-smoke"
  "rollback-drill"
)

required_tokens=(
  "pull_request:"
  "push:"
  "tags:"
  "workflow_dispatch:"
  "permissions:"
  "concurrency:"
  "SRE_CI_POOL: \"sre/"
  "SRE_DEPLOY_POOL: \"sre/deploy\""
  "runs-on: [self-hosted, Linux, X64, sre/"
)

report_failure() {
  local module="$1"
  local message="$2"
  printf 'module-cicd-check: %s: %s\n' "$module" "$message" >&2
  failures=$((failures + 1))
}

while IFS= read -r -d '' module_dir; do
  module="${module_dir#module/}"
  file="$module_dir/ci-workflow.yaml"

  if [[ ! -f "$file" ]]; then
    report_failure "$module" "missing ci-workflow.yaml"
    continue
  fi

  if ! grep -Fq "github.com/ZoneCNH/${module}/.github/workflows/ci.yml" "$file"; then
    report_failure "$module" "missing module repository workflow target"
  fi

  for token in "${required_tokens[@]}"; do
    if ! grep -Fq "$token" "$file"; then
      report_failure "$module" "missing required token: $token"
    fi
  done

  for job in "${required_jobs[@]}"; do
    if ! grep -Eq "^[[:space:]]{2}${job}:" "$file"; then
      report_failure "$module" "missing required job: $job"
    fi
  done

  bad_runs_on="$(grep -nE '^[[:space:]]*runs-on:' "$file" | grep -Ev 'runs-on: \[self-hosted, Linux, X64, sre/[^]]+\]' || true)"
  if [[ -n "$bad_runs_on" ]]; then
    report_failure "$module" "non-SRE runs-on found: ${bad_runs_on//$'\n'/; }"
  fi

  if grep -nE '^[[:space:]]*runs-on:.*(ubuntu-latest|windows-latest|macos-latest)' "$file" >/dev/null; then
    report_failure "$module" "GitHub-hosted runner is forbidden"
  fi

  if grep -nE '(^|[[:space:]])(ssh|scp|rsync|kubectl|helm|systemctl)([[:space:]]|$)|docker compose' "$file" >/dev/null; then
    report_failure "$module" "inline remote deployment command is forbidden"
  fi
done < <(find module -mindepth 1 -maxdepth 1 -type d ! -name '_template' -print0 | sort -z)

if [[ "$failures" -gt 0 ]]; then
  printf 'module-cicd-check: %d failure(s)\n' "$failures" >&2
  exit 1
fi

printf 'module-cicd-check: all module CI/CD contracts use sre/ machine pools\n'
