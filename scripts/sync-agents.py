#!/usr/bin/env python3
"""Detect agent definition drift across the Claude, Codex, and Copilot platforms.

Scans the three mirrored agent directories (.claude/agents, .codex/agents,
.copilot/agents), extracts each agent's canonical name from its platform-specific
format, and reports any divergence in agent set across platforms.

Exit code:
  0 = no drift (all three platforms expose the same agent set)
  1 = drift detected (agent count or names diverge across platforms)
"""

import argparse
import json
import re
import sys
from pathlib import Path

PLATFORMS = {
    ".claude": {"dir": ".claude/agents", "ext": ".md"},
    ".codex": {"dir": ".codex/agents", "ext": ".toml"},
    ".copilot": {"dir": ".copilot/agents", "ext": ".md"},
}

NAME_RE_MD = re.compile(r"^name:\s*(.+?)\s*$")
NAME_RE_TOML = re.compile(r'^name\s*=\s*"([^"]+)"\s*$')


def extract_name_md(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as fh:
            for _ in range(20):
                line = fh.readline()
                if not line:
                    break
                match = NAME_RE_MD.match(line)
                if match:
                    return match.group(1).strip().strip('"').strip("'")
    except OSError:
        pass
    return file_path.stem


def extract_name_toml(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as fh:
            for line in fh:
                match = NAME_RE_TOML.match(line)
                if match:
                    return match.group(1).strip()
    except OSError:
        pass
    return file_path.stem


def scan_platform(root, platform):
    spec = PLATFORMS[platform]
    agents_dir = root / spec["dir"]
    names = set()
    if not agents_dir.is_dir():
        return names
    for fp in sorted(agents_dir.glob(f"*{spec['ext']}")):
        if spec["ext"] == ".toml":
            names.add(extract_name_toml(fp))
        else:
            names.add(extract_name_md(fp))
    return names


def build_report(root, source):
    platform_agents = {p: scan_platform(root, p) for p in PLATFORMS}
    counts = {p: len(a) for p, a in platform_agents.items()}
    if all(platform_agents.values()):
        common = set.intersection(*platform_agents.values())
    else:
        common = set()
    source_set = platform_agents[source]

    drift = {}
    for platform, agents in platform_agents.items():
        if platform == source:
            continue
        missing = source_set - agents
        extra = agents - source_set
        if missing or extra:
            drift[platform] = {"missing": sorted(missing), "extra": sorted(extra)}

    only_one = {}
    all_names = set().union(*platform_agents.values())
    for name in sorted(all_names):
        present_in = [p for p, a in platform_agents.items() if name in a]
        if len(present_in) == 1:
            only_one[name] = present_in[0]

    sets_equal = (
        platform_agents[".claude"]
        == platform_agents[".codex"]
        == platform_agents[".copilot"]
    )
    has_drift = not sets_equal

    return {
        "root": str(root),
        "source": source,
        "counts": counts,
        "common_count": len(common),
        "drift": drift,
        "only_one_platform": only_one,
        "has_drift": has_drift,
    }


def print_text(report):
    source = report["source"]
    print(f"Agent drift check (source={source})")
    print(f"root: {report['root']}")
    for platform in PLATFORMS:
        print(f"  {platform}: {report['counts'][platform]} agents")
    print(f"  common (all three): {report['common_count']}")

    only_one = report["only_one_platform"]
    if only_one:
        print("\n仅在单一平台存在的 agent:")
        for name, platform in only_one.items():
            print(f"  {name} -> {platform}")

    drift = report["drift"]
    if drift:
        print(f"\n相对基准源 {source} 的漂移:")
        for platform, diff in drift.items():
            if diff["missing"]:
                print(f"  {platform} 缺失: {', '.join(diff['missing'])}")
            if diff["extra"]:
                print(f"  {platform} 多出: {', '.join(diff['extra'])}")

    if report["has_drift"]:
        print("\n发现漂移: 三平台 agent 不一致")
    else:
        print("\n无漂移: 三平台 agent 一致")


def main():
    parser = argparse.ArgumentParser(
        description="Detect agent drift across Claude, Codex, and Copilot platforms."
    )
    parser.add_argument(
        "--root", default=None, help="Repository root (auto-detected if omitted)"
    )
    parser.add_argument(
        "--source",
        default=".claude",
        choices=list(PLATFORMS.keys()),
        help="Baseline platform for missing/extra reporting (default: .claude)",
    )
    parser.add_argument(
        "--json",
        dest="as_json",
        action="store_true",
        help="Emit a JSON report instead of human-readable text",
    )
    args = parser.parse_args()

    if args.root:
        root = Path(args.root).resolve()
    else:
        root = Path(__file__).resolve().parent.parent

    if not root.is_dir():
        print(f"sync-agents: root directory not found: {root}", file=sys.stderr)
        sys.exit(2)

    report = build_report(root, args.source)

    if args.as_json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print_text(report)

    sys.exit(1 if report["has_drift"] else 0)


if __name__ == "__main__":
    main()
