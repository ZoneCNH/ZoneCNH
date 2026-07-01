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
| PRG-006 | **Partial** | 真实 soak/chaos 测试存在但 gated 在 `BINANCE_*_LIVE=1` env 后，默认 CI 跑不到端到端系统行为 |
| PRG-007 | PASS | 43 GitHub + 43 Beads 全关闭 |

> ⚠️ **2026-06-30 测试体系深度分析**（2026-07-02 复核修正）：`report/binance/TEST-ANALYSIS-20260630.md` 触发对测试深度的复核，部分描述已证实与代码不符（详见报告头部免责声明）。复核后准确状况：
> - soak：3 个测试（1 CI-runnable ServerStability + 2 真实管线 gated by `BINANCE_SOAK_LIVE=1`），非"只测 NATS pub/sub"
> - chaos：12 个测试（6 真实故障注入含 `systemctl stop` NATS/Redis、`kill -9` + 6 连通性），非"不注入故障"
> - security：9 个函数（3 真实 + 6 skip），非"6 个全 skip"
> - depth：76 个 Test 函数 / 125 处 `t.Skip` stubs（按报告路线图承接），depth 文件头注释明确引用本报告作为 roadmap
> - FR-042 (soak)、FR-043 (chaos)、FR-044 (security) 真实测试存在但 gated，默认 CI 覆盖有限；PRG-006 维持 Partial
> - 建议在补齐默认 CI 覆盖前不应标记为 L3 Production。详见报告（含免责声明）。
