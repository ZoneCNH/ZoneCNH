# Binance 模块待办事项

> **来源**：`report/binance/DATA-INTEGRITY-DEEP-ANALYSIS-20260706.md` + `plans/binance/DATA-INTEGRITY-FIX-PLAN-20260706.md`
> **生成日期**：2026-07-06
> **基线**：SPEC v3.14.0 / Runtime v0.13.0 / 55 FR Done / release_closeable=YES

---

## 数据完整性修复（2026-07-06）

### P0 — 数据完整性阻断（必须修复）

- [x] **R1**：TDengine Partial 写入静默丢失 — `taos_writer.go:125-139` Partial 返回 nil 不重投
  - 修复：Partial 返回 `ErrPartialWrite` error（两处分支）；同步更新测试断言
  - 验证：`go test ./internal/server/storage/...` PASS
  - 工时：2d
- [x] **R3**：NATS_SUBJECT config default 不匹配 — `config.go:317` `binance.market.*.*`（3 段）vs publisher `.v1`（4 段）
  - 修复：default 改为 `binance.market.>`
  - 工时：0.5h

### P1 — 采集完整性（需专项开发）

- [x] **R2**：`@fundingRate`/`@markPrice` 独立流未默认订阅 — `product_line.go:102-108` DefaultMarketStreams 缺失
  - 修复：新增 `DefaultMarketStreamsForProductLine(pl)`，um_perp/cm_perp 追加 `@markPrice` + `@fundingRate`
  - 验证：`go test ./internal/client/...` PASS
  - 工时：0.5d
- [x] **R2a**：Reconciler DefaultEventTypes 命名不一致 — `reconciler.go:77` 用 Binance 原始流名而非归一化名
  - 修复：`[trade, depth, kline, aggTrade, bookTicker]` → `[trade, tick, bar, depth, funding_rate, mark_price]`
  - 工时：0.5d

### P2 — 治理卫生（非阻断）

- [x] **R4**：depth 不纳入完整性扫描 — `scanner.go:60-65` 排除 depth
  - 修复：`gate/OBSERVABILITY.md` 新增 §8 depth 排除声明（快照型数据，不适用 heartbeat 模式）
  - 工时：0.5d
- [x] **R5a**：`goal/goal.md` 版本回刷 v3.14.0/v0.13.0；状态 55/55 YES
- [x] **R5b**：`module/registry.yaml` 版本回刷 v3.14.0/v0.13.0
- [x] **R5c**：`docs/architecture/05-foundation.md` 版本回刷 v3.14.0/v0.13.0；55 Done
- [x] **R5d**：`matrix/TRACEABILITY.md` Source-SPEC v3.14.0；§4 55 Done
- [x] **R5e**：`STATUS.md` runtime v0.13.0；55/55 Done
- [x] **R5f**：`README.md` Spec-Version v3.14.0；55 Done
- [x] **R5g**：`spec/SPEC.md` §5/§22a/§23 正文 Done 数 48/54→55 对齐
- [x] **R5h**：`gate/OBSERVABILITY.md` Module-Version v3.9.8→v3.14.0

### 执行编排

| Track | 范围 | 任务 | 工时 |
|---|---|---|---|
| A (runtime) | R1 Partial 重投 + R2 fundingRate + R2a Reconciler + R3 NATS config | A1-A5 | ~3d |
| B (docs) | R4 depth 声明 + R5 版本回刷（6 文件） | B1-B7 | ~1.5d |
| C (optional) | R4+ DepthSnapshotScanner 增强 | C1 | ~1.5d |

### 验收命令

```bash
# Track A (runtime)
cd /home/workspace/binance
go build ./... && go vet ./... && go test ./internal/server/storage/... ./internal/server/deadletter/... ./internal/client/... ./internal/server/reconcile/... ./pkg/binancecfg/...
go test -race ./internal/server/storage/...
scripts/boundary-gates.sh

# Track B (docs)
cd /home/workspace/ZoneCNH
.github/ci/binance-version-consistency-check.sh
.github/ci/binance-reference-integrity-check.sh
rg "v3.9.8|v0.12.0|v3.9.6|v0.8.0|v3.10.0" module/binance/goal/ module/registry.yaml docs/architecture/05-foundation.md STATUS.md module/binance/README.md module/binance/matrix/TRACEABILITY.md
# 预期：0 命中
```

---

## 历史归档

> 以下为已完成的历史待办，保留用于审计追溯。完整历史见 `evidence/2026-06-28/todo-archived.md`。

- [x] 2026-07-05：16 项报告深度分析修复（TODO-01~16，fix/report-followup 分支）
- [x] 2026-07-05：白名单策略统一四类市场各 top 20（ADR-008，v3.14.0）
- [x] 2026-07-05：白名单系统实盘验证六项细化（v3.13.0，PR #429~431）
- [x] 2026-07-05：Phase-1~8 全量修复，28 GitHub Issues 全部关闭（PRG-007 PASS）
- [x] 2026-07-04：20 轮审查共识修复 N2/N4/N6/N7/ORDBK（PR #425 + #1668）
- [x] 2026-07-04：PRG-006 gated resilience 测试 CI-runnable
- [x] 2026-07-06：GAP-E59 数据血缘/版本控制修复（`internal/server/lineage/` + migration 012）
