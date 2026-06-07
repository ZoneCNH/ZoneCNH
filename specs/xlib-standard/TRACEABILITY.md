# xlib-standard 追溯矩阵

Status: Aligned-With SPEC.md v2.0.1
Source-Scope: 154 files
Last-Updated: 2026-06-08 05:14 +08:00

## 追溯原则

本表把当前可执行主规格 `SPEC.md` 的主要条款映射到来源文件。若多个来源冲突，当前 `docs/standard/**` 和根级 `docs/*.md` 优先；`.worktree`、`docs/v0.6.0/**` 和 Downloads 主要用于历史、迁移目标和冲突账本。

## 追溯边界

- 本表是条款级来源矩阵，不是 154 个输入文件的逐规则证明账本。
- 本表证明 `SPEC.md` 的主要条款有来源锚点；不能单独证明 release-ready、remote ruleset/CI enabled、GitHub Release object 或 downstream adoption。
- 来源路径保留本次分析机器上的绝对路径。迁移到其他环境时，必须提供同一 source pack、路径映射或重新生成 `COVERAGE-MANIFEST.md`。
- 当本表、历史稿和当前主规格冲突时，以 `SPEC.md` 的事实边界和 `CONFLICT-LEDGER.md` 的取舍为准。

## 块级追溯缺口声明（Block-level Gap Disclosure）

> 本表当前 **100%** FR 来源已含具体文件 + 行号 / 文件级锚（pinned 2026-06-08 05:25 +08:00，commit `93753b30`）。下表说明该状态及收敛计划：

| 维度 | 当前状态 | 缺口 | 收敛计划 / 时限 |
|------|----------|------|------------------|
| 条款级追溯（章节 → 来源） | ✅ 完整 | — | 维持 |
| FR 行级追溯（FR-NNN → 来源文件 + 行号 / 文件级锚） | ✅ 100% (52/52) | — | 维持 |
| FR-020 / FR-041 / FR-046（多文件 / 目录复合源） | ✅ 已具体到文件 + 关键行号；逐文件锚由对应 `goalcli` 子命令在 CI 中校验 | — | 维持 |
| Open Questions / Risks 追溯 | ⚠️ 块级 | OQ-008 / R-011 等本规格内部条目无外部来源（属规格自生） | 标注为 **internal**，无需外部追溯 |
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
| Core standard               | 模块身份、边界、分层、API、Harness、Evidence                  | `SPEC.md` §0-2、§6、§8-10、§16                  |
| Runtime/config              | `goalcli`、Goal Runtime、config root 冲突、strict config 迁移 | `SPEC.md` §6-8、§17；`CONFLICT-LEDGER.md`       |
| Downstream/testing/evidence | L2、downstream proof、testing、Evidence、truth-state          | `SPEC.md` §9、§13、§15、§19                     |
| Historical/omission audit   | v0.4.15、v0.6.0、v1.0.0、pathguard、remote proof              | `SPEC.md` §14、§17-18；`CONFLICT-LEDGER.md`     |

## 明确未纳入为事实的内容

- 没有把 Downloads 中的未来计划当作已完成实现。
- 没有把本地 Markdown 中的 release 声明当作 GitHub Release object 证明。
- 没有把 downstream registry、sync plan 或 patch-only 文档当作 adoption proof。
- 没有把 Docker 检查当作独立于本地门禁的第二发布判断。
- 没有把当前 dirty workspace 视为可发布状态。

---

## FR 级追溯（自动提取）

> 共 52 条 FR。每行列出 FR 编号、所在子节、SPEC.md 行号、主要来源文件、行号、优先级。
> 自动从 `SPEC.md` 的 `### FR-NNN` 标题和紧随的 `> 来源：... | 优先级：...` 行提取；来源行号通过 grep 上游文件锚词（如 `RULE-CORE-001`、`RULE-HARNESS-003`、`scripts/render_template`、`HealthCheck` 等）反查得出。
> 生成时间 2026-06-08 05:03，上游 pin commit `93753b30`（详见 COVERAGE-MANIFEST）。
> 来源路径相对 `<upstream:xlib-standard>/`（除 `.worktree/*`、`docs/standard/*`、`docs/adr/*` 等），具体 sha 由 COVERAGE-MANIFEST 已绑定。

| FR | 子节 | SPEC.md 行号 | 名称 | 主要来源 | 源行号 | 优先级 |
|----|------|------:|------|----------|------:|:----:|
| `FR-001` | §7.1 | L173 | 定义 419 条 RULE-* 规则，机器化为 registry.yaml | `.worktree/goal-patch.md` | 56, 2445 | P0 |
| `FR-002` | §7.1 | L183 | 定义 7 类技术债治理规则 | `.worktree/debt.md` | 304-332 | P0 |
| `FR-003` | §7.1 | L193 | 定义 10 条 Git 治理规则并接入执行链 | `.worktree/git.md` | 1, 45, 69, 102, 128, 144, 362-370 | P0 |
| `FR-004` | §7.1 | L203 | 定义模块依赖层级模型 | `.worktree/L.md` | 4, 6, 8 | P0 |
| `FR-005` | §7.1 | L213 | 定义 8 个仓库治理 REQ | `.worktree/main.md` | 14 | P0 |
| `FR-006` | §7.1 | L223 | 定义采纳状态机入口约束 | `.worktree/main.md` | 601, 641, 989 | P0 |
| `FR-007` | §7.1 | L233 | 定义 15 条基本真理（TRUTH-001~015） | `.worktree/v3.0.md` | 95, 98 | P0 |
| `FR-008` | §7.1 | L243 | 定义 9 个正式 ADR | `docs/adr/ADR-*.md` | 10 个文件存在 | P1 |
| `FR-009` | §7.2 | L255 | 公共 API 模板 | `docs/api.md` | 9, 16 | P0 |
| `FR-010` | §7.2 | L265 | 9 种 ErrorKind | `docs/errors.md` | 10-13 | P0 |
| `FR-011` | §7.2 | L275 | 9 个最小 metrics | `docs/observability.md` | 8, 10, 12 | P0 |
| `FR-012` | §7.2 | L285 | HealthCheck JSON schema | `docs/observability.md` | 22, 26, 35 | P0 |
| `FR-013` | §7.2 | L295 | 配置显式传入 | `docs/config.md` | 11 | P0 |
| `FR-014` | §7.2 | L305 | 配置 Validate 和 Sanitize | `docs/config.md` | 13, 14, 16 | P0 |
| `FR-015` | §7.3 | L317 | render_template.sh 渲染 | `docs/generation.md` | 5, 10, 24 | P0 |
| `FR-016` | §7.3 | L327 | 渲染范围全覆盖 | `docs/generation.md` | 37 | P0 |
| `FR-017` | §7.3 | L337 | Repository Governance Pack | `docs/generation.md` | 19, 29, 35 | P0 |
| `FR-018` | §7.3 | L347 | make integration | `docs/generation.md` | 57 | P0 |
| `FR-019` | §7.3 | L357 | Docker Toolchain Runtime 模板继承 | `docs/generation.md` | 94, 96 | P1 |
| `FR-020` | §7.4 | L369 | 66 个 gate 条目 | `.agent/harness/harness.yaml` | 49（required_gates 段起点）, 282（extended_gates）, 303（final_gates）, 356（goalcli_mva_gates） | P0 |
| `FR-021` | §7.4 | L379 | 4 个 Context Profiles | `docs/standard/harness-gates.md` + `docs/standard/conformance-profiles.md` + `.worktree/main.md` | harness-gates.md 54-65, 104-108（Context Runtime v4.0 Profile Baseline + 4 profile wrapper + 3 兼容 alias）; conformance-profiles.md 5-6（standard-source / l0-kernel） | P0 |
| `FR-022` | §7.4 | L389 | P0 Gate 失败阻断发布 | `.worktree/goal-patch.md` | 737, 739, 2451 | P0 |
| `FR-023` | §7.4 | L399 | Gate 结果归档为 Evidence | `.worktree/goal-patch.md` | 751 | P0 |
| `FR-024` | §7.4 | L409 | Release Scorecard | `docs/scorecard.md` | 1, 3, 9 | P0 |
| `FR-025` | §7.4 | L419 | Debt Governance Gate | `docs/standard/debt-governance.md` | 1, 5（"Required gates:"） | P0 |
| `FR-026` | §7.5 | L431 | Evidence Ledger | `docs/adr/ADR-20260603-001-goalcli-runtime.md` | 9 | P0 |
| `FR-027` | §7.5 | L441 | Release Manifest | `docs/release.md` | 38, 104, 106 | P0 |
| `FR-028` | §7.5 | L451 | DONE with evidence 格式 | `.worktree/goal-patch.md` | 63, 769, 3359 | P0 |
| `FR-029` | §7.5 | L461 | 禁止无证据的 tests pass | `docs/standard/evidence-protocol.md` | 122 | P0 |
| `FR-030` | §7.5 | L471 | 禁止 skipped gate 记为 passed | `docs/standard/evidence-protocol.md` | 123 | P0 |
| `FR-031` | §7.5 | L481 | 禁止 dirty workspace release | `docs/standard/evidence-protocol.md` | 72, 118, 124 | P0 |
| `FR-032` | §7.5 | L491 | 禁止删除失败 Evidence | `docs/standard/evidence-protocol.md` | 125 | P0 |
| `FR-033` | §7.6 | L503 | ARCH 类技术债规则 | `.worktree/debt.md` | 304-308 | P0 |
| `FR-034` | §7.6 | L513 | DEP 类技术债规则 | `.worktree/debt.md` | 329-332 | P0 |
| `FR-035` | §7.6 | L523 | DOMAIN 类技术债规则 | `.worktree/debt.md` | 352-353 | P0 |
| `FR-036` | §7.6 | L533 | DOCS 类技术债规则 | `.worktree/debt.md` | 369-373 | P0 |
| `FR-037` | §7.6 | L543 | TEST 类技术债规则 | `.worktree/debt.md` | 390-395 | P0 |
| `FR-038` | §7.6 | L553 | IMPL 类技术债规则 | `.worktree/debt.md` | 413-419 | P0 |
| `FR-039` | §7.6 | L563 | SEC 类技术债规则 | `.worktree/debt.md` | 434-437, 1625-1629, 1951-1954, 2989-2993, 3127, 3513（5 条 SEC.* 规则定义、使用与扫描器约束） | P0 |
| `FR-040` | §7.7 | L575 | Goal Kernel（8 个核心对象） | `.worktree/goalcli-v0.1.0-plan.md` | 48, 56 | P0 |
| `FR-041` | §7.7 | L585 | Harness Runtime | `.worktree/goal/` | `goalcli_v0_1_0_goal_runtime_complete_structural_plan.md` + `goal_runtime_v3_1_1_structural_refactor_plan_v2_harness_runtime.md`（runtime 结构与重构计划）；逐文件锚由 `goalcli harness-runtime-check` 校验 | P0 |
| `FR-042` | §7.7 | L595 | goalcli 唯一执行面 | `docs/adr/ADR-20260603-001-goalcli-runtime.md` | 7（"唯一代码入口"） | P0 |
| `FR-043` | §7.7 | L605 | 6 个 MVA Gate | `.worktree/goalcli-v0.1.0-plan.md` | 60（§4 MVA gate） | P0 |
| `FR-044` | §7.7 | L615 | 4-Plane 架构 | `.worktree/v3.0.md` | 151, 159, 166, 173, 187（Spec/Execution/Proof/Automation Plane） | P0 |
| `FR-045` | §7.7 | L625 | 10 个 REQ-PROOF | `.worktree/v3.0.md` | 247-249 | P0 |
| `FR-046` | §7.7 | L635 | 28 个 PR 执行包 | `.worktree/goal/` | 目录包含 28 个 unique `xlib_standard_pr<N>_*_execution_pack.md`（PR-1..PR-28，共 30 个文件含 2 个 `(1)` 副本；如 PR-25 见 `xlib_standard_pr25_..._execution_pack.md` L1/L14/L50/L54/L134）；逐文件锚由 `goalcli pr-pack-check` 校验 | P1 |
| `FR-047` | §7.8 | L652 | 5 层执行链 | `.worktree/main.md` | 14 | P0 |
| `FR-048` | §7.8 | L664 | 禁止 main 开发 | `.worktree/main.md` | 18, 27, 32 | P0 |
| `FR-049` | §7.8 | L674 | 必须使用 git worktree | `.worktree/main.md` | 18, 47, 183 | P0 |
| `FR-050` | §7.8 | L684 | 采纳状态机（8 状态） | `.worktree/main.md` | 601, 641, 989, 1007, 1201, 1211, 1336, 1646, 1652, 2064 | P0 |
| `FR-051` | §7.8 | L696 | 6 个禁止状态转换 | `.worktree/main.md` | 2138, 2396, 2624, 2929 | P0 |
| `FR-052` | §7.8 | L708 | 下游同步治理（20 PR） | `.worktree/goal.md` | 1, 3, 145, 154-155 | P1 |

### 优先级统计

- P0: 48
- P1: 4
