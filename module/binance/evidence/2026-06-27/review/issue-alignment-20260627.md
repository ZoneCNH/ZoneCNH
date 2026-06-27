# binance Issue Alignment Evidence — 2026-06-27

- Date: 2026-06-27
- Scope: Beads issues + GitHub issues for binance governance/runtime alignment
- Runtime anchor: `/home/binance@f046e16`
- Governance repo: `/home/ZoneCNH`

> `[COMPUTED, HIGH]` This file is superseded for current #1268-#1279 tracker status by `ISSUE-BLOCKERS-1268-1279.md`. The rows below are preserved as blocker evidence; current #1268-#1279 tracker state is GitHub `OPEN` and Beads `ZoneCNH-xzcr*` in_progress as Evidence-Done blocker ownership. Linked Evidence-Done rows remain pending.
> GitHub #1093 / Beads `ZoneCNH-8lb` is tracker open / Evidence pending, and Beads `ZoneCNH-az71` is intentionally retained as `in_progress` because git operations are blocked.

## §1 Baseline

`[COMPUTED, HIGH]` Beads baseline contained 16 open issues and 1 in-progress git-operation issue before this alignment pass.

`[COMPUTED, HIGH]` GitHub baseline contained 13 open issues: #1093 and #1268-#1279.

`[COMPUTED, HIGH]` OMX team mode could not be used because the leader worktree was already dirty. The blocker split was performed directly without stashing or reverting existing unrelated changes.

## §2 Alignment Matrix

| Beads | GitHub | Decision | Evidence / Blocker |
| --- | --- | --- | --- |
| ZoneCNH-cdma | none | Close Beads | `[COMPUTED, HIGH]` Closed by `docs/governance/module-governance/10-governance-levels.md`, which defines L1/L2/L3 governance levels |
| ZoneCNH-sd02 | none | Close Beads | `[COMPUTED, HIGH]` Closed by `docs/governance/module-governance/templates/MODULE-GOVERNANCE-REVIEW.md`, which extracts reusable governance review rules and templates |
| ZoneCNH-wbyc | none | Close Beads | `[COMPUTED, HIGH]` Closed by `docs/governance/module-governance/09-maintenance-cadence.md`, which defines quarterly pruning audit workflow |
| ZoneCNH-8lb | #1093 | Historical tracker archived / Evidence pending | `[COMPUTED, HIGH]` Historical tracker accounting is archived; M4 is not complete because `live_integration >= 15` and soak evidence are still missing in `docs/governance/CORE-LOOP-MILESTONES.md` |
| ZoneCNH-az71 | none | Historical git-operation blocker | `[COMPUTED, HIGH]` This row records an earlier no-git state and is outside the active #1268-#1279 evidence blocker split |
| ZoneCNH-xzcr | #1268 | Tracker open / Evidence pending | `[COMPUTED, HIGH]` Epic tracker is in_progress as Evidence-Done blocker ownership; Evidence-State remains `1 Done (FR-009) / 43 Pending` |
| ZoneCNH-xzcr.1 | #1269 | Tracker open / Evidence pending | `[COMPUTED, HIGH]` Evidence gap persists; sanitized direct TC/live outputs for FR-013/017/025/037, production canary, and rollback drill evidence are still missing |
| ZoneCNH-xzcr.2 | #1270 | Tracker open / Evidence pending | `[COMPUTED, HIGH]` Evidence gap persists; archived OTel span export, external Kafka/NATS trace propagation, slog trace_id evidence, sampling/fallback evidence are still missing |
| ZoneCNH-xzcr.3 | #1271 | Tracker open / Evidence pending | `[COMPUTED, HIGH]` Evidence gap persists; real Kafka quota evidence, pressure/failure isolation evidence, per-caller API limiting evidence, and ClickHouse timeout direct TC output are still missing |
| ZoneCNH-xzcr.4 | #1272 | Tracker open / Evidence pending | `[COMPUTED, HIGH]` Evidence gap persists; audit field-completeness/idempotency, retention/archive, and deployed Postgres permission evidence are still missing |
| ZoneCNH-xzcr.5 | #1273 | Tracker open / Evidence pending | `[COMPUTED, HIGH]` Evidence gap persists; live-gated sanitized evidence or explicit blockers for redisx/kafkax/natsx/postgresx/taosx/ossx/clickhousex are still missing |
| ZoneCNH-xzcr.6 | #1274 | Tracker open / Evidence pending | `[COMPUTED, HIGH]` Evidence gap persists; credential path/testnet for UM/CM/Options and mainnet evidence or blocker are still missing |
| ZoneCNH-xzcr.7 | #1275 | Tracker open / Evidence pending | `[COMPUTED, HIGH]` Evidence gap persists; dashboard, AlertManager budget alert dry/live evidence, usage report, and prod/prod-like redacted evidence are still missing |
| ZoneCNH-xzcr.8 | #1276 | Tracker open / Evidence pending | `[COMPUTED, HIGH]` Evidence gap persists; cross-env destruction drill, irreversible delete proof, certificate_of_destruction archive, and compliance audit evidence are still missing |
| ZoneCNH-xzcr.9 | #1277 | Tracker open / Evidence pending | `[COMPUTED, HIGH]` Evidence gap persists; TC-066~TC-083 matrix closure, live-gated ExchangeInfo proof, server consumer/migration direct TC, and priority/shedding/smoothing proof are still missing |
| ZoneCNH-xzcr.10 | #1278 | Tracker open / Evidence pending | `[COMPUTED, HIGH]` Evidence gap persists; archived command/config/before-after bundle, persistent medium verification, and traceability sync remain missing |
| ZoneCNH-xzcr.11 | #1279 | Tracker open / Evidence pending | `[COMPUTED, HIGH]` Evidence gap persists; archived replay input/output, Kafka/NATS live evidence or explicit blockers, and status doc sync remain missing |

## §3 Agent Lane Evidence

`[COMPUTED, HIGH]` Lane A verified targeted runtime tests for P0/P1 issues and produced local evidence that supports blocker alignment only; live/direct production evidence remains deferred.

`[COMPUTED, HIGH]` Lane B verified targeted runtime tests for P2 issues and produced implementation anchors that support blocker alignment only; Evidence-State remains pending.

`[COMPUTED, HIGH]` Lane C verified Beads/GitHub alignment, confirmed the three governance-only Beads issues are locally closable, and relocated #1093 to `docs/governance/CORE-LOOP-MILESTONES.md` while preserving its milestone blockers.

## §4 Synchronization Rules Applied

1. Treat #1268-#1279 as tracker open / Evidence pending items while direct proof/evidence archive gaps remain tracked as Evidence pending.
2. Do not treat issue synchronization as production, live, milestone, or Evidence-Done completion.
3. For GitHub #1268-#1279, preserve blocker ledger links and keep evidence gaps pending until linked Evidence-Done proof is attached or blocker deferral is accepted.
4. Keep `ZoneCNH-az71` outside the active #1268-#1279 evidence blocker split.

## §5 Verification Plan

`[COMPUTED, HIGH]` Completion requires no-git trailing-space scan (`rg -n '[ \t]+$' ...`), stale-path grep, runtime spec-artifact boundary check, Beads/GitHub status checks, and a 10-pass omission loop over issue IDs, document links, and expected states.

## §6 Continuation Audit

`[COMPUTED, HIGH]` At `2026-06-27 17:23:58 +0800`, `/home/binance/scripts/readiness-audit.sh` returned `readiness-audit PASS`.

`[COMPUTED, HIGH]` Runtime release evidence was collected under `/home/binance/release/evidence/binance/20260627-agent-audit/`.

`[COMPUTED, HIGH]` `/home/binance/release/evidence/binance/20260627-agent-audit/status.txt` reports PASS for HEAD capture, Go version capture, gofmt, boundary gates, `go build ./...`, `go test ./... -count=1`, `go test ./... -race -count=1`, `go vet ./...`, `golangci-lint run`, smoke self-test, retired HTTP ingest guard, local/external ledger writes, `git diff --check`, and pre/post git status capture.

`[COMPUTED, HIGH]` `/home/binance/release/evidence/binance/20260627-agent-audit/external-gates.log` still reports `live_binance_websocket=NOT_CAPTURED`, `remote_github_actions=NOT_CAPTURED`, `release_tag=NOT_CAPTURED`, and `release_closeable=NO`.

`[COMPUTED, HIGH]` `/home/binance/release/evidence/binance/20260627-agent-audit/lifecycle-local-gates.log` reports local lifecycle PASS items, but also `durable_historical_fetch_replay=NOT_IMPLEMENTED` and `live_historical_exchange_capture=NOT_CAPTURED`.

`[COMPUTED, HIGH]` This continuation audit strengthens the local readiness evidence but does not make #1093 or #1268-#1279 Evidence-Done, because their acceptance still depends on live, production, external CI, release, rollback, destructive, credentialed, or archived direct-test evidence.

`[COMPUTED, HIGH]` Continuation audit comments were synced to GitHub #1093 and the active blocker set #1268-#1279 after collecting the local runtime evidence:

| GitHub | Continuation comment |
| --- | --- |
| #1093 | https://github.com/ZoneCNH/ZoneCNH/issues/1093#issuecomment-4816373415 |
| #1268 | https://github.com/ZoneCNH/ZoneCNH/issues/1268#issuecomment-4817259575 |
| #1269 | https://github.com/ZoneCNH/ZoneCNH/issues/1269#issuecomment-4817259662 |
| #1270 | https://github.com/ZoneCNH/ZoneCNH/issues/1270#issuecomment-4817259743 |
| #1271 | https://github.com/ZoneCNH/ZoneCNH/issues/1271#issuecomment-4817259984 |
| #1272 | https://github.com/ZoneCNH/ZoneCNH/issues/1272#issuecomment-4817261573 |
| #1273 | https://github.com/ZoneCNH/ZoneCNH/issues/1273#issuecomment-4817261710 |
| #1274 | https://github.com/ZoneCNH/ZoneCNH/issues/1274#issuecomment-4817261829 |
| #1275 | https://github.com/ZoneCNH/ZoneCNH/issues/1275#issuecomment-4817261946 |
| #1276 | https://github.com/ZoneCNH/ZoneCNH/issues/1276#issuecomment-4817262052 |
| #1277 | https://github.com/ZoneCNH/ZoneCNH/issues/1277#issuecomment-4817262148 |
| #1278 | https://github.com/ZoneCNH/ZoneCNH/issues/1278#issuecomment-4817262293 |
| #1279 | https://github.com/ZoneCNH/ZoneCNH/issues/1279#issuecomment-4817262394 |
