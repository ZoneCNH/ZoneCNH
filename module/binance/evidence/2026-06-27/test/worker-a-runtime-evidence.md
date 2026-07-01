# Worker A Runtime Evidence - FR-013/017/025/037, ExchangeInfo, Backfill, DLQ

Date: 2026-06-27
Runtime repo: `/home/workspace/binance`
Runtime HEAD: `ae08c0ffdd3a860a7d99c76fbbc045e5167d258b`
Spec/evidence repo: `/home/workspace/ZoneCNH`
Spec/evidence HEAD: `df2ce996a5b54e1919ffa8ca49db2a73414df4a9`

## Scope

- Beads: `ZoneCNH-xzcr.1`, `ZoneCNH-xzcr.9`, `ZoneCNH-xzcr.10`, `ZoneCNH-xzcr.11`
- GitHub: `#1269`, `#1277`, `#1278`, `#1279`
- Runtime areas: FR-013/017/025/037, FR-031~036 ExchangeInfo, #1117 backfill progress restart persistence, #1118 DLQ snapshot/replay persistence.

## Verification Commands

All commands were run from `/home/workspace/binance`.

| Area | Command | Result |
| --- | --- | --- |
| FR-025 throttle, ExchangeInfo, backfill restart persistence | `go test ./internal/client -run 'Test(ThrottleManager|DecodeSpotExchangeInfo|FetchSpotExchangeInfo|ExchangeInfoRefresher|CatalogReloadProductLine|AdminHistory|HistoryRuntime)' -count=1` | PASS: `ok github.com/ZoneCNH/binance/internal/client 0.016s` |
| Client runtime config wiring | `go test ./cmd/binance-client -run 'TestStandaloneConfigFromCfg' -count=1` | PASS: `ok github.com/ZoneCNH/binance/cmd/binance-client 0.011s` |
| FR-013 stream/control-plane reliability | `go test ./internal/server/controlplane -run 'Test(RetryBudget|ActiveStreamRegistry|StreamRegistry|WeightGate|ClockSkew|HTTPBackoff)' -count=1` | PASS: `ok github.com/ZoneCNH/binance/internal/server/controlplane 0.017s` |
| FR-017 quality counters and #1118 DLQ snapshot/replay | `go test ./internal/server -run 'Test(AdminStreamsIncludesQualityCounters|AdminDeadLetterReplayEndpointReplaysOnce|AdminDeadLetterFileBackedSnapshotAndReplayAfterRestart|Process_ReportsQualityGapRepairAndSLA|QualityTracker|Process_DispatchFailureDeadLetters|DeadLetter)' -count=1` | PASS: `ok github.com/ZoneCNH/binance/internal/server 0.023s` |
| Server DLQ/config wiring | `go test ./cmd/binance-server -run 'Test.*DeadLetter|TestServerConfig|TestConfig' -count=1` | PASS: `ok github.com/ZoneCNH/binance/cmd/binance-server 0.022s` |
| FR-037 canary gate self-test | `bash scripts/deploy-canary-gate.sh --self-test` | PASS: error-rate/consumer-lag checks passed; negative inputs rejected; `deploy-canary-gate self-test PASS` |
| Release readiness smoke audit | `bash scripts/readiness-audit.sh` | PASS: canary self-test passed; `readiness-audit PASS` |

## Closure Assessment

- `ZoneCNH-xzcr.1` / GitHub `#1269`: Runtime direct evidence is present for FR-013, FR-017, FR-025, and FR-037 canary gate self-test. This supports local implementation evidence only; live/gated canary evidence remains deferred and the tracker stays open.
- `ZoneCNH-xzcr.9` / GitHub `#1277`: Runtime direct ExchangeInfo evidence is present for decode/fetch/refresh/catalog reload/client config. This supports local implementation evidence only; live-gated ExchangeInfo evidence remains deferred and the tracker stays open.
- `ZoneCNH-xzcr.10` / GitHub `#1278`: Runtime direct evidence is present for file-backed backfill progress restart persistence. This supports local implementation evidence only; postgresx-backed snapshot and medium verification remain deferred and the tracker stays open.
- `ZoneCNH-xzcr.11` / GitHub `#1279`: Runtime direct evidence is present for admin DLQ snapshot/replay and file-backed replay after restart. This supports local implementation evidence only; Kafka/NATS live-gated proof remains deferred and the tracker stays open.

## Main Thread Follow-up

- Attach or archive live/gated evidence for canary, ExchangeInfo, and DLQ Kafka/NATS paths, or record explicit blockers.
- Decide and record whether `catalog_exchange_info_snapshots` postgresx backing is in scope now or deferred for `ZoneCNH-xzcr.10`.
- Update Beads/GitHub closure state and documentation projections from the evidence bundle.
- Update main docs/tables; Worker A intentionally did not edit projection or status tables.
