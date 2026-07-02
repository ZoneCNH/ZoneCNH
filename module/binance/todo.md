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

## 运行时缺口投影（2026-07-02 新增）

> 以下为 `report/binance/DATA-INTEGRITY-E2E-20260701.md` v3.9 识别的运行时缺口只读投影。
> 完整矩阵见 `module/binance/RUNTIME-GAP-MATRIX.md`。
> 规格口径（48 Done）与运行时口径（58 Open）正交——规格 Done 表示 FR 功能面已闭合，运行时 Open 表示生产部署中存在缺口。

- 运行时缺口总数: 58（P0=3, P1=13, P2=22, P3=20）
- 总工时估算: ~73.5 人天
- 漏洞链: 15 条
- 自审轮次: 27 轮（200+ 维度矩阵核验）

### P0 — CRITICAL（3 项，7d）

| GAP-ID | 一句话 | 工时 |
|--------|--------|------|
| GAP-E1 | coverage 状态持久化违反 client/server 边界 | 2.5d |
| GAP-E6 | UM/CM/Options 未装配 ExchangeInfoRefresher | 0.5d |
| GAP-E25 | client 无 ClientID/分片机制，多副本重复采集 | 4d |

### P1 — HIGH（13 项，16.5d）

| GAP-ID | 一句话 | 工时 |
|--------|--------|------|
| GAP-E2 | server 消费端无完整性扫描器 | 2d |
| GAP-E3 | 端到端二向对账缺失 | 1d |
| GAP-E7 | SPEC §75 vs §509 内部矛盾 | 0.5d |
| GAP-E10 | catalog SSOT 职责模糊，server 无订阅通道 | 2d |
| GAP-E12 | NATS AckWait 30s vs backfill 5min 不匹配 | 1.5d |
| GAP-E17 | server 25+ 处 time.Now() 不带 UTC | 0.5d |
| GAP-E18 | TDengine 部分成功调用方忽略 | 1d |
| GAP-E24 | CatalogEntry 无 Tier/Priority，全量采集 | 2.5d |
| GAP-E26 | interval 治理碎片化 + REST fallback 1m | 1.5d |
| GAP-E27 | WebSocket 无 SetReadLimit，OOM 风险 | 0.5d |
| GAP-E28 | PG 完全无事务管理 | 2d |
| GAP-E32 | 7 处 goroutine 无 recover | 0.5d |
| GAP-E37 | admin API 缺 CSRF 防护 | 1d |

### 立即可上（独立无依赖，ROI 排序）

1. GAP-E32（0.5d）— goroutine recover
2. GAP-E27（0.5d）— WebSocket OOM 保护
3. GAP-E34（0.5d）— HTTP server 完整超时
4. GAP-E6（0.5d）— 4 产品线 refresher 装配
5. GAP-E29（1.5d）— migration runner
6. GAP-E36（1d）— buildinfo 注入

> 完整 P2/P3 列表见 `RUNTIME-GAP-MATRIX.md` §2.3~§2.4。
