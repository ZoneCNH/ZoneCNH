# configx 完整规格

> Foundation L1 配置层。加载、验证、提供配置给所有其他模块。

最后更新：2026-06-07

---

## 1. Metadata

- Status: Approved
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-07
- Owner: ZoneCNH
- Layer: L1 基础能力
- Version: v0.1.4
- Repository: [github.com/ZoneCNH/configx](https://github.com/ZoneCNH/configx)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md)

---

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-12 | v1.0.2 | 版本号对齐：v0.7.3→v0.1.4 与 ARCHITECTURE.md 一致；Non-goals §5 澄清 RemoteSource SPI 扩展点；§15.2 移除已过时的 kernel 依赖声明 | ZoneCNH |
| 2026-06-12 | v1.0.1 | 对齐修复：移除过时 kernel.Deps 引用；Status Draft→Approved；依赖方向修正 kernel 为允许依赖；TRACEABILITY 完整重写 | ZoneCNH |
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |

## 2. Summary

`configx` 管理配置的加载、合并、验证和分发。支持 YAML/TOML/JSON 文件 + 环境变量覆盖，通过 schema 校验保证配置正确性。

---

## 3. Problem

70+ 模块各自加载配置，格式不统一、覆盖优先级不明确、缺少验证，导致：

- 同一配置在不同模块中 key 名不同
- 环境变量和文件冲突时行为不确定
- 配置错误在运行时才发现，定位困难
- 配置格式变更时需要修改多处代码

---

## 4. Goals

- 统一配置加载：文件（YAML/TOML/JSON）+ 环境变量 + 默认值
- 明确的覆盖优先级：默认值 → 文件 → 环境变量 → 命令行参数
- 启动时 schema 校验，fail-fast
- 并发安全读取
- 只读模式（运行时不允许修改配置）

---

## 5. Non-goals

- 不做运行时配置热更新（考虑作为后续特性）
- 不做远程配置中心产品（K8s ConfigMap 可通过文件挂载）；RemoteSource SPI 扩展点属于 v1.0 目标范围，由 goal.md 定义
- 不做敏感信息加密（→ 环境变量或 secret manager）
- 不做跨服务配置同步
- v1.0 目标（见 goal.md）：RemoteSource SPI、配置热更新回滚、敏感字段自动脱敏、配置文档生成

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| L1 运行时模块（observex, resiliencx, schedulex） | 通过 `Reader` 接口读取本模块配置 |
| 业务域模块 | 通过 `Reader` 接口读取业务配置 |
| `x.go` 组合根 | 创建 Config 实例，注入到各模块 |
| 存储扩展（redisx, kafkax 等） | 通过 `Reader` 接口读取连接配置 |

---

## 7. Functional Requirements

### FR-001: Load

WHEN 调用 `Load(path string)` 且文件存在且格式有效
THEN 解析文件内容，返回 nil

WHEN 调用 `Load(path string)` 且文件不存在
THEN 返回 `os.ErrNotExist`

WHEN 调用 `Load(path string)` 且文件格式无效（YAML/TOML/JSON 语法错误）
THEN 返回解析错误，配置不变

### FR-002: WithEnvOverride

WHEN 调用 `WithEnvOverride(prefix string)`
THEN 以 `prefix` 开头的环境变量覆盖对应配置键（`_` → `.`）

WHEN 环境变量值类型与 schema 不匹配
THEN 返回类型转换错误

### FR-003: Validate

WHEN 调用 `Validate()` 且配置符合 schema
THEN 返回 nil

WHEN 调用 `Validate()` 且配置不符合 schema
THEN 返回包含所有违规字段的错误列表

### FR-004: Get

WHEN 调用 `Get(key string)` 且 key 存在
THEN 返回对应值

WHEN 调用 `Get(key string)` 且 key 不存在
THEN 返回 nil

WHEN 多个 goroutine 并发调用 `Get`
THEN 无数据竞争（并发安全）

### FR-005: Watch（可选）

WHEN 调用 `Watch(key string, callback)` 且配置变更
THEN 调用 callback 通知变更

WHEN Watch 的 key 不存在
THEN 返回错误

---

## 8. Business Rules

| 编号 | 规则 |
|------|------|
| BR-001 | 覆盖优先级：默认值 → 文件 → 环境变量 → 命令行参数 |
| BR-002 | 启动时必须通过 schema 校验（fail-fast） |
| BR-003 | 配置键使用点分路径（`data.market.symbol`） |
| BR-004 | 环境变量覆盖使用前缀 + 下划线（`APP_DATA_MARKET_SYMBOL`） |
| BR-005 | Reader 接口只能读，不能写 |
| BR-006 | 配置值类型必须与 schema 定义一致 |
| BR-007 | 未定义的配置键应被忽略或报 warning（可配置） |
| BR-008 | 公共错误变量使用 `configx:` 前缀命名空间 |
| BR-009 | Reader/Config/Option 接口遵循 Go 接口隔离原则 |
| BR-010 | Release 制品通过全部 CI Gate（编译/测试/覆盖率/vet/lint/secret） |
| BR-011 | 敏感字段（password/token/secret/key/accessKey/secretKey）自动脱敏 |

---

## 9. Interface Contract

```go
type Reader interface {
    Get(key string) interface{}
    GetString(key string) string
    GetInt(key string) int
    GetFloat(key string) float64
    GetBool(key string) bool
    GetDuration(key string) time.Duration
    IsSet(key string) bool
}

type Config interface {
    Reader
    Load(path string) error
    WithEnvOverride(prefix string) Config
    Validate() error
    Watch(key string, callback func(interface{})) error
}

func New(opts ...Option) Config
```text

### 9.1 Option 模式

```go
type Option func(*config)

func WithDefaults(defaults map[string]interface{}) Option
func WithSchema(schema *jsonschema.Schema) Option
func WithEnvPrefix(prefix string) Option
func WithStrictMode(strict bool) Option  // 未定义的 key 报错
```text

### 9.2 用法示例

```go
cfg := configx.New(
    configx.WithDefaults(map[string]interface{}{
        "data.market.symbol":    "BTCUSDT",
        "data.market.interval":  "1m",
    }),
    configx.WithSchema(schema),
)

// 加载文件
if err := cfg.Load("config.yaml"); err != nil {
    return err
}

// 环境变量覆盖
cfg = cfg.WithEnvOverride("APP")

// 启动校验
if err := cfg.Validate(); err != nil {
    return err
}

// 读取配置
symbol := cfg.GetString("data.market.symbol")  // → "BTCUSDT" 或环境变量覆盖值
```text

---

## 10. Data Model

### 10.1 公共错误

```go
var (
    ErrInvalidFormat     = errors.New("configx: invalid format")
    ErrValidationFailed  = errors.New("configx: validation failed")
    ErrKeyNotFound       = errors.New("configx: key not found")
    ErrTypeMismatch      = errors.New("configx: type mismatch")
    ErrAlreadyLoaded     = errors.New("configx: already loaded")
)
```text

### 10.2 配置覆盖层次

```text
命令行参数（最高优先级）
    ↑ 覆盖
环境变量（前缀匹配）
    ↑ 覆盖
配置文件（YAML/TOML/JSON）
    ↑ 覆盖
默认值（WithDefaults）
```text

---

## 11. Config Schema

configx 自身的配置：

```yaml
config:
  path: config.yaml           # 配置文件路径
  format: yaml                # 文件格式：yaml / toml / json
  env_prefix: APP             # 环境变量前缀
  strict: false               # 未定义 key 是否报错
  watch: false                # 是否启用文件监控（可选）
```text

其他模块的配置通过统一的 schema 定义：

```yaml
# 模块 schema 示例
data:
  market:
    symbol: string            # required
    interval: string          # default: "1m"
    depth: int                # default: 20
  macro:
    providers: []string       # required
```text

---

## 12. Error Handling

| 错误 | 调用方处理 |
|------|-----------|
| `ErrInvalidFormat` | 检查文件格式和内容，修复后重试 |
| `ErrValidationFailed` | 检查错误列表中的具体字段，修复配置 |
| `ErrKeyNotFound` | 检查 key 拼写，确认已在 schema 中定义 |
| `ErrTypeMismatch` | 检查环境变量值类型是否匹配 schema |
| `ErrAlreadyLoaded` | 不要重复调用 Load，直接使用已加载的配置 |

**错误消息格式：** `"configx: <operation>: <detail>"`
**Validation 错误包含：** 字段路径 + 预期类型 + 实际值

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| 空配置文件 | 使用默认值 |
| 配置文件只有注释 | 使用默认值 |
| 环境变量值为空字符串 | 视为设置空值（非未设置） |
| 环境变量类型转换失败 | 返回 ErrTypeMismatch |
| 点分路径的中间节点不存在 | 自动创建中间节点 |
| 并发 Get + Watch | 需要加锁，保证并发安全 |
| schema 定义了 key 但文件中未提供且无默认值 | Validate 报错（required） |
| 超大配置文件（>10MB） | 正常解析，内存 < 文件大小 2x |

---

## 14. Directory Structure

```text
configx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── config.go               # Config 接口实现
├── reader.go               # Reader 接口实现
├── schema.go               # schema 定义与校验
├── merge.go                # 配置合并逻辑
├── env.go                  # 环境变量覆盖
├── watch.go                # 文件监控（可选）
├── options.go              # Option 模式
├── errors.go               # 公共错误变量
├── internal/
│   ├── yaml/               # YAML 解析器
│   ├── toml/               # TOML 解析器
│   ├── json/               # JSON 解析器
│   └── merge/              # 深度合并算法
├── testdata/
│   ├── config.yaml
│   ├── config.toml
│   ├── config.json
│   └── schema.json
├── example_test.go
└── integration_test.go
```text

---

## 15. Dependencies

### 15.1 go.mod

```text
module github.com/ZoneCNH/configx

go 1.23
```text

### 15.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| stdlib | observex, resiliencx, schedulex, testkitx |
| `gopkg.in/yaml.v3`（可选） | 所有业务域实现 |
| `github.com/pelletier/go-toml/v2`（可选） | `kernel`（foundationx exit 已完成，不再依赖） |
| `github.com/santhosh-tekuri/jsonschema/v5`（可选） | 所有存储/中间件扩展 |

---

## 16. Testing

### 16.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| YAML 加载 | 解析正确，支持嵌套结构 |
| TOML 加载 | 解析正确，支持嵌套结构 |
| JSON 加载 | 解析正确，支持嵌套结构 |
| 环境变量覆盖 | 正确覆盖对应 key |
| 类型转换 | string→int, string→bool, string→duration |
| schema 校验通过 | 返回 nil |
| schema 校验失败 | 返回所有违规字段 |
| 并发 Get | -race 测试通过 |
| Get 不存在的 key | 返回 nil（不 panic） |
| 重复 Load | 返回 ErrAlreadyLoaded |
| 空文件加载 | 使用默认值 |

### 16.2 Given/When/Then 用例

**TC-001: 文件 + 环境变量覆盖**
Given 默认值 `symbol=BTCUSDT`，文件中 `symbol=ETHUSDT`，环境变量 `APP_SYMBOL=SOLUSDT`
When 加载文件，应用环境变量覆盖
Then `Get("symbol")` 返回 `"SOLUSDT"`

**TC-002: schema 校验失败**
Given schema 要求 `symbol` 为 string 类型
When 配置中 `symbol=123`（int）
Then `Validate()` 返回包含 `symbol: expected string, got int` 的错误

**TC-003: 并发安全**
Given 已加载配置
When 100 个 goroutine 并发调用 `Get("symbol")`
Then 无 data race，所有返回值一致

**TC-004: Watch 配置监听**
Given 配置文件已加载并开启 Watch
When 文件内容变更且通过校验
Then Reader 读到新值并触发变更回调

**TC-005: Reader 只读视图**
Given 已创建配置 Reader
When 调用读取接口
Then 不能通过 Reader 修改底层配置


**TC-006: Load 文件不存在**
Given 调用 `Load("/nonexistent/config.yaml")`
When 文件不存在
Then 返回 `os.ErrNotExist`，配置不变

**TC-007: Load 文件格式无效**
Given 调用 `Load("invalid.yaml")` 且文件内容为非法 YAML 语法
When 解析失败
Then 返回 `ErrInvalidFormat`，配置不变

**TC-008: 敏感字段脱敏**
Given 配置包含 `db.password=secret123`
When 通过 Reader.GetString("db.password") 读取或输出到日志
Then 返回值/日志内容为 `"***"`，不包含原始密码

**TC-009: Release DoD 门禁**
Given 所有 Task 实现完成
When 运行 `go test -race -count=1 ./...` 和 `gitleaks detect --no-git`
Then 所有测试通过，零 data race，零 secret 泄露，覆盖率 ≥ 80%
Given 已创建配置 Reader
When 调用读取接口
Then 不能通过 Reader 修改底层配置

### 16.3 Benchmark

| 场景 | 目标 |
|------|------|
| 配置加载（1000 个 key） | < 50ms |
| Get 单次调用 | < 100ns |
| schema 校验（1000 个 key） | < 10ms |

### 16.4 集成测试

| 场景 | 验证点 |
|------|--------|
| 完整加载链 | 默认值 → 文件 → 环境变量 → 校验 → 读取 |
| 格式自动检测 | .yaml/.toml/.json 自动选择解析器 |
| 嵌套 key 访问 | `data.market.symbol` 正确访问 |

---

## 17. Performance Budget

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| 配置加载（1000 个 key） | < 50ms | benchmark test |
| Get 单次调用 | < 100ns | benchmark test |
| 并发 Get（100 goroutine） | 无显著退化 | benchmark test |
| 常驻内存 | < 5MB | profiling |

---

## 18. Observability

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `configx.load.duration` | histogram，配置加载耗时 |
| metric | `configx.validation.errors` | counter，校验错误数量 |
| metric | `configx.get.duration` | histogram，Get 调用耗时 |
| log | `configx.loaded` | info，配置加载完成，含文件路径和 key 数量 |
| log | `configx.env_override` | debug，环境变量覆盖了哪些 key |
| log | `configx.validation_failed` | warn，校验失败详情 |

---

## 19. Security

| 要求 | 实现方式 |
|------|----------|
| 敏感配置不写日志 | 日志中对密码、token 等字段脱敏（显示 `***`） |
| 配置文件权限检查 | 启动时检查文件权限，过宽则 warning |
| 环境变量不泄露 | 错误消息中不包含环境变量值 |

---

## 20. CI Gate

### 20.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` | 总覆盖率 < 80% |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment |

### 20.2 configx 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 不依赖 kernel | `go list -deps ./... \| grep "kernel"` | 依赖 kernel |

---

## 21. Upgrade Compatibility

| 变更类型 | 版本升级 |
|----------|----------|
| Reader 接口新增方法 | **minor**（实现需跟上） |
| Reader 接口删除/修改方法 | **major** |
| Config 接口变更 | **minor**（x.go 是唯一组装者） |
| 新增配置文件格式支持 | minor |
| 新增必填 schema 字段 | **minor**（带默认值） |

---

## 22. Release DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、配置说明、API 概览
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更（或已 bump major）
- [ ] 所有 Functional Requirements 有对应测试
- [ ] 所有 Edge Cases 有对应测试

---
---
## 24. Lifecycle

| 阶段 | 状态 | 说明 |
|------|------|------|
| 初始化 | `configx.New(opts...)` | 创建 Config 实例，应用 Option |
| 加载 | `Load(path)` | 解析配置文件，填充 data |
| 覆盖 | `WithEnvOverride(prefix)` | 环境变量覆盖配置键 |
| 校验 | `Validate()` | schema 校验，fail-fast |
| 运行 | `Reader.Get(key)` | 并发安全只读访问 |
| 关闭 | 进程退出 | 无资源需清理（无连接池/文件句柄） |

## 23. Open Questions

- 是否需要支持配置热更新（Watch 特性）？当前只支持启动时加载。
- 是否需要支持配置版本管理（记录每次配置变更）？
- 敏感配置（密码、token）是否需要内置加密支持？
- 是否需要支持配置模板（引用其他 key 的值）？
