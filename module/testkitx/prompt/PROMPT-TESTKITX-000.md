# TASK-TESTKITX-000 开发 Prompt

> 项目骨架：go.mod、doc.go
>
> 上游 Task：[TASK-TESTKITX-000.md](../tasks/TASK-TESTKITX-000.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 规格：[SPEC.md](../SPEC.md) §15

---

## 任务

创建 testkitx 仓库的项目骨架。testkitx 是 Foundation L1 test-only 工具包，提供 fake/fixture/golden/contract/boundary 测试工具。禁止进入生产依赖图。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| § | 15 | SPEC.md | go.mod 依赖声明 |
| BR | BR-006 | SPEC.md §8 | testkitx 是唯一允许依赖所有 Foundation L1 模块的包（仅 go test） |

## 文件清单

### 1. `go.mod`

```text
module github.com/ZoneCNH/testkitx

go 1.23
```

### 2. `doc.go`

```go
// Package testkitx provides test infrastructure: fake implementations,
// fixture loading, golden file testing, contract tests, boundary scanning,
// and goroutine leak detection. This package is test-only and must never
// appear in production import graphs.
package testkitx
```

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-000-01 | §15 | `cat go.mod` | module github.com/ZoneCNH/testkitx，go 1.23 |
| AC-000-02 | §15 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 整洁 |
| AC-000-03 | — | `go build ./...` | 编译通过 |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `grep "github.com/ZoneCNH/testkitx" go.mod` | = 1 |
| `go mod tidy && git diff --exit-code go.mod go.sum` | 无变更 |

## 禁止事项

- 不要在 go.mod 中添加生产依赖的 require 块
- 不要在 doc.go 中导入任何内部包
- 不要包含测试密钥或个人环境路径

## 证据回填

完成后提交以下产物到 `docs/evidence/TASK-TESTKITX-000/`：

1. `go build ./...` 输出（编译通过）
2. `cat go.mod` 输出
3. `go mod tidy && git diff --exit-code go.mod go.sum` 输出（无变更）
4. 新建文件清单（路径 + 行数）

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入指定目录
3. 更新 TASK-TESTKITX-000 状态为 completed
4. 后续 TASK-TESTKITX-001~005 可并行启动
