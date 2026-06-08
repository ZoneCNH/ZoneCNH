#!/usr/bin/env python3
"""
matrix-gen.py — Matrix 生成与更新脚本
从 Spec 和 Tasks 自动生成 Traceability Matrix YAML。

用法:
  python3 docs/goal/tools/matrix-gen.py --spec-dir <spec目录> --task-dir <task目录> --output <输出文件>
  python3 docs/goal/tools/matrix-gen.py --check-only --matrix <matrix文件>

功能:
  --spec-dir    Spec 文件目录（扫描 *.md 中的 FR-xxx）
  --task-dir    Task 文件目录（扫描 TASK-xxx）
  --output      输出 Matrix YAML 文件路径
  --check-only  仅检查现有 Matrix 的完整性
  --matrix      指定 Matrix 文件（配合 --check-only）
"""

import argparse
import os
import re
import sys
from pathlib import Path
from datetime import datetime


def extract_requirements(spec_dir: str) -> list[dict]:
    """从 Spec 文件中提取 Requirements"""
    requirements = []
    spec_path = Path(spec_dir)
    if not spec_path.exists():
        print(f"[WARN] Spec 目录不存在: {spec_dir}", file=sys.stderr)
        return requirements

    for md_file in spec_path.rglob("*.md"):
        content = md_file.read_text(encoding="utf-8")
        spec_match = re.search(r"Spec\s*(?:ID|编号)[:\s]*(\S+)", content)
        spec_id = spec_match.group(1) if spec_match else md_file.stem

        for match in re.finditer(r"(FR-\d+)[:\s]+(.+?)(?:\n|$)", content):
            fr_id = match.group(1)
            desc = match.group(2).strip()
            requirements.append({
                "spec_id": spec_id,
                "req_id": fr_id,
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
        for match in re.finditer(r"TASK-[\w-]+", content):
            task_id = match.group(0)
            tasks.append({"task_id": task_id, "file": str(md_file)})

    return tasks


def generate_matrix(requirements: list[dict], tasks: list[dict], goal_id: str = "GOAL-AUTO") -> str:
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
        lines.append(f'    task_id: ""  # TODO: 填入对应 Task ID')
        lines.append(f'    code_module: ""  # TODO: 填入代码模块')
        lines.append(f'    test_case: ""  # TODO: 填入测试用例')
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
            lines.append(f'    code_module: ""')
            lines.append(f'    test_case: ""')
            lines.append(f"    status: Unmapped")
            lines.append(f"    risk: Medium")
            lines.append("")

    return "\n".join(lines)


def check_matrix(matrix_file: str) -> dict:
    """检查现有 Matrix 的完整性"""
    result = {"total": 0, "mapped": 0, "unmapped": 0, "orphan_tasks": 0, "missing_tests": 0}

    path = Path(matrix_file)
    if not path.exists():
        print(f"[ERROR] Matrix 文件不存在: {matrix_file}", file=sys.stderr)
        return result

    content = path.read_text(encoding="utf-8")

    entries = re.findall(r"- goal_id:", content)
    result["total"] = len(entries)

    mapped = re.findall(r"status:\s*(Done|Implemented|Tested)", content)
    result["mapped"] = len(mapped)
    result["unmapped"] = result["total"] - result["mapped"]

    empty_tasks = re.findall(r'task_id:\s*""', content)
    result["orphan_tasks"] = len(empty_tasks)

    empty_tests = re.findall(r'test_case:\s*""', content)
    result["missing_tests"] = len(empty_tests)

    return result


def main():
    parser = argparse.ArgumentParser(description="Matrix 生成与检查工具")
    parser.add_argument("--spec-dir", help="Spec 文件目录")
    parser.add_argument("--task-dir", help="Task 文件目录")
    parser.add_argument("--output", help="输出 Matrix YAML 文件")
    parser.add_argument("--goal-id", default="GOAL-AUTO", help="Goal ID")
    parser.add_argument("--check-only", action="store_true", help="仅检查现有 Matrix")
    parser.add_argument("--matrix", help="Matrix 文件路径（配合 --check-only）")
    args = parser.parse_args()

    if args.check_only:
        matrix_file = args.matrix or ".agent/matrix.yaml"
        result = check_matrix(matrix_file)
        print(f"Matrix 完整性检查:")
        print(f"  总行数:        {result['total']}")
        print(f"  已完成:        {result['mapped']}")
        print(f"  未完成:        {result['unmapped']}")
        print(f"  孤儿 Task:     {result['orphan_tasks']}")
        print(f"  缺失测试覆盖:  {result['missing_tests']}")

        if result['total'] > 0:
            coverage = result['mapped'] * 100 // result['total']
            print(f"  覆盖率:        {coverage}%")
            if coverage < 70:
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
