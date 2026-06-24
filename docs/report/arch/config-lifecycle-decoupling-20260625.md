# 配置与生命周期解耦 — 彻底解耦架构报告（2026-06-25 更新验证）

- **Date**: 2026-06-25（更新验证）
- **Scope**: 20 个基座模块 + 5 个领域共享层模块 + `module/binance`
- **核心原则**: 配置"读取机制"与"语义归属"分离；生命周期编排由 composition root 统一执行
- **证据基础**: go.mod require + `.go` import 代码级扫描（2026-06-25 实时证据线）

## 1. 核心原则

```text
┌─────────────────────────────────────────────────────┐
│ configx ── 读取机制层                                │
│   source/merge/decode/secret binding/redaction        │
│   provenance/配置快照                                 │
│   ★ 不知道任何业务键的语义                            │
├─────────────────────────────────────────────────────┤
│ 各 FoundationX 模块 ── typed Config 层               │
│   natsx.Config / redisx.Config / postgresx.Config     │
│   defaults + Validate()                               │
│   ★ 不读业务配置文件，不依赖 binance                  │
├─────────────────────────────────────────────────────┤
│ module/binance ── 业务语义层                          │
│   endpoint / product_lines / symbol policy            │
│   ack policy / storage policy / fanout policy         │
│   ★ 不拥有 infra connection pool config               │
│   ★ 不解析 env/secrets                                │
├─────────────────────────────────────────────────────┤
│ cmd/* assembly ── 装配层                              │
│   调用 configx → decode → 拆分配置                    │
│      → 传给 natsx.Config / redisx.Config / ...        │
│      → 传给 binance core constructor                  │
│   ★ 不重新校验业务规则                                │
└─────────────────────────────────────────────────────┘
```

## 2. 配置所有权分层

| 层 | 负责内容 | 不负责内容 | 代码实证 |
|----|---------|-----------|---------|
| `configx` | source/merge/decode/env/secret binding/redaction/provenance/配置快照 | Binance 产品线/NATS subject/Redis key/TAOS retention 的业务语义 | 零 ZoneCNH require，是纯机制层；binance 经 `pkg/binancecfg/config.go:23` 调 `configx.NewAllEnvSource` |
| 各 FoundationX 模块 | 自己的 typed Config/defaults/`Validate()`，如 `natsx.Config`/`redisx.Config` | 业务配置文件、binance | 各 infra 模块零业务 require |
| `module/binance` | Binance endpoint/product lines/subscription filters/symbol policy/ack/storage/fanout/archive/API policy | infra connection pool config、自建 env/file/vault loader | `pkg/binancecfg` 已提供 per-module typed DTO 聚合；production `internal/**` 无直接 `os.Getenv` |
| `cmd/*` assembly | 将 configx/binancecfg decode 结果拆分传给各 owner constructor | 重新校验业务规则 | `cmd/binance-client/main.go` 已接入 `binancecfg.Load(ctx)`；`cmd/binance-server/main.go` 仍残留 `os.Getenv("MODE")`、`os.Getenv("XGO_BINANCE_KAFKA_BROKERS")` |

### 2.1 当前状态：核心层 PASS，装配入口部分收敛

[COMPUTED, HIGH] `pkg/binancecfg` 已经通过 `configx.NewAllEnvSource` 聚合 8 个 `FOUNDATIONX_*` 前缀，且 `pkg/binancecfg/config_test.go` 覆盖了 `Load`。

**2026-06-25 验证更新**：
- `cmd/binance-client/main.go` → ✅ 已改为 `binanceCfg, err := binancecfg.Load(ctx)`
- `cmd/binance-server/main.go` → ⚠️ 仍直接读取：
  - `os.Getenv("MODE")` — 判断是否 test 模式
  - `os.Getenv("XGO_BINANCE_KAFKA_BROKERS")` — Kafka brokers 列表
  - 其他 `os.Getenv(key)` 调用 — 残留配置路径
- `cmd/binance-smoke/main.go` → 测试工具，允许直接读 env

### 2.2 os.Getenv 分布矩阵

| 位置 | os.Getenv 调用 | 性质 | 判定 |
|------|---------------|------|------|
| `internal/**` | 仅 `_test.go` 中的 `BINANCE_NATSX_INTEGRATION` | 集成测试跳过逻辑 | ✅ 合法 |
| `cmd/binance-client/main.go` | `os.Getenv("XGO_BINANCE_STREAMS")` | 经 `binancecfg.Load` 后的补充覆盖 | ⚠️ 应纳入 binancecfg |
| `cmd/binance-server/main.go` | `os.Getenv("MODE")`, `os.Getenv("XGO_BINANCE_KAFKA_BROKERS")` 等 | 直接读取，未经 binancecfg | ❌ 待收敛 |
| `cmd/binance-smoke/main.go` | 多个 `os.Getenv` | 冒烟测试工具 | ✅ 合法 |

## 3. 生命周期阶段（8 阶段顺序）

```
1. configx load/merge/decode 配置
   └─→ 生成 provenance/redaction evidence

2. 各模块 Validate()
   └─→ 失败时不创建外部连接

3. bootstrap 创建 kernel primitives
   ├─→ observex (logger/metrics/tracing/health)
   ├─→ resiliencx (默认运行时弹性策略)
   └─→ schedulex

4. bootstrap 创建 concrete infra clients
   ├─→ natsx / redisx / postgresx / taosx
   ├─→ kafkax / ossx / clickhousex
   └─→ 所有连接池在此阶段建立

5. binance cmd/* assembly 注入
   ├─→ 将 concrete clients 包成 ports
   └─→ 注入 internal/client / internal/server

6. bootstrap 按依赖顺序 start
   ├─→ observability first
   ├─→ infra clients
   ├─→ consumer/publisher
   ├─→ Binance client/server
   └─→ scheduler jobs → readiness

7. Runtime: Binance core 只做业务判断
   ├─→ validation
   ├─→ idempotency key
   ├─→ storage/fanout/archive 成功条件
   └─→ Ack/Nak policy

8. Shutdown
   ├─→ 取消 readiness
   ├─→ drain subscriptions/jobs
   ├─→ stop Binance server/client
   └─→ 关闭 infra clients + observability flush
```

## 4. 配置注入模式（代码示例）

```go
// ✅ 正确：assembly 层读取环境变量，构造各模块 Config，注入 core
// cmd/binance-server/main.go
func main() {
    ctx := context.Background()

    // 1. 用 configx 加载
    cfg, err := binancecfg.Load(ctx)   // → 内部调用 configx.NewAllEnvSource
    if err != nil { log.Fatal(err) }

    // 2. 构造 infra configs
    natsCfg := natsx.Config{
        URL:      cfg.NATS.URL,
        Stream:   cfg.NATS.Stream,
        // ...
    }

    // 3. 创建 infra clients
    nc, _ := natsx.New(ctx, natsCfg)
    rc, _ := redisx.New(ctx, redisCfg)

    // 4. 注入 binance core（core 只持有 interface，不知道 env）
    client := bincore.NewServer(
        bincore.WithNATS(nc),
        bincore.WithRedis(rc),
        // ...
    )
    client.Run(ctx)
}
```

```go
// ❌ 错误：core 包内直接读 env、构造 infra client
// internal/client/runtime.go (已修复：该函数已移除)
func NewRuntime(...) *Runtime {
    nc, _ := natsx.New(ctx, natsCfg)  // ← 这属于 assembly，不属于 core
    // ...
}
```

## 5. Ack 语义的配置/生命周期归属

[COMPUTED, HIGH] Ack 语义属于 `module/binance` 的业务 policy；ManualAck/Nak primitive 属于 `natsx`。

| 层面 | 归属 | 不归属 |
|------|------|--------|
| ManualAck/Nak primitive | `natsx` | binance 不实现自己的 Ack 机制 |
| "storage + fanout 成功后才 Ack" | `module/binance` | `natsx` 不决定何时 Ack |
| NakWithDelay(5s) 策略 | `module/binance` | `natsx` 只提供 Nak 能力 |
| MaxDeliver(5) → Dead Letter | `natsx` 提供机制 | `module/binance` 选择参数 |

## 6. 反模式警示

| 反模式 | 示例 | 正确做法 |
|--------|------|---------|
| core 包内 os.Getenv | `internal/client/config.go: os.Getenv("NATS_URL")` | 移到 `cmd/*/main.go`，经 configx 加载后注入 |
| mega Config 类型 | `type BinanceConfig struct { NATS NATSConfig; Redis RedisConfig; ... }` | 各模块只声明自己的 Config，assembly 负责组装 |
| core 内构造 infra client | `internal/client/runtime.go: natsx.New(...)` | 移到 assembly；core 只接收注入的 interface |
| 弱类型 config map | `map[string]interface{}` 在 core 间传递配置 | 使用 typed Config struct |
| assembly 中校验业务规则 | `if len(cfg.Symbols) < 1 { panic(...) }` | 在 Config.Validate() 中定义，assembly 只调用 Validate() |

## 7. 迁移清单

| # | 任务 | 优先级 | 状态 |
|---|------|-------|------|
| 1 | `cmd/binance-server` 统一从 `binancecfg.Load(ctx)` 获取配置 | HIGH | ⚠️ 待执行（client 已完成） |
| 2 | 移除 `cmd/binance-server` 中的 `os.Getenv("MODE")` | HIGH | ⚠️ 待执行 |
| 3 | 移除 `cmd/binance-server` 中的 `os.Getenv("XGO_BINANCE_KAFKA_BROKERS")` | HIGH | ⚠️ 待执行 |
| 4 | `cmd/binance-client` 中 `os.Getenv("XGO_BINANCE_STREAMS")` 纳入 binancecfg | MED | ⚠️ 待执行 |
| 5 | 各模块补充 `Validate()` 方法，在 bootstrap start 前执行 | MED | 部分完成 |
| 6 | 统一所有模块的配置环境变量前缀为 `FOUNDATIONX_*` | LOW | 部分完成 |

## 8. 结论

[COMPUTED, HIGH] 配置/生命周期解耦在核心层已经成立：
- `configx` 是纯机制层，不拥有任何业务语义
- binance production `internal/**` 无直接 `os.Getenv`（仅测试文件）
- `bootstrap` 仅由 assembly 调用，core 层零引用
- config 机制 (`configx`) 与 config 语义 (各模块 typed Config) 已分离
- **2026-06-25 更新**：`cmd/binance-client` 已接入 `binancecfg.Load`；`cmd/binance-server` 仍残留 3+ 处 `os.Getenv` 直接读取

剩余工作聚焦于 **装配入口收敛**：让 `cmd/binance-server` 也统一走 `binancecfg.Load` → 拆分配置 → 注入构造函数的正规路径。

[RULES I BROKE]: 无
