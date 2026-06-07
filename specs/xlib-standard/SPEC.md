# xlib-standard 完整规格

> 基座 · 标准事实源。标准事实源、Go Reference Template、Gate 与 Evidence 定义。

最后更新：2026-06-07

---

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-07
- Owner: ZoneCNH
- Layer: L0 基座
- Version: v0.1.0
- Repository: [github.com/ZoneCNH/xlib-standard](https://github.com/ZoneCNH/xlib-standard)
- Related: [CONSTITUTION.md](../CONSTITUTION.md), [ARCHITECTURE.md](../ARCHITECTURE.md), [xlibgate](../xlibgate/SPEC.md)

---

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |

## 2. Summary

`xlib-standard` 是 Foundation 的标准事实源，定义模块应该长什么样、怎么测试、怎么发布。它不参与运行时，不被任何生产代码 import。它是文档和模板集合，为 `xlibgate` 提供 Gate 和 Evidence 的标准定义，为新模块提供 Go Reference Template。

---

## 3. Problem

Foundation 由 70+ 个 Go 模块组成，如果没有统一标准，会导致：
- 模块目录结构不一致，新人上手成本高
- 命名规范散落在口头约定中，无法机器校验
- 错误格式不统一，日志聚合困难
- Gate 和 Evidence 定义与机器执行脱节
- 新模块创建时缺少可复用的骨架模板

---

## 4. Goals

- 定义 Foundation 模块的完整标准：命名、错误、接口、目录、配置
- 提供 Go Reference Template，新模块可一键生成合规骨架
- 定义 Gate 清单（CI gate 标准和阈值），与 `xlibgate` 机器执行保持一致
- 定义 Evidence 清单（release evidence 标准），与 CI artifact 格式保持一致
- 提供模块骨架生成器（`init.sh`）
- 作为所有 Foundation 模块的唯一标准来源（single source of truth）

---

## 5. Non-goals

- 不是运行时依赖（不被任何 Go 模块 import）
- 不承载业务逻辑
- 不替代 `xlibgate`（机器执行在 xlibgate，标准定义在 xlib-standard）
- 不替代 `testkitx`（测试工具）
- 不做代码审查（→ human review + AI reviewer）
- 不做 CI 平台管理
- 不编译、不测试、不发布为 Go 包

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| `xlibgate` | 消费 Gate 和 Evidence 定义，用于机器门禁执行 |
| 新模块创建者 | 使用 Go Reference Template 生成模块骨架 |
| Foundation 贡献者 | 参考标准规范编写合规代码 |
| CI 流水线 | 参考 Gate 清单配置检查步骤 |
| AI 代理 | 参考标准规范进行代码生成和审查 |

---

## 7. Functional Requirements

### FR-001: 命名规范

WHEN 创建 Foundation Go 模块
THEN 包名使用小写无下划线（如 `configx`、`observex`）
AND 指标前缀使用 `foundationx_`
AND 公共函数/类型使用 PascalCase
AND 私有函数/类型使用 camelCase

WHEN 命名与标准不符
THEN `xlibgate` 的 lint 检查应能检测并报错

### FR-002: 错误规范

WHEN 定义公共错误
THEN 格式为 `errors.New("module: description")`（小写，冒号分隔）
AND 错误变量使用 `Err` 前缀（如 `ErrConfigInvalid`）
AND 使用 `%w` 包装底层错误

WHEN 错误格式不符合规范
THEN `xlibgate` 的 lint 检查应能检测并报错

### FR-003: 接口规范

WHEN 定义跨域接口
THEN 接口保持窄（3-5 个方法）
AND 接口有 godoc 注释
AND 实现方有编译期检查（`var _ Interface = (*Impl)(nil)`）

WHEN 接口方法超过 5 个
THEN 应考虑拆分为多个窄接口

### FR-004: 目录规范

WHEN 创建新模块
THEN 目录结构遵循 Go Reference Template
AND 实现细节放在 `internal/` 目录
AND 测试数据放在 `testdata/` 目录
AND 公共 API 在包根目录

WHEN 目录结构不符合模板
THEN `xlibgate` 的结构检查应能检测并报错

### FR-005: 配置规范

WHEN 模块需要配置
THEN 使用 YAML schema 定义配置结构
AND 支持环境变量覆盖（前缀 + 下划线映射）
AND 配置键使用点分路径（如 `data.market.symbol`）

WHEN 配置格式不符合规范
THEN 启动时应 fail-fast

### FR-006: Gate 定义

WHEN 定义模块的 CI Gate
THEN 必须包含：编译、测试、覆盖率（≥80%）、vet、lint、依赖检查、Secret 扫描
AND 可选包含：Benchmark、自检
AND Gate 标准与 `xlibgate` 配置保持一致

WHEN Gate 标准与 `xlibgate` 不一致
THEN 以 `xlib-standard` 定义为准，`xlibgate` 需同步更新

### FR-007: Evidence 定义

WHEN 定义模块的 Release Evidence
THEN 必需 evidence 包含：test_coverage（JSON）、race_test（boolean）、secret_scan（JSON）
AND 可选 evidence 包含：benchmark（text）、dependency_graph（DOT/JSON）
AND Evidence schema 与 CI artifact 格式保持一致

WHEN Evidence 格式变更
THEN 需要同步更新 schema 和 CI 流水线

### FR-008: 模块骨架生成

WHEN 运行 `init.sh <module-name> [--layer L0|L1|L2]`
THEN 生成符合 Go Reference Template 的完整目录结构
AND 生成的模块可直接编译通过
AND 生成的 `go.mod` 使用正确的 module path 和 Go 版本

WHEN 模块名已存在
THEN 输出错误提示，不覆盖

---

## 8. Business Rules

| 编号 | 规则 |
|------|------|
| BR-001 | `xlib-standard` 是标准的唯一来源（single source of truth） |
| BR-002 | Gate 定义必须与 `xlibgate` 配置保持一致 |
| BR-003 | Evidence schema 必须与 CI artifact 格式保持一致 |
| BR-004 | Go Reference Template 必须生成可编译的模块骨架 |
| BR-005 | 标准变更需要同步更新 `xlibgate` 和 CI 流水线 |
| BR-006 | 标准规范文档必须包含正例和反例 |
| BR-007 | 模块命名不使用下划线（Go 惯例） |
| BR-008 | 错误格式必须是 `"module: description"` 小写格式 |
| BR-009 | 接口宽度不超过 5 个方法 |
| BR-010 | 所有标准规范必须有对应的机器检查手段（在 `xlibgate` 中实现） |

---

## 9. Interface Contract

### 9.1 标准规范文档

```
specs/
├── naming.md           # 命名规范
├── errors.md           # 错误规范
├── interfaces.md       # 接口规范
├── directory.md        # 目录规范
└── config.md           # 配置规范
```

### 9.2 Gate 定义

```yaml
# gates/common.yaml
gates:
  - name: build
    command: "go build ./..."
    blocking: true
  - name: test
    command: "go test ./... -race -count=1"
    blocking: true
  - name: coverage
    command: "go test ./... -coverprofile=cover.out && go tool cover -func=cover.out"
    threshold: ">= 80%"
    blocking: true
  - name: vet
    command: "go vet ./..."
    blocking: true
  - name: lint
    command: "golangci-lint run"
    blocking: true
  - name: dependency
    command: "go mod tidy && git diff --exit-code go.mod go.sum"
    blocking: true
  - name: secret_scan
    command: "gitleaks detect --no-git"
    blocking: true
  - name: benchmark
    command: "go test -bench=. -benchmem -count=3 ./..."
    blocking: false
```

### 9.3 Evidence Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["test_coverage", "race_test", "secret_scan"],
  "properties": {
    "test_coverage": {
      "type": "object",
      "required": ["total"],
      "properties": {
        "total": { "type": "number", "minimum": 0, "maximum": 100 },
        "per_package": { "type": "object" }
      }
    },
    "race_test": { "type": "boolean" },
    "secret_scan": {
      "type": "object",
      "required": ["findings"],
      "properties": {
        "findings": { "type": "array" }
      }
    },
    "benchmark": { "type": "string" },
    "dependency_graph": { "type": "object" }
  }
}
```

### 9.4 模块骨架生成器

```bash
# 生成新模块
./scripts/init.sh my-module --layer L1

# 生成的目录结构
my-module/
├── go.mod
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── my_module.go
├── errors.go
├── options.go
├── internal/
├── testdata/
├── example_test.go
└── integration_test.go
```

---

## 10. Data Model

### 10.1 标准版本

```go
const (
    StandardVersion = "1.0.0"
    MinGoVersion    = "1.23"
    MinCoverage     = 80  // 百分比
)
```

### 10.2 Layer 定义

```go
type Layer string

const (
    LayerL0 Layer = "L0"  // 基座原语层（stdlib-only）
    LayerL1 Layer = "L1"  // 基础能力层
    LayerL2 Layer = "L2"  // 业务域层
)
```

---

## 11. Config Schema

`xlib-standard` 自身不加载配置。它的产出物（Gate 定义、Evidence schema、模板）是其他工具的配置输入。

Gate 定义文件 `gates/common.yaml` 的 schema：

```yaml
gates:
  - name: string          # required，gate 名称
    command: string        # required，执行命令
    blocking: bool         # required，是否阻塞
    threshold: string      # 可选，阈值条件（如 ">= 80%"）
    description: string    # 可选，gate 描述
```

---

## 12. Error Handling

| 错误场景 | 处理方式 |
|----------|----------|
| 模板生成时目标目录已存在 | 输出错误提示，不覆盖 |
| 模板生成时权限不足 | 输出权限错误提示 |
| 标准规范文档格式错误 | 文档 lint 检查报错 |
| Gate 定义与 `xlibgate` 不一致 | CI 中的同步检查报错 |
| Evidence schema 与 CI artifact 不匹配 | `xlibgate check release` 报错 |

**错误消息格式：** `"xlib-standard: <operation>: <detail>"`

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| 模块名包含大写字母 | 拒绝，Go 包名不允许大写 |
| 模块名包含下划线 | 拒绝，Go 惯例不使用下划线 |
| 模块名与已有模块冲突 | 输出错误提示 |
| 模板中 Go 版本低于 MinGoVersion | 使用 MinGoVersion |
| Gate 定义文件为空 | 使用默认 Gate 清单 |
| Evidence schema 更新后旧 CI artifact 不兼容 | 提供迁移指南 |
| 标准规范文档有歧义 | 以代码示例为准，文档补充说明 |
| `init.sh` 在非 Unix 环境运行 | 提供 PowerShell 等价脚本或提示使用 WSL |

---

## 14. Directory Structure

```
xlib-standard/
├── README.md
├── CHANGELOG.md
├── LICENSE
├── template/                   # Go Reference Template
│   ├── go.mod.tmpl
│   ├── README.md.tmpl
│   ├── CHANGELOG.md.tmpl
│   ├── doc.go.tmpl
│   ├── module.go.tmpl
│   ├── errors.go.tmpl
│   ├── options.go.tmpl
│   ├── example_test.go.tmpl
│   └── integration_test.go.tmpl
├── specs/                      # 标准规范文档
│   ├── naming.md               # 命名规范
│   ├── errors.md               # 错误规范
│   ├── interfaces.md           # 接口规范
│   ├── directory.md            # 目录规范
│   └── config.md               # 配置规范
├── gates/                      # Gate 定义
│   ├── common.yaml             # 通用 Gate 清单
│   └── module-specific/        # 模块专属 Gate
│       ├── kernel.yaml
│       └── contracts.yaml
├── evidence/                   # Evidence 定义
│   └── schema.json             # Evidence JSON schema
└── scripts/
    └── init.sh                 # 模块骨架生成器
```

---

## 15. Dependencies

### 15.1 特殊说明

`xlib-standard` 不是 Go 模块，没有 `go.mod`。它是文档和模板集合，不编译、不测试、不发布为 Go 包。

### 15.2 依赖方向

| 依赖关系 | 说明 |
|----------|------|
| `xlibgate` → `xlib-standard` | `xlibgate` 消费 Gate 和 Evidence 定义 |
| 所有 Foundation 模块 → `xlib-standard` | 参考标准规范 |
| `xlib-standard` → 无 | 不依赖任何模块 |

---

## 16. Testing

### 16.1 模板验证

| 测试场景 | 验证点 |
|----------|--------|
| 模板生成可编译 | `init.sh` 生成的模块 `go build ./...` 通过 |
| 模板生成可测试 | `init.sh` 生成的模块 `go test ./...` 通过 |
| 模板符合标准 | 生成的模块通过 `xlibgate check all` |
| 模板 Go 版本 | 生成的 go.mod 使用 MinGoVersion |

### 16.2 标准一致性验证

| 测试场景 | 验证点 |
|----------|--------|
| Gate 定义与 xlibgate 一致 | `gates/common.yaml` 与 `xlibgate.yaml` 的检查项匹配 |
| Evidence schema 与 CI artifact 一致 | CI 产出的 artifact 符合 `evidence/schema.json` |
| 标准规范文档有示例 | 每条规范至少有一个正例和一个反例 |

### 16.3 Given/When/Then 用例

**TC-001: 生成新模块**
Given 运行 `init.sh my-module --layer L1`
When 检查生成的目录结构
Then 包含 go.mod、README.md、CHANGELOG.md、LICENSE、doc.go、my_module.go、errors.go、options.go、internal/、testdata/

**TC-002: 模板可编译**
Given 运行 `init.sh test-module --layer L0`
When 在生成目录运行 `go build ./...`
Then 编译成功

**TC-003: Gate 定义一致性**
Given `gates/common.yaml` 定义了 8 项 Gate
When 对比 `xlibgate.yaml` 的检查项
Then 两者完全匹配

---

## 17. Performance Budget

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| 模块骨架生成 | < 5s | 手动计时 |
| 标准规范文档渲染 | < 1s | 手动计时 |

---

## 18. Observability

| 类型 | 名称 | 说明 |
|------|------|------|
| log | `xlib-standard.init.started` | info，模块生成开始 |
| log | `xlib-standard.init.completed` | info，模块生成完成 |
| log | `xlib-standard.init.error` | error，模块生成失败 |

---

## 19. Security

| 要求 | 实现方式 |
|------|----------|
| 模板不包含硬编码密钥 | 模板中使用占位符，不包含真实密钥 |
| 生成脚本不执行任意代码 | `init.sh` 只做文件复制和模板替换 |

---

## 20. CI Gate

### 20.1 标准一致性 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 模板可编译 | `init.sh test-module --layer L1 && cd test-module && go build ./...` | 编译失败 |
| 模板可测试 | `cd test-module && go test ./...` | 测试失败 |
| Gate 定义一致性 | `diff <(yq '.gates[].name' gates/common.yaml) <(yq '.gates[].name' ../xlibgate/gates/common.yaml)` | 不一致 |
| 文档格式 | markdown lint | 格式错误 |

---

## 21. Upgrade Compatibility

| 变更类型 | 版本升级 |
|----------|----------|
| 标准规范内容变更（新增规范） | **minor** |
| 标准规范内容变更（修改现有规范） | **major**（需评估影响） |
| Gate 清单新增项 | **minor** |
| Gate 清单删除/修改项 | **major** |
| Evidence schema 新增可选字段 | **minor** |
| Evidence schema 新增必填字段 | **minor**（带默认值） |
| Evidence schema 删除/修改字段 | **major** |
| 模板结构变更 | **minor** |
| Go Reference Template 生成的目录结构变更 | **minor** |

---

## 22. Release DoD

- [ ] 所有标准规范文档有正例和反例
- [ ] Go Reference Template 生成的模块可编译通过
- [ ] Go Reference Template 生成的模块通过 `xlibgate check all`
- [ ] Gate 定义与 `xlibgate` 配置一致
- [ ] Evidence schema 与 CI artifact 格式一致
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、标准概览、贡献指南

---

## 23. Open Questions

- 标准规范是否需要支持版本化（v1、v2 并存）？
- 模板是否需要支持多种语言（如 TypeScript、Python）？
- Gate 定义是否需要支持条件阻塞（如某些 Gate 只在 release 时阻塞）？
- Evidence 是否需要支持签名验证（防止篡改）？
- 模块骨架生成器是否需要支持增量更新（同步标准变更到已有模块）？
