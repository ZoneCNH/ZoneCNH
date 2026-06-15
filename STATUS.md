# 📊 项目状态监控

> FoundationX 量化交易基础设施的实时健康度与风险追踪
>
> 数据来源：各 GitHub 仓库实际状态，定期更新
>
> 最后更新：2026-06-15
>
> 同步基线：`module/` 为模块规格库 SSOT，`docs/governance/` 为 Spec 治理 SSOT，`docs/goal/` 为 Goal 规则 SSOT，`specs/` 已移除。
> 机器事实源：`.foundationx/status/index.json` — 由 `xlibgate fleet-status` 生成，供 CI 和自动投影消费。多维成熟度以该文件为准，本文手工块为投影。

---

## 组件明细表

### 基座

| 组件                                                      | 版本        | 阶段投影               | 门禁口径        | 子维度投影                                       | 说明                                                                                                                                                                                                |
| --------------------------------------------------------- | ----------- | ---------------------- | --------------- | ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [xlib-standard](https://github.com/ZoneCNH/xlib-standard) | v1.0.0      | spec/code/release      | factory-ready   | spec=100 mat=98 tsk=100 pln=100 prm=100 cod=100  | 标准事实源 / Go Reference Template；Generator/Harness/Evidence 已拆分至 xlib-harness / xlib-evidence；✅ .repo-contract.yaml (is_standard_source)；✅ GitHub Release v1.0.0 已发布                  |
| [xlib-harness](https://github.com/ZoneCNH/xlib-harness)   | -           | spec/code              | release-pending | spec=98 mat=100 tsk=98 pln=100 prm=100 cod=100   | 模块生成器与门禁执行器：generate/scaffold、spec-lint、boundary-check、traceability-gate；✅ CI 已部署；⚠️ git tag + GitHub Release 缺失                                                             |
| [xlib-evidence](https://github.com/ZoneCNH/xlib-evidence) | -           | spec/code              | release-pending | spec=98 mat=100 tsk=100 pln=100 prm=100 cod=100  | 证据收集与发布运行时：collect-coverage、generate-manifest、validate-manifest、report；✅ CI 已部署；⚠️ git tag + GitHub Release 缺失                                                                |
| [xlibgate](https://github.com/ZoneCNH/xlibgate)           | v1.0.0      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | check/l2/trust 三组门禁；✅ .repo-contract.yaml，v1.0.0 已对齐（此前误标 v1.1.1）；trust CLI 已实现                                                                                                 |
| [kernel](https://github.com/ZoneCNH/kernel)               | v1.0.0      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | L0 原语 / 12 子包 / stdlib-only；✅ .repo-contract.yaml，v1.0.0 已对齐，建议 API 冻结                                                                                                               |
| [configx](https://github.com/ZoneCNH/configx)             | v1.0.0      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 配置管理；✅ v1.0.0 GitHub Release 已发布；此前误标 v0.1.4 已修正；✅ .repo-contract.yaml                                                                                                           |
| [observex](https://github.com/ZoneCNH/observex)           | v0.3.1      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 可观测性；✅ v0.3.1 GitHub Release 已发布；此前误标 v1.0.0 已修正                                                                                                                                   |
| [testkitx](https://github.com/ZoneCNH/testkitx)           | v0.4.0      | spec/code/release      | test-only       | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Fake / Fixture / Golden / Contract / Leak / Boundary / Manifest 测试工具包；✅ v0.4.0 GitHub Release 已发布；test-only；factory grade 不适用                                                        |
| [resiliencx](https://github.com/ZoneCNH/resiliencx)       | v0.4.9      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 弹性策略（timeout / retry / circuit / bulkhead / rate / fallback）；✅ v0.4.9 GitHub Release 已发布；此前误标 v1.0.1 已修正                                                                         |
| [schedulex](https://github.com/ZoneCNH/schedulex)         | v1.0.0      | spec/code/release      | factory-ready   | spec=98 mat=100 tsk=100 pln=100 prm=100 cod=100  | cron/interval/delay 调度；✅ .repo-contract.yaml，v1.0.0 已对齐；98.2% 覆盖，下游 smoke 通过                                                                                                        |
| [redisx](https://github.com/ZoneCNH/redisx)               | v1.0.1      | spec/code/release/live | live-ready      | spec=98 mat=100 tsk=100 pln=100 prm=100 cod=100  | Redis L2 adapter；✅ .repo-contract.yaml，v1.0.1；此前误标 v1.0.0（tag 超前于表格）；Docker-backed Redis 验证通过                                                                                   |
| [kafkax](https://github.com/ZoneCNH/kafkax)               | v1.0.2      | spec/code/release/live | live-ready      | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Kafka L2 adapter；✅ .repo-contract.yaml，v1.0.2；此前误标 v1.0.0（tag 超前于表格）；真实 broker gates 已验证                                                                                       |
| [natsx](https://github.com/ZoneCNH/natsx)                 | v1.0.0      | spec/code/release/live | factory-blocked | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | NATS L2 adapter；✅ .repo-contract.yaml；真实 dev auth live gate 已验证；正式四源 98+ arbiter 与生产 TLS gate 未闭合（BLK-001/BLK-002）；非 factory                                                 |
| [postgresx](https://github.com/ZoneCNH/postgresx)         | v1.0.0      | spec/code/release/live | factory-blocked | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | PostgreSQL；✅ .repo-contract.yaml；live integration 通过；单元测试 52.4% + Docker integration skip（BLK-006）；非 factory                                                                          |
| [taosx](https://github.com/ZoneCNH/taosx)                 | v1.0.1      | spec/code/release/live | factory-blocked | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | TDengine L2 adapter；真实 taosWS WebSocket 集成已验证；SPEC 评分 67（BLK-007）；非 factory until blocker closed                                                                                     |
| [ossx](https://github.com/ZoneCNH/ossx)                   | v1.0.1      | spec/code/release/live | factory-blocked | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Aliyun OSS L2 adapter；✅ .repo-contract.yaml，v1.0.1 已对齐；race/vet/build/release-check 已通过；BLK-008 open：API 文档 / integration evidence / quickstart / release manifest 未归档；非 factory |
| [clickhousex](https://github.com/ZoneCNH/clickhousex)     | v1.0.1      | spec/code/live         | release-blocked | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | ClickHouse；SPEC+TRACEABILITY+TASKS 完成；公开 GitHub Release 未发布（BLK-003）；RELEASE pending；非 factory                                                                                        |
| [contracts](https://github.com/ZoneCNH/contracts)         | v1.0.1-spec | spec/code              | release-pending | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 跨域稳定端口/事件/DTO 契约；spec-only；无公开 GitHub Release / git tag 对齐；非 factory until release                                                                                               |
| [transportx](https://github.com/ZoneCNH/transportx)       | v1.1.1-spec | spec/code              | release-pending | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 应用通信底座规格基线；spec-only；无公开 GitHub Release / git tag 对齐；production_import_allowed=false；非 factory until release                                                                    |

> ⚠️ **版本 / release 注记**：公开文档是投影层；版本、release 与 factory 状态以 `.foundationx/status/index.json` + `.foundationx/blockers.json` 为准。当前 20-module projection 中 15/20 已发布 GitHub Release（19 个 Foundation 组件 + L2.5 `domainx` 事实层投影）；L2.5 全部 5 模块（decimalx/domainx/domain-market/domain-macro/domain-exchange）已在各自仓库发布 v1.0.0+ release；公开投影仍有 BLK-001/002/003/006/007/008 open，不声明 Foundation 整体 factory grade。

> **成熟度语义说明（2026-06-14 v2 Trust Alignment）**：上表"进度"反映本仓库 Spec 管线评分（spec→code），不代表可投产等级（factory grade）。下表提供多维度成熟度视图；RELEASE=❌ 或存在 open blocker 的模块不得投影为 FACTORY=✅。

<details>
<summary>📊 基座多维成熟度展开（点击展开）</summary>

| 模块                          |     SPEC      |               IMPL                |             RELEASE              |        LIVE INT         |         EXT CI         |            ADOPT            |                     SOAK                      | FACTORY | 备注                                                                                                                                                       |
| ----------------------------- | :-----------: | :-------------------------------: | :------------------------------: | :---------------------: | :--------------------: | :-------------------------: | :-------------------------------------------: | :-----: | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| xlib-standard                 |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.0; GitHub Release 已发布; 9 CI workflows                                                                                                              |
| xlib-harness                  |      ✅       |                ✅                 |                ❌                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ❌    | CI 已部署; generate/scaffold/spec-lint/boundary/traceability; ⚠️ git tag + GitHub Release 缺失                                                             |
| xlib-evidence                 |      ✅       |                ✅                 |                ❌                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ❌    | CI 已部署; evidence collect/generate/validate/report; ⚠️ git tag + GitHub Release 缺失                                                                     |
| xlibgate                      |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.0; CI 已部署; 8 workflows; 此前误标 v1.1.1                                                                                                            |
| kernel                        |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v1.0.0; 4 CI workflows; 13 下游消费者; API 冻结建议                                                                                                        |
| configx                       |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v1.0.0; GitHub Release 已发布; 4 CI workflows; 2 下游消费者; 此前误标 v0.1.4 已修正                                                                        |
| observex                      |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v0.3.1; GitHub Release 已发布; 4 CI workflows; 2 下游消费者; 此前误标 v1.0.0 已修正                                                                        |
| testkitx                      |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   N/A   | v0.4.0; GitHub Release 已发布; 4 CI workflows; test-only — factory grade 不适用                                                                            |
| resiliencx                    |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v0.4.9; GitHub Release 已发布; 9 CI workflows; 2 下游消费者; 此前误标 v1.0.1 已修正                                                                        |
| schedulex                     |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v1.0.0; 6 CI workflows; 下游 smoke 通过; 1 下游消费者                                                                                                      |
| redisx                        |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.1; 9 CI workflows; Docker-backed Redis 验证通过                                                                                                       |
| kafkax                        |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.2; 8 CI workflows; 真实 broker gates 已验证                                                                                                           |
| natsx                         |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ❌    | v1.0.0; 6 CI workflows; dev auth live gate 已验证; BLK-001/BLK-002 open; 非 factory                                                                        |
| postgresx                     |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ❌    | v1.0.0; 3 CI workflows; live integration 通过; BLK-006 open（52.4% coverage + Docker integration skip）; 非 factory                                        |
| taosx                         |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ❌    | v1.0.1; 8 CI workflows; 真实 taosWS 已验证; BLK-007 open（SPEC 67）; 非 factory                                                                            |
| ossx                          |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ❌    | v1.0.1; CI 已部署; 真实 Aliyun OSS 集成已验证; BLK-008 open（API 文档 / integration evidence / quickstart / release manifest 未归档）; 非 factory          |
| clickhousex                   |      ✅       |                ✅                 |                ❌                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ❌    | v1.0.1; CI 已部署+运行(Docker ClickHouse); 公开 GitHub Release 未发布（BLK-003）; 非 factory                                                               |
| contracts                     |      ✅       |                ✅                 |                ❌                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ❌    | v1.0.1-spec; spec-only; 无公开 GitHub Release / git tag 对齐; all_aligned=false                                                                            |
| transportx                    |      ✅       |                ✅                 |                ❌                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ❌    | v1.1.1-spec; spec-only; 无公开 GitHub Release / git tag 对齐; production_import_allowed=false                                                              |
| domainx                       |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.1; L2.5 领域共享层; 公开 GitHub Release/tag v1.0.1 已观测并完成 fact-layer/trust release 对账; factory grade；live/soak N/A（纯值对象库） |
| > **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级） |

> **数据来源**：本表依据 `module/` 规格状态、`.foundationx/status/index.json`、`.foundationx/blockers.json`、公开 GitHub release 页面、GitHub Actions CI 运行状态与 FOUNDATION-DEPS.yaml 反向依赖图（ADOPT）投影。Open blocker 会下调 FACTORY 投影。
>
> **CI 构建状态**（最新 run，2026-06-15）：✅ 全部 20 模块已配置 CI workflows | Trust Alignment 5 模块本次部署: xlib-harness / xlib-evidence / ossx / clickhousex / domainx
>
> **管线评分注记**：上表 `pln/prm/cod` 列对外仓模块为 pass-through（未实际在目标 repo 运行验证），100 分仅表示 plan/prompt 文档模板完整，不代表代码可编译或已通过测试。CI 构建状态为此处补充机械证据。

</details>

### L2.5 · 领域共享层（5 个）

| 组件                                                          | 版本   | 进度     | 覆盖率要求 | 说明                                                                                                                                                        |
| ------------------------------------------------------------- | ------ | -------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [decimalx](https://github.com/ZoneCNH/decimalx)               | v1.0.0 | ████ 100% | 100%       | 高精度十进制类型；v1.0.0 GitHub Release 已发布，8 FR Done；factory grade；live/soak N/A（纯值对象库）                                                                   |
| [domainx](https://github.com/ZoneCNH/domainx)                 | v1.0.1 | ████ 100% | 100%       | 领域共享值对象：Order / Position / Trade / Portfolio / ExecutionReport；公开 v1.0.1 release/tag 已观测并完成 trust 对账；factory grade；live/soak N/A（纯值对象库） |
| [domain-market](https://github.com/ZoneCNH/domain-market)     | v1.0.0 | ████ 100% | 100%       | 市场数据域模型；v1.0.0 GitHub Release 已发布，7 FR Done；factory grade；live/soak N/A（纯值对象库）                                                                       |
| [domain-macro](https://github.com/ZoneCNH/domain-macro)       | v1.0.0 | ████ 100% | 100%       | 宏观数据域模型；v1.0.0 GitHub Release 已发布，7 FR Done；factory grade；live/soak N/A（纯值对象库）                                                                       |
| [domain-exchange](https://github.com/ZoneCNH/domain-exchange) | v1.0.0 | ████ 100% | 100%       | 交易域模型；v1.0.0 GitHub Release 已发布，7 FR Done；factory grade；live/soak N/A（纯值对象库）                                                                           |

<details>
<summary>📊 L2.5 领域共享层多维成熟度展开（点击展开）</summary>

| 模块            | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                                                                                                                                                             |
| --------------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| decimalx        |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ✅    | v1.0.0；100%；v1.0.0 GitHub Release 已发布，8 FR Done；factory grade；live/soak N/A（纯值对象库）                                                          |
| domainx         |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ✅    | v1.0.1；100%；领域共享值对象：Order/Position/Trade/Portfolio/ExecutionReport；公开 v1.0.1 release/tag 已观测并完成 trust 对账；factory grade；live/soak N/A（纯值对象库） |
| domain-market   |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ✅    | v1.0.0；100%；v1.0.0 GitHub Release 已发布，7 FR Done；factory grade；live/soak N/A（纯值对象库）                                                          |
| domain-macro    |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ✅    | v1.0.0；100%；v1.0.0 GitHub Release 已发布，7 FR Done；factory grade；live/soak N/A（纯值对象库）                                                          |
| domain-exchange |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ✅    | v1.0.0；100%；v1.0.0 GitHub Release 已发布，7 FR Done；factory grade；live/soak N/A（纯值对象库）                                                          |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 数据域 · 行情

| 组件                                                          | 类型     | 版本   | 进度     | 覆盖率要求 | 说明                  |
| ------------------------------------------------------------- | -------- | ------ | -------- | ---------- | --------------------- |
| [binance](https://github.com/ZoneCNH/binance)                 | SDK      | -      | ███░ 80% | 100%       | Binance CEX           |
| [okx](https://github.com/ZoneCNH/okx)                         | SDK      | -      | ███░ 80% | 100%       | OKX CEX               |
| [bybit](https://github.com/ZoneCNH/bybit)                     | SDK      | -      | ███░ 80% | 100%       | Bybit CEX             |
| [bitget](https://github.com/ZoneCNH/bitget)                   | SDK      | -      | ███░ 80% | 100%       | Bitget CEX            |
| [kucoin](https://github.com/ZoneCNH/kucoin)                   | SDK      | -      | ███░ 80% | 100%       | KuCoin CEX            |
| [gate](https://github.com/ZoneCNH/gate)                       | SDK      | -      | ███░ 80% | 100%       | Gate CEX              |
| [mexc](https://github.com/ZoneCNH/mexc)                       | SDK      | -      | ███░ 80% | 100%       | MEXC CEX              |
| [htx](https://github.com/ZoneCNH/htx)                         | SDK      | -      | ███░ 80% | 100%       | HTX CEX               |
| [coinbase](https://github.com/ZoneCNH/coinbase)               | SDK      | -      | ███░ 80% | 100%       | Coinbase CEX          |
| [hyperliquid](https://github.com/ZoneCNH/hyperliquid)         | SDK      | -      | ███░ 80% | 100%       | Hyperliquid DEX       |
| [lighter](https://github.com/ZoneCNH/lighter)                 | SDK      | -      | ███░ 80% | 100%       | Lighter DEX           |
| [upbit](https://github.com/ZoneCNH/upbit)                     | SDK      | -      | ███░ 80% | 100%       | Upbit CEX             |
| [coinglass](https://github.com/ZoneCNH/coinglass)             | SDK      | -      | ███░ 80% | 100%       | 衍生品聚合数据        |
| [binance-market](https://github.com/ZoneCNH/binance-market)   | Provider | v0.1.0 | ███░ 80% | 100%       | Binance Kline/Ticker  |
| [bybit-market](https://github.com/ZoneCNH/bybit-market)       | Provider | v0.1.0 | ███░ 80% | 100%       | Bybit Kline/Ticker    |
| [bitget-market](https://github.com/ZoneCNH/bitget-market)     | Provider | v0.1.0 | ███░ 80% | 100%       | Bitget Kline/Ticker   |
| [okx-market](https://github.com/ZoneCNH/okx-market)           | Provider | v0.1.0 | ███░ 80% | 100%       | OKX Kline/Ticker      |
| [coinbase-market](https://github.com/ZoneCNH/coinbase-market) | Provider | v0.1.0 | ███░ 80% | 100%       | Coinbase Kline/Ticker |

<details>
<summary>📊 数据域 · 行情多维成熟度展开（点击展开）</summary>

| 模块            | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                               |
| --------------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | ---------------------------------- |
| binance         |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Binance CEX              |
| okx             |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；OKX CEX                  |
| bybit           |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Bybit CEX                |
| bitget          |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Bitget CEX               |
| kucoin          |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；KuCoin CEX               |
| gate            |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Gate CEX                 |
| mexc            |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；MEXC CEX                 |
| htx             |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；HTX CEX                  |
| coinbase        |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Coinbase CEX             |
| hyperliquid     |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Hyperliquid DEX          |
| lighter         |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Lighter DEX              |
| upbit           |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Upbit CEX                |
| coinglass       |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；衍生品聚合数据           |
| binance-market  |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | Provider v0.1.0；80%；Kline/Ticker |
| bybit-market    |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | Provider v0.1.0；80%；Kline/Ticker |
| bitget-market   |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | Provider v0.1.0；80%；Kline/Ticker |
| okx-market      |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | Provider v0.1.0；80%；Kline/Ticker |
| coinbase-market |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | Provider v0.1.0；80%；Kline/Ticker |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 数据域 · 宏观

| 组件                                                  | 版本 | 进度     | 覆盖率要求 | 说明           |
| ----------------------------------------------------- | ---- | -------- | ---------- | -------------- |
| [fred](https://github.com/ZoneCNH/fred)               | -    | ███░ 80% | 100%       | 美联储 FRED    |
| [treasury](https://github.com/ZoneCNH/treasury)       | -    | ███░ 80% | 100%       | 美国财政部     |
| [yield-curve](https://github.com/ZoneCNH/yield-curve) | -    | ███░ 80% | 100%       | 收益率曲线     |
| [bea](https://github.com/ZoneCNH/bea)                 | -    | ███░ 80% | 100%       | 美国经济分析局 |
| [ecb](https://github.com/ZoneCNH/ecb)                 | -    | ███░ 80% | 100%       | 欧洲央行       |
| [uk-cb](https://github.com/ZoneCNH/uk-cb)             | -    | ███░ 80% | 100%       | 英国央行       |
| [japan-cb](https://github.com/ZoneCNH/japan-cb)       | -    | ███░ 80% | 100%       | 日本央行       |
| [eastmoney](https://github.com/ZoneCNH/eastmoney)     | -    | ███░ 80% | 100%       | 东方财富 A 股  |
| [jinshi](https://github.com/ZoneCNH/jinshi)           | -    | ███░ 80% | 100%       | 金十快讯       |
| [jin10](https://github.com/ZoneCNH/jin10)             | -    | ███░ 80% | 100%       | 金十行情       |
| [yahoo](https://github.com/ZoneCNH/yahoo)             | -    | ███░ 80% | 100%       | Yahoo Finance  |

<details>
<summary>📊 数据域 · 宏观多维成熟度展开（点击展开）</summary>

| 模块        | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                  |
| ----------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | --------------------- |
| fred        |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；美联储 FRED 数据 |
| treasury    |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；美国财政部数据   |
| yield-curve |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；收益率曲线       |
| bea         |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；美国经济分析局   |
| ecb         |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；欧洲央行         |
| uk-cb       |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；英国央行         |
| japan-cb    |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；日本央行         |
| eastmoney   |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；东方财富 A 股    |
| jinshi      |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；金十快讯         |
| jin10       |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；金十行情         |
| yahoo       |  ✅  |  ✅  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；Yahoo Finance    |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 数据域 · 另类

| 组件                                                            | 版本 | 进度    | 覆盖率要求 | 说明                     |
| --------------------------------------------------------------- | ---- | ------- | ---------- | ------------------------ |
| [alternative-data](https://github.com/ZoneCNH/alternative-data) | -    | ░░░░ 5% | 100%       | 链上、社交情绪、新闻 NLP |

<details>
<summary>📊 数据域 · 另类多维成熟度展开（点击展开）</summary>

| 模块             | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                                      |
| ---------------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | ----------------------------------------- |
| alternative-data |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；链上数据、社交情绪、新闻 NLP 均未开始 |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 分析域

| 组件                                                      | 版本         | 进度     | 覆盖率要求 | 说明                                                                     |
| --------------------------------------------------------- | ------------ | -------- | ---------- | ------------------------------------------------------------------------ |
| [factor-engine](https://github.com/ZoneCNH/factor-engine) | -            | ░░░░ 5%  | 100%       | 因子计算引擎                                                             |
| [feature-store](https://github.com/ZoneCNH/feature-store) | -            | ░░░░ 5%  | 100%       | 特征存储与版本管理                                                       |
| [factor-eval](https://github.com/ZoneCNH/factor-eval)     | -            | ░░░░ 5%  | 100%       | 因子评估                                                                 |
| [market_regime](https://github.com/ZoneCNH/market_regime) | -            | ░░░░ 5%  | 100%       | 市场状态识别                                                             |
| [macro_regime](https://github.com/ZoneCNH/macro_regime)   | -            | ░░░░ 5%  | 100%       | 宏观经济体制识别（M1-M7）                                                |
| [ms_brain](https://github.com/ZoneCNH/ms_brain)           | -            | ░░░░ 5%  | 100%       | M×S 系统架构分析体系                                                     |
| [regime-engine](https://github.com/ZoneCNH/regime-engine) | v0.1.0       | ██░░ 25% | 100%       | M×S 联合决策引擎（M+S → action/risk/permission），骨架完成，30+ 测试通过 |
| [flowx](https://github.com/ZoneCNH/flowx)                 | v0.1.0-draft | ░░░░ 5%  | 100%       | 数据流管线引擎 — 流式 ETL、窗口聚合、背压控制（7 FR, SPEC draft）        |

<details>
<summary>📊 分析域多维成熟度展开（点击展开）</summary>

| 模块          | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                               |
| ------------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | ---------------------------------- |
| factor-engine |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现                 |
| feature-store |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现                 |
| factor-eval   |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现                 |
| market_regime |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现                 |
| macro_regime  |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现                 |
| ms_brain      |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现                 |
| regime-engine |  ❌  |  ⚠️  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0；25% 骨架完成，30+ 测试通过 |
| flowx         |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0-draft；7 FR，SPEC draft     |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 决策域

| 组件                                                          | 版本         | 进度    | 覆盖率要求 | 说明                                                                |
| ------------------------------------------------------------- | ------------ | ------- | ---------- | ------------------------------------------------------------------- |
| [signal-factory](https://github.com/ZoneCNH/signal-factory)   | -            | ░░░░ 5% | 100%       | 信号生成与组合                                                      |
| [backtest-engine](https://github.com/ZoneCNH/backtest-engine) | -            | ░░░░ 5% | 100%       | 事件驱动回测                                                        |
| [optimizer](https://github.com/ZoneCNH/optimizer)             | -            | ░░░░ 5% | 100%       | 参数优化                                                            |
| [backtestx](https://github.com/ZoneCNH/backtestx)             | v0.1.0-draft | ░░░░ 5% | 100%       | 回测引擎 — 事件驱动回测、Walk-Forward、蒙特卡洛（7 FR, SPEC draft） |
| [strategyx](https://github.com/ZoneCNH/strategyx)             | v0.1.0-draft | ░░░░ 5% | 100%       | 策略工厂 — 策略注册、参数管理、信号组合（7 FR, SPEC draft）         |
| [maestro](https://github.com/ZoneCNH/maestro)                 | v0.1.0-draft | ░░░░ 5% | 100%       | 工作流编排引擎 — DAG 工作流、状态机、错误恢复（9 FR, SPEC draft）   |

<details>
<summary>📊 决策域多维成熟度展开（点击展开）</summary>

| 模块            | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                           |
| --------------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | ------------------------------ |
| signal-factory  |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现             |
| backtest-engine |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现             |
| optimizer       |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现             |
| backtestx       |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0-draft；7 FR，SPEC draft |
| strategyx       |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0-draft；7 FR，SPEC draft |
| maestro         |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0-draft；9 FR，SPEC draft |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 执行域

| 组件                                                            | 版本         | 进度    | 覆盖率要求 | 说明                                                         |
| --------------------------------------------------------------- | ------------ | ------- | ---------- | ------------------------------------------------------------ |
| [risk-engine](https://github.com/ZoneCNH/risk-engine)           | -            | ░░░░ 5% | 100%       | 风险管理引擎                                                 |
| [order-engine](https://github.com/ZoneCNH/order-engine)         | -            | ░░░░ 5% | 100%       | 订单执行引擎                                                 |
| [portfolio-engine](https://github.com/ZoneCNH/portfolio-engine) | -            | ░░░░ 5% | 100%       | 投资组合管理                                                 |
| [settlement](https://github.com/ZoneCNH/settlement)             | -            | ░░░░ 5% | 100%       | 结算与对账                                                   |
| [riskx](https://github.com/ZoneCNH/riskx)                       | v0.1.0-draft | ░░░░ 5% | 100%       | 风控引擎 — 事前风控、回撤控制、熔断机制（7 FR, SPEC draft）  |
| [orderx](https://github.com/ZoneCNH/orderx)                     | v0.1.0-draft | ░░░░ 5% | 100%       | 订单管理器 — 订单生命周期、SOR、状态机（7 FR, SPEC draft）   |
| [positionx](https://github.com/ZoneCNH/positionx)               | v0.1.0-draft | ░░░░ 5% | 100%       | 仓位管理器 — 实时仓位追踪、PnL、敞口监控（7 FR, SPEC draft） |

<details>
<summary>📊 执行域多维成熟度展开（点击展开）</summary>

| 模块             | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                           |
| ---------------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | ------------------------------ |
| risk-engine      |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现             |
| order-engine     |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现             |
| portfolio-engine |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现             |
| settlement       |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现             |
| riskx            |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0-draft；7 FR，SPEC draft |
| orderx           |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0-draft；7 FR，SPEC draft |
| positionx        |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0-draft；7 FR，SPEC draft |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 入口 · 横切 · Rust

| 组件                                              | 域   | 版本   | 进度                            | 覆盖率要求 | 说明                                                      |
| ------------------------------------------------- | ---- | ------ | ------------------------------- | ---------- | --------------------------------------------------------- |
| [x.go](https://github.com/ZoneCNH/x.go)           | 入口 | v0.0.1 | ███░ 80%                        | 100%       | 组合根，2.8MB/33 项                                       |
| [alertx](https://github.com/ZoneCNH/alertx)       | 横切 | -      | ░░░░ 5%                         | 100%       | 告警引擎                                                  |
| [observex](https://github.com/ZoneCNH/observex)   | 横切 | v0.3.1 | 全管线 --force pass (spec→code) | 100%       | 可观测性（同时归属基座）；✅ v0.3.1 GitHub Release 已发布 |
| [stdlib.rs](https://github.com/ZoneCNH/stdlib.rs) | Rust | -      | -                               | 100%       | Rust 标准库                                               |
| [module](./module/README.md)                      | 独立 | -      | -                               | 100%       | 项目技术规范与接口定义                                    |

---

## 总览仪表盘

```text
组件总数: 80    已有: 58    已创建: 29    平均进度: 62%

进度分布:
  ███░ ≥80% ██████████████████████████████████████████████  55 个 (68%)
  █░░░ 25%  ░                                                 1 个 ( 1%)
  ░░░░  5%  ████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  22 个 (28%)
  未标注    ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   2 个 ( 3%)

版本覆盖: 有版本号 37 个 (46%)    无版本号 43 个 (54%)
```

### 按域统计

| 域                     | 总数   | 已有   | 已创建 | 平均进度                           | 有版本号                                              |
| ---------------------- | ------ | ------ | ------ | ---------------------------------- | ----------------------------------------------------- |
| 基座                   | 19     | 19     | 0      | Spec→Code 投影完成；factory 未闭合 | 17                                                    |
| L2.5 领域共享层        | 5      | 5      | 5      | 100%                               | 5 (全部 5/5 factory grade；live/soak N/A)            |
| 数据域 · 行情 SDK      | 13     | 13     | 0      | 80%                                | 0                                                     |
| 数据域 · 行情 Provider | 5      | 5      | 0      | 80%                                | 5 (全部)                                              |
| 数据域 · 宏观          | 11     | 11     | 0      | 80%                                | 0                                                     |
| 数据域 · 另类          | 1      | 0      | 1      | 5%                                 | 0                                                     |
| 分析域                 | 8      | 1      | 7      | 8%                                 | 2 (regime-engine, flowx)                              |
| 决策域                 | 6      | 0      | 6      | 5%                                 | 3 (backtestx, strategyx, maestro)                     |
| 执行域                 | 7      | 0      | 7      | 5%                                 | 3 (riskx, orderx, positionx)                          |
| 入口                   | 1      | 1      | 0      | 80%                                | 1 (x.go)                                              |
| 横切                   | 2      | 1      | 1      | 53%                                | 1 (observex)                                          |
| Rust                   | 1      | 1      | 0      | -                                  | 0                                                     |
| 独立                   | 1      | 1      | 0      | -                                  | 0                                                     |
| **合计**               | **80** | **58** | **29** | **62%**                            | **37**                                                |

---

## 域健康度

### 🟢 基座（健康）

- 组件：19 个（不含 L2.5；机器事实层另将 `domainx` 作为 L2.5 模块计入 20-module projection）；
  Spec→Code 管线投影已闭合，但不等于 Foundation 整体 factory grade。
- 核心模块的 release/factory 投影以 `.foundationx/status/index.json` + `.foundationx/blockers.json` 为准；当前 BLK-001/BLK-002/BLK-003/BLK-006/BLK-007/BLK-008 open，因此不得声明 Foundation 单一 100% 或 factory-grade。
- 存储层 `redisx` v1.0.1（Docker-backed Redis + persistence restart recovery 验证），`kafkax` v1.0.2（真实 broker gates 已验证），`natsx` v1.0.0（dev auth live gate 已验证；BLK-001/BLK-002 open），`postgresx` v1.0.0（live integration 通过；BLK-006 open），`taosx` v1.0.1（真实 taosWS WebSocket 集成已验证；BLK-007 open），`ossx` v1.0.1（真实 Aliyun OSS 集成、race/vet/build/release-check 已验证；BLK-008 open：API 文档 / integration evidence / quickstart / release manifest 未归档；非 factory）；`clickhousex` v1.0.1（公开 GitHub Release 未发布，BLK-003）；`transportx` v1.1.1-spec（SPEC baseline，production_import_allowed=false）。
- **SRE/CI/CD**：已产出 [`docs/sre/foundation-cicd-plan.md`](../docs/sre/foundation-cicd-plan.md)（19 模块 4 阶段部署方案、8 标签池、Docker 集成测试、标准化模板），待落地
- **阻塞项**：BLK-001 natsx 正式四源 98+ arbiter 未完成；BLK-002 natsx 生产 TLS gate 未闭合；BLK-003 clickhousex 公开 GitHub Release 未发布；BLK-006 postgresx 覆盖率 52.4% + Docker integration skip；BLK-007 taosx SPEC 67；BLK-008 ossx API 文档 / integration evidence / quickstart / release manifest 未归档。

### 🟢 L2.5 领域共享层（健康）

- 组件：5 个，进度 80%
- Phase 0 已完成，当前已建模的上层模块已依赖此层

### 🟢 数据域 · 行情（健康）

- SDK：13 个交易所适配器，全部 80%，无版本号
- Provider：5 个 Kline/Ticker Provider，全部 v0.1.0，进度 80%
- **待确认**：SDK 全部无版本号，是否已通过生产验证？

### 🟡 数据域 · 宏观（注意）

- 组件：11 个，全部 80%，无版本号
- 6 个央行数据源结构高度相似（fred / treasury / bea / ecb / uk-cb / japan-cb）
- **风险**：同质化严重，是否考虑合并为统一适配器？

### 🔴 数据域 · 另类（阻塞）

- 组件：1 个，仅创建（5%）
- **阻塞项**：链上数据、社交情绪、新闻 NLP 尚未开始实现

### 🔴 分析域（阻塞）

- 组件：8 个，7 个处于早期（5%），regime-engine 骨架完成（25%）
- **阻塞项**：factor-engine / feature-store / factor-eval / market_regime / macro_regime / ms_brain 均未实现到可用闭环；flowx SPEC 已创建（v0.1.0-draft）
- **依赖**：需要数据域提供数据，L2.5 已就绪

### 🔴 决策域（阻塞）

- 核心组件 3 个仅创建（5%）：signal-factory / backtest-engine / optimizer
- backtestx / strategyx / maestro SPEC 已创建（v0.1.0-draft）
- **阻塞项**：依赖分析域产出因子

### 🔴 执行域（阻塞）

- 组件：7 个，全部仅创建（5%）
- riskx / orderx / positionx SPEC 已创建（v0.1.0-draft）
- **阻塞项**：依赖决策域产出信号

### 🟡 入口（注意）

- x.go 已有（80%，v0.0.1），但 2.8MB/33 项体量异常大
- **架构守卫**：x.go 应只承担组合根职责；需核实是否存在因子计算、信号判断、风控规则或订单路由
- **待确认**：入口主逻辑是否能收敛为配置加载、依赖 wiring 和生命周期控制

### 🟡 横切（注意）

- alertx 仅创建（5%），observex 已完成（100%，v0.3.1，✅ GitHub Release 已发布）
- observex 同属基座和横切，职责边界通过 ADR 明确（见 `module/observex/ADR-dual-attribution.md`，R7 已闭环）

---

## 风险清单

### 🔴 高风险

| #   | 风险                                            | 影响             | 建议                         |
| --- | ----------------------------------------------- | ---------------- | ---------------------------- |
| R1  | 分析域/决策域/执行域核心链路低完成度（多数 5%） | 核心业务链路断裂 | 当前最高优先级，聚焦 Phase 1 |
| R2  | alternative-data 仅创建（5%）                   | 另类数据能力缺失 | 可延后，不影响核心链路       |

### 🟡 中风险

| #   | 风险                                    | 影响                              | 建议                                                                   |
| --- | --------------------------------------- | --------------------------------- | ---------------------------------------------------------------------- |
| R3  | x.go 2.8MB 体量异常                     | 可能违反组合根边界                | 按 ARCHITECTURE.md 的组合根守卫核实，剥离业务逻辑                      |
| R4  | 13 个交易所 SDK 全部无版本号            | 无法追踪 API 兼容性               | 建立版本化发布机制                                                     |
| R5  | 宏观数据源 6 个央行适配器同质化         | 维护成本高                        | 考虑合并为统一适配器                                                   |
| R7  | observex 双重归属（基座+横切）          | 职责边界模糊                      | ✅ 已记录 ADR：`module/observex/ADR-dual-attribution.md`（2026-06-12） |
| R10 | ~~`.omc/state/sessions` 已入库~~        | ~~可能泄露 prompt/会话/环境信息~~ | ✅ 已修复：`git rm -r --cached .omc`（2026-06-07）                     |
| R11 | ~~公开 README 含 `127.0.0.1` 本地链接~~ | ~~外部无法访问，降低专业度~~      | ✅ 已修复：批量移除所有本地链接（2026-06-07）                          |
| R12 | 71 个仓库无统一命名前缀                 | 分类困难，增加维护成本            | 按 `foundation-*`/`adapter-*`/`engine-*`/`lab-*` 重整                  |

### 🟢 低风险

| #   | 风险                                                                                                                                                                                                   | 影响                                                              | 建议                                                     |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------- | -------------------------------------------------------- |
| R8  | natsx 正式四源 98+ arbiter 与生产 TLS gate 仍 open；postgresx 单元测试覆盖率 52.4% 且 Docker 集成测试 skip；taosx SPEC 67；ossx API 文档 / integration evidence / quickstart / release manifest 未归档 | 阻塞对应模块 factory 投影，不阻塞上层继续按 spec/adapter 边界开发 | 按 BLK-001/002/006/007/008 关闭证据后再恢复 factory 投影 |
| R9  | 分析域↔决策域若用实现包互调                                                                                                                                                                            | Go 循环导入和边界泄漏                                             | 只允许通过 contracts 事件/DTO 与 L2.5 模型连接           |

---

## 待办与阻塞

### 当前阻塞项

- [ ] Phase 1（分析域）未开始 → 阻塞 Phase 2/3/4/5
- [ ] x.go 体量待核实 → 按组合根守卫确认并剥离业务逻辑

### 下一步行动

1. **聚焦 Phase 1**：先固化 MarketDataProvider / FactorInput / FactorOutput，再实现 factor-engine → feature-store → factor-eval
2. **核实 x.go**：确认只包含配置加载、依赖 wiring 和生命周期控制，必要时剥离业务逻辑
3. **版本化 SDK**：为 13 个交易所 SDK 建立 tagged release
4. **统一宏观适配器**：评估 6 个央行数据源合并可行性
5. ~~**清理仓库卫生**（R10）~~：✅ 已完成（2026-06-07）
6. ~~**移除本地链接**（R11）~~：✅ 已完成（2026-06-07）
7. **重整仓库命名**（R12）：评估按 `foundation-*`/`adapter-*`/`engine-*`/`lab-*` 前缀重命名的可行性

---

## 文档同步检查

| 检查项           | README | ARCHITECTURE | STATUS    | 一致性 |
| ---------------- | ------ | ------------ | --------- | ------ |
| 组件总数         | 77     | 77           | 80        | ⚠️     |
| market-data 数量 | 18     | 18 (13+5)    | 18 (13+5) | ✅     |
| macro-data 数量  | 11     | 11           | 11        | ✅     |
| L2.5 组件        | 5      | 5            | 5         | ✅     |
| 分析域组件       | 8      | 8            | 8         | ✅     |
| 决策域组件       | 6      | 6            | 6         | ✅     |
| 横切组件         | 2      | 2            | 2         | ✅     |

注：以上为各文档 unique repo 链接数（grep github.com/ZoneCNH 去重后计数）。README 与 ARCH 均为 77；STATUS 去重后为 78（多 stdlib.rs）。STATUS 的 80 是域统计 domain-sum 口径，不与 README/ARCH unique-link 77 直接比较（observex 计入基座+横切 2 域，stdlib.rs+module 独立计）。L2.5=5/分析域=8/决策域=6 三文档一致。

### 迁移与门禁基线

| 项目          | 当前状态                                                                                                | 验证方式                                         |
| ------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| 规格库入口    | `module/` 承载 24 份模块与组合根规格；`docs/governance/` 承载治理模板、生命周期、追溯与评分规则         | 旧路径扫描、`spec-lint.sh`、治理路径扫描         |
| Goal 规则入口 | `docs/goal/` 定义交付规则；`.config/goal/` 承载运行状态                                                 | `traceability-check.sh`、`task-spec-validate.sh` |
| 公开索引      | `README.md`、`ARCHITECTURE.md`、`STATUS.md` 区分 `module/` 与 `docs/governance/` 入口                   | `status-consistency-check.sh`、治理路径扫描      |
| 漂移防护      | 不恢复旧 `specs/` 与 `module/governance` 路径，agent 与 CI 引用保持 `module/` + `docs/governance/` 口径 | 旧路径扫描、`spec-drift-guard.sh`                |

---

## 管线状态总览

20/20 模块全部阶段 ≥67（rule-scorer 真实评分），其中 13/20 全线 ≥98。该表是 Spec→Code 管线分项评分，不代表 release/factory；release/factory 投影以 `.foundationx/status/index.json` + `.foundationx/blockers.json` 为准。

| 模块          | spec | matrix | tasks | plan | prompt | code |
| ------------- | :--: | :----: | :---: | :--: | :----: | :--: |
| clickhousex   | 100  |  100   |  100  | 100  |  100   | 100  |
| configx       | 100  |  100   |  96   | 100  |  100   | 100  |
| contracts     | 100  |  100   |  100  | 100  |  100   | 100  |
| domainx       | 100  |  100   |  100  | 100  |  100   | 100  |
| kafkax        | 100  |  100   |  100  | 100  |  100   | 100  |
| kernel        | 100  |  100   |  100  | 100  |  100   | 100  |
| natsx         | 100  |  100   |  92   | 100  |  100   | 100  |
| observex      | 100  |  100   |  100  | 100  |  100   | 100  |
| ossx          | 100  |  100   |  100  | 100  |  100   | 100  |
| postgresx     | 100  |  100   |  100  | 100  |  100   | 100  |
| redisx        |  98  |  100   |  100  | 100  |  100   | 100  |
| resiliencx    | 100  |  100   |  100  | 100  |  100   | 100  |
| schedulex     |  98  |  100   |  100  | 100  |  100   | 100  |
| taosx         |  67  |  100   |  76   | 100  |  100   | 100  |
| testkitx      | 100  |  100   |  100  | 100  |  100   | 100  |
| transportx    |  84  |  100   |  100  | 100  |  100   | 100  |
| xlib-evidence |  83  |  100   |  100  | 100  |  100   | 100  |
| xlib-harness  |  83  |  100   |  97   | 100  |  100   | 100  |
| xlib-standard | 100  |   80   |  98   | 100  |  100   | 100  |
| xlibgate      | 100  |  100   |  100  | 100  |  100   | 100  |

> 剩余 7 模块需 SPEC 级内容修复（spec 缺 WHEN/THEN、章节等）。prompt/code 外仓模块为 pass-through。xlib-standard 为快照格式除外。
