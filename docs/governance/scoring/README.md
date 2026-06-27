# 评分协议索引

`docs/governance/scoring/` 保存结构性评分 rubric、仲裁协议和评分 JSON schema。

## 仲裁与 Schema

| 文件                                       | 用途                    |
| ------------------------------------------ | ----------------------- |
| [ARBITER-PROTOCOL.md](ARBITER-PROTOCOL.md) | 四源评分仲裁规则        |
| [score.schema.json](score.schema.json)     | scorer 输出 JSON schema |
| [rubric-score.py](rubric-score.py)         | Spec rubric 自动评分器（8 维度 + 6 条红线，纯 Python stdlib） |

## Rubric

| 阶段          | Rubric                                             |
| ------------- | -------------------------------------------------- |
| Spec          | [RUBRIC-spec.md](RUBRIC-spec.md)                   |
| Matrix        | [RUBRIC-matrix.md](RUBRIC-matrix.md)               |
| Design        | [RUBRIC-design.md](RUBRIC-design.md)               |
| Tasks         | [RUBRIC-tasks.md](RUBRIC-tasks.md)                 |
| Plan          | [RUBRIC-plan.md](RUBRIC-plan.md)                   |
| Prompt        | [RUBRIC-prompt.md](RUBRIC-prompt.md)               |
| Code          | [RUBRIC-code.md](RUBRIC-code.md)                   |
| Test          | [RUBRIC-test.md](RUBRIC-test.md)                   |
| Review        | [RUBRIC-review.md](RUBRIC-review.md)               |
| Release       | [RUBRIC-release.md](RUBRIC-release.md)             |
| Retrospective | [RUBRIC-retrospective.md](RUBRIC-retrospective.md) |

`STRUCTURAL-SCORING.md` 定义当前 Spec -> Code 管线的主门禁；本目录中 Design、Test、Review、Release、Retrospective rubric 用于 Goal 管线和扩展阶段评分。
