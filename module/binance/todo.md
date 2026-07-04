# Binance 模块 TODO — 20 轮审查修复任务

> **更新日期**: 2026-07-04
> **来源**: 20 轮独立复现审查共识 (`REVIEW-20260704-20ROUND-CONSENSUS.md`) + DEEP-ANALYSIS 增量
> **修复计划**: `plans/binance/FIX-PLAN-20260704.md`
> **PR**: runtime [#425](https://github.com/ZoneCNH/binance/pull/425)（`edd7805`）+ docs [#1668](https://github.com/ZoneCNH/ZoneCNH/pull/1668)（`59907845`）
> **基线**: runtime `main@edd7805`（fix/20round-review-consensus branch）

---

## P0 — 阻断发布（必须修复）

- [x] **N2**: 修复 NATS subject 段数不匹配（consumer.go `binance.market.*.*` → `binance.market.>`）
  - 文件: `internal/server/consumer/consumer.go:22`
  - 状态: ✅ 已修复
- [x] **T0**: 修复 TRACEABILITY.md release_closeable 矛盾（YES → NO，因 PRG-006=Partial）
  - 文件: `module/binance/matrix/TRACEABILITY.md` + 全量文档同步
  - 状态: ✅ 已修复（12 个文件全量修正）
- [x] **SPEC-PRG**: 修复 SPEC.md "PRG-001~007 全 PASS" 矛盾
  - 文件: `module/binance/spec/SPEC.md` + ACCEPTANCE.md + FEATURES.md
  - 状态: ✅ 已修复

## P1 — 阻断发布（需专项开发）

- [x] **N4**: 接入 UM/CM/Options connector 到主运行时启动路径
  - 文件: `internal/client/runtime.go`
  - 状态: ✅ 已修复（新增 EnableUMPerp/CMPerp/Options 配置 + fan-in 合并 events）
- [x] **N6**: TaosWriter 支持 funding_rate/mark_price 事件类型
  - 文件: `internal/server/storage/taos_writer.go`
  - 状态: ✅ 已修复（新增 fundingRatePoint() + markPricePoint() + st_funding_rate/st_mark_price 表）
- [x] **N7**: retention 去硬编码 ProductLine:"spot"，支持全产品线
  - 文件: `internal/server/assembly/storage.go`
  - 状态: ✅ 已修复（遍历 ["spot","um_perp","cm_perp","options"]）
- [x] **ORDBK**: depth 完整档位存储（不再退化为 top-of-book tick）
  - 文件: `internal/server/storage/taos_writer.go`
  - 状态: ✅ 已修复（新增 depthPoint() + st_depth 表，保留 bids_json/asks_json 完整档位）
- [x] **TEST1**: 修复 internal/client 测试超时（lifecycle worker goroutine 泄漏）
  - 文件: `internal/client/final_coverage_test.go`
  - 状态: ✅ 已修复（context.Background() → WithTimeout(10s)）
- [x] **SchemaVersion**: DefaultStandaloneConfig 缺 SchemaVersion 字段
  - 文件: `internal/client/runtime.go:111`
  - 状态: ✅ 已修复（补 wire.DefaultSchemaVersion）

## P2 — 业务完整性（非阻断）

- [x] **N3**: ACK-before-persist 时序在 SLA 文档显式声明
  - 文件: `module/binance/gate/OBSERVABILITY.md` §6
  - 状态: ✅ 已修复（新增 ACK 时序语义表 + SLA 声明）
- [x] **N5**: OLAP 10min 内存窗口在文档标注为 "内存窗口模式"
  - 文件: `internal/server/assembly/olap_source.go` 注释 + `module/binance/gate/OBSERVABILITY.md` §7
  - 状态: ✅ 已修复（代码注释 + 文档声明内存窗口限制）
- [x] **PRG7**: open issue 关闭或文档如实反映状态
  - GitHub: ZoneCNH/binance
  - 状态: ✅ 已修复（关闭 9 个已修复 issue：#365/#366/#367/#368/#372/#373/#375/#376/#401；剩余 27 个 open）

## P3 — 治理卫生

- [x] **DOC1**: 修复 404 链接引用（不存在的仓库）
  - 状态: ✅ 已确认（binance-market/binance-server 引用在 "Removed Legacy Module" 章节，为废弃文档非活跃引用）
- [x] **REG1**: 修复 registry.yaml maturity_ref 断链
  - 文件: `module/registry.yaml`
  - 状态: ✅ 已修复（maturity_ref → module/binance/goal/goal.md；spec_version v3.9.6→v3.9.8；latest_tag v0.11.0→v0.12.0）

---

## 已修复项（确认）

- [x] **N1**: main 分支编译失败 — `storageAssembly` 缺 `runtime` 字段 → 已修复（storage.go:313）
- [x] **GAP-E1**: client 直写 Postgres — `history_state_postgres.go` 已删除
- [x] **VER**: 版本号三方分裂 — 全部统一到 v3.9.8
- [x] **GM1**: RUNTIME-GAP-MATRIX 路径断链 — 已迁移至 `module/binance/matrix/RUNTIME-GAP-MATRIX.md`
- [x] **Boundary Gates**: 15/15 PASS

---

## 验收检查清单

- [x] `go build ./...` 无错误
- [x] `go test ./... -count=1 -timeout=180s` 全部 PASS（24/24 packages）
- [x] `bash scripts/boundary-gates.sh` 15/15 PASS
- [x] `grep "binance.market.>" internal/server/consumer/consumer.go` 命中
- [x] `grep "release_closeable: NO" module/binance/matrix/TRACEABILITY.md` 命中
- [x] `grep "PRG-001~007 全 PASS" module/binance/spec/SPEC.md` 无命中
- [x] `grep "NewUMPerpConnector\|NewCMPerpConnector\|NewOptionsConnector" internal/client/runtime.go` ≥3 命中
- [x] `grep "funding_rate\|mark_price" internal/server/storage/taos_writer.go` ≥2 命中
- [x] `grep 'ProductLine: "spot"' internal/server/assembly/storage.go` 无硬编码命中
- [x] `release_closeable=YES` 残留文档引用 = 0（排除历史归档）
