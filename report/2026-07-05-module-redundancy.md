# module/ 多余模块深度分析

> 日期：2026-07-05
> 分支：`docs/module-redundancy-analysis`
> 范围：`module/` 目录与 `module/registry.yaml` 注册表的全量比对
> 方法：只读分析，证据来自当前仓库 `registry.yaml` / `FOUNDATION-DEPS.yaml` / 各模块 `SPEC.md` 实际内容

---

## 一、宏观全景

`module/registry.yaml` 注册 **65 个模块**，目录实存 **67 个**。lifecycle 分布：

| lifecycle  | 数量 |
| ---------- | ---- |
| active     | 27   |
| production | 2    |
| proposed   | 32   |
| archived   | 4    |

逐集群比对 SPEC 摘要、FOUNDATION-DEPS 依赖矩阵与目录归属后，识别出三类"多余"。

---

## 二、确属多余的模块（建议处置）

### A. 4 个 archived 旧引擎 — registry 残留 `[KNOWN]`

| 模块               | 取代者      | 证据                                                             |
| ------------------ | ----------- | ---------------------------------------------------------------- |
| `backtest_engine`  | `backtestx` | registry `lifecycle: archived`，`local_path: None`，目录已不存在 |
| `order_engine`     | `orderx`    | 同上                                                             |
| `portfolio_engine` | `positionx` | 同上                                                             |
| `risk_engine`      | `riskx`     | 同上                                                             |

`[COMPUTED]` 这 4 个条目在 registry 中只保留 `repo` 字段（指向已废弃 GitHub 仓库），无 `local_path`、无 `spec_ref`、无任何被引用记录。属于"宪法 C-1 主干唯一"意义下的历史残骸——保留无害，但若追求 registry 精简，应移入独立 `archived` 段或删除。置信度 `HIGH`。

### B. binance 内部 4 子层被过度拆分为顶层模块 `[INFERRED]`

**这是最实质的冗余。** `binancex` / `binancecfg` / `assembly` / `cmd` 四个模块：

| 证据维度  | 观察                                                                                                         |
| --------- | ------------------------------------------------------------------------------------------------------------ |
| SPEC 状态 | 全部 `Draft（从 patches/{name}/*.go 反向提取）`，v0.1.0                                                      |
| 依赖矩阵  | **均未出现在 `FOUNDATION-DEPS.yaml`**（只有 bootstrap/domainx 等真模块出现）                                 |
| 归属      | layer/domain 与 `binance` 完全一致（business/data）                                                          |
| 消费者    | 仅 `binance` 一处；`binancex` 自述"支持多交易所 adapter 多态"，但 okx/hyperliquid 等 proposed 交易所尚未落地 |
| 职责      | adapter 抽象 / config 加载 / 中间件装配 / 入口 main —— 这是一个模块的**内部架构分层**，不是独立可复用模块    |

`[INFERRED]` 把单一模块的内部架构层（SDK 抽象 / 配置 / 装配 / 入口）提升为顶层注册模块，违反了"模块边界 = 可独立复用单元"的隐含语义。`binance` 自身已是 production（v3.14.0，55 Done），完全可承载这四层作为内部文档。`binancex` 的"多交易所复用"目标是**过早抽象**——等 okx/hyperliquid 真正落地并复用时再独立不迟。置信度 `MED`（取决于未来是否真有多交易所复用）。

处置建议：合并回 `module/binance/` 作为内部架构文档（如 `module/binance/internal-arch/`），从 registry 移除这 4 个条目。

### C. 2 个分类模板目录与 `_template` 重复 `[KNOWN]`

- `data_cs_module/`（含 `SPEC-TEMPLATE.md`、`UPGRADE-ROADMAP.md`）
- `data_independent_process/`（含 `SPEC-TEMPLATE.md`）

`[COMPUTED]` 这两个目录对应 registry 的 `arch_type: cs_module`（7 个）和 `arch_type: independent_process`（28 个）两类架构模板，与已有的 `_template/`、`_exchange-template/` 职责重叠。目录命名是"分类名"而非"模块名"，且未注册。属于模板体系碎片化。置信度 `HIGH`。

处置建议：统一并入 `_template/` 体系（如 `_template/cs_module/`、`_template/independent_process/`）。

---

## 三、看似多余实则不冗余（澄清）

| 集群                                               | 判定       | 依据                                                                                                          |
| -------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------- |
| `market_regime` / `macro_regime` / `regime_engine` | **不冗余** | S 引擎(S1-S7) / M 引擎(M1-M7) / M×S 联合决策引擎，三层分工明确，SPEC 互引                                     |
| `factor_engine` / `feature_store` / `factor_eval`  | **不冗余** | 因子计算 / 特征存储 / IC 评估，职责正交                                                                       |
| `composer` / `maestro`                             | **不冗余** | composer=系统级 25 进程组合根(entry 域)；maestro=决策域业务 DAG 工作流编排                                    |
| `bootstrap` / `composer` / `cmd`                   | **不冗余** | bootstrap=L1 通用进程组装层（被 FOUNDATION-DEPS 引用，active）；composer=系统组合根；cmd=(若保留)binance 入口 |

---

## 四、附带发现：注册缺口（非多余，是漏登记）`[KNOWN]`

`bea` / `eastmoney` / `ecb` / `japan_cb` / `uk_cb` / `yield_curve` 这 6 个目录有完整 goal/spec/matrix 制品，且被 `macro_data/spec/SPEC.md` 显式引用为宏观 adapter（"fred/bea/ecb/treasury/yield_curve/uk_cb/japan_cb/eastmoney/jin10/yahoo 等宏观 adapter"），但**未在 registry 注册**。同类的 `fred`/`treasury`/`yahoo` 却已注册。这是注册不一致，应补登记，而非删除。

---

## 五、处置优先级

| 优先级 | 项                                                        | 动作                                  | 风险                                   |
| ------ | --------------------------------------------------------- | ------------------------------------- | -------------------------------------- |
| P1     | binance 4 子层合并回 binance                              | 移 registry 4 条目 + 文档迁入 binance | 低（proposed/未落地，无 runtime 影响） |
| P2     | data_cs_module / data_independent_process 并入 \_template | 目录合并                              | 极低                                   |
| P3     | 4 archived engines                                        | 移入 archived 段或保留                | 零（仅治理整洁度）                     |
| P3     | 6 个 macro adapter 补登记                                 | registry 加条目                       | 零                                     |

**核心结论**：真正"多余"的是 **binance 的 4 个过度拆分子层**（B 类）——这是唯一具有架构语义冗余的处置项；其余多为治理整洁度问题（A/C 类）和注册缺口（第四节）。

---

## 六、证据复现命令

```bash
# 注册模块数与 lifecycle 分布
python3 -c "
import yaml
d=yaml.safe_load(open('module/registry.yaml'))
mods={k:v for k,v in d.items() if isinstance(v,dict) and 'repo' in v}
from collections import Counter
print('total:', len(mods))
print(Counter(v.get('lifecycle') for v in mods.values()))
"

# 目录 vs registry 差集
python3 -c "
import yaml, os
d=yaml.safe_load(open('module/registry.yaml'))
reg=set(k for k,v in d.items() if isinstance(v,dict) and 'repo' in v)
dirs=set(x for x in os.listdir('module') if os.path.isdir('module/'+x))
print('孤儿目录:', sorted(dirs-reg))
print('registry 残留:', sorted(reg-dirs))
"

# binance 4 子层是否在依赖矩阵
grep -E 'binancex|binancecfg|assembly|cmd' module/FOUNDATION-DEPS.yaml
# 预期：无输出（证实非独立依赖节点）
```

`[RULES I BROKE]：无违反项。本次为只读分析，未编辑任何治理/源码文件；证据均来自当前会话实际执行的命令输出，未引用历史输出；置信度已显式标注。`
