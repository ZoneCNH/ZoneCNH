# `module/binance/` 深度分析报告

> **分析日期**：2026-06-22
> **分析范围**：`module/binance/` 全量文档资产（13 个文件，~3,778 行）
> **分析者**：Claude Code
> **证据标签**：`[KNOWN]` 来自实际文件读取与 git 历史；`[INFERRED]` 来自跨文档交叉验证
> **置信度**：HIGH（除 runtime 实际状态部分标注 MED）

> **状态更新（2026-06-22）**：本报告是 PR #850 的历史基线快照；P0/P1 文档对齐项已由 PR #852/#853 与 [v2 报告](./deep-analysis-20260622-v2.md) 复核。当前判断以 v2 和后续修复记录为准，本报告保留作问题发现与评分基线。

---

## 摘要

`module/binance` 是 ZoneCNH 数据域的 **Binance 专属 Market Data C/S 模块**，被设计为所有交易所采集模块（okx/bybit/bitget/kucoin/...）的参考实现。

**综合评分：68/100（C+）**

- 规格设计质量优秀（23 节模板完整、分布式约束清晰、边界 gate 完备）
- 跨文档对齐与运行时实现严重滞后（版本 7 处漂移、ARCHITECTURE 90% vs STATUS 5% 的 100x 进度冲突）
- 作为 13 个 C/S 模块的"参考实现"，其漂移会沿 fork 路径放大

---

## 一、模块定位与结构

### 1.1 角色定位 `[KNOWN][HIGH]`

`module/binance` 是 ZoneCNH 数据域的 **Binance 专属 Market Data C/S 模块**，按 `STATUS.md:113`、`ARCHITECTURE.md:206` 被标记为 **"C/S Module 参考实现"**——即所有交易所采集模块应仿照此结构。

- **职责**：Binance 行情采集 → 网络消息发布 → 服务端存储 → REST API/Kafka 广播
- **不拥有**：canonical domain（在 `domain_market`）、跨交易所通用语义、策略/下单/风控
- **架构**：强制分布式独立进程（`binance-client` ↔ NATS JetStream ↔ `binance-server`），**禁止同进程调用**

### 1.2 文件资产 `[KNOWN]`

| 文件                     |  行数 | 角色                                       |
| ------------------------ | ----: | ------------------------------------------ |
| `SPEC.md`                | 1,155 | 模块根 SPEC v2.1.2（23 节结构）            |
| `DEEP-ANALYSIS.md`       | 1,302 | 架构升级分析（v1.0.1 → v2.0.0 迁移依据）   |
| `BOUNDARY-GATES.md`      |   359 | CI 门禁（11 条 gate）v2.1.1                |
| `RUNTIME-MAPPING.md`     |   299 | docs ↔ runtime repo 路径映射               |
| `TRACEABILITY.md`        |   195 | 根级追溯矩阵 v2.1.0                        |
| `ACCEPTANCE.md`          |   137 | 验收文档                                   |
| `FEATURES.md`            |   111 | 完整功能清单（投影）                       |
| `IMPLEMENTATION-PLAN.md` |   110 | 实施计划                                   |
| `README.md`              |    63 | 模块入口                                   |
| `goal.md`                |    47 | 业务目标                                   |
| `client/`                |     — | Client 子模块（SPEC v2.1.0, ~31KB）        |
| `server/`                |     — | Server 子模块（SPEC v1.2.0, ~35KB）        |
| `tasks/`                 |  8 个 | Root 任务规格（TASK-BINANCE-ROOT-000~007） |

---

## 二、规格质量分析

### 2.1 优点（结构与边界）`[KNOWN][HIGH]`

1. **23 节模板完整**：`SPEC.md` 严格落实 `CONSTITUTION.md` 第四条 23 节结构（Metadata → Open Questions）。
2. **C/S 边界显式量化**：BR-002/BR-003/BR-006 明确禁止 client↔server 跨界 import；`BOUNDARY-GATES.md` 提供 11 条可执行的 grep/CI 脚本。
3. **追溯矩阵闭合**：v2.1.0 追溯矩阵的 13 个 FR、9 个 BR、20 个 NFR、28 个 TC、47 个 AC 形成完整 FR→AC→TC→Task 链路。
4. **分布式约束强力**：`DEEP-ANALYSIS.md §0` 通过 5 条 R1-R5 规则（"不得共享 Go interface/内存"、"`internal/cs` 必须删除"、"client/server 必须可在不同机器启动"）锁死同进程退化路径。
5. **G0-1~G0-6 上游契约链**：6/6 闭合（natsx、domain_market、redisx/taosx/postgresx/ossx/kafkax/Gin、market_data 消费）。

### 2.2 结构性问题

#### 🔴 P0：跨文档版本严重漂移 `[KNOWN][HIGH]`

```text
SPEC.md                   v2.1.2  (2026-06-21)
client/SPEC.md            v2.1.0  (2026-06-21)
server/SPEC.md            v1.2.0  ← 落后两个 minor
TRACEABILITY.md           v2.1.0  ← 落后 v2.1.2
client/TRACEABILITY.md    v2.0.0  ← 落后 v2.1.0
server/TRACEABILITY.md    （未声明 Matrix-Version）
FEATURES.md               v2.0.0  ← 落后 v2.1.2
BOUNDARY-GATES.md         v2.1.1
README.md                 引用 v1.0.0  ← 严重过时
```

**违反**：`CLAUDE.md §版本号自动递增`、"版本号变更必须同步更新"。`SPEC.md` 已迭代到 v2.1.2 引入 FR-006a~d/FR-007a/FR-010/FR-011 拆分，但 `server/SPEC.md` 仍在 v1.2.0，且 `FEATURES.md` 整体停留在 v2.0.0 投影，**实现清单与 SSOT 已脱节**。

#### 🔴 P0：内外部状态自相矛盾 `[INFERRED][HIGH]`

- `ARCHITECTURE.md:447` 称 binance **"v0.2.0 (rt) / v2.1.0 (spec)、进度 90%、bootstrap + 4 产品线"**
- `STATUS.md:113` 称 binance **"v2.1.0 (spec)、进度 5%、runtime 待 PR-007"**
- `STATUS.md:132` 称 binance **"✅ (有 GitHub)、❌ (CI/构建/测试/部署全无)"**
- `TRACEABILITY.md`：FR-001/FR-002 标 **Partial（Spot 已实现）**、其余全 ⬜ Pending

**结论**：ARCHITECTURE 的 90% 与 STATUS 的 5% 是 **100x 数据冲突**，违反 `CLAUDE.md §数量验证门禁` 的"跨维度交叉验证"要求。从模块内 TRACEABILITY 看真实进度更接近 **10-15%**（FR-001/FR-002 部分实现、FR-009 边界 gate 文档化、TC-020 PASS）。

#### 🟡 P1：FEATURES.md 与 TRACEABILITY.md FR 编号体系不一致 `[KNOWN][HIGH]`

| FEATURES.md FR                    | TRACEABILITY.md FR                           |
| --------------------------------- | -------------------------------------------- |
| FR-006 Full-Stack Storage（单条） | 拆分为 FR-006a / 6b / 6c / 6d                |
| 无 FR-010、FR-011                 | 含 FR-010（clickhousex）、FR-011（分布式锁） |
| FR-010 = Boundary Enforcement     | FR-009 = Boundary Enforcement                |

`FEATURES.md` 还是 v2.0.0 的旧 FR 编号映射，没跟上 v2.1.2 的拆分。**实施清单的可信度受损**。

#### 🟡 P1：根级 SPEC 含 47 个 AC，但 SPEC.md 内 grep `AC-` 为 0 `[KNOWN][HIGH]`

```text
grep AC- module/binance/SPEC.md       → 0 hits
grep AC- module/binance/TRACEABILITY.md → 47 unique AC IDs
```

AC 注册表（`TRACEABILITY.md §5`）声明了 AC-001~AC-047，但 `SPEC.md` 的 FR 章节用 WHEN/THEN 行为表述，**没有显式 AC-### 锚点**。这导致：

- AC 与 FR 的精确映射只在 TRACEABILITY.md 维护（单点漂移风险）
- 评分系统中 §1 FR 列若按"AC 列存在"判定会通过，按"FR 锚点存在"判定会失败
- 违反 `~/.claude/rules/ecc/matrix-scoring-rules.md §R1`（跨表走查仍可闭合，但属于结构脆弱）

#### 🟡 P1：Server SPEC 落后导致 FR 不一致 `[KNOWN][HIGH]`

- 根 `SPEC.md` FR-006 = Full-Stack Storage（包含 6a/6b/6c/6d）
- `server/SPEC.md` FR-005 = Multi-Store Write（单条覆盖 redisx/taosx/postgresx/ossx）

子规格未按根规格拆分，**子任务（SERVER-012~016）与根 FR 的映射在 TRACEABILITY 表中需脑补**。

#### 🟢 P2：legacy 名称大量保留 `[KNOWN][MED]`

`BOUNDARY-GATES.md §2` 允许 `module/binance/` 自引用历史。但实际：

- `SPEC.md §3.1`、`goal.md`、`README.md` 共有 30+ 处 `binance-market` 历史描述
- 容易让 grep gate 复杂化，且对新读者造成认知噪声

应考虑把"取代 binance-market"的描述压缩到 1 个章节 + Appendix B 引用。

#### 🟢 P2：DEEP-ANALYSIS.md 62KB 体量过大 `[KNOWN][MED]`

`DEEP-ANALYSIS.md` 1,302 行（62KB），含 v1.0.1 旧代码实态审计 + v2.0.0 升级路径。其中：

- §0 分布式约束 → 应升入 `SPEC.md §4 Goals` 顶部
- §12 代码实态审计 → 历史文档，建议移到 `docs/migrations/`
- 当前在模块根目录会让 SSOT 入口产生误导

---

## 三、设计原则合规性

### 3.1 与 `CONSTITUTION.md §1-§14` 对照 `[KNOWN][HIGH]`

| 宪法条款                  | binance 实现                                                                                     | 状态 |
| ------------------------- | ------------------------------------------------------------------------------------------------ | :--: |
| §1 模块独立性             | 独立仓库 `github.com/ZoneCNH/binance`                                                            |  ✅  |
| §2 单一职责               | 仅 Binance 行情；不跨交易所、不策略                                                              |  ✅  |
| §3 依赖单向               | 数据域 → 基座/L2.5；无反向                                                                       |  ✅  |
| §4 23 节 SPEC             | 完整                                                                                             |  ✅  |
| §5 命名 snake_case        | `binance` 单词，无歧义；Runtime monorepo `binance/` ✅；`internal/cs` 包名违反域语义但已计划删除 |  🟡  |
| §6 contracts 拥有跨域接口 | wire envelope 由 `domain_market` 拥有；binance 不定义 proto                                      |  ✅  |
| §9 orderx 抽象            | N/A（数据域）                                                                                    |  —   |
| §11 反馈通过事件          | natsx subject + kafkax topic                                                                     |  ✅  |
| §12 领域语义沉到 L2.5     | `domain_market` 已 own canonical types                                                           |  ✅  |

### 3.2 与项目核心原则对照 `[INFERRED][HIGH]`

```text
基座 → 数据域 → 分析域 ⇄ 决策域 → 执行域 → x.go
```

binance 是**数据域唯一的 C/S 参考实现**，其他 12 个 C/S 模块按 STATUS.md 仍是 v0.1.1 单体形态。这意味着：

- ✅ binance 承载了 C/S 模式的**规格示范责任**
- 🔴 但 server SPEC v1.2.0 落后 root v2.1.2、FEATURES.md 落后 → 示范作用打折
- 🔴 其他 12 个模块若 fork binance 的结构，**继承的是不一致的版本基线**

---

## 四、Runtime 状态推断

### 4.1 实际进度 `[INFERRED][MED]`

> 基于文档证据交叉，无 runtime 仓库直接访问

| 维度                   | 文档声明                  | 推断真实状态                                                   |
| ---------------------- | ------------------------- | -------------------------------------------------------------- |
| Spec                   | v2.1.2 Approved           | ✅ 真实                                                        |
| FR-001 (Product Lines) | Partial（Spot 已实现）    | 🟡 Spot 是 docs 中 active client task 状态                     |
| FR-009 (Boundary Gate) | Implemented + TC-020 PASS | 🟡 仅 BOUNDARY-GATES 文档落地；runtime CI 脚本是否执行不可验证 |
| 其他 11 个 FR          | ⬜ Pending                | 🔴 一致                                                        |
| TC-020 PASS            | 单测/CI 已跑通            | ❓ 无 evidence 文件证明                                        |
| `internal/cs` 删除     | Documented as required    | 🔴 DEEP-ANALYSIS.md §0.4 仍列其为"违规当前态"                  |

### 4.2 关键阻塞 `[INFERRED][HIGH]`

```text
PR-007 (TASK-BINANCE-ROOT-007 runtime-implementation) 是单一关键路径节点：
  阻塞 12 个 FR (FR-003~008, FR-010, FR-011)
  阻塞 25/28 TC
  阻塞 9/9 BR runtime 验证
```

---

## 五、综合评分

> 评分基准：`docs/governance/scoring/` 5 维度。措辞强度按 R0 仅对【硬】约束扣分。

| 维度                           | 满分 |   得分 | 主要扣分点                                                                                                   |
| ------------------------------ | ---: | -----: | ------------------------------------------------------------------------------------------------------------ |
| **规格结构（SPEC quality）**   |   25 | **23** | -2：DEEP-ANALYSIS §0 分布式约束未升入 SPEC §4 顶部                                                           |
| **追溯完整性（Traceability）** |   25 | **19** | -3：SPEC.md 无 AC-### 锚点；-2：server SPEC FR 编号未对齐根 SPEC v2.1.2；-1：client TRACEABILITY v2.0.0 落后 |
| **边界与门禁（Boundary）**     |   20 | **18** | -2：TC-020 PASS 标注但无证据文件路径                                                                         |
| **跨文档对齐（Alignment）**    |   15 |  **6** | -5：版本号 7 处漂移；-3：ARCHITECTURE 90% vs STATUS 5% 进度冲突；-1：README 引用 v1.0.0                      |
| **运行时实现（Runtime）**      |   15 |  **2** | -13：13 个 FR 中 11 个 Pending；25/28 TC 待跑；`internal/cs` 删除未确认                                      |
| **合计**                       |  100 | **68** | 等级：**C+**（规格优秀、对齐与实现严重滞后）                                                                 |

---

## 六、优先级修复建议

### P0（48 小时内）

1. **同步版本号**：把 `server/SPEC.md` 升到 v2.1.x、`FEATURES.md` 升到 v2.1.2 投影、`client/TRACEABILITY.md` 升到 v2.1.0、`README.md` 引用 v2.1.2
2. **解决进度冲突**：`ARCHITECTURE.md:447` 的 "90%" 与 `STATUS.md:113` 的 "5%" 必须二择一，并跑 `python3 scripts/audit-status.py --network` 验证
3. **在 SPEC.md 中插入 AC-### 锚点**：每个 FR 节末尾列 `**AC**: AC-001~AC-003`，消除追溯单点依赖

### P1（一周内）

4. **拆分 server/SPEC.md FR-005 → FR-006a~d** 与根 SPEC 对齐
5. **FEATURES.md FR 编号体系全面替换**为 v2.1.2 体系（含 FR-007a/FR-010/FR-011）
6. **DEEP-ANALYSIS.md §0** 上提到 `SPEC.md §4 Goals` 顶部，原文件迁移到 `docs/migrations/binance-v2-upgrade.md`

### P2（持续）

7. **PR-007 runtime 实施**：拆分为 7 个子 PR（natsx publisher / consumer / redisx / taosx / postgresx / kafkax / Gin），每个 PR 闭合 1-2 个 FR + 对应 TC
8. **CI 门禁运行证据归档**：在 `release/evidence/binance/` 输出 TC-020 PASS log 文件
9. **删除 `internal/cs`**：runtime 仓库执行后在 BOUNDARY-GATES.md §5 标注完成日期

---

## 七、风险信号

- 🔴 **示范污染**：作为 13 个 C/S 模块的参考实现，binance 的版本漂移会沿 fork 路径放大
- 🟡 **审查疲劳**：1,302 行 DEEP-ANALYSIS + 1,155 行 SPEC 让评审者难以全量校验，需要分层入口
- 🟢 **架构本身坚实**：分布式约束 + boundary gates + 上游契约链 G0-1~G0-6 是高质量基础，问题集中在**对齐与执行**而非**设计**

---

## 八、证据清单

| 证据                       | 来源文件                                | 行号/位置  |
| -------------------------- | --------------------------------------- | ---------- |
| SPEC v2.1.2                | `module/binance/SPEC.md`                | L6         |
| server SPEC v1.2.0         | `module/binance/server/SPEC.md`         | L9         |
| TRACEABILITY v2.1.0        | `module/binance/TRACEABILITY.md`        | L7         |
| client TRACEABILITY v2.0.0 | `module/binance/client/TRACEABILITY.md` | L6         |
| FEATURES v2.0.0            | `module/binance/FEATURES.md`            | L9         |
| ARCHITECTURE 进度 90%      | `ARCHITECTURE.md`                       | L447       |
| STATUS 进度 5%             | `STATUS.md`                             | L113       |
| STATUS CI/构建全无         | `STATUS.md`                             | L132       |
| 13 FR Partial+Pending 矩阵 | `module/binance/TRACEABILITY.md`        | L19-L33    |
| FR-009 Implemented         | `module/binance/TRACEABILITY.md`        | L31        |
| 分布式约束 §0              | `module/binance/DEEP-ANALYSIS.md`       | L9-L80     |
| BOUNDARY GATES 11 条       | `module/binance/BOUNDARY-GATES.md`      | 全文       |
| 上游契约链 G0-1~G0-6       | `module/binance/SPEC.md`                | Appendix D |

---

[RULES I BROKE]：无 — 全程基于文件 Read 与 git 历史；未实际访问 `github.com/ZoneCNH/binance` runtime 仓库，runtime 状态相关结论标注为 `[INFERRED][MED]`。

**生成时间**：2026-06-22
**生成者**：Claude Code（深度分析模式）
**审查状态**：待 user/architect agent 二次审查
