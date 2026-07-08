# module/binance TODO — 未修复问题追踪（read-only projection）

> 截至 2026-07-08 第二轮事实校验 + 全部修复已合并。已修复的 P0/P1/P2 见
> [`ALIGNMENT-SYNC.md`](../../docs/migrations/binance-ALIGNMENT-SYNC.md) 与 runtime 仓 `CHANGELOG.md`。
> 本文件仅追踪**尚未修复或有意保留**的问题；它是 read-only projection，不是 Closure SSOT。
> 已关闭项归宿见文末「已关闭项摘要」。

- **Last-Updated**: 2026-07-08（全部修复已合并）
- **Runtime-Version**: v0.14.0 (main HEAD `e06466e`，含全部修复)
- **文档性质**：read-only projection；进度与验证以 ALIGNMENT-SYNC.md 为 SSOT

---

## P2 — 中优

| # | 问题 | 位置 | 状态 |
|---|------|------|------|
| P2-03 | CI 工作流重复（gitleaks/govulncheck 三方交叉，release tag 双触发） | `.github/workflows/` | **分析完成 + DEPRECATED 标注**（binance PR #456 已合并）；实际删除/合并需 repo admin 核对分支保护 required checks + release 双触发人工决策。security.yml 已标 DEPRECATED，release.yml 已标竞态警告。 |

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

## 已关闭项摘要（2026-07-08 两轮事实校验，全部已合并）

以下项已从本 todo 移除，记录其归宿：

### 第一轮（binance PR #453，已 MERGED）

| 原编号 | 说明 |
|--------|------|
| P1-07 | main 已修：`BackfillSplitRatio` env 桥接齐全 |
| P1-08 | `DispatchRetryBackoffs` env 桥接（`FOUNDATIONX_BINANCE_DISPATCH_RETRY_BACKOFFS`）+ `parseDurationList` + 3 test |
| P2-05 | main 已修：gocyclo nolint 全部移除 |
| P3-01 | 删除 `validateAndApply` 死代码（零调用方） |
| P3-02 | 抽取 `dropOldestAndSend` helper，去重 Dispatch vs run forwarder 通道满逻辑 |
| P3-04 | `topnOnce`/`incrementalOnce` sync.Once 保护懒初始化 |
| P3-06 | `AIMDConfig` + `DefaultAIMDConfig()`，6 个 AIMD 常量可配置（零值向后兼容） |
| P3-07 | `.env.example` 前缀 `XGO_BINANCE_*` → `FOUNDATIONX_BINANCE_*` + 注释订正 |
| P3-08 | `configs/binance-server.env.example` 补 `FOUNDATIONX_KAFKAX_SASL_MECHANISM=PLAIN`（RECONCILE_HOUR main 已修） |
| P3-09 | env.example 加注释说明 `ReconcileCronHour` 代码 fallback=4 vs 示例=2 的设计意图 |
| P3-11 | 路径订正：`internal/coverage` → `internal/server/coverage` |

### 第二轮（binance PR #454/#455/#456/#457/#458，全部已 MERGED）

| 原编号 | 说明 |
|--------|------|
| P3-03 | PR #454：`handleSnapshotTopN` 通过 `bookPool`（sync.Pool）+ `Book.Reset()` 复用 Book 对象，减少 GC 压力 |
| P3-05 | PR #454：`pushTopN` 跳过 `DepthModeSnapshotTopN` 模式 books，消除双重推送 |
| P2-07 | PR #455：`NewAdminServer` 的 `options ...any` → `...AdminOption`（8 个 `With*` 函数），编译期类型安全 |
| P2-03 | PR #456：CI 去重分析 + security.yml DEPRECATED 标注 + release.yml 竞态警告（实际删除待 admin） |
| (CI) | PR #457/#458：self-hosted runner Go toolchain 修复（`GOTOOLCHAIN=local` + `go env -w GOROOT`） |

**所有修复已合并到 binance main**（HEAD `e06466e`）。验证：build/vet/test/race/boundary-gates 15/15。
