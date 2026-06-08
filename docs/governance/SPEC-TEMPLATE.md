# SPEC-TEMPLATE.md — 23 节结构模板

> FoundationX 模块规格模板。新建 `module/{module}/SPEC.md` 时复制本文件。
>
> `spec-lint.sh` 校验所有 23 节必须存在。每节的 `{占位符}` 需替换为实际内容。

最后更新：2026-06-07

---

## 1. Metadata

> 模块元数据，用于索引和 CI 校验。

```markdown
- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-07
- Owner: ZoneCNH
- Layer: L1 {层级}
- Version: v0.1.0
- Repository: [github.com/ZoneCNH/{module}](https://github.com/ZoneCNH/{module})
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), {依赖模块}
```text

| 字段 | 说明 |
|------|------|
| `Status` | 规格生命周期状态：Draft / Review / Approved / Implemented / Changed / Deprecated |
| `Spec-Version` | 规格文档版本号（与代码 Version 解耦） |
| `Last-Updated` | 规格最后修改日期 |
| `Owner` | 规格负责人 |
| `Layer` | 架构层级（基座 / 数据域 / 分析域 / 决策域 / 执行域） |
| `Version` | 模块代码版本号 |
| `Repository` | 模块仓库链接 |
| `Related` | 相关文档链接 |

---

## 2. Summary

> 一段话描述模块的定位和核心能力。

```markdown
`{module}` 提供 {核心能力}。{解决什么问题}，{为谁服务}。
```text

**要求**：不超过 3 句话，能让人在 30 秒内理解模块价值。

---

## 3. Problem

> 描述模块要解决的具体问题。用量化数据支撑。

```markdown
{领域}需要{能力}。直接使用{底层技术}存在以下问题：

- {问题 1}
- {问题 2}
- {问题 3}
```text

**要求**：

- 至少列出 3 个具体问题
- 有量化数据优先（如"延迟 > 500ms"、"重复代码 > 200 行"）
- 不写"不够好"这类模糊表述

---

## 4. Goals

> 模块要达成的具体目标。每条可测试。

```markdown
- 提供 {接口名} 接口，支持 {能力}
- 管理 {资源}，支持 {配置项}
- 集成 {依赖模块} 的 {能力}
```text

**要求**：

- 每条 Goal 对应一个或多个 FR
- 使用可测试表述（"提供 X 接口"而非"支持 X"）
- 不超过 8 条

---

## 5. Non-goals

> 明确不做的事情。防止范围蔓延。

```markdown
- 不做 {功能 A}（由 {模块/层级} 负责）
- 不做 {功能 B}（超出本模块职责）
- 不做 {功能 C}（当前版本不支持）
```text

**要求**：

- `spec-lint.sh` 校验此节不能为空
- 每条 Non-goal 应说明为什么不做（谁负责 / 为什么超出范围）
- 至少 3 条

---

## 6. Consumers

> 谁会使用这个模块。

```markdown
| 消费者 | 使用方式 |
|--------|----------|
| `{module-a}` | 调用 {接口} 做 {用途} |
| `{module-b}` | 调用 {接口} 做 {用途} |
```text

**要求**：

- 列出所有已知消费者
- 说明每个消费者使用哪个接口
- 如果消费者尚未实现，标注"待创建"

---

## 7. Functional Requirements

> 功能需求。每个 FR 使用 WHEN/THEN 格式。

```markdown
### FR-001: {功能名称}

**功能描述**：{一句话描述}

**WHEN** {触发条件}
**THEN** {预期行为}

**WHEN** {另一个触发条件}
**THEN** {另一个预期行为}
```text

**要求**：

- FR 编号连续（FR-001, FR-002, ...），`spec-lint.sh` 校验
- 每个 FR 至少有 1 条 WHEN/THEN，`spec-lint.sh` 校验
- WHEN 描述触发条件，THEN 描述系统行为
- 不写"系统应该"这种模糊表述
- 每个 FR 对应追溯矩阵中的一行

---

## 8. Business Rules

> 业务规则。约束模块行为的硬性规则。

```markdown
### BR-001: {规则名称}

{规则描述}

**约束**：{具体约束条件}
**违反时**：{错误处理方式}
```text

**要求**：

- BR 编号连续（BR-001, BR-002, ...）
- 每条 BR 必须有"违反时"的处理方式
- BR 不可与 FR 冲突

---

## 9. Interface Contract

> 接口定义。Go 接口签名。

```markdown
```go
// {InterfaceName} {接口用途}
type {InterfaceName} interface {
    // {Method} {方法用途}
    {Method}(ctx context.Context, {params}) ({returns}, error)
}
```​
```text

**要求**：

- 接口由消费方定义（`contracts` 包）
- 接口尽量小（1-5 个方法）
- 每个方法必须有 `context.Context` 参数
- 每个方法必须返回 `error`
- 参数和返回值使用标准类型或 `contracts` 中定义的类型

---

## 10. Data Model

> 数据结构定义。

```markdown
### {StructName}

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| {Field} | `{type}` | ✅/❌ | {说明} |
```text

**要求**：

- 使用 Go 结构体定义
- 标注 JSON tag（如需要序列化）
- 标注必填/可选
- 使用 `decimalx` 处理金额，不使用 `float64`

---

## 11. Config Schema

> 配置项定义。

```markdown
| 配置项 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `{key}` | `{type}` | `{default}` | {说明} |
```text

**要求**：

- 使用 `configx` 的配置格式
- 每个配置项必须有默认值
- 敏感配置（密码、密钥）不写默认值，标注"从环境变量读取"

---

## 12. Error Handling

> 错误处理策略。

```markdown
| 错误 | 触发条件 | 处理方式 | 错误码 |
|------|----------|----------|--------|
| `{ErrName}` | {条件} | {处理} | `{code}` |
```text

**要求**：

- 公共错误变量定义在 `errors.go`
- 错误消息格式：`"package: operation: detail"`
- 使用 `%w` 保留错误链
- 不在库中使用 `log.Fatal` 或 `os.Exit`

---

## 13. Edge Cases

> 边界场景。

```markdown
| 场景 | 输入/状态 | 预期行为 |
|------|-----------|----------|
| 空输入 | {描述} | {行为} |
| 超时 | {描述} | {行为} |
| 并发 | {描述} | {行为} |
```text

**要求**：

- 至少覆盖：空值、超时、并发、重试、资源耗尽
- 每个 Edge Case 对应至少一个测试用例

---

## 14. Directory Structure

> 模块目录结构。

```text
{module}/
├── {module}.go          # 核心实现
├── {module}_test.go     # 测试
├── errors.go            # 错误定义
├── options.go           # Option 模式配置
├── go.mod               # 模块定义
├── testdata/            # 测试数据
└── README.md            # 模块文档
```text

**要求**：

- 遵循 Go 项目布局惯例
- 测试文件与源文件同目录
- 测试数据放在 `testdata/` 目录

---

## 15. Dependencies

> 依赖声明。

```markdown
### 直接依赖

| 依赖 | 版本 | 用途 | 来源 |
|------|------|------|------|
| `{pkg}` | `{version}` | {用途} | 标准库 / contracts / 第三方 |

### 间接依赖

| 依赖 | 被谁引入 | 用途 |
|------|----------|------|
| `{pkg}` | `{direct-dep}` | {用途} |
```text

**要求**：

- 优先使用标准库
- 第三方依赖需经 spec 批准
- 使用 `configx` 管理配置，不直接读取环境变量
- 使用 `observex` 集成可观测性，不直接使用 prometheus/jaeger

---

## 16. Testing

> 测试策略。

```markdown
### 测试矩阵

| TC 编号 | 对应 FR | 测试类型 | 场景 | 预期结果 |
|---------|---------|----------|------|----------|
| TC-001 | FR-001 | 单元 | {场景} | {结果} |

### 测试工具

- 框架：`testing` + `testify`
- Mock：`testkitx`
- 覆盖率：`go tool cover`
- 竞态：`go test -race`

### 测试数据

| 文件 | 用途 |
|------|------|
| `testdata/{file}` | {用途} |
```text

**要求**：

- 每个 FR 至少对应 1 个 TC
- 测试使用 Given/When/Then 注释
- 测试名包含 TC 编号（如 `TestRegister_TC001`）
- 覆盖率 ≥ 80%

---

## 17. Performance Budget

> 性能预算。

```markdown
| 操作 | 指标 | 目标 | 测量方式 |
|------|------|------|----------|
| {Operation} | 延迟 P99 | < {X}ms | `go test -bench` |
| {Operation} | 内存 | < {X}MB | `go test -benchmem` |
| {Operation} | 吞吐 | > {X}/s | `go test -bench` |
```text

**要求**：

- 每个性能敏感的操作必须有预算
- 使用具体数值，不写"快速"、"高效"
- 标注测量方式

---

## 18. Observability

> 可观测性集成。

```markdown
### Metrics

| 指标名 | 类型 | 说明 |
|--------|------|------|
| `{metric}` | counter/gauge/histogram | {说明} |

### Tracing

| Span 名 | 说明 |
|---------|------|
| `{span}` | {说明} |

### Logging

| 事件 | 级别 | 说明 |
|------|------|------|
| `{event}` | info/warn/error | {说明} |
```text

**要求**：

- 使用 `observex` 的 `metrics` / `tracing` / `logging` 子模块
- 不直接使用 prometheus/jaeger/logrus

---

## 19. Security

> 安全要求。

```markdown
- 不硬编码 secret、API key、密码
- 不在日志中记录敏感数据
- 用户输入必须校验
- {模块特有的安全要求}
```text

**要求**：

- 每个模块必须有此节
- 至少包含通用安全要求（硬编码、日志、输入校验）

---

## 20. CI Gate

> CI 门禁定义。

```markdown
### 20.1 通用 Gate（所有模块）

| Gate | 命令 | 通过条件 |
|------|------|----------|
| 编译 | `go build ./...` | 零错误 |
| 测试 | `go test ./... -race -count=1` | 全部通过 |
| 覆盖率 | `go tool cover -func=cover.out` | ≥ 80% |
| Vet | `go vet ./...` | 零警告 |
| Lint | `golangci-lint run` | 零警告 |
| 依赖 | `go mod tidy && git diff --exit-code` | 无变更 |
| 安全 | `gitleaks detect --no-git` | 零泄露 |
| Benchmark | `go test -bench=. -benchmem` | 在预算内 |

### 20.2 模块专属 Gate

| Gate | 命令 | 通过条件 |
|------|------|----------|
| {自定义} | `{命令}` | {条件} |
```text

**要求**：

- 通用 Gate 不可修改
- 模块专属 Gate 根据模块特性定义（如 redisx 需要 Redis 连接测试）

---

## 21. Upgrade Compatibility

> 升级兼容性。

```markdown
| 变更类型 | 兼容性 | 迁移方式 |
|----------|--------|----------|
| {变更} | 向后兼容 / Breaking | {迁移步骤} |
```text

**要求**：

- 每个接口变更必须标注兼容性
- Breaking Change 必须提供迁移步骤
- 遵循 CONSTITUTION.md 第十条的变更分类

---

## 22. Release DoD

> 发布完成的定义。

```markdown
- [ ] 所有 FR 实现完成
- [ ] 所有 AC 验证通过
- [ ] 所有 TC 编写并全部通过
- [ ] 覆盖率 ≥ 80%
- [ ] CI Gate 全部通过
- [ ] Performance Budget 达标
- [ ] 追溯矩阵更新完成
- [ ] spec 状态更新为 Implemented
```text

**要求**：

- 使用 checkbox 格式
- 每项可验证
- 对应 DEFINITION-OF-DONE.md 的要求

---

## 23. Open Questions

> 待解决的问题。分为 Blocking / Non-blocking / Future。

```markdown
### Blocking（阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-001 | {问题} | 待解决 | {负责人} |

### Non-blocking（不阻塞开发）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-002 | {问题} | 待解决 | {负责人} |

### Future（未来考虑）

| ID | 问题 | 状态 | 负责人 |
|----|------|------|--------|
| OQ-003 | {问题} | 待评估 | - |
```text

**要求**：

- Blocking 问题必须在开发前解决
- Non-blocking 问题可以在开发中解决
- Future 问题记录备忘，不承诺解决时间

---

### 附录区（可选）

当 spec 内容超出 23 节标准结构时，可在最后追加附录章节：
- 编号使用 `## Appendix A: 标题` / `## Appendix B: 标题` ... 字母序，**不**使用 `## 24. ...`；
- 附录内容仅用于参考性映射、历史溯源、关键数字汇总等**非规范性**材料；
- 规范性条款（FR / BR / AC / NFR / TC）必须留在 §1–§23 内，附录不得引入新的规范条款；
- 附录子节使用 `### Appendix X.1` / `### Appendix X.2`，不强制层级深度。

---

## 使用指南

1. 复制本文件为 `module/{module}/SPEC.md`
2. 填写 Metadata，设置 `Status: Draft`
3. 按 23 节顺序填写内容
4. 如需补充非规范性材料，可在 §23 后追加 `## Appendix A: ...` 附录区
5. 确保每个 FR 有 WHEN/THEN
6. 确保每个 BR 有"违反时"处理
7. 确保每个 TC 对应至少一个 FR
8. 运行 `spec-lint.sh` 验证结构
9. 提交 PR，进入 Review

---

## 相关文档

| 文档 | 用途 |
|------|------|
| [`docs/governance/LIFECYCLE.md`](./LIFECYCLE.md) | 规格生命周期状态机 |
| [`docs/governance/TASK-TEMPLATE.md`](./TASK-TEMPLATE.md) | Task Spec 模板 |
| [`docs/governance/AGENT-SPEC-TEMPLATE.md`](./AGENT-SPEC-TEMPLATE.md) | Agent Spec 模板 |
| [`docs/governance/TRACEABILITY.md`](./TRACEABILITY.md) | 追溯矩阵 |
| [`docs/governance/anti-requirements.md`](./anti-requirements.md) | 反需求 |
| [`.github/ci/spec-lint.sh`](../../.github/ci/spec-lint.sh) | 结构校验脚本 |
