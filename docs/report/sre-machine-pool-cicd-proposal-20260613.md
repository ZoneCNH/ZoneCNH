# SRE 机器池 CI/CD 架构提案（兼容现有 runner 与部署目标策略）

> 日期：2026-06-13  
> 范围：仅基于本仓库可见的 workflow、CI 守卫脚本和治理文档提出架构建议；不修改现有 CI/CD 行为。

## 1. 目标与边界

本提案回答：在不破坏现有 runner 约束和部署目标策略的前提下，如何设计面向 SRE 机器池的 CI/CD 架构。

成功标准：

- 直接声明 runner 的业务仓库 job 继续严格使用 `[self-hosted, Linux, X64, homepage]`。
- 真实部署不在业务仓库内联执行，必须通过 `ZoneCNH/sre` 的 reusable workflow 发布入口承接。
- 部署到运行环境或远端机器时，目标机器池统一表达为 `sre/`。
- 提案区分“证据 / 推论 / 未知项”，并给出可落地的优先级建议。

## 2. 证据（来自本仓库文件）

### 2.1 Runner 与 reusable workflow 硬约束

- `.github/AGENTS.md:20` 要求所有直接声明 runner 的 workflow job，其 `runs-on` 必须严格为 `[self-hosted, Linux, X64, homepage]`。
- `.github/AGENTS.md:21` 禁止 GitHub-hosted runner、lowercase 变体或未批准的业务/个人/模块专属额外 runner label。
- `.github/AGENTS.md:22` 要求 job 级 reusable workflow 默认只能指向仓库内 workflow；部署类 job 只能调用 `ZoneCNH/sre/.github/workflows/deploy-contract.yml@main`。
- `.github/ci/workflow-policy-guard.sh:12` 将期望 runner 固定为 `['self-hosted', 'Linux', 'X64', 'homepage']`。
- `.github/ci/workflow-policy-guard.sh:94-99` 会在 `runs-on` 标签不完全匹配时失败。
- `.github/ci/workflow-policy-guard.sh:109-116` 会拒绝非仓库内 reusable workflow 或非批准 SRE deploy-contract 的调用。

### 2.2 SRE 控制面与部署目标边界

- `.github/AGENTS.md:23` 要求主页仓库不得收纳或跟踪 `sre/` 源码，并且 `.gitignore` 必须保留 `sre/`。
- `.github/AGENTS.md:24` 禁止在本仓库 workflow 中内联 `ssh`、`scp`、`rsync`、`kubectl`、`helm`、`systemctl` 或 `docker compose` 等远程部署命令。
- `.github/AGENTS.md:25` 要求部署到运行环境或远端机器的 job 必须统一以 `sre/` 机器池为目标。
- `.github/ci/deploy-policy-guard.sh:18-24` 同时检查 `.gitignore` 是否保留 `sre/`，以及是否误跟踪 `sre/` 路径。
- `.github/ci/deploy-policy-guard.sh:43-48` 要求部署 workflow 调用 `ZoneCNH/sre/.github/workflows/deploy-contract.yml@main`，并拒绝 inline 远程部署命令。
- `.gitignore:97` 已保留 `sre/`。

### 2.3 治理文档中的发布入口合同

- `docs/governance/DEPLOYMENT.md:108-112` 明确普通文档、测试、治理类 job 使用 `homepage` profile，部署执行必须通过 `ZoneCNH/sre` reusable workflow，部署 profile 标签由 SRE 仓库内部承接。
- `docs/governance/DEPLOYMENT.md:114-125` 给出业务仓库新增部署时唯一允许的 reusable workflow 示例，输入包括 `target`、`environment`、`action` 和 `ref`。
- `docs/governance/DEPLOYMENT.md:127-133` 要求部署 workflow 禁止 `pull_request` 触发、必须配置 GitHub Environment 和 concurrency，且 smoke/rollback 由 SRE 仓库入口承接。
- `docs/governance/DEPLOYMENT.md:220` 再次声明本仓库禁止 GitHub-hosted runner，部署必须调用 SRE 发布入口并以 `sre/` 机器池为目标。

### 2.4 现有 CI/CD 拓扑

- `docs/ci-deployment.md:8` 描述本仓库 GitHub Actions 直接 job 统一运行在 `[self-hosted, Linux, X64, homepage]`，部署目标统一为 `sre/`。
- `docs/ci-deployment.md:45-47` 要求部署到运行环境或远端机器的 job 统一落在 `sre/` 机器池，并说明 `release.yml` 当前只创建 GitHub Release 元数据，不等同机器部署。
- `docs/ci-deployment.md:162-165` 将 `markdownlint`、`link-check`、`grep-guard` 和 `workflow-policy-guard` 列为 docs CI 的关键检查，其中 `workflow-policy-guard` 是全局 runner 与部署目标策略守卫。
- `.github/workflows/release.yml:17-23` 复用 `docs-ci.yml` 与 `goal-ci.yml` 作为发布质量门禁。
- `.github/workflows/release.yml:25-39` 在发布前执行 `goal-release-gate.sh`，且该 job 使用 `[self-hosted, Linux, X64, homepage]`。
- `docs/ci-deployment.md:282` 明确当前 Release workflow 不执行机器部署；后续若增加真实部署步骤，部署目标必须统一为 `sre/` 机器池。

## 3. 推论（基于证据的架构判断）

1. 本仓库应被视为“业务 CI 与发布编排仓库”，而不是部署执行控制面；它可以发起质量门禁、生成发布元数据、调用 SRE 发布合同，但不应直接持有部署脚本、远程命令或 SRE runner profile。
2. `homepage` runner label 是业务仓库的 CI 执行 profile；`sre/` 是部署目标机器池/控制面边界，不应被写成业务仓库 job 的额外 `runs-on` label。
3. 兼容现有策略的最小架构是“双平面”：业务 CI 平面继续跑在 `[self-hosted, Linux, X64, homepage]`；部署执行平面隐藏在 `ZoneCNH/sre` reusable workflow 后，由 SRE 仓库内部选择真实机器池、凭据、smoke 与 rollback 实现。
4. 当前 release pipeline 已具备“质量门禁 → 发布门禁 → 发布元数据”的骨架；真实部署应作为后续受控 job 接在这些门禁之后，而不是替换现有 CI job 或放宽 runner 策略。
5. 由于策略守卫已经脚本化，新增部署能力的主要风险不是本仓库 CI label 漂移，而是 SRE deploy-contract 的输入/输出合同、审批、并发和回滚证据是否足够明确。

## 4. 未知项（本仓库不可见或需 SRE 确认）

- `ZoneCNH/sre` 仓库的 `deploy-contract.yml` 实现、输入默认值、输出字段和失败语义在本仓库不可见。
- `sre/` 机器池的真实机器清单、容量、隔离策略、扩缩容方式和 runner 生命周期在本仓库不可见。
- GitHub Environment 的 reviewer、secret 分层、production 审批策略和审计保留期在本仓库不可见。
- SRE 侧 smoke、rollback、canary 或蓝绿发布脚本的幂等性、超时、重试和日志归档策略在本仓库不可见。
- 当前仓库没有真实机器部署 workflow，因此无法从本仓库验证 SRE 发布合同的端到端执行结果。

## 5. 推荐架构

### 5.1 控制面分层

| 平面 | 所属仓库 | 执行位置 | 主要职责 | 本仓库可见合同 |
| --- | --- | --- | --- | --- |
| 业务 CI 平面 | 本仓库 | `[self-hosted, Linux, X64, homepage]` | 文档检查、Goal CI、治理守卫、发布元数据 | `.github/workflows/*.yml` + `.github/ci/*` |
| 发布编排平面 | 本仓库 | `[self-hosted, Linux, X64, homepage]` 或 job 级 reusable workflow 调用 | 在质量门禁后选择 target/environment/action/ref，并调用 SRE 合同 | `uses: ZoneCNH/sre/.github/workflows/deploy-contract.yml@main` |
| SRE 部署执行平面 | `ZoneCNH/sre` | SRE 内部机器池 / runner / 部署节点 | 凭据装载、远程发布、smoke、rollback、审计 | 本仓库只通过 reusable workflow 输入/输出感知 |

### 5.2 建议 workflow 形态

新增真实部署能力时，不修改既有 CI runner 策略；新增部署 job 应位于 release/部署 workflow 的质量门禁之后：

```yaml
jobs:
  quality-gate:
    uses: ./.github/workflows/docs-ci.yml

  goal-control-plane:
    uses: ./.github/workflows/goal-ci.yml

  deploy-staging:
    needs:
      - quality-gate
      - goal-control-plane
    uses: ZoneCNH/sre/.github/workflows/deploy-contract.yml@main
    with:
      target: homepage
      environment: staging
      action: deploy
      ref: ${{ github.sha }}
```

部署 workflow 还应保留：

- `concurrency`：按 `target + environment` 分组，避免同一环境并发发布。
- `environment`：staging 与 production 分离；production 必须走 GitHub Environment 审批。
- `permissions`：默认最小权限；只给发布元数据、OIDC 或 artifact 下载所需权限。
- `workflow_dispatch` / tag / release 触发：避免 `pull_request` 直接触发真实部署。

### 5.3 SRE deploy-contract 建议输入/输出

建议 SRE 合同至少稳定以下输入：

| 字段 | 建议 | 原因 |
| --- | --- | --- |
| `target` | `homepage` 等业务服务标识 | 业务仓库表达“部署什么”，不表达机器细节 |
| `environment` | `staging` / `production` | 绑定 GitHub Environment 审批、secret 和审计 |
| `action` | `plan` / `deploy` / `smoke` / `rollback` | 支持可审计的发布动作拆分 |
| `ref` | commit SHA 或 release tag | 保证部署对象可追溯 |
| `change_id` | 可选，release id / run id | 方便跨仓库日志关联 |
| `rollback_ref` | 可选 | 让 rollback 目标显式化 |

建议 SRE 合同至少返回以下输出或 artifact：

- `deployment_id`：SRE 侧发布流水号。
- `target_pool`：实际承接的 SRE 机器池或逻辑池名。
- `smoke_result`：smoke 结论与关键探针。
- `rollback_artifact`：rollback 入口、目标版本和执行证据。
- `audit_log_url`：SRE 侧日志或审计记录链接。

## 6. 具体建议

### P0：保持现有策略不可变

1. 继续要求所有本仓库直接 job 使用 `[self-hosted, Linux, X64, homepage]`；不要新增 `sre`、`deploy`、业务机或个人机 runner label。
2. 继续保留 `.gitignore` 中的 `sre/`，并保持 `.github/ci/deploy-policy-guard.sh` 阻止误跟踪 SRE 控制面源码。
3. 新增真实部署时只允许 job 级调用 `ZoneCNH/sre/.github/workflows/deploy-contract.yml@main`；不得在业务仓库写远程部署命令。
4. 部署 workflow 必须配置 `concurrency`、GitHub Environment 和非 `pull_request` 触发策略。

### P1：把“机器池”从 runner label 中解耦

1. 在业务仓库中将 `homepage` 理解为 CI profile，将 `sre/` 理解为部署目标池/控制面边界。
2. 将真实机器选择、凭据装载、远程命令、smoke 与 rollback 全部放在 SRE 仓库内部。
3. 在 SRE deploy-contract 输出中暴露逻辑 `target_pool` 和审计链接，而不是让业务仓库感知具体主机。

### P1：补充跨仓库证据合同

1. 要求 SRE deploy-contract 上传部署摘要 artifact，至少包含 commit、environment、target、deployment id、smoke 结果和 rollback 指令。
2. 业务仓库发布说明可链接该 artifact，但不复制 SRE 内部脚本。
3. 将 smoke/rollback 证据纳入 release gate 的人工检查清单，等 SRE 合同稳定后再考虑机器可读门禁。

### P2：增强本仓库守卫的说明性测试

1. 增加一个文档化的“允许/拒绝样例”清单，覆盖错误 runner label、GitHub-hosted runner、inline ssh、缺少 concurrency、非 SRE reusable workflow 等案例。
2. 在不引入真实部署的前提下，为 `workflow-policy-guard.sh` 和 `deploy-policy-guard.sh` 增加 fixture 级回归测试，降低未来策略漂移风险。
3. 保留 `self-hosted-test.yml` 作为 runner 可用性烟雾测试，但不要把它扩展成部署探针。

## 7. 兼容性矩阵

| 现有策略 | 提案是否兼容 | 说明 |
| --- | --- | --- |
| 直接 job 必须使用 `[self-hosted, Linux, X64, homepage]` | 兼容 | 提案不新增直接部署 runner label |
| reusable workflow 只能本仓库或 SRE deploy-contract | 兼容 | 真实部署只通过 SRE contract |
| 不跟踪 `sre/` 源码 | 兼容 | 本仓库只引用 `ZoneCNH/sre`，不收纳控制面 |
| 禁止 inline 远程部署命令 | 兼容 | 远程动作在 SRE 仓库内部执行 |
| 部署目标统一为 `sre/` | 兼容 | 业务仓库表达目标，经 SRE 合同落到 SRE 机器池 |
| release 当前只发布元数据 | 兼容 | 提案建议部署作为后续受控增量，不改变当前 release 语义 |

## 8. 建议落地顺序

1. **先不改 workflow**：确认本提案与 SRE 团队对 deploy-contract 的输入/输出理解一致。
2. **定义 SRE 合同文档**：在 SRE 仓库或治理文档中明确 deploy-contract 输入、输出、artifact 和失败语义。
3. **加 staging-only 部署 job**：在质量门禁之后接入 `deploy-staging`，只允许手动或受控触发。
4. **接入 smoke/rollback 证据**：要求 SRE contract 返回 artifact，再把链接纳入发布说明。
5. **生产发布审批**：确认 GitHub Environment reviewer 与 concurrency 策略后，再开放 production。
6. **回归测试守卫**：为策略守卫增加 fixture 测试，确保未来新增 workflow 不绕过 runner/deploy 边界。

## 9. 结论

推荐采用“业务 CI 固定 homepage runner + SRE deploy-contract 承接真实部署”的双平面架构。这样可以在不改变现有 runner 策略、不收纳 SRE 控制面、不暴露远程部署命令的前提下，把部署职责集中到 `ZoneCNH/sre` 的机器池与审计体系中。
