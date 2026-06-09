#!/usr/bin/env python3
"""matrix-gen.py — Matrix edge model 生成与检查脚本。

从 Spec 和 Tasks 自动生成 Traceability Matrix YAML edge。

用法:
  python3 docs/goal/tools/matrix-gen.py --spec-dir <spec目录> --task-dir <task目录> --output <输出文件>
  python3 docs/goal/tools/matrix-gen.py --check-only --matrix <matrix文件>

功能:
  --spec-dir    Spec 文件目录（扫描 *.md 中的 REQ-SPEC-*，兼容旧 Requirement 标记）
  --task-dir    Task 文件目录（扫描 TASK-GOAL-*）
  --output      输出 Matrix edge YAML 文件路径
  --check-only  仅检查现有 Matrix 的完整性
  --matrix      指定 Matrix 文件（配合 --check-only）
"""

import argparse
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

SPEC_ID_RE = re.compile(r"(?<![A-Za-z0-9-])SPEC-[A-Za-z0-9][A-Za-z0-9-]*-v\d+\b")
REQ_ID_RE = re.compile(r"(?<![A-Za-z0-9-])REQ-SPEC-[A-Za-z0-9][A-Za-z0-9-]*-v\d+-\d{3}\b")
LEGACY_REQ_RE = re.compile(r"\bFR-\d{3}\b")
TASK_ID_RE = re.compile(r"(?<![A-Za-z0-9-])TASK-GOAL-\d{8}-\d{3}-\d{3}\b")
DEFAULT_GOAL_ID = "GOAL-20260608-001"
DEFAULT_MATRIX_FILE = ".config/goal/matrix/matrix.yaml"
DEFAULT_OWNER = "goal-matrix"
EDGE_REQUIRED_FIELDS = [
    "source_id",
    "target_id",
    "relation",
    "status",
    "evidence_id",
    "gate_id",
    "owner",
    "updated_at",
]
EDGE_NON_EMPTY_FIELDS = set(EDGE_REQUIRED_FIELDS) - {"evidence_id"}
EDGE_RELATIONS = {
    "decomposes_to",
    "contains",
    "accepted_by",
    "planned_by",
    "implemented_by",
    "prompted_by",
    "verified_by",
    "evidenced_by",
}
EDGE_STATUSES = {
    "Unmapped",
    "Mapped",
    "Linked",
    "Verified",
    "Dropped",
    "Drifted",
    "Stale",
    "Blocked",
    "Changed",
}
EDGE_TERMINAL_STATUSES = {"Verified", "Dropped"}
PLACEHOLDER_ID_RE = re.compile(r"(?<![A-Za-z0-9-])[A-Za-z]+-[Xx]{2,}(?![A-Za-z0-9-])")


def clean_value(raw: str) -> str:
    value = raw.split("#", 1)[0].strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        value = value[1:-1]
    return value


def parse_inline_list(value: str) -> list[str]:
    value = clean_value(value)
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [clean_value(part) for part in inner.split(",") if clean_value(part)]
    return [value] if value else []


def as_list(value: Any) -> list[str]:
    if isinstance(value, list):
        return [str(item) for item in value]
    if isinstance(value, str):
        return parse_inline_list(value)
    return []


def yaml_scalar(value: str) -> str:
    escaped = str(value).replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def trailing_line_text(content: str, start: int) -> str:
    """提取 ID 所在行中 ID 后面的描述文本。"""
    line_end = content.find("\n", start)
    if line_end == -1:
        line_end = len(content)
    return content[start:line_end].lstrip(" :：-\t").strip()


def extract_requirements(spec_dir: str) -> list[dict]:
    """从 Spec 文件中提取 Requirements"""
    requirements = []
    spec_path = Path(spec_dir)
    if not spec_path.exists():
        print(f"[WARN] Spec 目录不存在: {spec_dir}", file=sys.stderr)
        return requirements

    for md_file in spec_path.rglob("*.md"):
        content = md_file.read_text(encoding="utf-8")
        spec_match = SPEC_ID_RE.search(content)
        spec_id = spec_match.group(0) if spec_match else md_file.stem

        seen_req_ids = set()
        for match in REQ_ID_RE.finditer(content):
            req_id = match.group(0)
            if req_id in seen_req_ids:
                continue
            seen_req_ids.add(req_id)
            desc = trailing_line_text(content, match.end()) or "Requirement extracted from spec"
            requirements.append({
                "spec_id": spec_id,
                "req_id": req_id,
                "id_format": "canonical",
                "description": desc,
            })

        for match in LEGACY_REQ_RE.finditer(content):
            req_id = match.group(0)
            if req_id in seen_req_ids:
                continue
            seen_req_ids.add(req_id)
            desc = trailing_line_text(content, match.end()) or "Legacy requirement extracted from spec"
            requirements.append({
                "spec_id": spec_id,
                "req_id": req_id,
                "id_format": "legacy",
                "description": desc,
            })

    return requirements


def extract_tasks(task_dir: str) -> list[dict]:
    """从 Task 文件中提取 Tasks"""
    tasks = []
    task_path = Path(task_dir)
    if not task_path.exists():
        print(f"[WARN] Task 目录不存在: {task_dir}", file=sys.stderr)
        return tasks

    for md_file in task_path.rglob("*.md"):
        content = md_file.read_text(encoding="utf-8")
        for match in TASK_ID_RE.finditer(content):
            task_id = match.group(0)
            tasks.append({"task_id": task_id, "file": str(md_file)})

    return tasks


def generate_matrix(requirements: list[dict], tasks: list[dict], goal_id: str = DEFAULT_GOAL_ID) -> str:
    """生成 Matrix edge YAML"""
    today = datetime.now().strftime("%Y-%m-%d")
    lines = [
        "# 自动生成的 Traceability Matrix edge model",
        f"# 生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"# Goal ID: {goal_id}",
        "# Required fields: " + ", ".join(EDGE_REQUIRED_FIELDS),
        "",
        "matrix:",
    ]

    def add_edge(
        source_id: str,
        target_id: str,
        relation: str,
        status: str,
        gate_id: str,
        note: str = "",
    ) -> None:
        lines.append(f"  - source_id: {yaml_scalar(source_id)}")
        lines.append(f"    target_id: {yaml_scalar(target_id)}")
        lines.append(f"    relation: {relation}")
        lines.append(f"    status: {status}")
        lines.append('    evidence_id: ""')
        lines.append(f"    gate_id: {gate_id}")
        lines.append(f"    owner: {DEFAULT_OWNER}")
        lines.append(f"    updated_at: {today}")
        if note:
            lines.append(f"    note: {yaml_scalar(note)}")
        lines.append("")

    spec_ids = sorted({req["spec_id"] for req in requirements if req.get("spec_id")})
    for spec_id in spec_ids:
        add_edge(goal_id, spec_id, "decomposes_to", "Linked", "G1")

    for req in requirements:
        add_edge(
            req["spec_id"],
            req["req_id"],
            "contains",
            "Linked",
            "G2",
            req.get("description", ""),
        )

    seen_tasks: set[str] = set()
    for task in tasks:
        task_id = task["task_id"]
        if task_id in seen_tasks:
            continue
        seen_tasks.add(task_id)
        add_edge(goal_id, task_id, "implemented_by", "Unmapped", "G5")

    return "\n".join(lines)


def parse_matrix(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None
    current_key: str | None = None

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        start = re.match(r"^\s*-\s+(source_id|goal_id):\s*(.*)$", raw_line)
        if start:
            if current:
                rows.append(current)
            current = {"source_id": clean_value(start.group(2))}
            current_key = "source_id"
            continue

        if current is None:
            continue

        field = re.match(r"^\s+([A-Za-z_]+):\s*(.*)$", raw_line)
        if field:
            current_key = field.group(1)
            value = clean_value(field.group(2))
            current[current_key] = parse_inline_list(value) if value.startswith("[") else value
            continue

        item = re.match(r"^\s+-\s*(.+?)\s*$", raw_line)
        if item and current_key:
            current.setdefault(current_key, [])
            if not isinstance(current[current_key], list):
                current[current_key] = []
            current[current_key].append(clean_value(item.group(1)))

    if current:
        rows.append(current)
    return rows


def check_matrix(matrix_file: str) -> dict:
    """检查现有 Matrix edge 的完整性"""
    result = {
        "missing": False,
        "total": 0,
        "terminal": 0,
        "non_terminal": 0,
        "missing_required": 0,
        "empty_required": 0,
        "invalid_relation": 0,
        "invalid_status": 0,
        "verified_without_evidence": 0,
        "dropped_without_reason": 0,
        "placeholder_ids": 0,
    }

    path = Path(matrix_file)
    if not path.exists():
        print(f"[ERROR] Matrix 文件不存在: {matrix_file}", file=sys.stderr)
        result["missing"] = True
        return result

    rows = parse_matrix(path)
    result["total"] = len(rows)

    for row in rows:
        missing = [field for field in EDGE_REQUIRED_FIELDS if field not in row]
        if missing:
            result["missing_required"] += 1

        empty = [
            field
            for field in EDGE_NON_EMPTY_FIELDS
            if field in row and not str(row.get(field, "")).strip()
        ]
        if empty:
            result["empty_required"] += 1

        relation = str(row.get("relation", "")).strip()
        status = str(row.get("status", "")).strip()
        if relation not in EDGE_RELATIONS:
            result["invalid_relation"] += 1
        if status not in EDGE_STATUSES:
            result["invalid_status"] += 1
        if status in EDGE_TERMINAL_STATUSES:
            result["terminal"] += 1

        evidence_ids = [ref for ref in as_list(row.get("evidence_id", "")) if ref]
        if status == "Verified" and not evidence_ids:
            result["verified_without_evidence"] += 1
        if status == "Dropped" and not str(row.get("drop_reason", "")).strip():
            result["dropped_without_reason"] += 1

        checked_ids = []
        checked_ids.extend(as_list(row.get("source_id", "")))
        checked_ids.extend(as_list(row.get("target_id", "")))
        checked_ids.extend(evidence_ids)
        if any(PLACEHOLDER_ID_RE.search(value) for value in checked_ids):
            result["placeholder_ids"] += 1

    result["non_terminal"] = result["total"] - result["terminal"]
    return result


def main():
    parser = argparse.ArgumentParser(description="Matrix 生成与检查工具")
    parser.add_argument("--spec-dir", help="Spec 文件目录")
    parser.add_argument("--task-dir", help="Task 文件目录")
    parser.add_argument("--output", help="输出 Matrix YAML 文件")
    parser.add_argument("--goal-id", default=DEFAULT_GOAL_ID, help="Goal ID")
    parser.add_argument("--check-only", action="store_true", help="仅检查现有 Matrix")
    parser.add_argument("--matrix", help="Matrix 文件路径（配合 --check-only）")
    args = parser.parse_args()

    if args.check_only:
        matrix_file = args.matrix or DEFAULT_MATRIX_FILE
        result = check_matrix(matrix_file)
        print("Matrix edge 完整性检查:")
        print(f"  总 edge 数:          {result['total']}")
        print(f"  已终态:              {result['terminal']}")
        print(f"  未终态:              {result['non_terminal']}")
        print(f"  缺失必填字段:        {result['missing_required']}")
        print(f"  必填字段为空:        {result['empty_required']}")
        print(f"  非法 relation:       {result['invalid_relation']}")
        print(f"  非法 status:         {result['invalid_status']}")
        print(f"  Verified 缺 evidence: {result['verified_without_evidence']}")
        print(f"  Dropped 缺原因:      {result['dropped_without_reason']}")
        print(f"  占位 ID:             {result['placeholder_ids']}")

        if result["missing"] or result["total"] == 0:
            sys.exit(1)

        if result['total'] > 0:
            coverage = result['terminal'] * 100 // result['total']
            print(f"  覆盖率:        {coverage}%")
            if (
                coverage < 60
                or result["missing_required"] > 0
                or result["empty_required"] > 0
                or result["invalid_relation"] > 0
                or result["invalid_status"] > 0
                or result["verified_without_evidence"] > 0
                or result["dropped_without_reason"] > 0
                or result["placeholder_ids"] > 0
            ):
                sys.exit(1)
        sys.exit(0)

    if not args.spec_dir or not args.task_dir:
        print("生成模式需要 --spec-dir 和 --task-dir", file=sys.stderr)
        sys.exit(1)

    requirements = extract_requirements(args.spec_dir)
    tasks = extract_tasks(args.task_dir)

    print(f"发现 {len(requirements)} 个 Requirement，{len(tasks)} 个 Task")

    yaml_content = generate_matrix(requirements, tasks, args.goal_id)

    if args.output:
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(yaml_content, encoding="utf-8")
        print(f"Matrix 已写入: {args.output}")
    else:
        print(yaml_content)


if __name__ == "__main__":
    main()
