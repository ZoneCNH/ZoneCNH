# PROMPT-TESTKITX-001

> FakeConfig 实现

```yaml
prompt_id: PROMPT-TESTKITX-001
task_ref: TASK-TESTKITX-001
spec_ref:
  - "module/testkitx/SPEC.md#FR-001 (FakeConfig)"
  - "module/testkitx/SPEC.md#9.1 (Fake 接口契约)"
  - "module/testkitx/SPEC.md#BR-001 (编译期接口检查)"
  - "module/testkitx/SPEC.md#BR-002 (确定性行为)"
  - "module/testkitx/SPEC.md#TC-001 (FakeConfig 类型安全)"
matrix_ref:
  - "module/testkitx/TRACEABILITY.md"
task_files:
  - "fake_config.go"
  - "fake_config_test.go"
depends_on:
  - "TASK-TESTKITX-000"
```

---

## 任务

实现 FakeConfig —— 基于内存 `map[string]any` 的配置源，实现 `configx.Reader` 接口，支持测试中注入配置值。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-001 | SPEC.md §7 | FakeConfig：内存配置源，Get(key) 返回值 |
| BR | BR-001 | SPEC.md §8 | 编译期接口检查：`var _ configx.Reader = (*FakeConfigImpl)(nil)` |
| BR | BR-002 | SPEC.md §8 | 行为确定性，不引入 `time.Now()` 或 `math.Rand()` |
| TC | TC-001 | SPEC.md §16.4 | FakeConfig 类型安全 |

## 接口契约

必须实现 `configx.Reader` 接口（参考 configx 模块定义）：

```go
type Reader interface {
    Get(key string) any
    GetString(key string) string
    GetInt(key string) int
    GetBool(key string) bool
    GetFloat64(key string) float64
    GetDuration(key string) time.Duration
    // ... 及其他 configx.Reader 方法
}
```

构造签名：

```go
func FakeConfig(values map[string]any) (*FakeConfigImpl, configx.Reader)
```

## 文件清单

### 1. `fake_config.go`

实现要点：
- 内部使用 `map[string]any` 存储配置值
- `sync.RWMutex` 保护并发访问
- 构造时接受 `map[string]any`，可选 nil（所有 Get 返回零值）
- 所有 `Get*` 方法并发安全
- `Set(key string, value any)` 方法支持运行时注入
- 无 `time.Now()` 或无 `math.Rand()` 调用
- 编译期断言行：`var _ configx.Reader = (*FakeConfigImpl)(nil)`

行为规范（来自 SPEC FR-001）：

```gherkin
WHEN 调用 FakeConfig(values) 创建配置
THEN 返回 configx.Reader，Get(key) 返回对应值

WHEN 调用 FakeConfig(values) 且 key 不存在
THEN 返回 nil（或对应类型的零值）
```

边界场景：
- `values` 为 nil 时，所有 Get 返回零值
- 并发读写不产生 data race（-race 测试通过）

### 2. `fake_config_test.go`

测试场景：

| 测试用例 | 说明 |
|----------|------|
| `TestFakeConfig_Get` | Set 后 Get 返回正确值 |
| `TestFakeConfig_GetString` | GetString 返回字符串值，非字符串返回空 |
| `TestFakeConfig_GetInt` | GetInt 返回整数值 |
| `TestFakeConfig_GetBool` | GetBool 返回布尔值 |
| `TestFakeConfig_GetFloat64` | GetFloat64 返回浮点值 |
| `TestFakeConfig_GetDuration` | GetDuration 返回 Duration 值 |
| `TestFakeConfig_KeyNotFound` | 未设置的 key 返回零值 |
| `TestFakeConfig_NilValues` | values 为 nil 时所有 Get 返回零值 |
| `TestFakeConfig_Concurrent` | 并发读写安全 |

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-FC-01 | FR-001 | `go test -run TestFakeConfig -v ./...` | 全部通过 |
| AC-FC-02 | BR-001 | `go build ./...` | 编译通过（接口断言检查） |
| AC-FC-03 | BR-002 | 代码审查 | 无 `time.Now()` / `math.Rand()` 调用 |
| AC-FC-04 | TC-001 | `go test -race -run TestFakeConfig_Concurrent ./...` | 无 data race |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -race -count=1 ./...` | 全部通过，无 data race |
| `go vet ./...` | 无警告 |
| `grep "var _ configx.Reader" fake_config.go` | 找到编译期断言 |

## 禁止事项

- 不要依赖 `time.Now()` 或 `math.Rand()`（违反 BR-002）
- 不要在 fake 中实现真正的配置加载逻辑
- 不要遗漏任何 configx.Reader 接口方法
- 不要在 Get 方法中 panic（应返回零值）
- 不要使用 `sync.Map`（使用 `sync.RWMutex` + 普通 map）

## 证据回填

完成后提交以下产物：

1. `go test -v -race ./...` 完整输出
2. `go build ./...` 输出（编译通过）
3. `grep "var _ configx.Reader" fake_config.go` 输出
4. 文件变更清单：`git diff --stat HEAD`

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入 `docs/evidence/`
3. 更新 TASK-TESTKITX-001 状态为 completed
