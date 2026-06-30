# signal_factory 规格

- Status: Approved
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-30
- Layer: 决策域 · 信号生成
- Version: v0.1.0-draft
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/contracts`, `module/regime_engine`, `module/factor_eval`, `module/feature_store`, `module/riskx`, `module/orderx`, `module/backtestx`

> 公开投影 caveat：Status=Approved 与文档大纲到位不等同于 factory-grade；运行时实现以 GitHub 仓库 `signal_factory` 为准（当前 v0.1.0 骨架，5 tests PASS）。本 SPEC 补全自 2026-06-22 PR S-3 修复（原 82 行存根 → 23 节完整框架）。

---

## 1. 摘要

`signal_factory` 是决策域的**信号生成与组合**模块。它消费 `regime_engine` 输出的 `DecisionCard`（含 action / risk / permission）与 `factor_eval` 提供的因子评估结果，按 regime 门控规则与因子权重策略，产出标准化的 `SignalIntent[]`，作为 `riskx` 风控判断的输入。它是分析域到执行域的**关键决策节点**——这里是策略意图首次具体化为可路由订单的边界。

---

## 2. 问题与背景

量化交易系统中信号生成层面临的挑战：

- **多因子组合**：单一因子 IC 不稳定，需多因子加权组合，但权重策略（等权 / IC 加权 / regime 加权）需可配置
- **Regime 联动**：不同市场体制下因子有效性差异显著，需 `DecisionCard.permission` 强门控
- **DTO 漂移**：策略层直接生成订单意图易绕过风控，需统一 `SignalIntent` 契约
- **时序一致**：信号生成时机必须严格对齐 factor 评估周期与 regime 切换时点
- **冲突仲裁**：多因子方向冲突时需明确组合规则（净 long/short、强度归一）

---

## 3. 目标

- **统一信号 DTO**：消费 `contracts.SignalIntent`（v1.5.0 P1 DTO），不自创等效结构
- **Regime 门控**：`DecisionCard.permission = DENY` 时强制 Direction=FLAT，Confidence=0
- **因子组合**：支持等权 / IC 加权 / regime 加权三种权重策略，权重归一化
- **置信度计算**：基于 IC 稳定性、因子一致性、regime permission 推导 [0, 1] float
- **可回测**：实盘与回测共享同一份生成代码（P6 原则）
- **冲突门**：净方向冲突时按总权重决定净方向，FLAT 优先于 LONG/SHORT

---

## 4. 非目标

- 不做因子计算（→ `factor_engine`）
- 不做因子评估（→ `factor_eval`，IC/IR 计算）
- 不做风控判断（→ `riskx`）
- 不做订单执行（→ `orderx`）
- 不做策略参数管理（→ `strategyx`）
- 不做交易所适配（→ `orderx` adapter 层）
- 不做仓位计算（→ `positionx`）

---

## 5. 消费者

| 消费者       | 使用方式 |
| ------------ | -------- |
| `maestro`    | 编排 workflow 中调用 Generate，传入 DecisionCard 与 instrument 列表 |
| `riskx`      | 接收 `SignalIntent[]` 作为 CheckOrder 的上游输入 |
| `backtestx`  | 回测场景中重放历史 DecisionCard + factor_eval 结果生成历史信号 |
| `strategyx`  | 策略层接收 SignalIntent 回执用于参数调整 |
| `observex`   | 消费 signal_emit / regime_gate_block 事件用于监控 |

---

## 6. 功能需求

### FR-001: Signal 生成

WHEN `factor_eval` 输出 `FactorEvalResult[]`（含 IC、分层收益、信号方向） AND `regime_engine` 输出 `DecisionCard`（action / risk_tier / permission）
THEN 对每个 `InstrumentKey` 生成 `SignalIntent{InstrumentKey, Direction, Strength, Confidence, FactorAttribution, RegimeDecision, GeneratedAt, ExpiresAt}`
AND Direction ∈ {LONG, SHORT, FLAT}
AND Strength ∈ [0, 1.0]（按 position_caps 归一化）
AND Confidence ∈ [0, 1.0]（IC 稳定性加权）

### FR-002: 因子组合

WHEN 多因子对同一 instrument 产生信号
THEN 按配置的权重策略组合：
- `equal_weight`：权重等于 1/N
- `ic_weighted`：权重 ∝ |IC| / Σ|IC|
- `regime_weighted`：权重 ∝ IC × regime_factor（不同 regime 下因子有效性系数）
AND 权重总和 ≤ 1.0（归一化）
AND 净 Direction 由加权 Strength 决定（正→LONG，负→SHORT，∣净∣<阈值→FLAT）

### FR-003: Regime Gate

WHEN `DecisionCard.permission = DENY`
THEN 对应 instrument 的 SignalIntent.Direction 强制为 FLAT
AND Strength = 0，Confidence = 0
AND emit `regime_gate_block` 事件（含 instrument / regime_action / blocked_at）

### FR-004: 冲突门

WHEN 多因子方向冲突（部分 LONG 部分 SHORT）
THEN 计算净加权 Strength：
- `|净 Strength| < conflict_threshold` → Direction = FLAT
- `净 Strength > 0` → Direction = LONG，Strength = |净|
- `净 Strength < 0` → Direction = SHORT，Strength = |净|
AND emit `signal_conflict_resolved` 事件（含 instrument / 净 Strength / 冲突因子数）

### FR-005: 置信度计算

WHEN 生成 SignalIntent
THEN Confidence = w1 × ic_stability + w2 × factor_consistency + w3 × regime_alignment
AND w1+w2+w3 = 1.0（默认 0.4/0.3/0.3）
AND Confidence < min_confidence_threshold（默认 0.3）时 Direction = FLAT

### FR-006: 信号过期

WHEN 生成 SignalIntent
THEN ExpiresAt = GeneratedAt + ttl（按 instrument 频率决定，默认 5min）
AND 消费方（riskx / orderx）必须检查 ExpiresAt > now()

### FR-007: 信号追溯

WHEN 生成 SignalIntent
THEN FactorAttribution 必须列出参与计算的因子 ID + 权重 + IC 值
AND RegimeDecision 必须引用 DecisionCard.ID 与 regime_state
AND 用于事后归因分析

### FR-008: Module Identity

- README H1 必须为 `# signal_factory`
- go.mod 必须为 `github.com/ZoneCNH/signal_factory`
- 不得残留 xlib_standard / 其他模块 identity

---

## 7. 接口契约

```go
// 消费 contracts v1.5.0 P1 DTO，不自定义等效结构
import "github.com/ZoneCNH/contracts/pkg/contracts"

type SignalFactory interface {
    // Generate 是主入口：DecisionCard + factor_eval 结果 → SignalIntent[]
    Generate(
        ctx context.Context,
        card contracts.DecisionCard,
        evalResults []contracts.FactorEvalResult,
        instruments []contracts.InstrumentKey,
    ) ([]contracts.SignalIntent, error)

    // Combine 用于组合多个 SignalIntent 为单一（同 instrument）
    Combine(
        signals []contracts.SignalIntent,
        strategy WeightStrategy,
    ) (contracts.SignalIntent, error)
}

type WeightStrategy string

const (
    EqualWeight       WeightStrategy = "equal_weight"
    ICWeighted        WeightStrategy = "ic_weighted"
    RegimeWeighted    WeightStrategy = "regime_weighted"
)

// 配置结构
type Config struct {
    DefaultStrategy        WeightStrategy
    ConflictThreshold      float64        // |净 Strength| 低于此值 → FLAT
    MinConfidenceThreshold float64        // Confidence 低于此值 → FLAT
    SignalTTL              time.Duration  // SignalIntent 默认过期时间
    RegimeFactorMap        map[string]float64  // regime_state → 因子有效性系数
}
```

---

## 8. 行为约束

| ID     | 规则 |
| ------ | --- |
| BR-001 | Regime DENY 必须覆盖所有因子信号为 FLAT（强门控，无例外） |
| BR-002 | 信号权重总和必须 ≤ 1.0（归一化后） |
| BR-003 | Confidence < min_confidence_threshold 时 Direction 强制 FLAT |
| BR-004 | ExpiresAt > GeneratedAt 必须严格成立 |
| BR-005 | FactorAttribution 不得为空（必须列出至少 1 个因子来源） |
| BR-006 | SignalIntent 一旦生成不得修改（不可变 DTO，重生成创建新对象） |
| BR-007 | 冲突门优先级 > 因子组合（即先解决冲突再归一化权重） |

---

## 9. 错误处理

| 错误码 | 触发条件 | 处理 |
| --- | --- | --- |
| `ERR_DECISION_CARD_INVALID` | DecisionCard 为空或字段缺失 | 拒绝生成，返回 error |
| `ERR_FACTOR_EVAL_EMPTY` | factor_eval 结果为空 | 返回空 SignalIntent[]（合法） |
| `ERR_INSTRUMENT_NOT_FOUND` | instruments 中含 regime_engine 未覆盖的 instrument | 跳过该 instrument，emit warning |
| `ERR_WEIGHT_STRATEGY_UNKNOWN` | 配置的 strategy 未注册 | fallback 到 EqualWeight，emit warning |
| `ERR_REGIME_GATE_BLOCKED` | permission=DENY | 不算错误，按 FR-003 处理 |

错误不应中断整个 batch；单 instrument 失败不影响其他 instrument 的信号生成。

---

## 10. 边界场景

- **无 factor_eval 结果**：返回空 `[]SignalIntent`，不抛错（信号系统正常路径）
- **DecisionCard.permission=DENY 但 factor_eval 强信号**：FR-003 强门控覆盖
- **多因子全部 FLAT**：净 Strength=0，FLAT 信号必须仍发出（用于平仓决策）
- **regime 切换时刻**：以 DecisionCard.GeneratedAt 为准，不混用旧 regime + 新 factor
- **NaN/Inf 因子 IC**：跳过该因子，emit warning
- **时钟回退**：以 GeneratedAt 为单调来源，不依赖系统时钟比较

---

## 11. 验收标准

| AC ID | 验收条件 |
| --- | --- |
| AC-001 | 正常路径：DecisionCard + 3 因子 → 单 instrument 加权 SignalIntent，Direction 与净加权一致 |
| AC-002 | Regime DENY → 所有 instrument FLAT + Strength=0 + Confidence=0 |
| AC-003 | 冲突门：2 LONG + 1 SHORT 净 Strength<阈值 → FLAT |
| AC-004 | 置信度低于阈值 → FLAT（即使因子方向一致） |
| AC-005 | SignalIntent 携带完整 FactorAttribution（≥1 因子 ID + 权重 + IC） |
| AC-006 | ExpiresAt = GeneratedAt + ttl 严格成立 |
| AC-007 | Module Identity：README H1 + go.mod 与模块名一致 |

---

## 12. 测试矩阵

| TC ID | 测试 | 覆盖 FR/AC |
| --- | --- | --- |
| TC-SIG-001 | 单因子单 instrument 正常路径 | FR-001, AC-001 |
| TC-SIG-002 | 多因子等权组合 | FR-002 |
| TC-SIG-003 | IC 加权组合 + 归一化 | FR-002, BR-002 |
| TC-SIG-004 | regime DENY 全 FLAT | FR-003, AC-002 |
| TC-SIG-005 | 冲突门 LONG/SHORT 净抵消 | FR-004, AC-003 |
| TC-SIG-006 | 低置信度强制 FLAT | FR-005, AC-004 |
| TC-SIG-007 | 信号过期时间生成 | FR-006, AC-006 |
| TC-SIG-008 | FactorAttribution 完整性 | FR-007, AC-005 |
| TC-SIG-009 | Module Identity 校验 | FR-008, AC-007 |
| TC-SIG-010 | factor_eval 空结果合法返回 | ERR_FACTOR_EVAL_EMPTY |
| TC-SIG-011 | NaN/Inf 因子跳过 | 边界场景 |

---

## 13. 目录结构

```text
signal_factory/
├── cmd/
│   └── signal_factory/
│       └── main.go              # 独立进程入口（bootstrap.Build）
├── internal/
│   ├── generator/               # FR-001 信号生成核心
│   ├── combiner/                # FR-002 因子组合
│   ├── regime_gate/             # FR-003 regime 门控
│   ├── conflict_resolver/       # FR-004 冲突门
│   ├── confidence/              # FR-005 置信度计算
│   └── attribution/             # FR-007 信号追溯
├── pkg/
│   └── signalfactoryx/          # 公开 adapter 包（供 composer 注册）
├── go.mod                       # github.com/ZoneCNH/signal_factory
└── README.md                    # H1 = signal_factory
```

独立进程（非 C/S），bootstrap.Build 接入，无 client/server 拆分。

---

## 14. CI Gate

| Gate | 内容 | 工具 |
| --- | --- | --- |
| build | `go build ./...` | go toolchain |
| test | `go test -race -coverprofile ./...`，覆盖率 ≥ 80% | go test |
| boundary | 禁止 import production-only 包到 test path | `xlibgate boundary-check` |
| traceability | TRACEABILITY.md 中 FR↔TC 映射完整 | `xlib_harness traceability-gate` |
| module-identity | README H1 + go.mod 校验 | `xlib_harness spec-lint` |
| contract | 消费 contracts.SignalIntent 不自创等效 DTO | import scan |

---

## 15. 性能预算

| 指标 | 目标 | 验证 |
| --- | --- | --- |
| Generate 单 instrument | P99 < 5ms | benchmark `BenchmarkGenerateSingle` |
| Generate 100 instruments | P99 < 200ms | benchmark `BenchmarkGenerateBatch100` |
| Combine 10 信号 | P99 < 1ms | benchmark `BenchmarkCombine10` |
| 内存：单次 Generate 1k instruments | < 16MB | runtime/pprof |

---

## 16. 可观测输出

| 类型 | 名称 | 内容 |
| --- | --- | --- |
| metric | `signal_factory_generate_total` | counter，按 direction 标签 |
| metric | `signal_factory_generate_duration_ms` | histogram，P50/P95/P99 |
| metric | `signal_factory_regime_block_total` | counter，regime DENY 触发次数 |
| metric | `signal_factory_conflict_resolved_total` | counter，冲突门触发次数 |
| event  | `signal_emit` | 每生成 SignalIntent 发出（含 instrument/direction/confidence） |
| event  | `regime_gate_block` | regime DENY 时发出 |
| event  | `signal_conflict_resolved` | 冲突门触发时发出 |
| trace  | `signal_factory.Generate` | span，含 instrument 数与策略类型 |
| log    | error/warn 级 | DecisionCard 缺失、因子异常 |

---

## 17. 发布 DoD

- [ ] FR-001 ~ FR-008 全部实现并测试通过
- [ ] AC-001 ~ AC-007 全部验收通过
- [ ] TC-SIG-001 ~ TC-SIG-011 全部 PASS
- [ ] 覆盖率 ≥ 80%
- [ ] benchmark 满足性能预算
- [ ] Module Identity 校验通过（README H1 + go.mod）
- [ ] 消费 contracts.SignalIntent 不自创 DTO
- [ ] CI 全部 gate 通过（build/test/boundary/traceability/contract）
- [ ] GitHub Release 发布

---

## 18. 反需求

- ❌ 不做因子计算（→ factor_engine）
- ❌ 不做因子评估（→ factor_eval）
- ❌ 不做风控判断（→ riskx）
- ❌ 不做订单执行（→ orderx）
- ❌ 不做策略参数管理（→ strategyx）
- ❌ 不做交易所适配
- ❌ 不在 SignalIntent 中嵌入订单参数（如 price/qty 计算 → riskx 负责）

---

## 19. 依赖

| 依赖 | 用途 | 版本 |
| --- | --- | --- |
| `contracts` | SignalIntent / DecisionCard / FactorEvalResult / InstrumentKey | v1.5.0+ |
| `regime_engine` | DecisionCard 来源（运行时通过 ports） | v1.0.0+ |
| `factor_eval` | FactorEvalResult 来源（运行时通过 ports） | v0.1.0+ |
| `domain_market` | InstrumentKey 类型 | v1.1.0+ |
| `kernel` | lifecycx / errx / obsx | v1.0.0+ |
| `configx` | 配置加载 | v1.1.0+ |
| `observex` | metrics / events | v0.3.4+ |
| `bootstrap` | 进程组装 | v0.2.0+ |

---

## 20. 兼容性

| 变更类型 | 版本升级 |
| --- | --- |
| 新增 WeightStrategy 类型 | minor |
| 新增 FR / AC / TC | minor |
| SignalFactory 接口变更 | major |
| 修改默认阈值（conflict_threshold / min_confidence_threshold） | minor |
| 升级 contracts 版本（DTO 不兼容） | major |

---

## 21. 待解决问题

- 多周期信号合成（intraday + EOD）的时序对齐策略？
- 跨账户信号是否共享 attribution？
- regime 切换瞬间的信号是否应延迟一个周期？
- 因子相关性高时是否需要去相关处理？

---

## 22. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-17 | v0.1.0-draft | 初始基线（FR-001~004，82 行存根） | ZoneCNH |
| 2026-06-22 | v1.0.0 | S-3 修复：补全 23 节完整结构（FR-005~008、AC/TC 矩阵、性能预算、可观测、DoD） | Claude + ZoneCNH |

---

## 23. 参考

- `module/contracts/SPEC.md` §2 — `SignalIntent` 与 `SignalFactoryProvider` 契约定义
- `module/regime_engine/SPEC.md` — DecisionCard 输出契约
- `module/factor_eval/SPEC.md` — FactorEvalResult 契约
- `module/riskx/SPEC.md` — 下游消费链路
- `CONSTITUTION.md` §1 P5 — 风控是独立引擎，策略只能通过 riskx 提交订单
- `ARCHITECTURE.md` §核心设计原则 — 回测与实盘共享代码（P6）
