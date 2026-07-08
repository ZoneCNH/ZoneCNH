# module/binance TODO — 未修复问题追踪（read-only projection）

> 截至 2026-07-08 事实校验（runtime HEAD `0047d8a`）。已修复的 P0/P1/P2 见
> [`ALIGNMENT-SYNC.md`](../../docs/migrations/binance-ALIGNMENT-SYNC.md) 与 runtime 仓 `CHANGELOG.md`。
> 本文件仅追踪**尚未修复或有意保留**的问题；它是 read-only projection，不是 Closure SSOT。
> 已关闭项归宿见文末「已关闭项摘要」。

- **Last-Updated**: 2026-07-08
- **Runtime-Version**: v0.14.0 (HEAD `0047d8a` + todo-cleanup-batch 待合入)
- **文档性质**：read-only projection；进度与验证以 ALIGNMENT-SYNC.md 为 SSOT

---

## P2 — 中优（可计划修复）

| # | 问题 | 位置 | 修复方案 |
|---|------|------|----------|
| P2-03 | CI 工作流重复：统一管线 `binance-ci.yml` 与 `build.yml`/`lint.yml`/`test.yml` 重叠；`security.yml` 与 `secrets-scan.yml`/`vuln-scan.yml` 三方交叉；`release.yml` 与 `release-cd.yml` 双轨 | `.github/workflows/`（12 个文件） | 保留主 CI，降级其余或删除重叠 job |
| P2-07 | `admin.go` `options ...any` 依赖注入缺乏类型安全（3 处签名） | `internal/client/admin.go:48,57,66` | 改为显式参数或 functional options（破坏性接口变更，需评估调用方影响） |

---

## P3 — 低优（可逐步改善）

| # | 问题 | 位置 | 修复方案 |
|---|------|------|----------|
| P3-03 | `handleSnapshotTopN` 每条事件新建 Book 对象（GC 压力） | `internal/client/orderbook/manager.go:669` | sync.Pool 复用 Book 对象 |
| P3-05 | `handleSnapshotTopN` 与 `StartTopNPusher.pushTopN` 双重 TopN 推送到同一 `topnCh` | `internal/client/orderbook/manager.go:688-702` + `StartTopNPusher:200-211` | 需设计决策：snapshot_topn 模式下是否禁用定时推送（当前可能是 feature：即时+兜底；需 SPEC 澄清） |

---

## 设计意图（非缺陷，不修复）

### 原生设计决策

- `option_tick` 无序列号检测（期权无连续序列号）
- `depth_rebuild_*` 不进对账（标记事件仅时间间隔检测）
- `lifecycle.supportedEventTypes` 不含 depth/option（由 orderbook/REST 覆盖）
- Mapper 不覆盖 depth/option（domainmarket 无 canonical 类型）
- `triggerRebuild` 使用 `context.Background()`（对齐是后台任务，设计选择）

### 有意保留的缓解决策（曾列入待修，经评估为不修）

- **Market API token 空值免鉴权**（原 P1-03，`internal/server/api/query.go:189`）：作为部署降级路径保留。生产部署应通过 `MARKET_API_TOKEN` 显式注入；不在代码层强制 fail-closed，避免阻塞本地开发与无 token 场景下的合法只读访问。如需硬化，应在部署侧（入口网关/反向代理）施加鉴权。
- **pprof 端点暴露**（原 P1-04，`internal/server/admin.go:130`）：已由 admin endpoint 的鉴权层覆盖。更严格的网络隔离（仅内网/IPv4 localhost）属于部署治理范畴，不在此仓 spec 范围内。
- **`MustMarshalInstrumentKey` panic**（原 P3-10，`internal/ingestcodec/instrumentkey.go:35`）：已重构为 Go `Must*` 惯例，注释明确"仅用于编程错误场景"，实际仅 test 调用。生产代码路径无 panic，原"生产代码 panic"关切已不成立。

---

## 变更历史指针

本文件的「修复进度」与「轮次验证结果」不在 projection 中追踪，统一以 SSOT 为准：

- **跨仓对齐 SSOT**：[`ALIGNMENT-SYNC.md`](../../docs/migrations/binance-ALIGNMENT-SYNC.md)
- **runtime 仓 CHANGELOG**：`github.com/ZoneCNH/binance` 的 `CHANGELOG.md`

避免在 projection 与 SSOT 之间双重追踪；如发现两者冲突，以 ALIGNMENT-SYNC.md 为准并在其处订正。

---

## 已关闭项摘要（2026-07-08 事实校验）

以下项已从本 todo 移除，记录其归宿：

| 原编号 | 归宿 | 说明 |
|--------|------|------|
| P1-07 | main 已修（`17dcdec` 之前） | `BackfillSplitRatio` env 桥接齐全（binancecfg `BACKFILL_SPLIT_RATIO` + cmd 桥接） |
| P1-08 | 本轮修复（binance PR #453） | `DispatchRetryBackoffs` env 桥接（`FOUNDATIONX_BINANCE_DISPATCH_RETRY_BACKOFFS`）+ `parseDurationList` + 3 个 test |
| P2-05 | main 已修（gocyclo nolint 全部移除） | `RunStandalone`/`buildStorage`/`detectGapByEventType`/`UpsertEntries` 已重构或不再触发警告 |
| P3-01 | 本轮修复（binance PR #453） | 删除 `validateAndApply` 死代码（零调用方） |
| P3-02 | 本轮修复（binance PR #453） | 抽取 `dropOldestAndSend` helper，去重 Dispatch vs run forwarder 通道满逻辑 |
| P3-04 | 本轮修复（binance PR #453） | `topnOnce`/`incrementalOnce` sync.Once 保护 `topnCh`/`incrementalCh` 懒初始化 |
| P3-06 | 本轮修复（binance PR #453） | `AIMDConfig` + `DefaultAIMDConfig()`，6 个 AIMD 常量可配置（零值向后兼容） |
| P3-07 | 本轮修复（binance PR #453） | `.env.example` 前缀 `XGO_BINANCE_*` → `FOUNDATIONX_BINANCE_*` + 注释订正（`XGO_BINANCE_DISPATCHER` bare env 例外保留） |
| P3-08 | 本轮修复（SASL_MECHANISM）+ main 已修（RECONCILE_HOUR） | `configs/binance-server.env.example` 补 `FOUNDATIONX_KAFKAX_SASL_MECHANISM=PLAIN` |
| P3-09 | 本轮修复（binance PR #453） | env.example 加注释说明 `ReconcileCronHour` 代码 fallback=4 vs 示例=2 的设计意图（低峰错峰） |
| P3-11 | 路径订正 | `internal/coverage` → `internal/server/coverage`；覆盖率持平（42.4%/45.0%/70.2%，orderbook 微降 1.8pp） |

**本轮验证**：binance runtime 仓 build PASS / vet PASS / 改动包 test PASS / orderbook race PASS / boundary-gates 15/15 PASS。

**待合入**：本轮 8 项代码修复在 binance PR #453（`fix/todo-cleanup-batch` branch）。
