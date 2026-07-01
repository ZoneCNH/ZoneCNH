# resiliencx Context Package

> Prompt ID: PROMPT-RESILIENCX-v1
> Source Spec: [SPEC.md](../SPEC.md) v1.1.0
> Source Goal: [goal.md](../goal.md) v1.0.2 发布基线
> 生成日期：2026-06-29
> 状态：已交付（对齐运行时仓库 `/home/workspace/resiliencx`，tag v1.0.2，commit `1aaa0dc`）

## 上下文概要

resiliencx 已交付 v1.0.2（GitHub Release），六大弹性策略（timeout/retry/circuit/bulkhead/ratelimit/fallback）以独立子包形式提供。本 Context Package 为 Pipeline 对齐而记录，非实时 AI 编码输入。

## 关联任务

所有 task 见 [tasks/](../tasks/) 目录。关键 Task 映射：

| Task | 能力 | 运行时证据 |
|------|------|----------|
| TASK-RESILIENCX-001 | timeout.Do | `/home/workspace/resiliencx/pkg/resiliencx/timeout/timeout.go` |
| TASK-RESILIENCX-002 | retry.Do + Policy | `/home/workspace/resiliencx/pkg/resiliencx/retry/retry.go` |
| TASK-RESILIENCX-003 | CircuitBreaker (三态 + HalfOpen) | `/home/workspace/resiliencx/pkg/resiliencx/circuit/circuit.go` |
| TASK-RESILIENCX-004 | Bulkhead | `/home/workspace/resiliencx/pkg/resiliencx/bulkhead/bulkhead.go` |
| TASK-RESILIENCX-005 | RateLimiter (token bucket) | `/home/workspace/resiliencx/pkg/resiliencx/ratelimit/ratelimit.go` |
| TASK-RESILIENCX-006 | Fallback | `/home/workspace/resiliencx/pkg/resiliencx/fallback/fallback.go` |
| TASK-RESILIENCX-007 | Compose + InstrumentStrategy | `/home/workspace/resiliencx/pkg/resiliencx/compose.go` |

## 关键约束

- 依赖链：`kernel`（ctx/err）→ resiliencx 各子包
- stdlib-only，零第三方依赖
- 可观测通过 Metrics interface 注入，不直接依赖 observex
- 策略参数由消费者通过 configx 读取后传入

## 参考

- [SPEC.md](../SPEC.md) — v1.1.0
- [DESIGN.md](../DESIGN.md) — 架构与 ADR
- [TRACEABILITY.md](../TRACEABILITY.md) — FR 追溯矩阵
- [ACCEPTANCE.md](../ACCEPTANCE.md) — 验收清单
