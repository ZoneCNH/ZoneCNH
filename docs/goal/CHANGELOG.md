# 变更日志

> 记录 docs/goal/ 体系的重大结构性变更。

## 2026-06-08 — 结构性修正

### SSOT 消除

- **08-quality-gates.md §6**: Release 前检查清单改为引用 04-gates.md G10，消除重复定义
- **05-layer-standards.md §7+§8**: 合并重复的 Test 标准章节为单一 §7
- **09-templates.md**: Matrix 模板 status 值从 `Todo` 改为 `Unmapped`，与 05-layer-standards §9 对齐
- **15-registry.md**: Task Registry 示例 status 从 `executing` 改为 `In Progress`，与 05-layer-standards §4 对齐

### 结构增强

- **03-pipeline.md §2.5**: 新增对象状态总表，统一索引 Goal/Spec/Design/Plan/Task/Matrix/Pipeline/Issue/Gate/Maturity/Change Level 的状态定义和 SSOT 位置
- **00-quickstart.md §6**: 新增"高级使用"阅读路径，覆盖 13-23 号文件
- **14-agent-protocols.md §1**: 添加指向 `.claude/agents/goal-*.md` 已实现 Agent 的链接

### 状态澄清

- **22-delivery-os.md**: 添加"愿景架构（Vision）"状态标签
- **23-workflow-governance-checks.md**: 添加"愿景架构（Vision）"状态标签
- **README.md**: tools/ 条目标注为"planned"

### 补充修正

- **09-templates.md §6**: Matrix YAML 和 JSON 模板中的 `Todo` 改为 `Unmapped`
- **05-layer-standards.md Task 状态**: 详细定义从 `Todo → Ready → In Progress → …` 改为 `Unmapped → Mapped → In Progress → …`，与摘要部分一致

### 工具锚点清理

- **05-layer-standards.md**: 移除 8 个冗余 HTML 锚点标签（重复的 Plan/Tasks/Prompt/Matrix anchor）
