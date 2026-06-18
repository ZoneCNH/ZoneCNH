# schedulex 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-18
Source: SPEC.md v1.0.1 | Tasks: TASK-SCHEDULEX-000 ~ TASK-SCHEDULEX-011

> 状态列说明（基于运行时 v1.0.0 实测）：`✅ 已实现` = 运行时已交付且有测试；`⚠️ 部分` = 有实现但与原 AC 描述有偏差（命名/能力弱）；`❌ 缺口` = 运行时未实现（v1.1 候选，见 goal §15）。判定基线见 SPEC §8 canonical API。

---

## §1 功能需求追溯（FR）

| Requirement   | Description                          | Acceptance Criteria                                                                                                                                                | Test Case      | Task     | Status   |
| ------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------- | -------- | -------- |
| FR-001        | Schedule：注册 job + 参数校验        | AC-001: AddJob 注册合法 job 返回 nil<br>AC-002: trigger 不合法 → ErrInvalidJob<br>AC-003: interval <= 0 → ErrInvalidJob<br>AC-004: 重复 Job name → ErrJobExists | TC-001, TC-009 | TASK-002 | ⚠️ 部分 |
| FR-002        | Trigger：cron/interval/delay 触发    | AC-005: cron 到达调度时间调用 Job.Run<br>AC-006: interval 到期调用 Job.Run<br>AC-007: Delay 后首次触发（v1.1 缺口）                                                | TC-001         | TASK-002 | ⚠️ 部分 |
| FR-003        | Overlap Policy：Skip/Queue/Replace   | AC-008: Skip → 上次未完成时跳过<br>AC-009: QueueOne → 至多排队一个<br>AC-010: Replace → 取消旧的启动新的（v1.1 缺口）                                             | TC-002         | TASK-003 | ⚠️ 部分 |
| FR-004        | Misfire Policy：Skip/RunOnce/CatchUp | AC-011: Skip → 跳过错过的触发<br>AC-012: RunOnce → 补执行一次<br>AC-013: CatchUp → 补执行所有错过次数                                                              | TC-003         | TASK-004 | ✅ 已实现 |
| FR-005        | Cancel：取消 job                     | AC-014: 存在的 job 取消返回 nil（v1.1 缺口）<br>AC-015: 不存在返回错误（v1.1 缺口）                                                                               | TC-005         | TASK-002 | ❌ 缺口 |
| FR-006        | Stop：graceful shutdown              | AC-016: Shutdown 等待正在执行的 job 完成<br>AC-017: 超时返回 ctx.Err()（v1.1：ErrShutdownTimeout）                                                                 | TC-006         | TASK-005 | ⚠️ 部分 |
| FR-007        | EventSink：生命周期事件回调          | AC-018: scheduled/started/succeeded/failed/misfire 等事件输出到 EventSink                                                                                         | TC-007         | TASK-006 | ✅ 已实现 |
| FR-008        | Locker：分布式锁                     | AC-019: TryLock 成功 → 执行 job<br>AC-020: 锁失败 → 跳过本次（EventLockSkipped）<br>AC-021: TTL < 执行时间 → 配置错误（v1.1 缺口）                                  | TC-004         | TASK-007 | ⚠️ 部分 |
| FR-009        | Clock：可注入时钟                    | AC-022: StaticClock 注入后调度基于 StaticClock                                                                                                                     | TC-008         | TASK-008 | ✅ 已实现 |

---


| Requirement   | Description                                                  | Acceptance Criteria                                     | TC ID(s) | Task     | Status   |
| ------------- | ------------------------------------------------------------ | ------------------------------------------------------- | ----------------- | -------- | -------- |
| BR-001        | Schedule 必须校验 trigger 合法性（cron 语法 / interval > 0） | 非法 trigger → ErrInvalidJob，不注册 job                | TC-001            | TASK-002 | ✅ 已实现 |
| BR-002        | 同一 Job name 重复注册返回 ErrJobExists                      | 重复 AddJob 同一 name → ErrJobExists                    | TC-009            | TASK-002 | ⚠️ 部分 |
| BR-003        | Shutdown 必须等待正在执行的 job 完成或 ctx 超时              | Shutdown 后所有运行中 job 完成或返回 ctx.Err()          | TC-006            | TASK-005 | ⚠️ 部分 |
| BR-004        | overlap 行为由 OverlapPolicy 决定，不内置隐式策略            | 未设置 OverlapPolicy 时使用默认值（全局配置）           | TC-002            | TASK-003 | ✅ 已实现 |
| BR-005        | job panic 被 catch，不影响其他 job                           | panic job 不影响其他 job 的正常调度                     | TC-006            | TASK-002 | ✅ 已实现 |
| BR-006        | lock TTL > job 最大执行时间，防止锁提前释放                  | TTL 不足 → 配置错误，拒绝注册（运行时尚未校验）         | TC-004            | TASK-007 | ❌ 缺口 |
| BR-007        | DST 切换时触发时间必须正确（不能跳过或重复触发）             | DST 边界触发时间符合目标时区 cron 语义（golden 存在，实现用 AddDate） | TC-008            | TASK-008 | ⚠️ 部分 |
| BR-008        | job handler 必须接受 context.Context，支持取消传播           | Job.Run 签名为 func(ctx context.Context) error          | CI Gate: go build | TASK-001 | ✅ 已实现 |

---

## §3 非功能需求追溯（NFR）

| Requirement   | Description                   | Acceptance Criteria                   | Test Case                         | Task               | Status   |
| ------------- | ----------------------------- | ------------------------------------- | --------------------------------- | ------------------ | -------- |
| NFR-P01       | job 触发延迟 < 10ms（单节点） | Benchmark 测量触发到 Job.Run 调用延迟 | CI Gate: go test -bench           | TASK-009           | ⚠️ 部分 |
| NFR-P02       | 1000 个 job 内存占用 < 10MB   | Profiling 测量常驻内存                | CI Gate: go test -bench -benchmem | TASK-009           | ⚠️ 部分 |
| NFR-P03       | 常驻内存 < 5MB                | Profiling 测量基线内存                | CI Gate: go test -bench -benchmem | TASK-009           | ⚠️ 部分 |
| NFR-S01       | 分布式锁安全：锁 TTL 约束     | TTL < job timeout → 配置错误（未校验） | TC-004                            | TASK-007           | ❌ 缺口 |
| NFR-S02       | job panic 隔离                | panic 不传播到调度器                  | TC-006                            | TASK-002           | ✅ 已实现 |
| NFR-O01       | 6 个 metric + 8 个 log 输出   | EventSink 回调可用；metric/log/span 未实现 | CI Gate: integration test         | TASK-006, TASK-009 | ❌ 缺口 |

---

## §4 TC→FR 反向追溯

| Test Case   | 覆盖需求                        | 验证内容                    |
| ----------- | ------------------------------- | --------------------------- |
| TC-001      | FR-001, FR-002, BR-001          | 正常 cron/interval 触发     |
| TC-002      | FR-003, BR-004                  | OverlapPolicy 三种策略      |
| TC-003      | FR-004                          | MisfirePolicy 三种策略      |
| TC-004      | FR-008, BR-006, NFR-S01         | 分布式锁获取/失败/TTL 校验  |
| TC-005      | FR-005                          | Cancel 存在/不存在 job      |
| TC-006      | FR-006, BR-003, BR-005, NFR-S02 | Stop 等待/超时 + panic 隔离 |
| TC-007      | FR-007                          | EventSink 生命周期事件      |
| TC-008      | FR-009, BR-007                  | Clock 注入 + DST 切换       |
| TC-009      | FR-001, BR-002                  | 重复 JobID 检测             |

---

## §5 全局 AC 注册表

| AC ID   | 描述                                                        | 关联 FR/BR              | 验证方式   | 状态 |
| ------- | ----------------------------------------------------------- | ----------------------- | ---------- | ---- |
| AC-001  | AddJob 注册合法 job 返回 nil                                | FR-001                  | TC-001     | ⚠️ 部分 |
| AC-002  | trigger 不合法返回 ErrInvalidJob                            | FR-001, BR-001          | Unit       | ✅ 已实现 |
| AC-003  | interval <= 0 返回 ErrInvalidJob                            | FR-001, BR-001          | Unit       | ✅ 已实现 |
| AC-004  | 重复 Job name 返回 ErrJobExists                             | FR-001, BR-002          | TC-009     | ✅ 已实现 |
| AC-005  | cron 触发：到达调度时间调用 Job.Run                         | FR-002                  | TC-001     | ✅ 已实现 |
| AC-006  | interval 触发：间隔到期调用 Job.Run                         | FR-002                  | TC-001     | ✅ 已实现 |
| AC-007  | Delay 首次延迟后首次触发                                    | FR-002                  | Unit       | ❌ 缺口 |
| AC-008  | OverlapSkip：上次未完成时跳过本次                           | FR-003, BR-004          | TC-002     | ✅ 已实现 |
| AC-009  | OverlapQueueOne：上次未完成时至多排队一个                   | FR-003, BR-004          | TC-002     | ⚠️ 部分 |
| AC-010  | OverlapReplace：取消旧的执行，启动新的                      | FR-003, BR-004          | TC-002     | ❌ 缺口 |
| AC-011  | MisfireSkip：跳过错过的触发                                 | FR-004                  | TC-003     | ✅ 已实现 |
| AC-012  | MisfireRunOnce：补执行一次                                  | FR-004                  | TC-003     | ✅ 已实现 |
| AC-013  | MisfireCatchUp：补执行所有错过次数                          | FR-004                  | TC-003     | ✅ 已实现 |
| AC-014  | Cancel 存在的 job 返回 nil                                  | FR-005                  | TC-005     | ❌ 缺口 |
| AC-015  | Cancel 不存在的 job 返回错误                                | FR-005                  | TC-005     | ❌ 缺口 |
| AC-016  | Shutdown 等待正在执行的 job 完成                            | FR-006, BR-003          | TC-006     | ✅ 已实现 |
| AC-017  | Shutdown 超时返回 ctx.Err()（v1.1：ErrShutdownTimeout）     | FR-006, BR-003          | TC-006     | ⚠️ 部分 |
| AC-018  | job 生命周期事件回调（scheduled/started/succeeded/failed/misfire） | FR-007            | TC-007     | ✅ 已实现 |
| AC-019  | 分布式锁 TryLock 成功时执行 job                             | FR-008                  | TC-004     | ✅ 已实现 |
| AC-020  | 分布式锁失败时跳过本次（EventLockSkipped）                  | FR-008                  | TC-004     | ✅ 已实现 |
| AC-021  | lock TTL < job 最大执行时间返回配置错误                     | FR-008, BR-006, NFR-S01 | TC-004     | ❌ 缺口 |
| AC-022  | StaticClock 注入后调度基于 StaticClock                      | FR-009                  | TC-008     | ✅ 已实现 |

---

## §6 覆盖率仪表盘

| 维度   | 总数 | ✅ 已实现 | ⚠️ 部分 | ❌ 缺口 | 实现真实度 |
| ------ | ---- | --------- | ------- | ------- | ---------- |
| FR     | 9    | 3 (FR-004/007/009) | 5 (FR-001/002/003/006/008) | 1 (FR-005) | 8/9 有实现 |
| BR     | 8    | 4 (BR-001/004/005/008) | 3 (BR-002/003/007) | 1 (BR-006) | 7/8 有实现 |
| NFR    | 6    | 1 (NFR-S02) | 3 (NFR-P01/02/03) | 2 (NFR-S01/O01) | 4/6 有实现 |
| AC     | 22   | 13 | 3 | 6 | 19/22 可验或部分可验 |
| TC     | 9    | 按 AC 细判见 §5 | — | — | 8/9 可验 |
| 合计   | —    | — | — | — | — |

> 实现真实度基于运行时 v1.0.0 实测（SPEC §8 canonical API），不等于"完全符合原 SPEC 草案"。
> ⚠️ 部分 = 有实现但与原 AC 描述有偏差（命名/能力弱）；❌ 缺口 = 运行时未实现，登记为 v1.1 候选（见 goal §15）。
> 详细缺口登记见 ACCEPTANCE.md §6 与 goal §15。

---

## §7 变更历史

| 日期       | 变更内容                                                                                                 | 作者    |
| ---------- | -------------------------------------------------------------------------------------------------------- | ------- |
| 2026-06-09 | 初始版本（迁移前全局矩阵）                                                                               | ZoneCNH |
| 2026-06-12 | 深度分析修复：增加 Task 列、补全 BR-001/003/004/006/008、增加 NFR 追溯、增加 AC 注册表、增加覆盖率仪表盘 | ZoneCNH |
| 2026-06-18 | 状态列对齐运行时 v1.0.0 实测，三态标注已实现/部分/缺口；AC 注册表新增状态列 | agent-team |
