# domain_macro v1.0.0 Implementation Plan

| 字段 | 值 |
| --- | --- |
| 模块 | `domain_macro` |
| 当前版本 | v0.1.0 |
| 目标版本 | v1.0.0 |
| 依赖顺序 | `decimalx` API freeze 后，与 `domain_market` / `domainx` 可并行 |
| 最后更新 | 2026-06-16 |

## 里程碑

| 里程碑 | 内容 | 退出条件 |
| --- | --- | --- |
| M0 SPEC / Precision ADR | 冻结 float64 迁移或 Decimal 采用路线 | ADR/SPEC 完成 |
| M1 MacroPoint / InformationSet | 时间、可见性、copy-on-write、不变量 | no-lookahead 测试通过 |
| M2 Revision / As-of | revision ordering、preliminary/confirmed、as-of 查询 | revision 测试通过 |
| M3 Provider DTO boundary | `yahoo_models` 迁出或 internal 化 | static boundary scan 通过 |
| M4 Release | docs、CI、migration、release manifest | tag v1.0.0 前门禁通过 |

## M0: SPEC / Precision ADR

**目标**：冻结 API 语义与数值精度策略，为后续实现提供契约基线。

**任务**：
- TASK-MAC-007: 精度 ADR 与 decimalx 采用

**交付物**：
- `docs/adr/XXXX-precision-policy.md`：明确 MacroPoint.Value / IndicatorValue.Value 采用 `decimalx.Decimal` 或 float64 兼容路线
- `MIGRATION.md`：float64 → decimalx.Decimal 迁移指南
- SPEC Approved（已完成）
- TRACEABILITY Ready（已完成）

**退出条件**：
- [x] SPEC status = Approved
- [x] TRACEABILITY status = Ready
- [ ] ADR 文档完成且经评审
- [ ] CI lint 规则可检测未决策 float64

**依赖**：`decimalx` API freeze

---

## M1: MacroPoint / InformationSet — No-lookahead Invariant

**目标**：实现 MacroPoint 时间语义、fail-closed 可见性、MacroInformationSet copy-on-write，确保回测无前视偏差。

**任务**：
- TASK-MAC-001: MacroPoint 三类时间语义（ObservedAt/ReleasedAt/AvailableAt + Validate）
- TASK-MAC-002: MacroPoint 修订版本与来源审计（RevisionVersion/IsPreliminary/Source）
- TASK-MAC-003: IsVisibleAt fail-closed 可见性规则
- TASK-MAC-004: MacroInformationSet 与 copy-on-write

**交付物**：
- `macropoint.go`：MacroPoint struct + NewMacroPoint + Validate + IsVisibleAt + getter
- `errors.go`：ErrMissingAvailableAt, ErrLookAheadBias, ErrInvalidRevision, ErrInvalidSeriesCode, ErrFutureDataRejected
- `information_set.go`：MacroInformationSet + FilterMacroPointsForBacktest + DataFreshnessSec
- 测试：visibility table tests、property tests、race tests、copy-on-write tests

**退出条件**：
- [ ] IsVisibleAt fail-closed：缺失 AvailableAt → false
- [ ] IsVisibleAt fail-closed：未来数据 → false
- [ ] FilterMacroPointsForBacktest 仅返回可见点
- [ ] MacroInformationSet.Points() 返回 slice 副本
- [ ] DataFreshnessSec 空集返回 -1
- [ ] `go test ./... -race` 通过
- [ ] `go test ./... -count=100` 通过（property test）

**依赖**：M0 ADR 决策确定 Value 字段类型

---

## M2: Revision / As-of — 验证资产

**目标**：实现修订版本去重选择、preliminary/final 优先级、deterministic as-of 查询。

**任务**：
- TASK-MAC-005: RevisionVersion 选择与去重
- TASK-MAC-006: MacroState / MacroRegimeCard 枚举与校验

**交付物**：
- `revision.go`：SelectLatestRevisions 或集成到 FilterMacroPointsForBacktest
- `macrostate.go`：MacroState 枚举 + IsValid + MacroRegimeCard + Validate
- `indicator_value.go`：IndicatorValue struct
- 测试：revision ordering golden tests、MacroState validation tests

**退出条件**：
- [ ] 同一 SeriesCode+ObservedAt 多 revision → 选择最高可见版本
- [ ] preliminary 不得覆盖 final（除非 revision 更高且可见）
- [ ] RevisionVersion 相同时 final 优先于 preliminary
- [ ] MacroState 四枚举 IsValid == true，非法值 IsValid == false
- [ ] MacroRegimeCard.Validate 可校验
- [ ] Golden 测试通过
- [ ] `go test ./... -race` 通过

**依赖**：M1 完成（MacroPoint + InformationSet 基础）

---

## M3: Provider DTO Boundary — 下游采用

**目标**：确保 provider DTO 不污染 domain 公共 API，static boundary scan 通过。

**任务**：（SPEC FR-MAC-008，非独立 TASK 文件，集成到 M3 PR）

**交付物**：
- `yahoo_models.go` 等迁移到 `internal/provider/yahoo` 或 `infra` 包
- 公共 API 仅暴露中立领域模型
- static boundary scan 脚本或 CI gate

**退出条件**：
- [ ] `yahoo_models` 等不在 `domain/` 公共目录暴露
- [ ] static boundary scan 通过
- [ ] `GOWORK=off make adoption-check` 通过
- [ ] 下游模块编译通过

**依赖**：M1 + M2 完成（公共 API 冻结后才能确认边界）

---

## M4: Release

**目标**：发布 v1.0.0，包含文档、CI gate、release manifest。

**交付物**：
- `CHANGELOG.md`：v1.0.0 变更记录
- `MIGRATION.md`：迁移指南（如精度 ADR 涉及 breaking change）
- CI gate：staticcheck / govulncheck / boundary / adoption-check
- Git tag v1.0.0 + release manifest
- Release DoD 全部勾选

**退出条件**：
- [ ] SPEC Approved
- [ ] 所有 FR 实现并测试
- [ ] 缺失 AvailableAt 必须失败或不可见
- [ ] DecisionTime 之后数据不可见（property tests）
- [ ] RevisionVersion 选择 deterministic（golden tests）
- [ ] 宏观值精度策略已冻结（ADR + migration）
- [ ] Provider DTO 不污染 domain Public API
- [ ] MacroInformationSet 不暴露可变内部 slice
- [ ] Metrics 命名稳定
- [ ] Version 更新为 v1.0.0
- [ ] CHANGELOG.md、MIGRATION.md、release manifest 齐全
- [ ] `GOWORK=off go test ./... -race` 通过
- [ ] `staticcheck ./...` 通过
- [ ] `govulncheck ./...` 通过

**依赖**：M0 + M1 + M2 + M3 全部完成

---

## PR 类别

| 类别 | 目的 | 里程碑 |
| --- | --- | --- |
| docs-v1-contract | 明确 no-lookahead、revision、precision 和 DTO 边界 | M0 |
| api-v1-freeze | 冻结 MacroPoint、InformationSet、State/Regime API | M1 |
| invariant-tests | 覆盖 visibility、revision、copy-on-write、state validate | M1-M2 |
| provider-boundary | yahoo_models 迁出或 internal 化 | M3 |
| ci-release-gates | 加入 staticcheck/govulncheck/boundary/adoption gate | M4 |
| release-v1.0.0 | 发布 tag、release notes 与 manifest | M4 |

## 依赖图

```text
decimalx API freeze
       │
       ▼
      M0 (ADR)
       │
       ▼
      M1 (MacroPoint + InformationSet + Visibility)
       │
       ▼
      M2 (Revision + MacroState)
       │
       ▼
      M3 (Provider DTO boundary)
       │
       ▼
      M4 (Release)
```
