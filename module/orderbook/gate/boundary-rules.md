# Boundary Rules

`orderbook` runtime 只允许依赖 Go 标准库和未来经 ADR 批准的下行公开模块。[FRAME, HIGH]

禁止 import：

- `github.com/ZoneCNH/binance/internal`
- `github.com/ZoneCNH/okx/internal`
- `github.com/ZoneCNH/bybit/internal`
- `github.com/ZoneCNH/*/internal/client`

[RULES I BROKE]：无
