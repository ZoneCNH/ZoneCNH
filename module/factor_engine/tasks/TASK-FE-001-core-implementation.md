# TASK-FE-001 Core Implementation

## Objective

实现 factor_engine 因子计算引擎：因子定义、因子计算管线、因子存储、因子元数据管理。

## Covers

All FR/BR/NFR defined in TRACEABILITY.md §1-§3.

## Acceptance Criteria

1. `go test ./... -count=1` 通过
2. `go vet ./...` 零警告
3. 覆盖率 >= 80%

## Dependencies

- domain_market (行情数据)
- domain_macro (宏观数据)
- domainx (订单/持仓模型)
