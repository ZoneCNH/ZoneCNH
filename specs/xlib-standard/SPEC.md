# xlib-standard SPEC

> FoundationX 基础库标准工厂。标准源 + Go 参考模板 + Generator + Harness + Evidence Runtime + Debt Governance Runtime。

- Status: Review
- Spec-Version: v2.0.1
- Last-Updated: 2026-06-08
- Owner: ZoneCNH
- Layer: 基座（Foundation Gate 治理子层；详见 §15.1）
- Version: v0.6.x（目标 v1.0.0-rc.1）

> **Status: Review**（待独立 reviewer 签字后升级 Approved）
>
> Approved 前置条件：
> - [x] 远端治理证据（OQ-001 已由 REMOTE-EVIDENCE.md 闭合）
> - [x] FR 行级覆盖 100%（51/52 行级 + 1/52 子目录级）
> - [ ] 独立 reviewer 签字
>
> 详细变更记录：见 git log

- Repository: [github.com/ZoneCNH/xlib-standard](https://github.com/ZoneCNH/xlib-standard)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md),
  [SPEC-TEMPLATE.md](../SPEC-TEMPLATE.md), [xlibgate/SPEC.md](../xlibgate/SPEC.md),
  [kernel/SPEC.md](../kernel/SPEC.md), [configx/SPEC.md](../configx/SPEC.md)

---

## 1. 元信息（Metadata）

| 字段 | 值 |
|------|-----|
| 模块名 | xlib-standard |
| 仓库 | `github.com/ZoneCNH/xlib-standard` |
| 层级 | 基座（Foundation Gate 治理子层；属于 ARCHITECTURE.md 五领域之"基座"内的标准/门禁子层，不新建第六领域。详见 §15.1） |
| 角色 | Standard Source + Go Reference Template + Generator + Harness + Evidence Runtime + Debt Governance Runtime |
| 默认下游 | kernel(L0), configx(L1), observex(L1), testkitx(L1), redisx(L2) |
| Go 版本 | 1.23.x（遵循 `.tool-versions`，`GOWORK=off` 必须） |
| 当前基线版本 | v0.6.x（v1.0.0-rc.1 前） |
| Goal ID | GOAL-20260602-001 |
| 目标版本 | v1.0.0 stable |

---

## 2. 概述（Summary）

xlib-standard 是 FoundationX 量化交易基础设施的**基础库标准工厂**，同时承担六类职责：

1. **Standard Source**：定义所有基础库必须遵守的标准、规则和契约（419 条 RULE-*，203 条 docs/standard/ 规则）
2. **Go Reference Template**：提供可编译的 Go 参考模板，通过 `scripts/render_template.sh` 生成下游基础库
3. **Generator**：模板渲染器，将 Go text/template 占位符 `{{.Module}}` / `{{.Package}}` / `{{.ModulePath}}` 替换为具体库的标识（详见 §9.1.1 / FR-015）
4. **Harness**：Gate 执行控制面，定义 66 个 gate 条目（44 required_gates + 10 extended_gates + 6 final_gates + 6 goalcli_mva_gates）和 4 个 Context Profiles；大写 MVA 条目按 alias 处理，不生成第二套权威 gate
5. **Evidence Runtime**：管理 Evidence Ledger（`.agent/evidence/ledger.jsonl`），证明所有声明的真实性
6. **Debt Governance Runtime**：7 类技术债治理（ARCH/DEP/DOMAIN/DOCS/TEST/IMPL/SEC），40+ 条规则

xlib-standard 本身不包含业务逻辑，不依赖 x.go，不读取生产密钥。它是所有基础库的"工程基因库"。

### 2.0 使用边界（Scope Boundary）

- xlib-standard 是基础库标准工厂，不是业务库，不是 L1/L2 provider runtime。
- 所有基础库必须使用 xlib-standard 的标准、模板和门禁。
- 下游库（kernel、configx、redisx 等）消费 xlib-standard 的产物，不反向依赖。
- x.go 是私有业务 consumer，不作为标准门禁的前置条件。

### 2.1 权威来源与事实层级

规格按事实强度分层：

| 层级 | 来源 | 用法 |
|------|------|------|
| Current Standard | `docs/standard/**`、根级 `docs/*.md` | 当前可执行规范和门禁事实。 |
| Domain Supplement | `docs/testing/**`、`docs/l2/**`、`docs/evidence/**` | 下游、L2、测试和证据补充。 |
| Historical Plan | `.worktree/*.md`、`docs/v0.6.0/**`、Downloads | 迁移目标、历史审查、未落地设计和冲突证据。 |
| Runtime Proof | release/evidence、ledger、CI artifact、remote ruleset proof | 只有真实产物可证明执行状态或远端状态。 |

禁止把弱事实升级为强事实：

- `registered` ≠ `adopted`
- `baseline_scanned` ≠ `implemented`
- `dry_run_ready` ≠ `executed`
- `artifact_exists` ≠ `usable`
- `CHECK_STATUS=passed` ≠ release-ready evidence
- downstream sync plan ≠ downstream adoption proof

### 2.2 当前事实边界

本规格只能证明本地输入文件已被整理成规格包；不能单独证明远端、发布或下游仓库的当前状态。

| 事项 | 本规格当前结论 | 升级为 passed/adopted/release-ready 所需证明 |
|------|--------------|------------------------------------------|
| 输入覆盖 | 154 个输入文件被纳入当前整理口径。 | 新增或删除源文件后同步更新覆盖清单和追溯表。 |
| 语义整理 | 7 组并行分析 + 主线程证据收敛。 | 具体条款仍以来源追溯、冲突账本和后续实现验证为准。 |
| Release-ready | 仅定义 release-ready 条件和 fail-closed 规则。 | release-final、preflight、manifest、score、evidence check、clean workspace 和 GitHub Release proof。 |
| 远端治理 | 仅定义 branch protection、ruleset、required checks 和 workflow 权限要求。 | GitHub API、ruleset export、required checks、CI artifact 或仓库设置证据。 |
| 下游采用 | 仅定义 adoption proof 条件。 | 下游仓库 commit、gate output、proof schema、rollback plan 和下游 CI 证据。 |

---

## 3. 问题（Problem）

### 3.1 痛点

1. **身份漂移**：旧名 `baselib-template` 和 `foundationx` 导致 README、docs、.agent 出现身份混乱
2. **规则散文化**：419 条规则存在于 13856 行散文（goal-patch.md）中，不可机器读、不可自动验证
3. **伪完成风险**：登记态（registered）、dry-run、patch-only 被误判为 adopted，导致虚假完成声明
4. **配置分散**：`.agent/`、`.xlib/`、`.config/` 三套配置路径并存，下游无法确定权威来源
5. **Gate 缺失**：本地 hooks 不是服务器强制机制，GitHub 服务端 branch protection/ruleset 未配置

### 3.2 量化现状

- 规则总数：419 条（P0=119, P1=244, P2=56）
- 规则机器化率：87%（363/419 active）
- 治理能力评分：8.5/10（缺 GitHub 服务端保护）
- 下游采纳状态：全部 `not_adopted`，evidence_state 为 `not_run`
- L2 适配器：全部停留在 L2-T0/T1

---

## 4. 目标（Goals）

### 4.1 P0 目标（必须达成）

- **G-P0-1 唯一主身份**：xlib-standard 是唯一主身份，承担 6 类职责（ADR-20260602-001）
- **G-P0-2 规则机器化**：419 条规则全部机器化为 registry.yaml，P0=100% 有 enforcer（ADR-20260603-002/004/005）
- **G-P0-3 证据驱动完成**：没有 Evidence 不允许 DONE，完成声明必须使用 `DONE with evidence:` 格式
- **G-P0-4 Proof-based adoption**：登记态 ≠ adopted，只有 downstream repo 自身生成的 proof-based adoption 才能进入 registry
- **G-P0-5 配置统一**：v1.0.0 前将配置拓扑收敛到 `.config/`（18 个命名空间）
- **G-P0-6 三层硬约束**：本地 hooks + CI gate + GitHub Ruleset 三重强制

### 4.2 P1 目标（应当达成）

- **G-P1-7 Goal Runtime v3.1.1**：28 个 PR 执行包全部落地，Goal Kernel + Harness Runtime + Extensions 架构
- **G-P1-8 L2 测试工厂**：15 个 L2 适配器全部达到 L2-T2 级别
- **G-P1-9 Debt Governance**：7 类技术债治理规则全部纳入 Gate
- **G-P1-10 自动化**：Issue → Goal → Task → Branch → Commit → PR → Version → Release → Issue Close 全链路

---

## 5. Non-goals（不做什么）

- 不包含业务逻辑实现
- 不替代下游仓库自身治理
- 不依赖 x.go
- 不读取 ``<secret-store-path>``
- 不公开 L3-L6 业务系统
- 不自动修复技术债
- 不引入 BDD 工具链
- 不默认强制 Chaos/Mutation Test

---

## 6. 消费者（Consumers）

| 消费者 | 领域 / 层级 | 消费方式 | 采纳状态 |
|--------|-------------|----------|----------|
| kernel | 基座 / L0 | 生成模板 + 标准继承 | not_adopted |
| configx | 基座 / L1 | 生成模板 + 标准继承 | not_adopted |
| observex | 基座 / L1（横切） | 生成模板 + 标准继承 | not_adopted |
| testkitx | 基座 / L1 | 生成模板 + 标准继承 | not_adopted |
| resiliencx | 基座 / L1 | 生成模板 + 标准继承 | not_adopted |
| schedulex | 基座 / L1 | 生成模板 + 标准继承 | not_adopted |
| redisx | 基座 / L2 | 生成模板 + L2 适配规范 | not_adopted |
| kafkax | 基座 / L2 | 生成模板 + L2 适配规范 | not_adopted |
| natsx | 基座 / L2 | 生成模板 + L2 适配规范 | not_adopted |
| postgresx | 基座 / L2 | 生成模板 + L2 适配规范 | not_adopted |
| taosx | 基座 / L2 | 生成模板 + L2 适配规范 | not_adopted |
| ossx | 基座 / L2 | 生成模板 + L2 适配规范 | not_adopted |
| clickhousex | 基座 / L2 | 生成模板 + L2 适配规范 | not_adopted |

> 注：L0/L1/L2 是**基座领域内部**的依赖层级编号（详见 §15.1、ARCHITECTURE.md），不与"基座/数据域/分析域/决策域/执行域/入口"领域命名冲突。L2 适配器共 7 个。
>
> docs/l2/ 目录下有 15 个执行计划文件，覆盖上述 7 个 L2 适配器 + xlib-standard 自身 + testkitx + xlibgate + xgo-market-data + xgo-macro-data + engines + xgo runtime system gate。

| 消费者 | 领域 / 层级 | 消费方式 | 采纳状态 |
|--------|------|----------|----------|
| xgo-market-data | 数据域（私有） | 标准继承 | consumer-only |
| xgo-macro-data | 数据域（私有） | 标准继承 | consumer-only |
| x.go | 入口（私有） | 标准继承（consumer-only） | consumer-only |

---

## 7. 功能需求（Functional Requirements）

### 7.1 标准源（Standard Source）

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
THEN 依赖方向必须符合**领域分层 + 门禁** 模型（详见 §15.1）：门禁 → 基座 L0 → 基座 L1 → 基座 L2 → 数据域 → 分析域/决策域 → 执行域 → 入口；横切层（observex/alertx）可被任意层依赖；反向导入被阻断

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

### FR-007: 定义 15 条基本真理（TRUTH-001~015）

WHEN goalcli 执行任何 gate
THEN TRUTH-001~015 作为不可违反的前置条件被检查

WHEN 基本真理被违反（如无证据宣称 DONE）
THEN 对应 gate 失败并引用具体 TRUTH 编号

> 来源：v3.0.md | 优先级：P0

### FR-008: 定义 9 个正式 ADR

WHEN 查询 docs/adr/ 目录
THEN 存在 9 个状态为 Accepted 的正式 ADR（ADR-20260602-001 到 ADR-20260604-001）

WHEN 新架构决策产生
THEN 必须创建新 ADR 并遵循 ADR-000-template.md 格式

> 来源：docs/adr/ | 优先级：P1

### 7.2 Go 参考模板（Go Reference Template）

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

### 7.3 Generator

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

### 7.4 Harness

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

### 7.5 Evidence Runtime

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

### 7.6 Debt Governance Runtime

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

### 7.7 Goal Runtime v3.1.1

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

### 7.8 仓库治理协议

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

---

## 8. 业务规则（Business Rules）

### 8.1 核心铁律（Iron Rules，7 条；亦记为 BR-001..BR-007）

> **编号别名（消解结构债 S4 / S11）**：`BR-NNN` 为对外引用的业务规则编号，`IR-NNN` 为内部分类编号，`TRUTH-NNN` 为治理真理编号，`RULE-CORE-NNN` 为 enforcer 源码编号。四者在本表一一对应；对外文档 / 追溯矩阵 / Task Spec 一律使用 `BR-NNN`，enforcer 与 registry.yaml 一律使用 `RULE-CORE-NNN`。

| BR | IR | TRUTH | 规则 | 来源 |
|----|----|-------|------|------|
| BR-001 | IR-001 | TRUTH-001 | 没有证据，不允许 DONE | RULE-CORE-001 |
| BR-002 | IR-002 | TRUTH-002 | Goal 必须从真实上下文开始 | RULE-CORE-002 |
| BR-003 | IR-003 | TRUTH-003 | 需求必须可验证 | RULE-CORE-003 |
| BR-004 | IR-004 | TRUTH-004 | 所有变更必须可追踪 | RULE-CORE-004 |
| BR-005 | IR-005 | TRUTH-005 | Harness 是机器裁判 | RULE-CORE-005 |
| BR-006 | IR-006 | TRUTH-006 | Self-improving 是强制环节 | RULE-CORE-006 |
| BR-007 | IR-007 | TRUTH-007 | 登记态 ≠ adopted | main.md, goal.md |

> §22.4 / TRACEABILITY 中过去并列出现 `IR-001 / TRUTH-001` 两套编号的位置，对外一律改写为 `BR-001`，内部规则源码与 enforcer 保留 `RULE-CORE-001`，不再并列两套独立体系。

### 8.2 规则前缀体系（RULE Taxonomy）

419 条规则按前缀分类：

| 前缀 | 类别 | 示例 |
|------|------|------|
| RULE-CORE | 核心铁律 | RULE-CORE-001（没有证据不允许 DONE） |
| RULE-HARNESS | Harness 执行 | RULE-HARNESS-003（P0 Gate 失败阻断发布） |
| RULE-EVIDENCE | Evidence 协议 | RULE-EVIDENCE-001（DONE with evidence 格式） |
| RULE-SEC | 安全规则 | XS-CORE-008（日志脱敏） |
| RULE-DEP | 依赖规则 | RULE-DEP-001（依赖方向） |
| RULE-IMPL | 实现规则 | RULE-IMPL-001（模块边界） |
| RULE-TEST | 测试规则 | RULE-TEST-001（覆盖率） |
| RULE-DOCS | 文档规则 | RULE-DOCS-001（ADR 必需） |
| RULE-ARCH | 架构规则 | RULE-ARCH-001（层级治理） |
| RULE-DOMAIN | 领域规则 | RULE-DOMAIN-001（禁止业务术语） |

### 8.3 RULE 前缀 ↔ FR 映射（消解结构债 S7）

> 419 条 RULE-* 按前缀汇总到 FR 覆盖区段。本表为**块级**映射，行级 RULE→FR→TC 映射由 `registry.yaml` + `goalcli trace-coverage` 维护，行级缺口由 NG-33 阻断（详见 §22.4 / TRACEABILITY.md §"块级追溯缺口声明"）。

| RULE 前缀 | 主要覆盖 FR | 覆盖说明 |
|-----------|-------------|----------|
| RULE-CORE | FR-001 / FR-007（BR-001..BR-007 / TRUTH-001..015） | 7 条铁律 / 15 条真理 |
| RULE-HARNESS | FR-020..FR-025 | 66 个 gate 条目、Profile、Scorecard、Debt Gate |
| RULE-EVIDENCE | FR-026..FR-032 | Evidence Ledger、Manifest、DONE 格式、4 项禁止 |
| RULE-DEP | FR-004 / FR-015..FR-019 | 依赖方向、模板渲染依赖、Docker 工具链 |
| RULE-IMPL | FR-009..FR-014 / FR-040..FR-046 | Go 参考模板、Goal Runtime |
| RULE-TEST | FR-020 / §16（TC-001..017） | 测试分层、覆盖率、race gate |
| RULE-DOCS | FR-008 / §C 文档清单 | ADR、文档入口 |
| RULE-ARCH | FR-004 / §15 | 层级治理 |
| RULE-DOMAIN | FR-005 / FR-047..FR-052 | 仓库治理、采纳状态机、下游同步 |
| RULE-SEC | §19 / FR-013 / FR-014 | 配置脱敏、secret policy、日志脱敏 |

### 8.4 规则权威顺序

```text
iron-rules.md > registry.yaml > *-rules.md > ADR-* > .worktree/goal-patch.md
```text

### 8.5 完成定义（DoD）

| 级别 | 要求 | 来源 |
|------|------|------|
| Task DoD | 变更范围明确 + 测试/检查已运行 + 文档有入口 + known gap 已记录 | docs/standard/dod.md |
| Issue DoD | 验收标准满足 + 相关 gate 通过 + review checklist 完成 + 无违规 | docs/standard/dod.md |
| Goal DoD | 所有必需项有实现或不适用理由 + ci/integration/evidence 有新鲜结果 | docs/standard/dod.md |
| Release DoD | manifest 生成 + release-check 通过 + score >= 9.8 + final-check + preflight 通过 | docs/standard/dod.md |

### 8.6 采纳状态机禁止转换（6 个）

从 `main.md` 和 `goal.md` 提取的 6 个禁止状态转换：

| # | 禁止转换 | 原因 |
|---|----------|------|
| 1 | registered → adopted | 登记态不等于已采纳，必须经过 proof-based adoption |
| 2 | dry_run → adopted | dry-run 只验证流程，不证明落地 |
| 3 | patch_only → adopted | patch-only 不等于 proof-based adoption |
| 4 | not_run → adopted | 未运行禁止直接 adopted |
| 5 | gate_outputs_missing → proof_based_adoption | 缺少 gate 输出不能声称 proof-based（条件状态：evidence_state=partial 时的中间态） |
| 6 | baseline_scanned → adopted | 基线扫描不等于采纳完成（条件状态：adoption_status=registered 时的扫描态） |

核心铁律：`registered != adopted`、`patch_only != proof_based_adoption`、`gate_outputs_missing != proof_based_adoption`。

### 8.7 关键约束

1. **依赖方向**：L3 → L2 → L1 → L0 → stdlib，不可反向（L.md, ADR-20260604-001）
2. **L3 私有边界**：L3 业务系统不公开、不开源，公开库不得包含业务语义（ADR-20260604-001）
3. **配置显式传入**：不得隐式读取 ``<secret-store-path>``（docs/config.md）
4. **日志脱敏**：不得输出 secret/token/password/private key/连接凭据（docs/standard/xlib-standard.md XS-CORE-008）
5. **单一执行面**：cmd/goalcli 是唯一机器执行面，拒绝第二套并列执行面（ADR-20260603-001）
6. **证据不可删**：禁止删除失败 Evidence（docs/standard/evidence-protocol.md EP-012）

---

## 9. 接口契约（Interface Contract）

### 9.1 公共 API

| API | 说明 | 契约 |
|-----|------|------|
| `Config` | 配置结构体 | 必须支持 Validate 和 Sanitize |
| `Validate` | 验证配置 | 拒绝无效配置，返回 ErrorKindValidation |
| `Sanitize` | 脱敏配置 | 屏蔽 token/secret/password/key |
| `New` | 创建客户端 | 拒绝 nil/canceled/expired context |
| `Close` | 关闭客户端 | 必须幂等 |
| `HealthCheck` | 健康检查 | 返回 healthy/degraded/unhealthy |
| `Error` / `NewError` / `WrapError` | 错误构造 | 支持 errors.Is/errors.As |
| `Metrics` | 指标注册 | 9 个最小指标 |
| `Version` | 版本信息 | 返回模块版本 |

#### 9.1.1 Go 参考签名（Template Reference）

> **格式说明**：下方 fenced block 是 **text/template 源**（使用 Go template 占位符 `{{.Module}}` / `{{.Package}}`），不是可直接 `go vet` 的 Go 源文件。模板渲染产物（替换占位符后的 `.go` 文件）才是 §7 FR-009 / FR-015 中 `go vet ./...` 的目标。

```gotemplate
package {{.Package}}

import (
    "context"
    "time"
)

// Config 是模块对外配置结构体，所有字段必须可序列化且无生产 secret 默认值。
// 必须由调用方显式构造，禁止隐式读取生产路径（详见 §7 FR-013、§19）。
type Config struct {
    // 由各模块自行定义具体字段；本规格只约束方法集。
}

// Validate 校验配置；无效时必须返回 ErrorKindValidation 包装的 error
// （详见 §12.1 / FR-014）。
func (c *Config) Validate() error

// Sanitize 返回脱敏后的 Config 深拷贝（值类型），可安全写入日志、Evidence、Manifest。
// 必须屏蔽 token / secret / password / private_key / 连接凭据（XS-CORE-008）。
// 实现必须深拷贝所有引用类型字段（map/slice/pointer），不得共享底层数组。
func (c *Config) Sanitize() Config

// {{.Module}}Client 是公共客户端接口；本规格只约束最小方法集（Close + HealthCheck）。
// 其余 §9.1 表中声明的 API（Metrics / Version / Error 系列）按下方"独立函数 / 包级 API"
// 提供；模块特有方法由各下游 SPEC §9 自行扩展。
type {{.Module}}Client interface {
    // Close 释放资源，必须幂等（多次调用不报错）。
    Close(ctx context.Context) error

    // HealthCheck 返回当前健康状态。
    HealthCheck(ctx context.Context) (HealthStatus, error)
}

// New 构造客户端；context 不可为 nil/canceled/expired。
func New(ctx context.Context, cfg Config) ({{.Module}}Client, error)

// HealthStatus 与 §9.5 JSON Schema 对齐。
type HealthStatus struct {
    Name      string                 `json:"name"`
    Status    string                 `json:"status"` // healthy | degraded | unhealthy
    Message   string                 `json:"message,omitempty"`
    CheckedAt time.Time              `json:"checked_at"`
    LatencyMs int64                  `json:"latency_ms"`
    Metadata  map[string]any         `json:"metadata,omitempty"`
}

// ErrorKind 是 9 类错误枚举（详见 §12.1）。
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

// 包级独立 API（不属于 Client 接口）：
//   NewError / WrapError / IsKind 构成稳定错误 contract，详见 §12.2。
//   Metrics 返回需注册到 observex 的 9 个最小指标定义（详见 §18.1）。
//   Version 返回模块语义化版本字符串（如 "v0.6.3"）。
func NewError(kind ErrorKind, msg string) error
func WrapError(kind ErrorKind, cause error, msg string) error
func IsKind(err error, kinds ...ErrorKind) bool
func Metrics() []MetricDescriptor
func Version() string
```text

**约束**：

- 模板渲染入口：`scripts/render_template.sh --module <name> --package <pkg>`，替换 `{{.Module}}` / `{{.Package}}` 占位符；渲染产物路径不得落在本仓库内（详见 §7 FR-015 / §22.6.4）。
- 接口最小化（`Client` 仅 `Close` + `HealthCheck` 两方法）；其余 §9.1 表中的 API 作为**包级独立函数 / 类型**（`New / Validate / Sanitize / NewError / Metrics / Version`），不强制塞入 Client 接口。
- 所有方法 / 函数第一参数 `context.Context`（构造、Close、HealthCheck），返回值含 `error`。
- 接收器一致性：`Config.Validate()` 与 `Config.Sanitize()` 统一为 **pointer 接收器读取 + 返回值类型副本**；Sanitize 必须做 deep copy（不得共享 map/slice 底层数组）。
- 禁止暴露 `float64` 表达金额（基座统一使用 `decimalx`，详见 ARCHITECTURE.md）。
- 模板生成后必须通过 `GOWORK=off go vet ./...`（FR-009 / FR-015）。
- 需要 Go ≥ 1.18（`map[string]any` 别名）；模块根 `go.mod` 必须声明 `go 1.23` 与 `.tool-versions` 一致（§1 元信息）。

### 9.2 Gate Result Envelope

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
```text

### 9.3 Exit Code 契约

| 退出码 | 含义 |
|--------|------|
| 0 | passed |
| 1 | failed/planned/gap |
| 2 | 非法参数 |
| 3-9 | 保留 |

### 9.4 goalcli CLI Contract

| 字段 | 要求 |
|------|------|
| 输出格式 | JSON report 符合 goalcli-report.schema.json |
| status=passed | 返回 0 |
| status=failed/planned/gap | 返回 1 |
| --verify/--strict | 遇到 planned/gap 必须阻断 |
| P0 commands | 68 个必须实现 |
| P1 commands | 26 个必须实现 |
| P2 commands | 12 个必须实现 |
| 14 个 surface | 必须同批同步 |

> 注：v0.2.0 gap ledger 中有 5 个命令处于 pending 状态（score-gate、proof-replay、depth-report、conformance-check、standard-impact-report），待后续 PR 实现。

### 9.5 HealthCheck JSON Schema

```json
{
  "name": "string",
  "status": "healthy|degraded|unhealthy",
  "message": "string",
  "checked_at": "2026-06-07T...",
  "latency_ms": 0,
  "metadata": {}
}
```text

---

## 11. 数据模型（Data Model）

> 本节按 `SPEC-TEMPLATE.md §10` 约束：每个核心对象给出字段表 + Go struct 参考；JSON tag 与 §9.5 / §9.2 / §10.6 schema 对齐。

### 10.1 Goal 对象模型

Goal 是 Goal Runtime 的核心承载对象，贯穿 Spec → Plan → Task → Evidence → Release。

| 字段          | 类型                | 必填 | 说明                                                             |
|---------------|---------------------|:----:|------------------------------------------------------------------|
| `ID`          | `string`            |  ✅  | 形如 `GOAL-YYYYMMDD-NNN`；全局唯一                               |
| `Title`       | `string`            |  ✅  | 一句话目标描述                                                   |
| `Status`      | `GoalStatus`        |  ✅  | `draft / accepted / in_progress / blocked / done / superseded`  |
| `Priority`    | `string`            |  ✅  | `P0 / P1 / P2`                                                   |
| `SpecRef`     | `string`            |  ✅  | 关联 SPEC.md 路径与锚点                                          |
| `Plan`        | `[]TaskRef`         |  ⭕  | 拆解出的 Task 列表                                               |
| `Evidence`    | `[]EvidenceRef`     |  ⭕  | Evidence Ledger 行号或路径                                       |
| `CreatedAt`   | `time.Time`         |  ✅  | RFC3339                                                          |
| `UpdatedAt`   | `time.Time`         |  ✅  | RFC3339                                                          |

```go
type Goal struct {
    ID        string         `json:"id"`
    Title     string         `json:"title"`
    Status    GoalStatus     `json:"status"`
    Priority  string         `json:"priority"`
    SpecRef   string         `json:"spec_ref"`
    Plan      []TaskRef      `json:"plan,omitempty"`
    Evidence  []EvidenceRef  `json:"evidence,omitempty"`
    CreatedAt time.Time      `json:"created_at"`
    UpdatedAt time.Time      `json:"updated_at"`
}

type GoalStatus string

const (
    GoalStatusDraft       GoalStatus = "draft"
    GoalStatusAccepted    GoalStatus = "accepted"
    GoalStatusInProgress  GoalStatus = "in_progress"
    GoalStatusBlocked     GoalStatus = "blocked"
    GoalStatusDone        GoalStatus = "done"
    GoalStatusSuperseded  GoalStatus = "superseded"
)
```text

**Evidence Chain 9 Goal Groups**：

| 组 | 目标              | 产出              |
|----|-------------------|-------------------|
| G1 | Goal Acceptance   | MVA Gate 1        |
| G2 | Spec Verification | Requirement ATDD  |
| G3 | Design Review     | Architecture ADR  |
| G4 | Plan Execution    | Task breakdown    |
| G5 | Task Completion   | Implementation    |
| G6 | Test Evidence     | Coverage report   |
| G7 | Review Approval   | Code review       |
| G8 | Delivery          | Release manifest  |
| G9 | Retrospective     | Lessons learned   |

### 10.2 Proof Runtime 4-Plane 架构

```text
Spec Plane → Execution Plane → Proof Plane → Automation Plane
```text

> 注：Proof Runtime 当前完成度约 88-92%。10 个 REQ-PROOF 中，Facts SSOT、GateReport、Evidence Replay 已完全实现；Downstream Proof Schema、Proof Depth D0-D7 等处于设计封顶阶段，待 PR 逐步落地。

### 10.3 Goal Kernel 对象（8 个）

每个对象都是 Go struct，导出字段为 PascalCase，JSON tag 为 snake_case。

| 对象       | 必填字段（最小）                                | JSON tag 关键字            |
|------------|-------------------------------------------------|----------------------------|
| `Goal`     | 见 §10.1                                        | 同上                       |
| `Spec`     | `ID`, `Path`, `Version`, `FRs[]`                | `id / path / version`      |
| `Design`   | `ID`, `GoalID`, `ADRRefs[]`                     | `id / goal_id / adr_refs`  |
| `Plan`     | `GoalID`, `Tasks[]`                             | `goal_id / tasks`          |
| `Task`     | `ID`, `Title`, `Status`, `Owner`                | `id / title / status`      |
| `Test`     | `ID`, `TaskID`, `Kind`, `Result`                | `id / task_id / kind`      |
| `Evidence` | 见 §10.5                                        | 同 §10.5                   |
| `Review`   | `ID`, `Subject`, `Reviewer`, `Decision`         | `id / subject / decision`  |

### 10.4 Harness Runtime 对象（14 个）

`HarnessConfig`、`ModeRouter`、`GateRegistry`、`CommandRegistry`、`BlockingPolicy`、`EvidencePolicy`、`CostBudget`、`ConformanceLevel`、`RuntimeVersion`、`RuntimeConstitution`、`StopConditions`、`ExpansionPolicy`、`SimplificationPolicy`、`RuntimeBenchmark`。

完整 struct 定义由 `cmd/goalcli/internal/runtime/` 包承载；本规格只约束对象集合与边界。

### 10.5 Evidence Ledger

- **源**：`.agent/evidence/ledger.jsonl`（append-only JSONL，禁止删除失败 Evidence，FR-032）
- **派生**：`release/evidence/goalcli/`（generated packs，不是 source ledger）

每一行记录 schema（与 §13.2 truth-state、§10.7 AdoptionStatus 共享枚举）：

| 字段              | 类型     | 必填 | 说明                                                  |
|-------------------|----------|:----:|-------------------------------------------------------|
| `schema_version`  | `string` |  ✅  | 形如 `"1.0"`                                          |
| `timestamp`       | `string` |  ✅  | RFC3339                                               |
| `goal_id`         | `string` |  ✅  | 关联 Goal                                             |
| `gate_id`         | `string` |  ✅  | 关联 Gate                                             |
| `status`          | `string` |  ✅  | `passed / failed / planned / gap`                     |
| `exit_code`       | `int`    |  ✅  | 与 §9.3 一致                                          |
| `truth_state`     | `string` |  ✅  | `verified / planned / weak / violated / unverified_remote / incomplete`；详见 §13.2 / §2.1 |
| `adoption_status` | `string` |  ⭕  | 与 §10.7 AdoptionStatus 枚举一致；仅 downstream 相关 gate 必填 |
| `evidence_state`  | `string` |  ⭕  | `not_run / partial / complete`；与 §10.7 一致         |
| `evidence_path`   | `string` |  ⭕  | 派生 evidence pack 相对路径                            |
| `command`         | `string` |  ⭕  | 触发命令                                              |
| `details`         | `object` |  ⭕  | 任意 JSON 详情                                         |

```go
type EvidenceEntry struct {
    SchemaVersion   string          `json:"schema_version"`
    Timestamp       string          `json:"timestamp"`
    GoalID          string          `json:"goal_id"`
    GateID          string          `json:"gate_id"`
    Status          string          `json:"status"`
    ExitCode        int             `json:"exit_code"`
    TruthState      TruthState      `json:"truth_state"`
    AdoptionStatus  AdoptionStatus  `json:"adoption_status,omitempty"`
    EvidenceState   string          `json:"evidence_state,omitempty"`
    EvidencePath    string          `json:"evidence_path,omitempty"`
    Command         string          `json:"command,omitempty"`
    Details         map[string]any  `json:"details,omitempty"`
}

type TruthState string

const (
    TruthStateVerified         TruthState = "verified"
    TruthStatePlanned          TruthState = "planned"
    TruthStateWeak             TruthState = "weak"             // registered / baseline_scanned / dry_run_ready 等弱事实
    TruthStateViolated         TruthState = "violated"         // 弱事实尝试升级为强事实
    TruthStateUnverifiedRemote TruthState = "unverified_remote" // 远端治理不可本地证明
    TruthStateIncomplete       TruthState = "incomplete"       // manifest 字段缺失等
)
```text

### 10.6 Release Manifest（latest.json）

> 本表字段必须**完整覆盖 §22.4 的 37 项 No-Go 条件**——每项 No-Go 都有对应的 manifest 字段或 evidence pack 引用，否则 release-final-check 无机器可读判断依据。

| 字段                          | 类型              | 必填 | 说明 / 关联 No-Go                       |
|-------------------------------|-------------------|:----:|---------------------------------------|
| `module`                      | `string`          |  ✅  | 模块名                                |
| `version`                     | `string`          |  ✅  | 形如 `v0.6.3`（NG-01 CHANGELOG 条目对应） |
| `commit`                      | `string`          |  ✅  | 40 char commit sha                    |
| `tree_sha`                    | `string`          |  ✅  | 40 char tree sha                      |
| `source_digest`               | `string`          |  ✅  | source pack sha256                    |
| `go_version`                  | `string`          |  ✅  | 编译时 Go 版本（NG-07 toolchain 漂移） |
| `generated_at`                | `string`          |  ✅  | RFC3339                               |
| `changelog_entry`             | `string`          |  ✅  | CHANGELOG.md 中本版本条目锚点（NG-01） |
| `public_api_surface`          | `object`          |  ✅  | API 冻结快照（NG-02）                  |
| `surface_classification`      | `object`          |  ✅  | stable / experimental / internal 分类（NG-03） |
| `breaking_changes`            | `[]BreakingChange`|  ⭕  | 含 migration_note（NG-04）             |
| `release_entrypoint`          | `string`          |  ✅  | 必须为 `cmd/goalcli`，不得为 `cmd/xlibgate`（NG-05 / NG-06） |
| `workflow_pins`               | `[]WorkflowPin`   |  ✅  | 每个 workflow action 的 40-char SHA（NG-08） |
| `workflow_permissions`        | `[]WorkflowPerm`  |  ✅  | 每个 workflow 的 explicit permissions（NG-09） |
| `pr_template_present`         | `bool`            |  ✅  | PR template + CODEOWNERS 存在（NG-10） |
| `registry_validation_status`  | `string`          |  ✅  | `passed / failed`（NG-11）             |
| `release_artifact_validation` | `string`          |  ✅  | `passed / failed`（NG-12）             |
| `generator_determinism`       | `object`          |  ✅  | determinism / idempotency 证据（NG-13） |
| `downstream_replays`          | `[]ReplayResult`  |  ✅  | kernel/configx/redisx replay 结果（NG-14） |
| `downstream_status`           | `[]AdoptionRecord`|  ✅  | 不得把 not_run 报告为 passed（NG-15）  |
| `p0_debt_count`               | `int`             |  ✅  | 必须 == 0（NG-16）                     |
| `truth_state_violations`      | `int`             |  ✅  | 必须 == 0（NG-17）                     |
| `manifest_blocks_present`     | `[]string`        |  ✅  | 必须含 goal/worktree/branch/cicd/governance/risk/downstream（NG-18） |
| `open_blockers`               | `[]BlockerRef`    |  ✅  | P0 blocker / RC blocker 必须为空（NG-19） |
| `rollback_policy`             | `RollbackPolicy`  |  ✅  | 回滚策略文件存在与摘要（NG-20）        |
| `docker_toolchain_parity`     | `object`          |  ✅  | parity 证明（NG-21）                   |
| `toolchain_drift_report`      | `object`          |  ✅  | docs/workflow/manifest 间一致性（NG-07 复核） |
| `trace_coverage_todo_count`   | `int`             |  ✅  | TRACEABILITY 中 `[行级证据 TODO]` 数量（NG-33 输入） |
| `checks`                      | `[]CheckResult`   |  ✅  | 各 gate 结果                          |
| `contracts`                   | `[]ContractRef`   |  ✅  | 接口 / schema 锚点                    |
| `dependencies`                | `[]Dependency`    |  ✅  | go.mod 关键 require                   |
| `tools`                       | `[]ToolPin`       |  ✅  | golangci-lint / govulncheck 等版本    |
| `standard_impact`             | `object`          |  ⭕  | 影响下游模块清单                       |
| `downstream_sync_required`    | `bool`            |  ⭕  | 是否要求下游同步                       |
| `score`                       | `float`           |  ✅  | scorecard 总分（≥ 9.8 才允许 release） |
| `workflow`                    | `string`          |  ✅  | 触发的 workflow 文件名                |
| `artifacts`                   | `[]ArtifactRef`   |  ✅  | 产物清单                              |
| `evidence_pack_ref`           | `string`          |  ✅  | 关联 evidence pack 路径（NG-22..NG-37 由 pack 覆盖） |

剩余 NG-22..NG-37 由 `evidence_pack_ref` 指向的 pack 内部 JSON 文件覆盖，详见 §22.4 完整表。

### 10.7 Adoption Registry

```yaml
adoption_status: not_run | registered | dry_run | patch_only | proof_verified | adopted | blocked | superseded
evidence_state: not_run | partial | complete
proof_based_adoption: true | false
```text

```go
type AdoptionStatus string

const (
    AdoptionNotRun         AdoptionStatus = "not_run"
    AdoptionRegistered     AdoptionStatus = "registered"
    AdoptionDryRun         AdoptionStatus = "dry_run"
    AdoptionPatchOnly      AdoptionStatus = "patch_only"
    AdoptionProofVerified  AdoptionStatus = "proof_verified"
    AdoptionAdopted        AdoptionStatus = "adopted"
    AdoptionBlocked        AdoptionStatus = "blocked"
    AdoptionSuperseded     AdoptionStatus = "superseded"
)

type AdoptionRecord struct {
    Module             string         `json:"module"`
    AdoptionStatus     AdoptionStatus `json:"adoption_status"`
    EvidenceState      string         `json:"evidence_state"`
    ProofBasedAdoption bool           `json:"proof_based_adoption"`
    LastUpdated        time.Time      `json:"last_updated"`
}
```text

合法状态转换由 FR-051 的 6 个禁止转换规则约束。

### 10.8 配置拓扑（.config/）

18 个命名空间：`xlib`, `goals`, `checklists`, `harness`, `cicd`, `github`, `governance`, `rules`,
`evidence`, `self-improving`, `context`, `facts`, `assertions`, `policies`, `registry`, `templates`, `standard`, `release`。

每个命名空间对应 `.config/<ns>/` 目录，详细 schema 由对应 `docs/standard/<ns>-*.md` 规范化（详见 §21 迁移）。

---

## 12. Config Schema（配置 Schema）

> 本模块作为标准源/模板/Harness/Evidence Runtime，自身不暴露生产业务配置。下游生成库的 Config Schema 由 `scripts/render_template.sh` 渲染产出，并满足以下硬性约束：

- **显式传入**：所有配置必须经构造函数显式注入；禁止隐式读取 ``<secret-store-path>`` 或任何生产路径（详见 §7 FR-013、§19 安全）。
- **Validate**：所有 Config 必须实现 `Validate() error`，无效配置返回 `ErrorKindValidation`（详见 §7 FR-014）。
- **Sanitize**：所有 Config 必须实现 `Sanitize() Config`，输出可入日志/Evidence；屏蔽 `token / secret / password / private_key / 连接凭据`（XS-CORE-008）。
- **配置拓扑**：v1.0.0 目标拓扑收敛到 `.config/` 18 个命名空间，见 §10.8 与 §21 迁移。
- **Schema 校验**：registry / release artifact 必须通过 schema validation；缺失即 fail-closed（详见 §10.5 / §20 CI Gate）。

完整字段表见各下游模块自身 SPEC.md 的 §11；本规格只定义 schema 约束。

---

## 13. 错误处理（Error Handling）

### 12.1 ErrorKind（9 种）

| ErrorKind | Retryable | 说明 |
|-----------|-----------|------|
| config | 否 | 配置错误 |
| validation | 否 | 验证失败 |
| connection | 视场景 | 连接错误 |
| unavailable | 视场景 | 服务不可用 |
| timeout | 是 | 超时 |
| auth | 否 | 认证失败 |
| conflict | 否 | 冲突 |
| rate_limit | 是 | 限流 |
| internal | 否 | 内部错误 |

### 12.2 错误规则

- 公共错误必须使用 `Error`/`NewError`/`WrapError` 表达稳定 contract
- 包装错误必须保留 cause，支持 `errors.Is`/`errors.As`
- 调用方按 `IsKind(err, ErrorKind...)` 做分支判断，不依赖错误字符串
- 错误可纳入 Evidence，但不得包含原始凭据

### 12.3 xlibgate 硬性失败（7 种）

1. secret_leak
2. layer_violation
3. missing_required_contract
4. missing_required_evidence
5. race_detected
6. goroutine_leak
7. release_level_overclaimed

---

## 14. Edge Cases（边界场景）

> 本节包含**调用者视角**的边界场景与**治理视角**的失败语义两类。每条 Edge Case 必须有对应 TC（详见 §16.5）。

### 13.1 调用者视角边界（Caller-Side Edge Cases）

> 下游模块在自身 §13 沿用并扩展。本表为 Go 参考模板的最小集，对应 §9.1.1 接口签名。

| EC ID | 场景 | 触发条件 | 预期行为 | 对应 TC | 对应 FR |
|-------|------|----------|----------|---------|---------|
| EC-001 | nil context | `New(nil, cfg)` / `Close(nil)` / `HealthCheck(nil)` | 返回 `ErrorKindValidation`；禁止 panic | TC-002 | FR-014 |
| EC-002 | canceled / expired context | 传入 `ctx, _ := context.WithCancel(...); cancel(); New(ctx, cfg)` | 立即返回 `ErrorKindTimeout` 或 `ErrorKindUnavailable`；不发起远端连接 | TC-003 | FR-013 / FR-014 |
| EC-003 | 多次 / 并发 Close | 同一 client `Close()` 调用 N 次（N≥2），允许并发 | 幂等：每次返回 nil；底层资源只释放一次；无 race | TC-004 / TC-008 | FR-009 |
| EC-004 | 并发 New / Close | N goroutine 同时 `New(ctx, cfg)` 然后 `Close(ctx)` | 无 race（`go test -race` 通过）；无 FD/goroutine 泄漏（XS-CORE-011） | TC-008 | FR-009 |
| EC-005 | 资源耗尽 | 连接池 / FD / 内存达到上限 | 返回 `ErrorKindUnavailable` 或 `ErrorKindRateLimit`；保留 cause；不 OOM | TC-016 | FR-010 |
| EC-006 | Sanitize 嵌套 nil map | `Config{Nested: nil}` 调用 `Sanitize()` | 返回有效 Config 副本；不 panic；nil 字段保持 nil | TC-006 | FR-014 |
| EC-007 | HealthCheck 超时 | 下游不可达，传入 `timeoutCtx` (timeout=1ms) | 返回 `status=unhealthy / degraded`；`latency_ms ≤ timeout+epsilon`；不挂起 | TC-005 | FR-012 |
| EC-008 | Validate 在 nil receiver | `var c *Config; c.Validate()` | 返回 `ErrorKindValidation`；禁止 panic（防御性检查） | TC-017 | FR-014 |
| EC-009 | Sanitize 修改返回值不影响原对象 | `s := cfg.Sanitize(); s.X = ...` | 原 `cfg` 字段不变；map/slice 不共享底层 | TC-007 | FR-014 / XS-CORE-008 |
| EC-010 | 隐式 secret 路径读取 | 设置 `$HOME=/home/k8s` 后调用 `New(ctx, Config{})` 试图读取生产 secret | enforcer 拒绝隐式读取；返回 `ErrorKindConfig`；详见 §19.1 XS-CORE-016 | TC-009 | FR-013 |

### 13.2 治理视角失败语义（Governance Edge Cases）

#### 13.2.1 xlibgate 硬性失败（7 种）

见 §12.3。任一触发即 fail-closed，不得降级。每条对应 §23.2 风险表与 §10.5 EvidenceEntry 中 `truth_state=violated` 记录。

#### 13.2.2 弱事实禁止升级（truth-state）

| Edge | 弱事实 | 不可视为 | 检测点 |
|------|--------|----------|--------|
| EC-G1 | `registered` | `adopted` | FR-006 / FR-051 / §10.7 AdoptionStatus 枚举 |
| EC-G2 | `baseline_scanned` | `implemented` | §10.5 EvidenceEntry.truth_state |
| EC-G3 | `dry_run_ready` | `executed` | §9.3 退出码 / §10.5 status |
| EC-G4 | `artifact_exists` | `usable` | release-final-check / §10.6 字段完整性 |
| EC-G5 | `CHECK_STATUS=passed` | `release-ready evidence` | §22.3 Gate Chain |
| EC-G6 | downstream sync plan | downstream adoption proof | FR-052 / FR-006 |

详见 §2.1 / §8.7 / `CONFLICT-LEDGER.md`。

#### 13.2.3 远端治理不可本地证明

本地文件不能证明 GitHub branch protection 已启用、ruleset 生效、required checks 绑定、GitHub Release object 已创建等。详见 §23.3 / §23 OQ-001。这些必须通过远端 API / CI artifact / ruleset export 单独证明，记录为 EvidenceEntry 中 `truth_state=unverified_remote`。

---

## 15. Directory Structure（目录结构）

> xlib-standard 自身目录结构以上游 `github.com/ZoneCNH/xlib-standard` 仓库为权威；本规格只声明顶层约束：

```text
xlib-standard/
├── cmd/goalcli/          # 唯一 Go runtime 执行面
├── scripts/              # render_template.sh 等 helper
├── docs/
│   ├── standard/         # 27 个标准文档（详见 §C.1）
│   ├── adr/              # 9 个正式 ADR + 1 模板 + 3 历史（详见 §C.2）
│   ├── l2/               # L2 适配器执行计划
│   ├── testing/          # L2 测试与 evidence 标准
│   └── evidence/         # Evidence 协议补充
├── contracts/            # goalcli-report.schema.json 等
├── .agent/               # 控制面（registries / policies / inbox / evidence ledger）
├── .xlib/                # facts（v1.0.0 前与 .agent 并存）
├── .config/              # v1.0.0 目标数据面（18 命名空间，详见 §10.8）
└── .worktree/            # 当前工作上下文与历史规划
```text

下游生成库的目录结构由模板渲染保证（详见 §7 FR-015~017）。

---

## 16. 依赖（Dependencies）

### 15.1 层级依赖模型

> **领域命名口径**：与 `ARCHITECTURE.md` / `CLAUDE.md` 一致，采用 **领域分层**（基座 / 数据域 / 分析域 / 决策域 / 执行域 / 入口 / 横切）。`xlib-standard`、`xlibgate` 属于 **基座领域的 Foundation Gate 治理子层**，不是独立于五领域之外的第六领域。下表保留旧 L 编号仅作历史映射。

```text
基座 · Foundation Gate 子层：xlib-standard, xlibgate
    ↓
基座 L0（原 L0）：kernel
    ↓
基座 L1（原 L1）：configx / observex / testkitx / resiliencx / schedulex
    ↓
基座 L2（原 L2）：redisx / kafkax / natsx / postgresx / taosx / ossx / clickhousex
    ↓
（以下为私有域，不开源；对应 ARCHITECTURE.md 的数据域 / 分析域 / 决策域 / 执行域 / 入口）
xgo-contracts → xgo-market-data, xgo-macro-data → market-engine, macro-engine, regime-engine → x.go
```text

### 15.2 L2 Provider 规格

L2 模块包括 `postgresx`、`redisx`、`kafkax`、`natsx`、`taosx`、`ossx`、`clickhousex`。

L2 交付链：capability manifest → contract pack → adapter implementation → evidence pack → contract/integration/chaos/benchmark/adoption gates → xlibgate release judgment。

Release ladder：

| 阶段 | 语义 |
|------|------|
| T0 | 文档和计划存在，不可发布。 |
| T1 | capability 和 contract 初步存在，不可发布。 |
| T2 | 本地 contract/integration 有证据，但未达 release profile。 |
| T3 | 首个 release-allowed 阶段。 |
| T4 | factory-grade；包括更完整的故障、性能、兼容和 adoption 证据。 |

缺失 profile、pack、readiness 或证据时，L2 release 必须 fail closed。

### 15.3 依赖方向规则

- 依赖只能从高层指向低层，不可反向
- L3-L6 不公开、不开源
- xlib-standard 不得依赖 x.go 或业务仓库
- 生成库不得依赖 x.go

### 15.4 工具依赖

| 工具 | 版本 | 用途 |
|------|------|------|
| Go | 1.23.x | 编译 |
| golangci-lint | v2.1.6 | Lint |
| govulncheck | v1.3.0 | 漏洞扫描 |
| python3 | 3.x | 脚本 |
| sha256sum | - | 校验和 |
| make | - | 构建 |
| git | - | 版本控制 |
| Docker | - | 工具链运行时 |

---

## 17. 测试（Testing）

### 16.1 测试分层（TL0-TL7）

> **命名口径**：测试分层使用前缀 `TL`（Test Layer），避免与 §15.1 领域分层 "基座 L0/L1/L2" 撞名。

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

### 16.2 Gate 分类（66 个 harness.yaml 条目）

| harness.yaml section | 数量 | 语义边界 |
|----------------------|------|----------|
| required_gates | 44 | required_gates 是当前权威 gate 定义来源，覆盖 fmt/vet/lint/test/race、治理、registry、Docker、release scope、evidence、version、doctor 等必跑条目 |
| extended_gates | 10 | 扩展验证，包含 property、golden、fuzz_smoke、ci_extended、release_check_extended 和 goalcli G12-G15 下游/交付条目 |
| final_gates | 6 | 发布最终判定，包含 release_score_final、release_final_check、release_preflight、score、kernel_downstream、goalcli_g16_runtime_final |
| goalcli_mva_gates | 6 | 大写 MVA alias，映射到 goalcli G12-G16 流程，不生成第二套权威 gate |

> 口径：66 个 gate 条目 = 44 required_gates + 10 extended_gates + 6 final_gates + 6 goalcli_mva_gates。`gate_link_semantics.authority_source` 指向 `required_gates[].id`，重复 command link 只表示 alias。

> 注：9 个 proof_depth taxonomy 条目（file_exists, command_registered, dry_run, positive_fixture, negative_fixture, mutation_fixture, live_run, evidence_replay, downstream_adoption）不计入 gate 总数。

**Context Profiles（4 个）**：

| Profile | 组合 |
|---------|------|
| context-lite | governance-check |
| context-standard | governance-check + p1-governance-check + docs-check |
| context-full | governance-check + p1-governance-check + p2-runtime-check |
| context-release | context-full + integration + dependency-check + standard-impact-check + score-check + evidence + release-evidence |

### 16.3 Profile Gates

| Profile | 库类型 | 特殊要求 |
|---------|--------|----------|
| Pure Library | kernel, testkitx | 标准测试 |
| Config Library | configx | 配置验证/脱敏 |
| Observability Library | observex | metrics/health |
| Storage Library | postgresx, redisx, taosx, ossx, clickhousex | 连接池/事务 |
| Messaging Library | kafkax | 消息语义 |

### 16.4 必需覆盖

- `go test ./...` 覆盖公共包、internal/、contracts/、testkit/ 和 examples/
- 配置校验/脱敏、typed error kind、wrapped cause、客户端创建/取消/过期/幂等关闭
- HealthCheck JSON contract、生命周期 metrics、Config.Sanitize secret 不变量（property test）
- Config 边界输入（fuzz-smoke）、HealthStatus JSON 输出（golden test）

### 16.5 TC ↔ FR 追溯矩阵（核心 P0）

> **范围**：以下表覆盖 §13 Edge Cases 与 §7.2 Go 参考模板 FR (FR-009..FR-014) 的最小用例集。其余 P0 FR 的 TC 由 harness.yaml 的 gate 输出 + Evidence pack 间接证明；本表为"代码可写"的最小用例样板，下游模块在自身 SPEC §16 沿用并扩展。

| TC ID | 测试类型 (TL) | 对应 FR / Edge | 场景 (Given/When) | 预期结果 (Then) |
|-------|---------------|----------------|--------------------|------------------|
| TC-001 | TL1 Unit | FR-009 / FR-013 | 调用 `New(ctx, Config{})` 传入零值 Config | 返回 `ErrorKindValidation`；未创建任何 goroutine/FD |
| TC-002 | TL1 Unit | FR-014 / EC-001 | 调用 `New(nil, validCfg)` 传入 nil context | 返回 `ErrorKindValidation`；panic 不被允许 |
| TC-003 | TL1 Unit | EC-002 | 调用 `New(canceledCtx, validCfg)` | 立即返回 `ErrorKindTimeout` 或 `ErrorKindUnavailable`；不发起远端连接 |
| TC-004 | TL1 Unit | EC-003 | `client.Close(ctx)` 调用 N 次（N>=2） | 幂等：每次都返回 nil；底层资源只释放一次 |
| TC-005 | TL2 Contract | FR-012 / EC-007 | `client.HealthCheck(timeoutCtx)`，timeout=1ms，下游不可用 | 返回 `status=unhealthy / degraded`，`latency_ms<=timeout+epsilon`；不挂起 |
| TC-006 | TL2 Property | FR-014 / EC-006 | 任意嵌套 `Config{Nested: {Token: rand}}` 调用 `Sanitize()` | 返回值的所有 `token / secret / password / private_key` 字段为空；原对象不被修改 |
| TC-007 | TL2 Property | FR-014 | `cfg.Sanitize()` 返回值修改其 map/slice | 原 `cfg` 字段不变（验证 deep copy） |
| TC-008 | TL2 Boundary | EC-004 / EC-005 | 并发 N goroutine 同时调用 `client.Close(ctx)` | 无 race（`go test -race` 通过）；无 panic；其中一个 Close 成功，其余幂等返回 |
| TC-009 | TL2 Security | FR-013 / 19.1 | `os.Setenv("HOME","/home/k8s")` 后调用 `New(ctx, Config{})` | enforcer 拒绝隐式读取 ``<secret-store-path>``；返回 `ErrorKindConfig` |
| TC-010 | TL4 Golden | FR-012 | `HealthCheck()` 输出 JSON | 与 `testdata/health.golden.json` 字节级一致（除 `checked_at`/`latency_ms`） |
| TC-011 | TL4 Fuzz | FR-014 | `go test -fuzz=FuzzConfigValidate` ≥ 30s | 无 panic；任何 Validate 失败都返回 `ErrorKindValidation` 而非其他 ErrorKind |
| TC-012 | TL6 Release | FR-027 / §10.6 | `goalcli release-final-check` 在缺失 manifest 任一必填字段时 | 退出码 1；evidence 记录 `truth_state=incomplete`；阻断 release |
| TC-013 | TL2 Truth-state | FR-006 / §13.2 | `adoption_status=registered` 直接尝试 → `adopted` | enforcer 拒绝；返回禁止转换原因；详见 §10.7 / FR-051 |
| TC-014 | TL2 Contract | FR-010 / §12.1 | `IsKind(err, ErrorKindTimeout)` 应用于 `WrapError(ErrorKindTimeout, cause, "")` | 返回 true；`errors.Is(err, cause)` 也必须为 true |
| TC-015 | TL1 Unit | FR-011 | `Metrics()` 返回值 | 长度 == 9；命名匹配 §18.1 表；无重复 |
| TC-016 | TL2 Boundary | FR-010 / EC-005 | 注入连接池/FD/内存上限（fake limiter），调用 `New` / `client` 操作 | 返回 `ErrorKindUnavailable` 或 `ErrorKindRateLimit`；保留 cause（`errors.Is` 命中）；进程不 OOM |
| TC-017 | TL1 Unit | FR-014 / EC-008 | `var c *Config; c.Validate()`（nil receiver） | 返回 `ErrorKindValidation`；禁止 panic（防御性检查） |

**追溯绑定**：

- 每条 TC 必须落到一个具体 Go test 函数（`Test<TC编号>` 或 `TestFR<NNN>_<scenario>`）。
- 每条 TC 必须有对应的 `Evidence Ledger` 行（FR-026 / §10.5）；失败时 `status=failed` 不得删除（FR-032）。
- 本表不替代 harness.yaml gate；harness 通过运行 `go test` + 解析 JUnit 输出消费这些 TC。
- **TC 编号命名空间**：本表的 `TC-001..TC-017` 属于 `xlib-standard` 命名空间。下游模块在自身 SPEC §16 复用时**必须加模块前缀**（`<module>-TC-NNN`，如 `redisx-TC-001`），并在自身追溯表标注"继承自 xlib-standard TC-NNN"，禁止裸 `TC-NNN` 跨模块复用。
- 下游模块在自身 SPEC §16 至少为该模块独有 FR 增补 ≥1 TC，并继承本表 TC-001..TC-017 作为"基础合规集"。

**无显式 TC 的 FR 处理**（traceability-check.sh 已报警的 5 条）：

| 无 TC 的 FR | 由何替代覆盖 | 证据路径 |
|-------------|--------------|----------|
| FR-001 (419 条规则) | harness gate `registry-validate` | `pack/registry-validate.json` |
| FR-002 (7 类技术债) | harness gate `debt-scan` | `pack/debt-scan.json` |
| FR-005 (8 个 REQ) | harness gate `adoption-check` | `pack/adoption-check.json` |
| FR-046 (28 个 PR 包) | 计划性 FR，由 `goal-runtime` ledger 追踪，无单元 TC | `.agent/evidence/ledger.jsonl` |
| FR-052 (20 PR 下游同步) | 计划性 FR，由 `downstream-sync-policy` gate 追踪 | `pack/downstream-sync.json` |

> 上述 5 条 FR 不在 §16.5 单元 TC 集合内是**设计选择**（gate 级而非 unit 级），但 `traceability-check.sh` 仍会标黄；本表显式列出替代证据后视为已解释，进入 Approved 前由 reviewer 复核。

---

## 18. 性能（Performance Budget）

### 17.1 Gate 成本预算

- 每个 Gate 必须有成本预算（runtime_cost_budget.yaml）
- A-Z 是 Capability Catalog，不是必经流程
- Full Mode 不得滥用，只在高风险上下文阻断

### 17.2 测试性能要求

- Race detection gate 必须通过（`go test -race`）
- 竞态/共享状态必须通过 race gate 验证（XS-CORE-010）
- 不得创建隐藏全局 client、后台 goroutine 或不可关闭资源（XS-CORE-011）

### 17.3 CI 性能约束

| 指标 | 目标 |
|------|------|
| 单 Gate 最大执行时间 | < 5 分钟 |
| 核心质量 Gates（fmt/vet/lint/test/race 等） | < 15 分钟 |
| Release Scorecard 计算 | < 30 秒 |
| Evidence Manifest 生成 | < 10 秒 |
| goalcli score --min 9.8 | < 60 秒 |

### 17.4 模板渲染性能

- `scripts/render_template.sh` 单次渲染 < 10 秒
- `make integration`（渲染 3 个临时下游库）< 2 分钟
- 并行渲染时文件锁必须互斥

---

## 19. 可观测性（Observability）

### 18.1 最小指标（9 个）

| 指标 | 类型 | 说明 |
|------|------|------|
| client_created_total | counter | 客户端创建 |
| client_closed_total | counter | 客户端关闭 |
| client_errors_total | counter | 错误计数 |
| client_health_status | gauge | 健康状态 |
| client_health_latency_ms | histogram | 健康检查延迟 |
| client_requests_total | counter | 请求计数 |
| client_request_duration_seconds | histogram | 请求延迟 |
| client_retries_total | counter | 重试计数 |
| client_inflight | gauge | 进行中请求 |

### 18.2 Metrics 规则

- metrics label 不能包含高基数字段、用户凭据或业务私有标识（XS-CORE-009）
- 只能记录脱敏配置，不得记录原始凭据

---

## 20. 安全（Security）

### 19.1 P0 安全规则

| 规则 | 来源 |
|------|------|
| 不得隐式读取 ``<secret-store-path>`` | XS-CORE-016 |
| 不得将密钥内容写入源码/README/测试日志/manifest/PR/Evidence | XS-CORE-017 |
| 日志不得输出 secret/token/password/private key/连接凭据 | XS-CORE-008 |
| Claude review 仅限本地执行，不使用 repo API key | ARA-002 |
| Claude 审查脚本禁用工具访问，禁止 push/branch/close/settings 操作 | ARA-003 |
| 第三方 Action 必须固定为 40 位 commit SHA | docs/supply-chain.md |
| Docker image build context 不得包含 Git metadata 或 Agent 运行态 | DTS-003 |
| 未列入 contract 的私密变量不得默认传入容器 | DTS-005 |

### 19.2 安全扫描工具

- `govulncheck`：固定版本 `golang.org/x/vuln/cmd/govulncheck@v1.3.0`
- `golangci-lint`：固定版本 `v2.1.6`
- `XLIB_ENABLE_VULNCHECK=1`：强制启用漏洞扫描

### 19.3 AI 审查边界

- Copilot review 通过 GitHub ruleset 配置
- Claude review 仅限本地执行
- AI review 是 advisory，除非 ruleset 明确提升为 required status check
- auto-merge 默认禁用

---

## 21. CI Gate（持续集成门禁）

### 20.1 Gate 总览

Harness 定义 **66 个 gate 条目**（44 required_gates + 10 extended_gates + 6 final_gates + 6 goalcli_mva_gates）与 **4 个 Context Profiles**（detail 见 §7 FR-020~025 与 §16.2）。

### 20.2 必经检查链（与发布流程一致）

```bash
make docs-check
make governance-check
make integration
make evidence
make release-check
make release-evidence-check
goalcli score --min 9.8
make release-final-check
make release-preflight VERSION=vX.Y.Z
```text

### 20.3 阻断语义

- 任一 P0 Gate 失败 → 阻断发布（FR-022）
- skipped gate 不得记为 passed（FR-030）
- dirty workspace 不得 release（FR-031）
- 失败 Evidence 不得删除（FR-032）
- 7 种 xlibgate 硬性失败 fail-closed（详见 §12.3）

### 20.4 三层硬约束

本地 hooks + CI gate + GitHub Ruleset，三者必须同时生效（FR-047 5 层执行链）。本地文件不能证明 GitHub Ruleset 已启用——见 §23.3 远端治理不可本地证明项。

---

## 22. 迁移（Upgrade Compatibility）

### 21.1 v1.0.0 配置迁移

- **目标**：`.config/` 作为唯一机器可读事实源
- **迁移表**：20+ 条目（`.agent/` → `.config/`，`.xlib/` → `.config/`）
- **37 No-Go 条件**（Part F）：任一为真则不得发布 v1.0.0，核心包括：
  - CHANGELOG 缺 v1.0.0 条目
  - public API surface 未冻结
  - stable/experimental/internal surface 未分类
  - breaking change 缺 migration note
  - release.yml 仍使用 cmd/xlibgate
  - workflow 仍使用 deprecated release entrypoint
  - toolchain 版本在 docs/workflow/manifest 间漂移
  - 任一 workflow action 未 pin 40-char SHA
  - workflow 无 explicit permissions
  - PR template / CODEOWNERS 缺失
  - registry schema validation 缺失
  - release artifact schema validation 缺失
  - generator determinism / idempotency 未证明
  - kernel/configx/redisx replay 未通过
  - downstream not_run 被报告为 passed
  - P0 debt > 0
  - truth-state violation > 0
  - release manifest 缺 goal/worktree/branch/cicd/governance/risk/downstream blocks
  - open P0 blocker / RC blocker 未清零
  - rollback policy 缺失
  - Docker toolchain runtime parity 未证明
  - 其余 16 条见源文件 Part F 完整列表
- **平台适配器分类学**（5 类）：
  1. xlib_standard_fact（标准源事实）
  2. platform_native（平台原生）
  3. thin_adapter（薄适配器）
  4. generated_projection（生成投影，如 CODEOWNERS）
  5. forbidden_legacy（禁止遗留）

### 21.2 迁移路径

```text
v1 提出概念 → v2 审计补全 → v3 修补 P0 缺口 → v5 终极版
```text

### 21.3 关键决策

- `.agent/` 控制面保留，`.config/` 数据面统一
- 迁移必须有回滚计划
- 下游 effective subset 限制为 7 个文件
- CODEOWNERS 从 `.config/github/codeowners.json` 生成

### 21.4 未来考虑（Future Considerations）

> 原 §附录 B，2026-06-08 并入 §21（消解结构债 S3）。

1. **v1.0.0-rc.1**：先进入 rc.1，P0 清零后再发布 stable
2. **Goal Runtime v3.1.1**：28 个 PR 执行包逐步落地
3. **L2 测试工厂**：15 个适配器全部达到 L2-T2+
4. **自动化全链路**：Issue → Goal → ... → Release → Issue Close
5. **xlibctl**：pinned CLI binary 用于工具链分发
6. **Proof Depth D0-D7**：gate 验证深度标准化
7. **Standard Production Kernel**：Canonical Facts → Standard Graph → Goal Graph → Debt Graph → Harness Proof Graph → Evidence Ledger

---

## 23. Release DoD（发布完成定义）

### 22.1 四级 DoD（见 §8.5；每级 checklist 项即 `AC-NNN` 验收标准编号）

> **AC 编号约定**：`AC-T01..T04` 为 Task DoD、`AC-I01..I04` 为 Issue DoD、`AC-G01..G03` 为 Goal DoD、`AC-R01..R06` 为 Release DoD。`TRACEABILITY.md` / 下游 Task Spec 通过 `AC-*` 引用本表条目，闭合 FR↔BR↔AC↔TC 四向链。

**Task DoD**：

- [ ] **AC-T01** 变更范围明确（goal_id / issue 关联）
- [ ] **AC-T02** 测试 / 检查已运行并产生 evidence
- [ ] **AC-T03** 文档有入口（README/CHANGELOG/docs 至少一处）
- [ ] **AC-T04** Known gap 已记录到 ledger

**Issue DoD**：

- [ ] **AC-I01** 验收标准全部满足
- [ ] **AC-I02** 相关 gate 通过（exit code == 0）
- [ ] **AC-I03** Review checklist 完成
- [ ] **AC-I04** 无 XLIB_DEBT_VIOLATIONS

**Goal DoD**：

- [ ] **AC-G01** 所有必需项有实现或不适用理由
- [ ] **AC-G02** CI / integration / evidence 有当日新鲜结果
- [ ] **AC-G03** EvidenceEntry.truth_state ∈ {verified, planned}（无 violated）

**Release DoD**：

- [ ] **AC-R01** Manifest（latest.json）生成且字段完整（§10.6）
- [ ] **AC-R02** release-check 通过
- [ ] **AC-R03** Scorecard 总分 ≥ 9.8
- [ ] **AC-R04** release-final-check 通过
- [ ] **AC-R05** preflight 通过
- [ ] **AC-R06** §22.4 37 项 No-Go 全部为 ✅

### 22.2 DONE with evidence 模板

```text
DONE with evidence:
- Scope:
- Source files:
- Commands:
- Artifacts:
- Manifest:
- Downstream:
- Release status:
- Known gaps:
```text

没有 Evidence 的完成声明不能作为 release / adoption / final-complete 事实（FR-028 / FR-029）。

### 22.3 发布前 Gate Chain

见 §20.2。任一步骤失败即 fail-closed，不得跳过、不得 dry-run 代替（FR-030 / FR-031）。

### 22.4 v1.0.0 No-Go 条件（37 项完整列表）

> 每一行：触发条件 → 验证命令 → gate-id → evidence 路径 / manifest 字段。机器化扫描入口：`goalcli release-final-check --no-go-table`。

| NG-ID  | No-Go 触发条件 | 验证命令 / Gate | Evidence 字段 / 路径 |
|--------|----------------|------------------|---------------------|
| NG-01  | CHANGELOG.md 缺本版本条目 | `make changelog-check` | `latest.json.changelog_entry` |
| NG-02  | 公共 API surface 未冻结 / 与 manifest 不一致 | `make api-freeze-check` | `latest.json.public_api_surface` |
| NG-03  | surface 分类（stable/experimental/internal）缺失 | `make api-classify-check` | `latest.json.surface_classification` |
| NG-04  | breaking change 未带 migration_note | `make breaking-check` | `latest.json.breaking_changes[].migration_note` |
| NG-05  | release entrypoint 误用 `cmd/xlibgate` | `make entrypoint-check` | `latest.json.release_entrypoint == "cmd/goalcli"` |
| NG-06  | xlibgate 二进制被发布 | `make release-binary-audit` | `evidence/release-binary-audit.json` |
| NG-07  | go_version 在 docs / workflow / manifest 间漂移 | `make toolchain-drift-check` | `latest.json.toolchain_drift_report` |
| NG-08  | workflow action 未 pin 至 40-char SHA | `make workflow-pin-check` | `latest.json.workflow_pins` |
| NG-09  | workflow 未声明 explicit permissions | `make workflow-perm-check` | `latest.json.workflow_permissions` |
| NG-10  | PR template / CODEOWNERS 缺失 | `make pr-template-check` | `latest.json.pr_template_present == true` |
| NG-11  | registry validation 失败 | `goalcli registry-validate` | `latest.json.registry_validation_status` |
| NG-12  | release artifact validation 失败 | `goalcli artifact-validate` | `latest.json.release_artifact_validation` |
| NG-13  | generator 非 deterministic / 非 idempotent | `make generator-determinism` | `latest.json.generator_determinism` |
| NG-14  | downstream replay（kernel/configx/redisx）失败 | `make replay-downstream` | `latest.json.downstream_replays` |
| NG-15  | downstream adoption 状态把 not_run 标为 passed | §10.7 AdoptionStatus 校验 | `latest.json.downstream_status` |
| NG-16  | P0 debt count > 0 | `goalcli debt-scan --p0` | `latest.json.p0_debt_count == 0` |
| NG-17  | truth_state violations > 0 | `goalcli truth-check` | `latest.json.truth_state_violations == 0` |
| NG-18  | manifest 缺失必备 block | `goalcli manifest-validate` | `latest.json.manifest_blocks_present` |
| NG-19  | P0 / RC blocker 未清零 | `goalcli blocker-list --release-blocking` | `latest.json.open_blockers == []` |
| NG-20  | rollback policy 缺失或未签出摘要 | `make rollback-policy-check` | `latest.json.rollback_policy` |
| NG-21  | docker toolchain parity 失败 | `make docker-parity` | `latest.json.docker_toolchain_parity` |
| NG-22  | evidence pack 缺失 | `goalcli pack-validate` | `latest.json.evidence_pack_ref` |
| NG-23  | evidence pack 内 ledger 缺日 / 缺 goal | `goalcli ledger-coverage` | `pack/ledger-coverage.json` |
| NG-24  | branch protection 未启用 / required checks 不匹配 | `goalcli remote-attest branch-protection` | `pack/branch-protection.json`（远端，§23.3） |
| NG-25  | ruleset 未生效 | `goalcli remote-attest ruleset` | `pack/ruleset-export.json` |
| NG-26  | GitHub Release object 未创建 / asset 缺失 | `goalcli remote-attest release` | `pack/release-object.json` |
| NG-27  | required check 未绑定到 protected branch | `goalcli remote-attest required-checks` | `pack/required-checks.json` |
| NG-28  | govulncheck 未通过 / 未启用 | `make vulncheck` | `pack/govulncheck.json` |
| NG-29  | golangci-lint 失败 | `make lint` | `pack/lint.json` |
| NG-30  | go test -race 失败 | `make test-race` | `pack/test-race.json` |
| NG-31  | coverage 阈值未达（lib / generator / runtime） | `make coverage-check` | `pack/coverage.json` |
| NG-32  | spec-lint 不为零失败 | `bash specs/scripts/spec-lint.sh` | `pack/spec-lint.json` |
| NG-33  | TRACEABILITY 行级缺口超阈值 | `goalcli trace-coverage` | `pack/trace-coverage.json` |
| NG-34  | COVERAGE-MANIFEST commit/tree 未固定 | `goalcli coverage-pin-check` | `pack/coverage-pin.json` |
| NG-35  | downstream 模块未生成 adoption proof（首次 release 例外） | `goalcli adoption-proof` | `pack/adoption-proof.json` |
| NG-36  | 7 项 xlibgate 硬性失败任一触发（详见 §12.3） | `xlibgate verify` | `pack/xlibgate-verify.json` |
| NG-37  | scorecard < 9.8 | `goalcli scorecard` | `latest.json.score >= 9.8` |

### 22.5 Patch 自动发布

`.github/workflows/release-auto-patch.yml` 自动计算 `vX.Y.(Z+1)` 并发布（详见 §22.6.2）。Patch 仍须通过 §22.4 全部 37 项 No-Go。

### 22.6 部署与运行时细节

> 原 §附录 D，2026-06-08 并入 §22（消解结构债 S3）。

#### 22.6.1 发布流程

```text
make docs-check
make governance-check
make integration
make evidence
make release-check
make release-evidence-check
goalcli score --min 9.8
make release-final-check
make release-preflight VERSION=vX.Y.Z
git tag vX.Y.Z
git push origin vX.Y.Z
```text

#### 22.6.2 Main 合并自动 Patch 发布

`.github/workflows/release-auto-patch.yml` 自动计算 `vX.Y.(Z+1)` 并发布。

#### 22.6.3 Docker Toolchain Runtime

- Docker 是工具链运行时，不是第二套 gate
- `.dockerignore` 必须排除 `.git`/`<runtime-dirs>`/`.worktree`/本地 Evidence
- 环境变量必须显式传递并记录语义

#### 22.6.4 生成器详细规格

当前标准入口：`scripts/render_template.sh --module <module> --name <name> --package <package> --out <path>`

- 输出目录不得是 `xlib-standard` 根，也不得落在本仓库内部。
- 输出目录必须不存在或为空。
- 必须替换 module/name/package/import path、README、docs、contracts、examples、scripts、manifest、Makefile、CI 中的模板 token。
- 必须去除旧身份 token 和不可提交的生成态 latest 文件。
- 必须排除 `.git`、`<runtime-dirs>`、`.worktree`、`.agent/inbox`、临时缓存、历史生成产物、release/debt latest。
- 生成库必须通过 `GOWORK=off go test ./...` 和标准门禁。
- 生成库不得引入 `x.go`、业务导入、生产 secret 路径或 provider 真实凭证。

治理包渲染：下游使用 `--enable-governance` 时，必须写入标准版本、标准 commit、layer、lock 文件和治理材料。

默认代表下游：`kernel`（L0）、`configx`（L1）、`redisx`（L2）。

#### 22.6.5 goalcli 运行时规格

`cmd/goalcli` 是唯一 Go runtime execution face。通用 CLI 契约：

- 除明确 delegated script 外，所有命令输出 JSON。
- JSON 必须包含 `command`、`status`，并可包含 `details`、`gaps`。
- 报告 schema 使用 `contracts/goalcli-report.schema.json`。
- 所有命令本地、非破坏、默认 dry-run。
- `--verify` 和 `--strict` 必须阻断 planned/gap/unknown。

退出码：`passed`→0，`failed`/`planned`/`gap`→1，`unknown`/illegal invocation/schema violation→2。

Goal Runtime：`.agent/evidence/ledger.jsonl` 是目标执行源 ledger；`GOAL_ID` 必须绑定目标执行；G12-G16 为阻断型目标门禁。

---

## 24. 待解决问题（Open Questions）

### 23.1 Open Questions

| 编号 | 问题 | 状态 | 决策时限 |
|------|------|------|----------|
| OQ-001 | GitHub 服务端 branch protection/ruleset 如何配置？ | **已闭合**（branch protection 启用 ci/security/integration 三 required checks + enforce_admins + linear history；两条 active ruleset `protect-main` + `protect-release-tags`；详见 `REMOTE-EVIDENCE.md` §2/§3，pinned 2026-06-08 05:15 +08:00） | 已收敛 |
| OQ-002 | v1.0.0-rc.1 何时发布？ | 待确认 | P0 debt 清零后 |
| OQ-003 | GoalCLI god module 何时重构？ | 已知技术债 | PR-22 Phase 4 |
| OQ-004 | 版本漂移（v0.4.15 多文件仍引用 v0.4.13）何时修复？ | 已知技术债 | 下次 patch 前 |
| OQ-005 | 债务检测从 marker text 扫描升级到语义分析的时间线？ | 已知技术债 | PR-28 Phase 5 |
| OQ-006 | render-check 在 Makefile 中缺失如何补齐？ | 已记录 | PR-10 |
| OQ-007 | P1 活跃覆盖 81.3% < 90%，需再索引 26 条 P1 规则 | 已记录 | v1.0.0-rc.1 前 |
| OQ-008 | COVERAGE-MANIFEST.md 的 commit / tree sha 何时固定？ | **已固定**（93753b30 / 296e3b91，2026-06-08 04:59 +08:00；详见 COVERAGE-MANIFEST.md "路径占位符"段） | 已收敛 |

### 23.2 风险（Risks）

> 原 §附录 A，2026-06-08 并入 §23（消解结构债 S3）。

| 编号 | 风险 | 级别 | 缓解措施 |
|------|------|------|----------|
| R-001 | L2 适配器全部停留在 L2-T0/T1 | 高 | 按 docs/l2/ 执行计划逐个推进 |
| R-002 | v0.6.0 计划与实际脱节 | 中 | 归档 v0.6.0 计划，标注为历史规划 |
| R-003 | AI 审查 402 配额限制 | 中 | 降级为 advisory，不作为 blocking gate |
| R-004 | govulncheck 暂停 | 中 | 通过 XLIB_ENABLE_VULNCHECK=1 强制启用 |
| R-005 | 规则绑定语义漂移 | 中 | 后续 enforcer 改名时需同步更新 |
| R-006 | 本地 hooks 可被绕过 | 高 | 升级为 GitHub ruleset 强制 |
| R-007 | 重复文件未实质修改 | 低 | 清理冗余副本 |
| R-008 | 本地文件不能证明远端治理状态 | 高 | 通过 GitHub API、ruleset export、CI artifact 或 Release object 证明 |
| R-009 | 13 个下游库全部 not_adopted | 高 | 至少推进 kernel 首次采纳，证明模板可用 |
| R-010 | 规格膨胀（当前规模含实现细节） | 中 | 将 PR 执行包清单、goalcli 命令列表拆分到 docs/ 子文档 |
| R-011 | COVERAGE-MANIFEST 的 commit/tree sha 未固定，存在漂移风险 | 中（**本地已收敛**） | 2026-06-08 04:59 本地 pin；commit `93753b30…`、tree `296e3b91…`、154 文件 sha256-prefix 已写入 COVERAGE-MANIFEST §"文件级 sha256"；release 阶段仍由 NG-34 强制重算复核 |

### 23.3 远端治理不可本地证明项

本地文件不能证明：GitHub branch protection 已启用、ruleset 生效、required checks 绑定、
GitHub Release object 已创建、远端 workflow 权限和 Actions pin 生效、下游仓库已接受标准 patch。
这些项必须通过远端 API、CI artifact、GitHub Release、ruleset export 或下游仓库 commit proof 单独证明。

---

### 23.4 参考资料：文档清单（Documentation Inventory）

> 本子节是 §23 内的参考性映射表，不引入额外硬约束。

#### 23.4.1 标准文档（docs/standard/，27 个）

| 文件 | 类别 | 规则数 |
|------|------|--------|
| xlib-standard.md | IMPL+DEP+SEC | 17 |
| acceptance-matrix.md | IMPL | 8 |
| agent-team-contract.md | IMPL | 5 |
| ai-review-automation.md | IMPL+SEC | 6 |
| branch-governance.md | IMPL | 9 |
| conformance-profiles.md | IMPL | 3 |
| debt-governance.md | IMPL | 6 |
| docker-toolchain-standard.md | IMPL+DEP | 10 |
| dod.md | IMPL+DOCS | 5 |
| downstream-compatibility.md | DEP | 6 |
| downstream-registry.md | DEP | 5 |
| evidence-protocol.md | IMPL | 15 |
| goal-runtime.md | IMPL | 5 |
| goalcli-cli-contract.md | IMPL | 16 |
| goalcli-runtime.md | IMPL | 6 |
| layer-governance-rules.md | ARCH | - |
| repository-governance-protocol.md | IMPL | - |
| downstream-adoption-protocol.md | DEP | - |
| harness-gates.md | IMPL | - |
| layering.md | ARCH | - |
| module-boundary.md | ARCH | - |
| release-standard.md | IMPL | - |
| repository-roles.md | IMPL | - |
| retrospective-and-patches.md | DOCS | - |
| security-and-secret-policy.md | SEC | - |
| template-generation-contract.md | IMPL | - |
| truth-state.md | IMPL | - |
| versioning.md | IMPL | - |
| README.md | DOCS | - |

#### 23.4.2 ADR 文档（10 个）

| ADR | 状态 | 核心决策 |
|-----|------|----------|
| ADR-20260602-001 | Accepted | xlib-standard 唯一主身份 |
| ADR-20260602-002 | Accepted | 默认下游从 foundationx 迁移到 kernel |
| ADR-20260602-003 | Accepted | Core Gate 五类检查 |
| ADR-20260603-001 | Accepted | goalcli 作为唯一执行面 |
| ADR-20260603-002 | Accepted | Rule Registry 作为规则 SSOT |
| ADR-20260603-003 | Accepted | 三个域规则文件 |
| ADR-20260603-004 | Accepted | Registry active 提升 Batch 1 |
| ADR-20260603-005 | Accepted | goalcli self-improving-check |
| ADR-20260604-001 | Accepted | L0/L1/L2/L3 分层治理 |

> 注：另有 1 个 ADR 模板（ADR-000-template.md）和 3 个历史规划文件（1.md, 2.md, 3.md），不计入正式 ADR。

#### 23.4.3 9 条核心架构原则

1. 唯一主身份原则
2. 证据驱动完成原则
3. 分层依赖方向原则
4. 机器化优先原则
5. 单一执行面原则
6. 生成闭环原则
7. 标准源治理原则
8. 自进化原则
9. 边界不可污染原则

---

### 23.5 参考资料：关键数字与映射（Key Figures & Mappings）

> 本子节是 §23 内的参考性映射表，不引入额外硬约束。

#### 23.5.1 关键数字汇总

| 指标 | 数值 |
|------|------|
| 输入文件总数（当前整理口径） | 154 |
| 主规格工件总行数（不含 archive） | 2,598（SPEC 2013 + CONFLICT 180 + COVERAGE 201 + TRACEABILITY 148 + README 56） |
| 规则总数 | 419 |
| P0 active | 119 (100%) |
| P1 active | 244 |
| 合计 active | 363 (87%) |
| docs/standard/ 规则数 | ~203 |
| ADR 数量 | 9（正式）+ 1 模板 + 3 历史文件 |
| PR 执行包数 | 28 |
| L2 适配器 | 7（执行计划文件 15） |
| Gates | 66（44 required_gates + 10 extended_gates + 6 final_gates + 6 goalcli_mva_gates） |
| goalcli P0 命令 | 68 |
| goalcli 总命令 | 106 |
| Evidence 协议规则 | 15 |
| 15 条基本真理 | TRUTH-001~015 |
| 采纳状态数 | 8 |
| 禁止状态转换 | 6 |

#### 23.5.2 文件到规格节映射

| 源文件组 | 主要贡献节 |
|----------|-----------|
| .worktree/goal.md | §6.7, §7, §9 |
| .worktree/debt.md | §6.6, §7 |
| .worktree/main.md | §6.8, §7 |
| .worktree/stable.md | §14 |
| .worktree/v3.0.md | §6.7, §9 |
| .worktree/goal-patch.md | §7, §10 |
| .worktree/git.md | §6.8, §7 |
| .worktree/L.md | §15 |
| .worktree/goalcli-v0.1.0-plan.md | §6.7, §8 |
| docs/api.md | §8 |
| docs/config.md | §8, §11 |
| docs/errors.md | §10 |
| docs/observability.md | §16 |
| docs/release.md | §17 |
| docs/testing.md, docs/test-strategy.md | §13 |
| docs/generation.md | §6.3 |
| docs/supply-chain.md | §11 |
| docs/scorecard.md | §12 |
| docs/standard/*.md | §7, §8, §11 |
| docs/adr/*.md | §18 |
| docs/l2/*.md | §15 |
| docs/evidence/*.md | §9 |
| Downloads/*.md | §14 |

#### 23.5.3 迭代演进时间线

```text
2026-06-01  1.md (v1.0 方案) → 2.md (v1.1 方案)
2026-06-02  ADR-001 (身份确立) → ADR-002 (kernel 命名) → ADR-003 (Core Gate)
2026-06-03  ADR-001 (goalcli) → ADR-002 (registry SSOT) → ADR-003 (域规则)
            → ADR-004 (active promotion) → ADR-005 (self-improving)
2026-06-02  3.md (自动化方案)
2026-06-04  ADR-001 (Layer Governance)
2026-06-05  v0.4.15 深度分析（8.3/10）
2026-06-06  第七轮审查补丁（12 个 P0 bypass）
2026-06-07  本规格文档（154 文件当前整理口径）
```text

#### 23.5.4 15 条基本真理（TRUTH-001~015）

> 与 §7.1 Iron Rules 的重复映射（结构债 S3 缓解）：TRUTH 是表述层，IR 是分类层；两者语义重叠时以 TRUTH 编号为外部引用、IR 编号为内部分类。

| # | TRUTH | 对应 IR | 说明 |
|--:|-------|--------|------|
| 1 | 规则不进入 Gate 就不是规则 | IR-005 | Harness 是机器裁判 |
| 2 | 登记态 ≠ adopted | IR-007 | 与 TRUTH-15 同义，TRUTH-15 是扩展形式 |
| 3 | goalcli 是唯一执行面 | — | FR-042 权威 |
| 4 | Proof 是完成的唯一合法证明 | IR-001 | 与 TRUTH-8 同义 |
| 5 | 依赖方向只能从高层指向低层 | — | §7.6 关键约束 1、FR-004 |
| 6 | 本地 + CI + GitHub Ruleset 三重硬约束 | — | FR-047 5 层执行链 |
| 7 | 4-Plane 分离关注点 | — | FR-044 |
| 8 | 没有 Evidence 不允许 DONE | IR-001 | 与 TRUTH-4 同义；FR-028 |
| 9 | Goal 必须从真实上下文开始 | IR-002 | |
| 10 | 需求必须可验证 | IR-003 | |
| 11 | 所有变更必须可追踪 | IR-004 | |
| 12 | Harness 是机器裁判 | IR-005 | 与 TRUTH-1 同义 |
| 13 | Self-improving 是强制环节 | IR-006 | |
| 14 | 文档 ≠ 证据（document ≠ proof） | IR-001 | 同义簇 |
| 15 | registered/baseline_scanned/patch-only ≠ adopted | IR-007 | 与 TRUTH-2 扩展 |

#### 23.5.5 DONE 模板

```text
DONE with evidence:
- Scope:
- Source files:
- Commands:
- Artifacts:
- Manifest:
- Downstream:
- Release status:
- Known gaps:
```text

没有 Evidence 的完成声明不能作为 release、adoption 或 final-complete 事实。
