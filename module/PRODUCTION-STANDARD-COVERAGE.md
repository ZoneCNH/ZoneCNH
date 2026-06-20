# Production Standard 覆盖矩阵

> 生成日期：2026-06-19
>
> 范围：`docs/production-standards/` 下 20 个生产标准模块到 `module/` 模块制品的对账。
> 本文件是 `module/` 侧补充索引，不取代 `module/{module}/SPEC.md`、`TRACEABILITY.md` 或 `docs/production-standards/*.md`。

## 口径

- `docs/production-standards/*.md` 是生产标准叙述源；`module/{module}/` 是模块 Goal、Spec、Traceability、Task、Plan、Prompt、Evidence 制品 SSOT；`module/FOUNDATION-DEPS.yaml` 是机器可读依赖边界。
- `Local Complete` 不等于 `Production Accepted`。前者表示本地单元、集成或证据闭环通过；后者还需要 release artifact、外部 CI / security gate、追溯证据、适用阶段的四源 `>=98` 门禁，以及标准要求的 downstream、soak、benchmark 证据。
- `production_import_allowed=false` 或 `factory=false` 在 release / factory 证据完成前必须保持为阻断语义，不能因本地通过而自动翻转。
- `ossx` 当前应按“本地能力完成、生产导入未放行”解释；真 bucket 本地通过不能替代外部 release、安全、下游接入和 soak 证据。

## 覆盖摘要

- 生产标准模块：20 个。
- 20/20 已有 `SPEC.md`、`FEATURES.md`、`ACCEPTANCE.md`、`TRACEABILITY.md`、`goal.md`、`ci-workflow.yaml`。
- 18/20 已有顶层 `IMPLEMENTATION-PLAN.md`；缺口为 `bootstrap`、`testkitx`。
- `contracts/IMPLEMENTATION-PLAN.md` 存在，当前缺口不是计划文件缺失，而是 spec-only 到 release / runtime evidence 的生产闭环尚未形成。
- 主要跨模块缺口集中在版本 / 状态口径漂移、本地证据与生产证据混写、顶层计划缺失、门禁证据映射不足。

## 缺口优先级

### P0

- `clickhousex` 元数据口径需对齐：生产标准写 `Module-Version v1.0.8 (Spec v1.0.1)`，`module/clickhousex/SPEC.md` 写 `Version: v1.0.1`，`ACCEPTANCE.md` 写 `Module-Version: v1.0.8`；应明确“规格版本”和“模块发布版本”双轨，不把它误判为实现回退。
- `xlibgate` trust 组能力仍未完成：`FR-012` 至 `FR-019`、`BR-010`、`NFR-011` 至 `NFR-018` 仍是未实现 / 未验收状态。
- `bootstrap`、`testkitx` 缺顶层 `IMPLEMENTATION-PLAN.md`；其中 `testkitx` 的 `TRACEABILITY.md` 已是通过口径，但 `ACCEPTANCE.md` 摘要仍有 `⬜`，需要统一状态表达。

### P1

- `ossx` 需要补外部 release artifact、Gitleaks / xlibgate、安全扫描、下游接入和 soak 证据，保持本地完成与生产验收分层。
- `postgresx` 需要补 `NFR-001` 至 `NFR-005`、`v1.x` deferred、`BLK-006`、downstream 和 soak 证据。
- `natsx` 需要补 `BLK-002` TLS 生产闭环、benchmark 和四源仲裁证据。
- `transportx` 需要把 `TX-GATE-005` 至 `TX-GATE-012` 落成门禁状态矩阵和证据路径。
- `observex`、`schedulex` 需要补齐自观测 / downstream smoke / `Replace` 映射等标准证据。

### P2

- `redisx`、`kafkax`、`taosx`、`resiliencx`、`configx`、`kernel`、`xlib-*` 需要统一 task -> AC -> TC -> evidence 的命名、证据 ID 和完成语义。
- `xlib_harness` 需要更细粒度地区分本地成熟度、外部 release、安全门禁和兼容性证据；`xlib_evidence` 已在生产标准页闭合 v0.2.4 release、100.0% 覆盖率、release evidence assets 和 Trust Alignment 证据。

## 模块矩阵

| 模块 | 生产标准 | 层 / 边界 | `module/` 覆盖 | 当前信号 | 需补信息 |
| --- | --- | --- | --- | --- | --- |
| `xlib_standard` | [xlib_standard.md](../docs/production-standards/xlib_standard.md) | 标准源；不进入运行时 | 五件套 + 计划齐备 | v1.0.1 已发布，release-preflight 通过 | 校验 `goalcli`、`traceability-check` 和 release evidence 命名一致性。 |
| `xlib_harness` | [xlib_harness.md](../docs/production-standards/xlib_harness.md) | 生成器 / 门禁执行器；不进入运行时 | 五件套 + 计划齐备 | scaffold、spec-lint、boundary-check、traceability-gate 基线已成型 | 补 `FR-003` 边界控制和 `FR-005` 兼容性检查的可执行证据粒度。 |
| `xlib_evidence` | [xlib_evidence.md](../docs/production-standards/xlib_evidence.md) | 证据运行时；不承载业务运行时 | 五件套 + 计划齐备 | collect-coverage / generate-manifest / validate-manifest / remote-evidence / report；v0.2.4 已发布，100.0% 覆盖率与 release evidence assets 已归档 | 本地成熟度、外部 release、安全门禁、兼容性和 Trust Alignment 证据已在生产标准页分层闭合。 |
| `kernel` | [kernel.md](../docs/production-standards/kernel.md) | L0；stdlib-only 根原语 | 五件套 + 计划齐备 | 12 个 root primitive 为上层依赖根 | 补 Goal Matrix closure 和 evidence ID 对齐说明。 |
| `configx` | [configx.md](../docs/production-standards/configx.md) | L1 primitive；只依赖 `kernel` | 五件套 + 计划齐备 | Client / Loader / Source / StrictDecode / SecretString 基线完整 | `Watch` / `TASK-CONFIGX-007` deferred 需要保持阻断语义与 proof boundary。 |
| `observex` | [observex.md](../docs/production-standards/observex.md) | L1 primitive；只依赖 `kernel` | 五件套 + 计划齐备 | Logger / Meter / Tracer / Exporter / Redaction 基线完整 | 补 self-observation 指标、CI 证据和 redaction 回归证据。 |
| `testkitx` | [testkitx.md](../docs/production-standards/testkitx.md) | L1 test-only；禁止生产导入 | 缺顶层 `IMPLEMENTATION-PLAN.md`，其余制品齐备 | 2026-06-18 证据显示 build / vet / test / race 通过，覆盖率 92.6% | 新增顶层计划；统一 `ACCEPTANCE.md` 摘要 `⬜` 与 `TRACEABILITY.md` 通过口径；继续保持 no-production-import。 |
| `resiliencx` | [resiliencx.md](../docs/production-standards/resiliencx.md) | L1 primitive；只依赖 `kernel` | 五件套 + 计划齐备 | v1.0.2 已发布，Timeout / Retry / CircuitBreaker / Bulkhead 等能力成型 | 补 `retry.Policy{MaxAttempts:0}`、`bulkhead.New(0)` 等边界测试和历史 downgrade 文案修正证据。 |
| `schedulex` | [schedulex.md](../docs/production-standards/schedulex.md) | L1 primitive；只依赖 `kernel` | 五件套 + 计划齐备 | v1.0.1，Scheduler / Trigger / Policy / Clock 基线完整 | 补 downstream smoke 和 `Replace` 映射证据。 |
| `xlibgate` | [xlibgate.md](../docs/production-standards/xlibgate.md) | CI gate；不进入运行时 | 五件套 + 计划齐备 | imports / gomod / baseline / release / l2 门禁已有基线 | 实现并验收 trust 组 `FR-012` 至 `FR-019`、`BR-010`、`NFR-011` 至 `NFR-018`。 |
| `redisx` | [redisx.md](../docs/production-standards/redisx.md) | L2 storage；生产依赖限定 `kernel` + Redis 客户端 | 五件套 + 计划齐备 | v1.1.0 已发布，release workflow 与 dev Redis 集成验证通过 | 补 task -> AC -> TC -> evidence 的细粒度映射。 |
| `kafkax` | [kafkax.md](../docs/production-standards/kafkax.md) | L2 storage；生产依赖限定 `kernel` + Kafka 客户端 | 五件套 + 计划齐备 | Kafka producer / consumer / health / metrics 规格基线存在 | 统一 blocker、integration skip 语义和 evidence ID。 |
| `natsx` | [natsx.md](../docs/production-standards/natsx.md) | L2 storage / messaging；生产依赖限定 `kernel` + NATS 客户端 | 五件套 + 计划齐备 | v1.0.0 已发布，dev auth live gate 已验证；非 factory | 关闭 `BLK-002` TLS 生产 gate，补 benchmark 与四源 `98+` 仲裁证据。 |
| `postgresx` | [postgresx.md](../docs/production-standards/postgresx.md) | L2 storage；生产依赖限定 `kernel` + PostgreSQL 客户端 | 五件套 + 计划齐备 | v1.0.0 已发布，release-final-check 与 live integration 通过；非 factory | 补 `NFR-001` 至 `NFR-005`、`BLK-006`、downstream、soak 和 v1.x deferred 证据。 |
| `taosx` | [taosx.md](../docs/production-standards/taosx.md) | L2 storage；生产依赖限定 `kernel` + TDengine 客户端 | 五件套 + 计划齐备 | v1.0.3 本地发布候选，覆盖率 100%，TDengine dev live gate 通过 | 补外部 tag / GitHub Release、factory、soak 和 release artifact 证据。 |
| `ossx` | [ossx.md](../docs/production-standards/ossx.md) | L2 storage；生产依赖限定 `kernel` + Aliyun OSS 客户端 | 五件套 + 计划齐备 | v1.2.0 本地单元 + 5 个真 bucket 集成通过，覆盖率 100%；非 factory | 补外部 CI / security、release artifact / archive、downstream、soak；继续显式区分 local complete 与 production accepted。 |
| `clickhousex` | [clickhousex.md](../docs/production-standards/clickhousex.md) | L2 storage；生产依赖限定 `kernel` + ClickHouse 客户端 | 五件套 + 计划齐备 | v1.0.8 GitHub Release 已发布，quality / lint / integration / secret-scan / trust / release-check 通过 | 对齐 Spec-Version v1.0.1 与 Module-Version v1.0.8 口径；补 multi-hour soak、external rollout、100000-row 和 complex benchmark 证据。 |
| `contracts` | [contracts.md](../docs/production-standards/contracts.md) | L5 contracts；无生产依赖 | 五件套 + 计划齐备 | spec-only，无公开 GitHub Release / git tag 对齐；非 factory | 补 runtime evidence、contract governance gate、release / tag 和生产导入前置证据。 |
| `transportx` | [transportx.md](../docs/production-standards/transportx.md) | L6 transport；依赖 `contracts`、`configx`、`observex`、`resiliencx` | 五件套 + 计划齐备 | spec-only；`production_import_allowed=false`；非 factory | 建立 `TX-GATE-005` 至 `TX-GATE-012` 状态矩阵和证据路径；release / tag 前不得放行生产导入。 |
| `bootstrap` | [bootstrap.md](../docs/production-standards/bootstrap.md) | L1 Assembly 特例；可组合 L0 / L1 primitives 与受控 L2 adapter | 缺顶层 `IMPLEMENTATION-PLAN.md`，其余制品齐备 | `SPEC.md` 仍为 Draft；runtime v0.1.0；边界门禁有一次通过记录 | 新增顶层计划；显式保留 Draft、import gate blocker、`foundationx` OQ-004 与边界 / runtime evidence 重归档要求。 |

## 下一轮补齐队列

1. 先补 `bootstrap`、`testkitx` 的顶层 `IMPLEMENTATION-PLAN.md`，并同步 `testkitx` 验收摘要状态。
2. 对齐 `clickhousex` 的规格版本与模块发布版本双轨表达，避免把 release v1.0.8 与 spec v1.0.1 混写成冲突。
3. 为 `xlibgate` trust 组建立任务与验收证据闭环。
4. 为 `transportx` 建立 `TX-GATE-005` 至 `TX-GATE-012` 的门禁状态矩阵。
5. 对 `ossx`、`postgresx`、`natsx`、`taosx` 补外部生产证据，不用本地通过替代 release / security / downstream / soak。

## 停止条件

本矩阵的完成条件是：20 个生产标准模块均有 `module/` 行；每个 P0 缺口都有可执行下一步；本地完成与生产验收的证据口径被显式区分。
