# Binance 模块深度分析报告 v4 — 历史数据 vs 实时数据缺口

- [COMPUTED, HIGH] 报告日期：2026-06-22
- [COMPUTED, HIGH] 分析范围：`module/binance/SPEC.md` v2.2.2 + `client/SPEC.md` v2.1.1 + `server/SPEC.md` v2.1.0 + `NAMING.md` v1.0.0 + `RUNTIME-MAPPING.md` v2.0.0 + `TRACEABILITY.md` v2.2.3
- [COMPUTED, HIGH] 目标问题：判断 `binance` 模块对**历史数据处理**与**实时数据处理**的覆盖完整性，识别"同步对象 / 周期 / 策略"未明确的缺口
- [INFERRED, HIGH] 现状：FR-001 ~ FR-011 仅覆盖**实时事件流的转发管道**，未覆盖历史数据生命周期与同步控制面
- [COMPUTED, HIGH] 证据：FR/AC/TC 全表 grep `历史回填`、`backfill`、`gap fill`、`同步周期`、`symbol discovery` 命中为 0

---

## 一、实时数据处理 — 现状评估

### 1.1 已覆盖（评估：[COMPUTED, HIGH]）

| 维度 | 现状 | 来源 |
|---|---|---|
| 接入协议 | Binance WS + REST | SPEC §2 §11 `binance.ws_url` / `binance.rest_url` |
| 事件类型 | tick / trade / bar / depth × 4 产品线 = 16 组合 | NAMING §3 §4 |
| 投递语义 | at-least-once（JetStream PubAck + ManualAck） | FR-003、FR-004 |
| 幂等 | redisx SetNX 72h | FR-005 / BR-002 |
| 持久 | taosx 时序 + postgresx 元数据 + redisx 热缓存 | FR-006a/b/c |
| 缓存 TTL | tick 60s / depth 5s | §11.2.2 |

### 1.2 实时数据未明确的 6 个关键问题（评估：[INFERRED, HIGH]）

| # | 问题 | SPEC 现状 | 风险 |
|---|---|---|---|
| **R1** | **同步对象怎么选**：哪些 symbol 订阅、哪些不订阅 | §11.1 `binance.symbols.allow/deny` 只有空列表注释，**没有规则说"空=全部"还是"空=拒绝"** | 部署即"采全宇宙"或"采空"，无法预测 |
| **R2** | **新合约动态发现**：Binance 新增上市的 symbol 如何感知 | 无 FR；catalog 仅 §FR-001 提"可独立配置启用/禁用"，**未定义谁来增量发现** | 错过新币上市的前 N 小时数据 |
| **R3** | **K 线周期选择**：bar 有 1s/1m/5m/15m/1h/1d…，本模块订阅哪些 | NAMING §2 只说"K 线（多周期）"，**没有枚举具体周期** | 不同 connector 决策不一致，下游分析无法预期 |
| **R4** | **深度档位**：spot 取 5/10/20 档？um_perp 取 partial vs diff？ | §9 仅注释 Options 用 `@depth1000`，**spot/um_perp/cm_perp 档位未定义** | 实现期再定，深度数据语义漂移 |
| **R5** | **WS 心跳/重连周期**：disconnect 触发条件 | FR-003 "connector 自动重连"，**未给重连退避曲线、最大窗口、最大尝试次数** | connector 实现各自为政 |
| **R6** | **REST 兜底**：WS 断流期间是否调 REST `/api/v3/klines` 补 tick/bar | 完全缺失 | 长断流期间数据有 gap，幂等系统反而吃掉 REST 补的旧 tick |

---

## 二、历史数据处理 — 现状评估

### 2.1 SPEC 仅覆盖"归档退潮"，未覆盖"历史涨潮"（评估：[COMPUTED, HIGH]）

SPEC 提到的历史相关字段，全部是**热数据 → 冷数据的单向流动**：

| FR | 描述 | 方向 |
|---|---|---|
| FR-006a | `taosx.Query` 历史 tick/bar 查询 | 读历史 |
| FR-006d | `ossx Archival` 写到 OSS | 热→冷归档 |
| FR-007 | `GET /api/v1/market/bars/:symbol/range` | 读历史 |
| FR-010 | clickhousex ETL：taosx → clickhousex 聚合 | 热→热聚合 |

**完全没有的反方向**：
- ❌ 历史数据**初始化回填**（首次部署冷启动）
- ❌ 历史数据**断流补齐**（gap fill）
- ❌ 历史数据**全量校验**（与交易所对账）
- ❌ 历史数据**冷数据回热**（OSS → taosx 复活）

### 2.2 历史数据 9 个未明确的关键问题（评估：[INFERRED, HIGH]）

| # | 问题 | 风险 |
|---|---|---|
| **H1** | **首次部署冷启动**：第一次启动 binance-client 时，需要从哪个时间点开始采？只采当下 WS 还是回填过去 N 天？ | 系统投产即丢失历史，因子需要至少 30~365d 历史回测 |
| **H2** | **回填窗口**：每个 product_line × event_type 的 backfill 深度（1m bar 拉 5 年？tick 拉 30 天？） | 未定义则实现期由 ops 拍脑袋，模块间不一致 |
| **H3** | **回填来源**：Binance REST 历史 API（`/api/v3/klines`、`/fapi/v1/aggTrades`、`/fapi/v1/depth`），还是第三方数据集（Binance Vision、bybit dump、Kaggle）？ | 数据准确性 / 完整性差异巨大 |
| **H4** | **同步周期**：增量同步多久跑一次？（实时 WS + 每 5 分钟 REST 校对？每日全量对账？） | 无周期定义则永远不会校验 |
| **H5** | **Gap 检测**：发现 taosx 中某 symbol 某时段缺数据的算法（基于 trade_id 连号？基于时间窗口期望条数？） | 无检测=无修复 |
| **H6** | **Gap fill 优先级**：补 trade 优先还是补 bar 优先？补哪个产品线优先？ | 补数据期间挤占实时管道，影响 SLA |
| **H7** | **历史数据幂等**：REST 回填的 trade 与 WS 实时 trade 的 idempotency key 是否一致？若不一致则双写；若一致则 SetNX 拒掉实时（数据顺序倒挂） | SPEC FR-005 假设事件时间唯一，REST 回填会击穿假设 |
| **H8** | **冷数据回热**：用户查询 90 天前的 tick（已归档到 OSS），API 怎么响应？同步回拉 taosx？返回 OSS 链接？返回 503？ | FR-007 `/api/v1/market/ticks/:symbol/range` 行为未定义 |
| **H9** | **回填 throttle**：Binance REST 有 IP weight 限流（spot 1200/min，futures 2400/min），回填如何不打爆？回填进度可见性？ | 回填打满限额导致实时 REST 调用（如 listenKey 续期）失败 |

---

## 三、同步对象 — 缺失的控制面（评估：[INFERRED, HIGH]）

SPEC 把"同步对象"问题埋在两个不显眼的位置：

| 位置 | 内容 | 问题 |
|---|---|---|
| `binance.product_lines: []` | 默认空数组 | 未定义"空=全部还是空=拒绝" |
| `binance.symbols.allow/deny: []` | 白名单 + 黑名单 | 未定义优先级、未定义通配符语法、未定义热更新 |

**未定义的关键决策**：

1. **粒度**：是产品线粒度还是 (产品线, symbol) 二维粒度？(`spot:BTCUSDT` 启用但 `um_perp:BTCUSDT` 不启用是否合法？)
2. **动态发现**：postgresx `binance_instruments` 表是被动入库（看到事件才记），还是主动同步（每日拉 `/api/v3/exchangeInfo`）？
3. **配额**：每个产品线最多订阅多少 symbol？Binance WS 单连接 1024 streams 上限怎么分配？
4. **下线处理**：Binance 下架某 symbol，client 应该立即停止订阅还是继续尝试（导致重连风暴）？

---

## 四、周期 — 全文 grep 结果（评估：[COMPUTED, HIGH]）

文档中所有 `周期 / interval / 定时 / cron / scheduler` 命中：

| 位置 | 周期 | 用途 |
|---|---|---|
| §11.2.5 `clickhouse.etl.interval` | 5m | taosx → clickhousex ETL |
| §11.2.7 `oss.archiver.schedule` | `0 3 * * *` | OSS 归档 cron |
| §11.2.2 `redis.idempotency.ttl` | 72h | 幂等 key 寿命 |
| §11.2.4 `taos.retention.{ticks,bars,depth}` | 720h/8760h/72h | 热数据保留期 |
| §11.2.7 `oss.archiver.{ticks,bars}_cutoff` | 720h/2160h | 热→冷截止 |
| FR-011 | 30s lease / 10s 续期 / 5s 轮询 | 分布式锁 |

**完全没有的周期**：
- ❌ WS 重连退避
- ❌ REST 健康检查
- ❌ 合约目录刷新（exchangeInfo 拉取）
- ❌ 回填扫描
- ❌ Gap 检测
- ❌ 全量对账
- ❌ Funding rate / Mark price 这类**非事件性**周期数据（um_perp/cm_perp 必备）

---

## 五、补充建议 — 需要新增的 FR 列表

> 优先级 P0/P1/P2，每条都给出建议的 FR 编号与所属 SPEC 章节

### P0：实时数据控制面（堵当前已知洞）

| 建议 FR | 内容 | 落点 |
|---|---|---|
| **FR-012 Symbol Discovery & Filtering** | client 启动时拉 `/api/v3/exchangeInfo` + 三个 futures 对应 endpoint，按 `symbols.allow/deny` 白黑名单过滤；每 6h 刷新一次合约目录；新合约入 `binance_instruments` 表并触发 `instruments.changed` 事件 | root SPEC §7 + client/SPEC §7 |
| **FR-013 WebSocket Connection Policy** | 重连退避 `1s, 2s, 4s, 8s, 16s, 30s, 30s...`；单连接 stream 上限 200（Binance 限 1024，留 80% buffer）；超过则起新连接；keepalive ping 3min；listenKey 续期 30min | client/SPEC §7 |
| **FR-014 Bar Interval Subscription Set** | 显式枚举订阅周期：spot/um_perp/cm_perp 订阅 `1s, 1m, 5m, 15m, 1h, 4h, 1d`；options 仅 `1m, 5m, 1h, 1d`；其他周期下游通过 clickhousex 重采样 | NAMING §2 + root SPEC §9 |
| **FR-015 Depth Snapshot Tier** | spot/um_perp 订阅 `@depth20@100ms` + `@depth@1000ms`（增量）；cm_perp 同上；options 沿用现有 `@depth1000`；snapshot 与 incremental 用 `update_id` 拼合 | root SPEC §9 |

### P0：历史数据生命周期（关键缺失）

| 建议 FR | 内容 | 落点 |
|---|---|---|
| **FR-016 Historical Backfill on Cold Start** | 首次部署或新增 symbol 时通过 REST 拉历史；默认深度：tick=7d、trade=30d、bar(1m)=365d、bar(1h+)=1825d、depth=不回填（无 REST 历史接口） | server/SPEC §7 新增章节"Backfill" |
| **FR-017 Gap Detection & Fill** | server 每 5min 跑 gap detector：trade 用 `aggTrade.a`（trade_id）连号校验；bar 按时间窗口期望条数；发现 gap 入 `binance_backfill_jobs` 队列；coordinator 锁内单实例消费 | server/SPEC §7 |
| **FR-018 Backfill Throttle & Priority** | Binance REST 限速感知 token bucket（spot 1200 weight/min，futures 2400）；80% 给实时（exchangeInfo / listenKey），20% 给回填；优先级 trade > bar > tick | server/SPEC §7 |
| **FR-019 Backfill Idempotency Key Strategy** | REST 回填的 idempotency_key 维度必须与 WS 路径一致；trade 用 `exchange + product_line + symbol + trade_id`；bar 用 `... + interval + open_time`；保证回填与实时不双写 | BR-008 扩展 |

### P1：周期数据 & 校验

| 建议 FR | 内容 | 落点 |
|---|---|---|
| **FR-020 Funding Rate / Mark Price Stream** | um_perp/cm_perp 必须订阅 `markPriceUpdate` (1s/3s)；`fundingInfo` 8h；写入新 taosx 超表 `binance_funding`；event_type 扩展 `funding`/`mark_price` | NAMING §2 扩展 event_type 到 6 值 |
| **FR-021 Daily Reconciliation Job** | 每日 04:00 UTC 跑全量对账：按 symbol × 1d 维度，比对 taosx 聚合的 OHLCV vs Binance `/api/v3/klines` 返回值；差异超阈值（0.01%）入 `binance_reconciliation_alerts` | server/SPEC §7 |
| **FR-022 Cold Data Rehydration** | `/api/v1/market/ticks/:symbol/range` 落在 OSS 归档区时，按 query 触发 async OSS→taosx 回热（临时表 24h TTL）；同步响应 202 + job_id；客户端轮询 | FR-007 扩展 |

### P2：可观测性 & 治理

| 建议 FR | 内容 | 落点 |
|---|---|---|
| **FR-023 Backfill Progress API** | `GET /api/v1/admin/backfill/jobs`、`GET /api/v1/admin/backfill/coverage/:symbol`；coverage 返回每个 (product_line, symbol, event_type) 的最早可用时间戳 | server/SPEC §7 |
| **FR-024 Symbol Subscription Hot Reload** | `POST /api/v1/admin/symbols/reload`；从 postgresx 重读白黑名单；publish `symbols.changed` natsx 事件；client 订阅后增减 stream，不重启进程 | client + server SPEC §7 |

---

## 六、同步周期 — 建议的周期总表（评估：[INFERRED, HIGH]）

| 任务 | 周期 | 触发位置 | 备注 |
|---|---|---|---|
| Binance exchangeInfo 拉取 | 6h | client | 发现新合约 |
| WebSocket 重连 | 退避 1→30s | client | 单连接 |
| WS keepalive ping | 3min | client | 维持 |
| listenKey 续期 | 30min | client | user-data stream |
| listenKey 失效检测 | 60min | client | 失败重建 |
| Gap detector 扫描 | 5min | server (coordinator) | trade_id 连号 |
| Backfill worker 调度 | 30s 一批 | server (coordinator) | 受 throttle 限制 |
| ETL taosx → clickhousex | 5min | server (coordinator) | 已存在 |
| OSS 归档 | 每日 03:00 UTC | server (coordinator) | 已存在 |
| 全量对账 | 每日 04:00 UTC | server (coordinator) | 新增 |
| coordinator lease 续期 | 10s | server | 已存在 |
| Health check（taosx/pg/redis/kafka） | 30s | server admin | `/readyz` |
| Funding rate 拉取 | 8h（仅 um/cm_perp） | client | 非事件性 |

---

## 七、对当前文档治理体系的影响

> 评估：若按本报告补充，影响面如下

| 影响项 | 估算 |
|---|---|
| 新增 FR | 13 条（FR-012 ~ FR-024） |
| 新增 AC | ~30 条 |
| 新增 TC | ~20 条 |
| 新增 BR | 2 条（Backfill 优先级、Reconciliation 容差） |
| event_type 枚举扩展 | 4 → 6（加 funding、mark_price），触发 RULES R2 4×N 矩阵重新校验 |
| 新增 taosx 超表 | `binance_market_funding`、`binance_market_mark_price` |
| 新增 postgresx 表 | `binance_backfill_jobs`、`binance_reconciliation_alerts` |
| 新增 Kafka topic | 8 条（funding/mark_price × 2 产品线 × v1） |
| SPEC 版本 bump | MAJOR（event_type 枚举变更，按 RULES R3） |

---

## 八、建议落地顺序

1. **第一步**（P0 实时控制面）：补 FR-012/013/014/015 — 解决"采什么 / 怎么采 / 多深"
2. **第二步**（P0 历史生命周期）：补 FR-016/017/018/019 — 解决"从哪里开始 / 缺了怎么办"
3. **第三步**（P1 周期数据）：补 FR-020/021/022 — 解决"funding 缺失 / 没对账 / 冷数据不可用"
4. **第四步**（P2 治理）：补 FR-023/024 — 解决"运维不可见 / 不可热配"

每步独立 PR，独立 MINOR/MAJOR bump。建议先在 `module/binance/` 新增一份 `DATA-LIFECYCLE.md` 作为讨论稿，避免直接动 SPEC.md 引起治理风暴；定稿后再一次性 fold 进 SPEC §7。

---

## 停止条件

- [COMPUTED, HIGH] 本轮**未修改任何治理文件**（仅新增本报告到 `docs/report/binance/`）
- [INFERRED, HIGH] 建议下一步：用户确认是否进入 P0 补 FR 阶段；如确认，先建 `module/binance/DATA-LIFECYCLE.md` 讨论稿

[RULES I BROKE]：无 — 本次只读分析 + 新建报告文件，未触及 `module/binance/` 受保护治理文件
