> **效力声明**：本文件内容提取自 [`CONSTITUTION.md`](../../CONSTITUTION.md)（FoundationX 最高治理文件）。
> 如本文件与根目录 `CONSTITUTION.md` 有差异，以 `CONSTITUTION.md` 为准。
>
> [← 上一节](04-interface-contracts.md) · [↑ 目录](README.md) · [下一节 →](06-observability.md)

---

## 第五条：测试标准

### 5.1 覆盖率要求

| 模块类型    | 最低覆盖率   | 说明                       |
| ----------- | ------------ | -------------------------- |
| L0 (kernel) | 100%         | 原语层必须高度可靠，零遗漏 |
| L1 运行时   | 80%          | 标准覆盖率                 |
| 存储扩展    | 80%          | 单元测试 + 可选集成测试    |
| 契约        | 80%          | 含 breaking change 检测    |
| 门禁        | 80%          | 自检通过                   |

### 5.2 测试分类

| 类型     | 标签          | 运行条件       | 阻塞级别      |
| -------- | ------------- | -------------- | ------------- |
| 单元测试 | 无            | 始终运行       | 必须通过      |
| 集成测试 | `integration` | 外部服务可达时 | 不可达时 skip |
| 基准测试 | `benchmark`   | PR 附带结果    | 建议          |
| 竞态测试 | `-race`       | 始终运行       | 必须通过      |

### 5.3 测试命名

```go
func TestFunctionName_Scenario_ExpectedBehavior(t *testing.T) {
    // Arrange — 准备测试数据
    // Act      — 执行被测函数
    // Assert   — 验证结果
}
```text

### 5.4 禁止事项

- 禁止测试依赖执行顺序
- 禁止测试共享可变状态
- 禁止 sleep 等待（使用 channel 或 retry）
- 禁止测试中硬编码时间（使用 `FakeClock`）

---
