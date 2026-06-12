# xlib-standard SPEC
## Metadata

Status: Approved
Owner: ZoneCNH
Version: v1.0.0
Updated: 2026-06-12

本规格定义 `xlib-standard` 五类职责中后四类的可执行交付规格——Go Reference Template、Generator、Harness Gate 和 Evidence Runtime。第一类职责（Standard Source / 标准事实源）的文档规范定义见 goal.md。本规格约束公共 API、模板生成、验证 gate、release manifest 与最终验收，不承载业务域实现。

## Constitution Compliance

| 条款            | 要求                               | 遵循方式                                             |
| --------------- | ---------------------------------- | ---------------------------------------------------- |
| §1 分层领域模型 | 模板不承载业务域，只生成基座库骨架 | 模板仅含 Config/Error/Health/Metrics/Client/Version  |
| §3 接口契约优先 | `contracts/` 定义跨域接口 + 内部治理 schema | 跨域契约：errors/health/config/metrics（4 件）；内部治理：agent-policy/goalcli/execution-context 等（12 件） |
| §5 配置外部化   | 配置由调用方显式传入               | Config 结构体必填字段校验                            |
| §7 错误处理规范 | 9 种 ErrorKind 稳定                | errors.go 实现 NewError/WrapError/IsKind             |
| §9 可观测性     | P0 指标名稳定、label 低基数        | NoopMetrics + 5 个 P0 指标                           |
| §11 发布流程    | release manifest + checksum        | release_check.sh 生成 latest.json + .sha256          |
| §13 安全红线    | 不提交 secret/API key              | Sanitize 脱敏 + security gate 扫描                   |

## Lifecycle State

| 阶段    | 状态      | 说明                                           |
| ------- | --------- | ---------------------------------------------- |
| Spec    | Approved  | 2026-06-09 批准                                |
| Plan    | Approved  | 6 子任务依赖拓扑已确认                         |
| Tasks   | Ready     | 9 个 task spec 已拆分                          |
| Prompt  | Ready     | 9 个 context packet 已生成                     |
| Code    | Completed | G6 PASS, 16 FR/27 AC/24 TC verified            |
| Test    | Completed | G7 PASS, Evidence 6 文件                       |
| Release | Released  | 上游 v1.0.0 已发布（tag v1.0.0，PR #115 已合入；version.go 仍为 v0.6.6 待上游同步） |

## Summary

`xlib-standard` 提供 xlib 体系的唯一标准源：标准文档（`docs/standard/`）、可编译可渲染可验证的 Go Reference Template、Generator（`render_template.sh`）、17 个 CI Gate 和 Evidence Runtime（release manifest + checksum + goalcli 证据 CLI）。本 SPEC 聚焦后四类的可执行交付细节。交付物包括模板源码、渲染脚本、边界检查、合约检查、安全检查、CI gate、release manifest、goalcli 证据工具和最终发布检查。

## Problem

当前基础库模块容易出现公共 API 不一致、模板渲染后仍残留模板名、gate 命令不稳定、release 证据不可复现等问题。缺少统一标准会导致下游模块在初始化阶段重复修补配置、错误、健康检查、指标和发布流程。

## Goals

| Goal | Description                                                           | Trace              |
| ---- | --------------------------------------------------------------------- | ------------------ |
| G-0  | 定义 xlib 体系标准事实源（文档规范）。见 goal.md。                  | Standard Source     |
| G-1  | 定义 Config、Error、Health、Metrics、Client、Version 的最小公共 API。 | API standard       |
| G-2  | 提供 Go 参考模板，并保证模板本身可编译、可测试、可 vet。              | Reference template |
| G-3  | 提供渲染脚本，从标准模板创建独立 Go module。                          | Generator          |
| G-4  | 定义最小 CI gate 与边界检查。                                         | Gates              |
| G-5  | 生成 release manifest，并用最终检查锁定发布证据。                     | Evidence Runtime   |

## Non-goals

- 不承载业务运行（不实现任何业务域逻辑、交易逻辑、行情逻辑或风控逻辑）。标准事实源的文档规范定义见 `goal.md`。
- 不替代下游模块的业务测试、集成测试或生产配置。
- 不引入数据库、消息队列、外部网络调用或运行时平台依赖。
- 不提供跨语言模板；本版本仅覆盖 Go module。
- 不承载业务域运行时逻辑（交易、行情、风控）。标准源自身的可执行交付物（模板代码、渲染脚本、CI 门禁、发布证据生成）属于标准源职责，不属于业务运行时。

## Consumers

| Consumer     | Need                                                 |
| ------------ | ---------------------------------------------------- |
| 新基础库模块 | 使用统一模板快速生成可测试仓库骨架。                 |
| 模块维护者   | 通过固定 gate 复用边界、合约、安全和 release 检查。  |
| 评分管线     | 从规格、矩阵、任务、计划、提示词到代码阶段闭合追溯。 |
| CI 系统      | 执行确定性命令，输出可审查证据。                     |

## Functional Requirements

### FR-001: Config 标准

- WHEN 调用 `Config.Validate` 且必填字段缺失 THEN 返回 validation kind 错误。
- WHEN `timeout` 或 `retry` 等数值配置为负数 THEN 返回 validation kind 错误。
- WHEN 调用 `Config.Sanitize` THEN secret、token、key 等敏感字段必须替换为 `***`。

### FR-002: Error 标准

- WHEN 调用 `NewError` THEN 返回的错误包含 kind、message 和可选 cause。
- WHEN 调用 `WrapError` THEN `errors.Is` 和 `errors.Unwrap` 必须保持可穿透。
- WHEN 使用 `IsKind` 匹配错误类型 THEN 匹配成功时返回 true。
- WHEN cause 为 deadline 类错误 THEN kind 必须归一为 timeout。
- WHEN cause 为 canceled 类错误 THEN kind 必须归一为 unavailable。

### FR-003: Health 标准

- WHEN `HealthCheck` 收到 nil context THEN 返回 unhealthy 状态。
- WHEN 客户端处于可用状态 THEN 返回 healthy 状态。
- WHEN 客户端已关闭或未初始化 THEN 返回 unhealthy 状态。
- WHEN context deadline 短于客户端 timeout THEN 返回 degraded 状态。

### FR-004: Metrics 标准

- WHEN 使用 `NoopMetrics` THEN 所有指标方法必须无副作用且不 panic。
- WHEN 记录指标 THEN 指标名必须匹配 contract 中的 P0 名称。
- WHEN 添加 label THEN 仅允许低基数键 `op`、`kind`、`status`。

### FR-005: Client 标准

- WHEN `New` 收到 nil config 且无法校验 THEN 返回错误。
- WHEN `New` 收到 nil context THEN 返回 validation kind 错误。
- WHEN `New` 收到已取消 context THEN 返回 unavailable kind 错误。
- WHEN 参数有效 THEN 返回可关闭的 `*Client`。
- WHEN 多次调用 `Close` THEN 必须幂等且不 panic。
- WHEN `Close` 收到 nil context THEN 返回 validation kind 错误。

### FR-006: Version 标准

- WHEN 查询版本信息 THEN 返回 module name 和 version。
- WHEN build metadata 不存在 THEN 返回稳定默认值而不是 panic。

### FR-007: 公共 API 模板

- WHEN 检查模板源码 THEN 必须包含 Config、Client、Error、Health、Metrics、Version 的公共 API。
- WHEN 检查 examples 和 testkit THEN 必须提供 basic example 与测试辅助包。

### FR-008: 模板可编译

- WHEN 在模板仓库运行 `go vet ./...` THEN 输出零警告。
- WHEN 在模板仓库运行 `go test ./...` THEN 全部测试通过。

### FR-009: render_template.sh 渲染

- WHEN 调用渲染脚本 THEN 只接受 `--module-path`、`--package-name`、`--out`、`--module-name` 参数。
- WHEN 渲染成功 THEN 输出目录必须包含 go.mod、源码、tests、scripts、Makefile 与 README。

### FR-010: 生成库无模板残留

- WHEN 检查生成库 THEN 不得出现 `templatex`、`xlib-standard`、`foundationx` 或 `baselib-template` 残留。
- WHEN 检查 go.mod 和包名 THEN 必须使用目标 module path 与 package name。

### FR-011: 17 个 CI gate

- WHEN 执行 `make ci` THEN 必须串联 doctor-hooks-local、fmt、vet、lint、test、race、boundary、architecture、domain、secret-check、security、security-debt、contracts、governance-check、debt、score、rules-verify。
- WHEN 任一 gate 失败 THEN `make ci` 必须非零退出。

### FR-012: boundary gate 检查

- WHEN 执行边界检查 THEN 必须拦截 `x.go/internal`、`/home/k8s/secrets/env`、`foundationx`、`baselib-template`、`templatex`、`xlib-standard` 非法引用。
- WHEN 检查生成库 THEN 必须排除 `.git` 等非源码目录。

### FR-013: release manifest

- WHEN 执行 release check THEN 生成 `release/manifest/latest.json` 和 sha256 文件。
- WHEN 读取 manifest THEN 必须包含 module path、package name、version、commit、tree sha、go version、contracts hash、gates、generated at。
- WHEN 写入 manifest THEN 不得包含 goal runtime、score、debt、branch governance、agent review、downstream matrix 或 docker runtime 字段。
- WHEN 执行 `make release-check` THEN 串联 ci、integration、dependency-check、standard-impact-check、docs-check、score-check、governance-check、p1-governance-check、p2-runtime-check、debt-evidence、fact-audit、evidence、release-evidence-hash、release-evidence-check、release-evidence-checksum-check。

### FR-014: release final check

- WHEN 执行最终检查 THEN manifest checksum 必须校验通过。
- WHEN 执行最终检查 THEN `make ci` 与 release check 必须均已通过。

### FR-015: Evidence Runtime CLI（goalcli）

- WHEN 运行 `goalcli audit` THEN 输出目标审计报告（G0-G11 gate 状态）。
- WHEN 运行 `goalcli dashboard` THEN 生成治理仪表盘 JSON（goalcli-dashboard schema）。
- WHEN 运行 `goalcli fact` THEN 执行事实检查并输出 fact-audit 证据。
- WHEN 运行 `goalcli schema-check` THEN 校验 contracts/ 中所有 schema 文件的有效性。
- WHEN 运行 `goalcli traceability` THEN 生成 FR→Code 追溯矩阵。
- WHEN 运行 `goalcli governance` THEN 输出分支保护、ruleset、CI 状态等远端治理检查结果。
- WHEN 运行 `goalcli debt` THEN 扫描技术债务（debtcheck）并输出债务报告。
- WHEN 运行 `goalcli adoption` THEN 检查下游模块对 xlib-standard 的采纳状态。
- WHEN 运行 `goalcli selfimproving` THEN 触发受控递归自改进流程。

### FR-016: L2 下游仓库模板（`templates/l2/`）

- WHEN Generator 渲染 L2 仓库骨架 THEN 必须包含 `.agent/`（证据 gates + capabilities）、`.github/workflows/`（CI 模板）、`test/`（契约/集成/benchmark/chaos）、`docker-compose.test.yml`、`Makefile`。
- WHEN 检查 L2 模板完整性 THEN 12 个模板文件必须全部存在且可渲染。

## Business Rules

### BR-001: 配置显式传入

库不得读取隐式环境配置；调用方必须显式传入配置结构。

### BR-002: 错误消息格式

公共错误消息必须稳定、短句化、可测试；错误 kind 比错误文本更适合作为断言对象。

### BR-003: Metrics label 低基数

指标 label 不得包含 ID、路径、用户输入、动态 module path 或 high-cardinality 值。

### BR-004: 模板占位符完整性

渲染脚本必须替换所有模板占位符；缺少必要参数时必须失败。

### BR-005: 生成库独立性

生成库必须可脱离标准模板仓库独立构建、测试和发布。

### BR-006: 库中禁止退出进程

库代码不得调用 `log.Fatal`、`os.Exit` 或等价退出进程逻辑。

### BR-007: Sanitize 脱敏范围

脱敏必须覆盖 secret、token、key、password 类字段，并保留非敏感配置用于诊断。

## Acceptance Criteria

| AC     | Acceptance                                               | 验证命令 | 代码位置 |
| ------ | -------------------------------------------------------- |
| AC-000 | 管线基线清理完成，模块文档和任务入口可被规则评分器发现。 | `python3 scripts/rule-scorer.py spec xlib-standard --check` | `module/xlib-standard/SPEC.md` |
| AC-001 | 必填字段缺失时配置校验返回 validation kind 错误。        | `GOWORK=off go test ./pkg/templatex/ -run TestConfigValidate/Required -count=1` | `pkg/templatex/config.go:23-32` |
| AC-002 | 负数 timeout 配置返回 validation kind 错误。             | `GOWORK=off go test ./pkg/templatex/ -run TestConfigValidate/Negative -count=1` | `pkg/templatex/config.go:28-31` |
| AC-003 | 配置脱敏后 secret 类字段显示为 `***`。                   | `GOWORK=off go test ./pkg/templatex/ -run TestConfigSanitize -count=1` | `pkg/templatex/config.go:34-39` |
| AC-004 | `NewError` 创建的错误字段完整。                          | `GOWORK=off go test ./pkg/templatex/ -run TestNewError -count=1` | `pkg/templatex/errors.go:28-34` |
| AC-005 | `WrapError` 包装后 `errors.Is` 可穿透。                  | `GOWORK=off go test ./pkg/templatex/ -run TestWrapError -count=1` | `pkg/templatex/errors.go:34-36,55-59` |
| AC-006 | `IsKind` 匹配目标 kind 返回 true。                       | `GOWORK=off go test ./pkg/templatex/ -run TestIsKind -count=1` | `pkg/templatex/errors.go:62-67` |
| AC-007 | deadline cause 归一为 timeout kind。                     | `GOWORK=off go test ./pkg/templatex/ -run TestContextError/Deadline -count=1` | `pkg/templatex/errors.go:87-96` |
| AC-008 | canceled cause 归一为 unavailable kind。                 | `GOWORK=off go test ./pkg/templatex/ -run TestContextError/Canceled -count=1` | `pkg/templatex/errors.go:87-96` |
| AC-009 | nil context 健康检查返回 unhealthy。                     | `GOWORK=off go test ./pkg/templatex/ -run TestHealthCheck/NilContext -count=1` | `pkg/templatex/health.go:44-50` |
| AC-010 | 健康客户端返回 healthy。                                 | `GOWORK=off go test ./pkg/templatex/ -run TestHealthCheck/Healthy -count=1` | `pkg/templatex/health.go:98-103` |
| AC-011 | `NoopMetrics` 调用不 panic。                             | `GOWORK=off go test ./pkg/templatex/ -run TestNoopMetrics -count=1` | `pkg/templatex/metrics.go:21-27` |
| AC-012 | P0 指标名与 contract 一致。                              | `GOWORK=off go test ./pkg/templatex/ -run TestMetricsNames -count=1` | `pkg/templatex/metrics.go:15-19` |
| AC-013 | metrics label 仅使用低基数键。                           | `GOWORK=off go test ./pkg/templatex/ -run TestMetricsLabels -count=1` | `pkg/templatex/metrics.go:15-19` |
| AC-014 | nil context 创建客户端返回错误。                         | `GOWORK=off go test ./pkg/templatex/ -run TestNew/NilContext -count=1` | `pkg/templatex/client.go:24-28` |
| AC-015 | canceled context 创建客户端返回错误。                    | `GOWORK=off go test ./pkg/templatex/ -run TestNew/CanceledContext -count=1` | `pkg/templatex/client.go:29-33` |
| AC-016 | 无效 config 创建客户端返回错误。                         | `GOWORK=off go test ./pkg/templatex/ -run TestNew/InvalidConfig -count=1` | `pkg/templatex/client.go:33-37` |
| AC-017 | 有效参数创建 `*Client`。                                 | `GOWORK=off go test ./pkg/templatex/ -run TestNew/Valid -count=1` | `pkg/templatex/client.go:38-39` |
| AC-018 | `Close` 多次调用幂等且不 panic。                         | `GOWORK=off go test ./pkg/templatex/ -run TestClose/Idempotent -count=1` | `pkg/templatex/client.go:45-68` |
| AC-019 | 版本信息包含 module name 和 version。                    | `GOWORK=off go test ./pkg/templatex/ -run TestVersion -count=1` | `pkg/templatex/version.go:6-7` |
| AC-020 | 模板 `go vet` 零警告。                                   | `GOWORK=off go vet ./pkg/templatex/` | `pkg/templatex/*.go` |
| AC-021 | 模板 `go test` 全部通过。                                | `GOWORK=off go test ./pkg/templatex/ -count=1` | `pkg/templatex/*_test.go` |
| AC-022 | 渲染输出目录结构完整。                                   | `bash scripts/render_template.sh --module-path test --package-name test --out /tmp/out && test -f /tmp/out/go.mod` | `scripts/render_template.sh` |
| AC-023 | 生成库无模板名和标准库名残留。                           | `bash scripts/check_rendered_template.sh /tmp/out` | `scripts/check_rendered_template.sh` |
| AC-024 | `make ci` 的 17 个 gate 全部通过。                       | `GOWORK=off make ci` | `Makefile (ci: target)` |
| AC-025 | boundary gate 检查 6 类非法引用。                        | `bash scripts/check_boundary.sh` | `scripts/check_boundary.sh` |
| AC-026 | release manifest 生成且字段完整。                        | `GOWORK=off make release-check` | `Makefile (release-check) + scripts/generate_manifest.sh` |
| AC-027 | release final check 校验 manifest checksum。             | `GOWORK=off make release-final-check` | `Makefile (release-final-check)` |
| AC-028 | goalcli audit 输出 G0-G11 gate 状态审计报告。            | `GOWORK=off go run ./cmd/goalcli audit` | `cmd/goalcli/audit_goal.go` |
| AC-029 | goalcli dashboard 生成符合 goalcli-dashboard schema 的仪表盘 JSON。 | `GOWORK=off go run ./cmd/goalcli dashboard --out /tmp/dashboard.json` | `cmd/goalcli/dashboard_generate.go` |
| AC-030 | goalcli fact 执行事实检查并输出 fact-audit 证据。         | `GOWORK=off go run ./cmd/goalcli fact` | `cmd/goalcli/fact.go` |
| AC-031 | goalcli schema-check 校验 contracts/ 中所有 schema 有效性。 | `GOWORK=off go run ./cmd/goalcli schema-check` | `cmd/goalcli/schema_check.go` |
| AC-032 | goalcli traceability 生成 FR→Code 追溯矩阵。              | `GOWORK=off go run ./cmd/goalcli traceability` | `cmd/goalcli/traceability.go` |
| AC-033 | goalcli governance 输出远端治理检查结果。                 | `GOWORK=off go run ./cmd/goalcli governance` | `cmd/goalcli/governance.go` |
| AC-034 | goalcli debt 扫描技术债务并输出债务报告。                 | `GOWORK=off go run ./cmd/goalcli debt` | `cmd/goalcli/debt.go` |
| AC-035 | goalcli adoption 检查下游采纳状态。                       | `GOWORK=off go run ./cmd/goalcli adoption` | `cmd/goalcli/adoption_check.go` |
| AC-036 | goalcli selfimproving 触发受控递归自改进流程。            | `GOWORK=off go run ./cmd/goalcli selfimproving` | `cmd/goalcli/selfimproving.go` |
| AC-037 | templates/l2/ 12 个模板文件全部存在且可渲染。          | `bash scripts/check_l2_templates.sh` | `templates/l2/` |

## Test Cases

| TC     | Type        | Scenario                | Expected                   |
| ------ | ----------- | ----------------------- | -------------------------- |
| TC-001 | Unit        | Config 必填字段缺失     | 返回 validation kind       |
| TC-002 | Unit        | Config 负数 timeout     | 返回 validation kind       |
| TC-003 | Unit        | Config 脱敏             | secret 替换为 `***`        |
| TC-004 | Unit        | NewError 创建           | 字段正确                   |
| TC-005 | Unit        | WrapError 包装          | `errors.Is` 可穿透         |
| TC-006 | Unit        | IsKind 匹配             | 返回 true                  |
| TC-007 | Unit        | deadline cause          | kind 为 timeout            |
| TC-008 | Unit        | canceled cause          | kind 为 unavailable        |
| TC-009 | Unit        | HealthCheck nil context | 返回 unhealthy             |
| TC-010 | Unit        | HealthCheck 健康客户端  | 返回 healthy               |
| TC-011 | Unit        | NoopMetrics 调用        | 无 panic                   |
| TC-012 | Unit        | 指标名匹配 contract     | P0 名称一致                |
| TC-013 | Unit        | label 低基数            | 只有允许键                 |
| TC-014 | Unit        | New nil context         | 返回错误                   |
| TC-015 | Unit        | New canceled context    | 返回错误                   |
| TC-016 | Unit        | New 无效 config         | 返回错误                   |
| TC-017 | Unit        | New 正常创建            | 返回客户端                 |
| TC-018 | Unit        | Close 幂等              | 多次调用不 panic           |
| TC-019 | Integration | 模板 go vet             | 零警告                     |
| TC-020 | Integration | 模板 go test            | 全部通过                   |
| TC-021 | Integration | 渲染模板                | 输出结构完整               |
| TC-022 | Integration | 检查生成库残留          | 无非法残留                 |
| TC-023 | Integration | make ci                 | 17 个 gate 全通过          |
| TC-024 | Integration | release manifest        | 字段完整且 checksum 可校验 |
| TC-025 | Integration | goalcli audit           | 输出 G0-G11 审计报告      |
| TC-026 | Integration | goalcli dashboard       | 输出合规仪表盘 JSON       |
| TC-027 | Integration | goalcli fact            | 输出 fact-audit 证据      |
| TC-028 | Integration | goalcli schema-check    | 全 schema 校验通过        |
| TC-029 | Integration | goalcli traceability    | 生成 FR→Code 追溯矩阵     |
| TC-030 | Integration | goalcli governance      | 输出远端治理状态          |
| TC-031 | Integration | goalcli debt            | 输出技术债务报告          |
| TC-032 | Integration | goalcli adoption        | 输出下游采纳状态          |
| TC-033 | Integration | goalcli selfimproving   | 自改进流程正常执行        |
| TC-034 | Integration | templates/l2 完整性检查 | 12 模板文件在位          |

## Interfaces

公共接口包括 `Config.Validate`、`Config.Sanitize`、`New(ctx, cfg, ...opts)`、`Client.Close(ctx)`、`HealthCheck(ctx)`、`Metrics`、`NoopMetrics`、`WithMetrics(metrics)`、`Option`、`NewError`、`WrapError`、`IsKind`、`VersionInfo`。接口必须保持小表面积，测试应优先断言 kind、状态和结构字段。

## Data Model

| Model           | Fields                                                                                                  |
| --------------- | ------------------------------------------------------------------------------------------------------- |
| Config          | Name、Timeout、Secret                                                                                  |
| Error           | kind、message、cause                                                                                    |
| HealthStatus    | status、message、checked_at、LatencyMs、Metadata                                                       |
| VersionInfo     | ModuleName、Version                                                                                    |
| ReleaseManifest | module_path、package_name、version、commit、tree_sha、go_version、contracts_sha256、gates、generated_at |

## Configuration

配置必须由调用方显式传入。模板生成参数仅允许 module path、package name、输出目录和可选 module name。脚本不得从生产环境文件、私有 secret 目录或隐式 runtime 配置读取默认值。

## State

模板仓库本身不维护运行时状态。可生成状态只允许出现在渲染输出目录、release manifest 目录和临时测试目录。评分和管线运行态由 `.omx/state`、`.omc/state` 或 `.copilot/state` 承载，不属于模板业务状态。

## Error Handling

所有公共错误必须返回给调用方，不得直接退出进程。validation、timeout、unavailable、internal 等 kind 必须稳定。包装错误必须保留 cause，便于 `errors.Is`、`errors.As` 和 kind 匹配。

## Edge Cases

- nil context 创建客户端或健康检查。
- 已取消 context 创建客户端。
- 负数 timeout、retry 或空 module path。
- 渲染输出目录已存在且包含旧文件。
- 模板占位符缺失或未替换。
- 生成库包含模板仓库名、旧包名或非法边界引用。
- release manifest 已存在但 checksum 不匹配。

## Security

脚本和模板不得提交 secret、API key、账户 ID、私有端点或生产配置。安全检查必须扫描常见凭证模式。`Sanitize` 必须避免泄露敏感字段，同时保留足够诊断信息。

## Observability

模板仅定义 metrics 接口和 no-op 实现，不强制具体后端。P0 指标名必须稳定，label 必须低基数。Release manifest 是发布可观测证据，记录 gate 结果和生成时间。

## Performance

模板库初始化必须轻量，不做网络调用。`NoopMetrics`、kind 匹配和健康状态构造应为常数级操作。`make ci` 适合作为本地开发 gate，渲染 smoke test 不应依赖外部服务。

## Testing Strategy

测试分三层：公共 API 单元测试、模板仓库集成测试、生成库 smoke test。最小验证命令包括 `GOWORK=off go test ./...`、`GOWORK=off go test -race ./...`、`GOWORK=off make ci`、`GOWORK=off make release-check` 和 `GOWORK=off make release-final-check`。

## CI Gate

CI 必须运行 `GOWORK=off make ci` 和 `GOWORK=off make release-check`。`make ci` 的最小 gate 为 doctor-hooks-local、fmt、vet、lint、test、race、boundary、architecture、domain、secret-check、security、security-debt、contracts、governance-check、debt、score、rules-verify。任何 gate 失败时 CI 必须失败。

## Release DoD

发布前必须满足：模板测试通过、生成库测试通过、边界检查通过、合约检查通过、安全检查通过、release manifest 生成、checksum 校验通过、最终检查通过。发布证据必须可复现并可由 CI 重新生成。

## Dependencies

### 外部依赖

模板优先使用 Go 标准库。允许使用本仓库已有脚本、Makefile 和 GitHub Actions。不得为模板生成、边界检查或 release manifest 引入新的外部运行时依赖，除非后续规格显式批准。

### 内部实现包（`internal/`）

| 包 | 用途 | 被引用方 |
|----|------|---------|
| `internal/sanitize/` | 敏感字段脱敏（`sanitize.Secret()`） | `pkg/templatex/config.go` |
| `internal/validation/` | 前置条件校验（`validation.RequireNonEmpty()`） | `pkg/templatex/config.go` |
| `internal/xlibfacts/` | 事实检查引擎 | `cmd/goalcli/fact.go` |
| `internal/goalruntime/` | Goal 运行时状态管理 | `cmd/goalcli/goalruntime.go` |
| `internal/debtcheck/` | 技术债务扫描 | `cmd/goalcli/debt.go` |
| `internal/releasequality/` | 发布质量评分（`score.go`） | `cmd/goalcli/`、release gate |
| `internal/tools/releasemanifest/` | 发布清单生成工具 | `Makefile` release-check 目标 |

### 模板系统（`templates/l2/`）

`templates/l2/` 包含 12 个 L2 标准模板文件，用于 Generator 角色生成下游仓库骨架：
- `.agent/` — 代理配置（evidence gates, capabilities）
- `.github/workflows/` — CI 流水线模板
- `test/` — 契约测试、集成测试、benchmark、chaos 测试模板
- `docker-compose.test.yml` — 容器化测试环境
- `Makefile` — 下游仓库构建入口

## Breaking Change Policy

破坏性接口变更（ErrorKind 增删、Config 字段类型变更、Metrics label 变更）必须：

1. 在 兼容矩阵中记录。
2. 在 release manifest 中体现版本 bump。
3. 提供迁移脚本或回滚说明。
4. 经下游消费者确认后方可合入。

## Rollout

先修复并验证 `xlib-standard` 标准源，再用于生成 `kernel` 等下游基础库。每次下游采用前必须重新运行渲染 smoke test、边界检查和生成库测试。破坏性接口变更必须进入 semver 兼容矩阵并在 release manifest 中体现。
