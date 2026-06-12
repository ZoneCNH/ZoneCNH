# TASK-TESTKITX-001 开发 Prompt

> FakeConfig 实现：内存配置源，支持测试注入
>
> 上游 Task：[TASK-TESTKITX-001.md](../tasks/TASK-TESTKITX-001.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 规格：[SPEC.md](../SPEC.md) §7 FR-001、§9.1

---

## 任务

实现 `FakeConfig`，提供内存配置源用于测试注入。实现 `configx.Reader` 接口，支持 `Set`/`Get`/`GetString`/`GetInt` 方法，并发安全。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| FR | FR-001 | SPEC.md §7 | FakeConfig：内存配置源 |
| BR | BR-001 | SPEC.md §8 | 编译期接口检查 `var _ configx.Reader = (*FakeConfigImpl)(nil)` |
| BR | BR-006 | SPEC.md §8 | 允许依赖 Foundation L1 模块（仅 go test） |
| AC | AC-001 | TRACEABILITY.md §5 | FakeConfig 实现 configx.Reader 接口 |

## 文件清单

### 1. `fake_config.go`

- `FakeConfig` 结构体：内部 `map[string]any` + `sync.RWMutex`
- `FakeConfig(values map[string]any) configx.Reader` 工厂函数
- `Set(key string, value any)` 注入配置值
- 实现 `configx.Reader` 接口：`Get`/`GetString`/`GetInt`/`GetBool`/`GetFloat64`/`GetDuration`
- 编译期接口检查：`var _ configx.Reader = (*FakeConfigImpl)(nil)`

### 2. `fake_config_test.go`

- `TestFakeConfig_SetAndGet`：Set 后 Get 返回正确值
- `TestFakeConfig_KeyNotFound`：未设置的 key 返回零值
- `TestFakeConfig_Concurrent`：并发读写无 data race
- `TestFakeConfig_NilValues`：nil values map 时所有 Get 返回零值

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-001-01 | FR-001 | `go test -run TestFakeConfig -v -count=1` | 全部通过 |
| AC-001-02 | BR-001 | `go build ./...` | 编译通过（接口断言验证） |
| AC-001-03 | FR-001 | `go test -race -run TestFakeConfig -count=1` | 无 data race |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go test -run TestFakeConfig -v -count=1` | 全部测试通过 |
| `go test -race -run TestFakeConfig -count=1` | 无 data race |

## 禁止事项

- 不要使用 `time.Now()` 或 `math.Rand()`（确定性要求，BR-002）
- 不要在 fake_config 中导入业务域模块
- 不要遗漏任何 configx.Reader 接口方法

## 证据回填

完成后提交以下产物到 `docs/evidence/TASK-TESTKITX-001/`：

1. `go build ./...` 输出
2. `go test -run TestFakeConfig -v -count=1` 输出
3. `go test -race -run TestFakeConfig -count=1` 输出
4. 新建文件清单（路径 + 行数）

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入指定目录
3. 更新 TASK-TESTKITX-001 状态为 completed
