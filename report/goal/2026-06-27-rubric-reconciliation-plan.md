# Rubric 与模块实践 Reconciliation 计划

> 生成日期：2026-06-27
> 数据来源：`docs/governance/scoring/rubric-score.py spec` 对 55 个模块 SPEC.md 的机器评分
> 方法：维度分数 + 红线触发原因 + 缺失章节统计

---

## 一、现状概览

| 维度分数区间     | 模块数 | 占比 | 说明                                      |
| ---------------- | ------ | ---- | ----------------------------------------- |
| ≥ 90（接近通过） | 2      | 4%   | binance(100)、xlib_standard(96)           |
| 80-89（小缺口）  | 20     | 36%  | 缺 Metadata + Open Questions              |
| 60-79（中缺口）  | 14     | 25%  | 缺 Metadata + Open Questions + 部分 FR/BR |
| < 60（大缺口）   | 19     | 35%  | 缺 10+ 章节                               |

**红线触发分布**：

| 红线                            | 触发次数 | 说明                                     |
| ------------------------------- | -------- | ---------------------------------------- |
| 23 节缺失或空壳                 | 50/55    | 最普遍，主要缺 Metadata + Open Questions |
| Metadata 关键字段缺失           | 49/55    | Owner、Repository 字段                   |
| FR 缺 WHEN/THEN 或 AC/TC 映射   | 33/55    | FR 格式不规范                            |
| Non-goals < 3 或 Edge Cases < 5 | 21/55    | 范围边界不清                             |

> [COMPUTED, HIGH] 50/55 模块因红线触发导致 `composite_score=0`，即使维度分数可能高达 89。这是 rubric 的正确行为（红线 → 零分），不是 false negative。

---

## 二、分层修复策略

### Tier 0：已通过（无需修复）

| 模块          | 维度分 | Composite | 状态                                    |
| ------------- | ------ | --------- | --------------------------------------- |
| binance       | 100    | 100       | ✅ PASS                                 |
| xlib_standard | 96     | 0         | ⚠️ 红线触发（Metadata），维度分接近通过 |

### Tier 1：快速修复（补 Metadata + Open Questions → 可达 ≥90）

**范围**：维度分 ≥ 80 且仅缺 Metadata 和/或 Open Questions 的 20 个模块。

**修复内容**：

1. 在 SPEC.md 头部添加 `## 1. Metadata` 章节，包含 Owner、Repository、Status、Spec-Version、Last-Updated
2. 在 SPEC.md 末尾添加 `## 23. Open Questions` 章节（即使为空也标注 "当前无开放问题"）

**模块清单**：

| 模块            | 维度分 | 缺失章节                               |
| --------------- | ------ | -------------------------------------- |
| domainx         | 89     | Metadata, Open Questions               |
| kafkax          | 89     | Metadata, Open Questions               |
| observex        | 89     | Metadata, Open Questions               |
| schedulex       | 89     | Metadata, Open Questions               |
| clickhousex     | 87     | Metadata, Open Questions               |
| kernel          | 87     | Metadata, Open Questions               |
| natsx           | 85     | Metadata, Open Questions               |
| transportx      | 85     | Metadata, Open Questions               |
| redisx          | 84     | Metadata, Dependencies, Open Questions |
| coinglass       | 83     | —                                      |
| hyperliquid     | 83     | —                                      |
| okx             | 82     | —                                      |
| postgresx       | 82     | Metadata, Open Questions               |
| resiliencx      | 81     | Metadata, Open Questions               |
| testkitx        | 81     | Metadata, Open Questions               |
| xlib_harness    | 81     | Metadata, Open Questions               |
| decimalx        | 80     | Metadata, Open Questions               |
| domain_exchange | 80     | Metadata, Open Questions               |
| domain_macro    | 80     | Metadata, Open Questions               |
| domain_market   | 80     | Metadata, Open Questions               |

**预计工作量**：每个模块 ~15 分钟，总计 ~5 小时。

### Tier 2：中等修复（补 FR/BR 格式 + Non-goals → 可达 ≥80）

**范围**：维度分 60-79 的 14 个模块。

**修复内容**：

1. Tier 1 全部修复
2. FR 改为 WHEN/THEN 格式
3. BR 补违反后果
4. Non-goals 补充至 ≥ 3 条
5. Edge Cases 补充至 ≥ 5 条

**模块清单**：

| 模块           | 维度分 | 主要缺口                                                                       |
| -------------- | ------ | ------------------------------------------------------------------------------ |
| xlib_evidence  | 75     | Metadata, Open Questions                                                       |
| configx        | 74     | Metadata, Open Questions                                                       |
| contracts      | 74     | Open Questions                                                                 |
| backtestx      | 72     | Metadata, Open Questions                                                       |
| flowx          | 72     | Metadata, Open Questions                                                       |
| maestro        | 72     | Metadata, Open Questions                                                       |
| orderx         | 72     | Metadata, Open Questions                                                       |
| positionx      | 72     | Metadata, Open Questions                                                       |
| riskx          | 72     | Metadata, Open Questions                                                       |
| strategyx      | 72     | Metadata, Open Questions                                                       |
| factor_engine  | 64     | Metadata, Goals, Non-goals, Open Questions                                     |
| fred           | 63     | Metadata, Interface Contract, Data Model                                       |
| taosx          | 63     | Metadata, Interface Contract, Data Model, Error Handling, Upgrade, Release DoD |
| signal_factory | 62     | Metadata, Data Model, Config, Security, Upgrade, Open Questions                |

**预计工作量**：每个模块 ~1 小时，总计 ~14 小时。

### Tier 3：深度修复（需补 10+ 章节）

**范围**：维度分 < 60 的 19 个模块。

**修复内容**：

1. Tier 2 全部修复
2. 补充缺失的 10+ 章节（Problem, Consumers, Interface Contract, Data Model, Config Schema, Error Handling, Edge Cases, Directory Structure, Dependencies, Testing, Performance Budget, Observability, Security, CI Gate, Upgrade Compatibility, Release DoD）

**模块清单**（按维度分排序）：

| 模块             | 维度分 | 缺失章节数 |
| ---------------- | ------ | ---------- |
| regime_engine    | 51     | 8          |
| alertx           | 38     | 22         |
| ossx             | 38     | 14         |
| feature_store    | 36     | 15         |
| xlibgate         | 35     | 20         |
| optimizer        | 34     | 17         |
| alternative_data | 28     | 22         |
| composer         | 28     | 22         |
| treasury         | 28     | 22         |
| x.go             | 28     | 22         |
| factor_eval      | 27     | 18         |
| market_data      | 27     | 20         |
| pe_data          | 27     | 18         |
| ms_brain         | 25     | 20         |
| market_regime    | 24     | 20         |
| macro_data       | 23     | 20         |
| bootstrap        | 18     | 23         |
| macro_regime     | 17     | 20         |
| settlement       | 17     | 20         |

**预计工作量**：每个模块 ~3-5 小时，总计 ~60-95 小时。

---

## 三、执行原则

1. **先迁移后修复**：模块先从平铺结构迁移到嵌套结构（`SPEC.md` → `spec/SPEC.md`），再做内容修复，避免路径二次调整。
2. **批量机械化优先**：Tier 1 的 Metadata + Open Questions 是机械化操作，可批量执行。
3. **按活跃度排序**：优先修复有 CI 运行态或近期开发的模块（schedulex、natsx、redisx 等），其次修复架构关键模块（kernel、resiliencx）。
4. **红线优先于维度分**：即使维度分 89，红线触发就是 0 分。修复红线（Metadata + Open Questions）是性价比最高的操作。
5. **禁止降低 rubric 标准**：如果模块确实不适用某章节，在 SPEC.md 中标注 "N/A — 原因说明" 而非删除章节，让 rubric 能识别为非空壳。

---

## 四、验收标准

- [ ] Tier 1（20 模块）composite_score ≥ 90（补齐 Metadata + Open Questions 后红线清除）
- [ ] Tier 2（14 模块）composite_score ≥ 80
- [ ] Tier 3（19 模块）composite_score ≥ 60 或标注为 "spec 重写中" 暂停状态
- [ ] CI gate `four-source-check.sh` 对所有已迁移模块无报错
- [ ] `rubric-score.py spec` 对 Tier 1 模块全部 PASS

---

## 五、验证命令

```bash
# 批量评分所有模块
python3 -c "
import subprocess, glob, re
for p in sorted(glob.glob('module/*/SPEC.md') + glob.glob('module/*/spec/SPEC.md')):
    r = subprocess.run(['python3', 'docs/governance/scoring/rubric-score.py', 'spec', p], capture_output=True, text=True)
    m = re.search(r'composite_score: (\d+)/100', r.stdout)
    d = re.search(r'维度评分 \((\d+)/100\)', r.stdout)
    mod = p.split('/')[1]
    print(f'{mod:<20} dim={d.group(1) if d else \"?\":>3}  composite={m.group(1) if m else \"?\":>3}')
"
```

---

_计划生成时间：2026-06-27_
_数据来源：rubric-score.py spec 对 55 个模块的机器评分_
