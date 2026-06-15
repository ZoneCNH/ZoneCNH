# decimalx Traceability Matrix

| 字段 | 值 |
| --- | --- |
| 模块 | `decimalx` |
| 目标版本 | v1.0.0 |
| 状态 | Ready |
| 最后更新 | 2026-06-16 |

## §1 FR Traceability

| FR ID | Requirement | WHEN | THEN | AC ID(s) | TC ID(s) | Verification |
| --- | --- | --- | --- | --- | --- | --- |
| FR-DEC-001 | decimal-immutable | 调用 `Coeff()` 或任何算术方法 | 返回 `big.Int` 副本，receiver 不被修改 | AC-DEC-001 | TC-DEC-001, TC-DEC-007 | `go test -race ./...` |
| FR-DEC-002 | parse-grammar | 输入十进制字符串 | 仅接受普通十进制；拒绝空串、空格、指数记法、非法 scale | AC-DEC-002 | TC-DEC-002 | `go test -run TestParse -fuzz=FuzzParse` |
| FR-DEC-003 | string-output | 调用 `String()`/`CanonicalString()`/`FixedString(scale)` | `String()` 保留 scale；`CanonicalString()` 去除无意义 0；`FixedString` 必须 exact 或返回 rounding-required 错误 | AC-DEC-003 | TC-DEC-003 | `go test -run TestString` |
| FR-DEC-004 | arithmetic-exact | 调用 Add/Sub/Mul | 结果精确，无舍入 | AC-DEC-004 | TC-DEC-005 | `go test -run TestArithmetic` |
| FR-DEC-005 | arithmetic-rounding | 调用 Quo/Quantize/Rescale | 必须显式携带 Rounding/Context 参数；零值 Context 对非精确商不得静默四舍五入 | AC-DEC-004 | TC-DEC-005 | `go test -run TestQuoScale` |
| FR-DEC-006 | rounding-modes | 使用 RoundDown/RoundHalfEven/RoundHalfUp | 每种 mode 语义锁定、边界行为测试通过 | AC-DEC-009 | TC-DEC-008 | `go test -run TestRounding` |
| FR-DEC-007 | json-encoding | 序列化/反序列化 Decimal | JSON 值必须是带引号十进制字符串 | AC-DEC-005 | TC-DEC-003 | `go test -run TestJSON -fuzz=FuzzJSON` |
| FR-DEC-008 | sql-scan | SQL `Scan(float32)` 或 `Scan(float64)` | 返回错误，拒绝 float 输入 | AC-DEC-006 | TC-DEC-004 | `go test -run TestSQLScan` |
| FR-DEC-009 | money-currency | 跨币种 Add/Sub | 返回错误，不允许跨币种运算 | AC-DEC-007 | TC-DEC-006 | `go test -run TestMoney` |
| FR-DEC-010 | error-identity | 调用方使用 `errors.Is`/`errors.As` | typed errors 可识别，错误码可被 transport 层映射 | AC-DEC-008 | TC-DEC-008 | `go test -run TestErrors` |

## §2 BR Traceability

| BR ID | Rule | Verification Method |
| --- | --- | --- |
| BR-DEC-001 | `Decimal` 不可变——所有 arithmetic 返回新值，不修改 receiver | TC-DEC-001 (`Coeff()` 返回 copy), TC-DEC-007 (并发读取无 data race) |
| BR-DEC-002 | `Parse` 默认使用 `DefaultLimits`，拒绝超出 precision/scale 上限的输入 | TC-DEC-002 (Parse 拒绝空串/指数/空白/非法 scale) + boundary fuzz tests |
| BR-DEC-003 | 非精确除法必须显式 rounding，零值 Context 不得静默截断 | TC-DEC-005 (`QuoExact(1,3)` 返回 ErrNonTerminating) |
| BR-DEC-004 | JSON 序列化仅允许带引号十进制字符串，禁止 JSON number | TC-DEC-003 (JSON round-trip `"1.23000"` → Decimal → `"1.23000"`) |
| BR-DEC-005 | SQL `Scan(float64)` 必须失败——防止静默精度损失 | TC-DEC-004 (`Scan(float64)` 返回 ErrFloatScanRejected) |
| BR-DEC-006 | `Money` 跨币种运算必须失败——防止隐式汇率假设 | TC-DEC-006 (`Money(USD).Add(Money(EUR))` 返回 ErrCurrencyMismatch) |
| BR-DEC-007 | rounding mode 语义一旦冻结不可在 minor 版本内变更 | FR-DEC-006 WHEN/THEN 行为 golden/snapshot 固化 + API freeze review |

## §3 NFR Traceability

| NFR ID | Category | Requirement | Verification |
| --- | --- | --- | --- |
| NFR-DEC-001 | 可审计 | 同一输入在不同机器、时区与运行时必须得到一致输出 | `go test ./...` (所有测试跨平台一致) + v1 golden snapshot (`testdata/v1/*.golden`) |
| NFR-DEC-002 | 可迁移 | v1.0.0 后公共 API 破坏性变更必须进入新主版本 | API freeze review + `make release-check` + Go module `go vet` / `staticcheck` |
| NFR-DEC-003 | 可验证 | 核心算术、格式化、JSON、SQL、Money/Currency 均需 golden 或 property 测试 | `go test ./...` + `go test -fuzz=Fuzz -fuzztime=30s` + `go test -race ./...` + `make adoption-check` |

## §4 TC→FR Reverse

| TC ID | Covers FR(s) | Description | Command |
| --- | --- | --- | --- |
| TC-DEC-001 | FR-DEC-001 | `Coeff()` 返回 copy，修改 copy 不影响原 Decimal | `go test -run TestCoeffCopy -race` |
| TC-DEC-002 | FR-DEC-002 | Parse 拒绝空串、指数、空白、非法 scale | `go test -run TestParse -fuzz=FuzzParse -fuzztime=30s` |
| TC-DEC-003 | FR-DEC-003, FR-DEC-007 | JSON round-trip：`"1.23000"` → Decimal → `"1.23000"` (覆盖格式化 + JSON 编码) | `go test -run TestJSONRoundTrip` |
| TC-DEC-004 | FR-DEC-008 | `Scan(float64)` 返回 ErrFloatScanRejected | `go test -run TestSQLScan` |
| TC-DEC-005 | FR-DEC-004, FR-DEC-005 | `QuoExact(1,3)` 返回 ErrNonTerminating (精确除失败，需显式 rounding) | `go test -run TestQuoExact` |
| TC-DEC-006 | FR-DEC-009 | `Money(USD).Add(Money(EUR))` 返回 ErrCurrencyMismatch | `go test -run TestMoneyCurrency` |
| TC-DEC-007 | FR-DEC-001 | 并发读取 Decimal 无 data race | `go test -run TestConcurrent -race` |
| TC-DEC-008 | FR-DEC-001..FR-DEC-010 | v1 golden snapshot 行为一致 (全 FR 回归) | `go test -run TestGoldenV1` + `GOWORK=off make release-check` |

## §5 AC Registry

| AC ID | FR/BR Reference | Criterion | Verification |
| --- | --- | --- | --- |
| AC-DEC-001 | FR-DEC-001, BR-DEC-001 | 系数导出 copy，外部修改不影响原值 | TC-DEC-001 (`go test -run TestCoeffCopy -race`) + TC-DEC-007 (`go test -run TestConcurrent -race`) |
| AC-DEC-002 | FR-DEC-002, BR-DEC-002 | whitespace/exponent/非法格式均拒绝 | TC-DEC-002 (`go test -run TestParse -fuzz=FuzzParse`) |
| AC-DEC-003 | FR-DEC-003 | String/Canonical/FixedString 输出稳定 | TC-DEC-003 (formatting round-trip) + `go test -run TestString` |
| AC-DEC-004 | FR-DEC-004, FR-DEC-005, BR-DEC-003 | 精确运算与显式 rounding/context | TC-DEC-005 (`go test -run TestQuoExact`) + `go test -run TestQuoScale` |
| AC-DEC-005 | FR-DEC-007, BR-DEC-004 | JSON 仅使用 quoted decimal string | TC-DEC-003 (JSON round-trip) + `go test -run TestJSON -fuzz=FuzzJSON` |
| AC-DEC-006 | FR-DEC-008, BR-DEC-005 | SQL scan 拒绝 float | TC-DEC-004 (`go test -run TestSQLScan`) |
| AC-DEC-007 | FR-DEC-009, BR-DEC-006 | Money 跨币种运算 fail-closed | TC-DEC-006 (`go test -run TestMoneyCurrency`) |
| AC-DEC-008 | FR-DEC-010 | typed errors 支持 errors.Is | TC-DEC-008 (`go test -run TestErrors`) |
| AC-DEC-009 | FR-DEC-006, BR-DEC-007 | RoundDown/RoundHalfEven/RoundHalfUp 语义锁定，边界行为一致 | TC-DEC-008 (v1 golden snapshot) + `go test -run TestRounding` |
