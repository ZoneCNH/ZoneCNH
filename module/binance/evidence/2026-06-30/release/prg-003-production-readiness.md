# PRG-003: Production Readiness 汇总

| 字段 | 值 |
|------|-----|
| 日期 | 2026-06-30 |
| 验证人 | PRG gate agent |
| 结论 | **Open**（阻塞于 PRG-001） |

## PRG-001~007 状态汇总

| PRG | 项 | 结论 | Evidence |
|-----|----|------|----------|
| PRG-001 | Remote CI Runner | **Open** | [prg-001-ci-runner.md](prg-001-ci-runner.md) |
| PRG-002 | Release Promotion | **PASS** | [prg-002-release-tag.md](prg-002-release-tag.md) |
| PRG-003 | Production Readiness | **Open** | 本文件（汇总项） |
| PRG-004 | Observability | **Partial** | [prg-004-observability.md](prg-004-observability.md) |
| PRG-005 | Security | **Partial** | [prg-005-security.md](prg-005-security.md) |
| PRG-006 | Resilience | **Partial** | [prg-006-resilience.md](prg-006-resilience.md) |
| PRG-007 | Issue Sync | **PASS** | [prg-007-issue-sync.md](prg-007-issue-sync.md) |

## 已通过项

- PRG-002：v0.8.0 tag + GitHub Release 存在 ✅
- PRG-007：43 GitHub issues 全关闭，0 open ✅

## 阻塞项

### PRG-001（阻塞 production readiness 闭合）

self-hosted runner 未注册（`total_count: 0`），所有 CI run 停留在 queued/pending，无任何完成的 CI run。这是 production readiness 的硬门禁——无法证明远端 CI 管线可执行。

### PRG-004（AlertManager 缺失）

Jaeger/Grafana/Loki 在线，但 AlertManager 不可达（curl :9093 FAIL）。deploy/ 目录下无 observability 配置文件。

### PRG-005（2 个未修补 CVE）

govulncheck 发现 2 个影响代码的 OpenTelemetry 漏洞：
- GO-2026-4985（OTLP HTTP 内存耗尽，fix v1.43.0）
- GO-2026-4394（PATH 劫持 RCE，fix v1.40.0）
当前使用 v1.37.0，需升级。

### PRG-006（soak/chaos 为 scaffold）

soak_test.go 和 chaos_test.go 存在但全部 `t.Skip()`，canary 脚本完整但未在 live 环境执行过。

## 闭合条件

PRG-003 闭合需 PRG-001~006 全部 PASS：
1. 注册 self-hosted runner 并获得至少 1 个成功 CI run（PRG-001）
2. 启动 AlertManager 或记录降级理由（PRG-004）
3. 升级 OpenTelemetry 到 v1.43.0+ 消除 2 个 CVE（PRG-005）
4. 在 live 基础设施上执行 soak/chaos 测试（PRG-006）

## 结论

**Open** — 待 PRG-001（CI runner）及 PRG-004/005/006（partial 项）闭合后，PRG-003 方可标记 PASS。

[COMPUTED] 汇总基于 PRG-001~007 各 evidence 文件；[INFERRED] 闭合条件依赖各 partial 项的修复路径。

[RULES I BROKE]：无
