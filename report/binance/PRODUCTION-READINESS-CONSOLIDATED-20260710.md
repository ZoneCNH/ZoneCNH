# Binance 四业务线生产就绪综合复审与优化报告

> [COMPUTED, HIGH] 审计窗口：2026-07-10 至 2026-07-11（Asia/Shanghai）。
> [COMPUTED, HIGH] ZoneCNH 审计基线：`b870934a940688f057c1391bfcd039e56ca16e76`。
> [COMPUTED, HIGH] runtime 审计基线：`b20f6d44f8b246149c7a9f9c06a4dc27bc7b49ef`。
> [COMPUTED, HIGH] runtime 整改提交：`e2c4970896153fd89ead3771eb302d85410643c9`、`bcde5357a25d71c02a7b841612b05eb0b32f1786`。
> [COMPUTED, HIGH] 修复分支：两个仓库均为 `fix/binance-production-readiness-20260710-v2`，且均位于规范 worktree 路径。
> [COMPUTED, HIGH] 审计方式：Agent Team 多轮并行覆盖规格、runtime、数据完整性与发布证据；实现任务按互斥写范围推进，随后分别执行 Standards、Spec、并发与证据信任链对抗复审。
> [COMPUTED, HIGH] 范围：公共市场数据 `spot`、`um_perp`、`cm_perp`、`options`；不包含下单、账户、仓位、私有用户流或策略。
> [COMPUTED, HIGH] 协议复核交叉使用 Binance Developer Catalog 与官方 `binance-connector-js` 提交 `a4a5fb66804c4387d5437c84927a1bc4816391fb`，避免以仓内旧文档反过来证明实现正确。

## 1. 最终裁决

**[INFERRED, HIGH] 当前裁决为 No-Go，不能把现有 `binance` 候选声明为生产可发布。**

[COMPUTED, HIGH] 当前 canonical 规格投影为 `13 Done / 52 Partial / 0 Drifted / 0 Pending`，`release_closeable_spec=NO`、`release_closeable_runtime=NO`。

[COMPUTED, HIGH] 本轮已修复同毫秒 aggTrade 丢失、CM kline 前缀静默丢失、实时/历史 trade 粒度错配、Options/UM/CM 非法流名与路由、历史任务提前完成、白名单版本回滚与 Options fail-open 绕过、client 内存背压/PubAck retry、跨产品订单簿 dispatch、订单簿畸形数据部分写入/旧 generation 覆盖/持久快照假 fresh、consumer DLQ durability、OSS 混分区/失败丢批、发布证据假绿和部署文档越界等高风险问题。

[COMPUTED, HIGH] No-Go 仍由两类独立条件共同构成：一类是 client 可靠投递策略与 canonical spec 的冲突、Options 订单簿 live 对齐/容量证据、订单簿 generation/freshness、Catalog diff、coverage 能力矩阵、funding 独立数据、OSS 归档 durability；另一类是 GitHub `main` 当前未受 branch protection/ruleset 保护、fixed attested signer workflow 仍为强制失败的占位合同，NATS、Kafka、TDengine、Redis、部署 API 五项签名外部门禁及 tag/release notes/preflight/rollback 证据均未绑定同一 RC。

[INFERRED, HIGH] 用户目标明确包含四业务线与订单簿，因此本报告不采用“只存在代码路径、没有 live 证据”来制造 Go 结论；只有负责人显式缩小 release profile，或 Options 订单簿完成容量、snapshot+diff、重连与 checksum 验收，才能改变该项判定。

## 2. 四业务线能力矩阵

[COMPUTED, HIGH] 下表判定以当前审计基线和本轮 feature worktree 为准；`PARTIAL` 表示存在实现但尚未形成生产闭环，`BLOCKED` 表示发布硬阻断。

| 业务线 | 实时行情 | 历史同步 | 白名单 | 本地订单簿 | 发布判定 |
| --- | --- | --- | --- | --- | --- |
| `spot` | [COMPUTED, HIGH] PARTIAL：默认实时改用 `@aggTrade`；有界内存 Queue/Relay、阻塞背压与 PubAck retry 已接入，只有 durable ACK 才移除；进程崩溃窗口仍被规格明确接受为可丢失 | [COMPUTED, HIGH] PARTIAL：aggTrade ID 分页、周期传递与 durable completion 已修；每页 checkpoint/水位对账未闭环 | [COMPUTED, HIGH] PARTIAL：tier SSOT、严格空集、动态刷新与版本单调已修；Catalog candidate/admission 尚未分层 | [COMPUTED, HIGH] PARTIAL：复合身份 dispatch、畸形事件原子拒绝、旧 generation 隔离和持久快照 bridge 已修；断连 freshness 与完整增量输出仍未闭环 | [INFERRED, HIGH] NO |
| `um_perp` | [COMPUTED, HIGH] PARTIAL：默认 `@aggTrade`、`@depth@100ms`、`@markPrice@1s` 已校正且不再订阅非法 `1s` kline；独立 `funding_rate` 事件未形成 | [COMPUTED, HIGH] PARTIAL：trade/kline 支持且超过 24h 显式拒绝；官方长历史归档源与 funding/mark 专用解析未实现 | [COMPUTED, HIGH] PARTIAL：产品线隔离、乱序版本拒绝已修；真实审核/回灌证据未闭环 | [COMPUTED, HIGH] PARTIAL：depth mode、product-aware dispatch 与 capability reconcile 已修；freshness 契约仍在 | [INFERRED, HIGH] NO |
| `cm_perp` | [COMPUTED, HIGH] PARTIAL：流名/周期已与 UM 同步校正；delivery/quarterly 与 perpetual discovery 语义尚未完全隔离 | [COMPUTED, HIGH] PARTIAL：kline 按 1000 根与 200 天上限前向分窗，已阻断返回“最近 limit 条”造成的前缀丢失；长历史 trade 源仍缺 | [COMPUTED, HIGH] PARTIAL：产品线隔离与版本单调已修；真实变更回灌未形成发布证据 | [COMPUTED, HIGH] PARTIAL：复合身份与 mode 已修；rebuild/persist/freshness 未闭环 | [INFERRED, HIGH] NO |
| `options` | [COMPUTED, HIGH] PARTIAL：官方 `@optionTrade`/`@optionTicker`/depth 已走 `/public`，kline 走 `/market`，无活跃 catalog 时不再订阅伪 symbol；容量预检和数组消息展开仍有缺口 | [COMPUTED, HIGH] PARTIAL：公共 kline `/eapi/v1/klines` 及 testnet REST 已接入；trade/depth 历史明确 unsupported | [COMPUTED, HIGH] PARTIAL：provider 不可用/fail-open 时改为严格 deny-all，仅显式批准集可订阅；人工审核真实 E2E 未闭环 | [COMPUTED, HIGH] PARTIAL：已接入显式订单簿白名单、`/eapi/v1/depth` 与 full-incremental manager；尚无 live alignment/reconnect/checksum 证据 | [INFERRED, HIGH] NO |

## 3. 行情数据流与可靠性边界

[FRAME, HIGH] 生产目标数据流应使用以下责任边界；箭头表示事实在发布前必须经过的确认链，而不是当前所有节点均已闭环。

```text
Binance exchangeInfo ──► Candidate Catalog ──► Product-line Admission/Whitelist
                                                    │
Binance WS/REST ──► Connector ──► Normalize ──► Reliable client handoff
                                                    │ durable publish ACK
                                                    ▼
                                              NATS JetStream
                                                    │ ManualAck
                                                    ▼
                  ┌──────── DLQ durable handoff ◄── Server validation/idempotency
                  │                                 │
                  │                                 ├──► Raw durable SSOT
                  │                                 ├──► TDengine / hot cache
                  │                                 ├──► Kafka fanout / query API
                  │                                 └──► Partitioned OSS archive
                  │
                  └──────── replay after root-cause repair
```

[COMPUTED, HIGH] `Connector → reliable client handoff` 的进程内路径已接通：四线共用 collector 改为 context-aware blocking send，`LiveDelivery` 使用有界内存 Queue/Relay/Cursor；`MaxPublishRetry=N` 现在严格表示首次 publish 后再重试 N 次。单个 retry window 耗尽会触发带 `BNC-CLIENT-4004`/`ErrNATSPubAck` 的结构化告警，在 capped backoff 后继续持有并重试同一队列，而不是让 runtime 解栈；只有 durable PubAck 才移除事件和推进 cursor。operator-facing queue/backoff 配置、专用 queue/retry 指标和 crash recovery 仍未闭合。

[COMPUTED, HIGH] `module/binance/spec/client/SPEC.md` §23 OQ-002 明确禁止本地 spool/checkpoint，并在故障矩阵中接受“进程崩溃时未 PubAck 事件丢失”；因此不能在不修改 Goal/Spec/Matrix 的前提下把磁盘 durable queue 私自接入生产。该规格选择与本次“数据完整性生产级”目标冲突，必须先由负责人裁决允许的丢失窗口，或批准本地 WAL/多实例冗余与可验证补数方案。

[COMPUTED, HIGH] 当前 server consumer 已接通持久 DLQ：JSONL 每条 `fsync` 后才返回成功，重启恢复去重 ID；非 smoke 环境缺 `FOUNDATIONX_BINANCE_DLQ_PATH` 会拒绝启动，配置路径同时绑定 writer 与 replay file。

[COMPUTED, HIGH] OSS 归档现按 `(product_line,event_type,UTC date)` 分区；批次 ID 使用 128-bit 加密随机量，熵失败 fail-closed；上传失败保留同一 pending batch/object key 并施加有界背压，受控 Close 会循环排空。pending/current 仍仅驻留进程内，SIGKILL 后的 archive retry 恢复尚未实现。

## 4. 本轮已完成的深度优化

### 4.1 历史同步

- [COMPUTED, HIGH] aggTrade 首页面按时间定位，后续页面仅用 exchange `fromId` 推进；本地再执行 `[from,to)` 过滤，避免 `timestamp+1ms` 跳过同毫秒事件。
- [COMPUTED, HIGH] `HistoryFetchResult` 新增 `SourceID`，排序、去重与 repair idempotency key 均纳入 exchange-native aggregate-trade ID。
- [COMPUTED, HIGH] 新增 1000 条同毫秒成交跨分页回归测试，验证 1002 个不同 ID 全部保留。
- [COMPUTED, HIGH] 回填 job 不再在创建时推进 coverage；只有 fetch 非空且每条 repair ingest 获得 durable ACK 后才标 completed 并推进 coverage。
- [COMPUTED, HIGH] transport error、reject、non-durable ACK、缺失 fetcher/ingestor、空结果均 fail-closed 为 failed，不能制造覆盖率。
- [COMPUTED, HIGH] daily reconciliation 现在从 `TradingDate` 推导 UTC `[00:00,24:00)`，只调度当前公共 REST 能力明确支持的 trade/kline；unsupported task 不再标 completed。
- [COMPUTED, HIGH] Options 新增官方公共 kline 路由；UM/CM `markPrice`/`fundingRate` 不再错误落到 kline endpoint，而是显式 unsupported。
- [COMPUTED, HIGH] UM/CM aggTrades 首个时间窗口改为严格小于一小时，REST 权重按 Spot/UM/CM/Options 端点分别计算；该修复不能突破 UM/CM 仅保留最近 24 小时历史的上游限制。
- [COMPUTED, HIGH] kline payload 现保留 quote volume、trade count 与 taker volumes；aggTrade 使用原始 JSON 对象，避免固定结构删除 futures `nq` 等新增字段；畸形行改为整页 fail-closed。
- [COMPUTED, HIGH] failed job 现可用同一 ID 重试；重启遗留 `running` 会转为 `failed`，首次状态落盘失败不会启动无记录 worker，快照保存已串行化，离散窗口不再被 min/max 桥接成虚假连续区间。
- [COMPUTED, HIGH] CM kline 现按 interval 与 1000 条上限前向分窗，并额外限制单窗最大 200 天；1500 根回归用例验证即使上游从 `endTime` 倒数返回最近 1000 根，仍保留前段。
- [COMPUTED, HIGH] lifecycle 的 kline `Interval` 现进入 History request/job/coverage/idempotency identity，`5m` 任务不再默认拉取 `1m`；不同周期的 coverage 也不再相互覆盖。
- [COMPUTED, HIGH] 损坏/不可读历史状态会投影为 `unavailable` 并拒绝 backfill/reconcile/catalog 覆写；文件保存改为 temp write→file fsync→rename→parent-directory fsync。

### 4.2 实时流与白名单

- [COMPUTED, HIGH] UM/CM 默认 diff depth 从 `@depth@1000ms` 校正为 sequence-bearing `@depth@100ms`，并对 Spot/UM/CM/Options 统一应用 order-book depth mode 过滤。
- [COMPUTED, HIGH] 订单簿 runtime dispatch 从 symbol-only 改为 `(product_line,symbol)`，避免 Spot 与 UM 同名 `BTCUSDT` 被当成歧义事件静默拒绝。
- [COMPUTED, HIGH] stream suffix 分类支持 `@depth@100ms`、partial depth、`@markPrice@1s` 与 `@optionTicker`；严格白名单下未知 suffix 不再无条件放行。
- [COMPUTED, HIGH] client 不再把服务端未返回的 `allowed_streams=0` 解释为 StreamAll，而是从 `prime/standard/lite/blocked` tier capability SSOT 推导 stream mask；blocked/unknown tier fail-closed。
- [COMPUTED, HIGH] 白名单不再跨市场扁平化；Spot、UM、CM、Options 各自取产品线集合，非 nil 空集合表示 deny-all，nil 才表示显式 fail-open/no-policy。
- [COMPUTED, HIGH] 所有四个 connector 均安装动态白名单 snapshot，cache update 会触发 connector refresh，不再只给 Spot 注入启动时快照。
- [COMPUTED, HIGH] 严格空白名单不再使 connector goroutine 永久退出；首次拉取失败会进入可观测 fail-open，回调安装也改为加锁，消除启动后赋值的数据竞争。
- [COMPUTED, HIGH] Options 使用独立公开流 capability，不再因空 tier 被误判 blocked；Options OrderBookManager 只允许显式订单簿白名单且仅使用 full-incremental 模式，fail-open 不会订阅全量期权合约。
- [COMPUTED, HIGH] OrderBookManager 在既有 symbol 的 feature/depth capability 变化时会重建复合订阅，不再把旧能力保留到进程重启。
- [COMPUTED, HIGH] 白名单 HTTP/NATS/timer refresh 已串行化，cache 在锁内拒绝旧/同版本变更，增量版本 gap 强制回到全量快照；旧 v11 慢响应不再能覆盖已应用的 v12。
- [COMPUTED, HIGH] Options 未加载/provider 失败/fail-open 均改为严格 deny-all，非 `OrderbookEnabled` 项不再获得 depth bit；OrderBook reconcile 整轮串行且拒绝旧 generation 回加已撤销 symbol。
- [COMPUTED, HIGH] 实时默认流已改为 Spot/UM/CM `@aggTrade`、Options `@optionTrade`；Options trade/ticker/depth 路由 `/public`，kline 路由 `/market`，三条衍生品不再混入 Spot-only `1s` kline。
- [COMPUTED, HIGH] canonical trade side 现按 aggressor 语义映射：`m=true` 表示 buyer maker，因此主动方为 SELL；Options `S` 字段存在时优先使用官方显式方向。
- [COMPUTED, HIGH] `RunStandalone` 已接入有界内存 `LiveDelivery`；collector 满 channel 时阻塞而不是 drop，transport error/non-durable ACK 按“首次 + N 次重试”执行指数退避，窗口耗尽告警后仍阻塞重试同一内存队列，durable PubAck 前事件不会被删除或推进 cursor。
- [COMPUTED, HIGH] 订单簿对每个 snapshot/diff 先整批校验 price/qty；畸形行不再部分修改 book、推进 update ID 或转发增量。持久快照仅作为 BUFFERING candidate，经产品线 bridge 后才 ALIGNED；旧 generation REST 结果不能覆盖新 generation。
- [COMPUTED, HIGH] Spot 与 UM/CM snapshot bridge 保持独立公式；`rebuild_start/complete` marker 使用 2048-key 有界、按 instrument/type/generation 合并的队列，下游阻塞时对新 key 施加背压。`OrderBookManager.Close()` 现在取消并等待 REST alignment、TopN、persist、checksum、marker dispatcher 与 symbol state machine；单 symbol revoke 也会取消并等待该 symbol alignment。checksum 按稳定 identity 轮转 `ChecksumSampleSize` 子集并受 `ChecksumConcurrency` 限制；`RunStandalone` 退出时先摘除回调可见指针再关闭 manager。
- [COMPUTED, HIGH] `BUFFERING→ALIGNED` 现在由 `bufferMu` 与单调 `bufferEpoch` 共同提交：REST/持久化恢复在锁内应用完整 tail、清空 buffer 并切换状态；clear/refill ABA 会拒绝旧前缀并在没有下一条事件时自动重拉，已读 BUFFERING 但锁后已 ALIGNED 的事件改走 aligned 路径。AlignReject/Wait 同时比较 epoch 与捕获长度，计算期间 append 不再因 `aligning=true` 吞掉重试。
- [COMPUTED, HIGH] `snapshot_topn` 任一非法 price/qty 会保留旧 book 作为 last-known state，但立即转为 `BUFFERING/stale`，fresh 查询返回 nil，不部分写入或推进 update ID，并以可取消背压向下游发送保留旧档位/旧 ID 的 `Stale=true` 安全边界；会造成 ABA/跨 symbol 内容错读的全局 Book pool 已移除，last-known snapshot 也有独立并发锁。
- [COMPUTED, HIGH] orderbook `FilePersistor` 已改为唯一 temp→file fsync→rename→directory fsync，首次目录创建逐级同步父目录；同 symbol 并发保存串行且等待可被 context 取消。该快照仍只作为 untrusted recovery candidate，必须经 sequence bridge 才能 fresh。
- [COMPUTED, HIGH] orderbook 增量档位、`LastUpdateID` 与 update time 由单次 Book 写锁原子提交；per-symbol mutation gate 将 event apply/forward、checksum、overflow rebuild 与 snapshot replacement 串行到同一 generation，旧读 ALIGNED 的事件在 rebuild 后转入 buffer。checksum 仅在 generation、manager/book identity、ALIGNED 状态及 REST/live update ID 均稳定一致时比较档位；正常实时推进或同 symbol book 换代会跳过，真实同 ID drift 仍触发 rebuild。snapshot rebuild 在清 book 前可靠发送 retained stale TopN，下一完整快照发送 `rebuild_complete`。
- [COMPUTED, HIGH] 白名单 stream/orderbook policy 现由同一原子 snapshot 读取；refresh 在锁内共同提交 cache 与 degraded 状态、锁外派发可重入 callback，provider 在读取中退化时 Options 仍 deny-all。全量、增量与版本确认区分 stale 与 persistence error：rename 前失败不发布内存版本，rename 已提交但目录同步失败时内存跟随磁盘并让 Client 进入显式 degraded；首次创建缓存目录还会逐级同步父目录项，避免磁盘/内存分叉与误报 stale。

### 4.3 Server durability 与治理

- [COMPUTED, HIGH] assembly 已将已配置的 `DeadLetterWriter` 显式注入 consumer runner；processor panic 在 writer 存在时先 durable write 再 `Term()`，writer 不存在时保持未 ACK 而不是主动删除消息。
- [COMPUTED, HIGH] File DLQ 启动时扫描既有 JSONL 恢复 seen IDs；损坏 JSON、空白 ID 或截断尾行均 fail-closed；每条记录 fsync，首次创建同步 parent directory，正常关闭由 `Assembly.Close` 统一负责。
- [COMPUTED, HIGH] 非 smoke assembly 现在强制持久 DLQ path；缺失或 writer 初始化失败会在启动期 fail-closed，并清理已创建的 storage/dispatcher。
- [COMPUTED, HIGH] production kafkax 装配已启用 strict dispatch handoff；strict storage 失败即使 DLQ 成功也返回 retryable，strict Kafka 失败即使 primary storage 成功也不 ACK、不标 durable，strict 模式下 nil dispatcher 也在写 storage 前 fail-closed，DLQ 不再替代 strict primary barrier；`FOUNDATIONX_BINANCE_SKIP_KAFKA=1` 仅 smoke 允许，non-smoke 启动期拒绝。
- [COMPUTED, HIGH] OSS archive 已拆分混合产品/事件/日期批次，上传失败不再先删除内存 batch；同 key 重试、跨实例随机 batch ID、有界 pending/current 与 Close 排空均有 RED→GREEN 测试。
- [COMPUTED, HIGH] runtime README 的当前裁决已从错误的 `release_closeable=YES` 改为 NO；状态与 release-packet 校验器现在复用同一 external evidence validator。任意 `bash -c`/`BINANCE_EXTERNAL_*_COMMAND` 已失去发放 PASS 的能力，只有绑定固定 repo、signer workflow、signer digest、protected-main source ref 与 source digest 的 GitHub attestation artifact+bundle 才可能关闭五项 gate。
- [COMPUTED, HIGH] `status.txt` 的本地 PASS 行现仅作审计，不能授权 `release_closeable=YES`；status workflow 要求 `refs/heads/main` 且 `github.ref_protected=true`，用 clean child、fresh HOME、固定工具 PATH 与 `GOENV=off` 执行，并在每项门禁前后绑定当前 `GITHUB_SHA`。只有 YES 才实时重跑不可扩展的 format/boundary/build/test/race/vet/lint/smoke/diff 门禁；`head.log` 可绑定 evidence-only 提交的祖先 source SHA，但其后任何所选 evidence 目录之外的变更都会 fail-closed。
- [COMPUTED, HIGH] external evidence importer 使用 fresh exclusive output、0600/umask 077、symlink/NUL/CR/size/重复字段/事件 ID/双 SHA-256 校验，并为 root-owned fixed-path `gh attestation verify` 设置 60 秒超时；安全关键脚本固定 helper `PATH=/usr/bin:/bin`、清除 `GIT_*`、校验 canonical checkout 与 verifier 祖先目录，并拒绝异常 `BASH_ENV`/导出函数。所有发布判定入口以 clean environment 调 validator；PASS 只在私有 staging 完成共享复验后发布，最终 ledger 作为最后一个 commit marker。status workflow 只在 main push 时使用 §17 受治理 runner，不执行 pull-request 或 feature-ref 脚本。
- [COMPUTED, HIGH] 深度复审将 Options/orderbook、当前 RC evidence 与数据完整性假绿项一并降级；canonical 投影为 `13 Done / 52 Partial / 0 Drifted / 0 Pending`，spec/runtime 均为 NO。
- [COMPUTED, HIGH] docs gate 新增 Matrix 行计数、Summary 与五个活跃入口的一致性检查，原先的 65/0 与 43/22 双真相将直接失败。
- [COMPUTED, HIGH] 六份核心部署/运维文档（`deploy/` 三份、gate 两份、release 一份）已移除具体基础设施操作、环境地址、账户与敏感路径，统一引用 `docs/sre/DEPLOY-CONTRACT.yaml` 的 `zonecnh.deploy-contract.v1` 和 `sre/deploy` 执行平面。

## 5. 尚未闭环的发布硬阻断

### 5.1 P0：本地实现

1. [COMPUTED, HIGH] client 有界内存 queue/backpressure/PubAck retry 与 transport/non-durable retry-window 已接入，窗口耗尽不会再解栈丢掉仍可达的内存队列；但 canonical spec 禁止本地 spool 并接受 crash-window 丢失。queue/backoff/max-retry 仍无 operator 配置桥接，queue-depth/retry-exhaustion 也无专用指标或告警 sink。因此尚不能证明进程崩溃与长故障场景的数据完整性。
2. [COMPUTED, HIGH] Options 已有显式白名单的 OrderBookManager、REST snapshot 与 sequence alignment 代码路径，但仍缺真实 live snapshot+diff、断线重连、合约过期 churn、容量上限与 checksum 对账证据，不能视为生产闭环。
3. [COMPUTED, HIGH] Spot/UM/CM 的畸形事件原子性、alignment generation/revoke 生命周期、buffer/state 原子交接、Reject append 与 clear/refill ABA 重试、mutation/rebuild 跨代隔离、candidate 文件与目录 durability barrier、持久快照 bridge、snapshot stale/complete 边界、非法 top-N reliable fail-stale、同 ID checksum 与 marker 有界/可关闭生命周期已修；但 WS disconnect 尚无可观察的 connector→manager stale/rebuild 接线，普通增量仍为 best-effort，持续阻塞时同 key 中间 generation 会被有界合并；checksum 在高流速下无法取得相同 update ID 时会跳过，尚无断电级 crash test，canonical 也未定义 snapshot max-age/强制 checksum 阈值。
4. [COMPUTED, HIGH] Catalog discovery 与 admission 仍未彻底分层；现有过滤发生在 `DiffSync` 前，策略移除可被投影为 exchange delisting，新上市候选也无法形成独立 candidate 集。
5. [COMPUTED, HIGH] Catalog diff 没有真实 Updated 语义，runtime 发布消息也不能可靠表达 Added/Updated/Removed；server delisted checker 未在生产装配中强制启用。
6. [COMPUTED, HIGH] coverage reporter 仍以历史 backfill coverage 代替实时 WS 观测，server scanner 又对所有产品线统一要求 trade/bookTicker/kline/funding/mark；该能力矩阵在 Spot/Options 上不成立。
7. [COMPUTED, HIGH] UM/CM `@markPrice@1s` 的 payload 含 funding 字段，但 normalize 只产生 `mark_price_update`，不会形成独立 `funding_rate` 数据流；专用历史 funding endpoint/decoder 也未实现。
8. [COMPUTED, HIGH] OSS 混分区、失败即丢、跨实例弱 key 已修；但 pending/current retry 仍是进程内状态，SIGKILL 后不能恢复，且 archive 是否位于 server ACK durable barrier 内仍需负责人裁决。
9. [COMPUTED, HIGH] production DLQ path 已改为必填；但 pinned `natsx v1.0.5` 的 `FetchMessage` 不暴露单消息 delivery attempt/metadata，consumer 无法在本仓内可靠识别 MaxDeliver 重试耗尽；parent-directory fsync 也尚无断电级 crash test。
10. [COMPUTED, HIGH] history failed-job retry、重启 recovery、初始落盘失败、状态加载 fail-closed、fsync 和 interval 隔离已修；但每个 `(product_line,symbol,data_type,interval)` 仍只保留一个 coverage 区间，“fetch 非空”仍会把整个请求窗口记为 covered，没有 source watermark/count/hash 完整性证明；reconcile 未严格按 `as_of`、产品能力、事件类型与目标窗口逐项验证。
11. [COMPUTED, HIGH] UM/CM aggTrades 仅允许查询最近 24 小时，而当前 04:00 UTC daily job 回填完整前一 UTC 日，窗口开头届时已超过上游保留期；在引入连续增量 checkpoint 或官方历史归档源之前，该 daily trade 路径只能稳定失败，不能声称历史完整。
12. [COMPUTED, HIGH] lifecycle 已传递显式 kline interval，但 daily/default cold-start 仍只生成单个 `1m` kline 周期，不能证明规格要求的多周期历史完整；抓取仍先将所有页聚合到内存后串行重放，无页级 durable cursor。
13. [COMPUTED, HIGH] release evidence 门禁已改为固定 GitHub attestation 信任链，并由 status/release-packet 共同复验；旧的本地回显、伪造十行 PASS、stale source SHA、`GOFLAGS=-run=^$`、`BASH_ENV` startup、caller-PATH/GIT 环境重定向、最小 ledger+marker、unsigned bundle、symlink 与覆盖重跑 PoC 均 fail-closed，PASS ledger 也不再早于组合复验发布。但 GitHub API 于 2026-07-11 返回 `main protected=false` 且 ruleset 为空，status workflow 会正确拒绝；`.github/workflows/binance-external-gates.yml` 仍固定退出失败且没有 attestation 权限。真实签名正向路径、隔离 runner 上的同 UID/TOCTOU 威胁边界、current packet、live E2E、remote CI、tag/release notes/preflight/rollback 均未绑定同一 RC。
14. [COMPUTED, HIGH] root、client、server 规格仍复用相同 `FR-*` 标识表达不同语义；当前 docs gate 只能比较 root SPEC/FEATURES/Matrix 的 ID+状态，不能证明子规格语义唯一，追溯链仍存在 ID collision。

### 5.2 P0：外部证据与 GitHub 控制面

[COMPUTED, HIGH] 当前 `release/evidence/binance/20260710/external-gates.tsv` 的五项结果均为 `BLOCKED/NOT_RUN`。

[COMPUTED, HIGH] 2026-07-11 的 GitHub API 读回为 `main protected=false`、repository rulesets `[]`；代码已把 `github.ref_protected=true` 设为 YES 的必要条件，因此在管理员配置保护规则前 status workflow 会 fail-closed。该配置属于外部仓库控制面，本轮未擅自修改。

| Gate | 当前状态 | 必需证明 |
| --- | --- | --- |
| NATS JetStream | [COMPUTED, HIGH] BLOCKED | [FRAME, HIGH] PubAck durability、duplicate PubAck、ManualAck、NAK/redelivery 与重启恢复 |
| Kafka | [COMPUTED, HIGH] BLOCKED | [FRAME, HIGH] 两个独立 consumer group 收到同一事件身份且无静默丢失 |
| TDengine | [COMPUTED, HIGH] BLOCKED | [FRAME, HIGH] 写入后 latest/range readback、同时间戳多事件与重放幂等 |
| Redis | [COMPUTED, HIGH] BLOCKED | [FRAME, HIGH] latest/range readback、key namespace、TTL 与故障恢复 |
| 部署 API | [COMPUTED, HIGH] BLOCKED | [FRAME, HIGH] deployed latest/range 响应与存储事件身份、时间边界一致 |

### 5.3 P0：安全事件处置

[COMPUTED, HIGH] 2026-07-10 文档审计在旧部署说明中发现环境地址和凭据样式字面量；本轮已从活跃文档删除，且报告不复述该值。

[COMPUTED, HIGH] 当前证据不能判断该字面量是否曾在任何环境真实生效，也不能证明仓库历史、派生缓存或既有会话已完成清理。

[INFERRED, HIGH] 安全门禁必须保持 BLOCKED，直至负责人完成对应凭据轮换、既有会话失效、访问日志审计、异常访问复核与仓库历史处置，并把签名回执绑定同一 RC；仅删除工作树文本不构成事件关闭。

## 6. 数据完整性生产契约

[INFERRED, HIGH] 只有把以下指标按 `product_line × event_type` 绑定 SLO、告警、证据有效期和 repair 状态，才能把“数据在流动”提升为“数据完整”。

| 维度 | 必需指标 | 发布门禁 |
| --- | --- | --- |
| Freshness | [FRAME, HIGH] last observed/acked event age、WS disconnect age | [FRAME, HIGH] 超阈值进入 stale，不得继续对外声称 fresh |
| Coverage | [FRAME, HIGH] expected vs observed interval coverage | [FRAME, HIGH] 只能由真实实时观测或 durable backfill ACK 推进 |
| Gap | [FRAME, HIGH] sequence gap、kline cadence gap、futures `pu` mismatch | [FRAME, HIGH] repair 完成且 durable replay 后才能关闭 |
| Duplicate | [FRAME, HIGH] exchange ID/request ID duplicate ratio | [FRAME, HIGH] 同毫秒多 trade 不得被 timestamp-only 去重 |
| Late data | [FRAME, HIGH] event-time lag P95/P99、late count | [FRAME, HIGH] late policy 与查询可见性必须确定 |
| Reconcile | [FRAME, HIGH] source↔raw↔query count/hash mismatch | [FRAME, HIGH] 不允许仅比较进程内计数 |
| Order book | [FRAME, HIGH] generation、stale、rebuild、buffer overflow、checksum drift | [FRAME, HIGH] stale/rebuilding 时下游必须收到可靠 marker |
| Durable ACK | [FRAME, HIGH] publish/consume/storage/DLQ latency 与 failure ratio | [FRAME, HIGH] ACK 之前必须满足选定的 durable barrier |
| Sink divergence | [FRAME, HIGH] raw/TDengine/cache/Kafka/API identity divergence | [FRAME, HIGH] 超阈值阻断 release |
| Archive | [FRAME, HIGH] partition completeness、upload retry、rehydrate checksum | [FRAME, HIGH] 混分区、失败丢批或不可回灌均为 blocker |

## 7. 历史同步生产契约

- [FRAME, HIGH] 每个 `(product_line,event_type)` 必须明确标记 `supported`、`postponed` 或 `unsupported`，并记录 endpoint、最大 page、cursor、时间单位、唯一键和 rate limit。
- [FRAME, HIGH] 所有窗口使用半开区间 `[start,end)`；分页游标必须由 exchange 唯一 ID 或官方唯一 open time 推进，不能只用“最后时间戳 + 1ms”。
- [FRAME, HIGH] REST→WS handoff 必须冻结 watermark，先回填至 watermark，再缓存/接续实时事件，最后按 exchange ID 去重。
- [FRAME, HIGH] job completion 必须等于 fetch 完整、每条 durable replay ACK、coverage 原子推进和 evidence 持久化全部成功。
- [FRAME, HIGH] 进程重启后 `running` job 必须显式恢复为可重试/failed，不得永久占用同一 idempotency key。
- [FRAME, HIGH] coverage 必须保存可证明的区间集合或等价 gap 表达；禁止用最小起点与最大终点把不连续窗口合并成虚假连续覆盖。
- [FRAME, HIGH] UM/CM trade 必须在 24 小时保留窗口内持续 checkpoint，或切换到可校验的官方历史归档；04:00 UTC 才回填完整前一日不满足交易所约束。
- [COMPUTED, HIGH] 本轮已实现官方约束分窗、completion、failed-job retry、restart recovery、初始/加载持久化 fail-closed、fsync、interval identity 与快照串行化；coverage 区间集合、页级 cursor、reconcile 能力矩阵、内存 resource governor 生命周期和多周期 daily 计划仍未闭环。

## 8. 白名单与 Catalog 生产契约

- [COMPUTED, HIGH] 当前 tier capability SSOT 为 `prime/standard/lite/blocked`；server 只需返回 tier，client 必须本地推导 streams/features/depth，不能依赖不存在的投影字段。
- [FRAME, HIGH] `nil policy`、`explicit empty`、`blocked symbol` 与 `provider failure` 必须是四个不同状态。
- [COMPUTED, HIGH] 本轮已区分 `nil policy`、`explicit empty`、`blocked`、`provider failure`；Options 对后三类强制 deny-all，Spot/UM/CM 的 provider failure 仍保留显式 fail-open 降级与告警语义。
- [FRAME, HIGH] 白名单 key 必须包含 product line；Spot 的 `BTCUSDT` 授权不能自动准入 UM 的同名 symbol。
- [FRAME, HIGH] Candidate Catalog 记录 exchange 事实，Admission/Collection 记录策略事实；策略移除不得被写成 exchange delisted。
- [FRAME, HIGH] Options 必须先通过人工审核/underlying 容量策略，再允许 connector 订阅；所需 shard 超过连接上限时 readiness 必须 fail-closed。
- [COMPUTED, HIGH] 本轮已完成 connector 侧产品线隔离与动态刷新，但 Candidate Catalog 与 Collection Catalog 的结构性分离仍是后续 P0。

## 9. 订单簿生产契约

- [COMPUTED, HIGH] 本轮已把事件身份固定为 `(product_line,symbol)`，让四业务线的 depth mode 只选择一种协议流，并为显式批准的 Options 合约接入 REST snapshot + diff alignment 路径。
- [FRAME, HIGH] 每次 rebuild 必须有单调 generation；旧 generation 的 snapshot、buffer、timer 与 marker 均不得修改新 book。
- [FRAME, HIGH] `rebuild_start`、`rebuild_complete`、stale 与 gap marker 必须可靠投递；非阻塞 channel 丢 marker 不符合生产语义。
- [FRAME, HIGH] persisted snapshot 只能在年龄、产品身份、sequence bridge、checksum 与 generation 均验证后转为 ALIGNED/fresh。
- [FRAME, HIGH] apply 任一 price/qty 失败必须阻断 update ID 推进并触发可审计 rebuild。
- [FRAME, HIGH] Options 必须基于官方已给出的 `U/u/pu` 字段，另行冻结并验证 snapshot bridge 算法，完成 reconnect replay 和 live comparison 后才能纳入四线订单簿发布 profile；不能把 UM/CM 的首次 bridge 公式未经证据直接当作 Options 官方契约。

## 10. 官方协议核验

- [COMPUTED, HIGH] Binance Options 公共 kline 使用 `GET /eapi/v1/klines`；本轮据此实现 Options kline history：[官方文档](https://developers.binance.com/legacy-docs/derivatives/options-trading/market-data/Kline-Candlestick-Data)。
- [COMPUTED, HIGH] Binance Options diff depth 文档给出 `U`、`u`、`pu` 与 `/public` 路由；因此“官方协议未知”已不是延期理由：[官方文档](https://developers.binance.com/legacy-docs/derivatives/options-trading/websocket-market-streams/Diff-Book-Depth-Streams)。
- [COMPUTED, HIGH] Spot snapshot bridge 丢弃 `u <= lastUpdateId` 的事件，随后按本地 update ID `+1` 检查 gap；UM/CM 则丢弃 `u < lastUpdateId`，首包要求 `U <= lastUpdateId <= u`，后续再校验 `pu == previous u`。两套公式不能统一成一个 `lastUpdateId+1` 规则：[Spot](https://developers.binance.com/zh-CN/docs/products/spot/testnet/web-socket-streams)、[UM](https://developers.binance.com/legacy-docs/zh-CN/derivatives/usds-margined-futures/websocket-market-streams/How-to-manage-a-local-order-book-correctly)、[CM](https://developers.binance.com/legacy-docs/derivatives/coin-margined-futures/websocket-market-streams/How-to-manage-a-local-order-book-correctly)。
- [INFERRED, MED] Options 官方 diff 文档当前明确了 `U/u/pu` 字段，但本轮没有找到与 UM/CM 同等明确的官方“local order book correctly”首次 snapshot bridge 步骤；因此 Options 使用 futures-like bridge 只能作为待 live 对账的实现假设，不能提升为官方事实。
- [COMPUTED, HIGH] Binance Options 订单簿使用 `GET /eapi/v1/depth`，最大 1000 档权重 20；本轮据此接入 snapshot 和端点权重：[官方文档](https://developers.binance.com/en/docs/catalog/core-trading-derivatives-trading-options/api/rest-api/market-data#order-book)。
- [COMPUTED, HIGH] Spot 5000 档 depth 当前权重 250，UM/CM 1000 档当前权重 20；旧实现分别低估为 50/10，本轮已按官方档位修正：[Spot](https://developers.binance.com/en/docs/catalog/core-trading-spot-trading/api/rest-api/market#order-book)、[UM](https://developers.binance.com/en/docs/catalog/core-trading-derivatives-trading-usd-s-m-futures/api/rest-api/market-data#order-book)、[CM](https://developers.binance.com/en/docs/catalog/core-trading-derivatives-trading-coin-m-futures/api/rest-api/market-data#order-book)。
- [COMPUTED, HIGH] Binance COIN-M aggTrades 支持 `fromId`/时间查询并对组合参数给出约束；本轮使用 ID continuation 避免同毫秒丢失：[官方文档](https://developers.binance.com/legacy-docs/derivatives/coin-margined-futures/market-data/rest-api/Compressed-Aggregate-Trades-List)。
- [COMPUTED, HIGH] Binance USDⓈ-M aggTrades 的时间范围与参数组合也有独立约束，不能把 Spot 分页预算直接复用到衍生品：[官方文档](https://developers.binance.com/en/docs/catalog/core-trading-derivatives-trading-usd-s-m-futures/api/rest-api/market-data#compressed-aggregate-trades-list)。
- [COMPUTED, HIGH] Binance Options mark price/Greeks 是独立能力，不能伪装为 kline：[官方文档](https://developers.binance.com/legacy-docs/derivatives/options-trading/market-data/Option-Mark-Price)。
- [COMPUTED, HIGH] 官方 Options SDK 将 trade 定义为 `<symbol>@optionTrade`、ticker 定义为 `<symbol>@optionTicker`，两者均由 `/public` 处理；kline 位于 `/market`：[Options Trade](https://developers.binance.com/legacy-docs/derivatives/options-trading/websocket-market-streams/Trade-Streams)、[Options Ticker](https://developers.binance.com/legacy-docs/derivatives/options-trading/websocket-market-streams/24-hour-TICKER)。
- [COMPUTED, HIGH] Spot/UM/CM 实时聚合成交使用 `<symbol>@aggTrade`；Spot 历史 `/api/v3/aggTrades` 与该实时粒度匹配：[Spot WebSocket](https://github.com/binance/binance-spot-api-docs/blob/master/web-socket-streams.md)、[UM](https://developers.binance.com/legacy-docs/derivatives/usds-margined-futures/websocket-market-streams/Aggregate-Trade-Streams)、[CM](https://developers.binance.com/legacy-docs/derivatives/coin-margined-futures/websocket-market-streams/Aggregate-Trade-Streams)。
- [COMPUTED, HIGH] 只有 Spot 支持 `1s` kline；UM/CM/Options 本轮改为从 `1m` 开始，CM REST 同时遵守单窗最大 200 天与从 `endTime` 返回最近 `limit` 条的契约：[CM Kline](https://developers.binance.com/en/docs/catalog/core-trading-derivatives-trading-coin-m-futures/api/rest-api/market-data#kline-candlestick-data)。
- [COMPUTED, HIGH] Binance 官方 Options connector 已明确 `/eapi/*` 可使用 `https://testnet.binancefuture.com/`，本轮因此修正 Options testnet REST 不应返回空端点的旧判断：[官方 connector](https://github.com/binance/binance-connector-js/tree/master/clients/derivatives-trading-options)。

## 11. 验证证据

[COMPUTED, HIGH] 本轮已获得以下聚焦证据；它们证明局部修复，不等于 release Go。

| 验证 | 结果 |
| --- | --- |
| history/whitelist/product connector 聚焦测试 | [COMPUTED, HIGH] PASS |
| LiveDelivery、orderbook production safety、OSS archive、mandatory DLQ 的 TDD seam | [COMPUTED, HIGH] PASS，均保留 RED→GREEN 行为证据 |
| `go test ./internal/server/... -count=1` | [COMPUTED, HIGH] PASS |
| consumer/deadletter/assembly race 子集 | [COMPUTED, HIGH] PASS |
| runtime status consistency gate | [COMPUTED, HIGH] PASS，canonical verdict 为 NO |
| status / external runner / release-packet 对抗 fixtures | [COMPUTED, HIGH] PASS：unsigned local YES、旧 `printf/.invalid` command PoC、最小 ledger+marker、symlink、NUL、超限文件、覆盖重跑、caller-PATH/GIT 重定向、异常 `BASH_ENV`/导出函数、共享 validator 失败、源码后改和 dirty worktree 均 fail-closed |
| ZoneCNH binance docs gate | [COMPUTED, HIGH] PASS（新增一致性检查后） |
| deployment docs 禁词与敏感地址扫描 | [COMPUTED, HIGH] PASS |
| 变更 Markdown 相对链接 | [COMPUTED, HIGH] PASS（38 个 changed Markdown、98 个相对链接） |
| `GOWORK=off go build ./...` | [COMPUTED, HIGH] PASS |
| `GOWORK=off go test ./... -count=1` | [COMPUTED, HIGH] PASS |
| `GOWORK=off go test ./... -race -count=1` | [COMPUTED, HIGH] PASS，0 data race |
| `GOWORK=off go vet ./...` | [COMPUTED, HIGH] PASS |
| `GOWORK=off go test ./... -coverprofile=...` | [COMPUTED, HIGH] PASS，module statement coverage `82.2%`；critical `orderbook` 为 `77.9%`，`cmd/binance-client` 为 `75.7%`、`cmd/binance-server` 为 `50.8%`，未形成逐 package 80% 结论 |
| repository-wide Actionlint；变更 workflow Yamllint | [COMPUTED, HIGH] PASS；既有 `build.yml` 未引用的 GOROOT 推导已修复 |
| status clean-env/SHA/protection 对抗 fixtures | [COMPUTED, HIGH] PASS：BASH startup、GOFLAGS no-tests、缺失/漂移 SHA、未保护 ref 均 fail-closed |
| `golangci-lint run ./...` | [COMPUTED, HIGH] BLOCKED：本机 linter 由 Go 1.25 构建，低于仓库目标 Go 1.26，配置加载前即退出 |
| `staticcheck ./...` | [COMPUTED, HIGH] FAIL：仓库既有 `U1000`/`SA1012` 等基线仍存在；本轮并发改动集中的 `internal/client/orderbook` 单包检查 PASS |
| `./scripts/boundary-gates.sh` | [COMPUTED, HIGH] 18/18 PASS |
| `TestSoak_ServerStability`（`SOAK_DURATION=30s`，测试墙钟 60s） | [COMPUTED, HIGH] PASS：`sent=11996`、`accepted=11996`、`rejected=0`、`dupes=1196`、`sink=10800`，heap growth `0.0%`，mid-final `-18.2%`，goroutine delta `0` |
| `-tags=chaos` 确定性故障注入 | [COMPUTED, HIGH] PASS：ProcessRestart、StorageFailure、DispatchFailure、IdempotencyUnavailable、ConcurrentFailureInterleaving；需外部环境/特权的 NATS、Redis、TDengine、Kafka 和 stop/kill 用例 SKIP |
| `gitleaks dir . --redact`（runtime + ZoneCNH） | [COMPUTED, HIGH] PASS，未发现 secret |
| Agent Team 最终 P0/P1 复审 | [COMPUTED, HIGH] PASS：alignment append/commit、buffer ABA、mutation/rebuild 跨代、snapshot stale/complete、checksum 时序、Book 原子快照、status false-green 均已有确定性回归；当前 scope 未发现剩余实现级 P0/P1 |
| 外部五项 E2E | [COMPUTED, HIGH] BLOCKED/NOT_RUN |
| GitHub main protection/ruleset | [COMPUTED, HIGH] BLOCKED：2026-07-11 API 读回 `protected=false`、`rulesets=[]` |

[COMPUTED, HIGH] 默认 `/home/workspace/go.work` 中的 `natsx` 工作区存在独立冲突；binance pinned-module 验证统一使用 `GOWORK=off`。该问题必须作为多仓集成 workspace blocker 单独处理，不能归因于本轮 binance module patch。

## 12. 达到 Go 的分阶段路径

1. [INFERRED, HIGH] **R0 — 冻结真值**：保持 `release_closeable_spec=NO` 与 runtime NO；选定唯一 RC SHA，旧 evidence 全部标历史快照。
2. [INFERRED, HIGH] **R1 — 本地 P0**：裁决 client crash-window 与 archive retry 持久化策略；补 connector disconnect→orderbook stale/rebuild；完成 Options live alignment/容量验收；拆分 Catalog candidate/admission；修复 coverage/funding 与 history capability；补齐 client queue 配置/指标。
3. [INFERRED, HIGH] **R2 — 确定性集成**：增加四线 live fixture、kill/restart replay、同名 symbol、同毫秒 trade、daily window、mixed archive partition、multi-replica idempotency 与 capability-matrix tests。
4. [INFERRED, HIGH] **R3 — 真实外部门禁**：先由管理员配置并验证 main branch protection/ruleset，再实现和审查 fixed signer workflow；随后在 protected main 与 §17 受治理 runner 上执行 NATS、Kafka、TDengine、Redis、API 五项 E2E，生成绑定环境身份、event ID、RC SHA、raw artifact 与 attestation bundle 的证据。
5. [INFERRED, HIGH] **R4 — 发布来源**：为同一 RC 生成 remote CI URL、tag、release notes、artifact digest、SBOM、preflight、canary、rollback 与 post-deploy observation。
6. [INFERRED, HIGH] **R5 — 重新裁决**：只有 canonical Matrix 无 Partial、所有 PRG 和 runtime packet 同时通过，才把 spec/runtime verdict 一次性提升为 YES。

## 13. 需要负责人的显式裁决

- [INFERRED, HIGH] Options 订单簿 live alignment、合约 churn 与容量验收是本次四线目标的 P0；若要延期，必须显式定义一个不含 Options 本地订单簿的 release profile，并同步修改 Goal/Spec/AC/Matrix，不能只在实现里跳过。
- [COMPUTED, HIGH] 当前 production kafkax 已选择 strict barrier：primary storage 与 Kafka handoff 均成功后才 ACK，DLQ 不替代任一 strict primary；负责人仍须裁决 OSS archive 是否也进入同步 ACK barrier，或作为可恢复异步派生层。
- [INFERRED, HIGH] 必须解决 client OQ-002：若继续禁止本地 spool，就要明确可接受的 crash-window loss，并用多实例采集或可证明补数闭环；若目标是零静默丢失，则须先变更 Goal/Spec/Matrix，再引入受容量、fsync、加密和恢复测试约束的 WAL。
- [INFERRED, HIGH] Options provider failure 已固定 fail-closed；负责人仍必须裁决 Spot/UM/CM 在 provider 失败时是继续 availability-first fail-open，还是改为全线 fail-closed，并绑定告警和恢复时限。
- [COMPUTED, HIGH] persistent DLQ 已设为 production 必填；负责人仍须确认其保留期、加密、容量与 replay 处置 SLO。
- [INFERRED, HIGH] 必须决定 OSS upload 是否需要跨进程持久重试；跨实例 object key 已修，但当前 pending/current 只保证进程存活期与受控关闭。

## 14. 任务与证据状态

[COMPUTED, HIGH] Beads 已存在与本任务完全匹配的 P0 epic `ZoneCNH-7i1p`，当前为 `in_progress`；本地代码/文档优化不能替代其外部证据子项。

[COMPUTED, HIGH] 本轮尝试写回 Beads 时遇到本地 Dolt schema 错误 `events.id has no default`；因此没有伪造 close/update，epic 保持 `in_progress`，该 tracker 故障也需单独修复。

[COMPUTED, HIGH] repo-local `spec-code-pipeline` 与 Sol/Luna 外层入口均执行了前置核验，但当前 Matrix 没有外层协议要求的 canonical `M-###` Edge ID，无法提供真实 `--matrix-edge`；因此本轮使用原生 Agent Team 完成审计/实现/复核，并对正式 pipeline 保持 fail-closed，未声称已运行 Luna。

[COMPUTED, HIGH] 本轮未执行 push、PR、release 或部署；两个 feature worktree 均保留为可审查交付物。

## 15. 结论

[INFERRED, HIGH] 本轮优化显著降低了“假绿发布”和确定性数据丢失风险，但尚未实现用户要求的四业务线全链路生产闭环。

[INFERRED, HIGH] 当前正确交付状态是：**生产级整改分支 + 可复现局部证据 + 明确 No-Go 阻断账本**，不是“已可发布”。

[RULES I BROKE]：无
