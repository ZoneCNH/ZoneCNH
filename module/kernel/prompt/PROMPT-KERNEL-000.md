# TASK-KERNEL-000 开发 Prompt

> 项目骨架：go.mod、Makefile、README.md、LICENSE
>
> 上游 Task：[TASK-KERNEL-000.md](../tasks/TASK-KERNEL-000.md)
> 追溯矩阵：[TRACEABILITY.md](../TRACEABILITY.md)
> 实现计划：[IMPLEMENTATION-PLAN.md](../IMPLEMENTATION-PLAN.md) §2 Phase 1

---

## 任务

创建 kernel 仓库的项目骨架。这是 kernel 实现的起点，阻塞所有后续 Task。kernel 是 stdlib-only 的 L0 原语层，go.mod 不得包含任何 require 块。

## 关联需求

| 类型 | 编号 | 出处 | 说明 |
|------|------|------|------|
| § | 14 | SPEC.md | 目录结构 |
| § | 15.1 | SPEC.md | go.mod stdlib-only |
| BR | BR-009 | SPEC.md §8 | 零外部依赖 |

## 文件清单

### 1. `go.mod`

```text
module github.com/ZoneCNH/kernel

go 1.23
```

- 无 `require` 块
- 无 `replace` 指令

### 2. `Makefile`

包含以下目标：

| 目标 | 命令 |
|------|------|
| `build` | `go build ./...` |
| `test` | `go test -race -count=1 ./...` |
| `cover` | `go test -race -coverprofile=coverage.out ./... && go tool cover -func=coverage.out` |
| `bench` | `go test -bench=. -benchmem -count=3 ./...` |
| `lint` | `golangci-lint run` |
| `vet` | `go vet ./...` |
| `check-stdlib` | `go list -deps ./... \| grep -v "^std" \| grep -v "^github.com/ZoneCNH/kernel$$"` |
| `tidy` | `go mod tidy && git diff --exit-code go.mod go.sum` |
| `release-preflight` | `build + test + cover + bench + lint + vet + check-stdlib + tidy` |

### 3. `README.md`

内容结构：
- 模块定位：Foundation L0 原语层，12 子包轻量工具集，stdlib-only
- 12 子包清单及各自用途
- 快速开始：`go get github.com/ZoneCNH/kernel`
- 验证命令：`go build ./...` / `go test -race ./...`
- 许可证信息

### 4. `LICENSE`

MIT License，版权归属 ZoneCNH。

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-SKEL-01 | §15.1 | `cat go.mod` | module github.com/ZoneCNH/kernel，go 1.23，无 require |
| AC-SKEL-02 | §14 | `make help 2>/dev/null \|\| cat Makefile` | build/test/cover/bench/lint/vet/check-stdlib 目标存在 |
| AC-SKEL-03 | §2 | `cat README.md` | 含模块定位、12 子包清单、快速开始 |
| AC-SKEL-04 | — | `go build ./...` | 编译通过 |
| AC-SKEL-05 | BR-009 | `go list -deps ./...` | 无外部依赖 |

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go build ./...` | 编译通过 |
| `go list -deps ./...` | 无 kernel 外部依赖 |
| `grep -c "module github.com/ZoneCNH/kernel" go.mod` | = 1 |

## 禁止事项

- 不要在 go.mod 中添加 require 块
- 不要在 README.md 中包含未实现的子包
- 不要包含测试密钥或个人环境路径
- 不要引入 Makefile 的远程脚本依赖

## 证据回填

完成后提交以下产物到 `docs/evidence/2026-06-12/TASK-KERNEL-000/`：

1. `go build ./...` 输出（编译通过）
2. `go list -deps ./...` 输出（无外部依赖）
3. `cat go.mod` 输出
4. `make` 或 `cat Makefile` 输出
5. 新建文件清单（路径 + 行数）

## 完成后

1. 运行全部验证命令确认通过
2. 将证据产物写入指定目录
3. 更新 TASK-KERNEL-000 状态为 completed
4. 后续 TASK-KERNEL-001~013 可并行启动
