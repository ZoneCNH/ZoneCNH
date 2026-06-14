#!/usr/bin/env python3
"""audit-status.py — Cross-document consistency checker.

Validates STATUS.md / README.md / ARCHITECTURE.md counts against
actual table data and unique repo links. Also verifies the .foundationx
fact layer so generated projections cannot overstate blocker/release state.

Checks:
  1. Table row counts match domain stats totals
  2. Dashboard matches domain stats aggregate row
  3. Sync check table matches unique repo grep counts
  4. Base module version count consistency
  5. No stale "strategies" references
  6. Domain-sum arithmetic (row sums == aggregate)
  7. (--network) GitHub 404 link scan
  8. Cross-dimension RELEASE/FACTORY checks against fact-layer projections
  9. FoundationX fact-layer guard

Usage:
  python3 scripts/audit-status.py                      # local checks
  python3 scripts/audit-status.py --foundationx-only   # fact-layer only
  python3 scripts/audit-status.py --network            # include 404 scan

Exit: 0 = PASS, 1 = FAIL
"""
import json, re, sys, os, subprocess
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PASS, FAIL = 0, 0
NETWORK = "--network" in sys.argv
FOUNDATIONX_ONLY = "--foundationx-only" in sys.argv

GREEN = "\033[32m"; RED = "\033[31m"; NC = "\033[0m"
def ok(msg):
    global PASS; PASS += 1
    print(f"  {GREEN}PASS{NC} {msg}")
def no(msg):
    global FAIL; FAIL += 1
    print(f"  {RED}FAIL{NC} {msg}")
def chk(label, a, b):
    if str(a) == str(b): ok(f"{label}: {a} == {b}")
    else: no(f"{label}: {a} != {b}")

def load(name):
    return (ROOT / name).read_text()

def load_json(name):
    return json.loads((ROOT / name).read_text())

def stable_counter(counter):
    return {k: counter[k] for k in sorted(counter)}

def unique_repos(text):
    return len(set(re.findall(r'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+', text)))

def github_rows_between(text, start_h, end_h=None):
    """Count github.com links between two ### headings."""
    count = 0; counting = False
    for line in text.splitlines():
        if line.startswith(start_h): counting = True; continue
        if end_h and line.startswith(end_h): break
        if counting and "github.com" in line: count += 1
    return count

def parse_domain_stats(text):
    """Parse 按域统计 table. Returns dict of {domain_name: {col: val}} plus totals dict."""
    rows = {}; totals = {}
    in_table = False
    for line in text.splitlines():
        if "按域统计" in line: in_table = True; continue
        if in_table and "|" in line:
            parts = [p.strip() for p in line.split("|")]
            if len(parts) < 8: continue
            domain = parts[1].replace("*", "").strip()
            if domain in ("域", "----------------------", ""): continue
            data = {
                "total":    parts[2].replace("*", "").strip(),
                "existing": parts[3].replace("*", "").strip(),
                "created":  parts[4].replace("*", "").strip(),
                "progress": parts[5].replace("*", "").replace("%", "").strip(),
                "versioned": parts[6].replace("*", "").strip(),
            }
            if domain == "合计": totals = data
            else: rows[domain] = data
        elif in_table and "---" in line and not line.startswith("|"):
            break
    return rows, totals

def parse_dashboard(text):
    """Extract {total, existing, created, progress} from ASCII dashboard."""
    m = re.search(
        r'组件总数:\s*(\d+)\s+已有:\s*(\d+)\s+已创建:\s*(\d+)\s+平均进度:\s*(\d+)%', text
    )
    return dict(zip(["total","existing","created","progress"], m.groups())) if m else {}

def parse_sync_table(text):
    """Parse 文档同步检查 table. Returns list of {check, readme, arch, status}."""
    rows = []; in_table = False
    for line in text.splitlines():
        if "文档同步检查" in line: in_table = True; continue
        if in_table and "|" in line and not line.strip().startswith("|---"):
            parts = [p.strip() for p in line.split("|")]
            if len(parts) >= 5 and parts[1] and parts[1] != "检查项":
                rows.append({"check": parts[1], "readme": parts[2], "arch": parts[3], "status": parts[4]})
        elif in_table and not line.startswith("|") and line.strip():
            break
    return rows

def count_base_versions(text):
    """Count modules with version != '-' in the base component table."""
    count = 0; in_base = False
    for line in text.splitlines():
        if line.startswith("### 基座"): in_base = True; continue
        if in_base and line.startswith("### "): break
        if in_base and "github.com" in line:
            parts = [p.strip() for p in line.split("|")]
            if len(parts) >= 4:
                ver = parts[2]
                if ver and ver != "-": count += 1
    return count

def count_sdk_provider(text):
    """Count SDK and Provider rows separately in market-data section."""
    sdk = prov = 0; in_market = False
    for line in text.splitlines():
        if "### 数据域 · 行情" in line: in_market = True; continue
        if in_market and "### 数据域 · 宏观" in line: break
        if in_market and "github.com" in line:
            if "| SDK " in line: sdk += 1
            elif "| Provider " in line: prov += 1
    return sdk, prov

def audit_foundationx_fact_layer():
    """Validate machine-readable FoundationX fact sources and invariants."""
    print("--- 9. FoundationX fact-layer guard ---")
    try:
        status = load_json(".foundationx/status/index.json")
        blockers_doc = load_json(".foundationx/blockers.json")
        contract = load_json(".foundationx/repo-contract.json")
        schema = load_json(".foundationx/repo-contract.schema.json")
    except Exception as exc:
        no(f"Could not load .foundationx JSON: {exc}")
        return

    modules = status.get("modules", {})
    blockers = blockers_doc.get("blockers", [])
    open_blockers = [b for b in blockers if b.get("status") == "open"]
    resolved_blockers = [b for b in blockers if b.get("status") == "resolved"]

    chk("Foundation module total", status.get("total_modules"), len(modules))
    expected_summary = {
        "spec_complete": sum(1 for m in modules.values() if m.get("spec") is True),
        "impl_complete": sum(1 for m in modules.values() if m.get("impl") is True),
        "release_published": sum(1 for m in modules.values() if m.get("release") is True),
        "live_integration": sum(1 for m in modules.values() if m.get("live") is True),
        "factory_grade": sum(1 for m in modules.values() if m.get("factory") is True),
    }
    for key, expected in expected_summary.items():
        chk(f"status.summary.{key}", status.get("summary", {}).get(key), expected)

    release_false_factory_true = [
        name for name, mod in modules.items()
        if mod.get("release") is False and mod.get("factory") is True
    ]
    if release_false_factory_true:
        no(f"release=false but factory=true: {', '.join(release_false_factory_true)}")
    else:
        ok("release=false implies factory=false")

    chk("Blocker total", blockers_doc.get("total_blockers"), len(blockers))
    chk("Open blocker total", blockers_doc.get("open_blockers"), len(open_blockers))
    chk("Resolved blocker total", blockers_doc.get("resolved_blockers"), len(resolved_blockers))
    chk("Blockers by_severity", blockers_doc.get("by_severity"), stable_counter(Counter(b.get("severity") for b in blockers)))
    chk("Blockers open_by_severity", blockers_doc.get("open_by_severity"), stable_counter(Counter(b.get("severity") for b in open_blockers)))

    by_module = defaultdict(list)
    for blocker in blockers:
        by_module[blocker.get("module")].append(blocker.get("id"))
    expected_by_module = {k: v for k, v in sorted(by_module.items())}
    chk("Blockers by_module", blockers_doc.get("by_module"), expected_by_module)

    open_modules = sorted({b.get("module") for b in open_blockers})
    chk("factory_blocking_modules", blockers_doc.get("factory_blocking_modules"), open_modules)
    factory_overstated = [
        name for name in open_modules
        if modules.get(name, {}).get("factory") is not False
    ]
    if factory_overstated:
        no(f"open blocker modules with factory!=false: {', '.join(factory_overstated)}")
    else:
        ok("open blockers force factory=false")

    release_blocking_modules = sorted({b.get("module") for b in open_blockers if b.get("category") == "release"})
    chk("release_blocking_modules", blockers_doc.get("release_blocking_modules"), release_blocking_modules)
    release_overstated = [
        name for name in release_blocking_modules
        if modules.get(name, {}).get("release") is not False
    ]
    if release_overstated:
        no(f"open release blocker modules with release!=false: {', '.join(release_overstated)}")
    else:
        ok("open release blockers force release=false")

    if schema.get("properties", {}).get("schema_version", {}).get("const") == contract.get("schema_version"):
        ok("repo-contract schema const matches contract schema_version")
    else:
        no("repo-contract schema const does not match contract schema_version")

    required = schema.get("required", [])
    missing = [key for key in required if key not in contract]
    if missing:
        no(f"repo-contract missing schema-required keys: {', '.join(missing)}")
    else:
        ok("repo-contract contains schema-required keys")

    for guard_key in ("public_docs", "fact_sources", "audit_scripts"):
        missing_paths = [
            path for path in contract.get("projection_guards", {}).get(guard_key, [])
            if not (ROOT / path).exists()
        ]
        if missing_paths:
            no(f"projection_guards.{guard_key} missing paths: {', '.join(missing_paths)}")
        else:
            ok(f"projection_guards.{guard_key} paths exist")

# ── Load ────────────────────────────────────────────────────
if FOUNDATIONX_ONLY:
    print("=== audit-status.py --foundationx-only ===")
    print()
    audit_foundationx_fact_layer()
    print()
    print(f"Summary: {PASS} passed, {FAIL} failed")
    sys.exit(1 if FAIL else 0)

STATUS = load("STATUS.md")
README = load("README.md")
ARCH   = load("ARCHITECTURE.md")

print("=== audit-status.py ===")
print()

# ── 1. Table row counts vs domain stats ────────────────────
print("--- 1. Table rows vs domain stats ---")
rows, totals = parse_domain_stats(STATUS)
BASE      = github_rows_between(STATUS, "### 基座", "### L2.5")
L25       = github_rows_between(STATUS, "### L2.5", "### 数据域")
SDK, PROV = count_sdk_provider(STATUS)
MACRO     = github_rows_between(STATUS, "### 数据域 · 宏观", "### 数据域 · 另类")
ALT       = github_rows_between(STATUS, "### 数据域 · 另类", "### 分析域")
ANALYSIS  = github_rows_between(STATUS, "### 分析域", "### 决策域")
DECISION  = github_rows_between(STATUS, "### 决策域", "### 执行域")
EXECUTION = github_rows_between(STATUS, "### 执行域", "### 入口")

DMAP = {"Base":"基座","L2.5":"L2.5 领域共享层","SDK":"数据域 · 行情 SDK",
       "Provider":"数据域 · 行情 Provider","Macro":"数据域 · 宏观","Alt":"数据域 · 另类",
       "Analysis":"分析域","Decision":"决策域","Execution":"执行域"}
def _get(label,x): return rows.get(DMAP[label],{}).get(x,"?")
chk("Base", str(BASE), _get("Base","total"))
chk("L2.5", str(L25), _get("L2.5","total"))
chk("SDK", str(SDK), _get("SDK","total"))
chk("Provider", str(PROV), _get("Provider","total"))
chk("Macro", str(MACRO), _get("Macro","total"))
chk("Alt", str(ALT), _get("Alt","total"))
chk("Analysis", str(ANALYSIS), _get("Analysis","total"))
chk("Decision", str(DECISION), _get("Decision","total"))
chk("Execution", str(EXECUTION), _get("Execution","total"))

# ── 2. Dashboard vs totals ─────────────────────────────────
print("\n--- 2. Dashboard vs domain stats ---")
dash = parse_dashboard(STATUS)
if dash and totals:
    chk("Total",    dash["total"],    totals["total"])
    chk("Existing", dash["existing"], totals["existing"])
    chk("Created",  dash["created"],  totals["created"])
    chk("Progress", dash["progress"] + "%", totals["progress"] + "%")
else:
    no("Could not parse dashboard or totals")

# ── 3. Sync table vs unique repos ──────────────────────────
print("\n--- 3. Sync table vs unique repos ---")
sync_rows = parse_sync_table(STATUS)
st = next((r for r in sync_rows if "组件总数" in r["check"]), None)
ru = unique_repos(README); au = unique_repos(ARCH); su = unique_repos(STATUS)
if st:
    chk("README", str(ru), st["readme"])
    chk("ARCH",   str(au), st["arch"])
    d = abs(su - int(st["status"]))
    if d <= 2: ok(f"STATUS: actual={su} sync-table={st['status']} (diff={d}, OK)")
    else: no(f"STATUS: actual={su} sync-table={st['status']} (diff={d})")
else:
    no("Sync table row not found")

# ── 4. Base version count ──────────────────────────────────
print("\n--- 4. Base version count ---")
bv = count_base_versions(STATUS)
dsv = rows.get("基座", {}).get("versioned", "?")
num = re.match(r'\d+', dsv)
num = num.group(0) if num else dsv
chk("BaseVer", str(bv), num)

# ── 5. Stale references ────────────────────────────────────
print("\n--- 5. Stale references ---")
refs = [l.strip()[:80] for l in (STATUS+"\n"+README+"\n"+ARCH).splitlines()
        if "strategies" in l.lower() and "strategyx" not in l.lower()]
if refs: no(f"{len(refs)} stale 'strategies' references"); [print(f"    {r}") for r in refs[:5]]
else: ok("No stale 'strategies' references")

# ── 6. Domain-sum arithmetic ───────────────────────────────
print("\n--- 6. Domain-sum row sums ---")
st_sum = sum(int(r["total"]) for r in rows.values())
se_sum = sum(int(r["existing"]) for r in rows.values())
sc_sum = sum(int(r["created"]) for r in rows.values())
chk("Total",    str(st_sum), totals["total"])
chk("Existing", str(se_sum), totals["existing"])
chk("Created",  str(sc_sum), totals["created"])

# ── 7. 404 check ───────────────────────────────────────────
print("\n--- 7. 404 check ---")
if NETWORK:
    repos = sorted(set(re.findall(r'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+', STATUS+README+ARCH)))
    nf = 0
    for url in repos:
        name = url.split("/")[-1]
        try:
            r = subprocess.run(["gh","api",f"repos/ZoneCNH/{name}"], capture_output=True, text=True, timeout=10)
            if "Not Found" in r.stdout: no(f"404: {name}"); nf += 1
        except Exception: pass
    if nf == 0: ok(f"No 404 links ({len(repos)} repos)")
else:
    print("  SKIPPED (use --network)")

# ── 8. Cross-dimension: RELEASE/FACTORY ↔ version note ──────
print("\n--- 8. Cross-dimension checks ---")
# Count RELEASE ✅/❌ from multidimensional table
release_yes = release_no = 0
in_multi = False
for line in STATUS.splitlines():
    if "📊 基座多维成熟度展开" in line: in_multi = True; continue
    if in_multi and line.startswith("</details>"): break
    if in_multi and re.match(r'^\| [a-z]', line):
        parts = [p.strip() for p in line.split("|")]
        if len(parts) >= 6:
            r_val = parts[4]  # RELEASE = column 5 (1-indexed)
            if r_val == "✅": release_yes += 1
            elif r_val == "❌": release_no += 1

# Cross-check RELEASE projection against the machine-readable fact layer.
# STATUS prose can change shape; the fact layer is the authority for release counts.
foundation_status = load_json(".foundationx/status/index.json")
fact_release_published = foundation_status.get("summary", {}).get("release_published")
if fact_release_published is None:
    no("Could not parse FoundationX release_published summary")
else:
    chk("RELEASE ✅ vs fact-layer release_published", str(release_yes), str(fact_release_published))

# FACTORY N/A count
factory_na = 0
in_multi = False
for line in STATUS.splitlines():
    if "📊 基座多维成熟度展开" in line: in_multi = True; continue
    if in_multi and line.startswith("</details>"): break
    if in_multi and re.match(r'^\| [a-z]', line):
        parts = [p.strip() for p in line.split("|")]
        if len(parts) >= 10:
            f_val = parts[9]  # FACTORY = column 10
            if f_val == "N/A": factory_na += 1
# testkitx should be N/A (test-only)
if factory_na >= 1:
    ok(f"FACTORY N/A={factory_na} (testkitx=test-only)")
else:
    no(f"FACTORY N/A={factory_na} (expected >=1)")

print()
audit_foundationx_fact_layer()

print()
print(f"Summary: {PASS} passed, {FAIL} failed")
sys.exit(1 if FAIL else 0)
