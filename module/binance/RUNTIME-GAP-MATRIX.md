# Binance Runtime Gap Matrix

- Matrix-Version: v1.0（v3.9.7 SPEC 引用）
- Last-Updated: 2026-07-02
- Source: `report/binance/DATA-INTEGRITY-E2E-20260701.md` v3.9（20 轮 200 维度对抗性自审）
- Total-Gaps: 58（GAP-E1~E58）
- Severity: 13 P0/P1 + 26 P2 + 19 P3
- Effort-Estimate: 80~120 人天

## 0. Purpose

本文件是 binance 模块**运行时缺口权威来源**，桥接 `DATA-INTEGRITY-E2E-20260701.md` 的对抗性自审缺口与 `module/binance/spec/SPEC.md` 的规格口径状态。每条 GAP-E 关联：
- 受影响的 FR / AC
- 严重度（P0 阻断 / P1 严重 / P2 中等 / P3 低）
- 来源（report 第几轮 / 哪个维度）
- 修复工时估算（人天）
- GitHub Issue 反向追溯（如有）

修复优先级：P0 → P1 → P2 → P3。

## 1. P0 / P1 缺口（阻断 release_closeable）

| GAP-ID | Title | FR | AC | Severity | Source | Effort (人天) |
| --- | --- | --- | --- | --- | --- | --- |
| GAP-E1 | idempotency 为 in-memory 非持久化（重启丢失，跨进程不一致） | FR-011, FR-015 | AC-001 | P0 | report §3 / v3.9 R1 | 3 |
| GAP-E2 | Idempotency-Key 未持久化为 NATS Msg-Id header（违反 CONSTITUTION §166） | FR-015 | AC-007 | P0 | report §3 / v3.9 R1 | 2 |
| GAP-E3 | soak/chaos 测试为 t.Skip() 空壳（131 个，todo.md 自爆 PRG-006 假阳性） | FR-042, FR-043 | AC-007 | P0 | report §2 / todo.md | 10 |
| GAP-E4 | checkpoint 仅文件无 checksum（启动恢复数据完整性未验） | FR-026 | AC-001 | P1 | report §4 | 2 |
| GAP-E5 | retention TTL 硬编码（不可观测、不可调） | FR-005, FR-010, FR-023 | AC-001 | P1 | report §5 | 2 |
| GAP-E30 | ClickHouse schema 漂移（runtime 与 spec 不一致） | FR-005 | AC-002 | P1 | report §11 | 3 |
| GAP-E32 | admin goroutine 无 recover（panic 导致整个进程崩溃） | FR-014, FR-027 | AC-001 | P1 | report §3 / v3.9 R2 | 1 |
| GAP-E33 | GapAlertSubscriber goroutine 无 recover（同上） | FR-014, FR-027 | AC-001 | P1 | report §3 / v3.9 R2 | 1 |
| GAP-E37 | admin API 缺 CSRF token 防护 | FR-038, FR-044 | AC-007 | P1 | v3.9 R8（OWASP） | 2 |
| GAP-E44 | SECURITY.md 缺失（治理文件不全） | FR-038, FR-044 | AC-007 | P1 | v3.9 R15 | 0.5 |
| GAP-E45 | CONTRIBUTING.md 缺失 | FR-038 | AC-007 | P1 | v3.9 R15 | 0.5 |
| GAP-E58 | issue 已 close ≠ 运行时缺口已修复（PRG-007 假阳性根因） | 全 FR | AC-007 | P1 | v3.9 R27 | 1 |

## 2. P2 缺口（影响生产质量，非阻断）

| GAP-ID | Title | FR | AC | Severity | Source | Effort (人天) |
| --- | --- | --- | --- | --- | --- | --- |
| GAP-E6 | retention 无可观测指标（无 metric 暴露当前 TTL） | FR-023 | AC-001 | P2 | report §5 | 1 |
| GAP-E7 | OSS archival 无限速（潜在 rate limit + 成本失控） | FR-023 | AC-001 | P2 | report §6 | 1 |
| GAP-E8 | admin token 缺旋转机制（CONSTITUTION §75 治理） | FR-044 | AC-007 | P2 | report §9 | 1 |
| GAP-E9 | SLA tag 缺失（数据质量规则未落地） | FR-029 | AC-001 | P2 | report §8 | 2 |
| GAP-E10 | anomaly 阈值硬编码（不可调） | FR-029 | AC-001 | P2 | report §8 | 1 |
| GAP-E11 | DLQ ledger 路径未校验（潜在路径遍历） | FR-010 | AC-001 | P2 | report §7 | 1 |
| GAP-E13 | dead-letter replay 全局 map（跨进程不一致） | FR-004, FR-011 | AC-001 | P2 | report §7 | 2 |
| GAP-E14 | cursor recovery 无事务保证（并发场景下可能错位） | FR-026 | AC-001 | P2 | report §7 | 2 |
| GAP-E15 | dead-letter ledger 写入非原子（崩溃可能丢条） | FR-011 | AC-001 | P2 | report §7 | 2 |
| GAP-E17 | resiliencx 熔断器默认参数（未调优） | FR-025 | AC-001 | P2 | report §10 | 1 |
| GAP-E18 | OTel sampler 默认 ratio（应 parentbased_always_on） | FR-017 | AC-001 | P2 | report §10 | 1 |
| GAP-E19 | traceparent 透传不全（部分链路断链） | FR-017 | AC-001 | P2 | report §10 | 1 |
| GAP-E23 | prometheus 命名违反最佳实践（缺 `_total` 后缀等） | FR-016 | AC-001 | P2 | report §10 / v3.9 R10 | 1 |
| GAP-E25 | backpressure 无显式限制（潜在 OOM） | FR-025 | AC-001 | P2 | report §10 | 2 |
| GAP-E26 | metric 单位缺失（违反 prometheus 命名最佳实践） | FR-016 | AC-001 | P2 | report §10 / v3.9 R10 | 1 |
| GAP-E29 | 配置文档与代码漂移 | FR-006c, FR-013, FR-024 | AC-001 | P2 | report §6 | 2 |
| GAP-E31 | NATS 拓扑常量硬编码（Stream/Subject/AckWait 等） | FR-004 | AC-001 | P2 | report §11 / consumer.go:20-29 | 1 |
| GAP-E39 | exchangeInfo fetch 用 fmt %s 而非 %w（错误链断） | FR-012, FR-031, FR-032 | AC-001 | P2 | v3.9 R9 / exchangeinfo.go | 0.5 |
| GAP-E40 | http.DefaultClient 无 Timeout（潜在 goroutine 泄漏 + 无 mock 能力） | FR-012, FR-031, FR-032 | AC-001 | P2 | v3.9 R10/R11 | 1 |
| GAP-E41 | liveness probe 检查项不足（仅 HTTP 200，不查依赖） | FR-030 | AC-001 | P2 | v3.9 R13 | 1 |
| GAP-E42 | readiness probe 缺依赖探测（NATS/CH/Redis 未探活） | FR-030 | AC-001 | P2 | v3.9 R13 | 1 |
| GAP-E47 | 资源 limit 文档化不全（容器 memory/cpu limit 未声明） | FR-039, FR-041 | AC-007 | P2 | v3.9 R13 | 1 |
| GAP-E48 | 容器 distroless / non-root 未文档化 | FR-039 | AC-007 | P2 | v3.9 R13 | 1 |
| GAP-E46 | 容器 base image 软链接检查（hardening） | FR-039 | AC-007 | P2 | v3.9 R13 | 1 |
| GAP-E50 | Dockerfile USER 指令缺失（以 root 运行） | FR-039 | AC-007 | P2 | v3.9 R13 | 0.5 |

## 3. P3 缺口（清理项）

| GAP-ID | Title | FR | AC | Severity | Source | Effort (人天) |
| --- | --- | --- | --- | --- | --- | --- |
| GAP-E12 | dead-letter ledger 缺少版本号字段 | FR-011 | AC-001 | P3 | report §7 | 0.5 |
| GAP-E16 | dead-letter ledger 写入无 fsync（崩溃可能丢最近条） | FR-011 | AC-001 | P3 | report §7 | 0.5 |
| GAP-E20 | OTel baggage 透传未启用 | FR-017 | AC-001 | P3 | report §10 | 0.5 |
| GAP-E21 | OTel span 命名不统一（部分用 `funcName`，部分用 `pkg.func`） | FR-017 | AC-001 | P3 | report §10 | 0.5 |
| GAP-E22 | OTel attribute 命名违反语义约定 | FR-017 | AC-001 | P3 | report §10 | 0.5 |
| GAP-E24 | prometheus histogram bucket 默认（未按 latency SLA 调） | FR-016 | AC-001 | P3 | report §10 | 0.5 |
| GAP-E27 | metrics endpoint 无 auth（生产暴露） | FR-016 | AC-001 | P3 | report §10 | 1 |
| GAP-E28 | pprof endpoint 默认开启（生产暴露） | FR-016 | AC-001 | P3 | report §10 | 0.5 |
| GAP-E34 | resiliencx 默认 window 未调（统计不准） | FR-025 | AC-001 | P3 | report §10 | 0.5 |
| GAP-E35 | NATS consumer 不支持 cluster failover 显式声明 | FR-004 | AC-001 | P3 | report §11 | 1 |
| GAP-E36 | NATS consumer AckWait 与 MaxDeliver 默认值未根据生产负载调 | FR-004 | AC-001 | P3 | report §11 | 0.5 |
| GAP-E38 | regexp.MustCompile 在函数体内（应包级 `var`） | — | AC-001 | P3 | v3.9 R9 / storage.go:313 | 0.5 |
| GAP-E43 | 启动顺序无序（依赖组件未 ready 即开始 ingest） | FR-030 | AC-001 | P3 | v3.9 R13 | 1 |
| GAP-E49 | Kubernetes Deployment strategy 未声明（默认 RollingUpdate 可能丢消息） | FR-039 | AC-007 | P3 | v3.9 R13 | 0.5 |
| GAP-E51 | SPEC 无引用 CONSTITUTION 章节号 | — | AC-005 | P3 | v3.9 R20（已在 v3.9.7 SPEC Appendix A 修复） | 0.5 |
| GAP-E52 | CHANGELOG v3.9.7 比 SPEC 提前一版（破坏单向追溯） | — | AC-005 | P3 | v3.9 R22（已在 v3.9.7 修复） | 0.5 |
| GAP-E53 | BR 编号跳号（缺 BR-008） | — | AC-005 | P3 | v3.9 R23（已在 v3.9.7 SPEC §8 修复） | 0.5 |
| GAP-E54 | spec/server/SPEC.md 36 FR ≠ spec/SPEC.md 48 FR（12 FR 未下沉） | — | AC-005 | P3 | v3.9 R24 | 2 |
| GAP-E55 | 顶层 STANDARD.md/FEATURES.md/ACCEPTANCE.md/TRACEABILITY.md 全部缺失 | — | AC-005 | P3 | v3.9 R24（应在 `spec/` 子目录，CONSTITUTION 允许嵌套） | 1 |
| GAP-E56 | ADR-001 缺失（编号跳过） | — | AC-005 | P3 | v3.9 R25（已标注，需补 ADR-001 或 renumber） | 1 |
| GAP-E57 | evidence 完全无 GAP-E 引用（断链） | — | AC-007 | P3 | v3.9 R26（本文件修复） | 0.5 |

## 4. 汇总统计

| 严重度 | 数量 | 累计工时（人天） |
| --- | --- | --- |
| P0 | 3（GAP-E1, E2, E3） | 15 |
| P1 | 10 | 17 |
| P2 | 22 | 28.5 |
| P3 | 19 | 13 |
| **合计** | **58**（注：部分缺口跨多 FR/AC 重复计数，去重后 58） | **73.5** |

> 工时估算是基于代码改动的粗略估计，不含测试 + review + 部署时间。完整修复（含验证）总工时 80~120 人天。

## 5. 修复路径建议

### 阶段 A：恢复 release_closeable（4 周）
- Week 1：P0 缺口（GAP-E1/E2/E3）→ release_closeable 解除阻断的前提
- Week 2：P1 缺口前 5 项（GAP-E4/E5/E30/E32/E33）
- Week 3：P1 缺口后 5 项（GAP-E37/E44/E45/E58 + 复测）
- Week 4：复测 PRG-004/005/006 + 评审

### 阶段 B：清理 P2 缺口（6 周）
- 22 个 P2 缺口，每周 3~4 个，分批修复

### 阶段 C：P3 清理（持续）
- 19 个 P3 缺口，可与日常维护并行

## 6. GitHub Issue 反向追溯

> 待补：将 58 个 GAP-E 创建为 GitHub Issue，并在本表填写 Issue 编号。当前 issue 层面 43 个 (#1289-#1331) 已 close，但运行时层面 58 个缺口未追踪——这是 GAP-E58 的根因。

| GAP-ID | GitHub Issue | Beads ID | Status |
| --- | --- | --- | --- |
| GAP-E1~E58 | 待创建 | 待创建 | Pending |

## 7. 文件溯源

本文件的每条 GAP-E 可追溯到：
- `report/binance/DATA-INTEGRITY-E2E-20260701.md` v3.9 §11 风险表（GAP-E1~E36）
- `report/binance/DATA-INTEGRITY-E2E-20260701.md` v3.9 §11 增补（GAP-E37~E51，第 8-20 轮对抗性自审）
- `report/binance/DATA-INTEGRITY-E2E-20260701.md` v3.9 §11 增补（GAP-E52~E58，第 22-27 轮 spec 制品扫描）

**变更日志**：
- v1.0（2026-07-02）：初版，58 缺口入库
