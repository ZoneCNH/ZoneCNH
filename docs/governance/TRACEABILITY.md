# Traceability Matrix 规范

> 本文件定义模块级追溯矩阵的结构、字段和校验规则；具体矩阵存放在 `module/{module}/TRACEABILITY.md`。

Last-Updated: 2026-06-09

---

## 1. 目标

追溯矩阵用于确保每个模块的需求、验收标准、测试用例、任务和实现证据可以闭环追踪。

| 目标         | 说明                                             |
| ------------ | ------------------------------------------------ |
| 防漏功能     | 每个 `FR-*` 必须能追到至少一个验收标准和测试用例 |
| 防漏业务规则 | 每个 `BR-*` 必须能追到验证方式或明确的门禁检查   |
| 防伪完成     | Task 完成后必须回填矩阵状态，不能只改实现        |
| 支撑评分     | Matrix 阶段和 Code 阶段评分以模块矩阵作为证据源  |

---

## 2. 存放位置

| 制品         | 路径                                          | 职责                                                   |
| ------------ | --------------------------------------------- | ------------------------------------------------------ |
| 追溯矩阵规范 | `docs/governance/TRACEABILITY.md`             | 定义结构、字段、状态和校验命令                         |
| 模块追溯矩阵 | `module/{module}/TRACEABILITY.md`             | 记录该模块的具体 `FR/BR -> AC -> TC -> Task -> Status` |
| 评分规则     | `docs/governance/scoring/RUBRIC-matrix.md`    | 对矩阵结构完整性打分                                   |
| 仲裁协议     | `docs/governance/scoring/ARBITER-PROTOCOL.md` | 聚合四源评分并决定 gate                                |

`docs/governance/TRACEABILITY.md` 不保存具体模块行；新增模块必须创建自己的 `module/{module}/TRACEABILITY.md`。

---

## 3. 最小表结构

推荐所有模块使用以下最小列集。已有模块可以增加 `Evidence`、`Owner`、`Source` 等列，但不得删除核心列。

| Requirement   | Description          | Acceptance Criteria   | Test Case / TC ID(s) | Task     | Status   |
| ------------- | -------------------- | --------------------- | ---------------- | -------- | -------- |
| FR-001        | 用户可观察的功能需求 | AC-001                | TC-001           | TASK-001 | Pending  |
| BR-001        | 业务约束或工程规则   | AC-010                | CI Gate / TC-010 | TASK-002 | Pending  |

---

## 4. 字段规则

| 字段                  | 要求                                                                                                   |
| --------------------- | ------------------------------------------------------------------------------------------------------ |
| `Requirement`         | 使用 `FR-###` 或 `BR-###`；编号必须与 `SPEC.md` 或模块级参考文件一致                                   |
| `Description`         | 简短描述需求含义，避免复制整段 spec                                                                    |
| `Acceptance Criteria` | `FR-*` 不得为空；优先引用 `AC-###`                                                                     |
| `Test Case`           | `FR-*` 和 `BR-*` 均应引用 `TC-###`、CI Gate、lint/race/import check 等可验证机制                       |
| `Task`                | 已拆分任务后填写 `TASK-###`；拆分前可暂填 `-`                                                          |
| `Status`              | 推荐使用 `Pending`、`In Progress`、`Done`、`Failed`、`Deferred`；兼容历史状态 `⬜`、`🔵`、`✅`、`❌`、`⏭️` |

---

## 5. 覆盖规则

每个模块矩阵必须满足：

1. `SPEC.md` 或模块级 FR 参考文件中的每个 `FR-*` 都有矩阵行。
2. 每个 `FR-*` 至少有一个非空 `Acceptance Criteria`。
3. 每个 `FR-*` 和 `BR-*` 至少有一个可验证机制。
4. 出现 `TC-###` 时，编号必须存在于对应模块 `SPEC.md`，快照型模块可使用独立参考文件。
5. Code 阶段完成后，相关矩阵行必须回填 `Task` 和 `Status`。
6. Matrix 阶段不得修改 `docs/governance/TRACEABILITY.md` 来伪造模块覆盖率。

---

## 6. 状态语义

| 状态                | 含义                           |
| ------------------- | ------------------------------ |
| `Pending` / `⬜`     | 已登记，尚未开始实现或验证     |
| `In Progress` / `🔵` | 任务正在实现或验证中           |
| `Done` / `✅`        | 实现、测试和证据已闭环         |
| `Failed` / `❌`      | 验证失败或需求被证伪           |
| `Deferred` / `⏭️`   | 明确延期，需记录原因和上游决策 |

---

## 7. 验证命令

```bash
TRACEABILITY_STRICT=1 bash .github/ci/traceability-check.sh
```

该检查以 `module/{module}/TRACEABILITY.md` 为事实来源，并验证：

- 必需模块均存在矩阵文件。
- `FR-*` 覆盖数量与模块参考文件一致。
- `FR-*` 的验收标准非空。
- `FR-*` / `BR-*` 的验证机制非空。
- `TC-###` token 格式合法，且能在对应 `SPEC.md` 中找到。
- 状态值属于允许枚举。

---

## 8. Review Prompt

```text
请审查 module/{module}/TRACEABILITY.md：
1. 是否覆盖 SPEC.md 或模块级 FR 参考文件中的所有 FR/BR？
2. 每个 FR 是否具备可测试的 AC？
3. 每个 FR/BR 是否至少有一个 TC 或 CI Gate？
4. Task 与 Status 是否能反映当前实现证据？
5. 是否存在把具体模块矩阵写回 docs/governance/TRACEABILITY.md 的边界错误？
```
