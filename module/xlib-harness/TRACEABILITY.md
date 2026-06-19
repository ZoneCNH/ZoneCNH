# xlib-harness Traceability

> Module: `xlib-harness`
> Version: v0.1.2
> Last-Updated: 2026-06-19
> Implementation-Baseline: `/home/xlib-harness@aa83306685a9`

## Requirement Traceability Matrix

| FR ID | Requirement | Acceptance Criteria | Test Case | Status |
| --- | --- | --- | --- | --- |
| FR-001 | 生成 6 个标准模块资产 | AC-001 | TC-001 | PASS |
| FR-002 | 检查 23 节规格结构、FR Given/When/Then、AC/TC 可验证性 | AC-002 | TC-002 | PASS |
| FR-003 | 拒绝禁止运行时依赖引用 | AC-003 | TC-003 | PASS |
| FR-004 | 检查 CI/CD 引用与 Makefile 门禁 | AC-004 | TC-004 | PASS |
| FR-005 | 检查 Markdown 格式问题 | AC-005 | TC-005 | PASS |
| FR-006 | 检查 FR/AC/TC 追踪闭环 | AC-006 | TC-006 | PASS |

## Non-Functional Traceability

| NFR ID | Requirement | Acceptance Criteria | Evidence | Status |
| --- | --- | --- | --- | --- |
| NFR-001 | harness 运行时只依赖 Go 标准库 | AC-003 | `go list -deps ./...` 与 `fixtures/bad-dependency` | PASS |
| NFR-002 | JSON 输出可由自动化消费 | AC-004 | `xlib-harness check <module> --json \| jq .` | PASS |
| NFR-003 | CI/CD 可重复执行 | AC-004 | `make ci` 与 GitHub Actions workflow | PASS |
| NFR-004 | Go 覆盖率达到 100% | AC-006 | `go tool cover -func=coverage.out` total 100.0% | PASS |

## Test Cases

| TC ID | Scenario | Command | Expected |
| --- | --- | --- | --- |
| TC-001 | Generate module docs | `go run . generate /tmp/xlib-harness-smoke --force` | 6 个资产创建成功 |
| TC-002 | Spec gate accepts compliant module | `go run . check fixtures/compliant-module --profile spec` | 规格检查全部通过 |
| TC-003 | Boundary gate rejects forbidden dependency | `go run . check fixtures/bad-dependency --profile boundary` | 非零退出并报告禁止依赖 |
| TC-004 | Full gate accepts compliant module | `go run . check fixtures/compliant-module --profile full` | 14 项检查全部通过 |
| TC-005 | Format checks detect markdown issues | Go unit tests | trailing whitespace、空链接、表格漂移均被覆盖 |
| TC-006 | Trace gate rejects incomplete matrix | `go run . check fixtures/broken-trace --profile full` | 非零退出并报告追踪断链 |

## Closure

Every FR has at least one AC and TC. Every AC and TC is referenced in this matrix. The implementation gate itself validates this closure through the `trace` check in full profile.
