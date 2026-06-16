# TASK-BINANCE-SERVER-006 Gin Admin

## Objective

Expose safe server-local admin and health endpoints.

## Scope

Endpoints:

```text
/healthz
/readyz
/debug/*
/admin/*
```

## Deliverables

- Gin router
- health/readiness handlers
- debug handlers
- protected admin handlers
- secret redaction tests

## Acceptance Criteria

- `/healthz` reports process liveness.
- `/readyz` verifies ingest server and downstream dispatch readiness.
- `/debug/*` is read-only.
- `/admin/*` mutates server-local state only.
- admin cannot mutate client connector state.
- admin cannot bypass idempotency.
- no endpoint exposes secrets.

## Dependencies

- SERVER-001
- SERVER-005
- transport/admin policy
