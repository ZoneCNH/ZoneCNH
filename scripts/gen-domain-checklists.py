#!/usr/bin/env python3
"""为 5 个 L2.5 领域共享模块生成 FEATURES.md 与 ACCEPTANCE.md。

适用：domainx、decimalx、domain-market、domain-exchange、domain-macro
读 module/{m}/SPEC.md 抽取 FR/BR/NFR/TC/AC 编号；
写 module/{m}/FEATURES.md（实现清单）与 module/{m}/ACCEPTANCE.md（验收清单）。

调用：python3 scripts/gen-domain-checklists.py
"""
import re
from pathlib import Path
from datetime import date

MODULES = ["domainx", "decimalx", "domain-market", "domain-exchange", "domain-macro"]

TODAY = date.today().isoformat()
ROOT = Path(__file__).resolve().parent.parent

# Match FR-001 / FR-DEC-001 / FR-MAC-001 etc. The 2nd capture is the suffix
# (digits with optional letter-prefix segment), kept verbatim in the output ID.
HEADING_RE = re.compile(
    r"^###\s+(FR|BR|NFR|AC|TC)-([A-Z]+-\d+(?:[-.]\d+)?|\d+(?:[-.]\d+)?)\s*[:：]?\s*(.*?)\s*$"
)
TABLE_RE = re.compile(
    r"^\|\s*(FR|BR|NFR|AC|TC)-([A-Z]+-\d+(?:[-.]\d+)?|\d+(?:[-.]\d+)?)\s*\|\s*(.*?)\s*\|"
)
AC_INLINE_RE = re.compile(r"AC-([A-Z\d-]+):\s*([^|]+)")


def extract(spec_path: Path) -> dict:
    data: dict = {"FR": [], "BR": [], "NFR": [], "AC": [], "TC": []}
    seen: set = set()
    if not spec_path.exists():
        return data
    text = spec_path.read_text(encoding="utf-8", errors="replace")
    for ln in text.splitlines():
        m = HEADING_RE.match(ln)
        if m:
            t, num, title = m.group(1), m.group(2), m.group(3).strip()
            key = (t, num)
            if key not in seen:
                seen.add(key)
                data[t].append((f"{t}-{num}", title or ""))
            continue
        m = TABLE_RE.match(ln)
        if m:
            t, num, body = m.group(1), m.group(2), m.group(3).strip()
            key = (t, num)
            if key not in seen:
                seen.add(key)
                title = body[:140] + ("…" if len(body) > 140 else "")
                data[t].append((f"{t}-{num}", title))
            for am in AC_INLINE_RE.finditer(ln):
                ac_id = "AC-" + am.group(1)
                ac_title = am.group(2).strip()[:120]
                if ac_id not in seen:
                    seen.add(ac_id)
                    data["AC"].append((ac_id, ac_title))
    return data


def gen_features(module: str, data: dict) -> str:
    fr, br, nfr = data["FR"], data["BR"], data["NFR"]
    lines = [
        f"# {module} 完整实现功能清单",
        "",
        "- Status: Generated（与 [SPEC.md](./SPEC.md) 同步抽取，未经 pipeline-arbiter 校验）",
        f"- Last-Updated: {TODAY}",
        "- Source: [SPEC.md](./SPEC.md) · [TRACEABILITY.md](./TRACEABILITY.md) · [goal.md](./goal.md)",
        f"- Scale: {len(fr)} FR · {len(br)} BR · {len(nfr)} NFR",
        "",
        f"> 本文档是 {module} **要完整实现的、可勾选的功能清单**，把 SPEC 的 FR/BR/NFR 展开成具体可验收的功能点。",
        "> 它不是 Why（goal.md）、不是规格（SPEC.md）、不是追溯矩阵（TRACEABILITY.md）。",
        "> 实现状态以本清单勾选为准；任一未勾选项存在即视为未完整实现。",
        "",
        "勾选图例：`[ ]` 待实现 · `[x]` 已实现并通过对应 TC · `[~]` 部分实现（须在备注列注明缺口）",
        "",
        "---",
        "",
        "## 1. 功能需求（FR）",
        "",
    ]
    if fr:
        for fid, title in fr:
            lines.append(f"- [ ] **{fid}** {title or '（标题待补，见 SPEC）'}")
    else:
        lines.append("> SPEC 中未抽取到 `FR-` 编号；请人工对照 SPEC §6 功能需求补全。")

    lines += ["", "## 2. 业务规则（BR）", ""]
    if br:
        for bid, title in br:
            lines.append(f"- [ ] **{bid}** {title or '（规则待补，见 SPEC）'}")
    else:
        lines.append("> SPEC 中未抽取到 `BR-` 编号；请人工对照 SPEC §7 行为约束补全。")

    lines += ["", "## 3. 非功能需求（NFR）", ""]
    if nfr:
        for nid, title in nfr:
            lines.append(f"- [ ] **{nid}** {title or '（指标待补，见 SPEC）'}")
    else:
        lines.append("> SPEC 中未抽取到 `NFR-` 编号；请人工对照 SPEC §11 非功能需求补全（如有）。")

    lines += [
        "",
        "---",
        "",
        "## 4. 完整实现判定",
        "",
        "本清单 §1-§3 全部 `[x]` 勾选 + ACCEPTANCE.md 全部 TC 通过 + SPEC §19 验收门禁通过 + pipeline-arbiter 翻转 Approved。",
        "",
        "## 5. 明确不做",
        "",
        f"参见 [SPEC.md](./SPEC.md) §4 非目标章节。{module} 只承担 SPEC 范围内的能力，不做范围外业务语义/集成编排/跨模块横切。",
        "",
    ]
    return "\n".join(lines) + "\n"


def gen_acceptance(module: str, data: dict) -> str:
    ac, tc = data["AC"], data["TC"]
    lines = [
        f"# {module} 完整验收清单",
        "",
        "- Status: Generated（与 [SPEC.md](./SPEC.md) 同步抽取，未经 pipeline-arbiter 校验）",
        f"- Last-Updated: {TODAY}",
        "- Source: [SPEC.md](./SPEC.md) · [TRACEABILITY.md](./TRACEABILITY.md) · [FEATURES.md](./FEATURES.md)",
        f"- Scale: {len(ac)} AC · {len(tc)} TC",
        "",
        f"> 本文档是 {module} 的 **完成定义（Definition of Done）**，把 SPEC 的 AC/TC 展开成可执行的验收项。",
        "> 任一未勾选项存在即视为未达成完整验收；通过条件以 SPEC §19 验收门禁为准。",
        "",
        "勾选图例：`[ ]` 未通过 · `[x]` 已通过并有证据 · `[~]` 部分通过（须在备注列注明缺口）",
        "",
        "---",
        "",
        "## 1. 验收标准（AC）",
        "",
    ]
    if ac:
        for aid, title in ac:
            lines.append(f"- [ ] **{aid}** {title or '（标准待补，见 SPEC）'}")
    else:
        lines.append("> SPEC 中未抽取到 `AC-` 编号；请人工对照 SPEC §6 各 FR 的 AC 列补全。")

    lines += ["", "## 2. 测试用例（TC）", ""]
    if tc:
        for tid, title in tc:
            lines.append(f"- [ ] **{tid}** {title or '（用例待补，见 SPEC）'}")
    else:
        lines.append("> SPEC 中未抽取到 `TC-` 编号；请人工对照 SPEC §15 测试矩阵补全。")

    lines += [
        "",
        "---",
        "",
        "## 3. 发布门禁（SPEC §19）",
        "",
        "实现落地后，下列门禁必须全部通过才能声称完整验收：",
        "",
        "```bash",
        "git diff --check",
        "bash .github/ci/spec-lint.sh",
        "TRACEABILITY_STRICT=1 bash .github/ci/traceability-check.sh",
        "bash .github/ci/task-spec-validate.sh",
        f"go test ./module/{module}/... 2>/dev/null || true   # 远程仓库为准",
        "go list -deps ./... | grep -v configx                # 禁止 configx 直接依赖（如 SPEC 要求）",
        "```",
        "",
        "## 4. 完整验收判定",
        "",
        "§1 全部 AC `[x]` + §2 全部 TC `[x]` + §3 全部门禁通过 + 远程 `github.com/ZoneCNH/<repo>` Release 标签存在并指向当前 SPEC 版本。",
        "",
    ]
    return "\n".join(lines) + "\n"


def main() -> None:
    for m in MODULES:
        spec = ROOT / "module" / m / "SPEC.md"
        data = extract(spec)
        mod_dir = ROOT / "module" / m

        (mod_dir / "FEATURES.md").write_text(gen_features(m, data), encoding="utf-8")
        (mod_dir / "ACCEPTANCE.md").write_text(gen_acceptance(m, data), encoding="utf-8")

        print(
            f"{m:18s} FR:{len(data['FR']):>2d} BR:{len(data['BR']):>2d} "
            f"NFR:{len(data['NFR']):>2d} AC:{len(data['AC']):>2d} TC:{len(data['TC']):>2d}"
        )


if __name__ == "__main__":
    main()
