# CI 部署文档

> FoundationX 文档枢纽 CI/CD 完整部署指南。
> 最后更新：2026-06-08

## 1. 概述

本仓库使用 GitHub Actions 作为 CI/CD 平台，运行在 **self-hosted runner**（`[self-hosted, linux, x64]`）上。

共 **5 个 workflow**、**28 个 job**，覆盖五个维度：

| Workflow          | 文件                | 职责                                                      | Job 数 |
| ----------------- | ------------------- | --------------------------------------------------------- | ------ |
| **Docs CI**       | `docs-ci.yml`       | 文档质量守卫（Markdown 格式、链接、敏感内容、Spec 结构）  | 12     |
| **Goal CI**       | `goal-ci.yml`       | Goal 驱动交付体系门禁（YAML、Registry、ID、Matrix、Gate） | 10     |
| **Outer Metrics** | `outer-metrics.yml` | 评分体系外部锚点采集与 Goodhart 检测                      | 2      |
| **Release**       | `release.yml`       | 版本发布（质量门禁 → manifest → GitHub Release）          | 3      |
| **Scripts Tests** | `scripts-tests.yml` | rule-scorer 单元测试与 shell 脚本烟雾测试                 | 2      |

## 2. Self-Hosted Runner 要求

### 2.1 Runner 标签

所有 workflow 使用以下标签：

```yaml
runs-on: [self-hosted, linux, x64]
```

### 2.2 预装依赖

self-hosted runner **必须预装**以下依赖，CI 不会自动安装：

| 依赖           | 最低版本  | 用途                                  | 安装命令（参考）                   |
| -------------- | --------- | ------------------------------------- | ---------------------------------- |
| `git`          | ≥ 2.30    | 所有 workflow                         | `apt install git`                  |
| `python3`      | ≥ 3.11    | Goal CI、Outer Metrics、Scripts Tests | `apt install python3`              |
| `pip`          | 随 Python | 安装 Python 包                        | `apt install python3-pip`          |
| `yamllint`     | latest    | Goal CI YAML 语法检查                 | `pip install yamllint`             |
| `pytest`       | latest    | Scripts Tests 单元测试                | `pip install pytest`               |
| `pyyaml`       | latest    | Goal CI Python 脚本解析 YAML          | `pip install pyyaml`               |
| `jq`           | ≥ 1.6     | Release manifest 解析                 | `apt install jq`                   |
| `node` / `npx` | ≥ 18      | Docs CI markdownlint-cli2             | 见 [Node.js 安装](#23-nodejs-安装) |
| `lychee`       | ≥ 0.15    | Docs CI / Release 链接检查            | 见 [lychee 安装](#24-lychee-安装)  |
| `bash`         | ≥ 4.0     | 所有 CI 脚本                          | 系统自带                           |

### 2.3 Node.js 安装

markdownlint-cli2 通过 `npx` 运行，需要 Node.js：

```bash
# 推荐使用 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc
nvm install 22
nvm use 22

# 或直接安装
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 2.4 lychee 安装

```bash
# 方法 1：cargo
cargo install lychee

# 方法 2：二进制
curl -LO https://github.com/lycheeverse/lychee/releases/latest/download/lychee-x86_64-unknown-linux-gnu.tar.gz
tar xzf lychee-x86_64-unknown-linux-gnu.tar.gz
sudo mv lychee /usr/local/bin/

# 方法 3：apt（版本可能较旧）
sudo apt install lychee
```

### 2.5 一键安装脚本

```bash
#!/usr/bin/env bash
# ci-deps-install.sh — CI 依赖一键安装
set -euo pipefail

echo "=== 安装系统包 ==="
sudo apt-get update
sudo apt-get install -y git python3 python3-pip jq

echo "=== 安装 Python 包 ==="
pip3 install --user yamllint pytest pyyaml

echo "=== 安装 Node.js ==="
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

echo "=== 安装 lychee ==="
if ! command -v lychee &>/dev/null; then
  curl -LO https://github.com/lycheeverse/lychee/releases/latest/download/lychee-x86_64-unknown-linux-gnu.tar.gz
  tar xzf lychee-x86_64-unknown-linux-gnu.tar.gz
  sudo mv lychee /usr/local/bin/
  rm -f lychee-x86_64-unknown-linux-gnu.tar.gz
fi

echo "=== 验证 ==="
git --version
python3 --version
node --version
jq --version
lychee --version
yamllint --version
pytest --version

echo "✅ 全部依赖安装完成"
```

## 3. Workflow 详解

### 3.1 Docs CI（文档质量守卫）

**文件**：`.github/workflows/docs-ci.yml`

**触发条件**：

| 触发                | 条件                                                                                                                                     |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `pull_request`      | 变更路径匹配 `*.md`、`docs/**/*.md`、`module/**/*.md`、`.github/workflows/*.yml`、`.github/ci/**`、`.markdownlint.json`、`.lycheeignore` |
| `push` (main)       | 同上                                                                                                                                     |
| `schedule`          | 每周一 09:17 UTC（北京时间 17:17）                                                                                                       |
| `workflow_dispatch` | 手动触发                                                                                                                                 |
| `workflow_call`     | 被其他 workflow 调用（Release 质量门禁复用）                                                                                             |

**权限**：`contents: read`

**Job 列表**（全部并行执行）：

| #   | Job                     | 超时  | 职责                                              | 工具/脚本                                 |
| --- | ----------------------- | ----- | ------------------------------------------------- | ----------------------------------------- |
| 1   | `markdownlint`          | 10min | Markdown 格式规范                                 | `DavidAnson/markdownlint-cli2-action@v19` |
| 2   | `link-check`            | 15min | 链接有效性检查                                    | `lycheeverse/lychee-action@v2`            |
| 3   | `grep-guard`            | 10min | 敏感内容守卫（凭据/本地路径/运行时目录/本地地址） | `.github/ci/grep-guard.sh`                |
| 4   | `status-consistency`    | 10min | 状态表与文档一致性                                | `.github/ci/status-consistency-check.sh`  |
| 5   | `spec-lint`             | 15min | Spec 23节结构校验、FR 连续性、模糊词检测          | `.github/ci/spec-lint.sh`                 |
| 6   | `spec-drift-guard`      | 10min | SPEC.md 篡改检测                                  | `.github/ci/spec-drift-guard.sh`          |
| 7   | `traceability-check`    | 10min | 追踪矩阵完整性                                    | `.github/ci/traceability-check.sh`        |
| 8   | `task-spec-validate`    | 10min | Task Spec 结构和一致性                            | `.github/ci/task-spec-validate.sh`        |
| 9   | `spec-status-report`    | 10min | Spec 状态报告生成                                 | `.github/ci/spec-status-report.sh`        |
| 10  | `glossary-consistency`  | 10min | 术语与 GLOSSARY.md 一致性                         | `.github/ci/glossary-consistency.sh`      |
| 11  | `anti-requirement-scan` | 10min | 反需求扫描                                        | `.github/ci/anti-requirement-scan.sh`     |
| 12  | `outer-metrics-guard`   | 10min | 宪法 §14.2 — 拒绝 LLM agent 写入 outer-metrics    | `scripts/outer-metrics-validate.sh`       |

**配置文件**：

- `.markdownlint.json` — Markdownlint 规则（行长 200、允许 HTML 元素等）
- `.lycheeignore` — 链接检查排除列表（计划中未创建的仓库、外部服务）

### 3.2 Goal CI（Goal 驱动交付体系门禁）

**文件**：`.github/workflows/goal-ci.yml`

**触发条件**：

| 触发                  | 条件                                                                                                                                                         |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `push` (main)         | 变更路径匹配 `.config/goal/**`、`docs/goal/**`、`docs/report/goal-*`、`.claude/agents/goal-*`、`.codex/agents/goal-*`、`.copilot/agents/goal-*`、`AGENTS.md` |
| `pull_request` (main) | 同上                                                                                                                                                         |

**依赖链**：

```
yaml-lint ──┬── registry-check ──┬── rule-drift-check ──┬── id-format-check
            │                    │                     ├── matrix-coverage
            │                    │                     ├── gate-check
            │                    │                     └── orphan-check
            ├── agent-check      │
            └── docs-check       │
                                 └── summary (always)
```

**Job 列表**：

| #   | Job                | 超时  | 依赖                   | 职责                                       |
| --- | ------------------ | ----- | ---------------------- | ------------------------------------------ |
| 1   | `yaml-lint`        | 10min | —                      | yamllint 校验 `.config/goal/**/*.yaml`     |
| 2   | `registry-check`   | 10min | yaml-lint              | 6 个注册表文件存在性 + 10 个 YAML 结构验证 |
| 3   | `rule-drift-check` | 10min | registry-check         | 规则源一致性检查                           |
| 4   | `id-format-check`  | 10min | rule-drift-check       | ID 格式正则校验（GOAL-YYYYMMDD-NNN 等）    |
| 5   | `matrix-coverage`  | 10min | rule-drift-check       | Matrix 覆盖率 ≥95%                         |
| 6   | `gate-check`       | 10min | rule-drift-check       | G0-G11 Gate 状态验证                       |
| 7   | `orphan-check`     | 10min | rule-drift-check       | Task→Goal 引用完整性                       |
| 8   | `agent-check`      | 10min | yaml-lint              | 5 个 goal agent 文件存在性 + frontmatter   |
| 9   | `docs-check`       | 10min | yaml-lint              | docs 与 AGENTS.md 交叉引用                 |
| 10  | `summary`          | 10min | 全部（`if: always()`） | 生成 Step Summary 汇总表                   |

### 3.3 Outer Metrics（评分体系外部锚点）

**文件**：`.github/workflows/outer-metrics.yml`

**触发条件**：

| 触发                | 条件                             |
| ------------------- | -------------------------------- |
| `push` (main)       | 任何变更                         |
| `schedule`          | 每日 02:30 UTC（北京时间 10:30） |
| `workflow_dispatch` | 手动触发                         |

**权限**：`contents: write`、`pull-requests: write`、`issues: write`

**Job 列表**：

| Job                     | 超时  | 职责                                                               |
| ----------------------- | ----- | ------------------------------------------------------------------ |
| `collect-and-evaluate`  | 20min | 采集 git 指标 → 计算相关系数 → Goodhart 检测 → 自动创建 PR + Issue |
| `validate-write-source` | 10min | （仅 PR）拒绝 LLM agent 写入 outer-metrics                         |

**数据流**：

```
module/*/SPEC.md → outer-metrics-from-git.sh → outer-metrics-eval.sh
                                                    ↓
                                          .omc/state/outer-metrics/
                                                    ↓
                                          create-pull-request (auto PR)
                                                    ↓
                                          Goodhart? → 创建 RSI Issue
```

**宪法 §14.2 守卫**：`scripts/outer-metrics-validate.sh` 检查 commit 作者白名单：

- ✅ `github-actions[bot]`
- ✅ commit message 含 `[outer-metrics]` 或 `[outer-metrics:manual]`
- ✅ commit message 含脚本名（`outer-metrics-from-git.sh`、`outer-metrics-eval.sh`）
- ❌ 任何 LLM agent（Claude、Codex、Copilot、task-executor）

### 3.4 Release（版本发布）

**文件**：`.github/workflows/release.yml`

**触发条件**：推送 `v*` 格式的 tag

**权限**：`contents: write`

**流程**：

```
tag push (v*)
    ↓
quality-gate (复用 docs-ci.yml 全部 12 个检查)
    ↓
build-manifest (生成 release-manifest.json + upload artifact)
    ↓
publish-release (下载 artifact → 生成 changelog → 创建 GitHub Release)
```

**Job 列表**：

| Job               | 超时            | 依赖           | 职责                                                            |
| ----------------- | --------------- | -------------- | --------------------------------------------------------------- |
| `quality-gate`    | 由 docs-ci 定义 | —              | 调用 `docs-ci.yml`（`workflow_call`）                           |
| `build-manifest`  | 15min           | quality-gate   | 生成 release manifest JSON                                      |
| `publish-release` | 10min           | build-manifest | 按 conventional commits 分类生成 changelog，创建 GitHub Release |

**发布流程**：

```bash
# 1. 确保 main 分支最新
git checkout main && git pull

# 2. 运行本地质量检查（可选）
bash .github/ci/grep-guard.sh
bash .github/ci/spec-lint.sh

# 3. 创建 tag
git tag v0.5.0

# 4. 推送 tag 触发 Release
git push origin v0.5.0
```

**Changelog 自动生成规则**：

| Commit 前缀 | 分类      |
| ----------- | --------- |
| `feat:`     | ✨ 新功能 |
| `fix:`      | 🐛 修复   |
| `docs:`     | 📝 文档   |
| 其他        | 🔧 其他   |

### 3.5 Scripts Tests（脚本健壮性）

**文件**：`.github/workflows/scripts-tests.yml`

**触发条件**：

| 触发                | 条件                                                      |
| ------------------- | --------------------------------------------------------- |
| `pull_request`      | 变更路径匹配 `scripts/**`、`docs/governance/scoring/**` |
| `push` (main)       | 同上                                                      |
| `workflow_dispatch` | 手动触发                                                  |

**Job 列表**：

| Job                 | 超时  | 职责                                                     |
| ------------------- | ----- | -------------------------------------------------------- |
| `rule-scorer-tests` | 10min | `pytest scripts/tests/ -v`                               |
| `shell-smoke`       | 10min | rule-scorer.py CLI 烟雾测试 + outer-metrics 脚本烟雾测试 |

## 4. CI 脚本清单

### 4.1 `.github/ci/` 脚本

| 脚本                           | 行数 | 职责                                                                         | 调用方           |
| ------------------------------ | ---- | ---------------------------------------------------------------------------- | ---------------- |
| `spec-lint.sh`                 | 539  | 23节结构、FR 连续性、模糊词、metadata、xlib-standard 专用门禁、Analysis Lint | docs-ci, release |
| `status-consistency-check.sh`  | ~250 | 状态表与文档交叉一致性                                                       | docs-ci, release |
| `task-spec-validate.sh`        | ~280 | Task Spec 结构和引用一致性                                                   | docs-ci          |
| `traceability-check.sh`        | ~190 | 追踪矩阵 FR↔证据映射                                                         | docs-ci, release |
| `grep-guard.sh`                | 132  | 4 类敏感内容扫描（凭据/运行时目录/本地地址/本地路径）                        | docs-ci, release |
| `glossary-consistency.sh`      | ~100 | 术语表一致性                                                                 | docs-ci          |
| `anti-requirement-scan.sh`     | ~110 | 反需求扫描                                                                   | docs-ci          |
| `spec-drift-guard.sh`          | ~70  | SPEC.md 篡改检测                                                             | docs-ci, release |
| `spec-status-report.sh`        | ~90  | 状态报告生成                                                                 | docs-ci, release |
| `generate-release-manifest.sh` | ~100 | Release manifest 生成                                                        | release          |

### 4.2 `scripts/` 脚本

| 脚本                        | 行数 | 职责                         | 调用方                                |
| --------------------------- | ---- | ---------------------------- | ------------------------------------- |
| `rule-scorer.py`            | ~450 | 规则评分引擎                 | scripts-tests                         |
| `pipeline.py`               | ~180 | 管线编排                     | —                                     |
| `arbiter.py`                | ~300 | 四源仲裁                     | —                                     |
| `score-validate.py`         | ~150 | 评分验证                     | —                                     |
| `outer-metrics-from-git.sh` | ~100 | git 指标采集                 | outer-metrics                         |
| `outer-metrics-eval.sh`     | ~180 | 相关系数计算 + Goodhart 检测 | outer-metrics, scripts-tests          |
| `outer-metrics-validate.sh` | ~90  | 写入源合法性校验             | docs-ci, outer-metrics, scripts-tests |

## 5. 配置文件

| 文件                   | 用途                                                              |
| ---------------------- | ----------------------------------------------------------------- |
| `.markdownlint.json`   | Markdownlint 规则配置（行长 200、允许 HTML 元素、禁用首行 H1 等） |
| `.lycheeignore`        | 链接检查排除列表（计划中未创建的仓库、不稳定外部服务）            |
| `.github/yamllint.yml` | yamllint 配置（Goal CI 使用）                                     |

## 6. 故障排查

### 6.1 常见问题

| 症状                          | 原因                             | 解决                                                                  |
| ----------------------------- | -------------------------------- | --------------------------------------------------------------------- |
| `lychee: command not found`   | runner 未安装 lychee             | 见 [2.4 lychee 安装](#24-lychee-安装)                                 |
| `npx: command not found`      | runner 未安装 Node.js            | 见 [2.3 Node.js 安装](#23-nodejs-安装)                                |
| `yamllint: command not found` | runner 未安装 yamllint           | `pip install yamllint`                                                |
| `pytest: command not found`   | runner 未安装 pytest             | `pip install pytest`                                                  |
| `jq: command not found`       | runner 未安装 jq                 | `apt install jq`                                                      |
| `timeout-minutes` 超时        | CI 脚本卡死或网络问题            | 检查 runner 网络连接，检查脚本是否有死循环                            |
| `outer-metrics-guard` 失败    | LLM agent 尝试修改 outer-metrics | 确保 outer-metrics 变更由 CI bot 或人工 `[outer-metrics:manual]` 提交 |
| `spec-lint` 报 23 节缺失      | SPEC.md 结构不完整               | 按 `module/README.md` 模板补齐 §1-§23                                 |
| `grep-guard` 误报             | 文档中讨论安全模式时引用关键词   | 在 `.lycheeignore` 或脚本白名单中排除                                 |

### 6.2 调试命令

```bash
# 本地运行单个 CI 脚本
bash .github/ci/grep-guard.sh
bash .github/ci/spec-lint.sh
bash .github/ci/status-consistency-check.sh

# 本地运行 markdownlint
npx markdownlint-cli2 "*.md" "docs/**/*.md" "module/**/*.md"

# 本地运行 lychee
lychee --verbose --exclude-loopback --exclude-file .lycheeignore '*.md' 'docs/**/*.md'

# 本地运行 yamllint
yamllint -c .github/yamllint.yml .config/goal/**/*.yaml

# 本地运行 pytest
pytest scripts/tests/ -v

# 本地运行 rule-scorer
python3 scripts/rule-scorer.py spec <module-name>
```

### 6.3 手动触发 Workflow

所有 workflow 均支持 `workflow_dispatch` 手动触发：

```bash
# 使用 GitHub CLI
gh workflow run docs-ci.yml
gh workflow run goal-ci.yml
gh workflow run outer-metrics.yml
gh workflow run scripts-tests.yml

# 触发 Release（需要先创建 tag）
git tag v0.5.0
git push origin v0.5.0
```

## 7. 架构决策记录

| 日期       | 决策                                                  | 理由                             |
| ---------- | ----------------------------------------------------- | -------------------------------- |
| 2026-06-08 | 全部 workflow 切换到 `[self-hosted, linux, x64]`      | 降低成本，利用已有 runner 资源   |
| 2026-06-08 | 所有 job 添加 `timeout-minutes`                       | 防止 self-hosted runner 挂起阻塞 |
| 2026-06-08 | 移除 `apt-get install` 和 `pip install` 步骤          | self-hosted runner 应预装依赖    |
| 2026-06-08 | release.yml 质量门禁改为 `workflow_call` 复用 docs-ci | 消除重复维护，DRY 原则           |
| 2026-06-08 | outer-metrics-guard 移除 PR-only 条件                 | workflow_call 复用时需全场景覆盖 |
| 2026-06-08 | scripts-tests smoke 去掉 `\|\| true`                  | CI 失败应真正阻断，不容忍错误    |

## 8. 维护清单

### 新增 CI 脚本时

- [ ] 脚本添加到 `.github/ci/` 或 `scripts/`
- [ ] 设置可执行权限 `chmod +x`
- [ ] 在对应 workflow 中添加 step
- [ ] 本地验证脚本可独立运行
- [ ] 更新本文档的脚本清单

### 新增 Workflow 时

- [ ] 使用 `[self-hosted, linux, x64]` runner
- [ ] 每个 job 添加 `timeout-minutes`
- [ ] 路径过滤避免无关变更触发
- [ ] 评估是否可通过 `workflow_call` 复用现有 workflow
- [ ] 更新本文档的 Workflow 概述

### Runner 环境变更时

- [ ] 更新本文档的预装依赖清单
- [ ] 更新一键安装脚本
- [ ] 在所有受影响的 workflow 上验证
