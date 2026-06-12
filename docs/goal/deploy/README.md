# Goal 体系单仓库最小部署包

> 本指南帮助你在 5 分钟内将 Goal 驱动交付体系的最小可用集部署到任意仓库。

## 1. 最小目录结构

```text
your-repo/
├── .config/goal/
│   ├── schema/
│   │   └── rules.yaml              # 控制面规则（从 ZoneCNH 复制模板）
│   ├── registry/
│   │   └── goals.yaml              # Goal Registry（空模板）
│   ├── matrix/
│   │   └── matrix.yaml             # Matrix（空模板）
│   ├── gates/
│   │   └── state.yaml              # Gate 状态
│   └── pipeline/
│       └── state.yaml             # Pipeline 状态机
├── docs/goal/tools/                # 核心工具（3 个文件）
│   ├── goal-workflow.sh
│   ├── lint-goal.sh
│   └── rule-drift-check.py
└── .github/workflows/
    └── goal-ci.yml                # 最小 CI
```

## 2. 一条命令初始化

```bash
# 1. 创建配置中心目录
mkdir -p .config/goal/{schema,registry,matrix,gates,pipeline,evidence,prompts}

# 2. 从 ZoneCNH 获取核心脚本
curl -sL https://raw.githubusercontent.com/ZoneCNH/ZoneCNH/main/docs/goal/tools/goal-workflow.sh \
  -o docs/goal/tools/goal-workflow.sh
curl -sL https://raw.githubusercontent.com/ZoneCNH/ZoneCNH/main/docs/goal/tools/lint-goal.sh \
  -o docs/goal/tools/lint-goal.sh
curl -sL https://raw.githubusercontent.com/ZoneCNH/ZoneCNH/main/docs/goal/tools/rule-drift-check.py \
  -o docs/goal/tools/rule-drift-check.py

# 3. 复制 rules.yaml 模板
curl -sL https://raw.githubusercontent.com/ZoneCNH/ZoneCNH/main/.config/goal/schema/rules.yaml \
  -o .config/goal/schema/rules.yaml

# 4. 初始化空 Registry 和 Matrix
cat > .config/goal/registry/goals.yaml << 'EOF'
# Goal Registry
goals: []
EOF

cat > .config/goal/matrix/matrix.yaml << 'EOF'
# Traceability Matrix (canonical edge model)
matrix: []
EOF

# 5. 首次验证
chmod +x docs/goal/tools/*.sh
bash docs/goal/tools/goal-workflow.sh preflight
```

## 3. 最小 CI Workflow

```yaml
# .github/workflows/goal-ci.yml
name: Goal CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  goal-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.10"

      - name: Install PyYAML
        run: pip install PyYAML

      - name: Goal Preflight
        run: bash docs/goal/tools/goal-workflow.sh preflight

      - name: Goal Validate (non-blocking)
        run: bash docs/goal/tools/goal-workflow.sh validate
        continue-on-error: true
```

> **注意**：以上 CI 使用 `ubuntu-latest`（hosted runner），适用于无 self-hosted runner 的仓库。ZoneCNH 主仓库强制使用 `[self-hosted, Linux, X64, homepage]`，其他仓库可按需选择。

## 4. 不复制的内容

以下文件属于 ZoneCNH 主仓库专属，**不需要**复制到其他仓库：

| 文件                            | 原因                           |
| ------------------------------- | ------------------------------ |
| `docs/goal/00-authority-map.md` | 权威边界定义，仅主仓库需要     |
| `docs/goal/03-pipeline.md`      | 管线 SSOT，其他仓库引用即可    |
| `docs/goal/04-gates.md`         | Gate SSOT，其他仓库引用即可    |
| `schema/goal.schema.yaml`       | Canonical schema，仅主仓库维护 |
| `schema/state-dictionary.yaml`  | 状态字典，仅主仓库维护         |
| `tools/self-test.sh`            | 工具链自测，仅主仓库需要       |
| `tools/goal-validate.py`        | 全量控制面验证，按需复制       |
| `tools/matrix-gen.py`           | 按需复制（有 Spec/Tasks 时）   |
| 全部 `docs/goal/1*.md ~ 2*.md`  | 方法论规范，引用主仓库文档即可 |

## 5. 三种采纳级别

| 级别          | 适用场景                       | 复制内容                                                      | CI 强度                  |
| ------------- | ------------------------------ | ------------------------------------------------------------- | ------------------------ |
| **Lint Only** | 想用 Goal 风格但不需要全流程   | `lint-goal.sh` + `rule-drift-check.py`                        | `preflight` only         |
| **Standard**  | 有 Goal/Spec/Tasks 制品        | 上述 + `goal-workflow.sh` + `.config/goal/` 目录              | `validate`（PR 阻断）    |
| **Full**      | 需要 Gate + Evidence + Release | 上述 + `goal-validate.py` + `matrix-gen.py` + `gate-check.sh` | `gate`（Release 前阻断） |

### 升级路径

```text
Lint Only → 首次创建 Goal → Standard → 首次 Release → Full
```

## 6. 常见问题

### Q: 我没有 Python 3.10+ 怎么办？

`lint-goal.sh` 和 `goal-workflow.sh preflight`（不含 Python 部分）可以在纯 Bash 环境运行。Python 工具（`rule-drift-check.py`, `goal-validate.py`）需要 3.10+。CI 中使用 `actions/setup-python@v5` 即可自动安装。

### Q: 必须用 self-hosted runner 吗？

不必须。ZoneCNH 主仓库因工具链隔离需求强制 self-hosted runner。其他仓库可以用 `ubuntu-latest` hosted runner，注意安装 PyYAML 依赖。

### Q: 我只想用 lint，不需要完整 Gate 怎么办？

选择"Lint Only"级别，只复制 `lint-goal.sh` 和 `rule-drift-check.py`，运行 `bash docs/goal/tools/lint-goal.sh .` 即可。Gate 检查只在有 `.config/goal/` 运行制品时才需要。

### Q: Matrix 怎么生成？

确保 Spec 和 Tasks 文件已创建后，安装 `matrix-gen.py` 并运行：

```bash
python3 docs/goal/tools/matrix-gen.py \
  --spec-dir module/ \
  --task-dir docs/goal/tasks/ \
  --output .config/goal/matrix/matrix.yaml \
  --goal-id GOAL-YYYYMMDD-NNN
```

### Q: 如何与主仓库保持同步？

```bash
# 周期性同步核心脚本
curl -sL https://raw.githubusercontent.com/ZoneCNH/ZoneCNH/main/docs/goal/tools/goal-workflow.sh \
  -o docs/goal/tools/goal-workflow.sh
```

主仓库 `CHANGELOG.md` 记录结构性变更，同步时查阅。
