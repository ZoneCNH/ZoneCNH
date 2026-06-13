# TASK-TRANSPORTX-020: Outbox/Inbox SPI

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-022

- **ACs**: AC-022
- **TCs**: TC-022
- **Phase**: Data Integrity (Phase 5)
- **Priority**: P2
- **Dependencies**: TASK-001 (Envelope)
- **Status**: Pending

## Scope

Define Outbox interface (Save, MarkPublished, Pending) and Inbox interface (Seen, MarkProcessed). Core defines only SPI, not business orchestration. Adapter implementations (postgresoutbox, redisidem) are separate tasks.


## Non-Scope

Does NOT implement broker clients, storage drivers, business event semantics, or domain DTOs.

## Files

- `outbox/outbox.go` — Outbox interface
- `inbox/inbox.go` — Inbox interface
- `conformance/outbox_inbox_test.go` — Outbox/Inbox cycle test

## Acceptance

- [ ] Outbox.Save stores Envelope
- [ ] Outbox.MarkPublished marks event as sent
- [ ] Outbox.Pending returns unpublished events
- [ ] Inbox.Seen returns true for processed message_id
- [ ] Inbox.MarkProcessed records message as processed
- [ ] `go test ./conformance/... -run TestOutboxInboxCycle` passes
