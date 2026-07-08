# 宏观数据源 C/S 模块标准

> **规范级别**：推荐（非强制）  
> **适用模块**：fred, bea, ecb, treasury, uk_cb, japan_cb, yahoo, yield_curve, jin10, eastmoney, crcl, macro_data, macro_regime  
> **状态**：草案 v0.1.0  
> **创建日期**：2026-07-08  

## 1 目的

宏观数据源模块（采集外部宏观数据→归一化→持久化→暴露查询接口）共享相同的 C/S 架构槽位和持久化拓扑。本标准化 13 个数据源模块的统一工程约束，避免每模块一份重复的 RULES.md（如 fred RULES.md v1.1.0）的同时守住关键质量门禁。

## 2 架构槽位

```
采集层                  持久化层              查询层
┌──────────┐   NATS    ┌──────────┐   HTTP   ┌──────────┐
│  client  │ ──ingest→ │  server  │ ←──query─│  API     │
│ (采集)   │           │ (持久化)  │           │ (对外)    │
└──────────┘           └──────────┘           └──────────┘
```

| 层 | 职责 | 禁止逾越 |
|----|------|---------|
| client | 调用外部 API → 归一化为 `MacroObservation` → NATS ingest | 禁止直接访问 server 的内部存储 |
| server | 接收 ingest → 持久化写入 → 响应 query | 禁止直接调用外部 API |
| API   | HTTP 查询 + 管理接口 | 禁止绕过 IsVisibleAt 返回未发布数据 |

**进程边界**：client 和 server 是独立进程，唯一的通信通道是 NATS JetStream（ingest subject `cs.IngestSubject`）。

## 3 存储拓扑与写入顺序

所有数据源模块必须遵守以下写入顺序（**raw-first 守恒律**）：

| 步骤 | 存储 | 语义 |
|------|------|------|
| 1 | OSS (BlobStore) | 原始 API 响应归档，路径含 SHA256 hash |
| 2 | Postgres | checkpoint 推进 + 幂等账本 + 序列元数据 |
| 3 | TDengine | 结构化 observation 写入（权威时序库） |
| 4 | Redis | 缓存（可重建层，可容忍丢失） |
| 5 | ClickHouse | 分析读模型（可重建层） |
| 6 | Kafka | 持久化 business event（下游消费） |

**幂等键**：五元组 `(series_id, vintage_at, released_at, available_at, source_component)` 作为幂等性去重键。违反顺序的写入视为违规。

## 4 无前视语义

所有 API 查询必须通过 `IsVisibleAt(t time.Time)` 过滤：

- 禁止返回 `released_at > query_time` 或 `available_at > query_time` 的观测值
- 外部路由序列（来自 ECB/BoJ/Yahoo 等）降级为仅 `available_at` 过滤，不做 vintage 断言
- 违反此规则的 PR 自动 block

## 5 七类存储适配器接口

```
Store {
    TD    TDStore       // WriteObservation / QueryObservations
    PG    PGStore       // InitSchema / WriteSeriesMeta / CreateJob / IsIdempotent / MarkIdempotent
    Redis RedisStore   // Get / Set / Del (缓存层)
    Kafka KafkaStore   // PublishEvent (durable events)
    NATS  NATSStore    // Subscribe / Publish (ingest handoff)
    OSS   OSSStore     // Put / Get (raw archive)
    CH    CHStore      // WriteObservation / QueryObservations (分析读模型)
}
```

各模块仅在 bootstrap 中按需初始化（`Spec.Stores` 位掩码）。测试环境使用 `MemoryStore`。

## 6 路由与源组件

- `source_component` 标识数据权威来源（如 `FRED`, `ECB`, `BOJ`, `YAHOO`）
- 外部路由序列权威清单在 `spec/SERIES-CATALOG.md` 维护
- 路由逻辑集中在 `internal/domain/source_router.go`（或等价位置），禁止散落

## 7 契约变更协议

`cs.IngestEnvelope` schema 变更：

| 类型 | 操作 | 通知 |
|------|------|------|
| minor | 新增可选字段 | 仅更新 `cs.Version` |
| major | 删除/重命名必填字段 | 新建 ADR + 提前 2 周通知 ms_brain 等下游 |

## 8 CI 门禁

每个数据源模块的 CI pipeline 必须包含：

| 门禁 | 命令 | 说明 |
|------|------|------|
| Unit | `go test ./... -count=1` | 单元测试（无外部依赖） |
| Integration | `go test -tags=integration ./internal/integration/...` | 集成测试（带 NATS/Postgres 的端到端验证） |
| Build | `go build ./...` + `go vet ./...` | 编译正确性 |
| Lint | `golangci-lint run` 或等价 | 代码质量 |
| Boundary Gates | `bash scripts/boundary-gates.sh` | 模块边界校验（C/S 隔离、依赖合规、wire contract 等） |
| Worktree Guard | `bash scripts/harness/no-main-dev.sh` | 禁止直接 main 开发 |
| Coverage | `go test -coverprofile=...` + `go tool cover` | 覆盖率门禁（≥80%） |

## 9 版本管理

- 模块 `spec/SPEC.md` 的 `Spec-Version` 字段为唯一版本权威源
- `registry.yaml` 的 `spec_version` 和 `release.latest_tag` 必须与 spec 和 GitHub Release 一致
- 版本变更必须同步更新 `registry.yaml`（违反 `RULES.md §9` 级别的治理规则）

## 10 文档清单

| 文档 | 路径 | 强制 |
|------|------|------|
| SPEC | `module/{m}/spec/SPEC.md` | 强制 |
| RULES | `module/{m}/RULES.md` | 建议（可引用本标准代替） |
| README | `README.md` | 强制 |
| CHANGELOG | `CHANGELOG.md` | 强制 |
| BOUNDARY-GATES | `BOUNDARY-GATES.md` | 强制 |
| CI Workflow | `.github/workflows/ci.yml` | 强制 |
| Integration Workflow | `.github/workflows/integration.yml` | 建议 |
| Release Workflow | `.github/workflows/release.yml` | 建议 |

## 附录 A：适用模块对照

| 模块 | 代码库 | C/S 实现 | 当前生命周期 |
|------|--------|----------|-------------|
| fred | fred | ✓ | implemented |
| bea | bea | scaffold | proposed |
| ecb | ecb | scaffold | proposed |
| treasury | treasury | scaffold | proposed |
| uk_cb | uk-cb | scaffold | proposed |
| japan_cb | japan-cb | scaffold | proposed |
| yahoo | yahoo | scaffold | proposed |
| yield_curve | yield-curve | scaffold | proposed |
| jin10 | jin10 | ✓ | planned |
| eastmoney | eastmoney | scaffold | proposed |
| crcl | crcl | scaffold | proposed |
| macro_data | macro-data | ✓ | implemented |
| macro_regime | macro-regime | ✓ | implemented |
