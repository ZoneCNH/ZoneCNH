# xlib-harness Goal

> Goal-Version: v1.2.0
> Last-Updated: 2026-06-19
> Module-State: 已发布
> Release-Version: v0.1.2
> Implementation-Baseline: `/home/xlib-harness@aa83306685a9`

## 背景

Foundation 20 模块需要一个独立的最小合规脚手架与验收门禁，用于在尚未接入完整业务代码前先建立统一的规格、追踪矩阵、任务拆分、验收文档和 CI/CD 边界。

`xlib-harness` 的目标不是业务库，而是一个标准库依赖的 harness 工具。它生成模块级规格资产，并对这些资产执行规格结构、追踪闭环、运行时依赖边界、Markdown 格式和 CI/CD 引用门禁。

## 业务目标

1. 生成标准模块文档集合：`README.md`、`SPEC.md`、`TRACEABILITY.md`、`IMPLEMENTATION-PLAN.md`、`ACCEPTANCE.md`、`FEATURES.md`。
2. 提供可脚本化 CLI：`xlib-harness generate` 与 `xlib-harness check`。
3. 保证 harness 自身不依赖业务模块或横切库，运行时只使用 Go 标准库。
4. 让 compliant fixture 通过完整门禁，让 broken fixture 稳定失败。
5. 让工具自身达到 100% Go 覆盖率，并纳入 `make ci` 与 GitHub Actions。

## 成功标准

| ID | 标准 | 验收方式 | 状态 |
| --- | --- | --- | --- |
| G-001 | 生成 6 个模块文档资产 | `go run . generate /tmp/xlib-harness-smoke --force` | PASS |
| G-002 | 规格门禁覆盖 23 节结构、FR/AC/TC 可验证性 | `go run . check fixtures/compliant-module --profile spec` | PASS |
| G-003 | 边界门禁禁止 `observex`、`configx`、`resiliencx`、`schedulex`、`testkitx`、`xlib-standard` 运行时引用 | `go run . check fixtures/bad-dependency --profile boundary` 预期失败 | PASS |
| G-004 | 追踪矩阵门禁能发现未闭合 FR/AC/TC | `go run . check fixtures/broken-trace --profile full` 预期失败 | PASS |
| G-005 | harness 自身质量门禁完整通过 | `make ci` | PASS |
| G-006 | Go 覆盖率达到 100% | `go test ./... -coverprofile=coverage.out -covermode=count && go tool cover -func=coverage.out` | PASS |

## 范围

### In Scope

- CLI 参数解析、文本输出和 JSON 输出。
- 文档生成模板。
- 规格、追踪、边界、格式、CI/CD 引用检查。
- compliant、bad-dependency、broken-trace fixture。
- Makefile 与 GitHub Actions CI/CD 配置。
- 根仓库 `module/xlib-harness` 的 Spec、Traceability、Task、Acceptance、Features 投影。

### Out of Scope

- 业务模块实现。
- 远端发布推送或 GitHub Release 人工审批。
- 引入第三方 CLI 依赖作为 harness 运行时依赖。
- 替代 `xlibgate` 的外部信任门禁。

## 当前证据

- `/home/xlib-harness@aa83306685a9`
- 本地 release tag：`v0.1.2`
- `make ci`：PASS
- `go test ./...`：PASS
- `go test ./... -race -count=1`：PASS
- `go vet ./...`：PASS
- `go test ./... -coverprofile=coverage.out -covermode=count && go tool cover -func=coverage.out`：PASS，total 100.0%
- `go test -bench=. ./...`：PASS
- `git diff --check`：PASS
