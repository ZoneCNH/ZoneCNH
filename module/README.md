# Foundation 模块规格索引

> 17 个基座模块的独立完整规格，按架构层级组织。`x.go` 组合根不再作为 `module/` 下的模块规格维护。

最后更新：2026-06-14

---

## 同步口径

- `module/` 是当前仓库的模块规格制品 SSOT：承载 `module/*/SPEC.md`、`module/*/TRACEABILITY.md`、`module/*/tasks/` 和模块实现计划；`docs/governance/` 是 Spec → Code 治理、模板、门禁和评分规则 SSOT。
- 模块级 Goal 文档固定为 `module/{module}/goal.md`；禁止使用 `module/{module}/goal/` 目录、`module/{module}/goal/1.md` 或 `goal/*.md` 多文件槽位。
- `module/{module}/` 只保存 Goal、Spec、Traceability、Task、Plan、Prompt、Evidence 等交付制品；对应模块代码仓库的本地工作目录统一为 `/home/{module}`。
- `docs/goal/` 是 Goal 驱动交付规则 SSOT；`.config/goal/` 是 Goal 运行状态、Registry、Gate、Evidence 和 Prompt 版本的 SSOT。
- Goal 制品通过 ID 和路径引用 `module/`，不复制完整模块规格；根目录 `README.md`、`ARCHITECTURE.md`、`STATUS.md` 与三平台 agent 配置只做索引和执行入口同步。
- 同步验证以旧路径扫描、`git diff --check`、`.github/ci/spec-lint.sh`、`.github/ci/status-consistency-check.sh`、`.github/ci/spec-drift-guard.sh`、`.github/ci/traceability-check.sh` 和 `.github/ci/task-spec-validate.sh` 为准；不得重新引入 `specs/`。

---

## 分层总览

```text
标准源 ──→ 门禁校验 ──→ L0 原语 ──→ L1 运行时 / 测试 ──→ 存储扩展 / 契约 / 传输
 xlib-standard    xlibgate       kernel    configx            redisx        contracts
                  (CI gate)               observex            kafkax
                                          resiliencx          natsx
                                          schedulex           postgresx
                                          testkitx            taosx
                                                              ossx
                                                              clickhousex
                                                              transportx
```

依赖方向：自上而下。同层模块平级协作，不存在编译期依赖。

---

## Goal 文档索引

命名规则：每个模块最多一个 `goal.md`，路径固定为 `module/{module}/goal.md`。

以下 `goal.md` 来自 `/home/zone/Downloads/xlib-v1.0-module-goals-md/xlib-v1.0-module-goals/` 的 1.0 发布基线，用于定义模块发布定位、边界、契约、测试证据和 DoD；`SPEC.md` 仍是模块功能规格 SSOT。

| 模块          | 1.0 Goal                           |
| ------------- | ---------------------------------- |
| xlib-standard | [goal.md](./xlib-standard/goal.md) |
| kernel        | [goal.md](./kernel/goal.md)        |
| configx       | [goal.md](./configx/goal.md)       |
| observex      | [goal.md](./observex/goal.md)      |
| testkitx      | [goal.md](./testkitx/goal.md)      |
| resiliencx    | [goal.md](./resiliencx/goal.md)    |
| schedulex     | [goal.md](./schedulex/goal.md)     |
| xlibgate      | [goal.md](./xlibgate/goal.md)      |
| redisx        | [goal.md](./redisx/goal.md)        |
| kafkax        | [goal.md](./kafkax/goal.md)        |
| natsx         | [goal.md](./natsx/goal.md)         |
| postgresx     | [goal.md](./postgresx/goal.md)     |
| taosx         | [goal.md](./taosx/goal.md)         |
| ossx          | [goal.md](./ossx/goal.md)          |
| clickhousex   | [goal.md](./clickhousex/goal.md)   |
| contracts     | [goal.md](./contracts/goal.md)     |
| transportx    | [goal.md](./transportx/goal.md)    |

---

## L0 原语（1 个）

stdlib-only 基础原语。所有上层模块的根依赖。

| 模块   | 规格                        | 核心职责                                                                                                                            |
| ------ | --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| kernel | [SPEC.md](./kernel/SPEC.md) | 12 子包轻量工具集：lifecycx/errx/healthx/obsx/retryx/shutdownx/syncx/timex/validx/versionx/contextx/contracttest（12 FR，12 tasks） |

---

## L1 运行时（4 个）

共享横切能力。可选依赖，按需引入。

| 模块       | 规格                                                                                                                                                | 核心职责                                                                                                                                                                              |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| configx    | [SPEC.md](./configx/SPEC.md) · [DESIGN.md](./configx/DESIGN.md) · [TRACEABILITY.md](./configx/TRACEABILITY.md) · [tasks/](./configx/tasks/)         | Client/Loader/Source 模式、多源合并（YAML/TOML/JSON/.env/Env/Map）、StrictDecode、SecretString 脱敏、SecretPolicy、Provenance、Hash、HealthCheck、Metrics（13 FR，11 BR，97.1% 覆盖） |
| observex   | [SPEC.md](./observex/SPEC.md) · [tasks/](./observex/tasks/)                                                                                         | Logger/Meter/Tracer/Exporter、Redaction、Label Policy、Health（7 FR，11 tasks）                                                                                                       |
| resiliencx | [SPEC.md](./resiliencx/SPEC.md) · [goal.md](./resiliencx/goal.md) · [TRACEABILITY.md](./resiliencx/TRACEABILITY.md) · [tasks/](./resiliencx/tasks/) | Timeout/Retry/CircuitBreaker/Bulkhead/RateLimiter/Fallback、策略组合（6 FR，8 BR，10 tasks，v1.0.1 Approved）                                                                         |
| schedulex  | [SPEC.md](./schedulex/SPEC.md) · [tasks/](./schedulex/tasks/)                                                                                       | Scheduler/Trigger/OverlapPolicy/MisfirePolicy/EventSink/Locker/Clock（9 FR，12 tasks，v1.0.1）                                                                                        |

---

## L1 测试（1 个）

test-only，不参与生产运行时。

| 模块     | 规格                                                                                                                                                                    | 核心职责                                                                                                                                                  |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| testkitx | [SPEC.md](./testkitx/SPEC.md) · [TRACEABILITY.md](./testkitx/TRACEABILITY.md) · [tasks/](./testkitx/tasks/) · [plan/](./testkitx/plan/) · [prompt/](./testkitx/prompt/) | FakeConfig/FakeLogger/FakeMeter/FakeTracer/FakeClock/FakeBreaker/Eventually/GoldenUpdate/BoundaryCheck/GoroutineLeakCheck（10 FR，11 tasks，管线 100 分） |

---

## 门禁（2 个）

标准源和机器门禁，不参与运行时。

| 模块          | 规格                                                                  | 核心职责                                                                                                                                      |
| ------------- | --------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| xlib-standard | [SPEC.md](./xlib-standard/SPEC.md) · [tasks/](./xlib-standard/tasks/) | 标准事实源、Go Reference Template、Generator、Harness Gate、Evidence Runtime（15 FR + goalcli，12 tasks）                                     |
| xlibgate      | [SPEC.md](./xlibgate/SPEC.md) · [tasks/](./xlibgate/tasks/)           | check imports/gomod/baseline/release/all、输出格式、l2 validate-manifest/plan/check-contracts/check-evidence/release-check（11 FR，10 tasks） |

---

## 存储扩展（7 个）

基础设施客户端封装。均为可选，按需引入。

| 模块        | 规格                                                    | 封装目标                                                                                             |
| ----------- | ------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| redisx      | [SPEC.md](./redisx/SPEC.md) · [goal.md](./redisx/goal.md) · [TRACEABILITY.md](./redisx/TRACEABILITY.md) · [tasks/](./redisx/tasks/) | Redis KeyBuilder/Options/KV/TTL/Cache/Hash/List/PubSub/Pipeline/Locker/Counter/RateLimit/Codec/Health；直接生产依赖限定为 kernel + Redis 客户端库，configx/observex/resiliencx/contracts 仅作为外部投影或 adapter 边界（12 FR，10 BR，4 NFR，10 tasks） |
| kafkax      | [SPEC.md](./kafkax/SPEC.md) · [TRACEABILITY.md](./kafkax/TRACEABILITY.md) · [goal.md](./kafkax/goal.md) | Kafka — 消息队列、事件流                                                                             |
| natsx       | [SPEC.md](./natsx/SPEC.md) · [TRACEABILITY.md](./natsx/TRACEABILITY.md) | NATS — 内部通信、JetStream（v1.0.0 已发布；repair-slice 20/20；真实 dev auth live gate 已验证；正式四源 98+ arbiter 与生产 TLS gate 待补） |
| postgresx   | [SPEC.md](./postgresx/SPEC.md) · [TRACEABILITY.md](./postgresx/TRACEABILITY.md) · [goal.md](./postgresx/goal.md) · [tasks/](./postgresx/tasks/) | PostgreSQL — 关系型存储、事务、迁移（v1.0.0 已发布，release-final-check + live integration 通过） |
| taosx       | [SPEC.md](./taosx/SPEC.md) · [TRACEABILITY.md](./taosx/TRACEABILITY.md) · [goal.md](./taosx/goal.md) | TDengine L2 adapter contract（pkg/taosx v1.0.1；真实 taosWS WebSocket 集成已验证，pkg/taosx 100.0% 覆盖） |
| ossx        | [SPEC.md](./ossx/SPEC.md) · [TRACEABILITY.md](./ossx/TRACEABILITY.md) · [goal.md](./ossx/goal.md) · [IMPLEMENTATION-PLAN.md](./ossx/IMPLEMENTATION-PLAN.md) · [tasks/](./ossx/tasks/) · [prompt/](./ossx/prompt/) | Aliyun OSS 对象存储 L2 adapter（v1.0.1 已发布；真实 Aliyun OSS 集成、race、vet、build、release-check 与 100.0% 覆盖已验证；S3/MinIO/Azure/GCS Provider 仅保留扩展位） |
| clickhousex | [SPEC.md](./clickhousex/SPEC.md) · [TRACEABILITY.md](./clickhousex/TRACEABILITY.md) · [goal.md](./clickhousex/goal.md) · [tasks/](./clickhousex/tasks/) | ClickHouse — OLAP 查询、批量写入（v1.0.1；完整 SPEC + TRACEABILITY §1-§7 + 7 Tasks，覆盖率 100%）                                                                     |

---

## 契约与传输（2 个）

跨域稳定端口、事件协议与跨 runtime / adapter 传输契约。

| 模块       | 规格                                                                                                                | 核心职责                                                                                                                       |
| ---------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| contracts  | [SPEC.md](./contracts/SPEC.md) · [goal.md](./contracts/goal.md) · [TRACEABILITY.md](./contracts/TRACEABILITY.md) · [tasks/](./contracts/tasks/) | MarketDataProvider/MacroDataProvider、Event、Topic、DTO、Breaking Change（6 FR，10 BR，8 NFR，5 tasks）                                      |
| transportx | [SPEC.md](./transportx/SPEC.md) · [TRACEABILITY.md](./transportx/TRACEABILITY.md) · [goal.md](./transportx/goal.md) | 应用通信底座规格基线；Envelope/Endpoint、ServiceIdentity、QoS、Codec、RPC、EventBus、Stream、Outbox/Inbox、Audit Plane、Data Classification、SchemaRegistry 与 conformance gates（25 FR，18 BR，25 TC） |

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
Feature Spec（功能怎么表现）   → module/*/SPEC.md（23 节结构）
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

| 层级           | 文档            | 位置                                                                                                                                                                                                          |
| -------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Product Spec   | 产品规格        | [`docs/product/product-spec.md`](../docs/product/product-spec.md)                                                                                                                                             |
| Feature Spec   | 模块完整规格    | [`module/*/SPEC.md`](#分层索引)（23 节结构）                                                                                                                                                                  |
| Technical Spec | 架构 + 宪法     | [`ARCHITECTURE.md`](../ARCHITECTURE.md) + [`CONSTITUTION.md`](../CONSTITUTION.md)                                                                                                                             |
| Test Spec      | 测试策略        | [`docs/testing/test-strategy.md`](../docs/testing/test-strategy.md)                                                                                                                                           |
| Agent Spec     | AI 代理规格模板 | [`docs/governance/AGENT-SPEC-TEMPLATE.md`](../docs/governance/AGENT-SPEC-TEMPLATE.md)（规则：[`agent-rules.md`](../docs/ai/agent-rules.md)、Prompt：[`prompt-templates.md`](../docs/ai/prompt-templates.md)） |

### 交付治理入口（docs/governance）

| 文件                                                                            | 用途                                                    |
| ------------------------------------------------------------------------------- | ------------------------------------------------------- |
| [`DEFINITION-OF-READY.md`](../docs/governance/DEFINITION-OF-READY.md)           | spec 可以进入开发的前置条件                             |
| [`DEFINITION-OF-DONE.md`](../docs/governance/DEFINITION-OF-DONE.md)             | 模块实现完成的验收条件                                  |
| [`SPEC-TEMPLATE.md`](../docs/governance/SPEC-TEMPLATE.md)                       | 23 节结构模板 — 新建模块规格时复制本文件                |
| [`TRACEABILITY.md`](../docs/governance/TRACEABILITY.md)                         | 需求追踪表：FR → AC → TC → 实现                         |
| [`DEVELOPMENT-WORKFLOW.md`](../docs/governance/DEVELOPMENT-WORKFLOW.md)         | Spec → Ship 完整管线总览                                |
| [`STRUCTURAL-SCORING.md`](../docs/governance/STRUCTURAL-SCORING.md)             | 每阶段结构评分、98 分门禁和有界递归自改进               |
| [`scoring/ARBITER-PROTOCOL.md`](../docs/governance/scoring/ARBITER-PROTOCOL.md) | 四源评分仲裁、repair budget 和 pipeline_blocked 规则    |
| [`PRE-DEVELOPMENT.md`](../docs/governance/PRE-DEVELOPMENT.md)                   | 开发前准备 — 实现策略、Task 拆分、追溯矩阵              |
| [`CODING-SESSION-PROTOCOL.md`](../docs/governance/CODING-SESSION-PROTOCOL.md)   | 编码会话协议 — Context Packet、Plan-first、自查、Review |
| [`SPEC-DRIFT-PROTOCOL.md`](../docs/governance/SPEC-DRIFT-PROTOCOL.md)           | Spec Drift 处理 — 代码与 Spec 不一致时的协议            |
| [`TESTING-STRATEGY.md`](../docs/governance/TESTING-STRATEGY.md)                 | 测试策略 — 从 Spec 生成测试、优先级、验收               |
| [`PR-TEMPLATE.md`](../docs/governance/PR-TEMPLATE.md)                           | PR/Issue/Branch/Commit 模板和命名规则                   |
| [`DEPLOYMENT.md`](../docs/governance/DEPLOYMENT.md)                             | 部署清单 — RC 检查、Smoke Test、CI 配置                 |
| [`REVIEW-STRATEGY.md`](../docs/governance/REVIEW-STRATEGY.md)                   | 审查策略 — 每层轻审查、转换点强审查、高风险点反审查     |

### Spec 状态流转

```text
Draft → Review → Approved → Implemented → Changed → Deprecated
```

完整状态机定义、流转规则、CI 集成点详见 [`LIFECYCLE.md`](../docs/governance/LIFECYCLE.md)。

---

## 相关文档

| 文档                                                                | 定位                                       |
| ------------------------------------------------------------------- | ------------------------------------------ |
| [`ARCHITECTURE.md`](../ARCHITECTURE.md)                             | 系统全局架构、依赖拓扑、设计原则           |
| [`CONSTITUTION.md`](../CONSTITUTION.md)                             | 系统宪法 — 最高治理条款                    |
| [`docs/product/product-spec.md`](../docs/product/product-spec.md)   | 产品规格 — Vision、Users、Goals、MVP Scope |
| [`docs/testing/test-strategy.md`](../docs/testing/test-strategy.md) | 测试策略 — 覆盖率、格式、工具、CI 集成     |
| [`docs/ai/agent-rules.md`](../docs/ai/agent-rules.md)               | AI 代理规则 — 编码、测试、安全、禁止事项   |
| [`docs/ai/prompt-templates.md`](../docs/ai/prompt-templates.md)     | Prompt 模板 — 审查、拆分、实现、自查、修复 |
| [`module/foundation-modules.md`](./foundation-modules.md)           | Why & What — 模块定位和能力需求            |
| [`module/FOUNDATION-SPEC.md`](./FOUNDATION-SPEC.md)                 | How & Check — 接口签名和 CI gate           |
| [`module/FOUNDATION-DEPS.yaml`](./FOUNDATION-DEPS.yaml)             | 机器可读依赖矩阵                           |
| [`module/FOUNDATION-V1.md`](./FOUNDATION-V1.md)                     | v1 路线图                                  |

---

## AI 工作流速查

### 0. 端到端工作流

```text
$spec-code-pipeline <module>
/project:spec-code-pipeline <module>

Spec → Matrix → Tasks → Plan → Prompt → Code
```

Codex 使用 `.codex/skills/spec-code-pipeline/SKILL.md`，
Claude Code 使用 `.claude/commands/spec-code-pipeline.md`，
Copilot 使用 `.copilot/commands/spec-code-pipeline.md`。
每个阶段进入下一阶段前都必须由 Claude / Copilot / Codex team scoring 和 `pipeline-arbiter`
通过：`composite_score = min(四源评分) >= 98`，且无红线、低置信度或异常分差；Spec 通过后由 arbiter 自动翻转 `Status: Approved`，`spec-review` 仅作为参考证据。

### 1. Spec 审查

```markdown
请 review module/{module}/SPEC.md。
重点检查：模糊需求、冲突要求、缺失边界、缺失验收标准、缺失测试用例。
输出：Blocking issues / Non-blocking suggestions / Ready or Not ready。
```

### 2. 任务拆分

```markdown
请根据 Approved 的 module/{module}/SPEC.md 和 module/{module}/TRACEABILITY.md 生成 implementation tasks。
每个 task 控制在 200 行以内，对应 requirement IDs / acceptance criteria / test cases。
```

### 3. 模块实现

```markdown
请根据 module/{module}/TASK-<NNN>-PROMPT.md，在 /home/{module} 对应代码仓库中实现当前 ready task。
上下文：SPEC.md + TRACEABILITY.md + task spec + IMPLEMENTATION-PLAN.md + AGENTS.md。
限制：只做当前 task 范围内的内容，不引入新依赖。
```

### 4. 自查

```markdown
请检查当前实现是否符合 spec。
输出：Requirement coverage table / AC result / Test coverage / Deviations。
```

详细 prompt 模板见 [`docs/ai/prompt-templates.md`](../docs/ai/prompt-templates.md)。
