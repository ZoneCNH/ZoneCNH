# Binance SPEC

- Spec-Version: v3.9.7
- Module: binance
- Last-Updated: 2026-07-02
- Runtime-Repo: `/home/workspace/binance`
- Runtime-Version: v0.8.0
- State-Model: single-state only
- Current-State: 22 Done / 15 Partial / 11 Drifted / 0 Pending
- release_closeable: NO（运行时缺口 58 项未闭合，详见 `module/binance/RUNTIME-GAP-MATRIX.md`）
- Open-P10-Issues: 58（GAP-E1~E58，源自 `report/binance/DATA-INTEGRITY-E2E-20260701.md` v3.9 对抗性自审）

## 1. Goal

`binance` 提供 Binance 市场数据 ingestion、规范化、持久化、查询与生产就绪治理入口。本版本（v3.9.7）将规格与运行时事实对齐：基于 `DATA-INTEGRITY-E2E-20260701.md` v3.9 的 20 轮 200 维度对抗性自审，识别 58 个运行时缺口，全面降级 `release_closeable` 至 NO，重映射 48 FR 状态。

本规格遵循 `CONSTITUTION.md` §75（client 不写数据库）、§166（幂等键 / Idempotency-Key）、§509（NATS JetStream 契约）、§7（分级采集 + 水平扩展）、§8（分级 ID 体系）、§9（产品线/event_type 白名单）、§10.4（Spec Appendix 版本同步规则）。

## 2. Authority

| 层级 | 权威 |
| --- | --- |
| 最高治理 | `CONSTITUTION.md`（§0~§20，章节视图见 `docs/constitution/`） |
| 模块规格 | 本文件 |
| 运行时缺口权威 | `module/binance/RUNTIME-GAP-MATRIX.md`（58 个 GAP-E × FR × AC × 严重度 × 工时） |
| 追溯矩阵 | `module/binance/matrix/TRACEABILITY.md` |
| 对抗性自审报告 | `report/binance/DATA-INTEGRITY-E2E-20260701.md` v3.9 |
| issue 投影 | Beads 与 GitHub issue 为当前 SSOT；历史本地投影归档于 `module/binance/evidence/2026-06-28/todo-archived.md` |
| 配置 schema | `module/binance/design/CONFIG-SCHEMA.md` |
| runtime 证据 | `/home/workspace/binance` 的测试、脚本、tag、CI/release evidence |

## 3. Scope

包含 client ingestion、server consumer/query、shared DTO validation、NATS JetStream contract、ClickHouse persistence、REST/Admin API、ExchangeInfo catalog、observability/security/deploy readiness 的规格要求。不包含交易下单、账户管理、私有交易策略或生产凭证。

## 4. Runtime Boundary

| 子系统 | 职责 | 禁止 |
| --- | --- | --- |
| `internal/client` | 连接 Binance、公有市场流转换、发布 envelope | 依赖 server 包、写数据库（CONSTITUTION §75）、暴露生产 `/ingest` |
| `internal/server` | 消费 NATS、校验、持久化、查询 API | 连接 Binance WS、持有 client-only 配置 |
| `internal/wire` | shared DTO、topic/subject schema、validation、smoke-only transport | 承载业务流程、持久化、生产入口 |
| `configs/*.env.example` | 参数示例与默认边界 | 写入真实凭证 |

## 5. State Model

只允许单一状态：`Done` / `Partial` / `Drifted` / `Pending`。历史 `Code-State` / `Evidence-State` 双态口径已废除（CONSTITUTION §10.4）。

**v3.9.7 状态重映射**（基于 `RUNTIME-GAP-MATRIX.md` 58 缺口）：
- Done：22 个 FR（规格与运行时一致，无运行时缺口）
- Partial：15 个 FR（运行时存在 1~3 个 P2/P3 缺口，可生产但需治理）
- Drifted：11 个 FR（运行时存在 P0/P1 缺口或规格运行时漂移）
- Pending：0 个

参见 `TRACEABILITY.md §1`（FR 状态）+ `RUNTIME-GAP-MATRIX.md`（缺口映射）。

## 6. Product Lines and Event Types

遵循 `CONSTITUTION.md` §9（产品线/event_type 白名单）：

| 维度 | 允许值 |
| --- | --- |
| product_line | `spot`, `um_perp`, `cm_perp`, `options` |
| event_type | `tick`, `bar`, `depth`, `trade`, `funding_rate`, `mark_price` |
| identity | exchange + product_line + instrument_type + instrument_subtype + symbol + expiry + strike + option_type |
| kline interval | 15 个 Binance REST 标准 interval（CONSTITUTION §7.x，v3.6 用户裁决） |

## 7. Functional Requirements

> 状态口径：Done = 规格与运行时一致；Partial = 运行时有 P2/P3 缺口；Drifted = 运行时有 P0/P1 缺口或规格漂移。详细证据见 `RUNTIME-GAP-MATRIX.md`。

| ID | Scope | Requirement | State | Closure evidence |
| --- | --- | --- | --- | --- |
| FR-001 | client | ingest public tick/trade-like stream and normalize envelope | Done | local runtime + E2E history |
| FR-002 | client | ingest kline/bar stream and normalize envelope | Done | local runtime + E2E history |
| FR-003 | contract | publish to NATS subject `binance.market.{product_line}.{event_type}.v1` | Done | drift-check 22/22 PASS + publisher `.v1` fix |
| FR-004 | server | consume JetStream independently from client process | Partial | GAP-E31 NATS 拓扑常量硬编码；GAP-E13 全局 map replay |
| FR-005 | server | persist ticks to ClickHouse schema | Drifted | GAP-E5 retention TTL 硬编码；GAP-E30 ClickHouse schema 漂移 |
| FR-006a | client | provide client CLI/config loading | Done | runtime config examples |
| FR-006b | server | provide server CLI/config loading | Done | runtime config examples |
| FR-006c | config | shared env validation and deterministic defaults | Partial | GAP-E29 配置文档与代码漂移 |
| FR-006d | smoke | local-only smoke path remains non-production | Done | `/ingest` smoke-only gate |
| FR-007 | API | query tick data through REST | Done | REST API + analytics tests PASS |
| FR-007a | replay | historical replay/import path | Done | analytics tests PASS + history_lifecycle.go |
| FR-008 | client | ingest depth stream | Done | local runtime + E2E history |
| FR-009 | client | ingest aggregate trade stream | Done | local runtime + E2E history |
| FR-010 | server | persist/query bar aggregates | Partial | GAP-E5 retention；GAP-E11 DLQ ledger 路径未校验 |
| FR-011 | reliability | delayed retry, parking, dead-letter behavior | Drifted | GAP-E1 idempotency in-memory 非持久；GAP-E13 全局 map；GAP-E15 dead-letter ledger 非原子 |
| FR-012 | catalog | ExchangeInfo catalog refresh | Partial | GAP-E39/E40 fetch exchangeInfo 用 http.DefaultClient + fmt %s |
| FR-013 | control | whitelist/blacklist hot reload | Partial | GAP-E29 配置漂移 |
| FR-014 | ops | graceful shutdown and drain | Drifted | GAP-E32 admin goroutine 无 recover；GAP-E33 GapAlertSubscriber 无 recover |
| FR-015 | identity | stable idempotency/event keys | Drifted | GAP-E1 idempotency in-memory；GAP-E2 Idempotency-Key 非持久化；CONSTITUTION §166 |
| FR-016 | observability | metrics exporter coverage | Partial | GAP-E23 prometheus 命名违反最佳实践；GAP-E26 metric 单位缺失 |
| FR-017 | observability | trace propagation and OTel visibility | Partial | GAP-E18 OTel sampler 默认 ratio；GAP-E19 traceparent 透传不全 |
| FR-018 | API | query bars through REST | Done | local runtime evidence |
| FR-019 | API | query depth through REST | Done | local runtime evidence |
| FR-020 | API | query funding-rate data | Done | local runtime/docs |
| FR-021 | API | query mark-price data | Done | local runtime/docs |
| FR-022 | identity | distinguish spot/perp/delivery/options instruments | Done | DTO/schema evidence |
| FR-023 | lifecycle | retention, TTL, archival policy | Drifted | GAP-E5 TTL 硬编码；GAP-E6 retention 无可观测；GAP-E7 OSS archival 无限速 |
| FR-024 | control | symbol-change control subject and reload | Partial | GAP-E29 配置漂移 |
| FR-025 | reliability | backpressure and reconnect limits | Partial | GAP-E17 resiliencx 熔断器默认参数；GAP-E25 backpressure 无显式限制 |
| FR-026 | recovery | checkpoint recovery after restart | Drifted | GAP-E4 checkpoint 仅文件无 checksum；GAP-E14 cursor recovery 无事务保证 |
| FR-027 | client | multi-product websocket lifecycle | Partial | GAP-E32/E33 goroutine 无 recover |
| FR-028 | errors | normalized error taxonomy | Done | quality.go + error taxonomy |
| FR-029 | data quality | anomaly/SLA tags and quality rules | Partial | GAP-E9 SLA tag 缺失；GAP-E10 anomaly 阈值硬编码 |
| FR-030 | admin | health/readiness/admin status | Drifted | GAP-E41 liveness 检查项不足；GAP-E42 readiness 缺依赖探测；GAP-E43 启动顺序无序 |
| FR-031 | catalog | full ExchangeInfo sync | Partial | GAP-E39/E40 fetch 用 DefaultClient |
| FR-032 | catalog | diff ExchangeInfo sync | Partial | GAP-E39/E40 同上 |
| FR-033 | catalog | delist handling | Done | exchangeinfo.go symbols BREAK/HALT/DELTED lifecycle |
| FR-034 | identity | InstrumentKey stability | Done | product_line.go + DTO validation |
| FR-035 | identity | delivery expiry metadata | Done | exchangeinfo_option.go delivery metadata |
| FR-036 | identity | options metadata | Done | exchangeinfo_option.go (111 lines) |
| FR-037 | smoke | `/ingest` returns 404 in production, enabled only for local smoke | Done | boundary gate + runtime route |
| FR-038 | security | credential rotation runbook and implementation | Drifted | GAP-E37 CSRF token 缺失；GAP-E44 SECURITY.md 缺失；GAP-E45 CONTRIBUTING.md 缺失 |
| FR-039 | deployment | HA/DR deployment documentation | Partial | GAP-E46~E50 容器/资源/lifecycle |
| FR-040 | release | canary deployment exercise | Done | canary drill script |
| FR-041 | capacity | capacity planning and load model | Partial | GAP-E41/E42 资源限制文档化不全 |
| FR-042 | quality | soak test | Drifted | GAP-E3 soak 测试 2min 不足；todo.md 自爆 PRG-006 假阳性 |
| FR-043 | quality | chaos test | Drifted | GAP-E3 chaos 不注入真实故障；todo.md 自爆 |
| FR-044 | security | admin auth, mTLS, scan gates, pentest readiness | Drifted | GAP-E37 CSRF；GAP-E44 SECURITY.md；GAP-E8 admin token 旋转 |

## 8. Business Requirements

> BR 编号历史跳号问题（缺 BR-008，BR-009/010 跨文件存在）已在 v3.9.7 修复——保留原 BR-001~005 作为规格核心，BR-006/007/008/009/010 归档至 FEATURES.md 边界声明。

| ID | Requirement | Covered FR |
| --- | --- | --- |
| BR-001 | market facts are normalized once and reusable downstream | FR-001~005, FR-015, FR-022 |
| BR-002 | client/server can be operated independently（CONSTITUTION §75） | FR-004, FR-006a, FR-006b, FR-014 |
| BR-003 | data contracts are explicit and versioned（CONSTITUTION §509） | FR-003, FR-015, FR-029 |
| BR-004 | market catalog changes do not require manual schema edits | FR-012, FR-031~036 |
| BR-005 | production promotion requires observable, secure, repeatable operation | FR-016~017, FR-038~044 |

## 9. Acceptance Criteria

> 42 AC 全部基于"规格口径"通过，但不覆盖运行时缺口（详见 `ACCEPTANCE.md §5`）。运行时缺口由 58 个 GAP-E 单独追踪。

| AC | Requirement | State |
| --- | --- | --- |
| AC-001 | runtime tests pass before local completion claims | Done（规格口径） |
| AC-002 | `scripts/spec-runtime-drift-check.sh` passes in `/home/workspace/binance` | Done（22/22 PASS） |
| AC-003 | active docs use only `binance.market.{product_line}.{event_type}.v1` for market subjects（CONSTITUTION §509） | Done |
| AC-004 | production `/ingest` is disabled or 404 | Done |
| AC-005 | `SPEC.md` remains compact; detailed parameter tables live in design docs | Done |
| AC-006 | `TRACEABILITY.md` remains compact and references history instead of duplicating it | Done |
| AC-007 | issue closeability requires issue-level evidence, not local inference | Drifted（issue 已 close 但运行时缺口未闭合，GAP-E58） |
| AC-008~AC-042 | （详见 `ACCEPTANCE.md §2`） | Done（规格口径） |

## 10. NATS and Kafka Contracts

遵循 `CONSTITUTION.md` §509（NATS JetStream 契约）：

| Bus | Canonical pattern | Notes |
| --- | --- | --- |
| NATS JetStream | `binance.market.{product_line}.{event_type}.v1` | stream `BINANCE_MARKET`；version suffix mandatory |
| Kafka optional bridge | `binance.{product_line}.{event_type}.v1` | bridge-only; not a replacement for NATS Contract |
| Control | `binance.control.instruments.changed`, `binance.control.symbols.changed` | no market payloads |
| Idempotency-Key | NATS header `Nats-Msg-Id` 必须为 Idempotency-Key（CONSTITUTION §166） | GAP-E2 当前为内存 hash |

## 11. Configuration

Configuration parameters are owned by `module/binance/design/CONFIG-SCHEMA.md` and projected into `/home/workspace/binance/configs/binance-client.env.example` and `/home/workspace/binance/configs/binance-server.env.example`。GAP-E29 配置文档与代码存在漂移，需修复。

## 12. API Boundary

| Route family | Role | State |
| --- | --- | --- |
| `GET /api/v1/market/ticks/:symbol` | query tick facts | Done |
| `GET /api/v1/market/bars/:symbol` | query bars | Done |
| `GET /api/v1/market/depth/:symbol` | query depth | Done |
| `GET /api/v1/market/funding-rate/:symbol` | query funding rate | Done |
| `GET /api/v1/market/mark-price/:symbol` | query mark price | Done |
| `POST /ingest` | local smoke only; production must return 404 | Done |
| Admin API | mTLS + Bearer token（GAP-E37 CSRF token 缺失） | Partial |

## 13. Persistence Boundary

ClickHouse tables must use stable instrument identity, event timestamp, ingestion timestamp, source sequence where available, payload checksum, and schema version。GAP-E5（TTL 硬编码）、GAP-E6（retention 无可观测）、GAP-E30（schema 漂移）需修复。

**client 永远不写数据库**（CONSTITUTION §75）。所有持久化由 server 承担。

## 14. Directory Structure

| Path | Role |
| --- | --- |
| `goal/` | module goal |
| `spec/` | current specs（含 `SPEC.md` / `ACCEPTANCE.md` / `FEATURES.md` / `client/` / `server/`） |
| `design/` | architecture and extracted detail tables（ADR-002~004，GAP-E56 ADR-001 缺失） |
| `matrix/` | traceability SSOT |
| `tasks/` | task specs |
| `prompt/` | context packages |
| `evidence/` | dated evidence and reviews |
| `gate/` | boundary rules and gates（6 文件齐全） |
| `RUNTIME-GAP-MATRIX.md` | 运行时缺口矩阵（v3.9.7 新增） |
| `CHANGELOG.md` | 变更日志 |

Deprecated root spec files were physically deleted in v3.9.5; history is recovered through git, not active files.

## 15. Testing

Minimum local proof for this SPEC revision:

```bash
cd /home/workspace/binance
bash -n scripts/spec-runtime-drift-check.sh
scripts/spec-runtime-drift-check.sh
go test ./...

cd /home/workspace/ZoneCNH
git diff --check
wc -l module/binance/spec/SPEC.md module/binance/matrix/TRACEABILITY.md
```

**v3.9.7 新增要求**：`todo.md` 已自爆 PRG-006 soak/chaos 测试为空壳（131 个 `t.Skip()`），GAP-E3 需在补齐 Phase 1-3 后才能恢复 release_closeable=YES。

## 16. Observability

Metrics, logs, tracing, dashboards, alerts 已部署（Jaeger 16686 / Grafana 3000 / Loki 3100 / AlertManager 9093，2026-06-30 验证在线）。但：
- GAP-E23：prometheus 命名违反最佳实践（`_total` 后缀缺失等）
- GAP-E26：metric 单位缺失
- GAP-E18：OTel sampler 默认 ratio（应 parentbased_always_on）
- GAP-E19：traceparent 透传不全

PRG-004 状态：Partial（待 GAP-E18/E19/E23/E26 修复后恢复 PASS）。

## 17. Security

Production closeability requires:
- ✅ credential rotation runbook（508 行）
- ❌ CSRF token on admin API（GAP-E37）
- ✅ secrets scanning（gitleaks）
- ✅ vulnerability scanning（govulncheck）
- ✅ admin auth（Bearer token）
- ❌ admin token 旋转机制（GAP-E8）
- ❌ mTLS enforcement 实证（GAP-E44 SECURITY.md 缺失）
- ❌ CONTRIBUTING.md（GAP-E45）

PRG-005 状态：Drifted。

## 18. Deployment

HA/DR, canary, capacity, soak, chaos evidence 部分就位：
- ✅ canary drill script（FR-040 Done）
- ✅ HA/DR docs（7 docs）
- ❌ 容器 distroless / non-root（GAP-E46）
- ❌ 资源 limit 文档化（GAP-E47/E48）
- ❌ liveness/readiness probe 配置（GAP-E41/E42）
- ❌ 启动顺序（GAP-E43）

PRG-006 状态：Drifted（todo.md 已自爆 soak/chaos 假阳性）。

## 19. Traceability

Canonical FR/BR/AC mapping is in `module/binance/matrix/TRACEABILITY.md`。本文件 §7 与 TRACEABILITY.md §1 的 FR 状态必须一致。运行时缺口映射在 `RUNTIME-GAP-MATRIX.md`。

**v3.9.7 修复**：
- TRACEABILITY.md §1 新增 Runtime-Gap 列（与 Done/Partial/Drifted/Pending 平级）
- §6 仪表盘 FR 实现状态从 §1 派生（CLAUDE.md §5.1）

## 20. Issue Alignment

`module/binance/evidence/2026-06-28/todo-archived.md` preserves the retired local P10 action projection。GitHub issue numbers and Beads ids 当前状态：
- 43 GitHub (#1289-#1331) + 43 Beads P10 issues 全部关闭（issue 层面）
- 但运行时层面 58 个 GAP-E 未闭合（GAP-E58: issue 已 close ≠ 运行时缺口已修复）

`module/binance/RUNTIME-GAP-MATRIX.md` 提供 GAP-E → GitHub Issue 的反向追溯，避免 issue 关闭后运行时缺口被遗忘。

## 21. Release Gate

**Current release gate verdict: `release_closeable=NO`**（v3.9.7 全面降级）

降级原因：
- 48 FR 中仅 22 Done / 15 Partial / 11 Drifted（Done 率 46%，远低于 90% 阈值）
- 58 个运行时缺口（13 P0/P1 + 26 P2 + 19 P3）未闭合
- todo.md 自爆 PRG-006 soak/chaos 假阳性

PRG-001~007 当前状态：

| PRG | v3.9.6 声称 | v3.9.7 实际 | 降级原因 |
| --- | --- | --- | --- |
| PRG-001 CI runner | PASS | PASS | 实证 ubuntu-latest 已迁移 |
| PRG-002 Release tag | PASS | PASS | v0.8.0 已发布 |
| PRG-003 综合 | PASS | **FAIL** | PRG-004/005/006 实际为 Partial/Drifted |
| PRG-004 可观测性 | PASS | **Partial** | GAP-E18/E19/E23/E26 |
| PRG-005 安全 | PASS | **Drifted** | GAP-E37/E44/E45/E8 |
| PRG-006 soak/chaos | PASS | **Drifted** | todo.md 自爆 131 个 t.Skip() |
| PRG-007 issue closure | PASS | **Partial** | issue 已 close 但 GAP-E58 运行时缺口未闭合 |

恢复路径：
1. 补齐 RUNTIME-GAP-MATRIX.md 58 个缺口（按 P0 → P1 → P2 → P3 顺序）
2. 修复 PRG-004/005/006 至 PASS
3. 复跑 soak/chaos 真实故障注入
4. 重新评审 release_closeable

## 22. Change History

| Version | Date | Change |
| --- | --- | --- |
| v3.9.7 | 2026-07-02 | 基于 `DATA-INTEGRITY-E2E-20260701.md` v3.9 对抗性自审（20 轮 200 维度）全面降级 release_closeable；48 FR 状态重映射；新增 RUNTIME-GAP-MATRIX.md 引用；修复 BR-008 跳号；补全 CONSTITUTION §75/§166/§509/§7/§8/§9 章节引用；修复 ADR-001 缺失标注；修复 CHANGELOG 提前一版问题 |
| v3.9.6 | 2026-06-28 | compact SPEC, issue projection alignment, `.v1` subject enforcement |
| v3.9.5 | 2026-06-28 | deprecated spec files physically deleted |
| v3.9.4 | 2026-06-28 | structural score gate repair |

> DoD 标题版本号与 Spec-Version 一致（v3.9.7），遵循 CLAUDE.md §5.3。

## 23. Stop Condition

**当前（v3.9.7）：未达到 Stop Condition。**

恢复 Stop Condition 需要：
1. RUNTIME-GAP-MATRIX.md 中 58 个 GAP-E 全部闭合（issue-level evidence）
2. PRG-001~007 全部 PASS（含 PRG-006 真实故障注入复测）
3. 48 FR 中 Done ≥ 43（当前 22，需再修 21 个 FR 至 Done，达 90% 阈值）
4. release_closeable 恢复 YES

本 Stop Condition 遵循 `CONSTITUTION.md` §10.4（Spec 制品 stop condition 规则）。

---

## Appendix A. CONSTITUTION 章节引用清单（v3.9.7 新增，修复 GAP-E51）

本规格显式引用以下 `CONSTITUTION.md` 章节：

| CONSTITUTION 章节 | 引用位置 | 主题 |
| --- | --- | --- |
| §0 | §分支纪律 | 分支保护 |
| §7 | §6 / §8 | 分级采集 + 水平扩展 |
| §8 | §6 | 分级 ID 体系 |
| §9 | §6 | 产品线/event_type 白名单 |
| §10.4 | §5 / §22 / §23 | Spec Appendix 版本同步 |
| §75 | §4 / §8 / §13 | client 不写数据库 |
| §166 | §7 FR-015 / §10 | 幂等键 / Idempotency-Key |
| §509 | §8 BR-003 / §10 | NATS JetStream 契约 |

## Appendix B. 运行时缺口摘要（v3.9.7 新增）

详见 `module/binance/RUNTIME-GAP-MATRIX.md`。摘要：
- **总缺口数**：58（GAP-E1~E58）
- **来源**：`report/binance/DATA-INTEGRITY-E2E-20260701.md` v3.9 对抗性自审（20 轮 200 维度）
- **严重度分布**：13 P0/P1 + 26 P2 + 19 P3
- **修复工时估算**：约 80~120 人天

> 本 Appendix 仅覆盖全部 58 缺口的摘要；权威来源为 `RUNTIME-GAP-MATRIX.md`，避免重复定义。
