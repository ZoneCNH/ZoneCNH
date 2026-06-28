# xlib_evidence Goal

## 发布定位

xlib_evidence 是 Foundation 的证据收集与发布运行时。从 xlib_standard 拆分而来，独立承担 Evidence Runtime 职责。

## 边界

- **拥有**：覆盖率收集、门禁结果聚合、Release Manifest 生成与验证、远程证据查询
- **不拥有**：标准定义（xlib_standard）、门禁执行（xlib_harness / xlibgate）、CI 管线编排

## 契约

| 契约 | 消费者 | 说明 |
|------|--------|------|
| `collect` | CI / 模块开发者 | 收集模块覆盖率与门禁结果 |
| `manifest` | CI / xlibgate | 生成和验证 Release Manifest |
| `report` | 治理 / 审计 | 跨模块统一证据报告 |

## 测试证据

- manifest 生成 → 验证 闭环 golden 测试
- 覆盖率 < 100% 拒绝发布
- manifest 篡改检测
- 2026-06-19 本地验收：`go test ./...`、`go test ./... -race -count=1`、`go vet ./...` 通过；覆盖率 total 100.0% >= 100.0%

## DoD

- [x] 5 FR 全部实现并通过 SPEC.md FR-001..005 的 WHEN/THEN 验证
- [x] collect → generate → validate 端到端可跑通
- [x] 测试覆盖率 = 100.0%
