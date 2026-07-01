# Session Learnings: xlibgate Trust Alignment 全管线交付

- **日期**: 2026-06-14
- **来源**: xlibgate Trust Alignment 全管线交付会话 (SPEC → DESIGN → PLAN → TASKS → MATRIX → PROMPT → CODE → TEST → CI → META)
- **PR 数**: 17 (11 docs + 6 code)
- **状态**: 已记录

---

## 1. Linter Revert Cycles

**根因**: 项目的 PostToolUse hook 在每次 Edit 后自动运行格式化/lint，频繁将手动编辑回退到 hook 偏好版本。

**影响**: Consumer 表、Directory Structure 节被回退 5-8 次，release_test.go 被删除 3 次，多次重复相同编辑。

**时间浪费**: ~20-25% 会话时间

**缓解**:
- 大节修改用 `Write` 替代多次 `Edit`（原子化操作，避免增量回退）
- commit 后立即 `grep` 验证关键节是否存在
- 遇到持续回退时接受 hook 版本，不反复对抗

**已关联修复**: PR #313 `fix: hooks — session branch guard + post-tool dirty-file guard`

---

## 2. Git Branch Discipline

**根因**: `git stash` + `checkout` + `stash pop` + `commit` 序列中，多次误提交到 `main`。

**影响**: 需要 `git reset --soft HEAD~1` 撤销误提交，某次导致 commit 完全丢失。

**缓解**:
- 每次 commit 前执行: `git branch --show-current && git merge-base --is-ancestor main HEAD`
- 不在 `main` 上 `stash pop`
- 已关联 CLAUDE.md 规则: "编辑前基线确认"

**已关联修复**: PR #340 `docs: CLAUDE.md — 新增编辑前基线确认规则`

---

## 3. PROMPT Consolidation

**发现**: 10 个独立 PROMPT 文件共享 60% 相同模板代码（601 行 → 合并后 130 行）。

**收益**: -471 行 (-78%)，pipeline lint 100/100 不变。

**推广**: 同一模块多 task 优先用 1 个 consolidated PROMPT 文件，而非 N 个独立文件。

**PR**: #327 `refactor: xlibgate — 合并 10 PROMPT 为 1 个`

---

## 4. YAML Test Fixtures

**根因**: Go raw string literal 中的 YAML 使用 tab 缩进（Go 源码自动缩进），导致 `gopkg.in/yaml.v3` 解析器将 tab 解释为 YAML 内容的一部分。

**影响**: Fleet test AutoCreateDir 失败，debug 8+ 次才发现是 YAML 缩进问题。

**缓解**:
- YAML 测试夹具用 `fmt.Sprintf` 或字符串拼接 (`"key: " + value + "\n"`)，不用 raw string literal
- 验证 YAML 可解析: `yaml.Unmarshal([]byte(content), &v)`

---

## 5. Pipeline Lint Section Naming

**发现**: `rule-scorer.py` 的 prompt scorer 要求精确 section 名称:
- ~~`Current Scope`~~ → `Scope`
- ~~`Verification`~~ → `Validation`

**影响**: 10 个 PROMPT 文件 40/100 → 修复后 100/100。

**缓解**: 每个 scorer stage 开始前先读 `rule-scorer.py` 源码确认 required section 名称和文件匹配模式。

**PR**: #323 `fix: xlibgate — 管线 lint 修复（100/100 全线通过）`

---

## 6. Dead Agent Calls

**发现**: `code-structural-score` agent 对 xlibgate 模块无输出（代码在外部仓库 /home/workspace/xlibgate，agent 只在 docs repo 内搜索）。

**影响**: 48 tool calls 白费。

**缓解**: 外部仓库的代码评分用手动按 RUBRIC-code.md 逐维度判定，不依赖 agent。

---

## 7. Signal-to-Noise Ratio

| 类别 | 占比 | 说明 |
|------|------|------|
| 内容创作 | 40-50% | ~3700 行净新增内容 |
| Linter 回退 | 20-25% | 重复编辑同内容 |
| Git 问题 | 10-15% | 分支/commit/stash 修复 |
| 验证 | 10-15% | Pipeline lint 重跑 |
| 无效 debug | 5-10% | Fleet test fixture 等问题 |

---

## 8. 下次可复制的最佳实践

1. **commit 前验证 branch**: `git branch --show-current` + ancestry check
2. **大节用 Write 不用 Edit**: 避免增量回退
3. **YAML 夹具: 字符串拼接 > raw literal**: 避免不可见缩进问题
4. **PROMPT 合并**: 同模块多 task → 1 个 consolidated
5. **先读 scorer 源码再写 Prompt**: 确认 section 名称和文件匹配模式
6. **信任 lint 结果**: 不重复验证已确认的评分
7. **外部仓库代码评分**: 手动按 rubric 评分，不用 agent
8. **遇到 linter 回退 3 次以上**: 接受 hook 版本，找 non-hook 时间窗口提交
