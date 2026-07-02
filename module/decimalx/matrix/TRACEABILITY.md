# decimalx 需求追溯矩阵

> 模块级追溯矩阵。治理规范见 [docs/governance/TRACEABILITY.md](../../docs/governance/TRACEABILITY.md)。

Last-Updated: 2026-06-30
Source: module/decimalx/SPEC.md

---

## §1 FR Traceability

| FR ID | Requirement | AC ID(s) | TC ID(s) | Task | Verification | Status |
|-------|-------------|----------|----------|------|--------------|--------|
| FR-DEC-001 | decimal-immutable | AC-DEC-001 | TC-DEC-001, TC-DEC-007 | TASK-DECIMALX-001 | `go test -race ./...` | ✅ |
| FR-DEC-002 | parse-grammar | AC-DEC-002 | TC-DEC-002 | TASK-DECIMALX-002 | `go test -run TestParse -fuzz=FuzzParse` | ✅ |
| FR-DEC-003 | string-output | AC-DEC-003 | TC-DEC-003 | TASK-DECIMALX-003 | `go test -run TestString` | ✅ |
| FR-DEC-004 | arithmetic-exact | AC-DEC-004 | TC-DEC-005 | TASK-DECIMALX-004 | `go test -run TestArithmetic` | ✅ |
| FR-DEC-005 | arithmetic-rounding | AC-DEC-004 | TC-DEC-005 | TASK-DECIMALX-004 | `go test -run TestQuoScale` | ✅ |
| FR-DEC-006 | rounding-modes | AC-DEC-009 | TC-DEC-008 | TASK-DECIMALX-004 | `go test -run TestRounding` | ✅ |
| FR-DEC-007 | json-encoding | AC-DEC-005 | TC-DEC-003 | TASK-DECIMALX-003 | `go test -run TestJSON -fuzz=FuzzJSON` | ✅ |
| FR-DEC-008 | sql-scan | AC-DEC-006 | TC-DEC-004 | TASK-DECIMALX-003 | `go test -run TestSQLScan` | ✅ |
| FR-DEC-009 | money-currency | AC-DEC-007 | TC-DEC-006 | TASK-DECIMALX-005 | `go test -run TestMoney` | ✅ |
| FR-DEC-010 | error-identity | AC-DEC-008 | TC-DEC-008 | TASK-DECIMALX-006 | `go test -run TestErrors` | ✅ |

---

## §2 BR Traceability

| BR ID | Rule | TC ID(s) | Task | Verification | Status |
|-------|------|----------|------|--------------|--------|
| BR-DEC-001 | `Decimal` 不可变——所有 arithmetic 返回新值，不修改 receiver | TC-DEC-001, TC-DEC-007 | TASK-DECIMALX-001 | TC-DEC-001 (`Coeff()` 返回 copy), TC-DEC-007 (并发读取无 data race) | ✅ |
| BR-DEC-002 | `Parse` 默认使用 `DefaultLimits`，拒绝超出 precision/scale 上限的输入 | TC-DEC-002 | TASK-DECIMALX-002 | TC-DEC-002 (Parse 拒绝空串/指数/空白/非法 scale) + boundary fuzz tests | ✅ |
| BR-DEC-003 | 非精确除法必须显式 rounding，零值 Context 不得静默截断 | TC-DEC-005 | TASK-DECIMALX-004 | TC-DEC-005 (`QuoExact(1,3)` 返回 ErrNonTerminating) | ✅ |
| BR-DEC-004 | JSON 序列化仅允许带引号十进制字符串，禁止 JSON number | TC-DEC-003 | TASK-DECIMALX-003 | TC-DEC-003 (JSON round-trip `"1.23000"` → Decimal → `"1.23000"`) | ✅ |
| BR-DEC-005 | SQL `Scan(float64)` 必须失败——防止静默精度损失 | TC-DEC-004 | TASK-DECIMALX-003 | TC-DEC-004 (`Scan(float64)` 返回 ErrFloatScanRejected) | ✅ |
| BR-DEC-006 | `Money` 跨币种运算必须失败——防止隐式汇率假设 | TC-DEC-006 | TASK-DECIMALX-005 | TC-DEC-006 (`Money(USD).Add(Money(EUR))` 返回 ErrCurrencyMismatch) | ✅ |
| BR-DEC-007 | rounding mode 语义一旦冻结不可在 minor 版本内变更 | — | TASK-DECIMALX-004 | FR-DEC-006 WHEN/THEN 行为 golden/snapshot 固化 + API freeze review | ✅ |

---

## §3 NFR Traceability

| NFR ID | Category | Requirement | Task | Verification | Status |
|--------|----------|-------------|------|--------------|--------|
| NFR-DEC-001 | 可审计 | 同一输入在不同机器、时区与运行时必须得到一致输出 | TASK-DECIMALX-007 | `go test ./...` (所有测试跨平台一致) + v1 golden snapshot (`testdata/v1/*.golden`) | ✅ |
| NFR-DEC-002 | 可迁移 | v1.0.0 后公共 API 破坏性变更必须进入新主版本 | TASK-DECIMALX-007 | API freeze review + `make release-check` + Go module `go vet` / `staticcheck` | ✅ |
| NFR-DEC-003 | 可验证 | 核心算术、格式化、JSON、SQL、Money/Currency 均需 golden 或 property 测试 | TASK-DECIMALX-007 | `go test ./...` + `go test -fuzz=Fuzz -fuzztime=30s` + `go test -race ./...` + `make adoption-check` | ✅ |

---

## §4 TC→FR Reverse

| TC ID | Covers FR(s) | Command |
|-------|-------------|---------|
| TC-DEC-001 | FR-DEC-001 | `Coeff()` 返回 copy，修改 copy 不影响原 Decimal |
| TC-DEC-002 | FR-DEC-002 | Parse 拒绝空串、指数、空白、非法 scale |
| TC-DEC-003 | FR-DEC-003, FR-DEC-007 | JSON round-trip：`"1.23000"` → Decimal → `"1.23000"` (覆盖格式化 + JSON 编码) |
| TC-DEC-004 | FR-DEC-008 | `Scan(float64)` 返回 ErrFloatScanRejected |
| TC-DEC-005 | FR-DEC-004, FR-DEC-005 | `QuoExact(1,3)` 返回 ErrNonTerminating (精确除失败，需显式 rounding) |
| TC-DEC-006 | FR-DEC-009 | `Money(USD).Add(Money(EUR))` 返回 ErrCurrencyMismatch |
| TC-DEC-007 | FR-DEC-001 | 并发读取 Decimal 无 data race |
| TC-DEC-008 | FR-DEC-001..FR-DEC-010 | v1 golden snapshot 行为一致 (全 FR 回归) |

---

## §5 AC Registry

| AC ID | FR/BR Ref | Criterion | Verification | Status |
|-------|-----------|-----------|-------------|--------|
| AC-DEC-001 | FR-DEC-001, BR-DEC-001 | 系数导出 copy，外部修改不影响原值 | (see TRACEABILITY.md §4) | ✅ |
| AC-DEC-002 | FR-DEC-002, BR-DEC-002 | whitespace/exponent/非法格式均拒绝 | (see TRACEABILITY.md §4) | ✅ |
| AC-DEC-003 | FR-DEC-003 | String/Canonical/FixedString 输出稳定 | (see TRACEABILITY.md §4) | ✅ |
| AC-DEC-004 | FR-DEC-004, FR-DEC-005, BR-DEC-003 | 精确运算与显式 rounding/context | (see TRACEABILITY.md §4) | ✅ |
| AC-DEC-005 | FR-DEC-007, BR-DEC-004 | JSON 仅使用 quoted decimal string | (see TRACEABILITY.md §4) | ✅ |
| AC-DEC-006 | FR-DEC-008, BR-DEC-005 | SQL scan 拒绝 float | (see TRACEABILITY.md §4) | ✅ |
| AC-DEC-007 | FR-DEC-009, BR-DEC-006 | Money 跨币种运算 fail-closed | (see TRACEABILITY.md §4) | ✅ |
| AC-DEC-008 | FR-DEC-010 | typed errors 支持 errors.Is | (see TRACEABILITY.md §4) | ✅ |
| AC-DEC-009 | FR-DEC-006, BR-DEC-007 | RoundDown/RoundHalfEven/RoundHalfUp 语义锁定，边界行为一致 | (see TRACEABILITY.md §4) | ✅ |

---

## §6 覆盖率仪表盘

| 维度 | 总数 | Done | 覆盖率 |
| --- | --- | --- | --- |
| FR | 10 | 10 | 100% |
| BR | 7 | 7 | 100% |


| NFR | 3 | 3 | 100% |
| AC | 9 | 9 | 100% |
| TC | 8 | 8 | 100% |
| **合计** | **37** | **37** | **100%** |

> 说明：全部 FR/BR/NFR/AC/TC 标记 Done。Task 总数 = TASK-DECIMALX-001~007 共 7 项。

---

## §7 变更历史

| 日期 | 变更内容 |
| --- | --- |
| 2026-06-29 | Goal 管线对齐：§1 FR/§2 BR/§3 NFR 表新增 Task 列（TASK-DECIMALX-001~007）；新增 §6 覆盖率仪表盘；新增 §7 变更历史 |
| 2026-06-16 | 初始版本：§1-§5 追溯矩阵 |
