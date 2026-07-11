# FoundationX 25 模块生产发布就绪深度审计

- 审计日期：2026-07-11。[COMPUTED, HIGH]
- 审计范围：标准 4 模块、L0 1 模块、L1/测试/组装 6 模块、存储 7 模块、契约 2 模块、L2.5 5 模块。[COMPUTED, HIGH]
- 审计方式：agent team 分组只读取证，主 agent 交叉验证依赖、版本、CI、Release、消费者安装与治理事实。[COMPUTED, HIGH]
- 任务追踪：Beads ZoneCNH-gtst。[COMPUTED, HIGH]
- 审计基准：[CONSTITUTION.md](../CONSTITUTION.md)、[BASELINE.yaml](../BASELINE.yaml)、[FOUNDATION-DEPS.yaml](../module/FOUNDATION-DEPS.yaml)、[registry.yaml](../module/registry.yaml)。[COMPUTED, HIGH]

## 1. 结论

**当前 25 个 checkout 中，零个满足“现在即可无条件发布到生产”的完整门禁。** [COMPUTED, HIGH]

**7 个模块为 CONDITIONAL，18 个模块为 NO-GO，GO 为 0。** [COMPUTED, HIGH]

这里的 CONDITIONAL 只表示“已有可消费版本，或核心代码与测试较强”；它不表示当前 HEAD 可发布，也不表示 Release Done 或 Goal Done。[FRAME, HIGH]

当前 fleet 的主要问题不是 Go module 循环依赖，而是发布身份、版本血缘、证据真实性、CI fail-open、语义重复和复制式治理耦合。[COMPUTED, HIGH]

### 1.1 最强反论证：独立解耦不等于零依赖

如果把“每个模块必须独立解耦”解释成“模块之间不得有任何 import”，它会与现有治理目标直接冲突：domainx 需要 decimalx 的精确数值语义，domain_exchange 需要 domainx 与 domain_market 的唯一领域语义，bootstrap 需要在组合 seam 注入运行时 adapter。[FRAME, HIGH]

本报告采用以下可验证定义：

- 每个模块有唯一仓库身份、唯一 Go module identity、独立版本与独立 Release evidence。[FRAME, HIGH]
- 依赖图必须单向、无环、只走权威矩阵允许的下行边。[FRAME, HIGH]
- 同一领域语义只存在一个 SSOT；不得通过复制类型或复制治理实现来伪造“无依赖”。[FRAME, HIGH]
- interface 应小而深；adapter 位于稳定 seam，基础设施细节不泄漏到领域共享层。[FRAME, HIGH]
- 模块可独立构建、测试、发布和回滚；一个同层模块的新版本不得无证据地拖垮其他模块。[FRAME, HIGH]

按这个定义，当前 Go module 图机械无环，但 fleet 尚未实现独立发布与语义解耦。[COMPUTED, HIGH]

## 2. 裁决口径

| 裁决 | 含义 |
| --- | --- |
| GO | 当前受审 HEAD 的 Code/Test/Release/Goal 证据均闭合，可直接推进发布。[FRAME, HIGH] |
| CONDITIONAL | 已有可消费基线或核心实现较强，但当前 HEAD 的 CI、版本、manifest、分支保护或外部证据未闭合；当前仍不可发布。[FRAME, HIGH] |
| NO-GO | 存在可重复的构建、测试、身份、安全、协议、数据正确性或 release evidence 阻断。[FRAME, HIGH] |

纯 library 的 Goal Done 不要求虚构“已部署”；它应由真实下游 adoption、兼容性、性能预算和故障/边界证据证明。[FRAME, HIGH]

治理评分、Approved 状态、GitHub tag 或单次绿色测试都不能单独翻译成生产可用性。[FRAME, HIGH]

## 3. Fleet 总览

### 3.1 逐模块裁决

下表每行均由本地命令、runtime 源码、GitHub API/Actions/Release 或消费者 smoke 直接计算；具体证据在后续章节展开。[COMPUTED, HIGH]

| 层 | 模块 | 当前 Code/Test | 已有发布基线 | 当前发布裁决 | 最高阻断 |
| --- | --- | --- | --- | --- | --- |
| 标准 | xlib_standard | 本地 test/race/vet/lint/coverage 100% 通过 | v1.0.2 存在 | NO-GO | 自身 evidence usable=false、required release gates not_run、release-check 被禁用、工作区不净。[COMPUTED, HIGH] |
| 标准 | xlib_harness | test/race/vet 通过，coverage 98.2%，lint 失败 | v0.2.1 Release 失败 | NO-GO | 低于自身 100% 门槛、版本仍写 v0.2.0、main 未保护。[COMPUTED, HIGH] |
| 标准 | xlib_evidence | test/race/vet/coverage 100% 通过 | v0.3.0 Release 失败 | NO-GO | Attestation Results map 可被外部 alias 修改，Release govulncheck 失败。[COMPUTED, HIGH] |
| 标准 | xlibgate | 本地旧树 test/race/vet/lint/coverage 82.7% 通过 | v1.3.0 Release 失败 | NO-GO | 自身 runner-policy 阻断自身 workflow，manifest/evidence 失败。[COMPUTED, HIGH] |
| L0 | kernel | 当前 fix 分支 test/race 失败 | v1.1.1 有 manifest 资产 | NO-GO | 当前分支删除 govulncheck 安装但 make ci 仍强制；公共零 panic 声明也有反例。[COMPUTED, HIGH] |
| L1 | configx | race/vet/boundary/govuln 通过，coverage 96.5% | v1.1.0 可消费 | CONDITIONAL | 当前 workflow 产生零 job 失败；manifest commit 不绑定 tag。[COMPUTED, HIGH] |
| L1 | observex | race/vet/boundary/govuln 通过，coverage 99.9% | v0.3.4 可消费 | CONDITIONAL | tag 内 Version=v0.3.2；HEAD/manifest v0.3.6 但无对应 tag/Release；主 CI 未生成。[COMPUTED, HIGH] |
| L1 | resiliencx | race/vet/boundary/govuln 与六策略覆盖 100% | v1.0.2 可消费 | CONDITIONAL | 当前 checkout 版本回退、远端 release score 9.0 小于 9.8、标准源职责漂移。[COMPUTED, HIGH] |
| L1 | schedulex | race/vet/boundary/govuln 通过，coverage 97.8% | v1.0.0 可消费 | CONDITIONAL | 当前 release-check 缺工具闭包，manifest 不能绑定 commit/checks。[COMPUTED, HIGH] |
| L1 Assembly | bootstrap | build/test/race/vet 失败 | v0.2.0/v0.2.2 消费均失败 | NO-GO | 不存在的 foundationx/observex 依赖与 taosx API 漂移使整体不可编译。[COMPUTED, HIGH] |
| L1 test-only | testkitx | race/vet/boundary/govuln 通过，coverage 92.9% | v1.0.0 可消费 | NO-GO | tag 内 Version=v0.4.0，当前 CI 未生成，版本完整性不成立。[COMPUTED, HIGH] |
| 存储 | redisx | clean dependency resolution 失败 | v1.1.2 Release 存在 | NO-GO | 依赖不存在的 observex v1.0.0；integration 默认 skip=0；版本/manifest 多点漂移。[COMPUTED, HIGH] |
| 存储 | kafkax | unit/race/vet/boundary 通过，coverage 约 73.8% | v1.1.2 仅 tag | NO-GO | 四个真实 broker gate 明确 status=gap，release 链未调用，main CI/Docker 失败。[COMPUTED, HIGH] |
| 存储 | natsx | embedded NATS 测试较强，coverage 约 85.4% | v1.0.5 仅 tag | NO-GO | live/TLS/SLO/正式 arbiter 未闭合，manifest 缺失，公开 interface 泄漏 nats.go 类型。[COMPUTED, HIGH] |
| 存储 | postgresx | unit/race/vet/boundary/真实 PG17 CI/coverage 100% 通过 | v1.1.2 Release 存在 | CONDITIONAL | VERSION/源码 Version 仍 v1.1.0，release workflow 条件错误，版本权威未闭合。[COMPUTED, HIGH] |
| 存储 | taosx | unit/race/vet/boundary 通过，pkg coverage 约 79% | v1.1.2 Release 存在 | NO-GO | CI integration 仅模板渲染；100% 声明与 75% gate 冲突；Version/manifest 仍 v1.0.5。[COMPUTED, HIGH] |
| 存储 | ossx | unit/race/vet 与 pkg coverage 100% 通过 | v1.2.1 仅 tag | NO-GO | 当前 workflow YAML 无效；live/release-tag/soak/downstream evidence 明确未归档。[COMPUTED, HIGH] |
| 存储 | clickhousex | unit/race/vet/真实 ClickHouse main CI/coverage 100% 通过 | v1.0.9 Release 存在 | NO-GO | 当前 workflow YAML 无效；幽灵版本 v1.0.10；写重试缺幂等契约；T4 evidence blocked。[COMPUTED, HIGH] |
| 契约 | contracts | race/vet/boundary/govuln 通过，coverage 81.8% | v1.5.0 仅 tag；Latest Release v0.4.7 | NO-GO | gRPC 语义与宪法 HTTP+Gin 冲突；无 v1.5.0 manifest/Release；复制标准源实现。[COMPUTED, HIGH] |
| 契约 | transportx | 核心 pkg coverage 0% | v0.0.1 Release；v1.1.1-spec 仅 tag | NO-GO | go.mod 声明 xlib-standard，按 transportx 路径不可消费；Runtime Pending。[COMPUTED, HIGH] |
| L2.5 | decimalx | 当前 build/test/race/vet 通过，coverage 80.5%；staticcheck/lint 失败 | v1.0.0 消费者 race+coverage 81.2% 通过 | CONDITIONAL | latest manifest 仍 v0.2.0，main 未保护，当前静态门禁失败。[COMPUTED, HIGH] |
| L2.5 | domainx | 当前 build/test/race/vet/lint 通过，coverage 91.1% | v1.0.1 消费者通过 | CONDITIONAL | Version 常量 v1.0.0、tag 与 main 历史 diverged、CI 使用禁用 runner、无 manifest。[COMPUTED, HIGH] |
| L2.5 | domain_market | 当前 feature checkout test/race 通过，coverage 53.2%，staticcheck 失败 | v1.1.0 消费者 race 通过但 coverage 51.1% | NO-GO | 低覆盖、module path 错、release commit CI 失败、基础设施与订单语义泄漏。[COMPUTED, HIGH] |
| L2.5 | domain_macro | 当前 main test/race 通过但实现回退 | v1.0.1 消费者 race+coverage 81.2% 通过 | NO-GO | main 无 CI、公开 float64/Yahoo DTO/可变 slice；release 与 main diverged；Version 回退。[COMPUTED, HIGH] |
| L2.5 | domain_exchange | 当前 main build/test/race/vet 均失败 | v1.0.0 消费者 race+coverage 80.0% 通过 | NO-GO | go.sum checksum mismatch、13 方法巨型 interface、Credential/重复领域类型、无 CI。[COMPUTED, HIGH] |

### 3.2 层级汇总

以下汇总由上一表 25 个逐模块裁决计数得到。[COMPUTED, HIGH]

| 范围 | GO | CONDITIONAL | NO-GO |
| --- | ---: | ---: | ---: |
| 标准 + L0 | 0 | 0 | 5 |
| L1 + 契约 | 0 | 4 | 4 |
| 存储 | 0 | 1 | 6 |
| L2.5 | 0 | 2 | 3 |
| **合计** | **0** | **7** | **18** |

上述汇总只描述当前受审事实，不预测修复后的结果。[COMPUTED, HIGH]

## 4. 系统性红线

### 4.1 成熟度事实层正在过度声明

.foundationx/status/index.json 当前声明 25/25 spec complete、25/25 impl complete、25/25 release published、24/25 factory grade、open blockers=0。[COMPUTED, HIGH]

L2.5 五份 SPEC 又逐份写明“机器事实层保持 factory=false”，但同一事实层把五个模块全部标记 factory=true。[COMPUTED, HIGH]

scripts/audit-status.py 的 Foundation fact-layer 检查会验证投影与该 JSON 自洽，却不重新执行 runtime build、consumer install、远端 CI、Release asset 或 branch protection 取证。[COMPUTED, HIGH]

因此当前 40 项 PASS 主要证明投影内部一致，不能证明 25 个 runtime 仓真实可发布。[INFERRED, HIGH]

建议立即把所有当前 NO-GO 模块的 factory/release claim 降为 false 或 blocked，并让状态刷新只接受 commit-bound、可重放 receipt。[INFERRED, HIGH]

### 4.2 六个 Go module identity 与权威矩阵不一致

下表逐行比较 FOUNDATION-DEPS 的 module path 与对应 runtime go.mod。[COMPUTED, HIGH]

| 模块 | FOUNDATION-DEPS 期望 | runtime go.mod 实际 |
| --- | --- | --- |
| xlib_standard | github.com/ZoneCNH/xlib_standard | github.com/ZoneCNH/xlib-standard |
| xlib_harness | github.com/ZoneCNH/xlib_harness | github.com/ZoneCNH/xlib-harness |
| transportx | github.com/ZoneCNH/transportx | github.com/ZoneCNH/xlib-standard |
| domain_market | github.com/ZoneCNH/domain_market | github.com/ZoneCNH/domain-market |
| domain_macro | github.com/ZoneCNH/domain_macro | github.com/ZoneCNH/domain-macro |
| domain_exchange | github.com/ZoneCNH/domain_exchange | github.com/ZoneCNH/domain-exchange |

其余 19 个目标仓的 module identity 与 FOUNDATION-DEPS 对齐。[COMPUTED, HIGH]

transportx 不是普通命名漂移：它与 xlib_standard 声明同一 module identity，导致独立 transportx 消费路径失败。[COMPUTED, HIGH]

对已发布 v1 模块直接改 module path 是 breaking change；不得重写既有 tag，必须用 ADR 明确兼容路径、major 版本策略和下游迁移窗口。[COMMON, HIGH]

### 4.3 Go baseline 有三个互相冲突的事实

BASELINE.yaml 声明 Go 1.26、toolchain go1.26.5、CI 1.26.5；FOUNDATION-DEPS.yaml 仍声明 go_baseline 1.23。[COMPUTED, HIGH]

25 个 runtime go.mod 中，20 个声明 1.25.0，taosx 声明 1.25.12，4 个 L2.5 模块声明 1.23；没有一个声明当前 BASELINE 的 1.26。[COMPUTED, HIGH]

在 baseline SSOT 收敛前，任何“全 fleet 已通过统一 Go 基线”的声明都不成立。[INFERRED, HIGH]

### 4.4 发布血缘与版本身份普遍失真

多个仓出现 tag、GitHub Release、VERSION、源码 Version、repo-contract、manifest、registry 六者不一致。[COMPUTED, HIGH]

domainx、domain_macro、domain_exchange 的 latest release tag 与当前 main 历史 diverged；domain_macro 当前 main 还回退到 public float64，而 v1.0.1 release 已采用 Decimal。[COMPUTED, HIGH]

已发布 tag 不得移动；正确修复是保留旧 tag、恢复或合并 release lineage、在新 patch/minor tag 重放所有门禁并生成新 receipt。[COMMON, HIGH]

### 4.5 CI 绿色包含“没有运行”的假绿

configx、observex、testkitx、bootstrap、ossx、clickhousex 的当前 workflow 存在无效 step、错误 job condition 或 YAML 结构错误，GitHub 产生零 jobs 或 workflow-file failure。[COMPUTED, HIGH]

redisx、kafkax、natsx、taosx 的名为 integration 的默认目标存在 skip=0 或只渲染模板的路径，不能证明真实 Redis/Kafka/NATS/TDengine 行为。[COMPUTED, HIGH]

domain_macro 与 domain_exchange 当前 main 没有 workflow；domainx 与 domain_market 使用 BASELINE 禁止的 ubuntu-latest。[COMPUTED, HIGH]

“required job 缺席”必须视为 FAIL，不得把其他独立 workflow 的绿色状态投影成 CI=true。[FRAME, HIGH]

### 4.6 分支保护与 Release evidence 未闭合

L2.5 五仓 main 均无 branch protection/ruleset；多个标准、L1、存储、契约仓也无 required status checks。[COMPUTED, HIGH]

BASELINE 要求 runner fingerprint、release manifest、CI manifest；多数目标 Release 没有三者的 commit-bound uploaded asset。[COMPUTED, HIGH]

GitHub 自动生成的 source zip/tar 不等于项目上传的 release evidence asset。[COMMON, HIGH]

## 5. 依赖与解耦分析

### 5.1 机械依赖图

25 个 go.mod 的 Foundation 内部直接依赖图无环，未发现 storage-to-storage 运行时依赖。[COMPUTED, HIGH]

主要实际边如下。[COMPUTED, HIGH]

~~~text
domainx ---------> decimalx
domain_market ---> decimalx
domain_macro ----> decimalx
domain_exchange -> decimalx + domain_market

redisx ----------> observex
kafkax ----------> observex
clickhousex -----> observex

bootstrap -------> kernel + configx + observex + resiliencx
                  + redisx + kafkax + natsx + postgresx
                  + taosx + ossx + clickhousex
~~~

该图证明“无循环”和“存储间无直接调用”，但没有证明独立发布、职责唯一或 interface 深度。[COMPUTED, HIGH]

### 5.2 语义与复制式耦合

xlib_standard 与 xlibgate 在 114 个同相对路径文件中有 60 个字节完全相同，两仓都宣称 Standard/Template/Generator/Harness/Evidence 五类职责。[COMPUTED, HIGH]

redisx、kafkax、natsx、taosx 复制 internal/sanitize、validation、testkit、goalcli 和 release-quality 实现；natsx/taosx 还保留公开 pkg/templatex。[COMPUTED, HIGH]

contracts、transportx、resiliencx 也携带标准源或模板职责残留。[COMPUTED, HIGH]

这类复制不会在 go.mod 形成环，却会让一次规则修复在多个仓重复传播并产生版本/门禁漂移；当前 fleet 已出现这种漂移。[INFERRED, HIGH]

### 5.3 bootstrap 的 release-train coupling

bootstrap 公开面较小，但实现直接持有并构造七个存储具体 client；任一 adapter 的不可解析版本或 interface 漂移都会让 bootstrap 整体失编译。[COMPUTED, HIGH]

当前 observex/foundationx 不存在版本与 taosx Pool API 漂移已同时触发该故障。[COMPUTED, HIGH]

建议让 bootstrap 依赖小型 factory/registration seam，具体 storage adapter 由组合根注册；bootstrap 不应在一个构造函数中静态绑定全 fleet。[INFERRED, HIGH]

### 5.4 目标形态

以下是本报告建议的深模块 seam 与允许依赖形态，不是当前实现事实。[FRAME, HIGH]

~~~text
控制面，不进入业务运行时 import graph
  xlib_standard  = schema / template / policy data 的唯一事实源
  xlib_harness   = 执行、fixture、conformance orchestration
  xlib_evidence  = immutable receipt / attestation / store
  xlibgate       = 消费 versioned policy bundle 的判定 CLI

运行时根
  kernel         = stdlib-only 原语
  decimalx       = stdlib-only 精确数值
  contracts      = HTTP + Gin 跨模块契约

运行时下行 DAG
  L1 primitives ----> kernel 或更小的本地 seam
  domainx ----------> decimalx
  domain_market ----> decimalx；订单语义引用 domainx，不再复制
  domain_macro -----> decimalx
  domain_exchange --> decimalx + domainx + domain_market
  storage adapters -> vendor driver + observex 小接口
  transportx -------> contracts + L1 横切 seam
  bootstrap --------> adapter registry/factory，不直接绑定全部具体构造器
~~~

这是“有受控依赖但可独立发布”的目标，而不是通过复制语义实现表面零依赖。[FRAME, HIGH]

## 6. 标准层与 L0 深度分析

### 6.1 xlib_standard

当前本地代码门禁强，但仓库自身 evidence-usability 明确 usable=false、no_release_usability_claim=true，required release gates 为 not_run，release-check job 还被 if:false 禁用。[COMPUTED, HIGH]

因此它当前只能作为代码候选，不能作为可审计的标准发布源。[INFERRED, HIGH]

P0 是恢复可执行 release gate、清理工作区并生成 commit-bound policy bundle、manifest、checksum、runner fingerprint 和 downstream adoption receipt。[INFERRED, HIGH]

### 6.2 xlib_harness

coverage 98.2% 低于自身 100% 门禁，lint 有 ineffassign，v0.2.1 tag 内 VERSION/README 仍为 v0.2.0，Release workflow 失败。[COMPUTED, HIGH]

三个 purity profile 实际执行同一组规则，部分检查只按名称匹配，尚不能证明 profile 语义或误报边界。[COMPUTED, HIGH]

P0 是修复自身门禁与版本；P1 是用真实 adapter/profile contract test 证明不同 profile 的可观察行为。[INFERRED, HIGH]

### 6.3 xlib_evidence

Attestation v2 构造器和 Store 读写路径没有深拷贝 Results map，调用方可通过共享 alias 修改 store 内对象。[COMPUTED, HIGH]

VerifyIntegrity 可以事后发现 digest 不一致，但不能阻止内部 append-only 状态被外部引用修改。[INFERRED, HIGH]

P0 是在所有入口和出口做深拷贝或使用不可变表示，并为 create-after-mutate、read-after-mutate、concurrent access 增加 contract/race tests。[INFERRED, HIGH]

### 6.4 xlibgate

xlibgate v1.3.0 会用 self_hosted_only 规则阻断自己当前的 ubuntu-latest workflows，且 release docs/manifest gate 失败。[COMPUTED, HIGH]

门禁工具不能通过自己的门禁时，不应继续作为 fleet factory claim 的权威判定器。[INFERRED, HIGH]

P0 是先收敛 BASELINE 与 runner-policy，再发布一个自身全绿、带 evidence asset 的新版本。[INFERRED, HIGH]

### 6.5 kernel

远端 main 的 v1.1.1 有五个 manifest/checksum 资产，可作为已发布条件性基线；当前 fix/disable-govulncheck 分支 test/race/CI 明确失败。[COMPUTED, HIGH]

contextx 对零值 Key 的路径可 panic，与 public API 零 panic 声明冲突。[COMPUTED, HIGH]

P0 是撤销或完整实现 govulncheck 政策变更并修复零值 Key 行为；P1 是增加真实 x.go consumer evidence。[INFERRED, HIGH]

## 7. L1 与契约层深度分析

### 7.1 四个 L1 primitive

configx、observex、resiliencx、schedulex 的核心 interface 均较窄，本地 race/vet/boundary/govuln 与覆盖率整体较强，且已有可消费版本。[COMPUTED, HIGH]

四者当前都因 workflow、版本、manifest 或 release-score 漂移而不能从当前 HEAD 发版。[COMPUTED, HIGH]

这四个模块应优先做“发布控制面修复”，不需要先扩大功能面。[INFERRED, HIGH]

### 7.2 bootstrap

bootstrap 是系统级 P0：当前依赖图不可重建，已有 v0.2.0 与 v0.2.2 消费 smoke 都失败，当前 main CI 也没有有效 jobs。[COMPUTED, HIGH]

它不应继续被 maturity index 标记 impl/release/CI/factory 全 true。[INFERRED, HIGH]

### 7.3 testkitx

testkitx 的 test-only 角色没有在当前 25 仓生产依赖图中被违反，但 v1.0.0 tag 内 Version 仍为 v0.4.0，当前主 CI 未生成。[COMPUTED, HIGH]

test-only module 的 L3/L4 应定义为“版本可消费 + production import guard + contract/fake parity”，而不是伪装 runtime deployment。[FRAME, HIGH]

### 7.4 contracts

contracts 核心代码纯度和 coverage 达标，但 v1.5.0 只是 tag，Latest Release 仍 v0.4.7，且没有当前 manifest。[COMPUTED, HIGH]

ingestion 文档仍宣称 gRPC bidirectional stream，当前也没有 HTTP method/path、统一 error envelope 与 Gin endpoint contract，违反宪法 §4.5。[COMPUTED, HIGH]

P0 是先完成 HTTP+Gin 契约迁移与版本发布闭环，再允许 transportx 或业务模块消费新端点。[INFERRED, HIGH]

### 7.5 transportx

transportx 的 go.mod 声明 xlib-standard，核心 pkg coverage 为 0%，README/SPEC 明确 production_import_allowed=false 与 Runtime Pending。[COMPUTED, HIGH]

因此 v0.0.1 的绿色 workflow 主要证明复制的标准模板，而不是 transport runtime conformance。[INFERRED, HIGH]

P0 必须先裁决它是独立 module 还是 xlib_standard 子包；在唯一 identity、HTTP+Gin interface、完整 tests 和 manifest 闭合前保持生产禁用。[INFERRED, HIGH]

## 8. 存储层深度分析

### 8.1 共性结论

七个存储模块之间没有运行时直接依赖，这一机械边界良好。[COMPUTED, HIGH]

真正阻断是 clean dependency rebuild、真实后端 evidence、版本一致性、CI fail-closed、幂等语义和复制治理残留。[COMPUTED, HIGH]

### 8.2 redisx

redisx 依赖不存在的 observex v1.0.0，clean go list/vet/race/boundary 均失败；缓存测试通过不能替代可重复构建。[COMPUTED, HIGH]

当前 integration workflow 没有开启真实 Redis 条件，默认 skip 并返回 0；历史 live/AOF/RDB 报告不能证明当前 v1.1.2 commit。[COMPUTED, HIGH]

### 8.3 kafkax

kafkax 的 broker integration、fault injection、metrics golden、admin golden 在缺 fixture 时明确 status=gap，但 release-check 不调用它们。[COMPUTED, HIGH]

最新 main CI 与 Docker Contract 失败，v1.1.2 只有 tag、没有 GitHub Release，manifest 仍 v0.4.13。[COMPUTED, HIGH]

### 8.4 natsx

natsx 的 embedded server 测试覆盖较广，但 live/TLS/SLO/正式 arbiter 不完整，README 明确禁止 100/100 声明。[COMPUTED, HIGH]

公开 interface 暴露 nats.Option、nats.Msg、nats.StreamConfig，令兼容性直接绑定 nats.go 具体类型。[COMPUTED, HIGH]

### 8.5 postgresx

postgresx 是存储组最接近生产候选的模块：clean main、真实 PostgreSQL 17 service CI、unit/race/vet/boundary 与 coverage 100% 均通过。[COMPUTED, HIGH]

它仍不能立即发版，因为 v1.1.2 tag/manifest/CHANGELOG 与 VERSION/源码 Version v1.1.0 不一致，release workflow 还有无效 shell 条件。[COMPUTED, HIGH]

### 8.6 taosx

taosx 存在真实 TDengine build-tag test，但 CI/release integration 只运行模板渲染，没有执行 SQL、batch、schemaless、重连或故障路径。[COMPUTED, HIGH]

机器门槛 75%、实测约 79%，而 README/AC 声称 100%；这属于验收语义冲突，不是四舍五入问题。[COMPUTED, HIGH]

### 8.7 ossx

ossx 本地 unit/race/vet 与核心 coverage 100% 较强，但当前 workflow YAML 无效；自身 acceptance 只声明 local-production-candidate，并列出 release-tag、Gitleaks、xlibgate、live artifact、downstream、soak 未完成。[COMPUTED, HIGH]

### 8.8 clickhousex

clickhousex 本地与 main 真实 ClickHouse CI 较强，但当前 workflow YAML 无效，仓内声称 v1.0.10 而远端最新正式 Release 仍 v1.0.9。[COMPUTED, HIGH]

Exec/InsertBatch 对 retryable error 自动重试，却没有 dedup key 或 ambiguous-send contract；服务端已接受写入而客户端收到瞬时错误时可能重复写。[INFERRED, HIGH]

## 9. L2.5 深度分析

### 9.1 decimalx — CONDITIONAL

当前 checkout 的 build/test/race/vet/tidy-diff 通过，coverage 80.5%；v1.0.0 发布包在干净消费者环境中 race+coverage 81.2% 通过。[COMPUTED, HIGH]

staticcheck 与 golangci-lint 因 deprecated error/Div 使用及测试风格共失败；release/manifest/latest.json 仍记录 v0.2.0，而公开 Release 为 v1.0.0。[COMPUTED, HIGH]

remote main 当前 checks 成功并使用 self-hosted sre/contracts，但 main 无保护，latest manifest 不能证明 v1.0.0 或当前 HEAD。[COMPUTED, HIGH]

P0 是修复静态门禁与重建 v1.0.x commit-bound manifest；P1 是把所有 deprecated compatibility 测试隔离为显式兼容套件。[INFERRED, HIGH]

### 9.2 domainx — CONDITIONAL

当前 main 的 build/test/race/vet/lint/tidy-diff 通过，coverage 91.1%；v1.0.1 发布包的消费者测试也通过。[COMPUTED, HIGH]

源码 Version 仍 v1.0.0，v1.0.1 tag 与 main 历史 diverged，当前 CI 使用 ubuntu-latest，main 无保护且无 release manifest。[COMPUTED, HIGH]

UnmarshalJSON 可接受 DTO 中任意 total_equity、filled quantity 与 timestamp 并覆盖构造结果，没有执行与构造器相同的不变量校验。[COMPUTED, HIGH]

Order/Portfolio 又直接读取 time.Now 与随机 ID，难以通过 interface seam 做完全确定的回测/测试。[COMPUTED, HIGH]

P1 是注入 Clock/IDSource internal seam，并让所有反序列化重新走完整 constructor/validator。[INFERRED, HIGH]

### 9.3 domain_market — NO-GO

当前 checkout 位于 fix/l2_5_clock_injection，而非 main；本地 test/race 通过，但 coverage 53.2%，v1.1.0 发布包 coverage 51.1%，均低于 80%。[COMPUTED, HIGH]

staticcheck 因继续调用 decimalx 已弃用 Div 失败；current main CI 使用 ubuntu-latest。[COMPUTED, HIGH]

v1.1.0 release commit db03b09 的 GitHub Actions 明确因 decimalx checksum mismatch 失败，尽管 Release 页面写着 test/race/vet verified。[COMPUTED, HIGH]

源码同时存在 MarketFactEnvelope 与不同结构的 MarketEventEnvelope，而 SPEC 宣称后者是前者的 deprecated alias。[COMPUTED, HIGH]

源码还公开 RuntimeMode、PositionSide、OrderType、MockDataProvider、KafkaMarketEvent、TDEngineCompensationTask，并使用 Binance 风格 bookTicker/depthUpdate/markPrice event literal。[COMPUTED, HIGH]

这些类型分别泄漏运行模式、订单语义、测试 double、消息基础设施、存储补偿与 vendor 命名，违反自身领域纯净与唯一 SSOT 目标。[INFERRED, HIGH]

feature 分支新增的包级可变 nowSource/SetTimeSource 也不是安全的 per-instance Clock seam；并发替换可产生全局测试干扰或 race。[INFERRED, HIGH]

P0 是恢复 coverage/CI/identity；P1 是删除基础设施与订单重复语义、统一唯一 envelope，并用依赖注入代替全局 Clock。[INFERRED, HIGH]

### 9.4 domain_macro — NO-GO

v1.0.1 发布包使用 decimalx 并在消费者环境 race+coverage 81.2% 通过，但当前 main 已与该 release diverged。[COMPUTED, HIGH]

当前 main 的 MacroPoint.Value 与 IndicatorValue.Value 回退为 float64，公开 YahooObservation/YahooCheckpoint/YahooGap provider DTO，MacroInformationSet.Points 也是可外部修改的 slice。[COMPUTED, HIGH]

当前实现没有按 SPEC 选择同一 SeriesCode+ObservedAt 的最高可见 RevisionVersion，无可见点时 freshness 也返回 0 而非规格中的 -1/special value。[COMPUTED, HIGH]

当前 main 无 CI、无分支保护，module identity 使用 domain-macro，Version 常量仍 v1.0.0。[COMPUTED, HIGH]

P0 是把 v1.0.1 的 Decimal、完整 provenance 与 validation 合回 main 并新增 CI；P1 是移走 Yahoo DTO、封装 slice、实现确定性 revision selection。[INFERRED, HIGH]

### 9.5 domain_exchange — NO-GO

当前 main 的 build/test/race/coverage/vet/tidy 均因 decimalx v1.0.0 checksum mismatch 失败；独立临时 module cache 与 Go checksum database 都复现下载 hash 与 go.sum 记录不一致。[COMPUTED, HIGH]

这证明 current main 不可重复构建，但不证明攻击；最小事实是仓内 go.sum 已过时或错误。[COMPUTED, HIGH]

已发布 v1.0.0 作为外部依赖可安装，消费者 race+coverage 80.0% 通过；消费者不使用依赖模块仓内的 go.sum，因此这不反证 current main 的维护者构建失败。[COMMON, HIGH]

VenueAdapter 有 13 个方法，Exchange 有 12 个方法，均违反宪法不超过 7 方法和自身“拆分能力接口”规格。[COMPUTED, HIGH]

当前 main 移除了 domainx 依赖，却重新定义 Order、Trade、Balance、OrderStatus，并复用 domain_market.OrderType；这制造了第二套订单 SSOT。[COMPUTED, HIGH]

Credential 公开 APIKey/APISecret/Passphrase，PlaceOrderRequest 没有 Validate，ClientID 仍可空；DecimalPtrFromString 对非法输入静默返回 nil；Registry.List 也没有 deterministic sort。[COMPUTED, HIGH]

当前 main 无任何 GitHub workflow、无 branch protection、module identity 使用 domain-exchange。[COMPUTED, HIGH]

P0 是先修 go.sum 并发新 patch，不移动 v1.0.0 tag；P1 是拆成 AccountReader、OrderPlacer、OrderCanceler、OrderQuerier、MarketReader、DerivativeReader、Streamer 等小 interface，并让 adapter 层持有 Credential。[INFERRED, HIGH]

## 10. 修复顺序

### Wave 0：冻结错误声明

1. 将当前 18 个 NO-GO 模块标为 release=false/factory=false 或 blocked，并记录本报告 evidence ref。[INFERRED, HIGH]
2. 将 7 个 CONDITIONAL 标为 current_head_releaseable=false；保留既有可消费版本事实，但禁止把它投影为当前 HEAD 全绿。[INFERRED, HIGH]
3. 禁止创建或移动 stable tag，直到 Wave 1 的 release identity gate 生效。[INFERRED, HIGH]

### Wave 1：恢复信任控制面

1. 统一 Go baseline SSOT，删除 FOUNDATION-DEPS 的 1.23 漂移，所有 CI 固定 go1.26.5、GOTOOLCHAIN=local、CGO_ENABLED=0、GOFLAGS=-mod=readonly -trimpath。[INFERRED, HIGH]
2. 修复六个 module identity；通过 ADR 决定兼容 facade、major version 与迁移窗口，不重写历史 tag。[INFERRED, HIGH]
3. 强制 tag、VERSION、源码 Version、repo-contract、manifest、registry 六者一致。[INFERRED, HIGH]
4. 强制 latest tag 必须是 main 或批准 release branch 的祖先；diverged history 必须显式审批。[INFERRED, HIGH]
5. 每个 release 上传 runner fingerprint、CI manifest、release manifest、checksum、SBOM/attestation，并绑定准确 commit/tree/tag。[INFERRED, HIGH]
6. 所有 required job 缺席、skip、零 job 或 external fixture 缺失必须 FAIL CLOSED。[INFERRED, HIGH]
7. 启用 main protection/ruleset 与 required checks。[INFERRED, HIGH]

### Wave 2：先修系统级 P0

1. 修 bootstrap 与 redisx 的不可解析依赖图，增加空 GOMODCACHE consumer smoke。[INFERRED, HIGH]
2. 修 transportx 唯一 identity 与 HTTP+Gin runtime contract；未完成前保持 production_import_allowed=false。[INFERRED, HIGH]
3. 修 domain_exchange go.sum，修 domain_market release/checksum/coverage，恢复 domain_macro main 正确实现。[INFERRED, HIGH]
4. 修 xlib_evidence map alias、kernel 当前分支、xlibgate 自阻断 policy。[INFERRED, HIGH]
5. 修所有零 job/YAML/condition workflow 故障。[INFERRED, HIGH]

### Wave 3：深化 interface 与移除复制耦合

1. xlib_standard 只拥有 policy data；harness 只执行；evidence 只存不可变 receipt；xlibgate 只判定。[INFERRED, HIGH]
2. 删除 runtime 仓的 pkg/templatex、goalcli、generator、standard-source 身份与复制治理实现。[INFERRED, HIGH]
3. bootstrap 改为 registry/factory seam；具体 adapter 在组合根注册。[INFERRED, HIGH]
4. domain_market/domain_macro/domain_exchange 删除 provider、Kafka、TDengine、Credential 与重复订单语义。[INFERRED, HIGH]
5. 所有 fake/mock 必须过与生产 adapter 相同的 contract suite。[FRAME, HIGH]

### Wave 4：真实后端与 Goal evidence

| 模块族 | 必须补齐的真实 evidence |
| --- | --- |
| Redis | 当前 commit 的 live、AOF/RDB restart、failover、lock fencing、skip 检测。[FRAME, HIGH] |
| Kafka | broker、rebalance、auth failure、outage、DLQ、lag、idempotent/at-least-once contract。[FRAME, HIGH] |
| NATS | external TLS/auth、JetStream redelivery、SLO、reconnect、consumer adoption。[FRAME, HIGH] |
| PostgreSQL | pool exhaustion、长事务、网络分区/主备切换、容量阈值。[FRAME, HIGH] |
| TDengine | SQL、batch、schemaless、reconnect、真实 endpoint 的 commit-bound evidence。[FRAME, HIGH] |
| OSS | multipart 中断恢复、限流、超时、区域故障、大对象、soak。[FRAME, HIGH] |
| ClickHouse | ambiguous write、dedup/idempotency、网络故障、多小时 soak、外部 consumer rollout。[FRAME, HIGH] |
| 纯 library | 至少两个真实消费者、兼容 smoke、benchmark budget、public surface diff、rollback 证明。[FRAME, HIGH] |

### Wave 5：按依赖顺序重发

建议 release train 为：控制面四模块 → kernel/decimalx/contracts 根 → L1 primitives → domainx/domain_market/domain_macro → storage adapters → domain_exchange/transportx → bootstrap/testkitx。[INFERRED, HIGH]

每一步只消费上一步已发布、可从空 module cache 安装、带完整 receipt 的 immutable tag。[FRAME, HIGH]

## 11. 统一 Production Release Gate

每个模块只有同时满足以下项目才可从 NO-GO/CONDITIONAL 升为 GO：

- clean feature/release worktree，HEAD 与批准分支关系明确。[FRAME, HIGH]
- go.mod identity 与 registry/FOUNDATION-DEPS 一致。[FRAME, HIGH]
- 空 GOMODCACHE 下 build、test、race、vet、staticcheck、golangci、govuln、gitleaks 全通过。[FRAME, HIGH]
- coverage 达本层门槛，且不能靠无断言或模板包灌水。[FRAME, HIGH]
- public interface diff 与 breaking-change policy 通过。[FRAME, HIGH]
- boundary gate 证明无反向边、无同层循环、无 testkitx 生产 import、无 vendor/provider 泄漏。[FRAME, HIGH]
- 真实后端 gate 不允许 skip=pass；外部不可用时 verdict 必须 BLOCKED。[FRAME, HIGH]
- tag、Version、manifest、repo-contract、changelog、registry 完全一致。[FRAME, HIGH]
- Release tag immutable，commit 是批准分支祖先，required CI 全部存在并成功。[FRAME, HIGH]
- Release 上传 manifest/checksum/SBOM/attestation/runner fingerprint/CI receipt。[FRAME, HIGH]
- 外部消费者从空 cache 安装并编译，不依赖本地 replace 或 worktree。[FRAME, HIGH]
- main protection 与 required checks 生效。[FRAME, HIGH]
- library 有真实 adoption；runtime 有 live/soak/SLO/rollback evidence。[FRAME, HIGH]

## 12. 已执行证据

### 12.1 本地

对适用仓执行或检查了 git branch/status/HEAD/tag、go.mod、直接依赖、公开 interface、README、Makefile、CI、manifest、boundary、test、race、coverage、vet、tidy-diff、staticcheck、golangci-lint、govulncheck 与 gitleaks。[COMPUTED, HIGH]

L2.5 五个 published package 还在独立临时 module、空 GOMODCACHE、公开 Go proxy/sumdb 环境中执行了 go get package、consumer test、race 与 coverage。[COMPUTED, HIGH]

对 25 个 go.mod 做了权威 module identity 对比，并检查了 Foundation 内部直接边与循环。[COMPUTED, HIGH]

### 12.2 远端

通过 GitHub API/CLI 读取了 latest Release、tag commit、compare lineage、workflow、run/job log、commit check-runs、release assets、main protection 与 rulesets。[COMPUTED, HIGH]

关键公开证据：

- [domain_market v1.1.0 Release](https://github.com/xhyperium/domain_market/releases/tag/v1.1.0)
- [domain_market release commit 失败 run](https://github.com/xhyperium/domain_market/actions/runs/27667972236)
- [domain_exchange v1.0.0 Release](https://github.com/xhyperium/domain_exchange/releases/tag/v1.0.0)
- [decimalx v1.0.0 checksum database entry](https://sum.golang.org/lookup/github.com/%21zone%21c%21n%21h/decimalx@v1.0.0)

### 12.3 Team 分工

- Agent A：xlib_standard、xlib_harness、xlib_evidence、xlibgate、kernel。[COMPUTED, HIGH]
- Agent B：configx、observex、resiliencx、schedulex、bootstrap、testkitx、contracts、transportx。[COMPUTED, HIGH]
- Agent C：redisx、kafkax、natsx、postgresx、taosx、ossx、clickhousex。[COMPUTED, HIGH]
- 主 agent：L2.5 五模块、25 仓 identity/DAG、治理事实、消费者 smoke 与总裁决。[COMPUTED, HIGH]

## 13. 未知与边界

本次没有使用生产凭据，也没有从本地直接连接外部 Redis、Kafka、NATS、TDengine 或 Aliyun OSS。[COMPUTED, HIGH]

因此这些模块的当前 production live、容量、故障恢复和多小时 soak 不能判为通过；相关结论保持 UNKNOWN/BLOCKED。[COMPUTED, HIGH]

PostgreSQL 与 ClickHouse 有当前 main CI 的真实 service evidence，但没有生产规模、主备切换或容量 SLO evidence。[COMPUTED, HIGH]

secret scan 通过只表示扫描范围未命中规则，不等于依赖、历史、运行环境和供应链不存在秘密或漏洞。[COMMON, HIGH]

部分本地 checkout 原本位于 feature branch、落后远端、历史 diverged 或含用户未提交文件；本报告明确区分 current checkout、remote main 与 published tag，不把三者混为同一 revision。[COMPUTED, HIGH]

## 14. 最终建议

不要继续以“25/25 released、24/25 factory、0 blockers”作为管理入口；先冻结该投影并完成 Wave 1 的可重放 evidence 控制面。[INFERRED, HIGH]

短期最有价值的动作不是补更多功能，而是恢复版本身份、CI fail-closed、release lineage、manifest、branch protection 与真实 consumer/backend gate。[INFERRED, HIGH]

在控制面可信后，优先修 bootstrap、transportx、redisx、domain_exchange、domain_market、domain_macro 与 xlib_evidence；它们分别阻断系统组装、契约消费、可重复构建、L2.5 领域正确性和证据完整性。[INFERRED, HIGH]

[RULES I BROKE]：使用 Python 做了可由 shell 完成的只读结构计数 | 报告生成后的验证步骤 | 误用了 Python；未修改 runtime、报告内容或证据。
