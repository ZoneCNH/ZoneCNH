# domain-macro 规格

- Status: Approved
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-15
- Layer: L2.5 领域共享
- Version: v1.0.1
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`, `decimalx`

> 公开投影 caveat：Status=Approved 与 100.0% 覆盖证据不等同于 factory-grade；机器事实层保持 factory=false。

---

## 1. 摘要

`domain-macro` 定义宏观数据点、宏观状态、宏观信息集、修订版本和 no-lookahead 可见性规则。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | MacroPoint、MacroInformationSet、MacroState、MacroRegimeCard、revision/as-of/freshness 语义 |
| Depends on | `kernel`、`decimalx` 或精度 ADR 指定的数值边界 |
| Excludes | provider API client、forecasting、factor/allocation、external API DTO |
| Boundary with storage/provider | provider DTO 必须在 adapter/internal 层完成转换，公共领域模型只暴露宏观语义 |

## 3. 功能需求

| ID | 需求 |
| --- | --- |
| FR-MAC-001 | MacroPoint 必须表达 observed/released/available 三类时间。 |
| FR-MAC-002 | MacroPoint 必须记录 revision version、preliminary flag 和 source。 |
| FR-MAC-003 | `IsVisibleAt(decisionTime)` 必须 fail-closed，available time 缺失或晚于 decision time 时不可见。 |
| FR-MAC-004 | MacroInformationSet.AsOf 必须只返回 decision time 可见数据，并保持 copy-on-write。 |
| FR-MAC-005 | RevisionVersion 必须非负并可用于 deterministic revision ordering。 |
| FR-MAC-006 | MacroState / MacroRegimeCard 必须有稳定枚举和 validate 规则。 |
| FR-MAC-007 | 公共数值精度必须通过 ADR 冻结，推荐采用 `decimalx.Decimal`。 |

## 4. 非功能需求

- 回测安全：任何不可见数据默认拒绝，禁止 look-ahead。
- 可审计：来源、修订、初值/终值和 freshness 指标可追溯。
- 领域纯净：公共模型不包含 provider DTO 或 transport schema。

## 5. 非目标与发布门禁

- 不实现 provider API client（Yahoo/FRED API 调用由数据采集层负责）
- 不实现经济预测或情景推演（由策略域和因子引擎负责）
- 不实现因子计算或资产配置逻辑（由因子引擎和策略域负责）
- 不在公共 API 暴露 provider DTO（yahoo_models 等须迁入 internal 或 infra 层）
- 不依赖 transport 层（HTTP、gRPC、Kafka）或存储层（Redis、Postgres、TDengine）
- 不实现策略或风控逻辑（由策略域和风控域负责）

### 发布门禁

| 门禁 | 要求 |
| --- | --- |
| No-lookahead | AsOf/IsVisibleAt fail-closed 测试覆盖。 |
| 精度 ADR | 明确 Decimal 迁移或 float64 兼容退出路线。 |
| DTO 边界 | `yahoo_models` 等 provider DTO 不在公共领域 API 泄漏。 |
| 修订门禁 | revision ordering 与 preliminary/confirmed 数据测试通过。 |

## 6. 消费者

- 策略/回测引擎：通过 MacroInformationSet.AsOf 获取可见宏观信息
- 因子引擎：基于 MacroPoint 和 MacroState 生成宏观因子
- 风控模块：使用 MacroState 判断经济周期
- 数据采集层（provider）：构造 MacroPoint 并设置 AvailableAt
- 研究平台：查询宏观修订历史与 freshness

## 7. 功能需求

| ID | 需求 | WHEN | THEN |
|----|------|------|------|
| FR-MAC-001 | macropoint-time | 构造 MacroPoint | ObservedAt/ReleasedAt/AvailableAt 三类时间语义固定；AvailableAt 缺失时 Validate 失败 |
| FR-MAC-002 | macropoint-revision | 同一 SeriesCode+ObservedAt 存在多个 revision | RevisionVersion >= 0 且用于 deterministic ordering；preliminary/final 标识可追溯 |
| FR-MAC-003 | visibility | 调用 IsVisibleAt(decisionTime) | ObservedAt/ReleasedAt/AvailableAt 任一晚于 decisionTime 则不可见；AvailableAt 缺失时不可见 |
| FR-MAC-004 | information-set | 构造 MacroInformationSet | Points 只含 IsVisibleAt(DecisionTime) 为 true 的数据；copy-on-write 防止外部修改 |
| FR-MAC-005 | revision-selection | 同一 SeriesCode+ObservedAt 有多版本可见 | 选择最高 RevisionVersion；preliminary 不得覆盖 final 除非 revision 更高且可见 |
| FR-MAC-006 | macrostate | 构造 MacroState | 枚举 recovery/expansion/slowdown/contraction 稳定；IsValid() 可校验 |
| FR-MAC-007 | precision | 宏观值精度决策 | 推荐采用 decimalx.Decimal；若保留 float64 须标为派生/convenience 并保留 decimal 原始值 |
| FR-MAC-008 | provider-dto | provider DTO 边界 | yahoo_models 等 DTO 须迁入 internal 或 infra；公共 API 仅暴露中立模型 |

## 8. 行为约束

| ID | 规则 |
|----|------|
| BR-MAC-001 | IsVisibleAt 必须 fail-closed：缺失 AvailableAt 的点不可见 |
| BR-MAC-002 | FilterMacroPointsForBacktest 必须拒绝缺失 AvailableAt 的点，避免前视偏差 |
| BR-MAC-003 | MacroInformationSet 构造器 copy-on-write：getter 返回 slice 副本 |
| BR-MAC-004 | 同一 DecisionTime + 同一输入数据 → MacroInformationSet 输出 deterministic |
| BR-MAC-005 | DataFreshnessSec 规则：无可见点时返回 -1 或特殊值；未来数据拒绝 |
| BR-MAC-006 | provider DTO 不得污染 domain Public API |


### Acceptance Criteria Registry

| AC ID | FR/BR Ref | Criterion |
|-------|-----------|----------|
| AC-MAC-001 | FR-MAC-001 | TC-MAC-001 | - | 🔲 | |
| AC-MAC-002 | FR-MAC-002 | TC-MAC-003 | - | 🔲 | |
| AC-MAC-003 | FR-MAC-003 | TC-MAC-001, TC-MAC-002, TC-MAC-005 | - | 🔲 | |
| AC-MAC-004 | FR-MAC-004 | TC-MAC-004, TC-MAC-006 | - | 🔲 | |
| AC-MAC-005 | FR-MAC-005 | TC-MAC-003, TC-MAC-005 | - | 🔲 | |
| AC-MAC-006 | FR-MAC-006 | TC-MAC-003 | - | 🔲 | |
| AC-MAC-007 | FR-MAC-007 | - | - | 🔲 | |
| AC-MAC-008 | FR-MAC-008 | TC-MAC-007 | - | 🔲 | |

## 9. 接口契约

```go
type MacroPoint struct {
    SeriesCode      string
    Value           decimalx.Decimal  // 或按 ADR 决策
    ObservedAt      time.Time
    ReleasedAt      time.Time
    AvailableAt     time.Time
    RevisionVersion int
    IsPreliminary   bool
    Source          string
}

func (p MacroPoint) Validate() error
func (p MacroPoint) IsVisibleAt(decisionTime time.Time) bool

type MacroInformationSet struct {
    DecisionTime     time.Time
    Points           []MacroPoint
    DataFreshnessSec float64
}

func FilterMacroPointsForBacktest(points []MacroPoint, decisionTime time.Time) MacroInformationSet

type MacroState string

const (
    MacroRecovery   MacroState = "recovery"
    MacroExpansion  MacroState = "expansion"
    MacroSlowdown   MacroState = "slowdown"
    MacroContraction MacroState = "contraction"
)

func (s MacroState) IsValid() bool

type MacroRegimeCard struct {
    State     MacroState
    UpdatedAt time.Time
    Source    string
}

type IndicatorValue struct {
    SeriesCode string
    Value      decimalx.Decimal  // 或按 ADR 决策
    Date       time.Time
    Source     string
}
```

## 10. 数据模型

```go
type MacroPoint struct {
    SeriesCode      string
    Value           decimalx.Decimal
    ObservedAt      time.Time   // 统计观测时间
    ReleasedAt      time.Time   // 数据发布时间
    AvailableAt     time.Time   // 数据可用时间（fail-closed 关键字段）
    RevisionVersion int         // >= 0
    IsPreliminary   bool
    Source          string      // 数据来源标识
}

type MacroInformationSet struct {
    decisionTime     time.Time
    points           []MacroPoint  // 仅含 IsVisibleAt(DecisionTime)=true
    dataFreshnessSec float64
}

type MacroState string  // recovery/expansion/slowdown/contraction

type MacroRegimeCard struct {
    State     MacroState
    UpdatedAt time.Time
    Source    string
}

type IndicatorValue struct {
    SeriesCode string
    Value      decimalx.Decimal
    Date       time.Time
    Source     string
}
```

## 11. 配置模式

```yaml
domain_macro:
  precision_policy: decimal  # decimal | float64_compatible
  visibility:
    require_available_at: true
    fail_closed: true
  freshness:
    max_staleness_sec: 86400
  metrics:
    missing_available_at: true
    future_data_rejected: true
    information_set_violation: true
```

## 12. 错误处理

| 错误 | 含义 | 调用方处理 |
|------|------|-----------|
| ErrMissingAvailableAt | MacroPoint.AvailableAt 为零值 | 采集层须补齐 AvailableAt；否则回测/策略拒绝 |
| ErrLookAheadBias | IsVisibleAt 检测到前视偏差 | 检查 DecisionTime 设置 |
| ErrInvalidRevision | RevisionVersion < 0 | 修正 RevisionVersion |
| ErrInvalidSeriesCode | SeriesCode 为空或非法 | 检查 SeriesCode 格式 |
| ErrFutureDataRejected | AvailableAt 晚于 DecisionTime | 确认时间语义或调整 DecisionTime |

## 13. 边界情况

- MacroPoint.AvailableAt 为零值：Validate 失败，IsVisibleAt 返回 false
- 同一 SeriesCode+ObservedAt 有 preliminary 和 final 两个版本：revision 更高且可见的优先
- DecisionTime 恰好等于 AvailableAt：可见（<= 含边界）
- MacroInformationSet.Points 为空切片：DataFreshnessSec 返回 -1
- 时区差异：ObservedAt/ReleasedAt/AvailableAt 使用 UTC，跨时区须在采集层统一
- RevisionVersion 相同时有 preliminary 和 final：final 优先

## 14. 目录结构

```text
module/domain-macro/
  SPEC.md
  goal.md
  TRACEABILITY.md
  IMPLEMENTATION-PLAN.md
  tasks/
```

## 15. 依赖

- 允许：`kernel`（errors、contracts）
- 允许：`decimalx`（宏观值精度，按 ADR 决策）
- 禁止：provider API client（Yahoo/FRED）
- 禁止：transport 层（HTTP、gRPC）
- 禁止：存储层（Redis、Postgres、TDengine）
- 禁止：策略/因子/风控模块
- 禁止：`yahoo_models` 等 provider DTO 在公共 API 暴露

## 16. 测试

- 单元测试：MacroPoint.Validate、IsVisibleAt 各时间组合
- 单元测试：FilterMacroPointsForBacktest 的 dedup/revision selection
- Property 测试：随机时间组合验证 IsVisibleAt 不泄露未来数据
- Fuzz 测试：随机 MacroPoint 集合验证 MacroInformationSet deterministic
- Race 测试：并发读取 MacroInformationSet
- Golden 测试：典型宏观修订案例快照

### 16.1 Traceability Test Cases

**TC-MAC-001:** 缺失 AvailableAt 的 MacroPoint → Validate 失败。
**TC-MAC-002:** DecisionTime 之后 AvailableAt 的点 → IsVisibleAt 返回 false。
**TC-MAC-003:** 同一 SeriesCode+ObservedAt 多 revision → 选择最高可见版本。
**TC-MAC-004:** MacroInformationSet 不暴露可变内部 slice（copy-on-write）。
**TC-MAC-005:** 未来修订版本不可见。
**TC-MAC-006:** 并发读取 MacroInformationSet 无 data race。
**TC-MAC-007:** provider DTO 不在 domain Public API 泄漏。

## 17. 性能预算

| 指标 | 目标 |
|------|------|
| IsVisibleAt | < 100ns |
| FilterMacroPointsForBacktest（1000 点） | < 1ms |
| MacroInformationSet 构造（copy-on-write） | < 500μs |

## 18. 可观测性

- Metrics：freshness、missing_available_at、future_data_rejected、information_set_violation
- Metric 命名在 SPEC 中固定，不得在 minor 版本内变更
- 证据报告格式：JSON

## 19. 安全

- 不读取密钥
- 不连接远程服务
- Fail-closed 默认策略：缺失时间、未来数据、非法修订均返回错误

## 20. CI 门禁

- `GOWORK=off go test ./...`
- `GOWORK=off go test -race ./...`
- `GOWORK=off go test ./... -count=100`
- `staticcheck ./...`
- `govulncheck ./...`
- Lint：domain 原始值不得新增未决策的 float64 财务/宏观值
- `GOWORK=off make adoption-check`（如接入 xlib-standard）

## 21. 升级兼容性

- v1 IsVisibleAt/FilterMacroPointsForBacktest 语义保持稳定
- MacroState 枚举只可追加，不可删除或改值
- 精度 ADR 变更（float64 → decimalx.Decimal）为破坏性变更，须进 MIGRATION.md
- provider DTO 迁移为破坏性变更，须在 MIGRATION.md 写明

## 22. 发布 DoD

- [ ] SPEC Approved
- [ ] 所有 FR 实现并测试
- [ ] 缺失 AvailableAt 必须失败或不可见
- [ ] DecisionTime 之后数据不可见（property tests）
- [ ] RevisionVersion 选择 deterministic（golden tests）
- [ ] 宏观值精度策略已冻结（ADR + migration）
- [ ] Provider DTO 不污染 domain Public API
- [ ] MacroInformationSet 不暴露可变内部 slice（copy-on-write tests）
- [ ] Metrics 命名稳定
- [ ] Version 更新为 v1.0.0
- [ ] CHANGELOG.md、MIGRATION.md、release manifest 齐全

## 23. 待解决问题

- 宏观值精度：采用 decimalx.Decimal（方案 A）还是保留 float64 + DecimalValue（方案 B）？
- yahoo_models.go 是否迁入 internal/provider/yahoo 还是 infra 下游？
- 宏观日历事件模型是否纳入 v1.1？
- 数据源优先级与 fallback policy 是否纳入 v1.1？

---

### 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-15 | v1.0.0 | 初始版本：L2.5 宏观数据点与状态模型 | ZoneCNH |
