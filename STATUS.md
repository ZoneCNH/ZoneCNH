# 📊 项目状态监控

> FoundationX 量化交易基础设施的实时健康度与风险追踪
>
> 数据来源：各 GitHub 仓库实际状态，定期更新
>
> 最后更新：2026-06-21
>
> 同步基线：`module/` 为模块规格库 SSOT，`docs/governance/` 为 Spec 治理 SSOT，`docs/goal/` 为 Goal 规则 SSOT，`specs/` 已移除。
> 机器事实源：`.foundationx/status/index.json` — 由 `xlibgate fleet-status` 生成，供 CI 和自动投影消费。多维成熟度以该文件为准，本文手工块为投影。

---

## 组件明细表

### 基座

| 组件                                                      | 版本（目标投影）| 阶段投影               | 门禁口径        | 子维度投影                                       | 说明                                                                                                                                                                                                |
| --------------------------------------------------------- | ----------- | ---------------------- | --------------- | ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [xlib_standard](https://github.com/ZoneCNH/xlib_standard) | v1.1.0      | spec/code/release      | factory-ready   | spec=100 mat=98 tsk=100 pln=100 prm=100 cod=100  | 标准事实源 / Go Reference Template；Generator/Harness/Evidence 已拆分至 xlib_harness / xlib_evidence；✅ .repo-contract.yaml (is_standard_source)；✅ GitHub Release v1.0.0 已发布                  |
| [xlib_harness](https://github.com/ZoneCNH/xlib_harness)   | v1.1.0      | spec/code/release      | factory-ready   | spec=98 mat=100 tsk=98 pln=100 prm=100 cod=100   | 模块生成器与门禁执行器：generate/scaffold、spec-lint、boundary-check、traceability-gate、format-check；✅ CI 已部署；✅ GitHub Release v0.1.6 已发布；Release run 27855366871 与 main CI run 27855396013 通过；coverage 100.0%；pinned gitleaks CLI secret scan 已对齐 |
| [xlib_evidence](https://github.com/ZoneCNH/xlib_evidence) | v0.2.4      | spec/code/release      | factory-ready   | spec=98 mat=100 tsk=100 pln=100 prm=100 cod=100  | 证据收集与发布运行时：collect-coverage、generate-manifest、validate-manifest、remote-evidence、report；✅ CI 已部署；✅ GitHub Release v0.2.4 已发布；release evidence assets 已归档；go test/race/vet/build/coverage 100.0% 通过 |
| [xlibgate](https://github.com/ZoneCNH/xlibgate)           | v1.2.0      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | check/l2/trust 三组门禁；✅ .repo-contract.yaml，v1.0.0 已对齐（此前误标 v1.1.1）；trust CLI 已实现                                                                                                 |
| [kernel](https://github.com/ZoneCNH/kernel)               | v2.1.0      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | L0 原语 / 12 子包 / stdlib-only；✅ .repo-contract.yaml，v1.0.0 已对齐；2026-06-18 代码侧验收全部通过（test/race/vet/coverage 100% / stdlib-only / secrets，evidence: `.config/goal/evidence/kernel-acceptance-20260618/`）；BLK-011 resolved（kernel factory 闭合，Factory=true）                                                                                     |
| [configx](https://github.com/ZoneCNH/configx)             | v1.2.0      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 配置管理；✅ v1.1.0 GitHub Release 已发布（完整交付 v1.0 路线 5 项 MUST：ArgsSource / RemoteSource SPI / Bind / Snapshot+Watch+Rollback / DocGen）；version.go 与 git tag 与 CHANGELOG 已对齐；✅ .repo-contract.yaml                                                                                                           |
| [observex](https://github.com/ZoneCNH/observex)           | v1.1.0      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 可观测性；✅ v0.3.4 GitHub Release 已发布（Labels 改为 type alias，允许下游 map[string]string 直接满足接口）；v1.0.0 误置 tag/Release 已清理（2026-06-19）                                                                                                                                   |
| [testkitx](https://github.com/ZoneCNH/testkitx)           | v1.1.0      | spec/code/release      | test-only       | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Fake / Fixture / Golden / Contract / Leak / Boundary / Manifest 测试工具包；✅ v0.4.0 GitHub Release 已发布；test-only；factory grade 不适用                                                        |
| [resiliencx](https://github.com/ZoneCNH/resiliencx)       | v1.1.0      | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 弹性策略（timeout / retry / circuit / bulkhead / rate / fallback）；✅ v0.4.9 GitHub Release 已发布；此前误标 v1.0.1 已修正                                                                         |
| [schedulex](https://github.com/ZoneCNH/schedulex)         | v1.1.0      | spec/code/release      | factory-ready   | spec=98 mat=100 tsk=100 pln=100 prm=100 cod=100  | cron/interval/delay 调度；✅ .repo-contract.yaml，v1.0.0 已对齐；98.2% 覆盖，下游 smoke 通过                                                                                                        |
| [bootstrap](https://github.com/ZoneCNH/bootstrap)         | v0.2.0      | spec/code/release      | factory-ready   | spec=~90 mat=N/A tsk=N/A pln=N/A prm=N/A cod=N/A | L1 通用进程组装层：configx/observex/resiliencx + lifecycx 统一组装 + 8 存储 adapter 构造（StoreSet 位掩码）；✅ GitHub Release v0.2.0；✅ BLK-009 closed（foundationx 依赖清零 + Stores!=None 全部实现）                        |
| [redisx](https://github.com/ZoneCNH/redisx)               | v1.2.0      | spec/code/release/live | live-ready      | spec=98 mat=100 tsk=100 pln=100 prm=100 cod=100  | Redis L2 adapter；✅ .repo-contract.yaml，v1.1.0；GitHub Release v1.1.0 已发布；PR #19、release workflow 27802471873、release-preflight 与 dev Redis 集成验证通过                             |
| [kafkax](https://github.com/ZoneCNH/kafkax)               | v1.2.0      | spec/code/release/live | live-ready      | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Kafka L2 adapter；✅ .repo-contract.yaml，v1.1.0；此前误标 v1.0.0（tag 超前于表格）；真实 broker gates 已验证                                                                                       |
| [natsx](https://github.com/ZoneCNH/natsx)                 | v1.1.0      | spec/code/release/live | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | NATS L2 adapter；✅ .repo-contract.yaml；真实 dev auth live gate 已验证；GitHub Release 已发布                                                                          |
| [postgresx](https://github.com/ZoneCNH/postgresx)         | v1.1.0      | spec/code/release/live | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | PostgreSQL；✅ .repo-contract.yaml；live integration 通过；GitHub Release 已发布                                                                                         |
| [taosx](https://github.com/ZoneCNH/taosx)                 | v1.1.0      | spec/code/release/live | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | TDengine L2 adapter；真实 taosWS WebSocket 集成已验证；GitHub Release 已发布                                                                                              |
| [ossx](https://github.com/ZoneCNH/ossx)                   | v1.2.1 | spec/code/release      | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | Aliyun OSS L2 adapter；✅ v1.2.1 PR #8 已合并（真实 adapters/aliyun + 流式 + multipart + presign + 策略 + retry/circuit + observex hooks）；pkg/ossx 100% 覆盖；✅ BLK-010 resolved（2026-06-20） |
| [clickhousex](https://github.com/ZoneCNH/clickhousex)     | v1.1.0      | spec/code/release/live  | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | ClickHouse；OLAP 查询、批量写入；GitHub Release 已发布；CI 已部署+运行(Docker ClickHouse)                                                                                  |
| [contracts](https://github.com/ZoneCNH/contracts)         | v1.5.0 | spec/code/release       | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 跨域稳定端口/事件/DTO 契约；✅ P0 DTO 已固化（RegimeSnapshot/RegimeCard/DecisionCard + 3 Provider ports，PR #10）；✅ P1 SignalIntent DTO 升入（PR #12，2026-06-21）；ingestion contract §8.4 已实现 |
| [transportx](https://github.com/ZoneCNH/transportx)       | v1.3.0 | spec/code/release       | factory-ready   | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 应用通信底座规格基线；spec-only；✅ GitHub Release v1.1.1-spec 已发布                                                                                                                            |

> ✅ **版本 / release 注记**：公开文档是投影层；"版本（目标投影）"列为规划目标版本，已发布版本以"状态总览"表或 `.foundationx/status/index.json` + `.foundationx/blockers.json` 为准。当前 21-module projection 中 21/21 已发布 GitHub Release tag，21/21 impl；**0 open blockers，Foundation 21/21 factory-ready** ✅（BLK-009 bootstrap + BLK-010 ossx 均已 resolved，2026-06-20）。

> **成熟度语义说明（2026-06-14 v2 Trust Alignment）**：上表"进度"反映本仓库 Spec 管线评分（spec→code），不代表可投产等级（factory grade）。"子维度投影"列中 `pln/prm/cod` 对外仓模块为文档模板 pass-through 评分 **[P]**，不代表代码编译或测试已验证——权威代码质量见对应仓库 CI/GitHub Release。下表提供多维度成熟度视图；RELEASE=❌ 或存在 open blocker 的模块不得投影为 FACTORY=✅。

<details>
<summary>📊 基座多维成熟度展开（点击展开）</summary>

| 模块                          |     SPEC      |               IMPL                |             RELEASE              |        LIVE INT         |         EXT CI         |            ADOPT            |                     SOAK                      | FACTORY | 备注                                                                                                                                                       |
| ----------------------------- | :-----------: | :-------------------------------: | :------------------------------: | :---------------------: | :--------------------: | :-------------------------: | :-------------------------------------------: | :-----: | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| xlib_standard                 |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.0; GitHub Release 已发布; 9 CI workflows                                                                                                              |
| xlib_harness                  |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v0.1.6; GitHub Release 已发布; generate/scaffold/spec-lint/boundary/traceability/format-check; Release run 27855366871 与 main CI run 27855396013 通过; coverage 100.0%; pinned gitleaks CLI; CI 已部署                                                                  |
| xlib_evidence                 |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v0.2.4; GitHub Release v0.2.4 已发布; evidence collect/generate/validate/remote-evidence/report; release evidence assets 已归档; go test/race/vet/build/coverage 100.0%; CI 已部署                                                                          |
| xlibgate                      |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.0; CI 已部署; 8 workflows; 此前误标 v1.1.1                                                                                                            |
| kernel                        |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v1.0.0; 4 CI workflows; 13 下游消费者; 2026-06-18 代码侧验收全部通过（evidence: kernel-acceptance-20260618）；BLK-011 resolved（factory 闭合，Factory=true）                                                                             |
| configx                       |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v1.1.0; GitHub Release 已发布; v1.0 路线 5 项 MUST 已交付; 4 CI workflows; 2 下游消费者                                                                        |
| observex                      |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v0.3.4; Labels 改为 type alias（PR #14）; redisx/kafkax/clickhousex 已对齐使用 observex alias; GitHub Release 已发布                                                                        |
| testkitx                      |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   N/A   | v0.4.0; GitHub Release 已发布; 4 CI workflows; test-only — factory grade 不适用                                                                            |
| resiliencx                    |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v0.4.9; GitHub Release 已发布; 9 CI workflows; 2 下游消费者; 此前误标 v1.0.1 已修正                                                                        |
| schedulex                     |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v1.0.0; 6 CI workflows; 下游 smoke 通过; 1 下游消费者                                                                                                      |
| bootstrap                     |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v0.2.0; GitHub Release 已发布; 8 存储 adapter 构造全部实现; BLK-009 closed; factory-ready                  |
| redisx                        |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.1.0; GitHub Release 已发布; CI/release workflows 通过; Docker-backed + dev Redis 集成验证通过                                                           |
| kafkax                        |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.1.0; 8 CI workflows; 真实 broker gates 已验证                                                                                                           |
| natsx                         |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.3; GitHub Release 已发布; 6 CI workflows; dev auth live gate 已验证                                                               |
| postgresx                     |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.0; GitHub Release 已发布; 3 CI workflows; live integration 通过                                                              |
| taosx                         |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.1; GitHub Release 已发布; 8 CI workflows; 真实 taosWS WebSocket 集成已验证 |
| ossx                          |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.2.1; PR #8 merged; 真实 adapters/aliyun + 流式 + multipart + presign + retry/circuit + observex hooks; pkg/ossx 100% 覆盖; BLK-010 resolved ✅ |
| clickhousex                   |      ✅       |                ✅                 |                ✅                |           ✅            |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.8; GitHub Release 已发布; CI 已部署+运行(Docker ClickHouse)                                                  |
| contracts                     |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             ✅              |                      N/A                      |   ✅    | v1.5.0; P0 DTO 已固化（RegimeSnapshot/RegimeCard/DecisionCard + 3 Provider ports）；✅ P1 SignalIntent DTO 升入（PR #12，2026-06-21）                          |
| transportx                    |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.1.1-spec; GitHub Release 已发布; spec-only; 应用通信底座规格基线                                                      |
| domainx                       |      ✅       |                ✅                 |                ✅                |           N/A           |           ✅           |             N/A             |                      N/A                      |   ✅    | v1.0.1; L2.5 领域共享层; 公开 GitHub Release/tag v1.0.1 已观测并完成 fact-layer/trust release 对账; factory grade；live/soak N/A（纯值对象库） |
| > **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级） |

> **数据来源**：本表依据 `module/` 规格状态、`.foundationx/status/index.json`、`.foundationx/blockers.json`、公开 GitHub release 页面、GitHub Actions CI 运行状态与 FOUNDATION-DEPS.yaml 反向依赖图（ADOPT）投影。Open blocker 会下调 FACTORY 投影。
>
> **CI 构建状态**（最新 run，2026-06-15）：✅ 全部 20 模块已配置 CI workflows | Trust Alignment 5 模块本次部署: xlib_harness / xlib_evidence / ossx / clickhousex / domainx
>
> **管线评分注记**：上表 `pln/prm/cod` 列对外仓模块为 pass-through（未实际在目标 repo 运行验证），100 分仅表示 plan/prompt 文档模板完整，不代表代码可编译或已通过测试。CI 构建状态为此处补充机械证据。

</details>

### L2.5 · 领域共享层（5 个）

| 组件                                                          | 版本   | 进度     | 覆盖率要求 | 说明                                                                                                                                                        |
| ------------------------------------------------------------- | ------ | -------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [decimalx](https://github.com/ZoneCNH/decimalx)               | v1.0.0 | ████ 100% | 100%       | 高精度十进制类型；v1.0.0 GitHub Release 已发布，8 FR Done；factory grade；live/soak N/A（纯值对象库）                                                                   |
| [domainx](https://github.com/ZoneCNH/domainx)                 | v1.0.1 | ████ 100% | 100%       | 领域共享值对象：Order / Position / Trade / Portfolio / ExecutionReport；公开 v1.0.1 release/tag 已观测并完成 trust 对账；factory grade；live/soak N/A（纯值对象库） |
| [domain_market](https://github.com/ZoneCNH/domain_market)     | v1.1.0 | ████ 100% | 100%       | 市场数据域模型 + ProductLine/InstrumentKey/MarketFactEnvelope/MarketEventEnvelope canonical 类型 + IsValid() + exchange-neutral 命名；7 FR Done；factory grade；live/soak N/A（纯值对象库）                           |
| [domain_macro](https://github.com/ZoneCNH/domain_macro)       | v1.0.0 | ████ 100% | 100%       | 宏观数据域模型；v1.0.0 GitHub Release 已发布，7 FR Done；factory grade；live/soak N/A（纯值对象库）                                                                       |
| [domain_exchange](https://github.com/ZoneCNH/domain_exchange) | v1.0.0 | ████ 100% | 100%       | 交易域模型；v1.0.0 GitHub Release 已发布，7 FR Done；factory grade；live/soak N/A（纯值对象库）                                                                           |

<details>
<summary>📊 L2.5 领域共享层多维成熟度展开（点击展开）</summary>

| 模块            | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                                                                                                                                                             |
| --------------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| decimalx        |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ✅    | v1.0.0；100%；v1.0.0 GitHub Release 已发布，8 FR Done；factory grade；live/soak N/A（纯值对象库）                                                          |
| domainx         |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ✅    | v1.0.1；100%；领域共享值对象：Order/Position/Trade/Portfolio/ExecutionReport；公开 v1.0.1 release/tag 已观测并完成 trust 对账；factory grade；live/soak N/A（纯值对象库） |
| domain_market   |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ✅    | v1.1.0；100%；ProductLine/InstrumentKey/MarketFactEnvelope/MarketEventEnvelope canonical 类型；7 FR Done；factory grade；live/soak N/A（纯值对象库） |
| domain_macro    |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ✅    | v1.0.0；100%；v1.0.0 GitHub Release 已发布，7 FR Done；factory grade；live/soak N/A（纯值对象库）                                                          |
| domain_exchange |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ✅    | v1.0.0；100%；v1.0.0 GitHub Release 已发布，7 FR Done；factory grade；live/soak N/A（纯值对象库）                                                          |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 数据域 · 行情

| 组件                                                          | 架构类型     | 版本   | 进度     | 覆盖率要求 | 说明                  |
| ------------------------------------------------------------- | -------- | ------ | -------- | ---------- | --------------------- |
| [market_data](https://github.com/ZoneCNH/market_data)         | 独立进程 | v1.0.0 | ██░░ 30% | 100%       | dispatch 聚合（域入口）：Receiver + DualWriteSink；FR-MD-001~008；v1.0.0 released |
| [binance](https://github.com/ZoneCNH/binance)                 | C/S Module | v0.1.0      | ░░░░  5% | 100%       | 参考实现：bootstrap + client/server；Spec Approved；4产品线 |
| [okx](https://github.com/ZoneCNH/okx)                         | C/S Module      | v0.1.1 | ███░ 80% | 100%       | OKX CEX 行情采集；待升级 client/server 拆分 |
| [bybit](https://github.com/ZoneCNH/bybit)                     | C/S Module      | v0.1.1 | ███░ 80% | 100%       | Bybit CEX             |
| [bitget](https://github.com/ZoneCNH/bitget)                   | C/S Module      | v0.1.1 | ███░ 80% | 100%       | Bitget CEX            |
| [kucoin](https://github.com/ZoneCNH/kucoin)                   | C/S Module      | v0.1.1 | ███░ 80% | 100%       | KuCoin CEX            |
| [gate](https://github.com/ZoneCNH/gate)                       | C/S Module      | v0.1.1 | ███░ 80% | 100%       | Gate CEX              |
| [mexc](https://github.com/ZoneCNH/mexc)                       | C/S Module      | v0.1.1 | ███░ 80% | 100%       | MEXC CEX              |
| [htx](https://github.com/ZoneCNH/htx)                         | C/S Module      | v0.1.1 | ███░ 80% | 100%       | HTX CEX               |
| [coinbase](https://github.com/ZoneCNH/coinbase)               | C/S Module      | v0.1.1 | ███░ 80% | 100%       | Coinbase CEX          |
| [hyperliquid](https://github.com/ZoneCNH/hyperliquid)         | C/S Module      | v0.1.1 | ███░ 80% | 100%       | Hyperliquid DEX       |
| [lighter](https://github.com/ZoneCNH/lighter)                 | C/S Module      | v0.1.1 | ███░ 80% | 100%       | Lighter DEX           |
| [upbit](https://github.com/ZoneCNH/upbit)                     | C/S Module      | v0.1.1 | ███░ 80% | 100%       | Upbit CEX             |
| [coinglass](https://github.com/ZoneCNH/coinglass)             | C/S Module      | v0.1.1 | ███░ 80% | 100%       | 衍生品聚合数据        |

<details>
<summary>📊 数据域 · 行情多维成熟度展开（点击展开）</summary>

| 模块            | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                               |
| --------------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | ---------------------------------- |
| binance         |  ✅  |  ❌  |   ❌    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | C/S Module；v0.1.0；Spec Approved；4产品线          |
| okx             |  ✅  |  ✅  |   ✅    |   ⏳待验证 |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；OKX CEX；factory ❌ 原因：LIVE INT 待 market_data dispatch 集成验证 |
| bybit           |  ✅  |  ✅  |   ✅    |   ⏳待验证 |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Bybit CEX；factory ❌ 同上 |
| bitget          |  ✅  |  ✅  |   ✅    |   ⏳待验证 |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Bitget CEX；factory ❌ 同上 |
| kucoin          |  ✅  |  ✅  |   ✅    |   ⏳待验证 |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；KuCoin CEX；factory ❌ 同上 |
| gate            |  ✅  |  ✅  |   ✅    |   ⏳待验证 |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Gate CEX；factory ❌ 同上 |
| mexc            |  ✅  |  ✅  |   ✅    |   ⏳待验证 |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；MEXC CEX；factory ❌ 同上 |
| htx             |  ✅  |  ✅  |   ✅    |   ⏳待验证 |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；HTX CEX；factory ❌ 同上 |
| coinbase        |  ✅  |  ✅  |   ✅    |   ⏳待验证 |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Coinbase CEX；factory ❌ 同上 |
| hyperliquid     |  ✅  |  ✅  |   ✅    |   ⏳待验证 |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Hyperliquid DEX；factory ❌ 同上 |
| lighter         |  ✅  |  ✅  |   ✅    |   ⏳待验证 |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Lighter DEX；factory ❌ 同上 |
| upbit           |  ✅  |  ✅  |   ✅    |   ⏳待验证 |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；Upbit CEX；factory ❌ 同上 |
| coinglass       |  ✅  |  ✅  |   ✅    |   ⏳待验证 |  N/A   |  N/A  | N/A  |   ❌    | SDK；80%；衍生品聚合数据；factory ❌ 同上 |

> **factory ❌ 升级路径（12 SDK 共同）**：LIVE INT 需 `market_data` dispatch port adapter 集成验证真实 tick 数据流后方可触发批量 factory-ready 评估。非阻塞上层开发，豁免已记录。

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 数据域 · 宏观

| 组件                                                  | 架构类型 | 版本 | 进度     | 覆盖率要求 | 说明           |
| ----------------------------------------------------- | -------- | ---- | -------- | ---------- | -------------- |
| [macro_data](https://github.com/ZoneCNH/macro_data)   | 独立进程 | v1.0.0 | ██░░ 30% | 100%       | dispatch 聚合（域入口）：Receiver + DualWriteSink |
| [fred](https://github.com/ZoneCNH/fred)               | C/S Module | v0.1.1 | ███░ 80% | 100%       | 美联储 FRED 宏观数据采集 |
| [treasury](https://github.com/ZoneCNH/treasury)       | C/S Module | v0.1.1 | ███░ 80% | 100%       | 美国财政部     |
| [yield_curve](https://github.com/ZoneCNH/yield_curve) | C/S Module | v0.1.1 | ███░ 80% | 100%       | 收益率曲线     |
| [bea](https://github.com/ZoneCNH/bea)                 | C/S Module | v0.1.1 | ███░ 80% | 100%       | 美国经济分析局 |
| [ecb](https://github.com/ZoneCNH/ecb)                 | C/S Module | v0.1.1 | ███░ 80% | 100%       | 欧洲央行       |
| [uk_cb](https://github.com/ZoneCNH/uk_cb)             | C/S Module | v0.1.1 | ███░ 80% | 100%       | 英国央行       |
| [japan_cb](https://github.com/ZoneCNH/japan_cb)       | C/S Module | v0.1.1 | ███░ 80% | 100%       | 日本央行       |
| [eastmoney](https://github.com/ZoneCNH/eastmoney)     | C/S Module | v0.1.1 | ███░ 80% | 100%       | 东方财富 A 股  |
| [jin10](https://github.com/ZoneCNH/jin10)             | C/S Module | v0.2.0 | ███░ 80% | 100%       | 金十数据 SDK：openapi（宏观数据）+ flash（实时快讯） |
| [yahoo](https://github.com/ZoneCNH/yahoo)             | C/S Module | v0.1.1 | ███░ 80% | 100%       | Yahoo Finance  |

<details>
<summary>📊 数据域 · 宏观多维成熟度展开（点击展开）</summary>

| 模块        | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                  |
| ----------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | --------------------- |
| fred        |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；美联储 FRED 数据 |
| treasury    |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；美国财政部数据   |
| yield_curve |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；收益率曲线       |
| bea         |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；美国经济分析局   |
| ecb         |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；欧洲央行         |
| uk_cb       |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；英国央行         |
| japan_cb    |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；日本央行         |
| eastmoney   |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；东方财富 A 股    |
| jin10       |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.2.0；金十数据 SDK：openapi + flash |
| yahoo       |  ✅  |  ✅  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 80%；v0.1.1；Yahoo Finance    |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 数据域 · 另类

| 组件                                                            | 版本 | 进度    | 覆盖率要求 | 说明                     |
| --------------------------------------------------------------- | ---- | ------- | ---------- | ------------------------ |
| [alternative_data](https://github.com/ZoneCNH/alternative_data) | v0.1.0 | ░░░░ 5% | 100%       | 链上、社交情绪、新闻 NLP |

<details>
<summary>📊 数据域 · 另类多维成熟度展开（点击展开）</summary>

| 模块             | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                                      |
| ---------------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | ----------------------------------------- |
| alternative_data |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；链上数据、社交情绪、新闻 NLP 均未开始 |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 分析域

> 分析域全部模块为**独立进程（非 C/S）**，bootstrap 接入，无 client/server 拆分。

| 组件                                                      | 架构类型 | 版本         | 进度     | 覆盖率要求 | 说明                                                                     |
| --------------------------------------------------------- | -------- | ------------ | -------- | ---------- | ------------------------------------------------------------------------ |
| [factor_engine](https://github.com/ZoneCNH/factor_engine) | 独立进程 | v0.1.0       | ░░░░ 5%  | 100%       | 因子计算引擎                                                             |
| [feature_store](https://github.com/ZoneCNH/feature_store) | 独立进程 | v0.1.0       | ░░░░ 5%  | 100%       | 特征存储与版本管理                                                       |
| [factor_eval](https://github.com/ZoneCNH/factor_eval)     | 独立进程 | v0.1.0       | ░░░░ 5%  | 100%       | 因子评估                                                                 |
| [market_regime](https://github.com/ZoneCNH/market_regime) | 独立进程 | v0.2.0       | ████████ 70% | 100%       | 市场状态识别（S1-S7）；BarWindow+Subscriber+domain-market 适配器，12 tests PASS |
| [macro_regime](https://github.com/ZoneCNH/macro_regime)   | 独立进程 | v0.2.0       | ████████ 70% | 100%       | 宏观经济体制识别（M1-M7）；MacroInformationSet mapper+ClassifyFromSet，13 tests PASS  |
| [ms_brain](https://github.com/ZoneCNH/ms_brain)           | 独立进程 | v1.6.6       | ░░░░ 5%  | 100%       | M×S 系统架构分析体系                                                     |
| [regime_engine](https://github.com/ZoneCNH/regime_engine) | 独立进程 | v1.0.0       | ████ 60% | 100%       | M×S 联合决策引擎（P0 DTO 桥接层，RegimeSnapshot+RegimeCard→DecisionCard，13 tests PASS） |
| [flowx](https://github.com/ZoneCNH/flowx)                 | 独立进程 | v0.1.0-draft | ░░░░ 5%  | 100%       | 数据流管线引擎 — 流式 ETL、窗口聚合、背压控制（7 FR, SPEC draft）        |

<details>
<summary>📊 分析域多维成熟度展开（点击展开）</summary>

| 模块          | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                               |
| ------------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | ---------------------------------- |
| factor_engine |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现                 |
| feature_store |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现                 |
| factor_eval   |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现                 |
| market_regime |  ❌  |  ⚠️  |   ⚠️    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.2.0；70% S引擎，BarWindow+Subscriber+adapter接入，12 tests PASS |
| macro_regime  |  ❌  |  ⚠️  |   ⚠️    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.2.0；70% M引擎，mapper+ClassifyFromSet接入，13 tests PASS           |
| ms_brain      |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现                 |
| regime_engine |  ❌  |  ⚠️  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v1.0.0；60% P0桥接完成，13 tests PASS，contracts v1.4.0 接入    |
| flowx         |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0-draft；7 FR，SPEC draft     |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 决策域

| 组件                                                          | 版本         | 进度    | 覆盖率要求 | 说明                                                                |
| ------------------------------------------------------------- | ------------ | ------- | ---------- | ------------------------------------------------------------------- |
| [signal_factory](https://github.com/ZoneCNH/signal_factory)   | v0.1.0       | ████ 40% | 100%       | 信号生成工厂，消费 DecisionCard→SignalIntent[]，冲突门+强度映射，5 tests PASS |
| [backtest_engine](https://github.com/ZoneCNH/backtest_engine) | v0.1.0       | ░░░░ 5% | 100%       | ~~占位~~ → [**backtestx**](https://github.com/ZoneCNH/backtestx)  |
| [optimizer](https://github.com/ZoneCNH/optimizer)             | v0.1.0       | ░░░░ 5% | 100%       | 参数优化                                                            |
| [backtestx](https://github.com/ZoneCNH/backtestx)             | v0.1.0-draft | ░░░░ 5% | 100%       | 回测引擎 — 事件驱动回测、Walk-Forward、蒙特卡洛（7 FR, SPEC draft） |
| [strategyx](https://github.com/ZoneCNH/strategyx)             | v0.1.0-draft | ░░░░ 5% | 100%       | 策略工厂 — 策略注册、参数管理、信号组合（7 FR, SPEC draft）         |
| [maestro](https://github.com/ZoneCNH/maestro)                 | v0.1.0-draft | ░░░░ 5% | 100%       | 工作流编排引擎 — DAG 工作流、状态机、错误恢复（9 FR, SPEC draft）   |

<details>
<summary>📊 决策域多维成熟度展开（点击展开）</summary>

| 模块            | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                           |
| --------------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | ------------------------------ |
| signal_factory  |  ❌  |  ⚠️  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0；40% 骨架，DecisionCard→SignalIntent，5 tests PASS |
| backtest_engine | [P]废弃 | [P]废弃 |  [P]废弃  |  [P]废弃  | [P]废弃 | [P]废弃 | [P]废弃 | ~~占位~~ → backtestx | 仅创建占位，已迁移至 backtestx；不参与质量评估 |
| optimizer       |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现             |
| backtestx       |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0-draft；7 FR，SPEC draft |
| strategyx       |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0-draft；7 FR，SPEC draft |
| maestro         |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0-draft；9 FR，SPEC draft |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 执行域

| 组件                                                            | 版本         | 进度    | 覆盖率要求 | 说明                                                         |
| --------------------------------------------------------------- | ------------ | ------- | ---------- | ------------------------------------------------------------ |
| [risk_engine](https://github.com/ZoneCNH/risk_engine)           | ~~占位~~     | ░░░░ 5% | 100%       | ~~风险管理引擎~~ → [**riskx**](https://github.com/ZoneCNH/riskx) |
| [order_engine](https://github.com/ZoneCNH/order_engine)         | ~~占位~~     | ░░░░ 5% | 100%       | ~~订单执行引擎~~ → [**orderx**](https://github.com/ZoneCNH/orderx) |
| [portfolio_engine](https://github.com/ZoneCNH/portfolio_engine) | v0.1.0       | ░░░░ 5% | 100%       | ~~占位~~ → [**positionx**](https://github.com/ZoneCNH/positionx)  |
| [settlement](https://github.com/ZoneCNH/settlement)             | v0.1.0       | ░░░░ 5% | 100%       | 结算与对账                                                   |
| [riskx](https://github.com/ZoneCNH/riskx)                       | v0.1.0 | ████░ 40% | 100%       | 风控引擎 — ✅ 最小实现（仓位上限/最大持仓/熔断门禁，7 tests PASS，消费 contracts.SignalIntent）  |
| [orderx](https://github.com/ZoneCNH/orderx)                     | v0.1.0-draft | ░░░░ 5% | 100%       | 订单管理器 — 订单生命周期、SOR、状态机（7 FR, SPEC draft）   |
| [positionx](https://github.com/ZoneCNH/positionx)               | v0.1.0-draft | ░░░░ 5% | 100%       | 仓位管理器 — 实时仓位追踪、PnL、敞口监控（7 FR, SPEC draft） |

<details>
<summary>📊 执行域多维成熟度展开（点击展开）</summary>

| 模块             | SPEC | IMPL | RELEASE | LIVE INT | EXT CI | ADOPT | SOAK | FACTORY | 备注                           |
| ---------------- | :--: | :--: | :-----: | :------: | :----: | :---: | :--: | :-----: | ------------------------------ |
| risk_engine      | [P]废弃 | [P]废弃 | [P]废弃 |  [P]废弃  | [P]废弃 | [P]废弃 | [P]废弃 | ~~占位~~ → riskx | 仅创建占位，已迁移至 riskx；不参与质量评估 |
| order_engine     | [P]废弃 | [P]废弃 | [P]废弃 |  [P]废弃  | [P]废弃 | [P]废弃 | [P]废弃 | ~~占位~~ → orderx | 仅创建占位，已迁移至 orderx；不参与质量评估 |
| portfolio_engine | [P]废弃 | [P]废弃 | [P]废弃 |  [P]废弃  | [P]废弃 | [P]废弃 | [P]废弃 | ~~占位~~ → positionx | 仅创建占位，已迁移至 positionx；不参与质量评估 |
| settlement       |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | 5%；仅创建，无实现             |
| riskx            |  ❌  |  ❌  |   ✅    |   N/A    |  N/A   |  N/A  | N/A  |   ⚠️    | v0.1.0；最小实现（仓位检查+熔断，7 tests PASS）；消费 contracts.SignalIntent P1 DTO |
| orderx           |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0-draft；7 FR，SPEC draft |
| positionx        |  ❌  |  ❌  |   N/A   |   N/A    |  N/A   |  N/A  | N/A  |   ❌    | v0.1.0-draft；7 FR，SPEC draft |

> **维度说明**：SPEC=规格完成 | IMPL=实现完成 | RELEASE=tag/release/manifest 一致 | LIVE INT=真实服务集成（非 mock） | EXT CI=外部 CI artifact | ADOPT=下游模块真实采用 | SOAK=生产或类生产长时间运行 | FACTORY=factory_grade_allowed（最高综合等级）

</details>

### 入口 · 横切

| 组件                                              | 域   | 版本   | 进度                            | 覆盖率要求 | 说明                                                      |
| ------------------------------------------------- | ---- | ------ | ------------------------------- | ---------- | --------------------------------------------------------- |
| [x.go](https://github.com/ZoneCNH/x.go)           | 入口 | v0.0.1 | ███░ 80%                        | 100%       | 组合根，2.8MB/33 项                                       |
| [composer](https://github.com/ZoneCNH/composer)   | 入口 | v0.2.0 | ████████░ 85%                   | 100%       | 数据域组合根：25 进程 + HTTP health + Docker Compose；✅ SinkPort 适配器（14 tests）；✅ RegimeCoordinator v0.2.0（dispatch→regime→engine→signal_factory 全链路，6 tests PASS） |
| [alertx](https://github.com/ZoneCNH/alertx)       | 横切 | v0.1.0 | ░░░░ 5%                         | 100%       | 告警引擎                                                  |
| [observex](https://github.com/ZoneCNH/observex)   | 横切 | v0.3.4 | 全管线 --force pass (spec→code) | 100%       | 可观测性（同时归属基座）；✅ v0.3.4 GitHub Release 已发布；Labels type alias；redisx/kafkax/clickhousex 已对齐 |
| [module](./module/README.md)                      | 独立 | -      | -                               | 100%       | 项目技术规范与接口定义                                    |

---

## 总览仪表盘

```text
组件总数: 77    已有: 58    已创建: 19    平均进度: 58%

进度分布 (domain-sum 口径, 含废弃占位):
  已验证数字 — 由 python3 scripts/audit-status.py --network 最终确认

版本覆盖: ⏳ 待审计验证
```

### 按域统计

| 域                     | 总数   | 已有   | 已创建 | 平均进度                           | 架构组成                                              |
| ---------------------- | ------ | ------ | ------ | ---------------------------------- | ----------------------------------------------------- |
| 基座                   | 20     | 20     | 0      | Spec→Code 投影完成；Foundation 整体非 factory | 20 独立 module                                                    |
| L2.5 领域共享层        | 5      | 5      | 0      | 100%                               | 5 纯值对象库 (factory grade；live/soak N/A)            |
| 数据域 · market_data   | 14     | 13     | 1      | 80%                                | 13 C/S Module + 1 独立进程 (dispatch)                                      |
| 数据域 · macro_data    | 11     | 11     | 0      | 80%                                | 10 C/S Module + 1 独立进程 (dispatch)                                      |
| 数据域 · 另类          | 1      | 0      | 1      | 5%                                 | 1 (v0.1.0)                                            |
| 分析域                 | 8      | 3      | 5      | 40%                                | 8 独立进程（market_regime/macro_regime v0.2.0；regime_engine v1.0.0） |
| 决策域                 | 6      | 1      | 5      | 10%                                | 6 (signal_factory v0.1.0 ✅；其余 v0.1.0+)              |
| 执行域                 | 7      | 1      | 6      | 10%                                | 7 (riskx v0.1.0 ✅ 最小实现；其余 v0.1.0+)              |
| 入口                   | 2      | 2      | 0      | 85%                                | 2 (x.go v0.0.1；composer v0.2.0 ✅ Coordinator+SinkPort) |
| 横切                   | 2      | 1      | 1      | 53%                                | 2 (observex, alertx)                                  |
| 独立                   | 1      | 1      | 0      | -                                  | 0                                                     |
| **合计**               | **77** | **58** | **19** | **58%**                            | **73**                                                |

> ⚠️ **废弃占位说明**：总数 77（新增 macro_data dispatch 独立进程）；4 个历史占位仓库（`backtest_engine`→决策域、`risk_engine`/`order_engine`/`portfolio_engine`→执行域）已迁移至新名称（backtestx/riskx/orderx/positionx），多维成熟度表中已标注 **[P]废弃**，不参与质量评估。活跃组件 73 个。

---

## 域健康度

### 🟢 基座（健康）

- 组件：19 个（不含 L2.5；机器事实层另将 `domainx` 作为 L2.5 模块计入 20-module projection）；
  Spec→Code 管线投影已闭合，但不等于 Foundation 整体 factory grade。
 - 核心模块全部 21/21 GitHub Release tag 已发布，21/21 impl，**0 open blockers，Foundation 21/21 factory-ready** ✅（BLK-009 bootstrap + BLK-010 ossx 均已 resolved，2026-06-20）。
 - 存储层全部模块 GitHub Release 已发布、CI 已部署、live integration 已验证。
 - **阻塞项**：BLK-009 ✅ closed（bootstrap v0.2.0，2026-06-20）；BLK-010 ✅ resolved（ossx v1.2.1 PR #8 merged，2026-06-20）；BLK-011 已 resolved（kernel factory 闭合）。BLK-001~008 历史项已闭合。

### 🟢 L2.5 领域共享层（健康）

- 组件：5 个，进度 80%
- Phase 0 已完成，当前已建模的上层模块已依赖此层

### 🟢 数据域 · market_data（健康）

- market_data 域：14 组件（13 C/S Module + 1 独立进程 dispatch）
- dispatch（market_data）：独立进程，v1.0.0，Receiver + DualWriteSink，进度 30%
- C/S Module（13）：binance 为参考实现（v0.2.0，bootstrap + client/server + 4 产品线）；其余 12 个 v0.1.1，待升级
- **factory 升级路径**：13 C/S Module 需完成 client/server 拆分 + bootstrap 接入 + dispatch 集成验证后批量触发 factory-ready 评估

### 🟡 数据域 · macro_data（注意）

- macro_data 域：11 组件（10 C/S Module + 1 独立进程 dispatch）
- dispatch（macro_data）：独立进程，v1.0.0，Receiver + DualWriteSink
- C/S Module（10）：全部 v0.1.1 tagged release，待升级 bootstrap + client/server 拆分
- 6 个央行数据源结构高度相似（fred / treasury / bea / ecb / uk_cb / japan_cb）
- **评估结论（2026-06-16）**：各模块保持独立架构，不合并；建议在 contracts 中提取共享 DataSource 接口统一契约

### 🔴 数据域 · 另类（阻塞）

- 组件：1 个，仅创建（5%）
- **阻塞项**：链上数据、社交情绪、新闻 NLP 尚未开始实现

### 🔴 分析域（阻塞）

- 组件：8 个，**全部为独立进程（非 C/S）**，bootstrap 接入，无 client/server 拆分
- 三引擎（market_regime/macro_regime v0.2.0，regime_engine v1.0.0）已完成 P0 桥接；dispatch→regime SinkPort 适配器 ✅（composer v0.1.0，MarketRegimeSink/MacroRegimeSink，14 tests PASS），5 个处于早期（5%）
- **阻塞项**：factor_engine / feature_store / factor_eval / ms_brain 均未实现到可用闭环；flowx SPEC 已创建（v0.1.0-draft）
- **里程碑**：分析域三引擎 contracts v1.4.0 P0 DTO 接入完成，M×S→DecisionCard 链路打通

### 🔴 决策域（阻塞）

- signal_factory v0.1.0 骨架完成（40%）：DecisionCard→SignalIntent 链路打通；~~backtest_engine~~ / optimizer 仅创建（5%）
- backtestx / strategyx / maestro SPEC 已创建（v0.1.0-draft）
- **阻塞项**：依赖分析域产出因子；signal_factory 待接入真实因子信号

### 🔴 执行域（阻塞）

- 组件：7 个，全部仅创建（5%）
- riskx / orderx / positionx SPEC 已创建（v0.1.0-draft）
- **阻塞项**：依赖决策域产出信号

### 🟡 入口（注意）

- x.go 已有（80%，v0.0.1）；2.8MB 体量已核实为治理/工具 CLI（goalcli+templatex），非 Composition Root
- **composer v0.1.0** ✅（75%）：数据域组合根，25 进程（23 adapter + market-data + macro-data）+ HTTP health + Docker Compose；dispatch→regime SinkPort 适配器已完成（MarketRegimeSink/MacroRegimeSink）
- **待完成**：regime_engine → signal_factory → riskx 完整链路集成

### 🟡 横切（注意）

- alertx 仅创建（5%），observex 已完成（100%，v0.3.4，✅ GitHub Release 已发布）
- observex 同属基座和横切，职责边界通过 ADR 明确（见 `module/observex/ADR-dual-attribution.md`，R7 已闭环）

---

## 风险清单

### 🔴 高风险

| #   | 风险                                            | 影响             | 建议                         |
| --- | ----------------------------------------------- | ---------------- | ---------------------------- |
| R1  | 分析域/决策域/执行域核心链路低完成度（多数 5%） | 核心业务链路断裂 | 当前最高优先级，聚焦 Phase 1 |
| R2  | alternative_data 仅创建（5%）                   | 另类数据能力缺失 | 可延后，不影响核心链路       |

### 🟡 中风险

| #   | 风险                                    | 影响                              | 建议                                                                   |
| --- | --------------------------------------- | --------------------------------- | ---------------------------------------------------------------------- |
| ~~R3~~  | ~~x.go 2.8MB 体量异常~~                 | ~~可能违反组合根边界~~            | ✅ **已核实**：x.go = 治理/工具 CLI（goalcli+templatex），非 Composition Root；composer 独立仓库承担数据域组合根 |
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

- [ ] Phase 1（分析域）仍待完成收口 → 阻塞 Phase 2/3/4/5
- [x] ~~x.go 体量待核实~~ ✅ **已核实**：x.go = 治理 CLI，非组合根；composer v0.1.0 承担数据域组合根

### 下一步行动

1. **聚焦 Phase 1**：先固化 MarketDataProvider / FactorInput / FactorOutput，再实现 factor_engine → feature_store → factor_eval
2. **同步 contracts 契约口径**：`SignalIntent` 已升入 contracts；P1 / P2 兼容投影别名（`RegimeSnapshotEvent` / `RegimeCardEvent` / `DecisionCardEvent` / `MarketRegimePort` / `MacroRegimePort` / `RegimeEnginePort`）已在 contracts 补齐；当前待推进的是 contracts Approved 与跨域 AC / TC 收口
3. ~~**版本化 SDK**~~：✅ 已完成 — 18 仓库 v0.1.1 tagged release（2026-06-16）
4. ~~**统一宏观适配器**~~：✅ 已评估 — 保持独立模块架构，11 仓库全部 v0.1.1 tagged release（2026-06-16）
5. ~~**清理仓库卫生**（R10）~~：✅ 已完成（2026-06-07）
6. ~~**移除本地链接**（R11）~~：✅ 已完成（2026-06-07）
7. **重整仓库命名**（R12）：评估按 `foundation-*`/`adapter-*`/`engine-*`/`lab-*` 前缀重命名的可行性

---

## 文档同步检查

| 检查项           | README | ARCHITECTURE | STATUS    | 一致性 |
| ---------------- | ------ | ------------ | --------- | ------ |
| 组件总数         | 74     | 75           | 75        | ⚠️ ARCH/STATUS +1 (新增 macro_data dispatch) |
| market_data 数量 | 14     | 14          | 14        | ✅     |
| macro_data 数量  | 10     | 11           | 11        | ⚠️ ARCH/STATUS +1 (新增 macro_data dispatch) |
| L2.5 组件        | 5      | 5            | 5         | ⏳ 待验证 |
| 分析域组件       | 8      | 8            | 8         | ⏳ 待验证 |
| 决策域组件       | 6      | 6            | 6         | ⏳ 待验证 |
| 横切组件         | 2      | 2            | 2         | ⏳ 待验证 |

注：macro_data 域从 10 增至 11（新增 dispatch 独立进程），ARCHITECTURE.md 同步新增 macro_data 行。README.md 暂未同步（后续单开 PR）。STATUS 域统计 domain-sum 口径（77）与 unique-link 口径不完全等同（observex 计入基座+横切 2 域，废弃占位不计入 unique-link）。

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
| contracts     | 100  |  100   |  100  | 100  |  100   | 100  | ✅ P0 DTO 2026-06-20 |
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
| bootstrap     | ~90  |  N/A   |  N/A  | N/A  |  N/A   | N/A  |
| taosx         | ~88  |  100   | ~88   | 100  |  100   | 100  |
| testkitx      | 100  |  100   |  100  | 100  |  100   | 100  |
| transportx    |  84  |  100   |  100  | 100  |  100   | 100  |
| xlib_evidence |  83  |  100   |  100  | 100  |  100   | 100  |
| xlib_harness  |  83  |  100   |  97   | 100  |  100   | 100  |
| xlib_standard | 100  |   80   |  98   | 100  |  100   | 100  |
| xlibgate      | 100  |  100   |  100  | 100  |  100   | 100  |

> 剩余 7 模块需 SPEC 级内容修复（spec 缺 WHEN/THEN、章节等）。prompt/code 外仓模块为 pass-through。xlib_standard 为快照格式除外。
