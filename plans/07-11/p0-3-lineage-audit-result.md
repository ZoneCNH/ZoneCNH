# P0-3: contracts lineage 审计结果

> 日期: 2026-07-11

## 审计输出

```
=== ALL TAGS ===
v0.5.2 45cabadc4037189be91833daf72b3c087137ad59
archive/fix/remove-dead-reject-requestid 96aae647c10957d9a17fd1a3b48b23e8c2900e17
v0.5.1 11880bc0063ebd0fa7bb31812b4902f8787f9f52
archive/fix/remove-dead-ack-requestid c4fc7d3cea7162e3cc104875e23812f4b240abf4
archive/fix/all-reject-codes-unsupported-channel 13899ed1876c9d10ef33777ffb8636cba78fb4d5
v0.5.0 ddeef06bfd3250a6c3479b1551b1eed3ad8c4707
archive/feat/ingestion-canonical-enrichment c5bc7a8e52c7b38b0142cfd01419dba3fd4e094e
v0.4.7 0e8ad9078314bcfe8daabb63dc0aae21acbb69ab

=== ANCESTOR CHECK (vs main=27322038e71eb2c0f9955f0dc0adf87c431fbdf8) ===
ANCESTOR: v0.5.2 (45cabadc4037189be91833daf72b3c087137ad59)
ORPHAN(not ancestor): archive/fix/remove-dead-reject-requestid
ANCESTOR: v0.5.1 (11880bc0063ebd0fa7bb31812b4902f8787f9f52)
ORPHAN(not ancestor): archive/fix/remove-dead-ack-requestid
ORPHAN(not ancestor): archive/fix/all-reject-codes-unsupported-channel
ANCESTOR: v0.5.0 (ddeef06bfd3250a6c3479b1551b1eed3ad8c4707)
ORPHAN(not ancestor): archive/feat/ingestion-canonical-enrichment
ANCESTOR: v0.4.7 (0e8ad9078314bcfe8daabb63dc0aae21acbb69ab)

LATEST_VALID: v0.5.2 (45cabadc4037189be91833daf72b3c087137ad59)

=== MAIN SUMMARY ===
v0.5.2..main distance: 2 commits
2732203 ci: 改用 GitHub-hosted runner (ubuntu-latest) 替代 self-hosted (#24)
1e6ab96 fix: align workflow runner labels with sre/module.md (#23)
```

## 版本裁决

### 关键发现

**v1.5.0 tag 不存在。** contracts 仓库中没有任何 v1.5.0 tag。RULING-003 中声称"当前 tag v1.5.0"是分析报告的错误前提。

### 实际版本状态

| 项目               | 值                                                |
| ------------------ | ------------------------------------------------- |
| HEAD (main)        | 27322038e71eb2c0f9955f0dc0adf87c431fbdf8          |
| 最新合法祖先       | v0.5.2 (45cabadc4037189be91833daf72b3c087137ad59) |
| 距 v0.5.2 的提交数 | 2 (CI/workflow 变更)                              |
| 合法版本 tag 链    | v0.4.7 → v0.5.0 → v0.5.1 → v0.5.2                 |
| 不存在 tag         | v1.5.0（phantom — 从未存在）                      |

### 裁决

- **裁决**: `v0.5.3`
- **理由**: v1.5.0 tag 不存在（phantom tag），RULING-003 的前提错误。实际最新合法版本为 v0.5.2，main 领先 2 个提交（均为 CI/工作流配置变更，非功能变更）。按语义化版本规范，正常 patch bump 到 v0.5.3。
- **裁决表对照**: 不属于裁决表四场景。实际场景为"v1.5.0 不存在 + 最新合法=v0.5.2"，等价于"v0.5.2 是合法祖先"的正常 patch 递增。
- **最新合法祖先**: v0.5.2

### 裁决表评估

| 裁决表行                                      | 匹配 | 说明                              |
| --------------------------------------------- | ---- | --------------------------------- |
| v1.5.0 是 main 合法祖先 → v1.5.1              | 否   | v1.5.0 不存在                     |
| v1.5.0 孤儿，最新合法=v0.4.0 → v2.0.0         | 否   | 最新合法是 v0.5.2 非 v0.4.0       |
| v1.5.0 孤儿，最新合法=v1.3.0 → v1.4.0+retract | 否   | 最新合法是 v0.5.2 非 v1.3.0       |
| 无合法祖先 tag → v1.0.0                       | 否   | 有完整的 v0.4.7~v0.5.2 合法祖先链 |

### 附加说明

1. **archive/\*** tag 为归档功能分支 tag，不属于版本发布 tag，其 orphan 状态符合预期，不影响裁决。
2. v0.5.2→main 的 2 个提交为 CI runner 变更，属于基础设施调整，建议包含在 v0.5.3 发布中。

## 修正操作

```bash
# contracts 无需 retroactive 修正 — 当前版本号链完整
# 只需发布 v0.5.3：
cd /home/workspace/contracts
git checkout main
# 更新 VERSION 文件（如有）为 v0.5.3
# 更新 CHANGELOG.md
# git tag -a v0.5.3 -m "v0.5.3: CI runner alignment"
# git push origin main --tags
```

## 受影响的制品

| 制品                                   | 影响                                                |
| -------------------------------------- | --------------------------------------------------- |
| RULING-003 (ruling-contracts.md)       | 需要更新：纠正 v1.5.0 phantom 错误；裁决改为 v0.5.3 |
| contracts/VERSION（如有）              | 写入 v0.5.3                                         |
| contracts/CHANGELOG.md                 | 追加 v0.5.3 entry                                   |
| 联合验证矩阵 MARKET-CONTRACT           | 版本号引用从 v1.5.x 修正为 v0.5.3                   |
| 分析报告 07-11-analysis.md §2.2 矛盾 3 | 前提 "tag v1.5.0" 为错误声明，需纠正                |
