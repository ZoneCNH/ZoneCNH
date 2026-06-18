# xlib-harness 完整验收清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v0.1.1
- Module-State: 已发布
- Layer: L1 执行器
- Runtime-Repo: /home/xlib-harness
- Acceptance-Baseline: /home/xlib-harness@335eef9
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于验收 xlib-harness 是否达到可发布、可追溯、可复验状态。未明确标记为 ✅ 的条目发布前不得视为通过。

## 1. 验收命令清单

| 类别 | 命令 | 通过标准 |
| --- | --- | --- |
| 文档存在性 | cd /home/ZoneCNH && test -f module/xlib-harness/FEATURES.md && test -f module/xlib-harness/ACCEPTANCE.md | FEATURES.md 与 ACCEPTANCE.md 均存在 |
| 文档格式 | cd /home/ZoneCNH && git diff --check -- module/xlib-harness | 无尾随空格或补丁格式错误 |
| 运行时测试 | cd /home/xlib-harness && go test ./... | 所有包测试通过 |
| 竞态检查 | cd /home/xlib-harness && go test ./... -race -count=1 | 无 data race，测试稳定通过 |
| 静态检查 | cd /home/xlib-harness && go vet ./... | 无 vet 问题 |
| 覆盖率证据 | cd /home/xlib-harness && go test ./... -coverprofile=coverage.out | 覆盖率文件生成并满足模块 Spec 门槛 |
| 依赖边界 | cd /home/xlib-harness && go list -deps ./... && go list -m all | 依赖不越过 FOUNDATION-DEPS.yaml 登记边界，且不出现 github.com/ZoneCNH/xlib-standard import/module dependency |

## 2. AC 验收登记

| ID | 验收项 | 关联要求/测试/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| AC-001 | FR-001 | 生成目录包含 SPEC.md / TRACEABILITY.md / goal.md / tasks/ / IMPLEMENTATION-PLAN.md / ls module// file inventory check | ✅ | TRACEABILITY.md |
| AC-002 | FR-002 | 检查 23 节结构、WHEN/THEN 格式、AC 可验证性 / spec-lint 输出逐项 PASS/FAIL | ✅ | TRACEABILITY.md |
| AC-003 | FR-003 | 验证依赖矩阵、production-import-testkitx 禁止、stdlib-only gate / boundary-check 输出逐项 PASS/FAIL | ✅ | TRACEABILITY.md |
| AC-004 | FR-004 | xlib-standard 模板自身通过所有检查 / validate --template 输出全部 PASS | ✅ | TRACEABILITY.md |
| AC-005 | FR-005 | Markdown 结构、链接有效性、表格对齐 / format-check 输出逐项 PASS/FAIL | ✅ | TRACEABILITY.md |
| AC-006 | FR-006 | FR → AC → TC 全链路闭合，断开或缺环检出并报告缺口 / traceability-gate 输出闭合/断链报告 | ✅ | TRACEABILITY.md |

## 3. TC 测试验收登记

| ID | 测试项 | 关联要求/验收/任务 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TC-001 | FR-001 | xlib-harness generate test-module --output /tmp/harness-test && diff <(ls /tmp/harness-test/module/test-module/) <(echo -e "SPEC.md\nTRACEABILITY.md\ngoal.md\ntasks/\nIMPLEMENTATION-PLAN.md") | ✅ | TRACEABILITY.md |
| TC-002 | FR-002 | xlib-harness check fixtures/compliant-module --profile spec（expect pass）; xlib-harness check fixtures/broken-module --profile spec（expect itemized failures） | ✅ | TRACEABILITY.md |
| TC-003 | FR-003 | xlib-harness check fixtures/module-with-bad-dep --profile boundary（expect dependency violation reported） | ✅ | TRACEABILITY.md |
| TC-004 | FR-004 | xlib-harness validate --template（expect xlib-standard template passes all checks） | ✅ | TRACEABILITY.md |
| TC-005 | FR-005 | xlib-harness check fixtures/format-issues --profile spec（expect format issues itemized） | ✅ | TRACEABILITY.md |
| TC-006 | FR-006 | xlib-harness check fixtures/broken-trace --profile full（expect broken FR→AC→TC chain reported with gap details） | ✅ | TRACEABILITY.md |

## 4. 覆盖闭合验收

| ID | 覆盖对象 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | generate-module：从 xlib-standard 模板生成完整模块骨架（SPEC.md / TRACEABILITY.md / goal.md / tasks/ / IMPLEMENTATION-PLAN.md） | AC-001 / TC-001 / xlib-harness generate test-module && ls module/test-module/ | ✅ | TRACEABILITY.md |
| FR-002 | spec-lint：检查 23 节结构完整性、FR WHEN/THEN 格式、AC 可验证性 | AC-002 / TC-002 / xlib-harness check --profile spec | ✅ | TRACEABILITY.md |
| FR-003 | boundary-check：验证允许/禁止依赖、production-import-testkitx 禁止、stdlib-only gate | AC-003 / TC-003 / xlib-harness check --profile boundary | ✅ | TRACEABILITY.md |
| FR-004 | template-validate：验证 xlib-standard 模板自举——模板自身符合模板定义 | AC-004 / TC-004 / xlib-harness validate --template | ✅ | TRACEABILITY.md |
| FR-005 | format-check：检查 Markdown 结构、链接有效性、表格对齐 | AC-005 / TC-005 / xlib-harness check --profile spec | ✅ | TRACEABILITY.md |
| FR-006 | traceability-gate：FR → AC → TC 链路全闭合 | AC-006 / TC-006 / xlib-harness check --profile full | ✅ | TRACEABILITY.md |
| BR-001 | generate 必须在 5 秒内完成骨架生成 | — / benchmark test: go test -bench=Generate -benchtime=5s | ✅ | TRACEABILITY.md |
| BR-002 | check 不得修改被检模块的任何文件 | — / 前后文件 hash 对比: sha256sum before/after | ✅ | TRACEABILITY.md |
| BR-003 | check 失败退出码必须非零 | — / exit code 验证: xlib-harness check ; echo $? 期望 != 0 | ✅ | TRACEABILITY.md |
| NFR-001 | Performance | generate 延迟 < 5s；check 延迟（单模块） < 10s / benchmark: go test -bench=. ./... | ✅ | TRACEABILITY.md |
| NFR-002 | Observability | 门禁结果输出为结构化 JSON / output format validation: xlib-harness check --json \ / jq . | ✅ | TRACEABILITY.md |
| NFR-003 | Security | generate 写入路径限制在 module/ 下；不读取密钥；不执行远程代码 / path traversal test: xlib-harness generate ../escape 应拒绝 | ✅ | TRACEABILITY.md |
| NFR-004 | Dependency Boundary | 允许只读 xlib-standard 模板；禁止 github.com/ZoneCNH/xlib-standard Go import/module dependency，并禁止 observex/configx/resiliencx/schedulex/业务域模块 / dependency graph analysis: go list -deps/go list -m + boundary allow/deny list | ✅ | TRACEABILITY.md |

## 5. 验收证据归档

| 证据 | 命令/场景 | 结果 |
| --- | --- | --- |
| 单元测试 | `cd /home/xlib-harness && go test ./...` | PASS |
| 竞态检查 | `cd /home/xlib-harness && go test ./... -race -count=1` | PASS |
| 静态检查 | `cd /home/xlib-harness && go vet ./...` | PASS |
| 覆盖率 | `cd /home/xlib-harness && go test ./... -coverprofile=coverage.out && go tool cover -func=coverage.out` | PASS；total `88.8%`，核心包 `89.2%` |
| 性能基线 | `cd /home/xlib-harness && go test -bench=. ./...` | PASS；`BenchmarkGenerate` 约 `220281 ns/op`，`BenchmarkCheckFullProfile` 约 `223926 ns/op` |
| CLI smoke | build、dependency-boundary、template-validate、generate、check-full、readonly、negative-gates、explicit-xlib-standard-rejected、security-boundary | 全部 PASS |
| 安全扫描 | secret pattern scan | PASS |

## 6. 发布 DoD 清单

- [x] FEATURES.md 的 FR、BR/NFR、任务清单与 SPEC/TRACEABILITY 当前登记一致。
- [x] ACCEPTANCE.md 的 AC、TC 与运行时代码测试名、证据文件或 CI 记录一致。
- [x] 运行时代码仓库 /home/xlib-harness 通过 go test、go test -race、go vet 与覆盖率门槛。
- [x] 所有外部服务依赖有本地可重复的测试替身或明确 live-gate 证据。
- [x] 安全检查确认没有凭证、私有端点、账户 ID 或实盘配置进入公开文档与代码。
- [x] 版本号、发布标签、CHANGELOG 或 release note 与本目录状态一致。

## 7. 当前缺口登记

- 无开放发布缺口。
- 远端 GitHub Actions 结果作为 v0.1.1 发布后的补充信号；当前发布判定以 /home/xlib-harness 本地可复验命令与 release notes 为准。
