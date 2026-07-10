> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](03-dependency-direction.md) · [↑ 目录](README.md) · [下一节 →](05-testing-standards.md)

---

## 第四条：接口契约

### 4.1 接口定义规则

| 规则       | 说明                                            |
| ---------- | ----------------------------------------------- |
| 窄接口     | 每个接口 3-5 个方法，不超过 7 个                |
| 编译期检查 | 所有接口必须有 `var _ Interface = (*impl)(nil)` |
| godoc 注释 | 所有公共接口和方法必须有文档注释                |
| 不可变 DTO | 跨域 DTO 字段只读，不提供 setter                |
| 返回错误   | 方法签名返回 `error` 作为最后一个返回值         |

### 4.2 接口位置

| 接口类型      | 定义位置                 |
| ------------- | ------------------------ |
| 跨域端口      | `contracts/`             |
| 域内接口      | 各域内部模块             |
| 基座接口      | 各基座模块自身           |
| L2.5 领域模型 | `decimalx/`, `domain-*/` |

### 4.3 配置接口

所有可配置模块必须提供：

```go
type Config struct {
    // 字段使用 mapstructure tag
    // 提供 Validate() error 方法
    // 提供默认值
}
```text

### 4.4 行为规格（WHEN/THEN）

每个模块的 SPEC.md 必须包含行为性规格，不能只有结构性描述。

**必需的行为规格章节：**

| 章节                    | 要求                                              |
| ----------------------- | ------------------------------------------------- |
| Functional Requirements | 每个公共方法必须有 WHEN/THEN 描述                 |
| Business Rules          | 模块不变量和校验规则必须显式列出                  |
| Error Handling          | 错误分类 + 调用方处理指南（不是模块自身故障模式） |
| Acceptance Criteria     | 统一验收清单（从 CI Gate + DoD 合并）             |

**WHEN/THEN 格式：**

```text
WHEN [条件/输入]
THEN [系统行为/输出]
AND [副作用/状态变更]
```text

**示例（configx.Reader.Get）：**

```text
WHEN path 存在于已加载配置中
THEN 返回对应值和 nil error

WHEN path 不存在
THEN 返回零值和 false

WHEN path 存在但类型不匹配
THEN 返回零值和 ErrTypeMismatch
```text

**规则：**

- 每个公共导出方法至少 2 个 WHEN/THEN（正常路径 + 异常路径）
- 边界条件必须有独立的 WHEN/THEN
- 不可省略 Error Handling 章节 — 无模块特定要求时写"参见 CONSTITUTION.md 第八条"

### 4.5 跨模块通信协议

模块间通信统一使用 HTTP 协议，统一使用 [Gin](https://github.com/gin-gonic/gin) 框架。

| 规则           | 说明                                                                       |
| -------------- | -------------------------------------------------------------------------- |
| 通信协议       | 模块间通信统一使用 HTTP                                                     |
| Web 框架       | 统一使用 Gin（`github.com/gin-gonic/gin`）                                |
| 端口定义       | 跨模块 HTTP 端点须在 `contracts/` 中声明                                   |
| DTO            | 请求/响应体须为 contracts 层不可变 DTO（§4.1）                             |
| 错误映射       | HTTP 状态码须遵循 RFC 9110 语义，业务错误须通过统一错误信封返回            |

**禁止：**

- 禁止引入其他 Web 框架（Echo、Fiber、Chi、net/http 原生路由等）
- 禁止使用 gRPC、WebSocket 等非 HTTP 协议作为模块间同步通信方式（异步事件流不受此限，见 §3.1 依赖拓扑）
- 禁止在业务域模块内直接绕过 contracts 层定义 HTTP 端点

---
