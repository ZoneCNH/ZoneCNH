# module/binance CHANGELOG

所有 notable 变更记录，按 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/) 格式维护。

- Doc-Version: v2.2.3
- Last-Updated: 2026-06-22
- Spec-Reference: `module/binance/SPEC.md` v2.2.3
- 治理规则：`module/binance/RULES.md` R9 文档存在性

---

## [v2.2.3] — 2026-06-22

### Changed
- TRACEABILITY FR-009 状态附 runtime SHA `bae80d6` + CI workflow URL（runtime PR ZoneCNH/binance#9 合并）
- ARCHITECTURE-DRIFT-WATCHLIST D8 风险级别 MEDIUM → LOW（CI 已自动化）
- 业务报告 §Runtime 核对结果 第 4 项证据升级为 runtime commit + CI workflow URL

### Removed (runtime 仓)
- runtime 仓 `internal/cs/` 目录（doc.go + types.go），满足 BR-005 No cs Package

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
- TRACEABILITY TC-005/021/022 → PASS（boundary gate 证据对齐）
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
