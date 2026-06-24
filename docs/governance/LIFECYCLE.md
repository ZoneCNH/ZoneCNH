# Spec 生命周期

> 定义 `module/*/SPEC.md` 的状态流转规则。

最后更新：2026-06-25

---

## 1. 状态定义

| 状态          | 含义                       | 进入条件                                               | 退出条件                                               |
| ------------- | -------------------------- | ------------------------------------------------------ | ------------------------------------------------------ |
| `Draft`       | 草稿，正在编写             | 新建 `SPEC.md`                                         | 内容完整后进入 Spec 四源评分                           |
| `Review`      | 结构评分或修复中           | `Draft` 或 `Changed` 提交 Spec gate                    | `pipeline-arbiter` pass 自动转 `Approved`；fail 回修复 |
| `Approved`    | 已批准，可进入开发         | Spec 四源评分和 arbiter 均通过                         | 开发者开始实现                                         |
| `Implemented` | 已实现                     | 模块追溯矩阵所有 FR 标记 `Done` / `✅`，且 DoD 证据齐全 | -                                                      |
| `Changed`     | 已批准或已实现的规格被修改 | 修改 `Approved` / `Implemented` 状态的 `SPEC.md`       | 重新进入 `Review` 并跑四源评分                         |
| `Deprecated`  | 已废弃                     | 模块被移除或替代                                       | -                                                      |

> **主态与描述性后缀**：上表六态为**主态**。主态可与描述性后缀组合以表达过渡情形，合法形式见 [`DEFINITION-OF-READY.md` §Status 合法值](./DEFINITION-OF-READY.md#status-合法值)。常见后缀组合：
> - `Spec Approved / Tasks Pending` — 规格层 Approved、实施层未启动（Approved 子态）
> - `Docs Baseline Approved / Runtime Pending` — 文档基线 Approved、运行时未启动
> - `Approved (Docs Baseline Synced / Runtime Truth Verified)` — 文档与 runtime 双向同步
> - `Approved (contract-corrected)` — 历史 contract 修正后批准
> - `Implemented Locally` — 本地实现版本
>
> **判定规则**：spec-lint 按 `Approved → Review → Draft → Implemented → Changed → Deprecated` 顺序抽取首个匹配关键词作为 `status_main`，用于 AC 必填等门禁判断。后缀不影响主态判定。

---

## 2. 状态流转图

```text
Draft -> Review -> Approved -> Implemented
           ^          |              |
           |          v              v
           +------- Changed <--------+

Deprecated is terminal.
```

**合法流转**：

| 当前状态    | 允许流转到  | 触发条件                                                                     |
| ----------- | ----------- | ---------------------------------------------------------------------------- |
| Draft       | Review      | Spec 内容完整，进入 Spec 结构评分                                            |
| Review      | Approved    | 四源评分齐全，`pipeline-arbiter` gate=pass                                   |
| Review      | Draft       | gate=fail 且需要重写基础需求                                                 |
| Approved    | Implemented | `module/{module}/TRACEABILITY.md` 所有 FR 标记 `Done` / `✅`，且 DoD 证据齐全 |
| Approved    | Changed     | 修改 spec 行为语义                                                           |
| Implemented | Changed     | 修改 spec 内容（需求变更）                                                   |
| Changed     | Review      | 变更提交四源评分                                                             |
| Changed     | Approved    | 仅 PATCH 格式或元数据修正且不改变 FR/BR/AC/TC 语义                           |
| Any         | Deprecated  | 模块被正式废弃                                                               |

**禁止流转**：

- `Draft` -> `Implemented`（跳过 Spec gate）
- `Review` -> `Implemented`（跳过开发与验收）
- `Implemented` -> `Draft`（已实现不可回退为草稿）
- `Deprecated` -> 任何活跃状态（废弃不可逆，需新建）
- `Approved` / `Implemented` 的语义变更继续停留在原状态

---

## 3. Metadata 节规范

每个 `module/*/SPEC.md` 的 Metadata 节必须包含：

```markdown
## 1. Metadata

- Status: Draft | Review | Approved | Implemented | Changed | Deprecated
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-09
- Owner: ZoneCNH
- Layer: L1 存储扩展
- Version: v0.7.3
- Repository: [github.com/ZoneCNH/xxx](https://github.com/ZoneCNH/xxx)
```

| 字段           | 说明                                      |
| -------------- | ----------------------------------------- |
| `Status`       | 规格生命周期状态（本文件定义的六态之一，可附描述性后缀，见 §1）  |
| `Spec-Version` | 规格文档自身版本号，与代码 `Version` 解耦 |
| `Last-Updated` | 规格最后一次修改日期                      |
| `Owner`        | 规格负责人                                |
| `Layer`        | 架构层级或模块域                          |
| `Version`      | 模块代码版本号                            |
| `Repository`   | 模块仓库链接                              |

---

## 4. 变更分类

沿用 `CONSTITUTION.md` 第十条的变更分类：

| 分类   | 影响                                | 示例                        | 生命周期要求                                                   |
| ------ | ----------------------------------- | --------------------------- | -------------------------------------------------------------- |
| PATCH  | 格式修正、错别字、非语义元数据      | 修复表格格式、更新时间      | 不重置状态；若触及受保护治理文件，仍按第十四条执行             |
| MINOR  | 新增 FR/BR、修改 AC/TC、补充 NFR    | 新增 `FR-010`               | `Approved` / `Implemented` 必须转 `Changed` 并重新跑 Spec gate |
| MAJOR  | 删除 FR、修改接口签名、改变设计原则 | 删除 `FR-003`、修改公共 API | 必须转 `Changed`，重新跑四源评分，并重新同步 Matrix/Tasks      |

**状态重置规则**：

- PATCH 变更：不改变生命周期状态，除非修改了 FR/BR/AC/TC 语义。
- MINOR 变更：`Approved` / `Implemented` -> `Changed`。
- MAJOR 变更：`Approved` / `Implemented` -> `Changed`，且必须重新执行 Spec -> Matrix -> Tasks 的受影响阶段。
- `docs/governance/`、`CONSTITUTION.md`、CI gate、scoring rubric 等受保护文件变更，必须额外遵守 `CONSTITUTION.md` 第十四条。

---

## 5. CI 与 Arbiter 集成

### 5.1 状态校验

Spec lint 和 rule scorer 至少校验：

- `Status` 值必须包含六态关键词之一（主态；可附描述性后缀，见 §1 与 `DEFINITION-OF-READY.md` §Status 合法值）。不接受 `Active`、`WIP` 等非标准值。
- `Spec-Version` 必须存在且格式为 `vX.Y.Z`。
- `Last-Updated` 必须存在且为有效日期。
- `Approved` / `Implemented` 状态的语义变更不得绕过 `Changed`。

### 5.2 流转校验

当变更修改 `module/*/SPEC.md` 时：

1. 读取 Metadata 节的当前 `Status`。
2. 判断变更是否影响 FR/BR/AC/TC、接口、设计原则或验收语义。
3. 若影响语义且当前为 `Approved` / `Implemented`，要求状态变为 `Changed`。
4. 将变更后的 Spec 提交四源评分：`claude`、`codex`、`copilot`、`rules`。
5. `pipeline-arbiter` 只有在 `composite_score >= 98`、无红线、无低置信度、LLM 分差和 rules 异构分歧均在阈值内时，才能判定 `gate=pass`。

### 5.3 自动推进

- Spec 阶段四源评分通过后，`pipeline-arbiter` 可将 `Draft` / `Review` / `Changed` 自动推进为 `Approved`。
- `module/{module}/TRACEABILITY.md` 中该模块所有 FR 标记 `Done` / `✅`，且 DoD 证据齐全后，CI 可建议将 `Approved` 推进为 `Implemented`。
- 普通模块 Spec 的 `Approved` 不依赖额外人工批准；人工批准只用于受保护治理文件、外部生产权限、凭证、依赖引入或 `CONSTITUTION.md` 明确要求的场景。

---

## 6. 操作指南

### 6.1 新建 Spec

1. 复制 `docs/governance/SPEC-TEMPLATE.md` 到 `module/{module}/SPEC.md`。
2. 填写 Metadata，设置 `Status: Draft`。
3. 完成 23 节内容和 FR/BR/AC/TC 编号。
4. 运行 Spec 阶段四源评分；arbiter pass 后进入 `Approved`。

### 6.2 修改已批准的 Spec

1. 判断变更分类：PATCH / MINOR / MAJOR。
2. PATCH 且无语义变化时，更新 `Last-Updated` 和必要说明。
3. MINOR / MAJOR 或任何语义变化时，将 `Status` 改为 `Changed`。
4. 重跑 Spec 四源评分；pass 后由 arbiter 推进为 `Approved`。
5. 同步更新 `module/{module}/TRACEABILITY.md` 和受影响 Task。

### 6.3 标记为已实现

1. 确保 `module/{module}/TRACEABILITY.md` 中该模块所有 FR 为 `Done` / `✅`。
2. 确保 `docs/governance/DEFINITION-OF-DONE.md` 要求的证据齐全。
3. 将 `SPEC.md` 的 `Status: Approved` 改为 `Status: Implemented`。
4. 运行 traceability、lint、测试和状态报告校验。

### 6.4 废弃 Spec

1. 在 `SPEC.md` 中添加废弃说明（原因、替代方案、迁移风险）。
2. 修改 `Status: *` -> `Status: Deprecated`。
3. 在 `ARCHITECTURE.md` 和 `STATUS.md` 的模块状态视图中同步标记。

---

## 7. 校验清单

变更 `SPEC.md` 时检查：

- [ ] `Status` 字段值含六态主态关键词之一（可附描述性后缀，见 §1）。
- [ ] 状态流转合法。
- [ ] `Spec-Version` 和 `Last-Updated` 已按变更分类更新。
- [ ] FR/BR/AC/TC 语义变化已进入 `Changed`。
- [ ] `module/{module}/TRACEABILITY.md` 已同步更新。
- [ ] 受影响 Task、Plan、Prompt 或证据文件已同步。
- [ ] 四源评分与 arbiter 结论已记录。
- [ ] 受保护治理文件变更已按 `CONSTITUTION.md` 第十四条处理。

---

## 相关文档

| 文档                                                                   | 用途                                                         |
| ---------------------------------------------------------------------- | ------------------------------------------------------------ |
| [`module/README.md`](../../module/README.md)                           | 模块规格体系总览                                             |
| [`docs/governance/TRACEABILITY.md`](./TRACEABILITY.md)                 | 追溯矩阵规范；具体矩阵位于 `module/{module}/TRACEABILITY.md` |
| [`docs/governance/DEVELOPMENT-WORKFLOW.md`](./DEVELOPMENT-WORKFLOW.md) | Spec -> Code 管线                                            |
| [`docs/governance/DEFINITION-OF-READY.md`](./DEFINITION-OF-READY.md)   | 进入开发的前置条件                                           |
| [`docs/governance/DEFINITION-OF-DONE.md`](./DEFINITION-OF-DONE.md)     | 实现完成的验收条件                                           |
| [`CONSTITUTION.md`](../../CONSTITUTION.md)                             | 变更管理与受保护文件规则                                     |
