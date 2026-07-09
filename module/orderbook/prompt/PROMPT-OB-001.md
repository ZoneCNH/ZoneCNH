# PROMPT-OB-001: Implement orderbook v0.1.0

> Source Task: TASK-OB-002 / TASK-OB-003
> Runtime Path: `/home/workspace/orderbook`

## Objective

实现 stdlib-only OrderBook runtime core：adapter/event/book/sync/replay/quality/conformance，并通过 `go test ./...` 与 gate 脚本。[FRAME, HIGH]

## Constraints

- 不 import venue internal 包。[FRAME, HIGH]
- 不连接外部服务。[FRAME, HIGH]
- 不使用 float 存储 public price/qty。[FRAME, HIGH]

## Acceptance

运行：

```bash
go test ./...
bash scripts/boundary-gates.sh
bash scripts/replay-determinism-gate.sh
bash scripts/gap-injection-gate.sh
```

[RULES I BROKE]：无
