# module/binance CHANGELOG

所有 notable 变更记录，按 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/) 格式维护。

- Module-Version: v3.5.0
- Last-Updated: 2026-06-23
- Spec-Reference: `module/binance/SPEC.md` v3.5.0
- 治理规则：`module/binance/RULES.md` R9 文档存在性

---

## [Unreleased] — 2026-06-23

### Added
- `DEEP-ANALYSIS.md` 拆分为 `DEEP-ANALYSIS-ARCHIVE-architecture.md` + `DEEP-ANALYSIS-ARCHIVE-operations.md` + `DEEP-ANALYSIS-ARCHIVE-integration.md` 三个归档文件（GitHub #930）。

### Changed
- 记录 `/home/binance` 本地 runtime boundary evidence：SHA `71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`，`scripts/boundary-gates.sh` 10/10 PASS，`go build/test/race/vet`、`golangci-lint`、本地 smoke self-test PASS。
- 记录 runtime PR `ZoneCNH/binance#11`：merge commit `5a57a19aed3be5420135b8e05016da15faf094ed`，source commit `7873b795b13fc4b5a0fc4310300b6f196cca7532`，远端 `Boundary Gates (10 gates)` PASS；独立 `cmd/binance-client` + HTTP `/ingest` client/server 边界已证明。
- 将 `RUNTIME-MAPPING.md` 标为目标运行时映射而非完成声明，并补充 JetStream PubAck/ManualAck、durable natsx/storage/fanout/query 等未证明项；`cmd/binance-client` 只关闭 HTTP boundary 证据，不关闭 FR-003 publish/consume。
- 2026-06-23 round 2 证据刷新：重新运行 `/home/binance/scripts/boundary-gates.sh` 10/10 PASS；`go build`/`go vet`/`go test` 全部 PASS 于 SHA `71e2a6e8bb5591c43e8a2ebfff8c7645bf030786`；全部 9 个 issue 分支已合并至 origin/main。

### Reviewed
- PR-007a~g 分布式 runtime、远端 CI、release tag、live websocket 与外部依赖集成证据仍未闭合；本节不关闭 `ZoneCNH-n0s` / GitHub #923。
- **P2-2 SPEC §4 分布式约束（#930）**：DEEP-ANALYSIS.md §0 分布式约束已迁移至 `SPEC.md` §4 Goals（分布式 C/S 架构）与 FR-011（Distributed Coordinator Lock），SPEC 已明确独立进程、natsx 网络通信、禁止同进程调用等约束。无需额外迁移。
- **P2-3 binance-market 遗留引用（#930）**：全量扫描 `module/binance/*.md` 中 whitelist 外文件（client/SPEC.md、server/SPEC.md、RUNTIME-MAPPING.md、BOUNDARY-GATES.md、TRACEABILITY.md、ACCEPTANCE.md、IMPLEMENTATION-PLAN.md、README.md、FEATURES.md、client/README.md、server/README.md、tasks/*.md）的 `binance-market` 引用，全部为 BR-001 边界声明（"已移除 / 禁止恢复 / 禁止路径"）或 AC/TC 追踪元数据，无发现需压缩的冗余叙事。
- **P2-5 BOUNDARY-GATES.md 审查（#930）**：10 道 gate 完整覆盖 BR-001~BR-009 + go.mod 合规，每道 gate 有可执行关闭规则与 runtime 证据引用。无发现结构性缺口。Gate §2 No Legacy binance-market 关闭规则明确，与 RULES R1 豁免清单一致。

### Deferred
- **P2-4 commit coverage matrix（#930）**：binance runtime 仓约 50 个 preserve/stash commit 的覆盖率矩阵建立仍为开放任务。当前 `/home/binance` 仓库的 squash merge 策略已将 PR 级历史保留在 main 分支，但其对应 issue/AC 的精细映射尚未建立。建议待 FR-003~FR-030 runtime 实现推进后按需建立。

---

## [v3.5.0] — 2026-06-23

### Added
- FR-029 Data Quality & Freshness SLA：端到端 event_time→persist/fanout 延迟上限 + schema 漂移检测 + stale alert（AC-099~101, TC-047, ROOT-010）。SPEC §17 Performance Budget 补 3 项 freshness 指标（端到端 persist P99 < 200ms、fanout P99 < 300ms、stale alert 阈值 spot/um/cm 30s / options 60s）。
- FR-030 Options Chain Raw Field Pass-through：option chain 原始字段（strike/expiry/option_type/mark/IV）透传至下游，Greeks 派生归分析域（AC-102~104, TC-048/049, CLIENT-020）。

### 决策依据
- P2-2 数据质量 SLA：§17 原仅单环节延迟，缺端到端 freshness 与断流检测，补 FR-029 + NFR。
- P2-3 历史回填：FR-016/017/019/025/027/028 已完整覆盖（backfill planner/gap replay/resource governance/throttle/rehydration/progress API），**无缺口，不新增 FR**。
- P2-4 Options Greeks：Greeks/IV 派生属分析域职责，本模块只需透传 option chain 原始字段，补 FR-030。

### 触发依据
- R3 / CONSTITUTION §10.4：FR-029/030 契约登记 + §17 NFR 扩展属接口契约演进 → Spec-Version MINOR bump v3.4.0 → v3.5.0。FR-029/030 仅追溯登记（与 FR-012~028 同层级），WHEN/THEN 主体待 promote 时补。

---

## [v3.4.0] — 2026-06-23

### Added
- SPEC §9 Instrument Identity 新增 `instrument_subtype` 维度（perpetual/delivery），仅 um_perp/cm_perp 适用；FR-002 补交割合约 WHEN/THEN（`instrument_subtype=delivery` + 非零 expiry 与永续产出不同 InstrumentKey，共享 subject 不拆分订阅）。
- NAMING §1.1 新增 `instrument_subtype` canonical 维度表 + 承载规则（不进入 subject/topic/path，只进入 InstrumentKey identity 与 TDengine tag / Redis key identity 段）。
- RULES R2 补"交割合约承载"条款：禁止拆 product_line 破坏 4×6 矩阵。

### Changed
- NAMING §1 um_perp/cm_perp 语义注释从"永续"改为"合约（永续 + 交割）"，消除命名与可承载交割合约的语义张力。
- RULES R2 矩阵维度 4×4（16 组合）→ 4×6（24 组合），对齐 NAMING §2 已声明的 4×6 矩阵。
- NAMING §10 drift detection 增 `USDⓈ-M 永续|COIN-M 永续` 残留检测。

### 触发依据
- R3 / CONSTITUTION §10.4：FR-002 instrument identity 契约扩展（新增 instrument_subtype 维度 + WHEN/THEN）属接口契约演进 → Spec-Version MINOR bump v3.3.0 → v3.4.0。NAMING/RULES 矩阵维度与语义注释为文档治理，因依附契约变更同 PR 同步，Module-Version 跟随 root SPEC。

---

## [v3.3.0] — 2026-06-23

### Changed
- 收紧 R3 bump 触发器：Spec-Version 只反映接口契约演进，排除文档治理变更（状态修正/错字/版本同步/issue 闭环/讨论稿/规则文案）。根因：v3.1.0/v3.3.0 把文档治理当契约 bump 导致版本号通胀。收紧后 spec 版本与 runtime 成熟度解耦。
- 版本号统一治理：字段名收敛为 `Spec-Version`（仅 root/client/server SPEC.md）/ `Module-Version`（所有治理文档）/ `Runtime-Version`（SPEC.md runtime 版本，原 `Version` 字段）。
- 废弃异名字段 `Doc-Version` / `Matrix-Version` / `Version`：RULES/NAMING/DATA-LIFECYCLE/STANDARD/WATCHLIST/CHANGELOG/IMPLEMENTATION-PLAN/TRACEABILITY 全部改用 `Module-Version`。
- 顶层治理文档 Module-Version 统一对齐 root SPEC Spec-Version（v3.3.0）；NAMING/RULES/DATA-LIFECYCLE/STANDARD/WATCHLIST 从游离版本号（v1.0.2/v2.1.0/v0.2.0/v0.1.1/v1.0.0）收敛到 v3.3.0。
- SPEC.md L10 `Version: v0.1.0` → `Runtime-Version: v0.1.0`（区分规格版本与 runtime 版本）；client/SPEC、server/SPEC 同步。
- server/TRACEABILITY.md 补建结构化版本字段（Module-Version + Spec-Reference），与 client/TRACEABILITY 对称；版本从散文 v2.1.1 对齐到 server/SPEC v2.2.0。

### Added
- RULES R6 从"仅 ACCEPTANCE"扩展为"全量版本统一"规则：字段名收敛 + 顶层版本号统一 + 子规格对称 + Spec-Reference 闭环。
- RULES R3 补充子规格 bump 时 TRACEABILITY 同步条款。
- check-binance-docs.sh 增项：顶层文档 Module-Version 全量校验 + 子规格 TRACEABILITY 对称校验 + 异名字段禁用检测。
- WATCHLIST D4 从"ACCEPTANCE 脱钩"升级为"模块版本号分裂与脱钩"全量监控点。

---

## [v3.2.0] — 2026-06-23

### Added
- fold DATA-LIFECYCLE §7 候选 FR 进 SPEC/TRACEABILITY/NAMING：新增 FR-025（Backfill Throttle & Priority）、FR-026（Daily Reconciliation Job）、FR-027（Cold Data Rehydration）、FR-028（Backfill Progress API）。
- TRACEABILITY 新增 AC-087~AC-098、TC-043~TC-046；FR 总数 24→28、TC 42→46、AC 86→98。
- NAMING §2.1 补 bar 订阅周期集（spot/um_perp/cm_perp = 1s/1m/5m/15m/1h/4h/1d；options = 1m/5m/1h/1d）。
- NAMING §3.1 + SPEC §9 补 control subjects（`binance.control.instruments.changed` / `binance.control.symbols.changed`）。
- SPEC §9 补 FR-015 depth 订阅档位表（@depth20@100ms + @depth@1000ms 增量 + update_id 拼合）。
- server/SPEC §7 新增 FR-025~FR-028 节。

### Changed
- root SPEC v3.1.0 → v3.3.0（MINOR，FR 接口新增）；server/SPEC v2.1.0 → v2.2.0（MINOR）。
- STATUS/README/ARCHITECTURE 三文档 binance 版本同步 v3.3.0。
- RULES R1 例外清单补 BR-001 边界声明豁免；R9 收录 STANDARD.md + DATA-LIFECYCLE.md。
- ACCEPTANCE/FEATURES 新增 L1/L2 状态口径分层图例（RULES R4）。

### Reviewed
- FR-025~028 全部 Pending：runtime 仓未实现，L2 状态默认 `Pending — 以 runtime 仓为准`。

---

## [v3.1.0] — 2026-06-22

### Added
- 将 root SPEC / TRACEABILITY 扩展到 FR-012..FR-024、AC-086、TC-042，记录 realtime control、historical lifecycle、event governance、release evidence 与 runtime hot reload 后续交付面。
- 在 TRACEABILITY 中登记 R2 governance matrix（4 product lines × 6 event types × 5 documents/checker anchors）。

### Changed
- README、ACCEPTANCE、FEATURES、IMPLEMENTATION-PLAN 与 root SPEC 版本同步到 v3.1.0。
- `RUNTIME-MAPPING.md` 管理端点口径从旧 `/api/v1/admin/catalog/reload` 统一为当前 runtime 已验证的 `POST /api/v1/admin/symbols/reload`。

### Reviewed
- 保留 FR-024 Pending：endpoint 单元证据已存在，但 active stream add/remove no-restart proof、live websocket、remote CI 与 release tag 仍未闭合。

---

## [v2.2.3] — 2026-06-22

### Changed
- Stage0–Stage2 文档治理基线收敛：ACCEPTANCE、FEATURES、IMPLEMENTATION-PLAN、TRACEABILITY 与 root SPEC v2.2.3 对齐
- Kafka topic 文档从旧式 `binance.market.{product_line}.{event_type}` 收敛到 `binance.{product_line}.{event_type}.v1`，保留 natsx subject 为 `binance.market.*`
- TRACEABILITY FR-009 状态附 runtime SHA `bae80d6` + CI workflow URL（runtime PR ZoneCNH/binance#9 合并）
- ARCHITECTURE-DRIFT-WATCHLIST D8 风险级别 MEDIUM → LOW（CI 已自动化）
- 业务报告 §Runtime 核对结果 第 4 项证据升级为 runtime commit + CI workflow URL

### Removed (runtime 仓)
- runtime 仓 `internal/cs/` 目录（doc.go + types.go），满足 BR-005 No cs Package

### Added
- 新建 `scripts/check-binance-docs.sh`，作为 Stage1 可执行文档治理检查
- 新建 `module/binance/DATA-LIFECYCLE.md`，记录 Stage2 lifecycle gap 与 FR-012..FR-024 草案
- 新建 `module/binance/STANDARD.md`，记录 FR-024 前置 runtime control 标准与证据门禁
- 新建 `docs/report/binance/INDEX.md`，收口报告索引与 Stage0–Stage2 gate 入口

### Reviewed
- 关闭 `DATA-LIFECYCLE.md` review checklist，确认 FR-012..FR-024 的落点、bump class、依赖顺序与 `STANDARD.md` 前置关系；该结论不修改 root SPEC，也不标记 Release DoD

### Added (runtime 仓)
- runtime 仓 `.github/workflows/boundary-gates.yml`（9 道 boundary gate 自动化），满足 RULES.md R10

---

## [v2.2.2] — 2026-06-22

### Added
- 新建 `CHANGELOG.md`（本文），对齐 Keep-a-Changelog 格式，满足 RULES.md R9 文档存在性
- 新建 `module/binance/NAMING.md`（命名 SSOT，4 产品线 × 4 event_type 对称矩阵）
- 新建 `module/binance/RULES.md`（R1-R10 治理规则，全部机器可检测）
- 新建 `module/binance/ARCHITECTURE-DRIFT-WATCHLIST.md`（D1-D8 漂移监控点）

### Changed
- ACCEPTANCE Module-Version v2.0.0 → v2.2.2（R6 同步）
- FEATURES Module-Version v2.0.0 → v2.2.2
- IMPLEMENTATION-PLAN Version v2.1.2 → v2.2.2

### Fixed
- 4 套不兼容命名（usdm_futures/coinm_futures/um_perp/cm_perp/futures_usdt/futures_coin）全部收敛到 `um_perp/cm_perp`

---

## [v2.2.1] — 2026-06-22

### Changed
- TRACEABILITY BR-001/002/003/005/006/007/008/009 → Implemented（boundary gate §2-§11 PASS）
- TRACEABILITY TC-020/021/022 → PASS（boundary gate 证据对齐）；TC-005 保持 Pending，等待 FR-003 独立进程 publish/consume 集成证据
- 业务报告 `docs/report/binance/business-types-coverage-20260622.md` §Runtime 核对建议 → §Runtime 核对结果（[INFERRED] → [COMPUTED][HIGH]）

### Fixed
- 归档 5 个 v2.0.0 前 task 到 `archive/`（R5 物理隔离）
- DEEP-ANALYSIS 归档到 `docs/report/binance/`

---

## [v2.2.0] — 2026-06-22

### Added
- `binance.market.cm_perp.depth` + `binance.market.options.depth` natsx subject（R2 4×4 对称矩阵缺口闭合）
- TASK-CLIENT-006 Scope 新增 depth/update events（Binance EOptions `<symbol>@depth1000` WebSocket stream）

### Changed
- 产品线命名收敛：所有 `usdm_futures` → `um_perp`、`coinm_futures` → `cm_perp`
- FR-001 状态 Partial → Pending（与 client/TRACEABILITY 同步，以 runtime 仓为准）

### Fixed
- 子规格版本不一致：client TRACEABILITY 引用 → client/SPEC v2.1.1，server TRACEABILITY 引用 → server/SPEC v2.1.0
- 报告归类：binance 深度分析报告移到 `docs/report/binance/` 子目录

---

## [v2.1.2] — 2026-06-22

### Added
- Boundary Enforcement（FR-009）TC-020~TC-022 CI gate 覆盖
- FR-007a（analytics API）、FR-010（clickhousex OLAP）、FR-011（分布式锁）

### Changed
- FR-006 拆分为 6a/6b/6c/6d（taosx/postgresx/redisx cache/ossx）
- 根 SPEC Config §11 从 14 项扩展至 100+ 项

---

## [v2.1.0] — 2026-06-21

### Added
- 七模块补全：natsx consumer + redisx 幂等 + taosx 时序 + postgresx 元数据 + kafkax fanout + ossx 归档 + Gin REST API
- BNC-009~013 错误码
- Performance Budget 从 8 项扩展至 20 项
- TC 从 22 条扩展至 28 条
- AC 从 35 条扩展至 47 条
- NFR 从 13 条扩展至 20 条

### Changed
- Subject 命名统一 um_perp/cm_perp

---

## [v2.0.0] — 2026-06-21

### Added
- natsx JetStream 分布式架构（Client → natsx → Server）
- Durable consumer `binance-server`（PubAck + ManualAck）
- redisx SetNX 幂等（TTL 72h）
- BOUNDARY-GATES.md 9 个 boundary gate
- 4 产品线 × 4 event_type 对称矩阵（SPEC §9 natsx subject 表）

### Removed
- gRPC bidi stream（替换为 natsx JetStream）
- `internal/cs` 同进程 C/S 桥接（违反 BR-005）
- binance-market 旧模块（统一到 client/server）
- client spool/checkpoint（natsx PubAck 替代）

### Changed
- 架构从同进程 C/S → 分布式 C/S（独立部署，natsx 网络通信）
- FR-003~006 重写，新增 FR-007~010
- BR-004~009 对齐 ManualAck/redisx/ossx/存储所有权
- NFR 删除 spool/gRPC 延迟，新增 natsx/taosx/Gin 预算

---

## [v1.4.0] — 2026-06-17

### Changed
- runtime 骨架落地，TRACEABILITY 实现状态 0% → 71%

---

## [v1.3.0] — 2026-06-17

### Changed
- 同步 SPEC v1.0.1 Status 晋升

---

## [v1.2.0] — 2026-06-17

### Changed
- BR-002/003 拆分，BR 总数 8 → 9

---

## [v1.1.0] — 2026-06-17

### Fixed
- FR/BR/AC 错位修复
- 新增 AC-021~023 边界强制

---

## [v1.0.0] — 2026-06-16

### Added
- 首次从零创建 §1-§7 标准追溯矩阵
- SPEC 23 节结构初始化
- client/server 双端架构决策
- 移除 `binance-market` 旧模块

---

## 版本对照

| 版本 | SPEC | TRACEABILITY | 关键变更 |
|------|------|-------------|----------|
| v3.3.0 | v3.3.0 | v3.3.0 | FR-012~FR-024 登记 + R2 120-cell matrix + symbols reload endpoint 口径 |
| v2.2.3 | v2.2.3 | v2.2.3 | runtime evidence + CI URL + topic/version drift guard |
| v2.2.2 | v2.2.2 | v2.2.2 | CHANGELOG 新建 + 版本号全量对齐 |
| v2.2.1 | v2.2.0 | v2.2.1 | Boundary gate 证据回填 |
| v2.2.0 | v2.2.0 | v2.2.0 | 命名收敛 + Options depth 补全 |
| v2.1.2 | v2.1.0 | v2.1.0 | 七模块补全 + 追溯链扩展 |
| v2.0.0 | v2.0.0 | v2.0.0 | natsx JetStream 分布式架构重写 |
| v1.0.0-v1.4.0 | v1.0.0 | v1.0.0-v1.4.0 | 早期演进 |

---

## 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-22 | v3.3.0 | root SPEC/TRACEABILITY/ACCEPTANCE/FEATURES/README/IMPLEMENTATION-PLAN/RUNTIME-MAPPING 同步到 v3.3.0 登记态 | ZoneCNH |
| 2026-06-22 | v2.2.2 | 新建 CHANGELOG + ACCEPTANCE/FEATURES/IMPLEMENTATION-PLAN 版本号同步到 v2.2.2 | ZoneCNH |
| 2026-06-22 | v2.2.1 | Boundary gate evidence 回填 + 5 个 v2.0.0 前 task 归档 | ZoneCNH |
| 2026-06-22 | v2.2.0 | 命名收敛 + Options/cm_perp depth 补全 + 状态口径修复 | ZoneCNH |
| 2026-06-21 | v2.1.0 | 七模块补全 + 追溯链扩展 | ZoneCNH |
| 2026-06-21 | v2.0.0 | natsx JetStream 分布式架构重写 | ZoneCNH |
| 2026-06-17 | v1.4.0 | runtime 骨架落地 | ZoneCNH |
| 2026-06-17 | v1.3.0 | SPEC v1.0.1 Status 同步 | ZoneCNH |
| 2026-06-17 | v1.2.0 | BR-002/003 拆分 | ZoneCNH |
| 2026-06-17 | v1.1.0 | FR/BR/AC 错位修复 + AC-021~023 边界强制 | ZoneCNH |
| 2026-06-16 | v1.0.0 | 首次创建 | ZoneCNH |
