# schedulex 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.0.0
- Module-State: 已发布
- Layer: L0 调度
- Runtime-Repo: /home/schedulex
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 schedulex 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | 统一调度、任务注册、触发、并发与生命周期治理 |
| 文档目录 | module/schedulex |
| 运行时代码目录 | /home/schedulex |
| Go 基线 | 1.23 |
| 允许依赖 | kernel |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Schedule：注册 job + 参数校验 | AC-001: 合法 cron job 返回 JobID; AC-002: cron 语法错误 → ErrInvalidTrigger; AC-003: interval <= 0 → ErrInvalidTrigger; AC-004: 重复 JobID → ErrDuplicateJob / TC-001, TC-009 / TASK-002 / ⬜ | - | TRACEABILITY.md |
| FR-002 | Trigger：cron/interval/delay 触发 | AC-005: cron 到达调度时间调用 handler; AC-006: interval 到期调用 handler; AC-007: Delay 后首次触发 / TC-001 / TASK-002 / ⬜ | - | TRACEABILITY.md |
| FR-003 | Overlap Policy：Skip/Queue/Replace | AC-008: Skip → 上次未完成时跳过; AC-009: Queue → 排队等待; AC-010: Replace → 取消旧的启动新的 / TC-002 / TASK-003 / ⬜ | - | TRACEABILITY.md |
| FR-004 | Misfire Policy：Skip/RunOnce/CatchUp | AC-011: Skip → 跳过错过的触发; AC-012: RunOnce → 补执行一次; AC-013: CatchUp → 补执行所有错过次数 / TC-003 / TASK-004 / ⬜ | - | TRACEABILITY.md |
| FR-005 | Cancel：取消 job | AC-014: 存在的 job 取消返回 nil; AC-015: 不存在返回 ErrJobNotFound / TC-005 / TASK-002 / ⬜ | - | TRACEABILITY.md |
| FR-006 | Stop：graceful shutdown | AC-016: 等待正在执行的 job 完成; AC-017: 超时强制取消 → ErrShutdownTimeout / TC-006 / TASK-005 / ⬜ | - | TRACEABILITY.md |
| FR-007 | EventSink：生命周期事件回调 | AC-018: trigger/start/complete/fail/misfire 事件输出 / TC-007 / TASK-006 / ⬜ | - | TRACEABILITY.md |
| FR-008 | Locker：分布式锁 | AC-019: 锁获取成功 → 执行 job; AC-020: 锁获取失败 → 跳过本次; AC-021: TTL < 执行时间 → 配置错误 / TC-004 / TASK-007 / ⬜ | - | TRACEABILITY.md |
| FR-009 | Clock：可注入时钟 | AC-022: FakeClock 注入后调度基于 FakeClock / TC-008 / TASK-008 / ⬜ | - | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | Schedule 必须校验 trigger 合法性（cron 语法 / interval > 0） | 非法 trigger → ErrInvalidTrigger，不注册 job / TC-001 / TASK-002 / ⬜ | - | TRACEABILITY.md |
| BR-002 | 同一 JobID 重复注册返回 ErrDuplicateJob | 重复 Schedule 同一 ID → ErrDuplicateJob / TC-009 / TASK-002 / ⬜ | - | TRACEABILITY.md |
| BR-003 | Stop 必须等待正在执行的 job 完成或超时 | Stop 后所有运行中 job 完成或超时返回 ErrShutdownTimeout / TC-006 / TASK-005 / ⬜ | - | TRACEABILITY.md |
| BR-004 | overlap 行为由 OverlapPolicy 决定，不内置隐式策略 | 未设置 OverlapPolicy 时使用默认值（全局配置） / TC-002 / TASK-003 / ⬜ | - | TRACEABILITY.md |
| BR-005 | job panic 被 catch，不影响其他 job | panic job 不影响其他 job 的正常调度 / TC-006 / TASK-002 / ⬜ | - | TRACEABILITY.md |
| BR-006 | lock TTL > job 最大执行时间，防止锁提前释放 | TTL 不足 → 配置错误，拒绝注册 / TC-004 / TASK-007 / ⬜ | - | TRACEABILITY.md |
| BR-007 | DST 切换时触发时间必须正确（不能跳过或重复触发） | DST 边界触发时间符合目标时区 cron 语义 / TC-008 / TASK-008 / ⬜ | - | TRACEABILITY.md |
| BR-008 | job handler 必须接受 context.Context，支持取消传播 | JobHandler 签名为 func(ctx context.Context) error / CI Gate: go build / TASK-001 / ⬜ | - | TRACEABILITY.md |
| NFR-O01 | 6 个 metric + 8 个 log 输出 | EventSink 或日志中可观测 / CI Gate: integration test / TASK-006, TASK-009 / ⬜ | - | TRACEABILITY.md |
| NFR-P01 | job 触发延迟 < 10ms（单节点） | Benchmark 测量触发到 handler 调用延迟 / CI Gate: go test -bench / TASK-009 / ⬜ | - | TRACEABILITY.md |
| NFR-P02 | 1000 个 job 内存占用 < 10MB | Profiling 测量常驻内存 / CI Gate: go test -bench -benchmem / TASK-009 / ⬜ | - | TRACEABILITY.md |
| NFR-P03 | 常驻内存 < 5MB | Profiling 测量基线内存 / CI Gate: go test -bench -benchmem / TASK-009 / ⬜ | - | TRACEABILITY.md |
| NFR-S01 | 分布式锁安全：锁 TTL 约束 | TTL < job timeout → 配置错误 / TC-004 / TASK-007 / ⬜ | - | TRACEABILITY.md |
| NFR-S02 | job panic 隔离 | panic 不传播到调度器 / TC-006 / TASK-002 / ⬜ | - | TRACEABILITY.md |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-SCHEDULEX-000 | TASK-SCHEDULEX-000 | module/schedulex/tasks/TASK-SCHEDULEX-000.md | - | tasks/TASK-SCHEDULEX-000.md |
| TASK-SCHEDULEX-001 | TASK-SCHEDULEX-001 | module/schedulex/tasks/TASK-SCHEDULEX-001.md | - | tasks/TASK-SCHEDULEX-001.md |
| TASK-SCHEDULEX-002 | TASK-SCHEDULEX-002 | module/schedulex/tasks/TASK-SCHEDULEX-002.md | - | tasks/TASK-SCHEDULEX-002.md |
| TASK-SCHEDULEX-003 | TASK-SCHEDULEX-003 | module/schedulex/tasks/TASK-SCHEDULEX-003.md | - | tasks/TASK-SCHEDULEX-003.md |
| TASK-SCHEDULEX-004 | TASK-SCHEDULEX-004 | module/schedulex/tasks/TASK-SCHEDULEX-004.md | - | tasks/TASK-SCHEDULEX-004.md |
| TASK-SCHEDULEX-005 | TASK-SCHEDULEX-005 | module/schedulex/tasks/TASK-SCHEDULEX-005.md | - | tasks/TASK-SCHEDULEX-005.md |
| TASK-SCHEDULEX-006 | TASK-SCHEDULEX-006 | module/schedulex/tasks/TASK-SCHEDULEX-006.md | - | tasks/TASK-SCHEDULEX-006.md |
| TASK-SCHEDULEX-007 | TASK-SCHEDULEX-007 | module/schedulex/tasks/TASK-SCHEDULEX-007.md | - | tasks/TASK-SCHEDULEX-007.md |
| TASK-SCHEDULEX-008 | TASK-SCHEDULEX-008 | module/schedulex/tasks/TASK-SCHEDULEX-008.md | - | tasks/TASK-SCHEDULEX-008.md |
| TASK-SCHEDULEX-009 | TASK-SCHEDULEX-009 | module/schedulex/tasks/TASK-SCHEDULEX-009.md | - | tasks/TASK-SCHEDULEX-009.md |
| TASK-SCHEDULEX-010 | TASK-SCHEDULEX-010 | module/schedulex/tasks/TASK-SCHEDULEX-010.md | - | tasks/TASK-SCHEDULEX-010.md |
| TASK-SCHEDULEX-011 | TASK-SCHEDULEX-011 | module/schedulex/tasks/TASK-SCHEDULEX-011.md | - | tasks/TASK-SCHEDULEX-011.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/schedulex/goal.md |
| SPEC.md | 存在 | module/schedulex/SPEC.md |
| TRACEABILITY.md | 存在 | module/schedulex/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/schedulex/IMPLEMENTATION-PLAN.md |
| tasks/ | 12 个 Markdown 文件 | module/schedulex/tasks |

## 6. 实现完成判定

- [ ] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [ ] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [ ] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [ ] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [ ] 运行时代码仓库 /home/schedulex 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [ ] 发布说明、版本标签与本目录登记状态一致。
