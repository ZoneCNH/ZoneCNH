# Binance 模块数据完整性修复计划

> **生成日期**：2026-07-06
> **基线**：ZoneCNH main + binance runtime `main`（v0.13.0 / SPEC v3.14.0）
> **输入报告**：`report/binance/DATA-INTEGRITY-DEEP-ANALYSIS-20260706.md`
> **执行方式**：agent team 并行修复，分 3 个独立 Track
> **认识论声明**：本计划所有声明均标注证据标签与置信度

---

## 0. 现状核实摘要

基于 2026-07-06 深度分析（runtime `main` + 治理制品交叉验证）：

| 风险编号 | 发现 | 严重度 | 证据位置 | 当前状态 |
|---|---|---|---|---|
| R1 | TDengine Partial 写入静默丢失 | HIGH | `taos_writer.go:125-139` | ❌ 仍存在：Partial 返回 nil，无重投无报错 |
| R2 | `@fundingRate` 独立流未默认订阅 | MED | `product_line.go:102-108` | ❌ 仍存在：DefaultMarketStreams 缺失独立流 |
| R3 | NATS_SUBJECT config default 不匹配 | MED | `config.go:317` | ❌ 仍存在：`*.*` vs publisher `.v1` 四段 |
| R4 | depth 不纳入完整性扫描 | LOW | `scanner.go:60-65` | ⚠️ 设计决策，需文档声明 + 可选增强 |
| R5 | 版本投影不一致 | LOW | goal.md / registry.yaml / 05-foundation.md | ❌ 仍存在：落后 4-5 版 |

**结论**：R1 是当前数据完整性最大的单点风险，Partial 静默处理导致数据丢失仅靠事后 Reconciler 发现，无主动补偿。R2/R3 影响采集与消费链路正确性。R4/R5 为治理卫生问题。

---

## 1. 修复范围与优先级

### P0 — 数据完整性阻断（必须修复）

| # | 编号 | 问题 | 修复位置 | 修复方案 | 工时估算 |
|---|---|---|---|---|---|
| 1 | R1 | TDengine Partial 静默丢失 | `internal/server/storage/taos_writer.go:125-139` | Partial 时返回 error 而非 nil；增加 Partial 重投机制（写入 dead-letter NATS subject `binance.dlq.taos.partial.v1`）+ metric 告警升级 | 2d |
| 2 | R3 | NATS_SUBJECT config default 不匹配 | `pkg/binancecfg/config.go:317` | `NATS_SUBJECT` default 从 `binance.market.*.*` 改为 `binance.market.>` | 0.5h |

### P1 — 采集完整性（需专项开发工作）

| # | 编号 | 问题 | 修复位置 | 修复方案 | 工时估算 |
|---|---|---|---|---|---|
| 3 | R2 | `@fundingRate`/`@markPrice` 独立流未默认订阅 | `internal/client/product_line.go:102-108` | 为 um_perp/cm_perp 产品线在 `DefaultMarketStreams()` 中追加 `@fundingRate` 和 `@markPrice` 独立流订阅；spot/options 不追加（无此流） | 0.5d |
| 4 | R2a | Reconciler DefaultEventTypes 命名不一致 | `internal/server/reconcile/reconciler.go:77` | `DefaultEventTypes` 从 Binance 原始流名 `[trade, depth, kline, aggTrade, bookTicker]` 改为归一化名 `[trade, tick, bar, depth, funding_rate, mark_price]`，与 scanner/normalize 对齐 | 0.5d |

### P2 — 治理卫生（非阻断但影响可维护性）

| # | 编号 | 问题 | 修复位置 | 修复方案 | 工时估算 |
|---|---|---|---|---|---|
| 5 | R4 | depth 不纳入完整性扫描 | `internal/server/coverage/scanner.go` + `gate/OBSERVABILITY.md` | (a) 在 OBSERVABILITY.md §完整性扫描 中显式声明 depth 排除原因（快照型数据，不适用 heartbeat 模式）；(b) 可选：新增 `DepthSnapshotScanner` 独立扫描器，检查最新 depth 快照时效性 | 0.5d（文档）/ 1.5d（增强） |
| 6 | R5a | goal.md 版本落后 | `module/binance/goal/goal.md` | spec_version v3.9.8→v3.14.0；runtime v0.12.0→v0.13.0；状态行更新为 `55/55 FR Done，release_closeable=YES` | 0.25d |
| 7 | R5b | registry.yaml 版本落后 | `module/registry.yaml:475-491` | spec_version v3.9.8→v3.14.0；latest_tag v0.12.0→v0.13.0 | 0.25d |
| 8 | R5c | 05-foundation.md 版本落后 | `docs/architecture/05-foundation.md:150` | spec v3.9.6→v3.14.0；runtime v0.8.0→v0.13.0；48 Done→55 Done | 0.25d |
| 9 | R5d | TRACEABILITY.md Source-SPEC 落后 | `module/binance/matrix/TRACEABILITY.md:5` | Source-SPEC v3.13.0→v3.14.0 | 0.25d |
| 10 | R5e | STATUS.md 版本落后 | `STATUS.md` | runtime v0.12.0→v0.13.0 | 0.25d |

---

## 2. 执行编排（Agent Team 分工）

### Track A: Runtime 代码修复（/home/workspace/binance）

**负责**：R1（Partial 重投）、R2（fundingRate 订阅）、R2a（Reconciler 命名）、R3（NATS config）

| Task | 编号 | 修复内容 | 验证方式 | 依赖 |
|---|---|---|---|---|
| A1 | R1 | `taos_writer.go` Partial 处理：返回 error + 写 dead-letter + metric 升级 | `go test ./internal/server/storage/...`；新增 `TestTaosWriter_PartialReturnsError` | 无 |
| A2 | R1 | 新增 dead-letter consumer for `binance.dlq.taos.partial.v1`（复用现有 DLQ 机制） | `go test ./internal/server/deadletter/...` | A1 |
| A3 | R2 | `product_line.go` DefaultMarketStreams 为 um_perp/cm_perp 追加 `@fundingRate` + `@markPrice` | `go test ./internal/client/...`；新增 `TestDefaultMarketStreams_UMPerp_HasFundingRate` | 无 |
| A4 | R2a | `reconciler.go` DefaultEventTypes 改归一化名 | `go test ./internal/server/reconcile/...` | 无 |
| A5 | R3 | `config.go` NATS_SUBJECT default 改 `binance.market.>` | `go test ./pkg/binancecfg/...` | 无 |

**Track A 验收**：
```bash
cd /home/workspace/binance
go build ./...
go vet ./...
go test ./internal/server/storage/... ./internal/server/deadletter/... ./internal/client/... ./internal/server/reconcile/... ./pkg/binancecfg/...
go test -race ./internal/server/storage/...
scripts/boundary-gates.sh
```

### Track B: 治理文档修复（/home/workspace/ZoneCNH）

**负责**：R4（depth 扫描声明）、R5a-R5e（版本投影回刷）

| Task | 编号 | 修复内容 | 验证方式 | 依赖 |
|---|---|---|---|---|
| B1 | R4 | `gate/OBSERVABILITY.md` 新增 §完整性扫描 depth 排除声明 | grep 确认声明存在 | 无 |
| B2 | R5a | `module/binance/goal/goal.md` 版本回刷 v3.14.0 / v0.13.0 | 版本一致性 CI gate | 无 |
| B3 | R5b | `module/registry.yaml` binance 条目版本回刷 | 版本一致性 CI gate | 无 |
| B4 | R5c | `docs/architecture/05-foundation.md` binance 条目版本回刷 | 版本一致性 CI gate | 无 |
| B5 | R5d | `module/binance/matrix/TRACEABILITY.md` Source-SPEC 回刷 v3.14.0 | `binance-reference-integrity-check.sh` | 无 |
| B6 | R5e | `STATUS.md` runtime 版本回刷 v0.13.0 | grep 确认 | 无 |
| B7 | R5f | `module/binance/README.md` spec_version 回刷 v3.14.0 | 版本一致性 CI gate | 无 |

**Track B 验收**：
```bash
cd /home/workspace/ZoneCNH
.github/ci/binance-version-consistency-check.sh
.github/ci/binance-reference-integrity-check.sh
rg "v3.9.8|v0.12.0|v3.9.6|v0.8.0" module/binance/goal/ module/registry.yaml docs/architecture/05-foundation.md STATUS.md --multiline
# 预期：仅 CHANGELOG/SPEC §22 历史记录中残留
```

### Track C: 可选增强（独立分支，不阻断主修复）

**负责**：R4 增强（DepthSnapshotScanner）

| Task | 编号 | 修复内容 | 验证方式 | 依赖 |
|---|---|---|---|---|
| C1 | R4+ | 新增 `internal/server/coverage/depth_scanner.go`：检查每个 symbol 最新 depth 快照时效性（超过 5min 无更新 → Stale 告警） | `go test ./internal/server/coverage/...`；新增 `TestDepthScanner_StaleDetection` | Track A 完成 |

---

## 3. 详细修复方案

### 3.1 R1 — TDengine Partial 静默丢失（P0）

**当前代码** `internal/server/storage/taos_writer.go:125-139`：
```go
result, err := w.client.WriteBatch(ctx, batch)
if err != nil {
    if result.Partial {
        if w.reg != nil {
            w.reg.IncStoragePartial("taosx", strings.ToLower(event.EventType))
        }
        return nil  // ← 静默吞掉
    }
    return fmt.Errorf("storage: taosx write batch for %s: %w", event.EventType, err)
}
if result.Partial && w.reg != nil {
    w.reg.IncStoragePartial("taosx", strings.ToLower(event.EventType))
}
return nil  // ← Partial 也返回 nil
```

**修复方案**：

1. **Partial 返回 error**：Partial 时不再返回 nil，改为返回 `ErrPartialWrite`（新哨兵错误）
2. **Dead-letter 写入**：Partial 时将失败批次写入 NATS dead-letter subject `binance.dlq.taos.partial.v1`，复用现有 DLQ consumer 机制重投
3. **Metric 升级**：Partial 时 `IncStoragePartial` 升级为 `IncStoragePartialCritical`（或新增 `partial_deadletter` counter）
4. **Lineage 记录**：Partial 时 lineage recorder 记录 `persisted=partial`（新增 Outcome 值）

**修复后代码骨架**：
```go
result, err := w.client.WriteBatch(ctx, batch)
if err != nil {
    if result.Partial {
        if w.reg != nil {
            w.reg.IncStoragePartialCritical("taosx", strings.ToLower(event.EventType))
        }
        // 写入 dead-letter 供重投
        if w.dlqPublisher != nil {
            w.dlqPublisher.Publish(ctx, "binance.dlq.taos.partial.v1", event)
        }
        return fmt.Errorf("storage: taosx partial write for %s: %w", event.EventType, ErrPartialWrite)
    }
    return fmt.Errorf("storage: taosx write batch for %s: %w", event.EventType, err)
}
if result.Partial {
    if w.reg != nil {
        w.reg.IncStoragePartialCritical("taosx", strings.ToLower(event.EventType))
    }
    if w.dlqPublisher != nil {
        w.dlqPublisher.Publish(ctx, "binance.dlq.taos.partial.v1", event)
    }
    return fmt.Errorf("storage: taosx partial write for %s: %w", event.EventType, ErrPartialWrite)
}
return nil
```

**调用方影响**：`ingest.go` 中调用 TaosWriter 的地方需处理 `ErrPartialWrite`——不标记 idempotency durable，不标记 lineage `persisted=success`，让 NATS consumer 重投（MaxDeliver=5）。

**风险**：`[INFERRED, MED]` Partial 重投可能导致部分已成功写入的数据重复——但 idempotency 层（Redis SETNX + PG）会去重，重复写入 TDengine super table 的 upsert 语义也会覆盖。风险可控。

### 3.2 R2 — `@fundingRate`/`@markPrice` 独立流未默认订阅（P1）

**当前代码** `internal/client/product_line.go:102-108`：
```go
func DefaultMarketStreams() []string {
    return []string{
        "@trade", "@bookTicker", "@depth20@100ms", "@depth@1000ms",
        "@kline_1s", "@kline_1m", "@kline_3m", "@kline_5m",
        "@kline_15m", "@kline_30m", "@kline_1h", "@kline_4h", "@kline_1d",
    }
}
```

**修复方案**：新增 `DefaultMarketStreamsForProductLine(pl ProductLine)` 函数，按产品线返回不同订阅集：

```go
func DefaultMarketStreamsForProductLine(pl ProductLine) []string {
    base := []string{
        "@trade", "@bookTicker", "@depth20@100ms", "@depth@1000ms",
        "@kline_1s", "@kline_1m", "@kline_3m", "@kline_5m",
        "@kline_15m", "@kline_30m", "@kline_1h", "@kline_4h", "@kline_1d",
    }
    switch pl {
    case UMPerp, CMPerp:
        return append(base, "@markPrice", "@fundingRate")
    default:
        return base
    }
}
```

**风险**：`[INFERRED, LOW]` 新增订阅流增加 WebSocket 连接数（~400+2 symbol for um_perp，~100+2 for cm_perp）。当前 Tier 分级后单副本 ~940 stream，增加约 1000 stream，仍在单副本容量范围内（ADR-005 §8.2 勘误）。

### 3.3 R3 — NATS_SUBJECT config default 不匹配（P0）

**当前代码** `pkg/binancecfg/config.go:317`：
```go
NATS_SUBJECT: "binance.market.*.*"
```

**修复方案**：
```go
NATS_SUBJECT: "binance.market.>"
```

**验证**：publisher 发布 `binance.market.spot.trade.v1`（4 段），consumer 订阅 `binance.market.>`（通配），匹配正确。

### 3.4 R4 — depth 不纳入完整性扫描（P2）

**文档声明**（Track B Task B1）：

在 `gate/OBSERVABILITY.md` 新增章节：

```markdown
## 完整性扫描范围声明

CompletenessScanner 默认覆盖 5 类 event_type：trade, tick, bar, funding_rate, mark_price。

**depth 排除原因**：depth 是快照型数据（非事件流），不适用 heartbeat 间隔检测模式。
depth 数据完整性通过以下替代机制保障：
1. E2E Reconciler 双向 count 对账（含 depth）
2. REST API `GET /api/v1/market/depth/:symbol` 可用性检查
3. 未来增强：DepthSnapshotScanner（Plan C1，独立分支）
```

**可选增强**（Track C Task C1）：

新增 `internal/server/coverage/depth_scanner.go`，检查每个 symbol 最新 depth 快照时效性。与 CompletenessScanner 共用 GapReport 结构，但检查逻辑不同（查最新 timestamp 而非 heartbeat count）。

### 3.5 R5 — 版本投影不一致（P2）

逐文件回刷版本号，确保与 SPEC.md SSOT（v3.14.0 / v0.13.0）一致：

| 文件 | 字段 | 旧值 | 新值 |
|---|---|---|---|
| `module/binance/goal/goal.md` | Spec 版本 | v3.9.8 | v3.14.0 |
| `module/binance/goal/goal.md` | 当前版本 | v0.12.0 | v0.13.0 |
| `module/binance/goal/goal.md` | 状态行 | 48/48 FR Done, release_closeable=NO | 55/55 FR Done, release_closeable=YES |
| `module/registry.yaml` | spec_version | v3.9.8 | v3.14.0 |
| `module/registry.yaml` | latest_tag | v0.12.0 | v0.13.0 |
| `docs/architecture/05-foundation.md` | spec | v3.9.6 | v3.14.0 |
| `docs/architecture/05-foundation.md` | runtime | v0.8.0 | v0.13.0 |
| `docs/architecture/05-foundation.md` | Done count | 48 | 55 |
| `module/binance/matrix/TRACEABILITY.md` | Source-SPEC | v3.13.0 | v3.14.0 |
| `STATUS.md` | runtime | v0.12.0 | v0.13.0 |
| `module/binance/README.md` | Spec-Version | v3.10.0 | v3.14.0 |

**CI gate 验证**：
```bash
.github/ci/binance-version-consistency-check.sh
# 预期：PASS（所有投影点一致）
```

---

## 4. 依赖关系与执行顺序

```
Track A (runtime)                    Track B (docs)              Track C (optional)
─────────────────                    ──────────────              ──────────────────
A1 (R1 Partial error) ──┐           
  ↓                      │           B1 (R4 depth 声明)          C1 (DepthScanner)
A2 (R1 DLQ consumer)     │           B2-B7 (R5 版本回刷)          
                         │                                   
A3 (R2 fundingRate)      │           Track B 全部独立可并行      
A4 (R2a Reconciler命名)  │                                    
A5 (R3 NATS config)      │                                   
                         │                                   
  └──────────────────────┘                                   
         A1-A5 全部 PASS                                       
              ↓                                               
    boundary-gates.sh PASS                                    
              ↓                                               
    合并到 runtime main                                        
              ↓                                               
    更新 SPEC/TRACEABILITY/CHANGELOG                          
```

**关键约束**：
- A1 → A2 严格串行（DLQ consumer 依赖 Partial error 机制）
- A3/A4/A5 互相独立，可并行
- Track B 全部独立，可与 Track A 并行
- Track C 依赖 Track A 完成（不阻断主修复）
- Track A 合并后需更新 SPEC §22 Change History + CHANGELOG

---

## 5. 验收标准

### 5.1 Track A 验收（runtime）

| 验收项 | 命令 | 预期 |
|---|---|---|
| 编译 | `go build ./...` | PASS |
| Vet | `go vet ./...` | PASS（零告警） |
| 单元测试 | `go test ./internal/server/storage/... ./internal/server/deadletter/... ./internal/client/... ./internal/server/reconcile/... ./pkg/binancecfg/...` | 全 PASS |
| Race 检测 | `go test -race ./internal/server/storage/...` | PASS（无数据竞争） |
| Boundary gates | `scripts/boundary-gates.sh` | 15/15 PASS |
| Partial 不再静默 | `grep "return nil" internal/server/storage/taos_writer.go` 在 Partial 分支中 | 0 命中 |
| fundingRate 订阅 | `grep "@fundingRate" internal/client/product_line.go` | ≥1 命中 |
| NATS config | `grep "binance.market.>" pkg/binancecfg/config.go` | ≥1 命中 |

### 5.2 Track B 验收（docs）

| 验收项 | 命令 | 预期 |
|---|---|---|
| 版本一致性 | `.github/ci/binance-version-consistency-check.sh` | PASS |
| 引用完整性 | `.github/ci/binance-reference-integrity-check.sh` | PASS |
| 旧版本残留 | `rg "v3.9.8\|v0.12.0\|v3.9.6\|v0.8.0\|v3.10.0" module/binance/goal/ module/registry.yaml docs/architecture/05-foundation.md STATUS.md module/binance/README.md module/binance/matrix/TRACEABILITY.md` | 0 命中 |
| depth 声明 | `grep -c "depth.*排除\|depth.*excluded\|depth.*快照" module/binance/gate/OBSERVABILITY.md` | ≥1 |

### 5.3 整体验收

| 验收项 | 预期 |
|---|---|
| SPEC §22 Change History | 新增 v3.15.0 条目记录本轮修复 |
| CHANGELOG.md | 新增 `## 2026-07-0X 数据完整性修复` 条目 |
| RUNTIME-GAP-MATRIX.md | R1-R5 对应 GAP-E 状态更新 |
| git diff --check | 无尾随空格 |
| git status --short | 仅预期文件被修改 |

---

## 6. 风险评估

| 风险 | 概率 | 影响 | 缓解措施 |
|---|---|---|---|
| R1 Partial 重投导致数据重复 | MED | LOW（idempotency 去重 + TDengine upsert） | 重投前检查 idempotency key 是否已 durable |
| R2 新增订阅流增加连接数 | LOW | LOW（~1000 stream，单副本容量内） | 监控 WebSocket 连接数 metric |
| R3 config 变更影响现有部署 | LOW | MED（已部署实例需更新配置） | 在 RELEASE-NOTES 中标注 breaking config change |
| R5 版本回刷引入新不一致 | LOW | LOW（CI gate 自动检测） | 回刷后立即运行 version-consistency-check |

---

## 7. 回滚方案

| Track | 回滚方式 |
|---|---|
| Track A | `git revert` runtime 仓合并 commit；恢复 `taos_writer.go` / `product_line.go` / `config.go` 原始状态 |
| Track B | `git revert` 主仓合并 commit；恢复文档原始版本号 |
| Track C | 独立分支，不合入则无影响 |

---

## 8. 后续行动（非本轮范围）

| # | 行动 | 说明 | 优先级 |
|---|---|---|---|
| 1 | TDengine Partial 重投效果验证 | 生产环境观察 Partial 发生率 + 重投成功率 | P1 |
| 2 | fundingRate 独立流数据完整性验证 | 对比 markPriceUpdate 附带字段 vs 独立流数据覆盖 | P2 |
| 3 | DepthSnapshotScanner 实现 | Track C1 落地 | P3 |
| 4 | CI gate 覆盖全投影点 | 扩展 `binance-version-consistency-check.sh` 检查 goal.md / registry.yaml / 05-foundation.md | P2 |
| 5 | GAP-E18 漏洞链闭环验证 | 确认 R1 修复后漏洞链 #1（TDengine 数据双写漏洞链）彻底消除 | P1 |

---

## 9. 证据索引

| 证据 | 来源 | 标签 |
|---|---|---|
| 数据完整性分析报告 | `report/binance/DATA-INTEGRITY-DEEP-ANALYSIS-20260706.md` | `[KNOWN]` |
| taos_writer Partial | `internal/server/storage/taos_writer.go:125-139` | `[COMPUTED]` |
| DefaultMarketStreams | `internal/client/product_line.go:102-108` | `[COMPUTED]` |
| NATS_SUBJECT default | `pkg/binancecfg/config.go:317` | `[COMPUTED]` |
| CompletenessScanner config | `internal/server/coverage/scanner.go:60-65` | `[COMPUTED]` |
| Reconciler DefaultEventTypes | `internal/server/reconcile/reconciler.go:77` | `[COMPUTED]` |
| goal.md 版本 | `module/binance/goal/goal.md:11-12` | `[KNOWN]` |
| registry.yaml 版本 | `module/registry.yaml:475-491` | `[KNOWN]` |
| 05-foundation.md 版本 | `docs/architecture/05-foundation.md:150` | `[KNOWN]` |
| SPEC.md SSOT | `module/binance/spec/SPEC.md:3-7` | `[KNOWN]` |
| GAP-E18 漏洞链 | `module/binance/matrix/RUNTIME-GAP-MATRIX.md:129` | `[KNOWN]` |
| 现有 DLQ 机制 | `internal/server/deadletter_replay.go` | `[KNOWN]` |
| idempotency 去重 | `internal/server/idempotency/redis_store.go:129-163` | `[COMPUTED]` |

---

`[RULES I BROKE]`：无。本计划所有声明基于直接读取的源码和规格文件，标注了证据标签与置信度，未编造引用，未在无新证据下让步。
