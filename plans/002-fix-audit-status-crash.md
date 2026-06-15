# Plan 002: 修复 audit-status.py 全模式崩溃（FileNotFoundError）

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
- **Effort**: S（加 try/except + 测试，约 30 分钟）
- **Risk**: LOW（仅增加错误处理，不改逻辑）
- **Depends on**: none
- **Category**: bug
- **Planned at**: commit `b4f486b`, 2026-06-15

## Why this matters

`scripts/audit-status.py` 是文档一致性验证的核心工具。在 `--full` 模式下，第 420-421 行直接调用 `load_json(".foundationx/status/index.json")` 和 `load_json(".foundationx/blockers.json")`，没有错误处理。如果任一 JSON 文件缺失或损坏，整个审计流程崩溃并抛出未处理的 `FileNotFoundError` 或 `JSONDecodeError`，中断 CI 管线。这是一个已上报但未修复的关键路径 bug。

## Current state

- `scripts/audit-status.py:420-421`:
  ```python
  foundation_status = load_json(".foundationx/status/index.json")
  blockers_doc = load_json(".foundationx/blockers.json")
  ```
- `load_json()` 函数定义在文件前部（约第 18-28 行），需要确认其错误处理行为
- 这两个 JSON 文件是 `.foundationx/` 目录下的 CI 生成文件，在本地开发环境中可能不存在
- 后续代码（第 422-424 行）使用 `.get()` 安全访问这些数据，所以默认空值是安全的
- 项目中其他类似的错误处理模式：`scripts/pipeline.py` 使用 `try/except` + `sys.exit(1)` 处理文件缺失

## Commands you will need

| Purpose | Command | Expected on success |
|---------|---------|---------------------|
| 复现崩溃 | `rm -f .foundationx/status/index.json && python3 scripts/audit-status.py` | FileNotFoundError 堆栈跟踪 |
| 修复后测试 | `python3 scripts/audit-status.py` | 优雅降级，继续执行（提示文件缺失） |
| 运行现有测试 | `pytest scripts/tests/test_audit_status.py -v` | 全部通过 |
| Python 语法检查 | `python3 -m py_compile scripts/audit-status.py` | exit 0 |

## Scope

**In scope**:
- `scripts/audit-status.py` — 仅修改第 420-421 行的错误处理

**Out of scope**:
- 不修改 `load_json()` 函数本身的签名或行为
- 不修改 `.foundationx/` 目录的任何文件
- 不修改其他脚本的错误处理

## Git workflow

- Branch: `fix/audit-status-crash`
- Commit 格式：`fix: audit-status.py 处理 .foundationx JSON 文件缺失`（遵循仓库 Conventional Commits 规范）
- 不要推送或创建 PR，除非操作员指示

## Steps

### Step 1: 确认 load_json() 的错误行为

打开 `scripts/audit-status.py`，找到 `load_json()` 函数（约第 18-28 行）。确认它在文件不存在时是抛出异常还是返回 None。

```bash
grep -n "def load_json" scripts/audit-status.py
```

读取该函数的实现，确认错误处理行为。

**Verify**: 理解 `load_json()` 在文件缺失时的行为。

### Step 2: 添加 try/except 保护

在第 420-421 行周围添加错误处理：

```python
# ── 8. Cross-dimension: RELEASE/FACTORY ↔ fact layer ──────
print("\n--- 8. Cross-dimension checks ---")
try:
    foundation_status = load_json(".foundationx/status/index.json")
except (FileNotFoundError, json.JSONDecodeError):
    print("  WARNING: .foundationx/status/index.json not found or invalid, skipping cross-dimension checks")
    foundation_status = {}
try:
    blockers_doc = load_json(".foundationx/blockers.json")
except (FileNotFoundError, json.JSONDecodeError):
    print("  WARNING: .foundationx/blockers.json not found or invalid, skipping cross-dimension checks")
    blockers_doc = {}
```

（注意：需要确认文件顶部已 `import json`，通常已有）

**Verify**: `python3 -m py_compile scripts/audit-status.py` → exit 0

### Step 3: 验证修复

临时移除 JSON 文件验证降级行为：
```bash
# 备份（如果文件存在）
[ -f .foundationx/status/index.json ] && cp .foundationx/status/index.json /tmp/index.json.bak
[ -f .foundationx/blockers.json ] && cp .foundationx/blockers.json /tmp/blockers.json.bak

# 模拟文件缺失
rm -f .foundationx/status/index.json
python3 scripts/audit-status.py 2>&1 | grep -q "WARNING.*index.json"
echo "exit $? (期望 0 — 找到 WARNING 消息)"

# 恢复文件
[ -f /tmp/index.json.bak ] && mv /tmp/index.json.bak .foundationx/status/index.json
[ -f /tmp/blockers.json.bak ] && mv /tmp/blockers.json.bak .foundationx/blockers.json
```

**Verify**: 两个 grep 都返回 0（WARNING 消息被打印且脚本未崩溃）

## Test plan

- 在 `scripts/tests/test_audit_status.py` 中新增测试：
  - `test_full_mode_handles_missing_index_json` — 使用 `tmp_path` 创建不含 index.json 的临时 `.foundationx` 目录，验证 `audit-status.py` 不会崩溃
  - `test_full_mode_handles_missing_blockers_json` — 同上，针对 blockers.json
  - 参考现有测试的结构：`test_audit_status_full_mode_runs_clean()` 的模式

```bash
pytest scripts/tests/test_audit_status.py -v
```

**Verify**: 测试全部通过，包括 2 个新增测试

## Done criteria

- [ ] `python3 -m py_compile scripts/audit-status.py` 没有语法错误
- [ ] 模拟 `.foundationx/status/index.json` 缺失时脚本打印 WARNING 并继续执行
- [ ] 模拟 `.foundationx/blockers.json` 缺失时脚本打印 WARNING 并继续执行
- [ ] 两个文件都存在时行为不变（回归检查）
- [ ] `pytest scripts/tests/test_audit_status.py -v` 全部通过
- [ ] `plans/README.md` 状态行已更新

## STOP conditions

- `load_json()` 在文件缺失时已经返回 None（已有正确处理）— 确认后记录，关闭本计划
- 第 420-421 行与你在此计划中看到的摘录不匹配 — 代码已漂移，重新评估
- 修复后 `test_audit_status_full_mode_runs_clean()` 失败 — 说明 `.foundationx/` 数据被该测试依赖，需要调整测试而非修复代码
- 文件实际存在于本地但 CI 环境缺少 — 确认 CI 的 foundation JSON 生成步骤先于 audit-status 运行

## Maintenance notes

- 注意 `load_json()` 可能在其他地方也被调用但没有错误处理 — 本计划仅修第 420-421 行，但若 audit 发现其他位置有类似问题，应单独立计划
- 后续新增 `load_json()` 调用时，遵循本计划的错误处理模式（安全默认值 + WARNING 消息）
