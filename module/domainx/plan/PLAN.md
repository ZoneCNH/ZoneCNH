# domainx 实现计划

> 来源：[SPEC.md](./SPEC.md) v1.0.0
> 生成日期：2026-06-14

---

## 1. 依赖 DAG

```text
TASK-DOMAINX-001 (Order + Enums + Errors) ────────────────────────┐
│                                                                  │
├── TASK-DOMAINX-002 (Fill) ──────────────────────────────────────┤
├── TASK-DOMAINX-003 (Position) ──────────────────────────────────┤
├── TASK-DOMAINX-004 (Exposure) ──────────────────────────────────┤
│                                                                  │
├── TASK-DOMAINX-005 (JSON + Immutability + testdata) ────────────┤
│                                                                  │
└── TASK-DOMAINX-006 (CI gates + Benchmark + Docs) ───────────────┘
```

## 2. 实现顺序

### Phase 1: 基础骨架（1 task，阻塞全部）

| Task | 文件 | 依赖 | Effort |
|------|------|------|--------|
| TASK-DOMAINX-001 | order.go, order_test.go, enums.go, errors.go | — | 2h |

**交付物**：
- `enums.go`：Side / OrderType / OrderStatus / FillSide 常量定义
- `errors.go`：7 个公共错误变量（ErrInvalidQuantity, ErrInvalidPrice 等）
- `order.go`：Order 结构体 + NewOrder() 构造函数 + 校验逻辑 + getter
- `order_test.go`：TC-001~004（正常构造 + 非法 quantity/price/symbol）

### Phase 2: 独立值对象（3 tasks，全部可并行）

| Task | 文件 | 依赖 | Effort |
|------|------|------|--------|
| TASK-DOMAINX-002 | fill.go, fill_test.go | 001（enums, errors） | 1h |
| TASK-DOMAINX-003 | position.go, position_test.go | 001（errors） | 1h |
| TASK-DOMAINX-004 | exposure.go, exposure_test.go | 001（errors） | 1h |

**并行度：3**（互相无依赖，仅依赖 Phase 1 的 errors 和 enums）

**交付物**：
- TASK-002：Fill 结构体 + NewFill() + TC-005~006
- TASK-003：Position 结构体 + NewPosition() + MarketValue() + UnrealizedPnL() + TC-007~008
- TASK-004：Exposure 结构体 + NewExposure() + NetExposureRatio() + TC-009~010

### Phase 3: 横切验证（1 task）

| Task | 文件 | 依赖 | Effort |
|------|------|------|--------|
| TASK-DOMAINX-005 | json_test.go, testdata/*.json | 001, 002, 003, 004 | 1.5h |

**交付物**：
- `json_test.go`：TC-011~014（Order/Fill JSON round-trip + 缺失字段错误 + 并发读 race）
- `testdata/`：5 个 golden files（order_valid/invalid, fill_valid, position_valid, exposure_valid）

### Phase 4: 质量门禁（1 task）

| Task | 文件 | 依赖 | Effort |
|------|------|------|--------|
| TASK-DOMAINX-006 | go.mod, benchmark_test.go, doc.go, README.md, CHANGELOG.md, LICENSE | 001, 002, 003, 004, 005 | 2h |

**交付物**：
- `go.mod` + `go.sum`：模块定义（stdlib + decimalx）
- `benchmark_test.go`：4 项 Benchmark（NewOrder, NewFill, MarketValue, JSONRoundTrip）
- `doc.go`：包级 godoc
- `README.md`：模块定位 + 类型概览 + 快速开始 + API 参考
- `CHANGELOG.md`：v1.0.0 初始发布

---

## 3. 总 Effort 估算

| Phase | Tasks | 并行度 | Effort（串行） | Effort（并行） |
|-------|-------|--------|---------------|---------------|
| Phase 1 | 1 | 1 | 2h | 2h |
| Phase 2 | 3 | 3 | 3h | 1h |
| Phase 3 | 1 | 1 | 1.5h | 1.5h |
| Phase 4 | 1 | 1 | 2h | 2h |
| **总计** | **6** | — | **8.5h** | **6.5h** |

---

## 4. 文件交付矩阵

| 文件 | TASK-001 | TASK-002 | TASK-003 | TASK-004 | TASK-005 | TASK-006 |
|------|:--------:|:--------:|:--------:|:--------:|:--------:|:--------:|
| enums.go | ✅ | | | | | |
| errors.go | ✅ | | | | | |
| order.go | ✅ | | | | | |
| order_test.go | ✅ | | | | | |
| fill.go | | ✅ | | | | |
| fill_test.go | | ✅ | | | | |
| position.go | | | ✅ | | | |
| position_test.go | | | ✅ | | | |
| exposure.go | | | | ✅ | | |
| exposure_test.go | | | | ✅ | | |
| json_test.go | | | | | ✅ | |
| testdata/*.json | | | | | ✅ | |
| go.mod | | | | | | ✅ |
| benchmark_test.go | | | | | | ✅ |
| doc.go | | | | | | ✅ |
| README.md | | | | | | ✅ |
| CHANGELOG.md | | | | | | ✅ |
| LICENSE | | | | | | ✅ |

---

## 5. Risk Assessment

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| decimalx 依赖未就绪 | Low | High（阻塞所有任务） | 确认 decimalx v1.0.0 已发布；若未发布，先 stubs |
| OrderStatus 六态争议（OQ-002） | Medium | Low（enum 常量易改） | 当前定义六态，如争议改为 string alias |
| 命名变更（OQ-001：domainx → domain-*） | Low | Medium（需 rename） | 在 Phase 1 前确认；如未确认，继续用 domainx |
| 并发安全测试漏检 | Low | Medium | TASK-005 显式包含 `go test -race` TC-014 |

---

## 6. CI Gate 矩阵

| Gate | Phase | 阻塞条件 |
|------|-------|----------|
| go build | Phase 1+ | 编译失败 |
| go test | Phase 1+ | 测试失败 |
| go test -race | Phase 3+ | data race |
| go vet | Phase 4 | vet 警告 |
| golangci-lint | Phase 4 | lint 错误 |
| coverage ≥ 80% | Phase 4 | 覆盖率不足 |
| gitleaks | Phase 4 | secret 泄露 |
| benchmark | Phase 4 | 性能回退 > 10% |

## 5. 风险与回滚

| 风险 | 级别 | 缓解 | 回滚 |
|------|------|------|------|
| API 破坏性变更 | LOW | 已有可工作实现，向后兼容 | `git revert` |
| 外部依赖不可用 | MEDIUM | 健康检查 + 降级策略 | 回退到上一稳定版本 |
| 配置兼容性回归 | LOW | 已有 canonical+legacy 测试覆盖 | 回退配置变更 |

