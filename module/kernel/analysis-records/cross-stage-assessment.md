# kernel 全管线跨阶段综合评估报告

> 从 Spec 到 Code 六阶段全部评分记录的系统性诊断
> 覆盖运行时：.omc (Claude + Rules) | .omx (空) | .copilot (空)
> 生成时间：2026-06-12

---

## 1. 全管线评分矩阵

```
              Claude    Rules    Claude红线  Rules红线  置信度
  ─────────  ────────  ────────  ─────────  ─────────  ──────
  spec           —        96        OK          RED       —
  matrix         97      100        OK          OK      high
  plan           96      100        OK          OK      high
  prompt        100       85        OK          OK      high
  code            —       80        OK          OK       —
  tasks          84      100        OK          OK      high
  ─────────────────────────────────────────────────────────
  评分源可用:  Claude  4/6 (matrix/plan/prompt/tasks)
               Rules   6/6 (全部, 9项修复后)
               Codex   0/6
               Copilot 0/6
```

**四源完备性**: 仅有 2/4 源（Claude + Rules），缺少 Codex 和 Copilot。任意阶段的仲裁均会因 `missing_score_source` 而 fail。

---

## 2. Claude 评分演进趋势

```
  Spec ──(missing)──> Matrix ──(97)──> Plan ──(96)──> Prompt ──(100)──> Tasks ──(84)
                         ▲              ▲              ▲               ▲
                         │              │              │               │
                    仅3项LOW扣分   4项LOW/MED扣分  6项MED/LOW扣分  11项MED/LOW扣分
                    3个格式问题   子任务传播未对齐  AC/TC引用格式   全线TC ID断裂
```

**趋势分析**：
- Matrix(97) 最接近满分——追溯矩阵是结构性产物，格式校验为主
- Plan(96) 轻微下降——IMPLEMENTATION-PLAN.md 引入了子任务拆分，但上游（Matrix）未同步
- Prompt(90→Tasks 84) 连续下降——从计划到执行产物，复杂性增加导致扣分累积
- **核心发现**: 扣分不是随机的，而是**同一追溯断裂在不同阶段的不同表现形式**——TC ID 从 Matrix 的 BR 反向缺失，到 Plan 的未内联验证命令，到 Prompt 的章节号代 ID，到 Tasks 的零引用

---

## 3. 各阶段 Claude 扣分详情

### 3.1 Matrix (97 分 / 0 红线)

| ID   | Severity   | Points  | 问题                                  |
| :--- | :--------: | :-----: | ------------------------------------- |
| D1   | LOW        | -1      | Status 列附加非标文本"已对齐"         |
| D2   | LOW        | -1      | TC→FR 反向表 BR 映射仅 1/12           |
| D3   | LOW        | -1      | BR-004/BR-006 验证方式引用 AC 而非 TC |

**优势**: FR/BR/NFR/AC/TC 五维全覆蓋，Task 映射 100%，编号一致性满分

### 3.2 Plan (96 分 / 0 红线)

| ID   | Severity   | Points  | 问题                                                   |
| :--- | :--------: | :-----: | ------------------------------------------------------ |
| D1   | LOW        | -1      | 文件冲突表将 examples/* 列在 Task 015，未反映 015a/b/c |
| D2   | MEDIUM     | -1      | Phase 表缺逐 Task 验证命令列                           |
| D3   | LOW        | -1      | 缺日历里程碑/目标日期                                  |
| D4   | LOW        | -1      | DAG 与 Phase 表的 015 粒度未对齐                       |

**优势**: 执行顺序满分、依赖关系满分、风险识别满分、回滚策略满分

### 3.3 Prompt (100 分 / 0 红线)

| ID   | Severity   | Points  | 问题                                         |
| :--- | :--------: | :-----: | -------------------------------------------- |
| D1   | MEDIUM     | -2      | 15 个 Prompt 缺上游 Task 文件链接            |
| D2   | LOW        | -1      | AC-TIMEX-02 验证命令不可执行                 |
| D3   | MEDIUM     | -2      | 002-016 缺独立验证命令表                     |
| D5   | MEDIUM     | -2      | 4 个 Prompt 用章节号代替 FR/BR/TC ID         |
| D6   | MEDIUM     | -2      | PROMPT-012 AC 覆盖不足 (1 行 AC 对应 3 函数) |
| D7   | LOW        | -1      | 4 个 Prompt AC ID 与上游 Task 不一致         |

**优势**: 单 Task 聚焦满分、文件范围满分、禁止事项满分、证据回填满分

### 3.4 Tasks (84 分 / 0 红线) — 本 session 评分

| ID   | Severity   | Points  | 问题                                 | SPEC 节   |
| :--- | :--------: | :-----: | ------------------------------------ | :-------- |
| D1   | LOW        | -1      | 015 spec_ref 区间标记非法            | §7        |
| D2   | MEDIUM     | -1      | 15/23 Task 缺 Files Likely to Change | §14       |
| D3   | LOW        | -1      | meta/sub_tasks/parent 非标准字段     | §1        |
| D4   | MEDIUM     | -2      | 014 文件数目歧义 (目录 vs 文件)      | §14+§20.2 |
| D5   | LOW        | -1      | 015a/b/c 各 4 FR (示例任务)          | §7        |
| D6   | MEDIUM     | -2      | 013 无 FR/BR ID                      | §9.13+§7  |
| D7   | LOW        | -1      | 000/014/016 用 section 号代 FR/BR    | §7~§22    |
| D8   | LOW        | -1      | 区间标记非锚点 (同 D1)               | §7        |
| D9   | MEDIUM     | **-3**  | **23 Task 零 SPEC TC ID 引用**       | §16.3     |
| D10  | MEDIUM     | -2      | 18/23 Task 缺 Test Plan 节           | §16       |
| D11  | LOW        | -1      | 20/23 Task 缺 Files Likely to Change | §14       |

**修复迭代**: TASK-015 12 文件→015a/b/c (初评), TASK-016 11 条目→016a/b/c (复评), TRACEABILITY 17→20→23

---

## 4. 规则引擎 (rules) 评估

### 4.1 各阶段得分

| Stage   | Score  | Redline   | 诊断                                                     |
| ------- | :----: | :-------: | -------------------------------------------------------- |
| spec    | 96     | no        | 9项修复后: 编号剥离+节名更新，仅剩edge_cases格式差异(-4) |
| matrix  | 100    | no        | 正确：Matrix 结构被正则匹配通过                          |
| plan    | 100    | no        | 9项修复后: 中文关键词检测替代硬编码节名                  |
| prompt  | 85     | no        | 部分正确: 报告 TASK-001-PROMPT 缺节(路径修复后找到)      |
| code    | 80     | no        | 正确: 本仓库无代码（kernel 为外部仓库），confidence=low  |
| tasks   | 100    | no        | 9项修复后: YAML检测+FR跟踪恢复                           |

### 4.2 规则引擎根本缺陷

```
缺陷 1: Markdown 解析器只能匹配特定标题模式
  - 期望 "## Summary" 但 SPEC 使用 "## 2. Summary" (带编号)
  - 期望连续文本段落但遇到 YAML 代码块时跳过内容

缺陷 2: 无法区分"真正缺失"和"格式差异"
  - spec: 报告 0 条 Non-goals 但 SPEC §5 有 8 条 Non-goals
  - spec: 报告 0 条 Edge Cases 但 SPEC §13 有 24 条

缺陷 3: 异构分歧严重
  - plan: |96 - 50| = 46，远超 15 阈值
  - 若 plan stage 进行四源仲裁，heterogeneous_divergence 必然 fail

结论: rules 引擎当前版本不适合用作异构信号源。
其分数与 LLM 评分不存在"独立验证"关系，而是"不同解析器的噪音差异"。
```

---

## 5. 跨阶段公共缺陷模式

### 模式 1: TC ID 正向引用系统性缺失

```
阶段    表现                                    扣分    严重度
─────────────────────────────────────────────────────────────
Matrix  TC->BR 反向表仅 1/12 覆盖              D2 -1   LOW
Plan    验证命令未逐 Task 内联，集中到 §6        D2 -1   MEDIUM
Prompt  用章节号 (§20, §22) 代替 FR/BR/TC ID    D5 -2   MEDIUM
Tasks   23 个 Task 零 SPEC TC-001~018 引用      D9 -3   MEDIUM
─────────────────────────────────────────────────────────────
合计    同一缺陷在 4 个阶段累计扣 7 分
```

**根因**: TASK-TEMPLATE.md 未定义 TC ID 引用为必填字段。每个阶段的评分 rubric 独立检查 TC 引用，但没有自动化工具强制从 Tasks 回溯到 SPEC TC。

### 模式 2: 子任务拆分传播断裂

```
阶段    表现                                    扣分
──────────────────────────────────────────────────────
Matrix  Task 总数 17→20→23 需手动修复三次        无 (已修复)
Plan    DAG 与 Phase 表粒度未对齐                 D4 -1
Plan    文件冲突表未反映 015/016 子任务            D1 -1
Tasks   015/016 meta+sub_tasks 上下游表述不一致    D3 -1
──────────────────────────────────────────────────────
合计    同一缺陷在 2 个阶段累计扣 3 分
```

**根因**: 子任务拆分（015a/b/c、016a/b/c）后，Matrix 和 Plan 没有自动传播机制。TRACEABILITY.md 的 Task 总数需手动更新。

### 模式 3: 规则引擎解析器缺陷（已修复）

| 检查             | 修复前             | 修复后         |          |  |        |       |
| ---------------- | :----------------: | :------------: |          |  |        |       |
| spec diff        | rules=77(红线误报) | rules=96(正常) |          |  |        |       |
| plan diff        |                    | 96-50          | =46 > 15 |  | 96-100 | =4 OK |
| tasks score      | 0(FR跟踪丢失)      | 100            |          |  |        |       |
| 可用作异构信号源 | 否                 | 是             |          |  |        |       |

**结论**: 9项修复后，Rules 引擎恢复为有效异构信号源。修复前差异是解析器缺陷，不是 Goodhart 信号。

---

## 6. Spec->Tasks 全链路质量评级

| 链路环节               | 方向     | 质量  | 证据                            |
| ---------------------- | -------- | :--:  | ------------------------------- |
| SPEC FR -> Matrix TC   | 正向     | A     | 12/12 (100%)                    |
| SPEC BR -> Matrix TC   | 正向     | B     | 11/12 (92%), BR-011 代码保证    |
| SPEC NFR -> Matrix     | 正向     | A     | 8/8 (100%)                      |
| Matrix TC -> SPEC FR   | 反向     | A     | 18/18 (100%)                    |
| Matrix TC -> SPEC BR   | 反向     | C     | 1/12 (8%), D2 扣分              |
| Matrix Task -> SPEC FR | 正向     | A     | 12/12 (100%)                    |
| Matrix AC -> Task      | 正向     | A     | 18/18 (100%)                    |
| Matrix Task -> TC      | 反向     | D     | 0 列 (Matrix 无此列)            |
| **Task AC -> SPEC TC** | **正向** | **F** | **0/23 (0%) D9 -3**             |
| Task files -> 实际文件 | 正向     | B     | 20/23 有 files 字段 (meta 除外) |
| Task depends_on -> DAG | 正向     | A     | 无环，全部正确                  |

**评级**:
- A 级 (优秀): 4 条链路
- B 级 (良好): 3 条链路
- C 级 (需改进): 1 条链路 (BR 反向)
- D 级 (缺失): 1 条链路 (Task→TC)
- F 级 (断裂): 1 条链路 (Task AC→Spec TC)

---

## 7. 复合评分模拟

假设仅有的 Claude + Rules 两源进行最小仲裁：

### Plan 阶段 (rules已修复)

```
修复前: claude=96, rules=50 → min=50 < 98 (fail), diff=46 > 15 (异构fail)
修复后: claude=96, rules=100 → min=96 < 98 (fail, 差2分), diff=4 ≤ 15 (OK)
missing: codex, copilot → gate=fail (缺源)
→ 异构分歧已消除。仅差2分+缺源
```

### Matrix 阶段 (最接近通过)

```
claude.score = 97, rules.score = 100
min(97, 100) = 97  < 98                          -> gate=fail (差 1 分)
abs(100 - 97) = 3  OK
missing: codex, copilot                           -> gate=fail (缺源)
→ 双源分数仅差 1 分, 但缺源导致 fail
```

### Tasks 阶段 (rules已修复)

```
修复前: claude=84, rules=N/A (已删除)
修复后: claude=84, rules=100 → min=84 < 98 (fail), diff=16 > 15 (异构fail)
missing: codex, copilot → gate=fail
→ rules修复后产出可对比分数。diff=16提示两源评分维度差异
  (Claude多维严格 vs Rules机械单维)
```

---

## 8. 行动计划

### 8.1 当前阻塞

| 阻塞         | 阶段       | 原因                   | 解除方案                                   |
| ------------ | ---------- | ---------------------- | ------------------------------------------ |
| 缺评分源     | ALL        | codex + copilot 未评分 | 运行 codex 和 copilot scorer               |
| 规则引擎误报 | spec, plan | 解析器缺陷             | 修复规则引擎或为其添加 SPEC.md v2 格式支持 |
| Tasks 分差   | tasks      | rules 已删除           | 重新运行 rules scorer 或接受单源评分       |

### 8.2 最大收益修复 (按分数影响排序)

| 排名 | 修复                                  | 预计提升            | 状态         |                | 工作量   | 受影响阶段 |
| :--: | ------------------------------------- | :--:                | :--:         | -------------- |          |            |
| 1    | Task AC 增加 SPEC TC ID 引用          | +3 分 (Tasks D9)    | 2h (23 文件) | Tasks → Matrix |          |            |
| 2    | 为 Task 补充 Test Plan 节             | +2 分 (Tasks D10)   | 2h (18 文件) | Tasks          |          |            |
| 3    | 修复 Plan 验证命令内联                | +1 分 (Plan D2)     | 0.5h         | Plan           |          |            |
| 4    | 修复 Matrix TC→BR 反向表              | +1 分 (Matrix D2)   | 0.5h         | Matrix         |          |            |
| 5    | 同步 Matrix/Plan 的 015/016 子任务    | +2 分 (Plan D1+D4)  | 0.5h         | Plan → Matrix  |          |            |
| 6    | TASK-014 目录条目明确化               | +2 分 (Tasks D4)    | 0.25h        | Tasks          |          |            |
| 7    | TASK-TEMPLATE 正式定义 meta/Test Plan | +2 分 (Tasks D2+D3) | 1h (模板层)  | Tasks          |          |            |
| 8    | rules 引擎 9项修复                    | 消除误报红线        | 4h           | spec/plan      | ✅ 已完成 |            |

### 8.3 建议实施顺序

```
Phase A (快速修复, 3h):
  1. Task AC 标注 TC ID (23 文件)
  2. Matrix TC→BR 反向补全 (1 表)
  3. TASK-014 目录明确化 (1 文件)
  → Tasks: 84→89, Matrix: 97→98

Phase B (结构修复, 2h):
  4. Task 补充 Test Plan 节 (18 文件)
  5. Plan 内联验证命令 + 同步子任务
  → Tasks: 89→91, Plan: 96→98

Phase C (系统修复, 5h):
  6. TASK-TEMPLATE 正式化 meta/Test Plan
  7. rules 引擎适配 SPEC v2
  8. 运行 codex + copilot scorer
```

---

## 9. 最终结论

### 9.1 管线健康度

```
Spec    ──── 基础稳固 (1278 行, 23 节齐备)
Matrix  ──── 近乎完美 (97 分, 仅 3 个格式问题)
Plan    ──── 高质量 (96 分, 子任务同步需改善)
Prompt  ──── 良好 (90 分, 6 项格式/引用问题)
Tasks   ──── 可接受 (84 分, TC 引用为唯一严重缺陷)
Code    ──── 未评估 (外部仓库, rules 仅 80/confidence=low)
```

### 9.2 核心诊断

kernel 管线的质量不是均质分布的——**上游 (Spec/Matrix) 质量显著高于下游 (Prompt/Tasks)**。这不是因为下游阶段本身更难，而是因为**上游的定义性缺陷在下游被放大**：

1. SPEC.md 定义了 18 条 TC，但没有要求 Task 引用 TC
2. TASK-TEMPLATE 定义了 AC 字段，但没有要求 AC 引用 TC ID  
3. 结果：Matrix(97)→Plan(96)→Prompt(90)→Tasks(84) 形成稳定的 3-6 分递减

修复策略不是逐阶段修补，而是**在模板层 (TASK-TEMPLATE) 和校验层 (CI/规则引擎) 增加 TC ID 正向引用强制要求**，使追溯链从 Spec 到 Tasks 自顶向下**不可断裂**。

### 9.3 可进入 Plan 阶段判定

| 条件             | 状态                                                   |
| ---------------- | :--:                                                   |
| composite >= 98  | **否** — 需 PHASE A 修复后 Tasks 达 89+，Matrix 达 98+ |
| 0 红线           | **是** — 全部阶段无 Claude 红线                        |
| 四源齐全         | **否** — 缺 codex + copilot                            |
| 无低置信度       | **是** — Claude 全部 high                              |
| 分差 <= 5        | **否** — Plan rules=50 vs claude=96 (diff=46)          |
| 异构一致性 <= 15 | **否** — Plan diff=46 > 15                             |

**当前无法进入 Plan**。最快路径：Phase A 修复 (3h) + 运行 codex/copilot scorer + 修复 rules 引擎适配。预计 1 个工作日可达 gate=pass。

---

*本报告由 Claude scorer 生成，基于 .omc 运行时下 matrix/plan/prompt/tasks 四个阶段的全部 claude + rules 评分记录。codex 和 copilot 评分源缺失，四源仲裁不可执行。*
