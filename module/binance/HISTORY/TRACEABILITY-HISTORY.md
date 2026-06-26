# TRACEABILITY.md 历史变更摘要归档

> 本文件记录 2026-06-23 至 2026-06-26 期间 TRACEABILITY.md §1 前导注释块中的历史变更摘要。
> 活跃文档中仅保留当前版本（v3.7.1）和上一稳定版本（v3.6.1）的摘要。
> 完整变更历史以 `CHANGELOG.md` 为 SSOT。

---

## v3.6.2（2026-06-26）

补充 SPEC §4.2 Production Readiness Gates（PRG-001~PRG-007），把 Plan008 的 S3/S4/S6/S26/S28/S29/S30/S31/S32/S34/S35/M1-M4 收敛为 NFR-021~NFR-027。本次不改变 FR 当前投影；`release_closeable=YES` 仍不自动升格为 30/30 Done。

## v3.1.0

FR-006 拆分为 6a(taosx)/6b(postgresx)/6c(redisx cache)/6d(ossx)；FR-007 扩展 analytics API(7a)；新增 FR-010（clickhousex OLAP 存储）、FR-011（分布式协调锁）；v3.1.0 继续登记 FR-012~FR-024，覆盖 realtime control、historical lifecycle、event governance、release evidence 与 runtime hot reload；subject 命名统一 `um_perp`/`cm_perp`；Error 码扩展至 BNC-013；Performance Budget 扩展至 20 项。

## v3.2.0

fold DATA-LIFECYCLE §7 候选 FR 进 SPEC/TRACEABILITY/NAMING——新增 FR-025~028；NAMING §2.1 补 bar 订阅周期集、§3.1 补 control subjects；SPEC §9 补 FR-015 depth 档位表 + control subjects；AC 扩展至 098、TC 扩展至 046。

## v3.3.0

版本号统一治理——字段名收敛为 `Spec-Version`（仅 SPEC）/ `Module-Version`（治理文档）/ `Runtime-Version`（SPEC runtime 版本）；废弃 `Doc-Version`/`Matrix-Version`/`Version` 异名；顶层 Module-Version 对齐 root SPEC；server/TRACEABILITY 补建版本字段；R6 扩展为全量版本统一规则。

## v3.5.1（2026-06-24）

FR 实现状态从「1 Done / 29 Pending」刷新为「22 Done / 8 Partial / 0 Pending」，对齐 runtime HEAD `8290dc9`（PR #73 之后的真实代码状态）。22 个 Done FR 拥有非 stub 生产代码路径；8 个 Partial 各有明确缺口。BR-004 提升为 Partial。该段仅保留为历史记录。

## v3.6.0（2026-06-25，已被 v3.6.1 覆盖）

FR 实现状态曾从「22 Done / 8 Partial」刷新为「19 Done / 11 Partial」，对齐 runtime HEAD `e02b190`（Plan007 A1~A10 + B1~B8）。引入 main.go 装配级证据标准：FR 标 Done 必须同时满足「writer/代码存在」且「`cmd/binance-server/main.go` 装配真实实例」。上调 6 项，下调 9 项（main.go 装配断层）。BR-004 提升为 Done。该段仅保留为历史记录。

## 2026-06-23 历史证据刷新（round 2）

本地 runtime evidence 已归档至 `/home/binance/release/evidence/binance/20260623/`；证据提交 `71e2a6e8`；boundary gates 重新运行 10/10 PASS，`go build`/`go vet`/`go test` 全部 PASS。GitHub #923~#931 已关闭。该关闭仅表示 issue tracking closure。

## 2026-06-24 历史本地 readiness 刷新

本地验证：boundary gates `13 passed, 0 failed`，`go test ./... -race -count=1` PASS。该证据只更新 FR-009/BR 边界与本地 build/readiness 追溯。该段仅保留为历史记录。

## 2026-06-24 历史 gated JetStream 子集刷新

真实本地 NATS JetStream 已证明 accepted PubAck、duplicate PubAck、Ack 后不重投、immediate Nak 到 `MaxDeliver=5` 后停止。TC-004/TC-006 继续 Pending。该段仅保留为历史记录。

## 2026-06-24 历史 kafkax fanout 本地子集刷新

本地 adapter 已验证 topic/key 和 strict handoff `BNC-008` before durable/Ack。FR-008 仍未 Done。该段仅保留为历史记录。
