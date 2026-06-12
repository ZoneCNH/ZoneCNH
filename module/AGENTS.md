# Module 层代理工作指南

> 本文件指导 AI 代理在 `module/` 目录下的文档编写、审查和维护工作。当本文件与 `CONSTITUTION.md` 冲突时，以 `CONSTITUTION.md` 为准。

## 权威层级

代理在遇到模块文档矛盾时，必须按以下顺序裁决：

1. **CONSTITUTION.md**（最高权威）— §1.1 十三条设计原则定义每个模块的核心身份
2. **ARCHITECTURE.md**（第二权威）— 展开宪法中的简写为完整实现定义
3. **module/README.md**（索引权威）— 模块分类、分层、依赖方向
4. **模块级 goal.md + SPEC.md**（模块权威）— 单个模块的定位与可执行规格

### 关键宪法条款速查

| 条款 | 含义                                                               | 涉及模块                |
| ---- | ------------------------------------------------------------------ | ----------------------- |
| P1   | Foundation 先边界后功能                                            | xlib-standard, xlibgate |
| P2   | xlib-standard 不是运行时依赖，是标准事实源/模板/Gate/Evidence 输入 | xlib-standard           |
| P3   | resiliencx 只做运行时弹性                                          | resiliencx              |
| P4   | testkitx 只能 test-only                                            | testkitx                |

## xlib-standard 五角色定义（权威参考）

经过 2026-06-11 文档矛盾修复和对齐，xlib-standard 的权威定义为五类职责：

| 角色                      | 职责                               | 交付物                                                           |
| ------------------------- | ---------------------------------- | ---------------------------------------------------------------- |
| **Standard Source**       | xlib 体系的文档规范与工程标准      | docs/standard/ 下 8 大标准域                                     |
| **Go Reference Template** | 可编译、可测试的 Go 基础库参考模板 | pkg/templatex/ 下 Config/Error/Health/Metrics/Client/Version API |
| **Generator**             | 模板渲染与独立 Go module 生成      | render_template.sh + 生成库结构                                  |
| **Harness Gate**          | CI 门禁与边界检查                  | make ci（9 gate）+ boundary/contracts check                      |
| **Evidence Runtime**      | release manifest 与发布证据生成    | release_check.sh → latest.json + .sha256                         |

**关键区分**：xlib-standard 不承载**业务运行**，但它有可执行交付物（模板代码、生成器脚本、gate 命令、evidence manifest）。"没有业务运行时代码" ≠ "纯文档"。

引用此定义时：

- 使用 **五类职责** 或 **五角色**（不是 "4 项职责"）
- 不得声称 `Runtime 代码不适用`（正确表述：`不承载业务运行`）
- 不得声称 `不追求提供运行时代码`（正确表述：`通过 Go 参考模板、代码生成器、Harness Gate 和 Evidence Runtime 让标准可编译、可执行、可验证`）

## 模块目录结构

每个模块目录 `module/{module}/` 的标准结构：

```text
module/{module}/
├── goal.md            # 模块 1.0 Goal 定位（必须，单文件）
├── SPEC.md            # 可执行规格（必须，23 节结构）
├── README.md          # 模块分析索引与入口说明
├── TRACEABILITY.md    # 需求追溯矩阵（FR→AC→TC→Evidence）
├── PLAN.md            # 根级实现计划（供 scorer 读取）
├── tasks/             # 任务 spec（TASK-{MODULE}-NNN.md）
├── prompt/            # Context Packet（PROMPT-{MODULE}-NNN.md）
├── plan/              # 历史执行计划（可归档）
├── analysis/          # 本地分析快照
└── evidence/          # 测试证据
```

### 文档角色区分

| 文档              | 性质                                      | 读者                    |
| ----------------- | ----------------------------------------- | ----------------------- |
| `goal.md`         | 模块定位与 1.0 发布标准（是什么、为什么） | 架构负责人、模块 Owner  |
| `SPEC.md`         | 可执行功能规格（做什么、怎么验证）        | 开发者、评审者、AI 代理 |
| `README.md`       | 模块级索引与快照说明                      | 所有读者                |
| `TRACEABILITY.md` | 条款级来源矩阵                            | 治理审计、评分管线      |

## 模块定位规则

### 定位描述必须与宪法一致

每个模块的 `goal.md` 和 `SPEC.md` 中的定位描述必须与 CONSTITUTION.md §1.1 的对应条款一致：

- **xlib-standard**：五类职责（见上文），不承载业务运行
- **xlibgate**：机器门禁，check imports/gomod/baseline/release/all
- **kernel**：L0 原语，stdlib-only，Module/App/Lifecycle
- **resiliencx**：L1 运行时弹性，timeout/retry/circuit/bulkhead/rate/fallback
- **testkitx**：L1 test-only，FakeConfig/FakeLogger/FakeMeter/FakeTracer

### 模块间引用

- 引用其他模块时，使用 `https://github.com/ZoneCNH/{module}` 格式
- 引用 xlib-standard 时，应指向其五角色定义而非过时的 "4 项职责" 模型
- 跨域依赖必须符合 `FOUNDATION-DEPS.yaml` 中声明的允许依赖边

## 文档同步规则

### 架构变更时的同步链

当修改模块定位或职责时，必须同步更新：

1. `module/{module}/goal.md` — 模块定位
2. `module/{module}/SPEC.md` — 功能规格
3. `module/README.md` — 模块索引表中的核心职责列
4. `ARCHITECTURE.md` — 状态表、依赖图、角色定义
5. `CONSTITUTION.md` — 如涉及原则变更（需 ADR）

### 组件计数一致性

`ARCHITECTURE.md` 中的组件数量标注（如 `market-data (19)`）必须与实际表格行数一致。修改后运行：

```bash
.github/ci/status-consistency-check.sh
```

## Spec 编写规范

### 23 节结构

每个 SPEC.md 遵循统一结构。模板见 `docs/governance/SPEC-TEMPLATE.md`。

### 关键检查清单

编写或修改 SPEC.md 时必须检查：

- [ ] Metadata 状态、版本、日期完整
- [ ] Goals 表每项可追溯（Trace 列不为空）
- [ ] Non-goals 明确排除范围，防止 AI 代理越界
- [ ] Functional Requirements 使用 WHEN/THEN 格式
- [ ] Acceptance Criteria 可测试、可验证
- [ ] Test Cases 覆盖所有 FR 和边界场景
- [ ] Constitution Compliance 表完整

## 常见陷阱

### ❌ 禁止

| 陷阱                                  | 正确做法                         |
| ------------------------------------- | -------------------------------- |
| 描述 xlib-standard 为 "4 项职责"      | 使用 "五类职责" / "五角色"       |
| 声称 xlib-standard "不提供运行时代码" | "不承载业务运行，有可执行交付物" |
| 将 Evidence Runtime 列为 non-goal     | Evidence Runtime 是五角色之一    |
| 从非 main 分支创建新分支              | 必须从 main HEAD 创建            |
| 在 main 上直接编辑                    | 使用 worktree 或 feature branch  |
| 新建 `module/{module}/goal/` 目录     | goal.md 固定为单文件             |

### ⚠️ 注意

- **矛盾≠错误**：SPEC.md 和 goal.md 可能各描述了同一模块的不同侧面。先对照 CONSTITUTION 裁决，不要直接 "调和"
- **修复前先分类**：区分实质矛盾（必须修）、粒度差异（以上游为准）、术语角度差异（装饰性，可保留）
- **历史文档加归档标记**：不删除历史计划/任务，而是在文件头添加 `⚠️ 归档警告` 并指向当前权威定义
- **goal.md 固定单文件**：禁止创建 `goal/` 子目录或多文件槽位

### ⚡ 效率规则

- **一文件一次编辑**：列出该文件所有变更后一次性完成，禁止反复修改同一文件
- **同模块聚合 PR**：同一模块的所有文档修复 → 1 个 PR，禁止每个小修改单独 PR
- **变更 > 30% 直接重写**：优先 `Write` 替代多次 `Edit`
- **分析完再动手**：读完所有相关文件、列出完整变更清单后再开始编辑

## 验证命令

```bash
# 检查模块文档一致性
.github/ci/spec-lint.sh
.github/ci/spec-drift-guard.sh
.github/ci/status-consistency-check.sh
.github/ci/traceability-check.sh

# 检查模块引用完整性
.github/ci/task-spec-validate.sh

# 全局扫描过期语言
grep -rn "4 项职责\|Runtime 代码不适用\|不追求提供运行时" module/ --include="*.md" | grep -v "plan/PLAN.md" | grep -v "retrospective"
```

## 相关文档

| 文档                                      | 用途                     |
| ----------------------------------------- | ------------------------ |
| `CONSTITUTION.md`                         | 最高治理条款（§0-§19）   |
| `ARCHITECTURE.md`                         | 架构图、依赖拓扑、状态表 |
| `module/README.md`                        | 模块规格索引与分层总览   |
| `AGENTS.md`                               | 仓库级代理工作指南       |
| `docs/governance/SPEC-TEMPLATE.md`        | 23 节 spec 模板          |
| `docs/governance/TRACEABILITY.md`         | 追溯矩阵规范             |
| `docs/governance/DEVELOPMENT-WORKFLOW.md` | Spec → Ship 完整管线     |
