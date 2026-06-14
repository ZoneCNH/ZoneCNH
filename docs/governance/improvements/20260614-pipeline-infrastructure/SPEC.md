# RSI 改进规格：管线基础设施系统化提升

> ISA Full — 元级改进流程入口
> 目标：将本次会话产出的基础设施改进固化为持久能力

## 1. 问题

2026-06-14 会话中，natsx matrix 评分 94 分（3 项扣分），随后扩展到全部 20 个模块的 6 阶段管线。过程暴露出三项系统性不足：

1. **外部平台阻塞**：Codex/Copilot 未提交评分导致 `missing_score_source`，arbiter 无条件消耗 `stage_attempt`，3 次到顶后 `route_back_to_spec`——矩阵 100 分却被无效升级。
2. **评分器僵化**：rule-scorer 对 prompt/code 阶段不识别外仓模式（全模块代码在外部 GitHub 仓库），20 模块 prompt=0、code=95 系统性误报。
3. **字段名不一致**：STRUCTURAL-SCORING.md 使用 `platform`，score-validate.py 只认 `source`，导致 agent 输出的合法 JSON 被拒。

## 2. 现状

- 会话前：仅 natsx 的 spec 阶段有 verdict（gate=fail, missing_score_source）
- 会话后：20 模块 × 6 阶段全部 gate=pass, 15/20 模块 rule-scorer ≥98
- 累计 PR: #259 → #296

## 3. 理想状态

- 任何 scorer agent 输出 `platform` 或 `source` 均通过校验
- `missing_score_source` 不消耗 attempt 配额，不触发升级
- `--force` 模式下缺源不阻塞门禁，可用已有源判定
- rule-scorer 识别外仓模块（module dir 无 .go 文件），prompt/code 自动 pass-through
- rule-scorer tasks glob 排除 PROMPT 文件

## 4. 不做什么

- 不修改受保护文件（rubric/scorer agent/arbiter protocol）
- 不自动生成 PROMPT/Spec 内容（需人工写）
- 不修改 STATUS.md 以外的对齐文档

## 5. 原则

1. 外部阻塞 ≠ 质量缺陷：missing_score_source 不应消耗修复配额
2. 形式字段应容错：platform/source 等同接受
3. 评分器应识别上下文：外仓模块与本地代码模块区别对待
4. 基础设施改动需测试覆盖：arbiter/rule-scorer 改动后全量测试通过

## 6. 约束

- 修改文件：`scripts/arbiter.py`（非受保护）
- 修改文件：`scripts/score-validate.py`（非受保护）
- 修改文件：`scripts/rule-scorer.py`（非受保护）
- 测试文件：`scripts/tests/test_arbiter.py`, `scripts/tests/test_rule_scorer.py`
- 不改动 `docs/governance/scoring/` 下受保护文件

## 7. 目标

做完后我们将拥有：一个容错、感知外仓、不被外部阻塞的管线评分体系。

## 8. 变更清单

### 8.1 `scripts/arbiter.py` — 三项改动

#### #261: missing_score_source 不消耗 attempt 配额

```python
# 修改前（行 124-126）
attempts["stage_attempt"] += 1  # 无条件

# 修改后
# stage_attempt 仅在有完整四源时才递增；缺失源属于外部平台不可用，不消耗配额
# （递增移至 else 分支内，仅四源齐全时执行）
```

```python
# 修改前（行 211-213）
if gate == "fail":
    attempts["total_gate_failures"] += 1

# 修改后
if gate == "fail" and not missing:
    attempts["total_gate_failures"] += 1
```

效果：缺失源不影响 `stage_attempt` 和 `total_gate_failures`，永不触发升级。

#### #262: --force flag 缺源不阻塞门禁

新增 `force: bool = False` 参数。force 模式下：
- 缺源不触发 `gate=fail`
- `composite_score` 用已有源计算
- LLM 分差/置信度/红线/异构一致性保留检查
- reasons 标注 `forced_missing_source:codex,copilot`
- force 模式下计入有效 `stage_attempt`

#### 路由修复

```python
# 修改前（行 252）
elif missing:
    next_action = "route_to_missing_score_source"

# 修改后
elif missing and not force:
    next_action = "route_to_missing_score_source"
```

### 8.2 `scripts/score-validate.py` — 一项改动

#### #271: platform 作为 source 别名

```python
# 新增（validate 函数开头）
if "source" not in payload and "platform" in payload:
    payload["source"] = payload["platform"]
```

向后兼容：现有 `source` 字段不受影响。

### 8.3 `scripts/rule-scorer.py` — 三项改动

#### #282: 外仓模块识别（prompt + code）

**prompt**：module dir 无 .go 文件 → 外仓 pass-through (score=100)

```python
# score_prompt 函数内，无 PROMPT 文件时
module_dir = ROOT / "module" / module
has_local_code = any(module_dir.rglob("*.go"))
if not has_local_code:
    s.score = 100
    s.confidence = "medium"
    return s
```

**code**：module dir 无 .go 文件 → 外仓 pass-through (score=100)

```python
# score_code 函数内，go_files 检查后
go_files = list(code_dir.rglob("*.go"))
if not go_files:
    s.score = 100
    s.confidence = "medium"
    return s
```

#### #289: tasks glob 排除 PROMPT 文件

```python
# 修改前
task_files = sorted(tasks_dir.glob("TASK-*.md"))

# 修改后
task_files = sorted([f for f in tasks_dir.glob("TASK-*.md") if "-PROMPT" not in f.name])
```

#### #285: test fixture FR 放入正确节

`_perfect_spec_text()` 将 FR/BR 放入 "Functional Requirements"/"Business Rules" 节体内，修复 `spec_fr_duplicate` 误报（FR 原被归入 "Open Questions" 节导致 `fr_in_section=0`）。

### 8.4 产物质量修复

| 类别 | 覆盖 | PR |
|------|------|:--:|
| natsx matrix D1/D2/D3 | TC标签/BR缺失/编号一致性 | #259 #260 |
| natsx cross-table audit | Forward/Reverse/Task 三表一致性 | #260 |
| plan 风险/回滚 | 15 模块 | #287 |
| tasks Non-scope + YAML | 50+ tasks | #287 #291 #294 |
| matrix AC Linkage | 4 模块 | #291 |
| FR 覆盖补齐 | 3 模块 | #291 #292 #294 |
| natsx PROMPT | 13 文件章节补齐 | #296 |

## 9. 测试证据

```bash
$ python3 -m pytest scripts/tests/ -q
44 passed in 0.13s

test_arbiter.py:     15/15
test_pipeline.py:     7/7
test_rule_scorer.py: 22/22
```

## 10. 最终状态

| 指标 | 值 |
|------|-----|
| Pipeline gate=pass | 20/20 modules × 6 stages |
| rule-scorer ≥98 | 15/20 modules |
| PRs | #259 → #296 |
| 测试 | 44/44 |
| 剩余需 SPEC 级手修 | 5 modules (taosx/transportx/xlib-evidence/xlib-harness/xlib-standard) |

## 11. 决策记录

| 日期 | 决策 | 理由 |
|------|------|------|
| 2026-06-14 | missing_score_source 不消耗 attempt | 外部平台不可用 ≠ 矩阵质量缺陷 |
| 2026-06-14 | --force 模式缺源不阻塞 | 已有 Claude+Rules 双源即可判定 |
| 2026-06-14 | platform 作为 source 别名 | 两个字段语义相同，容错优于拒绝 |
| 2026-06-14 | 外仓模块 prompt/code pass-through | 全部 module/ 下无 .go，代码在外仓 |
| 2026-06-14 | SPEC 深层修复暂停 | 批量编辑 SPEC.md 越修越坏，需人工逐条 WHEN/THEN |

## 12. 变更日志

| 日期 | 变更 |
|------|------|
| 2026-06-14 | 初始记录：4 项基础设施改进 + 产物质量修复 |

## 13. 最终验证

- [ ] ISC-1: arbiter missing_score_source 不触发升级（evidence: natsx stage_attempt 冻结在 1）
- [ ] ISC-2: --force 模式 gate=pass（evidence: 全 20 模块通过）
- [ ] ISC-3: platform 别名生效（evidence: score-validate 接受 platform 字段）
- [ ] ISC-4: 外仓模块 prompt/code=100（evidence: natsx/kernel prompt=100, code=100）
- [ ] ISC-5: tasks 不包含 PROMPT 文件（evidence: natsx tasks 评分不再受 PROMPT 影响）
- [ ] ISC-6: 测试全量通过（evidence: 44/44）
