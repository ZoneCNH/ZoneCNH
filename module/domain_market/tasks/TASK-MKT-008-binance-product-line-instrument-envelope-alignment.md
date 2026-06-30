# TASK-MKT-008 Binance Product-Line / Instrument Identity / Envelope Alignment

- Status: Approved
- Owner: `module/domain_market`
- Last-Updated: 2026-06-30
- Blocks: `module/binance` runtime implementation

## Objective

Close the Binance upstream semantic gap by approving canonical product-line tokens, instrument identity dimensions, and envelope naming semantics.

## Deliverables

- `module/domain_market/SPEC.md` §10 — ProductLine (spot/um_perp/cm_perp/option), InstrumentKey (12 dimensions), MarketFactEnvelope ✅
- Product-line collision test requirements → **Done: §10.1 InstrumentKey dimension matrix + collision examples**
- `MarketFactEnvelope` canonical naming decision → **Done: §10 MarketFactEnvelope = canonical wrapper; §9 MarketEventEnvelope deprecated alias**
- Deprecated alias policy for `MarketEventEnvelope` → **Done: §9 `type MarketEventEnvelope = MarketFactEnvelope` + "Deprecated: v2 将移除此别名"**
- Time semantics for `EventTime`, `ReceivedAt`, `AvailableAt`, `DecisionTime` → **Done: §10.1 event type mapping + time semantics table**

## Acceptance Criteria

1. Spot `BTCUSDT` and USDⓈ-M `BTCUSDT` cannot share the same `InstrumentKey` (product_line + instrument_type + margin_asset vs quote_asset dimensions differ). ✅
2. COIN-M instruments include settlement_asset / contract_code dimensions. ✅
3. Options instruments include expiry, strike, and option_type. ✅
4. New Binance tasks use `MarketFactEnvelope`, not ambiguous `MarketEventEnvelope` wording. ✅
5. `DecisionTime` is defined as downstream no-lookahead availability time, not exchange event time (§10.1 time semantics). ✅
