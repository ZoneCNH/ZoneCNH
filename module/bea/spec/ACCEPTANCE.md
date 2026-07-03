# bea 完整验收清单

- Status: Planned（Production Target）
- Last-Updated: 2026-07-04
- Module-Version: v0.2.0
- Source: `spec/SPEC.md`、`matrix/TRACEABILITY.md`、`spec/FEATURES.md`

> 本文档是 `bea` 的验收清单。  
> [x] 已通过 · [ ] 未通过

## 验收命令（runtime 仓）

| 类别 | 命令 | 通过标准 |
| ---- | ---- | -------- |
| 构建 | `go build ./...` | 零错误 |
| 单元测试 | `go test ./... -count=1` | 全通过 |
| 并发测试 | `go test ./... -race -count=1` | 零 race |
| 静态检查 | `go vet ./...` | 零 warning |
| 边界门禁 | `bash scripts/boundary-gates.sh` | 所有 gate 通过 |
| 漂移检查 | `scripts/spec-runtime-drift-check.sh` | SPEC 与 runtime 一致 |

## 验收项

| AC | 验收内容 | 状态 | 证据锚点 |
| -- | -------- | ---- | -------- |
| AC-BEA-001 | 子模块 client/server 独立启动并通过 health/readiness/version | [ ] | service startup logs |
| AC-BEA-002 | 配置仅引用 secret reference，脱敏扫描通过 | [ ] | config schema + redaction report |
| AC-BEA-003 | 三层采集清单覆盖完整，参数枚举无缺口 | [ ] | dataset catalog report |
| AC-BEA-004 | Raw-First + 七介质链路闭合，失败可回放 | [ ] | integration replay evidence |
| AC-BEA-005 | 增量/全量/Re-sync 作业追踪可用 | [ ] | sync job + checkpoint report |
| AC-BEA-006 | no-lookahead 与修订可见性规则通过 | [ ] | visibility/revision tests |
| AC-BEA-007 | 发布日历触发采集成功，轮询仅兜底 | [ ] | scheduler evidence |
| AC-BEA-008 | 质量校验（完整性/一致性/异常值/修订）通过 | [ ] | quality report |
| AC-BEA-009 | 仪表盘、PDF 报告、异常预警链路可运行 | [ ] | reporting pipeline evidence |

## 关键验收阈值

| 维度 | 阈值 |
| ---- | ---- |
| 发布窗口 freshness | `< 24h` |
| 非窗口 freshness | `< 72h` |
| API 热点查询 P95 | `< 300ms` |
| Kafka publish lag | `< 10s` |
| ClickHouse read model lag | `< 60s` |
| 单轮同步目标耗时 | `<= 30min` |
| 全量对账 | 每月至少 1 次 |
| 采集覆盖率 | 三层数据集 100% 覆盖 |

## 拒绝发布条件

1. 任一子模块无法独立 C/S 启动。
2. NATS/Kafka 职责混用。
3. `available_at` 缺失导致 no-lookahead 破坏。
4. 权威层写入失败仍推进 checkpoint。
5. secret 值出现在文档、日志或配置产物。

