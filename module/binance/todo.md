# Binance 模块

---

## 后续工作 — 10 个 Open GitHub Issues（按 Phase 分批推进）

> **来源**：`gh issue list -R ZoneCNH/binance --state open`（2026-07-05 核实）
> **统计**：P2×8 / P3×2 = 10 项
> **SSOT**：GitHub Issues 为追踪 SSOT，本节为本地只读投影
> **已关闭**：Phase-1（4）+ Phase-5（3）+ Phase-6（4）+ Phase-7（7）= 18 项于 2026-07-05 关闭

### ~~Phase-1 — 治理陷阱（4 项，2026-07-05 已关闭）~~

| #   | 标题                                                       | 关闭证据 |
| --- | ---------------------------------------------------------- | -------- |
| 369 | T2-1: evidence/ 补 GAP-E 引用                              | 4 文件含 GAP-E1，3 文件含 RUNTIME-GAP-MATRIX |
| 371 | T9-1: SCORECARD 测试维度评分下调                           | 93→85，脚注引用 TEST-ANALYSIS |
| 400 | T4-1: Task 计数矛盾对齐                                    | 44/44 对齐 |
| 402 | T8-3 修正: BR 数量缩减 vs CHANGELOG                        | CHANGELOG BR-009→BR-004 对齐 SPEC §8 |

### ~~Phase-5 — 独立可上项（3 项，2026-07-05 已关闭）~~

| #   | 标题                                          | 关闭证据 |
| --- | --------------------------------------------- | -------- |
| 374 | GAP-E32: 7 处 goroutine 加 recover 包装       | 7 处落点 go func() = recover() |
| 377 | GAP-E36: ldflags 注入 buildinfo               | Makefile LDFLAGS 4 变量 + --version flag |
| 378 | GAP-E29: 集成 golang-migrate migration runner | up/down/version/force 子命令，build PASS |

### ~~Phase-6 — ExchangeInfo 分级体系（4 项，2026-07-05 已关闭）~~

| #   | 标题                                                             | 关闭证据 |
| --- | ---------------------------------------------------------------- | -------- |
| 379 | GAP-E26: interval SSOT（前置）                                   | RequiredBarIntervals 7→9, eventTypeToInterval 解析后缀 |
| 380 | EXCHANGEINFO §8.3: 静态白名单 MVP（STREAM_SYMBOLS）              | STREAM_SYMBOLS 配置+过滤+.env.example 文档 |
| 381 | GAP-E24: CatalogEntry 动态分级                                   | QuoteVolumeUSD + TierConfig + applyCatalogClassification |
| 382 | EXCHANGEINFO §8.1: options 独立维度                              | options_classification.go (距到期天数, moneyness) 分桶 |

### ~~Phase-7 — 数据完整性（7 项，2026-07-05 已关闭）~~

| #   | 标题                                          | 关闭证据 |
| --- | --------------------------------------------- | -------- |
| 383 | GAP-E2: server CompletenessScanner            | completeness/scanner.go 周期扫描 coverage 缺口 |
| 384 | GAP-E3: E2E 二向对账 + OSS checksum           | reconcile/reconciler.go + SHA256 OSS checksum |
| 385 | GAP-E10: catalog diff NATS pub/sub            | catalogdiff/subscriber.go + catalog_publisher.go |
| 386 | GAP-E12: AckWait 30s → 5min                   | consumer.go AckWait = 5 * time.Minute |
| 387 | GAP-E17: server time.Now().UTC() 强制         | 0 处 time.Now() 无 UTC，26 处有 UTC |
| 388 | GAP-E18: TDengine 部分成功捕获（不重投）      | taos_writer.go Partial=true → metric 不重投 |
| 389 | GAP-E28: PG 事务管理（多步写入原子性）        | pg_tx.go WithTx 通用事务包装 |

### Phase-8 — 批量修复（10 项，按子阶段分批）

| 优先级 | #   | 标题         | 子阶段 | GAP-ID          |
| ------ | --- | ------------ | ------ | --------------- |
| P2     | 390 | 可观测性补强 | 8.1    | E9+E30+E35      |
| P2     | 391 | 安全加固     | 8.2    | E37+E44+E45     |
| P2     | 392 | 部署治理     | 8.3    | E41~E50         |
| P2     | 393 | Schema 演进  | 8.4    | E8+E19+E23      |
| P2     | 394 | 配置治理     | 8.5    | E31+E4          |
| P2     | 395 | 容错与韧性   | 8.6    | E11+E16+E33     |
| P2     | 396 | 优雅运行     | 8.7    | E14+E15+E20+E22 |
| P2     | 397 | 测试与质量   | 8.8    | E21+E40         |
| P3     | 398 | 长尾低优     | 8.9    | E38+E39         |
| P3     | 399 | 治理文档批次 | 8.10   | E51~E58         |

### 推荐执行顺序

```
Phase-8（批量修复，可按子阶段并行）← 下一批次
  #390→#391→...→#399
```

### 关键依赖链（来自 RUNTIME-GAP-MATRIX §4）

```
E6 ✅ → E26 → E24 → E31 → E25 → E28 → E1/E7/E10/E20
         ↓
      E2/E3（完整性校验）→ E12/E17/E18（存储可靠性）
```
