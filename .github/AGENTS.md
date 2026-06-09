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
