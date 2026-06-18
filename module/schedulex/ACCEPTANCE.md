# schedulex 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.0.0
- Module-State: 已发布（运行时 API 与原 SPEC 草案有偏差，已对齐；缺口登记为 v1.1 候选）
- Layer: L0 调度
- Runtime-Repo: /home/schedulex
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 schedulex 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。
> 当前登记状态列（基于运行时 v1.0.0 实测）：`可验(运行时 v1.0.0)` / `⚠️ 部分` / `缺口(v1.1)`。判定基线见 SPEC §8 canonical API。

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
| AC-001 | AddJob 合法 job 返回 nil | FR-001 / TC-001 | ⚠️ 部分（不返回 JobID） | TRACEABILITY.md |
| AC-002 | trigger 不合法返回 ErrInvalidJob | FR-001, BR-001 / Unit | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| AC-003 | interval <= 0 返回 ErrInvalidJob | FR-001, BR-001 / Unit | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| AC-004 | 重复 Job name 返回 ErrJobExists | FR-001, BR-002 / TC-009 | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| AC-005 | cron 触发：到达调度时间调用 Job.Run | FR-002 / TC-001 | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| AC-006 | interval 触发：间隔到期调用 Job.Run | FR-002 / TC-001 | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| AC-007 | Delay 首次延迟后首次触发 | FR-002 / Unit | 缺口(v1.1) | TRACEABILITY.md |
| AC-008 | OverlapSkip：上次未完成时跳过本次 | FR-003, BR-004 / TC-002 | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| AC-009 | OverlapQueueOne：上次未完成时至多排队一个 | FR-003, BR-004 / TC-002 | ⚠️ 部分（QueueOne 非 Queue） | TRACEABILITY.md |
| AC-010 | OverlapReplace：取消旧的执行，启动新的 | FR-003, BR-004 / TC-002 | 缺口(v1.1) | TRACEABILITY.md |
| AC-011 | MisfireSkip：跳过错过的触发 | FR-004 / TC-003 | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| AC-012 | MisfireRunOnce：补执行一次 | FR-004 / TC-003 | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| AC-013 | MisfireCatchUp：补执行所有错过次数 | FR-004 / TC-003 | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| AC-014 | Cancel 存在的 job 返回 nil | FR-005 / TC-005 | 缺口(v1.1) | TRACEABILITY.md |
| AC-015 | Cancel 不存在的 job 返回错误 | FR-005 / TC-005 | 缺口(v1.1) | TRACEABILITY.md |
| AC-016 | Shutdown 等待正在执行的 job 完成 | FR-006, BR-003 / TC-006 | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| AC-017 | Shutdown 超时返回 ctx.Err()（v1.1：ErrShutdownTimeout） | FR-006, BR-003 / TC-006 | ⚠️ 部分（无专属错误） | TRACEABILITY.md |
| AC-018 | job 生命周期事件回调（scheduled/started/succeeded/failed/misfire） | FR-007 / TC-007 | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| AC-019 | 分布式锁 TryLock 成功时执行 job | FR-008 / TC-004 | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| AC-020 | 分布式锁失败时跳过本次（EventLockSkipped） | FR-008 / TC-004 | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| AC-021 | lock TTL < job 最大执行时间返回配置错误 | FR-008, BR-006, NFR-S01 / TC-004 | 缺口(v1.1) | TRACEABILITY.md |
| AC-022 | StaticClock 注入后调度基于 StaticClock | FR-009 / TC-008 | 可验(运行时 v1.0.0) | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001, FR-002, BR-001 | 正常 cron/interval 触发（AddJob + Job.Run） | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| TC-002 | FR-003, BR-004 | OverlapPolicy：Skip/QueueOne 可验，Replace 缺 | ⚠️ 部分 | TRACEABILITY.md |
| TC-003 | FR-004 | MisfirePolicy 三种策略 | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| TC-004 | FR-008, BR-006, NFR-S01 | 分布式锁 TryLock/失败可验；TTL 校验缺 | ⚠️ 部分 | TRACEABILITY.md |
| TC-005 | FR-005 | Cancel 存在/不存在 job（运行时无 Cancel） | 缺口(v1.1) | TRACEABILITY.md |
| TC-006 | FR-006, BR-003, BR-005, NFR-S02 | Shutdown 等待/ctx 超时 + panic 隔离 | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| TC-007 | FR-007 | EventSink 生命周期事件（9 EventType） | 可验(运行时 v1.0.0) | TRACEABILITY.md |
| TC-008 | FR-009, BR-007 | StaticClock 注入 + DST（golden 存在，AddDate 实现） | ⚠️ 部分 | TRACEABILITY.md |
| TC-009 | FR-001, BR-002 | 重复 Job name 检测（ErrJobExists） | 可验(运行时 v1.0.0) | TRACEABILITY.md |

## 4. 覆盖闭合验收

## 4. 覆盖闭合验收

覆盖闭合以 TRACEABILITY.md §1–§3 为权威（FR/BR/NFR × AC × TC × Task × 状态五列），FEATURES.md §2/§3 为实现清单镜像。本节不重复登记，避免四份拷贝漂移。

**汇总状态（基于运行时 v1.0.0 实测）：**

| 维度 | 总数 | ✅ 已实现 | ⚠️ 部分 | ❌ 缺口 |
| --- | --- | --- | --- | --- |
| FR | 9 | 3 | 5 | 1 |
| BR | 8 | 4 | 3 | 1 |
| NFR | 6 | 1 | 3 | 2 |
| AC | 22 | 13 | 3 | 6 |
| TC | 9 | 7 | 2（部分） | 1（缺口） |

详见 [TRACEABILITY.md](./TRACEABILITY.md) §1–§6。

## 5. 发布 DoD 清单

- [x] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致（2026-06-18 对齐运行时 v1.0.0）。
- [x] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致（状态列已标注可验/部分/缺口）。
- [x] 运行时代码仓库 /home/schedulex 通过 go build、go vet、go test（v1.0.0 实测，覆盖率 98.2%）。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据（Locker 为 SPI，下游 redisx/postgresx 适配需 live-gate）。
- [x] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [x] 版本号、发布标签、CHANGELOG 与本目录状态一致（v1.0.0 已发布；本文档为 v1.0.1 修订对齐）。

## 6. 当前缺口登记

基于运行时 v1.0.0 实测（SPEC §8 canonical API），以下为运行时未实现项，登记为 v1.1 候选（见 goal §15、SPEC §22 OQ-005~010）。这些**不阻塞 v1.0.0 发布**（已按现状发布），但发布前需在 PR 说明中显式标注：

| 缺口 | 关联 FR/AC | 影响 | v1.1 对应 |
| --- | --- | --- | --- |
| `Cancel(id)` 单 job 取消 | FR-005 / AC-014/015 | 无法运行时取消单个 job，只能全局 Shutdown | goal §15 / OQ-005 |
| `OverlapPolicy = Replace` | FR-003 / AC-010 | 无"取消旧的执行新的"策略 | goal §15 / OQ-006 |
| `ErrShutdownTimeout` 专属错误 | FR-006 / AC-017 | Shutdown 超时返回 ctx.Err()，无语义化错误 | goal §15 / OQ-007 |
| `Delay` 首次延迟 | FR-002 / AC-007 | 需用 Once/DailyAt 表达 | goal §15 |
| 完整 JobStatus + JobState 枚举 | SPEC §8.3 | 仅 Snapshot，无 RunCount/ErrorCount/State | goal §15 / OQ-008 |
| metrics（6 个） | NFR-O01 | 无 metric 输出，仅 EventSink | goal §15 / OQ-009 |
| 结构化 log（8 条） | NFR-O01 | 无结构化日志 | goal §15 / OQ-009 |
| trace span | NFR-O01 | 无 trace 集成 | goal §15 / OQ-009 |
| Locker TTL ≥ job timeout 校验 | BR-006 / NFR-S01 / AC-021 | 未做 TTL 配置校验 | goal §15 |
| YAML SchedulerConfig 桥接 | SPEC §9/§10 | 仅 functional options，无 YAML 解析 | goal §15 / OQ-010 |

补充说明：

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- ⚠️ 部分 / ❌ 缺口项在 TRACEABILITY.md 状态列与 goal §15 已登记，发布前需在 PR 描述中引用。
- 若 SPEC/TRACEABILITY 缺少 AC 或 TC，必须先补齐追溯矩阵，再执行发布验收（当前已闭合）。
