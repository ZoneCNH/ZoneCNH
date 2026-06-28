# configx Context Package

> Prompt ID: PROMPT-CONFIGX-v1
> Source Spec: [SPEC.md](../SPEC.md) v1.2.0
> Source Goal: [goal.md](../goal.md) 1.0 发布基线
> 生成日期：2026-06-29
> 状态：已交付（对齐运行时仓库 `/home/configx`，tag v1.1.0）

## 上下文概要

configx 已交付 v1.1.0（GitHub Release），完整覆盖 SPEC v1.2.0 的所有 FR（FR-001~FR-018）。本 Context Package 为 Pipeline 对齐而记录，非实时 AI 编码输入。

## 关联任务

所有 task 见 [tasks/](../tasks/) 目录。关键 Task 映射：

| Task | 能力 | 运行时证据 |
|------|------|----------|
| TASK-CONFIGX-001 | Reader 接口 + 基础 Config | `/home/configx/pkg/configx/reader.go` |
| TASK-CONFIGX-003 | 多源加载 (File/Env/Args) | `/home/configx/pkg/configx/source_*.go` |
| TASK-CONFIGX-004 | 校验引擎 (required/range/enum/format) | `/home/configx/pkg/configx/validate.go` |
| TASK-CONFIGX-006 | RemoteSource SPI | `/home/configx/pkg/configx/remote.go` |
| TASK-CONFIGX-007 | Bind API | `/home/configx/pkg/configx/bind.go` |
| TASK-CONFIGX-008 | ConfigSnapshot + Watch + Rollback | `/home/configx/pkg/configx/snapshot.go` + `watch.go` |
| TASK-CONFIGX-009 | DocGen | `/home/configx/pkg/configx/docgen.go` + `cmd/configdoc/` |

## 关键约束

- 依赖链：`kernel`（error/context/validation）→ `configx`
- 不依赖 `observex`/`resiliencx`/`schedulex`
- 测试策略：unit test（table-driven）+ golden file + 契约测试
- 覆盖目标：`make coverage-threshold` 100%

## 参考

- [SPEC.md](../SPEC.md) — v1.2.0
- [DESIGN.md](../DESIGN.md) — 架构与 ADR
- [TRACEABILITY.md](../TRACEABILITY.md) — FR 追溯矩阵
- [ACCEPTANCE.md](../ACCEPTANCE.md) — 验收清单
