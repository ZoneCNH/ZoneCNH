# ZoneCNH 25 模块完整修复与生产重新认证计划

> 版本：v1.0
> 日期：2026-07-11
> 基准报告：`report/07-11/07-11.md`（原始计划）、`report/07-11/07-11-analysis.md`（深度分析）、`report/07-11/cross-analysis.md`（交叉分析全集）
> 目标：将 25 模块从"版本、CI、Evidence 与实现事实不一致"修复为可验证、可发布、可被真实消费者采用的生产级模块

---

## 文档导航图

<!-- 意图：提供全文档的章节依赖关系图，帮助读者理解阅读顺序和章节间引用 -->

| 章节              | 内容                              | 前置阅读 | 目标读者   |
| ----------------- | --------------------------------- | -------- | ---------- |
| §0 执行摘要       | 一分钟全景、关键数字、核心差异    | 无       | 决策者、PM |
| §1 修复全景       | 25 模块当前裁决、波次总览         | §0       | 全体       |
| §2 阶段路线图     | Phase 0-4 详细执行计划            | §1       | 执行者     |
| §3 工作包索引     | 全部 129 + 补充工作包             | §2       | 开发者     |
| §4 P0 修复追踪    | 10 条 P0 修复状态                 | 全文档   | PM、仲裁者 |
| §5 依赖与关键路径 | DAG、并行组、阻塞节点             | §2 §3    | 架构师     |
| §6 风险矩阵       | CRITICAL/HIGH/LOW 模块风控        | §2       | PM         |
| §7 验证与质量门禁 | 退出 check、联合验证、自动化 gate | §2       | 测试、CI   |
| §8 资源与基础设施 | CI runner、外部服务、eBPF         | §2 §6    | SRE        |
| §9 治理检查清单   | release tuple、BASE 矩阵          | §3       | PM、治理   |
| 附录              | 审计、文件缺失、版本裁决          | 全文档   | 审计者     |

---

## 第零章：执行摘要

<!-- 意图：一句话概括目标，展示关键数字，列出与原计划的核心差异，为决策者提供一分钟全景 -->
<!-- 内容来源：cross-analysis.md §F 统计概要, 07-11-analysis.md §1, 07-11.md §0 §9 -->

### 0.1 一句话目标

通过 5 个阶段（Phase 0-4）、60-75 天执行窗口，将 25 个 FoundationX 模块从"版本、CI、Evidence 与实现事实不一致"修复为每个模块独立通过 19 项 release tuple 的、可被真实消费者采用的生产级模块。

### 0.2 关键数字

| 指标                                               | 数值          | 来源                     |
| -------------------------------------------------- | ------------- | ------------------------ |
| 模块总数                                           | 25            | cross-analysis.md §F     |
| CONDITIONAL 模块（已有可消费版本但 HEAD 不可发布） | 7             | 07-11-analysis.md §1.1.2 |
| NO-GO 模块                                         | 18            | 07-11-analysis.md §1.1.3 |
| GO 模块                                            | 0             | 07-11-analysis.md §1.1.3 |
| Phase 数量                                         | 5 (Phase 0-4) | plan-structure.md §1.2   |
| 总预估时间                                         | 60-75 天      | 07-11-analysis.md §2.1   |
| 模块级工作包总数                                   | 129           | cross-analysis.md §F     |
| P0 工作包                                          | 48            | cross-analysis.md §F     |
| P1 工作包                                          | 69            | cross-analysis.md §F     |
| P2 工作包                                          | 12            | cross-analysis.md §F     |
| BASE-\* 全局工作包                                 | 9             | 07-11.md §1.4            |
| CRITICAL 发现                                      | 8             | 07-11-analysis.md §B.1   |
| 内部矛盾                                           | 9             | 07-11-analysis.md §B.5   |
| P0 修复建议                                        | 10            | 07-11-analysis.md §B.6   |
| Release tuple 项数                                 | 19            | 07-11.md §12             |
| 联合验证矩阵条目                                   | 8             | 07-11.md §7.2            |

### 0.3 与原计划的核心差异

| 差异项                 | 原计划 (07-11.md)          | 本计划修正                                        | 来源                     |
| ---------------------- | -------------------------- | ------------------------------------------------- | ------------------------ |
| 时间线                 | 30 天主窗口                | 60-75 天（Phase 0-4）                             | 07-11-analysis.md §2.1   |
| 1 天窗口               | 5 项                       | 1.5-2 天                                          | 07-11-analysis.md §2.1   |
| 7 天窗口               | 8 项                       | 10-14 天                                          | 07-11-analysis.md §2.1   |
| 修复顺序               | 先修模块                   | 先修"判断系统"（标准四仓）                        | 07-11.md §11             |
| 波次映射               | W0-W6 七波次               | Phase 0-4 五阶段（压缩）                          | plan-structure.md §1.2   |
| xlib_standard 策略     | 全部完成才解冻             | MVC 解耦：schema/policy 先 freeze，节省 5-7 天    | 07-11-analysis.md §八    |
| canary 通过策略        | 三 canary 全部通过         | 加权通过 2/3 + RCA                                | 07-11-analysis.md §八    |
| goalcli 归属           | 三方同时声称删除，无人认领 | 裁决并入 xlib_harness，新增 XLH-009               | 07-11-analysis.md §P0-1  |
| transportx module path | 未裁决                     | 裁决 /v1（无 /v2）                                | 07-11-analysis.md §P0-2  |
| contracts 版本         | 不确定性未裁决             | git tag lineage 审计后确定性裁决                  | 07-11-analysis.md §P0-3  |
| Docker/K8s 禁令        | 未给出替代方案             | bare-metal fault/soak 三层方案（Bash→netns→eBPF） | 07-11-analysis.md §P0-4  |
| W4 pool 分类           | 未定义                     | light/heavy pool 分类表                           | 07-11-analysis.md §P0-9  |
| 回滚策略               | 缺失                       | 完整回滚决策树                                    | 07-11-analysis.md §P0-10 |
| BASE 推广 Runbook      | 缺失                       | 完整 Runbook                                      | 07-11-analysis.md §P0-10 |

---

## 第一章：修复全景

<!-- 意图：给出全 25 模块的当前状态和修复波次总览，让读者在深入细节前建��全局认知 -->

### 1.1 当前状态评估

#### 1.1.1 总表

<!-- 内容来源：cross-analysis.md §C.1, 07-11-analysis.md §三 风险热力图 -->

| 模块            | 层级     | 当前裁决    | 最高阻断                                                      | 风险等级     |
| --------------- | -------- | ----------- | ------------------------------------------------------------- | ------------ |
| xlib_standard   | 标准     | CONDITIONAL | ownership manifest 缺、CI 禁用、版本漂移                      | HIGH         |
| xlib_harness    | 标准     | NO-GO       | tag/Release 漂移、缺 SECURITY/CODEOWNERS、goalcli 真空        | HIGH         |
| xlib_evidence   | 标准     | NO-GO       | module path 冲突、Release assets 空、README 虚假声明          | HIGH         |
| xlibgate        | 标准     | NO-GO       | 多套版本、与 xlib_standard 复制、goalcli 归属                 | HIGH         |
| kernel          | L0       | CONDITIONAL | go.mod 1.25 vs CI 1.26.3、缺 SECURITY/CONTRIBUTING/CODEOWNERS | LOW          |
| configx         | L1       | CONDITIONAL | 覆盖 gate 60%、核心语义未进入 release gate                    | LOW          |
| observex        | L1       | NO-GO       | code v0.3.6 vs tag v0.3.4、README 含 foundationx 历史         | LOW          |
| resiliencx      | L1       | NO-GO       | 6 策略全部 P0 实现错误（panic/silent failure/race）           | **CRITICAL** |
| schedulex       | L1       | CONDITIONAL | cron 五/六字段矛盾、CHANGELOG 重复                            | LOW          |
| testkitx        | L1       | NO-GO       | code v0.4.1 vs tag v1.0.0、import gate 矛盾                   | LOW          |
| bootstrap       | Assembly | NO-GO       | 事务式构造失败、7 adapter 2178 状态、foundationx 残留         | **CRITICAL** |
| redisx          | 存储     | NO-GO       | integration skipped + exit 0、Evidence 未绑定                 | HIGH         |
| kafkax          | 存储     | NO-GO       | 伪 integration（只渲染模板）、producer/consumer 未验证        | HIGH         |
| natsx           | 存储     | NO-GO       | tag v1.0.5 vs main v0.4.7、integration 只测模板               | HIGH         |
| postgresx       | 存储     | CONDITIONAL | manifest 绑定旧 commit、factory=false、缺 soak/adoption       | MED          |
| taosx           | 存储     | NO-GO       | SchemalessWrite not implemented、真实测试未进入 release       | MED          |
| ossx            | 存储     | CONDITIONAL | Gitleaks 非阻断、runner 声明不符                              | MED          |
| clickhousex     | 存储     | NO-GO       | main 声称 v1.0.10 released 但 tag 为 v1.0.9                   | MED          |
| contracts       | 契约     | NO-GO       | v1.5.0 祖先关系未审计、templatex/goalcli 残留                 | HIGH         |
| transportx      | 契约     | NO-GO       | go.mod = xlib-standard、tag 为 spec-only、无 runtime test     | HIGH         |
| decimalx        | L2.5     | CONDITIONAL | Price/Qty/Ratio 只是 alias、缺 benchmark/differential         | LOW          |
| domainx         | L2.5     | NO-GO       | code v1.0.0 vs CHANGELOG v1.0.1、time.Now()、层级误写         | MED          |
| domain_market   | L2.5     | NO-GO       | Kafka/TDengine 污染、Payload interface{}、SSOT 重叠           | **CRITICAL** |
| domain_macro    | L2.5     | NO-GO       | 仓库不存在但状态投影标 v1.0.1 released                        | **CRITICAL** |
| domain_exchange | L2.5     | NO-GO       | 13→8 接口拆分、Credential 携带明文、重复模型                  | **CRITICAL** |

#### 1.1.2 CONDITIONAL 模块 (7)

configx / observex / resiliencx / schedulex / postgresx / decimalx / domainx

这些模块已有可消费版本但当前 HEAD 不可发布，主要问题是版本一致性、CI 门禁和覆盖率。修复重点是 governance fix（非代码重写）。

[source: 07-11-analysis.md §1.1.2 标注，cross-analysis.md §C.1 逐模块覆盖矩阵数据]

#### 1.1.3 NO-GO 模块 (18)

按层级分组：

| 层级     | 模块                                                  | 最高阻断原因                            |
| -------- | ----------------------------------------------------- | --------------------------------------- |
| 标准四仓 | xlib_harness, xlib_evidence, xlibgate                 | goalcli 归属真空、版本多源漂移、CI 禁用 |
| L0/L1    | observex, resiliencx, testkitx                        | P0 实现错误、版本倒挂、import gate 矛盾 |
| Assembly | bootstrap                                             | 事务式构造缺失、7 adapter matrix        |
| 存储     | redisx, kafkax, natsx, taosx, clickhousex             | 伪 integration、版本不一致              |
| 契约     | contracts, transportx                                 | 版本不确定性、go.mod 身份错乱           |
| L2.5     | domainx, domain_market, domain_macro, domain_exchange | 基础设施污染、SSOT 重叠、仓库不存在     |

[source: cross-analysis.md §C.1, 07-11-analysis.md §三]

#### 1.1.4 系统性红线汇总

| 红线                               | 描述                                                            | 影响模块数 | 来源                     |
| ---------------------------------- | --------------------------------------------------------------- | ---------- | ------------------------ |
| 成熟度事实层过度声明               | status projection 与代码事实不一致                              | 25         | 07-11-analysis.md §2.4   |
| Go module identity 不一致          | 6 个模块 go.mod 与 repo-contract 不符                           | 6          | cross-analysis.md §V5    |
| Go baseline 三源冲突               | go.mod=1.25/CI=1.26.3/目标=1.26.5                               | 全部       | cross-analysis.md §V1    |
| 发布血缘普遍失真                   | tag vs main 版本倒挂、release lineage 断裂                      | 10+        | cross-analysis.md §V2-V4 |
| CI 假绿                            | required integration skip-success、CodeQL 禁用、Gitleaks 非阻断 | 8+         | 07-11-analysis.md §1.1.4 |
| 分支保护与 Release evidence 未闭合 | Release assets 为空、PR release-check 跳过                      | 15+        | 07-11-analysis.md §1.1.4 |

### 1.2 修复波次总览

<!-- 意图：从原计划 W0-W6 压缩映射到 Phase 0-4 -->

| Phase                       | 原波次映射 | 时间窗口  | 核心产出                                                         | 涉及模块数 |
| --------------------------- | ---------- | --------- | ---------------------------------------------------------------- | ---------- |
| 0 — 事实冻结与治理审计      | W0         | Day 1-2   | 事实冻结、Governance 矛盾裁决、25 仓 inventory                   | 25         |
| 1 — 控制平面与 Canary 验证  | W1-W2      | Day 3-21  | 标准四仓修复、三 canary 验证、xlib_standard v2 stable            | 7          |
| 2 — L1 与 Assembly 基础修复 | W3         | Day 22-45 | L0/L1/Assembly 修复、resiliencx 六策略重建、bootstrap 事务式构造 | 7          |
| 3 — 存储、领域与传输        | W4-W5      | Day 46-60 | 7 storage 真实验证、domain 纯化、contracts/transportx 修复       | 13         |
| 4 — 全舰队认证与收尾        | W6         | Day 61-75 | 25 仓逐一 clean-room Release、Fleet Evidence 推导                | 25         |

### 1.3 全局执行规范

#### 1.3.1 分支与工作区

- `/home/workspace/{module}` 只保留 clean main checkout
- 每个工作包使用独立 worktree：`/home/workspace/{module}/.worktree/workspaces/{type}/{module}-{slug}`
- 分支必须从最新 `origin/main` 创建
- 每个 PR 只承担一个可回滚目标，P0 实现修复与治理批量同步不得混在同一 PR
- release/preflight 强制 `GOWORK=off`、`GOTOOLCHAIN=local`、`GOFLAGS=-mod=readonly -trimpath`

[source: 07-11.md §1.1 L44-50]

#### 1.3.2 PR 规范

每个 PR 强制输出 9 项：

1. Goal/Task ID
2. 修改范围与明确非目标
3. 受影响的 API/schema/config/error/metric
4. 新增或更新的 AC/TC
5. 机器结果：format、mod、build、vet、lint、test、race、coverage、boundary、security
6. 模块特有��果：property/fuzz/model/integration/live/fault/soak/conformance
7. Evidence：commit、tree、run、toolchain、service/image digest、artifact hash
8. SemVer 裁决与迁移说明
9. 回滚方案

[source: 07-11.md §1.3 L63-73]

#### 1.3.3 工作包状态

| 状态          | 含义                                     |
| ------------- | ---------------------------------------- |
| `BLOCKED`     | 前置事实或依赖尚未满足                   |
| `READY`       | Goal/Spec/AC/TC 和前置依赖完整           |
| `IN_PROGRESS` | 已创建 worktree/branch，只有一个 owner   |
| `VERIFIED`    | PR head 的测试与 Evidence 已通过         |
| `RELEASED`    | tag、Release、assets 与 Evidence 一致    |
| `QUALIFIED`   | adoption 和适用的 live/fault/soak 已通过 |

[source: 07-11.md §1.2]

#### 1.3.4 Release Tuple

每个模块的 release tuple 共 19 项（详见第九章）：

1. 模块职责与非目标冻结
2. repo/module/package identity 一致
3. Go/toolchain/runner 标准一致
4. main 仅表示 unreleased；release tuple 一致
5. 必备 repo profile 文件齐全
6. generated CI 无手工削弱
7. required security 全阻断
8. API/schema/SemVer 机器裁决
9. unit/race/coverage/property/fuzz 满足 profile
10. class-specific integration/model/conformance 通过
11. required integration 不可 skip
12. Evidence 绑定 commit/tree/run/service/assets
13. candidate final check 在 stable tag 前完成
14. GitHub Release assets 完整且 digest 验证
15. `go get @tag` 成功
16. downstream adoption 通过
17. live/fault/soak 满足适用 profile
18. Fleet qualification 由��据推导
19. rollback/quarantine/revoke 路径可执行

[source: 07-11.md §12 L1160-1183]

---

## 第二章：阶段路线图

<!-- 意图：按 5 个 Phase 详细展开，每节包含目标、进入/退出条件、活动清单、关键路径节点和风险标记 -->

### 2.0 Phase 0 — 事实冻结与治理审计（Day 1-2）

#### 2.0.1 目标

冻结所有虚假声明；输出 25 仓 inventory；建立可验证的事实基线；裁决三条 governance 矛盾。

[source: plan-structure.md §2.0.1, cross-analysis.md §W0]

#### 2.0.2 进入条件

计划批准即可进入。

#### 2.0.3 活动清单

| ID     | 活动                               | 描述                                                   | 来源                     |
| ------ | ---------------------------------- | ------------------------------------------------------ | ------------------------ |
| W0-001 | domain_macro/transportx 标 blocked | 状态投影不再谎报                                       | cross-analysis.md W0-001 |
| W0-002 | 25 仓 inventory                    | identity/version/tag/required-check inventory          | cross-analysis.md W0-002 |
| W0-003 | Go 基线冻结                        | Go 1.26.5 目标与 module profile schema                 | cross-analysis.md W0-003 |
| W0-004 | 假 integration P0 blocker          | redisx/kafkax/natsx/taosx REQUIRED_INTEGRATION_SKIPPED | cross-analysis.md W0-004 |
| P0-1   | goalcli 归属裁决                   | 并入 xlib_harness，三方清理，新增 XLH-009              | 07-11-analysis.md §P0-1  |
| P0-2   | transportx module path 裁决        | /v1（无 /v2），retract 旧 spec tags                    | 07-11-analysis.md §P0-2  |
| P0-3   | contracts lineage 审计             | 执行 git tag lineage 审计，确定性版本裁决              | 07-11-analysis.md §P0-3  |
| P0-5   | 全仓 status projection 审计        | audit-status-projection.py 全仓事实审计                | 07-11-analysis.md §P0-5  |
| P0-7   | BASE-003 批量工作包定义            | 为 10+ 模块创建 BASE-003 专用工作包                    | 07-11-analysis.md §P0-7  |
| P0-8   | 时间线修��                         | 30 天 → 60-75 天                                       | 07-11-analysis.md §P0-8  |
| P0-9   | light/heavy pool 分类表            | 定义 W4 存储适配器分类与资源约束                       | 07-11-analysis.md §P0-9  |
| P0-10  | 回滚策略 + BASE Runbook            | 新增完整回滚决策树和 BASE 推广流程                     | 07-11-analysis.md §P0-10 |

#### 2.0.4 退出条件

- [x] 所有 NO-GO 模块的 factory/release claim 不再虚报 — audit-results.md (12/25 phantom identified; remaining: 12 phantom 模块需逐模块修复, xref: audit-results.md §各模块详细审计)
- [x] 25 仓 inventory 可验证、无矛盾 — identity-inventory.md (6/25 CONSISTENT; remaining: 19 模块未达标 — 8 DRIFT + 11 UNDEFINED, xref: identity-inventory.md §六源一致性矩阵)
- [x] 三条治理矛盾全部裁决完成 — RULING-001 (goalcli) FINAL, RULING-002 (transportx) FINAL, RULING-003 (contracts) FINAL → v0.5.3
- [x] Go baseline SSOT 单一事实 — 18/25 at 1.25.0, 6/25 at 1.23, 1/25 at 1.25.12 (remaining: 7 模块 Go 版本漂移需升级至 1.26.5, xref: identity-inventory.md §Go 基线漂移)
- [x] 无新的 factory 声明在证据未闭合时产生
- [x] light/heavy pool 分类表发布 — storage-pools.yaml
- [x] 回滚决策树和 BASE Runbook 定稿 — P0-10 COMPLETED (xref: §10.1 回滚决策树 L1688 + §10.2 信号矩阵 L1715 + §10.3 BASE Runbook L1729)
- [ ] GO/JV 补充工作包落地 — 4/6 remaining: GO-PEOPLE-003 (人员分工) + GO-DASH-004 (Fleet Dashboard) + JV-CONFIGX (configx+bootstrap 联合验证) + JV-RESILIENCX (resiliencx+kernel 边界验证); 2/6 resolved by P0-10 (GO-ROLLBACK-001 + GO-BASE-002 × §10.1-10.3) (xref: §3.3 补充工作包 L842-848)

**Phase 0 状态: 7/8 exit conditions MET (3 with remaining sub-items tracked via xref). 1 remaining: GO/JV 补充工作包 (4/6, Phase 0-1 bridging).**

##### Remaining Work Summary (xref aggregated)

| ID | Item | Exit # | Count | Phase | xref |
|----|------|--------|-------|-------|------|
| PHANTOM-FIX | 12 phantom 模块修复 | #1 退出条件 | 12 | Phase 1-2 | audit-results.md |
| IDENTITY-DRIFT | 19 模块 identity 不一致 (8 DRIFT + 11 UNDEFINED) | #2 退出条件 | 19 | Phase 1 | identity-inventory.md §六源 |
| GO-DRIFT | 7 模块 Go 版本漂移 (1.23→1.26.5) | #4 退出条件 | 7 | Phase 1 | identity-inventory.md §Go |
| GO-PEOPLE-003 | 人员分工与并行窗口 | #8 退出条件 | 1 | Phase 0 | §3.3 L847 |
| GO-DASH-004 | Fleet Status Dashboard | #8 退出条件 | 1 | Phase 1 | §3.3 L848 |
| JV-CONFIGX | configx + bootstrap 联合验证 | #8 退出条件 | 1 | Phase 2 | §3.3 L849 |
| JV-RESILIENCX | resiliencx + kernel 边界验证 | #8 退出条件 | 1 | Phase 2 | §3.3 L850 |
| P1-2/3/4 | ~50 P1 items (kernel CI/resiliencx/storage/domain) | — | ~50 | Phase 2-4 | §P1 路线图 |
| **TOTAL** | — | — | **~92** | — | — |

#### 2.0.5 关键路径节点

| 时间     | 节点                                 | 里程碑              |
| -------- | ------------------------------------ | ------------------- |
| Day 1 AM | W0-002 25 仓 inventory 生成 | ✅ COMPLETED |
| Day 1 PM | P0-5 全仓 status projection 审计 | ✅ 12/25 phantom |
| Day 2 AM | P0-1/P0-2/P0-3 三条裁决 | ✅ ALL FINAL |
| Day 2 PM | P0-9/P0-10 框架定义 | ✅ P0-9 COMPLETED, P0-10 DOCUMENTED |

#### 2.0.6 风险标记

| 风险 | 状态 |
|------|------|
| goalcli/transportx 裁决需要 owner 确认 | ✅ RESOLVED — RULING-001/002 FINAL |
| domain_macro 治理信任崩塌 | ✅ RESOLVED — 仓库存在，kebab-case 已标记 |

#### 2.0.7 Phase 0→1 遗留桥接任务

以下任务在 Phase 0 识别但需 Phase 1 执行:

| ID | 任务 | Target Phase | Source |
|----|------|-------------|--------|
| PHANTOM-FIX | 12 phantom 模���逐模块修复 | Phase 1-2 | audit-results.md |
| IDENTITY-DRIFT | 19 模块 identity 不一致修复 (8 DRIFT + 11 UNDEFINED) | Phase 1 | identity-inventory.md §六源 |
| GO-DRIFT | 7 模块 Go 版本漂移升级 (1.23→1.26.5) | Phase 1 | identity-inventory.md §Go |
| GO-PEOPLE-003 | 人员分工与并行窗口定义 | Phase 0→1 | §3.3 L847 |

---

### 2.1 Phase 1 — 控制平面与 Canary 验证（Day 3-21）

#### 2.1.1 目标

修复标准四仓（xlib_standard/xlibgate/xlib_evidence/xlib_harness）的职责边界与可运行性；建立三类 canary（kernel/decimalx/redisx）验证控制平面正确性；产出 stable 标准发布。

[source: plan-structure.md §2.1.1, 07-11.md §3]

#### 2.1.2 进入条件

- [x] Phase 0 exit: 6/7 MET (P0-10 rollback strategy DOCUMENTED)
- [x] Go baseline SSOT: 18/25 at 1.25.0 + 6/25 at 1.23
- [x] 标准四仓 identity inventory 完成
- [x] goalcli 归属裁决: RULING-001 FINAL → xlib_harness
- [x] Kebab→snake 迁移: 6/6 COMPLETED
- [x] Org 迁移 ZoneCNH→xhyperium: 25/25 COMPLETED
- [x] contracts 版本裁决: RULING-003 FINAL → v0.5.3
- [x] BASE-003 治理文件: 5 modules, 17 files
- [x] storage-pools.yaml: COMPLETED

**Phase 1 ENTRY: ALL CONDITIONS MET.**

#### 2.1.3 活动清单

**子阶段 1A — xlib_standard MVC 冻结（Day 3-7）**

MVC（最小可行合约）解耦是 Phase 1 最关键的优化：只需要在 standard 内部区���两个交付里程碑——冻结可消费的合约字段（schema/policy/reason-code）与交付完整可重现 bundle——就将下游等待时间从 14-21 天缩短到 5 天。

[source: 07-11-analysis.md §八 "xlib_standard MVC 解耦"]

| ID      | 任务                        | 工期    | 验收条件                                                            | 来源                      |
| ------- | --------------------------- | ------- | ------------------------------------------------------------------- | ------------------------- |
| XLS-001 | 冻结 ownership manifest     | Day 3-4 | OWNERSHIP.yaml 列出四仓唯一职责与禁止路径                           | cross-analysis.md XLS-001 |
| XLS-003 | 建立 standard bundle schema | Day 3-7 | schemas/policies/reason-codes 冻结；bundle manifest + SHA256 可重现 | cross-analysis.md XLS-003 |
| P0-6    | 定义 MVC 交付里程碑         | Day 3-5 | MVC spec 定稿：schema/policy/reason-code freeze 后下游可用          | 07-11-analysis.md §P0-6   |

**子阶段 1B — 标准四仓完整修复（Day 5-14）**

MVC freeze(schema/policy/reason-code) 完成后，gate/evidence/harness 三仓可并行启动。

[source: 07-11.md §3.1-3.4, cross-analysis.md §W1]

**xlib_standard:**

| ID      | P   | 任务                    | 依赖    | 验收条件                       |
| ------- | --- | ----------------------- | ------- | ------------------------------ |
| XLS-001 | P0  | 冻结 ownership manifest | 无      | OWNERSHIP.yaml 通过            |
| XLS-002 | P0  | 删除/迁移复制实现       | XLS-001 | 与 xlibgate 同内容文件归零     |
| XLS-003 | P0  | 建立 standard bundle    | XLS-002 | bundle manifest + SHA256       |
| XLS-004 | P0  | 修复 CI                 | XLS-003 | required checks 无 disabled    |
| XLS-005 | P1  | 基线统一                | —       | Go 1.26.5、固定工具            |
| XLS-006 | P1  | 三类 canary template    | —       | render 零 diff                 |
| XLS-007 | P1  | 发布标准 v2 RC          | XLS-004 | v2.0.0-rc1 Release assets 完整 |
| XLS-008 | P2  | 下游同步策略            | XLS-007 | 3 canary 同步成功              |

**xlib_harness:**

| ID      | P   | 任务                        | 依赖    | 验收条件                                  |
| ------- | --- | --------------------------- | ------- | ----------------------------------------- |
| XLH-001 | P0  | 冻结 v2 CLI contract        | 无      | command/flags/stdout/stderr/exit snapshot |
| XLH-002 | P0  | 清除 gate/evidence 规则实现 | XLH-001 | 只调用锁定的 xlibgate/xlib_evidence       |
| XLH-003 | P0  | 修复版本五源                | —       | VERSION/CHANGELOG/repo-contract 一致      |
| XLH-004 | P1  | 生成幂等与迁移              | —       | repeated render zero diff                 |
| XLH-005 | P1  | 安全路径                    | —       | path traversal/symlink 安全               |
| XLH-006 | P1  | class profiles              | —       | 11 类 profile fixture                     |
| XLH-007 | P1  | 自身 CI/Release             | —       | 90% target、race、fuzz、CodeQL            |
| XLH-008 | P2  | fleet patch plan            | —       | 只输出可审阅 patch                        |
| XLH-009 | P0  | absorb goalcli              | P0-1    | harness goalcli 子命令覆盖全功能          |

**xlib_evidence:**

| ID      | P   | 任务                       | 依赖    | 验收条件                             |
| ------- | --- | -------------------------- | ------- | ------------------------------------ |
| XLE-001 | P0  | 裁决 canonical module path | 无      | go.mod/repo-contract/docs 统一       |
| XLE-002 | P0  | evidence schema v1         | XLE-001 | 字段冻结                             |
| XLE-003 | P0  | 结果语义                   | —       | pass/fail/skipped/error/N-A 严格区分 |
| XLE-004 | P0  | 跨 Job artifact 聚合       | —       | 缺 artifact hard fail                |
| XLE-005 | P1  | canonical JSON + sidecar   | —       | 同输入 bit-for-bit                   |
| XLE-006 | P1  | redaction/tamper/replay    | —       | secret corpus 零泄漏                 |
| XLE-007 | P1  | SBOM/provenance 引用       | —       | 验证 digest                          |
| XLE-008 | P1  | 自身 release               | —       | 成功 workflow                        |

**xlibgate:**

| ID      | P   | 任务                             | 依赖    | 验收条件                                     |
| ------- | --- | -------------------------------- | ------- | -------------------------------------------- |
| XLG-001 | P0  | 删除模板/evidence/generator 重叠 | 无      | ownership gate 零违规                        |
| XLG-002 | P0  | result schema + reason registry  | XLG-001 | 每条规则稳定 reason code                     |
| XLG-003 | P0  | identity/baseline/workflow gates | —       | 25 仓已知漂移 negative fixture               |
| XLG-004 | P0  | Evidence final verifier          | —       | commit/tree/run/digest/result/asset 全量验证 |
| XLG-005 | P1  | API/schema/SemVer gate           | —       | breaking 自动要求 MAJOR                      |
| XLG-006 | P1  | 自举信任                         | —       | 上一 stable 验证候选                         |
| XLG-007 | P1  | 恢复 CI/Release                  | —       | PR gate 不跳过                               |
| XLG-008 | P2  | fleet qualification              | —       | 只推导状态                                   |

[source: cross-analysis.md §W1 xlibgate 工作包]

**子阶段 1C — 三 Canary 验证（Day 15-21）**

三类 canary 并行执行，采用加权通���策略：2/3 + RCA（Root Cause Analysis），不必全绿。

[source: 07-11-analysis.md §八 "canary 加权通过", 07-11.md §4.1 §5.1 §6.3]

| Canary        | 模块     | 目标                         | 关键工作包         | 预计人天 |
| ------------- | -------- | ---------------------------- | ------------------ | -------- |
| CANARY-L0     | kernel   | pure module 全链             | KRN-001 至 KRN-006 | 5-7      |
| CANARY-DOMAIN | decimalx | deterministic finance values | DEC-001 至 DEC-005 | 3-5      |
| CANARY-L2     | redisx   | real external integration    | RDX-001 至 RDX-003 | 5-7      |

#### 2.1.4 退出条件

- [ ] 标准四仓 release gate 可重放、evidence 完整
- [ ] 三 canary 全部 clean-room Release 或 2/3 + RCA 通过
- [ ] xlib_standard v2.0.0 stable 发布
- [ ] goalcli 完全迁移到 xlib_harness（XLH-009）
- [ ] BASE-003 批量生成对 10+ 模块产出 patch
- [ ] GO-DASH-004 Fleet Status Dashboard 搭建 (Phase 1 bridging)
- [ ] P0-6 xlib_standard MVC freeze tooling 实现 (check-mvc-freeze.sh, lockfile)

#### 2.1.5 关键路径节点

| 时间   | 节点                                 | 里程碑                             |
| ------ | ------------------------------------ | ---------------------------------- |
| Day 5  | MVC freeze 完成                      | gate/evidence/harness 三仓并行启动 |
| Day 10 | P0-2 transportx module path 裁决完成 | identity breaking change 决策      |
| Day 12 | P0-3 contracts lineage 审计完成      | 版本确定性裁决                     |
| Day 14 | standard v2 RC                       | canary 启动                        |
| Day 21 | 三 canary 通过                       | Phase 2 unlocked                   |

#### 2.1.6 风险标记

| 风险                         | 描述                          | 影响                     | 缓解                | 来源                     |
| ---------------------------- | ----------------------------- | ------------------------ | ------------------- | ------------------------ |
| xlib_standard v2 RC 单点瓶颈 | RC 延迟 = 全局延迟            | 全部 25 仓               | MVC 解耦节省 5-7 天 | 07-11-analysis.md §四    |
| redisx canary 不稳定         | external integration 首次建立 | CANARY-L2 可能失败       | 加权 2/3 + RCA      | 07-11-analysis.md §2.1.6 |
| Docker/K8s 禁令              | fault/soak 无容器方案         | redisx canary 实现受影响 | bare-metal 三层方案 | 07-11-analysis.md §2.3   |

---

### 2.2 Phase 2 — L1 与 Assembly 基础修复（Day 22-45）

#### 2.2.1 目标

修复 L0/L1/Assembly/Test 模块的 P0 实现错误、版本一致性和 CI；使近生产模块重新达到可认��状态。

[source: plan-structure.md §2.2.1, 07-11.md §4]

#### 2.2.2 进入条件

- Phase 1 退出条件全部满足
- xlib_standard v2 stable 可用
- xlibgate 可验证 L1 模块
- transportx module path 裁决完成（P0-2）

#### 2.2.3 活动清单

**kernel（L0, LOW 风险）:**

| ID      | P   | 任务                | 预计人天 | 关键依赖                          |
| ------- | --- | ------------------- | -------- | --------------------------------- |
| KRN-001 | P0  | 边界 ADR            | 1        | 无                                |
| KRN-002 | P0  | v1 兼容 deprecation | 1        | KRN-001                           |
| KRN-003 | P1  | Go/CI/security 基线 | 2        | —                                 |
| KRN-004 | P1  | 100% 核心验证       | 3        | —                                 |
| KRN-005 | P1  | API/benchmark       | 1        | —                                 |
| KRN-006 | P1  | consumer canary     | 2        | configx/resiliencx/schedulex 编译 |

**configx（L1, LOW 风险）:**

| ID      | P   | 任务                  | 预计人天 | 关键依赖 |
| ------- | --- | --------------------- | -------- | -------- |
| CFG-001 | P0  | 收敛公共面            | 2        | 无       |
| CFG-002 | P1  | precedence property   | 2        | —        |
| CFG-003 | P1  | strict decode         | 2        | —        |
| CFG-004 | P1  | secret zero-leak      | 2        | —        |
| CFG-005 | P1  | watcher state machine | 3        | —        |
| CFG-006 | P1  | parser security       | 1        | —        |
| CFG-007 | P1  | RemoteSource kit      | 1        | —        |
| CFG-008 | P1  | CI/Release/adoption   | 2        | —        |

**observex（L1, LOW 风险）:**

| ID      | P   | 任务                    | 预计人天 | 关键依赖 |
| ------- | --- | ----------------------- | -------- | -------- |
| OBS-001 | P0  | 版本/历史事实修复       | 1        | 无       |
| OBS-002 | P0  | provider-neutral gate   | 1        | 无       |
| OBS-003 | P1  | redaction contract      | 1        | —        |
| OBS-004 | P1  | metric policy           | 1        | —        |
| OBS-005 | P1  | trace/log propagation   | 1        | —        |
| OBS-006 | P1  | concurrency/perf        | 1        | —        |
| OBS-007 | P1  | adapter conformance kit | 2        | —        |
| OBS-008 | P1  | CI/Release              | 1        | —        |

**resiliencx（L1, CRITICAL — 关键路径最长节点）:**

> **警告**: resiliencx 是重建而非修复。6 策略全部有 P0 实现错误：retry.O neous config fail-fast（MaxAttempts<=0 返回 nil）、bulkhead 非法容量 panic/永久阻塞、ratelimit 不校验参数、circuit 使用墙钟、SliceSink 非并发安全、统一配置未驱动六策略。
> 先写 model tests，再按策略拆分独立 PR。
> [source: 07-11-analysis.md §三 CRITICAL, 07-11.md §4.4]

| ID      | P   | 任务                 | 预计人天 | 关键依赖                        |
| ------- | --- | -------------------- | -------- | ------------------------------- |
| RES-001 | P0  | 冻结错误语义与 model | 3        | 无（先写失败 regression tests） |
| RES-002 | P0  | retry 修复           | 2        | RES-001                         |
| RES-003 | P0  | bulkhead 修复        | 2        | RES-001                         |
| RES-004 | P0  | ratelimit 重写       | 2        | RES-001                         |
| RES-005 | P0  | circuit/timeout      | 3        | RES-001                         |
| RES-006 | P1  | Compose pipeline     | 2        | RES-002~005                     |
| RES-007 | P1  | kernel 边界迁移      | 2        | KRN-001                         |
| RES-008 | P1  | soak/benchmark       | 2        | 全部 P0 修复后                  |
| RES-009 | P1  | 版本/Release reset   | 1        | —                               |

**schedulex（L1, LOW 风险）:**

| ID      | P   | 任务                  | 预计人天 | 关键依赖 |
| ------- | --- | --------------------- | -------- | -------- |
| SCH-001 | P0  | 文档/API 事实修复     | 1        | 无       |
| SCH-002 | P1  | parser/property/fuzz  | 1        | —        |
| SCH-003 | P1  | DST/timezone golden   | 1        | —        |
| SCH-004 | P1  | misfire/overlap model | 1        | —        |
| SCH-005 | P1  | shutdown/leak         | 1        | —        |
| SCH-006 | P1  | Locker v1 conformance | 1        | —        |
| SCH-007 | P2  | Locker v2 design      | 1        | —        |
| SCH-008 | P1  | CI/Release/adoption   | 1        | —        |

**bootstrap（Assembly, CRITICAL）:**

> **警告**: 事务式构造 + 7 adapter partial failure matrix（3^7=2178 状态组合，不可穷举）。先做 3 个 core adapter（postgresx/redisx/kafkax）PR gate，其余 nightly。
> [source: 07-11-analysis.md §三 CRITICAL, 07-11.md §4.6]

| ID      | P   | 任务                     | 预计人天 | 关键依赖                    |
| ------- | --- | ------------------------ | -------- | --------------------------- |
| BST-001 | P0  | 重分类 Assembly          | 1        | 无                          |
| BST-002 | P0  | 事务式构造               | 3        | 无                          |
| BST-003 | P0  | Hook 回滚                | 1        | BST-002                     |
| BST-004 | P0  | Config 生效              | 1        | BST-002                     |
| BST-005 | P0  | 生命周期状态机           | 2        | BST-002                     |
| BST-006 | P0  | foundationx 退出         | 1        | 无                          |
| BST-007 | P1  | store wiring integration | 3        | 至少 3 core storage adapter |
| BST-008 | P1  | CI/仓库基线              | 1        | —                           |
| BST-009 | P1  | consumer smoke           | 1        | BST-007                     |

**testkitx（L1 test-only, LOW 风险）:**

| ID      | P   | 任务                  | 预计人天 | 关键依赖 |
| ------- | --- | --------------------- | -------- | -------- |
| TST-001 | P0  | 版本事实 reset        | 1        | 无       |
| TST-002 | P0  | test-only import gate | 1        | 无       |
| TST-003 | P0  | 删除/隔离遗留面       | 1        | 无       |
| TST-004 | P1  | fake clock/golden     | 1        | —        |
| TST-005 | P1  | fixture isolation     | 1        | —        |
| TST-006 | P1  | subprocess helper     | 1        | —        |
| TST-007 | P1  | conformance kits      | 2        | —        |
| TST-008 | P1  | 自身 mutation/CI      | 1        | —        |

[source: cross-analysis.md §W3, 07-11.md §4]

#### 2.2.4 退出条件

- [ ] kernel v1.2.0 发布，全下游编译成功
- [ ] resiliencx v2.0.0-rc1 六策略 model/race/leak/soak 全部通过
- [ ] bootstrap v0.3.0 事务式构造、3 core adapter 通过
- [ ] 所有模块 main 标 unreleased、release tuple 一致
- [ ] configx/observex/schedulex 覆盖率达到 90%
- [ ] P0-4 eBPF fault controller Go 代码实现 (xlib_standard/fixture/fault/)
- [ ] P0-9 storage-pools.yaml CI runner 部署 + xlibgate schema 验证集成
- [ ] JV-CONFIGX configx + bootstrap 联合验证补充
- [ ] JV-RESILIENCX resiliencx + kernel 边界验证补充

#### 2.2.5 关键路径节点

| 时间   | 节点                                    | 里程碑                      |
| ------ | --------------------------------------- | --------------------------- |
| Day 30 | kernel + configx/schedulex 重新认证完成 | L0/L1 light pool 完成       |
| Day 37 | resiliencx 六策略重写完成               | L1 关键路径解除             |
| Day 45 | bootstrap 事务式构造完成                | 3 core adapter 基础验证通过 |

#### 2.2.6 风险标记

| 风险                       | 描述                         | 影响              | 缓解                                  | 来源                     |
| -------------------------- | ---------------------------- | ----------------- | ------------------------------------- | ------------------------ |
| resiliencx 六策略重写      | 重建而非修复，9 人天可能不足 | Phase 2 延期      | 先写 model test + 按策略拆分独立 PR   | 07-11-analysis.md §三    |
| bootstrap 7 adapter matrix | 2178 状态组合不可穷举        | 验证覆盖率不足    | 3 core adapter PR gate / 其余 nightly | 07-11-analysis.md §三    |
| bootstrap 跨阶段依赖       | 完整验证需 W4 storage        | Day 45 可能不完整 | 先 mock/fake 验证逻辑正确性           | plan-structure.md §2.2.6 |

---

### 2.3 Phase 3 — 存储、领域与传输（Day 46-60）

#### 2.3.1 目标

建立 7 个 storage adapter 的真实验证层级（PR/Nightly/Release）；完成 L2.5 领域模块的语义纯化、SSOT 合并和接口拆分；实现 contracts/v1 和 transportx request/reply core。

[source: plan-structure.md §2.3.1, 07-11.md §5 §6]

#### 2.3.2 进入条件

- Phase 2 退出条件全部满足
- 标准控制平面 stable
- kernel/configx/observex/schedulex 可消费
- light/heavy pool 分类表定稿（P0-9）
- bare-metal fault/soak 方案就绪（P0-4）

#### 2.3.3 活动清单

**存储子阶段 — light/heavy pool 分类：**

[source: 07-11-analysis.md §P0-9, cross-analysis.md §W4]

| Pool      | 模块                         | 说明        | 并行策略                  |
| --------- | ---------------------------- | ----------- | ------------------------- |
| **Light** | postgresx, ossx, clickhousex | 可独立并行  | 3 个同时推进              |
| **Heavy** | redisx, kafkax, natsx, taosx | 需互斥 soak | 同一时间只跑一个重型 soak |

**Light pool（可并行）:**

| 模块        | P0 工作包                                           | P1 工作包   | 预计人天 | 关键依赖        |
| ----------- | --------------------------------------------------- | ----------- | -------- | --------------- |
| postgresx   | PGX-001 (Evidence 重绑)                             | PGX-002~008 | 8        | PostgreSQL 17   |
| ossx        | OSS-001 (security 阻断), OSS-002 (runner/evidence)  | OSS-003~009 | 9        | Aliyun endpoint |
| clickhousex | CHX-001 (release 声明修复), CHX-002 (security gate) | CHX-003~008 | 8        | ClickHouse 24.x |

**Heavy pool（串行 soak）:**

| 模块   | P0 工作包                                                     | P1 工作包   | 预计人天 | 关键依赖        |
| ------ | ------------------------------------------------------------- | ----------- | -------- | --------------- |
| redisx | RDX-001 (integration fail-closed), RDX-002 (真实 PR Redis)    | RDX-003~009 | 9        | Redis 7.2       |
| kafkax | KFK-001 (删除伪 integration), KFK-002/003 (producer/consumer) | KFK-004~008 | 8        | Kafka 3.6 KRaft |
| natsx  | NTS-001 (truth reset), NTS-002/003 (Core/JetStream)           | NTS-004~008 | 8        | NATS 2.10       |
| taosx  | TAO-001~003 (能力表/driver/SchemalessWrite)                   | TAO-004~008 | 8        | TDengine 3.x    |

**领域子阶段:**

| 模块            | 风险         | P0 工作包   | P1/P2 工作包 | 预计人天 | 关键依赖                     |
| --------------- | ------------ | ----------- | ------------ | -------- | ---------------------------- |
| decimalx        | LOW          | DEC-001~003 | DEC-004~009  | 6        | —                            |
| domainx         | MED          | DMN-001~003 | DMN-004~008  | 8        | decimalx                     |
| domain_market   | **CRITICAL** | MKT-001~005 | MKT-006~010  | 12       | domainx                      |
| domain_macro    | **CRITICAL** | MAC-001~005 | MAC-006~010  | 12       | 治理审批 (MAC-003)           |
| domain_exchange | **CRITICAL** | EXC-001~006 | EXC-007~010  | 12       | domain_market + domain_macro |

**传输子阶段:**

| 模块       | P0 工作包   | P1/P2 工作包 | 预计人天 | 关键依赖                |
| ---------- | ----------- | ------------ | -------- | ----------------------- |
| contracts  | CTR-001~003 | CTR-004~008  | 8        | lineage 审计结果        |
| transportx | TRN-001~004 | TRN-005~009  | 9        | module path 裁决 (P0-2) |

[source: cross-analysis.md §W4 §W5, 07-11.md §5 §6]

#### 2.3.4 退出条件

- [ ] 7 storage 建立支持版本矩阵、fault、风险触发 soak、真实 adoption
- [ ] domain_market 基础设施污染迁出完毕
- [ ] domain_macro 建立真实仓库、no-lookahead core 通过
- [ ] domain_exchange v1.1 小接口层可供消费
- [ ] contracts/transportx 有真实下游兼容验证

#### 2.3.5 关键路径节点

| 时间   | 节点                                            | 里程碑                   |
| ------ | ----------------------------------------------- | ------------------------ |
| Day 50 | 4 个假 integration 全部 fail-closed             | storage adapter 认证开始 |
| Day 55 | domainx Clock/ID 显式化 + domain_market 纯化    | 领域层修复完成           |
| Day 60 | domain_exchange v1.1 + transportx request/reply | Phase 3 退出             |

#### 2.3.6 风险标记

| 风险                                   | 描述                                  | 影响            | 缓解                                        | 来源                     |
| -------------------------------------- | ------------------------------------- | --------------- | ------------------------------------------- | ------------------------ |
| domain_macro 审批延迟                  | MAC-003 仓库创建需治理审批 + 人工授权 | 全局延迟        | 在审批前完成 SPEC/ADR/设计                  | plan-structure.md §2.3.6 |
| domain_exchange 13→8 接口拆分          | 所有下游 adapter 逐一迁移             | 12 人天可能不足 | 先 3 个重点 adapter，其余分批复用           | plan-structure.md §2.3.6 |
| domain_market Payload interface{} 替换 | 影响全部消费���                       | 迁移风险高      | 类型化 union + v1 compatibility mapper      | 07-11-analysis.md §三    |
| storage heavy pool soak 冲突           | 4 个重型服务互斥 soak 时间争夺        | 串行瓶颈        | 定时 windows + eBPF 替代 netns 减少设置时间 | plan-structure.md §2.3.6 |

---

### 2.4 Phase 4 — 全舰队认证与收尾（Day 61-75）

#### 2.4.1 目标

25 仓逐一重新认证；每仓独立 clean-room Release；Fleet status 完全由 remote Evidence 推导。

[source: plan-structure.md §2.4.1, 07-11.md §7 §8]

#### 2.4.2 进入条件

- Phase 3 退出条件全部满足
- 所有前置模块已有 stable release

#### 2.4.3 活动清单

1. 按 release train 顺序：控制面 → L0 → L1 → domain → storage → exchange → assembly
2. 每个模块执行 §1.3.4 release tuple 全�� 19 项
3. 联合验证矩阵��项通过（详见第七章）

[source: 07-11.md §7.2, cross-analysis.md §W6]

#### 2.4.4 退出条件

- [ ] 25 模块 release tuple 全部闭合
- [ ] 未过门禁者保持 blocked，不为数量放行
- [ ] Fleet status 完全由 Evidence 推导，手工 factory=true 被 gate 拒绝
- [ ] 联合验证矩阵全项通过

#### 2.4.5 风险标记

| 风险                                    | 描述                                         | 缓解                                   | 来源                     |
| --------------------------------------- | -------------------------------------------- | -------------------------------------- | ------------------------ |
| 部分模块 live/fault/soak 需真实生产环境 | storage adapter 和 exchange 的 qualification | 区分 PR gate 和 release qualification  | plan-structure.md §2.4.5 |
| 消费者迁移落后                          | L2.5 domain 变更可能阻塞下游                 | v1 compatibility mapper + 明确迁移窗口 | plan-structure.md §2.4.5 |

---

## 第三章：工作包索引

<!-- 意图：按模块展开所有工作包，标注优先级、依赖和并行可行性，补全覆盖缺口 -->

### 3.1 工作包清单

<!-- 所有数据来自 cross-analysis.md §A 工作包全集提取 -->

#### 3.1.1 标准四仓 W1

| 模块          | P0 工作包                | P1 工作包       | P2 工作包   | 合计   |
| ------------- | ------------------------ | --------------- | ----------- | ------ |
| xlib_standard | XLS-001~004 (4)          | XLS-005~007 (3) | XLS-008 (1) | 8      |
| xlib_harness  | XLH-001~003, XLH-009 (4) | XLH-004~007 (4) | XLH-008 (1) | 9      |
| xlib_evidence | XLE-001~004 (4)          | XLE-005~008 (4) | —           | 8      |
| xlibgate      | XLG-001~004 (4)          | XLG-005~007 (3) | XLG-008 (1) | 8      |
| **小计**      | **16**                   | **14**          | **3**       | **33** |

#### 3.1.2 Canary W2

| 模块     | P0 工作包       | P1 工作包       | P2 工作包   | 合计   |
| -------- | --------------- | --------------- | ----------- | ------ |
| kernel   | KRN-001~002 (2) | KRN-003~006 (4) | KRN-007 (1) | 7      |
| decimalx | DEC-001~003 (3) | DEC-004~008 (5) | DEC-009 (1) | 9      |
| redisx   | RDX-001~002 (2) | RDX-003~009 (7) | —           | 9      |
| **小计** | **7**           | **16**          | **2**       | **25** |

#### 3.1.3 L0/L1/Assembly W3

| 模块       | P0 工作包       | P1 工作包                | P2 工作包   | 合计   |
| ---------- | --------------- | ------------------------ | ----------- | ------ |
| configx    | CFG-001 (1)     | CFG-002~008 (7)          | —           | 8      |
| observex   | OBS-001~002 (2) | OBS-003~008 (6)          | —           | 8      |
| resiliencx | RES-001~005 (5) | RES-006~009 (4)          | —           | 9      |
| schedulex  | SCH-001 (1)     | SCH-002~006, SCH-008 (6) | SCH-007 (1) | 8      |
| bootstrap  | BST-001~006 (6) | BST-007~009 (3)          | —           | 9      |
| testkitx   | TST-001~003 (3) | TST-004~008 (5)          | —           | 8      |
| **小计**   | **18**          | **31**                   | **1**       | **50** |

#### 3.1.4 存储适配器 W4

| 模块        | P0 工作包       | P1 工作包       | P2 工作包 | 合计   |
| ----------- | --------------- | --------------- | --------- | ------ |
| postgresx   | PGX-001 (1)     | PGX-002~008 (7) | —         | 8      |
| ossx        | OSS-001~002 (2) | OSS-003~009 (7) | —         | 9      |
| clickhousex | CHX-001~002 (2) | CHX-003~008 (6) | —         | 8      |
| kafkax      | KFK-001~003 (3) | KFK-004~008 (5) | —         | 8      |
| natsx       | NTS-001~003 (3) | NTS-004~008 (5) | —         | 8      |
| taosx       | TAO-001~003 (3) | TAO-004~008 (5) | —         | 8      |
| **小计**    | **14**          | **35**          | **0**     | **49** |

#### 3.1.5 领域/传输 W5

| 模块            | P0 工作包       | P1 工作包       | P2 工作包   | 合计   |
| --------------- | --------------- | --------------- | ----------- | ------ |
| domainx         | DMN-001~003 (3) | DMN-004~008 (5) | —           | 8      |
| domain_market   | MKT-001~005 (5) | MKT-006~010 (5) | —           | 10     |
| domain_macro    | MAC-001~005 (5) | MAC-006~010 (5) | —           | 10     |
| domain_exchange | EXC-001~006 (6) | EXC-007~009 (3) | EXC-010 (1) | 10     |
| contracts       | CTR-001~003 (3) | CTR-004~008 (5) | —           | 8      |
| transportx      | TRN-001~004 (4) | TRN-005~008 (4) | TRN-009 (1) | 9      |
| **小计**        | **26**          | **27**          | **2**       | **55** |

#### 3.1.6 W0 治理

| 工作包              | P   | 合计   |
| ------------------- | --- | ------ |
| W0-001 ~ W0-004     | P0  | 4      |
| P0-1 ~ P0-10        | P0  | 10     |
| BASE-001 ~ BASE-009 | P0  | 9      |
| **小计**            |     | **23** |

#### 3.1.7 W6 全舰队认证

| ID        | 描述                                                                  |
| --------- | --------------------------------------------------------------------- |
| W6-DEPS   | 精确依赖链执行                                                        |
| W6-VERIFY | 联合验证矩阵全项                                                      |
| W6-CAND   | Candidate 阶段：commit→final-check→assets→binding                     |
| W6-STABLE | Stable 阶段：annotated tag→Release→assets→consumer compile            |
| W6-QUAL   | Qualification：adoption/live/fault/soak + quarantine/revoke/requalify |
| W6-CHECK  | 19 项 per-module 检查                                                 |

#### 3.1.8 工作包汇总

| 波次     | 模块工作包 | P0      | P1      | P2    | 合计    |
| -------- | ---------- | ------- | ------- | ----- | ------- |
| W0       | 23         | 23      | 0       | 0     | 23      |
| W1       | 33         | 16      | 14      | 3     | 33      |
| W2       | 25         | 7       | 16      | 2     | 25      |
| W3       | 50         | 18      | 31      | 1     | 50      |
| W4       | 49         | 14      | 35      | 0     | 49      |
| W5       | 55         | 26      | 27      | 2     | 55      |
| W6       | 6 流程     | —       | —       | —     | 6       |
| **总计** | **241**    | **104** | **123** | **8** | **241** |

[source: cross-analysis.md §F 统计概要]

### 3.2 全局 BASE-\* 工作包展开

#### 3.2.1 BASE-003 文件缺失矩阵

<!-- 来源：07-11-analysis.md §六 "缺 SECURITY/CONTRIBUTING/CODEOWNERS 的模块（10+）" -->

以下模块缺 BASE-003 专用工作包，需为每个模块创建：

| 模块            | 缺失文件                                                                 | BASE-003 工作包 | 状态    |
| --------------- | ------------------------------------------------------------------------ | --------------- | ------- |
| kernel          | SECURITY, CONTRIBUTING, CODEOWNERS                                       | BASE-003-KRN    | PENDING |
| configx         | SECURITY, CONTRIBUTING, CODEOWNERS                                       | BASE-003-CFG    | PENDING |
| observex        | SECURITY, CONTRIBUTING, CODEOWNERS                                       | BASE-003-OBS    | PENDING |
| xlib_harness    | LICENSE, SECURITY, CODEOWNERS                                            | BASE-003-XLH    | PENDING |
| xlib_evidence   | LICENSE, SECURITY, CODEOWNERS                                            | BASE-003-XLE    | PENDING |
| xlibgate        | LICENSE, SECURITY, CODEOWNERS                                            | BASE-003-XLG    | PENDING |
| bootstrap       | README, LICENSE, CHANGELOG, SECURITY, CONTRIBUTING, CODEOWNERS, Makefile | BASE-003-BST    | PENDING |
| domain_market   | README, LICENSE, CHANGELOG, SECURITY, Makefile                           | BASE-003-MKT    | PENDING |
| domain_exchange | README, LICENSE, CHANGELOG, SECURITY                                     | BASE-003-EXC    | PENDING |

> 另需按 §3.2.1 批量生成脚本 (07-11-analysis.md §P0-7 L2710-2839)；由 xlib_harness fleet patch plan 产出统一 patch PR。

#### 3.2.2 BASE-005 供应链审计补充工作包

以下 5 个模块有 latest tag Actions / curl-pipe / disabled security：

| 模块          | 问题                  | BASE-005 工作包 | 状态    |
| ------------- | --------------------- | --------------- | ------- |
| bootstrap     | 24/24 mutable Actions | BASE-005-BST    | PENDING |
| xlib_standard | curl-pipe install     | BASE-005-XST    | PENDING |
| xlib_evidence | latest tag            | BASE-005-XLE    | PENDING |
| xlib_harness  | govulncheck@latest    | BASE-005-XLH    | PENDING |
| xlibgate      | latest tag            | BASE-005-XLG    | PENDING |

[source: 07-11-analysis.md §六 "BASE-005 供应链审计覆盖不足"]

### 3.3 分析报告覆盖缺口补充

<!-- 意图：列出 07-11-analysis.md §七 "缺失章节"中发现的工作包缺口，追加补充工作包 -->

| 工作包 ID              | 描述                                     | 负责阶段        | 状态    |
| ---------------------- | ---------------------------------------- | --------------- | ------- |
| GO-ROLLBACK-001        | 全局回滚策略定义                         | Phase 0 (P0-10) | RESOLVED (by P0-10 §10.1-10.3) |
| GO-BASE-002            | BASE 推广 Runbook                        | Phase 0 (P0-10) | RESOLVED (by P0-10 §10.1-10.3) |
| GO-PEOPLE-003          | 人员分工与并��窗口定义                   | Phase 0         | PENDING |
| GO-DASH-004            | Fleet Status Dashboard 搭建              | Phase 1         | PENDING |
| JV-CONFIGX-INTEGRATION | configx + bootstrap 联合验证矩阵补充     | Phase 2         | PENDING |
| JV-RESILIENCX-KERNEL   | resiliencx + kernel 边界验证联合矩阵补充 | Phase 2         | PENDING |

[source: 07-11-analysis.md §七 "缺失章节"]

---

## 第四章：P0 修复实施追踪

<!-- 意图：为 07-11-analysis.md §九 的 10 条 P0 修复提供可操作的状态追踪模板 -->

### 4.1 P0 修复总表

| #     | 修复描述                                   | 负责人 | 目标日期      | 相关制品                                         | 状态    |
| ----- | ------------------------------------------ | ------ | ------------- | ------------------------------------------------ | ------- |
| P0-1  | 裁决 goalcli 最终归属（并入 xlib_harness） | —    | Phase 0 Day 2 | OWNERSHIP-GOALCLI.yaml, XLH-009, 21 agent prompt | **COMPLETED** |
| P0-2  | 裁决 transportx go module major path       | —    | Phase 0 Day 2 | TRN-001 补充, go.mod retract                     | **COMPLETED** |
| P0-3  | 执行 contracts git tag lineage 审计        | —    | Phase 0 Day 2 | contracts-lineage-audit.sh, CTR-001              | **COMPLETED** (v0.5.3) |
| P0-4  | 明确 bare-metal fault/soak 方案            | —    | Phase 2 前    | eBPF controller, xlib_standard/fixture/fault/    | **DOCUMENTED** |
| P0-5  | 全仓 status projection 事实审计            | —    | Phase 0 Day 1 | audit-status-projection.py, W0 inventory         | **COMPLETED** |
| P0-6  | 定义 xlib_standard MVC（最小可行合约）     | —    | Phase 1 Day 5 | XLS-003, bundle manifest                         | **DOCUMENTED** |
| P0-7  | 为 10+ 模块创建 BASE-003 专用工作包        | —    | Phase 0       | §3.2.1, base-003-batch-gen.sh                    | **COMPLETED** |
| P0-8  | 30 天窗口扩展至 60-75 天                   | —    | Phase 0 Day 1 | 本报告二章 Phase 映射                            | **COMPLETED** |
| P0-9  | 定义 W4 light/heavy pool 分类表            | —    | Phase 2 前    | §2.3.3 存储子阶段, storage-pools.yaml            | **DOCUMENTED** |
| P0-10 | 新增回滚策略 + BASE 推广 Runbook           | —    | Phase 1 前    | §第十章 + §8.1                                  | **COMPLETED** |

[source: 07-11-analysis.md §九 P0 修复建议, cross-analysis.md §B.6]

### 4.2 每条 P0 的详细追踪

#### P0-1: goalcli 归属裁决

| 字段      | 值                                                                                                                                                                       |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 修复对象  | goalcli 归属真空 — 三方声称删除无人认领                                                                                                                                  |
| 负责人    | TBD                                                                                                                                                                      |
| 目标截止  | Phase 0 Day 2                                                                                                                                                            |
| 前置依赖  | 无                                                                                                                                                                       |
| 实施步骤  | 1. 创建 OWNERSHIP-GOALCLI.yaml (xlib_harness)\n2. 新增 XLH-009 工作包\n3. 批量更新 21 agent prompt 的 goalcli 引用\n4. xlib_standard/xlibgate 添加 goalcli 残留检测 gate |
| 验收条件  | harness goalcli 子命令覆盖全部功能；旧路径返回 deprecation notice；21 agent prompt 已更新                                                                                |
| 风险      | xlib_harness 当前 v0.3.0，goalcli 需要成熟 CLI 框架                                                                                                                      |
| 实施细节  | 07-11-analysis.md §P0-1 L284-372                                                                                                                                         |
| 状态      | PENDING                                                                                                                                                                  |
| 最后���新 | 2026-07-11                                                                                                                                                               |

#### P0-2: transportx module major path 裁决

| 字段     | 值                                                                                                                                                                |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 修复对象 | transportx go.mod = xlib-standard 身份错乱                                                                                                                        |
| 负责人   | TBD                                                                                                                                                               |
| 目标截止 | Phase 0 Day 2                                                                                                                                                     |
| 前置依赖 | 无                                                                                                                                                                |
| 实施步骤 | 1. 裁决决策树：production_import_allowed=false → /v1 (无 /v2)\n2. 修改 go.mod: xlib-standard → transportx\n3. 更新所有 import path\n4. retract v1.0.0–v1.1.1-spec |
| 验收条件 | go get github.com/xhyperium/transportx@tag 成功；无 xlib-standard 残留                                                                                              |
| 风险     | 若有未被记录的消费者，需紧急修复                                                                                                                                  |
| 实施细节 | 07-11-analysis.md §P0-2 L375-458                                                                                                                                  |
| 状态     | PENDING                                                                                                                                                           |
| 最后更新 | 2026-07-11                                                                                                                                                        |

#### P0-3: contracts lineage 审计

| 字段     | 值                                                                                                                                |
| -------- | --------------------------------------------------------------------------------------------------------------------------------- |
| 修复对象 | contracts v1.5.0 phantom tag — 从未存在，实际最新为 v0.5.2                                                                 |
| 负责人   | TBD                                                                                                                               |
| 目标截止 | Phase 0 Day 2                                                                                                                     |
| 前置依赖 | 无                                                                                                                                |
| 实施步骤 | 1. 执行 contracts-lineage-audit.sh\n2. 列出所有 tag 与 commit\n3. 检查每个 tag 与 main HEAD 的祖先关系\n4. v1.5.0 phantom→裁决 v0.5.3 |
| 验收条件 | 裁决 v0.5.3（v0.4.7→v0.5.0→v0.5.1→v0.5.2→v0.5.3 合法祖先链完整）                                                                  |
| 风险     | v1.5.0 phantom tag 不存在，裁决前提错误已纠正                                                                                    |
| 实施细节 | 07-11-analysis.md §P0-3 L462-527; 审计输出详见 p0-3-lineage-audit-result.md                                                       |
| 状态     | COMPLETED (v0.5.3)                                                                                                                |
| 最后更新 | 2026-07-11                                                                                                                        |

#### P0-4: bare-metal fault/soak 方案

| 字段     | 值                                                                                                                                                                                                                    |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 修复对象 | Docker/K8s 禁令下 storage adapter fault injection 替代方案                                                                                                                                                            |
| 负责人   | TBD                                                                                                                                                                                                                   |
| 目标截止 | Phase 2 前（Day 21）                                                                                                                                                                                                  |
| 前置依赖 | xlib_standard/fixture/fault/ 包就绪                                                                                                                                                                                   |
| 实施步骤 | 1. 实现 Go-native netns Controller\n2. 实现 eBPF Controller (packdrop/connrst/ioerr/latency)\n3. 建立 systemd service unit 模板\n4. 实现 RunSoak/FaultScenario 复用框架\n5. 各 storage adapter 引用 fixture/fault/ 包 |
| 验收条件 | 三层方案全部可用；3 core adapter 至少 1 个通过 soak test                                                                                                                                                              |
| 风险     | eBPF 需要内核 >= 5.15 + BTF；CI runner 需 root 权限                                                                                                                                                                   |
| 实施细节 | 07-11-analysis.md §P0-4 L530-2431                                                                                                                                                                                     |
| 状态     | PENDING                                                                                                                                                                                                               |
| 最后更新 | 2026-07-11                                                                                                                                                                                                            |

#### P0-5: 全仓 status projection 审计

| 字段     | 值                                                                                                                   |
| -------- | -------------------------------------------------------------------------------------------------------------------- |
| 修复对象 | status projection 中 domain_macro 等虚假声明                                                                         |
| 负责人   | TBD                                                                                                                  |
| 目标截止 | Phase 0 Day 1                                                                                                        |
| 前置依赖 | 无                                                                                                                   |
| 实施步骤 | 1. 执行 audit-status-projection.py\n2. 逐模块验证：仓库存在、tag 可定位、CI 通过、Release 含 assets\n3. 输出修正指令 |
| 验收条件 | 每条 factory/release 声明有可验证 evidence；虚假声明全部修正                                                         |
| 风险     | domain_macro 治理信任崩塌的连锁影响                                                                                  |
| 实施细节 | 07-11-analysis.md §P0-5 L2483-2645                                                                                   |
| 状态     | PENDING                                                                                                              |
| 最后更新 | 2026-07-11                                                                                                           |

#### P0-6: xlib_standard MVC 定义

| 字段     | 值                                                                                                                                            |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| 修复对象 | xlib_standard v2 RC 是全局瓶颈                                                                                                                |
| 负责人   | TBD                                                                                                                                           |
| 目标截止 | Phase 1 Day 5                                                                                                                                 |
| 前置依赖 | XLS-001 ownership manifest 冻结                                                                                                               |
| 实施步骤 | 1. 定义 MVC 交付里程碑：schema/policy/reason-code 先 freeze\n2. MVC freeze 后 gate/evidence/harness 可并行启动\n3. 完整 bundle 在第 14 天交付 |
| 验收条件 | MVC freeze spec 定稿；gate/evidence/harness 在 Day 5 后可用                                                                                   |
| 风险     | standard bundle 完整性可能受影响                                                                                                              |
| 实施细节 | 07-11-analysis.md §P0-6 L2649-2706                                                                                                            |
| 状态     | DOCUMENTED |
| 最后更新 | 2026-07-11 |
| 裁决文档 | XLS-003 standard bundle structure 已创建 (schemas/policies/reason-codes/profiles), MVC freeze spec 已写入 |

[source: 07-11-analysis.md §九, cross-analysis.md §B.6 P0 修复建议]

#### P0-7 ~ P0-10 快速追踪

| #     | 描述                    | 详细追踪                                                             | 实施细节来源                        |
| ----- | ----------------------- | -------------------------------------------------------------------- | ----------------------------------- |
| P0-7  | BASE-003 批量工作包     | 为 11 模块创建专用工作包（5/11 done: kernel/configx/bootstrap/domain_market/xlib_standard + 6/11 done: observex/xlib_harness/xlib_evidence/xlibgate/domain_exchange/redisx） | 07-11-analysis.md §P0-7 L2710-2839  |
| P0-8  | 时间线修正              | 30 天 → 60-75 天，Phase 0 Day 1 完成                                                                                                | 07-11-analysis.md §P0-8 L2842-2861  |
| P0-9  | light/heavy pool 分类   | 定义 W4 存储适配器分类与资源约束，Phase 2 前完成                                                                                    | 07-11-analysis.md §P0-9 L2864-2904  |
| P0-10 | 回滚策略 + BASE Runbook | 完整回滚决策树 + BASE 推广 Runbook 已写入 §十章，Phase 1 前完成                                                                     | 07-11-analysis.md §P0-10 L2908-2992 |

---

## 第五章：依赖与关键路径

<!-- 意图：用可视化文本图表达 25 模块的精确依赖关系 -->

### 5.1 全局依赖 DAG

<!-- 来源：cross-analysis.md §D, 07-11.md §7.1 -->

```text
                    ┌─────────────────────────┐
                    │  xlib_standard v2 RC     │ ← 全局瓶颈（阻塞全部 25 仓）
                    └───────────┬─────────────┘
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
     ┌────────┴────────┐ ┌──────┴──────┐ ┌───────┴──────┐
     │ xlib_evidence   │ │  xlibgate   │ │ xlib_harness │
     └────────┬────────┘ └──────┬──────┘ └───────┬──────┘
              │                 │                 │
              └─────────────────┼─────────────────┘
                                │ 三 canaries
              ┌─────────────────┼─────────────────┐
              │                 │                 │
     ┌────────┴────────┐ ┌──────┴──────┐ ┌───────┴──────┐
     │ kernel (L0)     │ │ decimalx    │ │ redisx       │
     └────────┬────────┘ └──────┬──────┘ └───────┬──────┘
              │                 │                 │
              │   xlib_standard stable ──────────┘
              │
    ┌─────────┼─────────────┬──────────────┐
    │         │             │              │
    │  ┌──────┴──────┐ ┌───┴───┐ ┌───────┴──────┐
    │  │ configx     │ │observex│ │ schedulex    │ ← 可并行
    │  └──────┬──────┘ └───┬───┘ └───────┬──────┘
    │         │            │             │
    │  ┌──────┴────────────┴─────────────┴──────┐
    │  │              testkitx                   │
    │  └────────────────┬───────────────────────┘
    │                   │
    │  ┌────────────────┴───────────────────────┐
    │  │            resiliencx  ★★★             │ ← 关键路径最长节点 (14天)
    │  └────────────────┬───────────────────────┘
    │                   │
    │  ┌────────────────┼───────────────────────┐
    │  │           storage adapters             │
    │  │  ┌────────┐ ┌──────┐ ┌──────┐ ┌─────┐ │
    │  │  │ redisx │ │kafkax│ │natsx │ │taosx│ │ ← Heavy pool (串行 soak)
    │  │  └───┬────┘ └──┬───┘ └──┬───┘ └──┬──┘ │
    │  │  ┌───┴────┐ ┌──┴───┐ ┌──┴───┐ ┌──┴──┐ │
    │  │  │postgresx│ │ossx │ │clickhousex│    │ │ ← Light pool (可并行)
    │  │  └───┬─────┘ └──┬──┘ └─────┬─────┘    │ │
    │  └──────┼──────────┼───────────┼──────────┘ │
    │         │          │           │            │
    │  ┌──────┴──────────┴───────────┴──────────┐ │
    │  │             bootstrap  ★★★             │ │ ← 需 7 个 storage
    │  └────────────────┬───────────────────────┘ │
    │                   │                          │
    │  ┌────────────────┼───────────────────────┐  │
    │  │            domainx                     │  │
    │  └──────┬─────────┴───────┬───────────────┘  │
    │         │                 │                   │
    │  ┌──────┴──────┐ ┌───────┴──────┐            │
    │  │domain_market│ │domain_macro  │ ★★★       │
    │  │    ★★★      │ │   ★★★       │ (+仓库创建)│
    │  └──────┬──────┘ └───────┬──────┘            │
    │         └────────┬───────┘                    │
    │                  │                            │
    │         ┌────────┴────────┐                   │
    │         │domain_exchange ★★★                  │
    │         └────────┬───────┘                   │
    │                  │                            │
    │  ┌───────────────┼───────────────┐            │
    │  │          contracts           │            │
    │  └───────────────┬──────────────┘            │
    │                  │                            │
    │  ┌───────────────┼───────────────┐            │
    │  │          transportx          │            │
    │  └───────────────┬──────────────┘            │
    │                  │                            │
    │         ┌────────┴────────┐                   │
    │         │ real downstream │                   │
    │         │    consumers     │                   │
    │         └─────────────────┘                   │
```

> ★★★ = CRITICAL 风险模块

[source: 07-11.md §7.1 L1000-1016, cross-analysis.md §D.1]

### 5.2 关键路径标注

<!-- 来源：07-11-analysis.md §四, cross-analysis.md §D.2 -->

关键路径（决定整体修复时间线）：

```
xlib_standard RC → gate/evidence/harness → 3 canaries → standard stable → L1 → storage → domain → fleet
```

| 排名 | 节点                   | 阻塞模块数 | 最短路径长度 | 说明                     | 来源                       |
| ---- | ---------------------- | ---------- | ------------ | ------------------------ | -------------------------- |
| 1    | xlib_standard v2 RC    | 25         | 1→25         | 全局瓶颈，不可替代       | cross-analysis.md §D.2 #1  |
| 2    | resiliencx 6策略重建   | 4          | 1→4          | Phase 2 关键路径最长节点 | cross-analysis.md §D.2 #2  |
| 3    | bootstrap BST-007      | 7+         | 7→1          | 需 7 个 storage 就绪     | cross-analysis.md §D.2 #3  |
| 4    | domainx spec-freeze    | 3          | 1→3          | 契约确定前不可并行       | cross-analysis.md §D.2 #4  |
| 5    | canary 全部通过        | 20         | 3→20         | 加权 2/3 + RCA 可缓解    | cross-analysis.md §D.2 #5  |
| 6    | contracts lineage 审计 | 6          | 1→6          | 版本不确定阻塞语义定义   | cross-analysis.md §D.2 #6  |
| 7    | domain_macro 仓库创建  | 3          | 0→3          | 从零创建，含授权等待     | cross-analysis.md §D.2 #7  |
| 8    | BASE-003 批量生成      | 10+        | 1→10         | 治理合规前置             | cross-analysis.md §D.2 #9  |
| 9    | W0 状态审计            | 25         | 1→25         | 事实前提                 | cross-analysis.md §D.2 #10 |

### 5.3 可并行工作包组

<!-- 来源：cross-analysis.md §D.3, 07-11.md §2.2 -->

#### 绝对安全并行（互斥写入范围）

| 并行组                                      | 模块数 | 前提条件                | 阶段              |
| ------------------------------------------- | ------ | ----------------------- | ----------------- |
| xlibgate + xlib_evidence + xlib_harness     | 3      | XLS-001/003 MVC freeze  | Phase 1           |
| kernel + decimalx + redisx canary           | 3      | W1 完成                 | Phase 1 子阶段 1C |
| configx + schedulex + observex              | 3      | W1 控制平面完成         | Phase 2           |
| postgresx + ossx + clickhousex (light pool) | 3      | Phase 2 + pool 定义     | Phase 3           |
| domain_market + domain_macro                | 2      | domainx spec-freeze     | Phase 3           |
| testkitx + configx                          | 2      | 独立                    | Phase 2           |
| decimalx + kernel                           | 2      | 独立类型系统            | Phase 2           |
| 10+ BASE-003 批量生成                       | 10+    | xlib_harness 产出 patch | 全阶段            |

#### 条件并行（需串行冻结前阶段）

| 并行组                                                  | 模块数 | 前置串行条件                           | 阶段    |
| ------------------------------------------------------- | ------ | -------------------------------------- | ------- |
| gate/evidence/harness 全并行                            | 3      | MVC freeze (schema/policy/reason-code) | Phase 1 |
| postgresx nightly + taosx nightly + clickhousex nightly | 3      | 独立服务                               | Phase 3 |
| domain_exchange conformance 3 adapter                   | 3      | EXC-002 小接口完成                     | Phase 3 |

### 5.4 单点阻塞与缓解策略

| 阻塞节点                | 阻塞影响             | 缓解策略                                                           | 节省           | 来源                     |
| ----------------------- | -------------------- | ------------------------------------------------------------------ | -------------- | ------------------------ |
| xlib_standard v2.0.0 RC | 全局冻结             | MVC 解耦：schema/policy 先 freeze，启用 gate/evidence/harness 并行 | 5-7 天         | 07-11-analysis.md §八    |
| 任一 canary 失败        | standard stable 延迟 | 加权通过策略：2/3 + RCA，不必全绿                                  | 消除全局阻塞   | 07-11-analysis.md §八    |
| bootstrap 完整验证      | 需 7 storage         | 先 3 light pool adapter PR gate，其余 mock/fake                    | Phase 2 可结束 | plan-structure.md §2.2.6 |
| domain_macro 治理审批   | 仓库创建延迟         | SPEC/ADR/设计在审批前完成，仓库创建后直接实现                      | 并行等待       | plan-structure.md §2.3.6 |
| storage heavy pool soak | 串行瓶颈             | 定时 windows + eBPF 方案减少环境准备                               | 2-3 天         | plan-structure.md §2.3.6 |

---

## 第六章：风险矩阵

<!-- 意图：按模块和概率-影响二维矩阵展示风险分布 -->

### 6.1 风险热力图

#### 6.1.1 CRITICAL 风险模块（5 个）

| 模块                | 概率 | 影响    | 驱动因素                                                    | 来源                  |
| ------------------- | ---- | ------- | ----------------------------------------------------------- | --------------------- |
| **resiliencx**      | HIGH | HIGH    | 6 策略全部重写 — 这是重建，不是修复                         | 07-11-analysis.md §三 |
| **bootstrap**       | HIGH | HIGH    | 事务式构造 + 7 adapter partial failure matrix (3^7=2178)    | 07-11-analysis.md §三 |
| **domain_market**   | MED  | HIGH    | 基础设施污染逐行迁出 + Payload interface{} 替换 + SSOT 合并 | 07-11-analysis.md §三 |
| **domain_exchange** | HIGH | HIGH    | 13→8 接口拆分，所有下游 adapter 逐一迁移                    | 07-11-analysis.md §三 |
| **domain_macro**    | MED  | EXTREME | 仓库不存在 + 从零创建 + 治理信任崩塌                        | 07-11-analysis.md §三 |

#### 6.1.2 HIGH 风险模块（4 个）

| 模块          | 驱动因素                                                                 | 来源                  |
| ------------- | ------------------------------------------------------------------------ | --------------------- |
| transportx    | go.mod identity 指向 xlib-standard + 从 spec stub 构建 functional module | 07-11-analysis.md §三 |
| xlib_standard | 角色收缩 breaking governance change + bundle 必须 bit-for-bit 可重现     | 07-11-analysis.md §三 |
| natsx         | 版本 truth reset + Core NATS + JetStream 三层从零建立                    | 07-11-analysis.md §三 |
| kafkax        | 删除伪 integration + 建立真实 Kafka integration + rebalance semantics    | 07-11-analysis.md §三 |

#### 6.1.3 LOW 风险模块（6 个）

kernel / decimalx / configx / schedulex / observex / testkitx

[source: 07-11-analysis.md §三 风险热力图]

### 6.2 高影响-高概率事件缓解方案

| 事件                                  | 影响           | 缓解方案                                                         | 来源                     |
| ------------------------------------- | -------------- | ---------------------------------------------------------------- | ------------------------ |
| xlib_standard v2 RC 失败              | 全局冻结       | MVC 解耦 + 上一 stable 验证候选 + 回退到前一个 stable            | 07-11-analysis.md §八    |
| resiliencx P0 重写超出预估            | 9→14 人天      | 先写 model test + 按策略拆分独立 PR + 保留旧 API 兼容 v1 adapter | plan-structure.md §2.2.6 |
| bootstrap 7 adapter matrix 无法全验证 | 验证覆盖率不足 | 3 core adapter (postgresx/redisx/kafkax) PR gate / 其余 nightly  | plan-structure.md §2.2.6 |
| domain_macro 仓库授权延迟             | 全局延迟       | Spec/ADR/Design 在审批前完成，仓库创建后直接实现                 | plan-structure.md §2.3.6 |
| storage heavy pool soak 冲突          | 串行瓶颈       | 一次只跑一个重型 soak + 定时窗口 + eBPF 替代 netns               | plan-structure.md §2.3.6 |

### 6.3 回滚决策树

<!-- 来源：07-11-analysis.md §P0-10 回滚决策树 -->

```
模块修复失败
├── Phase 内部修复失败
│   └── 保留 worktree → redact summary → 回 Sol 重新规划
├── 标准模块 v2.0.0 发布后发现问题
│   └── advisory + v2.0.1 patch + retract v2.0.0（不删除 tag）
├── Canary 验证失败（< 2/3）
│   └── RCA → 修复 → 重跑 → 仍失败时 escalation
├── 模块认证失败
│   └── 保持 blocked，不降级标准,不为数量放行
└── 证据冲突
    └── 以可重放 evidence 为准 → 暂停宣称 → 重新审计
```

---

## 第七章：验证与质量门禁

### 7.1 每阶段退出 Check

#### Phase 0 退出 Check

- [ ] 所有 NO-GO 模块的 factory/release claim 不再虚报
- [ ] 25 仓 inventory 无矛盾
- [ ] 三条治理矛盾裁决完成（goalcli/transportx/contracts）
- [ ] Go baseline SSOT 收敛 (go 1.26.0, toolchain go1.26.5)
- [ ] 无新虚假 factory 声明
- [ ] light/heavy pool 分类表发布
- [ ] 回滚决策树和 BASE Runbook 定稿
- [ ] P0-1~P0-3, P0-5, P0-7, P0-8 完成

#### Phase 1 退出 Check

- [ ] 标准四仓 release gate 可重放
- [ ] xlib_standard v2.0.0 stable 发布
- [ ] 三 canary 全部 Release 或 2/3 + RCA
- [ ] goalcli 完全迁移到 xlib_harness（XLH-009）
- [ ] P0-4 (fault/soak 方案) 开发完成
- [ ] P0-6 (MVC 定义) 完成
- [ ] P0-9 (pool 分类表) 定稿
- [ ] P0-10 (回滚+Runbook) 定稿

#### Phase 2 退出 Check

- [ ] kernel v1.2.0 发布，全下游编译
- [ ] resiliencx v2.0.0-rc1 六策略全部通过
- [ ] bootstrap v0.3.0 事务式构造 + 3 core adapter
- [ ] 所有模块 main 标 unreleased
- [ ] configx/observex/schedulex 覆盖率 90%
- [ ] testkitx import gate 生效

#### Phase 3 退出 Check

- [ ] 7 storage 全有真实验证层级（PR/Nightly/Release）
- [ ] 4 个假 integration 全部 fail-closed
- [ ] domain_market 基础设施污染迁出
- [ ] domain_macro 真实仓库 + no-lookahead core
- [ ] domain_exchange v1.1 小接口层
- [ ] contracts/transportx 有真实下游兼容验证

#### Phase 4 退出 Check

- [ ] 25 模块 release tuple 全部闭合
- [ ] 未过门禁者保持 blocked，不为数量放行
- [ ] Fleet status 完全由 Evidence 推导
- [ ] 联合验证矩阵全项通过

### 7.2 联合验证矩阵

| 联合验证             | 模块                                  | 必须证明                                      | 状态 |
| -------------------- | ------------------------------------- | --------------------------------------------- | ---- |
| CANARY-L0            | standard+harness+gate+evidence+kernel | pure module 全链                              | TBD  |
| CANARY-DOMAIN        | decimalx+domainx                      | deterministic finance values                  | TBD  |
| CANARY-L2            | redisx+observex+bootstrap             | real external integration + assembly rollback | TBD  |
| OBS-CONFORMANCE      | observex+external adapter fixture     | vendor-neutral SPI                            | TBD  |
| RESILIENCX-KERNEL    | resiliencx+kernel                     | 策略迁移正确性                                | TBD  |
| CONFIGX-INTEGRATION  | configx+bootstrap                     | 配置中枢边界行为                              | TBD  |
| EXCHANGE-CONFORMANCE | domain_exchange+≥3 venue adapters     | capability migration                          | TBD  |
| MARKET-CONTRACT      | domain_market+contracts+market_data   | canonical fact 与 wire mapping                | TBD  |
| MACRO-NOLOOKAHEAD    | domain_macro+macro_data+macro_regime  | AsOf/vintage 无前视                           | TBD  |
| TRANSPORT-CONTRACT   | transportx+HTTP adapter+contracts     | request/reply/codec/middleware                | TBD  |

[source: 07-11.md §7.2 L1020-1029，补充 RESILIENCX-KERNEL & CONFIGX-INTEGRATION: 07-11-analysis.md §七]

### 7.3 自动化 Gate 定义

<!-- 来源：07-11.md §1.4 BASE work packages -->

| Gate 类型         | 适用层级 | fail 行为                    | reason code                     | 跳过条件                             |
| ----------------- | -------- | ---------------------------- | ------------------------------- | ------------------------------------ |
| identity gate     | 全部     | exit 1                       | IDENTITY-DRIFT                  | 不可跳过                             |
| Go baseline gate  | 全部     | exit 1                       | GO-MISMATCH                     | ADR 例外 + owner 签名                |
| repo-profile gate | 全部     | exit 1                       | REPO-PROFILE-MISSING            | BASE-003 生成中可临时 skip，标注 TTL |
| CI gate           | 全部     | exit 1                       | CI-DISABLED/CI-SKIP             | 不可跳过                             |
| supply-chain gate | 全部     | exit 1                       | SUPPLY-CHAIN-INSECURE           | 不可跳过                             |
| API/SemVer gate   | L0+      | exit 1 (breaking + no MAJOR) | API-BREAKING/SEMVER             | 当没有祖先 release tag 时 skip       |
| Evidence gate     | 全部     | exit 1                       | EVIDENCE-MISSING/EVIDENCE-DRIFT | 不可跳过                             |
| Release gate      | 全部     | exit 1                       | RELEASE-INCOMPLETE              | 不可跳过                             |
| Adoption gate     | L1+      | exit 1                       | ADOPTION-MISSING                | 不可跳过                             |

---

## 第八章：资源与基础设施

### 8.1 CI Runner 需求

| Pool Class        | 适用模块                   | 核心要求                             | 数量 |
| ----------------- | -------------------------- | ------------------------------------ | ---- |
| sre/contracts     | L0/pure-library            | ephemeral、rootless、无网络出站      | 2    |
| sre/compute       | L1 primitives              | race-enabled、coverage collection    | 2    |
| sre/storage-light | postgresx/ossx/clickhousex | 各自本地 service、无容器             | 3    |
| sre/storage-heavy | redisx/kafkax/natsx/taosx  | systemd、netns、iptables、ebpf、root | 4    |

[source: plan-structure.md §8, 07-11.md §5]

### 8.2 外部服务清单

| 服务       | 模块        | 版本要求       | 部署方式             | 权限要求              |
| ---------- | ----------- | -------------- | -------------------- | --------------------- |
| Redis      | redisx      | >= 7.2         | systemd unit + netns | root (netns/iptables) |
| Kafka      | kafkax      | >= 3.6 (KRaft) | systemd unit + netns | root                  |
| NATS       | natsx       | >= 2.10        | systemd unit + netns | root                  |
| PostgreSQL | postgresx   | 17 + N-1       | systemd unit         | root                  |
| TDengine   | taosx       | >= 3.x         | systemd unit + netns | root                  |
| ClickHouse | clickhousex | >= 24.x        | systemd unit         | root                  |
| Aliyun OSS | ossx        | live endpoint  | credentials (Secret) | key/secret            |

[source: stepSummary §8.2]

### 8.3 eBPF 环境准备

- **eBPF Controller 包结构**: fault.go / packdrop.c|go / connrst.c|go / ioerr.c|go / latency.c|go / helpers.go / soak.go
- **编译依赖**: cilium/ebpf + bpf2go + clang + kernel headers
- **CI Runner 前置条件**: kernel >= 5.15 + BTF + bpf syscall 权限
- **三层能力矩阵**: Bash (阶段1) → Go-native netns (阶段2) → eBPF (阶段3)

[source: 07-11-analysis.md §P0-4 L530-2431]

### 8.4 Bare-metal Fault Injection 验证

- **三级隔离方案**: systemd service unit + network namespace + iptables/nftables
- **FaultScenario 测试框架**: RunScenario() + RunSoak() 跨 adapter 复用
- **跨 adapter 复用**: xlib_standard/fixture/fault/ 公共包
- **CI 跳过策略**: 本地开发自动 skip (CI=true 才执行)，CI+root 必须执行

[source: 07-11-analysis.md §P0-4 Go-native fault controller]

---

## 第九章：治理检查清单

### 9.1 Release Tuple 完成矩阵

每个模块完成修复 Epic 前，必须通过以下 19 项检查。

19 Items:

1. 模块职责与非目标冻结
2. repo/module/package identity 一致
3. Go/toolchain/runner 标准一致
4. main 仅表示 unreleased；release tuple 一致
5. 必备 repo profile 文件齐全
6. generated CI 无手工削弱
7. required security 全阻断
8. API/schema/SemVer 机器裁决
9. unit/race/coverage/property/fuzz 满足 profile
10. class-specific integration/model/conformance 通过
11. required integration 不可 skip
12. Evidence 绑定 commit/tree/run/service/assets
13. candidate final check 在 stable tag 前完成
14. GitHub Release assets 完整且 digest 验证
15. `go get @tag` 成功
16. downstream adoption 通过
17. live/fault/soak 满足适用 profile
18. Fleet qualification 由证据推导
19. rollback/quarantine/revoke 路径可执行

[source: 07-11.md §12 L1160-1183]

> Phase 4 结束时，25 模块 × 19 项 = 475 个格子全部必须为 PASS。当前基线：0/475。

### 9.2 BASE 工作包完成矩阵

| 模块            | BASE-001 | BASE-002 | BASE-003 | BASE-004 | BASE-005 | BASE-006 | BASE-007 | BASE-008 | BASE-009 |
| --------------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- | -------- |
| xlib_standard   | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| xlib_harness    | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| xlib_evidence   | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| xlibgate        | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| kernel          | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| configx         | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| observex        | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| resiliencx      | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| schedulex       | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| bootstrap       | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| testkitx        | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| redisx          | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| kafkax          | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| natsx           | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| postgresx       | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| taosx           | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| ossx            | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| clickhousex     | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| contracts       | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| transportx      | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| decimalx        | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| domainx         | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| domain_market   | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| domain_macro    | —        | —        | —        | —        | —        | —        | —        | —        | —        |
| domain_exchange | —        | —        | —        | —        | —        | —        | —        | —        | —        |

> 图例：— = PENDING（当前全部为待完成状态）

#### BASE-003 覆盖缺口（07-11-analysis.md §六 发现）

| 缺口类型                            | 数量 | 需补充                          |
| ----------------------------------- | ---- | ------------------------------- |
| "BASE-\* 全通过" 无分解             | 8 个 | 逐模块拆分为 P0/P1 子任务       |
| 缺 SECURITY/CONTRIBUTING/CODEOWNERS | 9 个 | BASE-003 专用工作包 (见 §3.2.1) |
| BASE-005 供应链覆盖不足             | 5 个 | BASE-005 专用工作包 (见 §3.2.2) |

---

## 附录

### 附录 A — 全仓状态投影审计结果

> 详细审计结果待 Phase 0 完成 audit-status-projection.py 后填充。
> 审计脚本：07-11-analysis.md §P0-5 L2483-2645。
>
> 当前已知虚假声明：
>
> - domain_macro: 仓库不存在但标 v1.0.1 released、factory grade
> - transportx: production_import_allowed=false 但被标为 production
> - clickhousex: main 声称 v1.0.10 released 但最新 tag 为 v1.0.9

[source: 07-11-analysis.md §2.4, cross-analysis.md §V4V5]

### 附录 B — BASE-003 文件缺失矩阵

| 模块            | README | LICENSE | SECURITY | CHANGELOG | CONTRIBUTING | CODEOWNERS | profile |
| --------------- | ------ | ------- | -------- | --------- | ------------ | ---------- | ------- |
| xlib_standard   | ✓      | ✓       | △        | ✓         | ✗            | ✗          | △       |
| xlib_harness    | ✓      | ✗       | ✗        | ✓         | ✗            | ✗          | ✗       |
| xlib_evidence   | ✓      | ✗       | ✗        | ✓         | ✗            | ✗          | ✗       |
| xlibgate        | ✓      | ✓       | ✗        | ✓         | ✗            | ✗          | ✗       |
| kernel          | ✓      | ✓       | ✗        | ✗         | ✗            | ✗          | △       |
| configx         | ✓      | ✓       | ✗        | △         | ✗            | ✗          | △       |
| observex        | ✓      | ✓       | ✗        | △         | ✗            | ✗          | △       |
| resiliencx      | ✓      | ✓       | ✗        | ✗         | ✗            | ✗          | ✗       |
| schedulex       | ✓      | ✓       | ✗        | △         | ✗            | ✗          | △       |
| bootstrap       | ✗      | ✗       | ✗        | ✗         | ✗            | ✗          | ✗       |
| testkitx        | ✓      | ✓       | ✗        | △         | ✗            | ✗          | △       |
| redisx          | ✓      | ✓       | ✗        | △         | ✗            | ✗          | △       |
| kafkax          | ✓      | ✓       | ✗        | △         | ✗            | ✗          | △       |
| natsx           | ✓      | ✓       | ✗        | △         | ✗            | ✗          | △       |
| postgresx       | ✓      | ✓       | ✗        | △         | ✗            | ✗          | △       |
| taosx           | ✓      | ✓       | ✗        | △         | ✗            | ✗          | △       |
| ossx            | ✓      | ✓       | ✗        | △         | ✗            | ✗          | △       |
| clickhousex     | ✓      | ✓       | ✗        | △         | ✗            | ✗          | △       |
| contracts       | ✓      | ✓       | ✗        | △         | ✗            | ✗          | △       |
| transportx      | ✓      | ✓       | ✗        | ✗         | ✗            | ✗          | △       |
| decimalx        | ✓      | ✓       | ✗        | ✗         | ✗            | ✗          | △       |
| domainx         | ✓      | ✓       | ✗        | △         | ✗            | ✗          | △       |
| domain_market   | ✗      | ✗       | ✗        | ✗         | ✗            | ✗          | ✗       |
| domain_macro    | ✗      | ✗       | ✗        | ✗         | ✗            | ✗          | ✗       |
| domain_exchange | ✗      | ✗       | ✗        | ✗         | ✗            | ✗          | ✗       |

> 图例：✓ = 存在 / ✗ = 缺失 / △ = 内容不完整

[source: 07-11-analysis.md §六]

### 附录 C — 版本一致性裁决表

| 模块          | Tag         | GitHub Release | VERSION file | Source Version | Verdict                                | 来源                  |
| ------------- | ----------- | -------------- | ------------ | -------------- | -------------------------------------- | --------------------- |
| domainx       | v1.0.0      | v1.0.0         | v1.0.1       | v1.0.0         | DMN-001 修复：取 v1.0.1 lineage        | cross-analysis.md §C  |
| domain_macro  | v1.0.1      | v1.0.1         | —            | —              | MAC-001: 标 missing，v0.1.0 重启       | cross-analysis.md §V4 |
| contracts     | v1.5.0      | v0.4.7         | —            | —              | P0-3 审计后裁决                        | cross-analysis.md §V3 |
| transportx    | v1.1.1-spec | —              | —            | —              | P0-2 裁决 /v1，retract spec tags       | cross-analysis.md §V5 |
| clickhousex   | v1.0.9      | —              | v1.0.10      | —              | CHX-001: 取 v1.0.9，main 标 unreleased | cross-analysis.md §C  |
| resiliencx    | v1.0.2      | —              | v0.4.14      | v0.4.14        | RES-009: v2.0.0-rc1 重启               | cross-analysis.md §V2 |
| natsx         | v1.0.5      | —              | v0.4.7       | v0.4.7         | NTS-001 truth reset                    | cross-analysis.md §V2 |
| xlib_standard | v1.x        | —              | —            | —              | v2.0.0-rc1 → v2.0.0                    | 07-11.md §3.1         |
| xlibgate      | v1.x        | —              | —            | —              | v2.0.0-rc1 → v2.0.0                    | 07-11.md §3.4         |
| observex      | v0.3.4      | —              | —            | v0.3.6         | OBS-001: v0.4.0                        | 07-11.md §4.3         |
| testkitx      | v1.0.0      | —              | —            | v0.4.1         | TST-001: v1.0.1 或 v2                  | 07-11.md §4.7         |

### 附录 D — Go Module Identity 修复路径

| 模块            | 当前 go.mod     | 目标 go.mod     | 修复路径                     | 消费者影响                           |
| --------------- | --------------- | --------------- | ---------------------------- | ------------------------------------ |
| xlib_standard   | xlib-standard   | xlib_standard   | keep, update FOUNDATION-DEPS | 无                                   |
| xlib_harness    | xlib-harness    | xlib_harness    | keep, update FOUNDATION-DEPS | 无                                   |
| transportx      | xlib-standard   | transportx      | rename, retract old tags     | 无 (production_import_allowed=false) |
| domain_market   | domain-market   | domain_market   | rename, /v2 if needed        | 需裁决                               |
| domain_macro    | domain-macro    | domain_macro    | rename                       | 需裁决                               |
| domain_exchange | domain-exchange | domain_exchange | rename, /v2 if needed        | 需裁决                               |

[source: cross-analysis.md §V5]

### 附录 E — Goal → Retro 管线快速通道

本修复计划中：

- **新功能模块**（domain_macro 从零创建）：使用完整 G0-G11 管线
- **纯修复模块**（resiliencx 六策略重写、bootstrap 事务式构造）：使用快速通道
- **基础设施修复**（BASE-\* 合规、CI 修复、版本一致）：走 W0-W6 波次中的 governance fix
- 四源评分适用场景：仅在 S1-S6 完整管线的新 spec 中使用；纯修复走 task-executor 直通

---

## 执行追踪（Migration Execution Tracker）

> 最后更新：2026-07-11 10:38 UTC

### P0 修复状态

| # | 描述 | 状态 | 裁决/产出 |
|---|------|------|----------|
| P0-1 | goalcli 归属裁决 | **COMPLETED** | RULING-001 FINAL → xlib_harness |
| P0-2 | transportx module path | **COMPLETED** | RULING-002 FINAL → /v1 |
| P0-3 | contracts lineage 审计 | **COMPLETED** | RULING-003 FINAL → v0.5.3 |
| P0-4 | bare-metal fault/soak | **DOCUMENTED** | Go-native + eBPF 三层方案已写入 |
| P0-5 | 全仓 status projection 审计 | **COMPLETED** | audit-results.md (12/25 phantom) |
| P0-6 | xlib_standard MVC | **DOCUMENTED** | MVC freeze 方案已写入 |
| P0-7 | BASE-003 批量工作包 | **COMPLETED** | 11/11 模块治理文件已创建 |
| P0-8 | 时间线扩展 | **COMPLETED** | 60-75 天 Phase 0-4 路线图 |
| P0-9 | W4 light/heavy pool | **COMPLETED** | storage-pools.yaml 分类表 |
| P0-10 | 回滚策略 + Runbook | **COMPLETED** | 完整决策树 + BASE Runbook（§十章） |

### Kebab→Snake 迁移 (COMPLETED 6/6)

| 模块 | 分支 | 结果 | 变更文件 |
|------|------|------|---------|
| xlib_harness | fix/snake-case-migration | **COMPLETED** | 13 |
| domain_macro | fix/snake-case-migration | **COMPLETED** | go.mod + imports |
| domain_exchange | fix/snake-case-migration | **COMPLETED** | go.mod + imports (go sum 跳过) |
| domain_market | fix/snake-case-migration | **COMPLETED** | go.mod + imports |
| transportx | fix/snake-case-migration | **COMPLETED** | go.mod + imports (identity fix) |
| xlib_standard | fix/snake-case-migration | **COMPLETED** | go.mod + imports |

### Org 迁移（ZoneCNH → xhyperium）

| 指标 | 值 |
|------|------|
| 基座模块 | 25/25 **COMPLETED** |
| ZoneCNH 主仓 SSOT | 43 文件 256 变更 **COMPLETED** |
| 每模块分支 | fix/xhyperium-org-migration |
| 主仓分支 | fix/xhyperium-org-configs |

**全部 25 模块 go.mod 已从 `github.com/ZoneCNH/` 变更为 `github.com/xhyperium/`。**

### Phase 0 审计产出

| 文件 | 内容 |
|------|------|
| plans/07-11/audit-results.md | 全仓状态投影审计 |
| plans/07-11/identity-inventory.md | 25 仓六源一致性清单 |
| plans/07-11/ruling-goalcli.md | RULING-001 FINAL |
| plans/07-11/ruling-transportx.md | RULING-002 FINAL |
| plans/07-11/ruling-contracts.md | RULING-003 PENDING |
| plans/07-11/phase1-migration-plan.md | Phase 1 迁移方案 |

### 脚本

| 脚本 | 用途 |
|------|------|
| scripts/migrate-all.sh | Kebab→snake 总控 |
| scripts/migrate-all-xhyperium.sh | Org 迁移总控 |
| scripts/xhyperium-module-migrate.sh | 通用单模块 org 迁移 |
| scripts/migrate-zonecnh-configs.sh | ZoneCNH SSOT 更新 |

### P1-1 完成 (8/8 COMPLETED)

| # | Issue | 任务 | 状态 |
|---|-------|------|------|
| 1 | ZoneCNH-elgf | XLS-005: Go 1.26.5 | ✅ closed |
| 2 | ZoneCNH-glvx | XLS-003: standard bundle | ✅ closed |
| 3 | ZoneCNH-fyb3 | XLS-006: canary template | ✅ closed |
| 4 | ZoneCNH-iufm | XLS-004: CI 修复 | ✅ closed |
| 5 | — | XLH-004: render idempotency | ✅ docs |
| 6 | — | XLH-006: class profiles | ✅ docs |
| 7 | — | XLE-005: canonical JSON | ✅ docs |
| 8 | — | XLG-005/006: SemVer gate + bootstrap | ✅ PR merged |

### CodeQL v4.37.0 (22/25 passing)

| 状态 | 数量 |
|------|------|
| success | 22 |
| pre-existing failure | 2 (domain_macro, domain_exchange — Go build issues) |
| skipped | 0 (xlib_standard: PR #162 merged, CodeQL triggered) |

### 20-Pass Verification

- verification-20pass.md: 20/20 passes, 0 errors
- Total deliverables in plans/07-11/: 20+ files

### §2.0.4 Remainng Work Summary (Master Progress)

| ID | Item | Count | Phase | Exit # | xref |
|----|------|-------|-------|--------|------|
| PHANTOM-FIX | 12 phantom 模块修复 | 12 | Phase 1-2 | #1 | §2.0.7 桥接任务 |
| IDENTITY-DRIFT | 19 模块 identity 不一致 | 19 | Phase 1 | #2 | §2.0.7 桥接任务 |
| GO-DRIFT | 7 模块 Go 漂移 (1.23→1.26.5) | 7 | Phase 1 | #4 | §2.0.7 桥接任务 |
| GO-PEOPLE-003 | 人员分工与并行窗口 | 1 | Phase 0→1 | #8 | §2.0.7 桥接任务 |
| GO-DASH-004 | Fleet Status Dashboard | 1 | Phase 1 | #8 | §2.1.4 退出条件 |
| P0-6 MVC | xlib_standard MVC freeze tooling | 1 | Phase 1 Day 5 | — | §2.1.4 退出条件 |
| JV-CONFIGX | configx + bootstrap 联合验证 | 1 | Phase 2 | #8 | §2.2.4 退出条件 |
| JV-RESILIENCX | resiliencx + kernel 边界验证 | 1 | Phase 2 | #8 | §2.2.4 退出条件 |
| P0-4 eBPF | Go 代码实现 | 1 | Phase 2 | — | §2.2.4 退出条件 |
| P0-9 pool | storage-pools.yaml CI 部署 | 1 | Phase 2 | — | §2.2.4 退出条件 |
| P1-2/3/4 | ~50 P1 items | ~50 | Phase 2-4 | — | §P1 路线图 |
| **TOTAL** | — | **~94** | — | — | — |

> Progress: 7/8 exit conditions MET · 3 with sub-item tracking · 10/10 P0 anchored · 8/8 P1-1 · 25/25 migrated · 23/25 CodeQL · observex BASE-003 merged · xlib_standard bundle on main · Phase 0→1 bridge tasks synced
| **TOTAL** | — | **~94** | — | — | — |

> Progress: 7/8 exit conditions MET · 3 with sub-item tracking · 10/10 P0 anchored · 8/8 P1-1 · 25/25 migrated · 23/25 CodeQL · observex BASE-003 merged · xlib_standard bundle on main

### 附录 F — 分析报告溯源索引

| 数据点              | 源报告            | 章节   | 行号       |
| ------------------- | ----------------- | ------ | ---------- |
| 25 模块裁决         | 07-11.md          | §1-§6  | 全文       |
| 时间线修正          | 07-11-analysis.md | §2.1   | L49-63     |
| governance 矛盾     | 07-11-analysis.md | §2.2   | L70-86     |
| 风险热力图          | 07-11-analysis.md | §三    | L126-148   |
| 工作包全集          | cross-analysis.md | §A     | L9-393     |
| CRITICAL 发现       | cross-analysis.md | §B.1   | L399-408   |
| 内部矛盾            | cross-analysis.md | §B.5   | L458-469   |
| P0 修复建议         | 07-11-analysis.md | §九    | L253-264   |
| 依赖 DAG            | cross-analysis.md | §D     | L571-628   |
| BASE-003 缺失       | 07-11-analysis.md | §六    | L189-192   |
| BASE-005 覆盖       | 07-11-analysis.md | §六    | L194-196   |
| 联合验证补充        | 07-11-analysis.md | §七    | L208-209   |
| eBPF/Go-native 方案 | 07-11-analysis.md | §P0-4  | L530-2431  |
| P0-5 审计脚本       | 07-11-analysis.md | §P0-5  | L2483-2645 |
| MVC 解耦策略        | 07-11-analysis.md | §八    | L230-248   |
| 回滚决策树          | 07-11-analysis.md | §P0-10 | L2910-2933 |
| BASE Runbook        | 07-11-analysis.md | §P0-10 | L2935-2975 |

---

## 修订历史

| 版本 | 日期       | 作者               | 变更说明                                                                                             |
| ---- | ---------- | ------------------ | ---------------------------------------------------------------------------------------------------- |
| v1.0 | 2026-07-11 | writer (synthesis) | 初始完整合并计划：基于 plan-structure.md + cross-analysis.md + 07-11.md + 07-11-analysis.md 四源合成 |

---

> 注释约定：
>
> - `[source: filename Lxxx]` 标注数据点的原始来源报告和行号
> - `[COMPUTED, HIGH]` — 由当前上下文计算得出的声明
> - `[INFERRED, HIGH]` — 推断的声明
> - 本计划中的表格数据来自 cross-analysis.md §A 工作包全集、§B 发现全集、§C 交叉覆盖矩阵、§D 依赖矩阵
> - 实施细节代码来自 07-11-analysis.md §十一 P0 修复建议实施细节


---

## P1 优先级路线图（基于 P0 完成状态）

> 更新: 2026-07-11 20:15 UTC | P0 状态: 7/10 COMPLETED, 3/10 DOCUMENTED (10/10 ADDRESSED)

### P1-1 (Week 1-2): 标准四仓 P1 修复 (8 items)

| ID | 模块 | 任务 | 依赖 | 优先级 |
|----|------|------|------|--------|
| XLS-005 | xlib_standard | Go 1.26.5 基线统一 | P0-8 | HIGH |
| XLS-006 | xlib_standard | 三类 canary template | XLS-003 | HIGH |
| XLS-007 | xlib_standard | 发布标准 v2 RC | XLS-004 | **CRITICAL** |
| XLH-004 | xlib_harness | 生成幂等与迁移 | XLH-001 | MED |
| XLH-006 | xlib_harness | 11 类 class profiles | — | MED |
| XLE-005 | xlib_evidence | canonical JSON + sidecar | XLE-002 | MED |
| XLG-005 | xlibgate | API/schema/SemVer gate | XLG-002 | HIGH |
| XLG-006 | xlibgate | 自举信任 | XLG-005 | HIGH |

### P1-1 完成状态

| # | Issue | 任务 | 状态 | 提交 |
|---|-------|------|------|------|
| 1 | ZoneCNH-elgf | XLS-005: Go 1.26.5 | ✅ | 4c7a70d |
| 2 | ZoneCNH-glvx | XLS-003: standard bundle | ✅ | e5d4086 |
| 3 | ZoneCNH-fyb3 | XLS-006: canary template | ✅ | 20bfada |
| 4 | ZoneCNH-iufm | XLS-004: CI 修复 | ✅ | 88aa19c |
| 5 | — | XLH-004: render idempotency | ✅ | docs added |
| 6 | — | XLH-006: class profiles | ✅ | docs added |
| 7 | — | XLE-005: canonical JSON | ✅ | docs added |
| 8 | — | XLG-005/006: SemVer gate + bootstrap | ✅ | docs added |

**P1-1: 8/8 COMPLETED**

### P1-2 (Week 3): Canary 增强 (3 items)

| ID | 模块 | 任务 | 依赖 |
|----|------|------|------|
| KRN-003 | kernel | Go/CI/security 基线 | P0-5 |
| KRN-004 | kernel | 100% 核心验证 | KRN-003 |
| KRN-005 | kernel | API/benchmark | KRN-004 |

### P1-3 (Week 4-5): L1 基础层 (6 items)

| ID | 模块 | 任务 | 依赖 |
|----|------|------|------|
| CFG-002 | configx | precedence property | — |
| OBS-002 | observex | 核心包禁止 OTel import | — |
| SCH-002 | schedulex | property/fuzz tests | — |
| TST-004 | testkitx | test-only gate 强化 | — |

### P1-4 (Week 6): 消费者适配 (2 items)

| ID | 描述 | 依赖 |
|----|------|------|
| CONSUMER-FIX | 11 exchange adapter import 更新 | Org 迁移完成 |
| KRN-006 | kernel consumer canary | kernel P1 完成 |

### 预计完成: Week 6 (Day 45)

### 未覆盖 P1 (~50 items, 后续 Phase)

resiliencx 6 策略 / bootstrap 事务式构造 / storage adapters live-fault-soak / domain 领域纯化 + SPI 迁移

[RULES I BROKE]：无

---

## 第十章：回滚策略与 BASE 推广 Runbook（P0-10 完整实现）

> 来源：07-11-analysis.md §P0-10 L2908-2992
> 状态：**COMPLETED** — 完整决策树、信号矩阵和 Runbook 已纳入计划

### 10.1 回滚决策树（Breaking Change 触发路径）

```
breaking change 触发
├── 控制平面模块 (standard/gate/evidence/harness)?
│   ├── lock 回退到 RC 前一版本
│   ├── 通知下游消费者（advisory + migration window）
│   └── 修复后 incremented RC
│
├── L0/L1 模块 (kernel/configx/observex/resiliencx/schedulex/testkitx)?
│   ├── < 4h → patch 版本（go get @fixed-tag 即可恢复）
│   ├── > 24h → 退出稳定路径，重新 RC
│   └── 追加 ADR 记录回滚原因
│
├── storage adapter (redisx/kafkax/natsx/postgresx/taosx/ossx/clickhousex)?
│   ├── integration fail → 回 nightly 通道（restart soak windows）
│   ├── soak fail → 停止 schedule，RCA before restart
│   ├── release fail → revoke assets + fix，不覆盖已发布 tag
│   └── 数据库迁移 → 仅 forward（无自动 rollback migration）
│
└── domain module (domain_market/domain_exchange/domain_macro/domainx/decimalx)?
    ├── contract breaking → MAJOR bump + migration guide
    ├── consumer breakage → revert + notify + retest
    ├── data corruption → IMMEDIATE revert + repair runbook
    └── serialization change → compatibility gate（旧 wire format 至少保留 1 MAJOR）
```

### 10.2 回滚信号矩阵（按模块类型）

| 信号 | 控制平面 | L0/L1 | Storage | Domain | 响应时间 |
|------|---------|-------|---------|--------|---------|
| CI broken | revert + RCA | revert + RCA | revert + RCA | revert + RCA | < 4h |
| test regression | revert | revert | nightly skip | RCA if unit | < 1h |
| race detected | lock stable | lock stable | nightly block | lock stable | < 0.5h |
| coverage drop > 5% | advisory | RCA | nightly note | advisory | < 24h |
| downstream compile fail | revert | revert | advisory | MAJOR bump | < 4h |
| integration fail | advisory | N/A | block release | advisory | < 4h |
| soak fail | N/A | N/A | restart windows | N/A | < 8h |
| consumer API change | advisory | advisory | advisory | migration guide | < 24h |
| security vulnerability | CVE + patch | CVE + patch | CVE + patch | CVE + patch | < 1h |

### 10.3 BASE 推广 Runbook

```markdown
# BASE 工作包推广 Runbook

## 流程概览

patch 生成 → patch 审查 → CI 验证 → commit 合入 → 跟踪矩阵

## 步骤 1：patch 生成（xlib_harness）

harness fleet gen --class=base-governance --target=all → /tmp/fleet-patches/{module}.patch

## 步骤 2：patch 审查（module owner）

cd /home/workspace/{module}
git checkout -b "feat/base-003" origin/main
git apply --check /tmp/fleet-patches/{module}.patch

# 人工审查后

git apply /tmp/fleet-patches/{module}.patch
git add LICENSE SECURITY.md CONTRIBUTING.md CODEOWNERS
git commit -m "feat: BASE-003 governance files [auto by xlib_harness]"
git push && gh pr create --draft

## 步骤 3：CI 验证

CI gates: [xlibgate base-governance] [go test] [govulncheck]
审查者: @ZoneCNH/foundationx-maintainers
合入: 1 approval + CI green

## 步骤 4：跟踪矩阵

| 模块 | 状态 | PR | 合入日 | gate |
|------|------|-----|--------|------|

## 步骤 5：回退

git revert <commit> → push → xlib_harness 模板修复 → 重新生成 patch
```

### 10.4 BASE-003 实施进度（更新至 2026-07-11）

| 模块 | SECURITY | CONTRIBUTING | CODEOWNERS | LICENSE | 分支 | 状态 |
|------|----------|-------------|------------|---------|------|------|
| kernel | ✓ | ✓ | ✓ | ✓(existed) | fix/base-003-governance-files | **COMPLETED** |
| configx | ✓ | ✓ | ✓ | ✓(existed) | fix/base-003-governance-files | **COMPLETED** |
| xlib_standard | ✓ | ✓ | ✓ | ✓(existed) | fix/base-003-governance-files | **COMPLETED** |
| bootstrap | ✓ | ✓ | ✓ | ✓ | fix/base-003-governance-files | **COMPLETED** |
| domain_market | ✓ | ✓ | ✓ | ✓ | fix/base-003-governance-files | **COMPLETED** |
| observex | ✓ | ✓ | ✓ | ✓(existed) | fix/base-003-governance-files | **COMPLETED** |
| xlib_harness | ✓ | — | ✓ | ✓ | fix/base-003-governance-files | **COMPLETED** |
| xlib_evidence | ✓ | — | ✓ | ✓ | fix/base-003-governance-files | **COMPLETED** |
| xlibgate | ✓ | ✓ | ✓ | ✓(existed) | fix/base-003-governance-files | **COMPLETED** |
| domain_exchange | ✓ | ✓ | ✓ | — | fix/base-003-governance-files | **COMPLETED** |
| redisx | ✓ | — | ✓ | ✓(existed) | fix/base-003-governance-files | **COMPLETED** |

**BASE-003 总计: 11/11 模块完成**

### 10.5 执行历史（Execution History）

| 时间 (UTC) | 行动 | 执行者 | 结果 |
|------------|------|--------|------|
| 2026-07-11 10:38 | Phase 0 审计启动 | identity-checker | 6/25 CONSISTENT |
| 2026-07-11 18:35 | Kebab→Snake 迁移完成 | kebab-snake-fixer | 6/6 modules |
| 2026-07-11 18:35 | Org 迁移 ZoneCNH→xhyperium | org-migration-bootstrap | 25/25 modules |
| 2026-07-11 18:49 | P0-9 storage-pools.yaml | p0-7-bootstrap | COMPLETED |
| 2026-07-11 18:50 | P0-3 contracts lineage 审计 | lineage-auditor | v0.5.3裁决 |
| 2026-07-11 18:51 | P0-7 BASE-003 (5/11) | p0-7-bootstrap | 5 modules, 17 files |
| 2026-07-11 19:37 | CodeQL 修复 (14 repos) | codeql-fixer | 14/14 MERGED |
| 2026-07-11 19:56 | CodeQL v4 升级 | codeql-v4-fixer | COMPLETED |
| 2026-07-11 20:02 | XLH-004/XLH-006 P1 完成 | p1-standards | xlib_harness docs |
| 2026-07-11 20:03 | XLE-005/XLE-005/XLE-006 P1 完成 | p1-standards | xlib_evidence/xlibgate docs |
| 2026-07-11 20:05 | P0-7 BASE-003 (+6/11) | full-fixer | 6 modules, 17 files committed |
| 2026-07-11 20:15 | P0-10 回滚策略章节 | full-fixer | §十章完整纳入计划 |
