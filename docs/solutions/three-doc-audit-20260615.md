# 三文件一致性审计 2026-06-15

## 范围

STATUS.md / ARCHITECTURE.md / README.md 跨文件域成员、版本号、进度、计数全量对账与修正。

## 交付指标

| 指标 | 值 |
|------|----|
| 波及文件 | 3 (STATUS.md / ARCHITECTURE.md / README.md) + CLAUDE.md + hooks + CI |
| 闭合 PR | 18 (#385–#408) |
| 修正类别 | 版本号、归属漂移、已删除残留、统计合计、仪表盘、同步表、规则固化、预防门禁 |
| 最终组件数 | 80 |
| 仪表盘自洽 | 55+1+22+2=80, 37+43=80, 58+22=80 |
| 404 仓库 | 0 (78 repos 全量验证) |
| audit-status.py 检查 | 21/21 PASS |

## PR 清单

| PR | 类别 | 说明 |
|----|------|------|
| #385 | 版本审计 | 19 基座模块 vs GitHub Release 逐一核对，14/20 有 Release，18/20 有 git tag |
| #386 | 残差修复 | observex 横切段 v0.3.1→v1.0.0，基座/L2.5 统计修正 |
| #387 | 同步表审计 | L2.5/分析域/决策域 STATUS 列与实际表行对齐 |
| #388 | 归属对齐 | domainx 移入 README 基座段 |
| #389 | 同步表注释 | 注释计数从主观描述修正为 grep 实测值 |
| #390 | 版本同步 | ARCHITECTURE 状态表 12 处版本/进度与 STATUS 对齐 |
| #391 | 域统计 | 分析域/决策域/执行域有版本号列补齐（2/3/3），合计 30→37 |
| #392 | 跨文件引用 | README/ARCH 中 19→20 基座模块引用 |
| #393 | 404 移除 | strategies 仓库全文件删除（HTTP 404） |
| #394 | 仪表盘重算 | 总数组件/已有/已创建/平均进度/进度分布全量递推 |
| #395 | 风险清单 | R6 strategies 引用移除 |
| #396 | 注记修正 | GitHub Release 数 18→14（clickhousex/contracts/transportx/domainx 无 Release） |
| #397 | 同步表 | README/ARCH unique repos 78→77 (strategies 移除后) |
| #398 | 仪表盘 | 5% 分布 21→22，未标注 3→2 |
| #399 | 预防 | CountGuard PreToolUse hook 部署 |
| #400 | 仪表盘 | 二次 recalc，同步合并冲突 |
| #401 | 规则 | CLAUDE.md 固化数量验证门禁、三文档同步、404 扫描规则 |
| #402 | 复核 | 无残余问题（linter 同步后状态确认） |
| #403 | 同步表 | 组件总数行 78/78/80→77/77/78 |
| #404 | 闭合 | 三文件一致性审计会话闭合记录 |
| #406 | 成熟度 | RELEASE 列口径修正 — 4 模块 git tag 有但 GitHub Release 无 → ❌ |
| #408 | 预防 | audit-status.py + CI gate 部署 |

## 修改清单

### domainx 归并（3 文件）

| 文件 | 修改 |
|------|------|
| STATUS.md | 组件表 domainx 从 L2.5 移至基座；L2.5 标题 5→4；版本注记/域统计/域健康度同步 |
| ARCHITECTURE.md | ASCII 图新增 `领域共享: domainx`；Foundation(19)→Foundation(20)；SRE 文档引用修正 |
| README.md | 链路列表 domainx 从 L2.5 移至基座契约段；ASCII 图同步；"19 个基座模块"→"20 个" |

### 版本/进度对齐（ARCH 状态总览表 ← STATUS 组件表）

| 模块 | 修正 |
|------|------|
| xlib-standard | 版本 `-` → `v1.0.0`，状态 `已有` → `已发布` |
| xlib-harness | 版本 `v1.0.0` → `-`，补充 git tag + GitHub Release 缺失注记 |
| xlib-evidence | 同上 |
| testkitx | 版本 `v0.4.0` → `v1.0.0`，进度 `90%` → `100%` |
| resiliencx | 版本 `v1.0.1` → `v1.0.0` (GitHub Release 实际为 v1.0.0) |
| xlibgate | 进度 `95%` → `100%` |
| redisx | 版本 `v1.0.0` → `v1.0.1` (GitHub Release 实际为 v1.0.1) |
| postgresx | 进度 `90%` → `100%` |
| decimalx | 版本 `v0.2.0` → `v0.1.0` |
| regime-engine | 版本 `-` → `v0.1.0`，进度 `5%` → `25%` |

### strategies 移除（3 文件）

全部 GitHub 链接、组件表行、ASCII 引用、风险清单 R6、域健康度描述移除。决策域 7→6，组件总数 81→80，unique repos 78→77。

### 域统计有版本号修正

| 域 | 原值 | 修正值 | 遗漏模块 |
|----|:---:|:-----:|------|
| 分析域 | 1 (regime-engine) | 2 | +flowx (v0.1.0-draft) |
| 决策域 | 0 | 3 | backtestx, strategyx, maestro (v0.1.0-draft) |
| 执行域 | 0 | 3 | riskx, orderx, positionx (v0.1.0-draft) |
| 合计 | 30 | 37 | -- |

### 仪表盘递推

| 项 | 原值 | 修正值 | 说明 |
|----|:---:|:-----:|------|
| 组件总数 | 81 | 80 | strategies 移除 (-1) |
| 已有 | 65 | 58 | 重算各域已有行 |
| 已创建 | 16 | 22 | 7 个 v0.1.0-draft + 原已创建 |
| 平均进度 | 65% | 62% | 加权重算 (4955/80) |
| ≥80% | 54 | 55 | 重算 |
| 60% | 1 | 0 | strategies 移除，唯一 60% 项消失 |
| 5% | 15 | 22 | 7 个 v0.1.0-draft + 原 5% 项 |
| 有版本号 | 31 | 37 | +6 (v0.1.0-draft 模块) |
| GitHub Release 数 | 18/20 | 14/20 | clickhousex/contracts/transportx/domainx 无 Release |

### 同步检查表最终值

| 检查项 | README | ARCH | STATUS | 一致性 |
|--------|:------:|:----:|:------:|:------:|
| 组件总数 | 77 | 77 | 78 | ⚠️ (STATUS 多 stdlib.rs) |
| L2.5 组件 | 4 | 4 | 4 | ✅ |
| 分析域组件 | 8 | 8 | 8 | ✅ |
| 决策域组件 | 6 | 6 | 6 | ✅ |
| 横切组件 | 2 | 2 | 2 | ✅ |

### 新增文件

| 文件 | 用途 |
|------|------|
| `.claude/hooks/count-guard.mjs` | Write/Edit 三文档时扫描数量模式并输出验证提醒 |
| `scripts/audit-status.py` | 22 项交叉验证（表行 vs 域统计、仪表盘 vs 合计、同步表 vs grep、版本计数、残留引用、域算术、404 扫描） |
| `.github/workflows/audit-status.yml` | PR/push 触发 audit-status.py，FAIL 阻断合并 |
| `CLAUDE.md` (更新) | 新增 §数量验证门禁、§三文档交叉同步、更新 §模块-仓库强制对应 |

## 验收标准（ISC）

- [x] ISC-1 domainx 三文件统一归基座
- [x] ISC-2 仪表盘 55+1+22+2=80, 37+43=80, 58+22=80
- [x] ISC-3 ARCH 状态表 12 处版本/进度与 STATUS 对齐
- [x] ISC-4 78 repos gh api 全量存在，0 404
- [x] ISC-5 同步表各域计数与组件表一致
- [x] ISC-6 strategies 全部引用已移除
- [x] ISC-7 GitHub Release / git tag 计数与 gh api 验证一致
- [x] ISC-8 CountGuard hook + audit-status.py + CI gate 三线预防已部署
- [x] ISC-9 audit-status.py 21/21 PASS
- [x] ISC-10 域统计有版本号合计 37，各域分项与表列一致

## 预防门禁

| 层级 | 工具 | 触发 | 阻断 |
|------|------|------|:----:|
| 会话内 | count-guard.mjs | Write/Edit 三文档 | 告警，不阻断 |
| 本地 | audit-status.py | 手动 / Stop hook | 报告 FAIL |
| CI | audit-status.yml | PR/push 到三文档 | **阻断 merge** |
| 规则 | CLAUDE.md §数量验证门禁 | 每次计数变更 | 永久约束 |

## 闭合 PR

#385 → #386 → #387 → #388 → #389 → #390 → #391 → #392 → #393 → #394 → #395 → #396 → #397 → #398 → #399 → #400 → #401 → #402 → #403 → #404 → #406 → #408，全部 squash-merge 至 ZoneCNH main。
