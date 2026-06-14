# Context Packet — Trust Alignment 子命令组

> 覆盖 TASK-XLIBGATE-010 ~ TASK-XLIBGATE-019
> 来源：SPEC.md v1.1.1, PLAN.md, DESIGN.md §12

---

## Context

Trust Alignment 是 xlibgate v2 新增的第三组子命令（check / l2 / trust），负责 Foundation 70+ 模块的信任对齐验证。8 个检查器消费 xlib-standard 定义的标准文件（.repo-contract.yaml、FOUNDATION-DEPS.yaml），输出统一的 per-check JSON 格式（§9.3.1）。

**依赖**：xlib-standard Gate/Evidence 标准定义已完成。
**并行度**：8 个检查器完全独立，CI 中可并行执行。
**测试覆盖**：TC-014~TC-029（16 条验收标准）。

---

## Scope

### 统一输出格式（scanner/trust/common.go）

```go
type TrustResult struct {
    Check      string     `json:"check"`
    Repo       string     `json:"repo"`
    Status     string     `json:"status"`     // pass|fail|error
    Severity   string     `json:"severity"`   // info|warn|block
    Findings   []Finding  `json:"findings"`
    ReasonCode string     `json:"reason_code"`
    Evidence   any        `json:"evidence"`
}
```

### reason_code 枚举（10 值）

`IDENTITY_MISMATCH`, `TEMPLATE_RESIDUE`, `TEMPLATE_RESIDUE_SELF_SKIP`, `RELEASE_DRIFT`, `FACTORY_GATE_BLOCKED`, `IMPORT_BOUNDARY_VIOLATION`, `TESTKIT_PROD_IMPORT`, `SECRET_LEAK`, `PRIVATE_ENDPOINT_LEAK`, `CONTRACT_PARSE_ERROR`

### Shared Constraints

- 不依赖 Foundation 运行时模块（纯 CLI，stdlib + yaml.v3）
- exit code: 0=pass, 1=fail, 2=error
- findings 含 File+Line，不输出密钥原文
- 统一 JSON 通过 `scanner/trust/common.go` 共享

---

## Non-scope

- 不实现具体检查逻辑（由各 TASK 负责）
- 不修改 check/l2 子命令
- 不依赖 Foundation 运行时模块

## Acceptance

### 010: trust 框架
- **Files**: cmd/trust.go, scanner/trust/common.go
- **AC**: `xlibgate trust --help` 输出 8 子命令；统一 JSON 格式正确
- **Non-scope**: 不实现具体检查逻辑

### 011: trust identity（五源比对）
- **Files**: cmd/trust_identity.go, scanner/trust/identity.go
- **AC**: TC-014（pass）/ TC-015（IDENTITY_MISMATCH）/ CONTRACT_PARSE_ERROR
- **Non-scope**: 不检查 SPEC.md 内容，不验证 go.mod 依赖版本

### 012: trust template-residue（BR-010 短语扫描）
- **Files**: cmd/trust_template.go, scanner/trust/template.go
- **AC**: TC-016（pass）/ TC-017（TEMPLATE_RESIDUE）/ xlib-standard 自跳 / --summary 统计
- **5 禁止短语**（精确字符串匹配）："承担五类职责：Standard Source..."，"本仓库不再把标准源与模板实现拆成两个角色"，"提供可编译参考包 pkg/templatex"，"渲染后会移动到 pkg/<package-name>"，"生成库包括 configx、observex、testkitx"
- **Non-scope**: 不扫描二进制文件，不做模糊匹配

### 013: trust release-consistency（七源一致性）
- **Files**: cmd/trust_release.go, scanner/trust/release.go
- **AC**: TC-018（pass）/ TC-019（RELEASE_DRIFT）/ VERSION/CHANGELOG 缺失
- **Non-scope**: 不修改 VERSION/CHANGELOG，不做语义化版本比较
- **七源**: .repo-contract.yaml / go.mod / VERSION / CHANGELOG / git tag / release manifest / GitHub release

### 014: trust maturity（11 维工厂级判定）
- **Files**: cmd/trust_maturity.go, scanner/trust/maturity.go
- **AC**: TC-020（pass）/ TC-021（FACTORY_GATE_BLOCKED）/ 单百分比拒绝
- **11 维**: spec_complete, implementation_complete, unit_tests_complete, contract_tests_complete, traceability_complete, release_manifest_complete, live_integration_complete, failure_profiles_complete, external_ci_artifacts_complete, downstream_adoption_complete, production_soak_complete
- **Non-scope**: 不自动修复未满足维度

### 015: trust import-boundary（FOUNDATION-DEPS.yaml 驱动）
- **Files**: cmd/trust_boundary.go, scanner/trust/boundary.go
- **AC**: TC-022（pass）/ TC-023（IMPORT_BOUNDARY_VIOLATION）/ kernel_stdlib_violation
- **Non-scope**: 不实现 check imports 逻辑（独立实现），不解析间接依赖

### 016: trust testkit-prod-import（生产隔离）
- **Files**: cmd/trust_testkit.go, scanner/trust/testkit.go
- **AC**: TC-024（pass）/ TC-025（TESTKIT_PROD_IMPORT）/ --strict 模式
- **路径分类**: pkg/=生产, internal/=生产, cmd/=生产; *_test.go=允许, test/=允许, testkit/=允许
- **Non-scope**: 不检查 go.mod testkitx 依赖

### 017: trust secret-redaction（文档脱敏）
- **Files**: cmd/trust_secret.go, scanner/trust/secret.go
- **AC**: TC-026（pass）/ TC-027（SECRET_LEAK 脱敏输出）/ PRIVATE_ENDPOINT_LEAK
- **开发上下文豁免**: test/, testdata/, *_test.go, dev-only markdown, README 本地开发章节
- **Non-scope**: 不使用 gitleaks（check all 专用），不输出密钥原文

### 018: trust fleet-status（舰队聚合）
- **Files**: cmd/trust_fleet.go, scanner/trust/fleet.go
- **AC**: TC-028（pass, 20 模块全成功）/ TC-029（partial fail, 仍生成 index.json）/ --summary-only
- **Non-scope**: 不嵌套调用 CLI，不推送 index.json

### 019: 集成测试 + 文档
- **Files**: README.md, CHANGELOG.md, integration_test.go
- **AC**: 所有 trust 子命令集成测试通过；TC-014~TC-029 全部覆盖；覆盖率 >= 80%

---

## Validation

```bash
# 并行执行所有 trust 检查
xlibgate trust identity --repo . &
xlibgate trust template-residue --repo . &
xlibgate trust release-consistency --offline --repo . &
xlibgate trust maturity --factory --repo . &
xlibgate trust import-boundary --repo . --deps FOUNDATION-DEPS.yaml &
xlibgate trust testkit-prod-import --repo . &
xlibgate trust secret-redaction --repo . --path release/evidence &
wait

# 舰队聚合（依赖上述独立检查完成）
xlibgate trust fleet-status --repos-root .. --output .foundationx/status/index.json

# 全量测试
go test -race -count=1 ./...
go tool cover -func=.coverage/cover.out | grep total | awk '{print $3}'  # >= 80%
```
