# CI 部署文档

> FoundationX 文档枢纽 CI/CD 完整部署指南。
> 最后更新：2026-07-10

## 1. 概述

本仓库使用 GitHub Actions 作为 CI/CD 平台。当前直接声明 runner 的 job 使用 `[self-hosted, Linux, X64, <approved sre/* pool>]`；`ubuntu-latest` 与历史 `[self-hosted, Linux, X64, ci-governance]` 仅由策略门禁兼容接受，不代表当前目标配置。
Reusable workflow job 只能调用仓库内 workflow 或批准的 SRE 部署合同入口。真实部署不在本仓库内联执行，部署到运行环境或远端机器时，目标机器池统一为 **`sre/`**。

共 **11 个 workflow**、**57 个 top-level job**（其中 **54** 个直接声明 `runs-on`，**3** 个调用 reusable workflow），覆盖仓库文档、Goal 体系、依赖矩阵、Foundation 跨仓集成、Foundation 发布前置、外部评分锚点、发布元数据、SRE 部署合同预检和 runner 烟雾测试：

| Workflow                   | 文件                         | 职责                                                                 | Job 数 |
| -------------------------- | ---------------------------- | -------------------------------------------------------------------- | ------ |
| **Docs CI**                | `docs-ci.yml`                | 文档质量守卫、workflow 策略守卫、部署策略守卫、Spec 结构检查         | 14     |
| **Goal CI**                | `goal-ci.yml`                | Goal 驱动交付体系门禁（YAML、Registry、ID、Matrix、Gate）            | 12     |
| **Deps Matrix**            | `deps-matrix.yml`            | Foundation 依赖矩阵检查和 PR 汇总                                    | 4      |
| **Foundation Integration** | `foundation-integration.yml` | Foundation 依赖矩阵、跨模块边界、`go.work` 联合构建和证据聚合        | 6      |
| **Foundation Release**     | `foundation-release.yml`     | Foundation 基座模块标签发布、跨模块 release manifest 和证据聚合      | 9      |
| **Outer Metrics**          | `outer-metrics.yml`          | 评分体系外部锚点采集与 Goodhart 检测                                 | 2      |
| **Release**                | `release.yml`                | 版本发布元数据、SRE 部署合同预检、GitHub Release                     | 5      |
| **Scripts Tests**          | `scripts-tests.yml`          | rule-scorer 单元测试与 shell 脚本烟雾测试                            | 2      |
| **Runner Test**            | `runner-test.yml`            | self-hosted runner 手动探测                                          | 1      |
| **Self-Hosted Test**       | `self-hosted-test.yml`       | self-hosted runner 基线烟雾测试                                      | 1      |
| **Minimal Test**           | `minimal-test.yml`           | 最小 workflow 连通性测试                                             | 1      |

## 2. Self-Hosted Runner 与部署目标要求

### 2.1 Runner 标签

所有直接声明 runner 的 workflow job 必须使用以下 runner class 之一：

```yaml
runs-on: [self-hosted, Linux, X64, sre/governance]
# 或任一经批准的 sre/* pool，例如 sre/foundation-l1
# ubuntu-latest / ci-governance 仅保留为兼容输入，不作为当前推荐配置
```

禁止项：

- `macos-*`、`windows-*` 等未批准的 GitHub-hosted runner
- `Linux` / `X64` 大小写漂移
- 未批准的业务、个人或模块专属额外 label；当前批准的项目池标签为 `sre/*`，`ci-governance` 仅作历史兼容
- 未经批准的外部 reusable workflow 绕过仓库内 runner 策略

job 级 reusable workflow `uses:` 只能指向 `./.github/workflows/*` 或批准的 `ZoneCNH/sre/.github/workflows/deploy-contract.yml@main`。
该规则由 `.github/ci/workflow-policy-guard.sh` 强制校验，覆盖直接 `runs-on`、仓库内 reusable workflow 调用和部署目标声明。

### 2.2 部署目标

- 部署到运行环境或远端机器的 job 必须统一落在 `sre/` 机器池。
- workflow 不得通过业务机、个人机或模块专属 runner label 表达部署目标；目标选择应由 SRE 入口、环境变量或部署清单完成。
- `release.yml` 生成 `release-manifest.json` 和 `sre-deploy-contract.json`，并执行 SRE 合同预检；它不等同机器部署。
- 真实部署只能通过 `ZoneCNH/sre/.github/workflows/deploy-contract.yml@main` 消费合同和 evidence，由 SRE 控制面在 `sre/` 机器池执行。
- 本仓库 workflow 和脚本不得内联 `ssh`、`scp`、`rsync`、`kubectl`、`helm`、`systemctl` 或 `docker compose` 等真实部署命令。

### 2.3 基础依赖

CI runner **必须满足**以下基础依赖。`sre/*` self-hosted runner 需按池配置安装；`ubuntu-latest` 仅为兼容路径。Python 包依赖由 job-local 工具链安装，不要求 runner 全局预装：

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
| 14  | `deployment-policy`     | 10min | 部署控制面边界守卫                                | `.github/ci/deploy-policy-guard.sh`       |

**配置文件**：

- `.markdownlint.json` — Markdownlint 规则（行长 200、允许 HTML 元素等）
- `.lycheeignore` — 链接检查排除列表（计划中未创建的仓库、外部服务）

### 3.2 Goal CI（Goal 驱动交付体系门禁）

**文件**：`.github/workflows/goal-ci.yml`

**触发条件**：

| 触发                  | 条件                                                                                                                                                         |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `push` (main)         | 变更路径匹配 `.config/goal/**`、`docs/goal/**`、`report/goal-*`、`.claude/agents/goal-*`、`.codex/agents/goal-*`、`.copilot/agents/goal-*`、`AGENTS.md` |
| `pull_request` (main) | 同上                                                                                                                                                         |

**依赖链**：

```text
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

```text
module/*/spec/SPEC.md → outer-metrics-from-git.sh → outer-metrics-eval.sh
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

**触发条件**：`workflow_dispatch`（当前仅保留手动触发；`push` tag 触发已禁用，待自托管 runner 恢复后再恢复）

**权限**：`contents: write`

**流程**：

```text
workflow_dispatch
    ↓
quality-gate (复用 docs-ci.yml 全部 14 个检查)
    + goal-control-plane (复用 goal-ci.yml 全部 12 个检查)
    ↓
release-gate (执行 Goal 发布硬阻断)
    ↓
build-manifest (下载 Goal gate 产物 → 生成 release-manifest.json + sre-deploy-contract.json → SRE 合同预检 + upload artifact)
    ↓
publish-release (下载 artifact → 生成 changelog → 创建 GitHub Release)
```

当前 Release workflow 只创建 GitHub Release 元数据并产出 SRE 部署合同，不执行机器部署。真实部署必须由 `ZoneCNH/sre` 工作流消费该合同，并在 `sre/` 机器池执行。

**Job 列表**：

| Job                  | 超时             | 依赖                             | 职责                                               |
| -------------------- | ---------------- | -------------------------------- | -------------------------------------------------- |
| `quality-gate`       | 由 docs-ci 定义  | —                                | 调用 `docs-ci.yml`（`workflow_call`）              |
| `goal-control-plane` | 由 goal-ci 定义  | —                                | 调用 `goal-ci.yml`（`workflow_call`）              |
| `release-gate`       | 10min            | quality-gate, goal-control-plane | 执行 Goal release gate 并上传产物                  |
| `build-manifest`     | 15min            | release-gate                     | 生成 release manifest、SRE contract 并执行预检     |
| `publish-release`    | 10min            | build-manifest                   | 生成 changelog 并创建 GitHub Release               |

**发布流程**：

```bash
# 1. 确保 main 分支最新
git checkout main && git pull

# 2. 运行本地质量检查（可选）
bash .github/ci/grep-guard.sh
bash .github/ci/workflow-policy-guard.sh
bash .github/ci/deploy-policy-guard.sh
bash .github/ci/spec-lint.sh

# 生成并预检 release/SRE 合同（可选）
bash .github/ci/generate-release-manifest.sh
bash .github/ci/deploy-contract-preflight.sh

# 3. 通过 workflow_dispatch 手动触发 Release
#    - 在 GitHub Actions 页面选择 release.yml
#    - ref 选定要发布的 tag 或对应提交
#    - 运行 workflow
```

**Changelog 自动生成规则**：

- `feat:`：新功能
- `fix:`：修复
- `docs:`：文档
- 其他：其他

### 3.5 Foundation Integration（基座集成）

**文件**：`.github/workflows/foundation-integration.yml`

**触发条件**：

- `schedule`：每天 03:00 UTC 定时巡检。
- `workflow_dispatch`：手动触发。

该 workflow 当前是跨仓集成巡检入口，不在 PR 中自动接触 self-hosted runner 的跨仓 clone 行为。

**Job 列表**：

- `yaml-lint`（10min）：校验 `module/FOUNDATION-DEPS.yaml` YAML 结构。
- `deps-matrix-full`（30min）：校验 16 个 Foundation 依赖矩阵条目、模块身份、Go baseline 和模块本地基础检查。
- `boundary-cross-check`（20min）：扫描真实 Go import 图，校验 allowed/forbidden/test-only 边界。
- `joint-build-test`（30min）：克隆 6 个基础模块，生成 `go.work`，执行 build/test。
- `evidence-collect`（15min）：聚合 Foundation CI evidence，生成 JSON、sha256，并上传 `foundation-integration-evidence` artifact。
- `summary`（5min）：生成 Step Summary 汇总。

联合构建脚本对“没有成功加入任何模块”“`go build` 失败”“`go test` 失败”均硬失败。依赖矩阵脚本默认把 Go baseline mismatch 作为阻断；只有显式设置 `FOUNDATION_GO_BASELINE_MODE=warn` 时才降级为兼容告警。

### 3.6 Foundation Release（基座发布前置）

**文件**：`.github/workflows/foundation-release.yml`

**触发条件**：`workflow_dispatch`

**主要输入**：

- `release_version`：Foundation 版本号，例如 `v0.5.0`。
- `modules`：发布模块列表，`all` 表示 6 个第一阶段基础模块。
- `dry_run`：是否只生成计划和证据，不推送 tag。

**Job 列表**：

- `quality-gate`（由 docs-ci 定义）：复用 Docs CI 门禁。
- `resolve-modules`（10min）：解析 `all` 或显式模块列表。
- `validate-foundation`（20min）：运行 Foundation 集成检查。
- `prepare-release`（15min）：生成 release 计划、manifest 和 evidence。
- `module-release-*`（15min）：按模块推送 tag 或 dry-run。
- `aggregate-release`（10min）：汇总 Foundation release evidence。

真实 tag 推送需要 `FOUNDATION_RELEASE_TOKEN`。该 workflow 仍是发布前置和聚合面，不执行机器部署。

### 3.7 Scripts Tests（脚本健壮性）

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

- `spec-lint.sh`（539）：23 节结构、FR 连续性、模糊词、metadata、xlib_standard 专用门禁和 Analysis Lint；调用方：docs-ci, release。
- `status-consistency-check.sh`（~250）：状态表与文档交叉一致性；调用方：docs-ci, release。
- `task-spec-validate.sh`（~280）：Task Spec 结构和引用一致性；调用方：docs-ci。
- `traceability-check.sh`（~190）：追踪矩阵 FR↔证据映射；调用方：docs-ci, release。
- `grep-guard.sh`（132）：4 类敏感内容扫描；调用方：docs-ci, release。
- `workflow-policy-guard.sh`（131）：全局 runner 与 `sre/` 部署目标策略守卫；调用方：docs-ci。
- `deploy-policy-guard.sh`（53）：禁止本仓内联远程部署命令，固定 SRE 控制面边界；调用方：docs-ci。
- `deploy-contract-preflight.sh`（119）：校验 SRE 部署合同字段、证据路径和执行面声明；调用方：release。
- `foundation-deps-full-check.sh`（约 190）：校验 Foundation 模块依赖矩阵、模块路径身份、Go baseline 默认阻断、模块本地边界和 secret scan；调用方：foundation-integration。
- `foundation-boundary-check.sh`（约 360）：扫描真实 Go import 图，执行 module path、allowed/forbidden deps、forbidden edges、stdlib-only 和 `testkitx` 生产导入门禁；调用方：foundation-integration。
- `foundation-joint-build.sh`（55）：克隆基础模块、生成 `go.work`、执行联合 build/test；调用方：foundation-integration。
- `foundation-evidence-collect.sh`（259）：聚合 Foundation 集成证据，输出模块身份、commit、Go 版本、runner/provenance 和 artifact digest；调用方：foundation-integration。
- `glossary-consistency.sh`（~100）：术语表一致性；调用方：docs-ci。
- `anti-requirement-scan.sh`（~110）：反需求扫描；调用方：docs-ci。
- `spec-drift-guard.sh`（~70）：SPEC.md 篡改检测；调用方：docs-ci, release。
- `spec-status-report.sh`（~90）：状态报告生成；调用方：docs-ci, release。
- `generate-release-manifest.sh`（110）：Release manifest、SRE deploy contract 和 sha256 摘要生成；调用方：release。

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

- `lychee: command not found`：runner 未安装 lychee；见 [2.5 lychee 安装](#25-lychee-安装)。
- `npx: command not found`：runner 未安装 Node.js；见 [2.4 Node.js 安装](#24-nodejs-安装)。
- `yamllint: command not found`：job-local Python 工具链未激活；运行 `bash docs/goal/tools/setup-ci-toolchain.sh` 后激活 venv。
- `pytest: command not found`：job-local Python 工具链未激活；运行 `bash docs/goal/tools/setup-ci-toolchain.sh` 后激活 venv。
- `jq: command not found`：runner 未安装 jq；安装 `jq`。
- `workflow-policy-guard` 失败：runner 标签或部署目标违反全局规则；改为 `[self-hosted, Linux, X64, sre/<approved-pool>]`，部署目标统一声明为 `sre/`。
- `deployment-policy` 失败：本仓出现内联远程部署或 `sre/` 边界漂移；删除本仓部署命令，保留 `.gitignore` 中 `sre/`，改走 SRE 合同入口。
- `deploy-contract-preflight` 失败：SRE 合同字段、证据路径或执行面声明不合规；重新生成 manifest/evidence，确保 `target_pool` 以 `sre/` 开头。
- `foundation-deps-full-check` 失败：常见原因是模块 `go.mod` module path 与矩阵不一致、Go baseline 偏离 `go_baseline`、模块本地 boundary/secret scan 失败。兼容期只能显式设置 `FOUNDATION_GO_BASELINE_MODE=warn` 降级，默认必须阻断。
- `foundation-boundary-check` 失败：常见原因是 module path 身份不一致、命中 forbidden import、生产代码导入 `testkitx`，或在 `FOUNDATION_BOUNDARY_REQUIRE_SOURCES=true` 时缺少源码。
- `foundation-joint-build` 失败：模块 clone、`go.work`、构建或测试失败；检查 6 个基础模块仓库、Go baseline 和跨模块依赖。
- `timeout-minutes` 超时：CI 脚本卡死或网络问题；检查 runner 网络连接，检查脚本是否有死循环。
- `outer-metrics-guard` 失败：LLM agent 尝试修改 outer-metrics；确保变更由 CI bot 或人工 `[outer-metrics:manual]` 提交。
- `spec-lint` 报 23 节缺失：SPEC.md 结构不完整；按 `module/README.md` 模板补齐 §1-§23。
- `grep-guard` 误报：文档中讨论安全模式时引用关键词；在 `.lycheeignore` 或脚本白名单中排除。

### 6.2 调试命令

```bash
# 本地运行单个 CI 脚本
bash .github/ci/grep-guard.sh
bash .github/ci/workflow-policy-guard.sh
bash .github/ci/deploy-policy-guard.sh
bash .github/ci/spec-lint.sh
bash .github/ci/status-consistency-check.sh
bash .github/ci/generate-release-manifest.sh
bash .github/ci/deploy-contract-preflight.sh

# 本地运行 Foundation 集成脚本（需要网络和模块仓库可访问）
bash .github/ci/foundation-deps-full-check.sh
bash .github/ci/foundation-boundary-check.sh
bash .github/ci/foundation-joint-build.sh

# 定向调试单个模块
FOUNDATION_DEPS_MODULES=kernel bash .github/ci/foundation-deps-full-check.sh
FOUNDATION_BOUNDARY_MODULES=kernel bash .github/ci/foundation-boundary-check.sh
FOUNDATION_GO_BASELINE_MODE=warn FOUNDATION_DEPS_MODULES=kernel bash .github/ci/foundation-deps-full-check.sh

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
gh workflow run foundation-integration.yml
gh workflow run foundation-release.yml -f release_version=v0.5.0 -f modules=all -f dry_run=true
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

| 日期       | 决策                                                       | 理由                                       |
| ---------- | ---------------------------------------------------------- | ------------------------------------------ |
| 2026-06-13 | Release 产出 `sre-deploy-contract.json` 并执行预检         | 分离 CI 控制面与 SRE 执行面                |
| 2026-06-13 | Foundation joint-build 对无模块、构建失败、测试失败硬失败  | 避免集成 CI 假阳性                         |
| 2026-06-13 | Foundation Go baseline mismatch 默认阻断                   | 防止工具链漂移进入基座组合                 |
| 2026-06-13 | Foundation boundary 以真实 Go import 图和 module path 判定 | 防止 YAML-only 检查漏掉依赖与身份漂移      |
| 2026-06-11 | 全局 workflow 策略由 `workflow-policy-guard.sh` 强制校验   | 防止 runner 与部署规则回退                 |
| 2026-06-11 | 部署到运行环境或远端机器统一落在 `sre/` 机器池             | 避免业务机或个人机承载发布职责             |
| 2026-06-18 | **历史**：self-hosted runner 下线，goal-ci.yml 迁移到 `ubuntu-latest` | runner 已退役，统一使用 hosted runner       |
| 2026-06-08 | **历史**：全部 workflow 切换到 `[self-hosted, Linux, X64, ci-governance]` | 降低成本，利用项目 self-hosted runner 资源 |
| 2026-06-08 | 所有 job 添加 `timeout-minutes`                            | 防止 self-hosted runner 挂起阻塞           |
| 2026-06-08 | Python 包改为 job-local 工具链                             | 避免 runner 全局 Python 依赖漂移           |
| 2026-06-08 | release.yml 质量门禁改为 `workflow_call` 复用 docs-ci      | 消除重复维护，DRY 原则                     |
| 2026-06-08 | outer-metrics-guard 移除 PR-only 条件                      | workflow_call 复用时需全场景覆盖           |
| 2026-06-08 | scripts-tests smoke 去掉 `\|\| true`                       | CI 失败应真正阻断，不容忍错误              |

## 8. 维护清单

### 新增 CI 脚本时

- [ ] 脚本添加到 `.github/ci/` 或 `scripts/`
- [ ] 设置可执行权限 `chmod +x`
- [ ] 在对应 workflow 中添加 step
- [ ] 本地验证脚本可独立运行
- [ ] 更新本文档的脚本清单

### 新增 Workflow 时

- [ ] 每个 job 使用 `[self-hosted, Linux, X64, <approved sre/* pool>]` runner；兼容例外须有明确迁移理由
- [ ] 不添加未批准的业务、个人或模块专属 runner label
- [ ] 每个 job 添加 `timeout-minutes`
- [ ] 路径过滤避免无关变更触发
- [ ] 评估是否可通过 `workflow_call` 复用现有 workflow
- [ ] 本地运行 `bash .github/ci/workflow-policy-guard.sh`
- [ ] 本地运行 `bash .github/ci/deploy-policy-guard.sh`
- [ ] 更新本文档的 Workflow 概述

### 新增部署 Job 时

- [ ] 只能调用 `ZoneCNH/sre/.github/workflows/deploy-contract.yml@main`
- [ ] 部署目标统一声明为 `sre/` 机器池
- [ ] 不通过业务机、个人机或模块专属 runner label 表达部署目标
- [ ] 禁止 `pull_request` 触发，配置 GitHub Environment 与 `concurrency`
- [ ] 生成并预检 `release/manifest/sre-deploy-contract.json`
- [ ] 本地运行 `bash .github/ci/workflow-policy-guard.sh`
- [ ] 本地运行 `bash .github/ci/deploy-policy-guard.sh`
- [ ] 本地运行 `bash .github/ci/deploy-contract-preflight.sh`
- [ ] 在 PR 描述中说明部署入口、目标目录和回滚方式

### Runner 环境变更时

- [ ] 更新本文档的预装依赖清单
- [ ] 更新一键安装脚本
- [ ] 在所有受影响的 workflow 上验证
