# TASK-TRANSPORTX-020: Outbox/Inbox SPI

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-022
- **ACs**: AC-022
- **TCs**: TC-022
- **Phase**: Data Integrity (Phase 5)
- **Dependencies**: TASK-001 (Envelope)
- **Status**: Pending

## Scope

Define Outbox interface (Save, MarkPublished, Pending) and Inbox interface (Seen, MarkProcessed). Core defines only SPI, not business orchestration. Adapter implementations (postgresoutbox, redisidem) are separate tasks.

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
