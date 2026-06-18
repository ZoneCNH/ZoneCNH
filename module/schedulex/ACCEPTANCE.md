# schedulex 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.0.0
- Module-State: 已发布
- Layer: L0 调度
- Runtime-Repo: /home/schedulex
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 schedulex 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/schedulex/FEATURES.md && test -f module/schedulex/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/schedulex | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/schedulex && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/schedulex && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/schedulex && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/schedulex && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/schedulex && go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | Schedule 合法 cron job 返回 JobID | FR-001 / TC-001 | - | TRACEABILITY.md |
| AC-002 | cron 语法错误返回 ErrInvalidTrigger | FR-001, BR-001 / Unit | - | TRACEABILITY.md |
| AC-003 | interval <= 0 返回 ErrInvalidTrigger | FR-001, BR-001 / Unit | - | TRACEABILITY.md |
| AC-004 | 重复 JobID 返回 ErrDuplicateJob | FR-001, BR-002 / TC-009 | - | TRACEABILITY.md |
| AC-005 | cron 触发：到达调度时间调用 handler | FR-002 / TC-001 | - | TRACEABILITY.md |
| AC-006 | interval 触发：间隔到期调用 handler | FR-002 / TC-001 | - | TRACEABILITY.md |
| AC-007 | Delay 首次延迟后首次触发 | FR-002 / Unit | - | TRACEABILITY.md |
| AC-008 | OverlapSkip：上次未完成时跳过本次 | FR-003, BR-004 / TC-002 | - | TRACEABILITY.md |
| AC-009 | OverlapQueue：上次未完成时排队等待 | FR-003, BR-004 / TC-002 | - | TRACEABILITY.md |
| AC-010 | OverlapReplace：取消旧的执行，启动新的 | FR-003, BR-004 / TC-002 | - | TRACEABILITY.md |
| AC-011 | MisfireSkip：跳过错过的触发 | FR-004 / TC-003 | - | TRACEABILITY.md |
| AC-012 | MisfireRunOnce：补执行一次 | FR-004 / TC-003 | - | TRACEABILITY.md |
| AC-013 | MisfireCatchUp：补执行所有错过次数 | FR-004 / TC-003 | - | TRACEABILITY.md |
| AC-014 | Cancel 存在的 job 返回 nil | FR-005 / TC-005 | - | TRACEABILITY.md |
| AC-015 | Cancel 不存在的 job 返回 ErrJobNotFound | FR-005 / TC-005 | - | TRACEABILITY.md |
| AC-016 | Stop 等待正在执行的 job 完成 | FR-006, BR-003 / TC-006 | - | TRACEABILITY.md |
| AC-017 | Stop 超时强制取消，返回 ErrShutdownTimeout | FR-006, BR-003 / TC-006 | - | TRACEABILITY.md |
| AC-018 | job 生命周期事件回调（trigger/start/complete/fail/misfire） | FR-007 / TC-007 | - | TRACEABILITY.md |
| AC-019 | 分布式锁获取成功时执行 job | FR-008 / TC-004 | - | TRACEABILITY.md |
| AC-020 | 分布式锁获取失败时跳过本次 | FR-008 / TC-004 | - | TRACEABILITY.md |
| AC-021 | lock TTL < job 最大执行时间返回配置错误 | FR-008, BR-006, NFR-S01 / TC-004 | - | TRACEABILITY.md |
| AC-022 | FakeClock 注入后调度基于 FakeClock | FR-009 / TC-008 | - | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001, FR-002, BR-001 | 正常 cron/interval 触发 | - | TRACEABILITY.md |
| TC-002 | FR-003, BR-004 | OverlapPolicy 三种策略 | - | TRACEABILITY.md |
| TC-003 | FR-004 | MisfirePolicy 三种策略 | - | TRACEABILITY.md |
| TC-004 | FR-008, BR-006, NFR-S01 | 分布式锁获取/失败/TTL 校验 | - | TRACEABILITY.md |
| TC-005 | FR-005 | Cancel 存在/不存在 job | - | TRACEABILITY.md |
| TC-006 | FR-006, BR-003, BR-005, NFR-S02 | Stop 等待/超时 + panic 隔离 | - | TRACEABILITY.md |
| TC-007 | FR-007 | EventSink 生命周期事件 | - | TRACEABILITY.md |
| TC-008 | FR-009, BR-007 | Clock 注入 + DST 切换 | - | TRACEABILITY.md |
| TC-009 | FR-001, BR-002 | 重复 JobID 检测 | - | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
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

## 5. 发布 DoD 清单

- [ ] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [ ] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [ ] 运行时代码仓库 /home/schedulex 通过 go test、go test -race、go vet 与覆盖率门槛。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [ ] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- SPEC/TRACEABILITY 已登记 AC/TC 主链路；当前主要缺口是 /home/schedulex 实现、测试、CI、覆盖率、race/vet 与集成证据需要复验归档。
