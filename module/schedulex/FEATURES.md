# schedulex v1.0.0 功能实现清单

- Status: Accepted
- Last-Updated: 2026-06-18
- Module-Version: v1.0.0
- Module-State: 本地发布验收通过
- Layer: L1 调度基座
- Runtime-Repo: /home/schedulex
- Runtime-Branch: ci/sre-cicd-pools-20260618
- Source: SPEC.md, /home/schedulex README.md, Makefile, release-check evidence

> 本清单记录 `schedulex` v1.0.0 已验收的运行时能力。v1.0 以 `AddJob`、可注入时钟、确定性触发、调度快照、事件 sink 与锁接口为对外契约；旧追溯文档中的 `Cancel`、`Replace`、`Delay` 等扩展项登记为 v1.1 候选，不作为本版本已发布能力。

## 1. 模块边界

| 项目 | v1.0.0 要求 |
| --- | --- |
| 模块职责 | 单进程确定性调度、任务注册、触发计算、并发/重叠治理、误触发补偿、生命周期关闭与可审计事件 |
| 文档目录 | `module/schedulex` |
| 运行时代码目录 | `/home/schedulex` |
| Go 基线 | Go 1.23 |
| 运行时依赖 | 标准库 only；生产代码不依赖 `x.go`、L2 或业务域 |
| CI/CD 约束 | `GOWORK=off`；SRE self-hosted runner；release gate 必须通过 `make release-check VERSION=v1.0.0` |
| 对外承诺 | 公共 API、错误、策略、事件、锁接口、测试、证据与 release manifest 可复验 |

## 2. 已验收功能

| ID | 功能项 | v1.0.0 对外契约 | 验收证据 | 状态 |
| --- | --- | --- | --- | --- |
| FR-001 | 调度器生命周期 | `NewScheduler`、`AddJob`、`Start`、`Shutdown`、`Snapshot`；重复 job 返回 `ErrJobExists`，关闭后返回 `ErrSchedulerClosed` | `api-check`、`test`、`race`、`release-check` | PASS |
| FR-002 | 触发器 | `Once`、`Every`、5-field `Cron`、`DailyAt`；支持 `WithTriggerStartAt` 与 `WithTriggerEndAt` | `trigger-determinism-check`、`timezone-dst-golden-check` | PASS |
| FR-003 | 可注入时钟 | `Clock` 接口与测试时钟支持确定性推进，不依赖真实时间完成核心验收 | trigger golden tests、DST tests | PASS |
| FR-004 | Misfire 策略 | `MisfireSkip`、`MisfireRunOnce`、`MisfireCatchUp` | `misfire-contract-check`、contracts | PASS |
| FR-005 | Overlap 与并发控制 | `OverlapSkip`、`OverlapQueueOne`、`OverlapAllow`；调度器级 `WithMaxConcurrent` | overlap tests、`scheduler-race-check`、`scheduler-leak-check` | PASS |
| FR-006 | 事件输出 | `EventSink` 支持调度器级与 job 级事件，覆盖生命周期、misfire、lock、shutdown 等状态 | contracts、docs-check | PASS |
| FR-007 | 锁扩展接口 | `Locker`、`Lease`、`WithLocker`、`WithLockKey`、`WithLockTTL`；只定义接口，不内置具体分布式锁后端 | `lock-interface-check`、boundary | PASS |
| FR-008 | 快照与可观测状态 | `Snapshot`、`JobSnapshot` 提供可审计运行状态与 job 状态 | contracts、docs-check | PASS |
| FR-009 | 边界与安全 | 标准库 only；无凭证、私有端点、账户 ID 或实盘配置；不越过 L1 基座边界 | `boundary`、`security`、`governance-check` | PASS |
| FR-010 | 发布证据 | `release/manifest/latest.json`、校验和、score gate 与 release preflight 可复验 | `release-final-check`、`score=10.0`、`release-preflight` | PASS |

## 3. 公共 API 摘要

| 类别 | v1.0.0 契约 |
| --- | --- |
| 调度器入口 | `NewScheduler(opts ...Option) (*Scheduler, error)` |
| 任务注册 | `AddJob(job Job, trigger Trigger, opts ...JobOption) error` |
| 运行控制 | `Start(ctx context.Context) error`、`Shutdown(ctx context.Context) error` |
| 状态读取 | `Snapshot() Snapshot` |
| Job 合约 | `Job.Name() string`、`Job.Run(ctx context.Context) error` |
| Trigger 合约 | `Trigger.Next(after time.Time) (time.Time, bool)` |
| 调度器选项 | `WithClock`、`WithEventSink`、`WithMaxConcurrent` |
| Job 选项 | `WithMisfirePolicy`、`WithOverlapPolicy`、`WithJitter`、`WithLocker`、`WithLockKey`、`WithLockTTL`、`WithJobEventSink` |
| 错误集合 | `ErrSchedulerClosed`、`ErrJobExists`、`ErrInvalidJob`、`ErrInvalidOption`、`ErrLockUnavailable` |

## 4. CI/CD 与发布能力

| 项目 | v1.0.0 配置 |
| --- | --- |
| Required status checks | `ci`、`release-check`、`security`、`integration`、`gates`、`worktree-check` |
| Main 保护 | required status checks + required signatures |
| Release tag 保护 | `v*` tag + required signatures |
| CI runner | `[self-hosted, Linux, X64, sre/foundation-l1]` |
| Release runner | `[self-hosted, Linux, X64, sre/deploy]` |
| 核心 CI 命令 | `GOWORK=off make release-check VERSION="${VERSION}"` |
| Release 触发 | push `v*` tag 后执行 release workflow，生成 manifest 并发布 GitHub Release |

## 5. v1.1 候选与非本版能力

| 项目 | 当前结论 |
| --- | --- |
| Cancel API | v1.0.0 未暴露单 job cancel；当前通过 `Shutdown(ctx)` 关闭调度器，通过 `Snapshot()` 查看状态 |
| Schedule/JobID API | v1.0.0 使用 `AddJob` + `Job.Name()`，未暴露返回 `JobID` 的注册入口 |
| List API | v1.0.0 使用 `Snapshot()`，未暴露独立 list 入口 |
| Stop API | v1.0.0 使用 `Shutdown(ctx)`，超时语义由传入 context 决定 |
| Delay trigger | v1.0.0 使用 `Once(time.Time)` 表达一次性延后触发 |
| OverlapReplace | v1.0.0 支持 `skip`、`queue_one`、`allow`，不支持 replace |
| 多 listener EventBus | v1.0.0 提供单个 `EventSink` 接口扩展点 |
| 内置锁后端 | v1.0.0 只提供 `Locker` 接口，不绑定 Redis、数据库或外部服务 |
| 指标/日志/span 导出器 | v1.0.0 通过事件与快照提供观测基础，不内置具体 exporter |

## 6. 实现完成判定

- [x] 已验收 FR-001 至 FR-010 的运行时代码、单元测试、契约测试或脚本证据。
- [x] 已通过 `GOWORK=off make release-check VERSION=v1.0.0`。
- [x] 已通过 integration、governance、p1、p2、score 与 release preflight。
- [x] 已确认生产代码保持标准库 only 与 L1 基座边界。
- [x] 已同步 CI/CD required checks、runner pool、release gate 与文档登记。
- [ ] tag 发布后的网络 downstream smoke 需等待 `v1.0.0` 对外可解析后执行。
