# 产品/工具级 Spec

`docs/spec/` 存放由 `docs/goal/` 需求派生出来的产品级、工具级或控制面规格。它不是 `module/` 规格库，不承载模块源码需求，也不替代 `docs/governance/` 的 Spec -> Code 流程规则。

当前目录的主要用途是描述 Goal 体系自身工具的行为契约，例如 `goalctl` 这类本地命令控制面。此类规格必须说明自己从哪些 `docs/goal/` 权威需求派生，并保持只读解释边界：可以把 Goal、Spec、Matrix、Gate、Evidence、Registry、CI 等规则转化为可执行命令契约，但不能创建新的状态、Gate、ID、Registry、Matrix 或 Evidence 语义。

## 权威关系

| 事项 | 权威来源 | `docs/spec/` 职责 |
| --- | --- | --- |
| Goal 结构、状态与质量要求 | `docs/goal/02-goal-standard.md` | 引用 Goal 目标、成功标准、状态和可验证性要求 |
| Spec 层结构与需求原子化 | `docs/goal/05-layer-standards.md` | 把上游 Goal 需求拆成可测试的工具需求 |
| Gate 与阻塞语义 | `docs/goal/04-gates.md` | 描述命令如何检查 G0-G11，不新增 Gate |
| DoR / DoD | `docs/goal/06-dod.md` | 声明规格进入实现和完成验收的条件 |
| Lint 规则 | `docs/goal/10-lint-rules.md` | 保证 Requirement、Acceptance Criteria、测试链路可检查 |
| 权威边界 | `docs/goal/00-authority-map.md` | 明确 SSOT、投影、配置和运行态边界 |
| 机器可读规则 | `.config/goal/schema/rules.yaml` | 作为可执行校验规则镜像引用，不反向覆盖文档权威 |

## 编写要求

每个 `docs/spec/` 规格至少包含以下信息：

1. `Spec ID`、状态、版本、日期和输出位置。
2. `Source Goal` 或 `Source Requirement`，指向具体 `docs/goal/` 章节或配置权威。
3. 目标、非目标和权威映射。
4. 原子化 Requirement 与对应 Acceptance Criteria。
5. 正常路径、异常路径、边界场景、安全/权限/数据/性能约束。
6. Traceability，说明 Goal -> Spec -> Requirement -> Acceptance Criteria -> Test/Evidence 的映射。
7. 验证命令，以及无法验证时的记录方式。

## DoR / DoD

进入实现前必须满足：

1. 上游 Goal 或来源需求已声明，且不依赖 `module/` 目录作为事实源。
2. 权威边界明确，不把 `.config/goal/runtime/`、`.omx/state/` 或临时日志当作规范源。
3. 所有 Requirement 可实现、可测试、可追溯。

完成验收前必须满足：

1. 每个 Requirement 至少有一个 Acceptance Criteria。
2. 每个关键 Acceptance Criteria 能映射到测试、命令输出或 Evidence。
3. 规格没有新增 `docs/goal/` 之外的 Pipeline、Gate、ID、Registry、Matrix 或 Evidence 语义。
4. 相关 `docs/goal/tools/` 校验通过，或记录明确的失败原因、阻断等级和下一步入口。

## 当前规格

| Spec | 来源需求 | 状态 | 说明 |
| --- | --- | --- | --- |
| [goalctl-spec.md](goalctl-spec.md) | `docs/goal/` 控制面、Gate、Matrix、Evidence、Registry 与 Lint 需求 | Draft / Implementation Ready | Goal 驱动交付体系的本地命令控制面规格 |
