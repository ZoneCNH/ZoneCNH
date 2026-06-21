# data_independent_process — 独立进程标准化模板

分析域独立进程模块的 23 节 SPEC 模板和实现指南。

## 适用模块

| 域 | 模块 | 数量 |
|----|------|:---:|
| 分析域 | market_regime, macro_regime, regime_engine, factor_engine, feature_store, factor_eval, flowx, ms_brain | 8 |
| 数据域 (dispatch) | market_data, macro_data | 2 |

## 文件

| 文件 | 用途 |
|------|------|
| [SPEC-TEMPLATE.md](./SPEC-TEMPLATE.md) | 独立进程 23 节 SPEC 模板 — 新建模块时复制填写 |
| [README.md](./README.md) | 本文件 |

## 架构类型

详见 [ARCHITECTURE.md#模块架构类型](../../ARCHITECTURE.md#模块架构类型)

## 与 C/S Module 的区别

| 特征 | C/S Module | 独立进程 |
|------|:---:|:---:|
| client/server 拆分 | ✅ | ❌ |
| spool/checkpoint/idempotency | ✅ | ❌ |
| bootstrap 接入 | ✅ | ✅ |
| contracts port | ✅ | ✅ |
| admin 端点 | ✅ | ✅ |
| 专属 Gate 数 | 6 | 4 |

## 使用方式

```bash
cp module/data_independent_process/SPEC-TEMPLATE.md module/{新模块}/SPEC.md
```
