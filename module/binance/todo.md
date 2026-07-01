# module/binance todo（只读投影）

> Beads/GitHub Issues 是关闭 SSOT，本文件仅为只读投影 (read-only projection, not an active closure SSOT)。

## 当前状态

- Single State: 48 Done / 0 Partial / 0 Drifted / 0 Pending
- release_closeable: YES（PRG-001~007 全 PASS）
- 43 GitHub (#1289-#1331) + 43 Beads P10 issues 全部关闭
- 47/47 tasks Done
- 覆盖率: 99.9%（short + full mode）
- 边界门禁: 15/15 PASS

## PRG 阻塞项

| PRG | 状态 | 说明 |
|-----|------|------|
| PRG-001 | PASS | CI runner 从 self-hosted 迁移到 ubuntu-latest，CI 已触发运行 |
| PRG-002 | PASS | v0.8.0 tag + GitHub Release 均存在 |
| PRG-003 | PASS | PRG-001~006 全 PASS |
| PRG-004 | PASS | Jaeger/Grafana/Loki/AlertManager 全在线 |
| PRG-005 | PASS | OpenTelemetry SDK v1.44.0，govulncheck 清洁 |
| PRG-006 | PASS | soak test 2min PASS，chaos test 5/5 PASS |
| PRG-007 | PASS | 43 GitHub + 43 Beads 全关闭 |

> ⚠️ **2026-06-30 测试体系深度分析**：`report/binance/TEST-ANALYSIS-20260630.md` 对 112 个测试文件代码级审计发现：
> - PRG-006 依赖的 soak 测试只验证 NATS 传输（非 binance 管线），chaos 测试不注入真实故障
> - FR-042 (soak)、FR-043 (chaos)、FR-044 (security) 的 131 个测试为 `t.Skip()` 空壳
> - 建议在补齐 Phase 1-3 前不应标记为 L3 Production。详见报告。
