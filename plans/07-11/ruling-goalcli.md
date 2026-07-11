# 治理裁决 RULING-001: goalcli 归属

**裁决日期**: 2026-07-11
**裁决编号**: RULING-001
**裁决者**: FoundationX Governance
**状态**: FINAL

## 背景

xlib_standard (XLS-002)、xlibgate (XLG-001)、xlib_harness (XLH-002) 三方同声称要"删除/迁出 goalcli runtime 重叠"。但无一方声明 goalcli 的最终归属。三个模块同时删除意味着 goalcli 从系统中消失，但 21 个管线 agent prompt 仍然引用它。

此矛盾已在分析报告 §2.2 矛盾 1 中标记为 HIGH 严重度，并在 §P0-1 中被列为 P0 优先修复项。

## 裁决

**goalcli 并入 xlib_harness**，作为 `harness goalcli` 子命令。

### 方案评估

| 方案                 | 描述                             | 优势                                       | 劣势                                           | 裁决 |
| -------------------- | -------------------------------- | ------------------------------------------ | ---------------------------------------------- | ---- |
| A: 并入 xlib_harness | goalcli 成为 harness 子命令      | harness 已负责 CLI contract；单一 CLI 入口 | harness 当前 v0.3.0，goalcli 需要成熟 CLI 框架 | **采用** |
| B: 独立工具          | goalcli 成为独立 Foundation 模块 | 关注点分离                                 | 增加维护负担；违反角色去重原则                 | 排除 |
| C: 废弃              | 管线 agent 直接调用 harness CLI  | 最简                                       | 21 agent prompt 全部引用 goalcli，迁移成本高   | 排除 |

### 采用理由

1. xlib_harness 已负责 CLI contract (XLH-001)，吸收 goalcli 是同一责任的纵向深化
2. 单一 CLI 入口 (`harness goalcli`) 减少维护负担
3. 符合标准控制平面角色去重原则（宪法 §12）
4. xlib_harness 当前 v0.3.0 状态有足够的成长空间吸收 goalcli

### 排除的方案

- **方案 B（独立工具）**：增加维护负担，违反角色去重原则，且 goalcli 功能与 xlib_harness CLI 高度重叠
- **方案 C（废弃）**：21 agent prompt 全部引用 goalcli，迁移成本过高；管道化 agent 的切换窗口与 25 模块修复窗口重叠风险不可接受

## 实施步骤

### 步骤 1：创建 ownership 声明

在 `xlib_harness` 仓库创建 `OWNERSHIP-GOALCLI.yaml`：

```yaml
# /home/workspace/xlib_harness/OWNERSHIP-GOALCLI.yaml
module: goalcli
canonical_owner: xlib_harness
decision_date: 2026-07-11
rationale: |
  goalcli 作为 FoundationX 管线的 CLI 入口，并入 xlib_harness 以消除
  xlib_standard/xlibgate/xlib_harness 三方复制。
consumers:
  - .claude/agents/goal-*.md # 21 agent prompt 引用 goalcli
  - .codex/agents/goal-*.toml
  - .copilot/agents/goal-*.md
deprecation_schedule:
  - phase: xlib_standard
    action: delete cmd/goalcli/
    deadline: XLS-002 completion
  - phase: xlibgate
    action: delete internal/goalcli/
    deadline: XLG-001 completion
  - phase: xlib_harness
    action: absorb into cmd/goalcli/
    deadline: XLH-009 (new work package)
migration_guide: docs/goalcli-migration.md
```

### 步骤 2：新增 xlib_harness 工作包

| ID      | P   | 任务                        | 验收                                                                           |
| ------- | --- | --------------------------- | ------------------------------------------------------------------------------ |
| XLH-009 | P0  | absorb goalcli into harness | `harness goalcli` 子命令覆盖原 goalcli 全部功能；旧路径返回 deprecation notice |

### 步骤 3：批量更新 agent prompt 引用

```bash
# 批量替换 agent prompt 中的 goalcli 引用
for agent_dir in .claude/agents .codex/agents .copilot/agents; do
  if [ -d "$agent_dir" ]; then
    find "$agent_dir" -type f -print0 | xargs -0 sed -i \
      's|goalcli |harness goalcli |g'
  fi
done

# 验证：任何残留的裸 goalcli 引用都应被 flag
grep -rn 'goalcli ' .claude/agents/ .codex/agents/ .copilot/agents/ \
  | grep -v 'harness goalcli' \
  | grep -v 'OWNERSHIP-GOALCLI'
```

### 步骤 4：边界 gate 残留检测

在 `xlib_standard` 和 `xlibgate` 仓库的 CI 中添加 goalcli 残留检测：

```yaml
# .github/workflows/boundary-gates.yml (追加)
jobs:
  goalcli-ownership:
    runs-on: [self-hosted, ephemeral]
    steps:
      - name: verify goalcli not owned by xlib_standard
        run: |
          if [ -d cmd/goalcli ] || [ -d internal/goalcli ]; then
            echo "FAIL: goalcli still exists in xlib_standard"
            exit 1
          fi
          echo "PASS: goalcli ownership transferred to xlib_harness"
```

在 `xlibgate` 仓库做相同检测。

## 受影响的制品

| 制品路径 | 变更类型 | 说明 |
|---------|---------|------|
| `/home/workspace/xlib_standard/cmd/goalcli/` | 删除 | goalcli 迁出 |
| `/home/workspace/xlibgate/internal/goalcli/` | 删除 | goalcli 迁出 |
| `/home/workspace/xlib_harness/cmd/goalcli/` | 新增 | 吸收 goalcli |
| `/home/workspace/xlib_harness/OWNERSHIP-GOALCLI.yaml` | 新增 | 归属声明 |
| `.claude/agents/goal-*.md` | 修改 | `goalcli` → `harness goalcli` |
| `.codex/agents/goal-*.toml` | 修改 | 同上 |
| `.copilot/agents/goal-*.md` | 修改 | 同上 |
| `xlib_standard/.github/workflows/boundary-gates.yml` | 新增 gate | goalcli 残留检测 |
| `xlibgate/.github/workflows/boundary-gates.yml` | 新增 gate | goalcli 残留检测 |

## 回退条件

如果 xlib_harness 在 30 天内无法完成 goalcli 吸收（以 XLH-009 验收通过为标志），将 goalcli 恢复为独立工具并留在 xlib_standard 作为临时托管方。回退触发条件：

1. XLH-009 30 天内未通过验收
2. `harness goalcli` 子命令覆盖度 < 原 goalcli 功能的 100%
3. 迁移过程引入新的管线 regression

## 关联工作包

| 工作包 | 模块 | 优先级 | 关系 |
|-------|------|--------|------|
| XLS-002 | xlib_standard | P0 | goalcli 删除 |
| XLG-001 | xlibgate | P0 | goalcli 删除 |
| XLH-009 | xlib_harness | P0 | goalcli 吸收（新增） |

## 签署

本裁决由 FoundationX Governance 根据分析报告 `/home/workspace/ZoneCNH/report/07-11/07-11-analysis.md` §2.2 矛盾 1 和 §P0-1 生成。裁决为 FINAL 状态，不可上诉，回退仅可在回退条件满足时触发。
