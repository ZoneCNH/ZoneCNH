# SRE Tools

数据域配置注入工具集。

## gen-env.sh — 从 dev.md 生成本地 .env

从 `sre/secrets/env/dev.md` 的 per-provider 凭据自动生成 adapter 的 `.env`（含真值，不进 git）或 `.env.example`（无真值，可提交）。

### 用法

```bash
# 生成 /home/fred/.env（含真值，自动确保 .gitignore 排除）
./docs/sre/tools/gen-env.sh fred

# 生成 /home/binance/.env.example（无真值，可提交）
./docs/sre/tools/gen-env.sh binance --example

# 输出到 stdout（不写文件，适合检查）
./docs/sre/tools/gen-env.sh okx --stdout
```

### 生成的 .env 格式

统一 `XGO_{MODULE}_*` 前缀，对齐 bootstrap configx EnvSource（报告 §七 / SOP §七）：

```bash
# ---- Provider API ----
XGO_FRED_API_KEY=<dev.md FRED key>     # 仅 fred 模块
XGO_BINANCE_API_KEY=                    # 行情模块（公共行情通常不需要）
XGO_BINANCE_API_SECRET=
XGO_BINANCE_MODE=testnet

# ---- Dispatch 目标 ----
XGO_{MODULE}_DISPATCH_TARGET=market-data   # 行情 → market-data；宏观 → macro-data
XGO_{MODULE}_DISPATCH_ADDR=:9090

# ---- 可观测（bootstrap 统一加载）----
XGO_{MODULE}_LOG_LEVEL=info
XGO_{MODULE}_METRICS_ADDR=:9091
```

### 关键设计

- **adapter 零存储**：`.env` 不含 PG/TD/Redis/Kafka/OSS/CH 凭据——这些属于聚合层（market-data/macro-data）
- **自动分类**：脚本根据 module 名自动识别行情（`market_*` 库）/宏观（`macro_*` 库）
- **库名变体**：自动处理 dev.md 库名差异（jin10→jinshi、japan-cb→japan_cb、yield-curve→yield_curve）
- **安全**：`--write` 模式生成的 `.env` 含明文密码，自动确保在 `.gitignore` 中

### 关联

- [基础架构报告 §七](../../docs/report/data-domain-infrastructure-20260617.md)
- [Bootstrap SOP §七](../../docs/sre/data-domain-bootstrap.md)
