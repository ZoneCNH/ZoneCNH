# xlib-harness Features

> Module: `xlib-harness`
> Version: v0.1.2
> Last-Updated: 2026-06-19
> Implementation-Baseline: `/home/xlib-harness@aa83306685a9`

## Feature Summary

`xlib-harness` 提供一个标准库依赖的模块脚手架与验收门禁。它生成 Foundation 模块的基础文档集合，并在本地和 CI 中检查规格结构、追踪闭环、运行时依赖边界、Markdown 格式和 CI/CD 引用。

## Functional Features

| Feature ID | Capability | CLI / Artifact | Status |
| --- | --- | --- | --- |
| FR-001 | 生成模块资产 | `xlib-harness generate <module> --force` | Implemented |
| FR-002 | 规格结构门禁 | `xlib-harness check <module> --profile spec` | Implemented |
| FR-003 | 运行时边界门禁 | `xlib-harness check <module> --profile boundary` | Implemented |
| FR-004 | CI/CD 引用门禁 | `xlib-harness check <module> --profile full` | Implemented |
| FR-005 | Markdown 格式门禁 | `xlib-harness check <module> --profile full` | Implemented |
| FR-006 | 追踪闭环门禁 | `xlib-harness check <module> --profile full` | Implemented |

## Generated Assets

| Asset | Purpose |
| --- | --- |
| `README.md` | 模块公开入口、命令摘要和状态说明 |
| `SPEC.md` | 23 节规格文档 |
| `TRACEABILITY.md` | FR/AC/TC 追踪矩阵 |
| `IMPLEMENTATION-PLAN.md` | 任务、风险和验证计划 |
| `ACCEPTANCE.md` | 验收命令和证据 |
| `FEATURES.md` | 功能清单 |

## Quality Features

| NFR ID | Capability | Evidence |
| --- | --- | --- |
| NFR-001 | 标准库运行时依赖 | `go list -deps ./...` 与边界 fixture 验证 |
| NFR-002 | JSON 输出可由自动化消费 | `xlib-harness check <module> --json \| jq .` |
| NFR-003 | fixture 可重复验收 | `make ci` |
| NFR-004 | 100% Go 覆盖率 | `go tool cover -func=coverage.out` total 100.0% |

## Task Coverage

| Task | Feature Coverage | Status |
| --- | --- | --- |
| `TASK-XLIBHARNESS-001` | CLI 生成与资产清单 | Completed |
| `TASK-XLIBHARNESS-002` | 规格结构与 23 节模板 | Completed |
| `TASK-XLIBHARNESS-003` | 运行时依赖边界门禁 | Completed |
| `TASK-XLIBHARNESS-004` | CI/CD 引用与 Makefile 门禁 | Completed |
| `TASK-XLIBHARNESS-005` | Markdown 格式门禁 | Completed |
| `TASK-XLIBHARNESS-006` | 追踪矩阵闭环门禁 | Completed |

## Release Notes

### v0.1.2

- 将 harness 提升到可发布状态，CLI、公开 API、fixture 和 CI/CD 均由 `make ci` 覆盖。
- 覆盖率门禁提升到 100.0%。
- 边界门禁解析 `go.mod` 与 Go imports，禁止 `observex`、`configx`、`resiliencx`、`schedulex`、`testkitx`、`xlib-standard` 运行时引用。
- 规格门禁覆盖 23 节结构、FR Given/When/Then、AC/TC 可验证性。
- 增加 `v0.1.2` 本地 release tag。
