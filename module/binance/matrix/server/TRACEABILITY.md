# module/binance/server TRACEABILITY

> 追溯矩阵 §1–§7，符合 `../../../../docs/governance/TRACEABILITY.md` 标准格式。
> 数据来源：`module/binance/spec/server/SPEC.md` v3.9.8（FR/BR 使用 root canonical 编号）。
> **SC 编号说明**：本文件的 SC-001~SC-026 为子模块本地场景 ID（Scenario），不与 root TRACEABILITY 的 canonical TC-001~TC-083 冲突。正式 TC 编号以 `module/binance/matrix/TRACEABILITY.md` §4 为准。

- Module-Version: v3.9.8（FR/BR 编号统一为 root canonical；与 root SPEC v3.9.8 一致）
- Last-Updated: 2026-07-04（全局 single state 为 48 Done / 0 Partial / 0 Drifted / 0 Pending，release_closeable=NO）
- Spec-Reference: `module/binance/spec/server/SPEC.md` v3.9.8

> **v2.1.1 变更摘要**：元数据对齐 server SPEC v2.1.0；保留 v2.1.0 的 FR/TC/AC 追溯结构；
> SC-020/021 覆盖；FR-002→FR-005 编号修正（v2.0.0 漏收 Consumer Lifecycle 导致整体偏移）；
> 新增 FR-007a（clickhousex Analytics API）、FR-010（clickhousex OLAP Storage）、FR-011
> （Distributed Coordinator Lock）及对应 TC/AC；BR 表对齐 SPEC BR-001~BR-006 + 补充
> Cold-Write-First（BR-007）、Server Owns Binance Storage（BR-008）、No cs Package（BR-009）。

> **v2.2.0 变更摘要**：server/SPEC §7 新增 FR-025~FR-028（Backfill Throttle/Reconciliation/Rehydration/Progress API）；Module-Version 对齐 server/SPEC v2.2.0。

---

## §1 FR 追溯表

| FR ID | 功能需求 | AC | SC ID(s) | Task | 实现状态 |
|-------|----------|-----|----------|------|:--------:|
| FR-001 | natsx Consumer Binding — durable consumer `binance-server`，禁止同进程调用 | AC-001 ~ AC-003 | SC-001, SC-002 | TASK-BINANCE-SERVER-010 | ✅ Done |
| FR-002 | Consumer Lifecycle — 优雅关闭（SIGTERM 完成 in-flight Ack）、ack_wait 超时重投、进程重启自动恢复 | AC-031 ~ AC-032 | SC-020, SC-021 | TASK-BINANCE-SERVER-010 | ✅ Done |
| FR-003 | Envelope Validation — 校验 product_line / instrument_key / event_type / event_time / idempotency_key 全部有效；非法消息 ManualNak | AC-004 ~ AC-006 | SC-003, SC-004 | TASK-BINANCE-SERVER-002 | ✅ Done |
| FR-004 | Idempotent Acceptance — redisx SetNX 防止 JetStream 重投导致重复写入（key TTL 72h） | AC-007 ~ AC-009 | SC-005, SC-006 | TASK-BINANCE-SERVER-011 | ✅ Done |
| FR-005 | Multi-Store Write — taosx WriteBatch（时序）+ postgresx Upsert（元数据）+ redisx SET（热缓存）并行写入；全部成功才进入 kafkax dispatch | AC-010 ~ AC-015 | SC-007, SC-008, SC-009 | TASK-BINANCE-SERVER-013, TASK-BINANCE-SERVER-012 | ✅ Done |
| FR-006 | kafkax Dispatch — 处理成功后广播到下游 topic，symbol 为 partition key | AC-016 ~ AC-018 | SC-010, SC-011 | TASK-BINANCE-SERVER-014 | ✅ Done |
| FR-007 | Gin Market API — /api/v1/market/* REST 接口，作为 market_data 唯一数据接口 | AC-019 ~ AC-024 | SC-012 ~ SC-015 | TASK-BINANCE-SERVER-015 | ✅ Done |
| FR-007a | clickhousex Analytics API — /api/v1/analytics/vwap/top-movers/correlation OLAP 查询 | AC-033 ~ AC-035 | SC-022 | TASK-BINANCE-SERVER-015 | ✅ Done |
| FR-008 | ossx Archival — 每日定时将 taosx 中超 RetentionDays 数据归档到对象存储；ETag 确认后删热数据 | AC-025 ~ AC-027 | SC-016, SC-017 | TASK-BINANCE-SERVER-016 | ✅ Done |
| FR-009 | Boundary Enforcement — CI gate 阻断 server 导入 client/cs 包；go.mod 合规检查（含 clickhousex） | AC-028 ~ AC-030 | SC-018, SC-019 | TASK-BINANCE-SERVER-008 | ✅ Done |
| FR-010 | clickhousex OLAP Storage — 每 5 分钟 ETL 聚合 taosx→clickhousex，为 analytics API 提供 OLAP 查询 | AC-036 ~ AC-038 | SC-023, SC-024 | TASK-BINANCE-SERVER-017 | ✅ Done |
| FR-011 | Distributed Coordinator Lock — redisx SetNX 分布式锁，HA 场景下确保 coordinator 单点执行 | AC-039 ~ AC-040 | SC-025, SC-026 | TASK-BINANCE-SERVER-013 | ✅ Done |

---

## §2 BR 追溯表

| BR ID | 业务规则 | 来源（SPEC §8） | 验证方式 | Task | 实现状态 |
|-------|----------|----------------|----------|------|:--------:|
| BR-001 | ManualAck 全链路写入后才 Ack — redisx SetNX + taosx + postgresx + kafkax handoff 全成功后才调用 msg.Ack() | BR-001 | SC-002: 处理失败→NakWithDelay 集成测试 | TASK-BINANCE-SERVER-010 | ✅ Done |
| BR-002 | redisx SetNX 幂等唯一性 — 相同 idempotency key 最多写入 taosx 一次（at-most-once storage）| BR-002 | SC-005, SC-006: SetNX 原子性集成测试 | TASK-BINANCE-SERVER-011 | ✅ Done |
| BR-003 | ManualAck Only After Durable Processing — validation + idempotency + durable storage + kafkax handoff 全完成才 Ack；失败路径使用 Nak/retry/dead-letter | BR-003 | SC-002: 写入失败→未 Ack 验证；SC-011: kafkax 失败→未 Ack | TASK-BINANCE-SERVER-010 | ✅ Done |
| BR-004 | Validation Failure → Terminal Reject — terminal_validation 失败不进入幂等/存储/fanout 管线 | BR-004 | SC-003, SC-004: 非法消息 Nak 且无下游调用 | TASK-BINANCE-SERVER-002 | ✅ Done |
| BR-005 | Admin Surface Isolation — admin 端点只能变更 server-local 状态；禁止修改 client connector、绕过 idempotency、暴露 secrets | BR-005 | admin endpoint auth test | TASK-BINANCE-SERVER-006 | ✅ Done |
| BR-006 | Server Must Not Import Client Internals — 禁止 import `module/binance/client`、`internal/cs`、gRPC ingest runtime | BR-006 | SC-018: CI gate grep 零匹配 | TASK-BINANCE-SERVER-008 | ✅ Done |
| BR-007 | Cold-Write-First — ossx ETag 验证通过后才从 taosx 删除归档段数据，禁止先删后写 | FR-008 约束 | SC-016: PutObject 失败→taosx 未删除验证 | TASK-BINANCE-SERVER-016 | ✅ Done |
| BR-008 | Server Owns Binance Storage — server 独占 taosx/postgresx/redisx/clickhousex/ossx（Binance 专属），market_data 禁止直连 | FR-005/FR-010 约束 | CI Gate: BOUNDARY-GATES.md §7 | TASK-BINANCE-SERVER-008 | ✅ Done |
| BR-009 | No cs Package — 禁止导入 `internal/cs`；禁止 client 与 server 同进程运行 | FR-009 约束 | CI Gate: BOUNDARY-GATES.md §5, §6 | TASK-BINANCE-SERVER-008 | ✅ Done |

---

## §3 NFR 追溯表

| NFR ID | 非功能需求 | 来源(SPEC §) | 验证方式 |
|--------|-----------|-------------|----------|
| NFR-S01 | natsx consumer 消息处理延迟（receive→Ack）P99 < 50ms | 性能预算 | integration test: JetStream latency |
| NFR-S02 | redisx SetNX 幂等检查延迟 P99 < 1ms | 性能预算 | `go test -bench BenchmarkIdempotencyCheck` |
| NFR-S03 | taosx WriteBatch 吞吐量 ≥ 10万 TPS（批量参数绑定） | 性能预算 | `go test -bench BenchmarkWriteBatch` |
| NFR-S04 | Gin API /api/v1/market/ticks 响应延迟 P99 < 20ms（redisx cache 命中） | 性能预算 | httptest benchmark |
| NFR-S05 | Gin API /api/v1/market/depth P99 < 1ms（redisx 直接命中） | 性能预算 | httptest benchmark |
| NFR-S06 | clickhousex InsertBatch (50000 rows) P99 < 500ms | 性能预算 | integration test |
| NFR-S07 | Gin API /api/v1/analytics/* P99 < 2s（clickhousex OLAP） | 性能预算 | httptest benchmark |
| NFR-S08 | Metrics: consumer lag / idempotency hits / taosx write TPS / kafkax dispatch errors / API p99 latency | Observability | metrics endpoint |
| NFR-S09 | Logs 含 subject / symbol / product_line / idempotency_hash | Observability | log inspection |
| NFR-S10 | API key 不出现于 log / debug 端点输出 | Security | gitleaks + secret redaction test |
| NFR-S11 | Admin auth when exposed outside loopback-only | Security | auth test |
| NFR-S12 | ossx 归档完整性：ETag 验证通过后才执行 taosx 删除 | 数据完整性 | SC-016 |

---

## §4 SC→FR 反向追溯

| SC ID | 覆盖 FR(s) | 覆盖 BR(s) | 测试类型 | 场景摘要 | 状态 |
|-------|-----------|------------|:--------:|---------|:----:|
| SC-001 | FR-001 | — | 单元（mock JetStream） | durable consumer 订阅 binance.market.> | ✅ Done |
| SC-002 | FR-001, FR-002 | BR-001, BR-003 | 集成（处理失败→NakWithDelay） | handler 报错→NakWithDelay；未 Ack | ✅ Done |
| SC-003 | FR-003 | BR-004 | 单元（缺字段→Nak） | 缺 symbol/exchange_time→ManualNak；无下游调用 | ✅ Done |
| SC-004 | FR-003 | BR-004 | 单元（非法 product_line→Nak） | 非法枚举→ManualNak；无存储调用 | ✅ Done |
| SC-005 | FR-004 | BR-002 | 单元（首次 SetNX→false） | SetNX 返回 true → 进入存储管线 | ✅ Done |
| SC-006 | FR-004 | BR-002 | 单元（重复 SetNX→true，跳过写入） | SetNX 返回 false → Ack 并跳过，taosx.Write 未调用 | ✅ Done |
| SC-007 | FR-005 | — | 单元（mock taosx WriteTick） | WriteTick 参数：symbol+product_line 子表名 | ✅ Done |
| SC-008 | FR-005 | — | 集成（WriteBatch 吞吐 benchmark） | WriteBatch 合并多条，非循环 WriteTick | ✅ Done |
| SC-009 | FR-005 | — | 单元（postgresx UpsertSymbol 幂等；ClockOffset 记录） | ON CONFLICT DO UPDATE，同 symbol 两次不报错 | ✅ Done |
| SC-010 | FR-006 | — | 单元（topic 名称 + partition key） | topic=binance.{line}.{type}.v1；key=symbol | ✅ Done |
| SC-011 | FR-006 | BR-003 | 单元（Kafka 不可达→error，未 Ack） | kafkax.Send 失败→NakWithDelay；Ack 未发送 | ✅ Done |
| SC-012 | FR-007 | — | httptest（/api/v1/market/ticks 返回 taosx 数据） | 返回正确 JSON，status 200 | ✅ Done |
| SC-013 | FR-007 | — | httptest（/api/v1/market/depth 读 redisx） | redisx 命中，P99 < 1ms | ✅ Done |
| SC-014 | FR-007 | — | httptest（无效 API key → 401） | Authorization 无效→401 | ✅ Done |
| SC-015 | FR-007 | — | httptest（超限 → 429） | 令牌桶耗尽→429 + Retry-After | ✅ Done |
| SC-016 | FR-008 | BR-007 | 单元（PutObject 失败→taosx 未删除） | ossx.PutObject 报错→taosx.Delete 未调用 | ✅ Done |
| SC-017 | FR-008 | BR-007 | 单元（路径格式验证） | key=binance/{line}/{symbol}/{YYYY}/{MM}/{DD}/{type}.parquet | ✅ Done |
| SC-018 | FR-009 | BR-006, BR-009 | CI gate（cs 包/client 包 import 检查） | grep internal/client\|internal/cs 零匹配 | ✅ Done |
| SC-019 | FR-009 | BR-008 | CI gate（go.mod 合规检查） | gin/ossx/natsx/redisx/taosx/postgresx/kafkax/clickhousex 均为 direct | ✅ Done |
| SC-020 | FR-002 | — | 单元（SIGTERM 优雅关闭） | consumer 收 SIGTERM，完成当前 Ack 后关闭，不丢弃 in-flight 消息 | ✅ Done |
| SC-021 | FR-002 | — | 单元（ack_wait 超时重投） | 处理超 ack_wait 未 Ack → JetStream 重投；redisx SetNX 幂等过滤 | ✅ Done |
| SC-022 | FR-007a | — | httptest（/api/v1/analytics/vwap + top-movers + correlation） | clickhousex mock 返回聚合结果；clickhousex 不可达→503 | ✅ Done |
| SC-023 | FR-010 | BR-008 | 集成（clickhousex ETL：taosx Query → 聚合 → InsertBatch） | 5 分钟 ETL 周期，InsertBatch 写入 1m_ohlcv / 5m_vwap | ✅ Done |
| SC-024 | FR-010 | — | 单元（clickhousex 不可达→ETL 跳过，实时 API 不受影响） | InsertBatch 报错→warn+跳过；ticks API 正常返回 | ✅ Done |
| SC-025 | FR-011 | — | 单元（redisx SetNX 获取锁 → 启动 ETL scheduler） | SetNX 返回 true → scheduler.Start 被调用 | ✅ Done |
| SC-026 | FR-011 | — | 单元（lease 续期失败 → 停止任务；正常关闭 → Del 主动释放） | Expire 报错→停止 ETL；Shutdown→Del 被调用 | ✅ Done |

---

## §5 AC 注册表

### FR-001: natsx Consumer Binding

| AC ID | AC 描述 | 验证方式 |
|-------|---------|----------|
| AC-001 | durable consumer 绑定名称 `binance-server`，进程重启后从上次 Ack 位置继续消费 | SC-001: mock 验证 Subscribe 使用 Durable option |
| AC-002 | ManualAck — Handle 成功后 Ack；Handle 失败后 NakWithDelay(5s) | SC-002: mock handler 失败→验证 NakWithDelay |
| AC-003 | consumer 不持有任何 client 接口，不导入 `internal/client` 或 `internal/cs` | SC-018: CI gate grep 零匹配 |

### FR-002: Consumer Lifecycle

| AC ID | AC 描述 | 验证方式 |
|-------|---------|----------|
| AC-031 | server 收到 SIGTERM 时，完成当前处理中消息的 Ack 后才关闭 consumer，不丢弃 in-flight 消息 | SC-020: 注入 SIGTERM → 验证 consumer 等待 Ack 后关闭 |
| AC-032 | consumer 处理超过 `ack_wait` 仍未 Ack → JetStream 自动重投；redisx SetNX 幂等过滤重复 | SC-021: mock ack_wait 超时 → 验证重投 + SetNX 幂等过滤 |

### FR-003: Envelope Validation

| AC ID | AC 描述 | 验证方式 |
|-------|---------|----------|
| AC-004 | envelope 缺必填字段（symbol / exchange_time / product_line）→ ManualNak（解析失败不重投） | SC-003: 构造不完整 JSON → 验证 Nak，无下游调用 |
| AC-005 | 不支持的 product_line 值 → ManualNak | SC-004: 非法 product_line → Nak |
| AC-006 | 合法 envelope 通过验证，进入幂等检查管线 | SC-003 负向验证反向确认 |

### FR-004: Idempotent Acceptance

| AC ID | AC 描述 | 验证方式 |
|-------|---------|----------|
| AC-007 | 首次消息：redisx SetNX 返回 true → 继续处理（非重复） | SC-005: mock SetNX 返回 true |
| AC-008 | 重复消息（相同 hash key 已存在）：SetNX 返回 false → Ack 并跳过，不写 taosx | SC-006: mock SetNX 返回 false → taosx.Write 未调用 |
| AC-009 | Redis 不可达时 → 返回 error，consumer NakWithDelay | SC-005: mock SetNX 返回 err → NakWithDelay |

### FR-005: Multi-Store Write

| AC ID | AC 描述 | 验证方式 |
|-------|---------|----------|
| AC-010 | taosx.WriteTick 使用 symbol+product_line 生成子表名，自动创建子表 | SC-007: mock 验证 WriteWithAutoCreate 参数 |
| AC-011 | taosx.WriteBatch 合并多条消息为一次网络往返（非循环 WriteTick） | SC-008: benchmark mock 验证 WriteBatch 被调用 |
| AC-012 | taosx 不可达时 → error，consumer NakWithDelay | SC-007: mock 注入 error |
| AC-013 | postgresx.UpsertSymbol ON CONFLICT DO UPDATE，幂等插入 | SC-009: 同 symbol 插入两次不报错 |
| AC-014 | postgresx.RecordClockOffset 每分钟采样写入 binance_clock_offsets 表 | SC-009: mock 验证 INSERT 被调用 |
| AC-015 | postgresx.UpdateIngestStatus 更新 last_seq，用于 gap fill 检测 | SC-009: mock 验证 seq 参数 |

### FR-006: kafkax Dispatch

| AC ID | AC 描述 | 验证方式 |
|-------|---------|----------|
| AC-016 | Kafka topic = `binance.{product_line}.{event_type}.v1`，与 natsx subject 明确分离 | SC-010: mock 验证 topic 字符串 |
| AC-017 | partition key = `[]byte(symbol)`，相同 symbol 有序到达同一 partition | SC-010: mock 验证 Key 参数 |
| AC-018 | Kafka 不可达时 → error；未完成 kafkax handoff 前不 Ack，进入 retry/dead-letter/告警路径 | SC-011: mock 返回 error → Ack 未发送 + observex 告警 |

### FR-007: Gin Market API

| AC ID | AC 描述 | 验证方式 |
|-------|---------|----------|
| AC-019 | GET /api/v1/market/ticks 从 taosx 查询，支持 symbol + time range + limit | SC-012: httptest + mock taosx |
| AC-020 | GET /api/v1/market/depth/:symbol 从 redisx 读取最新深度快照，P99 < 1ms | SC-013: mock redisx 验证 key 格式 |
| AC-021 | 无效 API key → 401 | SC-014: httptest 验证状态码 |
| AC-022 | 超限（>1000 req/min per key）→ 429 + Retry-After header | SC-015: mock 令牌桶耗尽 |
| AC-023 | GET /readyz 三组件（taosx / redisx / postgresx）任一断连 → 503 | SC-012: mock taosx 断连 → 503 |
| AC-024 | 所有响应统一 JSON，错误使用 `{"error":"...","code":"..."}` 结构 | SC-012~015: 验证响应体格式 |

### FR-007a: clickhousex Analytics API

| AC ID | AC 描述 | 验证方式 |
|-------|---------|----------|
| AC-033 | GET /api/v1/analytics/vwap 从 clickhousex 返回跨符号 VWAP 排名 | SC-022: mock clickhousex 返回聚合结果 |
| AC-034 | GET /api/v1/analytics/top-movers 返回涨幅/跌幅 top N | SC-022: 同上 |
| AC-035 | clickhousex 不可达时 analytics API 返回 503；实时 API（ticks/bars/depth）不受影响 | SC-022: mock clickhousex error → 503；ticks 正常 |

### FR-008: ossx Archival

| AC ID | AC 描述 | 验证方式 |
|-------|---------|----------|
| AC-025 | 每日定时归档 cutoff（now - RetentionDays）之前的 taosx 数据 | SC-017: 验证 taosx 查询参数含 cutoff |
| AC-026 | 先 ossx.PutObject + 验证 ETag，成功后才 taosx.Delete（先写冷再删热） | SC-016: mock PutObject 失败→Delete 未调用 |
| AC-027 | 归档路径 `binance/{product_line}/{symbol}/{YYYY}/{MM}/{DD}/{event_type}.parquet` | SC-017: 验证 key 字符串格式 |

### FR-009: Boundary Enforcement

| AC ID | AC 描述 | 验证方式 |
|-------|---------|----------|
| AC-028 | server 源码无 `internal/client` 或 `internal/cs` 导入 | SC-018: CI gate grep 零匹配 |
| AC-029 | go.mod 中 gin / ossx / clickhousex 为 direct 依赖；redisx/kafkax/natsx/postgresx/taosx 为 direct 依赖 | SC-019: go mod 检查 |
| AC-030 | BOUNDARY-GATES §5（cs 包禁止）+ §6（同进程禁止）CI gate 全 PASS | SC-018: 本地 PASS |

### FR-010: clickhousex OLAP Storage

| AC ID | AC 描述 | 验证方式 |
|-------|---------|----------|
| AC-036 | ETL scheduler 每 5 分钟从 taosx 聚合写入 clickhousex（1m_ohlcv / 5m_vwap / 15m_stats） | SC-023: mock taosx 查询 + InsertBatch 调用验证 |
| AC-037 | clickhousex InsertBatch 失败 → error 日志 + 告警 + 跳过本批次（下周期重试） | SC-024: InsertBatch 报错→ warn + 实时 API 正常 |
| AC-038 | 启动时 market_binance 库不存在 → 自动 DDL 建库建表 | SC-023: mock DDL 执行验证 |

### FR-011: Distributed Coordinator Lock

| AC ID | AC 描述 | 验证方式 |
|-------|---------|----------|
| AC-039 | redisx SetNX("lock:binance:coordinator", instanceID, 30s) 成功 → 启动 ETL + 归档 scheduler | SC-025: mock SetNX true → scheduler.Start 被调用 |
| AC-040 | lease 续期失败 → 停止 ETL + 归档；正常关闭 → Del 主动释放锁 | SC-026: mock Expire 失败→Stop；Shutdown→Del 被调用 |

---

## §6 覆盖率仪表盘

| 指标 | 计数 | 覆盖率 |
|------|:----:|:------:|
| 总 FR（含子项 FR-007a） | 12 | — |
| 总 BR | 9 | — |
| 总 NFR | 12 | — |
| 总 SC | 26 | — |
| 总 AC | 40 | — |
| FR→SC 映射率 | 12 / 12 | 100% |
| BR→验证映射率 | 9 / 9 | 100% |
| SC→FR 回溯率 | 26 / 26 | 100% |
| AC→验证映射率 | 40 / 40 | 100% |
| 实现完成率 | 12 Done / 0 Partial / 12 FR | 100% Done（全局发布以 root single state `48 Done / 0 Partial / 0 Drifted / 0 Pending` 与 release_closeable=NO 为准） |

	> **v2.2.2 状态同步更正 (2026-07-04)**：2026-06-28 full E2E 包仅作为历史运行证据，不构成发布关闭结论。当前采用 single state；root 当前为 `48 Done / 0 Partial / 0 Drifted / 0 Pending`，release_closeable=NO（PRG-006=Partial，PRG-007=Partial）。

---

## §7 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-16 | v1.0.0 | 初始版本：§1-§7 标准追溯矩阵，基于 server SPEC.md v1.0.0 生成 | ZoneCNH |
| 2026-06-17 | v1.1.0 | AC 命名空间统一：AC-S01~AC-S18 → AC-001~AC-018 | ZoneCNH |
| 2026-06-17 | v1.1.1 | 同步 server SPEC v1.0.1 修订（metadata 字段统一） | ZoneCNH |
| 2026-06-17 | v1.1.2 | 同步 SPEC v1.0.2 Status 晋升（Review → Approved） | ZoneCNH |
| 2026-06-21 | v2.0.0 | **全面重写**：gRPC/同进程 cs → natsx JetStream 分布式架构；FR-001~009 全部对齐 natsx/redisx/postgresx/taosx/kafkax/Gin/ossx；BR/NFR/TC/AC 全面更新 | ZoneCNH |
| 2026-06-21 | v2.1.0 | **对齐当时的 server SPEC 基线**：补充 FR-002 Consumer Lifecycle（SC-020/021, AC-031/032）；FR 命名全面对齐 SPEC（FR-002→FR-003 Envelope Validation, FR-003→FR-004 Idempotent Acceptance, FR-004+005→FR-005 Multi-Store Write）；新增 FR-007a（clickhousex Analytics API, SC-022, AC-033~035）、FR-010（clickhousex OLAP, SC-023/024, AC-036~038）、FR-011（Coordinator Lock, SC-025/026, AC-039~040）；BR 从 6 条扩展至 9 条（对齐 SPEC BR-001~006 + Cold-Write-First/Server Owns Storage/No cs Package）；NFR 10→12；TC 19→26；AC 30→40 | ZoneCNH |
| 2026-06-22 | v2.1.1 | 修正追溯矩阵元数据：对应 server SPEC v2.1.0；实现状态仍保持 Pending，代码待实现 | ZoneCNH |
| 2026-06-26 | v2.2.1 | **P0 状态同步**：FR/BR 实现状态从全 Pending 同步为 9 Done / 3 Partial（Partial: FR-007/007a/011），对齐 root TRACEABILITY v3.9.0 Runtime-Anchor `/home/workspace/binance@0602e78428633a368b0afcd1c578c07ed7144752`；SC/NFR 仍保持 Pending（子模块独立测试证据未闭合）；§6 仪表盘刷新 | ZCode |
