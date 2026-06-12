# kernel 模块全管线结构评分与修复 — 最终评估报告

> Agent: tasks-structural-score (Claude / DeepSeek v4 Pro)
> 日期: 2026-06-12
> 模块: kernel
> 覆盖: Spec → Matrix → Plan → Prompt → Tasks → Code 六阶段

---

## 一、执行摘要

kernel 模块管线经过 Spec v2.0.0 重写、Matrix v2.1 重建、Tasks 迭代拆分和 rule-scorer.py 9 项修复后，最
终 Tasks 阶段 Claude 评分 **84/100**（0 红线），Rules 评分 **100/100**。

**核心发现**: 追溯链的 SPEC→TRACEABILITY 段高质量（15/15 覆盖），但 TRACEABILITY→TASK 段正向引用断裂 —
—全部 23 个 Task 无 SPEC TC ID 引用。这一缺陷在 Matrix→Plan→Prompt→Tasks 四个阶段以不同形式出现，累
计扣 7 分，是全管线最严重的系统性缺陷。

**修复成就**: TASK-016 拆分为 016a/b/c（红线清零）、rule-scorer.py 9 项修复（恢复为有效异构信号源）、
TRACEABILITY Task 总数 17→23。

---

## 二、全管线评分矩阵

```
Stage     Claude   Rules   Min    Diff   状态
------    ------   -----   ---   ----   ----
spec          —       96     —      —     —
matrix       97      100    97      3    FAIL(<98)
plan         96      100    96      4    FAIL(<98)
prompt      100       85    85     15    FAIL(<98)
code          —       80     —      —     —
tasks        84      100    84     16    FAIL(<98,diff>15)
```

**阻塞**: 4/4 阶段 composite < 98。最佳 Matrix=97（差 1 分）。缺 Codex/Copilot 评分源。

---

## 三、Tasks 阶段扣分明细（Claude: 84/100, 0红线）

| ID | Severity | Pts | 问题 | SPEC 节 |
|:---|:--------:|:--:|------|:---|
| D1 | LOW | -1 | TASK-015 spec_ref 区间标记 `FR-001~FR-012` 非法 | §7 |
| D2 | MEDIUM | -1 | 15/23 Task 缺 `## Files Likely to Change` 节 | §14 |
| D3 | LOW | -1 | meta/sub_tasks/parent 等非标准 YAML 字段 | §1 |
| D4 | MEDIUM | -2 | TASK-014 文件数目歧义（5.go + 3 目录） | §14+§20.2 |
| D5 | LOW | -1 | TASK-015a/b/c 各引用 4 个 FR（示例任务，不触红线） | §7 |
| D6 | MEDIUM | -2 | TASK-013 spec_ref 仅引用 §9.13，无 FR/BR | §9.13 |
| D7 | LOW | -1 | TASK-000/014/016 用 section 号代 FR/BR ID | §7~§22 |
| D8 | LOW | -1 | 区间标记非锚点（同 D1） | §7 |
| **D9** | **MEDIUM** | **-3** | **23 Task 零 SPEC TC-001~018 引用** | **§16.3** |
| D10 | MEDIUM | -2 | 18/23 Task 缺 `## Test Plan` 节 | §16 |
| D11 | LOW | -1 | 20/23 Task 缺 `## Files Likely to Change` 节 | §14 |

**D9 是全管线最严重的单项缺陷**——23 个 Task 与 SPEC TC 无正向链接，Matrix 是唯一追溯桥梁。

---

## 四、各阶段 Claude 评分汇总

### Matrix (97/100)
3 项 LOW 扣分：Status 列非标文本、TC→BR 反向缺失、BR 验证方式模糊。FR/BR/NFR/AC/TC 五维全覆盖，编号一致性满分。

### Plan (96/100)
4 项扣分：文件冲突表未反映 015a/b/c、Phase 表缺验证命令列、缺里程碑、DAG 粒度未对齐。执行顺序和依赖关系满分。

### Prompt (100/100)
8 维度满分，0 扣分。PROMPT-001（errx）为最高质量模板（FR=6 TC=2 BR=5）。但 17 个文件对应拆分前结构，缺 015a/b/c 和 016a/b/c 的独立 Prompt。

### Tasks (84/100) — 本 session 评分
11 项扣分，覆盖完整性(15/15)、Scope/Non-scope(12/12)满分。最弱维度：测试计划(5/10)。

---

## 五、跨阶段系统性缺陷

### 缺陷 1: TC ID 正向引用断裂（累计 -7 分）

```
Matrix   (97): TC→BR 反向表仅 1/12 覆盖           D2 -1 LOW
Plan     (96): 验证命令未逐 Task 内联              D2 -1 MEDIUM
Prompt  (100): 用章节号代替 FR/BR/TC ID             D5 -2 MEDIUM
Tasks    (84): 23 Task 零 SPEC TC-001~018 引用      D9 -3 MEDIUM
```

根因: TASK-TEMPLATE 未定义 TC ID 引用为必填字段。

### 缺陷 2: 子任务拆分传播断裂（累计 -3 分）

```
Matrix:    Task 总数 17→20→23 三次手动修复
Plan:      DAG 与 Phase 表、文件冲突表未反映子任务  D1/D4 -2
Tasks:     meta/sub_tasks 非标准字段                D3 -1
Prompt:    缺 015a/b/c + 016a/b/c 的独立 Prompt     6 文件缺失
```

根因: 子任务拆分后无自动传播机制。

### 缺陷 3: 规则引擎解析器缺陷（已修复）

| 阶段 | 修复前 | 修复后 | 说明 |
|------|:-----:|:-----:|------|
| spec | 77/3红线 | **96**/0红线 | 编号剥离+节名更新 |
| plan | 50 | **100** | 中文关键词检测 |
| tasks | 0 | **100** | YAML检测+FR跟踪恢复 |
| matrix | 100 | 100 | 不变 |

---

## 六、Rule-scorer.py 9 项修复清单（已完成并验证）

### 解析 Bug（6 项）
| # | 行号 | 症状 | 修复 |
|---|:---:|------|------|
| 1 | 101 | count_sections 不剥离编号 | 新增 _strip_number() |
| 2 | 212 | _section_body 无编号前缀 | 正则加 `(?:\d+[. ]\s*)?` |
| 3 | 173 | FR 跨节引用误判重复 | 仅 FR 节内检测 |
| 4 | 196 | Non-blocking 触 Blocking 红线 | 改为匹配子节标题 |
| 5 | 300 | Tasks 未检测 YAML 字段 | Scope→`^\s*scope:` Accept→`^\s*acceptance_criteria:` |
| 6 | 347 | Plan 节检测无编号前缀 | 同 Fix 2 |

### 硬编码数据（3 项）
| # | 行号 | 问题 | 修复 |
|---|:---:|------|------|
| 7 | 110 | SPEC_REQUIRED_SECTIONS 8/23 不匹配 | 更新为 v2.0.0 实际节名 |
| 8 | 345 | Plan required 5/5 不匹配中文标题 | 中文关键词内容检测 |
| 9 | 368 | Prompt 路径需修正 | `module/{m}/tasks/` glob |

---

## 七、产物修复记录

| 修复 | 文件 | 变更 |
|------|------|------|
| TASK-016 拆分 | 016→016a/016b/016c | 5+5+2 文件，红线清零 |
| TRACEABILITY 总数 | Line 126 | 17→23 |
| BR-009 引用 | Line 40 | 去除单子任务标注 |
| NFR-005/006/008 | Lines 55-58 | 增加 `（执行: 016c）` |

---

## 八、全链路质量评级

| 链路 | 方向 | 等级 | 证据 |
|------|------|:--:|------|
| SPEC FR → Matrix TC | 正向 | A | 12/12 |
| Matrix TC → SPEC FR | 反向 | A | 18/18 |
| Matrix Task → SPEC FR | 正向 | A | 12/12 |
| Matrix AC → Task | 正向 | A | 18/18 |
| SPEC NFR → Matrix | 正向 | A | 8/8 |
| SPEC BR → Matrix TC | 正向 | B | 11/12 |
| Task depends_on → DAG | 正向 | A | 无环 |
| Task files → 实际文件 | 正向 | B | 20/23 |
| Matrix TC → SPEC BR | 反向 | C | 1/12 |
| Matrix Task → TC | 反向 | D | 无此列 |
| **Task AC → SPEC TC** | **正向** | **F** | **0/23** |

---

## 九、可进入 Plan 阶段判定

| 条件 | 状态 | 说明 |
|------|:--:|------|
| composite ≥ 98 | 否 | 最佳 Matrix=97(差1分), Tasks=84 |
| 0 红线 | 是 | 全阶段无 Claude 红线 |
| 四源齐全 | 否 | 缺 Codex + Copilot |
| 异构一致性 ≤ 15 | 部分 | Tasks diff=16 略超, Plan diff=4 OK |
| Rules 可用性 | 是 | 9 项修复后恢复 |
| Prompt 同步 Tasks | 否 | 缺 6 个子任务 Prompt |

---

## 十、后续行动

| 优先级 | 动作 | 预计收益 |
|:--:|------|:--:|
| P0 | Task AC 标注 SPEC TC-001~018 引用 | Tasks +3~5 分 |
| P0 | 补充 18 个 Task 的 Test Plan 节 | Tasks +2 分 |
| P0 | 补建 015a/b/c + 016a/b/c 的 6 个 Prompt | Prompt 同步 Tasks |
| P1 | TASK-TEMPLATE 增加 Test Plan 为必填字段 | 系统性改善 |
| P1 | 运行 Codex + Copilot scorer | 四源仲裁 |
| P2 | TASK-TEMPLATE 定义 meta/子任务模式 | 消除非标字段 |
| P2 | TASK-014 目录条目明确化 | Tasks +2 分 |

---

*本报告融合了 kernel 模块从 Spec 到 Code 的全管线评分、诊断、修复和行动计划。所有评分数据与磁盘文件一致。*
*最后更新: 2026-06-12*
