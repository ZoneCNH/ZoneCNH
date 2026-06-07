# xlib-standard 历史深度分析报告（已归档）

Status: **archived**（2026-06-08 归档；非当前权威）

> **归档说明**：本报告基于 181 文件旧口径，与当前 154 文件主规格冲突，已于 2026-06-08 移入 `archive/`。
> 文中所有口径（181 文件、旧 gate 分类、旧 ADR 汇总、v1→v2 修正历史）**不得**作为当前交付判定。
> 当前权威以 `../SPEC.md` 为准；冲突解释见 `../CONFLICT-LEDGER.md` §16。
>
> 分析时间：2026-06-07（v2 修正版）
> 分析范围：`github.com/ZoneCNH/xlib-standard` 仓库 + `specs/xlib-standard/SPEC.md` v2.0.0
> 分析框架：Goal Runtime + Recursive Self-Improvement + Autoresearch + 六类债务
> 修正说明：v1 版本存在事实性错误（ADR 缺失误判、gate 数量低估、版本号误报），本版基于仓库实际数据重写

---

## 0. 执行摘要

按历史 v2 口径，SPEC.md 已从 v0.3.7 升级到 v2.0.0（23 节、~800 行），历史分析采用 181-file source set、419 条规则、旧 ADR 汇总、28 个 PR 执行包。仓库治理成熟度极高，但存在 **下游采纳断层** 和 **规格膨胀** 两类核心问题。

| 维度   | 评级    | 关键发现                                                                   |
| ------ | ------- | -------------------------------------------------------------------------- |
| 结构债 | ✅ 低   | 分层清晰，boundary gate 强制执行，零外部依赖                               |
| 实现债 | ⚠️ 中   | cmd/goalcli 两个文件过大，正则解析 YAML，常量硬编码                        |
| 测试债 | ⚠️ 中   | pkg/templatex 测试完备（含 fuzz/property/golden），但 governance.go 无测试 |
| 文档债 | ⚠️ 中   | ADR 已存在（9 个 Accepted），但下游矩阵全 `not_adopted`，SPEC 膨胀风险      |
| 依赖债 | ✅ 极低 | go.mod 零外部依赖，仅标准库                                                |
| 领域债 | ⚠️ 中   | 6 类职责边界清晰但 Harness/Evidence 有交叉                                 |

---

## 1. 事实校验（v1 错误修正）

| v1 结论                                  | 实际状态                                                         | 修正     |
| ---------------------------------------- | ---------------------------------------------------------------- | -------- |
| D-001: 无独立 ADR 目录                   | ✅ `docs/adr/` 存在，13 个文件（9 个 Accepted ADR + template + 3 个历史方案文档） | **撤回** |
| D-002: SPEC.md 版本号 v0.3.7 滞后        | ✅ SPEC.md 已升级为 v2.0.0                                       | **撤回** |
| harness.yaml 有 20+ gates                | 实际 66 个 gate 条目（44 required_gates + 10 extended_gates + 6 final_gates + 6 goalcli_mva_gates），另有 9 级 proof_depth taxonomy | **修正** |
| .agent/registries/ 有 4 个 SSOT registry | 实际 14 个文件（含 downstream-registry、command-registry 等）    | **修正** |
| ci.yml 只有一个 job                      | 确认：ci.yml 确实是单 job（`make release-check`）                | **确认** |
| governance.go 过大                       | 确认：仍是最大文件，无对应测试                                   | **确认** |
| 零外部依赖                               | 确认：go.mod 只有 `go 1.23`                                      | **确认** |

---

## 2. Goal Runtime 分析

### 2.1 Goal Runtime v3.1.1 完整性

| 组件                          | 状态                  | 实际数据                                                                                                            |
| ----------------------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `cmd/goalcli` CLI             | ✅ 19 个 Go 文件      | governance/traceability/debt/adoption/selfimproving/audit/dashboard/downstream-sync/schema-check                    |
| `.agent/harness/harness.yaml` | ✅ schema_version 3.1 | **66 个 gate 条目**（44 required_gates + 10 extended_gates + 6 final_gates + 6 goalcli_mva_gates），proof_depth taxonomy 9 级 |
| `.agent/registries/`          | ✅ **14 个文件**      | command-registry、issue-registry、makefile-baseline、downstream-registry、downstream-adoption-status 等             |
| `.agent/policies/debt/`       | ✅ 完整               | rules.yaml、exceptions.yaml、profile.yaml、dependency-purpose.yaml                                                  |
| Makefile                      | ✅ 50+ targets        | required/extended/governance/release/docker 分层                                                                    |
| CI workflows                  | ✅ 9 个               | ci、release、security、adoption-check、docker-contract、goal-gates、integration、release-auto-patch、worktree-guard |
| Evidence Protocol             | ✅ 完整               | `DONE with evidence:` + manifest lifecycle + SHA256                                                                 |
| Docker Toolchain              | ✅ 完整               | Dockerfile + docker-compose.yml + devcontainer                                                                      |
| `pkg/templatex/`              | ✅ 17 个文件          | client/config/errors/health/metrics/version/options/doc + 8 个测试文件（含 fuzz/property/golden）                   |
| `docs/adr/`                   | ✅ 13 个文件          | 9 个 Accepted ADR（20260602-001 ~ 20260604-001）+ template + 3 个历史方案文档                                      |

### 2.2 Harness Gates 分类（66 个）

| harness.yaml section | 数量 | 代表 gates |
| -------------------- | ---- | ---------- |
| required_gates       | 44   | fmt, vet, lint, test, race, docs_check, debt, governance_check, docker_*、release_evidence_check、governance_release_scope |
| extended_gates       | 10   | property, golden, fuzz_smoke, ci_extended, release_check_extended, goalcli_g12_acceptance ~ goalcli_g15b_certify |
| final_gates          | 6    | release_score_final, release_final_check, release_preflight, score, kernel_downstream, goalcli_g16_runtime_final |
| goalcli_mva_gates    | 6    | G12_ACCEPTANCE ~ G12_G16_FINAL；按 alias 处理，不生成第二套权威 gate |

### 2.3 14 个 Registry 文件

| Registry                           | 用途                 |
| ---------------------------------- | -------------------- |
| command-registry.yaml              | goalcli 命令注册     |
| command-implementation-status.yaml | 命令实现状态追踪     |
| commands.yaml                      | 命令定义             |
| issue-registry.yaml                | Issue 注册           |
| makefile-baseline.yaml             | Makefile 基线        |
| makefile-target-registry.yaml      | Makefile target 注册 |
| downstream-registry.yaml           | 下游库注册           |
| downstream-adoption-status.yaml    | 下游采纳状态         |
| downstream-adoption-modes.yaml     | 下游采纳模式         |
| downstream-baseline-scan.yaml      | 下游基线扫描         |
| generated-artifacts.yaml           | 生成产物注册         |
| physical-migration-manifest.yaml   | 物理迁移清单         |
| runtime.yaml                       | 运行时配置           |
| debt/                              | 债务策略目录         |

---

## 3. 结构债分析

### 3.1 分层违规 Import

| 检查项             | 结果    | 说明                                                                  |
| ------------------ | ------- | --------------------------------------------------------------------- |
| `x.go` import 禁令 | ✅ 强制 | `make boundary` + `main-guard` + `worktree-guard`                     |
| L2 互相耦合        | ✅ 无   | go.mod 零外部依赖，L2 库不在此仓库                                    |
| 循环依赖           | ✅ 无   | `internal/` → `pkg/templatex` 单向，`cmd/goalcli` → `internal/` 单向  |
| 上帝模块           | ⚠️ 存在 | `cmd/goalcli/governance.go` 和 `cmd/goalcli/traceability.go` 文件过大 |

### 3.2 发现的结构问题

### S-001: cmd/goalcli/governance.go 过大

- 严重度：P1
- 问题：单文件包含 `emitReport`、`runVersion`、`runDoctor`、`runMainGuard`、`runWorktreeGuard`、`runWorktreeCheck`、`runContextCheck` 等 10+ 个函数
- 建议：拆分为 `report.go`（emitReport）、`guard.go`（main-guard/worktree-guard）、`doctor.go`

### S-002: cmd/goalcli/traceability.go 过大

- 严重度：P1
- 问题：单文件包含解析、校验、路径判定等 200+ 行逻辑
- 建议：拆分为 `trace_parser.go` + `trace_checker.go`

### S-003: internal/ 包过多（9 个）

- 严重度：P2
- 问题：debtcheck、goalcli、goalruntime、releasequality、runtime、sanitize、tools、validation、xlibfacts，部分职责重叠
- 建议：合并 `validation` + `sanitize` 为 `validation`，合并 `goalcli` + `goalruntime` 为 `runtime`

---

## 4. 实现债分析

### 4.1 重复代码

### I-001: emitReport 函数重复调用模式

- 严重度：P2
- 问题：每个 `run*` 函数都重复 `if len(gaps) > 0 { return emitReport(...) } return emitReport(...)` 模式
- 建议：提取 `runGate(cmdName string, details []string, gaps []string) int` 通用函数

### I-002: 文件存在性检查重复

- 严重度：P2
- 问题：`runDoctor`、`runContextCheck`、`runSelfImprovingCheck` 都有类似的 `for _, p := range required { if !fileExists(p) { gaps = append(...) } }` 模式
- 建议：提取 `requireFiles(root string, paths []string) []string` 工具函数

### 4.2 过时模式

### I-003: validation.go 使用反射解析 YAML

- 严重度：P2
- 问题：`ValidateRuntimeFileOwnership` 使用 `reflect` 包，Go 1.23 已有更简洁的方式
- 建议：使用 `gopkg.in/yaml.v3` 或 `encoding/json` 替代

### I-004: selfimproving.go 使用正则解析 YAML

- 严重度：P2
- 问题：`statusRe := regexp.MustCompile(...)` 和 `patchIDRe := regexp.MustCompile(...)` 用正则解析 YAML 结构
- 建议：使用 YAML parser 替代正则，避免格式变化导致假阴性

### 4.3 补丁热点

### I-005: xlibfacts 常量硬编码

- 严重度：P1
- 问题：`CurrentReleaseVersion = "v0.6.1"` 等常量硬编码在 Go 源码中，与 `.xlib/facts/xlib.yaml` 双重维护
- 建议：Go 常量作为 fallback，优先从 `.xlib/facts/xlib.yaml` 加载

---

## 5. 测试债分析

### 5.1 测试文件清单

| 包                    | 测试文件                                                                                                                                                      | 测试类型                  |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------- |
| `cmd/goalcli`         | main_test.go, audit_goal_test.go, dashboard_generate_test.go, downstream_sync_plan_test.go, schema_check_test.go, selfimproving_test.go, traceability_test.go | 单元测试                  |
| `pkg/templatex`       | client_test.go, config_test.go, config_fuzz_test.go, config_property_test.go, errors_test.go, health_test.go, health_golden_test.go, metrics_test.go          | 单元+fuzz+property+golden |
| `internal/validation` | validation_test.go                                                                                                                                            | 单元测试                  |
| `internal/xlibfacts`  | facts_test.go                                                                                                                                                 | 单元测试                  |
| `internal/debtcheck`  | debtcheck_test.go                                                                                                                                             | 单元测试                  |
| `contracts`           | contracts_test.go                                                                                                                                             | Schema 校验测试           |
| `scripts/`            | check_dependency_diff_test.go, check_release_preflight_test.go, check_standard_impact_test.go, render_template_test.go, run_integration_test.go               | 脚本集成测试              |

### 5.2 测试覆盖分析

### T-001: pkg/templatex 测试完备

- 严重度：✅ 无问题
- 现状：8 个测试文件，覆盖单元+fuzz+property+golden，是仓库测试最完备的包
- 结论：参考模板质量有保障

### T-002: cmd/goalcli 测试覆盖不均

- 严重度：P1
- 现状：`governance.go` 是最大的文件但没有对应的 `governance_test.go`
- 问题：核心治理逻辑（main-guard、worktree-guard、doctor、context-check）缺少单元测试
- 建议：添加 `governance_test.go`，覆盖 `emitReport`、`runDoctor`、`runMainGuard` 等

### T-003: 内部包测试缺失

- 严重度：P2
- 现状：`internal/runtime`、`internal/releasequality`、`internal/goalcli`、`internal/goalruntime`、`internal/tools` 没有测试文件
- 建议：至少为 `runtime` 和 `releasequality` 添加基础测试

### T-004: 脚本测试为 Go 包装

- 严重度：P2
- 现状：`scripts/check_dependency_diff_test.go` 等是 Go 测试包装 shell 脚本
- 问题：脚本本身的 shell 逻辑未被测试
- 建议：关键脚本添加 bats 或 shunit2 测试

### 5.3 脆弱测试风险

### T-005: selfimproving_test.go 依赖文件系统

- 严重度：P2
- 问题：测试直接读取 `.agent/` 目录，依赖仓库结构
- 建议：使用 `t.TempDir()` 构造 fixture

### T-006: traceability_test.go 依赖矩阵文件

- 严重度：P2
- 问题：测试读取 `.agent/traceability/traceability-matrix.md`
- 建议：使用内联 fixture 或 `testdata/` 目录

---

## 6. 文档债分析

### 6.1 ADR 已存在（v1 错误修正）

`docs/adr/` 目录存在，包含 13 个文件，其中 9 个为 Accepted ADR，另有 template 和 3 个历史方案文档：

| ADR              | 状态     | 核心决策                             |
| ---------------- | -------- | ------------------------------------ |
| ADR-20260602-001 | Accepted | xlib-standard 唯一主身份             |
| ADR-20260602-002 | Accepted | 默认下游从 foundationx 迁移到 kernel |
| ADR-20260602-003 | Accepted | Core Gate 五类检查                   |
| ADR-20260603-001 | Accepted | goalcli 作为唯一执行面               |
| ADR-20260603-002 | Accepted | Rule Registry 作为规则 SSOT          |
| ADR-20260603-003 | Accepted | 三个域规则文件                       |
| ADR-20260603-004 | Accepted | Registry active 提升 Batch 1         |
| ADR-20260603-005 | Accepted | goalcli self-improving-check         |
| ADR-20260604-001 | Accepted | L0/L1/L2/L3 分层治理                 |

另有 `1.md`、`2.md`、`3.md` 为方案演进文档，`ADR-000-template.md` 为模板。

### 6.2 文档与代码一致性

### D-001: 下游矩阵全 `not_adopted`

- 严重度：P1
- 问题：13 个下游库全部 `not_adopted` / `not_run`，标准定义与实际采纳脱节
- 建议：至少让 `kernel` 完成首次采纳，证明模板可用

### D-002: SPEC.md 膨胀风险

- 严重度：P1
- 问题：SPEC.md 已达 ~800 行、23 节，包含大量实现细节（28 个 PR 执行包、106 个 goalcli 命令、419 条规则清单），与"规格文档"的定位有偏差
- 建议：将实现细节（PR 执行包清单、goalcli 命令列表、规则清单）拆分到 `docs/` 子文档，SPEC.md 保留架构决策和验收标准

### D-003: harness gates 数量不同步

- 严重度：P2
- 问题：历史材料曾混用 "17+ Required Gates"、语义 gate 家族和 66 个 gate 条目；当前口径应区分 harness.yaml 的 66 个 gate 条目（44 required_gates + 10 extended_gates + 6 final_gates + 6 goalcli_mva_gates）与旧 required-family 说法
- 状态：已修复（当前 SPEC.md FR-020、§2 和 §13.2 使用 harness.yaml section 口径）

### D-004: docs/standard/ 27 个文件但 SPEC.md 只列出 18 个

- 严重度：P2
- 问题：SPEC.md Section 18.1 列出 18 个文件 + "其他 9 个文件"
- 建议：补全 27 个文件的完整清单

---

## 7. 依赖债分析

### 7.1 依赖清单

```text
module github.com/ZoneCNH/xlib-standard
go 1.23
// 零外部依赖
```text

| 检查项         | 结果                                 |
| -------------- | ------------------------------------ |
| 直接依赖       | 0 个                                 |
| 间接依赖       | 0 个                                 |
| CVE 风险       | ✅ 无（无外部依赖）                  |
| 废弃依赖       | ✅ 无                                |
| renovate.json  | ✅ 存在                              |
| dependabot.yml | ✅ 存在                              |
| govulncheck    | ✅ 支持（`XLIB_ENABLE_VULNCHECK=1`） |

### 7.2 依赖治理

**DEP-001: 零外部依赖是优点也是限制**

- 严重度：信息
- 问题：go.mod 只有 `go 1.23`，完全依赖标准库
- 影响：优点是零 CVE 风险；限制是 YAML 解析用正则而非标准库，增加维护成本
- 建议：如果 YAML 解析需求增加，考虑引入 `gopkg.in/yaml.v3`（成熟、无 CVE）

---

## 8. 领域债分析（DDD 视角）

### 8.1 限界上下文

| 上下文                | 包含                                           | 边界清晰度         |
| --------------------- | ---------------------------------------------- | ------------------ |
| Standard Source       | `docs/standard/`（27 个）、`contracts/`        | ✅ 清晰            |
| Go Reference Template | `pkg/templatex/`（17 个文件）                  | ✅ 清晰            |
| Generator             | `scripts/render_template.sh`、`templates/`     | ✅ 清晰            |
| Harness Gate          | `Makefile`、`cmd/goalcli/`、`.agent/harness/`  | ⚠️ 模糊            |
| Evidence Runtime      | `release/`、`.agent/evidence/`                 | ⚠️ 模糊            |
| Debt Governance       | `.agent/policies/debt/`、`internal/debtcheck/` | ✅ 清晰            |
| Goal Runtime          | `cmd/goalcli/`、`.agent/registries/`           | ⚠️ 与 Harness 重叠 |

### 8.2 领域问题

**DM-001: Harness 与 Evidence 边界模糊**

- 严重度：P2
- 问题：`cmd/goalcli/` 同时包含 gate 执行（Harness）和 evidence 生成（Evidence Runtime），职责边界不清晰
- 建议：在代码层面通过 package 分离：`cmd/goalcli/gate/` 和 `cmd/goalcli/evidence/`

**DM-002: "gate" 术语过载**

- 严重度：P2
- 问题：66 个 gate 条目横跨 4 个 harness section，且大写 MVA 条目是 alias，"gate" 在不同上下文含义不同
- 建议：在 GLOSSARY.md 中明确区分 `required-gate`、`extended-gate`、`final-gate`、`mva-alias` 和 `proof_depth`

**DM-003: proof_depth 与 status 语义重叠**

- 严重度：P2
- 问题：`proof_depth`（9 级证据强度）和 `status`（8 状态采纳状态机）有交叉，如 `partial_implemented` + `file_exists` 的组合含义不直观
- 建议：文档补充 proof_depth × status 矩阵的语义解释

---

## 9. Autoresearch 发现

### 9.1 递归自改进模式

xlib-standard 已实现完整的 recursive self-improvement 循环：

```text
gate 失败 → retrospective → patches (harness/prompt/rule) → gate 收紧 → 再验证
```text

但存在两个断点：

**A-001: patches 无自动应用**

- 严重度：P1
- 问题：`harness-patches.yaml` 等只记录补丁，没有自动应用机制
- 建议：添加 `make apply-patches` 命令，自动将 ACCEPTED 状态的 patches 应用到对应文件

**A-002: retrospective 无自动触发**

- 严重度：P1
- 问题：retrospective 是手动触发的，CI 失败后没有自动创建 retrospective
- 建议：CI workflow 添加 `on: failure` job，自动生成 retrospective 模板

### 9.2 Goal Runtime 自治性

**A-003: goalcli 无插件机制**

- 严重度：P2
- 问题：所有 gate 逻辑硬编码在 `cmd/goalcli/` 中，新增 gate 需要修改 Go 代码
- 建议：考虑 plugin 或 registry-based gate 注册机制

**A-004: harness.yaml 无 schema 校验**

- 严重度：P2
- 问题：`harness.yaml` 没有 JSON Schema 校验，格式错误只能在运行时发现
- 建议：添加 `contracts/harness.schema.json`

---

## 10. 统一 CI/CD 分析

### 10.1 当前 CI/CD 状态（9 个 workflows）

| Workflow                 | 触发           | 职责                            |
| ------------------------ | -------------- | ------------------------------- |
| `ci.yml`                 | PR + push main | release-check + evidence upload |
| `release.yml`            | release        | 发布流程                        |
| `security.yml`           | 定期           | 安全扫描                        |
| `adoption-check.yml`     | PR             | 下游采纳检查                    |
| `docker-contract.yml`    | PR             | Docker 工具链校验               |
| `goal-gates.yml`         | PR             | Goal governance gates           |
| `integration.yml`        | PR             | 集成测试                        |
| `release-auto-patch.yml` | release        | 自动补丁                        |
| `worktree-guard.yml`     | PR             | worktree 合规检查               |

### 10.2 CI/CD 问题

**CI-001: ci.yml 只有一个 job**

- 严重度：P1
- 问题：`ci.yml` 把所有检查放在一个 job 里（`make release-check`），失败时无法定位具体 gate
- 建议：拆分为多个 job（lint、test、boundary、contracts、debt、evidence），支持并行执行

**CI-002: 无 Docker CI 环境**

- 严重度：P1
- 问题：虽然有 Dockerfile 和 docker-compose.yml，但 CI workflow 使用 `ubuntu-latest` + `setup-go`，没有使用 Docker 工具链
- 建议：添加 Docker CI workflow 或在 ci.yml 中使用 `docker compose run toolchain`

**CI-003: 无 CI 缓存策略**

- 严重度：P2
- 问题：ci.yml 只缓存 Go modules，没有缓存 golangci-lint 和 govulncheck 二进制
- 建议：添加工具二进制缓存

---

## 11. Docker 编译环境分析

### 11.1 当前 Docker 状态

| 组件                                   | 状态    | 说明                                        |
| -------------------------------------- | ------- | ------------------------------------------- |
| Dockerfile                             | ✅ 存在 | 多阶段构建，基于 `golang:1.23-bookworm`     |
| docker-compose.yml                     | ✅ 存在 | toolchain service + build/mod cache volumes |
| .devcontainer/                         | ✅ 存在 | VS Code devcontainer 配置                   |
| scripts/docker/                        | ✅ 存在 | check_toolchain.sh + docker_gate.sh         |
| contracts/docker-toolchain.schema.json | ✅ 存在 | Docker 工具链 schema                        |

### 11.2 Docker 问题

**DC-001: Dockerfile 工具版本硬编码**

- 严重度：P2
- 问题：`GOLANGCI_LINT_VERSION=v2.1.6` 和 `GOVULNCHECK_VERSION=v1.1.4` 在 Dockerfile 和 `xlibfacts/facts.go` 中双重维护
- 建议：从 `xlibfacts` 读取版本，或使用 `.xlib/facts/xlib.yaml` 作为 SSOT

**DC-002: 无 ARM64 支持**

- 严重度：P2
- 问题：Dockerfile 没有 `--platform` 声明，ARM64 环境（M1/M2 Mac）可能构建失败
- 建议：添加 `FROM --platform=$BUILDPLATFORM` 或 multi-arch build

**DC-003: docker-compose.yml 无 CI profile**

- 严重度：P2
- 问题：docker-compose.yml 只有 `toolchain` service，没有 CI-specific profile
- 建议：添加 `ci` profile，包含 `make ci` 的完整 gate 链

---

## 12. 优先级排序

### P0（阻塞发布）

无。v1 的 D-002（版本号滞后）已撤回。

### P1（应尽快修复）

| ID     | 问题                     | 修复建议                                  |
| ------ | ------------------------ | ----------------------------------------- |
| S-001  | governance.go 过大       | 拆分为 report.go + guard.go + doctor.go   |
| S-002  | traceability.go 过大     | 拆分为 trace_parser.go + trace_checker.go |
| I-005  | xlibfacts 常量硬编码     | 优先从 YAML 加载                          |
| T-002  | governance.go 无测试     | 添加 governance_test.go                   |
| D-001  | 下游全 not_adopted       | 推进 kernel 首次采纳                      |
| D-002  | SPEC.md 膨胀             | 拆分实现细节到 docs/ 子文档               |
| A-001  | patches 无自动应用       | 添加 make apply-patches                   |
| A-002  | retrospective 无自动触发 | CI on:failure 自动生成模板                |
| CI-001 | ci.yml 单 job            | 拆分为多 job 并行                         |
| CI-002 | 无 Docker CI             | 添加 Docker CI workflow                   |

### P2（可延后）

| ID     | 问题                           | 修复建议                         |
| ------ | ------------------------------ | -------------------------------- |
| I-001  | emitReport 重复模式            | 提取 runGate 通用函数            |
| I-002  | 文件检查重复                   | 提取 requireFiles 工具函数       |
| I-003  | validation.go 用反射           | 改用 yaml.v3                     |
| I-004  | selfimproving.go 正则解析 YAML | 改用 YAML parser                 |
| T-003  | 内部包测试缺失                 | 添加 runtime/releasequality 测试 |
| T-004  | 脚本 shell 逻辑未测试          | 添加 bats 测试                   |
| T-005  | selfimproving 测试依赖文件系统 | 使用 t.TempDir()                 |
| T-006  | traceability 测试依赖矩阵      | 使用内联 fixture                 |
| D-003  | harness gates 列表不同步       | 同步 SPEC.md                     |
| D-004  | 标准文档列表不完整             | 补充缺失条目                     |
| DM-001 | Harness/Evidence 边界模糊      | package 分离                     |
| DM-002 | "gate" 术语过载                | GLOSSARY.md 区分                 |
| DM-003 | proof_depth × status 语义      | 补充矩阵文档                     |
| A-003  | goalcli 无插件机制             | registry-based gate 注册         |
| A-004  | harness.yaml 无 schema         | 添加 schema.json                 |
| CI-003 | 无工具缓存                     | 添加二进制缓存                   |
| DC-001 | Docker 版本硬编码              | 从 xlibfacts 读取                |
| DC-002 | 无 ARM64                       | multi-arch build                 |
| DC-003 | 无 CI profile                  | 添加 docker ci profile           |

---

## 13. 推荐行动计划

### 阶段 1：结构优化（3 天）

1. 拆分 `cmd/goalcli/governance.go` 为 3 个文件
2. 拆分 `cmd/goalcli/traceability.go` 为 2 个文件
3. 提取 `emitReport` 和 `requireFiles` 通用函数
4. 添加 `governance_test.go`

### 阶段 2：测试加固（3 天）

1. 为 internal/runtime 和 internal/releasequality 添加测试
2. 改造 selfimproving/traceability 测试使用 fixture
3. 关键脚本添加 bats 测试

### 阶段 3：CI/CD 增强（3 天）

1. 拆分 ci.yml 为多 job 并行
2. 添加 Docker CI workflow
3. 添加 CI on:failure 自动生成 retrospective 模板
4. 添加 `make apply-patches` 命令

### 阶段 4：文档收敛（2 天）

1. 将 SPEC.md 实现细节拆分到 `docs/spec-details/`
2. 推进 kernel 首次采纳
3. 同步 harness gates 列表和标准文档列表
4. 补充 proof_depth × status 矩阵文档

---

## 14. SPEC.md v2.0.0 质量评估

| 维度         | 评分 | 说明                                                |
| ------------ | ---- | --------------------------------------------------- |
| 完整性       | 9/10 | 23 节全覆盖，419 条规则、9 formal ADR + template/history、28 PR 包 |
| 准确性       | 9/10 | gates 数量已统一为 66，文档列表仍待补全（18 vs 27） |
| 可执行性     | 9/10 | 每个 FR 有来源、每个 gate 有 proof_depth            |
| 膨胀度       | 6/10 | ~800 行，含大量实现细节（PR 包清单、命令列表）      |
| 与仓库一致性 | 8/10 | 核心一致，细节有滞后                                |

**总结**：SPEC.md v2.0.0 是高质量的架构规格文档，主要风险是膨胀（实现细节过多）和少量数字不同步。建议将实现清单拆分到子文档，保持 SPEC.md 聚焦于架构决策和验收标准。
