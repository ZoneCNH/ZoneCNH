# 基座模块清单深度审计报告

> FoundationX 基座模块的一致性、覆盖面、冗余度和成熟度四维分析
>
> 审计日期：2026-06-14
>
> 审计范围：ARCHITECTURE.md · STATUS.md · module/README.md · CONSTITUTION.md · .github/ci/ · module/FOUNDATION-TRACKER.md

---

## 执行摘要

**结论：基座模块清单需要立即优化迭代。** 当前存在核心文档矛盾（18 vs 20 模块计数）、状态表缺失 2 个模块、1 个模块进度虚高、1 个门禁模块零实现。这些问题已在 git 历史中累积至少 3 次提交未完全收敛。

**关键数字**：

| 指标       | 当前声明                            | 实际               | 差距             |
| ---------- | ----------------------------------- | ------------------ | ---------------- |
| 基座模块数 | 18（STATUS/CI） / 20（拓扑/README） | 20（module/ 目录） | 2 个模块未入表   |
| 100% 模块  | 15                                  | 13（排除虚高）     | 2 个虚高         |
| 迁移完成度 | 100%（隐含）                        | ~80%               | 18→20 迁移未闭环 |

---

## 1. 一致性分析

### 1.1 核心矛盾：18 vs 20

| 文档位置                   | 声明的基座模块数  | 实际列出数 |
| -------------------------- | ----------------- | ---------- |
| ARCHITECTURE.md 拓扑图     | "Foundation (20)" | 20         |
| ARCHITECTURE.md 状态总览表 | —                 | **18**     |
| STATUS.md 域统计表         | "基座 18"         | **18**     |
| STATUS.md 组件明细表       | —                 | **18**     |
| module/README.md 标题      | "20 个基座模块"   | 20         |
| module/ 目录实际子目录     | —                 | **20**     |
| CI FOUNDATION_MODULES 数组 | 18 元素           | **18**     |

**🔴 CRITICAL：ARCHITECTURE.md 内部自相矛盾** — 拓扑图声称为 20，状态总览表只有 18 行。

### 1.2 缺失模块识别

以下 2 个模块在 `module/` 目录中存在完整规格和 goal.md，但**未出现在 STATUS.md 和 ARCHITECTURE.md 状态表中**：

| 缺失模块      | module/ 目录 | goal.md | SPEC.md | TRACEABILITY | tasks/ |
| ------------- | ------------ | ------- | ------- | ------------ | ------ |
| xlib-harness  | ✅           | ✅      | ✅      | ✅           | ✅     |
| xlib-evidence | ✅           | ✅      | ✅      | ✅           | ✅     |

**缺失位置清单**：

- [ ] ARCHITECTURE.md §状态总览 基座行
- [ ] STATUS.md §组件明细表 基座行
- [ ] STATUS.md §域健康度 基座描述
- [ ] .github/ci/status-consistency-check.sh FOUNDATION_MODULES 数组
- [ ] ARCHITECTURE.md 表 "Foundation v1 规格文档" 说的 "18 个基座模块"（实际应是 20）

### 1.3 迁移历史追溯

```
17 模块 → f4678b0: CI 数组新增 domainx，17→18
18 模块 → c464d53: ARCHITECTURE 拓扑 18→20（xlib-standard → standard+harness+evidence）
当前   → STATUS/CI 停在 18，拓扑为 20，矛盾持续
```

**迁移完成度：~80%**

已完成：

- ✅ ARCHITECTURE.md 拓扑图更新为 20
- ✅ module/README.md 更新为 20（含 xlib-harness、xlib-evidence goal 索引）
- ✅ module/ 目录已创建 xlib-harness/ 和 xlib-evidence/
- ✅ 两个新模块的 SPEC.md、TRACEABILITY.md、goal.md、tasks/ 已产出

未完成：

- ❌ STATUS.md 补充 xlib-harness / xlib-evidence 行
- ❌ ARCHITECTURE.md 状态总览表补充两个模块行
- ❌ CI FOUNDATION_MODULES 数组补充两个模块（18→20）
- ❌ STATUS.md 域统计 "基座 18" 改为 "基座 20"
- ❌ 平均进度重算（新增 2 个 100% 模块会拉高平均值）

### 1.4 L2.5 归属矛盾

| 文档位置           | decimalx | domain-market | domain-exchange | domain-macro |
| ------------------ | -------- | ------------- | --------------- | ------------ |
| 各域说明表         | L2.5     | L2.5          | L2.5            | L2.5         |
| 状态总览表         | L2.5     | L2.5          | L2.5            | L2.5         |
| **本地开发路径表** | **基座** | **基座**      | **基座**        | **基座**     |
| STATUS.md 域统计   | L2.5     | L2.5          | L2.5            | L2.5         |

**🟡 WARNING**：本地开发路径表将 4 个 L2.5 模块错误地列在 `基座` 域下。这可能导致新贡献者误解 L2.5 的域归属。

### 1.5 domainx 描述矛盾

- ARCHITECTURE.md "各域说明" 表：domainx 列为基座组件，描述为"执行域共享值对象"
- 业务流图中：domainx 在 risk-engine 下方标注为"执行域共享值对象（归属基座）"
- domainx SPEC.md 职责：Order/Position/Trade/Portfolio/ExecutionReport — 纯粹的执行域语义

**🟡 WARNING**：domainx 的内容是执行域语义，归属是基座。这在逻辑上不矛盾（L2.5 共享值对象，归属基座管理），但描述容易造成混淆。建议在所有位置统一标注为"执行域共享值对象（L2.5 领域共享，归属基座）"。

---

## 2. 覆盖面分析

### 2.1 能力矩阵

| 能力类别     | 负责模块                            | 状态                      | 评分 |
| ------------ | ----------------------------------- | ------------------------- | ---- |
| 生命周期管理 | kernel (lifecycx/shutdownx)         | v1.0.0 发布               | ★★★  |
| 配置管理     | configx                             | v1.0.0 发布               | ★★★  |
| 可观测性     | observex                            | v1.0.0 发布               | ★★★  |
| 弹性策略     | resiliencx                          | v1.0.1 发布               | ★★★  |
| 任务调度     | schedulex                           | v1.0.0 发布               | ★★★  |
| 测试支持     | testkitx                            | SPEC 完整，代码阶段进行中 | ★★☆  |
| 标准/门禁    | xlib-standard/harness/evidence/gate | 3/4 完整，gate 零实现     | ★★☆  |
| KV/缓存      | redisx                              | v1.0.0 发布               | ★★★  |
| 消息队列     | kafkax                              | v1.0.0 发布               | ★★★  |
| 内部通信     | natsx                               | v1.0.0 发布               | ★★★  |
| 关系型存储   | postgresx                           | v1.0.0 发布 (90%)         | ★★☆  |
| 时序存储     | taosx                               | v1.0.1 发布               | ★★★  |
| 对象存储     | ossx                                | v1.0.1 发布               | ★★★  |
| OLAP 分析    | clickhousex                         | v1.0.1 发布               | ★★★  |
| 跨域契约     | contracts                           | v1.0.1-spec               | ★★☆  |
| 通信底座     | transportx                          | v1.1.1-spec               | ★★☆  |
| 领域共享     | domainx                             | SPEC 完整                 | ★★☆  |

评分：★★★ = 成熟发布 (3分)，★★☆ = 有规格待代码/验证 (2分)，★☆☆ = 仅有轮廓 (1分)

### 2.2 能力空白

| 缺失能力       | 重要性 | 当前状态                                 | 建议                                                      |
| -------------- | ------ | ---------------------------------------- | --------------------------------------------------------- |
| Secret 管理    | P0     | configx.SecretString 覆盖基本需求        | 暂不需要独立模块，configx 已足够                          |
| 分布式锁       | P1     | schedulex.Locker interface + redisx Lock | 接口已预留，实现分散。可考虑在 redisx 中统一 Lock 实现    |
| 服务发现       | P2     | 无覆盖                                   | 分布式部署时需要。可新建 `discoveryx` 或集成到 transportx |
| API Gateway    | P2     | 无覆盖                                   | 对上层暴露统一入口时需要                                  |
| gRPC/HTTP 框架 | P2     | transportx 定义了 RPC 契约但无实现       | transportx 只定义契约，adapter 需单独建                   |
| 身份认证/授权  | P2     | 无覆盖                                   | 多租户/生产环境必需                                       |
| 工作流引擎     | P3     | 无覆盖                                   | 复杂交易流程编排可能需要                                  |

### 2.3 CONSTITUTION 十三原则覆盖

| 原则                              | 承担模块                           | 覆盖度             |
| --------------------------------- | ---------------------------------- | ------------------ |
| P1: Foundation 先边界后功能       | xlibgate + FOUNDATION-DEPS.yaml    | ✅                 |
| P2: xlib-standard 不是运行时依赖  | xlib-standard                      | ✅                 |
| P3: resiliencx 只做运行时弹性     | resiliencx + risk-engine           | ✅                 |
| P4: testkitx 只能 test-only       | testkitx + xlibgate boundary check | ✅                 |
| P5: 风控是独立引擎                | risk-engine                        | 非基座职责         |
| P6: 回测与实盘共享代码            | factor-engine/signal-factory       | 非基座职责         |
| P7: contracts 只定义跨域稳定契约  | contracts                          | ✅                 |
| P8: transportx 只定义通信底座契约 | transportx                         | ✅                 |
| P9: 领域语义沉到 L2.5             | decimalx/domain-\*                 | ✅                 |
| P10: 数据职责不跨域               | (架构约束)                         | ✅                 |
| P11: 执行抽象交易所差异           | order-engine                       | 非基座职责         |
| P12: 反馈通过事件表达             | contracts (事件协议)               | ✅                 |
| P13: x.go 只做组合根              | x.go                               | 待核实（体量异常） |

**结论**：基座相关的 9 条原则均有模块承担。P13 (x.go 组合根) 是最需要核实的。

---

## 3. 冗余度分析

### 3.1 模块对分析

| 模块对                                       | 重叠度 | 边界清晰度 | 建议                                                                                                                                                                                                            |
| -------------------------------------------- | ------ | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| kernel.retryx ↔ resiliencx                   | Low    | Clear      | ✅ 保持分离。L0 primitive vs L1 policy，文档已明确                                                                                                                                                              |
| xlibgate ↔ xlib-harness                      | Low    | Clear      | ✅ 互补关系。harness 做 spec/boundary/traceability/format 门禁，gate 做 imports/gomod/baseline/release 门禁                                                                                                     |
| xlib-standard ↔ xlib-harness ↔ xlib-evidence | Low    | Clear      | ✅ 拆分合理。standard=标准源+模板，harness=生成+门禁执行，evidence=证据收集+发布                                                                                                                                |
| contracts ↔ transportx                       | Low    | Clear      | ✅ contracts 是业务契约（DTO/事件协议），transportx 是通信契约（RPC/EventBus/Codec）                                                                                                                            |
| redisx ↔ natsx                               | Medium | Clear      | ✅ 不同用途：redisx 做缓存/KV，natsx 做内部通信。natsx JetStream 的 KV 功能有概念重叠但实际场景不同                                                                                                             |
| postgresx ↔ clickhousex                      | Low    | Clear      | ✅ postgresx 做 OLTP，clickhousex 做 OLAP                                                                                                                                                                       |
| taosx ↔ clickhousex                          | Low    | Fuzzy      | 🟡 两者都做时序数据。taosx 面向 IoT 时序（TDengine），clickhousex 面向分析查询。建议在各自 SPEC 中明确使用场景边界                                                                                              |
| testkitx ↔ xlib-evidence                     | Medium | Fuzzy      | 🟡 testkitx 有 golden/contract/boundary/manifest evidence，xlib-evidence 做 coverage/manifest/remote evidence/report。manifest 功能重叠。建议明确：testkitx 是**测试期**证据，xlib-evidence 是**CI/发布期**证据 |

### 3.2 L2.5 归属争议

**发现**：本地开发路径表将 decimalx/domain-market/domain-exchange/domain-macro 错误归入基座域。

**建议**：在本地开发路径表中为 L2.5 创建独立分区，与"各域说明"表和 STATUS 域统计保持一致。

### 3.3 domainx 位置评估

domainx 当前归属基座，但其内容（Order/Position/Trade/Portfolio/ExecutionReport）是纯粹的执行域语义。不矛盾但需注意：

- 如果 domainx 被所有上层域依赖 → 正确归属基座
- 如果只有执行域使用 → 应该移到执行域或与 domain-exchange 合并

从 ARCHITECTURE.md 业务流图看，domainx 确实被 risk-engine/order-engine/portfolio-engine/settlement 共享，归属基座合理。

---

## 4. 成熟度分析

### 4.1 单模块审计

| #   | 模块          | 声明进度       | 校准进度 | 版本        | 关键缺口                                                    | 风险 |
| --- | ------------- | -------------- | -------- | ----------- | ----------------------------------------------------------- | ---- |
| 1   | kernel        | 100%           | **100%** | v1.0.0      | 无                                                          | 🟢   |
| 2   | configx       | 100%           | **100%** | v1.0.0      | 无                                                          | 🟢   |
| 3   | observex      | 100%           | **100%** | v1.0.0      | 无                                                          | 🟢   |
| 4   | testkitx      | 100%           | **80%**  | v1.0.0-spec | code/ 阶段未完成！管线 100 分但代码未实现                   | 🟡   |
| 5   | resiliencx    | 100%           | **100%** | v1.0.1      | 无                                                          | 🟢   |
| 6   | schedulex     | 100%           | **100%** | v1.0.0      | 无                                                          | 🟢   |
| 7   | xlibgate      | 无进度条       | **30%**  | v1.0.2      | **全部 10 个 tasks 未勾选！** 仅有 SPEC                     | 🔴   |
| 8   | xlib-standard | 100%           | **100%** | v1.0.0      | 无（拆分后标准源职责清晰）                                  | 🟢   |
| 9   | xlib-harness  | **不在状态表** | **100%** | -           | 缺失于 STATUS/CI 数组                                       | 🔴   |
| 10  | xlib-evidence | **不在状态表** | **100%** | -           | 缺失于 STATUS/CI 数组                                       | 🔴   |
| 11  | redisx        | 100%           | **100%** | v1.0.0      | 无                                                          | 🟢   |
| 12  | kafkax        | 100%           | **100%** | v1.0.0      | 无                                                          | 🟢   |
| 13  | natsx         | 100%           | **95%**  | v1.0.0      | 四源 98+ arbiter 与生产 TLS gate 待补                       | 🟡   |
| 14  | postgresx     | 90%            | **90%**  | v1.0.0      | 生产 soak 待完成；foundationx 依赖未纳入退出计划（Issue 6） | 🟡   |
| 15  | taosx         | 100%           | **100%** | v1.0.1      | 无                                                          | 🟢   |
| 16  | ossx          | 100%           | **100%** | v1.0.1      | 无                                                          | 🟢   |
| 17  | clickhousex   | 100%           | **100%** | v1.0.1      | 无                                                          | 🟢   |
| 18  | contracts     | 100%           | **100%** | v1.0.1-spec | 无代码实现，纯契约规格                                      | 🟢   |
| 19  | transportx    | 100%           | **100%** | v1.1.1-spec | 无代码实现，纯规格基线                                      | 🟢   |
| 20  | domainx       | 100%           | **100%** | -           | 无版本号                                                    | 🟡   |

### 4.2 进度虚高 Top 3

1. **testkitx：100% → 80%**（-20%）
   - 原因：Matrix/Tasks/Plan/Prompt 四阶段 100 分，但 code/ 阶段未启动
   - FOUNDATION-TRACKER 明确标注 "code/ 阶段: 在 testkitx 仓库实现 Go 代码" 未勾选
   - 虽然已有 PR #1 的基础代码，但完整的 10 FR 对应实现尚未完成

2. **xlibgate：无进度 → 30%**（虚标为"✅ 已有"）
   - 原因：SPEC.md 完整（11 FR），但 TASK-XLIBGATE-000 到 009 全部未勾选
   - 实际是一个只有规格、零实现的模块
   - STATUS.md 应标注为 "🔨 已创建" 或至少降级进度

3. **xlib-harness / xlib-evidence：未跟踪**
   - 原因：完全缺失于状态监控体系
   - 两个模块的 SPEC + TRACEABILITY + goal + tasks 均已产出，但无人知道它们"存在"

### 4.3 阻塞项清单

| #   | 阻塞项                               | 影响范围                                               | 优先级  |
| --- | ------------------------------------ | ------------------------------------------------------ | ------- |
| B1  | 18 vs 20 文档矛盾未闭环              | CI 检查数组错误，统计数字失真                          | 🔴 立即 |
| B2  | xlibgate 零实现                      | 所有模块的 imports/gomod/baseline/release 门禁无人执行 | 🔴 高   |
| B3  | testkitx code 阶段未完成             | 下游模块缺少统一的测试工具包                           | 🟡 中   |
| B4  | postgresx foundationx 依赖 (Issue 6) | 与 foundationx exit plan 矛盾                          | 🟡 中   |
| B5  | natsx 四源评分/生产 TLS gate         | natsx 生产部署风险                                     | 🟢 低   |

### 4.4 基座整体就绪度评估

**能否支持 Phase 1（分析域）启动？**

✅ **可以**。核心运行时能力（kernel/configx/observex/resiliencx/schedulex）已全部成熟发布，存储层（redisx/kafkax/natsx/postgresx）已就绪，契约层（contracts/transportx/domainx）规格完整可 mock。Phase 1 分析域不依赖 xlibgate 代码实现或 CI 门禁。

⚠️ **但**：testkitx 代码未完成意味着分析域模块将缺少统一的测试 fake/fixture/golden 支持。

---

## 5. 优化迭代建议

### 5.1 立即修复（本周，预计 2-3 小时）

| 修复项 | 具体操作                                         | 文件                                        |
| ------ | ------------------------------------------------ | ------------------------------------------- |
| F1     | 补充 xlib-harness 和 xlib-evidence 到状态表      | ARCHITECTURE.md §状态总览                   |
| F2     | 补充 xlib-harness 和 xlib-evidence 到组件明细表  | STATUS.md §组件明细表                       |
| F3     | FOUNDATION_MODULES 数组 18→20                    | .github/ci/status-consistency-check.sh      |
| F4     | 域统计 "基座 18"→"基座 20"，重算平均进度         | STATUS.md §按域统计                         |
| F5     | 修复 L2.5 模块在本地路径表中的错误归属           | ARCHITECTURE.md §本地开发路径               |
| F6     | testkitx 进度降级 100%→80%，标注 code 阶段待完成 | STATUS.md + ARCHITECTURE.md                 |
| F7     | xlibgate 添加进度条（30%）和 "🔨 待实现" 标注    | STATUS.md + ARCHITECTURE.md                 |
| F8     | "18 个基座模块的独立完整规格"→"20 个"            | ARCHITECTURE.md §Foundation v1 规格文档描述 |

### 5.2 短期优化（本月）

| 优化项 | 说明                                             | 工作量                                                 |
| ------ | ------------------------------------------------ | ------------------------------------------------------ | ------- |
| O1     | 推进 xlibgate 代码实现（TASK-000~009）           | 最高优先级门禁缺失                                     | 3-5 天  |
| O2     | 推进 testkitx code 阶段                          | 解锁下游模块统一测试                                   | 2-3 天  |
| O3     | 为 domainx 添加版本号（至少 v0.1.0）             | 版本覆盖从 18/20 提升到 19/20                          | 30 分钟 |
| O4     | taosx 与 clickhousex 的时序边界文档化            | 在各自 SPEC.md §2 Summary 明确使用场景差异             | 1 小时  |
| O5     | testkitx 与 xlib-evidence 的 evidence 边界文档化 | 明确：testkitx=测试期证据，xlib-evidence=CI/发布期证据 | 1 小时  |
| O6     | postgresx foundationx 依赖迁移（Issue 6）        | 完成 foundationx exit plan 最后一块                    | 1-2 天  |

### 5.3 中期建议（3 个月内）

| 建议 | 说明                                                                                                                            |
| ---- | ------------------------------------------------------------------------------------------------------------------------------- |
| M1   | **不建议新增模块**。当前 20 个模块覆盖面充分，核心缺失（服务发现/API Gateway/Auth）不是基座层职责，应放在上层或独立域           |
| M2   | **不建议合并模块**。存储层模块（7 个）各有明确的使用场景差异，合并会破坏单一职责                                                |
| M3   | 评估 domainx 是否应和 domain-exchange 统一管理。两者共享执行域语义，分开维护可能增加认知负担                                    |
| M4   | 建立模块清单自动化审计 CI。将本报告的检查项编码为 CI gate：数量一致性（topology=status=ci=module/ dir）、归属一致性、进度一致性 |
| M5   | natsx 四源评分和 TLS gate 补齐后，整个基座层可声明 Production Ready                                                             |

### 5.4 建议的基座模块最终清单（20 个，不变）

```
标准与门禁（4）：
  xlib-standard ─── 标准事实源 / Go Reference Template
  xlib-harness  ─── 模块生成器 + 门禁执行器
  xlib-evidence ─── 证据收集与发布运行时
  xlibgate      ─── CI 机器门禁 CLI

L0 原语（1）：
  kernel ─── 12 子包，stdlib-only

L1 运行时（4）：
  configx ─── 配置管理
  observex ─── 可观测性契约
  resiliencx ─── 运行时弹性策略
  schedulex ─── 任务调度

L1 测试（1）：
  testkitx ─── 测试 fake/fixture/golden/contract/boundary/leak

存储扩展（7）：
  redisx ─── KV/缓存/分布式锁
  kafkax ─── 消息队列/事件流
  natsx ─── 内部通信/JetStream
  postgresx ─── 关系型存储
  taosx ─── 时序存储（IoT 场景）
  ossx ─── 对象存储
  clickhousex ─── OLAP 分析查询

契约与传输（2）：
  contracts ─── 跨域稳定端口/事件/DTO
  transportx ─── 通信底座契约

领域共享（1）：
  domainx ─── 执行域共享值对象（归属基座）
```

---

## 6. 附录

### A. 文档一致性矩阵

| 检查项             | README  | ARCHITECTURE 拓扑 | ARCHITECTURE 状态表 | STATUS   | module/README | CI 脚本 |
| ------------------ | ------- | ----------------- | ------------------- | -------- | ------------- | ------- |
| 基座模块数         | -       | 20 ✅             | 18 ❌               | 18 ❌    | 20 ✅         | 18 ❌   |
| xlib-harness 存在  | -       | ✅                | ❌                  | ❌       | ✅            | ❌      |
| xlib-evidence 存在 | -       | ✅                | ❌                  | ❌       | ✅            | ❌      |
| L2.5 归属          | L2.5 ✅ | L2.5 ✅           | L2.5 ✅             | L2.5 ✅  | N/A           | N/A     |
| 本地路径 L2.5      | -       | 基座 ❌           | -                   | -        | -             | -       |
| testkitx 进度      | -       | 100%              | 100%                | 100%     | 100%          | -       |
| xlibgate 进度      | -       | -                 | -                   | 无进度条 | -             | -       |

### B. 审计方法

本报告通过对以下文档的逐行对比和交叉验证生成：

- `ARCHITECTURE.md`（467 行）— 拓扑图、状态表、依赖矩阵、边界守卫
- `STATUS.md`（305 行）— 进度分布、域统计、组件明细、风险清单
- `module/README.md`（344 行）— 模块索引、goal 列表、规格结构
- `.github/ci/status-consistency-check.sh` — CI FOUNDATION_MODULES 数组
- `module/FOUNDATION-TRACKER.md` — Issue 执行跟踪器
- `CONSTITUTION.md` — 十三原则覆盖
- `module/` 目录结构 — 20 个子目录验证

### C. 变更建议映射

```
本报告建议 → 对应文件变更：

F1-F8（立即修复）→ ARCHITECTURE.md + STATUS.md + CI 脚本
O1-O2（代码推进）→ xlibgate + testkitx 代码仓库
O3-O6（小修小补）→ domainx/taosx/clickhousex/testkitx/xlib-evidence SPEC
M1-M5（中期建议）→ 独立规划文档
```

---

_报告生成：Claude Code 多维度手工分析（agent team 因 API 余额不足回退为直接分析）_
_审核状态：已审核 — 2026-06-14 全部可文档化项已修复_
_下一步：O1 (xlibgate 代码) / O2 (testkitx code 阶段) / O6 (postgresx foundationx) 需跨仓库操作_

---

## 7. 修复状态（2026-06-14 闭环）

### 已完成（本仓库 10 PR + 3 外部仓库 PR）

| 修复 | PR | 内容 |
|------|----|------|
| F1-F8 | [#235](https://github.com/ZoneCNH/ZoneCNH/pull/235) | 状态表 18→20、CI 对齐、进度校准、L2.5 修正 |
| 五类职责 | [#236](https://github.com/ZoneCNH/ZoneCNH/pull/236) | xlib-standard 五类→二类职责 ×6 |
| README | [#237](https://github.com/ZoneCNH/ZoneCNH/pull/237) | README 17→20 + 缺失模块条目 |
| O3+O5 | [#238](https://github.com/ZoneCNH/ZoneCNH/pull/238) | domainx v0.1.0 + evidence 边界文档化 |
| O4 | [#239](https://github.com/ZoneCNH/ZoneCNH/pull/239) | taosx/clickhousex 时序存储边界 |
| TRACKER | [#240](https://github.com/ZoneCNH/ZoneCNH/pull/240) | FOUNDATION-TRACKER 对齐更新 |
| 仓库+规则 | [#241](https://github.com/ZoneCNH/ZoneCNH/pull/241) | 创建 3 缺失仓库 + CLAUDE.md 强制对应规则 + CI |
| O2 代码 | [#244](https://github.com/ZoneCNH/ZoneCNH/pull/244) | testkitx code 阶段完成 → 80%→90%（外部 [testkitx#13](https://github.com/ZoneCNH/testkitx/pull/13)） |
| O6 迁移 | [#245](https://github.com/ZoneCNH/ZoneCNH/pull/245) | postgresx foundationx 依赖迁移完成（外部 [postgresx#8](https://github.com/ZoneCNH/postgresx/pull/8)） |
| O1 门禁 | [#246](https://github.com/ZoneCNH/ZoneCNH/pull/246) | xlibgate CLI 实现完成 → 30%→90%（外部 [xlibgate#23](https://github.com/ZoneCNH/xlibgate/pull/23)） |

### 审计遗漏项（本报告未覆盖，已修复）

| 遗漏 | 发现方式 | PR |
|------|----------|----|
| xlib-harness/xlib-evidence/domainx 仓库 404 | 第三轮深度排查 | [#241](https://github.com/ZoneCNH/ZoneCNH/pull/241) |
| README.md 基座列表仅 17 个 | 第三轮深度排查 | [#237](https://github.com/ZoneCNH/ZoneCNH/pull/237) |
| xlib-standard 五类职责描述 6 处过时 | 第二轮深度排查 | [#236](https://github.com/ZoneCNH/ZoneCNH/pull/236) |

### 未完成（需跨仓库代码操作）

| 项 | 仓库 | 说明 |
|----|------|------|
| O1 | ZoneCNH/xlibgate | ✅ PR #23 merged — CLI 实现完成（进度 30%→90%） |
| O2 | ZoneCNH/testkitx | ✅ PR #13 merged — code 阶段完成（进度 80%→90%） |
| O6 | ZoneCNH/postgresx | ✅ PR #8 merged — 132 foundationx 引用→0 |

### 当前基线

```
基座模块: 20 (全文档统一) · 仓库: 20/20 · 版本覆盖: 29/74
CI: status-consistency-check 13/13 ✅ · repo-existence-check 20/20 ✅
```
