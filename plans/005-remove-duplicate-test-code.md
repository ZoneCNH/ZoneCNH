# Plan 005: 删除 test_audit_status.py 重复代码

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md`.
>
> **Drift check (run first)**: `git diff --stat b4f486b..HEAD -- scripts/tests/test_audit_status.py`
> If test_audit_status.py changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding; on a
> mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2（维护隐患，当前行为正确）
- **Effort**: S（删除 60 行，约 10 分钟）
- **Risk**: LOW（两份代码完全一致，删除重复不会改变行为）
- **Depends on**: none（但建议在 002、003 修复后再做，避免冲突）
- **Category**: tests
- **Planned at**: commit `b4f486b`, 2026-06-15

## Why this matters

`scripts/tests/test_audit_status.py` 中有两份完全相同的函数定义：
- `load_audit_status_namespace()` 定义在 `:72-79` 和 `:130-137`
- `test_compare_multidimensional_projection_detects_drift_and_overclaims()` 定义在 `:82-128` 和 `:140-185`

第二份覆盖第一份（Python 模块级定义语义）。pytest 对两个 `test_*` 函数各执行一次（因为两次定义结果是同一个函数对象），浪费 CI 时间。更严重的是：如果有人只编辑第一份（误以为它是唯一的），修改不会生效——第二份覆盖第一份。

## Current state

`scripts/tests/test_audit_status.py:130-185` — 第二份重复：
```python
def load_audit_status_namespace():
    """Load audit_status module into a namespace for testing."""
    ...

def test_compare_multidimensional_projection_detects_drift_and_overclaims():
    """Multidimensional projection comparison catches drift and overclaims."""
    ...
```

第 72-128 行有相同内容的第一份定义。

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| 确认重复 | `grep -n "def load_audit_status_namespace\|def test_compare_multidimensional_projection_detects_drift" scripts/tests/test_audit_status.py` | 每个函数名出现 2 次 |
| Python 语法检查 | `python3 -m py_compile scripts/tests/test_audit_status.py` | exit 0 |
| 运行测试 | `pytest scripts/tests/test_audit_status.py -v` | 全部通过 |

## Scope

**In scope**:
- `scripts/tests/test_audit_status.py` — 删除第 130-185 行

**Out of scope**:
- 不修改测试逻辑本身
- 不修改其他测试文件
- 不修改被测试的 `audit-status.py`

## Git workflow

- Branch: `test/remove-duplicate-test-code`
- Commit 格式：`test: 删除 test_audit_status.py 重复函数定义`
- 建议与 002/003 合并为同一 PR

## Steps

### Step 1: 确认两份定义完全一致

```bash
python3 -c "
with open('scripts/tests/test_audit_status.py') as f:
    lines = f.readlines()

# 提取第一份定义的行范围 (约 72-128)
first = ''.join(lines[71:128])
# 提取第二份定义的行范围 (约 130-185)
second = ''.join(lines[129:185])

if first == second:
    print('CONFIRMED: definitions are identical — safe to delete lines 130-185')
else:
    print('WARNING: definitions differ — manual review needed')
    import difflib
    for line in difflib.unified_diff(first.splitlines(), second.splitlines()):
        print(line)
"
```

**Verify**: 输出 `CONFIRMED: definitions are identical`

### Step 2: 删除第二份重复定义

用 Edit 工具删除第 130-185 行（第二份 `load_audit_status_namespace` 和 `test_compare_multidimensional_projection_detects_drift_and_overclaims` 的定义）。

```python
# 精确 old_string（从文件实际内容复制）：
# 第 129 行的空行 + 第 130-137 行的 load_audit_status_namespace + 空行 + 第 140-185 行的测试函数 + 结尾空行
```

**Verify**: `grep -c "def load_audit_status_namespace" scripts/tests/test_audit_status.py` → `1`

### Step 3: 验证删除后测试通过

```bash
python3 -m py_compile scripts/tests/test_audit_status.py
pytest scripts/tests/test_audit_status.py -v
```

**Verify**: 所有测试通过，且 `test_compare_multidimensional_projection_detects_drift_and_overclaims` 只运行 1 次（而非 2 次）

## Test plan

- 无需新增测试（这是删除死代码，不改变行为）
- 验证命令：`pytest scripts/tests/test_audit_status.py -v` → 全部通过，测试数量不变

## Done criteria

- [ ] `grep -c "def load_audit_status_namespace" scripts/tests/test_audit_status.py` → `1`
- [ ] `grep -c "def test_compare_multidimensional_projection_detects_drift" scripts/tests/test_audit_status.py` → `1`
- [ ] `python3 -m py_compile scripts/tests/test_audit_status.py` 通过
- [ ] `pytest scripts/tests/test_audit_status.py -v` 全部通过
- [ ] `plans/README.md` 状态行已更新

## STOP conditions

- 两份定义不完全一致 — 手工审查差异，确定保留哪份
- 删除后测试失败 — 说明有其他代码引用了被删除的行号，需要确认原因
- 文件结构与上述行号不匹配 — 代码已漂移

## Maintenance notes

- 这个重复很可能是 copy-paste 产物。建议在 CI 中添加 `pytest --flake-finder` 或 pylint 的 duplicate-code 检查
- 检查命令：`grep -n "def " scripts/tests/*.py | sort -t: -k3 | uniq -f1 -d` — 查找跨文件的重复函数名
