# module/binance 深度结构分析报告

> 分析日期：2026-06-28
> 分析范围：`module/binance/` 全量文档 + `/home/binance` runtime 代码（HEAD `2efc44a`）
> 分析目标：结构性问题诊断 + client/server 边界规范 + 生产级可发布差距
> Spec-Version：v3.9.0 · Runtime-Version：v0.2.0

---

## 目录

1. [评分总览](#1-评分总览)
2. [Client/Server 边界审计](#2-clientserver-边界审计)
3. [结构性问题清单](#3-结构性问题清单)
4. [生产级可发布差距](#4-生产级可发布差距)
5. [补充与优化建议](#5-补充与优化建议)
6. [结论](#6-结论)

---

## 1. 评分总览

### 1.1 多维度评分

| 维度        | 评分 | 满分 | 等级 | 关键依据                                                                        |
| ----------- | :--: | :--: | :--: | ------------------------------------------------------------------------------- |
| 架构设计    | 9.0  |  10  |  A   | 分布式 C/S + NATS JetStream 解耦清晰；C1-C6 约束可执行；分层合理                |
| 边界强制    | 9.5  |  10  |  A+  | 14 道 boundary gate CI 拦截；`internal/cs` 已删除；无跨边界 import              |
| Spec 完整性 | 8.5  |  10  |  A-  | 44 FR + 12 BR + 27 NFR + 154 AC + 83 TC；23 节结构完整；部分 WHEN/THEN 过度细碎 |
| 追溯矩阵    | 8.0  |  10  |  B+  | FR→AC→TC 全链路 100% 登记；但双态模型（Code/Evidence）导致状态认知混乱          |
| 代码完成度  | 5.5  |  10  |  C+  | Code-State 23/48 Done (48%)；25 个 Code-Partial FR 未闭合                       |
| 生产就绪    | 5.0  |  10  |  C   | 本地 E2E PASS 但无远程 CI/release tag；PRG gate 证据不完整；HA/DR 文档缺失      |
| 文档治理    | 6.5  |  10  |  B-  | 文档量巨大但冗余严重；4 个退役文件仍存；TRACEABILITY 历史注记过多               |
| 测试覆盖    | 7.0  |  10  |  B   | ~90 个 test 文件；boundary gate 14/14；但 Code-Partial FR 的 TC 覆盖深度不足    |
| 可观测性    | 7.5  |  10  |  B+  | Prometheus metrics 完整；OTel tracing 已接入；但 cost/audit 指标为 anchor 级    |
| 安全合规    | 6.0  |  10  |  B-  | admin auth Bearer token；append-only audit；但 credential rotation runbook 缺失 |

### 1.2 综合评分

| 指标             |      值      | 说明                                                                          |
| ---------------- | :----------: | ----------------------------------------------------------------------------- |
| **综合结构分**   | **7.2 / 10** | 架构与边界设计优秀，代码完成度和生产就绪度是主要瓶颈                          |
| **生产可发布度** | **5.5 / 10** | 本地可编译可测试，但 25 个 Partial FR + 无 release tag + 无远程 CI = 不可发布 |
| **边界规范度**   | **9.0 / 10** | client/server 边界是全模块最强项                                              |

---

## 2. Client/Server 边界审计

### 2.1 边界定义审计

SPEC §4.1 定义了 6 条分布式架构约束（C1-C6），均为 CI 可执行约束：

| 约束 | 内容                                                                    | 强制方式             | runtime 实态                                              | 判定 |
| ---- | ----------------------------------------------------------------------- | -------------------- | --------------------------------------------------------- | :--: |
| C1   | client/server 独立进程，禁止同进程 wiring                               | BOUNDARY-GATES §6    | `cmd/binance-client` + `cmd/binance-server` 独立入口      |  ✅  |
| C2   | client→server 仅通过 natsx JetStream                                    | BOUNDARY-GATES §6    | publisher/consumer 通过 NATS subject 通信                 |  ✅  |
| C3   | NATS 独立部署，不内嵌                                                   | SPEC §4              | runtime 仅配置 `nats.url` 连接                            |  ✅  |
| C4   | `internal/cs` 不作为运行时依赖                                          | BOUNDARY-GATES §5    | `internal/cs/` 目录已空（仅残留）                         |  ✅  |
| C5   | client 不 import server internals；反之亦然                             | BOUNDARY-GATES §3,§4 | 14/14 gate PASS                                           |  ✅  |
| C6   | 共享 wire contract 在 `internal/wire`，canonical 语义在 `domain_market` | BOUNDARY-GATES §8    | `internal/wire/` 存在（doc.go + transport.go + types.go） |  ⚠️  |

### 2.2 边界执行审计

**14 道 boundary gate 全部 PASS**（runtime HEAD `2efc44a`）：

```
§2  No Legacy binance-market          ✅
§3  Client Must Not Import Server     ✅
§4  Server Must Not Import Client     ✅
§5  No cs Package as Runtime Dep      ✅
§6  No Same-Process C/S Communication ✅
§7  Binance Server Owns Storage Only  ✅
§8  Wire Contract Externality         ✅
§9  Domain-Market Semantic Source     ✅
§10 Admin Surface Boundary            ✅
§11 go.mod Dependency Compliance      ✅
§12 natsx Presence                    ✅
§13 Storage Presence                  ✅
§14 Gin Presence                      ✅
§15 (新增)                             ✅
```

### 2.3 边界问题诊断

#### 问题 B-1：`internal/wire` 与 BR-007 存在语义张力 [MEDIUM]

SPEC §4.1 C6 声明"共享 wire contract 位于 `internal/wire`——canonical 市场语义属于 `domain_market`"。BR-007 声明"不得定义自己的 proto 或 wire schema"。

`internal/wire/` 当前包含 `transport.go` + `types.go`，定义了 HTTP JSON `/ingest` 消息结构。这与 BR-007 "wire schema 由 `domain_market.MarketFactEnvelope` 定义"存在张力——`internal/wire` 事实上定义了本模块的 HTTP ingest 消息边界，属于"本模块消息结构"而非 canonical domain。

**建议**：将 `internal/wire` 的 HTTP ingest 消息结构明确标注为 "transport adapter types"（非 canonical wire schema），或在 SPEC 中显式声明 `internal/wire` 的角色为"HTTP→NATS 适配层"而非"wire contract owner"。

#### 问题 B-2：`cmd/binance-server` 存在 HTTP `/ingest` 端点 [LOW]

`internal/server/ingest.go` + `internal/client/http_ingest_endpoint.go` 表明 runtime 保留了 HTTP `/ingest` 作为 fallback ingest 路径。SPEC §2 明确"client→server 仅通过 natsx JetStream"。

**现状**：`cmd/binance-smoke` 是 C1 的唯一例外（本地 self-test），但 HTTP `/ingest` 端点在非 smoke 模式下也可用，存在绕过 NATS 边界的风险。

**建议**：在 `cmd/binance-server/main.go` 中 gate HTTP `/ingest` 端点为 smoke-only（`XGO_BINANCE_SMOKE=1` 才注册路由），生产模式不暴露此端点。

#### 问题 B-3：client/server 目录结构不对称 [LOW]

SPEC client §14 和 server §14 定义的目录结构（`client/` 下有 `go.mod`、`go.sum`）与 runtime monorepo 结构（`internal/client/`、`internal/server/` 共享一个 `go.mod`）不一致。

**现状**：runtime 为 monorepo（`github.com/ZoneCNH/binance`），client 和 server 共享 `go.mod`，通过 `internal/client` 和 `internal/server` 隔离。SPEC 中的独立 `client/go.mod` 结构是理想目标，非当前实态。

**建议**：SPEC §14 已在 server/SPEC 中修正为 monorepo 布局，client/SPEC §14 也应同步修正，消除"client 是独立 Go module"的误导。

### 2.4 边界规范总结

| 维度     | 状态 | 说明                                                             |
| -------- | :--: | ---------------------------------------------------------------- |
| 进程隔离 |  ✅  | 两个独立 cmd 入口，无同进程 wiring                               |
| 代码隔离 |  ✅  | 14 道 gate 强制，无跨边界 import                                 |
| 通信隔离 |  ✅  | NATS JetStream 为唯一生产通信通道                                |
| 依赖方向 |  ✅  | client→domain_market+natsx；server→domain_market+natsx+7 storage |
| 共享契约 |  ⚠️  | `internal/wire` 角色需明确                                       |
| 退化路径 |  ⚠️  | HTTP `/ingest` 应 gate 为 smoke-only                             |

---

## 3. 结构性问题清单

### S-1：双态模型（Code/Evidence）导致状态认知混乱 [CRITICAL]

**现象**：TRACEABILITY 引入 Code-State（23 Done / 25 Partial）和 Evidence-State（44 Done / 0 Pending）双态模型。25 个 Code-Partial FR 被标记为 Evidence-Done，这意味着"验收测试通过但代码未完成"——这在逻辑上自相矛盾。

**根因**：2026-06-28 全量 E2E 证据闭合将所有 FR 的 Evidence 提升为 Done，但 Code-State 仍保留 25 Partial。Evidence-Done 的语义被稀释为"存在某种形式的测试证据"，而非"代码完整且通过验收"。

**影响**：

- `release_closeable=YES` 的声明基于 Evidence-State 44/44 Done，但 Code-State 仅 48% Done
- 外部读者无法判断模块是否真正可发布
- 25 个 Partial FR 的"证据"可能只是 anchor 级实现（代码存在但未完整装配或未覆盖全部 WHEN/THEN 分支）

**建议**：

- 废除双态模型，恢复单一状态模型（Done/Partial/Drifted/Pending）
- Evidence-Done 必须以 Code-Done 为前提（Code-Partial 的 FR 不能标 Evidence-Done）
- `release_closeable` 应基于 Code-State 而非 Evidence-State

### S-2：25 个 Code-Partial FR 未闭合 [CRITICAL]

48 个 FR 中 25 个为 Code-Partial（52%），覆盖核心功能：

| Partial FR | 名称                          | 缺口                                |
| ---------- | ----------------------------- | ----------------------------------- |
| FR-007     | Gin Market API                | 可能未完整装配或路由不全            |
| FR-007a    | clickhousex Analytics API     | 同上                                |
| FR-011     | Distributed Coordinator Lock  | HA 选举未完整验证                   |
| FR-013     | Exchange Reliability Controls | 限流模型已对齐但 runtime 覆盖不完整 |
| FR-016     | Historical Backfill Planner   | REST fetcher 注入不完整             |
| FR-017     | Gap Detection and Replay      | 分策略检测已实现但覆盖深度不足      |
| FR-023     | Release Evidence Bundle       | 远程 CI evidence 缺失               |
| FR-024     | Runtime Config Hot Reload     | 仅 symbol catalog reload            |
| FR-025     | Backfill Throttle & Priority  | P0/P1/P2 已实现但自适应降速未验证   |
| FR-026     | Daily Reconciliation Job      | 对账 job 未完整运行                 |
| FR-027     | Cold Data Rehydration         | 回热 job 未完整运行                 |
| FR-028     | Backfill Progress API         | 持久化已接线但生产验证缺失          |
| FR-031~036 | ExchangeInfo Sync 6 项        | runtime 原语已实现但覆盖深度不足    |
| FR-038~044 | 生产就绪 7 项                 | anchor 级实现，多数为骨架           |

**建议**：按 P0→P1→P2 优先级逐批闭合 Code-Partial，每批完成后更新 TRACEABILITY 并验证。

### S-3：文档冗余与历史注记膨胀 [HIGH]

**现象**：

- TRACEABILITY.md 包含大量历史变更注记（v3.5.1/v3.6.0/v3.6.1/v3.7.1/v3.9.0 等），单文件超过 380+ 行，历史信息占 40%+
- 4 个退役文件仍存在（DATA-LIFECYCLE.md、DATA-QUALITY-SLA.md、ENDPOINTS.md、SPEC-exchangeinfo-sync.md），虽添加了 DEPRECATED 横幅但未物理删除
- SPEC.md 超过 1550 行，部分 FR 的 WHEN/THEN 过度细碎（如 FR-013 的退避参数表、FR-017 的分策略检测表），适合放在 design 文档而非 SPEC
- BOUNDARY-GATES.md 包含 §20 推广模板，与本模块边界门禁无关
- todo.md 声称 26/26 全部完成，与 Code-State 25 Partial 矛盾

**建议**：

- TRACEABILITY 历史注记迁移到 CHANGELOG 或单独的 `matrix/CHANGELOG.md`
- 4 个退役文件物理删除（git 历史保留追溯能力）
- SPEC 中过度细碎的参数表迁移到 design/ 或 schema/
- BOUNDARY-GATES §20 迁移到 `docs/governance/`
- todo.md 与 TRACEABILITY Code-State 对齐

### S-4：main.go 手动环境变量装配 [MEDIUM]

`cmd/binance-server/main.go`（383 行）通过 `os.Getenv` 手动读取环境变量装配所有组件，而非使用 config-driven DI。

**现状**：

- `storage_env.go` 封装了存储装配，但 main.go 仍有大量 `env()` 调用
- `smokeModeFromEnv()` / `dispatcherModeFromEnv()` 等函数在 main 包中，非配置层
- 生产配置应通过 `binancecfg.Load` 统一加载，而非分散在 main.go

**影响**：配置变更需要修改 main.go 代码；缺乏配置校验；难以测试不同配置组合。

**建议**：将所有环境变量读取收敛到 `pkg/binancecfg`，main.go 仅做 `cfg := binancecfg.Load()` + `app := server.New(cfg)` + `app.Run()`。

### S-5：无远程 CI 证据与 release tag [HIGH]

**现状**：

- 所有证据为本地运行（`/home/binance/release/evidence/binance/20260628-full-e2e-closure/`）
- 无 GitHub Actions 远程 CI run 证据
- 无 GitHub Release tag（runtime-version v0.2.0 但未发布）
- FR-023（Release Evidence Bundle）为 Code-Partial，CI/live evidence 缺失

**影响**：无法证明代码在非本地环境可编译、可测试、可通过 gate。

**建议**：

- 配置 GitHub Actions workflow（build + test + vet + lint + boundary-gates + govulncheck）
- 首次远程 CI PASS 后打 `v0.2.0` release tag
- 生成 CI evidence 并归档到 `evidence/ci/{run_id}/`

### S-6：PRG（Production Readiness Gates）证据不完整 [HIGH]

SPEC §4.2 定义了 7 个 PRG，多个 PRG 的证据不完整：

| PRG     | 要求                                 | 当前证据                                   | 缺口                             |
| ------- | ------------------------------------ | ------------------------------------------ | -------------------------------- |
| PRG-001 | ClickHouse ReplicatedMergeTree + TTL | dependency contract 闭环                   | 单节点例外未记录原因             |
| PRG-002 | kafkax retry/DLQ topic contract      | DLQTopicForEvent/RetryTopicForEvent 已实现 | 真实 broker DLQ e2e 未验证       |
| PRG-003 | feature flag + canary + rollback     | deploy-canary-gate.sh 已实现               | 生产 canary 部署未执行           |
| PRG-004 | quota/isolation                      | 指标 anchor 已实现                         | 多租户 soak test 未执行          |
| PRG-005 | trace context 传播                   | OTel 已接入                                | 端到端 trace 可视化未验证        |
| PRG-006 | audit append-only + HA/DR 文档       | audit_log + REVOKE 已实现                  | HA/DR/RPO/RTO 部署文档缺失       |
| PRG-007 | 容量/成本/销毁/runbook               | 指标 anchor + runbook 已实现               | credential rotation runbook 缺失 |

### S-7：历史数据回填起始时间定义不完整 [HIGH]

FR-016 定义了冷启动 `first_kline_time` 二分探测策略，但仅覆盖 bar（K线），存在 9 个缺口：

| # | 缺口 | 说明 |
|---|------|------|
| 1 | 仅覆盖 bar 冷启动 | `first_kline_time` 探测的是首根 K 线，trade/tick/depth/funding_rate/mark_price 的同步起始时间未定义 |
| 2 | 保守下界硬编码 | spot=2017-07-01 等写死常量，exchangeInfo `onboardDate` 缺失时不可配置 |
| 3 | trade 回填未定义 fromId 策略 | Binance aggTrades API 支持 `fromId` 按 trade_id 分页（比 startTime 精确），SPEC 未定义 |
| 4 | depth 回填策略缺失 | depth 是增量更新无 REST 回填，SPEC 未声明不可回填 |
| 5 | tick 回填策略缺失 | bookTicker 无 REST endpoint，SPEC 未声明不可回填 |
| 6 | funding_rate/mark_price 回填缺失 | 有 REST endpoint 但 SPEC 未定义回填策略 |
| 7 | 新 symbol 冷启动 event_type 范围不明确 | FR-032 说"自动冷启动回填"但未定义回填哪些 event_type |
| 8 | 冷启动→实时切换点不明确 | backfill cursor 到达 end 后如何切换到实时采集未定义 |
| 9 | 探测 weight 未纳入预算 | 二分查找的 REST 调用 weight 是否从 FR-025 预算扣除未定义 |

**修复状态**：已在 SPEC.md FR-016 中补全（按 event_type 回填策略表 + BNC-019 错误码 + 冷启动→实时切换 + 探测 weight 预算 + 配置项 `backfill.cold_start_fallback_time` / `backfill.cold_start_buffer` / `backfill.probe_max_rest_calls`）。FR-032 新 symbol 行已同步更新引用。

### S-8：SPEC 与 runtime 之间的 drift 风险 [MEDIUM]

多个 FR 在 SPEC 中有详细 WHEN/THEN 但 runtime 仅为 anchor 实现：

- FR-013 限流模型：SPEC 定义了完整的 AIMD 策略 + 418 熔断，runtime `reliability.go` 实现了核心逻辑但未覆盖全部边界
- FR-017 缺口检测：SPEC 定义了 6 种事件类型分策略检测，runtime `quality.go` 实现了分策略但 depth 快照刷新未完整
- FR-032 symbol 生命周期：SPEC 定义了 BREAK/HALT/DELISTED 完整生命周期，runtime 处理深度不足

**建议**：建立 spec-runtime drift 检测脚本，定期比对 SPEC WHEN/THEN 与 runtime 代码覆盖度。

---

## 4. 生产级可发布差距

### 4.1 阻塞发布项（P0 — 必须闭合）

| #    | 差距                       | 当前状态           | 目标状态                | 工作量估计   |
| ---- | -------------------------- | ------------------ | ----------------------- | ------------ |
| P0-1 | 25 个 Code-Partial FR 闭合 | 23/48 Done         | ≥40/48 Done             | 大（2-4 周） |
| P0-2 | 远程 CI GitHub Actions     | 无                 | 全量 CI PASS            | 小（1-2 天） |
| P0-3 | Release tag 发布           | 无                 | `v0.2.0` GitHub Release | 小（半天）   |
| P0-4 | 双态模型修正               | Code/Evidence 分离 | 单态模型                | 小（1 天）   |
| P0-5 | HA/DR 部署文档             | 缺失               | RPO/RTO 文档            | 中（2-3 天） |

### 4.2 强烈建议项（P1 — 发布前闭合）

| #    | 差距                                             | 当前状态          | 目标状态         |
| ---- | ------------------------------------------------ | ----------------- | ---------------- |
| P1-1 | PRG-002 真实 Kafka DLQ e2e                       | 本地 adapter 验证 | broker e2e PASS  |
| P1-2 | PRG-003 canary 部署演练                          | script 已实现     | 生产 canary 执行 |
| P1-3 | PRG-006 HA/DR 文档                               | 缺失              | 完整部署文档     |
| P1-4 | PRG-007 credential rotation                      | 缺失              | rotation runbook |
| P1-5 | HTTP `/ingest` gate 为 smoke-only                | 生产可暴露        | smoke-only       |
| P1-6 | main.go 配置收敛                                 | env 散落          | configx 统一     |
| P1-7 | 文档精简（退役文件删除 + TRACEABILITY 历史迁移） | 冗余              | 精简             |
| P1-8 | SPEC §14 client 目录结构修正                     | 独立 module       | monorepo 对齐    |

### 4.3 可延后项（P2 — 发布后迭代）

| #    | 差距                              | 说明                                 |
| ---- | --------------------------------- | ------------------------------------ |
| P2-1 | spec-runtime drift 检测脚本       | 自动化比对 SPEC WHEN/THEN 与代码覆盖 |
| P2-2 | cost 指标从 anchor 升级为完整实现 | FR-043 当前为骨架                    |
| P2-3 | 多 endpoint 负载均衡              | client OQ-003 待评估                 |
| P2-4 | WS 多路复用                       | client OQ-005 待评估                 |
| P2-5 | client 横向扩展                   | client OQ-007 待评估                 |

---

## 5. 补充与优化建议

### 5.1 Client/Server 边界规范强化

#### 5.1.1 通信契约冻结

当前 natsx subject 格式 `binance.market.{product_line}.{event_type}` 已定义但未版本化。建议：

- subject 增加 `.v1` 后缀：`binance.market.{product_line}.{event_type}.v1`
- 与 Kafka topic `binance.{product_line}.{event_type}.v1` 对齐
- 版本变更通过 BR-007 wire contract externality gate 强制

#### 5.1.2 HTTP `/ingest` 退化路径关闭

```go
// cmd/binance-server/main.go
if smokeModeFromEnv() {
    mux.HandleFunc("/ingest", ingestHandler)
}
// 生产模式不注册 /ingest 路由
```

#### 5.1.3 `internal/wire` 角色明确化

将 `internal/wire` 重命名或注释为 "HTTP-to-NATS transport adapter"，明确其非 canonical wire contract owner。canonical wire payload 为 `domain_market.MarketFactEnvelope` JSON。

### 5.2 生产部署准备

#### 5.2.1 GitHub Actions CI

```yaml
# .github/workflows/ci.yml
jobs:
  build-test:
    steps:
      - go build ./...
      - go test ./... -race -count=1
      - go vet ./...
      - golangci-lint run
      - govulncheck ./...
      - ./scripts/boundary-gates.sh
      - mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out
```

#### 5.2.2 HA/DR 部署文档

需补充以下文档：

- NATS JetStream 集群部署（≥3 节点，RPO=0，RTO<30s）
- Redis Sentinel/Cluster（RPO<1s，RTO<10s）
- PostgreSQL 主从复制（RPO<1s，RTO<60s）
- TDengine 集群部署（RPO<5s，RTO<60s）
- Kafka 集群（≥3 broker，RF=3，RPO=0，RTO<30s）

#### 5.2.3 Credential Rotation Runbook

- Binance API Key/Secret 轮换流程
- NATS credentials 轮换流程
- Redis/PostgreSQL/TDengine/Kafka 密码轮换流程
- 轮换期间零停机策略

### 5.3 文档治理优化

#### 5.3.1 文档精简计划

| 文件               | 当前                | 动作                     | 目标       |
| ------------------ | ------------------- | ------------------------ | ---------- |
| TRACEABILITY.md    | 380+ 行（40% 历史） | 历史注记迁移到 CHANGELOG | <200 行    |
| SPEC.md            | 1550+ 行            | 参数表迁移到 design/     | <1000 行   |
| 4 个退役文件       | 存在但 DEPRECATED   | 物理删除                 | 0          |
| BOUNDARY-GATES §20 | 推广模板            | 迁移到 docs/governance/  | 不在此文件 |
| todo.md            | 26/26 完成（矛盾）  | 对齐 Code-State 或归档   | 准确或删除 |

#### 5.3.2 状态模型简化

废除双态模型，恢复单一状态：

```
Done    = 代码完整 + 装配就绪 + TC PASS + evidence 归档
Partial = 代码存在但有缺口（子链路/注入/覆盖/E2E）
Drifted = 代码存在但 spec 已变更导致行为不一致
Pending = 仅规格登记
```

`release_closeable` 标准：**≥90% FR Done + 0 Drifted + 0 Pending + PRG 全 PASS + 远程 CI PASS + release tag**。

### 5.4 代码完成度提升路径

按优先级分批闭合 25 个 Code-Partial FR：

**第一批（P0 核心 — 2 周）**：

- FR-007/007a：完整装配 Gin 路由 + 所有 endpoint 可用
- FR-016/017/025：backfill/gap detection/throttle 完整实现
- FR-023：远程 CI evidence
- FR-024：完整 catalog reload + no-restart proof

**第二批（P1 生产就绪 — 1 周）**：

- FR-011：HA 选举完整验证
- FR-026/027/028：reconcile/rehydration/progress 完整运行
- FR-031~036：ExchangeInfo sync 覆盖深度提升

**第三批（P2 合规 — 1 周）**：

- FR-038~044：retention/tracing/quota/audit/schema/cost/compliance 从 anchor 升级为完整实现

---

## 6. 结论

### 6.1 核心判断

`module/binance` 的**架构设计和边界强制是优秀的**——分布式 C/S 架构清晰，14 道 boundary gate CI 拦截，client/server 进程/代码/通信三层隔离到位。SPEC 的 FR/BR/AC/TC 追溯链完整（100% 登记）。

但**距离生产级可发布还有显著差距**：

1. **代码完成度不足**：48 个 FR 中仅 23 个 Code-Done（48%），25 个核心 FR 为 Partial
2. **状态模型混乱**：双态模型将 25 个 Partial FR 标为 Evidence-Done，`release_closeable=YES` 的声明过于乐观
3. **生产证据缺失**：无远程 CI、无 release tag、HA/DR 文档缺失、PRG 多项证据不完整
4. **文档冗余严重**：退役文件未删除、TRACEABILITY 历史膨胀、SPEC 过度细碎

### 6.2 可发布路径

```
当前状态 → [闭合 P0-1: 25 Partial FR] → [P0-2: 远程 CI] → [P0-3: release tag] → [P0-4: 状态模型修正] → [P0-5: HA/DR 文档] → 可发布
```

**预估工作量**：4-6 周（2 人），其中闭合 25 Partial FR 占 60%。

### 6.3 边界规范度评价

Client/Server 边界是本模块最强项，评分 **9.0/10**。建议强化的 3 项：

1. HTTP `/ingest` gate 为 smoke-only
2. `internal/wire` 角色明确化
3. subject 版本化（`.v1` 后缀）

---

> [COMPUTED, HIGH] 本报告基于 `module/binance/` 全量文档（README/SPEC/client-SPEC/server-SPEC/TRACEABILITY/BOUNDARY-GATES/CHANGELOG/todo/goal/design/）与 runtime 仓库 `/home/binance` HEAD `2efc44a` 代码实态交叉分析。评分依据为各维度文档与代码的交叉验证，非单一来源声明。
>
> [KNOWN] SPEC 声称 `release_closeable=YES` 基于 Evidence-State 44/44 Done，但本报告判定该标准过于宽松——Code-State 48% Done 的模块不应声明可发布。
>
> [INFERRED] 25 个 Code-Partial FR 的 Evidence-Done 可能基于 anchor 级实现（代码存在但未完整装配或未覆盖全部 WHEN/THEN 分支），而非完整功能验证。

[RULES I BROKE]：无。本报告遵循了证据标签、置信度标注和反奉承规则。最强反论证已前置（"release_closeable=YES 声明过于乐观"）。
