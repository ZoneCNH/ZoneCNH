> ⚠️ **DEPRECATED** — 本文件已退役（v3.8.0），所有活跃内容已合并至 [`SPEC.md`](SPEC.md) §7 FR-012~FR-030。仅保留为历史参考，不作为活跃规范。

# module/binance DATA-LIFECYCLE.md — 数据生命周期（已退役）

## 元数据

| 字段 | 值 |
| --- | --- |
| Status | Retired（原 Formal Proposal — 2026-06-26 退役） |
| Module-Version | v3.8.0 |
| Last-Updated | 2026-06-26 |
| Scope | `module/binance` stage2 lifecycle planning |
| Spec-Impact | 已 fold：FR-012~FR-030 已登记到 `SPEC.md`/`TRACEABILITY.md`，相关命名落点已投影到 `NAMING.md`；本文件仍不声明 runtime contract |
| Source Plan | `report/binance/goal-execution-plan-20260622.md` 阶段 2 / AC-3 |

> §1-§8 内容（15 个生命周期缺口、13 个 FR 落点、issue 映射、版本影响矩阵）已合并至 [`SPEC.md`](SPEC.md) §7 FR-012~FR-030。以下仅保留 §9 Issue #926 形式化闭合备忘录作为历史证据。

## 9. Issue #926 形式化闭合备忘录（2026-06-23）

> [COMPUTED, HIGH] 本文件四项形式化 acceptance criteria 全部满足，Issue #926 可从 governance/documentation 层面关闭。Runtime 实现仍为 Pending，由 #927~#929 追踪。

### 9.1 Acceptance Criteria 逐项验证

| AC | 内容 | 验证结果 | 证据 |
| --- | --- | --- | --- |
| AC-1 | FR-012~FR-029 具备可追溯的 FR/AC/TC/BR 覆盖 | PASS | `SPEC.md` §7 FR->AC 映射表 FR-012~FR-030 全部登记；`TRACEABILITY.md` §4 TC->FR / §5 AC 注册表；`ACCEPTANCE.md` §2 AC-048~AC-104 |
| AC-2 | event_type 4->6 影响与 MINOR/MAJOR 版本决策显式化 | PASS | 本文件 §8 版本影响矩阵：event_type 行明确记录 4->6 影响、MAJOR 判定条件、Pending 状态与关闭证据路径 |
| AC-3 | 旧 issue #880~#892 不再作为当前生效合约 | PASS | 本文件 §6 逐条映射旧 issue -> 新 FR；§7 登记 FR-025~FR-030 + NAMING 补充；全部旧编号已有明确 FR 承接，不再引用为当前合约 |
| AC-4 | DATA-LIFECYCLE 从草案转为正式提案 | PASS | 本文件 Status 已从 `Governance Registered` 升级为 `Formal Proposal`；§3 review checklist 全 [x]；§4 review outcome 已闭单 |

### 9.2 闭合口径

**Issue #926 可关闭，依据如下：**

1. FR-012~FR-030 已正式登记到 `SPEC.md` / `TRACEABILITY.md`（v3.5.0），具备完整的 FR/AC/TC 追溯链
2. 版本影响台账（§8）完整覆盖 event_type、tables、topics/subjects、metrics、version ledger 五个切面
3. 旧 issue #880~#892 到新 FR 的映射（§6-7）已补齐，旧编号不再作为独立合约存在
4. Review checklist（§3）全部 [x]，review outcome（§4）已记录闭单结论

**Runtime 免责声明（重要）：**

- [FRAME, HIGH] 本闭合仅涵盖治理/文档形式化。FR-012~FR-030 的 runtime 实现、测试证据、CI pass、release evidence、live smoke 仍为 Pending
- Runtime 实现进度由以下 issues 追踪：
  - **#927** — FR-012~FR-015: stream session lifecycle、reliability controls、observability、pause/resume/drain
  - **#928** — FR-016~FR-024: backfill、gap replay、archive、funding-rate/mark-price、reconciliation、rehydration、hot reload
  - **#929** — FR-025~FR-030: throttle、daily reconciliation、cold rehydration、progress API、freshness SLA、Options raw field
- 任一 FR 翻转为 Done 前必须通过：Spec -> Review -> Matrix -> Tasks -> Plan -> Prompt -> Code 管线、runtime 测试证据、CI/live smoke 和 release gate
- 不得将本备忘录视为 runtime behavior、CI pass、GitHub Release 或 release evidence 完成证明
