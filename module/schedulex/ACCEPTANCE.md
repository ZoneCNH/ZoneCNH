# schedulex v1.0.0 验收清单

- Status: PASS
- Last-Updated: 2026-06-18
- Module-Version: v1.0.0
- Module-State: 本地发布验收通过
- Layer: L1 调度基座
- Runtime-Repo: /home/schedulex
- Runtime-Branch: ci/sre-cicd-pools-20260618
- Source: /home/schedulex release-check evidence, SPEC.md, FEATURES.md

> 本清单记录本轮 `schedulex` v1.0.0 验收结论。验收对象是当前运行时仓库 `/home/schedulex` 的 `AddJob` 版公共 API 与 CI/CD 发布门禁；旧文档中的 `Cancel`、`Replace`、`Schedule` 返回 `JobID` 等能力不作为 v1.0.0 验收项。

## 1. 验收结论

| 项目 | 结论 |
| --- | --- |
| 总体结论 | PASS |
| 发布版本 | `v1.0.0` |
| 本地 release gate | `GOWORK=off make release-check VERSION=v1.0.0` 已通过 |
| 质量评分 | `score=10.0`，门槛 `min=9.8` |
| 主要剩余条件 | tag 发布后执行网络 downstream smoke，验证外部模块可解析 `v1.0.0` |

## 2. 验收命令与证据

| 类别 | 命令 | 结果 | 证据说明 |
| --- | --- | --- | --- |
| Runtime diff hygiene | `cd /home/schedulex && git diff --check` | PASS | 无尾随空格或补丁格式错误 |
| Runtime integration | `cd /home/schedulex && GOWORK=off make integration` | PASS | 渲染 `kernel`、`corekit` 模板并执行测试 |
| Governance all | `cd /home/schedulex && ./scripts/check_governance.sh all` | PASS | CI、规则集、release gates、文档与证据配置一致 |
| Governance p1 | `cd /home/schedulex && ./scripts/check_governance.sh p1` | PASS | CI 包含 lint、release-check 与 required status checks |
| Score gate | `cd /home/schedulex && ./scripts/check_schedulex_score.sh --min 9.8` | PASS | `score=10.0 min=9.8 status=pass` |
| Release check | `cd /home/schedulex && GOWORK=off make release-check VERSION=v1.0.0` | PASS | fmt、vet、lint、test、race、boundary、contracts、docs、security、api、downstream-smoke、integration、governance、score、release-preflight 全链路通过 |
| Module docs hygiene | `cd /home/ZoneCNH && git diff --check -- module/schedulex` | PASS | 本目录文档补丁格式通过 |

## 3. AC 验收登记

| ID | 验收项 | v1.0.0 通过标准 | 验收证据 | 状态 |
| --- | --- | --- | --- | --- |
| AC-001 | 公共 API 快照 | `contracts/public_api.snapshot` 与导出 API 一致 | `api-check`、`contracts` | PASS |
| AC-002 | 任务注册 | 合法 job + trigger 可通过 `AddJob` 注册；重复 job 返回 `ErrJobExists`；非法 job/option 返回对应错误 | unit tests、contracts | PASS |
| AC-003 | 触发确定性 | `Once`、`Every`、`Cron`、`DailyAt` 的 next time 计算可复验 | `trigger-determinism-check` | PASS |
| AC-004 | 时钟与 DST | 注入时钟与时区/DST golden case 不跳触、不重复触发 | `timezone-dst-golden-check` | PASS |
| AC-005 | Misfire 策略 | `skip`、`run_once`、`catch_up` 行为符合契约 | `misfire-contract-check` | PASS |
| AC-006 | Overlap 与并发 | `skip`、`queue_one`、`allow` 与 max concurrency 行为稳定，race 检查通过 | `scheduler-race-check`、unit tests | PASS |
| AC-007 | Shutdown | `Shutdown(ctx)` 幂等；等待运行中任务或遵守 context 超时；无 goroutine leak | `scheduler-leak-check`、race tests | PASS |
| AC-008 | Snapshot | `Snapshot()` 可返回调度器与 job 可审计状态 | contracts、docs-check | PASS |
| AC-009 | EventSink | 调度器级与 job 级事件可注入，事件合约通过测试 | contracts、unit tests | PASS |
| AC-010 | Locker | `Locker`/`Lease` 接口与 job lock 选项可编译、可测试；锁失败按契约跳过或上报 | `lock-interface-check` | PASS |
| AC-011 | 边界与安全 | 标准库 only，无上层域依赖、无 secret、无代码可达漏洞 | `boundary`、`security` | PASS |
| AC-012 | CI/CD 与发布 | required checks、runner pool、release manifest、score 与 release preflight 全部闭合 | `governance-check`、`release-check` | PASS |

## 4. TC 验收登记

| ID | 测试项 | 对应命令/证据 | 状态 |
| --- | --- | --- | --- |
| TC-001 | Trigger 和 cron/interval 触发 | `trigger-determinism-check`、unit tests | PASS |
| TC-002 | Overlap 三类 v1.0 策略 | unit tests、`scheduler-race-check` | PASS |
| TC-003 | Misfire 三类策略 | `misfire-contract-check` | PASS |
| TC-004 | Locker 接口与失败路径 | `lock-interface-check` | PASS |
| TC-005 | Snapshot 可审计状态 | contracts、docs-check | PASS |
| TC-006 | Shutdown、panic 隔离、leak/race | `scheduler-leak-check`、`scheduler-race-check` | PASS |
| TC-007 | EventSink 生命周期事件 | contracts、unit tests | PASS |
| TC-008 | Clock 注入与 DST | `timezone-dst-golden-check` | PASS |
| TC-009 | 重复 job 检测 | unit tests、contracts | PASS |
| TC-010 | Downstream/rendered template smoke | `GOWORK=off make integration`、`downstream-smoke` | PASS；网络解析 smoke 等待 tag 发布后复验 |

## 5. 旧 AC 映射

| 旧口径 | v1.0.0 对齐结论 |
| --- | --- |
| Schedule 返回 JobID | 已由 `AddJob` + `Job.Name()` 取代；返回 JobID 的 API 不属于 v1.0.0 |
| Cancel 单 job | v1.0.0 非目标；当前提供 `Shutdown(ctx)` 与 `Snapshot()` |
| List job | 已由 `Snapshot()` 覆盖可审计读取场景 |
| Stop | 已由 `Shutdown(ctx)` 覆盖 |
| ErrInvalidTrigger / ErrDuplicateJob / ErrShutdownTimeout | v1.0.0 使用 `ErrInvalidOption`、`ErrInvalidJob`、`ErrJobExists` 与 context 超时语义 |
| Delay | 已用 `Once(time.Time)` 覆盖一次性延后触发场景 |
| OverlapReplace | v1.0.0 非目标；当前支持 `OverlapSkip`、`OverlapQueueOne`、`OverlapAllow` |

## 6. 发布 DoD

- [x] `FEATURES.md` 的功能清单与 `/home/schedulex` 当前公共 API、Makefile gate 和 release evidence 对齐。
- [x] `ACCEPTANCE.md` 的 AC/TC 与运行时代码测试、契约、CI/CD 证据一致。
- [x] `/home/schedulex` 通过 fmt、vet、lint、test、race、build、boundary、contracts、docs-check 与 security。
- [x] `/home/schedulex` 通过 integration、governance、p1、p2、score 与 release-preflight。
- [x] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [x] 版本号、release manifest、CI/CD required checks 与本目录状态一致。
- [ ] tag 发布后执行外部网络 downstream smoke 并回填发布后证据。
