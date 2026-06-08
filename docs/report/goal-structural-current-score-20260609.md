# Goal 体系结构复评报告（2026-06-09）

## 1. 结论

本轮已完成对 `docs/goal/` 与 `.config/goal/` 的结构性修复和复评。

**当前本地结构评分：97/100。**

该分数表示本地文档、规则、工具、样例和既有运行制品已重新对齐；不等同于 Spec → Code 管线要求的四源评分门禁通过。若要宣称正式 98 分门禁通过，仍需运行 `claude / codex / copilot / rules` 四源 scorer 与 `pipeline-arbiter`。

## 2. 评分账本

| 项目 | 扣分 | 说明 |
|------|------|------|
| 四源门禁未执行 | -2 | 本轮运行了 rules drift、matrix、lint、gate readiness 与语法检查，但未实际执行三路 LLM scorer 与 arbiter。 |
| 语义验收深度不足 | -1 | 本地检查能证明结构、枚举、路径、字段和追溯关系闭合，但不能完全替代人工/LLM 对业务语义质量的对抗性审查。 |
| 合计 | -3 | 100 - 3 = 97。 |

## 3. Agent Team 分工与结果

| Lane | 职责 | 主要发现 | 修复状态 |
|------|------|----------|----------|
| Helmholtz | 工具、schema、运行制品一致性 | Gate enum 漂移、Evidence 路径与 ID 模式不一致、Matrix `Dropped` 原因校验过松、既有 Matrix evidence ID 未闭合 | 已修复 |
| Lovelace | 文档口径、术语和历史报告漂移 | 历史统一报告仍描述旧问题，README/风险文档残留 `CI Gate` 口径，易与正式 Goal Gate 混淆 | 已修复 |
| 主线程 | 集成、验证、报告 | 汇总两路发现，执行补丁、运行验证、固化当前评分 | 已完成 |

## 4. 已修复的结构性问题

### 4.1 Matrix 终态与追溯链

- Matrix 终态统一为 `Verified` / `Dropped`。
- `Dropped` 必须携带非空 `drop_reason`。
- Matrix 行补齐 `acceptance_criteria`、`prompt_id`、`evidence_ids`。
- `.config/goal/matrix/matrix.yaml` 中既有 evidence ID 已按当前命名规则回填。

### 4.2 Gate 与 CI Check 边界

- Goal Gate result 统一为 `PASS / PASS_WITH_RISK / FAIL / BLOCKED`。
- `WAIVED` 明确为策略记录，不再作为 Gate result。
- `CI Gates` 口径收敛为 `CI Checks`，编号使用 `CI-CHK*` / `XG-CHK*`，避免与 G0-G11 Goal Gate 混淆。
- `gate-check.sh` 明确定位为“Gate 制品就绪检查”，不冒充四源 arbiter。

### 4.3 Evidence 路径、字段与状态

- Evidence 生成路径统一为：

```text
.config/goal/evidence/{YYYY-MM-DD}/{TASK-ID}/{EVID-ID}.md
```

- Evidence ID 统一绑定 Test：

```text
EVID-TEST-{TASK-ID}-{NNN}
```

- Evidence 必填字段统一包含 Goal、Spec、Task、Acceptance Criteria、Test、Status、Files Changed、Commands Run。
- 初始状态从 `PENDING` 调整为 `PARTIAL`，与规则枚举一致。

### 4.4 ID 命名与快速开始样例

- Spec 示例统一使用 `SPEC-*-v1`，移除混用的 `v1.0`。
- Requirement 与 Acceptance Criteria 示例统一为：

```text
REQ-SPEC-{domain}-v1-{NNN}
AC-REQ-SPEC-{domain}-v1-{NNN}-{NNN}
```

- Quickstart 中的 Matrix、Prompt、Evidence 样例已按当前追溯链重写。

### 4.5 Registry 与 Pipeline 口径

- Registry 口径统一为“6 个业务 Registry 文件 + 横切运行制品”。
- Pipeline 明确为“双轴状态机”：主流程状态与对象状态分开描述。
- Task 可终态保留 `Done / Dropped`；Matrix 可终态为 `Verified / Dropped`，不再混用。

### 4.6 历史报告权威性

- 旧的 2026-06-08 阶段报告已标注为历史快照。
- 当前评分权威指向本文件，避免多个报告同时声称当前 98 分。

## 5. 验证证据

本轮执行并通过以下检查：

```bash
python3 docs/goal/tools/rule-drift-check.py --root . --quiet
python3 docs/goal/tools/matrix-gen.py --check-only --matrix .config/goal/matrix/matrix.yaml
bash docs/goal/tools/lint-goal.sh docs/goal
bash docs/goal/tools/gate-check.sh .
bash -n docs/goal/tools/lint-goal.sh
bash -n docs/goal/tools/gate-check.sh
bash -n docs/goal/tools/evidence-collect.sh
python3 -m py_compile docs/goal/tools/matrix-gen.py docs/goal/tools/rule-drift-check.py
git diff --check -- docs/goal docs/report .config/goal
```

关键结果：

| 检查 | 结果 |
|------|------|
| Rule Drift | 通过，无输出 |
| Matrix Check | 5 行全部终态，覆盖率 100%，无孤儿 Task，无 Dropped 缺原因 |
| Goal Lint | ERRORS=0，WARNINGS=0 |
| Gate Readiness | PASS=7，FAIL=0，WARN=0 |
| Shell/Python 语法 | 通过 |
| Diff Check | 通过 |

## 6. 剩余风险

| 风险 | 影响 | 建议 |
|------|------|------|
| 未执行四源 scorer | 不能宣称正式 98 分门禁通过 | 需要时运行完整 `claude / codex / copilot / rules` scorer 与 `pipeline-arbiter` |
| 报告目录仍保留历史快照 | 读者可能看到旧评分标题 | 已加历史说明；后续引用应优先指向本文件 |
| 本地验证偏结构化 | 不能完全覆盖业务语义 | 对关键 Goal 再做一次人工/LLM 对抗性审查 |

## 7. 下一步

如果目标是进入正式管线门禁，下一步应运行四源结构评分与 arbiter。若目标是文档体系自洽，本轮修复已经达到可验收状态。
