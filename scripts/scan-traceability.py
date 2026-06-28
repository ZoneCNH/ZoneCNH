#!/usr/bin/env python3
"""Scan all module/*/TRACEABILITY.md files for Goal pipeline compliance."""

import glob, re, os, subprocess, sys

def scan_traceability(modules=None, verbose=False):
    """Return (issues, total_modules)."""
    issues = []
    total = 0

    pattern = 'module/*/TRACEABILITY.md'
    if modules:
        files = [f'module/{m}/TRACEABILITY.md' for m in modules]
    else:
        files = sorted(glob.glob(pattern))

    for f in files:
        if not os.path.exists(f):
            continue
        mod = os.path.basename(os.path.dirname(f))
        if mod.startswith('_'):
            continue
        total += 1

        with open(f) as fh:
            content = fh.read()

        mi = []
        for i in range(1, 8):
            if ('\xa7' + str(i)) not in content:
                mi.append('S' + str(i))

        if content.count('业务规则追溯') > 1:
            mi.append('DUP-S2')

        lu = re.search(r'Last-Updated:\s*(\S+)', content)
        if not lu:
            mi.append('NO-DATE')
        elif lu.group(1) != '2026-06-29':
            mi.append('DATE=' + lu.group(1))

        s6 = content.find('\n## \xa76')
        if s6 > 0 and '| Done ' not in content[s6:s6+800]:
            mi.append('S6-FMT')

        # Check Task column: accepts "Task" or "任务锚点" (contracts convention)
        first_3k = content[:3000]
        if '| Task ' not in first_3k and '任务锚点' not in first_3k:
            mi.append('NO-TASK')

        if mi:
            issues.append((mod, mi))

    return issues, total


if __name__ == '__main__':
    import argparse
    p = argparse.ArgumentParser(description='Scan TRACEABILITY.md for Goal pipeline compliance')
    p.add_argument('modules', nargs='*', help='specific modules to scan (default: all)')
    p.add_argument('--verbose', '-v', action='store_true')
    p.add_argument('--json', action='store_true', help='output as JSON')
    args = p.parse_args()

    issues, total = scan_traceability(args.modules, args.verbose)

    if args.json:
        import json
        print(json.dumps({
            'total': total,
            'issues': len(issues),
            'details': [{'module': m, 'issues': i} for m, i in issues]
        }, indent=2))
    else:
        print(f'Total: {total}, Issues: {len(issues)}')
        for mod, mi in sorted(issues):
            print(f'  {mod}: {",".join(mi)}')
        if not issues:
            print('ALL CLEAN')

    sys.exit(0 if not issues else 1)
