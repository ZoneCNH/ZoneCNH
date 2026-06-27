# Goal 驱动交付管线 — 结构性问题深度诊断与评分

> 分析日期：2026-06-27
> 分析范围：`docs/goal/` + `.config/goal/` + `module/*/goal/` + `.foundationx/`
> 方法：代码证据驱动的结构化诊断，6 个问题 × 3 维度评分 × 优先级排序

---

## 评分方法

每个问题按三个维度评分：
- **严重度** (Severity)：对体系一致性和可靠性的影响（1-10）
- **影响面** (Blast Radius)：受影响的模块/流程数量（1-10）
- **修复难度** (Fix Difficulty)：修复所需的工作量和风险（1-10，越低越易修）

**综合分** = `严重度 × 影响面 / 修复难度`（越高越需要优先处理）

---

## 问题一：双管线并存 — 结构性裂痕

[COMPUTED, HIGH]

### 证据

两套管线在 `AGENTS.md` 中并列存在，共享 6 个相同阶段但使用完全不同的治理机制：

| 维度 | Goal 管线 | Spec→Code 管线 |
|------|-----------|----------------|
| 阶段数 | 11（含 G0-G11 门禁） | 6（S1-S6） |
| 门禁机制 | 四态裁决 (PASS/PASS_WITH_RISK/FAIL/BLOCKED) | `composite_score = min(claude, codex, copilot, rules) >= 98` |
| 评分源 | 单源（goal-reviewer） | 四源（claude/codex/copilot/rules）+ arbiter |
| 状态枚举 | 四轴状态模型（13 正常 + 8 异常） | 阶段推进制（Spec→Matrix→Tasks→Plan→Prompt→Code） |
| Agent | 5 个 goal-* Agent | 10+ 个 spec/task/prompt/score Agent |
| 共享阶段 | **Spec / Design / Plan / Tasks / Prompt / Code** | ← 完全相同 |

### 冲突场景

同一模块的 Spec 阶段：
- Goal 管线 G2 Spec Gate 判定 `PASS`（单 reviewer，阈值 90）
- Spec→Code 管线 arbiter 判定 `FAIL`（四源 composite_score < 98）

**没有文档定义哪个裁决优先。** 执行者自主选择管线，或被迫两套都跑。

### 根源

Goal 体系（`docs/goal/`）先建立，Spec→Code 管线（`docs/governance/DEVELOPMENT-WORKFLOW.md`）后建立。两者从未被统一或明确划界。Goal 体系覆盖 Goal→Retrospective 全生命周期，Spec→Code 管线覆盖 Spec→Code 实现阶段，形成**嵌套式重叠**而非互补式分工。

### 影响

- 执行者认知负担倍增（两套状态、两套 Gate、两套 Agent）
- 同一模块可能有两套冲突裁决
- 无冲突时的优先级规则不存在
- binance 模块实际走了 Spec→Code 管线，Goal 管线完全未追踪

| 评分 | 值 |
|------|-----|
| 严重度 | **9** — 同一模块可能有两套冲突裁决 |
| 影响面 | **7** — 影响所有进入开发的模块 |
| 修复难度 | **8** — 需要重新设计阶段职责划分 |
| **综合分** | **7.9** |

---

## 问题二：Gate 阈值体系碎片化

[COMPUTED, HIGH]

### 证据

从 `.config/goal/gates/state.yaml` 中提取所有 Gate 阈值：

| Gate 组 | PASS 阈值 | PASS_WITH_RISK min | 差异 |
|---------|-----------|-------------------|------|
| **标准 G0-G10** (GOAL-20260608-001) | **90** | 80-85 | 基准线 |
| **标准 G11** | **80** | 70 | -10 vs 基准 |
| **Kernel GK-0~GK-7** (GOAL-KERNEL-20260609-001) | **90** | 80-85 | 与标准一致 |
| **Kernel GK-8** (Evidence) | **98** | null（禁止PWR） | **+8** vs 标准 G8 |
| **Kernel GK-9** (Review) | **98** | null（禁止PWR） | **+8** vs 标准 G9 |
| **Kernel GK-10** (Release) | **98** | null（禁止PWR） | **+8** vs 标准 G10 |
| **Kernel GK-11** | **80** | 70 | 与标准一致 |

### 三重不一致

1. **G8/G9/G10 阈值在标准（90）和 kernel（98）之间相差 8 分** — 没有任何文档解释为什么 kernel 的 Evidence/Review/Release Gate 需要更高的阈值
2. **G11（Retrospective）阈值为 80** — 低于所有其他 Gate 的 90，但 `04-gates.md` 没有给出 G11 低阈值的理由
3. **PASS_WITH_RISK 最低值不一致**：G0/G1 = 80，G2-G9 = 85，G11 = 70

### 根源

`04-gates.md` §5 定义了"允许 PASS_WITH_RISK 的 Gate"表，但只列出了阈值，**没有定义阈值推导原则**。kernel 模块的 98 阈值似乎是针对特定模块手工设定的，但缺少 `threshold_rationale` 字段或 ADR 记录。

| 评分 | 值 |
|------|-----|
| 严重度 | **7** — 执行者无法预测某 Gate 的阈值 |
| 影响面 | **5** — 目前仅影响 kernel 模块，但模板化后会扩散 |
| 修复难度 | **3** — 建立统一阈值原则 + 个别调整需 ADR |
| **综合分** | **11.7** |

---

## 问题三：跨系统状态耦合与漂移

[COMPUTED, HIGH]

### 证据：kernel 模块的 Gate 状态与 FoundationX 不一致

**`.config/goal/gates/state.yaml`** (最后更新 2026-06-15)：
```yaml
GK-8 (Evidence):  BLOCKED — "kernel edges are Dropped with empty evidence_id"
GK-9 (Review):    BLOCKED — "缺少四源 98+ arbiter 归档"
GK-10 (Release):  BLOCKED — "kernel in factory_blocking_modules via BLK-011"
```

**`.foundationx/blockers.json`** (最后更新 2026-06-21)：
```json
"BLK-011": {
  "status": "resolved",
  "resolved_at": "2026-06-18",
  "resolution": "factory_evidence_chain_closed"
}
"factory_blocking_modules": [],
"open_blockers": 0
```

**`.foundationx/status/index.json`** (最后更新 2026-06-25)：
```json
"kernel": {
  "factory": true,
  "note": "Factory closed 2026-06-18: Goal Matrix 23 edges Verified ... BLK-011 resolved"
}
```

### 诊断

1. BLK-011 已于 **2026-06-18** 解决
2. FoundationX status/index.json 已于 **2026-06-25** 更新，kernel.factory = true
3. 但 Goal 管线的 gates/state.yaml 中 GK-8/GK-9/GK-10 仍为 **BLOCKED**，最后检查时间为 **2026-06-15**
4. **漂移时长：10 天以上**，且 blocking 原因已不存在

### 后果

Goal 管线对 kernel 模块给出了**错误的阻断信号** — 执行者看到 GK-8/GK-9/GK-10 都是 BLOCKED，但实际上所有阻塞条件已解除。这会导致：
- 不必要的升级和排查
- 对 Gate 体系的信任度下降
- 执行者学会"无视 Gate 状态"

### 根源

Goal 管线的 Gate 状态是**手工快照**而非自动聚合。FoundationX blockers.json 和 Goal gates/state.yaml 之间没有自动同步机制。`25-execution-guide.md` §5 要求"在关闭 release_blocking 风险的同一变更中更新上述快照"，但这一规则在 kernel 案例中被违反。

| 评分 | 值 |
|------|-----|
| 严重度 | **10** — Gate 给出已失效的阻断信号，动摇体系可信度 |
| 影响面 | **6** — 影响所有依赖 FoundationX 的模块 |
| 修复难度 | **4** — 需要自动化同步或 CI 校验 |
| **综合分** | **15.0** |

---

## 问题四：控制面投影与模块 SSOT 的权威冲突

[COMPUTED, MED]

### 证据

权威映射 `00-authority-map.md` 定义了双层 Matrix：

| 位置 | 性质 |
|------|------|
| `.config/goal/matrix/matrix.yaml` | 控制面快照，跨模块 |
| `module/{module}/matrix/TRACEABILITY.md` | 模块 SSOT |

但实际数据呈现三种不一致模式：

**模式 A — 模块有但控制面无**：
```
module/binance/matrix/TRACEABILITY.md      ← 存在
module/binance/matrix/client/TRACEABILITY.md ← 存在
module/binance/matrix/server/TRACEABILITY.md ← 存在
.config/goal/matrix/matrix.yaml             ← 无 binance 条目
```

**模式 B — 控制面有但模块可能不全**：
```
.config/goal/matrix/matrix.yaml 中有 kernel 23 条边
module/kernel/TRACEABILITY.md 中有 12 FR 对应条目
但 ID 体系不同（kernel 用 GOAL-KERNEL-*，控制面用 SPEC-kernel-v1/FR-KERNEL-*）
```

**模式 C — 两边都有但状态可能不一致**（如问题三所示）

### 分析

`00-authority-map.md` 说 `.config/goal/matrix/` 是"可审查矩阵与链路校验结果"，`module/{module}/matrix/` 是"模块级追溯记录（模块 SSOT）"。但 **"模块 SSOT"与"控制面快照"的冲突解决规则不存在**。如果模块 Matrix 显示 `Verified` 但控制面 Matrix 显示 `Dropped`，哪个是真相？

### 根源

两套 Matrix 的生成路径不同：
- 模块 Matrix 由模块开发者/Agent 手工维护
- 控制面 Matrix 由 `matrix-gen.py --check-only` 校验
- 两者没有双向同步机制

| 评分 | 值 |
|------|-----|
| 严重度 | **8** — 同一事实有两个可能矛盾的记录 |
| 影响面 | **7** — 影响所有有 traceability 的模块 |
| 修复难度 | **6** — 需要定义同步协议 + 自动化 |
| **综合分** | **9.3** |

---

## 问题五：binance 模块的管线断层

[COMPUTED, MED]

### 证据

binance 模块是仓库中**制品最完整**的模块之一：

| 制品 | 数量 |
|------|------|
| goal.md | 1（7 条成功标准，4 个 Non-goals） |
| SPEC.md + 子模块 spec | 5 个文件 |
| FEATURES.md + ACCEPTANCE.md | 2 个文件 |
| DESIGN.md + ADR × 3 + 深度分析 × 4 | 8 个文件 |
| PLAN.md（含 client/server 子计划） | 3 个文件 |
| Task 文件（client 14 + server 17 + root 8） | **39 个文件** |
| TRACEABILITY.md（含 client/server） | 3 个文件 |
| gate/ 文件（6 个） | 6 个文件 |
| evidence/（按日期 2026-06-26 归档） | 4+ 个文件 |
| schema/ | 1 个文件 |

但管线状态完全缺失：
```
.config/goal/pipeline/state.yaml  ← 无 binance 条目
.config/goal/gates/state.yaml     ← 无 binance 条目
.config/goal/matrix/matrix.yaml   ← 无 binance 条目
```

### 断层分析

binance 模块在 **Spec→Code 管线**（S1-S6）中推进（证据：`module/binance/design/STRUCTURAL-SCORING-20260626.md` 为 2026-06-26 的结构性评分），但在 **Goal 管线**中完全未被追踪。

这表明两套管线在实际使用中已经**分叉**——binance 走了 Spec→Code 管线而绕过了 Goal 管线。`module/binance/goal/goal.md` 虽存在但从未被 Goal 管线的 pipeline/gate/matrix 消费。

### 根源

Goal 管线的 pipeline 状态是手工维护的 YAML 文件，没有自动发现新模块 Goal 并初始化管线状态的机制。

| 评分 | 值 |
|------|-----|
| 严重度 | **8** — 管线对最完整的模块"不可见" |
| 影响面 | **4** — 目前仅 binance 明显，但其他 58 个模块可能类似 |
| 修复难度 | **5** — 需要自动化模块发现 + 管线初始化 |
| **综合分** | **6.4** |

---

## 问题六：文档体系膨胀 — 入门摩擦过高

[COMPUTED, MED]

### 证据

`docs/goal/` 目录文件统计：
- 核心方法论文档：26 个（00-26）
- RSI 标准子目录：30 章节
- 变更请求：2 个
- 部署指南：2 个
- 工具说明：1 个
- Schema 文件：8 个 YAML
- **总计：60+ 个 Markdown 文件**

新 Agent 首次执行必须按 `25-execution-guide.md` 阅读 9 个文件（顺序固定），完整掌握需要 2-4 小时。对于 XS/S 级任务，学习成本远超任务本身。

`rules.yaml` 中定义了 **47 个正则模式**、**30+ 个禁止文件模式**、**50+ 个允许制品模式**。

### 影响

高入门门槛导致两个后果：
1. 执行者倾向于**绕过 Goal 管线**（如 binance 走 Spec→Code 管线）
2. 如果强制执行全套 Gate，小任务的交付速度被显著拖慢

对比：复杂度分级（XS→XL）虽然存在，但 XS Lite Mode 的文档仍然要求 G0 + G1 上下文恢复和目标定义，对"修一个 typo"来说仍显过重。

| 评分 | 值 |
|------|-----|
| 严重度 | **6** — 不破坏体系正确性，但削弱采纳率 |
| 影响面 | **8** — 影响所有新加入的模块和执行者 |
| 修复难度 | **5** — 需要分层文档 + 自动化引导 |
| **综合分** | **9.6** |

---

## 总分汇总

| # | 问题 | 严重度 | 影响面 | 修复难度 | 综合分 | 优先级 |
|---|------|--------|--------|----------|--------|--------|
| 3 | 跨系统状态漂移 | 10 | 6 | 4 | **15.0** | 🔴 P0 |
| 2 | Gate 阈值碎片化 | 7 | 5 | 3 | **11.7** | 🔴 P0 |
| 6 | 文档体系膨胀 | 6 | 8 | 5 | **9.6** | 🟡 P1 |
| 4 | Matrix 权威冲突 | 8 | 7 | 6 | **9.3** | 🟡 P1 |
| 1 | 双管线并存 | 9 | 7 | 8 | **7.9** | 🟡 P1 |
| 5 | binance 管线断层 | 8 | 4 | 5 | **6.4** | 🟢 P2 |

---

## 优化建议

### P0 — 立即修复

#### 1. 修复 kernel Gate 状态漂移（问题三）

**具体措施**：
- 将 GK-8/GK-9/GK-10 的 verdict 从 `BLOCKED` 更新为 `PASS`（基于已闭合的证据链：BLK-011 resolved 2026-06-18，kernel.factory=true，Goal Matrix 23 edges Verified）
- 在 CI 中增加 `state-consistency-check`：对比 FoundationX blockers.json 与 Goal gates/state.yaml，检测漂移
- 在 `25-execution-guide.md` §5 中增加自动化校验步骤，防止手工快照遗漏
- 风险：低（只是更新已过时的快照）

#### 2. 建立 Gate 阈值统一原则（问题二）

在 `04-gates.md` §5 中增加阈值推导原则：

```markdown
### 阈值推导原则

1. **阻断型 Gate (G0-G10)**: PASS 阈值 = 90，PASS_WITH_RISK min = 85
2. **非阻断型 Gate (G11)**: PASS 阈值 = 80，PASS_WITH_RISK min = 70
3. **阈值提升需 ADR**: 任何偏离上述基准的阈值必须附带 ADR 记录 rationale
4. **G6/G10 零容忍**: 不允许 PASS_WITH_RISK（已存在规则）
```

kernel 的 GK-8/GK-9/GK-10 阈值 98 需要回退到 90 或附带 ADR 解释为什么 kernel 的 Evidence/Review/Release Gate 需要比标准高 8 分。

### P1 — 短期优化

#### 3. 管线统一或明确分工（问题一）

建议方案（二选一）：

**方案 A — 阶段注入**：Spec→Code 管线的四源评分 + arbiter 作为 Goal 管线 G2-G6 的增强校验。`composite_score >= 98` 成为 G2/G3/G4/G5/G6 的补充检查项，而非独立门禁系统。

```text
Goal 管线: G0 → G1 → G2[+四源评分] → G3[+四源评分] → G4[+四源评分] → G5[+四源评分] → G6[+四源评分] → G7 → G8 → G9 → G10 → G11
```

**方案 B — 声明上下游**：Goal 管线负责 G0-G2（Context→Goal→Spec 审批）和 G7-G11（Test→Release→Retrospective）；Spec→Code 管线负责 Spec 审批后的 Matrix→Tasks→Plan→Prompt→Code。两者通过 G5（Task/Matrix Gate）交接。

#### 4. Matrix 双层同步协议（问题四）

在 `00-authority-map.md` 中增加 Matrix 同步规则：

```markdown
### Matrix 同步规则

1. 模块 `matrix/TRACEABILITY.md` 是模块追溯的权威源
2. `.config/goal/matrix/matrix.yaml` 是跨模块控制面快照
3. 每次模块 Matrix 变更后，MUST 同步更新控制面 Matrix（通过 matrix-gen.py --sync）
4. CI 的 matrix-coverage 检查必须对比两者，发现漂移时 FAIL
```

#### 5. 入门路径精简（问题六）

为 XS/S 级任务提供 `quickstart-lite.md`：
- 阅读清单从 9 个文件压缩到 3 个：`00-authority-map.md` + `00-quickstart.md` + `25-execution-guide.md`（仅 §1-§4）
- Lite Mode 预配置模板：Goal → DoD → Code → Test → Evidence → Review（6 步替代 11 步）
- 在 `00-quickstart.md` 顶部增加"我只想快速开始"一节，直接跳转到 Lite Mode

### P2 — 中期改进

#### 6. 自动化模块发现与管线初始化（问题五）

```bash
# 新增命令：扫描 module/*/goal/goal.md 并与 pipeline/state.yaml 对比
bash docs/goal/tools/goal-workflow.sh discover
# 输出：未追踪的 Goal 列表 + 建议初始化命令
```

同时：
- 新增模块 Goal 时，在 pre-commit hook 中检测并提示
- 在 CI summary 中增加 "未追踪 Goal" 计数

---

## 总体评分

| 维度 | 得分 | 满分 | 说明 |
|------|------|------|------|
| 概念完整性 | 85 | 100 | 核心概念（Goal→Evidence 闭环）自洽且严谨 |
| 实现一致性 | **58** | 100 | 阈值碎片化、状态漂移、双管线冲突 |
| 可操作性 | 70 | 100 | 命令入口清晰但入门文档过重 |
| 可扩展性 | **55** | 100 | 新模块接入管线存在手工断层 |
| 跨系统一致性 | **42** | 100 | Goal 管线与 FoundationX/Spec→Code 管线缺乏同步 |
| **加权总分** | **62** | 100 | 体系设计优秀，工程落地有显著改进空间 |

---

## 核心结论

Goal 驱动交付管线的方法论设计是出色的——11 层主流程 + 12 Gate 纵深防御 + 四轴状态模型 + 全链路 ID 追溯是一条完整的"从目标到证据"的工程哲学。

但**工程落地的治理债务**正在侵蚀体系的可信度：

1. **最紧迫**：kernel 的 Gate 状态已漂移 10 天以上，给出了错误的阻断信号
2. **最隐蔽**：两套管线在实际使用中已分叉（binance 走了 Spec→Code 而非 Goal 管线）
3. **最基础**：Gate 阈值缺少统一推导原则，同一 Gate 在不同模块可能差 8 分
4. **最根本**：体系设计追求严谨性最大化，但可及性不足导致执行者寻找绕过路径

这些问题不解决，体系会从"强制严谨"退化为"可绕过的仪式"。修复优先级应遵循：先止血（P0 状态漂移 + 阈值原则），再治本（P1 管线统一 + 入门精简），最后提效（P2 自动化发现）。
