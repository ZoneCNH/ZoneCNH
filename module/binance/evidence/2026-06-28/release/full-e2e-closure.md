# 2026-06-28 全量 E2E 证据闭合

## 概述

2026-06-28 完成 binance 模块全部 13 个 GitHub issues（#1267-#1279）和 13 个 Beads issues（ZoneCNH-xzcr* + ZoneCNH-8lb）的证据闭合。

## 证据来源

- **Runtime 仓库**：`/home/binance@2efc44a`
- **证据归档**：`/home/binance/release/evidence/binance/20260628-full-e2e-closure/`
- **配置来源**：`/home/ZoneCNH/sre/secrets/env/dev.md`（通过 `/home/binance/.env` 加载）

## 7 个外部依赖 E2E 结果

| 依赖 | 检查内容 | 状态 | 证据文件 |
| ---- | -------- | ---- | -------- |
| redisx | connect + set | PASS | storage-live.log |
| kafkax | produce + consume roundtrip | PASS | kafka-live.log |
| natsx | JetStream semantics | PASS | natsx-integration.log |
| postgresx | connect + exec | PASS | storage-live.log |
| taosx | WebSocket connect + health | PASS | storage-live.log |
| ossx | aliyun OSS archive + list + delete | PASS | oss-live.log |
| clickhousex | connect + exec | PASS | storage-live.log |

## 4 条产品线 Mainnet Live 结果

| 产品线 | WebSocket Endpoint | 状态 | 证据文件 |
| ------ | ------------------- | ---- | -------- |
| spot | wss://stream.binance.com:9443 | PASS | mainnet-live.log |
| um_perp | wss://fstream.binance.com | PASS | mainnet-live.log |
| cm_perp | wss://dstream.binance.com | PASS | mainnet-live.log |
| options | wss://fstream.binance.com/public | PASS | mainnet-live.log |

## 全量门禁结果

| 检查项 | 状态 |
| ------ | ---- |
| go build ./... | PASS |
| go vet ./... | PASS |
| go test -race ./... | PASS |
| boundary-gates.sh (14 gates) | PASS |
| golangci-lint run | PASS |
| govulncheck | PASS |
| gofmt -l | PASS |

## 根因修复

此前 taosx 和 clickhousex E2E 失败的根因是执行测试前未 `source .env`，导致环境变量未注入。修复方式：`set -a; source .env; set +a` 后再执行 `STORAGE_LIVE=1` 测试。

## 10x 重复检查

10 轮检查均确认 GitHub 和 Beads 的 binance 相关 open issues = 0。

## release_closeable

YES
