# L2.5 领域共享层 v1.0.0 readiness evidence — 2026-06-15

## Scope

本证据切片只覆盖 ZoneCNH 总仓的 L2.5 领域共享层文档 / 证据对齐，范围为 `decimalx`、`domainx`、`domain-market`、`domain-macro`、`domain-exchange` 五个模块。它用于说明 v1.0.0 readiness 当前状态和剩余证据门禁，不是 v1.0.0 release announcement，也不是 factory-grade adoption 证明。

主要输入：

- `.omx/context/l25-shared-domain-v100-20260615T062234Z.md`
- `module/{decimalx,domainx,domain-market,domain-macro,domain-exchange}/goal.md`
- `README.md`、`module/README.md`、`STATUS.md`、`ARCHITECTURE.md`、`GLOSSARY.md`

## Current gap

总仓已有 L2.5 v1.0.0 目标、依赖顺序、SPEC / TRACEABILITY / IMPLEMENTATION-PLAN 基线，但此前缺少一个统一的 readiness 证据切片来同时说明：

1. 五个 L2.5 模块的当前版本和目标版本；
2. 哪些内容只是文档 / 计划 / 规格基线；
3. 哪些证据仍必须由各模块仓 worker evidence、CI artifact、git tag 或 GitHub Release 补齐后才能声明 release / factory-grade。

## Readiness matrix

| 模块 | 当前版本（ZoneCNH 口径） | 目标版本 | Readiness state | 下一证据门禁 |
| --- | --- | --- | --- | --- |
| `decimalx` | v0.2.0 | v1.0.0 | 文档 / 执行计划基线已对齐；release 待补证 | API freeze、Money/Currency 所属权确认、精度 / rounding 证据、CI release gate、v1.0.0 tag / GitHub Release |
| `domainx` | v1.0.0 | v1.0.0 | 共享值对象规格基线已对齐；公开 release 证明待补证 | 模块仓 CI artifact、v1.0.0 tag / GitHub Release、adoption gate / factory-grade 证据 |
| `domain-market` | v0.1.0 | v1.0.0 | 文档 / 执行计划基线已对齐；release 待补证 | market model 质量门禁、与 decimalx / domainx API freeze 对齐、CI release gate、v1.0.0 tag / GitHub Release |
| `domain-macro` | v0.1.0 | v1.0.0 | 文档 / 执行计划基线已对齐；release 待补证 | no-lookahead / precision ADR、与 decimalx / domainx API freeze 对齐、CI release gate、v1.0.0 tag / GitHub Release |
| `domain-exchange` | v0.1.0 | v1.0.0 | 文档 / 执行计划基线已对齐；release 待补证 | 上游共享模型冻结、SPI / VenueAdapter CI gate、v1.0.0 tag / GitHub Release |

## Dependency topology

```text
decimalx -> domainx -> domain-market / domain-macro -> domain-exchange
```

该顺序是 v1.0.0 文档 / 执行计划基线的依赖顺序。任何对 L2.5 release / factory-grade 的公开声明，必须在上游 API freeze、下游兼容、CI release gate、外部 CI artifact、git tag / GitHub Release 和 adoption gate 都有证据后再更新。

## ZoneCNH validation checklist

本仓证据切片的验证口径：

- `git diff --check`：Markdown / whitespace patch sanity。
- `.github/ci/glossary-consistency.sh`：术语表与文档口径一致性。
- `.github/ci/status-consistency-check.sh`：README / STATUS / ARCHITECTURE / module docs 基础状态一致性。
- Targeted `rg` checks：确认 L2.5 readiness evidence 链接、`domainx` 归属、`decimalx` v0.2.0 口径和 release / factory-grade 限定语存在。

Go module tests are not required for this ZoneCNH slice unless Go module files are changed in this repository; module repo code validation remains owned by the module workers.

## Stop condition

ZoneCNH 可声明：L2.5 v1.0.0 readiness 文档 / 证据口径已对齐，并明确列出 release / factory-grade 剩余门禁。ZoneCNH 不声明：五个模块均已完成 v1.0.0 release、外部 CI artifact、git tag / GitHub Release 或 production adoption。
