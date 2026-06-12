# CI 部署文档

> FoundationX 文档枢纽 CI/CD 完整部署指南。
> 最后更新：2026-06-11

## 1. 概述

本仓库使用 GitHub Actions 作为 CI/CD 平台，所有直接声明 runner 的 job 统一运行在 **self-hosted runner**（`[self-hosted, Linux, X64, homepage]`）上。Reusable workflow job 只能调用仓库内 workflow，因此被调用 workflow 继续受同一 runner 规则约束。部署到运行环境或远端机器时，目标机器池统一为 **`sre/`**。

共 **9 个 workflow**、**41 个 top-level job**（其中 **39** 个直接声明 `runs-on`，**2** 个调用仓库内 reusable workflow），覆盖仓库文档、Goal 体系、依赖矩阵、外部评分锚点、发布元数据和 runner 烟雾测试：

| Workflow             | 文件                   | 职责                                                      | Job 数 |
| -------------------- | ---------------------- | --------------------------------------------------------- | ------ |
| **Docs CI**          | `docs-ci.yml`          | 文档质量守卫、workflow 策略守卫、Spec 结构检查            | 13     |
| **Goal CI**          | `goal-ci.yml`          | Goal 驱动交付体系门禁（YAML、Registry、ID、Matrix、Gate） | 12     |
| **Deps Matrix**      | `deps-matrix.yml`      | Foundation 依赖矩阵检查和 PR 汇总                         | 4      |
| **Outer Metrics**    | `outer-metrics.yml`    | 评分体系外部锚点采集与 Goodhart 检测                      | 2      |
| **Release**          | `release.yml`          | 版本发布元数据（质量门禁 → manifest → GitHub Release）    | 5      |
| **Scripts Tests**    | `scripts-tests.yml`    | rule-scorer 单元测试与 shell 脚本烟雾测试                 | 2      |
| **Runner Test**      | `runner-test.yml`      | self-hosted runner 手动探测                               | 1      |
| **Self-Hosted Test** | `self-hosted-test.yml` | self-hosted runner 基线烟雾测试                           | 1      |
| **Minimal Test**     | `minimal-test.yml`     | 最小 workflow 连通性测试                                  | 1      |

## 2. Self-Hosted Runner 与部署目标要求

### 2.1 Runner 标签

所有直接声明 runner 的 workflow job 必须使用完全一致的标签：

```yaml
runs-on: [self-hosted, Linux, X64, homepage]
```

禁止项：

- `ubuntu-latest`、`macos-*`、`windows-*` 等 GitHub-hosted runner
- `Linux` / `X64` 大小写漂移
- 未批准的业务、个人或模块专属额外 label；当前仓库批准的项目标签仅为 `homepage`
- 调用外部 reusable workflow 绕过仓库内 runner 策略

job 级 reusable workflow `uses:` 只能指向 `./.github/workflows/*`。该规则由 `.github/ci/workflow-policy-guard.sh` 强制校验，覆盖直接 `runs-on`、仓库内 reusable workflow 调用和部署目标声明。

### 2.2 部署目标

- 部署到运行环境或远端机器的 job 必须统一落在 `sre/` 机器池。
- workflow 不得通过业务机、个人机或模块专属 runner label 表达部署目标；目标选择应由 SRE 入口、环境变量或部署清单完成。
- `release.yml` 当前只创建 GitHub Release 元数据，不等同机器部署；若未来加入真实部署步骤，必须显式声明 `sre/` 目标并通过 workflow 策略守卫。

### 2.3 基础依赖

self-hosted runner **必须预装**以下基础依赖。Python 包依赖由 job-local 工具链安装，不要求 runner 全局预装：

| 依赖           | 最低版本  | 用途                                  | 安装命令（参考）                   |
| -------------- | --------- | ------------------------------------- | ---------------------------------- |
| `git`          | ≥ 2.30    | 所有 workflow                         | `apt install git`                  |
| `python3`      | ≥ 3.11    | Goal CI、Outer Metrics、Scripts Tests | `apt install python3`              |
| `python3-venv` | 随 Python | job-local Python 工具链               | `apt install python3-venv`         |
| `pip`          | 随 Python | job-local Python 工具链 bootstrap     | `apt install python3-pip`          |
| `jq`           | ≥ 1.6     | Release manifest 解析                 | `apt install jq`                   |
| `node` / `npx` | ≥ 18      | Docs CI markdownlint-cli2             | 见 [Node.js 安装](#24-nodejs-安装) |
| `lychee`       | ≥ 0.15    | Docs CI / Release 链接检查            | 见 [lychee 安装](#25-lychee-安装)  |
| `bash`         | ≥ 4.0     | 所有 CI 脚本                          | 系统自带                           |

`yamllint`、`pytest`、`pyyaml` 等 Python 依赖由 CI job 通过 `docs/goal/tools/setup-ci-toolchain.sh` 写入 job-local `.cache/ci-python/`，不得要求 runner 全局预装。

### 2.4 Node.js 安装

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

### 2.5 lychee 安装

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

### 2.6 一键安装脚本

```bash
#!/usr/bin/env bash
# ci-deps-install.sh — CI 依赖一键安装
set -euo pipefail

echo "=== 安装系统包 ==="
sudo apt-get update
sudo apt-get install -y git python3 python3-venv python3-pip jq

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

echo "=== 验证基础工具 ==="
git --version
python3 --version
node --version
jq --version
lychee --version

echo "=== 验证 job-local Python 工具链 ==="
bash docs/goal/tools/setup-ci-toolchain.sh
. .cache/ci-python/bin/activate
python -c "import yaml, pytest; print('python deps ok')"
yamllint --version
pytest --version
deactivate

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
| 4   | `workflow-policy-guard` | 10min | 全局 runner 与部署目标策略守卫                    | `.github/ci/workflow-policy-guard.sh`     |
| 5   | `status-consistency`    | 10min | 状态表与文档一致性                                | `.github/ci/status-consistency-check.sh`  |
| 6   | `spec-lint`             | 15min | Spec 23节结构校验、FR 连续性、模糊词检测          | `.github/ci/spec-lint.sh`                 |
| 7   | `spec-drift-guard`      | 10min | SPEC.md 篡改检测                                  | `.github/ci/spec-drift-guard.sh`          |
| 8   | `traceability-check`    | 10min | 追踪矩阵完整性                                    | `.github/ci/traceability-check.sh`        |
| 9   | `task-spec-validate`    | 10min | Task Spec 结构和一致性                            | `.github/ci/task-spec-validate.sh`        |
| 10  | `spec-status-report`    | 10min | Spec 状态报告生成                                 | `.github/ci/spec-status-report.sh`        |
| 11  | `glossary-consistency`  | 10min | 术语与 GLOSSARY.md 一致性                         | `.github/ci/glossary-consistency.sh`      |
| 12  | `anti-requirement-scan` | 10min | 反需求扫描                                        | `.github/ci/anti-requirement-scan.sh`     |
| 13  | `outer-metrics-guard`   | 10min | 宪法 §14.2 — 拒绝 LLM agent 写入 outer-metrics    | `scripts/outer-metrics-validate.sh`       |

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
quality-gate (复用 docs-ci.yml 全部 13 个检查)
    + goal-control-plane (复用 goal-ci.yml 全部 12 个检查)
    ↓
release-gate (执行 Goal 发布硬阻断)
    ↓
build-manifest (生成 release-manifest.json + upload artifact)
    ↓
publish-release (下载 artifact → 生成 changelog → 创建 GitHub Release)
```

当前 Release workflow 只创建 GitHub Release 元数据，不执行机器部署。若后续增加真实部署步骤，部署目标必须统一为 `sre/` 机器池。

**Job 列表**：

| Job                  | 超时             | 依赖                              | 职责                                                            |
| -------------------- | ---------------- | --------------------------------- | --------------------------------------------------------------- |
| `quality-gate`       | 由 docs-ci 定义  | —                                 | 调用 `docs-ci.yml`（`workflow_call`）                           |
| `goal-control-plane` | 由 goal-ci 定义  | —                                 | 调用 `goal-ci.yml`（`workflow_call`）                           |
| `release-gate`       | 10min            | quality-gate, goal-control-plane  | 执行 Goal release gate 并上传产物                               |
| `build-manifest`     | 15min            | release-gate                      | 生成 release manifest JSON                                      |
| `publish-release`    | 10min            | build-manifest                    | 按 conventional commits 分类生成 changelog，创建 GitHub Release |

**发布流程**：

```bash
# 1. 确保 main 分支最新
git checkout main && git pull

# 2. 运行本地质量检查（可选）
bash .github/ci/grep-guard.sh
bash .github/ci/workflow-policy-guard.sh
bash .github/ci/spec-lint.sh

# 3. 创建 tag
git tag v0.5.0

# 4. 推送 tag 触发 Release
git push origin v0.5.0
```

**Changelog 自动生成规则**：

| Commit 前缀 | 分类      |
| ----------- | --------- |
| `feat:`     | ✨ 新功能  |
| `fix:`      | 🐛 修复    |
| `docs:`     | 📝 文档    |
| 其他        | 🔧 其他    |

### 3.5 Scripts Tests（脚本健壮性）

**文件**：`.github/workflows/scripts-tests.yml`

**触发条件**：

| 触发                | 条件                                                      |
| ------------------- | --------------------------------------------------------- |
| `pull_request`      | 变更路径匹配 `scripts/**`、`docs/governance/scoring/**`   |
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
| `workflow-policy-guard.sh`     | 131  | 全局 runner 与 `sre/` 部署目标策略守卫                                       | docs-ci          |
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

| 症状                          | 原因                              | 解决                                                                  |
| ----------------------------- | --------------------------------- | --------------------------------------------------------------------- |
| `lychee: command not found`   | runner 未安装 lychee              | 见 [2.5 lychee 安装](#25-lychee-安装)                                 |
| `npx: command not found`      | runner 未安装 Node.js             | 见 [2.4 Node.js 安装](#24-nodejs-安装)                                |
| `yamllint: command not found` | job-local Python 工具链未激活     | 运行 `bash docs/goal/tools/setup-ci-toolchain.sh` 后激活 venv         |
| `pytest: command not found`   | job-local Python 工具链未激活     | 运行 `bash docs/goal/tools/setup-ci-toolchain.sh` 后激活 venv         |
| `jq: command not found`       | runner 未安装 jq                  | `apt install jq`                                                      |
| `workflow-policy-guard` 失败  | runner 标签或部署目标违反全局规则 | 改为 `[self-hosted, Linux, X64, homepage]`；部署目标统一声明为 `sre/` |
| `timeout-minutes` 超时        | CI 脚本卡死或网络问题             | 检查 runner 网络连接，检查脚本是否有死循环                            |
| `outer-metrics-guard` 失败    | LLM agent 尝试修改 outer-metrics  | 确保 outer-metrics 变更由 CI bot 或人工 `[outer-metrics:manual]` 提交 |
| `spec-lint` 报 23 节缺失      | SPEC.md 结构不完整                | 按 `module/README.md` 模板补齐 §1-§23                                 |
| `grep-guard` 误报             | 文档中讨论安全模式时引用关键词    | 在 `.lycheeignore` 或脚本白名单中排除                                 |

### 6.2 调试命令

```bash
# 本地运行单个 CI 脚本
bash .github/ci/grep-guard.sh
bash .github/ci/workflow-policy-guard.sh
bash .github/ci/spec-lint.sh
bash .github/ci/status-consistency-check.sh

# 本地准备 job-local Python 工具链
bash docs/goal/tools/setup-ci-toolchain.sh
. .cache/ci-python/bin/activate

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
gh workflow run deps-matrix.yml
gh workflow run outer-metrics.yml
gh workflow run scripts-tests.yml
gh workflow run runner-test.yml
gh workflow run self-hosted-test.yml
gh workflow run minimal-test.yml

# 触发 Release（需要先创建 tag）
git tag v0.5.0
git push origin v0.5.0
```

## 7. 架构决策记录

| 日期       | 决策                                                       | 理由                                       |       |                               |
| ---------- | ---------------------------------------------------------- | ------------------------------------------ |       |                               |
| 2026-06-11 | 全局 workflow 策略由 `workflow-policy-guard.sh` 强制校验   | 防止 runner 与部署规则回退                 |       |                               |
| 2026-06-11 | 部署到运行环境或远端机器统一落在 `sre/` 机器池             | 避免业务机或个人机承载发布职责             |       |                               |
| 2026-06-08 | 全部 workflow 切换到 `[self-hosted, Linux, X64, homepage]` | 降低成本，利用项目 self-hosted runner 资源 |       |                               |
| 2026-06-08 | 所有 job 添加 `timeout-minutes`                            | 防止 self-hosted runner 挂起阻塞           |       |                               |
| 2026-06-08 | Python 包改为 job-local 工具链                             | 避免 runner 全局 Python 依赖漂移           |       |                               |
| 2026-06-08 | release.yml 质量门禁改为 `workflow_call` 复用 docs-ci      | 消除重复维护，DRY 原则                     |       |                               |
| 2026-06-08 | outer-metrics-guard 移除 PR-only 条件                      | workflow_call 复用时需全场景覆盖           |       |                               |
| 2026-06-08 | scripts-tests smoke 去掉 `\                                | \                                          | true` | CI 失败应真正阻断，不容忍错误 |

## 8. 维护清单

### 新增 CI 脚本时

- [ ] 脚本添加到 `.github/ci/` 或 `scripts/`
- [ ] 设置可执行权限 `chmod +x`
- [ ] 在对应 workflow 中添加 step
- [ ] 本地验证脚本可独立运行
- [ ] 更新本文档的脚本清单

### 新增 Workflow 时

- [ ] 每个 job 使用 `[self-hosted, Linux, X64, homepage]` runner
- [ ] 不添加未批准的业务、个人或模块专属 runner label
- [ ] 每个 job 添加 `timeout-minutes`
- [ ] 路径过滤避免无关变更触发
- [ ] 评估是否可通过 `workflow_call` 复用现有 workflow
- [ ] 本地运行 `bash .github/ci/workflow-policy-guard.sh`
- [ ] 更新本文档的 Workflow 概述

### 新增部署 Job 时

- [ ] 部署目标统一声明为 `sre/` 机器池
- [ ] 不通过业务机、个人机或模块专属 runner label 表达部署目标
- [ ] 本地运行 `bash .github/ci/workflow-policy-guard.sh`
- [ ] 在 PR 描述中说明部署入口、目标目录和回滚方式

### Runner 环境变更时

- [ ] 更新本文档的预装依赖清单
- [ ] 更新一键安装脚本
- [ ] 在所有受影响的 workflow 上验证
