# kernel 完整规格

> Foundation L0 原语层。stdlib-only，不依赖任何 Foundation L1 模块。

最后更新：2026-06-07

---

## 1. 定位

`kernel` 是应用的运行时骨架，负责把模块组织成一个可启动、可停止、可观测、可验证的应用。

### 核心职责

- `App` / `Module` / `Lifecycle` 抽象
- 模块注册、依赖声明和依赖图校验
- 启动顺序、停止顺序和优雅退出
- readiness / liveness / health 状态
- 启动失败、停止失败、panic 的处理规则
- context 传递和 cancellation
- 与 `configx`、`observex`、`resiliencx`、`schedulex` 的标准集成点

### 明确不做

- 不做配置解析细节
- 不做日志实现
- 不做重试策略
- 不放交易、行情、风控、订单逻辑
- 不做存储、网络、业务 DTO

---

## 2. 接口契约

### 2.1 Module / App / Lifecycle

```go
type Module interface {
    Name() string
    Init(ctx context.Context, deps Deps) error
    Start(ctx context.Context) error
    Stop(ctx context.Context) error
    Health() HealthStatus
}

type Deps struct {
    Config    configx.Reader
    Logger    observex.Logger
    Meter     observex.Meter
    Tracer    observex.Tracer
    Resilient *resiliencx.Policies
    Scheduler schedulex.Scheduler
}

type HealthStatus struct {
    Ready   bool
    Live    bool
    Message string
}

type App interface {
    Register(m Module) error
    Run(ctx context.Context) error
    Shutdown(ctx context.Context) error
    ModuleHealth(name string) HealthStatus
    DependencyGraph() graph.DirectedGraph
}
```

### 2.2 契约约束

- `Register` 后必须校验依赖图，循环依赖返回 `ErrCycleDetected`
- `Run` 按拓扑序启动，`Shutdown` 按反序停止
- `Init` 失败的模块不能进入 `Start`
- `Health()` 是幂等的、无副作用的
- `Stop` 超时后 force shutdown，记录未完成模块

### 2.3 公共错误

```go
var (
    ErrCycleDetected    = errors.New("kernel: dependency cycle detected")
    ErrModuleNotFound   = errors.New("kernel: module not found")
    ErrAlreadyRegistered = errors.New("kernel: module already registered")
    ErrStartupFailed    = errors.New("kernel: startup failed")
    ErrShutdownTimeout  = errors.New("kernel: shutdown timeout")
)
```

---

## 3. 目录结构

```
kernel/
├── go.mod                      # stdlib-only，无外部依赖
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go                      # 包级文档
├── kernel.go                   # App / Module / Deps 顶层导出
├── registry.go                 # 模块注册表
├── graph.go                    # 依赖图（拓扑排序、环检测）
├── lifecycle.go                # 启动 / 停止 / 健康检查
├── shutdown.go                 # 优雅停机（signal handling、deadline）
├── health.go                   # HealthStatus
├── errors.go                   # 公共错误变量
├── options.go                  # Option 模式配置
├── internal/
│   ├── dag/                    # DAG 实现（拓扑排序、环检测）
│   └── signal/                 # OS signal 处理
├── testdata/
│   └── *.golden
├── example_test.go
├── benchmark_test.go
└── integration_test.go         # //go:build integration
```

---

## 4. 依赖

### 4.1 go.mod

```
module github.com/ZoneCNH/kernel

go 1.23
```

### 4.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| stdlib only | configx, observex, resiliencx, schedulex, testkitx |
| | 所有业务域实现 |
| | 所有 L2.5 领域共享层 |
| | 所有存储/中间件扩展 |

### 4.3 特殊说明

kernel 是 stdlib-only 的 L0 原语层。它通过接口接收 `configx.Reader`、`observex.Logger` 等，但不 import 这些包。`Deps` 结构体的类型定义在消费方（如 `x.go`）组装时注入。

---

## 5. CI Gate

### 5.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `go test ./... -coverprofile=cover.out && go tool cover -func=cover.out` | 总覆盖率 < 80% |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment |

### 5.2 kernel 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| stdlib-only | `go list -deps ./... \| grep -v "^std" \| grep -v "kernel"` | 任何非 stdlib 依赖 |
| no-hidden-goroutine | `grep -rn "go func" --include="*.go" . \| grep -v _test.go \| grep -v internal/` | 非 internal 包启动 goroutine |

### 5.3 CI Pipeline

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.23' }
      - run: golangci-lint run

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.23' }
      - run: go test ./... -race -count=1 -coverprofile=cover.out
      - name: Coverage gate
        run: |
          COV=$(go tool cover -func=cover.out | grep total | awk '{print $3}' | tr -d '%')
          if (( $(echo "$COV < 80" | bc -l) )); then
            echo "FAIL: coverage $COV% < 80%"
            exit 1
          fi

  stdlib-only:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.23' }
      - run: |
          EXTERNAL=$(go list -deps ./... | grep -v "^std" | grep -v "github.com/ZoneCNH/kernel" || true)
          if [ -n "$EXTERNAL" ]; then
            echo "BLOCKED: kernel has external dependencies:"
            echo "$EXTERNAL"
            exit 1
          fi

  benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.23' }
      - run: go test -bench=. -benchmem -count=3 ./... | tee bench.txt
      - uses: actions/upload-artifact@v4
        with: { name: benchmark, path: bench.txt }
```

---

## 6. 测试矩阵

### 6.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| 循环依赖检测 | `Register(A→B→A)` 返回 `ErrCycleDetected` |
| 拓扑序启动 | `Run` 按依赖序调用 `Init` → `Start` |
| 反序停止 | `Shutdown` 按启动反序调用 `Stop` |
| 启动失败 fail-fast | 模块 A 启动失败 → B 不启动 → App 返回错误 |
| 停止超时 force | 模块 Stop 超时 → deadline 后强制返回 |
| 健康检查 | `Health()` 幂等、无副作用 |
| context 取消 | parent ctx cancel → 所有模块收到通知 |
| 重复注册 | 同一模块名注册两次 → `ErrAlreadyRegistered` |
| 模块未找到 | `ModuleHealth("unknown")` → `ErrModuleNotFound` |
| panic 隔离 | 模块 Start panic → 被 catch → App 返回错误 |

### 6.2 Benchmark

| 场景 | 目标 |
|------|------|
| 50 模块注册 + 依赖图校验 | < 10ms |
| 冷启动（不含业务模块） | < 100ms |
| 依赖图拓扑排序（100 节点） | < 1ms |

### 6.3 集成测试

| 场景 | 验证点 |
|------|--------|
| 完整启动-运行-停止 | App.Run → 模块全部 Running → signal → Shutdown → 全部 Stopped |
| 启动失败回滚 | 部分模块 Init 成功、Start 失败 → 已 Init 的模块被 Stop |

---

## 7. 性能预算

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| 冷启动（不含业务模块） | < 100ms | benchmark test |
| 模块注册 + 依赖图校验 | < 10ms / 50 模块 | benchmark test |
| graceful shutdown（无阻塞模块） | < 5s | integration test |
| 常驻内存 | < 2MB | profiling |

---

## 8. 可观测输出

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `kernel.module.start.duration` | histogram，模块启动耗时 |
| metric | `kernel.module.stop.duration` | histogram，模块停止耗时 |
| metric | `kernel.module.status` | gauge，模块运行状态（0=stopped, 1=starting, 2=running, 3=stopping, 4=error） |
| log | `kernel.module.starting` | info，模块开始启动，含 module name |
| log | `kernel.module.started` | info，模块启动完成，含 duration |
| log | `kernel.module.start_failed` | error，模块启动失败，含 error + module name |
| log | `kernel.shutdown.initiated` | info，收到停机信号 |
| log | `kernel.shutdown.completed` | info，停机完成，含 duration |
| log | `kernel.dependency.cycle` | error，检测到循环依赖，含 cycle path |
| span | `kernel.startup` | 根 span，包含所有模块启动子 span |
| span | `kernel.shutdown` | 根 span，包含所有模块停止子 span |

---

## 9. 故障模式

| 故障场景 | 降级行为 | 是否阻塞启动 |
|----------|----------|--------------|
| 模块启动失败 | **fail-fast**：记录失败模块，拒绝启动整个应用 | 是 |
| 模块停止超时 | **force shutdown**：超过 deadline 后强制终止，记录未完成模块 | 否（运行时） |
| 依赖图存在循环 | **fail-fast**：启动前检测，报错并退出 | 是 |
| 模块 panic | **隔离**：catch panic，记录堆栈，返回错误 | 是（启动时）/ 否（运行时） |

---

## 10. 安全要求

| 要求 | 实现方式 |
|------|----------|
| 启动错误不泄露配置细节 | 错误消息包含模块名和错误类型，不包含配置值 |
| shutdown 不泄露内部状态 | 错误消息只包含超时模块名，不包含内部堆栈 |

---

## 11. 配置依赖

kernel 通过 `configx.Reader` 接收以下配置：

```yaml
kernel:
  startup_timeout: 30s        # 模块启动超时
  shutdown_timeout: 15s       # 优雅停机超时
  health_check_interval: 10s  # 健康检查周期
  modules: []                 # 显式模块列表（可选，默认自动发现）
```

---

## 12. 升级兼容

| 变更类型 | 版本升级 |
|----------|----------|
| Module interface 变更 | **major**（所有依赖模块需同步更新） |
| 新增可选配置字段 | patch / minor |
| 新增必填配置字段 | **minor**（带默认值） |
| 修复 bug | **patch** |

---

## 13. 发布 DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、配置说明、API 概览
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] stdlib-only 检查通过
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更（或已 bump major）
