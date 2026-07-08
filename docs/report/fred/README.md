# FRED 模块深度分析报告总览

**分析日期**：2026-07-08  
**模块版本**：v1.1.0（registry lifecycle: proposed）  
**运行时仓库**：https://github.com/ZoneCNH/fred（Go，34 文件，v0.1.1 release）  
**分析方法**：4 个并行 Agent 独立分析，结果汇总

---

## 报告目录

| 文件 | 分析层 | 核心发现 |
|---|---|---|
| [01-spec-analysis.md](01-spec-analysis.md) | 需求层（Goal/Spec/SERIES-API/CATALOG） | 综合 87/100，4 个 P0 问题 |
| [02-matrix-analysis.md](02-matrix-analysis.md) | 追溯矩阵层（TRACEABILITY） | 覆盖率 100%，5 类结构缺陷 |
| [03-plan-analysis.md](03-plan-analysis.md) | 计划与任务层（PLAN/TASK） | 缺失 6 个 Task，prompt 目录空置 |
| [04-engineering-analysis.md](04-engineering-analysis.md) | 工程与治理层（DESIGN/GATE/CI/Evidence） | DoD 5/10 Pending，cmd/* 覆盖率 0% |
| [05-fred-rules-proposal.md](05-fred-rules-proposal.md) | 模块规范建议（FRED-RULES.md 草稿） | 10 节专属规范建议 |

---

## 综合评分

| 维度 | 得分 | 关键问题 |
|---|---|---|
| 需求层质量 | 87/100 | Goal Status 过期，FR-C007/C008 孤儿，别名不一致 |
| 追溯矩阵质量 | 82/100 | §1/§4 内部矛盾，子矩阵状态冻结，AC-008 孤儿 |
| 计划与任务质量 | 65/100 | 缺 Scope 节/验证命令节，FR 编号孤岛，缺失 6 个 Task |
| 工程与治理质量 | 70/100 | DoD 50%，cmd/* 0%，CI 配置缺陷，evidence 不完整 |
| **综合** | **76/100** | **工程验证是最大短板** |

---

## 全局 P0 问题清单（必须立即处理）

| # | 问题 | 归属层 | 具体位置 |
|---|---|---|---|
| G-P0-01 | Goal Status: Draft（已实施但未更新）| 需求层 | `goal/goal.md` |
| G-P0-02 | FR-C007 无对应 AC（fail-fast 行为无验收标准）| 需求层 | `spec/client/SPEC.md §6` |
| G-P0-03 | FR-C008 无对应 AC（日志/指标关联字段无验收标准）| 需求层 | `spec/client/SPEC.md §6` |
| G-P0-04 | TC-011/V-017 在 ACCEPTANCE.md 缺失（悬空引用）| 需求层 | `spec/ACCEPTANCE.md` |
| G-P0-05 | VXVCLS vs VIXCLS 别名不一致（OPEN-CAT-1 未关闭）| 需求层 | SPEC §5.2 vs SERIES-CATALOG §10 |
| G-P0-06 | 主矩阵 §4 TC-003/TC-004 FR 归属错误（§1/§4 内部矛盾）| 矩阵层 | `matrix/TRACEABILITY.md §4` |
| G-P0-07 | FR-S011 双重任务归属 | 矩阵层 | `matrix/server/TRACEABILITY.md` |
| G-P0-08 | cmd/* 入口覆盖率 0%（启动失败无 CI 拦截）| 工程层 | `cmd/fred-client/`, `cmd/fred-server/` |
| G-P0-09 | AC-003/004/005 三项核心 DoD Pending（全链路从未端到端验证）| 工程层 | `spec/ACCEPTANCE.md` |
| G-P0-10 | 所有 Task 缺失独立 Verification Commands 节 | 计划层 | `tasks/*.md` |
| G-P0-11 | 所有 Task FR 编号孤岛（与根矩阵脱节）| 计划层 | `tasks/*.md` |

---

## 需要新增的文件清单

### 需求层规范（按优先级）

| 文件 | 用途 | 优先级 |
|---|---|---|
| `spec/SERIES-NAMING.md` | Series ID 命名规则，关闭 OPEN-CAT-1 | P0 |
| `spec/FRED-API-CONVENTIONS.md` | FRED v1 采集约定 | P1 |
| `spec/NO-LOOKAHEAD-SEMANTICS.md` | no-lookahead 查询语义形式化定义 | P1 |
| `spec/COVERAGE-AUDIT-THRESHOLDS.md` | 六域覆盖审计阈值，关闭 OPEN-008 | P1 |

### 模块规范

| 文件 | 用途 | 优先级 |
|---|---|---|
| `FRED-RULES.md` | fred 专属模块规范（10 节） | P1 |

### 架构决策记录

| 文件 | 用途 | 优先级 |
|---|---|---|
| `design/ADR-001-nats-vs-kafka-handoff.md` | NATS 选型依据 | P2 |
| `design/ADR-002-tdengine-timeseries.md` | TDengine 选型依据 | P2 |
| `design/ADR-003-cs-architecture.md` | 双服务 vs 单进程决策演化 | P2 |

### 缺失 Task 文件

| 文件 | 用途 | 优先级 |
|---|---|---|
| `tasks/TASK-FRED-INTEGRATION-001.md` | 端到端集成验收 | P0 |
| `tasks/TASK-FRED-PERF-001.md` | 性能预算验证 | P0 |
| `tasks/TASK-FRED-OPS-001.md` | 可观测性与运维验证 | P1 |
| `tasks/client/TASK-FRED-CLIENT-003.md` | Release Calendar 调度触发 | P1 |
| `tasks/server/TASK-FRED-SERVER-003.md` | ms_brain 集成契约验证 | P1 |

### Prompt Context Package

| 文件 | 对应 Task | 优先级 |
|---|---|---|
| `prompt/PROMPT-FRED-ROOT-001.md` | TASK-FRED-001 | P0 |
| `prompt/PROMPT-FRED-CLIENT-001.md` | TASK-FRED-CLIENT-001 | P0 |
| `prompt/PROMPT-FRED-SERVER-001.md` | TASK-FRED-SERVER-001 | P0 |
| `prompt/PROMPT-FRED-CLIENT-002.md` | TASK-FRED-CLIENT-002 | P1 |
| `prompt/PROMPT-FRED-SERVER-002.md` | TASK-FRED-SERVER-002 | P1 |

---

## 优先级执行路线图

### 第一阶段（< 1 天，无需开发）

1. 更新 `goal/goal.md` Status → `Approved`
2. 在 client/SPEC.md §6 补充 AC-C006 和 AC-C007
3. 在 ACCEPTANCE.md 补充 TC-011 和 V-017
4. 统一别名 VXVCLS→VIXCLS，WDTGAL→WTREGEN，关闭 OPEN-CAT-1
5. 修复主矩阵 §4 TC-003/TC-004 FR 归属（精确单行修改）
6. 修复 server 子矩阵 FR-S011 双重归属

### 第二阶段（< 1 周，文档补齐）

7. 同步子矩阵状态（Planned → Done/CI-gated）
8. 为所有 Task 添加 Scope/Non-scope 节和 Verification Commands 节
9. 统一 Task FR 编号为根规格体系
10. 创建 `spec/SERIES-NAMING.md`（关闭 OPEN-CAT-1）
11. 创建 `FRED-RULES.md`（10 节专属规范）
12. 补全 evidence/review/release/retrospective 子目录
13. 修复 CI workflow（boundary 补 setup-go，lint 升级 golangci-lint）

### 第三阶段（< 1 月，工程强化）

14. 补齐 cmd/* 入口单元测试（目标覆盖率 ≥ 50%）
15. 建立 CI 集成验证流水线（OPEN-004 闭环）
16. 创建 5 个 Prompt Context Package 文件
17. 补充性能预算生产 SLA（§17）和 Admin API 鉴权规范（§19）
18. 补充 3 个 ADR 文档
19. 补 CHANGELOG v1.0.0 历史并迁移至 Conventional Commits

---

## 正向肯定

以下是 fred 模块做得好的地方，值得保持：

- ✅ 主规格 16/16 FR 全量有 AC 和 TC，追溯链完整
- ✅ 仪表盘数据自洽（§7 与实际行数严格吻合）
- ✅ boundary-gates 9 道全过
- ✅ internal/client 96.4%、internal/cs 100%、internal/domain 100% 覆盖率优秀
- ✅ DESIGN.md 架构决策清晰，8 节全覆盖
- ✅ RUNTIME-MAPPING.md 与 Spec 高度对齐
- ✅ self-hosted runner 配置合规，无 GitHub-hosted runner 滥用
- ✅ gitleaks secret scan 完整接入
- ✅ SERIES-CATALOG.md 分类完整（12 类 90 序列），P0/P1/P2 分层清晰
- ✅ cs.Version 版本号在四处文件保持一致（无漂移）
