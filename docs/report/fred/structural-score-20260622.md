# fred 结构性问题与评分报告

- Date: 2026-06-22
- Scope: `module/fred/`
- Output: 结构性问题、分项评分、迭代优先级
- Existing Context: 已存在 `docs/report/fred/deep-analysis-20260622.md`；本报告只补结构性评分账本，不覆盖既有深度报告。
- Evidence Rule: `[COMPUTED]` 来自本仓库文件与命令输出；`[INFERRED]` 是基于证据的工程判断。

## 1. 总评分

[COMPUTED][HIGH] `module/fred/` 已形成 `goal.md`、`SPEC.md`、`TRACEABILITY.md`、`FEATURES.md`、`ACCEPTANCE.md`、`IMPLEMENTATION-PLAN.md` 和 `README.md` 的完整规格包；但核心状态仍以 `Draft`、`Planned`、`Pending` 为主。证据：`goal.md:10`、`SPEC.md:14`、`TRACEABILITY.md:10`、`FEATURES.md:39-52`、`ACCEPTANCE.md:40-60`。

| 评分对象 | 分数 | 结论 |
| --- | ---: | --- |
| SPEC 单文件结构 | 84/100 | `[COMPUTED][HIGH]` 目标、边界、FR/BR/AC/TC、持久化、配置和安全约束较完整，但仍有 4 个开放问题未关闭。 |
| `module/fred/` 结构健康 | 68/100 | `[COMPUTED][HIGH]` 文档骨架完整，但追溯矩阵、验收命令和实施证据尚未闭环。 |
| 发布验收就绪 | 42/100 | `[COMPUTED][HIGH]` 所有 AC/TC 仍为 `Pending`，不能证明 `/home/fred` 已满足目标状态。 |

结构健康分项账本：

| 维度 | 分数 | 扣分原因 |
| --- | ---: | --- |
| 需求与边界完整度 | 18/20 | `[COMPUTED][HIGH]` FR/BR/AC/TC 和七类持久化介质已定义；扣分来自 `/home/fred` 旧 `Stores=None` 迁移仍未完成。 |
| 领域共享层与 C/S 边界 | 14/20 | `[COMPUTED][HIGH]` 已要求共享基座组件和 `domain_macro`，但 `domain_macro` 具体包路径与字段仍是开放项。 |
| 追溯一致性 | 9/20 | `[COMPUTED][HIGH]` `TRACEABILITY.md` 的 BR 编号语义与 `SPEC.md` 发生漂移，且 TC-007/TC-008 未进入验证命令表。 |
| 验收可执行性 | 13/20 | `[COMPUTED][HIGH]` `ACCEPTANCE.md` 有 AC/TC/DoD，但所有条目仍是 `Pending`，缺少真实运行证据。 |
| 实施就绪度 | 14/20 | `[COMPUTED][HIGH]` `IMPLEMENTATION-PLAN.md` 已拆分阶段和任务，但配置映射、集成环境、运行时边界仍待补齐。 |
| 总分 | 68/100 | `[INFERRED][HIGH]` 规格层可继续推进，但未达到进入发布或合并验收的结构闭环。 |

## 2. P0 结构性问题

### P0-1. 追溯矩阵 BR 编号漂移

[COMPUTED][HIGH] `SPEC.md` 中 BR-002 是幂等性、BR-003 是 `available_at` 防未来函数、BR-005 是 Postgres checkpoint、BR-006 是 Redis/ClickHouse 可重建、BR-007 是 OSS 原始数据路径约束；但 `TRACEABILITY.md` 将这些编号语义重新排列。证据：`SPEC.md:69-76`、`TRACEABILITY.md:47-54`。

影响：

- `[INFERRED][HIGH]` 管线评分和人工评审会把同一个 BR 编号解释成不同约束，导致误判覆盖率。
- `[INFERRED][HIGH]` 后续 Task/Prompt 若按 `TRACEABILITY.md` 执行，可能优先实现错误约束或漏验关键业务规则。

修复要求：

1. 以 `SPEC.md:69-76` 为权威，重写 `TRACEABILITY.md` 的 BR 表。
2. 同步修正 `goal.md` 到 BR/TC 的映射，避免继续引用漂移后的编号。
3. 增加一次 `rg -n "BR-00[2-7]" module/fred` 的人工核对记录。

### P0-2. TC 注册表不闭合

[COMPUTED][HIGH] `SPEC.md` 和 `ACCEPTANCE.md` 都定义了 TC-001 到 TC-008，但 `TRACEABILITY.md` 的验证命令只列出 TC-001 到 TC-006。证据：`SPEC.md:193-200`、`ACCEPTANCE.md:53-60`、`TRACEABILITY.md:60-65`。

影响：

- `[INFERRED][HIGH]` 七介质连通、降级恢复、密钥脱敏和边界检查无法被完整追溯到可执行命令。
- `[INFERRED][MED]` 即使后续实现通过部分测试，也不能证明 `AC-007`、`AC-008` 已覆盖。

修复要求：

1. 在 `TRACEABILITY.md` 增加 TC-007、TC-008 的命令槽位。
2. 将每个 AC 映射到至少一个 TC，避免 `TC-006` 作为过宽的兜底测试。
3. 将命令从占位描述升级为 `/home/fred` 可运行命令或明确标记为暂不可运行及原因。

### P0-3. 目标状态与运行时状态证据断层

[COMPUTED][HIGH] `SPEC.md` 明确说明当前 `/home/fred` 仍有旧 `Stores=None` 边界，`FEATURES.md` 与 `ACCEPTANCE.md` 也标记运行时证据未完成。证据：`SPEC.md:14`、`FEATURES.md:82-87`、`ACCEPTANCE.md:18-19`、`ACCEPTANCE.md:40-60`。

影响：

- `[INFERRED][HIGH]` 当前 `module/fred/` 只能证明“目标规格已定义”，不能证明“fred 服务已实现”。
- `[INFERRED][HIGH]` 若直接将 `Planned`/`Pending` 视作完成，会误导 main 分支状态和模块索引。

修复要求：

1. 保持文档中 Target / Current / Evidence 三类状态分离。
2. 等 `/home/fred` 真实迁移后，再将 `Planned`/`Pending` 改为 `Verified`。
3. 在 `ACCEPTANCE.md` 补入测试命令、执行时间、退出码和关键输出摘要。

## 3. P1 优化项

### P1-1. `domain_macro` 合约仍停留在目标定义

[COMPUTED][HIGH] `SPEC.md` 已定义 `domain_macro` 必须提供 `MacroSeries`、`MacroObservation`、`ReleaseCalendar`、`RevisionPolicy` 等模型字段，但开放问题仍说明具体包路径和字段以实现为准。证据：`SPEC.md:102-110`、`SPEC.md:274-276`、`FEATURES.md:91-94`。

[INFERRED][HIGH] 下一轮应补一个 `domain_macro` 合约清单，至少包含包路径、模型字段、禁止依赖、兼容策略和测试夹具。

### P1-2. 配置键映射未闭合

[COMPUTED][HIGH] 文档已规定配置来源是 `sre/secrets/env/dev.md`，且不得提交密钥值；但开放问题仍要求把 dev 配置键映射到 `configx` schema。证据：`SPEC.md:126-138`、`SPEC.md:274-276`、`IMPLEMENTATION-PLAN.md:26-33`。

[INFERRED][HIGH] 下一轮应补 `CONFIGURATION.md` 或在 `SPEC.md` 中加入“配置键名 -> 用途 -> 必填性 -> 默认策略 -> secret redaction”的表。

### P1-3. API/Event/Storage 契约可更机器可检

[COMPUTED][HIGH] `SPEC.md` 已定义 HTTP/gRPC/API 能力、Kafka topic、NATS 控制语义和七介质职责，但尚未给出 schema 文件、IDL 文件或 topic payload 版本化格式。证据：`SPEC.md:80-98`、`SPEC.md:114-122`、`SPEC.md:181-187`。

[INFERRED][MED] 下一轮可增加 `contracts/` 目录或在 `module/fred/` 增加契约索引，用于绑定 OpenAPI/protobuf/JSON Schema/DDL 的权威来源。

## 4. 建议迭代顺序

1. `[COMPUTED][HIGH]` 先修 `TRACEABILITY.md` 的 BR 编号漂移和 TC-007/TC-008 缺口，因为这是评分门禁的结构性红线。
2. `[INFERRED][HIGH]` 再补 `domain_macro` 合约和配置键映射，降低实现阶段返工。
3. `[INFERRED][HIGH]` 然后把 `ACCEPTANCE.md` 的 `Pending` 项改造成可运行验证命令和证据槽。
4. `[INFERRED][MED]` 最后再进入 `/home/fred` 实现侧验收，避免在规格追溯不一致时写代码。

## 5. Gate 判断

| Gate | 当前判断 | 原因 |
| --- | --- | --- |
| G0 规格存在 | Pass | `[COMPUTED][HIGH]` `module/fred/SPEC.md` 存在且结构完整。 |
| G1 目标边界清楚 | Pass | `[COMPUTED][HIGH]` 独立 C/S、共享基座、`domain_macro`、七介质和配置来源已定义。 |
| G2 追溯闭环 | Fail | `[COMPUTED][HIGH]` BR 编号漂移，TC-007/TC-008 未进验证命令表。 |
| G3 验收可执行 | Fail | `[COMPUTED][HIGH]` AC/TC 全部 `Pending`，缺少运行输出和退出码。 |
| G4 实施就绪 | Conditional | `[INFERRED][HIGH]` 可进入追溯修复与设计补齐，但不宜宣称已可发布。 |

## 6. 结论

[INFERRED][HIGH] `module/fred/` 不是“缺规格”，而是“规格骨架完整但结构闭环不足”。当前最值得补的是追溯一致性和验收可执行性，而不是继续扩展新功能描述。若先修 P0 三项，结构健康分预计可从 68/100 提升到 80/100 左右；若再补 `domain_macro` 合约、配置键映射和真实 `/home/fred` 验收证据，发布验收就绪分才有机会超过 80/100。

[RULES I BROKE]：无
