# module/binance/server TRACEABILITY

> 追溯矩阵版本：v2.0.0 | 最后更新：2026-06-21 | 对应 server SPEC v1.1.0
>
> **v2.0.0 架构变更**：gRPC bidi stream + 同进程 cs 接口 → natsx JetStream 网络通信；
> server 获得 Binance 专属全栈存储（taosx + postgresx + redisx + ossx）；
> 新增 Gin REST Market API 作为 market_data 的唯一数据接口；运维 admin/health 端点迁移为 Gin server-local endpoints。

---

## §1 FR 追溯表

| FR ID | 功能需求 | AC | TC ID(s) | Task | 实现状态 |
|-------|----------|-----|----------|------|:--------:|
| FR-001 | natsx Consumer — 通过 JetStream durable consumer 从 client 接收行情事件（网络通信，禁止同进程） | AC-001 ~ AC-003 | TC-001, TC-002 | TASK-BINANCE-SERVER-010 | ⬜ Pending |
| FR-002 | Message Validation — 验证 envelope/payload/domain enum；不合法消息 Nak | AC-004 ~ AC-006 | TC-003, TC-004 | TASK-BINANCE-SERVER-002 | ⬜ Pending |
| FR-003 | redisx Idempotency — SetNX 防止 JetStream 重投导致重复写入（key TTL 24h） | AC-007 ~ AC-009 | TC-005, TC-006 | TASK-BINANCE-SERVER-011 | ⬜ Pending |
| FR-004 | taosx Persistence — 规范化事件写入 TDengine 超表，支持 WriteBatch + QueryRange | AC-010 ~ AC-012 | TC-007, TC-008 | TASK-BINANCE-SERVER-013 | ⬜ Pending |
| FR-005 | postgresx Catalog — 维护 symbol 注册、时钟偏移、采集进度三张元数据表 | AC-013 ~ AC-015 | TC-009 | TASK-BINANCE-SERVER-012 | ⬜ Pending |
| FR-006 | kafkax Dispatch — 处理成功后广播到下游 topic，symbol 为 partition key | AC-016 ~ AC-018 | TC-010, TC-011 | TASK-BINANCE-SERVER-014 | ⬜ Pending |
| FR-007 | Gin Market API — /api/v1/market/* REST 接口，作为 market_data 唯一数据接口 | AC-019 ~ AC-024 | TC-012 ~ TC-015 | TASK-BINANCE-SERVER-015 | ⬜ Pending |
| FR-008 | ossx Archival — 每日定时将 taosx 中超 RetentionDays 数据归档到对象存储 | AC-025 ~ AC-027 | TC-016, TC-017 | TASK-BINANCE-SERVER-016 | ⬜ Pending |
| FR-009 | Boundary Enforcement — CI gate 阻断 server 导入 client/cs 包；go.mod 合规检查 | AC-028 ~ AC-030 | TC-018, TC-019 | TASK-BINANCE-SERVER-008 | ⬜ Pending |

---

## §2 BR 追溯表

| BR ID | 业务规则 | 验证方式 | Task | 实现状态 |
|-------|----------|----------|------|:--------:|
| BR-001 | natsx ManualAck — 全链路写入（redisx+taosx+postgresx+kafkax handoff）成功后才 Ack，失败时 NakWithDelay | TC-002: 处理失败→NakWithDelay 集成测试 | TASK-BINANCE-SERVER-010 | ⬜ |
| BR-002 | Idempotency At Most Once — 相同 (product_line, exchange_time, event_type, symbol) 最多写入 taosx 一次 | TC-005, TC-006: SetNX 原子性集成测试 | TASK-BINANCE-SERVER-011 | ⬜ |
| BR-003 | Cold-Write-First — ossx 上传确认（ETag）后才从 taosx 删除归档段数据，禁止先删后写 | TC-016: 上传失败→taosx 未删除验证 | TASK-BINANCE-SERVER-016 | ⬜ |
| BR-004 | Server Owns Storage — server 独占 taosx/postgresx/redisx/ossx（Binance 专属），market_data 禁止直连 | CI Gate: BOUNDARY-GATES.md §7 | TASK-BINANCE-SERVER-008 | ⬜ |
| BR-005 | No cs Package — 禁止导入 `internal/cs`；禁止与 client 同进程运行 | CI Gate: BOUNDARY-GATES.md §5, §6 | TASK-BINANCE-SERVER-008 | ⬜ |
| BR-006 | Server Must Not Import Client Internals | CI gate: grep internal/client 零匹配 | TASK-BINANCE-SERVER-008 | ⬜ |

---

## §3 NFR 追溯表

| NFR ID | 非功能需求 | 来源(SPEC §) | 验证方式 |
|--------|-----------|-------------|----------|
| NFR-S01 | natsx consumer 消息处理延迟（receive→Ack）P99 < 50ms | 性能预算 | integration test: JetStream latency |
| NFR-S02 | redisx SetNX 幂等检查延迟 P99 < 1ms | 性能预算 | `go test -bench BenchmarkIdempotencyCheck` |
| NFR-S03 | taosx WriteBatch 吞吐量 ≥ 10万 TPS（批量参数绑定） | 性能预算 | `go test -bench BenchmarkWriteBatch` |
| NFR-S04 | Gin API /api/v1/market/ticks 响应延迟 P99 < 20ms（redisx cache 命中） | 性能预算 | httptest benchmark |
| NFR-S05 | Gin API /api/v1/market/depth P99 < 1ms（redisx 直接命中） | 性能预算 | httptest benchmark |
| NFR-S06 | Metrics: consumer lag / idempotency hits / taosx write TPS / kafkax dispatch errors / API p99 latency | Observability | metrics endpoint |
| NFR-S07 | Logs 含 subject / symbol / product_line / idempotency_hash | Observability | log inspection |
| NFR-S08 | API key 不出现于 log / debug 端点输出 | Security | gitleaks + secret redaction test |
| NFR-S09 | Admin auth when exposed outside loopback-only | Security | auth test |
| NFR-S10 | ossx 归档完整性：ETag 验证通过后才执行 taosx 删除 | 数据完整性 | TC-016 |

---

## §4 TC→FR 反向追溯

| TC ID | 覆盖 FR(s) | 覆盖 BR(s) | 测试类型 | 状态 |
|-------|-----------|------------|----------|:----:|
| TC-001 | FR-001 | — | 单元（mock JetStream） | ⬜ |
| TC-002 | FR-001 | BR-001 | 集成（处理失败→NakWithDelay） | ⬜ |
| TC-003 | FR-002 | — | 单元（缺字段→Nak） | ⬜ |
| TC-004 | FR-002 | — | 单元（非法 product_line→Nak） | ⬜ |
| TC-005 | FR-003 | BR-002 | 单元（首次 SetNX→false） | ⬜ |
| TC-006 | FR-003 | BR-002 | 单元（重复 SetNX→true，跳过写入） | ⬜ |
| TC-007 | FR-004 | — | 单元（mock taosx WriteTick） | ⬜ |
| TC-008 | FR-004 | — | 集成（WriteBatch 吞吐 benchmark） | ⬜ |
| TC-009 | FR-005 | — | 单元（UpsertSymbol 幂等；ClockOffset 记录） | ⬜ |
| TC-010 | FR-006 | — | 单元（topic 名称 + partition key） | ⬜ |
| TC-011 | FR-006 | — | 单元（Kafka 不可达→error） | ⬜ |
| TC-012 | FR-007 | — | httptest（/api/v1/market/ticks 返回 taosx 数据） | ⬜ |
| TC-013 | FR-007 | — | httptest（/api/v1/market/depth 读 redisx） | ⬜ |
| TC-014 | FR-007 | — | httptest（无效 API key → 401） | ⬜ |
| TC-015 | FR-007 | — | httptest（超限 → 429） | ⬜ |
| TC-016 | FR-008 | BR-003 | 单元（PutObject 失败→taosx 未删除） | ⬜ |
| TC-017 | FR-008 | BR-003 | 单元（路径格式验证） | ⬜ |
| TC-018 | FR-009 | BR-005, BR-006 | CI gate（cs 包/client 包 import 检查） | ⬜ |
| TC-019 | FR-009 | BR-004 | CI gate（go.mod 合规检查） | ⬜ |

---

## §5 AC 注册表

| AC ID | 所属 FR | AC 描述 | 验证方式 |
|-------|---------|---------|----------|
| AC-001 | FR-001 | durable consumer 绑定名称 `binance-server`，进程重启后从上次 Ack 位置继续消费 | TC-001: mock 验证 Subscribe 使用 Durable option |
| AC-002 | FR-001 | ManualAck — Handle 成功后 Ack；Handle 失败后 NakWithDelay(5s) | TC-002: mock handler 失败→验证 NakWithDelay |
| AC-003 | FR-001 | consumer 不持有任何 client 接口，不导入 `internal/client` 或 `internal/cs` | TC-018: CI gate grep 零匹配 |
| AC-004 | FR-002 | envelope 缺必填字段（symbol/exchange_time/product_line）→ Nak（解析失败不重投） | TC-003: 构造不完整 JSON → 验证 Nak |
| AC-005 | FR-002 | 不支持的 product_line 值 → Nak | TC-004: 非法 product_line → Nak |
| AC-006 | FR-002 | 合法 envelope 通过验证，进入处理管线 | TC-003 负向验证反向确认 |
| AC-007 | FR-003 | 首次消息：SetNX 返回 true → 继续处理（非重复） | TC-005: mock SetNX 返回 true |
| AC-008 | FR-003 | 重复消息（相同 hash key 已存在）：SetNX 返回 false → Ack 并跳过，不写 taosx | TC-006: mock SetNX 返回 false → taosx.Write 未调用 |
| AC-009 | FR-003 | Redis 不可达时 → 返回 error，consumer NakWithDelay | TC-005: mock SetNX 返回 err → NakWithDelay |
| AC-010 | FR-004 | WriteTick 使用 symbol+product_line 生成子表名，自动创建子表 | TC-007: mock 验证 WriteWithAutoCreate 参数 |
| AC-011 | FR-004 | WriteBatch 合并多条消息为一次网络往返（非循环 WriteTick） | TC-008: benchmark mock 验证 WriteBatch 被调用 |
| AC-012 | FR-004 | taosx 不可达时 → error，consumer NakWithDelay | TC-007: mock 注入 error |
| AC-013 | FR-005 | UpsertSymbol ON CONFLICT DO UPDATE，幂等插入 | TC-009: 同 symbol 插入两次不报错 |
| AC-014 | FR-005 | RecordClockOffset 每分钟采样写入 binance_clock_offsets 表 | TC-009: mock 验证 INSERT 被调用 |
| AC-015 | FR-005 | UpdateIngestStatus 更新 last_seq，用于 gap fill 检测 | TC-009: mock 验证 seq 参数 |
| AC-016 | FR-006 | topic = `binance.market.{product_line}.{event_type}`，与 natsx subject 一致 | TC-010: mock 验证 topic 字符串 |
| AC-017 | FR-006 | partition key = `[]byte(symbol)`，相同 symbol 有序到达同一 partition | TC-010: mock 验证 Key 参数 |
| AC-018 | FR-006 | Kafka 不可达时 → error；未完成 kafkax handoff 前不 Ack，进入 retry/dead-letter/告警路径 | TC-011: mock 返回 error → observex 告警 |
| AC-019 | FR-007 | GET /api/v1/market/ticks 从 taosx 查询，支持 symbol + time range + limit | TC-012: httptest + mock taosx |
| AC-020 | FR-007 | GET /api/v1/market/depth/:symbol 从 redisx 读取最新深度快照，P99 < 1ms | TC-013: mock redisx 验证 key 格式 |
| AC-021 | FR-007 | 无效 API key → 401 | TC-014: httptest 验证状态码 |
| AC-022 | FR-007 | 超限（>1000 req/min per key）→ 429 + Retry-After header | TC-015: mock 令牌桶耗尽 |
| AC-023 | FR-007 | GET /readyz 三组件（taosx/redisx/postgresx）任一断连 → 503 | TC-012: mock taosx 断连 → 503 |
| AC-024 | FR-007 | 所有响应统一 JSON，错误使用 `{"error":"...","code":"..."}` 结构 | TC-012~015: 验证响应体格式 |
| AC-025 | FR-008 | 每日定时归档 cutoff（now - RetentionDays）之前的 taosx 数据 | TC-017: 验证 taosx 查询参数含 cutoff |
| AC-026 | FR-008 | 先 ossx.PutObject + 验证 ETag，成功后才 taosx.Delete（先写冷再删热） | TC-016: mock PutObject 失败→Delete 未调用 |
| AC-027 | FR-008 | 归档路径 `binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet` | TC-017: 验证 key 字符串格式 |
| AC-028 | FR-009 | server 源码无 `internal/client` 或 `internal/cs` 导入 | TC-018: CI gate grep 零匹配 |
| AC-029 | FR-009 | go.mod 中 gin / ossx 为 direct 依赖；redisx/kafkax/natsx/postgresx/taosx 为 direct 依赖 | TC-019: go mod 检查 |
| AC-030 | FR-009 | BOUNDARY-GATES §5（cs 包禁止）+ §6（同进程禁止）CI gate 全 PASS | TC-018: 本地 PASS |

---

## §6 覆盖率仪表盘

| 指标 | 计数 | 覆盖率 |
|------|:----:|:------:|
| 总 FR | 9 | — |
| 总 BR | 6 | — |
| 总 NFR | 10 | — |
| 总 TC | 19 | — |
| 总 AC | 30 | — |
| FR→TC 映射率 | 9 / 9 | 100% |
| BR→验证映射率 | 6 / 6 | 100% |
| TC→FR 回溯率 | 19 / 19 | 100% |
| AC→验证映射率 | 30 / 30 | 100% |
| 实现完成率 | 0 / 9 FR | 0%（文档对齐 v2.0.0，代码待实现） |

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-16 | v1.0.0 | 初始版本：§1-§7 标准追溯矩阵，基于 server SPEC.md v1.0.0 生成 | ZoneCNH |
| 2026-06-17 | v1.1.0 | R7 AC 命名空间统一：AC-S01~AC-S18 → AC-001~AC-018 | ZoneCNH |
| 2026-06-17 | v1.1.1 | 同步 server SPEC v1.0.1 修订（metadata 字段统一） | ZoneCNH |
| 2026-06-17 | v1.1.2 | 同步 SPEC v1.0.2 Status 晋升（Review → Approved） | ZoneCNH |
| 2026-06-21 | v2.0.0 | **全面重写：gRPC/同进程 cs → natsx JetStream 分布式架构**：FR-001~009 全部对齐 natsx(010)/redisx(011)/postgresx(012)/taosx(013)/kafkax(014)/Gin(015)/ossx(016)；BR-001~006 对齐 ManualAck/幂等/冷写/存储所有权；NFR 新增 consumer lag / WriteBatch TPS / API p99；TC-001~019 + AC-001~030 全面更新；归档旧 gRPC FR-001~008 描述 | ZoneCNH |
