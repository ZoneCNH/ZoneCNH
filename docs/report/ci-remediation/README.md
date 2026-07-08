# CI 修复与一致性审计（全模块）

> 目标：深度分析 `/home/workspace/` 下每个模块的 CI 配置，修复缺陷直至 CI 通过。
> 状态：**进行中（Wave 1 基础库 + Wave 3 治理仓 静态审计中）**。

## 关键发现：本地 checkout 为治理/CI 脚手架，不含实现源码

本机 `/home/workspace/{module}` 各仓为 **CI/治理脚手架**（含 `.github/workflows/`、`scripts/`、`go.mod`、`Makefile`、`docs`），但 **`pkg/` 等实现目录为空**，`git ls-tree main` 确认 0 个 `.go` 文件，`go build ./...` 仅因无包可编译而返回 0。真正的实现源码与 CI 实际执行均在远端 GitHub。

因此本任务的**本地可验证部分＝CI workflow YAML 配置静态审计与修复**（fred 的 D-P0-2「integration 空跑」即此类缺陷）。代码级 `go test` 通过与否只能在远端 CI 验证，无法在本地伪造。

## 模块分类（71 个目录）

| 类别 | 数量 | 说明 | 处置 |
| ---- | ---- | ---- | ---- |
| 有 CI + 有本地源码 | 0 | 本地均无源码 | — |
| 有 CI（workflow 存在） | 35 | 配置静态审计 + 修复 | Wave 1 / Wave 3 覆盖 |
| 无 CI（NOCI） | 36 | 多为市场/交易所源模块，本地无源码 | 见「NOCI 模块处置建议」 |

## 审计维度（每个 workflow）

1. 被引用的本地脚本/action/path 是否真实存在（`make <target>`、`./scripts/...`、内联）。
2. 本地可复用 workflow `uses: ./.github/workflows/...` 是否解析。
3. integration/soak/chaos/security/live 作业是否带对应 `-tags`（fred D-P0-2 类）。
4. `go-version` / `actions/setup-go` 版本引用是否合理一致。
5. YAML 可解析性（`python3 yaml.safe_load`）。

## 跨模块静态审计速览（脚本初扫）

| 检查项 | 结果 |
| ------ | ---- |
| 被引用本地脚本缺失 | 0（未发现） |
| 本地可复用 workflow 引用未解析 | 0（未发现） |
| integration 作业缺 `-tags`（需逐文件确认） | 待各 agent 逐文件核实 |

## 各模块结果

> 由 agent 团队回填（Wave 1：domain/messaging/coreinfra/storage/support；Wave 3：binance/ms_brain/market_data/ZoneCNH/xlib_*）。

| 模块 | Agent | workflow 数 | 缺陷数 | 已修复 | 剩余阻塞 | 分支 |
| ---- | ----- | ---------- | ------ | ------ | -------- | ---- |
| _（待回填）_ | | | | | | |

## NOCI 模块处置建议

36 个无 CI 模块（多数为交易所/市场数据源：bitget/okx/bybit/coinbase/kucoin/mexc/upbit/htx/hyperliquid/gate/lighter/coinglass/ecb/bea/treasury/uk_cb/japan_cb/yahoo/yield_curve/eastmoney/jin10/crcl/macro_data/macro_regime/market_data?/market_regime/regime_engine/riskx/signal_factory/ms_brain?/composer/frontend/mxs/gostacks/foundationx 等）：

- 本地无 `.go` 源码 ⇒ 此刻创建 CI 无实际构建目标，且无法在本地验证其正确性。
- **建议**：待实现源码落入远端仓后，统一引用 `foundationx` 提供的可复用 CI workflow（或按标准 `ci.yml` 模板创建），避免 36 份重复配置。不在本任务内臆造 CI。
- 例外：`fred` 已在前期完成 registry/CI 门禁修复（PR #1729/#1730/#1731/#1733）。

## 分支纪律

所有修复在 `/home/workspace/{module}` 各自 `fix/ci-{module}` 分支提交，**不提交 main**；ZoneCNH 报告在 `docs/ci-remediation` 分支。统一 PR 待 consolidation 阶段推送。
