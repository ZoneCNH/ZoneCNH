# 模块模板体系入口

> ZoneCNH 模块模板统一索引。新增模块时按架构类型选用对应模板。
> 本文件是模板体系的统一入口，消除模板碎片化（P2 处置）。

## 模板索引

| 模板 | 路径 | 适用范围 |
| --- | --- | --- |
| CEX C/S Module 模板 | [`./cex-cs-module/README.md`](./cex-cs-module/README.md) | 数据域 · 行情交易所接入（CEX/DEX/聚合数据源）的范式定义 |
| C/S Module 标准化模板 | [`../data_cs_module/README.md`](../data_cs_module/README.md) | 数据域 C/S 子模块（行情 + 宏观），含 23 节 SPEC 模板 + SDK→C/S 升级路线图 |
| 独立进程标准化模板 | [`../data_independent_process/README.md`](../data_independent_process/README.md) | 分析域独立进程模块，含 23 节 SPEC 模板 |
| Exchange 模板 | [`../_exchange-template/README.md`](../_exchange-template/README.md) | 交易所接入模板 |

## 选用指南

| 新增模块类型 | 选用模板 |
| --- | --- |
| 行情交易所 C/S 模块（CEX/DEX） | `cex-cs-module`（范式定义）+ `data_cs_module`（SPEC 模板） |
| 宏观 C/S 模块（fred/ecb/...） | `data_cs_module`（SPEC 模板 + 升级路线图） |
| 独立进程模块（factor_engine/regime_engine/...） | `data_independent_process` |

## 设计说明

`data_cs_module` / `data_independent_process` 因含活跃治理文档（UPGRADE-ROADMAP.md 升级路线图、23 节 SPEC 模板）且被 11+ 处治理文档与 SPEC 引用，保留原位置以避免破坏相对引用链；通过本入口统一索引，消除模板碎片化。`cex-cs-module` 是行情专用的 C/S 范式定义，与 `data_cs_module`（通用 C/S SPEC 模板）互补。
