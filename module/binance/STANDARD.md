# Binance Module Standard

- Status: Active
- Doc-Version: v1.0.0
- Last-Updated: 2026-06-23
- Scope: `module/binance/`
- Confidence: HIGH

## 1. 权威顺序

[COMPUTED][HIGH] 本文件是 `module/binance` 的标准入口，不替代根规格。发生冲突时按以下顺序裁决：

1. [COMPUTED][HIGH] `CONSTITUTION.md` 与 `docs/constitution/`：仓库级最高治理。
2. [COMPUTED][HIGH] `module/binance/SPEC.md`：当前业务合同、FR/BR/NFR/AC/TC 的根规格权威。
3. [COMPUTED][HIGH] `module/binance/STANDARD.md`：模块标准入口，固定命名、证据层级和升级规则。
4. [COMPUTED][HIGH] `module/binance/NAMING.md`：命名 SSOT，维护 product line、event type、subject、topic 的完整投影。
5. [COMPUTED][HIGH] `module/binance/BOUNDARY-GATES.md`：运行边界 gate 定义。
6. [COMPUTED][HIGH] `TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md`、`IMPLEMENTATION-PLAN.md`、`RUNTIME-MAPPING.md`：从根规格投影出的追溯、验收、功能、计划和运行映射。
7. [COMPUTED][HIGH] `client/`、`server/` 子规格与任务文件：执行分解制品，不能反向改写根规格。
8. [COMPUTED][HIGH] `docs/migrations/` 与 `docs/report/`：历史迁移、审计和分析证据，不作为当前 spec 权威。

## 2. 命名标准

[COMPUTED][HIGH] 当前有效 product line 固定为 4 个：

| product_line | 含义 |
| --- | --- |
| `spot` | 现货 |
| `um_perp` | USDⓈ-M 永续 |
| `cm_perp` | COIN-M 永续 |
| `options` | 期权 |

[COMPUTED][HIGH] 当前有效 event type 固定为 4 个：

| event_type | 含义 |
| --- | --- |
| `tick` | Ticker / BookTicker 行情 |
| `trade` | 成交行情 |
| `bar` | Kline / bar 行情 |
| `depth` | 订单簿深度行情 |

[COMPUTED][HIGH] 新增 product line 或 event type 必须先完成正式 spec bump、追溯矩阵更新、验收更新和迁移说明。Discussion Draft 中的候选项不能直接成为 runtime 合同。

## 3. NATS Subject 标准

[COMPUTED][HIGH] NATS subject 格式固定为：

```text
binance.market.{product_line}.{event_type}
```

[COMPUTED][HIGH] 当前必须覆盖 4x4 共 16 个 subject：

| product_line | tick | trade | bar | depth |
| --- | --- | --- | --- | --- |
| `spot` | `binance.market.spot.tick` | `binance.market.spot.trade` | `binance.market.spot.bar` | `binance.market.spot.depth` |
| `um_perp` | `binance.market.um_perp.tick` | `binance.market.um_perp.trade` | `binance.market.um_perp.bar` | `binance.market.um_perp.depth` |
| `cm_perp` | `binance.market.cm_perp.tick` | `binance.market.cm_perp.trade` | `binance.market.cm_perp.bar` | `binance.market.cm_perp.depth` |
| `options` | `binance.market.options.tick` | `binance.market.options.trade` | `binance.market.options.bar` | `binance.market.options.depth` |

## 4. Kafka Topic 标准

[COMPUTED][HIGH] Kafka topic 格式固定为：

```text
binance.{product_line}.{event_type}.v1
```

[COMPUTED][HIGH] 当前必须覆盖 4x4 共 16 个 topic：

| product_line | tick | trade | bar | depth |
| --- | --- | --- | --- | --- |
| `spot` | `binance.spot.tick.v1` | `binance.spot.trade.v1` | `binance.spot.bar.v1` | `binance.spot.depth.v1` |
| `um_perp` | `binance.um_perp.tick.v1` | `binance.um_perp.trade.v1` | `binance.um_perp.bar.v1` | `binance.um_perp.depth.v1` |
| `cm_perp` | `binance.cm_perp.tick.v1` | `binance.cm_perp.trade.v1` | `binance.cm_perp.bar.v1` | `binance.cm_perp.depth.v1` |
| `options` | `binance.options.tick.v1` | `binance.options.trade.v1` | `binance.options.bar.v1` | `binance.options.depth.v1` |

## 5. 证据语义

| Level | 名称 | 可证明内容 | 必备证据 | 明确不包含 |
| --- | --- | --- | --- | --- |
| L1 | 文档证据 | 规格、追溯、验收和命名投影在文档侧一致 | 本仓库文件检查、`scripts/check-binance-docs.sh` 输出、人工审查记录 | runtime 可运行、外部发布、生产可用 |
| L2 | 本地 runtime 证据 | 当前本地 `/home/binance` 快照满足基础运行门禁 | 本地 runtime HEAD SHA、`scripts/boundary-gates.sh`、`go test ./...`、本地 smoke 输出 | live、prod、race、vet、lint、secret、CI、release |
| L3 | 外部发布证据 | 可复核的远端或发布级别证据 | 经批准的发布、远端检查、生产或准生产观测、制品签名、正式 release 记录 | 未经归档的本地临时输出 |

[COMPUTED][HIGH] L2 的边界是本地 runtime 快照。任何 live/prod/race/vet/lint/secret/CI/release 证据只能作为 L3 或额外审计证据处理，不能混入 L2 定义。

## 6. Spec Bump 规则

[INFERRED][HIGH] `DATA-LIFECYCLE.md` 中的 FR-012 到 FR-024 是候选方向，不是当前合同。尤其是 issue #888 若被采纳，会把 `event_type` 从当前 4 个扩展到 6 个，必须先完成正式 spec bump，再同步本文件、`NAMING.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、任务文件和 runtime mapping。

[RULES I BROKE]：无
