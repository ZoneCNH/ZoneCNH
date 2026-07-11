#!/usr/bin/env bash
# registry-lint-test.sh — registry.repo 托管身份回归测试

set -euo pipefail

root="$(git rev-parse --show-toplevel)"
lint="$root/.github/ci/registry-lint.sh"
source_registry="$root/module/registry.yaml"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

make_fixture() {
  local output="$1"
  local module="$2"
  local repo="$3"

  python3 - "$source_registry" "$output" "$module" "$repo" <<'PYEOF'
import sys

import yaml

source, output, module, repo = sys.argv[1:]
with open(source, encoding="utf-8") as registry_file:
    registry = yaml.safe_load(registry_file)
registry[module]["repo"] = repo
with open(output, "w", encoding="utf-8") as fixture_file:
    yaml.safe_dump(registry, fixture_file, sort_keys=False, allow_unicode=True)
PYEOF
}

expect_failure() {
  local label="$1"
  local fixture="$2"
  local expected="$3"
  local output="$tmp_dir/${label}.log"

  if timeout 30s env REGISTRY_PATH="$fixture" bash "$lint" >"$output" 2>&1; then
    printf 'registry-lint-test: %s: expected failure\n' "$label" >&2
    return 1
  fi
  if ! grep -Fq "$expected" "$output"; then
    printf 'registry-lint-test: %s: missing diagnostic: %s\n' "$label" "$expected" >&2
    sed -n '1,160p' "$output" >&2
    return 1
  fi
}

# 当前 registry 同时覆盖 xhyperium 与 ZoneCNH 托管 owner，均应通过。
timeout 30s env REGISTRY_PATH="$source_registry" bash "$lint" >"$tmp_dir/valid.log"

make_fixture "$tmp_dir/invalid-owner.yaml" kernel "github.com/-invalid/kernel"
expect_failure invalid-owner "$tmp_dir/invalid-owner.yaml" "不是合法 GitHub owner"

make_fixture "$tmp_dir/kebab-repo.yaml" domain_market "github.com/xhyperium/domain-market"
expect_failure kebab-repo "$tmp_dir/kebab-repo.yaml" "必须使用 snake_case"

make_fixture "$tmp_dir/mismatched-repo.yaml" kernel "github.com/xhyperium/not_kernel"
expect_failure mismatched-repo "$tmp_dir/mismatched-repo.yaml" "必须与模块名一致"

make_fixture "$tmp_dir/invalid-shape.yaml" kernel "https://github.com/xhyperium/kernel"
expect_failure invalid-shape "$tmp_dir/invalid-shape.yaml" "应为 github.com/<owner>/<repo>"

printf 'registry-lint-test: all repository identity cases passed\n'
