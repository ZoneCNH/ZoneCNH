# docs/standards — 编码规范索引

本目录存放 FoundationX 全系统的编码规范文档。

> **效力层级**：`CONSTITUTION.md` > 本目录规范 > 社区最佳实践。
> 当本目录文档与 `CONSTITUTION.md` 冲突时，以 `CONSTITUTION.md` 为准。

---

## 文档列表

| 文档 | 适用范围 | 说明 |
|------|---------|------|
| [go-coding-standards.md](./go-coding-standards.md) | 所有 Go 模块 | 格式化、命名、错误处理、并发、接口设计、测试等 13 个维度 |

---

## 使用说明

- 所有 Go 模块开发必须遵循 `go-coding-standards.md`。
- 文档中标注 **FoundationX 强制** 的规则来源于 `CONSTITUTION.md`，优先级最高。
- 标注 **FoundationX 补充** 的规则是项目特定扩展，与社区规范有细微差异。
- 未标注的内容为通用 Go 社区最佳实践，当项目规则无覆盖时适用。

---

## 新增规范文档

新增规范文档时需满足：

1. 与 `CONSTITUTION.md` 无冲突，或明确标注差异来源。
2. 同步更新本 `README.md` 的文档列表。
3. 通过 PR 合入，不得直接提交到 `main`。
