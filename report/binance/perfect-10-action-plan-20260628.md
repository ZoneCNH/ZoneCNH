# module/binance 满分 10 逐维度提升方案

> 创建日期：2026-06-28
> 基线报告：`report/binance/deep-structural-analysis-20260628.md`
> 目标：每个维度从当前评分提升至 10/10，达到生产级可发布状态
> Spec-Version：v3.9.0 · Runtime-Version：v0.2.0 · Runtime-Anchor：`/home/binance@2efc44a`

> Current alignment note（2026-06-28 v3.9.6 → P10 fix round）：本方案是 P10 修复前的行动基线。P10 修复轮已完成：43 GitHub issues + 43 Beads issues 全部关闭；Phase 1（16 issues）deliverable 完整验证；Phase 2-6（27 issues）deliverable 已创建，pending live validation。当前 SSOT 为 `module/binance/spec/SPEC.md`、`module/binance/matrix/TRACEABILITY.md`、`module/binance/todo.md` 与 `module/binance/evidence/2026-06-28/review/p10-issue-alignment.md`；当前结论为 `release_closeable=NO`（Code-Done 23/48 ≈ 47.9% < 90%）。10 轮验证全部 PASS。Runtime branch: `feat/p10-fix-20260628`。

---

## 评分总览与目标

| 维度 | 当前 | 目标 | 差距 | 预估工作量 |
|------|:----:|:----:|:----:|-----------|
| 架构设计 | 9.0 | 10 | 1.0 | 2 天 |
| 边界强制 | 9.5 | 10 | 0.5 | 1 天 |
| Spec 完整性 | 8.5 | 10 | 1.5 | 3 天 |
| 追溯矩阵 | 8.0 | 10 | 2.0 | 2 天 |
| 代码完成度 | 5.5 | 10 | 4.5 | 3-4 周 |
| 生产就绪 | 5.0 | 10 | 5.0 | 2 周 |
| 文档治理 | 6.5 | 10 | 3.5 | 3 天 |
| 测试覆盖 | 7.0 | 10 | 3.0 | 1-2 周 |
| 可观测性 | 7.5 | 10 | 2.5 | 1 周 |
| 安全合规 | 6.0 | 10 | 4.0 | 1-2 周 |
| **总计** | **7.2** | **10** | **2.8** | **6-8 周（2 人）** |

---

## 1. 架构设计 9.0 → 10

### 当前扣分项（-1.0）

| 扣分点 | 扣分 | 原因 |
|--------|:----:|------|
| `internal/wire` 角色与 BR-007 语义张力 | -0.4 | wire 包定义 HTTP ingest 消息结构，与"canonical wire schema 属于 domain_market"存在矛盾 |
| main.go 手动 env 装配（383 行） | -0.3 | 配置散落在 main 包，非 config-driven DI |
| HTTP `/ingest` 退化路径生产可暴露 | -0.2 | 绕过 NATS 边界的 fallback 路径未 gate |
| subject 未版本化 | -0.1 | natsx subject 无 `.v1` 后缀，无法平滑升级 |

### 达到 10 的行动清单

#### A-1：`internal/wire` 角色明确化 [0.4 分]

```go
// internal/wire/doc.go
// Package wire 提供 HTTP-to-NATS 传输适配器类型。
// 本包不拥有 canonical wire schema——canonical payload 为
// domain_market.MarketFactEnvelope JSON。
// 本包仅定义 HTTP /ingest 入口的消息边界适配类型，
// 供 cmd/binance-smoke 本地 self-test 使用。
package wire
```

- 在 SPEC §4.1 C6 补充说明：`internal/wire` 是 transport adapter，非 wire contract owner
- 在 BOUNDARY-GATES §8 补充检查：`internal/wire` 不得定义 canonical domain 类型（只做适配）

#### A-2：main.go 配置收敛 [0.3 分]

```go
// 目标 main.go 结构（<60 行）
func main() {
    cfg := binancecfg.Load()           // 统一配置加载 + 校验
    app, err := server.New(cfg)        // DI 组装
    if err != nil { log.Fatal(err) }
    bootstrap.Run(app)                 // 生命周期编排
}
```

- 将所有 `os.Getenv` / `env()` 调用迁移到 `pkg/binancecfg`
- `smokeModeFromEnv()` / `dispatcherModeFromEnv()` 迁移到 config 层
- `storage_env.go` 逻辑合并到 `binancecfg.Load` + `server.New`
- main.go 仅保留入口逻辑

#### A-3：HTTP `/ingest` gate 为 smoke-only [0.2 分]

```go
// cmd/binance-server/main.go
if cfg.Server.SmokeMode {
    mux.HandleFunc("/ingest", ingestHandler)
    slog.Warn("HTTP /ingest endpoint registered in smoke mode only")
}
// 生产模式不注册 /ingest
```

- BOUNDARY-GATES §6 补充检查：非 smoke 模式下 `/ingest` 路由不存在
- 新增 gate：`grep -r "HandleFunc.*ingest" cmd/binance-server/ && ! smoke gate → FAIL`

#### A-4：subject 版本化 [0.1 分]

| 当前 | 目标 |
|------|------|
| `binance.market.{pl}.{et}` | `binance.market.{pl}.{et}.v1` |

- SPEC §9 subject 表全量加 `.v1`
- Kafka topic 已为 `.v1`，natsx subject 对齐
- BOUNDARY-GATES §12 检查 subject 格式包含 `.v1`

---

## 2. 边界强制 9.5 → 10

### 当前扣分项（-0.5）

| 扣分点 | 扣分 | 原因 |
|--------|:----:|------|
| HTTP `/ingest` 退化路径 | -0.3 | 生产可暴露，绕过 NATS 边界 |
| client/SPEC §14 目录结构与 runtime 不一致 | -0.1 | SPEC 写独立 `client/go.mod`，runtime 是 monorepo |
| boundary-gates.sh 未检查 subject 版本化 | -0.1 | 缺少 `.v1` 格式校验 |

### 达到 10 的行动清单

#### B-1：HTTP `/ingest` smoke-only gate [0.3 分]

- 见 A-3
- 新增 boundary gate §15：`Production mode must not register /ingest route`
- 验证命令：`XGO_BINANCE_SMOKE=0 ./binance-server & curl -s localhost:8080/ingest → 404`

#### B-2：client/SPEC §14 目录结构修正 [0.1 分]

```text
# 修正前（client/SPEC §14）
client/
├── go.mod          ← 独立 module（错误）
├── go.sum
├── SPEC.md

# 修正后
# Runtime monorepo 布局（github.com/ZoneCNH/binance）
internal/client/
├── catalog/
├── connector/
├── connectors/
├── normalize/
├── mapper/
├── idempotency/
├── publisher/
├── admin/
└── ...
```

- client/SPEC §14 改为 monorepo `internal/client/` 布局
- 与 server/SPEC §14 对称

#### B-3：subject 版本化 gate [0.1 分]

- BOUNDARY-GATES §12 新增检查：`rg "binance\.market\.[a-z_]+\.[a-z_]+" --type go | grep -v "\.v1" → FAIL`
- 确保所有 publish/subscribe 代码使用 `.v1` subject

---

## 3. Spec 完整性 8.5 → 10

### 当前扣分项（-1.5）

| 扣分点 | 扣分 | 原因 |
|--------|:----:|------|
| 部分 WHEN/THEN 过度细碎（参数表/分策略表在 SPEC 而非 design） | -0.5 | FR-013 退避参数表、FR-017 分策略检测表应在 design |
| 4 个退役文件仍存在 | -0.4 | DEPRECATED 但未删除 |
| SPEC.md 超 1550 行 | -0.3 | 信息密度低，检索困难 |
| AC/TC 编号空间有历史协调痕迹（AC-131~154 vs AC-105~130） | -0.3 | 编号空间协调说明残留 |

### 达到 10 的行动清单

#### C-1：参数表迁移到 design/ [0.5 分]

| 迁移内容 | 源 | 目标 |
|---------|---|------|
| FR-013 退避参数表（base_delay/max_delay/multiplier/jitter/budget） | SPEC §7 FR-013 | `design/EXCHANGE-RELIABILITY.md` |
| FR-013 HTTP 429/418 差异化策略详细参数 | SPEC §7 FR-013 | `design/EXCHANGE-RELIABILITY.md` |
| FR-017 分策略检测表（6 种 event_type） | SPEC §7 FR-017 | `design/GAP-DETECTION.md` |
| FR-025 P0/P1/P2 三级优先级详细参数 | SPEC §7 FR-025 | `design/BACKFILL-THROTTLE.md` |
| FR-029 per-event-type 字段级校验规则表 | SPEC §7 FR-029 | `design/DATA-QUALITY.md` |
| FR-036 tier×productLine 流组合映射表 | SPEC §7 FR-036 | `design/CONNECTION-TOPOLOGY.md` |

SPEC 保留 WHEN/THEN 主体 + 引用链接：`详见 design/EXCHANGE-RELIABILITY.md §参数表`。

#### C-2：退役文件物理删除 [0.4 分]

```bash
git rm module/binance/spec/DATA-LIFECYCLE.md
git rm module/binance/spec/DATA-QUALITY-SLA.md
git rm module/binance/spec/ENDPOINTS.md
git rm module/binance/spec/SPEC-exchangeinfo-sync.md
```

- git 历史保留追溯能力
- SPEC §14 目录结构移除"已退役文件"小节
- 所有引用这些文件的链接更新为指向 SPEC 对应章节或 design/

#### C-3：SPEC 精简至 <1000 行 [0.3 分]

- 执行 C-1 后 SPEC 行数预计降至 ~1100 行
- 进一步精简：FR→AC 映射索引表（§7 末尾）迁移到 TRACEABILITY §5（已存在），SPEC 仅保留引用
- Metadata 区块精简（去掉过长的 Last-Updated 变更说明，保留版本号 + 日期 + 一句话摘要）
- 目标：SPEC < 1000 行，每行信息密度高

#### C-4：AC/TC 编号空间清理 [0.3 分]

- 删除 TRACEABILITY 中的编号空间协调说明（"AC-105~128→131~154"等）
- AC 编号连续递增，不保留协调痕迹
- 如有历史需要，迁移到 `docs/migrations/ac-bnc-legacy-mapping.md`（已存在）

---

## 4. 追溯矩阵 8.0 → 10

### 当前扣分项（-2.0）

| 扣分点 | 扣分 | 原因 |
|--------|:----:|------|
| 双态模型导致状态认知混乱 | -0.8 | 25 个 Code-Partial 标为 Evidence-Done |
| TRACEABILITY 历史注记占 40%+ | -0.5 | v3.5.1/v3.6.0/v3.6.1 等历史变更注记未迁移 |
| 旧 release-closeable YES 声明基于 Evidence-State 而非 Code-State | -0.4 | 标准过于宽松 |
| todo.md 声称 26/26 完成与 Code-State 矛盾 | -0.3 | 状态不一致 |

### 达到 10 的行动清单

#### D-1：废除双态模型，恢复单一状态 [0.8 分]

```text
Done    = 代码完整 + 装配就绪 + TC PASS + evidence 归档
Partial = 代码存在但有缺口
Drifted = 代码存在但 spec 已变更导致行为不一致
Pending = 仅规格登记
```

- Evidence-Done 必须以 Code-Done 为前提
- Code-Partial FR 的 Evidence 列改为 Evidence-Pending
- `release_closeable` 标准：≥90% FR Done + 0 Drifted + 0 Pending + PRG 全 PASS + 远程 CI PASS + release tag

#### D-2：历史注记迁移 [0.5 分]

- TRACEABILITY §1 的所有 `> **v3.x.x 历史变更摘要**` 注记迁移到 CHANGELOG
- TRACEABILITY 只保留当前状态 + 最近一次变更摘要（1 条）
- 目标：TRACEABILITY < 200 行

#### D-3：`release_closeable` 标准修正 [0.4 分]

```text
release_closeable = (
    Code-Done FR / Total FR ≥ 90%
    AND Drifted FR = 0
    AND Pending FR = 0
    AND PRG-001~007 全 PASS
    AND 远程 CI PASS
    AND release tag 已发布
    AND HA/DR 部署文档存在
)
```

- 当前状态：Code-Done 48% → `release_closeable=NO`

#### D-4：todo.md 对齐或归档 [0.3 分]

- todo.md 26/26 完成是基于 Evidence-State（已废除此概念）
- 选项 A：更新 todo.md 为 25 个 Code-Partial FR 的闭合计划
- 选项 B（推荐）：归档 todo.md 到 `evidence/2026-06-28/todo-archived.md`，新 TODO 使用 Beads `bd` 管理

---

## 5. 代码完成度 5.5 → 10

### 当前扣分项（-4.5）

| 扣分点 | 扣分 | 原因 |
|--------|:----:|------|
| 25 个 Code-Partial FR | -4.0 | 52% FR 代码不完整 |
| main.go 装配问题 | -0.3 | 手动 env 装配 |
| spec-runtime drift | -0.2 | 多个 FR 的 WHEN/THEN 与 runtime 代码覆盖不一致 |

### 达到 10 的行动清单

#### E-1：第一批 P0 核心 FR 闭合 [1.5 分]

| FR | 缺口 | 闭合标准 | 预估 |
|----|------|---------|------|
| FR-007 | Gin 路由完整装配 | 所有 `/api/v1/market/*` endpoint 可用 + e2e | 2 天 |
| FR-007a | Analytics API 完整 | vwap/top-movers/correlation/volume-profile 全可用 | 1 天 |
| FR-016 | REST fetcher 注入 + 历史回填起始时间完整 | history_fetcher 真实注入 + cursor 恢复 e2e + per-event_type 回填策略（bar/trade/funding_rate/mark_price 可回填，depth/tick 拒绝 BNC-019）+ trade fromId 分页 + 冷启动→实时切换 + 探测 weight 预算 | 3 天 |
| FR-017 | depth 快照刷新 | depth updateId 跳跃→snapshot refresh 完整 | 1 天 |
| FR-023 | 远程 CI evidence | GitHub Actions CI run evidence 归档 | 1 天 |
| FR-024 | 完整 reload proof | no-restart 集成测试 + live proof | 1 天 |

#### E-2：第二批 P1 生产就绪 FR 闭合 [1.0 分]

| FR | 缺口 | 闭合标准 | 预估 |
|----|------|---------|------|
| FR-011 | HA 选举完整 | 多实例锁竞争 + lease 续期 + failover e2e | 1 天 |
| FR-013 | 限流全覆盖 | AIMD 恢复 + 418 熔断 + clock skew 全分支 TC | 1 天 |
| FR-025 | 自适应降速 | P2 降为 0 + 恢复策略 e2e | 1 天 |
| FR-026 | 对账完整运行 | 04:00 UTC job + tolerance + alerts 表 e2e | 1 天 |
| FR-027 | 回热完整运行 | OSS→taosx 回热 + 24h TTL 过期 e2e | 1 天 |
| FR-028 | 持久化验证 | postgresx state-store + 重启恢复 e2e | 1 天 |

#### E-3：第三批 P2 ExchangeInfo FR 闭合 [0.8 分]

| FR | 缺口 | 闭合标准 | 预估 |
|----|------|---------|------|
| FR-031 | 四线发现完整 | spot/um/cm/options exchangeInfo 拉取 + API 陷阱处理 | 1 天 |
| FR-032 | 持久化 + 刷新 | upsert + 6h diff-only + control stream + Reload/SyncCatalog | 1 天 |
| FR-033 | tier 分级 | SymbolsByTier + admin PATCH + 默认 disabled | 0.5 天 |
| FR-034 | 白名单 | deny>allow>tier 裁决 + admin reload 集成 | 0.5 天 |
| FR-035 | admin auth | Bearer token + loopback fallback + audit_log | 0.5 天 |
| FR-036 | 连接拓扑 | StreamsForProductLineTier + 分组连接 + 升降级 drain | 1 天 |

#### E-4：第四批 P2 合规 FR 闭合 [0.7 分]

| FR | 缺口 | 闭合标准 | 预估 |
|----|------|---------|------|
| FR-038 | retention 完整 | 定时 DELETE + OSS ETag 前置校验 + DB KEEP | 0.5 天 |
| FR-039 | tracing 完整 | OTel SDK + W3C traceparent + slog trace_id + 采样 | 1 天 |
| FR-040 | quota 完整 | Kafka quota + WS 连接池 + API per-caller + CH 超时 | 1 天 |
| FR-041 | audit 完整 | admin 写审计 + append-only + 保留期 + OSS 归档 | 0.5 天 |
| FR-042 | schema version | MAJOR reject + MINOR 兼容 + 兼容矩阵 | 0.5 天 |
| FR-043 | cost 完整 | 存储/带宽指标 + 预算告警 | 0.5 天 |
| FR-044 | destruction 完整 | data_classification + 合规保留 + 销毁证明 | 0.5 天 |

#### E-5：main.go 装配重构 [0.3 分]

- 见 A-2

#### E-6：spec-runtime drift 检测 [0.2 分]

```bash
# scripts/spec-drift-check.sh
# 对比 SPEC WHEN/THEN 数量与 runtime test 覆盖的分支数
when_count=$(rg "^\*\*WHEN\*\*" module/binance/spec/SPEC.md | wc -l)
test_count=$(rg "func Test" /home/binance/internal/ | wc -l)
# 当 when_count / test_count < 0.8 时 WARN
```

---

## 6. 生产就绪 5.0 → 10

### 当前扣分项（-5.0）

| 扣分点 | 扣分 | 原因 |
|--------|:----:|------|
| 无远程 CI | -1.5 | 所有证据为本地运行 |
| 无 release tag | -1.0 | runtime v0.2.0 未发布 |
| PRG 证据不完整 | -0.8 | PRG-002/003/005/006/007 多项缺口 |
| HA/DR 文档缺失 | -0.7 | NATS/Redis/PG/TDengine/Kafka 部署文档 |
| credential rotation runbook 缺失 | -0.5 | 无密钥轮换流程 |
| 无 canary 部署演练 | -0.3 | script 已实现但未执行 |
| 无容量规划 | -0.2 | 无存储/带宽/TPS 容量预估 |

### 达到 10 的行动清单

#### F-1：GitHub Actions 远程 CI（self-hosted runners） [1.5 分]

> **强制要求**：CI/CD 必须使用 **self-hosted runners**，禁止使用 GitHub-hosted runners（`ubuntu-latest` 等）。原因：(1) 需要访问内网基础设施（NATS/Redis/PG/TDengine/Kafka/OSS）；(2) live E2E 测试需要内网连通性；(3) 安全合规要求构建环境可控。

```yaml
# .github/workflows/binance-ci.yml
name: Binance CI
on: [push, pull_request]
jobs:
  build:
    runs-on: [self-hosted, linux, binance]
    # self-hosted runner 要求：
    # - Linux x86_64，Go 1.23+，golangci-lint, govulncheck 已预装
    # - 内网连通 NATS/Redis/PG/TDengine/Kafka/OSS（STORAGE_LIVE=1 可用）
    # - runner label: binance（专用 runner group）
    steps:
      - uses: actions/checkout@v4
      - name: Verify Go version
        run: go version | grep -q '1.23' || (echo "Go 1.23+ required" && exit 1)
      - run: go build ./...
      - run: go vet ./...
      - run: go test ./... -race -count=1
      - run: |
          mkdir -p .coverage
          go test ./... -coverprofile=.coverage/cover.out -count=1
          go tool cover -func=.coverage/cover.out
      - run: golangci-lint run
      - run: govulncheck ./...
      - run: ./scripts/boundary-gates.sh
      - name: Live E2E (self-hosted only)
        env:
          STORAGE_LIVE: "1"
        run: |
          set -a; source .env; set +a
          go test ./test/e2e/... -tags=live -count=1 -v
      - uses: actions/upload-artifact@v4
        with: { name: ci-evidence, path: .coverage/ }
```

**self-hosted runner 配置要求**：

| 项目 | 要求 |
|------|------|
| OS | Linux x86_64（Ubuntu 22.04+ 或等价） |
| Go | 1.23+（预装） |
| 工具链 | golangci-lint, govulncheck, gitleaks（预装） |
| 内网连通 | NATS :4222 / Redis :6379 / PG :5432 / TDengine :6041 / Kafka :9092 / OSS endpoint |
| Runner label | `self-hosted, linux, binance`（专用 group） |
| 并发 | ≥2 job（CI + live E2E 并行） |
| 安全 | runner 机器在内网，通过 GitHub Actions self-hosted agent 回连；无公网入站 |
| 缓存 | Go module cache 持久化（`~/go/pkg/mod`）以加速构建 |

- 首次远程 CI PASS 后归档 evidence 到 `evidence/ci/{run_id}/`
- FR-023 Code-Partial → Done

#### F-2：Release tag 发布 [1.0 分]

```bash
# 前置条件
# 1. 远程 CI PASS
# 2. Code-Done FR ≥ 90% (≥43/48)
# 3. PRG-001~007 全 PASS
# 4. CHANGELOG 更新

git tag -a v0.2.0 -m "Binance market data C/S module v0.2.0"
git push origin v0.2.0
gh release create v0.2.0 --title "v0.2.0" --notes-file CHANGELOG-v0.2.0.md
```

- 生成 live evidence：release tag + CHANGELOG 片段 + CI evidence 引用
- 归档到 `evidence/live/v0.2.0/`

#### F-3：PRG 全 PASS [0.8 分]

| PRG | 行动 | 验证 |
|-----|------|------|
| PRG-001 | ClickHouse DDL 确认 ReplicatedMergeTree 或记录单节点例外 | DDL diff + TTL 验证 |
| PRG-002 | 真实 Kafka broker DLQ e2e | topic/ACL contract + failure-injection |
| PRG-003 | canary 部署演练 | `/readyz` + error-rate + rollback drill |
| PRG-004 | 多租户 soak test | quota config + failure isolation |
| PRG-005 | 端到端 trace 可视化 | OTel span/log + Jaeger/Tempo 截图 |
| PRG-006 | HA/DR 部署文档 | 见 F-4 |
| PRG-007 | credential rotation runbook | 见 F-5 |

#### F-4：HA/DR 部署文档 [0.7 分]

新建 `docs/deployment/` 目录：

| 文档 | 内容 |
|------|------|
| `nats-ha.md` | NATS JetStream 集群部署（≥3 节点，RPO=0，RTO<30s） |
| `redis-ha.md` | Redis Sentinel/Cluster（RPO<1s，RTO<10s） |
| `postgres-ha.md` | PostgreSQL 主从复制（RPO<1s，RTO<60s） |
| `tdengine-ha.md` | TDengine 集群部署（RPO<5s，RTO<60s） |
| `kafka-ha.md` | Kafka 集群（≥3 broker，RF=3，RPO=0，RTO<30s） |
| `minio-oss-ha.md` | MinIO/OSS 高可用（RPO=0，RTO<5min） |
| `ha-dr-summary.md` | 汇总 RPO/RTO 矩阵 + 灾难恢复 runbook |

#### F-5：Credential Rotation Runbook [0.5 分]

新建 `docs/runbooks/credential-rotation.md`：

| 凭证 | 轮换流程 | 零停机策略 |
|------|---------|-----------|
| Binance API Key/Secret | 生成新 key → 更新 env → rolling restart | 双 key 并行期 |
| NATS credentials | 生成新 user → 更新 env → rolling restart | 旧 user 72h 后 revoke |
| Redis password | CONFIG SET requirepass → 更新 env → rolling restart | Sentinel failover 期间容忍 |
| PostgreSQL password | ALTER ROLE → 更新 env → rolling restart | 连接池自动重连 |
| TDengine password | ALTER USER → 更新 env → rolling restart | 连接池自动重连 |
| Kafka SASL/SCRAM | 新增 credential → 更新 env → rolling restart | 旧 credential 72h 后删除 |

#### F-6：Canary 部署演练 [0.3 分]

```bash
# scripts/deploy-canary.sh
kubectl rollout deployment binance-server --canary
# 等待 5min
./scripts/deploy-canary-gate.sh  # /readyz + error-rate + consumer-lag
# PASS → full rollout
# FAIL → kubectl rollout undo
```

- 记录演练证据到 `evidence/canary/{date}/`

#### F-7：容量规划 [0.2 分]

新建 `docs/capacity-planning.md`：

| 组件 | 预估 TPS | 存储增长/日 | 内存 | CPU |
|------|---------|------------|------|-----|
| client (4 线) | 40K events/s | — | 256MB | 2 core |
| NATS JetStream | 40K msg/s | ~50GB/天 (7d ret) | 4GB | 4 core |
| server | 40K events/s | — | 1-4GB | 4 core |
| taosx | 40K writes/s | ~100GB/天 | 8GB | 8 core |
| clickhousex | ETL 5min | ~20GB/天 | 4GB | 4 core |
| postgresx | ~1K writes/s | ~1GB/天 | 2GB | 2 core |
| redisx | ~40K ops/s | ~1GB | 2GB | 2 core |
| ossx | — | ~100GB/天 (归档) | — | — |
| kafkax | 40K msg/s | ~50GB/天 | 4GB | 4 core |

---

## 7. 文档治理 6.5 → 10

### 当前扣分项（-3.5）

| 扣分点 | 扣分 | 原因 |
|--------|:----:|------|
| TRACEABILITY 历史注记膨胀（40%+） | -1.0 | v3.5.1~v3.9.0 变更注记未迁移 |
| 4 个退役文件未删除 | -0.8 | DEPRECATED 但仍存在 |
| SPEC.md 超 1550 行 | -0.6 | 信息密度低 |
| BOUNDARY-GATES §20 推广模板不属此文件 | -0.4 | 跨模块内容混入 |
| todo.md 与 Code-State 矛盾 | -0.4 | 26/26 完成 vs 25 Partial |
| 文档间版本号/状态引用不一致 | -0.3 | README/FEATURES/ACCEPTANCE/TRACEABILITY 统计需手动同步 |

### 达到 10 的行动清单

#### G-1：TRACEABILITY 精简 [1.0 分]

- 所有 `> **v3.x.x 历史变更摘要**` 注记迁移到 CHANGELOG
- TRACEABILITY 只保留：当前状态表 + 最近一次变更摘要 + FR/BR/NFR/TC/AC 表
- 目标：< 200 行

#### G-2：退役文件物理删除 [0.8 分]

- 见 C-2

#### G-3：SPEC 精简 [0.6 分]

- 见 C-1 + C-3

#### G-4：BOUNDARY-GATES §20 迁移 [0.4 分]

- §20 推广模板迁移到 `docs/governance/boundary-gates-template.md`
- BOUNDARY-GATES 只保留本模块 14 道 gate

#### G-5：todo.md 归档 [0.4 分]

- 见 D-4

#### G-6：状态一致性 CI gate 自动化 [0.3 分]

```bash
# .github/ci/binance-status-consistency-check.sh
# 已存在（P2-8），需增强：
# - 校验 README / FEATURES / ACCEPTANCE / TRACEABILITY 的 Code-Done 统计一致
# - 校验 release_closeable 与 Code-Done 比例一致
# - 校验无双态模型残留（Evidence-Done for Code-Partial FR → FAIL）
```

---

## 8. 测试覆盖 7.0 → 10

### 当前扣分项（-3.0）

| 扣分点 | 扣分 | 原因 |
|--------|:----:|------|
| Code-Partial FR 的 TC 覆盖深度不足 | -1.5 | 25 个 Partial FR 的 TC 可能只覆盖 happy path |
| 覆盖率未达 98% | -0.5 | SPEC 要求 ≥98%，当前未确认 |
| 无远程 CI 测试证据 | -0.5 | 全部为本地 |
| 无压力/soak test | -0.3 | 无持续负载测试 |
| 无混沌/故障注入测试 | -0.2 | 无网络分区/存储故障注入 |

### 达到 10 的行动清单

#### H-1：Partial FR 深度测试补全 [1.5 分]

每个 Code-Partial FR 闭合时必须补全：

| 测试类型 | 要求 |
|---------|------|
| Happy path | WHEN/THEN 主体全覆盖 |
| Error path | 每个 WHEN/THEN 的失败分支 |
| Edge case | SPEC §13 Edge Cases 对应场景 |
| Integration | 跨组件端到端 |
| Race condition | `-race` flag 下 PASS |

#### H-2：覆盖率 ≥ 98% 验证 [0.5 分]

```bash
mkdir -p .coverage
go test ./... -coverprofile=.coverage/cover.out -count=1
go tool cover -func=.coverage/cover.out | tail -1
# 目标：total: ≥ 98.0%
```

- 低于 98% 的包补充测试
- 覆盖率报告归档到 `evidence/coverage/`

#### H-3：远程 CI 测试 [0.5 分]

- 见 F-1
- 远程 CI 必须运行 `go test -race -count=1`

#### H-4：Soak Test [0.3 分]

```bash
# test/soak/soak_test.go
// 持续 30min 负载测试
// - 4 产品线并发采集
// - 内存/ goroutine / FD 监控
// - 无内存泄漏（heap growth < 10%）
// - 无 goroutine 泄漏（goroutine count stable）
```

#### H-5：混沌测试 [0.2 分]

```bash
# test/chaos/chaos_test.go
// - NATS 断连恢复
// - Redis 不可达降级
// - taosx 写入失败 Nak
// - Kafka 不可达 DLQ
// - 进程 SIGKILL 重启恢复
```

---

## 9. 可观测性 7.5 → 10

### 当前扣分项（-2.5）

| 扣分点 | 扣分 | 原因 |
|--------|:----:|------|
| cost/audit 指标为 anchor 级 | -0.8 | FR-043/044 指标骨架未完整实现 |
| OTel tracing 端到端可视化未验证 | -0.5 | 传播已实现但无 Jaeger/Tempo 截图 |
| 无 Grafana dashboard | -0.5 | 无可视化仪表盘 |
| 无 AlertManager 告警规则 | -0.4 | 告警规则未配置 |
| 无日志聚合配置 | -0.3 | slog 结构化日志但无 Loki/ELK 配置 |

### 达到 10 的行动清单

#### I-1：cost/audit 指标完整实现 [0.8 分]

```go
// internal/server/metrics/cost.go
var (
    StorageBytesTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{Name: "binance_storage_bytes_total"},
        []string{"store", "product_line"},
    )
    BandwidthBytesTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{Name: "binance_bandwidth_bytes_total"},
        []string{"direction", "product_line"},
    )
    StorageBytesPerHour = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{Name: "binance_storage_bytes_per_hour"},
        []string{"store", "product_line"},
    )
)
```

- FR-043 cost 指标从 anchor 升级为完整 CounterVec/GaugeVec
- FR-044 audit 指标补充 lifecycle audit counter

#### I-2：OTel 端到端可视化 [0.5 分]

```bash
# 部署 Jaeger 或 Tempo
docker run -p 16686:16686 jaegertracing/all-in-one

# 运行端到端测试并截图
# - client normalize span
# - NATS publish span
# - server consume span
# - kafkax dispatch span
# - 全链路 trace 可视化
```

- 截图归档到 `evidence/observability/tracing-e2e.png`

#### I-3：Grafana Dashboard [0.5 分]

新建 `docs/observability/grafana-dashboard.json`：

| Panel | 指标 | 告警阈值 |
|-------|------|---------|
| Consumer Lag | `binance_server_consumer_lag` | > 1000 |
| E2E Latency P99 | `binance_e2e_latency_seconds` | > 200ms |
| Accept Rate | `binance_server_accepted_total` | — |
| Reject Rate | `binance_server_rejected_total` | > 1% |
| Duplicate Rate | `binance_server_duplicate_total` | > 5% |
| Stream State | `binance_stream_state` | disconnected |
| Kafka Dispatch Failures | `binance_server_kafkax_dispatch_failures_total` | > 0 |
| Storage Write Latency | taosx write latency | > 50ms |
| Memory RSS | runtime.MemStats | > 80% limit |
| Cost Storage | `binance_storage_bytes_total` | > budget |

#### I-4：AlertManager 告警规则 [0.4 分]

新建 `docs/observability/alerts.yaml`：

```yaml
groups:
  - name: binance-critical
    rules:
      - alert: BinanceConsumerLagHigh
        expr: binance_server_consumer_lag > 1000
        for: 5m
        labels: { severity: critical }
      - alert: BinanceE2ELatencyHigh
        expr: histogram_quantile(0.99, binance_e2e_latency_seconds) > 0.2
        for: 5m
        labels: { severity: warning }
      - alert: BinanceStreamDown
        expr: binance_stream_state{state="disconnected"} == 1
        for: 1m
        labels: { severity: critical }
      - alert: BinanceRejectRateHigh
        expr: rate(binance_server_rejected_total[5m]) / rate(binance_server_consumed_total[5m]) > 0.01
        for: 5m
        labels: { severity: warning }
      - alert: BinanceKafkaDispatchFailures
        expr: rate(binance_server_kafkax_dispatch_failures_total[5m]) > 0
        for: 1m
        labels: { severity: critical }
```

#### I-5：日志聚合配置 [0.3 分]

新建 `docs/observability/logging.yaml`：

```yaml
# Loki Promtail 配置
scrape_configs:
  - job_name: binance
    static_configs:
      - targets: [localhost]
        labels:
          job: binance
          __path__: /var/log/binance/*.log
    pipeline_stages:
      - json:
          expressions:
            level: level
            product_line: product_line
            trace_id: trace_id
      - labels:
          level:
          product_line:
```

---

## 10. 安全合规 6.0 → 10

### 当前扣分项（-4.0）

| 扣分点 | 扣分 | 原因 |
|--------|:----:|------|
| credential rotation runbook 缺失 | -1.0 | 无密钥轮换流程 |
| admin auth 仅 loopback，无 mTLS | -0.6 | 生产环境需反向代理认证 |
| 无 secrets 扫描 CI gate | -0.5 | gitleaks 仅本地 |
| 无依赖漏洞扫描 CI gate | -0.5 | govulncheck 仅本地 |
| 无网络隔离文档 | -0.4 | NATS/Redis/PG/TDengine/Kafka TLS/mTLS 配置缺失 |
| 无数据分类标注实施 | -0.4 | FR-044 data_classification 仅 spec |
| 无合规销毁演练 | -0.3 | FR-044 销毁证明未执行 |
| 无渗透测试 | -0.3 | 无 API 安全测试 |

### 达到 10 的行动清单

#### J-1：Credential Rotation Runbook [1.0 分]

- 见 F-5

#### J-2：Admin Auth + mTLS [0.6 分]

```yaml
# configs/binance-server.env.example
# 生产环境 admin 认证
ADMIN_BIND=:8082
ADMIN_TLS_CERT=/etc/binance/tls/admin.crt
ADMIN_TLS_KEY=/etc/binance/tls/admin.key
ADMIN_TOKEN=${FOUNDATIONX_BINANCE_ADMIN_TOKEN}
# 非 loopback 必须启用 TLS + Bearer token
```

- Gin admin 端点启用 TLS
- 生产环境强制 Bearer token（`ADMIN_TOKEN` 非空时拒绝无 token 请求）
- 文档记录反向代理（nginx/Caddy）+ mTLS 配置

#### J-3：Secrets 扫描 CI gate [0.5 分]

```yaml
# .github/workflows/binance-ci.yml (self-hosted runner)
- name: gitleaks
  run: gitleaks detect --no-git --source .
  # self-hosted runner 预装 gitleaks，直接本地执行
```

#### J-4：依赖漏洞扫描 CI gate [0.5 分]

```yaml
# .github/workflows/binance-ci.yml (self-hosted runner)
- name: govulncheck
  run: govulncheck ./...
- name: go mod audit
  run: |
    go list -json -m all | govulncheck -mode=source ./...
    # self-hosted runner 预装 govulncheck，无需 GitHub-hosted action
```

#### J-5：网络隔离文档 [0.4 分]

新建 `docs/security/network-isolation.md`：

| 组件 | 协议 | TLS | mTLS | 网络策略 |
|------|------|:---:|:----:|---------|
| client → Binance | WSS/HTTPS | ✅ | — | 出站 only |
| client → NATS | TCP | ✅ | ✅ | NATS namespace |
| server → NATS | TCP | ✅ | ✅ | NATS namespace |
| server → Redis | TCP | ✅ | — | Redis namespace |
| server → PostgreSQL | TCP | ✅ | — | PG namespace |
| server → TDengine | TCP | ✅ | — | TDengine namespace |
| server → Kafka | TCP | ✅ | SASL | Kafka namespace |
| server → OSS | HTTPS | ✅ | — | 出站 only |
| server → ClickHouse | TCP | ✅ | — | CH namespace |
| market_data → server Gin | HTTP | ✅ | — | 内网 only |
| SRE → admin | HTTP | ✅ | mTLS | VPN only |

#### J-6：数据分类标注实施 [0.4 分]

```sql
-- migrations/004_data_classification.sql
ALTER TABLE binance_tick 
  ADD COLUMN data_classification TEXT DEFAULT 'market_public';
ALTER TABLE binance_bar
  ADD COLUMN data_classification TEXT DEFAULT 'market_public';
-- ... 所有表添加 data_classification 列
```

- 新增数据自动标注 `data_classification`
- 合规保留期配置：`market_public` 7y / `market_derived` 3y / `operational` 1y / `audit` 7y

#### J-7：合规销毁演练 [0.3 分]

```bash
# scripts/destruction-drill.sh
# 1. 选择测试数据（>retention 的 operational 数据）
# 2. 执行不可逆销毁（OSS delete + taosx DROP STABLE + PG DELETE）
# 3. 生成 certificate_of_destruction JSON
# 4. 归档到 OSS binance/certificates/{YYYY}/
# 5. 写入 audit_log
```

#### J-8：API 渗透测试 [0.3 分]

```bash
# test/security/api_security_test.go
# - SQL 注入测试（/api/v1/market/ticks?symbol='; DROP TABLE--）
# - XSS 测试（/api/v1/instruments?product_line=<script>）
# - 路径遍历测试（/api/v1/market/../../../etc/passwd）
# - 速率限制测试（1000+ req/min → 429）
# - 未认证访问测试（无 API key → 401）
# - Admin 端点越权测试（GET-only 用户 POST → 403）
```

---

## 执行路径

### 阶段 1：基础修复（第 1-2 周）

```
文档治理 (G) + Spec 完整性 (C) + 追溯矩阵 (D) + 边界强制 (B) + 架构设计 (A)
→ 文档精简、退役文件删除、双态模型废除、main.go 重构、HTTP /ingest gate
→ 预期：维度 1-4 + 7 达到 9.5+
```

### 阶段 2：代码闭合（第 3-5 周）

```
代码完成度 (E) 第一批 + 第二批 + 第三批 + 第四批
→ 25 个 Code-Partial FR 逐批闭合
→ 预期：维度 5 达到 9.0+
```

### 阶段 3：生产部署（第 5-6 周）

```
生产就绪 (F) + 测试覆盖 (H) + 可观测性 (I) + 安全合规 (J)
→ 远程 CI、release tag、PRG 全 PASS、HA/DR 文档、soak test、Grafana dashboard、credential rotation
→ 预期：维度 6/8/9/10 达到 9.5+
```

### 阶段 4：收尾验证（第 6-7 周）

```
全维度最终验证
→ 所有 FR Code-Done + 远程 CI PASS + release tag + PRG 全 PASS + 覆盖率 ≥98%
→ soak test PASS + 混沌测试 PASS + 渗透测试 PASS
→ 预期：全维度 10/10
```

---

## 验收标准

| 检查项 | 标准 | 命令 |
|--------|------|------|
| FR 完成度 | ≥43/48 Code-Done (≥90%) | `rg "Done" TRACEABILITY.md §1` |
| 远程 CI | GitHub Actions PASS（self-hosted runner） | `gh run list --workflow=binance-ci.yml` |
| Release tag | `v0.2.0` 已发布 | `gh release view v0.2.0` |
| 覆盖率 | ≥ 98% | `go tool cover -func=.coverage/cover.out` |
| Boundary gates | 14/14 PASS | `./scripts/boundary-gates.sh` |
| PRG | 7/7 PASS | PRG-001~007 evidence 归档 |
| HA/DR 文档 | 7 份文档存在 | `ls docs/deployment/` |
| Credential rotation | runbook 存在 | `ls docs/runbooks/credential-rotation.md` |
| Grafana dashboard | JSON 存在 | `ls docs/observability/grafana-dashboard.json` |
| AlertManager 规则 | YAML 存在 | `ls docs/observability/alerts.yaml` |
| Soak test | 30min PASS | `test/soak/soak_test.go` |
| 混沌测试 | 全 PASS | `test/chaos/chaos_test.go` |
| 渗透测试 | 全 PASS | `test/security/api_security_test.go` |
| 文档精简 | SPEC <1000 行 / TRACEABILITY <200 行 | `wc -l` |
| 退役文件 | 0 个存在 | `ls module/binance/spec/DATA-LIFECYCLE.md` → not found |

---

> [COMPUTED, HIGH] 本方案基于 `report/binance/deep-structural-analysis-20260628.md` 的 10 维度评分，每个维度的扣分点均有对应的闭合行动。总预估工作量 6-8 周（2 人），其中代码闭合（维度 5）占 50%。
>
> [INFERRED] 阶段 1（文档治理）可在 1 周内完成且不依赖代码变更，建议立即启动。阶段 2（代码闭合）是关键路径，需按 P0→P1→P2 顺序执行。
>
> [KNOWN] 旧 release-closeable YES 声明基于已废除的双态模型 Evidence-State；当前 v3.9.6 口径已改为 `release_closeable=NO`，后续重新判定必须基于单态模型与 issue-level evidence。

[RULES I BROKE]：无。本方案遵循了证据标签、置信度标注和反奉承规则。
