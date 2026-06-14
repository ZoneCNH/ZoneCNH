# natsx 实现计划

> 来源：[SPEC.md](./SPEC.md) | [TRACEABILITY.md](./TRACEABILITY.md)
> 生成日期：2026-06-14
> 更新：2026-06-14（补齐 files/验证命令/风险）

---

## 1. 依赖 DAG

```text
TASK-NATSX-001 (Phase 1: Core NATS publish/subscribe)
├── TASK-NATSX-002 (Request-Reply)
├── TASK-NATSX-003 (JetStream publish/subscribe)
├── TASK-NATSX-004 (JetStream AddStream/AddConsumer + reconnect)
├── TASK-NATSX-005 (Health checks)
└── TASK-NATSX-006 (CI/Benchmark/Docs)
```

## 2. 实现顺序

### Phase 1: Foundation

| Task | Scope | Files | Effort | Verify |
|------|-------|-------|--------|--------|
| TASK-NATSX-001 | Publish/Subscribe 基础接口：subject 校验、handler 注册、连接错误处理 | client.go, subscription.go, msg.go, errors.go, client_test.go | 2h | `go test -run 'TestEmbeddedNATSCore' -count=1` |
| TASK-NATSX-002 | Request-Reply 模式：responder、timeout、ctx cancel | client.go, client_test.go | 2h | `go test -run 'TestEmbeddedNATSCore' -count=1` |

### Phase 2: Features

| Task | Scope | Files | Effort | Verify |
|------|-------|-------|--------|--------|
| TASK-NATSX-003 | JetStream 发布订阅：ack/redelivery/dead-letter 行为 | jetstream.go, errors.go, jetstream_test.go | 2h | `go test -race -count=1` |
| TASK-NATSX-004 | AddStream/AddConsumer：创建、幂等、冲突配置、drain | jetstream.go, options.go, internal/reconnect/backoff.go, jetstream_test.go | 2h | `go test -race -count=1` |
| TASK-NATSX-005 | Health 检查、GracefulShutdown、Drain、错误脱敏 | health.go, health_test.go | 2h | `go test -race -count=1` |

### Phase 3: Quality Gates

| Task | Scope | Files | Effort | Verify |
|------|-------|-------|--------|--------|
| TASK-NATSX-006 | CI gate 集成、测试覆盖率、benchmark 基线、README、CHANGELOG | go.mod, README.md, CHANGELOG.md, benchmark_test.go, example_test.go | 2h | `go test ./... -coverprofile=coverage.out && go tool cover -func=coverage.out` |

## 3. 总 Effort

| Phase | Tasks | Effort |
|-------|-------|--------|
| Foundation | 2 | 4h |
| Features | 3 | 6h |
| Quality | 1 | 2h |
| **Total** | **6** | **12h** |

## 4. CI Gate 矩阵

| Gate | Phase | 条件 | 命令 |
|------|-------|------|------|
| go build | All | 零错误 | `GOWORK=off go build ./pkg/natsx` |
| go test -race | All | 全部通过 | `GOWORK=off go test -race ./pkg/natsx -count=1` |
| coverage >= 80% | Final | 覆盖率达标 | `go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` |
| go vet | Final | 零警告 | `GOWORK=off go vet ./pkg/natsx` |
| golangci-lint | Final | 零错误 | `golangci-lint run` |
| gitleaks | Final | 零命中 | `gitleaks detect --no-git` |

## 5. 风险与回滚

| 风险 | 级别 | 缓解 | 回滚 |
|------|------|------|------|
| Core NATS API 破坏性变更 | LOW | 已有可工作实现 (repair-slice)，向后兼容 | `git revert` 单 commit |
| JetStream 消费语义回归 | LOW | repair-slice 已覆盖 publish/pull/ack/nack/redelivery | 回滚到 commit `393d148` |
| 配置兼容 (FOUNDATIONX_NATS_* vs NATS_*) | LOW | 已有 canonical+legacy fallback 测试 | 回退 env loading 逻辑 |
| TLS 配置遗漏 | LOW | PR #7 已实现 TLS gate + 集成测试 | 回退 TLS config 变更 |
