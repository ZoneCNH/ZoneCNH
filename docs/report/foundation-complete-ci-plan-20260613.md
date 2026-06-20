# Foundation 完整 CI 方案

- 日期：2026-06-13
- 状态：已落地控制面、SRE 合同预检、Go baseline 阻断、真实 import 边界扫描、模块身份门禁和集成 evidence artifact；模块仓 CI 与发布级证据仍按 P2-P5 推进
- 范围：CI 体系设计、机器池执行策略、跨仓集成、发布前置校验、SRE 机器部署边界和证据链。
- 非范围：不在本仓库内联真实机器部署，不在本仓库管理 SRE 机器凭据，不修改 SRE 控制面实现。

## 1. 目标

建立一套可落地、可审计、可扩展的 Foundation CI 体系，使 6 个第一阶段基础模块和依赖矩阵中的 16 个条目都能被机器化校验。

核心目标：

1. PR 阶段阻止格式、测试、依赖边界、Go baseline 和凭据泄露问题进入主干。
2. 跨仓集成阶段验证 6 个基础模块能在同一个 `go.work` 中构建和测试。
3. 发布前置阶段生成可追溯证据，支持后续 release 和 SRE 部署合同。
4. 所有直接 job 继续遵守现有 runner 约束：`[self-hosted, Linux, X64, homepage]`。
5. CI 与 CD 解耦：CI 证明代码和元数据可发布；真实部署只在 SRE 机器上执行，并只通过 `ZoneCNH/sre` 合同承接。

## 2. 当前证据

### 2.1 Foundation 模块基数

`module/foundation-modules.md` 固化第一阶段基础模块为 6 个：

| 层级         | 模块         | CI 重点                                         |
| ------------ | ------------ | ----------------------------------------------- |
| L0           | `kernel`     | stdlib-only、无隐藏 goroutine、无业务语义       |
| L1           | `configx`    | 配置解析、脱敏、边界导入                        |
| L1           | `observex`   | logs、metrics、traces、health 契约              |
| L1           | `resiliencx` | timeout、retry、breaker、bulkhead、degrade 契约 |
| L1           | `schedulex`  | timer、cron、job、clock、lifecycle 契约         |
| L1 test-only | `testkitx`   | 只能作为测试依赖，不得进入生产路径              |

`module/FOUNDATION-DEPS.yaml` 中还有标准、门禁、存储扩展和契约条目，因此 CI 的完整校验对象不是只看 6 个模块，而是：

- 6 个第一阶段基础模块。
- 2 个标准/门禁条目：`xlib_standard`、`xlibgate`。
- 7 个存储扩展条目：`redisx`、`kafkax`、`natsx`、`postgresx`、`taosx`、`ossx`、`clickhousex`。
- 1 个契约条目：`contracts`。

合计 16 个依赖矩阵条目。

### 2.2 已有 CI 基线

本仓库已有以下 CI 能力：

| 能力                | 现状                                                    | 证据                                           |
| ------------------- | ------------------------------------------------------- | ---------------------------------------------- |
| runner 策略守卫     | 直接 job 必须使用 `[self-hosted, Linux, X64, homepage]` | `.github/ci/workflow-policy-guard.sh`          |
| 部署策略守卫        | 本仓库不得内联远程部署，部署合同只能走 SRE              | `.github/ci/deploy-policy-guard.sh`            |
| 文档/治理 CI        | docs、goal、脚本测试、依赖矩阵检查                      | `.github/workflows/*.yml`                      |
| Foundation 集成 CI  | YAML lint、依赖矩阵、边界、联合构建测试、证据收集       | `.github/workflows/foundation-integration.yml` |
| Foundation 发布前置 | 质量门禁、模块选择、tag、manifest、evidence             | `.github/workflows/foundation-release.yml`     |
| Release/SRE 合同    | 生成 release manifest、SRE deploy contract 并预检       | `.github/workflows/release.yml`                |

### 2.3 已收敛项与剩余缺口

本轮已收敛：

1. `docs/ci-deployment.md` 已纳入 `foundation-integration.yml`、`foundation-release.yml` 和 release/SRE 合同预检说明。
2. `.github/ci/foundation-joint-build.sh` 已按失败即非零退出的语义处理联合 build/test。
3. `release.yml` 已生成 `release-manifest.json`、`sre-deploy-contract.json`，并通过 `deploy-contract-preflight.sh` 校验 SRE 执行面字段。
4. `docs/governance/DEPLOYMENT.md` 已明确本仓 release 只做 manifest、contract 和 preflight，不执行真实机器部署。
5. `.github/ci/foundation-deps-full-check.sh` 已读取 YAML `go_baseline`，默认阻断 Go baseline mismatch，并校验模块路径身份。
6. `.github/ci/foundation-boundary-check.sh` 已扫描真实 Go import 图，按 YAML 执行 allowed/forbidden/test-only 边界和 module path 身份门禁。
7. `.github/ci/foundation-evidence-collect.sh` 已输出 schema 化 JSON、sha256、模块 commit、Go 版本、runner/provenance 和 artifact digest；`foundation-integration.yml` 已上传 `foundation-integration-evidence` artifact。
8. 本地验证已覆盖 `kernel` 正向通过；全量 boundary 扫描只暴露 `contracts` 模块身份漂移。

剩余缺口：

1. 发布级 SBOM、模块 build/test 摘要和 release evidence 仍需与模块仓 CI 产物打通。
2. 6 个基础模块仓库还需要铺同构 `module-ci.yml` 和 evidence 输出。
3. self-hosted runner 执行 PR 需要明确安全策略，避免未受信任 fork PR 接触内部机器和 secrets。
4. 当前真实模块状态存在 drift：`/home/contracts` 的 `go.mod` 声明为 `github.com/ZoneCNH/xlib_standard`，与矩阵期望 `github.com/ZoneCNH/contracts` 不一致；`kafkax`、`natsx`、`ossx`、`postgresx` 的本地 Go baseline 也已被 evidence 标记为不匹配。
5. 多个模块仓边界脚本仍需修正。当前已见问题包括 `observex` secret fixture 命中 `password=` 扫描、`resiliencx` boundary 目标引用缺失目录、`schedulex` 需要 `GOWORK=off`、`kafkax` 存在 internal 到 public 包导入。
   `testkitx` 仍命中 `pkg/testkitx/boundarytest/boundarytest.go:69` 的 `Position` 业务语义项。

## 3. CI 总体架构

推荐采用四层 CI 架构：

```text
L0 模块仓 CI
  每个 Foundation 模块仓库独立执行 fmt、vet、test、race、依赖边界和 secret scan

L1 本仓治理 CI
  校验文档、Goal、workflow 策略、部署策略、依赖矩阵和治理脚本

L2 Foundation 集成 CI
  克隆 6 个基础模块，生成 go.work，执行联合 build/test 和跨仓边界扫描

L3 发布前置 CI
  在质量门禁后生成 release manifest、evidence、tag 计划和可审计材料
```

这一架构把“模块自身正确性”和“基座组合正确性”分开验证：

- 单模块 CI 负责局部质量，失败反馈快。
- 集成 CI 负责组合质量，覆盖单仓无法发现的版本和接口不兼容。
- 发布前置 CI 只在门禁通过后运行，避免把 release 逻辑混入普通 PR。
- SRE 部署合同不属于 CI 主体，只消费 CI 产出的 release/evidence。

## 4. 双平面与机器池策略

CI 方案中保留双平面，但这里的双平面不是复杂化，而是职责隔离：

| 平面       | 所在位置           | 机器/runner 表达                      | 责任                                      |
| ---------- | ------------------ | ------------------------------------- | ----------------------------------------- |
| CI 控制面  | 本仓库与各模块仓库 | `[self-hosted, Linux, X64, homepage]` | 运行测试、依赖边界、证据生成、发布前置    |
| SRE 执行面 | `ZoneCNH/sre`      | `sre/` 目标池，由 SRE 内部解析        | 真实部署、凭据装载、smoke、rollback、审计 |

关键约束：

1. 业务仓库不新增 `sre`、`deploy`、模块名或个人机器 label。
2. 当前 workflow policy 要求直接 job 使用完全一致的 label 集合，因此短期机器池应保持同构：所有可承接本仓 CI 的 runner 都暴露 `self-hosted`、`Linux`、`X64`、`homepage`。
3. 如果未来需要区分轻量文档机、Go 构建机和发布签名机，应先扩展 `workflow-policy-guard.sh` 的允许规则，再调整 workflow，不能绕开现有守卫。
4. 真实部署机器、凭据和远程命令不进入本仓库。CI 只生成可供 SRE 合同消费的 evidence。

### 4.1 部署执行定位

部署执行位置必须固定在 SRE 机器池：

1. 本仓库 CI runner 只执行测试、边界扫描、manifest/evidence 生成和发布前置校验，不执行 `ssh`、`scp`、`rsync`、`kubectl`、`helm`、`systemctl`、`docker compose` 等真实部署命令。
2. 本仓库如需发起部署，只能以 job-level reusable workflow 调用 `ZoneCNH/sre/.github/workflows/deploy-contract.yml@main`，不得在本仓 workflow 或脚本中内联远程命令。
3. `ZoneCNH/sre` 接收 `release_ref`、`environment`、`target` 或 `target_pool=sre/...`、manifest、evidence 和可选 `dry_run`，由 SRE 控制面解析目标机器池。
4. SRE workflow 在 SRE 受控 runner/机器上装载凭据、选择目标主机、执行部署、运行 smoke、执行 rollback 并写审计。
5. SRE 返回 `deployment_id`、实际目标池摘要、smoke 结果、rollback 引用和审计日志地址；本仓只消费这些结果，不保存敏感主机、凭据或远程命令细节。
6. SRE 部署失败时，业务 release 状态应标记为 failed 或 blocked；rollback 与 smoke 证据保留在 SRE artifact 中，CI 不自行补救生产状态。

机器池最低规格建议：

| 池内角色                 | 数量建议 | 规格建议                      | 用途                                        |
| ------------------------ | -------- | ----------------------------- | ------------------------------------------- |
| baseline runner          | 2        | 2 vCPU / 4 GB RAM / 20 GB SSD | docs、goal、轻量脚本、策略守卫              |
| go integration runner    | 2        | 4 vCPU / 8 GB RAM / 40 GB SSD | 跨仓 clone、`go.work` build/test、race 子集 |
| release preflight runner | 1        | 2 vCPU / 4 GB RAM / 20 GB SSD | manifest、evidence、tag dry-run、签名前置   |

在现有 label 约束未放开前，这些机器可以通过容量和调度策略区分，但 workflow 层仍只声明同一组 runner labels。

## 5. Workflow 设计

### 5.1 模块仓 CI

每个基础模块仓库都应有同构 CI。建议文件名：

```text
.github/workflows/module-ci.yml
```

触发：

- `pull_request`：仅执行无 secrets 的只读检查。
- `push` 到主分支：执行完整检查。
- `workflow_dispatch`：允许人工重跑。
- tag/release：只执行发布前置，不直接部署。

推荐 job：

| job         | 必需 | 说明                                         |
| ----------- | ---- | -------------------------------------------- |
| `policy`    | 是   | 检查 runner、permissions、workflow 基本策略  |
| `toolchain` | 是   | 校验 Go baseline、`go env`、module path      |
| `format`    | 是   | `gofmt`、`go mod tidy` diff 检查             |
| `static`    | 是   | `go vet`、可选 `staticcheck`、`govulncheck`  |
| `unit`      | 是   | `go test ./...`                              |
| `race`      | 推荐 | 对非纯契约包执行 `go test -race ./...`       |
| `boundary`  | 是   | 检查禁止导入业务域、入口、部署和其他非法模块 |
| `secrets`   | 是   | 检查 API key、私有 endpoint、账户 ID、token  |
| `evidence`  | 是   | 上传 JSON evidence 和测试摘要                |

参考骨架：

```yaml
name: module-ci

on:
  pull_request:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read

jobs:
  module-ci:
    runs-on: [self-hosted, Linux, X64, homepage]
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: "1.23"
          cache: true
      - run: gofmt -w .
      - run: git diff --exit-code
      - run: go mod tidy
      - run: git diff --exit-code go.mod go.sum
      - run: go vet ./...
      - run: go test ./...
      - run: go test -race ./...
```

实际落地时，`gofmt -w .` 可以改成只读脚本，避免 CI 直接修改工作区后让 diff 语义混乱。

### 5.2 本仓治理 CI

本仓库继续负责架构、文档、Goal、依赖矩阵和 workflow 策略。

必跑检查：

1. `markdownlint` 覆盖 `README.md`、`ARCHITECTURE.md`、`docs/**`、`module/**`。
2. 链接检查覆盖公开 GitHub 仓库链接和本地相对链接。
3. `workflow-policy-guard.sh` 阻止 runner label 漂移。
4. `deploy-policy-guard.sh` 阻止把部署命令写入业务仓库。
5. `FOUNDATION-DEPS.yaml` schema 校验。
6. `module/foundation-modules.md` 与 `FOUNDATION-DEPS.yaml` 的模块清单一致性校验。
7. `docs/ci-deployment.md` 的 workflow 清单与 `.github/workflows/*.yml` 实际文件一致。

### 5.3 Foundation 集成 CI

现有 `foundation-integration.yml` 是正确入口，已承接完整集成门禁的核心阻断。

必跑检查：

- `YAML lint`：`FOUNDATION-DEPS.yaml` 结构可读。
- `deps full check`：16 个条目可解释，校验 module path，Go baseline 默认阻断。
- `real import boundary`：基于真实仓库 import 图拒绝禁止依赖。
- `joint build`：6 个基础模块在同一 `go.work` 中 `go build ./...`。
- `joint test`：6 个基础模块在同一 `go.work` 中 `go test ./...`。
- `adapter rule`：`resiliencx`、`schedulex` 对 `observex` 的集成只允许 adapter。
- `test-only rule`：`testkitx` 不得被生产模块导入。
- `evidence collect`：输出模块 commit、Go 版本、结果摘要、artifact digest。

已修正：

- `foundation-joint-build.sh` 中 `go build ./...` 失败必须退出非零。
- `foundation-boundary-check.sh` 已从 YAML 结构检查升级为真实 Go import 图检查。
- Go baseline mismatch 默认阻断；兼容期只能显式设置 `FOUNDATION_GO_BASELINE_MODE=warn` 降级。

仍需继续推进：

- evidence 输出补 artifact digest、SBOM、provenance、runner 信息和测试摘要。
- 6 个基础模块仓库补同构 module CI。
- 修正 `contracts` module path drift 和 `testkitx` boundary 词表命中。

### 5.4 发布前置 CI

`foundation-release.yml` 应保持“发布前置”定位，不做机器部署。

发布前置必须产出：

1. `release/foundation/release-${version}.json`
2. `release/foundation/evidence-${version}.json`
3. 每个模块的 commit SHA、tag、Go version、test result。
4. 模块源码包或构建产物的 digest。
5. SBOM 或依赖清单。
6. provenance 元数据：workflow run id、runner label、触发者、触发 ref。
7. 所有 gate 的 pass/fail 摘要。

发布前置失败条件：

- 任一基础模块无法 clone。
- 任一模块 Go baseline 不一致。
- 任一模块测试失败。
- 任一 forbidden import 命中。
- `FOUNDATION-DEPS.yaml` 与模块清单不一致。
- evidence 缺少必填字段。
- release version 不符合约定。

## 6. 质量门禁

CI 应以门禁方式表达，而不是只堆 job。

| Gate | 名称             | 阻断条件                                                      | 责任 workflow         |
| ---- | ---------------- | ------------------------------------------------------------- | --------------------- |
| G0   | workflow policy  | runner、permissions、reusable workflow 策略不合规             | docs/governance CI    |
| G1   | source hygiene   | 格式、tidy、lint、链接、secret scan 失败                      | 模块 CI + 本仓 CI     |
| G2   | toolchain        | Go baseline、module path、依赖工具版本不合规                  | 模块 CI + 集成 CI     |
| G3   | unit quality     | `go test ./...`、race 子集或核心用例失败                      | 模块 CI               |
| G4   | boundary         | forbidden deps、业务语义、entry import、testkitx 生产导入命中 | 模块 CI + 集成 CI     |
| G5   | integration      | `go.work` build/test、adapter 规则或接口兼容失败              | Foundation 集成 CI    |
| G6   | release evidence | manifest/evidence/SBOM/provenance 不完整                      | Foundation release CI |
| G7   | ci observability | 关键 job 长期超时、runner 不健康、artifact 丢失               | SRE + 本仓观测        |

G0 到 G5 应作为 PR 或 merge 前强制门禁。G6 只在 release 前强制。G7 不直接阻断单个 PR，但必须触发运维告警和容量治理。

## 7. 依赖边界策略

依赖边界以 `module/FOUNDATION-DEPS.yaml` 为权威输入。

### 7.1 允许依赖

当前应固定：

- `kernel` 不依赖任何 Foundation 模块。
- `configx`、`observex`、`resiliencx`、`schedulex` 只依赖 `kernel`。
- `testkitx` 可依赖 6 个基础模块，但只能在测试路径使用。
- 存储扩展只依赖 `kernel`。
- `contracts` 不依赖 Foundation 实现模块。

### 7.2 禁止依赖

CI 必须拒绝以下导入方向：

1. Foundation 导入数据域、分析域、决策域、执行域或入口模块。
2. Foundation 导入 `github.com/ZoneCNH/x.go`。
3. L0 `kernel` 导入 L1 模块。
4. L1 运行时模块相互硬依赖，除明确 adapter 以外。
5. 生产包导入 `testkitx`。
6. 存储扩展反向导入业务模块。

### 7.3 实现方式

建议分两层实现：

1. 快速检查：`rg` 扫描 `import` 块和字符串常量，快速发现明显违规。
2. 准确检查：`go list -deps -json ./...` 解析真实依赖图，按 YAML 规则判定。

如果二者结论冲突，以 `go list` 结果为准，并保留 `rg` 命中作为诊断线索。

## 8. Evidence Schema

建议将 evidence 统一为 JSON，schema 名称：

```text
foundation-ci-evidence/v1
```

必填字段：

```json
{
  "schema": "foundation-ci-evidence/v1",
  "generated_at": "2026-06-13T00:00:00Z",
  "workflow": {
    "name": "foundation-integration",
    "run_id": "123456789",
    "run_attempt": 1,
    "trigger": "workflow_dispatch",
    "ref": "refs/heads/main"
  },
  "runner": {
    "labels": ["self-hosted", "Linux", "X64", "homepage"],
    "os": "Linux",
    "arch": "X64"
  },
  "modules": [
    {
      "name": "kernel",
      "repo": "https://github.com/ZoneCNH/kernel",
      "commit": "sha",
      "go_version": "1.23",
      "build": "passed",
      "test": "passed",
      "boundary": "passed",
      "digest": "sha256:..."
    }
  ],
  "gates": [
    {
      "id": "G5",
      "name": "integration",
      "status": "passed"
    }
  ]
}
```

保留原则：

- PR evidence 保留 14 天。
- main branch evidence 保留 90 天。
- release evidence 与 manifest 长期保留。
- evidence 不包含 secrets、私有 endpoint、账户 ID 或机器内网地址。

## 9. 安全策略

self-hosted runner 的 CI 安全边界必须明确：

1. PR 默认使用 `permissions: contents: read`。
2. 未受信任 fork PR 不得自动获得 secrets。
3. 禁止在 `pull_request` job 中执行部署、tag push、release publish 或远程命令。
4. 需要写权限的 release job 只能通过 `workflow_dispatch`、tag 或受保护分支触发。
5. `FOUNDATION_RELEASE_TOKEN` 只允许用于发布前置 job，不进入普通 PR job。
6. runner 工作目录每次 job 后清理，避免跨 job 泄漏。
7. CI 日志必须脱敏，尤其是 endpoint、token、账户标识和私有路径。

## 10. 分支保护与必需检查

建议主分支要求以下检查通过：

| 检查                               | 适用范围                                           |
| ---------------------------------- | -------------------------------------------------- |
| `docs-ci`                          | 本仓库所有 PR                                      |
| `goal-ci`                          | Goal/治理相关文件变更                              |
| `scripts-tests`                    | `.github/ci/**`、`scripts/**` 变更                 |
| `deps-matrix`                      | `module/FOUNDATION-DEPS.yaml`、Foundation 文档变更 |
| `workflow-policy-guard`            | 所有 workflow 变更                                 |
| `deploy-policy-guard`              | 所有 workflow 和部署文档变更                       |
| `foundation-integration / summary` | Foundation 模块、依赖矩阵、发布前置变更            |
| `module-ci`                        | 各基础模块仓库 PR                                  |

跨仓约束：

- 模块仓合入前必须先通过本模块 `module-ci`。
- 更新 Foundation 依赖矩阵时，必须触发本仓 `foundation-integration`。
- release 前必须重新跑 `foundation-release`，不能复用旧 PR 的普通 CI 结果。

## 11. 观测与 SLO

CI 自身也需要观测。

建议指标：

| 指标                             | 目标         |
| -------------------------------- | ------------ |
| docs/governance CI P95           | 小于 5 分钟  |
| module-ci P95                    | 小于 12 分钟 |
| foundation-integration P95       | 小于 30 分钟 |
| foundation-release preflight P95 | 小于 20 分钟 |
| runner queue time P95            | 小于 3 分钟  |
| flaky retry rate                 | 小于 2%      |
| artifact upload failure rate     | 小于 1%      |

告警条件：

- 任一 required check 连续 3 次因 runner/环境失败而非代码失败。
- runner queue time 连续 30 分钟高于阈值。
- evidence 或 manifest artifact 上传失败。
- `workflow-policy-guard` 或 `deploy-policy-guard` 被绕过。

## 12. 落地步骤

### P0：冻结当前策略

1. 保留所有直接 job 的固定 runner labels。
2. 保留 `deploy-policy-guard.sh` 对 SRE 合同和 inline 远程命令的限制。
3. 明确 `foundation-release.yml` 当前是发布前置，不是机器部署。

验收：

- `workflow-policy-guard.sh` 通过。
- `deploy-policy-guard.sh` 通过。
- 本仓没有跟踪 `sre/` 目录。

### P1：修正文档和脚本缺口

1. [x] 更新 `docs/ci-deployment.md` workflow 清单，纳入 `foundation-integration.yml` 和 `foundation-release.yml`。
2. [x] 修复 `foundation-joint-build.sh`，使 `go build ./...` 失败立即退出。
3. [x] 补齐 release manifest、SRE deploy contract 与本地 preflight。
4. [x] 将 Go baseline mismatch 从 warn 逐步切换为 fail。
5. [x] 为 `foundation-boundary-check.sh` 增加真实 import 图检查。

验收：

- 人为制造 build 失败时，joint build job 非零退出。
- 人为导入 forbidden module 时，boundary check 非零退出。
- `testkitx` 被生产包导入时，CI 非零退出。

### P2：铺设模块仓 CI

1. 在 6 个基础模块仓库添加同构 `module-ci.yml`。
2. 每个模块复用同一套脚本命名和 evidence 格式。
3. 对 `kernel` 增加 stdlib-only 专项检查。
4. 对 `testkitx` 增加 test-only 专项检查。

验收：

- 6 个模块仓 PR 都能独立跑完 `module-ci`。
- 任一模块导入业务域时 CI 失败。
- 任一模块 Go baseline 偏离时 CI 失败。

### P3：升级集成 CI

1. [x] `foundation-integration.yml` 执行真实 import 图检查，覆盖 16 个矩阵条目与 6 个基础模块。
2. [x] `go.work` 联合 build/test 失败必须阻断。
3. [x] 集成 evidence 输出纳入模块 commit、Go version、runner/provenance 和 artifact digest。
4. [ ] release evidence 继续接入模块 build/test/boundary 结果与 SBOM。

验收：

- 6 个模块任一模块版本不兼容时，集成 CI 失败。
- evidence JSON 能追溯到具体 run id 和每个模块 commit。

### P4：升级发布前置

1. `foundation-release.yml` 在 tag 前确认所有 gate pass。
2. manifest 增加 digest、SBOM/provenance 引用。
3. release evidence 与 manifest 作为 artifact 上传。
4. release job 权限最小化，token 只在需要写 tag/release 的 job 中暴露。

验收：

- 缺少 evidence 字段时 release preflight 失败。
- release manifest 能被 SRE deploy-contract 消费。
- release workflow 不包含机器部署命令。

### P5：接入观测

1. 采集 job duration、queue time、failure reason 和 artifact 状态。
2. 将 runner health 与 CI SLO 输出到 SRE 可见位置。
3. 对 flaky test 和 runner 环境失败做分类。

验收：

- 能区分代码失败、测试失败、runner 失败、artifact 失败。
- 连续 runner 环境失败会触发 SRE 处理。

## 13. Agent Team 执行拆分

如果用 agent team 落地，建议拆 5 条并行 lane：

- `L1 docs/explore`：更新 `docs/ci-deployment.md` 与 workflow 清单一致性。
- `L2 executor`：已修复 joint build 与 Go baseline fail 策略。
- `L3 executor`：已实现真实 import boundary checker。
- `L4 executor`：已定义集成 evidence schema 并升级 collect 脚本；release evidence 与 SBOM 接入留在 P4。
- `L5 verifier`：设计 fixture 和回归命令，验证 guards 不被绕过。

主控 agent 负责合并、统一错误语义、跑最终验证，并确认没有引入部署行为。

## 14. 完成标准

完整 CI 方案完成后，应满足：

1. 6 个 Foundation 基础模块都有独立 `module-ci`。
2. 本仓治理 CI 覆盖文档、Goal、workflow、部署策略和依赖矩阵。
3. Foundation 集成 CI 能真实 clone、build、test 并扫描 import 图。
4. 发布前置 CI 能生成完整 manifest 和 evidence。
5. 所有直接 job 使用 `[self-hosted, Linux, X64, homepage]`。
6. 本仓不出现 inline 远程部署命令。
7. 真实部署执行位置固定为 SRE 机器池，本仓只触发 `ZoneCNH/sre` 部署合同并消费返回证据。
8. SRE 部署合同只消费 release/evidence，不反向污染 CI。
9. 所有 required check 可纳入分支保护。

## 15. 验证命令

本仓当前可立即执行的验证：

```bash
git diff --check
bash .github/ci/workflow-policy-guard.sh
bash .github/ci/deploy-policy-guard.sh
npx --yes markdownlint-cli2 docs/ci-deployment.md docs/governance/DEPLOYMENT.md docs/report/foundation-complete-ci-plan-20260613.md
bash .github/ci/generate-release-manifest.sh
bash .github/ci/deploy-contract-preflight.sh
bash -n .github/ci/foundation-deps-full-check.sh
bash -n .github/ci/foundation-boundary-check.sh
bash -n .github/ci/foundation-evidence-collect.sh
FOUNDATION_DEPS_MODULES=kernel FOUNDATION_GO_BASELINE_MODE=fail bash .github/ci/foundation-deps-full-check.sh
FOUNDATION_BOUNDARY_MODULES=kernel bash .github/ci/foundation-boundary-check.sh
FOUNDATION_EVIDENCE_OUTDIR=/tmp/foundation-evidence-smoke bash .github/ci/foundation-evidence-collect.sh foundation-ci-plan-smoke
```

当前已知漂移复现命令，修复前预期返回非零，不作为通过项：

```bash
FOUNDATION_BOUNDARY_MODULES=contracts bash .github/ci/foundation-boundary-check.sh
FOUNDATION_DEPS_MODULES=contracts FOUNDATION_GO_BASELINE_MODE=fail bash .github/ci/foundation-deps-full-check.sh
bash .github/ci/foundation-deps-full-check.sh
```

本地全量 deps smoke 已确认上述模块仓 drift 会阻断；其中 `natsx` 模块 boundary 在本地环境长时间无输出，当前回合已终止该验证进程，完整全量运行应交给 CI runner 按 job timeout 执行。

需要网络和跨仓访问的完整验证：

```bash
bash .github/ci/foundation-deps-full-check.sh
bash .github/ci/foundation-boundary-check.sh
bash .github/ci/foundation-joint-build.sh
bash .github/ci/foundation-evidence-collect.sh foundation-ci-plan-smoke
```

这些跨仓命令应在 runner 环境中执行，确保 GitHub 凭据、网络、Go 工具链和 artifact 权限与真实 CI 一致。

## 16. 结论

完整 CI 的核心不是新增更多 workflow，而是把现有骨架补成可阻断、可追溯、可观测的门禁链。

短期优先级：

1. 已完成控制面文档同步、joint build 失败阻断、release manifest/SRE contract 生成与 preflight。
2. 已完成真实 import 边界检查、module path 身份门禁和 Go baseline 默认阻断。
3. 统一 6 个模块仓的 module-ci，输出同构 evidence。
4. 继续把 release evidence 接入模块 build/test 摘要、SBOM 和 SRE 返回证据。
5. 修正 `contracts` module path drift 与 `testkitx` boundary 命中。
6. 保持 CI 与部署双平面隔离，避免为了接入机器池而放宽 runner 和部署守卫。
