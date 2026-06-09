# Goal 配置中心

> 本目录是 Goal Control Plane 的可提交配置、schema 与审计快照目录；不是所有本地 runtime state 的唯一存放处。私有或临时运行状态应写入 `.config/goal/runtime/` 或 `.omx/state/`，并按仓库策略忽略提交。

## 目录结构

```text
.config/goal/
├── README.md              # 本文件
├── schema/                # 机器可读规则投影
│   └── rules.yaml         # docs/goal/ 权威规则的机器可读投影
├── registry/              # Registry 子系统：固定 6 个业务索引文件
│   ├── goals.yaml         # Goal Registry
│   ├── tasks.yaml         # Task Registry
│   ├── issues.yaml        # Issue Registry
│   ├── releases.yaml      # Release Registry
│   ├── risks.yaml         # Risk Registry
│   └── decisions.yaml     # Decision Registry
├── matrix/                # 配置中心旁路组件：追溯矩阵
│   └── matrix.yaml        # Traceability Matrix
├── evidence/              # 配置中心旁路组件：证据文件
│   └── EVID-*.md          # Evidence 文件
├── prompts/               # 配置中心旁路组件：Prompt 版本
│   └── TASK-*/            # 按 Task 分组
│       ├── v1.md
│       └── prompt-meta.yaml
├── gates/                 # 配置中心旁路组件：Gate 状态
│   └── state.yaml         # Gate 状态记录
├── pipeline/              # 配置中心旁路组件：流水线状态快照
│   └── state.yaml         # Pipeline 状态快照
└── runtime/               # 本地/临时运行态，忽略提交
```

## Registry 边界

Registry 子系统只包含 `.config/goal/registry/` 下的 6 个业务索引文件：`goals.yaml`、`tasks.yaml`、`issues.yaml`、`releases.yaml`、`risks.yaml`、`decisions.yaml`。

`schema/`、`matrix/`、`gates/`、`pipeline/`、`evidence/`、`prompts/` 是配置中心旁路组件。它们承载规则投影、追溯、门禁、运行状态快照、证据和上下文包版本，可被 Registry 记录引用，但不属于 Registry 子系统。

因此 Registry 数量门禁只作用于 `registry/` 下的 6 个 YAML；旁路组件由 Matrix、Gate、Pipeline、Evidence、Prompt 规则独立校验。

## 权威与投影来源

`.config/goal/` 中的 YAML 和 Markdown 是控制面配置或审计快照。它们可以引用、镜像和校验 `docs/goal/` 权威文档，但不得反向定义新的状态枚举、Gate、ID、Registry 结构、Matrix 规则或 Evidence 协议。

| 文档 | 用途 |
|------|------|
| `docs/goal/00-authority-map.md` | 权威边界和配置/runtime 边界 |
| `.config/goal/schema/rules.yaml` | 机器可读规则投影 |
| `docs/goal/15-registry.md` | Registry 6 个业务索引文件边界定义 |
| `docs/goal/05-layer-standards.md §9` | Matrix 标准 |
| `docs/goal/13-runtime-engine.md §4` | Evidence Protocol |
| `docs/goal/04-gates.md` | Gate 定义 |
| `docs/goal/03-pipeline.md` | Pipeline 四轴状态模型与状态机 |

## Git 提交边界

| 路径 | 策略 | 说明 |
|------|------|------|
| `.config/goal/README.md` | 提交 | 控制面索引与边界说明 |
| `.config/goal/schema/` | 提交 | `docs/goal/` 权威规则的机器可读投影 |
| `.config/goal/registry/` | 提交 | Registry 审计快照和业务索引 |
| `.config/goal/matrix/` | 提交 | Traceability Matrix 快照 |
| `.config/goal/gates/` | 提交 | Gate 评审事实快照 |
| `.config/goal/pipeline/` | 提交 | Pipeline 状态快照 |
| `.config/goal/evidence/` | 提交 | Evidence 审计文件 |
| `.config/goal/prompts/` | 提交 | Prompt 与 Context Package 版本 |
| `.config/goal/runtime/` | 忽略 | 本地执行上下文、恢复缓存和临时状态 |
| `.config/goal/**/locks/`, `.config/goal/**/local/`, `.config/goal/**/cache/`, `.config/goal/**/logs/` | 忽略 | 锁、本地覆盖、缓存和日志 |
| `.config/goal/**/*.lock`, `.config/goal/**/*.tmp`, `.config/goal/**/*.log` | 忽略 | 临时文件和运行日志 |

禁止在 `.config/goal/` 提交凭证、API key、账户 ID、私有端点、实盘交易配置或个人本地路径。本地敏感值只允许进入 ignored runtime/local 路径或外部密钥管理系统。

## Agent 写入边界

每个 Agent 只写入自己负责的文件，读取不限：

| Agent | 写入文件 | 职责 |
|-------|----------|------|
| goal-spec | `registry/goals.yaml`, `registry/tasks.yaml`, `registry/issues.yaml`, `registry/releases.yaml`, `registry/risks.yaml`, `registry/decisions.yaml`, `pipeline/state.yaml` | Goal/Task/Issue/Release/Risk/Decision 生命周期管理，Pipeline 状态推进 |
| goal-matrix | `matrix/matrix.yaml` | 追溯矩阵生成、更新、覆盖率验证 |
| goal-reviewer | `gates/state.yaml` | Gate 状态检查与记录 |
| goal-prompt-builder | `prompts/TASK-*/v*.md`, `prompts/TASK-*/prompt-meta.yaml` | Context Package 构建与版本管理 |
| goal-evidence | `evidence/EVID-*.md` | 证据收集、验证、Failure Budget 管理 |

**并发规则**：
- 不同 Agent 写入不同文件，无冲突
- 同一文件只由一个 Agent 写入
- 所有 Agent 可读取任意文件

## 状态同步

当状态变更时，相关 Agent 应更新对应文件：

| 变更对象 | 更新文件 |
|----------|----------|
| Goal 创建/更新 | `registry/goals.yaml` |
| Task 创建/完成 | `registry/tasks.yaml` |
| Issue 状态变更 | `registry/issues.yaml` |
| Release 准备 | `registry/releases.yaml` |
| 风险识别 | `registry/risks.yaml` |
| 决策记录 | `registry/decisions.yaml` |
| Matrix 更新 | `matrix/matrix.yaml` |
| Evidence 收集 | `evidence/EVID-*.md` |
| Gate 检查 | `gates/state.yaml` |
| Pipeline 状态快照 | `pipeline/state.yaml` |
| Runtime 执行上下文 | `.config/goal/runtime/` 或 `.omx/state/` |
