# 工作流治理检查

> **状态：已落地（原愿景架构）** — 治理检查全部实现。Eval Replay（✅ `rsi-trigger.py --propose` + 100 cases 基线）、Incident Handoff（✅ `goal-delivery.sh incident`）、Progressive Delivery（✅ `release --compile` 自动聚合）。详见 [`deploy/roadmap.md`](deploy/roadmap.md)（Phase 1-5 全部完成）。

本章定义 Controlled RSI 和 Delivery OS 的操作级检查。它关注的不是”是否有流程”，而是”流程变更、发布演练和递归改进是否可验证、可回滚、可追溯”。

## 治理对象

| 对象               | 必须记录                                              |
| ------------------ | ----------------------------------------------------- |
| Workflow Change    | 变更原因、影响范围、关联证据、批准者、版本            |
| Runtime Policy     | 自动化权限、人工审批点、禁止动作、失败处理            |
| Change Request     | 被改动的 Goal/Spec/Matrix/Gate/Prompt、风险、回滚路径 |
| Prompt Pack        | 输入来源、允许修改范围、验证命令、停止条件            |
| Gate Rule          | 规则来源、阈值、失败输出、豁免条件                    |
| Evaluation Dataset | 历史案例、预期结果、通过标准、覆盖的失败模式          |

所有治理对象都应能追溯到事实证据，而不是只追溯到一次讨论结论。

## RSI 变更检查

| 检查               | 问题                                        | 失败信号                       |
| ------------------ | ------------------------------------------- | ------------------------------ |
| Workflow Changelog | 本次工作流改了什么，为什么改？              | 只有结果，没有原因和证据       |
| Workflow Rollback  | 如果补丁误伤，如何恢复旧规则？              | 没有旧版本、迁移说明或回滚步骤 |
| Runtime Policy     | 这项改进是自动允许、仅建议，还是必须审批？  | Agent 直接修改门禁或评分阈值   |
| Change Impact      | 会影响哪些模板、Prompt、Gate、Matrix 字段？ | 只改一个文件，相关产物不同步   |
| Safety Case        | 为什么它不会降低质量、安全或责任边界？      | 删除检查、降低阈值、模糊 owner |
| Eval Replay        | 历史失败案例能否证明补丁有效？              | 只凭直觉认为新规则更好         |

RSI 补丁没有通过这些检查时，只能进入 Improvement Backlog，不能直接成为默认工作流。

## Drift Checks

| 漂移类型       | 检查方式                                        | 修复方向                                      |
| -------------- | ----------------------------------------------- | --------------------------------------------- |
| Goal Drift     | 实现、测试或指标是否偏离已批准 Goal             | 发起 CR，而不是改写 Goal 适配实现             |
| Matrix Drift   | FR/AC/Task/Test/Evidence 是否断链               | 补矩阵映射或阻止进入下一 Gate                 |
| Metric Drift   | 指标口径、窗口、owner 是否变化                  | 更新 Observability Contract 和 Metrics Review |
| Prompt Drift   | Prompt 是否遗漏最新边界、风险、验证命令         | 重新生成 Prompt Pack 并记录来源               |
| Artifact Drift | Spec、Matrix、Task、Plan、Prompt 是否版本不一致 | 生成 Stale Artifact Report                    |
| Policy Drift   | 实际执行是否绕过 Runtime Policy                 | 回滚自动化权限并补审批记录                    |

Drift Check 的输出应是结构化报告，至少包含 `detected_at`、`artifact`、`expected`、`actual`、`impact`、`required_action`。

### 当前仓库同步基线

| 基线          | 权威位置                                                          | 失败信号                                       | 验证方式                                         |
| ------------- | ----------------------------------------------------------------- | ---------------------------------------------- | ------------------------------------------------ |
| 模块规格库    | `module/*/SPEC.md`、`module/*/TRACEABILITY.md`、`module/*/tasks/` | Goal、Prompt、agent 或 CI 仍引用旧规格路径     | 旧路径扫描必须为空                               |
| 管线治理规则  | `docs/governance/`                                                | DoR/DoD、Template、Scoring、Arbiter 口径不一致 | `spec-lint.sh`、`spec-drift-guard.sh`            |
| Goal 运行状态 | `.config/goal/`                                                   | Registry、Gate、Evidence 与模块任务断链        | `traceability-check.sh`、`task-spec-validate.sh` |
| 公开索引      | `README.md`、`ARCHITECTURE.md`、`STATUS.md`                       | 组件数量、模块路径或 Goal 适配入口不一致       | `status-consistency-check.sh`                    |

`Artifact Drift` 在本仓库中必须覆盖 `module/` 与 `docs/goal/` 的双向引用：Goal 规则可以引用模块制品，但不能复制模块规格；模块规格可以引用 Goal ID 和 Gate 口径，但不能改写 Goal 状态机。

## 删除与放宽防护

| 防护                      | 禁止行为                                       |
| ------------------------- | ---------------------------------------------- |
| Test Deletion Guard       | 删除失败测试、降低断言强度、用快照覆盖真实断言 |
| Evidence Deletion Guard   | 删除失败证据、覆盖历史报告、只保留通过结果     |
| Prompt Safety Guard       | 移除 allowed files、审批点、安全/隐私/资金约束 |
| Gate Weakening Guard      | 降低门禁阈值、扩大豁免范围、跳过 reviewer 分离 |
| Metric Substitution Guard | 用新指标替代旧指标但不记录映射和原因           |

任何删除或放宽都必须有 CR、影响分析、回滚方案和明确批准者。

## Workflow Test Pyramid

| 层级        | 验证对象                                | 示例                               |
| ----------- | --------------------------------------- | ---------------------------------- |
| Unit        | 单条规则、模板字段、ID 格式             | 缺 AC 时 lint 必须失败             |
| Integration | Goal/Spec/Matrix/Task/Prompt 之间的链路 | 未映射 Test 的 AC 不得进入 Code    |
| Regression  | 历史失败案例是否被新规则捕获            | 曾经漏掉的回滚计划缺失必须被拦截   |
| Mutation    | 故意破坏工作流资产，验证 Gate 是否报错  | 删除 Evidence 或降低阈值应触发失败 |
| Simulation  | 发布、回滚、指标窗口和事故路径演练      | Release Simulation、Rollback Drill |

Controlled RSI 的验证重点是：新规则能抓住旧问题，并且不会制造更大的流程成本或安全缺口。

## Scorecard

| 指标                | 解释                                     |
| ------------------- | ---------------------------------------- |
| Capture Rate        | 新规则捕获历史失败案例的比例             |
| False Positive Rate | 合法任务被误拦截的比例                   |
| Rework Reduction    | 同类返工是否下降                         |
| Gate Escape Rate    | 通过 Gate 后仍暴露的严重问题数量         |
| Lead Time Impact    | 新规则对交付周期的影响                   |
| Safety Preservation | 安全、隐私、资金、权限约束是否保持或增强 |

Scorecard 应在改进合入后继续观察至少一个交付周期。没有后验数据的改进，只能算“已部署”，不能算“已证明有效”。

## Release Simulation 模板

```yaml
release_simulation:
  release_id:
  goal_ids: []
  matrix_snapshot:
  deployment_path:
  rollback_path:
  metrics_window:
  rehearsal_steps:
    - step:
      expected:
      evidence:
  failure_cases:
    - scenario:
      detection:
      rollback_action:
      owner:
  decision: pass | fail | blocked
```

## Rollback Drill 模板

```yaml
rollback_drill:
  release_id:
  trigger_condition:
  rollback_target:
  data_migration_impact:
  verification_commands: []
  operator:
  duration:
  evidence:
  gaps:
    - gap:
      required_fix:
```

## 最小执行清单

每次工作流改进合入前，至少确认：

1. 有 Workflow Changelog 和回滚路径。
2. 有 CR 或明确的 Auto-allowed 依据。
3. 有历史案例或样例任务验证。
4. 没有删除失败测试、失败证据或关键 Gate。
5. Module、Matrix、Prompt、Gate、Metric 的相关产物已同步，且没有旧规格路径残留。
6. Scorecard 定义了后验观察指标。

满足这些条件，Controlled RSI 才是受控改进；否则只是把复盘意见写进了流程。
