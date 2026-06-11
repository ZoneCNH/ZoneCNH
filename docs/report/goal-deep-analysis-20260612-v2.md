# `docs/goal/` 深度分析报告 v2

**分析日期**：2026-06-12
**分析方法**：全量文档审读 + 工具链验证 + 元数据分析
**分析范围**：30 个核心文档 + 30 章 RSI 标准 + 8 个 YAML Schema + 9 个工具脚本 + 部署包 + 变更请求

---

## 1. 体系全景

### 1.1 规模统计

| 维度 | 数据 |
|------|------|
| 总行数 | **~11,047 行**（纯文档），含工具 ~18,000+ 行 |
| 核心文档 | **30 个** (00-authority-map 至 26-rsi-full-standard) |
| RSI 子标准 | **30 章**（rsi-standard/ 子目录） |
| YAML Schema | **8 个** (4 数据 + 4 契约) |
| 可执行工具 | **9 个脚本**（4 Bash + 5 Python） |
| 变更请求 | **1 个已记录** (CR-20260610) |
| 术语定义 | **53 条** (GLOSSARY.md) |
| 单文件最大 | `goal-delivery.sh` (2,164 行 Shell) |

### 1.2 文件分层

```text
00-03   基础层：权威映射 → 快速开始 → 方法论 → 管线状态机
04-08   治理层：Gate 体系 → 层级标准 → DoD → ID 系统 → 质量门禁
09-11   执行层：模板库 → Lint 规则 → AI 协作
12-19   运营层：运营管理 → 运行引擎 → Agent 协议 → Registry → CI/CD → 风险决策 → 成熟度 → 自改进
20-26   高级层：指标证据 → 受控 RSI → Delivery OS → 治理检查 → 统一分析 → 执行指南 → RSI 完整标准
```

### 1.3 层级依赖热力图

```text
                   00-authority-map ←── 最高治理入口
                   /        |        \
          01-methodology  02-goal   03-pipeline
          /    \           /   \        |
    04-gates  05-layer  06-dod  07-id  08-quality
         \      /  \      |      |
          09-templates  10-lint  11-ai-collab
              \         /       /
              12-operations ←── 13-runtime ←── 14-agent-protocols
                    |              |              |
               15-registry    16-ci-cd    17-risk-decisions
                                   \         /
                                18-maturity → 19-self-improving
                                     |
                              20-metrics → 21-controlled-rsi
                                    |           |
                              22-delivery-os  23-governance
                                     \         /
                              24-unification-analysis
                                     |
                              25-execution-guide → 26-rsi-full-standard
```

---

## 2. 核心设计评估

### 2.1 设计亮点

#### A. 权威映射体系（00-authority-map.md）— 评级：★ ★ ★ ★ ★

这是整个体系最出色的设计决策。每个概念都有明确的 SSOT（单一事实来源）定义位置，区分了"权威定义"和"可引用/投影"位置，并明确禁止事项。这从根本上防止了文档漂移。

**关键机制**：
- SSOT 表覆盖 25 个主题的权威位置
- 四轴状态模型（`pipeline_state` / `current_phase` / `phase_status` / `workflow_step`）清晰分离了全局状态、层级进度、局部进度和执行步骤
- 配置与运行态边界表明确了哪些目录可提交、哪些不可提交

#### B. 工具链自举（self-test.sh + 负例 fixture）— 评级：★ ★ ★ ★ ★

工具链自身有正负例自测是罕见的工程纪律。当前覆盖 7 类 fixture（旧状态、格式错误 ID、缺失 Evidence、Matrix orphan、Gate 不一致、控制面不一致、Release gate 阻断），45/45 PASS。

#### C. Matrix 横切模型 — 评级：★ ★ ★ ★ ☆

将追溯矩阵定义为横切制品而非管线阶段是正确的架构决策。64 edge 100% 终态覆盖率，canonical edge 模型（`source_id` / `target_id` / `relation` / `status` / `evidence_id` / `gate_id` / `owner` / `updated_at`）清晰可验证。

#### D. Controlled RSI 的安全边界 — 评级：★ ★ ★ ★ ★

R0-R9 Gate 体系对自改进做了精细的分级控制：从 R0 证据摄入到 R9 复盘度量，每层都有明确的阻断条件。禁止自动改动的 7 类资产清单和不变量清单构成了有效的安全围栏。

### 2.2 设计关注点

#### A. 愿景文档落地差距（22-delivery-os.md, 23-workflow-governance-checks.md）

两个核心文档标记为"愿景架构（Vision）"，描述的目标形态（五个运行时、Workflow Compiler、Prompt Compiler、Release Drills）与当前实际可执行能力之间存在显著差距。

**具体差距**：

| 愿景能力 | 当前状态 | 差距 |
|----------|----------|------|
| Workflow Compiler（编译 Goal→Task 清单） | `goal-delivery.sh --compile` 已落地 | ✅ 已闭合 |
| Prompt Compiler（控制面→执行约束） | 手工 Context Package | 🟡 半自动 |
| Evidence Bundle 自动聚合 | 手工组装 | 🟡 roadmap Phase 3 |
| Release Simulation | 未自动化 | 🔴 roadmap Phase 4 |
| Eval Dataset 积累 | 未启动 | 🔴 roadmap Phase 5 |

**建议**：要么加速 Phase 4/5 落地，要么将愿景文档降级为"附录：未来方向"，避免新读者将愿景当成当前能力。

#### B. 文档量与实用性张力

11,000+ 行方法论文档对于一个"文档枢纽仓库"（本身不包含应用代码）来说体量巨大。核心问题是：**~70 个下游仓库的实际采纳率是多少？**

当前 CHANGELOG 记录了大量的自我修正（断链修复、SSOT 消除、格式统一、状态澄清），说明文档在持续迭代中日趋完善，但这些修正主要发生在体系内部。缺乏对下游仓库采纳情况的量化跟踪。

**建议**：在 `deploy/roadmap.md` 或 `18-maturity.md` 中增加"下游采纳率"指标（如：多少仓库已初始化 `.config/goal/`、多少仓库 Gate 通过率 > 80%）。

#### C. 跨平台 Agent 语义漂移（已记录但未全部修复）

`agent-cross-platform-compatibility.md` 记录了 3 个 MEDIUM 级漂移：

1. **G10 阻断条件 7 vs 8 项**：Claude 端缺少 Agent 隔离违规检查
2. **Matrix Verified 定义 2 链路 vs 4 链路**：Claude 要求 Code+Test，Codex/Copilot 要求 Code+Test+Evidence+Gate
3. **Claude 独有功能未投影**：Prompt Chain 7 步、Failure Budget、AutoResearch、Evidence 类型分类

这些差异如果不在 CI 中强制检查，可能导致不同平台的 Agent 做出不同的 Gate 裁决。

#### D. RSI 标准的定位模糊

`26-rsi-full-standard.md`（RSI-SG-001）从 43KB 单文件拆成了 30 章独立文档，内容覆盖 R0-R5 分级、四层边界（模型/系统/组织/生态）、Gate A-X 放行门禁、T1-T15 不可接受风险阈值等——这是一个面向"前沿模型实验室"的 AI 安全治理标准草案。

但 `21-controlled-rsi.md` 是工程工作流层面的受控改进机制，两者的关系是"21 聚焦工程 RSI，26 覆盖全谱系 RSI 治理"。对于这个不包含模型训练代码的文档枢纽仓库，30 章 RSI 标准的实用性存疑。

**建议**：明确 RSI 完整标准的读者是谁（ZoneCNH 的 AI 安全审计团队？外部评估机构？），如果目前没有直接使用场景，可降级为参考附录。

---

## 3. 工具链验证结果

### 3.1 实测通过项

```
✅ goal-workflow.sh preflight  PASS (errors=0, warnings=1)
✅ lint-goal.sh               PASS (G-LINT 3/7 automated, 5/7 checked)
✅ matrix-gen.py --check-only PASS (64 edges, 100% 覆盖率)
✅ goal-validate.py --strict  PASS (验证通过)
✅ self-test.sh               PASS (45/45 用例通过)
✅ rule-drift-check.py        PASS (10/10 checks)
```

### 3.2 当前警告

```
WARN: CR-20260610-goal-protected-assets-sync.md G-LINT-005 [需人工确认]: Goal 可能缺少目标用户/角色说明
```

这是变更请求文件被 Lint 扫描到——CR 文件不应被当作 Goal 文件来 Lint。建议在 `lint-goal.sh` 中排除 `change-requests/` 目录。

---

## 4. 成熟度评估

### 4.1 自评校准

体系自评 L3（标准化），综合统一度 85/100。我的独立评估：

| 维度 | 自评 | 独立评估 | 说明 |
|------|------|----------|------|
| 方法论完整性 | — | 92/100 | 30 文档覆盖从 Goal 到 Retrospective 全链路 |
| 工具链执行力 | — | 85/100 | 9 脚本 + CI 集成 + 自测体系，扎实 |
| 跨平台一致性 | 82 | 78/100 | 存在 3 个 MEDIUM 漂移未修复 |
| 下游可采纳性 | — | 65/100 | 部署包完善，但缺乏采纳率数据 |
| 治理闭环 | — | 88/100 | Authority map + SSOT + Gate + CR 体系完整 |
| 自改进机制 | — | 80/100 | R0-R9 设计优秀，但 Eval Dataset 为空 |

**综合独立评估：82/100**（略低于自评 85，主要扣分在下游采纳率和跨平台语义一致性）

### 4.2 Phase 路线图校准

```text
Phase 1 ✅ 基础管线           → L3，已落地
Phase 2 ✅ Workflow Compiler   → L3+，MVP 已落地
Phase 3 ✅ Contract Layer      → L3+，MVP 已落地
Phase 4 ✅ Five Runtimes       → L4，部分落地（drills 已实现）
Phase 5 🟡 Self-optimizing     → L5，MVP 已落地但 Eval Dataset 为空
```

路线图声称 5 个 Phase 全部 "✅ 已完成"，但实际上 Phase 4 的部分验收项（Evidence Bundle 自动聚合、DAG 可视化）和 Phase 5 的全部核心验收项（Scorecard 自动触发、Eval Dataset ≥ 100 案例、Capture Rate ≥ 80%）均未完成。建议将 Phase 4/5 标记改为 "🟡 MVP 落地，完整版进行中"。

---

## 5. 结构性问题清单

### 5.1 P0（影响正确性）

无当前 P0 问题。之前发现的主要问题（Codex 幻影引用、Claude 缺少 CONSTITUTION.md 引用）已于 2026-06-12 修复。

### 5.2 P1（影响一致性）

| # | 问题 | 位置 |
|---|------|------|
| 1 | Matrix Verified 定义跨平台不一致（2 链路 vs 4 链路） | `agent-cross-platform-compatibility.md` §3.5.2 |
| 2 | G10 阻断条件 Claude=7 vs Codex/Copilot=8 | 同上 §3.5.1 |
| 3 | CR 文件被 lint-goal.sh 扫描并报告 WARN | `lint-goal.sh` 缺少 change-requests/ 排除 |
| 4 | Phase 4/5 标记为 "✅ 已完成" 但核心验收项未达成 | `deploy/roadmap.md` |

### 5.3 P2（影响清晰度）

| # | 问题 | 位置 |
|---|------|------|
| 5 | 愿景文档（22、23）与当前能力的差距未在文档内标注 | `22-delivery-os.md`, `23-workflow-governance-checks.md`（虽有 Vision 标签，但未列具体差距） |
| 6 | 30 章 RSI 标准的实用性和目标读者不清晰 | `rsi-standard/` |
| 7 | 缺少下游仓库采纳率的量化跟踪指标 | `18-maturity.md`, `deploy/roadmap.md` |
| 8 | Copilot/Codex Agent 缺少精简文档索引（已记录为 P3 建议，建议升级为 P2） | `agent-cross-platform-compatibility.md` §7.5 |

---

## 6. 架构决策记录

本次分析期间识别到的关键架构决策：

| 决策 | 判断 | 理由 |
|------|------|------|
| Matrix 作为横切制品而非管线阶段 | ✅ 正确 | 避免管线膨胀，Matrix 本质是跨阶段索引 |
| 四轴状态模型 | ✅ 正确 | 清晰分离全局状态/层级/进度/执行，防止状态语义混淆 |
| SSOT + 投影模式 | ✅ 正确 | 每个概念一个权威源，其余位置只引用，这是防止文档腐烂的最有效机制 |
| Controlled RSI 的分级 Gate (R0-R9) | ✅ 正确 | 既允许自动化改进，又设置了硬性安全边界 |
| docs/goal/ 不覆盖 Constitution | ✅ 正确 | 治理层级清晰：Constitution > docs/goal > 模块文档 |
| 模块代码路径 `/home/{module}` 与制品路径 `module/{module}/` 分离 | ✅ 正确 | 源码和制品物理隔离，防止规格仓库承载实现代码 |

---

## 7. 改进路线图建议

### 短期（1-2 周）
1. **统一 G10 阻断条件为 8 项**（补入 Agent 隔离检查）
2. **统一 Matrix Verified 为四链路**（Code+Test+Evidence+Gate）
3. **修复 lint-goal.sh 排除 change-requests/ 目录**
4. **修正 roadmap Phase 4/5 状态标签**（区分"MVP 落地"和"完整版完成"）

### 中期（1-2 月）
5. **启动 Eval Dataset 积累**（每个 Release 的失败/成功案例自动归档）
6. **建立下游仓库采纳率仪表板**（至少追踪 ~70 仓库中有多少启用了 `.config/goal/`）
7. **Phase 4 完整落地**：Evidence Bundle 自动聚合 + DAG 可视化

### 长期（3-6 月）
8. **Phase 5 完整落地**：Scorecard 自动触发 RSI Proposal
9. **RSI 标准实用化**：明确目标读者，或降级为参考附录
10. **愿景文档落地或重分类**：22/23 号文档要么加速实现，要么明确标注"计划中，预计 2027-Q3"

---

## 8. 总结

`docs/goal/` 是一个**设计精良、执行扎实、自洽性强**的 Goal 驱动交付方法论体系。它的核心优势在于：

- **权威映射体系**从根本上防止了文档腐烂
- **自测工具链**（45/45 PASS, 7 类 fixture）建立了对工具正确性的信心
- **Controlled RSI 的 R0-R9 Gate** 在自动化和安全性之间取得了罕见的平衡
- **三平台 Agent 兼容性审计**体现了工程纪律

主要改进空间在于：
- **跨平台语义一致性**（2 个 MEDIUM 漂移待修复）
- **愿景与现实的差距管理**（22/23 号文档的能力标注）
- **下游采纳的量化闭环**（目前只知自己的仓库状态，不知 ~70 个下游仓库的状态）

**一句话判断**：这是一个"对自己要求很高"的元方法体系——用自己定义的方法管理自己的演进，并且做得相当好。当前核心瓶颈不是缺少规则，而是需要将这套规则的采纳从 1 个仓库扩展到 ~70 个仓库。
