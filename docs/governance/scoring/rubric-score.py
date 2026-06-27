#!/usr/bin/env python3
"""Rubric-based structural auto-scorer for Goal pipeline artifacts.

Evaluates a SPEC.md (or other artifact) against the dimensions and red lines
defined in docs/governance/scoring/RUBRIC-{type}.md.  Produces a per-dimension
score, red-line status, and composite total.

Only the Python standard library is required so the script can run in CI
before project dependencies are installed.

Usage:
    python3 rubric-score.py spec path/to/SPEC.md
    python3 rubric-score.py spec path/to/SPEC.md --json
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent.parent

SPEC_SECTIONS = [
    "Metadata", "Summary", "Problem", "Goals", "Non-goals", "Consumers",
    "Functional Requirements", "Business Rules", "Interface Contract",
    "Data Model", "Config Schema", "Error Handling", "Edge Cases",
    "Directory Structure", "Dependencies", "Testing", "Performance Budget",
    "Observability", "Security", "CI Gate", "Upgrade Compatibility",
    "Release DoD", "Open Questions",
]

METADATA_FIELDS = [
    "Status", "Spec-Version", "Last-Updated", "Owner", "Layer",
    "Version", "Repository",
]

VALID_STATUS = {"Draft", "Review", "Approved", "Implemented", "Changed", "Deprecated"}

PASS_THRESHOLD = 98


@dataclass
class DimensionScore:
    name: str
    max_score: int
    score: int
    deductions: list[str] = field(default_factory=list)


@dataclass
class RedLine:
    name: str
    triggered: bool
    detail: str = ""


@dataclass
class ScoreReport:
    artifact: str
    rubric_type: str
    dimensions: list[DimensionScore]
    red_lines: list[RedLine]
    total: int
    max_total: int
    composite_score: int
    pass_threshold: int
    verdict: str


def parse_sections(text: str) -> dict[str, str]:
    """Split markdown into a {section_title: body} dict."""
    sections: dict[str, str] = {}
    current_title = ""
    current_body: list[str] = []
    for line in text.splitlines():
        m = re.match(r"^#{1,3}\s+(.+?)\s*$", line)
        if m:
            if current_title:
                sections[current_title] = "\n".join(current_body).strip()
            current_title = m.group(1).strip()
            current_body = []
        else:
            current_body.append(line)
    if current_title:
        sections[current_title] = "\n".join(current_body).strip()
    return sections


def section_nonempty(body: str) -> bool:
    """A section is non-empty if it has content beyond placeholders/whitespace."""
    if not body:
        return False
    stripped = body.strip()
    if not stripped:
        return False
    placeholder_patterns = [
        r"\{.+\}",
        r"^```(markdown|text)?\s*$",
        r"^```$",
        r"^---$",
        r"^\|.*\|.*$",
    ]
    lines = [
        ln for ln in stripped.splitlines()
        if ln.strip()
        and not any(re.match(p, ln.strip()) for p in placeholder_patterns)
    ]
    return len(lines) > 0


def count_list_items(body: str) -> int:
    """Count markdown list items (lines starting with - or * or N.)."""
    if not body:
        return 0
    return len(re.findall(r"^\s*[-*]\s+\S", body, re.MULTILINE))


def find_section(sections: dict[str, str], *names: str) -> str | None:
    """Find a section by flexible name matching."""
    for name in names:
        for key, body in sections.items():
            if name.lower() in key.lower():
                return body
    return None


def score_spec(sections: dict[str, str]) -> tuple[list[DimensionScore], list[RedLine]]:
    dims: list[DimensionScore] = []
    reds: list[RedLine] = []

    # --- D1: 23 节结构与元数据 (15) ---
    missing = []
    empty = []
    for i, sec in enumerate(SPEC_SECTIONS, 1):
        body = find_section(sections, sec)
        if body is None:
            missing.append(f"{i}. {sec}")
        elif not section_nonempty(body):
            empty.append(f"{i}. {sec}")
    meta_body = find_section(sections, "Metadata") or ""
    missing_fields = [f for f in METADATA_FIELDS if f not in meta_body]
    status_match = re.search(r"Status:\s*(\w+)", meta_body)
    status_invalid = status_match and status_match.group(1) not in VALID_STATUS

    d1_score = 15
    d1_deductions = []
    if missing:
        d1_score -= min(len(missing) * 3, 10)
        d1_deductions.append(f"缺失章节: {', '.join(missing)}")
    if empty:
        d1_score -= min(len(empty) * 2, 5)
        d1_deductions.append(f"空壳章节: {', '.join(empty)}")
    if missing_fields:
        d1_score -= min(len(missing_fields), 3)
        d1_deductions.append(f"Metadata 缺失字段: {', '.join(missing_fields)}")
    if status_invalid:
        d1_score -= 2
        d1_deductions.append(f"Status 非法值: {status_match.group(1)}")
    d1_score = max(0, d1_score)
    dims.append(DimensionScore("23 节结构与元数据", 15, d1_score, d1_deductions))

    # --- D2: 清晰性与范围边界 (12) ---
    d2_score = 12
    d2_deductions = []
    summary = find_section(sections, "Summary") or ""
    if not section_nonempty(summary):
        d2_score -= 3
        d2_deductions.append("Summary 为空")
    problem = find_section(sections, "Problem") or ""
    if count_list_items(problem) < 3:
        d2_score -= 2
        d2_deductions.append("Problem 未列出至少 3 个问题")
    goals = find_section(sections, "Goals") or ""
    if not section_nonempty(goals):
        d2_score -= 3
        d2_deductions.append("Goals 为空")
    nongoals = find_section(sections, "Non-goals") or ""
    nongoals_count = count_list_items(nongoals)
    if nongoals_count < 3:
        d2_score -= 2
        d2_deductions.append(f"Non-goals 仅 {nongoals_count} 条 (需 ≥3)")
    consumers = find_section(sections, "Consumers") or ""
    if not section_nonempty(consumers):
        d2_score -= 2
        d2_deductions.append("Consumers 为空")
    d2_score = max(0, d2_score)
    dims.append(DimensionScore("清晰性与范围边界", 12, d2_score, d2_deductions))

    # --- D3: FR/BR 行为规格 (15) ---
    d3_score = 15
    d3_deductions = []
    fr_body = find_section(sections, "Functional Requirements") or ""
    fr_items = re.findall(r"FR[-\s]*\d+", fr_body)
    when_then = len(re.findall(r"WHEN.*?THEN", fr_body, re.IGNORECASE | re.DOTALL))
    if fr_items and when_then < len(fr_items):
        d3_score -= min((len(fr_items) - when_then) * 2, 8)
        d3_deductions.append(f"FR 缺 WHEN/THEN: {len(fr_items) - when_then}/{len(fr_items)}")
    if not fr_items:
        d3_score -= 8
        d3_deductions.append("无 FR 编号")
    br_body = find_section(sections, "Business Rules") or ""
    br_items = re.findall(r"BR[-\s]*\d+", br_body)
    if not br_items:
        d3_score -= 4
        d3_deductions.append("无 BR 编号")
    br_consequences = len(re.findall(r"(?:违反|否则|若不|violation|consequence)", br_body, re.IGNORECASE))
    if br_items and br_consequences < len(br_items):
        d3_score -= min((len(br_items) - br_consequences), 3)
        d3_deductions.append("BR 缺违反后果")
    d3_score = max(0, d3_score)
    dims.append(DimensionScore("FR/BR 行为规格", 15, d3_score, d3_deductions))

    # --- D4: 追溯链闭合 (15) ---
    d4_score = 15
    d4_deductions = []
    ac_count = len(re.findall(r"\bAC[-\s]*\d+", fr_body))
    tc_count = len(re.findall(r"\bTC[-\s]*\d+", fr_body))
    if fr_items and ac_count < len(fr_items):
        d4_score -= min((len(fr_items) - ac_count) * 2, 8)
        d4_deductions.append(f"FR 缺 AC 映射: {len(fr_items) - ac_count}/{len(fr_items)}")
    if fr_items and tc_count < len(fr_items):
        d4_score -= min((len(fr_items) - tc_count) * 2, 7)
        d4_deductions.append(f"FR 缺 TC 映射: {len(fr_items) - tc_count}/{len(fr_items)}")
    d4_score = max(0, d4_score)
    dims.append(DimensionScore("追溯链闭合", 15, d4_score, d4_deductions))

    # --- D5: 接口/数据/配置/错误契约 (13) ---
    d5_score = 13
    d5_deductions = []
    contract_sections = [
        ("Interface Contract", 3),
        ("Data Model", 3),
        ("Config Schema", 3),
        ("Error Handling", 2),
        ("Directory Structure", 2),
    ]
    for sec_name, penalty in contract_sections:
        body = find_section(sections, sec_name)
        if not body or not section_nonempty(body):
            d5_score -= penalty
            d5_deductions.append(f"{sec_name} 缺失或空壳")
    d5_score = max(0, d5_score)
    dims.append(DimensionScore("接口/数据/配置/错误契约", 13, d5_score, d5_deductions))

    # --- D6: 边界场景/安全/可观测/性能 (12) ---
    d6_score = 12
    d6_deductions = []
    edge_body = find_section(sections, "Edge Cases") or ""
    edge_count = count_list_items(edge_body)
    if edge_count < 5:
        d6_score -= 4
        d6_deductions.append(f"Edge Cases 仅 {edge_count} 条 (需 ≥5)")
    for sec_name, penalty in [("Security", 3), ("Observability", 3), ("Performance Budget", 2)]:
        body = find_section(sections, sec_name)
        if not body or not section_nonempty(body):
            d6_score -= penalty
            d6_deductions.append(f"{sec_name} 缺失或空壳")
    d6_score = max(0, d6_score)
    dims.append(DimensionScore("边界场景/安全/可观测/性能", 12, d6_score, d6_deductions))

    # --- D7: 测试/CI/Release DoD (10) ---
    d7_score = 10
    d7_deductions = []
    for sec_name, penalty in [("Testing", 4), ("CI Gate", 3), ("Release DoD", 3)]:
        body = find_section(sections, sec_name)
        if not body or not section_nonempty(body):
            d7_score -= penalty
            d7_deductions.append(f"{sec_name} 缺失或空壳")
    d7_score = max(0, d7_score)
    dims.append(DimensionScore("测试/CI/Release DoD", 10, d7_score, d7_deductions))

    # --- D8: 治理/生命周期/依赖/变更 (8) ---
    d8_score = 8
    d8_deductions = []
    deps_body = find_section(sections, "Dependencies") or ""
    if not section_nonempty(deps_body):
        d8_score -= 2
        d8_deductions.append("Dependencies 为空")
    upgrade_body = find_section(sections, "Upgrade Compatibility") or ""
    if not section_nonempty(upgrade_body):
        d8_score -= 3
        d8_deductions.append("Upgrade Compatibility 为空")
    if "CONSTITUTION" not in (find_section(sections, "Metadata") or ""):
        d8_score -= 1
        d8_deductions.append("Metadata 未引用 CONSTITUTION")
    breaking = re.search(r"[Bb]reaking", upgrade_body)
    if breaking:
        if not re.search(r"(?:迁移|migrat|回滚|rollback)", upgrade_body, re.IGNORECASE):
            d8_score -= 2
            d8_deductions.append("Breaking Change 缺迁移/回滚说明")
    d8_score = max(0, d8_score)
    dims.append(DimensionScore("治理/生命周期/依赖/变更", 8, d8_score, d8_deductions))

    # --- Red lines ---
    reds.append(RedLine(
        "23 节缺失或空壳",
        bool(missing or empty),
        f"缺失 {len(missing)}, 空壳 {len(empty)}" if (missing or empty) else "",
    ))
    reds.append(RedLine(
        "Metadata 关键字段缺失",
        bool(missing_fields),
        ", ".join(missing_fields) if missing_fields else "",
    ))
    reds.append(RedLine(
        "FR 缺 WHEN/THEN 或 AC/TC 映射",
        bool(fr_items and (when_then < len(fr_items) or ac_count < len(fr_items))),
        "" if not fr_items else f"WHEN/THEN {when_then}/{len(fr_items)}, AC {ac_count}/{len(fr_items)}",
    ))
    oq_body = find_section(sections, "Open Questions") or ""
    has_blocking_oq = bool(re.search(r"\[?Blocking\]?|阻塞", oq_body, re.IGNORECASE))
    reds.append(RedLine(
        "Blocking Open Questions 存在",
        has_blocking_oq,
        "" if not has_blocking_oq else "存在标记为 Blocking 的 Open Question",
    ))
    reds.append(RedLine(
        "Non-goals < 3 或 Edge Cases < 5",
        nongoals_count < 3 or edge_count < 5,
        f"Non-goals={nongoals_count}, Edge Cases={edge_count}" if (nongoals_count < 3 or edge_count < 5) else "",
    ))
    reds.append(RedLine(
        "Breaking Change 缺迁移/回滚说明",
        bool(breaking and not re.search(r"(?:迁移|migrat|回滚|rollback)", upgrade_body, re.IGNORECASE)),
        "" if not breaking else "检测到 Breaking Change 但无迁移/回滚说明",
    ))

    return dims, reds


def score_artifact(rubric_type: str, text: str) -> ScoreReport:
    sections = parse_sections(text)

    if rubric_type == "spec":
        dims, reds = score_spec(sections)
    else:
        raise ValueError(f"不支持的 rubric 类型: {rubric_type} (当前仅支持 'spec')")

    total = sum(d.score for d in dims)
    max_total = sum(d.max_score for d in dims)
    any_red = any(r.triggered for r in reds)
    composite = 0 if any_red else total

    verdict = "PASS" if composite >= PASS_THRESHOLD and not any_red else "FAIL"

    return ScoreReport(
        artifact="",
        rubric_type=rubric_type,
        dimensions=dims,
        red_lines=reds,
        total=total,
        max_total=max_total,
        composite_score=composite,
        pass_threshold=PASS_THRESHOLD,
        verdict=verdict,
    )


def main():
    parser = argparse.ArgumentParser(
        description="Rubric-based structural auto-scorer for Goal pipeline artifacts."
    )
    parser.add_argument(
        "rubric_type",
        choices=["spec"],
        help="Rubric type (currently only 'spec' is supported).",
    )
    parser.add_argument(
        "artifact",
        help="Path to the artifact file to score (e.g., module/{m}/SPEC.md).",
    )
    parser.add_argument(
        "--json",
        dest="as_json",
        action="store_true",
        help="Emit a JSON report instead of human-readable text.",
    )
    args = parser.parse_args()

    artifact_path = Path(args.artifact)
    if not artifact_path.is_file():
        print(f"rubric-score: 文件不存在: {artifact_path}", file=sys.stderr)
        sys.exit(2)

    text = artifact_path.read_text(encoding="utf-8")
    report = score_artifact(args.rubric_type, text)
    report.artifact = str(artifact_path)

    if args.as_json:
        print(json.dumps(asdict(report), indent=2, ensure_ascii=False))
    else:
        print(f"Rubric auto-score: {report.rubric_type}")
        print(f"Artifact: {report.artifact}")
        print(f"\n维度评分 ({report.total}/{report.max_total}):")
        for d in report.dimensions:
            status = "OK" if d.score == d.max_score else "DEDUCT"
            print(f"  [{status}] {d.name}: {d.score}/{d.max_score}")
            for ded in d.deductions:
                print(f"         - {ded}")
        print(f"\n红线检查:")
        for r in report.red_lines:
            tag = "TRIGGERED" if r.triggered else "clear"
            print(f"  [{tag}] {r.name}" + (f" — {r.detail}" if r.detail else ""))
        print(f"\ncomposite_score: {report.composite_score}/{report.max_total}")
        print(f"verdict: {report.verdict} (threshold: {report.pass_threshold})")

    sys.exit(0 if report.verdict == "PASS" else 1)


if __name__ == "__main__":
    main()
