# xlib-standard 冲突与取舍账本

Status: Aligned-With ANALYSIS.md v3.0.0

Last-Updated: 2026-06-08


本账本只保留同一上游 SSOT 内部说法之间的硬冲突。分析快照 vs 现实边界已迁移到 `SNAPSHOT-BOUNDARY.md`。


## 1. 标准源 vs 运行时实现

冲突：部分历史材料把 `xlib-standard` 描述为近似完整基础库运行时，当前标准文档则把它限定为标准源、模板、生成器、Harness 和 Evidence Runtime。

取舍：`xlib-standard` 不实现真实 L1/L2 provider runtime，也不承载业务。它只提供参考模板、契约、门禁和证据机制。

Resolved-in: ANALYSIS.md §2；analysis/template.md；analysis/runtime.md


## 2. `corekit`、`foundationx`、`baselib-template` 的身份

冲突：历史和迁移文档中出现旧名称或中性目标名称。

取舍：当前主身份是 `xlib-standard`。`corekit` 仅为中性组织路径 smoke/registry 目标；`foundationx` 和 `baselib-template` 仅为迁移上下文。

Resolved-in: ANALYSIS.md §2；analysis/governance.md


## 3. 默认下游范围

冲突：不同文档列出 `kernel`、`configx`、`redisx`、全部 L2 和 x.go。

取舍：默认代表下游为 `kernel`、`configx`、`redisx`。全部 L2 是矩阵和路线图对象；`x.go` 是 consumer-review-only。

Resolved-in: ANALYSIS.md §6；analysis/governance.md


## 4. `cmd/goalcli` vs scripts

冲突：早期材料依赖 shell scripts，后续标准要求 `cmd/goalcli` 成为唯一机器入口。

取舍：`cmd/goalcli` 是规范入口。Makefile 可以包装；scripts 可以保留为 delegated helper 或兼容层，但不能成为事实裁决源。

Resolved-in: analysis/runtime.md


## 5. 生成器复制策略

冲突：当前 `render_template.sh` 以模板渲染和排除项为主，strict 计划要求 allowlist materialization 和 pathguard。

取舍：当前分析保留 `render_template.sh` 为上游入口，同时把 allowlist materialization、pathguard、symlink/case/path traversal/go:embed 检查列为目标约束。

Resolved-in: analysis/template.md；SNAPSHOT-BOUNDARY.md B-01


## 6. Evidence artifact exists vs release-ready

冲突：历史证据和 latest 文件可能存在，但 current release-ready 还要求 score、workflow、manifest、debt、standard impact、release evidence check 和 clean workspace。

取舍：存在文件只是 artifact_exists。Release-ready 必须通过上游 release-final/preflight 和 manifest 校验；本仓库不声明通过。

Resolved-in: analysis/runtime.md；SNAPSHOT-BOUNDARY.md


## 7. Docker Toolchain Runtime

冲突：Docker 文档容易被理解为第二套 gate。

取舍：Docker 只是同一套门禁的可复现执行环境，不创建独立质量声明。

Resolved-in: analysis/template.md；analysis/runtime.md


## 8. `CHECK_STATUS=passed`

冲突：Evidence 命令可用 `CHECK_STATUS=passed` 生成材料，但 truth-state 禁止直接把它视为发布完成。

取舍：`CHECK_STATUS=passed` 只是 evidence 生成上下文。Release 还必须通过 release evidence、score、final-check 和 preflight。

Resolved-in: analysis/runtime.md；analysis/governance.md


## 9. Secret 和测试 fixture

冲突：测试和生成器需要 fixture，但标准禁止生产 secret。

取舍：fixture 必须是脱敏、虚构或 disposable test repo 数据；任何真实 secret、真实账户和生产 endpoint 都禁止进入仓库、Evidence、logs 或 manifest。

Resolved-in: analysis/template.md


## 10. ADR 10 vs 9 formal + template/history

冲突：旧材料使用 10 个 ADR 的汇总数字；当前整理口径区分 9 个 Accepted ADR、template 和历史规划文档。

取舍：正式 ADR 按 9 个 Accepted ADR 处理。template 与 `1/2/3` 历史规划文件只作为背景；若源仓库新增 ADR，必须同步更新 `INDEX.md`、覆盖清单和追溯表。

Resolved-in: INDEX.md §2
