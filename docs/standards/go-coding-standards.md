# Go 语言编码规范

> 综合整合 **Google Go Style Guide**、**Effective Go**、**Go Code Review Comments** 及 **Uber Go Style Guide** 最佳实践。
> 核心目标：让代码**可读、一致且易于维护**。

> **效力层级**：`CONSTITUTION.md` > 本文档 > 社区最佳实践。
> 文中标注 **FoundationX 强制** 的规则来源于 `CONSTITUTION.md`，具有最高优先级；
> 标注 **FoundationX 补充** 的规则是项目特定扩展，与通用 Go 惯例有细微差异。

---

## 目录

1. [代码风格与格式化](#1-代码风格与格式化)
2. [命名规范](#2-命名规范)
3. [注释规范](#3-注释规范)
4. [错误处理](#4-错误处理)
5. [并发编程](#5-并发编程)
6. [接口设计](#6-接口设计)
7. [性能规范](#7-性能规范)
8. [日志规范](#8-日志规范)
9. [泛型使用](#9-泛型使用)
10. [项目结构](#10-项目结构)
11. [测试规范](#11-测试规范)
12. [工具链](#12-工具链)
13. [参考资料](#13-参考资料)
14. [AI 协作 Checkpoint](#14-ai-协作-checkpoint)

---

## 1. 代码风格与格式化

**目标**：统一代码格式，消除风格争议，是规范的基石。

### 强制格式化

所有 Go 代码必须使用 `gofmt` 进行格式化。强烈建议使用 `goimports`，它在 `gofmt` 基础上还能自动管理导入包的增删和排序。

### 行长度与文件大小

| 维度 | 建议上限 |
|------|---------|
| 每行字符数 | **120 个字符** |
| 单文件行数 | **800 行** |
| 单函数行数 | **80 行** |

超过部分应合理拆分或换行。

### 缩进与空格

- 使用 **Tab** 进行缩进（`gofmt` 自动处理）。
- 运算符和操作数之间建议留空格。

### Import 分组与排序

导入语句按逻辑分组，组内按字母顺序排列，各组间用空行分隔。

推荐顺序：**标准库 → 第三方库 → 公司内部库 → 项目内部包**。

```go
import (
    // 标准库
    "context"
    "fmt"
    "time"

    // 第三方库
    "github.com/spf13/viper"
    "go.uber.org/zap"

    // 公司内部库
    "github.com/your-company/pkg/logger"

    // 项目内部包
    "myproject/internal/model"
)
```

### 声明与初始化

- 相关声明（`import`、`const`、`var`、`type`）使用分组语法。
- 函数外部必须使用 `var` 关键字声明。
- 初始化结构体推荐使用 `&T{}` 而非 `new(T)`。
- 创建 `slice` 或 `map` 时，尽量指定容量以预先分配内存，提升性能。

```go
// 推荐：预分配容量
s := make([]int, 0, 100)
m := make(map[string]int, 50)
```

---

## 2. 命名规范

**目标**：让命名清晰、简洁且能表达意图。

### 包名

- 使用**全小写**的单个单词，不使用下划线或驼峰。
- 应简短且包含上下文信息。
- 避免使用 `util`、`common`、`helper` 等泛化名称。

### 文件命名

- 使用**全小写**，单词间用下划线分隔，如 `user_service.go`。
- 测试文件以 `_test.go` 结尾。

### 标识符可见性

| 风格 | 说明 |
|------|------|
| `UpperCamelCase` | **导出（Exported）**，可被其他包访问 |
| `lowerCamelCase` | **不导出（Unexported）**，仅包内私有 |

### 各类标识符命名

| 类型 | 风格 | 示例 |
|------|------|------|
| 变量 | `lowerCamelCase` | `userName`，循环变量用 `i`、`j` |
| 常量 | `MixedCaps` 为主 | `MaxRetries`、`DefaultTimeout` |
| Topic / 事件通道常量 | `UPPER_SNAKE` 或 `PascalCase` | `TopicMarketData`、`TOPIC_MARKET_DATA` |
| 函数/方法 | `MixedCaps`，动词或动词短语 | `GetUser`、`parseRequest` |
| 类型（结构体/接口） | `UpperCamelCase`，名词 | `UserService`、`OrderManager` |
| 单方法接口 | `-er` 后缀 | `Reader`、`Closer`、`Stringer` |

> **FoundationX 补充（来自 CONSTITUTION.md §7.1）**：项目中 Topic 类常量允许使用 `UPPER_SNAKE`（如 `TOPIC_MARKET_DATA`）或 `PascalCase`（如 `TopicMarketData`），两种形式均合法，同一模块内保持一致即可。

### 接收器

使用 1-2 个字母的缩写，在类型的所有方法中保持一致。

```go
func (u *User) Name() string { return u.name }
func (u *User) SetName(name string) { u.name = name }
```

### Getter / Setter

Go 不推荐使用 `Get` 前缀。字段 `Name` 的 Getter 应命名为 `Name()` 而非 `GetName()`。

### 缩略词

保持大小写一致：

```go
// 正确
HTTPServer
urlParser
userID
serverURL

// 错误
HttpServer
UrlParser
userId
serverUrl
```

---

## 3. 注释规范

**目标**：使注释能有效生成文档，提高代码可读性。

### 导出声明必须注释

所有导出的包、函数、类型、变量、常量都必须有注释。

### 注释格式

注释应是以被声明对象名称开头的**完整句子**，并以句号结尾。

```go
// Package user provides utilities for user management and authentication.
package user

// User represents a registered user in the system.
type User struct {
    // ID is the unique identifier of the user.
    ID int64
    // Name is the display name of the user.
    Name string
}

// GetByID retrieves a user by their unique identifier.
// It returns ErrNotFound if the user does not exist.
func GetByID(ctx context.Context, id int64) (*User, error) {
    // ...
}
```

### TODO / FIXME

使用标准格式，便于工具识别：

```go
// TODO(username): 优化查询性能
// FIXME: 此处存在竞态条件，待修复
```

---

## 4. 错误处理

**目标**：编写健壮、可预测的代码，优雅地处理异常情况。

### 显式处理错误

永远**不要**使用 `_` 忽略错误返回值。

```go
// Bad
data, _ := os.ReadFile("file.txt")

// Good
data, err := os.ReadFile("file.txt")
if err != nil {
    return fmt.Errorf("read file failed: %w", err)
}
```

### 错误信息格式

- 错误信息应为**全小写**。
- **不以标点符号结尾**。
- 使用 `%w` 包装错误以保留调用链。
- **FoundationX 补充（来自 CONSTITUTION.md §8.2）**：错误信息须包含模块名前缀，格式为 `"module: operation context"`。

```go
// Bad
return fmt.Errorf("Read file failed.")
return fmt.Errorf("read config file: %w", err)  // 缺少模块名前缀

// Good（含模块名前缀）
return fmt.Errorf("redisx: get %q: %w", key, err)
return fmt.Errorf("configx: load file %s: %w", path, err)
```

### 错误处理顺序

保持快速返回（early return）风格，避免深层嵌套。

```go
// Bad：深层嵌套
func process(data []byte) error {
    if data != nil {
        if len(data) > 0 {
            // 处理逻辑...
        }
    }
    return nil
}

// Good：快速返回
func process(data []byte) error {
    if data == nil || len(data) == 0 {
        return errors.New("data is empty")
    }
    // 处理逻辑...
    return nil
}
```

### 自定义错误类型

对于复杂的错误场景，定义自定义错误类型以提供更多上下文。

```go
type NotFoundError struct {
    Resource string
    ID       int64
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s with id %d not found", e.Resource, e.ID)
}
```

### Panic 使用原则

- **不要**在业务逻辑中使用 `panic`，只在程序初始化阶段（如配置加载失败）使用。
- 如果使用了 `recover`，必须在 `defer` 中调用，并记录日志。

---

## 5. 并发编程

**目标**：安全地使用并发原语，避免常见的并发陷阱。

### Context 传递

`context.Context` 作为函数的**第一个参数**传递，**不要**将其存储为结构体字段。

```go
// Bad
type Client struct {
    ctx context.Context
}

// Good
func (c *Client) DoSomething(ctx context.Context, arg string) error {
    // ...
}
```

### Goroutine 管理

启动 goroutine 前，必须清楚它**如何退出**。

```go
// 使用 sync.WaitGroup 等待完成
var wg sync.WaitGroup
wg.Add(1)
go func() {
    defer wg.Done()
    // 工作逻辑...
}()
wg.Wait()
```

推荐使用 `golang.org/x/sync/errgroup` 管理一组 goroutine 的生命周期和错误处理。

```go
g, ctx := errgroup.WithContext(ctx)
g.Go(func() error {
    return fetchData(ctx)
})
g.Go(func() error {
    return processData(ctx)
})
if err := g.Wait(); err != nil {
    return err
}
```

### 数据竞争防护

多个 goroutine 访问同一变量时，必须使用同步机制。零值的 `sync.Mutex` 可直接使用。

```go
type SafeCounter struct {
    mu    sync.Mutex
    count int
}

func (c *SafeCounter) Inc() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.count++
}
```

### Channel 使用原则

- 优先使用 channel 在 goroutine 间通信：**通过通信共享内存，而非通过共享内存通信**。
- 明确 channel 的所有者（生产者负责关闭 channel）。
- 使用 `select` + `context` 处理超时和取消。

```go
select {
case result := <-ch:
    // 处理结果
case <-ctx.Done():
    return ctx.Err()
}
```

---

## 6. 接口设计

**目标**：设计小而专注的接口，提升可组合性和可测试性。

### 小接口原则

接口应尽量小，只包含必要的方法。`io.Reader`（1 个方法）优于臃肿的大接口。

> **FoundationX 强制（来自 CONSTITUTION.md §4.1）**：每个接口 **3-5 个方法**，最多不超过 **7 个方法**。

```go
// Bad：大接口难以实现和测试
type UserRepository interface {
    GetByID(ctx context.Context, id int64) (*User, error)
    Create(ctx context.Context, user *User) error
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id int64) error
    List(ctx context.Context, filter Filter) ([]*User, error)
    Count(ctx context.Context, filter Filter) (int, error)
}

// Good：按使用方需求拆分
type UserReader interface {
    GetByID(ctx context.Context, id int64) (*User, error)
}

type UserWriter interface {
    Create(ctx context.Context, user *User) error
    Update(ctx context.Context, user *User) error
}
```

### 接口在消费方定义

接口应由**使用方**定义，而非由实现方提前声明。这是 Go 最重要的设计哲学之一。

```go
// Bad：实现方提前定义接口（通常放在 service 包）
// service/user.go
type UserService interface { ... }
type userServiceImpl struct { ... }

// Good：消费方按需定义所需接口
// handler/user.go
type userFetcher interface {
    GetByID(ctx context.Context, id int64) (*User, error)
}

type UserHandler struct {
    fetcher userFetcher
}
```

### 不要提前抽象

只有在出现**第二个实现**（或需要 mock 测试）时，才提取接口。不要为"将来可能有多实现"而提前定义接口。

### 接口组合

利用 Go 接口嵌入实现接口组合：

```go
type ReadWriter interface {
    io.Reader
    io.Writer
}
```

### 编译期接口检查

**FoundationX 强制（来自 CONSTITUTION.md §4.1）**：所有接口实现必须添加编译期断言，确保类型实现了目标接口，避免运行时才发现遗漏。

```go
// 在接口实现的 .go 文件顶部添加
var _ UserReader = (*userRepository)(nil)
var _ UserWriter = (*userRepository)(nil)
```

### 跨域 DTO 不可变

**FoundationX 强制（来自 CONSTITUTION.md §4.1）**：跨域传输对象（DTO）字段只读，**不提供 setter 方法**。消费方应通过构造函数或 Builder 创建，而非逐字段修改。

```go
// Bad：提供 setter 导致 DTO 可变
type OrderDTO struct { ID int64 }
func (d *OrderDTO) SetID(id int64) { d.ID = id }

// Good：只读字段，通过构造函数创建
type OrderDTO struct {
    ID     int64
    Symbol string
}
func NewOrderDTO(id int64, symbol string) OrderDTO {
    return OrderDTO{ID: id, Symbol: symbol}
}
```

### 返回具体类型，接受接口

函数参数接受接口（灵活），函数返回值优先返回具体类型（避免隐藏信息）。

```go
// 参数用接口，便于 mock
func Process(r io.Reader) error { ... }

// 返回具体类型，调用方可以获得完整信息
func NewUserService(db *sql.DB) *UserService { ... }
```

---

## 7. 性能规范

**目标**：避免常见的性能陷阱，在关键路径上编写高效代码。

### 字符串拼接

多次拼接字符串时使用 `strings.Builder`，避免大量内存分配。

```go
// Bad：每次 + 都会分配新内存
var s string
for _, word := range words {
    s += word + " "
}

// Good：Builder 复用底层缓冲区
var b strings.Builder
b.Grow(estimatedLen) // 预分配容量
for _, word := range words {
    b.WriteString(word)
    b.WriteByte(' ')
}
result := b.String()
```

### defer 的性能影响

`defer` 有一定运行时开销（约 30-100ns/次）。在**热路径**（高频调用的函数）中，如果函数极短，考虑显式调用替代 `defer`。

```go
// 非热路径：defer 是推荐写法，确保资源释放
func readConfig(path string) ([]byte, error) {
    f, err := os.Open(path)
    if err != nil {
        return nil, err
    }
    defer f.Close()
    return io.ReadAll(f)
}
```

### defer 在循环中的陷阱

**不要**在循环中使用 `defer`，文件句柄会等到函数返回时才释放。

```go
// Bad：所有文件在函数返回前都不会关闭
for _, path := range paths {
    f, _ := os.Open(path)
    defer f.Close() // 危险！
    process(f)
}

// Good：用闭包或辅助函数包裹
for _, path := range paths {
    func() {
        f, err := os.Open(path)
        if err != nil { return }
        defer f.Close()
        process(f)
    }()
}
```

### nil slice vs empty slice

`nil` slice 和空 slice 在大多数情况下行为相同，但 JSON 序列化结果不同。

```go
var s1 []int         // nil slice：json 序列化为 null
s2 := []int{}        // empty slice：json 序列化为 []
s3 := make([]int, 0) // empty slice：json 序列化为 []

// 函数返回时，无数据返回 nil，有数据但空返回 empty
func getItems() []Item {
    if noData {
        return nil      // 明确表示无数据
    }
    return []Item{}     // 表示有操作但结果为空
}
```

### 避免 slice 内存泄漏

对大 slice 取子切片时，底层数组不会被 GC 回收。

```go
// Bad：data 底层大数组一直存活
func getFirst100(data []byte) []byte {
    return data[:100]
}

// Good：copy 出新 slice，释放原始数据
func getFirst100(data []byte) []byte {
    result := make([]byte, 100)
    copy(result, data[:100])
    return result
}
```

### map 的零值陷阱

未初始化的 map 写入会 panic，读取返回零值。

```go
// Bad：写入 nil map 会 panic
var m map[string]int
m["key"] = 1 // panic: assignment to entry in nil map

// Good
m := make(map[string]int)
m["key"] = 1
```

---

## 8. 日志规范

**目标**：统一日志格式，便于机器解析和问题排查。

### 使用结构化日志

禁止在生产代码中使用 `fmt.Println` 或 `log.Printf` 打印日志。使用结构化日志库（推荐 `go.uber.org/zap` 或 Go 1.21+ 内置的 `log/slog`）。

```go
// Bad
fmt.Println("user login:", userID)
log.Printf("request failed: %v", err)

// Good（使用 zap）
logger.Info("user login", zap.Int64("user_id", userID))
logger.Error("request failed", zap.Error(err), zap.String("method", "POST"))

// Good（使用 slog，Go 1.21+）
slog.Info("user login", "user_id", userID)
slog.Error("request failed", "err", err, "method", "POST")
```

### 日志级别

| 级别 | 使用场景 |
|------|---------|
| `Debug` | 开发调试信息，生产环境关闭 |
| `Info` | 关键业务事件（启动、登录、订单创建）|
| `Warn` | 可恢复的异常（重试、降级、配置缺失）|
| `Error` | 需要关注的错误，但程序仍可继续 |
| `Fatal` | 不可恢复的错误，调用后程序退出 |

### 日志内容规范

- **不要**在日志中打印密码、Token、信用卡号等敏感信息。
- 错误日志必须包含足够的上下文（请求 ID、用户 ID、关键参数）。
- 使用 `logger.With(...)` 创建带上下文的子 logger，避免每条日志重复传字段。
- **FoundationX 强制（来自 CONSTITUTION.md §6.4）**：敏感字段必须使用 `observex.Redactor` 处理，禁止直接打印 API key、token、密码明文。

```go
// Bad：直接打印敏感字段
logger.Info("connecting", zap.String("api_key", apiKey))

// Good：使用 Redactor 脱敏
logger.Info("connecting", zap.String("api_key", observex.Redact(apiKey)))
```

```go
// 在请求处理开始时创建带上下文的 logger
reqLogger := logger.With(
    zap.String("request_id", requestID),
    zap.Int64("user_id", userID),
)
// 后续调用 reqLogger，无需重复传字段
reqLogger.Info("processing order")
reqLogger.Error("payment failed", zap.Error(err))
```

### 日志初始化

logger 应在应用入口初始化一次，通过参数或依赖注入传递，**不要**使用全局变量。

---

## 9. 泛型使用

**目标**：在合适的场景使用泛型减少重复代码，避免过度使用。

> 适用于 Go 1.18+

### 何时使用泛型

- 实现通用数据结构（栈、队列、集合）。
- 编写对多种类型执行相同操作的工具函数（`Map`、`Filter`、`Reduce`）。
- 减少相同逻辑对不同数值类型的重复实现。

```go
// 不用泛型：需要为每种类型写一遍
func SumInts(nums []int) int { ... }
func SumFloat64s(nums []float64) float64 { ... }

// 使用泛型：一次实现，多类型复用
func Sum[T int | int64 | float64](nums []T) T {
    var total T
    for _, n := range nums {
        total += n
    }
    return total
}
```

### 使用约束（Constraints）

通过 `constraints` 包或自定义约束限制类型参数范围：

```go
import "golang.org/x/exp/constraints"

func Min[T constraints.Ordered](a, b T) T {
    if a < b {
        return a
    }
    return b
}
```

### 何时不使用泛型

- **不要**为了"可能将来复用"而提前泛化。
- 如果接口（`interface{}`/`any`）已经够用，不必引入泛型。
- 泛型不适合替代 `interface` 来实现多态行为（方法分派仍用接口）。
- 避免过度嵌套的泛型约束，会显著降低可读性。

```go
// Bad：过度泛化，可读性差
func Process[T interface{ Validate() error; Save() error }](items []T) error

// Good：直接用接口
type Processor interface {
    Validate() error
    Save() error
}
func Process(items []Processor) error
```

---

## 10. 项目结构

**目标**：使项目组织清晰，便于理解和维护。

### 推荐目录布局

遵循社区公认的 [Standard Go Project Layout](https://github.com/golang-standards/project-layout)。

```
myproject/
├── cmd/                  # 可执行文件入口（每个子目录对应一个二进制）
│   └── server/
│       └── main.go
├── internal/             # 私有代码，外部项目无法导入
│   ├── handler/
│   ├── service/
│   └── repository/
├── pkg/                  # 公共库代码，可被外部项目导入
├── api/                  # API 协议定义（OpenAPI、proto 文件等）
├── configs/              # 配置文件模板
├── scripts/              # 脚本（构建、部署、代码生成等）
├── docs/                 # 文档
├── go.mod
└── go.sum
```

### 避免过度设计

- 从**扁平**结构开始，只在必要时增加目录层级。
- 不要为了结构而结构，优先保持简单。

### internal 包的使用

将不打算对外暴露的代码放入 `internal/`，Go 编译器会强制执行访问限制。

---

## 11. 测试规范

**目标**：通过测试保证代码质量，使代码易于重构。

### 文件与函数命名

- 测试文件以 `_test.go` 结尾。
- 测试函数以 `Test` 开头，简单场景用 `TestFunctionName`，多场景用 `TestFunctionName_Scenario_ExpectedBehavior`。
- Benchmark 函数以 `Benchmark` 开头。

**FoundationX 强制（来自 CONSTITUTION.md §5.3）**：测试命名须遵循三段式格式：

```go
func TestGetByID_NotFound_ReturnsError(t *testing.T) {
    // Arrange — 准备测试数据
    // Act      — 执行被测函数
    // Assert   — 验证结果
}

func TestGetByID_ValidID_ReturnsUser(t *testing.T) { ... }
func TestConnect_Timeout_ReturnsTimeoutError(t *testing.T) { ... }
```

### 表驱动测试

对于有多种输入输出的函数，优先使用**表驱动测试**，使测试用例清晰、易于扩展。

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"正数相加", 1, 2, 3},
        {"含零值", 0, 5, 5},
        {"负数相加", -1, -2, -3},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.expected {
                t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.expected)
            }
        })
    }
}
```

### Mock 与依赖注入

- 对外部依赖（数据库、HTTP、消息队列）使用接口抽象。
- 使用 `gomock` 或 `testify/mock` 生成 Mock 对象。
- 通过依赖注入传入依赖，便于测试替换。

### 测试覆盖率

**FoundationX 强制（来自 CONSTITUTION.md §5.1）**：覆盖率按模块层级要求：

| 模块类型 | 最低覆盖率 | 说明 |
|---------|-----------|------|
| L0（kernel） | **100%** | 原语层必须高度可靠，零遗漏 |
| L1 运行时 | **80%** | 标准覆盖率 |
| 存储扩展 | **80%** | 单元测试 + 可选集成测试 |
| 通用项目 | **80%** | 一般工程最低目标 |

竞态测试必须始终运行且通过：

```bash
go test ./... -cover
go test ./... -race -coverprofile=coverage.out
go tool cover -html=coverage.out
```

### 测试辅助函数

使用 `t.Helper()` 标记测试辅助函数，使错误报告指向正确的调用位置。

```go
func assertEqual(t *testing.T, got, want int) {
    t.Helper()
    if got != want {
        t.Errorf("got %d, want %d", got, want)
    }
}
```

---

## 12. 工具链

**目标**：利用自动化工具保证代码质量。

| 工具 | 用途 | 说明 |
|------|------|------|
| `gofmt` | 代码格式化 | 强制执行，提交前必须运行 |
| `goimports` | 格式化 + import 管理 | 推荐替代 `gofmt` |
| `golangci-lint` | 综合静态分析 | 集成数十个 linter，CI 必备 |
| `go test` | 单元测试 | 配合 `-race` 检测数据竞争 |
| `go vet` | 代码静态检查 | 检查常见错误模式 |
| `go mod` | 依赖管理 | 定期运行 `go mod tidy` |

### 推荐 golangci-lint 配置

```yaml
# .golangci.yml
linters:
  enable:
    - errcheck       # 检查未处理的错误
    - gosimple       # 简化代码建议
    - govet          # 静态分析
    - ineffassign    # 检查无效赋值
    - staticcheck    # 综合静态检查
    - goimports      # import 排序
    - revive         # 代码风格检查
    - gocyclo        # 圈复杂度检查

linters-settings:
  gocyclo:
    min-complexity: 15
```

### CI 集成建议

```yaml
# GitHub Actions 示例
- name: Run linter
  uses: golangci/golangci-lint-action@v3
  with:
    version: latest

- name: Run tests
  run: go test -race -coverprofile=coverage.out ./...
```

---

## 13. 参考资料

| 文档 | 说明 |
|------|------|
| [Effective Go](https://go.dev/doc/effective_go) | Go 官方核心指南，理解 Go 语言习惯用法的基础 |
| [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments) | 代码审查常见问题清单，是 Effective Go 的补充 |
| [Google Go Style Guide](https://google.github.io/styleguide/go/guide) | Google 内部的 Go 风格指南，全面且深入 |
| [Uber Go Style Guide](https://github.com/uber-go/guide) | Uber 开源的风格指南，非常详细实用，有中文翻译 |
| [Standard Go Project Layout](https://github.com/golang-standards/project-layout) | 社区公认的项目目录布局规范 |

---

## 14. AI 协作 Checkpoint

**目标**：在 AI 辅助编码（Vibe Coding）场景下，用分阶段 Checkpoint 拦截"能编译通过却在运行时 Panic、死锁或数据竞争"的代码。

> Go 没有 Rust 的所有权与借用检查兜底，且并发原语使用频繁，AI 代码更易通过编译却在运行时崩溃。本节为 AI 协作场景的补充流程规范，与 §5（并发）、§6（接口）、§11（测试）、§12（工具链）配合使用，不重复其中的编码细则。

### 14.1 质量层：工具链三连

每次接受 AI 生成代码后，必须依次执行以下三项作为 Accept Checkpoint：

| 顺序 | 命令 | 作用 |
|------|------|------|
| 1 | `go build ./...` | 基础编译检查 |
| 2 | `go vet ./...` | 拦截低级逻辑错误（Printf 格式错误、不可达代码、锁拷贝等）|
| 3 | `go test -race ./...` | **最关键**：检测数据竞争 |

> **FoundationX 强制（来自 CONSTITUTION.md §5.1）**：`-race` 为必选项。量化系统并发密度高，AI 误用 goroutine、channel 或全局变量产生的数据竞争只能由 race detector 暴露，禁止以"测试变慢"为由省略。

```bash
go build ./... && go vet ./... && go test -race ./...
```

### 14.2 设计层：接口先行（契约 Checkpoint）

让 AI 先定义 `interface`，经人工确认契约合理后再编写 `struct` 实现。Go 接口为隐式实现，AI 在编写实现时易偏离预期；接口定义即架构 Checkpoint，防止实现细节失控导致后期无法重构。

```text
1. AI 定义 interface（如 MarketDataFeed、OrderRouter）
2. 人工审查契约：方法集、参数、返回值、context 传递
3. 确认后 AI 编写 struct 实现
4. 补编译期断言（见 §6 编译期接口检查）
```

### 14.3 规范层：Lint 与 Git 回滚

| 手段 | Checkpoint 作用 |
|------|----------------|
| `golangci-lint` | 拦截不符合 Idiomatic Go 的代码（错误处理嵌套过深、未处理 `err`、命名不规范等）|
| Git 小步提交 | 每通过一次 Checkpoint 即提交一个逻辑单元；一旦 Lint 或 race 测试报错且 AI 修复陷入循环，立即回滚到上一个绿色提交 |

```bash
# 回滚到上一个通过全部检查的提交
git reset --hard <last-green-commit>
```

### 14.4 业务层：Context 与状态落盘

**Context 传递检查**：AI 生成的所有网络请求与长耗时任务必须正确接收并传递 `context.Context`，这是优雅退出与防资源泄漏的 Checkpoint。

- `ctx context.Context` 必须为函数首参，并向下传递到所有子调用。
- 在 `select` 中监听 `ctx.Done()`，禁止将 `ctx` 存入结构体字段（见 §5）。

**状态落盘**：策略运行中定时将内存状态（持仓、订单）序列化落盘，防止 Panic 导致内存数据全丢。

```go
// 定时快照：用 encoding/gob 或 json 序列化到 Redis / 本地文件
type PositionSnapshot struct {
    Positions map[string]Position
    Orders    []Order
    UpdatedAt time.Time
}

func (s *Store) Snapshot(ctx context.Context) error {
    snap := s.buildSnapshot()
    data, err := json.Marshal(snap)
    if err != nil {
        return fmt.Errorf("strategy: marshal snapshot: %w", err)
    }
    return s.sink.Save(ctx, data)
}
```

> 错误信息须含模块名前缀（见 §4）；Context 传递规范见 §5。

### 14.5 流程小结

```text
AI 写代码 → go vet && go test -race → golangci-lint → git commit
                ↑                          │
                └─── 报错且修复循环 ──→ git reset --hard 回滚
```

- `interface` 是设计 Checkpoint，`go test -race` 是安全 Checkpoint。
- 永远不盲信 AI 生成的 goroutine 并发代码，必须经 `-race` 验证。
- 小步提交，保留可回滚的绿色锚点。

---

## 总结与核心原则

| 原则 | 说明 |
|------|------|
| **一致性** | 团队内部一旦选定标准，共同遵守，优先于个人偏好 |
| **简单性** | 能用简单方式实现的，不用复杂方式；从扁平结构开始 |
| **显式优于隐式** | 错误显式处理，依赖显式注入，生命周期显式管理 |
| **可读性** | 代码是写给人看的，命名清晰胜过注释详尽 |
