# TASK-KERNEL-016a

> docs/：项目文档目录 + 治理/Spec/设计/标准文档

---

```yaml
task_id: TASK-KERNEL-016a
module: kernel
scope: "创建 docs/ 项目文档：ADR、设计、治理、Spec、标准、证据目录"
parent: TASK-KERNEL-016
spec_ref:
  - "module/kernel/SPEC.md#22"
files:
  - "docs/adr/ADR-001.md"
  - "docs/design/architecture.md"
  - "docs/governance/compliance.md"
  - "docs/spec/README.md"
  - "docs/standard/coding.md"
acceptance_criteria:
  - "AC-DOCS-A01: 5 个文档目录均已创建含占位文件"
  - "AC-DOCS-A02: ADR 记录 DESIGN.md §4 的 6 个决策"
depends_on:
  - "TASK-KERNEL-014"
estimated_effort: "0.75h"
priority: P1
status: pending
```

## Non-scope

- 不复制 SPEC.md 全文（引用即可）
- 不包含测试密钥或个人环境路径
