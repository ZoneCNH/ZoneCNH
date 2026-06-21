# Context Packet — TASK-XLIB-001

> PR-2: 文档对齐 — 重写 README、standard.md、INDEX.md
> 工作分支: `feat/xlib-v1-docs`
> 工作目录: /home/xlib_standard/.worktree/workspaces/feat/xlib-v1-docs

## Current Task

TASK-XLIB-001: 文档对齐 — 重写 README、standard.md、INDEX.md

## Related Spec

- module/xlib_standard/SPEC.md (§1 概述, §14 目录结构)

## Related Requirements

- FR-001: 定义基座库标准规范
- FR-006: 文档与示例管理
- AC-001: standard.md 包含全部规则
- AC-016: README 描述五类职责（Standard Source / Go Reference Template / Generator / Harness Gate / Evidence Runtime）
- AC-017: examples 提供最小可运行示例

## Current Scope

重写 3 个文档文件：

1. **README.md** — 描述五类职责（Standard Source / Go Reference Template / Generator / Harness Gate / Evidence Runtime），不超过 200 行
2. **docs/standard.md** — 完整标准规范，包含目录结构、命名规则、go.mod 规则、错误处理规则、契约规则、测试规则
3. **docs/INDEX.md** — 文档索引，仅列出 9 个保留文件

## Out of Scope

- 不修改 `SPEC.md`、`TRACEABILITY.md`
- 不修改 `tasks/` 目录
- 不修改代码文件（`pkg/`、`contracts/`）
- 不新增文档，只重写现有文档

## Validation Commands

```bash
# README 不超过 200 行
wc -l README.md | awk '{if ($1 > 200) exit 1}'

# standard.md 包含关键章节
grep -q "## 目录结构" docs/standard.md
grep -q "## 命名规则" docs/standard.md
grep -q "## go.mod 规则" docs/standard.md
grep -q "## 错误处理" docs/standard.md
grep -q "## 契约规则" docs/standard.md
grep -q "## 测试规则" docs/standard.md

# INDEX.md 存在且合理
test -f docs/INDEX.md && wc -l docs/INDEX.md | awk '{if ($1 > 50) exit 1}'
```

## Required Output

1. 文件变更清单
2. 需求覆盖表
3. 验证结果

## Evidence Format

完成后提交 evidence 到 `.config/goal/evidence/` 目录，格式如下：

```markdown
- **Evidence ID**: EVID-TEST-TASK-XLIB-001-001
- **Status**: PASS
- **Files Changed**: <实际修改的文件列表>
- **Commands Run**: <实际执行的命令及输出>
```

## Project Rules

- Follow AGENTS.md
- 使用中文
- 引用组件用 `https://github.com/ZoneCNH/<repo>` 格式
- 不引入新依赖

## Test Case Reference

参见 `module/xlib_standard/TRACEABILITY.md` FR-007 对应 TC-019~TC-020。文档变更通过 grep 验证内容完整性。
