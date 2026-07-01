#!/usr/bin/env bash
# Enforce the repository deployment boundary: business repos reference SRE, they do not host it.

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

    if grep -qE '^[[:space:]]*pull_request:' "$workflow"; then
      fail "$workflow 不允许在 pull_request 触发部署。"
    fi

    if ! grep -qE '^[[:space:]]*concurrency:' "$workflow"; then
      fail "$workflow 部署 workflow 必须配置 concurrency。"
    fi

    if ! grep -qE 'uses:[[:space:]]*ZoneCNH/sre/\.github/workflows/deploy-contract\.yml@main' "$workflow"; then
      fail "$workflow 必须调用 ZoneCNH/sre/.github/workflows/deploy-contract.yml@main。"
    fi

    if grep -qE '(^|[[:space:]|;&])(ssh|scp|rsync|kubectl|helm|systemctl)([[:space:]]|$)|docker[[:space:]]+compose' "$workflow"; then
      fail "$workflow 禁止 inline 远程部署命令；请放入 SRE deploy/ 入口。"
    fi
  fi
done

note "检查完成：deployment_workflows=${deploy_count}"
