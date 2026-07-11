# orderbook Gate Rules

| Gate | Rule |
| --- | --- |
| Boundary Gate | Runtime 不得 import `github.com/xhyperium/binance/internal`、`okx/internal`、`bybit/internal` 或其他 venue internal 包。[FRAME, HIGH] |
| Replay Gate | 同一 fixture replay 100 次 BookHash 必须一致。[FRAME, HIGH] |
| Gap Gate | sequence break 必须产生 GapEvent 和 `reliable=false` QualityEvent。[FRAME, HIGH] |
| Evidence Gate | 测试命令、环境、结果和剩余风险必须记录。[FRAME, HIGH] |

[RULES I BROKE]：无
