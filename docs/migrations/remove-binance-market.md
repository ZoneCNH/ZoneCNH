# Migration: 移除 binance-market 模块

> 本文件记录 `binance-market` 旧模块从 ZoneCNH active architecture 中移除的迁移过程。
>
> 此路径是 `module/binance/spec/SPEC.md` BR-001、`module/binance/BOUNDARY-GATES.md` §2 显式允许的 legacy 历史性提及位置（与 `CHANGELOG.md` 并列）。

- Migration-ID: MIG-001
- Status: Completed
- Last-Updated: 2026-06-17
- Owner: ZoneCNH
- Related: `module/binance/spec/SPEC.md` v1.0.0、`module/binance/BOUNDARY-GATES.md` §2、`module/binance/matrix/TRACEABILITY.md` BR-001、`module/binance/tasks/TASK-BINANCE-ROOT-000-remove-binance-market.md`

---

## 1. 背景

`binance-market` 是 ZoneCNH 早期数据域的 Binance 行情 Provider 模块，与被动 `binance` SDK 并存。该双模块拆分存在以下结构性问题：

1. **职责不清**：`binance` SDK 和 `binance-market` Provider 边界模糊，新增产品线时无法确定代码归属
2. **传输契约缺失**：Provider 输出的事件"向谁发送"未定义，下游每个集成各自发明传输方式
3. **身份碰撞风险**：Spot `BTCUSDT` 与 USDⓈ-M `BTCUSDT` 缺少显式 `product_line` 维度，下游可能产生 InstrumentKey 碰撞
4. **可靠性无保障**：缺少 at-least-once + idempotent acceptance + ACK-driven checkpoint 的端到端语义
5. **边界侵蚀**：Provider 容易向其内部引入 storage/query/strategy 所有权，违背数据域职责边界

## 2. 替代方案

`binance-market` 被 **`module/binance` C/S Module** 取代，即显式 client/server 双端架构：

```text
Binance Exchange
  ↓ (REST/WebSocket)
module/binance/client     ← 交易所侧采集（4 产品线 connector + parser + spool + checkpoint）
  ↓ contracts §8.4 gRPC bidi stream (MarketDataService.Ingest)
module/binance/server     ← 摄入受理（验证 + 幂等 + durable ACK + dispatch）
  ↓ market_data §4 DownstreamDispatchPort
module/market_data        ← 交易所中立后续管线
```

替代映射：

| binance-market 旧能力 | 新归属 |
|---|---|
| Binance REST/WebSocket 采集 | `module/binance/client/connector/{spot,usdm_futures,coinm_futures,options}.go` |
| Symbol 解析 | `module/binance/client/parser/parser.go` |
| 事件规范化 | `module/binance/client/normalize/normalize.go` |
| canonical 类型映射 | `module/binance/client/mapper/mapper.go`（依赖 `module/domain_market`） |
| 下游传输 | `module/contracts` §8.4 `MarketDataService` gRPC bidi stream |
| 摄入受理 | `module/binance/server/internal/server/{ingest,validation,idempotency,ack,dispatch}` |
| 下游分发 | `module/binance/server/dispatch` → `module/market_data` §4 DownstreamDispatchPort |

## 3. 时间线

| 日期 | 事件 |
|---|---|
| 2026-06-05 | `xhyperium/binance-market` 仓库创建 |
| 2026-06-14 | 仓库最后一次 push（无后续变更） |
| 2026-06-16 | `module/binance` C/S Module spec v1.0.0 正式发布（root + client + server 三份 SPEC） |
| 2026-06-16 | `STATUS.md` / `ARCHITECTURE.md` / `README.md` 中 `binance-market` 引用全部清除 |
| 2026-06-16 | `binance-market` 仓库设为 **private**（不公开访问） |
| 2026-06-17 | `module/binance` 上游 6/6 G0 Phase Gate 全部 PASS（contracts §8.4 + domain_market §10 + market_data §4） |
| 2026-06-17 | `binance-market` 仓库 **deleted**（彻底删除，不可恢复） |
| 2026-06-17 | `module/FOUNDATION-DEPS.yaml` 移除 `github.com/xhyperium/binance-market` 依赖项（version 1.2.1 → 1.2.2） |
| 2026-06-17 | 本迁移文档归档 |

## 4. 当前禁止路径

`module/binance/BOUNDARY-GATES.md` §2 在 CI 中强制以下规则：

```text
forbidden_re='module/binance-market|github.com/xhyperium/binance-market|binance-market|docs/services/binance-market-client-svc.md'
allow_re='docs/migrations/remove-binance-market.md|CHANGELOG.md'
```

active 文档中（除本文件 + `CHANGELOG.md`）任何对 `binance-market` 的引用都会触发 CI gate 失败，PR 不可合并。

## 5. 历史代码处理建议

如外部仓库或下游模块仍存在对 `github.com/xhyperium/binance-market` 的依赖：

1. **采集路径替换**：将 `binance-market` 客户端调用替换为 `module/binance/client` 的运行时实现（runtime 仓库 `github.com/xhyperium/binance` 的 `cmd/binance-client` 与 `internal/client` 子包）
2. **接收路径替换**：原直接消费 `binance-market` 输出的下游模块，应通过 `module/contracts` §8.4 `MarketDataService` gRPC bidi stream 对接 `module/binance/server`，或通过 `module/market_data` §4 DownstreamDispatchPort 接收已验收事件
3. **域类型替换**：原 `binance-market` 自定义的 ProductLine / InstrumentKey / MarketScope 等枚举与值对象，应改为 `module/domain_market` §10 中 canonical 类型
4. **wire 协议替换**：原 `binance-market` 自定义传输协议（HTTP/Kafka 等），应改为 `module/contracts` §8.4 定义的 gRPC `IngestRequest` / `IngestResult` 双向流

## 6. 不可恢复说明

`binance-market` 仓库已于 2026-06-17 通过 GitHub 仓库删除（`gh api -X DELETE repos/xhyperium/binance-market` 等价操作）彻底移除：

- 仓库 URL `https://github.com/xhyperium/binance-market` 返回 404
- `gh api repos/xhyperium/binance-market` 返回 `Not Found`
- 历史 commit、issue、PR、release 全部不可恢复
- 已分发的 release 二进制资产（如有）从此无法通过 GitHub 下载
- 任何外部 fork（如存在）独立保留但与 origin 完全断链

**不可逆性**：删除操作无法在 GitHub 上原地撤销。如需恢复历史，须有外部 mirror 或本地 `git clone` 备份。

> 旧 `binance` SDK 仓库（`github.com/xhyperium/binance`）保留，作为 `module/binance` C/S Module 的 monorepo 运行时仓库继续承载新架构。两者重名无关：旧 SDK 仓库已被新模块完全接管。

## 7. 关联清单

- 旧文档（已删除或不再 active）：
  - `docs/services/binance-market-client-svc.md`（已删除）
  - `module/binance-market/`（从未在本仓库存在；如有外部 fork 需自行清理）
- 关联 issue / PR：
  - `TASK-BINANCE-ROOT-000-remove-binance-market`（root tasks 目录）
  - PR #674：fix: binance/server SPEC Repository 字段 monorepo 对齐（同期清理 server SPEC 引用）
  - 本 PR：docs: 创建 binance-market 移除迁移文档 + 清理 FOUNDATION-DEPS
- 关联 SPEC：
  - `module/binance/spec/SPEC.md` §5（Non-goals 中显式声明不兼容）+ §8 BR-001（CI gate 强制）+ §21 Upgrade Compatibility + Appendix B
  - `module/binance/BOUNDARY-GATES.md` §2（gate script）
  - `module/binance/matrix/TRACEABILITY.md` BR-001 + AC-022
  - `module/binance/tasks/TASK-BINANCE-ROOT-000-remove-binance-market.md`

---

> 本文件一旦创建后内容稳定。后续变更以追加节方式记录于 §3 时间线表，不修改既有节内容。
