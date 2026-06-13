# TASK-TRANSPORTX-008: Codec Interface + JSON Implementation

- **Module**: transportx
- **Spec**: `module/transportx/SPEC.md` v1.1.1
- **FRs**: FR-018
- **ACs**: AC-018
- **TCs**: TC-018
- **Phase**: QoS + Codec + Registry (Phase 2)
- **Priority**: P0
- **Dependencies**: none
- **Status**: Pending

## Scope

Define Codec interface with Marshal/Unmarshal. Provide default JSON codec implementation. Codec must be pluggable per Endpoint or per method.


## Non-Scope

Does NOT implement Protobuf codec (deferred to v1.2.0 per SPEC OQ-4).

## Files

- `codec/codec.go` — Codec interface
- `codec/json/codec.go` — JSON codec implementation
- `codec/json/codec_test.go` — Round-trip tests

## Acceptance

- [ ] Codec interface: `Marshal(v any) ([]byte, error)`, `Unmarshal(data []byte, v any) error`
- [ ] JSON codec round-trip preserves equality for structs, primitives, slices
- [ ] p95 ≤ 5 ms for 1 KB payload
- [ ] `go test ./codec/json/... -run TestRoundTrip` passes
