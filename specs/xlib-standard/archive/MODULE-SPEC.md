# xlib-standard 模块规格（已归档）

Status: **archived**（2026-06-08 归档；非当前权威）
Spec-Version: 2026-06-07.agent-team
Source-Scope: `/home/xlib-standard/.worktree/*.md`, `/home/xlib-standard/docs/**`, `/home/zone/Downloads/xlib-standard/**`
Input-Files: 154
Coverage-Method: agent-team semantic synthesis; 1000-pass check verifies input file-set stability only

> **归档说明**：本文件已于 2026-06-08 移入 `archive/`，独有内容已合并入 `../SPEC.md`。
> 不得作为当前规格、追溯、冲突取舍或门禁事实引用。当前权威以 `../SPEC.md` 为准。
> 仅供溯源比对；任何引用都应同步指向 `../SPEC.md` 对应章节。

## 1. 模块身份

`xlib-standard` 是基础库体系的唯一标准源，不是业务库、不是生产运行时，也不是下游模块源码仓库。

它承担六个职责：

| 职责 | 说明 |
| --- | --- |
| Standard Source | 维护分层、边界、API、证据、发布和安全规则。 |
| Go Reference Template | 提供可编译的 Go 模板，作为下游基础库的参考形状。 |
| Generator | 通过受控入口渲染 `kernel`、`configx`、`redisx` 等下游库骨架。 |
| Harness | 提供本地、可机器验证的质量门禁和发布门禁。 |
| Evidence Runtime | 生成、校验和追踪完成证据、发布证据、目标证据。 |
| Debt Governance Runtime | 扫描并阻断架构、测试、依赖、安全和实现债务。 |

Docker Toolchain Runtime 只是可复现工具链环境，不是第二套发布门禁，也不替代本地 `GOWORK=off` 门禁。

## 2. 权威来源与事实层级

规格按事实强度分层：

| 层级 | 来源 | 用法 |
| --- | --- | --- |
| Current Standard | `docs/standard/**`、根级 `docs/*.md` | 当前可执行规范和门禁事实。 |
| Domain Supplement | `docs/testing/**`、`docs/l2/**`、`docs/evidence/**` | 下游、L2、测试和证据补充。 |
| Historical Plan | `.worktree/*.md`、`docs/v0.6.0/**`、Downloads | 迁移目标、历史审查、未落地设计和冲突证据。 |
| Runtime Proof | release/evidence、ledger、CI artifact、remote ruleset proof | 只有真实产物可证明执行状态或远端状态。 |

禁止把弱事实升级为强事实：

- `registered` 不等于 `adopted`。
- `baseline_scanned` 不等于 `implemented`。
- `dry_run_ready` 不等于 `executed`。
- `artifact_exists` 不等于 `usable`。
- `CHECK_STATUS=passed` 不等于 release-ready evidence。
- downstream sync plan 不等于 downstream adoption proof。

### 当前事实边界

本目录只能证明本地输入文件已被整理成规格包；不能单独证明远端、发布或下游仓库的当前状态。

| 事项 | 本目录当前结论 | 升级为 passed/adopted/release-ready 所需证明 |
| --- | --- | --- |
| 输入覆盖 | 154 个本地绝对路径输入文件被纳入清单和追溯。 | 新增或删除输入文件后同步更新 `COVERAGE-MANIFEST.md`、`TRACEABILITY.md` 和本规格；跨机器复现还需要同一 source pack、路径映射或重新生成覆盖清单。 |
| 语义整理 | agent team 分片合成并由主规格收敛。 | 具体条款仍以来源追溯、冲突账本和后续实现验证为准。 |
| 1000-pass 检查 | 只证明输入文件集合和清单稳定。 | 不得解释为同一语义经过 1000 次独立人工审查。 |
| Release-ready | 仅定义 release-ready 条件和 fail-closed 规则。 | release-final、preflight、manifest、score、evidence check、clean workspace 和 GitHub Release proof。 |
| 远端治理 | 仅定义 branch protection、ruleset、required checks 和 workflow 权限要求。 | GitHub API、ruleset export、required checks、CI artifact 或仓库设置证据。 |
| 下游采用 | 仅定义 adoption proof 条件。 | 下游仓库 commit、gate output、proof schema、rollback plan 和下游 CI 证据。 |
| 仓库交付 | 仅说明规格包文件内容。 | `git status`、commit、tag 或 release artifact 证明其已进入版本控制或发布边界。 |

## 3. 分层模型

| 层级 | 模块 | 允许职责 | 禁止项 |
| --- | --- | --- | --- |
| Standard/Runtime | `xlib-standard` | 标准、模板、生成器、Harness、Evidence、Debt、Goal Runtime | 真实 L1/L2 运行时、业务模型、`x.go` 依赖、生产凭证。 |
| L0 | `kernel` | 无业务基础原语、稳定契约、错误和生命周期基元 | profile runtime、业务仓库依赖、生产密钥路径。 |
| L1 | `configx`、`observex`、`testkitx` | 配置、观测、测试辅助和标准契约执行 | 应用编排、业务语义、生产端点。 |
| L2 | `postgresx`、`redisx`、`kafkax`、`natsx`、`taosx`、`ossx`、`clickhousex` | Provider-neutral adapter、契约包、能力声明、证据包 | 业务 schema、私有仓库约束、不可替换厂商假设。 |
| L3/Business | `x.go`、`market-data`、`macro-data`、engines | 组合基础库和承载业务 | 反向定义基础库标准。 |

依赖方向只能从上层消费下层或消费标准产物：

```text
x.go / business
  -> L2 provider libraries
  -> L1 support libraries
  -> L0 kernel
  -> xlib-standard contracts/template/gates
```

`xlib-standard` 不依赖 `x.go`、业务仓库、已生成运行时或 profile runtime。

## 4. 边界和非目标

`xlib-standard` 必须包含：

- 标准文档、分层文档、模块边界、仓库角色、DoD、Harness 门禁、Evidence 协议、Release 标准。
- Go 模板、公共 API 参考、契约、示例、生成脚本、Makefile、CI 工作流和 schema。
- `cmd/goalcli` 机器门禁入口及其 JSON 报告契约。
- 本地证据、发布证据、债务证据、标准影响和下游同步计划的生成规则。
- 下游治理包和可被渲染的标准材料。

`xlib-standard` 禁止包含：

- L1/L2 真实 provider runtime、真实连接池、真实队列/数据库客户端。
- `x.go` 业务模型、业务仓库导入、私有策略、交易或生产配置。
- 隐式读取 `/home/k8s/secrets/env/*` 或其他生产 secret 路径。
- 隐藏全局 client、不可关闭后台资源、不可审计副作用。
- 把 `baselib-template`、`foundationx`、`corekit` 当作主身份。
- 把 release manifest/latest、debt latest、临时 evidence latest 当作应提交源文件。

## 5. 公共 API 规格

参考模板和生成库必须暴露稳定、最小、可测试的 API 面：

| API | 要求 |
| --- | --- |
| `Config` | 调用方显式传入；字段可校验、可脱敏、可映射到 config schema。 |
| `Config.Validate` | 对名称、超时、端点、必需字段执行确定性校验；错误归类为标准 ErrorKind。 |
| `Config.Sanitize` | 返回可写入日志和 Evidence 的脱敏副本；不得泄露 token、secret、账户或私有端点。 |
| `New(ctx, cfg)` | 拒绝 nil、canceled、expired context；不得隐式读取生产环境。 |
| `Close` | 幂等；多次调用安全；关闭后健康状态必须反映 closed/unhealthy。 |
| `HealthCheck(ctx)` | 返回稳定 JSON shape；nil/canceled context 或未初始化状态为 unhealthy；短 deadline 可 degraded。 |
| `Error` / `NewError` / `WrapError` | 保留 `Kind` 和 cause；消费者按 kind 分支，不按字符串分支。 |
| `Metrics` | 暴露标准指标名称和状态标签，不泄露业务数据。 |
| `Version` | 可用于 Evidence 和 release manifest 的版本事实。 |

标准 ErrorKind：

| Kind | 语义 |
| --- | --- |
| `config` | 配置解析、缺失或格式错误。 |
| `validation` | 显式校验失败。 |
| `connection` | 外部连接创建或握手失败。 |
| `unavailable` | 依赖不可用或服务状态不可用。 |
| `timeout` | deadline、timeout 或 context 超时。 |
| `auth` | 认证、鉴权或凭证错误。 |
| `conflict` | 状态冲突、重复或并发冲突。 |
| `rate_limit` | 配额或限流。 |
| `internal` | 未分类内部错误。 |

## 6. 配置与 Secret

配置规则：

- 配置必须由调用方显式传入，不能隐式读取生产 secret 目录。
- `Validate` 处理真实性和边界，`Sanitize` 处理日志和 Evidence 安全。
- schema 字段、默认值、错误 kind 与文档必须一致。
- 日志、Evidence、manifest、test fixture 只能使用脱敏配置。

配置根冲突的合并取舍：

- 当前标准和运行时仍引用 `.agent/**`、`.xlib/**`、`.agent/registries/**`、`.agent/policies/**` 等治理源。
- Downloads 和 v0.6.0 strict-config-root 计划提出未来 canonical root 为 `.config/xlib`，并禁止 `.agent`/`.xlib` 作为事实源。
- 本规格把 `.config/xlib` 定义为迁移目标，而不是当前已完成事实。
- 在迁移完成前，门禁必须 fail closed：不能同时从多个根拼接事实并声称一致；必须报告当前使用的 root、兼容读路径和迁移缺口。
- 删除或停用 `.agent/**`、`.xlib/**` 前，必须有双读迁移计划、兼容测试、Evidence 和回滚方案。

## 7. 生成器规格

当前标准入口是：

```bash
scripts/render_template.sh --module <module> --name <name> --package <package> --out <path>
```

当前可执行 CLI 契约以 `SPEC.md` FR-015 为准；本历史副本不得成为竞争性的生成器接口定义。

要求：

- 输出目录不得是 `xlib-standard` 根，也不得落在本仓库内部。
- 输出目录必须不存在或为空。
- 必须替换 module/name/package/import path、README、docs、contracts、examples、scripts、manifest、Makefile、CI 中的模板 token。
- 必须去除旧身份 token 和不可提交的生成态 latest 文件。
- 必须排除 `.git`、`.omc`、`.omx`、`.worktree`、`.agent/inbox`、临时缓存、历史生成产物、release/debt latest。
- 生成库必须通过 `GOWORK=off go test ./...` 和标准门禁。
- 生成库不得引入 `x.go`、业务导入、生产 secret 路径或 provider 真实凭证。

治理包渲染：

- 下游使用 `--enable-governance` 时，必须写入标准版本、标准 commit、layer、lock 文件和治理材料。
- `adoption-check` 只在下游仓库证明治理包被采用；在标准仓库只生成和校验可渲染材料。
- 当前复制模板与 strict allowlist 计划存在冲突；最终方向是 allowlist materialization，并通过 pathguard 防止 symlink、大小写混淆、路径穿越、go:embed、fixture、Docker context、Make/YAML/Shell/Go 引用泄漏。

默认代表下游：

- `kernel`：默认集成 smoke 和 L0 代表。
- `configx`：L1 代表。
- `redisx`：L2 代表。
- `corekit`：中性组织路径 smoke/registry 目标，不是默认 `make integration` 下游。
- `foundationx`、`baselib-template`：迁移上下文和历史兼容，不是当前主身份。

## 8. `goalcli` 运行时规格

`cmd/goalcli` 是唯一 Go runtime execution face。Makefile 可以包装它，脚本只能作为兼容或 delegated helper。

通用 CLI 契约：

- 除明确 delegated script 外，所有命令输出 JSON。
- JSON 必须包含 `command`、`status`，并可包含 `details`、`gaps`。
- 报告 schema 使用 `contracts/goalcli-report.schema.json`。
- 所有命令本地、非破坏、默认 dry-run；不得读取真实 secret、不得访问生产系统、不得修改下游仓库。
- `--verify` 和 `--strict` 必须阻断 planned/gap/unknown。

退出码：

| 状态 | Exit Code |
| --- | --- |
| `passed` | 0 |
| `failed`、`planned`、`gap` | 1 |
| `unknown`、illegal invocation、schema violation | 2 |

Goal Runtime：

- `.agent/evidence/ledger.jsonl` 是目标执行源 ledger。
- `release/evidence/goalcli/**` 是生成证据包，不是源 ledger。
- `GOAL_ID` 必须绑定目标执行。
- G12-G16 为阻断型目标门禁。
- 只有同一 `GOAL_ID` 的 plan、execute、verify、evidence、review、release 记录完整 reconciled 后，目标才能 complete。
- `audit-goal` 和 dashboard 只能审计或展示，不能替代 `write-evidence`。

## 9. Harness 门禁

标准门禁按依赖关系顺序执行：

| 门禁 | 目的 |
| --- | --- |
| `fmt` / `vet` / `lint` | 代码格式、静态检查、lint baseline。 |
| `test` / `race` | 单元、集成前测试和并发安全。 |
| `boundary` | 模块边界、禁止导入、禁止 secret 路径。 |
| `security` / `secret` | secret 扫描和安全基线。 |
| `contracts` | API、schema、health、metrics、error 和 evidence schema 一致性。 |
| `docs-check` | 文档和标准索引一致性。 |
| `integration` | 渲染代表下游并运行标准 smoke。 |
| `dependency-check` | 依赖目的、漏洞策略和 supply-chain 基线。 |
| `standard-impact-check` | 标准变更影响面和下游同步要求。 |
| `downstream-sync-plan` | 本地生成同步计划，不声称 adoption。 |
| `score` | 发布治理完整性评分，最低 9.8。 |
| `evidence` | 生成 evidence manifest 和 artifact。 |
| `release-evidence-check` | 校验 release evidence 可用性。 |
| `release-final-check` | 清洁工作区、分支、tag、manifest、score 和门禁最终聚合。 |
| `release-preflight VERSION=<version>` | 版本、分支、tag、changelog、lint、vuln window 发布预检。 |

推荐 release verify 路径：

```bash
XLIB_CONTEXT=release_verify GOWORK=off make release-check
```

## 10. Evidence 协议

完成声明必须使用 `DONE with evidence:`，并列出：

- scope。
- commands。
- artifacts。
- manifest。
- release status。
- known gaps。

Release evidence 必须包含：

- manifest latest JSON、sha256 和 CI artifact。
- source digest、tree sha、tracked file count、go version。
- checks、contracts、dependencies、tools、standard impact。
- downstream sync required conclusion。
- downstream adoption 字段，默认 `not_claimed`、`local_contract_only`、`proof=false`、`repo_write=false`，除非存在可校验 adoption proof。
- generator evidence。
- workflow metadata、score、governance runtime。
- debt evidence digest、score、status、profile 和 P0/P1/P2 计数。

Manifest 是生成产物；模板可提交，latest manifest 不应作为源文件提交。

## 11. 下游同步与 Adoption

下游同步只说明标准如何传播，不证明被采用。

Adoption proof 必须满足 proof schema，并至少包含：

- source repo 和 source commit。
- downstream repo 和 downstream commit。
- mode。
- gate outputs。
- rollback。

下游状态规则：

| 状态 | 可声明内容 |
| --- | --- |
| `not_adopted` | 尚未采用；release evidence 必须记录覆盖缺口。 |
| `registered` | registry 里存在目标；不能声明实现。 |
| `baseline_scanned` | 完成基线扫描；不能声明兼容。 |
| `patch_only` | 有本地 patch 或计划；不能声明 adoption。 |
| `adopted` | 有 proof schema、命令输出、下游 commit 和 rollback。 |

`x.go` 是私有业务 consumer-review-only 表面。它可以消费基础库，但不得成为标准门禁通过的前置条件，也不得把业务约束反向写入标准。

## 12. L2 Provider 规格

L2 模块包括 `postgresx`、`redisx`、`kafkax`、`natsx`、`taosx`、`ossx`、`clickhousex`。

L2 交付链：

```text
capability manifest
  -> contract pack
  -> adapter implementation
  -> evidence pack
  -> contract / integration / chaos / benchmark / adoption gates
  -> xlibgate release judgment
```

Release ladder：

| 阶段 | 语义 |
| --- | --- |
| T0 | 文档和计划存在，不可发布。 |
| T1 | capability 和 contract 初步存在，不可发布。 |
| T2 | 本地 contract/integration 有证据，但未达 release profile。 |
| T3 | 首个 release-allowed 阶段。 |
| T4 | factory-grade；包括更完整的故障、性能、兼容和 adoption 证据。 |

缺失 profile、pack、readiness 或证据时，L2 release 必须 fail closed，并保留失败证据。

## 13. 测试规格

必需测试面：

- `go test ./...`。
- config validate/sanitize/error/cause。
- lifecycle context、close、idempotency。
- health JSON golden。
- metrics names and labels。
- contract/schema sync。
- config schema mapping。
- `scripts/render_template.sh` 渲染 `kernel` 并测试。
- `Config.Sanitize` property test。
- `Config` fuzz test。
- release manifest temp fixture repo test。
- debt evidence and checksum test。
- Docker toolchain targets smoke，作为同一套门禁的容器化执行，不是第二声明来源。

所有测试和 release 检查必须保留 `GOWORK=off`，不得依赖仓库外 `go.work`。

## 14. 安全与供应链

安全规则：

- 禁止提交 API key、账户 ID、生产端点、私有 endpoint、真实 token。
- 日志、metrics、Evidence、manifest 只允许脱敏数据。
- secret 扫描是 release 阻断门禁。
- 依赖必须有 purpose，记录在 dependency purpose policy 或 ADR。

供应链规则：

- GitHub Actions 必须 pin 到 40-char SHA。
- `golangci-lint` baseline 缺失时失败。
- `govulncheck` 在启用、force 或窗口期要求时必须可用；缺失即失败。
- Docker image 固定工具链；安装 Go、make、git、jq、curl、ca certs、python3-yaml、golangci-lint、govulncheck。
- Docker build context 必须排除 `.git`、`.omc`、`.omx`、`.worktree`、local evidence、cache、output。
- release metadata bind mount 是例外，但必须可审计。

## 15. Debt Governance

Debt scanner 读取：

- `.agent/policies/debt/rules.yaml`
- `.agent/registries/debt/rule-registry.yaml`
- `.agent/policies/debt/exceptions.yaml`
- `.agent/policies/debt/dependency-purpose.yaml`

Debt gate 包括：

- architecture debt。
- domain debt。
- docs drift debt。
- dependency debt。
- testing debt。
- implementation debt。
- security debt。

Release 阻断条件：

- 缺少 debt evidence。
- debt status 不是 passed。
- score 小于 9.8。
- 存在 P0 debt。
- evidence sha256 与 manifest 不一致。

## 16. 发布规格

发布前必须满足：

- `GOWORK=off make ci`。
- `GOWORK=off make docs-check`。
- `GOWORK=off make integration`。
- `CHECK_STATUS=passed GOWORK=off make evidence`。
- `RELEASE_EVIDENCE_REQUIRE_PASSED=1 GOWORK=off make release-evidence-check`。
- `go run ./cmd/goalcli score --min 9.8` 或 Makefile 包装。
- `make release-final-check`。
- `make release-preflight VERSION=<version>`。

每次 main merge 应产生且只产生一个 stable semver patch release。自动 patch release 必须从最新 stable tag 计算 `patch+1`，并创建 GitHub Release object。

如果工作区 dirty、分支不对、tag 冲突、manifest 不可用、远端 release 规则不可证明或 evidence 不完整，发布必须 fail closed。

## 17. 版本与迁移

历史材料显示版本轨迹从 `v0.4.15`、`v0.6.0` strict-config-root 计划，推进到 `v1.0.0-rc.1` 交付清单和目标 runtime。

当前规格的取舍：

- `v0.4.15` 是中间优化状态，不是最终完备状态。
- `v0.6.0` strict-config-root 是重要迁移计划，不等于当前已经删除 `.agent/**`。
- `v1.0.0` 应按 rc gate 处理，直到 P0 blockers、workflow、pinned actions、permissions、downstream replay、truth-state、manifest 全部闭合。
- 稳定发布前不得把计划文件中的通过声明当作真实 release proof。

## 18. 远端治理与不可本地证明项

本地文件不能证明：

- GitHub branch protection 当前已启用。
- ruleset 当前生效。
- required checks 当前绑定。
- GitHub Release object 已创建。
- 远端 workflow 权限和 Actions pin 当前生效。
- 下游仓库已接受标准 patch。

这些项必须通过远端 API、CI artifact、GitHub Release、ruleset export 或下游仓库 commit proof 单独证明。

## 19. 接受标准

一个 `xlib-standard` 模块变更只有在以下条件满足时才能声明完成：

1. 修改保持 `xlib-standard` 作为标准源和模板源，不引入业务或 provider runtime。
2. API、config、errors、health、metrics、contracts、docs 保持一致。
3. 生成器输出可编译、无旧身份 token、无 forbidden path、无 secret。
4. Harness、Evidence、Debt、Goal Runtime 门禁可本地机器验证。
5. 相关 release evidence、standard impact、downstream sync decision 和 debt evidence 生成并校验。
6. 弱事实没有被升级成强事实。
7. 所有未能证明的远端或下游状态被记录为 gap，而不是 passed。

## 20. DONE 模板

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
```

没有 Evidence 的完成声明不能作为 release、adoption 或 final-complete 事实。
