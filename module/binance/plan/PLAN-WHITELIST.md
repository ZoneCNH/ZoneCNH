# binance 白名单系统实施计划

- Module-Version: v4.0.0
- Last-Updated: 2026-07-10
- Status: Historical Completion Snapshot（当前 root 为 13 Done / 52 Partial / 0 Drifted / 0 Pending，`release_closeable_spec=NO`、`release_closeable_runtime=NO`）
- Runtime-Repo: `/home/workspace/binance`
- Source-Design: `module/binance/design/EXCHANGEINFO-WHITELIST-DESIGN.md` v0.4
- Source-ADR: `module/binance/design/ADR-006-server-side-whitelist-rewrite.md` + `ADR-008-whitelist-top20-unify.md`

## 1. 目标

> [COMPUTED, HIGH] 本计划记录 2026-07-07 白名单迭代的历史执行结果；其中 Done/PASS/YES 仅描述当时投影，不是当前 RC 的发布判定。当前状态只读 root `matrix/TRACEABILITY.md`。

将 binance 模块的白名单能力从"配置驱动本地过滤"升级为"服务端 DB SSOT + NATS 推送 + 下游消费方 SDK"，覆盖 FR-045~050 / BR-009。

## 2. 依赖图

```
WL-001 (catalog_symbols 扩展)
  │
  ▼
WL-002 (whitelist 三表 + version SSOT)
  │
  ▼
WL-003 (SyncJob + 准入规则)        ← 核心 task
  │
  ├──────────────┐
  ▼              ▼
WL-004          WL-005
(API)        (NATS push)
  │              │
  └──────┬───────┘
         ▼
      WL-006
   (Consumer SDK)
```

## 3. 实现顺序

| 序号 | Task | FR | 优先级 | 预估 | 前置 | 验证命令 |
|------|------|----|--------|------|------|----------|
| 1 | WL-001 catalog_symbols 扩展 | FR-050 | P0 | 3h | — | `go test ./internal/server/storage/...` |
| 2 | WL-002 whitelist 三表 + version | FR-046 | P0 | 4h | WL-001 | `go test ./internal/server/storage/...` |
| 3 | WL-003 SyncJob + 准入规则 | FR-045 | P1 | 6h | WL-002 | `go test ./internal/server/whitelist/...` |
| 4 | WL-004 Whitelist API | FR-047 | P1 | 4h | WL-003 | `go test ./internal/server/api/...` |
| 5 | WL-005 NATS version 推送 | FR-048 | P1 | 2h | WL-003 | `go test ./internal/server/whitelist/...` |
| 6 | WL-006 Consumer SDK | FR-049 | P2 | 6h | WL-004, WL-005 | `go test ./pkg/whitelistclient/...` |

> WL-004 与 WL-005 可并行（均只依赖 WL-003）。

## 4. 阶段门禁

| Gate | 条件 | 状态 |
|------|------|------|
| G-WL-0 | migration 011_whitelist.sql 幂等可执行 | Done |
| G-WL-1 | catalog_symbols 扩展字段 + ApplyDiff 改造测试 PASS | Done |
| G-WL-2 | whitelist 三表 + advisory lock 事务测试 PASS | Done |
| G-WL-3 | SyncJob 准入/下架/观察期规则测试 PASS | Done |
| G-WL-4 | API 全量/增量/无变化响应测试 PASS | Done |
| G-WL-5 | NATS version 推送集成测试 PASS | Done |
| G-WL-6 | Consumer SDK 缓存/容灾/重启恢复测试 PASS | Done |
| G-WL-7 | `go test ./...` 全量 PASS + `go vet ./...` 无 warning | Done |

## 5. 风险

| 风险 | 影响 | 缓解 |
|------|------|------|
| advisory lock 在 PG 连接池下行为异常 | SyncJob 并发互斥失效 | 使用 `pg_try_advisory_xact_lock`（事务级锁），连接池需保证同一事务在同一连接 |
| 现有 `buildSymbolWhitelist` 降级路径与 DB SSOT 冲突 | 启动时 DB 不可用仍用旧配置 | 保留旧路径作为 fallback，监控告警区分 "DB 模式" vs "降级模式" |
| NATS 推送丢失导致下游消费方延迟感知 | 下游白名单过期 | 3h 定时刷新兜底，丢失推送最多导致 3h 延迟 |
| options 准入规则过于宽松 | 高风险标的自动上线 | options 按 24h quoteVolume top 20 自动放行（ADR-008），top 20 以外进人工审核队列；TRADING 过滤前置（ADR-005 §6.1） |
| catalog_symbols 扩展字段影响现有查询 | 现有功能回归 | 新字段均允许 NULL/默认值，不破坏现有 SELECT |

## 6. 历史验收记录（非当前状态源）

- [x] FR-045~051 全部标记 Done
- [x] 当时 `module/binance/spec/SPEC.md` 投影为 55 Done / 10 Pending
- [x] `module/binance/matrix/TRACEABILITY.md` FR-045~051 行 State=Done
- [x] `go test ./...` PASS in `/home/workspace/binance`
- [x] migration `011_whitelist.sql` 幂等执行
- [x] 当时曾投影 release_closeable=YES；该结论已被 2026-07-10 深度复审取代
