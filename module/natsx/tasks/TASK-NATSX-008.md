---
TASK-NATSX-008:
  module: natsx
  scope: "配置契约：foundationx.nats.* 加载、默认值、环境变量、旧别名兼容"
  spec_ref:
    - "module/natsx/SPEC.md#FR-NFR-008"
    - "module/natsx/SPEC.md#11-config-schema"
  acceptance_criteria:
    - "AC-CFG-001: foundationx.nats.* 默认值正确"
    - "AC-CFG-002: FOUNDATIONX_NATS_* 优先于 legacy NATS_*"
    - "AC-CFG-003: 配置错误不打印 token/password/nkey/credentials"
  files:
    - "config.go"
    - "env.go"
    - "options.go"
    - "config_test.go"
  priority: P1
  status: pending
---

## Scope

配置契约：foundationx.nats.* 加载、默认值、环境变量、旧别名兼容

## Non-Scope

Does NOT implement NATS server deployment, JetStream stream auto-provisioning, or NATS account management. Does NOT implement config source parsing (→ configx).

## Acceptance

- [ ] NFR-008 verified via TC-008
