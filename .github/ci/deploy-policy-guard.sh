#!/usr/bin/env bash
# deploy-policy-guard.sh — 强制执行 CICD-001 部署隔离规则
# 检查项：sre/deploy pool 强制 | 禁止 PR 触发部署 | concurrency 互斥 |
#         ZoneCNH/sre reusable workflow 调用 | 禁止 inline 部署命令 |
#         self-hosted runner 强制

set -euo pipefail

fail() {
  echo "::error::$*"
  exit 1
}

note() {
  echo "deploy-policy-guard: $*"
}

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

if [[ ! -f .gitignore ]] || ! grep -q '^sre/$' .gitignore; then
  fail "本仓库必须在 .gitignore 保持 sre/；SRE 控制面不能被主页仓库收纳。"
fi

if git ls-files | grep -q '^sre/'; then
  fail "检测到已跟踪的 sre/ 路径；部署控制面必须保留在 ZoneCNH/sre 独立仓库。"
fi

mapfile -t workflows < <(find .github/workflows -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) | sort 2>/dev/null || true)

deploy_count=0

for workflow in "${workflows[@]}"; do
  if [[ "$workflow" =~ (deploy|deployment) ]] \
    || grep -qE 'ZoneCNH/sre/\.github/workflows/deploy-contract\.yml|environment:[[:space:]]*(staging|production)|执行部署|生产部署|灰度部署|上线部署' "$workflow"; then
    deploy_count=$((deploy_count + 1))

    # CICD-001 §deploy: 禁止 PR 触发部署
    if grep -qE '^[[:space:]]*pull_request:' "$workflow"; then
      fail "$workflow 不允许在 pull_request 触发部署（CICD-001）。"
    fi

    # CICD-001 §deploy: concurrency 强制互斥
    if ! grep -qE '^[[:space:]]*concurrency:' "$workflow"; then
      fail "$workflow 部署 workflow 必须配置 concurrency（CICD-001）。"
    fi

    # CICD-001 §deploy: 必须调用 ZoneCNH/sre reusable workflow
    if ! grep -qE 'uses:[[:space:]]*ZoneCNH/sre/\.github/workflows/deploy-contract\.yml@main' "$workflow"; then
      fail "$workflow 必须调用 ZoneCNH/sre/.github/workflows/deploy-contract.yml@main（CICD-001）。"
    fi

    # CICD-001 §ci_cd: 禁止 inline 远程部署命令
    if grep -qE '(^|[[:space:]|;&])(ssh|scp|rsync|kubectl|helm|systemctl)([[:space:]]|$)|docker[[:space:]]+compose' "$workflow"; then
      fail "$workflow 禁止 inline 远程部署命令；请放入 SRE deploy/ 入口（CICD-001）。"
    fi

    # CICD-001: 部署 job 的 runs-on 必须使用 sre/deploy pool
    deploy_jobs=$(grep -E '^[[:space:]]{2}[a-zA-Z_-]+:' "$workflow" | sed 's/:.*//' | xargs || true)
    for job in $deploy_jobs; do
      if grep -A2 "^  ${job}:" "$workflow" | grep -qE 'environment:.*(production|staging)'; then
        runs_on=$(grep -A5 "^  ${job}:" "$workflow" | grep "runs-on:" | head -1 || true)
        if [[ -n "$runs_on" ]] && ! echo "$runs_on" | grep -qE 'sre/deploy'; then
          fail "$workflow job ${job}: deploy job 必须使用 sre/deploy pool（CICD-001）"
        fi
      fi
    done
  fi
done

note "检查完成：deployment_workflows=${deploy_count}"
