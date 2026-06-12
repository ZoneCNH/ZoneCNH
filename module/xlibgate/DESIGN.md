# xlibgate 设计方案

> Design ID: DESIGN-xlibgate-v1
> Source Spec: [SPEC.md](./SPEC.md) v1.0.0
> 生成日期：2026-06-12

---

## 1. 架构概述

xlibgate 是 Foundation L0 基座层的**单体 CLI 工具**，负责在 CI 和本地执行机器可验证的门禁检查。它不是库，不被任何模块 import；它只扫描其他模块的代码，不产生运行时依赖。

```text
┌──────────────────────────────────────────────────────────────────┐
│                        触发方式                                   │
│  CI 流水线 (PR check)   开发者本地 (pre-commit)   x.go release   │
└──────────┬──────────────┬──────────────────┬─────────────────────┘
           │              │                  │
           ▼              ▼                  ▼
┌──────────────────────────────────────────────────────────────────┐
│                     main.go (CLI 入口)                            │
│                                                                    │
│  flag 解析 → 配置加载 → 子命令路由                                  │
└─────────────┬────────────────────────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────────────────────────┐
│                    cmd/ (CLI 子命令层)                             │
│                                                                    │
│  root.go      check.go     imports.go    gomod.go                 │
│  baseline.go  release.go   all.go                                 │
└───┬───────┬───────┬─────────┬──────────┬─────────────────────────┘
    │       │       │         │          │
    ▼       ▼       ▼         ▼          ▼
┌──────────────────────────────────────────────────────────────────┐
│                    scanner/ (核心扫描引擎)                          │
│                                                                    │
│  imports.go         gomod.go           baseline.go                 │
│  ────────────       ─────────          ───────────                 │
│  AST 解析 +         执行 go mod tidy   go.mod go 指令               │
│  import 路径匹配     + diff 比较       版本比较                     │
└────────────────────┬──────────────────┬───────────────────────────┘
                     │                  │
                     ▼                  ▼
┌──────────────────────────────────────────────────────────────────┐
│  evidence/               internal/                                 │
│  ─────────               ─────────                                 │
│  collector.go            gomod/ — go.mod 解析封装                   │
│  validator.go            ast/   — Go AST 解析工具                   │
└──────────────────────────────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│  config.go          report.go          errors.go                   │
│  ─────────          ─────────          ────────                    │
│  xlibgate.yaml      统一输出           公共 sentinel                │
│  解析 + 校验        JSON + human       error 变量                   │
└──────────────────────────────────────────────────────────────────┘
```

### 1.1 设计原则

1. **纯 CLI，零 import**：xlibgate 不被任何模块 import，只作为独立二进制执行。
2. **stdlib 优先**：核心逻辑只依赖 stdlib（`go/parser`、`go/ast`、`os/exec`），配置解析依赖 `gopkg.in/yaml.v3`。
3. **子检查独立**：每个 checker（imports/gomod/baseline/release）独立执行，互不依赖状态。
4. **标准化输出**：统一 JSON 输出格式，适配 CI artifact 消费。
5. **外部工具集成**：gitleaks 作为外部命令调用（`os/exec`），不自研扫描逻辑。

---

## 2. 组件设计

### 2.1 cmd/ — CLI 入口和子命令

**职责**：flag 解析、子命令路由、全局配置注入。

**核心文件**：
- `main.go`：程序入口，调用 `cmd.Execute()`
- `root.go`：root 命令，注册全局 flags（`--config`、`--output`、`--artifact`）
- `check.go`：`check` 父命令，不直接执行，聚合子命令
- `imports.go`：`check imports` 子命令实现
- `gomod.go`：`check gomod` 子命令实现
- `baseline.go`：`check baseline` 子命令实现
- `release.go`：`check release` 子命令实现
- `all.go`：`check all` 子命令，编排所有子检查

**设计决策**：
- 使用 Go stdlib `flag` 包（零外部依赖），不用 cobra 等第三方 CLI 框架。
- 每个子命令文件独立：负责 flag 定义 → 参数校验 → scanner 调用 → report 输出。
- `check all` 使用顺序执行（非并行），确保输出顺序可预测。
- 某子检查 error 时不中断其余检查（符合 BR-006）。

### 2.2 scanner/ — 核心扫描引擎

**职责**：执行具体的门禁检查逻辑，返回结构化检查结果。

**核心文件**：

**imports.go — import 边界扫描器**
- 输入：项目根路径 + 禁止规则列表
- 过程：遍历 Go 源文件 → `go/parser` 解析 AST → 提取 `*ast.ImportSpec` → 匹配 forbidden 规则
- 输出：`[]Violation`（文件路径、行号、违规 import 路径）
- 跳过 `vendor/` 目录
- 规则匹配支持通配符 `"*"` 表示禁止所有目标

**gomod.go — go.mod 整洁度检查器**
- 输入：模块路径
- 过程：`os/exec` 调用 `go mod tidy` → `git diff --exit-code go.mod go.sum` → 捕获 diff
- 输出：diff 文本（如有）、整洁状态
- 无 go.mod 时返回 `ErrGomodDirty` 包装

**baseline.go — Go baseline 检查器**
- 输入：expected 版本 + 模块路径列表
- 过程：解析 `go.mod` 的 `go` 指令行 → 与 expected 比较
- 输出：不匹配的模块列表和版本差异
- 只验证 `go` 指令，不检查 `replace` 指令

**设计决策**：
- scanner 不感知 CLI flags，只接受结构化参数，便于单元测试。
- AST 解析使用 `go/parser` + `go/ast`（stdlib），不依赖第三方解析器。
- gomod 检查通过 `os/exec` 执行外部命令，捕获 stdout/stderr 和 exit code。
- scanner 函数返回 `CheckResult`，不直接输出。

### 2.3 evidence/ — release evidence 收集和校验

**职责**：收集 CI 产生的 release evidence，校验其完整性和 schema 合规性。

**核心文件**：
- `collector.go`：从文件路径或 CI artifact 收集 evidence 数据
- `validator.go`：根据 xlib-standard 定义的 Evidence schema 校验 evidence 项

**设计决策**：
- evidence schema 定义由 xlib-standard 维护，xlibgate 在运行时校验。
- 支持的 evidence 项：`test_coverage >= 80%`、`race_test_pass`、`secret_scan_pass`、`gomod_tidy`、`vet_clean`。
- 无效 JSON 返回 `ErrEvidenceInvalid`，缺失必需项返回 `ErrEvidenceMissing`。

### 2.4 internal/ — 内部工具包

**职责**：提供可复用的低层解析能力，不暴露为公开 API。

**核心目录**：
- `internal/gomod/`：go.mod 文件解析（提取 module 名、go 版本、require 列表）
- `internal/ast/`：Go AST 遍历工具（提取 import spec、文件路径映射）

**设计决策**：
- `internal/` 目录确保这些工具不被外部 import（Go 编译器强制）。
- 解析逻辑集中封装，避免 scanner 层直接操作字符串。

### 2.5 config.go — 配置加载

**职责**：加载和解析 `xlibgate.yaml`（或 `--config` 指定路径），产出类型安全的配置结构体。

**核心类型**：
```go
type Config struct {
    Baseline   BaselineConfig   `yaml:"baseline"`
    Imports    ImportsConfig    `yaml:"imports"`
    Release    ReleaseConfig    `yaml:"release"`
    SecretScan SecretScanConfig `yaml:"secret_scan"`
}
```

**设计决策**：
- 使用 `gopkg.in/yaml.v3` 解析 YAML（唯一外部依赖）。
- 配置文件为空时使用默认值（无 forbidden 规则、无 baseline 要求）。
- 解析失败返回 `ErrConfigInvalid`，文件不存在返回 `ErrConfigMissing`。
- 不支持多文件合并（见 SPEC §23 Open Questions）。

### 2.6 report.go — 统一输出

**职责**：将检查结果格式化为 JSON 或 human-readable 文本，写入 stdout 或 artifact 文件。

**核心类型**：
```go
type Report struct {
    Status    CheckStatus   `json:"status"`
    Timestamp string        `json:"timestamp"`
    Checks    []CheckResult `json:"checks"`
    Summary   Summary       `json:"summary"`
}

type Summary struct {
    Total  int `json:"total"`
    Passed int `json:"passed"`
    Failed int `json:"failed"`
    Errors int `json:"errors"`
}
```

**设计决策**：
- JSON 输出固定 schema（`status` + `checks[]` + `summary`），字段变更遵循 SemVer。
- Human-readable 输出自动检测终端颜色支持（`os.Stdout` 是否为 tty）。
- `--artifact` 参数将 JSON 写入指定文件路径，同时可继续输出到 stdout。

### 2.7 errors.go — 公共错误变量

**职责**：定义所有 sentinel error，调用方通过 `errors.Is` 判断错误类型。

```go
var (
    ErrConfigInvalid    = errors.New("xlibgate: invalid config")
    ErrConfigMissing    = errors.New("xlibgate: config file not found")
    ErrEvidenceInvalid  = errors.New("xlibgate: invalid evidence format")
    ErrEvidenceMissing  = errors.New("xlibgate: required evidence missing")
    ErrBaselineMismatch = errors.New("xlibgate: go baseline version mismatch")
    ErrImportViolation  = errors.New("xlibgate: import boundary violation")
    ErrGomodDirty       = errors.New("xlibgate: go.mod not tidy")
)
```

**设计决策**：
- 所有 error 使用 `"xlibgate: <reason>"` 前缀格式。
- 底层错误通过 `fmt.Errorf("%w: ...", ErrXxx, err)` 包装，保留错误链。
- sentinel error 与 exit code 映射：`ErrConfigInvalid`/`ErrConfigMissing` → exit 2，`ErrImportViolation` → exit 1。

---

## 3. 数据流

```text
配置文件 (xlibgate.yaml)
       │
       ▼
  config.go: 加载 + 解析 → Config 结构体
       │
       ▼
  CLI 子命令选择（check imports | gomod | baseline | release | all）
       │
       ▼
  参数注入 → scanner/evidence 层
       │
       ▼
  各 checker 独立执行：
  ┌─────────────┬──────────┬───────────┬──────────┬──────────┐
  │ imports.go  │ gomod.go │baseline.go│validator │ gitleaks │
  │ AST 扫描    │go mod tidy│ go 版本   │.go       │ os/exec  │
  │             │ + diff    │ 比较      │ evidence │          │
  └──────┬──────┴────┬─────┴─────┬─────┴────┬─────┴────┬─────┘
         │           │           │          │          │
         └───────────┴───────────┴──────────┴──────────┘
                            │
                            ▼
                   结果收集 → []CheckResult
                            │
                            ▼
                    report.go: 格式化输出
                            │
                   ┌────────┴────────┐
                   ▼                 ▼
              stdout (文本)    artifact 文件 (JSON)
```

**关键路径**：
1. `config.go` 是整个管线的起点，配置加载失败直接 exit 2。
2. scanner 层不调用 report 层（依赖反转：cmd 层协调 scanner → report）。
3. `check all` 收集所有 `CheckResult` 后统一交给 report 层。

---

## 4. 关键技术决策（ADR）

### ADR-001: stdlib flag vs cobra

- **决策**：使用 Go stdlib `flag` 包，不使用 cobra。
- **理由**：xlibgate CLI 结构固定（check 及其子命令），不需要 cobra 的动态命令注册和帮助生成能力。stdlib flag 零依赖，符合 "接近 stdlib" 原则。
- **后果**：子命令路由需要手动实现（根据 `os.Args[1]` 分发），但命令数量少（~7 个），复杂度可控。

### ADR-002: 顺序执行 vs 并行执行

- **决策**：`check all` 采用顺序执行所有子检查。
- **理由**：输出顺序可预测，CI 日志可读性好。各子检查耗时短（< 10s），并行化的收益有限，但增加的并发复杂度（输出交错、错误传播）是实在的。
- **后果**：总耗时 = 各子检查耗时之和，但仍满足 50 模块 < 30s 的预算。

### ADR-003: gitleaks 作为外部命令

- **决策**：通过 `os/exec` 调用 `gitleaks detect --no-git`，不自研 secret 扫描。
- **理由**：gitleaks 是社区标准的 secret 检测工具，规则库持续更新。自研扫描引擎维护成本高、漏报风险大。
- **后果**：运行环境需预装 `gitleaks` 二进制。gitleaks 不可用时 `check all` 中 secret_scan 标记为 error（不阻塞其余检查）。

### ADR-004: 配置单文件 vs 多文件合并

- **决策**：单一配置文件 `xlibgate.yaml`（或 `--config` 指定），不支持多文件合并。
- **理由**：当前 Foundation 模块结构单一，组织级 + 项目级配置合并尚无明确需求（见 SPEC §23 Open Questions）。
- **后果**：未来如需支持多级配置，需新增合并逻辑（不破坏现有单文件接口）。

### ADR-005: scanner 层无输出

- **决策**：scanner 层只返回 `CheckResult` 结构体，不直接写入 stdout/文件。
- **理由**：分离"检查"和"输出"关注点，使 scanner 可测试（不依赖终端），report 格式可独立演进。
- **后果**：所有输出统一经过 report 层，确保 JSON/human-readable 一致性。

---

## 5. 依赖关系

```text
xlibgate (L0 CLI 工具)
├── stdlib
│   ├── flag          — CLI 参数解析
│   ├── go/parser     — Go AST 解析
│   ├── go/ast        — AST 节点遍历
│   ├── os/exec       — 外部命令调用（go mod tidy、gitleaks）
│   └── encoding/json — JSON 输出
├── gopkg.in/yaml.v3  — 配置文件解析（唯一外部依赖）
├── gitleaks          — secret 扫描（外部命令，非 Go 依赖）
│
├── 不依赖任何 Foundation 运行时模块
│   （kernel、configx、observex、redisx 等 — 全部禁止）
│
└── 不被任何模块 import（纯 CLI 工具）
```

---

## 6. 错误处理

### 6.1 Exit Code 映射

| 场景 | Exit Code | 对应 sentinel error |
|------|-----------|-------------------|
| 所有检查通过 | 0 | — |
| 检查未通过（违规） | 1 | `ErrImportViolation`, `ErrGomodDirty`, `ErrBaselineMismatch`, `ErrEvidenceMissing` |
| 内部错误 | 2 | `ErrConfigInvalid`, `ErrConfigMissing`, `ErrEvidenceInvalid` |

### 6.2 错误包装策略

```go
// 底层错误保留
if err := yaml.Unmarshal(data, &config); err != nil {
    return fmt.Errorf("%w: %v", ErrConfigInvalid, err)
}

// check all 中某子检查 error —— 标记为 error 继续执行
result := CheckResult{Name: "imports", Status: StatusError, Details: ...}
results = append(results, result)
// 不 return，继续执行 gomod 检查
```

### 6.3 调用方处理

| 错误 | 调用方处理 |
|------|-----------|
| `ErrConfigInvalid` | `errors.Is(err, ErrConfigInvalid)` → 检查 YAML 语法 |
| `ErrConfigMissing` | `errors.Is(err, ErrConfigMissing)` → 确认 `--config` 路径 |
| `ErrImportViolation` | 移除违规 import，调整模块依赖 |
| `ErrGomodDirty` | 运行 `go mod tidy` 并提交变更 |

---

## 7. 输出格式

### 7.1 JSON 结构定义

```go
// CheckResult 是单次检查的结果
type CheckResult struct {
    Name       string      `json:"name"`        // "imports" | "gomod" | "baseline" | "release"
    Status     CheckStatus `json:"status"`      // "pass" | "fail" | "error"
    Details    []Violation `json:"details,omitempty"`
    DurationMs int64       `json:"duration_ms"`
}

// Violation 是单条违规详情
type Violation struct {
    File    string `json:"file"`              // 文件路径
    Line    int    `json:"line,omitempty"`    // 行号（可选）
    Message string `json:"message"`           // 违规描述
}

// CheckStatus 是检查状态的枚举类型
type CheckStatus string

const (
    StatusPass  CheckStatus = "pass"
    StatusFail  CheckStatus = "fail"
    StatusError CheckStatus = "error"
)
```

### 7.2 Human-readable 格式

- 带颜色：`pass` 绿色、`fail` 红色、`error` 黄色
- 违规项包含 `文件路径:行号: 描述` 格式
- 终端不支持颜色时自动降级为纯文本

---

## 8. 技术风险

| 风险 | 概率 | 影响 | 缓解 |
|------|------|------|------|
| AST 解析大项目耗时超预算 | Low | Medium | Benchmark 验证 50 模块 < 10s，跳过 vendor 目录 |
| `go mod tidy` 网络依赖导致超时 | Medium | Medium | 设置合理超时（context.WithTimeout），超时标记 error 不阻塞 |
| gitleaks 未安装导致 secret_scan 跳过 | Medium | Low | 检查 gitleaks 可用性，不可用时标记 error 并提示安装 |
| xlib-standard evidence schema 升级不兼容 | Low | High | evidence 校验前做 schema 版本检查，不匹配时输出明确错误 |
| CI 环境无 color 导致输出乱码 | Low | Low | 自动检测 tty，非 tty 时输出纯文本 |
| 并发多个 xlibgate 实例冲突 | Low | Low | 各实例独立工作（无共享状态），artifact 文件路径由调用方指定 |

---

## 9. 设计约束

- 不被任何 Foundation 模块 import（纯 CLI 工具）。
- 核心依赖限制为 Go stdlib + `gopkg.in/yaml.v3`。
- 不承载业务逻辑，不做代码格式化（→ gofmt）、不做代码审查（→ human/AI）。
- CLI 命令结构变更 → minor version bump，exit code 语义变更 → major version bump。
- 所有检查结果通过 `CheckResult` 结构体传递，不直接写入 stdout。
- 公共错误变量在 `errors.go` 中集中定义。

---

## 10. 测试策略

### 10.1 单元测试

- **scanner/imports_test.go**：构造含违规 import 的 fixture 文件，验证检测结果含文件路径和行号
- **scanner/gomod_test.go**：构造 tidy/dirty 两种 go.mod fixture，验证 diff 捕获
- **scanner/baseline_test.go**：构造不同 go 版本的 go.mod fixture，验证版本比较逻辑
- **config_test.go**：有效 YAML → 正确加载，语法错误 → `ErrConfigInvalid`，文件不存在 → `ErrConfigMissing`
- **report_test.go**：JSON 输出 schema 完整性，human-readable 输出包含文件路径行号
- **errors_test.go**：`errors.Is` 可正确匹配 sentinel error

### 10.2 集成测试

- `integration_test.go`（`//go:build integration`）：完整 CLI 流程 `check all --config testdata/config.yaml`
- 自检：`xlibgate check all --config xlibgate.yaml` → pass
- CI artifact 输出：`--artifact result.json` → 文件写入且格式正确

### 10.3 Benchmark

```bash
go test -bench=. -benchmem -count=3 ./scanner/ ./...
```

---

## 11. 可扩展性

### 11.1 新增检查子命令

1. 在 `scanner/` 下新增 checker 文件（如 `license.go`）
2. 在 `cmd/` 下新增子命令文件（如 `license.go`）
3. 在 `cmd/all.go` 的检查列表中注册新 checker
4. 在 `config.go` 中新增对应配置段

### 11.2 扩展不阻塞的方向

- 新增 forbidden 规则类型（当前只支持 source→targets，可扩展为 regex 匹配）
- JSON 输出新增字段（如 `suggestions`），不破坏现有消费者
- Human-readable 输出新增格式选项（如 `--output markdown`）
- 支持插件化 checker（通过外部二进制调用，类似 gitleaks 模式）
