# Binance Commit Coverage Audit 2026-06-23

- Status: Audit
- Scope: `ZoneCNH/ZoneCNH` PR metadata and `/home/binance` local commit window
- Issue: #896
- Confidence: MED

## 1. 审计结论

[COMPUTED][MED] #896 的前提不能被本 lane 严格复现，因此不应关闭该 issue。

[COMPUTED][HIGH] `ZoneCNH/ZoneCNH` 中 PR #850、PR #852、PR #853 的 mergedAt 与 mergeCommit 可通过 `gh pr view` 复核。

[KNOWN][MED] 当前任务要求记录 `/home/binance` 在 2026-06-21 到 2026-06-23（+08）窗口内 unique commits=191、literal 保存/backup/preserve/auto-stash grep count=0、extended OR grep count=52。

[COMPUTED][MED] 本 lane 对 `/home/binance` 的本地只读复核未能得到 unique commits=191：在当前本地 refs 下，`git log --all` 同窗口 unique commit count 为 10。该差异支持“不严格复现”的结论。

## 2. PR 合并事实

| PR | mergedAt UTC | mergedAt +08 | mergeCommit |
| --- | --- | --- | --- |
| #850 | 2026-06-22T00:09:24Z | 2026-06-22 08:09:24 +08 | `b92a6909a646af8236db6bc865fbf23f709f6534` |
| #852 | 2026-06-22T04:44:59Z | 2026-06-22 12:44:59 +08 | `2d83b6b9d9795d5c568794ce5f483c853d74a6cb` |
| #853 | 2026-06-22T04:51:49Z | 2026-06-22 12:51:49 +08 | `aa7d8bf3bdb7541e87bbb68717e73cd837c560de` |

## 3. Commit Coverage 记录

| 项目 | 记录值 | 来源 |
| --- | --- | --- |
| `/home/binance` 统计窗口 | 2026-06-21 00:00:00 +08 到 2026-06-23 23:59:59 +08 | 任务输入 |
| unique commits | 191 | 任务输入 |
| literal 保存/backup/preserve/auto-stash grep count | 0 | 任务输入 |
| extended OR grep count | 52 | 任务输入 |
| 本地 `git log --all` unique commits 复核 | 10 | 当前 lane 只读命令 |
| 本地 literal grep 复核 | 0 | 当前 lane 只读命令 |

## 4. 复核命令

```bash
gh pr view 850 --repo ZoneCNH/ZoneCNH --json number,mergedAt,mergeCommit
gh pr view 852 --repo ZoneCNH/ZoneCNH --json number,mergedAt,mergeCommit
gh pr view 853 --repo ZoneCNH/ZoneCNH --json number,mergedAt,mergeCommit
git -C /home/binance log --all --since='2026-06-21 00:00 +0800' --until='2026-06-23 23:59:59 +0800' --format=%H | sort -u | wc -l
git -C /home/binance log --all --since='2026-06-21 00:00 +0800' --until='2026-06-23 23:59:59 +0800' --format='%H %s' --grep='保存' --grep='backup' --grep='preserve' --grep='auto-stash'
```

## 5. 处理建议

[INFERRED][MED] #896 应保持打开，直到主线程能说明 191 的统计来源、refs 范围、是否包含远端或临时 refs、以及 extended OR 的完整表达式。

[INFERRED][MED] 若后续要关闭 #896，应先补一份可复跑命令记录，确保 unique commit count、literal grep count 和 extended OR count 都能在同一工作区复现。

[RULES I BROKE]：无
