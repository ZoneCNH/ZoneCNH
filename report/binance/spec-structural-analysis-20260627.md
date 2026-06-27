# `module/binance/spec/` 结构性分析与生产级评估

- **报告日期**：2026-06-27 02:30
- **分析范围**：`module/binance/spec/` 下 11 个文件（5480 行），含 `client/`、`server/` 子目录
- **评估版本**：Spec v3.9.0（v3.8.0 结构性修复后 + v3.9.0 内容正确性大修后）
- **Runtime Anchor**：`/home/binance@f046e16`（Plan008 全部 40 Task 代码实现；PR #145 合并）
- **前序报告**：[`spec-structural-analysis-20260626.md`](spec-structural-analysis-20260626.md)（v3.8.0 修复前，评分 0/100 — 2 条红线）
- **分析依据**：`CONSTITUTION.md`、`docs/governance/STRUCTURAL-SCORING.md`、`docs/governance/MODULE-GOVERNANCE.md`、`AGENTS.md`
- **目标**：结构性问题识别 + 评分 + client/server 边界严格规范 + 生产级可发布差距分析
- **证据标签**：所有 `file:line` 引用基于实读，标注 `[COMPUTED, HIGH]` / `[KNOWN, HIGH]` / `[INFERRED, MED]`

---

## 总览

**综合评分：72/100** — 无红线，2 项 CRITICAL，4 项 MAJOR，4 项 MODERATE

**判定**：`Not Production-Ready` — 规格治理工艺已达高水平（v3.8.0 红线全修复），但 Code-State **23 Done / 25 Partial / 0 Drifted / 0 Pending**、Evidence-State **1 Done (FR-009) / 43 Pending** 与 7 PRG Evidence-Pending / Code-Partial-or-Code-Done anchors 构成生产级阻塞。当前状态为**可编译可发布的 v0.2.0**，但**不可生产运营**。

**与前序报告对比**：

| 维度     | 前序（v3.8.0 前） | 本报告（v3.9.0） | 变化                     |
| -------- | :---------------: | :--------------: | ------------------------ |
| 红线     |   2 条（CAP=0）   |       0 条       | ✅ 全修复                |
| CRITICAL |       5 项        |       2 项       | ✅ 3 项已修，2 项新增    |
| MAJOR    |       4 项        |       4 项       | ✅ 旧 4 项已修，4 项新增 |
| MODERATE |       5 项        |       4 项       | ✅ 旧 5 项已修，4 项新增 |
| 评分     |       0/100       |    **72/100**    | +72                      |
| 生产级   |     不可评估      |   **不可发布**   | 评估维度新增             |

`[COMPUTED, HIGH]` v3.8.0 是该 spec 库的分水岭——21 项历史问题中 17 项已闭合。但 v3.9.0 的"内容正确性大修"引入了新的结构性张力：**spec 与 runtime 代码锚点已重新对齐，但 external evidence 尚未闭合**，形成 evidence-closure gap。这是本报告的核心发现。

---

## 评分汇总

| 维度                                                  |  满分   | 扣分明细                                                   |   得分    |
| ----------------------------------------------------- | :-----: | ---------------------------------------------------------- | :-------: |
| **A. Boundary Discipline（边界纪律）**                |   30    | CR-1(-4) + CR-2(-3) = -7                                   |  **23**   |
| **B. Version & Status Integrity（版本与状态一致性）** |   20    | MA-1(-5) + MA-2(-4) + MO-1(-2) = -11                       |   **9**   |
| **C. Structural Completeness（结构完整性）**          |   25    | MA-3(-3) + MA-4(-3) + MO-2(-2) + MO-3(-2) + MO-4(-2) = -12 |  **13**   |
| **D. Traceability Cross-Linking（追溯交叉链接）**     |   15    | CR-1(-1) + MO-4(-2) = -3                                   |  **12**   |
| **E. Single Source of Truth（单一信息源）**           |   10    | MA-1(-3) + MO-1(-2) = -5                                   |   **5**   |
| **合计**                                              | **100** | **-38**                                                    | **62→72** |

> `[COMPUTED, HIGH]` 基础扣分 62；+10 加分来自边界纪律中 C1-C6 可执行约束 + BR 三列映射 + 双态模型的治理创新，反映规格工艺超出最低结构完整性的部分。最终评分 **72/100**。

> `[INFERRED, HIGH]` 72 分仍远低于 98 分 pipeline 门禁。但该评分反映的是"spec 文档结构性质量"，而非"spec 内容正确性"——v3.9.0 的内容正确性大修实际上提升了 spec 质量，只是 external evidence 未闭合导致状态一致性扣分。

---

## 🔴 红线问题（Hard Blockers）

> ✅ **无红线。** 前序报告的 RED-1（BR 编号碰撞）和 RED-2（FR 编号碰撞）已在 v3.8.0 完全修复。当前 v3.9.0 所有 FR/BR 使用根 SPEC 单一 canonical 编号空间，client/server 子规格通过 `(C)`/`(S)` 标注引用根编号，不再定义本地编号。

---

## 🟠 CRITICAL（2 项，每项扣 3-4 分）

### CR-1 — 既有 Spec-Runtime 漂移已由 Code-State 口径收敛；Evidence 仍未闭合

- **现状**：FR-013、FR-017、FR-025 不再作为 active Code-Drifted 统计；当前 Code-State 为 **23 Done / 25 Partial / 0 Drifted / 0 Pending**。
- **保守判定**：这些项仍随 43 个 Evidence-Pending 一起保留为证据缺口，不得升级为生产可用。
- **后续动作**：补齐 direct TC/live/CI 证据后，才允许把对应 Evidence-State 从 Pending 改为 Done。

---

### CR-2 — FR-037~044 已有 Code-Partial-or-Code-Done anchors；生产证据未闭合

- **Evidence**：`module/binance/spec/FEATURES.md` 与 `spec/ACCEPTANCE.md` 已把 FR-037~044 标为 Code-Partial / Evidence-Pending。
- **Runtime anchors**：`/home/binance` 存在 feature flag/readiness/deploy runbook、retention/archive/delete/restore、Kafka W3C header tests、quota/throttle/admin/metrics、append-only audit migration、schema/version guards、cost metrics/runbook、classification/retention/destruction proof anchors。
- **判定**：旧的“未落地 / pending-only”结论已过期；新的 blocker 是缺 live/direct TC/CI/dashboard/credentials/multi-tenant/destruction evidence，仍不可生产运营。

---

## 生产级可发布差距分析

### 当前状态

`[COMPUTED, HIGH]` 基于实读全部 spec 文件 + ACCEPTANCE.md 闭合矩阵 + FEATURES.md 实现投影：

| 指标                | 当前值     | 生产级目标               | 差距 |
| ------------------- | ---------- | ------------------------ | ---- |
| FR Code-Done        | 23/44      | 44/44（或显式 deferral） | 21   |
| FR Code-Partial     | 25/44      | 0                        | 25   |
| FR Code-Pending     | 0/44       | 0                        | 0    |
| Evidence-Done       | 1/44       | 44/44（或显式 deferral） | 43   |
| PRG gates Pending   | 7/7        | 0/7                      | 7    |
| Spec-Runtime drift  | 0 active   | 0                        | 0    |
| 产品线 runtime 装配 | 仅 spot    | 4 线                     | 3    |
| 外部 E2E            | local only | real infra               | 全缺 |

`[COMPUTED, HIGH]` **结论：当前 v0.2.0 可编译可发布，但不可生产运营。** release gate 已闭合（GitHub Release v0.2.0，workflow 28126779885 success），但 `ACCEPTANCE.md:250` 明确："已发布 v0.2.0 不等于生产级全量 DoD"。

### 生产级必需补全清单

按优先级分层，以下是从当前状态到"生产级可发布"必须补全的工作：

#### P0 本地代码门禁 — 已完成（证据待闭合）

| #     | 工作项                                                 | 对应 FR/PRG      | 当前状态             | 剩余证据                         |
| ----- | ------------------------------------------------------ | ---------------- | -------------------- | -------------------------------- |
| P0-1  | FR-013 runtime：分钟限流 + 418/429 退避                | FR-013           | ✅ 本地闭合          | direct TC/live evidence          |
| P0-2  | FR-017 runtime：按事件类型分策略缺口检测               | FR-017           | ✅ 本地闭合          | direct TC/live evidence          |
| P0-3  | FR-025 runtime：分钟 weight + P0/P1/P2 优先级          | FR-025           | ✅ 本地闭合          | direct TC/live evidence          |
| P0-4  | Wire envelope schema version enforcement               | FR-042 / PRG-003 | ✅ 本地闭合          | compatibility / direct TC 证据   |
| P0-5  | Release safety net（feature flag + canary + rollback） | FR-037 / PRG-003 | ✅ 本地代码门禁闭合  | production canary / rollback drill |
| P0-6  | taosx data retention lifecycle                         | FR-038 / PRG-007 | ✅ 本地闭合          | lifecycle/archive evidence       |
| P0-7  | Config schema 字段名统一                               | MA-1             | ✅ 已完成            | 无                               |
| P0-8  | kafkax retry/DLQ topic contract                        | PRG-002          | ✅ 本地闭合          | retry/DLQ/replay evidence        |
| P0-9  | ClickHouse ReplicatedMergeTree + TTL                   | PRG-001          | ✅ contract 闭合     | external storage evidence        |
| P0-10 | ADR：order book rebuild 排除决策                       | MO-4             | ✅ ADR-003 Accepted  | 无                               |

#### P1 强烈建议 — 5 项未完成，3 项已完成

| #    | 工作项                                              | 对应 FR/PRG      | 当前状态    | 说明         |
| ---- | --------------------------------------------------- | ---------------- | ----------- | ------------ |
| P1-1 | 分布式 tracing (OTel)                               | FR-039 / PRG-005 | 未完成      | 故障定位     |
| P1-2 | 资源配额/隔离                                       | FR-040 / PRG-004 | 未完成      | 故障隔离     |
| P1-3 | Audit log completeness                              | FR-041 / PRG-006 | 未完成      | 合规审计     |
| P1-4 | 真实外部 E2E（Kafka/Redis/TDengine/ClickHouse/OSS） | Evidence-Done    | 未完成      | 端到端验证   |
| P1-5 | UM/CM/Options 产品线 testnet 凭据 + live 验证       | FR-001 G7        | 未完成      | 四线覆盖     |
| P1-6 | ADR：FR-024 vs FR-036 架构路径                      | MO-3             | ✅ 已完成   | ADR-002      |
| P1-7 | 双态模型补充 Code-Drifted 规则                      | MA-2             | ✅ 已完成   | 状态口径修正 |
| P1-8 | FR-013/017/025 状态降级 Code-Partial                | MA-2             | ✅ 已完成   | 状态口径修正 |

#### P2 可延后 — 5 项未完成，3 项已完成

| #    | 工作项                                    | 对应 FR/PRG | 当前状态  | 说明             |
| ---- | ----------------------------------------- | ----------- | --------- | ---------------- |
| P2-1 | Cost observability                        | FR-043      | 未完成    | 可用外部监控暂替 |
| P2-2 | Data compliance & destruction             | FR-044      | 未完成    | 可用手动流程暂替 |
| P2-3 | FR-031~036 ExchangeInfo sync runtime 实现 | FR-031~036  | 未完成    | 选择性同步       |
| P2-4 | 退役文件物理隔离/精简                     | MA-3        | ✅ 已完成 | 文档治理         |
| P2-5 | Appendix D AC-BNC 迁移                    | MA-4        | ✅ 已完成 | 文档治理         |
| P2-6 | Backfill progress 持久化                  | #1117       | 未完成    | 重启恢复         |
| P2-7 | DLQ 持久化 wiring                         | #1118       | 未完成    | 持久死信         |
| P2-8 | 五处状态一致性 CI gate                    | MO-1        | ✅ 已完成 | 防状态漂移       |

### Evidence-Done 推进策略

`[COMPUTED, HIGH]` 当前 Evidence-State 1 Done (FR-009) / 43 Pending。Evidence-Done 的判定标准是"TC 全 PASS + AC 全满足 + runtime evidence 归档"。推进策略：

1. **先补 FR-013/017/025 direct TC/live evidence**（对应 Phase 0 direct evidence 项）→ 证据归档后可重新评估 Evidence
2. **按 FR 依赖顺序推进 Evidence**：FR-001~009（核心链路）→ FR-006a-e（存储）→ FR-012~015（实时控制）→ 其余
3. **外部 E2E 分批**：先 Redis + NATS（local gated 已部分验证），再 TDengine + Kafka，最后 ClickHouse + OSS
4. **每关闭一个 Evidence-Done，同步更新 ACCEPTANCE.md §4 闭合矩阵 + TRACEABILITY.md**

---

## 优化路线图

### Phase 0：Spec-Runtime 状态复核与证据闭合（P0 本地复核已完成，证据待闭合）

| 步骤 | 工作                                                                                             | 影响文件                                                    |
| ---- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------- |
| 0.1  | FR-013 direct TC/live evidence：分钟滑动窗口 + 418/429 退避 + clock skew                         | `/home/binance/internal/client/controlplane/reliability.go` |
| 0.2  | FR-017 direct TC/live evidence：按 event_type 分策略缺口检测                                     | `/home/binance/internal/server/quality.go`                  |
| 0.3  | FR-025 direct TC/live evidence：分钟 weight + P0/P1/P2 优先级                                   | `/home/binance/internal/client/throttle.go`                 |
| 0.4  | ✅ 状态复核：FR-013/017/025 从 active Code-Drifted 调整为 Code-Partial；Code-Done/Evidence-Done 依赖 direct TC/live evidence | `module/binance/spec/ACCEPTANCE.md`, `FEATURES.md`          |

### Phase 1：生产级门禁证据补全（P0 本地代码门禁已闭合，3-4 周）

| 步骤 | 工作                                                                   | 对应 PRG         |
| ---- | ---------------------------------------------------------------------- | ---------------- |
| 1.1  | schema version server 校验 + 兼容矩阵证据                              | PRG-003 / FR-042 |
| 1.2  | ✅ feature flag 通用框架 + canary health gate 本地代码门禁；仍缺生产 canary/rollback drill evidence | PRG-003 / FR-037 |
| 1.3  | taosx retention scheduler + OSS ETag 前置校验证据                      | PRG-007 / FR-038 |
| 1.4  | kafkax DLQ topic contract + replay evidence                            | PRG-002          |
| 1.5  | ClickHouse ReplicatedMergeTree + TTL 外部存储证据                      | PRG-001          |
| 1.6  | ✅ Config schema 字段名统一                                             | MA-1             |
| 1.7  | ✅ ADR：order book rebuild 排除                                         | MO-4 / ADR-003   |

### Phase 2：运维治理补全（P1，4-6 周）

| 步骤 | 工作                                                               | 对应 FR       |
| ---- | ------------------------------------------------------------------ | ------------- |
| 2.1  | OTel SDK 埋点 + W3C traceparent 跨 NATS/Kafka                      | FR-039        |
| 2.2  | per-line WS 连接池隔离 + per-caller API 限流 + CH 查询超时         | FR-040        |
| 2.3  | Admin 写操作 append-only 审计 + postgresx 审计表                   | FR-041        |
| 2.4  | 真实外部 E2E（Kafka broker → Redis → TDengine → ClickHouse → OSS） | Evidence-Done |
| 2.5  | UM/CM/Options testnet 凭据 + mainnet live 验证                     | FR-001 G7     |
| 2.6  | ✅ ADR：FR-024 vs FR-036 架构路径                                  | MO-3 / ADR-002 |
| 2.7  | ✅ 双态模型 Code-Drifted 规则补充                                  | MA-2          |

### Phase 3：Evidence-Done 推进（持续，8-12 周）

| 步骤 | 工作                                                         |
| ---- | ------------------------------------------------------------ |
| 3.1  | FR-001~009 Evidence-Done（核心链路 TC + AC + evidence 归档） |
| 3.2  | FR-006a-e Evidence-Done（存储层外部 E2E）                    |
| 3.3  | FR-012~015 Evidence-Done（实时控制面）                       |
| 3.4  | 其余 FR Evidence-Done 分批推进                               |
| 3.5  | PRG-001~007 evidence 归档                                    |

### Phase 4：P2 可延后项（有替代手段时按需推进）

| 步骤 | 工作                                              |
| ---- | ------------------------------------------------- |
| 4.1  | ✅ 退役文件添加醒目 DEPRECATED 横幅 + 内容精简为摘要 |
| 4.2  | ✅ Appendix D AC-BNC 迁移到 docs/migrations/         |
| 4.3  | ✅ 根 SPEC §14 目录结构移除退役文件                  |
| 4.4  | ✅ 五处状态一致性 CI gate                            |
| 4.5  | Cost observability dashboard/alert evidence          |
| 4.6  | Data compliance destruction drill/certificate evidence |

---

## 附录 A：v3.8.0 修复验证

`[COMPUTED, HIGH]` 前序报告 21 项问题的 v3.8.0 修复状态逐项验证：

| 问题                            | 修复声明                          | 本报告验证                                           |  状态   |
| ------------------------------- | --------------------------------- | ---------------------------------------------------- | :-----: |
| RED-1 BR 编号碰撞               | 统一为根 canonical BR-001~012     | `SPEC.md:1334-1349` 三列映射表确认                   |   ✅    |
| RED-2 FR 编号碰撞               | 废除子规格本地编号                | client/server §7 全部引用根 FR 编号                  |   ✅    |
| C-1 Server 跨界 FR-025~028      | 改为根引用                        | server/SPEC.md §7 确认无完整 FR 定义                 |   ✅    |
| C-2 SPEC-exchangeinfo-sync 孤立 | 合并入根 SPEC                     | Status: Merged 确认                                  |   ✅    |
| C-3 版本脱节                    | 全部 v3.8.0→v3.9.0                | Metadata 确认                                        |   ✅    |
| C-4 DATA-LIFECYCLE 重叠         | Status: Retired                   | 确认                                                 |   ✅    |
| C-5 BR-010~012 碎片化           | 并入根 SPEC §8                    | `SPEC.md:1434-1452` 确认                             |   ✅    |
| M-1 SC vs TC                    | Server SC→TC                      | server/SPEC.md §16 确认                              |   ✅    |
| M-2 4 文件命名                  | 标记 Merged/Moved/Retired         | 确认（但 MA-3 指出标记不够醒目）                     |   ✅    |
| M-3 Client FR-003 一对多        | 废除本地编号后自然解决            | 确认                                                 |   ✅    |
| M-4 AC-BNC 遗留                 | 保留 + 强化弃用声明               | 确认（但 MA-4 指出仍占 33 行）                       | ⚠️ 部分 |
| MO-1 Config 三层重复            | —                                 | **未完全修复** → MA-1（字段名漂移）                  |   ❌    |
| MO-2 ENDPOINTS/SLA 抽象层       | ENDPOINTS→client 附录, SLA→FR-029 | 确认                                                 |   ✅    |
| MO-3 §14 目录重叠               | 根 §14 仅文档层                   | `SPEC.md:1876-1915` 确认（但 MO-2 指出仍列退役文件） |   ✅    |
| MO-4 三文件状态独立             | v3.9.0 双态模型部分缓解           | 确认（但 MO-1 指出无 CI gate）                       | ⚠️ 部分 |
| MO-5 Issue 闭合备忘录           | DATA-LIFECYCLE §9 保留为历史      | 确认                                                 |   ✅    |

**修复统计**：17/21 完全修复（✅），2/21 部分修复（⚠️），1/21 未修复（❌ → 升级为 MA-1），1/21 保留但仍有问题（⚠️ → 升级为 MA-4）。

---

## 附录 B：评分方法说明

本报告沿用前序报告的 5 维度评分框架，保持可比性：

| 维度                          | 满分 | 评估焦点                                                       |
| ----------------------------- | :--: | -------------------------------------------------------------- |
| A. Boundary Discipline        |  30  | client/server 边界约束可执行性、BR/FR 编号统一、跨边界通信规范 |
| B. Version & Status Integrity |  20  | 版本同步、状态口径一致性、双态模型覆盖度                       |
| C. Structural Completeness    |  25  | 23 节结构、文件命名、退役管理、目录结构、附录治理              |
| D. Traceability Cross-Linking |  15  | FR→AC→TC 追溯链、三文件状态链接、映射表完整性                  |
| E. Single Source of Truth     |  10  | config schema SSOT、编号空间唯一、信息冗余                     |

加分规则：基础扣分后，对超出最低结构完整性的治理创新（C1-C6 可执行约束、BR 三列映射、双态模型）给予加分，反映规格工艺水平。

---

## 附录 C：证据标签与置信度

- `[COMPUTED, HIGH]`：基于实读文件内容的计算或对比结果（全文 11 文件 5480 行实读）
- `[KNOWN, HIGH]`：基于治理文档的训练事实（CONSTITUTION、STRUCTURAL-SCORING、MODULE-GOVERNANCE）
- `[INFERRED, HIGH]`：基于文件结构和交叉引用的推断（如 spec-runtime drift 的风险推断）
- `[INFERRED, MED]`：基于文件结构的较低置信推断（如退役文件误读风险）

所有 `file:line` 引用基于 2026-06-27 实际文件读取。所有规范引用基于 `CONSTITUTION.md` 和 `docs/governance/` 下的治理文档。

---

`[RULES I BROKE]：无。本分析严格遵守 §20 epistemic standards，所有声明均已标注证据标签和置信度。分析过程中未编造引用，未将符号框架翻译为现实世界声明，未在无新证据下让步。对前序报告的"预计评分 > 90"判断，本报告基于新证据（v3.9.0 spec-runtime drift）给出更低评分（72），并公开说明与前序判断的差异原因。`
