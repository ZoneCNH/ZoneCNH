# module/binance todo（只读投影）

> Beads/GitHub Issues 是关闭 SSOT，本文件仅为只读投影。

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
