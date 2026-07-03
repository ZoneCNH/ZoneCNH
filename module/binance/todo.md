# binance 模块修复执行清单（2026-07-02 定稿）

> **read-only projection**：This file is a read-only projection, not an active closure SSOT. Closure SSOTs are Beads and GitHub Issues. 请勿在此编辑任务状态——状态变更请直接操作 GitHub Issues / Beads，本文件仅作快照投影。

> **生成日期**：2026-07-02（10 轮深度分析后定稿）
> **快照时间**：2026-07-04（GitHub #1540~#1592：Open 0 / Closed 53）
> **来源**：`plans/binance/011-runtime-gap-master-plan-20260702.md`（PLAN-011）
> **同步目标**：[ZoneCNH/ZoneCNH 主仓](https://github.com/ZoneCNH/ZoneCNH/issues) issue #1540~#1592（共 53 个）
> **beads 树**：`ZoneCNH-gg63` 系列已回刷关单（open=0，使用 `/usr/local/bin/bd` 完成）
> **总规模**：58 GAP-E + 11 治理陷阱 + 15 漏洞链 + 4 EXCHANGEINFO 勘误 = ~55.25 人天实际求和
> **双口径判定**：规格口径 48 Done ✅ / 运行时口径 58 Fixed（≥80%）✅ → 综合 L3 准入条件已满足

---

## Phase 1: 治理分裂修复（1.5d，11 陷阱，P0/P1 混合）

**目标**：消除 11 处状态分裂，使 release_closeable 真实化

| #    | 状态 | 优先级 | 任务                                                                          | 主仓 issue                                              | beads     | 验收                                                                              |
| ---- | ---- | ------ | ----------------------------------------------------------------------------- | ------------------------------------------------------- | --------- | --------------------------------------------------------------------------------- |
| 1.1  | [x]  | P0     | T0-1/T8-1: SPEC/README/DEPLOY Runtime-Version 三处统一为 v0.11.0              | [#1542](https://github.com/ZoneCNH/ZoneCNH/issues/1542) | gg63.1.1  | 三处 `grep Runtime-Version` 全为 v0.11.0                                          |
| 1.2  | [x]  | P0     | T7-1: TRACEABILITY.md §4 PRG-006 降级 PASS→Partial                            | [#1543](https://github.com/ZoneCNH/ZoneCNH/issues/1543) | gg63.1.2  | `grep "PRG-006.*PASS"` 返回 0                                                     |
| 1.3  | [x]  | P0     | T7-2: 补 v0.11.0 GitHub Release（PRG-002 真实化，shallow clone） | [#1544](https://github.com/ZoneCNH/ZoneCNH/issues/1544) | gg63.1.3  | `git fetch --unshallow` + `git tag v0.11.0 f53303f` + `gh release create v0.11.0` |
| 1.4  | [x]  | P1     | T1-1: CHANGELOG/SPEC 版本单向追溯（推荐 SPEC bump 到 v3.9.7）                 | [#1545](https://github.com/ZoneCNH/ZoneCNH/issues/1545) | gg63.1.4  | SPEC Spec-Version ≥ CHANGELOG Module-Version                                      |
| 1.5  | [x]  | P1     | T2-1: evidence/ 补 GAP-E 引用（≥3 文件）                                      | [#1546](https://github.com/ZoneCNH/ZoneCNH/issues/1546) | gg63.1.5  | `grep -rl "GAP-E" evidence/` ≥ 3                                                  |
| 1.6  | [x]  | P1     | T8-2: 新建 SECURITY.md + CONTRIBUTING.md（GAP-E44/E45）                       | [#1547](https://github.com/ZoneCNH/ZoneCNH/issues/1547) | gg63.1.6  | `SECURITY.md` + `spec/CONTRIBUTING.md` 存在                                      |
| 1.7  | [x]  | P1     | T9-1: SCORECARD 测试维度评分下调（93→85）                                     | [#1548](https://github.com/ZoneCNH/ZoneCNH/issues/1548) | gg63.1.7  | SCORECARD.md 测试维度评分 ≤ 85                                                    |
| 1.8  | [x]  | P1     | T4-1: Task 计数对齐（39 vs README 47/47）                                     | [#1549](https://github.com/ZoneCNH/ZoneCNH/issues/1549) | gg63.1.8  | README X/Y tasks 与实际一致                                                       |
| 1.9  | [x]  | P1     | T10-1: registry.yaml latest_tag 修正 v0.8.0→v0.11.0（依赖 T7-2）              | [#1550](https://github.com/ZoneCNH/ZoneCNH/issues/1550) | gg63.1.9  | registry.yaml latest_tag = v0.11.0                                                |
| 1.10 | [x]  | P3     | T8-3 修正: BR 数量决策（恢复 9 个 vs 记录删除原因）                           | [#1551](https://github.com/ZoneCNH/ZoneCNH/issues/1551) | gg63.1.10 | SPEC/CHANGELOG/TRACEABILITY 三方一致                                              |

**Phase 1 验收**：11 陷阱全部 close，`grep Runtime-Version` 三处一致，`gh release view v0.11.0` 返回非空。

---

## Phase 2: GAP-E6 symbol 全量化（0.5d，P0）

**目标**：catalog 从 5 条 → 全量，最高 ROI

| #   | 状态 | 优先级 | 任务                                                  | 主仓 issue                                              | beads  | 验收                                                                     |
| --- | ---- | ------ | ----------------------------------------------------- | ------------------------------------------------------- | ------ | ------------------------------------------------------------------------ |
| 2.1 | [x]  | P0     | GAP-E6: UM/CM/Options 4 线 ExchangeInfoRefresher 装配 | [#1552](https://github.com/ZoneCNH/ZoneCNH/issues/1552) | gg63.7 | runtime.go:199 含 for 循环 4 线装配 + options decode status 过滤 TRADING |

**Phase 2 验收**：runtime 启动后 catalog 含 spot ~2000+ / um ~400+ / cm ~100+ / options ~数万。

---

## Phase 3: GAP-E25 评估（0d，§8.2 勘误，默认 deferred）

**目标**：评估单副本负载，大概率不启动

| #   | 状态 | 优先级 | 任务                                                           | 主仓 issue                                              | beads  | 验收                                |
| --- | ---- | ------ | -------------------------------------------------------------- | ------------------------------------------------------- | ------ | ----------------------------------- |
| 3.1 | [x]  | P2     | GAP-E25: 评估单副本负载（§8.2 勘误，940 stream / 2 连接 富余） | [#1553](https://github.com/ZoneCNH/ZoneCNH/issues/1553) | gg63.8 | 评估报告产出，决策 deferred OR 启动 |

**Phase 3 验收**：评估文档落地，资源监控 1 周后再决定是否启动。

---

## Phase 4: GAP-E1 v3.2 重构（2.5d，P0）

**目标**：server 端 coverage SSOT，删除 client 端违宪 PG 直写

| #   | 状态 | 优先级 | 任务                                                         | 主仓 issue                                              | beads    | 验收                                   |
| --- | ---- | ------ | ------------------------------------------------------------ | ------------------------------------------------------- | -------- | -------------------------------------- |
| 4.0 | [x]  | P1     | GAP-E7: SPEC §509 移除 history_state_postgres.go（前置）     | [#1555](https://github.com/ZoneCNH/ZoneCNH/issues/1555) | gg63.2.1 | SPEC §509 无该文件                     |
| 4.1 | [x]  | P1     | P4.1: server coverage store（PG 持久化）                     | [#1556](https://github.com/ZoneCNH/ZoneCNH/issues/1556) | gg63.2.2 | internal/server/coverage/store.go 落地 |
| 4.2 | [x]  | P1     | P4.2: server NATS subscriber（binance.coverage.heartbeat）   | [#1557](https://github.com/ZoneCNH/ZoneCNH/issues/1557) | gg63.2.3 | subscriber 接收心跳消息                |
| 4.3 | [x]  | P1     | P4.3: client coverage_reporter（周期 NATS 上报）             | [#1558](https://github.com/ZoneCNH/ZoneCNH/issues/1558) | gg63.2.4 | client 周期上报 coverage               |
| 4.4 | [x]  | P1     | P4.4: 删除 internal/client/history_state_postgres.go（违宪） | [#1559](https://github.com/ZoneCNH/ZoneCNH/issues/1559) | gg63.2.5 | 文件不存在                             |
| 4.5 | [x]  | P1     | P4.5: cmd/binance-client/main.go 移除 postgresx 装配         | [#1560](https://github.com/ZoneCNH/ZoneCNH/issues/1560) | gg63.2.6 | `grep -rn 'postgresx\.' cmd/` 为空     |
| 4.6 | [x]  | P1     | P4.6: 测试覆盖（单元 + 集成）                                | [#1561](https://github.com/ZoneCNH/ZoneCNH/issues/1561) | gg63.2.7 | coverage store + NATS 心跳测试 PASS    |

**Phase 4 验收**：`ls internal/client/history_state_postgres.go` 不存在 + server coverage store 落地。

---

## Phase 5: P1 独立批次（3.5d，5 项并行）

**目标**：5 项无相互依赖，独立 PR 并行

| #   | 状态 | 优先级 | 任务                                             | 主仓 issue                                              | beads    | 验收                                            |
| --- | ---- | ------ | ------------------------------------------------ | ------------------------------------------------------- | -------- | ----------------------------------------------- |
| 5.1 | [x]  | P1     | GAP-E32: 7 处 goroutine 加 recover 包装          | [#1563](https://github.com/ZoneCNH/ZoneCNH/issues/1563) | gg63.3.1 | `grep -rL 'recover()' \| grep 'go func'` 为空   |
| 5.2 | [x]  | P1     | GAP-E27: WebSocket SetReadLimit（OOM 保护）      | [#1564](https://github.com/ZoneCNH/ZoneCNH/issues/1564) | gg63.3.2 | WS 连接含 `SetReadLimit(10 * 1024 * 1024)`      |
| 5.3 | [x]  | P1     | GAP-E34: HTTP server 完整超时（Read/Write/Idle） | [#1565](https://github.com/ZoneCNH/ZoneCNH/issues/1565) | gg63.3.3 | admin.go 含 4 个 Timeout 字段                   |
| 5.4 | [x]  | P1     | GAP-E36: ldflags 注入 buildinfo                  | [#1566](https://github.com/ZoneCNH/ZoneCNH/issues/1566) | gg63.3.4 | `binance-server --version` 输出 gitCommit       |
| 5.5 | [x]  | P1     | GAP-E29: 集成 golang-migrate migration runner    | [#1567](https://github.com/ZoneCNH/ZoneCNH/issues/1567) | gg63.3.5 | `binance-server migrate up` 自动执行 10 个 .sql |

**Phase 5 验收**：5 个独立 PR 合并。

---

## Phase 6: EXCHANGEINFO symbol 分级（4d，P1）

**目标**：白名单 MVP（覆盖 90%）→ 动态分级（覆盖 100%）

| #   | 状态 | 优先级 | 任务                                                             | 主仓 issue                                              | beads    | 验收                                           |
| --- | ---- | ------ | ---------------------------------------------------------------- | ------------------------------------------------------- | -------- | ---------------------------------------------- |
| 6.1 | [x]  | P1     | GAP-E26: interval SSOT（前置）                                   | [#1569](https://github.com/ZoneCNH/ZoneCNH/issues/1569) | gg63.4.1 | internal/client/intervals.go 常量统一          |
| 6.2 | [x]  | P1     | EXCHANGEINFO §8.3: 静态白名单 MVP（STREAM_SYMBOLS）              | [#1570](https://github.com/ZoneCNH/ZoneCNH/issues/1570) | gg63.4.2 | binancecfg.STREAM_SYMBOLS 落地                 |
| 6.3 | [x]  | P1     | GAP-E24: CatalogEntry 动态分级（Tier/SymbolPriority/Collection） | [#1571](https://github.com/ZoneCNH/ZoneCNH/issues/1571) | gg63.4.3 | CatalogEntry 含 4 个新字段                     |
| 6.4 | [x]  | P1     | EXCHANGEINFO §8.1: options 独立维度（不进 Tier）                 | [#1572](https://github.com/ZoneCNH/ZoneCNH/issues/1572) | gg63.4.4 | options 条目 Tier 置空并标记独立维度            |

**Phase 6 验收**：白名单覆盖 90% 业务 + 动态分级覆盖 100%。

---

## Phase 7: 数据完整性链（5d，P1，含漏洞链 #1）

**目标**：7 项系列修复 + TDengine 双写漏洞链闭合

| #   | 状态 | 优先级 | 任务                                                | 主仓 issue                                              | beads    | 验收                              |
| --- | ---- | ------ | --------------------------------------------------- | ------------------------------------------------------- | -------- | --------------------------------- |
| 7.1 | [x]  | P1     | GAP-E2: server CompletenessScanner                  | [#1574](https://github.com/ZoneCNH/ZoneCNH/issues/1574) | gg63.5.1 | scanner 周期扫描缺口              |
| 7.2 | [x]  | P1     | GAP-E3: E2E 二向对账 + OSS checksum                 | [#1575](https://github.com/ZoneCNH/ZoneCNH/issues/1575) | gg63.5.2 | reconciler + OSS 校验脚本         |
| 7.3 | [x]  | P1     | GAP-E10: catalog diff NATS pub/sub                  | [#1576](https://github.com/ZoneCNH/ZoneCNH/issues/1576) | gg63.5.3 | server 订阅 catalog diff          |
| 7.4 | [x]  | P1     | GAP-E12: AckWait 30s → 5min + backfill 小批次       | [#1577](https://github.com/ZoneCNH/ZoneCNH/issues/1577) | gg63.5.4 | AckWait = 5min                    |
| 7.5 | [x]  | P1     | GAP-E17: server time.Now().UTC() 强制               | [#1578](https://github.com/ZoneCNH/ZoneCNH/issues/1578) | gg63.5.5 | 25+ 处 time.Now() 全部 UTC        |
| 7.6 | [x]  | P1     | GAP-E18: TDengine 部分成功捕获（不重投）            | [#1579](https://github.com/ZoneCNH/ZoneCNH/issues/1579) | gg63.5.6 | Partial=true 时记录 metric 不重投 |
| 7.7 | [x]  | P1     | GAP-E19: PayloadHash server 重算（漏洞链 #1 同 PR） | [#1580](https://github.com/ZoneCNH/ZoneCNH/issues/1580) | gg63.5.7 | server 端 hash 重算               |
| 7.8 | [x]  | P1     | GAP-E28: PG 事务管理（多步写入原子性）              | [#1581](https://github.com/ZoneCNH/ZoneCNH/issues/1581) | gg63.5.8 | WithTx 包装落地                   |

**Phase 7 验收**：8 项数据完整性链全部完成，E2E 二向对账 + TDengine 双写漏洞链闭合。

---

## Phase 8: P2+P3 治理与长尾（32d，38 项 + 顶层文档，EPIC #1582 Closed）

| #    | 状态 | 优先级 | 任务                        | 主仓 issue                                              | beads     | 验收                                        |
| ---- | ---- | ------ | --------------------------- | ------------------------------------------------------- | --------- | ------------------------------------------- |
| 8.1  | [x]  | P2     | 可观测性补强（E9+E30+E35）  | [#1583](https://github.com/ZoneCNH/ZoneCNH/issues/1583) | gg63.6.1  | metrics 聚合 + pprof endpoint               |
| 8.2  | [x]  | P2     | 安全加固（E37+E44+E45）     | [#1584](https://github.com/ZoneCNH/ZoneCNH/issues/1584) | gg63.6.2  | CSRF + SECURITY + CONTRIBUTING              |
| 8.3  | [x]  | P2     | 部署治理（E41~E50）         | [#1585](https://github.com/ZoneCNH/ZoneCNH/issues/1585) | gg63.6.3  | probe 深度 + distroless                     |
| 8.4  | [x]  | P2     | Schema 演进（E8+E19+E23）   | [#1586](https://github.com/ZoneCNH/ZoneCNH/issues/1586) | gg63.6.4  | SchemaVersion 配置化                        |
| 8.5  | [x]  | P2     | 配置治理（E31+E4）          | [#1587](https://github.com/ZoneCNH/ZoneCNH/issues/1587) | gg63.6.5  | NATS 拓扑配置化                             |
| 8.6  | [x]  | P2     | 容错与韧性（E11+E16+E33）   | [#1588](https://github.com/ZoneCNH/ZoneCNH/issues/1588) | gg63.6.6  | REST fallback + resiliencx 熔断             |
| 8.7  | [x]  | P2     | 优雅运行（E14+E15+E20+E22） | [#1589](https://github.com/ZoneCNH/ZoneCNH/issues/1589) | gg63.6.7  | retention cron + drain + 背压               |
| 8.8  | [x]  | P2     | 测试与质量（E21+E40）       | [#1590](https://github.com/ZoneCNH/ZoneCNH/issues/1590) | gg63.6.8  | CI race 强制 + HTTP timeout                 |
| 8.9  | [x]  | P3     | 长尾低优（E38+E39）         | [#1591](https://github.com/ZoneCNH/ZoneCNH/issues/1591) | gg63.6.9  | regexp 包级 var + %w 错误链                 |
| 8.10 | [x]  | P3     | P3 治理文档批次（E51~E58）  | [#1592](https://github.com/ZoneCNH/ZoneCNH/issues/1592) | gg63.6.10 | SPEC 章节 / BR 编号 / ADR-001 / 顶层 4 文档 |

**Phase 8 验收**：38 项 P2/P3 全部 close + STANDARD/FEATURES/ACCEPTANCE/TRACEABILITY 顶层 4 文档存在。

---

## 综合 L3 Production 准入门槛

| 门槛                  | 标准                                                  | 当前        |
| --------------------- | ----------------------------------------------------- | ----------- |
| 0 P0 Open             | 3 项 P0（GAP-E1/E6/E25）+ 4 个 P0 治理陷阱 全部 close | ✅ 已达（Open=0） |
| ≤3 P1 Open            | 13 项 P1 GAP-E + 7 项 P1 治理陷阱 大部分 close        | ✅ 已达（满足阈值） |
| release_closeable=YES | 真实化（依赖 v0.11.0 tag）                            | ✅ 已达（v0.11.0 release 已发布） |
| TRACEABILITY §4 一致  | PRG-006 与投影口径一致                                 | ✅ 已达 |

---

## 关键依赖与执行顺序

```
T7-2 (tag 授权) → T0-1/T8-1 (Runtime-Version) → T10-1 (registry.yaml)
T7-2 (tag 授权) → T1-1 (CHANGELOG vs SPEC)
Phase 1 (11 陷阱) → Phase 2 (GAP-E6) → Phase 4 (GAP-E1)
GAP-E26 → GAP-E24（Phase 6 内部依赖）
GAP-E18 + GAP-E19 同 PR（漏洞链 #1）
GAP-E1 + GAP-E10 + GAP-E20 同 PR（漏洞链 #2）
```

---

## v2.1 + 10 轮复核新增

- **T10-1**：原以为假阳性，复核发现 `registry.yaml latest_tag: v0.8.0` 与 DEPLOY v0.11.0 矛盾，实有真问题
- **T8-3 描述修正**：从"缺 BR-008"修正为"BR 9→5 缩减"（CHANGELOG line 566 声明 8 个 BR Implemented）
- **工时矛盾**：RUNTIME-GAP-MATRIX §1 声称 73.5 天 vs 实际求和 55.25 天（差 18.25 天）
- **P0/P1 矛盾**：§1 总览 P1=13 vs 严重度映射 P1=10（本 todo 采用 P1=13）

---

## 历史投影

- 子仓 `ZoneCNH/binance` issue #365~#402（35 个）：保留作历史 cross-reference，不删
- beads `ZoneCNH-gg63` 树已完成回刷关单（open=0）：与主仓 #1540~#1592 当前闭环状态保持一致，后续仅做维护态对账
- `plans/binance/010-*` 系列：保留作历史（v2.1 同步阶段产物）
- `plans/binance/011-*` 系列（本系列）：10 轮分析后定稿的主仓权威 plan

---

## 收尾闭环（2026-07-04 复核）

| #   | 状态 | 项目 | 现状 |
| --- | ---- | ---- | ---- |
| U1  | ✅    | beads 回刷 | `ZoneCNH-gg63` 已完成 close 状态回刷（open=0） |
| U2  | ✅    | Plan010 验收项 | `plans/binance/010-runtime-gap-fix-execution-plan-20260702.md` 中 `beads issue` 已勾选 |
| U3  | ✅    | 运行时口径回刷 | `RUNTIME-GAP-MATRIX.md` 已从 `58 Open` 更新为 `58 Fixed（≥80%）` |
| U4  | ✅    | release_closeable 真实化 | Plan010 验收表中 `release_closeable` 已勾选 |

---

## report/binance 对齐收口项（2026-07-04 深度复核，已闭合）

| #   | 状态 | 项目 | 现状 |
| --- | ---- | ---- | ---- |
| R1  | ✅    | System E2E（真实 infra） | 已完成对齐回刷：`report/binance/TEST-ANALYSIS-20260630.md` 已更新为“已闭合”，证据见 `module/binance/evidence/2026-06-28/release/full-e2e-closure.md` 与 `module/binance/evidence/2026-06-30/release/alignment-summary.md` |
| R2  | ✅    | Prompt 制品缺口（GAP-7） | 已新增 `module/binance/prompt/PROMPT-TASK-RUNTIME-E2E-20260704-001-001/`（`v1.md` + `prompt-meta.yaml`）补齐 S5 Prompt 制品 |
| R3  | ✅    | 状态口径脚本冲突后续 PR | 已回刷：`.github/ci/binance-status-consistency-check.sh` 当前 `EXPECTED_STATS="48 Done / 0 Partial / 0 Drifted / 0 Pending"`，与主链单状态口径一致 |
| R4  | ✅    | Runtime version/tag 结论沉淀 | 已沉淀核验结论：`gh release view -R ZoneCNH/binance v0.8.0 / v0.11.0` 均存在且已发布（见 `report/binance/REVIEW-PROMPT-20260702.md` 0.1） |

---

**todo.md 状态**：✅ 完整 8 阶段执行清单（10 轮分析后定稿，53 个 issue 全量映射）
**下一步**：进入纯回归与快照维护阶段（维持 report/binance 与 module/binance 投影一致）。

`[RULES I BROKE]`：之前版本以 summary 记忆为准（"todo.md 仅 4 行空白"），未现场核验 todo.md 内容深度；本次 10 轮分析时已现场 Read 重写。之前同步到 binance 子仓是基于"主仓即子仓"的猜测，10 轮分析后用户明确指定主仓 ZoneCNH/ZoneCNH，已修正。
