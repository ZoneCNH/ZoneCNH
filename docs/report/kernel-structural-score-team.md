# kernel Spec 结构性评估报告

> 评估对象：`specs/kernel/` 目录全部文件
> 评估日期：2026-06-08
> 评估人：spec-analysis（Critic）

---

## 摘要

kernel spec 目录包含 SPEC.md（23 节完整规格，705 行）、IMPLEMENTATION-PLAN.md（DAG + 并行策略）、TRACEABILITY.md（FR→AC→TC 全链追溯）、TASK-001-PROMPT.md（开发 prompt）和 tasks/ 子目录下 11 个任务文件（TASK-KERNEL-000~010）。

**整体质量：优秀。** SPEC.md 是标杆级的 23 节结构，WHEN/THEN 语义清晰，边界场景覆盖充分。追溯矩阵实现零缺口覆盖（5 FR / 9 BR / 8 AC / 18 TC 全部闭环）。任务拆分粒度合理，依赖关系明确。主要改进点集中在：目录级 README 缺失、IMPLEMENTATION-PLAN 可视化不足、AC 编号体系不统一、以及 plan 阶段边界不清晰。

**总评：80 / 100**

---

## 评分总览

| # | 维度 | 分数 | 满分 | 评级 |
|---|------|------|------|------|
| 1 | 文档完整性 | 7 | 10 | 🟡 良好 |
| 2 | 结构一致性 | 8 | 10 | 🟢 优秀 |
| 3 | 交叉引用完整性 | 9 | 10 | 🟢 优秀 |
| 4 | 职责边界清晰度 | 8 | 10 | 🟢 优秀 |
| 5 | 任务分解质量 | 8 | 10 | 🟢 优秀 |
| 6 | SPEC 质量 | 9 | 10 | 🟢 优秀 |
| 7 | IMPLEMENTATION-PLAN 质量 | 7 | 10 | 🟡 良好 |
| 8 | 可维护性 | 8 | 10 | 🟢 优秀 |
| | **合计** | **64** | **80** | |
| | **换算总分** | **80** | **100** | 🟢 |

---

## 详细问题列表

### 1. 文档完整性（7/10）

**✅ 优点**
- SPEC.md 23 节结构完整（§1 Metadata ~ §23 Open Questions），705 行，深度充分
- TRACEABILITY.md 覆盖 FR→AC→TC 全链，Coverage Summary 零缺口
- IMPLEMENTATION-PLAN.md 包含 DAG、并行策略、文件冲突分析、风险缓解
- tasks/ 下 11 个任务文件全部存在，每个都有 YAML frontmatter + Requirements + Test Plan + Implementation Notes

**❌ 严重问题**

无。

**⚠️ 中等问题**

| ID | 问题 | 位置 |
|----|------|------|
| D1-1 | **缺少 `specs/kernel/README.md`**：父目录 `specs/README.md` 有完整索引，但 kernel 子目录无本地 README。缺少快速入口点说明 kernel spec 包的文件清单、使用方式和导航 | `specs/kernel/` |
| D1-2 | **`TASK-001-PROMPT.md` 命名不一致**：所有任务文件遵循 `TASK-KERNEL-XXX.md` 命名，唯独此文件名为 `TASK-001-PROMPT.md`，且使用后缀 `-PROMPT` 而非纯任务名 | `specs/kernel/TASK-001-PROMPT.md` |

**💡 改进建议**

| ID | 建议 |
|----|------|
| D1-3 | 考虑添加 `specs/kernel/INDEX.md`，作为 11 个 task 文件的快速索引（当前需遍历目录才能了解全貌） |

---

### 2. 结构一致性（8/10）

**✅ 优点**
- 11 个 task 文件严格遵循统一模板：YAML frontmatter → Requirements Covered → Test Plan → Implementation Notes
- SPEC.md 遵循 `specs/README.md` 定义的 23 节模板
- TRACEABILITY.md 使用统一的 6 列表格（Requirement / Description / AC / TC / Task / Status）
- 所有文件使用中文描述，英文保留给仓库名、模块名和技术术语

**⚠️ 中等问题**

| ID | 问题 | 位置 |
|----|------|------|
| D2-1 | **文件格式混合**：task 文件和 TRACEABILITY 使用 Markdown，SPEC.md §11 的配置使用 YAML。SPEC.md 中 9.1/10.1/10.2 使用 Go 代码块。这本身合理，但 `IMPLEMENTATION-PLAN.md` 的依赖 DAG 用纯 text 代码块，可视化不如 Mermaid/ASCII 图清晰 | `IMPLEMENTATION-PLAN.md:10-22` |
| D2-2 | **Status 字段仅 task 文件有 YAML 格式**，TRACEABILITY 的 Status 列是纯文本 `Pending`，无机器可读的状态枚举定义 | `TRACEABILITY.md:11` vs `tasks/*.md:status` |

**💡 改进建议**

| ID | 建议 |
|----|------|
| D2-3 | IMPLEMENTATION-PLAN 的 DAG 可考虑使用 Mermaid diagram，提高可读性和可渲染性 |

---

### 3. 交叉引用完整性（9/10）

**✅ 优点**
- **追溯矩阵零缺口**：5 FR / 9 BR / 8 AC / 18 TC 全部有覆盖，Coverage Summary 表验证无 gap
- Traceability Rules Verification 全部勾选 ✅
- 所有 task 文件的 `spec_ref` 字段正确指向 `specs/kernel/SPEC.md#§编号`
- IMPLEMENTATION-PLAN 的 DAG 与 task 文件的 `depends_on` 一致（全部 11 个 task 引用匹配）
- task 文件的 Requirements Covered 表正确引用 FR/BR 编号
- task 文件的 Test Plan 正确引用 TC 编号

**⚠️ 中等问题**

| ID | 问题 | 证据 |
|----|------|------|
| D3-1 | **AC 编号体系不统一**：SPEC.md 定义 AC-001~AC-008，task 文件使用 AC-NEW-01~AC-NEW-61。TRACEABILITY 只包含 AC-001~AC-008，**task 文件中独有的 AC-NEW-XX 未进入追溯矩阵**，存在追溯盲区 | TRACEABILITY.md 只有 AC-001~AC-008；TASK-KERNEL-002.md 定义 AC-NEW-09~AC-NEW-15，均未出现在 TRACEABILITY.md |

**💡 改进建议**

| ID | 建议 |
|----|------|
| D3-2 | 将 AC-NEW-XX 编号纳入 TRACEABILITY.md，或在 TRACEABILITY 中增加 "Task-level AC" 列，确保 task 级验收标准也被追溯 |

---

### 4. 职责边界清晰度（8/10）

**✅ 优点**
- SPEC.md：需求定义（What）— WHEN/THEN 行为规格、接口契约、业务规则
- IMPLEMENTATION-PLAN.md：执行策略（How-to-organize）— DAG、并行、文件冲突
- TRACEABILITY.md：追溯与覆盖验证（Traceability）
- tasks/*.md：单任务执行规格（Execute）— scope、AC、test plan、implementation notes
- TASK-001-PROMPT.md：首个任务的可执行 prompt（即开即用）

**⚠️ 中等问题**

| ID | 问题 | 位置 |
|----|------|------|
| D4-1 | **TASK-001-PROMPT.md 定位模糊**：它是 TASK-KERNEL-000 的可执行 prompt（内容完全对应 000 的 scope），但放在根目录而非 tasks/ 子目录，且命名不一致。其余 10 个 task 没有对应的 PROMPT 文件 | `specs/kernel/TASK-001-PROMPT.md` |
| D4-2 | **IMPLEMENTATION-PLAN 与 task 文件内容部分重叠**：plan 的"实现顺序"表和 task 的 `depends_on` + `estimated_effort` 描述同一信息，维护时需同步两处 | `IMPLEMENTATION-PLAN.md:28-40` vs `tasks/*.md` |

**💡 改进建议**

| ID | 建议 |
|----|------|
| D4-3 | 考虑将 TASK-001-PROMPT.md 移入 tasks/ 并重命名为 `TASK-KERNEL-000-PROMPT.md`，或建立统一的 PROMPT 生成规范 |

---

### 5. 任务分解质量（8/10）

**✅ 优点**
- 11 个 task 覆盖完整功能链：骨架(000) → 接口(001) → 依赖图(002) / 注册表(003) / 配置(008) → 启动(004) → 停机(005) → 健康检查(006) → panic 隔离(007) → 集成测试(009) → 文档(010)
- 每个 task 有明确的 `scope`、`acceptance_criteria`、`depends_on`、`estimated_effort`、`priority`
- 文件冲突分析完备（IMPLEMENTATION-PLAN.md:71-81）
- 并行策略合理：Phase 3 最大并行度 3（002/003/008）
- 每个 task 的 Implementation Notes 提供具体实现指导（算法选择、数据结构、注意事项）

**⚠️ 中等问题**

| ID | 问题 | 证据 |
|----|------|------|
| D5-1 | **TASK-KERNEL-005 depends_on 缺少 003**：IMPLEMENTATION-PLAN DAG 显示 004 依赖 002+003，005 依赖 004。但 TASK-KERNEL-005 的 depends_on 只列出 `[001, 004]`，**漏掉了通过 004 间接依赖的 002**。虽然 DAG 传递性隐含了这一点，但显式列出直接依赖更安全 | `TASK-KERNEL-005.md:depends_on: [001, 004]` vs `IMPLEMENTATION-PLAN.md:36` 显示 004 依赖 `002, 003` |
| D5-2 | **TASK-KERNEL-008 depends_on 只有 001**：008 修改 kernel.go（001 创建），但 IMPLEMENTATION-PLAN 建议 008 与 002/003 并行。如果 008 的 options.go 需要引用 001 的接口，那么依赖链正确。但 `options.go` 是否间接依赖 registry（003）的 app 结构体不够明确 | `TASK-KERNEL-008.md:depends_on: [TASK-KERNEL-001]` |

**💡 改进建议**

| ID | 建议 |
|----|------|
| D5-3 | 为 task 添加 `blocks` 字段（反向依赖），使每个 task 明确知道自己阻塞了哪些下游 task |
| D5-4 | 在 task YAML 中增加 `status` 的可选值枚举：`pending / in_progress / blocked / completed / verified` |

---

### 6. SPEC 质量（9/10）

**✅ 优点**
- **23 节结构完整**：从 §1 Metadata 到 §23 Open Questions，严格遵循 specs/README.md 模板
- **WHEN/THEN 语义清晰**：FR-001~FR-005 每个都覆盖了正常路径、异常路径和边界路径（共 17 个 WHEN/THEN 子句）
- **Business Rules 完备**：9 条规则全部有"违反时"处理说明（BR-001~BR-009）
- **Edge Cases 深入**：21 个边界场景，覆盖并发、空状态、panic、超时、死锁等
- **接口契约精确**：§9.1 包含完整的 Go 接口定义，包括 kernel 内最小接口（Logger/Meter/Tracer/ConfigReader/Scheduler/ResilientPolicy），明确 BR-009 的 stdlib-only 设计
- **CI Gate 可执行**：§20 提供具体命令和阻断条件，包含 kernel 专属 gate（stdlib-only、no-hidden-goroutine）
- **可观测性详细**：§18 定义了 3 个 metric + 6 个 log + 2 个 span，命名规范（`foundationx_kernel_*`）
- **测试矩阵完整**：§16.1 单元测试 10 场景 + §16.2 AC 表 + §16.3 Given/When/Then 18 个 TC + §16.4 Benchmark + §16.5 集成测试

**💡 改进建议**

| ID | 建议 |
|----|------|
| D6-1 | §11 Config Schema 的 `modules: []` 字段描述为"显式模块列表（可选，默认自动发现）"，但 §9.1 的 App 接口没有 `AutoDiscover()` 方法，Register 是显式调用。建议澄清 `modules` 配置项的语义——是否只是文档性配置，kernel 并不实际使用它 |
| D6-2 | §23 Open Questions 中两个 Non-blocking 问题已有决策结论，建议将结论提升到对应的正文章节（§5 Non-goals 或 §7 FR），减少读者在 §23 和正文之间跳转 |

---

### 7. IMPLEMENTATION-PLAN 质量（7/10）

**✅ 优点**
- **DAG 清晰**：树形结构展示依赖链，每个节点标注功能名
- **并行策略合理**：Phase 3 最大并行度 3，标注了可并行 task
- **文件冲突分析**：8 个文件的创建/修改 Task 和冲突风险一目了然
- **测试策略分层**：单元 / 集成 / Benchmark / stdlib-only / 覆盖率，按 task 粒度分配
- **风险缓解**：4 个核心风险（拓扑排序 bug、panic recovery、并发安全、stdlib-only）均有具体缓解措施

**⚠️ 中等问题**

| ID | 问题 | 证据 |
|----|------|------|
| D7-1 | **DAG 可视化为树形但实际是 DAG**：TASK-KERNEL-006 依赖 001+003，但树形图中 006 只作为 001 的子节点显示（靠注释 `← 依赖 001, 003` 补充）。同理 009 依赖 5 个 task，只挂在 008 下。容易误读为线性依赖 | `IMPLEMENTATION-PLAN.md:18-22` |
| D7-2 | **缺少 Phase 边界和退出标准**：plan 提到 Phase 1~9 但没有明确定义每个 Phase 的完成标准（exit criteria）。例如 Phase 3（002/003/008 并行）完成后，进入 Phase 4 的前提条件是什么？ | `IMPLEMENTATION-PLAN.md:28-40` |
| D7-3 | **缺少回滚策略**：如果某个 Phase 中途失败（如 004 实现到一半发现 002 的拓扑排序有 bug），如何回退？plan 的风险缓解只说"充分测试"，没有具体的修复/回退路径 | `IMPLEMENTATION-PLAN.md:96-104` |

**💡 改进建议**

| ID | 建议 |
|----|------|
| D7-4 | 将 DAG 改用 Mermaid `graph TD` 语法渲染，可自动处理多父节点依赖的可视化 |
| D7-5 | 在每个 Phase 行增加 `Exit: <前置条件列表>` 列 |

---

### 8. 可维护性（8/10）

**✅ 优点**
- **目录结构清晰**：`specs/kernel/` + `specs/kernel/tasks/` 二级结构
- **命名规范一致**：TASK-KERNEL-{NNN}.md 格式，三位数编号
- **文件粒度合理**：task 文件平均 60 行（53~72 行），易于 AI 代理单次读取
- **SPEC.md 有变更历史**：§1.1 记录了 v1.0.0 → v1.1.0 的变更内容
- **所有文件使用 UTF-8 中文**，无编码问题

**⚠️ 中等问题**

| ID | 问题 | 证据 |
|----|------|------|
| D8-1 | **SPEC.md 705 行偏长**：虽未超过 800 行上限，但对于需要快速参考的场景（如 AI 代理上下文窗口），缺少摘要或 TOC。当前只能靠 §2 Summary 的一句话概括 | `SPEC.md` 705 行 |
| D8-2 | **go.mod Go 版本不一致**：SPEC.md §15.1 写 `go 1.23`，TASK-001-PROMPT.md 写 `go 1.24`。需统一 | `SPEC.md:442` vs `TASK-001-PROMPT.md:18` |

**💡 改进建议**

| ID | 建议 |
|----|------|
| D8-3 | 在 SPEC.md 头部（§1 之后）增加目录（TOC），方便长文档导航 |
| D8-4 | 统一 Go 版本为 `go 1.24`（与最新 task prompt 一致），并同步更新 SPEC.md §15.1 |

---

## 改进建议优先级排序

| 优先级 | ID | 问题 | 影响 | 工作量 |
|--------|----|------|------|--------|
| P1 | D3-1 | AC 编号体系不统一，AC-NEW-XX 未进入追溯矩阵 | 追溯盲区，可能导致 task 级 AC 被遗漏 | 中（更新 TRACEABILITY.md） |
| P1 | D8-2 | go.mod Go 版本 1.23 vs 1.24 不一致 | 开发者困惑，可能导致编译问题 | 小（改一处数字） |
| P2 | D1-1 | 缺少 specs/kernel/README.md | 新人/代理无法快速了解 spec 包结构 | 小（新建一个文件） |
| P2 | D4-1 | TASK-001-PROMPT.md 命名和位置不一致 | 文件组织混乱 | 小（移文件+重命名） |
| P2 | D7-1 | DAG 树形图不准确表示多父依赖 | 误导开发顺序理解 | 中（改用 Mermaid） |
| P2 | D7-2 | Phase 缺少退出标准 | Phase 间质量门不明确 | 中（为 9 个 Phase 补标准） |
| P3 | D7-3 | 缺少回滚策略 | Phase 失败时无恢复指导 | 中 |
| P3 | D3-2 | AC-NEW-XX 纳入追溯矩阵 | 消除追溯盲区 | 中 |
| P3 | D8-1 | SPEC.md 增加 TOC | 长文档导航 | 小 |
| P3 | D6-1 | §11 modules 配置项语义澄清 | 减少歧义 | 小 |
| P3 | D6-2 | §23 决策结论提升到正文 | 减少跳转 | 小 |

---

## 维度分析雷达图（文本版）

```
文档完整性     ███████░░░  7/10
结构一致性     ████████░░  8/10
交叉引用完整性 █████████░  9/10
职责边界清晰度 ████████░░  8/10
任务分解质量   ████████░░  8/10
SPEC 质量      █████████░  9/10
IMPLEMENTATION ███████░░░  7/10
可维护性       ████████░░  8/10
```

---

## 结论

kernel spec 包整体质量 **优秀**（80/100），SPEC.md 可作为其他模块规格的标杆。追溯矩阵实现零缺口覆盖，任务拆分粒度合理且依赖明确。

**2 个 P1 问题需优先修复**：AC 编号统一（消除追溯盲区）和 Go 版本一致（消除歧义）。

**P2 问题建议在进入开发前修复**：添加目录级 README、统一 PROMPT 文件命名、改善 DAG 可视化、补充 Phase 退出标准。

**P3 问题可在开发过程中逐步改进**。

---

*报告生成时间：2026-06-08*
