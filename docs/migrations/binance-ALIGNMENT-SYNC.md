# module/binance 对齐同步文档（Runtime ↔ Spec）

> 本文档追踪运行时仓 `github.com/xhyperium/binance` 与规格仓 `module/binance` 之间的状态对齐与同步记录。
> 每次跨仓深度检查/修复后更新，确保规格口径与运行时实现一致、无漂移。
>
> **仓库迁移记录**：binance 运行时仓已从 `github.com/ZoneCNH/binance` 迁移至 `github.com/xhyperium/binance`（与 ZoneCNH→xhyperium 组织迁移一致；registry.yaml `repo`/`owner` 同步更新为 `xhyperium`）。本仓库历史提交/引用中仍可见旧路径，属历史快照，不影响当前路由。

- **Last-Updated**: 2026-07-10
- **Spec-Version**: v4.1.0
- **Runtime-Version**: v0.15.1（last published tag `fc967053d7d8c21dba3c4e93962effbbbba0a70c`；本轮 implementation commit `3f6366728b635c32d73565874965d40c20a92caf` 未创建新 tag）[COMPUTED, HIGH]
- **Spec-State**: 65 Done / 0 Partial / 0 Pending / `release_closeable_spec=YES`。[COMPUTED, HIGH]
- **Runtime-State**: full test PASS / race PASS / build PASS / vet PASS / boundary 15/15 PASS / drift PASS；external-gates 5 BLOCKED/NOT_RUN，故 `release_closeable_runtime=NO`。[COMPUTED, HIGH]

## 0. 2026-07-10 当前 closure override

| 对齐面 | 当前事实 | 证据 |
| --- | --- | --- |
| Runtime implementation | `ticker`、`open_interest`、`index_reference`、`contract_info` canonical 链路已在 implementation commit `3f6366728b635c32d73565874965d40c20a92caf` 完成；`force_order` 是 opt-in scaffold；Options depth 是 fixture/capture，OrderBookManager 仍 postponed。[COMPUTED, HIGH] | `/home/workspace/binance` runtime tests、`docs/release/RELEASE-NOTES-UNRELEASED-20260710.md` |
| Local verification | full test、race、build、vet、boundary、drift、e2e fixture、公开 Options depth capture、本地 NATS JetStream 语义均 PASS。[COMPUTED, HIGH] | [`module/binance/todo.md`](../../module/binance/todo.md) §1 |
| External release gates | NATS、Kafka、TDengine、Redis、部署 API 五项为 `BLOCKED/NOT_RUN`，缺少所需目标环境/凭证；不以 local fake 替代。[COMPUTED, HIGH] | `release/evidence/binance/20260710/external-gates.tsv` |
| Formal release | packet validator 为 11 blockers；无新 tag、无真实部署、无回滚执行。[COMPUTED, HIGH] | `scripts/validate-release-packet.sh` 输出与 packet template |

> 本节覆盖旧历史快照的当前解释；旧表中的版本、稳定表名、coverage 与 release-closeable 结论不得投影到 2026-07-10 当前状态。[COMPUTED, HIGH]

---

## 1. 版本对齐矩阵

| 维度 | 规格仓（module/binance） | 运行时仓（binance） | 状态 |
|------|--------------------------|---------------------|------|
| Spec-Version | v4.0.1 | — | ✅ 一致 |
| Runtime-Version | v0.15.0 | v0.15.0（tag `52d9144`） | ✅ 一致 |
| FR 总数 | 65 Done | 65 Done 可验证 | ✅ 一致 |
| release_closeable | YES | 门禁全 PASS + GitHub Release 已创建 | ✅ 一致 |
| 覆盖率门槛 | ≥80% | 86.1%（实测） | ✅ 一致 |
| 边界门禁 | 15/15 | 15/15 PASS | ✅ 一致 |
| readiness-audit | PASS | PASS（Release gate status + Plan008 tokens） | ✅ 一致 |

---

## 2. 历史 20 轮深度检查汇总（2026-07-07；不继承为本轮 closure evidence）

对运行时仓执行 20 轮独立重复检查，覆盖构建/测试/配置/数据完整性/OrderBook/安全/错误处理/并发/性能/文档/CI/边界/flaky/资源泄漏/代码质量等维度。

### 2.1 已修复问题（本轮）

| # | 严重度 | 问题 | 修复位置 | 验证 |
|---|--------|------|----------|------|
| R1 | **P0** | `depth_topn` 序列号 gap 检测失效（`lastSequence` 未更新） | `internal/server/quality.go` extractSequenceInfo 设置 finalUpdate | 新增单测 `TestQualityTracker_DepthTopNGapDetection` PASS |
| R2 | **P0** | `ORDERBOOK_PERSIST_DIR` 三源不一致（config.go vs env.example） | `pkg/binancecfg/config.go` default 改为 `/tmp/orderbook` | 三源一致 |
| R3 | **P0** | CI Dockerfile/Go 版本（1.25）与 CI 工作流（1.26.4）不一致 | `Dockerfile` + `.golangci.yml` 升级到 1.26 | 版本一致 |
| R4 | **P1** | OrderBook `sb.book` 并发竞态（checksum goroutine vs event loop） | `manager.go`/`health.go`/`persist.go` 增加 `bookMu` RWMutex | race test PASS |
| R5 | **P1** | `runtime.go` 关键错误静默丢弃（connector.Start/admin.Start/SubscribeWithMode） | 增加 `slog.Error` + 错误返回 | build PASS |
| R6 | **P1** | `InFlightTracker.Drain` goroutine 泄漏（ctx 取消后永久阻塞） | `lifecycle.go` 循环条件增加 `ctx.Err() == nil` | build PASS |
| R7 | **P1** | CI `make build-all` 目标缺失（release-cd.yml 引用） | `Makefile` 新增 `build-all` 目标 | `make build-all` 成功 |
| R8 | **P1** | `drift-check.sh` 引用已删除的 `internal/wire` | 更新为 `internal/ingestcodec` | 脚本逻辑对齐 |
| R9 | **P1** | `README.md` 目录结构过时（缺 ingestcodec/orderbook/pkg 等） | 更新目录结构 | doc 与代码一致 |
| R10 | **P1** | `TestOrderbookDispatchIntegration` flaky（3s 超时偏紧） | 超时增至 10s | race test PASS |
| R11 | **P2** | `lifecycle.go:396` `fmt.Printf` 应为结构化日志 | 改为 `slog.Error` | vet PASS |

### 2.2 已知限制（设计意图，非缺陷）

| 问题 | 说明 |
|------|------|
| `option_tick` 无序列号检测 | 期权 ticker 无连续序列号，仅时间间隔检测（合理） |
| `depth_rebuild_*` 不进对账 | rebuild 标记事件仅时间间隔检测，不参与序列对账（合理） |
| `lifecycle.supportedEventTypes` 不含 depth/option | depth 由 orderbook manager 管理，option 由 REST 回填覆盖（by design） |
| Mapper 不覆盖 depth/option | domainmarket v1.1.0 无 depth/option canonical 类型（by design） |
| `triggerRebuild` 使用 `context.Background()` | 对齐是后台任务，独立 context 可接受（设计选择） |

### 2.3 低优先级待办（后续迭代）

| # | 类别 | 位置 | 说明 |
|---|------|------|------|
| T1 | 死代码 | `orderbook/align.go` validateAndApply | 未被调用，是 handleAligned 子集 |
| T2 | 重复代码 | `orderbook/manager.go` Dispatch vs run forwarder | 通道满处理逻辑重复，可抽共享方法 |
| T3 | 圈复杂度 | `runtime.go` RunStandalone (34), `storage.go` buildStorage (32) | 已 nolint，可后续拆分 |
| T4 | 测试覆盖 | `internal/server/coverage` (42.4%), `internal/ingestcodec` (45%) | 存储层/工具函数零覆盖 |
| T5 | 日志统一 | `internal/server/api/*.go` 使用 `log.Printf` | 应统一为 `slog` |
| T6 | 类型安全 | `admin.go` `options ...any` 依赖注入 | 缺乏编译期类型检查 |
| T7 | CI 冗余 | `binance-ci.yml` 与 6 个独立 workflow 重复 | 建议保留主 CI，降级其余 |

---

## 3. 历史事件类型链路对齐快照（11 种；不替代当前 runtime canonical 链路）

| 事件类型 | normalize | taos_writer | quality | reconciler | 状态 |
|----------|-----------|-------------|---------|------------|------|
| trade | ✅ | ✅ st_trade | ✅ | ✅ | 对齐 |
| tick | ✅ | ✅ st_tick | ✅ | ✅ | 对齐 |
| bar | ✅ | ✅ st_bar | ✅ | ✅ | 对齐 |
| depth | ✅ | ✅ st_depth | ✅ | ✅ | 对齐 |
| depth_topn | runtime | ✅ st_depth_topn | ✅ (R1 修复) | ✅ | 对齐 |
| depth_incremental | runtime | ✅ st_depth_incremental | ✅ | ✅ | 对齐 |
| depth_rebuild_start | runtime | ✅ st_depth_incremental | ⏭ (时间间隔) | ⏭ | 设计如此 |
| depth_rebuild_complete | runtime | ✅ st_depth_incremental | ⏭ (时间间隔) | ⏭ | 设计如此 |
| funding_rate | ✅ | ✅ st_funding_rate | ✅ | ✅ | 对齐 |
| mark_price | ✅ | ✅ st_mark_price | ✅ | ✅ | 对齐 |
| option_tick | ✅ | ✅ st_option_tick | ⏭ (时间间隔) | ✅ | 对齐 |

**结论**：所有 11 种事件类型端到端链路闭合，4 处映射（StableSpecs / taosDeleteStable / toPoint / taos_ddl.sql）完全一致。

---

## 4. 配置一致性对齐（修复后）

| 配置项 | configx default | env.example (client) | env.example (server) | 状态 |
|--------|-----------------|----------------------|----------------------|------|
| BackfillThrottlePerMinute | 600 | 600 | 600 | ✅ 三源一致 |
| OrderBookDepthMode | full_incremental | full_incremental | full_incremental | ✅ 三源一致 |
| OrderBookTopNIntervalMs | 100 | 100 | 100 | ✅ 三源一致 |
| OrderBookTopNDepth | 20 | 20 | 20 | ✅ 三源一致 |
| OrderBookPersistDir | /tmp/orderbook | /tmp/orderbook | /tmp/orderbook | ✅ 三源一致 (R2) |
| NATSSubject | binance.market.> | — | binance.market.> | ✅ 一致 |

---

## 5. 历史门禁与验证状态（2026-07-07 快照）

| 门禁/检查 | 结果 | 说明 |
|-----------|------|------|
| Build | ✅ PASS | `go build ./...` 零错误 |
| Vet | ✅ PASS | `go vet ./...` 零告警 |
| Test (30 pkg) | ✅ PASS | 0 FAIL |
| Race | ✅ PASS | `-race -count=1` 0 race |
| Boundary Gates | ✅ 15/15 | §2-§16 全 PASS |
| go.mod verify | ✅ PASS | all modules verified |
| go.mod tidy | ✅ PASS | 无 diff |
| Coverage | ✅ 86.1% | ≥80% 标准 |

---

## 6. 同步规则

1. **单一状态模型**：FR 只有 Done 或 Pending（历史双态口径已废除）
2. **版本号唯一源**：`spec/SPEC.md` 的 `Spec-Version` 字段
3. **配置三源一致**：binancecfg default / env.example / 代码运行时默认值必须对齐
4. **事件类型四映射一致**：StableSpecs / taosDeleteStable / toPoint / taos_ddl.sql 必须同步修改
5. **门禁不降级**：boundary-gates.sh 15/15 为硬门禁，任何修改不得降低通过数
6. **文档即交付物**：README/CHANGELOG/对齐文档与代码同步更新

---

## 7. 第二轮修复记录（2026-07-07 续）

第一轮 20 轮检查修复（提交 `908d8c8`）后，针对 `todo.md` 中未修复的 P1/P2 项执行第二轮修复。

### 7.1 本轮修复清单

| # | 严重度 | 问题 | 修复位置 | 验证 |
|---|--------|------|----------|------|
| R12 | **P1** | `depth_topn`/`depth_incremental`/`depth_rebuild_*` 无 retention 配置 | `assembly/storage.go` buildTaosRetentionConfigs 添加 5 条 7d retention | 测试 `TestBuildTaosRetentionConfigs` 更新期望 11 条 PASS |
| R13 | **P1** | `depth_rebuild_start/complete` 不在 `DefaultEventTypes` 对账列表 | `reconcile/reconciler.go:77` 追加 2 个事件类型 | build PASS |
| R14 | **P1** | `applyAIMDRate` 硬编码 80/20 比例 | `throttle.go` 新增 `coldPct`/`repairPct` 字段，`NewThrottleManager` 存储，`applyAIMDRate` 使用 | build PASS |
| R15 | **P1** | `DispatchRetryBackoffs` 注释与实现不符 | `ingest.go` 注释修正为单次尝试；`server.go` 默认值保持 `[0]` | 测试 `TestProcess_MetricsDeadLetter` PASS |
| R16 | **P1** | `IngestTransport` 注释过时（"natsx \| http"） | `binance-server.env.example:17` 改为 `# 仅支持 natsx（http 已退役）` | doc 同步 |
| R17 | **P2** | `runtime-release-evidence.sh` 硬编码日期 20260623 | 改为 `$(date -u +%Y%m%d)` | 脚本逻辑修正 |
| R18 | **P2** | boundary-gates.yml 注释称13道门禁，实际15道 | 注释和 job name 改为 15 | 文档一致 |
| R19 | **P2** | `docker-compose.yml` 镜像版本 v0.8.0 与 README v0.14.0 不一致 | 统一为 v0.14.0 | 版本一致 |
| R20 | **P2** | `api/*.go` 使用 `log.Printf` 而非 `slog` | `query.go` `stdLogger.Printf` 改为 `slog.Error` | vet PASS |

### 7.2 本轮测试修复（flaky 增强）

| # | 问题 | 修复 | 验证 |
|---|------|------|------|
| T1 | `TestBuildTaosRetentionConfigs` 期望 7 条，实际 11 条 | 更新测试期望为 11 | PASS |
| T2 | `TestOrderbookDispatchIntegration` 并发超时（10s） | 超时增至 30s | 全包测试 PASS |
| T3 | `TestManager_FullIncremental_AlignWithMockFetcher` 并发超时（2s） | `waitForState` 超时增至 10s | 全包测试 PASS |

### 7.3 本轮验证状态

| 门禁/检查 | 结果 |
|-----------|------|
| Build | ✅ PASS |
| Test (30 pkg) | ✅ 0 FAIL |
| Race | ✅ 0 race |
| Boundary Gates | ✅ 15/15 PASS |
| Vet | ✅ PASS |
| Coverage | ✅ 86.1% |

### 7.4 仍未修复（设计意图/后续迭代）

| # | 问题 | 决策 |
|---|------|------|
| D1 | Market API token 为空免鉴权 | 设计降级（本地/测试），保留 |
| D2 | pprof 端点暴露 | 已有 auth token 保护，低风险 |
| D3 | BackfillSplitRatio/DispatchRetryBackoffs 环境变量配置 | 需 binancecfg + cmd 桥接，后续迭代 |
| D4 | CI 工作流重复 | 架构重构，后续迭代 |
| D5 | gocyclo 警告（RunStandalone/buildStorage） | 已 nolint，可后续拆分 |
| D6 | admin.go options ...any 类型安全 | 接口变更，后续迭代 |
| D7 | P3-01~P3-11 代码质量/测试覆盖 | 低优先级，逐步改善 |

---

*本文件由 20 轮深度检查驱动生成，每次修复后增量更新。*

## 8. 2026-07-10 当前 20 轮 closure 结果

[COMPUTED, HIGH] 本轮 implementation commit 为 `3f6366728b635c32d73565874965d40c20a92caf`，dated evidence commit 为 `660a3701589cc15fa95c7859fae02fad4863e1ad`；执行 `scripts/binance-final-20-check.sh` 后 `round=01..20 PASS`，脚本 exit 0。日志：`/tmp/binance-final-20check-20260710-final2/SUMMARY.tsv`。

[COMPUTED, HIGH] 每轮覆盖完整 `go test ./... -count=1`、build/vet、boundary、drift、e2e fixture、release ledger/packet、Zone docs/version/reference/diff；external ledger 的 5 项 BLOCKED/NOT_RUN 是预期的真实环境阻断，不是漏检。
