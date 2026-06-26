# Plan 008 Issues 同步一致性报告

> beads issues ↔ GitHub issues ↔ Plan 008 Task 三方一致性核验报告
>
> - 日期：2026-06-25
> - Plan：`plans/binance/008-binance-production-fix-master-plan.md`
> - SSOT：`plans/binance/008-tasks.json`
> - **GitHub 仓库：`ZoneCNH/ZoneCNH`**（issues #1132-#1171）
> - beads workspace：`ZoneCNH`（prefix=ZoneCNH，label `plan008`）
> - Runtime-Anchor：`/home/binance@f18a329`（Plan008 final closeout；PR #103+#104 runtime fix baseline 为 `3f20be0`）
> - Final-Code-Anchor：`/home/binance` `fix/plan008-production-fixes@46d8aa8`（PR #145，OPEN）；`/home/kafkax` `fix/plan008-production-fixes@7b2d9ce`

---

## 1. 执行摘要

`[COMPUTED, HIGH]` Plan 008 的 **40 个 Task**（T008.001-T040）已完整拆解为可追踪的 issue 体系：

| 维度 | 数量 | 位置 |
| --- | --- | --- |
| Plan Task（SSOT） | 40 | `008-tasks.json` |
| GitHub issues | 40 | **`ZoneCNH/ZoneCNH`** #1132-#1171（closed，label `plan008`） |
| beads issues | 40 | ZoneCNH workspace（label `plan008`，status `closed`，external-ref `gh-N`） |
| 依赖链接（beads） | 25 | `bd link --type blocks` |
| 覆盖缺口 G1-G9 | 9/9 | 全部有 Task |
| 覆盖标准 S1-S35 | 35/35 | 全部有 Task |
| 覆盖里程碑 M1-M4 | 4/4 | 全部有 Task |

`[COMPUTED, HIGH]` 最终收口状态：GitHub `plan008` issues 40/40 CLOSED，beads `plan008` issues 40/40 `closed`；T008.039/T008.040 已记录 release closeout 证据：GitHub Release `v0.2.0`，workflow `28126779885` completed/success，`release_closeable=YES`，#1170/#1171 closed。

`[COMPUTED, HIGH]` Kafka 补证状态：T008.003 的最终代码证据落在 `kafkax@7b2d9ce` 与 `binance@46d8aa8`；binance PR #145 已推送但仍为 OPEN。验证证据为 `go test ./cmd/binance-server`、`go test ./...`、10 轮 `git diff --check && go test ./... -count=1` 通过；未运行 live Kafka broker E2E 或生产凭证场景。

**三方 100% 一致，0 遗漏，0 open Plan008 issue。**

---

## 2. 仓库决策与迁移记录

### 2.1 仓库选择

GitHub issues 建在 **`ZoneCNH/ZoneCNH`**（而非 `ZoneCNH/binance`），理由：

1. Plan 008 文档位于本仓库 `plans/binance/`
2. beads workspace 位于本仓库 `.beads/`
3. 历史 binance 相关 issue（`report/binance` 系列 #1104-#1123）惯例建在本仓库
4. 集中文档治理与 issue 追踪，符合仓库"Markdown 文档枢纽"定位

### 2.2 迁移记录

`[COMPUTED, HIGH]` 初始误建至 `ZoneCNH/binance`（#105-#144），已迁移：

| 操作 | 仓库 | 范围 | 状态 |
| --- | --- | --- | --- |
| 关闭错建 issue | ZoneCNH/binance | #105-#144（40 个） | ✅ 全部 CLOSED（reason: not planned） |
| 重建 issue | ZoneCNH/ZoneCNH | #1132-#1171（40 个） | ✅ 创建后 OPEN；最终收口为 40/40 CLOSED |
| 更新 beads external_ref | ZoneCNH workspace | 40 个 issue | ✅ gh-105~144 → gh-1132~1171 |
| 更新 beads github 配置 | config.yaml | owner/repo | ✅ ZoneCNH/ZoneCNH |
| 删除 beads 重复 issue | ZoneCNH workspace | 40 个（pull 误建） | ✅ 已清理 |

> binance 仓库的 #105-#144 为已关闭的迁移痕迹，不参与活跃追踪。

---

## 3. 完整映射表（40 Task ↔ GitHub ↔ beads）

| Task | Phase | 优先级 | 映射 | 缺口 | GitHub | beads ID |
| --- | :--: | :--: | --- | --- | --- | --- |
| T008.001 | 0 | P0 | S1 | G6 | [#1132](https://github.com/ZoneCNH/ZoneCNH/issues/1132) | ZoneCNH-hdw |
| T008.002 | 0 | P0 | S5 | G8 | [#1133](https://github.com/ZoneCNH/ZoneCNH/issues/1133) | ZoneCNH-bet |
| T008.003 | 0 | P0 | S7 | fanout丢失 | [#1134](https://github.com/ZoneCNH/ZoneCNH/issues/1134) | ZoneCNH-ahe |
| T008.004 | 0 | P0 | FR-032 | G4/G5前置 | [#1135](https://github.com/ZoneCNH/ZoneCNH/issues/1135) | ZoneCNH-7d6 |
| T008.005 | 0 | P0 | S3/S4前置 | 存储§6 | [#1136](https://github.com/ZoneCNH/ZoneCNH/issues/1136) | ZoneCNH-njl |
| T008.006 | 0 | P0 | S6 | 分析域DLQ | [#1137](https://github.com/ZoneCNH/ZoneCNH/issues/1137) | ZoneCNH-0pa |
| T008.007 | 1 | P0 | S16 | G1/G2 | [#1138](https://github.com/ZoneCNH/ZoneCNH/issues/1138) | ZoneCNH-1x4 |
| T008.008 | 1 | P0 | G1/S16 | G1 | [#1139](https://github.com/ZoneCNH/ZoneCNH/issues/1139) | ZoneCNH-dgq |
| T008.009 | 1 | P0 | G2/S16 | G2 | [#1140](https://github.com/ZoneCNH/ZoneCNH/issues/1140) | ZoneCNH-slc |
| T008.010 | 1 | P0 | S16 | G1/G2 | [#1141](https://github.com/ZoneCNH/ZoneCNH/issues/1141) | ZoneCNH-n5l |
| T008.011 | 1 | P0 | G4/S9 | G4 | [#1142](https://github.com/ZoneCNH/ZoneCNH/issues/1142) | ZoneCNH-8kt |
| T008.012 | 1 | P0 | G3 | G3 | [#1143](https://github.com/ZoneCNH/ZoneCNH/issues/1143) | ZoneCNH-4e8r |
| T008.013 | 1 | P0 | G8/S5 | G8 | [#1144](https://github.com/ZoneCNH/ZoneCNH/issues/1144) | ZoneCNH-y941 |
| T008.014 | 1 | P0 | G8 | G8 | [#1145](https://github.com/ZoneCNH/ZoneCNH/issues/1145) | ZoneCNH-4xvp |
| T008.015 | 1 | P0 | G6/S2 | G6 | [#1146](https://github.com/ZoneCNH/ZoneCNH/issues/1146) | ZoneCNH-d674 |
| T008.016 | 1 | P0 | G6/S1 | G6 | [#1147](https://github.com/ZoneCNH/ZoneCNH/issues/1147) | ZoneCNH-ptva |
| T008.017 | 1 | P0 | G7/S12/S13 | G7 | [#1148](https://github.com/ZoneCNH/ZoneCNH/issues/1148) | ZoneCNH-gu84 |
| T008.018 | 1 | P0 | G6/G7 | G6/G7 | [#1149](https://github.com/ZoneCNH/ZoneCNH/issues/1149) | ZoneCNH-8cnj |
| T008.019 | 1 | P0 | G8/S12 | G8 | [#1150](https://github.com/ZoneCNH/ZoneCNH/issues/1150) | ZoneCNH-oig2 |
| T008.020 | 2 | P1 | G5 | G5 | [#1151](https://github.com/ZoneCNH/ZoneCNH/issues/1151) | ZoneCNH-incw |
| T008.021 | 2 | P1 | G5 | G5 | [#1152](https://github.com/ZoneCNH/ZoneCNH/issues/1152) | ZoneCNH-o97y |
| T008.022 | 2 | P1 | G9 | G9 | [#1153](https://github.com/ZoneCNH/ZoneCNH/issues/1153) | ZoneCNH-oj40 |
| T008.023 | 2 | P1 | G9 | G9 | [#1154](https://github.com/ZoneCNH/ZoneCNH/issues/1154) | ZoneCNH-zwsz |
| T008.024 | 2 | P0 | S3 | 分析域SPOF | [#1155](https://github.com/ZoneCNH/ZoneCNH/issues/1155) | ZoneCNH-ugsm |
| T008.025 | 2 | P0 | S4 | 存储§6 | [#1156](https://github.com/ZoneCNH/ZoneCNH/issues/1156) | ZoneCNH-x6an |
| T008.026 | 2 | P1 | S14 | 重复写入 | [#1157](https://github.com/ZoneCNH/ZoneCNH/issues/1157) | ZoneCNH-vmsl |
| T008.027 | 2 | P0 | S26 | — | [#1158](https://github.com/ZoneCNH/ZoneCNH/issues/1158) | ZoneCNH-yzd3 |
| T008.028 | 2 | P0 | S26 | — | [#1159](https://github.com/ZoneCNH/ZoneCNH/issues/1159) | ZoneCNH-1x7m |
| T008.029 | 2 | P1 | S27 | — | [#1160](https://github.com/ZoneCNH/ZoneCNH/issues/1160) | ZoneCNH-jfma |
| T008.030 | 2 | P1 | S28 | — | [#1161](https://github.com/ZoneCNH/ZoneCNH/issues/1161) | ZoneCNH-lj5c |
| T008.031 | 2 | P1 | S29 | — | [#1162](https://github.com/ZoneCNH/ZoneCNH/issues/1162) | ZoneCNH-qiad |
| T008.032 | 2 | P1 | S30/S33 | — | [#1163](https://github.com/ZoneCNH/ZoneCNH/issues/1163) | ZoneCNH-z9sa |
| T008.033 | 2 | P1 | S8/S10/S11/S15/S17 | DR | [#1164](https://github.com/ZoneCNH/ZoneCNH/issues/1164) | ZoneCNH-2zhj |
| T008.034 | 3 | P2 | S18-S25 | — | [#1165](https://github.com/ZoneCNH/ZoneCNH/issues/1165) | ZoneCNH-j9zq |
| T008.035 | 3 | P2 | S31 | — | [#1166](https://github.com/ZoneCNH/ZoneCNH/issues/1166) | ZoneCNH-njvg |
| T008.036 | 3 | P2 | S32 | — | [#1167](https://github.com/ZoneCNH/ZoneCNH/issues/1167) | ZoneCNH-pyxz |
| T008.037 | 3 | P2 | S34/S35 | — | [#1168](https://github.com/ZoneCNH/ZoneCNH/issues/1168) | ZoneCNH-5ts9 |
| T008.038 | 3 | P2 | M1-M4 | — | [#1169](https://github.com/ZoneCNH/ZoneCNH/issues/1169) | ZoneCNH-vicx |
| T008.039 | 4 | P0 | 全部 | — | [#1170](https://github.com/ZoneCNH/ZoneCNH/issues/1170) | ZoneCNH-036r |
| T008.040 | 4 | P0 | 全部 | — | [#1171](https://github.com/ZoneCNH/ZoneCNH/issues/1171) | ZoneCNH-771j |

### 3.1 优先级与 Phase 分布

| Phase | Task 范围 | 数量 | 优先级 | Plan §7 | ✓ |
| --- | --- | :--: | --- | :--: | :--: |
| 0 | T008.001-006 | 6 | 全 P0 | 6 | ✓ |
| 1 | T008.007-019 | 13 | 全 P0 | 13 | ✓ |
| 2 | T008.020-033 | 14 | P0×4 / P1×10 | 14 | ✓ |
| 3 | T008.034-038 | 5 | 全 P2 | 5 | ✓ |
| 4 | T008.039-040 | 2 | 全 P0 | 2 | ✓ |

---

## 4. 依赖图（beads blocks 关系，25 条）

```
T004(FR-032) ──blocks──▶ T011(G4 cursor)
T007(AlertDispatcher) ──blocks──▶ T008(G1 stale) , T009(G2 gap)
T011 ──blocks──▶ T012(G3 replay)
T002(natsx hook) ──blocks──▶ T013(G8 DLQ)
T013 ──blocks──▶ T014(G8 replay endpoint) , T019(DLQ→OSS)
T001(taosx DeleteRange) ──blocks──▶ T016(G6 retention B) , T039(验收)
T015(KEEP 365) ──blocks──▶ T016
T016 , T017(OSS迁移) ──blocks──▶ T018(删除顺序契约)
T017 ──blocks──▶ T019 , T022(G9 冷热判断)
T012 , T004 ──blocks──▶ T020(G5 reconcile)
T022 ──blocks──▶ T023(G9 rehydrate)
T005(ch DDL校验) ──blocks──▶ T024(S3 副本) , T025(S4 TTL)
T024 ──blocks──▶ T026(S14 幂等)
T027(feature flag) ──blocks──▶ T028(回滚 runbook)
T008 , T023 ──blocks──▶ T038(M1-M4 仪表盘)
T001 , T038 ──blocks──▶ T039(全量回归)
T039 ──blocks──▶ T040(TRACEABILITY 同步)
```

---

## 5. 核验记录

### 5.1 三方一致性核验（10 维度）

脚本：`plans/binance/008-verify-10rounds.sh`（REPO=ZoneCNH/ZoneCNH）

| 轮次 | 检查维度 | 结果 |
| --- | --- | :--: |
| 1 | 数量/状态一致：SSOT(40)==GH(40 CLOSED)==beads(40 closed) | ✅ |
| 2 | 每个 SSOT task_id 在 GH map 有记录 | ✅ |
| 3 | 每个 SSOT task_id 在 beads map 有记录 | ✅ |
| 4 | GH 编号唯一连续（#1132-#1171） | ✅ |
| 5 | beads ID 全部唯一（40） | ✅ |
| 6 | 每个 beads external_ref 与 GH 编号匹配（实时查询） | ✅ |
| 7 | GH map 编号集合 == GH 实时编号集合（精确匹配） | ✅ |
| 8 | 每个 GH issue 标题含 [task_id]（批量查询） | ✅ |
| 9 | 9 个数据缺口 G1-G9 全覆盖 | ✅ |
| 10 | 35 标准 S1-S35 + 4 里程碑 M1-M4 全覆盖，且 release/workflow/closeout 证据存在 | ✅ |

### 5.2 SSOT 忠实性核验（7 维度）

脚本：`plans/binance/008-verify-faithfulness.sh`

| 轮次 | 检查维度 | 结果 |
| --- | --- | :--: |
| 11a | Plan 文档 task_id 集合 == SSOT task_id 集合 | ✅ |
| 11b | Plan 文档与 SSOT 均为 40 个 Task | ✅ |
| 11c | T008.001-T040 连续无间断 | ✅ |
| 11d | Phase 分布与 Plan §7 一致（6/13/14/5/2） | ✅ |
| 11e | 优先级 P0/P1/P2 合计 40 | ✅ |
| 11f | 40 个 SSOT 标题与 Plan §2 表格标题一致 | ✅ |
| 11g | Plan §3.6 覆盖声明与核验数据一致 | ✅ |

### 5.3 核验结论

`[COMPUTED, HIGH]` 经 **17 轮多维核验**，以 final closeout 口径最终运行 10/10 + 7/7 全通过：

- **40/40 Task** 三方映射完整
- **0 遗漏**（9 缺口 + 35 标准 + 4 里程碑 = 48 项 100% 覆盖）
- **0 不一致**（GH 实时、beads 实时、SSOT、Plan 文档四方吻合）
- **40/40 CLOSED**（GitHub `plan008` issues #1132-#1171）
- **40/40 closed**（beads `plan008` issues）
- **T008.039/T008.040 release evidence**：`v0.2.0` / workflow `28126779885` / `release_closeable=YES`
- **0 open Plan008 issue**
- binance 仓旧 issue 40 个全部 CLOSED，无活跃重复
- binance PR #145 仍为 OPEN；这是代码同步 PR 状态，不是 Plan008 issue 遗留

---

## 6. beads GitHub 同步说明

`[KNOWN, HIGH]` beads 与 GitHub 的同步机制（基于实测）：

- beads `external_ref` 字段（格式 `gh-N`）建立 **beads→GitHub 单向追溯**
- `bd github push/pull/sync` 是独立机制，**不读取 `external_ref`** 匹配，会按标题/URL 匹配，全量 sync 会引入无关 issue 污染
- **正确做法**：手动维护 `external_ref` + `gh issue` 双向操作，**不使用** `bd github sync`（已验证会导致 193 push + 106 import 的重复污染）
- beads github 配置已设为 `ZoneCNH/ZoneCNH`，但仅用于 `bd github status` 显示，不作为自动同步依据

### 关闭 issue 的双向操作

```bash
# 完成一个 Task 时，两边都操作
bd close ZoneCNH-hdw --reason="T008.001 完成"
gh issue close 1132 --repo ZoneCNH/ZoneCNH --reason completed
```

---

## 7. 制品清单

| 制品 | 用途 |
| --- | --- |
| `plans/binance/008-tasks.json` | SSOT — 40 Task 结构化数据 |
| `plans/binance/008-gh-issue-map.tsv` | Task ID → GitHub issue 编号映射（#1132-1171） |
| `plans/binance/008-beads-issue-map.tsv` | Task ID → beads ID → GitHub 编号映射 |
| `plans/binance/008-create-gh-issues-zonecnh.sh` | ZoneCNH issue 创建脚本（可复现） |
| `plans/binance/008-create-beads-issues.sh` | beads issue 创建脚本 |
| `plans/binance/008-update-beads-extref.sh` | beads external_ref 迁移脚本 |
| `plans/binance/008-add-beads-deps.sh` | beads 依赖链接脚本 |
| `plans/binance/008-verify-10rounds.sh` | 10 轮三方一致性核验脚本 |
| `plans/binance/008-verify-faithfulness.sh` | SSOT 忠实性核验脚本 |
| `plans/binance/008-issues-sync-report.md` | 本报告 |

---

`[RULES I BROKE]`：

1. **§20 真实性 — 仓库判断错误并纠正**：初始误将 issue 建至 `ZoneCNH/binance`（#105-144），经用户指正后迁移至 `ZoneCNH/ZoneCNH`（#1132-1171）。旧 issue 已全部关闭，本报告 §2.2 完整记录了迁移过程。这是我的判断失误，已公开纠正。
2. **§20 证据标签**：所有 `[COMPUTED, HIGH]` 声明基于核验脚本输出 + 实时 GitHub/beads API 查询。核验脚本 Round 8 曾因逐个 API 调用触发限流而偶发失败，已修复为批量查询。
3. **beads github sync 机制**：§6 基于 `bd github sync --dry-run` 实测得出"全量 sync 会污染"的结论（193 push + 106 import），这是 `[COMPUTED, HIGH]` 的实测证据，据此选择手动双向维护而非自动 sync。
