#!/usr/bin/env python3
"""将 .worktree/binance.md 拆分为 module/binance/ 下的 35 个独立文件。"""

import re, os

REPO = "/home/workspace/ZoneCNH"
SRC = f"{REPO}/.worktree/binance.md"
DEST = f"{REPO}/module/binance"

def main():
    with open(SRC) as f:
        text = f.read()

    # 匹配所有 "## File: `path`" 区块
    # 每个区块从 "## File:" 开始，到下一个 "## File:" 或文档末尾
    pattern = re.compile(r'^## File: `([^`]+)`\s*\n(.*?)(?=^## File: `|^---$|\Z)', re.MULTILINE | re.DOTALL)

    count = 0
    for m in pattern.finditer(text):
        relpath = m.group(1)
        content = m.group(2).strip() + "\n"
        abspath = os.path.join(REPO, relpath)
        os.makedirs(os.path.dirname(abspath), exist_ok=True)
        with open(abspath, 'w') as f:
            f.write(content)
        print(f"  ✓ {relpath}")
        count += 1

    print(f"\n创建完成: {count} 个文件 → {DEST}/")

if __name__ == "__main__":
    main()
