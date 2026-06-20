> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](15-delivery-pipeline.md) · [↑ 目录](README.md) · [下一节 →](17-ai-assisted-delivery.md)

---

## 第十六条：追溯与门禁

### 16.1 统一制品 ID

| 前缀   | 制品        | 示例             |
| ------ | ----------- | ---------------- |
| G-     | Goal        | G-001            |
| S-     | Spec        | S-001            |
| M-     | Matrix edge | M-001            |
| T-     | Task        | TASK-REDISX-000  |
| P-     | Prompt      | P-001            |
| C-     | Code Module | CsvExportService |
| TC-    | Test Case   | TC-001           |

### 16.2 追溯覆盖要求

- 每个 Goal 必须有 Spec 覆盖
- 每个 P0 验收标准必须有 Test 覆盖
- 每个 Task 必须有 Goal 来源
- 每个 Code 变更必须有 Matrix 映射

### 16.3 孤儿检测

- 无 Goal 来源的 Task = 范围蔓延，必须标记或删除
- 无 Matrix 映射的 Code = 孤儿代码，必须标记或删除
- 无 Test 的 AC = 不可验证，不得标记完成

### 16.4 门禁

每层之间必须有质量门禁（DoR/DoD）。门禁可渐进增强（Shadow → Advisory → Enforced），但不可绕过。

### 16.5 实现细节

本条款的详细追溯矩阵和门禁规则见 `docs/governance/TRACEABILITY.md`、`docs/governance/DEFINITION-OF-READY.md`、`docs/governance/DEFINITION-OF-DONE.md`、`docs/governance/LIFECYCLE.md`。

---
