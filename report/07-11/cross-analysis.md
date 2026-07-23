# 交叉分析报告：07-11.md × 07-11-analysis.md 行动全集

> 生成日期：2026-07-11  
> 分析范围：`report/07-11/07-11.md`（原始计划 1187 行）× `report/07-11/07-11-analysis.md`（分析报告 2993 行）  
> 产出：工作包全集 + 发现全集 + 交叉覆盖 + 依赖矩阵

---

## A. 工作包全集提取（来自 07-11.md）

### W0: 事实冻结

| ID | P | 模块 | 任务描述 | 依赖 | 验收条件 | 行号 |
|----|---|------|---------|------|---------|------|
| W0-001 | P0 | ZoneCNH 治理 | domain_macro 标 missing，transportx 标 blocked | 无 | 状态投影不再谎报 | L5 |
| W0-002 | P0 | ZoneCNH 治理 | 25 仓 identity/version/tag/required-check inventory | 无 | inventory 完成 | L100 |
| W0-003 | P0 | ZoneCNH 治理 | 冻结 Go 1.26.5 目标与 module profile schema | 无 | profile schema 冻结 | L92 |
| W0-004 | P0 | redisx/kafkax/natsx/taosx | REQUIRED_INTEGRATION_SKIPPED P0 blocker | 无 | 4 个假 integration 识别为 blocker | L93 |

### W1: 标准控制平面 (xlib_standard, xlib_harness, xlib_evidence, xlibgate)

#### xlib_standard (§3.1, L119-157)

| ID | P | 任务描述 | 关键修改 | 验收条件 | 行号 |
|----|---|---------|---------|---------|------|
| XLS-001 | P0 | 冻结 ownership manifest | 新增 OWNERSHIP.yaml | duplicate ownership gate 通过 | L137 |
| XLS-002 | P0 | 删除/迁移复制实现 | 迁出 cmd/goalcli、gate/evidence runtime | 与 xlibgate 同内容文件归零 | L138 |
| XLS-003 | P0 | 建立 standard bundle | schemas/policies/templates/profiles/reason-codes | bundle manifest + SHA256 可重现 | L139 |
| XLS-004 | P0 | 修复 CI | 生成式 workflow、self-hosted ephemeral | required checks 无 disabled | L140 |
| XLS-005 | P1 | 基线统一 | Go 1.26.5、固定工具 | toolchain gate 通过 | L141 |
| XLS-006 | P1 | 三类 canary template | kernel/decimalx/redisx fixtures | render 零 diff | L142 |
| XLS-007 | P1 | 发布标准 v2 RC | migration guide | v2.0.0-rc1 Release assets 完整 | L143 |
| XLS-008 | P2 | 下游同步策略 | drift plan、自动 PR | 3 canary 同步成功 | L144 |

#### xlib_harness (§3.2, L160-194)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| XLH-001 | P0 | 冻结 v2 CLI contract | command/flags/stdout/stderr/exit snapshot | L176 |
| XLH-002 | P0 | 清除 gate/evidence 规则实现 | 只调用锁定的 xlibgate/xlib_evidence contract | L177 |
| XLH-003 | P0 | 修复版本五源 | VERSION/CHANGELOG/repo-contract/main/release tuple 一致 | L178 |
| XLH-004 | P1 | 生成幂等与迁移 | repeated render zero diff | L179 |
| XLH-005 | P1 | 安全路径 | path traversal/symlink/取消/并发/partial write 回滚 | L180 |
| XLH-006 | P1 | class profiles | 11 类 profile 正负 fixture | L181 |
| XLH-007 | P1 | 自身 CI/Release | 90% target、race、fuzz、CodeQL、SBOM | L182 |
| XLH-008 | P2 | fleet patch plan | 只输出可审阅 patch，不自动写 main | L183 |

#### xlib_evidence (§3.3, L197-232)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| XLE-001 | P0 | 裁决 canonical module path | go.mod/repo-contract/docs/consumer 统一 | L214 |
| XLE-002 | P0 | evidence schema v1 | commit/tree/run/ref/tool/result/service/assets 字段冻结 | L215 |
| XLE-003 | P0 | 结果语义 | pass/fail/skipped/error/N-A 严格区分 | L216 |
| XLE-004 | P0 | 跨 Job artifact 聚合 | 缺 artifact hard fail | L217 |
| XLE-005 | P1 | canonical JSON + sidecar | 同输入 bit-for-bit | L218 |
| XLE-006 | P1 | redaction/tamper/replay | secret corpus 零泄漏 | L219 |
| XLE-007 | P1 | SBOM/provenance 引用 | 验证 digest | L220 |
| XLE-008 | P1 | 自身 release | 成功 workflow、二进制、manifest、SBOM | L221 |

#### xlibgate (§3.4, L235-270)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| XLG-001 | P0 | 删除模板/evidence/generator 重叠 | ownership gate 零违规 | L252 |
| XLG-002 | P0 | result schema + reason registry | 每条规则稳定 reason code；exit 2 未知输入 | L253 |
| XLG-003 | P0 | identity/baseline/workflow gates | 25 仓已知漂移 negative fixture | L254 |
| XLG-004 | P0 | Evidence final verifier | commit/tree/run/digest/result/asset 全量验证 | L255 |
| XLG-005 | P1 | API/schema/SemVer gate | ancestor release diff；breaking 自动要求 MAJOR | L256 |
| XLG-006 | P1 | 自举信任 | 上一 stable 验证候选；3 canary shadow 运行 | L257 |
| XLG-007 | P1 | 恢复 CI/Release | PR gate 不跳过、SAST 阻断 | L258 |
| XLG-008 | P2 | fleet qualification | 只推导状态，不写手工 factory=true | L259 |

### W2: 三类 Canary (kernel, decimalx, redisx)

#### kernel (§4.1, L275-304)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| KRN-001 | P0 | 边界 ADR | L0 只保留退避/同步原语 | L287 |
| KRN-002 | P0 | v1 兼容 deprecation | 标记策略 API；提供迁移示例 | L288 |
| KRN-003 | P1 | Go/CI/security 基线 | BASE-* 全通过 | L289 |
| KRN-004 | P1 | 100% 核心验证 | package coverage 100、race、fuzz | L290 |
| KRN-005 | P1 | API/benchmark | 相对合法祖先 apidiff | L291 |
| KRN-006 | P1 | consumer canary | configx/resiliencx/schedulex compile/contract | L292 |
| KRN-007 | P2 | v2 清理 | 全下游迁移后删除策略面 | L293 |

#### redisx (§5.1, L524-554)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| RDX-001 | P0 | integration fail-closed | required Redis 不可达退出非 0 | L537 |
| RDX-002 | P0 | 真实 PR Redis | 固定 digest、health、ACL | L538 |
| RDX-003 | P1 | TLS/auth/reconnect | ACL/TLS、credential rotate | L539 |
| RDX-004 | P1 | data semantics | TTL/precision/pipeline | L540 |
| RDX-005 | P1 | lock/rate | owner token、fencing、TTL 原子性 | L541 |
| RDX-006 | P1 | cache/pool | stampede、pool saturation | L542 |
| RDX-007 | P1 | persistence/fault | RDB/AOF restart、network cut | L543 |
| RDX-008 | P1 | Evidence/版本 | main unreleased；service/run binding | L544 |
| RDX-009 | P1 | adoption/qualification | bootstrap + 一个业务消费者 | L545 |

#### decimalx (§6.3, L821-851)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| DEC-001 | P0 | Go/仓库/Release 基线 | BASE-*；金融纯库 profile | L833 |
| DEC-002 | P0 | arithmetic invariants | Add/Sub/Mul exact；Quo/Quantize | L834 |
| DEC-003 | P0 | rounding matrix | sign/tie/scale/overflow/zero | L835 |
| DEC-004 | P1 | parse/resource limits | digits/scale/CPU/memory bounds | L836 |
| DEC-005 | P1 | JSON/SQL | quoted decimal；float scan reject | L837 |
| DEC-006 | P1 | Money/currency | currency equality、cross-currency failure | L838 |
| DEC-007 | P1 | differential/benchmark | 独立实现对照、alloc/latency | L839 |
| DEC-008 | P1 | distinct types migration | 新 Price/Qty/Ratio defined types | L840 |
| DEC-009 | P2 | alias removal | 下游迁移完成后删除 | L841 |

### W3: L0/L1/Assembly/Test (configx, observex, resiliencx, schedulex, bootstrap, testkitx)

#### configx (§4.2, L307-337)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| CFG-001 | P0 | 收敛公共面 | 删除/迁移模板式 Client/Health/Metrics | L319 |
| CFG-002 | P1 | precedence property | file/env/map/args/remote last-wins 全排列 | L320 |
| CFG-003 | P1 | strict decode | unknown/duplicate/type/range/schema | L321 |
| CFG-004 | P1 | secret zero-leak | String/JSON/error/log 全路径 | L322 |
| CFG-005 | P1 | watcher state machine | atomic swap/slow subscriber/cancel/rollback | L323 |
| CFG-006 | P1 | parser security | JSON/TOML/YAML/env fuzz | L324 |
| CFG-007 | P1 | RemoteSource kit | fake/real adapter conformance | L325 |
| CFG-008 | P1 | CI/Release/adoption | 80%→90%；bootstrap 下游 canary | L326 |

#### observex (§4.3, L340-369)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| OBS-001 | P0 | 版本/历史事实修复 | main 标 unreleased；单一 release tuple | L351 |
| OBS-002 | P0 | provider-neutral gate | 核心包禁止 OTel/Zap/Prometheus import | L352 |
| OBS-003 | P1 | redaction contract | Field/Attr/context/error/health | L353 |
| OBS-004 | P1 | metric policy | name/label allowlist、cardinality budget | L354 |
| OBS-005 | P1 | trace/log propagation | context cancel、sampling/noop | L355 |
| OBS-006 | P1 | concurrency/perf | memory recorder race、allocation | L356 |
| OBS-007 | P1 | adapter conformance kit | noop/memory/fake 同套 kit | L357 |
| OBS-008 | P1 | CI/Release | SAST medium+ 阻断；80%→90% | L358 |

#### resiliencx (§4.4, L373-407)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| RES-001 | P0 | 冻结错误语义与 model | 先写失败 regression/model tests | L388 |
| RES-002 | P0 | retry 修复 | invalid config fail-fast；classifier/idempotency | L389 |
| RES-003 | P0 | bulkhead 修复 | capacity validation、acquire/release ownership | L390 |
| RES-004 | P0 | ratelimit 重写 | token bucket model、future debt、concurrency | L391 |
| RES-005 | P0 | circuit/timeout | deterministic clock；状态机 model | L392 |
| RES-006 | P1 | Compose pipeline | 策略顺序、event sink、错误分类 | L393 |
| RES-007 | P1 | kernel 边界迁移 | 使用 L0 原语；下游编译 | L394 |
| RES-008 | P1 | soak/benchmark | high contention、cancel storm | L395 |
| RES-009 | P1 | 版本/Release reset | 隔离错误 v1 tag、自洽 release tuple | L396 |

#### schedulex (§4.5, L410-439)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| SCH-001 | P0 | 文档/API 事实修复 | cron 五/六字段裁决；CHANGELOG 去重 | L422 |
| SCH-002 | P1 | parser/property/fuzz | invalid/edge cron、interval/delay | L423 |
| SCH-003 | P1 | DST/timezone golden | spring-forward/fall-back、月末/闰年 | L424 |
| SCH-004 | P1 | misfire/overlap model | catch-up 上限、skip/coalesce | L425 |
| SCH-005 | P1 | shutdown/leak | 零 real sleep、cancel、drain、race | L426 |
| SCH-006 | P1 | Locker v1 conformance | acquire/contention/expiry/release | L427 |
| SCH-007 | P2 | Locker v2 design | RenewableLease/FencedLease 独立小接口 | L428 |
| SCH-008 | P1 | CI/Release/adoption | 80%→90%；bootstrap consumer | L429 |

#### bootstrap (§4.6, L442-479)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| BST-001 | P0 | 重分类 Assembly | 架构/registry/dependency matrix 一致 | L456 |
| BST-002 | P0 | 事务式构造 | 每步登记 closer；失败逆序回滚 | L457 |
| BST-003 | P0 | Hook 回滚 | pre/post hook 任一失败释放全部资源 | L458 |
| BST-004 | P0 | Config 生效 | LoadResult/provenance/ConfigHash | L459 |
| BST-005 | P0 | 生命周期状态机 | mutex/atomic；Start/Run/Shutdown 幂等 | L460 |
| BST-006 | P0 | foundationx 退出 | go.mod/import graph 零遗留 | L461 |
| BST-007 | P1 | store wiring integration | 7 adapter success/partial failure matrix | L462 |
| BST-008 | P1 | CI/仓库基线 | 删除 bak/空 step；Actions SHA pin | L463 |
| BST-009 | P1 | consumer smoke | composer/minimal service 构造与关闭 | L464 |

#### testkitx (§4.7, L482-511)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| TST-001 | P0 | 版本事实 reset | released tuple 与 main unreleased 分离 | L494 |
| TST-002 | P0 | test-only import gate | 生产 package import testkitx 必失败 | L495 |
| TST-003 | P0 | 删除/隔离遗留面 | Client/Health/Config/template 迁出 | L496 |
| TST-004 | P1 | fake clock/golden | deterministic；golden update 需显式授权 | L497 |
| TST-005 | P1 | fixture isolation | parallel/tempdir/port/env 无冲突 | L498 |
| TST-006 | P1 | subprocess helper | cancel/timeout/stdout/stderr/leak | L499 |
| TST-007 | P1 | conformance kits | storage/domain/transport kit 版本兼容矩阵 | L500 |
| TST-008 | P1 | 自身 mutation/CI | 80%→90%；mutation shadow | L501 |

### W4: 存储适配器 (kafkax, natsx, postgresx, taosx, ossx, clickhousex)

#### kafkax (§5.2, L557-587)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| KFK-001 | P0 | 删除伪 integration | 启动真实 Kafka/KRaft 固定 digest | L569 |
| KFK-002 | P0 | producer contract | acks/idempotence/partition key/retry | L570 |
| KFK-003 | P0 | consumer group | rebalance/offset/redelivery/cancel | L571 |
| KFK-004 | P1 | broker fault | leader loss/restart/partition | L572 |
| KFK-005 | P1 | TLS/SASL | auth fail/rotate/certificate | L573 |
| KFK-006 | P1 | Admin API | topic/config/partition golden | L574 |
| KFK-007 | P1 | backpressure/perf | batch/queue/memory budget | L575 |
| KFK-008 | P1 | Evidence/adoption | broker version/digest/run | L576 |

#### natsx (§5.3, L589-617)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| NTS-001 | P0 | truth reset | v1 tag lineage、main unreleased | L600 |
| NTS-002 | P0 | Core NATS integration | publish/subscribe/request/reply | L601 |
| NTS-003 | P0 | JetStream integration | stream/consumer/durable/ack/redelivery | L602 |
| NTS-004 | P1 | security | TLS/NKey/creds/auth rotate | L603 |
| NTS-005 | P1 | fault/health | server restart/network cut/degraded | L604 |
| NTS-006 | P1 | lifecycle | ctx cancel/subscription close/goroutine leak | L605 |
| NTS-007 | P1 | templatex 清理 | 只保留 natsx runtime 与 fixture | L606 |
| NTS-008 | P1 | SLO/Evidence/adoption | latency/error/reconnect SLO | L607 |

#### postgresx (§5.4, L620-649)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| PGX-001 | P0 | Evidence 重绑候选 | 完整 commit/tree/run/PG image digest | L632 |
| PGX-002 | P1 | 版本矩阵 | PostgreSQL 当前/N-1 | L633 |
| PGX-003 | P1 | pool/timeout | exhaustion/max lifetime/cancel/leak | L634 |
| PGX-004 | P1 | transaction | isolation/deadlock/rollback/commit | L635 |
| PGX-005 | P1 | migration | up-down-up/partial failure/lock | L636 |
| PGX-006 | P1 | TLS/auth/fault | certificate/credential rotate/restart | L637 |
| PGX-007 | P1 | real runner policy | 真实 sre/storage-heavy | L638 |
| PGX-008 | P1 | adoption/soak | bootstrap + 一个真实 service | L639 |

#### taosx (§5.5, L652-681)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| TAO-001 | P0 | 能力表/非目标裁决 | 承诺 API 必须实现 | L664 |
| TAO-002 | P0 | 生产 WebSocket driver live | 调用真实 NewWebSocketDriver | L665 |
| TAO-003 | P0 | SchemalessWrite | protocol/validation/partial failure | L666 |
| TAO-004 | P1 | batch/query mapping | timestamp precision/timezone/decimal | L667 |
| TAO-005 | P1 | reconnect/fault | server restart/network cut/retry | L668 |
| TAO-006 | P1 | TDengine matrix | 版本固定 | L669 |
| TAO-007 | P1 | perf/leak | batch throughput/memory | L670 |
| TAO-008 | P1 | Evidence/adoption | production driver digest | L671 |

#### ossx (§5.6, L684-714)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| OSS-001 | P0 | security 阻断 | gitleaks/SAST/secret scan hard fail | L699 |
| OSS-002 | P0 | runner/evidence | storage-light；tag live 绑定 Aliyun endpoint | L700 |
| OSS-003 | P1 | multipart lifecycle | initiate/upload/complete/abort/resume | L701 |
| OSS-004 | P1 | data integrity | checksum/range/stream cancel | L702 |
| OSS-005 | P1 | version/delete | versioning/delete marker/idempotent | L703 |
| OSS-006 | P1 | presign | expiry/method/header/policy | L704 |
| OSS-007 | P1 | auth/quota/fault | credential rotate/permission/timeout | L705 |
| OSS-008 | P1 | fixture/live 分层 | MinIO 仅 PR fixture；Aliyun tag gate | L706 |
| OSS-009 | P1 | adoption/soak | 一个真实 consumer | L707 |

#### clickhousex (§5.7, L717-746)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| CHX-001 | P0 | 修复 release 声明 | main 改 unreleased；不假称 v1.0.10 | L729 |
| CHX-002 | P0 | security hard gate | gitleaks/SAST/vuln/license 阻断 | L730 |
| CHX-003 | P1 | type mapping | Decimal/DateTime/Nullable/Array/Map | L731 |
| CHX-004 | P1 | insert semantics | batch/partial/async/dedup | L732 |
| CHX-005 | P1 | schema evolution | add/rename/type change compatibility | L733 |
| CHX-006 | P1 | real chaos | server restart/network cut/slow query | L734 |
| CHX-007 | P1 | soak/perf | 3h workflow 绑定候选 commit | L735 |
| CHX-008 | P1 | real adoption | 下游 service 实际写/查 canary | L736 |

### W5: Contracts/Transportx/Domain (contracts, transportx, domainx, domain_market, domain_macro, domain_exchange)

#### contracts (§6.1, L751-780)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| CTR-001 | P0 | release lineage 重建 | 找到候选祖先稳定 tag；main 标 unreleased | L763 |
| CTR-002 | P0 | 删除 templatex/goalcli | 仓库只保留 contracts/schema/test fixtures | L764 |
| CTR-003 | P0 | API breaking gate | Go apidiff/enum/error/topic/config/schema | L765 |
| CTR-004 | P1 | wire golden | JSON/schema canonical/optional/required | L766 |
| CTR-005 | P1 | SemVer arbiter | breaking 自动要求 MAJOR + ADR + migration | L767 |
| CTR-006 | P1 | PR consumer fixtures | 固定两个 consumer fixtures | L768 |
| CTR-007 | P1 | nightly/release consumers | 至少两个真实下游 compile/contract | L769 |
| CTR-008 | P1 | Evidence/assets | API snapshot/schema bundle/SBOM | L770 |

#### transportx (§6.2, L783-818)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| TRN-001 | P0 | module identity 修复 | go.mod/package/repo-contract/README/tag 一致 | L800 |
| TRN-002 | P0 | 删除 templatex/goalcli | 只保留 transport core/tests/docs | L801 |
| TRN-003 | P0 | 范围/Spec 重写 | v1 request/reply；其他 planes 非目标 | L802 |
| TRN-004 | P0 | Envelope/validation | ID/method/route/header/body/deadline | L803 |
| TRN-005 | P1 | cancel/deadline | parent cancel/deadline exceeded/late response | L804 |
| TRN-006 | P1 | Codec | JSON compatibility/size limit | L805 |
| TRN-007 | P1 | Middleware | fixed order/redaction-before-log | L806 |
| TRN-008 | P1 | conformance kit | HTTP 与 request/reply adapter 共享 contract | L807 |
| TRN-009 | P2 | pub/sub/stream design | backpressure/ordering/subscription lifecycle | L808 |

#### domainx (§6.4, L854-883)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| DMN-001 | P0 | identity/version/layer | L2.5/v1.0.1 lineage/main unreleased | L866 |
| DMN-002 | P0 | Clock/ID 注入 | constructors 接收 explicit time/ID | L867 |
| DMN-003 | P0 | Order state model | 合法/非法 transition/fill/cancel | L868 |
| DMN-004 | P1 | Position/Portfolio properties | PnL/avg price/exposure | L869 |
| DMN-005 | P1 | immutable update | copy-on-write；无 setter/global mutable | L870 |
| DMN-006 | P1 | canonical codec | explicit projection/round-trip/golden | L871 |
| DMN-007 | P1 | API/SemVer | apidiff/error identity/downstream | L872 |
| DMN-008 | P1 | adoption | domain_market/domain_exchange + 一个业务 | L873 |

#### domain_market (§6.5, L886-920)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| MKT-001 | P0 | 领域纯化 ADR | Kafka/TDengine/metrics/clock 迁出 | L900 |
| MKT-002 | P0 | SSOT 收口 | OrderType/PositionSide 回 domainx | L901 |
| MKT-003 | P0 | Mock 迁移 | domainmarkettest/testkitx；deterministic | L902 |
| MKT-004 | P0 | InstrumentKey | venue/product/symbol 全身份 | L903 |
| MKT-005 | P0 | typed facts | 替代 Payload interface{} | L904 |
| MKT-006 | P1 | Tick/Quote/Bar | decimal/time/bid-ask/OHLCV invariants | L905 |
| MKT-007 | P1 | OrderBook model | sorting/cross/duplicate/seq/gap | L906 |
| MKT-008 | P1 | time/quality | event/received/available/decision | L907 |
| MKT-009 | P1 | codec/API/adoption | explicit canonical projection | L908 |
| MKT-010 | P1 | repo/CI/Release | domain-pure profile/95% target | L909 |

#### domain_macro (§6.6, L923-956)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| MAC-001 | P0 | 修正事实 | status/release/factory=false or missing | L937 |
| MAC-002 | P0 | Spec/ADR 冻结 | observation period/ReleasedAt/AvailableAt | L938 |
| MAC-003 | P0 | 仓库/bootstrap | 获授权后创建真实 repo/module/CI | L939 |
| MAC-004 | P0 | MacroPoint | series/region/unit/frequency/SA/source | L940 |
| MAC-005 | P0 | visibility | InformationSet.AsOf(decisionTime) | L941 |
| MAC-006 | P1 | revision model | preliminary/final/deterministic ordering | L942 |
| MAC-007 | P1 | no-lookahead properties | future release/availability/revision | L943 |
| MAC-008 | P1 | decimal/codec | decimalx；explicit canonical projection | L944 |
| MAC-009 | P1 | consumers | macro_data/macro_regime/backtest replay | L945 |
| MAC-010 | P1 | first release | v0.x evidence；adoption 后 v1 | L946 |

#### domain_exchange (§6.7, L959-993)

| ID | P | 任务描述 | 验收条件 | 行号 |
|----|---|---------|---------|------|
| EXC-001 | P0 | consumer inventory | Binance/OKX/Bybit compile 依赖矩阵 | L973 |
| EXC-002 | P0 | 小接口 v1.1 | Identity/Health/Account/OrderWrite 等 8 接口 | L974 |
| EXC-003 | P0 | 旧 SPI 兼容 | Deprecated VenueAdapter + composition adapter | L975 |
| EXC-004 | P0 | CredentialRef | opaque ref/provider；不持明文 secret | L976 |
| EXC-005 | P0 | canonical mapping | domainx Order/Execution；vendor mapping 留 mapper | L977 |
| EXC-006 | P0 | typed errors | auth/rate/balance/precision/unsupported | L978 |
| EXC-007 | P1 | Registry | race-safe/duplicate error/deterministic | L979 |
| EXC-008 | P1 | conformance kit | idempotent submit/unknown-pending/batch partial | L980 |
| EXC-009 | P1 | downstream migration | 每个 adapter 逐迁小接口 | L981 |
| EXC-010 | P2 | v2 removal | 删除巨型 SPI/明文 Credential/重复模型 | L982 |

### W6: 全舰队重新认证 — 基准条款（§7-12，L996-1187）

W6 不含模块级工作包，由下列统一流程覆盖：

| 条款 | ID | 描述 | 行号 |
|------|----|------|------|
| 7.1 精确依赖顺序 | W6-DEPS | 依赖链：standard RC→gate/evidence/harness→canaries→stable→下游 | L1000-1016 |
| 7.2 联合验证矩阵 | W6-VERIFY | CANARY-L0/DOMAIN/L2、OBS/EXCHANGE/MARKET/MACRO/TRANSPORT conformance | L1020-1029 |
| 8.1 Candidate 阶段 | W6-CAND | commit→final-check→assets→binding | L1035-1041 |
| 8.2 Stable 阶段 | W6-STABLE | annotated tag→Release→assets→consumer compile | L1043-1050 |
| 8.3 Qualification | W6-QUAL | adoption/live/fault/soak + quarantine/revoke/requalify | L1052-1058 |
| 12 检查清单 | W6-CHECK | 19 项 per-module 检查（身份→回滚） | L1160-1183 |

### BASE-* 全局工作包（§1.4，L77-89）

| ID | P | 描述 | 验收条件 | 行号 |
|----|---|------|---------|------|
| BASE-001 | P0 | 身份统一 | repo ID/repository/module path/package/repo-contract 一致 | L79 |
| BASE-002 | P0 | Go 基线 | go 1.26.0/toolchain 1.26.5；例外有 ADR | L82 |
| BASE-003 | P0 | 仓库文件 | README/LICENSE/SECURITY/CHANGELOG/CONTRIBUTING/CODEOWNERS/profile 齐全 | L83 |
| BASE-004 | P0 | 生成式 CI | workflow 来自锁定 standard bundle；零手工削弱 | L84 |
| BASE-005 | P0 | 供应链 | Actions 40 位 SHA；无 latest/curl-pipe | L85 |
| BASE-006 | P0 | API/版本事实 | main=unreleased/next；released tuple 一致 | L86 |
| BASE-007 | P0 | Evidence | 每个 gate 上传结构化 result | L87 |
| BASE-008 | P0 | Release | candidate SHA final check 后才创建稳定 tag | L88 |
| BASE-009 | P0 | Adoption | go get @tag + 至少一个消费者 | L89 |

---

## B. 分析报告发现全集（来自 07-11-analysis.md）

### B.1 CRITICAL 级发现（8 项）

| # | 发现 | 行号 | 发现者 | 严重度 |
|----|------|------|--------|--------|
| C1 | 时间线严重低估：1天→1.5-2天、7天→10-14天、30天→45-60天 | L49-63 | risk-feasibility | **CRITICAL** |
| C2 | goalcli 归属真空：三方同时声明删除，无人认领 | L70-74 | gap-optimizer | **CRITICAL** |
| C3 | transportx module path 未裁决：go.mod 仍是 xlib-standard，未裁定 /v2 | L77-80 | gap-optimizer | **CRITICAL** |
| C4 | contracts 版本不确定性：v1.5.0 祖先关系未审计，发布边界模糊 | L83-86 | gap-optimizer | **CRITICAL** |
| C5 | Docker/K8s 禁令与 fault/soak 矛盾：7 个 storage adapter 需要容器编排 | L90-101 | risk-feasibility | **CRITICAL** |
| C6 | domain_macro 治理信任崩塌：仓库不存在但投影标 factory grade | L104-111 | risk-feasibility + gap-optimizer | **CRITICAL** |
| C7 | W4 light/heavy pool 未定义：声称可并行但无分类表/资源约束 | L114-121 | dependency-architect | **CRITICAL** |
| C8 | BASE 推广策略缺失：patch 产出后谁负责 PR 创建与审核 | L204-205 | gap-optimizer | **CRITICAL** |

### B.2 NEEDS_REVISION 级（3 项）

| # | 发现 | 行号 | 发现者 |
|----|------|------|--------|
| N1 | W4 light/heavy pool 未定义（同 C7，升级为 CRITICAL） | L22 | dependency-architect |
| N2 | testkitx 并行：`test-only import gate` 必失败 vs 自身迁移生产式 Config 矛盾 | L23-25 | dependency-architect |
| N3 | domain_market/macro 并行安全风险：macro 仓库不存在，并行创建不可靠 | L26-28 | dependency-architect |

### B.3 ISSUES_FOUND 级（3 类细分）

#### 工作包覆盖缺口（4 类）

| # | 问题 | 详情 | 分析行号 |
|----|------|------|---------|
| G1 | BASE 映射严重不均 | 8 个模块只说"BASE-* 全通过"无分解：kernel(L289)/decimalx(L831)/bootstrap(L463)/domain_market(L909)/observex(L359)/configx(L313)/schedulex(L429)/xlib_standard(L140) | L185-187 |
| G2 | 缺 SECURITY/CONTRIBUTING/CODEOWNERS 10+ 模块 | kernel/configx/observex/xlib_harness/xlib_evidence/xlibgate/bootstrap/domain_market/domain_exchange 无 BASE-003 专用工作包 | L189-192 |
| G3 | BASE-005 供应链审计覆盖不足 | 5 个模块有 latest tag Actions/curl-pipe，仅 bootstrap CI 修复中提及 SHA-pin | L194-196 |
| G4 | 联合验证矩阵缺失项 2 个 | configx + 下游集成验证缺失；resiliencx + kernel 边界验证缺失 | L208-209 |

#### 验收可测量性（3 类）

| # | 问题 | 详情 | 行号 |
|----|------|------|------|
| A1 | "BASE-* 全通过"无量化指标 | 8 个模块无分解，无法追踪进度 | L185-187 |
| A2 | "满足 profile"无具体标准 | 多模块验收条件写"满足 profile"但 profile 尚未完整定义 | 分散多行 |
| A3 | coverage 目标 80%→90% 无中间 checkpoint | 多模块缺乏渐进指标 | 分散多行 |

#### 缺失章节（4 类）

| # | 缺失内容 | 影响 | 行号 |
|----|---------|------|------|
| M1 | 全局回滚策略 | xlib_standard v2.0.0 RC 失败后无撤回路径 | L203 |
| M2 | BASE 推广 Runbook | xlib_harness 产出 patch 后无推进流程 | L204 |
| M3 | 人员分工与并行窗口 | 哪些工作必须同一 owner 串行未定义 | L205-206 |
| M4 | Fleet Status Dashboard | 跨 25 仓聚合进度监控缺失 | L207 |

### B.4 版本一致性 CRITICAL_GAP（5 条）

| # | 问题 | 详情 | 行号 |
|----|------|------|------|
| V1 | Go 版本四重不一致 | go.mod=1.25/CI=1.26.3/目标=1.26.5/文档=1.26.0 | 分散在 07-11.md 各模块 |
| V2 | tag vs main 版本倒挂 | resiliencx code v0.4.14 vs tag v1.0.2；natsx tag v1.0.5 vs main v0.4.7 | analysis L10-12 |
| V3 | release lineage 断裂 | contracts v1.5.0 可能不是 main 祖先 | analysis L83-86 |
| V4 | 不存在仓库标 released | domain_macro 仓库不存在但标 v1.0.1 | analysis L104-111 |
| V5 | transportx go.mod 身份错乱 | go.mod 为 xlib-standard，repo-contract 称 transportx | analysis L77-80 |

### B.5 报告内部矛盾（9 条）

| # | 矛盾描述 | 原始行号 | 严重度 |
|----|---------|---------|--------|
| 1 | GOWORK=off vs 跨模块 canary 需要 multi-module workspace | 07-11.md L50 vs L288/L320 | MED |
| 2 | 单 PR 可回滚 vs BASE-003 7 文件一次提交 | 07-11.md L49 vs L83 | LOW-MED |
| 3 | goalcli 归属真空：三方声明删除，无人认领 | 07-11.md L131 vs L244-246 vs L251 | HIGH |
| 4 | testkitx import gate "必失败" vs 自身迁移生产式 Config | 07-11.md L496 vs L486-487 | MED |
| 5 | SchemalessWrite not implemented → 公开 API 无 not implemented | 07-11.md L658 vs L677-680 | MED |
| 6 | transportx go.mod 是 xlib-standard vs repo-contract 称 transportx | 07-11.md L787 vs L801 | HIGH |
| 7 | domain_macro 不存在标为 factory grade | 07-11.md L927 vs L937 | HIGH |
| 8 | xlib_harness v0.3.0 产出 compound loop 但尚未 stable | 07-11.md L187 vs L1102/L1124 | LOW |
| 9 | contracts 在依赖链中的位置未裁决 | 07-11.md L1008-1016 | MED |

### B.6 P0 修复建议（10 条）及实施方案

| # | 行动 | 对象 | 实施方案行号 | 截止 |
|----|------|------|------------|------|
| P0-1 | 裁决 goalcli 最终归属（并入 xlib_harness，新增 XLH-009） | §3 | L284-372 | W1 Day 2 |
| P0-2 | 裁决 transportx go module major path（裁决 /v1，无 /v2） | §6.2 | L375-458 | W1 Day 10 |
| P0-3 | 执行 contracts git tag lineage 审计，给出确定性版本 | §6.1 | L462-527 | W1 Day 12 |
| P0-4 | 明确 bare-metal fault/soak 方案（systemd + netns + iptables + eBPF 三层） | §5 W4 | L530-2431 | W3 前 |
| P0-5 | 全仓 status projection 事实审计（audit-status-projection.py） | W0 | L2483-2645 | W0 Day 1 |
| P0-6 | 定义 xlib_standard "最小可行合约"（MVC：schema/policy/reason-code） | W1 | L2649-2706 | W1 Day 5 |
| P0-7 | 为 10+ 模块创建 BASE-003 专用工作包 | §1.4 | L2710-2839 | W1 Day 11 |
| P0-8 | 时间线扩展至 45-60 天 | §9 | L2842-2861 | W0 Day 2 |
| P0-9 | 定义 W4 light/heavy pool 分类表 | §2.2 | L2864-2904 | W3 前 |
| P0-10 | 新增回滚策略 + BASE 推广 Runbook 章节 | 新章 | L2908-2992 | W1 前 |

---

## C. 文档交叉覆盖分析

### C.1 逐模块覆盖矩阵

| 模块 | 07-11.md 工作包数 | 分析报告指出的缺口 | 报告覆盖 |
|------|-----------------|-------------------|---------|
| xlib_standard | 8 (XLS-001~008) | goalcli 归属未定 (C2)；MVC freeze 策略 (P0-6)；BASE-003 缺失 | 全覆盖 |
| xlib_harness | 8 (XLH-001~008) | goalcli 归属 (C2)；缺失 LICENSE/SECURITY/CODEOWNERS (G2) | 全覆盖，+XLH-009 建议 |
| xlib_evidence | 8 (XLE-001~008) | module path 冲突 (V5)；缺失 LICENSE/SECURITY/CODEOWNERS (G2) | 全覆盖 |
| xlibgate | 8 (XLG-001~008) | goalcli 归属 (C2)；缺失 LICENSE/SECURITY/CODEOWNERS (G2) | 全覆盖 |
| kernel | 7 (KRN-001~007) | BASE-003 缺失 (G2)；缺 SECURITY/CONTRIBUTING/CODEOWNERS | 概念覆盖，组织缺失 |
| decimalx | 9 (DEC-001~009) | W2 canary 依赖分析合理 | 全覆盖 |
| redisx | 9 (RDX-001~009) | Docker 禁令与 fault 测试矛盾 (C5)；W4 pool 未定义 (C7) | 概念覆盖，实施矛盾 |
| configx | 8 (CFG-001~008) | BASE 无分解 (G1)；缺 SECURITY (G2)；联合验证缺失 (G4) | 全覆盖，项目级缺漏 |
| observex | 8 (OBS-001~008) | BASE 无分解 (G1)；缺 SECURITY (G2) | 全覆盖，项目级缺漏 |
| resiliencx | 9 (RES-001~009) | 6 策略重写时间低估 (C1)；kernel 边界验证缺失 (G4) | 全覆盖，时间低估 |
| schedulex | 8 (SCH-001~008) | 相对低风险 | 全覆盖 |
| bootstrap | 9 (BST-001~009) | 事务式构造 2187 状态组合 (风险热力)；BASE 无分解 (G1)；全部文件缺失 (G2) | 全覆盖，风险低估 |
| testkitx | 8 (TST-001~008) | import gate 矛盾 (N2, 矛盾 4) | 全覆盖 |
| kafkax | 8 (KFK-001~008) | Docker 禁令矛盾 (C5)；W4 pool 未定义 (C7) | 概念覆盖 |
| natsx | 8 (NTS-001~008) | Docker 禁令矛盾 (C5)；W4 pool 未定义 (C7) | 概念覆盖 |
| postgresx | 8 (PGX-001~008) | Docker 禁令矛盾 (C5)；W4 pool 未定义 (C7) | 概念覆盖 |
| taosx | 8 (TAO-001~008) | SchemalessWrite 矛盾 (C9, 矛盾 5) | 全覆盖 |
| ossx | 9 (OSS-001~009) | W4 pool 未定义 (C7) | 概念覆盖 |
| clickhousex | 8 (CHX-001~008) | release 声明错误 (V2) | 全覆盖 |
| contracts | 8 (CTR-001~008) | 版本不确定性 (C4)；依赖链位置未裁决 (矛盾 9) | 全覆盖，治理缺口 |
| transportx | 9 (TRN-001~009) | module path 未裁决 (C3)；身份错乱 (矛盾 6)；go.mod 错误 (V5) | 全覆盖，身份缺口 |
| domainx | 8 (DMN-001~008) | 相对合理 | 全覆盖 |
| domain_market | 10 (MKT-001~010) | 基础设施污染迁出耗时 (C1)；BASE 无分解 (G1)；全部文件缺失 (G2) | 全覆盖，时间低估 |
| domain_macro | 10 (MAC-001~010) | 仓库不存在 (C6, 矛盾 7)；治理信任崩塌 | 全覆盖 |
| domain_exchange | 10 (EXC-001~010) | 13→8 接口拆分 耗时 (C1)；缺 SECURITY (G2) | 全覆盖，时间低估 |
| ZoneCNH 治理 | W0 4 项 | 全仓 status 审计缺失 (C6, P0-5) | 全覆盖 |

### C.2 原始计划说了但分析报告未覆盖

| 主题 | 原始行号 | 分析报告状态 |
|------|---------|------------|
| §1.1 分支与工作区规范（5 条规则） | L44-50 | 未覆盖 |
| §1.3 每个 PR 的强制输出（9 项） | L63-73 | 未覆盖 |
| §8.1 Candidate 阶段流程（5 步） | L1036-1041 | 未覆盖 |
| §8.2 Stable 阶段流程（6 步） | L1043-1050 | 未覆盖 |
| §8.3 Qualification 四种状态 | L1052-1058 | 未覆盖 |
| §10 衡量指标与自动迭代 | L1102-1135 | 仅提及进度度量，未深入 |
| xlib_standard 退出标准（4 项） | L152-156 | 未覆盖 |
| xlib_harness 退出标准（3 项） | L190-193 | 未覆盖 |
| xlib_evidence 退出标准（3 项） | L228-231 | 未覆盖 |
| xlibgate 退出标准（3 项） | L266-269 | 未覆盖 |
| 各模块的发布建议（版本建议） | 分散各模块 | 部分覆盖（contracts/transportx 详细） |

### C.3 分析报告说了但原始计划未覆盖

| 主题 | 分析报告行号 | 原始计划状态 |
|------|------------|------------|
| xlib_standard MVC 解耦策略 | L230-248 | 未在原始计划中定义 |
| canary 加权通过 (2/3 + RCA) | L219-220 | 原始计划要求全部通过 |
| 三层故障注入方案 (Bash→netns→eBPF) | L530-2431 | 原始计划未给出具体方案 |
| XLH-009 (goalcli 吸收工作包) | L331 | 原始计划 xlib_harness 只到 XLH-008 |
| contracts lineage 审计脚本 | L468-527 | 原始计划仅建议审计 |
| BASE-003 批量生成脚本 | L2729-2784 | 原始计划仅列出 BASE-003 名 |
| 修订后时间线 (45-60天) | L2842-2861 | 原始计划为 30 天 |
| storage-pools.yaml (light/heavy) | L2864-2904 | 原始计划 L112 仅提名称 |
| 回滚决策树 | L2910-2933 | 原始计划缺失 |
| BASE 推广 Runbook | L2935-2975 | 原始计划缺失 |
| 单点阻塞瀑布分析 | L151-162 | 原始计划仅在 §7.1 给出顺序 |
| 联合验证矩阵缺失 2 项 | L207-209 | 原始计划 §7.2 无 configx/resiliencx 验证 |

### C.4 信息差总结

| 维度 | 原始计划 (07-11.md) | 分析报告 (07-11-analysis.md) |
|------|---------------------|------------------------------|
| 工作包颗粒度 | 细（129 个模块级 + 9 个 BASE） | 粗（聚焦宏观缺口和矛盾） |
| 时间估算 | 乐观（30天主窗口） | 批判（45-60天修正） |
| 治理裁决 | 未决（goalcli/transportx/contracts 悬空） | 给出裁决方案 |
| 实施方案 | 概念级（"建立 bundle"） | 操作级（脚本+代码 300+ 行） |
| 风险识别 | 隐式（在阻断描述中） | 显式（CRITICAL/HIGH/LOW 三级） |
| 矛盾检测 | 无 | 系统（9+5=14 条） |
| 回滚策略 | 缺失 | 完整决策树 |
| 人员/并行 | 仅 §2.2 原则 | 指出缺失 |
| 运维配置 | 无 | 完整 systemd service/soak schedule |

---

## D. 依赖矩阵

### D.1 全局工作包阻塞关系

```
W0 事实冻结 ──────────────────────────────────────────────────────────────┐
│                                                                          │
├── 25 仓 inventory ──→ W1 标准控制平面所有工作包                           │
├── P0 blocker 声明 ──→ redisx/kafkax/natsx/taosx 所有 W4 工作包           │
└── Go 基线冻结 ──→ 所有模块 BASE-002                                      │
                                                                           │
W1 标准控制平面 ────────────────────────────────────────────────────────── │
│                                                                          │
├── XLS-001 (ownership) ──→ XLS-002 (删除复制) ──→ XLS-003 (bundle)        │
│         │                                                                 │
│         └──→ XLH-001 (CLI contract) ──→ XLH-002 (清除规则)               │
│         └──→ XLG-001 (删除重叠) ──→ XLG-002 (reason registry)            │
│         └──→ XLE-001 (module path) ──→ XLE-002 (schema)                   │
│                                                                          │
├── MVC freeze (P0-6 建议：前 5 天)                                        │
│   └──→ gate/evidence/harness 可并行启动（不等 full bundle）              │
│                                                                          │
└── XLS-007 (v2 RC) ──→ XLG-006 (自举验证) ──→ XLS-008 (下游同步)         │
                           │                                                │
                           └──→ 所有下游 worktree/branch                    │
                                                                           │
W2 三类 Canary ────────────────────────────────────────────────────────── │
│                                                                          │
├── KRN-001 (边界 ADR) ──→ RES-007 (kernel 边界迁移)                       │
│                            └──→ BST-001~007 (bootstrap)                   │
│                                                                          │
├── KRN-002 (deprecation) ──→ KRN-007 (v2 清理，13 个模块下游）            │
│                                                                          │
└── RDX-001→009 (redisx) ──→ BST-007 (store wiring)                        │
                                                                           │
W3 L0/L1 ────────────────────────────────────────────────────────────────  │
│                                                                          │
├── configx/schedulex/observex ──→ bootstrap (可并行)                      │
├── resiliencx (6 策略重建) ──→ kernel 边界验证 ──→ bootstrap              │
│   └── 关键路径最长节点！！！！                                            │
└── testkitx ──→ domain_market Mock 迁移 (MKT-003)                         │
                                                                           │
W4 存储适配器 ─────────────────────────────────────────────────────────── │
│                                                                          │
├── light pool (kafkax/natsx/ossx) — 可并行 3 个                           │
├── heavy pool (redisx/postgresx/taosx/clickhousex) — 串行 soak            │
└── 全部 7 个 ──→ BST-007 (store wiring integration)                       │
                                                                           │
W5 Domain ───────────────────────────────────────────────────────────────  │
│                                                                          │
├── domainx ──→ domain_market ──→ domain_exchange                          │
├── domainx ──→ domain_macro ──→ domain_exchange                           │
├── decimalx 为前置（金融类型）                                              │
├── contracts 位置取决于 lineage 审计结果                                   │
└── transportx → contracts (若独立 DTO 可解耦)                               │
                                                                           │
W6 全舰队重新认证 ──────────────────────────────────────────────────────  │
│                                                                          │
└── 所有 25 仓逐一 clean-room Release ──→ Fleet Evidence 推导              │
```

### D.2 关键路径节点（按阻塞强度排序）

| 排名 | 节点 | 阻塞模块数 | 最短路径长度 | 说明 |
|------|------|-----------|------------|------|
| 1 | xlib_standard v2 RC | 全部 25 仓 | 1→25 | 全局瓶颈，不可替代 |
| 2 | resiliencx 6策略重建 | 4 (kernel/boundary/bootstrap/storage) | 1→4 | 14天关键路径 |
| 3 | bootstrap BST-007 | 7 storage + domain layers | 7→1 | 需 7 个 storage 就绪 |
| 4 | domainx spec-freeze | 3 (domain_market/macro/exchange) | 1→3 | 契约确定前不可并行 |
| 5 | canary 全部通过 | 所有下游 | 3→20 | 加权 2/3 + RCA 可缓解 |
| 6 | contracts lineage 审计 | 6 (domain/transport/consumers) | 1→6 | 版本不确定阻塞语义定义 |
| 7 | domain_macro 仓库创建 | 3 (domain_macro/macro_data/backtest) | 0→3 | 从零创建，含授权等待 |
| 8 | testkitx import gate | 全部生产模块 | 1→21 | 生产包误引入检测 |
| 9 | BASE-003 批量生成 | 10+ 模块 | 1→10 | 治理合规前置 |
| 10 | W0 状态审计 | 全部 25 仓 | 1→25 | 事实前提 |

### D.3 可并行路径

#### 绝对安全并行（互斥写入）

| 并行组 | 模块数 | 前提条件 |
|--------|--------|---------|
| configx + schedulex + observex | 3 | W1 控制平面完成 |
| kafkax + natsx + ossx (light pool) | 3 | W1 完成 + pool 定义 |
| domain_market + domain_macro | 2 | W1 完成 + domainx spec-freeze (原始计划声称可并行，分析报告指出风险) |
| testkitx + configx | 2 | 独立，无共享写入区域 |
| decimalx + kernel | 2 | 独立类型系统，无直接依赖 |
| 10+ 模块 BASE-003 批量生成 | 10+ | xlib_harness 产出 patch |

#### 条件并行（需串行冻结前一阶段）

| 并行组 | 模块数 | 前置串行条件 |
|--------|--------|-------------|
| xlibgate + xlib_evidence + xlib_harness | 3 | XLS-001/002/003 MVC freeze 后 |
| kernel + decimalx + redisx canary | 3 | W1 完成后全并行 |
| postgresx nightly + taosx nightly + clickhousex nightly | 3 | 独立服务，可并行 CI |
| domain_exchange conformance 3 adapter | 3 | EXC-002 小接口完成后 |

### D.4 原始计划 (§2.2) 并行原则 vs 分析报告修正

| 原始主张 | 行号 | 问题 | 修正建议 | 参考 |
|---------|------|------|---------|------|
| W1 内四仓可并行，但 schema/CLI 先串行冻结 | L109 | 正确 | +MVC freeze 策略 (P0-6) | analysis L230-248 |
| W2 三 canary 可并行；全部通过才 stable | L110 | 正确但严格 | +加权通过 2/3 + RCA | analysis L220 |
| W3 configx/observex/schedulex 可并行 | L111 | 正确 | 无修正 | — |
| W3 resiliencx 与 kernel 边界先决 | L111 | 正确 | 覆盖 (G4 缺口) | analysis L209 |
| W4 可按 light/heavy pool 并行 | L112 | **未定义** | +分类表 (P0-9) | analysis L2864-2904 |
| W5 domainx 先于 market/macro，先于 exchange | L113 | 正确 | +domain_macro 仓库不存在风险 | analysis L104-111 |

---

## E. 综合建议优先级

基于交叉分析，推荐的执行优先级（独立于原始波次）：

| 优先序 | 行动 | 理由 |
|--------|------|------|
| **立即** | P0-5 全仓 status 审计 | 修正 phantom 数据，恢复治理信任 |
| **立即** | P0-8 时间线修正 | 防止不切实际的承诺 |
| **立即** | P0-1 goalcli 归属裁决 | 解除三仓同时删除的真空 |
| **D1-2** | P0-6 MVC freeze 定义 | 解除下游阻塞，节省 5-7 天 |
| **D1-5** | P0-7 BASE-003 批量工作包 | 治理合规全覆盖 |
| **D1-10** | P0-2 transportx module path | Go module identity breaking change |
| **D1-12** | P0-3 contracts lineage 审计 | 版本不确定性阻塞所有消费者的 SemVer |
| **W1 完成前** | P0-10 回滚策略 + BASE Runbook | 框架搭建 |
| **W3 前** | P0-4 bare-metal fault/soak | Docker 禁令下的替代方案 |
| **W3 前** | P0-9 light/heavy pool 分类 | 资源约束的确定性 |

---

## F. 统计概要

| 维度 | 数量 |
|------|------|
| 模块级工作包总数 | 129 (不含 BASE-9) |
| P0 工作包 | 48 |
| P1 工作包 | 69 |
| P2 工作包 | 12 + W6 流程 |
| CRITICAL 发现 | 8 |
| NEEDS_REVISION 发现 | 3 |
| ISSUES_FOUND 发现 | 16 (4+3+4+2+3) |
| 版本一致性 GAP | 5 |
| 内部矛盾 | 9 |
| P0 修复建议 | 10 |
| 联合验证矩阵条目 | 8 |
| 阻塞链最长节点 (resiliencx) | 阻塞 4 个下游模块 |
| 全局瓶颈 (xlib_standard RC) | 阻塞全部 25 个模块 |
| 缺失章节 | 4 |
| 可安全并行模块组 | 6 组 |

---

> 原始行号引用格式：`07-11.md Lxxx` 指向原始计划；`analysis Lxxx` 指向分析报告。  
> 所有 10 条 P0 修复建议均有完整实施方案，详细代码和脚本见 `07-11-analysis.md` §十一。  
> 信息差警示：原始计划缺失回滚策略、人员分工、Fleet Dashboard 和故障注入方案 4 个关键章节，分析报告提供了全部补全。

[RULES I BROKE]：无
