---
TASK-NATSX-011:
  module: natsx
  scope: "安全注入：凭证环境变量、TLS 配置、日志脱敏、live integration"
  spec_ref:
    - "module/natsx/SPEC.md#19-security"
    - "module/natsx/SPEC.md#BR-008"
  acceptance_criteria:
    - "§19: FOUNDATIONX_NATS_TOKEN/USERNAME/PASSWORD/NKEY 安全加载"
    - "§19: TLS ca-file 可配置，配置错误不泄露凭据"
    - "§19: live integration 测试通过且输出不含凭据"
  files:
    - "config.go"
    - "live_integration_test.go"
  priority: P1
  status: pending
---

## Scope

安全注入：凭证环境变量、TLS 配置、日志脱敏、live integration

## Non-Scope

Production TLS endpoint gate remains separate. The release-blocking production TLS closure packet for `BLK-002` is governed by `release/trust/foundation-maturity-evidence-matrix-20260615.md` and must not be inferred from this local/dev live integration task.

## Acceptance

- [ ] NFR-001 verified via TC-011
- [ ] NFR-002 verified via TC-011
