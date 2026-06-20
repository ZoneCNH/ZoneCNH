> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](07-naming-conventions.md) · [↑ 目录](README.md) · [下一节 →](09-security.md)

---

## 第八条：错误处理

### 8.1 错误定义

```go
// 模块级哨兵错误
var ErrNotFound = errors.New("redisx: key not found")
var ErrConnectionClosed = errors.New("redisx: connection closed")

// 错误包装
if err != nil {
    return fmt.Errorf("redisx: get %q: %w", key, err)
}
```text

### 8.2 错误规则

| 规则         | 说明                           |
| ------------ | ------------------------------ |
| 哨兵错误     | 可编程处理的错误定义为包级变量 |
| 错误包装     | 使用 `%w` 包装底层错误，保留链 |
| 错误消息格式 | `"module: operation context"`  |
| 不要静默吞掉 | 所有错误必须显式处理或向上传播 |
| 不要 panic   | 除非不可恢复的初始化失败       |

### 8.3 错误分类

| 分类     | 处理方式                      | 示例         |
| -------- | ----------------------------- | ------------ |
| 可重试   | 返回错误 + `Retryable()` 方法 | 网络超时     |
| 不可重试 | 直接返回错误                  | 参数校验失败 |
| 致命     | 返回错误 + 日志 fatal         | 配置不可用   |

---
