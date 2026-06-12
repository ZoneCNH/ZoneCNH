# PLAN-TESTKITX-001

> FakeConfig 实现计划
>
> 对应 Task：`module/testkitx/tasks/TASK-TESTKITX-001.md`
> 对应 Spec：`module/testkitx/SPEC.md#FR-001`, `SPEC.md#9.1`, `SPEC.md#13`

---

## 1. Task 摘要

```yaml
task_id: TASK-TESTKITX-001
scope: "实现 FakeConfig，内存配置源，支持测试注入"
priority: P0
estimated_effort: "1h"
depends_on: [TASK-TESTKITX-000]
blocks: [TASK-TESTKITX-010]
```

---

## 2. 覆盖需求

| 需求 | 描述 | AC |
|------|------|-----|
| FR-001 | FakeConfig 内存配置源 | AC-001: Set 后 Get 返回注入值 |
| BR-001 | 接口编译期检查 | `var _ configx.Reader = (*FakeConfigImpl)(nil)` |
| NFR-001 | fake 初始化 < 1ms | benchmark 验证 |
| SPEC §13 | Edge Case: values 为 nil | 所有 Get 返回 nil |

---

## 3. 接口契约

```go
// SPEC §9.1
func FakeConfig(values map[string]any) configx.Reader
```

FakeConfig 必须实现 `configx.Reader` 接口的全部方法，包括但不限于：
- `Get(key string) any`
- `GetString(key string) string`
- `GetInt(key string) int`
- `GetBool(key string) bool`
- `GetFloat64(key string) float64`
- `GetDuration(key string) time.Duration`
- `GetStringSlice(key string) []string`

**实现前必须阅读** `configx` 模块的接口定义，确认完整方法列表。

---

## 4. 实现步骤

### Step 1: 实现 FakeConfig 结构体

**目标文件**：`fake_config.go`

**实现要点**：
- 内部存储：`map[string]any`（使用 `sync.RWMutex` 保护并发访问）
- 构造函数 `FakeConfig(values map[string]any) configx.Reader`
- 实现 `configx.Reader` 接口的所有方法
- 类型安全：`GetString` 对非 string 值做类型断言，失败返回零值
- 未设置的 key 返回零值（不 panic）
- 编译期接口检查：`var _ configx.Reader = (*fakeConfigImpl)(nil)`

**结构体设计**：
```go
type fakeConfigImpl struct {
    mu     sync.RWMutex
    values map[string]any
}
```

**验证**：
```bash
go build ./...
```

### Step 2: 实现并发安全

**实现要点**：
- 所有读方法使用 `RLock/RUnlock`
- `Set` 方法（如有）使用 `Lock/Unlock`
- 使用 `sync.RWMutex` 而非 `sync.Mutex`（读多写少场景优化）

### Step 3: 编写单元测试

**目标文件**：`fake_config_test.go`

**测试用例**：

| 用例 | 描述 | 验证点 |
|------|------|--------|
| TestFakeConfig_BasicGetSet | Set 后 Get 返回正确值 | `Get("symbol")` 返回 "BTCUSDT" |
| TestFakeConfig_GetString | GetString 类型转换 | GetString 返回 string，非 string 返回 "" |
| TestFakeConfig_GetInt | GetInt 类型转换 | GetInt 返回 int，非 int 返回 0 |
| TestFakeConfig_GetBool | GetBool 类型转换 | GetBool 返回 bool，非 bool 返回 false |
| TestFakeConfig_MissingKey | 未设置的 key | Get/Methods 返回零值，不 panic |
| TestFakeConfig_NilValues | values 为 nil | 所有 Get 返回 nil |
| TestFakeConfig_Concurrent | 并发读写 | `-race` 通过 |
| TestFakeConfig_InterfaceCheck | 接口实现 | 编译期已检查，测试确认所有方法可用 |

---

## 5. 验证汇总

```bash
go build ./...
go test -run TestFakeConfig -race -count=1 -v ./...
```

**通过标准**：编译通过 + 全部测试通过 + 无 data race。

---

## 6. 风险与回滚

| 风险 | 概率 | 影响 | 缓解 | 回滚 |
|------|------|------|------|------|
| configx.Reader 接口方法签名不确定 | Medium | High | 先读 configx 模块接口定义 | 修正方法签名 |
| 并发 data race | Low | High | RWMutex 保护 + `-race` CI | 加锁粒度调整 |

**回滚路径**：本 task 仅新增文件，回滚 = `rm fake_config.go fake_config_test.go`。
