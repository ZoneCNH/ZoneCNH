#!/usr/bin/env python3
"""audit-status.py — Cross-document consistency checker for STATUS.md / README.md / ARCHITECTURE.md

Checks: table counts vs domain stats, dashboard vs totals, sync table vs grep, version counts,
stale references, domain-sum arithmetic, optional 404 scan.

Usage: python3 scripts/audit-status.py [--network]
Exit: 0 = PASS, 1 = FAIL
"""
import re, sys, os, subprocess, json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PASS, FAIL, TOTAL = 0, 0, 0
NETWORK = "--network" in sys.argv

GREEN = "\033[32m"; RED = "\033[31m"; NC = "\033[0m"
def ok(msg): global PASS, TOTAL; PASS += 1; TOTAL += 1; print(f"  {GREEN}PASS{NC} {msg}")
def no(msg): global FAIL, TOTAL; FAIL += 1; TOTAL += 1; print(f"  {RED}FAIL{NC} {msg}")
def chk(label, a, b):
    if str(a) == str(b): ok(f"{label}: {a} == {b}")
    else: no(f"{label}: {a} != {b}")

def read(path): return (ROOT / path).read_text()

def unique_repos(text):
    return len(set(re.findall(r'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+', text)))

def parse_domain_stats(text):
    """Parse the 按域统计 table, return dict {domain: {total, existing, created, progress, versioned}} and totals row."""
    in_table = False
    rows = {}
    totals = {}
    for line in text.splitlines():
        if "按域统计" in line:
            in_table = True
            continue
        if in_table and line.startswith("|---"):
            continue
        if in_table and line.startswith("|"):
            parts = [p.strip() for p in line.split("|")]
            if len(parts) < 7:
                continue
            # parts: ['', domain, total, existing, created, progress, versioned, '']
            domain = parts[1].replace("*", "").strip()
            total = parts[2].replace("*", "").strip()
            existing = parts[3].replace("*", "").strip()
            created = parts[4].replace("*", "").strip()
            progress = parts[5].replace("*", "").replace("%", "").strip()
            versioned = parts[6].replace("*", "").strip()
            if domain == "合计":
                totals = {"total": total, "existing": existing, "created": created,
                          "progress": progress, "versioned": versioned}
            elif domain:
                rows[domain] = {"total": total, "existing": existing, "created": created,
                                "progress": progress, "versioned": versioned}
        elif in_table and not line.startswith("|"):
            break
    return rows, totals

def count_github_in_section(text, start_heading, end_heading=None):
    """Count github.com links between two markdown headings."""
    lines = text.splitlines()
    counting = False
    count = 0
    for line in lines:
        if line.startswith(start_heading):
            counting = True
            continue
        if end_heading and line.startswith(end_heading):
            break
        if counting and "github.com" in line:
            count += 1
    return count

def parse_sync_table(text):
    """Parse the 文档同步检查 table, return list of {check, readme, arch, status}."""
    in_table = False
    rows = []
    for line in text.splitlines():
        if "文档同步检查" in line:
            in_table = True
            continue
        if in_table and "|" in line and not line.startswith("|---") and not line.startswith("| -"):
            parts = [p.strip() for p in line.split("|")]
            if len(parts) >= 5:
                check = parts[1]
                readme = parts[2]
                arch = parts[3]
                status = parts[4]
                if check and check != "检查项":
                    rows.append({"check": check, "readme": readme, "arch": arch, "status": status})
        elif in_table and not line.startswith("|"):
            break
    return rows

def parse_dashboard(text):
    """Extract dashboard counters from the ASCII-art block."""
    m = re.search(r'组件总数:\s*(\d+)\s+已有:\s*(\d+)\s+已创建:\s*(\d+)\s+平均进度:\s*(\d+)%', text)
    if m:
        return {"total": m.group(1), "existing": m.group(2), "created": m.group(3), "progress": m.group(4)}
    return {}

def count_base_versions(text):
    """Count non-empty, non-dash version fields in base component table."""
    in_base = False
    count = 0
    for line in text.splitlines():
        if line.startswith("### 基座"):
            in_base = True
            continue
        if in_base and line.startswith("###"):
            break
        if in_base and "github.com" in line:
            parts = [p.strip() for p in line.split("|")]
            if len(parts) >= 4:
                ver = parts[2]  # version is column index 2 (0=empty, 1=name, 2=version)
                if ver and ver != "-":
                    count += 1
    return count

def count_sdk_provider(text):
    """Count SDK and Provider rows in the 数据域·行情 section."""
    sdk = 0; prov = 0
    in_market = False
    for line in text.splitlines():
        if line.startswith("### 数据域 · 行情"):
            in_market = True; continue
        if in_market and line.startswith("### 数据域 · 宏观"):
            break
        if in_market and "github.com" in line:
            if "SDK" in line: sdk += 1
            elif "Provider" in line: prov += 1
    return sdk, prov

# ── Load documents ──────────────────────────────────────────
status = read("STATUS.md")
readme = read("README.md")
arch = read("ARCHITECTURE.md")

print("=== audit-status.py ===")
print()

# ── 1. Table row counts vs domain stats ────────────────────
print("--- 1. Table row counts vs domain stats ---")
rows, totals = parse_domain_stats(status)

# Map domain stats keys to table counts
BASE = count_github_in_section(status, "### 基座", "### L2.5")
L25 = count_github_in_section(status, "### L2.5", "### 数据域")
SDK, PROV = count_sdk_provider(status)
MACRO = count_github_in_section(status, "### 数据域 · 宏观", "### 数据域 · 另类")
ALT = count_github_in_section(status, "### 数据域 · 另类", "### 分析域")
ANALYSIS = count_github_in_section(status, "### 分析域", "### 决策域")
DECISION = count_github_in_section(status, "### 决策域", "### 执行域")
EXECUTION = count_github_in_section(status, "### 执行域", "### 入口")

def ds_total(domain_key):
    return rows.get(domain_key, {}).get("total", "?")

chk("Base",      BASE,      ds_total("基座"))
chk("L2.5",      L25,       ds_total("L2.5 领域共享层"))
chk("SDK",       SDK,       ds_total("数据域 · 行情 SDK"))
chk("Provider",  PROV,      ds_total("数据域 · 行情 Provider"))
chk("Macro",     MACRO,     ds_total("数据域 · 宏观"))
chk("Alt",       ALT,       ds_total("数据域 · 另类"))
chk("Analysis",  ANALYSIS,  ds_total("分析域"))
chk("Decision",  DECISION,  ds_total("决策域"))
chk("Execution", EXECUTION, ds_total("执行域"))

# ── 2. Dashboard vs totals ─────────────────────────────────
print("\n--- 2. Dashboard vs domain stats totals ---")
dash = parse_dashboard(status)
chk("Total",    dash.get("total"),    totals["total"])
chk("Existing", dash.get("existing"), totals["existing"])
chk("Created",  dash.get("created"),  totals["created"])
chk("Progress", dash.get("progress") + "%", totals["progress"] + "%")

# ── 3. Sync table vs actual unique repos ───────────────────
print("\n--- 3. Sync check table vs actual unique repos ---")
sync_rows = parse_sync_table(status)
sync_total = next((r for r in sync_rows if "组件总数" in r["check"]), None)

ru = unique_repos(readme)
au = unique_repos(arch)
su = unique_repos(status)

if sync_total:
    chk("README",  str(ru), sync_total["readme"])
    chk("ARCH",    str(au), sync_total["arch"])
    diff = abs(su - int(sync_total["status"]))
    if diff <= 2:
        ok(f"STATUS: actual={su} sync-table={sync_total['status']} (diff={diff}, OK)")
    else:
        no(f"STATUS: actual={su} sync-table={sync_total['status']} (diff={diff})")
else:
    no("Sync table 组件总数 row not found")

# ── 4. Base version count ──────────────────────────────────
print("\n--- 4. Base version count ---")
bv = count_base_versions(status)
ds_bv = rows.get("基座", {}).get("versioned", "?")
ds_bv_num = re.match(r'\d+', ds_bv)
ds_bv_num = ds_bv_num.group(0) if ds_bv_num else ds_bv
chk("BaseVer", str(bv), ds_bv_num)

# ── 5. Stale references ────────────────────────────────────
print("\n--- 5. Stale references ---")
all_text = status + "\n" + readme + "\n" + arch
strat_lines = [l for l in all_text.splitlines() if "strategies" in l.lower() and "strategyx" not in l.lower()]
if strat_lines:
    no(f"{len(strat_lines)} stale 'strategies' references")
    for l in strat_lines[:5]: print(f"    {l.strip()[:80]}")
else:
    ok("No stale 'strategies' references")

# ── 6. Domain-sum arithmetic ────────────────────────────────
print("\n--- 6. Domain-sum row sums ---")
st = sum(int(r["total"]) for r in rows.values())
se = sum(int(r["existing"]) for r in rows.values())
sc = sum(int(r["created"]) for r in rows.values())
chk("DomainSumTotal",    str(st), totals["total"])
chk("DomainSumExisting", str(se), totals["existing"])
chk("DomainSumCreated",  str(sc), totals["created"])

# ── 7. 404 check (optional) ─────────────────────────────────
print("\n--- 7. 404 check ---")
if NETWORK:
    repos = set(re.findall(r'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+', status + readme + arch))
    found_404 = 0
    for url in sorted(repos):
        repo_name = url.split("/")[-1]
        try:
            r = subprocess.run(["gh", "api", f"repos/ZoneCNH/{repo_name}"],
                             capture_output=True, text=True, timeout=10)
            if "Not Found" in r.stdout:
                no(f"404: {repo_name}")
                found_404 += 1
        except Exception:
            pass
    if found_404 == 0:
        ok(f"No 404 links ({len(repos)} repos checked)")
else:
    print("  SKIPPED (use --network for full 404 scan)")

# ── Summary ─────────────────────────────────────────────────
print(f"\n{'='*42}")
print(f"Results: {GREEN}{PASS} passed{NC} / {RED}{FAIL} failed{NC} / {TOTAL} total")
print(f"{'='*42}")

sys.exit(0 if FAIL == 0 else 1)
