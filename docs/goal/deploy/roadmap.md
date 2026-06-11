# Delivery OS 落地路线图

> 基于 `docs/report/goal-deep-analysis-20260612.md` 深度分析，将 `22-delivery-os.md` 和 `23-workflow-governance-checks.md` 的愿景架构分解为 5 个可执行 Phase。

生成日期：2026-06-12
当前成熟度：L3（标准化）→ 目标：L5（自优化）

---

## 总览

```text
Phase 1 ──→ Phase 2 ──→ Phase 3 ──→ Phase 4 ──→ Phase 5
  ✅ 已完成    🟡 近期      ⬜ 中期      ⬜ 远期      ⬜ 愿景
  基础管线    Compiler    Contract    Runtimes    自优化
  L3           MVP         Layer       完整版       L5
```

---

## Phase 1 — 基础管线 ✅ 已完成

**状态**：已落地，对应 L3 成熟度。

### 已实现

| 组件                   | 实现                                                        |
| ---------------------- | ----------------------------------------------------------- |
| 11 层主流程管线        | `03-pipeline.md` + 四轴状态模型                             |
| G0-G11 Gate 体系       | `04-gates.md` + `goal-validate.py` strict 模式              |
| Matrix Edge Model      | canonical edge + 8 relation + `matrix-gen.py`               |
| 4 个 YAML Schema       | goal / matrix / evidence / state-dictionary                 |
| 核心 5 Agent（三平台） | goal-spec / matrix / reviewer / prompt-builder / evidence   |
| 统一工作流入口         | `goal-workflow.sh`（preflight/validate/gate/ci/release）    |
| 端到端编排             | `goal-delivery.sh` v2（11 层制品创建 + Gate 委托）          |
| 工具链自举             | `self-test.sh`（7 类正负例 fixture）                        |
| Controlled RSI         | `21-controlled-rsi.md`（R0-R9 Gate + 四策略级别）           |
| 最小部署包             | `docs/goal/deploy/README.md`（3 级采纳指南）                |
| CI 集成                | `goal-ci.yml` + `goal-release-gate.sh` + self-hosted runner |

### 验证命令

```bash
bash docs/goal/tools/goal-workflow.sh validate
python3 docs/goal/tools/goal-validate.py --mode strict
python3 docs/goal/tools/matrix-gen.py --check-only
```

---

## Phase 2 — Workflow Compiler MVP 🟡 近期

**目标**：从手工编写 Prompt → 半自动生成 Context Package。Lint 规则 100% 自动化。

**预估工作量**：2-4 周

### 2.1 Workflow Compiler（最小可用版）

| 功能                    | 输入                       | 输出                     | 优先级 |
| ----------------------- | -------------------------- | ------------------------ | ------ |
| `workflow compile`      | Goal + Spec + Matrix       | 任务列表 + Gate 要求     | P0     |
| `workflow lint`         | 控制面目录                 | 结构化错误报告（JSON）   | P0     |
| `workflow prompt build` | Task + Matrix + 代码上下文 | Context Package markdown | P1     |

**实现方式**：扩展 `goal-delivery.sh auto` 命令，增加 `--compile` 模式。

```bash
# 从 Goal 编译出完整任务清单
bash docs/goal/tools/goal-delivery.sh auto --compile --goal-id GOAL-YYYYMMDD-NNN

# 为单个 Task 生成 Prompt Pack
bash docs/goal/tools/goal-delivery.sh prompt --task-id TASK-xxx --compile
```

### 2.2 Lint 规则 100%

| 规则   | 当前                        | 目标  |
| ------ | --------------------------- | ----- |
| G-LINT | 3/7 automated               | 7/7   |
| S-LINT | 8/8（3 automated + 5 semi） | 8/8   |
| M-LINT | 8/8                         | 8/8   |
| P-LINT | 10/10                       | 10/10 |
| C-LINT | 2/7                         | 5/7   |

剩余 5 条 manual 规则（G-LINT-003/004/005/007 + C-LINT 部分）→ semi-automated。

### 2.3 验收

- [ ] `goal-delivery.sh auto --compile` 可从 Goal 生成完整 Task 清单
- [ ] `goal-delivery.sh prompt --compile` 可生成含 allowed files + 验证命令的 Prompt Pack
- [ ] Lint 自动化率 87.5% → 95%+
- [ ] `goal-workflow.sh validate` 全部通过

---

## Phase 3 — Contract Layer + Evidence Runtime ⬜ 中期

**目标**：关键边界写成可检查契约。Evidence 收集从手工 → 自动关联。

**预估工作量**：4-8 周

### 3.1 契约层

为以下契约建立 YAML schema + 自动校验：

| 契约                      | Schema                           | 校验工具                             |
| ------------------------- | -------------------------------- | ------------------------------------ |
| State Machine Contract    | 从 `03-pipeline.md` 提取转换规则 | `goal-validate.py --check-contracts` |
| API/Data Contract         | 字段、兼容性、迁移规则           | 新增 `contract-check.py`             |
| Privacy/Security Contract | 权限、密钥、数据保留             | 新增（复用 rule-drift-check 模式）   |
| Performance Contract      | 延迟、吞吐、资源                 | 新增                                 |
| Reliability Contract      | 回滚、降级、重试                 | 与 Release Manifest 联动             |
| Observability Contract    | 指标、日志、追踪                 | 与 Metrics Validation Check 联动     |

### 3.2 Evidence Runtime 增强

| 功能            | 当前                              | 目标                                         |
| --------------- | --------------------------------- | -------------------------------------------- |
| Evidence 收集   | `evidence-collect.sh`（手工调用） | CI 自动触发，关联 Task ID                    |
| Evidence Graph  | 概念存在                          | DAG 可视化（`matrix-gen.py --graph`）        |
| Evidence Bundle | 手工组装                          | `goal-delivery.sh release --bundle` 自动聚合 |

### 3.3 验收

- [x] 6 个契约各有一个 `.schema.yaml`（state-machine-contract + api-data-contract + security-contract + ops-contract，含 performance/reliability/observability 三段）+ `goal-validate.py` 集成
- [ ] `goal-delivery.sh release --bundle` 自动生成 Evidence Bundle
- [ ] `matrix-gen.py --graph` 输出追溯 DAG

---

## Phase 4 — 完整 Five Runtimes + Release Drills ⬜ 远期

**目标**：`22-delivery-os.md` 中五个 Runtime 全部有对应可执行工具。发布演练可自动化。

**预估工作量**：8-12 周

### 4.1 五个 Runtime 落地

| Runtime             | 核心工具                                                   | 新增/增强     |
| ------------------- | ---------------------------------------------------------- | ------------- |
| Intent Runtime      | goal-spec Agent + `goal-delivery.sh goal/spec/design`      | ✅ 已有       |
| Control Runtime     | goal-matrix + goal-reviewer + `goal-validate.py`           | ✅ 已有       |
| Execution Runtime   | goal-prompt-builder + `goal-delivery.sh plan/tasks/prompt` | 🟡 Phase 2    |
| Evidence Runtime    | goal-evidence + `evidence-collect.sh` + `gate-check.sh`    | 🟡 Phase 3    |
| Improvement Runtime | RSI R0-R9 + `21-controlled-rsi.md`                         | 🟡 增强自动化 |

### 4.2 Release Drills

| 演练                        | 实现方式                                                    |
| --------------------------- | ----------------------------------------------------------- |
| Release Simulation          | `goal-delivery.sh release --simulate`（dry-run 发布路径）   |
| Rollback Drill              | `goal-delivery.sh release --rollback-drill`（验证回滚路径） |
| Progressive Delivery Matrix | 在 Release Manifest 中增加 `progressive_delivery` 段        |
| Metrics Window Check        | `goal-delivery.sh release --metrics-window`                 |
| Incident Handoff            | 模板 + CI 检查                                              |

### 4.3 验收

- [ ] 五个 Runtime 各有至少一个可执行入口
- [ ] `goal-delivery.sh release --simulate` 可演练完整发布路径
- [ ] Release Simulation 失败时 G10 阻断

---

## Phase 5 — Self-optimizing（L5 成熟度）⬜ 愿景

**目标**：RSI 闭环从"人工触发"升级为"基于 Scorecard 自动触发提案"。

**预估工作量**：持续迭代

### 5.1 自动化 RSI 触发

```text
Scorecard 指标异常 → 自动生成 Improvement Proposal → R0-R9 Gate → Human Approval → Apply
```

### 5.2 Eval Dataset 持续积累

- 每个 Release 的 failure/success 案例自动归档
- `workflow test` 用历史案例回放新规则
- Capture Rate 和 False Positive Rate 自动计算

### 5.3 跨仓库指标面板

- 从 ~70 个独立仓库采集 Goal 达成率、Gate 通过率、RSI 改进效果
- 统一 Scorecard 面板

### 5.4 验收

- [ ] Scorecard 指标异常可自动触发 RSI Proposal
- [ ] Eval Dataset ≥ 100 个案例
- [ ] Capture Rate ≥ 80%，False Positive Rate ≤ 10%

---

## 里程碑时间线

```text
2026-06  ✅ Phase 1 完成（当前）
2026-07  🟡 Phase 2 启动：Workflow Compiler MVP + Lint 100%
2026-08  🟡 Phase 2 完成
2026-09  ⬜ Phase 3 启动：Contract Layer + Evidence Runtime
2026-11  ⬜ Phase 3 完成
2027-Q1  ⬜ Phase 4 启动：Five Runtimes + Release Drills
2027-Q2  ⬜ Phase 4 完成
2027-Q3+ ⬜ Phase 5 持续迭代
```

---

## 就绪检查（来自 22-delivery-os.md §就绪检查）

在进入 Phase 2 前，先回答：

1. **当前最大损失来自哪里？**
   需求误解、实现缺陷、发布风险，还是目标未达成？
   → 当前最大瓶颈是跨 ~70 仓库的采纳率，Phase 2 的 Workflow Compiler 直接降低采纳门槛。

2. **哪些证据已经稳定存在，哪些仍靠聊天记录？**
   → Matrix 64 edge 100% 覆盖已稳定。Evidence Bundle 手工组装，Phase 3 自动化。

3. **Matrix 是否真的控制任务、Prompt、测试和发布？**
   → Matrix 已控制 G5 和 G10。Prompt→Code 链路待 Compiler 自动化。

4. **指标失败后是否有标准处理路径？**
   → Metrics Gap Report 已定义，但实际触发链路待 Phase 5 自动化。

5. **工作流改进是否有版本、验证和回滚？**
   → RSI R0-R9 已定义版本和回滚。Eval Replay 数据集待 Phase 5 积累。
