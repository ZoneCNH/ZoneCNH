# configx 设计方案

> Design ID: DESIGN-configx-v1
> Source Spec: [SPEC.md](./SPEC.md) v1.0.0
> Version Mapping: 本文档描述 v0.1.4 已实现能力；[goal.md](./goal.md) 定义 v1.0 完整目标。详见 §1.2。
> 生成日期：2026-06-12

## 1. 架构概述

configx 是 Foundation L1 配置管理模块，提供统一的多源配置加载、合并、校验和分发。核心设计为单 Config 实例 + Reader 接口分离。

```text
┌──────────────────────────────────────────────────────────┐
│                      x.go (组合根)                        │
│  cfg := configx.New(opts...)                              │
│  cfg.Load("config.yaml")                                  │
│  cfg.WithEnvOverride("APP")                               │
│  cfg.Validate()                                           │
│  // 注入 cfg.Reader() 到各模块                             │
└──────────┬───────────────────────────────────────────────┘
           │ Reader 接口
     ┌─────┼─────┬──────┬──────┐
     ▼     ▼     ▼      ▼      ▼
  observex resiliencx redisx kafkax ...
```

### 1.1 设计原则

1. **接口分离**：Config（写操作）≠ Reader（读操作），运行时只注入 Reader
2. **Fail-fast**：启动时 schema 校验，配置错误在启动期暴露
3. **覆盖优先级明确**：默认值 → 文件 → 环境变量 → 命令行参数
4. **并发安全**：配置加载后不可变，Reader 无锁读取
5. **敏感脱敏**：password/token/key/secret 字段自动脱敏

### 1.2 与 goal.md 的版本映射

| 能力 | v0.1.4 (DESIGN.md 覆盖) | v1.0 (goal.md 目标) | 状态 |
|------|:---:|:---:|:--:|
| FileSource / EnvSource / ArgsSource | ✅ | ✅ | 已实现 |
| ConfigSource SPI（远程配置源扩展点） | ❌ | ✅ | v1.0 计划 |
| ConfigSnapshot（不可变配置快照） | ❌ | ✅ | v1.0 计划 |
| ConfigChangeEvent（热更新事件） | ❌ | ✅ | v1.0 计划 |
| bind(prefix, class) 强类型绑定 | ❌ | ✅ | v1.0 计划 |
| ConfigValidator SPI（自定义校验扩展） | ❌ | ✅ | v1.0 计划 |
| 热更新失败回滚 | ❌ | ✅ | v1.0 计划 |
| 审计日志（变更来源/操作者/脱敏 diff） | ❌ | ✅ | v1.0 计划 |
| 配置文档自动生成 | ❌ | ✅ | v1.0 计划 |
| 敏感字段脱敏（自动 + Reveal()） | ⚠️ TASK-010 实现中 | ✅ | v0.3 过渡 |
| Watch 文件监控 | ⚠️ 可选特性 (FR-005) | ✅ | v0.1.4 可用 |

> **说明**：本 DESIGN.md 聚焦 v0.1.4 已实现的架构决策。v1.0 新增能力（ConfigSource SPI、热更新回滚、审计日志等）的具体设计将在 v1.0 开发阶段补充，goal.md 作为需求基线。

## 2. 核心设计

### 2.1 Reader 接口 — 只读视图

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
```

### 2.2 Config 接口 — 完整生命周期

```go
type Config interface {
    Reader
    Load(path string) error
    WithEnvOverride(prefix string) Config
    Validate() error
    Watch(key string, callback func(interface{})) error
}
```

### 2.3 配置覆盖层级

```
命令行参数 (最高优先级)
  ↑ 覆盖
环境变量 (APP_ 前缀)
  ↑ 覆盖
配置文件 (YAML/TOML/JSON)
  ↑ 覆盖
默认值 (WithDefaults)
```

### 2.4 Option 模式

```go
func WithDefaults(map[string]interface{}) Option
func WithSchema(*jsonschema.Schema) Option
func WithEnvPrefix(string) Option
func WithStrictMode(bool) Option
```

### 2.5 测试策略与 Mock 注入点

**测试分层**：

| 层级 | 覆盖范围 | Mock 策略 | 对应 Task |
|------|----------|-----------|-----------|
| 单元测试 | 解析器、合并算法、类型转换、校验规则 | 纯函数，无需 mock | 002~005 |
| Reader 测试 | Get/并发安全/类型方法 | `sync.RWMutex` 保护的 `map[string]interface{}` 直接注入 | 006 |
| 集成测试 | 完整加载链：默认值→文件→环境变量→校验→读取 | 使用 `testdata/` 下的 fixture 文件 | 002~007 |
| 安全测试 | 脱敏、权限检查、gitleaks | 含敏感字段的 fixture 配置 | 010 |
| Watch 测试 | 文件变更→回调触发 | 临时文件 + `time.Tick` 轮询（不需要真实 fsnotify） | 007 |

**Mock 注入点**：

| 注入点 | 位置 | 用途 |
|--------|------|------|
| `config.data` (内部 map) | `reader.go` | Reader 单元测试直接构造嵌套 map 验证点分路径遍历，无需 Load 完整流程 |
| `WithDefaults(map)` Option | `options.go` | 集成测试注入预定义默认值，避免依赖外部配置文件 |
| `WithSchema(*jsonschema.Schema)` Option | `options.go` | 校验测试注入自定义 schema，覆盖边界类型和 required 规则 |
| `WithStrictMode(bool)` Option | `options.go` | 控制未定义 key 行为，strict=true 用于严格模式测试 |
| `testdata/` 目录 | 项目根 | fixture 文件（YAML/TOML/JSON/schema），所有集成测试共享 |
| `Reveal(key) string` | `sanitize.go` | 调试用原始值查看（仅测试环境使用，生产代码需 CI 扫描阻断） |

## 3. 关键架构决策 (ADR)

### ADR-001: Reader 接口分离
- **决策**：Config 嵌入 Reader，但只注入 Reader 到业务模块
- **理由**：防止运行时意外修改配置，符合 BR-005
- **考虑的替代方案**：
  - *方案 B: 单一 Config 接口 + 文档约定"不要写"* — 依赖纪律而非编译器，BR-005 无法强制
  - *方案 C: Config 和 Reader 完全独立的两个 interface（无嵌入）* — 类型冗余，Get 方法需在两处声明
- **选择理由**：嵌入（embedding）兼顾类型安全和代码复用，Go 接口组合惯用法
- **后果**：业务模块仅 import Reader 接口

### ADR-002: Fail-fast 校验
- **决策**：启动时强制 schema 校验，失败阻断启动
- **理由**：配置错误在运行时才发现代价高昂
- **考虑的替代方案**：
  - *方案 B: 延迟校验（首次 Get 时校验）* — 启动快但错误发现晚，不符合 fail-fast 原则
  - *方案 C: 仅日志 warn 不阻断* — 运维友好但容易忽略，线上事故风险高
- **选择理由**：量化交易基础设施要求启动确定性；配置错误应尽早暴露
- **后果**：所有必填配置必须在启动时可用

### ADR-003: 无运行时配置修改
- **决策**：配置加载后全局不可变（冻结核心配置）
- **理由**：并发安全、可复现
- **考虑的替代方案**：
  - *方案 B: atomic.Value 包装整个配置* — 支持替换但增加内存开销和 GC 压力
  - *方案 C: 细粒度锁 + 可变配置* — 灵活但引入锁竞争和死锁风险
- **选择理由**：v0.1.4 以启动时一次性加载为核心场景，不可变设计最简单安全
- **后果**：Watch 为可选特性（FR-005），非核心路径；v1.0 将引入 ConfigSnapshot 支持安全热更新

### ADR-004: 敏感字段脱敏
- **决策**：password/token/secret/key/accessKey/secretKey 字段自动脱敏
- **理由**：防止日志、错误消息、监控输出泄露凭据
- **考虑的替代方案**：
  - *方案 B: 依赖调用方手动脱敏* — 不可靠，单点遗漏即泄露
  - *方案 C: 在日志/序列化层统一脱敏* — 覆盖面更广但侵入性强，且无法区分字段语义
- **选择理由**：在 Reader 层脱敏保证所有读取路径覆盖；提供 `Reveal()` 供调试使用
- **后果**：调试需显式调用 Reveal() 查看原始值
- **实现 Task**：TASK-CONFIGX-010

## 4. 生命周期状态机

```
  New(opts...)          Load(path)        WithEnvOverride()
      │                     │                    │
      ▼                     ▼                    ▼
┌─────────┐   ┌─────────┐   ┌─────────────┐   ┌──────────┐
│ 初始化   │──▶│  加载    │──▶│  环境变量覆盖 │──▶│   校验    │
│ (创建    │   │ (解析    │   │ (env→key     │   │ (schema   │
│  Config) │   │  文件)   │   │  映射+覆盖)   │   │  fail-fast)│
└─────────┘   └─────────┘   └─────────────┘   └────┬─────┘
                                                    │
                                                    ▼
                    ┌──────────┐              ┌──────────┐
                    │   关闭    │◀─────────────│   运行    │
                    │ (进程退出) │              │ (并发只读  │
                    │ 无资源清理 │              │  Get*())  │
                    └──────────┘              └──────────┘
```

| 阶段 | 触发方法 | 状态变更 | 可逆性 | 错误处理 |
|------|----------|----------|:--:|------|
| 初始化 | `New(opts...)` | 创建空 Config，应用 Option | ✅ 可重建 | Option 冲突时 panic（设计时约束） |
| 加载 | `Load(path)` | data 填充，来源标记为 FILE | ❌ 不可逆（ErrAlreadyLoaded） | 文件不存在/格式无效→返回 error，data 不变 |
| 覆盖 | `WithEnvOverride(prefix)` | env→key 映射写入覆盖层 | ✅ 返回新 Config（原实例不变） | 类型转换失败→返回 ErrTypeMismatch |
| 校验 | `Validate()` | 校验状态标记为 VALIDATED | ✅ 可重复调用 | 校验失败→返回错误列表，不阻断后续 Get |
| 运行 | `Reader.Get*(key)` | 只读访问，无状态变更 | — | key 不存在→返回 nil/零值，不 panic |
| 关闭 | 进程退出 | Config 实例随进程销毁 | — | 无资源需清理（无连接池/文件句柄） |

> **注**：Watch 阶段（FR-005）为可选特性，在 Load→Validate→Run 之间插入文件监控循环，不在主生命周期路径中。

## 5. 依赖关系

```text
configx (L1)
├── yaml.v3 (文件解析)
├── go-toml/v2 (文件解析)
└── 被以下模块依赖：
    ├── observex (L1)
    ├── resiliencx (L1)
    ├── schedulex (L1)
    ├── testkitx (L1)
    ├── 存储扩展 (redisx, kafkax, ...)
    └── 业务域模块
```

> **注**：foundationx exit 已完成 — kernel 不再被依赖。

## 6. 技术风险

| 风险 | 概率 | 影响 | 缓解 |
|------|:--:|:--:|------|
| YAML/TOML 解析差异 | Low | High | 统一 golden 测试 |
| 环境变量类型转换错误 | Medium | Medium | 明确的类型转换规则 |
| Watch 并发安全 | Medium | High | mutex + 快照模式 |
| 敏感信息泄露 | Low | Critical | 自动脱敏 + CI 扫描（TASK-010） |
