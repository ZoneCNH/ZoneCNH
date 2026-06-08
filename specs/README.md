# Foundation 与组合根规格索引

> 16 个基座模块的独立完整规格，加上 x.go 组合根规格；共 17 份规格，按架构层级组织。

最后更新：2026-06-08

---

## 分层总览

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

依赖方向：自上而下。同层模块平级协作，不存在编译期依赖。

---

## L0 原语（1 个）

stdlib-only 基础原语。所有上层模块的根依赖。

| 模块   | 规格                        | 核心职责                                                                                     |
| ------ | --------------------------- | -------------------------------------------------------------------------------------------- |
| kernel | [SPEC.md](./kernel/SPEC.md) | Module/App/Lifecycle、依赖图校验、拓扑序启动、优雅停机、error/time/context/health/validation |

---

## L1 运行时（4 个）

共享横切能力。可选依赖，按需引入。

| 模块       | 规格                            | 核心职责                                                                        |
| ---------- | ------------------------------- | ------------------------------------------------------------------------------- |
| configx    | [SPEC.md](./configx/SPEC.md)    | Reader/Manager/Provider、多源合并、schema 校验、脱敏、热加载                    |
| observex   | [SPEC.md](./observex/SPEC.md)   | Logger/Meter/Tracer/Exporter、label policy、metrics 命名规范                    |
| resiliencx | [SPEC.md](./resiliencx/SPEC.md) | Policy/Executor/Breaker、策略链（rate→bulkhead→circuit→timeout→retry→fallback） |
| schedulex  | [SPEC.md](./schedulex/SPEC.md)  | Scheduler/Job/Trigger/Locker、overlap/misfire 策略、DST 处理                    |

---

## L1 测试（1 个）

test-only，不参与生产运行时。

| 模块     | 规格                          | 核心职责                                                                   |
| -------- | ----------------------------- | -------------------------------------------------------------------------- |
| testkitx | [SPEC.md](./testkitx/SPEC.md) | Fake 实现、contract test harness、boundary scanner、goroutine leak checker |

---

## 门禁（2 个）

标准源和机器门禁，不参与运行时。

| 模块          | 规格                               | 核心职责                                                           |
| ------------- | ---------------------------------- | ------------------------------------------------------------------ |
| xlib-standard | [SPEC.md](./xlib-standard/SPEC.md) · [tasks/](./xlib-standard/tasks/) | 标准事实源、Go Reference Template、Generator、Harness Gate、Evidence Runtime（52 FR，12 tasks） |
| xlibgate      | [SPEC.md](./xlibgate/SPEC.md)      | CLI 门禁、import 边界扫描、Go baseline 对齐、release evidence 校验 |

---

## 存储扩展（7 个）

基础设施客户端封装。均为可选，按需引入。

| 模块        | 规格                             | 封装目标                            |
| ----------- | -------------------------------- | ----------------------------------- |
| redisx      | [SPEC.md](./redisx/SPEC.md)      | Redis — 缓存、分布式锁、Pub/Sub     |
| kafkax      | [SPEC.md](./kafkax/SPEC.md)      | Kafka — 消息队列、事件流            |
| natsx       | [SPEC.md](./natsx/SPEC.md)       | NATS — 内部通信、JetStream          |
| postgresx   | [SPEC.md](./postgresx/SPEC.md)   | PostgreSQL — 关系型存储、事务、迁移 |
| taosx       | [SPEC.md](./taosx/SPEC.md)       | TDengine — 时序数据写入与查询       |
| ossx        | [SPEC.md](./ossx/SPEC.md)        | 对象存储 — S3/MinIO/local 多后端    |
| clickhousex | [SPEC.md](./clickhousex/SPEC.md) | ClickHouse — OLAP 查询、批量写入    |

---

## 契约（1 个）

跨域稳定端口和事件协议。

| 模块      | 规格                           | 核心职责                                                                            |
| --------- | ------------------------------ | ----------------------------------------------------------------------------------- |
| contracts | [SPEC.md](./contracts/SPEC.md) | MarketDataProvider/MacroDataProvider 端口、事件协议、DTO 契约、breaking change 检测 |

---

## 组合根（1 个）

应用入口，负责配置加载、依赖组装和生命周期管理。

| 模块 | 规格                     | 核心职责                                               |
| ---- | ------------------------ | ------------------------------------------------------ |
| x.go | [SPEC.md](./xgo/SPEC.md) | 组合根 — 配置加载、模块 wiring、生命周期控制、优雅停机 |

---

## 规格结构约定

每个 SPEC.md 遵循统一结构（23 节），同时覆盖**结构性规格**（模块是什么）和**行为性规格**（模块做什么）：

### Part 1: 身份与范围

| 章节         | 说明                         |
| ------------ | ---------------------------- |
| 1. Metadata  | 状态、负责人、日期、关联文档 |
| 2. Summary   | 一句话描述                   |
| 3. Problem   | 解决什么痛点                 |
| 4. Goals     | 要实现什么                   |
| 5. Non-goals | 不做什么                     |

### Part 2: 行为契约

| 章节                       | 说明                          |
| -------------------------- | ----------------------------- |
| 6. Consumers               | 谁用这个模块（哪些模块/角色） |
| 7. Functional Requirements | 每个公共方法的 WHEN/THEN      |
| 8. Business Rules          | 不变量、校验规则              |

### Part 3: 技术契约

| 章节                    | 说明                      |
| ----------------------- | ------------------------- |
| 9. Interface Contract   | Go 接口 + 用法示例        |
| 10. Data Model          | 结构体、常量、错误变量    |
| 11. Config Schema       | 配置结构                  |
| 12. Error Handling      | 错误分类 + 调用方处理指南 |
| 13. Edge Cases          | 边界场景                  |
| 14. Directory Structure | 推荐的包布局              |

### Part 4: 质量契约

| 章节                   | 说明                                      |
| ---------------------- | ----------------------------------------- |
| 15. Dependencies       | 可以依赖 / 禁止依赖                       |
| 16. Testing            | 单元/集成/基准测试 + Given/When/Then 用例 |
| 17. Performance Budget | 延迟/吞吐目标                             |
| 18. Observability      | metrics/logs/traces 清单                  |
| 19. Security           | 密钥管理、输入校验、数据保护              |

### Part 5: 生命周期

| 章节                      | 说明                         |
| ------------------------- | ---------------------------- |
| 20. CI Gate               | 编译、测试、覆盖率、特定检查 |
| 21. Upgrade Compatibility | 向后兼容和迁移策略           |
| 22. Release DoD           | 可发布的验收清单             |

### Part 6: 开放

| 章节               | 说明       |
| ------------------ | ---------- |
| 23. Open Questions | 未决定的事 |

### 设计原则

- **一个 SPEC 只管一个模块**：不要一个 SPEC 写完整层
- **每个需求都要能被测试**：Functional Requirements 必须可验证
- **所有边界情况都写出来**：Edge Cases 不可省略
- **Non-goals 防止越界**：AI 代理必须遵守 Non-goals
- **Error Handling 是调用方视角**：不是模块自身故障，而是"调用方遇到这个错误该怎么办"
- **Acceptance Criteria 是统一验收清单**：从 CI Gate + DoD 合并而来

---

## Spec 系统总览

FoundationX 采用 5 层 spec 系统，驱动 AI 代理按 spec 施工：

```text
Product Spec（为什么做）       → docs/product/product-spec.md
  ↓
Feature Spec（功能怎么表现）   → specs/*/SPEC.md（23 节结构）
  ↓
Technical Spec（怎么实现）     → ARCHITECTURE.md + CONSTITUTION.md
  ↓
Task Spec（本次改什么）        → AI 按 prompt 模板拆分
  ↓
Prompt（让 AI 执行哪一步）     → docs/ai/prompt-templates.md
  ↓
Code → Test → PR
```

### 文档结构映射

| 层级           | 文档            | 位置                                                                                                                                                                               |
| -------------- | --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Product Spec   | 产品规格        | [`docs/product/product-spec.md`](../docs/product/product-spec.md)                                                                                                                  |
| Feature Spec   | 模块完整规格    | [`specs/*/SPEC.md`](#分层索引)（23 节结构）                                                                                                                                        |
| Technical Spec | 架构 + 宪法     | [`ARCHITECTURE.md`](../ARCHITECTURE.md) + [`CONSTITUTION.md`](../CONSTITUTION.md)                                                                                                  |
| Test Spec      | 测试策略        | [`docs/testing/test-strategy.md`](../docs/testing/test-strategy.md)                                                                                                                |
| Agent Spec     | AI 代理规格模板 | [`specs/AGENT-SPEC-TEMPLATE.md`](./AGENT-SPEC-TEMPLATE.md)（规则：[`agent-rules.md`](../docs/ai/agent-rules.md)、Prompt：[`prompt-templates.md`](../docs/ai/prompt-templates.md)） |

### 治理文件

| 文件                                                         | 用途                                                    |
| ------------------------------------------------------------ | ------------------------------------------------------- |
| [`DEFINITION-OF-READY.md`](./DEFINITION-OF-READY.md)         | spec 可以进入开发的前置条件                             |
| [`DEFINITION-OF-DONE.md`](./DEFINITION-OF-DONE.md)           | 模块实现完成的验收条件                                  |
| [`SPEC-TEMPLATE.md`](./SPEC-TEMPLATE.md)                     | 23 节结构模板 — 新建模块规格时复制本文件                |
| [`TRACEABILITY.md`](./TRACEABILITY.md)                       | 需求追踪表：FR → AC → TC → 实现                         |
| [`DEVELOPMENT-WORKFLOW.md`](./DEVELOPMENT-WORKFLOW.md)       | Spec → Ship 完整管线总览                                |
| [`PRE-DEVELOPMENT.md`](./PRE-DEVELOPMENT.md)                 | 开发前准备 — 实现策略、Task 拆分、追溯矩阵              |
| [`CODING-SESSION-PROTOCOL.md`](./CODING-SESSION-PROTOCOL.md) | 编码会话协议 — Context Packet、Plan-first、自查、Review |
| [`SPEC-DRIFT-PROTOCOL.md`](./SPEC-DRIFT-PROTOCOL.md)         | Spec Drift 处理 — 代码与 Spec 不一致时的协议            |
| [`TESTING-STRATEGY.md`](./TESTING-STRATEGY.md)               | 测试策略 — 从 Spec 生成测试、优先级、验收               |
| [`PR-TEMPLATE.md`](./PR-TEMPLATE.md)                         | PR/Issue/Branch/Commit 模板和命名规则                   |
| [`DEPLOYMENT.md`](./DEPLOYMENT.md)                           | 部署清单 — RC 检查、Smoke Test、CI 配置                 |
| [`REVIEW-STRATEGY.md`](./REVIEW-STRATEGY.md)                 | 审查策略 — 每层轻审查、转换点强审查、高风险点反审查    |

### Spec 状态流转

```text
Draft → Review → Approved → Implemented → Changed → Deprecated
```

完整状态机定义、流转规则、CI 集成点详见 [`LIFECYCLE.md`](./LIFECYCLE.md)。

---

## 相关文档

| 文档                                                                | 定位                                       |
| ------------------------------------------------------------------- | ------------------------------------------ |
| [`ARCHITECTURE.md`](../ARCHITECTURE.md)                             | 系统全局架构、依赖拓扑、设计原则           |
| [`CONSTITUTION.md`](../CONSTITUTION.md)                             | 模块宪法 — 13 条治理条款                   |
| [`docs/product/product-spec.md`](../docs/product/product-spec.md)   | 产品规格 — Vision、Users、Goals、MVP Scope |
| [`docs/testing/test-strategy.md`](../docs/testing/test-strategy.md) | 测试策略 — 覆盖率、格式、工具、CI 集成     |
| [`docs/ai/agent-rules.md`](../docs/ai/agent-rules.md)               | AI 代理规则 — 编码、测试、安全、禁止事项   |
| [`docs/ai/prompt-templates.md`](../docs/ai/prompt-templates.md)     | Prompt 模板 — 审查、拆分、实现、自查、修复 |
| [`module/foundation-modules.md`](../module/foundation-modules.md)   | Why & What — 模块定位和能力需求            |
| [`module/FOUNDATION-SPEC.md`](../module/FOUNDATION-SPEC.md)         | How & Check — 接口签名和 CI gate           |
| [`module/FOUNDATION-DEPS.yaml`](../module/FOUNDATION-DEPS.yaml)     | 机器可读依赖矩阵                           |
| [`module/FOUNDATION-V1.md`](../module/FOUNDATION-V1.md)             | v1 路线图                                  |

---

## AI 工作流速查

### 0. 端到端工作流

```text
$spec-code-pipeline <module>
/project:spec-code-pipeline <module>

Spec → Matrix → Tasks → Plan → Prompt → Code
```

Codex 使用 `.codex/skills/spec-code-pipeline/SKILL.md`，Claude Code 使用 `.claude/commands/spec-code-pipeline.md`。Matrix 前仍需 `spec-review` Go 判断和 `Status: Approved`。

### 1. Spec 审查

```markdown
请 review specs/<module>/SPEC.md。
重点检查：模糊需求、冲突要求、缺失边界、缺失验收标准、缺失测试用例。
输出：Blocking issues / Non-blocking suggestions / Ready or Not ready。
```

### 2. 任务拆分

```markdown
请根据 Approved 的 specs/<module>/SPEC.md 和 specs/<module>/TRACEABILITY.md 生成 implementation tasks。
每个 task 控制在 200 行以内，对应 requirement IDs / acceptance criteria / test cases。
```

### 3. 模块实现

```markdown
请根据 specs/<module>/TASK-<NNN>-PROMPT.md 实现当前 ready task。
上下文：SPEC.md + TRACEABILITY.md + task spec + IMPLEMENTATION-PLAN.md + AGENTS.md。
限制：只做当前 task 范围内的内容，不引入新依赖。
```

### 4. 自查

```markdown
请检查当前实现是否符合 spec。
输出：Requirement coverage table / AC result / Test coverage / Deviations。
```

详细 prompt 模板见 [`docs/ai/prompt-templates.md`](../docs/ai/prompt-templates.md)。
