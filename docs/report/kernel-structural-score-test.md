# kernel 规格结构性评估报告

> 评估日期：2026-06-08
> 评估范围：`specs/kernel/` 目录全部 15 个 .md 文件
> 评估版本：SPEC v1.1.0

---

## 摘要评分表

| 维度 | 得分 | 满分 | 说明 |
|------|------|------|------|
| 文档完整性 | 9 | 10 | SPEC 23 节齐全，任务文件结构完整，缺集中式 AC 注册表 |
| 结构一致性 | 7 | 10 | 任务文件格式统一，但 AC 编号体系分裂（SPEC vs TASK） |
| 交叉引用完整性 | 7 | 10 | FR→BR→AC→TC→Task 链路完整，但 AC-NEW 系列脱离追溯矩阵 |
| 职责边界清晰度 | 9 | 10 | L0/L1 边界明确，Deps 注入模式清晰，任务职责单一 |
| 任务分解质量 | 8 | 10 | DAG 合理、并行策略清晰，但 IMPLEMENTATION-PLAN DAG 图有遗漏 |
| SPEC 质量 | 9 | 10 | WHEN/THEN 格式规范，18 条边界场景覆盖全面，有小量缺口 |
| IMPLEMENTATION-PLAN 质量 | 8 | 10 | 关键路径、文件冲突分析到位，DAG 图与任务文件不完全一致 |
| 可维护性 | 7 | 10 | 文件组织清晰，但版本不一致和孤岛文件增加维护风险 |
| **总分** | **64** | **80** | **换算百分制：80 分** |

---

## 详细问题清单

### ❌ 严重问题

#### S-01: AC 编号体系分裂 — 61 个 AC-NEW 未纳入追溯矩阵

**位置**：SPEC.md §16.2（AC-001~AC-008）、tasks/TASK-KERNEL-*.md（AC-NEW-01~AC-NEW-61）

SPEC 的验收标准节（§16.2）仅定义了 AC-001 到 AC-008 共 8 项。但 11 个任务文件中额外定义了 AC-NEW-01 到 AC-NEW-61 共 61 项验收标准，这些 AC-NEW 编号：

- 未出现在 SPEC.md 的任何位置
- 未纳入 TRACEABILITY.md 的追溯矩阵
- 无法从 SPEC 端正向追溯到测试
- 无法确认是否覆盖了所有 WHEN/THEN 场景

TRACEABILITY.md 声称 `AC: 8 | Covered: 8 | Gaps: None`，但实际上有 69 个 AC（8 + 61），追溯矩阵只覆盖了 11.6%。

**影响**：验收时无法确认所有 AC 已通过；新贡献者无法从 SPEC 端了解完整验收清单。

**修复建议**：将 AC-NEW-XX 全部合并到 SPEC.md §16.2，并同步更新 TRACEABILITY.md 的 AC 表。或在 TRACEABILITY.md 中增加"任务级 AC"子表。

---

#### S-02: Go 版本声明不一致 — go 1.23 vs go 1.24

**位置**：SPEC.md:442（`go 1.23`）、TASK-001-PROMPT.md:18（`go 1.24`）

SPEC §15.1 的 go.mod 示例声明 `go 1.23`，而 TASK-001-PROMPT.md 的 go.mod 模板声明 `go 1.24`。这是一个会导致实际构建行为差异的硬冲突：

- Go 1.24 引入了对 `go.mod` 中 `tool` 指令的支持
- min Go 版本影响 `go vet`、`go test` 的行为差异
- 执行者不知道以哪个为准

**影响**：可能导致 CI 环境与本地开发环境的 Go 版本不一致，或构建产物行为差异。

**修复建议**：统一为一个版本（建议 go 1.24，因为这是较新的声明），并在 SPEC.md §15.1 和 TASK-001-PROMPT.md 中同步更新。

---

### ⚠️ 中等问题

#### M-01: TASK-001-PROMPT.md 是游离于任务体系之外的孤岛文件

**位置**：`specs/kernel/TASK-001-PROMPT.md`

该文件：
- 不在 `tasks/` 子目录中，与 TASK-KERNEL-000~010 的组织结构不一致
- 没有任何其他文件引用它（grep 确认零引用）
- 定义了自己的 AC-NEW-01/02/03，与 TASK-KERNEL-000.md 的 AC-NEW-01/02/03 编号冲突但内容不同
  - TASK-001-PROMPT: AC-NEW-01 = `go build` 编译通过
  - TASK-KERNEL-000: AC-NEW-01 = 所有 10 个错误变量可被外部包引用

**影响**：AC 编号冲突导致验收时歧义；文件位置不一致增加维护成本。

**修复建议**：将 TASK-001-PROMPT.md 的内容合并到 TASK-KERNEL-000.md 的 Implementation Notes 中，或删除该文件。如果保留，至少重命名 AC 编号避免冲突。

---

#### M-02: IMPLEMENTATION-PLAN 依赖 DAG 图与任务文件 depends_on 不完全一致

**位置**：IMPLEMENTATION-PLAN.md:10-22

DAG 图中 TASK-KERNEL-009 的入边显示为：
```
└── TASK-KERNEL-009 (集成测试) ← 依赖 004, 005, 006, 007, 008
```

但 TASK-KERNEL-009.md 的 depends_on 字段列出了 004, 005, 006, 007, 008 五项，DAG 图的树形结构无法完整表达 005→009 的依赖关系（因为 005 在树中是 004 的子节点，视觉上暗示 009 只通过 007 间接依赖 005）。

**影响**：执行者可能误解依赖关系，错误地并行执行 005 和 009。

**修复建议**：将 DAG 图改为表格或 Mermaid 图，完整表达所有依赖边。

---

#### M-03: §13 边界场景与 §16.3 测试用例存在覆盖缺口

**位置**：SPEC.md §13 vs §16.3

§13 定义了 18 个边界场景，但以下场景在 §16.3 中没有对应的 TC：

| 边界场景 | 是否有对应 TC |
|----------|--------------|
| 并发 Run | ❌ 无直接 TC |
| Run 后再 Register | ❌ 无直接 TC |
| Register() 在 Shutdown() 完成后调用 | ❌ 无直接 TC |
| 模块 Init 内部调用 Register | ❌ 无直接 TC |
| 模块 Start 耗时 >startup_timeout | ❌ 无直接 TC |
| Run() 和 Shutdown() 并发调用 | ❌ 无直接 TC |
| 模块 Init 内部调用 Shutdown() | ❌ 无直接 TC |
| ctx 超时 < 模块 Init 耗时 | ❌ 无直接 TC |

8 个边界场景缺少直接 TC 编号映射（部分可能被现有 TC 隐式覆盖，但未显式关联）。

**影响**：验收时无法确认这些边界场景是否被测试覆盖。

**修复建议**：为每个缺失的边界场景补充 TC 编号，并在 §16.3 中添加对应的 Given/When/Then 用例。

---

#### M-04: `modules: []` 配置项无对应实现任务

**位置**：SPEC.md:352

Config Schema 中定义了 `modules: [] # 显式模块列表（可选，默认自动发现）`，但：

- 没有任何任务文件提到实现模块自动发现功能
- TASK-KERNEL-003（注册表）只实现了手动 Register，未涉及自动发现
- §23 Open Questions 中也未提及此配置项的决策

**影响**：配置 schema 声明了一个不存在的功能，可能导致用户困惑。

**修复建议**：要么删除 `modules: []` 配置项（当前设计只支持手动 Register），要么在 §23 中记录决策并在 IMPLEMENTATION-PLAN 中增加对应任务。

---

#### M-05: TASK-KERNEL-005 depends_on 遗漏隐式依赖

**位置**：tasks/TASK-KERNEL-005.md:27-29

TASK-KERNEL-005 的 depends_on 为 `[TASK-KERNEL-001, TASK-KERNEL-004]`，但其 files 列表包含 `internal/signal/signal.go`，这是一个新文件。TASK-KERNEL-004 也创建 `lifecycle.go`。虽然通过 004 的传递依赖可以覆盖 002/003，但 IMPLEMENTATION-PLAN 的实现顺序表中 005 的依赖列显示 `004`，而 DAG 图中 005 是 004 的子节点 — 这是正确的。

实际上这不是一个真正的问题，因为 004 已经依赖 002 和 003，传递依赖是完整的。**降级为建议**。

---

#### M-06: health_check_interval 默认值未在 SPEC 中明确

**位置**：SPEC.md:351、TASK-KERNEL-008.md:43

SPEC §11 Config Schema 中 `health_check_interval: 10s` 以示例值出现，但未明确标注"默认值"。TASK-KERNEL-008 的 Test Plan 中测试 `New()` 的默认值，但只测试了 `startup_timeout: 30s` 和 `shutdown_timeout: 15s`，未测试 `health_check_interval` 的默认值。

**影响**：实现者可能将默认值设为 0 或其他值，导致行为不一致。

**修复建议**：在 SPEC §11 中明确标注每个配置项的默认值，并在 TASK-KERNEL-008 的 Test Plan 中补充 health_check_interval 默认值测试。

---

### 💡 建议

#### L-01: TRACEABILITY.md 增加"任务级 AC"列

当前追溯矩阵只追踪 SPEC 定义的 AC-001~AC-008。建议在 AC 表中增加一列"Task AC"，列出每个 FR/BR 对应的任务级 AC 编号（AC-NEW-XX），形成完整的双向追溯。

#### L-02: IMPLEMENTATION-PLAN 考虑使用 Mermaid 图替代 ASCII DAG

当前 ASCII DAG 图在表达多入边节点（如 TASK-KERNEL-009 有 5 个前置依赖）时力不从心。Mermaid 或表格形式能更准确地表达复杂依赖关系。

#### L-03: 任务文件增加 Status 追踪字段的使用说明

所有任务文件的 YAML frontmatter 都有 `status: pending`，但没有说明状态流转规则（pending → in_progress → completed → verified？）。建议在 IMPLEMENTATION-PLAN 或独立的 CONTRIBUTING.md 中定义状态机。

#### L-04: SPEC §9.1 代码块标记为 ```text 而非 ```go

SPEC.md:279 和 :303 的代码块结束标记为 ````text` 而非 ````go`，导致语法高亮失效。这是排版问题，不影响内容正确性。

#### L-05: 考虑为 TASK-KERNEL-007 增加冲突缓解策略

TASK-KERNEL-007 修改 TASK-KERNEL-004 和 005 创建的文件（lifecycle.go、shutdown.go）。IMPLEMENTATION-PLAN 的文件冲突分析已标注此风险，但未给出具体的合并策略。建议在 TASK-KERNEL-007 的 Implementation Notes 中明确：是追加新函数还是修改现有函数的调用点。

#### L-06: §23 Open Questions 已有决策结论，建议归档

§23 中的 3 个问题（1 blocking + 2 non-blocking）都已有明确决策。建议将已决策的问题移到"已决策"子节或变更历史中，保留 Open Questions 节只放真正待决的问题。

---

## 改进优先级

| 优先级 | 编号 | 问题 | 预估工作量 |
|--------|------|------|-----------|
| P0 | S-01 | AC-NEW 编号纳入追溯矩阵 | 2h（合并 AC + 更新 TRACEABILITY） |
| P0 | S-02 | Go 版本统一 | 10min（改两处声明） |
| P1 | M-01 | 处理 TASK-001-PROMPT.md 孤岛文件 | 30min（合并或删除） |
| P1 | M-03 | 补充边界场景 TC 覆盖 | 1h（补充 8 个 TC 的 Given/When/Then） |
| P1 | M-04 | 处理 modules: [] 配置项 | 15min（删除或记录决策） |
| P2 | M-02 | DAG 图改为更精确的表达 | 30min |
| P2 | M-06 | 明确 health_check_interval 默认值 | 10min |
| P3 | L-01~L-06 | 各项建议 | 各 10-30min |

---

## 维度评分明细

### 1. 文档完整性（9/10）

**优点**：
- SPEC 包含完整的 23 节结构，覆盖功能需求、业务规则、接口契约、测试、安全、CI 等全部维度
- 每个任务文件包含 scope、spec_ref、files、acceptance_criteria、depends_on、estimated_effort、implementation notes
- TRACEABILITY.md 提供了 FR→BR→AC→TC→Task 的完整追溯链
- IMPLEMENTATION-PLAN.md 包含依赖 DAG、并行策略、文件冲突分析、风险缓解

**扣分**：
- 缺少集中式的 AC 注册表（AC-NEW-XX 分散在各任务文件中，无统一视图）

### 2. 结构一致性（7/10）

**优点**：
- 11 个任务文件格式高度统一（YAML frontmatter + Requirements Covered + Test Plan + Implementation Notes）
- 所有 spec_ref 引用使用一致的 `specs/kernel/SPEC.md#节号` 格式

**扣分**：
- TASK-001-PROMPT.md 位于根目录而非 tasks/ 子目录，格式与任务文件不同
- AC 编号体系分裂：SPEC 用 AC-001~AC-008，任务用 AC-NEW-01~AC-NEW-61
- TASK-001-PROMPT 与 TASK-KERNEL-000 的 AC-NEW-01/02/03 编号冲突

### 3. 交叉引用完整性（7/10）

**优点**：
- 每个任务的 spec_ref 精确到 SPEC 节号
- TRACEABILITY.md 的 FR→AC→TC→Task 链路完整
- Coverage Summary 显示 FR/BR/AC/TC 全覆盖

**扣分**：
- 61 个 AC-NEW 未纳入追溯矩阵
- TASK-001-PROMPT.md 零引用
- §13 的 8 个边界场景缺少 §16.3 的 TC 映射

### 4. 职责边界清晰度（9/10）

**优点**：
- L0/L1 边界在 SPEC §15.3 和 BR-008/BR-009 中明确定义
- Deps 注入模式清晰分离了 kernel 与 L1 的职责
- 每个任务职责单一，无职责重叠
- internal/dag 和 internal/signal 的包边界合理

**扣分**：
- `modules: []` 配置项暗示了自动发现功能，但未明确其职责归属

### 5. 任务分解质量（8/10）

**优点**：
- 11 个任务覆盖了 SPEC 的所有功能需求
- 依赖 DAG 合理，关键路径清晰（18.5h）
- Phase 3 的三路并行策略有效利用开发资源
- 工作量估算合理（0.5h~4h）
- 文件冲突分析提前识别了 kernel.go、lifecycle.go、shutdown.go 的修改冲突

**扣分**：
- IMPLEMENTATION-PLAN 的 DAG 图无法完整表达 TASK-KERNEL-009 的 5 个前置依赖
- TASK-KERNEL-005 的 depends_on 虽然通过传递依赖完整，但 DAG 图的树形结构可能误导

### 6. SPEC 质量（9/10）

**优点**：
- FR 使用 WHEN/THEN 格式，每个场景独立可测
- 18 条边界场景覆盖了并发、panic、context 取消等关键路径
- 接口契约使用 Go 代码定义，无歧义
- CI Gate 包含 stdlib-only 和 no-hidden-goroutine 两个 kernel 专属检查
- §18 Observability 定义了 3 个 metric + 6 个 log + 2 个 span

**扣分**：
- 8 个边界场景缺少 §16.3 的 TC 编号映射
- health_check_interval 默认值未明确标注
- modules: [] 配置项未有对应实现

### 7. IMPLEMENTATION-PLAN 质量（8/10）

**优点**：
- 依赖 DAG 清晰表达任务间关系
- 实现顺序表包含 Phase、文件、依赖、并行、工作量 5 列
- 关键路径计算正确（18.5h）
- 文件冲突分析提前识别风险
- 测试策略覆盖单元/集成/Benchmark/CI Gate

**扣分**：
- DAG 图的树形结构在多入边节点处表达力不足
- 未为每个任务指定具体的验证命令（虽然任务文件中有）

### 8. 可维护性（7/10）

**优点**：
- 文件组织清晰：SPEC.md + IMPLEMENTATION-PLAN.md + TRACEABILITY.md + tasks/
- 变更历史记录在 SPEC §1.1
- 每个任务文件自包含，可独立阅读

**扣分**：
- Go 版本不一致增加跨文件维护成本
- TASK-001-PROMPT.md 孤岛文件
- AC 编号体系分裂导致更新 SPEC 时需要同步更新所有任务文件
- 无状态流转规则文档

---

## 总结

kernel 规格的整体质量**良好**（80/100）。SPEC 的 23 节结构完整、WHEN/THEN 格式规范、边界场景覆盖全面。任务分解合理，依赖关系清晰，并行策略有效。

最需要优先解决的两个问题是：
1. **AC 编号体系分裂**（S-01）：61 个 AC-NEW 未纳入追溯矩阵，破坏了端到端可追溯性
2. **Go 版本不一致**（S-02）：两处声明冲突，可能导致构建行为差异

这两个问题的修复成本低（合计 < 2.5h），但对规格的可信度和可执行性影响显著。
