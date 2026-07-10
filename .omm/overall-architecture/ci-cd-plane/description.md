CI/CD 执行平面。.github/workflows/ 下 workflow（integration.yml、test.yml 等）；BASELINE.yaml 是 Go 基线 + CI/CD runner 策略 SSOT；docs/sre/ 下 RUNNER-POOLS.yaml（11 个 sre/* runner pool）和 MODULE-RUNNER-MAP.yaml（68 模块到 runner pool 的映射）；knowledge/ci.md 是 CICD-001 完整方案。

CICD-001 规定全体系只运行在 self-hosted runners（[self-hosted, Linux, X64, sre/*] pool），禁止 GitHub-hosted runners；部署只能走 sre/deploy。
