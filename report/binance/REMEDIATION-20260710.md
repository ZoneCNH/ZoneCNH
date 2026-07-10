# Binance 2026-07-10 深度分析修复回执

> 状态：[COMPUTED, HIGH]；对应 runtime 分支 `fix/binance-production-readiness-20260710`，提交 `462772f6`。

## 已修复

- [COMPUTED, HIGH] CI 全部迁移到受控 self-hosted runner；移除 Docker、Kubernetes、inline deploy 与旧 contract adapter；增加 release artifact/SBOM 工作流。
- [COMPUTED, HIGH] Spot、UM、CM、Options 的 connector/endpoint/stream 配置独立解析，避免 Spot 配置泄漏；公共配置校验与 product metadata 测试补齐。
- [COMPUTED, HIGH] orderbook 使用 product+symbol identity、字符串定点价格 key、科学计数与任意数值零处理；接受单边 depth diff，补齐 sequence、align、generation/recovery 与并发测试。
- [COMPUTED, HIGH] ingest 先完成持久化/dispatch/DLQ durable handoff，再写 durable idempotency；同 hash 的 pending reservation 可重试，不再错误返回 duplicate ACK；生产 assembly 启用 strict durable handoff，DLQ 可由 `FOUNDATIONX_BINANCE_DLQ_PATH` 注入。
- [COMPUTED, HIGH] `go test ./...`、`git diff --check`、boundary gates 19/19 PASS。

## 仍需外部闭合

- [COMPUTED, HIGH] GitHub hosted runner、真实 Binance WebSocket、Kafka/存储 live E2E、正式 tag/release notes、部署前检查与 rollback 证据仍需在受控环境执行；因此 `release_closeable=NO`，不能由本地 PASS 推导为可发布。
- [INFERRED, MED] 生产环境必须显式设置 `FOUNDATIONX_BINANCE_DLQ_PATH` 并确保目录由 SRE 预创建且具备持久磁盘权限；本地测试不会伪造该外部条件。

