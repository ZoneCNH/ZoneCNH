# Binance 25-issue full closure review — PR #910

- Date: 2026-06-23
- Author: leader integration (agent team execution)
- Scope: historical PR #910 closure audit of all 25 open GitHub binance issues (#866~#896); not current Beads closure evidence.
- Source: historical `gh issue list --state open` (pre-closure) + `module/binance/` SSOT + PR #910 diff.
- Prior slice: `governance-closure-20260623.md` (worker-3, 6 issues).

> [COMPUTED, HIGH] **2026-06-23 当前状态覆盖声明**：本报告是历史 PR #910 闭环证据，不是当前 Beads closure evidence。当前本地 Beads audit 仍有 9 个 binance open issues（ZoneCNH-awc, ZoneCNH-n0s, ZoneCNH-4h5, ZoneCNH-7un, ZoneCNH-8ep, ZoneCNH-97r, ZoneCNH-h1p, ZoneCNH-t51, ZoneCNH-azf）；runtime/release evidence Pending。
>
> [COMPUTED, HIGH] PR #910 历史口径：25 个 GitHub issue 全部 closed；GitHub open count = 0。核查基线为 `module/binance/SPEC.md` v3.1.0（commit c158fc86 + PR #910）。
>
> [COMPUTED, HIGH] Post-PR #936 note: this report covers #866~#896 only and does not close #925/#930/#931. Read it with `pr-936-governance-docs-closure-20260623.md` before treating any PR #910 projection as current backlog.

---

## 1. Closure summary

| 维度                              | 值                                                             |
| --------------------------------- | -------------------------------------------------------------- |
| 待处理 open issues（pre-closure） | 25（#866~#873, #879~#896）                                     |
| 已修复确认（核查）                | 19                                                                |
| 本次补齐残留                      | 3（#871, #872, #895）                                         |
| FR 语义对齐（讨论稿层）           | 13（#879~#892）                                                    |
| PR                                | #910（squash merged 2026-06-23）                              |
| release manifest bump             | v1.13.0 → v1.13.1（PATCH）                                     |
| 验证                              | check-binance-docs.sh PASS；audit-status.py 52 passed 0 failed |
| post-closure open count           | 0                                                              |

---

## 2. Per-issue final status

### 2.1 P0 漂移（#866/#867/#868/#873）

| Issue                                  | 判定                      | 证据                                                                                                                   |
| -------------------------------------- | ------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| #866 P0-2 NATS subject 缺 3 trade 组合 | ✅ 已修复                 | RUNTIME-MAPPING.md 含 16 个 `binance.market.{pl}.{et}` 组合（含 spot/um_perp/cm_perp/options × trade）                 |
| #867 P0-1 README 版本漂移              | ✅ 已修复（PR #910 同步） | README.md `Spec-Version: v3.1.0`；STATUS/README/ARCHITECTURE 三文档同步 v3.1.0                                         |
| #868 P0-3 Kafka topic 漂移             | ✅ 已修复                 | SPEC/ACCEPTANCE/RUNTIME-MAPPING 的 Kafka topic 全为 `binance.{pl}.{et}.v1`；`binance.market.*` 仅 natsx subject 上下文 |
| #873 P0-4 RULES 任务文件名             | ✅ 已修复                 | RULES.md R2 引用 `kafkax-dispatch` / `ossx-archiver`（与实际 task 文件名一致）                                         |

### 2.2 P0/P1 治理（#870/#871/#872）

| Issue                     | 判定        | 本次动作                                                                    | 证据                                                                                            |
| ------------------------- | ----------- | --------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| #870 P1-1 检查脚本        | ✅ 已修复   | —                                                                           | `scripts/check-binance-docs.sh` 存在且 PASS（覆盖 R1/R2/R6/R9 + FR-030/AC-104/TC-049/120-cell） |
| #871 P3 STANDARD.md       | ⚠️ 本次补齐 | Status Draft→Active (v0.1.1)；RULES R9 收录 STANDARD.md + DATA-LIFECYCLE.md | STANDARD.md Active；RULES.md R9 表含两行                                                        |
| #872 P0-5 状态 L1/L2 分层 | ⚠️ 本次补齐 | ACCEPTANCE.md + FEATURES.md 新增 L1/L2 状态口径图例（RULES R4）             | ACCEPTANCE.md §2 图例表；FEATURES.md 状态说明段                                                 |

### 2.3 G-14 + R-01~R-13（#879~#892，13 issues）

| Issue                           | 判定                      | 证据                                                                                 |
| ------------------------------- | ------------------------- | ------------------------------------------------------------------------------------ |
| #879 G-14 DATA-LIFECYCLE 讨论稿 | ✅ 已修复（PR #910 扩充） | DATA-LIFECYCLE.md v3.5.0 含 15 缺口 + FR-012~030 + §6 issue→FR 映射 + §7 FR-025~030 登记口径 |
| #880~#892 R-01~R-13             | ✅ 已修复（追溯登记）     | TRACEABILITY.md 含 FR-012~030 + AC-048~104 + TC-029~049                              |
| #888 R-09 event_type 4→6        | ✅ 已修复                 | NAMING.md 4×6=24 矩阵 + TRACEABILITY 120-cell matrix + funding/mark_price event_type |

> [FRAME, HIGH] #880~#892 的 issue 标题语义（Symbol Discovery/Backfill/Reconciliation/Rehydration/Progress API）是 2026-06-22 早期提案；DATA-LIFECYCLE §4 review 已将它们重组为 FR-012~024（runtime-control + lifecycle 语义）。当前 §7 已声明 FR-025~FR-030 规格层登记口径；runtime/release evidence 仍 Pending，不能据此关闭当前 Beads 实现项或 release DoD。

### 2.4 G-09~G-12 文档整理（#893/#894/#895/#896）

| Issue                         | 判定                          | 本次动作                                | 证据                                                        |
| ----------------------------- | ----------------------------- | --------------------------------------- | ----------------------------------------------------------- |
| #893 G-09 §0 升 SPEC §4       | ✅ 已修复（PR #910 修正引用） | SPEC §88 `见 §0`→`见 §4 Goals`          | SPEC.md §4 Goals 分布式约束小节 + DEEP-ANALYSIS §0 迁移引用 |
| #894 G-10 §12 迁移 migrations | ✅ 已修复                     | —                                       | `docs/migrations/binance-v2-upgrade.md` + INDEX.md 收录     |
| #895 G-11 binance-market 压缩 | ⚠️ 本次补齐                   | RULES R1 例外清单补 BR-001 边界声明豁免 | RULES.md R1 BR-001 豁免段                                   |
| #896 G-12 commit 覆盖审计     | ✅ 已修复                     | —                                       | `docs/report/binance/commit-coverage-audit-20260623.md`     |

---

## 3. Current residual actions（runtime/release evidence）

> [FRAME, HIGH] 以下为当前残留动作：FR-025~FR-030 已登记，但仍需要 runtime feature tests、CI/live evidence 与 release evidence 才能关闭。

| FR             | 标题                                      | Landing                            | Bump  | 覆盖 issue / Beads |
| -------------- | ----------------------------------------- | ---------------------------------- | ----- | ---------- |
| FR-025         | Backfill Throttle & Priority              | `server/SPEC.md` §7 throttle       | MINOR | #886       |
| FR-026         | Daily Reconciliation Job                  | `server/SPEC.md` §7 reconciliation | MINOR | #889       |
| FR-027         | Cold Data Rehydration                     | `SPEC.md` FR-007 扩展              | MINOR | #890       |
| FR-028         | Backfill Progress API                     | `server/SPEC.md` §7 admin API      | MINOR | #891       |
| FR-029         | Data Quality & Freshness SLA              | `SPEC.md` / `TRACEABILITY.md` / runtime evidence | MINOR | Beads P2-2 |
| FR-030         | Options Chain Raw Field Pass-through      | `SPEC.md` / `TRACEABILITY.md` / NAMING subject matrix | MINOR | Beads P2-4 |
| NAMING §2      | 订阅周期集枚举                            | `NAMING.md` §2                     | PATCH | #882       |
| NAMING subject | `instruments.changed` + `symbols.changed` | `NAMING.md` §3                     | MINOR | #880, #892 |
| FR-015 扩展    | depth 订阅档位 + update_id 拼合           | `SPEC.md` §9                       | MINOR | #883       |

---

## 4. Verification

| 检查               | 命令                                               | 结果                               |
| ------------------ | -------------------------------------------------- | ---------------------------------- |
| binance 文档漂移   | `bash scripts/check-binance-docs.sh`               | PASS（binance docs checks passed） |
| 仓库数量门禁       | `python3 scripts/audit-status.py --network`        | 52 passed, 0 failed                |
| 三文档版本一致     | `grep binance STATUS.md README.md ARCHITECTURE.md` | 全 v3.1.0                          |
| Historical GitHub PR #910 issue state | PR #910-era `gh issue list --state open` evidence | historical 0；not current Beads state |

---

## 5. Known gaps intentionally not hidden

1. **FR-025~FR-030 已登记但 runtime/release evidence 未闭合**：当前闭环只完成文档追溯，不关闭功能实现或 release DoD。
2. **runtime 证据**：FR-012~024 全部 Pending（runtime 仓未推送功能实现），L2 状态默认 `Pending — 以 runtime 仓为准`。
3. **#896 PR/head 覆盖**：`commit-coverage-audit-20260623.md` 仅本地 git 证据，GitHub PR/head lineage 仍需权威映射（见 governance-closure §5 gap 1）。

[RULES I BROKE]：无 — 本报告是 PR #910 闭环证据，仅新增到 `docs/report/binance/`；所有事实基于 gh CLI + grep + check 脚本验证。
