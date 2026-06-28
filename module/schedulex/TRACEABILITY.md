# schedulex 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-29
Source: SPEC.md v1.0.0 | Tasks: TASK-SCHEDULEX-000 ~ TASK-SCHEDULEX-011

---

## §1 功能需求追溯（FR）

| Requirement   | Description                          | Acceptance Criteria                                                                                                                                                | Test Case      | Task     | Status   |
| ------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------- | -------- | -------- |
| FR-001        | Schedule：注册 job + 参数校验        | AC-001: 合法 cron job 返回 JobID<br>AC-002: cron 语法错误 → ErrInvalidTrigger<br>AC-003: interval <= 0 → ErrInvalidTrigger<br>AC-004: 重复 JobID → ErrDuplicateJob | TC-001, TC-009 | TASK-002 | ⬜        |
| FR-002        | Trigger：cron/interval/delay 触发    | AC-005: cron 到达调度时间调用 handler<br>AC-006: interval 到期调用 handler<br>AC-007: Delay 后首次触发                                                             | TC-001         | TASK-002 | ⬜        |
| FR-003        | Overlap Policy：Skip/Queue/Replace   | AC-008: Skip → 上次未完成时跳过<br>AC-009: Queue → 排队等待<br>AC-010: Replace → 取消旧的启动新的                                                                  | TC-002         | TASK-003 | ⬜        |
| FR-004        | Misfire Policy：Skip/RunOnce/CatchUp | AC-011: Skip → 跳过错过的触发<br>AC-012: RunOnce → 补执行一次<br>AC-013: CatchUp → 补执行所有错过次数                                                              | TC-003         | TASK-004 | ⬜        |
| FR-005        | Cancel：取消 job                     | AC-014: 存在的 job 取消返回 nil<br>AC-015: 不存在返回 ErrJobNotFound                                                                                               | TC-005         | TASK-002 | ⬜        |
| FR-006        | Stop：graceful shutdown              | AC-016: 等待正在执行的 job 完成<br>AC-017: 超时强制取消 → ErrShutdownTimeout                                                                                       | TC-006         | TASK-005 | ⬜        |
| FR-007        | EventSink：生命周期事件回调          | AC-018: trigger/start/complete/fail/misfire 事件输出                                                                                                               | TC-007         | TASK-006 | ⬜        |
| FR-008        | Locker：分布式锁                     | AC-019: 锁获取成功 → 执行 job<br>AC-020: 锁获取失败 → 跳过本次<br>AC-021: TTL < 执行时间 → 配置错误                                                                | TC-004         | TASK-007 | ⬜        |
| FR-009        | Clock：可注入时钟                    | AC-022: FakeClock 注入后调度基于 FakeClock                                                                                                                         | TC-008         | TASK-008 | ⬜        |

---


| Requirement   | Description                                                  | Acceptance Criteria                                     | TC ID(s) | Task     | Status   |
| ------------- | ------------------------------------------------------------ | ------------------------------------------------------- | ----------------- | -------- | -------- |
| BR-001        | Schedule 必须校验 trigger 合法性（cron 语法 / interval > 0） | 非法 trigger → ErrInvalidTrigger，不注册 job            | TC-001            | TASK-002 | ⬜        |
| BR-002        | 同一 JobID 重复注册返回 ErrDuplicateJob                      | 重复 Schedule 同一 ID → ErrDuplicateJob                 | TC-009            | TASK-002 | ⬜        |
| BR-003        | Stop 必须等待正在执行的 job 完成或超时                       | Stop 后所有运行中 job 完成或超时返回 ErrShutdownTimeout | TC-006            | TASK-005 | ⬜        |
| BR-004        | overlap 行为由 OverlapPolicy 决定，不内置隐式策略            | 未设置 OverlapPolicy 时使用默认值（全局配置）           | TC-002            | TASK-003 | ⬜        |
| BR-005        | job panic 被 catch，不影响其他 job                           | panic job 不影响其他 job 的正常调度                     | TC-006            | TASK-002 | ⬜        |
| BR-006        | lock TTL > job 最大执行时间，防止锁提前释放                  | TTL 不足 → 配置错误，拒绝注册                           | TC-004            | TASK-007 | ⬜        |
| BR-007        | DST 切换时触发时间必须正确（不能跳过或重复触发）             | DST 边界触发时间符合目标时区 cron 语义                  | TC-008            | TASK-008 | ⬜        |
| BR-008        | job handler 必须接受 context.Context，支持取消传播           | JobHandler 签名为 func(ctx context.Context) error       | CI Gate: go build | TASK-001 | ⬜        |

---

## §3 非功能需求追溯（NFR）

| Requirement   | Description                   | Acceptance Criteria                   | Test Case                         | Task               | Status   |
| ------------- | ----------------------------- | ------------------------------------- | --------------------------------- | ------------------ | -------- |
| NFR-P01       | job 触发延迟 < 10ms（单节点） | Benchmark 测量触发到 handler 调用延迟 | CI Gate: go test -bench           | TASK-009           | ⬜        |
| NFR-P02       | 1000 个 job 内存占用 < 10MB   | Profiling 测量常驻内存                | CI Gate: go test -bench -benchmem | TASK-009           | ⬜        |
| NFR-P03       | 常驻内存 < 5MB                | Profiling 测量基线内存                | CI Gate: go test -bench -benchmem | TASK-009           | ⬜        |
| NFR-S01       | 分布式锁安全：锁 TTL 约束     | TTL < job timeout → 配置错误          | TC-004                            | TASK-007           | ⬜        |
| NFR-S02       | job panic 隔离                | panic 不传播到调度器                  | TC-006                            | TASK-002           | ⬜        |
| NFR-O01       | 6 个 metric + 8 个 log 输出   | EventSink 或日志中可观测              | CI Gate: integration test         | TASK-006, TASK-009 | ⬜        |

---

## §4 TC->FR 反向追溯

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

| AC ID   | 描述                                                        | 关联 FR/BR              | 验证方式   |
| ------- | ----------------------------------------------------------- | ----------------------- | ---------- |
| AC-001  | Schedule 合法 cron job 返回 JobID                           | FR-001                  | TC-001     |
| AC-002  | cron 语法错误返回 ErrInvalidTrigger                         | FR-001, BR-001          | Unit       |
| AC-003  | interval <= 0 返回 ErrInvalidTrigger                        | FR-001, BR-001          | Unit       |
| AC-004  | 重复 JobID 返回 ErrDuplicateJob                             | FR-001, BR-002          | TC-009     |
| AC-005  | cron 触发：到达调度时间调用 handler                         | FR-002                  | TC-001     |
| AC-006  | interval 触发：间隔到期调用 handler                         | FR-002                  | TC-001     |
| AC-007  | Delay 首次延迟后首次触发                                    | FR-002                  | Unit       |
| AC-008  | OverlapSkip：上次未完成时跳过本次                           | FR-003, BR-004          | TC-002     |
| AC-009  | OverlapQueue：上次未完成时排队等待                          | FR-003, BR-004          | TC-002     |
| AC-010  | OverlapReplace：取消旧的执行，启动新的                      | FR-003, BR-004          | TC-002     |
| AC-011  | MisfireSkip：跳过错过的触发                                 | FR-004                  | TC-003     |
| AC-012  | MisfireRunOnce：补执行一次                                  | FR-004                  | TC-003     |
| AC-013  | MisfireCatchUp：补执行所有错过次数                          | FR-004                  | TC-003     |
| AC-014  | Cancel 存在的 job 返回 nil                                  | FR-005                  | TC-005     |
| AC-015  | Cancel 不存在的 job 返回 ErrJobNotFound                     | FR-005                  | TC-005     |
| AC-016  | Stop 等待正在执行的 job 完成                                | FR-006, BR-003          | TC-006     |
| AC-017  | Stop 超时强制取消，返回 ErrShutdownTimeout                  | FR-006, BR-003          | TC-006     |
| AC-018  | job 生命周期事件回调（trigger/start/complete/fail/misfire） | FR-007                  | TC-007     |
| AC-019  | 分布式锁获取成功时执行 job                                  | FR-008                  | TC-004     |
| AC-020  | 分布式锁获取失败时跳过本次                                  | FR-008                  | TC-004     |
| AC-021  | lock TTL < job 最大执行时间返回配置错误                     | FR-008, BR-006, NFR-S01 | TC-004     |
| AC-022  | FakeClock 注入后调度基于 FakeClock                          | FR-009                  | TC-008     |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| ---- | ---- | ---- | ------ |
| FR (功能需求) | 9 | 0 | 0% |
| BR (业务规则) | 8 | 0 | 0% |


| NFR (非功能需求) | 6 | 0 | 0% |
| AC (验收标准) | 22 | 0 | 0% |
| TC (测试用例) | 9 | 0 | 0% |
| **合计** | **54** | **0** | **0%** |

> 说明：全部 FR/BR/NFR/AC/TC 当前为 ⬜（Pending/未实现）。Task 总数 = TASK-001~011 共 11 项。

---

## §7 变更历史

| 日期       | 变更内容                                                                                                 | 作者    |
| ---------- | -------------------------------------------------------------------------------------------------------- | ------- |
| 2026-06-29 | Goal 管线对齐：§2 BR 表补全独立章节标题；§6 覆盖率仪表盘标准化为 Done/覆盖率格式 | ZoneCNH |
| 2026-06-12 | 深度分析修复：增加 Task 列、补全 BR-001/003/004/006/008、增加 NFR 追溯、增加 AC 注册表、增加覆盖率仪表盘 | ZoneCNH |
| 2026-06-09 | 初始版本（迁移前全局矩阵）                                                                               | ZoneCNH |
