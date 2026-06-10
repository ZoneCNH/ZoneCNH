# 16. CI/CD 与工程实践

> 本文档从原 `advanced-operations.md` 拆分而来，聚焦于 CI/CD 集成、执行阶段、反模式和 x.go 专用规则。Risk Register、ADR、Release Manifest 和落地计划已拆分至 [17-risk-and-decisions.md](17-risk-and-decisions.md)。

---

## 1. CI/CD 集成

CI/CD 不只跑测试，还要验证交付物完整性。

### CI Checks

| Check | 名称                   | 检查内容     |
| ----- | ---------------------- | ------------ |
| CI-CHK0 | Repository Cleanliness | 工作区干净   |
| CI-CHK1 | Build                  | 编译通过     |
| CI-CHK2 | Unit Tests             | 单元测试通过 |
| CI-CHK3 | Integration Tests      | 集成测试通过 |
| CI-CHK4 | Lint / Format          | 代码风格一致 |
| CI-CHK5 | Architecture Rules     | 架构规则合规 |
| CI-CHK6 | Docs Sync              | 文档同步     |
| CI-CHK7 | Changelog Sync         | 变更日志同步 |
| CI-CHK8 | Evidence Manifest      | 证据清单完整 |
| CI-CHK9 | Release Manifest       | 发布清单完整 |
| CI-CHK10 | Goal Control Plane     | `goal-validator` strict 验证通过 |
| CI-CHK11 | Release Gate Hard Block | G10 PASS、无打开的 release_blocking 风险、有 Evidence 包 |

### 检查规则

```text
代码变更   → 必须有测试
功能变更   → 必须有文档
行为变更   → 必须有 CHANGELOG
架构变更   → 必须有 ADR
存储变更   → 必须有 migration + rollback
Issue 完成 → 必须有 evidence
PR 合并    → 必须有 release manifest
发布 tag   → 必须先通过 Goal CI 与 release gate
G10 未 PASS → 禁止创建 Release
```

### Release 硬阻断

tag 发布顺序固定为：docs-ci 质量门禁 → 可复用 Goal CI → `.github/ci/goal-release-gate.sh` → release manifest → GitHub Release。

release gate 在以下情况必须非零退出：G10 未 PASS、存在打开的 `release_blocking` 风险、缺失 `.config/goal/evidence/**/*.md`、Goal CI 未定义或未要求 `goal-validator`。

### CI 权威与投影边界

CI MUST 调用统一 validator 或 `docs/goal/tools/` 中的封装脚本，不得在 workflow YAML 中复制第二套 Gate 规则。允许 workflow 只做调度、缓存、上传 artifact 和组合 job 结果。

推荐命令：

```bash
python3 docs/goal/tools/rule-drift-check.py --root .
python3 docs/goal/tools/goal-validate.py --root . --mode strict
python3 docs/goal/tools/matrix-gen.py --check-only --matrix .config/goal/matrix/matrix.yaml
bash docs/goal/tools/goal-workflow.sh validate
```

如果 `.github/workflows/` 需要新增或修改强规则，Agent MUST 先生成 `docs/goal/change-requests/` 提案并要求 Human Approval。

---

## 2. 执行阶段

严格按以下阶段执行。

本节 Phase 是 CI / `workflow_step` 执行剖面，用于组织检查和报告；它不是 `current_phase` 主流程枚举，也不得覆盖 `pipeline_state`。CI 可把 Phase 结果投影到 Gate / Evidence，但主流程层级仍以 [03-pipeline.md §1](03-pipeline.md#1-完整管线) 为准。

### Phase 0: Pre-flight

```text
目标：确认环境、输入、约束、可执行性
检查：分支、工作区、依赖、测试命令、文档入口、Issue 来源、外部服务依赖
输出：preflight_report.md
```

### Phase 1: Discovery

```text
目标：理解现状，而不是马上修改
检查：项目结构、README/docs/ADR/CHANGELOG、相关源码、Issue 列表、代码与文档差异、模块边界、风险点
输出：discovery_report.md、architecture_snapshot.md、debt_inventory.md
```

### Phase 2: Planning

```text
目标：把问题拆成可执行计划
检查：P0/P1/P2/P3 分类、优先级、DoD、验证命令、依赖顺序、可并行任务、阻塞项、高风险变更
输出：goal_execution_plan.md、issue_breakdown.md、dependency_graph.md、risk_register.md
```

### Phase 3: Implementation

```text
目标：按顺序完成任务
规则：一次只处理一个 Issue、修改前说明影响范围、修改后运行最小验证、不允许顺手重构、新问题登记不混入
输出：code changes、test changes、migration files、config updates
```

### Phase 4: Verification

```text
目标：证明完成，而不是声称完成
执行：build、unit tests、integration tests、lint、format、regression checks、smoke test
输出：verification_report.md、test_evidence.log
```

### Phase 5: Documentation Sync

```text
目标：保持事实链一致
同步：README、CHANGELOG、docs/、ADR、config examples、issue notes、release notes
输出：docs_update_summary.md、changelog_entry.md
```

### Phase 6: Review

```text
目标：检查是否引入新债务
检查：架构边界、循环依赖、重复实现、错误处理、测试覆盖、文档、隐式行为变化、安全风险
输出：review_report.md、risk_assessment.md
```

### Phase 7: Release / PR

```text
目标：形成可合并交付
输出：commit summary、PR title、PR description、test evidence、linked issues、release note、rollback plan、Goal release gate verdict
```

### Phase 8: Retrospective

```text
目标：把一次执行转化为长期复利资产
总结：哪些规则有效、哪些假设错误、哪些检查应该自动化、哪些 Prompt 需要改进、哪些文档应该升级为 SSOT、哪些测试应该永久加入 CI
输出：retrospective.md、new_rules.md、prompt_patch.md
```

---

## 3. 反模式

以下行为全部禁止：

| 反模式                   | 说明                  |
| ------------------------ | --------------------- |
| Goal 直接跳 Code         | 跳过 Spec/Design/Plan |
| 没有 Spec 就写 Design    | 需求未固化就设计      |
| 没有 Design 就拆 Tasks   | 架构未定就拆任务      |
| 没有 DoD 就执行          | 完成标准不明确        |
| 没有测试就声称完成       | 缺少验证              |
| 没有证据就声称完成       | 缺少证明              |
| 顺手扩大范围             | Scope Creep           |
| 混入无关重构             | 任务混杂              |
| 用假实现绕过测试         | Mock 绕过而非真正实现 |
| 修改公共接口不写决策记录 | 无 ADR                |
| 文档和代码冲突时静默选择 | 不解决冲突            |

---

## 4. x.go 专用规则

### 4.1 模块边界

核心模块：`market_data`、`macro_data`、`regime_engine`、`storage`、`config`、`observability`、`ci`、`release`

边界规则：

```text
Market Data 不直接决定 Regime
Macro Data 不直接依赖 Market Data 内部实现
Regime Engine 只消费标准化状态输入
Storage 必须通过 interface 隔离
Config 不使用隐式全局状态
CI Check 优先 Go 化
Gate 规则不应长期散落 Python / Shell / Go 多语言实现，除非边界明确
```

### 4.2 数据链路

**Market Data：**

```text
Binance REST / WS → Adapter → Normalizer → Validator → Kafka / Redis / TDengine / PostgreSQL
```

**Macro Data：**

```text
FRED / Treasury / Yahoo / Manual Source → Adapter → Normalizer → Feature Builder → Macro Regime Classifier
```

**Regime Engine：**

```text
Market Regime + Macro Regime → MxS Decision Matrix → Action Profile → Risk Tier
```

### 4.3 x.go 强制 DoD

```text
- go test ./... 通过
- go vet ./... 通过
- README 更新
- CHANGELOG 更新
- docs/ 更新
- 配置 example 更新
- Issue 状态同步
- Release Manifest 更新
- 无 fake implementation
- 无未解释 TODO
- 无跨模块违规依赖
- 有 rollback plan
- 有 Traceability Matrix
```

### 4.4 x.go 专用检查

XG-CHK* 是 x.go 代码仓库的 CI 检查项，不是 Goal 体系的独立 Gate 编号；其结果应回填到对应的 G7 Test Gate、G8 Evidence Gate 或 G9 Review Gate。

| 检查项 | 名称                             |
| ----- | -------------------------------- |
| XG-CHK1 | Module Boundary Check             |
| XG-CHK2 | No Fake Implementation Check      |
| XG-CHK3 | Config Example Check              |
| XG-CHK4 | Docs / CHANGELOG Check            |
| XG-CHK5 | Release Manifest Check            |
| XG-CHK6 | Go-first Check for Internal Tools |
| XG-CHK7 | Secrets Path Check                |
| XG-CHK8 | Issue Sync Check                  |

### 4.5 Secrets 约束

```text
Redis / Kafka / PostgreSQL / TDengine / OSS 配置应遵循：
<secrets-env-dir>/*
```

---

## 5. Facts / Assumptions / Unknowns

每次执行前必须分类。

### Facts（事实）

```text
已确认、可验证的信息
示例：项目使用 Go 1.22、PostgreSQL 16、Redis 7
```

### Assumptions（假设）

```text
未验证但暂且接受的信息
示例：假设 Binance WS 延迟 < 100ms
规则：假设必须标记，验证后转为 Fact 或标记为 Invalid
```

### Unknowns（未知项）

```text
已知不知道的信息
示例：TDengine 在高并发写入下的性能表现
规则：Unknown 必须进入 AutoResearch 或 Risk Register
```
