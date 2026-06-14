# Changelog

本文件记录所有版本变更，遵循 [Semantic Versioning](https://semver.org/)。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

## [Unreleased]

### Added

- 新增 `transportx` Foundation 传输契约规格索引，并纳入架构、状态与 CI 一致性门禁。
- 新增 `scripts/audit-status.py` 三文档交叉一致性自校验脚本（22 项检查）。
- 新增 `.github/workflows/audit-status.yml` CI 门禁，PR 触及 STATUS/README/ARCHITECTURE 时自动运行 audit-status.py，FAIL 阻断合并。
- 新增 `.claude/hooks/count-guard.mjs` PreToolUse hook，Write/Edit 三文档时扫描数量模式。BLOCK 级（exit 2）：组件总数/平均进度/有版本号；WARN 级（exit 0）：X/Y 分数/百分比/已有/已创建。COUNT_GUARD_STRICT=false 降级为全告警。

### Changed

- 固化模块级 Goal 文档路径为 `module/{module}/goal.md`，禁止 `goal/` 目录和 `goal/1.md` 槽位。
- **STATUS.md / README.md / ARCHITECTURE.md 三文档全量交叉审计闭合**（52 PRs, #385-#439）。审计日期 2026-06-15，最终 audit-status.py (v2 cross-dimension) 24/24 PASS，78 repos 0 404。详情见 `docs/solutions/three-doc-audit-20260615.md`。

  > 验证：`gh pr list --repo ZoneCNH/ZoneCNH --state merged --json number --jq '[.[] | select(.number >= 385 and .number <= 439)] | length'` → 52

  **审计根因**：agent 凭常识编造计数（18 vs 14 个 Release、67% vs 62% 平均进度、有版本号 1/0/0 vs 2/3/3），而非逐表逐行 grep 统计。

  **修正清单**：
  - 基座 20 模块版本号 vs GitHub Release 逐一核对（14/20 有 Release，18/20 有 git tag）
  - domainx 三文档归属统一（L2.5 → 基座）
  - strategies 404 仓库全文件移除（决策域 7→6，组件总数 81→80）
  - 域统计有版本号：分析域 1→2，决策域 0→3，执行域 0→3，合计 30→37
  - 仪表盘全部递推重算（平均进度 67%→62%，5% 分布 15→22，已创建 16→22）
  - 同步检查表自身 5 处过时计数修正
  - ARCHITECTURE 状态表 12 处版本/进度对齐

  **最终自洽状态**（24/24 机械化检查全部 PASS，含 RELEASE 列与版本注记交叉验证）：
  - 组件总数 80 = 55(≥80%) + 1(25%) + 22(5%) + 2(未标注)
  - 80 = 58(已有) + 22(已创建)
  - 80 = 37(有版本号) + 43(无版本号)
  - 78 repos gh api 逐一验证，0 404
  - 14 个 GitHub Release tag 全部与 STATUS.md 版本号一致
  - 管线评分全部 ≥67（最低 taosx spec=67），其中 13/20 全线 ≥98
  - 全部 20 模块 CI 已部署（1~11 workflows）

  **预防门禁**：
  - L1 CountGuard hook（BLOCK 组件总数/平均进度/有版本号，WARN 其余）
  - L2 audit-status.py（22 项机械化验证）
  - L3 CI gate（.github/workflows/audit-status.yml，PR 触及三文档时自动运行，FAIL 阻断 merge）

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
