# 快速开始

> **5 分钟理解体系 → 10 分钟走完案例 → 1 分钟选对模式**

> **ID 格式说明**：本文档使用新格式 ID（如 TASK-GOAL-20260601-001-001、REQ-SPEC-order-export-001），详见 [07-id-system.md#id-格式](07-id-system.md#1-id-格式)。

---

## 1. 一句话理解

Goal 驱动交付的核心就一件事：**让每一行代码都能追溯到一个可验证的业务目标。**

```text
你有一个目标 → 拆成需求 → 建追踪矩阵 → 拆任务 → 排计划 → 写 Prompt → 写代码 → 验证 → 上线 → 验证目标达成
```

---

## 2. 你需要什么

| 如果你只有 10 分钟 | 如果你有 1 小时 | 如果你要长期使用 |
|-------------------|----------------|-----------------|
| 读本文件 | 读本文件 + 01-methodology | 读完全部 01-11 |

---

## 3. 最小可用闭环

不需要读完所有文档，先跑通这个：

```text
Goal → Task → DoD → Code → Test → Done
```

### Step 1: 写 Goal

```text
Goal: 运营用户能导出订单 CSV
Success: 导出 10,000 行 < 10 秒
Deadline: 2026-06-15
```

### Step 2: 拆 Task

```text
TASK-GOAL-20260601-001-001: 实现 CSV 生成服务
TASK-GOAL-20260601-001-002: 实现导出 API 接口
TASK-GOAL-20260601-001-003: 实现文件下载
```

### Step 3: 写 DoD

```text
- CSV 包含所有订单字段
- 空数据时生成表头
- 测试通过
```

### Step 4: 写代码 + 测试

### Step 5: 验证 DoD 全部满足

**这就是最简闭环。** 跑通一次后，再逐步叠加 Spec、Matrix、Gate。

---

## 4. 端到端案例：订单 CSV 导出

以下是一个完整推演，展示每一层的实际产出。

### 4.1 Goal

```text
Goal ID:    GOAL-20260601-001
Title:      运营用户订单 CSV 导出
Background: 运营每天手动整理订单报表，耗时 30 分钟以上
Success:    报表整理时间 ≤ 5 分钟
Metrics:
  - 单次 100,000 行导出 ≤ 30 秒
  - 导出成功率 ≥ 98%
Deadline:   2026-06-15
Non-goals:  不做 Excel 导出、不做定时邮件、不做报表可视化
```

**Gate 检查（G1 Goal Gate）：**
- [x] 目标是结果而非方案 ✓
- [x] 有可衡量的成功标准 ✓
- [x] 有截止时间 ✓
- [x] 有非目标 ✓
- → **PASS**

### 4.2 Spec

```text
Spec ID: SPEC-order-export-v1.0

Requirements:
  REQ-SPEC-order-export-v1.0-001: 用户可按日期范围筛选订单
  REQ-SPEC-order-export-v1.0-002: 用户可按订单状态筛选
  REQ-SPEC-order-export-v1.0-003: 导出文件为 CSV 格式
  REQ-SPEC-order-export-v1.0-004: CSV 字段顺序固定
  REQ-SPEC-order-export-v1.0-005: 空数据时仍生成表头

Acceptance Criteria:
  AC-REQ-order-export-001-001: 选择日期范围后，只导出该范围内的订单
  AC-REQ-order-export-002-001: 选择"已完成"状态后，只导出已完成订单
  AC-REQ-order-export-003-001: CSV 文件可在 Excel 中正常打开
  AC-REQ-order-export-004-001: 空筛选条件下，CSV 只包含表头行

Out of Scope:
  - Excel 导出
  - 定时邮件发送
  - 报表可视化
```

**Gate 检查（G2 Spec Gate）：**
- [x] 每个 Requirement 有 Acceptance Criteria ✓
- [x] 边界条件已定义 ✓
- [x] 非目标已明确 ✓
- → **PASS**

### 4.3 Matrix

```text
| Req ID  | AC ID  | Task ID | Test ID | Status |
|---------|--------|---------|---------|--------|
| REQ-SPEC-order-export-v1.0-001 | AC-REQ-order-export-001-001 | TASK-GOAL-20260601-001-001 | TEST-TASK-GOAL-20260601-001-001-001 | — |
| REQ-SPEC-order-export-v1.0-002 | AC-REQ-order-export-002-001 | TASK-GOAL-20260601-001-001 | TEST-TASK-GOAL-20260601-001-001-002 | — |
| REQ-SPEC-order-export-v1.0-003 | AC-REQ-order-export-003-001 | TASK-GOAL-20260601-001-002 | TEST-TASK-GOAL-20260601-001-002-001 | — |
| REQ-SPEC-order-export-v1.0-004 | AC-REQ-order-export-004-001 | TASK-GOAL-20260601-001-002 | TEST-TASK-GOAL-20260601-001-002-002 | — |
| REQ-SPEC-order-export-v1.0-005 | AC-REQ-order-export-004-001 | TASK-GOAL-20260601-001-002 | TEST-TASK-GOAL-20260601-001-002-003 | — |
```

**Gate 检查（Matrix）：**
- [x] 每个 Requirement 至少映射一个 Task ✓
- [x] 每个 AC 至少映射一个 Test ✓
- [x] 无孤立 Task ✓
- → **PASS**

### 4.4 Tasks

```text
TASK-GOAL-20260601-001-001: 实现 OrderRepository.findByFilterPaged()
  Input:  dateRange, status, page, pageSize
  Output: List<Order>
  DoD:    分页查询正确、筛选条件生效、测试通过

TASK-GOAL-20260601-001-002: 实现 CsvExportService.generateOrderCsv()
  Input:  List<Order>
  Output: CSV 文件路径
  DoD:    字段顺序正确、空数据有表头、UTF-8 编码、测试通过

TASK-GOAL-20260601-001-003: 实现 ExportController.exportOrders()
  Input:  HTTP 请求（筛选参数）
  Output: CSV 文件下载
  DoD:    权限校验、参数验证、错误处理、测试通过
```

### 4.5 Plan

```text
Phase 1: TASK-GOAL-20260601-001-001（基础查询，无依赖）
Phase 2: TASK-GOAL-20260601-001-002（依赖 TASK-GOAL-20260601-001-001 的输出）
Phase 3: TASK-GOAL-20260601-001-003（依赖 TASK-GOAL-20260601-001-002 的输出）
```

### 4.6 Prompt

```text
Context Package: CP-002

Goal: GOAL-20260601-001 订单 CSV 导出
Spec: SPEC-order-export-v1.0
Matrix: REQ-SPEC-order-export-v1.0-003→AC-REQ-order-export-003-001→TASK-GOAL-20260601-001-002, REQ-SPEC-order-export-v1.0-004→AC-REQ-order-export-004-001→TASK-GOAL-20260601-001-002, REQ-SPEC-order-export-v1.0-005→AC-REQ-order-export-004-001→TASK-GOAL-20260601-001-002
Task: TASK-GOAL-20260601-001-002 实现 CsvExportService.generateOrderCsv()

Existing Code:
- OrderRepository.findByFilterPaged()

Constraints:
- 不得一次性加载全部订单到内存
- CSV 必须 UTF-8 编码

Tests Required:
- test_csv_column_order
- test_empty_csv_with_headers
- test_large_csv_memory

Do Not:
- 不实现 Excel 导出
- 不实现定时邮件
```

### 4.7 Code + Test

```text
实现 CsvExportService.generateOrderCsv()
编写测试：
  ✓ test_csv_column_order — PASS
  ✓ test_empty_csv_with_headers — PASS
  ✓ test_large_csv_memory — PASS
```

### 4.8 Evidence

```text
Evidence ID: EVID-TASK-GOAL-20260601-001-002-20260601-001
Task ID: TASK-GOAL-20260601-001-002
Files Changed: src/export/CsvExportService.ts, tests/export/csv.test.ts
Commands Run: npm test -- --grep "csv"
Results: 3/3 passed
Requirement Proof: REQ-SPEC-order-export-v1.0-003 ✓, REQ-SPEC-order-export-v1.0-004 ✓, REQ-SPEC-order-export-v1.0-005 ✓
```

### 4.9 Matrix 更新

```text
| Req ID  | AC ID  | Task ID | Test ID | Status |
|---------|--------|---------|---------|--------|
| REQ-SPEC-order-export-v1.0-001 | AC-REQ-order-export-001-001 | TASK-GOAL-20260601-001-001 | TEST-TASK-GOAL-20260601-001-001-001 | PASS |
| REQ-SPEC-order-export-v1.0-002 | AC-REQ-order-export-002-001 | TASK-GOAL-20260601-001-001 | TEST-TASK-GOAL-20260601-001-001-002 | PASS |
| REQ-SPEC-order-export-v1.0-003 | AC-REQ-order-export-003-001 | TASK-GOAL-20260601-001-002 | TEST-TASK-GOAL-20260601-001-002-001 | PASS |
| REQ-SPEC-order-export-v1.0-004 | AC-REQ-order-export-004-001 | TASK-GOAL-20260601-001-002 | TEST-TASK-GOAL-20260601-001-002-002 | PASS |
| REQ-SPEC-order-export-v1.0-005 | AC-REQ-order-export-004-001 | TASK-GOAL-20260601-001-002 | TEST-TASK-GOAL-20260601-001-002-003 | PASS |
```

全部 PASS → **Release Gate 通过**。

### 4.10 上线后验证

```text
Expected: 报表整理时间 ≤ 5 分钟
Observed: 3 分钟
Result:   ✓ Goal 达成
```

---

## 5. 模式选择决策树

```text
你的变更是什么类型？
│
├─ 只改文档/修 typo → Lite Mode
│   └─ Goal → Task → DoD → Evidence → Review
│
├─ 改一个函数/修一个 bug → Lite Mode
│   └─ Goal → Task → DoD → Code → Test → Evidence → Review
│
├─ 新增一个功能 → Standard Mode
│   └─ Goal → Spec → Design → Plan → Tasks → Prompt → Code → Test → Review → Release
│
├─ 改公共接口/改架构 → Full Mode
│   └─ 全流程 + ADR + Human Approval + Release Manifest + Rollback
│
├─ 改数据库/存储 → Full Mode
│   └─ 全流程 + Migration + Rollback Plan + Human Approval
│
└─ 不确定 → 默认用 Standard Mode
    └─ 执行中发现复杂度不够再升级
```

### 快速判断

| 问自己 | 如果是 | 用 |
|--------|--------|-----|
| 只影响一个文件？ | Yes | Lite |
| 影响多个文件但同一模块？ | Yes | Standard |
| 影响多个模块？ | Yes | Standard |
| 改变了外部可感知的行为？ | Yes | Full |
| 改了数据库 Schema？ | Yes | Full |
| 改了公共 API？ | Yes | Full |

---

## 6. 推荐阅读顺序

### 快速上手（30 分钟）

```text
1. 00-glossary.md — 核心术语定义
2. 00-quickstart.md（本文件）— 建立整体认知
3. 01-methodology.md — 理解核心原理
4. 09-templates.md — 拿到可用模板
```

### 完整掌握（2 小时）

```text
1. 00-quickstart.md
2. 01-methodology.md
3. 02-goal-standard.md
4. 03-pipeline.md
5. 04-gates.md
6. 05-layer-standards.md
7. 06-dod.md
8. 07-id-system.md
9. 08-quality-gates.md
10. 09-templates.md
11. 11-ai-collaboration.md
```

### 深度使用（4 小时）

```text
全部按顺序读：00 → 01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11
```

### 高级使用（按需）

> 以下文件覆盖运行引擎、Agent 协议、CI/CD、风险决策、成熟度、递归改进和 Delivery OS。适合需要深入治理和自动化的团队。

```text
13-runtime-engine.md     — 执行模式、对象模型、Evidence、失败预算
14-agent-protocols.md    — Agent Team 协作、Worktree 隔离
15-registry.md           — Registry 子系统（Goal/Task/Issue/Release/Risk/Decision）
16-ci-cd.md              — CI Gates、x.go 规则、反模式
17-risk-and-decisions.md — Risk Register、ADR、Release Manifest
18-maturity.md           — L0-L5 成熟度升级路径
19-self-improving.md     — Patch 系统、体系演进
20-metrics-evidence.md   — Metrics Review、Evidence Graph
21-controlled-rsi.md     — 受控递归改进
22-delivery-os.md        — Delivery OS 五个运行时（愿景架构）
23-workflow-governance-checks.md — 工作流治理检查（愿景架构）
```

---

## 7. 常见问题

### "这套体系太重了，我的小任务也要走这么多步骤？"

不需要。用 Lite Mode，5 步搞定：Goal → Task → DoD → Code → Done。

### "Matrix 真的有必要吗？"

当你发现"需求说要做但代码里漏了"的时候，Matrix 就有必要了。如果任务简单到不会遗漏，可以跳过。

### "我怎么知道 Goal 写得好不好？"

用 02-goal-standard.md 的评分表自检。核心就三条：
1. 是结果不是方案
2. 有数字可以衡量
3. 有截止时间

### "Prompt Chain 必须 7 步吗？"

不是。小任务一个 Prompt 搞定。Prompt Chain 适用于复杂功能，目的是避免一个 Prompt 塞太多上下文导致 AI 输出质量下降。

### "Agent Team 是必须用 9 个 Agent 吗？"

不是。那是虚拟角色分工，实际可以一个人扮演所有角色。Agent Team 的价值在于：当你真的用 AI Agent 执行时，给它明确的角色定义能提高输出质量。
