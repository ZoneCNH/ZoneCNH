# Binance Subscription Governance — 对齐结论

> 基于 `design/DEEP-ANALYSIS-INDEX.md`、`design/EVENT-TYPE-MAPPING.md` 与 Plan 013 历史实施计划。
> 验证日期：2026-07-10。
> Plan 013 历史验证：30 次连续 build+test 通过。
> 本轮 closure audit：runtime implementation commit `3f6366728b635c32d73565874965d40c20a92caf`；针对最终 docs checker 状态的 20/20 轮重复检查 PASS；见 [`todo.md`](todo.md)、[`evidence/2026-07-10/review/todo-closure-20260710.md`](evidence/2026-07-10/review/todo-closure-20260710.md) 与 `/tmp/binance-final-20check-20260710-final2/SUMMARY.tsv`。[COMPUTED, HIGH]
> **Plan 013 修订（2026-07-09）**：白名单规则统一重构完成——7 套机制收敛为 PG 双表 1 套；tier 词表 `core/standard` → `prime/standard/lite/blocked`；`tierCapabilityMap` 三元组推导 SSOT；DepthLevel 全链路接通。下方 §4/§5/§13 及「配置文件清单」中标 ❌(Plan 013 删) 的项为已删除死代码，不再生效。

## 2026-07-10 发布 gate 对齐增补

| 项 | 当前对齐结论 |
| --- | --- |
| 文档 gate | `bash scripts/check-binance-docs.sh` 已从旧根 `module/binance/SPEC.md` SKIP 修复为扫描 goal-driven 目录，并在 2026-07-09 本仓通过。[COMPUTED, HIGH] |
| 标准 | `module/binance/gate/STANDARD.md` 已升级为发布与漂移标准，覆盖业务边界、产品线矩阵、canonical event_type、合约身份、options、order book、Foundation 依赖、发布证据和 gate 职责边界。[COMPUTED, HIGH] |
| 规则 | `module/binance/gate/RULES.md` 已同步 R1/R2/R13：指向 `spec/NAMING.md` 与 `gate/STANDARD.md`，并禁止 docs gate 因旧根 SPEC 缺失而 SKIP。[COMPUTED, HIGH] |
| runtime implementation | `/home/workspace/binance` feature branch 已落地 canonical `ticker/open_interest/index_reference/contract_info` 链路；implementation commit 为 `3f6366728b635c32d73565874965d40c20a92caf`。[COMPUTED, HIGH] |
| runtime evidence bundle | dated external ledger 已提交于 `660a3701589cc15fa95c7859fae02fad4863e1ad`，ledger 内 runner commit 绑定 implementation SHA。[COMPUTED, HIGH] |
| runtime 发布口径 | 当前仅有 last published tag `v0.15.1` @ `fc967053d7d8c21dba3c4e93962effbbbba0a70c`；本轮无新 tag、无部署、无回滚，故 runtime `release_closeable=NO`。[COMPUTED, HIGH] |
| 已补齐的本地证据 | full test/race/build/vet、boundary 15/15、drift、NATS 本地 JetStream 语义、Options depth fixture + public capture、release scripts 与 packet validator 均已纳入；它们不替代外部 durable/fanout/query E2E。[COMPUTED, HIGH] |
| 仍需外部 gate | `release/evidence/binance/20260710/external-gates.tsv` 当前记录 NATS/Kafka/TDengine/Redis/API 五项 `BLOCKED/NOT_RUN`；正式 tag/release notes、preflight 与 rollback 仍需人工授权和目标环境。[COMPUTED, HIGH] |

## Plan 013 修订摘要（2026-07-09）

| 维度 | Plan 013 前 | Plan 013 后 |
|------|-------------|-------------|
| symbol 控制机制 | 7 套（仅 3 套生效） | 1 套（PG 双表 SSOT） |
| tier 词表 | `core/standard`（2 档） | `prime/standard/lite/blocked`（4 档，禁止向后兼容） |
| 能力三元组 | 客户端零值/硬编码 | `tierCapabilityMap` 从 tier 推导（决策 5：PG 只存 tier 单列） |
| DepthLevel | 5 处断链，硬编码 L4 | 全链路接通（ObEntry→OrderbookWhitelist→obWantEntry→SubscribeWithFeatures→SyncSubscriptionsWithCapabilities） |
| 死代码 | whitelist.yaml/strategy_acl.yaml/features.yaml/tier_map/policy.Manager/WhitelistWatcher | 全部删除（Phase 1，commit 8985105） |
| 验证 | — | 15 boundary-gates 全过 + race 全绿 + options 回归 PASS |

> Plan 013 历史执行详见 [`plans/binance/013-whitelist-unification-plan-20260709.md`](../../plans/binance/013-whitelist-unification-plan-20260709.md)；当前 `todo.md` 已切换为 release readiness TODO 投影。

## 总体完成度

```
████████████████████ 100%  规格/治理实施投影完成；runtime 发布仍 BLOCKED
├── ██████████████████ 100%  访问控制 (Symbol/Stream/Feature/Depth + Hot-Reload)
├── ██████████████████ 100%  订阅管理 (SubscriptionPool + FanOut)
├── ██████████████████ 100%  连接治理 (ReconnectQueue + AntiBanEngine)
├── ██████████████████ 100%  速率治理 (On429 + Priority + Burst)
├── ██████████████████ 100%  资源治理 (AdaptiveManager)
└── ██████████████████ 100%  防封禁引擎 (AntiBanEngine)
```

## 13 章完成度

| § | 章节 | 实现 | 验证 |
|---|------|------|------|
| §1  | Symbol Whitelist    | ✅ Entry.Enabled + StreamWhitelist + PG 双表 SSOT（Plan 013） | 自动化 |
| §2  | Stream Whitelist    | ✅ StreamType 8位掩码 + streamConfig 接入 | 7 tests |
| §3  | OrderBook Whitelist | ✅ OrderbookFeatures 6位掩码（从 tier 推导，Plan 013） | 3 tests |
| §3+ | DepthLevel 分级     | ✅ L0-L4 全链路接通（tierCapabilityMap 驱动，Plan 013 §3） | 5 断链修复 |
| §4  | Feature Whitelist   | ❌ Plan 013 删（features.yaml 为死代码，能力改由 tier→tierCapabilityMap 推导） | — |
| §5  | 策略白名单           | ❌ Plan 013 删（strategy_acl.yaml 为死代码，follow-up 另开 plan） | — |
| §6  | IP 封禁原因          | ✅ 已分析 | — |
| §7  | Reconnect Manager   | ✅ ReconnectQueue 2/s 限速 + backoff | 集成 |
| §8  | Subscription Pool   | ✅ 引用计数 + FanOut | 11 tests |
| §9  | Connection Pool     | ✅ connection_pool.yaml 骨架 | config |
| §10 | Rate Limiter        | ✅ On429 + Priority + Burst | 7 tests |
| §11 | 自适应白名单         | ✅ AdaptiveManager CPU/Memory 驱动 | 6 tests |
| §12 | Anti-Ban Engine     | ✅ AntiBanEngine 连接风暴检测 | 3 tests |
| §13 | 配置文件拆分         | ✅ Plan 013 后精简：删 whitelist/features/strategy_acl.yaml 死代码；tier 配置改 env（`FOUNDATIONX_BINANCE_TIERS_*`） | 5 tests |

## 新增模块（超出原 13 章）

| 模块 | 说明 | 验证 |
|------|------|------|
| EtcdLock | etcd 原生 Leader 选举 | 7 unit + 4 integration |
| CircuitBreakerClient | 熔断器防 etcd 阻塞 | 12 tests |
| MarketFusion | 行情融合器 + TTL dedup | 10 tests |
| UMFuturesClient | USDS-M Futures REST SDK | 14 endpoints + HMAC |
| UMFuturesErrors | 限流/无效 symbol ���误处理 | 9 tests |

## 测试覆盖

| 包 | 测试数 | 状态 |
|----|--------|------|
| `pkg/binancecfg/` (config + watcher) | 13 | ✅ |
| `pkg/whitelistclient/` (Entry/Stream/Depth/Feature) | 26 | ✅ |
| `internal/client/` (governance) | 55+ | ✅ |
| `internal/server/cache/` (etcd/circuit) | 46 | ✅ |
| **合计** | **140+** | **ALL PASS** |

## 30 次验证通过

```
Phase 1: 10 passes (after streamConfig + ReconnectQueue)
Phase 2: 10 passes (after RateLimiter + SubscriptionPool + DepthLevel)
Phase 3: 10 passes (after AdaptiveManager + AntiBanEngine + config files)
────────────────────
30/30 ALL PASSES
```

## 配置文件清单 (Plan 013 后精简)

| 文件 | 状态 |
|------|------|
| `whitelist.yaml` | ❌ Plan 013 删（死代码，PG 双表为 SSOT） |
| `reconnect.yaml` | ✅ |
| `rate_limit.yaml` | ✅ |
| `connection_pool.yaml` | ✅ |
| `features.yaml` | ❌ Plan 013 删（死代码，能力由 tierCapabilityMap 推导） |
| `strategy_acl.yaml` | ❌ Plan 013 删（死代码，follow-up 另开 plan） |
| `anti_ban.yaml` | ✅ |
| `adaptive.yaml` | ✅ |
| `otel-collector.yaml` | ✅ (已有) |
| `binance-client.env.example` | ✅ (已有) |
| `binance-server.env.example` | ✅ (已有) |
| **tier env**（`FOUNDATIONX_BINANCE_TIERS_*`）| ✅ Plan 013 新增（CORE_SYMBOLS/CORE_QUOTE_VOLUME/STANDARD_QUOTE_VOLUME/BLOCKED_SYMBOLS） |

## 提交记录

| 提交 | 内容 |
|------|------|
| `0664bf2` | streamConfig StreamType 接入 |
| `446de16` | ReconnectQueue 全局重连队列 |
| `e48af2f` | Rate Limiter On429 + Priority + Burst |
| `6f7509e` | SubscriptionPool + FanOut |
| `a6e6620` | DepthLevel 分级 + Book.TopN |
| `5dccbf9` | EtcdLock 实现 |
| `5fbe669` | CircuitBreakerClient |
| `5518d19` | Health Probe |
| `6d136b4` | WhitelistWatcher 热加载 |
| `ab225d8` | AdaptiveManager |
| `d58155d` | MarketFusion 行情融合器 |
| `bee6966` | MarketFusion TTL dedup |
| `1cb0be9` | UMFuturesClient REST SDK |
| `7b002d8` | UMFuturesErrors 限流处理 |
| `65db015` | AntiBanEngine 防封禁引擎 |
| `8985105` | **Plan 013 Phase 1** 删白名单死代码（tier_map/whitelist_config/feature_acl/policy/3 个 yaml） |
| `3910085` | **Plan 013 Phase 2a** migration 018 tier 数据迁移 core→prime |
| *(本分支)* | **Plan 013 Phase 2-6** migration 017 CHECK + tierCapabilityMap + DepthLevel 全链路 + 4 档词表 + 文档同步 |

## 热加载特性

> ⚠️ Plan 013 删除了 `WhitelistWatcher`（fsnotify 文件监听）——经 PR #1742 核实为零生产引用死代码。白名单变更改由 PG 双表 + 服务端 API 增量推送（`whitelistclient` cache 刷新）驱动，不再依赖本地 YAML 热加载。下表为历史记录，已不生效。

| 功能 | 状态 |
|------|------|
| fsnotify 文件监听 | ❌ Plan 013 删（WhitelistWatcher 死代码） |
| 模块级路径解析 | ❌ Plan 013 删 |
| 500ms debounce | ❌ Plan 013 删 |
| context 优雅关闭 | ❌ Plan 013 删 |
| PG 增量推送 + cache 刷新 | ✅ Plan 013 后的权威路径 |
