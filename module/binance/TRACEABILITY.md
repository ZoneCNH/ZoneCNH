# module/binance TRACEABILITY

> 追溯矩阵 — 确保 FR/BR → AC → TC → Task → Status 闭环可追溯。
>
> 规范来源：`docs/governance/TRACEABILITY.md`

- Matrix-Version: v2.1.0
- Last-Updated: 2026-06-21
- Spec-Reference: `module/binance/SPEC.md` v2.1.0

---

## §1 FR 追溯表

> **v2.1.0 变更摘要**：FR-006 拆分为 6a(tasox)/6b(postgresx)/6c(redisx cache)/6d(ossx)；FR-007 扩展 analytics API(7a)；新增 FR-010（clickhousex OLAP 存储）、FR-011（分布式协调锁）；subject 命名统一 `um_perp`/`cm_perp`；Error 码扩展至 BNC-013；Performance Budget 扩展至 20 项。

| FR ID | 功能需求 | AC | TC ID(s) | Task | 实现状态 |
|-------|----------|-----|----------|------|----------|
| FR-001 | Product-Line Support：Client 可独立采集 Spot / USDⓈ-M / COIN-M / Options 四产品线 | AC-001 ~ AC-003 | TC-001 | TASK-BINANCE-ROOT-001, CLIENT-001 | **Partial** — Spot connector 已实现；其余三产品线待后续迭代 |
| FR-002 | Instrument Identity：四产品线 canonical instrument identity 跨 product_line 不碰撞 | AC-004 ~ AC-006 | TC-002, TC-003 | TASK-BINANCE-ROOT-002, CLIENT-004 | **Partial** — Spot parser+mapper 已实现；USDM/COINM/Options 待后续 |
| FR-003 | natsx Communication：Client/Server 通过 natsx JetStream **网络**通信，禁止共享进程或内存 | AC-007 ~ AC-010 | TC-004, TC-005 | CLIENT-014, SERVER-010 | ⬜ Pending |
| FR-004 | At-Least-Once Delivery：JetStream durable consumer + ManualAck 确保消息不丢失 | AC-011 ~ AC-013 | TC-006 | CLIENT-014, SERVER-010 | ⬜ Pending |
| FR-005 | Idempotent Acceptance：redisx SetNX 确保相同消息最多写入 taosx 一次（72h TTL） | AC-014 ~ AC-016 | TC-007, TC-008 | SERVER-011 | ⬜ Pending |
| FR-006a | taosx Time-Series：WriteBatch 写入 tick/bar/depth 到超级表子表 | AC-017 ~ AC-018 | TC-009 | SERVER-012 | ⬜ Pending |
| FR-006b | postgresx Metadata：幂等 upsert instrument catalog + 审计日志 | AC-019 ~ AC-020 | TC-010 | SERVER-012 | ⬜ Pending |
| FR-006c | redisx Hot Cache：最新 tick/bar/depth 热缓存（60s/5s TTL），失败降级 | AC-036 ~ AC-037 | TC-023 | SERVER-013 | ⬜ Pending（v2.1.0 拆出） |
| FR-006d | ossx Archival：定时将 taosx 过期数据归档到 OSS，ETag 校验后删热 | AC-026 ~ AC-028 | TC-016, TC-017 | SERVER-016 | ⬜ Pending |
| FR-007 | Gin Market API：/api/v1/market/* REST 接口，redisx 热缓存 + taosx 回退 | AC-021 ~ AC-025 | TC-012 ~ TC-015 | SERVER-015 | ⬜ Pending |
| FR-007a | clickhousex Analytics API：/api/v1/analytics/* OLAP 查询（vwap/top-movers/correlation） | AC-038 ~ AC-040 | TC-024 | SERVER-015 | ⬜ Pending（v2.1.0 新增） |
| FR-008 | kafkax Broadcast：将 accepted facts 广播到 binance.market.* topic | AC-029 ~ AC-031 | TC-018, TC-019 | SERVER-014 | ⬜ Pending |
| FR-009 | Boundary Enforcement：CI gate 阻断 client/server 跨界、cs 包引用、go.mod 合规 | AC-032 ~ AC-035 | TC-020 ~ TC-022 | SERVER-008 | **Implemented** — BOUNDARY-GATES.md v2.0.0 落地 |
| FR-010 | clickhousex OLAP Storage：定时 ETL 聚合 taosx→clickhousex，为 analytics API 提供 OLAP 查询 | AC-041 ~ AC-044 | TC-025, TC-026 | SERVER-017 | ⬜ Pending（v2.1.0 新增） |
| FR-011 | Distributed Coordinator Lock：redisx SetNX 分布式锁，coordinator HA 选举 + lease 续期 | AC-045 ~ AC-047 | TC-027, TC-028 | SERVER-013 | ⬜ Pending（v2.1.0 新增） |

---

## §2 BR 追溯表

| BR ID | 业务规则 | 验证方式 | Task | 实现状态 |
|-------|----------|----------|------|----------|
| BR-001 | No binance-market：禁止在 active architecture 中引用 `binance-market` | CI Gate: BOUNDARY-GATES.md §2 | TASK-BINANCE-ROOT-000 | Pending |
| BR-002 | Client Must Not Import Server Internals | CI Gate: BOUNDARY-GATES.md §3 | CLIENT-014, SERVER-010 | Pending |
| BR-003 | Server Must Not Import Client Internals | CI Gate: BOUNDARY-GATES.md §4 | SERVER-010 | Pending |
| BR-004 | natsx ManualAck — 全链路写入成功（redisx+taosx+postgresx+kafkax handoff）后才 Ack；失败 NakWithDelay | TC-006: 处理失败→NakWithDelay 集成测试 | SERVER-010 | Pending |
| BR-005 | No cs Package：禁止 `internal/cs` 包；禁止 C/S 同进程运行 | CI Gate: BOUNDARY-GATES.md §5, §6 | SERVER-008 | **Documented** — BOUNDARY-GATES v2.0.0 |
| BR-006 | Server Owns Binance Storage：market_data 禁止直连 binance 的 taosx/postgresx/redisx/ossx | CI Gate: BOUNDARY-GATES.md §7 | SERVER-012 ~ SERVER-016 | Pending |
| BR-007 | No Domain Ownership：模块不得定义 canonical domain semantics SSOT，必须引用 `domain_market` | CI Gate: BOUNDARY-GATES.md §8 | TASK-BINANCE-ROOT-004 | Pending |
| BR-008 | Wire Contract Externality：不得定义自己的 proto，接口协议通过 natsx subject + JSON envelope | CI Gate: BOUNDARY-GATES.md §10 | SERVER-010, CLIENT-014 | Pending |
| BR-009 | go.mod Dependency Compliance：gin/ossx 为 direct；redisx/kafkax/natsx/postgresx/taosx 从 indirect 升为 direct | CI Gate: BOUNDARY-GATES.md §11 | SERVER-015, SERVER-016 | Pending |

---

## §3 NFR 追溯表

| NFR ID | 非功能需求 | 来源 (SPEC §) | 验证方式 |
|--------|------------|---------------|----------|
| NFR-001 | Client event normalization 延迟 P99 < 1ms | §17 Performance Budget | `go test -bench BenchmarkNormalize` |
| NFR-002 | Canonical mapping 延迟 P99 < 100μs | §17 | `go test -bench BenchmarkCanonicalMapping` |
| NFR-003 | natsx Publish 延迟 P99 < 10ms（含 JetStream PubAck 往返） | §17 | integration test |
| NFR-004 | Server consumer process (validate→store) 延迟 P99 < 50ms | §17 | integration test |
| NFR-005 | redisx SetNX 幂等检查 P99 < 1ms | §17 | `go test -bench BenchmarkIdempotencyCheck` |
| NFR-006 | redisx hot cache read P99 < 0.5ms | §17 | `go test -bench BenchmarkRedisCacheRead` |
| NFR-007 | taosx WriteBatch 吞吐量 ≥ 100,000 TPS | §17 | `go test -bench BenchmarkTaosWriteBatch` |
| NFR-008 | postgresx UpsertSymbol 延迟 P99 < 5ms | §17 | `go test -bench BenchmarkPgUpsert` |
| NFR-009 | clickhousex InsertBatch (50000 rows) 延迟 P99 < 500ms | §17 | integration test |
| NFR-010 | clickhousex analytics Query 延迟 P99 < 2s | §17 | integration test |
| NFR-011 | kafkax Send (async) 延迟 P99 < 5ms | §17 | integration test |
| NFR-012 | ossx Upload (100MB) 吞吐量 ≥ 50 MB/s | §17 | integration test |
| NFR-013 | Gin API /api/v1/market/ticks (redisx hit) P99 < 5ms | §17 | httptest benchmark |
| NFR-014 | Gin API /api/v1/analytics/vwap (clickhousex) P99 < 2s | §17 | httptest benchmark |
| NFR-015 | Gin API /api/v1/instruments (postgresx) P99 < 20ms | §17 | httptest benchmark |
| NFR-016 | Client restart recovery < 10s | §17 | integration test |
| NFR-017 | 各组件 Prometheus metrics 正确暴露（consumer lag/taosx TPS/API p99/dispatch errors） | §18 Observability | metrics endpoint |
| NFR-018 | 所有日志含 product_line + symbol + subject | §18 | 日志级别检查 |
| NFR-019 | API Key / Secret 从环境变量读取，不硬编码 | §19 Security | CI: `gitleaks detect --no-git` |
| NFR-020 | Secrets 不出现于 log、debug、admin 端点输出 | §19 | secret redaction test |

---

## §4 TC→FR 反向追溯

| TC ID | 覆盖 FR(s) | 覆盖 BR(s) | 测试类型 | 状态 |
|-------|------------|------------|----------|------|
| TC-001 | FR-001 | — | 集成（Binance testnet） | Pending |
| TC-002 | FR-002 | BR-007 | 单元（product_line identity） | Pending |
| TC-003 | FR-002 | BR-007 | 单元（cross product_line 不碰撞） | Pending |
| TC-004 | FR-003 | BR-005 | 集成（client natsx Publish，server 独立进程接收） | Pending |
| TC-005 | FR-003 | BR-002, BR-003 | CI gate（跨进程边界检查） | Pending |
| TC-006 | FR-004 | BR-004 | 集成（JetStream ManualAck：成功→Ack，失败→NakWithDelay） | Pending |
| TC-007 | FR-005 | — | 单元（SetNX 首次→新消息；重复→跳过） | Pending |
| TC-008 | FR-005 | — | 单元（Redis 不可达→error→NakWithDelay） | Pending |
| TC-009 | FR-006a | BR-006 | 单元（taosx WriteTick + WriteBatch） | Pending |
| TC-010 | FR-006b | BR-006 | 单元（postgresx UpsertSymbol 幂等） | Pending |
| TC-011 | FR-006a | — | 集成（taosx QueryRange 时间范围过滤） | Pending |
| TC-012 | FR-007 | — | httptest（/api/v1/market/ticks redisx hit + taosx fallback） | Pending |
| TC-013 | FR-007 | — | httptest（/api/v1/market/depth redisx cache） | Pending |
| TC-014 | FR-007 | — | httptest（API key 401） | Pending |
| TC-015 | FR-007 | — | httptest（限流 429） | Pending |
| TC-016 | FR-006d | BR-006 | 单元（先写 ossx ETag 校验后删 taosx） | Pending |
| TC-017 | FR-006d | — | 单元（归档路径格式） | Pending |
| TC-018 | FR-008 | — | 单元（kafkax topic + partition key） | Pending |
| TC-019 | FR-008 | BR-004 | 单元（kafkax 不可达→error/不 Ack） | Pending |
| TC-020 | FR-009 | BR-005 | CI gate（cs 包/client 包 import 检查） | **PASS** |
| TC-021 | FR-009 | BR-001 | CI gate（no-legacy 引用检查） | Pending |
| TC-022 | FR-009 | BR-009 | CI gate（go.mod 7 infra + gin + clickhousex direct） | Pending |
| TC-023 | FR-006c | — | 单元（redisx SET(tick:*, json, 60s)；PUT 失败→降级不阻塞） | Pending |
| TC-024 | FR-007a | — | httptest（/api/v1/analytics/vwap + top-movers + correlation） | Pending |
| TC-025 | FR-010 | BR-006 | 集成（clickhousex ETL：taosx Query → 聚合 → InsertBatch） | Pending |
| TC-026 | FR-010 | — | 单元（clickhousex 不可达→503 + ETL 跳过本批次） | Pending |
| TC-027 | FR-011 | — | 单元（redisx SetNX 获取锁 → 启动 ETL；5s 轮询重试） | Pending |
| TC-028 | FR-011 | — | 单元（lease 续期失败 → 停止任务；主动释放锁 → Del） | Pending |

---

## §5 AC 注册表

| AC ID | 所属 FR | AC 描述 | 验证方式 |
|-------|---------|---------|----------|
| AC-001 | FR-001 | Client 启动且 product-line 已启用时建立 WebSocket 连接并开始采集 | TC-001 |
| AC-002 | FR-001 | WebSocket 连接断开后自动重连，JetStream durable consumer 自动恢复消费位置 | 集成测试：模拟断连 → 验证重连 |
| AC-003 | FR-001 | 收到 Binance 原生事件后映射为 MarketFactEnvelope 并通过 natsx 发布 | TC-004 |
| AC-004 | FR-002 | Binance 原生事件映射为 canonical MarketFactEnvelope，所有必填字段正确填充 | TC-002 |
| AC-005 | FR-002 | Binance 原生字段缺失时使用 product-line 配置补全 | TC-002 |
| AC-006 | FR-002 | 同 symbol 跨 product_line 时 InstrumentKey 可区分（BTCUSDT Spot ≠ BTCUSDT USDⓈ-M） | TC-003 |
| AC-007 | FR-003 | Client 通过 `natsx.Publish(subj, json)` 发布事件，等待 JetStream PubAck（确保持久化） | TC-004 |
| AC-008 | FR-003 | Server 通过 `natsx.Subscribe(durable)` 订阅，不共享 client 进程或内存 | TC-004, TC-005 |
| AC-009 | FR-003 | Subject 格式 `binance.market.{product_line}.{event_type}`，大小写统一小写 | TC-004 |
| AC-010 | FR-003 | C/S 可在不同机器独立启动，CI gate 验证无跨进程 import | TC-005 |
| AC-011 | FR-004 | JetStream durable consumer（durable: `binance-server`）进程重启后从上次 Ack 位置恢复 | TC-006 |
| AC-012 | FR-004 | 处理成功（redisx+taosx+postgresx+kafkax handoff 全完成）后 msg.Ack() | TC-006 |
| AC-013 | FR-004 | 处理失败时 msg.NakWithDelay(5s)，MaxDeliver=5 后进入死信 | TC-006 |
| AC-014 | FR-005 | 首次消息（SetNX 成功）→ 继续写入 taosx | TC-007 |
| AC-015 | FR-005 | 重复消息（SetNX 失败）→ Ack 并跳过，不写 taosx | TC-007 |
| AC-016 | FR-005 | Redis 不可达 → error，consumer NakWithDelay | TC-008 |
| AC-017 | FR-006 | taosx WriteTick 使用 symbol+product_line 子表名，自动创建子表 | TC-009 |
| AC-018 | FR-006 | taosx WriteBatch 合并多条消息一次网络往返 | TC-009 |
| AC-019 | FR-006 | postgresx UpsertSymbol 幂等（ON CONFLICT DO UPDATE） | TC-010 |
| AC-020 | FR-006 | postgresx UpdateIngestStatus 更新 last_seq 用于 gap fill | TC-010 |
| AC-021 | FR-007 | GET /api/v1/market/ticks 从 taosx 查询，支持 symbol+time range+limit | TC-012 |
| AC-022 | FR-007 | GET /api/v1/market/depth/:symbol 从 redisx 读取最新快照 | TC-013 |
| AC-023 | FR-007 | 无效 API key → 401 | TC-014 |
| AC-024 | FR-007 | 超限（1000 req/min）→ 429 + Retry-After | TC-015 |
| AC-025 | FR-007 | GET /readyz 任一组件断连 → 503 | TC-012 |
| AC-026 | FR-008 | 每日定时查询 cutoff（now - 90d）之前的 taosx 数据 | TC-016 |
| AC-027 | FR-008 | ossx ETag 验证通过后才执行 taosx.Delete（先写冷再删热） | TC-016 |
| AC-028 | FR-008 | 归档路径格式 `binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet` | TC-017 |
| AC-029 | FR-009 | kafkax topic = `binance.market.{product_line}.{event_type}` | TC-018 |
| AC-030 | FR-009 | partition key = symbol，相同 symbol 有序到达同一 partition | TC-018 |
| AC-031 | FR-009 | Kafka 不可达时返回 error；未完成 kafkax handoff 前不 Ack，进入 retry/dead-letter/告警路径 | TC-019 |
| AC-032 | FR-010 | server 源码无 `internal/client` 或 `internal/cs` 导入（CI gate） | TC-020 |
| AC-033 | FR-010 | 任何代码 reintroduce `binance-market` 引用时 CI no-legacy gate 失败 | TC-021 |
| AC-034 | FR-010 | go.mod gin/ossx 为 direct；五个 infra 模块从 indirect 升为 direct | TC-022 |
| AC-035 | FR-009 | BOUNDARY-GATES §5（cs 包禁止）+ §6（同进程禁止）+ §11（go.mod 合规）全 PASS | TC-020 |
| AC-036 | FR-006c | redisx SET(tick:{line}:{symbol}, json, 60s) 写入最新行情缓存 | TC-023 |
| AC-037 | FR-006c | redisx 缓存写入失败 → warn 日志 + 降级（不阻塞主管线） | TC-023 |
| AC-038 | FR-007a | GET /api/v1/analytics/vwap 从 clickhousex 返回跨符号 VWAP 排名 | TC-024 |
| AC-039 | FR-007a | GET /api/v1/analytics/top-movers 返回涨幅/跌幅 top N | TC-024 |
| AC-040 | FR-007a | GET /api/v1/analytics/correlation 返回两 symbol Pearson 相关系数 | TC-024 |
| AC-041 | FR-010 | ETL scheduler 每 5 分钟从 taosx 聚合写入 clickhousex（1m_ohlcv/5m_vwap/15m_stats） | TC-025 |
| AC-042 | FR-010 | clickhousex InsertBatch 失败 → error 日志 + 告警 + 跳过本批次（下周期重试） | TC-026 |
| AC-043 | FR-010 | clickhousex 不可达 → analytics API 返回 503；实时 API 不受影响 | TC-026 |
| AC-044 | FR-010 | 启动时 market_binance 库不存在 → 自动 DDL 建库建表 | TC-025 |
| AC-045 | FR-011 | redisx SetNX("lock:binance:coordinator", instanceID, 30s) 成功 → 启动 scheduler | TC-027 |
| AC-046 | FR-011 | 锁获取失败 → standby 模式，每 5s 轮询重试，自动接管 | TC-027 |
| AC-047 | FR-011 | lease 续期失败 → 停止 ETL+归档；正常关闭 → Del 主动释放 | TC-028 |

---

## §6 覆盖率仪表盘

| 指标 | 总数 | 已覆盖 | 覆盖率 | 说明 |
|------|------|--------|--------|------|
| 功能需求 (FR) | 15 | 15 | 100% | FR-001~FR-011（含 6a/6b/6c/6d + 7a 子项，15 条独立有 AC+TC 的 FR） |
| 业务规则 (BR) | 9 | 9 | 100% | BR-001 ~ BR-009 全部有 CI Gate 或 TC |
| 非功能需求 (NFR) | 20 | 20 | 100% | NFR-001 ~ NFR-020 全部有验证方式 |
| 测试用例 (TC) | 28 | 28 | 100% | TC-001 ~ TC-028 全部有对应 FR/BR |
| 验收标准 (AC) | 47 | 47 | 100% | AC-001 ~ AC-047 全部有验证方式 |
| FR→TC 覆盖率 | — | 14/14 | 100% | — |
| BR→验证覆盖率 | — | 9/9 | 100% | — |
| AC→验证覆盖率 | — | 47/47 | 100% | — |
| 实现状态 | — | 1/15 FR | 7% | FR-009 boundary gate 已落地；其余 v2.1.0 目标代码待实现 |

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-16 | v1.0.0 | 从零创建 §1-§7 标准追溯矩阵 | ZoneCNH |
| 2026-06-17 | v1.1.0 | 修复 FR/BR/AC 错位，新增 AC-021~023 边界强制 | ZoneCNH |
| 2026-06-17 | v1.2.0 | BR-002/003 拆分；BR 总数 8→9 | ZoneCNH |
| 2026-06-17 | v1.3.0 | 同步 SPEC v1.0.1 Status 晋升 | ZoneCNH |
| 2026-06-17 | v1.4.0 | runtime 骨架落地，实现状态 0%→71% | ZoneCNH |
| 2026-06-21 | v2.0.0 | **全面重写：gRPC/spool/checkpoint/同进程 → natsx JetStream 分布式架构**：FR-003~006 替换，新增 FR-007~010；BR-004~009 对齐 ManualAck/redisx/ossx/存储所有权；NFR 删除 spool/gRPC 延迟，新增 natsx/taosx/Gin 预算；TC 扩展至 22 条；AC 扩展至 35 条；覆盖率全部 100% | ZoneCNH |
| 2026-06-21 | v2.1.0 | **七模块补全 + 追溯链扩展**：FR-006 拆分为 6a(taosx)/6b(postgresx)/6c(redisx cache)/6d(ossx)；新增 FR-010（clickhousex OLAP）、FR-011（分布式锁）、FR-007a（analytics API）；Config §11 从 14 项扩展至 100+ 项（7 模块 + Gin + Obs + 环境变量）；Error 码 BNC-009~013；Performance Budget 从 8 项扩展至 20 项；Subject 命名统一 um_perp/cm_perp；TC 22→28；AC 35→47；NFR 13→20；dashboard 全量更新 | ZoneCNH |
