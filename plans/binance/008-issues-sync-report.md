# Plan 008 Issues 同步一致性报告

> beads issues ↔ GitHub issues ↔ Plan 008 Task 三方一致性核验报告
>
> - 日期：2026-06-26
> - Plan：`plans/binance/008-binance-production-fix-master-plan.md`
> - SSOT：`plans/binance/008-tasks.json`
> - **GitHub 仓库：`ZoneCNH/ZoneCNH`**（issues #1132-#1171）
> - beads workspace：`ZoneCNH`（prefix=ZoneCNH，label `plan008`）
> - Plan Runtime-Anchor：`/home/binance@3f20be0`（Plan 输入基线）
> - Execution Runtime-Anchor：`/home/binance@e32a126391ab03dcddcbc31945fcf2dc757e8025`（Plan008 最新本地 follow-up）
> - Remote CI Anchor：`ZoneCNH/binance#145@a991c46c7959ad533196e9392c90a04734de2eda`（Plan008 PR CI 修复证据）

---

## 1. 执行摘要

`[COMPUTED, HIGH]` Plan 008 的 **40 个 Task**（T008.001-T008.040）已完整拆解为可追踪的 issue 体系：

| 维度 | 数量 | 位置 |
| --- | --- | --- |
| Plan Task（SSOT） | 40 | `008-tasks.json` |
| GitHub issues | 40 | **`ZoneCNH/ZoneCNH`** #1132-#1171（当前权威状态：38 closed / 2 open；#1170/#1171 release-gated open，label `plan008`） |
| beads issues | 40 | ZoneCNH workspace（当前状态：38 closed / 2 open；label `plan008`，external-ref `gh-N`） |
| 依赖链接（beads） | 25 | `bd link --type blocks` |
| 覆盖缺口 G1-G9 | 9/9 | 全部有 Task |
| 覆盖标准 S1-S35 | 35/35 | 全部有 Task |
| 覆盖里程碑 M1-M4 | 4/4 | 全部有 Task |

**映射 100% 一致，0 遗漏；release-gated 状态需保守处理。**

### 1.1 Plan008 执行闭环（2026-06-26）

`[COMPUTED, HIGH]` GitHub 与 Beads 实时复核显示 #1132-#1171 / T008.001-T008.040 均为 38 closed、2 open。T008.001-T008.038 已完成闭合；T008.039/T008.040 保持 release-gated open，因为 `release/evidence/binance/20260625-task2/external-gates.log` 仍记录 `release_tag=NOT_CAPTURED` 与 `release_closeable=NO`。最新本地 follow-up 已补 options expiry aggregate normalization、bounded combined options live selector、optionTicker exact-key parsing 与 `BINANCE_OSSX_LIVE` archive/list/delete opt-in gate；`live-gates-20260626.txt` 已记录 Options WS 和 OSSX live I/O captured。

| Evidence | Result |
| --- | --- |
| Binance runtime PR | [ZoneCNH/binance#145](https://github.com/ZoneCNH/binance/pull/145) @ `a991c46c7959ad533196e9392c90a04734de2eda`（remote CI anchor） |
| Binance local follow-up | `/home/binance/.worktree/workspaces/fix/plan008-production-fixes` @ `e32a126391ab03dcddcbc31945fcf2dc757e8025`（options aggregate normalization + bounded Options live selector + `efb63f8` exact-key parser + OSSX live gate；本地 changed-package 10 轮 PASS） |
| Foundation PRs | [taosx#18](https://github.com/ZoneCNH/taosx/pull/18) @ `6dd70cb`; [natsx#19](https://github.com/ZoneCNH/natsx/pull/19) @ `6bbfda0`; [kafkax#20](https://github.com/ZoneCNH/kafkax/pull/20) @ `7b2d9ce`; [clickhousex#11](https://github.com/ZoneCNH/clickhousex/pull/11) @ `457d9ff` |
| Local runtime gates | `gofmt -l cmd internal pkg test tools`; `git diff --check`; `./scripts/readiness-audit.sh`; `go test ./...`; `go test -race ./...`; `go vet ./...`; `golangci-lint run`; `govulncheck ./...`; `runtime-release-evidence.sh` 全 PASS |
| Remote CI | 截至 2026-06-26 01:14 +0800，GitHub Actions for PR #145: Boundary Gates, Build & Vet, Test & Race & Cover, gitleaks, golangci-lint, govulncheck 全 PASS |
| T008.011 local fix | [#1142 evidence comment](https://github.com/ZoneCNH/ZoneCNH/issues/1142#issuecomment-4802133265)；`go test ./internal/client -run 'TestHistoryRuntimePersistsAndRestoresState\|TestPostgresHistoryStateStore\|TestResolveStandaloneConfigModeAndOverrides' -count=1`；`go test ./cmd/binance-client ./internal/client -count=1`；migration 006 实际 schema 为 `history_runtime_state(snapshot JSONB)` |
| External gates | `release_closeable=NO`; live gate evidence in `live-gates-20260626.txt`: JetStream ack/ManualAck/NAK captured, taosx/postgresx/redisx/clickhousex assembly captured, Kafka broker roundtrip captured, Binance Spot/bookTicker/UM/CM/Options WS captured, OSSX archive live I/O captured; release tag evidence remains uncaptured |

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
| 重建 issue | ZoneCNH/ZoneCNH | #1132-#1171（40 个） | ✅ 已重建；当前 #1132-#1169 closed，#1170/#1171 release-gated open |
| 更新 beads external_ref / description | ZoneCNH workspace | 40 个 issue | ✅ gh-105~144 → gh-1132~1171；description 内 GitHub 引用已归一到 `ZoneCNH/ZoneCNH` |
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
| 1 | 数量一致：SSOT(40)==GH(40)==beads(40) | ✅ |
| 2 | 每个 SSOT task_id 在 GH map 有记录 | ✅ |
| 3 | 每个 SSOT task_id 在 beads map 有记录 | ✅ |
| 4 | GH 编号唯一连续（#1132-#1171） | ✅ |
| 5 | beads ID 全部唯一（40） | ✅ |
| 6 | 每个 beads external_ref 与 GH 编号匹配（实时查询） | ✅ |
| 7 | GH map 编号集合 == GH 实时编号集合（精确匹配） | ✅ |
| 8 | 每个 GH issue 标题含 [task_id]（批量查询） | ✅ |
| 9 | 9 个数据缺口 G1-G9 全覆盖 | ✅ |
| 10 | 35 标准 S1-S35 + 4 里程碑 M1-M4 全覆盖 | ✅ |

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

`[COMPUTED, HIGH]` 经 **17 轮多维核验**，最终运行 10/10 + 7/7 全通过：

- **40/40 Task** 三方映射完整
- **0 遗漏**（9 缺口 + 35 标准 + 4 里程碑 = 48 项 100% 覆盖）
- **映射 0 不一致**（GH 实时编号、Beads external_ref、SSOT、Plan 文档四方吻合）
- **Release-gated 状态仍需保守处理**：#1132-#1169 当前已关闭；#1170/#1171 保持 open。后续完成判定以 GitHub issue 状态、代码验证和 Plan DoD 为准。
- binance 仓旧 issue 40 个全部 CLOSED，无活跃重复

### 5.4 执行同步更新（2026-06-26）

`[COMPUTED, HIGH]` 截至 2026-06-26 实时复核，GitHub #1132-#1171 与 Beads Plan008 项均为 38 closed / 2 open。#1170/#1171 已补 partial-live blocker 评论并保持 open。

`[COMPUTED, HIGH]` 本轮新增 T008.011/#1142 的代码证据评论；以下为本报告可直接追溯的关闭/证据补充记录。

| Task | GitHub | Beads | 关闭依据 |
| ---- | ------ | ----- | -------- |
| T008.011 | #1142 | `ZoneCNH-8kt` | `go test ./internal/client -run 'TestHistoryRuntimePersistsAndRestoresState\|TestPostgresHistoryStateStore\|TestResolveStandaloneConfigModeAndOverrides' -count=1`；`go test ./cmd/binance-client ./internal/client -count=1`；[#1142 evidence comment](https://github.com/ZoneCNH/ZoneCNH/issues/1142#issuecomment-4802133265)；migration 006 实际 schema 为 `history_runtime_state(snapshot JSONB)` |
| T008.013 | #1144 | `ZoneCNH-y941` | `go test -count=1 ./internal/server/deadletter -run 'TestFileWriter_(Write_OK\|Idempotent\|EmptyID_Error)'`；`go test -count=1 ./internal/server -run 'TestAppendDeadLetterWritesConfiguredFileWriter'`；`go test -count=1 ./internal/server/consumer -run 'TestRunnerWritesDeadLetterBeforeTerminalReject'` |
| T008.024 | #1155 | `ZoneCNH-ugsm` | `go test -count=1 ./internal/server/storage/olap -run 'TestEnsureSchema_ExecsDDL'` 验证 `ReplicatedMergeTree` DDL |
| T008.025 | #1156 | `ZoneCNH-x6an` | `go test -count=1 ./internal/server/storage/olap -run 'TestEnsureSchema_ExecsDDL'` 验证 ClickHouse TTL DDL |
| T008.029 | #1160 | `ZoneCNH-jfma` | `go test -count=1 ./internal/server -run 'TestDefaultValidator(RejectsInvalidSchemaVersion\|AcceptsSupportedSemanticSchemaVersion)'` |
| T008.032 | #1163 | `ZoneCNH-z9sa` | `go test -count=1 ./internal/server/controlplane -run 'TestLifecycle_(DrainWaitsInFlightAndAudits\|DrainTimeoutRecordsError\|AuditRecentExposesAllActions)'` |

| 系统 | total | closed | open | 判定 |
| ---- | ----- | ------ | ---- | ---- |
| GitHub | 40 | 38 | 2 | 权威执行状态 |
| Beads | 40 | 38 | 2 | 本地追踪状态已同步到 release-gated open |

`[INFERRED, HIGH]` 剩余 2 个 GitHub issue 不应关闭，原因是 strict DoD 的 release/live gate 仍缺外部证据。

- Release-gated open：T008.039、T008.040；GitHub partial-live comments: [#1170](https://github.com/ZoneCNH/ZoneCNH/issues/1170#issuecomment-4802238741), [#1171](https://github.com/ZoneCNH/ZoneCNH/issues/1171#issuecomment-4802238748)。
- 已捕获进展：本地 JetStream PubAck/duplicate/ManualAck/NAK；dev storage assembly（taosx/postgresx/redisx/clickhousex）；Kafka broker produce/consume；Binance Spot/bookTicker/UM/CM/Options WS；`BINANCE_OSSX_LIVE` archive/list/delete。
- 关键缺口：release tag artifact / release publication evidence 尚未归档；T008.039/T008.040 因此保持 release-gated open。

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
