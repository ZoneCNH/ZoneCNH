> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](05-testing-standards.md) · [↑ 目录](README.md) · [下一节 →](07-naming-conventions.md)

---

## 第六条：可观测性

### 6.1 Metrics 命名规范

```text
foundationx_<module>_<operation>_<measure>
```text

| 部分          | 说明     | 示例                         |
| ------------- | -------- | ---------------------------- |
| `foundationx` | 固定前缀 | `foundationx`                |
| `<module>`    | 模块名   | `redisx`                     |
| `<operation>` | 操作名   | `get`, `set`, `query`        |
| `<measure>`   | 度量类型 | `duration`, `errors`, `size` |

### 6.2 必需的可观测输出

| 类型   | 每个模块必须提供                           |
| ------ | ------------------------------------------ |
| metric | 操作耗时（histogram）、错误计数（counter） |
| log    | 连接成功/失败、关键状态变更                |
| health | 健康检查接口实现                           |

### 6.3 Label Policy

- 不得将高基数字段（如 request ID、user ID）作为 metric label
- 必须使用 `observex` 定义的标准 label（如 `status`, `operation`）
- 自定义 label 必须在 SPEC.md 中声明

### 6.4 Redaction

- 日志中不得出现敏感数据明文
- 必须使用 `observex.Redactor` 处理 API key、token、密码
- 配置值中的敏感字段必须标记为 `sensitive`

---
