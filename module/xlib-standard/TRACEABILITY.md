# xlib-standard 追溯矩阵

> FR → AC → TC → Task 全链路映射。最后更新：2026-06-10

---

## 追溯表

| FR     | Description         | AC                                                         | TC              | Task          | Status   |
| ------ | ------------------- | ---------------------------------------------------------- | --------------- | ------------- | -------- |
| FR-001 | Config 标准         | AC-001: Validate 必填字段缺失返回 ErrorKindValidation      | TC-001          | TASK-XLIB-003 | verified |
| FR-001 | Config 标准         | AC-002: Validate 负数 timeout 返回 ErrorKindValidation     | TC-002          | TASK-XLIB-003 | verified |
| FR-001 | Config 标准         | AC-003: Sanitize 脱敏 secret 替换为 `***`                  | TC-003          | TASK-XLIB-003 | verified |
| FR-002 | Error 标准          | AC-004: NewError 创建 Error 字段正确                       | TC-004          | TASK-XLIB-006 | verified |
| FR-002 | Error 标准          | AC-005: WrapError 包装 errors.Is 可穿透                    | TC-005          | TASK-XLIB-006 | verified |
| FR-002 | Error 标准          | AC-006: IsKind 匹配返回 true                               | TC-006          | TASK-XLIB-006 | verified |
| FR-002 | Error 标准          | AC-007: context.DeadlineExceeded ErrorKind = timeout       | TC-007          | TASK-XLIB-006 | verified |
| FR-002 | Error 标准          | AC-008: closed error ErrorKind = closed                    | TC-008          | TASK-XLIB-006 | verified |
| FR-003 | Health 标准         | AC-009: HealthCheck nil context 返回 unhealthy             | TC-009          | TASK-XLIB-007 | verified |
| FR-003 | Health 标准         | AC-010: HealthCheck 健康客户端返回 healthy                 | TC-010          | TASK-XLIB-007 | verified |
| FR-004 | Metrics 标准        | AC-011: NoopMetrics 不 panic                               | TC-011          | TASK-XLIB-007 | verified |
| FR-004 | Metrics 标准        | AC-012: 指标名匹配 contract 5 个 P0 指标名一致             | TC-012          | TASK-XLIB-007 | verified |
| FR-004 | Metrics 标准        | AC-013: label 低基数只有 op/kind/status                    | TC-013          | TASK-XLIB-007 | verified |
| FR-005 | Client 标准         | AC-014: New nil context 返回错误                           | TC-014          | TASK-XLIB-006 | verified |
| FR-005 | Client 标准         | AC-015: New canceled context 返回错误                      | TC-015          | TASK-XLIB-006 | verified |
| FR-005 | Client 标准         | AC-016: New 无效 config 返回错误                           | TC-016          | TASK-XLIB-006 | verified |
| FR-005 | Client 标准         | AC-017: New 正常创建返回 \*Client                          | TC-017          | TASK-XLIB-006 | verified |
| FR-005 | Client 标准         | AC-018: Close 幂等多次调用不 panic                         | TC-018          | TASK-XLIB-006 | verified |
| FR-006 | Version 标准        | AC-019: 版本信息返回 module path/version/commit/build time | N/A (API check) | TASK-XLIB-003 | verified |
| FR-007 | 公共 API 模板       | AC-020: 模板 go vet 零警告                                 | TC-019          | TASK-XLIB-008 | verified |
| FR-008 | 模板可编译          | AC-021: 模板 go test 全部通过                              | TC-020          | TASK-XLIB-008 | verified |
| FR-009 | render_template.sh  | AC-022: 渲染输出目录结构完整                               | TC-021          | TASK-XLIB-002 | verified |
| FR-010 | 生成库无残留        | AC-023: grep 无 templatex/xlib-standard                    | TC-022          | TASK-XLIB-005 | verified |
| FR-011 | 9 个最小 gate       | AC-024: make ci 9 个 gate 全通过                           | TC-023          | TASK-XLIB-002 | verified |
| FR-012 | boundary gate       | AC-025: check_boundary.sh 检查 6 项                        | TC-023          | TASK-XLIB-002 | verified |
| FR-013 | release manifest    | AC-026: manifest 生成且字段完整                            | TC-024          | TASK-XLIB-004 | verified |
| FR-014 | release final check | AC-027: checksum 校验通过                                  | TC-024          | TASK-XLIB-005 | verified |

---

## 覆盖率统计

| 指标               | 值        |
| ------------------ | --------- |
| FR 总数            | 14        |
| 有 AC 的 FR        | 14 (100%) |
| AC 总数            | 27        |
| 有 TC 的 AC        | 24        |
| TC 总数            | 24        |
| 孤儿 TC（无 FR）   | 0         |
| 孤儿 FR（无 Task） | 0         |

---

## Task 覆盖

| Task                                                       | FR 覆盖                | AC 覆盖                |
| ---------------------------------------------------------- | ---------------------- | ---------------------- |
| TASK-XLIB-000                                              | -                      | 目录删除验收           |
| TASK-XLIB-001                                              | -                      | 文档验收               |
| TASK-XLIB-002                                              | FR-009, FR-011, FR-012 | AC-022, AC-024, AC-025 |
| TASK-XLIB-003, TASK-XLIB-006, TASK-XLIB-007, TASK-XLIB-008 | FR-001~FR-008          | AC-001~AC-021          |
| TASK-XLIB-004                                              | FR-013, FR-014         | AC-026                 |
| TASK-XLIB-005                                              | FR-010, FR-014         | AC-023, AC-027         |

---

## Evidence 引用

| Evidence ID                 | Task ID       | AC                           | Status   |
| --------------------------- | ------------- | ---------------------------- | -------- |
| EVID-TEST-TASK-XLIB-000-001 | TASK-XLIB-000 | AC-000                       | PASS     |
| EVID-TEST-TASK-XLIB-001-001 | TASK-XLIB-001 | AC-001                       | PASS     |
| EVID-TEST-TASK-XLIB-002-001 | TASK-XLIB-002 | AC-002                       | PARTIAL  |
| EVID-TEST-TASK-XLIB-003-002 | TASK-XLIB-003 | AC-003                       | PARTIAL  |
| EVID-TEST-TASK-XLIB-004-001 | TASK-XLIB-004 | AC-004                       | PARTIAL  |
| EVID-TEST-TASK-XLIB-005-001 | TASK-XLIB-005 | AC-005                       | PARTIAL  |
| EVID-TEST-TASK-XLIB-003-001 | TASK-XLIB-003 | AC-001~AC-003, AC-019        | verified |
| EVID-TEST-TASK-XLIB-006-001 | TASK-XLIB-006 | AC-004~AC-008, AC-014~AC-018 | verified |
| EVID-TEST-TASK-XLIB-007-001 | TASK-XLIB-007 | AC-009~AC-013                | verified |
| EVID-TEST-TASK-XLIB-008-001 | TASK-XLIB-008 | AC-020, AC-021               | verified |

## BR 覆盖

| BR     | Description                  | Violation Consequence     | Verification  | Task          |
| ------ | ---------------------------- | ------------------------- | ------------- | ------------- |
| BR-001 | Config 必填字段不可零值      | 返回 ErrorKindValidation  | TC-001        | TASK-XLIB-003 |
| BR-002 | ErrorKind 只能是 8 种之一    | 序列化失败返回 internal   | TC-004~TC-008 | TASK-XLIB-006 |
| BR-003 | HealthStatus 只能是 3 种之一 | 序列化失败返回 unknown    | TC-009~TC-010 | TASK-XLIB-007 |
| BR-004 | Metrics label 低基数         | 高基数 label 导致内存爆炸 | TC-013        | TASK-XLIB-007 |
| BR-005 | Client.Close 幂等            | 第二次 Close panic        | TC-018        | TASK-XLIB-006 |
| BR-006 | Secret 字段必须脱敏          | 明文存储泄露凭证          | TC-003        | TASK-XLIB-003 |
| BR-007 | errors.Is 可穿透             | 调用方无法判断错误类型    | TC-005        | TASK-XLIB-006 |
