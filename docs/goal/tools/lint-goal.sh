#!/usr/bin/env bash
# lint-goal.sh — Goal/Spec/Matrix Lint 规则检查
# 执行 docs/goal/10-lint-rules.md 中定义的自动化检查
# 用法: ./docs/goal/tools/lint-goal.sh <目标目录或文件>

set -euo pipefail

TARGET="${1:?用法: $0 <目标目录或文件>}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
LINT_GROUPS=("G" "S" "M" "P")

declare -A RULE_TOTAL=(
    ["G"]=7
    ["S"]=8
    ["M"]=8
    ["P"]=10
)
declare -A RULE_AUTOMATED=(
    ["G"]=3
    ["S"]=8
    ["M"]=8
    ["P"]=2
)
declare -A RULE_FINDINGS=(
    ["G"]=0
    ["S"]=0
    ["M"]=0
    ["P"]=0
)
declare -A RULE_SEEN=()

error() { echo -e "${RED}ERROR${NC}: $1"; ((ERRORS += 1)); }
warn()  { echo -e "${YELLOW}WARN${NC}:  $1"; ((WARNINGS += 1)); }
ok()    { echo -e "${GREEN}OK${NC}:    $1"; }
mark_rule() { RULE_SEEN["$1:$2"]=1; }
finding() { ((RULE_FINDINGS["$1"] += 1)); }
file_has() { grep -qi -- "$1" "$f"; }
file_has_ext() { grep -qE -- "$1" "$f"; }
file_has_literal() { grep -qF -- "$1" "$f"; }
file_count_ext() {
    local count
    count=$(grep -cE -- "$1" "$f" || true)
    printf '%s\n' "${count:-0}"
}

echo "=========================================="
echo "  Goal 体系 Lint 检查"
echo "=========================================="
echo ""

# 收集目标文档和配置文件
if [ -d "$TARGET" ]; then
    FILES=$(find "$TARGET" \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" \) -type f -not -path "*/docs/goal/schema/*" 2>/dev/null)
elif [ -f "$TARGET" ]; then
    FILES="$TARGET"
else
    echo "目标不存在: $TARGET"
    exit 1
fi

for f in $FILES; do
    BASENAME=$(basename "$f")

    # === Goal Lint 规则 ===
    if echo "$BASENAME" | grep -qi "goal\|spec\|task"; then

        # G-LINT-001: Goal 必须有衡量指标
        mark_rule "G" "G-LINT-001"
        if file_has "goal"; then
            if ! file_has_ext "[0-9]+(%|秒|分钟|小时|ms|个|次|条|行)"; then
                if file_has "成功\|完成\|达到\|目标"; then
                    warn "[$BASENAME] G-LINT-001: Goal 描述成功但缺少量化指标"
                    finding "G"
                fi
            fi
        fi

        # G-LINT-002: 禁止模糊词
        mark_rule "G" "G-LINT-002"
        FUZZY_WORDS=("优化" "提升" "改善" "完善" "加强" "尽量" "尽可能" "适时" "酌情")
        for word in "${FUZZY_WORDS[@]}"; do
            if file_has_literal "$word"; then
                WORD_CONTEXT=$(grep -A1 -- "$word" "$f" || true)
                if ! grep -qE "[0-9]+" <<< "$WORD_CONTEXT"; then
                    warn "[$BASENAME] G-LINT-002: 发现模糊词「$word」且无量化说明"
                    finding "G"
                fi
            fi
        done

        # G-LINT-003: Goal 不应包含实现细节
        mark_rule "G" "G-LINT-003"
        IMPL_WORDS=("数据库" "Redis" "PostgreSQL" "API" "接口" "前端" "后端" "微服务" "SDK")
        for word in "${IMPL_WORDS[@]}"; do
            if file_has_literal "$word"; then
                WORD_CONTEXT=$(grep -B2 -- "$word" "$f" || true)
                if grep -qi "goal" <<< "$WORD_CONTEXT"; then
                    warn "[$BASENAME] G-LINT-003: Goal 包含实现细节「$word」，应改为结果描述"
                    finding "G"
                fi
            fi
        done
    fi

    # === Spec Lint 规则 ===
    if echo "$BASENAME" | grep -qi "spec"; then
        # S-LINT-001~003: 结构化语义分析（Python inline）
        # S-LINT-004~008: trigger → 缺失内容 关键词 + 上下文检查

        SPEC_FINDINGS=$(python3 - "$f" <<'PYSPEC'
import re
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()

def emit(level: str, rule: str, message: str) -> None:
    print(f"{level}\t{rule}\t{message}")

# ── Markdown section extraction ──────────────────────────────────
# Extract sections by heading level (## / ###), keeping heading text
sections: list[tuple[str, str, int]] = []  # (heading, body, level)
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

section_map: dict[str, str] = {}
for h, b, _ in sections:
    section_map[h.lower()] = b

def section_contains(section_key: str, pattern: str) -> bool:
    body = section_map.get(section_key.lower(), "")
    return bool(re.search(pattern, body, re.IGNORECASE))

# ── S-LINT-001: 每条 Functional Requirement 必须有唯一 ID ────────
# 提取所有 FR ID（FR-NNN 或 REQ-SPEC-*，从 heading 和 body 分别扫描）
req_pattern = re.compile(r"\b(REQ-SPEC-[A-Za-z0-9._-]+|FR-\d+)\b", re.IGNORECASE)
req_ids: list[str] = []
req_sources: dict[str, list[str]] = {}  # id -> [source headings] for dedup
for h, b, _ in sections:
    for m in req_pattern.finditer(h):
        rid = m.group(0)
        req_ids.append(rid)
        req_sources.setdefault(rid.upper(), []).append(f"heading:{h[:60]}")
    for m in req_pattern.finditer(b):
        rid = m.group(0)
        req_ids.append(rid)
        req_sources.setdefault(rid.upper(), []).append(f"body of §{h[:40]}")

if not req_ids:
    # 降级：检查是否有任何形式的编号列表（如 1. / 2. / a) 等）
    # 这些可能表示未使用结构化 ID 的需求
    loose_items = re.findall(r"^\s*[-*]\s+[A-Z].*$|^\s*(WHEN|MUST|SHALL)\b", text, re.MULTILINE | re.IGNORECASE)
    if loose_items:
        emit("WARN", "S-LINT-001",
             f"发现 {len(loose_items)} 条需求描述，但无结构化 ID（FR-NNN / REQ-SPEC-*）")
    else:
        emit("WARN", "S-LINT-001",
             "未发现 Functional Requirement ID，无法校验唯一性")
else:
    seen: set[str] = set()
    dups: list[str] = []
    for rid in req_ids:
        if rid.upper() in seen:
            dups.append(rid)
        seen.add(rid.upper())
    if dups:
        emit("ERROR", "S-LINT-001",
             f"发现 {len(dups)} 个重复 Requirement ID: {', '.join(dups)}")

# ── S-LINT-002: 每条 Requirement 必须能被测试 ──────────────────────
# 规则语义：FR 数量和 AC 数量应匹配（至少 1:1）。如果 FR 远多于 AC，
# 说明有些 Requirement 不可测试。TC 的存在是加分项。
fr_blocks: list[tuple[str, str]] = []
for h, b, lvl in sections:
    if re.search(r"^(FR-|REQ-SPEC-)", h, re.IGNORECASE):
        fr_blocks.append((h, b))

ac_id_set = set(a.upper() for a in re.findall(r"\bAC-\d+\b", text, re.IGNORECASE))
tc_id_set = set(t.upper() for t in re.findall(r"\bTC-\d+\b", text, re.IGNORECASE))

fr_count = len(fr_blocks)
ac_count = len(ac_id_set)
tc_count = len(tc_id_set)

if fr_count == 0:
    pass  # 无 FR 则规则不适用（可能无 Functional Requirements 段）
elif ac_count == 0:
    # 无 AC = 完全不可测试
    emit("WARN", "S-LINT-002",
         f"{fr_count} 条 FR 存在，但零 AC 条目——需求不可测试")
elif fr_count > ac_count * 2:
    # FR 是 AC 两倍以上 → 覆盖率严重不足
    emit("WARN", "S-LINT-002",
         f"{fr_count} 条 FR 仅对应 {ac_count} 条 AC（覆盖不足，建议 1:1 映射）")
elif tc_count == 0 and ac_count < fr_count:
    # 有 AC 但无 TC — 降级告警
    emit("WARN", "S-LINT-002",
         f"{fr_count} 条 FR 对应 {ac_count} 条 AC，无 TC 入口")

# ── S-LINT-003: 每条 Acceptance Criteria 必须有明确结果 ────────────
# 「明确结果」= 描述中包含可验证的断言，而非仅描述行为或表达期望
# 通过信号：RETURN 具体值、状态码、字段断言、时间约束、布尔表达式
ac_body = section_map.get("acceptance criteria", "")
if ac_body:
    # 提取 AC 表格行：| AC-XXX | 描述 |
    ac_rows = re.findall(r"\|\s*(AC-\S+)\s*\|\s*(.+?)\s*\|", ac_body)
    ac_items = [f"{aid} | {desc.strip()}" for aid, desc in ac_rows]
    if not ac_items:
        # fallback: list-style AC items
        ac_items = re.findall(r"-\s*(AC-\S+[^\n]*)", ac_body)

    # 「模糊词」= 不能单独构成验收标准的表述
    vague_patterns = [
        r"测试通过", r"功能正常", r"正确实现", r"满足需求",
        r"行为正确", r"结果正确", r"符合预期\s*$", r"无异常",
        r"正常运行", r"操作成功\s*$",
        r"pass\s+test", r"works?\s+correctly\s*$",
        r"as\s+expected\s*$", r"no\s+error",
    ]
    vague_acs: list[str] = []
    empty_acs: list[str] = []
    # 「确定性信号」= AC 描述中包含可验证结果的关键词
    determinate_signals = [
        r"\b返回\b", r"\bRETURN\b", r"\b显示\b", r"\b输出\b",
        r"\bstatus\b", r"\b状态.*(为|是|=)\b", r"=", r"==",
        r"\bmust\b", r"\bshall\b", r"\b错误\b", r"\binvalid\b",
        r"\bpanic\b", r"\bpanic\b", r"\bfail\b", r"\bsuccess\b",
    ]

    for item in ac_items:
        # ac_items 格式: "AC-NNN | description text" 或 "AC-NNN description"
        if "|" in item:
            ac_id = item.split("|")[0].strip()
            desc = item.split("|", 1)[-1].strip()
        else:
            ac_id = item[:40].strip()
            desc = item

        # 检查是否空描述
        desc = re.sub(r"\s+", " ", desc).strip()
        if not desc or len(desc) < 5:
            empty_acs.append(ac_id[:40])
            continue

        # 空描述已标记，不需要再检查模糊度
        # 检查是否仅有模糊词，缺乏具体断言
        has_determinate = any(re.search(sig, desc, re.IGNORECASE) for sig in determinate_signals)
        for pat in vague_patterns:
            if re.search(pat, desc, re.IGNORECASE):
                if has_determinate:
                    # AC 同时有模糊词 + 具体断言 → 可以接受
                    pass
                else:
                    vague_acs.append(ac_id[:80])
                break

    if empty_acs:
        emit("WARN", "S-LINT-003",
             f"{len(empty_acs)} 条 AC 缺少结果描述: {', '.join(empty_acs[:5])}")
    if vague_acs:
        emit("WARN", "S-LINT-003",
             f"{len(vague_acs)} 条 AC 描述模糊、无明确可验证结果（如「测试通过」「功能正常」）")

# ── S-LINT-004~008: trigger → missing 语义检查 ─────────────────────
all_headings = [h.lower() for h, _, _ in sections]
body_has = lambda pattern: bool(re.search(pattern, text, re.IGNORECASE))
has_section = lambda name: any(name.lower() in h for h in all_headings)

# S-LINT-004: 权限相关 Spec 必须包含 Security Requirements
if body_has(r"权限|认证|登录|auth|permission|角色"):
    if not has_section("security") and not body_has(r"security\s*requirement|安全要求|权限检查|access\s*control"):
        emit("WARN", "S-LINT-004",
             "Spec 涉及权限/认证但缺少 Security Requirements 段")

# S-LINT-005: 数据导入/导出 Spec 必须包含数据量限制
if body_has(r"导出|导入|export|import|download|上传|upload"):
    if not body_has(r"[0-9]+\s*(行|条|MB|GB|记录|record|limit|max|上限|限制)"):
        emit("WARN", "S-LINT-005",
             "Spec 涉及导入/导出但缺少数据量限制（如 1000 行、500MB 上限）")

# S-LINT-006: 异步任务 Spec 必须包含状态流转规则
if body_has(r"异步|async|队列|queue|任务|task|job|定时|schedule"):
    if not body_has(r"状态|status|流转|transition|回调|callback|重试|retry"):
        if not has_section("state"):
            emit("WARN", "S-LINT-006",
                 "Spec 涉及异步任务但缺少状态流转规则（状态/重试/回调）")

# S-LINT-007: 涉及错误场景的 Spec 必须包含 Error Handling
if body_has(r"错误|error|异常|exception|失败|fail"):
    if not has_section("error handling") and not body_has(r"error\s*handling|错误处理|fallback|降级"):
        emit("WARN", "S-LINT-007",
             "Spec 涉及错误场景但缺少 Error Handling 段")

# S-LINT-008: 涉及外部服务的 Spec 必须包含失败处理
if body_has(r"外部|external|API|第三方|third\s*party|调用|call|请求|request"):
    if not body_has(r"超时|timeout|重试|retry|熔断|circuit\s*break|降级|fallback"):
        emit("WARN", "S-LINT-008",
             "Spec 涉及外部服务但缺少失败处理（超时/retry/熔断/降级）")

PYSPEC
)
        # 处理 Python 输出的 Spec lint 结果
        # 始终标记所有已检查的规则
        for r in S-LINT-001 S-LINT-002 S-LINT-003 S-LINT-004 S-LINT-005 S-LINT-006 S-LINT-007 S-LINT-008; do
            mark_rule "S" "$r"
        done
        if [ -n "$SPEC_FINDINGS" ]; then
            while IFS=$'\t' read -r level rule message; do
                [ -z "$level" ] && continue
                if [ "$level" = "ERROR" ]; then
                    error "[$BASENAME] $rule: $message"
                else
                    warn "[$BASENAME] $rule: $message"
                fi
                finding "S"
            done <<< "$SPEC_FINDINGS"
        fi
    fi

    # === Matrix Lint 规则 ===
    if echo "$BASENAME" | grep -qi "matrix\|traceability"; then
        for rule in M-LINT-001 M-LINT-002 M-LINT-003 M-LINT-004 M-LINT-005 M-LINT-006 M-LINT-007 M-LINT-008; do
            mark_rule "M" "$rule"
        done

        MATRIX_FINDINGS=$(python3 - "$f" <<'PY'
import re
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()

required = [
    "source_id",
    "target_id",
    "relation",
    "status",
    "evidence_id",
    "gate_id",
    "owner",
    "updated_at",
]
non_empty = {"source_id", "target_id", "relation", "status", "gate_id", "owner", "updated_at"}
relations = {
    "decomposes_to",
    "contains",
    "accepted_by",
    "planned_by",
    "implemented_by",
    "prompted_by",
    "verified_by",
    "evidenced_by",
}
statuses = {"Unmapped", "Mapped", "Linked", "Verified", "Dropped", "Drifted", "Stale", "Blocked", "Changed"}


def clean(value: str) -> str:
    value = value.split("#", 1)[0].strip()
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        value = value[1:-1]
    return value.strip()


rows = []
current = None
for raw_line in text.splitlines():
    start = re.match(r"^\s*-\s+(source_id|goal_id):\s*(.*)$", raw_line)
    if start:
        if current is not None:
            rows.append(current)
        current = {"source_id": clean(start.group(2))}
        continue
    if current is None:
        continue
    field = re.match(r"^\s+([A-Za-z_]+):\s*(.*)$", raw_line)
    if field:
        current[field.group(1)] = clean(field.group(2))
if current is not None:
    rows.append(current)


def emit(level: str, rule: str, message: str) -> None:
    print(f"{level}\t{rule}\t{message}")


if not rows:
    emit("ERROR", "M-LINT-008", "未发现以 source_id 或 goal_id 开始的 Matrix edge")

for idx, row in enumerate(rows, 1):
    missing = [name for name in required if name not in row]
    if missing:
        emit("ERROR", "M-LINT-001", f"edge {idx} 缺少字段: {', '.join(missing)}")

    empty_ids = [name for name in ("source_id", "target_id") if row.get(name, "") == ""]
    if empty_ids:
        emit("ERROR", "M-LINT-006", f"edge {idx} 空 ID 字段: {', '.join(empty_ids)}")

    empty_meta = [name for name in ("gate_id", "owner", "updated_at") if row.get(name, "") == ""]
    if empty_meta:
        emit("ERROR", "M-LINT-007", f"edge {idx} 空元数据字段: {', '.join(empty_meta)}")

    empty_required = [name for name in non_empty if name in row and row.get(name, "") == ""]
    if empty_required:
        emit("ERROR", "M-LINT-001", f"edge {idx} 必填字段为空: {', '.join(sorted(empty_required))}")

    relation = row.get("relation", "")
    if relation and relation not in relations:
        emit("ERROR", "M-LINT-002", f"edge {idx} 非法 relation: {relation}")

    status = row.get("status", "")
    if status and status not in statuses:
        emit("ERROR", "M-LINT-003", f"edge {idx} 非法 status: {status}")

    if status == "Verified" and row.get("evidence_id", "") == "":
        emit("ERROR", "M-LINT-004", f"edge {idx} Verified 缺少 evidence_id")

    if status == "Dropped" and row.get("drop_reason", "") == "":
        emit("ERROR", "M-LINT-005", f"edge {idx} Dropped 缺少 drop_reason")
PY
)
        if [ -n "$MATRIX_FINDINGS" ]; then
            while IFS=$'\t' read -r level rule message; do
                [ -z "$level" ] && continue
                if [ "$level" = "ERROR" ]; then
                    error "[$BASENAME] $rule: $message"
                else
                    warn "[$BASENAME] $rule: $message"
                fi
                finding "M"
            done <<< "$MATRIX_FINDINGS"
        fi
    fi

    # === Prompt Lint 规则 ===
    if echo "$BASENAME" | grep -qi "prompt"; then

        # P-LINT-001: Prompt 必须有 Constraints
        mark_rule "P" "P-LINT-001"
        if ! file_has "constraint\|限制\|禁止\|do.not"; then
            warn "[$BASENAME] P-LINT-001: Prompt 缺少 Constraints/限制条件"
            finding "P"
        fi

        # P-LINT-002: Prompt 必须有明确输出格式
        mark_rule "P" "P-LINT-002"
        if ! file_has "output\|输出\|格式\|format"; then
            warn "[$BASENAME] P-LINT-002: Prompt 缺少输出格式说明"
            finding "P"
        fi
    fi

    # === 通用检查 ===
    if file_has_ext "[0-9]{5,}.*@(163|qq|gmail)\.(com|cn)"; then
        error "[$BASENAME] 安全: 发现疑似真实邮箱地址"
    fi
    if file_has_ext "api[_-]?key.*=.*[A-Za-z0-9]{20,}"; then
        error "[$BASENAME] 安全: 发现疑似 API Key"
    fi

done

echo ""
echo "=========================================="
echo "  规则覆盖摘要"
echo "=========================================="
for group in "${LINT_GROUPS[@]}"; do
    CHECKED=0
    for key in "${!RULE_SEEN[@]}"; do
        if [[ "$key" == "$group:"* ]]; then
            ((CHECKED += 1))
        fi
    done
    TOTAL="${RULE_TOTAL[$group]:-0}"
    AUTOMATED="${RULE_AUTOMATED[$group]:-0}"
    FINDINGS="${RULE_FINDINGS[$group]:-0}"
    echo "${group}-LINT: automated=${AUTOMATED}/${TOTAL} checked_this_run=${CHECKED} findings=${FINDINGS}"
done

echo ""
echo "=========================================="
echo "  结果: ERRORS=${ERRORS}  WARNINGS=${WARNINGS}"
echo "=========================================="

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}存在错误，需修复。${NC}"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}存在警告，建议修复。${NC}"
    exit 0
else
    echo -e "${GREEN}全部通过。${NC}"
    exit 0
fi
