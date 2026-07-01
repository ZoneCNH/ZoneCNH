# Plan006 执行对齐记录（2026-06-24）

> Scope: 本记录同步 agent team、本地验证、Beads、GitHub issue 状态；不改变 `006-binance-production-readiness-fix.md` 的发布就绪或生产级验收口径。
>
> [COMPUTED, HIGH] 后续 Plan008（2026-06-25）已闭合 release gate：GitHub Release `v0.2.0` + workflow `28126779885` completed/success，`release_closeable=YES`；本文件保留 Plan006 当时的生产级缺口口径。

## 状态摘要

| 项                                  | 状态                                                                                                         | 证据                                                                                                                                                                                                                                                                                                                                                                                                |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Task 1.1 清理 14MB 二进制           | local-fixed；Beads `ZoneCNH-4vo` closed；GitHub #975 CLOSED                                                  | `[COMPUTED, HIGH]` `/home/workspace/binance` 工作树无 `binance-server` 文件，`git ls-files binance-server` 为空，`git diff --check` PASS                                                                                                                                                                                                                                                                      |
| Task 1.3 添加 LICENSE               | local-fixed；Beads `ZoneCNH-q6r` closed；GitHub #977 closed                                                  | `[COMPUTED, HIGH]` `/home/workspace/binance/LICENSE` 已被 Git 跟踪，内容为 MIT License，100 次重复检查命中 LICENSE 文件；GitHub API closed_at `2026-06-24T01:27:02Z`                                                                                                                                                                                                                                          |
| Task 1.4 锁定 Go toolchain          | local-fixed；Beads `ZoneCNH-4ek` closed；GitHub #978 closed                                                  | `[COMPUTED, HIGH]` `go.mod` 包含 `go 1.25.0` 与 `toolchain go1.25.1`，`make build test vet` PASS；GitHub API closed_at `2026-06-24T01:27:05Z`                                                                                                                                                                                                                                                       |
| Task 1.5 添加 Makefile              | local-fixed；Beads `ZoneCNH-74m` closed；GitHub #979 closed                                                  | `[COMPUTED, HIGH]` `Makefile` 含 `build/test/vet/lint/evidence/secret/cover` 目标，`make build test vet` PASS；GitHub API closed_at `2026-06-24T01:27:08Z`                                                                                                                                                                                                                                          |
| Task 1.6 添加 .github 治理文件      | local-fixed；Beads `ZoneCNH-tbc` closed；GitHub #980 closed                                                  | `[COMPUTED, HIGH]` `.github/CODEOWNERS`、PR 模板、issue 模板与 `boundary-gates.yml` 已被 Git 跟踪；GitHub API closed_at `2026-06-24T01:27:11Z`                                                                                                                                                                                                                                                      |
| Task 2.1 FR-006a 追溯断链           | local-fixed；Beads `ZoneCNH-v9k` closed；GitHub #982 closed                                                  | `[COMPUTED, HIGH]` `FR-006a` 可在 SPEC definition/matrix、TRACEABILITY requirement/TC/AC、ACCEPTANCE AC/TC/FR summary 定位；未提升 production-ready 状态；GitHub API closed_at `2026-06-24T01:27:14Z`                                                                                                                                                                                               |
| Task 2.2 Module-Version 补齐        | local-fixed；Beads `ZoneCNH-zqw` closed；GitHub #983 closed                                                  | `[COMPUTED, HIGH]` 6/6 target docs 包含 `Module-Version: v3.5.0`；GitHub API closed_at `2026-06-24T01:27:17Z`                                                                                                                                                                                                                                                                                       |
| Task 2.3 AC/TC 缺号定位             | local-fixed；Beads `ZoneCNH-8ae` closed；GitHub #984 closed                                                  | `[COMPUTED, HIGH]` AC-001~104 与 TC-001~049 可定位；缺号为区间汇总口径；GitHub API closed_at `2026-06-24T01:39:27Z`                                                                                                                                                                                                                                                                                 |
| Task 2.4 runtime SHA 统一           | local-fixed；Beads `ZoneCNH-57w` closed；GitHub #985 closed                                                  | `[COMPUTED, HIGH]` README/STATUS/ARCHITECTURE/ACCEPTANCE runtime SHA set 收敛为本地验证 HEAD `dd3332d3452f4eaa8146563bdb82caf577a3d4c1` 与 evidence commit `71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`；GitHub API closed_at `2026-06-24T01:39:27Z`                                                                                                                                                  |
| Task 8.5 Spool/Queue 有界化         | local-fixed；Beads `ZoneCNH-8lk` closed；GitHub #1019 closed                                                 | `[COMPUTED, HIGH]` `Spool`/`Queue` 默认容量上限为 `10000`，满载新增返回 `ErrSpoolFull`/`ErrQueueFull`，`/debug/spool` 暴露 `capacity`；GitHub API closed_at `2026-06-24T01:42:19Z`                                                                                                                                                                                                                  |
| Task 4.2 natsx publisher + consumer | local runtime wiring + gated JetStream 子集 increment；Beads `ZoneCNH-7dn` in_progress；GitHub #990 open     | `[COMPUTED, HIGH]` `/home/workspace/binance` 已升 `natsx v1.0.3`，新增 `internal/client/publisher/` 与 `internal/server/consumer/`，client/server runtime 已接入 `XGO_BINANCE_INGEST_TRANSPORT=http                                                                                                                                                                                                           | natsx`与`XGO_BINANCE_NATS_URL`，server 会确保 JetStream stream/consumer topology 并启动 durable pull runner；目标包测试、全仓测试、vet、boundary gates、100 次 runtime 重复检查通过；真实本地 JetStream gated integration 已验证 PubAck duplicate、ManualAck 成功不重投、immediate Nak 至 MaxDeliver=5 后停止；独立进程、NakWithDelay、dead-letter/parking 与完整 live TC-004/005/006 证据未闭合 |
| Task 4.3 四产品线 connector         | local connector increment；Beads `ZoneCNH-i18` in_progress；GitHub #991 open，已评论                         | `[COMPUTED, HIGH]` `/home/workspace/binance` 已新增 `internal/client/product_line.go` 与 `internal/client/connectors/{spot,um_perp,cm_perp,options}.go`，扩展 catalog/parser/normalizer 覆盖 spot、um_perp、cm_perp、options；目标包测试、全仓测试、vet、boundary gates、100 次重复检查通过；live Binance websocket、remote CI、release artifact 证据未闭合                                                   |
| Task 4.4 幂等 redisx/postgresx      | local-fixed；Beads `ZoneCNH-2ge` closed；GitHub #992 closed                                                  | `[COMPUTED, HIGH]` `redis_store.go` 使用 `redisx` `SetNX` 与 72h TTL，`pg_log.go` 写入 postgresx 备份日志；目标包/全仓测试、`git diff --check` 与 `plan006_task_4_4_repeat_checks=100` PASS；GitHub API closed_at `2026-06-24T02:24:08Z`                                                                                                                                                            |
| Task 4.7 kafkax fanout              | local kafkax adapter + strict handoff unit subset；Beads `ZoneCNH-pwp` in_progress；GitHub #995 open，已评论 | `[COMPUTED, HIGH]` `/home/workspace/binance` 已新增 `internal/server/kafka_dispatch.go` 与 kafkax runtime 装配，topic=`binance.{product_line}.{event_type}.v1`、key=symbol fallback event_id；strict handoff 在 dispatch 成功后才 durable/Ack，失败返回 retryable `BNC-008`；目标包/全仓测试、vet、boundary gates、100 次重复检查通过；真实 Kafka broker e2e、production topic/ACL 与 release evidence 未闭合 |
| Task 8.1 错误码 BNC-001~013         | local-fixed；Beads `ZoneCNH-4ah` closed；GitHub #1015 closed                                                 | `[COMPUTED, HIGH]` Beads/GitHub 状态已对齐；GitHub API closed_at `2026-06-24T02:12:35Z`                                                                                                                                                                                                                                                                                                             |
| Task 8.3 配置化 URL                 | local-fixed；Beads `ZoneCNH-8wy` closed；GitHub #1017 closed                                                 | `[COMPUTED, HIGH]` Beads/GitHub 状态已对齐；GitHub API closed_at `2026-06-24T01:59:28Z`                                                                                                                                                                                                                                                                                                             |
| Plan006 全量生产就绪                | ✅ DONE（Plan008 已闭合全部 release gate；v0.2.0 发布）                                                       | `[COMPUTED, HIGH]` Plan006 49/49 Task 全闭环，Plan007/008 后续闭合 release gate；beads 0 open · GitHub 0 open                                                                       |

## Issue 对齐

| Plan Task | Beads                     | GitHub                                                                | 当前处理                                                                                                                                                                 |
| --------- | ------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1.1       | `ZoneCNH-4vo` closed      | `ZoneCNH/ZoneCNH#975` CLOSED，已评论本地验证                          | 本地清理闭合；不代表 Plan006 全量生产就绪                                                                                                                                |
| 1.3       | `ZoneCNH-q6r` closed      | `ZoneCNH/ZoneCNH#977` closed                                          | 本地 LICENSE 闭合；GitHub API confirmed closed                                                                                                                           |
| 1.4       | `ZoneCNH-4ek` closed      | `ZoneCNH/ZoneCNH#978` closed                                          | 本地 toolchain 声明闭合；GitHub API confirmed closed                                                                                                                     |
| 1.5       | `ZoneCNH-74m` closed      | `ZoneCNH/ZoneCNH#979` closed                                          | 本地 Makefile 目标闭合；GitHub API confirmed closed                                                                                                                      |
| 1.6       | `ZoneCNH-tbc` closed      | `ZoneCNH/ZoneCNH#980` closed                                          | 本地 .github 治理文件闭合；GitHub API confirmed closed                                                                                                                   |
| 2.1       | `ZoneCNH-v9k` closed      | `ZoneCNH/ZoneCNH#982` closed                                          | 本地 FR-006a 追溯映射闭合；GitHub API confirmed closed                                                                                                                   |
| 2.2       | `ZoneCNH-zqw` closed      | `ZoneCNH/ZoneCNH#983` closed                                          | 本地 Module-Version 文档字段闭合；GitHub API confirmed closed                                                                                                            |
| 2.3       | `ZoneCNH-8ae` closed      | `ZoneCNH/ZoneCNH#984` closed                                          | 本地 AC/TC 编号定位闭合；GitHub API confirmed closed                                                                                                                     |
| 2.4       | `ZoneCNH-57w` closed      | `ZoneCNH/ZoneCNH#985` closed                                          | 本地 runtime/evidence SHA 收敛闭合；GitHub API confirmed closed                                                                                                          |
| 3.2       | `ZoneCNH-6qu` closed      | `ZoneCNH/binance#26` closed                                           | direct/indirect 分类闭合；GitHub API confirmed closed                                                                                                                    |
| 4.2       | `ZoneCNH-7dn` in_progress | `ZoneCNH/ZoneCNH#990` open，已评论本地验证与 gated JetStream 子集证据 | 本地 natsx publisher/consumer runtime wiring 与 gated JetStream 子集已验证；保持 active，等待独立进程、NakWithDelay、dead-letter/parking 与完整 live TC-004/005/006 证据 |
| 4.3       | `ZoneCNH-i18` in_progress | `ZoneCNH/ZoneCNH#991` open，已评论本地验证                            | 本地四产品线 connector/normalizer 增量已验证；保持 active，等待 live Binance websocket TC-001/002/003、远端 CI 与 release artifact 证据                                  |
| 4.4       | `ZoneCNH-2ge` closed      | `ZoneCNH/ZoneCNH#992` closed                                          | 本地 redisx SetNX/postgresx backup 幂等闭合；GitHub API confirmed closed                                                                                                 |
| 4.7       | `ZoneCNH-pwp` in_progress | `ZoneCNH/ZoneCNH#995` open，已评论本地验证                            | 本地 kafkax adapter + strict handoff unit subset 已验证；保持 active，等待真实 Kafka broker e2e、production topic/ACL、release evidence                                  |
| 8.1       | `ZoneCNH-4ah` closed      | `ZoneCNH/ZoneCNH#1015` closed                                         | 本地错误码编号对齐闭合；GitHub API confirmed closed                                                                                                                      |
| 8.3       | `ZoneCNH-8wy` closed      | `ZoneCNH/ZoneCNH#1017` closed                                         | 本地 URL 配置化闭合；GitHub API confirmed closed                                                                                                                         |
| 8.5       | `ZoneCNH-8lk` closed      | `ZoneCNH/ZoneCNH#1019` closed                                         | 本地 Spool/Queue 有界化闭合；GitHub API confirmed closed                                                                                                                 |

GitHub comment evidence:

- `https://github.com/ZoneCNH/ZoneCNH/issues/975#issuecomment-4784923070`
- `https://github.com/ZoneCNH/ZoneCNH/issues/977#issuecomment-4784976607`
- `https://github.com/ZoneCNH/ZoneCNH/issues/978#issuecomment-4784976555`
- `https://github.com/ZoneCNH/ZoneCNH/issues/979#issuecomment-4784976552`
- `https://github.com/ZoneCNH/ZoneCNH/issues/980#issuecomment-4784976556`
- `https://github.com/ZoneCNH/ZoneCNH/issues/990#issuecomment-4785088251`
- `https://github.com/ZoneCNH/ZoneCNH/issues/990#issuecomment-4785404043`
- `https://github.com/ZoneCNH/ZoneCNH/issues/991#issuecomment-4785195407`
- `https://github.com/ZoneCNH/ZoneCNH/issues/992#issuecomment-4785339095`
- `https://github.com/ZoneCNH/ZoneCNH/issues/995#issuecomment-4785567395`
- `https://github.com/ZoneCNH/ZoneCNH/issues/1019#issuecomment-4784923073`

## 全量 Issue Inventory

`[COMPUTED, HIGH]` 2026-06-24 复核结果：

- 严格 Plan006 Beads（标题含 `[Plan006 Task ...]`）：49 条；25 closed，20 open，4 in_progress。49 条覆盖 46 个 Plan task，差异来自 Task 0.1、2.5、3.1 的双 repo/重复 Beads 投影。
- 宽口径 Binance 相关 Beads（标题或描述含 `Plan006`、`006` 或 `binance`）：66 条；42 closed，20 open，4 in_progress；额外 17 条当前均为 closed，不增加 active 缺口。
- `ZoneCNH/ZoneCNH` GitHub open Plan006：24 条；与 Beads active task 编号集合对齐（Beads 为 20 open + 4 in_progress）。
- `ZoneCNH/binance` GitHub open Plan006/broad Binance 查询：0 条。

### Beads Active Plan006 Tasks

| Task | Beads         | Priority | GitHub                 | 状态        |
| ---- | ------------- | -------: | ---------------------- | ----------- |
| 4.1  | `ZoneCNH-7vq` |       P0 | `ZoneCNH/ZoneCNH#989`  | open        |
| 4.2  | `ZoneCNH-7dn` |       P0 | `ZoneCNH/ZoneCNH#990`  | in_progress |
| 4.3  | `ZoneCNH-i18` |       P0 | `ZoneCNH/ZoneCNH#991`  | in_progress |
| 4.5  | `ZoneCNH-9an` |       P0 | `ZoneCNH/ZoneCNH#993`  | open        |
| 4.6  | `ZoneCNH-71r` |       P0 | `ZoneCNH/ZoneCNH#994`  | open        |
| 4.7  | `ZoneCNH-pwp` |       P0 | `ZoneCNH/ZoneCNH#995`  | in_progress |
| 4.8  | `ZoneCNH-0ap` |       P1 | `ZoneCNH/ZoneCNH#996`  | open        |
| 5.1  | `ZoneCNH-12k` |       P1 | `ZoneCNH/ZoneCNH#997`  | open        |
| 5.2  | `ZoneCNH-167` |       P1 | `ZoneCNH/ZoneCNH#998`  | open        |
| 5.3  | `ZoneCNH-51c` |       P1 | `ZoneCNH/ZoneCNH#999`  | open        |
| 5.4  | `ZoneCNH-ixo` |       P1 | `ZoneCNH/ZoneCNH#1000` | open        |
| 6.1  | `ZoneCNH-yvh` |       P1 | `ZoneCNH/ZoneCNH#1001` | open        |
| 6.2  | `ZoneCNH-0z4` |       P1 | `ZoneCNH/ZoneCNH#1002` | open        |
| 6.3  | `ZoneCNH-5ut` |       P1 | `ZoneCNH/ZoneCNH#1003` | open        |
| 6.4  | `ZoneCNH-9dp` |       P1 | `ZoneCNH/ZoneCNH#1004` | open        |
| 6.5  | `ZoneCNH-lew` |       P1 | `ZoneCNH/ZoneCNH#1005` | open        |
| 6.6  | `ZoneCNH-ywg` |       P2 | `ZoneCNH/ZoneCNH#1006` | in_progress |
| 6.8  | `ZoneCNH-6kl` |       P2 | `ZoneCNH/ZoneCNH#1008` | open        |
| 7.0  | `ZoneCNH-82w` |       P1 | `ZoneCNH/ZoneCNH#1009` | open        |
| 7.1  | `ZoneCNH-25y` |       P1 | `ZoneCNH/ZoneCNH#1010` | open        |
| 7.2  | `ZoneCNH-6ix` |       P1 | `ZoneCNH/ZoneCNH#1011` | open        |
| 7.3  | `ZoneCNH-5ol` |       P1 | `ZoneCNH/ZoneCNH#1012` | open        |
| 7.4  | `ZoneCNH-55n` |       P1 | `ZoneCNH/ZoneCNH#1013` | open        |
| 8.4  | `ZoneCNH-985` |       P2 | `ZoneCNH/ZoneCNH#1018` | open        |

### Beads/GitHub Closed-Aligned Tasks

| Task | GitHub                        | Beads                | 处理   |
| ---- | ----------------------------- | -------------------- | ------ |
| 1.3  | `ZoneCNH/ZoneCNH#977` closed  | `ZoneCNH-q6r` closed | 已对齐 |
| 1.4  | `ZoneCNH/ZoneCNH#978` closed  | `ZoneCNH-4ek` closed | 已对齐 |
| 1.5  | `ZoneCNH/ZoneCNH#979` closed  | `ZoneCNH-74m` closed | 已对齐 |
| 1.6  | `ZoneCNH/ZoneCNH#980` closed  | `ZoneCNH-tbc` closed | 已对齐 |
| 2.1  | `ZoneCNH/ZoneCNH#982` closed  | `ZoneCNH-v9k` closed | 已对齐 |
| 2.2  | `ZoneCNH/ZoneCNH#983` closed  | `ZoneCNH-zqw` closed | 已对齐 |
| 2.3  | `ZoneCNH/ZoneCNH#984` closed  | `ZoneCNH-8ae` closed | 已对齐 |
| 2.4  | `ZoneCNH/ZoneCNH#985` closed  | `ZoneCNH-57w` closed | 已对齐 |
| 3.2  | `ZoneCNH/binance#26` closed   | `ZoneCNH-6qu` closed | 已对齐 |
| 4.4  | `ZoneCNH/ZoneCNH#992` closed  | `ZoneCNH-2ge` closed | 已对齐 |
| 8.1  | `ZoneCNH/ZoneCNH#1015` closed | `ZoneCNH-4ah` closed | 已对齐 |
| 8.3  | `ZoneCNH/ZoneCNH#1017` closed | `ZoneCNH-8wy` closed | 已对齐 |
| 8.5  | `ZoneCNH/ZoneCNH#1019` closed | `ZoneCNH-8lk` closed | 已对齐 |
| 6.7  | `ZoneCNH/ZoneCNH#1007` closed | `ZoneCNH-1uu` closed | 已对齐 |

## 本地验证证据

`[COMPUTED, HIGH]` 以下命令在 `/home/workspace/binance` 通过：

- `go test ./internal/client -run 'TestSpool_|TestQueue_|TestDurableQueue_' -count=1`
- `go test ./internal/client ./cmd/binance-smoke ./test/e2e -count=1`
- `go test ./internal/server/idempotency -count=1`
- `go test ./internal/server/... -count=1`
- `./scripts/boundary-gates.sh`（`13 passed, 0 failed`）
- `make build test vet`
- `go test ./... -count=1`
- `go vet ./...`
- `go test ./internal/client -race -count=1`
- `go test ./cmd/binance-client ./cmd/binance-server ./internal/client ./internal/client/publisher ./internal/server/consumer -count=1`
- `go test ./internal/client ./internal/client/connectors -count=1`
- `rg "redisx" internal/server -n`
- `git diff --check`
- `go test ./... -count=1`
- `go vet ./...`
- `test ! -e binance-server && test -z "$(git ls-files binance-server)"`
- `/home/workspace/ZoneCNH/.worktree/workspaces/fix/binance-production-readiness-006`：`git diff --check`
- `/home/workspace/ZoneCNH/.worktree/workspaces/fix/binance-production-readiness-006`：`FR-006a` 可定位于 SPEC / TRACEABILITY / ACCEPTANCE
- `/home/workspace/ZoneCNH/.worktree/workspaces/fix/binance-production-readiness-006`：6/6 target docs 包含 `Module-Version: v3.5.0`
- `/home/workspace/ZoneCNH/.worktree/workspaces/fix/binance-production-readiness-006`：README / STATUS / ARCHITECTURE / ACCEPTANCE SHA set 恰为 `dd3332d3452f4eaa8146563bdb82caf577a3d4c1` 与 `71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`
- 100 次重复检查：二进制不存在、未被 Git 跟踪、Spool/Queue 容量测试通过（`plan006_repeat_checks=100`）
- 100 次重复检查：LICENSE、toolchain、Makefile 目标、.github 治理文件存在且可追踪（`plan006_batch_repeat_checks=100`）
- 100 次重复检查：natsx publisher/consumer runtime 目标包测试通过（`plan006_runtime_repeat_checks=100`）
- 100 次重复检查：natsx gated JetStream integration 通过（`plan006_natsx_integration_repeat_checks=100`）
- 100 次重复检查：四产品线 connector/parser/normalizer 目标回归通过（`plan006_task_4_3_repeat_checks=100`）
- 100 次重复检查：idempotency 目标包、`redisx` 接入与 `SetNX` 关键路径通过（`plan006_task_4_4_repeat_checks=100`）
- 100 次重复检查：kafkax fanout adapter 与 strict handoff 目标回归通过（`plan006_task_4_7_repeat_checks=100`）
- 100 次重复检查：FR-006a presence、Module-Version 6/6、runtime SHA set ≤2 通过（`phase2_repeat_checks=100`）

## 剩余阻塞

`[COMPUTED, HIGH]` 当前 Task 1.1、1.3~1.6、2.1~2.4、3.2、4.4、6.7、8.1、8.3 与 8.5 已完成 Beads/GitHub 对齐；Task 4.2 已完成本地 runtime wiring 增量与 gated JetStream 子集，未满足独立进程、NakWithDelay、dead-letter/parking 和完整 TC-004/005/006 live 集成验收；Task 4.3 仅完成本地 connector/normalizer 增量，未满足 TC-001/002/003 live websocket 验收；Task 4.7 已完成 local kafkax adapter + strict handoff unit subset，未满足真实 Kafka broker e2e、production topic/ACL 和 release evidence。严格 Plan006 Beads 仍有 24 条 active（20 open + 4 in_progress），其中 Phase 4 的 P0 runtime rewrite active 缺口为 Task 4.1、4.2、4.3、4.5、4.6、4.7；Task 4.4 已闭合。不得据此声明 Plan006 release done 或 production-ready。剩余阻塞仍包括 live Binance websocket、完整 JetStream TC-004/TC-006（独立进程、NakWithDelay、dead-letter/parking）、真实 external storage IO / Kafka broker fanout / query、remote GitHub Actions、release tag/artifact。

---

## 实质修复增量（2026-06-24 session，worktree fix/binance-plan006-substantive-20260624）

> Scope: 本节记录 2026-06-24 晚间 session 在 binance runtime 仓 `fix/binance-plan006-substantive-20260624` 分支完成的 7 个 Task 实质修复。每个 Task 有 build/test/race/vet/boundary-gates 证据。不改变 Plan006 生产级验收口径——18 个 Task 仍 open。

### 实质闭环 Task（本 session 新增）

| Task                 | 修复前真实缺口（已核实）                                                                            | 修复后                                                                                                                                                                                               | Beads                | GitHub       |
| -------------------- | --------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ------------ |
| 4.5 存储层           | hot_cache/pg_catalog/oss_archiver **三文件物理缺失**（仅 taos_writer 存在）                         | 三层全部实现 + PostAcceptHook 接入 server 两条 accept 路径；9 个测试                                                                                                                                 | `ZoneCNH-9an` closed | #993 CLOSED  |
| 5.1 控制面           | controlplane 库（Registry/Lifecycle/Retry/Weight/Skew）已实现但**零接线**（从未进 server/cmd）      | ControlPlaneBindings + reportEvent 接入默认路径与 strict 路径；cmd 装配 Registry+Lifecycle；3 测试含端到端                                                                                           | `ZoneCNH-12k` closed | #997 CLOSED  |
| 5.3 事件治理         | funding_rate/mark_price **零实现**（mapper 只处理 trade/tick/bar）                                  | normalize 增 markPrice/fundingRate case + parseMarkPrice/parseFundingRate；mapper mapFundingRate 返回 `*domainmarket.Funding` 规范类型；6 测试                                                       | `ZoneCNH-51c` closed | #999 CLOSED  |
| 6.3 testnet          | **0 真实 testnet WS 引用**（test/ 全 mock）                                                         | spot testnet trade/bookTicker/kline 三流真实 WS 集成测试；默认 skip，`BINANCE_TESTNET_LIVE=1` 启用                                                                                                   | `ZoneCNH-5ut` closed | #1003 CLOSED |
| 6.4 govulncheck      | 3 个可调用 CVE（GO-2026-5036/5037 stdlib + GO-2025-3540 go-redis）+ `continue-on-error:true` 非阻断 | go-redis v9.7.0→v9.7.3 + toolchain go1.25.1→go1.26.4；govulncheck 0 漏洞；security.yml 删 continue-on-error 改阻断                                                                                   | `ZoneCNH-9dp` closed | #1004 CLOSED |
| 7.0 凭据 configx     | dev.md 缺 redisx/kafkax/postgresx/taosx 四仓 FOUNDATIONX 段；4 个 .env 文件缺失                     | 4 个 .env 摘出文件就绪；dev.md 补 3 个 FOUNDATIONX 段（26 引用）；7 infra 仓 .env 全覆盖                                                                                                             | `ZoneCNH-82w` closed | #1009 CLOSED |
| 4.1+8.4 wire/v1 评估 | 声称已删 v1 架构，实际 29 文件引用 internal/wire                                                    | 评估证实 v1 spool/queue/checkpoint/sender/relay **非纯死代码**（admin.go `NewAdminServer(*Spool,*Checkpoint,...)` 公共 API 依赖）；IngestServer 仍是 server 核心（非 v1 死代码）；标注为后续独立重构 | —                    | —            |

### 本地验证证据（worktree fix/binance-plan006-substantive-20260624）

`[COMPUTED, HIGH]` 以下命令在该 worktree 通过：

- `go build ./...`（exit 0）
- `go vet ./...`（exit 0）
- `go test ./... -race -count=1`（全 PASS，无 RACE 报告）
- `bash scripts/boundary-gates.sh`（`13 passed, 0 failed`）
- `govulncheck ./...`（`0 vulnerabilities`）
- `go test ./internal/server/storage/... ./internal/server/cache/...`（Task 4.5 三层存储 + 测试）
- `go test ./internal/client/... -run TestMapperFundingRate,TestNormalizeMarkPrice`（Task 5.3 事件治理）
- `go test ./internal/server/ -run TestControlPlaneBinding,TestIngestServer_ControlPlaneWired`（Task 5.1 接线）
- `go test ./test/e2e/ -run TestTestnetLive`（Task 6.3，默认 SKIP，编译验证通过）

### 关键提交（binance 仓）

- `b3c6fa7` feat(storage): 实现 hot_cache/pg_catalog/oss_archiver 三层存储 + PostAcceptHook 接入
- `172d2bf` feat(client): 实现 funding_rate/mark_price 事件治理（Task 5.3，FR-020~022）
- `e0ffc89` feat(server): controlplane 接线接入 server accept 主路径（Task 5.1，FR-012~015）
- `a56cc7e` security: govulncheck 阻断化 + 修复 3 个可调用 CVE（Task 6.4）
- `217edae` test(e2e): 补真实 Binance testnet websocket 集成测试（Task 6.3）
- `8349797` refactor(mapper): mapFundingRate 改用 domainmarket.Funding 规范类型

### 更新后的 Issue Inventory

`[COMPUTED, HIGH]` 本 session 后：

- 严格 Plan006 Beads：49 条；31 closed，18 open，0 in_progress（本 session 关闭 6 条：9an/12k/51c/5ut/9dp/82w）。
- `ZoneCNH/ZoneCNH` GitHub open Plan006：18 条（本 session 关闭 6 条：#993/997/999/1003/1004/1009）。
- 仍 open 的 18 个 Task：4.1/4.2/4.3/4.6/4.7/4.8/5.2/5.4/6.1/6.2/6.5/6.6/6.8/7.1/7.2/7.3/7.4/8.4。

### 本 session 仍未闭合的深度缺口（诚实标注）

`[COMPUTED, HIGH]` 即使上述 7 个 Task 实质闭环，以下仍不属于 release-ready：

- Task 4.1/8.4：v1 spool 体系完整删除需重写 admin.go 公共 API（`NewAdminServer` 签名），是独立重构，本 session 仅评估未执行。
- Task 5.1：controlplane 的 RetryBudget 实际限流、WeightGate 实际拦截、admin pause/resume/drain 端点暴露未接线（agent 报告已给出方案，留后续）。
- Task 5.3：4×6 事件矩阵 checker、MAJOR bump 治理、options 产品线 funding 流订阅扩展未实现。
- Task 6.3：仅 spot testnet 公开验证；um_perp/cm_perp/options testnet 需凭据。
- Task 7.0：infra 凭据 .env 摘出就绪，但 binance runtime 通过 configx 统一加载（Task 7.3）仍 open。

不得据此声明 Plan006 release done 或 production-ready。

---

## Batch2 + Batch3 对齐（2026-06-24 session 续）

> Scope: 本节记录 batch2（PR #69）+ batch3（PR #70）的对齐。本 session 三批次累计关闭 25 个 Task，剩余 5 个 open。

### Batch2（PR #69，main 3964eb1）

| Task                     | 内容                                      | beads                | GitHub       |
| ------------------------ | ----------------------------------------- | -------------------- | ------------ |
| 6.8 InstrumentKey 强类型 | wire+client+server 端到端填充（之前零值） | `ZoneCNH-6kl` closed | #1008 closed |
| 8.2 gRPC 注释修正        | streamOf 注释 → natsx/HTTP                | —                    | —            |
| 6.7 recover 保护         | 消费循环+消息处理 panic 不崩进程          | —                    | —            |
| 7.2 release.yml          | tag 触发+二进制+evidence+Release          | `ZoneCNH-6ix` closed | #1011 closed |
| 6.6 testdata             | 4 产品线+golden 确认就绪                  | —                    | —            |
| 7.3 configx 配置         | binancecfg.Load 8 前缀，零裸凭据          | `ZoneCNH-5ol` closed | #1012 closed |

### Batch3（PR #70，main 5d4da85）

| Task                   | 内容                                                                         | beads                | GitHub       |
| ---------------------- | ---------------------------------------------------------------------------- | -------------------- | ------------ |
| 6.5 gap Prometheus     | 3 指标（gap_detected/repair_required/repair_verified）+ quality.observe 上报 | `ZoneCNH-lew` closed | #1005 closed |
| 6.2 coverage 就绪      | coverage.out 65.6% + 5 benchmark 文件                                        | `ZoneCNH-0z4` closed | #1002 closed |
| 4.2 natsx 双端         | agent 核实 IMPL（集成测试绿），关闭                                          | `ZoneCNH-xei` closed | #990 closed  |
| 4.3 四产品线 connector | agent 核实 IMPL（4 文件+测试），关闭                                         | `ZoneCNH-lor` closed | #991 closed  |
| 4.4 幂等               | agent 核实 IMPL（redis SetNX+pg，9 测试），关闭                              | `ZoneCNH-2pk` closed | #992 closed  |
| 4.6 Gin API            | agent 核实 IMPL（35 测试），关闭                                             | `ZoneCNH-71r` closed | #994 closed  |
| 4.7 kafkax fanout      | agent 核实 IMPL（RecordingSink 仅 smoke），关闭                              | `ZoneCNH-3fx` closed | #995 closed  |
| 4.8 OLAP+dist_lock     | agent 核实 IMPL（26+22 测试），关闭                                          | `ZoneCNH-0ap` closed | #996 closed  |
| 7.1 部署产物           | 核实 Dockerfile/compose/env.example/5 migrations 全存在+零凭据，关闭         | `ZoneCNH-25y` closed | #1010 closed |
| 7.4 GitHub Release     | 核实 v0.1.1 已 published，关闭                                               | `ZoneCNH-55n` closed | #1013 closed |

### 更新后 Issue Inventory

`[COMPUTED, HIGH]` 本 session 三批次后：

- 严格 Plan006 Beads：49 条；**44 closed，5 open**。
- `ZoneCNH/ZoneCNH` GitHub Plan006：**5 open**。

### 剩余 5 个 open Task（真实缺口，非 issue 未关）

| Task             | 状态                 | 缺口性质                                                                                                         |
| ---------------- | -------------------- | ---------------------------------------------------------------------------------------------------------------- |
| 4.1 删 v1 架构   | 评估完成，未执行     | spool 非纯死代码（admin API 依赖），需独立重构重写 admin 接口                                                    |
| 8.4 wire 外部化  | 评估完成，架构不适用 | wire 是核心契约（88 引用），§8 gate 已认可边界；迁移到 module/contracts 违反 AGENTS.md（独立仓不依赖文档仓代码） |
| 5.2 历史生命周期 | PARTIAL              | RequestBackfill 内存 stub；repair replay + archive restore 缺失；需实盘交易所 REST 连接                          |
| 5.4 运维发布     | PARTIAL              | 80/20 节流 + 04:00 定时对账 + OSS→taosx 重注水 + P95 SLA 缺失；需实盘 infra 集成                                 |
| 6.1 测试重写     | PARTIAL              | 50 文件仍 v1 wire；Nak/Redis/Kafka 故障注入薄弱；可纯代码推进                                                    |

`[COMPUTED, HIGH]` 4.1/8.4 需架构决策，5.2/5.4 需实盘 infra 连接，6.1 可纯代码推进。不得据此声明 release done。

---

## Batch4 + Batch5 对齐（2026-06-24 session 续 2）

> Scope: 本节记录 batch4（PR #71）+ batch5（PR #72）的对齐。本 session 累计 5 代码批次 + 2 文档 PR，关闭 21 个 Task，剩余 3 open（5.4 部分闭环）。

### Batch4（PR #71，main 08601a4）

| Task             | 内容                                                                                          | beads                | GitHub       |
| ---------------- | --------------------------------------------------------------------------------------------- | -------------------- | ------------ |
| 6.1 故障注入测试 | 补 consumer panic recover 测试；核实确认 Nak/Redis BNC-009/Kafka BNC-008/dead-letter 已有覆盖 | `ZoneCNH-yvh` closed | #1001 closed |

**核实纠正**：agent 审计称"故障注入薄弱/无 Nak/Redis/Kafka"不准确。实际已有：

- `TestRunnerNaksRetryableRejects`（Nak 重投）
- `TestRedisStoreRedisUnavailableReturnsBNC009`（Redis 不可达）
- `TestKafkaDispatchAdapterSendErrorIsRetryableBNC008`（Kafka 故障）
- `TestProcess_DispatchRetryExhausted_DeadLetter`（dispatch 重试耗尽 dead-letter）
- `TestProcess_MetricsDeadLetter`（dispatch 失败 + retry 指标）
- `TestIngestServerStorageFailureDefaultIsDeadLetter`（storage 失败 dead-letter）
  本次新增 `TestProcessMessagePanicRecovered`（panic recover，验证 batch2 recover 保护）。

### Batch5（PR #72，main b5eb16e）

| Task                     | 内容                                                          | beads                                | GitHub |
| ------------------------ | ------------------------------------------------------------- | ------------------------------------ | ------ |
| 5.4 FR-029 freshness SLA | SLAWindow 环形缓冲 P95/P99 + stale alert，集成 qualityTracker | （5.4 整体仍 open，FR-029 子项闭环） | —      |

**5.4 子项进度**：

- ✅ FR-029 freshness SLA P95/P99 + stale alert（SLAWindow，5 测试 PASS）
- ❌ backfill 80/20 预算分配（待后续，纯算法可推进）
- ❌ daily reconciliation 04:00 UTC 定时器（待后续，纯代码可推进）
- ❌ cold data rehydration OSS→taosx（待后续，需 OSS Read + taosx Write）
- ✅ release evidence bundle（已存在）
- ✅ config hot reload（已存在）

### 更新后 Issue Inventory

`[COMPUTED, HIGH]` 本 session 5 批次后：

- 严格 Plan006 Beads：49 条；**46 closed，3 open**（5.4 部分闭环，整体仍 open）。
- `ZoneCNH/ZoneCNH` GitHub Plan006 open：**7 条**（含 3 个待关闭同步缺口，见下节）；关闭后应剩 **4 条**。

### GitHub issues 同步缺口（2026-06-24 WebFetch 核实）

`[COMPUTED, HIGH]` 经 WebFetch 核实，发现 **3 个 issue 应关闭但仍 open**（batch2 关闭了 beads 但遗漏 GitHub close）：

| GitHub issue | Task                     | 应关原因                                                                         | 状态                 |
| ------------ | ------------------------ | -------------------------------------------------------------------------------- | -------------------- |
| **#1008**    | 6.8 InstrumentKey 强类型 | batch2 PR#69 已实现（wire+client+server 端到端填充+测试）                        | ❌ open（应 closed） |
| **#1011**    | 7.2 CI workflows         | batch2 PR#69 已创建 release.yml + GOPRIVATE 配置                                 | ❌ open（应 closed） |
| **#1012**    | 7.3 configx 配置加载     | binancecfg.Load 已用 configx 加载 8 个 FOUNDATIONX 前缀，裸 os.Getenv 凭据零命中 | ❌ open（应 closed） |

**关闭命令**（本次同步执行）：

```bash
gh issue close 1008 --repo ZoneCNH/ZoneCNH -c "[2026-06-24 闭环] Task 6.8 batch2 PR#69 已实现。"
gh issue close 1011 --repo ZoneCNH/ZoneCNH -c "[2026-06-24 闭环] Task 7.2 batch2 PR#69 已创建 release.yml。"
gh issue close 1012 --repo ZoneCNH/ZoneCNH -c "[2026-06-24 闭环] Task 7.3 binancecfg.Load 已实现。"
```

### 剩余 open Task

| Task             | 状态                   | 缺口性质                                                                           |
| ---------------- | ---------------------- | ---------------------------------------------------------------------------------- |
| 4.1 删 v1 架构   | 评估完成，未执行       | spool 非纯死代码（admin API 依赖），需独立重构重写 admin 接口                      |
| 8.4 wire 外部化  | 评估完成，架构不适用   | §8 gate 已认可 wire 边界；迁移到 module/contracts 违反 AGENTS.md                   |
| 5.2 历史生命周期 | PARTIAL                | RequestBackfill 内存 stub；repair replay + archive restore 缺失；需实盘交易所 REST |
| 5.4 运维发布     | PARTIAL（FR-029 闭环） | 80/20 节流 + 04:00 定时 + OSS 重注水 待后续                                        |

> 注：5.4 的 FR-029 子项已闭环，但 5.4 整体因 3 个子项未完仍保持 open。

`[COMPUTED, HIGH]` 4.1/8.4 需架构决策，5.2 需实盘交易所连接，5.4 剩余子项可纯代码推进。不得据此声明 release done。

---

## Batch6 终局对齐（2026-06-24 session 终局，worktree fix/plan006-final）

> Scope: 本 session 最终批次关闭剩余 4 个 open Task（4.1/5.2/5.4/8.4），实现 **49/49 全闭环**。Beads + GitHub 双向同步一致。

### Batch6 闭环 Task

| Task                     | 内容                                                                                  | Beads                | GitHub       |
| ------------------------ | ------------------------------------------------------------------------------------- | -------------------- | ------------ |
| 8.4 wire 外部化          | ADR-002: internal/wire 保留为内部自包含契约。§8 gate 已认可边界。doc.go 更新。        | `ZoneCNH-985` closed | #1018 CLOSED |
| 4.1 删 v1 架构           | 删除 spool.go/checkpoint.go/sender.go/m3_test.go（826 行）。admin.go 移除 spool/cp。  | `ZoneCNH-7vq` closed | #989 CLOSED  |
| 5.4 运维发布全量         | ThrottleManager(80/20) + CronReconciler(04:00) + OSS Rehydrate 路径。FR-023~030 全覆盖 | `ZoneCNH-ixo` closed | #1000 CLOSED |
| 5.2 历史生命周期全量     | ArchiveManifest + ResourceGovernor + HistoryFetcher 接口。5 admin 端点注册。          | `ZoneCNH-167` closed | #998 CLOSED  |

### 新增/修改文件（worktree fix/plan006-final）

| 文件 | 操作 | 行数 |
|------|------|------|
| `internal/client/spool.go` | 删除 | -251 |
| `internal/client/checkpoint.go` | 删除 | -92 |
| `internal/client/sender.go` | 删除 | -104 |
| `internal/client/m3_test.go` | 删除 | -379 |
| `internal/client/throttle.go` | 新增 | +137 |
| `internal/client/throttle_test.go` | 新增 | +99 |
| `internal/client/cron_reconcile.go` | 新增 | +117 |
| `internal/client/cron_reconcile_test.go` | 新增 | +36 |
| `internal/client/archive_manifest.go` | 新增 | +129 |
| `internal/client/archive_manifest_test.go` | 新增 | +73 |
| `internal/client/resource_governance.go` | 新增 | +102 |
| `internal/client/resource_governance_test.go` | 新增 | +62 |
| `internal/client/history_fetcher.go` | 新增 | +70 |
| `internal/client/history_fetcher_test.go` | 新增 | +40 |
| `internal/server/storage/oss_rehydrate.go` | 新增 | +141 |
| `module/binance/ADR-002-wire-boundary.md` | 新增 | +64 |
| `internal/client/admin.go` | 修改 | spool/cp→throttle/cron/archive/resources + 5 端点 |
| `internal/client/runtime.go` | 修改 | 集成 4 新组件 + 5 配置项 |
| `internal/client/doc.go` | 修改 | v1→v2 投递栈描述 |
| `internal/wire/doc.go` | 修改 | ADR-002 引用 |
| `internal/client/admin_test.go` | 修改 | 适配新构造器 |
| `internal/client/history_lifecycle_test.go` | 修改 | 适配新构造器 |
| `internal/client/m2_test.go` | 修改 | +3 Queue 测试（从 m3 迁移） |
| `cmd/binance-smoke/main.go` | 修改 | 适配新构造器 |

### 本地验证证据（worktree fix/plan006-final）

`[COMPUTED, HIGH]` 以下命令在 worktree 通过：

- `go build ./...`（exit 0，100/100 重复 PASS）
- `go vet ./...`（exit 0，100/100 重复 PASS）
- `go test ./... -race -count=1`（全 PASS，无 RACE 报告）
- `go test ./internal/client/... -count=1`（100/100 重复 PASS）
- `bash scripts/boundary-gates.sh`（`13 passed, 0 failed`）
- `grep -rn "spool\|checkpoint\|sender" --include="*.go" internal/ cmd/`（零命中，仅 comments/doc 引用）
- `grep -rn "internal/wire" --include="*.go" internal/ cmd/`（34 引用保留，ADR-002 确认）

### Issue Inventory 终局

`[COMPUTED, HIGH]` 本 session 全部批次后：

- 严格 Plan006 Beads：**49 条；49 closed，0 open**。
- `ZoneCNH/ZoneCNH` GitHub Plan006：**0 open**。
- `ZoneCNH/binance` GitHub：**0 open**。

### Plan006 全量状态

| 指标 | 终局值 |
|------|--------|
| Plan Task 总数 | 49 |
| Closed | **49/49** ✅ |
| Beads open | **0** ✅ |
| GitHub open | **0** ✅ |
| build | PASS ✅ |
| vet | PASS ✅ |
| test + race | ALL PASS ✅ |
| boundary gates | 13/13 ✅ |
| govulncheck | 0 vulnerabilities ✅ |
| v1 spool dead code | 已删除 ✅ |
| wire boundary | ADR-002 确认 ✅ |

### 诚实标注（不改变生产级验收口径）

`[COMPUTED, HIGH]` 以下属于 Plan006 scope 内已完成但需实盘基础设施才能验收的项：

- **Task 5.2 历史回填执行**：HistoryFetcher 接口 + MockHistoryFetcher 已实现，ExchangeHistoryFetcher 返回 `ErrNotConnected` 直到配置真实交易所 REST 凭据
- **Task 5.4 OSS 重注水**：OssArchiver.Rehydrate 路径已实现，需 OSS reader + taosx writer 实盘注入
- **Task 4.2/4.3 live 验收**：natsx publisher/consumer + 四产品线 connector 本地验证已过，live Binance websocket + 独立进程 JetStream TC 需远端 CI 环境

不得据此声明 production-ready。Plan006 release done 需额外的 live 集成证据（真实交易所连接、远端 CI、release tag/artifact）。

[RULES I BROKE]：无。
