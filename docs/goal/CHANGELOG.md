# 变更日志

> 记录 docs/goal/ 体系的重大结构性变更。

## 2026-06-12 — 文档清理与 RSI 标准归档

- 删除 `docs/raw/1.md`（外部审计反馈，核心建议已通过 Schema 权威化工作落地）
- 归档 `docs/RSI_complete_standard_zh.md` → `docs/goal/26-rsi-full-standard.md`（RSI-SG-001，完整 RSI 分级标准）
- `00-authority-map.md`：新增 `26-rsi-full-standard.md` 权威行
- `21-controlled-rsi.md`：末尾增加完整 RSI 标准的交叉引用

---

## 2026-06-12 — P2 跨平台验证

### 跨平台 Agent 审计

- 新增 `docs/goal/agent-cross-platform-compatibility.md`：Claude / Copilot / Codex 三平台 Agent 兼容性报告（Agent 存在性矩阵、文档引用一致性、MUST 语义等价、详细度差异）
- 修复 `.codex/agents/goal-spec.toml`：4 处幻影文档引用 → 对齐真实文件（`02-goal-schema.md`→`02-goal-standard.md`, `07-human-approval.md`→`06-dod.md`, `09-tasks-and-prompt.md`→`09-templates.md`）
- 修复 `.codex/agents/goal-prompt-builder.toml`：1 处幻影引用 → `09-templates.md`
- Copilot CLI 全量 Smoke：lint-goal.sh / goal-validate.py / matrix-gen.py / self-test.sh 45/45 PASS，跨路径兼容 OK
- `24-standard-unification-analysis.md`：新增 Agent 跨平台维度（80），综合评分 80→81/100

---

## 2026-06-12 — Schema 权威化 Phase 1

### 新增 Schema 文件

- 新增 `docs/goal/schema/goal.schema.yaml`：canonical Goal 对象 schema，定义 18 个字段的完整类型/正则/枚举/必填属性，包含标准→模板→Registry 三源字段映射表
- 新增 `docs/goal/schema/matrix.schema.yaml`：canonical Matrix edge schema，定义 14 个 canonical 字段、8 个控制面 relation、9 个状态枚举、覆盖率阈值和合格标准
- 新增 `docs/goal/schema/evidence.schema.yaml`：canonical Evidence schema，统一 Evidence 文件（11 个必填字段）和 Evidence Bundle（17 个必填字段），消除 evidence-collect.sh 与 gate-check.sh 的字段漂移
- 新增 `docs/goal/schema/state-dictionary.yaml`：统一状态字典，将 5 种状态命名风格归并为 4 类（lifecycle_status / runtime_phase / gate_result / metric_conclusion），定义唯一大小写和允许值

### 文档对齐

- `07-id-system.md` 新增 §4：明确 ID 后缀 `vN` 与文档 `version` 字段的区分
- `02-goal-standard.md` 新增 §12：Schema 权威引用 + 字段来源标注表
- `09-templates.md`：Goal/Matrix/Evidence 模板增加 schema 引用注释
- `10-lint-rules.md` 新增 §7：35 条规则的实现状态表（16 implemented / 7 manual / 12 planned）+ 规则→工具映射
- `24-standard-unification-analysis.md`：新增 2026-06-12 修复进展，修订统一度评分从 66→78/100

### 控制面与工具

- `.config/goal/schema/rules.yaml`：增加 4 个 schema 文件引用 + 各段 canonical_schema 指针 + state_dictionary 段
- `.config/goal/registry/goals.yaml`：增加字段映射注释
- `evidence-collect.sh`：增加 evidence.schema.yaml 引用
- `gate-check.sh`：增加 evidence.schema.yaml + matrix.schema.yaml 引用
- `lint-goal.sh`：排除 `docs/goal/schema/` 目录，防止 schema 定义文件被误判为数据文件

### 验证

- `goal-workflow.sh preflight` — PASS（0 errors）
- `goal-workflow.sh validate` — PASS（0 errors）
- `goal-validate.py --mode strict` — PASS
- `matrix-gen.py --check-only` — PASS（64 edges, 100% 覆盖率）
- `self-test.sh` — PASS（45/45）

## 2026-06-11 — 模块只读分析快照 allowlist 对齐

- 明确 `module/{module}/` 可保存受规则 allowlist 约束的只读分析快照，但仍禁止实现源码树、vendor 源码或从 `/home/{module}` 复制出的模块代码。
- 将 `ANALYSIS.md`、`FR-DETAIL.md`、`CONFLICT-LEDGER.md`、`COVERAGE-MANIFEST.md`、`REMOTE-EVIDENCE.md`、`REVIEW-VERDICT.md`、`SNAPSHOT-BOUNDARY.md` 和 `analysis/` 投影到 `.config/goal/schema/rules.yaml`。
- 用于承载 `xlib-standard` 上游标准快照与追溯证据，不放宽 Code 交付边界。

## 2026-06-11 — Release 快照调和与反向阻断校验

- 调和 Risk Registry、Gate risk metadata、Pipeline state 和 Release Registry，使 G10 / G11 PASS 与已关闭 release_blocking 风险保持一致。
- `goal-validate.py` 新增反向一致性检查：无 `Open` / `Escalated` release_blocking 风险且 G10 / G11 PASS 时，Pipeline 不得继续 `BLOCKED`，Release 不得停留在 `in_review` / `rejected`。
- `self-test.sh` 增加 stale release snapshot 回归用例，`25-execution-guide.md` 与 `17-risk-and-decisions.md` 增加状态快照调和规则。

## 2026-06-11 — Goal 权威与 Agent 投影同步

- G10 / Release Gate 的必备输入显式补齐 `validation summary`，并与 schema 中的 release blocking condition 保持一致。
- `00-authority-map.md` 移除不存在的 `todo.md` 证据落点，改为 Change Request、Evidence Bundle 或交付报告。
- 新增 `.codex/agents/goal-*.toml`，使 Codex Goal Agent 投影与 Claude Goal Agent、`docs/goal/14-agent-protocols.md` 和 `.config/goal/schema/rules.yaml` 对齐。
- 新增 `.copilot/agents/goal-*.md`，使 Copilot Goal prompt 投影覆盖 `goal-spec`、`goal-reviewer`、`goal-matrix`、`goal-prompt-builder` 和 `goal-evidence`；`.copilot/AGENTS.md` 明确这些文件只是 `docs/goal/` 的平台投影。
- 修正 Claude `goal-matrix` 与 `goal-prompt-builder` 的旧 row model、旧路径、旧状态推进和 Gate 可跳过表述。
- 更新 `CR-20260610-goal-protected-assets-sync.md`；Copilot Goal Agent 投影缺口已关闭，但 Copilot CLI 运行时 smoke 仍需单独验证。

## 2026-06-11 — Goal CI self-hosted runner 合同固化

### CI 可执行性

- 统一 Goal workflow、工具文档示例与 validator fixture 到 `[self-hosted, Linux, X64, homepage]`，固定使用当前仓库已登记的项目 self-hosted runner。
- 将缺少 `homepage` 标签的通用 self-hosted runner 选择登记为 validator 阻断条件，防止 workflow 在首个 step 前落到不合格 runner。
- 将 self-hosted runner、workspace-local tool cache 与 toolchain setup 写入 schema、validator 和 self-test，防止回退 hosted runner 或依赖全局 Python/pip 状态。
- 明确 `/opt/hostedtoolcache` 首步前失败是 self-hosted runner 基础设施阻断，不得通过切换 hosted runner、跳过 Gate 或放宽 validator 规避。
- 为缺少 `python3-venv` / `ensurepip` 的 self-hosted runner 固化 workspace-local `pip --target` fallback；fallback 仍由 `setup-ci-toolchain.sh` 管理，不放宽 Gate 或依赖全局包。

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
