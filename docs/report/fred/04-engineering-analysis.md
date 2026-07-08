# FRED 模块工程与治理层深度分析报告

**分析日期**：2026-07-08  
**模块版本**：v1.1.0

---

## 执行摘要

`fred` 模块整体处于**工程基础已成形、集成验证存在系统性缺口**的状态。核心风险：

- **5/10 DoD 条款 Pending**（全部依赖 CI dev secret）
- `cmd/*` 入口覆盖率 0%
- evidence 三大子目录（review/release/retrospective）完全缺失
- schema 与 prompt 目录仅有 README 占位
- CHANGELOG 缺乏版本历史且不符合 Conventional Commits 规范
- CI workflow 的 `boundary` 与 `lint` 两个 Job 存在配置缺陷

---

## 一、Design 质量评估

DESIGN.md 共 8 节，覆盖双服务 C/S + NATS handoff、数据流、持久化、无前视语义、一致性/失败处理、可观测性/安全、发布门禁，**逻辑自洽，结构完整**。

### ADR 缺失（重要风险）

`design/` 目录下**不存在任何 ADR 文件**：

| 缺失 ADR | 内容 |
|----------|------|
| ADR-001 | 为何选择 NATS JetStream 而非 Kafka 作为 client→server handoff |
| ADR-002 | TDengine vs InfluxDB/TimescaleDB 时序存储选型 |
| ADR-003 | 双服务 C/S 架构 vs 单进程架构的决策演化（OPEN-007 已关闭但无 ADR） |

---

## 二、Gate 完整性评估

| Gate | 可机器验证 | 状态 |
|---|---|---|
| BG-001 入口存在性 | ✅ | 完整 |
| BG-002 依赖边界 | ✅ | 完整 |
| BG-003 共享基座接入 | ⚠️ 部分 | 仅正向扫描 |
| BG-004 出域模型 | ✅ | 完整 |
| BG-005 raw-first | ⚠️ 部分 | 无独立校验命令 |
| BG-006 适配器层 | ✅ | 覆盖 7 类存储 |
| BG-007 NATS/Kafka 职责分离 | ✅ | 有运行时验证 |
| BG-008 no-lookahead 字段完整 | ✅ | 有单元测试 |
| BG-009 checkpoint 顺序 | ⚠️ 部分 | 无独立 shell 命令 |
| BG-010 Redis/ClickHouse 可重建 | ⚠️ 部分 | CI-gated |
| BG-011 admin API 强鉴权 | ⚠️ 部分 | 仅靠代码审查 |
| BG-012 secret 不落盘 | ✅ | gitleaks-action 完整 |
| BG-013 外部路由不混入完整性断言 | ✅ | 显式包含 |

### 缺失的关键 Gate

| 缺失 Gate | 风险级别 | 建议编号 |
|---|---|---|
| 限流 Gate（30/120 req/min） | P1 | BG-014 |
| 数据质量 Gate（非空率/格式） | P1 | BG-015 |
| Schema 版本兼容 Gate | P2 | BG-016 |
| Coverage 阈值 Gate | P2 | BG-017 |

---

## 三、CI 工作流分析

### 已识别问题

| 问题 | 严重性 | 位置 |
|------|--------|------|
| `boundary` Job 缺少 `setup-go` 步骤，非确定性构建 | P1 | ci-workflow.yaml L85-93 |
| `lint` 仅 `go vet`，缺乏 golangci-lint 静态分析 | P1 | ci-workflow.yaml L83 |
| 无 docs-only PR 路径过滤，文档 PR 触发全量 CI | P1 | ci-workflow.yaml L9-11 |
| `integration` Job 在无 dev secret 时全为 SKIP | P2 | — |
| 无覆盖率阈值守卫 Job，cmd/* 0% 不触发 CI 失败 | P2 | — |

**self-hosted Runner 合规性**：CI Pool（`sre/storage-light`）和 Deploy Pool（`sre/deploy`）配置合规，与仓库 CI 治理规范完全一致。✅

---

## 四、Evidence 评估

```
evidence/
├── README.md                  ✅ 规范完整
└── 2026-07-08/test/           ✅ 唯一证据文件
    review/                    ❌ 缺失
    release/                   ❌ 缺失
    retrospective/             ❌ 缺失
```

### unit-and-gate.log 覆盖率

| 包/组件 | 覆盖率 | 状态 |
|---|---|---|
| `cmd/fred-client` | **0.0%** | ❌ |
| `cmd/fred-server` | **0.0%** | ❌ |
| `internal/client` | 96.4% | ✅ |
| `internal/cs` | 100.0% | ✅ |
| `internal/domain` | 100.0% | ✅ |
| `internal/server` | 84.0% | ⚠️ |
| `internal/store` | 100.0% | ✅ |
| `pkg/fredx` | 78.8% | ⚠️ 低于 80% 基线 |
| boundary-gates | 9 passed, 0 failed | ✅ |

---

## 五、Release DoD 完成状态

| DoD 条款 | 状态 |
|---|---|
| AC-001 服务可启动 | ✅ Passed |
| AC-002 无 secret 值 | ✅ Passed |
| AC-003 七类存储写入闭合 | ❌ Pending（CI-gated） |
| AC-004 Redis 可重建 | ❌ Pending（CI-gated） |
| AC-005 NATS admin trigger | ❌ Pending（CI-gated） |
| AC-006 no-lookahead | ✅ Passed |
| AC-007 边界门禁 | ✅ Passed |
| AC-008 追溯矩阵闭合 | ✅ Passed |
| AC-009 ms_brain 消费契约 | ❌ Pending（OPEN-005） |
| AC-010 全量覆盖审计 | ❌ Pending（OPEN-008） |

**完成比例：5/10（50%）Passed**

---

## 六、关键风险清单

### P0 — 阻断发布

| 编号 | 风险 | 根因 |
|---|---|---|
| R-001 | AC-003/004/005 三项核心 DoD Pending | 集成环境依赖 dev secret，从未端到端验证 |
| R-002 | cmd/* 入口覆盖率 0% | 启动失败无法在 CI 拦截 |
| R-003 | AC-009 ms_brain 消费契约 Pending | ms_brain 无 runtime fixture |

### P1 — 影响质量

| R-004 | `boundary` Job 非确定性 | 缺 setup-go |
|---|---|---|
| R-005 | lint 不完整 | 仅 go vet |
| R-006 | CHANGELOG 缺 v1.0.0 历史 | 变更不可审计 |
| R-007 | evidence review/release/retrospective 缺失 | 证据不完整 |
| R-008 | pkg/fredx 覆盖率 78.8% | 低于 80% 基线 |

---

## 七、改进建议

### P0（Release 前必须完成）

**I-001**：补齐 `cmd/*` 入口单元测试（目标覆盖率 ≥ 50%）

**I-002**：建立 CI 集成验证流水线（OPEN-004 闭环）

**I-003**：补全 evidence 三个子目录（review/release/retrospective）

### P1（质量提升）

**I-004**：修复 `boundary` Job 的 `setup-go` 缺失
```yaml
- uses: actions/setup-go@v5
  with:
    go-version: ${{ env.GO_VERSION }}
    cache: true
```

**I-005**：升级 `lint` Job 为 golangci-lint（errcheck/staticcheck/gosec/revive/govet）

**I-006**：补 CHANGELOG v1.0.0 历史并迁移至 Conventional Commits

**I-007**：添加 docs-only PR 路径过滤
```yaml
paths-ignore: ['**.md', 'docs/**', 'module/fred/evidence/**']
```

### P2（长期改进）

**I-010**：补充 3 个 ADR 文档（NATS/TDengine/双服务决策）

**I-011**：CI 补充覆盖率守卫（pkg/fredx ≥ 85%）

---

## 八、模块专属规范建议（FRED-RULES.md）

**建议创建 `module/fred/FRED-RULES.md`**，覆盖：

```
§1 进程边界不变式
§2 持久化写入顺序规则（raw-first 守恒律）
§3 无前视查询不变式（available_at 闸门）
§4 外部路由序列清单维护规程
§5 NATS/Kafka 职责分层不可逾越条款
§6 cs.IngestEnvelope 契约变更协议（major/minor 版本规则）
§7 ms_brain 下游契约变更通知规程
§8 覆盖率与 Gate 最低阈值
§9 evidence 归档义务（release 必须四子目录完整）
§10 ADR 触发条件（何时必须新建 ADR）
```
