# ADR-001: alertx 架构基线与三大 Open Question 决策

> 状态：Accepted
> 日期：2026-06-26
> 决策者：ZoneCNH
> 关联：`module/alertx/SPEC.md`、`module/observex/ADR-dual-attribution.md`、`CONSTITUTION.md` §2/§3/§10

---

## 背景

`alertx` 于 2026-06-10 注册（`module/registry.yaml:892`），`lifecycle: proposed`，`arch_type: independent_process`，`domain: crosscut`，`layer: business`。初始 SPEC 为占位草稿（commit `97ba6dd4`），遗留三个 Blocking Open Question 阻止进入 Spec→Code 管线：

1. **订阅模式未定** — alertx 应订阅 observex 导出流、直接订阅业务事件、还是两者？
2. **规则定义方式未定** — 配置文件 DSL、代码规则、还是矩阵？
3. **进入管线的优先级与首版版本号未定**。

同时存在一个架构张力（架构深度分析标记为 P1 风险）：`observex` 曾因「基座 + 横切」双重归属触发 R7 风险，事后用 `ADR-dual-attribution.md` 闭环。alertx 作为横切层唯一告警组件，若不在进入管线前钉死层级归属，有重演 R7 的风险。

本 ADR 在 alertx 进入 Spec→Code 管线前闭合上述全部 Blocking 项，并钉死层级归属，为后续 23 节 SPEC 与代码实现提供不可变基线。

---

## 决策

### D1. 层级归属：横切消费者（layer: business / domain: crosscut）

alertx 的逻辑层级为**业务层消费者**，横切（crosscut）是其**域归属**而非基座层级。三层界定：

| 维度 | alertx 角色 | 说明 |
| --- | --- | --- |
| **域归属** | crosscut（横切） | 与 observex 同列横切域，但告警语义独立 |
| **层级归属** | business（业务层） | alertx 是 observex 的下游消费者，依赖 L1 基座（kernel/observex/contracts），自身不属基座 |
| **物理部署** | independent_process（独立进程） | `github.com/ZoneCNH/alertx`，独立 go.mod，通过 cmd/alertx 入口运行 |

**与 observex 的关键区别**：observex 是 L1 基座（被所有层消费的运行时能力），alertx 是业务层横切消费者（单向下游依赖 observex + contracts，不向上游暴露能力）。alertx **不在** FOUNDATION-DEPS.yaml 的 `layer_dependencies` 基座登记中，而在业务域依赖矩阵登记。

### D2. 订阅模式：双订阅

alertx 采用**双订阅**架构：

1. **订阅 observex 导出流** — 通过实现 observex 的 `Exporter` 接口（`ExportLogs`/`ExportMetrics`/`ExportSpans`）消费 LogEntry/MetricPoint/SpanData/HealthStatus，用于**系统健康类**与**指标阈值类**告警。
2. **订阅业务域状态事件** — 通过 contracts 定义的 `Event` envelope（`AlertEvent` payload）订阅业务域状态变更（如 riskx 风控触发、strategyx 策略异常），用于**策略/风控类**告警。

理由：三类告警（ROADMAP v0.5.0：策略异常 + 风控触发 + 系统健康）的信号源不同——系统健康来自 observex 指标，策略/风控来自业务事件。单订阅任一方都会丢失另一类告警来源。

### D3. 规则定义：YAML DSL

告警规则用 **YAML DSL** 定义（对齐 observex §10 配置范式），非代码内嵌规则、非矩阵。规则文件经启动时校验（DSL schema + 语义校验），校验失败阻断进程启动（BR 级约束）。支持运行时热加载（FR-007）。

DSL 选型理由：YAML 可由运维/非开发人员维护、可版本控制、可被 linter 校验；代码规则需重编译违反热加载目标；矩阵表达力不足以描述条件逻辑。

### D4. 首版版本：v1.0.0

alertx 首次发布目标 **runtime tag v1.0.0**（非渐进 v0.x）。依据宪法 §10.4.1，Spec-Version（v1.0.0）与 Runtime-Version（v1.0.0）双轴独立声明但首版对齐。理由：用户明确要求「完整生产级」，MVP 缩范围不符合目标；observex 的 v0.3.x 渐进是其作为基座库的演化路径，alertx 作为独立进程首版即承诺稳定接口。

---

## 替代方案

### 方案 A：单订阅 observex（被否决）

仅订阅 observex 导出流，业务域告警由 observex 中转。

- 优点：订阅逻辑单一，实现简单。
- 缺点：业务域的「风控触发」「策略异常」语义在 observex 层不存在（observex 只采集不做语义），中转会导致告警语义丢失 + 反向耦合 observex 理解业务。
- 未选择原因：违反 observex 边界（SPEC §4 非目标「不做告警升级」），且无法表达 ROADMAP 三类告警中的策略/风控类。

### 方案 B：代码内嵌规则（被否决）

规则用 Go 代码实现（如 `rule.StrategyBreach{Threshold: ...}`）。

- 优点：类型安全、IDE 支持、无解析风险。
- 缺点：规则变更需重编译重启，违反 FR-007 热加载目标；运维无法直接维护规则。
- 未选择原因：热加载是生产级告警引擎的核心诉求（规则迭代频繁）。

### 方案 C：纯横切基座归属（被否决）

将 alertx 归为 L1 基座（类似 observex）。

- 优点：与 observex 层级并列，视觉对称。
- 缺点：alertx 依赖 observex（单向下游），若同属基座会形成基座内部依赖，破坏基座「依赖 kernel 原语」的最小约束；且 alertx 消费业务语义，不满足基座「vendor-neutral 运行时能力」定义。
- 未选择原因：违反 §3 依赖方向（基座不得依赖业务层语义），重演 observex R7 的归属混淆。

---

## 后果

### 正面影响

- 闭合 SPEC §22 全部 Blocking Open Question，解除进入 Spec→Code 管线阻塞。
- 钉死层级归属，消除 P1 风险（避免重演 observex R7）。
- 双订阅 + YAML DSL + 热加载构成生产级告警引擎的标准形态。
- 明确 alertx 在横切层的独占 owner 地位（observex ADR-dual-attribution 已预留）。

### 负面影响

- 双订阅增加实现复杂度（两套订阅 + 事件归一化层）。
- YAML DSL 需配套 schema 校验工具，增加 CI gate 项。
- v1.0.0 首版承诺稳定接口，后续 Breaking Change 须走 §10.2 迁移流程，灵活性低于 v0.x 渐进。

### 风险与缓解

| 风险 | 概率 | 影响 | 缓解措施 |
| --- | --- | --- | --- |
| contracts 缺 AlertEvent 类型，双订阅的业务侧无契约 | 高 | 高 | S1 阶段先在 contracts v1.5.0 新增 alert 契约，作为 alertx 依赖前置 |
| YAML DSL 设计反复导致 SPEC §7/§9 返工 | 中 | 中 | 本 ADR 钉死 DSL 形态，SPEC §7 按此展开，降低返工面 |
| observex Exporter 接口未来变更冲击 alertx 订阅层 | 低 | 高 | SPEC §15 锁定 observex v0.3.1+ 版本范围，§21 升级兼容性章节声明 |
| 双订阅事件归一化层成为性能瓶颈 | 低 | 中 | §17 性能预算设定规则评估 <1ms/条，Benchmark 守护 |

---

## 实施计划

| 里程碑 | 目标 | 验收 |
| --- | --- | --- |
| S0（本 ADR） | 钉死架构基线 | ADR Accepted + STATUS 覆盖率列修正 |
| S1 | contracts v1.5.0 新增 alert 契约 | contracts 仓 PR 合入 + tag v1.5.0 |
| S2 | alertx SPEC 23 节展开 | SPEC-lint 23 节序 + AC 必填 |
| S3-S8 | Spec→Code 管线全阶段 gate pass | composite_score ≥98 + Release v1.0.0 |
| S9 | 毕业 proposed → active | registry lifecycle=active + GitHub Release |

---

## 约束

- alertx 不得向上游暴露能力（单向下游依赖 observex + contracts + 基座）。
- 规则 DSL 必须 schema 校验，校验失败阻断启动（不可降级为 warn）。
- 三类告警（策略异常 / 风控触发 / 系统健康）必须全部支持（ROADMAP v0.5.0 锚点）。
- Spec-Version 与 Runtime-Version 双轴独立（宪法 §10.4.1），禁止互相推导。

---

## 参考

- [CONSTITUTION.md §2](../../CONSTITUTION.md) — 模块边界（拥有/不拥有声明）
- [CONSTITUTION.md §3](../../CONSTITUTION.md) — 依赖方向（单向下行）
- [CONSTITUTION.md §10.4.1](../../docs/constitution/10-change-management.md) — Spec-Version / Runtime-Version 双轴
- [module/observex/ADR-dual-attribution.md](../observex/ADR-dual-attribution.md) — observex 双重归属先例（R7 闭环）
- [module/registry.yaml:892-904](../registry.yaml) — alertx 注册条目
- [ROADMAP.md:213](../../ROADMAP.md) — v0.5.0 三类告警锚点
- [docs/goal/rsi-standard/23-monitoring-incident-response.md](../../docs/goal/rsi-standard/23-monitoring-incident-response.md) — I0-I5 事件分级标准（severity 映射源）

---

## 后续

- S1：在 contracts v1.5.0 定义 AlertEvent / AlertRule / Severity / AlertSink（本 ADR D2 双订阅的业务侧契约面）。
- S2：SPEC §7 FR 按三类告警 + 五大能力（规则/去重/分级/通知/生命周期）展开。
- S2：SPEC §9 接口契约定义 RuleEvaluator / Deduper / Notifier / AlertStore / RuleStore 窄接口。
