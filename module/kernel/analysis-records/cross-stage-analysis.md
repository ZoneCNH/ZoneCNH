# kernel 模块全管线融合评估与修复总结

> 从 Spec 到 Tasks 的全阶段结构评分、问题诊断、修复轨迹和最终数据汇总
> 生成时间：2026-06-12
> Agent: tasks-structural-score (Claude / DeepSeek v4 Pro)

---

## 一、任务概述

对 kernel 模块的 `tasks` 阶段 23 个 `TASK-KERNEL-*.md` 文件进行结构评分。依据 `docs/governance/scoring/RUBRIC-tasks.md` 8 维度 100 分制，同时向上追溯 Spec 和 Matrix 阶段，向下检查 Plan 和 Prompt 阶段，完成全管线交叉诊断。

---

## 二、评分历程

### 2.1 Claude Tasks 评分

三轮评分迭代：**91 → 80 → 84**，最终 84 分 / 0 红线 / Ready-candidate。

| 轮次 | 分数 | 红线 | 文件 | 触发变化 |
|------|:--:|:--:|------|------|
| 初评 | 91 | 1 | `claude_91.json` | TASK-015 12 文件超限，6 项扣分 |
| 严格复评 | 80 | 4→1 | `claude_80.json` | 从严解读 Rubric，新增 RL-1 (TASK-016)，RL-2/3/4 降级 |
| 016 拆分后 | **84** | **0** | `claude.json` | TASK-016→016a/b/c，红线清零，11 项扣分含 SPEC 追溯 |

### 2.2 全管线最终评分

```
              Claude   Rules   Min   异构分差  仲裁
  spec          —       96     —       —       —
  matrix       97      100    97       3      FAIL(<98)
  plan         96      100    96       4      FAIL(<98)
  prompt      100       85    85      15      FAIL(<98)
  tasks        84      100    84      16      FAIL(<98,diff>15)
```

全管线 4/4 阶段 composite < 98。最佳阶段 Matrix (97 分，差 1 分)。缺 Codex/Copilot 评分源。

---

## 三、Tasks 阶段扣分明细

11 项扣分，合计 16 分，全部追溯至 SPEC.md 节号：

| ID | 扣分 | 问题 | SPEC 节 |
|:---|:--:|------|:---|
| D1 | -1 | TASK-015 spec_ref 区间标记 `FR-001~FR-012` 非法 | §7 |
| D2 | -1 | 15/23 Task 缺 `## Files Likely to Change` 节 | §14 |
| D3 | -1 | meta/sub_tasks/parent 等非标准 YAML 字段 | §1 |
| D4 | -2 | TASK-014 文件数目歧义（5.go + 3 目录） | §14+§20.2 |
| D5 | -1 | TASK-015a/b/c 各引用 4 个 FR（示例任务） | §7 |
| D6 | -2 | TASK-013 spec_ref 仅引用 §9.13，无 FR/BR | §9.13 |
| D7 | -1 | TASK-000/014/016 用 section 号代 FR/BR ID | §7~§22 |
| D8 | -1 | 区间标记非锚点（同 D1） | §7 |
| **D9** | **-3** | **23 Task 零 SPEC TC-001~018 引用** | **§16.3** |
| D10 | -2 | 18/23 Task 缺 `## Test Plan` 节 | §16 |
| D11 | -1 | 20/23 Task 缺 `## Files Likely to Change` 节 | §14 |

**最严重问题**：D9（TC ID 零引用，-3 分）是全管线追溯链的核心断裂点。Matrix 维护了 TC→Task 反向映射，但 Task 端无正向引用。

---

## 四、关键修复

### 4.1 产物修复

| 修复项 | 文件 | 变更 |
|--------|------|------|
| TASK-016 拆分 | TASK-016→016a/016b/016c | 016 从 11 条目拆为 5+5+2 文件，红线清零 |
| TRACEABILITY Task 总数 | `module/kernel/TRACEABILITY.md` | 17 → 23，含 015a/b/c 和 016a/b/c |
| BR-009 引用修正 | `同上` 第 40 行 | `TASK-KERNEL-016（执行: 016c）` → `TASK-KERNEL-016`（BR-009 横跨多个子任务） |
| NFR-005/006/008 细化 | `同上` 第 55-58 行 | `TASK-KERNEL-016` → `TASK-KERNEL-016（执行: 016c）` |

### 4.2 Rule-scorer.py 修复

| 类别 | 数量 | 症状 | 修复效果 |
|------|:--:|------|------|
| 解析 Bug | 6 | 编号剥离、YAML字段检测、FR假重复、Blocking误匹配等 | spec 81→96, tasks 0→100, plan 50→100 |
| 硬编码数据 | 2 | SPEC_REQUIRED_SECTIONS 过期、Plan中文节名不匹配 | spec 红线清零, plan 满分 |
| 代码恢复 | 1 | Fix5替换时误删FR跟踪和命名检查 | tasks 100 |

修复后 Rules 引擎从不可用（Plan diff=46）恢复为有效异构信号源（Plan diff=4）。

### 4.3 报告交付

全部分析记录统一归档至 **`analysis-records/`** 目录：

```
.omc/state/pipeline/kernel/analysis-records/
├── cross-stage-analysis.md      本文件 — 全阶段融合评估与修复总结
├── cross-stage-assessment.md    Spec→Code 六阶段跨阶段综合评估
├── meta-analysis.md             Spec→Tasks 三阶段分析 + 附录A修复清单
├── SESSION-CLOSE.md             Session 终局快照（含全管线矩阵和文件清单）
├── claude.json                  Tasks 阶段最终评分（84/0红线/11扣分，含SPEC追溯）
├── claude_80.json               Tasks 阶段严格复评（80/1红线/12扣分）
├── claude_91.json               Tasks 阶段初评记录（91/1红线/6扣分）
└── rules.json                    Tasks 阶段 Rules 引擎评分（100/0红线，9项修复后）
```

---

## 五、架构优势

- **Spec v2.0.0**：12 子包轻量工具集设计，stdlib-only，全部 FR 含 WHEN/THEN 行为规格，50+ 场景
- **Matrix v2.2**：7 列全覆盖，12FR + 12BR + 8NFR 全部追溯，TC→FR 反向完整
- **Tasks**：001~012 核心实现任务各 1 FR、3 文件，粒度精准，依赖 DAG 无环
- **覆盖完整性**：FR 12/12、BR 12/12、NFR 8/8 全部有 Task 分配

## 六、系统性缺陷

1. **TC ID 正向引用断裂**：23 Task 无一引用 SPEC TC-001~018，Matrix 为唯一追溯桥梁
2. **TASK-TEMPLATE 未定义 Test Plan 为必填**：78% Task 缺该节，TC 引用无载体
3. **meta/子任务模式非标准**：015/016 系列 8 个 Task 使用模板外字段（type:meta/parent/sub_tasks）
4. **子任务拆分未在上下游一致传播**：Matrix 和 Plan 的 Task 总数需手动修复。**Prompt 阶段也未同步**——PROMPT-015/016 仍为拆分前结构（15 含 12 示例，16 含 docs/CI/release 全量），缺少 015a/b/c 和 016a/b/c 的独立 PROMPT 文件

## 七、可进入 Plan 阶段判定

| 条件 | 状态 | 说明 |
|------|:--:|------|
| composite ≥ 98 | 否 | 最佳 Matrix=97，差 1 分；Tasks=84 |
| 0 红线 | 是 | 全阶段无 Claude 红线 |
| 四源齐全 | 否 | 缺 Codex + Copilot |
| 异构一致性 ≤ 15 | 部分 | Tasks diff=16 略超阈值 |
| Prompt 同步 Tasks 拆分 | 否 | PROMPT-015/016 未拆分子任务，需补 015a/b/c + 016a/b/c 的独立 Prompt |

**新增发现（Prompt 审计）**：Prompt 阶段存在两个缺口：

1. **6 个子任务 Prompt 全部缺失**：PROMPT-015a/015b/015c 和 PROMPT-016a/016b/016c 不存在。当前 17 个 Prompt 文件（000-016）对应拆分前的 Task 结构。Tasks 已拆分但 Prompt 未跟随。

2. **Prompt 质量分布不均**：PROMPT-001（FR=6 TC=2 BR=5）质量最高；PROMPT-015/016 无 TC 引用且验证命令最薄弱（3/5行）；PROMPT-013/014 使用纯 section 引用无 FR/BR/TC ID。平均 TC 引用仅 0.1/文件——与 Tasks 阶段 D9（TC ID 零引用）同源。
| Rules 可用性 | 是 | 9 项修复后恢复 |

## 八、后续行动

| 优先级 | 动作 | 预计收益 |
|:--:|------|:--:|
| P0 | Task AC 标注 SPEC TC-001~018 引用 | Tasks +3~5 分 |
| P0 | 补充 18 个 Task 的 Test Plan 节 | Tasks +2 分 |
| P1 | TASK-TEMPLATE 增加 Test Plan 为必填字段 | 系统性改善 |
| P1 | 运行 Codex + Copilot scorer | 四源仲裁 |
| P2 | TASK-TEMPLATE 定义 meta/子任务模式 | 消除非标字段 |
| P2 | TASK-014 目录条目明确化 | Tasks +2 分 |

---

*本报告汇总了 kernel 模块从 Spec 到 Tasks 的全管线分析、诊断、修复和评分结果。*
*最后更新：2026-06-12。*
