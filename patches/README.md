# ZoneCNH Runtime Patch Bundle

本次生成的代码补丁，对应 ZoneCNH/ZoneCNH docs hub 中已发布的模块 SPEC。

## 应用顺序

```
1. domain-market    → github.com/ZoneCNH/domain-market
2. contracts        → github.com/ZoneCNH/contracts
3. market-data      → github.com/ZoneCNH/market-data (空仓库，从零初始化)
4. binance          → github.com/ZoneCNH/binance (老 SDK 升级)
```

## 各仓库应用方法

### domain-market (add canonical types)

```bash
cd domain-market
cp ../patches/domain-market/canonical.go pkg/domainmarket/
cp ../patches/domain-market/canonical_test.go pkg/domainmarket/
# 添加 decimalx 依赖
go get github.com/ZoneCNH/decimalx@latest
go mod tidy
# 构建 + 测试
go build ./...
go test ./... -race -count=1
```

### contracts (add ingestion wire contract)

```bash
cd contracts
cp ../patches/contracts/ingestion.go pkg/contracts/
cp ../patches/contracts/ingestion_test.go pkg/contracts/
go build ./...
go test ./... -race -count=1
```

### market-data (init empty repo)

```bash
cd market-data
go mod init github.com/ZoneCNH/market-data
mkdir -p pkg/dispatch
cp ../patches/market-data/dispatch.go pkg/dispatch/
go mod tidy
go build ./...
```

### binance (upgrade to C/S Module)

```bash
cd binance
mkdir -p internal/server
cp ../patches/binance/server.go internal/server/
go build ./...
```

## 依赖链

```
domain-market (canonical types)
    ↓
contracts (ingestion DTOs)
    ↓
market-data (dispatch port) ← binance (server implementation)
```

## 生成信息

- 日期: 2026-06-17
- 来源: ZoneCNH/ZoneCNH docs hub SPEC v0.1.1 ~ v1.1.0
- 语言: Go 1.23
