# Test Strategy: FoundationX

> Foundation 模块的测试策略和验证方法。

最后更新：2026-06-07
Status: Approved

---

## 1. 测试金字塔

```text
         ┌─────────────┐
         │  E2E / 集成   │  少量，验证模块协作
         ├─────────────┤
         │   单元测试     │  大量，验证单模块行为
         └─────────────┘
```

Foundation 模块是基础设施层，不涉及 UI，因此测试重点在：
- **单元测试**：每个模块的公共接口、错误处理、边界场景
- **集成测试**：模块间通过接口协作（如 kernel + configx）
- **Benchmark**：性能预算验证

---

## 2. 测试要求

### 2.1 覆盖率

| 指标 | 目标 |
|------|------|
| 单元测试覆盖率 | ≥ 80% |
| 公共接口覆盖率 | 100%（每个公共方法至少 1 个测试） |
| 错误路径覆盖率 | 100%（每个公共错误至少 1 个测试） |
| Edge Case 覆盖率 | ≥ 80%（spec 中列出的 Edge Cases） |

### 2.2 测试格式

所有测试使用 **Given/When/Then** 格式，与 spec 中的 TC 编号对应：

```go
// TC-001: 正常启动和停止
// Given 注册模块 A（无依赖）
// When 调用 Run
// Then A.Init 被调用，然后 A.Start 被调用
func TestApp_Run_TC001(t *testing.T) {
    // Arrange
    app := kernel.New()
    m := &mockModule{name: "A"}
    app.Register(m)

    // Act
    err := app.Run(context.Background())

    // Assert
    require.NoError(t, err)
    assert.True(t, m.initCalled)
    assert.True(t, m.startCalled)
}
```

### 2.3 测试命名

测试函数名必须包含 TC 编号：`TestXxx_TC001`，方便追溯到 spec。

---

## 3. 测试分类

### 3.1 单元测试

每个模块必须包含：
- 公共接口的正常路径测试
- 公共接口的错误路径测试
- Edge Cases 测试（来自 spec Section 13）
- 并发安全测试（`-race` flag）
- Benchmark 测试（来自 spec Section 17）

### 3.2 集成测试

标记为 `//go:build integration`，验证：
- 模块间通过接口协作的正确性
- 完整的启动-运行-停止生命周期
- 配置加载 → 模块初始化 → 运行的完整链路

### 3.3 Benchmark 测试

每个模块必须有 benchmark，验证 spec 中的 Performance Budget：
- 关键操作的延迟目标
- 内存使用目标
- 并发性能目标

---

## 4. 测试工具

| 工具 | 用途 |
|------|------|
| `testing` (stdlib) | 基础测试框架 |
| `testkitx` | 测试专用工具：golden file、fixture、harness |
| `github.com/stretchr/testify` | assert/require（可选，不强制） |
| `go test -race` | 数据竞争检测 |
| `go test -bench` | 性能基准测试 |
| `go test -coverprofile` | 覆盖率报告 |

---

## 5. CI 集成

每个模块的 CI 必须执行：

```bash
# 1. 编译
go build ./...

# 2. 测试（含 race 检测）
go test ./... -race -count=1

# 3. 覆盖率
go test ./... -coverprofile=cover.out
go tool cover -func=cover.out

# 4. vet
go vet ./...

# 5. lint
golangci-lint run

# 6. Benchmark
go test -bench=. -benchmem -count=3 ./...
```

覆盖率 < 80% 阻塞合并。

---

## 6. Mock 策略

- **不 mock 外部依赖**：Foundation 模块通过接口解耦，使用接口的测试实现即可
- **不 mock 时间**：使用 `time.Time` 参数注入，不 mock `time.Now()`
- **不 mock I/O**：使用 `io.Reader`/`io.Writer` 接口注入
- **Mock 仅用于**：外部服务（交易所 API、消息队列）的集成测试

---

## 7. 测试数据管理

- 使用 `testdata/` 目录存放测试数据文件
- 使用 golden file 模式验证输出格式（`testkitx` 支持）
- 测试数据不包含真实凭证、API key 或账户信息
- 使用合成数据或脱敏数据

---

## 8. 测试 Review Checklist

- [ ] 每个公共方法至少 1 个测试
- [ ] 每个公共错误至少 1 个测试
- [ ] spec 中的 Edge Cases 有对应测试
- [ ] 测试使用 Given/When/Then 格式
- [ ] 测试名包含 TC 编号
- [ ] `-race` 测试通过
- [ ] 覆盖率 ≥ 80%
- [ ] Benchmark 结果符合 Performance Budget
- [ ] 测试不依赖外部服务
- [ ] 测试数据不包含敏感信息
