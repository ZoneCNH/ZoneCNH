# module/binance 治理分层等级提案（L1/L2/L3）

- Proposal-ID: binance-gov-tier-20260626
- Status: Proposal（待讨论审批）
- Created: 2026-06-26
- Author: ZoneCNH（Phase 0 断链修复完成后推进）
- Trigger: 数据域 CS 架构治理模式是否需要优化？→ 需要，"减负 + 修断链 + 分层"

---

## 0. 动机

binance 的治理密度（10 条规则、27 个必存文档、13 道边界门禁、8 个漂移监控点）是 5 个月有机生长的结果。它对后续 9 个 proposed 数据域模块（okx/hyperliquid/coinglass/fred/treasury/market_data/macro_data/pe_data/alternative_data）形成不可持续的模板预期。

本提案定义 **L1/L2/L3 三级治理等级**，让：
- 新模块从 **L1 起步**（最小可行门槛）
- 成熟模块升级到 **L2**（标准维持门槛）
- **L3 保留给跨模块参考实现**（当前 binance 级）

核心原则：**L1 准入门槛 ≤ binance v1.0.0 时期的治理密度；L3 不做减法，但明确它是"天花板"而非"地板"。**

---

## 1. L1 — 最小可行模块（Minimal Viable Module）

**目标**：`proposed → active` 毕业门禁。新模块只需 L1 即可进入 active。

### 1.1 必存文档（8 个）

| 文档 | 用途 | 最低要求 |
|------|------|----------|
| `SPEC.md` | 模块规格 | ≥ 12 节核心内容（元数据/摘要/问题/目标/非目标/消费者/FR/BR/NFR/配置/错误码/附录）；Status = Approved |
| `TRACEABILITY.md` | 追溯矩阵 | FR→AC→TC ≥ 80% 覆盖；FR ≥ 8 条 |
| `goal.md` | 业务目标 | Primary Goals + Non-Goals + Success Criteria |
| `ACCEPTANCE.md` | 验收清单 | 验收命令 + AC 登记表 + Build/Test/Vet gate |
| `README.md` | 模块索引 | Role + Submodules + Runtime Shape + 数据流图 |
| `client/SPEC.md` | 客户端子规格 | 若 `arch_type: cs_module` |
| `server/SPEC.md` | 服务端子规格 | 若 `arch_type: cs_module` |
| `BOUNDARY-GATES.md` | CI 门禁 | ≥ 5 个 gate（禁止 legacy/禁止跨进程互导/go.mod 合规） |

### 1.2 推荐文档（非强制）

- `IMPLEMENTATION-PLAN.md`
- `RUNTIME-MAPPING.md`
- `CHANGELOG.md`
- `NAMING.md`（若模块有 product_line/event_type 等多维命名需求）

### 1.3 毕业条件

```
1. SPEC Status = Approved（经 pipeline-arbiter 98 分门禁）
2. TRACEABILITY FR→AC→TC 覆盖 ≥ 80%
3. BOUNDARY-GATES ≥ 5/5 PASS（runtime CI）
4. go build/test/race/vet PASS
5. runtime 首次 release tag（v0.1.0）
```

---

## 2. L2 — 标准模块（Standard Module）

**目标**：`active` 维持门槛。模块进入 active 后 30 天内应达到 L2。当前 binance 去掉 L3 专属文档即为 L2。

### 2.1 L2 额外文档（+5 个，共 13 个）

| 文档 | 用途 |
|------|------|
| L1 全部 | — |
| `IMPLEMENTATION-PLAN.md` | 实现计划 + 阶段门禁 + PR 顺序 |
| `RUNTIME-MAPPING.md` | 运行时仓映射（spec→code） |
| `CHANGELOG.md` | 模块变更历史（Keep a Changelog 格式） |
| `NAMING.md` | 命名 SSOT（product_line × event_type × subject × topic × path） |
| `server/docs/PERSISTENCE-WIRING.md` | 存储装配契约（若 server 有存储） |

### 2.2 L2 治理规则

- 命名一致性（4×N 矩阵无缺口）
- 版本 bump 触发器（CONSTITUTION §10.4）
- L1/L2 状态分层（boundary gate ≠ functional acceptance）
- 归档物理隔离（task 替代时 `git mv` 到 archive/）

### 2.3 毕业条件

```
1. L1 全部满足
2. 4×N 命名矩阵 100% 对称（NAMING.md + drift detection）
3. FR→AC→TC→Task 四层追溯闭环 100%
4. 版本字段统一（Module-Version == root Spec-Version；R6 规则）
5. IMPLEMENTATION-PLAN gate 全部 PASS
```

---

## 3. L3 — 全量治理（Full Governance Reference）

**目标**：跨模块参考实现。仅需 1-2 个模块达到 L3，作为其他模块的治理天花板。

### 3.1 L3 额外文档（+8 个，共 21 个）

| 文档 | 用途 |
|------|------|
| L2 全部 | — |
| `RULES.md` | 单模块治理规则（10 条硬/软/开规则） |
| `STANDARD.md` | Runtime control standard + evidence gates |
| `ARCHITECTURE-DRIFT-WATCHLIST.md` | 漂移监控点（D1-Dn） |
| `FEATURES.md` | 功能特性总览 + 实现投影 |
| `server/docs/ENDPOINTS.md` | REST API 端点（server 专属） |
| `server/docs/DATA-LIFECYCLE.md` | 数据生命周期（server 专属） |
| `server/docs/DATA-QUALITY-SLA.md` | 数据质量 SLA（server 专属） |
| `server/docs/OPERATIONS.md` | 部署与运维（server 专属） |

### 3.2 L3 专属治理能力

- **单模块规则**（R1-R10）：硬约束 + 软建议 + 开放检查
- **漂移监控**：定期 PR review / GC agent 逐项检查
- **文档退役审计**：每季度检查哪些文档 3 个月未被引用或更新
- **跨模块模板提取**：当 ≥ 2 个模块需要同类型文档时，上提为模板

### 3.3 当前 L3 模块

| 模块 | 状态 |
|------|------|
| `binance` | ✅ L3（参考实现） |
| `okx` | ⬜ L1（proposed，v0.1.0-draft） |
| `hyperliquid` | ⬜ L1（proposed，v0.1.0-draft） |

> 未来若 okx 或 hyperliquid 达到 L2 后需要 RULES/STANDARD/DRIFT-WATCHLIST 等 L3 文档，不应重复 binance 的全部内容——应提取通用模板到 `docs/governance/module-governance/`，模块只保留模块特定部分。

---

## 4. 升级路径

```text
proposed ──(L1 毕业)──→ active ──(30天内 L2)──→ active(L2) ──(按需 L3)──→ active(L3)
```

- **L1→L2**：自然演进，30 天内补齐 L2 文档
- **L2→L3**：按需升级。仅当模块需要单模块规则、漂移监控、SLA 等高级治理能力时才升级。不强制所有 active 模块达到 L3。

---

## 5. RULES.md R9 文档清单改造

当前 R9 是平面清单（27 个文件），改为分层清单：

```markdown
## R9【开】文档存在性

**L1 最小可行（8 个）**：
| 文件 | 用途 |
|---|---|
| SPEC.md | 模块规格 |
| ...

**L2 标准（+5 个，共 13 个）**：
| 文件 | 用途 |
|---|---|
| IMPLEMENTATION-PLAN.md | 实现计划 |
| ...

**L3 全量（+8 个，共 21 个）**：
| 文件 | 用途 |
|---|---|
| RULES.md | 治理规则 |
| ...

binance 当前处于 L3，后续数据域模块（okx/hyperliquid 等）从 L1 起步。
```

---

## 6. 与现有治理体系的兼容性

- `MODULE-GOVERNANCE.md` 八域体系：本提案的 L1/L2/L3 是其补充，定义"每个模块的文档完备度等级"
- `CONSTITUTION.md` §10.4：不受影响——版本管理规则不变
- `registry.yaml`：可选增加 `gov_tier: L1|L2|L3` 字段
- `STRUCTURAL-SCORING.md`：L1/L2/L3 可作为评分维度之一

---

## 7. 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-26 | v1.0.0-draft | 初始提案：L1/L2/L3 三级定义、升级路径、R9 改造方案 |
