# TASK-TRANSPORTX-005: DeliveryReceipt

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-011

- **ACs**: AC-011
- **TCs**: TC-011
- **Phase**: Foundation Contracts (Phase 1)
- **Priority**: P0
- **Dependencies**: TASK-001 (Envelope), TASK-002 (Endpoint)
- **Status**: Pending

## Scope

Implement DeliveryReceipt struct with receiptId, envelopeId, endpoint, status, ackId, offset, attempt, latencyMs, retryDecision, errorCode, redactionVersion. Return Receipt for every publish/subscribe/request/bridge completion.


## Non-Scope

Does NOT implement broker clients or domain-specific receipt semantics.

## Files

- `receipt/receipt.go` — DeliveryReceipt struct + helpers
- `receipt/status.go` — Receipt status enum
- `receipt/retry_decision.go` — RetryDecision type
- `receipt/receipt_test.go` — Receipt field completeness tests

## Acceptance

- [ ] Receipt contains all required fields
- [ ] Status enum: OK, FAILED, ABANDONED, DEAD_LETTERED
- [ ] RetryDecision enum: NONE, RETRY, DEAD_LETTER
- [ ] `go test ./receipt/... -run TestReceiptFields` passes
