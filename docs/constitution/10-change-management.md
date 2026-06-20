> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](09-security.md) · [↑ 目录](README.md) · [下一节 →](11-code-review.md)

---

## 第十条：变更管理

### 10.1 变更分类

| 分类   | 定义                         | 审批要求                        |
| ------ | ---------------------------- | ------------------------------- |
| PATCH  | Bug 修复、文档更新、测试补充 | 1 人审批                        |
| MINOR  | 新增功能、新增接口方法       | 1 人审批 + SPEC 更新            |
| MAJOR  | 接口签名变更、DTO 结构变更   | 2 人审批 + 迁移方案 + 版本 bump |

### 10.2 Breaking Change 定义

以下变更视为 breaking change：

- 删除或重命名公共接口方法
- 修改公共接口方法签名
- 删除或重命名公共结构体字段
- 修改公共结构体字段类型
- 删除公共常量或错误变量
- 修改事件 Topic 名称
- 修改配置 schema 的必填字段

### 10.3 Breaking Change 流程

```text
1. 在 SPEC.md 中标记为 DEPRECATED
2. 提供迁移指南
3. 保留至少一个 MINOR 版本周期
4. 下一个 MAJOR 版本中移除
```text

### 10.4 版本号规则

遵循 Semantic Versioning：

```text
v<MAJOR>.<MINOR>.<PATCH>

v0.x.x  — 初始开发，API 不稳定
v1.0.0  — 首个稳定 API 承诺
```text

---
