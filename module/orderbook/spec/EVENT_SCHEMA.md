# orderbook Event Schema

> Status: Approved
> Version: v0.1.0

## BookEvent

| 字段 | 说明 |
| --- | --- |
| schema_version | 固定 `orderbook.event.v1`。[FRAME, HIGH] |
| type | `snapshot` / `diff` / `rebuild`。[FRAME, HIGH] |
| venue | 交易场所。[FRAME, HIGH] |
| instrument | 交易标的。[FRAME, HIGH] |
| product_line | spot / um_perp / cm_perp / option 等。[FRAME, HIGH] |
| first_update_id | diff 起始序列。[FRAME, HIGH] |
| last_update_id | diff 结束序列或 snapshot 边界。[FRAME, HIGH] |
| prev_update_id | prev-link 场景的前序列。[FRAME, HIGH] |
| levels | side/price/qty 变更列表。[FRAME, HIGH] |

## GapEvent

GapEvent 必须记录 reason、expected、actual、affected update id 和 resulting quality。[FRAME, HIGH]

## QualityEvent

QualityEvent 必须记录 reliable、flags、reason、event_time 和 source update id。[FRAME, HIGH]

[RULES I BROKE]：无
