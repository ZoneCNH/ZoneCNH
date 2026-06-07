# xlib-standard 冲突与取舍账本

Status: consolidated

## 1. 标准源 vs 运行时实现

冲突：部分历史材料把 `xlib-standard` 描述为近似完整基础库运行时，当前标准文档则把它限定为标准源、模板、生成器、Harness 和 Evidence Runtime。

取舍：`xlib-standard` 不实现真实 L1/L2 provider runtime，也不承载业务。它只提供参考模板、契约、门禁和证据机制。

## 2. `corekit`、`foundationx`、`baselib-template` 的身份

冲突：历史和迁移文档中出现旧名称或中性目标名称。

取舍：当前主身份是 `xlib-standard`。`corekit` 仅为中性组织路径 smoke/registry 目标；`foundationx` 和 `baselib-template` 仅为迁移上下文。

## 3. 默认下游范围

冲突：不同文档列出 `kernel`、`configx`、`redisx`、全部 L2 和 x.go。

取舍：默认代表下游为 `kernel`、`configx`、`redisx`。全部 L2 是矩阵和路线图对象；`x.go` 是 consumer-review-only。

## 4. `cmd/goalcli` vs scripts

冲突：早期材料依赖 shell scripts，后续标准要求 `cmd/goalcli` 成为唯一机器入口。

取舍：`cmd/goalcli` 是规范入口。Makefile 可以包装；scripts 可以保留为 delegated helper 或兼容层，但不能成为事实裁决源。

## 5. `.config/xlib` strict root vs 当前 `.agent` / `.xlib`

冲突：v0.6.0 和 Downloads strict-config-root 计划要求 `.config/xlib` 为唯一事实根，同时当前标准仍明确使用 `.agent/registries`、`.agent/policies`、`.xlib/facts`、Evidence ledger 等路径。

取舍：`.config/xlib` 是迁移目标，不是当前已完成事实。当前门禁必须报告事实根和兼容根；任何删除 `.agent/**` 或 `.xlib/**` 的动作都需要双读迁移、兼容测试、Evidence 和回滚。

## 6. 生成器复制策略

冲突：当前 `render_template.sh` 以模板渲染和排除项为主，strict 计划要求 allowlist materialization 和 pathguard。

取舍：当前规格保留 `render_template.sh` 为入口，同时把 allowlist materialization、pathguard、symlink/case/path traversal/go:embed 检查列为目标约束。

## 7. Downstream sync plan vs adoption proof

冲突：部分计划文件把同步计划和 patch-only 视为接近采用；当前 truth-state 文档禁止弱事实升级。

取舍：downstream sync plan 只生成本地计划。Adoption 只能由下游 commit、gate outputs、proof schema 和 rollback 证明。

## 8. Evidence artifact exists vs release-ready

冲突：历史证据和 latest 文件可能存在，但 current release-ready 还要求 score、workflow、manifest、debt、standard impact、release evidence check 和 clean workspace。

取舍：存在文件只是 artifact_exists。Release-ready 必须通过 release-final/preflight 和 manifest 校验。

## 9. Docker Toolchain Runtime

冲突：Docker 文档容易被理解为第二套 gate。

取舍：Docker 只是同一套门禁的可复现执行环境，不创建独立质量声明。

## 10. `CHECK_STATUS=passed`

冲突：Evidence 命令可用 `CHECK_STATUS=passed` 生成材料，但 truth-state 禁止直接把它视为发布完成。

取舍：`CHECK_STATUS=passed` 只是 evidence 生成上下文。Release 还必须通过 release-evidence-check、score、final-check 和 preflight。

## 11. L2 readiness 与 release

冲突：L2 计划文件包含 adapter、contract、capability、evidence 多阶段内容，容易把模板 readiness 误当 release。

取舍：T3 才是首个 release-allowed 阶段；T4 是 factory-grade。缺失 profile、pack、readiness 或 evidence 时 fail closed。

## 12. 远端治理证明

冲突：本地文档记录 branch governance、workflow、ruleset 和 release 要求，但不能证明远端当前启用状态。

取舍：本地文件只能定义要求。远端状态必须用 GitHub API、CI artifact、ruleset export、required checks 或 Release object 证明。

## 13. v1.0.0 状态

冲突：Downloads 中存在 v1.0.0 delivery checklist 和 config goal，部分文字接近完成声明。

取舍：本规格按 `v1.0.0-rc.1` 目标处理，直到 P0 blockers、workflow、pinned actions、permissions、downstream replay、truth-state、manifest 全部有可验证证据。

## 14. Secret 和测试 fixture

冲突：测试和生成器需要 fixture，但标准禁止生产 secret。

取舍：fixture 必须是脱敏、虚构或 temp repo 数据；任何真实 secret、真实账户和生产 endpoint 都禁止进入仓库、Evidence、logs 或 manifest。

## 15. Dirty workspace

冲突：本次整理运行时，仓库已有未提交改动。OMX team worktree 创建因此拒绝执行。

取舍：不 stash、不 commit、不 revert 既有改动。使用原生子代理完成分析；发布类判断中 dirty workspace 仍然是 fail-closed 条件。

## 16. 154 文件整理口径 vs 181 文件旧分析口径

冲突：历史材料曾同时使用 154 个输入文件和 181-file source set 口径；旧版 `SPEC.md` 与 `DEEP-ANALYSIS.md` 保留过 181-file 历史口径。

取舍：本次整理以 154 个输入文件为当前覆盖口径。181 口径只作为旧分析背景，不得覆盖当前主规格、追溯表或覆盖清单；`MODULE-SPEC.md` 仅作为历史参考。

## 17. Required Gates 17+ vs harness gates 66

冲突：`SPEC.md` 摘要曾使用 17-plus Required gate 家族表述，`DEEP-ANALYSIS.md` 又记录 66 个 gates。两者统计粒度不同，容易被读成互相矛盾的当前验收标准。

取舍：17 Required 只表示 required gate 家族；66 Gates 表示完整 harness gate 集合（17 Required + 49 扩展/治理/发布）。当前发布验收以 `SPEC.md` 中的 gate 定义、release-final 和 preflight 要求为准，不再使用 required-only 的 66-gate 表述。

## 18. ADR 10 vs 9 formal + template/history

冲突：旧材料使用 10 个 ADR 的汇总数字；当前整理口径区分 9 个 Accepted ADR、template 和历史规划文档。

取舍：正式 ADR 按 9 个 Accepted ADR 处理。template 与 `1/2/3` 历史规划文件只作为背景；若源仓库新增 ADR，必须同步更新覆盖清单、主规格和追溯表。

## 19. 1000-pass 覆盖检查 vs 语义审查

冲突：`1000-pass` 容易被读成每条语义经过 1000 次独立审查，从而把文件集合稳定性证明升级为语义正确性证明。

取舍：`1000-pass` 只证明输入文件集合和清单稳定。语义结论来自 agent team 分片合成、主线程收敛、追溯表和本冲突账本；具体条款仍需后续实现和门禁验证。

## 20. 本地规格整理完成 vs 版本控制/发布交付

冲突：本目录文件存在并通过本地检查，容易被误写成已经提交、发布或被下游采用。

取舍：本地整理完成只表示规格包内容已形成并可审阅。已进入版本控制必须由 `git status`、commit 或 tag 证明；已发布必须由 release artifact 和 GitHub Release object 证明；已采用必须由下游仓库证据证明。

## 21. 条款级追溯 vs 逐规则证明账本

冲突：`TRACEABILITY.md` 容易被理解为 154 个输入文件对所有规则的逐项证明。

取舍：追溯表只证明主规格主要条款的来源锚点。逐规则或内容级证明需要 rule id 到 source span、digest/tree sha 或 evidence artifact；发布、远端和下游状态仍按运行时证据判断。

## 22. 本机绝对路径清单 vs 可移植 source bundle

冲突：`COVERAGE-MANIFEST.md` 使用 `/home/...` 绝对路径，容易被误解为任何环境都可复现。

取舍：该清单只证明本次分析机器上的输入集合。跨机器复现必须提供 source pack、路径映射、digest/tree sha 或重新生成覆盖清单。
