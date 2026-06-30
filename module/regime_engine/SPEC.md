# regime_engine 规格

## 1. Metadata

- Status: Draft
- Spec-Version: v0.1.0-draft
- Last-Updated: 2026-06-30
- Owner: ZoneCNH
- Layer: 分析域 · M×S 联合决策
- Version: v0.1.0-draft
- Repository: [github.com/ZoneCNH/regime_engine](https://github.com/ZoneCNH/regime_engine)
- Related: `CONSTITUTION.md`, `../factor_engine/`, `../domain_market/`, `../contracts/`

> 本文档发布 regime_engine 基线。运行时实现为 Pending（issue #1086 TASK-REGIME_ENGINE-001）。

---

## 2. 摘要

regime_engine 是 M×S 联合决策引擎，融合 market_regime(S) 和 macro_regime(M) 输出，生成 DecisionCard(action/risk/permission)。它是数据域→分析域→决策域链路的核心节点，下游 signal_factory 消费 DecisionCard 生成 SignalIntent。

---

## 3. Goals

| # | Goal | Trace |
| --- | --- | --- |
| G1 | M×S 融合决策 | FR-001 |
| G2 | DecisionCard 标准输出 | FR-002 |
| G3 | 状态转移平滑（hysteresis） | FR-003 |
| G4 | 决策可解释性 | FR-004 |

---

## 4. Non-goals

- 不做 S/M 分类本身（market_regime/macro_regime 负责）
- 不做信号生成（signal_factory 负责）
- 不做风控判断（riskx 负责）
- 不做数据采集（数据域负责）
- 不做回测（backtestx 负责）

---

## 5. Glossary

| 术语 | 含义 |
| --- | --- |
| S | market_regime 状态 S1-S7 |
| M | macro_regime 状态 M1-M7 |
| DecisionCard | 融合输出，含 action/risk_tier/position_caps/trade_permission |
| DecisionMatrix | S×M 查表矩阵（7×7=49 组合） |
| Hysteresis | 状态转移滞后阈值，避免频繁切换 |

---

## 6. Functional Requirements

### FR-001: M×S 融合

WHEN S 和 M 分类输出可用
THEN 按 DecisionMatrix[S][M] 查表生成 action/risk/permission
AND 输出 RegimeLabel 格式为 "S{N}_M{N}"

### FR-002: DecisionCard

WHEN 融合完成
THEN 输出 DecisionCard{Action, RiskLevel, Permission, RegimeLabel, Confidence, Factors}
AND Action ∈ {LONG_ONLY, SHORT_ONLY, LONG_SHORT, CASH}
AND RiskLevel ∈ {LOW, MEDIUM, HIGH, CRITICAL}
AND Permission ∈ {ALLOW, REDUCE, DENY}

### FR-003: 状态转移

WHEN S 或 M 分类变化
THEN 检测 regime transition 并平滑输出（hysteresis）
AND 滞后阈值可配置（默认 2 个周期）
AND transition 事件可观测

### FR-004: 可解释性

WHEN 输出 DecisionCard
THEN 附带决策因子贡献度（Factors map[string]float64）
AND 附带 regime 匹配度（Confidence 0.0-1.0）

---

## 7. Business Rules

| ID | 规则 |
| --- | --- |
| BR-001 | 输入校验 fail-closed，非法数据拒绝处理 |
| BR-002 | 输出数据结构不可变，下游只读消费 |
| BR-003 | 计算不得依赖未来数据（no lookahead） |

---

## 8. Non-functional Requirements

| ID | 类别 | 要求 | 验证 |
| --- | --- | --- | --- |
| NFR-001 | 性能 | Decide 延迟 < 1ms | Benchmark |
| NFR-002 | 质量 | 测试覆盖率 >= 80% | go tool cover |
| NFR-003 | 安全 | 无硬编码密钥 | gitleaks |
| NFR-004 | 可观测 | 输出 metrics + tracing | observex |

---

## 9. Interface Contracts

```go
type RegimeEngine interface {
    Decide(ctx context.Context, s SClassification, m MClassification) (DecisionCard, error)
}

type SClassification struct {
    State      string  // S1-S7
    Bias       string  // bullish/bearish/neutral
    Confidence float64
}

type MClassification struct {
    State      string  // M1-M7
    Score      float64 // LGIP
    Confidence float64
}

type DecisionCard struct {
    Action      string  // LONG_ONLY | SHORT_ONLY | LONG_SHORT | CASH
    RiskLevel   string  // LOW | MEDIUM | HIGH | CRITICAL
    Permission  string  // ALLOW | REDUCE | DENY
    RegimeLabel string  // e.g. "S3_M5"
    Confidence  float64
    Factors     map[string]float64
    PositionCaps PositionCaps
}

type PositionCaps struct {
    MaxLong  float64
    MaxShort float64
}
```

---

## 10. Data Models

| 模型 | 来源 | 用途 |
| --- | --- | --- |
| DecisionMatrix | 本模块 | 7×7 查表，S×M → action/risk/permission |
| DecisionCard | contracts v1.5.0 | 跨域 DTO，下游 signal_factory 消费 |
| RegimeSnapshot | contracts v1.5.0 | 输入快照（S+M） |

---

## 11. Error Handling

| 错误 | 原因 | 处理 |
| --- | --- | --- |
| ErrInvalidSClassification | S 状态非法 | fail-closed，返回 error |
| ErrInvalidMClassification | M 状态非法 | fail-closed，返回 error |
| ErrDecisionMatrixGap | S×M 组合未定义 | fail-closed，返回 error（需补全矩阵） |

---

## 12. Boundary Scenarios

| 场景 | 预期 |
| --- | --- |
| S/M 同时变化 | 按 hysteresis 平滑，取新状态 |
| S/M 均非法 | DENY + CASH |
| Confidence=0 | DENY |
| 矩阵缺口 | fail-closed error |
| ctx 取消 | 立即返回 ctx.Err |

---

## 13. Acceptance Criteria

| AC | 描述 |
| --- | --- |
| AC-REGIME_ENGINE-001 | M×S 融合输出 DecisionCard |
| AC-REGIME_ENGINE-002 | DecisionCard 含 action/risk_tier/position_caps |
| AC-REGIME_ENGINE-003 | 状态转移可追溯（hysteresis） |
| AC-REGIME_ENGINE-004 | 输出可解释性字段完整（Factors + Confidence） |

---

## 14. Test Cases

| TC | 覆盖 | 类型 |
| --- | --- | --- |
| TC-REGIME_ENGINE-001 | FR-001 | 单元测试 |
| TC-REGIME_ENGINE-002 | FR-002 | 单元测试 |
| TC-REGIME_ENGINE-003 | FR-003 | 单元测试 |
| TC-REGIME_ENGINE-004 | FR-004 | 单元测试 |
| TC-REGIME_ENGINE-005 | BR-001 | 单元测试 |
| TC-REGIME_ENGINE-006 | BR-002 | 单元测试 |
| TC-REGIME_ENGINE-007 | BR-003 | 单元测试 |

---

## 15. Constitution Compliance

| 条款 | 合规 |
| --- | --- |
| §1 P1 Foundation 先边界后功能 | ✅ 接口先于实现 |
| §3 依赖单向 | ✅ 依赖 contracts/market_regime/macro_regime |
| §4 窄接口 | ✅ 1 方法 Decide |
| §5 测试标准 | ✅ 7 TC，覆盖率 >=80% |
| §7 命名 | ✅ snake_case regime_engine |

---

## 16. Directory Structure

```text
regime_engine/
├── cmd/regime_engine/main.go
├── internal/
│   ├── engine.go
│   ├── engine_test.go
│   └── matrix.go
├── pkg/regime_enginex/
│   └── regime_engine.go
├── go.mod
└── README.md
```

---

## 17. CI Gate

| Gate | 命令 |
| --- | --- |
| 编译 | `go build ./...` |
| 测试 | `go test ./... -race -count=1` |
| 覆盖率 | `go test -coverprofile=...` (>=80%) |
| vet | `go vet ./...` |
| lint | `golangci-lint run` |

---

## 18. Test Matrix

| 层级 | 范围 | 工具 |
| --- | --- | --- |
| 单元 | internal/engine | go test |
| 边界 | 49 S×M 组合 | table-driven test |
| 契约 | DecisionCard schema | contract test vs contracts |
| 性能 | Decide 延迟 | benchmark |

---

## 19. Performance Budget

| 指标 | 预算 |
| --- | --- |
| Decide 延迟 | < 1ms |
| 内存 | < 10MB |
| 启动 | < 100ms |

---

## 20. Observability Output

| 输出 | 格式 | 用途 |
| --- | --- | --- |
| regime_decision_total | counter | 决策次数 |
| regime_transition_total | counter | 状态转移次数 |
| regime_decision_latency | histogram | 延迟分布 |
| trace: Decide | span | 链路追踪 |

---

## 21. Release DoD

- [ ] 7 TC 全 PASS
- [ ] 覆盖率 >=80%
- [ ] contracts v1.5.0 对齐验证
- [ ] README H1 = `# regime_engine`
- [ ] go.mod = `github.com/ZoneCNH/regime_engine`
- [ ] GitHub Release tag

---

## 22. Dependencies

| 依赖 | 版本 | 用途 |
| --- | --- | --- |
| contracts | v1.5.0 | DecisionCard DTO |
| market_regime | v0.2.0 | S 分类输入 |
| macro_regime | v0.2.0 | M 分类输入 |
| bootstrap | v0.2.0 | 进程组装 |
| kernel | v1.0.0 | L0 原语 |
| observex | v0.3.4 | 可观测 |

---

## 23. Change Log

| 日期 | 版本 | 变更 | 作者 |
| --- | --- | --- | --- |
| 2026-06-25 | v0.1.1 | 23 节完整结构补全（issue #1091） | ZoneCNH |
| 2026-06-17 | v0.1.0-draft | 初始基线 | ZoneCNH |
