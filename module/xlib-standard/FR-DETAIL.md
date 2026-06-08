# xlib-standard FR 详细规格

> 本文件包含全部 52 个 FR 的 WHEN/THEN 行为规格。
> ANALYSIS.md / analysis/*.md 保留 FR 摘要表，详细内容以本文件为准。

> 权威来源：本文件；按 4 类职责分组阅读：§1..§4：
>
> - §1 规则源与 Debt Governance：FR-001..FR-008、FR-033..FR-039
> - §2 Go 参考模板与 Generator：FR-009..FR-019
> - §3 Harness、Evidence 与 Goal Runtime：FR-020..FR-032、FR-040..FR-046
> - §4 仓库治理协议：FR-047..FR-052

Status: Aligned-With ANALYSIS.md v3.1.0
Last-Updated: 2026-06-08
- Snapshot-Date: 2026-06-08
- Upstream-Commit: `93753b30e6d01fb4a9b096acaa0d7d53a2fb231c` (v0.6.5)
- Analysis-Version: v3.1.0

---

## 1. 规则源与 Debt Governance

### FR-001: 定义 419 条 RULE-* 规则，机器化为 registry.yaml

WHEN registry.yaml 被 goalcli 加载
THEN 419 条规则全部有条目，schema 验证通过，无缺失无重复

WHEN 规则按前缀（RULE-CORE/RULE-HARNESS/RULE-EVIDENCE 等）分类查询
THEN 返回正确的类别和优先级（P0=119, P1=244, P2=56）

> 来源：goal-patch.md, ADR-20260603-002 | 优先级：P0

### FR-002: 定义 7 类技术债治理规则

WHEN `make debt` 执行
THEN ARCH/DEP/DOMAIN/DOCS/TEST/IMPL/SEC 7 类规则全部被检查，无遗漏类别

WHEN 某类技术债规则被触发
THEN 返回规则编号、严重度和修复建议

> 来源：debt.md | 优先级：P0

### FR-003: 定义 10 条 Git 治理规则并接入执行链

WHEN 代码提交到仓库
THEN Git 治理规则必须接入 FR-047 定义的 5 层执行链，不在本条款另行定义第二套执行顺序

WHEN Git 治理规则被违反
THEN 对应层的 gate 阻断操作并返回违规详情

> 来源：git.md | 优先级：P0

### FR-004: 定义模块依赖层级模型

WHEN 模块 A 导入模块 B
THEN 依赖方向必须符合**领域分层 + 门禁** 模型（详见 analysis/governance.md §3.6）：门禁 → 基座 L0 → 基座 L1 → 基座 L2 → 数据域 → 分析域/决策域 → 执行域 → 入口；横切层（observex/alertx）可被任意层依赖；反向导入被阻断

WHEN 私有业务模块（数据域 / 分析域 / 决策域 / 执行域 / 入口）出现在公开库的 import 中
THEN boundary gate 失败并报告违规路径

> 来源：L.md, ADR-20260604-001 | 优先级：P0

### FR-005: 定义 8 个仓库治理 REQ

WHEN 仓库初始化或模板生成
THEN 8 个 REQ（worktree/hooks/Makefile/CI/ruleset/evidence/audit/no-false-adopted）全部有对应文件或配置

WHEN 某个 REQ 缺失
THEN adoption-check gate 失败并报告缺失项

> 来源：main.md | 优先级：P0

### FR-006: 定义采纳状态机入口约束

WHEN 下游仓库执行采纳流程
THEN adoption_status 从 not_run 开始，并必须使用 FR-050 的 8 状态枚举和 FR-051 的禁止转换规则

WHEN 采纳流程尝试绕过 FR-050/FR-051
THEN 操作被拒绝并返回禁止原因

> 来源：main.md | 优先级：P0

### FR-007: 定义 15 条基本真理（同义表见 `analysis/governance.md`）

WHEN goalcli 执行任何 gate
THEN 基本真理同义表作为不可违反的前置条件被检查（推荐引用 BR / FR）

WHEN 基本真理被违反（如无证据宣称 DONE）
THEN 对应 gate 失败并引用具体 TRUTH 编号

> 来源：v3.0.md | 优先级：P0

### FR-008: 定义 9 个正式 ADR

WHEN 查询 docs/adr/ 目录
THEN 存在 9 个状态为 Accepted 的正式 ADR（ADR-20260602-001 到 ADR-20260604-001）

WHEN 新架构决策产生
THEN 必须创建新 ADR 并遵循 ADR-000-template.md 格式

> 来源：docs/adr/ | 优先级：P1

---

## 2. Go 参考模板与 Generator

### FR-009: 公共 API 模板

WHEN 模板渲染完成
THEN 生成的 Go 代码包含 Config, Validate, Sanitize, New, Close, HealthCheck, Error, Metrics, Version 全部公共 API

WHEN 生成的代码执行 `go vet`
THEN 无警告，所有导出符号有文档注释

> 来源：docs/api.md | 优先级：P0

### FR-010: 9 种 ErrorKind

WHEN 调用方使用 `IsKind(err, ErrorKind...)` 做分支判断
THEN 9 种 ErrorKind（config/validation/connection/unavailable/timeout/auth/conflict/rate_limit/internal）全部可识别

WHEN 错误被包装（WrapError）
THEN errors.Is/errors.As 能穿透包装层匹配原始 ErrorKind

> 来源：docs/errors.md | 优先级：P0

### FR-011: 9 个最小 metrics

WHEN 客户端创建、关闭、请求、重试、健康检查等操作发生
THEN 对应 counter/gauge/histogram 指标自动递增或记录

WHEN Prometheus scrape /metrics 端点
THEN 返回 9 个最小指标（client_created_total, client_closed_total, client_errors_total,
client_health_status, client_health_latency_ms, client_requests_total,
client_request_duration_seconds, client_retries_total, client_inflight）

> 来源：docs/observability.md | 优先级：P0

### FR-012: HealthCheck JSON schema

WHEN HealthCheck() 被调用
THEN 返回的 JSON 符合 contracts/health.schema.json，包含 name/status/message/checked_at/latency_ms/metadata 字段

WHEN status 为 unhealthy
THEN message 字段必须包含人类可读的故障原因

> 来源：docs/observability.md | 优先级：P0

### FR-013: 配置显式传入

WHEN 客户端通过 New() 创建
THEN 配置必须由调用方显式传入，不得隐式读取 `<secret-store-path>` 或环境变量

WHEN 配置中包含 secret/token/password 字段
THEN Sanitize() 必须将其屏蔽后才能输出到日志或 Evidence

> 来源：docs/config.md | 优先级：P0

### FR-014: 配置 Validate 和 Sanitize

WHEN 调用 Validate() 且配置字段缺失或无效
THEN 返回 ErrorKindValidation 错误，列出所有不合法字段

WHEN 调用 Sanitize()
THEN 返回新副本，secret/token/password/key 字段被替换为 `***`

> 来源：docs/config.md | 优先级：P0

---

## 2.1 Generator

### FR-015: render_template.sh 渲染

WHEN 执行 `scripts/render_template.sh --module <module-path> --name <module-name> --package <package> --out <path>`
THEN `--module` 驱动 `{{.ModulePath}}`（Go module path，如 `github.com/ZoneCNH/kernel`）、
`--name` 驱动 `{{.Module}}`（短模块名，用于类型名前缀，如 `Kernel`）、
`--package` 驱动 `{{.Package}}`（Go 包名，如 `kernel`）、`--out` 驱动输出目录；
模板中所有 `{{.Module}}` / `{{.Package}}` / `{{.ModulePath}}` 占位符必须全部替换为实际值，输出目录结构完整

WHEN 渲染目标目录已存在
THEN 不覆盖已有文件，返回警告

> 来源：docs/generation.md | 优先级：P0

### FR-016: 渲染范围全覆盖

WHEN 模板渲染完成
THEN 生成的产物覆盖 Go 代码、JSON contract、shell 脚本、Makefile、CI 配置、文档 6 类文件

WHEN 某类文件缺失
THEN 渲染脚本返回非零退出码并报告缺失类别

> 来源：docs/generation.md | 优先级：P0

### FR-017: Repository Governance Pack

WHEN 渲染时传入 `--enable-governance --layer <L0|L1|L2> --standard-version <ver>`
THEN 生成的仓库包含完整治理文件集（Makefile targets、CI workflows、hooks、CODEOWNERS）

WHEN governance pack 生成后执行 `make governance-check`
THEN 所有 governance gate 通过

> 来源：docs/generation.md | 优先级：P0

### FR-018: make integration

WHEN 执行 `make integration`
THEN 临时渲染 kernel/configx/redisx 三个下游库，编译通过，gate 全部通过

WHEN 任一下游库渲染或编译失败
THEN `make integration` 返回非零退出码并报告失败库名

> 来源：docs/generation.md | 优先级：P0

### FR-019: Docker Toolchain Runtime 模板继承

WHEN 渲染 Docker 相关模板
THEN .dockerignore、Dockerfile、docker-compose.yml 从标准模板继承，排除 `.git`/`<runtime-dirs>`/`.worktree`

WHEN Docker 构建执行
THEN 工具链版本与 docs/workflow/manifest 一致，无版本漂移

> 来源：docs/generation.md | 优先级：P1

---

## 3. Harness、Evidence 与 Goal Runtime

### FR-020: 66 个 gate 条目

WHEN harness.yaml 被 goalcli 加载
THEN 66 个 gate 条目全部按 harness.yaml section 定义：44 required_gates、10 extended_gates、6 final_gates、6 goalcli_mva_gates；大写 MVA 条目作为 alias，不生成第二套权威 gate

WHEN 某个 gate 的 command 未在 Makefile 中注册
THEN harness validation 失败并报告未注册 gate

> 来源：harness.yaml | 优先级：P0

### FR-021: 4 个 Context Profiles

WHEN goalcli 以 `--profile context-lite` 执行
THEN 只运行 governance-check

WHEN goalcli 以 `--profile context-release` 执行
THEN 运行 context-full + integration + dependency-check + standard-impact-check + score-check + evidence + release-evidence

> 来源：main.md | 优先级：P0

### FR-022: P0 Gate 失败阻断发布

WHEN 任一 P0 gate 返回 failed
THEN 发布流程被阻断，不得创建 git tag

WHEN 所有 P0 gate 返回 passed
THEN 允许进入发布预检阶段

> 来源：goal-patch.md RULE-HARNESS-003 | 优先级：P0

### FR-023: Gate 结果归档为 Evidence

WHEN 任何 gate 执行完成
THEN 结果写入 `.agent/evidence/ledger.jsonl`，包含 gate_id/status/timestamp/evidence_path

WHEN Evidence 写入失败
THEN gate 视为 failed，不得报告 passed

> 来源：goal-patch.md RULE-HARNESS-004 | 优先级：P0

### FR-024: Release Scorecard

WHEN `goalcli score` 执行
THEN 返回 0~10.0 分，包含 gate runtime/CI/文档契约一致性维度

WHEN score < 9.8 且 `--min 9.8` 参数传入
THEN 命令返回非零退出码，阻断发布

> 来源：docs/scorecard.md | 优先级：P0

### FR-025: Debt Governance Gate

WHEN `make debt` 执行
THEN 7 类技术债规则全部检查，返回 debt score

WHEN debt score < 9.8
THEN gate 失败，P0 debt > 0 时阻断发布

> 来源：docs/standard/debt-governance.md | 优先级：P0

---

## 3.1 Evidence Runtime

### FR-026: Evidence Ledger

WHEN gate 执行完成
THEN 结果 append 到 `.agent/evidence/ledger.jsonl`，格式为 JSONL，每行包含 schema_version/goal_id/gate_id/status/timestamp/evidence_path

WHEN ledger.jsonl 被篡改或删除
THEN evidence_replay gate 失败，checksum 不匹配

> 来源：ADR-20260603-001 | 优先级：P0

### FR-027: Release Manifest

WHEN `make evidence` 执行
THEN 生成 `release/manifest/latest.json`，包含 module/version/commit/tree_sha/source_digest/
go_version/generated_at/checks/contracts/dependencies/tools/standard_impact/
downstream_sync_required/score/workflow/artifacts 等 20+ 字段

WHEN manifest schema 验证失败
THEN evidence gate 失败并报告缺失字段

> 来源：docs/release.md | 优先级：P0

### FR-028: DONE with evidence 格式

WHEN 贡献者声明任务完成
THEN 必须使用 `DONE with evidence:` 格式，后跟具体证据路径或命令输出

WHEN 使用其他格式（如 "tests pass"、"已完成"）
THEN 不被接受为合法完成声明

> 来源：goal-patch.md RULE-EVIDENCE-001 | 优先级：P0

### FR-029: 禁止无证据的 tests pass

WHEN 声称 "tests pass"
THEN 必须附带 `go test ./...` 的完整输出（包含 PASS/FAIL 行和覆盖率）

WHEN 无命令输出支撑
THEN evidence protocol 违规，gate 失败

> 来源：docs/standard/evidence-protocol.md | 优先级：P0

### FR-030: 禁止 skipped gate 记为 passed

WHEN 某个 required gate 被跳过（skip）
THEN Evidence 中必须记录为 skipped，不得记录为 passed

WHEN skipped gate 被记录为 passed
THEN evidence integrity check 失败

> 来源：docs/standard/evidence-protocol.md | 优先级：P0

### FR-031: 禁止 dirty workspace release

WHEN `git status` 显示未提交变更
THEN release-final-check 失败，不得宣称 release-final ready

WHEN workspace 干净且所有 gate passed
THEN 允许进入 release-final 阶段

> 来源：docs/standard/evidence-protocol.md | 优先级：P0

### FR-032: 禁止删除失败 Evidence

WHEN gate 执行失败
THEN 失败记录必须保留在 ledger.jsonl 中，不得删除或覆盖

WHEN 尝试删除失败 Evidence
THEN evidence append-only 策略阻止操作

> 来源：docs/standard/evidence-protocol.md | 优先级：P0

---

## 1.1 Debt Governance Runtime

### FR-033: ARCH 类技术债规则

WHEN `make debt` 执行 ARCH 检查
THEN NO_XGO_IMPORT, NO_L2_TO_L2_IMPORT, NO_IMPORT_CYCLE, FORBIDDEN_PACKAGE_NAME, NO_GOD_PACKAGE 5 条规则全部被验证

WHEN 任一 ARCH 规则被违反
THEN 返回违规文件路径、行号和规则编号

> 来源：debt.md | 优先级：P0

### FR-034: DEP 类技术债规则

WHEN `make debt` 执行 DEP 检查
THEN GOVULNCHECK, REACHABLE_CVE, UNPINNED_GITHUB_ACTION, CURL_BASH, LICENSE 等 10 条规则全部被验证

WHEN 发现未固定的 GitHub Action 或可达 CVE
THEN 返回依赖名称、版本和修复建议

> 来源：debt.md | 优先级：P0

### FR-035: DOMAIN 类技术债规则

WHEN `make debt` 执行 DOMAIN 检查
THEN FORBIDDEN_BUSINESS_TERM, BOUNDED_CONTEXT_VIOLATION 2 条规则被验证

WHEN 公开库中出现业务术语（如 ticker/order/position）
THEN 报告违规术语和所在文件

> 来源：debt.md | 优先级：P0

### FR-036: DOCS 类技术债规则

WHEN `make debt` 执行 DOCS 检查
THEN MISSING_REQUIRED_ADR, MAKE_TARGET_DRIFT, MANIFEST_SCHEMA_DRIFT 等 5 条规则全部被验证

WHEN Makefile target 与文档不一致
THEN 报告漂移的 target 名称和期望值

> 来源：debt.md | 优先级：P0

### FR-037: TEST 类技术债规则

WHEN `make debt` 执行 TEST 检查
THEN MISSING_CRITICAL_BEHAVIOR, FRAGILE_TEST, REAL_NETWORK_IN_UNIT 等 6 条规则全部被验证

WHEN 单元测试中发现真实网络调用
THEN 报告测试文件和违规调用

> 来源：debt.md | 优先级：P0

### FR-038: IMPL 类技术债规则

WHEN `make debt` 执行 IMPL 检查
THEN PANIC_RUNTIME 等规则被验证

WHEN 生产代码中发现 panic() 调用
THEN 报告文件路径和行号

> 来源：debt.md | 优先级：P0

### FR-039: SEC 类技术债规则

WHEN `make debt` 执行 SEC 检查
THEN 安全合规规则（日志脱敏、密钥管理、依赖漏洞）全部被验证

WHEN 发现安全违规（如明文密钥、未脱敏日志）
THEN 报告违规类型、严重度和修复建议

> 来源：debt.md | 优先级：P0

---

## 3.2 Goal Runtime v3.1.1

### FR-040: Goal Kernel（8 个核心对象）

WHEN goalcli 创建 Goal
THEN 对象模型包含 Goal/Spec/Design/Plan/Task/Test/Evidence/Review 8 个核心对象，每个对象有唯一 ID 和状态字段

WHEN 对象间引用不合法（如 Task 引用不存在的 Plan）
THEN 返回引用错误

> 来源：goalcli-v0.1.0-plan.md | 优先级：P0

### FR-041: Harness Runtime

WHEN goalcli 启动
THEN Mode Router 加载 harness.yaml，Gate Registry 注册所有 gate，Command Registry 注册所有命令，Blocking Policy 决定阻断规则

WHEN harness.yaml schema 版本不匹配
THEN 启动失败并报告版本不兼容

> 来源：.worktree/goal/ | 优先级：P0

### FR-042: goalcli 唯一执行面

WHEN 需要执行 gate/验证/发布操作
THEN 只能通过 cmd/goalcli 执行，拒绝第二套并列执行面

WHEN 发现绕过 goalcli 的直接 gate 调用
THEN governance-check 失败并报告违规

> 来源：ADR-20260603-001 | 优先级：P0

### FR-043: 6 个 MVA Gate

WHEN Goal 生命周期推进
THEN 6 个 MVA Gate（goalcli_g12_acceptance/g13_delivery/g14_handover/g15a_downstream_adoption/g15b_certify/g16_runtime_final）按序执行

WHEN 任一 MVA Gate 失败
THEN 后续 Gate 不得执行，Goal 状态回退

> 来源：goalcli-v0.1.0-plan.md | 优先级：P0

### FR-044: 4-Plane 架构

WHEN Goal 执行
THEN 数据流经 Spec Plane → Execution Plane → Proof Plane → Automation Plane 四层

WHEN Plane 间数据不一致（如 Spec 变更未传播到 Execution）
THEN proof_replay gate 检测到漂移并报告

> 来源：v3.0.md | 优先级：P0

### FR-045: 10 个 REQ-PROOF

WHEN Proof Runtime 执行
THEN 10 个 REQ-PROOF（Facts SSOT, GateReport, Evidence Replay, Downstream Proof Schema 等）逐项验证

WHEN 某个 REQ-PROOF 未实现
THEN 对应 proof_depth 降级，evidence 标记为 partial

> 来源：v3.0.md | 优先级：P0

### FR-046: 28 个 PR 执行包

WHEN 查询 Goal Runtime 执行计划
THEN 28 个 PR 分 5 个 Phase（MVA Core→可信治理→生态与协作→成熟化→自动化）有序排列

WHEN Phase N 的 PR 未完成
THEN Phase N+1 的 PR 不得开始

> 来源：.worktree/goal/ | 优先级：P1
>
> **两套 PR 体系说明**：
>
> - **28 PR（Goal Runtime）**：xlib-standard 自身的 Goal Runtime v3.1.1 执行包，
>   Phase 1 MVA Core（PR-1~8）→ Phase 2 可信治理（PR-9~13,18~20）→
>   Phase 3 生态与协作（PR-14~17,23）→ Phase 4 成熟化（PR-21~22,24~27）→
>   Phase 5 自动化（PR-28）。当前状态：设计封顶，进入执行阶段，无 PR 完成。
> - **20 PR（Downstream Sync）**：xlib-standard 标准变更向下游传播的同步执行链，见 goal.md。
> - 两套 PR 互相独立：Goal Runtime PR 是 xlib-standard 自身建设，Downstream Sync PR 是标准向下游扩散。

---

## 4. 仓库治理协议

### FR-047: 5 层执行链

本条是 FR-003 引用的 5 层执行链权威定义。

WHEN 代码变更提交
THEN 按 FR-003 的标准源 → 生成器 → 本地 hooks → CI gate → GitHub ruleset 顺序逐层生效

WHEN 某层被绕过（如直接 push 跳过 hooks）
THEN 后续层（CI/ruleset）阻断操作

> 来源：main.md, git.md | 优先级：P0

### FR-048: 禁止 main 开发

WHEN 尝试直接 commit 到 main/master 分支
THEN pre-commit hook + pre-push hook + goalcli main-guard 三重阻断

WHEN 在 worktree 分支提交
THEN 允许正常提交流程

> 来源：main.md | 优先级：P0

### FR-049: 必须使用 git worktree

WHEN 执行开发任务
THEN 必须在 git worktree 中工作，goalcli worktree-guard 验证当前目录是 worktree

WHEN 在主工作目录开发
THEN worktree-guard 失败并提示创建 worktree

> 来源：main.md | 优先级：P0

### FR-050: 采纳状态机（8 状态）

本条是 FR-006 引用的 adoption_status 枚举权威定义。

WHEN 查询下游仓库采纳状态
THEN adoption_status 为 FR-006 状态机中的 8 个合法值之一：not_run/registered/dry_run/patch_only/proof_verified/adopted/blocked/superseded

WHEN adoption_status 不在合法枚举中
THEN registry validation 失败

> 来源：main.md | 优先级：P0

### FR-051: 6 个禁止状态转换

本条是 FR-006 引用的禁止转换权威定义。

WHEN 尝试执行 registered→adopted、dry_run→adopted、patch_only→adopted、not_run→adopted、gate_outputs_missing→proof_based_adoption、baseline_scanned→adopted
THEN 操作被拒绝，返回 FR-006 状态机的禁止原因和正确路径

WHEN 按合法路径转换（如 registered→dry_run→proof_verified→adopted）
THEN 允许转换并记录 Evidence

> 来源：main.md | 优先级：P0

### FR-052: 下游同步治理（20 PR）

WHEN xlib-standard 标准变更
THEN 20 PR 执行链启动，按依赖顺序同步到下游仓库

WHEN 下游仓库同步失败
THEN 阻断后续下游同步，记录失败原因到 downstream-sync plan

> 来源：goal.md | 优先级：P1
