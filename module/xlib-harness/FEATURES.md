# xlib_harness Features

> Module: `xlib_harness`
> Version: v0.1.6
> Last-Updated: 2026-06-20
> Implementation-Baseline: `/home/xlib_harness@d90b35124701`

## Feature Summary

`xlib_harness` 提供一个标准库依赖的模块脚手架与验收门禁。它生成 Foundation 模块的基础文档集合，并在本地和 CI 中检查规格结构、追踪闭环、运行时依赖边界、Markdown 格式和 CI/CD 引用。

## Functional Features

| Feature ID | Capability | CLI / Artifact | Status |
| --- | --- | --- | --- |
| FR-001 | 生成模块资产 | `xlib_harness generate <module> --force` | Implemented |
| FR-002 | 规格结构门禁 | `xlib_harness check <module> --profile spec` | Implemented |
| FR-003 | 运行时边界门禁 | `xlib_harness check <module> --profile boundary` | Implemented |
| FR-004 | CI/CD 引用门禁 | `xlib_harness check <module> --profile full` | Implemented |
| FR-005 | Markdown 格式门禁 | `xlib_harness check <module> --profile full` | Implemented |
| FR-006 | 追踪闭环门禁 | `xlib_harness check <module> --profile full` | Implemented |

## Generated Assets

| Asset | Purpose |
| --- | --- |
| `README.md` | 模块公开入口、命令摘要和状态说明 |
| `SPEC.md` | 23 节规格文档 |
| `TRACEABILITY.md` | FR/AC/TC 追踪矩阵 |
| `goal.md` | 模块目标、范围和证据 |
| `IMPLEMENTATION-PLAN.md` | 任务、风险和验证计划 |
| `ACCEPTANCE.md` | 验收命令和证据 |
| `FEATURES.md` | 功能清单 |
| `tasks/TASK-001.md` | 首个可执行任务模板 |
| `Makefile` | 本地构建、测试、覆盖率和门禁入口 |
| `.github/workflows/ci.yml` | CI 引用 workflow |

## Quality Features

| NFR ID | Capability | Evidence |
| --- | --- | --- |
| NFR-001 | 标准库运行时依赖 | `go list -deps ./...` 与边界 fixture 验证 |
| NFR-002 | JSON 输出可由自动化消费 | `xlib_harness check <module> --json \| jq .` |
| NFR-003 | fixture 可重复验收 | `make ci` |
| NFR-004 | 100% Go 覆盖率 | `go tool cover -func=coverage.out` total 100.0% |
| NFR-005 | 发布门禁验证公开文档与免许可证 secret scan | `FEATURES.md`、`ACCEPTANCE.md`、Release run `27855366871`、main CI run `27855396013`、pinned `gitleaks` CLI |

## Task Coverage

| Task | Feature Coverage | Status |
| --- | --- | --- |
| `TASK-XLIBHARNESS-001` | CLI 生成与资产清单 | Completed |
| `TASK-XLIBHARNESS-002` | 规格结构与 23 节模板 | Completed |
| `TASK-XLIBHARNESS-003` | 运行时依赖边界门禁 | Completed |
| `TASK-XLIBHARNESS-004` | CI/CD 引用与 Makefile 门禁 | Completed |
| `TASK-XLIBHARNESS-005` | Markdown 格式门禁 | Completed |
| `TASK-XLIBHARNESS-006` | 追踪矩阵闭环门禁 | Completed |
| `TASK-XLIBHARNESS-007` | 代码仓库 `FEATURES.md`/`ACCEPTANCE.md` 与免许可证 secret scan 发布门禁 | Completed |

## Overall Score

| Dimension | Score | Evidence |
| --- | --- | --- |
| Functional coverage | 100/100 | FR-001 到 FR-006 均有 CLI、fixture 或单元测试证据 |
| Test coverage | 100/100 | `go tool cover -func=/tmp/xlib_harness-v016.cover` total 100.0%，所有函数 100.0% |
| CI/CD | 100/100 | Release run `27855366871` 与 main CI run `27855396013` 均 PASS |
| Documentation sync | 100/100 | `/home/xlib_harness` 与根仓库 `module/xlib_harness` 的 FEATURES/ACCEPTANCE/SPEC 投影已同步到 `v0.1.6` |
| Overall | 100/100 | 无已知阻断缺陷 |

## Release Notes

### v0.1.6

- 将 CI secret scan 从需要商业许可的 GitHub Action 替换为 pinned open-source CLI：`github.com/zricethezav/gitleaks/v8@v8.30.1`。
- 发布门禁和 main CI 均验证 `README.md`、`FEATURES.md`、`ACCEPTANCE.md` 与 workflow 文件存在且非空。
- 重新验收 `make ci`、race、vet、coverage、benchmark、xlibgate imports/gomod/baseline、gitleaks CLI 与 diff hygiene；coverage total 100.0%。
- 发布 GitHub Release `v0.1.6`，Release run `27855366871` 与 main CI run `27855396013` 均通过。

### v0.1.5

- 在代码仓库补齐 `FEATURES.md` 与 `ACCEPTANCE.md`，并将其纳入发布文档契约。
- GitHub Release `v0.1.5` 已发布，但 main CI 暴露 secret-scan action license gate；该问题由 `v0.1.6` 修复。

### v0.1.4

- 修复 CI/CD trust tooling pin，改用可安装的 `xlibgate@v1.0.0` imports/gomod/baseline 检查。
- 强化 Markdown fenced code 解析，支持 backtick/tilde fence，并要求相同 marker 关闭。
- 重新验收 `make ci`、race、vet、coverage、benchmark、secret scan 与 xlibgate trust checks；coverage total 100.0%，full profile 15 项通过。
- 增加 `v0.1.4` release tag，并发布 GitHub Release。

### v0.1.3

- 将 harness 提升到可发布状态，CLI、公开 API、fixture 和 CI/CD 均由 `make ci` 覆盖。
- 覆盖率门禁提升到 100.0%。
- 边界门禁解析 `go.mod` 与 Go imports，禁止 `observex`、`configx`、`resiliencx`、`schedulex`、`testkitx`、`xlib_standard` 运行时引用。
- 规格门禁覆盖 23 节结构、FR Given/When/Then、AC/TC 可验证性。
- 增加 `v0.1.3` 本地 release tag。
