本仓库是 Markdown 文档枢纽，没有构建/lint/测试步骤（无 go.mod、无 package.json 业务代码）。治理对象是 github.com/ZoneCNH 下 70+ 独立模块仓库；模块代码的本地工作目录由 registry.yaml 的 local_path 字段指定（每模块一个独立 git 仓库），本仓库只引用不收纳。

仓库级强制规则：禁止 Kubernetes 与 Docker（含相关配置与命令）；仓库命名强制 snake_case（仅 x.go 与 binance.rs 例外）；创建新模块/仓库须双闸门授权（治理层 §12 修正程序 + 执行层人工会话显式授权）。

CICD-001 规定全体系 CI/CD 只运行在 self-hosted runners（sre/* pool），禁止 GitHub-hosted runners；部署只能走 sre/deploy，业务仓库禁止内联 ssh/scp/rsync/kubectl/helm/docker compose。
