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

---

## 5. 关键架构决策

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
