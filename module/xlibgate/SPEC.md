# xlibgate 完整规格

> 基座 · 机器门禁。import 边界、go.mod、Go baseline、release evidence 机器检查。

最后更新：2026-06-07

---

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-07
- Owner: ZoneCNH
- Layer: L0 基座
- Version: v0.1.0
- Repository: [github.com/ZoneCNH/xlibgate](https://github.com/ZoneCNH/xlibgate)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), [xlib-standard](../xlib-standard/SPEC.md)

---

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |

## 2. Summary

`xlibgate` 是 Foundation 的机器可执行门禁 CLI 工具，负责在 CI 中验证依赖矩阵、import 边界、Go baseline 和 release evidence。它消费 `xlib-standard` 定义的 Gate 和 Evidence 标准，输出标准化的 pass/fail 结果。

---

## 3. Problem

Foundation 由 70+ 个 Go 模块组成，模块间的依赖关系、import 边界和发布质量需要机器强制执行。没有统一门禁工具，会导致：

- 业务域模块反向依赖 Foundation 基座层，破坏分层架构
- 生产包意外依赖 `testkitx`，引入测试代码到生产环境
- `go.mod` 不整洁，依赖树不可重现
- Go toolchain 版本不一致，编译行为不可预测
- release evidence 散落在各 CI 脚本中，无法统一校验

---

## 4. Goals

- 提供 CLI 工具，可在 CI 和本地统一执行所有门禁检查
- import 边界扫描：检测禁止的依赖方向（生产包不依赖 testkitx，业务域不反向依赖）
- go.mod 整洁度检查：确保 `go mod tidy` 无 diff
- Go baseline 对齐：确保所有模块使用统一的 Go toolchain 版本
- release evidence 校验：收集和验证发布必需的质量证据
- 依赖矩阵验证：消费 `FOUNDATION-DEPS.yaml` 校验完整依赖关系
- 输出格式支持 JSON 和 human-readable，适配 CI artifact
- secret 扫描门禁：集成 `gitleaks` 检测泄露

---

## 5. Non-goals

- 不参与运行时（纯 CLI 工具，不被任何模块 import）
- 不是库或框架
- 不承载业务逻辑
- 不替代 CI 平台本身（只提供检查能力，不管理流水线）
- 不替代 `xlib-standard`（标准定义在 xlib-standard，机器执行在 xlibgate）
- 不做代码格式化（→ `gofmt` / `goimports`）
- 不做代码审查（→ human review + AI reviewer）

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| CI 流水线 | 在 PR check 和 release pipeline 中调用 `xlibgate check all` |
| 开发者本地 | 在提交前本地运行 `xlibgate check imports` 验证合规 |
| `x.go` release 流程 | 调用 `xlibgate check release` 收集 release evidence |
| Foundation 治理 | 通过门禁结果监控架构合规性 |

---

## 7. Functional Requirements

### FR-001: check imports

WHEN 调用 `xlibgate check imports --config deps.yaml` 且所有 import 路径符合依赖矩阵
THEN 输出 pass 结果，exit code 0

WHEN 调用 `xlibgate check imports --config deps.yaml` 且检测到禁止的 import（如业务域反向依赖基座）
THEN 输出违规详情（文件路径、行号、违规的 import 路径），exit code 1

WHEN 调用 `xlibgate check imports` 且未提供 `--config` 参数
THEN 输出错误提示，exit code 2

WHEN 配置文件中定义了 `testkitx` 边界规则且生产包 import 了 `testkitx`
THEN 输出违规详情，exit code 1

### FR-002: check gomod

WHEN 调用 `xlibgate check gomod --path ./...` 且 `go mod tidy` 无 diff
THEN 输出 pass 结果，exit code 0

WHEN 调用 `xlibgate check gomod --path ./...` 且 `go mod tidy` 产生 diff
THEN 输出 diff 详情，exit code 1

WHEN 指定路径下不存在 `go.mod` 文件
THEN 输出错误提示，exit code 2

### FR-003: check baseline

WHEN 调用 `xlibgate check baseline --expected 1.23` 且所有模块的 `go.mod` 中 `go` 指令版本一致
THEN 输出 pass 结果，exit code 0

WHEN 调用 `xlibgate check baseline --expected 1.23` 且某些模块的 Go 版本不匹配
THEN 输出不匹配的模块列表和版本差异，exit code 1

WHEN 未提供 `--expected` 参数且配置文件中未定义 `baseline.go_version`
THEN 输出错误提示，exit code 2

### FR-004: check release

WHEN 调用 `xlibgate check release --evidence evidence.json` 且所有必需 evidence 项存在且通过
THEN 输出 pass 结果，exit code 0

WHEN 调用 `xlibgate check release --evidence evidence.json` 且某些必需 evidence 项缺失或不通过
THEN 输出缺失/失败的 evidence 列表，exit code 1

WHEN evidence 文件格式无效（非 JSON 或 schema 不匹配）
THEN 输出解析错误，exit code 2

### FR-005: check all

WHEN 调用 `xlibgate check all --config deps.yaml` 且所有子检查均通过
THEN 输出汇总结果（每项子检查的 pass 状态），exit code 0

WHEN 调用 `xlibgate check all --config deps.yaml` 且任一子检查失败
THEN 输出所有失败子检查的详情，exit code 1

WHEN `check all` 执行过程中某子检查发生内部错误
THEN 跳过该子检查标记为 error，继续执行其余检查，最终 exit code 2

### FR-006: 输出格式

WHEN 未指定 `--output` 参数
THEN 默认输出 human-readable 格式（带颜色的终端输出）

WHEN 指定 `--output json`
THEN 输出 JSON 格式，包含 `status`、`checks[]`、`summary` 字段

WHEN 指定 `--output json --artifact path.json`
THEN 将 JSON 结果写入指定文件路径

---

## 8. Business Rules

| 编号 | 规则 |
|------|------|
| BR-001 | 所有检查命令返回标准化 exit code：0=pass, 1=fail, 2=error |
| BR-002 | import 边界规则从 `deps.yaml` 配置文件读取，不硬编码 |
| BR-003 | Go baseline 版本从配置或 `--expected` 参数获取，不硬编码 |
| BR-004 | release evidence 清单与 `xlib-standard` 定义的 Evidence schema 保持一致 |
| BR-005 | secret 扫描使用 `gitleaks` 作为底层工具，不自行实现扫描逻辑 |
| BR-006 | `check all` 必须执行所有子检查，即使前面的检查已失败 |
| BR-007 | JSON 输出必须包含 machine-readable 的 status 字段（pass/fail/error） |
| BR-008 | 检查结果的 human-readable 输出必须包含文件路径和行号（如有） |
| BR-009 | 依赖矩阵文件 `FOUNDATION-DEPS.yaml` 的 schema 与 `xlib-standard` 定义一致 |

---

## 9. Interface Contract

### 9.1 CLI 命令

```bash
# import 边界检查
xlibgate check imports --config deps.yaml [--output json] [--artifact result.json]

# go.mod 整洁度
xlibgate check gomod --path ./... [--output json]

# Go baseline 对齐
xlibgate check baseline --expected 1.23 [--output json]

# release evidence
xlibgate check release --evidence evidence.json [--output json]

# 全量门禁
xlibgate check all --config deps.yaml [--output json] [--artifact result.json]

# 版本
xlibgate version
```text

### 9.2 Exit Code 定义

```text
0 — pass：所有检查通过
1 — fail：至少一项检查未通过
2 — error：发生内部错误（配置无效、文件缺失等）
```text

### 9.3 JSON 输出格式

```json
{
  "status": "pass|fail|error",
  "timestamp": "2026-06-07T12:00:00Z",
  "checks": [
    {
      "name": "imports",
      "status": "pass|fail|error",
      "details": [],
      "duration_ms": 1234
    }
  ],
  "summary": {
    "total": 5,
    "passed": 5,
    "failed": 0,
    "errors": 0
  }
}
```text

### 9.4 配置格式

```yaml
# xlibgate.yaml
baseline:
  go_version: "1.23"

imports:
  forbidden:
    - source: "github.com/ZoneCNH/testkitx"
      targets: ["*"]
    - source: "github.com/ZoneCNH/binance"
      targets: ["github.com/ZoneCNH/kernel", "github.com/ZoneCNH/configx"]

release:
  require:
    - test_coverage >= 80%
    - race_test_pass
    - secret_scan_pass
    - gomod_tidy
    - vet_clean
```text

---

## 10. Data Model

### 10.1 公共错误

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
```text

### 10.2 检查结果结构

```go
type CheckResult struct {
    Name       string        `json:"name"`
    Status     CheckStatus   `json:"status"`
    Details    []Violation   `json:"details,omitempty"`
    DurationMs int64         `json:"duration_ms"`
}

type CheckStatus string

const (
    StatusPass  CheckStatus = "pass"
    StatusFail  CheckStatus = "fail"
    StatusError CheckStatus = "error"
)

type Violation struct {
    File    string `json:"file"`
    Line    int    `json:"line,omitempty"`
    Message string `json:"message"`
}
```text

---

## 11. Config Schema

```yaml
# xlibgate.yaml 完整 schema
baseline:
  go_version: string          # required，期望的 Go 版本（如 "1.23"）

imports:
  forbidden:                  # 禁止的 import 规则列表
    - source: string          # 源包路径（支持通配符）
      targets: [string]       # 禁止 import 的目标包（["*"] 表示所有）

release:
  require: [string]           # 必需的 release evidence 条件列表

secret_scan:
  enabled: bool               # default: true
  config_path: string         # gitleaks 配置文件路径（可选）
```text

---

## 12. Error Handling

| 错误 | 调用方处理 |
|------|-----------|
| `ErrConfigInvalid` | 检查 YAML 语法和 schema，修复配置文件 |
| `ErrConfigMissing` | 确认 `--config` 参数路径正确，或在项目根目录放置 `xlibgate.yaml` |
| `ErrEvidenceInvalid` | 检查 evidence JSON 格式，确认与 schema 匹配 |
| `ErrEvidenceMissing` | 运行对应的 CI 步骤生成缺失的 evidence |
| `ErrBaselineMismatch` | 更新模块的 `go.mod` 中 `go` 指令版本，或更新 baseline 配置 |
| `ErrImportViolation` | 移除违规的 import 语句，调整模块依赖关系 |
| `ErrGomodDirty` | 运行 `go mod tidy` 并提交变更 |

**错误消息格式：** `"xlibgate: <check>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| 配置文件为空 | 使用默认值（无 forbidden 规则、无 baseline 要求） |
| 配置文件只有注释 | 同上，视为空配置 |
| `--path` 指向不存在的目录 | 输出错误提示，exit code 2 |
| `--path` 指向非 Go 项目（无 go.mod） | 输出错误提示，exit code 2 |
| import 路径包含 vendor 目录 | 跳过 vendor 目录，只扫描项目自身代码 |
| Go 模块使用 replace 指令 | baseline 检查只验证 `go` 指令版本，不检查 replace |
| evidence 文件超大（>100MB） | 正常解析，内存 < 文件大小 2x |
| 并发运行多个 `xlibgate` 实例 | 各实例独立，无状态冲突 |
| `check all` 中某子检查超时 | 标记为 error，继续执行其余检查 |
| CI 环境无 color 支持 | 自动检测终端，无 color 时输出纯文本 |

---

## 14. Directory Structure

```text
xlibgate/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── main.go                     # CLI 入口
├── cmd/
│   ├── root.go                 # root 命令和全局 flags
│   ├── check.go                # check 父命令
│   ├── imports.go              # check imports 子命令
│   ├── gomod.go                # check gomod 子命令
│   ├── baseline.go             # check baseline 子命令
│   ├── release.go              # check release 子命令
│   └── all.go                  # check all 子命令
├── scanner/
│   ├── imports.go              # import 边界扫描器
│   ├── gomod.go                # go.mod 整洁度检查器
│   └── baseline.go             # Go baseline 检查器
├── evidence/
│   ├── collector.go            # evidence 收集
│   └── validator.go            # evidence 校验
├── config.go                   # 配置加载和解析
├── report.go                   # 报告生成（JSON + human-readable）
├── errors.go                   # 公共错误变量
├── internal/
│   ├── gomod/                  # go.mod 解析工具
│   └── ast/                    # Go AST 解析工具
├── testdata/
│   ├── config.yaml
│   ├── deps.yaml
│   ├── evidence.json
│   └── fixtures/
├── example_test.go
├── benchmark_test.go
└── integration_test.go         # //go:build integration
```text

---

## 15. Dependencies

### 15.1 go.mod

```text
module github.com/ZoneCNH/xlibgate

go 1.23
```text

### 15.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| stdlib | 所有 Foundation 运行时模块（kernel, configx, observex 等） |
| `gopkg.in/yaml.v3`（配置解析） | 所有业务域实现 |
| Go AST 解析库（`go/parser`, `go/ast`） | 所有 L2.5 领域共享层 |
| `gitleaks`（secret 扫描，作为外部命令调用） | |

### 15.3 特殊说明

xlibgate 是纯 CLI 工具，不被任何模块 import。它只扫描其他模块的代码，不产生运行时依赖。

---

## 16. Testing

### 16.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| import 违规检测 | 业务域反向依赖 Foundation → 报错，含文件路径和行号 |
| testkitx 边界 | 生产包依赖 testkitx → 报错 |
| import 合规 | 符合依赖矩阵 → pass |
| go.mod 不整洁 | `go mod tidy` 有 diff → 报错 |
| go.mod 整洁 | `go mod tidy` 无 diff → pass |
| baseline 不匹配 | go.mod 中 go 版本 != expected → 报错 |
| baseline 匹配 | go.mod 中 go 版本 == expected → pass |
| release evidence 缺失 | 必需 evidence 项缺失 → 报错 |
| release evidence 完整 | 所有必需 evidence 项存在且通过 → pass |
| config 解析 | 有效 YAML → 正确加载 |
| config 无效 | 语法错误 → ErrConfigInvalid |
| config 缺失 | 文件不存在 → ErrConfigMissing |
| exit code | pass=0, fail=1, error=2 |
| JSON 输出 | 格式正确，包含所有必需字段 |
| human-readable 输出 | 包含文件路径和行号 |

### 16.2 Given/When/Then 用例

**TC-001: import 边界违规**
Given 配置禁止业务域 import 基座层
When 扫描到 `binance` import 了 `kernel`
Then 输出违规详情（文件路径、行号），exit code 1

**TC-002: go.mod 整洁**
Given 项目 go.mod 已 tidy
When 运行 `check gomod`
Then 输出 pass，exit code 0

**TC-003: baseline 不匹配**
Given 配置要求 Go 1.23，某模块 go.mod 指定 1.22
When 运行 `check baseline --expected 1.23`
Then 输出不匹配模块列表，exit code 1

**TC-004: check all 部分失败**
Given imports 检查失败，gomod 检查通过
When 运行 `check all`
Then 输出所有子检查结果，imports 为 fail，gomod 为 pass，exit code 1

**TC-005: check all 某子检查 error**
Given imports 检查正常，baseline 检查因配置缺失报 error
When 运行 `check all`
Then imports 结果正常输出，baseline 标记为 error，继续执行其余检查，exit code 2

**TC-006: check release evidence**
Given release evidence 文件存在且 schema 合法
When 运行 `check release`
Then 输出 pass，exit code 0

**TC-007: 输出格式**
Given 检查结果包含 pass、fail 和 error
When 使用 JSON 输出
Then 输出包含 check、status、message 和 evidence 字段

### 16.3 Benchmark

| 场景 | 目标 |
|------|------|
| 全量门禁（50 模块） | < 30s |
| import 扫描（50 模块） | < 10s |
| go.mod 检查（50 模块） | < 5s |
| baseline 检查（50 模块） | < 5s |
| JSON 报告生成 | < 100ms |

### 16.4 集成测试

| 场景 | 验证点 |
|------|--------|
| 完整 CI 流程 | `check all` → 所有子检查执行 → 汇总报告 |
| 自检 | `xlibgate check all --config xlibgate.yaml` → pass |
| CI artifact 输出 | `--artifact result.json` → 文件写入且格式正确 |

---

## 17. Performance Budget

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| 全量门禁（50 模块） | < 30s | benchmark test |
| import 扫描（50 模块） | < 10s | benchmark test |
| go.mod 检查（50 模块） | < 5s | benchmark test |
| baseline 检查（50 模块） | < 5s | benchmark test |
| JSON 报告生成 | < 100ms | benchmark test |
| 内存占用 | < 100MB | profiling |

---

## 18. Observability

| 类型 | 名称 | 说明 |
|------|------|------|
| log | `xlibgate.check.started` | info，检查开始，含 check name |
| log | `xlibgate.check.completed` | info，检查完成，含 status 和 duration |
| log | `xlibgate.check.failed` | warn，检查失败，含 violation 详情 |
| log | `xlibgate.check.error` | error，检查出错，含 error message |
| log | `xlibgate.config.loaded` | info，配置加载完成，含文件路径 |

---

## 19. Security

| 要求 | 实现方式 |
|------|----------|
| secret 扫描 | 集成 `gitleaks`，扫描所有源文件 |
| 配置文件不泄露敏感数据 | 配置文件只包含规则定义，不含密钥 |
| 错误消息不泄露文件内容 | 错误消息只包含文件路径和行号，不包含源代码 |

---

## 20. CI Gate

### 20.1 通用 Gate

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

### 20.2 xlibgate 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 自检 | `xlibgate check all --config xlibgate.yaml` | 自身门禁不通过 |
| 不依赖 Foundation 运行时 | `go list -deps ./... \| grep "ZoneCNH/kernel\|ZoneCNH/configx\|ZoneCNH/observex"` | 依赖运行时模块 |

---

## 21. Upgrade Compatibility

| 变更类型 | 版本升级 |
|----------|----------|
| CLI 命令结构变更（子命令增删） | **minor** |
| exit code 语义变更 | **major** |
| JSON 输出格式变更（字段增删） | **minor** |
| JSON 输出格式变更（字段重命名/删除） | **major** |
| 配置 schema 变更（新增可选字段） | **minor** |
| 配置 schema 变更（新增必填字段） | **minor**（带默认值） |
| 配置 schema 变更（字段删除/重命名） | **major** |
| 新增检查子命令 | **minor** |

---

## 22. Release DoD

- [ ] CLI 帮助文档完整（`--help` 输出所有子命令和参数）
- [ ] 所有 check 子命令有使用示例
- [ ] exit code 文档化
- [ ] JSON 输出格式文档化（含示例）
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、配置说明、CLI 参考
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] Secret 扫描通过
- [ ] 自检通过（`xlibgate check all`）
- [ ] 所有 Functional Requirements 有对应测试
- [ ] 所有 Edge Cases 有对应测试

---

## 23. Open Questions

- 是否需要支持增量扫描（只扫描变更文件）？当前为全量扫描。
- 是否需要支持自定义检查插件（用户定义的门禁规则）？
- import 边界规则是否需要支持正则表达式匹配？
- 是否需要支持多配置文件合并（如项目级 + 组织级配置）？
- release evidence 是否需要支持从远程 URL 获取？
