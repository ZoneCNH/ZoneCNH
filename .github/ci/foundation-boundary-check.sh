#!/usr/bin/env bash
set -euo pipefail

MATRIX_PATH="${FOUNDATION_BOUNDARY_MATRIX:-module/FOUNDATION-DEPS.yaml}"
WORKDIR="${FOUNDATION_BOUNDARY_WORKDIR:-/tmp/foundation-boundary-check}"
REQUIRE_SOURCES="${FOUNDATION_BOUNDARY_REQUIRE_SOURCES:-false}"

if [ "$REQUIRE_SOURCES" != "true" ] && [ "$REQUIRE_SOURCES" != "false" ]; then
    echo "ERROR: FOUNDATION_BOUNDARY_REQUIRE_SOURCES must be 'true' or 'false' (got: $REQUIRE_SOURCES)"
    exit 2
fi

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR/sources"

python3 - "$MATRIX_PATH" "$WORKDIR/sources" "$REQUIRE_SOURCES" <<'PYEOF'
import os
import re
import subprocess
import sys
from pathlib import Path

import yaml


matrix_path = Path(sys.argv[1])
clone_root = Path(sys.argv[2])
require_sources = sys.argv[3] == "true"
source_root = Path(os.environ.get("FOUNDATION_BOUNDARY_SOURCE_ROOT", "/home"))
module_filter = os.environ.get("FOUNDATION_BOUNDARY_MODULES") or os.environ.get("FOUNDATION_DEPS_MODULES", "")

with matrix_path.open("r", encoding="utf-8") as f:
    matrix = yaml.safe_load(f)

modules = matrix.get("modules", {})
allowed_deps = matrix.get("allowed_deps", {})
forbidden_deps = list(dict.fromkeys(matrix.get("forbidden_deps", [])))
forbidden_edges = matrix.get("forbidden_foundation_edges", [])
module_paths = {
    name: data.get("path", f"github.com/ZoneCNH/{name}")
    for name, data in modules.items()
}

if module_filter.strip():
    selected_modules = [item for item in re.split(r"[\s,]+", module_filter.strip()) if item]
else:
    selected_modules = list(modules)

unknown = [name for name in selected_modules if name not in modules]
if unknown:
    print(f"ERROR: unknown module(s): {', '.join(unknown)}", file=sys.stderr)
    sys.exit(2)


def is_import_prefix(import_path, target_path):
    return import_path == target_path or import_path.startswith(target_path + "/")


def module_for_import(import_path):
    matches = [
        (name, path)
        for name, path in module_paths.items()
        if is_import_prefix(import_path, path)
    ]
    if not matches:
        return None
    return max(matches, key=lambda item: len(item[1]))[0]


def is_external_import(import_path):
    first = import_path.split("/", 1)[0]
    return "." in first


def is_test_file(path):
    parts = set(path.parts)
    return (
        path.name.endswith("_test.go")
        or "testdata" in parts
        or "tests" in parts
        or "test" in parts
    )


def iter_go_files(root):
    ignored_dirs = {".git", ".omx", ".worktree", "vendor"}
    for path in root.rglob("*.go"):
        rel_parts = path.relative_to(root).parts
        if any(part in ignored_dirs for part in rel_parts):
            continue
        yield path


def parse_imports(path):
    imports = []
    in_block = False
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except UnicodeDecodeError:
        lines = path.read_text(errors="ignore").splitlines()

    for line_no, line in enumerate(lines, start=1):
        stripped = line.split("//", 1)[0].strip()
        if not stripped:
            continue

        if not in_block:
            if not stripped.startswith("import "):
                continue
            rest = stripped[len("import "):].strip()
            if rest.startswith("("):
                in_block = True
                rest = rest[1:].strip()
                if ")" in rest:
                    rest = rest.split(")", 1)[0]
                    in_block = False
                for match in re.finditer(r'"([^"]+)"', rest):
                    imports.append((line_no, match.group(1)))
            else:
                match = re.search(r'"([^"]+)"', rest)
                if match:
                    imports.append((line_no, match.group(1)))
            continue

        if ")" in stripped:
            before_close = stripped.split(")", 1)[0]
            in_block = False
            stripped = before_close

        for match in re.finditer(r'"([^"]+)"', stripped):
            imports.append((line_no, match.group(1)))

    return imports


def expand_target(target):
    if target == "business":
        return forbidden_deps
    if target == "x.go":
        return ["github.com/ZoneCNH/x.go"]
    if target in module_paths:
        return [module_paths[target]]
    if target.startswith("github.com/"):
        return [target]
    return []


def resolve_source(module_name):
    expected_module_path = module_paths[module_name]
    candidates = list(dict.fromkeys([
        source_root / module_name,
        Path("/home") / module_name,
    ]))
    for candidate in candidates:
        gomod = candidate / "go.mod"
        if not gomod.exists():
            continue
        module_match = re.search(
            r"(?m)^\s*module\s+(\S+)",
            gomod.read_text(encoding="utf-8", errors="ignore"),
        )
        current_module_path = module_match.group(1) if module_match else ""
        if current_module_path == expected_module_path:
            return candidate, "local"
        return candidate, f"module-mismatch:{current_module_path or '<missing>'}"

    module_path = module_paths[module_name]
    clone_dir = clone_root / module_name
    repo_url = f"https://{module_path}.git"
    env = os.environ.copy()
    env["GIT_TERMINAL_PROMPT"] = "0"
    try:
        result = subprocess.run(
            ["git", "clone", "--depth=1", repo_url, str(clone_dir)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=env,
            timeout=120,
        )
    except subprocess.TimeoutExpired:
        return None, f"clone timeout after 120s: {repo_url}"
    if result.returncode == 0:
        gomod = clone_dir / "go.mod"
        module_match = re.search(
            r"(?m)^\s*module\s+(\S+)",
            gomod.read_text(encoding="utf-8", errors="ignore") if gomod.exists() else "",
        )
        current_module_path = module_match.group(1) if module_match else ""
        if current_module_path != expected_module_path:
            return clone_dir, f"module-mismatch:{current_module_path or '<missing>'}"
        return clone_dir, "clone"
    return None, result.stderr.strip().splitlines()[-1] if result.stderr.strip() else "clone failed"


edge_rules = {}
edge_descriptions = {}
config_errors = []
for edge in forbidden_edges:
    source = edge.get("from")
    targets = edge.get("to", [])
    if source not in modules and source != "production":
        config_errors.append(f"unknown forbidden edge source: {source}")
        continue
    expanded = []
    for target in targets:
        target_paths = expand_target(target)
        if not target_paths:
            config_errors.append(f"unknown forbidden edge target: {source} -> {target}")
            continue
        expanded.extend((target, target_path) for target_path in target_paths)
    edge_rules[source] = expanded
    edge_descriptions[source] = edge.get("rule", "")

if config_errors:
    for error in config_errors:
        print(f"ERROR: {error}", file=sys.stderr)
    sys.exit(2)

print(f"Foundation boundary matrix: {matrix_path}")
print(f"Selected modules: {', '.join(selected_modules)}")
print(f"Require sources: {str(require_sources).lower()}")
print("")

violations = []
skipped = []
checked_modules = 0
go_file_count = 0
import_count = 0

for module_name in selected_modules:
    source_dir, source_kind = resolve_source(module_name)
    if isinstance(source_kind, str) and source_kind.startswith("module-mismatch:"):
        current_module_path = source_kind.split(":", 1)[1]
        print(f"FAIL {module_name}: {source_dir} has module {current_module_path}")
        violations.append((
            module_name,
            Path("go.mod"),
            1,
            current_module_path,
            "module-path",
            f"expected module path {module_paths[module_name]}",
        ))
        continue
    if source_dir is None:
        skipped.append((module_name, source_kind))
        print(f"SKIP {module_name}: {source_kind}")
        continue

    checked_modules += 1
    print(f"CHECK {module_name}: {source_dir} ({source_kind})")
    module_imports = []
    for go_file in iter_go_files(source_dir):
        go_file_count += 1
        rel_path = go_file.relative_to(source_dir)
        test_file = is_test_file(rel_path)
        for line_no, import_path in parse_imports(go_file):
            import_count += 1
            module_imports.append((rel_path, line_no, import_path, test_file))

    allowed = set(allowed_deps.get(module_name, []))
    self_path = module_paths[module_name]

    for rel_path, line_no, import_path, test_file in module_imports:
        target_module = module_for_import(import_path)

        if modules[module_name].get("stdlib_only") and is_external_import(import_path):
            if not is_import_prefix(import_path, self_path):
                violations.append((
                    module_name,
                    rel_path,
                    line_no,
                    import_path,
                    "stdlib-only",
                    "stdlib-only modules may not import external packages",
                ))

        if target_module and target_module != module_name:
            if target_module == "testkitx" and test_file:
                pass
            elif target_module not in allowed:
                violations.append((
                    module_name,
                    rel_path,
                    line_no,
                    import_path,
                    "allowed_deps",
                    f"{module_name} may only import Foundation modules listed in allowed_deps",
                ))

        for target_path in forbidden_deps:
            if is_import_prefix(import_path, target_path):
                violations.append((
                    module_name,
                    rel_path,
                    line_no,
                    import_path,
                    "forbidden_deps",
                    "Foundation modules must not import business or entry repositories",
                ))

        for target_name, target_path in edge_rules.get(module_name, []):
            if target_name == "testkitx" and test_file:
                continue
            if is_import_prefix(import_path, target_path):
                violations.append((
                    module_name,
                    rel_path,
                    line_no,
                    import_path,
                    f"forbidden_foundation_edges:{target_name}",
                    edge_descriptions.get(module_name, ""),
                ))

        for target_name, target_path in edge_rules.get("production", []):
            if module_name == target_name or test_file:
                continue
            if is_import_prefix(import_path, target_path):
                violations.append((
                    module_name,
                    rel_path,
                    line_no,
                    import_path,
                    "production-testkitx",
                    edge_descriptions.get("production", ""),
                ))

if require_sources and skipped:
    for module_name, reason in skipped:
        violations.append((
            module_name,
            Path("<source>"),
            0,
            reason,
            "missing-source",
            "FOUNDATION_BOUNDARY_REQUIRE_SOURCES=true requires every selected module to be readable",
        ))

print("")
print("── Foundation Boundary Summary ──")
print(f"CHECKED_MODULES: {checked_modules}  SKIP: {len(skipped)}  GO_FILES: {go_file_count}  IMPORTS: {import_count}")

if violations:
    print(f"FAIL: {len(violations)} boundary violation(s)")
    for module_name, rel_path, line_no, import_path, rule, message in violations:
        location = f"{module_name}:{rel_path}"
        if line_no:
            location = f"{location}:{line_no}"
        print(f"  {location}: {import_path} violates {rule}")
        if message:
            print(f"    {message}")
    sys.exit(1)

print("PASS: no forbidden import edges found")
PYEOF
