> 当前状态说明（2026-06-09）：本文件是 2026-06-08 的阶段性 lane 报告，不是当前全局评分权威。当前复评见 `docs/report/goal-structural-current-score-20260609.md`。

# Goal 规则归一化结构评分报告（98/100）

日期：2026-06-08
Lane：Registry / Lint / Scoring
目标：清理 Registry 边界，并补齐可执行评分证据。
结论：98/100；无红线；可作为本 lane 的通过证据。

## 评分摘要

| 维度 | 分值 | 证据 |
|------|------|------|
| Registry 边界 | 25/25 | Registry 固定为 6 个业务索引文件；Matrix、Gates、Pipeline、Evidence、Prompts 明确为配置中心旁路组件。 |
| 配置中心漂移检测 | 20/20 | `lint-goal.sh` 校验精确 6 文件、旁路组件位置、路径注释、旧版子系统口径残留。 |
| 状态与 Gate 检测 | 20/20 | 校验 Registry 状态枚举、Pipeline 状态字段、G0-G11 完整性、Gate status/verdict 枚举。 |
| Matrix / Evidence 检测 | 20/20 | 校验 Matrix 必填字段、`task_id` 回链 Task Registry、Matrix status/risk、Done/released 记录 evidence、Evidence 引用格式。 |
| 可执行证据 | 15/15 | `bash -n`、目标 lint、旧口径残留搜索、`git diff --check` 均通过。 |
| 风险扣分 | -2 | Evidence 引用仅校验格式与非空，不验证引用目标的业务语义；空 `evidence/`、`prompts/` 目录仅做边界存在校验。 |
| 总分 | 98/100 | 无红线、无阻断项。 |

## 红线检查

| 红线 | 结果 | 证据 |
|------|------|------|
| Registry 边界混入旁路组件 | PASS | `docs/goal/15-registry.md` 与 `.config/goal/README.md` 均声明 Registry 仅包含 6 个业务索引文件。 |
| Registry 文件数量漂移 | PASS | `lint-goal.sh` 要求 `.config/goal/registry/` 下仅存在 6 个指定 YAML 文件。 |
| Matrix 断开 Task 回链 | PASS | `lint-goal.sh` 校验每个 Matrix Row 的 `task_id` 存在于 Task Registry。 |
| Gate 集缺失 | PASS | `lint-goal.sh` 校验 G0-G11 共 12 个 Gate。 |
| Done / released 缺少证据 | PASS | `lint-goal.sh` 校验 Done Task 与 released Release 必须包含 evidence。 |

## 验证命令

```bash
bash -n docs/goal/tools/lint-goal.sh
docs/goal/tools/lint-goal.sh .config/goal
docs/goal/tools/lint-goal.sh docs/goal/15-registry.md
digit=7
rg -n "Registry ${digit}|${digit} 个子系统" docs/goal/15-registry.md .config/goal/README.md docs/goal/10-lint-rules.md docs/report/goal-structural-score-98-20260608.md
git diff --check
```

## 验证结果

| 命令 | 结果 |
|------|------|
| `bash -n docs/goal/tools/lint-goal.sh` | PASS |
| `docs/goal/tools/lint-goal.sh .config/goal` | PASS；`ERRORS=0`，`WARNINGS=0`。 |
| `docs/goal/tools/lint-goal.sh docs/goal/15-registry.md` | PASS；`ERRORS=0`，`WARNINGS=0`。 |
| 旧口径残留搜索 | PASS；无匹配。 |
| `git diff --check` | PASS |

## 剩余风险

- 当前 lint 使用 shell 与正则校验约束化 YAML 结构；如未来 Registry/Matrix/Gate YAML 引入复杂嵌套，应升级为 YAML parser。
- Evidence 引用规则覆盖非空、相对路径与父目录穿越，但不读取引用目标内容，也不判定业务证据质量。
- `evidence/` 与 `prompts/` 作为配置中心旁路目录当前只校验存在与边界归属，不要求目录内必须有文件。
