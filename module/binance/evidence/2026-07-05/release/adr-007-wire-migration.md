# ADR-007 Wire→Contracts 迁移 — Release Evidence

> 日期：2026-07-05
> 关联：`module/binance/design/ADR-007-wire-to-contracts-migration.md`（Accepted）
> 执行计划：`plans/binance/012-wire-to-contracts-migration-plan-20260705.md`（Phase 0-5）
> 仓库：`contracts`（v0.5.0 → v0.5.1）、`binance`（feat/wire-to-contracts-migration）

## 1. 实施摘要

ADR-002 过渡态闭环。`internal/wire` 删除，C/S 共享契约迁入 `contracts` canonical（v0.5.0 富化，v0.5.1 移除 `IngestAck.RequestID` 死字段）。binance 新增 `internal/ingestcodec` boundary 层承载 `domainmarket.InstrumentKey ↔ json.RawMessage` 序列化与 BNC 私有码→canonical 码映射。

## 2. contracts 仓变更（v0.5.0 breaking + v0.5.1 patch）

- `pkg/contracts/ingestion.go`：`IngestRequest` 补 Symbol/PayloadHash/TraceContext/Quality；`IngestAck` 补 AcceptedKey/AcceptedAt/Quality/Gap/SLA；新增 `TraceContext`/`QualityVerdict`/`GapStatus`/`SLAStatus` 导出类型；`IngestResult` 新增 `IsAck`/`IsReject`/`Validate()`/`ErrAckRejectMutuallyExclusive`。
- `pkg/contracts/ingestion_test.go`：新字段 JSON round-trip + 不变量方法覆盖。
- `pkg/contracts/alert_test.go`：修复 `mockRuleStore.Load` 返回类型笔误（预存编译错误）。
- `scripts/check_boundary_test.go`：fixture 从真实 import 改为注释形式，避免 `go list -deps` 编译失败导致 grep 检查不可达。
- 版本常量 `v0.4.6` → `v0.5.0` 全仓同步（governance.go / templatex/version.go / releasemanifest / template.json / README / release.md / harness.yaml / AGENTS.md / main_test.go）。
- `CHANGELOG.md`：v0.5.0 breaking 条目。

## 3. binance 仓变更

- 新增 `internal/ingestcodec/`：doc.go / aliases.go（contracts DTO 类型别名 + `IngestEndpoint` + 构造器 + `BoolToInt32`）/ bnc_code.go（BNC-001..019 + `BNCCodeToCanonical` 映射 + canonical 常量重导出）/ instrumentkey.go（Marshal/Unmarshal/MustMarshal）/ codec_test.go。
- 删除 `internal/wire/`（5 文件）。
- `go.mod`：新增 `github.com/ZoneCNH/contracts v0.5.1` direct 依赖（v0.5.0 → v0.5.1，移除 `replace` 指令）。
- 69 文件改动（+1076/−1662）：62 个 import 站点迁移，字段重命名（`IdempotencyKey`→`RequestID`、`Duplicate`(bool)→`DuplicateCount`(int)）、`IngestReject.Code`(BNC)→`RejectCode`(canonical)、InstrumentKey boundary 序列化。

## 4. 验证证据

### 4.1 contracts 仓

```
go build ./...                     → PASS
go vet ./...                       → PASS
go test ./...                      → PASS（15 packages）
go test -race ./...                → PASS（15 packages）
bash scripts/check_boundary.sh     → boundary check passed
```

### 4.2 binance 仓

```
go build ./...                     → PASS
go vet ./...                       → PASS
go test ./...                      → PASS（28 packages）
go test -race ./internal/... ./cmd/... ./pkg/...  → PASS（28 packages）
go test -race ./test/...           → PASS
bash scripts/boundary-gates.sh     → 15/15 PASS
rg "internal/wire" --type go       → 0 命中
rg "github.com/ZoneCNH/contracts" --type go → ≥1 命中
```

## 5. DoD 核对

- [x] `rg "internal/wire"` → 0 命中
- [x] binance `go build/test/race/vet` PASS（含 `./test/...` race）
- [x] `boundary-gates.sh` 15/15 PASS
- [x] contracts `go test -race ./...` PASS（含 scripts stale test fix）
- [x] contracts 版本常量 `v0.5.0` 全仓同步；v0.5.1 移除 `IngestAck.RequestID` 死字段
- [x] ADR-007 Accepted，ADR-002 Superseded
- [x] Evidence 归档（本文件）

## 6. 发布闭环（2026-07-05 完成）

- [x] contracts PR #19 合入 main 并打 `v0.5.0` tag（admin override CI 计费锁定）
- [x] binance `go.mod` 移除 `replace` 指令，`go get github.com/ZoneCNH/contracts@v0.5.0`（commit 11efdfd）
- [x] binance PR #432 合入
- [x] ZoneCNH PR #1679 合入
- [x] ZoneCNH 主仓 `report/arch/` + `report/binance/` 报告的"wire 未迁移"条目标记 Resolved

## 7. Post-ship 修复（2026-07-05）

> 26 轮深度排查发现 11 处迁移残留，全部修复。

| 仓库 | PR | 修复 |
|------|-----|------|
| contracts | [#20](https://github.com/ZoneCNH/contracts/pull/20) | `AllRejectCodes()` 漏收 `RejectUnsupportedChannel`（9→10） |
| contracts | [#21](https://github.com/ZoneCNH/contracts/pull/21) | 移除 `IngestAck.RequestID` 死字段（v0.5.1 tag） |
| binance | [#434](https://github.com/ZoneCNH/binance/pull/434) | 升级 v0.5.1 + `boolToInt32` DRY 收敛 |
| binance | [#435](https://github.com/ZoneCNH/binance/pull/435) | consumer JSON payload 字段名 + `Code`→`RejectCode` + BNC 码→canonical |
| binance | [#436](https://github.com/ZoneCNH/binance/pull/436) | `live_assembly_test.go` config 字段漂移修复 |
| binance | [#437](https://github.com/ZoneCNH/binance/pull/437) | `depth_test.go` RejectCode 类型不匹配 + `http_ingest_endpoint_test` canonical 语义 + go.sum tidy |

验证：7 个 build tag 全部 0 FAIL；全局 RejectCode 类型不匹配/BNC 字符串残留 0 命中。
