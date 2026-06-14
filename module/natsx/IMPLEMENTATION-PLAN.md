# natsx 实现计划

> 来源：[SPEC.md](./SPEC.md) | [TRACEABILITY.md](./TRACEABILITY.md) | 13 TASK 文件
> 生成日期：2026-06-14
> 更新：2026-06-14（task 6→13 重构：补齐 NFR 覆盖，TASK-006 重聚焦，TASK-010 废弃）

---

## 1. 依赖 DAG

```text
TASK-001 (Core NATS Pub/Sub) ──→ TASK-002 (Request-Reply, extends client.go)
    │
    ├──→ TASK-005 (Health)
    ├──→ TASK-006 (SubjectBuilder)
    ├──→ TASK-007 (Envelope, extends msg.go)
    │
TASK-003 (JetStream Pub/Sub) ──→ TASK-004 (AddStream/Consumer + reconnect, extends jetstream.go)
    │
    ├──→ TASK-008 (Config contract)
    ├──→ TASK-009 (Observability)
    └──→ TASK-011 (Security/TLS/live integration)
            │
            └──→ TASK-012 (Performance benchmark)
                    │
                    └──→ TASK-013 (Layer boundary) ──→ TASK-014 (Release + CI gate)
```

## 2. 实现顺序

### Phase 1: Core Foundation (P0, 阻塞链)

| Task | Scope | Files | Effort |
|------|-------|-------|--------|
| TASK-001 | Publish/Subscribe：subject 校验、handler 注册、连接错误处理 | client.go, subscription.go, msg.go, errors.go, client_test.go | 2h |
| TASK-002 | Request-Reply：responder、timeout、ctx cancel | client.go, client_test.go | 1h |
| TASK-003 | JetStream Publish/Subscribe：ack/redelivery/dead-letter | jetstream.go, errors.go, jetstream_test.go | 2h |
| TASK-004 | AddStream/AddConsumer：创建、幂等、冲突配置、reconnect | jetstream.go, options.go, internal/reconnect/backoff.go, jetstream_test.go | 2h |

### Phase 2: Cross-cutting (P1, 可并行)

| Task | Scope | Files | Effort |
|------|-------|-------|--------|
| TASK-005 | Health 检查、GracefulShutdown、Drain | health.go, health_test.go | 1h |
| TASK-006 | SubjectBuilder：构造与解析 | subject.go, subject_test.go | 1h |
| TASK-007 | NatsMessageEnvelope：trace/message/schema header 双向映射 | msg.go, msg_test.go | 1h |
| TASK-008 | Config：foundationx.nats.* 加载、环境变量、旧别名兼容 | config.go, env.go, options.go, config_test.go | 2h |
| TASK-009 | Observability：foundationx_nats_* 指标、连接日志、错误脱敏 | natsx.go, metrics_test.go | 1h |
| TASK-011 | Security/TLS：凭证注入、TLS 配置、live integration | config.go, live_integration_test.go | 1h |

### Phase 3: Quality Gates (P2, 收尾)

| Task | Scope | Files | Effort |
|------|-------|-------|--------|
| TASK-012 | Performance：benchmark 基线 + SLO 断言 | benchmark_test.go | 1h |
| TASK-013 | Layer boundary：依赖边界检查 | go.mod | 0.5h |
| TASK-014 | Release：README、CHANGELOG、CI gate、覆盖率 | go.mod, README.md, CHANGELOG.md, example_test.go, integration_test.go | 2h |

## 3. 总 Effort

| Phase | Tasks | Effort |
|-------|-------|--------|
| Core Foundation | 4 | 7h |
| Cross-cutting | 6 | 7h |
| Quality Gates | 3 | 3.5h |
| **Total** | **13** | **17.5h** |

## 4. CI Gate 矩阵

| Gate | Phase | 条件 | 命令 |
|------|-------|------|------|
| go build | All | 零错误 | `GOWORK=off go build ./pkg/natsx` |
| go test -race | All | 全部通过 | `GOWORK=off go test -race ./pkg/natsx -count=1` |
| coverage >= 80% | Final | 覆盖率达标 | `go test ./... -coverprofile=.coverage/cover.out && go tool cover -func=.coverage/cover.out` |
| go vet | Final | 零警告 | `GOWORK=off go vet ./pkg/natsx` |
| golangci-lint | Final | 零错误 | `golangci-lint run` |
| secret scan | Final | 零泄露 | `gitleaks detect --no-git` |
| benchmark | Phase 3 | 结果附 PR | `go test -bench=. -benchmem -count=3 ./...` |

## 5. 风险

| 风险 | 影响 | 缓解 |
|------|------|------|
| client.go / jetstream.go 多个 TASK 共享 | 合并冲突 | Phase 内顺序执行，Phase 间按文件归属协调 |
| NFR task AC ID 为自定义前缀 | rubric 扣 1 分 LOW | 已记录为工程惯例，不阻塞 |
| codex/copilot 评分源缺失 | gate 依赖 --force | 待补齐后重新仲裁 |
