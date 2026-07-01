# P10 Closure Evidence — Binance 模块

> [COMPUTED, HIGH] 本文件记录 P10 文档修复的验证证据，2026-06-28。
> 每个 action 附带验证命令和结果。Beads ID 为占位符，实际 ID 以 Beads 仓为准。

---

## 已验证完成项

### A-1 (#1293 / ZoneCNH-5k4j) — internal/wire 角色明确化

- **Status**: DONE
- **Evidence**: `internal/wire/doc.go` 存在于 `/home/workspace/binance/internal/wire/doc.go`，包含包级文档说明 wire 是 binance client/server 共享的契约类型层，记录了 ADR-002 过渡态和迁移路径。
- **Verification**: `cat /home/workspace/binance/internal/wire/doc.go` 显示 package doc 包含 transport adapter 角色说明和边界约束。

### A-4/B-3 (#1303 / ZoneCNH-5k4k) — Subject 版本化 `.v1`

- **Status**: DONE
- **Evidence**: runtime publisher 代码使用 `fmt.Sprintf("binance.market.%s.%s.v1", productLine, eventType)` 构造 subject。测试文件验证 `binance.market.spot.trade.v1`。drift check 脚本 A-4 检查全部 PASS。
- **Verification**: `rg "binance\.market\.%s\.%s\.v1" /home/workspace/binance/internal/client/publisher/publisher.go` 命中。`bash /home/workspace/binance/scripts/spec-runtime-drift-check.sh` A-4 全 PASS。

### B-2 (#1295 / ZoneCNH-5k4l) — client/SPEC §14 目录结构修正

- **Status**: DONE（本次修复）
- **Action**: 将 client/SPEC §14 Runtime 目录树从虚假子目录结构（`app/`、`catalog/`、`connector/`、`normalize/`、`mapper/`、`idempotency/`、`admin/`）修正为与 `/home/workspace/binance/internal/client/` 实际 flat layout 一致的文件列表。
- **Evidence**: `module/binance/spec/client/SPEC.md` §14 现在反映 monorepo flat layout，包含 `runtime.go`、`lifecycle.go`、`catalog.go`、`exchangeinfo.go`、`connector.go`、`connectors/`、`normalize.go`、`mapper.go`、`idempotency.go`、`publisher/`、`admin.go`、`http_ingest_endpoint.go`、`throttle.go`、`resource_governance.go`、`history_*.go`、`testdata/` 等实际文件。
- **Verification**: `ls /home/workspace/binance/internal/client/` 与 SPEC §14 目录树一致。

### C-1/G-3 (#1299 / ZoneCNH-5k4m) — SPEC 参数表迁移至 design/

- **Status**: DONE（已完成）
- **Evidence**: SPEC.md 为 225 行精简规格，不含 FR-013 退避参数表、FR-017 分策略检测表、FR-025 优先级参数、FR-029 校验规则表、FR-036 拓扑映射表。参数表归属 `module/binance/design/CONFIG-SCHEMA.md`。SPEC §11 明确 "Configuration parameters are owned by `module/binance/design/CONFIG-SCHEMA.md`"。AC-005 要求 SPEC < 1000 行。
- **Verification**: `rg "退避参数|分策略检测|优先级参数|校验规则表|拓扑映射" module/binance/spec/SPEC.md` 无匹配。`wc -l module/binance/spec/SPEC.md` = 225。

### C-2/G-2 (#1297 / ZoneCNH-5k4n) — 4 个 retired spec 文件物理删除

- **Status**: DONE
- **Evidence**: `spec/SPEC-exchangeinfo-sync.md`、`spec/DATA-LIFECYCLE.md`、`spec/DATA-QUALITY-SLA.md`、`spec/ENDPOINTS.md` 均已从 `module/binance/spec/` 物理删除。CI gate 验证 retired 文件不存在。
- **Verification**: `for f in spec/SPEC-exchangeinfo-sync.md spec/DATA-LIFECYCLE.md spec/DATA-QUALITY-SLA.md spec/ENDPOINTS.md; do test -e "module/binance/$f" && echo "EXISTS" || echo "DELETED"; done` → 全部 DELETED。

### C-3 (#1289 / ZoneCNH-5k4o) — SPEC.md 精简至 < 1000 行

- **Status**: DONE
- **Evidence**: SPEC.md 为 225 行，远低于 1000 行目标。
- **Verification**: `wc -l module/binance/spec/SPEC.md` = 225。

### C-4 (#1298 / ZoneCNH-5k4p) — AC/TC 命名空间清理

- **Status**: DONE
- **Evidence**: TRACEABILITY.md 使用连续 AC-001~AC-007 编号，无 "AC-105~128→131~154" 风格的命名空间协调注释。legacy AC-BNC 映射隔离在 `docs/migrations/ac-bnc-legacy-mapping.md`，CI gate 验证 active spec 中无 AC-BNC 行。
- **Verification**: `rg "AC-105|AC-128|AC-131|AC-154|105~128|131~154" module/binance/` 无匹配。`rg "AC-BNC" module/binance/matrix/TRACEABILITY.md` 无匹配。

### D-1 (#1290 / ZoneCNH-5k4q) — 废除双态模型

- **Status**: DONE
- **Evidence**: TRACEABILITY.md 和 SPEC.md 均声明 `State-Model: single-state only`。状态模型为 Done / Partial / Drifted / Pending 四态单一口径。无 `Evidence-Done` 或 `Evidence-State` 作为活跃状态标签。SPEC §5 明确 "历史 `Code-State` / `Evidence-State` 双态口径已废除"。
- **Verification**: `rg "Evidence-Done|Evidence-State|Code-State" module/binance/` 仅在废除上下文中出现。CI gate dual-state residue 检查 PASS。

### D-2/G-1 (#1300 / ZoneCNH-5k4r) — TRACEABILITY.md 精简至 < 200 行

- **Status**: DONE
- **Evidence**: TRACEABILITY.md 为 114 行（含 release_closeable 公式新增内容），低于 200 行目标。
- **Verification**: `wc -l module/binance/matrix/TRACEABILITY.md` = 114。

### D-3 (#1302 / ZoneCNH-5k4s) — release_closeable 判定标准

- **Status**: DONE（本次修复）
- **Action**: 在 TRACEABILITY.md §4 添加显式 release_closeable 判定公式：`release_closeable = Code-Done FR / Total FR ≥ 90% AND Drifted FR = 0 AND Pending FR = 0 AND PRG-001~007 全 PASS AND 远程 CI PASS AND release tag 已发布 AND HA/DR 部署文档存在`。当前状态 `release_closeable: NO`（23/48 ≈ 47.9% < 90%）。
- **Evidence**: `module/binance/matrix/TRACEABILITY.md` §4 包含完整公式和当前 NO 状态说明。
- **Verification**: `rg "release_closeable = Code-Done FR / Total FR" module/binance/matrix/TRACEABILITY.md` 命中。`rg "release_closeable: NO" module/binance/matrix/TRACEABILITY.md` 命中。

### D-4/G-5 (#1292 / ZoneCNH-5k4t) — todo.md 归档为 projection-only

- **Status**: DONE
- **Evidence**: `module/binance/evidence/2026-06-28/todo-archived.md` 存在，为 2026-06-28 归档快照。`module/binance/todo.md` 为 read-only projection 文件，头部声明 "This file is a read-only projection" 和 "Closure SSOTs are Beads and GitHub Issues"。CI gate 验证 todo.md 为 projection-only。
- **Verification**: `head -5 module/binance/todo.md` 显示 read-only projection 声明。`test -f module/binance/evidence/2026-06-28/todo-archived.md` → 存在。

### E-6 (#1331 / ZoneCNH-5k4u) — spec-runtime-drift-check.sh 存在

- **Status**: DONE
- **Evidence**: `/home/workspace/binance/scripts/spec-runtime-drift-check.sh` 存在，181 行，包含 A-1~A-4 drift 检查，全部 PASS。
- **Verification**: `bash /home/workspace/binance/scripts/spec-runtime-drift-check.sh` → "Spec/runtime drift check passed"。

### G-4 (#1296 / ZoneCNH-5k4v) — BOUNDARY-GATES §20 迁移至模板

- **Status**: DONE
- **Evidence**: `docs/governance/boundary-gates-template.md` 存在，包含从 `module/binance/gate/BOUNDARY-GATES.md` §20 迁移的跨模块推广模板。模板包含模块适配矩阵、实施状态和模板创建命令。
- **Verification**: `head -5 docs/governance/boundary-gates-template.md` 显示来源标注和迁移日期。

### G-6 (#1301 / ZoneCNH-5k4w) — 状态一致性 CI gate 增强

- **Status**: DONE（本次修复）
- **Action**: 增强 `.github/ci/binance-status-consistency-check.sh`，新增三项检查：
  1. **release_closeable 比率一致性**：从 TRACEABILITY 统计中计算 Code-Done/Total 比率，当 ≥90% 且 Drifted=0 且 Pending=0 时要求 `release_closeable: YES`，否则要求 `NO`。
  2. **双态模型残留检查**：扫描所有 active 文件（SPEC/TRACEABILITY/FEATURES/ACCEPTANCE/README/prompt README），检测 `Evidence-Done`/`Evidence-State`/`Code-State` 在废除上下文之外的活跃使用。
  3. **release_closeable 公式存在性检查**：验证 TRACEABILITY.md 包含 `release_closeable = Code-Done FR / Total FR` 公式和 `PRG-001~007` 引用。
  4. **todo.md projection-only 检查**：将 todo.md 从 "禁止存在" 改为 "必须为 read-only projection"。
- **Evidence**: `bash .github/ci/binance-status-consistency-check.sh` → "Result: PASS"。
- **Verification**: `bash -n .github/ci/binance-status-consistency-check.sh` → 语法正确。运行结果 PASS。

---

## 汇总

| Action ID | Issue # | 状态 | 备注 |
| --- | --- | --- | --- |
| A-1 | #1293 | DONE | 验证完成 |
| A-4/B-3 | #1303 | DONE | 验证完成 |
| B-2 | #1295 | DONE | 本次修复 §14 目录树 |
| C-1/G-3 | #1299 | DONE | 验证完成（参数表已迁移） |
| C-2/G-2 | #1297 | DONE | 验证完成（4 文件已删除） |
| C-3 | #1289 | DONE | 验证完成（225 行） |
| C-4 | #1298 | DONE | 验证完成（AC 连续编号） |
| D-1 | #1290 | DONE | 验证完成（单态模型） |
| D-2/G-1 | #1300 | DONE | 验证完成（114 行） |
| D-3 | #1302 | DONE | 本次修复（添加公式） |
| D-4/G-5 | #1292 | DONE | 验证完成（projection-only） |
| E-6 | #1331 | DONE | 验证完成 |
| G-4 | #1296 | DONE | 验证完成 |
| G-6 | #1301 | DONE | 本次修复（CI gate 增强） |

本次修改文件：
- `module/binance/spec/client/SPEC.md` — §14 目录结构修正
- `module/binance/matrix/TRACEABILITY.md` — §4 添加 release_closeable 公式
- `.github/ci/binance-status-consistency-check.sh` — 新增 release_closeable 比率检查、双态残留检查、公式存在性检查、todo.md projection 检查
- `module/binance/evidence/2026-06-28/review/p10-closure-evidence.md` — 本证据文件（新建）
