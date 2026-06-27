#!/usr/bin/env python3
"""Rubric-based structural auto-scorer for Goal pipeline artifacts.

Evaluates artifacts against the dimensions and red lines defined in
`docs/governance/scoring/RUBRIC-{type}.md`.  Produces a per-dimension score,
red-line status, and composite total.

Supported rubric types:
    spec    -> module/{m}/SPEC.md
    matrix  -> module/{m}/TRACEABILITY.md
    tasks   -> module/{m}/tasks/ (directory of TASK-*.md)
    plan    -> module/{m}/IMPLEMENTATION-PLAN.md or module/{m}/plan/PLAN.md
    prompt  -> module/{m}/TASK-{M}-{NNN}-PROMPT.md
    code    -> module/{m}/evidence/EVID-*.md (evidence bundle)

Only the Python standard library is required so the script can run in CI
before project dependencies are installed.

Usage:
    python3 rubric-score.py spec path/to/SPEC.md
    python3 rubric-score.py matrix path/to/TRACEABILITY.md
    python3 rubric-score.py tasks path/to/tasks/
    python3 rubric-score.py plan path/to/PLAN.md
    python3 rubric-score.py prompt path/to/TASK-NNN-PROMPT.md
    python3 rubric-score.py code path/to/EVID-*.md --task TASK-NNN
    python3 rubric-score.py <type> <path> --json
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

# Bilingual section name aliases.  Modules in this repo may use either the
# English names from SPEC-TEMPLATE.md or their Chinese equivalents (per
# AGENTS.md "文档默认中文").  ``find_section`` consults this map so both naming
# conventions are recognised.
SECTION_ALIASES: dict[str, list[str]] = {
    "Metadata": ["元数据", "Metadata"],
    "Summary": ["摘要", "Summary", "概述", "Overview"],
    "Problem": ["问题与背景", "问题", "Problem", "背景"],
    "Goals": ["目标", "Goals"],
    "Non-goals": ["非目标", "Non-goals", "不做"],
    "Consumers": ["消费者", "Consumers", "使用方"],
    "Functional Requirements": ["功能需求", "Functional Requirements", "FR"],
    "Business Rules": ["行为约束", "业务规则", "Business Rules", "BR"],
    "Interface Contract": ["接口契约", "接口定义", "Interface Contract", "Interface"],
    "Data Model": ["数据模型", "Data Model"],
    "Config Schema": ["配置模式", "配置", "Config Schema", "Config"],
    "Error Handling": ["错误处理", "Error Handling"],
    "Edge Cases": ["边界情况", "边界场景", "Edge Cases"],
    "Directory Structure": ["目录结构", "Directory Structure"],
    "Dependencies": ["依赖", "Dependencies", "依赖关系"],
    "Testing": ["测试", "Testing", "测试策略"],
    "Performance Budget": ["性能预算", "性能", "Performance Budget", "Performance"],
    "Observability": ["可观测性", "可观测", "Observability"],
    "Security": ["安全", "Security", "安全要求"],
    "CI Gate": ["CI 门禁", "CI Gate", "CI"],
    "Upgrade Compatibility": ["升级兼容性", "升级", "Upgrade Compatibility"],
    "Release DoD": ["发布 DoD", "Release DoD", "发布标准"],
    "Open Questions": ["开放问题", "待定问题", "Open Questions", "待决问题"],
}

# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------


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


# ---------------------------------------------------------------------------
# Markdown / table helpers
# ---------------------------------------------------------------------------


def parse_sections(text: str) -> dict[str, str]:
    """Split markdown into a {section_title: body} dict.

    Adaptive to heading level: the minimum heading level present in the
    document is treated as the top section level.  A heading at that level
    starts a new section; deeper headings (e.g. ``###`` when top is ``##``)
    are kept inside the current section's body so a parent section is not
    flagged empty when its content lives under sub-headings.
    """
    # First pass: pick the top section level.  ``#`` is usually a document
    # title (single occurrence); the real section level in SPEC-style docs is
    # ``##``.  Prefer the shallowest level that has more than one heading, or
    # the shallowest level present if all are singular.
    heading_re = re.compile(r"^(#{1,3})\s+(.+?)\s*$")
    level_counts: dict[int, int] = {}
    for ln in text.splitlines():
        m = heading_re.match(ln)
        if m:
            level_counts[len(m.group(1))] = level_counts.get(len(m.group(1)), 0) + 1
    if not level_counts:
        top_level = 2
    else:
        # Prefer the shallowest level with >1 heading (real sections); fall
        # back to the shallowest level present.
        multi = [lv for lv in sorted(level_counts) if level_counts[lv] > 1]
        top_level = multi[0] if multi else min(level_counts)

    sections: dict[str, str] = {}
    current_title = ""
    current_body: list[str] = []
    for line in text.splitlines():
        m = heading_re.match(line)
        if m:
            level = len(m.group(1))
            # A heading at or above the top section level starts a new section.
            # Deeper headings are part of the current section's body.
            if level <= top_level:
                if current_title:
                    sections[current_title] = "\n".join(current_body).strip()
                current_title = m.group(2).strip()
                current_body = []
            else:
                # Deeper heading: keep the line as part of the current body.
                current_body.append(line)
        else:
            current_body.append(line)
    if current_title:
        sections[current_title] = "\n".join(current_body).strip()
    return sections


def section_nonempty(body: str) -> bool:
    """A section is non-empty if it has content beyond placeholders/whitespace.

    Tables are real content — a section whose body is a markdown table is NOT
    empty.  Only pure scaffolding (fenced code fences, horizontal rules, bare
    placeholder braces) is ignored.
    """
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
    ]
    lines = [
        ln for ln in stripped.splitlines()
        if ln.strip()
        and not any(re.match(p, ln.strip()) for p in placeholder_patterns)
    ]
    return len(lines) > 0


def count_list_items(body: str) -> int:
    """Count markdown list items: bullet (``-`` / ``*``), numbered (``1.``) and
    table data rows (``| ... |``).  Table header and separator rows are excluded.
    """
    if not body:
        return 0
    bullets = len(re.findall(r"^\s*[-*]\s+\S", body, re.MULTILINE))
    numbered = len(re.findall(r"^\s*\d+\.\s+\S", body, re.MULTILINE))
    table_rows = 0
    for ln in body.splitlines():
        s = ln.strip()
        if not s.startswith("|") or "|" not in s[1:]:
            continue
        inner = s.strip("|").strip()
        if not inner:
            continue
        # Skip separator rows like | --- | --- |
        if all(re.match(r"^[-:]+$", c.strip()) for c in inner.split("|") if c.strip()):
            continue
        table_rows += 1
    return bullets + numbered + table_rows


def find_section(sections: dict[str, str], *names: str) -> str | None:
    """Find a section by flexible name matching.

    Each requested name is also matched against its bilingual aliases in
    ``SECTION_ALIASES``, so both English and Chinese section titles work.
    """
    for name in names:
        # Build the list of variants for this name (English + Chinese aliases).
        variants = [name]
        if name in SECTION_ALIASES:
            variants.extend(SECTION_ALIASES[name])
        for variant in variants:
            for key, body in sections.items():
                if variant.lower() in key.lower():
                    return body
    return None


def parse_markdown_tables(text: str) -> list[list[list[str]]]:
    """Extract all markdown tables from text as list of tables (list of rows)."""
    tables: list[list[list[str]]] = []
    current: list[list[str]] = []
    in_table = False
    for line in text.splitlines():
        stripped = line.strip()
        if "|" in stripped:
            cells = [c.strip() for c in stripped.split("|")]
            # Drop empty leading/trailing cells from outer pipes
            if cells and cells[0] == "":
                cells = cells[1:]
            if cells and cells[-1] == "":
                cells = cells[:-1]
            if cells and all(re.match(r"^[-:]+$", c.strip()) for c in cells if c.strip()):
                # separator row
                continue
            if cells:
                current.append(cells)
                in_table = True
        else:
            if in_table and current:
                tables.append(current)
                current = []
            in_table = False
    if in_table and current:
        tables.append(current)
    return tables


def extract_ids_from_text(text: str, prefix: str) -> set[str]:
    """Extract identifiers like FR-001, BR-002, TC-003, AC-004."""
    if not text:
        return set()
    escaped = re.escape(prefix)
    ids = set(re.findall(rf"\b{escaped}-\d+[A-Za-z]?\b", text))
    range_pattern = re.compile(
        rf"\b{escaped}-(\d+)\s*(?:~|–|—|to|至)\s*(?:{escaped}-)?(\d+)\b",
        re.IGNORECASE,
    )
    for match in range_pattern.finditer(text):
        start_text, end_text = match.groups()
        start, end = int(start_text), int(end_text)
        if start <= end and end - start <= 500:
            width = max(len(start_text), len(end_text))
            ids.update(f"{prefix}-{i:0{width}d}" for i in range(start, end + 1))
    return ids


def extract_task_ids(text: str) -> set[str]:
    """Extract governance/runtime task identifiers."""
    if not text:
        return set()
    return set(re.findall(
        r"\b(?:TASK-[A-Z0-9_]+-\d+[A-Za-z]?|(?:SERVER|CLIENT|ROOT)-\d+[A-Za-z]?)\b",
        text,
    ))


# ---------------------------------------------------------------------------
# Spec scoring
# ---------------------------------------------------------------------------


def score_spec(sections: dict[str, str], full_text: str = "") -> tuple[list[DimensionScore], list[RedLine]]:
    dims: list[DimensionScore] = []
    reds: list[RedLine] = []
    # Full document text is used for FR/BR/AC/TC detection so that ``### FR-XXX``
    # sub-headings (which sit inside the Functional Requirements section) are
    # counted even when the section body itself only holds the intro.
    doc_text = full_text or "\n".join(sections.values())

    # --- D1: 23 节结构与元数据 (15) ---
    missing = []
    empty = []
    for i, sec in enumerate(SPEC_SECTIONS, 1):
        body = find_section(sections, sec)
        if body is None:
            missing.append(f"{i}. {sec}")
        elif not section_nonempty(body):
            empty.append(f"{i}. {sec}")
    # Metadata may live in the document preamble (no ``## Metadata`` heading).
    # Fall back to the full document text for field presence checks, and do not
    # count Metadata as a missing section if its fields are present anywhere.
    meta_body = find_section(sections, "Metadata") or ""
    meta_search_body = meta_body or doc_text[:3000]
    missing_fields = [f for f in METADATA_FIELDS if f not in meta_search_body]
    if "Metadata" in (m.split(". ", 1)[-1] for m in missing) and not missing_fields:
        # Metadata fields exist in the preamble — don't count the section as
        # missing, just note the unconventional placement.
        missing = [m for m in missing if not m.endswith("Metadata")]
    status_match = re.search(r"Status:\s*(\w+)", meta_search_body)
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
    # Distinct FR/BR IDs across the whole document (a FR may be referenced many
    # times; we want the count of unique requirements, not citation frequency).
    fr_items = sorted(set(re.findall(r"FR[-\s]*\d+", doc_text)))
    when_then = len(re.findall(r"WHEN.*?THEN", doc_text, re.IGNORECASE | re.DOTALL))
    # Each FR should have >=1 WHEN/THEN block; compare against distinct FR count.
    if fr_items and when_then < len(fr_items):
        d3_score -= min((len(fr_items) - when_then) * 2, 8)
        d3_deductions.append(f"FR 缺 WHEN/THEN: {len(fr_items) - when_then}/{len(fr_items)}")
    if not fr_items:
        d3_score -= 8
        d3_deductions.append("无 FR 编号")
    br_body = find_section(sections, "Business Rules") or ""
    br_items = sorted(set(re.findall(r"BR[-\s]*\d+", doc_text)))
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
    ac_count = len(set(re.findall(r"\bAC[-\s]*\d+", doc_text)))
    tc_count = len(set(re.findall(r"\bTC[-\s]*\d+", doc_text)))
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
    if "CONSTITUTION" not in meta_search_body and "CONSTITUTION" not in doc_text[:3000]:
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
    # Only flag ACTIVE blocking questions — exclude lines that mark them as
    # resolved ("Resolved (was Blocking)", "已解决", "已确认").
    blocking_lines = [
        ln for ln in oq_body.splitlines()
        if re.search(r"Blocking|阻塞", ln, re.IGNORECASE)
        and not re.search(r"resolved|was|已解决|已确认|closed|non-blocking", ln, re.IGNORECASE)
    ]
    has_blocking_oq = len(blocking_lines) > 0
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


# ---------------------------------------------------------------------------
# Matrix scoring
# ---------------------------------------------------------------------------


def score_matrix(text: str) -> tuple[list[DimensionScore], list[RedLine]]:
    dims: list[DimensionScore] = []
    reds: list[RedLine] = []

    nonempty = bool(text and text.strip())
    tables = parse_markdown_tables(text) if nonempty else []

    # Collect all IDs from table cells (row is a list of cell strings)
    all_text = "\n".join(" ".join(row) for table in tables for row in table)

    raw_fr_ids = extract_ids_from_text(all_text, "FR")
    raw_br_ids = extract_ids_from_text(all_text, "BR")
    raw_ac_ids = extract_ids_from_text(all_text, "AC")
    raw_tc_ids = extract_ids_from_text(all_text, "TC")
    raw_task_ids = extract_task_ids(all_text)

    def header_text(table: list[list[str]]) -> str:
        return "|".join(table[0]).lower() if table else ""

    def table_has_header(table: list[list[str]], *needles: str) -> bool:
        joined = header_text(table)
        return any(needle in joined for needle in needles)

    def find_col(header: list[str], *terms: str) -> int:
        for i, name in enumerate(header):
            if any(term in name for term in terms):
                return i
        return -1

    def cell(row: list[str], idx: int) -> str:
        return row[idx] if 0 <= idx < len(row) else ""

    # Map FR -> AC, AC -> TC, and TC -> FR/BR from active traceability tables.
    # Historical changelog rows may contain superseded ID ranges; they must not
    # become current gate inputs.
    declared_fr_ids: set[str] = set()
    declared_br_ids: set[str] = set()
    declared_ac_ids: set[str] = set()
    declared_tc_ids: set[str] = set()
    declared_nfr_ids: set[str] = set()
    declared_task_ids: set[str] = set()

    fr_to_ac: dict[str, set[str]] = {}
    ac_to_tc: dict[str, set[str]] = {}
    tc_to_fr: dict[str, set[str]] = {}

    for table in tables:
        header = [c.strip().lower() for c in table[0]] if table else []
        first_header = header[0] if header else ""
        table_kind = ""
        if first_header == "fr id":
            table_kind = "fr"
        elif first_header == "br id":
            table_kind = "br"
        elif first_header == "nfr id":
            table_kind = "nfr"
        elif first_header == "tc id":
            table_kind = "tc"
        elif first_header == "ac id":
            table_kind = "ac"

        fr_idx = find_col(header, "fr id", "覆盖 fr", "所属 fr", "requirement", "req", "功能需求")
        br_idx = find_col(header, "br id", "覆盖 br", "business", "业务规则")
        ac_idx = find_col(header, "ac id", "acceptance", "验收", "ac")
        tc_idx = find_col(header, "tc id", "test case", "test", "测试", "验证方式", "tc")

        for row in table[1:]:
            if len(row) < 2:
                continue
            row_fr = extract_ids_from_text(cell(row, fr_idx), "FR")
            row_br = extract_ids_from_text(cell(row, br_idx), "BR")
            row_ac = extract_ids_from_text(cell(row, ac_idx), "AC")
            row_tc = extract_ids_from_text(cell(row, tc_idx), "TC")
            row_task = extract_task_ids(" ".join(row))

            if table_kind == "fr":
                declared_fr_ids.update(row_fr)
                declared_ac_ids.update(row_ac)
                declared_tc_ids.update(row_tc)
                declared_task_ids.update(row_task)
            elif table_kind == "br":
                declared_br_ids.update(row_br)
                declared_tc_ids.update(row_tc)
                declared_task_ids.update(row_task)
            elif table_kind == "nfr":
                declared_nfr_ids.update(extract_ids_from_text(cell(row, 0), "NFR"))
            elif table_kind == "tc":
                declared_tc_ids.update(row_tc)
                declared_fr_ids.update(row_fr)
                declared_br_ids.update(row_br)
            elif table_kind == "ac":
                declared_ac_ids.update(row_ac)
                declared_fr_ids.update(row_fr)
                declared_tc_ids.update(row_tc)

            for fid in row_fr:
                fr_to_ac.setdefault(fid, set()).update(row_ac)
            for aid in row_ac:
                ac_to_tc.setdefault(aid, set()).update(row_tc)
            for tid in row_tc:
                # TC maps back to FR/BR in same row
                tc_to_fr.setdefault(tid, set()).update(row_fr | row_br)

    fr_ids = declared_fr_ids or raw_fr_ids
    br_ids = declared_br_ids or raw_br_ids
    ac_ids = declared_ac_ids or raw_ac_ids
    tc_ids = declared_tc_ids or raw_tc_ids
    nfr_ids = declared_nfr_ids or extract_ids_from_text(all_text, "NFR")
    task_ids = declared_task_ids or raw_task_ids

    for fid in fr_ids:
        fr_to_ac.setdefault(fid, set())
    for aid in ac_ids:
        ac_to_tc.setdefault(aid, set())
    for tid in tc_ids:
        tc_to_fr.setdefault(tid, set())

    fr_without_ac = [fid for fid in fr_ids if not fr_to_ac.get(fid)]
    ac_without_tc = [aid for aid in ac_ids if not ac_to_tc.get(aid)]
    tc_without_fr = [tid for tid in tc_ids if not tc_to_fr.get(tid)]

    # --- D1: 表结构完整性 (15) ---
    d1_score = 15
    d1_deductions = []
    if not tables:
        d1_score -= 10
        d1_deductions.append("未找到表格")
    else:
        if not any(table_has_header(t, "requirement", "req", "fr id", "功能需求", "覆盖 fr", "所属 fr") for t in tables if t):
            d1_score -= 5
            d1_deductions.append("表头缺少 Requirement 列")
        if not any(table_has_header(t, "acceptance", "ac", "验收") for t in tables if t):
            d1_score -= 3
            d1_deductions.append("表头缺少 Acceptance Criteria 列")
        if not any(table_has_header(t, "test", "tc", "测试", "验证方式") for t in tables if t):
            d1_score -= 3
            d1_deductions.append("表头缺少 Test Case 列")
        if not any(table_has_header(t, "task", "任务") for t in tables if t):
            d1_score -= 2
            d1_deductions.append("表头缺少 Task 列")
    d1_score = max(0, d1_score)
    dims.append(DimensionScore("表结构完整性", 15, d1_score, d1_deductions))

    # --- D2: FR 覆盖闭合 (20) ---
    d2_score = 20
    d2_deductions = []
    if not fr_ids:
        d2_score -= 15
        d2_deductions.append("矩阵中未找到 FR")
    if fr_without_ac:
        d2_score -= min(len(fr_without_ac) * 3, 12)
        d2_deductions.append(f"{len(fr_without_ac)} 个 FR 无 AC")
    d2_score = max(0, d2_score)
    dims.append(DimensionScore("FR 覆盖闭合", 20, d2_score, d2_deductions))

    # --- D3: AC 闭合 (15) ---
    d3_score = 15
    d3_deductions = []
    if not ac_ids:
        d3_score -= 10
        d3_deductions.append("矩阵中未找到 AC")
    d3_score = max(0, d3_score)
    dims.append(DimensionScore("AC 闭合", 15, d3_score, d3_deductions))

    # --- D4: TC 闭合 (15) ---
    d4_score = 15
    d4_deductions = []
    if not tc_ids:
        d4_score -= 10
        d4_deductions.append("矩阵中未找到 TC")
    if ac_without_tc:
        d4_score -= min(len(ac_without_tc) * 3, 10)
        d4_deductions.append(f"{len(ac_without_tc)} 个 AC 无 TC")
    d4_score = max(0, d4_score)
    dims.append(DimensionScore("TC 闭合", 15, d4_score, d4_deductions))

    # --- D5: 反向追溯 (10) ---
    d5_score = 10
    d5_deductions = []
    if tc_without_fr:
        d5_score -= min(len(tc_without_fr) * 3, 10)
        d5_deductions.append(f"{len(tc_without_fr)} 个 TC 无 FR/BR 支撑")
    d5_score = max(0, d5_score)
    dims.append(DimensionScore("反向追溯", 10, d5_score, d5_deductions))

    # --- D6: Task 映射 (10) ---
    d6_score = 10
    d6_deductions = []
    if not task_ids:
        d6_score -= 6
        d6_deductions.append("矩阵中未找到 Task ID")
    if fr_ids and len([fid for fid in fr_ids if not task_ids]) > 0:
        # Simplified: just check there are tasks if there are FRs
        pass
    d6_score = max(0, d6_score)
    dims.append(DimensionScore("Task 映射", 10, d6_score, d6_deductions))

    # --- D7: BR/NFR 覆盖 (8) ---
    d7_score = 8
    d7_deductions = []
    if not br_ids:
        d7_score -= 4
        d7_deductions.append("矩阵中未找到 BR")
    if not nfr_ids:
        d7_score -= 2
        d7_deductions.append("矩阵中未找到 NFR")
    d7_score = max(0, d7_score)
    dims.append(DimensionScore("BR/NFR 覆盖", 8, d7_score, d7_deductions))

    # --- D8: 编号一致性 (7) ---
    d8_score = 7
    d8_deductions = []
    duplicates = []
    for id_set, prefix in [(fr_ids, "FR"), (ac_ids, "AC"), (tc_ids, "TC")]:
        # Since sets already dedupe, check within table rows
        pass
    if not nonempty:
        d8_score = 0
        d8_deductions.append("文件为空")
    d8_score = max(0, d8_score)
    dims.append(DimensionScore("编号一致性", 7, d8_score, d8_deductions))

    # --- Red lines ---
    reds.append(RedLine("TRACEABILITY.md 缺失或为空", not nonempty))
    reds.append(RedLine("存在无 AC 的 FR", bool(fr_without_ac), f"{len(fr_without_ac)} 个"))
    reds.append(RedLine("存在无 TC 的 AC", bool(ac_without_tc), f"{len(ac_without_tc)} 个"))
    reds.append(RedLine("存在无 FR 支撑的 TC", bool(tc_without_fr), f"{len(tc_without_fr)} 个"))
    reds.append(RedLine("引用了不存在的 Task ID", False))  # Cannot easily verify without spec

    return dims, reds


# ---------------------------------------------------------------------------
# Tasks scoring
# ---------------------------------------------------------------------------


def score_tasks(task_files: list[Path]) -> tuple[list[DimensionScore], list[RedLine]]:
    dims: list[DimensionScore] = []
    reds: list[RedLine] = []

    if not task_files:
        # All zeros + redline
        dims = [DimensionScore(name, max_score, 0, ["无 Task 文件"]) for name, max_score in [
            ("Task 模板符合度", 12), ("粒度合规", 15), ("spec_ref 闭合", 15),
            ("Scope/Non-scope", 12), ("覆盖完整性", 15), ("依赖声明", 10),
            ("测试计划", 10), ("优先级与文件清单", 11),
        ]]
        reds = [RedLine("任一 Task 无法追溯到 Spec", True, "无 Task 文件")]
        return dims, reds

    all_text = "\n".join(f.read_text(encoding="utf-8") for f in task_files)
    sections_per_file = [parse_sections(t) for t in all_text.split("\n---\n") if t.strip()]
    # If files don't use --- separator, treat each file as one doc
    if len(sections_per_file) != len(task_files):
        sections_per_file = [parse_sections(f.read_text(encoding="utf-8")) for f in task_files]

    task_count = len(task_files)
    spec_ref_count = 0
    acceptance_count = 0
    files_list_count = 0
    dependency_count = 0
    priority_count = 0
    scope_count = 0
    test_plan_count = 0

    over_5_files = 0
    over_3_fr = 0
    no_test_file = 0
    cross_module_hints = 0
    spec_refs: set[str] = set()
    all_fr_refs: set[str] = set()

    for sections in sections_per_file:
        text = "\n".join(sections.values())
        # spec_ref
        refs = re.findall(r"(?:spec_ref|spec_ref:|规格引用|来源|Source).*?\n(.*?)(?:\n##|\n# |\Z)", text, re.DOTALL | re.IGNORECASE)
        if not refs:
            # Try inline references like module/xxx/SPEC.md#FR-001
            refs = [text]
        ref_text = "\n".join(refs) if refs else text
        fr_refs = set(re.findall(r"FR[-\s]*\d+", ref_text))
        all_fr_refs.update(fr_refs)
        if fr_refs or re.search(r"SPEC\.md#", ref_text):
            spec_ref_count += 1
            spec_refs.update(fr_refs)

        # acceptance criteria
        ac_section = find_section(sections, "Acceptance Criteria", "验收标准", "Acceptance")
        if ac_section and section_nonempty(ac_section):
            acceptance_count += 1

        # files list
        files_section = find_section(sections, "Files", "文件", "Files likely to change")
        if files_section:
            files_list_count += 1
            file_lines = [ln.strip() for ln in files_section.splitlines() if ln.strip() and not ln.strip().startswith("-")]
            # Count items
            items = count_list_items(files_section)
            if items > 5:
                over_5_files += 1

        # FR count in task
        if len(fr_refs) > 3:
            over_3_fr += 1

        # dependencies
        dep_section = find_section(sections, "Dependencies", "depends_on", "依赖", "前置依赖")
        if dep_section and section_nonempty(dep_section):
            dependency_count += 1

        # priority
        if re.search(r"\bP[0-2]\b", text):
            priority_count += 1

        # scope / objective
        if find_section(sections, "Scope", "Objective", "scope", "目标", "任务"):
            scope_count += 1

        # test plan / test file
        if find_section(sections, "Test", "测试", "Test plan", "验证"):
            test_plan_count += 1
        if files_section and not re.search(r"_test\.|test_", files_section, re.IGNORECASE):
            no_test_file += 1

        # cross-module heuristic
        module_match = re.search(r"module:\s*(\w+)", text)
        if module_match:
            task_module = module_match.group(1)
            if task_module and re.search(rf"module/{task_module}/", text):
                pass
            else:
                # Look for references to other module paths
                other_modules = re.findall(r"module/(\w+)/", text)
                if other_modules and any(m != task_module for m in other_modules):
                    cross_module_hints += 1

    # --- D1: Task 模板符合度 (12) ---
    d1_score = 12
    d1_deductions = []
    missing_fields = task_count - spec_ref_count
    if missing_fields > 0:
        d1_score -= min(missing_fields * 2, 8)
        d1_deductions.append(f"{missing_fields} 个 Task 缺少 spec_ref")
    missing_ac = task_count - acceptance_count
    if missing_ac > 0:
        d1_score -= min(missing_ac * 2, 8)
        d1_deductions.append(f"{missing_ac} 个 Task 缺少验收标准")
    d1_score = max(0, d1_score)
    dims.append(DimensionScore("Task 模板符合度", 12, d1_score, d1_deductions))

    # --- D2: 粒度合规 (15) ---
    d2_score = 15
    d2_deductions = []
    if over_5_files:
        d2_score -= min(over_5_files * 3, 9)
        d2_deductions.append(f"{over_5_files} 个 Task 超过 5 个文件")
    if over_3_fr:
        d2_score -= min(over_3_fr * 3, 9)
        d2_deductions.append(f"{over_3_fr} 个 Task 超过 3 个 FR")
    if no_test_file:
        d2_score -= min(no_test_file * 2, 9)
        d2_deductions.append(f"{no_test_file} 个 Task 未包含测试文件")
    if cross_module_hints:
        d2_score -= min(cross_module_hints * 3, 9)
        d2_deductions.append(f"{cross_module_hints} 个 Task 疑似跨模块")
    d2_score = max(0, d2_score)
    dims.append(DimensionScore("粒度合规", 15, d2_score, d2_deductions))

    # --- D3: spec_ref 闭合 (15) ---
    d3_score = 15
    d3_deductions = []
    if spec_ref_count < task_count:
        d3_score -= min((task_count - spec_ref_count) * 3, 12)
        d3_deductions.append(f"{task_count - spec_ref_count} 个 Task 无法定位 spec_ref")
    d3_score = max(0, d3_score)
    dims.append(DimensionScore("spec_ref 闭合", 15, d3_score, d3_deductions))

    # --- D4: Scope/Non-scope (12) ---
    d4_score = 12
    d4_deductions = []
    if scope_count < task_count:
        d4_score -= min((task_count - scope_count) * 2, 8)
        d4_deductions.append(f"{task_count - scope_count} 个 Task 缺少 Scope/Objective")
    d4_score = max(0, d4_score)
    dims.append(DimensionScore("Scope/Non-scope", 12, d4_score, d4_deductions))

    # --- D5: 覆盖完整性 (15) ---
    d5_score = 15
    d5_deductions = []
    if not all_fr_refs:
        d5_score -= 10
        d5_deductions.append("Task 集合未引用任何 FR")
    d5_score = max(0, d5_score)
    dims.append(DimensionScore("覆盖完整性", 15, d5_score, d5_deductions))

    # --- D6: 依赖声明 (10) ---
    d6_score = 10
    d6_deductions = []
    if dependency_count < task_count:
        d6_score -= min((task_count - dependency_count) * 1, 5)
        d6_deductions.append(f"{task_count - dependency_count} 个 Task 未声明依赖")
    d6_score = max(0, d6_score)
    dims.append(DimensionScore("依赖声明", 10, d6_score, d6_deductions))

    # --- D7: 测试计划 (10) ---
    d7_score = 10
    d7_deductions = []
    if test_plan_count < task_count:
        d7_score -= min((task_count - test_plan_count) * 2, 8)
        d7_deductions.append(f"{task_count - test_plan_count} 个 Task 缺少测试计划")
    d7_score = max(0, d7_score)
    dims.append(DimensionScore("测试计划", 10, d7_score, d7_deductions))

    # --- D8: 优先级与文件清单 (11) ---
    d8_score = 11
    d8_deductions = []
    if priority_count < task_count:
        d8_score -= min((task_count - priority_count) * 2, 6)
        d8_deductions.append(f"{task_count - priority_count} 个 Task 未标注优先级")
    if files_list_count < task_count:
        d8_score -= min((task_count - files_list_count) * 2, 6)
        d8_deductions.append(f"{task_count - files_list_count} 个 Task 未列出文件")
    d8_score = max(0, d8_score)
    dims.append(DimensionScore("优先级与文件清单", 11, d8_score, d8_deductions))

    # --- Red lines ---
    reds.append(RedLine(
        "任一 Task 无法追溯到 Spec",
        spec_ref_count < task_count,
        f"{task_count - spec_ref_count}/{task_count} 个 Task 无 spec_ref",
    ))
    reds.append(RedLine("任一 Task 跨模块", cross_module_hints > 0, f"{cross_module_hints} 个"))
    reds.append(RedLine("任一 Task 超 5 文件或 3 FR", over_5_files > 0 or over_3_fr > 0, f"超文件 {over_5_files}, 超 FR {over_3_fr}"))
    reds.append(RedLine("实现与测试拆分到不同 Task", no_test_file > 0, f"{no_test_file} 个 Task 未列测试文件"))
    reds.append(RedLine("存在循环依赖", False))  # Requires graph analysis; not implemented
    reds.append(RedLine("Task 引入 Spec 外功能", False))  # Requires spec comparison; not implemented

    return dims, reds


# ---------------------------------------------------------------------------
# Plan scoring
# ---------------------------------------------------------------------------


def score_plan(text: str) -> tuple[list[DimensionScore], list[RedLine]]:
    dims: list[DimensionScore] = []
    reds: list[RedLine] = []
    sections = parse_sections(text)

    nonempty = bool(text and text.strip())

    # Heuristic checks
    has_order = bool(re.search(r"顺序|order|phase|stage|step", text, re.IGNORECASE))
    has_deps = bool(find_section(sections, "Dependencies", "依赖", "前置"))
    has_files = bool(re.search(r"文件|files|scope", text, re.IGNORECASE))
    has_validation = bool(find_section(sections, "验证", "Validation", "验证命令", "Done Definition"))
    has_risks = bool(find_section(sections, "Risk", "风险"))
    has_rollback = bool(re.search(r"回滚|rollback|修复|contingency", text, re.IGNORECASE))

    task_ids = extract_task_ids(text)
    spec_outside = bool(re.search(r"Spec 外|scope 外|spec-outside", text, re.IGNORECASE))

    # Recommended order heuristic
    recommended_order = ["contract", "model", "service", "ui", "integration", "test"]
    order_score = sum(1 for kw in recommended_order if re.search(rf"\b{kw}\b", text, re.IGNORECASE))

    # --- D1: 执行顺序合理性 (15) ---
    d1_score = 15
    d1_deductions = []
    if not has_order:
        d1_score -= 8
        d1_deductions.append("未明确执行顺序")
    if order_score < 3:
        d1_score -= min((3 - order_score) * 2, 6)
        d1_deductions.append(f"执行顺序关键词覆盖 {order_score}/6")
    d1_score = max(0, d1_score)
    dims.append(DimensionScore("执行顺序合理性", 15, d1_score, d1_deductions))

    # --- D2: 依赖关系完整 (12) ---
    d2_score = 12
    d2_deductions = []
    if not has_deps:
        d2_score -= 6
        d2_deductions.append("未声明 Task 依赖")
    if not task_ids:
        d2_score -= 4
        d2_deductions.append("计划未引用具体 Task ID")
    d2_score = max(0, d2_score)
    dims.append(DimensionScore("依赖关系完整", 12, d2_score, d2_deductions))

    # --- D3: 文件范围 (12) ---
    d3_score = 12
    d3_deductions = []
    if not has_files:
        d3_score -= 8
        d3_deductions.append("未列出目标文件范围")
    d3_score = max(0, d3_score)
    dims.append(DimensionScore("文件范围", 12, d3_score, d3_deductions))

    # --- D4: 验证命令 (15) ---
    d4_score = 15
    d4_deductions = []
    if not has_validation:
        d4_score -= 10
        d4_deductions.append("未提供验证命令或 Done Definition")
    commands = re.findall(r"(go test|go build|go vet|golangci-lint|pytest|make test|race)", text, re.IGNORECASE)
    if len(commands) < 2:
        d4_score -= min((2 - len(commands)) * 3, 6)
        d4_deductions.append(f"验证命令种类不足: {len(commands)}")
    d4_score = max(0, d4_score)
    dims.append(DimensionScore("验证命令", 15, d4_score, d4_deductions))

    # --- D5: 风险识别 (13) ---
    d5_score = 13
    d5_deductions = []
    if not has_risks:
        d5_score -= 8
        d5_deductions.append("未识别风险")
    d5_score = max(0, d5_score)
    dims.append(DimensionScore("风险识别", 13, d5_score, d5_deductions))

    # --- D6: 回滚策略 (10) ---
    d6_score = 10
    d6_deductions = []
    if not has_rollback:
        d6_score -= 7
        d6_deductions.append("未提供回滚或修复路径")
    d6_score = max(0, d6_score)
    dims.append(DimensionScore("回滚策略", 10, d6_score, d6_deductions))

    # --- D7: 估算与里程碑 (8) ---
    d7_score = 8
    d7_deductions = []
    if not re.search(r"\d+h|\d+d|milestone|里程碑|估算", text, re.IGNORECASE):
        d7_score -= 5
        d7_deductions.append("缺少工作量或里程碑估算")
    d7_score = max(0, d7_score)
    dims.append(DimensionScore("估算与里程碑", 8, d7_score, d7_deductions))

    # --- D8: 与 Spec/Matrix 一致 (15) ---
    d8_score = 15
    d8_deductions = []
    if spec_outside:
        d8_score -= 10
        d8_deductions.append("计划声明包含 Spec 外内容")
    if not task_ids:
        d8_score -= 5
        d8_deductions.append("未引用 Task，无法验证与 Matrix 一致")
    d8_score = max(0, d8_score)
    dims.append(DimensionScore("与 Spec/Matrix 一致", 15, d8_score, d8_deductions))

    # --- Red lines ---
    reds.append(RedLine("计划中存在 Spec/Matrix 之外的 Task", spec_outside))
    reds.append(RedLine("跳过前置依赖 Task", False))  # Requires dependency graph
    reds.append(RedLine("计划跨模块", bool(re.search(r"跨模块|cross-module|module/\w+/.*module/\w+", text))))
    reds.append(RedLine("高风险 Task 无回滚路径", has_risks and not has_rollback))
    reds.append(RedLine("任一 Task 无验证命令", not has_validation))
    reds.append(RedLine("文件范围互相冲突未协调", False))  # Requires cross-task analysis

    return dims, reds


# ---------------------------------------------------------------------------
# Prompt scoring
# ---------------------------------------------------------------------------


def score_prompt(text: str) -> tuple[list[DimensionScore], list[RedLine]]:
    dims: list[DimensionScore] = []
    reds: list[RedLine] = []
    sections = parse_sections(text)

    nonempty = bool(text and text.strip())

    task_ids = extract_task_ids(text)
    spec_refs = bool(re.search(r"SPEC\.md|spec/\w+/SPEC", text))
    matrix_refs = bool(re.search(r"TRACEABILITY|matrix", text, re.IGNORECASE))
    plan_refs = bool(re.search(r"PLAN\.md|IMPLEMENTATION-PLAN", text))
    has_files = bool(find_section(sections, "Files", "文件"))
    has_constraints = bool(find_section(sections, "Constraints", "约束", "禁止", "Do Not", "限制"))
    has_ac = bool(re.search(r"AC[-\s]*\d+|验收标准|Acceptance", text))
    has_validation = bool(find_section(sections, "Validation", "验证", "验证命令", "Test"))
    has_evidence = bool(re.search(r"证据|evidence|回填|完成后", text, re.IGNORECASE))
    has_fr = bool(re.search(r"FR[-\s]*\d+", text))

    # Single task focus heuristic
    multi_task = len(task_ids) > 1

    # --- D1: 单 Task 聚焦 (15) ---
    d1_score = 15
    d1_deductions = []
    if multi_task:
        d1_score -= 10
        d1_deductions.append(f"Prompt 引用 {len(task_ids)} 个 Task")
    if not task_ids:
        d1_score -= 8
        d1_deductions.append("未引用 Task ID")
    d1_score = max(0, d1_score)
    dims.append(DimensionScore("单 Task 聚焦", 15, d1_score, d1_deductions))

    # --- D2: 上下文引用完整 (15) ---
    d2_score = 15
    d2_deductions = []
    refs = sum([spec_refs, matrix_refs, plan_refs])
    if refs < 2:
        d2_score -= min((2 - refs) * 4, 10)
        d2_deductions.append(f"上下文引用不足: spec={spec_refs}, matrix={matrix_refs}, plan={plan_refs}")
    d2_score = max(0, d2_score)
    dims.append(DimensionScore("上下文引用完整", 15, d2_score, d2_deductions))

    # --- D3: 可改文件范围 (12) ---
    d3_score = 12
    d3_deductions = []
    if not has_files:
        d3_score -= 10
        d3_deductions.append("未列出允许修改的文件")
    else:
        files_section = find_section(sections, "Files", "文件") or ""
        if re.search(r"相关文件|相关代码|相关", files_section):
            d3_score -= 5
            d3_deductions.append("文件范围描述模糊")
    d3_score = max(0, d3_score)
    dims.append(DimensionScore("可改文件范围", 12, d3_score, d3_deductions))

    # --- D4: 禁止事项 (12) ---
    d4_score = 12
    d4_deductions = []
    if not has_constraints:
        d4_score -= 8
        d4_deductions.append("未列出禁止事项")
    d4_score = max(0, d4_score)
    dims.append(DimensionScore("禁止事项", 12, d4_score, d4_deductions))

    # --- D5: 验收标准 (13) ---
    d5_score = 13
    d5_deductions = []
    if not has_ac:
        d5_score -= 8
        d5_deductions.append("未引用 AC")
    d5_score = max(0, d5_score)
    dims.append(DimensionScore("验收标准", 13, d5_score, d5_deductions))

    # --- D6: 验证命令 (13) ---
    d6_score = 13
    d6_deductions = []
    if not has_validation:
        d6_score -= 10
        d6_deductions.append("未提供验证命令")
    commands = re.findall(r"(go test|go build|go vet|golangci-lint|pytest|make test|race)", text, re.IGNORECASE)
    if len(commands) < 1:
        d6_deductions.append("未找到具体可执行命令")
    d6_score = max(0, d6_score)
    dims.append(DimensionScore("验证命令", 13, d6_score, d6_deductions))

    # --- D7: 证据回填要求 (10) ---
    d7_score = 10
    d7_deductions = []
    if not has_evidence:
        d7_score -= 7
        d7_deductions.append("未明确证据回填要求")
    d7_score = max(0, d7_score)
    dims.append(DimensionScore("证据回填要求", 10, d7_score, d7_deductions))

    # --- D8: Requirement/AC/TC ID 引用 (10) ---
    d8_score = 10
    d8_deductions = []
    if not has_fr:
        d8_score -= 5
        d8_deductions.append("未引用 FR ID")
    if not has_ac:
        d8_score -= 5
        d8_deductions.append("未引用 AC ID")
    d8_score = max(0, d8_score)
    dims.append(DimensionScore("Requirement/AC/TC ID 引用", 10, d8_score, d8_deductions))

    # --- Red lines ---
    scope_expansion = bool(re.search(r"额外|顺便|also|additionally|scope.*expand|扩大范围", text, re.IGNORECASE))
    vague_files = has_files and re.search(r"相关文件|相关代码|相关", find_section(sections, "Files", "文件") or "")

    reds.append(RedLine("Prompt 服务多个 Task", multi_task))
    reds.append(RedLine("Prompt 扩大 Task scope", scope_expansion))
    reds.append(RedLine("未引用 Requirement / AC / TC ID", not has_fr or not has_ac))
    reds.append(RedLine("验证命令缺失或不可执行", not has_validation))
    reds.append(RedLine("允许修改文件范围模糊", bool(vague_files)))
    reds.append(RedLine("缺少证据回填要求", not has_evidence))

    return dims, reds


# ---------------------------------------------------------------------------
# Code scoring
# ---------------------------------------------------------------------------


def score_code(evidence_text: str, task_id: str = "") -> tuple[list[DimensionScore], list[RedLine]]:
    dims: list[DimensionScore] = []
    reds: list[RedLine] = []

    nonempty = bool(evidence_text and evidence_text.strip())

    # Evidence required fields
    has_files_changed = bool(re.search(r"Files Changed|修改文件|变更文件", evidence_text, re.IGNORECASE))
    has_commands = bool(re.search(r"Commands Run|执行命令|验证命令", evidence_text, re.IGNORECASE))
    has_results = bool(re.search(r"Results|执行结果|测试结果", evidence_text, re.IGNORECASE))
    has_status = bool(re.search(r"Status:\s*(PASS|FAIL|PARTIAL)", evidence_text, re.IGNORECASE))
    has_rollback = bool(re.search(r"Rollback|回滚", evidence_text, re.IGNORECASE))
    has_risks = bool(re.search(r"Risks|风险", evidence_text, re.IGNORECASE))
    has_traceability_update = bool(re.search(r"TRACEABILITY|Status.*Implemented|Status.*Done", evidence_text, re.IGNORECASE))

    # Test/lint/typecheck evidence
    test_pass = bool(re.search(r"(PASS|ok)\s+\(|测试通过|全部通过", evidence_text, re.IGNORECASE))
    lint_run = bool(re.search(r"golangci-lint|go vet|go fmt|black|flake8|ruff", evidence_text, re.IGNORECASE))
    race_run = bool(re.search(r"-race|race detector", evidence_text, re.IGNORECASE))

    # Secret scan
    secret_patterns = [
        r"api[_-]?key\s*[:=]\s*[\"']?[A-Za-z0-9]{16,}",
        r"password\s*[:=]\s*[\"'][^\"']{8,}[\"']",
        r"token\s*[:=]\s*[\"']?[A-Za-z0-9]{20,}",
        r"sk-[A-Za-z0-9]{20,}",
    ]
    secret_found = any(re.search(p, evidence_text, re.IGNORECASE) for p in secret_patterns)

    # --- D1: Task scope 符合度 (15) ---
    d1_score = 15
    d1_deductions = []
    if not has_files_changed:
        d1_score -= 8
        d1_deductions.append("Evidence 未列出修改文件")
    d1_score = max(0, d1_score)
    dims.append(DimensionScore("Task scope 符合度", 15, d1_score, d1_deductions))

    # --- D2: FR/AC 覆盖 (15) ---
    d2_score = 15
    d2_deductions = []
    fr_in_evidence = set(re.findall(r"FR[-\s]*\d+", evidence_text))
    ac_in_evidence = set(re.findall(r"AC[-\s]*\d+", evidence_text))
    if not fr_in_evidence:
        d2_score -= 8
        d2_deductions.append("Evidence 未引用 FR")
    if not ac_in_evidence:
        d2_score -= 5
        d2_deductions.append("Evidence 未引用 AC")
    d2_score = max(0, d2_score)
    dims.append(DimensionScore("FR/AC 覆盖", 15, d2_score, d2_deductions))

    # --- D3: 测试覆盖 (15) ---
    d3_score = 15
    d3_deductions = []
    if not re.search(r"coverage|覆盖率", evidence_text, re.IGNORECASE):
        d3_score -= 8
        d3_deductions.append("未记录覆盖率")
    tc_in_evidence = set(re.findall(r"TC[-\s]*\d+", evidence_text))
    if not tc_in_evidence:
        d3_score -= 5
        d3_deductions.append("未引用 TC")
    d3_score = max(0, d3_score)
    dims.append(DimensionScore("测试覆盖", 15, d3_score, d3_deductions))

    # --- D4: 测试通过证据 (12) ---
    d4_score = 12
    d4_deductions = []
    if not has_commands:
        d4_score -= 6
        d4_deductions.append("未记录执行命令")
    if not has_results:
        d4_score -= 4
        d4_deductions.append("未记录执行结果")
    if not test_pass:
        d4_score -= 6
        d4_deductions.append("测试结果未显示 PASS")
    d4_score = max(0, d4_score)
    dims.append(DimensionScore("测试通过证据", 12, d4_score, d4_deductions))

    # --- D5: 代码质量 (10) ---
    d5_score = 10
    d5_deductions = []
    if not lint_run:
        d5_score -= 5
        d5_deductions.append("未运行 lint/vet")
    d5_score = max(0, d5_score)
    dims.append(DimensionScore("代码质量", 10, d5_score, d5_deductions))

    # --- D6: 安全与边界 (10) ---
    d6_score = 10
    d6_deductions = []
    if secret_found:
        d6_score -= 10
        d6_deductions.append("Evidence 中疑似包含凭证/密钥")
    if not race_run:
        d6_score -= 3
        d6_deductions.append("未运行 race 检测")
    d6_score = max(0, d6_score)
    dims.append(DimensionScore("安全与边界", 10, d6_score, d6_deductions))

    # --- D7: 文档与注释 (8) ---
    d7_score = 8
    d7_deductions = []
    if not re.search(r"doc|注释|godoc|comment", evidence_text, re.IGNORECASE):
        d7_score -= 4
        d7_deductions.append("未记录文档/注释更新")
    d7_score = max(0, d7_score)
    dims.append(DimensionScore("文档与注释", 8, d7_score, d7_deductions))

    # --- D8: 追溯证据回填 (8) ---
    d8_score = 8
    d8_deductions = []
    if not has_traceability_update:
        d8_score -= 6
        d8_deductions.append("未更新 TRACEABILITY.md 或 Task 状态")
    d8_score = max(0, d8_score)
    dims.append(DimensionScore("追溯证据回填", 8, d8_score, d8_deductions))

    # --- D9: 无破坏性影响 (7) ---
    d9_score = 7
    d9_deductions = []
    fail_match = re.search(r"FAIL|失败|broken", evidence_text, re.IGNORECASE)
    if fail_match and not test_pass:
        d9_score -= 5
        d9_deductions.append("Evidence 中包含失败标记")
    d9_score = max(0, d9_score)
    dims.append(DimensionScore("无破坏性影响", 7, d9_score, d9_deductions))

    # --- Red lines ---
    reds.append(RedLine("修改了 Prompt 未授权的文件", False))  # Requires prompt comparison
    reds.append(RedLine("引入 Spec 外功能", False))  # Requires spec comparison
    reds.append(RedLine("任一 FR/AC 未覆盖", not fr_in_evidence or not ac_in_evidence))
    reds.append(RedLine("测试未运行或运行失败", not test_pass, "测试结果未 PASS"))
    reds.append(RedLine("出现硬编码凭证、密钥、敏感日志", secret_found))
    reds.append(RedLine("引入新依赖未在 Task 中声明", False))  # Requires task comparison
    reds.append(RedLine("破坏现有测试", bool(fail_match and not test_pass)))
    reds.append(RedLine("TRACEABILITY.md 未更新", not has_traceability_update))

    return dims, reds


# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------


def score_artifact(
    rubric_type: str,
    artifact_path: Path,
    task_id: str = "",
) -> ScoreReport:
    if rubric_type == "spec":
        text = artifact_path.read_text(encoding="utf-8")
        dims, reds = score_spec(parse_sections(text), full_text=text)
    elif rubric_type == "matrix":
        text = artifact_path.read_text(encoding="utf-8")
        dims, reds = score_matrix(text)
    elif rubric_type == "tasks":
        if artifact_path.is_dir():
            task_files = sorted(artifact_path.glob("TASK-*.md"))
        else:
            task_files = [artifact_path]
        dims, reds = score_tasks(task_files)
    elif rubric_type == "plan":
        text = artifact_path.read_text(encoding="utf-8")
        dims, reds = score_plan(text)
    elif rubric_type == "prompt":
        text = artifact_path.read_text(encoding="utf-8")
        dims, reds = score_prompt(text)
    elif rubric_type == "code":
        text = artifact_path.read_text(encoding="utf-8")
        dims, reds = score_code(text, task_id=task_id)
    else:
        raise ValueError(f"不支持的 rubric 类型: {rubric_type}")

    total = sum(d.score for d in dims)
    max_total = sum(d.max_score for d in dims)
    any_red = any(r.triggered for r in reds)
    composite = 0 if any_red else total

    verdict = "PASS" if composite >= PASS_THRESHOLD and not any_red else "FAIL"

    return ScoreReport(
        artifact=str(artifact_path),
        rubric_type=rubric_type,
        dimensions=dims,
        red_lines=reds,
        total=total,
        max_total=max_total,
        composite_score=composite,
        pass_threshold=PASS_THRESHOLD,
        verdict=verdict,
    )


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(
        description="Rubric-based structural auto-scorer for Goal pipeline artifacts."
    )
    parser.add_argument(
        "rubric_type",
        choices=["spec", "matrix", "tasks", "plan", "prompt", "code"],
        help="Rubric type.",
    )
    parser.add_argument(
        "artifact",
        help="Path to the artifact. For 'tasks' this should be a directory; for others a file.",
    )
    parser.add_argument(
        "--task",
        dest="task_id",
        default="",
        help="Task ID (only used for 'code' scoring).",
    )
    parser.add_argument(
        "--json",
        dest="as_json",
        action="store_true",
        help="Emit a JSON report instead of human-readable text.",
    )
    args = parser.parse_args()

    artifact_path = Path(args.artifact)
    if not artifact_path.exists():
        print(f"rubric-score: 路径不存在: {artifact_path}", file=sys.stderr)
        sys.exit(2)

    if args.rubric_type == "tasks" and not artifact_path.is_dir():
        print(f"rubric-score: 'tasks' 评分需要目录路径: {artifact_path}", file=sys.stderr)
        sys.exit(2)

    if args.rubric_type != "tasks" and artifact_path.is_dir():
        print(f"rubric-score: '{args.rubric_type}' 评分需要文件路径: {artifact_path}", file=sys.stderr)
        sys.exit(2)

    report = score_artifact(args.rubric_type, artifact_path, task_id=args.task_id)

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
