# xlib_harness 规格

Status: Approved
- Spec-Version: v1.3.0
- Last-Updated: 2026-06-30
- Layer: 基座 · 模块生成器与门禁执行器
- Version: v0.1.6
- Related: `CONSTITUTION.md`, `ARCHITECTURE.md`, `module/FOUNDATION-DEPS.yaml`, `xlibgate`

> 公开投影说明：v0.1.6 已由 `/home/xlib_harness@d90b35124701` 的本地验收、GitHub Actions Release run `27855366871`、main CI run `27855396013` 和 GitHub Release 证据支撑。

---

## 1. 摘要

`xlib_harness` 是 Foundation 模块的生成器与门禁执行器。它生成标准模块文档集合，并对已有模块执行规格结构、追踪闭环、运行时依赖边界、Markdown 格式和 CI/CD 引用检查。

## 2. 问题与背景

Foundation 20 模块需要统一的可机器验证规格资产。手工复制模板会带来结构漂移、追踪断链和边界规则遗漏，因此需要一个独立、标准库依赖、可在本地与 CI 中重复执行的 harness。

## 3. 目标

- 提供 `xlib_harness generate <module>` 生成标准模块文档集合。
- 提供 `xlib_harness check <module>` 对模块执行可组合门禁。
- 以 fixture 锁定 compliant、bad-dependency、broken-trace 三类行为。
- 保持 Go 运行时 stdlib-only，不把业务模块或横切工具作为运行时依赖。
- 让 harness 自身达到 100% Go 覆盖率，并通过 `make ci`。
- 在代码仓库公开 `FEATURES.md` 与 `ACCEPTANCE.md`，并由 CI/CD 发布门禁验证。

## 4. 非目标

- 不定义 Foundation 标准本身。
- 不替代 `xlibgate` 的编译、发布和外部信任门禁。
- 不参与业务运行时。
- 不连接交易所、账户、凭证或生产环境。
- 不引入第三方 Go 运行时依赖。

## 5. 消费者

- 模块开发者：生成新模块文档骨架。
- CI 管线：执行合规门禁。
- 根仓库投影：同步模块状态、验收证据和发布版本。
- 代码审查者：用结构化 JSON 输出定位失败项。

## 6. 功能需求

| ID | Requirement | Given | When | Then |
| --- | --- | --- | --- | --- |
| FR-001 | generate-module | 给定模块路径和可选 `--force` | 用户执行 `generate <module>` | 生成 `README.md`、`SPEC.md`、`TRACEABILITY.md`、`goal.md`、`IMPLEMENTATION-PLAN.md`、`ACCEPTANCE.md`、`FEATURES.md`、`tasks/TASK-001.md`、`Makefile`、`.github/workflows/ci.yml` |
| FR-002 | spec-lint | 给定模块 `SPEC.md` | 用户执行 `check <module> --profile spec` | 检查 23 节结构、FR Given/When/Then、AC/TC 可验证性 |
| FR-003 | boundary-check | 给定模块 `go.mod` 和 Go 源码 | 用户执行 `check <module> --profile boundary` | 拒绝 `observex`、`configx`、`resiliencx`、`schedulex`、`testkitx`、`xlib_standard` 运行时引用 |
| FR-004 | ci-reference-check | 给定模块 CI/CD 文件和 Makefile | 用户执行 `check <module> --profile full` | 验证 CI/CD 关键引用、`make ci` 和 release workflow 存在 |
| FR-005 | format-check | 给定模块 Markdown 文档 | 用户执行 `check <module> --profile full` | 检查尾随空格、空 Markdown 链接和表格列漂移 |
| FR-006 | traceability-gate | 给定 `TRACEABILITY.md` 与规格 FR/AC/TC | 用户执行 `check <module> --profile full` | 验证每个 FR 都闭合到 AC 和 TC，且 AC/TC 被矩阵引用 |

## 7. 行为约束

| ID | Rule | Verification |
| --- | --- | --- |
| BR-001 | `generate` 应在 5 秒内完成标准文档集合生成 | benchmark 与 smoke test |
| BR-002 | `check` 不得修改被检模块文件 | 单元测试与只读实现 |
| BR-003 | `check` 失败退出码必须非零 | CLI 负例测试 |
| BR-004 | `--json` 输出必须可被自动化消费 | JSON 单元测试与 CLI smoke |
| BR-005 | 发布门禁必须验证公开功能/验收文档与免许可证 secret scan | GitHub Actions Release run 与 main CI run |

### Acceptance Criteria Registry

| AC ID | FR/BR Ref | TC Ref | Criterion | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| AC-001 | FR-001 | TC-001 | 生成 10 个标准模块资产 | `xlib_harness generate /tmp/xlib_harness-smoke --force` | PASS |
| AC-002 | FR-002 | TC-002 | compliant fixture 通过 spec profile | `xlib_harness check fixtures/compliant-module --profile spec` | PASS |
| AC-003 | FR-003 | TC-003 | bad-dependency fixture 被 boundary profile 拒绝 | `xlib_harness check fixtures/module-with-bad-dep --profile boundary` | PASS |
| AC-004 | FR-004 | TC-004 | compliant fixture 通过 full profile CI/CD 引用检查 | `xlib_harness check fixtures/compliant-module --profile full` | PASS |
| AC-005 | FR-005 | TC-005 | Markdown 格式问题被报告 | Go unit tests | PASS |
| AC-006 | FR-006 | TC-006 | broken-trace fixture 被 full profile 拒绝 | `xlib_harness check fixtures/broken-trace --profile full` | PASS |
| AC-007 | BR-005 | TC-007 | 代码仓库公开文档与 secret scan 被发布门禁验证 | GitHub Actions Release run `27855366871` and main CI run `27855396013` | PASS |

## 8. 接口契约

```go
type GateProfile string

const (
    ProfileSpec     GateProfile = "spec"
    ProfileBoundary GateProfile = "boundary"
    ProfileFull     GateProfile = "full"
)

type Generator interface {
    Generate(module string, opts ...GenerateOption) (*GenerateResult, error)
}

type HarnessGate interface {
    Check(modulePath string, profile GateProfile) CheckResult
}
```

## 9. 数据模型

```go
type GenerateResult struct {
    Module       string   `json:"module"`
    Root         string   `json:"root"`
    FilesCreated []string `json:"files_created"`
    Warnings     []string `json:"warnings,omitempty"`
}

type CheckResult struct {
    Module  string      `json:"module"`
    Profile string      `json:"profile"`
    Passed  bool        `json:"passed"`
    Checks  []CheckItem `json:"checks"`
    Summary string      `json:"summary"`
}

type CheckItem struct {
    Name   string `json:"name"`
    Passed bool   `json:"passed"`
    Detail string `json:"detail"`
}
```

## 10. 配置模式

默认配置由 CLI 参数和内嵌标准模板决定，不读取远端模板目录：

```yaml
xlib_harness:
  template_source: embedded-stdlib
  profiles:
    spec:
      - required-assets
      - spec-section-depth
      - spec-23-section-structure
      - spec-fr-when-then
      - spec-ac-verifiability
      - spec-test-commands
    boundary:
      - forbidden-dependencies
    full:
      - spec
      - boundary
      - traceability-closure
      - format-check
      - ci-reference-check
```

## 11. 错误处理

| Failure | Meaning | Caller Handling |
| --- | --- | --- |
| 目标路径已存在且未传 `--force` | generate 防止覆盖已有资产 | 传入 `--force` 或选择新路径 |
| 模块路径无效或不可读取 | check 无法读取目标模块 | 修复路径或权限 |
| 门禁检查未通过 | `CheckResult.Passed=false` 且 CLI 非零退出 | 查看 `checks[].detail` 并修复模块 |
| JSON 编码失败 | 输出流异常 | 重试或检查调用方管道 |

## 12. 边界情况

- 模块路径包含路径遍历或非法字符。
- 目标目录存在部分文件，且未显式 `--force`。
- `SPEC.md` 缺少 23 节或缺少 FR/AC/TC 链条。
- `go.mod` 或 Go imports 引入禁止依赖。
- Markdown 表格存在列数漂移。
- `TRACEABILITY.md` 引用不存在的 AC/TC 或遗漏 FR。

## 13. 目录结构

```text
module/xlib_harness/
  goal.md
  SPEC.md
  TRACEABILITY.md
  IMPLEMENTATION-PLAN.md
  ACCEPTANCE.md
  FEATURES.md
  ci-workflow.yaml
  tasks/
    TASK-XLIBHARNESS-001.md
    TASK-XLIBHARNESS-002.md
    TASK-XLIBHARNESS-003.md
    TASK-XLIBHARNESS-004.md
    TASK-XLIBHARNESS-005.md
    TASK-XLIBHARNESS-006.md
    TASK-XLIBHARNESS-007.md
```

Module implementation lives in `/home/xlib_harness`; this root repository only stores governance projection documents.

## 14. 依赖

- Runtime: Go standard library only.
- CI tooling: `xlibgate@v1.0.0`, pinned open-source `gitleaks` CLI, GitHub CLI release step.
- Forbidden runtime refs: `observex`、`configx`、`resiliencx`、`schedulex`、`testkitx`、`xlib_standard`。
- Forbidden scope: business-domain modules, credentials, exchange endpoints, live trading config。

## 15. 测试

- 单元测试：CLI 参数、JSON 输出、各门禁 helper、错误路径。
- 集成测试：generate → check，compliant fixture full profile。
- 负例测试：bad-dependency、broken-trace、format issue。
- 覆盖率测试：`go test ./... -coverprofile=coverage.out -covermode=count && go tool cover -func=coverage.out`，要求 total 100.0%。
- 基准测试：`go test -bench=. ./...`。
- 发布文档契约：CI/CD 验证 `README.md`、`FEATURES.md`、`ACCEPTANCE.md` 和 workflow 文件存在且非空。

### 15.1 Traceability Test Cases

| TC ID | Scenario | Command | Expected |
| --- | --- | --- | --- |
| TC-001 | Generate module docs | `go run . generate /tmp/xlib_harness-smoke --force` | 10 个资产创建成功 |
| TC-002 | Spec gate accepts compliant module | `go run . check fixtures/compliant-module --profile spec` | 规格检查全部通过 |
| TC-003 | Boundary gate rejects forbidden dependency | `go run . check fixtures/module-with-bad-dep --profile boundary` | 非零退出并报告禁止依赖 |
| TC-004 | Full gate accepts compliant module | `go run . check fixtures/compliant-module --profile full` | 15 项检查全部通过 |
| TC-005 | Format checks detect markdown issues | Go unit tests | trailing whitespace、空链接、表格漂移均被覆盖 |
| TC-006 | Trace gate rejects incomplete matrix | `go run . check fixtures/broken-trace --profile full` | 非零退出并报告追踪断链 |
| TC-007 | Release docs and secret scan gates pass | GitHub Actions Release run `27855366871` and main CI run `27855396013` | `FEATURES.md`、`ACCEPTANCE.md` 与 pinned `gitleaks` CLI 均通过 |

## 16. 性能预算

| Metric | Target | Current Evidence |
| --- | --- | --- |
| Generate latency | < 5s | `BenchmarkGenerate-16` 462076 ns/op |
| Full profile check latency | < 10s | `BenchmarkCheckFullProfile-16` 2468222 ns/op |
| Coverage | 100.0% | `go tool cover -func=coverage.out` total 100.0% |

## 17. 可观测性

- CLI text 输出展示逐项门禁结果。
- `--json` 输出 `CheckResult`，供 CI 和审查工具消费。
- 不暴露业务运行时指标，不持久化证据数据库。

## 18. 安全

- 不读取、存储或输出凭证。
- 不执行远程代码。
- 不连接外部生产服务。
- 路径处理通过标准库文件 API，生成路径需显式传入。
- CI secret scan 使用 pinned open-source `gitleaks` CLI 扫描仓库历史；本地与 CI 均无真实凭证命中。

## 19. CI 门禁

Required local gates:

- `go build ./...`
- `go test ./...`
- `go test ./... -race -count=1`
- `go vet ./...`
- `go test ./... -coverprofile=coverage.out -covermode=count`
- `go tool cover -func=coverage.out`
- `go test -bench=. ./...`
- `make ci`
- `git diff --check`

GitHub Actions:

- `.github/workflows/ci.yml`: docs contract、Go validation、trust alignment、pinned CLI secret scan。
- `.github/workflows/release.yml`: tag-triggered release with `make ci`、`xlibgate@v1.0.0` and release docs contract。

## 20. 升级兼容性

- `spec`、`boundary`、`full` profile names remain stable for v0.x。
- `CheckResult` JSON field names are stable for automation consumers。
- New checks may be added to `full` only when fixtures and root projection are updated together。

## 21. 发布 DoD

- [x] SPEC Approved。
- [x] 所有 FR 实现并测试。
- [x] compliant fixture full profile 通过。
- [x] bad-dependency 与 broken-trace 负例稳定失败。
- [x] 覆盖率 total 100.0%。
- [x] `make ci` 通过。
- [x] CI/CD workflow 配置完成。
- [x] 本地 release tag `v0.1.6` 创建。
- [x] GitHub Release `v0.1.6` 发布并验证。
- [x] GitHub Actions main CI run `27855396013` 通过。

## 22. 待解决问题

- GitHub Actions 当前存在非阻断注解：actions Node.js 20 deprecation 提示，以及无 `go.sum` 时缓存恢复提示。
- 是否把 root 投影检查纳入统一 `xlibgate` 门禁，留待下一版本评估。
- 是否允许用户自定义 profile 组合，留待已有 profile 稳定后评估。

## 23. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
| --- | --- | --- | --- |
| 2026-06-20 | v0.1.6 | 将 secret scan 切换为免许可证 pinned CLI，补齐代码仓库 FEATURES/ACCEPTANCE 发布文档契约，Release 与 main CI 均通过 | ZoneCNH |
| 2026-06-20 | v0.1.5 | 补齐代码仓库公开 FEATURES/ACCEPTANCE 文档；main CI 暴露外部 secret scan action license gate，后续由 v0.1.6 修复 | ZoneCNH |
| 2026-06-20 | v0.1.4 | 修复 CI/CD trust tooling 可安装性，强化 Markdown fenced code 解析，重新验收 100% 覆盖率并发布 GitHub Release | ZoneCNH |
| 2026-06-20 | v0.1.3 | 中间发布候选，补齐生产级门禁、100% 覆盖率与 CI/CD 雏形，后续由 v0.1.4 修复 trust tooling pin | ZoneCNH |
| 2026-06-18 | v0.1.1 | 补齐验收证据、性能基线与发布文档同步 | ZoneCNH |
| 2026-06-14 | v1.0.0 | 初始版本，从标准模板拆分 harness 目标 | ZoneCNH |
