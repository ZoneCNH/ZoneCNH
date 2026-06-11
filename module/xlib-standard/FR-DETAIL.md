# xlib-standard FR 细节

> **更新（2026-06-12）**：本文件原本包含 52 条通用快照占位 FR（"WHEN 上游标准要求维护第 N 项契约"）。
> 2026-06-12 文档-代码对齐后，`SPEC.md` 已包含 14 条真实 FR（FR-001~FR-014），每条均有基于实际代码的 WHEN/THEN 行为描述。
> **当前权威 FR 入口为 `SPEC.md` §7 Functional Requirements**。本文件保留为历史快照说明。

## SPEC.md FR 索引

| FR | 主题 | 对应代码 |
|----|------|---------|
| FR-001 | Config 标准 (Validate/Sanitize) | `pkg/templatex/config.go` |
| FR-002 | Error 标准 (NewError/WrapError/IsKind) | `pkg/templatex/errors.go` |
| FR-003 | Health 标准 (HealthCheck/degraded状态) | `pkg/templatex/health.go` |
| FR-004 | Metrics 标准 (NoopMetrics/低基数label) | `pkg/templatex/metrics.go` |
| FR-005 | Client 标准 (New/Close/幂等) | `pkg/templatex/client.go` + `options.go` |
| FR-006 | Version 标准 (ModuleName/Version) | `pkg/templatex/version.go` |
| FR-007 | 公共 API 模板 (完整 API 面) | `pkg/templatex/*.go` |
| FR-008 | 模板可编译 (go vet/test) | `pkg/templatex/*_test.go` |
| FR-009 | render_template.sh 渲染 | `scripts/render_template.sh` |
| FR-010 | 生成库无模板残留 | `scripts/check_rendered_template.sh` |
| FR-011 | CI gate (17 项) | `Makefile` ci: 目标 |
| FR-012 | boundary gate 检查 | `scripts/check_boundary.sh` |
| FR-013 | release manifest (16 步) | `Makefile` release-check + `scripts/generate_manifest.sh` |
| FR-014 | release final check | `Makefile` release-final-check |

## 上游快照历史

原 52 条 FR 源于 2026-06-08 快照（commit `93753b3`），按 `docs/standard/xlib-standard.md` 的契约编号逐条生成索引占位。
2026-06-12 重对齐至上游 HEAD（`09c9ec2`，tag `v1.0.0`），FR 精简为 14 条可执行规格。
