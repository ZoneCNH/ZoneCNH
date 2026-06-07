# Spec 生命周期

> 定义 `specs/*/SPEC.md` 的状态流转规则。

最后更新：2026-06-07

---

## 1. 状态定义

| 状态 | 含义 | 进入条件 | 退出条件 |
|------|------|----------|----------|
| `Draft` | 草稿，正在编写 | 新建 SPEC.md | 提交 Review |
| `Review` | 审查中 | 提交 PR 修改 SPEC.md | Reviewer 批准 |
| `Approved` | 已批准，可进入开发 | PR 合并且 Reviewer 通过 | 开发者开始实现 |
| `Implemented` | 已实现 | 追溯矩阵中所有 FR 标记 `✅` | - |
| `Changed` | 已批准的规格被修改 | PR 修改 Approved 状态的 SPEC.md | 重新走 Review |
| `Deprecated` | 已废弃 | 模块被移除或替代 | - |

---

## 2. 状态流转图

```text
          ┌──────────────────────────────────────────┐
          │                                          │
          ▼                                          │
       Draft ──→ Review ──→ Approved ──→ Implemented │
                  ▲   │                    │         │
                  │   │                    │         │
                  │   └──→ Changed ────────┘         │
                  │         │                        │
                  └─────────┘                        │
                                                     │
                Deprecated ◄─────────────────────────┘
```

**合法流转**：

| 当前状态 | 允许流转到 | 触发条件 |
|----------|-----------|----------|
| Draft | Review | 提交 PR，spec 内容完整 |
| Review | Approved | Reviewer 批准 PR |
| Review | Draft | Reviewer 要求重大修改 |
| Approved | Implemented | 追溯矩阵所有 FR 标记 `✅` |
| Approved | Changed | PR 修改 spec 内容 |
| Implemented | Changed | PR 修改 spec 内容（需求变更） |
| Changed | Review | 提交 PR 重新审查 |
| Changed | Approved | 变更仅影响非行为节（Metadata、格式） |
| Any | Deprecated | 模块被正式废弃 |

**禁止流转**：

- `Draft` → `Implemented`（跳过审查）
- `Implemented` → `Draft`（已实现不可回退为草稿）
- `Deprecated` → 任何活跃状态（废弃不可逆，需新建）

---

## 3. Metadata 节规范

每个 `specs/*/SPEC.md` 的 Metadata 节必须包含：

```markdown
## 1. Metadata

- Status: Draft | Review | Approved | Implemented | Changed | Deprecated
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-07
- Owner: ZoneCNH
- Layer: L1 存储扩展
- Version: v0.7.3
- Repository: [github.com/ZoneCNH/xxx](https://github.com/ZoneCNH/xxx)
```

| 字段 | 说明 |
|------|------|
| `Status` | 规格生命周期状态（本文件定义的六态之一） |
| `Spec-Version` | 规格文档自身的版本号，与代码 Version 解耦 |
| `Last-Updated` | 规格最后一次修改日期 |
| `Owner` | 规格负责人 |
| `Layer` | 架构层级（基座 / 数据域 / 分析域 / 决策域 / 执行域） |
| `Version` | 模块代码版本号 |
| `Repository` | 模块仓库链接 |

---

## 4. 变更分类

沿用 CONSTITUTION.md 第十条的变更分类：

| 分类 | 影响 | 示例 | 审批要求 |
|------|------|------|----------|
| PATCH | 格式修正、错别字、注释 | 修复 WHEN/THEN 格式 | 1 人 Review |
| MINOR | 新增 FR/BR、修改 AC | 新增 FR-010 | 1 人 Review |
| MAJOR | 删除 FR、修改接口签名、改变设计原则 | 删除 FR-003、修改接口返回值 | 2 人 Review |

**状态重置规则**：

- PATCH 变更：不重置状态
- MINOR 变更：`Implemented` → `Changed`
- MAJOR 变更：`Implemented` → `Changed`，且必须重新走 Review

---

## 5. CI 集成

### 5.1 状态校验

`spec-lint.sh` 已校验 Metadata 节存在。扩展校验规则：

- Status 值必须是六态之一（不接受 `Active`、`WIP` 等非标准值）
- `Spec-Version` 必须存在且格式为 `vX.Y.Z`
- `Last-Updated` 必须存在且为有效日期

### 5.2 流转校验

当 PR 修改 `specs/*/SPEC.md` 时：

1. **检测当前状态**：读取 Metadata 节的 `Status` 字段
2. **校验流转合法性**：当前状态是否允许被修改
3. **自动建议状态**：
   - 如果当前是 `Approved` 且被修改 → 建议改为 `Changed`
   - 如果当前是 `Implemented` 且被修改 → 建议改为 `Changed`
4. **阻断非法流转**：如 `Draft` → `Implemented`

### 5.3 自动推进

- 追溯矩阵中某模块所有 FR 标记 `✅` → CI 建议将 SPEC.md Status 推进为 `Implemented`
- PR 合并后 Status 为 `Review` → CI 建议推进为 `Approved`（需人工确认）

---

## 6. 操作指南

### 6.1 新建 Spec

1. 复制 `specs/SPEC-TEMPLATE.md`
2. 填写 Metadata，设置 `Status: Draft`
3. 完成 23 节内容
4. 提交 PR → 自动进入 `Review`

### 6.2 修改已批准的 Spec

1. 在 PR 中修改 SPEC.md
2. CI 检测到 `Approved` 状态的 spec 被修改
3. 自动将 Status 重置为 `Changed`（或由作者手动修改）
4. PR 合并后重新进入 `Review`

### 6.3 标记为已实现

1. 确保追溯矩阵中该模块所有 FR 标记为 `✅`
2. 修改 SPEC.md 的 `Status: Approved` → `Status: Implemented`
3. 提交 PR，CI 验证追溯矩阵状态

### 6.4 废弃 Spec

1. 在 SPEC.md 中添加废弃说明（为什么废弃、替代方案）
2. 修改 `Status: *` → `Status: Deprecated`
3. 在 ARCHITECTURE.md 状态表中标记模块为 `deprecated`

---

## 7. 校验清单

变更 SPEC.md 时的检查清单：

- [ ] Status 字段值在六态之内
- [ ] Status 流转合法（参照第 2 节流转表）
- [ ] Spec-Version 已更新（MINOR/MAJOR 变更时）
- [ ] Last-Updated 已更新
- [ ] PATCH/MINOR/MAJOR 分类正确
- [ ] MAJOR 变更有 2 人审批
- [ ] 追溯矩阵同步更新（新增/修改 FR 时）

---

## 相关文档

| 文档 | 用途 |
|------|------|
| [`specs/README.md`](./README.md) | 规格体系总览 |
| [`specs/TRACEABILITY.md`](./TRACEABILITY.md) | 追溯矩阵 |
| [`specs/DEFINITION-OF-READY.md`](./DEFINITION-OF-READY.md) | 进入开发的前置条件 |
| [`specs/DEFINITION-OF-DONE.md`](./DEFINITION-OF-DONE.md) | 实现完成的验收条件 |
| [`CONSTITUTION.md`](../CONSTITUTION.md) | 第十条：变更管理 |
