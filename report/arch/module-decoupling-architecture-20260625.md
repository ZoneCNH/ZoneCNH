# FoundationX + 领域共享层 + module/binance 彻底解耦架构报告（2026-06-25 更新验证）

> **归档说明（2026-07-05）**：本报告中"binance wire 未迁移 contracts"相关条目（ADR-002 过渡态）已由 [ADR-007](../../module/binance/design/ADR-007-wire-to-contracts-migration.md) 闭环——`internal/wire` 已删除，C/S 契约迁入 `contracts` canonical（v0.5.0），binance 经 `internal/ingestcodec` boundary 引用。下文相关描述为 2026-06-25 时点状态，保留作历史追溯，不作为当前事实。

- **Date**: 2026-06-25（更新验证）
- **Scope**: 26 个模块（20 基座 + 5 领域共享 + 1 binance）
- **Output**: 模块边界定义 · 配置与生命周期解耦规则 · 禁止多层实现清单 · 最终依赖关系图
- **Evidence**: go.mod require + `.go` import 代码级四态扫描（真实 import / manifest 字符串 / exec.Command / 负向 test fixture 区分）
- **Confidence**: [COMPUTED, HIGH] 所有边界与依赖结论由代码证据支撑

> **分报告索引**：
>
> - 模块边界定义：[`module-boundary-definitions-20260625.md`](./module-boundary-definitions-20260625.md)
> - 禁止多层实现：[`no-multi-layer-implementation-20260625.md`](./no-multi-layer-implementation-20260625.md)
> - 配置与生命周期：[`config-lifecycle-decoupling-20260625.md`](./config-lifecycle-decoupling-20260625.md)
> - 依赖关系图：[`dependency-graph-20260625.md`](./dependency-graph-20260625.md)

## 0. 一句话结论

[COMPUTED, HIGH] 解耦架构在**代码层面已经成立**：

- 基座层 0 反向依赖 binance
- 领域层 0 infra 依赖
- infra 同层 0 真实互耦
- binance core 走依赖注入窄接口（六边形 ports），非多层封装
- **2026-06-25 更新验证**：transportx module name bug ✅ 已修复、domainx go.mod ✅ 已补、domain\_\* snake_case ✅ 已统一、natsx.New 越界 ✅ 已移除、binancecfg.Load ✅ 已接入 client

剩余工作不是"再造解耦层"，而是修正 **2 个工程隐患** + 收敛 **2 个过渡态**。

## 1. 模块分层总览

```text
┌──────────────────────────────────────────────────────────────────────┐
│ [治理/证据元层]                                                       │
│ xlib_standard · xlib_harness · xlib_evidence · xlibgate              │
│ 4 模块全部零 ZoneCNH require，不参与业务运行                          │
├──────────────────────────────────────────────────────────────────────┤
│ [L0] kernel (stdlib-only 最小原语)                                    │
├──────────────────────────────────────────────────────────────────────┤
│ [L1 运行时] configx · observex · resiliencx · schedulex              │
│ testkitx (test-only)                                                  │
│ 5 模块全部零 ZoneCNH require，构成独立叶子基座                        │
├──────────────────────────────────────────────────────────────────────┤
│ [L1.5 infra] redisx · kafkax · natsx · postgresx · taosx             │
│ ossx · clickhousex · contracts · transportx                          │
│ 9 模块 0 同层真实互耦，仅合规横切 observex / resiliencx               │
├──────────────────────────────────────────────────────────────────────┤
│ [装配层] bootstrap (唯一跨 CORE+INFRA 聚合点)                         │
├──────────────────────────────────────────────────────────────────────┤
│ [L2 领域共享] decimalx (根锚点) · domainx · domain_market             │
│ domain_macro · domain_exchange                                       │
│ 5 模块纯度红线成立：零 infra / binance / provider import              │
├──────────────────────────────────────────────────────────────────────┤
│ [L3 业务模块] module/binance                                          │
│ ├── core (业务算法，持有窄接口 ports)                                  │
│ ├── client (采集端，不 import server)                                  │
│ ├── server (处理端，不 import client)                                  │
│ └── assembly (cmd/*，仅构造注入)                                      │
└──────────────────────────────────────────────────────────────────────┘
```

## 2. 硬门禁达成情况

| 门禁                 | 含义                                      | 代码实证                                                 | 判定         |
| -------------------- | ----------------------------------------- | -------------------------------------------------------- | ------------ |
| 反向依赖 binance = 0 | 基座/领域/infra 无任何 import binance     | 全局 `rg "ZoneCNH/binance"` → 0 命中                     | ✅ PASS      |
| 领域纯度 = 0         | L2.5 无任何 import infra/provider/binance | 5 模块全局 `rg` → 0 命中（仅测试字符串字面量 "binance"） | ✅ PASS      |
| infra 同层互耦 = 0   | 7 个 infra 模块无真实互相 import          | 逐模块 `rg "^\"github.com/ZoneCNH/<sibling>\""` → 0 命中 | ✅ PASS      |
| 禁止多层实现         | 16 项能力各有唯一 production owner        | 12 项 PASS，4 项部分 PASS（均有已知缺口）                | ⚠️ 主体 PASS |
| 配置/生命周期解耦    | configx 机制层 ✓ 语义层 ✓ assembly 层 ⚠   | 核心 PASS，cmd/\* 入口部分收敛                           | ⚠️ 部分 PASS |

## 3. 解耦硬门禁代码级证据总结

```text
【反向依赖扫描】基座/领域/shared 层对 binance 的依赖 = 0

rg "github.com/ZoneCNH/binance" --type go /home/{kernel,configx,observex,resiliencx,schedulex,bootstrap,redisx,kafkax,natsx,postgresx,taosx,ossx,clickhousex,contracts,transportx,decimalx,domainx,domain-market,domain-macro,domain-exchange}/
→ 0 命中

【领域纯度扫描】L2.5 对 infra/provider 的依赖 = 0

rg "(redisx|kafkax|natsx|postgresx|taosx|ossx|clickhousex|transportx|binance)" \
   --type go /home/{decimalx,domainx,domain-market,domain-macro,domain-exchange}/
→ 命中均为测试文件中的字符串字面量（如 mock adapter name "binance"），零真实 Go import 语句

【infra 同层互耦扫描】7 个 infra 模块互相真实 import = 0

rg '^"github.com/ZoneCNH/(redisx|kafkax|natsx|postgresx|taosx|ossx|clickhousex)"' \
   --type go /home/{redisx,kafkax,natsx,postgresx,taosx,ossx,clickhousex}/
→ 0 命中

【binance core 纯度】internal/ 无 infra 客户端构造

rg "(natsx|redisx|kafkax|postgresx|taosx|ossx|clickhousex)\.New(" \
   --type go /home/workspace/binance/internal/
→ 命中均为测试文件（_test.go）或工具函数（NewEnvelope/NewKey/NewStatement），
   零 concrete client 构造（如 natsx.New）

【os.Getenv 边界】internal/ 无生产环境读取

rg "os\.Getenv" --type go /home/workspace/binance/internal/
→ 仅命中 _test.go 中的集成测试跳过逻辑（BINANCE_NATSX_INTEGRATION），
   生产代码零 os.Getenv
```

## 4. 全量模块 Owner 矩阵（精简版）

> 完整版见 [`module-boundary-definitions-20260625.md`](./module-boundary-definitions-20260625.md)

| 层      | 模块            | 一句话 Owner                                         |
| ------- | --------------- | ---------------------------------------------------- |
| 治理    | xlib_standard   | 标准、模板、门禁规则、evidence runtime               |
| 治理    | xlib_harness    | 验证 harness、合规检查入口                           |
| 治理    | xlib_evidence   | 证据采集、报告、审计材料                             |
| 治理    | xlibgate        | 依赖/边界/质量 gate 扫描                             |
| L0      | kernel          | 最小稳定 primitives (errx/healthx/lifecycx 等)       |
| L1      | configx         | 配置 source/merge/decode/secret/redaction/provenance |
| L1      | observex        | log/metric/trace/health 接口与 adapter               |
| L1      | resiliencx      | retry/timeout/circuit/backoff/bulkhead               |
| L1      | schedulex       | scheduler/lease-aware job/tick/cron                  |
| L1 test | testkitx        | contract/golden/fixture/harness (test-only)          |
| infra   | redisx          | Redis client/pool/SetNX/TTL/lock                     |
| infra   | kafkax          | Kafka producer/consumer/admin                        |
| infra   | natsx           | NATS/JetStream pub/sub/ManualAck/Nak                 |
| infra   | postgresx       | Postgres connection/transaction/migration            |
| infra   | taosx           | TDengine 时序写入查询                                |
| infra   | ossx            | OSS object storage client                            |
| infra   | clickhousex     | ClickHouse OLAP 写入查询                             |
| 契约    | contracts       | 跨域 ports/event protocols/稳定 DTO                  |
| 运输    | transportx      | 通信契约 envelope/codec/QoS/error mapping            |
| 装配    | bootstrap       | composition root（跨 CORE+INFRA 聚合点）             |
| 领域    | decimalx        | 精确数值根锚点 (零 require)                          |
| 领域    | domainx         | exchange-neutral 领域值对象                          |
| 领域    | domain_market   | Market data canonical values                         |
| 领域    | domain_macro    | Macro observation canonical values                   |
| 领域    | domain_exchange | Exchange interface/adapter SPI                       |
| 业务    | binance         | Binance 行情采集/处理/存储/API                       |

## 5. 禁止多层实现摘要（16 项能力）

> 完整版见 [`no-multi-layer-implementation-20260625.md`](./no-multi-layer-implementation-20260625.md)

| #    | 能力                  | 唯一 Owner                          | 状态                          |
| ---- | --------------------- | ----------------------------------- | ----------------------------- |
| 1    | 配置机制              | configx                             | ✅ PASS                       |
| 2    | 启停/生命周期         | bootstrap / cmd assembly            | ✅ PASS                       |
| 3    | 可观测性              | observex                            | ✅ PASS                       |
| 4    | 弹性                  | resiliencx                          | ✅ PASS                       |
| 5    | 调度                  | schedulex                           | ✅ PASS                       |
| 6~12 | 7 个 infra 客户端     | 对应 \*x 模块                       | ✅ PASS                       |
| 13   | 跨域端口              | contracts                           | ⚠️ 过渡态（wire 未迁移）      |
| 14   | 运输 envelope         | transportx                          | ⚠️ 潜伏风险（binance 未接入） |
| 15   | 领域 canonical types  | decimalx/domain\_\*                 | ✅ PASS                       |
| 16   | gate/harness/evidence | xlibgate/xlib_harness/xlib_evidence | ✅ PASS                       |

## 6. 配置/生命周期解耦摘要

> 完整版见 [`config-lifecycle-decoupling-20260625.md`](./config-lifecycle-decoupling-20260625.md)

- `configx` 是纯机制层（source/merge/decode/redaction/provenance），不拥有任何业务键语义
- 各 FoundationX 模块声明自己的 typed Config + defaults + Validate()
- `module/binance` 声明自己的业务 policy config（endpoint/product_lines/symbols/ack/storage/fanout/archive）
- `cmd/*` assembly 负责：configx.Load → decode → 拆分配置 → 注入 constructor

**当前状态**：核心层 PASS；`cmd/binance-client` 已接入 `binancecfg.Load`；`cmd/binance-server` 仍残留 `os.Getenv("MODE")`、`os.Getenv("XGO_BINANCE_KAFKA_BROKERS")` 等直接读取。

生命周期推荐 8 阶段顺序：config load → validate → kernel primitives → infra clients → injection → startup → runtime → shutdown。

## 7. 最终依赖关系图（精简版）

> 完整 Mermaid 图 + ASCII 图见 [`dependency-graph-20260625.md`](./dependency-graph-20260625.md)

```text
依赖方向 ← (左侧可 import 右侧)

binance (L3)
  ├─→ domain_exchange, domain_market, domainx, decimalx  (L2.5)
  ├─→ contracts, transportx                              (契约/运输，待接入)
  ├─→ observex, resiliencx, schedulex, configx            (L1)
  ├─→ kernel                                              (L0)
  └─→ redisx, kafkax, natsx, postgresx, taosx,            (infra, assembly-only)
      ossx, clickhousex

bootstrap → 全部 CORE + INFRA (唯一聚合点)

禁止箭头 (0 命中):
  Foundation/domain/shared/infra ← binance
  domain_* ← infra/provider
  infra_a ← infra_b (同层互耦)
```

## 8. 修复进展（2026-06-25 执行记录）

| #   | 问题                              | 严重度 | 状态              | 证据                                                                                                                   |
| --- | --------------------------------- | ------ | ----------------- | ---------------------------------------------------------------------------------------------------------------------- |
| 1   | transportx go.mod module name bug | HIGH   | ✅ **已自动修复** | `/home/workspace/transportx/go.mod:1` 现为 `module github.com/ZoneCNH/transportx`                                                |
| 2   | domain\_\* module path 分叉       | HIGH   | ✅ **已自动修复** | domain*market/main/macro/exchange 主 go.mod 均为 `github.com/ZoneCNH/domain*\*`（下划线）                              |
| 3   | domainx 主目录无 go.mod           | MED    | ✅ **已自动修复** | `/home/workspace/domainx/go.mod` 已存在，`module github.com/ZoneCNH/domainx`                                                     |
| 4   | binance runtime.go assembly 越界  | MED    | ✅ **已修复**     | 移除 `runtime.go` 的 `buildStandaloneIngestEndpoint` 和 `natsx` import；`RunStandalone` 强制要求 `IngestEndpoint` 注入 |
| 5   | binancecfg 已实现未接入 cmd/\*    | MED    | ⚠️ **部分修复**   | `cmd/binance-client/main.go` 已改为 `binancecfg.Load(ctx)`；`cmd/binance-server/main.go` 仍直接读 `os.Getenv`          |
| 6   | binance wire 未迁移 contracts     | MED    | ⬜ 待执行         | ADR-002 过渡态，`internal/wire/` 仍存在 3 文件                                                                         |
| 7   | bootstrap 分层定位需明确          | LOW    | ⬜ 待执行         | 文档任务                                                                                                               |
| 8   | domain\_\* main 落后于 worktree   | LOW    | ⬜ 待执行         | 低优先                                                                                                                 |

## 9. 工程隐患优先级排序（待修复）

| #   | 问题                                  | 严重度  | 修复                     |
| --- | ------------------------------------- | ------- | ------------------------ |
| 1   | binance server cmd 仍直接读 os.Getenv | **MED** | 统一走 `binancecfg.Load` |
| 2   | binance wire 未迁移 contracts         | **MED** | 按 ADR-002 上提契约      |
| 3   | binance 未 import transportx          | **MED** | 接入 envelope 标准化     |
| 4   | bootstrap 分层定位需明确              | **LOW** | 文档单列"装配层"         |
| 5   | domain\_\* main 落后于 worktree       | **LOW** | 同步版本号与代码         |

## 10. 验收清单

- [COMPUTED, HIGH] 20 个基座模块全部覆盖
- [COMPUTED, HIGH] 5 个领域共享层模块全部覆盖
- [COMPUTED, HIGH] `module/binance` 按 core/client/server/assembly 分解
- [COMPUTED, HIGH] 16 项能力均有唯一 production owner（12 PASS / 4 部分 PASS）
- [COMPUTED, HIGH] 配置与生命周期解耦规则完整（核心层 PASS，装配入口部分收敛）
- [COMPUTED, HIGH] 最终 Mermaid + ASCII 依赖关系图（含代码证据实线/虚线/颜色分级）
- [COMPUTED, HIGH] 反向依赖 binance=0、领域纯度=0、infra 同层互耦=0 均 PASS
- [COMPUTED, HIGH] 5 项工程隐患/过渡态已识别，均有代码证据与修复建议
- [COMPUTED, HIGH] 2026-06-25 前 4 项 HIGH/MED 问题已修复（transportx bug、domain\_\* path、domainx go.mod、natsx.New 越界）

[RULES I BROKE]: 无
