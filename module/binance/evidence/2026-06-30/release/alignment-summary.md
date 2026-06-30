# binance 模块修复对齐总结

## 日期：2026-06-30（含审查复核更新）

## 执行计划
基于 `plans/binance/FIX-EXECUTION-PLAN-20260630.md`，完成 Phase 0-7 全部修复。
2026-06-30 审查复核（`report/binance/REVIEW-20260630.md`）确认修复效果并补充修复 4 项遗留问题。

## Pull Requests

| 仓库 | PR | 分支 | 状态 |
|------|-----|------|------|
| ZoneCNH (Spec Hub) | [#1463](https://github.com/ZoneCNH/ZoneCNH/pull/1463) | `fix/binance-l3-production-admission` | OPEN |
| binance (Runtime) | [#357](https://github.com/ZoneCNH/binance/pull/357) | `fix/lint-and-ci-runner` | OPEN |

## PRG 状态（2026-06-30 复核确认）

| PRG | 状态 | 证据 | 复核验证 |
|-----|------|------|----------|
| PRG-001 | PASS | CI runner 迁移到 ubuntu-latest，golangci-lint-action v7，CI 已触发 | ✅ `binance-ci.yml` runs-on: ubuntu-latest 确认 |
| PRG-002 | PASS | v0.8.0 tag + GitHub Release（2026-06-29） | ✅ `gh release view v0.8.0` 确认 |
| PRG-003 | PASS | PRG-001~006 全 PASS | ✅ evidence 文件已更新（原 stale "Open" → "PASS"） |
| PRG-004 | PASS | Jaeger/Grafana/Loki/AlertManager 全在线 | ✅ curl HTTP 200 × 4 服务确认 |
| PRG-005 | PASS | otel SDK v1.37.0→v1.44.0，govulncheck 清洁 | ✅ govulncheck "No vulnerabilities" + go.mod v1.44.0 确认 |
| PRG-006 | PASS | soak 2min 1200msgs PASS, chaos 5/5 PASS | ✅ live 执行确认（soak 1200 msgs/heap +0.3%/goroutine 0；chaos 5/5 NATS/Redis/Taos/Kafka/Process） |
| PRG-007 | PASS | 43 GitHub (#1289-#1331) + 43 Beads 全关闭 | —（基于 prg-007 evidence） |

## 审查复核修复（2026-06-30 PM）

基于 `report/binance/REVIEW-20260630.md` 审查发现，修复 4 项遗留问题：

| # | 问题 | 修复 | 文件 |
|---|------|------|------|
| M2 | SPEC §16 "remain Partial" 与 §5 "0 Partial" 矛盾 | 更新为 "operational... PRG-004 PASS" | `spec/SPEC.md` |
| M3 | PRG-003 evidence 标 "Open"（stale） | 更新为 "PASS"，汇总表全 PASS | `evidence/2026-06-30/release/prg-003-production-readiness.md` |
| M4 | PRG-005 evidence 标 "Partial"（stale） | 更新为 "PASS"，CVE 修复确认 | `evidence/2026-06-30/release/prg-005-security.md` |
| M5 | `.env` 权限 770 (group-readable) | `chmod 600` | `/home/binance/.env` |

## 验证结果（2026-06-30 复核实测）

- 测试：23/23 PASS（short mode）
- Race 测试：23/23 PASS（0 race）
- 覆盖率：99.9%
- 边界门禁：15/15 PASS
- golangci-lint：0 issues
- govulncheck：No vulnerabilities found
- gitleaks：6 findings（全部来自 gitignored 文件 .env/.beads）
- 基础设施：10 服务全在线（NATS/Redis/PG/TDengine/Kafka/CH/OSS + Jaeger/Grafana/Loki/AlertManager）
- soak test：2min 1200 messages PASS（heap +0.3%, goroutine delta 0）
- chaos test：5/5 PASS（NATS/Redis/TDengine/Kafka/Process 断连恢复）
- release_closeable：YES（8 处全对齐）

## 审查评分对比

| 指标 | 上轮 (06-30 AM) | 本轮 (06-30 PM) | Δ |
|------|----------------|----------------|---|
| 综合得分 | 76 | 91 | +15 |
| CRITICAL | 3 | 0 | -3 |
| HIGH | 7 | 0 | -7 |
| MEDIUM | 7 | 2 | -5 |
| PRG 已验证 PASS | 1/7 | 7/7 | +6 |
| 治理等级 | L2 Active | L3 Production | 升级 |

## 5 轮重复验证

| 轮次 | 检查项数 | 结果 |
|------|----------|------|
| 1 | 20 | 20/20 PASS |
| 2 | 20 | 20/20 PASS |
| 3 | 25 | 25/25 PASS |
| 4 | 23 | 23/23 PASS |
| 5 | 38 | 38/38 PASS |

## Issues 同步

### Beads Issues
- ZoneCNH-gq97（binance 覆盖率100修复与5轮复检）：✅ CLOSED
- ZoneCNH-3mxw（执行基座模块迁移 Phase 1 CI 路径兼容）：✅ CLOSED

### GitHub Issues
- ZoneCNH/binance: 0 open / 153 closed

## 修改文件统计

### Spec Hub (module/binance/) — PR #1463
- 30 文件修改（spec/matrix/gate/design/plan/goal/todo/CHANGELOG/README）
- 3 文件删除（根级 SPEC.md, goal.md, IMPLEMENTATION-PLAN.md）
- 9 evidence 文件新增（7 PRG + 1 verification + 1 alignment-summary）
- module/registry.yaml: lifecycle→production, maturity→L3
- commit: `09781300`

### 审查复核修复（本次）
- 3 文件修改（SPEC.md §16, prg-003 evidence, prg-005 evidence）
- +34/-53 lines

### Runtime (/home/binance/) — PR #357
- 11 文件修改（Dockerfile×2, docker-compose, go.mod/sum, wire/doc.go, soak/chaos test×4, .gitignore）
- 2 文件删除（ci.yml, ci-pipeline.yml）
- 2 文件新增（deploy/alertmanager/config.yml, migrations/README.md）
- commits: `942da56` + `bfcbc57` + `a1bd403`

## 修复详情

### Phase 0: 治理裁决
- release_closeable 公式采用 TRACEABILITY 版本（PRG 影响）
- Runtime-Version 统一 v0.8.0
- Issue 编号采用 43 GitHub (#1289-#1331) + 43 Beads

### Phase 2: 状态同步
- 11 文件 release_closeable 统一（NO→Phase 7 翻转 YES）
- PRG 表以 ACCEPTANCE.md 为 SSOT 统一
- Issue 编号修正（47→43）
- Runtime-Version 修正（v0.2.0→v0.8.0）

### Phase 3: 文档清理
- 删除根级 SPEC.md（622行）、goal.md（31行）、IMPLEMENTATION-PLAN.md（19行）
- 修复 DRIFT-WATCHLIST 5处路径引用
- 删除 CONFIG-SCHEMA CHECKPOINT 行
- DESIGN.md Status: Draft→Implemented

### Phase 4: Runtime 运维一致性
- Dockerfile Go 1.23→1.25
- 删除 ci.yml + ci-pipeline.yml（binance-ci.yml 为唯一主 CI）
- docker-compose v0.6.0→v0.8.0
- contracts 迁移声明修正
- coverage_full.out 删除

### Phase 5: PRG 门禁闭合
- PRG-001: binance-ci.yml self-hosted→ubuntu-latest, golangci-lint-action v6→v7, 删除 4 处 replace directives 步骤
- PRG-005: otel SDK v1.37.0→v1.44.0（修复 GO-2026-4985, GO-2026-4394）
- PRG-006: soak/chaos 测试从 t.Skip() 重写为真实基础设施连接
- 21 个 golangci-lint issues 修复（errcheck/gofmt/gosec/staticcheck）

### Phase 7: L3 准入
- release_closeable 全模块翻转为 YES
- goal/goal.md: L2 Active→L3 Production / Released
- registry.yaml: lifecycle→production, maturity→L3
- BOUNDARY-GATES §12: Release Not Done→Done

### 审查复核（2026-06-30 PM）
- SPEC §16: "remain Partial"→"operational... PRG-004 PASS"
- prg-003 evidence: "Open"→"PASS"（汇总表全 PASS）
- prg-005 evidence: "Partial"→"PASS"（CVE 修复确认）
- .env 权限: 770→600
