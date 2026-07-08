# Changelog — fred

> 版本事实源：`spec/SPEC.md` Spec-Version · Release 事实源：GitHub Release

## [v1.1.0] - 2026-07-08

### 实现
- `fred-client` / `fred-server` 双服务经 `bootstrap.Build(Stores: bootstrap.All)` 完成生命周期、健康检查、配置装载与优雅关闭。
- `internal/cs`：C/S 契约、`cs.IngestEnvelope` / `cs.ControlMessage`、版本协商（`cs.Version = "v1.1.0"`）。
- `internal/client`：`Collector`（FRED v1 全端点矩阵）、`Normalizer`、`Ingester`（raw-first OSS 归档 + NATS 发布）、`FrequencyScheduler`、配置装载。
- `internal/server`：HTTP 查询/管理 API（`/api/v1/series/{id}`、`/api/v1/observations/query`、`/api/v1/jobs/backfill`、`/api/v1/jobs/{id}`、`/api/v1/coverage`、`/api/v1/config/reload`、`/health`）、`NATSConsumerComponent`、`bootstrap_store.go` 七类存储适配器、`router.go` 外部路由（`source_component`）。
- `internal/store`：受控适配桥（`BlobStore` / `Publisher` 接口 + `ossx` / `natsx` 适配器），业务代码仅依赖接口，杜绝直连。
- `pkg/fredx`：FRED v1 全端点参数编码、分页、限流（30/120 req/min、≤2 req/s）与退避重试。
- 完成 no-lookahead 查询（`IsVisibleAt`）、Redis 缓存重建路径、共享基座边界 gate（§9 迁移）与外部路由集成测试。

### 测试与门禁
- 单元测试基于内存/接口 fake 全量通过：`internal/cs` / `internal/domain` / `internal/store` 100%，`internal/server` 逻辑文件 100%（`bootstrap_store.go` 生产成功路径经 interface fake + nil-guard 覆盖约 53%），`internal/client` 96.4%，`pkg/fredx` 78.8%。
- 集成测试经 `//go:build integration` 接入 `sre/secrets/env/dev.md`；本地缺 dev secret 时干净 SKIP，于 CI 闭环 AC-003/004/005/009/010 等。
- 边界门禁 `scripts/boundary-gates.sh` 9 道全过；§9 已从“零存储禁止”迁移为“禁止业务/入口代码直连存储 SDK，仅受控桥可引入”。

### 文档
- `spec/SPEC.md`、`spec/FEATURES.md`、`spec/ACCEPTANCE.md`、`matrix/TRACEABILITY.md` 同步至 `v1.1.0`。
- 关闭 OPEN-001（边界脚本迁移）、OPEN-002（`domain_macro` 对齐）、OPEN-003（configx 键名映射）、OPEN-006（`domain_macro` 绑定方案 B）、OPEN-007（单进程路径移除）；保留 OPEN-004/005/008/009。

### 证据
- 单元测试与边界 gate 输出见 `evidence/2026-07-08/test/`。
- 集成测试于 CI 提供 `sre/secrets/env/dev.md` 后闭环。

## [Unreleased]

- 无（v1.1.0 已交付；后续规划项见 OPEN-004/005/008/009）。
