# module/binance registry

模块级注册投影。跨模块 Registry SSOT 归属 `.config/goal/registry/`。

## 当前投影

### Goal

- **GOAL-binance-v1**: Binance-specific market_data C/S module（见 `../goal/goal.md`）
- Status: Active
- Spec: SPEC-binance-v3.7.1
- Runtime: /home/binance@f046e16

### 状态投影

| FR 状态 | 数量 |
|---------|------|
| Done | 24 |
| Partial | 10 |
| Pending | 10 |
| Total | 44 |

详见 `../matrix/TRACEABILITY.md` 与 `../../report/binance/issues-sync-20260625.md`。

## 与 `.config/goal/registry/` 的关系

本目录为模块本地投影，供快速查阅。跨模块查询、Gate 裁决、CI 校验以 `.config/goal/registry/` 的 `goals.yaml`、`tasks.yaml` 等为准。
