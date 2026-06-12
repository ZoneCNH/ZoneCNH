# PROMPT-TESTKITX-000

> 项目骨架：go.mod、doc.go

```yaml
prompt_id: PROMPT-TESTKITX-000
task_ref: TASK-TESTKITX-000
spec_ref:
  - "module/testkitx/SPEC.md#14 (目录结构)"
  - "module/testkitx/SPEC.md#15 (go.mod 依赖声明)"
  - "module/testkitx/SPEC.md#18 (可观测性)"
  - "module/testkitx/SPEC.md#19 (安全)"
matrix_ref:
  - "module/testkitx/TRACEABILITY.md"
task_files:
  - "go.mod"
  - "doc.go"
  - "errors.go"
  - "testkitx.go"
  - "Makefile"
  - "LICENSE"
```

---

## 任务

创建 testkitx 仓库的项目骨架。testkitx 是 Foundation L1 test-only 工具包，提供 fake/fixture/golden/contract/boundary 工具。这是模块实现的起点，阻塞所有后续 Task。

核心约束：
- testkitx 是唯一允许依赖所有 Foundation L1 模块的包，但仅限 `go test` 使用
- 生产 import graph 中不能出现 testkitx
- 所有 fake 实现必须通过编译期接口检查（`var _ Interface = (*FakeImpl)(nil)`）

## 关联需求

| 类型   | 编号       | 出处       | 说明                                     |
| ------ | ---------- | ---------- | ---------------------------------------- |
| FR     | FR-001~010 | SPEC.md §7 | 全部 FR 的包级声明                       |
| BR     | BR-006     | SPEC.md §8 | testkitx 允许依赖所有 Foundation L1 模块 |
| BR     | BR-005     | SPEC.md §8 | 生产 import graph 不能出现 testkitx      |
| §      | 14         | SPEC.md    | 目录结构                                 |
| §      | 15         | SPEC.md    | 依赖声明                                 |
| §      | 18         | SPEC.md    | 不 emit 生产可观测数据                   |
| §      | 19         | SPEC.md    | 不进入生产二进制                         |

## 文件清单

### 1. `go.mod`

```text
module github.com/ZoneCNH/testkitx

go 1.23
```

- 依赖项：observex、configx、resiliencx 的接口类型（仅 test 使用）
- 无业务域实现依赖
- 无循环依赖

### 2. `doc.go`

```go
// Package testkitx provides test-only tools for Foundation modules.
//
// It includes fake implementations (FakeConfig, FakeLogger, FakeMeter,
// FakeTracer, FakeClock, FakeBreaker), test helpers (Eventually, GoldenUpdate,
// BoundaryCheck, GoroutineLeakCheck), and a contract test harness.
//
// testkitx MUST NOT appear in production import graphs.
// It is the only package allowed to import all Foundation L1 modules,
// but only for test purposes.
package testkitx
```

### 3. `errors.go`

定义公共错误哨兵：

```go
var (
    ErrBoundaryViolation = errors.New("testkitx: production dependency on testkitx")
    ErrGoroutineLeak     = errors.New("testkitx: goroutine leak detected")
    ErrGoldenMismatch    = errors.New("testkitx: golden file mismatch")
)
```

所有错误消息格式为 `"testkitx: <operation>: <detail>"`。

### 4. `testkitx.go`

顶层导出文件。当前仅声明 package，后续 Task 在此文件中导出公共 API。

### 5. `Makefile`

包含以下目标：

| 目标                | 命令                                                                                                                     |                 |   |                                    |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------ |                 |   |                                    |
| `build`             | `go build ./...`                                                                                                         |                 |   |                                    |
| `test`              | `go test -race -count=1 ./...`                                                                                           |                 |   |                                    |
| `cover`             | `mkdir -p .coverage && go test -race -coverprofile=.coverage/cover.out ./... && go tool cover -func=.coverage/cover.out` |                 |   |                                    |
| `bench`             | `go test -bench=. -benchmem -count=3 ./...`                                                                              |                 |   |                                    |
| `lint`              | `golangci-lint run`                                                                                                      |                 |   |                                    |
| `vet`               | `go vet ./...`                                                                                                           |                 |   |                                    |
| `tidy`              | `go mod tidy && git diff --exit-code go.mod go.sum`                                                                      |                 |   |                                    |
| `contract-test`     | `go test ./contract/... -race -count=1`                                                                                  |                 |   |                                    |
| `no-prod-import`    | `go list -deps github.com/ZoneCNH/x.go/... 2>/dev/null \                                                                 | grep testkitx \ | \ | echo "PASS: no production import"` |
| `release-preflight` | build + test + cover + bench + lint + vet + tidy + contract-test + no-prod-import                                        |                 |   |                                    |

### 6. `LICENSE`

MIT License，版权归属 ZoneCNH。

## 验收标准

| AC         | 关联   | 验证命令                        | 预期结果                                                                                     |                               |     |
| ---------- | ------ | ------------------------------- | -------------------------------------------------------------------------------------------- |                               |     |
| AC-SKEL-01 | §15    | `cat go.mod`                    | `module github.com/ZoneCNH/testkitx`，`go 1.23`                                              |                               |     |
| AC-SKEL-02 | §14    | `ls *.go`                       | doc.go、testkitx.go、errors.go 存在                                                          |                               |     |
| AC-SKEL-03 | §10    | `grep -c "ErrBoundaryViolation\ | ErrGoroutineLeak\                                                                            | ErrGoldenMismatch" errors.go` | = 3 |
| AC-SKEL-04 | —      | `go build ./...`                | 编译通过                                                                                     |                               |     |
| AC-SKEL-05 | §19    | `go list -m`                    | 无生产依赖                                                                                   |                               |     |
| AC-SKEL-06 | —      | `cat Makefile`                  | build/test/cover/bench/lint/vet/tidy/contract-test/no-prod-import/release-preflight 目标存在 |                               |     |

## 验证命令

| 命令                                                      | 判定标准                          |
| --------------------------------------------------------- | --------------------------------- |
| `go build ./...`                                          | 编译通过                          |
| `go mod tidy`                                             | 无变更（go.mod 和 go.sum 已最新） |
| `ls doc.go testkitx.go errors.go go.mod Makefile LICENSE` | 全部存在                          |
| `grep -c "package testkitx" doc.go`                       | = 1                               |

## 禁止事项

- 不要在 go.mod 中添加业务域依赖
- 不要引入循环依赖
- 不要在 doc.go 中写 TODO 注释（应直接完成）
- 不要包含测试密钥或个人环境路径
- 不要引入 Makefile 的远程脚本依赖
- 不要跳过 LICENSE 文件

## 证据回填

完成后提交以下产物到 `docs/evidence/`：

1. `go build ./...` 输出（编译通过）
2. `go mod tidy` 输出（无变更）
3. `cat go.mod` 输出
4. `ls -la *.go` 输出
5. 新建文件清单（路径 + 行数）

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入指定目录
3. 更新 TASK-TESTKITX-000 状态为 completed
4. 后续 TASK-TESTKITX-001~009 可并行启动
