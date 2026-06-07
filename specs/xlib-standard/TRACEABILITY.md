# xlib-standard 追溯矩阵

Status: consolidated
Source-Scope: 154 files

## 追溯原则

本表把当前主规格 `SPEC.md` 的主要条款映射到来源文件。若多个来源冲突，当前 `docs/standard/**` 和根级 `docs/*.md` 优先；`.worktree`、`docs/v0.6.0/**` 和 Downloads 主要用于历史、迁移目标和冲突账本。

## 追溯边界

- 本表是条款级来源矩阵，不是 154 个输入文件的逐规则证明账本。
- 本表证明 `SPEC.md` 的主要条款有来源锚点；不能单独证明 release-ready、remote ruleset/CI enabled、GitHub Release object 或 downstream adoption。
- 来源路径保留本次分析机器上的绝对路径。迁移到其他环境时，必须提供同一 source pack、路径映射或重新生成 `COVERAGE-MANIFEST.md`。
- 当本表、历史稿和当前主规格冲突时，以 `SPEC.md` 的事实边界和 `CONFLICT-LEDGER.md` 的取舍为准。

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
| `.config/xlib` 迁移目标冲突                                     | `docs/v0.6.0/*strict-config-root*.md`, `/home/zone/Downloads/xlib-standard/xlib-standard-strict-config-root-*.md`, `/home/zone/Downloads/xlib-standard/xlib-standard-v1.0.0-config-goal*.md`, `docs/standard/goal-runtime.md` | strict-config-root 是计划和目标；当前标准仍引用 `.agent`、`.xlib`、registry 和 policy 源。            |
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
| Release 语义                                                    | `docs/release.md`, `docs/standard/release-standard.md`, `/home/zone/Downloads/xlib-standard/xlib-standard-v1.0.0-delivery-checklist*.md`                                                                                      | Release gate、patch release、GitHub Release object 和 v1.0.0 checklist 都被纳入。                     |
| 历史版本和路线                                                  | `.worktree/v3.0.md`, `.worktree/stable.md`, `.worktree/goal*.md`, `docs/v0.6.0/**`, Downloads v0.4.15/v1.0.0 文件                                                                                                             | 历史文件用于版本轨迹和冲突，不直接覆盖当前标准。                                                      |

## Agent team 结果映射

| 分析通道                    | 重点                                                          | 已纳入章节                                      |
| --------------------------- | ------------------------------------------------------------- | ----------------------------------------------- |
| Core standard               | 模块身份、边界、分层、API、Harness、Evidence                  | `SPEC.md` §2、§4-§6、§8-§10、§16                |
| Runtime/config              | `goalcli`、Goal Runtime、config root 冲突、strict config 迁移 | `SPEC.md` §6-§8、§17；`CONFLICT-LEDGER.md`      |
| Downstream/testing/evidence | L2、downstream proof、testing、Evidence、truth-state          | `SPEC.md` §9、§13、§15、§19                     |
| Historical/omission audit   | v0.4.15、v0.6.0、v1.0.0、pathguard、remote proof              | `SPEC.md` §14、§17-§18；`CONFLICT-LEDGER.md`    |

## 明确未纳入为事实的内容

- 没有把 Downloads 中的未来计划当作已完成实现。
- 没有把本地 Markdown 中的 release 声明当作 GitHub Release object 证明。
- 没有把 downstream registry、sync plan 或 patch-only 文档当作 adoption proof。
- 没有把 Docker 检查当作独立于本地门禁的第二发布判断。
- 没有把当前 dirty workspace 视为可发布状态。
