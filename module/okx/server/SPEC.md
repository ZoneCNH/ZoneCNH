# module/okx/server SPEC

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-17
- Owner: ZoneCNH
- Layer: 数据域 · OKX 行情接入层
- Module-Version: v0.1.0-spec
- Repository: [github.com/ZoneCNH/okx](https://github.com/ZoneCNH/okx)（server/ 子目录）
- Pattern: 继承 [`module/binance/server/SPEC.md`](../../binance/server/SPEC.md) 范式

---

## 1. Summary

`module/okx/server` 是 OKX 行情数据的 gRPC ingest server。接收来自 `module/okx/client` 的规范化行情事件，执行校验、幂等去重、durable acceptance，通过 exchange-neutral downstream port 分发到 `module/market-data`。

## 2. Inherited Behavior

以下内容**完全继承** [`module/binance/server/SPEC.md`](../../binance/server/SPEC.md) 范式：

- §3 Problem
- §4 Goals 通用目标（grpc binding / lifecycle / validation / idempotency / durable acceptance / ACK / dispatch / admin）
- §5 Non-goals
- §6 Consumers
- §7 FR-001 ~ FR-008 通用 server 行为
- §8 BR-001 ~ BR-006 通用业务规则（idempotency / conflict / ACK after durable / no checkpoint advance on validation fail / admin isolation / no client imports）
- §9-10 通用 interface / data model
- §11-21 通用 config / error / edge / directory / dependencies / testing / performance / observability / security / upgrade

## 3. OKX-Specific Customization

### 3.1 Source Metadata Validation（覆盖 binance §7 FR-003）

server validation 阶段额外检查：

| 字段 | 检查规则 | 失败 reject |
|------|----------|------------|
| `source_metadata.environment` | 必须 ∈ {`production`, `simulated`} | terminal_validation |
| `source_metadata.okx_channel` | 必须非空，且在 OKX 已知 channel 列表 | terminal_validation |
| `source_metadata.okx_inst_type` | 必须 ∈ {`SPOT`, `MARGIN`, `SWAP`, `FUTURES`, `OPTION`} | terminal_validation |
| `source_metadata.okx_inst_id` | 必须非空 | terminal_validation |

### 3.2 Environment Isolation Enforcement（OKX 特异 BR-010）

**单 stream 内 environment 一致性**：每条 ingest stream 在首个 IngestRequest 时锁定 `environment` 值，后续请求 environment 不同 → `terminal_validation` reject + 关闭 stream。

理由：防止 simulated 数据混入 production pipeline。

### 3.3 Downstream Dispatch（继承 binance）

dispatch 给 `module/market-data` 的事件保留 `source_metadata.environment` 字段，下游可基于此过滤：
- production pipeline：仅消费 environment=production
- 测试 pipeline：可消费 environment=simulated

### 3.4 Idempotency Store

继承 binance：生产默认 Redis（SCADA-redis 共享实例），开发/测试 in-memory。

### 3.5 Error Codes

错误码使用 `OKX-` 前缀，详见父规格 §12。

## 4. Test Matrix Delta

新增 OKX 特异 TC（编号续接 binance server 的 TC-015）：

| TC 编号 | 场景 | 预期 |
|---------|------|------|
| TC-016 | 同一 stream 内 environment 漂移 | terminal_validation reject + stream 关闭 |
| TC-017 | source_metadata.okx_inst_type 缺失 | terminal_validation reject |
| TC-018 | 未知 okx_channel | terminal_validation reject |

## 5. Release DoD Delta

继承 binance server §22，新增：

- [ ] OKX source metadata 校验全部实现并通过 TC-016/017/018
- [ ] Environment isolation enforcement 通过 stream 级别测试
- [ ] dispatch 携带 environment 字段，下游可过滤
