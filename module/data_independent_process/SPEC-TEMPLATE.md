# SPEC-TEMPLATE.md — 独立进程 23 节规格模板

> **适用**：分析域独立进程模块（market_regime/macro_regime/regime_engine/factor_engine/feature_store/factor_eval/flowx/ms_brain）、数据域 dispatch 聚合层（market_data/macro_data）。
>
> **架构类型**：独立进程（非 C/S）— bootstrap 接入，无 `internal/client` / `internal/server` 拆分。
>
> **参考实现**：[module/market_regime/SPEC.md](../market_regime/SPEC.md)（S引擎）、[module/macro_regime/SPEC.md](../macro_regime/SPEC.md)（M引擎）。
>
> **使用方式**：复制本文件为 `module/{module}/SPEC.md`，填写所有 `{...}` 占位符。

最后更新：2026-06-21

---

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-21
- Owner: ZoneCNH
- Layer: 分析域 · {细分定位}（或 数据域 · dispatch 聚合）
- Version: v0.1.0
- Repository: [github.com/ZoneCNH/{module}](https://github.com/ZoneCNH/{module})
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), `module/contracts`, `module/domain_{...}`

> 架构类型：**[独立进程（非 C/S）](../../ARCHITECTURE.md#模块架构类型)** — bootstrap 接入，无 client/server 拆分

---

## 2. Summary

`module/{module}` 是 {分析域|数据域} 的 {定位描述}，{核心功能一句话}。

```text
{上游模块 / 数据源}
  ↓ contracts-defined port
module/{module}                  ← {处理/分类/决策}
  ↓ contracts-defined port
{下游模块}                       ← 消费方
```

{模块} 通过 bootstrap 组装为独立进程，{输入→处理→输出}闭环。

---

## 3. Problem

{领域} 需要 {能力}。直接 {现有方式} 存在以下问题：

1. **{问题 1}**：{描述}
2. **{问题 2}**：{描述}
3. **边界模糊**：{处理逻辑} 容易与上下游耦合，需要显式边界
4. **可靠性缺失**：缺乏标准化进程组装、健康检查和可观测性
5. **可测试性差**：无 clear input → output contract，难以独立验证

---

## 4. Goals

- 实现 {核心算法 / 分类器 / 处理逻辑}
- 通过 contracts-defined port 接收输入、输出结果
- 通过 bootstrap 标准化进程组装
- 提供 admin 端点（/healthz, /readyz）
- 集成 observex 可观测性
- 定义 enforceable boundary，防止跨域耦合

---

## 5. Non-goals

`module/{module}` 明确不做以下事情：

| 不做 | 原因 |
|------|------|
| 数据采集 | 属于数据域 |
| 数据存储 / query API | 属于存储层或下游模块 |
| 下游模块的调度决策 | 属于下游模块职责 |
| 定义跨域契约（DTO/port） | 由 `module/contracts` 拥有 |
| 实现 order execution | 属于执行域 |
| 提供实时 dashboard / UI | 属于上层工具 |

---

## 6. Consumers

| 消费者 | 使用方式 | 状态 |
|--------|----------|------|
| `{下游模块 A}` | 通过 contracts port 消费 `{OutputType}` | SPEC Approved, runtime integration pending |
| `{下游模块 B}` | 通过 contracts port 消费 `{OutputType}` | 待实现 |
| Operator / SRE | 通过 admin 端点监控 | 待实现 |
| CI Pipeline | 通过 BOUNDARY-GATES.md gate 脚本执行边界检查 | 待实现 |

---

## 7. Functional Requirements

### FR-001: Bootstrap Integration

**功能描述**：模块通过 bootstrap 组装为独立进程。

**WHEN** `cmd/{module}/main.go` 调用 `bootstrap.Build(ctx, Spec{Module, Stores=None})`
**THEN** 模块获得 config/observe/lifecycle 标准化组装

**WHEN** 收到 SIGTERM/SIGINT
**THEN** 逆序 Stop 注册的组件，幂等清理资源

### FR-002: Input Reception

**功能描述**：模块通过 contracts-defined port 接收上游数据。

**WHEN** 上游通过 contracts.`{InputPort}` 发送 `{InputType}`
**THEN** 模块接收、验证并开始处理

**WHEN** 输入数据验证失败
**THEN** 返回结构化错误，含 machine-readable reason（fail-closed）

### FR-003: Core Processing

**功能描述**：模块执行核心 {分类/计算/分析} 逻辑。

**WHEN** 收到有效的 `{InputType}`
**THEN** 执行 {具体处理逻辑}，输出 `{OutputType}`

**WHEN** {边界场景：输入不足 / 阈值未达 / 数据缺失}
**THEN** 输出 `{默认/降级}` 结果，含 confidence 或 degradation indicator

### FR-004: Output Production

**功能描述**：模块通过 contracts-defined port 输出结果。

**WHEN** 核心处理完成
**THEN** 通过 contracts.`{OutputPort}` 发布 `{OutputType}`（不可变）

**WHEN** 下游不可用
**THEN** 保持 last-known-good 状态，触发告警，不崩溃

### FR-005: Admin Surface

**功能描述**：模块暴露 admin 端点。

**WHEN** 请求 `GET /healthz`
**THEN** 返回 process liveness 状态（200 或 503）

**WHEN** 请求 `GET /readyz`
**THEN** 返回模块就绪状态（200 或 503）

**WHEN** 请求 `GET /debug/*`
**THEN** 返回只读诊断信息（当前状态、最近输入/输出摘要），不暴露 secrets

### FR-006: Boundary Enforcement

**功能描述**：模块边界通过 CI gate 强制执行。

**WHEN** 模块代码尝试 import 被禁止的依赖（如执行域实现包）
**THEN** CI boundary gate 失败

**WHEN** 模块内声明下游模块的所有权（如定义下游 DTO）
**THEN** CI ownership gate 失败

---

## 8. Business Rules

### BR-001: Fail-Closed

**规则**：输入校验失败时，模块拒绝处理并返回错误。

**约束**：不跳过校验、不静默丢弃、不使用默认值替代无效输入。

**违反时**：操作被拒绝，返回 structured error。

### BR-002: Immutable Output

**规则**：输出一旦生成即不可变，下游只读。

**约束**：禁止下游直接修改模块输出、禁止模块暴露可变内部状态。

**违反时**：CI boundary gate 失败。

### BR-003: No Lookahead

**规则**：处理逻辑不得使用未来数据（时间戳 ≤ 当前处理窗口）。

**约束**：禁止在 {T} 时刻的处理中引用 data[T+1]、禁止使用全量数据做"事后"分析。

**违反时**：CI gate 失败（通过 lookahead check 脚本检测）。

### BR-004: No Domain Ownership

**规则**：`module/{module}` 不得定义 contracts 中的 DTO 或 port 的 source of truth。

**约束**：所有跨域类型必须来自 `module/contracts`。模块可定义内部中间类型，但输出必须是对 contracts 类型的引用。

**违反时**：CI ownership gate 失败。

### BR-005: Stateless Processing

**规则**：每次处理基于当前输入 + 内部状态，不依赖外部可变状态。

**约束**：禁止直接读写其他模块的数据库/缓存/内存、禁止依赖全局可变单例。

**违反时**：进程间共享可变状态可能产生竞态，CI gate 警告。

### BR-006: Admin Boundary

**规则**：admin 端点仅可变更模块本地状态。

**约束**：禁止 admin 变更下游模块状态、禁止 admin 绕过 contracts port 直接操作上游。

**违反时**：操作被拒绝并返回错误。

---

## 9. Interface Contract

### 消费的 Port（由 contracts 定义）

```go
// {InputPortName} is consumed by {module}.
// Defined in module/contracts/SPEC.md.
type {InputPortName} interface {
    // {Method} provides {input_type} for {module} processing.
    {Method}(ctx context.Context, req *{InputType}) error
}
```

### 暴露的 Port（由 contracts 定义）

```go
// {OutputPortName} is implemented by {module}.
// Defined in module/contracts/SPEC.md.
type {OutputPortName} interface {
    // {Method} produces {output_type} from {module}.
    {Method}(ctx context.Context) (*{OutputType}, error)
}
```

**DTOs** (全部由 `module/contracts` 拥有)：

| DTO | 说明 |
|-----|------|
| `{InputType}` | 上游输入 |
| `{OutputType}` | 模块输出（不可变） |

---

## 10. Data Model

### Internal State

| 字段 | 类型 | 说明 |
|------|------|------|
| `{state_field}` | `{type}` | {说明} |

### Processing Model

```text
Input → Validate → {Transform} → {Classify/Compute} → Output
         │                                        │
         └──── fail-closed error ─────────────────┘
```

### Output Types

| 输出 | 说明 |
|------|------|
| `{OutputVariant1}` | {说明} |
| `{OutputVariant2}` | {说明} |

---

## 11. Config Schema

| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `{module}.{param}` | `{type}` | `{default}` | {说明} |
| `{module}.threshold` | `float64` | `0.5` | {分类/决策阈值} |
| `{module}.window_size` | `int` | `100` | {处理窗口大小} |
| `admin.bind` | `string` | `:8080` | admin HTTP 绑定地址 |

> **Security**：敏感参数从环境变量注入。

---

## 12. Error Handling

| 错误 | 触发条件 | 处理方式 | 错误码 |
|------|----------|----------|--------|
| `ErrInvalidInput` | 输入验证失败 | fail-closed，返回结构化错误 | `{MOD}-001` |
| `ErrProcessingFailed` | 核心处理异常 | 记录日志，保持 last-known-good 状态 | `{MOD}-002` |
| `ErrOutputFailed` | 下游不可达 | 保持 last-known-good，触发告警 | `{MOD}-003` |
| `ErrConfigInvalid` | 配置无效 | 进程启动失败 | `{MOD}-004` |
| `ErrInternalState` | 内部状态损坏 | 重启恢复 | `{MOD}-005` |
| `ErrTimeout` | 处理超时 | 超时后返回降级结果 | `{MOD}-006` |

---

## 13. Edge Cases

| 场景 | 输入/状态 | 预期行为 |
|------|-----------|----------|
| 空输入 | 上游未产生数据 | 保持 last-known-good 状态，不输出 |
| 无效输入 | 格式错误或缺失字段 | fail-closed，返回 `ErrInvalidInput` |
| 数据不足 | 窗口内数据量未达阈值 | 输出低 confidence 或降级结果 |
| 下游不可用 | 输出 port 无消费者 | 保持状态，触发告警，不崩溃 |
| 进程重启 | 信号触发停止 | 优雅停止，重启后从初始状态恢复 |
| 配置热更新 | 运行时配置变更 | 仅变更处理参数，不重置内部状态 |
| 超时 | 单次处理超过 deadline | 返回超时错误，保持 last-known-good |
| 并发输入 | 多个输入同时到达 | 串行处理或明确并发策略 |

---

## 14. Directory Structure

### Documentation (`module/{module}/`)

```text
module/{module}/
  goal.md                          # 模块 Goal 文档
  README.md                        # 模块索引
  SPEC.md                          # 本文件 — 模块完整规格
  TRACEABILITY.md                  # 需求追溯矩阵
  IMPLEMENTATION-PLAN.md           # 实现计划
  BOUNDARY-GATES.md                # CI 边界门禁定义
  tasks/                           # Task spec
```

### Runtime (`github.com/ZoneCNH/{module}/`)

```text
github.com/ZoneCNH/{module}/
  go.mod
  cmd/
    {module}/main.go               # bootstrap.Build() 独立进程入口
  internal/
    app/                            # 应用组装
    processor/                      # 核心处理逻辑
    validator/                      # 输入验证
    state/                          # 内部状态管理
    admin/                          # admin 端点
  pkg/
    {module}x/                      # 公开包
      {module}.go
      version.go
  test/
    integration/
    fixtures/
```

---

## 15. Dependencies

### Allowed Dependencies

| 依赖 | 用途 | 消费方 |
|------|------|--------|
| `module/contracts` | 输入/输出 port 和 DTO | processor |
| `module/domain_{...}` | domain 类型 | processor, validator |
| `module/bootstrap` | 进程组装（config/observe/lifecycle） | `cmd/{module}` |
| `module/observex` | 可观测性集成 | app |

### Forbidden Dependencies

| 禁止导入 | 原因 |
|----------|------|
| 执行域实现包 | 分析域与执行域通过 contracts 隔离 |
| 数据域内部实现 | 只消费 contracts port，不依赖数据源内部 |
| 决策域内部实现 | 通过 contracts 隔离，禁止反向依赖 |
| `github.com/ZoneCNH/storage` (as owned) | storage ownership 属于存储层 |

---

## 16. Testing

### Test Matrix

| TC 编号 | 对应 FR | 测试类型 | 场景 | 预期结果 |
|---------|---------|----------|------|----------|
| TC-001 | FR-001 | 集成 | 启动 `cmd/{module}` | bootstrap 组装完成，进程正常运行 |
| TC-002 | FR-002 | 单元 | 接收有效 `{InputType}` | 验证通过，开始处理 |
| TC-003 | FR-002 | 单元 | 接收无效输入 | fail-closed，返回 `ErrInvalidInput` |
| TC-004 | FR-003 | 单元 | 标准输入处理 | 输出正确的 `{OutputType}` |
| TC-005 | FR-003 | 单元 | 数据不足 | 输出低 confidence 或降级结果 |
| TC-006 | FR-004 | 集成 | 下游消费输出 | 下游收到正确的输出 |
| TC-007 | FR-005 | 单元 | GET /healthz | 返回 200 |
| TC-008 | FR-006 | CI | 模块 import 执行域包 | boundary gate 失败 |
| TC-009 | BR-003 | 单元 | 处理逻辑引用未来数据 | no-lookahead check 失败 |

### Test Tools

- 框架：`testing` + `testify`
- Mock：`testkitx`
- 覆盖率：`go test -cover`
- 竞态：`go test -race`
- Golden：用于确定性输出验证

---

## 17. Performance Budget

| 操作 | 指标 | 目标 | 测量方式 |
|------|------|------|----------|
| 单次处理 | 延迟 P99 | < {X}ms | `go test -bench` |
| 输入验证 | 延迟 P99 | < {X}μs | `go test -bench` |
| 启动时间 | 时间 | < 5s | integration test |
| 内存稳态 | RSS | < {X}MB | integration test |

---

## 18. Observability

### Metrics

| 指标名 | 类型 | 说明 |
|--------|------|------|
| `{module}_inputs_total` | counter | 接收的输入数 |
| `{module}_inputs_invalid_total` | counter | 无效输入数 |
| `{module}_outputs_total` | counter | 产生的输出数（per output type） |
| `{module}_processing_duration_seconds` | histogram | 处理延迟 |
| `{module}_processing_errors_total` | counter | 处理错误数 |
| `{module}_state_current` | gauge | 当前状态 indicator |
| `{module}_confidence_current` | gauge | 当前 confidence level |

### Logging

| 事件 | 级别 | 必要字段 |
|------|------|----------|
| Processing started | debug | input_id, input_type |
| Processing completed | debug | output_id, output_type, duration_ms |
| Input validation failed | warn | input_id, reason |
| Processing error | error | error, last_known_good_state |
| State transition | info | from_state, to_state, confidence |

### Tracing

| Span 名 | 说明 |
|---------|------|
| `{module}.validate` | 输入验证 |
| `{module}.process` | 核心处理 |
| `{module}.output` | 输出生成 |

---

## 19. Security

- 禁止硬编码 secret、API key、密码
- `/debug/*` 和 `/admin/*` 端点不得暴露 secrets 或私有配置
- Admin 端点在暴露于非本地可信网络时必须使用认证
- 日志中禁止记录完整输入/输出 payload（仅记录 metadata 和 ID）
- 输入校验对所有外部输入执行基本结构验证
- 不信任上游数据——始终 fail-closed

---

## 20. CI Gate

### 通用 Gate

| Gate | 命令 | 通过条件 |
|------|------|----------|
| 编译 | `go build ./...` | 零错误 |
| 测试 | `go test ./... -race -count=1` | 全部通过 |
| 覆盖率 | `go test ./... -coverprofile=coverage.out && go tool cover -func=coverage.out` | ≥ 80% |
| Vet | `go vet ./...` | 零警告 |
| Lint | `golangci-lint run` | 零警告 |
| 安全 | `gitleaks detect --no-git` | 零泄露 |
| 依赖 | `go mod tidy && git diff --exit-code` | 无变更 |

### 独立进程专属 Gate

| Gate | 命令 | 通过条件 |
|------|------|----------|
| Boundary | boundary gate script | 零跨域 import |
| Ownership | ownership gate script | 零 contracts DTO 定义、零下游所有权声明 |
| No lookahead | lookahead check script | 零未来数据引用（BR-003） |
| Admin boundary | admin gate script | 零跨模块 admin mutation |

---

## 21. Upgrade Compatibility

| 变更类型 | 兼容性 | 迁移方式 |
|----------|--------|----------|
| 新增输出类型 | 向后兼容 | 下游按需消费新类型 |
| 输入 DTO 变更 | 取决于 contracts 兼容策略 | 升级 contracts 版本 |
| 处理算法升级 | 向后兼容（需验证输出一致性） | 双运行验证、golden test 对比 |
| 状态 schema 变更 | 可能需要 migration | 提供 migration 工具或清空重建 |

---

## 22. Release DoD

`module/{module}` v1.0.0 发布完成标准：

- [ ] SPEC 完成并通过 spec-lint
- [ ] TRACEABILITY.md 完成，所有需求可追溯
- [ ] `cmd/{module}` 通过 bootstrap 组装为独立进程（FR-001）
- [ ] 核心处理逻辑实现并通过 golden test（FR-003）
- [ ] Fail-closed 行为验证通过（BR-001）
- [ ] No-lookahead 验证通过（BR-003）
- [ ] BOUNDARY-GATES.md 存在且全部通过（FR-006）
- [ ] 所有 FR 实现完成，所有 AC 验证通过
- [ ] 覆盖率 ≥ 80%
- [ ] CI Gate 全部通过（通用 + 独立进程专属）
- [ ] Performance Budget 达标
- [ ] Integration test 演示 `input → process → output` 完整数据流

---

## 23. Open Questions

### Blocking（阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-001 | `module/contracts` 的输入/输出 port 是否已定义？ | 待确认 | contracts owner |
| OQ-002 | 上游模块的输出 DTO 是否已稳定？ | 待确认 | upstream owner |

### Non-blocking（不阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-003 | 处理算法的具体选型（规则引擎 / ML模型 / 混合）？ | 待评估 | module owner |
| OQ-004 | 是否需要热更新处理参数？ | 待评估 | module owner |

### Future（未来考虑）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-005 | 是否需要 A/B 测试框架？ | 待评估 | architecture |
| OQ-006 | 是否需要分布式多实例协调？ | 待评估 | architecture |

---

## 使用指南

1. 复制本文件为 `module/{module}/SPEC.md`
2. 替换 `{module}` → 实际模块名（如 `market_regime`）
3. 替换 `{MOD}` → 错误码前缀（如 `MKR`、`MCR`、`RGE`）
4. 替换 `{定位描述}` → 具体定位（如 "S 引擎，市场状态识别 S1-S7"）
5. 替换 `{核心功能一句话}` → 模块的核心能力
6. 填写 §7 FR 的具体处理逻辑
7. 填写 §10 Data Model 的状态和处理模型
8. 填写 §11 Config 的具体参数
9. 确保每个 FR 有 WHEN/THEN
10. 确保每个 BR 有"违反时"处理
11. 运行 `spec-lint.sh` 验证结构
12. 提交 PR，进入 Review

---

## 相关文档

| 文档 | 用途 |
|------|------|
| [`ARCHITECTURE.md`](../../ARCHITECTURE.md#模块架构类型) | 独立进程架构类型定义 |
| [`module/market_regime/SPEC.md`](../market_regime/SPEC.md) | S 引擎参考（M 引擎同理） |
| [`module/data_cs_module/SPEC-TEMPLATE.md`](../data_cs_module/SPEC-TEMPLATE.md) | C/S Module 模板（对比参考） |
| [`docs/governance/SPEC-TEMPLATE.md`](../../docs/governance/SPEC-TEMPLATE.md) | 通用 23 节 SPEC 模板 |
| [`.github/ci/spec-lint.sh`](../../.github/ci/spec-lint.sh) | 结构校验脚本 |
