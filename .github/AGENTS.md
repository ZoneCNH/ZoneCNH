# .github 目录

FoundationX GitHub 配置。存放 CI/CD 工作流、代码所有权和仓库级配置。

## 目录结构

```text
.github/
├── workflows/                 # GitHub Actions 工作流
├── ci/                        # CI 配置脚本
├── CODEOWNERS                 # 代码所有权
└── yamllint.yml               # YAML lint 配置
```

## 规则

- 工作流变更需通过 PR 审查
- CODEOWNERS 必须反映当前模块所有权
- CI 脚本必须有错误处理和超时设置
- 所有直接声明 runner 的 `.github/workflows/*.{yml,yaml}` job，其 `runs-on` 必须严格为 `[self-hosted, Linux, X64, ci-governance]`
- 禁止使用 GitHub-hosted runner、lowercase 变体或未批准的业务/个人/模块专属额外 runner label
- job 级 reusable workflow `uses:` 默认只能指向 `./.github/workflows/*`；部署类 job 只能调用 `ZoneCNH/sre/.github/workflows/deploy-contract.yml@main`
- 主页仓库不得收纳或跟踪 `sre/` 源码；`.gitignore` 必须保留 `sre/`
- 禁止在本仓库 workflow 中内联 `ssh`、`scp`、`rsync`、`kubectl`、`helm`、`systemctl` 或 `docker compose` 等远程部署命令
- 部署到运行环境或远端机器的 job 必须统一以 `sre/` 机器池为目标
- workflow 变更必须通过 `bash .github/ci/workflow-policy-guard.sh`
- 部署边界变更必须通过 `bash .github/ci/deploy-policy-guard.sh`
