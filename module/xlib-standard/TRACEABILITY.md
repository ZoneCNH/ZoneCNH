# xlib-standard TRACEABILITY

> **更新（2026-06-12）**：本文件原为 52 条快照占位 FR 追踪表（commit `93753b3`，v0.6.5 快照）。
> 文档-代码重对齐后，权威 FR 入口为 `SPEC.md` §7（14 条真实 FR，每条对应实际代码文件）。
> 原 52 条快照 FR 追踪表已退役；FR 来源锚定 52/52（分析级）；行级 49、file 1、validator-output 2，不等于语义验证完整。

## 当前 FR→Code 追溯

| FR     | 主题                            | 代码文件                                                  | 状态     |
| ------ | ------------------------------- | --------------------------------------------------------- | -------- |
| FR-001 | Config 标准                     | `pkg/templatex/config.go`                                 | ✅ 已对齐 |
| FR-002 | Error 标准                      | `pkg/templatex/errors.go`                                 | ✅ 已对齐 |
| FR-003 | Health 标准                     | `pkg/templatex/health.go`                                 | ✅ 已对齐 |
| FR-004 | Metrics 标准                    | `pkg/templatex/metrics.go`                                | ✅ 已对齐 |
| FR-005 | Client 标准                     | `pkg/templatex/client.go` + `options.go`                  | ✅ 已对齐 |
| FR-006 | Version 标准                    | `pkg/templatex/version.go`                                | ✅ 已对齐 |
| FR-007 | 公共 API 模板                   | `pkg/templatex/*.go`                                      | ✅ 已对齐 |
| FR-008 | 模板可编译                      | `pkg/templatex/*_test.go`                                 | ✅ 已对齐 |
| FR-009 | 模板渲染                        | `scripts/render_template.sh`                              | ✅ 已对齐 |
| FR-010 | 模板残留检查                    | `scripts/check_rendered_template.sh`                      | ✅ 已对齐 |
| FR-011 | CI gate (17 项)                 | `Makefile` ci: 目标                                       | ✅ 已对齐 |
| FR-012 | boundary gate                   | `scripts/check_boundary.sh`                               | ✅ 已对齐 |
| FR-013 | release manifest                | `Makefile` release-check + `scripts/generate_manifest.sh` | ✅ 已对齐 |
| FR-014 | release final check             | `Makefile` release-final-check                            | ✅ 已对齐 |
| FR-015 | Evidence Runtime CLI（goalcli） | `cmd/goalcli/*.go`（12 文件）                             | ✅ 已对齐 |
| FR-016 | L2 下游仓库模板                 | `templates/l2/`（12 文件）                                | ✅ 已对齐 |

## 快照历史

原 52 条 FR 为 2026-06-08 快照，按上游 `docs/standard/xlib-standard.md` 逐契约编号。
2026-06-12 重对齐至上游 v1.0.0（`09c9ec2`），收缩为 14 条可执行规格。
