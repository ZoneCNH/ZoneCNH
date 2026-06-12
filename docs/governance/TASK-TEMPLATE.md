# Task Spec 模板

> AI 代理任务拆分的标准格式。每个 task 必须遵循此结构，确保可机器校验和追踪。

最后更新：2026-06-07

---

## 用途

Task Spec 是 Feature Spec（`module/*/SPEC.md`）到代码实现的中间层。AI 代理在实现模块时，必须先将 Feature Spec 拆分为 Task Spec，再逐个实现。

```text
Product Spec → Feature Spec → Task Spec → 代码实现 → 测试
                                    ↑
                              本模板定义的格式
```text

---

## Task 结构

每个 Task 必须包含以下字段：

```yaml
TASK-{MODULE}-{NNN}:           # 唯一 ID，如 TASK-KERNEL-001
  module: kernel                # 所属模块名
  scope: "实现 Register 函数"   # 一句话描述范围
  spec_ref:                     # 来源 spec 引用
    - "module/kernel/SPEC.md#FR-001"
    - "module/kernel/SPEC.md#BR-001"
  files:                        # 涉及的文件列表
    - "lifecycle.go"
    - "lifecycle_test.go"
  acceptance_criteria:          # 验收标准（从 spec AC 引用）
    - "AC-001: 模块注册后出现在依赖图中"
    - "AC-002: 重复注册返回 ErrDuplicateModule"
  depends_on:                   # 前置 task（可为空）
    - "TASK-KERNEL-000"
  estimated_effort: "1h"        # 预估工作量（可选）
  priority: P0                  # P0/P1/P2
  status: pending               # pending/in_progress/done/blocked
```text

---

## 字段说明

| 字段                  | 必填   | 说明                                                         |
| --------------------- | ------ | ------------------------------------------------------------ |
| `TASK-{MODULE}-{NNN}` | ✅      | 唯一 ID，MODULE 为模块名大写，NNN 为三位序号                 |
| `module`              | ✅      | 所属模块名，与 `module/{module}/SPEC.md` 对应                |
| `scope`               | ✅      | 一句话描述本 task 做什么，不超过 100 字                      |
| `spec_ref`            | ✅      | 至少一条引用，格式为 `module/{module}/SPEC.md#{FR/BR/AC-ID}` |
| `files`               | ✅      | 涉及的文件列表（含测试文件），使用相对于模块根目录的路径     |
| `acceptance_criteria` | ✅      | 至少一条 AC，格式为 `{AC-ID}: {描述}`                        |
| `depends_on`          | ⬜      | 前置 task ID 列表，可为空                                    |
| `estimated_effort`    | ⬜      | 预估工作量，格式为 `{N}h` 或 `{N}d`                          |
| `priority`            | ✅      | P0（阻塞其他 task）/ P1（本迭代必须）/ P2（可推迟）          |
| `status`              | ✅      | pending → in_progress → done / blocked                       |

---

## 拆分规则

### 一个 Task 的粒度

- **上限**：一个 task 最多涉及 5 个文件、最多实现 3 个 FR
- **下限**：一个 task 至少有 1 个 FR 和 1 个 AC
- **测试同体**：实现文件和对应的测试文件必须在同一个 task 中

### 拆分顺序

1. **接口先行**：先定义接口（contracts），再实现具体模块
2. **依赖优先**：被依赖的模块先拆分（如 kernel 在 configx 之前）
3. **垂直切分**：每个 task 应该是端到端的（接口 + 实现 + 测试），而非水平分层

### 禁止事项

- ❌ 一个 task 跨多个模块
- ❌ 一个 task 只写测试不写实现（或反之）
- ❌ 一个 task 没有 spec_ref（不允许无规格的自由发挥）
- ❌ 一个 task 的 AC 全部引用 BR 而无 FR（BR 是补充约束，不是独立功能）

---

## 示例

### 示例 1：单 FR 实现

```yaml
TASK-KERNEL-001:
  module: kernel
  scope: "实现模块注册功能，支持 Register 和重复注册检测"
  spec_ref:
    - "module/kernel/SPEC.md#FR-001"
    - "module/kernel/SPEC.md#BR-001"
  files:
    - "register.go"
    - "register_test.go"
  acceptance_criteria:
    - "AC-001: Register 后模块出现在 ModuleRegistry 中"
    - "AC-002: 重复注册同名模块返回 ErrDuplicateModule"
    - "AC-003: Register 支持 WithDependencies 选项"
  depends_on: []
  estimated_effort: "2h"
  priority: P0
  status: pending
```text

### 示例 2：多 FR 实现

```yaml
TASK-REDISX-003:
  module: redisx
  scope: "实现分布式锁 Locker 接口，支持 Acquire/Release/TTL 续期"
  spec_ref:
    - "module/redisx/SPEC.md#FR-009"
    - "module/redisx/SPEC.md#FR-010"
    - "module/redisx/SPEC.md#BR-005"
  files:
    - "locker.go"
    - "locker_test.go"
    - "redlock.go"
    - "redlock_test.go"
  acceptance_criteria:
    - "AC-009: Acquire 获取锁成功返回 nil"
    - "AC-009: Acquire 锁已被持有返回 ErrLockHeld"
    - "AC-010: Release 释放锁成功"
    - "AC-010: Release 非持有者释放返回 ErrNotLockOwner"
    - "BR-005: TTL 自动续期在锁持有期间持续生效"
  depends_on:
    - "TASK-REDISX-001"
    - "TASK-REDISX-002"
  estimated_effort: "4h"
  priority: P0
  status: pending
```text

### 示例 3：依赖链

```yaml
TASK-CONFIGX-001:
  module: configx
  scope: "实现配置文件加载，支持 YAML/JSON/TOML 格式"
  spec_ref:
    - "module/configx/SPEC.md#FR-001"
    - "module/configx/SPEC.md#BR-001"
  files:
    - "loader.go"
    - "loader_test.go"
  acceptance_criteria:
    - "AC-001: Load 读取 YAML 文件并解析为 Config 结构体"
    - "AC-001: Load 文件不存在返回 ErrConfigNotFound"
    - "BR-001: 同一 key 多次定义取最后出现的值"
  depends_on:
    - "TASK-KERNEL-001"
  estimated_effort: "2h"
  priority: P0
  status: pending
```text

---

## 批量拆分 Prompt

AI 代理在拆分 task 时，使用以下 prompt：

```markdown
请根据 module/{module}/SPEC.md 拆分 Task Spec。

要求：
1. 每个 FR 至少对应一个 task
2. 相关的 FR 和 BR 可以合并到同一个 task
3. 实现文件和测试文件必须在同一个 task
4. 遵循 TASK-TEMPLATE.md 的格式
5. 输出 YAML 格式的 task 列表
6. task 序号从 001 开始，按依赖顺序排列

约束：
- 一个 task 最多涉及 5 个文件
- 一个 task 最多实现 3 个 FR
- 每个 task 必须有 spec_ref 和 acceptance_criteria
- 被依赖的 task 必须先列出
```text

---

## 校验规则

CI 或 AI 代理可以使用以下规则校验 Task Spec：

1. **ID 唯一性**：同一模块内 TASK-{MODULE}-{NNN} 不重复
2. **spec_ref 有效**：引用的 FR/BR/AC 在对应 spec 中存在
3. **AC 覆盖**：每个 spec FR 至少被一个 task 的 AC 引用
4. **依赖无环**：depends_on 不形成循环依赖
5. **文件不冲突**：同一文件不被多个 in_progress 的 task 引用
6. **粒度合规**：files ≤ 5，FR ≤ 3

---

## 与现有文档的关系

| 文档                                    | 关系                                                        |
| --------------------------------------- | ----------------------------------------------------------- |
| `module/*/SPEC.md`                      | Task Spec 的来源，每个 task 必须引用 spec 中的 FR/BR/AC     |
| `docs/ai/prompt-templates.md` Section 2 | 任务拆分 prompt 的详细版本，本模板定义结构，prompt 定义流程 |
| `docs/governance/TRACEABILITY.md`       | Task 完成后更新 Status 列                                   |
| `docs/governance/DEFINITION-OF-DONE.md` | Task 完成的验收条件                                         |
| `docs/ai/agent-rules.md` Section 9      | AI 代理实现 task 时必须遵循的规则                           |
