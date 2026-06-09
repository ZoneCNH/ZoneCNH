# Goal 体系熵减分析报告

> 分析时间：2026-06-09 | 分析范围：`docs/goal/` 全部 28 个 Markdown 文档 + `tools/` 目录
> 分析方法：全量精读 → 信息流向追踪 → 冗余/不一致/漂移检测 → 合并建议 → 优先级排序
> 与既有报告关系：既有报告聚焦"评分"和"问题清单"，本报告聚焦**信息熵**——哪些信息是冗余的、哪些是矛盾的、哪些可以消除

---

## 1. 信息熵总览

| 维度        | 熵源                                          | 当前状态 | 减熵目标             |
| ----------- | --------------------------------------------- | -------- | -------------------- |
| 状态机定义  | 3 处独立定义 Goal 生命周期，枚举不一致        | 高熵     | 合并为 1 处 SSOT     |
| 对象 Schema | Goal/Matrix/Evidence 字段在 3+ 文件中各说各话 | 高熵     | 建立机器 schema 文件 |
| ID 格式     | 2 套版本号规则并存                            | 中熵     | 统一为 vN 或 vN.N    |
| Gate 阈值   | 文档定义与脚本实现分叉                        | 中-高熵  | 阈值表单一来源       |
| 重定向密度  | 08-quality-gates.md ~60% 行是"见 XXX"         | 中熵     | 合并或降级为索引     |
| 愿景文档    | 22/23 号文件标记 Vision，与实操文档混排       | 低-中熵  | 分离或标注层级       |
| 术语表      | 63 条，与正文定义存在微漂移                   | 低熵     | 定期对齐             |

**综合信息熵评级：中-高（约 0.65 / 1.0）**

---

## 2. SSOT 依赖图与信息流向

### 2.1 权威归属矩阵

| 信息类型          | SSOT 文件                            | 投影/引用文件                  | 冲突文件                                           |
| ----------------- | ------------------------------------ | ------------------------------ | -------------------------------------------------- |
| Pipeline 状态枚举 | `03-pipeline.md` §2.1-2.3            | 15-registry, GLOSSARY          | `02-goal-standard.md` §10（Goal 生命周期独立定义） |
| 对象状态总表      | `03-pipeline.md` §2.5                | —                              | `05-layer-standards.md`（Matrix 状态独立定义）     |
| Gate 定义         | `04-gates.md`                        | 00-authority-map, GLOSSARY     | `08-quality-gates.md`（Gate 阈值独立定义）         |
| Gate 阈值         | `08-quality-gates.md` §3             | 04-gates.md（引用）            | 脚本 `gate-check.sh`（阈值不同）                   |
| DoR/DoD           | `06-dod.md`                          | 08-quality-gates.md §2（引用） | —                                                  |
| ID 格式           | `07-id-system.md`                    | 09-templates                   | `12-operations.md`（版本号格式不同）               |
| 层标准            | `05-layer-standards.md`              | —                              | `08-quality-gates.md`（部分重叠）                  |
| Registry Schema   | `15-registry.md`                     | —                              | `09-templates.md`（Goal 字段名不同）               |
| Evidence 协议     | `13-runtime-engine.md` §4            | —                              | 脚本 `evidence-collect.sh`（ID/路径不同）          |
| CL 定义           | `13-runtime-engine.md` §2            | 00-authority-map               | —                                                  |
| 评分 Rubric       | `02-goal-standard.md` + 各 RUBRIC.md | 08-quality-gates.md §3         | —                                                  |
| Matrix 状态       | `05-layer-standards.md` §9           | 03-pipeline.md §2.5（引用）    | —                                                  |

### 2.2 信息流向图

```text
                    ┌─────────────────────┐
                    │  00-authority-map.md │  ← 权威归属定义
                    └─────────┬───────────┘
                              │ 声明谁是 SSOT
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐
  │ 03-pipeline   │  │ 04-gates      │  │ 06-dod        │
  │ (状态机)      │  │ (Gate 定义)   │  │ (DoR/DoD)     │
  └───────┬───────┘  └───────┬───────┘  └───────┬───────┘
          │                  │                  │
          │    ┌─────────────┼──────────────────┤
          ▼    ▼             ▼                  ▼
  ┌───────────────────────────────────────────────────┐
  │              05-layer-standards.md                 │
  │  (Spec/Design/Plan/Task/Prompt/Code/Test/Matrix)  │
  └───────────────────────┬───────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
  ┌───────────────┐ ┌───────────┐ ┌───────────────┐
  │ 08-quality    │ │ 09-       │ │ 10-lint       │
  │ gates (评分)  │ │ templates │ │ rules         │
  └───────────────┘ └───────────┘ └───────────────┘
          ▲               ▲
          │               │
  ┌───────────────┐ ┌───────────────┐
  │ 02-goal       │ │ 15-registry   │
  │ standard      │ │ (Schema)      │
  └───────────────┘ └───────────────┘

  注意：02-goal-standard.md 同时定义了 Goal 评分（应属于 08）
        和 Goal 生命周期（应属于 03）—— 双重职责 = 熵源
```

---

## 3. 冗余检测

### 3.1 高熵冗余（应消除）

#### R-1：Goal 生命周期三重定义

| 定义位置                  | 状态枚举                                                                                          | 大小写     |
| ------------------------- | ------------------------------------------------------------------------------------------------- | ---------- |
| `02-goal-standard.md` §10 | Draft → Reviewed → Approved → In Progress → Validated / Partially Validated / Failed → Deprecated | Title Case |
| `03-pipeline.md` §2.5     | Draft → Active → Paused → Achieved / Abandoned                                                    | Title Case |
| `15-registry.md` 示例     | active / design_ready / executing / ready_for_pr                                                  | snake_case |

**熵量：高** — 三个文件定义同一对象的三种不同生命周期，读者无法判断哪个是权威。

#### R-2：Spec 状态双重定义

| 定义位置                   | 状态枚举                                            |
| -------------------------- | --------------------------------------------------- |
| `05-layer-standards.md` §1 | Draft → Reviewed → Approved → Changed → Deprecated  |
| `03-pipeline.md` §2.5      | Draft → Review → Approved → Superseded / Deprecated |

**熵量：中-高** — `Changed` vs `Superseded` 是不同的终态语义。

#### R-3：Goal 对象字段三重定义

| 定义位置                 | 关键差异                                                                                                                                              |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `02-goal-standard.md` §3 | `id`, `name`, `context`, `objective`, `success_metrics`, `scope_in`, `scope_out`, `constraints`, `acceptance_criteria`, `owner`, `priority`, `status` |
| `09-templates.md` YAML   | 缺少 `owner`, `priority`, `status`；使用嵌套 `scope.in` / `scope.out`                                                                                 |
| `15-registry.md`         | `goal_id`, `title`, `north_star`, `success_criteria`, `current_phase`                                                                                 |

**熵量：高** — 同一对象三种字段命名：`name` vs `title`，`objective` vs `north_star`，`success_metrics` vs `success_criteria`。

#### R-4：Matrix Schema 双重定义

| 定义位置                   | 字段风格                                                       |
| -------------------------- | -------------------------------------------------------------- |
| `05-layer-standards.md` §9 | 展示表头：`Goal ID`, `Goal Item`, `Spec ID`, `Requirement`...  |
| `09-templates.md` YAML     | 机器字段：`goal`, `spec`, `requirement`, `task`, `prompt`...   |
| 脚本 `matrix-gen.py`       | 混合：`goal_id`, `spec_id`, `requirement_id`, `description`... |

**熵量：中-高** — 展示字段与机器字段未分离，脚本字段与文档字段不同。

#### R-5：Gate 阈值文档与脚本分叉

| 阈值项        | 文档定义                              | 脚本实现                        |
| ------------- | ------------------------------------- | ------------------------------- |
| Matrix 覆盖率 | `>= 95` 才 pass（08-quality-gates）   | `< 70` 才 fail（matrix-gen.py） |
| Goal 评分     | `>= 80` 进入 Spec（02-goal-standard） | 无脚本检查                      |

**熵量：中** — 阈值分叉意味着文档和脚本对"通过"的定义不同。

### 3.2 中熵冗余（可精简）

#### R-6：DoR/DoD 定义位置分散

- `06-dod.md` 是 SSOT，定义了 12 层 DoR/DoD
- `08-quality-gates.md` §2 引用了 06-dod.md，但自身也有独立的 DoR/DoD 摘要
- `05-layer-standards.md` 各层标准中隐含了 DoR/DoD 语义

**熵量：中** — 虽然 08 号文件声明引用 06，但 05 号文件中的隐含定义容易被误读为独立权威。

#### R-7：评分 Rubric 分散

- `02-goal-standard.md` §8 定义 Goal 评分（100 分）
- `08-quality-gates.md` §3 引用各 RUBRIC.md + 内联摘要
- 各 `docs/governance/scoring/RUBRIC-*.md` 是实际评分标准

**熵量：低-中** — 02-goal-standard.md 的 Goal 评分应迁移到 08-quality-gates.md 或 RUBRIC-goal.md。

#### R-8：Prompt 标准双重定义

- `05-layer-standards.md` §5 定义 Prompt 标准
- `11-ai-collaboration.md` 有独立的 Prompt 分层表（已通过 SSOT 引用消除直接重复，但仍有结构重叠）

**熵量：低** — CHANGELOG 记录了直接重复的消除，但两文件的 Prompt 关注角度仍有重叠。

### 3.3 低熵冗余（可接受）

#### R-9：愿景文档与实操文档混排

- `22-delivery-os.md`（Vision）和 `23-workflow-governance-checks.md`（Vision）已标注"愿景架构"
- 与 00-21 号实操文档在同一目录，编号连续

**熵量：低** — 标注已足够，但目录结构未分层。

#### R-10：CHANGELOG 与 24-standard-unification-analysis.md 内容关联

- 24 号文件是自分析报告，记录了结构统一度评分
- CHANGELOG 记录了修复历史
- 两者有信息重叠但角度不同

**熵量：低** — 可接受。

---

## 4. 不一致检测

### 4.1 状态机不一致（Critical）

#### I-1：Goal 生命周期冲突

| 特征       | 02-goal-standard    | 03-pipeline | 15-registry |
| ---------- | ------------------- | ----------- | ----------- |
| 初始态     | Draft               | Draft       | —           |
| 审核态     | Reviewed            | —           | —           |
| 激活态     | In Progress         | Active      | active      |
| 暂停态     | —                   | Paused      | —           |
| 终态(成功) | Validated           | Achieved    | —           |
| 终态(部分) | Partially Validated | —           | —           |
| 终态(失败) | Failed              | Abandoned   | —           |
| 弃用态     | Deprecated          | —           | —           |
| 大小写     | Title Case          | Title Case  | snake_case  |

**影响**：实现者无法确定 Goal 的合法状态流转。Registry 用户看到 `active`，文档看到 `In Progress`，Pipeline 看到 `Active`。

#### I-2：Spec 终态语义冲突

- `05-layer-standards.md`：终态为 `Changed`（表示 Spec 已被变更，需要重新审核）
- `03-pipeline.md`：终态为 `Superseded`（表示已被新版本取代）

`Changed` ≠ `Superseded`。前者暗示同一版本可恢复，后者暗示需要新版本。

#### I-3：Matrix 状态元状态边界

- `05-layer-standards.md` §9：`Blocked`, `Changed`, `Drifted`, `Stale` 是"元状态"
- `03-pipeline.md` §2.5：同名状态但无"元状态"标注
- 工具脚本中这些状态的处理逻辑不明确

### 4.2 ID/版本不一致（High）

#### I-4：版本号格式冲突

| 文件                  | 格式   | 示例                       |
| --------------------- | ------ | -------------------------- |
| `07-id-system.md`     | `vN`   | `SPEC-market-data-v1`      |
| `12-operations.md`    | `vN.N` | `v0.1`, `v1.0`, `v2.0`     |
| `09-templates.md`     | 混合   | `v1` 与 `v0.1` 并存        |
| `matrix-gen.py` regex | `v\d+` | 只接受 `v1`，不接受 `v1.0` |

**影响**：工具无法处理所有文档中出现的版本号格式。

#### I-5：Evidence ID 格式冲突

| 来源                  | ID 格式                            |
| --------------------- | ---------------------------------- |
| `07-id-system.md`     | `EVID-<test-id>-NNN`               |
| `evidence-collect.sh` | `EVID-${TASK_ID}-${TIMESTAMP}-001` |
| `15-registry.md` 路径 | 与脚本实际输出不一致               |

### 4.3 字段命名不一致（Medium）

#### I-6：Goal 字段命名漂移

| 语义     | 02-goal-standard         | 15-registry        | 09-templates             |
| -------- | ------------------------ | ------------------ | ------------------------ |
| 目标名称 | `name`                   | `title`            | `name`                   |
| 核心目标 | `objective`              | `north_star`       | `objective`              |
| 成功指标 | `success_metrics`        | `success_criteria` | `success_metrics`        |
| 状态字段 | `status`                 | `current_phase`    | 无                       |
| 作用域   | `scope_in` / `scope_out` | —                  | `scope.in` / `scope.out` |

**影响**：脚本和 Registry 必须猜测哪个字段对应哪个语义。

### 4.4 Gate 语义不一致（Medium）

#### I-7：`PASS_WITH_RISK` 流转语义未定义

- `04-gates.md` 定义了 `PASS_WITH_RISK` 结果
- `03-pipeline.md` 的 transition guard 多处只写"Gate PASS"
- 未明确 `PASS_WITH_RISK` 是否允许进入下一阶段

#### I-8：Advisory Score vs Hard Gate 混淆

- `02-goal-standard.md`：Goal 评分 `>= 80` 才能进入 Spec（advisory）
- `04-gates.md`：Gate 结果是 blocking 的（hard）
- `08-quality-gates.md`：定义了 Traceability `>= 95`、AC Coverage `>= 90` 等指标

未明确哪些是 advisory（建议），哪些是 hard gate（阻塞）。

---

## 5. 信息密度分析

### 5.1 文件密度排名

| 排名 | 文件                             | 行数 | 原创内容占比 | 角色                          |
| ---- | -------------------------------- | ---- | ------------ | ----------------------------- |
| 1    | 05-layer-standards.md            | 361  | ~90%         | **核心定义** — 8 层标准       |
| 2    | 11-ai-collaboration.md           | 358  | ~85%         | **核心定义** — AI 协作协议    |
| 3    | 00-quickstart.md                 | 358  | ~80%         | **教程** — 端到端案例         |
| 4    | 09-templates.md                  | 332  | ~85%         | **核心定义** — 模板集         |
| 5    | 18-maturity.md                   | 299  | ~90%         | **核心定义** — 成熟度模型     |
| 6    | 06-dod.md                        | 277  | ~95%         | **核心定义** — DoR/DoD        |
| 7    | 13-runtime-engine.md             | 274  | ~90%         | **核心定义** — 运行时引擎     |
| 8    | 04-gates.md                      | 252  | ~90%         | **核心定义** — Gate 定义      |
| 9    | 16-ci-cd.md                      | 244  | ~85%         | **核心定义** — CI/CD          |
| 10   | 08-quality-gates.md              | 225  | **~40%**     | **重定向密集** — 大量"见 XXX" |
| 11   | 12-operations.md                 | 205  | ~80%         | **核心定义** — 运维           |
| 12   | 02-goal-standard.md              | 186  | ~85%         | **核心定义** — Goal 标准      |
| 13   | 03-pipeline.md                   | 183  | ~90%         | **核心定义** — 管线状态       |
| 14   | 01-methodology.md                | 179  | ~85%         | **核心定义** — 方法论         |
| 15   | 15-registry.md                   | 173  | ~85%         | **核心定义** — Registry       |
| 16   | 22-delivery-os.md                | 171  | ~95%         | **愿景文档** — 未实现         |
| 17   | 23-workflow-governance-checks.md | 144  | ~95%         | **愿景文档** — 未实现         |
| 18   | 07-id-system.md                  | 68   | ~95%         | **核心定义** — ID 格式        |

### 5.2 低密度文件（减熵候选）

| 文件                                  | 问题                               | 建议                                     |
| ------------------------------------- | ---------------------------------- | ---------------------------------------- |
| `08-quality-gates.md`                 | ~60% 内容是引用其他文件 + 内联摘要 | 降级为索引文件，或合并入 04-gates.md     |
| `00-authority-map.md`                 | 已在 03/04/06/07 各 SSOT 中被内化  | 可保留为速查表，但不应承载新规则         |
| `24-standard-unification-analysis.md` | 自分析报告，修复后价值递减         | 归档到 `docs/report/goal/`，从主目录移除 |

### 5.3 高密度文件（拆分候选）

| 文件                              | 问题                                                        | 建议                                      |
| --------------------------------- | ----------------------------------------------------------- | ----------------------------------------- |
| `05-layer-standards.md` (361 行)  | 定义了 8 个层的标准，职责过宽                               | 考虑按层拆分，或至少将 Matrix 标准独立    |
| `11-ai-collaboration.md` (358 行) | 定义了 Context Package、PromptOps、Code Boundary 等多个概念 | 可拆为 PromptOps + Code Boundary 两个文件 |

---

## 6. 跨文件引用复杂度

### 6.1 引用扇入（被引用最多的文件）

| 文件                    | 被引用次数 | 引用来源                                                                                             |
| ----------------------- | ---------- | ---------------------------------------------------------------------------------------------------- |
| `03-pipeline.md`        | 8+         | 00-authority-map, 05-layer-standards, 08-quality-gates, 13-runtime, 15-registry, GLOSSARY, CHANGELOG |
| `04-gates.md`           | 6+         | 00-authority-map, 05-layer-standards, 08-quality-gates, 23-governance, GLOSSARY                      |
| `05-layer-standards.md` | 6+         | 00-authority-map, 08-quality-gates, 09-templates, 10-lint, GLOSSARY                                  |
| `02-goal-standard.md`   | 5+         | 00-authority-map, 08-quality-gates, 09-templates, GLOSSARY                                           |
| `06-dod.md`             | 4+         | 00-authority-map, 08-quality-gates, GLOSSARY                                                         |

### 6.2 引用扇出（引用最多的文件）

| 文件                  | 引用其他文件数                               |
| --------------------- | -------------------------------------------- |
| `08-quality-gates.md` | 8+（引用 02, 03, 04, 05, 06, 07, RUBRIC-\*） |
| `00-authority-map.md` | 7+（引用 03, 04, 05, 06, 07, 13, 15）        |
| `README.md`           | 24+（索引所有文件）                          |
| `GLOSSARY.md`         | 15+（引用定义来源）                          |

### 6.3 引用环

未检测到引用环。信息流向总体是单向的（从 SSOT 定义 → 投影引用）。

---

## 7. 熵减优先级排序

### P0 — 必须消除（阻塞可信度）

| 编号 | 熵源                    | 影响                         | 减熵操作                                       |
| ---- | ----------------------- | ---------------------------- | ---------------------------------------------- |
| E-01 | Goal 生命周期三重定义   | 实现者无法确定合法状态       | 统一到 `03-pipeline.md` §2.5，其他文件改为引用 |
| E-02 | Goal 对象字段三重定义   | 脚本/Registry/模板字段不兼容 | 建立 `schema/goal.schema.yaml`，所有文件引用   |
| E-03 | Matrix Schema 双重定义  | 工具输出与文档不一致         | 建立 `schema/matrix.schema.yaml`，统一字段     |
| E-04 | Evidence ID/路径冲突    | 生成器输出不满足 Gate 检查   | 统一 ID 格式到 `07-id-system.md`，更新脚本     |
| E-05 | Gate 阈值文档与脚本分叉 | "通过"的定义不一致           | 建立 `schema/gate-thresholds.yaml`，脚本读取   |

### P1 — 应该消除（影响可维护性）

| 编号 | 熵源                        | 影响                           | 减熵操作                                   |
| ---- | --------------------------- | ------------------------------ | ------------------------------------------ |
| E-06 | Spec 终态语义冲突           | Changed vs Superseded 语义不同 | 统一到 `03-pipeline.md`，明确定义          |
| E-07 | 版本号格式冲突              | 工具无法处理所有格式           | 统一到 `vN`，版本管理用独立 `version` 字段 |
| E-08 | `PASS_WITH_RISK` 流转未定义 | Gate 结果与管线流转脱节        | 在 `04-gates.md` 补充流转规则              |
| E-09 | Advisory vs Hard Gate 混淆  | 评分和门禁的边界不清           | 在 `08-quality-gates.md` 明确分类          |
| E-10 | 08-quality-gates.md 低密度  | 信息密度低，维护成本高         | 降级为索引或合并入 04-gates.md             |

### P2 — 可以优化（影响整洁度）

| 编号 | 熵源                                    | 影响                    | 减熵操作                            |
| ---- | --------------------------------------- | ----------------------- | ----------------------------------- |
| E-11 | 愿景文档与实操混排                      | 目录层级不清            | 考虑 `docs/goal/vision/` 子目录     |
| E-12 | 24-standard-unification-analysis 自分析 | 主目录含分析报告        | 移入 `docs/report/goal/`            |
| E-13 | 05-layer-standards.md 过大              | 单文件 361 行，8 层标准 | 考虑拆分 Matrix 标准                |
| E-14 | GLOSSARY 微漂移                         | 术语表与正文定义微调    | 定期对齐（已有 CHANGELOG 跟踪）     |
| E-15 | 11-ai-collaboration.md 过大             | 单文件 358 行           | 考虑拆分 PromptOps 和 Code Boundary |

---

## 8. 合并/精简建议

### 8.1 文件级合并建议

| 操作           | 源文件                                | 目标                                        | 理由                                |
| -------------- | ------------------------------------- | ------------------------------------------- | ----------------------------------- |
| **降级为索引** | `08-quality-gates.md`                 | 合并评分内容到 `04-gates.md` + 各 RUBRIC.md | 60% 是重定向，维护成本高于信息价值  |
| **归档**       | `24-standard-unification-analysis.md` | `docs/report/goal/`                         | 自分析报告，修复后价值递减          |
| **拆分**       | `05-layer-standards.md` §9 Matrix     | 独立为 `05b-matrix-standard.md`             | Matrix 是横切制品，不应藏在层标准中 |
| **合并**       | `02-goal-standard.md` §8 评分         | 迁移到 `RUBRIC-goal.md`                     | 评分标准应与各层 RUBRIC 统一        |

### 8.2 Schema 级统一建议

新增文件：`docs/goal/schema/`

| 文件                    | 内容                                          | 消除的熵源          |
| ----------------------- | --------------------------------------------- | ------------------- |
| `goal.schema.yaml`      | Goal 对象唯一机器 schema                      | E-02, I-6           |
| `matrix.schema.yaml`    | Matrix 行唯一机器 schema                      | E-03, R-4           |
| `evidence.schema.yaml`  | Evidence 对象唯一 schema                      | E-04, I-5           |
| `gate-thresholds.yaml`  | 所有 Gate 阈值单一来源                        | E-05, R-5           |
| `state-dictionary.yaml` | 四类状态枚举（lifecycle/runtime/gate/metric） | E-01, I-1, I-2, I-3 |

### 8.3 状态统一建议

建立状态字典，拆分为四类字段：

```yaml
# state-dictionary.yaml
lifecycle_status: # 对象生命周期
  - Draft
  - Reviewed
  - Approved
  - Active
  - Achieved
  - Partially_Achieved
  - Failed
  - Deprecated

runtime_phase: # 管线阶段就绪态
  - INIT
  - GOAL_READY
  - SPEC_READY
  - DESIGN_READY
  - PLAN_READY
  - TASKS_READY
  - EXECUTING
  - TESTING
  - REVIEWING
  - RELEASING
  - DONE
  - BLOCKED
  - NEEDS_REPLAN

gate_result: # 门禁结果
  - PASS
  - PASS_WITH_RISK
  - FAIL
  - BLOCKED

metric_conclusion: # 指标验证结论
  - Achieved
  - Partially_Achieved
  - Not_Achieved
  - Invalid_Metric
```

---

## 9. 减熵路线图

### Phase 1：Schema 权威化（1-2 天）

目标：消除 E-01 ~ E-05

1. 创建 `docs/goal/schema/` 目录
2. 编写 `goal.schema.yaml`、`matrix.schema.yaml`、`evidence.schema.yaml`
3. 编写 `state-dictionary.yaml`，统一四类状态枚举
4. 更新 `03-pipeline.md` §2.5 对象状态总表，引用 schema
5. 更新 `07-id-system.md`，明确版本号格式
6. 更新 `09-templates.md`，对齐 schema 字段
7. 更新 `15-registry.md`，对齐 schema 字段

### Phase 2：工具对齐（1 天）

目标：消除 I-4, I-5, R-5

1. 更新 `matrix-gen.py` regex，支持统一版本号格式
2. 更新 `evidence-collect.sh`，输出对齐 schema
3. 更新 `gate-check.sh`，阈值从 `gate-thresholds.yaml` 读取
4. 更新 `lint-goal.sh`，增加 schema 校验

### Phase 3：文档精简（0.5 天）

目标：消除 E-10 ~ E-13

1. 降级 `08-quality-gates.md` 为索引文件
2. 归档 `24-standard-unification-analysis.md` 到 `docs/report/goal/`
3. 考虑拆分 `05-layer-standards.md` §9 Matrix 为独立文件
4. 迁移 `02-goal-standard.md` §8 评分到 `RUBRIC-goal.md`

### Phase 4：持续对齐（持续）

目标：防止熵回弹

1. 每次修改后运行 `lint-goal.sh` 校验
2. CHANGELOG 记录所有结构性变更
3. 定期运行 GLOSSARY 对齐检查
4. Gate 阈值变更必须同步 schema 和脚本

---

## 10. 熵减收益估算

| 维度          | 当前熵   | Phase 1 后 | Phase 2 后 | Phase 3 后 |
| ------------- | -------- | ---------- | ---------- | ---------- |
| 状态机一致性  | 0.75     | 0.15       | 0.15       | 0.15       |
| Schema 一致性 | 0.70     | 0.10       | 0.10       | 0.10       |
| 工具一致性    | 0.60     | 0.60       | 0.10       | 0.10       |
| 文档密度      | 0.45     | 0.45       | 0.45       | 0.20       |
| **综合**      | **0.65** | **0.35**   | **0.20**   | **0.15**   |

Phase 1（Schema 权威化）能消除约 46% 的信息熵，是投入产出比最高的操作。

---

## 附录 A：与既有报告的关系

| 既有报告                                      | 本报告补充内容                                   |
| --------------------------------------------- | ------------------------------------------------ |
| `goal-docs-structural-analysis-20260609.md`   | 评分导向；本报告提供信息熵视角和具体减熵操作     |
| `goal-docs-deep-analysis-20260609.md`         | 问题清单导向；本报告聚焦冗余/不一致的系统性根因  |
| `goal-docs-deep-structural-audit-20260609.md` | 审计导向；本报告提供合并/精简的具体建议          |
| `ISSUE-LEDGER.md`                             | 追踪导向；本报告的 E-01~E-15 可作为新 issue 来源 |
| `24-standard-unification-analysis.md`         | 自分析报告；本报告覆盖其未涉及的熵减维度         |

## 附录 B：文件清单与行数

| 文件                             | 行数      | 角色       |
| -------------------------------- | --------- | ---------- |
| 05-layer-standards.md            | 361       | 核心定义   |
| 11-ai-collaboration.md           | 358       | 核心定义   |
| 00-quickstart.md                 | 358       | 教程       |
| 09-templates.md                  | 332       | 核心定义   |
| 18-maturity.md                   | 299       | 核心定义   |
| 06-dod.md                        | 277       | 核心定义   |
| 13-runtime-engine.md             | 274       | 核心定义   |
| 04-gates.md                      | 252       | 核心定义   |
| 16-ci-cd.md                      | 244       | 核心定义   |
| 08-quality-gates.md              | 225       | 重定向密集 |
| tools/README.md                  | 207       | 工具文档   |
| 12-operations.md                 | 205       | 核心定义   |
| 17-risk-and-decisions.md         | 195       | 核心定义   |
| 02-goal-standard.md              | 186       | 核心定义   |
| 03-pipeline.md                   | 183       | 核心定义   |
| 01-methodology.md                | 179       | 核心定义   |
| 15-registry.md                   | 173       | 核心定义   |
| 22-delivery-os.md                | 171       | 愿景文档   |
| README.md                        | 158       | 索引       |
| 23-workflow-governance-checks.md | 144       | 愿景文档   |
| 19-self-improving.md             | 144       | 核心定义   |
| 20-metrics-evidence.md           | 138       | 核心定义   |
| CHANGELOG.md                     | 123       | 变更记录   |
| 21-controlled-rsi.md             | 120       | 核心定义   |
| 10-lint-rules.md                 | 109       | 核心定义   |
| 14-agent-protocols.md            | 98        | 核心定义   |
| 07-id-system.md                  | 68        | 核心定义   |
| GLOSSARY.md                      | 62        | 术语索引   |
| **合计**                         | **5,929** |            |
