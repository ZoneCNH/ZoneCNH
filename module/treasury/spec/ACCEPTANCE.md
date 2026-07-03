# treasury 完整验收清单

- Status: Planned（Production Target）
- Last-Updated: 2026-07-03
- Module-Version: v0.2.0
- Source: `spec/SPEC.md`、`matrix/TRACEABILITY.md`、`spec/FEATURES.md`

> 本文档是 `treasury` 的验收清单。
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
| AC-TRY-001 | 四子模块 client/server 独立启动，health/readiness/version 正常 | [ ] | service startup logs / probes |
| AC-TRY-002 | 配置仅引用 secret reference，redaction 扫描通过 | [ ] | config schema + gitleaks |
| AC-TRY-003 | 模块采集清单四子模块端点覆盖完整（含 Debt/Revenue/FX 分类映射） | [ ] | collector contract tests |
| AC-TRY-004 | no-lookahead 语义通过（`available_at` 缺失拒绝） | [ ] | visibility tests |
| AC-TRY-005 | raw-first + 多存储链路闭合，失败可回放 | [ ] | integration replay evidence |
| AC-TRY-006 | NATS ingest/control 与 Kafka durable event 分层验证 | [ ] | bus contract tests |
| AC-TRY-007 | API 提供曲线/拍卖/财政/TIC 查询与作业控制 | [ ] | API contract tests |
| AC-TRY-008 | 覆盖率审计发现缺口并生成重采任务闭环，支持增量/全量重同步 | [ ] | coverage report + replay jobs |
| AC-TRY-009 | 边界门禁阻断绕过共享基座直连基础设施 | [ ] | boundary gate report |
| AC-TRY-010 | 宏观分析补充项可用（surprise/期限结构/可持续性/全球比较/质量治理） | [ ] | analytics contract evidence |

## 关键验收阈值

| 维度 | 阈值 |
| ---- | ---- |
| 日频 freshness | `< 24h` |
| 月频 freshness | `< 48h` |
| API 热点查询 P95 | `< 300ms` |
| Kafka publish lag | `< 10s` |
| ClickHouse read model lag | `< 60s` |
| 单轮同步目标耗时 | `<= 30min` |
| 全量重同步兜底 | 每月至少 1 次 |
| 覆盖率审计 | 四子模块采集清单 100% 覆盖 |

## 拒绝发布条件

1. 任一子模块无法独立 C/S 启动。
2. NATS/Kafka 职责混用。
3. `available_at`/`vintage_at` 缺失导致 no-lookahead 破坏。
4. 多存储写入失败仍推进 checkpoint。
5. secret 值出现在文档、日志或配置产物中。
