# schedulex Context Package

> Prompt ID: PROMPT-SCHEDULEX-v1
> Source Spec: [SPEC.md](../SPEC.md) v1.1.0
> Source Goal: [goal.md](../goal.md) 1.0 发布基线
> 生成日期：2026-06-29
> 状态：已交付（对齐运行时仓库 `/home/workspace/schedulex`）

## 上下文概要

schedulex 已交付 v1.0.0，提供统一任务调度运行时，支持 cron/interval/delay 三种触发方式，overlap/misfire 策略，可选分布式锁和可注入时钟。本 Context Package 为 Pipeline 对齐而记录，非实时 AI 编码输入。

## 关联任务

所有 task 见 [tasks/](../tasks/) 目录。关键 Task 映射：

| Task | 能力 | 运行时证据 |
|------|------|----------|
| TASK-SCHEDULEX-001 | Scheduler + Job + Trigger 基础框架 | `/home/workspace/schedulex/scheduler.go` |
| TASK-SCHEDULEX-002 | cron 触发 | `/home/workspace/schedulex/trigger.go` |
| TASK-SCHEDULEX-003 | interval 触发 | `/home/workspace/schedulex/trigger.go` |
| TASK-SCHEDULEX-004 | OverlapPolicy (Skip/QueueOne/Allow) | `/home/workspace/schedulex/overlap.go` |
| TASK-SCHEDULEX-005 | MisfirePolicy (Skip/RunOnce) | `/home/workspace/schedulex/misfire.go` |
| TASK-SCHEDULEX-006 | 可选分布式锁 (Locker) | `/home/workspace/schedulex/locker.go` |
| TASK-SCHEDULEX-007 | EventSink | `/home/workspace/schedulex/events.go` |
| TASK-SCHEDULEX-008 | 可注入 Clock | `/home/workspace/schedulex/clock.go` |

## 关键约束

- 依赖链：`kernel`（ctx/clock）→ schedulex
- 默认 at-least-once 执行语义
- stdlib-only
- 所有时间判断通过 Clock interface（不直接调用 time.Now()）

## 参考

- [SPEC.md](../SPEC.md) — v1.1.0
- [DESIGN.md](../DESIGN.md) — 架构与 ADR
- [TRACEABILITY.md](../TRACEABILITY.md) — FR 追溯矩阵
- [ACCEPTANCE.md](../ACCEPTANCE.md) — 验收清单
