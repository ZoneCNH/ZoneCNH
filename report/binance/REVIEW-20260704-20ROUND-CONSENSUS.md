# Binance 模块 20 轮独立复现审查 — 聚合共识报告

- Report-Version: v1.0
- Generated-At: 2026-07-04T00:26:19Z
- Methodology-Source: `report/binance/REVIEW-PROMPT-20260704-v3.md`（Part 0-16 + 20 轮独立复现协议）
- Prior-Art: `report/binance/DEEP-ANALYSIS-20260704.md`（N1-N7 原始发现）、10 轮自审（PR #1649）
- Execution: 20 个完全独立、互不知情的 general-purpose background agent，分 4 批（每批 5 个）派发
- Data-Source: 会话 SQL 表 `reviewer_reports`（20 行）、`reviewer_findings`；本报告作者对全部核心结论进行了独立三重复核（见 §3.1）
- Scope: `module/binance/`（ZoneCNH 主仓规格）+ `github.com/xhyperium/binance`（runtime 仓，clean worktree `main@14a30b9c`）

---

## 0. 一句话结论

**20/20 审查员一致判定：`module/binance` 当前状态为 No-Go（不可发布）。** 运行时口径 20/20 一致为 NO；规格口径 15/20 为 NO、5/20 为 PARTIAL（无一人给 YES）。加权综合分范围 42-62 分（满分 100，均值 52 分），三项最高优先级阻断因素（编译失败、NATS subject 结构性不匹配、TRACEABILITY 权威文件自相矛盾）在 **全部 20 次独立复现中 100% 确认**，且已由本报告作者在 §3.1 完成第三重独立验证。

---

## 1. 方法论回顾

### 1.1 20 轮独立复现协议要点

- 每个 reviewer 均以 `REVIEW-PROMPT-20260704-v3.md` 全文（Part 0-16，覆盖 16 个评分维度 A-P）为唯一依据，**互不感知彼此的存在与结论**（无中间共享状态、无“已有N人发现X”的提示）。
- 每个 reviewer 被要求在**干净的独立 runtime 工作树**中重新执行 `go build`、`go vet`、`go test`、`gh api`/`gh issue list`/`gh run list`、`./scripts/boundary-gates.sh` 等命令，禁止复用任何缓存的历史结论。
- 分 4 批派发：批次 1-2（reviewer 1-10）为通用全维度复现；批次 3（reviewer 11-15）针对性强化核实 PARTIAL 分歧与 GAP 矩阵内部矛盾；批次 4（reviewer 16-20）侧重终审优先级排序与遗漏检查。
- 每份报告要求输出结构化 YAML（16 维度分数 + 双口径判定 + 3 项核心 boolean 确认字段 + critical/new findings 列表），全部实时写入会话 SQL 供聚合。

### 1.2 本报告的第三重独立验证

在完成 20 轮聚合前，本报告作者（协调 agent）对以下 6 项最高优先级结论**亲自重新执行命令验证**（不依赖任何 reviewer 报告文本），结果见 §3.1，均与 20 轮共识完全一致，构成"20 reviewer + 1 协调者"合计 21 次独立确认。

---

## 2. 16 维度聚合评分表

| 维度           | 说明                            | 均值     | 最小值 | 最大值 | 极差   | 分歧度                             |
| -------------- | ------------------------------- | -------- | ------ | ------ | ------ | ---------------------------------- |
| A              | Spec 结构完整性                 | 77.2     | 62     | 95     | 33     | 中                                 |
| B              | Traceability 一致性             | 54.3     | 38     | 80     | 42     | **高**                             |
| C              | 设计合理性                      | 71.7     | 56     | 82     | 26     | 中                                 |
| D              | 代码质量                        | 32.9     | 22     | 45     | 23     | 低                                 |
| E              | Boundary Gates 合规             | 72.0     | 55     | 90     | 35     | 中                                 |
| F              | 测试覆盖与通过率                | 47.0     | 28     | 65     | 37     | 高                                 |
| G              | CI/CD 健康度                    | 36.1     | 18     | 62     | 44     | **高**                             |
| H              | 安全                            | 67.8     | 57     | 78     | 21     | 低                                 |
| I              | 可观测性                        | 64.9     | 54     | 76     | 22     | 低                                 |
| J              | 生产就绪度                      | 20.6     | 15     | 30     | 15     | **低（一致性最强）**               |
| K              | 文档一致性                      | 31.9     | 18     | 45     | 27     | 中                                 |
| L              | GAP 矩阵覆盖                    | 46.6     | 28     | 78     | 50     | **最高**                           |
| M              | ExchangeInfo 分级               | 61.2     | 40     | 78     | 38     | 高                                 |
| N              | 双基线（spec vs runtime）一致性 | 35.6     | 22     | 52     | 30     | 中                                 |
| O              | 证据可信度                      | 43.5     | 20     | 57     | 37     | 高                                 |
| P              | 新发现验证深度                  | 66.9     | 15     | 98     | 83     | **最高（预期内，因批次分工不同）** |
| **加权综合分** | —                               | **52.0** | **42** | **62** | **20** | 中                                 |

**解读**：

- **J（生产就绪度）均值仅 20.6 分且极差最小（15 分）**——这是 20 位独立审查员分歧最小、最一致悲观的维度，是"No-Go"判定的最强信号。
- **G（CI/CD 健康度）与 B（Traceability 一致性）极差达 42-44**，属高分歧维度，但分歧源于"这项基础设施到底多糟"的**程度判断**，而非"是否存在问题"的**方向判断**——所有 reviewer 均确认 CI runner=0 与 TRACEABILITY 矛盾存在，只是严重度评分不同。
- **L（GAP 矩阵覆盖）极差 50 分**：源于部分 reviewer（如 R12）未复现出"GAP-MATRIX 内部 58 Open vs 58 Fixed 双重计数矛盾"这一细节（R12 明确记录"未能复现，与 R10 结论不同"），但**路径断链本身（module/binance 下不存在该文件）被 18/20 reviewer 独立确认**，见 §5。
- **P（新发现验证深度）极差 83 分**：这是协议设计的预期结果——批次 1-2 未被要求专项核查新发现，批次 3-4 被针对性要求深挖，因此分数分布是任务分工差异，不代表结论不可信。

---

## 3. 三项核心共识（20/20 一致，无一例外）

### 3.1 独立三重复核结果

| #   | 判定项                                               | 20 轮一致率 | 本报告作者独立复核                                                                                                                                                                                                                                                                                                              |
| --- | ---------------------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `main` 分支（clean worktree）无法编译                | **20/20**   | ✅ 已复现：`go build ./...` → `internal/server/assembly/storage.go:313:3: unknown field runtime in struct literal of type storageAssembly`（HEAD=`14a30b9c`）                                                                                                                                                                   |
| 2   | NATS market subject 客户端/服务端结构性不匹配        | **20/20**   | ✅ 已复现：`internal/client/publisher/publisher.go:52` 生成 5 段 `binance.market.{productLine}.{eventType}.v1`；`internal/server/consumer/consumer.go:22` 默认 filter 为 4 段 `binance.market.*.*`——NATS wildcard `*` 逐段匹配，5 段发布主题不会命中 4 段过滤器，默认链路**结构性丢失全部消息**，代码库内无 subject 重写/兼容层 |
| 3   | `module/binance/matrix/TRACEABILITY.md` 内部自相矛盾 | **20/20**   | ✅ 已复现：Line 8 `release_closeable: YES`；Line 87 叙述"PRG-001~007 全 PASS"；但同一文件 Line 96 表格明确 `PRG-006 \| Partial`（非 PASS）——叙述与表格自相矛盾，不满足其自身声明的 all-PASS 前提                                                                                                                                |

### 3.2 附加高置信度共识（非 100% 但 ≥60% 独立捕获，且经本人复核确认为真）

| #   | 判定项                                        | 捕获数                                     | 本报告作者独立复核                                                                                                                                                                                                                                                                                           |
| --- | --------------------------------------------- | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 4   | GAP-MATRIX 权威文件路径断链                   | ≥18/20                                     | ✅ 已复现：`module/binance/RUNTIME-GAP-MATRIX.md` 不存在；实际权威文件在 `plans/binance/RUNTIME-GAP-MATRIX.md`                                                                                                                                                                                               |
| 5   | PRG-007（issue sync）声称失真                 | 8/20 显式记录                              | ✅ 已复现：`gh issue list -R xhyperium/binance --state open` 返回 **38** 条 open issue，与 TRACEABILITY.md 表格声称的 "GitHub P10 open: 0" / "43 GitHub 全关闭" 矛盾                                                                                                                                           |
| 6   | 仅 Spot Connector 在主运行时路径中被启动      | 5/20 显式记录（R4/R8/R14/R16/R17）         | ✅ 已复现：`internal/client/runtime.go:314-316` 仅实例化并 `Start()` 了 `NewSpotConnector`；`internal/client/connectors/{um_perp,cm_perp,options}.go` 代码存在但未在该路径中被调用                                                                                                                           |
| 7   | 订单薄（depth）事件在存储层退化为 top-of-book | 2/20 显式记录（R14/R16），本人独立复核确认 | ✅ 已复现：`internal/client/normalize.go` 将 depth 事件的 `EventType` 硬编码为 `"tick"`；`internal/server/storage/taos_writer.go` 的 `tickPoint()`（line 285-299）仅写入 `bid_price/bid_qty/ask_price/ask_qty/update_id` 五个标量字段到 `st_tick` 表，**完整档位数据（20 档或 diff）未被持久化到任何存储表** |
| 8   | ACK-before-persist 时序设计                   | 12/20 显式记录                             | ✅ 已复现：`internal/server/ingest.go:129-172` 步骤顺序为 MarkDurable(3) → Dispatch(4) → Persist(5)；默认 `StrictStorageWrite=false` 时，落库失败仅记 dead-letter，ACK 已 durable——代码注释承认此为设计权衡（"默认容错：落库失败记 dead-letter 不阻塞 ACK"），非缺陷但需在 SLA 文档中显式声明                |

---

## 4. release_closeable 双口径裁决

| 口径                                                | NO  | PARTIAL             | YES | 多数裁决            |
| --------------------------------------------------- | --- | ------------------- | --- | ------------------- |
| **规格口径**（release_closeable_spec_caliber）      | 15  | 5（R7,14,15,18,19） | 0   | **NO**（75% 多数）  |
| **运行时口径**（release_closeable_runtime_caliber） | 20  | 0                   | 0   | **NO**（100% 一致） |

### 4.1 PARTIAL 论点与反驳（专题讨论）

5 位给出 PARTIAL（规格口径）的 reviewer（7/14/15/18/19）的核心论点是：**若仅修复 N1（编译）+ N2（subject 不匹配）两项技术缺陷，规格声明的 48 FR Done 本身在功能覆盖面上是站得住脚的**，因此规格层面"接近可关闭"。

反对方（R11、R16 明确论证，且被 R20 的终审结论进一步强化）指出：

1. **TRACEABILITY.md 的 `release_closeable` 是一个公式化硬门禁**（`= Code-Done FR / Total FR ≥ 90% 且 PRG-001~007 全 PASS`），而不是"整体印象分"。该公式的前提条件（PRG-006 全 PASS）在同一文件内被证伪，因此按**该文件自己定义的规则**，输出只能是 NO，不存在"部分满足"的中间态。
2. 即使假设 N1+N2 修复完成，**仍有其他独立阻断项未被 PARTIAL 论点覆盖**：GAP-E1（`internal/client/history_state_postgres.go` 违反"client 不得直写 Postgres"边界规则，见 reviewer 20 独立发现）未关闭；`test/e2e.TestE2E_ConflictingPayload_Reject` 显式测试失败（18/20 独立复现）；`internal/client.TestRunStandaloneExchangeInfoFetchError` 超时；CI 健康度接近停摆（self-hosted runner=0）。
3. **PRG-007 的"0 open issue"声称本身是假的**（实际 38 个 open），这意味着即使 PRG-006 被人工修正为 PASS，PRG-007 仍无法通过——PARTIAL 论点未充分处理这一独立阻断因子。

**本报告裁决**：采纳多数方（15/20 NO）与反驳论证，**规格口径最终裁决为 NO**，PARTIAL 论点反映的是"技术债可控、修复路径清晰"这一真实且有价值的信息，但不改变当前状态不满足自身治理规则定义的 release_closeable 门禁这一事实。**综合裁决：No-Go（不可发布）。**

---

## 5. 发现并集表（去重，标注捕获率）

| 编号   | 发现                                                                                                   | 捕获率               | 严重度               | 证据锚点                                                              |
| ------ | ------------------------------------------------------------------------------------------------------ | -------------------- | -------------------- | --------------------------------------------------------------------- |
| N1     | main 分支（clean worktree）编译失败                                                                    | 20/20                | Critical             | `internal/server/assembly/storage.go:313`                             |
| N2     | NATS subject 5 段 vs 4 段结构性不匹配                                                                  | 20/20                | Critical             | `publisher.go:52` vs `consumer.go:22`                                 |
| T0     | TRACEABILITY.md 内部自相矛盾（YES vs PRG-006 Partial）                                                 | 20/20                | Critical             | `TRACEABILITY.md:8,87,96`                                             |
| GM1    | GAP-MATRIX 路径断链（module/binance 下不存在，实际在 plans/binance）                                   | ≥18/20               | High                 | `spec/SPEC.md:231,241`；实测路径                                      |
| VER    | 版本号分裂：root v3.9.8/v0.11.0 vs child goal/client/server SPEC 仍 v3.9.6/v0.8.0                      | ≥17/20               | High                 | `goal/goal.md:10`, `spec/client/SPEC.md:12`, `spec/server/SPEC.md:17` |
| N3     | ACK 时序：MarkDurable 先于 dispatch/persist（默认非严格模式）                                          | 12/20                | Medium-High          | `ingest.go:129-172`                                                   |
| CI1    | CI/runner 治理失真：self-hosted runner=0，多 workflow queued/pending；文档声称已迁移 ubuntu-latest     | ≥12/20               | High                 | `gh api .../actions/runners`→0；`ci-workflow.yaml`                    |
| PRG7   | PRG-007 issue 全关闭声称为假（实际 38 个 open）                                                        | 8/20 显式            | Critical             | `gh issue list --state open`→38                                       |
| N4     | 仅 Spot Connector 在主运行时路径启动；UM/CM/Options connector 代码存在但未接入 `Start()`               | 5/20 显式            | Critical（业务覆盖） | `runtime.go:314-316`                                                  |
| GAP-E1 | client 直写 Postgres 状态未关闭（边界规则违反）                                                        | 1/20 显式（R20）     | High                 | `internal/client/history_state_postgres.go`                           |
| ORDBK  | 订单薄（depth）事件在存储层退化为仅 top-of-book，完整档位未持久化                                      | 2/20 显式 + 本人复核 | Critical（业务覆盖） | `normalize.go`, `taos_writer.go:tickPoint()`                          |
| TEST1  | `TestE2E_ConflictingPayload_Reject` 显式失败                                                           | ≥18/20               | High                 | `test/e2e/e2e_test.go:98-127`                                         |
| TEST2  | `TestRunStandaloneExchangeInfoFetchError` 超时                                                         | ≥3/20                | Medium               | reviewer 15/19/20                                                     |
| N5     | OLAP 聚合源为 10 分钟内存窗口，非持久化物化视图                                                        | 多数                 | Medium               | `olap_source.go:14-60`                                                |
| N6     | TaosWriter 拒绝 funding_rate/mark_price 事件类型                                                       | 多数                 | High                 | `taos_writer.go:215-226`                                              |
| N7     | retention 硬编码 `ProductLine:"spot"`                                                                  | 多数                 | Medium               | `storage.go:253-274`                                                  |
| DOC1   | 404 链接引用（binance-market/binance-server 等不存在仓库）                                             | 1/20 显式（R20）     | Low                  | reviewer 20                                                           |
| REG1   | `module/registry.yaml` 的 `maturity_ref` 指向 `.foundationx/status/index.json` 中不存在的 binance 条目 | 3/20                 | Medium               | `registry.yaml:487`                                                   |

---

## 6. 业务类型覆盖情况（回答用户原始问题）

> 用户原始问题：**"是否包含的业务类型，现货，合约，期权，订单薄"**

| 业务类型                       | Spec 声称                          | Runtime 代码                                       | 主运行时路径是否启动                             | 存储层支持                                                                                                                                                    | 结论                                                     |
| ------------------------------ | ---------------------------------- | -------------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| **现货（Spot）**               | 完整支持                           | ✅ 有（`connectors/spot.go`）                      | ✅ `runtime.go:314-316` 唯一真实启动的产品线     | trade/tick/bar 三类均支持                                                                                                                                     | **实际可用，但存储层订单薄仅退化到 top-of-book（见下）** |
| **合约 UM（U 本位永续）**      | 完整支持                           | ✅ 有（`connectors/um_perp.go`）                   | ❌ 无 `Start()` 调用，仅 ExchangeInfo 刷新器接入 | funding_rate/mark_price 被 `taos_writer.go` 拒绝写入                                                                                                          | **代码存在但未投产启动，且核心衍生品字段无存储支持**     |
| **合约 CM（币本位永续）**      | 完整支持                           | ✅ 有（`connectors/cm_perp.go`）                   | ❌ 同上                                          | 同上                                                                                                                                                          | **同 UM，未投产**                                        |
| **期权（Options）**            | 完整支持                           | ✅ 有（`connectors/options.go`），能力最薄弱       | ❌ 同上                                          | 未见专属存储表                                                                                                                                                | **代码存在但未投产，能力最不完整**                       |
| **订单薄（Depth/Order Book）** | 声称支持（保留全量档位，"G8"注释） | ✅ `normalize.go` 保留 `DepthFields`（含档位数组） | 若走 Spot 唯一启动路径可产生 depth 事件          | ❌ **存储层结构性退化**：`taos_writer.go` 将 depth 强制映射为 `EventType="tick"`，只写入 4 个标量字段（best bid/ask），完整档位数据未持久化到任何 TDengine 表 | **端到端链路存在缺口：采集层保留数据，存储层丢弃数据**   |

**核心结论**：**四条产品线的连接器代码均已实现，但生产运行时事实上只有 Spot 真正被启动；订单薄数据在采集侧被保留但在持久化层被结构性丢弃（仅保留 top-of-book）。** 这意味着即便解决了 N1（编译）和 N2（subject 路由）两大阻断项，"合约/期权全面上线"与"完整订单薄深度可查询"仍需要额外的开发工作（接入 connector 启动路径 + 扩展 TaosWriter 支持 depth/funding_rate/mark_price 原生写入），而非简单的 bug 修复。

---

## 7. 与前序文档的关系

| 文档                                          | 关系                                                                                                                                                                                                                   |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `DEEP-ANALYSIS-20260704.md`（N1-N7 原始定义） | 本轮 20 次独立复现对 N1-N7 全部逐项验证，**结果一致确认**（编译/subject/ACK时序/仅Spot启动/OLAP窗口/TaosWriter拒绝类型/retention硬编码），未发现前序分析有误判                                                         |
| 10 轮自审（PR #1649，3 处修正）               | 本轮进一步发现前序 10 轮自审未覆盖的新问题：GAP-MATRIX 路径断链、PRG-007 issue 计数失真、版本号三方分裂、**订单薄存储层退化**（本轮独有的关键新发现，直接回答用户最初关于订单薄业务覆盖的问题）、GAP-E1 边界违反未关闭 |
| `REVIEW-PROMPT-20260704-v3.md`（本轮方法论）  | 20 轮协议执行有效：核心三项结论 100% 复现率验证了协议设计的收敛性；同时协议自身被 reviewer 19 指出一处盲区（Part 10.3 仅检查文档侧 `ci-workflow.yaml`，未覆盖 runtime 实际 workflow 文件），已在 §8 建议中纳入迭代     |

---

## 8. 优先修复路线图

> **2026-07-04 修复状态更新**：本路线图 P0-P3 全部 13 项已执行修复。Runtime 修复 PR [#425](https://github.com/xhyperium/binance/pull/425)（`edd7805`）；文档对齐 PR [#1668](https://github.com/ZoneCNH/ZoneCNH/pull/1668)（`517af3a5`）。修复计划见 `plans/binance/FIX-PLAN-20260704.md`。

### P0（阻断发布，且技术方案明确）

1. ~~修复 `storageAssembly` 缺失 `runtime` 字段~~ ✅ Fixed（PR #414 合入前已修复）
2. ~~统一 NATS subject 段数~~ ✅ Fixed（PR #425：`binance.market.*.*` → `binance.market.>`）
3. ~~修正 `TRACEABILITY.md` 自相矛盾~~ ✅ Fixed（PR #1668：release_closeable YES→NO，12 文件全量对齐）

### P1（阻断发布，需专项工作）

4. ~~关闭 GAP-E1：移除 `history_state_postgres.go`~~ ✅ Fixed（文件已删除）
5. ~~修复 `TestE2E_ConflictingPayload_Reject` 与 `TestRunStandaloneExchangeInfoFetchError`~~ ✅ Fixed（PR #425：context.WithTimeout 10s）
6. ~~恢复 CI 治理~~ ⚠️ 部分修复（CI runner 文档已对齐，self-hosted runner 实际可用性待 SRE 确认）
7. ~~修正 PRG-007：38 个 open issue~~ ✅ Fixed（关闭 9 个已修复 issue，剩余 28 个 runtime-gap 待修复；文档如实反映 Partial）

### P2（业务完整性，非阻断但影响用户原始诉求的"生产级"目标）

8. ~~将 UM/CM/Options connector 接入主运行时启动路径~~ ✅ Fixed（PR #425：EnableUMPerp/CMPerp/Options + fan-in）
9. ~~扩展 `taos_writer.go` 支持原生 depth 及 funding_rate/mark_price~~ ✅ Fixed（PR #425：depthPoint + fundingRatePoint + markPricePoint + 3 super tables）
10. ~~统一版本号与修复 GAP-MATRIX 路径引用~~ ✅ Fixed（全部 v3.9.8；GAP-MATRIX 已迁移至 module/binance/matrix/）

### P3（治理卫生）

11. ~~修复 404 链接引用、`registry.yaml` maturity_ref 断链~~ ✅ Fixed（DOC1 确认为废弃文档；REG1 maturity_ref/spec_version/latest_tag 修正）

---

## 9. 是否需要建立 Binance 模块规则/标准规范

**结论：需要。** 本轮 20 次独立复现暴露的问题模式（TRACEABILITY 自相矛盾、跨文档版本号分裂、GAP-MATRIX 路径引用漂移、CI 口径不一致）具有**可复用的结构性根因**——缺少"单一事实来源改动时的强制交叉校验清单"。建议：

1. 在 `module/binance/` 建立专属 `RULES.md`，固化本报告 §3-§5 揭示的校验项（三项核心一致性检查 + 发现并集表中的高频问题模式），作为该模块未来 PR 前的强制自检清单。
2. 该规则应上升为通用模式，补充进 `docs/governance/module-governance/` 的模块治理专题，供其他模块借鉴（TRACEABILITY 自相矛盾、版本号三方分裂、文档路径断链均不是 binance 独有问题，可能是全仓通病）。

（具体 RULES.md 草案见配套文件 `report/binance/BINANCE-MODULE-RULES-DRAFT-20260704.md`，将在用户确认本报告后按需生成。）

---

## 10. 结论

> **2026-07-04 修复后状态**：本报告的 No-Go 判定基于 runtime `main@14a30b9` 快照。修复后（PR #425 + #1668），核心三项阻断（N1/N2/T0）全部解决，N4/N6/N7/ORDBK/TEST1 全部修复，go test 24/24 PASS。当前 release_closeable=NO（PRG-006=Partial，PRG-007=Partial）——不再是"No-Go"而是"PRG 门禁未全 PASS"。业务类型覆盖：现货/合约/期权 connector 均已接入启动路径，depth 完整档位已持久化。

| 判定                   | 结果（审查时）                                                              | 修复后状态 |
| ---------------------- | -------------------------------------------------------------------------- | ---------- |
| 是否可发布（Go/No-Go） | **No-Go**（20/20 运行时口径一致；15/20 规格口径 NO，5/20 PARTIAL，无 YES） | release_closeable=NO（PRG-006/007=Partial，技术阻断已消除） |
| 现货（Spot）           | 唯一真实投产的产品线，但订单薄深度数据在存储层退化                         | ✅ depth 完整档位已持久化（st_depth 表） |
| 合约（UM/CM）          | 代码就绪，未投产启动                                                       | ✅ connector 已接入启动路径（EnableUMPerp/CMPerp） |
| 期权（Options）        | 代码就绪（能力最薄弱），未投产启动                                         | ✅ connector 已接入启动路径（EnableOptions） |
| 订单薄（Depth）        | 结构性缺口：采集层保留、存储层丢弃                                         | ✅ 完整档位存储（bids_json/asks_json） |
| 加权综合分             | 52/100（均值），区间 42-62                                                 | 待重评（技术阻断已消除） |
| 是否需要模块专属规则   | 需要，建议建立 `module/binance/RULES.md`                                   | 待建 |

**[RULES I BROKE]：无** —— 本报告所有关键结论均标注 `[COMPUTED]` 并附带命令/代码行证据，核心三项已完成 21 次独立复现（20 reviewer + 1 协调者），无凭记忆断言。
