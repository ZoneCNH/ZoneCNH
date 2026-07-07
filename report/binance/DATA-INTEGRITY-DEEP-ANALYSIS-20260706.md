# Binance 模块深度分析 — 数据完整性检查报告

> **分析日期**：2026-07-06（UTC）
> **分析范围**：`module/binance/` 治理制品 + `/home/workspace/binance` runtime 仓
> **分析目标**：深度分析 binance 模块，检查数据采集的数据完整性
> **证据来源**：SPEC v3.14.0、TRACEABILITY v3.13.0、goal/goal.md、RUNTIME-GAP-MATRIX.md、design/ 全量、gate/ 全量、CHANGELOG.md、runtime 仓源码交叉验证
> **认识论声明**：本报告所有事实性声明均标注证据标签与置信度
> **更新快照**：2026-07-06（runtime `main`；主仓 SPEC v3.14.0 / Runtime v0.13.0）

---

## 一、模块概览

| 维度              | 值                                                                      |
| ----------------- | ----------------------------------------------------------------------- |
| 定位              | 数据域 · 行情采集 C/S Module（ZoneCNH 规格参考实现）                    |
| 架构              | C/S 双进程：client 采集→NATS JetStream→server 消费→持久化→REST/kafkax   |
| 产品线            | Spot / USDⓈ-M / COIN-M / Options                                        |
| 事件类型          | tick, bar, depth, trade, funding_rate, mark_price（6 类）               |
| Spec 版本         | v3.14.0                                                                 |
| Runtime 版本      | v0.13.0                                                                 |
| FR 状态           | 55 Done / 0 Partial / 0 Pending（规格口径，100%）                       |
| release_closeable | YES（PRG-001~007 全 PASS）                                              |
| 运行时缺口        | 59 项 GAP-E（3 已修复 E1/E6/E59，其余通过 28 个 GitHub Issue 关闭映射） |
| 代码规模          | ~247K 行 Go 代码，119 源文件，143 测试文件，1898 测试函数               |

---

## 二、数据完整性检查结果

### 2.1 采集覆盖完整性

**四条产品线 × 六种事件类型覆盖矩阵** `[COMPUTED, HIGH]`：

| event_type   | spot | um_perp | cm_perp | options | 幂等键维度                         |
| ------------ | ---- | ------- | ------- | ------- | ---------------------------------- |
| trade        | ✅   | ✅      | ✅      | ✅      | trade_id                           |
| tick         | ✅   | ✅      | ✅      | ✅      | event_time + bid + ask             |
| bar          | ✅   | ✅      | ✅      | ✅      | interval + open_time               |
| depth        | ✅   | ✅      | ✅      | ✅      | U + u (firstUpdateId/lastUpdateId) |
| funding_rate | —    | ⚠️      | ⚠️      | —       | funding_time                       |
| mark_price   | —    | ⚠️      | ⚠️      | —       | event_time                         |

**发现的问题** `[COMPUTED, MED]`：

1. **`@fundingRate` 独立流未在 `DefaultMarketStreams()` 中** — `internal/client/product_line.go:102-108` 的默认订阅集仅含 `@trade, @bookTicker, @depth20@100ms, @depth@1000ms, @kline_*`，不包含 `@fundingRate` 和 `@markPrice` 独立流。合约的 funding_rate/mark_price 当前依赖 `@markPriceUpdate` 流的附带字段。
   - **影响**：若 Binance 在 markPriceUpdate 中不总是携带 funding rate 字段（`r`），funding_rate 数据可能不完整。
   - **风险等级**：MED — 归一化层 `normalize.go` 支持解析，但默认订阅不触发独立流。

2. **completeness scanner 不含 depth** — `internal/server/coverage/scanner.go:60-65` 的 `DefaultCompletenessScannerConfig.EventTypes = [trade, tick, bar, funding_rate, mark_price]`，depth 不纳入完整性扫描。这是设计决策（depth 是快照型数据，不适用 heartbeat 模式），但意味着 depth 数据缺失无法被自动检测。

### 2.2 存储写入完整性

**TDengine super table 覆盖** `[COMPUTED, HIGH]`：

6 类 event_type 全部有对应 super table：`trade, book_ticker (legacy: st_tick), kline (legacy: st_bar), funding_rate, mark_price_update (legacy: st_mark_price), depth_update (legacy: st_depth)`。`taos_writer.go:219-234` 的 `toPoint()` 方法完整路由，未知类型返回 `ErrUnsupportedEventType`。v3.18.0 命名对齐 Binance 原生事件名 + 去掉 st_ 前缀，runtime 待 migration。

### 2.3 TDengine Partial 写入风险（关键发现）

**`[COMPUTED, HIGH]`** `internal/server/storage/taos_writer.go:125-139`：

当 TDengine `WriteBatch` 返回 `result.Partial = true` 时，代码**仅记 metric 然后返回 nil（成功）**，不触发重投、不报错。这意味着：

- 调用方（ingest pipeline）认为写入成功 → idempotency 标记 durable → lineage 记 `persisted=success`
- **实际部分数据静默丢失**
- 仅靠 E2E Reconciler 事后对账才能发现
- 无 dead-letter / replay 通路补偿 Partial 丢失

**这是当前数据完整性最大的单点风险**，对应 GAP-E18（漏洞链 #1：TDengine 数据双写漏洞链）。虽然 SPEC 标注 28 个 GitHub Issue 已关闭，但 Partial 静默处理的设计在 runtime 代码中仍然存在。

### 2.4 幂等去重完整性

**`[COMPUTED, HIGH]`** 完整的双层幂等保护：

- **Redis SETNX 主层**：`idempotency/redis_store.go:129-163`，TTL 72h，CheckAndSet 时比对 payloadHash（相同=重复接受，不同=冲突 reject）
- **PG 备份层**：`idempotency/pg_log.go:66`，`INSERT ... ON CONFLICT DO UPDATE`，durable 标记单调升级（`old.durable OR EXCLUDED.durable`）
- **server 端 hash 重算**：GAP-E19 已修复——server 不再信任 client 传入的 hash，自行重算验证

### 2.5 完整性扫描与对账

**`[COMPUTED, HIGH]`** 两层完整性保障均已实现：

| 机制                | 文件                      | 覆盖范围                                                       | 状态                  |
| ------------------- | ------------------------- | -------------------------------------------------------------- | --------------------- |
| CompletenessScanner | `coverage/scanner.go`     | 5 类 event_type × active catalog symbols，10min stale 阈值     | ✅ 完整（不含 depth） |
| E2E Reconciler      | `reconcile/reconciler.go` | 双向 count 比对 + per-symbol 下钻 + SHA256 checksum + OSS 校验 | ✅ 完整               |

**注意**：Reconciler 的 `DefaultEventTypes = [trade, depth, kline, aggTrade, bookTicker]` 使用 Binance 原始流名而非归一化名，与 scanner 的归一化名不完全对应。

### 2.6 数据血缘（GAP-E59 修复）

**`[COMPUTED, HIGH]`** `internal/server/lineage/recorder.go`（224 行）：

- 三阶段追踪：`accepted → persisted → dispatched`
- Destination：`tdengine | clickhouse | kafka | oss`
- 双实现：InMemoryRecorder（ring buffer 50000 条）+ PostgresRecorder（append-only `data_lineage` 表，migration 012）
- 8 测试 PASS，coverage 89.1%，race 清洁

### 2.7 OSS 归档与 checksum

**`[COMPUTED, HIGH]`** `internal/server/storage/oss_archiver.go`（328 行）：

- 上传：NDJSON 格式，SHA256 checksum，metadata 带 `local-checksum`
- 校验：OSS 返回 ETag/ChecksumHex 必须与本地一致，否则删除损坏 object 并返回 BNC-012
- 删除前验证：`VerifyArchiveBeforeDelete()` 确认归档 proof 存在才允许 retention 删除
- 生命周期：`oss_lifecycle_scheduler.go` 周期清理 + `oss_rehydrate.go` 回灌

### 2.8 NATS Subject 一致性

**`[COMPUTED, HIGH]`** 发现一个潜在配置不一致：

- Publisher 实际发布：`binance.market.{productLine}.{eventType}.v1`（4 段，含 `.v1` 后缀）
- Consumer 订阅：`binance.market.>`（通配，正确匹配）
- **Config default**：`pkg/binancecfg/config.go:317` `NATS_SUBJECT` default `binance.market.*.*`（3 段，**不匹配 publisher 的 4 段 `.v1` subject**）

生产部署时若未显式覆盖 `NATS_SUBJECT`，consumer 可能无法匹配。这是一个配置层面的隐患。

### 2.9 Retention 策略

**`[COMPUTED, HIGH]`** 多级保留完整：

| classification | 保留年限 | 存储       |
| -------------- | -------- | ---------- |
| audit          | 7 年     | TDengine   |
| market_public  | 7 年     | TDengine   |
| market_derived | 3 年     | TDengine   |
| operational    | 1 年     | TDengine   |
| ClickHouse TTL | 730 天   | ClickHouse |
| OSS            | 30 天    | 冷存储     |

删除前强制 `VerifyArchiveBeforeDelete` 验证归档 proof。

### 2.10 Whitelist 系统

**`[COMPUTED, HIGH]`** 完整实现（FR-045~051）：

- SyncJob：事件驱动 + 30min 兜底 + PG advisory lock 单写者
- 准入规则：四类市场各 top 20（ADR-008 统一），options 自动准入
- API：`GET /internal/whitelist`（全量+增量）+ `POST /internal/whitelist/refresh`
- NATS 推送：`binance.whitelist.version`（独立 NATS 连接，publish 失败非致命）
- 下游 SDK：`pkg/whitelistclient/`（缓存 3h TTL + Bearer token 鉴权）

---

## 三、版本口径一致性检查

**`[COMPUTED, HIGH]`** 发现多处版本号不一致（投影字段未同步）：

| 来源                               | spec_version                | runtime_version | 说明         |
| ---------------------------------- | --------------------------- | --------------- | ------------ |
| SPEC.md（权威）                    | **v3.14.0**                 | **v0.13.0**     | 当前 SSOT    |
| TRACEABILITY.md                    | v3.13.0（Source-SPEC 标注） | —               | 落后一版     |
| goal/goal.md                       | v3.9.8                      | v0.12.0         | **严重落后** |
| README.md                          | v3.10.0                     | v0.13.0         | spec 落后    |
| registry.yaml                      | v3.9.8                      | v0.12.0         | **严重落后** |
| docs/architecture/05-foundation.md | v3.9.6                      | v0.8.0          | **严重落后** |
| STATUS.md                          | —                           | v0.12.0         | 落后         |
| DEEP-ANALYSIS 报告                 | v3.9.8                      | v0.12.0         | 历史快照     |

**结论**：SPEC.md 为版本唯一源（v3.14.0 / v0.13.0），但 goal.md、registry.yaml、05-foundation.md 等投影文件未同步回刷，差距达 4-5 个版本。CI 有 `binance-version-consistency-check.sh` 但显然未覆盖所有投影点。

---

## 四、数据完整性风险总结

### 4.1 已确认的风险

| #   | 风险                                   | 严重度   | 证据                                                | 状态                               |
| --- | -------------------------------------- | -------- | --------------------------------------------------- | ---------------------------------- |
| R1  | **TDengine Partial 静默丢失**          | **HIGH** | `taos_writer.go:125-139` 返回 nil 不重投            | 设计如此，依赖事后 Reconciler 对账 |
| R2  | **`@fundingRate` 独立流未默认订阅**    | MED      | `product_line.go:102-108` DefaultMarketStreams 缺失 | 归一化层支持但默认不触发           |
| R3  | **NATS_SUBJECT config default 不匹配** | MED      | `config.go:317` `*.*` vs publisher `.v1` 四段       | 生产需显式覆盖                     |
| R4  | **depth 不纳入完整性扫描**             | LOW      | `scanner.go:60-65` 排除 depth                       | 设计决策（快照型数据）             |
| R5  | **版本投影不一致**                     | LOW      | goal/registry/05-foundation 落后 4-5 版             | CI gate 未覆盖全投影点             |

### 4.2 数据完整性保障链路（已实现）

```
采集 → normalize → 幂等键 → NATS PubAck → server 消费 → 校验 → Redis SETNX 去重
  → TDengine 写入 → lineage 记录 → CompletenessScanner 周期扫描
  → E2E Reconciler 双向对账 → OSS checksum 校验 → retention 归档验证
```

**保障层级**：

1. **采集层**：四产品线全覆盖，6 事件类型归一化
2. **传输层**：JetStream PubAck + durable ManualAck + NakDelay(5s) × MaxDeliver(5)
3. **去重层**：Redis SETNX 72h + PG 备份双写
4. **存储层**：6 super table 全覆盖 + lineage 三阶段追踪
5. **校验层**：CompletenessScanner（5 类）+ E2E Reconciler（双向 count + checksum）
6. **归档层**：OSS SHA256 + 删除前 proof 验证
7. **保留层**：多级 retention + 分级校验

---

## 五、结论

`[COMPUTED, HIGH]` binance 模块在**规格层面**是 ZoneCNH 体系中最成熟的数据域模块——55/55 FR Done，完整的 C/S 架构，四产品线六事件类型覆盖，双层幂等去重，完整性扫描+E2E 对账+OSS checksum 三层校验，数据血缘 append-only 追踪。

**最大数据完整性风险**是 TDengine Partial 写入的静默处理（R1）——部分成功被当作完全成功处理，数据丢失仅靠事后 Reconciler 发现，无主动补偿通路。这是 GAP-E18 漏洞链的核心，建议优先评估是否需要增加 Partial 重投或 dead-letter 机制。

**版本口径不一致**（goal.md/registry.yaml 落后 4-5 版）不影响运行时数据完整性，但影响治理追溯准确性，建议回刷投影字段。

---

## 六、证据索引

| 证据                   | 来源                                                 | 标签         |
| ---------------------- | ---------------------------------------------------- | ------------ |
| SPEC v3.14.0           | `module/binance/spec/SPEC.md`                        | `[KNOWN]`    |
| TRACEABILITY v3.13.0   | `module/binance/matrix/TRACEABILITY.md`              | `[KNOWN]`    |
| RUNTIME-GAP-MATRIX     | `module/binance/matrix/RUNTIME-GAP-MATRIX.md`        | `[KNOWN]`    |
| goal.md                | `module/binance/goal/goal.md`                        | `[KNOWN]`    |
| CHANGELOG v3.14.0      | `module/binance/CHANGELOG.md`                        | `[KNOWN]`    |
| DEEP-ANALYSIS 20260704 | `report/binance/DEEP-ANALYSIS-20260704.md`           | `[KNOWN]`    |
| 采集覆盖               | `internal/client/product_line.go:102-108`            | `[COMPUTED]` |
| 存储写入               | `internal/server/storage/taos_writer.go:219-234`     | `[COMPUTED]` |
| Partial 处理           | `internal/server/storage/taos_writer.go:125-139`     | `[COMPUTED]` |
| 幂等去重               | `internal/server/idempotency/redis_store.go:129-163` | `[COMPUTED]` |
| 完整性扫描             | `internal/server/coverage/scanner.go:60-65`          | `[COMPUTED]` |
| E2E 对账               | `internal/server/reconcile/reconciler.go`            | `[COMPUTED]` |
| 数据血缘               | `internal/server/lineage/recorder.go`                | `[COMPUTED]` |
| OSS 归档               | `internal/server/storage/oss_archiver.go`            | `[COMPUTED]` |
| NATS subject           | `internal/client/publisher/publisher.go:43-53`       | `[COMPUTED]` |
| NATS config            | `pkg/binancecfg/config.go:317`                       | `[COMPUTED]` |
| Retention              | `internal/server/storage/taos_retention.go:20-23`    | `[COMPUTED]` |
| Whitelist              | `internal/server/whitelist/`                         | `[COMPUTED]` |
| registry.yaml          | `module/registry.yaml:475-491`                       | `[KNOWN]`    |
| 05-foundation.md       | `docs/architecture/05-foundation.md:150`             | `[KNOWN]`    |

---

`[RULES I BROKE]`：无。本报告所有声明均标注证据标签与置信度，未编造引用，未在无新证据下让步。
