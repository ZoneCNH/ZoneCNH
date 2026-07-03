# yield_curve 完整验收清单

- Status: Planned（Production Target）
- Last-Updated: 2026-07-03
- Module-Version: v0.1.0
- Source: `spec/SPEC.md`、`matrix/TRACEABILITY.md`、`spec/FEATURES.md`

> 本文档是 `yield_curve` 的验收清单。  
> [x] 已通过 · [ ] 未通过

## 验收命令（runtime 仓）

| 类别 | 命令 | 通过标准 |
| ---- | ---- | -------- |
| 构建 | `go build ./...` | 零错误 |
| 单元测试 | `go test ./... -count=1` | 全通过 |
| 并发测试 | `go test ./... -race -count=1` | 零 race |
| 静态检查 | `go vet ./...` | 零 warning |
| 边界门禁 | `bash scripts/boundary-gates.sh` | 所有 gate 通过 |
| 漂移检查 | `scripts/spec-runtime-drift-check.sh` | FR/BR/AC/TC 与实现一致 |

## 验收项

| AC | 验收内容 | 状态 | 证据锚点 |
| -- | -------- | ---- | -------- |
| AC-YC-001 | 五子模块 client/server 独立启动，health/readiness/version 正常 | [ ] | service startup logs / probes |
| AC-YC-002 | 配置仅引用 secret reference，redaction 扫描通过 | [ ] | config schema + gitleaks |
| AC-YC-003 | 采集清单覆盖五类曲线、双指标、双期限段 | [ ] | collector contract tests |
| AC-YC-004 | latest/archive/BLC 路由行为正确 | [ ] | routing tests |
| AC-YC-005 | source/source_url/fetched_at 审计字段完整 | [ ] | audit field checks |
| AC-YC-006 | 多工作簿拼接与旧版兼容解析通过 | [ ] | parser integration tests |
| AC-YC-007 | raw-first + 多存储链路闭合，失败可回放 | [ ] | integration replay evidence |
| AC-YC-008 | 增量/全量/重同步可用，缺口重采闭环 | [ ] | coverage report + replay jobs |
| AC-YC-009 | 边界门禁阻断绕过共享基座直连基础设施 | [ ] | boundary gate report |
| AC-YC-010 | 宏观分析补充项可用（政策联动/跨市场/衍生指标/治理） | [ ] | analytics contract evidence |

## 关键验收阈值

| 维度 | 阈值 |
| ---- | ---- |
| daily freshness | `< 24h` |
| monthly freshness | `< 72h` |
| API 热点查询 P95 | `< 300ms` |
| Kafka publish lag | `< 10s` |
| ClickHouse read model lag | `< 60s` |
| latest cache TTL | `24h` |
| archive cache TTL | `30d` |
| 单轮同步目标耗时 | `<= 30min` |
| 全量重同步兜底 | 每月至少 1 次 |
| 覆盖率审计 | 五类曲线清单 100% 覆盖 |

## 拒绝发布条件

1. 任一曲线子模块无法独立 C/S 启动。
2. latest/archive/BLC 路由不一致。
3. NATS/Kafka 职责混用。
4. `available_at` 缺失导致 no-lookahead 破坏。
5. 多存储写入失败仍推进 checkpoint。
6. secret 值出现在文档、日志或配置产物中。

