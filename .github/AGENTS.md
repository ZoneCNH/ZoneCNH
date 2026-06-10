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
- 所有直接声明 runner 的 `.github/workflows/*.{yml,yaml}` job，其 `runs-on` 必须严格为 `[self-hosted, Linux, X64]`
- 禁止使用 GitHub-hosted runner、lowercase 变体或业务/个人/模块专属额外 runner label
- job 级 reusable workflow `uses:` 只能指向 `./.github/workflows/*`，不得调用外部 reusable workflow 绕过 runner 策略
- 部署到运行环境或远端机器的 job 必须统一以 `sre/` 机器池为目标
- workflow 变更必须通过 `bash .github/ci/workflow-policy-guard.sh`
