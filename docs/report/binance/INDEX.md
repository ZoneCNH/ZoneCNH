# Binance Report Index

Status: active report index  
Last-Updated: 2026-06-22

This index is the stage-1 entry point for the Binance governance repair reports. It intentionally points to the active v3/v4/iteration/goal artifacts and does not revive abandoned v5 material.

## Active reports

- [`deep-analysis-20260622.md`](./deep-analysis-20260622.md) — v3 deep analysis baseline.
- [`deep-analysis-20260622-v2.md`](./deep-analysis-20260622-v2.md) — v4 follow-up analysis and execution gaps.
- [`iteration-plan-20260622.md`](./iteration-plan-20260622.md) — staged iteration plan used as the goal input.
- [`goal-execution-plan-20260622.md`](./goal-execution-plan-20260622.md) — ordered 7-stage execution plan and acceptance criteria.
- [`business-types-coverage-20260622.md`](./business-types-coverage-20260622.md) — business type coverage review.

## Guardrails

- Treat `module/binance/NAMING.md` as the naming SSOT for product lines, NATS subjects, and Kafka topics.
- Treat `module/binance/SPEC.md` as the current spec-version source; module metadata must stay synchronized with it.
- Do not mark runtime acceptance complete from report evidence alone; runtime proof belongs in the stage-7 evidence chain.
