# xlib-standard 追溯矩阵

Status: Aligned-With ANALYSIS.md v3.1.0
Source-Scope: 154 files
Last-Updated: 2026-06-08 05:49 +08:00

## 追溯原则

本表把本地分析快照 `ANALYSIS.md` 的主要条款映射到来源文件。若多个来源冲突，当前 `docs/standard/**` 和根级 `docs/*.md` 优先；`.worktree`、`docs/v0.6.0/**` 和 Downloads 主要用于历史、迁移目标和冲突账本。

## 追溯边界

- 本表是条款级来源矩阵，不是 154 个输入文件的逐规则证明账本。
- 本表证明 `ANALYSIS.md` 的主要条款有来源锚点；不能单独证明 release-ready、remote ruleset/CI enabled、GitHub Release object 或 downstream adoption。
- 来源路径保留本次分析机器上的绝对路径。迁移到其他环境时，必须提供同一 source pack、路径映射或重新生成 `COVERAGE-MANIFEST.md`。
- 当本表、历史稿和当前主规格冲突时，以 `ANALYSIS.md` 的事实边界、`CONFLICT-LEDGER.md` 和 `SNAPSHOT-BOUNDARY.md` 的取舍为准。

## 块级追溯缺口声明（Block-level Gap Disclosure）

> FR 来源锚定 52/52；其中行级 49、file 1（FR-008）、validator-output 2（FR-041, FR-046）。**不得**把“来源 100%”读作“语义验证 100%”。

| 维度 | 当前状态 | 缺口 | 收敛计划 / 时限 |
|------|----------|------|------------------|
| 条款级追溯（章节 → 来源） | ✅ 完整 | — | 维持 |
| FR 来源锚定（FR-NNN → 来源文件 + 证据类型） | ✅ 52/52 | 语义验证不由本表声明 | 维持证据类型分层 |
| FR 行级锚点 | ✅ 49/52 | FR-008 为 file；FR-041 / FR-046 为 validator-output | 非 line 证据不得计入行级覆盖 |
| FR-020（多行 YAML 源） | ✅ line | — | 维持 |
| FR-041 / FR-046（目录复合源） | ✅ validator-output | 目录复合源由 `goalcli harness-runtime-check` / `goalcli pr-pack-check` 校验，不伪装为逐行来源 | 维持 |
| Open Questions / Risks 追溯 | ⚠️ 块级 | OQ-008 / R-011 等本分析内部条目无外部来源（属规格自生） | 标注为 **internal**，无需外部追溯 |
| 远端治理（branch protection / ruleset / Release object） | ✅ **已闭合** | — | 见 `REMOTE-EVIDENCE.md`（2026-06-08 05:15 pinned）；OQ-001 已由 `gh api` 真证据收敛 |

> **TODO 标记规则**：尚未行级化的 FR 来源单元格在“追溯说明”列含 `[行级证据 TODO]` 标记；自动巡检命令：
>
> ```bash
> grep -n "\[行级证据 TODO\]" specs/xlib-standard/TRACEABILITY.md | wc -l
> ```
>
> 该数字进入 `latest.json.trace_coverage_todo_count`，是 NG-33 的输入。

## 核心条款追溯

| 规格条款                                                        | 主要来源                                                                                                                                                                                                                      | 追溯说明                                                                                              |
| --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| 模块身份：标准源、模板、生成器、Harness、Evidence Runtime       | `docs/spec.md`, `docs/standard/xlib-standard.md`, `docs/standard/repository-roles.md`                                                                                                                                         | 三处均定义 `xlib-standard` 不是业务库，而是标准和模板源。                                             |
| 非目标：无 `x.go`、无业务、无生产 secret                        | `docs/standard/module-boundary.md`, `docs/standard/layering.md`, `docs/config.md`, `docs/xgo-integration-boundary.md`                                                                                                         | 边界文档和配置文档共同禁止业务反向依赖和隐式生产 secret。                                             |
| 分层：Standard/L0/L1/L2/L3                                      | `docs/standard/layering.md`, `docs/standard/repository-roles.md`, `docs/downstream-matrix.md`, `docs/l2/00_index.md`                                                                                                          | 标准层到业务层的依赖方向由 layering 约束，L2 文件补充 provider 矩阵。                                 |
| 默认代表下游：`kernel`、`configx`、`redisx`                     | `docs/standard/downstream-compatibility.md`, `docs/generation.md`, `docs/downstream-sync-policy.md`                                                                                                                           | 默认 integration 和 downstream sync 以这三个代表为主。                                                |
| `corekit` 中性目标、`foundationx`/`baselib-template` 历史上下文 | `docs/standard/downstream-compatibility.md`, `docs/downstream-sync-policy.md`, `docs/migration/baselib-template-to-xlib-standard.md`                                                                                          | 这些名称不能替代当前主身份。                                                                          |
| 公共 API                                                        | `docs/api.md`, `docs/errors.md`, `docs/observability.md`, `docs/config.md`                                                                                                                                                    | Config、New、Close、HealthCheck、Error、Metrics 和 Version 的行为由根级 API 文档组成。                |
| ErrorKind                                                       | `docs/errors.md`                                                                                                                                                                                                              | ErrorKind 枚举、包装和脱敏要求来自错误文档。                                                          |
| Health/metrics                                                  | `docs/observability.md`, `docs/testing.md`                                                                                                                                                                                    | 健康状态、JSON 字段和指标名称由观测文档和测试文档支撑。                                               |
| 配置显式传入和脱敏                                              | `docs/config.md`, `docs/standard/security-and-secret-policy.md`                                                                                                                                                               | 配置不得隐式读取生产路径；脱敏输出可进日志和 Evidence。                                               |
| `.config/xlib` 迁移目标冲突                                     | `docs/v0.6.0/*strict-config-root*.md`, `<external-downloads>/xlib-standard-strict-config-root-*.md`, `<external-downloads>/xlib-standard-v1.0.0-config-goal*.md`, `docs/standard/goal-runtime.md` | strict-config-root 是计划和目标；当前标准仍引用 `.agent`、`.xlib`、registry 和 policy 源。            |
| 生成器入口                                                      | `docs/generation.md`, `docs/standard/template-generation-contract.md`, `docs/spec.md`                                                                                                                                         | `scripts/render_template.sh` 是当前标准入口；未来 strict allowlist 作为冲突和迁移目标记录。           |
| 生成排除项和 forbidden path                                     | `docs/generation.md`, `docs/standard/template-generation-contract.md`, `docs/standard/module-boundary.md`                                                                                                                     | 输出必须避免仓库状态、临时产物、业务导入和 secret path。                                              |
| `goalcli` JSON 和退出码                                         | `docs/standard/goalcli-cli-contract.md`                                                                                                                                                                                       | CLI 输出、schema、退出码、`--strict` 和 `--verify` 语义来自该文件。                                   |
| Goal Runtime ledger                                             | `docs/standard/goalcli-runtime.md`, `docs/standard/goal-runtime.md`, `docs/adr/ADR-20260603-001-goalcli-runtime.md`                                                                                                           | `cmd/goalcli` 为唯一 Go runtime entry，ledger 与 evidence pack 分离。                                 |
| Harness gates                                                   | `docs/standard/harness-gates.md`, `docs/release.md`, `docs/standard/release-standard.md`                                                                                                                                      | 门禁列表、release check 和 score 约束来自这些文件。                                                   |
| Truth-state                                                     | `docs/standard/truth-state.md`, `docs/standard/evidence-protocol.md`, `docs/downstream-sync-policy.md`                                                                                                                        | 弱事实禁止升级为强事实。                                                                              |
| Evidence manifest                                               | `docs/standard/evidence-protocol.md`, `docs/supply-chain.md`, `docs/release.md`                                                                                                                                               | Manifest 字段、generated artifact、CI artifact 和 downstream 字段来自 evidence/supply-chain/release。 |
| Downstream adoption proof                                       | `docs/standard/downstream-registry.md`, `docs/downstream-sync-policy.md`, `docs/downstream-matrix.md`, `docs/testing/l2-downstream-adoption.md`                                                                               | Adoption 需要 schema、下游 commit、gate outputs 和 rollback。                                         |
| L2 provider release ladder                                      | `docs/l2/*.md`, `docs/testing/l2-release-gate.md`, `docs/testing/l2-evidence-standard.md`, `docs/testing/l2-compliance-matrix.md`                                                                                             | L2 的 capability、contract、evidence、release profile 和 fail-closed 要求来自 L2 和 testing 子目录。  |
| 测试范围                                                        | `docs/testing.md`, `docs/test-strategy.md`, `docs/testing/l2-*.md`                                                                                                                                                            | 单元、contract、fuzz、golden、release fixture 和 L2 contract pack 测试由这些文档支撑。                |
| Debt governance                                                 | `docs/standard/debt-governance.md`, `docs/reports/rules-deep-analysis-20260605.md`                                                                                                                                            | Debt scanner、score、evidence 和 release 阻断条件来自债务文档。                                       |
| Docker Toolchain Runtime                                        | `docs/standard/docker-toolchain-standard.md`, `docs/self-improving/docker-toolchain.md`, `docs/self-improving/docker-toolchain-structural-report.md`                                                                          | Docker 是工具链 runtime，不是第二套门禁。                                                             |
| Supply chain                                                    | `docs/supply-chain.md`, `docs/standard/security-and-secret-policy.md`, `docs/standard/branch-governance.md`                                                                                                                   | Actions pin、govulncheck、golangci-lint、dependency purpose 和 secret 规则来自这些文件。              |
| Release 语义                                                    | `docs/release.md`, `docs/standard/release-standard.md`, `<external-downloads>/xlib-standard-v1.0.0-delivery-checklist*.md`                                                                                      | Release gate、patch release、GitHub Release object 和 v1.0.0 checklist 都被纳入。                     |
| 历史版本和路线                                                  | `.worktree/v3.0.md`, `.worktree/stable.md`, `.worktree/goal*.md`, `docs/v0.6.0/**`, Downloads v0.4.15/v1.0.0 文件                                                                                                             | 历史文件用于版本轨迹和冲突，不直接覆盖当前标准。                                                      |

## Agent team 结果映射

| 分析通道                    | 重点                                                          | 已纳入章节                                      |
| --------------------------- | ------------------------------------------------------------- | ----------------------------------------------- |
| Core standard               | 模块身份、边界、分层、API、Harness、Evidence                  | `ANALYSIS.md` §1-7；`analysis/template.md` §3；`analysis/runtime.md` §3                  |
| Runtime/config              | `goalcli`、Goal Runtime、config root 冲突、strict config 迁移 | `ANALYSIS.md` §7；`analysis/runtime.md` §3；`CONFLICT-LEDGER.md`       |
| Downstream/testing/evidence | L2、downstream proof、testing、Evidence、truth-state          | `analysis/governance.md` §3-4；`analysis/runtime.md` §3、§6                     |
| Historical/omission audit   | v0.4.15、v0.6.0、v1.0.0、pathguard、remote proof              | `ANALYSIS.md` §8；`analysis/runtime.md` §4；`CONFLICT-LEDGER.md`     |

## 明确未纳入为事实的内容

- 没有把 Downloads 中的未来计划当作已完成实现。
- 没有把本地 Markdown 中的 release 声明当作 GitHub Release object 证明。
- 没有把 downstream registry、sync plan 或 patch-only 文档当作 adoption proof。
- 没有把 Docker 检查当作独立于本地门禁的第二发布判断。
- 没有把当前 dirty workspace 视为可发布状态。

---

## FR 级追溯（自动提取）

> 共 52 条 FR。每行列出 FR 编号、所在子节、ANALYSIS.md 行号、主要来源文件、源行号、证据类型、优先级。
> `证据类型` 取值：`line` / `file` / `validator-output`；只有 `line` 计入行级锚点。
> 自动从 `ANALYSIS.md` 的 `### FR-NNN` 标题和紧随的 `> 来源：... | 优先级：...` 行提取；来源行号通过 grep 上游文件锚词（如 `RULE-CORE-001`、`RULE-HARNESS-003`、`scripts/render_template`、`HealthCheck` 等）反查得出。
> 生成时间 2026-06-08 05:03，上游 pin commit `93753b30`（详见 COVERAGE-MANIFEST）。
> 来源路径相对 `<upstream:xlib-standard>/`（除 `.worktree/*`、`docs/standard/*`、`docs/adr/*` 等），具体 sha 由 COVERAGE-MANIFEST 已绑定。

| FR | 子节 | ANALYSIS.md 行号 | 名称 | 主要来源 | 源行号 | 证据类型 | 优先级 |
|----|------|------:|------|----------|--------|:--------:|:----:|
| `FR-001` | §7.1 | L186 | 定义 419 条 RULE-* 规则，机器化为 registry.yaml | `.worktree/goal-patch.md` | 56, 2445 | line | P0 |
| `FR-002` | §7.1 | L196 | 定义 7 类技术债治理规则 | `.worktree/debt.md` | 304-332 | line | P0 |
| `FR-003` | §7.1 | L206 | 定义 10 条 Git 治理规则并接入执行链 | `.worktree/git.md` | 1, 45, 69, 102, 128, 144, 362-370 | line | P0 |
| `FR-004` | §7.1 | L216 | 定义模块依赖层级模型 | `.worktree/L.md` | 4, 6, 8 | line | P0 |
| `FR-005` | §7.1 | L226 | 定义 8 个仓库治理 REQ | `.worktree/main.md` | 14 | line | P0 |
| `FR-006` | §7.1 | L236 | 定义采纳状态机入口约束 | `.worktree/main.md` | 601, 641, 989 | line | P0 |
| `FR-007` | §7.1 | L246 | 定义 15 条基本真理（同义表见 `analysis/governance.md`） | `.worktree/v3.0.md` | 95, 98 | line | P0 |
| `FR-008` | §7.1 | L256 | 定义 9 个正式 ADR | `docs/adr/ADR-*.md` | 10 个文件存在 | file | P1 |
| `FR-009` | §7.2 | L268 | 公共 API 模板 | `docs/api.md` | 9, 16 | line | P0 |
| `FR-010` | §7.2 | L278 | 9 种 ErrorKind | `docs/errors.md` | 10-13 | line | P0 |
| `FR-011` | §7.2 | L288 | 9 个最小 metrics | `docs/observability.md` | 8, 10, 12 | line | P0 |
| `FR-012` | §7.2 | L300 | HealthCheck JSON schema | `docs/observability.md` | 22, 26, 35 | line | P0 |
| `FR-013` | §7.2 | L310 | 配置显式传入 | `docs/config.md` | 11 | line | P0 |
| `FR-014` | §7.2 | L320 | 配置 Validate 和 Sanitize | `docs/config.md` | 13, 14, 16 | line | P0 |
| `FR-015` | §7.3 | L332 | render_template.sh 渲染 | `docs/generation.md` | 5, 10, 24 | line | P0 |
| `FR-016` | §7.3 | L345 | 渲染范围全覆盖 | `docs/generation.md` | 37 | line | P0 |
| `FR-017` | §7.3 | L355 | Repository Governance Pack | `docs/generation.md` | 19, 29, 35 | line | P0 |
| `FR-018` | §7.3 | L365 | make integration | `docs/generation.md` | 57 | line | P0 |
| `FR-019` | §7.3 | L375 | Docker Toolchain Runtime 模板继承 | `docs/generation.md` | 94, 96 | line | P1 |
| `FR-020` | §7.4 | L387 | 66 个 gate 条目 | `.agent/harness/harness.yaml` | 49（required_gates 段起点）, 282（extended_gates）, 303（final_gates）, 356（goalcli_mva_gates） | line | P0 |
| `FR-021` | §7.4 | L397 | 4 个 Context Profiles | `docs/standard/harness-gates.md` + `docs/standard/conformance-profiles.md` + `.worktree/main.md` | harness-gates.md 54-65, 104-108（Context Runtime v4.0 Profile Baseline + 4 profile wrapper + 3 兼容 alias）; conformance-profiles.md 5-6（standard-source / l0-kernel） | line | P0 |
| `FR-022` | §7.4 | L407 | P0 Gate 失败阻断发布 | `.worktree/goal-patch.md` | 737, 739, 2451 | line | P0 |
| `FR-023` | §7.4 | L417 | Gate 结果归档为 Evidence | `.worktree/goal-patch.md` | 751 | line | P0 |
| `FR-024` | §7.4 | L427 | Release Scorecard | `docs/scorecard.md` | 1, 3, 9 | line | P0 |
| `FR-025` | §7.4 | L437 | Debt Governance Gate | `docs/standard/debt-governance.md` | 1, 5（"Required gates:"） | line | P0 |
| `FR-026` | §7.5 | L449 | Evidence Ledger | `docs/adr/ADR-20260603-001-goalcli-runtime.md` | 9 | line | P0 |
| `FR-027` | §7.5 | L459 | Release Manifest | `docs/release.md` | 38, 104, 106 | line | P0 |
| `FR-028` | §7.5 | L471 | DONE with evidence 格式 | `.worktree/goal-patch.md` | 63, 769, 3359 | line | P0 |
| `FR-029` | §7.5 | L481 | 禁止无证据的 tests pass | `docs/standard/evidence-protocol.md` | 122 | line | P0 |
| `FR-030` | §7.5 | L491 | 禁止 skipped gate 记为 passed | `docs/standard/evidence-protocol.md` | 123 | line | P0 |
| `FR-031` | §7.5 | L501 | 禁止 dirty workspace release | `docs/standard/evidence-protocol.md` | 72, 118, 124 | line | P0 |
| `FR-032` | §7.5 | L511 | 禁止删除失败 Evidence | `docs/standard/evidence-protocol.md` | 125 | line | P0 |
| `FR-033` | §7.6 | L523 | ARCH 类技术债规则 | `.worktree/debt.md` | 304-308 | line | P0 |
| `FR-034` | §7.6 | L533 | DEP 类技术债规则 | `.worktree/debt.md` | 329-332 | line | P0 |
| `FR-035` | §7.6 | L543 | DOMAIN 类技术债规则 | `.worktree/debt.md` | 352-353 | line | P0 |
| `FR-036` | §7.6 | L553 | DOCS 类技术债规则 | `.worktree/debt.md` | 369-373 | line | P0 |
| `FR-037` | §7.6 | L563 | TEST 类技术债规则 | `.worktree/debt.md` | 390-395 | line | P0 |
| `FR-038` | §7.6 | L573 | IMPL 类技术债规则 | `.worktree/debt.md` | 413-419 | line | P0 |
| `FR-039` | §7.6 | L583 | SEC 类技术债规则 | `.worktree/debt.md` | 434-437, 1625-1629, 1951-1954, 2989-2993, 3127, 3513（5 条 SEC.* 规则定义、使用与扫描器约束） | line | P0 |
| `FR-040` | §7.7 | L595 | Goal Kernel（8 个核心对象） | `.worktree/goalcli-v0.1.0-plan.md` | 48, 56 | line | P0 |
| `FR-041` | §7.7 | L605 | Harness Runtime | `.worktree/goal/` | `goalcli_v0_1_0_goal_runtime_complete_structural_plan.md` + `goal_runtime_v3_1_1_structural_refactor_plan_v2_harness_runtime.md`（runtime 结构与重构计划）；逐文件锚由 `goalcli harness-runtime-check` 校验 | validator-output | P0 |
| `FR-042` | §7.7 | L615 | goalcli 唯一执行面 | `docs/adr/ADR-20260603-001-goalcli-runtime.md` | 7（"唯一代码入口"） | line | P0 |
| `FR-043` | §7.7 | L625 | 6 个 MVA Gate | `.worktree/goalcli-v0.1.0-plan.md` | 60（§4 MVA gate） | line | P0 |
| `FR-044` | §7.7 | L635 | 4-Plane 架构 | `.worktree/v3.0.md` | 151, 159, 166, 173, 187（Spec/Execution/Proof/Automation Plane） | line | P0 |
| `FR-045` | §7.7 | L645 | 10 个 REQ-PROOF | `.worktree/v3.0.md` | 247-249 | line | P0 |
| `FR-046` | §7.7 | L655 | 28 个 PR 执行包 | `.worktree/goal/` | 目录包含 28 个 unique `xlib_standard_pr<N>_*_execution_pack.md`（PR-1..PR-28，共 30 个文件含 2 个 `(1)` 副本；如 PR-25 见 `xlib_standard_pr25_..._execution_pack.md` L1/L14/L50/L54/L134）；逐文件锚由 `goalcli pr-pack-check` 校验 | validator-output | P1 |
| `FR-047` | §7.8 | L676 | 5 层执行链 | `.worktree/main.md` | 14 | line | P0 |
| `FR-048` | §7.8 | L688 | 禁止 main 开发 | `.worktree/main.md` | 18, 27, 32 | line | P0 |
| `FR-049` | §7.8 | L698 | 必须使用 git worktree | `.worktree/main.md` | 18, 47, 183 | line | P0 |
| `FR-050` | §7.8 | L708 | 采纳状态机（8 状态） | `.worktree/main.md` | 601, 641, 989, 1007, 1201, 1211, 1336, 1646, 1652, 2064 | line | P0 |
| `FR-051` | §7.8 | L720 | 6 个禁止状态转换 | `.worktree/main.md` | 2138, 2396, 2624, 2929 | line | P0 |
| `FR-052` | §7.8 | L732 | 下游同步治理（20 PR） | `.worktree/goal.md` | 1, 3, 145, 154-155 | line | P1 |

### 优先级统计

- P0: 48
- P1: 4

---

## FR → AC → TC 闭合矩阵

> 来源：AC 编号取自 ANALYSIS.md §9（AC-T01\~T04 / AC-I01\~I04 / AC-G01\~G03 / AC-R01\~R06），TC 编号取自 `analysis/runtime.md`，命名空间为 `xlib-TC-001\~xlib-TC-017`。
> 空单元格表示该 FR 暂无对应 AC/TC 覆盖，属已知缺口（见下方覆盖统计）。

| FR | 名称 | AC | TC |
|----|------|----|----|
| FR-001 | 419 条 RULE-\* 规则 | AC-T02 | — |
| FR-002 | 7 类技术债治理规则 | AC-T02, AC-I04 | — |
| FR-003 | 10 条 Git 治理规则 | AC-T02 | — |
| FR-004 | 模块依赖层级模型 | AC-I04 | — |
| FR-005 | 8 个仓库治理 REQ | AC-T02 | — |
| FR-006 | 采纳状态机入口约束 | AC-I01 | xlib-TC-013 |
| FR-007 | 15 条基本真理 | AC-T02 | — |
| FR-008 | 9 个正式 ADR | AC-T03 | — |
| FR-009 | 公共 API 模板 | AC-T02 | xlib-TC-001 |
| FR-010 | 9 种 ErrorKind | AC-T02 | xlib-TC-014 |
| FR-011 | 9 个最小 metrics | AC-T02 | xlib-TC-015 |
| FR-012 | HealthCheck JSON schema | AC-T02 | xlib-TC-005, xlib-TC-010 |
| FR-013 | 配置显式传入 | AC-T02 | xlib-TC-001, xlib-TC-009 |
| FR-014 | 配置 Validate 和 Sanitize | AC-T02 | xlib-TC-002, xlib-TC-006, xlib-TC-007, xlib-TC-011, xlib-TC-017 |
| FR-015 | render\_template.sh 渲染 | AC-T02 | — |
| FR-016 | 渲染范围全覆盖 | AC-T02 | — |
| FR-017 | Repository Governance Pack | AC-T02 | — |
| FR-018 | make integration | AC-I02 | — |
| FR-019 | Docker Toolchain Runtime | AC-T02 | — |
| FR-020 | 66 个 gate 条目 | AC-I02 | — |
| FR-021 | 4 个 Context Profiles | AC-I02 | — |
| FR-022 | P0 Gate 失败阻断发布 | AC-R02 | — |
| FR-023 | Gate 结果归档为 Evidence | AC-T02, AC-R01 | — |
| FR-024 | Release Scorecard | AC-R03 | — |
| FR-025 | Debt Governance Gate | AC-I04 | — |
| FR-026 | Evidence Ledger | AC-R01 | — |
| FR-027 | Release Manifest | AC-R01 | xlib-TC-012 |
| FR-028 | DONE with evidence 格式 | AC-T02 | — |
| FR-029 | 禁止无证据的 tests pass | AC-T02 | — |
| FR-030 | 禁止 skipped gate 记为 passed | AC-R06 | — |
| FR-031 | 禁止 dirty workspace release | AC-R04 | — |
| FR-032 | 禁止删除失败 Evidence | AC-R06 | — |
| FR-033 | ARCH 类技术债规则 | AC-I04 | — |
| FR-034 | DEP 类技术债规则 | AC-I04 | — |
| FR-035 | DOMAIN 类技术债规则 | AC-I04 | — |
| FR-036 | DOCS 类技术债规则 | AC-I04 | — |
| FR-037 | TEST 类技术债规则 | AC-I04 | — |
| FR-038 | IMPL 类技术债规则 | AC-I04 | — |
| FR-039 | SEC 类技术债规则 | AC-I04 | — |
| FR-040 | Goal Kernel（8 核心对象） | AC-G01 | — |
| FR-041 | Harness Runtime | AC-G02 | — |
| FR-042 | goalcli 唯一执行面 | AC-I02 | — |
| FR-043 | 6 个 MVA Gate | AC-G02 | — |
| FR-044 | 4-Plane 架构 | AC-G01 | — |
| FR-045 | 10 个 REQ-PROOF | AC-G02 | — |
| FR-046 | 28 个 PR 执行包 | AC-G01 | — |
| FR-047 | 5 层执行链 | AC-I02 | — |
| FR-048 | 禁止 main 开发 | AC-I02 | — |
| FR-049 | 必须使用 git worktree | AC-I02 | — |
| FR-050 | 采纳状态机（8 状态） | AC-I01 | xlib-TC-013 |
| FR-051 | 6 个禁止状态转换 | AC-I01 | xlib-TC-013 |
| FR-052 | 下游同步治理（20 PR） | AC-G01 | — |

### 覆盖统计

| 维度 | 锚定/覆盖 | 总数 | 口径 |
|------|------|------|------|
| FR → AC | 52 | 52 | 52/52 |
| FR → TC | 10 | 52 | 19% |
| xlib-TC → FR（反向） | 17 | 17 | 17/17 |

> **缺口说明**：FR→xlib-TC 覆盖率 19%（10/52）仅反映 `analysis/runtime.md` 显式列出的 17 个 `xlib-TC`。
> 其余 42 个 FR 的 TC 由 harness.yaml 66 个 gate 输出 + Evidence pack 间接证明（见 analysis/runtime.md §3.1）。
> 下游模块 SPEC §17 应沿用 xlib-TC-001\~xlib-TC-017 模板并扩展覆盖。
