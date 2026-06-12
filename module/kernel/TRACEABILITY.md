# kernel 需求追溯矩阵

> 更新：2026-06-12（SPEC v2.0.0 重写对齐）
> 来源：module/kernel/SPEC.md v2.0.0

## FR → Code 追溯

| FR | 子包 | 代码文件 | 状态 |
|----|------|---------|------|
| FR-001 | lifecycx | `lifecycx/lifecycx.go` | ✅ 已对齐 |
| FR-002 | errx | `errx/errx.go` | ✅ 已对齐 |
| FR-003 | healthx | `healthx/healthx.go` | ✅ 已对齐 |
| FR-004 | obsx | `obsx/obsx.go` | ✅ 已对齐 |
| FR-005 | retryx | `retryx/retryx.go` | ✅ 已对齐 |
| FR-006 | shutdownx | `shutdownx/shutdownx.go` | ✅ 已对齐 |
| FR-007 | timex | `timex/timex.go` | ✅ 已对齐 |
| FR-008 | validx | `validx/validx.go` | ✅ 已对齐 |
| FR-009 | versionx | `versionx/versionx.go` | ✅ 已对齐 |
| FR-010 | contextx | `contextx/contextx.go` | ✅ 已对齐 |
| FR-011 | syncx | `syncx/syncx.go` | ✅ 已对齐 |
| FR-012 | contracttest | `contracttest/contracttest.go` | ✅ 已对齐 |

## 变更历史

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-06-12 | v2.0 | 从旧集中式 FR（5 FR, App/Module/Deps）重写为 12 子包 FR |
| 2026-06-08 | v1.0 | 初始版本（旧 SPEC v1.1.0） |
