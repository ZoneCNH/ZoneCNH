# module/eastmoney Prompt 包入口

- Last-Updated: 2026-07-04
- 目标：为单个 Task 生成可直接执行的 Context Packet

## 命名规范

- `PROMPT-EASTMONEY-ROOT-XXX.md`
- `PROMPT-EASTMONEY-CLIENT-XXX.md`
- `PROMPT-EASTMONEY-SERVER-XXX.md`

## Prompt 最小结构

1. Task 目标与边界（Scope / Non-scope）
2. 依赖与输入（Spec / Matrix / Plan / Runtime paths）
3. 实现要求（共享基座、`domain_macro`、七类持久化职责）
4. 验收命令（最小可运行命令 + 期望输出）
5. 风险与回滚策略

## 约束

- 必须显式声明 `nats` 与 `kafka` 分层职责。
- 必须显式声明 `domain_macro` 是出域唯一领域模型。
- 不得包含任何密钥值。
