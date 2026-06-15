# xlib-harness TRACEABILITY

## §1 FR Traceability

| FR ID | Requirement | AC ID(s) | TC ID(s) | Verification |
|-------|-------------|----------|----------|--------------|
| FR-001 | generate-module：从 xlib-standard 模板生成完整模块骨架（SPEC.md / TRACEABILITY.md / goal.md / tasks/ / IMPLEMENTATION-PLAN.md） | AC-001 | TC-001 | `xlib-harness generate test-module && ls module/test-module/` |
| FR-002 | spec-lint：检查 23 节结构完整性、FR WHEN/THEN 格式、AC 可验证性 | AC-002 | TC-002 | `xlib-harness check <module> --profile spec` |
| FR-003 | boundary-check：验证允许/禁止依赖、production-import-testkitx 禁止、stdlib-only gate | AC-003 | TC-003 | `xlib-harness check <module> --profile boundary` |
| FR-004 | template-validate：验证 xlib-standard 模板自举——模板自身符合模板定义 | AC-004 | TC-004 | `xlib-harness validate --template` |
| FR-005 | format-check：检查 Markdown 结构、链接有效性、表格对齐 | AC-005 | TC-005 | `xlib-harness check <module> --profile spec` |
| FR-006 | traceability-gate：FR → AC → TC 链路全闭合 | AC-006 | TC-006 | `xlib-harness check <module> --profile full` |

## §2 BR Traceability

| BR ID | Rule | Verification Method |
|-------|------|---------------------|
| BR-001 | generate 必须在 5 秒内完成骨架生成 | benchmark test: `go test -bench=Generate -benchtime=5s` |
| BR-002 | check 不得修改被检模块的任何文件 | 前后文件 hash 对比: `sha256sum` before/after |
| BR-003 | check 失败退出码必须非零 | exit code 验证: `xlib-harness check <bad-module>; echo $?` 期望 != 0 |

## §3 NFR Traceability

| NFR ID | Category | Requirement | Verification |
|--------|----------|-------------|--------------|
| NFR-001 | Performance | generate 延迟 < 5s；check 延迟（单模块） < 10s | benchmark: `go test -bench=. ./...` |
| NFR-002 | Observability | 门禁结果输出为结构化 JSON | output format validation: `xlib-harness check <module> --json \| jq .` |
| NFR-003 | Security | generate 写入路径限制在 module/ 下；不读取密钥；不执行远程代码 | path traversal test: `xlib-harness generate ../escape` 应拒绝 |
| NFR-004 | Dependency Boundary | 允许只读 xlib-standard 模板；禁止 observex/configx/resiliencx/schedulex/业务域模块 | dependency graph analysis: `go list -deps` + boundary allow/deny list |

## §4 TC → FR Reverse

| TC ID | Covers FR(s) | Command |
|-------|-------------|---------|
| TC-001 | FR-001 | `xlib-harness generate test-module --output /tmp/harness-test && diff <(ls /tmp/harness-test/module/test-module/) <(echo -e "SPEC.md\nTRACEABILITY.md\ngoal.md\ntasks/\nIMPLEMENTATION-PLAN.md")` |
| TC-002 | FR-002 | `xlib-harness check fixtures/compliant-module --profile spec`（expect pass）; `xlib-harness check fixtures/broken-module --profile spec`（expect itemized failures） |
| TC-003 | FR-003 | `xlib-harness check fixtures/module-with-bad-dep --profile boundary`（expect dependency violation reported） |
| TC-004 | FR-004 | `xlib-harness validate --template`（expect xlib-standard template passes all checks） |
| TC-005 | FR-005 | `xlib-harness check fixtures/format-issues --profile spec`（expect format issues itemized） |
| TC-006 | FR-006 | `xlib-harness check fixtures/broken-trace --profile full`（expect broken FR→AC→TC chain reported with gap details） |

## §5 AC Registry

| AC ID | FR/BR Ref | Criterion | Verification |
|-------|-----------|-----------|--------------|
| AC-001 | FR-001 | 生成目录包含 SPEC.md / TRACEABILITY.md / goal.md / tasks/ / IMPLEMENTATION-PLAN.md | `ls module/<generated>/` file inventory check |
| AC-002 | FR-002 | 检查 23 节结构、WHEN/THEN 格式、AC 可验证性 | spec-lint 输出逐项 PASS/FAIL |
| AC-003 | FR-003 | 验证依赖矩阵、production-import-testkitx 禁止、stdlib-only gate | boundary-check 输出逐项 PASS/FAIL |
| AC-004 | FR-004 | xlib-standard 模板自身通过所有检查 | `validate --template` 输出全部 PASS |
| AC-005 | FR-005 | Markdown 结构、链接有效性、表格对齐 | format-check 输出逐项 PASS/FAIL |
| AC-006 | FR-006 | FR → AC → TC 全链路闭合，断开或缺环检出并报告缺口 | traceability-gate 输出闭合/断链报告 |

## §6 FR → Task Mapping

| Requirement Ref | Task ID |
|-----------------|---------|
| FR-001 | TASK-HARNESS-001 |
| FR-002 | TASK-HARNESS-002 |
| FR-003 | TASK-HARNESS-003 |
| FR-004 | TASK-HARNESS-004 |
| FR-005 | TASK-HARNESS-005 |
| FR-006 | TASK-HARNESS-006 |
