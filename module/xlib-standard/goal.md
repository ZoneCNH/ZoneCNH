# xlib-standard 发布版本 1.0 Goal 定位与实现标准

| 字段 | 内容 |
| --- | --- |
| 模块名 | `xlib-standard` |
| 发布版本 | 1.0.0 |
| 所属层级 | 标准源层 / 规范基线 |
| 稳定级别 | 标准文档 Stable；模板 API Stable；Generator Stable；Gate 定义 Stable；Evidence 格式 Stable |
| 文档状态 | 1.0 发布基线文档 |
| 发布日期基准 | 2026-06-09 |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 1.0 发布判定原则

1. **稳定优先**：公开 API、配置项、错误码、指标名一旦进入 1.0，默认需要向后兼容。
2. **边界清晰**：模块只能解决自身层级的问题，不能向上侵入业务，也不能横向替代其他模块。
3. **证据完整**：每个 MUST 能力都必须有单元测试、关键路径集成测试或契约测试证明。
4. **可观测**：所有运行时模块必须输出最小可诊断信息，包括错误、耗时、调用量和关键状态。
5. **可演进**：1.0 允许保留扩展点，但不得把未稳定能力包装成稳定承诺。

## 1. Goal 定位

`xlib-standard` 的 Goal 是成为 xlib 体系的唯一标准源。它承担五类职责：标准事实源（文档规范）、Go Reference Template（可编译参考模板）、Generator（模板渲染与代码生成）、Harness Gate（CI 门禁与边界检查）和 Evidence Runtime（release manifest 与发布证据生成）。它不承载业务运行，但通过 Go 参考模板、代码生成器、Harness Gate 和 Evidence Runtime 让这些标准可编译、可执行、可验证。它以 1.0 发布标准定义所有模块必须遵循的工程规则、接口规则、配置规则、错误规则、观测规则、测试规则、版本规则和扩展规则。它的价值在于让后续所有模块具备一致的设计语言、验收口径和演进边界，避免每个模块各自发明标准。

### 1.1 为什么需要这个模块

- 没有统一标准时，模块接口、错误、配置、日志和测试证据会逐渐分裂，导致维护成本指数级上升。
- 基座模块必须长期稳定，稳定性的前提是发布前就有明确契约和变更规则。
- 扩展模块数量较多，需要统一接入标准，否则 Redis、Kafka、PostgreSQL、OSS 等模块会形成互不兼容的局部封装。
- 架构评审需要可执行的评审依据，而不是依赖个人经验判断。
- 新模块需要一致的代码骨架和 CI 门禁，而不是每次从零搭建。

### 1.2 五角色定义

| 角色 | 职责 | 交付物 |
| --- | --- | --- |
| Standard Source | 定义 xlib 体系的文档规范、工程规则和验收口径 | docs/standard/ 下 8 大标准域 |
| Go Reference Template | 提供可编译、可测试的 Go 基础库参考模板 | pkg/templatex/ 下 Config/Error/Health/Metrics/Client/Version API |
| Generator | 从标准模板渲染生成独立 Go module | render_template.sh + 生成库结构 |
| Harness Gate | 定义最小 CI 门禁和边界检查 | make ci（9 gate）+ boundary/contracts check |
| Evidence Runtime | 生成 release manifest 和发布证据 | release_check.sh → latest.json + .sha256 |

### 1.3 1.0 要解决的问题

- 定义 xlib 模块的命名、分层、依赖方向和版本语义，并维护标准事实源文档。
- 定义 Public API、SPI、Internal API 的稳定性等级。
- 定义错误码、异常、Result、配置项、日志字段、指标名、Trace 标签的统一规则。
- 提供可编译的 Go Reference Template，让新模块从统一骨架起步。
- 提供 Generator，从模板确定性渲染出独立 Go module，无模板残留。
- 定义 9 个最小 CI Gate，可串联执行并在任一失败时非零退出。
- 生成可复现的 Release Evidence（manifest + checksum + gate 结果）。
- 定义扩展模块如何接入标准源、如何证明符合标准。

### 1.4 目标用户

- 基座架构负责人
- 各模块 Owner
- 代码评审人员
- 测试与质量平台人员
- 业务团队接入负责人
- CI/CD 管线维护者

## 2. 1.0 发布目标

- MUST 形成一套可执行的 xlib 标准目录，而不是散落的说明文档。
- MUST 覆盖模块设计、API 设计、错误模型、配置模型、观测模型、测试证据、发布流程、兼容性管理。
- MUST 提供可编译、可测试、可 vet 的 Go Reference Template（Config / Error / Health / Metrics / Client / Version 公共 API）。
- MUST 提供 Generator（render_template.sh），可从模板确定性渲染出独立 Go module。
- MUST 定义 9 个最小 CI Gate（fmt / vet / lint / test / race / contracts / boundary / render-smoke / security），串联执行，任一失败非零退出。
- MUST 生成可复现的 Release Evidence（manifest + checksum + gate 结果）。
- MUST 为每类模块提供文档模板：L0 原语、L1 横切能力、测试工具、存储扩展、消息扩展、契约模块。
- MUST 产出检查清单，使新模块可以按清单完成 1.0 发布评审。
- SHOULD 提供示例模块文档，降低后续模块落地成本。

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| 新模块立项 | 模块 Owner 需要知道如何命名、如何分层、能依赖谁、必须交付什么 | 按标准模板完成模块 RFC 和 1.0 清单 |
| 新模块初始化 | 模块 Owner 需要快速生成可编译的 Go module 骨架 | 运行 Generator，得到独立可构建的模块仓库 |
| 发布评审 | 评审人员需要判断模块是否达到 1.0 稳定标准 | 使用统一门禁检查 API、配置、观测、测试、兼容性 |
| 问题排查 | 不同模块日志字段和错误码需要一致 | 可基于统一字段检索和聚合 |
| 破坏性变更评估 | 某模块需要改接口或配置 | 按兼容性规则判定是否允许进入 minor 或必须进入 major |
| CI 门禁执行 | CI 管线需要对模块执行确定性检查 | make ci 全部通过，失败非零退出 |

## 4. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| 模块标准 | 分层模型、依赖方向、命名规则、包结构、模块生命周期、发布物结构 | 标准文档评审通过；任一模块可按模板生成设计文档 |
| 接口标准 | Public API / SPI / Internal API 分级，参数命名，返回模型，异常暴露规则 | API Review Checklist 通过 |
| 错误标准 | 错误码分段、错误分类、可重试标记、用户可见消息与诊断消息分离 | 错误码表完整且无冲突 |
| 配置标准 | 配置命名、默认值、校验、敏感字段、热更新标记、废弃策略 | 配置参考生成并通过校验 |
| 命名规范 | 指标前缀 `foundationx_<module>_`、配置前缀 `foundationx.<module>.`、错误码前缀 `MODULE_`；L0 原语层可使用短前缀并在标准中声明豁免 | 命名一致性检查通过 |
| 观测标准 | 日志字段、指标命名、Trace 标签、诊断事件格式 | observex 对齐测试通过 |
| 测试标准 | 单测、集成测试、契约测试、兼容性测试、证据包格式 | CI 中可生成测试证据包 |
| 发布标准 | 版本号、变更日志、兼容性声明、回滚说明、废弃策略 | 发布门禁清单全部关闭 |
| 模板标准 | Go Reference Template 可编译、可测试、可 vet，公共 API 稳定 | `go vet ./...` 零警告，`go test ./...` 全部通过 |
| 生成器标准 | Generator 确定性渲染，生成库无模板残留，可脱离模板仓库独立构建 | 渲染 smoke test 通过，边界检查无非法引用 |
| 门禁标准 | 9 个最小 CI gate 串联执行，任一失败则 CI 非零退出 | `make ci` 全部通过 |
| 证据标准 | Release manifest 字段完整，checksum 可校验，gate 结果可追溯 | `make release-final-check` 通过 |

## 5. 职责边界

### 5.1 模块内职责

- 维护 xlib 统一规范、模板和检查清单。
- 维护 Go Reference Template 源码，保证其可编译、可测试、可 vet。
- 维护 Generator（render_template.sh），保证确定性渲染和生成库独立性。
- 维护 9 个最小 CI Gate 定义和 make ci 串联逻辑。
- 维护 Release Evidence 格式、manifest 生成和 checksum 校验。
- 定义模块文档结构和发布文档结构。
- 维护公共错误码段和模块错误码分配规则。
- 维护配置、观测、测试证据的标准字段。
- 定义兼容性级别和破坏性变更处理流程。

### 5.2 明确非目标

- 不承载任何业务域运行逻辑（交易、行情、风控）。
- 标准源的可执行交付物（模板、生成器、gate、evidence）不属于业务运行时。
- 不替代 kernel、observex、testkitx 等模块。
- 不替代公司级安全、合规或发布平台，只定义 xlib 接入要求。
- 不收纳与 xlib 无关的通用知识库内容。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 上游依赖 | 不依赖其他 xlib 运行时模块；可引用组织级工程规范，但必须固化为 xlib 可执行规则 |
| 模板依赖 | Go Reference Template 优先使用 Go stdlib；Generator / Gate / Evidence 工具允许使用 Makefile、shell 脚本、GitHub Actions |
| 下游依赖 | 所有 xlib 模块在 1.0 发布时都必须声明符合 xlib-standard 的版本 |
| 分层约束 | 标准源不能反向依赖具体实现；标准变更需要兼容性说明 |

## 7. 对外契约

### 7.1 公开能力面

| 契约 | 定位 | 1.0 稳定承诺 |
| --- | --- | --- |
| 标准文档目录 | 定义标准分类和文件命名 | 1.0 内目录结构稳定，新增标准只能追加不能破坏已有引用 |
| Go Reference Template | 可编译的 Go library 骨架（Config / Error / Health / Metrics / Client / Version） | 公共 API 签名稳定，允许追加可选字段和方法 |
| Generator | render_template.sh，接受 --module-path / --package-name / --out / --module-name | 参数集合稳定，输出目录结构稳定 |
| 检查清单 | 发布、测试、兼容性、安全、观测检查清单 | 1.0 检查项语义稳定 |
| 错误码分配表 | 模块错误码段和分类规则 | 错误码段一经分配不得复用 |
| 文档模板 | 模块 RFC、设计文档、配置参考、测试证据模板 | 模板字段稳定，允许追加可选字段 |
| CI Gate 定义 | 17 个 gate 的 make ci 串联逻辑 | gate 名称和执行顺序稳定 |
| Release Evidence | manifest latest.json + .sha256 格式 | 字段集合稳定，允许追加可选字段 |

### 7.2 1.0 逻辑接口基线

```text
standard/
  module-model.md
  api-standard.md
  error-standard.md
  config-standard.md
  observability-standard.md
  testing-standard.md
  release-standard.md
  compatibility-standard.md
  templates/
    module-design-template.md
    release-checklist.md
    test-evidence-template.md

template/                          # Go Reference Template（可编译源码）
  go.mod
  config.go
  errors.go
  health.go
  metrics.go
  client.go
  version.go
  ...

scripts/
  render_template.sh               # Generator
  Makefile                          # make ci（17 个 gate）
  release_check.sh                  # Evidence Runtime
```

## 8. 配置契约

| 配置项 | 含义 | 默认值 / 要求 | 稳定性 |
| --- | --- | --- | --- |
| foundationx.standard.version | 被其他模块文档引用的标准版本 | 1.0.0 | Stable |
| Generator --module-path | 渲染目标 Go module path | 必填，调用方显式传入 | Stable |
| Generator --package-name | 渲染目标 package name | 必填，调用方显式传入 | Stable |
| Generator --out | 渲染输出目录 | 必填，调用方显式传入 | Stable |
| Generator --module-name | 可选模块名 | 可选 | Stable |

本模块不承载业务运行时不读取隐式环境配置；Generator 参数由调用方显式传入。

## 9. 可观测契约

### 9.1 日志

- 标准文档本身不直接输出运行时日志。
- Generator 和 CI Gate 执行时 MAY 输出操作日志，用于排查渲染或门禁失败原因。
- Evidence 工具输出确定性 JSON（manifest），不输出非结构化日志。

### 9.2 指标

| 指标名 | 类型 | 标签 | 说明 |
| --- | --- | --- | --- |
| 无业务运行时指标 | N/A | N/A | 标准源不承载业务运行，不产生业务运行时指标 |

### 9.3 Evidence 输出（替代运行时 Trace/指标）

| 输出 | 格式 | 说明 |
| --- | --- | --- |
| Release Manifest | JSON（latest.json） | module path / package name / version / commit / tree sha / go version / contracts hash / gate results / generated_at |
| Checksum | .sha256 | manifest 完整性校验 |
| Gate Results | make ci 输出 | fmt / vet / lint / test / race / contracts / boundary / render-smoke / security 各 gate 的通过/失败状态 |

### 9.4 Trace / 诊断事件

- 不直接参与运行时 Trace。
- MAY 定义 Trace 字段标准供 observex 执行。

## 10. 错误模型与失败策略

| 错误码 | 错误类别 | 典型原因 | 1.0 处理策略 |
| --- | --- | --- | --- |
| STANDARD_CODE_CONFLICT | 标准冲突 | 两个模块申请相同错误码段或指标前缀 | 发布评审阻断，必须重新分配 |
| STANDARD_RULE_MISSING | 标准缺失 | 新能力无对应发布或测试标准 | 不得以 1.0 Stable 发布，只能标记 Experimental |
| STANDARD_COMPAT_UNKNOWN | 兼容性不明 | 变更无法判断是否破坏兼容 | 默认按破坏性变更处理 |
| STANDARD_NAMING_VIOLATION | 命名违规 | 配置键、指标名、错误码前缀不符合规范 | 发布评审阻断，必须修正 |
| STANDARD_TEMPLATE_INCOMPLETE | 模板不完整 | 模块文档缺少 MUST 章节 | 发布评审阻断，必须补齐 |
| STANDARD_GENERATE_FAILED | 生成失败 | Generator 渲染失败或生成库残留模板名 | 发布评审阻断，必须修正 |
| STANDARD_GATE_FAILED | 门禁失败 | 任一 CI gate 未通过 | 发布评审阻断，必须修正 |
| STANDARD_EVIDENCE_INVALID | 证据无效 | Manifest checksum 不匹配或字段缺失 | 发布评审阻断，必须重新生成 |

## 11. 安全、稳定性与兼容性要求

- MUST 在标准中要求所有模块做敏感信息脱敏。
- MUST 定义密钥、连接串、用户标识、租户标识的日志暴露边界。
- SHOULD 定义安全检查清单，用于发布前审查。
- Generator 渲染输出不得包含模板仓库名、旧包名或非法边界引用。
- CI Gate 的安全扫描必须拦截常见凭证模式。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容 | 发布门禁 |
| --- | --- | --- |
| 标准一致性检查 | 模板字段完整、错误码段无冲突、指标命名合法 | MUST 通过 |
| 模板可编译 | Go Reference Template 通过 `go vet ./...`、`go test ./...` 和 `go test -race ./...` | MUST 通过 |
| 生成器冒烟测试 | Generator 渲染成功，生成库 go.mod / 包名无模板残留 | MUST 通过 |
| CI Gate 集成 | `make ci` 的 17 个 gate 全部通过 | MUST 通过 |
| Evidence 复现 | `make release-final-check` 通过，manifest checksum 校验一致 | MUST 通过 |
| 模块合规抽检 | 至少选择 kernel、observex、redisx、contracts 验证标准可执行 | MUST 通过 |
| 文档链接检查 | 标准文档内部引用有效 | MUST 通过 |

## 13. 1.0 发布验收清单

- 标准目录完整，覆盖 1.0 所有模块类型。
- Go Reference Template 可编译（`go vet ./...` 零警告）、可测试（`go test ./...` 全部通过）、可 race test（`go test -race ./...` 通过）。
- Generator 渲染 smoke test 通过，生成库无模板残留，可脱离模板仓库独立构建和测试。
- 9 个 CI Gate（fmt / vet / lint / test / race / contracts / boundary / render-smoke / security）全部可执行并通过。
- Release manifest 生成且 checksum 可校验。
- 发布检查清单可以直接用于模块评审。
- 错误码、配置、观测、测试证据有明确规范。
- 所有 1.0 模块文档均声明符合该标准。

## 14. Definition of Done

- 标准文档合并到版本库并打 1.0 标签。
- Go Reference Template 通过 `go vet ./...`、`go test ./...` 和 `go test -race ./...`。
- Generator 可确定性渲染，生成库可脱离模板仓库独立构建、测试和发布。
- 9 个 CI Gate 串联可执行，任一失败非零退出。
- Release evidence（manifest + checksum + gate results）可复现、可审查。
- 模块文档模板可复制使用。
- 标准变更流程和 Owner 明确。
- 所有示例均不依赖特定业务。
- 发布门禁、依赖矩阵、契约登记和证据索引已纳入机器可检查治理制品。

## 15. 1.0 后演进方向

- 将 Generator / Gate / Evidence 工具独立为 `xlibgate` 独立 Go module（当前可先保留在 `xlib-standard/cmd/` 或 `xlib-standard/scripts/`）。
- 引入标准检查 CLI，自动扫描配置项、错误码和指标名。
- 引入标准站点，支持版本化浏览。
- 将发布门禁接入 CI/CD。
