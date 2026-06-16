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
| [xlib-harness](https://github.com/ZoneCNH/xlib-harness)   | v0.1.0      | spec/code/release      | factory-ready   | spec=98 mat=100 tsk=98 pln=100 prm=100 cod=100   | 模块生成器与门禁执行器：generate/scaffold、spec-lint、boundary-check、traceability-gate；✅ CI 已部署；✅ GitHub Release v0.1.0 已发布                                                    |
| [xlib-evidence](https://github.com/ZoneCNH/xlib-evidence) | v0.1.0      | spec/code/release      | factory-ready   | spec=98 mat=100 tsk=100 pln=100 prm=100 cod=100  | 证据收集与发布运行时：collect-coverage、generate-manifest、validate-manifest、report；✅ CI 已部署；✅ GitHub Release v0.1.0 已发布                                                       |
| [xlibgate](https://github.com/ZoneCNH/xlibgate)           | v1.0.0      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | check/l2/trust 三组门禁；✅ .repo-contract.yaml，v1.0.0 已对齐（此前误标 v1.1.1）；trust CLI 已实现                                                                                                 |
| [kernel](https://github.com/ZoneCNH/kernel)               | v1.0.0      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | L0 原语 / 12 子包 / stdlib-only；✅ .repo-contract.yaml，v1.0.0 已对齐，建议 API 冻结                                                                                                               |
| [configx](https://github.com/ZoneCNH/configx)             | v1.0.0      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 配置管理；✅ v1.0.0 GitHub Release 已发布；此前误标 v0.1.4 已修正；✅ .repo-contract.yaml                                                                                                           |
| [observex](https://github.com/ZoneCNH/observex)           | v0.3.1      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 可观测性；✅ v0.3.1 GitHub Release 已发布；此前误标 v1.0.0 已修正                                                                                                                                   |
| [testkitx](https://github.com/ZoneCNH/testkitx)           | v0.4.0      | spec/code/release      | test-only       | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Fake / Fixture / Golden / Contract / Leak / Boundary / Manifest 测试工具包；✅ v0.4.0 GitHub Release 已发布；test-only；factory grade 不适用                                                        |
| [resiliencx](https://github.com/ZoneCNH/resiliencx)       | v0.4.9      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 弹性策略（timeout / retry / circuit / bulkhead / rate / fallback）；✅ v0.4.9 GitHub Release 已发布；此前误标 v1.0.1 已修正                                                                         |
| [schedulex](https://github.com/ZoneCNH/schedulex)         | v1.0.0      | spec/code/release      | factory-ready   | spec=98 mat=100 tsk=100 pln=100 prm=100 cod=100  | cron/interval/delay 调度；✅ .repo-contract.yaml，v1.0.0 已对齐；98.2% 覆盖，下游 smoke 通过                                                                                                        |
| [redisx](https://github.com/ZoneCNH/redisx)               | v1.0.1      | spec/code/release/live | live-ready      | spec=98 mat=100 tsk=100 pln=100 prm=100 cod=100  | Redis L2 adapter；✅ .repo-contract.yaml，v1.0.1；此前误标 v1.0.0（tag 超前于表格）；Docker-backed Redis 验证通过                                                                                   |
| [kafkax](https://github.com/ZoneCNH/kafkax)               | v1.0.2      | spec/code/release/live | live-ready      | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Kafka L2 adapter；✅ .repo-contract.yaml，v1.0.2；此前误标 v1.0.0（tag 超前于表格）；真实 broker gates 已验证                                                                                       |
| [natsx](https://github.com/ZoneCNH/natsx)                 | v1.0.0      | spec/code/release/live | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | NATS L2 adapter；✅ .repo-contract.yaml；真实 dev auth live gate 已验证；GitHub Release 已发布                                                                          |
| [postgresx](https://github.com/ZoneCNH/postgresx)         | v1.0.0      | spec/code/release/live | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | PostgreSQL；✅ .repo-contract.yaml；live integration 通过；GitHub Release 已发布                                                                                         |
| [taosx](https://github.com/ZoneCNH/taosx)                 | v1.0.1      | spec/code/release/live | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | TDengine L2 adapter；真实 taosWS WebSocket 集成已验证；GitHub Release 已发布                                                                                              |
| [ossx](https://github.com/ZoneCNH/ossx)                   | v1.0.1      | spec/code/release/live | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Aliyun OSS L2 adapter；✅ .repo-contract.yaml；race/vet/build/release-check 已通过；GitHub Release 已发布                                                                 |
| [clickhousex](https://github.com/ZoneCNH/clickhousex)     | v1.0.1      | spec/code/release/live  | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | ClickHouse；OLAP 查询、批量写入；GitHub Release 已发布；CI 已部署+运行(Docker ClickHouse)                                                                                  |
| [contracts](https://github.com/ZoneCNH/contracts)         | v1.0.1-spec | spec/code/release       | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 跨域稳定端口/事件/DTO 契约；spec-only；✅ GitHub Release v1.0.1-spec 已发布                                                                                                                       |
| [transportx](https://github.com/ZoneCNH/transportx)       | v1.1.1-spec | spec/code/release       | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 应用通信底座规格基线；spec-only；✅ GitHub Release v1.1.1-spec 已发布                                                                                                                            |

> ✅ **版本 / release 注记**：公开文档是投影层；版本、release 与 factory 状态以 `.foundationx/status/index.json` + `.foundationx/blockers.json` 为准。当前 20-module projection 中 20/20 已发布 GitHub Release，0 open blockers，Foundation 整体 factory grade。

> **成熟度语义说明（2026-06-14 v2 Trust Alignment）**：上表"进度"反映本仓库 Spec 管线评分（spec→code），不代表可投产等级（factory grade）。下表提供多维度成熟度视图；RELEASE=❌ 或存在 open blocker 的模块不得投影为 FACTORY=✅。

<details>
<summary>📊 基座多维成熟度展开（点击展开）</summary>

| 模块                          |     SPEC      |               IMPL                |             RELEASE              |        LIVE INT         |         EXT CI         |            ADOPT            |                     SOAK                      | FACTORY | 备注                                                                                                                                                       |
| ----------------------------- | :-----------: | :-------------------------------: | :------------------------------: | :---------------------: | :--------------------: | :-------------------------: | :-------------------------------------------: | :-----: | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| xlib-standard                 |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.0; GitHub Release 已发布; 9 CI workflows                                                                                                              |
| xlib-harness                  |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v0.1.0; GitHub Release 已发布; generate/scaffold/spec-lint/boundary/traceability; CI 已部署                                                                  |
| xlib-evidence                 |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v0.1.0; GitHub Release 已发布; evidence collect/generate/validate/report; CI 已部署                                                                          |
| xlibgate                      |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.0; CI 已部署; 8 workflows; 此前误标 v1.1.1                                                                                                            |
| kernel                        |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v1.0.0; 4 CI workflows; 13 下游消费者; API 冻结建议                                                                                                        |
| configx                       |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v1.0.0; GitHub Release 已发布; 4 CI workflows; 2 下游消费者; 此前误标 v0.1.4 已修正                                                                        |
| observex                      |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v0.3.1; GitHub Release 已发布; 4 CI workflows; 2 下游消费者; 此前误标 v1.0.0 已修正                                                                        |
| testkitx                      |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   N/A   | v0.4.0; GitHub Release 已发布; 4 CI workflows; test-only — factory grade 不适用                                                                            |
| resiliencx                    |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v0.4.9; GitHub Release 已发布; 9 CI workflows; 2 下游消费者; 此前误标 v1.0.1 已修正                                                                        |
| schedulex                     |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v1.0.0; 6 CI workflows; 下游 smoke 通过; 1 下游消费者                                                                                                      |
| redisx                        |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.1; 9 CI workflows; Docker-backed Redis 验证通过                                                                                                       |
| kafkax                        |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.2; 8 CI workflows; 真实 broker gates 已验证                                                                                                           |
| natsx                         |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.0; GitHub Release 已发布; 6 CI workflows; dev auth live gate 已验证                                                               |
| postgresx                     |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.0; GitHub Release 已发布; 3 CI workflows; live integration 通过                                                              |
| taosx                         |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.1; GitHub Release 已发布; 8 CI workflows; 真实 taosWS WebSocket 集成已验证 |
| ossx                          |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.1; GitHub Release 已发布; CI 已部署; 真实 Aliyun OSS 集成、race/vet/build/release-check 已验证        |
| clickhousex                   |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.1; GitHub Release 已发布; CI 已部署+运行(Docker ClickHouse)                                                  |
| contracts                     |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v1.0.1-spec; GitHub Release 已发布; spec-only; 跨域稳定端口/事件/DTO 契约                                                     |
| transportx                    |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.1.1-spec; GitHub Release 已发布; spec-only; 应用通信底座规格基线                                                      |
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
| [binance](https://github.com/ZoneCNH/binance)                 | C/S Module | v1.0.0-spec | ███░ 80% | 100%       | Market Data C/S (client+server)；4产品线 |
| [okx](https://github.com/ZoneCNH/okx)                         | SDK      | v0.1.1 | ███░ 80% | 100%       | OKX CEX               |
| [bybit](https://github.com/ZoneCNH/bybit)                     | SDK      | v0.1.1 | ███░ 80% | 100%       | Bybit CEX             |
| [bitget](https://github.com/ZoneCNH/bitget)                   | SDK      | v0.1.1 | ███░ 80% | 100%       | Bitget CEX            |
| [kucoin](https://github.com/ZoneCNH/kucoin)                   | SDK      | v0.1.1 | ███░ 80% | 100%       | KuCoin CEX            |
| [gate](https://github.com/ZoneCNH/gate)                       | SDK      | v0.1.1 | ███░ 80% | 100%       | Gate CEX              |
| [mexc](https://github.com/ZoneCNH/mexc)                       | SDK      | v0.1.1 | ███░ 80% | 100%       | MEXC CEX              |
| [htx](https://github.com/ZoneCNH/htx)                         | SDK      | v0.1.1 | ███░ 80% | 100%       | HTX CEX               |
| [coinbase](https://github.com/ZoneCNH/coinbase)               | SDK      | v0.1.1 | ███░ 80% | 100%       | Coinbase CEX          |
| [hyperliquid](https://github.com/ZoneCNH/hyperliquid)         | SDK      | v0.1.1 | ███░ 80% | 100%       | Hyperliquid DEX       |
| [lighter](https://github.com/ZoneCNH/lighter)                 | SDK      | v0.1.1 | ███░ 80% | 100%       | Lighter DEX           |
| [upbit](https://github.com/ZoneCNH/upbit)                     | SDK      | v0.1.1 | ███░ 80% | 100%       | Upbit CEX             |
| [coinglass](https://github.com/ZoneCNH/coinglass)             | SDK      | v0.1.1 | ███░ 80% | 100%       | 衍生品聚合数据        |

<details>
<summary>📊 数据域 · 行情多维成熟度展开（点击展开）</summary>

| 模块            | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                               |
| --------------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | ---------------------------------- |
| binance         |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | C/S Module；v1.0.0-spec；4产品线     |
| okx             |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；OKX CEX                  |
| bybit           |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Bybit CEX                |
| bitget          |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Bitget CEX               |
| kucoin          |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；KuCoin CEX               |
| gate            |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Gate CEX                 |
| mexc            |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；MEXC CEX                 |
| htx             |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；HTX CEX                  |
| coinbase        |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Coinbase CEX             |
| hyperliquid     |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Hyperliquid DEX          |
| lighter         |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Lighter DEX              |
| upbit           |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Upbit CEX                |
| coinglass       |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；衍生品聚合数据           |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 数据域 · 宏观

| 组件                                                  | 版本 | 进度     | 覆盖率要求 | 说明           |
| ----------------------------------------------------- | ---- | -------- | ---------- | -------------- |
| [fred](https://github.com/ZoneCNH/fred)               | v0.1.1 | ███░ 80% | 100%       | 美联储 FRED    |
| [treasury](https://github.com/ZoneCNH/treasury)       | v0.1.1 | ███░ 80% | 100%       | 美国财政部     |
| [yield-curve](https://github.com/ZoneCNH/yield-curve) | v0.1.1 | ███░ 80% | 100%       | 收益率曲线     |
| [bea](https://github.com/ZoneCNH/bea)                 | v0.1.1 | ███░ 80% | 100%       | 美国经济分析局 |
| [ecb](https://github.com/ZoneCNH/ecb)                 | v0.1.1 | ███░ 80% | 100%       | 欧洲央行       |
| [uk-cb](https://github.com/ZoneCNH/uk-cb)             | v0.1.1 | ███░ 80% | 100%       | 英国央行       |
| [japan-cb](https://github.com/ZoneCNH/japan-cb)       | v0.1.1 | ███░ 80% | 100%       | 日本央行       |
| [eastmoney](https://github.com/ZoneCNH/eastmoney)     | v0.1.1 | ███░ 80% | 100%       | 东方财富 A 股  |
| [jin10](https://github.com/ZoneCNH/jin10)             | v0.2.0 | ███░ 80% | 100%       | 金十数据 SDK：openapi（宏观数据）+ flash（实时快讯） |
| [yahoo](https://github.com/ZoneCNH/yahoo)             | v0.1.1 | ███░ 80% | 100%       | Yahoo Finance  |

<details>
<summary>📊 数据域 · 宏观多维成熟度展开（点击展开）</summary>

| 模块        | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                  |
| ----------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | --------------------- |
| fred        |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；美联储 FRED 数据 |
| treasury    |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；美国财政部数据   |
| yield-curve |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；收益率曲线       |
| bea         |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；美国经济分析局   |
| ecb         |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；欧洲央行         |
| uk-cb       |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；英国央行         |
| japan-cb    |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；日本央行         |
| eastmoney   |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；东方财富 A 股    |
| jin10       |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.2.0；金十数据 SDK：openapi + flash |
| yahoo       |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；Yahoo Finance    |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 数据域 · 另类

| 组件                                                            | 版本 | 进度    | 覆盖率要求 | 说明                     |
| --------------------------------------------------------------- | ---- | ------- | ---------- | ------------------------ |
| [alternative-data](https://github.com/ZoneCNH/alternative-data) | v0.1.0 | ░░░░ 5% | 100%       | 链上、社交情绪、新闻 NLP |

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
| [factor-engine](https://github.com/ZoneCNH/factor-engine) | v0.1.0       | ░░░░ 5%  | 100%       | 因子计算引擎                                                             |
| [feature-store](https://github.com/ZoneCNH/feature-store) | v0.1.0       | ░░░░ 5%  | 100%       | 特征存储与版本管理                                                       |
| [factor-eval](https://github.com/ZoneCNH/factor-eval)     | v0.1.0       | ░░░░ 5%  | 100%       | 因子评估                                                                 |
| [market_regime](https://github.com/ZoneCNH/market_regime) | 空仓库       | ░░░░ 5%  | 100%       | 市场状态识别；空仓库，待初始化                                           |
| [macro_regime](https://github.com/ZoneCNH/macro_regime)   | 空仓库       | ░░░░ 5%  | 100%       | 宏观经济体制识别（M1-M7）；空仓库，待初始化                               |
| [ms_brain](https://github.com/ZoneCNH/ms_brain)           | v1.6.6       | ░░░░ 5%  | 100%       | M×S 系统架构分析体系                                                     |
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
| [signal-factory](https://github.com/ZoneCNH/signal-factory)   | v0.1.0       | ░░░░ 5% | 100%       | 信号生成与组合                                                      |
| [backtest-engine](https://github.com/ZoneCNH/backtest-engine) | v0.1.0       | ░░░░ 5% | 100%       | 事件驱动回测                                                        |
| [optimizer](https://github.com/ZoneCNH/optimizer)             | v0.1.0       | ░░░░ 5% | 100%       | 参数优化                                                            |
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
| [risk-engine](https://github.com/ZoneCNH/risk-engine)           | v0.1.0       | ░░░░ 5% | 100%       | 风险管理引擎                                                 |
| [order-engine](https://github.com/ZoneCNH/order-engine)         | v0.1.0       | ░░░░ 5% | 100%       | 订单执行引擎                                                 |
| [portfolio-engine](https://github.com/ZoneCNH/portfolio-engine) | v0.1.0       | ░░░░ 5% | 100%       | 投资组合管理                                                 |
| [settlement](https://github.com/ZoneCNH/settlement)             | v0.1.0       | ░░░░ 5% | 100%       | 结算与对账                                                   |
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

### 入口 · 横切

| 组件                                              | 域   | 版本   | 进度                            | 覆盖率要求 | 说明                                                      |
| ------------------------------------------------- | ---- | ------ | ------------------------------- | ---------- | --------------------------------------------------------- |
| [x.go](https://github.com/ZoneCNH/x.go)           | 入口 | v0.0.1 | ███░ 80%                        | 100%       | 组合根，2.8MB/33 项                                       |
| [alertx](https://github.com/ZoneCNH/alertx)       | 横切 | v0.1.0 | ░░░░ 5%                         | 100%       | 告警引擎                                                  |
| [observex](https://github.com/ZoneCNH/observex)   | 横切 | v0.3.1 | 全管线 --force pass (spec→code) | 100%       | 可观测性（同时归属基座）；✅ v0.3.1 GitHub Release 已发布 |
| [module](./module/README.md)                      | 独立 | -      | -                               | 100%       | 项目技术规范与接口定义                                    |

---

## 总览仪表盘

```text
组件总数: 78    已有: 56    已创建: 22    平均进度: 62%

进度分布:
  ███░ ≥80% ██████████████████████████████████████████████  54 个 (69%)
  █░░░ 25%  ░                                                 1 个 ( 1%)
  ░░░░  5%  ████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  22 个 (28%)
  未标注    ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   1 个 ( 1%)

版本覆盖: 有版本号 75 个 (96%)    无版本号 3 个 (4%)
```

### 按域统计

| 域                     | 总数   | 已有   | 已创建 | 平均进度                           | 有版本号                                              |
| ---------------------- | ------ | ------ | ------ | ---------------------------------- | ----------------------------------------------------- |
| 基座                   | 19     | 19     | 0      | Spec→Code 投影完成；factory 未闭合 | 19                                                    |
| L2.5 领域共享层        | 5      | 5      | 0      | 100%                               | 5 (全部 5/5 factory grade；live/soak N/A)            |
| 数据域 · 行情 SDK      | 13     | 13     | 0      | 80%                                | 13 (全部 v0.1.1)                                      |
| 数据域 · 行情 Provider | 5      | 5      | 0      | 80%                                | 5 (全部 v0.1.1)                                       |
| 数据域 · 宏观          | 10     | 10     | 0      | 80%                                | 10 (全部 v0.1.1)                                      |
| 数据域 · 另类          | 1      | 0      | 1      | 5%                                 | 1 (v0.1.0)                                            |
| 分析域                 | 8      | 1      | 7      | 8%                                 | 6 (含 ms_brain v1.6.6；market_regime/macro_regime 空仓库) |
| 决策域                 | 6      | 0      | 6      | 5%                                 | 6 (全部 v0.1.0+)                                      |
| 执行域                 | 7      | 0      | 7      | 5%                                 | 7 (全部 v0.1.0+)                                      |
| 入口                   | 1      | 1      | 0      | 80%                                | 1 (x.go)                                              |
| 横切                   | 2      | 1      | 1      | 53%                                | 2 (observex, alertx)                                  |
| 独立                   | 1      | 1      | 0      | -                                  | 0                                                     |
| **合计**               | **78** | **56** | **22** | **62%**                            | **75**                                                |

---

## 域健康度

### 🟢 基座（健康）

- 组件：19 个（不含 L2.5；机器事实层另将 `domainx` 作为 L2.5 模块计入 20-module projection）；
  Spec→Code 管线投影已闭合，但不等于 Foundation 整体 factory grade。
 - 核心模块全部 20/20 GitHub Release 已发布，0 open blockers，Foundation 整体 factory grade。
 - 存储层全部模块 GitHub Release 已发布、CI 已部署、live integration 已验证。
 - **阻塞项**：无 — 全部 8 项 BLK 已于 2026-06-16 闭合。

### 🟢 L2.5 领域共享层（健康）

- 组件：5 个，进度 80%
- Phase 0 已完成，当前已建模的上层模块已依赖此层

### 🟢 数据域 · 行情（健康）

- SDK：13 个交易所适配器，全部 v0.1.1，进度 80%
- **待确认**：SDK 全部 v0.1.1 tagged release，已通过生产验证？

### 🟡 数据域 · 宏观（注意）

- 组件：10 个，全部 80%，jin10 v0.2.0，其他 v0.1.1 tagged release
- 6 个央行数据源结构高度相似（fred / treasury / bea / ecb / uk-cb / japan-cb）
- **评估结论（2026-06-16）**：各模块保持独立架构，不合并；建议在 contracts 中提取共享 DataSource 接口统一契约

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
| R4  | ~~13 个交易所 SDK 全部无版本号~~        | ~~无法追踪 API 兼容性~~           | ✅ 已版本化：18 仓库 v0.1.1 tagged release（2026-06-16）               |
| R5  | ~~宏观数据源 6 个央行适配器同质化~~     | ~~维护成本高~~                    | ✅ 已评估 — 各模块保持独立，已统一打 v0.1.1（2026-06-16）              |
| R7  | observex 双重归属（基座+横切）          | 职责边界模糊                      | ✅ 已记录 ADR：`module/observex/ADR-dual-attribution.md`（2026-06-12） |
| R10 | ~~`.omc/state/sessions` 已入库~~        | ~~可能泄露 prompt/会话/环境信息~~ | ✅ 已修复：`git rm -r --cached .omc`（2026-06-07）                     |
| R11 | ~~公开 README 含 `127.0.0.1` 本地链接~~ | ~~外部无法访问，降低专业度~~      | ✅ 已修复：批量移除所有本地链接（2026-06-07）                          |
| R12 | 71 个仓库无统一命名前缀                 | 分类困难，增加维护成本            | 按 `foundation-*`/`adapter-*`/`engine-*`/`lab-*` 重整                  |

### 🟢 低风险

| #   | 风险                                                                                                                                                                                                   | 影响                                                              | 建议                                                     |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------- | -------------------------------------------------------- |
| R8  | natsx 正式四源 98+ arbiter 与生产 TLS gate 仍 open；postgresx 单元测试覆盖率 52.4% 且 Docker 集成测试 skip；taosx SPEC ~88 (全部闭合)；ossx API 文档 / integration evidence / quickstart / release manifest 未归档 | 阻塞对应模块 factory 投影，不阻塞上层继续按 spec/adapter 边界开发 | 按 BLK-001/002/006/007/008 关闭证据后再恢复 factory 投影 |
| R9  | 分析域↔决策域若用实现包互调                                                                                                                                                                            | Go 循环导入和边界泄漏                                             | 只允许通过 contracts 事件/DTO 与 L2.5 模型连接           |

---

## 待办与阻塞

### 当前阻塞项

- [ ] Phase 1（分析域）未开始 → 阻塞 Phase 2/3/4/5
- [ ] x.go 体量待核实 → 按组合根守卫确认并剥离业务逻辑

### 下一步行动

1. **聚焦 Phase 1**：先固化 MarketDataProvider / FactorInput / FactorOutput，再实现 factor-engine → feature-store → factor-eval
2. **核实 x.go**：确认只包含配置加载、依赖 wiring 和生命周期控制，必要时剥离业务逻辑
3. ~~**版本化 SDK**~~：✅ 已完成 — 18 仓库 v0.1.1 tagged release（2026-06-16）
4. ~~**统一宏观适配器**~~：✅ 已评估 — 保持独立模块架构，11 仓库全部 v0.1.1 tagged release（2026-06-16）
5. ~~**清理仓库卫生**（R10）~~：✅ 已完成（2026-06-07）
6. ~~**移除本地链接**（R11）~~：✅ 已完成（2026-06-07）
7. **重整仓库命名**（R12）：评估按 `foundation-*`/`adapter-*`/`engine-*`/`lab-*` 前缀重命名的可行性

---

## 文档同步检查

| 检查项           | README | ARCHITECTURE | STATUS    | 一致性 |
| ---------------- | ------ | ------------ | --------- | ------ |
| 组件总数         | 71     | 71           | 71        | ✅     |
| market-data 数量 | 13     | 13          | 13        | ✅     |
| macro-data 数量  | 10     | 10           | 10        | ✅     |
| L2.5 组件        | 5      | 5            | 5         | ✅     |
| 分析域组件       | 8      | 8            | 8         | ✅     |
| 决策域组件       | 6      | 6            | 6         | ✅     |
| 横切组件         | 2      | 2            | 2         | ✅     |

注：以上为各文档 unique repo 链接数（grep github.com/ZoneCNH 去重后计数）。README 与 ARCH 均为 77；STATUS 去重后同为 77（observex 计 1 次）。STATUS 的 79 是域统计 domain-sum 口径，不与 unique-link 77 直接比较（observex 计入基座+横切 2 域，module 独立计）。L2.5=5/分析域=8/决策域=6 三文档一致。

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
| taosx         | ~88  |  100   | ~88   | 100  |  100   | 100  |
| testkitx      | 100  |  100   |  100  | 100  |  100   | 100  |
| transportx    |  84  |  100   |  100  | 100  |  100   | 100  |
| xlib-evidence |  83  |  100   |  100  | 100  |  100   | 100  |
| xlib-harness  |  83  |  100   |  97   | 100  |  100   | 100  |
| xlib-standard | 100  |   80   |  98   | 100  |  100   | 100  |
| xlibgate      | 100  |  100   |  100  | 100  |  100   | 100  |

> 剩余 7 模块需 SPEC 级内容修复（spec 缺 WHEN/THEN、章节等）。prompt/code 外仓模块为 pass-through。xlib-standard 为快照格式除外。
