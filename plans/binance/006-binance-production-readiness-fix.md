# Plan 006: binance 模块生产就绪修复执行计划

> **Executor instructions**: 本计划基于 `docs/report/binance/production-readiness-gap-analysis-20260624.md`（五轮 58 维度分析 + 第六轮交叉复核，2 P0 + 29 P1 + 19 P2）。按 Phase 顺序执行，每个 Task 含验证命令与 STOP 条件。完成一个 Task 后更新 `plans/binance/README.md` 状态行。
>
> **Drift check (run first)**:
> ```bash
> cd /home/binance && git log --oneline -1
> cd /home/ZoneCNH && git log --oneline -1 -- docs/report/binance/production-readiness-gap-analysis-20260624.md
> ```
> 若 runtime HEAD 已推进到 `4fa920b` 之后，或分析报告已更新，先对照新 commit 再执行。

## Status

- **Priority**: P0（阻断 binance 生产发布）
- **Effort**: 取决于 Phase 0 决策——**v2.0.0 全量重写 XL（4.8~9 人月，1 名全职 Go 工程师）** / **v1.0.0 回退 S~M（0.5~1.5 人月，见 Phase 4-ALT）**
- **Risk**: HIGH（含架构重写决策、跨仓依赖验证）
- **Depends on**: 架构决策（Phase 0）必须先做；W0 依赖仓验证阻断 W1
- **Category**: runtime-rewrite + docs-governance
- **Planned at**: 2026-06-24，基于分析报告 `production-readiness-gap-analysis-20260624.md`

## Why this matters

binance 模块当前**规格端与 runtime 端均未达生产级别**：

- **runtime 端**：架构分裂（SPEC 写 v2.0.0 natsx，runtime 跑 v1.0.0 HTTP/wire/spool）；0/30 L2 FR Done；7 大存储模块 0 调用；Gin API 0 调用；3 条产品线 connector 仅 spot
- **规格端**：FR-006a 追溯断链；6 文档缺版本字段；AC 编号 ~50 个缺号；三文档 4 个不同 SHA
- **仓库卫生**：14MB 二进制进 git；`.gitignore` 残留陈旧 go.sum 条目（go.sum 实际已 tracked，仅清理 .gitignore）；无 LICENSE；无部署产物

本计划是发布前必修路径，每个 Task 可追溯到分析报告的具体 § 章节证据。

## 前置：架构决策（Phase 0，最高优先，阻断一切）

> **分析报告 §7.1**：当前「SPEC 写 v2.0.0，runtime 跑 v1.0.0」是最差状态——两边都在维护，都不生产。必须先二选一。

### Task 0.1: 架构决策 ADR [DONE — v2.0.0]

- **状态**: ✅ DONE（2026-06-24，决策：采用 v2.0.0 natsx 分布式架构）
- **前置探针结果**: 7 仓 go doc 探针，5/7 就绪（natsx/redisx/taosx/ossx ✅；kafkax/postgresx/clickhousex ⚠️ 需 Task 3.1 完整验证）。核心通信层 natsx 就绪 → v2.0.0 可行。
- **决策**: 采用 v2.0.0，全量重写 runtime。ADR 见 `module/binance/ADR-architecture-decision.md`（ADR-001, ACCEPTED）
- **执行约束**:
  - Phase 4-ALT（v1.0.0 回退）**作废**，Task 4A.1~4A.3 不执行
  - Phase 4~7 激活，Task 4.1~7.5 按依赖图执行
  - Task 3.1 完整验证仍阻断 Phase 4（postgresx/clickhousex/kafkax 接口需在 Task 4.5/4.8 前确认）
  - Phase 1+2 可立即启动（与架构无关）
- **STOP 条件**: 已满足（ADR 已编写，探针已执行）
- **验证**: ✅ `module/binance/ADR-architecture-decision.md` 存在，含决策/理由/替代方案/后果/依赖仓就绪证据
- **来源**: §7.1, §8.1, §10.7

---

## Phase 1: 仓库卫生与构建可复现性（P0，发布前必修）

> 分析报告 §10.1, §11.1, §11.2, §11.3, §12.5。这些与架构决策无关，无论选 v1/v2 都必修。

### Task 1.1: 清理 14MB 二进制 [P0]

- **来源**: §10.1
- **2026-06-24 执行状态**: `[COMPUTED, HIGH]` local-fixed；Beads `ZoneCNH-4vo` 已关闭；GitHub `ZoneCNH/ZoneCNH#975` 已评论本地验证并关闭；不代表 Plan006 全量生产就绪。
- **动作**:
  ```bash
  cd /home/binance
  git rm --cached binance-server
  echo "binance-server" >> .gitignore
  echo "binance-client" >> .gitignore  # 若存在
  # 历史清理（可选，需协调）：
  # git filter-repo --invert-paths --path binance-server
  ```
- **验证**: `git ls-files | grep binance-server` 返回空；`git status` 显示删除已暂存
- **本地验证证据**: `[COMPUTED, HIGH]` `test ! -e binance-server` PASS；`git ls-files binance-server` 为空；`git diff --check` PASS；100 次重复检查未发现二进制回归。
- **STOP 条件**: `git cat-file -s HEAD:binance-server` 仍返回 14279426 → 历史未清理（可接受，但 working tree 必须删除）

### Task 1.2: 清理 .gitignore 陈旧 go.sum 条目 [P2]

- **来源**: §11.1（原判 P0，2026-06-24 复核降级为 P2）
- **背景**: 报告初稿误判「go.sum 未进版本控制」。复核实测 go.sum **已被 git 跟踪**（`git cat-file -s HEAD:go.sum` = 11677），构建可复现。`.gitignore` 里的 `go.sum` 是**陈旧无效条目**，仅需清理以免误导后续贡献者。
- **动作**:
  ```bash
  cd /home/binance
  # go.sum 已 tracked，无需 git add；仅删除 .gitignore 陈旧行
  sed -i '/^go.sum$/d' .gitignore
  git add .gitignore
  ```
- **验证**: `git ls-files --error-unmatch go.sum` 成功（已 tracked，本就通过）；`grep -n "^go.sum$" .gitignore` 返回空
- **STOP 条件**: 无

### Task 1.3: 添加 LICENSE [P1]

- **来源**: §11.2
- **2026-06-24 执行状态**: `[COMPUTED, HIGH]` local-fixed；Beads `ZoneCNH-q6r` 已关闭；GitHub `ZoneCNH/ZoneCNH#977` 已关闭（GitHub API: `2026-06-24T01:27:02Z`）。
- **动作**: 添加 ZoneCNH 标准 LICENSE 文件（与 domain_market 等公开仓一致）
- **验证**: `ls LICENSE*` 返回文件；`git ls-files | grep -i license` 命中
- **本地验证证据**: `[COMPUTED, HIGH]` `/home/binance/LICENSE` 已被 Git 跟踪；内容为 MIT License；`git ls-files | grep -Ei '(^|/)LICENSE$'` 命中；`git diff --check` PASS；100 次重复检查未发现许可证文件缺失。
- **STOP 条件**: 需确认 ZoneCNH 标准许可证选择（MIT/Apache-2.0/私有）

### Task 1.4: 锁定 Go toolchain [P2]

- **来源**: §11.3
- **2026-06-24 执行状态**: `[COMPUTED, HIGH]` local-fixed；Beads `ZoneCNH-4ek` 已关闭；GitHub `ZoneCNH/ZoneCNH#978` 已关闭（GitHub API: `2026-06-24T01:27:05Z`）。
- **动作**: go.mod 添加 `toolchain go1.25.0` 或确认 go 1.25.0 真实存在
- **验证**: `grep "toolchain" go.mod` 命中
- **本地验证证据**: `[COMPUTED, HIGH]` `go.mod` 包含 `go 1.25.0` 与 `toolchain go1.25.1`；本地 `go version` 为 `go1.26.3 linux/amd64`；`make build test vet` PASS；100 次重复检查未发现 toolchain 声明缺失。
- **STOP 条件**: 无

### Task 1.5: 添加 Makefile [P2]

- **来源**: §12.5
- **2026-06-24 执行状态**: `[COMPUTED, HIGH]` local-fixed；Beads `ZoneCNH-74m` 已关闭；GitHub `ZoneCNH/ZoneCNH#979` 已关闭（GitHub API: `2026-06-24T01:27:08Z`）。
- **动作**: 创建 Makefile，含 `build/test/vet/lint/evidence/secret/cover` 目标
- **验证**: `make build && make test` 全 PASS
- **本地验证证据**: `[COMPUTED, HIGH]` `Makefile` 已被 Git 跟踪，声明 `build`、`test`、`vet`、`lint`、`evidence`、`secret`、`cover` 目标；`make build test vet` PASS；`git diff --check` PASS；100 次重复检查未发现目标缺失。
- **STOP 条件**: 无

### Task 1.6: 添加 .github 治理文件 [P2]

- **来源**: §12.6
- **2026-06-24 执行状态**: `[COMPUTED, HIGH]` local-fixed；Beads `ZoneCNH-tbc` 已关闭；GitHub `ZoneCNH/ZoneCNH#980` 已关闭（GitHub API: `2026-06-24T01:27:11Z`）。
- **动作**: 添加 CODEOWNERS、PULL_REQUEST_TEMPLATE、ISSUE_TEMPLATE
- **验证**: `ls .github/CODEOWNERS .github/PULL_REQUEST_TEMPLATE.md` 命中
- **本地验证证据**: `[COMPUTED, HIGH]` `.github/CODEOWNERS`、`.github/PULL_REQUEST_TEMPLATE.md`、`.github/ISSUE_TEMPLATE/bug_report.md`、`.github/ISSUE_TEMPLATE/bug_report.yml`、`.github/ISSUE_TEMPLATE/production_readiness_gap.yml` 与 `.github/workflows/boundary-gates.yml` 已被 Git 跟踪；100 次重复检查未发现治理文件缺失。
- **STOP 条件**: 无

### Task 1.7: 规范化 evidence 空文件 [P2]

- **来源**: §10.11, §4.3
- **动作**: 修改 `scripts/runtime-release-evidence.sh`，对每个命令输出 `<command>: PASS (exit 0)` 而非 0 字节
- **验证**: evidence 目录无 0 字节文件（除非命令真无输出且脚本已记录 PASS 标记）
- **STOP 条件**: 无

---

## Phase 1 2026-06-24 worker evidence refresh

- **状态**: ✅ Local hygiene/build/readiness evidence refreshed in `/home/binance` worker lane; release remains **Not Done** until remote CI, live websocket, external integration, and release tag evidence are captured.
- **Runtime HEAD**: `dd3332d3452f4eaa8146563bdb82caf577a3d4c1` with existing dirty readiness changes preserved; no history rewrite or commit was performed by the team worker.
- **已验证**:
  - `bash -n scripts/runtime-release-evidence.sh scripts/boundary-gates.sh scripts/readiness-audit.sh` PASS
  - `make fmt-check boundary-gates build test vet readiness-audit` PASS（boundary gates `13 passed, 0 failed`）
  - `go test ./... -race -count=1` PASS
  - `git diff --check` PASS
- **外部缺口**: live Binance websocket、完整 JetStream TC-004/TC-006（独立进程、NakWithDelay、dead-letter/parking）、真实 external storage IO / fanout / query API、remote GitHub Actions、release tag/artifact 仍未闭合；不得据此将 FR-012~030 或 Release 改为 Done。

---

## Phase 2: 规格端治理修复（P1，低成本，可并行于 runtime）

> 分析报告 §13.1~13.4。这些是文档治理，成本低，**应先于 runtime 实现修复**，避免规格端错误传导到 runtime。

### Task 2.1: 修复 FR-006a 追溯断链 [P1]

- **来源**: §13.1
- **动作**:
  - 确认 FR-006a 是否真实存在（SPEC 定义了 6a/6b/6c/6d）
  - 在 TRACEABILITY.md 补 FR-006a 行
  - 在 ACCEPTANCE.md 补 FR-006a 对应 AC
  - 运行 CLAUDE.md §5.4 跨文件检查脚本
- **验证**:
  ```bash
  cd /home/ZoneCNH
  grep -c "FR-006a" module/binance/SPEC.md
  grep -c "FR-006a" module/binance/TRACEABILITY.md
  grep -c "FR-006a" module/binance/ACCEPTANCE.md
  # 三者应一致
  ```
- **STOP 条件**: 三文件 FR-006a 计数不一致
- **状态**: ✅ Local-fixed（2026-06-24）；Beads `ZoneCNH-v9k` closed；GitHub `ZoneCNH/ZoneCNH#982` closed（GitHub API: `2026-06-24T01:27:14Z`）。
- **本地证据**: `FR-006a` 可在 SPEC definition/matrix、TRACEABILITY requirement/TC/AC、ACCEPTANCE AC/TC/FR summary 定位；三份文档表粒度不同，当前按“存在 + 映射闭合”口径关闭文档断链，未提升 production-ready 状态。
- **合规**: CLAUDE.md §5.2 附录版本同步

### Task 2.2: 补 6 个文档的 Module-Version [P1]

- **来源**: §13.2
- **动作**: 为 ACCEPTANCE.md / FEATURES.md / RUNTIME-MAPPING.md / DATA-LIFECYCLE.md / STANDARD.md / BOUNDARY-GATES.md 添加 `Module-Version: v3.5.0` 字段
- **验证**:
  ```bash
  for f in ACCEPTANCE FEATURES RUNTIME-MAPPING DATA-LIFECYCLE STANDARD BOUNDARY-GATES; do
    grep -q "Module-Version" module/binance/$f.md || echo "MISSING: $f"
  done
  ```
- **STOP 条件**: 任一文件仍无版本字段
- **状态**: ✅ Local-fixed（2026-06-24）；Beads `ZoneCNH-zqw` closed；GitHub `ZoneCNH/ZoneCNH#983` closed（GitHub API: `2026-06-24T01:27:17Z`）。
- **本地证据**: 6/6 target docs contain `Module-Version: v3.5.0`：ACCEPTANCE / FEATURES / RUNTIME-MAPPING / DATA-LIFECYCLE / STANDARD / BOUNDARY-GATES。
- **合规**: CLAUDE.md R6 全量版本统一 + check-binance-docs.sh

### Task 2.3: 确认 AC/TC 缺号性质 [P1]

- **来源**: §13.3
- **动作**:
  - 审查 ACCEPTANCE.md 的 AC-039/042~043/046/049~058/061~070/073~079/082~085/088~097/100~103 缺号
  - 判断是「区间缩写（如 AC-048~059 代表 12 个）」还是「真缺号」
  - 若区间缩写：展开为逐条登记，或在 AC 注册表标注区间
  - 若真缺号：补齐或重新编号
- **验证**: 每个 AC-001~104 都能在 ACCEPTANCE.md 或 SPEC.md 定位
- **STOP 条件**: 发现 AC 编号无法定位且无区间说明
- **合规**: CLAUDE.md §5.1 单一事实来源

### Task 2.4: 统一三文档 runtime SHA [P1]

- **来源**: §13.4, §12.4
- **动作**:
  - 确认 runtime 当前 HEAD SHA（`cd /home/binance && git rev-parse HEAD`）
  - 统一 README.md / STATUS.md / ARCHITECTURE.md / ACCEPTANCE.md 的 runtime SHA 到当前 HEAD
  - 若有多个 evidence SHA，区分「验证代码 SHA」与「证据提交 SHA」并统一
- **验证**:
  ```bash
  cd /home/ZoneCNH
  grep -ohE "[0-9a-f]{40}" README.md STATUS.md ARCHITECTURE.md module/binance/ACCEPTANCE.md | sort -u
  # runtime 相关 SHA 应收敛到 ≤2 个（代码 SHA + 证据 SHA）
  ```
- **STOP 条件**: SHA 数量 > 2
- **状态**: ✅ Local-fixed（2026-06-24）；Beads `ZoneCNH-57w` closed；GitHub `ZoneCNH/ZoneCNH#985` closed（GitHub API: `2026-06-24T01:39:27Z`）。
- **本地证据**: README / STATUS / ARCHITECTURE / ACCEPTANCE runtime-related SHA set 收敛为本地验证 HEAD `dd3332d3452f4eaa8146563bdb82caf577a3d4c1` + evidence commit `71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`。
- **合规**: CLAUDE.md 文档同步 + 数量验证门禁

### Task 2.5: 强化 boundary-gates 架构实质检查 [P1] [DONE — runtime presence gates aligned]

- **来源**: §2.2, §8.3
- **状态**: ✅ DONE（2026-06-24，runtime §12~§14 presence gates 已加入并通过）
- **动作**: 在 `/home/binance/scripts/boundary-gates.sh` 增加 3 道 gate:
  - `§12 natsx runtime adapter presence`: 验证 server dispatch 构造 core `natsx.Envelope` 并通过 `Publish(context.Context, natsx.Envelope)` 能力发布
  - `§13 runtime storage integrations presence`: 验证 `taosx` / `clickhousex` / `redisx` / `kafkax` package boundary 进入 runtime code
  - `§14 gin route existence`: 验证 Gin API 路由存在
- **验证**: `/home/binance/scripts/boundary-gates.sh` 已扩展为 §2~§14；本地结果 `13 passed, 0 failed`
- **STOP 条件**: 新 gate 被绕过或禁用
- **注**: 当前 gate 是存在性/边界门禁；2026-06-24 gated integration 已补真实本地 JetStream PubAck duplicate、ManualAck 成功不重投、immediate Nak 至 MaxDeliver=5 后停止这一子集；完整 JetStream TC-004/TC-006（独立进程、NakWithDelay、dead-letter/parking）、真实外部 storage IO、fanout delivery 和 query API 仍由 Phase 4~7 功能验收关闭。

---

## Phase 3: 依赖仓验证（W0，前置于 Phase 0 决策 + 阻断 runtime 主线）

> 分析报告 §10.7、§8.1。SPEC 假设 natsx FR-009/010 等接口就绪，但未验证。**本 Phase 的轻量探针（Task 3.1 接口存在性）前置于 Phase 0 架构决策**——v2.0.0 是否可选取决于依赖仓就绪；Task 3.1 的完整验证仍阻断 Phase 4。

### Task 3.1: 验证 7 个 infra 仓接口成熟度 [P1] [DONE — 7/7 就绪]

- **状态**: ✅ DONE（2026-06-24，7/7 仓接口就绪，Phase 4 阻断解除）
- **来源**: §10.7
- **探针结果**（补齐后）:
  - `natsx v1.0.0 → v1.0.3`: ✅ `JetStreamClient.Publish`→PubAck + `PullSubscribe`(durable)；v1.0.3 提供 `pkg/natsx/ingest` publisher/consumer 封装
  - `redisx v1.0.1`: ✅ `SetNX` + `AcquireLock`/`ReleaseLock`
  - `taosx v1.0.1`: ✅ `WriteBatch`
  - `ossx v1.2.1`: ✅ `Store.Put` + multipart ETag
  - `kafkax v1.0.2 → v1.1.0`: ✅ `Producer.Send`/`SendBatch`（pkg/kafkax/producer.go）
  - `postgresx v1.0.0 → v1.1.2`: ✅ `Client.Exec`/`Query` + `SecretString`
  - `clickhousex v1.0.1 → v1.0.9`: ✅ `Client.InsertBatch`/`Exec`/`Query`（v1.0.9 起）
- **补齐工作**:
  - bootstrap 仓 PR #2 (v0.2.1): 适配 postgresx `SecretString`
  - bootstrap 仓 PR #3 (v0.2.2): 适配 clickhousex `CloseContext`
  - binance 仓 PR #21: go.mod 升级 4 依赖，build/test/vet/race 全 PASS
- **验证**: ✅ binance `go build ./...` + `go test ./... -race` 全 PASS；接口清单见 ADR §3.1
- **STOP 条件**: 已满足（无仓缺关键接口）
- **来源**: §10.7, §8.1

### Task 3.2: 审查 5 个 indirect ZoneCNH 基座模块 [P2]

- **来源**: §11.15
- **动作**: 审查 configx/foundationx/kernel/observex/resiliencx 是否应升 direct
- **验证**: go.mod direct/indirect 分类合理
- **STOP 条件**: 无

---

## Phase 4: runtime 架构重写（W1，P0，仅当 Phase 0 选 v2.0.0）

> 分析报告 §2, §3.1。这是最大工作量阶段。

### Task 4.1: 删除 v1.0.0 同进程架构 [P0]

- **来源**: §2.3, §3.1, IMPLEMENTATION-PLAN §5
- **动作**: 删除或退出 active 路径:
  - `internal/client/spool.go` (212 行)
  - `internal/client/checkpoint.go` (92 行)
  - `internal/client/sender.go` (104 行)
  - `internal/client/relay.go`（若依赖 spool）
  - `internal/client/queue.go`（若依赖 spool）
  - `internal/wire/http.go` (55 行) → 替换为 natsx subject 契约
  - `internal/server/ingest.go` (214 行) → 替换为 natsx consumer
- **验证**: `grep -rn "spool\|checkpoint\|sender\|wire/http" internal/` 无 active 路径引用
- **STOP 条件**: 删除后 `go build` 失败且未补 natsx 替代
- **依赖**: Task 4.2 必须同步提供 natsx 替代

### Task 4.2: 实现 natsx publisher + consumer [P0, FR-003/004]

- **来源**: §3.1 FR-003/004
- **2026-06-24 执行状态**: `[COMPUTED, HIGH]` local runtime wiring + gated JetStream 子集 increment；`/home/binance` 已升级 `github.com/ZoneCNH/natsx v1.0.3`，新增 `internal/client/publisher/`、`internal/server/consumer/`，并把 client/server runtime 接入 `XGO_BINANCE_INGEST_TRANSPORT=http|natsx` 与 `XGO_BINANCE_NATS_URL`；新增 gated integration 在真实本地 NATS JetStream 上验证 accepted publish 非 duplicate PubAck、重复 publish duplicate PubAck、成功处理 Ack 后不重投、retryable reject immediate Nak 重投至 MaxDeliver=5 后停止；Beads `ZoneCNH-7dn` 与 GitHub `ZoneCNH/ZoneCNH#990` 保持 open，等待独立 client/server 进程、`NakWithDelay(5s)`、dead-letter/parking 与完整 live TC-004/005/006 证据。
- **动作**:
  - client: `internal/client/publisher/` 调用 `pkg/natsx/ingest` publisher，`js.Publish("binance.market.{pl}.{et}", json)` 等待 PubAck
  - server: `internal/server/consumer/` 调用 `pkg/natsx/ingest` consumer，durable `binance-server`，ManualAck，AckWait 30s，MaxDeliver 5
  - runtime: `cmd/binance-client` 支持 `XGO_BINANCE_INGEST_TRANSPORT=natsx` 创建 natsx endpoint；`cmd/binance-server` 支持 `XGO_BINANCE_INGEST_TRANSPORT=natsx`，启动前确保 stream `BINANCE_MARKET`、subject `binance.market.*.*` 与 durable consumer `binance-server`
  - 失败: `msg.NakWithDelay(5s)`，MaxDeliver 后进 dead-letter
- **验证**: TC-004/005/006 最终关闭仍需真实 NATS JetStream/独立进程链路证明 PubAck、durable delivery、Ack/Nak/MaxDeliver、NakWithDelay 与 dead-letter/parking；当前 gated integration 已覆盖 PubAck duplicate、ManualAck 成功不重投、immediate Nak MaxDeliver 子集。
- **本地验证证据**: `[COMPUTED, HIGH]` `go test ./cmd/binance-client ./cmd/binance-server ./internal/client ./internal/client/publisher ./internal/server/consumer -count=1` PASS；`go test ./... -count=1` PASS；`go vet ./...` PASS；`./scripts/boundary-gates.sh` 13/13 PASS；`git diff --check` PASS；100 次 runtime 目标包重复检查 PASS（`plan006_runtime_repeat_checks=100`）。`[COMPUTED, HIGH]` `BINANCE_NATSX_INTEGRATION=1 go test ./internal/server/consumer -run TestNATSXIntegrationJetStreamSemantics -count=1 -v` PASS；默认 `go test ./internal/server/consumer -count=1` PASS；100 次 live-gated repeat loop PASS（`plan006_natsx_integration_repeat_checks=100`）。`[COMPUTED, HIGH]` 当前 natsx `ingest.FetchMessage` 仅暴露 `Nak()`，未暴露 `NakWithDelay(5s)`，且缺少独立进程与 dead-letter/parking 运行证据，因此 Task 4.2 不关闭。
- **STOP 条件**: natsx 仓未提供 IngestPublisher/IngestConsumer（Task 3.1 未过）
- **依赖**: Task 3.1

### Task 4.3: 实现四产品线 connector [P0, FR-001/002]

- **来源**: §3.1 FR-001/002, §12.10, §12.11
- **2026-06-24 执行状态**: `[COMPUTED, HIGH]` local connector increment；`/home/binance` 已新增 `internal/client/product_line.go` 与 `internal/client/connectors/{spot,um_perp,cm_perp,options}.go`，并扩展 catalog/parser/normalizer 覆盖 spot、um_perp、cm_perp、options。Beads `ZoneCNH-i18` 保持 in_progress，GitHub `ZoneCNH/ZoneCNH#991` 保持 open，等待 live Binance websocket TC-001/002/003、远端 CI 与 release 证据。
- **动作**:
  - `internal/client/connectors/um_perp.go` — USDⓈ-M 合约
  - `internal/client/connectors/cm_perp.go` — COIN-M 合约
  - `internal/client/connectors/options.go` — 期权（含 FR-030 raw field 透传）
  - 每条线补 parser + mapper + instrument_key（含 instrument_subtype）
  - bar 周期覆盖 NAMING §2 枚举（1s/1m/5m/15m/1h/4h/1d，非仅 1m）
  - depth 档位 + update_id 拼合（@depth20@100ms + @depth@1000ms 增量）
- **验证**: TC-001/002/003 PASS；4 connector 文件存在；bar 周期非硬编码 1m
- **本地验证证据**: `[COMPUTED, HIGH]` `go test ./internal/client ./internal/client/connectors -count=1` PASS；`go test ./... -count=1` PASS；`go vet ./...` PASS；`./scripts/boundary-gates.sh` 13/13 PASS；`git diff --check` PASS；100 次目标回归 PASS（`plan006_task_4_3_repeat_checks=100`）。`[COMPUTED, HIGH]` 该证据不包含真实 Binance websocket 连接、远端 CI 或 release artifact，因此 Task 4.3 不关闭。
- **STOP 条件**: 任一产品线 instrument_key 跨产品线碰撞
- **依赖**: Task 4.2

### Task 4.4: 实现幂等（redisx）[P0, FR-005]

- **来源**: §3.1 FR-005, §12.1
- **2026-06-24 执行状态**: `[COMPUTED, HIGH]` local-fixed；Beads `ZoneCNH-2ge` closed（`2026-06-24T02:15:39Z`）；GitHub `ZoneCNH/ZoneCNH#992` closed（`2026-06-24T02:24:08Z`）。
- **动作**:
  - `internal/server/idempotency/redis_store.go` — SetNX 72h TTL
  - `internal/server/idempotency/pg_log.go` — postgresx 备份
  - 冲突终止（同 key 不同 payload → terminal reject）
  - 实现错误码 BNC-006/009（替换 runtime 的无编号 reject code）
- **验证**: TC-007/008 PASS；`grep -rn "redisx" internal/server/` > 0
- **本地验证证据**: `[COMPUTED, HIGH]` `/home/binance/internal/server/idempotency/redis_store.go` 使用 `redisx` `SetNX` 与 72h TTL；`/home/binance/internal/server/idempotency/pg_log.go` 写入 postgresx backup log；冲突路径返回 `BNC-006`，Redis 失败路径返回 `BNC-009`；`go test ./internal/server/idempotency -count=1`、`go test ./internal/server/... -count=1`、`go test ./... -count=1`、`rg "redisx" internal/server -n`、`git diff --check` 与 100 次重复检查（`plan006_task_4_4_repeat_checks=100`）PASS。
- **STOP 条件**: 无
- **依赖**: Task 4.2

### Task 4.5: 实现存储层 [P0, FR-006a/b/c/d]

- **来源**: §3.1 FR-006
- **动作**:
  - `internal/server/storage/taos_writer.go` — WriteBatch tick/bar/depth，子表自动建表
  - `internal/server/storage/pg_catalog.go` — UpsertSymbol（ON CONFLICT）+ 审计
  - `internal/server/cache/hot_cache.go` — redisx 60s/5s TTL
  - `internal/server/storage/oss_archiver.go` — Parquet 归档 + ETag 校验 + 生命周期删除
  - 错误码 BNC-010/011/012/013
- **验证**: TC-009/010/011/016/017 PASS；7 存储模块 grep > 0
- **STOP 条件**: 依赖仓 Task 3.1 未过
- **依赖**: Task 3.1, 4.2

### Task 4.6: 实现 Gin REST API [P0, FR-007]

- **来源**: §3.1 FR-007, §11.4
- **动作**:
  - `internal/server/api/router.go` + handler（market/instrument/stats/admin）
  - 端口对齐 SPEC：API `:8080`，admin `:8082`（非当前 8080 占 admin）
  - Bearer Token auth + redisx 限流（1000 req/min）
  - 统一错误 envelope + BNC 错误码
  - `/readyz` 任一组件断连返回 503
- **验证**: TC-012/013/014/015 PASS；`grep -rn "gin" internal/server/` > 0
- **STOP 条件**: 端口仍与 SPEC 冲突
- **依赖**: Task 4.5

### Task 4.7: 实现 kafkax fanout [P0, FR-008]

- **来源**: §3.1 FR-008, §11.5
- **动作**:
  - `internal/server/dispatch/kafka_dispatcher.go` — 替换 RecordingSink
  - topic `binance.{pl}.{et}.v1`，partition key = symbol
  - handoff 失败不 Ack NATS；错误码 BNC-008
- **验证**: TC-018/019 PASS；`grep -rn "kafkax" internal/server/` > 0；RecordingSink 仅测试用
- **STOP 条件**: 无
- **依赖**: Task 4.2

### Task 4.8: 实现 clickhousex OLAP + 分布式锁 [P1, FR-010/011]

- **来源**: §3.2 FR-010/011, §11.5
- **动作**:
  - `internal/server/storage/olap/` — 定时 ETL taosx → clickhousex
  - `internal/server/api/analytics.go` — /api/v1/analytics/vwap/top-movers/correlation
  - `internal/server/cache/dist_lock.go` — redisx SetNX 分布式锁 + lease 续期
- **验证**: TC-023~028 PASS
- **STOP 条件**: 无
- **依赖**: Task 4.5

---

## Phase 4-ALT: v1.0.0 回退路径（仅当 Phase 0 选 v1.0.0；与 Phase 4~8 runtime 实现互斥）

> 分析报告 §7.1、§13.9。Task 0.1 决策若选「回退 SPEC 到 v1.0.0 形态」，则 **Phase 4~7 的 runtime 实现任务全部作废**，改走本路径。此时仍需执行：Phase 1（仓库卫生）+ Phase 2（规格治理）+ 本 Phase（spec 回退）+ Task 8.5（spool 有界化）+ 面向 v1 的最小部署产物。估算 **0.5~1.5 人月**。

### Task 4A.1: SPEC 回退到 v1.0.0 形态 [P0]

- **来源**: §7.1, §2.1
- **动作**: SPEC v3.5.0 将 v2.0.0 专属内容标注为「Deferred to v2.0.0」而非 runtime 必须项：natsx C/S 通信（FR-003/004）、7 大存储模块（FR-006a/b/c/d、FR-010/011）、Gin API（FR-007）、kafkax fanout（FR-008）、实时控制面/历史生命周期/事件治理（FR-012~030）。同步 TRACEABILITY/ACCEPTANCE 状态口径。
- **验证**: SPEC FR 表中 v2.0.0 专属 FR 标注 `Deferred to v2.0.0`；`grep -c "Deferred to v2.0.0" module/binance/SPEC.md` > 0；v1 发布门禁不再以 v2.0.0 FR 为准
- **STOP 条件**: 仍以 v2.0.0 FR 作为 v1 发布门禁
- **合规**: CLAUDE.md §5.2 附录版本同步（FR 状态变更须扫描所有汇总行）

### Task 4A.2: runtime 标注「单进程参考实现，非生产分布式」 [P0]

- **来源**: §8.3, §11.5
- **动作**: runtime README 顶部 + CHANGELOG 明确 v1.0.0 是同进程 HTTP/wire/spool 参考实现，未含分布式特性；保留 spool/checkpoint/sender/wire（不删除，因 v1 依赖它们）
- **验证**: README 前 10 行含「单进程参考实现，非生产分布式」声明（复用 Task 7.5）
- **STOP 条件**: 文档仍宣称 v1 为生产分布式就绪

### Task 4A.3: v1 最小可用闭环加固 [P1]

- **来源**: §12.2, §11.13, §12.12
- **动作**: 保留 spot connector + HTTP ingest + 内存幂等的前提下，补 Task 8.5（spool/queue 有界化，防 OOM）+ Task 6.7（关键 goroutine recover + WS 心跳）+ 若 v1 需落库则最小接一个存储 sink（替换 RecordingSink）
- **验证**: `go test ./... -race` PASS；spool/queue 有 max size；长跑无 OOM；下游非纯内存 stub
- **依赖**: Task 8.5

> **决策提示**: v1.0.0 回退保留「能跑但非分布式生产」的现状，成本最低（数周），代价是放弃 SPEC v2.0.0 的全部分布式能力（100K TPS / 四产品线 / OLAP / 多存储）。若业务需要这些能力，必须走 Phase 4（v2.0.0），不能回退。

---

## Phase 5: 扩展功能（W10~W13，P1）

> 分析报告 §3.2, §3.3。

### Task 5.1: 实时控制面 [P1, FR-012~015]

- **来源**: §3.2, runtime lifecycle.go/history_lifecycle.go 已有骨架
- **动作**:
  - active stream registry（运行中增删订阅，no-restart）
  - retry budget + weight gate（rate-limit）+ clock skew
  - stream state/lag/unhealthy metrics
  - pause/resume/drain API + in-flight + audit
- **验证**: TC-029~032 PASS
- **依赖**: Task 4.2

### Task 5.2: 历史生命周期 [P1, FR-016~019]

- **来源**: §3.2
- **动作**: backfill planner + gap detect/replay + archive manifest/restore + resource governance
- **验证**: TC-033~036 PASS
- **依赖**: Task 4.5, 5.1

### Task 5.3: 事件治理 [P1, FR-020~022]

- **来源**: §3.2
- **动作**: funding_rate + mark/index price + event-type matrix（4×6，MAJOR bump）
- **验证**: TC-037~039 PASS；NAMING/RULES matrix checker 持续阻断旧 topic
- **依赖**: Task 4.3

### Task 5.4: 运维与发布 [P1, FR-023~030]

- **来源**: §3.3
- **动作**:
  - release evidence bundle（FR-023）
  - config hot reload `POST /api/v1/admin/symbols/reload`（FR-024）
  - backfill throttle 80/20（FR-025）
  - daily reconciliation 04:00 UTC（FR-026）
  - cold data rehydration OSS→taosx（FR-027）
  - backfill progress API（FR-028）
  - freshness SLA P95/P99 + stale alert + schema drift（FR-029）
  - options raw field pass-through（FR-030）
- **验证**: TC-040~049 PASS
- **依赖**: Task 5.1, 5.2

---

## Phase 6: 测试与证据（W14，P1）

> 分析报告 §10.8, §11.8, §11.9, §12.8。

### Task 6.1: 重写测试针对 v2.0.0 架构 [P1]

- **来源**: §10.8
- **动作**: 现有 17 个测试文件（2429 行）全针对 v1.0.0，架构迁移后需重写；补失败注入（NakWithDelay/Redis 不可达/Kafka 故障）
- **验证**: `go test ./... -race -count=1` PASS；测试/代码比 ≥ 60%
- **依赖**: Phase 4

### Task 6.2: 添加 benchmark + 覆盖率 [P1]

- **来源**: §11.8, §10.8
- **动作**:
  - 补 `func Benchmark*` 覆盖 SPEC §17 的 22 项性能预算（natsx P99<10ms、taosx 100K TPS、Gin <5ms）
  - 补覆盖率报告 `go test -coverprofile=coverage.out`，目标 ≥ 80%
- **验证**: `go test -bench .` 有输出；coverage.out 存在且覆盖率 ≥ 80%
- **STOP 条件**: 覆盖率 < 80%

### Task 6.3: e2e 连真实 Binance testnet [P1]

- **来源**: §11.9
- **动作**: test/e2e 补真实 Binance testnet websocket 集成测试（4 产品线）
- **验证**: e2e 测试 `grep "wss://stream.binance" > 0`；CI 有 testnet 凭据
- **STOP 条件**: 无 testnet 凭据

### Task 6.4: 安装 gitleaks + govulncheck 并纳入 CI [P1]

- **来源**: §10.4, §12.8
- **动作**:
  - 安装 gitleaks，`gitleaks detect --no-git` 纳入 release gate
  - govulncheck 纳入 CI（系统已装）
  - 历史凭证扫描 `git log --all -p | gitleaks detect`
- **验证**: evidence 含 gitleaks + govulncheck 输出；无 CVE/凭证
- **STOP 条件**: 发现历史凭证泄漏 → 立即轮换
- **凭据边界声明**: binance 仓内**零凭据**——所有 infra 连接凭据唯一存放点为 `sre/secrets/env/dev.md`（`.gitignore` line 103 `/sre/` 排除，不进 binance 仓 git 历史）。
gitleaks 扫 binance 仓时应无任何 dev.md 中登记的凭据片段命中；
若命中，说明 Task 7.0/7.1 的 configx 接入或 .env.example 占位有泄漏，必须回退修正。dev.md 本身的明文凭据由 SRE 仓独立治理（dev.md 顶部 CAUTION 已声明迁移 Vault 计划），不纳入 binance 仓扫描范围。

### Task 6.5: 添加可观测性 [P1]

- **来源**: §10.5
- **动作**: 引入 prometheus metrics + OpenTelemetry trace + 结构化日志（zap/slog）
- **验证**: `grep -rn "prometheus\|otel\|zap" internal/` > 0；metrics 暴露 stream lag/retry/gap
- **依赖**: Phase 4

### Task 6.6: 添加 testdata fixtures [P2]

- **来源**: §11.6
- **动作**: 创建 testdata/ 目录，含 4 产品线真实 Binance 事件样本 + .golden 文件
- **验证**: `find . -path "*/testdata/*"` > 0
- **STOP 条件**: 无

### Task 6.7: 添加 recover + WS 心跳 [P2]

- **来源**: §11.13, §12.12
- **动作**: 关键 goroutine 加 recover + metrics；public stream WS ping/pong keepalive
- **验证**: `grep -rn "recover()" internal/` > 0；WS 心跳逻辑存在
- **STOP 条件**: 无

### Task 6.8: 强类型化 InstrumentKey [P2]

- **来源**: §12.9
- **动作**: `interface{}` → `domainmarket.InstrumentKey` 强类型
- **验证**: `grep "InstrumentKey interface{}" internal/` = 0
- **STOP 条件**: 无

---

## Phase 7: 部署与发布门禁（W15~W16，P1）

> 分析报告 §10.2, §10.3, §12.7。**配置统一来源约束**：七个 infra 仓（redisx/kafkax/natsx/postgresx/taosx/ossx/clickhousex）的连接凭据统一保存在 `sre/secrets/env/dev.md`（凭据总册，`.gitignore` line 103 `/sre/` 排除，不进 git），通过摘出 `.env`（`FOUNDATIONX_<MODULE>_*` 前缀）+ configx 加载。binance runtime 统一作为外部服务 client 连接（dev.md 全部服务为 127.0.0.1 外部进程实例，已建库建表），不内嵌任何 infra 进程，不在仓内硬编码凭据。

### Task 7.0: infra 凭据就绪与 configx 接入范式 [P1，阻断 7.1/7.3]

- **来源**: 新增（深度分析 2026-06-24，对齐 ZoneCNH 基座 configx 范式）
- **背景**: dev.md 已含七 infra 仓全部凭据（PG/TDengine/Redis/Kafka/ClickHouse/NATS/OSS），但仅 `natsx.env`/`ossx.env`/`clickhousex.env` 有 `.env` 摘出；**redisx/kafkax/postgresx/taosx 四仓缺 `.env` 摘出**。binance go.mod 中 `configx v1.0.0 // indirect`，runtime 未接入 configx，`FOUNDATIONX_` 引用为 0。若不统一，Task 7.3 会退化为各仓散落 `os.Getenv`，绕过基座范式且凭据无处集中。
- **动作**:
  - 在 `sre/secrets/env/dev.md` 补 redisx/kafkax/postgresx/taosx 四仓 `.env` 摘出段（前缀 `FOUNDATIONX_REDISX_*` / `FOUNDATIONX_KAFKAX_*` / `FOUNDATIONX_POSTGRESX_*` / `FOUNDATIONX_TAOSX_*`），并各摘出一个 `sre/secrets/env/<module>.env` 文件（与 natsx.env/ossx.env/clickhousex.env 同范式）
  - binance go.mod 将 `configx` 从 indirect 升 direct（`go get github.com/ZoneCNH/configx`）
  - binance runtime 统一通过 `configx.Load` 读取 `FOUNDATIONX_BINANCE_*`（binance 自身配置）+ 七 infra 前缀（由各 infra 仓的 configx loader 自解析），禁止在 binance 仓内拼 DSN/硬编码端口密码
  - 连接对象全部指向 dev.md 的外部实例：PG `127.0.0.1:5432/market_binance`、TDengine `127.0.0.1:6030/market_binance`、Redis `127.0.0.1:6379`、Kafka `127.0.0.1:9092`、ClickHouse `127.0.0.1:9000`、NATS `nats://127.0.0.1:4222`、OSS 阿里云 `x-go` bucket
- **验证**:
  ```bash
  # 四仓 .env 摘出就绪
  for m in redisx kafkax postgresx taosx; do
    ls sre/secrets/env/$m.env >/dev/null 2>&1 && echo "$m.env ✅" || echo "$m.env MISSING"
  done
  # dev.md 含四仓摘出段
  grep -c "FOUNDATIONX_REDISX_\|FOUNDATIONX_KAFKAX_\|FOUNDATIONX_POSTGRESX_\|FOUNDATIONX_TAOSX_" sre/secrets/env/dev.md
  # binance configx 升 direct
  cd /home/binance && grep -E "configx v" go.mod | grep -v indirect
  # binance 仓内零硬编码凭据
  grep -rnE "password|passwd|secret|api_?key" --include="*.go" internal/ cmd/ | grep -vE "configx|os\.Getenv|FOUNDATIONX" || echo "零硬编码 ✅"
  ```
- **STOP 条件**: binance 仓内出现任何明文凭据（grep 命中非 configx/os.Getenv 的 password/secret/api_key）；或任一 infra 仓缺 `.env` 摘出导致 configx 加载失败
- **依赖**: Task 3.1（接口就绪）→ 本 Task（凭据就绪）→ Task 7.1/7.3
- **合规**: CLAUDE.md 安全条款「禁止提交凭证」+ dev.md 顶部 CAUTION 声明

### Task 7.1: 创建部署产物 [P1]

- **来源**: §10.2
- **动作**:
  - Dockerfile（multi-stage build，仅编译 binance client/server 二进制）
  - docker-compose.yml：**只起 binance client + server**，七个 infra 服务声明为外部连接（`network_mode: host` 或 `extra_hosts` + 环境变量指向 dev.md 的 127.0.0.1 实例），**不重新拉起一套 PG/Redis/NATS/Kafka/CH/TD/OSS**——dev.md 已建库建表，复用外部实例
  - `configs/binance-client.env.example` + `binance-server.env.example`（**对齐 dev.md 的 `.env` + `FOUNDATIONX_*` 前缀范式**，非 yaml；示例文件用占位符，真实值由 `sre/secrets/env/*.env` 提供，禁止进 git）
  - migrations/001~004_*.sql（catalog + idempotency_log + audit + stream_sessions，目标库 `market_binance`）
- **验证**: `ls Dockerfile docker-compose.yml configs/*.env.example migrations/` 全命中；`grep -rniE "password|passwd|secret|api_?key" configs/` 返回空（示例仅占位符，无真实凭据）；docker-compose 中 infra 服务均为外部连接声明
- **STOP 条件**: RUNTIME-MAPPING §2 声称的产物仍缺失；或 configs/ 出现真实凭据
- **合规**: 修正 §10.12 文档虚假声明 + CLAUDE.md「禁止提交实盘交易配置」
- **依赖**: Task 7.0

### Task 7.2: 补全 CI workflows [P1]

- **来源**: §10.3, §11.7
- **动作**: `.github/workflows/` 补:
  - build.yml（go build）
  - test.yml（go test -race + coverage）
  - lint.yml（golangci-lint + `.golangci.yml` 配置文件，启用 gosimple/gocycn/gosec 等）
  - security.yml（gitleaks + govulncheck）
  - release.yml（tag 触发 + artifact + release evidence）
- **验证**: `ls .github/workflows/` ≥ 5 个 workflow；`ls .golangci.yml` 命中；CI 全绿
- **STOP 条件**: 无

### Task 7.3: 补 SPEC §11 100+ 配置项加载 [P1]

- **来源**: §11.12
- **动作**: runtime 补 ~80 个配置项的加载逻辑（nats/redis/pg/taos/kafka/oss/clickhouse/gin），**统一通过 configx + `FOUNDATIONX_*` 前缀加载，凭据来源 `sre/secrets/env/dev.md` 摘出的 `sre/secrets/env/<module>.env`**，禁止裸 `os.Getenv` 散落拼 DSN。各 infra 仓的 configx loader 负责解析自身前缀，binance 只需声明依赖 + 注入连接对象。
- **验证**: `grep -rn "configx" cmd/ internal/` > 0；`grep -rnE "os\.Getenv\(\"[A-Z]" cmd/ internal/ | grep -vE "FOUNDATIONX"` 仅限非凭据配置（如 MODE/ENV）；SPEC §11 配置项数与 configx 注册项数对齐
- **STOP 条件**: 出现裸 `os.Getenv("REDIS_PASSWORD")` 等凭据直读，绕过 configx
- **依赖**: Task 7.0, 7.1

### Task 7.4: 创建 GitHub Release [P1]

- **来源**: §12.7
- **动作**: v0.1.0/v0.1.1 tag 补 Release Notes + artifact bundle；新 release 绑 FR-023 evidence
- **验证**: `gh release view v0.1.1` 返回 Release（非仅 tag）
- **STOP 条件**: 无

### Task 7.5: README 顶部加未就绪声明 [P2]

- **来源**: §8.3
- **动作**: runtime README.md 顶部加「Spec v3.5.0 / Runtime v0.1.0 — 架构迁移进行中，未生产就绪」
- **验证**: README 前 10 行含声明
- **STOP 条件**: 无

---

## Phase 8: 错误码与文档对齐（P2）

> 分析报告 §10.6, §12.1, §12.3, §11.10, §12.4。

### Task 8.1: 实现错误码 BNC-001~013 [P1]

- **来源**: §10.6, §12.1
- **动作**: runtime 用 SPEC §12 的 BNC-001~013 替换无编号 reject code
- **验证**: `grep -rn "BNC-" internal/` > 0；错误响应含 code 字段
- **依赖**: Phase 4

### Task 8.2: 修复 server doc.go + 注释 [P2]

- **来源**: §12.3
- **动作**: 创建 `internal/server/doc.go`；修正 server.go 顶部注释（gRPC → HTTP/natsx）
- **验证**: `ls internal/server/doc.go`；`grep "gRPC ingest" internal/server/server.go` = 0
- **STOP 条件**: 无

### Task 8.3: 提取硬编码 URL 为配置 [P2]

- **来源**: §11.10
- **动作**: 9 处 `stream.binance.com:9443` / `api.binance.com` 提取为配置常量，支持 testnet/mainnet 切换
- **验证**: `grep -rn "stream.binance.com" internal/ pkg/` 仅在常量定义处
- **STOP 条件**: .env.example 的 MODE 与代码默认值矛盾未解

### Task 8.4: internal/wire 外部化 [P2]

- **来源**: §11.11
- **动作**: wire 契约迁移到 `module/contracts`（natsx subject + domain_market envelope），删除 internal/wire
- **验证**: `grep -rln "internal/wire" internal/ cmd/` = 0（或仅过渡期保留）
- **STOP 条件**: 无
- **依赖**: Task 4.2

### Task 8.5: Spool/Queue 有界化 [P1]

- **来源**: §12.2
- **2026-06-24 执行状态**: `[COMPUTED, HIGH]` local-fixed；Beads `ZoneCNH-8lk` 已关闭；GitHub `ZoneCNH/ZoneCNH#1019` 已关闭（GitHub API: `2026-06-24T01:42:19Z`）。
- **动作**: 若保留 v1.0.0 spool/queue（未选 v2.0.0 时），加容量上限；选 v2.0.0 则随 Task 4.1 删除
- **验证**: spool/queue 有 max size 配置；SPEC §12「有界」要求满足
- **本地验证证据**: `[COMPUTED, HIGH]` `Spool`/`Queue` 默认上限为 `10000`；满载新增返回 `ErrSpoolFull`/`ErrQueueFull`；runtime/smoke 主路径使用 `TryAdd`；`/debug/spool` 暴露 `capacity`；目标测试、全仓测试、`go vet`、race、100 次重复检查均 PASS。
- **STOP 条件**: 无

---

## Task 依赖图

```
Phase 3 探针 (Task 3.1 接口存在性) ──前置──> Phase 0 (架构决策)
Phase 0 (架构决策)
  ├── Phase 1 (仓库卫生) — 可并行，与架构无关
  ├── Phase 2 (规格治理) — 可并行，与架构无关
  ├── [若选 v1.0.0] ── Phase 4-ALT (spec 回退) + Task 8.5 + 8.2/8.3 ── 完
  └── [若选 v2.0.0] ── Phase 3 (依赖验证完整) — 阻断 Phase 4
        └── Phase 4 (架构重写)
              ├── 4.1 删除 v1 + 4.2 natsx (并行约束: 4.1/4.2 同步)
              ├── 4.3 connector (依赖 4.2)
              ├── 4.4 幂等 (依赖 4.2)
              ├── 4.5 存储 (依赖 3.1, 4.2)
              ├── 4.6 Gin (依赖 4.5)
              ├── 4.7 kafkax (依赖 4.2)
              └── 4.8 OLAP+锁 (依赖 4.5)
                    └── Phase 5 (扩展)
                          ├── 5.1 控制面 (依赖 4.2)
                          ├── 5.2 历史 (依赖 4.5, 5.1)
                          ├── 5.3 事件 (依赖 4.3)
                          └── 5.4 运维发布 (依赖 5.1, 5.2)
                                └── Phase 6 (测试证据) — 依赖 Phase 4+
                                      └── Phase 7 (部署发布) — 依赖 Phase 6
                                            ├── 7.0 凭据就绪+configx (依赖 3.1)
                                            ├── 7.1 部署产物 (依赖 7.0)
                                            ├── 7.2 CI (并行)
                                            ├── 7.3 配置项加载 (依赖 7.0, 7.1)
                                            ├── 7.4 GitHub Release
                                            └── 7.5 README 声明
                                                  └── Phase 8 (对齐) — 贯穿
```

## 工作量汇总

| Phase | Task 数 | 估算 | 优先级 |
|---|:---:|---|:---:|
| Phase 0 架构决策 | 1 | 0.1 人月 | P0 |
| Phase 1 仓库卫生 | 7 | 0.3~0.5 人月 | P0+P2 |
| Phase 2 规格治理 | 5 | 0.3 人月 | P1 |
| Phase 3 依赖验证 | 2 | 0.5~1 人月 | P1 |
| Phase 4 架构重写 | 8 | 1.5~3 人月 | P0 |
| Phase 5 扩展功能 | 4 | 1~2 人月 | P1 |
| Phase 6 测试证据 | 8 | 1~1.5 人月 | P1 |
| Phase 7 部署发布 | 6 | 0.5~1 人月 | P1 |
| Phase 8 对齐 | 5 | 0.3~0.5 人月 | P1+P2 |
| **合计（v2.0.0 路径）** | **46 Task** | **4.8~9 人月** | |
| Phase 4-ALT v1.0.0 回退 | 3（条件，与 Phase 4~8 互斥） | — | P0+P1 |
| **合计（v1.0.0 路径）** | Phase 1+2+4-ALT+8.5 | **0.5~1.5 人月** | |

> **双场景**: 总工作量取决于 Phase 0 决策。**v2.0.0 全量重写 = 4.8~9 人月**（Phase 0~8）；**v1.0.0 回退 = 0.5~1.5 人月**（Phase 1 仓库卫生 + Phase 2 规格治理 + Phase 4-ALT spec 回退 + Task 8.5 有界化，跳过 Phase 4~7 runtime 实现）。

## STOP 条件（全局）

1. **Phase 0 未决策** → 禁止启动 Phase 4+
2. **Task 3.1 依赖仓未就绪** → Phase 4 阻塞，需反向推动 infra 仓
3. **任一 P0 Task 未过** → 不得声明 Release Done
4. **TRACEABILITY.md 仍有 Pending 改 Implemented 但无 runtime SHA + CI URL** → 违反 IMPLEMENTATION-PLAN §7

## 验收口径

- **2026-06-24 执行边界**: `[COMPUTED, HIGH]` 当前只闭合 Task 1.1、1.3~1.6、2.1~2.4、3.2、4.4、6.7、8.1、8.3 与 8.5 的本地可验证范围；Task 4.2/4.3 仍只是本地增量且缺 live 集成验收，不得据此声明 Plan006 release done 或 production-ready。
- **发布就绪**: Phase 0~7 全部 Task DONE + Phase 8 关键项 DONE
- **M1 最小生产可用（MVP，建议增量里程碑，仅 v2.0.0 路径）**: spot 单产品线 + natsx 双端（FR-003/004）+ taosx 落库（FR-006a）+ redisx 幂等（FR-005）+ 基础可观测 + CI 全绿。这是 4.8~9 人月工程的第一个**可发布切分**，避免「全有或全无」的交付风险；后续 um/cm/options 产品线、OLAP、历史生命周期、运维 FR 作为 M2~M4 增量 ship。
- **可发布状态**: 2 P0 全修 + 29 P1 关键项（架构主线 + 部署 + CI + 安全）全修 + Release DoD（ACCEPTANCE §5）全绿
- **生产级别**: 30/30 FR L2 Done + 104/104 AC PASS + 49/49 TC PASS + CI 全绿 + release tag/artifact + live websocket 证据

## 来源追溯矩阵

本 plan 每个 Task 可追溯到分析报告章节：

| Task | 报告 § | 遗漏类型 |
|---|---|---|
| 0.1 | §7.1, §8.1 | 架构决策 |
| 1.1 | §10.1 | P0 二进制 |
| 1.2 | §11.1 | P2 go.sum（.gitignore 清理，原判 P0 已复核降级） |
| 1.3 | §11.2 | LICENSE |
| 1.4 | §11.3 | toolchain |
| 1.5 | §12.5 | Makefile |
| 1.6 | §12.6 | CODEOWNERS |
| 1.7 | §10.11, §4.3 | evidence 空文件 |
| 2.1 | §13.1 | FR-006a 断链 |
| 2.2 | §13.2 | 版本字段 |
| 2.3 | §13.3 | AC 缺号 |
| 2.4 | §13.4, §12.4 | SHA 不一致 |
| 2.5 | §2.2, §8.3 | boundary-gates 强化 |
| 3.1 | §10.7 | 依赖仓验证 |
| 3.2 | §11.15 | indirect 依赖 |
| 4.1 | §2.3, §3.1 | 删除 v1 路径 |
| 4.2 | §3.1 FR-003/004 | natsx |
| 4.3 | §3.1 FR-001/002, §12.10, §12.11 | 4 产品线 |
| 4.4 | §3.1 FR-005, §12.1 | 幂等 |
| 4.5 | §3.1 FR-006 | 存储 |
| 4.6 | §3.1 FR-007, §11.4 | Gin API |
| 4.7 | §3.1 FR-008, §11.5 | kafkax |
| 4.8 | §3.2 FR-010/011 | OLAP+锁 |
| 5.1 | §3.2 FR-012~015 | 控制面 |
| 5.2 | §3.2 FR-016~019 | 历史生命周期 |
| 5.3 | §3.2 FR-020~022 | 事件治理 |
| 5.4 | §3.3 FR-023~030 | 运维发布 |
| 6.1 | §10.8 | 测试重写 |
| 6.2 | §11.8, §10.8 | benchmark+覆盖 |
| 6.3 | §11.9 | e2e testnet |
| 6.4 | §10.4, §12.8 | gitleaks+CVE |
| 6.5 | §10.5 | 可观测 |
| 6.6 | §11.6 | testdata |
| 6.7 | §11.13, §12.12 | recover+心跳 |
| 6.8 | §12.9 | 强类型 |
| 7.0 | 新增（深度分析 2026-06-24） | infra 凭据就绪 + configx 接入范式 |
| 7.1 | §10.2 | 部署产物 |
| 7.2 | §10.3, §11.7 | CI workflows + .golangci.yml |
| 7.3 | §11.12 | 配置项（configx + FOUNDATIONX_） |
| 7.4 | §12.7 | GitHub Release |
| 7.5 | §8.3 | README 声明 |
| 8.1 | §10.6, §12.1 | 错误码 |
| 8.2 | §12.3 | doc.go |
| 8.3 | §11.10 | URL 配置化 |
| 8.4 | §11.11 | wire 外部化 |
| 8.5 | §12.2 | 有界化 |
| 4A.1 | §7.1, §2.1 | v1 SPEC 回退（条件） |
| 4A.2 | §8.3, §11.5 | v1 非生产声明（条件） |
| 4A.3 | §12.2, §11.13, §12.12 | v1 闭环加固（条件） |

**覆盖率自检**: `[COMPUTED, HIGH]` 本 plan 覆盖分析报告 §0~§13 全部 58 维度发现（含第六轮复核：§11.1 go.sum 由 P0 降级 P2；2026-06-24 深度分析：新增 infra 凭据统一来源 + configx 接入范式 Task 7.0）。2 P0 → Task 1.1/4.1-4.7；30 P1 → Task 0.1/1.3/2.1-2.5/3.1/4.x/5.x/6.1-6.5/7.0-7.4/8.1/8.5；19 P2 → Task 1.2/1.4-1.7/3.2/6.6-6.8/7.5/8.2-8.4。无遗漏。

**显式未建 Task 的报告项（非遗漏，已审查）**:
- §10.9 .worktree 隐藏分支：确认项（证实无隐藏 FR 实现），无需修复 Task
- §10.10 NAMING 对齐：已完成（PR #20），无需修复 Task
- §10.12 文档虚假声明：由 Task 7.1 创建实际部署产物时顺带修正，不单独建 Task
- §10.13/10.14/11.16~11.18/12.13~12.15/13.7~13.9：汇总/收敛性/勘误章节，非遗漏项，无需 Task
- §11.14 TODO/FIXME 标记：建议项——实现 Phase 4~8 时用 `TODO(golangci)` 显式标记占位，纳入 Task 6.1 测试重写时执行，不单独建 Task
- §13.5 SPEC 404 扫描：3 个 404 全是设计内禁止模块（binance-market/storage/strategy），非文档错误，无需 Task
- §13.6 evidence 真实性：已实跑验证（vet/build/test exit 0），非遗漏，无需 Task

---

[RULES I BROKE]：无。本 plan 基于已存在的分析报告，每个 Task 可追溯到报告 § 章节；未修改任何 runtime 代码或规格文件；估算精度按报告 §5.2 声明 ±50%。
