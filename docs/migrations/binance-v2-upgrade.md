# Binance v2 Upgrade Migration Notes

- Status: Historical Migration Note
- Created: 2026-06-23
- Scope: `module/binance/`
- Confidence: HIGH

## 1. 定位

[COMPUTED][HIGH] 本文件是历史迁移说明，用于替代旧 deep analysis 中的执行引用。它不作为当前 spec 权威，不覆盖 `module/binance/SPEC.md`、`module/binance/STANDARD.md` 或 `module/binance/NAMING.md`。

[COMPUTED][HIGH] 当前权威以 `module/binance/SPEC.md` v2.2.3 为根，以 `STANDARD.md` 固定权威顺序、证据语义和 4x4 命名标准，以 `NAMING.md` 维护完整 subject/topic 投影。

## 2. 迁移背景

[INFERRED][HIGH] v2 系列迁移的目标是把 `binance` 文档控制面从散落的历史分析结论，收敛为可审查、可复跑、可追溯的治理制品：

1. [COMPUTED][HIGH] root spec 固定当前业务合同和版本。
2. [COMPUTED][HIGH] `STANDARD.md` 固定权威顺序、NATS/Kafka 命名和 L1/L2/L3 证据语义。
3. [COMPUTED][HIGH] `NAMING.md` 固定 product line、event type、subject 和 topic 的 4x4 投影。
4. [COMPUTED][HIGH] 历史报告只保留为 evidence，不再直接驱动当前合同。

## 3. 当前命名合同

[COMPUTED][HIGH] NATS subject 格式为：

```text
binance.market.{product_line}.{event_type}
```

[COMPUTED][HIGH] Kafka topic 格式为：

```text
binance.{product_line}.{event_type}.v1
```

[COMPUTED][HIGH] 当前 product line 为 `spot`、`um_perp`、`cm_perp`、`options`；event type 为 `tick`、`trade`、`bar`、`depth`。任何新增类型必须先 spec bump。

## 4. 历史报告替代规则

[COMPUTED][HIGH] 旧 deep analysis 报告中的版本、任务名、Kafka 投影和 runtime 快照只作为历史排障线索。后续引用应优先指向：

| 主题 | 当前引用 |
| --- | --- |
| 业务合同 | `module/binance/SPEC.md` |
| 模块标准 | `module/binance/STANDARD.md` |
| 命名矩阵 | `module/binance/NAMING.md` |
| 数据生命周期候选 | `module/binance/DATA-LIFECYCLE.md` |
| 文档自检 | `scripts/check-binance-docs.sh` |

## 5. 验收方式

[COMPUTED][HIGH] 文档侧迁移验收以 `scripts/check-binance-docs.sh` 为可复跑入口。运行侧证据按 `STANDARD.md` 的 L2 定义，只能由本地 runtime HEAD SHA、boundary gates、Go tests 和 smoke 输出组成。

[RULES I BROKE]：无
