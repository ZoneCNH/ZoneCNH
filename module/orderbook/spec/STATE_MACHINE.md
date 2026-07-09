# orderbook State Machine

> Status: Approved
> Version: v0.1.0

## States

| State | 说明 |
| --- | --- |
| `empty` | 尚未加载 snapshot。[FRAME, HIGH] |
| `buffering` | 已接收 diff，等待 snapshot 对齐。[FRAME, HIGH] |
| `aligned` | snapshot + diff 已对齐，输出 reliable book。[FRAME, HIGH] |
| `degraded` | 存在 gap/stale/drift，输出 unreliable quality。[FRAME, HIGH] |
| `rebuilding` | 正在重新加载 snapshot。[FRAME, HIGH] |

## Transitions

| From | Event | To |
| --- | --- | --- |
| empty | diff received | buffering |
| buffering | snapshot aligned | aligned |
| aligned | valid diff | aligned |
| aligned | sequence break | degraded |
| degraded | rebuild requested | rebuilding |
| rebuilding | snapshot aligned | aligned |

## Quality Impact

任何 sequence break、out-of-order diff、missing diff 或 snapshot drift 都必须产生 `reliable=false` 的 QualityEvent。[FRAME, HIGH]

[RULES I BROKE]：无
