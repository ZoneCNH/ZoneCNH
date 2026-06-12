# xlibgate 发布版本 1.0 Goal 定位与实现标准

| 字段 | 内容 |
| --- | --- |
| 模块名 | `xlibgate` |
| 发布版本 | 1.0.0 |
| 所属层级 | L0 基座 — 门禁 |
| 稳定级别 | CLI 接口 Stable；JSON 输出 Stable；Exit Code Stable；配置 Schema Stable |
| 文档状态 | 1.0 发布基线文档 |
| 发布日期基准 | 2026-06-09 |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 1.0 发布判定原则

1. **稳定优先**：CLI 命令结构、exit code 语义、JSON 输出格式、配置 schema 一旦进入 1.0，默认需要向后兼容。
2. **边界清晰**：xlibgate 只做机器门禁检查，不侵入业务域，不替代 xlib-standard 的标准定义角色。
3. **证据完整**：每个 MUST 能力都必须有单元测试、集成测试或 benchmark 证明。
4. **零运行时依赖**：不依赖任何 Foundation 运行时模块（kernel、configx、observex、resiliencx 等），仅依赖 stdlib + yaml.v3 + Go AST + gitleaks 外部命令。
5. **可演进**：1.0 允许保留扩展点（如自定义检查插件），但不得把未稳定能力包装成稳定承诺。

## 1. Goal 定位

`xlibgate` 的 Goal 是作为 Foundation 的机器可执行门禁 CLI 工具，在 CI 中验证依赖矩阵、import 边界、Go baseline 和 release evidence。它消费 `xlib-standard` 定义的 Gate 和 Evidence 标准，输出标准化的 pass/fail 结果。

**与 xlib-standard 的关系**：xlib-standard 定义标准（规范文档、Gate 定义、Evidence schema），xlibgate 机器执行（扫描代码、校验合规、输出结果）。两者互补：标准归 xlib-standard，执行归 xlibgate。

### 1.1 为什么需要这个模块

- Foundation 由 70+ 个 Go 模块组成，模块间的依赖关系、import 边界和发布质量需要机器强制执行。
- 没有统一门禁工具时，业务域模块可能反向依赖基座层，破坏分层架构。
- 生产包可能意外依赖 `testkitx`，引入测试代码到生产环境。
- `go.mod` 不整洁导致依赖树不可重现，Go toolchain 版本不一致导致编译行为不可预测。
- release evidence 散落在各 CI 脚本中，无法统一校验。

### 1.2 1.0 要解决的问题

- 提供 CLI 工具，在 CI 和本地统一执行所有门禁检查。
- import 边界扫描：检测禁止的依赖方向（生产包不依赖 testkitx，业务域不反向依赖基座）。
- go.mod 整洁度检查：确保 `go mod tidy` 无 diff。
- Go baseline 对齐：确保所有模块使用统一的 Go toolchain 版本。
- release evidence 校验：收集和验证发布必需的质量证据。
- 依赖矩阵验证：消费 `FOUNDATION-DEPS.yaml` 校验完整依赖关系。
- 输出格式支持 JSON 和 human-readable，适配 CI artifact。
- secret 扫描门禁：集成 `gitleaks` 检测泄露。

### 1.3 目标用户

- CI 流水线（PR check 和 release pipeline 中调用 `xlibgate check all`）
- 开发者本地（提交前运行 `xlibgate check imports` 验证合规）
- `x.go` release 流程（调用 `xlibgate check release` 收集 release evidence）
- Foundation 治理（通过门禁结果监控架构合规性）

## 2. 1.0 发布目标

- MUST 提供 `check imports` 子命令，扫描 import 边界违规。
- MUST 提供 `check gomod` 子命令，检查 `go mod tidy` 整洁度。
- MUST 提供 `check baseline` 子命令，校验 Go toolchain 版本一致性。
- MUST 提供 `check release` 子命令，验证 release evidence。
- MUST 提供 `check all` 子命令，串联执行所有子检查。
- MUST 输出标准化 exit code：0=pass, 1=fail, 2=error。
- MUST 支持 `--output json` 输出 JSON 格式结果。
- MUST 集成 `gitleaks` 进行 secret 扫描。
- MUST 消费 `FOUNDATION-DEPS.yaml` 配置文件，不硬编码依赖规则。
- SHOULD 支持 `--artifact` 参数将 JSON 结果写入文件。

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| import 边界检查 | CI 检测到业务域模块 import 了基座层 | 输出违规详情（文件路径、行号），exit code 1 |
| import 边界合规 | 所有 import 路径符合依赖矩阵 | 输出 pass，exit code 0 |
| go.mod 整洁 | `go mod tidy` 无 diff | 输出 pass，exit code 0 |
| go.mod 不整洁 | `go mod tidy` 产生 diff | 输出 diff 详情，exit code 1 |
| baseline 不匹配 | 某模块 go.mod 中 Go 版本 != 期望版本 | 输出不匹配模块列表，exit code 1 |
| release evidence 缺失 | 必需 evidence 项缺失 | 输出缺失项列表，exit code 1 |
| 全量门禁 | CI 执行 `check all` | 所有子检查执行，汇总结果，任一失败则 exit code 1 |
| 配置缺失 | 未提供 `--config` 参数或无配置文件 | 输出错误提示，exit code 2 |
| Secret 泄露 | gitleaks 检测到硬编码密钥 | 输出泄露位置，exit code 1 |

## 4. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| check imports | 扫描 import 路径，匹配依赖矩阵规则，输出违规文件路径和行号 | 违规检测测试通过；合规测试通过 |
| check gomod | 对指定路径执行 `go mod tidy` 并检测 diff | tidy 测试通过；dirty 测试通过 |
| check baseline | 读取 go.mod 中 `go` 指令，与期望版本比对 | 匹配测试通过；不匹配测试通过 |
| check release | 解析 evidence JSON，校验必需项存在且通过 | 完整测试通过；缺失测试通过 |
| check all | 串联所有子检查，即使前置检查失败也继续执行 | 部分失败测试通过；error 跳过测试通过 |
| 输出格式 | human-readable（默认，含颜色）和 JSON（`--output json`）两种输出 | JSON schema 校验通过；终端输出含路径和行号 |
| 配置加载 | 从 `xlibgate.yaml` 或 `--config` 指定文件加载规则 | 有效配置测试通过；无效配置报错测试通过 |
| secret 扫描 | 调用 `gitleaks` 检测源文件中的密钥泄露 | 泄露检测测试通过 |

## 5. 职责边界

### 5.1 模块内职责

- 提供 CLI 工具，在 CI 和本地统一执行所有门禁检查。
- import 边界扫描：基于 `FOUNDATION-DEPS.yaml` 检测禁止的依赖方向。
- go.mod 整洁度检查：确保 `go mod tidy` 无 diff。
- Go baseline 对齐：确保所有模块使用统一的 Go toolchain 版本。
- release evidence 校验：收集和验证发布必需的质量证据。
- 依赖矩阵验证：消费 `FOUNDATION-DEPS.yaml` 校验完整依赖关系。
- 输出标准化 pass/fail 结果，支持 JSON 和 human-readable 格式。
- 集成 `gitleaks` 进行 secret 扫描。

### 5.2 明确非目标

- 不参与运行时（纯 CLI 工具，不被任何模块 import）。
- 不是 API Gateway，不处理 HTTP 路由或流量转发。
- 不承载业务逻辑。
- 不替代 CI 平台本身（只提供检查能力，不管理流水线）。
- 不替代 `xlib-standard`（标准定义在 xlib-standard，机器执行在 xlibgate）。
- 不做代码格式化（→ `gofmt` / `goimports`）。
- 不做代码审查（→ human review + AI reviewer）。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 上游依赖 | 仅依赖 stdlib + `gopkg.in/yaml.v3`（配置解析）+ Go AST 标准库（`go/parser`、`go/ast`）+ `gitleaks`（作为外部命令调用）。禁止依赖所有 Foundation 运行时模块（kernel、configx、observex、resiliencx、schedulex 等）和所有业务域实现。 |
| 下游依赖 | 不被任何模块 import。xlibgate 是纯 CLI 工具，只扫描其他模块的代码，不产生运行时依赖。 |
| 分层约束 | L0 基座 — 门禁。xlibgate 只读取和检查其他模块，不向任何模块提供 API 或库函数。 |
| 契约依赖 | 消费 `xlib-standard` 定义的 Gate 定义、Evidence schema 和 `FOUNDATION-DEPS.yaml` 格式。不向 `contracts` 登记运行时 API（因为无运行时 API）。 |

## 7. 对外契约

### 7.1 公开能力面

| 契约 | 定位 | 1.0 稳定承诺 |
| --- | --- | --- |
| CLI 命令结构 | `xlibgate check <imports\|gomod\|baseline\|release\|all>` | 子命令名称和参数集合稳定 |
| exit code 语义 | 0=pass, 1=fail, 2=error | 语义稳定，不可变更 |
| JSON 输出格式 | `status`、`timestamp`、`checks[]`、`summary` 字段 | 字段集合稳定，允许追加可选字段 |
| 配置文件 schema | `xlibgate.yaml`（baseline / imports / release / secret_scan） | 字段集合稳定，允许追加可选字段 |
| 版本命令 | `xlibgate version` | 输出格式稳定 |

### 7.2 1.0 CLI 接口基线

```text
xlibgate
  check imports --config deps.yaml [--output json] [--artifact result.json]
  check gomod --path ./... [--output json]
  check baseline --expected 1.23 [--output json]
  check release --evidence evidence.json [--output json]
  check all --config deps.yaml [--output json] [--artifact result.json]
  version
```

### 7.3 Exit Code 定义

```text
0 — pass：所有检查通过
1 — fail：至少一项检查未通过
2 — error：发生内部错误（配置无效、文件缺失等）
```

### 7.4 JSON 输出格式

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
```

## 8. 配置契约

| 配置项 | 含义 | 默认值 / 要求 | 稳定性 |
| --- | --- | --- | --- |
| baseline.go_version | 期望的 Go 版本 | 必填，无默认值 | Stable |
| imports.forbidden | 禁止的 import 规则列表（source + targets） | 可选，空列表表示不检查 | Stable |
| release.require | 必需的 release evidence 条件列表 | 可选，空列表表示不检查 | Stable |
| secret_scan.enabled | 是否启用 gitleaks 扫描 | true | Stable |
| secret_scan.config_path | gitleaks 配置文件路径 | 可选 | Stable |

配置从 `xlibgate.yaml` 或 `--config` 指定的文件加载。配置文件只包含规则定义，不含密钥。

## 9. 可观测契约

### 9.1 日志

xlibgate 是 CLI 工具，不产生运行时日志。执行过程中输出以下事件到 stderr：

| 事件 | 级别 | 说明 |
| --- | --- | --- |
| xlibgate.check.started | info | 检查开始，含 check name |
| xlibgate.check.completed | info | 检查完成，含 status 和 duration |
| xlibgate.check.failed | warn | 检查失败，含 violation 详情 |
| xlibgate.check.error | error | 检查出错，含 error message |
| xlibgate.config.loaded | info | 配置加载完成，含文件路径 |

### 9.2 指标

xlibgate 是纯 CLI 工具，不承载业务运行，不产生运行时指标。检查耗时通过 JSON 输出中的 `duration_ms` 字段暴露。

### 9.3 诊断输出

- human-readable 模式输出到 stdout，包含文件路径和行号。
- JSON 模式输出到 stdout 或 `--artifact` 指定的文件。
- 所有检查结果均可机器解析。

## 10. 错误模型与失败策略

| 错误 | 错误类别 | 典型原因 | 1.0 处理策略 |
| --- | --- | --- | --- |
| ErrConfigInvalid | 配置无效 | YAML 语法错误或 schema 不匹配 | exit code 2，输出解析错误详情 |
| ErrConfigMissing | 配置缺失 | `--config` 路径不存在或无配置文件 | exit code 2，输出文件路径提示 |
| ErrEvidenceInvalid | evidence 格式无效 | JSON 格式错误或 schema 不匹配 | exit code 2，输出解析错误详情 |
| ErrEvidenceMissing | evidence 缺失 | 必需 evidence 项缺失或不通过 | exit code 1，输出缺失项列表 |
| ErrBaselineMismatch | baseline 不匹配 | go.mod 中 go 版本 != 期望版本 | exit code 1，输出不匹配模块列表 |
| ErrImportViolation | import 违规 | 检测到禁止的 import 路径 | exit code 1，输出文件路径和行号 |
| ErrGomodDirty | go.mod 不整洁 | `go mod tidy` 产生 diff | exit code 1，输出 diff 详情 |

**错误消息格式**：`"xlibgate: <check>: <detail>"`
**错误包装**：使用 `%w` 保留底层错误链

## 11. 安全、稳定性与兼容性要求

- MUST 集成 `gitleaks` 扫描所有源文件，检测硬编码密钥、token 和凭证。
- MUST 确保配置文件只包含规则定义，不含密钥或凭据。
- MUST 确保错误消息只包含文件路径和行号，不泄露源代码内容。
- MUST 保证 `check all` 中某子检查超时时标记为 error，继续执行其余检查，不阻塞管线。
- MUST 支持 CI 环境无 color 支持时自动降级为纯文本输出。
- SHOULD 各检查实例独立运行，无状态冲突，支持并发执行。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容 | 发布门禁 |
| --- | --- | --- |
| 单元测试 | import 违规检测 / testkitx 边界 / go.mod tidy 检测 / baseline 匹配与不匹配 / release evidence 校验 / 配置解析 / exit code 验证 | MUST 通过 |
| 集成测试 | 完整 CI 流程 `check all` / 自检 `xlibgate check all --config xlibgate.yaml` / CI artifact 输出 | MUST 通过 |
| 失败测试 | 配置无效 / 配置缺失 / evidence 格式无效 / go.mod 缺失 / 子检查超时 | MUST 通过 |
| Benchmark | 全量门禁（50 模块）< 30s / import 扫描 < 10s / go.mod 检查 < 5s / baseline 检查 < 5s / JSON 报告 < 100ms | SHOULD 通过 |

### 关键 Given/When/Then 用例

- **TC-001**：Given 配置禁止业务域 import 基座层，When 扫描到 `binance` import 了 `kernel`，Then 输出违规详情（文件路径、行号），exit code 1。
- **TC-002**：Given 项目 go.mod 已 tidy，When 运行 `check gomod`，Then 输出 pass，exit code 0。
- **TC-003**：Given 配置要求 Go 1.23 且某模块 go.mod 指定 1.22，When 运行 `check baseline --expected 1.23`，Then 输出不匹配模块列表，exit code 1。
- **TC-004**：Given imports 检查失败且 gomod 检查通过，When 运行 `check all`，Then 输出所有子检查结果，imports=fail，gomod=pass，exit code 1。
- **TC-005**：Given imports 检查正常且 baseline 因配置缺失报 error，When 运行 `check all`，Then imports 正常输出，baseline 标记为 error，继续执行其余检查，exit code 2。

## 13. 1.0 发布验收清单

- 6 个 FR（check imports / gomod / baseline / release / all / 输出格式）全部实现并通过测试。
- exit code 标准化：0=pass, 1=fail, 2=error，所有场景验证通过。
- JSON 输出格式稳定，包含 `status`、`checks[]`、`summary` 字段。
- 配置 schema 文档化，`--config` 参数正常工作。
- gitleaks 集成完成，secret 扫描可执行。
- 自检通过：`xlibgate check all --config xlibgate.yaml` → pass。
- 不依赖任何 Foundation 运行时模块（通过 `go list -deps` 验证）。
- `check all` 必须执行所有子检查，即使前面的检查已失败。

## 14. Definition of Done

- CLI 帮助文档完整（`--help` 输出所有子命令和参数）。
- 所有 check 子命令有使用示例。
- exit code 文档化。
- JSON 输出格式文档化（含示例）。
- CHANGELOG.md 已更新。
- README.md 包含：模块定位、快速开始、配置说明、CLI 参考。
- 单元测试覆盖率 ≥ 80%。
- `-race` 测试通过。
- Benchmark 结果无 > 10% 回退。
- `go vet` 无警告。
- `golangci-lint` 无错误。
- Secret 扫描通过（gitleaks）。
- 自检通过（`xlibgate check all`）。
- 所有 Functional Requirements 有对应测试。
- 所有 Edge Cases 有对应测试。

## 15. 1.0 后演进方向

- 支持增量扫描（只扫描变更文件），减少全量扫描耗时。
- 支持自定义检查插件（用户定义的门禁规则）。
- import 边界规则支持正则表达式匹配。
- 支持多配置文件合并（项目级 + 组织级配置叠加）。
- release evidence 支持从远程 URL 获取。
- 支持将门禁结果以结构化格式上报到治理平台。
