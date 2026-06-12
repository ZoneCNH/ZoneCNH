#!/usr/bin/env python3
"""
rule-scorer.py — 异构第 4 评分源（规则引擎 / 静态分析）

宪法 §14.4 要求：评分体系必须包含至少一个与 LLM 无相关性的独立信号源。
本脚本以纯机械规则评估 6 个管线阶段，输出格式与三平台 LLM scorer + rules 一致，
作为仲裁器的第 4 个证据来源。

特性：
- 零 LLM 调用：完全确定性
- 输入：单个模块的对应阶段产物
- 输出：JSON 评分（与 LLM scorer 同 schema）

用法：
  rule-scorer.py <stage> <module> [--runtime claude|codex|copilot] [--out PATH]

阶段：spec / matrix / tasks / plan / prompt / code
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RUNTIME_STATE_ROOTS = {
    "claude": ".omc/state/pipeline",
    "codex": ".omx/state/pipeline",
    "copilot": ".copilot/state/pipeline",
}


def default_runtime() -> str:
    runtime = os.environ.get("SPEC_PIPELINE_RUNTIME", "claude").lower()
    if runtime not in RUNTIME_STATE_ROOTS:
        allowed = ", ".join(sorted(RUNTIME_STATE_ROOTS))
        raise SystemExit(f"不支持的 SPEC_PIPELINE_RUNTIME={runtime!r}; 可选: {allowed}")
    return runtime


def state_root(runtime: str) -> Path:
    return ROOT / RUNTIME_STATE_ROOTS[runtime]


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


# ---------- 工具 ----------


@dataclass
class Score:
    score: int = 100
    deductions: list[dict] = field(default_factory=list)
    redline: bool = False
    confidence: str = "high"

    def deduct(self, points: int, rule: str, evidence: str):
        self.score = max(0, self.score - points)
        self.deductions.append(
            {"rule": rule, "points": points, "evidence": evidence}
        )

    def flag_redline(self, rule: str, evidence: str):
        self.redline = True
        self.deductions.append(
            {"rule": rule, "points": 0, "evidence": evidence, "redline": True}
        )

    def to_json(self, stage: str, module: str, source: str = "rules") -> dict:
        return {
            "source": source,
            "stage": stage,
            "module": module,
            "score": self.score,
            "redline": self.redline,
            "confidence": self.confidence,
            "deductions": self.deductions,
            "rule_engine_version": "1.0",
        }


def read(path: Path) -> str | None:
    if not path.exists() or not path.is_file():
        return None
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return None


def count_sections(text: str, level: int = 2) -> list[str]:
    """提取 markdown 标题。"""
    pattern = re.compile(rf"^{'#' * level} +(.+?)\s*$", re.MULTILINE)
    return [m.group(1).strip() for m in pattern.finditer(text)]


# ---------- 阶段评分 ----------


SPEC_REQUIRED_SECTIONS = [
    "Summary",
    "Problem",
    "Goals",
    "Non-goals",
    "Consumers",
    "Functional Requirements",
    "Business Rules",
    "Acceptance Criteria",
    "Test Cases",
    "Interfaces",
    "Data Model",
    "Configuration",
    "State",
    "Error Handling",
    "Edge Cases",
    "Security",
    "Observability",
    "Performance",
    "Testing Strategy",
    "CI Gate",
    "Release DoD",
    "Dependencies",
    "Rollout",
]


def score_spec(module: str) -> Score:
    s = Score()
    spec_path = ROOT / "module" / module / "SPEC.md"
    text = read(spec_path)
    if text is None:
        s.flag_redline("spec_missing", f"未找到 {spec_path.relative_to(ROOT)}")
        s.score = 0
        s.confidence = "low"
        return s

    # 1. 23 节结构（15 分）
    found_sections = {h.lower() for h in count_sections(text, 2)}
    missing = [
        sec for sec in SPEC_REQUIRED_SECTIONS if sec.lower() not in found_sections
    ]
    if missing:
        miss_pts = min(15, len(missing) * 2)
        s.deduct(miss_pts, "spec_section_missing", f"缺章节: {missing[:5]}")
        if len(missing) >= 8:
            s.flag_redline(
                "spec_skeleton_incomplete", f"缺 {len(missing)} 节，结构未成形"
            )

    # 2. Metadata 完整性（5 分）
    meta_fields = ["Status:", "Owner:", "Version:", "Updated:"]
    missing_meta = [f for f in meta_fields if f not in text[:2000]]
    if missing_meta:
        s.deduct(min(5, len(missing_meta) * 2), "spec_metadata_missing", str(missing_meta))

    # 3. FR/BR 编号规范（10 分）
    fr_ids = re.findall(r"\bFR-\d{3}\b", text)
    br_ids = re.findall(r"\bBR-\d{3}\b", text)
    if not fr_ids:
        s.deduct(5, "spec_no_fr", "未发现 FR-NNN 编号")
    if not br_ids:
        s.deduct(3, "spec_no_br", "未发现 BR-NNN 编号")
    # 唯一性
    fr_in_section = set(re.findall(r"\bFR-\d{3}\b", _section_body(text, "Functional Requirements")))
    if len(fr_ids) > len(fr_in_section) * 3:
        s.flag_redline("spec_fr_duplicate", "FR 编号过度重复（可能定义错误）")

    # 4. 追溯链：AC/TC 编号存在
    ac_ids = re.findall(r"\bAC-\d{3}\b", text)
    tc_ids = re.findall(r"\bTC-\d{3}\b", text)
    if fr_ids and not ac_ids:
        s.deduct(8, "spec_no_ac", "FR 存在但无 AC-NNN")
    if fr_ids and not tc_ids:
        s.deduct(7, "spec_no_tc", "FR 存在但无 TC-NNN")

    # 5. 行为规格 WHEN/THEN（10 分）
    when_then = len(re.findall(r"\bWHEN\b.*?\bTHEN\b", text, re.IGNORECASE | re.DOTALL))
    if fr_ids and when_then < len(fr_ids) // 2:
        s.deduct(
            8,
            "spec_when_then_sparse",
            f"FR 数 {len(fr_ids)}，WHEN/THEN 仅 {when_then}",
        )

    # 6. Blocking Open Questions（红线）
    if re.search(r"^###\s+Blocking[\s:]", text, re.MULTILINE):
        s.flag_redline("spec_blocking_open_question", "存在 Blocking Open Question")

    # 7. Non-goals 与 Edge Cases 充分性
    non_goals = re.findall(r"(?m)^- ", _section_body(text, "Non-goals"))
    if len(non_goals) < 3:
        s.deduct(4, "spec_non_goals_thin", f"Non-goals 仅 {len(non_goals)} 条 (< 3)")
    edge_cases = re.findall(r"(?m)^- ", _section_body(text, "Edge Cases"))
    if len(edge_cases) < 5:
        s.deduct(4, "spec_edge_cases_thin", f"Edge Cases 仅 {len(edge_cases)} 条 (< 5)")

    return s


def _section_body(text: str, heading: str) -> str:
    m = re.search(
        rf"^##\s+(?:\d+[. ]\s*)?{re.escape(heading)}\s*$([\s\S]*?)(?=^##\s|\Z)",
        text,
        re.MULTILINE | re.IGNORECASE,
    )
    return m.group(1) if m else ""


def score_matrix(module: str) -> Score:
    s = Score()
    candidates = [
        ROOT / "module" / module / "TRACEABILITY.md",
        ROOT / "module" / module / "MATRIX.md",
    ]
    path = next((p for p in candidates if p.exists()), None)
    if path is None:
        s.flag_redline("matrix_missing", f"未找到 {[str(p) for p in candidates]}")
        s.score = 0
        s.confidence = "low"
        return s

    text = read(path) or ""
    spec_text = read(ROOT / "module" / module / "SPEC.md") or ""

    fr_in_spec = set(re.findall(r"\bFR-\d{3}\b", spec_text))
    fr_in_matrix = set(re.findall(r"\bFR-\d{3}\b", text))
    ac_in_matrix = set(re.findall(r"\bAC-\d{3}\b", text))
    tc_in_matrix = set(re.findall(r"\bTC-\d{3}\b", text))

    # 1. FR 覆盖（25 分）
    missing_fr = fr_in_spec - fr_in_matrix
    if fr_in_spec:
        coverage = (len(fr_in_spec) - len(missing_fr)) / len(fr_in_spec)
        if coverage < 1.0:
            s.deduct(
                int((1 - coverage) * 25),
                "matrix_fr_coverage",
                f"未覆盖 FR: {sorted(missing_fr)[:5]}",
            )
        if coverage < 0.8:
            s.flag_redline(
                "matrix_fr_coverage_critical", f"FR 覆盖率 {coverage:.0%} < 80%"
            )

    # 2. AC/TC 编号存在（20 分）
    if not ac_in_matrix:
        s.deduct(10, "matrix_no_ac", "矩阵中无 AC 编号")
    if not tc_in_matrix:
        s.deduct(10, "matrix_no_tc", "矩阵中无 TC 编号")

    # 3. 表格结构（15 分）
    table_rows = len(re.findall(r"^\|.*\|.*\|", text, re.MULTILINE))
    if table_rows < 5:
        s.deduct(15, "matrix_table_thin", f"表格行数 {table_rows} < 5")
    elif table_rows < 10:
        s.deduct(5, "matrix_table_sparse", f"表格行数 {table_rows} < 10")

    # 4. 孤立 AC/TC（10 分）
    ac_in_spec = set(re.findall(r"\bAC-\d{3}\b", spec_text))
    orphan_ac = ac_in_matrix - ac_in_spec
    if orphan_ac:
        s.deduct(
            5, "matrix_orphan_ac", f"矩阵 AC 在 spec 中找不到: {sorted(orphan_ac)[:3]}"
        )

    return s


def score_tasks(module: str) -> Score:
    s = Score()
    tasks_dir = ROOT / "module" / module / "tasks"
    if not tasks_dir.exists() or not tasks_dir.is_dir():
        s.flag_redline("tasks_dir_missing", f"未找到 {tasks_dir.relative_to(ROOT)}")
        s.score = 0
        s.confidence = "low"
        return s

    task_files = sorted(tasks_dir.glob("TASK-*.md"))
    if not task_files:
        s.flag_redline("tasks_empty", "tasks/ 目录为空")
        s.score = 0
        return s

    spec_text = read(ROOT / "module" / module / "SPEC.md") or ""
    fr_in_spec = set(re.findall(r"\bFR-\d{3}\b", spec_text))
    fr_covered_by_tasks: set[str] = set()

    for tf in task_files:
        text = read(tf) or ""
        # 每个 task 必须含 Scope / Non-scope / Acceptance
        for sect in ["Scope", "Non-scope", "Acceptance"]:
            if not re.search(rf"^##\s+{sect}", text, re.MULTILINE | re.IGNORECASE):
                s.deduct(2, f"task_missing_{sect.lower()}", f"{tf.name} 缺 {sect}")
        # 关联 FR
        fr_covered_by_tasks.update(re.findall(r"\bFR-\d{3}\b", text))
        # 编号
        if not re.match(r"TASK-[A-Z0-9-]+-\d{3}\.md$", tf.name):
            s.deduct(3, "task_naming", f"{tf.name} 命名不符合 TASK-MODULE-NNN.md")

    # FR 覆盖率
    if fr_in_spec:
        missing = fr_in_spec - fr_covered_by_tasks
        cov = (len(fr_in_spec) - len(missing)) / len(fr_in_spec)
        if cov < 1.0:
            s.deduct(int((1 - cov) * 20), "tasks_fr_coverage", f"未覆盖: {sorted(missing)[:5]}")
        if cov < 0.7:
            s.flag_redline(
                "tasks_fr_coverage_critical", f"Task FR 覆盖率 {cov:.0%} < 70%"
            )

    # Task 粒度（10 分）
    if len(task_files) < 2:
        s.deduct(5, "tasks_too_few", f"只有 {len(task_files)} 个 task，可能过粗")
    if len(task_files) > 30:
        s.deduct(5, "tasks_too_many", f"{len(task_files)} 个 task，过细")

    return s


def score_plan(module: str) -> Score:
    s = Score()
    candidates = [
        ROOT / "module" / module / "IMPLEMENTATION-PLAN.md",
        ROOT / "module" / module / "PLAN.md",
    ]
    path = next((p for p in candidates if p.exists()), None)
    if path is None:
        s.flag_redline("plan_missing", "未找到 IMPLEMENTATION-PLAN.md / PLAN.md")
        s.score = 0
        s.confidence = "low"
        return s

    text = read(path) or ""

    required = ["Steps", "Dependencies", "Validation", "Risks", "Rollback"]
    for sect in required:
        if not re.search(rf"^#{{1,3}}\s+(?:\d+[. ]\s*)?{sect}\b", text, re.MULTILINE | re.IGNORECASE):
            s.deduct(8, f"plan_missing_{sect.lower()}", f"缺 {sect} 段")

    # 步骤可执行性（含 bash 块、文件路径）
    bash_blocks = len(re.findall(r"```(?:bash|sh|shell)\b", text))
    if bash_blocks < 1:
        s.deduct(10, "plan_no_commands", "无 bash 命令块，可执行性低")

    # Task 引用
    task_refs = re.findall(r"\bTASK-[A-Z0-9-]+-\d{3}\b", text)
    if not task_refs:
        s.deduct(10, "plan_no_task_ref", "未引用任何 TASK-NNN")

    # 验证命令
    if not re.search(r"go test|npm test|pytest|bash .*\.sh", text):
        s.deduct(8, "plan_no_validation_cmd", "无 test/validation 命令")

    return s


def score_prompt(module: str) -> Score:
    s = Score()
    candidates = sorted((ROOT / "module" / module).glob("TASK-*-PROMPT.md"))
    if not candidates:
        s.flag_redline("prompt_missing", "未找到 TASK-*-PROMPT.md")
        s.score = 0
        s.confidence = "low"
        return s

    for path in candidates:
        text = read(path) or ""
        required = ["Context", "Scope", "Non-scope", "Acceptance", "Validation"]
        missing = [
            sect
            for sect in required
            if not re.search(rf"^##?\s+{sect}", text, re.MULTILINE | re.IGNORECASE)
        ]
        if missing:
            s.deduct(
                min(15, len(missing) * 3),
                f"prompt_missing_sections",
                f"{path.name} 缺 {missing}",
            )

        # 引用文件路径
        path_refs = re.findall(r"[\w/.-]+\.(?:go|py|ts|md|toml|yml)", text)
        if len(path_refs) < 3:
            s.deduct(5, "prompt_thin_refs", f"{path.name} 文件引用过少 ({len(path_refs)})")

        # Task ID
        if not re.search(r"\bTASK-[A-Z0-9-]+-\d{3}\b", text):
            s.deduct(8, "prompt_no_task_id", f"{path.name} 未关联 TASK-NNN")

    return s


def score_code(module: str) -> Score:
    """Code 阶段：rule scorer 只能做表层检查（文件存在、test 比例、命名）"""
    s = Score()
    s.confidence = "medium"  # 代码质量难以纯规则评估

    # 寻找模块代码目录（约定 module/{module}/ 或外部仓库）
    module_dirs = [
        ROOT / "module" / module,
        ROOT / module,
    ]
    code_dir = next((p for p in module_dirs if p.exists() and p.is_dir()), None)

    if code_dir is None:
        # 代码可能在外部仓库；不算红线，但置信度为 low
        s.deduct(20, "code_dir_not_in_repo", "本仓库无对应代码目录（可能外部仓库）")
        s.confidence = "low"
        return s

    # Go 项目结构检查
    go_files = list(code_dir.rglob("*.go"))
    test_files = [f for f in go_files if f.name.endswith("_test.go")]
    if go_files:
        test_ratio = len(test_files) / len(go_files)
        if test_ratio < 0.3:
            s.deduct(
                15,
                "code_test_ratio_low",
                f"测试文件 {len(test_files)}/{len(go_files)} = {test_ratio:.0%} < 30%",
            )
        elif test_ratio < 0.5:
            s.deduct(8, "code_test_ratio_thin", f"测试比例 {test_ratio:.0%}")

    # go.mod
    if go_files and not (code_dir / "go.mod").exists():
        s.deduct(10, "code_no_gomod", "有 .go 文件但缺 go.mod")

    # README
    if not any((code_dir / n).exists() for n in ["README.md", "readme.md"]):
        s.deduct(5, "code_no_readme", "无 README.md")

    # log.Fatal / os.Exit 反需求
    for gf in go_files:
        gt = read(gf) or ""
        if re.search(r"\blog\.Fatal\b", gt):
            s.flag_redline("code_log_fatal", f"{gf.relative_to(ROOT)} 含 log.Fatal")
            break

    return s


# ---------- 入口 ----------


SCORERS = {
    "spec": score_spec,
    "matrix": score_matrix,
    "tasks": score_tasks,
    "plan": score_plan,
    "prompt": score_prompt,
    "code": score_code,
}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("stage", choices=list(SCORERS.keys()))
    ap.add_argument("module")
    ap.add_argument(
        "--runtime",
        choices=sorted(RUNTIME_STATE_ROOTS),
        default=default_runtime(),
        help="状态运行时：claude=.omc，codex=.omx，copilot=.copilot",
    )
    ap.add_argument("--out", type=Path, default=None, help="JSON 输出路径")
    args = ap.parse_args()

    score = SCORERS[args.stage](args.module)
    payload = score.to_json(args.stage, args.module, source="rules")

    out_path = (
        args.out
        if args.out is not None
        else state_root(args.runtime) / args.module / args.stage / "scores/rules.json"
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    print(json.dumps(payload, ensure_ascii=False, indent=2))
    print(f"\n✓ 写入 {display_path(out_path)}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
