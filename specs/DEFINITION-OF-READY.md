# Definition of Ready

> 一个 spec 可以进入开发的前置条件。

最后更新：2026-06-07

---

## 检查清单

一个 spec 可以进入开发，必须满足以下所有条件：

### 清晰性

- [ ] Summary 一句话能说清模块职责
- [ ] 无模糊词（"快速"、"简单"、"好看"等），或已有量化说明
- [ ] Goals 明确且可衡量

### 范围

- [ ] Goals 明确列出
- [ ] Non-goals 明确列出
- [ ] Consumers 明确列出（谁会用这个模块）

### 功能

- [ ] 每个 Functional Requirement 有编号（FR-xxx）
- [ ] 每个 FR 使用 WHEN/THEN 格式
- [ ] 覆盖正常路径和失败路径
- [ ] Business Rules 有编号（BR-xxx）

### 数据

- [ ] 数据模型已定义（类型、字段、默认值）
- [ ] 公共错误已定义
- [ ] 配置 schema 已定义

### 边界

- [ ] Edge Cases 已列出
- [ ] 空值/零值处理已说明
- [ ] 并发场景已说明
- [ ] 超时/取消场景已说明

### 安全

- [ ] 安全要求已列出
- [ ] 敏感数据处理已说明

### 测试

- [ ] 每个核心 FR 有对应 TC
- [ ] 每个 AC 可验证
- [ ] 测试策略已说明

### 开发

- [ ] 目录结构已定义
- [ ] 依赖约束已定义
- [ ] CI Gate 已定义
- [ ] Performance Budget 已定义
- [ ] 没有 Blocking 级 Open Questions

### 交叉检查

- [ ] 相关 Technical Spec 已存在（ARCHITECTURE.md）
- [ ] 不与其他 spec 冲突
- [ ] 符合 CONSTITUTION.md 的设计原则

---

## 判断标准

```text
如果一个需求不能被测试，它还不是合格需求。
如果一个需求没有边界，它会被 AI 自由发挥。
如果一个需求没有 Non-goals，AI 很容易做多。
如果一个 spec 有 Blocking Open Questions，它还不能进入开发。
```

---

## 例外

以下情况可以降低标准：
- **Bug 修复**：只需 FR + AC + TC
- **文档更新**：无需 FR/AC/TC
- **重构**：只需 AC（行为不变）+ TC（现有测试通过）
