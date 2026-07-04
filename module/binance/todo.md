# Binance 模块 TODO — 20 轮审查修复任务

> **更新日期**: 2026-07-04
> **来源**: 20 轮独立复现审查共识 (`REVIEW-20260704-20ROUND-CONSENSUS.md`) + DEEP-ANALYSIS 增量
> **修复计划**: `plans/binance/FIX-PLAN-20260704.md`
> **PR**: runtime [#425](https://github.com/ZoneCNH/binance/pull/425)（`edd7805`）+ docs [#1668](https://github.com/ZoneCNH/ZoneCNH/pull/1668)（`59907845`）
> **基线**: runtime `main@edd7805`（fix/20round-review-consensus branch）

---

## P0 — 阻断发布（必须修复）

- [x] **N2**: 修复 NATS subject 段数不匹配（consumer.go `binance.market.*.*` → `binance.market.>`）
  - 文件: `internal/server/consumer/consumer.go:22`
  - 状态: ✅ 已修复
- [x] **T0**: 修复 TRACEABILITY.md release_closeable 矛盾（YES → NO，因 PRG-006=Partial）
  - 文件: `module/binance/matrix/TRACEABILITY.md` + 全量文档同步
  - 状态: ✅ 已修复（12 个文件全量修正）
- [x] **SPEC-PRG**: 修复 SPEC.md "PRG-001~007 全 PASS" 矛盾
  - 文件: `module/binance/spec/SPEC.md` + ACCEPTANCE.md + FEATURES.md
  - 状态: ✅ 已修复

## P1 — 阻断发布（需专项开发）

- [x] **N4**: 接入 UM/CM/Options connector 到主运行时启动路径
  - 文件: `internal/client/runtime.go`
  - 状态: ✅ 已修复（新增 EnableUMPerp/CMPerp/Options 配置 + fan-in 合并 events）
- [x] **N6**: TaosWriter 支持 funding_rate/mark_price 事件类型
  - 文件: `internal/server/storage/taos_writer.go`
  - 状态: ✅ 已修复（新增 fundingRatePoint() + markPricePoint() + st_funding_rate/st_mark_price 表）
- [x] **N7**: retention 去硬编码 ProductLine:"spot"，支持全产品线
  - 文件: `internal/server/assembly/storage.go`
  - 状态: ✅ 已修复（遍历 ["spot","um_perp","cm_perp","options"]）
- [x] **ORDBK**: depth 完整档位存储（不再退化为 top-of-book tick）
  - 文件: `internal/server/storage/taos_writer.go`
  - 状态: ✅ 已修复（新增 depthPoint() + st_depth 表，保留 bids_json/asks_json 完整档位）
- [x] **TEST1**: 修复 internal/client 测试超时（lifecycle worker goroutine 泄漏）
  - 文件: `internal/client/final_coverage_test.go`
  - 状态: ✅ 已修复（context.Background() → WithTimeout(10s)）
- [x] **SchemaVersion**: DefaultStandaloneConfig 缺 SchemaVersion 字段
  - 文件: `internal/client/runtime.go:111`
  - 状态: ✅ 已修复（补 wire.DefaultSchemaVersion）

## P2 — 业务完整性（非阻断）

- [x] **N3**: ACK-before-persist 时序在 SLA 文档显式声明
  - 文件: `module/binance/gate/OBSERVABILITY.md` §6
  - 状态: ✅ 已修复（新增 ACK 时序语义表 + SLA 声明）
- [x] **N5**: OLAP 10min 内存窗口在文档标注为 "内存窗口模式"
  - 文件: `internal/server/assembly/olap_source.go` 注释 + `module/binance/gate/OBSERVABILITY.md` §7
  - 状态: ✅ 已修复（代码注释 + 文档声明内存窗口限制）
- [x] **PRG7**: open issue 关闭或文档如实反映状态
  - GitHub: ZoneCNH/binance
  - 状态: ✅ 已修复（关闭 9 个已修复 issue：#365/#366/#367/#368/#372/#373/#375/#376/#401；剩余 27 个 open）

## P3 — 治理卫生

- [x] **DOC1**: 修复 404 链接引用（不存在的仓库）
  - 状态: ✅ 已确认（binance-market/binance-server 引用在 "Removed Legacy Module" 章节，为废弃文档非活跃引用）
- [x] **REG1**: 修复 registry.yaml maturity_ref 断链
  - 文件: `module/registry.yaml`
  - 状态: ✅ 已修复（maturity_ref → module/binance/goal/goal.md；spec_version v3.9.6→v3.9.8；latest_tag v0.11.0→v0.12.0）

---

## 已修复项（确认）

- [x] **N1**: main 分支编译失败 — `storageAssembly` 缺 `runtime` 字段 → 已修复（storage.go:313）
- [x] **GAP-E1**: client 直写 Postgres — `history_state_postgres.go` 已删除
- [x] **VER**: 版本号三方分裂 — 全部统一到 v3.9.8
- [x] **GM1**: RUNTIME-GAP-MATRIX 路径断链 — 已迁移至 `module/binance/matrix/RUNTIME-GAP-MATRIX.md`
- [x] **Boundary Gates**: 15/15 PASS

---

## 验收检查清单

- [x] `go build ./...` 无错误
- [x] `go test ./... -count=1 -timeout=180s` 全部 PASS（24/24 packages）
- [x] `bash scripts/boundary-gates.sh` 15/15 PASS
- [x] `grep "binance.market.>" internal/server/consumer/consumer.go` 命中
- [x] `grep "release_closeable: NO" module/binance/matrix/TRACEABILITY.md` 命中
- [x] `grep "PRG-001~007 全 PASS" module/binance/spec/SPEC.md` 无命中
- [x] `grep "NewUMPerpConnector\|NewCMPerpConnector\|NewOptionsConnector" internal/client/runtime.go` ≥3 命中
- [x] `grep "funding_rate\|mark_price" internal/server/storage/taos_writer.go` ≥2 命中
- [x] `grep 'ProductLine: "spot"' internal/server/assembly/storage.go` 无硬编码命中
- [x] `release_closeable=YES` 残留文档引用 = 0（排除历史归档）

---

## 后续工作 — 28 个 Open GitHub Issues（按 Phase 分批推进）

> **来源**：`gh issue list -R ZoneCNH/binance --state open`（2026-07-04 核实）
> **统计**：P1×17 / P2×8 / P3×3 = 28 项
> **SSOT**：GitHub Issues 为追踪 SSOT，本节为本地只读投影

### Phase-1 — 治理陷阱（4 项）

| 优先级 | # | 标题 | 标签 |
|--------|---|------|------|
| P1 | 369 | T2-1: evidence/ 补 GAP-E 引用 | governance-trap |
| P1 | 371 | T9-1: SCORECARD 测试维度评分下调 | governance-trap |
| P1 | 400 | T4-1: Task 计数矛盾对齐（实际 39 vs README 47/47） | governance-trap |
| P3 | 402 | T8-3 修正: BR 数量缩减（9→5）vs CHANGELOG 声明 Implemented | governance-trap |

### Phase-5 — 独立可上项（3 项，无前置依赖）

| 优先级 | # | 标题 | GAP-ID |
|--------|---|------|--------|
| P1 | 374 | GAP-E32: 7 处 goroutine 加 recover 包装 | E32 |
| P1 | 377 | GAP-E36: ldflags 注入 buildinfo | E36 |
| P1 | 378 | GAP-E29: 集成 golang-migrate migration runner | E29 |

### Phase-6 — ExchangeInfo 分级体系（4 项，依赖链 E26→E24）

| 优先级 | # | 标题 | GAP-ID |
|--------|---|------|--------|
| P1 | 379 | GAP-E26: interval SSOT（前置） | E26 |
| P1 | 380 | EXCHANGEINFO §8.3: 静态白名单 MVP（STREAM_SYMBOLS） | — |
| P1 | 381 | GAP-E24: CatalogEntry 动态分级（Tier/SymbolPriority/Collection） | E24 |
| P1 | 382 | EXCHANGEINFO §8.1: options 独立维度（不进 Tier） | — |

### Phase-7 — 数据完整性（7 项，server 侧核心）

| 优先级 | # | 标题 | GAP-ID |
|--------|---|------|--------|
| P1 | 383 | GAP-E2: server CompletenessScanner | E2 |
| P1 | 384 | GAP-E3: E2E 二向对账 + OSS checksum | E3 |
| P1 | 385 | GAP-E10: catalog diff NATS pub/sub | E10 |
| P1 | 386 | GAP-E12: AckWait 30s → 5min + backfill 小批次 | E12 |
| P1 | 387 | GAP-E17: server time.Now().UTC() 强制 | E17 |
| P1 | 388 | GAP-E18: TDengine 部分成功捕获（不重投） | E18 |
| P1 | 389 | GAP-E28: PG 事务管理（多步写入原子性） | E28 |

### Phase-8 — 批量修复（10 项，按子阶段分批）

| 优先级 | # | 标题 | 子阶段 | GAP-ID |
|--------|---|------|--------|--------|
| P2 | 390 | 可观测性补强 | 8.1 | E9+E30+E35 |
| P2 | 391 | 安全加固 | 8.2 | E37+E44+E45 |
| P2 | 392 | 部署治理 | 8.3 | E41~E50 |
| P2 | 393 | Schema 演进 | 8.4 | E8+E19+E23 |
| P2 | 394 | 配置治理 | 8.5 | E31+E4 |
| P2 | 395 | 容错与韧性 | 8.6 | E11+E16+E33 |
| P2 | 396 | 优雅运行 | 8.7 | E14+E15+E20+E22 |
| P2 | 397 | 测试与质量 | 8.8 | E21+E40 |
| P3 | 398 | 长尾低优 | 8.9 | E38+E39 |
| P3 | 399 | 治理文档批次 | 8.10 | E51~E58 |

### 推荐执行顺序

```
Phase-5（独立项，可并行）
  ├─ #374 GAP-E32 goroutine recover
  ├─ #377 GAP-E36 ldflags buildinfo
  └─ #378 GAP-E29 migration runner
        ↓
Phase-6（分级体系链）
  #379 E26 → #380 白名单 → #381 E24 → #382 options
        ↓
Phase-7（数据完整性核心）
  #383 E2 → #384 E3 → #385 E10 → #386 E12 → #387 E17 → #388 E18 → #389 E28
        ↓
Phase-8（批量修复，可按子阶段并行）
  #390→#391→...→#399
        ↓
Phase-1（治理陷阱，可与上述并行）
  #369→#371→#400→#402
```

### 关键依赖链（来自 RUNTIME-GAP-MATRIX §4）

```
E6 ✅ → E26 → E24 → E31 → E25 → E28 → E1/E7/E10/E20
         ↓
      E2/E3（完整性校验）→ E12/E17/E18（存储可靠性）
```
