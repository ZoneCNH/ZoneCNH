---
TASK-NATSX-011:
  module: natsx
  scope: "安全注入：凭证环境变量、TLS 配置、日志脱敏、live integration"
  spec_ref:
    - "module/natsx/SPEC.md#FR-NFR-001"
    - "module/natsx/SPEC.md#FR-NFR-002"
    - "module/natsx/SPEC.md#BR-008"
    - "module/natsx/SPEC.md#19-security"
  acceptance_criteria:
    - "AC-SEC-001: FOUNDATIONX_NATS_TOKEN/USERNAME/PASSWORD/NKEY 安全加载"
    - "AC-SEC-002: TLS ca-file 可配置，配置错误不泄露凭据"
    - "AC-SEC-003: live integration 测试通过且输出不含凭据"
  files:
    - "config.go"
    - "live_integration_test.go"
  priority: P1
  status: pending
---

## Scope

安全注入：凭证环境变量、TLS 配置、日志脱敏、live integration

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Production TLS endpoint gate remains separate.

## Acceptance

- [ ] NFR-001 verified via TC-011
- [ ] NFR-002 verified via TC-011
