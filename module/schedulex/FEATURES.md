# schedulex 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.0.0
- Module-State: 已发布（运行时 API 与原 SPEC 草案有偏差，已对齐；缺口登记为 v1.1 候选）
- Layer: L0 调度
- Runtime-Repo: /home/schedulex
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 schedulex 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。
> 状态列（基于运行时 v1.0.0 实测）：✅ 已实现 / ⚠️ 部分 / ❌ 缺口（v1.1 候选，见 goal §15）。判定基线见 SPEC §8 canonical API。

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
| FR-001 | Schedule：注册 job + 参数校验（运行时方法为 AddJob，返回 error 不返回 JobID） | AC-001: AddJob 合法 job 返回 nil; AC-002: trigger 不合法 → ErrInvalidJob; AC-003: interval <= 0 → ErrInvalidJob; AC-004: 重复 Job name → ErrJobExists / TC-001, TC-009 / TASK-002 | ⚠️ 部分 | TRACEABILITY.md |
| FR-002 | Trigger：cron/interval/delay 触发（Delay 未实现，用 Once/DailyAt 替代） | AC-005: cron 到达调度时间调用 Job.Run; AC-006: interval 到期调用 Job.Run; AC-007: Delay 后首次触发（v1.1 缺口） / TC-001 / TASK-002 | ⚠️ 部分 | TRACEABILITY.md |
| FR-003 | Overlap Policy：Skip/Queue/Replace（运行时为 Skip/QueueOne/Allow，无 Replace） | AC-008: Skip → 上次未完成时跳过; AC-009: QueueOne → 至多排队一个; AC-010: Replace → 取消旧的启动新的（v1.1 缺口） / TC-002 / TASK-003 | ⚠️ 部分 | TRACEABILITY.md |
| FR-004 | Misfire Policy：Skip/RunOnce/CatchUp | AC-011: Skip → 跳过错过的触发; AC-012: RunOnce → 补执行一次; AC-013: CatchUp → 补执行所有错过次数 / TC-003 / TASK-004 | ✅ 已实现 | TRACEABILITY.md |
| FR-005 | Cancel：取消 job（运行时未实现，v1.1 缺口） | AC-014: 存在的 job 取消返回 nil（v1.1）; AC-015: 不存在返回错误（v1.1） / TC-005 / TASK-002 | ❌ 缺口 | TRACEABILITY.md |
| FR-006 | Stop：graceful shutdown（运行时为 Shutdown，返回 ctx.Err()，无 ErrShutdownTimeout） | AC-016: Shutdown 等待正在执行的 job 完成; AC-017: 超时返回 ctx.Err()（v1.1：ErrShutdownTimeout） / TC-006 / TASK-005 | ⚠️ 部分 | TRACEABILITY.md |
| FR-007 | EventSink：生命周期事件回调（9 个 EventType） | AC-018: scheduled/started/succeeded/failed/misfire 等事件输出 / TC-007 / TASK-006 | ✅ 已实现 | TRACEABILITY.md |
| FR-008 | Locker：分布式锁（TryLock/Lease，TTL 校验未实现） | AC-019: TryLock 成功 → 执行 job; AC-020: 锁失败 → 跳过本次（EventLockSkipped）; AC-021: TTL < 执行时间 → 配置错误（v1.1 缺口） / TC-004 / TASK-007 | ⚠️ 部分 | TRACEABILITY.md |
| FR-009 | Clock：可注入时钟（StaticClock） | AC-022: StaticClock 注入后调度基于 StaticClock / TC-008 / TASK-008 | ✅ 已实现 | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | Schedule 必须校验 trigger 合法性（cron 语法 / interval > 0） | 非法 trigger → ErrInvalidJob，不注册 job / TC-001 / TASK-002 | ✅ 已实现 | TRACEABILITY.md |
| BR-002 | 同一 Job name 重复注册返回 ErrJobExists | 重复 AddJob 同一 name → ErrJobExists / TC-009 / TASK-002 | ⚠️ 部分 | TRACEABILITY.md |
| BR-003 | Shutdown 必须等待正在执行的 job 完成或 ctx 超时 | Shutdown 后所有运行中 job 完成或返回 ctx.Err() / TC-006 / TASK-005 | ⚠️ 部分 | TRACEABILITY.md |
| BR-004 | overlap 行为由 OverlapPolicy 决定，不内置隐式策略 | 未设置 OverlapPolicy 时使用默认值（全局配置） / TC-002 / TASK-003 | ✅ 已实现 | TRACEABILITY.md |
| BR-005 | job panic 被 catch，不影响其他 job | panic job 不影响其他 job 的正常调度 / TC-006 / TASK-002 | ✅ 已实现 | TRACEABILITY.md |
| BR-006 | lock TTL > job 最大执行时间，防止锁提前释放 | TTL 不足 → 配置错误，拒绝注册（运行时尚未校验） / TC-004 / TASK-007 | ❌ 缺口 | TRACEABILITY.md |
| BR-007 | DST 切换时触发时间必须正确（不能跳过或重复触发） | DST 边界触发时间符合目标时区 cron 语义（golden 存在，实现用 AddDate） / TC-008 / TASK-008 | ⚠️ 部分 | TRACEABILITY.md |
| BR-008 | job handler 必须接受 context.Context，支持取消传播 | Job.Run 签名为 func(ctx context.Context) error / CI Gate: go build / TASK-001 | ✅ 已实现 | TRACEABILITY.md |
| NFR-O01 | 6 个 metric + 8 个 log 输出（运行时仅 EventSink 回调，metric/log/span 未实现） | EventSink 回调可用 / CI Gate: integration test / TASK-006, TASK-009 | ❌ 缺口 | TRACEABILITY.md |
| NFR-P01 | job 触发延迟 < 10ms（单节点） | Benchmark 测量触发到 Job.Run 调用延迟（待 benchmark 证据） / CI Gate: go test -bench / TASK-009 | ⚠️ 部分 | TRACEABILITY.md |
| NFR-P02 | 1000 个 job 内存占用 < 10MB | Profiling 测量常驻内存（待 profiling 证据） / CI Gate: go test -bench -benchmem / TASK-009 | ⚠️ 部分 | TRACEABILITY.md |
| NFR-P03 | 常驻内存 < 5MB | Profiling 测量基线内存（待 profiling 证据） / CI Gate: go test -bench -benchmem / TASK-009 | ⚠️ 部分 | TRACEABILITY.md |
| NFR-S01 | 分布式锁安全：锁 TTL 约束 | TTL < job timeout → 配置错误（未校验） / TC-004 / TASK-007 | ❌ 缺口 | TRACEABILITY.md |
| NFR-S02 | job panic 隔离 | panic 不传播到调度器 / TC-006 / TASK-002 | ✅ 已实现 | TRACEABILITY.md |

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

- [x] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖（FR-005 Cancel 为 v1.1 缺口，已登记 goal §15）。
- [x] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖（BR-006/NFR-S01 TTL 校验、NFR-O01 metric/log/span 为 v1.1 缺口）。
- [x] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [x] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [ ] 运行时代码仓库 /home/schedulex 的 lint、typecheck、test、race、coverage 验证证据已归档（v1.0.0 已通过 go build/vet/test，benchmark/profiling 基线报告待补）。
- [x] 发布说明、版本标签与本目录登记状态一致（v1.0.0 已发布；本文档对齐运行时事实基线）。

> 缺口见 TRACEABILITY.md 状态列与 goal §15。⚠️ 部分 / ❌ 缺口项不阻塞 v1.0.0（已按现状发布），作为 v1.1 候选。
