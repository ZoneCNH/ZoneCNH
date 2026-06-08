#!/usr/bin/env python3
"""
matrix-gen.py — Matrix 生成与更新脚本
从 Spec 和 Tasks 自动生成 Traceability Matrix YAML。

用法:
  python3 docs/goal/tools/matrix-gen.py --spec-dir <spec目录> --task-dir <task目录> --output <输出文件>
  python3 docs/goal/tools/matrix-gen.py --check-only --matrix <matrix文件>

功能:
  --spec-dir    Spec 文件目录（扫描 *.md 中的 REQ-SPEC-*，兼容旧 Requirement 标记）
  --task-dir    Task 文件目录（扫描 TASK-GOAL-*）
  --output      输出 Matrix YAML 文件路径
  --check-only  仅检查现有 Matrix 的完整性
  --matrix      指定 Matrix 文件（配合 --check-only）
"""

import argparse
import re
import sys
from pathlib import Path
from datetime import datetime

SPEC_ID_RE = re.compile(r"(?<![A-Za-z0-9-])SPEC-[A-Za-z0-9][A-Za-z0-9-]*-v\d+\b")
REQ_ID_RE = re.compile(r"(?<![A-Za-z0-9-])REQ-SPEC-[A-Za-z0-9][A-Za-z0-9-]*-v\d+-\d{3}\b")
LEGACY_REQ_RE = re.compile(r"\bFR-\d{3}\b")
TASK_ID_RE = re.compile(r"(?<![A-Za-z0-9-])TASK-GOAL-\d{8}-\d{3}-\d{3}\b")
DEFAULT_GOAL_ID = "GOAL-20260608-001"
DEFAULT_MATRIX_FILE = ".config/goal/matrix/matrix.yaml"


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
    """生成 Matrix YAML"""
    lines = [
        f"# 自动生成的 Traceability Matrix",
        f"# 生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"# Goal ID: {goal_id}",
        "",
        "matrix:",
    ]

    for req in requirements:
        lines.append(f"  - goal_id: {goal_id}")
        lines.append(f"    spec_id: {req['spec_id']}")
        lines.append(f"    requirement_id: {req['req_id']}")
        lines.append(f'    description: "{req["description"]}"')
        lines.append(f'    task_id: ""  # TODO: 如 TASK-GOAL-20260608-001-001')
        lines.append(f"    acceptance_criteria: []  # TODO: 如 AC-{req['req_id']}-001")
        lines.append(f'    code_module: ""  # TODO: 填入代码模块')
        lines.append(f'    test_case: ""  # TODO: 如 TEST-TASK-GOAL-20260608-001-001-001')
        lines.append(f'    prompt_id: ""  # TODO: 如 PROMPT-TASK-GOAL-20260608-001-001')
        lines.append(f"    evidence_ids: []  # TODO: 如 EVID-TEST-TASK-GOAL-20260608-001-001-001-001")
        lines.append(f"    status: Unmapped")
        lines.append(f"    risk: Low")
        lines.append("")

    mapped_tasks = set()
    orphan_tasks = [t for t in tasks if t["task_id"] not in mapped_tasks]
    if orphan_tasks:
        lines.append("  # 以下 Task 未关联到任何 Requirement（孤儿 Task）")
        for task in orphan_tasks:
            lines.append(f"  - goal_id: {goal_id}")
            lines.append(f'    spec_id: ""')
            lines.append(f'    requirement_id: ""')
            lines.append(f'    description: "孤儿 Task: {task["task_id"]}"')
            lines.append(f'    task_id: "{task["task_id"]}"')
            lines.append(f"    acceptance_criteria: []")
            lines.append(f'    code_module: ""')
            lines.append(f'    test_case: ""')
            lines.append(f'    prompt_id: ""')
            lines.append(f"    evidence_ids: []")
            lines.append(f"    status: Unmapped")
            lines.append(f"    risk: Medium")
            lines.append("")

    return "\n".join(lines)


def check_matrix(matrix_file: str) -> dict:
    """检查现有 Matrix 的完整性"""
    result = {
        "missing": False,
        "total": 0,
        "terminal": 0,
        "non_terminal": 0,
        "missing_tasks": 0,
        "orphan_tasks": 0,
        "missing_tests": 0,
        "dropped_without_reason": 0,
    }

    path = Path(matrix_file)
    if not path.exists():
        print(f"[ERROR] Matrix 文件不存在: {matrix_file}", file=sys.stderr)
        result["missing"] = True
        return result

    content = path.read_text(encoding="utf-8")

    entries = [
        entry
        for entry in re.split(r"\n(?=[ \t]*-[ \t]*goal_id:)", content)
        if re.search(r"^[ \t]*-[ \t]*goal_id:", entry, re.MULTILINE)
    ]
    result["total"] = len(entries)

    terminal = re.findall(r"status:\s*(Verified|Dropped)\b", content)
    result["terminal"] = len(terminal)
    result["non_terminal"] = result["total"] - result["terminal"]

    missing_tasks = re.findall(r'task_id:\s*""', content)
    result["missing_tasks"] = len(missing_tasks)

    orphan_tasks = re.findall(r'requirement_id:\s*""', content)
    result["orphan_tasks"] = len(orphan_tasks)

    empty_tests = re.findall(r'test_case:\s*""', content)
    result["missing_tests"] = len(empty_tests)

    for entry in entries:
        if re.search(r"status:\s*Dropped\b", entry) and not re.search(
            r"drop_reason:\s*(?!\"\"|''|$).+", entry
        ):
            result["dropped_without_reason"] += 1

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
        print(f"Matrix 完整性检查:")
        print(f"  总行数:        {result['total']}")
        print(f"  已终态:        {result['terminal']}")
        print(f"  未终态:        {result['non_terminal']}")
        print(f"  缺失 Task 映射: {result['missing_tasks']}")
        print(f"  孤儿 Task:     {result['orphan_tasks']}")
        print(f"  缺失测试覆盖:  {result['missing_tests']}")
        print(f"  Dropped 缺原因: {result['dropped_without_reason']}")

        if result["missing"] or result["total"] == 0:
            sys.exit(1)

        if result['total'] > 0:
            coverage = result['terminal'] * 100 // result['total']
            print(f"  覆盖率:        {coverage}%")
            if (
                coverage < 95
                or result["missing_tasks"] > 0
                or result["missing_tests"] > 0
                or result["dropped_without_reason"] > 0
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
