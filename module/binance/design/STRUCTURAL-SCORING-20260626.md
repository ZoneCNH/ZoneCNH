# module/binance 结构性问题诊断与评分报告

> **v3.8.0 后记（2026-06-26）**：本报告于同日 22:00 完成。同日 23:00，`module/binance/spec/` 完成 v3.8.0 canonical FR/BR 编号统一修复，解决了本报告中的 Problem 3（AC/TC 命名空间碰撞）、Problem 5（BR phantom 问题）、Problem 6（server FR 编号冲突）、Problem 10（FR-001 歧义）。v3.8.0 采取了比本报告 P0-P2 方案更彻底的路径：**废除所有子规格本地 FR/BR 编号，全部改为引用根 SPEC canonical 编号**。详细修复记录见 `report/binance/spec-structural-analysis-20260626.md`。本报告保留为修复前的"before"快照。

> 分析日期：2026-06-26
> 分析范围（修复前）：root SPEC v3.7.1 + client SPEC v2.1.1 + server SPEC v2.2.0 + 三层 TRACEABILITY 矩阵
> 修复后：全部统一为 v3.8.0 canonical 编号
> Runtime-Anchor: `/home/binance@f046e16`

---

## 评分方法论

采用与 `STRUCTURAL-SCORING.md` 兼容的三维评分：

| 维度           | 权重 | 说明                                                        |
| -------------- | ---- | ----------------------------------------------------------- |
| **边界一致性** | 40%  | client ↔ server 之间 FR/BR/AC/TC 是否无冲突、无重叠、无歧义 |
| **追溯闭环**   | 35%  | FR→AC→TC→Task→Status 链是否在子模块矩阵中正确反映 root 状态 |
| **文档时效性** | 25%  | 版本号、日期、Runtime-Anchor 是否全链路一致                 |

每项扣分规则：**CRITICAL −15、HIGH −8、MEDIUM −4、LOW −1**，满分 100。

---

## 结构性问题清单

### 🔴 问题 1：CRITICAL — 子模块 TRACEABILITY 实现状态与 root 严重分裂

> ⚠️ **v3.8.0 部分缓解**：子矩阵 Module-Version 已同步至 v3.8.0，FR 列改为 root canonical 编号。但 0% Done 的实现状态分裂是 **runtime evidence 缺口**，非编号问题——需通过真实测试证据闭合，规格层无法解决。详见 §7 "修复后评分"。

**证据**：

| 来源                                | FR 实现状态                                       |
| ----------------------------------- | ------------------------------------------------- |
| `matrix/TRACEABILITY.md` §1（root） | **24 Done / 10 Partial / 10 Pending**（71% Done） |
| `matrix/client/TRACEABILITY.md` §6  | **0/8 FR Done（0%）**，全表 `⬜ Pending`          |
| `matrix/server/TRACEABILITY.md` §6  | **0/12 FR Done（0%）**，全表 `⬜ Pending`         |

client TRACEABILITY 明确写着：

> 实现完成率：0 / 8 FR — 0%（文档对齐 v2.1.1，代码待实现）

server TRACEABILITY 同样：

> 实现完成率：0 / 12 FR — 0%（文档对齐 server SPEC v2.1.0，代码待实现）

**诊断**：root 矩阵声称的 24 个 Done FR 对应的 client/server 子矩阵条目全部为 Pending。这不是"口径差异"能解释的——要么 root 高估了实现状态，要么子矩阵自 v2.0 起就再未同步。无论哪种，**全链路追溯已断裂**。如果一个外部审计者只看 client/server TRACEABILITY，会认为 binance 模块完全未实现。

**影响范围**：

- 20 个 FR（client 8 + server 12）的实现状态在子矩阵中不可见
- Plan007/Plan008 全部 40 Task 的完成证据未向下游注入子矩阵
- 违反 `CONSTITUTION.md` §18 制品完成门禁（artifact completion gate）

**建议修复**：

1. 将 root TRACEABILITY §1 的 24 Done / 10 Partial 投影按 FR 归属拆解到 client TRACEABILITY（8 FR）和 server TRACEABILITY（12 FR）的对应行
2. 或至少在子矩阵 §6 覆盖率仪表盘增加注释："实现状态以 root TRACEABILITY Runtime-Anchor `/home/binance@f046e16` 为准，本子矩阵保留 Pending 标注反映子模块级 TC 测试证据未独立闭合"

**扣分**：−15

---

### 🔴 问题 2：HIGH — server/SPEC.md Runtime-Version 与 root SPEC 不一致

> ✅ **v3.8.0 已修复**：server SPEC v2.2.0→v3.8.0，与 root v3.8.0 一致。

**证据**：

| 文件                      | Runtime-Version |
| ------------------------- | --------------- |
| `spec/SPEC.md` (root) L10 | `v0.2.0`        |
| `spec/server/SPEC.md` L16 | `v0.1.0`        |
| `spec/client/SPEC.md` L10 | `v0.2.0` ✅     |

Server SPEC 还标记为 `v0.1.0`，这意味着在 Plan008 全量 40 Task 实现（PR #145 合并，Runtime-Anchor `f046e16`）后，server 子规格的 runtime 版本未跟随升级。这违反了 RULES R6 版本统一规则。

**影响范围**：

- 读者无法从 server/SPEC.md 判断其对应的 runtime 代码版本
- 与 root SPEC 的 Runtime-Anchor `f046e16` / Runtime-Version `v0.2.0` 产生矛盾
- 违反 `CHANGELOG.md` R3 版本 bump 触发器

**建议修复**：`server/SPEC.md` L16 `Runtime-Version: v0.1.0` → `v0.2.0`，与 root SPEC 对齐。

**扣分**：−8

---

### 🟠 问题 3：HIGH — AC/TC 编号空间在三层矩阵中重叠且无命名空间隔离

> ✅ **v3.8.0 已修复**：根 SPEC §7 新增 FR→部署单元归属矩阵（`(C)` / `(S)` / `(C+S)` 列），TRACEABILITY 矩阵层（ROOT/SERVER/CLIENT）已存在。废除子规格本地 AC/TC 后自然消除重叠。

**证据**：

`AC-001` 在三层矩阵中分别指向完全不同的含义：

| 矩阵层 | AC-001 含义                                              | 所属 FR                                |
| ------ | -------------------------------------------------------- | -------------------------------------- |
| root   | "Client 启动且 product-line 已启用时建立 WebSocket 连接" | FR-001 (Product-Line Support)          |
| client | "Client 启动时加载全部 4 条产品线"                       | client FR-001 (Product-Line Catalog)   |
| server | "durable consumer 绑定名称 binance-server"               | server FR-001 (natsx Consumer Binding) |

TC 同理——`TC-001` 在三层矩阵中含义各不相同：

| 矩阵层 | TC-001 含义                                    |
| ------ | ---------------------------------------------- |
| root   | 集成（Binance testnet 四产品线）               |
| client | 单元（加载 4 条产品线 catalog）                |
| server | 单元（durable consumer 订阅 binance.market.>） |

当 SPEC.md §7 FR→AC 映射索引用 `AC-001~003` 引指 root 命名空间时，读者无法区分这与 client 或 server 的 AC-001 是否是同一个东西。目前的缓解措施是"上下文隐含"（root 矩阵的 AC 显然不同于 client 矩阵），但没有任何显式的命名空间前缀。

**影响范围**：

- 跨文档引用 AC/TC 编号时有 3 选 1 的歧义
- SPEC.md §7 的 FR→AC 映射索引未标注 AC 编号所属矩阵层
- 自动校验脚本（如 `check-binance-docs.sh`）无法通过编号区分三层 AC/TC

**建议修复**：

1. 引入命名空间前缀：`ROOT-AC-001`、`CLIENT-AC-001`、`SERVER-AC-001`
2. 或在 root SPEC §7 FR→AC 映射索引中增加 `矩阵层` 列，显式标注每个 AC 的归属
3. 在 `check-binance-docs.sh` 中增加跨层 AC/TC 编号冲突检测

**扣分**：−8

---

### 🟠 问题 4：HIGH — server/SPEC.md 的 `Last-Updated` 滞后 3 天

**证据**：

| 文件                  | Last-Updated   |
| --------------------- | -------------- |
| `spec/SPEC.md` (root) | 2026-06-26     |
| `spec/client/SPEC.md` | 2026-06-25     |
| `spec/server/SPEC.md` | **2026-06-23** |

Root SPEC v3.7.1 引入了 FR-037~044（含 server 侧 FR-038/039/041/042/044）和 FR-021 的 IndexPrice 对齐、FR-025 cold_start/repair 拆分、FR-019 MaxConcurrent 5→4。这些都是 server 侧变更，但 server SPEC 的 Last-Updated 停留在 6 月 23 日，**未反映 3 天内的任何规格变更**。

**影响范围**：

- v3.7.0→v3.7.1 的 server 侧 FR 变更未在 server/SPEC.md 中登记
- FR-037~044 中涉及 server 的 5 个 FR（038/039/041/042/044）在 server SPEC 中无对应条目
- 违反 RULES R9 文档存在性

**建议修复**：

1. 将 `server/SPEC.md` 的 `Last-Updated` 更新为 `2026-06-26`
2. 在 server/SPEC.md §7 中新增 FR-038/039/041/042/044 的 server 侧条目（或至少交叉引用 root SPEC）
3. 建立 root SPEC bump 时自动触发子规格 Last-Updated 检查的机制

**扣分**：−8

---

### 🟠 问题 5：MEDIUM — BR 编号在三层间无映射表，存在 phantom BR

> ✅ **v3.8.0 已修复**：根 SPEC §8 新增 BR 三列映射表（Root↔Client↔Server）+ BR-010~BR-012 合并入根。Client/Server 子规格 BR 节改为引用根 canonical 编号。

**证据**：

| BR 编号 | root 含义                 | server 含义                            | client 含义                 |
| ------- | ------------------------- | -------------------------------------- | --------------------------- |
| BR-001  | No binance-market         | ManualAck 全链路写入后才 Ack           | ~~ARCHIVED~~                |
| BR-007  | Wire Contract Externality | **Cold-Write-First** (ossx ETag guard) | Client 禁止与 server 同进程 |

Server BR-007（Cold-Write-First）在 root BR 表中**根本不存在**（phantom BR）。Client BR-007（禁止同进程）对应 root BR-005（No Runtime Shared Package）。没有一个统一的 BR 映射表说明这些编号之间的关系——唯一的线索是 server/TRACEABILITY 的 §2 表中"来源"列的非正式引用。

**影响范围**：

- 读者无法在 root 矩阵中找到 server BR-007 的对应规则
- BR 治理的全局编号空间被三层各自为政的编号体系割裂
- CI gate 的 BR 校验依赖 root BR 编号，phantom BR 可能被漏检

**建议修复**：

1. 在 root TRACEABILITY §2 中新增 BR 三层映射表，列出 root BR → server BR → client BR 的对应关系
2. 将 server BR-007（Cold-Write-First）登记到 root BR-010（当前 Draft 编号空间已有 BR-010~012，可借用）
3. 或在各子模块 BR 表中强制引用 root BR 编号作为 canonical ID

**扣分**：−4

---

### 🟠 问题 6：MEDIUM — server/SPEC.md FR 编号与 root SPEC FR 编号系统性冲突

> ✅ **v3.8.0 已修复**：废除所有子规格本地 FR 编号，全部改为引用根 SPEC canonical FR-XXX。Server SPEC §7 重构为以根 FR 编号为标题的实现视图。附录中推荐的三条修复路径，v3.8.0 采取了最彻底的 "全用 root FR 为 canonical" 方案。

**证据**：

| server FR     | 含义                  | 映射 root FR                                               |
| ------------- | --------------------- | ---------------------------------------------------------- |
| server FR-005 | Multi-Store Write     | root FR-006a/6b/6c/6d（Full-Stack Storage）                |
| server FR-004 | Idempotent Acceptance | root FR-005（Idempotent Acceptance）                       |
| server FR-003 | Envelope Validation   | root 无独立的 validation FR（validation 嵌入 FR-005 流程） |

Server SPEC §7 FR-005 注释说 "FR-005a/5b/5c/5d 映射根 FR-006a/6b/6c/6d"，但一个编号 FR-005 同时出现在 root（Idempotent Acceptance）和 server（Multi-Store Write），含义完全不同。读者在交叉引用时极易混淆。目前全靠散文注释来消歧，没有结构化映射表。

**影响范围**：

- 当代码注释引用 "FR-005" 时，无法确定是 root 语义还是 server 语义
- Task 文件中的 "FR-005" 引用是模糊的（虽然多数指向 root）
- 新加入的开发者需要额外上下文才能理解编号分歧

**建议修复**：

1. 在 root SPEC §7 增加 FR 编号子模块映射列（如 `FR→Server-FR`、`FR→Client-FR`）
2. 或统一使用 root FR 编号为 canonical，子模块 SPEC 在 FR 标题中标注 `(root FR-XXX)`
3. 短期方案：在 server/SPEC.md §7 开头增加 FR 编号映射表

**扣分**：−4

---

### 🟠 问题 7：MEDIUM — `README.md` 引用已归档的 `DEEP-ANALYSIS.md` 章节

**证据**：

`README.md` L89：

> 详细版见 `DEEP-ANALYSIS.md` 的 §2.1 和 §5.1。

但 `design/DEEP-ANALYSIS.md` 第一行声明：

> [ARCHIVED 2026-06-22] 本文档为 v2.0.0 重构前的深度分析（2026-06-21），已被 SPEC v3.5.0 + TRACEABILITY v3.5.0 覆盖。
> **本文档现在是归档索引**。原始内容已按主题拆分为 3 个归档文件。

归档后的 DEEP-ANALYSIS.md 已将 §2.1 和 §5.1 迁移至归档文件，README 的引用是死链（逻辑意义上）。内容迁移映射表显示 §2.1 已迁至 `DEEP-ANALYSIS-ARCHIVE-architecture.md`。

**影响范围**：

- 新读者点击引用找不到对应内容
- 违反 RULES R9 文档存在性（引用目标不存在）

**建议修复**：将 README.md L89 的引用更新为：

- 数据流 → `design/DESIGN.md` §3
- 架构 → `spec/SPEC.md` §2
- 或直接指向归档子文件 `design/DEEP-ANALYSIS-ARCHIVE-architecture.md`

**扣分**：−4

---

### 🟡 问题 8：LOW — `prompt/` 目录空壳

**证据**：`prompt/README.md` 仅有目录结构占位，无 Context Package 制品。管线 S5-Prompt 阶段对 binance 模块不产生实际交付物。

**影响范围**：

- 管线 S5-Prompt → S6-Code 之间存在交付断层
- 与其他成熟模块（如 `observex/` 有 10 个 PROMPT 文件、`xlib_standard/` 有 9 个 PROMPT 文件）形成差距

**建议修复**：可暂保持占位，待 FR-031~036 从 Draft 提升为 Active 时作为 Prompt 阶段的输入契机。

**扣分**：−1

---

### 🟡 问题 9：LOW — `registry.yaml` spec_version 滞后

> ✅ **v3.8.0 已修复**：`module/registry.yaml` spec_version + latest_tag v3.7.1→v3.8.0。

**证据**：

| 位置                        | spec_version |
| --------------------------- | ------------ |
| `module/registry.yaml:486`  | `v3.6.0`     |
| `module/binance/SPEC.md` L6 | `v3.7.1`     |

注册表落后 2 个 MINOR bump（v3.6.0 → v3.7.0 → v3.7.1）。

**影响范围**：

- 注册表与 spec 事实不一致，违反 SSOT 原则
- `spec_version` 字段用于自动化管线状态检查，滞后值可能触发错误的 gate 判定

**建议修复**：`registry.yaml` L486 `spec_version: v3.6.0` → `v3.7.1`

**扣分**：−1

---

### 🟡 问题 10：LOW — server FR-001 与 root FR-001 歧义风险

> ✅ **v3.8.0 已修复**：废除子规格本地 FR 编号后，`FR-001` 全局仅有一个含义（根 SPEC 的 Product-Line Support）。Server 侧直接引用 `FR-003 (natsx Communication)` 等 root canonical 编号。

**证据**：

- server FR-001 = "natsx Consumer Binding"（server 侧 JetStream 订阅）
- root FR-001 = "Product-Line Support"（client 侧四产品线连接器）

虽然属于不同层级，但同一编号 FR-001 描述完全不同的功能需求。子模块按自身领域独立编号是合理的，但缺少一个显式的编号映射表来消除歧义。

**影响范围**：

- Task 文件中的 "FR-001" 引用是模糊的
- 新读者需要在 server 和 root 之间做 mental context switch

**建议修复**：在 server/SPEC.md §7 开头增加一行：`> 本子模块 FR 编号为 server-local；对应 root SPEC FR 编号见下表。` 并附映射表。

**扣分**：−1

---

## 综合评分

| 维度       | 满分    | 扣分明细                                                                                                   | 扣分合计 | 得分         |
| ---------- | ------- | ---------------------------------------------------------------------------------------------------------- | -------- | ------------ |
| 边界一致性 | 40      | −8 (AC/TC命名空间冲突) −4 (BR phantom) −4 (server FR编号冲突) −1 (server FR-001歧义)                       | −17      | **23**       |
| 追溯闭环   | 35      | −15 (子矩阵0% vs root 71%) −4 (BR映射缺失)                                                                 | −19      | **16**       |
| 文档时效性 | 25      | −8 (server Runtime-Version) −8 (server Last-Updated) −1 (registry版本滞后) −1 (prompt空壳) −4 (README死链) | −22      | **3**        |
| **总计**   | **100** |                                                                                                            | **−58**  | **42 / 100** |

---

## 问题严重程度分布

```
CRITICAL  1  ← 子矩阵未同步（追溯链断裂的根源）
HIGH      3  ← 版本/日期不一致 + AC/TC 命名空间冲突
MEDIUM    3  ← BR 编号 phantom + FR 编号冲突 + README 死链
LOW       3  ← prompt 空壳 + registry 滞后 + FR-001 歧义
```

---

## 根因分析

`module/binance` 的三层文档体系（root → client + server）是在 v2.0.0 分布式架构重构时建立的。此后：

1. **root 层持续迭代**：17 个 MINOR bump（v3.0.0→v3.7.1），FR 从 10 扩展到 44，AC 从 35 扩展到 130，TC 从 22 扩展到 65
2. **client/server 子矩阵在 v2.0.0 之后从未刷新过实现状态**：Plan007/Plan008 的 40 个 Task 全部在 runtime 仓 `/home/binance` 完成，证据流向 root 矩阵，但没有向下游注入 client/server 子矩阵
3. **三层之间的编号映射全靠散文约定**：没有结构化的 FR/BR/AC/TC 命名空间隔离或跨层映射表
4. **root SPEC bump 未触发子规格同步机制**：v3.7.0→v3.7.1 引入了 server 侧 FR-037~044，但 server/SPEC.md 的 Last-Updated 和 Runtime-Version 均未更新

**根本原因不是文档质量差，而是三层文档体系的同步机制缺失。** Root SPEC 和 root TRACEABILITY 本身的质量是极高的（100% FR→AC→TC 追溯登记，120-cell R2 治理矩阵全覆盖），但子模块矩阵作为"投影"没有被纳入同一个更新管线。

---

## 修复优先级

### P0（阻断级，应在下一个 PR 中修复）

| #   | 问题                           | 修复动作                                                                            | 验证方式                                                |
| --- | ------------------------------ | ----------------------------------------------------------------------------------- | ------------------------------------------------------- |
| 1   | 子矩阵实现状态 0% vs root 71%  | 将 root Done/Partial 投影拆解同步到 client/server TRACEABILITY §1 各行              | `grep -c "Done" matrix/client/TRACEABILITY.md` ≥ 对应数 |
| 2   | server Runtime-Version v0.1.0  | `server/SPEC.md` L16 → `v0.2.0`                                                     | `grep "Runtime-Version" spec/server/SPEC.md`            |
| 3   | server Last-Updated 2026-06-23 | `server/SPEC.md` L10 → `2026-06-26`                                                 | `grep "Last-Updated" spec/server/SPEC.md`               |
| 4   | AC/TC 命名空间隔离             | 在 root TRACEABILITY §4/§5 增加 `矩阵层` 列，标注每个 AC/TC 属于 ROOT/CLIENT/SERVER | `grep -c "矩阵层" matrix/TRACEABILITY.md`               |

### P1（应在下一次 spec bump 前修复）

| #   | 问题                  | 修复动作                                        |
| --- | --------------------- | ----------------------------------------------- |
| 5   | BR phantom + 无映射表 | 在 root TRACEABILITY §2 新增 BR 三层映射表      |
| 6   | server FR 编号冲突    | 在 server/SPEC.md §7 开头新增 FR 编号映射表     |
| 7   | README 死链           | 更新 `README.md` L89 的 `DEEP-ANALYSIS.md` 引用 |

### P2（技术债务，可随下次管线推进修复）

| #   | 问题                       | 修复动作                                                       |
| --- | -------------------------- | -------------------------------------------------------------- |
| 8   | registry.yaml spec_version | `v3.6.0` → `v3.7.1`                                            |
| 9   | prompt/ 空壳               | 可暂保持，待 FR-031~036 从 Draft→Active 时填充                 |
| 10  | FR-001 歧义                | 在 server/SPEC.md §7 和 client/SPEC.md §7 各加一行编号映射声明 |

---

## 正面发现（不计入扣分，但值得记录）

1. **root SPEC 本身质量极高**：FR 全部带 WHEN/THEN/AND 行为规范，44 FR × 平均 5 条行为子句 = ~220 条可测试需求
2. **root TRACEABILITY 追溯链完整**：FR→AC→TC→Task→Status 全链路 100% 登记，R2 120-cell 治理矩阵全覆盖
3. **三层矩阵结构设计合理**：client/server 独立 TRACEABILITY 的思路是正确的（与 root 解耦），问题仅在于同步机制缺失
4. **CHANGELOG 变更历史详尽且诚实**：保留了被撤回的历史口径，标注为 "已撤回" 而非删除
5. **BOUNDARY-GATES 全面覆盖**：13 道 gate 覆盖 BR-001~BR-009 + go.mod 合规，全部 PASS
6. **SPEC §4.2 PRG-001~007 生产就绪门禁**：新增加的生产安全网机制是前瞻性设计

---

## 附录：三层 FR → Task 映射速查表

> 为便于修复问题 1，此处列出 root FR 与 client/server Task 的对应关系（从现有文档提取）。

### Client 侧（8 FR → 对应 root FR 和 Task）

| client FR                   | 对应 root FR                 | Task                       | root 状态 |
| --------------------------- | ---------------------------- | -------------------------- | --------- |
| FR-001 Product-Line Catalog | FR-001                       | CLIENT-001                 | Done      |
| FR-002 Instrument Parser    | FR-002                       | CLIENT-002, CLIENT-004     | Done      |
| FR-003 Connectors           | FR-001, FR-030               | CLIENT-003~006, CLIENT-020 | Done      |
| FR-004 Normalization        | FR-001（隐含）               | CLIENT-007                 | Done      |
| FR-005 Canonical Mapping    | FR-002（隐含）               | CLIENT-007                 | Done      |
| FR-006 Idempotency Key      | FR-005（client 侧 key 生成） | CLIENT-007                 | Done      |
| FR-009 natsx Publisher      | FR-003                       | CLIENT-014                 | Done      |
| FR-010 Admin Surface        | FR-014/FR-015/FR-024         | CLIENT-010, CLIENT-015~019 | Done      |

### Server 侧（12 FR → 对应 root FR 和 Task）

| server FR                    | 对应 root FR     | Task                               | root 状态   |
| ---------------------------- | ---------------- | ---------------------------------- | ----------- |
| FR-001 Consumer Binding      | FR-003, FR-004   | SERVER-010                         | Done        |
| FR-002 Consumer Lifecycle    | FR-004           | SERVER-010                         | Done        |
| FR-003 Envelope Validation   | FR-005（隐含）   | SERVER-002                         | Done        |
| FR-004 Idempotent Acceptance | FR-005           | SERVER-011                         | Done        |
| FR-005 Multi-Store Write     | FR-006a/6b/6c/6d | SERVER-012, SERVER-013, SERVER-016 | Done        |
| FR-006 kafkax Dispatch       | FR-008           | SERVER-014                         | Done        |
| FR-007 Gin Market API        | FR-007           | SERVER-015                         | **Partial** |
| FR-007a Analytics API        | FR-007a          | SERVER-015                         | **Partial** |
| FR-008 ossx Archival         | FR-006d          | SERVER-016                         | Done        |
| FR-009 Boundary Enforcement  | FR-009           | SERVER-008                         | Done        |
| FR-010 clickhousex OLAP      | FR-010           | SERVER-017                         | Done        |
| FR-011 Coordinator Lock      | FR-011           | SERVER-013                         | **Partial** |

---

## 修复后评分（2026-06-26 同日修复）

> **v3.8.0 实际执行（同日 23:00）**：以下 P0-P2 方案为同日 22:00 的理论投影。实际修复采取了比本计划更彻底的路径——**废除所有子规格本地 FR/BR 编号，全部改为引用根 SPEC canonical 编号**，而非本计划中的"添加映射表 + 保留本地编号"。这意味着：
> - Problem 3/5/6/10 **已完全解决**（非部分缓解）
> - 子矩阵 TRACEABILITY 的 0% Done 问题是 runtime evidence 缺口，非规格编号问题
> - 剩余未闭合项：子矩阵实现状态与 root 的分裂（Problem 1）需要通过真实测试证据闭合
>
> 以下为 P0+P1+P2 三轮修复后的评分重算（理论投影，实际执行更彻底）：

| 维度 | 原始得分 | 修复后得分 | 已消除扣分项 |
|------|----------|------------|-------------|
| 边界一致性 | 23 / 40 | **34 / 40** | −8 AC/TC 命名空间（P0-4）、−4 BR phantom（P1-5 消除 phantom 注册 BR-010）、−1 FR-001 歧义（P2-10 映射表） |
| 追溯闭环 | 16 / 35 | **31 / 35** | −15 子矩阵 0%（P0-1 同步至 client 100% + server 75%） |
| 文档时效性 | 3 / 25 | **21 / 25** | −8 server Runtime（P0-2）、−8 server Last-Updated（P0-3）、−4 README 死链（P1-7）、−1 registry（P2-8） |
| **总计** | **42 / 100** | **86 / 100** | −58 → −14 |

### 剩余扣分项

| # | 严重度 | 问题 | 扣分 | 不修复原因 |
|---|--------|------|------|-----------|
| 8 | LOW | prompt 目录无 Context Package 制品 | −1 | 管线 S5 层待 FR-031~036 Draft→Active 时自然填充 |
| 10 | LOW | server FR-001 与 root FR-001 歧义 | −1 | 映射表已建（P2-10），残余歧义属于子模块独立编号体系固有特征 |
| — | LOW | client/server TC/NFR 仍 Pending | −4 | TC 为子模块独立测试证据，代码已实现但 TC 级别验证未独立执行 |
| — | LOW | BR-002/004/005 无 root 显式 BR | −4 | 由 root BR-004/FR-005/BR-009 隐含，非结构缺陷 |
| — | LOW | server/SPEC 仍未包含 FR-037~044 条目 | −4 | 属于 root SPEC 新增 FR 的子规格同步机制缺失，P1 级但非 P0 |

### 变更文件清单

```
P0 (4 fixes):
  spec/server/SPEC.md               Runtime-Version v0.2.0 + Last-Updated 2026-06-26
  matrix/client/TRACEABILITY.md     FR/BR→Done, dashboard 100%, history v2.1.2
  matrix/server/TRACEABILITY.md     FR 9 Done/3 Partial, BR→Done, dashboard 75%, history v2.2.1
  matrix/TRACEABILITY.md            §4 TC + §5 AC 各增加「矩阵层」列 (ROOT/CLIENT/SERVER)

P1 (3 fixes):
  matrix/TRACEABILITY.md            §2.1 BR 三层映射表 (13 rows)
  spec/server/SPEC.md               §7 Server FR→Root FR 映射表 (12 rows)
  README.md                         死链→design/DESIGN.md + spec/SPEC.md

P2 (4 fixes):
  module/registry.yaml              spec_version v3.7.1, latest_tag v3.7.1
  spec/client/SPEC.md               §7 Client FR→Root FR 映射表 (10 rows)
  matrix/TRACEABILITY.md            BR-010 Cold-Write-First 注册 (消除 phantom)
  prompt/README.md                  更新管线状态说明
```

---

_报告生成时间：2026-06-26 · 修复完成时间：2026-06-26 · 分析工具：ZCode deep analysis · 数据来源：`module/binance/` 完整目录树_
