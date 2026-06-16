# TASK-BINANCE-ROOT-005 contracts Dependency

## Objective

Validate and document the dependency of `module/binance` on `module/contracts` for the gRPC wire protocol, ensuring that the `MarketDataService`, ingest request/response types, and enumeration compatibility policy are correctly consumed.

## Scope

`module/contracts` owns the protobuf definitions and gRPC service contracts that wire `module/binance/client` to `module/binance/server`. This task ensures the contracts are sufficient for both sides to operate independently and that ACK/reject semantics are testable.

## Deliverables

- Dependency declaration in root SPEC.md referencing `module/contracts`
- Verification that all required protocol types are available:
  - `MarketDataService` (gRPC service definition)
  - `IngestRequest`
  - `IngestAck`
  - `IngestReject`
  - Canonical event envelope wire representation
  - Enum compatibility policy
- gRPC sender generation verification (client side)
- gRPC receiver implementation verification (server side)

## Acceptance Criteria

1. Client can generate a gRPC sender from the contracts definitions.
2. Server can implement the gRPC receiver interface from the contracts definitions.
3. ACK and reject semantics are documented and testable.
4. Enum compatibility policy is documented and enforceable.
5. No wire types are redefined within `module/binance`.

## Dependencies

- PR-001 (root docs established).
- `module/contracts` (external — must expose the listed protocol types).
