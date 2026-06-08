# Outer Metrics

> 评分体系的外部锚点。**LLM agent 一律只读**，禁止写入或修改。详见 `CONSTITUTION.md` §14.2。

本目录存放来自真实世界、不可被 LLM 篡改的质量信号，用于检测评分体系是否走向 Goodhart 优化（评分高但实际质量退化）。

---

## 文件结构

```text
.omc/state/outer-metrics/
├── README.md                   # 本文件
├── SCHEMA.md                   # 指标定义与采集来源
├── correlation.json            # scorer 分数 vs outer metric 的相关系数滚动统计
└── {module}.json               # 每个模块的真实质量指标
```

---

## 写入权限

| 来源 | 写入工具 | 写入频率 |
|------|----------|----------|
| CI 流水线（GitHub Actions） | `.github/workflows/outer-metrics.yml` | 每次合并到 main |
| 生产观测（实际事故、性能） | 外部 push（webhook 或定时 sync） | 实时 / 每日 |
| Git 历史统计 | `scripts/outer-metrics-from-git.sh` | 每周 |
| 人类维护者 | 手动编辑 | 按需 |

**严禁来源**：

- ❌ 任何 `*-structural-score` agent
- ❌ `pipeline-arbiter`
- ❌ `spec`、`task-split`、`task-planner`、`prompt-builder`、`task-executor`
- ❌ 任何在 Spec→Code 管线中运行的 agent

宪法 §14.2 强制规定上述 agent 对本目录**只读**。

---

## 用途

1. **Anti-Goodhart 检测**：定期计算 scorer 评分与 outer metric 的相关系数；低于阈值触发宪法 §14.4。
2. **RSI A/B 评判**：宪法 §14.3 RSI 流程中用作"哪一版 rubric 更接近真实质量"的裁判信号。
3. **管线健康报告**：作为 CI 仪表盘的数据源。

---

## 索引

| 文件 | 用途 |
|------|------|
| `SCHEMA.md` | 指标字段定义、采集来源、阈值 |
| `correlation.json` | 滚动相关系数与 Goodhart 信号 |
| `{module}.json` | 单模块真实质量记录 |
