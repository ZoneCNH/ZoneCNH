# Plan006 执行对齐记录（2026-06-24）

> Scope: 本记录同步 agent team、本地验证、Beads、GitHub issue 状态；不改变 `006-binance-production-readiness-fix.md` 的发布就绪或生产级验收口径。

## 状态摘要

| 项 | 状态 | 证据 |
|---|---|---|
| Task 1.1 清理 14MB 二进制 | local-fixed；Beads `ZoneCNH-4vo` closed；GitHub #975 CLOSED | `[COMPUTED, HIGH]` `/home/binance` 工作树无 `binance-server` 文件，`git ls-files binance-server` 为空，`git diff --check` PASS |
| Task 1.3 添加 LICENSE | local-fixed；Beads `ZoneCNH-q6r` closed；GitHub #977 closed | `[COMPUTED, HIGH]` `/home/binance/LICENSE` 已被 Git 跟踪，内容为 MIT License，100 次重复检查命中 LICENSE 文件；GitHub API closed_at `2026-06-24T01:27:02Z` |
| Task 1.4 锁定 Go toolchain | local-fixed；Beads `ZoneCNH-4ek` closed；GitHub #978 closed | `[COMPUTED, HIGH]` `go.mod` 包含 `go 1.25.0` 与 `toolchain go1.25.1`，`make build test vet` PASS；GitHub API closed_at `2026-06-24T01:27:05Z` |
| Task 1.5 添加 Makefile | local-fixed；Beads `ZoneCNH-74m` closed；GitHub #979 closed | `[COMPUTED, HIGH]` `Makefile` 含 `build/test/vet/lint/evidence/secret/cover` 目标，`make build test vet` PASS；GitHub API closed_at `2026-06-24T01:27:08Z` |
| Task 1.6 添加 .github 治理文件 | local-fixed；Beads `ZoneCNH-tbc` closed；GitHub #980 closed | `[COMPUTED, HIGH]` `.github/CODEOWNERS`、PR 模板、issue 模板与 `boundary-gates.yml` 已被 Git 跟踪；GitHub API closed_at `2026-06-24T01:27:11Z` |
| Task 2.1 FR-006a 追溯断链 | local-fixed；Beads `ZoneCNH-v9k` closed；GitHub #982 closed | `[COMPUTED, HIGH]` `FR-006a` 可在 SPEC definition/matrix、TRACEABILITY requirement/TC/AC、ACCEPTANCE AC/TC/FR summary 定位；未提升 production-ready 状态；GitHub API closed_at `2026-06-24T01:27:14Z` |
| Task 2.2 Module-Version 补齐 | local-fixed；Beads `ZoneCNH-zqw` closed；GitHub #983 closed | `[COMPUTED, HIGH]` 6/6 target docs 包含 `Module-Version: v3.5.0`；GitHub API closed_at `2026-06-24T01:27:17Z` |
| Task 2.3 AC/TC 缺号定位 | local-fixed；Beads `ZoneCNH-8ae` closed；GitHub #984 closed | `[COMPUTED, HIGH]` AC-001~104 与 TC-001~049 可定位；缺号为区间汇总口径；GitHub API closed_at `2026-06-24T01:39:27Z` |
| Task 2.4 runtime SHA 统一 | local-fixed；Beads `ZoneCNH-57w` closed；GitHub #985 closed | `[COMPUTED, HIGH]` README/STATUS/ARCHITECTURE/ACCEPTANCE runtime SHA set 收敛为本地验证 HEAD `dd3332d3452f4eaa8146563bdb82caf577a3d4c1` 与 evidence commit `71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`；GitHub API closed_at `2026-06-24T01:39:27Z` |
| Task 8.5 Spool/Queue 有界化 | local-fixed；Beads `ZoneCNH-8lk` closed；GitHub #1019 closed | `[COMPUTED, HIGH]` `Spool`/`Queue` 默认容量上限为 `10000`，满载新增返回 `ErrSpoolFull`/`ErrQueueFull`，`/debug/spool` 暴露 `capacity`；GitHub API closed_at `2026-06-24T01:42:19Z` |
| Task 4.2 natsx publisher + consumer | local runtime wiring + gated JetStream 子集 increment；Beads `ZoneCNH-7dn` in_progress；GitHub #990 open | `[COMPUTED, HIGH]` `/home/binance` 已升 `natsx v1.0.3`，新增 `internal/client/publisher/` 与 `internal/server/consumer/`，client/server runtime 已接入 `XGO_BINANCE_INGEST_TRANSPORT=http|natsx` 与 `XGO_BINANCE_NATS_URL`，server 会确保 JetStream stream/consumer topology 并启动 durable pull runner；目标包测试、全仓测试、vet、boundary gates、100 次 runtime 重复检查通过；真实本地 JetStream gated integration 已验证 PubAck duplicate、ManualAck 成功不重投、immediate Nak 至 MaxDeliver=5 后停止；独立进程、NakWithDelay、dead-letter/parking 与完整 live TC-004/005/006 证据未闭合 |
| Task 4.3 四产品线 connector | local connector increment；Beads `ZoneCNH-i18` in_progress；GitHub #991 open，已评论 | `[COMPUTED, HIGH]` `/home/binance` 已新增 `internal/client/product_line.go` 与 `internal/client/connectors/{spot,um_perp,cm_perp,options}.go`，扩展 catalog/parser/normalizer 覆盖 spot、um_perp、cm_perp、options；目标包测试、全仓测试、vet、boundary gates、100 次重复检查通过；live Binance websocket、remote CI、release artifact 证据未闭合 |
| Task 4.4 幂等 redisx/postgresx | local-fixed；Beads `ZoneCNH-2ge` closed；GitHub #992 closed | `[COMPUTED, HIGH]` `redis_store.go` 使用 `redisx` `SetNX` 与 72h TTL，`pg_log.go` 写入 postgresx 备份日志；目标包/全仓测试、`git diff --check` 与 `plan006_task_4_4_repeat_checks=100` PASS；GitHub API closed_at `2026-06-24T02:24:08Z` |
| Task 8.1 错误码 BNC-001~013 | local-fixed；Beads `ZoneCNH-4ah` closed；GitHub #1015 closed | `[COMPUTED, HIGH]` Beads/GitHub 状态已对齐；GitHub API closed_at `2026-06-24T02:12:35Z` |
| Task 8.3 配置化 URL | local-fixed；Beads `ZoneCNH-8wy` closed；GitHub #1017 closed | `[COMPUTED, HIGH]` Beads/GitHub 状态已对齐；GitHub API closed_at `2026-06-24T01:59:28Z` |
| Plan006 全量生产就绪 | IN PROGRESS | `[COMPUTED, HIGH]` live Binance websocket、完整 JetStream TC-004/TC-006（独立进程、NakWithDelay、dead-letter/parking）、真实 external storage IO/fanout/query、remote CI、release tag/artifact 尚未闭合 |

## Issue 对齐

| Plan Task | Beads | GitHub | 当前处理 |
|---|---|---|---|
| 1.1 | `ZoneCNH-4vo` closed | `ZoneCNH/ZoneCNH#975` CLOSED，已评论本地验证 | 本地清理闭合；不代表 Plan006 全量生产就绪 |
| 1.3 | `ZoneCNH-q6r` closed | `ZoneCNH/ZoneCNH#977` closed | 本地 LICENSE 闭合；GitHub API confirmed closed |
| 1.4 | `ZoneCNH-4ek` closed | `ZoneCNH/ZoneCNH#978` closed | 本地 toolchain 声明闭合；GitHub API confirmed closed |
| 1.5 | `ZoneCNH-74m` closed | `ZoneCNH/ZoneCNH#979` closed | 本地 Makefile 目标闭合；GitHub API confirmed closed |
| 1.6 | `ZoneCNH-tbc` closed | `ZoneCNH/ZoneCNH#980` closed | 本地 .github 治理文件闭合；GitHub API confirmed closed |
| 2.1 | `ZoneCNH-v9k` closed | `ZoneCNH/ZoneCNH#982` closed | 本地 FR-006a 追溯映射闭合；GitHub API confirmed closed |
| 2.2 | `ZoneCNH-zqw` closed | `ZoneCNH/ZoneCNH#983` closed | 本地 Module-Version 文档字段闭合；GitHub API confirmed closed |
| 2.3 | `ZoneCNH-8ae` closed | `ZoneCNH/ZoneCNH#984` closed | 本地 AC/TC 编号定位闭合；GitHub API confirmed closed |
| 2.4 | `ZoneCNH-57w` closed | `ZoneCNH/ZoneCNH#985` closed | 本地 runtime/evidence SHA 收敛闭合；GitHub API confirmed closed |
| 3.2 | `ZoneCNH-6qu` closed | `ZoneCNH/binance#26` closed | direct/indirect 分类闭合；GitHub API confirmed closed |
| 4.2 | `ZoneCNH-7dn` in_progress | `ZoneCNH/ZoneCNH#990` open，已评论本地验证与 gated JetStream 子集证据 | 本地 natsx publisher/consumer runtime wiring 与 gated JetStream 子集已验证；保持 active，等待独立进程、NakWithDelay、dead-letter/parking 与完整 live TC-004/005/006 证据 |
| 4.3 | `ZoneCNH-i18` in_progress | `ZoneCNH/ZoneCNH#991` open，已评论本地验证 | 本地四产品线 connector/normalizer 增量已验证；保持 active，等待 live Binance websocket TC-001/002/003、远端 CI 与 release artifact 证据 |
| 4.4 | `ZoneCNH-2ge` closed | `ZoneCNH/ZoneCNH#992` closed | 本地 redisx SetNX/postgresx backup 幂等闭合；GitHub API confirmed closed |
| 8.1 | `ZoneCNH-4ah` closed | `ZoneCNH/ZoneCNH#1015` closed | 本地错误码编号对齐闭合；GitHub API confirmed closed |
| 8.3 | `ZoneCNH-8wy` closed | `ZoneCNH/ZoneCNH#1017` closed | 本地 URL 配置化闭合；GitHub API confirmed closed |
| 8.5 | `ZoneCNH-8lk` closed | `ZoneCNH/ZoneCNH#1019` closed | 本地 Spool/Queue 有界化闭合；GitHub API confirmed closed |

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
- `https://github.com/ZoneCNH/ZoneCNH/issues/1019#issuecomment-4784923073`

## 全量 Issue Inventory

`[COMPUTED, HIGH]` 2026-06-24 复核结果：

- 严格 Plan006 Beads（标题含 `[Plan006 Task ...]`）：49 条；25 closed，21 open，3 in_progress。49 条覆盖 46 个 Plan task，差异来自 Task 0.1、2.5、3.1 的双 repo/重复 Beads 投影。
- 宽口径 Binance 相关 Beads（标题或描述含 `Plan006`、`006` 或 `binance`）：66 条；42 closed，21 open，3 in_progress；额外 17 条当前均为 closed，不增加 active 缺口。
- `ZoneCNH/ZoneCNH` GitHub open Plan006：24 条；与 Beads active task 编号集合对齐（Beads 为 21 open + 3 in_progress）。
- `ZoneCNH/binance` GitHub open Plan006/broad Binance 查询：0 条。

### Beads Active Plan006 Tasks

| Task | Beads | Priority | GitHub | 状态 |
|---|---|---:|---|---|
| 4.1 | `ZoneCNH-7vq` | P0 | `ZoneCNH/ZoneCNH#989` | open |
| 4.2 | `ZoneCNH-7dn` | P0 | `ZoneCNH/ZoneCNH#990` | in_progress |
| 4.3 | `ZoneCNH-i18` | P0 | `ZoneCNH/ZoneCNH#991` | in_progress |
| 4.5 | `ZoneCNH-9an` | P0 | `ZoneCNH/ZoneCNH#993` | open |
| 4.6 | `ZoneCNH-71r` | P0 | `ZoneCNH/ZoneCNH#994` | open |
| 4.7 | `ZoneCNH-pwp` | P0 | `ZoneCNH/ZoneCNH#995` | open |
| 4.8 | `ZoneCNH-0ap` | P1 | `ZoneCNH/ZoneCNH#996` | open |
| 5.1 | `ZoneCNH-12k` | P1 | `ZoneCNH/ZoneCNH#997` | open |
| 5.2 | `ZoneCNH-167` | P1 | `ZoneCNH/ZoneCNH#998` | open |
| 5.3 | `ZoneCNH-51c` | P1 | `ZoneCNH/ZoneCNH#999` | open |
| 5.4 | `ZoneCNH-ixo` | P1 | `ZoneCNH/ZoneCNH#1000` | open |
| 6.1 | `ZoneCNH-yvh` | P1 | `ZoneCNH/ZoneCNH#1001` | open |
| 6.2 | `ZoneCNH-0z4` | P1 | `ZoneCNH/ZoneCNH#1002` | open |
| 6.3 | `ZoneCNH-5ut` | P1 | `ZoneCNH/ZoneCNH#1003` | open |
| 6.4 | `ZoneCNH-9dp` | P1 | `ZoneCNH/ZoneCNH#1004` | open |
| 6.5 | `ZoneCNH-lew` | P1 | `ZoneCNH/ZoneCNH#1005` | open |
| 6.6 | `ZoneCNH-ywg` | P2 | `ZoneCNH/ZoneCNH#1006` | in_progress |
| 6.8 | `ZoneCNH-6kl` | P2 | `ZoneCNH/ZoneCNH#1008` | open |
| 7.0 | `ZoneCNH-82w` | P1 | `ZoneCNH/ZoneCNH#1009` | open |
| 7.1 | `ZoneCNH-25y` | P1 | `ZoneCNH/ZoneCNH#1010` | open |
| 7.2 | `ZoneCNH-6ix` | P1 | `ZoneCNH/ZoneCNH#1011` | open |
| 7.3 | `ZoneCNH-5ol` | P1 | `ZoneCNH/ZoneCNH#1012` | open |
| 7.4 | `ZoneCNH-55n` | P1 | `ZoneCNH/ZoneCNH#1013` | open |
| 8.4 | `ZoneCNH-985` | P2 | `ZoneCNH/ZoneCNH#1018` | open |

### Beads/GitHub Closed-Aligned Tasks

| Task | GitHub | Beads | 处理 |
|---|---|---|---|
| 1.3 | `ZoneCNH/ZoneCNH#977` closed | `ZoneCNH-q6r` closed | 已对齐 |
| 1.4 | `ZoneCNH/ZoneCNH#978` closed | `ZoneCNH-4ek` closed | 已对齐 |
| 1.5 | `ZoneCNH/ZoneCNH#979` closed | `ZoneCNH-74m` closed | 已对齐 |
| 1.6 | `ZoneCNH/ZoneCNH#980` closed | `ZoneCNH-tbc` closed | 已对齐 |
| 2.1 | `ZoneCNH/ZoneCNH#982` closed | `ZoneCNH-v9k` closed | 已对齐 |
| 2.2 | `ZoneCNH/ZoneCNH#983` closed | `ZoneCNH-zqw` closed | 已对齐 |
| 2.3 | `ZoneCNH/ZoneCNH#984` closed | `ZoneCNH-8ae` closed | 已对齐 |
| 2.4 | `ZoneCNH/ZoneCNH#985` closed | `ZoneCNH-57w` closed | 已对齐 |
| 3.2 | `ZoneCNH/binance#26` closed | `ZoneCNH-6qu` closed | 已对齐 |
| 4.4 | `ZoneCNH/ZoneCNH#992` closed | `ZoneCNH-2ge` closed | 已对齐 |
| 8.1 | `ZoneCNH/ZoneCNH#1015` closed | `ZoneCNH-4ah` closed | 已对齐 |
| 8.3 | `ZoneCNH/ZoneCNH#1017` closed | `ZoneCNH-8wy` closed | 已对齐 |
| 8.5 | `ZoneCNH/ZoneCNH#1019` closed | `ZoneCNH-8lk` closed | 已对齐 |
| 6.7 | `ZoneCNH/ZoneCNH#1007` closed | `ZoneCNH-1uu` closed | 已对齐 |

## 本地验证证据

`[COMPUTED, HIGH]` 以下命令在 `/home/binance` 通过：

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
- `/home/ZoneCNH/.worktree/workspaces/fix/binance-production-readiness-006`：`git diff --check`
- `/home/ZoneCNH/.worktree/workspaces/fix/binance-production-readiness-006`：`FR-006a` 可定位于 SPEC / TRACEABILITY / ACCEPTANCE
- `/home/ZoneCNH/.worktree/workspaces/fix/binance-production-readiness-006`：6/6 target docs 包含 `Module-Version: v3.5.0`
- `/home/ZoneCNH/.worktree/workspaces/fix/binance-production-readiness-006`：README / STATUS / ARCHITECTURE / ACCEPTANCE SHA set 恰为 `dd3332d3452f4eaa8146563bdb82caf577a3d4c1` 与 `71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`
- 100 次重复检查：二进制不存在、未被 Git 跟踪、Spool/Queue 容量测试通过（`plan006_repeat_checks=100`）
- 100 次重复检查：LICENSE、toolchain、Makefile 目标、.github 治理文件存在且可追踪（`plan006_batch_repeat_checks=100`）
- 100 次重复检查：natsx publisher/consumer runtime 目标包测试通过（`plan006_runtime_repeat_checks=100`）
- 100 次重复检查：natsx gated JetStream integration 通过（`plan006_natsx_integration_repeat_checks=100`）
- 100 次重复检查：四产品线 connector/parser/normalizer 目标回归通过（`plan006_task_4_3_repeat_checks=100`）
- 100 次重复检查：idempotency 目标包、`redisx` 接入与 `SetNX` 关键路径通过（`plan006_task_4_4_repeat_checks=100`）
- 100 次重复检查：FR-006a presence、Module-Version 6/6、runtime SHA set ≤2 通过（`phase2_repeat_checks=100`）

## 剩余阻塞

`[COMPUTED, HIGH]` 当前 Task 1.1、1.3~1.6、2.1~2.4、3.2、4.4、6.7、8.1、8.3 与 8.5 已完成 Beads/GitHub 对齐；Task 4.2 已完成本地 runtime wiring 增量与 gated JetStream 子集，未满足独立进程、NakWithDelay、dead-letter/parking 和完整 TC-004/005/006 live 集成验收；Task 4.3 仅完成本地 connector/normalizer 增量，未满足 TC-001/002/003 live websocket 验收。严格 Plan006 Beads 仍有 24 条 active（21 open + 3 in_progress），其中 Phase 4 的 P0 runtime rewrite active 缺口为 Task 4.1、4.2、4.3、4.5、4.6、4.7；Task 4.4 已闭合。不得据此声明 Plan006 release done 或 production-ready。剩余阻塞仍包括 live Binance websocket、完整 JetStream TC-004/TC-006（独立进程、NakWithDelay、dead-letter/parking）、真实 external storage IO/fanout/query、remote GitHub Actions、release tag/artifact。
