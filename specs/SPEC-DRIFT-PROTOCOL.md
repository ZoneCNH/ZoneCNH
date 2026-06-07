# Spec Drift Protocol

> 代码和 Spec 不一致时的处理协议。

最后更新：2026-06-08

---

## 问题

开发中经常出现：

```text
Spec 写的是 A
实现发现 A 不合理
代码做成了 B
```

**不能默默接受。** 需求变了，Spec 也必须变。

---

## 情况 1：Spec 对，代码错

**处理方式：改代码**

```markdown
当前实现偏离 Spec。Spec 是准的。

请将代码改回符合 Spec 的行为。
不要修改 Spec。
不要实现额外功能。
```

---

## 情况 2：代码暴露了 Spec 的问题

**处理方式：先改 Spec，再改 Task，再改代码**

```markdown
当前实现发现 Spec 可能存在问题。

请不要继续写代码。

请输出：
1. Spec 中的问题
2. 为什么当前 Spec 不合理
3. 推荐的 Spec 修改
4. 修改后会影响哪些 Requirements
5. 修改后需要新增或修改哪些 Test Cases
```

---

## 情况 3：需求变了

**处理方式：开新 Spec 版本**

```markdown
## Changelog

### 1.1.0 - 2026-06-08

- Changed delete behavior from immediate delete to confirmation dialog
- Added AC-006
- Added TC-006
```

---

## 原则

```text
不要让代码偷偷改变需求。
需求变了，Spec 也必须变。
```

---

## 什么时候必须更新 Spec

以下情况**必须**更新 Spec：

- 需求变了
- 默认行为变了
- 数据模型变了
- API contract 变了
- 错误提示变了
- 权限规则变了
- 验收标准变了
- 新增边界情况
- 新增 Non-goal

以下情况**不一定**需要更新 Spec：

- 内部函数重命名
- 样式微调
- 测试文件重构
- 代码目录小调整
- 非行为性优化

### 判断标准

```text
用户可见行为变了 → 更新 Spec
接口合同变了 → 更新 Spec
数据含义变了 → 更新 Spec
安全规则变了 → 更新 Spec
```

---

## Drift 检测 Prompt

定期运行：

```markdown
请对比当前实现与 SPEC.md，找出所有不一致。

不要修改代码。

输出：
| Spec Says | Code Does | Impact | Recommended Fix |
|---|---|---|---|

分类：
- Behavior drift（行为偏差）
- Contract drift（接口偏差）
- Scope drift（范围偏差）
- Security drift（安全偏差）
```

---

## 相关文档

| 文档 | 用途 |
|------|------|
| `specs/LIFECYCLE.md` | Spec 状态流转规则 |
| `specs/DEVELOPMENT-WORKFLOW.md` | 完整管线总览 |
| `specs/CODING-SESSION-PROTOCOL.md` | 编码会话协议 |
