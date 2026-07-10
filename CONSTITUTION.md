# FoundationX 宪法

> FoundationX 全系统的最高治理文件。
>
> 本文件是 AI 代理和人类贡献者在实现、审查或修改任何模块或交付流程时的最高权威参考。
> 当本文件与 `module/*/spec/SPEC.md`、`module/FOUNDATION-SPEC.md`、`docs/governance/DEVELOPMENT-WORKFLOW.md` 或其他文档冲突时，以本文件为准。

最后更新：2026-07-11

> **迁移通知**：宪法条款已按章节拆分至 [`docs/constitution/`](docs/constitution/)，便于按条款快速导航。
> 本文件作为向后兼容存根保留，所有外部引用（`CLAUDE.md`、`AGENTS.md`、`module/*/spec/SPEC.md` 等）无需修改。

---

## 章节目录

| 条款 | 文件 | 核心内容 |
| ---- | ---- | -------- |
| 序言 | [`docs/constitution/preamble.md`](docs/constitution/preamble.md) | 宪法约束对象与适用范围 |
| 第零条：分支纪律 | [`docs/constitution/00-branch-discipline.md`](docs/constitution/00-branch-discipline.md) | 🔴 最高优先级 — 禁止 main 开发、强制 worktree、Agent 约束 |
| 第一条：设计原则 | [`docs/constitution/01-design-principles.md`](docs/constitution/01-design-principles.md) | 十三条不变量 P1-P13（基座 + 领域） |
| 第二条：模块边界 | [`docs/constitution/02-module-boundaries.md`](docs/constitution/02-module-boundaries.md) | 职责声明、边界违规、仲裁优先级、奥卡姆剃刀、业务域定义（§2.7） |
| 第三条：依赖方向 | [`docs/constitution/03-dependency-direction.md`](docs/constitution/03-dependency-direction.md) | 依赖拓扑、单向下行规则、禁止依赖矩阵 |
| 第四条：接口契约 | [`docs/constitution/04-interface-contracts.md`](docs/constitution/04-interface-contracts.md) | 窄接口（≤7方法）、编译期检查、WHEN/THEN 行为规格、跨模块通信协议（§4.5 HTTP + Gin） |
| 第五条：测试标准 | [`docs/constitution/05-testing-standards.md`](docs/constitution/05-testing-standards.md) | 覆盖率分级（L0=100%）、测试分类、三段式命名、Mock 契约一致性（§5.5） |
| 第六条：可观测性 | [`docs/constitution/06-observability.md`](docs/constitution/06-observability.md) | Metrics 命名规范、Label Policy、Redaction |
| 第七条：命名规范 | [`docs/constitution/07-naming-conventions.md`](docs/constitution/07-naming-conventions.md) | Go 命名、模块命名模式、数据域跨层命名 |
| 第八条：错误处理 | [`docs/constitution/08-error-handling.md`](docs/constitution/08-error-handling.md) | 哨兵错误、%w 包装、错误消息格式 |
| 第九条：安全要求 | [`docs/constitution/09-security.md`](docs/constitution/09-security.md) | 密钥管理、输入校验、数据保护、依赖安全 |
| 第十条：变更管理 | [`docs/constitution/10-change-management.md`](docs/constitution/10-change-management.md) | PATCH/MINOR/MAJOR 分类、Breaking Change 流程 |
| 第十一条：代码审查 | [`docs/constitution/11-code-review.md`](docs/constitution/11-code-review.md) | 审查清单（9项）、严重性级别、AI 代理审查规则 |
| 第十二条：修正程序 | [`docs/constitution/12-amendment-procedure.md`](docs/constitution/12-amendment-procedure.md) | 修正条件、流程、修正历史记录 |
| 第十三条：最高条款 | [`docs/constitution/13-supreme-clause.md`](docs/constitution/13-supreme-clause.md) | 效力层级、适用范围（§1-§14 + §15-§19 + §20）、解释权 |
| 第十四条：管线自改约束 | [`docs/constitution/14-anti-goodhart.md`](docs/constitution/14-anti-goodhart.md) | 受保护文件清单、RSI 合法形式（fork/AB/outer/批准） |
| 第十五条：交付管线 | [`docs/constitution/15-delivery-pipeline.md`](docs/constitution/15-delivery-pipeline.md) | 管线七律 D1-D7、变更传播链 |
| 第十六条：追溯与门禁 | [`docs/constitution/16-traceability-gates.md`](docs/constitution/16-traceability-gates.md) | 制品 ID 前缀体系、覆盖要求、孤儿检测 |
| 第十七条：AI 辅助交付 | [`docs/constitution/17-ai-assisted-delivery.md`](docs/constitution/17-ai-assisted-delivery.md) | Prompt 质量标准、代码边界、输出验证 |
| 第十八条：制品完成层级 | [`docs/constitution/18-artifact-completion.md`](docs/constitution/18-artifact-completion.md) | 四级 Done L1-L4（Code/Test/Release/Goal） |
| 第十九条：受控递归改进 | [`docs/constitution/19-cri.md`](docs/constitution/19-cri.md) | CRI 七原则 R1-R7、改进边界、风险分级审批 |
| 第二十条：认识论标准 | [`docs/constitution/20-epistemic-standards.md`](docs/constitution/20-epistemic-standards.md) | 证据标签、置信度、FRAME→REALITY 禁止、反奉承红旗、自检要求 |
| 附录 A / B / L2.5 | [`docs/constitution/appendix.md`](docs/constitution/appendix.md) | 模块清单（基座+L2.5）、与 CLAUDE.md 关系、L2.5 收口边界 |

## CI/CD 执行平面（CICD-001）

> **SSOT**：`BASELINE.yaml` · **规则文档**：`knowledge/ci.md`

CICD-001 规定 ZoneCNH 全体系 CI/CD 只运行在 self-hosted runners 上，禁止使用 GitHub-hosted runners（`ubuntu-latest` / `windows-latest` / `macos-latest`）。所有 workflow job 必须声明 `[self-hosted, Linux, X64, sre/*]` pool，部署只能走 `sre/deploy`，业务仓库禁止内联 `ssh`/`scp`/`rsync`/`kubectl`/`helm`/`systemctl`/`docker compose` 等部署命令。

| 规则文件 | 用途 |
| -------- | ---- |
| [`BASELINE.yaml`](BASELINE.yaml) | Go 基线 + CI/CD runner 策略 SSOT |
| [`docs/sre/RUNNER-POOLS.yaml`](docs/sre/RUNNER-POOLS.yaml) | 11 个 `sre/*` runner pool 注册表 |
| [`docs/sre/MODULE-RUNNER-MAP.yaml`](docs/sre/MODULE-RUNNER-MAP.yaml) | 68 个模块到 runner pool 的确定性映射 |
| [`knowledge/ci.md`](knowledge/ci.md) | CICD-001 完整方案 + 恢复时间表 + 负责人

---

## 与 CLAUDE.md 的关系

`CLAUDE.md` 是 Claude Code 的工作指南，规定仓库级操作约定（文档同步、提交格式、安全红线）。
本宪法是系统级治理文件，规定模块实现（§1-§14）、交付管线（§15-§19）和认识论标准（§20）的技术要求。

当两者冲突时，`CLAUDE.md` 安全条款（不提交凭证等）优先；技术条款以本宪法为准。

---

## 修正历史摘要

详见 [`docs/constitution/12-amendment-procedure.md`](docs/constitution/12-amendment-procedure.md)。

| 日期 | 变更摘要 |
| ---- | -------- |
| 2026-07-11 | 新增 §2.7 业务域定义（数据域 · Data / 分析域 · Analytics / 决策域 · Decision / 执行域 · Execution）；新增 §4.5 跨模块通信协议（HTTP + Gin 强制约束）|
| 2026-07-05 | 新增 §2.6：模块与仓库创建授权；§0.3 增补 Agent 创建约束（交叉引用 §2.6）|
| 2026-07-03 | 新增 §5.5：Mock 契约一致性（Mock/Fake 须过与生产实现相同的契约测试，支撑 P6 回测与实盘共享代码）|
| 2026-06-21 | 新增第二十条：认识论标准（§20）|
| 2026-06-21 | 条款迁移至 `docs/constitution/`，本文件转为向后兼容存根 |
| 2026-06-16 | 新增 §2.5 模块增殖约束（奥卡姆剃刀）|
| 2026-06-12 | 新增 §2.4 本地代码目录；§5 P0 修复；§4.4 状态同步 |
| 2026-06-10 | §0.2 补充分支创建规则 |
| 2026-06-09 | 新增第零条：分支纪律（最高优先级）|
| 2026-06-08 | 新增 §15-§19 交付管线治理条款 |
| 2026-06-07 | 初始版本（§1-§14）|
