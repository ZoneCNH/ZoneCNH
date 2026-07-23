# 治理裁决 RULING-003: contracts 版本

**裁决日期**: 2026-07-11
**裁决编号**: RULING-003
**裁决者**: FoundationX Governance
**状态**: FINAL (lineage 审计已完成)

## 背景

contracts 当前 tag v1.5.0，但 main 代码/README 锚点不一致。分析报告 §2.2 矛盾 3（行 L772-774）引述原始计划建议：

> "若 v1.5.0 tag 内容不能代表当前 main 的合法祖先，禁止直接发布 v1.5.1；很可能需要明确迁移后发布 v2"

这是一个非裁决 — uncertainty 传播到所有消费者的版本图。contracts 的版本不确定性影响联合验证矩阵 MARKET-CONTRACT 和所有依赖 contracts 接口的模块。

## 裁决: v0.5.3

> **裁决日期**: 2026-07-11
> **审计详情**: 见 `p0-3-lineage-audit-result.md`
> **状态更新原因**: lineage 审计发现 v1.5.0 tag 不存在，实际最新版本为 v0.5.2。

### 裁决基于以下审计事实

1. **v1.5.0 是 phantom tag** — contracts 仓库中从未存在 v1.5.0 tag。原始分析报告 §2.2 的前提"当前 tag v1.5.0"是错误声明。
2. **最新合法祖先**: v0.5.2 (45cabadc4037189be91833daf72b3c087137ad59)
3. **main 领先 v0.5.2 2 个提交** — 均为 CI runner 配置变更（无功能变更）
4. **版本链完整**: v0.4.7 → v0.5.0 → v0.5.1 → v0.5.2，所有版本 tag 均为 main 合法祖先

### 裁决逻辑（对照规则表）

| 裁决表行 | 是否匹配 | 原因 |
|---------|---------|------|
| v1.5.0 是 main 合法祖先 → v1.5.1 | 否 | v1.5.0 不存在 |
| v1.5.0 孤儿，最新合法=v0.4.0 → v2.0.0 | 否 | 最新合法=v0.5.2 非 v0.4.0 |
| v1.5.0 孤儿，最新合法=v1.3.0 → v1.4.0+retract | 否 | 最新合法=v0.5.2 非 v1.3.0 |
| 无合法祖先 tag → v1.0.0 | 否 | 有 v0.4.7~v0.5.2 完整祖先链 |

**实际裁决**: 不匹配四场景中任何一个 → 等价于"最新合法 v0.5.2，正常 patch 递增" → **v0.5.3**。无需 retract（不存在 v1.5.0 需要 retract）。

## 审计方法

### 前置条件

contracts 仓库可访问且 `git` 命令可用。审计脚本定义如下：

```bash
#!/bin/bash
# contracts-lineage-audit.sh
# 用途: 审计 contracts 仓库的 git tag 与 main 分支的祖先关系

REPO="/home/workspace/contracts"
cd "$REPO" || exit 1

echo "=== contracts lineage audit ==="
echo ""

# 1. 列出所有 tag 及对应的 commit
echo "--- all tags ---"
git tag --sort=-creatordate | while read tag; do
  tag_sha=$(git rev-list -n1 "$tag" 2>/dev/null || echo "MISSING")
  echo "$tag -> $tag_sha"
done

echo ""

# 2. 检查每个 tag 是否在 main 的祖先链上
echo "--- ancestor check ---"
MAIN_HEAD=$(git rev-parse main)
for tag in $(git tag --sort=-creatordate); do
  tag_sha=$(git rev-list -n1 "$tag" 2>/dev/null || echo "")
  if [ -z "$tag_sha" ]; then
    echo "ORPHAN: $tag — tag points to nonexistent commit"
    continue
  fi
  if git merge-base --is-ancestor "$tag_sha" "$MAIN_HEAD" 2>/dev/null; then
    echo "ANCESTOR: $tag ($tag_sha) is ancestor of main ($MAIN_HEAD)"
  else
    echo "ORPHAN: $tag ($tag_sha) is NOT ancestor of main ($MAIN_HEAD)"
  fi
done

echo ""

# 3. 找 main 祖先链上最大的合法 tag
echo "--- latest valid ancestor tag ---"
for tag in $(git tag --sort=-version:refname); do
  tag_sha=$(git rev-list -n1 "$tag" 2>/dev/null || echo "")
  if [ -n "$tag_sha" ] && git merge-base --is-ancestor "$tag_sha" "$MAIN_HEAD" 2>/dev/null; then
    echo "LATEST_VALID: $tag ($tag_sha)"
    break
  fi
done
```

### 执行状态: 已完成

审计已执行，结果见附录 A。裁决交由 FoundationX Governance 生产环境实施。

**实施步骤**：
1. 确认 contracts 仓库 `main` 指向 27322038e71eb2c0f9955f0dc0adf87c431fbdf8
2. 更新 VERSION 文件为 v0.5.3（如有）
3. 追加 CHANGELOG.md v0.5.3 entry（描述 2 个 CI 变更）
4. `git tag -a v0.5.3 -m "v0.5.3: CI runner alignment"`
5. `git push origin main --tags`
6. 传播版本号修正到联合验证矩阵 MARKET-CONTRACT

## 受影响的制品

| 制品路径 | 变更类型 | 说明 |
|---------|---------|------|
| `/home/workspace/contracts/go.mod` | v0.5.3 | 根据裁决更新版本 |
| `/home/workspace/contracts/VERSION` | v0.5.3 | 根据裁决写入版本号 |
| `/home/workspace/contracts/CHANGELOG.md` | 追加 | 记录 v0.5.3 CI runner 变更 |
| 联合验证矩阵 MARKET-CONTRACT | 修正 | 移除 phantom v1.5.x 引用，改为 v0.5.3 |

## 关联工作包

| 工作包 | 模块 | 优先级 | 关系 |
|-------|------|--------|------|
| CTR-001 | contracts | P0 | release lineage 重建 |

## 签署

本裁决由 FoundationX Governance 根据分析报告 `/home/workspace/ZoneCNH/report/07-11/07-11-analysis.md` §2.2 矛盾 3 和 §P0-3 生成。lineage 审计已完成，裁决为 v0.5.3。详见附录 A 和 `p0-3-lineage-audit-result.md`。

---

## 附录 A: 审计结果

> **审计执行时间**: 2026-07-11 18:50 UTC+8
> **审计详情**: 见 `p0-3-lineage-audit-result.md`

### 审计输出

```
=== ALL TAGS (sorted by creatordate) ===
v0.5.2                                          45cabadc4037189be91833daf72b3c087137ad59    ANCESTOR
archive/fix/remove-dead-reject-requestid         96aae647c10957d9a17fd1a3b48b23e8c2900e17   ORPHAN (archive branch)
v0.5.1                                          11880bc0063ebd0fa7bb31812b4902f8787f9f52    ANCESTOR
archive/fix/remove-dead-ack-requestid            c4fc7d3cea7162e3cc104875e23812f4b240abf4   ORPHAN (archive branch)
archive/fix/all-reject-codes-unsupported-channel 13899ed1876c9d10ef33777ffb8636cba78fb4d5   ORPHAN (archive branch)
v0.5.0                                          ddeef06bfd3250a6c3479b1551b1eed3ad8c4707    ANCESTOR
archive/feat/ingestion-canonical-enrichment      c5bc7a8e52c7b38b0142cfd01419dba3fd4e094e   ORPHAN (archive branch)
v0.4.7                                          0e8ad9078314bcfe8daabb63dc0aae21acbb69ab    ANCESTOR

MAIN HEAD: 27322038e71eb2c0f9955f0dc0adf87c431fbdf8
DISTANCE v0.5.2..main: 2 commits
  - 2732203 ci: 改用 GitHub-hosted runner (ubuntu-latest) 替代 self-hosted
  - 1e6ab96 fix: align workflow runner labels with sre/module.md
```

### 最终裁决

**v0.5.3** — v1.5.0 tag 不存在（phantom），实际版本链 v0.4.7→v0.5.0→v0.5.1→v0.5.2 完整且合法。无需 retract。正常 patch 递增。

### 裁决日期

2026-07-11
