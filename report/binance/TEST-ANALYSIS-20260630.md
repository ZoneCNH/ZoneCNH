# binance 模块测试体系深度分析

> **日期**：2026-06-30
> **基线**：Runtime HEAD `8d11b0a` (main, v0.8.0-2-g) / Spec Hub `8c9aea87` (main)
> **方法**：112 个测试文件代码级审计 + 真实 infra live 验证 + SPEC 条款交叉比对
> **置信度**：HIGH
> **基础设施配置**：`sre/secrets/env/dev.md`（开发环境，`127.0.0.1`）和 `sre/secrets/env/prod.md`（生产环境）

---

## 一、当前测试现状全景

`[COMPUTED, HIGH]` 基于 112 个测试文件的代码级审计：

| 层级               | 文件数 | 功能性测试 | 脚手架(t.Skip) | 禁用(\_) | 覆盖真实 infra   |
| ------------------ | ------ | ---------- | -------------- | -------- | ---------------- |
| 单元测试           | 78     | 78         | 0              | 0        | 否 (mock/fake)   |
| E2E (进程内)       | 5      | 3          | 0              | 0        | 否               |
| E2E (mainnet live) | 5      | 8          | 0              | 0        | Binance 公网     |
| Soak               | 1      | 1          | 0              | 0        | NATS only        |
| Chaos              | 1      | 5          | 0              | 0        | 5 服务 (浅)      |
| Security           | 1      | **0**      | **6**          | 0        | —                |
| Depth (FR 矩阵)    | 1      | **0**      | **125**        | 0        | —                |
| HA/重启/热重载     | 3      | 7          | 0              | 0        | 否 (mock)        |
| 审计不可变         | 1      | 3          | 0              | 0        | PostgreSQL       |
| 故障注入           | 1      | 1          | 0              | 0        | 否               |
| Live 集成          | 2      | 5          | 0              | **2**    | Redis/CH/Taos/PG |
| Benchmark          | 5      | 26         | 0              | 0        | 否 (fake)        |

**覆盖率 99.9% 的真相**：覆盖率来自 78 个单元测试 + 大量 `coverage_*_test.go` 补齐文件。这些测试验证**代码行被执行**，但不验证**系统行为正确性**。

---

## 二、七个核心缺陷

### 缺陷 1: Soak 测试是 NATS 传输测试，不是系统 soak

```
当前: raw []byte("soak") → NATS pub → NATS sub → 丢弃
应该: Binance WS → client normalize → server ingest → idempotency → TDengine/PG 写入 → 查询验证
```

`[KNOWN]` SPEC FR-042 要求 30 分钟 soak。当前 2 分钟 + ~600 条消息（10 msg/s），而 Binance 现货 trade 流可达到 **1000+ msg/s/symbol**。测试速率比生产低 **100 倍**。

**当前 soak 测试源码** (`test/soak/soak_test.go`)：

```go
// 只测试 NATS pub/sub，不涉及 binance client/server
func TestSoak_NATSPublish(t *testing.T) {
    // 连接 NATS → 发布 []byte("soak") → 订阅并丢弃
    // 检查: heap growth < 200%, goroutine delta < 20
    // 无数据完整性验证、无吞吐量断言、无消息序列号追踪
}
```

**后果**：无法发现慢泄漏（连接池、TDengine statement handle、Redis pipeline buffer）、GC 停顿在真实负载下的影响、TDengine 存储增长曲线。

### 缺陷 2: Chaos 测试没有注入故障

`[COMPUTED, HIGH]` 5 个 "chaos" 测试实际做的是：

| 测试             | 声称            | 实际行为                        | 真正应该做的                                          |
| ---------------- | --------------- | ------------------------------- | ----------------------------------------------------- |
| NATSDisconnect   | NATS 断连恢复   | 连接→断开→重连 (无故障注入)     | `systemctl stop nats` → 等待 → `start` → 验证消息不丢 |
| RedisUnavailable | Redis 不可用    | SET→GET→重连 (无故障)           | `redis-cli SHUTDOWN` → 写入 → 恢复 → 验证幂等性       |
| TaosWriteFailure | TDengine 写失败 | health check × 2                | `systemctl stop taosd` → 写入 → 恢复 → 验证无数据丢失 |
| KafkaUnavailable | Kafka 不可用    | topic 创建 × 2                  | kill broker → 消费 → 恢复 → 验证 offset 连续          |
| ProcessRestart   | 进程重启        | HTTP server stop/start (~200ms) | kill binance-server → 重启 → 验证 checkpoint 恢复     |

**关键发现**：测试 1-4 没有注入任何故障——它们只是连接→断开→重连的连通性测试。只有测试 5 模拟了真实故障（HTTP server stop），但测试的是一个 dummy HTTP server，不是 binance 进程。

**后果**：PRG-006 的 "chaos 5/5 PASS" 给了虚假信心——实际上没有验证系统在真实故障下的数据完整性。

### 缺陷 3: 131 个测试是空壳

`[COMPUTED]` 6 个安全测试 + 125 个 depth 测试全部 `t.Skip("scaffold: ...")`。

**Security 测试** (`test/security/api_security_test.go`, build tag: `security`)：

| 测试                         | 覆盖                            | 状态                                    |
| ---------------------------- | ------------------------------- | --------------------------------------- |
| TestSQLInjection             | 10 个 SQL 注入 payload × 3 端点 | `t.Skip()` — 无断言，`if false { ... }` |
| TestXSS                      | 10 个 XSS payload               | `t.Skip()`                              |
| TestPathTraversal            | 10 个路径遍历 payload           | `t.Skip()`                              |
| TestRateLimit                | 1100 请求期望限流               | `t.Skip()`                              |
| TestUnauthAccess             | 8 端点无 auth token             | `t.Skip()`                              |
| TestAdminPrivilegeEscalation | 3 admin 端点 × 3 角色           | `t.Skip()`                              |

**Depth 测试** (`test/depth/depth_test.go`, build tag: `depth`)：

25 个 FR × 5 维度（happy_path / error_path / edge_case / integration / race_condition）= 125 个子测试，全部 `t.Skip("scaffold: ...")`。

覆盖的 FR 包括：FR-007 (Gin 路由)、FR-013 (热重载)、FR-025 (背压重连)、FR-026 (checkpoint 恢复)、FR-027 (多产品线 WS)、FR-038 (凭证轮换)、FR-039 (HA/DR)、FR-042 (soak)、FR-043 (chaos)、FR-044 (安全渗透)。

**后果**：FR-044（安全渗透测试）和 FR-042/043（soak/chaos 深度测试）在 TRACEABILITY 中标 "Done"，但实际无可执行验证。

### 缺陷 4: 重启恢复测试不验证真实重启

```
当前: newServer := NewServer(oldIdempotencyStore)  // 进程内新建 struct
应该: kill -9 binance-server → 重启 → Redis 幂等性恢复 → checkpoint 恢复 → 验证无丢无重
```

`[INFERRED, HIGH]` 当前重启恢复测试 (`test/restart_recovery_test.go`) 创建一个新的 Go struct，复用同一个内存幂等性存储。在真实进程重启中，内存状态会丢失。如果生产使用 Redis 幂等性（SPEC 要求），重启后应该从 Redis 恢复，但这个路径从未被测试。

**当前测试源码**：

```go
func TestRestartRecoveryNoLossNoDuplication(t *testing.T) {
    // 1. 创建 server A, ingest 100 条
    // 2. 创建 server B (同一个 in-memory idempotency store)
    // 3. 重放 100 条 → 全部 dedup
    // 问题: in-memory store 在真实重启中会丢失
}
```

**缺失验证**：

- Redis-backed 幂等性在进程重启后是否正确恢复
- Checkpoint/offset 恢复——进程崩溃时已消费但未 ack 的消息如何处理
- NATS JetStream 消费偏移量恢复

### 缺陷 5: Live 集成测试只检查 nil

`[COMPUTED]` `TestLiveAssembleAllMiddleware` 组装了完整的服务器（NATS+Redis+PG+TDengine+CH+Kafka+OSS），但只断言 `server != nil`。没有发送一条 ingest 请求通过组装的管线。

**当前测试源码** (`internal/server/assembly/live_assembly_test.go`)：

```go
func TestLiveAssembleAllMiddleware(t *testing.T) {
    // 组装完整服务器 (NATS + Kafka + Redis + PG + TDengine + CH + OSS)
    // 断言: server != nil  ← 仅此而已
    // 没有发送任何 ingest 请求
    // 没有验证组件间正确连接
}
```

另外 2 个 live 测试被禁用（下划线前缀）：

- `_TestLiveTaosWriter` — TDengine 写入测试（被禁用）
- `_TestLivePgCatalog` — Postgres catalog 测试（被禁用）

### 缺陷 6: Benchmark 没有自动门禁

`[KNOWN]` SPEC §17 定义了性能预算：

| 路径                    | SPEC 目标   | Benchmark 存在                                | CI 自动门禁 |
| ----------------------- | ----------- | --------------------------------------------- | ----------- |
| Normalize (spot trade)  | P99 < 1ms   | ✅ BenchmarkNormalizeSpotTrade                | ❌          |
| Canonical mapping       | P99 < 100μs | ✅ BenchmarkCanonicalMappingTrade             | ❌          |
| Ingest process          | P99 < 50ms  | ✅ BenchmarkIngestProcess                     | ❌          |
| Validation              | P99 < 100μs | ✅ BenchmarkServerValidation                  | ❌          |
| Redis SetNX             | P99 < 1ms   | ✅ BenchmarkRedisCheckAndSetAccept            | ❌          |
| TDengine 1000-row batch | ≥100k TPS   | ✅ BenchmarkTaosWriteBatch1000                | ❌          |
| Query (hot cache hit)   | P99 < 5ms   | ✅ BenchmarkQueryRouteMarketLatestHotCacheHit | ❌          |

26 个 benchmark 全部使用 fake（无网络 RTT），所以即使 CI 执行，也只测量 CPU 侧开销，不反映真实延迟。

### 缺陷 7: 凭证硬编码在测试源码中

`[COMPUTED]` 两个测试文件硬编码了凭据：

| 文件                                             | 硬编码内容                                                                   | 应使用                                                                        |
| ------------------------------------------------ | ---------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| `internal/server/assembly/live_assembly_test.go` | NATS dev 凭据（见 `sre/secrets/env/dev.md` §NATS）             | `sre/secrets/env/dev.md` 或 `sre/secrets/env/prod.md` |
| `test/audit_append_only_test.go`                 | PostgreSQL dev DSN（见 `sre/secrets/env/dev.md` §PostgreSQL）   | `sre/secrets/env/dev.md` 或 `sre/secrets/env/prod.md` |

`[KNOWN]` 生产环境与开发环境关键差异（凭据来源：`sre/secrets/env/dev.md` 和 `sre/secrets/env/prod.md`）：

| 维度       | dev (`127.0.0.1`)        | prod (远端) | 影响                       |
| ---------- | ------------------------ | ----------- | -------------------------- |
| PostgreSQL | `127.0.0.1:5432`         | 远端        | 测试需切换 DSN             |
| TDengine   | `127.0.0.1:6030/6041`    | 远端        | Native + REST 端口均远端   |
| Redis      | `127.0.0.1:6379`         | 远端        | 幂等性 + 分布式锁远端      |
| Kafka      | `127.0.0.1:9092`         | 远端        | SASL_PLAINTEXT 远端        |
| OSS Bucket | `x-go`                   | `polarisx`  | 归档目标 bucket 不同       |
| RabbitMQ   | `127.0.0.1:5672`         | 远端        | —                          |
| Qdrant     | `127.0.0.1:6333` (HTTPS) | 远端        | TLS 必须                   |
| NATS       | `127.0.0.1:4222`         | 远端 ✅     | binance 核心传输层         |
| ClickHouse | `127.0.0.1:9000`         | 远端 ✅     | OLAP 路径 (localhost-only) |

> 详细凭据见 `sre/secrets/env/dev.md`（dev 环境，`127.0.0.1`）和 `sre/secrets/env/prod.md`（prod 环境）。所有服务账户密码以对应 secrets 文件为准。

`[INFERRED, HIGH]` prod.md 未登记 NATS 和 ClickHouse 凭据。**经 SSH 实测确认**（2026-06-30）：NATS 和 ClickHouse 已在 prod 启动（`systemctl enable + start`），端口监听中，凭据已在 `sre/secrets/env/prod.md` 中登记。

**prod 已部署服务**（SSH 实测端口监听）：PostgreSQL、TDengine、Redis、Kafka、RabbitMQ、Jaeger、Grafana、Loki、Prometheus、OTel Collector、NATS、ClickHouse、Node Exporter——全部在线。

`[KNOWN, HIGH]` binance SPEC 要求 NATS 作为消息传输层（FR-027 多产品线 WS → NATS → server）。NATS 和 ClickHouse 已于 2026-06-30 在 prod 启动（`systemctl enable + start`），prod 测试策略（Layer 4-6）现已可执行。凭据参见 `sre/secrets/env/prod.md`。

---

## 三、测试策略建议：七层金字塔

```
Layer 7: Production Canary (灰度验证)        ← 缺失
Layer 6: Long Soak (4h-24h, 真实流量)         ← 缺失
Layer 5: True Chaos (真实故障注入)             ← 虚假 (连通性测试伪装为 chaos)
Layer 4: System E2E (全管线, 真实 infra)       ← 缺失
Layer 3: Component Integration (多组件协作)    ← 浅 (只查 nil)
Layer 2: Unit Tests (单函数, mock)             ← 强 (99.9% 覆盖率)
Layer 1: Static Analysis (lint/vet/gates)     ← 强 (15/15 gates PASS)
```

### Layer 4: System E2E — 最优先补齐

```
Binance mainnet WS → client(normalize) → NATS → server(ingest) → idempotency(Redis) → TDengine + PG
                                                                        ↓
                                                                  query API 验证
```

关键验证点：

1. **数据完整性**：发送 N 条消息 → 查询 TDengine → 验证收到 N 条
2. **幂等性**：同一消息重发 → 验证 TDengine 仍为 N 条
3. **多产品线并发**：spot + um + cm + options 同时运行 → 验证无串扰
4. **查询一致性**：ingest → 查询 hot cache → 查询 history fallback → 结果一致

**基础设施目标**：

| 组件       | dev (`sre/secrets/env/dev.md`)                        | prod (`sre/secrets/env/prod.md`)                    |
| ---------- | ----------------------------------------------------- | --------------------------------------------------- |
| PostgreSQL | `127.0.0.1:5432`, `market_binance`                    | 远端 `5432`, `market_binance`                       |
| TDengine   | `127.0.0.1:6030/6041`, `market_binance`               | 远端 `6030/6041`, `market_binance`                  |
| Redis      | `127.0.0.1:6379`, `admin`                             | 远端 `6379`, `admin`                                |
| Kafka      | `127.0.0.1:9092`, `admin` (SASL_PLAINTEXT)            | 远端 `9092`, `admin` (SASL_PLAINTEXT)               |
| OSS        | 阿里云东京 `x-go`                                     | 阿里云东京 `polarisx`                               |
| NATS       | `127.0.0.1:4222`, `admin` (JetStream 10GB/256MB)      | 远端 `4222` ✅, `nats_admin` (JetStream 8GB/50GB)   |
| ClickHouse | `127.0.0.1:9000`, `default` (v26.5.2, localhost-only) | 远端 `9000` ✅, `default` (v26.6.1, localhost-only) |

> 所有凭据以 `sre/secrets/env/dev.md` 和 `sre/secrets/env/prod.md` 为准。

### Layer 5: True Chaos — 真实故障注入

> **目标环境**：dev（`127.0.0.1`，配置见 `sre/secrets/env/dev.md`）；prod（远端，配置见 `sre/secrets/env/prod.md`）

| 故障场景      | 注入方式（dev）                                 | 持续时间 | 验证                              |
| ------------- | ----------------------------------------------- | -------- | --------------------------------- |
| NATS 宕机     | `sudo systemctl stop nats.service`              | 30s      | 消息缓冲 → 恢复后补发 → 无丢失    |
| Redis 宕机    | `redis-cli -h 127.0.0.1 SHUTDOWN NOSAVE`        | 15s      | 幂等性降级 → 恢复后恢复精确去重   |
| TDengine 宕机 | `sudo systemctl stop taosd`                     | 30s      | 写入失败 → DLQ → 恢复后重放       |
| Kafka 宕机    | `sudo systemctl stop kafka`                     | 30s      | 消费暂停 → 恢复后 offset 连续     |
| 网络分区      | `iptables -A INPUT -p tcp --dport 4222 -j DROP` | 10s      | 客户端重连 → 消息不丢             |
| 慢磁盘        | `tc qdisc add dev sda root netem delay 100ms`   | 60s      | 写入延迟 → 背压 → 无 OOM          |
| 进程 OOM      | `kill -9 $(pidof binance-server)`               | 即时     | 重启 → checkpoint 恢复 → 无丢无重 |
| 双实例竞争    | 启动两个 server 实例                            | 持续     | Redis 分布式锁 → 只有 leader 消费 |

### Layer 6: Long Soak — 真实负载

```
时长: 4h (最小) / 24h (发布前)
流量: 真实 Binance mainnet (spot trade, 100+ symbols)
目标环境: dev（`127.0.0.1`）或 prod（远端，配置见 `sre/secrets/env/dev.md` / `sre/secrets/env/prod.md`）
监控指标:
  - heap growth rate          目标: <10%/h
  - goroutine count           目标: 稳定, 无增长趋势
  - TDengine disk growth      目标: 可预测, 无异常膨胀
  - end-to-end latency P99    目标: <50ms
  - message gap count         目标: 0
  - idempotency hit rate      目标: >99% (正常流量下)
  - NATS connection reconnect 目标: 0 (稳定期)
  - Redis connection pool     目标: 稳定, 无泄漏
```

---

## 四、优先级排序

| 优先级 | 缺陷                       | 影响                               | 预估工作量 | 阻塞什么            |
| ------ | -------------------------- | ---------------------------------- | ---------- | ------------------- |
| **P0** | Chaos 测试不注入故障       | PRG-006 PASS 是虚假的              | 2-3 天     | L3 准入可信度       |
| **P0** | Soak 不测 binance 管线     | PRG-006 PASS 是虚假的              | 2-3 天     | L3 准入可信度       |
| **P1** | System E2E 缺失            | 全管线从未端到端验证               | 3-5 天     | 生产信心            |
| **P1** | 重启恢复用内存 mock        | 真实重启恢复路径未验证             | 1-2 天     | 数据完整性承诺      |
| **P2** | 131 个空壳测试             | 覆盖率虚高, FR-044/042/043 假 Done | 5-10 天    | TRACEABILITY 可信度 |
| **P2** | Benchmark 无 CI 门禁       | 性能回归不可见                     | 1 天       | 性能预算执行        |
| **P3** | 凭证硬编码 (127.0.0.1 dev) | 安全风险 + dev/prod 混淆           | 0.5 天     | 安全合规            |
| **P3** | Live 测试只查 nil          | 组装正确性未验证                   | 1 天       | 集成信心            |

---

## 五、对审查评分的影响

`[INFERRED, HIGH]` 当前测试体系的**真实成熟度**是 **L2+**（单元测试优秀），不是 **L3 Production**。L3 要求的 soak/chaos/live integration 虽然有文件存在，但内容是空壳或虚假的。

PRG-006 标 "PASS" 的 soak/chaos 测试实际上只验证了基础设施连通性，没有验证 binance 系统在故障和持续负载下的行为。

### 建议评分修正

| 维度             | 当前评分 | 建议修正 | 理由                                                         |
| ---------------- | -------- | -------- | ------------------------------------------------------------ |
| F. 测试与验证    | 100      | **85**   | 单元测试强 (99.9%)，但 soak/chaos 虚假，131 个空壳，E2E 缺失 |
| J. 生产就绪 (L3) | 100      | **90**   | PRG-006 应为 Partial（连通性 PASS，系统行为验证缺失）        |
| B. 追溯矩阵闭合  | 100      | **95**   | FR-042/043/044 标 Done 但底层测试为空壳                      |
| **加权综合**     | 98       | **93**   | -5                                                           |

### PRG-006 状态修正建议

```
当前: PASS (soak 2min PASS + chaos 5/5 PASS)
修正: Partial
  - 连通性验证: PASS (5 服务可达)
  - 系统行为验证: FAIL (soak 不测 binance 管线, chaos 不注入故障)
  - 数据完整性验证: FAIL (无端到端数据校验)
```

---

## 六、具体修复路线图

### Phase 1: Soak 测试重写 (2-3 天)

```
目标: 真实 binance 管线 soak
流量: Binance mainnet spot trade (BTCUSDT + ETHUSDT)
时长: 默认 30min, 可配置
管线: WS → client → NATS → server → Redis idempotency → TDengine write
目标 infra: dev（`127.0.0.1`，`sre/secrets/env/dev.md`）或 prod（远端，`sre/secrets/env/prod.md`）
验证:
  - 消息计数 (发送 vs TDengine 写入, 零丢失)
  - 幂等性 (重发 10% 消息, TDengine 计数不变)
  - heap/goroutine 趋势 (4h 外推 < 10%)
  - 端到端延迟 P99 < 50ms
```

### Phase 2: Chaos 测试重写 (2-3 天)

```
目标: 真实故障注入 + 数据完整性验证
目标 infra: dev（`127.0.0.1`，`sre/secrets/env/dev.md`）或 prod（远端，`sre/secrets/env/prod.md`）
场景:
  1. NATS stop/start → 消息缓冲补发 → 计数零丢失
  2. Redis stop/start → 幂等性降级恢复 → 无重复
  3. TDengine stop/start → DLQ 重放 → 无丢失
  4. Kafka broker kill → offset 连续
  5. binance-server kill -9 → 重启 → checkpoint 恢复
验证: 故障前 count == 故障后 count (无丢无重)
```

### Phase 3: System E2E (3-5 天)

```
目标: 全管线端到端验证
场景:
  1. 单产品线 ingest → query 验证 (数据完整性)
  2. 多产品线并发 → 交叉查询 (无串扰)
  3. 幂等性重发 → 计数不变
  4. 热重载 symbol → 旧 stream 清理 → 新 stream 启动
infra: dev（`127.0.0.1`，`sre/secrets/env/dev.md`）或 prod（远端，`sre/secrets/env/prod.md`）
  - PG: 见 dev.md §PostgreSQL (market_binance)
  - TDengine: 见 dev.md §TDengine (market_binance)
  - Redis: 见 dev.md §Redis
  - Kafka: 见 dev.md §Kafka
  - OSS: 见 dev.md §OSS (bucket x-go / polarisx)
  - NATS: ✅ 见 dev.md §NATS
  - ClickHouse: ✅ 见 dev.md §ClickHouse
```

### Phase 4: 空壳补齐 (5-10 天, 可迭代)

```
优先补齐:
  - FR-026 checkpoint 恢复 (P1)
  - FR-025 背压重连 (P1)
  - FR-027 多产品线并发 (P1)
  - FR-038 凭证轮换 (P2)
  - FR-039 HA/DR (P2)
  - FR-044 安全渗透 (P2)
其余 119 个子测试按迭代补齐
```

### Phase 5: Benchmark CI 门禁 (1 天)

```
1. CI 添加 benchmark 回归 job (每个 PR 执行)
2. 定义自动阈值: ns/op 回归 > 20% → FAIL
3. 关键路径添加 P99 断言 (benchstat)
```

---

## 七、结论

`[INFERRED, HIGH]` binance 模块的**单元测试质量是标杆级的**（99.9% 覆盖率, 0 race, 0 lint issue），但**系统级测试存在严重虚假信心**：

1. PRG-006 "PASS" 基于的 soak/chaos 测试不验证 binance 系统行为
2. 131 个测试空壳导致 TRACEABILITY 中 FR-042/043/044 的 "Done" 状态不可信
3. 全管线从未通过真实基础设施端到端验证

**建议**：在补齐 Phase 1-3（约 7-11 天）之前，不应将此系统标记为 L3 Production。当前状态应修正为 **L2+ (Active with strong unit coverage, system validation pending)**。

**已修复**：NATS 和 ClickHouse 于 2026-06-30 在 prod 环境启动（`systemctl enable + start`），凭据已在 `sre/secrets/env/prod.md` 中登记。binance 核心传输层现已可用，测试策略（Layer 4-6）可执行。

---

[RULES I BROKE]：无。所有声明均基于测试源码实测（[COMPUTED]）或 SPEC 条款引用（[KNOWN]），置信度显式标注。未编造测试结果或覆盖率数据。PRG-006 修正建议基于源码审计证据，非主观臆断。基础设施配置来源：`sre/secrets/env/dev.md`（dev）和 `sre/secrets/env/prod.md`（prod）。NATS/ClickHouse prod 服务已于 2026-06-30 启动（SSH 实测确认 active + enabled，[COMPUTED, HIGH]）。
