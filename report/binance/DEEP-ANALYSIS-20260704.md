# Binance 模块深度分析报告（2026-07-04）

> **审查范围**：主仓 `module/binance/`（spec/design/matrix/gate/tasks 全量制品）+ 运行时仓 `/home/workspace/binance`（GitHub `ZoneCNH/binance`，交叉核验源码/CI/Release）
> **审查方式**：4 路并行深度调研（客户端业务覆盖、服务端数据流、CI/测试/发布证据、模块规则体系）+ 本会话独立复现验证（origin/main 干净 worktree 编译、PR/CI 状态、GAP 矩阵交叉核对）
> **锚点**：Runtime `origin/main@14a30b9`（2026-07-03 push, PR #414）；主仓 Spec-Version v3.9.8；Runtime-Version 声明 v0.11.0（tag，落后 origin/main 9 commit）
> **证据标签**：`[COMPUTED]` 命令/文件核验结论、`[INFERRED]` 推断、`[KNOWN]` 既有事实、`[FRAME]` 官方文档自述口径。置信度标注 HIGH/MED/LOW。

---

## 0. 执行摘要（TL;DR）

**结论：`binance` 模块架构完整、文档治理成熟度高，但当前 `origin/main` 处于生产不可发布状态。** `[COMPUTED, HIGH]`

| 维度 | 官方文档口径 | 本次交叉核验结论 |
| --- | --- | --- |
| 规格完成度 | `48/48 FR Done`，`release_closeable=YES` | **口径本身自相矛盾，且本轮自审复核确认该矛盾在 main 最新提交后依然成立**：`goal.md`/`README.md`/`SPEC.md` 现仍称 `release_closeable=YES（PRG-001~007 全 PASS）`，但同仓 `matrix/TRACEABILITY.md:96` 现仍标注 `PRG-006 | Partial`，`evidence/2026-07-03/gap-e-projection-alignment.md:18` 亦确认此调整；历史文档 `evidence/2026-06-30/release/alignment-summary.md` 当天最终结论同为 `release_closeable: NO` |
| 运行时缺口 | `RUNTIME-GAP-MATRIX.md` 记录 58 项已知缺口（P0×3/P1×13/P2×22/P3×20） | 属实且证据扎实；但本次发现 **≥3 项新缺口未被该矩阵收录**（见 §6） |
| main 分支可编译性 | 未在任何文档中声明为风险 | **origin/main 当前编译失败**（`go build ./...` 于干净 worktree 复现，与 CI 失败一致） |
| 业务覆盖（4 产品线） | Spec 声明 Spot/UM/CM/Options 全覆盖 | **仅 Spot 实际在 runtime 启动**；UM/CM/Options 有连接器代码但未接入生产启动路径 |
| CI 健康度 | `PRG-001` 称 CI runner 已迁移 ubuntu-latest | 仅 1/12 workflow（`binance-ci.yml`）迁移；其余 11 个仍挂在 **0 个在线的 self-hosted runner** 上，`scheduled.yml` 已卡 16+ 小时 |
| 消息投递链路 | Spec 称 NATS subject 全链路 `.v1` 后缀一致 | **确认不匹配**（非风险，已用 NATS 通配符语义证实）：client 发布 5 段 subject（`binance.market.{pl}.{et}.v1`），server `Stream`/`Consumer` 固定用 4 段 `FilterSubject="binance.market.*.*"`——NATS `*` 精确匹配 1 个 token，段数不等即不可能匹配，见 §5 N2 修订 |

**一句话结论**：这是一个工程深度和治理密度都很高的模块（27+ 轮自审、58 项已知缺口全部有源码级证据），但当前 `main` 分支存在真实的编译阻断和至少一个高风险的消息链路/ACK 语义问题，**不满足"生产级别可发布状态"**。团队已在 PR #411（分支 `fix/runtime-gap-phase2-5`）中修复编译问题，但该 PR 自身 CI 也未通过（缺失文件未推送）。

---

## 1. 制品盘点

### 1.1 主仓 `module/binance/`（已迁移到嵌套目录结构）

```text
module/binance/
├── goal/goal.md              # v3.9.6 口径：release_closeable=YES
├── spec/{SPEC.md, client/SPEC.md, server/SPEC.md, ACCEPTANCE.md, FEATURES.md, NAMING.md, CONTRIBUTING.md}
├── design/{DESIGN.md, ADR-001~005, CONFIG-SCHEMA.md, PERSISTENCE-WIRING.md, RUNTIME-MAPPING.md, ...}
├── matrix/{TRACEABILITY.md, client/TRACEABILITY.md, server/TRACEABILITY.md}
├── gate/{RULES.md, STANDARD.md, BOUNDARY-GATES.md, SECURITY.md, OBSERVABILITY.md, OPERATIONS.md}
├── tasks/{client×18, server×18, ROOT×7}
├── plan/{PLAN.md, client/PLAN.md, server/PLAN.md}
├── evidence/2026-06-26 ~ 2026-07-03（按日期归档，含 P10 闭环、DATA-INTEGRITY、tier-gap 等）
├── prompt/PROMPT-TASK-RUNTIME-E2E-20260704-001-001/
├── README.md / CHANGELOG.md / STANDARD.md / SECURITY.md / TRACEABILITY.md / todo.md
```

### 1.2 运行时仓 `/home/workspace/binance`（`github.com/ZoneCNH/binance`）

```text
cmd/{binance-client, binance-server, binance-smoke}
internal/
├── client/{connectors/, publisher/, testdata/, normalize.go, mapper.go, product_line.go, runtime.go, ...}
├── server/{api/, assembly/, cache/, consumer/, controlplane/, coverage/, deadletter/, idempotency/, metrics/, storage/}
└── wire/
pkg/{binancecfg, binancex}
migrations/（10 个 .sql，无 migration runner）
.github/workflows/（12 个 workflow）
```

`[COMPUTED, HIGH]` 当前本地工作副本处于分支 `fix/runtime-gap-phase2-5`（对应 **开放 PR #411**），有未提交改动（新增 `internal/server/coverage/{store.go,subscriber.go}`、`internal/client/coverage_reporter.go`，删除 `internal/client/history_state_postgres.go`），说明模块正处于活跃迭代中，非静态归档状态。

### 1.3 报告归属说明

`report/binance/` 下已存在 17 份历史深度分析/评审文档（`DEEP-ANALYSIS-20260630.md`、`DATA-INTEGRITY-E2E-20260701.md` 6358 行、`plans/binance/RUNTIME-GAP-MATRIX.md` 58 项缺口等）。本报告**不重复**其已有的详尽缺口枚举，而是聚焦：(a) 交叉验证既有结论在 2026-07-04 时点是否仍然成立，(b) 补充此前未覆盖的新鲜发现（main 编译失败、subject 不匹配、ACK 时序），(c) 直接回答用户提出的 5 个问题。

---

## 2. 数据流架构图

### 2.1 设计态（Spec 声明的理想链路）

```mermaid
flowchart LR
    subgraph Exchange["Binance Exchange"]
        WS[WebSocket 实时流]
        REST[REST API<br/>ExchangeInfo/回填]
    end

    subgraph Client["module/binance/client"]
        Catalog[Catalog<br/>ExchangeInfoRefresher] --> Connectors[4×Connector<br/>Spot/UMPerp/CMPerp/Options]
        Connectors --> Normalize[Normalize<br/>trade/kline/depth/ticker/<br/>markPrice/fundingRate/option]
        Normalize --> Mapper[Mapper→domain_market envelope]
        Mapper --> Publisher[NATS Publisher<br/>binance.market.PL.ET.v1]
    end

    subgraph Bus["natsx JetStream"]
        Stream[(BINANCE_MARKET Stream)]
    end

    subgraph Server["module/binance/server"]
        Consumer[Consumer<br/>ManualAck] --> Validate[Validation]
        Validate --> Idem[Redis 幂等 CheckAndSet]
        Idem --> Ingest[IngestServer.Process]
        Ingest --> Storage[(TDengine 主存储)]
        Ingest --> Hooks[PostAcceptHooks]
        Hooks --> PG[(PostgreSQL<br/>catalog/audit)]
        Hooks --> HotCache[(Redis HotCache)]
        Hooks --> OSS[(OSS 冷归档)]
        Hooks --> OLAP[(ClickHouse ETL)]
        Ingest --> Kafka[Kafka 下游 fanout]
    end

    subgraph API["查询面"]
        Gin[Gin REST API<br/>market/analytics/admin]
    end

    WS --> Connectors
    REST --> Catalog
    Publisher --> Stream
    Stream --> Consumer
    HotCache --> Gin
    Storage --> Gin
    PG --> Gin
    OLAP --> Gin
```

### 2.2 实测态（源码交叉核验后的真实链路，2026-07-03 快照）

```mermaid
flowchart LR
    subgraph Exchange["Binance Exchange"]
        WS[WebSocket]
        REST[REST]
    end

    subgraph Client["client（runtime.go 实际启动路径）"]
        SpotOnly["仅 Spot Connector 被启动<br/>⚠️ UM/CM/Options 代码存在但未接线"]
        Norm["normalize.go<br/>depth 被折叠进 tick 事件类型<br/>markPrice/fundingRate 已解析但未入默认订阅"]
    end

    subgraph Bus["NATS"]
        direction TB
        PubSubj["client 发布：<br/>binance.market.*.*.v1（5 段）"]
        SubSubj["server 订阅：<br/>binance.market.*.*（4 段，⚠️ 无 .v1）"]
        PubSubj -.->|"❌ 已确认不匹配：NATS * 精确匹配1 token，段数不等无法路由"| SubSubj
    end

    subgraph Server["server（真实入口是 NATS consumer，非 gRPC）"]
        Ack["MarkDurable() 先于 storage 落库<br/>⚠️ 落库失败后重投会被当重复直接 Ack"]
        Taos["TaosWriter：仅支持 trade/tick/bar<br/>⚠️ funding_rate/mark_price → ErrUnsupportedEventType"]
        OLAPmem["OLAP 数据源=内存 10min 窗口<br/>⚠️ 非文档所述 taos→clickhouse ETL"]
        RetentionSpot["Retention 仅对 spot 硬编码调度<br/>⚠️ 未覆盖 um_perp/cm_perp/options"]
    end

    subgraph BuildFail["origin/main 当前状态"]
        Compile["❌ go build ./... 失败<br/>storage.go:313 引用不存在的 storageAssembly.runtime 字段<br/>已在 PR #411 修复但未合并，且 PR #411 CI 自身也未通过"]
    end

    WS --> SpotOnly --> Norm --> PubSubj
    REST --> SpotOnly
    SubSubj --> Ack --> Taos
    Ack --> OLAPmem
    Ack --> RetentionSpot
```

> 详细版设计态数据流见 `module/binance/design/DESIGN.md` §3、`module/binance/README.md` §数据流字符图；本报告 §2.2 为 2026-07-04 源码交叉核验后新增的"实测态"补充，标注了与设计态的具体偏差点及代码引用。

---

## 3. 业务类型覆盖矩阵（现货 / 合约 / 期权 / 订单簿）

| 业务类型 | Spec 声明 | Runtime 代码存在 | Runtime 实际启动 | 结论 |
| --- | --- | --- | --- | --- |
| **现货 Spot** | ✅ FR-001~010 等 | ✅ `connectors/spot.go`, `internal/client/spot.go:317-445` | ✅ `runtime.go:304-311` | **完全覆盖，唯一实际投产链路** `[COMPUTED, HIGH]` |
| **U本位合约 UMPerp** | ✅ FR-002a 等 | ✅ `connectors/um_perp.go`, `product_line.go:45-52` | ❌ `runtime.go:304-311` 只 new 了 Spot connector | **代码就绪，未接入生产** `[COMPUTED, HIGH]` |
| **币本位合约 CMPerp** | ✅ | ✅ `connectors/cm_perp.go`, `product_line.go:53-60` | ❌ 同上 | **代码就绪，未接入生产** `[COMPUTED, HIGH]` |
| **期权 Options** | ✅ FR-036 等 | ⚠️ 仅 `optionTicker` 结构化解析（`normalize.go:613-649`），未知子流走 raw fallback | ❌ 默认订阅无 `@optionTicker`；mapper 无 `option_tick` 分支；历史回填不支持 | **部分覆盖，且是 4 线中最薄的一支** `[COMPUTED, HIGH]` |
| **订单簿 Order Book** | ADR-003 明确排除"全量重建 + 增量重放" | ✅ depth 快照解析 `normalize.go:324-375` | ⚠️ depth 在发布语义上被**折叠为 `tick` 事件类型**，不形成独立 `*.depth.v1` subject | **符合 ADR-003 既定决策（快照级，非订单簿状态机），但连"快照独立发布"都未做到，语义比 ADR 声明的还弱** `[COMPUTED, HIGH]` |

### 数据类型覆盖清单（源码核验）

| 数据类型 | 解析 (normalize.go) | 映射 (mapper.go) | 默认实时订阅 | 历史回填 (REST) |
| --- | --- | --- | --- | --- |
| trade / aggTrade | ✅ | ✅ | ✅ | ✅（spot/um/cm） |
| kline / bar | ✅ | ✅ | ✅ | ✅（spot/um/cm，非 options） |
| depth（snapshot/diff） | ✅ | ✅（折叠进 tick） | ✅ | — |
| bookTicker / ticker | ✅ | ✅ | ✅ | — |
| mark_price | ✅ | ✅ | ❌ 未入默认订阅 | 路由错误，落到 kline 解析器 |
| funding_rate | ✅ | ✅ | ❌ 未入默认订阅 | 路由错误，落到 kline 解析器 |
| option_tick | ✅ | ❌ mapper 无分支 | ❌ | ❌ 不支持 |

### 结论（回答用户第 3 问）

`[INFERRED, HIGH]` 现货/U本位合约/币本位合约/期权/订单簿**均有代码涉及**，但生产可用性梯度差异巨大：Spot 生产就绪 → UM/CM 代码就绪但需接线 → Options 结构性薄弱 → 订单簿仅快照且发布语义被折叠。**这不是"缺失"，而是"单线（Spot）优先交付，其余三线处于半成品状态"**，与 `goal.md` 宣称的"Spot/USDⓈ-M/COIN-M/Options 全覆盖"存在实质性落差。

---

## 4. 生产就绪评估

### 4.1 CI 健康度总览

| Workflow | Runner | 最近状态 | 备注 |
| --- | --- | --- | --- |
| `binance-ci.yml` | ubuntu-latest（已迁移） | ❌ **failure** | `go build ./...` 编译失败（见 §4.2） |
| `boundary-gates.yml` / `build.yml` / `lint.yml` / `secrets-scan.yml` / `security.yml` / `status-consistency.yml` / `test.yml` / `vuln-scan.yml` | self-hosted | ⏳ pending/queued（>1h50m） | **0 个在线 runner**（`gh api repos/ZoneCNH/binance/actions/runners` → `total_count:0`） |
| `scheduled.yml` | self-hosted | ⏳ queued（**>16h55m**） | 长期卡死 |
| `release.yml` / `release-cd.yml` | self-hosted | cancelled（v0.11.0 时） | 风险高 |

`[COMPUTED, HIGH]` 最近 20 次 CI 运行：**成功 0（0%）/ 失败 3（15%）/ 挂起 17（85%）**。仅 `binance-ci.yml` 真正跑完并暴露真实代码问题；其余 11/12 workflow 因 self-hosted runner 全部下线而永久卡死，**测试/安全/边界门禁事实上已停摆**。

### 4.2 main 分支编译失败（本会话独立复现）

`[COMPUTED, HIGH]` 在干净 `git worktree`（`origin/main@14a30b9`，非本地脏工作区）中执行 `go build ./...`：

```
internal/server/assembly/storage.go:313:3: unknown field runtime in struct literal of type storageAssembly
```

根因：`storage.go:313` 构造 `&storageAssembly{..., runtime: server.RuntimeIntegrations{...}, ...}`，但 `assemble.go:368-381` 中 `storageAssembly` 结构体定义**没有 `runtime` 字段**。属于典型"结构体字段被移除/未同步添加"的合并期回归，**直接阻断 `cmd/binance-server` 主程序构建**。

修复现状：本地分支 `fix/runtime-gap-phase2-5`（对应 **开放 PR #411**）已包含修复（`assemble.go` 新增 `runtime server.RuntimeIntegrations` 字段 + `adminCfg.Runtime = asm.runtime`），但：
- PR #411 尚未合并；
- **PR #411 自身 CI 也未通过**——`Build & Vet` 报 `undefined: Heartbeat/Store/NewCoverageReporter/CoveragePublisher`，根因是本地工作区存在 3 个**未提交/未推送**的新文件（`internal/server/coverage/{store.go,subscriber.go}`, `internal/client/coverage_reporter.go`），PR 分支引用了这些符号但文件未随 PR 推送。

`[INFERRED, MED]` 这不是基础设施问题，而是**真实的开发中断/未完成提交**——需要开发者补推 3 个文件并重新触发 CI。

### 4.3 官方生产就绪证据的内部矛盾

`[COMPUTED, HIGH]` 本轮自审复核发现，矛盾比原表述更严重——**`matrix/TRACEABILITY.md` 存在文件内部自相矛盾**，而非仅仅是跨文档口径不一致：

- `TRACEABILITY.md:8,87,114,118`：多处声明 **`release_closeable: YES`**（`PRG-001~007 全 PASS`，48/48 FR Done）
- `TRACEABILITY.md:96`（同一文件）：PRG 逐项表中 **`PRG-006 | resilience | Partial`**——按 line 84 公式 `release_closeable = ... AND PRG-001~007 全 PASS`，PRG-006 非 PASS 应推导 `release_closeable = NO`，与该文件自身声明的 YES 矛盾
- `goal.md` / `README.md` / `spec/SPEC.md`：同步沿用 `release_closeable: YES`
- `evidence/2026-07-03/gap-e-projection-alignment.md:18`：确认 `PRG-006 已由 PASS 调整为 Partial`（即 TRACEABILITY 的逐项表已下修，但顶部汇总声明未跟随下修）
- 历史文档 `evidence/2026-06-30/release/alignment-summary.md` 当天最终结论同为 `release_closeable: NO`

`[INFERRED, MED]` 这是**规格口径（spec-level "Done"）与运行时口径（production gate "closeable"）的语义混用**——已被团队自己在 `RUNTIME-GAP-MATRIX.md` §7 显式声明为"双口径正交，不矛盾"，但 `TRACEABILITY.md` 自身的顶部汇总声明未随其内部 PRG-006 表格的下修而同步更新，导致**同一份权威追溯文档对外呈现自相矛盾的结论**，属于文档一致性缺口而非纯粹的口径设计问题。

### 4.4 Release 与 main 的差距

`[COMPUTED, HIGH]` 最新 tag/release：`v0.11.0`（2026-07-02）。`origin/main` 领先该 tag **9 个 commit**（config/schema/deploy/security/observability/client fix 均在内），且未发布。**在当前 CI 红灯 + 11/12 workflow 停摆的状态下，这 9 个 commit 不能被视为"可安全发布"**。

### 4.5 最终生产就绪结论

`[INFERRED, MED]` **不是"完全就绪"，也不是"完全不可用"**，准确表述为：

> 模块工程成熟度高（4×6 命名矩阵、L1/L2 状态分层、58 项已知缺口全部有源码级追溯），但发布被两类同时存在的问题阻塞：**(a) main 存在真实编译失败**，**(b) 除主 CI 外的 11 个测试/安全/门禁 workflow 因 self-hosted runner 下线而全面停摆**。在这两点解决前不应认定为可安全发布，无论规格口径的 FR 完成率数字如何。

---

## 5. 新发现的运行时缺口（未被 `RUNTIME-GAP-MATRIX.md` 58 项收录）

`plans/binance/RUNTIME-GAP-MATRIX.md`（58 项，P0×3/P1×13/P2×22/P3×20）覆盖详尽且证据扎实，本次交叉核验确认其条目属实。以下为本次调研**新发现、暂未被该矩阵收录**的问题，建议补充编号 GAP-E59+：

| # | 类别 | 一句话 | 源码位置 | 严重度建议 |
| --- | --- | --- | --- | --- |
| N1 | 编译阻断 | `storageAssembly` 缺 `runtime` 字段导致 `origin/main` 编译失败 | `internal/server/assembly/storage.go:313`, `assemble.go:368-381` | **P0**（已有 WIP 修复 PR #411，但该 PR 自身未完整推送） |
| N2 | 消息投递 | **已确认**（非疑似）：client 发布 5 段 subject `binance.market.{pl}.{et}.v1`，server `Stream.Subjects`/`Consumer.FilterSubject` 固定为 4 段 `binance.market.*.*`。NATS subject 通配符 `*` 精确匹配恰好 1 个 token（`>` 才匹配多段），4 段 pattern 结构性无法匹配 5 段 subject——`grep -rn "\.v1" internal/server/` 确认 server 端无任何 NATS market subject 使用 `.v1` | `internal/client/publisher/publisher.go:42-52`（`Subject()` 函数）vs `internal/server/consumer/consumer.go:20-25,101-117`（`Stream`/`EnsureTopology`/`NewNATSXConsumer`） | **P0（已确认的路由缺陷，非待验证风险）**——若无生产遥测证明消息仍在流动（如另有兼容层），当前推送的市场数据事实上不会进入 `BINANCE_MARKET` JetStream Stream |
| N3 | 数据可靠性 | `MarkDurable()` 先于 `storage.persist()` 执行；`StrictStorageWrite=true` 时首次落库失败、二次重投会被当重复直接 Ack，丢失重试机会 | `internal/server/ingest.go:129-187,207-219`, `assembly/assemble.go:141-147` | **P1**（潜在静默丢数据） |
| N4 | 运行时产品线覆盖 | runtime 启动路径只 `NewSpotConnector`，UM/CM/Options 未被启动，与 spec/goal 声明的"4 产品线全覆盖"不符 | `internal/client/runtime.go:304-314` | **P1**（业务功能缺口，非纯代码质量问题） |
| N5 | 可观测性口径 | OLAP/ClickHouse 数据源实为进程内存 10 分钟滚动窗口，非文档所述 "taos→clickhouse ETL" | `internal/server/assembly/olap_source.go:14-60` vs `design/PERSISTENCE-WIRING.md:24-35` | P2 |
| N6 | 存储覆盖 | `TaosWriter` 仅支持 `trade/tick/bar`，`funding_rate`/`mark_price` 写入返回 `ErrUnsupportedEventType`，与 FR-020/FR-021 "Done" 状态不符 | `internal/server/storage/taos_writer.go:215-226` | P1 |
| N7 | 运维覆盖 | Retention 调度硬编码 `ProductLine:"spot"`，其余 3 条产品线无保留策略 | `internal/server/assembly/storage.go:253-274` | P2 |

**建议动作**：由 module owner 将 N1-N7 并入 `plans/binance/RUNTIME-GAP-MATRIX.md`（编号 GAP-E59~E65），N1/N2 应作为最高优先级立即处理——N1 已阻断构建，N2 若实测确认不兼容将是数据链路级故障。

---

## 6. 模块规则 / 标准规范评估（回答用户第 5 问）

### 6.1 现状：**已建立，但分散、局部漂移，缺单一总纲**

`[COMPUTED, HIGH]` binance 已有 12 份规则/标准类文件，覆盖面遠超多数同级模块：

| 文件 | 定位 |
| --- | --- |
| `gate/RULES.md`（v3.9.0，R1-R12） | 治理总规则：命名 SSOT、4×6 矩阵对称、版本 bump、L1/L2 状态分层、归档隔离、PR 纪律 |
| `gate/BOUNDARY-GATES.md` | client/server 边界 gate 投影 |
| `gate/SECURITY.md` / `SECURITY.md`（runtime） | 安全基线（凭据/CSRF/限流/扫描） |
| `gate/OBSERVABILITY.md` | Metrics/SLO/告警（不含 tracing/logging 全量） |
| `gate/OPERATIONS.md` | 部署/扩缩容/DR runbook |
| `spec/NAMING.md` | product_line/event_type/subject/topic/env 命名 SSOT |
| `spec/CONTRIBUTING.md` / `CONTRIBUTING.md`（runtime） | 文档贡献 / 代码 PR 规则（读者分裂但互补） |
| `STANDARD.md`（根，7 行） | **纯导航 stub，未承担总纲职责** |
| `gate/STANDARD.md` | 实际是 **FR-024 hot reload 专项标准**，与根 `STANDARD.md` 撞名 |

### 6.2 已发现的规则体系自身漂移（需修复）

1. **BOUNDARY-GATES 口径三套并存**：`gate/RULES.md` R10 写"12 个 gate"；主仓 `gate/BOUNDARY-GATES.md` 写"13/13 PASS"；runtime `BOUNDARY-GATES.md` 已扩到 §2-§16。
2. **STANDARD.md 命名冲突**：根 `STANDARD.md`（导航 stub）与 `gate/STANDARD.md`（FR-024 专项）同名不同职责，根文件未链接后者。
3. **client admin 令牌认证机制未被 `gate/SECURITY.md` 收录**（非命名漂移）：`FOUNDATIONX_BINANCE_API_TOKEN`（server Gin 查询 API，`internal/server/api/query.go:510-515`）与 `FOUNDATIONX_BINANCE_ADMIN_TOKEN`（client admin 管理面，`pkg/binancecfg/config.go:261` `config:"ADMIN_TOKEN"`）是**两个合法的不同令牌**，服务于不同管理面，非同一概念的命名不一致；真正的缺口是 `gate/SECURITY.md` 全文未提及 "admin" 或 client 侧管理面认证（`grep -c admin gate/SECURITY.md` = 0），属于安全文档覆盖缺口。
4. **NAMING.md 内部自相矛盾**：声明 REST path 用 `snake_case`，示例却是 `funding-rate`/`mark-price`（kebab-case）；env 前缀声明 `XGO_BINANCE_*`，实际大量文档用 `FOUNDATIONX_BINANCE_*`。
5. **未显式声明继承全局 Go 规范**：`docs/standards/go-coding-standards.md` 的 14 维（错误处理/并发/接口设计/性能/泛型等）在 binance 模块规则中无显式继承声明或 delta 说明。

### 6.3 结论与建议

`[INFERRED, HIGH]` **不需要从零新建一整套规则体系**（已有骨架且颇具深度），但需要：

1. **P0 - 重写根 `module/binance/STANDARD.md`** 为唯一《binance 模块规则与标准规范总纲》：声明权威层级（`CONSTITUTION.md` → `go-coding-standards.md` → 本模块 `gate/*` → runtime repo docs）+ 10 类规则的 authority map（见下表）+ 仅做链接不重复内容。
2. **P0 - 将 `gate/STANDARD.md` 改名**为 `gate/FR024-HOT-RELOAD-STANDARD.md`，消除撞名。
3. **P0 - 统一 BOUNDARY-GATES 口径**（R10 / 主仓 / runtime 三处对齐到同一 gate 数量与编号）。
4. **P0 - 修复命名漂移**（REST path 大小写风格、env 前缀 `XGO_BINANCE_*` vs 实际 `FOUNDATIONX_BINANCE_*`），并在 `NAMING.md` 变更历史中记录；**同时补齐 `gate/SECURITY.md` 对 client admin 令牌（`FOUNDATIONX_BINANCE_ADMIN_TOKEN`）认证机制的文档覆盖**（见 §6.2 第 3 点修订）。
5. **P1 - 新建 `gate/API-COMPATIBILITY.md`**：统一 gRPC/HTTP/NATS/Kafka/schema 版本与 breaking change 策略（当前散落在多份 SPEC/README 中）。
6. **P1 - 新建 `gate/TESTING.md`**：统一 unit/integration/E2E/contract/race/coverage 的证据要求（当前散落在 `RULES.md` R4 与 runtime `CONTRIBUTING.md`）。
7. **P1 - `gate/OBSERVABILITY.md` 补齐 tracing/logging/redaction**，并链接 runtime 已有的 `docs/observability/tracing-setup.md`。
8. **P2 - 错误处理/并发安全/依赖治理**：不必单独成文，建议在总纲中声明"继承全局 Go 标准 + 列出 binance 专属 delta"（如 R11 分钟 weight 模型、R12 按事件类型的 gap detection 策略）。

**10 类规则覆盖矩阵总结**（详见附录）：命名规范、可观测性、安全、运维（回滚文档存在但未被 gate 吸收）为"部分覆盖但文档已存在，只是未被索引"；API 契约稳定性、测试规范、依赖治理为"部分覆盖，缺统一专项文档"；错误处理、并发安全为"仅存在于子规格，无模块级统一规则"。

---

## 7. 优先级修复路线图

```text
P0（立即，阻断构建/发布）
├── N1: 合并 PR #411 前先补推 3 个缺失文件，确保 PR CI 全绿，再合并修复 storageAssembly.runtime 编译错误
├── N2: 已确认 NATS subject 段数不匹配（client 5 段 vs server 4 段），需立即同 PR 修复 consumer.go 的 FilterSubject/Stream.Subjects 定义
├── 恢复 self-hosted runner 或将全部 11 个 workflow 迁移至 ubuntu-latest（参考 binance-ci.yml 先例）
└── 消解 release_closeable YES/NO 的顶层文档矛盾（goal.md/README.md/SPEC.md 称 YES + PRG-001~007 全 PASS，同仓 matrix/TRACEABILITY.md 与 evidence/2026-07-03/gap-e-projection-alignment.md 称 PRG-006 Partial——本轮自审复核确认此矛盾在 main 最新提交后依然成立，未被后续文档同步修复）

P1（本迭代）
├── N3: 修正 ACK 时序（storage 成功后再 MarkDurable）
├── N4: 将 UM/CM/Options connector 接入 runtime.go 实际启动路径，或在 goal.md 中明确降级声明
├── N6: 补齐 TaosWriter 对 funding_rate/mark_price 的支持，或下调 FR-020/021 状态
├── 重写 STANDARD.md 总纲 + gate/STANDARD.md 改名 + BOUNDARY-GATES 口径统一
└── 沿用既有 RUNTIME-GAP-MATRIX 路线图（MVP-M → MVP-J → MVP-A+ → MVP-F → MVP-G → MVP-I）

P2（后续）
├── N5/N7: OLAP 内存窗口升级为 taos-backed source；Retention 扩展到全产品线
├── 新建 gate/API-COMPATIBILITY.md、gate/TESTING.md
└── 命名漂移全量清理（token/env/REST path）
```

---

## 8. 附录：证据来源清单

- 本仓 `module/binance/`：`goal/goal.md`、`README.md`、`spec/SPEC.md`、`spec/client/SPEC.md`、`spec/server/SPEC.md`、`matrix/TRACEABILITY.md`、`matrix/client|server/TRACEABILITY.md`、`design/ADR-003/004/005`、`gate/RULES.md`、`gate/STANDARD.md`、`gate/BOUNDARY-GATES.md`、`gate/SECURITY.md`、`gate/OBSERVABILITY.md`、`gate/OPERATIONS.md`、`spec/NAMING.md`、`spec/CONTRIBUTING.md`、`STANDARD.md`、`CHANGELOG.md`、`evidence/2026-06-30/release/*`、`evidence/2026-07-03/gap-e-projection-alignment.md`
- `plans/binance/RUNTIME-GAP-MATRIX.md`（58 项运行时缺口，本报告交叉验证属实）
- 运行时仓 `/home/workspace/binance`（`origin/main@14a30b9`、分支 `fix/runtime-gap-phase2-5`）：`internal/client/{connectors/,normalize.go,mapper.go,product_line.go,runtime.go,history_rest.go}`、`internal/server/{assembly/,ingest.go,consumer/,storage/,api/,admin.go}`、`internal/wire/types.go`
- GitHub 实测：`gh run list/view`（run `28677918047` 失败详情）、`gh pr view/checks 411`、`gh release list`、`gh api repos/ZoneCNH/binance/actions/runners`（0 runner）
- 本会话独立验证：`git worktree add` 于 `origin/main` 干净副本执行 `go build ./...` 复现编译失败（避免本地脏工作区误导）

**[RULES I BROKE]**：无——本报告全程标注证据标签与置信度，编译失败结论已通过干净 worktree 独立复现（非转述 CI 日志），未发生 FRAME→REALITY 误用。

---

## 9. 十轮独立对抗性自审记录（2026-07-04 补充）

`[COMPUTED, HIGH]` 应要求对本报告执行 10 轮独立复核，逐轮聚焦不同维度，钉住锚点 `origin/main@14a30b9`（runtime）与 `ZoneCNH main@b35b158e`（本报告合并提交，复核时确认 `git log HEAD..origin/main` = 0，无漂移风险）。

| 轮次 | 维度 | 方法 | 结论 |
| --- | --- | --- | --- |
| 1 | 报告完整性 | 分段 `view` 全文 330+ 行 | 通过，合并后内容完整、无冲突残留标记 |
| 2 | 主仓文档引用 | 逐一 `[ -f ]` 核验 §8 附录 24 个引用路径 | 全部存在，无 404 引用 |
| 3 | 客户端代码引用 | 核验 16 个 client 文件存在性 + 行号范围抽查（runtime.go/product_line.go/normalize.go） | 引用准确；**同时发现 N2 可从"风险"升级为"确认"**（见轮次修正① ） |
| 4 | 服务端代码引用 | 核验 9 个 server 文件存在性 + subject 定义交叉核对 | 引用准确；确认 server 端无任何 `.v1` NATS market subject 用法 |
| 5 | CI/PR 时效性 | 重新 `gh pr view 411`、`gh run list --branch main` | main SHA、PR #411 状态未变，CI 挂起时长从 1h50m 增至 2h13m，问题持续未解决，结论仍成立 |
| 6 | GAP 矩阵去重 | 关键词搜索 + `GAP-E\d+` 编号提取 | 矩阵止于 E58，N1-N7 关键词零命中，E59-E65 编号无冲突 |
| 7 | Mermaid 语法 | `mermaid-cli` 编译两张图为 SVG | 均编译成功（47KB/26KB），语法无误 |
| 8 | 规则体系漂移证据 | 核验 BOUNDARY-GATES 口径/STANDARD 撞名/NAMING 矛盾/token 命名 | BOUNDARY-GATES（12 vs 13/13 vs §16）、STANDARD 撞名（7 行 vs 87 行）、NAMING.md 两处自相矛盾（REST path snake_case 声明 vs kebab-case 示例；env 前缀 `XGO_BINANCE_` 声明 vs 实际 `FOUNDATIONX_BINANCE_`）**均确认属实**；**token 命名漂移一项确认为误判**（见轮次修正②） |
| 9 | 用户 5 问覆盖度 | 章节结构 vs 原始问题逐一对照 | §4↔生产级别、§2↔数据流图、§3↔业务类型、§5+§7↔待补充优化、§6↔模块规则，五问全覆盖无遗漏 |
| 10 | release_closeable 矛盾时效性 | 重新读取当前 `TRACEABILITY.md`/`gap-e-projection-alignment.md` | **发现比原表述更严重的问题**：矛盾并非仅跨文档，而是 `TRACEABILITY.md` **文件内部自相矛盾**（顶部声明 YES，§PRG 表 line 96 却是 PRG-006 Partial）；该矛盾在 main 最新提交后依然成立，未被后续文档同步修复（见轮次修正③） |

### 本轮自审产生的 3 处实质性修正

1. **N2（NATS subject 不匹配）升级**：原表述为"需实测确认的风险"，经 NATS 通配符语义分析（`*` 精确匹配 1 个 token，4 段 pattern 结构性无法匹配 5 段 subject）确认为**已确认缺陷**，已更新 §0/§2.2/§5/§7 对应表述与严重度标注。
2. **Token 命名"漂移"改判为文档覆盖缺口**：原 §6.2 第 3 点误将 `FOUNDATIONX_BINANCE_API_TOKEN`（server 查询 API）与 `FOUNDATIONX_BINANCE_ADMIN_TOKEN`（client admin 管理面，`pkg/binancecfg/config.go:261` 确认为独立配置项）判定为同一令牌的命名不一致；核实后二者是两个合法的不同令牌，真正问题是 `gate/SECURITY.md` 未记录 client admin 认证机制，已更正措辞并调整 §6.3 建议 4。
3. **release_closeable 矛盾定性加深**：原 §4.3 表述为"跨文档口径不一致"，本轮发现矛盾实际发生在 `matrix/TRACEABILITY.md` **单一文件内部**（顶部汇总声明与其自身 §PRG 逐项表冲突），已更新 §0/§4.3 表述并保留时间戳证据（复核时点 vs 原撰写时点均确认矛盾持续存在）。

`[INFERRED, HIGH]` 10 轮自审共验证约 60+ 项具体引用（文件路径、行号、CI 状态、GAP 编号、Mermaid 语法、证据标签），发现 3 处需修正、0 处需撤回。原报告核心结论（main 编译失败、Spot-only 生产覆盖、release_closeable 自相矛盾、CI 停摆、模块规则分散漂移）在复核后**全部成立且部分证据强度得到提升**，未发现推翻性反例。

**[RULES I BROKE]**：无——本轮自审对 3 项修正均标注了原判断错误的具体原因与新证据，未静默覆盖历史结论；置信度标注遵循 §20 规范，无 FRAME→REALITY 误用。
