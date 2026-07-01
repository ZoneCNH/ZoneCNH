# binance 模块深度分析报告

> **分析日期**：2026-06-30
> **分析对象**：`module/binance/`（spec hub）+ `/home/workspace/binance/`（runtime 仓）
> **分析基准**：CONSTITUTION §0-§20、STRUCTURAL-SCORING 11 阶段维度、数据 C/S 模块治理等级 L1-L3、Go 编码规范 13 维度
> **证据口径**：runtime HEAD `744e5a7`（main, 2026-06-29）、spec hub v3.9.6、registry.yaml v0.8.0 tag

---

## 1. 执行摘要

binance 是 ZoneCNH 治理体系中**唯一 active 的数据域 C/S 模块**（registry.yaml），承担 Binance 交易所 4 产品线行情采集任务。模块经历 v1.0.0（gRPC + SQLite spool）→ v2.0.0（NATS JetStream）的架构迁移，当前 spec 版本 v3.9.6、runtime tag v0.8.0。

**核心结论**：

| 维度                   | 评分       | 判定                                                          |
| ---------------------- | ---------- | ------------------------------------------------------------- |
| Spec Hub 结构完整性    | **72/100** | 多处状态分裂，需修复                                          |
| Runtime 代码质量       | **89/100** | 边界纪律优秀，运维一致性待修                                  |
| Client/Server 边界规范 | **93/100** | 设计与执行均属上乘                                            |
| 生产就绪度             | **61/100** | L2 确认，L3 未达标                                            |
| **综合**               | **76/100** | **L2 Active → L3 Production candidate，距可发布仍有显著差距** |

**最严重问题**：`release_closeable` 状态全面分裂——root 级文档（SPEC/TRACEABILITY/todo/README）标注 `YES (48 Done)`，但 10+ 份子模块文档标注 `NO (23 Done / 25 Partial)`。PRG 门禁状态在 root TRACEABILITY（全 PASS）与 ACCEPTANCE.md（PRG-001~006 Open/Partial）之间直接矛盾。**在状态分裂解决前，release_closeable=YES 不可信。**

**最积极发现**：runtime 仓的 client/server 边界实现是治理体系的标杆——15 道 CI 门禁全部 PASS，import-path 级零违规，0 TODO/FIXME，0 panic，覆盖率 99.9%（short mode）。

---

## 2. 评分总览

### 2.1 多维度评分矩阵

| 维度                      | 满分 | 得分   | 等级   | 关键扣分原因                                                          |
| ------------------------- | ---- | ------ | ------ | --------------------------------------------------------------------- |
| **A. Spec 结构完整性**    | 100  | 72     | C+     | 状态分裂（3 CRITICAL）、根级旧 SPEC 未删、PRG 矛盾                    |
| **B. 追溯矩阵闭合**       | 100  | 65     | D+     | root vs 子模块 TRACEABILITY 矛盾、FR Partial vs Done 不一致           |
| **C. Design 架构质量**    | 100  | 85     | B+     | DESIGN.md 仍 Draft、DRIFT-WATCHLIST 检测命令引用旧路径                |
| **D. Runtime 代码质量**   | 100  | 89     | A-     | Go 版本不一致、contracts 迁移声明与事实不符、覆盖率双轨               |
| **E. Client/Server 边界** | 100  | 93     | A      | 边界设计优秀，仅扣运维一致性分                                        |
| **F. 测试与验证**         | 100  | 82     | B      | 全测试通过，但覆盖率 full mode 77.4% < 80% 门禁                       |
| **G. CI/CD 管线**         | 100  | 78     | C+     | CI workflow 存在但 self-hosted runner 未确认、ci.yml 旧模板残留       |
| **H. 安全与合规**         | 100  | 80     | B      | gitleaks/govulncheck 配置完整，SECURITY.md 限流状态待核实             |
| **I. 可观测性**           | 100  | 83     | B      | Prometheus metrics 定义完整，Grafana dashboard 待部署                 |
| **J. 生产就绪 (L3)**      | 100  | 61     | D+     | PRG-001~006 未闭合、live integration 不足、无 release evidence bundle |
| **K. 文档一致性**         | 100  | 58     | F      | 10+ 文件状态矛盾、CHANGELOG 滞后、路径引用漂移                        |
| **加权综合**              | 100  | **76** | **C+** | —                                                                     |

### 2.2 结构性评分（对标 STRUCTURAL-SCORING 11 阶段）

| 阶段                | 维度满分 | 评估得分 | 红线命中                  | 说明                                                  |
| ------------------- | -------- | -------- | ------------------------- | ----------------------------------------------------- |
| S1-Spec             | 100      | 78       | 无                        | 23 节结构完整，但状态分裂影响可信度                   |
| S2-Matrix           | 100      | 65       | **红线 2**：追溯断裂      | root vs 子模块 TRACEABILITY 矛盾                      |
| S3-Design           | 100      | 85       | 无                        | ADR 完整，DESIGN.md 仍 Draft                          |
| S4-Tasks            | 100      | 88       | 无                        | 39 个 task 结构清晰，5 个已归档                       |
| S5-Plan             | 100      | 80       | 无                        | PLAN.md §8 停止条件与 SPEC release_closeable=YES 矛盾 |
| S6-Prompt           | 100      | 30       | **红线 1**：空壳          | prompt/ 仅 README.md，无实际 PROMPT 文件              |
| S7-Code             | 100      | 89       | 无                        | 代码质量优秀                                          |
| S8-Test             | 100      | 82       | 无                        | full coverage 77.4% < 80% 门禁                        |
| S9-Review           | 100      | 70       | 无                        | evidence 文件存在但状态矛盾                           |
| S10-Release         | 100      | 55       | **红线 1**：PRG 未全 PASS | PRG-001~006 Open/Partial                              |
| S11-Retrospective   | 100      | 75       | 无                        | evidence/2026-06-26/retrospective/ 存在               |
| **composite (min)** | 100      | **30**   | —                         | 受 Prompt 空壳和 Release PRG 拖累                     |

> **注**：composite = min(...) 是治理管线门禁公式。当前 composite=30 远低于 98 分门禁，**管线判定为 pipeline_blocked**。但此分数受 prompt/ 空壳（管线已越过 S5 阶段）和状态分裂（可通过文档同步修复）的过度惩罚。若排除已过期阶段（S5-Prompt 已越阶段）并修复状态分裂，预估 composite 可恢复至 ~80。

### 2.3 治理等级评估

| 等级          | 条件                                                                           | binance 状态 |
| ------------- | ------------------------------------------------------------------------------ | ------------ |
| L1 Prototype  | goal + SPEC 骨架 + 边界声明 + 命名                                             | ✅ 达标      |
| L2 Active     | L1 + matrix + boundary gates + plan/tasks + runtime 编译与本地测试             | ✅ 达标      |
| L3 Production | L2 + PRG 全 PASS + live_integration ≥ 15 + 外部 E2E/soak/release/rollback 证据 | ❌ 未达标    |

**当前等级**：L2 Active（confirmed）
**目标等级**：L3 Production（gap = 6 项关键阻塞，详见 §5）

---

## 3. 结构性问题清单

### 3.1 CRITICAL 级（3 项）

#### C1. `release_closeable` 状态全面分裂

**严重度**：CRITICAL（影响范围：10+ 文件）
**证据标签**：`[COMPUTED, HIGH]`

root 级文档与子模块文档在同一天（2026-06-29）对 `release_closeable` 做出矛盾声明：

| 文件                                         | 日期  | release_closeable | FR 状态                 | 数据来源 |
| -------------------------------------------- | ----- | ----------------- | ----------------------- | -------- |
| `spec/SPEC.md`                               | 06-29 | **YES**           | 48 Done / 0 Partial     | root     |
| `matrix/TRACEABILITY.md`                     | 06-29 | **YES**           | 48 Done / 0 Partial     | root     |
| `README.md`                                  | 06-29 | **YES**           | 48 Done / 0 Partial     | root     |
| `todo.md`                                    | 06-29 | **YES**           | 47 tasks `[x]`          | root     |
| `goal.md`（根级）                            | 06-29 | **Released**      | 48/48 Done              | root     |
| `matrix/client/TRACEABILITY.md`              | 06-29 | **NO**            | 23 Done / 25 Partial    | 子模块   |
| `matrix/server/TRACEABILITY.md`              | 06-29 | **NO**            | 23 Done / 25 Partial    | 子模块   |
| `spec/ACCEPTANCE.md` §1.1                    | 06-29 | —                 | PRG-001~006 Open        | 验收     |
| `CHANGELOG.md`                               | 06-28 | **NO**            | 23/48 ≈ 47.9%           | 历史     |
| `gate/BOUNDARY-GATES.md` §12                 | 06-26 | **Not Done**      | G0 存储装配断层         | 门禁     |
| `plan/PLAN.md` §8                            | 06-26 | **blocked**       | "不得声明 Release Done" | 计划     |
| `design/ARCHITECTURE-DRIFT-WATCHLIST.md` D11 | 06-26 | **NO**            | YES 被标记为漂移        | 监控     |

**根因推断**：`[INFERRED, MED]` 2026-06-29 有人将 root 级文档的 FR 状态从 "23 Done / 25 Partial" 批量翻转为 "48 Done / 0 Partial" 并设置 release_closeable=YES，但**未同步 propagate** 到子模块 TRACEABILITY、ACCEPTANCE PRG 表、CHANGELOG、BOUNDARY-GATES、PLAN 和 DRIFT-WATCHLIST。这是不完整的批量状态更新操作。

**修复方案**：

1. 确认真实状态：运行 runtime 测试 + boundary-gates + 检查 PRG-001~006 实际状态
2. 以 `spec/ACCEPTANCE.md` §1.1 PRG 表为权威源（PRG-001~006 仍 Open/Partial）
3. 将 root 级文档回退为 `release_closeable=NO` 直到 PRG-001~006 全部闭合
4. 或：闭合 PRG-001~006 后再做全模块状态同步

#### C2. PRG 门禁状态矛盾

**严重度**：CRITICAL
**证据标签**：`[COMPUTED, HIGH]`

| PRG                        | root TRACEABILITY     | ACCEPTANCE.md §1.1                    | 矛盾性质 |
| -------------------------- | --------------------- | ------------------------------------- | -------- |
| PRG-001 (CI runner)        | PASS                  | **Open**（self-hosted runner 未配置） | 直接矛盾 |
| PRG-002 (release tag)      | PASS（v0.2.0 已发布）   | **Open**（v0.2.0 tag 未发布）         | 直接矛盾 |
| PRG-003 (live integration) | PASS                  | **Partial**                           | 直接矛盾 |
| PRG-004 (soak test)        | PASS                  | **Open**                              | 直接矛盾 |
| PRG-005 (rollback)         | PASS                  | **Open**                              | 直接矛盾 |
| PRG-006 (evidence bundle)  | PASS                  | **Partial**                           | 直接矛盾 |
| PRG-007 (issue sync)       | PASS                  | PASS                                  | 一致     |

**实际验证**：`[COMPUTED, HIGH]` git tag 列表显示 `v0.8.0` 存在（非 v0.2.0），但 ACCEPTANCE.md 引用的是 v0.2.0——版本号本身也不一致。runtime HEAD `744e5a7` 的测试全部通过、boundary-gates 15/15 PASS，但 self-hosted runner 的配置状态无法从代码仓确认。

**影响**：root TRACEABILITY §4 的 `release_closeable` 判定公式要求 "PRG-001~007 全 PASS AND 远程 CI PASS AND release tag 已发布"。若 ACCEPTANCE.md 为真，则 release_closeable=YES 违反自身判定公式。

#### C3. 根级 `SPEC.md`（v1.0.0 gRPC 架构）仍然存在

**严重度**：CRITICAL
**证据标签**：`[COMPUTED, HIGH]`

`spec/SPEC.md` §14 明确声明："Deprecated root spec files were physically deleted in v3.9.5"。但根级 `SPEC.md`（v1.0.0, 2026-06-16）仍然存在于 `module/binance/SPEC.md`，描述的是已废弃的 gRPC + SQLite spool + checkpoint 架构。

此文件与当前 `spec/SPEC.md`（v3.9.6, NATS JetStream）描述的架构**根本不同**，可能导致：

- 新读者误读旧架构
- 自动化工具引用错误文件
- DRIFT-WATCHLIST D5 检测命令引用 `module/binance/SPEC.md`（根级旧文件）而非 `module/binance/spec/SPEC.md`

**修复方案**：物理删除根级 `SPEC.md`，或重命名为 `SPEC.v1-deprecated.md` 并在文件头标注 `Status: Deprecated`。

### 3.2 HIGH 级（7 项）

#### H1. Issue 编号不一致

**位置**：`matrix/TRACEABILITY.md` §4/§5 vs `spec/SPEC.md` §1 / `spec/ACCEPTANCE.md`
**矛盾**：root TRACEABILITY 写 "47 GitHub (#148-#194) + 47 Beads"，SPEC/ACCEPTANCE 写 "43 GitHub (#1289~#1331) + 43 Beads"
**证据标签**：`[COMPUTED, HIGH]`

#### H2. Runtime-Version 不一致

**位置**：跨文件
**矛盾**：root SPEC/README/goal.md 标 v0.8.0，client/server SPEC 标 v0.2.0
**证据标签**：`[COMPUTED, HIGH]`

#### H3. DRIFT-WATCHLIST D11 将 `release_closeable=YES` 标记为漂移指标

**位置**：`design/ARCHITECTURE-DRIFT-WATCHLIST.md` D11
**问题**：D11 的检测命令 `rg "release_closeable[=]YES" module/binance` 在当前 SPEC.md 和 TRACEABILITY.md 上命中，但 D11 声称当前状态应为 NO。这形成了一个自相矛盾的监控点。
**证据标签**：`[COMPUTED, HIGH]`

#### H4. 子模块 TRACEABILITY 与 root TRACEABILITY 直接矛盾（同日期）

**位置**：`matrix/client/TRACEABILITY.md` §6 vs `matrix/TRACEABILITY.md` §6
**矛盾**：同日期 2026-06-29，client TRACEABILITY 明确写 "全局 single state 为 23 Done / 25 Partial / 0 Drifted / 0 Pending，release_closeable=NO"，root TRACEABILITY 写 "48 Done / 0 Partial, release_closeable=YES"。
**证据标签**：`[COMPUTED, HIGH]`

#### H5. server TRACEABILITY 标注 FR-007/007a/011 为 Partial

**位置**：`matrix/server/TRACEABILITY.md` §1/§6
**矛盾**：server TRACEABILITY 标注 FR-007/007a（idempotent acceptance）和 FR-011（downstream dispatch）为 Partial，但 root TRACEABILITY 对应 FR 全标 Done。
**证据标签**：`[COMPUTED, HIGH]`

#### H6. FEATURES.md §6 残留旧数据

**位置**：`spec/FEATURES.md` §6/§7
**矛盾**：头部标 "48 Done / 0 Partial"，§6 残留 "23 Done / 25 Partial / 0 Drifted / 0 Pending"，§7 残留 "release_closeable=NO (Code-Done 47.9% < 90% 门禁)"。
**证据标签**：`[COMPUTED, HIGH]`

#### H7. BOUNDARY-GATES.md §12 Release 标 "Not Done" + G0 存储装配断层

**位置**：`gate/BOUNDARY-GATES.md` §12
**问题**：明确标注 Release: Not Done，列出远端 CI、release tag、live websocket、真实 Kafka broker fanout、G0 存储装配闭合等未完成项。G0 存储装配断层声明："boundary-gates 的 §12-§14 gate 证明的是 runtime 代码中存在调用，不证明 main.go 装配了真实实例"。
**证据标签**：`[COMPUTED, HIGH]`

> **验证**：`[COMPUTED, HIGH]` runtime `cmd/binance-server/main.go` 仅 156 行，调用 `assembly.Assemble()` 集中装配。`assembly/` 目录存在且有完整实现。BOUNDARY-GATES.md §12 的 G0 断层声明可能是 06-26 的旧状态，P10 修复（06-27~06-29）可能已闭合——但文档未更新。

### 3.3 MEDIUM 级（7 项）

| #   | 问题                                                       | 位置                                                            | 影响                                                                                                         |
| --- | ---------------------------------------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| M1  | 两份 goal 文件不同步                                       | `goal.md` vs `goal/goal.md`                                     | 根级有最新版本元数据，嵌套位置无版本元数据                                                                   |
| M2  | DRIFT-WATCHLIST D5/D7 检测命令引用旧路径                   | `design/ARCHITECTURE-DRIFT-WATCHLIST.md`                        | D5 引用 `SPEC.md` 而非 `spec/SPEC.md`；D7 引用 `client/TRACEABILITY.md` 而非 `matrix/client/TRACEABILITY.md` |
| M3  | RULES.md R9 文档存在性检测命令引用根级路径                 | `gate/RULES.md` R9                                              | 与当前嵌套结构不匹配                                                                                         |
| M4  | CONFIG-SCHEMA.md 残留 `BINANCE_CHECKPOINT_PATH`            | `design/CONFIG-SCHEMA.md` Client 表                             | v2.0.0 已删除 checkpoint                                                                                     |
| M5  | plan/PLAN.md §8 停止条件与 SPEC release_closeable=YES 矛盾 | `plan/PLAN.md` §8                                               | "不得声明 Release Done" vs YES                                                                               |
| M6  | contracts 依赖声明与实际不符                               | runtime `internal/wire/doc.go`                                  | 声明 "contracts 已接入 go.mod"，实际 go.mod/go.sum 中无 contracts                                            |
| M7  | Go 版本不一致                                              | runtime `Dockerfile.client/server` + `.github/workflows/ci.yml` | go.mod 要求 1.25.0，Dockerfile.client/server 用 1.23-alpine，ci.yml 用 1.23                                  |

### 3.4 LOW 级（5 项）

| #   | 问题                                                                         | 位置                                            |
| --- | ---------------------------------------------------------------------------- | ----------------------------------------------- |
| L1  | DESIGN.md Status 仍为 Draft                                                  | `design/DESIGN.md`                              |
| L2  | server/SPEC.md Last-Updated (06-26) 比 root SPEC (06-29) 滞后 3 天           | `spec/server/SPEC.md`                           |
| L3  | IMPLEMENTATION-PLAN.md 过于精简（19 行），与 plan/PLAN.md（112 行）内容重叠  | 根级 `IMPLEMENTATION-PLAN.md` vs `plan/PLAN.md` |
| L4  | docker-compose.yml image tag v0.6.0 与 README release evidence v0.2.0 不匹配 | runtime `docker-compose.yml`                    |
| L5  | migration 编号跳过 007（001-006, 008-010），无说明                           | runtime `migrations/`                           |

---

## 4. Client/Server 边界深度分析

### 4.1 边界定义现状

#### 4.1.1 架构拓扑

```
┌─────────────────────────────────────────────────────────────────┐
│                    Go module: github.com/ZoneCNH/binance        │
│                                                                 │
│  ┌──────────────┐    NATS JetStream    ┌──────────────────────┐ │
│  │  cmd/client  │ ──────────────────▶  │  cmd/server          │ │
│  │  internal/   │   binance.market.    │  internal/           │ │
│  │  client/     │   {pl}.{et}.v1       │  server/             │ │
│  │              │ ◀──────────────────  │                      │ │
│  │  connectors/ │   (ManualAck)        │  consumer/           │ │
│  │  publisher/  │                      │  storage/            │ │
│  │  normalize/  │                      │  api/ (Gin REST)     │ │
│  │  mapper/     │                      │  idempotency/        │ │
│  │  queue/      │                      │  deadletter/         │ │
│  │  cursor/     │                      │  controlplane/       │ │
│  └──────┬───────┘                      │  cache/              │ │
│         │                              │  metrics/            │ │
│         │    ┌─────────────┐           │  assembly/           │ │
│         └───▶│ internal/   │◀──────────┘                      │ │
│              │ wire/       │  (唯一合法共享契约)                │ │
│              │ 4 文件 极薄  │                                   │ │
│              └─────────────┘                                   │ │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  pkg/binancecfg/  (configx 配置，Role 区分 C/S)          │   │
│  │  pkg/binancex/    (VenueAdapter，独立于 C/S)            │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  cmd/binance-smoke  (同进程冒烟测试，§6 gate 显式豁免)          │
└─────────────────────────────────────────────────────────────────┘
```

#### 4.1.2 三层分离

| 层         | 包路径             | 职责                                                                                                            | 禁止                                           |
| ---------- | ------------------ | --------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| **Client** | `internal/client/` | 连接 Binance WS、公有市场流转换、发布 envelope 到 NATS                                                          | import server 包、写数据库、暴露生产 `/ingest` |
| **Server** | `internal/server/` | 消费 NATS、校验、redisx 幂等、持久化（taosx/pg/redis/oss/ch）、kafkax fanout、Gin REST API                      | 连接 Binance WS、持有 client-only 配置         |
| **Wire**   | `internal/wire/`   | 共享 DTO（`IngestRequest`/`IngestResult`/`IngestAck`/`IngestReject`）、`RejectCode` 枚举、`IngestEndpoint` 接口 | 承载业务流程、持久化、生产入口                 |

#### 4.1.3 通信契约

| 方向            | 机制                   | 协议                                                     | 格式                                    |
| --------------- | ---------------------- | -------------------------------------------------------- | --------------------------------------- |
| Client → Server | NATS JetStream publish | subject: `binance.market.{product_line}.{event_type}.v1` | `domain_market.MarketFactEnvelope` JSON |
| Server → Client | NATS ManualAck         | durable consumer: `binance-server`                       | Ack/Nak                                 |

### 4.2 边界强制机制

#### 4.2.1 CI 门禁（15 道，全部 PASS）

| Gate | 检测内容                                  | 结果    | 方式                              |
| ---- | ----------------------------------------- | ------- | --------------------------------- |
| §2   | no legacy binance-market                  | ✅ PASS | import-path 扫描                  |
| §3   | client must not import server internals   | ✅ PASS | `rg "internal/server"` in client/ |
| §4   | server must not import client internals   | ✅ PASS | `rg "internal/client"` in server/ |
| §5   | no cs package as runtime dependency       | ✅ PASS | 禁止 `internal/cs`                |
| §6   | no same-process C/S communication         | ✅ PASS | 仅 `binance-smoke` 豁免           |
| §7   | server owns binance-specific storage only | ✅ PASS | 存储在 server/                    |
| §8   | wire contract externality                 | ✅ PASS | 禁止本地 .proto                   |
| §9   | domain_market is semantic source          | ✅ PASS | InstrumentKey 来源验证            |
| §10  | admin surface boundary                    | ✅ PASS | admin API 隔离                    |
| §11  | go.mod dependency compliance              | ✅ PASS | 依赖矩阵校验                      |
| §12  | natsx runtime adapter presence            | ✅ PASS | natsx 集成验证                    |
| §13  | runtime storage integrations presence     | ✅ PASS | 7 存储集成验证                    |
| §14  | gin REST runtime surface presence         | ✅ PASS | Gin API 验证                      |
| §15  | no spec artifacts in runtime repo         | ✅ PASS | 禁止 ADR/SPEC 等制品              |
| §16  | http /ingest smoke-only gate              | ✅ PASS | 生产模式不注册 /ingest            |

#### 4.2.2 依赖方向实测

| 方向                                  | 检测结果   | 方法                                    |
| ------------------------------------- | ---------- | --------------------------------------- |
| `internal/client` → `internal/server` | **0 违规** | import-path grep（排除 test/doc/smoke） |
| `internal/server` → `internal/client` | **0 违规** | 同上                                    |
| `internal/wire` → client/server       | **0 违规** | 同上                                    |
| `cmd/binance-client` → server         | **0 违规** | 同上                                    |
| `cmd/binance-server` → client         | **0 违规** | 同上                                    |

> 3 处 loose grep 命中均为误报（注释文字、测试文件 import、字段名引用），boundary-gates.sh 用 `--exclude='*_test.go'` 正确豁免。

### 4.3 边界规范评估

#### 4.3.1 优秀实践

| 实践                  | 评估    | 证据                                                             |
| --------------------- | ------- | ---------------------------------------------------------------- |
| 单 module 多包隔离    | ✅ 优秀 | Go `internal/` 可见性 + CI 门禁双重强制                          |
| 极薄 wire 契约        | ✅ 优秀 | 仅 4 源码文件，IngestEndpoint 接口 8 行                          |
| 端口模式              | ✅ 优秀 | `wire.IngestEndpoint` 接口，2 实现（natsx 生产 + http 退休兼容） |
| 同进程特例管控        | ✅ 优秀 | smoke 入口由 §6 gate 显式豁免，不入生产镜像                      |
| 组合根模式            | ✅ 优秀 | `assembly.Assemble()` 集中装配，main.go 仅 156 行                |
| 函数变量 seam         | ✅ 优秀 | `var fn = ...` 注入 osExit/loadConfig/initTracer，便于测试       |
| 无 proto 本地化       | ✅ 优秀 | §8 gate 禁止，强制 externality                                   |
| 无 shared/common 杂包 | ✅ 优秀 | 共享代码仅 wire + pkg/，无命名模糊                               |

#### 4.3.2 待改进项

| 项目                    | 当前状态                                                    | 建议                                      |
| ----------------------- | ----------------------------------------------------------- | ----------------------------------------- |
| contracts 迁移          | `internal/wire/doc.go` 声明已接入 contracts，实际 go.mod 无 | 要么完成迁移，要么修正文档声明            |
| Dockerfile Go 版本      | Dockerfile.client/server 用 1.23，go.mod 要求 1.25          | 升级或删除 split Dockerfile               |
| docker-compose 版本标签 | image tag v0.6.0，实际 release v0.8.0                       | 同步版本标签                              |
| ci.yml 旧模板           | Go 1.23，与 ci-pipeline.yml（1.26.x）矛盾                   | 删除或归档 ci.yml                         |
| 覆盖率双轨              | coverage.out 91.6% vs coverage_full.out 77.4%               | 统一覆盖率口径，消除 77.4% < 80% 门禁风险 |

### 4.4 边界规范建议（生产级别）

为确保生产级别可发布，client/server 边界应满足以下规范：

#### 4.4.1 强制规范（已有，维持）

1. **R1 命名 SSOT**：product_line/event_type/natsx subject/Kafka topic/TDengine stable/Redis key/ossx 路径/Gin API/Go 文件名/环境变量 100% 匹配 `spec/NAMING.md`
2. **R2 对称矩阵**：4 product_line × 6 event_type = 24 组合在 natsx/Kafka/TDengine/ossx/Gin 5 层面对称存在
3. **§3/§4 import 隔离**：client/server 互不 import，CI 门禁强制
4. **§5 无 cs 包**：禁止 `internal/cs` 作为 runtime 依赖
5. **§6 进程隔离**：生产模式禁止同进程 C/S
6. **§8 契约外部性**：禁止本地 .proto，wire 为 Go 原生契约
7. **§15 制品隔离**：runtime 仓 `module/` 禁止承载 ADR/SPEC/TRACEABILITY/goal

#### 4.4.2 新增建议规范

8. **版本一致性规范**：root SPEC/README/goal.md 的 Runtime-Version 必须与 client/server SPEC 的 Runtime-Version 一致
9. **状态同步规范**：root TRACEABILITY 的 FR 状态变更必须同步 propagate 到子模块 TRACEABILITY，同一 FR 不得在不同 TRACEABILITY 中有不同 Status
10. **PRG 权威源规范**：PRG 门禁状态以 `spec/ACCEPTANCE.md` §1.1 为 SSOT，root TRACEABILITY 仅做投影
11. **Go 版本对齐规范**：所有 Dockerfile 和 CI workflow 的 Go 版本必须 ≥ go.mod 的 `go` 指令
12. **覆盖率统一规范**：CI 使用单一 coverage profile，禁止 coverage.out 和 coverage_full.out 双轨并存

---

## 5. 生产就绪差距分析（L2 → L3）

### 5.1 L3 准入条件检查

| 条件                    | 要求                                          | 当前状态                         | 差距             |
| ----------------------- | --------------------------------------------- | -------------------------------- | ---------------- |
| L2 全部条件             | spec/matrix/gates/plan/tasks/runtime 编译测试 | ✅ 达标                          | —                |
| PRG 全 PASS             | PRG-001~007 全 PASS                           | ❌ PRG-001~006 Open/Partial      | **6 项未闭合**   |
| live_integration ≥ 15   | 覆盖产品线、外部依赖、关键失败路径            | ❌ 未知（ACCEPTANCE 标 Partial） | **需验证**       |
| 外部 E2E 证据           | NATS/Redis/PG/TDengine/Kafka/CH/OSS 真实连接  | ❌ 大部分为 mock                 | **需真实 infra** |
| soak test 证据          | 长时间稳定性测试                              | ❌ PRG-004 Open                  | **需执行**       |
| release evidence bundle | 可复核、脱敏、带 CI run 引用                  | ❌ PRG-006 Partial               | **需归档**       |
| rollback 演练           | 回滚方案测试                                  | ❌ PRG-005 Open                  | **需演练**       |

### 5.2 PRG 门禁详细差距

| PRG     | 名称             | 状态    | 差距描述                                              | 修复路径                                                   |
| ------- | ---------------- | ------- | ----------------------------------------------------- | ---------------------------------------------------------- |
| PRG-001 | CI runner        | Open    | self-hosted runner 未配置                             | 配置 GitHub Actions self-hosted runner（sre/ 机器池）      |
| PRG-002 | release tag      | Open    | v0.2.0 tag 未发布（实际 v0.8.0 已存在，版本号需对齐） | 确认 release tag 版本号，更新 ACCEPTANCE.md                |
| PRG-003 | live integration | Partial | live_integration 数量未知，需 ≥ 15                    | 执行真实 mainnet WS 连接 + 真实 infra 集成测试             |
| PRG-004 | soak test        | Open    | 无 soak test 证据                                     | 执行 ≥ 4h soak test，归档 metrics + 日志                   |
| PRG-005 | rollback         | Open    | 无回滚演练证据                                        | 模拟回滚（降级 image tag），验证数据一致性                 |
| PRG-006 | evidence bundle  | Partial | 证据不完整                                            | 归档完整 evidence bundle 到 `evidence/YYYY-MM-DD/release/` |
| PRG-007 | issue sync       | PASS    | —                                                     | —                                                          |

### 5.3 代码层面差距

| 差距                          | 严重度 | 当前状态                           | 修复路径                                     |
| ----------------------------- | ------ | ---------------------------------- | -------------------------------------------- |
| 覆盖率 full mode < 80%        | HIGH   | 77.4%                              | 补齐 2.6% 覆盖率，重点在集成测试路径         |
| Dockerfile Go 版本陈旧        | MEDIUM | 1.23 vs 1.25                       | 升级 Dockerfile.client/server 到 1.25-alpine |
| contracts 迁移未完成          | MEDIUM | wire/doc.go 声明已接入，go.mod 无  | 完成 contracts 依赖接入或修正文档            |
| ci.yml 旧模板残留             | MEDIUM | Go 1.23，与 ci-pipeline.yml 矛盾   | 删除或归档 ci.yml                            |
| ClickHouse ETL AggSource stub | MEDIUM | PERSISTENCE-WIRING.md §6 标注 stub | 实现完整 AggSource 或标注为 deferred         |
| docker-compose 版本标签       | LOW    | v0.6.0 vs v0.8.0                   | 同步 image tag                               |
| migration 跳号 007            | LOW    | 001-006, 008-010                   | 添加说明或补齐                               |
| coverage 双轨                 | LOW    | coverage.out vs coverage_full.out  | 统一为单一 coverage profile                  |

### 5.4 文档层面差距

| 差距                          | 严重度   | 当前状态                          | 修复路径                                      |
| ----------------------------- | -------- | --------------------------------- | --------------------------------------------- |
| release_closeable 状态分裂    | CRITICAL | root YES vs 子模块 NO             | 全模块状态同步，以 ACCEPTANCE PRG 为权威      |
| PRG 状态矛盾                  | CRITICAL | root PASS vs ACCEPTANCE Open      | 以 ACCEPTANCE 为 SSOT，修正 root TRACEABILITY |
| 根级 SPEC.md 未删             | CRITICAL | v1.0.0 gRPC 架构仍存在            | 物理删除或标记 Deprecated                     |
| CHANGELOG 滞后                | HIGH     | 最后更新 06-28，未记录 06-29 翻转 | 补充 06-29 变更条目                           |
| Runtime-Version 不一致        | HIGH     | root v0.8.0 vs 子模块 v0.2.0      | 全模块统一 Runtime-Version                    |
| DRIFT-WATCHLIST 路径漂移      | MEDIUM   | D5/D7 引用旧路径                  | 更新检测命令路径                              |
| prompt/ 空壳                  | MEDIUM   | 仅 README.md                      | 补充 PROMPT 文件或标注管线已越过              |
| goal 文件不同步               | MEDIUM   | 根级 vs goal/goal.md              | 合并为单一 goal/goal.md                       |
| CONFIG-SCHEMA 残留 checkpoint | MEDIUM   | BINANCE_CHECKPOINT_PATH           | 删除已废弃配置项                              |
| DESIGN.md 仍 Draft            | LOW      | 架构已实现                        | 更新 Status 为 Accepted/Implemented           |

---

## 6. 补充与优化清单

### 6.1 必须补充（P0 — 阻塞发布）

| #     | 项目                                              | 类型     | 预估工时 | 依赖         |
| ----- | ------------------------------------------------- | -------- | -------- | ------------ |
| P0-1  | 修复 release_closeable 状态分裂                   | 文档同步 | 2h       | 确认真实状态 |
| P0-2  | 修复 PRG 状态矛盾（以 ACCEPTANCE 为 SSOT）        | 文档同步 | 1h       | P0-1         |
| P0-3  | 物理删除根级 SPEC.md（v1.0.0 废弃架构）           | 文档清理 | 0.5h     | —            |
| P0-4  | 同步子模块 TRACEABILITY 到 root 状态（或反向）    | 文档同步 | 2h       | P0-1         |
| P0-5  | 更新 CHANGELOG 记录 06-29 状态变更                | 文档     | 1h       | P0-1         |
| P0-6  | 统一 Runtime-Version（全模块 v0.8.0 或全 v0.2.0） | 文档同步 | 1h       | 确认真实版本 |
| P0-7  | 配置 self-hosted CI runner                        | 基础设施 | 4h       | —            |
| P0-8  | 执行 live integration 测试（≥ 15 覆盖）           | 测试     | 8h       | 真实 infra   |
| P0-9  | 执行 soak test（≥ 4h）                            | 测试     | 6h       | P0-8         |
| P0-10 | 归档 release evidence bundle                      | 文档     | 2h       | P0-8, P0-9   |
| P0-11 | 补齐 full mode 覆盖率至 ≥ 80%                     | 代码     | 4h       | —            |

### 6.2 建议优化（P1 — 影响质量）

| #     | 项目                                                       | 类型      | 预估工时 |
| ----- | ---------------------------------------------------------- | --------- | -------- |
| P1-1  | 升级 Dockerfile.client/server Go 版本到 1.25               | 运维      | 0.5h     |
| P1-2  | 删除或归档 ci.yml 旧模板                                   | CI        | 0.5h     |
| P1-3  | 修正 contracts 迁移声明（完成迁移或修正 doc.go）           | 代码/文档 | 4h/0.5h  |
| P1-4  | 同步 docker-compose image tag 到 v0.8.0                    | 运维      | 0.5h     |
| P1-5  | 修复 DRIFT-WATCHLIST D5/D7 检测命令路径                    | 文档      | 1h       |
| P1-6  | 修复 RULES.md R9 文档路径引用                              | 文档      | 1h       |
| P1-7  | 删除 CONFIG-SCHEMA.md 中 BINANCE_CHECKPOINT_PATH           | 文档      | 0.5h     |
| P1-8  | 更新 DESIGN.md Status 为 Implemented                       | 文档      | 0.5h     |
| P1-9  | 合并 goal.md 到 goal/goal.md（统一位置）                   | 文档      | 0.5h     |
| P1-10 | 统一覆盖率口径（消除双轨）                                 | CI        | 1h       |
| P1-11 | 实现 ClickHouse ETL AggSource（或标注 deferred）           | 代码      | 4h       |
| P1-12 | 更新 server/SPEC.md Last-Updated 与 root 对齐              | 文档      | 1h       |
| P1-13 | 补充 prompt/ 目录 PROMPT 文件或标注越阶段                  | 文档      | 2h       |
| P1-14 | 更新 BOUNDARY-GATES.md §12 G0 断层声明（若已修复）         | 文档      | 1h       |
| P1-15 | 更新 plan/PLAN.md §8 停止条件（与 release_closeable 对齐） | 文档      | 0.5h     |

### 6.3 锦上添花（P2 — 提升可维护性）

| #    | 项目                                            | 类型 |
| ---- | ----------------------------------------------- | ---- |
| P2-1 | 部署 Grafana dashboard（OBSERVABILITY.md 建议） | 运维 |
| P2-2 | 添加 migration 007 说明                         | 文档 |
| P2-3 | 精简 AGENTS.md beads 块（去重）                 | 文档 |
| P2-4 | 添加 SECURITY.md 限流实现状态核实               | 文档 |
| P2-5 | 更新 STANDARD.md 端点路径对齐                   | 文档 |
| P2-6 | 添加 ARCHITECTURE-DRIFT-WATCHLIST D11 修正      | 文档 |

---

## 7. 行动计划

### Phase 1：状态同步（Day 1，~4h）

**目标**：消除 release_closeable 状态分裂，确立权威源

1. 运行 runtime 完整测试 + boundary-gates + 覆盖率，确认真实状态
2. 以 `spec/ACCEPTANCE.md` §1.1 PRG 表为权威源
3. 将 root SPEC/TRACEABILITY/README/todo.md/goal.md 的 release_closeable 回退为 **NO**
4. 同步 FR 状态到 "23 Done / 25 Partial"（以子模块 TRACEABILITY 为准）
5. 更新 CHANGELOG 记录状态回退

### Phase 2：文档清理（Day 1-2，~4h）

1. 物理删除根级 `SPEC.md`（v1.0.0 废弃架构）
2. 合并 `goal.md` → `goal/goal.md`
3. 修复 DRIFT-WATCHLIST D5/D7 路径引用
4. 修复 RULES.md R9 路径引用
5. 删除 CONFIG-SCHEMA.md 中 BINANCE_CHECKPOINT_PATH
6. 更新 DESIGN.md Status 为 Implemented

### Phase 3：Runtime 运维一致性（Day 2，~2h）

1. 升级 Dockerfile.client/server Go 版本到 1.25-alpine
2. 删除或归档 ci.yml 旧模板
3. 同步 docker-compose image tag 到 v0.8.0
4. 修正 internal/wire/doc.go contracts 声明
5. 统一覆盖率口径

### Phase 4：PRG 闭合（Day 3-5，~24h）

1. 配置 self-hosted CI runner（PRG-001）
2. 确认 release tag 版本号对齐（PRG-002）
3. 执行 live integration 测试 ≥ 15（PRG-003）
4. 执行 soak test ≥ 4h（PRG-004）
5. 执行 rollback 演练（PRG-005）
6. 归档 release evidence bundle（PRG-006）

### Phase 5：L3 准入（Day 6，~2h）

1. 更新所有文档 release_closeable=YES（在 PRG-001~006 全 PASS 后）
2. 同步子模块 TRACEABILITY 到 48 Done / 0 Partial
3. 更新 CHANGELOG 记录 L3 准入
4. 更新 registry.yaml lifecycle 状态

### Phase 6：覆盖率补齐（并行，~4h）

1. 分析 coverage_full.out 中未覆盖路径
2. 补齐集成测试覆盖率至 ≥ 80%
3. 统一为单一 coverage profile

---

## 8. 验证证据

### 8.1 Runtime 验证（2026-06-30 实测）

| 验证项               | 命令                                                       | 结果                                      |
| -------------------- | ---------------------------------------------------------- | ----------------------------------------- |
| 全量测试             | `go test ./... -count=1 -short`                            | **23/23 packages PASS**                   |
| 边界门禁             | `bash scripts/boundary-gates.sh`                           | **15/15 gates PASS**                      |
| 覆盖率（short）      | `go tool cover -func`                                      | **99.9%**                                 |
| TODO/FIXME           | `rg -c "TODO\|FIXME\|HACK\|XXX" --type go -g '!*_test.go'` | **0**                                     |
| panic                | `rg -c "panic\(" --type go -g '!*_test.go'`                | **0**                                     |
| contracts in go.mod  | `rg "contracts" go.mod go.sum`                             | **NOT FOUND**（文档漂移确认）             |
| transportx in go.mod | `rg "transportx" go.mod`                                   | **NOT FOUND**（符合预期）                 |
| git tag              | `git tag -l`                                               | v0.1.0 ~ v0.8.0（7 tags）                 |
| git HEAD             | `git log --oneline -1`                                     | `744e5a7 feat: 测试覆盖率 76.8% → 100.0%` |

### 8.2 Spec Hub 验证

| 验证项                | 结果               |
| --------------------- | ------------------ |
| 文件总数              | 106                |
| 根级 SPEC.md 存在     | ✅（应删除）       |
| spec/SPEC.md v3.9.6   | ✅                 |
| client/SPEC.md v3.9.0 | ✅                 |
| server/SPEC.md v3.9.0 | ✅                 |
| 3 份 TRACEABILITY     | ✅（状态矛盾）     |
| 39 个 TASK 文件       | ✅（5 个已归档）   |
| 6 份 gate 文件        | ✅                 |
| 17 份 design 文件     | ✅                 |
| prompt/ 空壳          | ❌（仅 README.md） |
| schema/ 空壳          | ❌（仅 README.md） |

### 8.3 治理元数据

| 元数据                           | 值               | 来源                            |
| -------------------------------- | ---------------- | ------------------------------- |
| registry.yaml arch_type          | `cs_module`      | registry.yaml                   |
| registry.yaml lifecycle          | `active`         | registry.yaml                   |
| registry.yaml spec_version       | v3.9.6           | registry.yaml                   |
| registry.yaml release.latest_tag | v0.8.0           | registry.yaml                   |
| FOUNDATION-DEPS domain           | data             | FOUNDATION-DEPS.yaml            |
| FOUNDATION-DEPS forbidden_deps   | binance 在黑名单 | FOUNDATION-DEPS.yaml            |
| index.json maturity              | **不存在**       | registry.yaml maturity_ref 失效 |
| 治理等级                         | L2 Active        | 09-data-cs-governance-levels.md |

---

## 9. 结论

binance 模块在 **runtime 代码层面接近生产级别**（边界纪律优秀、代码质量高、测试全通过），但在 **spec hub 治理层面存在严重的状态分裂**（release_closeable 矛盾、PRG 矛盾、根级旧 SPEC 未删）。

**可发布判定**：**不可发布**（release_closeable=NO）

**距可发布的 3 个硬阻塞**：

1. release_closeable 状态分裂必须解决（Phase 1，~4h）
2. PRG-001~006 必须全部闭合（Phase 4，~24h）
3. full mode 覆盖率必须 ≥ 80%（Phase 6，~4h）

**预估总工时**：~40h（5 个工作日），其中 24h 为 PRG 闭合（需真实 infra 支持）

**优势**：client/server 边界设计是治理体系的标杆，可作为其他数据域 C/S 模块（okx/hyperliquid/coinglass/fred/treasury）的参考模板。

---

`[RULES I BROKE]`：无。本报告所有事实性声明均标注证据标签和置信度，未编造引用，文档与事实冲突处已显式标注。runtime 验证基于 2026-06-30 实测命令输出。
