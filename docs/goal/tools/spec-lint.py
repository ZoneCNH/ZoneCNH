#!/usr/bin/env python3
"""S-LINT Spec 规则检查（docs/goal/10-lint-rules.md S-LINT-001~008）

用法: python3 spec-lint.py <spec_file.md>
输出: 每行 TSV 格式 "LEVEL\tRULE\tMESSAGE"
退出码: 0=无发现 1=有ERROR 2=有WARN
"""

import re
import sys


def emit(level: str, rule: str, message: str) -> None:
    print(f"{level}\t{rule}\t{message}")


# ── Markdown section extraction ──────────────────────────────────────

def extract_sections(text: str) -> list[tuple[str, str, int]]:
    sections: list[tuple[str, str, int]] = []
    current_heading = ""
    current_body_lines: list[str] = []
    current_level = 0
    heading_pattern = re.compile(r"^(#{2,4})\s+(.+)$")

    for raw in text.splitlines():
        m = heading_pattern.match(raw)
        if m:
            if current_heading or current_body_lines:
                sections.append((current_heading, "\n".join(current_body_lines), current_level))
            current_level = len(m.group(1))
            current_heading = m.group(2).strip()
            current_body_lines = []
        else:
            current_body_lines.append(raw)
    if current_heading or current_body_lines:
        sections.append((current_heading, "\n".join(current_body_lines), current_level))
    return sections


def lint_spec(text: str) -> tuple[int, int]:
    error_count = 0
    warn_count = 0

    def emit_count(level: str, rule: str, message: str) -> None:
        nonlocal error_count, warn_count
        emit(level, rule, message)
        if level == "ERROR":
            error_count += 1
        else:
            warn_count += 1

    sections = extract_sections(text)
    section_map: dict[str, str] = {h.lower(): b for h, b, _ in sections}
    all_headings = [h.lower() for h, _, _ in sections]

    # ── S-LINT-001: 每条 Functional Requirement 必须有唯一 ID ─────────
    req_pattern = re.compile(r"\b(REQ-SPEC-[A-Za-z0-9._-]+|FR-\d+)\b", re.IGNORECASE)
    req_ids: list[str] = []

    for h, b, _ in sections:
        for m in req_pattern.finditer(h):
            req_ids.append(m.group(0))
        for m in req_pattern.finditer(b):
            req_ids.append(m.group(0))

    if not req_ids:
        loose_items = re.findall(
            r"^\s*[-*]\s+[A-Z].*$|^\s*(WHEN|MUST|SHALL)\b",
            text, re.MULTILINE | re.IGNORECASE,
        )
        if loose_items:
            emit_count("WARN", "S-LINT-001",
                       f"发现 {len(loose_items)} 条需求描述，但无结构化 ID（FR-NNN / REQ-SPEC-*）")
        else:
            emit_count("WARN", "S-LINT-001",
                       "未发现 Functional Requirement ID，无法校验唯一性")
    else:
        seen: set[str] = set()
        dups: list[str] = []
        for rid in req_ids:
            if rid.upper() in seen:
                dups.append(rid)
            seen.add(rid.upper())
        if dups:
            emit_count("ERROR", "S-LINT-001",
                       f"发现 {len(dups)} 个重复 Requirement ID: {', '.join(dups)}")

    # ── S-LINT-002: 每条 Requirement 必须能被测试 ──────────────────────
    fr_blocks: list[tuple[str, str]] = []
    for h, b, _ in sections:
        if re.search(r"^(FR-|REQ-SPEC-)", h, re.IGNORECASE):
            fr_blocks.append((h, b))

    ac_id_set = set(a.upper() for a in re.findall(r"\bAC-\d+\b", text, re.IGNORECASE))
    tc_id_set = set(t.upper() for t in re.findall(r"\bTC-\d+\b", text, re.IGNORECASE))

    fr_count = len(fr_blocks)
    ac_count = len(ac_id_set)
    tc_count = len(tc_id_set)

    if fr_count > 0:
        if ac_count == 0:
            emit_count("WARN", "S-LINT-002",
                       f"{fr_count} 条 FR 存在，但零 AC 条目——需求不可测试")
        elif fr_count > ac_count * 2:
            emit_count("WARN", "S-LINT-002",
                       f"{fr_count} 条 FR 仅对应 {ac_count} 条 AC（覆盖不足，建议 1:1 映射）")
        elif tc_count == 0 and ac_count < fr_count:
            emit_count("WARN", "S-LINT-002",
                       f"{fr_count} 条 FR 对应 {ac_count} 条 AC，无 TC 入口")

    # ── S-LINT-003: 每条 Acceptance Criteria 必须有明确结果 ────────────
    ac_body = section_map.get("acceptance criteria", "")
    if ac_body:
        ac_rows = re.findall(r"\|\s*(AC-\S+)\s*\|\s*(.+?)\s*\|", ac_body)
        ac_items = [f"{aid} | {desc.strip()}" for aid, desc in ac_rows]
        if not ac_items:
            ac_items = re.findall(r"-\s*(AC-\S+[^\n]*)", ac_body)

        vague_patterns = [
            r"测试通过", r"功能正常", r"正确实现", r"满足需求",
            r"行为正确", r"结果正确", r"符合预期\s*$", r"无异常",
            r"正常运行", r"操作成功\s*$",
            r"pass\s+test", r"works?\s+correctly\s*$",
            r"as\s+expected\s*$", r"no\s+error",
        ]
        vague_acs: list[str] = []
        empty_acs: list[str] = []
        determinate_signals = [
            r"\b返回\b", r"\bRETURN\b", r"\b显示\b", r"\b输出\b",
            r"\bstatus\b", r"\b状态.*(为|是|=)\b", r"=", r"==",
            r"\bmust\b", r"\bshall\b", r"\b错误\b", r"\binvalid\b",
            r"\bpanic\b", r"\bfail\b", r"\bsuccess\b",
        ]

        for item in ac_items:
            if "|" in item:
                ac_id = item.split("|")[0].strip()
                desc = item.split("|", 1)[-1].strip()
            else:
                ac_id = item[:40].strip()
                desc = item

            desc = re.sub(r"\s+", " ", desc).strip()
            if not desc or len(desc) < 5:
                empty_acs.append(ac_id[:40])
                continue

            has_determinate = any(
                re.search(sig, desc, re.IGNORECASE) for sig in determinate_signals
            )
            for pat in vague_patterns:
                if re.search(pat, desc, re.IGNORECASE):
                    if not has_determinate:
                        vague_acs.append(ac_id[:80])
                    break

        if empty_acs:
            emit_count("WARN", "S-LINT-003",
                       f"{len(empty_acs)} 条 AC 缺少结果描述: {', '.join(empty_acs[:5])}")
        if vague_acs:
            emit_count("WARN", "S-LINT-003",
                       f"{len(vague_acs)} 条 AC 描述模糊、无明确可验证结果（如「测试通过」「功能正常」）")

    # ── S-LINT-004~008: trigger → missing 语义检查 ─────────────────────
    body_has = lambda pattern: bool(re.search(pattern, text, re.IGNORECASE))
    has_section = lambda name: any(name.lower() in h for h in all_headings)

    # S-LINT-004: 权限相关 Spec 必须包含 Security Requirements
    if body_has(r"权限|认证|登录|auth|permission|角色"):
        if not has_section("security") and not body_has(
            r"security\s*requirement|安全要求|权限检查|access\s*control"
        ):
            emit_count("WARN", "S-LINT-004",
                       "Spec 涉及权限/认证但缺少 Security Requirements 段")

    # S-LINT-005: 数据导入/导出 Spec 必须包含数据量限制
    if body_has(r"导出|导入|export|import|download|上传|upload"):
        if not body_has(r"[0-9]+\s*(行|条|MB|GB|记录|record|limit|max|上限|限制)"):
            emit_count("WARN", "S-LINT-005",
                       "Spec 涉及导入/导出但缺少数据量限制（如 1000 行、500MB 上限）")

    # S-LINT-006: 异步任务 Spec 必须包含状态流转规则
    if body_has(r"异步|async|队列|queue|任务|task|job|定时|schedule"):
        if not body_has(r"状态|status|流转|transition|回调|callback|重试|retry"):
            if not has_section("state"):
                emit_count("WARN", "S-LINT-006",
                           "Spec 涉及异步任务但缺少状态流转规则（状态/重试/回调）")

    # S-LINT-007: 涉及错误场景的 Spec 必须包含 Error Handling
    if body_has(r"错误|error|异常|exception|失败|fail"):
        if not has_section("error handling") and not body_has(
            r"error\s*handling|错误处理|fallback|降级"
        ):
            emit_count("WARN", "S-LINT-007",
                       "Spec 涉及错误场景但缺少 Error Handling 段")

    # S-LINT-008: 涉及外部服务的 Spec 必须包含失败处理
    if body_has(r"外部|external|API|第三方|third\s*party|调用|call|请求|request"):
        if not body_has(r"超时|timeout|重试|retry|熔断|circuit\s*break|降级|fallback"):
            emit_count("WARN", "S-LINT-008",
                       "Spec 涉及外部服务但缺少失败处理（超时/retry/熔断/降级）")

    return error_count, warn_count


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python3 spec-lint.py <spec_file.md>", file=sys.stderr)
        sys.exit(3)

    path = sys.argv[1]
    try:
        text = open(path, encoding="utf-8").read()
    except FileNotFoundError:
        print(f"文件不存在: {path}", file=sys.stderr)
        sys.exit(3)

    errors, warnings = lint_spec(text)
    if errors > 0:
        sys.exit(1)
    elif warnings > 0:
        sys.exit(2)
    else:
        sys.exit(0)
