# Binance 模块

---

## ✅ 全部 28 个 GitHub Issues 已关闭（2026-07-05）

> **来源**：`gh issue list -R ZoneCNH/binance --state open`（2026-07-05 核实 → 0 open）
> **SSOT**：GitHub Issues 为追踪 SSOT，本节为本地只读投影
> **执行批次**：Phase-1 + Phase-5 + Phase-6 + Phase-7 + Phase-8 = 28 项全部关闭

### Phase-1 — 治理陷阱（4 项，已关闭）

| #   | 标题                                                       | 关闭证据 |
| --- | ---------------------------------------------------------- | -------- |
| 369 | T2-1: evidence/ 补 GAP-E 引用                              | 4 文件含 GAP-E1，3 文件含 RUNTIME-GAP-MATRIX |
| 371 | T9-1: SCORECARD 测试维度评分下调                           | 93→85，脚注引用 TEST-ANALYSIS |
| 400 | T4-1: Task 计数矛盾对齐                                    | 44/44 对齐 |
| 402 | T8-3 修正: BR 数量缩减 vs CHANGELOG                        | CHANGELOG BR-009→BR-004 对齐 SPEC §8 |

### Phase-5 — 独立可上项（3 项，已关闭）

| #   | 标题                                          | 关闭证据 |
| --- | --------------------------------------------- | -------- |
| 374 | GAP-E32: 7 处 goroutine 加 recover 包装       | 7 处落点 go func() = recover() |
| 377 | GAP-E36: ldflags 注入 buildinfo               | Makefile LDFLAGS 4 变量 + --version flag |
| 378 | GAP-E29: 集成 golang-migrate migration runner | up/down/version/force 子命令，build PASS |

### Phase-6 — ExchangeInfo 分级体系（4 项，已关闭）

| #   | 标题                                                             | 关闭证据 |
| --- | ---------------------------------------------------------------- | -------- |
| 379 | GAP-E26: interval SSOT（前置）                                   | RequiredBarIntervals 7→9, eventTypeToInterval 解析后缀 |
| 380 | EXCHANGEINFO §8.3: 静态白名单 MVP（STREAM_SYMBOLS）              | STREAM_SYMBOLS 配置+过滤+.env.example 文档 |
| 381 | GAP-E24: CatalogEntry 动态分级                                   | QuoteVolumeUSD + TierConfig + applyCatalogClassification |
| 382 | EXCHANGEINFO §8.1: options 独立维度                              | options_classification.go (距到期天数, moneyness) 分桶 |

### Phase-7 — 数据完整性（7 项，已关闭）

| #   | 标题                                          | 关闭证据 |
| --- | --------------------------------------------- | -------- |
| 383 | GAP-E2: server CompletenessScanner            | completeness/scanner.go 周期扫描 coverage 缺口 |
| 384 | GAP-E3: E2E 二向对账 + OSS checksum           | reconcile/reconciler.go + SHA256 OSS checksum |
| 385 | GAP-E10: catalog diff NATS pub/sub            | catalogdiff/subscriber.go + catalog_publisher.go |
| 386 | GAP-E12: AckWait 30s → 5min                   | consumer.go AckWait = 5 * time.Minute |
| 387 | GAP-E17: server time.Now().UTC() 强制         | 0 处 time.Now() 无 UTC，26 处有 UTC |
| 388 | GAP-E18: TDengine 部分成功捕获（不重投）      | taos_writer.go Partial=true → metric 不重投 |
| 389 | GAP-E28: PG 事务管理（多步写入原子性）        | pg_tx.go WithTx 通用事务包装 |

### Phase-8 — 批量修复（10 项，已关闭）

| #   | 标题         | 关闭证据 |
| --- | ------------ | -------- |
| 390 | 可观测性补强 | client metrics 聚合 (events_published/errors/active_subscriptions) + pprof |
| 391 | 安全加固     | CSRF 防护 + SECURITY.md + CONTRIBUTING.md |
| 392 | 部署治理     | distroless + K8s strategy + securityContext + probes + Dockerfile fix |
| 393 | Schema 演进  | SchemaVersion 配置化 + PayloadHash server 重算 + 精度校验 |
| 394 | 配置治理     | NATS 拓扑配置化 + throttle 配置化 |
| 395 | 容错与韧性   | resiliencx v1.0.2 + exchangeinfo fallback + retry 分类 |
| 396 | 优雅运行     | graceful SIGTERM/SIGINT shutdown + retention cron + 背压 |
| 397 | 测试与质量   | CI race 强制 + HTTP client timeout |
| 398 | 长尾低优     | regexp 包级 var + 错误链 %w |
| 399 | 治理文档批次 | SPEC 23 节 + BR-001~008 + STANDARD/FEATURES/ACCEPTANCE/TRACEABILITY/ADR-001 |

### 关键依赖链（来自 RUNTIME-GAP-MATRIX §4）

```
E6 ✅ → E26 ✅ → E24 ✅ → E31 ✅ → E25 ✅ → E28 ✅ → E1/E7/E10 ✅/E20 ✅
         ↓
      E2/E3 ✅（完整性校验）→ E12/E17/E18 ✅（存储可靠性）
```
