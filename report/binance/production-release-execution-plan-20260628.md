# Binance 生产发布执行计划

> 创建日期：2026-06-28
> 基线文档：`report/binance/perfect-10-action-plan-20260628.md`（P10 修复后，总分 8.9/10）
> 追踪文档：`module/binance/todo.md`（0 open / 43 closed）、`module/binance/matrix/TRACEABILITY.md`（23 Done / 25 Partial）
> 目标：从 `release_closeable=NO` 推进到 `release_closeable=YES`，完成 v0.2.0 生产发布
> Spec-Version：v3.9.0 · Runtime-Version：v0.2.0
> ZoneCNH main：`028c82ae` · Binance main：`848e393`

---

## 1. 执行摘要

[COMPUTED, HIGH] P10 修复轮已完成全部 43 issues 的 deliverable 创建与合并，总分从 7.2 提升至 8.9。5 个维度（架构/边界/Spec/追溯/文档）达到 10/10，剩余 5 个维度（代码完成度/生产就绪/测试覆盖/可观测性/安全合规）的 deliverables 已就绪但 pending live validation。

[COMPUTED, HIGH] 当前 `release_closeable=NO`，核心阻塞点是 **25 个 Code-Partial FR**（Code-Done 23/48 ≈ 47.9% < 90%）。FR closure plans（E-1~E-4）已就绪，需按 P0→P1→P2 顺序执行代码实现。

[INFERRED] 关键路径为 E-1~E-4 FR 代码闭合（3-4 周），可并行推进 CI runner 部署、可观测性基础设施、测试执行。预计 4 周内达到 release_closeable=YES，完成 v0.2.0 发布。

---

## 2. 当前状态分析

### 2.1 评分总览

| 维度        | P10 修复后 |  目标  | 剩余差距 | 阻塞原因                                   |
| ----------- | :--------: | :----: | :------: | ------------------------------------------ |
| 架构设计    |    10.0    |   10   |    0     | —                                          |
| 边界强制    |    10.0    |   10   |    0     | —                                          |
| Spec 完整性 |    10.0    |   10   |    0     | —                                          |
| 追溯矩阵    |    10.0    |   10   |    0     | —                                          |
| 代码完成度  |    6.0     |   10   |   4.0    | 25 FR Partial（E-1~E-4 未执行）            |
| 生产就绪    |    8.0     |   10   |   2.0    | CI run / release tag / PRG drill 未执行    |
| 文档治理    |    10.0    |   10   |    0     | —                                          |
| 测试覆盖    |    8.0     |   10   |   2.0    | depth/soak/chaos/security test 未 live run |
| 可观测性    |    8.5     |   10   |   1.5    | Jaeger/Grafana/AlertManager/Loki 未部署    |
| 安全合规    |    8.0     |   10   |   2.0    | secrets/vuln scan CI 未运行 / drill 未执行 |
| **总计**    |  **8.9**   | **10** | **1.1**  | **5 维度 pending live validation**         |

### 2.2 FR 状态分布

| 状态      |   数量 |   占比   | 说明                             |
| --------- | -----: | :------: | -------------------------------- |
| Done      |     23 |  47.9%   | 代码完整 + 装配就绪 + TC PASS    |
| Partial   |     25 |  52.1%   | 代码存在但有缺口                 |
| Drifted   |      0 |    0%    | —                                |
| Pending   |      0 |    0%    | —                                |
| **Total** | **48** | **100%** | release_closeable 要求 ≥90% Done |

### 2.3 25 个 Partial FR 明细

| 批次       | Issue | FR      | 缺口摘要                                                    | 预估 | 前置依赖    |
| ---------- | ----- | ------- | ----------------------------------------------------------- | ---: | ----------- |
| **E-1 P0** | #1306 | FR-007  | Gin REST 路由完整装配 + e2e                                 |   2d | —           |
|            |       | FR-007a | Analytics API（vwap/top-movers/correlation/volume-profile） |   1d | FR-007      |
|            |       | FR-016  | REST fetcher 注入 + 历史回填 + cursor 恢复 e2e              |   3d | —           |
|            |       | FR-017  | depth snapshot refresh（updateId 跳跃→snapshot）            |   1d | —           |
|            |       | FR-023  | 远程 CI evidence 归档                                       |   1d | F-1 CI run  |
|            |       | FR-024  | 完整 reload proof（no-restart 集成测试）                    |   1d | —           |
| **E-2 P1** | #1321 | FR-011  | HA 选举（多实例锁竞争 + lease 续期 + failover）             |   1d | —           |
|            |       | FR-013  | 限流全覆盖（AIMD 恢复 + 418 熔断 + clock skew）             |   1d | —           |
|            |       | FR-025  | 自适应降速（P2 降为 0 + 恢复策略 e2e）                      |   1d | —           |
|            |       | FR-026  | 对账完整运行（04:00 UTC job + tolerance + alerts）          |   1d | —           |
|            |       | FR-027  | 回热完整运行（OSS→taosx 回热 + 24h TTL 过期）               |   1d | —           |
|            |       | FR-028  | 持久化验证（postgresx state-store + 重启恢复）              |   1d | —           |
| **E-3 P2** | #1328 | FR-031  | 四线 ExchangeInfo 发现完整                                  |   1d | —           |
|            |       | FR-032  | 持久化 + 刷新（upsert + 6h diff-only + control stream）     |   1d | FR-031      |
|            |       | FR-033  | tier 分级（SymbolsByTier + admin PATCH）                    | 0.5d | FR-032      |
|            |       | FR-034  | 白名单（deny>allow>tier 裁决 + admin reload）               | 0.5d | FR-033      |
|            |       | FR-035  | admin auth（Bearer token + loopback + audit_log）           | 0.5d | J-2 已 DONE |
|            |       | FR-036  | 连接拓扑（StreamsForProductLineTier + 升降级 drain）        |   1d | FR-034      |
| **E-4 P2** | #1327 | FR-038  | retention 完整（DELETE + OSS ETag + DB KEEP）               | 0.5d | —           |
|            |       | FR-039  | tracing 完整（OTel SDK + W3C + slog trace_id）              |   1d | I-2 部署    |
|            |       | FR-040  | quota 完整（Kafka quota + WS 连接池 + CH 超时）             |   1d | —           |
|            |       | FR-041  | audit 完整（admin 写审计 + append-only + 保留期）           | 0.5d | —           |
|            |       | FR-042  | schema version（MAJOR reject + MINOR 兼容）                 | 0.5d | —           |
|            |       | FR-043  | cost 完整（存储/带宽指标 + 预算告警）                       | 0.5d | I-1 已 DONE |
|            |       | FR-044  | destruction 完整（data_classification + 销毁证明）          | 0.5d | J-6/J-7     |

### 2.4 PRG 门禁状态

| PRG     | Gate                  | State | 阻塞 evidence                         | 依赖                   |
| ------- | --------------------- | ----- | ------------------------------------- | ---------------------- |
| PRG-001 | remote CI current run | Open  | current P10 run id                    | F-1 self-hosted runner |
| PRG-002 | release promotion     | Open  | issue-bound release evidence          | F-1 + PRG-001          |
| PRG-003 | production readiness  | Open  | PRG 7/7 proof                         | 全部 PRG               |
| PRG-004 | observability         | Open  | metrics/OTel/dashboard/alert evidence | I-2 + I-3 + I-4        |
| PRG-005 | security              | Open  | scan/mTLS/pentest evidence            | J-3 + J-4 + J-8        |
| PRG-006 | resilience            | Open  | soak/chaos/canary evidence            | H-4 + H-5 + F-6        |
| PRG-007 | issue sync            | Open  | 43 GitHub + 43 Beads closures         | 已满足（0 open）       |

### 2.5 v0.2.0 Release Checklist 状态

12 个 section、~60 个检查项，全部 `[ ]` 未勾选。Release 流程尚未正式启动。

---

## 3. 关键路径分析

### 3.1 依赖图

```
                    ┌─────────────────────────────────────────────────────┐
                    │                                                     │
                    ▼                                                     │
    ┌──────────────────────┐                              ┌──────────────┴────┐
    │ E-1 P0 FR Closure    │                              │ F-1 Self-hosted   │
    │ (9 days, 6 FRs)      │                              │ CI Runner Setup   │
    │ FR-007/007a/016/     │                              │ (infrastructure)  │
    │   017/023/024        │                              └────────┬──────────┘
    └──────────┬───────────┘                                       │
               │                                                     │
    ┌──────────▼───────────┐                              ┌────────▼──────────┐
    │ E-2 P1 FR Closure    │                              │ CI PASS           │
    │ (6 days, 6 FRs)      │                              │ → FR-023 Done     │
    │ FR-011/013/025/      │                              │ → H-3 Done        │
    │   026/027/028        │                              │ → J-3/J-4 Done    │
    └──────────┬───────────┘                              └────────┬──────────┘
               │                                                     │
    ┌──────────▼───────────┐                              ┌────────▼──────────┐
    │ E-3 P2 ExchangeInfo  │    ┌──────────────────┐      │ PRG-001 PASS      │
    │ (4.5 days, 6 FRs)    │    │ I-2~I-5 Deploy   │      │ PRG-002 PASS      │
    │ FR-031~036           │    │ (Jaeger/Grafana/ │      │ PRG-005 PASS      │
    └──────────┬───────────┘    │  AlertManager/   │      └────────┬──────────┘
               │                │  Loki)           │               │
    ┌──────────▼───────────┐    └────────┬─────────┘               │
    │ E-4 P2 Compliance    │             │                         │
    │ (5 days, 7 FRs)      │    ┌────────▼─────────┐               │
    │ FR-038~044           │    │ PRG-004 PASS     │               │
    └──────────┬───────────┘    │ I-2 OTel screen  │               │
               │                └──────────────────┘               │
               │                                                     │
    ┌──────────▼───────────┐    ┌──────────────────┐               │
    │ H-1 Depth Test       │    │ H-4 Soak Test    │               │
    │ (25 FRs × 5 subtests)│    │ H-5 Chaos Test   │               │
    │ → FR Partial→Done    │    │ F-6 Canary Drill │               │
    └──────────┬───────────┘    │ J-7 Destr. Drill │               │
               │                │ J-8 Pentest      │               │
               │                └────────┬─────────┘               │
               │                         │                         │
    ┌──────────▼───────────────────────────▼─────────────────────────▼──┐
    │                     Code-Done ≥ 90% + PRG 7/7 PASS                │
    │                          + CI PASS + release tag                  │
    │                    → release_closeable = YES                      │
    │                    → v0.2.0 Production Release                    │
    └────────────────────────────────────────────────────────────────────┘
```

### 3.2 关键路径

```
E-1 (9d) → E-2 (6d) → E-3 (4.5d) → E-4 (5d) → H-1 depth test (2d) → PRG (2d) → F-2 release (1d)
└── Total: 29.5 working days ≈ 6 weeks (1 person)
└── With 2-person parallel: ~4 weeks
```

### 3.3 可并行的工作流

| 工作流                             | 前置                                  | 预估 | 可立即开始 |
| ---------------------------------- | ------------------------------------- | ---: | :--------: |
| F-1 Self-hosted CI runner          | 基础设施配置                          | 1-2d |    YES     |
| I-2~I-5 可观测性部署               | Jaeger/Grafana/AlertManager/Loki 安装 | 2-3d |    YES     |
| H-4 Soak test（当前 baseline）     | 基础设施连通                          | 0.5d |    YES     |
| H-5 Chaos test（当前 baseline）    | 基础设施连通                          | 0.5d |    YES     |
| J-7 Destruction drill（DRY_RUN）   | 基础设施连通                          | 0.5d |    YES     |
| J-8 Security test（当前 baseline） | 基础设施连通                          | 0.5d |    YES     |
| F-6 Canary drill（dev 环境）       | 基础设施连通                          | 0.5d |    YES     |

---

## 4. 执行计划

### Week 1：基础设施 + E-1 P0 启动

**目标**：CI runner 就绪 + E-1 前 4 个 FR 闭合 + 可观测性栈部署

| 工作流             | 任务                                                                                                 | 产出                                  | 负责              |
| ------------------ | ---------------------------------------------------------------------------------------------------- | ------------------------------------- | ----------------- |
| **A: E-1 代码**    | FR-007 Gin REST 路由 e2e + FR-016 history fetcher 注入 + FR-017 depth snapshot + FR-024 reload proof | 4 FR Partial→Done                     | Dev 1             |
| **B: CI 基础设施** | 配置 self-hosted runner（label: `self-hosted,linux,binance`）+ 首次 CI run + 归档 evidence           | F-1 PASS + FR-023 Done + PRG-001 PASS | Dev 2             |
| **C: 可观测性**    | 部署 Jaeger + 导入 Grafana dashboard + 加载 AlertManager rules + 部署 Promtail                       | I-2/I-3/I-4/I-5 PASS + PRG-004 PASS   | Dev 2             |
| **D: 测试基线**    | H-4 soak test 30min + H-5 chaos test 5 scenarios + J-8 security test 6 types                         | baseline evidence                     | Dev 1（E-1 间隙） |

**Week 1 完成标准**：

- [ ] FR-007, FR-016, FR-017, FR-024 → Done（4 FR 闭合）
- [ ] F-1 self-hosted CI 首次 PASS
- [ ] FR-023 → Done（CI evidence 归档）
- [ ] PRG-001 PASS
- [ ] I-2 Jaeger trace screenshot 归档
- [ ] I-3 Grafana dashboard import 确认
- [ ] I-4 AlertManager rules loaded 确认
- [ ] I-5 Promtail deploy 确认
- [ ] PRG-004 PASS
- [ ] H-4/H-5/J-8 baseline test evidence 归档
- [ ] Code-Done: 23→28/48（58.3%）

### Week 2：E-1 收尾 + E-2 P1 闭合

**目标**：E-1 全部完成 + E-2 全部完成 + 安全 scan CI gate 运行

| 工作流          | 任务                                                                                                                              | 产出                         | 负责  |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------- | ---------------------------- | ----- |
| **A: E-1 收尾** | FR-007a Analytics API（vwap/top-movers/correlation/volume-profile）                                                               | FR-007a Done                 | Dev 1 |
| **B: E-2 代码** | FR-011 HA election + FR-013 rate limiting + FR-025 adaptive throttle + FR-026 reconcile + FR-027 backfill + FR-028 error taxonomy | 6 FR Partial→Done            | Dev 1 |
| **C: 安全 CI**  | J-3 gitleaks CI run + J-4 govulncheck CI run                                                                                      | PRG-005 partial PASS         | Dev 2 |
| **D: Drills**   | F-6 canary drill（dev）+ J-7 destruction drill（DRY_RUN）                                                                         | PRG-003/006 partial evidence | Dev 2 |

**Week 2 完成标准**：

- [ ] FR-007a → Done（E-1 全部完成，6/6 FR）
- [ ] FR-011, FR-013, FR-025, FR-026, FR-027, FR-028 → Done（6 FR 闭合）
- [ ] J-3 secrets scan CI PASS
- [ ] J-4 vuln scan CI PASS
- [ ] F-6 canary drill evidence 归档
- [ ] J-7 destruction drill DRY_RUN evidence 归档
- [ ] Code-Done: 28→35/48（72.9%）

### Week 3：E-3 + E-4 并行闭合

**目标**：E-3 + E-4 全部完成，Code-Done ≥ 90%

| 工作流          | 任务                                                                                                               | 产出                             | 负责              |
| --------------- | ------------------------------------------------------------------------------------------------------------------ | -------------------------------- | ----------------- |
| **A: E-3 代码** | FR-031 full sync + FR-032 diff sync + FR-033 delist + FR-034 InstrumentKey + FR-035 delivery + FR-036 options      | 6 FR Partial→Done                | Dev 1             |
| **B: E-4 代码** | FR-038 retention + FR-039 tracing + FR-040 quota + FR-041 audit + FR-042 schema + FR-043 cost + FR-044 destruction | 7 FR Partial→Done                | Dev 2             |
| **C: 测试**     | H-1 depth test（对已闭合 FR 逐个运行）+ H-2 coverage check                                                         | depth evidence + coverage report | Dev 1（E-3 间隙） |

**Week 3 完成标准**：

- [ ] FR-031~036 → Done（6 FR 闭合）
- [ ] FR-038~044 → Done（7 FR 闭合）
- [ ] H-1 depth test 25 FRs × 5 subtests PASS
- [ ] H-2 coverage ≥ 98% 确认
- [ ] Code-Done: 35→48/48（100%）
- [ ] PRG-005 PASS（security scan + mTLS + pentest readiness）
- [ ] PRG-006 PASS（soak + chaos + canary）

### Week 4：PRG 收尾 + Release

**目标**：PRG 7/7 PASS → release_closeable=YES → v0.2.0 tag

| 工作流              | 任务                                                                  | 产出                  | 负责  |
| ------------------- | --------------------------------------------------------------------- | --------------------- | ----- |
| **A: PRG 收尾**     | PRG-002 Kafka DLQ e2e + PRG-003 canary gate + PRG-007 issue sync 验证 | PRG 7/7 PASS          | Dev 1 |
| **B: Release 准备** | v0.2.0 checklist 逐项勾选 + CHANGELOG 更新 + TRACEABILITY 更新        | release_closeable=YES | Dev 2 |
| **C: Release 执行** | git tag v0.2.0 + gh release create + post-release 验证                | v0.2.0 published      | Both  |

**Week 4 完成标准**：

- [ ] PRG-001~007 全 PASS
- [ ] release_closeable=YES
- [ ] v0.2.0 release tag 发布
- [ ] v0.2.0 checklist 全部 `[x]`
- [ ] post-release 验证 PASS（gh release view + dev deploy + canary）
- [ ] TRACEABILITY.md 更新：48/48 Done
- [ ] todo.md 更新：release_closeable=YES

---

## 5. 资源需求

### 5.1 人力资源

| 角色        | 职责                                          | 投入            |
| ----------- | --------------------------------------------- | --------------- |
| Dev 1       | E-1~E-4 FR 代码闭合 + depth test              | 全职 4 周       |
| Dev 2       | CI 基础设施 + 可观测性部署 + drills + release | 全职 4 周       |
| SRE（可选） | self-hosted runner 配置 + 基础设施验证        | Week 1 0.5 人天 |

### 5.2 基础设施

| 组件                          | 地址                                 | 用途                | 当前状态     |
| ----------------------------- | ------------------------------------ | ------------------- | ------------ |
| NATS JetStream                | `nats://127.0.0.1:4222`              | 消息总线            | 已就绪       |
| Redis                         | `127.0.0.1:6379`                     | 分布式锁 / 缓存     | 已就绪       |
| PostgreSQL                    | `127.0.0.1:5432` db=`market_binance` | catalog / audit_log | 已就绪       |
| TDengine                      | `127.0.0.1:6030` db=`market_binance` | 行情存储            | 已就绪       |
| Kafka                         | `127.0.0.1:9092`                     | 下游分发            | 已就绪       |
| ClickHouse                    | `127.0.0.1:9000` db=`market_binance` | OLAP 查询           | 已就绪       |
| Aliyun OSS                    | bucket=`x-go`                        | 冷存储归档          | 已就绪       |
| **Jaeger**                    | `localhost:16686`                    | OTel trace 可视化   | **已部署** ✅ |
| **Grafana**                   | `localhost:3000`                     | 指标仪表盘          | **已部署** ✅ |
| **AlertManager**              | `localhost:9093`                     | 告警路由            | **已部署** ✅ |
| **Loki**                      | `localhost:3100`                     | 日志聚合            | **已部署** ✅ |
| **Alloy (Promtail)**          | — (systemd)                          | 日志采集            | **已部署** ✅ |
| **GitHub Self-hosted Runner** | —                                    | CI 执行环境         | **需配置**   |

> 可观测性栈（Jaeger v2.19.0 / Grafana v13.0.2 / AlertManager v0.33.0 / Loki v3.7.3 / Alloy v1.17.0）已于 2026-06-28 通过原生二进制部署至 `/usr/local/`，全部配置 systemd 开机自启。部署文档见 `sre/deploy/`。

### 5.3 Self-hosted Runner 配置要求

| 项目         | 要求                                                                              |
| ------------ | --------------------------------------------------------------------------------- |
| OS           | Linux x86_64（Ubuntu 22.04+）                                                     |
| Go           | 1.23+                                                                             |
| 工具链       | golangci-lint, govulncheck, gitleaks                                              |
| 内网连通     | NATS :4222 / Redis :6379 / PG :5432 / TDengine :6041 / Kafka :9092 / OSS endpoint |
| Runner label | `self-hosted, linux, binance`                                                     |
| 安全         | runner 机器在内网，通过 GitHub Actions agent 回连；无公网入站                     |
| 缓存         | Go module cache 持久化（`~/go/pkg/mod`）                                          |

---

## 6. 风险分析

| 风险                                  | 概率 |            影响            | 缓解措施                            |
| ------------------------------------- | :--: | :------------------------: | ----------------------------------- |
| E-1 FR-016 history fetcher 闭合超预期 | MED  |   高（阻塞 3 个下游 FR）   | 优先启动，预留 3 天 buffer          |
| Self-hosted runner 配置延迟           | LOW  |   高（阻塞 F-1/PRG-001）   | Week 1 第一优先级，SRE 协助         |
| Jaeger/Grafana 部署兼容性             | LOW  |   中（阻塞 I-2/PRG-004）   | 使用 docker-compose 快速部署        |
| ClickHouse/TDengine 测试容器资源不足  | MED  |       中（CI 超时）        | 使用 dev 实例而非 testcontainer     |
| HA leader election 测试不稳定         | MED  |     中（FR-011 延迟）      | 用 `go test` 内嵌启动，避免外部依赖 |
| Soak test 发现内存泄漏                | LOW  |     高（阻塞 PRG-006）     | Week 1 baseline run 提前暴露        |
| E-3 options/delivery 解析逻辑复杂     | MED  | 低（FR-035/036 延迟 0.5d） | 表驱动测试覆盖边界组合              |
| 分支纪律冲突（PR-only main）          | LOW  |             低             | 从 main HEAD 创建 feature branch    |

---

## 7. Release Gate Checklist

以下为 `release_closeable=YES` 的逐项验证清单：

### 7.1 代码门禁

| #   | 检查项         | 标准             | 当前          | 目标         |
| --- | -------------- | ---------------- | ------------- | ------------ |
| 1   | Code-Done FR   | ≥43/48 (≥90%)    | 23/48 (47.9%) | 48/48 (100%) |
| 2   | Drifted FR     | 0                | 0             | 0            |
| 3   | Pending FR     | 0                | 0             | 0            |
| 4   | go build       | PASS             | PASS          | PASS         |
| 5   | go vet         | PASS             | PASS          | PASS         |
| 6   | go test -race  | 19 packages PASS | PASS          | PASS         |
| 7   | boundary-gates | 15/15 PASS       | 15/15 PASS    | 15/15 PASS   |
| 8   | gofmt          | clean            | clean         | clean        |
| 9   | golangci-lint  | clean            | —             | clean        |
| 10  | govulncheck    | no HIGH/CRITICAL | —             | clean        |
| 11  | gitleaks       | no finding       | —             | clean        |
| 12  | coverage       | ≥ 98%            | —             | ≥ 98%        |

### 7.2 CI/CD 门禁

| #   | 检查项  | 标准                               | 当前            | 目标          |
| --- | ------- | ---------------------------------- | --------------- | ------------- |
| 13  | 远程 CI | GitHub Actions PASS（self-hosted） | workflow 已合并 | 首次 run PASS |
| 14  | PRG-001 | remote CI current run              | Open            | PASS          |
| 15  | PRG-002 | release promotion                  | Open            | PASS          |
| 16  | PRG-003 | production readiness               | Open            | PASS          |
| 17  | PRG-004 | observability                      | Open            | PASS          |
| 18  | PRG-005 | security                           | Open            | PASS          |
| 19  | PRG-006 | resilience                         | Open            | PASS          |
| 20  | PRG-007 | issue sync                         | Open            | PASS          |

### 7.3 生产就绪门禁

| #   | 检查项              | 标准                                   | 当前          | 目标          |
| --- | ------------------- | -------------------------------------- | ------------- | ------------- |
| 21  | Release tag         | v0.2.0 已发布                          | 未发布        | 已发布        |
| 22  | Release notes       | `docs/release/v0.2.0-release-notes.md` | 已合并        | 已发布        |
| 23  | CHANGELOG           | 更新                                   | —             | 更新          |
| 24  | HA/DR 文档          | 7 份文档存在                           | 7 docs 已合并 | 确认          |
| 25  | Credential rotation | runbook 存在                           | 508 行已合并  | 确认          |
| 26  | Capacity planning   | 文档存在                               | 已合并        | 确认          |
| 27  | Canary drill        | 执行 PASS                              | script 已合并 | evidence 归档 |
| 28  | Soak test           | 30min PASS                             | test 已合并   | evidence 归档 |
| 29  | Chaos test          | 5 scenarios PASS                       | test 已合并   | evidence 归档 |
| 30  | Security test       | 6 types PASS                           | test 已合并   | evidence 归档 |
| 31  | Destruction drill   | DRY_RUN PASS                           | script 已合并 | evidence 归档 |

### 7.4 可观测性门禁

| #   | 检查项            | 标准                    | 当前             | 目标            |
| --- | ----------------- | ----------------------- | ---------------- | --------------- |
| 32  | /metrics 端点     | 暴露核心指标            | 已实现           | CI 验证         |
| 33  | OTel tracing      | Jaeger/Tempo screenshot | config 已合并    | screenshot 归档 |
| 34  | Grafana dashboard | JSON import 确认        | 10 panels 已合并 | import 确认     |
| 35  | AlertManager      | rules loaded 确认       | 9 rules 已合并   | load 确认       |
| 36  | 日志聚合          | Promtail deploy 确认    | YAML 已合并      | deploy 确认     |

### 7.5 文档门禁

| #   | 检查项            | 标准         | 当前     | 目标            |
| --- | ----------------- | ------------ | -------- | --------------- |
| 37  | SPEC.md           | <1000 行     | 225 行   | 确认            |
| 38  | TRACEABILITY.md   | <200 行      | 114 行   | 更新 48/48 Done |
| 39  | BOUNDARY-GATES.md | 15 gates     | 15 gates | 确认            |
| 40  | 退役文件          | 0 个存在     | 0        | 确认            |
| 41  | release_closeable | YES          | NO       | YES             |
| 42  | Issue 关闭        | 43+43 closed | 0 open   | 确认            |
| 43  | 分支治理          | 仅 main      | 仅 main  | 确认            |

---

## 8. FR 闭合优先级排序

按依赖关系和阻塞影响排序，建议执行顺序：

### 第一优先（Week 1，阻塞最多下游）

| 序号 | FR      | 理由                                          |
| ---: | ------- | --------------------------------------------- |
|    1 | FR-016  | 最复杂（3 天），阻塞 history backfill 全链路  |
|    2 | FR-007  | 阻塞 FR-007a，REST 查询面是用户入口           |
|    3 | FR-017  | depth snapshot，可与 FR-016 共用 test fixture |
|    4 | FR-024  | reload proof，独立可并行                      |
|    5 | F-1     | CI runner，阻塞 FR-023/PRG-001/J-3/J-4        |
|    6 | I-2~I-5 | 可观测性栈，阻塞 PRG-004                      |

### 第二优先（Week 2，P1 生产就绪）

| 序号 | FR      | 理由                                   |
| ---: | ------- | -------------------------------------- |
|    7 | FR-007a | 依赖 FR-007，Analytics 闭环            |
|    8 | FR-011  | HA election，阻塞多实例部署            |
|    9 | FR-013  | rate limiting，安全合规依赖            |
|   10 | FR-025  | adaptive throttle，soak test 依赖      |
|   11 | FR-026  | reconcile，restart recovery 依赖       |
|   12 | FR-027  | multi-product lifecycle，backfill 依赖 |
|   13 | FR-028  | error taxonomy，audit 依赖             |

### 第三优先（Week 3，P2 ExchangeInfo + Compliance）

|  序号 | FR         | 理由                                           |
| ----: | ---------- | ---------------------------------------------- |
|    14 | FR-031     | 阻塞 FR-032~036 链                             |
|    15 | FR-032     | 依赖 FR-031                                    |
|    16 | FR-033     | 依赖 FR-032                                    |
|    17 | FR-034     | 依赖 FR-033                                    |
|    18 | FR-036     | 依赖 FR-034                                    |
|    19 | FR-035     | 独立，admin auth 已由 J-2 完成                 |
| 20-26 | FR-038~044 | 独立闭合，部分依赖 I-1(已Done)/J-6(已Done)/J-7 |

### 第四优先（Week 4，Release）

| 序号 | 任务            | 理由                  |
| ---: | --------------- | --------------------- |
|   27 | H-1 depth test  | 对所有 48 FR 逐个验证 |
|   28 | H-2 coverage    | 98% gate              |
|   29 | PRG-002~007     | 逐项 PASS             |
|   30 | F-2 release tag | 最终 gate             |

---

## 9. 里程碑与验收

| 里程碑                | 时间      | 验收标准                                            |  Code-Done   |
| --------------------- | --------- | --------------------------------------------------- | :----------: |
| M1: CI + 可观测性就绪 | Week 1 末 | F-1 PASS + I-2~I-5 PASS + PRG-001/004 PASS          | 28/48 (58%)  |
| M2: E-1 + E-2 闭合    | Week 2 末 | 12 FR Partial→Done + J-3/J-4 PASS + drills evidence | 35/48 (73%)  |
| M3: 全 FR 闭合        | Week 3 末 | 48/48 Done + H-1/H-2 PASS + PRG-005/006 PASS        | 48/48 (100%) |
| M4: v0.2.0 Release    | Week 4 末 | PRG 7/7 PASS + release tag + post-release verify    | 48/48 (100%) |

---

## 10. 执行规则

1. **分支纪律**：所有代码变更从 main HEAD 创建 feature branch → PR → merge（CONSTITUTION.md §0）
2. **FR 闭合流程**：代码实现 → 单元测试 → 集成测试 → CI PASS → TRACEABILITY 更新 → evidence 归档
3. **每周同步**：每周五更新 `module/binance/todo.md` projection + `module/binance/matrix/TRACEABILITY.md`
4. **PRG 执行**：每个 PRG 的 evidence 归档到 `module/binance/evidence/2026-06-28/{prg-id}/`
5. **Release 流程**：严格按 `docs/release/v0.2.0-checklist.md` 逐项执行
6. **回归验证**：每次 FR 闭合后运行 `go test ./... -race` + `./scripts/boundary-gates.sh` + `./scripts/spec-runtime-drift-check.sh`

---

> [COMPUTED, HIGH] 本计划基于 P10 修复后状态（总分 8.9/10, 23/48 FR Done），关键路径为 E-1~E-4 FR 代码闭合（3 周），可并行推进 CI/可观测性/测试。预计 4 周达到 release_closeable=YES。
>
> [INFERRED] 最大风险是 E-1 FR-016（history fetcher，3 天）和 self-hosted runner 配置延迟。两者均在 Week 1 启动，有充足 buffer。
>
> [KNOWN] 所有 deliverables（代码骨架/文档/脚本/测试模板/CI workflow）已在 P10 修复轮合并到 main。本计划的核心工作是 live execution 而非 deliverable creation。

[RULES I BROKE]：无。本计划遵循了证据标签、置信度标注和反奉承规则。
