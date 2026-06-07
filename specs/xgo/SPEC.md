# x.go 完整规格

> Foundation 组合根。唯一知道所有模块具体实现的位置，只做组合，不含业务逻辑。

最后更新：2026-06-07

---

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-07
- Owner: ZoneCNH
- Layer: 组合根（Composition Root）
- Version: v0.1.0
- Repository: [github.com/ZoneCNH/x.go](https://github.com/ZoneCNH/x.go)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), [specs/kernel/SPEC.md](../kernel/SPEC.md)

---

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |

## 2. Summary

`x.go` 是 FoundationX 的组合根（Composition Root），负责读取配置、创建所有 L1 模块实例、组装依赖（Deps 结构体）、注册到 kernel 并启动应用。它是整个系统中唯一知道所有模块具体实现的地方。

---

## 3. Problem

FoundationX 由 70+ 个模块组成，每个模块通过接口解耦。但应用启动时需要有人知道所有模块的具体实现并把它们组装在一起。如果这个组装逻辑分散在各模块中，会导致：

- 模块间产生隐式依赖（通过具体类型而非接口）
- 无法独立测试单个模块
- 新增或替换模块时需要修改多处代码
- 依赖图不透明，难以审计

---

## 4. Goals

- 成为唯一知道所有模块具体实现的位置
- 读取配置，创建模块实例，组装 Deps 结构体
- 注册所有模块到 kernel，启动应用
- 通过配置控制哪些模块参与组装（可选模块）
- 保持自身代码简洁，不含业务逻辑

---

## 5. Non-goals

- 不含任何业务逻辑（交易、行情、风控、订单）
- 不含模块的实现细节
- 不做配置解析（→ configx）
- 不做生命周期管理（→ kernel）
- 不做日志、监控（→ observex）
- 不做模块间通信（→ contracts）
- 不做重试、熔断（→ resiliencx）

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| 运维/部署 | 编译 x.go 为可执行文件，部署到生产环境 |
| 开发者 | 本地开发时运行 x.go 启动完整应用 |
| CI/CD | 集成测试时编译 x.go 启动应用进行端到端验证 |

---

## 7. Functional Requirements

### FR-001: 读取配置

WHEN x.go 启动
THEN 通过 configx 加载配置文件，获取所有模块的配置

WHEN 配置文件不存在或格式错误
THEN 返回明确错误，不启动应用

### FR-002: 创建模块实例

WHEN 配置加载成功
THEN 根据配置创建所有 L1 模块的具体实例

WHEN 某模块配置缺失必填项
THEN 返回该模块的 ValidationError，不启动应用

WHEN 配置中标记某模块为 disabled
THEN 跳过该模块，不创建实例

### FR-003: 组装依赖

WHEN 所有模块实例创建完成
THEN 创建 Deps 结构体，注入 configx.Reader、observex.Logger、observex.Meter、observex.Tracer、resiliencx.Policies 等

WHEN 某依赖创建失败（如 observex 初始化失败）
THEN 返回错误，不启动应用

### FR-004: 注册到 kernel

WHEN Deps 组装完成
THEN 调用 `kernel.Register(m)` 注册每个模块

WHEN 注册时检测到重复模块名
THEN 返回 `ErrAlreadyRegistered`

### FR-005: 启动应用

WHEN 所有模块注册完成
THEN 调用 `kernel.Run(ctx)` 启动应用

WHEN 启动过程中某模块失败
THEN kernel 自动回滚，x.go 退出并返回错误

### FR-006: 优雅停机

WHEN 收到 SIGTERM 或 SIGINT
THEN 调用 `kernel.Shutdown(ctx)` 优雅停机

---

## 8. Business Rules

| 编号 | 规则 |
|------|------|
| BR-001 | x.go 是唯一 import 所有 L1 模块具体实现的文件 |
| BR-002 | x.go 不含任何业务逻辑，只做组合 |
| BR-003 | 模块实例化顺序不影响（kernel 负责拓扑排序） |
| BR-004 | 可选模块通过配置控制，不影响其他模块 |
| BR-005 | Deps 中的接口类型由 x.go 组装时注入 |
| BR-006 | x.go 不直接调用任何模块的业务方法 |

---

## 9. Interface Contract

### 9.1 x.go 的角色

x.go 不暴露公共接口，它是 `main` 包的入口点：

```go
package main

import (
    "context"
    "os"
    "os/signal"
    "syscall"

    "github.com/ZoneCNH/kernel"
    "github.com/ZoneCNH/configx"
    "github.com/ZoneCNH/observex"
    "github.com/ZoneCNH/resiliencx"
    // L1 运行时模块
    "github.com/ZoneCNH/alertx"
    "github.com/ZoneCNH/redisx"
    "github.com/ZoneCNH/kafkax"
    // L2.5 领域共享层
    "github.com/ZoneCNH/decimalx"
    "github.com/ZoneCNH/domain-market"
    // 业务域模块
    "github.com/ZoneCNH/market-data"
    "github.com/ZoneCNH/factor-engine"
    "github.com/ZoneCNH/risk-engine"
    "github.com/ZoneCNH/order-engine"
    // ...
)

func main() {
    // 1. 加载配置
    cfg, err := configx.Load("config.yaml")
    if err != nil { /* 处理错误 */ }

    // 2. 创建可观测实例
    logger := observex.NewLogger(cfg)
    meter := observex.NewMeter(cfg)
    tracer := observex.NewTracer(cfg)

    // 3. 创建弹性策略
    policies := resiliencx.NewPolicies(cfg)

    // 4. 组装 Deps
    deps := kernel.Deps{
        Config:    cfg,
        Logger:    logger,
        Meter:     meter,
        Tracer:    tracer,
        Resilient: policies,
    }

    // 5. 创建 App
    app := kernel.New()

    // 6. 注册模块
    app.Register(marketdata.New(deps))
    app.Register(factorengine.New(deps))
    app.Register(riskengine.New(deps))
    app.Register(orderengine.New(deps))
    // ...

    // 7. 启动
    ctx, cancel := signal.NotifyContext(context.Background(),
        syscall.SIGTERM, syscall.SIGINT)
    defer cancel()

    if err := app.Run(ctx); err != nil {
        os.Exit(1)
    }
}
```

---

## 10. Data Model

### 10.1 公共错误

x.go 本身不定义错误变量，使用 kernel 和各模块的错误。

### 10.2 配置结构

```yaml
# config.yaml 示例
app:
  name: "foundationx"
  environment: "production"

kernel:
  startup_timeout: 30s
  shutdown_timeout: 15s

modules:
  market_data:
    enabled: true
    # ... 模块特定配置
  factor_engine:
    enabled: true
  risk_engine:
    enabled: true
  order_engine:
    enabled: true
```

---

## 11. Config Schema

x.go 读取的配置由 configx 解析，x.go 本身不定义 schema。各模块的配置 schema 见各自 spec。

顶层结构：

```yaml
app:          # 应用级配置（name, environment）
kernel:       # kernel 配置（超时、健康检查）
modules:      # 各模块配置（按模块名组织）
```

---

## 12. Error Handling

| 错误 | 调用方处理 |
|------|-----------|
| 配置加载失败 | 打印错误，退出码 1 |
| 模块实例化失败 | 打印错误，退出码 1 |
| 依赖组装失败 | 打印错误，退出码 1 |
| kernel.Run 失败 | 打印错误，退出码 1 |

**错误传播：** x.go 不包装错误，直接使用各模块返回的错误。

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| 所有模块 disabled | kernel.Run 立即返回 nil，正常退出 |
| 配置文件为空 | configx 返回错误，x.go 退出 |
| 某模块 import 不存在 | 编译失败（Go 编译期检查） |
| 重复注册同一模块 | kernel 返回 ErrAlreadyRegistered |
| SIGTERM 在启动过程中收到 | kernel 中断启动，已启动模块被 Stop |

---

## 14. Directory Structure

```
x.go/
├── go.mod                  # 依赖所有 L1 模块
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── main.go                 # 入口点：配置加载 → 模块创建 → 组装 → 启动
├── deps.go                 # Deps 组装逻辑（可选，如果 main.go 太长）
├── modules.go              # 模块注册列表（可选）
├── config.yaml             # 默认配置文件
├── config.yaml.example     # 配置示例
├── testdata/
│   └── *.golden
└── main_test.go            # 集成测试
```

---

## 15. Dependencies

### 15.1 go.mod

```
module github.com/ZoneCNH/x.go

go 1.23

require (
    github.com/ZoneCNH/kernel v0.7.3
    github.com/ZoneCNH/configx v0.2.0
    github.com/ZoneCNH/observex v0.3.0
    github.com/ZoneCNH/resiliencx v0.1.0
    // L1 运行时模块
    github.com/ZoneCNH/alertx v0.1.0
    github.com/ZoneCNH/redisx v0.1.0
    // L2.5 领域共享层
    github.com/ZoneCNH/decimalx v0.1.0
    github.com/ZoneCNH/domain-market v0.1.0
    // 业务域模块
    github.com/ZoneCNH/market-data v0.1.0
    github.com/ZoneCNH/factor-engine v0.1.0
    github.com/ZoneCNH/risk-engine v0.1.0
    github.com/ZoneCNH/order-engine v0.1.0
    // ...
)
```

### 15.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| 所有 L1 模块的具体实现 | 无（x.go 是组合根，可以依赖一切） |
| 所有 L2.5 领域共享层 | |
| 所有业务域模块 | |
| kernel, configx, observex, resiliencx | |

### 15.3 特殊说明

x.go 是整个系统中唯一允许 import 所有模块具体实现的包。其他模块只能通过 `contracts` 包的接口进行跨域通信。

---

## 16. Testing

### 16.1 单元测试

x.go 作为 `main` 包，不适合传统单元测试。测试重点在集成测试。

### 16.2 Given/When/Then 用例

**TC-001: 正常启动和停机**
Given 配置文件就绪，所有模块 enabled
When 运行 x.go
Then 所有模块启动成功，收到 SIGTERM 后优雅停机

**TC-002: 配置缺失**
Given 配置文件不存在
When 运行 x.go
Then 退出码 1，输出配置加载错误

**TC-003: 模块 disabled**
Given 配置中 market_data.enabled = false
When 运行 x.go
Then market-data 模块不注册，其他模块正常启动

**TC-004: Health 健康聚合**
Given 多个模块已启动
When 调用健康检查入口
Then 返回每个模块的健康状态和整体状态

**TC-005: Signal 信号处理**
Given x.go 正在运行
When 收到 SIGTERM
Then 触发优雅停机并返回退出码 0

**TC-006: Config 配置加载**
Given 配置文件包含模块 enabled 开关
When 启动 x.go
Then 按配置装配模块且配置错误时 fail-fast

### 16.3 Benchmark

| 场景 | 目标 |
|------|------|
| 完整启动（不含业务模块实际初始化） | < 2s |

### 16.4 集成测试

| 场景 | 验证点 |
|------|--------|
| 完整启动-运行-停机 | 所有模块 Running → SIGTERM → 所有 Stopped |
| 启动失败回滚 | 某模块 Start 失败 → 已启动模块被 Stop |

---

## 17. Performance Budget

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| 应用启动（不含业务模块实际连接） | < 2s | 集成测试 |
| 优雅停机（无阻塞模块） | < 5s | 集成测试 |

---

## 18. Observability

x.go 本身不产生 metric/log/span，通过 observex 初始化的 logger/meter/tracer 传递给各模块。

| 类型 | 名称 | 说明 |
|------|------|------|
| log | `xgo.starting` | info，应用开始启动 |
| log | `xgo.started` | info，应用启动完成 |
| log | `xgo.shutdown` | info，应用开始停机 |
| log | `xgo.startup_failed` | error，启动失败，含错误详情 |

---

## 19. Security

| 要求 | 实现方式 |
|------|----------|
| 配置中的敏感值不打印 | configx.SecretString 脱敏 |
| 启动错误不泄露配置细节 | 错误消息只包含模块名和错误类型 |

---

## 20. CI Gate

### 20.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |

### 20.2 x.go 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 无业务逻辑 | 人工审查 main.go 不含业务判断 | main.go 包含业务逻辑 |
| 依赖完整性 | 检查所有 enabled 模块是否已 import | 缺失模块 import |

---

## 21. Upgrade Compatibility

| 变更类型 | 版本升级 |
|----------|----------|
| 新增模块 | patch |
| 移除模块 | **minor**（影响部署配置时升为 major） |
| 修改配置结构 | **minor**（带默认值）或 **major**（破坏性） |
| 修改 Go 版本 | **minor** |

---

## 22. Release DoD

- [ ] main.go 无业务逻辑
- [ ] 所有 enabled 模块已 import 并注册
- [ ] 配置文件示例完整
- [ ] README.md 包含：模块定位、启动说明、配置说明
- [ ] CHANGELOG.md 已更新
- [ ] 集成测试通过
- [ ] Secret 扫描通过
- [ ] 依赖图无环（kernel 保证）

---

## 23. Open Questions

- 是否需要支持插件式模块加载（通过配置动态加载 .so）？
- 是否需要支持多环境配置覆盖（dev/staging/prod）？
- 是否需要在 x.go 中实现模块级别的 feature flag？
