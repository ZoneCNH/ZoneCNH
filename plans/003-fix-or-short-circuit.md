# Plan 003: 修复 audit-status.py `or` 短路 bug

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat b4f486b..HEAD -- scripts/audit-status.py`
> If scripts/audit-status.py changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S（1 行修复 + 测试，约 15 分钟）
- **Risk**: LOW（修正 bug，不改 API）
- **Depends on**: 002（修改同一文件同一区域，合并后可一次 commit）
- **Category**: bug
- **Planned at**: commit `b4f486b`, 2026-06-15

## Why this matters

`scripts/audit-status.py:197` 有一个 Python 经典的 falsy 短路 bug：

```python
open_factory_blockers = set(blockers_doc.get("factory_blocking_modules") or sorted({...}))
```

Python 中空列表 `[]` 是 falsy。如果 `blockers_doc` 中 `factory_blocking_modules` 被显式设置为空列表 `[]`（表示"没有工厂阻塞模块"），`or` 会短路到右边的 `sorted({...})` — 从 `blockers` 列表中动态计算。这导致无法区分"字段不存在"和"字段显式为空"两种语义，使明确声明"无阻塞模块"失效。

## Current state

`scripts/audit-status.py:196-201`:
```python
factory_na = sum(1 for row in status_rows.values() if row["factory"] == "N/A")
open_factory_blockers = set(blockers_doc.get("factory_blocking_modules") or sorted({
    blocker.get("module")
    for blocker in blockers_doc.get("blockers", [])
    if blocker.get("status") == "open"
}))
```

- 第 197 行：`or sorted({...})` 在左操作数为 falsy（`None`、`[]`）时执行
- `blockers_doc.get("factory_blocking_modules")` 返回 `None`（键不存在）或值（可能是 `[]`）
- `[] or sorted({...})` → 执行右侧 → 计算所有 open blocker 的模块名集合
- 正确行为：仅当键不存在时使用动态计算；键存在时（哪怕是空列表），使用显式值

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| Python 语法检查 | `python3 -m py_compile scripts/audit-status.py` | exit 0 |
| 运行现有测试 | `pytest scripts/tests/test_audit_status.py -v` | 全部通过 |

## Scope

**In scope**:
- `scripts/audit-status.py:197` — 1 行逻辑修复

**Out of scope**:
- 不修改 `blockers_doc` 的数据结构
- 不修改 `.foundationx/blockers.json` 的内容

## Git workflow

- Branch: `fix/audit-status-or-bug`（与 Plan 002 合并为同一 branch）
- Commit 格式：`fix: audit-status.py 修复空列表 or 短路判定 (COR-01)`
- 建议与 Plan 002 合并为一个 commit（同一文件，关联修复）

## Steps

### Step 1: 替换 `or` 为显式 `None` 检查

将第 197 行：
```python
open_factory_blockers = set(blockers_doc.get("factory_blocking_modules") or sorted({
    blocker.get("module")
    for blocker in blockers_doc.get("blockers", [])
    if blocker.get("status") == "open"
}))
```

改为：
```python
_fbm = blockers_doc.get("factory_blocking_modules")
if _fbm is None:
    _fbm = sorted({
        blocker.get("module")
        for blocker in blockers_doc.get("blockers", [])
        if blocker.get("status") == "open"
    })
open_factory_blockers = set(_fbm)
```

这个修改保留了语义：
- `factory_blocking_modules` 存在时（包括空列表 `[]`），使用显式值 → `set([])` = 空集合
- `factory_blocking_modules` 不存在（`None`），动态计算 → `set(sorted({...}))`

**Verify**: `python3 -m py_compile scripts/audit-status.py` → exit 0

### Step 2: 验证修复

```bash
python3 -c "
# 模拟验证：显式空列表不被短路
import ast, sys

# 构造模拟数据
class MockDoc:
    def get(self, key, default=None):
        if key == 'factory_blocking_modules':
            return []  # 显式空列表 — 以前会短路到 sorted(...)
        return default

doc = MockDoc()
# 模拟修复后的逻辑
_fbm = doc.get('factory_blocking_modules')
if _fbm is None:
    _fbm = sorted(set())
result = set(_fbm)
assert result == set(), f'Expected empty set, got {result}'
print('PASS: empty list correctly results in empty set')
"
```

**Verify**: 输出 `PASS: empty list correctly results in empty set`

## Test plan

- 在 `scripts/tests/test_audit_status.py` 中新增：
  - `test_empty_factory_blocking_modules_not_short_circuited` — 构造 blockers JSON，其中 `factory_blocking_modules` 为空列表但有 open blockers，验证 `open_factory_blockers` 为空集合（而非被 open blockers 填充）

```bash
pytest scripts/tests/test_audit_status.py -v
```

**Verify**: 测试全部通过

## Done criteria

- [ ] `python3 -m py_compile scripts/audit-status.py` 通过
- [ ] 显式空列表 `[]` 正确产生空集合（不触发动态计算）
- [ ] `factory_blocking_modules` 键缺失时行为不变（仍动态计算）
- [ ] `pytest scripts/tests/test_audit_status.py -v` 全部通过
- [ ] `plans/README.md` 状态行已更新

## STOP conditions

- 第 197 行与你在此计划中看到的摘录不匹配 — 代码已漂移
- `blockers_doc.get("factory_blocking_modules")` 已在其他地方被修改为返回非 falsy 默认值 — 确认后关闭本计划
- 修复后现有测试失败 — 说明现有测试依赖了旧的短路行为

## Maintenance notes

- 这是 Python 中 `or` 短路的一个经典陷阱。项目中其他 `dict.get("key") or default` 模式可能也有同样问题——建议后续做一次全局扫描
- 查找命令：`grep -rn "\.get(.*) or " scripts/` — 检查是否还有其他类似模式
