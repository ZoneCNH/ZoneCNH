# binance 结构性深度分析、评分与优化方案

> [COMPUTED, HIGH] 本报告针对 `module/binance/` 的规格、追溯、验收、边界与报告制品做结构诊断，并用 `/home/binance@756fbc5` 做窄范围运行时锚点复核。  
> [COMPUTED, HIGH] 本报告是单代理结构诊断分，不是 `docs/governance/STRUCTURAL-SCORING.md` 定义的四源仲裁分；不能替代正式 pipeline gate。

## 0. 结论

[COMPUTED, HIGH] `module/binance/` 的核心架构方向是正确的：它已经把 Binance 特定采集、C/S 分离、natsx JetStream、server-side durable consume、storage/fanout 以及 `domain_market` 语义边界写进根规格与子规格。证据见 `module/binance/SPEC.md:21`、`module/binance/SPEC.md:76`、`module/binance/client/SPEC.md:18`、`module/binance/server/SPEC.md:25`。

[COMPUTED, HIGH] 主要结构性问题不在“有没有架构目标”，而在“事实状态、运行时锚点、验收证据、发布含义”四套口径没有闭合。`README.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`report/binance/INDEX.md` 与部分历史报告同时表达了不同版本的状态投影，导致同一模块可以被读成 `24 Done / 10 Partial / 10 Pending`、`24 Done / 10 Partial / 0 Pending` 或 “release_closeable=YES 但 production DoD 未完成”。证据见 `module/binance/README.md:7`、`module/binance/README.md:93`、`module/binance/TRACEABILITY.md:49`、`module/binance/ACCEPTANCE.md:7`、`report/binance/INDEX.md:17`。

[COMPUTED, MED] 建议当前结构诊断分为 **56/100**；若按仓库正式门禁 `composite_score = min(claude, codex, copilot, rules) >= 98` 且无红线的口径，本模块当前应判为 **FAIL-candidate**，不是可发布完成态。正式门禁规则见 `docs/governance/STRUCTURAL-SCORING.md:81`。

## 1. 评分口径

[COMPUTED, HIGH] 本次评分只衡量结构闭合度，不衡量业务价值：

| 维度                 |    权重 |   得分 | 主要依据                                              |
| -------------------- | ------: | -----: | ----------------------------------------------------- |
| 边界与所有权清晰度   |      20 |     18 | C/S、natsx、domain_market、legacy 禁止项明确          |
| 状态与证据一致性     |      20 |      9 | README/TRACE/ACCEPTANCE/INDEX 存在相互冲突投影        |
| 运行时装配与验收闭合 |      20 |     10 | 当前 runtime 有进展，但文档锚点滞后且 full E2E 未闭合 |
| 生产就绪控制         |      20 |      7 | PRG-001~007 与生产 gap 仍缺证据                       |
| 文档层级与版本卫生   |      10 |      6 | 子规格、边界门禁、mapping、历史报告有版本漂移         |
| 下游契约与变更防护   |      10 |      6 | 多下游依赖存在，但 schema/consumer 兼容 gate 不足     |
| **总分**             | **100** | **56** | 单代理诊断分                                          |

[COMPUTED, HIGH] 这个分数低于正式门禁并不意味着架构方向错误，而是说明“可验证事实链”没有闭合。

## 2. 结构性问题排序

### P0-1 状态事实模型分裂

[COMPUTED, HIGH] `module/binance/README.md:7` 写当前投影为 `24 Done / 10 Partial / 10 Pending`，但 `module/binance/README.md:93` 和 `report/binance/INDEX.md:17` 又保留 `24 Done / 10 Partial / 0 Pending` 口径。`module/binance/TRACEABILITY.md:49` 再次确认有效基线是 `24 Done / 10 Partial / 10 Pending`。  
[INFERRED, HIGH] 这会让读者无法判断 release、issue close、FR Done、AC/TC pass 哪一个才是 SSOT；它是当前最大结构风险。

### P0-2 运行时锚点漂移

[COMPUTED, HIGH] 多个文档仍引用 `/home/binance@f046e16` 或更旧锚点：`module/binance/SPEC.md:13`、`module/binance/TRACEABILITY.md:10`、`report/binance/INDEX.md:17`。`module/binance/BOUNDARY-GATES.md:8` 记录 `71e2a6e8`，`module/binance/BOUNDARY-GATES.md:24` 还保留旧 G0 storage fracture 描述。当前本地 runtime HEAD 是 `/home/binance@756fbc5`，且 `cmd/binance-server/main.go:90`、`cmd/binance-server/main.go:134` 显示 storage assembly 已经从旧的 `bootstrap.None` 裂缝中推进了一步。  
[INFERRED, HIGH] 文档锚点和 runtime 事实不同步会同时制造假阳性和假阴性：已修的点继续被报告为失败，未验证的新点又可能被误认为已接受。

### P0-3 发布关闭与生产完成被混读

[COMPUTED, HIGH] `module/binance/ACCEPTANCE.md:7` 写 Plan008 release gate closed、`release_closeable=YES`，但 `module/binance/ACCEPTANCE.md:49` 到 `module/binance/ACCEPTANCE.md:59` 把 PRG-001~PRG-007 全部列为 Pending evidence，`module/binance/ACCEPTANCE.md:175` 到 `module/binance/ACCEPTANCE.md:189` 也明确 production DoD 未完成。  
[INFERRED, HIGH] 当前应把 release evidence、FR implementation、AC/TC pass、production readiness 拆成四个不同布尔/枚举字段，禁止用 release tag 或 issue close 推导功能完成。

### P1-4 验收层级没有闭合到独立进程和真实外部依赖

[COMPUTED, HIGH] 规格要求 client/server 独立部署、只经 JetStream 通信，见 `module/binance/SPEC.md:21` 和 `module/binance/SPEC.md:76`。验收文档仍把独立进程、live Binance websocket、真实 Kafka broker、full JetStream、DLQ 等列为 pending/partial，见 `module/binance/ACCEPTANCE.md:16`、`module/binance/ACCEPTANCE.md:29`、`module/binance/ACCEPTANCE.md:112`。  
[INFERRED, HIGH] 这说明当前边界门禁主要证明了静态结构，不足以证明分布式 C/S 运行时契约成立。

### P1-5 生产就绪门禁是“写入规格”，不是“证据驱动状态”

[COMPUTED, HIGH] `module/binance/SPEC.md:91` 到 `module/binance/SPEC.md:104` 定义 PRG-001~PRG-007；`report/binance/production-gaps-audit-20260625.md:17` 到 `report/binance/production-gaps-audit-20260625.md:29` 列出 release safety、schema compatibility、distributed tracing、quota/resource isolation、cost observability、audit completeness、data compliance/deletion 等欠账。  
[INFERRED, HIGH] 这些 PRG 是正确的治理方向，但当前更像 backlog，而不是能改变验收状态的证据源。

### P1-6 文档版本和历史报告未完全降噪

[COMPUTED, HIGH] `module/binance/analysis/DEEP-ANALYSIS.md:1` 标记为 archived，但仍在 `module/binance/analysis/` 下可见，内容基于 v2.0.0/v3.5.0。`module/binance/server/SPEC.md:12` 仍是 Runtime-Version `v0.1.0`，而根 README 是 `v0.2.0`。`module/binance/RUNTIME-MAPPING.md:25` 到 `module/binance/RUNTIME-MAPPING.md:33` 保留更旧 baseline 与未证实点。  
[INFERRED, MED] 历史材料没有错，但缺少清晰的“只读历史/不可作为当前状态”的机器可校验边界。

### P1-7 Options subject/product_line 与元数据漂移仍未收口

[COMPUTED, HIGH] `module/binance/ARCHITECTURE-DRIFT-WATCHLIST.md:9` 到 `module/binance/ARCHITECTURE-DRIFT-WATCHLIST.md:34` 把 `product_line` 命名漂移和 Options depth subject/topic 缺口标为 HIGH。  
[INFERRED, MED] 这类问题会直接影响下游 topic、symbol identity、schema compatibility 和消费者回放。

### P2-8 下游契约防护不足

[COMPUTED, HIGH] `module/FOUNDATION-DEPS.yaml:480` 表明 `factor_engine`、`feature_store`、`factor_eval`、`signal_factory`、`strategyx`、`riskx`、`orderx`、`positionx` 等下游依赖 `binance`。`report/binance/production-gaps-audit-20260625.md:59` 到 `report/binance/production-gaps-audit-20260625.md:85` 指出 schema compatibility 只有字段/头部迹象，缺少版本策略和兼容测试。  
[INFERRED, HIGH] 对多下游市场数据模块而言，没有 schema compatibility gate 会把局部改动放大成跨域回归。

## 3. 完整优化方案

### Phase 0: 冻结事实口径

[INFERRED, HIGH] 目标是在 0.5 到 1 天内停止状态继续分叉。

1. [INFERRED, HIGH] 指定一个当前 runtime anchor，例如 `/home/binance@756fbc5`；若不采纳该锚点，则必须写明替代 SHA。
2. [INFERRED, HIGH] 建立四字段状态模型：`implemented`、`accepted`、`production_ready`、`release_closeable`。任何一个字段不得自动推导另一个字段。
3. [INFERRED, HIGH] 明确 `issue closed != FR Done`、`release_closeable=YES != production DoD`、`boundary gate pass != functional acceptance`。
4. [INFERRED, HIGH] 立刻清除或改写 `24 Done / 10 Partial / 0 Pending` 与 `24 Done / 10 Partial / 10 Pending` 的冲突投影，只保留一个 SSOT 和多个只读投影。

验收条件：[INFERRED, HIGH] `rg "24 Done / 10 Partial / 0 Pending|24 Done / 10 Partial / 10 Pending" module/binance report/binance` 的命中必须全部能解释为当前 SSOT 或历史归档。

### Phase 1: 状态与证据归一化

[INFERRED, HIGH] 目标是在 1 到 2 天内修复文档层级。

1. [INFERRED, HIGH] 修订 `README.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`BOUNDARY-GATES.md`、`RUNTIME-MAPPING.md`、`IMPLEMENTATION-PLAN.md` 的头部元数据和 runtime anchor。
2. [INFERRED, HIGH] 给历史报告增加统一归档横幅：历史报告不能作为当前完成状态证据。
3. [INFERRED, HIGH] 把 FR/BR/AC/TC/PRG 的状态源分开：FR 表只记录功能实现证据；AC/TC 记录验收命令和输出；PRG 记录生产 gate 证据。
4. [INFERRED, MED] 修正子规格元数据漂移，例如 server Runtime-Version 与根模块 Runtime-Version 的关系。

验收条件：[INFERRED, HIGH] 同一个状态字段在所有当前文档中只有一个值；历史值只出现在明确 archive 区域。

### Phase 2: 运行时证据闭环

[INFERRED, HIGH] 目标是在 2 到 4 天内补齐能证明 C/S 架构成立的运行时证据。

1. [INFERRED, HIGH] 用独立 client 进程、独立 server 进程、真实 NATS JetStream、真实 Kafka broker、真实 postgresx/taosx/redisx 环境运行 E2E。
2. [INFERRED, HIGH] 记录每条证据的 runtime SHA、命令、配置摘要、日志路径、成功条件和失败重试行为。
3. [INFERRED, HIGH] 覆盖关键链路：client PubAck、server durable consume、storage 成功后 Ack、Kafka handoff 成功后 Ack、失败 Nak/DLQ、server restart 后不丢数据。
4. [INFERRED, HIGH] smoke/test mode 只允许证明开发健康，不允许提升 production acceptance。

验收条件：[INFERRED, HIGH] AC/TC 每一条从 Pending/Partial 变化为 PASS 时都能指向具体命令输出、runtime SHA 与日志。

### Phase 3: 生产就绪门禁实现

[INFERRED, HIGH] 目标是在 5 到 10 天内把 PRG-001~PRG-007 从 checklist 变成可执行 gate。

1. [INFERRED, HIGH] PRG-001 release safety：增加 canary、rollback、artifact provenance、release workflow evidence。
2. [INFERRED, HIGH] PRG-002 schema compatibility：定义 schema version policy、兼容矩阵、向后兼容测试、破坏性变更审批。
3. [INFERRED, HIGH] PRG-003 tracing：贯通 `traceparent`/`tracestate`，覆盖 websocket ingest、JetStream、server consume、storage、Kafka fanout。
4. [INFERRED, HIGH] PRG-004 quota/resource isolation：按 product_line/symbol/stream 类型设置限流、队列、丢弃和告警策略。
5. [INFERRED, HIGH] PRG-005 audit completeness：补 append-only audit，覆盖 admin、data lifecycle、DLQ、reconcile、schema change。
6. [INFERRED, HIGH] PRG-006 HA/DR：补 broker/store 故障、恢复、重放、备份恢复演练。
7. [INFERRED, HIGH] PRG-007 capacity/cost/compliance：补吞吐基线、存储成本、保留策略、删除/脱敏流程。

验收条件：[INFERRED, HIGH] PRG 状态不再是文字声明，而是由 CI、脚本、日志或 runbook drill evidence 推动。

### Phase 4: 下游契约保护

[INFERRED, HIGH] 目标是在 2 到 5 天内降低跨模块回归风险。

1. [INFERRED, HIGH] 为 JetStream/Kafka topic、payload、headers、symbol identity、product_line 建立 contract fixture。
2. [INFERRED, HIGH] 对 `factor_engine`、`feature_store`、`factor_eval`、`signal_factory`、`strategyx`、`riskx`、`orderx`、`positionx` 建立消费者兼容 smoke 或 golden fixture。
3. [INFERRED, MED] 对 Options depth topic 和 product_line 命名漂移单独开修复任务，先修契约再改实现。

验收条件：[INFERRED, HIGH] 任何 topic/schema/header 改动都必须先通过兼容矩阵，否则不能把 FR 或 PRG 标为 Done。

### Phase 5: 治理自动化

[INFERRED, HIGH] 目标是在 1 到 2 天内把容易复发的漂移变成自动失败。

1. [INFERRED, HIGH] 增加文档一致性检查：同一模块只能有一个 current runtime anchor。
2. [INFERRED, HIGH] 增加状态投影检查：禁止 current 文档中同时出现冲突的 `Done / Partial / Pending` 摘要。
3. [INFERRED, HIGH] 增加归档报告检查：archive 报告必须有 archive banner，且不能被 current index 当作当前证据。
4. [INFERRED, HIGH] 增加子规格元数据检查：client/server/root 的版本关系必须显式一致或声明偏差原因。

验收条件：[INFERRED, HIGH] 这些检查进入边界或文档 gate，并能在状态漂移时失败。

## 4. 推荐执行顺序

| 顺序 | 任务                           | 产物                               | 不做的事                 |
| ---: | ------------------------------ | ---------------------------------- | ------------------------ |
|    1 | 冻结 runtime anchor 与状态模型 | current anchor + 四字段状态表      | 不顺手升级 FR            |
|    2 | 清理当前文档冲突投影           | README/TRACE/ACCEPTANCE/INDEX 一致 | 不改 runtime             |
|    3 | 补独立进程 E2E 证据            | 命令、日志、runtime SHA            | 不用 smoke 代替 prod     |
|    4 | 实现 PRG 可执行 gate           | CI/scripts/runbook drill           | 不用 checklist 冒充 gate |
|    5 | 补下游兼容矩阵                 | contract fixtures                  | 不先改 topic/schema      |
|    6 | 正式四源复评分                 | arbiter verdict                    | 不用本报告分数替代       |

## 5. 复评分条件

[INFERRED, HIGH] 优化后可以按以下标准复评：

| 条件       | 目标                                                          |
| ---------- | ------------------------------------------------------------- |
| 状态一致性 | 所有 current 文档只有一个状态投影                             |
| 证据锚点   | 所有 current evidence 绑定同一 runtime SHA 或明确多 SHA 范围  |
| C/S 运行时 | 独立 client/server + real JetStream/Kafka/store E2E 通过      |
| PRG gate   | PRG-001~007 至少都有可执行证据源                              |
| 下游兼容   | schema/topic/header 变更有消费者 fixture                      |
| 正式评分   | 四源 `min(score) >= 98`，无红线、低置信度、异常分差或异构分歧 |

[INFERRED, MED] 若 Phase 0~2 完成，结构分可从 56 提升到约 72~80；若 Phase 3~5 完成并通过正式四源 gate，才有资格接近 98 分门槛。

## 6. 停止条件

[COMPUTED, HIGH] 当前报告已经保存为 `report/binance/structural-analysis-optimization-20260626.md`。  
[INFERRED, HIGH] 后续整改的停止条件不是“报告写完”，而是：冲突投影消失、runtime evidence 可追溯、AC/TC/PRG 状态由证据驱动、正式四源 gate 通过。

[RULES I BROKE]：无
