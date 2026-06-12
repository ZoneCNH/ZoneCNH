# PLAN-TESTKITX-007

> GoldenUpdate + fixture loader 实现计划
>
> 对应 Task：`module/testkitx/tasks/TASK-TESTKITX-007.md`
> 对应 Spec：`module/testkitx/SPEC.md#FR-008`, `SPEC.md#9.7`, `SPEC.md#11`, `SPEC.md#13`

---

## 1. Task 摘要

```yaml
task_id: TASK-TESTKITX-007
scope: "实现 GoldenUpdate（golden file 管理）和 fixture loader（测试数据加载）"
priority: P1
estimated_effort: "1h"
depends_on: [TASK-TESTKITX-000]
blocks: [TASK-TESTKITX-010]
```

---

## 2. 覆盖需求

| 需求     | 描述                                | AC                          |
| -------- | ----------------------------------- | --------------------------- |
| FR-008   | GoldenUpdate golden file 管理       | AC-008: 环境变量控制更新    |
| BR-004   | GOLDEN_UPDATE=1 时返回 true         | GoldenUpdate() 环境变量检查 |
| BR-007   | golden 文件不泄露 secret            | gitleaks 扫描通过           |
| SPEC §13 | Edge Case: CI 中 GOLDEN_UPDATE 设置 | CI Gate 阻止                |

---

## 3. 接口契约

```go
// SPEC §9.7
func GoldenUpdate() bool // 环境变量 GOLDEN_UPDATE=1 时返回 true
```

golden file 管理函数：
```go
// GoldenAssert 比较实际输出与 golden file
func GoldenAssert(t testing.TB, name string, got []byte)

// GoldenFile 返回 golden file 路径
func GoldenFile(t testing.TB, name string) string
```

fixture loader：
```go
// LoadFixture 从 testdata/ 加载 JSON fixture
func LoadFixture(t testing.TB, name string, v any)

// LoadGolden 从 testdata/ 加载 golden file 内容
func LoadGolden(t testing.TB, name string) []byte
```

---

## 4. 实现步骤

### Step 1: 实现 GoldenUpdate

**目标文件**：`golden.go`

**实现要点**：
- `GoldenUpdate() bool`：检查 `os.Getenv("GOLDEN_UPDATE") == "1"`
- `GoldenAssert(t testing.TB, name string, got []byte)`：
  - 读取 `testdata/<name>.golden`
  - 如果文件不存在且 GoldenUpdate() 为 true，写入 got
  - 如果文件存在且 GoldenUpdate() 为 true，覆盖写入
  - 如果文件存在且 GoldenUpdate() 为 false，比较内容，不一致则 `t.Errorf`
- **Secret 检查**：更新 golden 文件时，扫描常见 secret 模式（API key、token、private key 格式）

### Step 2: 实现 fixture loader

**目标文件**：`fixture.go`

**实现要点**：
- `LoadFixture(t testing.TB, name string, v any)`：从 `testdata/<name>.json` 解析 JSON 到 v
- `LoadGolden(t testing.TB, name string) []byte`：从 `testdata/<name>.golden` 读取原始内容
- 文件不存在时 `t.Fatalf` 给出清晰错误

### Step 3: 实现 hash helper

**目标文件**：`hash.go`

**实现要点**：
- `Hash(t testing.TB, data []byte) string`：计算 SHA256 哈希
- 用于 contract fingerprint 测试

### Step 4: 编写单元测试

**目标文件**：`golden_test.go`

**测试用例**：

| 用例                         | 描述                  | 验证点                    |
| ---------------------------- | --------------------- | ------------------------- |
| TestGoldenUpdate_EnvSet      | GOLDEN_UPDATE=1       | GoldenUpdate() 返回 true  |
| TestGoldenUpdate_EnvUnset    | GOLDEN_UPDATE 未设置  | GoldenUpdate() 返回 false |
| TestGoldenAssert_Match       | 内容匹配              | 无错误                    |
| TestGoldenAssert_Mismatch    | 内容不匹配            | t.Errorf 被调用           |
| TestGoldenAssert_UpdateMode  | 更新模式              | 文件被更新                |
| TestGoldenAssert_NewFile     | 文件不存在 + 更新模式 | 文件被创建                |
| TestLoadFixture_ValidJSON    | 有效 JSON             | 正确解析到结构体          |
| TestLoadFixture_FileNotFound | 文件不存在            | t.Fatal                   |

**测试数据**：在 `testdata/` 下创建 `.golden` 和 `.json` fixture 文件。

---

## 5. 验证汇总

```bash
go build ./...
GOLDEN_UPDATE=1 go test -run TestGolden -race -count=1 -v ./...
go test -run TestGolden -race -count=1 -v ./...  # 默认模式（不更新）
go test -run TestLoadFixture -race -count=1 -v ./...
gitleaks detect --no-git  # 验证 golden 文件无 secret
```

**通过标准**：编译通过 + 全部测试通过 + gitleaks 扫描通过。

---

## 6. 风险与回滚

| 风险                           | 概率   | 影响   | 缓解                              | 回滚                      |
| ------------------------------ | ------ | ------ | --------------------------------- | ------------------------- |
| golden file 路径错误           | Low    | Low    | 使用 `t.Name()` 生成确定性路径    | 修正路径                  |
| GOLDEN_UPDATE 在 CI 中意外设置 | Low    | High   | CI Gate 检查环境变量              | 在 CI 配置中显式 unset    |
| golden 文件泄露 secret         | Low    | High   | 更新时自动检查 + gitleaks CI gate | 删除泄露文件并轮换 secret |

**回滚路径**：本 task 仅新增文件，回滚 = `rm golden.go golden_test.go fixture.go hash.go testdata/*.golden testdata/*.json`。
