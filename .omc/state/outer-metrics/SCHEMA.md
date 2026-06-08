# Outer Metrics Schema

> 真实世界质量信号的字段定义。所有指标必须可机械采集，禁止 LLM 主观评分。

最后更新：2026-06-08

---

## 1. 单模块指标 `{module}.json`

```json
{
  "module": "kernel",
  "last_updated": "2026-06-08T09:00:00Z",
  "ship_history": [
    {
      "version": "v1.2.0",
      "shipped_at": "2026-05-01T00:00:00Z",
      "spec_sha": "abc123...",
      "pipeline_verdicts": {
        "spec":   { "min_score": 99, "attempts": 1 },
        "matrix": { "min_score": 99, "attempts": 1 },
        "tasks":  { "min_score": 98, "attempts": 2 },
        "plan":   { "min_score": 98, "attempts": 1 },
        "prompt": { "min_score": 100, "attempts": 1 },
        "code":   { "min_score": 99, "attempts": 1 }
      },
      "outer_metrics": {
        "real_bug_count_30d": 3,
        "real_bug_count_90d": 5,
        "rework_commit_count": 2,
        "rework_loc_ratio": 0.12,
        "test_flakiness_7d": 0.02,
        "ci_failure_rate_post_merge_7d": 0.01,
        "production_incident_count": 0,
        "p99_latency_regression_pct": 0.0,
        "security_advisory_count": 0,
        "developer_override_count": 1,
        "rollback_occurred": false
      }
    }
  ]
}
```

### 字段定义

| 字段 | 类型 | 含义 | 采集来源 |
|------|------|------|----------|
| `real_bug_count_30d` | int | 合并后 30 天内归因到本模块的 issue 数 | GitHub Issues 标签 |
| `real_bug_count_90d` | int | 合并后 90 天 | 同上 |
| `rework_commit_count` | int | 合并后回头修改本模块的 commit 数 | `git log` |
| `rework_loc_ratio` | float | rework LOC / 原始 LOC | `git diff --stat` |
| `test_flakiness_7d` | float | 测试 flake 率（重跑通过/总运行） | CI 历史 |
| `ci_failure_rate_post_merge_7d` | float | 合并后 7 天主分支 CI 失败率 | CI |
| `production_incident_count` | int | 涉及本模块的生产事故数 | 外部观测系统 |
| `p99_latency_regression_pct` | float | p99 延迟相对基线退化百分比 | 性能监控 |
| `security_advisory_count` | int | 安全公告数 | Dependabot / SAST |
| `developer_override_count` | int | 维护者绕过管线门禁的次数 | git 注释扫描 |
| `rollback_occurred` | bool | 是否触发回滚 | 部署系统 |

---

## 2. 相关性滚动统计 `correlation.json`

```json
{
  "computed_at": "2026-06-08T09:00:00Z",
  "window": "last_10_modules",
  "by_platform": {
    "claude":  { "correlation": 0.72, "modules_evaluated": 10 },
    "codex":   { "correlation": 0.68, "modules_evaluated": 10 },
    "copilot": { "correlation": 0.71, "modules_evaluated": 10 }
  },
  "by_stage": {
    "spec":   0.65,
    "matrix": 0.81,
    "tasks":  0.78,
    "plan":   0.59,
    "prompt": 0.62,
    "code":   0.84
  },
  "composite_score_vs_real_quality": 0.70,
  "goodhart_signal": false,
  "frozen_components": [],
  "rsi_recommendation": null
}
```

### 字段定义

| 字段 | 含义 |
|------|------|
| `by_platform.{p}.correlation` | scorer 评分与真实质量复合指标的 Spearman 相关系数 |
| `by_stage.{s}` | 每阶段评分与真实质量的相关性 |
| `composite_score_vs_real_quality` | `min(三平台)` 与真实质量的相关系数 |
| `goodhart_signal` | 是否检测到 Goodhart 早期信号（评分上升而质量下降） |
| `frozen_components` | 因相关性 <0.6 被宪法 §14.4 冻结的组件列表 |
| `rsi_recommendation` | 是否建议触发宪法 §14.3 RSI 流程 |

---

## 3. 真实质量复合指标定义

```text
real_quality_index = 100
  - 5 * real_bug_count_30d
  - 3 * rework_commit_count
  - 100 * production_incident_count
  - 50 * (1 if rollback_occurred else 0)
  - 20 * security_advisory_count
  - 50 * test_flakiness_7d * 10
  - 50 * ci_failure_rate_post_merge_7d * 10
  - 30 * developer_override_count
```

数值越高代表实际质量越好。**注意**：本公式本身也是受保护文件（属于评分方法论），修订须走宪法 §14.3 RSI 流程。

---

## 4. Goodhart 检测阈值

| 信号 | 阈值 | 触发动作 |
|------|------|----------|
| 任一平台 correlation < 0.6 | 持续 5 个模块 | 冻结该 platform scorer，触发 §14.3 |
| 任一阶段 by_stage 相关性 < 0.5 | 持续 5 个模块 | 冻结该阶段 rubric，触发 §14.3 |
| 评分均值上升 + real_quality_index 均值下降 | 滑动窗口 5 模块 | `goodhart_signal=true`，触发 §14.3 |

所有阈值由 `scripts/outer-metrics-eval.sh`（待实现）机械计算，不依赖 LLM 判断。

---

## 5. 采集脚本契约（待实现）

| 脚本 | 用途 | 触发 |
|------|------|------|
| `.github/workflows/outer-metrics.yml` | 合并后采集 CI/git 指标，写入 `{module}.json` | push to main |
| `scripts/outer-metrics-from-git.sh` | 计算 rework / 历史指标 | 每周 cron |
| `scripts/outer-metrics-eval.sh` | 计算相关系数并写 `correlation.json` | 每日 cron |
| `scripts/outer-metrics-validate.sh` | 校验 schema，拒绝非授权写入源 | CI 检查 |

脚本未实现前，可手动按 schema 维护 `{module}.json` 作为种子数据，但**禁止由 LLM agent 生成**。
