# Plan 004: 重建 release/manifest/latest.json 过期统计

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat b4f486b..HEAD -- release/manifest/latest.json STATUS.md`
> If STATUS.md changed significantly since this plan was written, re-derive the expected values before proceeding; on a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S-M（需要运行 audit-status.py 并验证输出）
- **Risk**: LOW（仅更新统计数字，不改结构）
- **Depends on**: 002, 003（需要先修 audit-status.py 的 bug 才能获得正确统计）
- **Category**: docs
- **Planned at**: commit `b4f486b`, 2026-06-15

## Why this matters

`release/manifest/latest.json` 是 CI 系统的事实来源（`STATUS.md:10-11` 声明 `由 release/manifest/latest.json 自动生成`）。当前该文件全部 8 项统计与 `STATUS.md` 不一致：

| 字段 | latest.json (过期) | STATUS.md (实际) |
|------|-------------------|-------------------|
| total_components | 70 | 80 |
| existing | 54 | 58 |
| planned | 16 | 22 |
| average_progress | 49% | 62% |
| versioned | 24 | 37 |
| repo_count | 67 | 78 |

CI 消费者读取这个 JSON 会显示错误的仪表盘数据，破坏 STATUS.md 作为 SSOT 的权威性。

## Current state

- `release/manifest/latest.json` — 上次生成于 `2026-06-15T03:00:57Z`，commit `768c83f`，版本 `v1.1.1`
- `STATUS.md` — 已通过大量 PR 更新（#385-#439 审计闭合），数据准确
- `scripts/audit-status.py` — 包含正确的统计逻辑（Plan 002-003 修复后）
- `.foundationx/status/index.json` — 模块级数据源
- `.foundationx/blockers.json` — 阻塞项数据源

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| 运行审计脚本 | `python3 scripts/audit-status.py` | 输出各项检查，exit 0 |
| 运行网络审计 | `python3 scripts/audit-status.py --network` | 24 项 PASS，0 404 |
| 验证新 manifest | `python3 -c "import json; m=json.load(open('release/manifest/latest.json')); print(f'components={m[\"stats\"][\"total_components\"]} existing={m[\"stats\"][\"existing\"]} avg={m[\"stats\"][\"average_progress\"]}% versioned={m[\"stats\"][\"versioned\"]} repos={m[\"stats\"][\"repo_count\"]}')"` | 输出应与 STATUS.md 一致 |

## Scope

**In scope**:
- `release/manifest/latest.json` — 更新 `stats` 对象和 `version`、`generated_at`
- 如果 `scripts/version-bump.sh` 或其他工具自动生成 manifest，则修复生成逻辑

**Out of scope**:
- 不修改 `STATUS.md` 的任何数据
- 不修改 manifest JSON 的 schema 结构
- 不修改 `.foundationx/` 下的源数据文件

## Git workflow

- Branch: `docs/rebuild-release-manifest`
- Commit 格式：`docs: 重建 release/manifest/latest.json 统计镜像 STATUS.md`
- 作为同一 PR 的一部分，同步更新 CLAUDE.md 的版本表（见 Plan 004b）

## Steps

### Step 1: 确认源数据的准确性

```bash
# 确认 STATUS.md 组件数
grep -oP 'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+' STATUS.md | sort -u | wc -l
# 确认有版本号的组件数
sed -n '20,39p' STATUS.md | grep 'github.com' | awk -F'|' '{gsub(/^[ ]+|[ ]+$/,"",$3); if($3!="" && $3!="-") print}' | wc -l
```

**Verify**: 记录实际数字，与上表 "STATUS.md (实际)" 列对比。

### Step 2: 运行审计脚本生成正确统计

```bash
python3 scripts/audit-status.py
```

如果 Plan 002 和 003 已完成，脚本应正确执行所有检查。

**Verify**: 脚本 exit 0，无 WARNING（或仅有预期的 WARNING）

### Step 3: 更新 release/manifest/latest.json

手动更新 `stats` 对象中的值。确保以下字段与 `python3 scripts/audit-status.py` 输出一致：
- `total_components`: 实际组件总数
- `existing`: 已有 GitHub 仓库的组件数
- `planned`: 仅有计划无仓库的组件数
- `average_progress`: 平均进度百分比（整数）
- `versioned`: 有版本号的组件数
- `repo_count`: 唯一 GitHub 仓库数

同时更新：
- `generated_at`: 当前 ISO 8601 时间戳
- `version`: 如果 manifest 格式或内容有显著变化，bump PATCH

```bash
# 设置正确的时间戳
python3 -c "
import json, datetime
with open('release/manifest/latest.json') as f:
    m = json.load(f)
m['generated_at'] = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
# 更新 stats（用实际数字替换）
m['stats']['total_components'] = 80  # 用 Step 1 确认的数字
# ... 其他字段
with open('release/manifest/latest.json', 'w') as f:
    json.dump(m, f, indent=2, ensure_ascii=False)
    f.write('\n')
print('Updated')
"
```

**Verify**: `python3 -c "import json; json.load(open('release/manifest/latest.json'))"` → 有效 JSON，exit 0

### Step 4: 交叉验证新 manifest 与 STATUS.md

```bash
python3 -c "
import json, subprocess, re

with open('release/manifest/latest.json') as f:
    m = json.load(f)

# 从 STATUS.md 提取实际数字
with open('STATUS.md') as f:
    status = f.read()

# 检查唯一仓库数
repos_status = set(re.findall(r'github\.com/ZoneCNH/([a-zA-Z0-9_.-]+)', status))
repos_status.discard('ZoneCNH')  # 排除自身引用

print(f'manifest.total_components: {m[\"stats\"][\"total_components\"]}')
print(f'STATUS.md unique repos:    {len(repos_status)}')
print(f'manifest.repo_count:       {m[\"stats\"][\"repo_count\"]}')
print(f'Match: {m[\"stats\"][\"repo_count\"] == len(repos_status)}')
"
```

**Verify**: `repo_count` 与 `unique repos` 匹配

## Test plan

- `python3 scripts/audit-status.py --network` → 24 项 PASS
- `python3 -c "import json; m=json.load(open('release/manifest/latest.json')); assert m['stats']['total_components'] >= 79"` → 通过
- 确认 CI 管道读取新 manifest 后仪表盘数据正确

## Done criteria

- [ ] `release/manifest/latest.json` 的 `stats.total_components` 与 STATUS.md 的 unique repo 数一致
- [ ] `stats.repo_count` 与 `grep -oP 'github\.com/ZoneCNH/[a-zA-Z0-9_.-]+' STATUS.md | sort -u | wc -l` 一致
- [ ] `generated_at` 时间戳已更新
- [ ] 新 manifest 是有效 JSON
- [ ] `plans/README.md` 状态行已更新

## STOP conditions

- `python3 scripts/audit-status.py` 失败 — 先完成 Plan 002 和 003
- STATUS.md 的 unique repo 数与 manifest 的 `repo_count` 差距 > 2 — 需要人工审查差异
- 更新 manifest 后 CI 仪表盘显示异常 — 回滚 manifest 并报告

## Maintenance notes

- 建议在 `scripts/version-bump.sh` 或 CI 中添加自动 manifest 重建步骤
- 理想情况下，`release/manifest/latest.json` 应由 `python3 scripts/audit-status.py --generate-manifest` 自动生成，而非手动编辑
- 每次 STATUS.md 重大更新后都应重建 manifest
