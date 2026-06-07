# configx 完整规格

> Foundation L1 运行时。统一配置加载、合并、校验、脱敏、版本和热加载。

最后更新：2026-06-07

---

## 1. 定位

`configx` 是配置统一入口，负责把文件、环境变量、远端配置和密钥引用合并成可校验、可追踪、可脱敏的配置对象。

### 核心职责

- 配置源：file、env、remote、secret reference
- 配置合并优先级
- schema 校验和版本迁移
- 默认值策略
- 敏感字段脱敏
- 配置 fingerprint / checksum
- 热加载和变更事件
- 非法配置 fail-fast
- Provenance（每个 key 记录 source、priority、override 链路）
- EffectiveConfigHash（配置指纹，可复现）
- SanitizedManifest（安全进入日志/health/CI artifact）
- StrictDecode（未识别字段、重复字段、类型错误 fail-fast）
- SecretPolicy（统一 secret key 识别规则）
- ValidationReport（字段级证据）

### 明确不做

- 不写业务默认策略
- 不理解交易所、策略、风控含义
- 不强制绑定全局单例
- 不负责解释配置背后的业务含义

---

## 2. 接口契约

### 2.1 Reader / Manager

```go
type Reader interface {
    Get(path string) (any, bool)
    GetString(path string) (string, error)
    GetInt(path string) (int, error)
    GetBool(path string) (bool, error)
    GetDuration(path string) (time.Duration, error)
    GetStringSlice(path string) ([]string, error)
    Unmarshal(target any) error
    Fingerprint() string
}

type Manager interface {
    Reader
    Load(ctx context.Context) error
    Watch(ctx context.Context, onChange func(ChangeEvent)) error
    Validate() []ValidationError
    Redacted() Reader
    Version() int
}
```

### 2.2 Provider

```go
type Provider interface {
    Name() string
    Load(ctx context.Context) (map[string]any, error)
    Watch(ctx context.Context, onChange func()) error
}
```

### 2.3 事件

```go
type ChangeEvent struct {
    Version     int
    Changed     []FieldChange
    Fingerprint string
}

type FieldChange struct {
    Path     string
    OldValue any
    NewValue any
}

type ValidationError struct {
    Path     string
    Message  string
    Severity string // error / warning
}
```

### 2.4 契约约束

- `Fingerprint()` 对相同输入必须返回稳定值（排除 secret 字段）
- `Load` 失败不能污染当前有效配置（copy-on-write 语义）
- `Watch` 回调在独立 goroutine 中执行，调用方需自行处理并发
- `Redacted()` 返回的 Reader 不含任何匹配 secret 模式的字段
- 合并优先级：env > file > default
- 热加载失败 → 保持当前配置不变

### 2.5 公共错误

```go
var (
    ErrConfigNotFound    = errors.New("configx: config file not found")
    ErrParseFailed       = errors.New("configx: parse failed")
    ErrValidationFailed  = errors.New("configx: validation failed")
    ErrSourceUnreachable = errors.New("configx: remote source unreachable")
    ErrStrictDecode      = errors.New("configx: unknown or duplicate field")
)
```

---

## 3. 目录结构

```
configx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── configx.go                  # Manager / Reader 顶层导出
├── errors.go                   # 公共错误变量
├── options.go                  # Option 模式配置
├── provider/
│   ├── file/                   # YAML / TOML / JSON 文件
│   ├── env/                    # 环境变量
│   ├── remote/                 # 远端（etcd / consul / Nacos）
│   └── secret/                 # 密钥引用（Vault / AWS SM）
├── schema.go                   # 校验
├── watch.go                    # 热加载
├── redact.go                   # 脱敏
├── merge.go                    # 多源合并
├── fingerprint.go              # 配置指纹
├── provenance.go               # 来源追踪
├── manifest.go                 # SanitizedManifest
├── strict.go                   # StrictDecode
├── secret_policy.go            # SecretPolicy
├── validation_report.go        # ValidationReport
├── internal/
│   ├── decode/
│   └── merge/
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
module github.com/ZoneCNH/configx

go 1.23
```

### 4.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| kernel（L0 原语） | observex, resiliencx, schedulex |
| stdlib | testkitx（仅 test） |
| YAML/TOML/JSON 解析库 | 所有业务域实现 |

### 4.3 foundationx 兼容

- 当前状态：v0.0.0 local replace（见 `ADR-foundationx-exit.md`）
- 计划：v0.3 前迁移到 kernel 原语（`errx.RedactedString` 替代 `foundationx.SecretString`）

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

### 5.2 configx 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| secret leak golden | `go test -run TestSecretLeak ./...` | secret 值出现在日志/错误/fingerprint |
| source precedence golden | `go test -run TestSourcePrecedence ./...` | env > file > default 规则被破坏 |
| no-foundationx-new | `grep -rn "foundationx" --include="*.go" . \| grep -v _test.go \| grep -v internal/foundationx` | 新增 foundationx 用法 |

### 5.3 依赖守卫

```bash
#!/bin/bash
# scripts/check-deps.sh
MODULE=$(head -1 go.mod | awk '{print $2}')
FORBIDDEN=(
    "github.com/ZoneCNH/binance"
    "github.com/ZoneCNH/factor-engine"
    "github.com/ZoneCNH/signal-factory"
    "github.com/ZoneCNH/risk-engine"
    "github.com/ZoneCNH/order-engine"
    # ... 所有业务域实现包
)
for pkg in $(go list ./...); do
    for dep in "${FORBIDDEN[@]}"; do
        if grep -q "$dep" <(go list -m all 2>/dev/null); then
            echo "BLOCKED: $MODULE imports forbidden dependency $dep"
            exit 1
        fi
    done
done
echo "Dependency guard passed"
```

---

## 6. 测试矩阵

### 6.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| 多源合并优先级 | env > file > default |
| schema 校验 | 缺少必填字段 → `ValidationError` |
| 类型安全读取 | `GetString` 对非 string 返回错误 |
| 热加载 + diff | `Watch` 回调收到正确的 `ChangeEvent` |
| 热加载失败保护 | 校验失败 → 配置不变 |
| fingerprint 稳定性 | 相同输入 → 相同 fingerprint |
| secret 脱敏 | `Redacted()` 不含匹配字段 |
| StrictDecode | 未识别字段 → `ErrStrictDecode` |
| Provenance | 每个 key 有正确的 source 记录 |
| SanitizedManifest | 输出不含 secret 字段 |
| SecretPolicy | 匹配 `password/secret/token/api_key` 等模式 |
| ValidationReport | 字段级错误和警告 |

### 6.2 Golden 测试

| 场景 | 验证点 |
|------|--------|
| secret leak | secret 值不出现在任何输出中 |
| source precedence | 合并顺序正确 |

### 6.3 集成测试

| 场景 | 验证点 |
|------|--------|
| env 覆盖 | 设置 env → `Get` 返回 env 值 |
| 远端不可达降级 | remote 超时 → fallback 到 file |

### 6.4 Benchmark

| 场景 | 目标 |
|------|------|
| 文件加载 1000 字段 | < 50ms |
| 单字段读取 | < 1μs |
| 热加载 + diff 计算 | < 100ms |
| fingerprint / checksum | < 1ms / 1000 字段 |

---

## 7. 性能预算

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| 文件加载 + 合并 + 校验 | < 50ms / 1000 字段 | benchmark test |
| 单字段读取（已加载） | < 1μs | benchmark test |
| 热加载 + diff 计算 | < 100ms | benchmark test |
| fingerprint / checksum 计算 | < 1ms / 1000 字段 | benchmark test |
| 常驻内存 | < 5MB | profiling |

---

## 8. 可观测输出

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `configx.load.duration` | histogram，配置加载耗时 |
| metric | `configx.reload.total` | counter，热加载次数，label: success/failure |
| metric | `configx.validation.errors` | counter，校验错误数 |
| log | `configx.loaded` | info，配置加载完成，含 source + field count + fingerprint |
| log | `configx.reload.triggered` | info，热加载触发 |
| log | `configx.reload.applied` | info，热加载应用，含变更字段 diff |
| log | `configx.reload.rejected` | warn，热加载被拒绝（校验失败），含 error |
| log | `configx.secret.redacted` | debug，敏感字段被脱敏，含 field path |

---

## 9. 故障模式

| 故障场景 | 降级行为 | 是否阻塞启动 |
|----------|----------|--------------|
| 配置文件不存在或解析失败 | **fail-fast**：无法启动，错误消息包含路径和格式细节 | 是 |
| 远端配置源不可达 | **fallback 到本地**：使用本地文件 + env，记录降级日志 | 否（有本地兜底时） |
| 热加载失败 | **保持当前配置**：不污染有效配置，记录错误，等待下次重试 | 否（运行时） |
| schema 校验失败 | **fail-fast**：非法配置不能启动；热加载时拒绝新值 | 视场景 |

---

## 10. 安全要求

| 要求 | 实现方式 |
|------|----------|
| secret 字段不能进入日志、错误消息、metrics label | 脱敏拦截器，基于 `redact_fields` 配置列表自动替换为 `***` |
| secret 字段不能进入配置 fingerprint | fingerprint 计算前排除 secret 字段 |
| 远端配置源需要 TLS | 强制 HTTPS / mTLS，不允许明文传输 |
| 配置文件权限检查 | 启动时检查敏感配置文件权限（0600），不满足则 warn |

### secret 识别模式

```
(?i)(password|passwd|secret|token|api[_-]?key|access[_-]?key|private[_-]?key|credential|auth)
```

---

## 11. 配置 schema

configx 自身不需要外部配置。它通过 Provider 接口接收配置源。但消费方（如 `x.go`）通过以下 schema 配置 configx 行为：

```yaml
configx:
  sources:
    - type: file
      path: /etc/app/config.yaml
    - type: env
      prefix: APP_
    - type: remote
      endpoint: https://config.example.com
      timeout: 5s
  schema:
    strict: true           # StrictDecode 模式
    unknown_field: error   # error / warn / ignore
  redact_fields:
    - password
    - secret
    - api_key
    - token
  watch:
    enabled: true
    interval: 30s
```

---

## 12. 升级兼容

| 变更类型 | 版本升级 |
|----------|----------|
| Reader / Manager interface 变更 | **major** |
| 新增可选配置字段 | patch / minor |
| 新增必填配置字段 | **minor**（带默认值） |
| 删除公共 API | **major** |
| 修改默认行为 | **minor** + changelog |
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
- [ ] secret leak golden 测试通过
- [ ] source precedence golden 测试通过
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更（或已 bump major）
