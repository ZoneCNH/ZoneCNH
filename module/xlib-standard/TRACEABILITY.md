# xlib-standard 追溯矩阵

> FR → AC → TC → Task 全链路映射。最后更新：2026-06-09

---

## 追溯表

| FR | Description | AC | TC | Task | Status |
|----|-------------|----|----|------|--------|
| FR-001 | Config 标准 | AC-001: Validate 必填字段缺失返回 ErrorKindValidation | TC-001 | TASK-XLIB-003 | pending |
| FR-001 | Config 标准 | AC-002: Validate 负数 timeout 返回 ErrorKindValidation | TC-002 | TASK-XLIB-003 | pending |
| FR-001 | Config 标准 | AC-003: Sanitize 脱敏 secret 替换为 `***` | TC-003 | TASK-XLIB-003 | pending |
| FR-002 | Error 标准 | AC-004: NewError 创建 Error 字段正确 | TC-004 | TASK-XLIB-003 | pending |
| FR-002 | Error 标准 | AC-005: WrapError 包装 errors.Is 可穿透 | TC-005 | TASK-XLIB-003 | pending |
| FR-002 | Error 标准 | AC-006: IsKind 匹配返回 true | TC-006 | TASK-XLIB-003 | pending |
| FR-002 | Error 标准 | AC-007: context.DeadlineExceeded ErrorKind = timeout | TC-007 | TASK-XLIB-003 | pending |
| FR-002 | Error 标准 | AC-008: closed error ErrorKind = closed | TC-008 | TASK-XLIB-003 | pending |
| FR-003 | Health 标准 | AC-009: HealthCheck nil context 返回 unhealthy | TC-009 | TASK-XLIB-003 | pending |
| FR-003 | Health 标准 | AC-010: HealthCheck 健康客户端返回 healthy | TC-010 | TASK-XLIB-003 | pending |
| FR-004 | Metrics 标准 | AC-011: NoopMetrics 不 panic | TC-011 | TASK-XLIB-003 | pending |
| FR-004 | Metrics 标准 | AC-012: 指标名匹配 contract 5 个 P0 指标名一致 | TC-012 | TASK-XLIB-003 | pending |
| FR-004 | Metrics 标准 | AC-013: label 低基数只有 op/kind/status | TC-013 | TASK-XLIB-003 | pending |
| FR-005 | Client 标准 | AC-014: New nil context 返回错误 | TC-014 | TASK-XLIB-003 | pending |
| FR-005 | Client 标准 | AC-015: New canceled context 返回错误 | TC-015 | TASK-XLIB-003 | pending |
| FR-005 | Client 标准 | AC-016: New 无效 config 返回错误 | TC-016 | TASK-XLIB-003 | pending |
| FR-005 | Client 标准 | AC-017: New 正常创建返回 *Client | TC-017 | TASK-XLIB-003 | pending |
| FR-005 | Client 标准 | AC-018: Close 幂等多次调用不 panic | TC-018 | TASK-XLIB-003 | pending |
| FR-006 | Version 标准 | AC-019: 版本信息返回 module path/version/commit/build time | - | TASK-XLIB-003 | pending |
| FR-007 | 公共 API 模板 | AC-020: 模板 go vet 零警告 | TC-019 | TASK-XLIB-003 | pending |
| FR-008 | 模板可编译 | AC-021: 模板 go test 全部通过 | TC-020 | TASK-XLIB-003 | pending |
| FR-009 | render_template.sh | AC-022: 渲染输出目录结构完整 | TC-021 | TASK-XLIB-002 | pending |
| FR-010 | 生成库无残留 | AC-023: grep 无 templatex/xlib-standard | TC-022 | TASK-XLIB-005 | pending |
| FR-011 | 9 个最小 gate | AC-024: make ci 9 个 gate 全通过 | TC-023 | TASK-XLIB-002 | pending |
| FR-012 | boundary gate | AC-025: check_boundary.sh 检查 6 项 | - | TASK-XLIB-002 | pending |
| FR-013 | release manifest | AC-026: manifest 生成且字段完整 | TC-024 | TASK-XLIB-004 | pending |
| FR-014 | release final check | AC-027: checksum 校验通过 | - | TASK-XLIB-005 | pending |

---

## 覆盖率统计

| 指标 | 值 |
|------|------|
| FR 总数 | 14 |
| 有 AC 的 FR | 14 (100%) |
| AC 总数 | 27 |
| 有 TC 的 AC | 24 |
| TC 总数 | 24 |
| 孤儿 TC（无 FR） | 0 |
| 孤儿 FR（无 Task） | 0 |

---

## Task 覆盖

| Task | FR 覆盖 | AC 覆盖 |
|------|---------|---------|
| TASK-XLIB-000 | - | 目录删除验收 |
| TASK-XLIB-001 | - | 文档验收 |
| TASK-XLIB-002 | FR-009, FR-011, FR-012 | AC-022, AC-024, AC-025 |
| TASK-XLIB-003 | FR-001~FR-008 | AC-001~AC-021 |
| TASK-XLIB-004 | FR-013, FR-014 | AC-026 |
| TASK-XLIB-005 | FR-010, FR-014 | AC-023, AC-027 |
