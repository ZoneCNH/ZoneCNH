# Boundary Gates 推广模板

> 来源：`module/binance/gate/BOUNDARY-GATES.md` §20（Plan007 B8），2026-06-28 迁移至此。
> 参考实现：binance `scripts/boundary-gates.sh`（13 gates）。
> 跨模块推广指南另见 [`boundary-gates-cross-module-promotion.md`](boundary-gates-cross-module-promotion.md)。

---

## 模块适配矩阵

| 模块 | 保留 gates | 移除 gates | 备注 |
|:-----|:-----------|:-----------|:-----|
| `binance` | 全部 13 | — | 参考实现 |
| `bootstrap` | §2/§5/§11 | §3/§4/§6-§10/§12-§14（无 C/S 架构） | 已就位 (6 gates) |
| `natsx` | §11（go.mod 合规） | 其余 | 待创建 |
| `contracts` | §11 + 纯度门禁（无 infra 依赖） | 其余 | 待创建 |
| `domain_*` | §9/§11 | 其余 | 待创建（纯度门禁：零 infra import） |
| `transportx` | §11 | 其余 | 待创建 |

## 实施状态

- ✅ `binance`：13 gates 完整实现 + CI 集成（`.github/workflows/boundary-gates.yml`）
- ✅ `bootstrap`：6 gates 已就位（含 foundationx 零命中纯度门禁）
- ⬜ `contracts`：待创建 `scripts/boundary-gates.sh`
- ⬜ `natsx`：待创建
- ⬜ `domain-market/macro/exchange`：待创建（纯度门禁：rg 验证零 infra/binance import）
- ⬜ `transportx`：待创建

## 模板创建命令

```bash
# 以 binance 为模板，逐模块复制并裁剪：
cp /home/binance/scripts/boundary-gates.sh /home/{module}/scripts/
# 编辑 gate 列表，移除不适用项，添加模块专属规则
```
