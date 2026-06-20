# Go 语言编码规范

> 综合整合 **Google Go Style Guide**、**Effective Go**、**Go Code Review Comments** 及 **Uber Go Style Guide** 最佳实践。
> 核心目标：让代码**可读、一致且易于维护**。

---

## 目录

1. [代码风格与格式化](#1-代码风格与格式化)
2. [命名规范](#2-命名规范)
3. [注释规范](#3-注释规范)
4. [错误处理](#4-错误处理)
5. [并发编程](#5-并发编程)
6. [项目结构](#6-项目结构)
7. [测试规范](#7-测试规范)
8. [工具链](#8-工具链)
9. [参考资料](#9-参考资料)

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
| 常量 | `MixedCaps` | `MaxRetries`（不用全大写加下划线） |
| 函数/方法 | `MixedCaps`，动词或动词短语 | `GetUser`、`parseRequest` |
| 类型（结构体/接口） | `UpperCamelCase`，名词 | `UserService`、`OrderManager` |
| 单方法接口 | `-er` 后缀 | `Reader`、`Closer`、`Stringer` |

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

```go
// Bad
return fmt.Errorf("Read file failed.")

// Good
return fmt.Errorf("read config file: %w", err)
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

## 6. 项目结构

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

## 7. 测试规范

**目标**：通过测试保证代码质量，使代码易于重构。

### 文件与函数命名

- 测试文件以 `_test.go` 结尾。
- 测试函数以 `Test` 开头，如 `TestGetUser`。
- Benchmark 函数以 `Benchmark` 开头。

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

追求合理的测试覆盖率，一般以 **80%** 以上为目标。

```bash
go test ./... -cover
go test ./... -coverprofile=coverage.out
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

## 8. 工具链

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

## 9. 参考资料

| 文档 | 说明 |
|------|------|
| [Effective Go](https://go.dev/doc/effective_go) | Go 官方核心指南，理解 Go 语言习惯用法的基础 |
| [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments) | 代码审查常见问题清单，是 Effective Go 的补充 |
| [Google Go Style Guide](https://google.github.io/styleguide/go/guide) | Google 内部的 Go 风格指南，全面且深入 |
| [Uber Go Style Guide](https://github.com/uber-go/guide) | Uber 开源的风格指南，非常详细实用，有中文翻译 |
| [Standard Go Project Layout](https://github.com/golang-standards/project-layout) | 社区公认的项目目录布局规范 |

---

## 总结与核心原则

| 原则 | 说明 |
|------|------|
| **一致性** | 团队内部一旦选定标准，共同遵守，优先于个人偏好 |
| **简单性** | 能用简单方式实现的，不用复杂方式；从扁平结构开始 |
| **显式优于隐式** | 错误显式处理，依赖显式注入，生命周期显式管理 |
| **可读性** | 代码是写给人看的，命名清晰胜过注释详尽 |
