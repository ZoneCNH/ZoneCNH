# xlib-harness 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-18
- Module-Version: v0.1.0
- Module-State: 已发布
- Layer: L1 执行器
- Runtime-Repo: /home/xlib-harness
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 xlib-harness 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；若运行时代码状态与本文不一致，以相应模块仓库的最新验证证据补充更新本文。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | 标准化命令执行、证据采集与本地/CI 一致性封装 |
| 文档目录 | module/xlib-harness |
| 运行时代码目录 | /home/xlib-harness |
| Go 基线 | 1.23 |
| 允许依赖 | 无 |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | generate-module：从 xlib-standard 模板生成完整模块骨架（SPEC.md / TRACEABILITY.md / goal.md / tasks/ / IMPLEMENTATION-PLAN.md） | AC-001 / TC-001 / xlib-harness generate test-module && ls module/test-module/ | ✅ | TRACEABILITY.md |
| FR-002 | spec-lint：检查 23 节结构完整性、FR WHEN/THEN 格式、AC 可验证性 | AC-002 / TC-002 / xlib-harness check --profile spec | ✅ | TRACEABILITY.md |
| FR-003 | boundary-check：验证允许/禁止依赖、production-import-testkitx 禁止、stdlib-only gate | AC-003 / TC-003 / xlib-harness check --profile boundary | ✅ | TRACEABILITY.md |
| FR-004 | template-validate：验证 xlib-standard 模板自举——模板自身符合模板定义 | AC-004 / TC-004 / xlib-harness validate --template | ✅ | TRACEABILITY.md |
| FR-005 | format-check：检查 Markdown 结构、链接有效性、表格对齐 | AC-005 / TC-005 / xlib-harness check --profile spec | ✅ | TRACEABILITY.md |
| FR-006 | traceability-gate：FR → AC → TC 链路全闭合 | AC-006 / TC-006 / xlib-harness check --profile full | ✅ | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | generate 必须在 5 秒内完成骨架生成 | — / benchmark test: go test -bench=Generate -benchtime=5s | ✅ | TRACEABILITY.md |
| BR-002 | check 不得修改被检模块的任何文件 | — / 前后文件 hash 对比: sha256sum before/after | ✅ | TRACEABILITY.md |
| BR-003 | check 失败退出码必须非零 | — / exit code 验证: xlib-harness check ; echo $? 期望 != 0 | ✅ | TRACEABILITY.md |
| NFR-001 | Performance | generate 延迟 < 5s；check 延迟（单模块） < 10s / benchmark: go test -bench=. ./... | ✅ | TRACEABILITY.md |
| NFR-002 | Observability | 门禁结果输出为结构化 JSON / output format validation: xlib-harness check --json \ / jq . | ✅ | TRACEABILITY.md |
| NFR-003 | Security | generate 写入路径限制在 module/ 下；不读取密钥；不执行远程代码 / path traversal test: xlib-harness generate ../escape 应拒绝 | ✅ | TRACEABILITY.md |
| NFR-004 | Dependency Boundary | 允许只读 xlib-standard 模板；禁止 observex/configx/resiliencx/schedulex/业务域模块 / dependency graph analysis: go list -deps + boundary allow/deny list | ✅ | TRACEABILITY.md |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-HARNESS-001 | 实现 generate 命令 | FR-001 / AC-001 | - | IMPLEMENTATION-PLAN.md |
| TASK-HARNESS-002 | 实现 spec-lint 检查 | FR-002 / AC-002 | - | IMPLEMENTATION-PLAN.md |
| TASK-HARNESS-003 | 实现 boundary-check 检查 | FR-003 / AC-003 | - | IMPLEMENTATION-PLAN.md |
| TASK-HARNESS-004 | 实现 template-validate 自举 | FR-004 / AC-004 | - | IMPLEMENTATION-PLAN.md |
| TASK-HARNESS-005 | 实现 format-check | FR-005 / AC-005 | - | IMPLEMENTATION-PLAN.md |
| TASK-HARNESS-006 | 实现 traceability-gate | FR-006 / AC-006 | - | IMPLEMENTATION-PLAN.md |
| TASK-XLIBHARNESS-001 | TASK-XLIBHARNESS-001: FR-001 | module/xlib-harness/tasks/TASK-XLIBHARNESS-001.md | - | tasks/TASK-XLIBHARNESS-001.md |
| TASK-XLIBHARNESS-002 | TASK-XLIBHARNESS-002: FR-002 | module/xlib-harness/tasks/TASK-XLIBHARNESS-002.md | - | tasks/TASK-XLIBHARNESS-002.md |
| TASK-XLIBHARNESS-003 | TASK-XLIBHARNESS-003: FR-003 | module/xlib-harness/tasks/TASK-XLIBHARNESS-003.md | - | tasks/TASK-XLIBHARNESS-003.md |
| TASK-XLIBHARNESS-004 | TASK-XLIBHARNESS-004: FR-004 | module/xlib-harness/tasks/TASK-XLIBHARNESS-004.md | - | tasks/TASK-XLIBHARNESS-004.md |
| TASK-XLIBHARNESS-005 | TASK-XLIBHARNESS-005: FR-005 | module/xlib-harness/tasks/TASK-XLIBHARNESS-005.md | - | tasks/TASK-XLIBHARNESS-005.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/xlib-harness/goal.md |
| SPEC.md | 存在 | module/xlib-harness/SPEC.md |
| TRACEABILITY.md | 存在 | module/xlib-harness/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/xlib-harness/IMPLEMENTATION-PLAN.md |
| tasks/ | 5 个 Markdown 文件 | module/xlib-harness/tasks |

## 6. 实现完成判定

- [ ] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [ ] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [ ] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [ ] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [ ] 运行时代码仓库 /home/xlib-harness 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [ ] 发布说明、版本标签与本目录登记状态一致。
