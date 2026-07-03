# module/fred Evidence 目录规范

- Last-Updated: 2026-07-03
- 作用：承载 S8-S11 的可审计证据，不作为规范权威源

## 目录结构

```text
evidence/
  YYYY-MM-DD/
    test/
    review/
    release/
    retrospective/
```

## 证据清单建议

| 子目录 | 最小证据 |
| --- | --- |
| `test/` | 关键测试命令输出、覆盖率、失败注入结果 |
| `review/` | 代码审查与边界审查结论 |
| `release/` | 发布门禁结果、版本与变更摘要 |
| `retrospective/` | 风险复盘与后续任务 |

## 规则

1. 证据必须可追溯到 FR/AC/TC 编号。
2. 证据可以失败，但不得伪造通过。
3. 证据文件中不得出现任何明文 secret。
