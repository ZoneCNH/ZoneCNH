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
- CI/CD job 必须运行在 self-hosted runner，基础标签为 `[self-hosted, Linux, X64]`
- 主页仓库不得收纳或跟踪 `sre/` 源码；`.gitignore` 必须保留 `sre/`
- 部署工作流只能调用 `ZoneCNH/sre/.github/workflows/deploy-contract.yml@main`
- 禁止在本仓库 workflow 中内联 `ssh`、`scp`、`rsync`、`kubectl`、`helm`、`systemctl` 或 `docker compose` 等远程部署命令
