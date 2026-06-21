# data-cs-module — C/S Module 标准化模板

数据域 C/S 子模块的 23 节 SPEC 模板和实现指南。

## 适用模块

| 域 | C/S Module 列表 | 数量 |
|----|----------------|------|
| market_data | binance(参考实现), okx, bybit, bitget, kucoin, gate, mexc, htx, coinbase, hyperliquid, lighter, upbit, coinglass | 13 |
| macro_data | fred, treasury, yield_curve, bea, ecb, uk_cb, japan_cb, eastmoney, jin10, yahoo | 10 |

## 文件

| 文件 | 用途 |
|------|------|
| [SPEC-TEMPLATE.md](./SPEC-TEMPLATE.md) | C/S Module 23 节 SPEC 模板 — 新建模块时复制填写 |
| [UPGRADE-ROADMAP.md](./UPGRADE-ROADMAP.md) | SDK → C/S Module 升级路线图 — P0/P1/P2 三批 22 模块 |
| [README.md](./README.md) | 本文件 |

## 参考实现

[module/binance/SPEC.md](../binance/SPEC.md) — 首个完整 C/S Module 规格（v0.2.0，bootstrap 接入 + client/server + 4 产品线）

## 架构类型

详见 [ARCHITECTURE.md#模块架构类型](../../ARCHITECTURE.md#模块架构类型)

## 使用方式

```bash
cp module/data-cs-module/SPEC-TEMPLATE.md module/{新模块}/SPEC.md
# 然后按模板中的使用指南逐项填写
```
