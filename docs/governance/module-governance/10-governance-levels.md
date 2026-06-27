# 模块治理等级

- Module-Governance-Topic: 10
- Last-Updated: 2026-06-27
- Status: Active
- Related-Beads: `ZoneCNH-cdma`

本专题定义模块治理 L1/L2/L3 等级，用于区分不同模块的治理负载。等级是治理义务强度，不是业务价值排序。

## §1 等级定义

| 等级 | 适用模块 | 最小治理义务 |
| --- | --- | --- |
| L1 | 实验性、低依赖、低风险、无生产路径模块 | registry 登记、基础 owner、Spec 状态清晰 |
| L2 | 已被其他模块依赖、进入 active/maintained、具备 release 投影的模块 | L1 + release ledger、health 评分、季度复盘 |
| L3 | 生产路径、资金/订单/关键数据链路、跨域核心依赖模块 | L2 + 强 owner 责任、发布证据、退役/回滚预案、依赖变更审查 |

## §2 等级字段【软】

`module/registry.yaml` 后续可增加 `governance_level` 字段。未正式迁移前，等级可先在模块治理复盘记录中声明。

推荐取值：

```yaml
governance_level: L1 | L2 | L3
```

## §3 升级触发【硬】

出现任一条件时，应把模块治理等级提升到至少 L2：

| 触发 | 最低等级 |
| --- | --- |
| 被其他 active 模块运行时依赖 | L2 |
| 存在正式 release 或 release candidate | L2 |
| 承载生产数据、资金、订单、风控、账户、密钥、审计链路 | L3 |
| 作为跨域 canonical contract / DTO / protocol | L3 |

## §4 降级触发【硬】

等级降级必须有记录，且至少说明：

1. 下游依赖是否已迁移或退役。
2. release 与 evidence 是否已归档。
3. 生命周期是否从 active/maintained 转入 deprecated/archived。
4. 是否需要退役 ADR；若不需要，写明原因。

## §5 与健康度的关系【软】

L3 模块健康度红线应优先处理。若 L3 模块连续两个季度处于 red 且无整改计划，必须开治理 issue 或退役/替换 ADR。
