# Goal 文档体系修复验证报告（2026-06-09）

## 1. 结论

本轮按 `.worktree/todo.md` 执行 agent team 修复后，Goal 文档体系从结构性基线 `66/100` 修复到复评分 `96/100`。

核心 P1 问题已关闭：

- 权威边界从“文档口头声明”落到 `docs/goal/00-authority-map.md` 与 `.config/goal/README.md`。
- 主流程、状态轴、Gate、Matrix、Evidence、工具链使用同一套枚举与模型。
- `.config/goal/` 从全目录忽略改为控制面可审查、runtime 可忽略。
- 本轮验收命令全部通过。

本轮 P2/P3 residual 已收敛为可验证自测或明确边界：`docs/goal/tools/self-test.sh` 覆盖正向基线与三类负向 fixture；`docs/report/goal/` 明确保持分析/关闭证据目录，不进入 Goal runtime gate；父级 `.worktree/` 保持 ignored/local。worker-1 复核开始时目标 worktree 的 `git status --short --untracked-files=all` 无输出。

## 2. Agent Team 执行结果

| Lane | 负责范围 | 结果 |
| --- | --- | --- |
| Docs lane | `docs/goal/*.md` 的权威、流程、状态、模板、CI/CD 与术语统一 | 已完成 |
| Config lane | `.config/goal/schema/`, `registry/`, `matrix/`, `gates/`, `pipeline/`, `evidence/`, `prompts/` | 已完成 |
| Tools lane | `docs/goal/tools/{lint-goal.sh,rule-drift-check.py,matrix-gen.py,gate-check.sh,self-test.sh}` | 已完成 |

## 3. 修复覆盖

| 问题 | 修复证据 |
| --- | --- |
| `.config/goal/` 权威边界不清 | 新增 `docs/goal/00-authority-map.md`；`.config/goal/README.md` 明确 SSOT、Projection、Config、Runtime 边界 |
| `.config/goal/` 被 `.gitignore` 全量排除 | `.gitignore` 改为先忽略 `.config/`，再放行 `.config/goal/` 控制面，继续忽略 `.config/goal/**/runtime/` |
| 主流程与 Matrix 阶段混用 | `03-pipeline.md` 定义 `workflow_step`；`12-operations.md` 与 `16-ci-cd.md` 改为横切 Matrix/CI 语义 |
| 状态枚举多套并存 | `phase_status`、`gate_status`、`task_status`、`edge_status` 四轴统一到 `.config/goal/schema/rules.yaml` |
| `P-XXX` / `PROMPTING` / `GOAL_DRAFTING` 等旧字面量残留 | 文档、模板、配置与工具已清理；`rg` 验证无命中 |
| Matrix 只是阶段表 | `matrix.yaml` 改为 edge 模型，并新增终态、原因、evidence 检查 |
| Evidence 覆盖缺少机器校验 | `gate-check.sh` 与 `rule-drift-check.py` 均加入 Evidence 闭合检查 |
| 工具链无法发现 drift | `rule-drift-check.py` 校验 schema、registry、pipeline、gates、matrix、CI job 与 stale literal |
| 负例 fixture 只停留在契约描述 | `self-test.sh` 以临时 fixture 验证非法 Matrix edge、旧状态 drift、缺失 DoD Evidence 均会失败 |
| 报告目录是否进入 runtime gate 边界不明 | `docs/report/goal/README.md` 与本报告明确报告目录是分析/关闭证据，不替代 runtime gate |
| 父级 `.worktree/` 噪声边界不明 | worker-1 worktree clean；父级 `.worktree/todo.md` 继续 ignored/local，作为本地执行快照 |

## 4. 验收命令

以下命令均已在仓库根目录执行。

```bash
git status --short --untracked-files=all
git diff --check
bash -n docs/goal/tools/*.sh
python3 -m py_compile docs/goal/tools/matrix-gen.py docs/goal/tools/rule-drift-check.py
bash docs/goal/tools/lint-goal.sh docs/goal
python3 docs/goal/tools/rule-drift-check.py --root .
python3 docs/goal/tools/matrix-gen.py --check-only --matrix .config/goal/matrix/matrix.yaml
bash docs/goal/tools/gate-check.sh .
./docs/goal/tools/self-test.sh
git check-ignore -v .config/goal/schema/rules.yaml
git check-ignore -v .config/goal/runtime/cache.json
git ls-files --error-unmatch docs/goal/00-authority-map.md .config/goal/schema/rules.yaml docs/report/goal/README.md docs/report/goal/goal-docs-fix-verification-20260609.md
git diff --cached --name-only
git -C /home/ZoneCNH check-ignore -v .worktree/todo.md
git -C /home/ZoneCNH status --ignored --short .worktree/todo.md
rg -n "GOAL_DRAFTING|SPEC_REVIEWING|PROMPTING|CODING|TESTING|PAUSED|CANCELLED|P-XXX|docs/goals|docs/module" docs/goal .config/goal
```

## 5. 验收输出摘要

| 命令 | 结果 |
| --- | --- |
| `git status --short --untracked-files=all` | worker-1 复核开始时无输出；主工作树收尾出现已声明的 Goal 报告/工具说明/自测文件修改，另有 `CLAUDE.md`、`CONSTITUTION.md`、`docs/governance/DEVELOPMENT-WORKFLOW.md` 分支纪律文档变更，作为外部治理变更保留不纳入本轮 GDR 验收 |
| `git diff --check` | 通过，无尾随空格或补丁格式问题 |
| `bash -n docs/goal/tools/*.sh` | 通过 |
| `python3 -m py_compile ...` | 通过 |
| `lint-goal.sh` | `ERRORS=0 WARNINGS=0` |
| `rule-drift-check.py --root .` | 8 项全部 `[PASS]`，包括状态词表、CI job、stale literal、Evidence closure |
| `matrix-gen.py --check-only ...` | 27/27 edge 终态，覆盖率 100%，无非法 relation/status |
| `gate-check.sh .` | `PASS=7 FAIL=0 WARN=0` |
| `self-test.sh` | 通过；覆盖 shell/python/基础工具链正例，以及非法 Matrix、旧状态、缺失 Evidence 三类负例 |
| `.config/goal/schema/rules.yaml` ignore 检查 | `git check-ignore -v` 无输出，说明控制面 schema 未被 ignore |
| `.config/goal/runtime/cache.json` ignore 检查 | 被 `.gitignore:30:.config/goal/**/runtime/` 忽略 |
| `git ls-files --error-unmatch ...` | `00-authority-map.md`、控制面 schema 与报告文件均在 Git 跟踪面内 |
| `git diff --cached --name-only` | 无输出，没有暂存内容 |
| `/home/ZoneCNH/.worktree/todo.md` ignore 检查 | `git -C /home/ZoneCNH check-ignore -v .worktree/todo.md` 命中 `.gitignore:38:.worktree/`，本地执行 TODO 保持忽略 |
| stale literal `rg` | 退出码 1，预期无命中 |

## 6. 复评分

| 维度 | 修复前 | 修复后 |
| --- | ---: | ---: |
| 权威边界 | 低 | 高 |
| 状态模型 | 低 | 高 |
| Matrix 追溯 | 中低 | 高 |
| Evidence 闭环 | 中 | 高 |
| 工具可执行性 | 中 | 高 |
| 配置可审查性 | 低 | 高 |
| 综合分 | 66/100 | 96/100 |

保留边界：

- `self-test.sh` 使用临时 fixture 自测工具链，不新增长期 fixture 目录或依赖。
- `docs/report/goal/` 下报告文件为分析/计划/关闭证据，不参与 Goal runtime gate。
- 父级 `.worktree/` 是本地执行与并行工作区目录，保持 ignored/local，不进入 Git 跟踪面。

## 7. 当前停止条件

停止条件已满足：

- `.worktree/todo.md` 中的 P1 修复目标已完成。
- 核心工具链验收通过。
- 配置中心边界可通过 `git check-ignore` 验证。
- 无旧状态枚举、旧 prompt ID、旧路径字面量残留。
- 问题账本已更新为本轮修复闭环状态，当前范围内无 deferred 项。
