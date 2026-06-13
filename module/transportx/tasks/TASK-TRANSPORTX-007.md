# TASK-TRANSPORTX-007: QoS Classification

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-017

- **BR_ref**: module/transportx/SPEC.md#BR-013 ,#BR-014
- **ACs**: AC-017
- **TCs**: TC-017
- **Phase**: QoS + Codec + Registry (Phase 2)
- **Priority**: P0
- **Dependencies**: TASK-001 (Envelope), TASK-006 (Errors)
- **Status**: Pending

## Scope

Implement QoSClass enum (REALTIME_BEST_EFFORT, DURABLE_EVENT, COMMAND_IDEMPOTENT, COMMAND_STRICT, AUDIT). Enforce hard rules: order/fill/risk/settlement ≠ REALTIME; COMMAND_IDEMPOTENT requires key; AUDIT must enter audit sink.


## Non-Scope

Does NOT implement broker clients, storage drivers, or business event semantics.

## Files

- `qos/qos.go` — QoSClass enum + validation
- `qos/rules.go` — Hard rule enforcement
- `qos/qos_test.go` — QoS violation + hard rules tests

## Acceptance

- [ ] QoSClass enum with 5 values
- [ ] order/fill/risk/settlement events on REALTIME_BEST_EFFORT → `TX_QOS_VIOLATION`
- [ ] COMMAND_IDEMPOTENT without idempotency_key → `TX_QOS_VIOLATION`
- [ ] AUDIT events must have audit sink configured
- [ ] `go test ./middleware/... -run TestQoSHardRules` passes
