---
scope: "TopicRegistry"
acceptance_criteria: []
---

# TASK-TRANSPORTX-009: TopicRegistry

- **Module**: transportx
- **spec_ref**: module/transportx/SPEC.md#FR-019

- **ACs**: AC-019
- **TCs**: TC-019
- **Phase**: QoS + Codec + Registry (Phase 2)
- **Priority**: P0
- **Dependencies**: TASK-007 (QoS)
- **Status**: Pending

## Scope

Implement TopicRegistry interface with Register, Resolve, List. Topic naming: `{domain}.{version}.{entity}.{action}`. Validate QoS binding, schema reference, ownership. Reject duplicate registration with `TX_TOPIC_DUPLICATE`.


## Non-Scope

Does NOT implement broker clients, storage drivers, or business event semantics.

## Files

- `registry/topic.go` — Topic struct
- `registry/topic_registry.go` — TopicRegistry interface + in-memory impl
- `registry/topic_registry_test.go` — Validation + duplicate rejection tests

## Acceptance

- [ ] Topic.Register validates naming pattern `{domain}.{version}.{entity}.{action}`
- [ ] Duplicate topic name → `TX_TOPIC_DUPLICATE`
- [ ] Topic.Resolve returns correct Topic by name
- [ ] Topic.List returns all registered topics
- [ ] `go test ./registry/... -run TestTopicValidation` passes

## Non-scope

- 不涉及本 Task 范围外的功能
