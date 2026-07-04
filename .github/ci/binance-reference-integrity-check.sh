#!/usr/bin/env bash
# binance-reference-integrity-check.sh — 校验 SPEC/TRACEABILITY 文件引用存在性

set -euo pipefail

SCRIPT_TIMEOUT_SECONDS="${SCRIPT_TIMEOUT_SECONDS:-120}"
if ! [[ "$SCRIPT_TIMEOUT_SECONDS" =~ ^[0-9]+$ ]] || [ "$SCRIPT_TIMEOUT_SECONDS" -le 0 ]; then
  echo "FAIL: SCRIPT_TIMEOUT_SECONDS must be a positive integer" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TARGET_FILES=(
  "module/binance/spec/SPEC.md"
  "module/binance/spec/client/SPEC.md"
  "module/binance/spec/server/SPEC.md"
  "module/binance/matrix/TRACEABILITY.md"
  "module/binance/matrix/client/TRACEABILITY.md"
  "module/binance/matrix/server/TRACEABILITY.md"
)

for rel in "${TARGET_FILES[@]}"; do
  if [ ! -f "$REPO_ROOT/$rel" ]; then
    echo "FAIL: missing target file: $rel" >&2
    exit 1
  fi
done

if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_CMD=(timeout "${SCRIPT_TIMEOUT_SECONDS}s")
else
  TIMEOUT_CMD=()
fi

"${TIMEOUT_CMD[@]}" python3 - "$REPO_ROOT" "${TARGET_FILES[@]}" <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
targets = [root / rel for rel in sys.argv[2:]]

missing: set[tuple[str, str, str]] = set()


def strip_fenced_code(text: str) -> str:
    return re.sub(r"```[\s\S]*?```", "", text)


def normalize_target(raw: str) -> str:
    target = raw.strip()
    if not target:
        return ""
    # markdown link target may be "path.md \"title\""
    target = target.split()[0].strip("<>")
    target = target.split("#", 1)[0]
    return target


def should_skip(target: str) -> bool:
    return (
        target == ""
        or target.startswith("#")
        or target.startswith("http://")
        or target.startswith("https://")
        or target.startswith("mailto:")
        or target.startswith("tel:")
    )


def resolve_path(src: Path, target: str) -> Path:
    if target.startswith("/"):
        return (root / target.lstrip("/")).resolve()
    if target.startswith("module/"):
        return (root / target).resolve()
    return (src.parent / target).resolve()


def to_rel(path: Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


link_re = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
backtick_re = re.compile(r"`([A-Za-z0-9_./-]+\.md(?:#[A-Za-z0-9._/-]+)?)`")

for src in targets:
    text = strip_fenced_code(src.read_text(encoding="utf-8"))
    candidates = []
    candidates.extend(link_re.findall(text))

    # 移除 markdown links，避免把 link label 里的 `path` 当成独立引用重复检查。
    text_without_links = link_re.sub("", text)
    candidates.extend(backtick_re.findall(text_without_links))

    for raw in candidates:
        target = normalize_target(raw)
        if should_skip(target):
            continue
        if not target.endswith(".md"):
            continue
        resolved = resolve_path(src, target)
        if (
            not resolved.exists()
            and not target.startswith(".")
            and not target.startswith("..")
            and not target.startswith("/")
            and not target.startswith("module/")
        ):
            resolved = (root / target).resolve()
        if not resolved.exists():
            missing.add((to_rel(src), raw, to_rel(resolved)))

if missing:
    print("FAIL: missing file references in SPEC/TRACEABILITY")
    for src, raw, resolved in sorted(missing):
        print(f"  - {src}: `{raw}` -> {resolved} (not found)")
    sys.exit(1)

print("PASS: SPEC/TRACEABILITY file references are valid")
PY
