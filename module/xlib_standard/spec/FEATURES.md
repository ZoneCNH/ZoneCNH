# xlib_standard 完整实现清单

- Status: Local-main merged from v1.0.2 acceptance evidence
- Last-Updated: 2026-06-20
- Module-Version: v1.0.2
- Module-State: 本地验收通过，待远端发布
- Layer: L1 工程标准
- Runtime-Repo: /home/xlib_standard
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, README.md, tasks/, prompt/

> 本清单用于约束 xlib_standard 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 0. v1.0.2 本地 main 合并证据快照

| 项目 | 证据 |
| --- | --- |
| 功能分支提交 | `/home/xlib_standard/.worktree/workspaces/xlib_standard` branch `xlib_standard` / `c899cf530f29ade438da048ddeff3f30584b6b04` |
| 本地 main 合并提交 | `/home/xlib_standard/.worktree/workspaces/main-merge` branch `main` / `8c41021d5d2573c8c97ccd968d5d3fbf0b0bf872` |
| Release 版本 | `v1.0.2` |
| Release facts target | `26792dc01317794fb337a0dc81bd732285e49100`；`ci_pull_request` 本地上下文跳过 tag 校验 |
| 本地发布验收 | `GOWORK=off XLIB_CONTEXT=ci_pull_request make release-check` 在功能分支与本地 main 合并提交均通过 |
| 覆盖率门槛 | `GOWORK=off make coverage-check` 通过，`coverage 100.0% >= 100.0%`；`go tool cover -func=coverage.out` 未发现非 100.0% 函数 |
| Goal score | `GOWORK=off go run ./cmd/goalcli score --min 9.8` 通过，score `10` |
| 证据 hash | 功能分支 `6c8d786bb4cbe4fd6eff54c5fe823538d2b035700d9869e49746af7f92f7dfd9`；本地 main `7e1d43ec6fc0e2f9c77fbbdfd37556ff2de4d5139868ad86aca00820e0000fbd` |
| Release manifest | 本地 main `release/manifest/latest.json` 记录 `version=v1.0.2`、`commit=8c41021d5d2573c8c97ccd968d5d3fbf0b0bf872`、`tree_state=clean`、`workflow_run_id=local` |
| CI/CD 配置 | `.github/workflows/ci.yml` 上传 `coverage-${{ github.run_id }}` 与 release manifest；`.github/workflows/goal-gates.yml` 执行 pinned golangci-lint、coverage-check、evidence-check |
| 远端发布缺口 | 本轮未执行远端 GitHub Actions、push、tag publish 或 GitHub Release 创建 |

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | Go 工程标准、目录约束、依赖边界与质量门禁 |
| 文档目录 | module/xlib_standard |
| 运行时代码目录 | /home/xlib_standard |
| Go 基线 | 1.23 |
| 允许依赖 | 无 |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Config 标准快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-002 | Error 标准快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-003 | Health 标准快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-004 | Metrics 标准快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-005 | Client 标准快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-006 | Version 标准快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-007 | 公共 API 模板快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-008 | 模板可编译快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-009 | render_template.sh 渲染快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-010 | 生成库无模板残留快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-011 | CI gate快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-012 | boundary gate快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-013 | release manifest快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-014 | release final check快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-015 | Evidence Runtime CLI快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-016 | L2 下游仓库模板快照锚点 | module/xlib_standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-017 | 上游标准快照契约 17快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-018 | 上游标准快照契约 18快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-019 | 上游标准快照契约 19快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-020 | 上游标准快照契约 20快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-021 | 上游标准快照契约 21快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-022 | 上游标准快照契约 22快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-023 | 上游标准快照契约 23快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-024 | 上游标准快照契约 24快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-025 | 上游标准快照契约 25快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-026 | 上游标准快照契约 26快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-027 | 上游标准快照契约 27快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-028 | 上游标准快照契约 28快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-029 | 上游标准快照契约 29快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-030 | 上游标准快照契约 30快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-031 | 上游标准快照契约 31快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-032 | 上游标准快照契约 32快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-033 | 上游标准快照契约 33快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-034 | 上游标准快照契约 34快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-035 | 上游标准快照契约 35快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-036 | 上游标准快照契约 36快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-037 | 上游标准快照契约 37快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-038 | 上游标准快照契约 38快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-039 | 上游标准快照契约 39快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-040 | 上游标准快照契约 40快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-041 | 上游标准快照契约 41快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-042 | 上游标准快照契约 42快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-043 | 上游标准快照契约 43快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-044 | 上游标准快照契约 44快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-045 | 上游标准快照契约 45快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-046 | 上游标准快照契约 46快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-047 | 上游标准快照契约 47快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-048 | 上游标准快照契约 48快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-049 | 上游标准快照契约 49快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-050 | 上游标准快照契约 50快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-051 | 上游标准快照契约 51快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-052 | 上游标准快照契约 52快照锚点 | module/xlib_standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | 配置显式传入：库不得读取隐式环境配置；调用方必须显式传入配置结构 | `pkg/templatex/config.go` 显式构造 + boundary gate | ✅ | SPEC.md §7 BR-001 |
| BR-002 | 错误消息格式：公共错误消息稳定、短句化；错误 kind 比错误文本更适合作为断言对象 | `pkg/templatex/errors.go` + AC-004/005/006/007/008 | ✅ | SPEC.md §7 BR-002 |
| BR-003 | Metrics label 低基数：label 不得包含 ID、路径、用户输入、动态 module path | AC-013 / `pkg/templatex/metrics.go:15-19` | ✅ | SPEC.md §7 BR-003 |
| BR-004 | 模板占位符完整性：渲染脚本必须替换所有模板占位符；缺少必要参数时必须失败 | AC-022/023 / `scripts/render_template.sh` + `scripts/check_rendered_template.sh` | ✅ | SPEC.md §7 BR-004 |
| BR-005 | 生成库独立性：生成库必须可脱离标准模板仓库独立构建、测试和发布 | AC-023/024 / boundary gate + `make ci` | ✅ | SPEC.md §7 BR-005 |
| BR-006 | 库中禁止退出进程：库代码不得调用 `log.Fatal`、`os.Exit` 或等价退出进程逻辑 | boundary gate `scripts/check_boundary.sh` | ✅ | SPEC.md §7 BR-006 |
| BR-007 | Sanitize 脱敏范围：覆盖 secret、token、key、password 类字段，并保留非敏感配置用于诊断 | AC-003 / `pkg/templatex/config.go:34-39` | ✅ | SPEC.md §7 BR-007 |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-XLIB-000 | TASK-XLIB-000 | module/xlib_standard/tasks/TASK-XLIB-000.md | - | tasks/TASK-XLIB-000.md |
| TASK-XLIB-001 | TASK-XLIB-001 | module/xlib_standard/tasks/TASK-XLIB-001.md | - | tasks/TASK-XLIB-001.md |
| TASK-XLIB-002 | TASK-XLIB-002 | module/xlib_standard/tasks/TASK-XLIB-002.md | - | tasks/TASK-XLIB-002.md |
| TASK-XLIB-003 | TASK-XLIB-003 | module/xlib_standard/tasks/TASK-XLIB-003.md | - | tasks/TASK-XLIB-003.md |
| TASK-XLIB-004 | TASK-XLIB-004 | module/xlib_standard/tasks/TASK-XLIB-004.md | - | tasks/TASK-XLIB-004.md |
| TASK-XLIB-005 | TASK-XLIB-005 | module/xlib_standard/tasks/TASK-XLIB-005.md | - | tasks/TASK-XLIB-005.md |
| TASK-XLIB-006 | TASK-XLIB-006 | module/xlib_standard/tasks/TASK-XLIB-006.md | - | tasks/TASK-XLIB-006.md |
| TASK-XLIB-007 | TASK-XLIB-007 | module/xlib_standard/tasks/TASK-XLIB-007.md | - | tasks/TASK-XLIB-007.md |
| TASK-XLIB-008 | TASK-XLIB-008 | module/xlib_standard/tasks/TASK-XLIB-008.md | - | tasks/TASK-XLIB-008.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/xlib_standard/goal.md |
| SPEC.md | 存在 | module/xlib_standard/SPEC.md |
| TRACEABILITY.md | 存在 | module/xlib_standard/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/xlib_standard/IMPLEMENTATION-PLAN.md |
| README.md | 存在 | module/xlib_standard/README.md |
| tasks/ | 9 个 Markdown 文件 | module/xlib_standard/tasks |
| prompt/ | 9 个 Markdown 文件 | module/xlib_standard/prompt |

## 6. 实现完成判定

- [x] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖（`make ci` 与 `make release-preflight` 覆盖模板、fact、traceability 与 release gates）。
- [x] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖（boundary、security、contracts、docs-check、cli-contract、adoption 与 evidence gates 通过）。
- [x] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC（traceability gate 与 `goalcli traceability-check` 在 release-preflight 中通过）。
- [x] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖（boundary gate 与 `GOWORK=off go list -deps ./...` 相关检查通过）。
- [x] 运行时代码仓库 /home/xlib_standard 的 lint、typecheck、test、coverage 与 release 验证证据已归档（v1.0.2 功能分支与本地 main 合并提交通过 `go test ./...`、100.0% coverage、`coverage-check`、`release-check` 与 goal score 10）。
- [x] 发布说明、版本号与本目录登记状态一致（v1.0.2 功能分支提交 `c899cf530f29ade438da048ddeff3f30584b6b04`，本地 main 合并提交 `8c41021d5d2573c8c97ccd968d5d3fbf0b0bf872`；远端 tag 与 GitHub Release 待执行）。
