# module/ 代理工作指南

> AI 代理在 `module/` 目录下工作时的约束、工作流和速查参考。

最后更新：2026-06-12

---

## 本目录定位

`module/` 是 FoundationX 16 个基座模块的**规格制品 SSOT**（单一事实源），承载：

| 制品        | 路径                                    | 说明                 |
| ----------- | --------------------------------------- | -------------------- |
| 模块规格    | `module/{module}/SPEC.md`               | 23 节结构，功能规格  |
| 模块目标    | `module/{module}/goal.md`               | 1.0 发布定位与 DoD   |
| 追溯矩阵    | `module/{module}/TRACEABILITY.md`       | FR → AC → TC → 实现  |
| 任务拆分    | `module/{module}/tasks/`                | Task spec 目录        |
| 实现计划    | `module/{module}/IMPLEMENTATION-PLAN.md` | 实现顺序与依赖       |
| 开发 Prompt | `module/{module}/TASK-{NNN}-PROMPT.md`  | Context Packet        |
| 证据        | `module/{module}/evidence/`             | 验收证据             |

模块代码的本地工作目录统一为 `/home/{module}`，对应 GitHub 仓库 `github.com/ZoneCNH/{module}`。本目录只保存规格制品，不收纳模块源码。

---

## 最高指令源

当本文件与其他文档冲突时，优先级如下：

```
CONSTITUTION.md（§0-§19，系统级最高治理）
  ↓
AGENTS.md（根目录，仓库级代理编排与管线规则）
  ↓
module/AGENTS.md（本文件，module/ 目录级操作约束）
  ↓
module/README.md（模块索引与分层总览）
  ↓
module/{module}/SPEC.md（单个模块规格）
```

---

## 分支纪律（最高优先级）

> 详见 `CONSTITUTION.md` 第零条。本条优先级高于以下所有工作流规则。

- **禁止**在 `main` 分支直接编辑 `module/` 下任何文件。
- **所有变更必须**通过 `git worktree` 或 feature branch 进行。
- **所有分支必须从 `main` HEAD 创建**。创建前先执行 `git fetch origin && git rebase origin/main`。
- 工作完成后通过 PR 或 merge 合入 main，随后清理 worktree。

Agent 进入 `module/` 工作前必检：

1. 确认当前不在 main 分支
2. `git fetch origin && git rebase origin/main`
3. 从 main HEAD 创建 worktree 或 branch
4. 记录来源 commit SHA

---

## Spec 开发管线

`module/` 下的模块从 Spec 到 Code 遵循标准管线，每个阶段都必须通过四源评分门禁（Claude / Codex / Copilot / rules）：

```text
Spec → Matrix → Tasks → Plan → Prompt → Code
```

### 阶段速查

| 阶段      | 产物                        | 门禁                    | 模型   |
| --------- | --------------------------- | ----------------------- | ------ |
| S1-Spec   | `SPEC.md`（23 节）           | `composite_score >= 98` | Opus   |
| S2-Matrix | `TRACEABILITY.md`           | `composite_score >= 98` | Sonnet |
| S3-Tasks  | `tasks/TASK-*.md`           | `composite_score >= 98` | Sonnet |
| S4-Plan   | `IMPLEMENTATION-PLAN.md`    | `composite_score >= 98` | Opus   |
| S5-Prompt | `TASK-{NNN}-PROMPT.md`      | `composite_score >= 98` | Sonnet |
| S6-Code   | `/home/{module}/` 下源码+测试 | 验收 + 证据             | Sonnet |

### 触发方式

| 平台        | 命令                                   |
| ----------- | -------------------------------------- |
| Claude Code | `/project:spec-code-pipeline {module}`  |
| Codex       | `$spec-code-pipeline {module}`         |
| Copilot CLI | `/project:spec-code-pipeline {module}` |

---

## 模块规格结构（23 节）

每个 `module/{module}/SPEC.md` 必须包含以下全部章节。模板见 `docs/governance/SPEC-TEMPLATE.md`。

### Part 1: 身份与范围

| 节号 | 标题      | 说明                         |
| ---- | --------- | ---------------------------- |
| 1    | Metadata  | 状态、负责人、日期、关联文档 |
| 2    | Summary   | 一句话描述                   |
| 3    | Problem   | 解决什么痛点                 |
| 4    | Goals     | 要实现什么                   |
| 5    | Non-goals | 不做什么                     |

### Part 2: 行为契约

| 节号 | 标题                    | 说明                      |
| ---- | ----------------------- | ------------------------- |
| 6    | Consumers               | 谁用这个模块              |
| 7    | Functional Requirements | 每个公共方法的 WHEN/THEN  |
| 8    | Business Rules          | 不变量、校验规则          |

### Part 3: 技术契约

| 节号 | 标题                | 说明                      |
| ---- | ------------------- | ------------------------- |
| 9    | Interface Contract  | Go 接口 + 用法示例        |
| 10   | Data Model          | 结构体、常量、错误变量    |
| 11   | Config Schema       | 配置结构                  |
| 12   | Error Handling      | 错误分类 + 调用方处理指南 |
| 13   | Edge Cases          | 边界场景                  |
| 14   | Directory Structure | 推荐的包布局              |

### Part 4: 质量契约

| 节号 | 标题               | 说明                                  |
| ---- | ------------------ | ------------------------------------- |
| 15   | Dependencies       | 可以依赖 / 禁止依赖                   |
| 16   | Testing            | 单元/集成/基准测试 + Given/When/Then  |
| 17   | Performance Budget | 延迟/吞吐目标                         |
| 18   | Observability      | metrics/logs/traces 清单              |
| 19   | Security           | 密钥管理、输入校验、数据保护          |

### Part 5: 生命周期

| 节号 | 标题                  | 说明                     |
| ---- | --------------------- | ------------------------ |
| 20   | CI Gate               | 编译、测试、覆盖率、检查 |
| 21   | Upgrade Compatibility | 向后兼容和迁移策略       |
| 22   | Release DoD           | 可发布的验收清单         |

### Part 6: 开放

| 节号 | 标题           | 说明       |
| ---- | -------------- | ---------- |
| 23   | Open Questions | 未决定的事 |

### 设计原则

- **一个 SPEC 只管一个模块**——不要一个 SPEC 写完整层
- **每个需求都要能被测试**——FR 必须可验证
- **所有边界情况都写出来**——Edge Cases 不可省略
- **Non-goals 防止越界**——AI 代理必须遵守 Non-goals
- **Error Handling 是调用方视角**——不是模块自身故障，而是"调用方遇到这个错误该怎么办"

---

## Goal 文档规则

- 模块级 Goal 文档固定为 `module/{module}/goal.md`。
- **禁止**新建 `module/{module}/goal/` 目录、`module/{module}/goal/1.md` 或 `goal/*.md` 多文件槽位。
- 未来如需多版本 Goal，必须先更新 `docs/goal/00-authority-map.md`、`.config/goal/schema/rules.yaml` 和 `module/README.md`。

---

## 依赖矩阵

`module/FOUNDATION-DEPS.yaml` 是机器可读依赖矩阵，定义允许/禁止的依赖边与特殊约束。

Agent 在新增模块间依赖之前，必须：
1. 检查 `FOUNDATION-DEPS.yaml` 是否允许该依赖边
2. 如不兼容，先提出矩阵修改方案
3. 更新 `ARCHITECTURE.md` 中的依赖图

---

## 常见工作流

### 1. 创建新模块规格

```markdown
请根据 docs/governance/SPEC-TEMPLATE.md 模板，为 module/{new-module}/ 创建 SPEC.md。
上下文：ARCHITECTURE.md + CONSTITUTION.md + FOUNDATION-DEPS.yaml。
填充全部 23 节。Status 设为 Draft。
```

### 2. 审查现有规格

```markdown
请审查 module/{module}/SPEC.md。
检查：模糊需求、冲突要求、缺失边界、缺失验收标准、缺失测试用例。
输出：Blocking issues / Non-blocking suggestions / Ready or Not ready。
```

### 3. 任务拆分

```markdown
请根据 Approved 的 module/{module}/SPEC.md 和 module/{module}/TRACEABILITY.md
生成 implementation tasks。每个 task 控制在 200 行以内，
对应 requirement IDs / acceptance criteria / test cases。
```

### 4. 模块实现

```markdown
请根据 module/{module}/TASK-{NNN}-PROMPT.md，在 /home/{module} 对应代码仓库中
实现当前 ready task。
上下文：SPEC.md + TRACEABILITY.md + task spec + IMPLEMENTATION-PLAN.md。
限制：只做当前 task 范围内的内容，不引入新依赖。
```

### 5. 结构评分

```markdown
请对 module/{module}/ 当前阶段的产物进行结构评分。
读取 docs/governance/scoring/RUBRIC-{stage}.md，输出红线、扣分账本和评分。
```

### 6. 阶段自改进（最多 3 次）

同阶段最多 3 次自动修复，失败后回退上游。全链路默认最多 18 次 gate fail，耗尽后写出 `pipeline_blocked` 与 `PIPELINE-RETROSPECTIVE.md`，不得无限重写。

---

## 关键文档速查

| 文档                                                  | 用途                          |
| ----------------------------------------------------- | ----------------------------- |
| `module/README.md`                                    | 模块索引与分层总览            |
| `module/FOUNDATION-DEPS.yaml`                         | 依赖矩阵（机器可读）          |
| `module/FOUNDATION-SPEC.md`                           | Foundation 接口签名与 CI gate |
| `module/FOUNDATION-TRACKER.md`                        | v1 执行跟踪器（issue 级）     |
| `module/FOUNDATION-V1.md`                             | v1 路线图                     |
| `../CONSTITUTION.md`                                  | 系统宪法（最高治理）          |
| `../ARCHITECTURE.md`                                  | 全局架构、依赖拓扑、设计原则  |
| `../AGENTS.md`                                        | 仓库级代理编排与管线规则      |
| `../docs/governance/SPEC-TEMPLATE.md`                 | 23 节规格模板                 |
| `../docs/governance/DEVELOPMENT-WORKFLOW.md`          | Spec → Ship 完整管线          |
| `../docs/governance/TRACEABILITY.md`                  | 追溯矩阵规范                  |
| `../docs/governance/DEFINITION-OF-READY.md`           | 进入开发的前置条件            |
| `../docs/governance/DEFINITION-OF-DONE.md`            | 完成验收条件                  |
| `../docs/governance/STRUCTURAL-SCORING.md`            | 结构评分方法论                |
| `../docs/governance/scoring/ARBITER-PROTOCOL.md`      | 四源评分仲裁协议              |
| `../docs/governance/CODING-SESSION-PROTOCOL.md`       | 编码会话协议                  |
| `../docs/goal/00-quickstart.md`                       | Goal 体系快速开始             |

---

## 模块分层速查

```text
标准源 ──→ 门禁校验 ──→ L0 原语 ──→ L1 运行时 / 测试 ──→ 存储扩展 / 契约
 xlib-standard    xlibgate       kernel    configx            redisx        contracts
                  (CI gate)               observex            kafkax
                                          resiliencx          natsx
                                          schedulex           postgresx
                                          testkitx            taosx
                                                              ossx
                                                              clickhousex
```

- **L0 原语**（kernel）：stdlib-only 基础原语，所有上层模块的根依赖
- **L1 运行时**（configx / observex / resiliencx / schedulex）：共享横切能力，可选依赖
- **L1 测试**（testkitx）：test-only，不参与生产运行时
- **门禁**（xlib-standard / xlibgate）：标准源和 CI gate，不参与运行时
- **存储扩展**（redisx / kafkax / natsx / postgresx / taosx / ossx / clickhousex）：基础设施客户端封装
- **契约**（contracts）：跨域稳定端口和事件协议

---

## Agent 行为约束

### 必须遵守

1. 编辑 `module/` 下文件前，确认在 worktree 或 feature branch 中，不在 main
2. 新增模块必须先建立 `module/{module}/` 目录，包含至少 `SPEC.md` 和 `goal.md`
3. 修改 SPEC.md 时必须保持完整的 23 节结构
4. 新增模块间依赖前检查 `FOUNDATION-DEPS.yaml`
5. 提交信息使用 Conventional Commits 格式 + 中文描述（如 `docs: 更新 kernel SPEC.md FR 列表`）
6. 所有输出和文档默认使用中文，保留英文模块名和技术名词

### 禁止事项

1. 禁止在 main 分支直接编辑任何文件
2. 禁止创建 `module/{module}/goal/` 目录或多文件 Goal
3. 禁止一个 SPEC.md 覆盖多个模块
4. 禁止删除或跳过 23 节中的任何一节
5. 禁止提交凭证、API key、账户 ID、私有端点或实盘配置
6. 禁止从非 main HEAD 的分支创建新 worktree 或 branch
