# 变更日志

> 记录 docs/goal/ 体系的重大结构性变更。

## 2026-06-11 — Goal CI self-hosted runner 合同固化

### CI 可执行性

- 统一 Goal workflow、工具文档示例与 validator fixture 到 `[self-hosted, Linux, X64]`。
- 将 self-hosted runner、workspace-local tool cache 与 toolchain setup 写入 schema、validator 和 self-test，防止回退 hosted runner 或依赖全局 Python/pip 状态。
- 明确 `/opt/hostedtoolcache` 首步前失败是 self-hosted runner 基础设施阻断，不得通过切换 hosted runner、跳过 Gate 或放宽 validator 规避。

## 2026-06-10 — Goal Delivery OS 执行口径收敛

### 执行性与可验证性

- 在入口、执行指南、Evidence 与 Matrix 模板中收敛 `release` 命令、canonical edge vocabulary 和 No Evidence, No Done 的最小证明包。
- 将 Constitution 与 Codex Agent 投影漂移记录到受保护资产 Change Request，避免文档优化绕过审批。
- 明确未批准 Change Request 只是提案，不能作为当前强规则源。

## 2026-06-10 — 模块代码本地路径规则固化

### 本地代码边界

- 统一模块代码仓库本地路径为 `/home/{module}`，其中 `{module}` 与 GitHub 仓库名一致。
- 明确 `module/{module}/` 只保存 Goal、Spec、Traceability、Task、Plan、Prompt、Evidence 等交付制品，不承载实现源码树。
- 同步 Code 标准、Code DoR/DoD、Code Lint、`module/README.md`、`AGENTS.md`、`CONSTITUTION.md` 和 `ARCHITECTURE.md` 的路径口径。
- 将本地代码边界投影到 `.config/goal/schema/rules.yaml` 的 `module_code_location`，并接入 `docs/goal/tools/rule-drift-check.py`，校验 `module/{module}/` 不承载源码树。

## 2026-06-09 — 模块级 Goal 文档路径固化

### 命名规则

- 固定模块级 Goal 文档路径为 `module/{module}/goal.md`，禁止 `module/{module}/goal/`、`module/{module}/goal/1.md` 和 `goal/*.md` 槽位。
- 同步 `module/README.md`、`AGENTS.md` 与 `.config/goal/schema/rules.yaml`，避免后续导入重新生成目录式 Goal。

## 2026-06-09 — Phase 1 权威边界与配置边界固化

### 权威边界

- 将 `00-authority-map.md` 纳入 `README.md` 和 `GLOSSARY.md` 入口，明确 README、Glossary、schema 与状态快照是 SSOT 的索引或投影。
- 在 `.config/goal/schema/rules.yaml`、`.config/goal/pipeline/state.yaml`、`.config/goal/gates/state.yaml` 增加 `authority_source`，只指向 `docs/goal/` 权威文档。

### 配置边界

- 调整 `.gitignore`，允许提交 `.config/goal/` 控制面目录中的 schema、Registry、Matrix、Gate、Pipeline、Evidence 和 Prompt 审计快照。
- 继续忽略 `.config/goal/runtime/`、`locks/`、`local/`、`cache/`、`logs/` 以及本地 lock/tmp/log 文件。

## 2026-06-09 — 深度分析残留项对齐

### SSOT 对齐

- 在 `03-pipeline.md` 明确 Pipeline 状态枚举是 Registry、Glossary、Runtime、Gate 与脚本校验的唯一状态来源。
- 将 `15-registry.md` 的 Issue 异常状态对齐到 Pipeline 异常状态枚举，并移除本地新增状态。

### 运行协议

- 在 `13-runtime-engine.md` 拆分 CL0 / CL1 Lite Mode，明确治理规则、状态、模板、脚本或追溯协议变更必须升为 CL1+。
- 在 Evidence 模板中补充 `Test ID: TEST-xxx`，对齐 ID 体系中 Evidence 必须绑定 Test ID 的要求。

### Lint 映射

- 在 `05-layer-standards.md` 将 Prompt 质量标准链接到 Prompt Lint。
- 在 `10-lint-rules.md` 增加 Prompt 质量标准到 `P-LINT-*` 规则的映射表。

## 2026-06-09 — 深度分析报告修复（断链 + SSOT + 格式）

### 断链修复

- **GLOSSARY.md L27**: Non-goal 锚点从 `02-goal-standard.md#7-non-goals` 修正为 `02-goal-standard.md#5-goal-模板`（Non-goals 在模板 §5 内，非顶层 §7）

### SSOT 消除

- **11-ai-collaboration.md §4 Prompt 分层**: 删除与 05-layer-standards.md §5 完全重复的 Prompt 类型表，改为引用 SSOT

### 格式统一

- **14-agent-protocols.md**: 标题从 `# 14. Agent 协议` 改为 `# Agent 协议`，与其他文件格式统一
- **15-registry.md**: 标题从 `# 15. Registry 系统` 改为 `# Registry 系统`，与其他文件格式统一

## 2026-06-09 — GLOSSARY 扩展（45 → 53 条术语）

### 新增术语

- 新增 8 个术语定义：AutoResearch、Code Boundary、Context Package、Failure Budget、Human Approval Check、MVA、North Star、PromptOps
- 来源文件：`11-ai-collaboration.md`、`13-runtime-engine.md`、`15-registry.md`、`17-risk-and-decisions.md`
- DoR 和 Change Level 已存在，本轮未重复添加

## 2026-06-09 — 评分体系全覆盖（11/11 阶段）

### 新增 RUBRIC

- 新增 5 个阶段评分 Rubric：`RUBRIC-design.md`、`RUBRIC-test.md`、`RUBRIC-review.md`、`RUBRIC-release.md`、`RUBRIC-retrospective.md`
- `score.schema.json` stage 枚举从 6 扩展到 11，覆盖完整管线
- `08-quality-gates.md` §3 评分体系从 3 个内联表扩展到 12 个（含 Matrix 横切制品）

### 覆盖矩阵

| 阶段 | 之前 | 现在 |
|------|------|------|
| Goal | 引用 02-goal-standard | 引用 02-goal-standard |
| Spec | ✅ schema + RUBRIC + 内联 | ✅ |
| Design | ❌ | ✅ schema + RUBRIC + 内联 |
| Plan | ✅ schema + RUBRIC | ✅ + 内联 |
| Tasks | ✅ schema + RUBRIC | ✅ + 内联 |
| Prompt | ✅ schema + RUBRIC + 内联 | ✅ |
| Code | ✅ schema + RUBRIC | ✅ + 内联 |
| Test | ❌ | ✅ schema + RUBRIC + 内联 |
| Review | ❌ | ✅ schema + RUBRIC + 内联 |
| Release | ❌ | ✅ schema + RUBRIC + 内联 |
| Retrospective | ❌ | ✅ schema + RUBRIC + 内联 |
| Matrix | ✅ schema + RUBRIC | ✅ + 内联 |

## 2026-06-09 — module 规格库迁移与同步基线

### 规格库迁移

- 将模块规格库口径统一到 `module/`：模块 SPEC、TRACEABILITY、tasks 和 governance 制品均以 `module/` 为当前事实源。
- 明确 `docs/goal/` 只定义 Goal 驱动交付规则、状态机、Gate、Registry 和 Evidence，不复制完整模块规格。
- 明确 `.config/goal/` 是 Goal 控制面配置与审计快照目录；Goal 制品通过 ID 和路径引用 `module/`，本地运行态不作为 SSOT。

### 同步门禁

- 增补 `module/` 与 `docs/goal/` 的同步边界，禁止恢复旧 `specs/` 目录。
- 将旧路径扫描、`spec-lint.sh`、`status-consistency-check.sh`、`spec-drift-guard.sh`、`traceability-check.sh` 和 `task-spec-validate.sh` 作为当前同步验证基线。

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
