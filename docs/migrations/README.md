# Migration index

This directory keeps historical and breaking-change migration notes referenced by
module specs. Runtime readiness still depends on each module's release DoD and
fresh verification evidence.

| Migration | Owner surface | Status | Notes |
|---|---|---|---|
| [`binance-v2-upgrade.md`](binance-v2-upgrade.md) | `module/binance` | Active docs anchor | Tracks the v2 move from same-process C/S to distributed natsx C/S. |
| [`remove-binance-market.md`](remove-binance-market.md) | `module/binance` | Historical cleanup | Tracks removal of the legacy `binance-market` provider path. |
