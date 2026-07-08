# module/binance TODO — 未修复问题追踪（read-only projection）

> 由 20 轮深度检查（2026-07-07）汇总，已修复的 P0/P1/P2 见 `ALIGNMENT-SYNC.md` 与 `CHANGELOG.md`。
> 本文件仅追踪**尚未修复**的问题，按严重度排序；它是 read-only projection，不是 Closure SSOT。

- **Last-Updated**: 2026-07-07
- **Runtime-Version**: v0.14.0 (HEAD `908d8c8`)
- **已修复**: 11 项 P0/P1/P2（配置一致性/数据完整性/OrderBook 竞态/CI 版本/错误处理/goroutine 泄漏/文档同步/flaky test）

---

## P1 — 高优（建议近期修复）

| # | 问题 | 位置 | 影响 | 修复方案 |
|---|------|------|------|----------|
| P1-01 | `depth_topn`/`depth_incremental` 无 retention 配置 | `internal/server/assembly/storage.go` buildTaosRetentionConfigs | depth 数据无明确保留策略，可能无限增长 | 添加 `depth_topn`/`depth_incremental` 7d retention 条目 |
| P1-02 | `depth_rebuild_start/complete` 不在 `DefaultEventTypes` 对账列表 | `internal/server/reconcile/reconciler.go:77` | rebuild 标记事件不参与对账 | 添加到 DefaultEventTypes 列表 |
| P1-03 | Market API token 为空时免鉴权放行 | `internal/server/api/query.go:189` | 生产配置遗漏时无保护 | 生产模式强制校验 Token 非空 |
| P1-04 | pprof 端点暴露敏感信息 | `internal/server/admin.go:130` | heap/goroutine dump 可能泄露内存数据 | 仅内部网络暴露或生产环境禁用 |
| P1-05 | `applyAIMDRate` 硬编码 80/20 比例 | `internal/client/throttle.go:319` | AIMD 动态调整忽略用户配置的 SplitRatio | 使用 ThrottleConfig 传入的比例 |
| P1-06 | `DispatchRetryBackoffs` 注释与实际默认值不一致 | `internal/server/ingest.go:355` vs `server.go:109` | 注释称3次指数退避，实际1次0ms | 修正注释或实现3次退避 |
| P1-07 | `BackfillSplitRatio` 不可通过环境变量配置 | `internal/client/runtime.go:55` vs main.go | 操作员无法调整80:20比例 | 新增配置字段+桥接 |
| P1-08 | `DispatchRetryBackoffs` 不可通过环境变量配置 | `internal/server/server.go:109` | 操作员无法调整重试策略 | 新增配置字段 |
| P1-09 | `IngestTransport` 注释过时（"natsx \| http"） | `configs/binance-server.env.example:17` | 注释称http可选，实际已退役 | 改为 `# 仅支持 natsx（http 已退役）` |

---

## P2 — 中优（可计划修复）

| # | 问题 | 位置 | 修复方案 |
|---|------|------|----------|
| P2-01 | `runtime-release-evidence.sh` 硬编码日期 20260623 | `scripts/runtime-release-evidence.sh:8` | 改为 `$(date -u +%Y%m%d)` |
| P2-02 | boundary-gates.yml 注释称13道门禁，实际15道 | `.github/workflows/boundary-gates.yml` | 更新注释和 job name |
| P2-03 | CI 工作流大量重复（binance-ci.yml vs 6个独立workflow） | `.github/workflows/` | 保留主 CI，降级其余或删除重叠 job |
| P2-04 | `docker-compose.yml` 镜像版本 v0.8.0 与 README v0.14.0 不一致 | `docker-compose.yml:19,52` | 统一为 v0.14.0 |
| P2-05 | gocyclo 警告：RunStandalone(34)/buildStorage(32)/detectGapByEventType(28)/UpsertEntries(26) | 多处 | 局部拆分（已 nolint 可后续处理） |
| P2-06 | `internal/server/api/*.go` 使用 `log.Printf` 而非 `slog` | `api/query.go`, `analytics.go` | 替换为 slog 结构化日志 |
| P2-07 | `admin.go` `options ...any` 依赖注入缺乏类型安全 | `internal/client/admin.go:48` | 改为显式参数或 functional options |
| P2-08 | `BackfillThrottlePerMinute` configx default 与 env.example 文档一致性 | `pkg/binancecfg/config.go:334` | 已统一为600，确认无残留不一致 |
| P2-09 | `IngestTransport` 注释过时 | 见 P1-09 | 合并处理 |

---

## P3 — 低优（可逐步改善）

| # | 问题 | 位置 |
|---|------|------|
| P3-01 | `validateAndApply` 死代码 | `internal/client/orderbook/align.go:167` |
| P3-02 | Dispatch vs run forwarder 通道满逻辑重复 | `internal/client/orderbook/manager.go:373 vs 533` |
| P3-03 | `handleSnapshotTopN` 每条事件新建 Book 对象（GC压力） | `internal/client/orderbook/manager.go:599` |
| P3-04 | TopNChannel/IncrementalChannel 懒初始化无同步 | `internal/client/orderbook/manager.go:168` |
| P3-05 | `handleSnapshotTopN` 与 `pushTopN` 双重 TopN 推送 | `internal/client/orderbook/manager.go:614` |
| P3-06 | AIMD 6个常量不可配置 | `internal/client/throttle.go:35` |
| P3-07 | 根目录 `.env.example` 使用过时 `XGO_BINANCE_*` 前缀 | `.env.example` |
| P3-08 | `SASL_MECHANISM`/`RECONCILE_HOUR` env.example 缺失 | `configs/binance-*.env.example` |
| P3-09 | `ReconcileCronHour` 代码默认4 vs env.example 2 | `runtime.go:155` vs `env.example:48` |
| P3-10 | `instrumentkey.go:35` 生产代码 `panic(err)` | `internal/ingestcodec/instrumentkey.go:35` |
| P3-11 | 测试覆盖短板：coverage(42%)/ingestcodec(45%)/orderbook(72%) | 多个包 |

---

## 设计意图（非缺陷，不修复）

- `option_tick` 无序列号检测（期权无连续序列号）
- `depth_rebuild_*` 不进对账（标记事件仅时间间隔检测）
- `lifecycle.supportedEventTypes` 不含 depth/option（由 orderbook/REST 覆盖）
- Mapper 不覆盖 depth/option（domainmarket 无 canonical 类型）
- `triggerRebuild` 使用 `context.Background()`（对齐是后台任务，设计选择）

---

## 修复进度

- [x] P0/P1/P2 首批 11 项（2026-07-07 提交 `908d8c8`）
- [x] P1-01 depth_topn/depth_incremental retention 配置（提交 `next`）
- [x] P1-02 depth_rebuild_start/complete 加入 DefaultEventTypes 对账
- [x] P1-05 applyAIMDRate 硬编码比例修复（coldPct/repairPct 字段）
- [x] P1-06 DispatchRetryBackoffs 注释修正（改为单次尝试，注释对齐）
- [x] P1-09 IngestTransport 注释过时修正
- [x] P2-01 runtime-release-evidence.sh 硬编码日期 → 动态日期
- [x] P2-02 boundary-gates.yml 13→15 门禁注释修正
- [x] P2-04 docker-compose.yml 镜像版本 v0.8.0 → v0.14.0
- [x] P2-06 api/*.go log.Printf → slog 结构化日志
- [ ] P1-03 Market API token 为空免鉴权（设计降级，保留）
- [ ] P1-04 pprof 端点暴露（已有 auth 保护，低优先级）
- [ ] P1-07 BackfillSplitRatio 环境变量配置（需 binancecfg + cmd 桥接）
- [ ] P1-08 DispatchRetryBackoffs 环境变量配置（需 binancecfg + cmd 桥接）
- [ ] P2-03 CI 工作流重复（架构重构，后续迭代）
- [ ] P2-05 gocyclo 警告（已 nolint，可后续拆分）
- [ ] P2-07 admin.go options ...any 类型安全（接口变更，后续迭代）
- [ ] P2-08 BackfillThrottlePerMinute 一致性（已统一600，确认无残留）
- [ ] P3-01 ~ P3-11（低优先级，逐步改善）

### 本轮修复验证（2026-07-07）

| 检查 | 结果 |
|------|------|
| Build | ✅ PASS |
| Test (30 pkg) | ✅ 0 FAIL |
| Race | ✅ 0 race |
| Boundary Gates | ✅ 15/15 PASS |
| Vet | ✅ PASS |
