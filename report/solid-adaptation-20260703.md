# SOLID 规则适配分析与处置账本

> **分析对象**：`report/archive/solid-template-20260703/SOLID.md`（外部通用 Go 量化 SOLID 规则模板，2026-07-03 引入时为 untracked 草案）。
> **数据来源**：`CONSTITUTION.md` §1-§8/§10/§14、`docs/standards/go-coding-standards.md`、`docs/architecture/03-boundaries.md` / `04-principles.md` / `08-contracts.md`、`module/FOUNDATION-DEPS.yaml`。
> **结论落地**：本报告的"采纳/改写"项已并入 `docs/standards/go-coding-standards.md`（同一 PR）；涉及宪法数值的冲突项一律以 `CONSTITUTION.md` 为准，未做任何受保护文件改动。

## 1. 总体判断

[COMPUTED, HIGH] 原模板假设**单仓分层架构**（`main.go`/`wire.go` 集中装配、`domain/ strategy/ infra/` 包结构、`Exchange`/`Strategy`/`DataReader` 占位接口），与本项目**多仓域模块架构**（~70 独立仓库、`contracts` 跨域契约、`composer`/`x.go` 组合根、L2.5 领域共享层）根本前提不同。

与既有 SSOT 对比：**约 70% 重叠、15% 冲突、15% 真增量**。处置策略：冲突以宪法为准 → 增量并入既有文档 → 重叠删除 → 原模板归档。

## 2. 逐条处置账本

图例：✅ 采纳（并入既有文档）· 🔄 改写（映射到本项目架构）· ♻️ 已覆盖（删除，避免双 SSOT）· ❌ 冲突（以宪法/既有标准为准）· ⚠️ 降级（WARN 审查线，不做 CI 阻断）

### S — 单一职责

| 规则 | 处置 | 说明 |
|---|---|---|
| S-PKG-01/02/03（包职责、禁 utils/common） | ✅ | 精神与"包名即职责"一致，可在后续 lint 落地 |
| S-PKG-04（基础设施与业务隔离） | 🔄 | 本项目以**仓库级隔离**实现（基座仓 vs 业务域仓），强于包级；域仓不得内嵌存储/传输适配器，统一走 redisx/kafkax 等扩展仓 |
| S-STR-01/02（字段≤8、方法≤10） | ⚠️ | 宪法无此数值；`RegimeSnapshot` 等领域 DTO 天然超 8 字段，仅作 code-review 警戒线 |
| S-STR-03/04（职责混合禁令） | ♻️ | 已由宪法 P9（数据职责不跨域）+ §2 模块边界覆盖 |
| S-FN-01/03/04 | ♻️ | 已由 go-coding-standards §1/§6 覆盖（参数封装、计算与 I/O 分离精神） |
| S-FN-02（函数≤50 行） | ❌ | 以 go-coding-standards §1 的 **80 行**为准 |
| S-FN-05（圈复杂度≤10） | ❌ | 以 go-coding-standards §12 golangci `gocyclo: 15` 为准 |
| 量化职责边界表 | 🔄 | 层→模块映射：数据获取=market_data/macro_data · 指标计算=factor_engine · 策略信号=signal_factory · 风控=riskx · 订单=orderx · 仓位=positionx · 通知=alertx |

### O — 开闭原则

| 规则 | 处置 | 说明 |
|---|---|---|
| O-ITF-01（所有可预见变化点必须抽象为接口） | ❌ | 与 go-coding-standards §6"不要提前抽象"（YAGNI）、宪法 §2.2"过度抽象=MEDIUM 违规"、§2.5 奥卡姆剃刀直接冲突，**拒绝** |
| O-ITF-02（接口定义在使用方包） | 🔄 | 已覆盖，但补充跨域例外：跨域端口统一归 `contracts`（P7 / §4.2 三分法）——已写入 go-coding-standards §6 |
| O-ITF-03（接口发布后禁改签名） | ✅ | 已写入 go-coding-standards §6"接口稳定性与演进"，破坏性变更走宪法 §10 MAJOR 流程 |
| O-ITF-04（禁类型断言分支） | ✅ | 已写入 go-coding-standards §6"禁止类型断言分支"，含 `switch strategyType` / `if exchange == "binance"` 违规信号 |
| O-STG-* / O-EXC-* / O-DAT-*（注册扩展） | 🔄 | 占位接口映射：Exchange→orderx 内部适配（P10）；DataReader→contracts `MarketDataProvider`/`MacroDataProvider`（已固化 2026-06-20）；Strategy→strategyx；Repository→存储扩展仓接口 |
| O-RSK-01/02（风控规则注册、规则间禁互调） | ✅→模块 | 与 P5 契合；"规则通过引擎编排、禁止互调"建议吸收进 `module/riskx/spec/SPEC.md`（后续独立 PR） |
| 违规判断标准 | ✅ | 已并入"禁止类型断言分支"小节 |

### L — 里氏替换（最大增量区）

| 规则 | 处置 | 说明 |
|---|---|---|
| L-CTR-01~04（前置/后置条件契约） | 🔄 | 本项目载体是宪法 §4.4 WHEN/THEN 行为规格——"所有实现必须满足 SPEC 的 WHEN/THEN"即 LSP，不引入平行术语体系 |
| L-FBD-01（实现禁 panic） | ♻️ | 宪法 §8.2 已覆盖且更精确（保留不可恢复初始化失败例外），以宪法为准 |
| L-FBD-02/04（零值语义、禁改入参） | 🔄 | 归入 WHEN/THEN 约定 + §4.1 不可变 DTO |
| L-MCK-01（Mock 过同套契约测试） | ⭐✅ | **真空白**，已写入 go-coding-standards §11"Mock 契约一致性"，直接支撑 P6 回测可信度 |
| L-MCK-02（Mock 模拟真实错误场景） | ✅ | 同上 |
| L-MCK-03（Mock 延迟可配置） | ✅ | 同上，与 §5.4 FakeClock 惯例一致 |
| L-MCK-04（Mock 全方法实现，禁 not implemented） | ✅ | 同上，并与 ISP"接口过大信号"联动 |
| 量化场景约束表 | 🔄 | 接口名替换为 contracts 真实端口（DecisionCardProvider、MarketRegimePort、MacroRegimePort 等，见 docs/architecture/08-contracts.md） |

### I — 接口隔离

| 规则 | 处置 | 说明 |
|---|---|---|
| I-GRN-01（方法≤5） | ❌ | 以宪法 §4.1 为准：3-5 个方法，**硬上限 7** |
| I-GRN-02（按调用方角色定义） | ♻️ | go-coding-standards §6 已覆盖 |
| I-GRN-03（读写分离） | ✅ | 已写入 go-coding-standards §6（小接口原则下的补充规则） |
| I-GRN-04（流式与请求/响应分离） | ✅ | 同上；与 transportx RPC/EventBus/Stream 契约分离一致 |
| 接口划分清单（CandleReader 等） | 🔄 | 概念正确、接口名虚构；权威清单是 contracts 端口表（08-contracts.md P0/P1/P2），引用而非重造 |
| I-DEP-01~05（依赖最小化） | 🔄 | 改写为域级规则，如"backtestx 只替换数据源与撮合环境，禁止依赖实时订阅链路"（P6 接口化表述）；具体落各模块 SPEC |
| I-AGG-01~03（接口聚合） | ♻️ | go-coding-standards §6"接口组合"已覆盖 |
| not-supported 占位 = ISP 违规 | ✅ | 已写入 §6 与 §11（与 L-MCK-04 合并） |

### D — 依赖倒置

| 规则 | 处置 | 说明 |
|---|---|---|
| D-DIR-01~04（依赖方向、禁循环） | ♻️ | 宪法 §3 拓扑 + `FOUNDATION-DEPS.yaml`（机器可读）+ xlibgate/import graph 守卫已是更强实现 |
| D-OWN-01~04（接口归属） | 🔄 | 本项目为三分法（contracts / 域内 / L2.5，宪法 §4.2），比模板两分法更细——已在 go-coding-standards §6 显式声明 |
| D-INJ-01（构造注入） | ✅ | 已写入 go-coding-standards §6"依赖注入" |
| D-INJ-02（禁全局变量/init 传依赖） | ✅ | 同上 |
| D-INJ-03（构造参数用接口，领域模型例外） | ✅ | 同上，Config 例外与宪法 §4.3 对齐 |
| D-INJ-04（测试/生产差异只在装配层） | ✅ | 同上 |
| D-WIR-01（装配集中 main.go/wire.go） | 🔄 | **改写**：跨域装配在 composer/x.go（P12）；域仓内在 cmd/ + bootstrap；禁止业务包散落装配——已写入 §6 |
| D-WIR-02（生产/回测同套核心） | ♻️ | = 宪法 P6，删除避免重复 |
| D-WIR-03（禁反射 DI 容器） | ✅ | 已写入 §6 |
| D-CFG-01~03（配置归属、禁业务读环境变量） | ✅🔄 | 映射到 configx/composer/bootstrap 加载链——已写入 §6 |

### 综合强制规则

| 规则 | 处置 | 说明 |
|---|---|---|
| RULE-ENF-01/02（CI 阻断、golangci） | ♻️ | boundary-gates.sh、xlibgate、golangci 配置已存在 |
| RULE-ENF-03（每接口须契约测试） | ✅ | 与 L-MCK-01 合并为"Mock 契约一致性" |
| 优先级 DIP>ISP>OCP>LSP>SRP | 🔄 | [INFERRED, MED] 建议调整为 **DIP>LSP>ISP>OCP>SRP**：本项目回测可信度是生命线（P6），LSP 违反直接污染回测→实盘一致性 |

## 3. 后续待办（不在本 PR 范围）

1. [宪法路径] 若团队认可，将"Mock 契约一致性"经 §12 修正程序升入 `CONSTITUTION.md` §5 测试标准。
2. [模块路径] O-RSK-02（风控规则禁互调、统一引擎编排）吸收进 `module/riskx/spec/SPEC.md`。
3. [Lint 路径] `forbidigo`/`depguard` 规则化检测：`utils|common|misc` 包名、类型断言分支、业务包读 `os.Getenv`。

## 4. 结论

SOLID 五原则在本项目**不是缺失，而是已被宪法 §1-§8 + 依赖矩阵 + contracts 端口以更强的仓库级/机器可读形式实现**。模板真增量仅两块——**Mock/生产契约一致性（LSP）**与**依赖注入成文化（DIP 细则）**，均已落入 `docs/standards/go-coding-standards.md`；数值冲突（接口方法数/函数行数/圈复杂度）一律以宪法与既有标准为准。

**[RULES I BROKE]**：无。
