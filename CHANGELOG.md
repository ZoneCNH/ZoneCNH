# Changelog

本文件记录所有版本变更，遵循 [Semantic Versioning](https://semver.org/)。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

## [Unreleased]

### Added

- 新增 `transportx` Foundation 传输契约规格索引，并纳入架构、状态与 CI 一致性门禁。
- 新增 `scripts/audit-status.py` 三文档交叉一致性自校验脚本（22 项检查）。
- 新增 `.github/workflows/audit-status.yml` CI 门禁，PR 触及 STATUS/README/ARCHITECTURE 时自动运行 audit-status.py，FAIL 阻断合并。
- 新增 `.claude/hooks/count-guard.mjs` PreToolUse hook，Write/Edit 三文档时扫描数量模式并告警。

### Changed

- 固化模块级 Goal 文档路径为 `module/{module}/goal.md`，禁止 `goal/` 目录和 `goal/1.md` 槽位。
- STATUS.md / README.md / ARCHITECTURE.md 三文档全量交叉审计闭合（18 PR，基座版本 vs GitHub Release 对齐、domainx 归并、strategies 404 移除、仪表盘递推、同步表自洽）。
- CLAUDE.md 新增 §数量验证门禁、§三文档交叉同步规则。

## [v0.5.0] - 2026-06-09

### Added

- **宪法 §0**：分支纪律（禁止 main 开发，强制 worktree 隔离）
- **宪法 §15-§19**：交付管线治理条款（管线七律、追溯门禁、AI 辅助交付、制品完成层级、CRI）
- **Goal 驱动交付体系 v1.0.0**：11 层管线（Goal→Spec→Design→Plan→Tasks→Prompt→Code→Test→Review→Release→Retrospective）
- **10 个 Goal Agent**：goal-spec, goal-reviewer, goal-matrix, goal-prompt-builder, goal-evidence, goal-architect, goal-planner, goal-governance, goal-context-recovery, goal-lint
- **38 条 Lint 规则**：G-LINT(7), S-LINT(8), M-LINT(8), P-LINT(10), C-LINT(5)
- **统一配置中心**：`.config/goal/`（10 个状态文件，6 个 YAML 注册表）
- **门禁体系**：G0-G11 共 12 个质量门禁
- **追溯矩阵**：Goal→Spec→AC→Task→Test→Evidence 全链路映射

### Changed

- **CONSTITUTION.md §0.2**：worktree 降为可选项，feature branch 为默认（后恢复为强制 worktree）

## [v0.4.1] - 2026-06-08

### Added

- Goal Agent 跨代理一致性优化（3 轮，修复 14 个问题）
- Agent 团队协作协议（14-agent-protocols.md）

## [v0.4.0] - 2026-06-08

### Added

- Goal 驱动交付体系初始版本
- 5 个核心 Goal Agent（goal-spec, goal-reviewer, goal-matrix, goal-prompt-builder, goal-evidence）
- 追溯矩阵规范（docs/governance/TRACEABILITY.md）
- Gate 体系（docs/governance/DEFINITION-OF-READY.md, DEFINITION-OF-DONE.md）

## [v0.3.1] - 2026-06-07

### Fixed

- CONSTITUTION.md 表格格式对齐
- goal 结构分析报告

## [v0.3.0] - 2026-06-07

### Added

- CONSTITUTION.md 初始版本（§1-§14）
- 模块宪法：十三条设计原则、模块边界、依赖方向、接口契约、测试标准
- 17 个模块规格骨架

## [v0.2.0] - 2026-06-07

### Added

- ARCHITECTURE.md 依赖拓扑文档
- 分层领域模型（基座→数据域→分析域⇄决策域→执行域→x.go）

## [v0.1.0] - 2026-06-07

### Added

- README.md 个人主页与技术栈索引
- CLAUDE.md 工作指南
- AGENTS.md 代理编排指南

---

版本历史锚点：

- [v0.5.0]: https://github.com/ZoneCNH/ZoneCNH/releases/tag/v0.5.0
- [v0.4.1]: https://github.com/ZoneCNH/ZoneCNH/releases/tag/v0.4.1
- [v0.4.0]: https://github.com/ZoneCNH/ZoneCNH/releases/tag/v0.4.0
- [v0.3.1]: https://github.com/ZoneCNH/ZoneCNH/releases/tag/v0.3.1
- [v0.3.0]: https://github.com/ZoneCNH/ZoneCNH/releases/tag/v0.3.0
- [v0.2.0]: https://github.com/ZoneCNH/ZoneCNH/releases/tag/v0.2.0
- [v0.1.0]: https://github.com/ZoneCNH/ZoneCNH/releases/tag/v0.1.0
