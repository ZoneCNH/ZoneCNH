# Binance v0.2.0 生产发布 — 任务清单

> 创建日期：2026-06-28
> 基线：`report/binance/production-release-execution-plan-20260628.md`
> 目标：`release_closeable=YES` → v0.2.0 生产发布
> 当前：23/48 FR Done (47.9%) → 目标 48/48 (100%)
> Issue 追踪：Beads (47 issues) + GitHub #148-#194

---

## E-1 P0 Batch — Week 1（6 FRs，9 days）

| #   | FR      | GitHub | Beads       | 任务                                                        | 状态  |
| --- | ------- | ------ | ----------- | ----------------------------------------------------------- | ----- |
| 1   | FR-016  | #150   | ZoneCNH-8qd | REST fetcher 注入 + 历史回填 + cursor 恢复 e2e              | `[ ]` |
| 2   | FR-007  | #148   | ZoneCNH-ydd | Gin REST 路由完整装配 + e2e                                 | `[ ]` |
| 3   | FR-017  | #151   | ZoneCNH-r3s | depth snapshot refresh（updateId 跳跃→snapshot）            | `[ ]` |
| 4   | FR-024  | #153   | ZoneCNH-ngz | 完整 reload proof（no-restart 集成测试）                    | `[ ]` |
| 5   | FR-007a | #149   | ZoneCNH-7k1 | Analytics API（vwap/top-movers/correlation/volume-profile） | `[ ]` |
| 6   | FR-023  | #152   | ZoneCNH-if7 | 远程 CI evidence 归档                                       | `[ ]` |

**完成标准**：6 FR Partial→Done，Code-Done 23→29/48

---

## E-2 P1 Batch — Week 2（6 FRs，6 days）

| #   | FR     | GitHub | Beads       | 任务                                               | 状态  |
| --- | ------ | ------ | ----------- | -------------------------------------------------- | ----- |
| 7   | FR-011 | #154   | ZoneCNH-7eo | HA 选举（多实例锁竞争 + lease 续期 + failover）    | `[ ]` |
| 8   | FR-013 | #155   | ZoneCNH-z7p | 限流全覆盖（AIMD 恢复 + 418 熔断 + clock skew）    | `[ ]` |
| 9   | FR-025 | #156   | ZoneCNH-9he | 自适应降速（P2 降为 0 + 恢复策略 e2e）             | `[ ]` |
| 10  | FR-026 | #157   | ZoneCNH-vi7 | 对账完整运行（04:00 UTC job + tolerance + alerts） | `[ ]` |
| 11  | FR-027 | #158   | ZoneCNH-qyk | 回热完整运行（OSS→taosx 回热 + 24h TTL 过期）      | `[ ]` |
| 12  | FR-028 | #159   | ZoneCNH-zmr | 持久化验证（postgresx state-store + 重启恢复）     | `[ ]` |

**完成标准**：6 FR Partial→Done，Code-Done 29→35/48

---

## E-3 P2 Batch — Week 3（6 FRs，4.5 days）

| #   | FR     | GitHub | Beads       | 任务                                                    | 状态  |
| --- | ------ | ------ | ----------- | ------------------------------------------------------- | ----- |
| 13  | FR-031 | #160   | ZoneCNH-6i6 | 四线 ExchangeInfo 发现完整                              | `[ ]` |
| 14  | FR-032 | #161   | ZoneCNH-afb | 持久化 + 刷新（upsert + 6h diff-only + control stream） | `[ ]` |
| 15  | FR-033 | #162   | ZoneCNH-azc | tier 分级（SymbolsByTier + admin PATCH）                | `[ ]` |
| 16  | FR-034 | #163   | ZoneCNH-wdz | 白名单（deny>allow>tier 裁决 + admin reload）           | `[ ]` |
| 17  | FR-035 | #164   | ZoneCNH-r54 | admin auth（Bearer token + loopback + audit_log）       | `[ ]` |
| 18  | FR-036 | #165   | ZoneCNH-03y | 连接拓扑（StreamsForProductLineTier + 升降级 drain）    | `[ ]` |

**完成标准**：6 FR Partial→Done，Code-Done 35→41/48

---

## E-4 P2 Batch — Week 3（7 FRs，5 days）

| #   | FR     | GitHub | Beads       | 任务                                               | 状态  |
| --- | ------ | ------ | ----------- | -------------------------------------------------- | ----- |
| 19  | FR-038 | #166   | ZoneCNH-jbu | retention 完整（DELETE + OSS ETag + DB KEEP）      | `[ ]` |
| 20  | FR-039 | #167   | ZoneCNH-2eb | tracing 完整（OTel SDK + W3C + slog trace_id）     | `[ ]` |
| 21  | FR-040 | #168   | ZoneCNH-aqg | quota 完整（Kafka quota + WS 连接池 + CH 超时）    | `[ ]` |
| 22  | FR-041 | #169   | ZoneCNH-xq1 | audit 完整（admin 写审计 + append-only + 保留期）  | `[ ]` |
| 23  | FR-042 | #170   | ZoneCNH-cw0 | schema version（MAJOR reject + MINOR 兼容）        | `[ ]` |
| 24  | FR-043 | #171   | ZoneCNH-t7f | cost 完整（存储/带宽指标 + 预算告警）              | `[ ]` |
| 25  | FR-044 | #172   | ZoneCNH-1nm | destruction 完整（data_classification + 销毁证明） | `[ ]` |

**完成标准**：7 FR Partial→Done，Code-Done 41→48/48 (100%)

---

## Infrastructure — Week 1 并行

| #   | ID  | GitHub | Beads       | 任务                          | 状态  |
| --- | --- | ------ | ----------- | ----------------------------- | ----- |
| 26  | F-1 | #173   | ZoneCNH-2sx | Self-hosted CI runner 配置    | `[ ]` |
| 27  | I-2 | #174   | ZoneCNH-lvu | Jaeger 部署 + OTel trace 验证 | `[ ]` |
| 28  | I-3 | #175   | ZoneCNH-k05 | Grafana dashboard import      | `[ ]` |
| 29  | I-4 | #176   | ZoneCNH-qbt | AlertManager rules load       | `[ ]` |
| 30  | I-5 | #177   | ZoneCNH-m9k | Promtail/Loki 部署            | `[ ]` |

---

## Tests — Week 1-3

| #   | ID  | GitHub | Beads       | 任务                               | 状态  |
| --- | --- | ------ | ----------- | ---------------------------------- | ----- |
| 31  | H-1 | #178   | ZoneCNH-868 | Depth test（25 FRs × 5 subtests）  | `[ ]` |
| 32  | H-2 | #179   | ZoneCNH-4vb | Coverage check（≥98%）             | `[ ]` |
| 33  | H-4 | #180   | ZoneCNH-b6h | Soak test（30min baseline）        | `[ ]` |
| 34  | H-5 | #181   | ZoneCNH-g8v | Chaos test（5 scenarios baseline） | `[ ]` |
| 35  | J-8 | #182   | ZoneCNH-d8z | Security test（6 types baseline）  | `[ ]` |

---

## Drills — Week 2

| #   | ID  | GitHub | Beads       | 任务                         | 状态  |
| --- | --- | ------ | ----------- | ---------------------------- | ----- |
| 36  | F-6 | #183   | ZoneCNH-85c | Canary drill（dev 环境）     | `[ ]` |
| 37  | J-7 | #184   | ZoneCNH-opp | Destruction drill（DRY_RUN） | `[ ]` |

---

## Security CI — Week 2

| #   | ID  | GitHub | Beads       | 任务                         | 状态  |
| --- | --- | ------ | ----------- | ---------------------------- | ----- |
| 38  | J-3 | #185   | ZoneCNH-5je | gitleaks secrets scan CI run | `[ ]` |
| 39  | J-4 | #186   | ZoneCNH-rsf | govulncheck vuln scan CI run | `[ ]` |

---

## PRG Gates — Week 4

| #   | PRG     | GitHub | Beads       | 任务                       | 状态  |
| --- | ------- | ------ | ----------- | -------------------------- | ----- |
| 40  | PRG-001 | #187   | ZoneCNH-rf7 | remote CI current run PASS | `[ ]` |
| 41  | PRG-002 | #188   | ZoneCNH-lfh | release promotion PASS     | `[ ]` |
| 42  | PRG-003 | #189   | ZoneCNH-3y9 | production readiness PASS  | `[ ]` |
| 43  | PRG-004 | #190   | ZoneCNH-bil | observability PASS         | `[ ]` |
| 44  | PRG-005 | #191   | ZoneCNH-ryu | security PASS              | `[ ]` |
| 45  | PRG-006 | #192   | ZoneCNH-54k | resilience PASS            | `[ ]` |
| 46  | PRG-007 | #193   | ZoneCNH-8yf | issue sync PASS            | `[ ]` |

---

## Release — Week 4

| #   | ID  | GitHub | Beads       | 任务                                     | 状态  |
| --- | --- | ------ | ----------- | ---------------------------------------- | ----- |
| 47  | F-2 | #194   | ZoneCNH-9vr | v0.2.0 release tag + post-release verify | `[ ]` |

---

## 里程碑

| 里程碑                | 时间      | 验收标准                                            | Code-Done    |
| --------------------- | --------- | --------------------------------------------------- | ------------ |
| M1: CI + 可观测性就绪 | Week 1 末 | F-1 PASS + I-2~I-5 PASS + PRG-001/004 PASS          | 29/48 (60%)  |
| M2: E-1 + E-2 闭合    | Week 2 末 | 12 FR Partial→Done + J-3/J-4 PASS + drills evidence | 35/48 (73%)  |
| M3: 全 FR 闭合        | Week 3 末 | 48/48 Done + H-1/H-2 PASS + PRG-005/006 PASS        | 48/48 (100%) |
| M4: v0.2.0 Release    | Week 4 末 | PRG 7/7 PASS + release tag + post-release verify    | 48/48 (100%) |

---

## 依赖链

```
E-1 (FR-016→FR-007→FR-017→FR-024→FR-007a) + F-1 → FR-023
    ↓
E-2 (FR-011→FR-013→FR-025→FR-026→FR-027→FR-028)
    ↓
E-3 (FR-031→FR-032→FR-033→FR-034→FR-035/FR-036) ‖ E-4 (FR-038~044)
    ↓
H-1 depth test → H-2 coverage
    ↓
PRG-001~007 → F-2 release
```

## 并行工作流

| 工作流                          | 前置                        | 可立即开始 |
| ------------------------------- | --------------------------- | :--------: |
| F-1 Self-hosted CI runner       | 基础设施配置                |    YES     |
| I-2~I-5 可观测性部署            | Jaeger/Grafana/AM/Loki 安装 |    YES     |
| H-4 Soak test baseline          | 基础设施连通                |    YES     |
| H-5 Chaos test baseline         | 基础设施连通                |    YES     |
| J-8 Security test baseline      | 基础设施连通                |    YES     |
| F-6 Canary drill (dev)          | 基础设施连通                |    YES     |
| J-7 Destruction drill (DRY_RUN) | 基础设施连通                |    YES     |
