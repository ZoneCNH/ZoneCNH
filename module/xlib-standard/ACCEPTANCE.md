# xlib-standard 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v1.0.0
- Module-State: 已发布
- Layer: L1 工程标准
- Runtime-Repo: /home/xlib-standard
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, README.md, tasks/, prompt/

> 本清单用于验收 xlib-standard 是否达到可发布、可追溯、可复验状态。除非条目明确记录为已通过，默认需要在运行时代码仓库重新执行验证并补充证据。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/xlib-standard/FEATURES.md && test -f module/xlib-standard/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/xlib-standard | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/xlib-standard && GOWORK=off go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/xlib-standard && GOWORK=off go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/xlib-standard && GOWORK=off go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/xlib-standard && GOWORK=off go test ./... -coverprofile=/tmp/xlib-standard-coverage.out && test -s /tmp/xlib-standard-coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/xlib-standard && GOWORK=off go list -deps ./... | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界 |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-000 | 管线基线清理完成，模块文档和任务入口可被规则评分器发现。 | python3 scripts/rule-scorer.py spec xlib-standard / module/xlib-standard/SPEC.md | - | SPEC.md |
| AC-001 | 必填字段缺失时配置校验返回 validation kind 错误。 | GOWORK=off go test ./pkg/templatex/ -run TestConfigValidate/Required -count=1 / pkg/templatex/config.go:23-32 | - | SPEC.md |
| AC-002 | 负数 timeout 配置返回 validation kind 错误。 | GOWORK=off go test ./pkg/templatex/ -run TestConfigValidate/Negative -count=1 / pkg/templatex/config.go:28-31 | - | SPEC.md |
| AC-003 | 配置脱敏后 secret 类字段显示为 ***。 | GOWORK=off go test ./pkg/templatex/ -run TestConfigSanitize -count=1 / pkg/templatex/config.go:34-39 | - | SPEC.md |
| AC-004 | NewError 创建的错误字段完整。 | GOWORK=off go test ./pkg/templatex/ -run TestNewError -count=1 / pkg/templatex/errors.go:28-34 | - | SPEC.md |
| AC-005 | WrapError 包装后 errors.Is 可穿透。 | GOWORK=off go test ./pkg/templatex/ -run TestWrapError -count=1 / pkg/templatex/errors.go:34-36,55-59 | - | SPEC.md |
| AC-006 | IsKind 匹配目标 kind 返回 true。 | GOWORK=off go test ./pkg/templatex/ -run TestIsKind -count=1 / pkg/templatex/errors.go:62-67 | - | SPEC.md |
| AC-007 | deadline cause 归一为 timeout kind。 | GOWORK=off go test ./pkg/templatex/ -run TestContextError/Deadline -count=1 / pkg/templatex/errors.go:87-96 | - | SPEC.md |
| AC-008 | canceled cause 归一为 unavailable kind。 | GOWORK=off go test ./pkg/templatex/ -run TestContextError/Canceled -count=1 / pkg/templatex/errors.go:87-96 | - | SPEC.md |
| AC-009 | nil context 健康检查返回 unhealthy。 | GOWORK=off go test ./pkg/templatex/ -run TestHealthCheck/NilContext -count=1 / pkg/templatex/health.go:44-50 | - | SPEC.md |
| AC-010 | 健康客户端返回 healthy。 | GOWORK=off go test ./pkg/templatex/ -run TestHealthCheck/Healthy -count=1 / pkg/templatex/health.go:98-103 | - | SPEC.md |
| AC-011 | NoopMetrics 调用不 panic。 | GOWORK=off go test ./pkg/templatex/ -run TestNoopMetrics -count=1 / pkg/templatex/metrics.go:21-27 | - | SPEC.md |
| AC-012 | P0 指标名与 contract 一致。 | GOWORK=off go test ./pkg/templatex/ -run TestMetricsNames -count=1 / pkg/templatex/metrics.go:15-19 | - | SPEC.md |
| AC-013 | metrics label 仅使用低基数键。 | GOWORK=off go test ./pkg/templatex/ -run TestMetricsLabels -count=1 / pkg/templatex/metrics.go:15-19 | - | SPEC.md |
| AC-014 | nil context 创建客户端返回错误。 | GOWORK=off go test ./pkg/templatex/ -run TestNew/NilContext -count=1 / pkg/templatex/client.go:24-28 | - | SPEC.md |
| AC-015 | canceled context 创建客户端返回错误。 | GOWORK=off go test ./pkg/templatex/ -run TestNew/CanceledContext -count=1 / pkg/templatex/client.go:29-33 | - | SPEC.md |
| AC-016 | 无效 config 创建客户端返回错误。 | GOWORK=off go test ./pkg/templatex/ -run TestNew/InvalidConfig -count=1 / pkg/templatex/client.go:33-37 | - | SPEC.md |
| AC-017 | 有效参数创建 *Client。 | GOWORK=off go test ./pkg/templatex/ -run TestNew/Valid -count=1 / pkg/templatex/client.go:38-39 | - | SPEC.md |
| AC-018 | Close 多次调用幂等且不 panic。 | GOWORK=off go test ./pkg/templatex/ -run TestClose/Idempotent -count=1 / pkg/templatex/client.go:45-68 | - | SPEC.md |
| AC-019 | 版本信息包含 module name 和 version。 | GOWORK=off go test ./pkg/templatex/ -run TestVersion -count=1 / pkg/templatex/version.go:6-7 | - | SPEC.md |
| AC-020 | 模板 go vet 零警告。 | GOWORK=off go vet ./pkg/templatex/... / pkg/templatex/... | - | SPEC.md |
| AC-021 | 模板 go test 全部通过。 | GOWORK=off go test ./pkg/templatex/... -count=1 / pkg/templatex/*_test.go | - | SPEC.md |
| AC-022 | 渲染输出目录结构完整。 | out_dir="$(mktemp -d)" && bash scripts/render_template.sh --module-name testlib --module-path example.com/testlib --package-name testlib --out "$out_dir" && test -f "$out_dir/go.mod" / scripts/render_template.sh | - | SPEC.md |
| AC-023 | 生成库无模板名和标准库名残留。 | out_dir="$(mktemp -d)" && bash scripts/render_template.sh --module-name testlib --module-path example.com/testlib --package-name testlib --out "$out_dir" && bash scripts/check_rendered_template.sh "$out_dir" testlib example.com/testlib testlib / scripts/check_rendered_template.sh | - | SPEC.md |
| AC-024 | make ci 的 17 个 gate 全部通过。 | GOWORK=off make ci / Makefile (ci: target) | - | SPEC.md |
| AC-025 | boundary gate 检查 6 类非法引用。 | bash scripts/check_boundary.sh / scripts/check_boundary.sh | - | SPEC.md |
| AC-026 | release manifest 生成且字段完整。 | GOWORK=off make release-check / Makefile (release-check) + scripts/generate_manifest.sh | - | SPEC.md |
| AC-027 | release final check 校验 manifest checksum。 | GOWORK=off make release-final-check / Makefile (release-final-check) | - | SPEC.md |
| AC-028 | goalcli audit 输出 G0-G11 gate 状态审计报告。 | GOWORK=off go run ./cmd/goalcli audit-goal --json / cmd/goalcli/audit_goal.go | - | SPEC.md |
| AC-029 | goalcli dashboard 生成符合 goalcli-dashboard schema 的仪表盘 JSON。 | GOWORK=off go run ./cmd/goalcli dashboard-generate --format json > /tmp/xlib-standard-dashboard.json && test -s /tmp/xlib-standard-dashboard.json / cmd/goalcli/dashboard_generate.go | - | SPEC.md |
| AC-030 | goalcli fact 执行事实检查并输出 fact-audit 证据。 | GOWORK=off go run ./cmd/goalcli fact audit --strict --json / cmd/goalcli/fact.go | - | SPEC.md |
| AC-031 | goalcli schema-check 校验 contracts/ 中所有 schema 有效性。 | GOWORK=off go run ./cmd/goalcli schema-check --all --report /tmp/xlib-standard-schema-check.json --json / cmd/goalcli/schema_check.go | - | SPEC.md |
| AC-032 | goalcli traceability 生成 FR→Code 追溯矩阵。 | GOWORK=off go run ./cmd/goalcli traceability-check --json / cmd/goalcli/traceability.go | - | SPEC.md |
| AC-033 | goalcli governance 输出远端治理检查结果。 | GOWORK=off go run ./cmd/goalcli github-governance / cmd/goalcli/governance.go | - | SPEC.md |
| AC-034 | goalcli debt 扫描技术债务并输出债务报告。 | GOWORK=off go run ./cmd/goalcli debt --output json / cmd/goalcli/debt.go | - | SPEC.md |
| AC-035 | goalcli adoption 检查下游采纳状态。 | GOWORK=off go run ./cmd/goalcli adoption-check --verify --json / cmd/goalcli/adoption_check.go | - | SPEC.md |
| AC-036 | goalcli selfimproving 触发受控递归自改进流程。 | GOWORK=off go run ./cmd/goalcli self-improving-check --strict / cmd/goalcli/selfimproving.go | - | SPEC.md |
| AC-037 | templates/l2/ 12 个模板文件全部存在且可渲染。 | bash scripts/check_l2_templates.sh / templates/l2/ | - | SPEC.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | Unit | Config 必填字段缺失 / 返回 validation kind / pkg/templatex/config_test.go | - | SPEC.md |
| TC-002 | Unit | Config 负数 timeout / 返回 validation kind / pkg/templatex/config_test.go | - | SPEC.md |
| TC-003 | Unit | Config 脱敏 / secret 替换为 *** / pkg/templatex/config_test.go | - | SPEC.md |
| TC-004 | Unit | NewError 创建 / 字段正确 / pkg/templatex/errors_test.go | - | SPEC.md |
| TC-005 | Unit | WrapError 包装 / errors.Is 可穿透 / pkg/templatex/errors_test.go | - | SPEC.md |
| TC-006 | Unit | IsKind 匹配 / 返回 true / pkg/templatex/errors_test.go | - | SPEC.md |
| TC-007 | Unit | deadline cause / kind 为 timeout / pkg/templatex/errors_test.go | - | SPEC.md |
| TC-008 | Unit | canceled cause / kind 为 unavailable / pkg/templatex/errors_test.go | - | SPEC.md |
| TC-009 | Unit | HealthCheck nil context / 返回 unhealthy / pkg/templatex/health_test.go | - | SPEC.md |
| TC-010 | Unit | HealthCheck 健康客户端 / 返回 healthy / pkg/templatex/health_test.go | - | SPEC.md |
| TC-011 | Unit | NoopMetrics 调用 / 无 panic / pkg/templatex/metrics_test.go | - | SPEC.md |
| TC-012 | Unit | 指标名匹配 contract / P0 名称一致 / pkg/templatex/metrics_test.go | - | SPEC.md |
| TC-013 | Unit | label 低基数 / 只有允许键 / pkg/templatex/metrics_test.go | - | SPEC.md |
| TC-014 | Unit | New nil context / 返回错误 / pkg/templatex/client_test.go | - | SPEC.md |
| TC-015 | Unit | New canceled context / 返回错误 / pkg/templatex/client_test.go | - | SPEC.md |
| TC-016 | Unit | New 无效 config / 返回错误 / pkg/templatex/client_test.go | - | SPEC.md |
| TC-017 | Unit | New 正常创建 / 返回客户端 / pkg/templatex/client_test.go | - | SPEC.md |
| TC-018 | Unit | Close 幂等 / 多次调用不 panic / pkg/templatex/client_test.go | - | SPEC.md |
| TC-019 | Integration | 模板 go vet / 零警告 / pkg/templatex/version_test.go | - | SPEC.md |
| TC-020 | Integration | 模板 go test / 全部通过 / pkg/templatex/*.go (go vet) | - | SPEC.md |
| TC-021 | Integration | 渲染模板 / 输出结构完整 / pkg/templatex/*_test.go | - | SPEC.md |
| TC-022 | Integration | 检查生成库残留 / 无非法残留 / scripts/render_template.sh | - | SPEC.md |
| TC-023 | Integration | make ci / 17 个 gate 全通过 / scripts/check_rendered_template.sh | - | SPEC.md |
| TC-024 | Integration | release manifest / 字段完整且 checksum 可校验 / Makefile (release-check) + scripts/generate_manifest.sh | - | SPEC.md |
| TC-025 | Integration | goalcli audit / 输出 G0-G11 审计报告 / cmd/goalcli/audit_goal_test.go | - | SPEC.md |
| TC-026 | Integration | goalcli dashboard / 输出合规仪表盘 JSON / cmd/goalcli/dashboard_generate_test.go | - | SPEC.md |
| TC-027 | Integration | goalcli fact / 输出 fact-audit 证据 / cmd/goalcli/fact.go + internal/xlibfacts/ | - | SPEC.md |
| TC-028 | Integration | goalcli schema-check / 全 schema 校验通过 / cmd/goalcli/schema_check_test.go | - | SPEC.md |
| TC-029 | Integration | goalcli traceability / 生成 FR→Code 追溯矩阵 / cmd/goalcli/traceability_test.go | - | SPEC.md |
| TC-030 | Integration | goalcli governance / 输出远端治理状态 / cmd/goalcli/governance.go | - | SPEC.md |
| TC-031 | Integration | goalcli debt / 输出技术债务报告 / cmd/goalcli/debt.go + internal/debtcheck/ | - | SPEC.md |
| TC-032 | Integration | goalcli adoption / 输出下游采纳状态 / cmd/goalcli/adoption_check.go | - | SPEC.md |
| TC-033 | Integration | goalcli selfimproving / 自改进流程正常执行 / cmd/goalcli/selfimproving_test.go | - | SPEC.md |
| TC-034 | Integration | templates/l2 完整性检查 / 12 模板文件在位 / templates/l2/ (12 files) | - | SPEC.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | Config 标准快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-002 | Error 标准快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-003 | Health 标准快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-004 | Metrics 标准快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-005 | Client 标准快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-006 | Version 标准快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-007 | 公共 API 模板快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-008 | 模板可编译快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-009 | render_template.sh 渲染快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-010 | 生成库无模板残留快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-011 | CI gate快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-012 | boundary gate快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-013 | release manifest快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-014 | release final check快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-015 | Evidence Runtime CLI快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-016 | L2 下游仓库模板快照锚点 | module/xlib-standard/SPEC.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-017 | 上游标准快照契约 17快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-018 | 上游标准快照契约 18快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-019 | 上游标准快照契约 19快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-020 | 上游标准快照契约 20快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-021 | 上游标准快照契约 21快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-022 | 上游标准快照契约 22快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-023 | 上游标准快照契约 23快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-024 | 上游标准快照契约 24快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-025 | 上游标准快照契约 25快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-026 | 上游标准快照契约 26快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-027 | 上游标准快照契约 27快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-028 | 上游标准快照契约 28快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-029 | 上游标准快照契约 29快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-030 | 上游标准快照契约 30快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-031 | 上游标准快照契约 31快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-032 | 上游标准快照契约 32快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-033 | 上游标准快照契约 33快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-034 | 上游标准快照契约 34快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-035 | 上游标准快照契约 35快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-036 | 上游标准快照契约 36快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-037 | 上游标准快照契约 37快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-038 | 上游标准快照契约 38快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-039 | 上游标准快照契约 39快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-040 | 上游标准快照契约 40快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-041 | 上游标准快照契约 41快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-042 | 上游标准快照契约 42快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-043 | 上游标准快照契约 43快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-044 | 上游标准快照契约 44快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-045 | 上游标准快照契约 45快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-046 | 上游标准快照契约 46快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-047 | 上游标准快照契约 47快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-048 | 上游标准快照契约 48快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-049 | 上游标准快照契约 49快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-050 | 上游标准快照契约 50快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-051 | 上游标准快照契约 51快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| FR-052 | 上游标准快照契约 52快照锚点 | module/xlib-standard/ANALYSIS.md / line / archived-snapshot | - | TRACEABILITY.md |
| BR-001 | 配置显式传入：库不得读取隐式环境配置；调用方必须显式传入配置结构 | `grep -RnE "os.Getenv\|os.LookupEnv" pkg/templatex/` 返回 0 | ✅ | SPEC.md §7 BR-001 |
| BR-002 | 错误消息格式：公共错误消息稳定、短句化；优先断言 kind | AC-004..008 / `go test ./pkg/templatex/ -run "TestNewError\|TestWrapError\|TestIsKind\|TestContextError"` | ✅ | SPEC.md §7 BR-002 |
| BR-003 | Metrics label 低基数（仅允许 op/kind/status） | AC-013 / `go test ./pkg/templatex/ -run TestMetricsLabels` | ✅ | SPEC.md §7 BR-003 |
| BR-004 | 模板占位符完整性：渲染脚本必须替换所有模板占位符；缺少必要参数时必须失败 | AC-022/023 / `out_dir="$(mktemp -d)" && bash scripts/render_template.sh --module-name testlib --module-path example.com/testlib --package-name testlib --out "$out_dir" && bash scripts/check_rendered_template.sh "$out_dir" testlib example.com/testlib testlib` | ✅ | SPEC.md §7 BR-004 |
| BR-005 | 生成库独立性：生成库必须可脱离标准模板仓库独立构建、测试和发布 | AC-023/024 / `out_dir="$(mktemp -d)" && bash scripts/render_template.sh --module-name testlib --module-path example.com/testlib --package-name testlib --out "$out_dir" && bash scripts/check_rendered_template.sh "$out_dir" testlib example.com/testlib testlib && cd "$out_dir" && GOWORK=off go vet ./... && GOWORK=off go test ./...` | ✅ | SPEC.md §7 BR-005 |
| BR-006 | 库中禁止退出进程（log.Fatal/os.Exit） | `grep -RnE "log\.Fatal\|os\.Exit" pkg/templatex/` 返回 0 / boundary gate | ✅ | SPEC.md §7 BR-006 |
| BR-007 | Sanitize 脱敏覆盖 secret、token、key、password 类字段，并保留非敏感配置 | AC-003 / `go test ./pkg/templatex/ -run TestConfigSanitize -count=1` | ✅ | SPEC.md §7 BR-007 |

## 5. 发布 DoD 清单

- [ ] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [ ] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [ ] 运行时代码仓库 /home/xlib-standard 通过 go test、go test -race、go vet 与覆盖率门槛。
- [ ] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [ ] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [ ] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 6. 当前缺口登记

- 当前文档只记录验收口径，不替代运行时代码仓库的最新 CI 结果。
- 若上表存在 Pending、Draft、Blocked、Open 或未登记状态，发布前必须补充证据或在模块追溯矩阵中登记豁免理由。
- SPEC/TRACEABILITY 已登记 AC/TC 主链路；当前主要缺口是 /home/xlib-standard 最新测试、race/vet、覆盖率、release manifest 与模板生成库复验证据需要归档。
