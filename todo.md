# 待办清单

> FoundationX 文档枢纽的待办事项，按优先级排列

## P0 — 阻塞核心链路

- [ ] Phase 1：分析域开发（factor-engine → feature-store → factor-eval）
- [ ] 核实 x.go 体量：确认只含配置加载、依赖 wiring 和生命周期控制，必要时剥离业务逻辑

## P1 — 质量与规范

- [ ] 为 14 个交易所 SDK 建立 tagged release（版本化发布）
- [ ] 评估 6 个央行数据源合并为统一宏观适配器
- [ ] 评估仓库命名重整（`foundation-*`/`adapter-*`/`engine-*`/`lab-*`）

## P2 — 债务清理

- [ ] 结构债：分层违规 import、L2 互相耦合、循环依赖、上帝模块
- [ ] 实现债：重复代码、过时模式、补丁热点
- [ ] 测试债：缺失测试 / 脆弱测试 / 金字塔倒置
- [ ] 文档债：ADR 缺失、文档与代码不一致
- [ ] 依赖债：过期 / 废弃 / 有 CVE 的第三方库
- [ ] 领域债：模型与业务语言不一致（DDD 视角）

## P3 — 工具与流程

- [ ] 设置 Copilot + Claude 自动执行 review
- [ ] 使用 subagent review 流程
- [ ] 深度分析 `/home/specs` 目录（30+ 子目录的技术规范资产）
