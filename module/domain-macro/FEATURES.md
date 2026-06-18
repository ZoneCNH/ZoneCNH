# domain-macro 完整实现功能清单

- Status: Generated（与 [SPEC.md](./SPEC.md) 同步抽取，未经 pipeline-arbiter 校验）
- Last-Updated: 2026-06-18
- Source: [SPEC.md](./SPEC.md) · [TRACEABILITY.md](./TRACEABILITY.md) · [goal.md](./goal.md)
- Scale: 8 FR · 6 BR · 0 NFR

> 本文档是 domain-macro **要完整实现的、可勾选的功能清单**，把 SPEC 的 FR/BR/NFR 展开成具体可验收的功能点。
> 它不是 Why（goal.md）、不是规格（SPEC.md）、不是追溯矩阵（TRACEABILITY.md）。
> 实现状态以本清单勾选为准；任一未勾选项存在即视为未完整实现。

勾选图例：`[ ]` 待实现 · `[x]` 已实现并通过对应 TC · `[~]` 部分实现（须在备注列注明缺口）

---

## 1. 功能需求（FR）

- [ ] **FR-MAC-001** MacroPoint 必须表达 observed/released/available 三类时间。
- [ ] **FR-MAC-002** MacroPoint 必须记录 revision version、preliminary flag 和 source。
- [ ] **FR-MAC-003** `IsVisibleAt(decisionTime)` 必须 fail-closed，available time 缺失或晚于 decision time 时不可见。
- [ ] **FR-MAC-004** MacroInformationSet.AsOf 必须只返回 decision time 可见数据，并保持 copy-on-write。
- [ ] **FR-MAC-005** RevisionVersion 必须非负并可用于 deterministic revision ordering。
- [ ] **FR-MAC-006** MacroState / MacroRegimeCard 必须有稳定枚举和 validate 规则。
- [ ] **FR-MAC-007** 公共数值精度必须通过 ADR 冻结，推荐采用 `decimalx.Decimal`。
- [ ] **FR-MAC-008** provider-dto

## 2. 业务规则（BR）

- [ ] **BR-MAC-001** IsVisibleAt 必须 fail-closed：缺失 AvailableAt 的点不可见
- [ ] **BR-MAC-002** FilterMacroPointsForBacktest 必须拒绝缺失 AvailableAt 的点，避免前视偏差
- [ ] **BR-MAC-003** MacroInformationSet 构造器 copy-on-write：getter 返回 slice 副本
- [ ] **BR-MAC-004** 同一 DecisionTime + 同一输入数据 → MacroInformationSet 输出 deterministic
- [ ] **BR-MAC-005** DataFreshnessSec 规则：无可见点时返回 -1 或特殊值；未来数据拒绝
- [ ] **BR-MAC-006** provider DTO 不得污染 domain Public API

## 3. 非功能需求（NFR）

> SPEC 中未抽取到 `NFR-` 编号；请人工对照 SPEC §11 非功能需求补全（如有）。

---

## 4. 完整实现判定

本清单 §1-§3 全部 `[x]` 勾选 + ACCEPTANCE.md 全部 TC 通过 + SPEC §19 验收门禁通过 + pipeline-arbiter 翻转 Approved。

## 5. 明确不做

参见 [SPEC.md](./SPEC.md) §4 非目标章节。domain-macro 只承担 SPEC 范围内的能力，不做范围外业务语义/集成编排/跨模块横切。

