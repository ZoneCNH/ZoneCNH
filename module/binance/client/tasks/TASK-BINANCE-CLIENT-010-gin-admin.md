# TASK-BINANCE-CLIENT-010 Gin Admin

## Objective

Expose safe client-local admin and health endpoints.

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
- `/readyz` verifies client config, spool availability, and sender readiness.
- `/debug/*` is read-only.
- `/admin/*` mutates client-local state only.
- no endpoint exposes API keys, secrets, signatures, or private config.
- admin cannot mutate server state.

## Dependencies

- transport/admin policy
- CLIENT-009 spool/checkpoint
