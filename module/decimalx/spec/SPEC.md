# decimalx 规格

- Status: Approved
- Owner: xhyperium
- Spec-Version: v1.0.0
- Last-Updated: 2026-07-10
- Layer: L2.5 领域共享
- Version: v1.0.0
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `kernel`

> 公开投影 caveat：Status=Approved 与 100.0% 覆盖证据不等同于 factory-grade；机器事实层保持 factory=false。

---

## 1. 摘要

`decimalx` 定义 ZoneCNH 金融域共享的定点十进制与货币值对象。它是 L2.5 数值语义根，向上服务市场数据、交易接口、宏观数据与交易域模型。

## 2. 边界

| 类型 | 说明 |
| --- | --- |
| Owns | `Decimal`、rounding/context、`Money`、`Currency`、JSON/SQL 数值边界 |
| Depends on | `kernel` 的基础错误/契约能力；不得依赖业务域模块 |
| Excludes | 交易所精度规则、账本/税务/估值、策略计算、通用数学 DSL |

## 3. 功能需求

| ID | 需求 |
| --- | --- |
| FR-DEC-001 | `Decimal` 必须不可变，任何系数导出不得暴露内部可变状态。 |
| FR-DEC-002 | Parse 必须采用稳定语法，拒绝空白、指数和非规范格式。 |
| FR-DEC-003 | 字符串输出必须区分规范输出、固定精度输出与调试输出。 |
| FR-DEC-004 | 加减乘必须精确；除法、量化和舍入必须显式携带 rounding/context。 |
| FR-DEC-005 | JSON 表达必须是带引号十进制字符串，避免 JavaScript/JSON number 精度损失。 |
| FR-DEC-006 | SQL scan 必须拒绝 float 输入，防止静默精度损失。 |
| FR-DEC-007 | `Money` 的币种必须参与等价性与运算校验，跨币种加减必须失败。 |
| FR-DEC-008 | 公开错误必须可用 `errors.Is` 识别并保持兼容。 |

## 4. 非功能需求

- 可审计：同一输入在不同机器、时区与运行时必须得到一致输出。
- 可迁移：v1.0.0 后公共 API 破坏性变更必须进入新主版本。
- 可验证：核心算术、格式化、JSON、SQL、Money/Currency 均需 golden 或 property 测试。

## 5. 非目标与发布门禁

- 不实现交易所精度规则（price tick、lot size 等由 domain_market/domain_exchange 负责）
- 不实现账本、税务或估值计算（由上层业务域负责）
- 不实现策略计算或指标公式（由因子引擎和策略域负责）
- 不提供通用数学 DSL 或统计分析库（只做精确十进制算术）
- 不依赖任何业务域模块（domain_market、domain_exchange、domain_macro、domainx）
- 不依赖 transport 层（HTTP、gRPC、Kafka）或存储层（Redis、Postgres、TDengine）

### v1.0.0 发布门禁

| 门禁 | 要求 |
| --- | --- |
| API freeze | 公共 API、错误类型、序列化语义完成兼容测试。 |
| 精度门禁 | 不允许 float64 参与公共 decimal/money 输入输出。 |
| 下游门禁 | `domain_market`、`domain_exchange`、`domain_macro`、`domainx` 可编译采用。 |
| CI 门禁 | 单元测试、race、fuzz/property、staticcheck、govulncheck 通过。 |

## 6. 消费者

- `domain_market`：Tick/Quote/Bar 的 Price/Qty 字段
- `domain_exchange`：PlaceOrderRequest 的 Price/Qty、Balance 的 Free/Locked
- `domain_macro`：MacroPoint 的 Value 字段（精度 ADR 决策后）
- `domainx`：Order/Position/ExecutionReport 金额字段
- `order_engine`、`risk_engine`、`factor_engine`：策略与执行层全部金融数值

## 7. 功能需求

| ID | 需求 | WHEN | THEN |
|----|------|------|------|
| FR-DEC-001 | decimal-immutable | 调用 `Coeff()` 或任何算术方法 | 返回 `big.Int` 副本，receiver 不被修改 |
| FR-DEC-002 | parse-grammar | 输入十进制字符串 | 仅接受普通十进制；拒绝空串、空格、指数记法、非法 scale |
| FR-DEC-003 | string-output | 调用 `String()`/`CanonicalString()`/`FixedString(scale)` | `String()` 保留 scale；`CanonicalString()` 去除无意义 0；`FixedString` 必须 exact 或返回 rounding-required 错误 |
| FR-DEC-004 | arithmetic-exact | 调用 Add/Sub/Mul | 结果精确，无舍入 |
| FR-DEC-005 | arithmetic-rounding | 调用 Quo/Quantize/Rescale | 必须显式携带 Rounding/Context 参数；零值 Context 对非精确商不得静默四舍五入 |
| FR-DEC-006 | rounding-modes | 使用 RoundDown/RoundHalfEven/RoundHalfUp | 每种 mode 语义锁定、边界行为测试通过 |
| FR-DEC-007 | json-encoding | 序列化/反序列化 Decimal | JSON 值必须是带引号十进制字符串 |
| FR-DEC-008 | sql-scan | SQL `Scan(float32)` 或 `Scan(float64)` | 返回错误，拒绝 float 输入 |
| FR-DEC-009 | money-currency | 跨币种 Add/Sub | 返回错误，不允许跨币种运算 |
| FR-DEC-010 | error-identity | 调用方使用 `errors.Is`/`errors.As` | typed errors 可识别，错误码可被 transport 层映射 |

## 8. 行为约束

| ID | 规则 |
|----|------|
| BR-DEC-001 | `Decimal` 不可变——所有 arithmetic 返回新值，不修改 receiver |
| BR-DEC-002 | `Parse` 默认使用 `DefaultLimits`，拒绝超出 precision/scale 上限的输入 |
| BR-DEC-003 | 非精确除法必须显式 rounding，零值 Context 不得静默截断 |
| BR-DEC-004 | JSON 序列化仅允许带引号十进制字符串，禁止 JSON number |
| BR-DEC-005 | SQL `Scan(float64)` 必须失败——防止静默精度损失 |
| BR-DEC-006 | `Money` 跨币种运算必须失败——防止隐式汇率假设 |
| BR-DEC-007 | rounding mode 语义一旦冻结不可在 minor 版本内变更 |


### Acceptance Criteria Registry

| AC ID | FR/BR Ref | Criterion |
|-------|-----------|----------|
| AC-DEC-001 | FR-DEC-001 | TC-DEC-001, TC-DEC-007 | `go test -race ./...` | |
| AC-DEC-002 | FR-DEC-002 | TC-DEC-002 | `go test -run TestParse -fuzz=FuzzParse` | |
| AC-DEC-003 | FR-DEC-003 | TC-DEC-003 | `go test -run TestString` | |
| AC-DEC-004 | FR-DEC-004 | TC-DEC-005 | `go test -run TestArithmetic` | |
| AC-DEC-009 | FR-DEC-006 | TC-DEC-008 | `go test -run TestRounding` | |
| AC-DEC-005 | FR-DEC-007 | TC-DEC-003 | `go test -run TestJSON -fuzz=FuzzJSON` | |
| AC-DEC-006 | FR-DEC-008 | TC-DEC-004 | `go test -run TestSQLScan` | |
| AC-DEC-007 | FR-DEC-009 | TC-DEC-006 | `go test -run TestMoney` | |
| AC-DEC-008 | FR-DEC-010 | TC-DEC-008 | `go test -run TestErrors` | |

## 9. 接口契约

```go
// Decimal 是不可变定点十进制数。
type Decimal struct { /* unexported fields */ }

func New(coeff int64, scale int32) Decimal
func Parse(s string) (Decimal, error)
func (d Decimal) Coeff() *big.Int       // 返回 copy
func (d Decimal) Scale() int32
func (d Decimal) String() string         // 保留 scale
func (d Decimal) CanonicalString() string
func (d Decimal) FixedString(scale int32) (string, error)
func (d Decimal) Add(other Decimal) Decimal
func (d Decimal) Sub(other Decimal) Decimal
func (d Decimal) Mul(other Decimal) Decimal
func (d Decimal) QuoExact(other Decimal) (Decimal, error)
func (d Decimal) QuoScale(other Decimal, scale int32, r Rounding) (Decimal, error)
func (d Decimal) Quantize(scale int32, r Rounding) (Decimal, error)
func (d Decimal) Rescale(scale int32, r Rounding) (Decimal, error)

type Rounding int
const (
    RoundDown     Rounding = iota
    RoundHalfEven
    RoundHalfUp
)

type Context struct { /* unexported fields */ }
type Limits struct {
    MaxPrecision int32
    MaxScale     int32
    MinScale     int32
}

var DefaultLimits Limits

// Money 是带币种的金额。
type Money struct { /* unexported fields */ }
func NewMoney(amount Decimal, currency Currency) Money
func (m Money) Add(other Money) (Money, error)
func (m Money) Sub(other Money) (Money, error)
func (m Money) Currency() Currency

type Currency string
type Price = Decimal
type Qty = Decimal
type Ratio = Decimal
```

## 10. 数据模型

```go
// Decimal 内部表示：coefficient * 10^(-scale)
// coefficient 使用 math/big.Int（不可变副本对外暴露）
// scale 可为负数（表示大数）

type Decimal struct {
    coeff *big.Int
    scale int32
}

type Limits struct {
    MaxPrecision int32  // 默认 18
    MaxScale     int32  // 默认 18
    MinScale     int32  // 默认 -18
}

type Money struct {
    amount   Decimal
    currency Currency
}

type CurrencyPolicy struct {
    Code      string
    MinorUnit int32
}
```

## 11. 配置模式

```yaml
decimalx:
  default_limits:
    max_precision: 18
    max_scale: 18
    min_scale: -18
  rounding_default: RoundHalfEven
```

## 12. 错误处理

| 错误 | 含义 | 调用方处理 |
|------|------|-----------|
| ErrParseFailed | 输入不是合法十进制字符串 | 检查输入格式，拒绝空白/指数/非法字符 |
| ErrScaleOverflow | scale 超出 Limits 范围 | 检查 scale 参数或调整 Limits |
| ErrPrecisionOverflow | precision 超出 Limits 范围 | 检查运算结果位数或调整 Limits |
| ErrRoundingRequired | FixedString 要求 exact 但需要舍入 | 改用 CanonicalString 或提供 Rounding |
| ErrDivZero | 除数为零 | 上游必须检查除数 |
| ErrNonTerminating | 除法结果为非终止小数 | 使用 QuoScale 并提供显式 rounding |
| ErrFloatScanRejected | SQL Scan 收到 float32/float64 | 确保数据库列使用 DECIMAL/STRING 类型 |
| ErrCurrencyMismatch | Money 跨币种运算 | 先转换币种或拒绝运算 |

## 13. 边界情况

- Parse 空字符串、`".1"`、`"1."`、`"+1"`、`"1e3"`、`"NaN"`、`"Inf"` 均须拒绝或按 grammar 规则处理
- scale 为负数时的 String/CanonicalString 输出（如 coeff=123, scale=-2 → "12300"）
- DefaultLimits 边界：precision 恰好等于 MaxPrecision 时通过，超出时拒绝
- 并发读取同一 Decimal/Money：必须无 data race
- `Coeff()` 返回的 `*big.Int` 被调用方修改不影响原 Decimal
- JSON 反序列化时遇到无引号 number（如 `1.23` 而非 `"1.23"`）必须失败

## 14. 目录结构

```text
module/decimalx/
  SPEC.md
  goal.md
  TRACEABILITY.md
  IMPLEMENTATION-PLAN.md
  tasks/
```

## 15. 依赖

- 允许：`kernel`（errors、contracts）
- 允许：Go 标准库 `math/big`、`strconv`、`encoding/json`、`database/sql`、`fmt`
- 禁止：任何业务域模块（domain_market、domain_exchange、domain_macro、domainx）
- 禁止：transport 层（HTTP、gRPC、Kafka）
- 禁止：存储层（Redis、Postgres、TDengine）

## 16. 测试

- 单元测试：Parse/String/CanonicalString/FixedString table tests
- 算术测试：Add/Sub 精确性；QuoExact 非终止拒绝；QuoScale rounding
- Fuzz 测试：`FuzzParseRoundTrip`、`FuzzJSONRoundTrip`、`FuzzAddSubInvariant`、`FuzzQuantizeRescale`
- Race 测试：并发读取同一 Decimal/Money
- Benchmark：Parse、String、Add、Mul、QuoScale、JSON
- Golden/snapshot：v1 freeze 公开行为写入 `testdata/v1/*.golden`

### 16.1 Traceability Test Cases

**TC-DEC-001:** `Coeff()` 返回 copy，修改 copy 不影响原 Decimal。
**TC-DEC-002:** Parse 拒绝空串、指数、空白、非法 scale。
**TC-DEC-003:** JSON round-trip：`"1.23000"` → Decimal → `"1.23000"`。
**TC-DEC-004:** `Scan(float64)` 返回 ErrFloatScanRejected。
**TC-DEC-005:** `QuoExact(1,3)` 返回 ErrNonTerminating。
**TC-DEC-006:** `Money(USD).Add(Money(EUR))` 返回 ErrCurrencyMismatch。
**TC-DEC-007:** 并发读取 Decimal 无 data race。
**TC-DEC-008:** v1 golden snapshot 行为一致。

## 17. 性能预算

| 指标 | 目标 |
|------|------|
| Parse（10 位数字） | < 1μs |
| String 输出 | < 500ns |
| Add/Mul | < 500ns |
| JSON Marshal/Unmarshal | < 2μs |
| QuoScale | < 1μs |

## 18. 可观测性

- 无运行时指标（纯计算库）
- 错误通过 typed errors 和错误码暴露，可被上层 observex 包装

## 19. 安全

- `DefaultLimits` 防止资源滥用（超长精度/超大 scale 拒绝）
- `ParseUnlimited` 仅允许 trusted boundary 使用，需 lint/文档约束
- 不读取密钥、不连接网络、不操作文件系统

## 20. CI 门禁

- `GOWORK=off go test ./...`
- `GOWORK=off go test -race ./...`
- `GOWORK=off go test ./... -fuzz=Fuzz -fuzztime=30s`
- `GOWORK=off go test ./... -bench=. -run '^$'`
- `staticcheck ./...`
- `govulncheck ./...`
- `GOWORK=off make adoption-check`（如接入 xlib_standard）
- `GOWORK=off make release-check`

## 21. 升级兼容性

- v1 Public API freeze 后字段删除、重命名、语义反转必须进入 v2
- 新增 rounding mode 属于向后兼容（新增常量不破坏现有代码）
- 错误类型只可追加，不可删除或改语义
- Money/Currency 若 v1 后拆出为 `moneyx`，须在 MIGRATION.md 写明迁移路径

## 22. 发布 DoD

- [ ] SPEC Approved
- [ ] 所有 FR 实现并测试
- [ ] API freeze review 通过，TRACEABILITY 中 Public API 项无 TBD
- [ ] Decimal immutability：Coeff() 不泄露内部状态（单测 + race）
- [ ] Parse grammar 固定，指数/空白/非法 scale 被拒绝（table tests + fuzz）
- [ ] JSON 必须是 quoted decimal string（round-trip tests）
- [ ] SQL float scan 必须失败
- [ ] Quo/Quantize 必须显式 rounding/context
- [ ] Money 跨币种 Add/Sub 失败
- [ ] v1 behavior snapshot 固化（golden files）
- [ ] 下游模块 smoke 通过（domain_market、domain_exchange、domain_macro、domainx）
- [ ] Version 更新为 v1.0.0
- [ ] CHANGELOG.md、MIGRATION.md、release manifest 齐全

## 23. 待解决问题

- Money/Currency 是否保留在 decimalx v1 Public API，或拆出新模块 moneyx？
- 是否需要更多 rounding modes（Ceiling、Floor、AwayFromZero）？
- ISO-4217 currency minor unit table 是否纳入 v1.1？
- decimal serialization schema registry 是否纳入 v1.1？

---

### 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-15 | v1.0.0 | 初始版本：L2.5 数值语义根，Decimal/Money/Currency 值对象 | ZoneCNH |
