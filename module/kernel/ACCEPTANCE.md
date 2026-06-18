# kernel 验收说明

- **Module**: `kernel`
- **Goal**: `GOAL-KERNEL-20260609-001`
- **Spec**: `SPEC-kernel-v2` / `module/kernel/SPEC.md`
- **Spec Version**: `v2.0.0`
- **Traceability**: `module/kernel/TRACEABILITY.md`
- **Release Target**: `v1.0.0`
- **Updated**: `2026-06-18`
- **Status**: `Acceptance Contract`

本文定义 `kernel` v1.0.0 的验收口径和 gate closure 前置条件。它是验收契约，不是当前 Factory、GK-9 或 GK-10 通过证明；任何 gate 状态仍以当前可复现验证输出、四源评分和 arbiter 归档为准。

## 验收范围

`kernel` 是 L0 原语层，验收范围限定为 12 个标准库优先、互相独立或单向依赖的 Go 子包：

| Domain | Package | Scope |
| --- | --- | --- |
| 生命周期 | `lifecycx` | Component lifecycle start/stop orchestration and deterministic rollback. |
| 错误 | `errx` | Typed error taxonomy, wrapping, joining, classification, and kind matching. |
| 健康 | `healthx` | Health status model, checks, aggregation, and immutable snapshots. |
| 观测 | `obsx` | Logger/tracer no-op primitives and secret-safe string handling. |
| 重试 | `retryx` | Retry policy, backoff delay, jitter hook, and stop conditions. |
| 关闭 | `shutdownx` | Signal-aware graceful shutdown with ordered hooks and timeout handling. |
| 同步 | `syncx` | Worker group, semaphore limiter, once gate, and concurrent safety primitives. |
| 时间 | `timex` | Clock interface, real clock, fake clock, and deterministic time tests. |
| 校验 | `validx` | Validation result, field violation, and error conversion. |
| 版本 | `versionx` | Version info model, build metadata, and runtime snapshot. |
| 上下文 | `contextx` | Context helpers bound to time abstractions and cancellation behavior. |
| 契约测试 | `contracttest` | Shared test helpers for downstream contract assertions. |

不在本次验收范围内的内容：集中式 runtime app、依赖图或拓扑排序、配置加载、DI 容器、模块注入、存储、网络客户端、业务 DTO、交易业务逻辑、外部服务集成。

## 通过规则

只有同时满足以下条件，才能将 `module/kernel` 的追溯矩阵边从 `Linked` 推进到 `Verified`，并作为 Factory / GK-9 / GK-10 关闭证据使用：

1. `/home/kernel` 处于干净工作区，当前 `HEAD`、release manifest、release tag 和证据包记录的 commit 一致。
2. `go test ./...`、`go test -race ./...`、`go vet ./...`、`make coverage-threshold` 当前执行通过。
3. release gate 命令当前执行通过，包括 `make release-check`、`make release-final-check` 或等价严格验证命令。
4. 四源 `claude` / `codex` / `copilot` / `rules` scorer 均有当前归档，`pipeline-arbiter` 计算的 composite score 不低于 `98`，且无红线、低置信度、异常分差或 rules 异构分歧。
5. Matrix strict check-only validator 当前执行通过，并能证明 FR / BR / AC / TC / Task / Evidence 链路闭合。
6. release manifest、risk register、validation summary、rollback validation、gate result 和 evidence bundle 均存在且互相引用一致。
7. `docs/goal/04-gates.md` 和 `docs/goal/20-metrics-evidence.md` 中的 G8/G10 hard blockers 不存在。

历史 `.foundationx/status/index.json` 或 `.config/goal/gates/state.yaml` 中的 PASS / factory 记录不能单独关闭当前 gate；它们只能作为历史参考输入。

## 功能验收

| Requirement | Package | Acceptance Criteria | Test Case | Task | Acceptance Signal |
| --- | --- | --- | --- | --- | --- |
| `FR-001` lifecycle | `lifecycx` | `AC-001`, `AC-002` | `TC-001`, `TC-002`, `TC-003` | `TASK-KERNEL-005` | 启动、停止、逆序回滚、panic/timeout 聚合行为可复现。 |
| `FR-002` error taxonomy | `errx` | `AC-003`, `AC-004` | `TC-004`, `TC-005` | `TASK-KERNEL-001` | Kind matching、wrap/join、`errors.Is/As` 兼容行为稳定。 |
| `FR-003` health | `healthx` | `AC-005` | `TC-007` | `TASK-KERNEL-011` | 多检查项聚合和状态优先级确定，快照不可变。 |
| `FR-004` observability | `obsx` | `AC-006`, `AC-007` | `TC-009` | `TASK-KERNEL-003` | No-op logger/tracer 安全，secret 不通过格式化输出泄露。 |
| `FR-005` retry | `retryx` | `AC-008` | `TC-006` | `TASK-KERNEL-009` | 最大次数、上下文取消、backoff/jitter 和错误返回确定。 |
| `FR-006` shutdown | `shutdownx` | `AC-009`, `AC-010` | `TC-008`, `TC-016` | `TASK-KERNEL-006` | 信号触发、有序 hook、超时和错误聚合行为可验证。 |
| `FR-007` time | `timex` | `AC-011` | `TC-015` | `TASK-KERNEL-002` | real/fake clock 接口一致，fake clock 并发推进无数据竞争。 |
| `FR-008` validation | `validx` | `AC-012` | `TC-011` | `TASK-KERNEL-008` | 字段级 violation 可聚合并能稳定转换为 `errx` 错误。 |
| `FR-009` version | `versionx` | `AC-013` | `TC-017` | `TASK-KERNEL-007` | 版本、commit、build time 和 dirty 标记输出稳定。 |
| `FR-010` context | `contextx` | `AC-014` | `TC-010` | `TASK-KERNEL-010` | timeout/deadline helper 与 `timex` 时钟抽象一致。 |
| `FR-011` sync | `syncx` | `AC-015`, `AC-016` | `TC-013`, `TC-014` | `TASK-KERNEL-004` | worker group、semaphore、once gate 在 race 检测下稳定。 |
| `FR-012` contracttest | `contracttest` | `AC-017` | `TC-018` | `TASK-KERNEL-012` | 下游可复用 contract assertions，不引入生产依赖。 |
| `BR-009` stdlib-only | all packages | `AC-018` | `TC-012` | `TASK-KERNEL-016` | `go list -deps` 和 release policy 证明无外部 runtime 依赖。 |

## 非功能验收

| NFR | Scope | Evidence Command Or Check | Task |
| --- | --- | --- | --- |
| `NFR-001` | `errx.NewError` 小于 100ns | `BenchmarkNewError` | `TASK-KERNEL-001` |
| `NFR-002` | `errx.IsKind` 5-chain 小于 1us | `BenchmarkIsKind` | `TASK-KERNEL-001` |
| `NFR-003` | `healthx.Aggregate` 10 items 小于 10us | `BenchmarkAggregate` | `TASK-KERNEL-011` |
| `NFR-004` | `retryx.Delay` 小于 100ns | `BenchmarkDelay` | `TASK-KERNEL-009` |
| `NFR-005` | 全子包 resident memory 小于 5MB | `go test -memprofile` / release profile evidence | `TASK-KERNEL-016c` |
| `NFR-006` | 覆盖率不低于 100% | `make coverage-threshold` / `go tool cover` | `TASK-KERNEL-016c` |
| `NFR-007` | secret-safe output | `TC-009` golden behavior | `TASK-KERNEL-003` |
| `NFR-008` | 无硬编码 secret | secret scan / release security gate | `TASK-KERNEL-016c` |

## 必需验证命令

最小 runtime 验证：

```bash
cd /home/kernel
go test ./...
go test -race ./...
go vet ./...
make coverage-threshold
```

release / governance 验证：

```bash
cd /home/kernel
make release-check
make release-final-check
scripts/check_release_evidence.sh
```

治理仓库侧验证：

```bash
cd <repo-root>
python3 docs/goal/tools/matrix-gen.py --check-only --matrix .config/goal/matrix/matrix.yaml
四源 claude/codex/copilot/rules scorer
pipeline-arbiter
rollback validator
GK-9 / GK-10 gate validator
```

治理侧路径、运行态与证据晋级规则：

- `<kernel-governance-evidence-worktree>` 是当前 checkout 的治理证据仓库 worktree；不得使用历史本机绝对路径作为规范路径。
- `/home/kernel` 是内核运行态验证 checkout，只能提供当前运行命令输出；不得等同于治理证据仓库或 release manifest。
- `task_id`、worker runtime status、team worktree 路径和 `.omx/state/` 仅是执行期线索；只有归档的命令输出、matrix、scorer、arbiter、rollback 与 gate validator 结果可晋级为 `Verified`。
- 证据晋级必须保留稳定 ID、当前 status、来源命令和时间；不得用历史状态文件、人工描述或 team runtime 成功状态替代。

## 当前证据状态

截至 `2026-06-18`，team verifier lane 报告 `/home/kernel` 当前 runtime 验证通过：

| Evidence | Status | Meaning |
| --- | --- | --- |
| `go test ./...` | reported pass | 可作为当前本地测试证据之一。 |
| `go test -race ./...` | reported pass | 可作为当前并发安全证据之一。 |
| `go vet ./...` | reported pass | 可作为当前静态检查证据之一。 |
| `make coverage-threshold` | reported pass | 可作为当前覆盖率证据之一。 |
| `module/kernel/ACCEPTANCE.md` | present | 验收契约已补齐，可被后续 gate 消费。 |

当前仍不得关闭 Factory / GK-9 / GK-10，原因如下：

- 缺少当前四源 98+ scorer 和 `pipeline-arbiter` 归档。
- 缺少当前 Matrix strict check-only、rollback validator 和 gate validator 输出。
- `/home/kernel` 当前 checkout 为 dirty，且与 release manifest commit、local `v1.0.0` tag 不一致。
- `/home/kernel/release/manifest/latest.json` 中 `score.status` 为 `not_run`。

## 非验收条款

- 不得仅凭 task 文档、历史状态文件或人工描述将 Matrix edge 标为 `Verified`。
- 不得在缺少四源 98+ arbiter、严格 validator、rollback validation 和 release evidence bundle 的情况下关闭 G10。
- 不得把当前 dirty `/home/kernel` checkout 等同于 release manifest 中记录的 clean release state。
- 不得把本文件视为实现代码变更或 release artifact；本文件只提供可审计验收口径。
