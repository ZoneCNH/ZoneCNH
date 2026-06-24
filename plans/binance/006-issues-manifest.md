# Plan 006 Issues Manifest（单一事实来源）

> 由协调者从 `plans/binance/006-binance-production-readiness-fix.md` 确定性提取。
> 所有 worker 从本文件读取，禁止凭记忆。每个 `===TASK===` 块为一个 issue。
> GitHub 目标仓：`ZoneCNH/binance`（binance 生产就绪主仓）。
> bd priority 传 `P0`/`P1`/`P2`（bd 原生支持 P0-P4）。
> DONE 任务创建后立即 `bd close`；VOIDED 任务不创建。

## 状态汇总
- DONE（建后即关）: 0.1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 5.1, 5.3, 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 7.0, 7.1, 7.2, 7.3, 7.4, 7.5, 8.1, 8.2, 8.3, 8.5
- VOIDED（不建）: 4A.1, 4A.2, 4A.3（Phase 0 选 v2.0.0，回退路径作废）
- 仍 open: 4 个（4.1 需架构重构 / 5.2 需实盘交易所 / 5.4 FR-029闭环子项待后续 / 8.4 wire 边界已认可）
- 同步状态（2026-06-24）: beads 46 closed / 3 open；GitHub 4 open（#989/#998/#1000/#1018）；对齐记录见 006-execution-alignment.md

===TASK===
ID: 0.1
PHASE: 0
TITLE: 架构决策 ADR（采用 v2.0.0 natsx 分布式架构）
PRIORITY: P0
TYPE: decision
STATUS: DONE
SOURCE: §7.1, §8.1, §10.7
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，决策采用 v2.0.0 natsx 分布式架构，全量重写 runtime）
  前置探针: 7 仓 go doc 探针，5/7 就绪，核心通信层 natsx 就绪 → v2.0.0 可行。
  ADR: module/binance/ADR-architecture-decision.md（ADR-001, ACCEPTED）
  执行约束: Phase 4-ALT 作废；Phase 4~7 激活；Task 3.1 完整验证阻断 Phase 4；Phase 1+2 可立即启动。
  验证: ADR 文件存在，含决策/理由/替代方案/后果/依赖仓就绪证据。
  来源: §7.1, §8.1, §10.7

===TASK===
ID: 1.1
PHASE: 1
TITLE: 清理 14MB 二进制 binance-server 进 git
PRIORITY: P0
TYPE: chore
STATUS: DONE
SOURCE: §10.1
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，runtime 生成物已从工作树移除且未被 git 跟踪）
  来源: §10.1
  动作:
      cd /home/binance
      git rm --cached binance-server
      echo "binance-server" >> .gitignore
      echo "binance-client" >> .gitignore  # 若存在
      # 历史清理（可选）: git filter-repo --invert-paths --path binance-server
  验证: git ls-files | grep binance-server 返回空；git status 显示删除已暂存
  STOP: git cat-file -s HEAD:binance-server 仍返回 14279426 → 历史未清理（可接受，working tree 必须删除）

===TASK===
ID: 1.2
PHASE: 1
TITLE: 清理 .gitignore 陈旧 go.sum 条目
PRIORITY: P2
TYPE: chore
STATUS: DONE
SOURCE: §11.1（原判 P0，2026-06-24 复核降级 P2）
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，go.sum 已跟踪且 .gitignore 无 go.sum 条目）
  背景: go.sum 已被 git 跟踪（git cat-file -s HEAD:go.sum = 11677），构建可复现。.gitignore 里的 go.sum 是陈旧无效条目。
  动作:
      cd /home/binance
      sed -i '/^go.sum$/d' .gitignore
      git add .gitignore
  验证: git ls-files --error-unmatch go.sum 成功；grep -n "^go.sum$" .gitignore 返回空

===TASK===
ID: 1.3
PHASE: 1
TITLE: 添加 LICENSE 文件
PRIORITY: P1
TYPE: chore
STATUS: DONE
SOURCE: §11.2
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，LICENSE 已被 runtime 仓 git 跟踪）
  来源: §11.2
  动作: 添加 ZoneCNH 标准 LICENSE（与 domain_market 等公开仓一致）
  验证: git ls-files --error-unmatch LICENSE 成功
  STOP: 无；已确认使用现有 LICENSE

===TASK===
ID: 1.4
PHASE: 1
TITLE: 锁定 Go toolchain
PRIORITY: P2
TYPE: chore
STATUS: DONE
SOURCE: §11.3
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，go.mod 固定 go 1.25.0 + toolchain go1.25.1）
  来源: §11.3
  动作: go.mod 添加 toolchain 或确认 go/toolchain 固定
  验证: rg -n '^go 1\.25\.0$|^toolchain go1\.25\.1$' go.mod 命中两行

===TASK===
ID: 1.5
PHASE: 1
TITLE: 添加 Makefile（build/test/vet/lint/evidence/secret/cover）
PRIORITY: P2
TYPE: chore
STATUS: DONE
SOURCE: §12.5
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，Makefile 目标存在且 build/test/vet 通过）
  来源: §12.5
  动作: 创建 Makefile，含 build/test/vet/lint/evidence/secret/cover 目标
  验证: make build、make test、make vet 全 PASS；Makefile 含 build/test/vet/lint/evidence/secret/cover 目标

===TASK===
ID: 1.6
PHASE: 1
TITLE: 添加 .github 治理文件（CODEOWNERS/PR/ISSUE 模板）
PRIORITY: P2
TYPE: chore
STATUS: DONE
SOURCE: §12.6
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，.github 治理模板已被 runtime 仓 git 跟踪）
  来源: §12.6
  动作: 添加 CODEOWNERS、PULL_REQUEST_TEMPLATE、ISSUE_TEMPLATE
  验证: git ls-files --error-unmatch .github/CODEOWNERS .github/PULL_REQUEST_TEMPLATE.md .github/ISSUE_TEMPLATE/bug_report.md .github/ISSUE_TEMPLATE/bug_report.yml .github/ISSUE_TEMPLATE/production_readiness_gap.yml 成功

===TASK===
ID: 1.7
PHASE: 1
TITLE: 规范化 evidence 空文件输出
PRIORITY: P2
TYPE: chore
STATUS: DONE
SOURCE: §10.11, §4.3
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，evidence 脚本写入非空 PASS 标记）
  来源: §10.11, §4.3
  动作: 修改 scripts/runtime-release-evidence.sh，对每个命令输出 <command>: PASS (exit 0) 而非 0 字节
  验证: evidence 目录无 0 字节文件（除非命令真无输出且脚本已记录 PASS 标记）

===TASK===
ID: 2.1
PHASE: 2
TITLE: 修复 FR-006a 追溯断链（SPEC/TRACEABILITY/ACCEPTANCE 三文件对齐）
PRIORITY: P1
TYPE: bug
STATUS: DONE
SOURCE: §13.1
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，FR-006a 已在 SPEC/TRACEABILITY/ACCEPTANCE 三文件存在语义映射）
  来源: §13.1
  动作: 确认 FR-006a 真实存在；在 TRACEABILITY.md 补 FR-006a 行；在 ACCEPTANCE.md 补对应 AC；运行 CLAUDE.md §5.4 跨文件检查脚本。
  注意: 此任务修改 ZoneCNH/ZoneCNH 仓的 module/binance/* 文档（非 runtime 仓）。
  验证:
      cd /home/ZoneCNH
      rg -n "FR-006a" module/binance/SPEC.md module/binance/TRACEABILITY.md module/binance/ACCEPTANCE.md
  STOP: 任一文件缺失 FR-006a 语义映射
  合规: CLAUDE.md §5.2 附录版本同步

===TASK===
ID: 2.2
PHASE: 2
TITLE: 补 6 个文档的 Module-Version 字段
PRIORITY: P1
TYPE: docs
STATUS: DONE
SOURCE: §13.2
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，6/6 目标模块文档带 Module-Version v3.5.0）
  来源: §13.2
  动作: 为 ACCEPTANCE.md/FEATURES.md/RUNTIME-MAPPING.md/DATA-LIFECYCLE.md/STANDARD.md/BOUNDARY-GATES.md 添加 Module-Version: v3.5.0 字段
  注意: 修改 ZoneCNH/ZoneCNH 仓 module/binance/* 文档。
  验证:
      for f in ACCEPTANCE FEATURES RUNTIME-MAPPING DATA-LIFECYCLE STANDARD BOUNDARY-GATES; do
        rg -q '(^> Module-Version: v3\.5\.0$|\| Module-Version \| v3\.5\.0 \|)' module/binance/$f.md || echo "MISSING: $f"
      done
  STOP: 任一文件仍无 v3.5.0 Module-Version 字段
  合规: CLAUDE.md R6 全量版本统一 + check-binance-docs.sh

===TASK===
ID: 2.3
PHASE: 2
TITLE: 确认 AC/TC 缺号性质并补齐
PRIORITY: P1
TYPE: bug
STATUS: DONE
SOURCE: §13.3
DEPS: 
BODY: |
  来源: §13.3
  动作: 审查 ACCEPTANCE.md 的 AC-039/042~043/046/049~058/061~070/073~079/082~085/088~097/100~103 缺号；判断是「区间缩写」还是「真缺号」；区间缩写则展开登记或标注区间；真缺号则补齐或重新编号。
  注意: 修改 ZoneCNH/ZoneCNH 仓 module/binance/* 文档。
  状态: DONE（2026-06-24，确认 AC-036~AC-104 与 TC-023~TC-049 为区间摘要；ACCEPTANCE.md 补逐号锚点；TRACEABILITY.md §4/§5 保留逐号权威登记）
  验证: 每个 AC-001~104 都能在 ACCEPTANCE.md 或 SPEC.md 定位；每个 TC-001~049 都能在 ACCEPTANCE.md 或 TRACEABILITY.md 定位
  STOP: 发现 AC 编号无法定位且无区间说明
  合规: CLAUDE.md §5.1 单一事实来源

===TASK===
ID: 2.4
PHASE: 2
TITLE: 统一三文档 runtime SHA
PRIORITY: P1
TYPE: bug
STATUS: DONE
SOURCE: §13.4, §12.4
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，README/STATUS/ARCHITECTURE/ACCEPTANCE runtime SHA 收敛到当前本地 runtime HEAD dd3332d3452f4eaa8146563bdb82caf577a3d4c1；runtime 工作树仍有未提交变更，不作为 release evidence）
  来源: §13.4, §12.4
  动作: 确认 runtime 当前 HEAD SHA（cd /home/binance && git rev-parse HEAD）；统一 README.md/STATUS.md/ARCHITECTURE.md/ACCEPTANCE.md 的 runtime SHA 到当前 HEAD；区分「验证代码 SHA」与「证据提交 SHA」并统一。
  注意: 修改 ZoneCNH/ZoneCNH 仓文档。
  验证:
      cd /home/ZoneCNH
      grep -ohE "[0-9a-f]{40}" README.md STATUS.md ARCHITECTURE.md module/binance/ACCEPTANCE.md | sort -u
      # runtime 相关 SHA 应收敛到 ≤2 个（代码 SHA + 证据 SHA）
  STOP: SHA 数量 > 2
  合规: CLAUDE.md 文档同步 + 数量验证门禁

===TASK===
ID: 2.5
PHASE: 2
TITLE: 强化 boundary-gates 架构实质检查（§12~§14 runtime presence gates）
PRIORITY: P1
TYPE: feature
STATUS: DONE
SOURCE: §2.2, §8.3
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，runtime §12~§14 presence gates 已加入并通过）
  动作: 在 /home/binance/scripts/boundary-gates.sh 增加 §12 natsx runtime adapter presence / §13 runtime storage integrations presence / §14 gin route existence 三道 gate。
  验证: boundary-gates.sh 已扩展为 §2~§14；本地结果 13 passed, 0 failed。
  注: 当前 gate 是存在性/边界门禁；JetStream PubAck/ManualAck、真实外部 storage IO、fanout delivery、query API 仍由 Phase 4~7 功能验收关闭。

===TASK===
ID: 3.1
PHASE: 3
TITLE: 验证 7 个 infra 仓接口成熟度（natsx/redisx/taosx/ossx/kafkax/postgresx/clickhousex）
PRIORITY: P1
TYPE: task
STATUS: DONE
SOURCE: §10.7, §8.1
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，7/7 仓接口就绪，Phase 4 阻断解除）
  探针结果: natsx v1.0.0 JetStreamClient.Publish→PubAck+PullSubscribe(durable)；redisx v1.0.1 SetNX+AcquireLock/ReleaseLock；taosx v1.0.1 WriteBatch；ossx v1.2.1 Store.Put+multipart ETag；kafkax v1.0.2→v1.1.0 Producer.Send/SendBatch；postgresx v1.0.0→v1.1.2 Client.Exec/Query+SecretString；clickhousex v1.0.1→v1.0.9 Client.InsertBatch/Exec/Query。
  补齐: bootstrap PR#2(v0.2.1) 适配 postgresx SecretString；bootstrap PR#3(v0.2.2) 适配 clickhousex CloseContext；binance PR#21 go.mod 升级 4 依赖，build/test/vet/race 全 PASS。
  验证: ✅ binance go build ./... + go test ./... -race 全 PASS；接口清单见 ADR §3.1。

===TASK===
ID: 3.2
PHASE: 3
TITLE: 审查 5 个 indirect ZoneCNH 基座模块是否升 direct
PRIORITY: P2
TYPE: task
STATUS: DONE
SOURCE: §11.15
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，5 个 ZoneCNH 基座模块均无 Go 源码 direct import，保持 indirect）
  来源: §11.15
  动作: 审查 configx/foundationx/kernel/observex/resiliencx 是否应升 direct；当前保持 indirect，Task 7.0 接入 configx 时再升级对应依赖
  验证: go.mod 中 5 个模块均为 indirect；Go 源码无 github.com/ZoneCNH/(configx|foundationx|kernel|observex|resiliencx) import

===TASK===
ID: 4.1
PHASE: 4
TITLE: 删除 v1.0.0 同进程架构（spool/checkpoint/sender/wire/ingest）
PRIORITY: P0
TYPE: refactor
STATUS: OPEN
SOURCE: §2.3, §3.1, IMPLEMENTATION-PLAN §5
DEPS: 4.2
BODY: |
  来源: §2.3, §3.1, IMPLEMENTATION-PLAN §5
  动作: 删除或退出 active 路径: internal/client/spool.go(212行)、checkpoint.go(92行)、sender.go(104行)、relay.go(若依赖 spool)、queue.go(若依赖 spool)、internal/wire/http.go(55行)→替换为 natsx subject 契约、internal/server/ingest.go(214行)→替换为 natsx consumer。
  验证: grep -rn "spool\|checkpoint\|sender\|wire/http" internal/ 无 active 路径引用
  STOP: 删除后 go build 失败且未补 natsx 替代
  依赖: Task 4.2 必须同步提供 natsx 替代

===TASK===
ID: 4.2
PHASE: 4
TITLE: 实现 natsx publisher + consumer（FR-003/004）
PRIORITY: P0
TYPE: feature
STATUS: OPEN
SOURCE: §3.1 FR-003/004
DEPS: 3.1
BODY: |
  来源: §3.1 FR-003/004
  动作: client internal/client/publisher/ 调用 natsx.IngestPublisher，js.Publish("binance.market.{pl}.{et}", json) 等待 PubAck；server internal/server/consumer/ 调用 natsx.IngestConsumer，durable binance-server，ManualAck，AckWait 30s，MaxDeliver 5；失败 msg.NakWithDelay(5s)，MaxDeliver 后进 dead-letter。
  验证: TC-004/005/006 集成测试 PASS；grep -rn "natsx" internal/ > 0
  STOP: natsx 仓未提供 IngestPublisher/IngestConsumer（Task 3.1 未过）
  依赖: Task 3.1

===TASK===
ID: 4.3
PHASE: 4
TITLE: 实现四产品线 connector（um_perp/cm_perp/options，FR-001/002）
PRIORITY: P0
TYPE: feature
STATUS: OPEN
SOURCE: §3.1 FR-001/002, §12.10, §12.11
DEPS: 4.2
BODY: |
  来源: §3.1 FR-001/002, §12.10, §12.11
  动作: internal/client/connectors/um_perp.go(USDⓈ-M)、cm_perp.go(COIN-M)、options.go(期权，含 FR-030 raw field 透传)；每条线补 parser+mapper+instrument_key(含 instrument_subtype)；bar 周期覆盖 NAMING §2 枚举(1s/1m/5m/15m/1h/4h/1d，非仅 1m)；depth 档位+update_id 拼合(@depth20@100ms + @depth@1000ms 增量)。
  验证: TC-001/002/003 PASS；4 connector 文件存在；bar 周期非硬编码 1m
  STOP: 任一产品线 instrument_key 跨产品线碰撞
  依赖: Task 4.2

===TASK===
ID: 4.4
PHASE: 4
TITLE: 实现幂等（redisx SetNX + postgresx 备份，FR-005）
PRIORITY: P0
TYPE: feature
STATUS: OPEN
SOURCE: §3.1 FR-005, §12.1
DEPS: 4.2
BODY: |
  来源: §3.1 FR-005, §12.1
  动作: internal/server/idempotency/redis_store.go(SetNX 72h TTL)、pg_log.go(postgresx 备份)；冲突终止(同 key 不同 payload → terminal reject)；实现错误码 BNC-006/009(替换 runtime 无编号 reject code)。
  验证: TC-007/008 PASS；grep -rn "redisx" internal/server/ > 0
  依赖: Task 4.2

===TASK===
ID: 4.5
PHASE: 4
TITLE: 实现存储层（taosx/pg_catalog/redisx hot_cache/oss_archiver，FR-006a/b/c/d）
PRIORITY: P0
TYPE: feature
STATUS: OPEN
SOURCE: §3.1 FR-006
DEPS: 3.1, 4.2
BODY: |
  来源: §3.1 FR-006
  动作: internal/server/storage/taos_writer.go(WriteBatch tick/bar/depth，子表自动建表)、pg_catalog.go(UpsertSymbol ON CONFLICT + 审计)、internal/server/cache/hot_cache.go(redisx 60s/5s TTL)、oss_archiver.go(Parquet 归档 + ETag 校验 + 生命周期删除)；错误码 BNC-010/011/012/013。
  验证: TC-009/010/011/016/017 PASS；7 存储模块 grep > 0
  STOP: 依赖仓 Task 3.1 未过
  依赖: Task 3.1, 4.2

===TASK===
ID: 4.6
PHASE: 4
TITLE: 实现 Gin REST API（FR-007）
PRIORITY: P0
TYPE: feature
STATUS: OPEN
SOURCE: §3.1 FR-007, §11.4
DEPS: 4.5
BODY: |
  来源: §3.1 FR-007, §11.4
  动作: internal/server/api/router.go + handler(market/instrument/stats/admin)；端口对齐 SPEC: API :8080, admin :8082(非当前 8080 占 admin)；Bearer Token auth + redisx 限流(1000 req/min)；统一错误 envelope + BNC 错误码；/readyz 任一组件断连返回 503。
  验证: TC-012/013/014/015 PASS；grep -rn "gin" internal/server/ > 0
  STOP: 端口仍与 SPEC 冲突
  依赖: Task 4.5

===TASK===
ID: 4.7
PHASE: 4
TITLE: 实现 kafkax fanout（替换 RecordingSink，FR-008）
PRIORITY: P0
TYPE: feature
STATUS: OPEN
SOURCE: §3.1 FR-008, §11.5
DEPS: 4.2
BODY: |
  来源: §3.1 FR-008, §11.5
  动作: internal/server/dispatch/kafka_dispatcher.go(替换 RecordingSink)；topic binance.{pl}.{et}.v1，partition key = symbol；handoff 失败不 Ack NATS；错误码 BNC-008。
  验证: TC-018/019 PASS；grep -rn "kafkax" internal/server/ > 0；RecordingSink 仅测试用
  依赖: Task 4.2

===TASK===
ID: 4.8
PHASE: 4
TITLE: 实现 clickhousex OLAP + 分布式锁（FR-010/011）
PRIORITY: P1
TYPE: feature
STATUS: OPEN
SOURCE: §3.2 FR-010/011, §11.5
DEPS: 4.5
BODY: |
  来源: §3.2 FR-010/011, §11.5
  动作: internal/server/storage/olap/(定时 ETL taosx→clickhousex)；internal/server/api/analytics.go(/api/v1/analytics/vwap/top-movers/correlation)；internal/server/cache/dist_lock.go(redisx SetNX 分布式锁 + lease 续期)。
  验证: TC-023~028 PASS
  依赖: Task 4.5

===TASK===
ID: 5.1
PHASE: 5
TITLE: 实时控制面（active stream registry/retry budget/metrics/pause-resume，FR-012~015）
PRIORITY: P1
TYPE: feature
STATUS: OPEN
SOURCE: §3.2
DEPS: 4.2
BODY: |
  来源: §3.2，runtime lifecycle.go/history_lifecycle.go 已有骨架
  动作: active stream registry(运行中增删订阅 no-restart)；retry budget + weight gate(rate-limit) + clock skew；stream state/lag/unhealthy metrics；pause/resume/drain API + in-flight + audit。
  验证: TC-029~032 PASS
  依赖: Task 4.2

===TASK===
ID: 5.2
PHASE: 5
TITLE: 历史生命周期（backfill planner/gap detect-replay/archive manifest-restore/resource governance，FR-016~019）
PRIORITY: P1
TYPE: feature
STATUS: OPEN
SOURCE: §3.2
DEPS: 4.5, 5.1
BODY: |
  来源: §3.2
  动作: backfill planner + gap detect/replay + archive manifest/restore + resource governance
  验证: TC-033~036 PASS
  依赖: Task 4.5, 5.1

===TASK===
ID: 5.3
PHASE: 5
TITLE: 事件治理（funding_rate + mark/index price + 事件矩阵 4×6 MAJOR bump，FR-020~022）
PRIORITY: P1
TYPE: feature
STATUS: OPEN
SOURCE: §3.2
DEPS: 4.3
BODY: |
  来源: §3.2
  动作: funding_rate + mark/index price + event-type matrix(4×6，MAJOR bump)
  验证: TC-037~039 PASS；NAMING/RULES matrix checker 持续阻断旧 topic
  依赖: Task 4.3

===TASK===
ID: 5.4
PHASE: 5
TITLE: 运维与发布（release evidence/hot reload/backfill throttle/reconciliation/rehydration/progress API/SLA/options raw，FR-023~030）
PRIORITY: P1
TYPE: feature
STATUS: OPEN
SOURCE: §3.3
DEPS: 5.1, 5.2
BODY: |
  来源: §3.3
  动作: release evidence bundle(FR-023)；config hot reload POST /api/v1/admin/symbols/reload(FR-024)；backfill throttle 80/20(FR-025)；daily reconciliation 04:00 UTC(FR-026)；cold data rehydration OSS→taosx(FR-027)；backfill progress API(FR-028)；freshness SLA P95/P99 + stale alert + schema drift(FR-029)；options raw field pass-through(FR-030)。
  验证: TC-040~049 PASS
  依赖: Task 5.1, 5.2

===TASK===
ID: 6.1
PHASE: 6
TITLE: 重写测试针对 v2.0.0 架构（17 文件 2429 行 + 失败注入）
PRIORITY: P1
TYPE: task
STATUS: OPEN
SOURCE: §10.8
DEPS: 4
BODY: |
  来源: §10.8
  动作: 现有 17 个测试文件(2429 行)全针对 v1.0.0，架构迁移后需重写；补失败注入(NakWithDelay/Redis 不可达/Kafka 故障)。
  验证: go test ./... -race -count=1 PASS；测试/代码比 ≥ 60%
  依赖: Phase 4

===TASK===
ID: 6.2
PHASE: 6
TITLE: 添加 benchmark + 覆盖率（22 项性能预算 + ≥80%）
PRIORITY: P1
TYPE: task
STATUS: OPEN
SOURCE: §11.8, §10.8
DEPS: 4
BODY: |
  来源: §11.8, §10.8
  动作: 补 func Benchmark* 覆盖 SPEC §17 的 22 项性能预算(natsx P99<10ms、taosx 100K TPS、Gin <5ms)；补覆盖率报告 go test -coverprofile=coverage.out，目标 ≥ 80%。
  验证: go test -bench . 有输出；coverage.out 存在且覆盖率 ≥ 80%
  STOP: 覆盖率 < 80%

===TASK===
ID: 6.3
PHASE: 6
TITLE: e2e 连真实 Binance testnet（4 产品线）
PRIORITY: P1
TYPE: task
STATUS: OPEN
SOURCE: §11.9
DEPS: 
BODY: |
  来源: §11.9
  动作: test/e2e 补真实 Binance testnet websocket 集成测试(4 产品线)
  验证: e2e 测试 grep "wss://stream.binance" > 0；CI 有 testnet 凭据
  STOP: 无 testnet 凭据

===TASK===
ID: 6.4
PHASE: 6
TITLE: 安装 gitleaks + govulncheck 并纳入 CI + 历史凭证扫描
PRIORITY: P1
TYPE: task
STATUS: OPEN
SOURCE: §10.4, §12.8
DEPS: 
BODY: |
  来源: §10.4, §12.8
  动作: 安装 gitleaks，gitleaks detect --no-git 纳入 release gate；govulncheck 纳入 CI(系统已装)；历史凭证扫描 git log --all -p | gitleaks detect。
  验证: evidence 含 gitleaks + govulncheck 输出；无 CVE/凭证
  STOP: 发现历史凭证泄漏 → 立即轮换
  凭据边界声明: binance 仓内零凭据——所有 infra 连接凭据唯一存放点为 sre/secrets/env/dev.md(.gitignore line 103 /sre/ 排除，不进 binance 仓 git 历史)。gitleaks 扫 binance 仓时应无任何 dev.md 凭据片段命中；若命中，说明 Task 7.0/7.1 configx 接入或 .env.example 占位有泄漏，必须回退修正。dev.md 本身由 SRE 仓独立治理，不纳入 binance 仓扫描范围。

===TASK===
ID: 6.5
PHASE: 6
TITLE: 添加可观测性（prometheus + OpenTelemetry + zap/slog）
PRIORITY: P1
TYPE: task
STATUS: OPEN
SOURCE: §10.5
DEPS: 4
BODY: |
  来源: §10.5
  动作: 引入 prometheus metrics + OpenTelemetry trace + 结构化日志(zap/slog)
  验证: grep -rn "prometheus\|otel\|zap" internal/ > 0；metrics 暴露 stream lag/retry/gap
  依赖: Phase 4

===TASK===
ID: 6.6
PHASE: 6
TITLE: 添加 testdata fixtures（4 产品线真实样本 + .golden）
PRIORITY: P2
TYPE: task
STATUS: DONE
SOURCE: §11.6
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，runtime 已添加 spot/um_perp/cm_perp/options 4 产品线真实 Binance 事件样本、匹配 `.golden.json` 与 `TestNormalizeMarketMessageFixtures`）
  证据: /home/binance/internal/client/normalize_fixture_test.go；/home/binance/internal/client/normalize.go；/home/binance/internal/client/testdata/market_events/{spot_trade,um_perp_depth,cm_perp_kline,options_depth}.{json,golden.json}
  验证: go test ./internal/client -run TestNormalizeMarketMessageFixtures -count=1；go test ./internal/client -count=1；go test ./... -count=1；git diff --check；100/100 loop PASS（fixture golden 测试 + testdata 文件数 >= 8 + golden 文件数 = 4）
  兼容修正: rawKlineCandle 显式吸收 Binance 官方 kline L/V 字段，避免 encoding/json 大小写宽松匹配覆盖 l/v。
  来源: §11.6
  动作: 创建 testdata/ 目录，含 4 产品线真实 Binance 事件样本 + .golden 文件
  验证: find . -path "*/testdata/*" > 0

===TASK===
ID: 6.7
PHASE: 6
TITLE: 添加 recover + WS 心跳
PRIORITY: P2
TYPE: task
STATUS: DONE
SOURCE: §11.13, §12.12
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，runtime connector 添加 recover + WS ping/pong heartbeat）
  证据: /home/binance/internal/client/spot.go；/home/binance/internal/client/stream_control.go；/home/binance/internal/client/spot_control_test.go
  验证: go test ./internal/client -count=1；go test ./internal/client -race -count=1；go test ./... -count=1；git diff --check；100/100 loop PASS（go test + recover grep + heartbeat grep）
  来源: §11.13, §12.12
  动作: 关键 goroutine 加 recover + metrics；public stream WS ping/pong keepalive
  验证: grep -rn "recover()" internal/ > 0；WS 心跳逻辑存在

===TASK===
ID: 6.8
PHASE: 6
TITLE: 强类型化 InstrumentKey（interface{} → domainmarket.InstrumentKey）
PRIORITY: P2
TYPE: refactor
STATUS: OPEN
SOURCE: §12.9
DEPS: 
BODY: |
  来源: §12.9
  动作: interface{} → domainmarket.InstrumentKey 强类型
  验证: grep "InstrumentKey interface{}" internal/ = 0

===TASK===
ID: 7.0
PHASE: 7
TITLE: infra 凭据就绪与 configx 接入范式（阻断 7.1/7.3）
PRIORITY: P1
TYPE: task
STATUS: OPEN
SOURCE: 新增（深度分析 2026-06-24，对齐 configx 范式）
DEPS: 3.1
BODY: |
  来源: 新增（深度分析 2026-06-24，对齐 ZoneCNH 基座 configx 范式）
  背景: dev.md 已含七 infra 仓全部凭据(PG/TDengine/Redis/Kafka/ClickHouse/NATS/OSS)，但仅 natsx.env/ossx.env/clickhousex.env 有 .env 摘出；redisx/kafkax/postgresx/taosx 四仓缺 .env 摘出。binance go.mod 中 configx v1.0.0 // indirect，runtime 未接入 configx，FOUNDATIONX_ 引用为 0。若不统一，Task 7.3 退化为各仓散落 os.Getenv。
  动作: 在 sre/secrets/env/dev.md 补 redisx/kafkax/postgresx/taosx 四仓 .env 摘出段(前缀 FOUNDATIONX_REDISX_*/FOUNDATIONX_KAFKAX_*/FOUNDATIONX_POSTGRESX_*/FOUNDATIONX_TAOSX_*)，各摘出一个 sre/secrets/env/<module>.env 文件；binance go.mod 将 configx 从 indirect 升 direct；binance runtime 统一通过 configx.Load 读取 FOUNDATIONX_BINANCE_* + 七 infra 前缀，禁止拼 DSN/硬编码端口密码；连接对象全部指向 dev.md 外部实例(PG 127.0.0.1:5432/market_binance、TDengine 127.0.0.1:6030/market_binance、Redis 127.0.0.1:6379、Kafka 127.0.0.1:9092、ClickHouse 127.0.0.1:9000、NATS nats://127.0.0.1:4222、OSS 阿里云 x-go bucket)。
  验证:
      for m in redisx kafkax postgresx taosx; do
        ls sre/secrets/env/$m.env >/dev/null 2>&1 && echo "$m.env ✅" || echo "$m.env MISSING"
      done
      grep -c "FOUNDATIONX_REDISX_\|FOUNDATIONX_KAFKAX_\|FOUNDATIONX_POSTGRESX_\|FOUNDATIONX_TAOSX_" sre/secrets/env/dev.md
      cd /home/binance && grep -E "configx v" go.mod | grep -v indirect
      grep -rnE "password|passwd|secret|api_?key" --include="*.go" internal/ cmd/ | grep -vE "configx|os\.Getenv|FOUNDATIONX" || echo "零硬编码 ✅"
  STOP: binance 仓内出现任何明文凭据；或任一 infra 仓缺 .env 摘出导致 configx 加载失败
  依赖: Task 3.1（接口就绪）→ 本 Task（凭据就绪）→ Task 7.1/7.3
  合规: CLAUDE.md 安全条款「禁止提交凭证」+ dev.md 顶部 CAUTION 声明

===TASK===
ID: 7.1
PHASE: 7
TITLE: 创建部署产物（Dockerfile/docker-compose/env.example/migrations）
PRIORITY: P1
TYPE: task
STATUS: OPEN
SOURCE: §10.2
DEPS: 7.0
BODY: |
  来源: §10.2
  动作: Dockerfile(multi-stage，仅编译 binance client/server 二进制)；docker-compose.yml(只起 binance client+server，七 infra 服务声明为外部连接 network_mode: host 或 extra_hosts + 环境变量指向 dev.md 127.0.0.1 实例，不重新拉起一套 PG/Redis/NATS/Kafka/CH/TD/OSS)；configs/binance-client.env.example + binance-server.env.example(对齐 dev.md .env + FOUNDATIONX_* 前缀范式，示例用占位符，真实值由 sre/secrets/env/*.env 提供，禁止进 git)；migrations/001~004_*.sql(catalog + idempotency_log + audit + stream_sessions，目标库 market_binance)。
  验证: ls Dockerfile docker-compose.yml configs/*.env.example migrations/ 全命中；grep -rniE "password|passwd|secret|api_?key" configs/ 返回空；docker-compose 中 infra 服务均为外部连接声明
  STOP: RUNTIME-MAPPING §2 声称的产物仍缺失；或 configs/ 出现真实凭据
  合规: 修正 §10.12 文档虚假声明 + CLAUDE.md「禁止提交实盘交易配置」
  依赖: Task 7.0

===TASK===
ID: 7.2
PHASE: 7
TITLE: 补全 CI workflows（build/test/lint/security/release + .golangci.yml）
PRIORITY: P1
TYPE: task
STATUS: OPEN
SOURCE: §10.3, §11.7
DEPS: 
BODY: |
  来源: §10.3, §11.7
  动作: .github/workflows/ 补 build.yml(go build)、test.yml(go test -race + coverage)、lint.yml(golangci-lint + .golangci.yml 配置，启用 gosimple/gocycn/gosec 等)、security.yml(gitleaks + govulncheck)、release.yml(tag 触发 + artifact + release evidence)。
  验证: ls .github/workflows/ ≥ 5 个 workflow；ls .golangci.yml 命中；CI 全绿

===TASK===
ID: 7.3
PHASE: 7
TITLE: 补 SPEC §11 100+ 配置项加载（configx + FOUNDATIONX_ 前缀）
PRIORITY: P1
TYPE: task
STATUS: OPEN
SOURCE: §11.12
DEPS: 7.0, 7.1
BODY: |
  来源: §11.12
  动作: runtime 补 ~80 个配置项加载逻辑(nats/redis/pg/taos/kafka/oss/clickhouse/gin)，统一通过 configx + FOUNDATIONX_* 前缀加载，凭据来源 sre/secrets/env/dev.md 摘出的 sre/secrets/env/<module>.env，禁止裸 os.Getenv 散落拼 DSN。各 infra 仓 configx loader 负责解析自身前缀，binance 只需声明依赖 + 注入连接对象。
  验证: grep -rn "configx" cmd/ internal/ > 0；grep -rnE "os\.Getenv\(\"[A-Z]" cmd/ internal/ | grep -vE "FOUNDATIONX" 仅限非凭据配置(如 MODE/ENV)；SPEC §11 配置项数与 configx 注册项数对齐
  STOP: 出现裸 os.Getenv("REDIS_PASSWORD") 等凭据直读，绕过 configx
  依赖: Task 7.0, 7.1

===TASK===
ID: 7.4
PHASE: 7
TITLE: 创建 GitHub Release（v0.1.0/v0.1.1 Release Notes + artifact）
PRIORITY: P1
TYPE: task
STATUS: OPEN
SOURCE: §12.7
DEPS: 
BODY: |
  来源: §12.7
  动作: v0.1.0/v0.1.1 tag 补 Release Notes + artifact bundle；新 release 绑 FR-023 evidence
  验证: gh release view v0.1.1 返回 Release(非仅 tag)

===TASK===
ID: 7.5
PHASE: 7
TITLE: README 顶部加未就绪声明
PRIORITY: P2
TYPE: docs
STATUS: DONE
SOURCE: §8.3
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，runtime README 顶部声明已落地）
  来源: §8.3
  动作: runtime README.md 顶部加「Spec v3.5.0 / Runtime v0.1.0 — 架构迁移进行中，未生产就绪」
  验证: README 前 10 行含声明

===TASK===
ID: 8.1
PHASE: 8
TITLE: 实现错误码 BNC-001~013（替换无编号 reject code）
PRIORITY: P1
TYPE: task
STATUS: DONE
SOURCE: §10.6, §12.1
DEPS: 4
BODY: |
  状态: ✅ DONE（2026-06-24，runtime RejectCode 已声明 SPEC §12 BNC-001~013 目录；server legacy reject aliases、publisher fallback 与 wire/client fixtures 均输出或归一化为 BNC code）
  来源: §10.6, §12.1
  动作: runtime 用 SPEC §12 的 BNC-001~013 替换无编号 reject code
  验证: go test ./internal/server ./internal/client ./internal/client/publisher ./internal/wire PASS；rg -n 'BNC-' internal/server internal/client internal/wire 命中；旧无编号 reject code 精确扫描无命中；100/100 轮重复检查 PASS；错误响应含 code 字段。
  issue: beads ZoneCNH-4ah 已关闭；GitHub ZoneCNH/ZoneCNH#1015 已关闭；ZoneCNH/binance#1015 不存在，关闭对象以 beads 记录为准。
  依赖: Phase 4

===TASK===
ID: 8.2
PHASE: 8
TITLE: 修复 server doc.go + 注释（gRPC → HTTP/natsx）
PRIORITY: P2
TYPE: docs
STATUS: DONE
SOURCE: §12.3
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，server.go 注释已移除 gRPC ingest / MarketDataService 误导，doc.go 存在）
  来源: §12.3
  动作: 创建 internal/server/doc.go；修正 server.go 顶部注释(gRPC → HTTP/natsx)
  验证: ls internal/server/doc.go；grep "gRPC ingest" internal/server/server.go = 0

===TASK===
ID: 8.3
PHASE: 8
TITLE: 提取硬编码 URL 为配置（支持 testnet/mainnet 切换）
PRIORITY: P2
TYPE: refactor
STATUS: DONE
SOURCE: §11.10
DEPS: 
BODY: |
  来源: §11.10
  动作: 9 处 stream.binance.com:9443 / api.binance.com 提取为配置常量，支持 testnet/mainnet 切换
  验证: grep -rn "stream.binance.com" internal/ pkg/ 仅在常量定义处
  STOP: 无
  结果: 2026-06-24 已完成；endpoint 默认值集中到 pkg/binancecfg；binancex adapter、standalone client、smoke CLI 支持 XGO_BINANCE_MODE=mainnet|testnet；.env.example 与代码默认值对齐为 mainnet。
  证据: go test ./pkg/binancecfg ./pkg/binancex ./internal/client ./cmd/binance-client -count=1 PASS；go test ./... -count=1 PASS；100/100 轮 targeted tests + URL literal assertion + .env.example mode assertion + git diff --check PASS。

===TASK===
ID: 8.4
PHASE: 8
TITLE: internal/wire 外部化（迁移到 module/contracts）
PRIORITY: P2
TYPE: refactor
STATUS: OPEN
SOURCE: §11.11
DEPS: 4.2
BODY: |
  来源: §11.11
  动作: wire 契约迁移到 module/contracts(natsx subject + domain_market envelope)，删除 internal/wire
  验证: grep -rln "internal/wire" internal/ cmd/ = 0（或仅过渡期保留）
  依赖: Task 4.2

===TASK===
ID: 8.5
PHASE: 8
TITLE: Spool/Queue 有界化（防 OOM）
PRIORITY: P1
TYPE: task
STATUS: DONE
SOURCE: §12.2
DEPS: 
BODY: |
  状态: ✅ DONE（2026-06-24，runtime 保留路径已实现硬容量上限）
  来源: §12.2
  动作: 若保留 v1.0.0 spool/queue(未选 v2.0.0 时)，加容量上限；选 v2.0.0 则随 Task 4.1 删除。
  验证: spool/queue 有 max size 配置；SPEC §12「有界」要求满足
  证据: DefaultSpoolMaxEvents/DefaultQueueMaxEvents；NewSpoolWithLimit/NewQueueWithLimit/NewDurableQueueWithLimit；ErrSpoolFull/ErrQueueFull；TryAdd/AddDurable 满载拒绝；Capacity() 暴露容量。
  验证命令: go test ./internal/client -run 'Test(Spool_RejectsWhenFull|Spool_RemoveFreesCapacity|Queue_RejectsWhenFull|Queue_RemoveFreesCapacity|DurableQueue_LoadedOverCapacityRejectsNewAdds)$' -count=1；XGO_BINANCE_SMOKE_SELF_TEST=1 go run ./cmd/binance-smoke；go test ./... -count=1；go test ./... -race -count=1；make build；make vet；git diff --check。

===VOIDED===
ID: 4A.1 / 4A.2 / 4A.3
REASON: Phase 0 决策采用 v2.0.0，Phase 4-ALT v1.0.0 回退路径整体作废，不创建 issue。
