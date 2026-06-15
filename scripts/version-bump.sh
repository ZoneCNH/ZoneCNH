#!/usr/bin/env bash
# version-bump.sh — 自动递增 Foundation v2 文档发布版本号
#
# 操作对象：
#   - release/manifest/latest.json     → version 字段（主文档发布版本）
#   - .repo-contract.yaml              → trust_hardening.ruleset 字段（信任规则版本）
#   - .foundationx/repo-contract.json   → trust_hardening.ruleset 字段（JSON 镜像）
#
# 用法：
#   ./scripts/version-bump.sh                          # patch bump (默认)
#   ./scripts/version-bump.sh --level patch            # v1.0.1 → v1.0.2
#   ./scripts/version-bump.sh --level minor            # v1.0.1 → v1.1.0
#   ./scripts/version-bump.sh --level major            # v1.0.1 → v2.0.0
#   ./scripts/version-bump.sh --target trust           # bump trust_hardening.ruleset
#   ./scripts/version-bump.sh --dry-run                # 预览但不写入
#
# 退出码：
#   0 - bump 成功
#   1 - 版本格式错误
#   2 - 文件不存在

set -euo pipefail

LEVEL="patch"
TARGET="manifest"
DRY_RUN=false

# ── 参数解析 ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --level)
      LEVEL="$2"
      shift 2
      ;;
    --target)
      TARGET="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# //'
      exit 0
      ;;
    *)
      echo "❌ 未知参数: $1"
      echo "用法: $0 [--level patch|minor|major] [--target manifest|trust] [--dry-run]"
      exit 1
      ;;
  esac
done

# ── 语义化版本 bump 函数 ──────────────────────────────────────────
bump_semver() {
  local version="$1"
  local level="$2"

  # 去掉 v 前缀
  local raw="${version#v}"
  # 去掉后缀（如 -spec, -foundation-v2 等）
  local suffix=""
  if [[ "$raw" =~ ^([0-9]+\.[0-9]+\.[0-9]+)(.*)$ ]]; then
    raw="${BASH_REMATCH[1]}"
    suffix="${BASH_REMATCH[2]}"
  fi

  IFS='.' read -r major minor patch <<< "$raw"

  # 验证数字
  if [[ -z "$major" || -z "$minor" || -z "$patch" ]]; then
    echo "❌ 无法解析版本号: $version" >&2
    exit 1
  fi

  case "$level" in
    major)
      major=$((major + 1))
      minor=0
      patch=0
      ;;
    minor)
      minor=$((minor + 1))
      patch=0
      ;;
    patch)
      patch=$((patch + 1))
      ;;
    *)
      echo "❌ 未知 bump level: $level (支持 patch/minor/major)" >&2
      exit 1
      ;;
  esac

  echo "v${major}.${minor}.${patch}${suffix}"
}

# ── 获取当前版本 ──────────────────────────────────────────────────
CURRENT_VERSION=""
FILE_PATH=""
FIELD_PATH=""

case "$TARGET" in
  manifest)
    FILE_PATH="release/manifest/latest.json"
    if [[ ! -f "$FILE_PATH" ]]; then
      echo "❌ 文件不存在: $FILE_PATH" >&2
      exit 2
    fi
    CURRENT_VERSION=$(python3 -c "
import json
with open('$FILE_PATH') as f:
    data = json.load(f)
print(data.get('version', ''))
")
    FIELD_PATH="version"
    ;;
  trust)
    FILE_PATH=".repo-contract.yaml"
    if [[ ! -f "$FILE_PATH" ]]; then
      echo "❌ 文件不存在: $FILE_PATH" >&2
      exit 2
    fi
    CURRENT_VERSION=$(python3 -c "
import yaml, sys
try:
    with open('$FILE_PATH') as f:
        data = yaml.safe_load(f)
    print(data.get('trust_hardening', {}).get('ruleset', ''))
except ImportError:
    # fallback: grep-based extraction
    import subprocess, sys
    result = subprocess.run(['grep', '-oP', 'ruleset:\\s*\\Kv[0-9.]+', '$FILE_PATH'],
                          capture_output=True, text=True)
    print(result.stdout.strip())
" 2>/dev/null || grep -oP 'ruleset:\s*\Kv[0-9.]+' "$FILE_PATH" | head -1)
    FIELD_PATH="trust_hardening.ruleset"
    ;;
  *)
    echo "❌ 未知 target: $TARGET (支持 manifest/trust)" >&2
    exit 1
    ;;
esac

if [[ -z "$CURRENT_VERSION" ]]; then
  echo "❌ 无法从 $FILE_PATH 读取当前版本" >&2
  exit 2
fi

# ── 计算新版本 ────────────────────────────────────────────────────
NEW_VERSION=$(bump_semver "$CURRENT_VERSION" "$LEVEL")

# ── 输出 ──────────────────────────────────────────────────────────
if $DRY_RUN; then
  echo "[DRY RUN] $CURRENT_VERSION → $NEW_VERSION  ($FILE_PATH :: $FIELD_PATH)"
  echo "  bump level: $LEVEL"
  exit 0
fi

# ── 写入 ──────────────────────────────────────────────────────────
NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

case "$TARGET" in
  manifest)
    python3 -c "
import json, sys
with open('$FILE_PATH') as f:
    data = json.load(f)
old = data.get('version', '?')
data['version'] = '$NEW_VERSION'
data['generated_at'] = '$NOW'
with open('$FILE_PATH', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
" && echo "✅ $FILE_PATH: $CURRENT_VERSION → $NEW_VERSION (level=$LEVEL, at=$NOW)"
    ;;

  trust)
    # Bump .repo-contract.yaml
    python3 -c "
import re
with open('$FILE_PATH') as f:
    content = f.read()
old_line = re.search(r'(trust_hardening:\s*\n\s+ruleset:\s*)(v[0-9.]+)', content)
if old_line:
    print(f'  found ruleset: {old_line.group(2)}')
new_content = re.sub(
    r'(trust_hardening:\s*\n\s+ruleset:\s*)(v[0-9.]+)',
    r'\g<1>$NEW_VERSION',
    content,
    count=1
)
with open('$FILE_PATH', 'w') as f:
    f.write(new_content)
" && echo "✅ $FILE_PATH: trust_hardening.ruleset $CURRENT_VERSION → $NEW_VERSION (level=$LEVEL)"

    # 同步 JSON 镜像
    if [[ -f .foundationx/repo-contract.json ]]; then
      python3 -c "
import json
with open('.foundationx/repo-contract.json') as f:
    data = json.load(f)
old = data.get('trust_hardening', {}).get('ruleset', '?')
data.setdefault('trust_hardening', {})['ruleset'] = '$NEW_VERSION'
with open('.foundationx/repo-contract.json', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
" && echo "✅ .foundationx/repo-contract.json: sync'd ruleset → $NEW_VERSION"
    fi

    # 同步 status index
    if [[ -f .foundationx/status/index.json ]]; then
      python3 -c "
import json
with open('.foundationx/status/index.json') as f:
    data = json.load(f)
old = data.get('trust_hardening', {}).get('ruleset', '?')
data.setdefault('trust_hardening', {})['ruleset'] = '$NEW_VERSION'
with open('.foundationx/status/index.json', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
" && echo "✅ .foundationx/status/index.json: sync'd trust_hardening.ruleset → $NEW_VERSION"
    fi
    ;;
esac

echo ""
echo "📋 版本号递增完成。"
echo "   别忘了 commit 并 push — git 历史会记录每次 bump。"
