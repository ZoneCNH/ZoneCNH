# configx 设计方案

> Design ID: DESIGN-configx-v1
> Source Spec: [SPEC.md](./SPEC.md) v1.0.1
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

## 3. 关键架构决策 (ADR)

### ADR-001: Reader 接口分离
- **决策**：Config 嵌入 Reader，但只注入 Reader 到业务模块
- **理由**：防止运行时意外修改配置，符合 BR-005
- **后果**：业务模块仅 import Reader 接口

### ADR-002: Fail-fast 校验
- **决策**：启动时强制 schema 校验，失败阻断启动
- **理由**：配置错误在运行时才发现代价高昂
- **后果**：所有必填配置必须在启动时可用

### ADR-003: 无运行时配置修改
- **决策**：配置加载后全局不可变（冻结核心配置）
- **理由**：并发安全、可复现
- **后果**：Watch 为可选特性，非核心路径

### ADR-004: 敏感字段脱敏
- **决策**：password/token/secret/key/accessKey/secretKey 字段自动脱敏
- **理由**：防止日志、错误消息、监控输出泄露凭据
- **后果**：调试需显式调用 Reveal() 查看原始值
- **实现 Task**：TASK-CONFIGX-010

## 4. 依赖关系

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

## 5. 技术风险

| 风险 | 概率 | 影响 | 缓解 |
|------|:--:|:--:|------|
| YAML/TOML 解析差异 | Low | High | 统一 golden 测试 |
| 环境变量类型转换错误 | Medium | Medium | 明确的类型转换规则 |
| Watch 并发安全 | Medium | High | mutex + 快照模式 |
| 敏感信息泄露 | Low | Critical | 自动脱敏 + CI 扫描（TASK-010） |
