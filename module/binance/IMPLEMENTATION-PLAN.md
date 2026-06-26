# binance 实施计划

- Module-Version: v3.7.1
- Last-Updated: 2026-06-25
- Status: execution plan; release blocked until runtime gates pass
- Runtime-Repo: `/home/binance`

## 1. 目标

`binance` 必须落成分布式 C/S：client 只负责 Binance 采集、canonical 映射和 `natsx` 发布；server 只通过 `natsx` durable consumer 接收消息，并完成 `redisx` 幂等/热缓存、`taosx` 时序、`postgresx` 元数据、`clickhousex` OLAP、`ossx` 归档、`kafkax` fanout、Gin API、`redisx` coordinator lock。

## 2. 阶段门禁

| Gate | 条件 | 状态 |
| --- | --- | --- |
| G0-1 | `natsx` subject/durable contract ready | PASS |
| G0-1a | NATS JetStream deployment boundary is explicit: external service; client/server only configure `nats.url` and `FOUNDATIONX_NATS_*` | PASS |
| G0-2 | `domain_market` canonical source ready | PASS |
| G0-3 | server storage ownership includes `redisx/taosx/postgresx/clickhousex/ossx/kafkax/Gin` | PASS |
| G0-4 | `/home/binance/scripts/boundary-gates.sh` 对齐 `BOUNDARY-GATES.md` 15 gates（含 §15 C7 client-no-storage + §16 C8 server-no-exchange） | PENDING until runtime PASS |
| G0-5 | `go.mod` direct deps: `natsx/redisx/kafkax/postgresx/taosx/clickhousex/ossx/gin` | PENDING until runtime PASS |
| G0-6 | tasks cover `SERVER-017` and `FR-011` | PASS |
| G0-7 | release claim blocked until runtime evidence exists | PENDING |

## 3. 推荐 PR 顺序

| PR | Scope | 关闭标准 |
| --- | --- | --- |
| PR-000 | Remove legacy `binance-market` | active runtime 和 active docs 不再引用旧模块为当前架构。 |
| PR-001 | Root docs v2.1.2 | `SPEC.md`、`TRACEABILITY.md`、`BOUNDARY-GATES.md`、`ACCEPTANCE.md`、`IMPLEMENTATION-PLAN.md` 版本和追溯一致。 |
| PR-002 | Client `natsx` publisher | client 无 server import，无 local spool/checkpoint 作为 active C/S 交付路径。 |
| PR-003 | Server `natsx` consumer | server durable consumer 使用 ManualAck、AckWait、MaxDeliver、dead-letter 策略。 |
| PR-004 | `redisx` idempotency/cache/coordinator lock | duplicate same payload 不重复副作用；conflict payload terminal reject。 |
| PR-005 | `taosx` + `postgresx` storage | facts、catalog、replay metadata 写入失败时不 Ack。 |
| PR-006 | `kafkax` fanout | downstream topic/key/handoff failure semantics 可测试。 |
| PR-007 | Gin market/admin API | market API、auth、rate limit、admin boundary 均有测试。 |
| PR-008 | `ossx` archiver + `clickhousex` OLAP | archive ETag guard、OLAP write/query/replay queue 可测试。 |
| PR-009 | hardening/test/lint/release gate | boundary/build/test/race/vet/lint/secret scan 全 PASS。 |

## 4. Runtime 目标布局

```text
github.com/ZoneCNH/binance/
  cmd/
    binance-client/       # 独立进程，可不同机器部署
    binance-server/       # 独立进程，可不同机器部署
  internal/
    client/
      catalog/            # Binance product-line catalog
      parser/             # Binance symbol/options parser
      connector/          # Binance WebSocket/REST collector
      normalizer/         # raw event normalization
      mapper/             # domain_market mapping
      idempotency/        # idempotency key generation
      publisher/          # natsx JetStream publisher
      admin/              # client-only admin HTTP
    server/
      consumer/           # natsx durable consumer
      processor/          # validation + ack pipeline
      storage/
        idempotency/      # redisx SetNX
        timeseries/       # taosx write/query
        catalog/          # postgresx metadata
        olap/             # clickhousex projection/replay
        archiver/         # ossx archive + ETag guard
      dispatch/           # kafkax downstream broadcast
      cache/              # redisx depth/hot cache
      api/                # Gin /api/v1/market/*
      admin/              # server-only admin HTTP
```

## 5. 关键删除与禁止

| 路径/模式 | 处理 | 原因 |
| --- | --- | --- |
| `internal/cs/` | 删除或从 runtime import graph 断开 | 同进程 C/S 接口违反分布式约束。 |
| `internal/client/spool/` | 删除或退出 active publish path | JetStream durable path 替代本地同进程补偿。 |
| `internal/client/checkpoint/` | 删除或退出 active publish path | checkpoint 不能作为 client-server handoff。 |
| `internal/client/sender/` | 由 `publisher/` 替代 | 禁止 gRPC/proto ingest sender 回流。 |
| local `.proto` / gRPC ingest schema | 禁止 | wire contract 必须外部化，不在 binance 本地定义。 |
| 通用 market storage/query/strategy ownership | 禁止 | binance 只拥有 Binance-specific ingestion/storage/API。 |

## 6. 实现顺序

1. 修复 `/home/binance/scripts/boundary-gates.sh`，让 15 gates（含 C7/C8 数据边界）能真实暴露 runtime 阻断。
2. 固化 runtime 配置边界：client/server 只读取外部 `nats.url` 和 `FOUNDATIONX_NATS_*`，不启动或打包 NATS Server。
3. 调整 `go.mod` direct deps：`natsx/redisx/kafkax/postgresx/taosx/clickhousex/ossx/gin` 必须为 direct。
4. 删除或隔离 `internal/cs`、spool、checkpoint、sender 等同进程 C/S 路径。
5. client 实现：catalog -> parser -> connector -> normalizer -> mapper -> idempotency -> publisher -> admin。
6. server 实现：consumer -> processor -> redisx idempotency/cache/lock -> taosx -> postgresx -> clickhousex -> ossx -> kafkax -> Gin API -> admin。
7. 补齐边界测试、集成测试、失败注入、build/test/race/vet/lint/secret scan。
8. 只有 runtime evidence 全部通过后，才允许把 `TRACEABILITY.md` 的 Pending 改为 Implemented。

## 7. Done Definition

| 条件 | 必须结果 |
| --- | --- |
| `/home/binance/scripts/boundary-gates.sh` | 15/15 PASS。 |
| `go build ./...` | PASS。 |
| `go test ./... -race -count=1` | PASS。 |
| `go vet ./...` | PASS。 |
| `golangci-lint run` | PASS。 |
| `gitleaks detect --no-git` | PASS。 |
| `TRACEABILITY.md` | 不存在没有 runtime evidence 的 `Implemented`。 |

## 8. 当前停止条件

在以下条件满足前，`module/binance` 只能声明“文档追溯闭合、runtime release blocked”，不得声明 Release Done：

- boundary gates 仍有任一 FAIL。
- build/test/race/vet/lint/secret scan 任一缺失或失败。
- `/home/binance` 中仍存在同进程 C/S、client/server 互导、local wire schema 或 go.mod direct dependency 不合规。
