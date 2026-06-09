# kernel 设计方案

> Design ID: DESIGN-kernel-v1
> Source Spec: SPEC-kernel-v1 (v1.1.0)
> 生成日期：2026-06-09

---

## 1. 架构概述

kernel 是 FoundationX L0 原语层，提供应用运行时骨架。采用 stdlib-only 设计，零外部依赖，通过 `Deps` 结构体注入 L1 能力。

```text
┌─────────────────────────────────────────────┐
│                    App                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │ Module A │ │ Module B │ │ Module C │    │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘    │
│       │             │             │          │
│  ┌────▼─────────────▼─────────────▼────┐    │
│  │         Lifecycle Manager            │    │
│  │  (Registry + Graph + Runner)         │    │
│  └──────────────────────────────────────┘    │
│                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │  Graph   │ │ Registry │ │ Shutdown │    │
│  │ (DAG)    │ │ (Map)    │ │ (Signal) │    │
│  └──────────┘ └──────────┘ └──────────┘    │
└─────────────────────────────────────────────┘
```

---

## 2. 模块拆分

| 文件 | 职责 | 对应 Spec |
|------|------|-----------|
| `kernel.go` | App/Module/Deps/HealthStatus/GraphView 顶层导出 | §9.1 |
| `errors.go` | 公共错误变量（10 个） | §10.1 |
| `registry.go` | 模块注册表（并发安全） | FR-001 |
| `graph.go` | 依赖图（DAG、环检测、拓扑排序） | FR-005, BR-001, BR-002 |
| `lifecycle.go` | 启动/停止编排（拓扑序启动、反序停止） | FR-002, FR-003 |
| `shutdown.go` | 优雅停机（signal handling、deadline、force） | FR-003, BR-006 |
| `health.go` | HealthStatus 查询 | FR-004, BR-005 |
| `options.go` | Option 模式配置 | §11 |
| `doc.go` | 包级文档 | — |
| `internal/dag/` | DAG 算法实现 | BR-001, BR-002 |
| `internal/signal/` | OS signal 处理 | FR-003 |

---

## 3. 接口设计

### 3.1 Module 接口

```go
type Module interface {
    Name() string
    Init(ctx context.Context, deps Deps) error
    Start(ctx context.Context) error
    Stop(ctx context.Context) error
    Health(ctx context.Context) HealthStatus
}
```

**设计决策**：Module 不持有 Deps 引用，Init 时接收，由模块自行保存。这避免了 kernel 管理模块内部状态。

### 3.2 Deps 结构体

```go
type Deps struct {
    Config    ConfigReader
    Logger    Logger
    Meter     Meter
    Tracer    Tracer
    Resilient ResilientPolicy
    Scheduler Scheduler
}
```

**ADR-001**：Deps 字段类型全部为 kernel 内定义的最小接口（BR-009）。L1 包提供实现，组合根注入。这保证 kernel import graph 只含 stdlib。

### 3.3 App 接口

```go
type App interface {
    Register(m Module) error
    Run(ctx context.Context) error
    Shutdown(ctx context.Context) error
    ModuleHealth(name string) HealthStatus
    DependencyGraph() GraphView
}
```

---

## 4. 数据流

```text
Register(A) → Register(B) → Register(C)
    ↓
Run(ctx)
    ↓
DependencyGraph() → 拓扑排序 → [A, B, C]
    ↓
A.Init(deps) → A.Start(ctx)
B.Init(deps) → B.Start(ctx)  // B 依赖 A
C.Init(deps) → C.Start(ctx)  // C 依赖 A
    ↓
（运行中）
    ↓
Shutdown(ctx)
    ↓
C.Stop(ctx) → B.Stop(ctx) → A.Stop(ctx)  // 反序
```

### 5.1 ModuleHealth 查询流

`ModuleHealth(name)` 的内部查询路径：

1. `app.ModuleHealth(name)` 被调用
2. 从 `registry` 查询模块是否存在 → 不存在则返回 `ErrModuleNotFound`
3. 检查 App 是否已 Run → 未 Run 则返回 `HealthStatus{Ready: false, Live: false}`
4. 调用 `module.Health(ctx)` 获取模块自报告状态
5. 如果模块 Health 方法 panic，catch 并返回 `HealthStatus{Ready: false, Live: false, Message: "health check panic"}`
6. 返回 HealthStatus 给调用方

**设计约束**：Health 必须是幂等且无副作用的（BR-005），调用 Health 不应改变模块状态。

---

## 5.2 关键架构决策

### ADR-001: Deps 接口内聚

- **决策**：Deps 中所有字段类型定义在 kernel 包内
- **理由**：BR-009 要求 kernel 不 import L1 包；接口定义在 kernel 内，L1 提供实现
- **后果**：L1 包需实现 kernel 定义的接口，接口变更需 major version

### ADR-002: panic 隔离

- **决策**：Init/Start/Stop 调用点全部 `defer recover()`
- **理由**：BR-007 要求模块 panic 不传播到调用方
- **后果**：panic 被转换为 `ErrStartupFailed` 或记录日志

### ADR-003: 拓扑排序算法

- **决策**：使用 Kahn 算法（BFS-based），同时检测环
- **理由**：O(V+E) 复杂度，天然支持环检测，实现简单
- **后果**：100+ 模块拓扑排序 < 1ms

### ADR-004: Shutdown 幂等

- **决策**：Shutdown 多次调用返回 nil，不重复 Stop
- **理由**：FR-003 要求幂等；signal handler 可能触发多次
- **后果**：需要状态机跟踪 shutdown 进度

### ADR-005: Run 后禁止 Register

- **决策**：Run 完成后 Register 返回 `ErrAlreadyStarted`
- **理由**：动态注册会破坏拓扑排序的确定性
- **后果**：所有模块必须在 Run 前注册

---

## 6. 依赖关系

```text
kernel (L0)
├── stdlib only
├── 无外部依赖
└── 被以下模块依赖：
    ├── configx (L1)
    ├── observex (L1)
    ├── resiliencx (L1)
    ├── schedulex (L1)
    ├── testkitx (L1)
    └── 所有业务域模块
```

---

## 7. 技术风险

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| 拓扑排序算法 bug | Low | High | 充分测试：自引用、互引用、深层链、100+ 节点 |
| panic recovery 遗漏 | Low | High | 逐一检查 Init/Start/Stop 调用点 |
| 并发安全问题 | Medium | High | `-race` 测试 + `sync.Mutex` 保护 |
| stdlib-only 被破坏 | Low | Critical | CI gate + `go list -deps` |
| 接口变更影响下游 | Medium | Major | SemVer 管理，接口变更 bump major |

---

## 8. 设计约束

- stdlib-only，零外部依赖（BR-008）
- Deps 接口类型在 kernel 内定义（BR-009）
- 不包含业务语义（Non-goal）
- 不实现日志/指标/追踪的具体实现（Non-goal）
- 公开 API 1.x 内向后兼容

## 10. 核心数据结构

### 10.1 app struct

```go
type app struct {
    modules        map[string]Module      // 已注册模块（name → Module）
    graph          *graph                  // 依赖图
    order          []string                // 拓扑排序后的启动顺序
    startupTimeout time.Duration           // 单模块启动超时
    shutdownTimeout time.Duration          // 优雅停机超时
    mu             sync.RWMutex            // 保护 running/shutdown 状态
    running        bool                    // App 是否正在运行
    shutdown       bool                    // App 是否已停机
    logger         Logger                  // 日志接口
    meter          Meter                   // 指标接口
}
```

### 10.2 registry（内部 map）

```go
type registry struct {
    mu      sync.RWMutex
    modules map[string]Module  // name → Module，注册时写入，Run 后只读
    order   []string           // 注册顺序（用于确定性遍历）
}
```

### 10.3 graph（邻接表）

```go
type graph struct {
    mu       sync.RWMutex
    adj      map[string][]string  // 邻接表：node → [依赖者列表]
    inDegree map[string]int       // 入度表：用于 Kahn 算法
    nodes    []string             // 所有节点名
}
```

---

## 11. Mock 策略

### 11.1 单元测试

- **Module 接口**：测试中使用 stub 实现（如 `stubModule`），可控返回值和 panic 行为
- **Deps 字段**：注入 mock Logger（记录日志调用）、mock Meter（验证指标上报）
- **CI gate**：`go list -deps` 验证无非 stdlib 依赖，无需 mock

### 11.2 集成测试

- 使用真实 `app` 实例 + stub Module，验证完整启动-运行-停止流程
- signal handler 使用 `internal/signal` 包的可注入 hook（避免真实 OS 信号）

---

## 12. 可扩展性与演进

### 9.1 已知扩展路径

| 扩展方向 | 当前设计支撑 | 演进方式 |
|----------|-------------|----------|
| 多 App 实例 | App 通过 `New()` 创建，无全局单例 | 直接创建多个独立 App 实例 |
| 自定义 GraphView 策略 | GraphView 为接口，内部实现可替换 | 未来可注入自定义拓扑排序算法 |
| 模块热注册 | 当前 Run 后禁止 Register（BR-004） | 未来可增加 `RegisterLazy()` 支持延迟注册 |
| 停机钩子 | Shutdown 仅调用 Stop | 未来可增加 `OnShutdown(ctx)` 回调链 |
| 健康检查策略 | HealthStatus 为固定结构 | 未来可扩展为 `HealthChecker` 接口支持自定义检查 |

### 9.2 设计不阻塞的演进方向

- Deps 结构体通过接口注入，新增能力只需扩展 Deps 字段，不改 Module 接口
- errors.go 使用 `errors.New` 裸变量，未来可升级为结构化错误码体系
- Option 模式配置（TASK-KERNEL-008）天然支持向后兼容扩展
