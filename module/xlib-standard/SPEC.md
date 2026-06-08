# xlib-standard 完整规格

> **归档说明**：本 SPEC.md 是基于 ANALYSIS.md v3.1.0 的结构化整理稿，不再作为可执行规格或独立开发入口。当前权威入口是 `ANALYSIS.md` / `FR-DETAIL.md` / `TRACEABILITY.md`。本文件仅供架构索引和追溯参考。

> 基座 · Foundation Gate 治理子层。标准事实源、Go Reference Template、Generator、Harness Gate、Evidence Runtime 与仓库治理协议。

最后更新：2026-06-08

---

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-08
- Owner: ZoneCNH
- Layer: 基座（Foundation Gate 治理子层）
- Version: v0.6.5
- Repository: [github.com/ZoneCNH/xlib-standard](https://github.com/ZoneCNH/xlib-standard)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), [xlibgate](../xlibgate/SPEC.md), [ANALYSIS.md](./ANALYSIS.md), [FR-DETAIL.md](./FR-DETAIL.md), [TRACEABILITY.md](./TRACEABILITY.md)

| 字段 | 说明 |
|------|------|
| `Status` | 规格生命周期状态：Draft |
| `Spec-Version` | 规格文档版本号（与上游代码版本解耦） |
| `Last-Updated` | 规格最后修改日期 |
| `Owner` | 规格负责人 |
| `Layer` | 基座 · Foundation Gate 治理子层（位于 L0 kernel 之上，不被任何运行时模块依赖） |
| `Version` | 上游代码版本号（pinned commit `93753b30`，v0.6.5） |
| `Repository` | 上游仓库链接 |
| `Related` | 相关文档链接 |

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-08 | v1.0.0 | 初始版本，基于 ANALYSIS.md v3.1.0 编写 | ZoneCNH |

---

## 2. Summary

`xlib-standard` 是 FoundationX 的"标准事实源"（Standard of Truth），不是运行时 Go 代码。它定义 419 条规则、Go Reference Template、Generator、Harness Gate、Evidence Runtime 和仓库治理协议，为 70+ 个基座模块提供统一的质量基线和治理框架。

---

## 3. Problem

FoundationX 由 70+ 个 Go 模块组成，缺乏统一标准源会导致以下问题：

1. **身份漂移**：旧名 `baselib-template` 和 `foundationx` 导致 README、docs、.agent 出现身份混乱，下游无法判断权威来源。
2. **规则散文化**：419 条规则存在于散文和 registry/enforcer 源之间，机器化口径不明确，87%（363/419）已机器化，但仍有 56 条待收敛。
3. **伪完成风险**：登记态（registered）、dry-run、patch-only 容易被误判为 adopted 或 release-ready，缺少证据驱动的完成判定机制。
4. **配置分散**：`.agent/`、`.xlib/`、`.config/` 三套路径并存，下游无法直接判断权威配置来源。
5. **Gate 缺口**：本地 hooks、CI gate 与 GitHub Ruleset 缺乏分层强制，不能用本地文件证明远端启用。
6. **执行面不统一**：shell scripts 与 Go runtime 并存，缺少唯一机器入口和标准化退出码。

---

## 4. Goals

### 4.1 P0 目标

| 编号 | 目标 | 对应 FR |
|------|------|---------|
| G-P0-1 | 唯一主身份：`xlib-standard` 是唯一主身份，承担标准源、模板、生成器、Harness、Evidence Runtime 与治理协议职责 | FR-001..FR-008 |
| G-P0-2 | 规则机器化：419 条规则以 registry/enforcer 为机器化执行口径 | FR-001, FR-033..FR-039 |
| G-P0-3 | 证据驱动完成：没有 Evidence 不允许 DONE，完成声明必须使用 `DONE with evidence:` 格式 | FR-026..FR-032 |
| G-P0-4 | Proof-based adoption：登记态 != adopted，只有下游仓库自身生成的 proof-based adoption 才能进入 adopted | FR-006, FR-050, FR-051 |
| G-P0-5 | 配置统一目标：v1.0.0 前将配置拓扑收敛到 `.config/` | FR-013, FR-014 |
| G-P0-6 | 三层硬约束：本地 hooks + CI gate + GitHub Ruleset 三重强制 | FR-047 |

### 4.2 P1 目标

| 编号 | 目标 | 对应 FR |
|------|------|---------|
| G-P1-7 | Goal Runtime v3.1.1：Goal Kernel + Harness Runtime + Extensions 架构逐步落地 | FR-040..FR-046 |
| G-P1-8 | L2 测试工厂：L2 适配器按 release ladder 达到 T2/T3/T4 | FR-018 |
| G-P1-9 | Debt Governance：7 类技术债治理规则纳入 Gate | FR-033..FR-039 |
| G-P1-10 | 自动化：Issue -> Goal -> Task -> Branch -> Commit -> PR -> Version -> Release -> Issue Close 全链路 | FR-046, FR-052 |

---

## 5. Non-goals

- **不做运行时代码**：`xlib-standard` 不实现真实 L1/L2 provider runtime，不承载业务逻辑（由下游 `kernel`、`configx`、`redisx` 等模块实现）。
- **不做二进制分发**：本仓库不包含 `goalcli` 二进制、release artifact 或下游实现源码。
- **不做远端状态声明**：本分析不声明上游 release-ready、GitHub Release object 已创建、远端 ruleset 当前启用或 downstream adopted（远端证据由 `REMOTE-EVIDENCE.md` 的 pinned 记录支撑）。
- **不做历史计划升级**：不把 `.worktree/**`、Downloads 或历史计划升级为 Current Standard。
- **不做第二套执行面**：不创建与 `cmd/goalcli` 并列的第二套 gate 执行入口。

---

## 6. Consumers

| 消费者 | 领域 / 层级 | 消费方式 | 采纳状态口径 |
|--------|-------------|----------|--------------|
| `kernel` | 基座 / L0 | 生成模板 + 标准继承 | 需 proof-based adoption 证据 |
| `configx` | 基座 / L1 | 生成模板 + 标准继承 | 需 proof-based adoption 证据 |
| `observex` | 基座 / L1（横切） | 生成模板 + 标准继承 | 需 proof-based adoption 证据 |
| `testkitx` | 基座 / L1 | 生成模板 + 标准继承 | 需 proof-based adoption 证据 |
| `resiliencx` | 基座 / L1 | 生成模板 + 标准继承 | 需 proof-based adoption 证据 |
| `schedulex` | 基座 / L1 | 生成模板 + 标准继承 | 需 proof-based adoption 证据 |
| `redisx` | 基座 / L2 | 生成模板 + L2 适配规范 | 需 proof-based adoption 证据 |
| `kafkax` | 基座 / L2 | 生成模板 + L2 适配规范 | 需 proof-based adoption 证据 |
| `natsx` | 基座 / L2 | 生成模板 + L2 适配规范 | 需 proof-based adoption 证据 |
| `postgresx` | 基座 / L2 | 生成模板 + L2 适配规范 | 需 proof-based adoption 证据 |
| `taosx` | 基座 / L2 | 生成模板 + L2 适配规范 | 需 proof-based adoption 证据 |
| `ossx` | 基座 / L2 | 生成模板 + L2 适配规范 | 需 proof-based adoption 证据 |
| `clickhousex` | 基座 / L2 | 生成模板 + L2 适配规范 | 需 proof-based adoption 证据 |
| `xgo-market-data` | 数据域（私有） | 标准继承 | consumer-only |
| `xgo-macro-data` | 数据域（私有） | 标准继承 | consumer-only |
| `x.go` | 入口（私有） | 标准继承 | consumer-only |
| `xlibgate` | 基座 · Gate | 消费 Gate 和 Evidence 标准 | 独立门禁工具 |

> 注：L0/L1/L2 是基座领域内部依赖层级，详见 `analysis/governance.md` 3.6 与 `ARCHITECTURE.md`。

---

## 7. Functional Requirements

> 52 条 FR 按 8 个职责组组织。每个 FR 保留编号、名称、优先级和 1-2 条核心 WHEN/THEN。完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md)。

### 7.1 Standard Source（FR-001..FR-008）

#### FR-001: 定义 419 条 RULE-* 规则，机器化为 registry.yaml [P0]

WHEN registry.yaml 被 goalcli 加载
THEN 419 条规则全部有条目，schema 验证通过，无缺失无重复

WHEN 规则按前缀（RULE-CORE/RULE-HARNESS/RULE-EVIDENCE 等）分类查询
THEN 返回正确的类别和优先级（P0=119, P1=244, P2=56）

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-001

#### FR-002: 定义 7 类技术债治理规则 [P0]

WHEN `make debt` 执行
THEN ARCH/DEP/DOMAIN/DOCS/TEST/IMPL/SEC 7 类规则全部被检查，无遗漏类别

WHEN 某类技术债规则被触发
THEN 返回规则编号、严重度和修复建议

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-002

#### FR-003: 定义 10 条 Git 治理规则并接入执行链 [P0]

WHEN 代码提交到仓库
THEN Git 治理规则必须接入 FR-047 定义的 5 层执行链，不在本条款另行定义第二套执行顺序

WHEN Git 治理规则被违反
THEN 对应层的 gate 阻断操作并返回违规详情

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-003

#### FR-004: 定义模块依赖层级模型 [P0]

WHEN 模块 A 导入模块 B
THEN 依赖方向必须符合领域分层 + 门禁模型：门禁 -> 基座 L0 -> 基座 L1 -> 基座 L2 -> 数据域 -> 分析域/决策域 -> 执行域 -> 入口；横切层可被任意层依赖；反向导入被阻断

WHEN 私有业务模块出现在公开库的 import 中
THEN boundary gate 失败并报告违规路径

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-004

#### FR-005: 定义 8 个仓库治理 REQ [P0]

WHEN 仓库初始化或模板生成
THEN 8 个 REQ（worktree/hooks/Makefile/CI/ruleset/evidence/audit/no-false-adopted）全部有对应文件或配置

WHEN 某个 REQ 缺失
THEN adoption-check gate 失败并报告缺失项

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-005

#### FR-006: 定义采纳状态机入口约束 [P0]

WHEN 下游仓库执行采纳流程
THEN adoption_status 从 not_run 开始，并必须使用 FR-050 的 8 状态枚举和 FR-051 的禁止转换规则

WHEN 采纳流程尝试绕过 FR-050/FR-051
THEN 操作被拒绝并返回禁止原因

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-006

#### FR-007: 定义 15 条基本真理 [P0]

WHEN goalcli 执行任何 gate
THEN 基本真理同义表作为不可违反的前置条件被检查（TRUTH-001..TRUTH-15，同义引用表见 `analysis/governance.md` 附录 A）

WHEN 基本真理被违反（如无证据宣称 DONE）
THEN 对应 gate 失败并引用具体 TRUTH 编号

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-007

#### FR-008: 定义 9 个正式 ADR [P1]

WHEN 查询 docs/adr/ 目录
THEN 存在 9 个状态为 Accepted 的正式 ADR（ADR-20260602-001 到 ADR-20260604-001）

WHEN 新架构决策产生
THEN 必须创建新 ADR 并遵循 ADR-000-template.md 格式

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-008

---

### 7.2 Go Reference Template（FR-009..FR-014）

#### FR-009: 公共 API 模板 [P0]

WHEN 模板渲染完成
THEN 生成的 Go 代码包含 Config, Validate, Sanitize, New, Close, HealthCheck, Error, Metrics, Version 全部公共 API

WHEN 生成的代码执行 `go vet`
THEN 无警告，所有导出符号有文档注释

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-009

#### FR-010: 9 种 ErrorKind [P0]

WHEN 调用方使用 `IsKind(err, ErrorKind...)` 做分支判断
THEN 9 种 ErrorKind（config/validation/connection/unavailable/timeout/auth/conflict/rate_limit/internal）全部可识别

WHEN 错误被包装（WrapError）
THEN errors.Is/errors.As 能穿透包装层匹配原始 ErrorKind

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-010

#### FR-011: 9 个最小 metrics [P0]

WHEN 客户端创建、关闭、请求、重试、健康检查等操作发生
THEN 对应 counter/gauge/histogram 指标自动递增或记录

WHEN Prometheus scrape /metrics 端点
THEN 返回 9 个最小指标（client_created_total, client_closed_total, client_errors_total, client_health_status, client_health_latency_ms, client_requests_total, client_request_duration_seconds, client_retries_total, client_inflight）

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-011

#### FR-012: HealthCheck JSON schema [P0]

WHEN HealthCheck() 被调用
THEN 返回的 JSON 符合 contracts/health.schema.json，包含 name/status/message/checked_at/latency_ms/metadata 字段

WHEN status 为 unhealthy
THEN message 字段必须包含人类可读的故障原因

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-012

#### FR-013: 配置显式传入 [P0]

WHEN 客户端通过 New() 创建
THEN 配置必须由调用方显式传入，不得隐式读取 `<secret-store-path>` 或环境变量

WHEN 配置中包含 secret/token/password 字段
THEN Sanitize() 必须将其屏蔽后才能输出到日志或 Evidence

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-013

#### FR-014: 配置 Validate 和 Sanitize [P0]

WHEN 调用 Validate() 且配置字段缺失或无效
THEN 返回 ErrorKindValidation 错误，列出所有不合法字段

WHEN 调用 Sanitize()
THEN 返回新副本，secret/token/password/key 字段被替换为 `***`

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-014

---

### 7.3 Generator（FR-015..FR-019）

#### FR-015: render_template.sh 渲染 [P0]

WHEN 执行 `scripts/render_template.sh --module <module-path> --name <module-name> --package <package> --out <path>`
THEN `--module` 驱动 `{{.ModulePath}}`、`--name` 驱动 `{{.Module}}`、`--package` 驱动 `{{.Package}}`、`--out` 驱动输出目录；模板中所有占位符必须全部替换为实际值，输出目录结构完整

WHEN 渲染目标目录已存在
THEN 不覆盖已有文件，返回警告

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-015

#### FR-016: 渲染范围全覆盖 [P0]

WHEN 模板渲染完成
THEN 生成的产物覆盖 Go 代码、JSON contract、shell 脚本、Makefile、CI 配置、文档 6 类文件

WHEN 某类文件缺失
THEN 渲染脚本返回非零退出码并报告缺失类别

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-016

#### FR-017: Repository Governance Pack [P0]

WHEN 渲染时传入 `--enable-governance --layer <L0|L1|L2> --standard-version <ver>`
THEN 生成的仓库包含完整治理文件集（Makefile targets、CI workflows、hooks、CODEOWNERS）

WHEN governance pack 生成后执行 `make governance-check`
THEN 所有 governance gate 通过

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-017

#### FR-018: make integration [P0]

WHEN 执行 `make integration`
THEN 临时渲染 kernel/configx/redisx 三个下游库，编译通过，gate 全部通过

WHEN 任一下游库渲染或编译失败
THEN `make integration` 返回非零退出码并报告失败库名

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-018

#### FR-019: Docker Toolchain Runtime 模板继承 [P1]

WHEN 渲染 Docker 相关模板
THEN .dockerignore、Dockerfile、docker-compose.yml 从标准模板继承，排除 `.git`/`<runtime-dirs>`/`.worktree`

WHEN Docker 构建执行
THEN 工具链版本与 docs/workflow/manifest 一致，无版本漂移

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-019

---

### 7.4 Harness（FR-020..FR-025）

#### FR-020: 66 个 gate 条目 [P0]

WHEN harness.yaml 被 goalcli 加载
THEN 66 个 gate 条目全部按 harness.yaml section 定义：44 required_gates、10 extended_gates、6 final_gates、6 goalcli_mva_gates；大写 MVA 条目作为 alias，不生成第二套权威 gate

WHEN 某个 gate 的 command 未在 Makefile 中注册
THEN harness validation 失败并报告未注册 gate

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-020

#### FR-021: 4 个 Context Profiles [P0]

WHEN goalcli 以 `--profile context-lite` 执行
THEN 只运行 governance-check

WHEN goalcli 以 `--profile context-release` 执行
THEN 运行 context-full + integration + dependency-check + standard-impact-check + score-check + evidence + release-evidence

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-021

#### FR-022: P0 Gate 失败阻断发布 [P0]

WHEN 任一 P0 gate 返回 failed
THEN 发布流程被阻断，不得创建 git tag

WHEN 所有 P0 gate 返回 passed
THEN 允许进入发布预检阶段

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-022

#### FR-023: Gate 结果归档为 Evidence [P0]

WHEN 任何 gate 执行完成
THEN 结果写入 `.agent/evidence/ledger.jsonl`，包含 gate_id/status/timestamp/evidence_path

WHEN Evidence 写入失败
THEN gate 视为 failed，不得报告 passed

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-023

#### FR-024: Release Scorecard [P0]

WHEN `goalcli score` 执行
THEN 返回 0~10.0 分，包含 gate runtime/CI/文档契约一致性维度

WHEN score < 9.8 且 `--min 9.8` 参数传入
THEN 命令返回非零退出码，阻断发布

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-024

#### FR-025: Debt Governance Gate [P0]

WHEN `make debt` 执行
THEN 7 类技术债规则全部检查，返回 debt score

WHEN debt score < 9.8
THEN gate 失败，P0 debt > 0 时阻断发布

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-025

---

### 7.5 Evidence Runtime（FR-026..FR-032）

#### FR-026: Evidence Ledger [P0]

WHEN gate 执行完成
THEN 结果 append 到 `.agent/evidence/ledger.jsonl`，格式为 JSONL，每行包含 schema_version/goal_id/gate_id/status/timestamp/evidence_path

WHEN ledger.jsonl 被篡改或删除
THEN evidence_replay gate 失败，checksum 不匹配

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-026

#### FR-027: Release Manifest [P0]

WHEN `make evidence` 执行
THEN 生成 `release/manifest/latest.json`，包含 module/version/commit/tree_sha/source_digest/go_version/generated_at/checks/contracts/dependencies/tools/standard_impact/downstream_sync_required/score/workflow/artifacts 等 20+ 字段

WHEN manifest schema 验证失败
THEN evidence gate 失败并报告缺失字段

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-027

#### FR-028: DONE with evidence 格式 [P0]

WHEN 贡献者声明任务完成
THEN 必须使用 `DONE with evidence:` 格式，后跟具体证据路径或命令输出

WHEN 使用其他格式（如 "tests pass"、"已完成"）
THEN 不被接受为合法完成声明

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-028

#### FR-029: 禁止无证据的 tests pass [P0]

WHEN 声称 "tests pass"
THEN 必须附带 `go test ./...` 的完整输出（包含 PASS/FAIL 行和覆盖率）

WHEN 无命令输出支撑
THEN evidence protocol 违规，gate 失败

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-029

#### FR-030: 禁止 skipped gate 记为 passed [P0]

WHEN 某个 required gate 被跳过（skip）
THEN Evidence 中必须记录为 skipped，不得记录为 passed

WHEN skipped gate 被记录为 passed
THEN evidence integrity check 失败

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-030

#### FR-031: 禁止 dirty workspace release [P0]

WHEN `git status` 显示未提交变更
THEN release-final-check 失败，不得宣称 release-final ready

WHEN workspace 干净且所有 gate passed
THEN 允许进入 release-final 阶段

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-031

#### FR-032: 禁止删除失败 Evidence [P0]

WHEN gate 执行失败
THEN 失败记录必须保留在 ledger.jsonl 中，不得删除或覆盖

WHEN 尝试删除失败 Evidence
THEN evidence append-only 策略阻止操作

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-032

---

### 7.6 Debt Governance Runtime（FR-033..FR-039）

#### FR-033: ARCH 类技术债规则 [P0]

WHEN `make debt` 执行 ARCH 检查
THEN NO_XGO_IMPORT, NO_L2_TO_L2_IMPORT, NO_IMPORT_CYCLE, FORBIDDEN_PACKAGE_NAME, NO_GOD_PACKAGE 5 条规则全部被验证

WHEN 任一 ARCH 规则被违反
THEN 返回违规文件路径、行号和规则编号

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-033

#### FR-034: DEP 类技术债规则 [P0]

WHEN `make debt` 执行 DEP 检查
THEN GOVULNCHECK, REACHABLE_CVE, UNPINNED_GITHUB_ACTION, CURL_BASH, LICENSE 等 10 条规则全部被验证

WHEN 发现未固定的 GitHub Action 或可达 CVE
THEN 返回依赖名称、版本和修复建议

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-034

#### FR-035: DOMAIN 类技术债规则 [P0]

WHEN `make debt` 执行 DOMAIN 检查
THEN FORBIDDEN_BUSINESS_TERM, BOUNDED_CONTEXT_VIOLATION 2 条规则被验证

WHEN 公开库中出现业务术语（如 ticker/order/position）
THEN 报告违规术语和所在文件

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-035

#### FR-036: DOCS 类技术债规则 [P0]

WHEN `make debt` 执行 DOCS 检查
THEN MISSING_REQUIRED_ADR, MAKE_TARGET_DRIFT, MANIFEST_SCHEMA_DRIFT 等 5 条规则全部被验证

WHEN Makefile target 与文档不一致
THEN 报告漂移的 target 名称和期望值

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-036

#### FR-037: TEST 类技术债规则 [P0]

WHEN `make debt` 执行 TEST 检查
THEN MISSING_CRITICAL_BEHAVIOR, FRAGILE_TEST, REAL_NETWORK_IN_UNIT 等 6 条规则全部被验证

WHEN 单元测试中发现真实网络调用
THEN 报告测试文件和违规调用

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-037

#### FR-038: IMPL 类技术债规则 [P0]

WHEN `make debt` 执行 IMPL 检查
THEN PANIC_RUNTIME 等规则被验证

WHEN 生产代码中发现 panic() 调用
THEN 报告文件路径和行号

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-038

#### FR-039: SEC 类技术债规则 [P0]

WHEN `make debt` 执行 SEC 检查
THEN 安全合规规则（日志脱敏、密钥管理、依赖漏洞）全部被验证

WHEN 发现安全违规（如明文密钥、未脱敏日志）
THEN 报告违规类型、严重度和修复建议

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-039

---

### 7.7 Goal Runtime v3.1.1（FR-040..FR-046）

#### FR-040: Goal Kernel（8 个核心对象）[P0]

WHEN goalcli 创建 Goal
THEN 对象模型包含 Goal/Spec/Design/Plan/Task/Test/Evidence/Review 8 个核心对象，每个对象有唯一 ID 和状态字段

WHEN 对象间引用不合法（如 Task 引用不存在的 Plan）
THEN 返回引用错误

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-040

#### FR-041: Harness Runtime [P0]

WHEN goalcli 启动
THEN Mode Router 加载 harness.yaml，Gate Registry 注册所有 gate，Command Registry 注册所有命令，Blocking Policy 决定阻断规则

WHEN harness.yaml schema 版本不匹配
THEN 启动失败并报告版本不兼容

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-041

#### FR-042: goalcli 唯一执行面 [P0]

WHEN 需要执行 gate/验证/发布操作
THEN 只能通过 cmd/goalcli 执行，拒绝第二套并列执行面

WHEN 发现绕过 goalcli 的直接 gate 调用
THEN governance-check 失败并报告违规

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-042

#### FR-043: 6 个 MVA Gate [P0]

WHEN Goal 生命周期推进
THEN 6 个 MVA Gate（goalcli_g12_acceptance/g13_delivery/g14_handover/g15a_downstream_adoption/g15b_certify/g16_runtime_final）按序执行

WHEN 任一 MVA Gate 失败
THEN 后续 Gate 不得执行，Goal 状态回退

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-043

#### FR-044: 4-Plane 架构 [P0]

WHEN Goal 执行
THEN 数据流经 Spec Plane -> Execution Plane -> Proof Plane -> Automation Plane 四层

WHEN Plane 间数据不一致（如 Spec 变更未传播到 Execution）
THEN proof_replay gate 检测到漂移并报告

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-044

#### FR-045: 10 个 REQ-PROOF [P0]

WHEN Proof Runtime 执行
THEN 10 个 REQ-PROOF（Facts SSOT, GateReport, Evidence Replay, Downstream Proof Schema 等）逐项验证

WHEN 某个 REQ-PROOF 未实现
THEN 对应 proof_depth 降级，evidence 标记为 partial

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-045

#### FR-046: 28 个 PR 执行包 [P1]

WHEN 查询 Goal Runtime 执行计划
THEN 28 个 PR 分 5 个 Phase（MVA Core -> 可信治理 -> 生态与协作 -> 成熟化 -> 自动化）有序排列

WHEN Phase N 的 PR 未完成
THEN Phase N+1 的 PR 不得开始

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-046

---

### 7.8 仓库治理协议（FR-047..FR-052）

#### FR-047: 5 层执行链 [P0]

WHEN 代码变更提交
THEN 按标准源 -> 生成器 -> 本地 hooks -> CI gate -> GitHub ruleset 顺序逐层生效

WHEN 某层被绕过（如直接 push 跳过 hooks）
THEN 后续层（CI/ruleset）阻断操作

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-047

#### FR-048: 禁止 main 开发 [P0]

WHEN 尝试直接 commit 到 main/master 分支
THEN pre-commit hook + pre-push hook + goalcli main-guard 三重阻断

WHEN 在 worktree 分支提交
THEN 允许正常提交流程

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-048

#### FR-049: 必须使用 git worktree [P0]

WHEN 执行开发任务
THEN 必须在 git worktree 中工作，goalcli worktree-guard 验证当前目录是 worktree

WHEN 在主工作目录开发
THEN worktree-guard 失败并提示创建 worktree

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-049

#### FR-050: 采纳状态机（8 状态）[P0]

WHEN 查询下游仓库采纳状态
THEN adoption_status 为 8 个合法值之一：not_run/registered/dry_run/patch_only/proof_verified/adopted/blocked/superseded

WHEN adoption_status 不在合法枚举中
THEN registry validation 失败

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-050

#### FR-051: 6 个禁止状态转换 [P0]

WHEN 尝试执行 registered->adopted、dry_run->adopted、patch_only->adopted、not_run->adopted、gate_outputs_missing->proof_based_adoption、baseline_scanned->adopted
THEN 操作被拒绝，返回禁止原因和正确路径

WHEN 按合法路径转换（如 registered->dry_run->proof_verified->adopted）
THEN 允许转换并记录 Evidence

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-051

#### FR-052: 下游同步治理（20 PR）[P1]

WHEN xlib-standard 标准变更
THEN 20 PR 执行链启动，按依赖顺序同步到下游仓库

WHEN 下游仓库同步失败
THEN 阻断后续下游同步，记录失败原因到 downstream-sync plan

> 完整 WHEN/THEN 见 [FR-DETAIL.md](./FR-DETAIL.md) FR-052

---

## 8. Business Rules

> 从 FR-DETAIL.md、analysis/rules.md 和 analysis/governance.md 提炼的硬性约束规则。

### BR-001: 没有证据不允许 DONE

任何完成声明必须使用 `DONE with evidence:` 格式，后跟具体证据路径或命令输出。口头声明、"tests pass"、"已完成" 等不带证据的表述不被接受。

**约束**：完成声明必须附带可验证的证据（命令输出、文件路径、artifact）。
**违反时**：gate 失败，引用 RULE-EVIDENCE-001。

### BR-002: Goal 必须从真实上下文开始

Goal 的创建必须基于真实的业务需求或技术问题，不得为虚构场景创建 Goal。

**约束**：Goal.SpecRef 必须指向有效的分析文档或 Issue。
**违反时**：goal validation 失败，返回 RULE-CORE-002 违规。

### BR-003: 需求必须可验证

每个 FR 必须有对应的 AC，每个 AC 必须有对应的 TC 或 gate 覆盖。不可验证的需求视为规格缺陷。

**约束**：FR->AC->TC 追溯链必须完整。
**违反时**：spec-lint 失败，报告未覆盖的 FR。

### BR-004: 所有变更必须可追踪

每个代码变更必须关联到 FR、ADR 或 Issue，不得存在无来源的变更。

**约束**：commit message 或 PR 必须引用 FR-NNN / ADR-NNN / Issue-NNN。
**违反时**：Git 治理规则（FR-003）阻断提交。

### BR-005: Harness 是机器裁判

Gate 的通过/失败由 harness 机器裁决，不接受人工覆盖或口头声明。

**约束**：所有 gate 结果必须写入 Evidence Ledger（FR-026）。
**违反时**：evidence integrity check 失败。

### BR-006: 登记态不等于 adopted

registered、dry_run、patch_only 状态不得直接转换为 adopted。adopted 状态必须经过 proof-based adoption 流程。

**约束**：adoption_status 转换必须遵循 FR-051 的 6 个禁止转换规则。
**违反时**：adoption-check gate 失败，返回禁止转换原因。

### BR-007: 依赖方向只能从高层指向低层

模块依赖必须遵循 FR-004 定义的领域分层模型。反向导入、循环导入、跨域私有导入均被禁止。

**约束**：import 路径必须符合依赖矩阵。
**违反时**：boundary gate 失败，报告违规路径和文件位置。

### BR-008: 单一执行面

`cmd/goalcli` 是唯一的机器执行入口。shell scripts 可作为 delegated helper 或兼容层，但不能成为事实裁决源。

**约束**：所有 gate/验证/发布操作必须通过 goalcli 执行。
**违反时**：governance-check 失败，报告绕过 goalcli 的违规调用。

### BR-009: 证据不可删除

Evidence Ledger（ledger.jsonl）采用 append-only 策略。失败记录不得删除或覆盖。

**约束**：ledger.jsonl 只允许 append 操作。
**违反时**：evidence_replay gate 失败，checksum 不匹配。

### BR-010: 弱事实禁止升级为强事实

| 弱事实 | 不可视为 |
|--------|----------|
| `registered` | `adopted` |
| `baseline_scanned` | `implemented` |
| `dry_run_ready` | `executed` |
| `artifact_exists` | `usable` |
| `CHECK_STATUS=passed` | `release-ready evidence` |
| downstream sync plan | downstream adoption proof |

**约束**：truth-state 分层必须严格区分。
**违反时**：对应 gate 失败，记录 `truth_state=violated`。

### BR-011: 配置不得隐式读取

所有配置必须由调用方显式传入，禁止隐式读取 `<secret-store-path>` 或任何生产路径。

**约束**：`New(ctx, Config{})` 不得访问文件系统或环境变量获取配置。
**违反时**：enforcer 拒绝，返回 ErrorKindConfig（RULE-SEC 相关）。

### BR-012: 日志不得输出敏感数据

日志中不得出现 secret、token、password、private key、连接凭据的明文。

**约束**：所有日志输出必须经过 Sanitize 处理。
**违反时**：SEC 类技术债 gate 失败，报告违规日志位置。

### BR-013: 测试 fixture 必须脱敏

测试和生成器中的 fixture 必须是脱敏、虚构或 disposable test repo 数据。任何真实 secret、真实账户和生产 endpoint 禁止进入仓库、Evidence、logs 或 manifest。

**约束**：testdata/ 中的 fixture 不得包含真实凭据。
**违反时**：secret 扫描 gate 失败。

### BR-014: P0 Gate 失败阻断发布

任一 P0 gate 返回 failed 时，发布流程被阻断，不得创建 git tag。

**约束**：所有 P0 gate 必须 passed 才能进入发布预检阶段。
**违反时**：release-final-check 失败。

### BR-015: Docker 不是第二套 Gate

Docker 只是同一套门禁的可复现执行环境，不创建独立质量声明或第二套 gate。

**约束**：Docker 构建结果不得替代本地/CI gate 的裁决。
**违反时**：不适用（结构性约束，非 gate 判定）。

---

## 9. Interface Contract

> xlib-standard 不是 Go 运行时代码，以下适配为 Generator API、goalcli CLI 契约和 Evidence JSON Schema。

### 9.1 Generator API（render_template.sh CLI 参数契约）

```bash
scripts/render_template.sh \
  --module <module-path>      # Go module path，如 github.com/ZoneCNH/kernel
  --name <module-name>        # 短模块名，用于类型名前缀，如 Kernel
  --package <package>         # Go 包名，如 kernel
  --out <path>                # 输出目录
  [--enable-governance]       # 可选：生成 Repository Governance Pack
  [--layer <L0|L1|L2>]       # 可选：基座层级
  [--standard-version <ver>] # 可选：标准版本号
```

**退出码**：

| 退出码 | 含义 |
|--------|------|
| 0 | 渲染成功 |
| 1 | 渲染失败（模板缺失、占位符未替换、文件类别缺失） |
| 2 | 非法参数 |

**模板占位符**：

| 占位符 | 驱动参数 | 示例值 |
|--------|----------|--------|
| `{{.Module}}` | `--name` | `Kernel` |
| `{{.Package}}` | `--package` | `kernel` |
| `{{.ModulePath}}` | `--module` | `github.com/ZoneCNH/kernel` |

### 9.2 goalcli CLI 契约

```bash
goalcli <command> [flags]
```

**核心命令**：

| 命令 | 说明 | 退出码 |
|------|------|--------|
| `goalcli score` | Release Scorecard，返回 0~10.0 分 | 0=pass, 1=score < min |
| `goalcli score --min 9.8` | Score 低于阈值时阻断 | 0=pass, 1=blocked |
| `goalcli harness-runtime-check` | Harness Runtime 验证 | 0=pass, 1=fail |
| `goalcli pr-pack-check` | PR 执行包验证 | 0=pass, 1=fail |
| `goalcli worktree-guard` | 验证当前目录是 worktree | 0=in worktree, 1=not |
| `goalcli main-guard` | 阻止 main 分支开发 | 0=not main, 1=blocked |

**输出格式**：JSON report 符合 `goalcli-report.schema.json`。

| 字段 | 类型 | 说明 |
|------|------|------|
| `schema_version` | `string` | 如 `"1.0"` |
| `goal_id` | `string` | 关联 Goal |
| `gate_id` | `string` | 关联 Gate |
| `status` | `string` | `passed` / `failed` / `planned` / `gap` |
| `exit_code` | `int` | 0=passed, 1=failed/planned/gap, 2=非法参数 |
| `timestamp` | `string` | RFC3339 |
| `evidence_path` | `string` | 证据文件路径 |

**P 命令数量**：P0 commands 68 个、P1 commands 26 个、P2 commands 12 个，共 14 个 surface 必须同批同步。

### 9.3 Evidence JSON Schema

**Gate Result Envelope**：

```json
{
  "schema_version": "1.0",
  "goal_id": "GOAL-...",
  "gate_id": "...",
  "status": "passed|failed|planned|gap",
  "exit_code": 0,
  "timestamp": "2026-06-07T...",
  "evidence_path": "..."
}
```

### 9.4 Go Reference Template（模板源，非可执行 Go）

```gotemplate
package {{.Package}}

import (
    "context"
    "time"
)

type Config struct {
    // 由各模块自行定义具体字段；上游规格只约束方法集。
}

func (c *Config) Validate() error
func (c *Config) Sanitize() Config

type {{.Module}}Client interface {
    Close(ctx context.Context) error
    HealthCheck(ctx context.Context) (HealthStatus, error)
}

func New(ctx context.Context, cfg Config) ({{.Module}}Client, error)

type HealthStatus struct {
    Name      string         `json:"name"`
    Status    string         `json:"status"`
    Message   string         `json:"message,omitempty"`
    CheckedAt time.Time      `json:"checked_at"`
    LatencyMs int64          `json:"latency_ms"`
    Metadata  map[string]any `json:"metadata,omitempty"`
}

type ErrorKind string

const (
    ErrorKindConfig      ErrorKind = "config"
    ErrorKindValidation  ErrorKind = "validation"
    ErrorKindConnection  ErrorKind = "connection"
    ErrorKindUnavailable ErrorKind = "unavailable"
    ErrorKindTimeout     ErrorKind = "timeout"
    ErrorKindAuth        ErrorKind = "auth"
    ErrorKindConflict    ErrorKind = "conflict"
    ErrorKindRateLimit   ErrorKind = "rate_limit"
    ErrorKindInternal    ErrorKind = "internal"
)

func NewError(kind ErrorKind, msg string) error
func WrapError(kind ErrorKind, cause error, msg string) error
func IsKind(err error, kinds ...ErrorKind) bool
func Metrics() []MetricDescriptor
func Version() string
```

> 模板渲染产物才是 `go vet ./...` 的目标，模板源本身不是可执行 Go 代码。

---

## 10. Data Model

> xlib-standard 的数据模型适配为 Gate Entry、Evidence Ledger JSONL、Release Manifest JSON、AdoptionStatus 枚举和 ErrorKind 枚举。

### 10.1 AdoptionStatus 枚举（8 状态）

```go
type AdoptionStatus string

const (
    AdoptionNotRun        AdoptionStatus = "not_run"
    AdoptionRegistered    AdoptionStatus = "registered"
    AdoptionDryRun        AdoptionStatus = "dry_run"
    AdoptionPatchOnly     AdoptionStatus = "patch_only"
    AdoptionProofVerified AdoptionStatus = "proof_verified"
    AdoptionAdopted       AdoptionStatus = "adopted"
    AdoptionBlocked       AdoptionStatus = "blocked"
    AdoptionSuperseded    AdoptionStatus = "superseded"
)
```

**合法转换路径**：registered -> dry_run -> proof_verified -> adopted；任何绕过中间状态的转换均被 FR-051 禁止。

### 10.2 ErrorKind 枚举（9 种）

| ErrorKind | Retryable | 说明 |
|-----------|-----------|------|
| `config` | 否 | 配置错误 |
| `validation` | 否 | 验证失败 |
| `connection` | 视场景 | 连接错误 |
| `unavailable` | 视场景 | 服务不可用 |
| `timeout` | 是 | 超时 |
| `auth` | 否 | 认证失败 |
| `conflict` | 否 | 冲突 |
| `rate_limit` | 是 | 限流 |
| `internal` | 否 | 内部错误 |

### 10.3 Evidence Ledger 行结构（JSONL）

```go
type EvidenceEntry struct {
    SchemaVersion  string         `json:"schema_version"`   // "1.0"
    Timestamp      string         `json:"timestamp"`        // RFC3339
    GoalID         string         `json:"goal_id"`          // 关联 Goal
    GateID         string         `json:"gate_id"`          // 关联 Gate
    Status         string         `json:"status"`           // passed/failed/planned/gap
    ExitCode       int            `json:"exit_code"`        // 0=passed, 1=failed
    TruthState     string         `json:"truth_state"`      // verified/planned/weak/violated/unverified_remote/incomplete
    AdoptionStatus string         `json:"adoption_status"`  // 与 AdoptionStatus 枚举一致
    EvidenceState  string         `json:"evidence_state"`   // not_run/partial/complete
    EvidencePath   string         `json:"evidence_path"`    // 派生 evidence pack 路径
    Command        string         `json:"command"`          // 触发命令
    Details        map[string]any `json:"details"`          // 任意 JSON 详情
}
```

**约束**：append-only（BR-009），篡改导致 checksum 不匹配（FR-026）。

### 10.4 Goal 核心对象

```go
type Goal struct {
    ID        string    // GOAL-YYYYMMDD-NNN，全局唯一
    Title     string    // 一句话目标描述
    Status    GoalStatus // draft/accepted/in_progress/blocked/done/superseded
    Priority  string    // P0/P1/P2
    SpecRef   string    // 关联 ANALYSIS.md 路径与锚点
    Plan      []TaskRef // 拆解出的 Task 列表
    Evidence  []EvidenceRef // Evidence Ledger 行号或路径
    CreatedAt time.Time // RFC3339
    UpdatedAt time.Time // RFC3339
}
```

### 10.5 Release Manifest 结构（latest.json）

| 字段 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| `module` | `string` | 是 | 模块名 |
| `version` | `string` | 是 | 版本号 |
| `commit` | `string` | 是 | git commit SHA |
| `tree_sha` | `string` | 是 | git tree SHA |
| `source_digest` | `string` | 是 | 源码摘要 |
| `go_version` | `string` | 是 | Go 工具链版本 |
| `generated_at` | `string` | 是 | RFC3339 |
| `checks` | `object` | 是 | gate 检查结果 |
| `contracts` | `object` | 是 | 契约验证结果 |
| `dependencies` | `object` | 是 | 依赖树 |
| `tools` | `object` | 是 | 工具链版本 |
| `standard_impact` | `object` | 是 | 标准影响评估 |
| `downstream_sync_required` | `bool` | 是 | 是否需要下游同步 |
| `score` | `number` | 是 | Release Scorecard 分数 |
| `workflow` | `object` | 是 | CI workflow 信息 |
| `artifacts` | `object` | 是 | 产物列表 |

### 10.6 Harness Gate 分类

| harness.yaml section | 数量 | 语义边界 |
|----------------------|------|----------|
| `required_gates` | 44 | 当前权威 gate 定义来源 |
| `extended_gates` | 10 | 扩展验证（property、golden、fuzz_smoke 等） |
| `final_gates` | 6 | 发布最终判定 |
| `goalcli_mva_gates` | 6 | MVA alias，映射到 goalcli G12-G16 |

### 10.7 TruthState 枚举

| 状态 | 说明 |
|------|------|
| `verified` | 已验证 |
| `planned` | 已计划 |
| `weak` | 弱事实 |
| `violated` | 已违反 |
| `unverified_remote` | 远端未验证 |
| `incomplete` | 不完整 |

---

## 11. Config Schema

> xlib-standard 的配置适配为 harness.yaml schema、registry.yaml schema 和 goalcli 配置。

### 11.1 harness.yaml Schema

```yaml
# harness.yaml 顶层结构
schema_version: string          # required，如 "1.0"
required_gates:                 # 44 个必跑 gate
  - id: string                  # gate ID，如 "fmt", "vet", "lint"
    command: string             # Makefile target 或 shell 命令
    priority: string            # P0/P1/P2
    timeout: string             # 如 "5m"
extended_gates:                 # 10 个扩展 gate
  - id: string
    command: string
    priority: string
    timeout: string
final_gates:                    # 6 个发布最终 gate
  - id: string
    command: string
    priority: string
    timeout: string
goalcli_mva_gates:              # 6 个 MVA alias gate
  - id: string                  # 如 "goalcli_g12_acceptance"
    command: string
    priority: string
    timeout: string
```

### 11.2 registry.yaml Schema

```yaml
# registry.yaml 顶层结构
schema_version: string          # required
rules:                          # 419 条规则
  - id: string                  # 规则 ID，如 "RULE-CORE-001"
    prefix: string              # 前缀类别：RULE-CORE/RULE-HARNESS/RULE-EVIDENCE 等
    priority: string            # P0/P1/P2
    category: string            # ARCH/DEP/DOMAIN/DOCS/TEST/IMPL/SEC
    description: string         # 规则描述
    enforcer: string            # 执行器标识
```

### 11.3 goalcli 配置

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `--profile` | `string` | `context-standard` | Context Profile（context-lite/context-standard/context-full/context-release） |
| `--min` | `number` | `9.8` | Score 最低阈值 |
| `--strict` | `bool` | `false` | 遇到 planned/gap 时阻断 |
| `--verify` | `bool` | `false` | 验证模式 |
| `--output` | `string` | `human` | 输出格式（human/json） |

### 11.4 Context Profiles

| Profile | 组合 |
|---------|------|
| `context-lite` | governance-check |
| `context-standard` | governance-check + p1-governance-check + docs-check |
| `context-full` | governance-check + p1-governance-check + p2-runtime-check |
| `context-release` | context-full + integration + dependency-check + standard-impact-check + score-check + evidence + release-evidence |

---

## 12. Error Handling

> xlib-standard 不是运行时代码，错误处理适配为 gate 失败语义和 evidence 协议违规。

### 12.1 Gate 失败分类

| 失败类型 | 触发条件 | 处理方式 | 对应 FR |
|----------|----------|----------|---------|
| `gate_failed` | P0 gate 返回 failed | 阻断发布，不得创建 git tag | FR-022 |
| `evidence_write_failed` | Evidence 写入失败 | gate 视为 failed | FR-023 |
| `manifest_schema_invalid` | Release Manifest schema 不匹配 | evidence gate 失败 | FR-027 |
| `done_without_evidence` | 完成声明无证据 | 不被接受为合法完成 | FR-028 |
| `skilled_as_passed` | skipped gate 记为 passed | evidence integrity check 失败 | FR-030 |
| `dirty_workspace` | git status 有变更 | release-final-check 失败 | FR-031 |
| `evidence_deleted` | 尝试删除失败 Evidence | append-only 策略阻止 | FR-032 |
| `adoption_forbidden_transition` | 禁止的状态转换 | 操作被拒绝 | FR-051 |
| `harness_version_mismatch` | harness.yaml schema 版本不匹配 | 启动失败 | FR-041 |

### 12.2 xlibgate 硬性失败（7 种）

| 失败类型 | 说明 | 处理方式 |
|----------|------|----------|
| `secret_leak` | 检测到 secret 泄露 | fail-closed，不得降级 |
| `layer_violation` | 依赖方向违反 | fail-closed |
| `missing_required_contract` | 缺失必需契约 | fail-closed |
| `missing_required_evidence` | 缺失必需证据 | fail-closed |
| `race_detected` | 检测到 data race | fail-closed |
| `goroutine_leak` | 检测到 goroutine 泄漏 | fail-closed |
| `release_level_overclaimed` | 发布级别过度声明 | fail-closed |

### 12.3 错误消息格式

```
xlib-standard: <gate-id>: <detail>
```

---

## 13. Edge Cases

### 13.1 弱事实升级（truth-state）

| 场景 | 弱事实 | 不可视为 | 检测点 |
|------|--------|----------|--------|
| EC-G1 | `registered` | `adopted` | FR-006 / FR-051 |
| EC-G2 | `baseline_scanned` | `implemented` | EvidenceEntry.truth_state |
| EC-G3 | `dry_run_ready` | `executed` | gate exit code / status |
| EC-G4 | `artifact_exists` | `usable` | release-final-check 字段完整性 |
| EC-G5 | `CHECK_STATUS=passed` | `release-ready evidence` | GitHub checks + release evidence pack |
| EC-G6 | downstream sync plan | downstream adoption proof | FR-052 / FR-006 |

### 13.2 模板边界场景

| 场景 | 预期行为 |
|------|----------|
| 渲染目标目录已存在 | 不覆盖已有文件，返回警告 |
| 模板占位符未全部替换 | 渲染脚本返回非零退出码 |
| `go vet` 输出有警告 | 渲染产物视为不合格 |
| Sanitize 嵌套 nil map | 返回有效 Config 副本，不 panic |
| HealthCheck 超时且下游不可达 | 返回 unhealthy/degraded，不挂起 |
| 并发 N goroutine 同时调用 Close | 幂等，无 race |
| Validate 在 nil receiver | 返回 ErrorKindValidation，禁止 panic |

### 13.3 远端治理不可本地证明

本地文件不能证明 GitHub branch protection 已启用、ruleset 生效、required checks 绑定、GitHub Release object 已创建。这些必须通过远端 API / CI artifact / ruleset export 单独证明，记录为 `truth_state=unverified_remote`。

### 13.4 配置拓扑迁移

`.config/xlib` 是 v1.0.0 迁移目标；当前上游仍有 `.agent/**`、`.xlib/**`、registry、policy 和 evidence ledger。迁移完成前，两套路径并存。

---

## 14. Directory Structure

> xlib-standard 不是运行时 Go 代码，目录结构适配为上游仓库布局。

### 14.1 上游仓库目录结构

```text
xlib-standard/
├── cmd/goalcli/          # 唯一 Go runtime 执行面
├── scripts/              # render_template.sh 等 helper
├── docs/
│   ├── standard/         # 标准文档（Current Standard 事实层级）
│   ├── testing/          # 测试补充
│   ├── l2/               # L2 适配规范
│   ├── evidence/         # 证据补充
│   ├── adr/              # 9 个正式 ADR
│   └── v0.6.0/           # 历史版本文档
├── contracts/            # goalcli-report.schema.json 等
├── .agent/               # 控制面（evidence/ledger.jsonl）
├── .xlib/                # facts（v1.0.0 前与 .agent 并存）
├── .config/              # v1.0.0 目标数据面
├── .worktree/            # 当前工作上下文与历史规划
├── release/
│   └── manifest/         # Release Manifest (latest.json)
├── registry/             # registry.yaml
├── Makefile              # make debt / make evidence / make integration
└── README.md
```

### 14.2 依赖方向模型

```text
基座 · Foundation Gate 子层：xlib-standard, xlibgate
    |
    v
基座 L0：kernel
    |
    v
基座 L1：configx / observex / testkitx / resiliencx / schedulex
    |
    v
基座 L2：redisx / kafkax / natsx / postgresx / taosx / ossx / clickhousex
    |
    v
私有域：xgo-contracts -> xgo-market-data, xgo-macro-data -> engines -> x.go
```

**约束**：依赖只能从高层指向低层，不可反向；`xlib-standard` 不得依赖 `x.go` 或业务仓库；生成库不得依赖 `x.go`。

### 14.3 规则权威顺序

```
iron-rules.md > registry.yaml > *-rules.md > ADR-* > .worktree/goal-patch.md
```

---

## 15. Dependencies

> xlib-standard 不是运行时 Go 代码，无运行时依赖。本节描述配置拓扑依赖和下游消费者关系。

### 15.0 运行时依赖

无。xlib-standard 不参与业务运行时，不被任何模块 import。

### 15.1 配置拓扑

### 15.1 配置路径

| 路径 | 用途 | 状态 |
|------|------|------|
| `.agent/` | 控制面（evidence、ledger） | 当前使用 |
| `.xlib/` | facts | 当前使用，v1.0.0 前与 .agent 并存 |
| `.config/` | v1.0.0 目标数据面 | 迁移目标 |
| `.agent/harness/harness.yaml` | Gate 定义 | 权威来源 |
| `registry/registry.yaml` | 规则注册表 | 权威来源 |

### 15.2 配置迁移约束

- v1.0.0 前将配置拓扑收敛到 `.config/`（G-P0-5）
- 迁移期间 `.agent/**`、`.xlib/**` 与 `.config/` 并存
- No-Go 条件与 release 裁决标准详见上游 `docs/standard/release-standard.md`

---

## 16. Testing

> TC 使用 `xlib-TC-001..xlib-TC-017` 命名空间。完整 TC 表见 `analysis/runtime.md` §6。

### 16.1 测试用例

| TC ID | 测试类型 | 对应 FR | 场景 | 预期结果 |
|-------|----------|---------|------|----------|
| xlib-TC-001 | TL1 Unit | FR-009, FR-013 | 调用 `New(ctx, Config{})` 传入零值 Config | 返回 ErrorKindValidation；未创建任何 goroutine/FD |
| xlib-TC-002 | TL1 Unit | FR-014 | 调用 `New(nil, validCfg)` 传入 nil context | 返回 ErrorKindValidation；panic 不被允许 |
| xlib-TC-003 | TL1 Unit | FR-013, FR-014 | 调用 `New(canceledCtx, validCfg)` | 立即返回 ErrorKindTimeout 或 ErrorKindUnavailable；不发起远端连接 |
| xlib-TC-004 | TL1 Unit | FR-009 | `client.Close(ctx)` 调用 N 次（N>=2） | 幂等：每次都返回 nil；底层资源只释放一次 |
| xlib-TC-005 | TL2 Contract | FR-012 | `client.HealthCheck(timeoutCtx)`，timeout=1ms，下游不可用 | 返回 status=unhealthy/degraded，latency_ms<=timeout+epsilon；不挂起 |
| xlib-TC-006 | TL2 Property | FR-014 | 任意嵌套 `Config{Nested: {Token: rand}}` 调用 `Sanitize()` | 返回值的所有 token/secret/password/private_key 字段为空；原对象不被修改 |
| xlib-TC-007 | TL2 Property | FR-014 | `cfg.Sanitize()` 返回值修改其 map/slice | 原 cfg 字段不变（验证 deep copy） |
| xlib-TC-008 | TL2 Boundary | FR-009 | 并发 N goroutine 同时调用 `client.Close(ctx)` | 无 race（`go test -race` 通过）；无 panic |
| xlib-TC-009 | TL2 Security | FR-013 | `os.Setenv("HOME","/home/k8s")` 后调用 `New(ctx, Config{})` | enforcer 拒绝隐式读取；返回 ErrorKindConfig |
| xlib-TC-010 | TL4 Golden | FR-012 | `HealthCheck()` 输出 JSON | 与 testdata/health.golden.json 字节级一致（除 checked_at/latency_ms） |
| xlib-TC-011 | TL4 Fuzz | FR-014 | `go test -fuzz=FuzzConfigValidate` >= 30s | 无 panic；任何 Validate 失败都返回 ErrorKindValidation |
| xlib-TC-012 | TL6 Release | FR-027 | `goalcli release-final-check` 在缺失 manifest 任一必填字段时 | 退出码 1；evidence 记录 truth_state=incomplete；阻断 release |
| xlib-TC-013 | TL2 Truth-state | FR-006, FR-050, FR-051 | adoption_status=registered 直接尝试 -> adopted | enforcer 拒绝；返回禁止转换原因 |
| xlib-TC-014 | TL2 Contract | FR-010 | `IsKind(err, ErrorKindTimeout)` 应用于 `WrapError(ErrorKindTimeout, cause, "")` | 返回 true；errors.Is(err, cause) 也必须为 true |
| xlib-TC-015 | TL1 Unit | FR-011 | `Metrics()` 返回值 | 长度 == 9；命名匹配指标表；无重复 |
| xlib-TC-016 | TL2 Boundary | FR-010 | 注入连接池/FD/内存上限（fake limiter），调用 New/client 操作 | 返回 ErrorKindUnavailable 或 ErrorKindRateLimit；保留 cause；进程不 OOM |
| xlib-TC-017 | TL1 Unit | FR-014 | `var c *Config; c.Validate()`（nil receiver） | 返回 ErrorKindValidation；禁止 panic |

### 16.2 无显式 TC 的 FR 处理

| 无 TC 的 FR | 由何替代覆盖 | 证据路径 |
|-------------|--------------|----------|
| FR-001 (419 条规则) | harness gate `registry-validate` | `pack/registry-validate.json` |
| FR-002 (7 类技术债) | harness gate `debt-scan` | `pack/debt-scan.json` |
| FR-005 (8 个 REQ) | harness gate `adoption-check` | `pack/adoption-check.json` |
| FR-046 (28 个 PR 包) | 计划性 FR，由 goal-runtime ledger 追踪 | `.agent/evidence/ledger.jsonl` |
| FR-052 (20 PR 下游同步) | 计划性 FR，由 downstream-sync-policy gate 追踪 | `pack/downstream-sync.json` |

### 16.3 测试分层

| 层 | 名称 | 说明 |
|----|------|------|
| TL0 | Spec/ATDD | 验收测试驱动 |
| TL1 | Unit/TDD | 单元测试 |
| TL2 | Contract/Boundary/Security | 契约/边界/安全测试 |
| TL3 | Integration Smoke | 集成冒烟测试 |
| TL4 | Property/Fuzz/Golden | 属性/模糊/黄金测试 |
| TL5 | Compatibility/Observability | 兼容性/可观测性测试 |
| TL6 | Release Evidence | 发布证据测试 |
| TL7 | Profile-Specific Heavy | 特定 Profile 重型测试 |

---

## 17. Performance Budget

### 17.1 Gate 执行性能

| 操作 | 指标 | 目标 | 测量方式 |
|------|------|------|----------|
| 单 Gate 最大执行时间 | 延迟 | < 5 分钟 | harness timeout |
| 核心质量 Gates（fmt/vet/lint/test/race） | 总延迟 | < 15 分钟 | CI pipeline |
| Release Scorecard 计算 | 延迟 | < 30 秒 | `goalcli score` |
| Evidence Manifest 生成 | 延迟 | < 10 秒 | `make evidence` |
| `goalcli score --min 9.8` | 延迟 | < 60 秒 | benchmark |

### 17.2 模板渲染性能

| 操作 | 指标 | 目标 | 测量方式 |
|------|------|------|----------|
| 单模块渲染 | 延迟 | < 30 秒 | `time render_template.sh` |
| `make integration`（3 个下游库） | 总延迟 | < 5 分钟 | CI pipeline |
| 渲染产物 `go vet` | 延迟 | < 60 秒 | `go vet ./...` |

---

## 18. Observability

### 18.1 goalcli 日志事件

| 事件 | 级别 | 说明 |
|------|------|------|
| `goalcli.gate.started` | info | gate 执行开始 |
| `goalcli.gate.completed` | info | gate 执行完成，含 status 和 duration |
| `goalcli.gate.failed` | warn | gate 失败，含 violation 详情 |
| `goalcli.score.calculated` | info | Score 计算完成 |
| `goalcli.evidence.appended` | info | Evidence 写入 ledger |
| `goalcli.evidence.integrity_failed` | error | Evidence 完整性检查失败 |
| `goalcli.adoption.transition_rejected` | warn | 采纳状态转换被拒绝 |

### 18.2 Evidence Metrics

| 指标 | 类型 | 说明 |
|------|------|------|
| `goalcli_gates_total` | counter | gate 执行总数 |
| `goalcli_gates_failed_total` | counter | gate 失败总数 |
| `goalcli_score` | gauge | 当前 Release Scorecard 分数 |
| `goalcli_evidence_entries_total` | counter | Evidence Ledger 条目总数 |
| `goalcli_adoption_status` | gauge | 下游采纳状态（按状态枚举编码） |

### 18.3 日志脱敏

- 日志中不得出现 secret/token/password/private key/连接凭据的明文（BR-012）
- 所有日志输出必须经过 Sanitize 处理
- metrics label 不能包含高基数字段、用户凭据或业务私有标识

---

## 19. Security

### 19.1 P0 安全规则

| 规则 | 编号 | 说明 |
|------|------|------|
| 不得隐式读取 `<secret-store-path>` | XS-CORE-016 | 配置必须显式传入 |
| 不得将密钥内容写入源码/README/测试日志/manifest/PR/Evidence | XS-CORE-017 | 全链路密钥隔离 |
| 日志不得输出 secret/token/password/private key/连接凭据 | XS-CORE-008 | 日志脱敏 |
| Claude review 仅限本地执行，不使用 repo API key | ARA-002 | AI 代理安全边界 |
| Claude 审查脚本禁用工具访问，禁止 push/branch/close/settings 操作 | ARA-003 | AI 代理权限最小化 |
| 第三方 Action 必须固定为 40 位 commit SHA | supply-chain.md | 供应链安全 |
| Docker image build context 不得包含 Git metadata 或 Agent 运行态 | DTS-003 | Docker 安全边界 |
| 未列入 contract 的私密变量不得默认传入容器 | DTS-005 | 容器 secret 隔离 |

### 19.2 测试 Fixture 安全

- fixture 必须是脱敏、虚构或 disposable test repo 数据（BR-013）
- 任何真实 secret、真实账户和生产 endpoint 禁止进入仓库、Evidence、logs 或 manifest
- secret 扫描 gate（gitleaks）作为强制门禁

### 19.3 远端安全边界

- 本地文件不能证明远端 branch protection、ruleset、required checks 当前启用
- 远端证据必须通过 GitHub API / CI artifact / ruleset export 单独证明
- pinned 证据见 `REMOTE-EVIDENCE.md`

---

## 20. CI Gate

### 20.1 统一验收清单

> 每个 AC 对应一个或多个 FR。

| AC 编号 | 验收标准 | 对应 FR | 验证方式 |
|---------|----------|---------|----------|
| AC-T01 | 模板渲染产物通过 `go vet ./...` 零警告 | FR-009 | CI gate |
| AC-T02 | harness.yaml 66 个 gate 条目全部在 Makefile 中注册 | FR-020, FR-015..FR-019, FR-023, FR-028, FR-029 | `goalcli harness-runtime-check` |
| AC-T03 | docs/adr/ 存在 9 个 Accepted ADR | FR-008 | 文件存在性检查 |
| AC-T04 | registry.yaml 419 条规则 schema 验证通过 | FR-001 | `goalcli registry-validate` |
| AC-I01 | 8 状态枚举和 6 个禁止转换规则正确执行 | FR-006, FR-050, FR-051 | `xlib-TC-013` |
| AC-I02 | `make integration` 渲染 kernel/configx/redisx 三个下游库，编译通过，gate 全过 | FR-018, FR-020, FR-021, FR-042, FR-047..FR-049 | CI pipeline |
| AC-I03 | goalcli JSON 输出符合 goalcli-report.schema.json | FR-041 | schema validation |
| AC-I04 | `make debt` 7 类技术债规则全部检查，debt score >= 9.8 | FR-002, FR-004, FR-025, FR-033..FR-039 | CI gate |
| AC-G01 | Goal Kernel 8 个核心对象模型正确创建和引用 | FR-040, FR-044, FR-046, FR-052 | `goalcli harness-runtime-check` |
| AC-G02 | Harness Runtime Mode Router/Gate Registry/Command Registry/Blocking Policy 正确加载 | FR-041, FR-043, FR-045 | `goalcli harness-runtime-check` |
| AC-R01 | Evidence Ledger append-only，篡改检测有效 | FR-023, FR-026, FR-027 | `evidence_replay` gate |
| AC-R02 | P0 Gate 失败阻断发布 | FR-022 | `release_final_check` gate |
| AC-R03 | Release Scorecard 返回 0~10.0 分，score < 9.8 阻断 | FR-024 | `goalcli score --min 9.8` |
| AC-R04 | dirty workspace 阻断 release | FR-031 | `release-final-check` gate |
| AC-R05 | DONE with evidence 格式强制 | FR-028, FR-029 | evidence protocol gate |
| AC-R06 | skipped gate 不得记为 passed，失败 Evidence 不得删除 | FR-030, FR-032 | `evidence_integrity` gate |

### 20.2 66 Gate 条目分类

| 分类 | 数量 | 说明 |
|------|------|------|
| required_gates | 44 | 必须通过，失败阻断发布 |
| extended_gates | 10 | 扩展检查，按 profile 启用 |
| final_gates | 6 | 发布前最终检查 |
| goalcli_mva_gates | 6 | MVA 生命周期 gate（alias，不生成第二套权威 gate） |

---

## 21. Upgrade Compatibility

### 21.1 变更分类

| 变更类型 | 版本升级 | 说明 |
|----------|----------|------|
| 新增规则（registry.yaml 新增条目） | minor | 向后兼容 |
| 新增 gate（harness.yaml 新增条目） | minor | 向后兼容 |
| 新增 goalcli 命令 | minor | 向后兼容 |
| 删除或重命名规则 | major | Breaking Change |
| 删除或重命名 gate | major | Breaking Change |
| 修改 gate 退出码语义 | major | Breaking Change |
| 修改 Evidence Ledger schema 字段 | major | Breaking Change |
| 修改 AdoptionStatus 枚举值 | major | Breaking Change |
| 修改 Release Manifest schema | major | Breaking Change |
| 新增 ErrorKind | minor | 向后兼容 |
| 新增 metrics | minor | 向后兼容 |

### 21.2 Breaking Change 流程

1. 在 SPEC.md 中标记为 DEPRECATED
2. 提供迁移指南
3. 保留至少一个 MINOR 版本周期
4. 下一个 MAJOR 版本中移除

### 21.3 下游同步

标准变更通过 FR-052 的 20 PR 执行链按依赖顺序同步到下游仓库。下游同步失败时阻断后续同步并记录失败原因。

---

## 22. Release DoD

### 22.1 发布验收清单

- [ ] 所有 P0 FR 实现完成（48/48）
- [ ] 所有 AC 验证通过（16/16）
- [ ] registry.yaml 419 条规则 schema 验证通过
- [ ] harness.yaml 66 个 gate 条目全部在 Makefile 中注册
- [ ] `make integration` 渲染 kernel/configx/redisx 三个下游库，编译通过，gate 全过
- [ ] `make debt` debt score >= 9.8
- [ ] Evidence Ledger 完整性检查通过
- [ ] Release Manifest schema 验证通过
- [ ] Release Scorecard >= 9.8
- [ ] 追溯矩阵更新完成（FR→AC 52/52）
- [ ] spec 状态更新为 Implemented

### 22.2 变更日志

| 日期 | 版本 | 变更内容 |
|------|------|----------|
| 2026-06-08 | v1.0.0 | 初始版本。基于 ANALYSIS.md v3.1.0（上游 commit `93753b30`，v0.6.5）编写完整 23 节 SPEC。 |

---

## 23. Open Questions

> 从 CONFLICT-LEDGER.md 和 SNAPSHOT-BOUNDARY.md 提取。

### Non-blocking（不阻塞开发）

> 原 Blocking OQ-001/OQ-002 已降级：两者均为设计决策而非实现前置条件，推荐默认方案已明确，可在 v1.0.0 迭代中收敛。

| ID | 问题 | 状态 | 来源 |
|----|------|------|------|
| OQ-001 | `.config/xlib` 迁移目标 vs 当前 `.agent/**`、`.xlib/**` 路径现实：v1.0.0 前如何收敛配置拓扑？ | 待解决（推荐：保留当前路径，v1.1.0 统一迁移） | SNAPSHOT-BOUNDARY.md B-01 |
| OQ-002 | 生成器复制策略：当前 `render_template.sh` 以模板渲染和排除项为主，strict 计划要求 allowlist materialization 和 pathguard，何时切换？ | 待解决（推荐：v1.0.0 保持模板渲染，v1.1.0 引入 strict 模式） | CONFLICT-LEDGER.md #5 |
| OQ-003 | 远端治理证明：本地 Markdown 不能证明 branch protection、ruleset、required checks 当前启用，需要建立远端证据采集流程 | 待解决 | SNAPSHOT-BOUNDARY.md B-04 |
| OQ-004 | v1.0.0 状态：Downloads 中 v1.0.0 checklist 是目标/计划，不是本地已发布事实，需要明确 v1.0.0 release-ready 判定标准 | 待解决 | SNAPSHOT-BOUNDARY.md B-05 |
| OQ-005 | ADR 数量：旧材料使用 10 个 ADR 的汇总数字，当前整理口径区分 9 个 Accepted ADR + template + 历史规划文档，需要确认最终口径 | 待解决 | CONFLICT-LEDGER.md #10 |
| OQ-006 | `cmd/goalcli` vs scripts：早期材料依赖 shell scripts，后续标准要求 `cmd/goalcli` 成为唯一机器入口，scripts 的兼容层边界需要明确 | 待解决 | CONFLICT-LEDGER.md #4 |
| OQ-007 | Secret 和测试 fixture：测试和生成器需要 fixture，但标准禁止生产 secret，fixture 的脱敏标准需要量化 | 待解决 | CONFLICT-LEDGER.md #9 |

### Future（未来考虑）

| ID | 问题 | 状态 | 来源 |
|----|------|------|------|
| OQ-008 | Docker Toolchain Runtime 是否需要独立的质量声明标准（当前只作为可复现执行环境）？ | 待评估 | CONFLICT-LEDGER.md #7 |
| OQ-009 | `CHECK_STATUS=passed` 语义边界：如何防止 evidence 生成上下文被误读为 release-ready？ | 待评估 | CONFLICT-LEDGER.md #8 |
| OQ-010 | 下游同步治理的 20 PR 执行链如何与 Goal Runtime 的 28 PR 执行链协调？ | 待评估 | FR-052 |
| OQ-011 | L2 Provider release ladder 的 T3 首个 release-allowed 阶段判定标准是否需要细化？ | 待评估 | analysis/governance.md 3.7 |
| OQ-012 | 154 文件整理口径 vs 181 文件旧分析口径的长期维护策略？ | 待评估 | SNAPSHOT-BOUNDARY.md B-06 |
| OQ-013 | 1000-pass 语义边界：`1000-pass` 只证明输入文件集合和清单稳定，不证明逐条语义审查完成，是否需要额外语义验证？ | 待评估 | SNAPSHOT-BOUNDARY.md B-08 |

---

## Appendix A: FR 追溯矩阵摘要

> 完整追溯矩阵见 [TRACEABILITY.md](./TRACEABILITY.md)。

| 维度 | 覆盖 | 总数 | 口径 |
|------|------|------|------|
| FR 来源锚定 | 52 | 52 | 行级 49、file 1、validator-output 2 |
| FR -> AC | 52 | 52 | 100% |
| FR -> TC | 10 | 52 | 19%（其余由 harness gate + Evidence pack 间接证明） |
| xlib-TC -> FR（反向） | 17 | 17 | 100% |
| AC 总数 | 16 | — | AC-T01..T04, AC-I01..I04, AC-G01..G03, AC-R01..R06 |
| TC 总数 | 17 | — | xlib-TC-001..xlib-TC-017 |

## Appendix B: TRUTH 同义引用表

> `TRUTH-NNN` 只在本表作为 BR / FR 的同义表述保留；跨文档引用应使用 `BR-NNN`、`FR-NNN` 或 `RULE-CORE-NNN`。

| TRUTH | 推荐引用 | 同义表述 |
|-------|----------|----------|
| TRUTH-001 | BR-005 | 规则不进入 Gate 就不是规则 / Harness 是机器裁判 |
| TRUTH-002 | BR-007 | 登记态不等于 adopted |
| TRUTH-003 | FR-042 | goalcli 是唯一执行面 |
| TRUTH-004 | BR-001 | Proof 是完成的唯一合法证明 |
| TRUTH-005 | FR-004 | 依赖方向只能从高层指向低层 |
| TRUTH-006 | FR-047 | 本地 + CI + GitHub Ruleset 三重硬约束 |
| TRUTH-007 | FR-044 | 4-Plane 分离关注点 |
| TRUTH-008 | BR-001 | 没有 Evidence 不允许 DONE |
| TRUTH-009 | BR-002 | Goal 必须从真实上下文开始 |
| TRUTH-010 | BR-003 | 需求必须可验证 |
| TRUTH-011 | BR-004 | 所有变更必须可追踪 |
| TRUTH-012 | BR-005 | Harness 是机器裁判 |
| TRUTH-013 | BR-006 | Self-improving 是强制环节 |
| TRUTH-014 | BR-001 | 文档不等于证据 |
| TRUTH-015 | BR-007 | registered / baseline_scanned / patch-only 不等于 adopted |

## Appendix C: 规则前缀体系

| 前缀 | 类别 | 主要覆盖 FR |
|------|------|-------------|
| RULE-CORE | 核心铁律（7 条） | FR-001, FR-007 |
| RULE-HARNESS | Harness 执行 | FR-020..FR-025 |
| RULE-EVIDENCE | Evidence 协议 | FR-026..FR-032 |
| RULE-DEP | 依赖规则 | FR-004, FR-015..FR-019 |
| RULE-IMPL | 实现规则 | FR-009..FR-014, FR-040..FR-046 |
| RULE-TEST | 测试规则 | FR-020, xlib-TC-001..017 |
| RULE-DOCS | 文档规则 | FR-008 |
| RULE-ARCH | 架构规则 | FR-004 |
| RULE-DOMAIN | 领域规则 | FR-005, FR-047..FR-052 |
| RULE-SEC | 安全规则 | FR-013, FR-014 |

---

## 追溯完整性报告

| 指标 | 状态 |
|------|------|
| FR 总数 | 52 |
| AC 总数 | 16 |
| TC 总数 | 17 |
| FR->AC 覆盖率 | 100%（52/52） |
| AC->TC 覆盖率 | 100%（16/16，部分由 harness gate 间接证明） |
| FR->TC 直接覆盖率 | 19%（10/52，其余由 gate + Evidence pack 间接覆盖） |
| 孤立 TC | 0（17 个 xlib-TC 全部映射回 FR） |
| BR 总数 | 15 |
| 边界场景 | 13（EC-G1..EC-G6 + EC-001..EC-010 中的 7 个模板边界） |
| Open Questions | 13（Non-blocking 7, Future 6） |
