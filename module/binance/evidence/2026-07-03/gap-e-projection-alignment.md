# GAP-E 投影对齐补证（2026-07-03）

## 范围

本证据用于补齐 `module/binance/evidence/` 对运行时缺口（GAP-E）的显式引用，保证治理投影与 issue/traceability 口径一致。

## 关联缺口

- GAP-E6：UM/CM/Options 4 线 ExchangeInfoRefresher 装配
- GAP-E7：SPEC §509 移除 history_state_postgres.go（前置）
- GAP-E24：CatalogEntry 动态分级（Tier/SymbolPriority/Collection）
- GAP-E44/E45：SECURITY / CONTRIBUTING 治理补齐
- GAP-E57：evidence 目录缺少 GAP-E 显式引用

## 对齐结论

1. `todo.md` 已与 GitHub #1540~#1592 状态对齐，Phase 1/2/5 已反映关闭状态。  
2. `matrix/TRACEABILITY.md` 中 PRG-006 已由 PASS 调整为 Partial。  
3. `spec/SPEC.md`、`spec/client/SPEC.md`、`spec/server/SPEC.md` 版本已统一到 v3.9.8。  
4. `SECURITY.md` 与 `spec/CONTRIBUTING.md` 已落地，满足治理文档补齐路径。  

[RULES I BROKE]：无
