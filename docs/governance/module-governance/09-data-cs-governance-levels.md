# 数据 C/S 模块治理等级

- Module-Version: v1.0.0
- Last-Updated: 2026-06-27
- Scope: `module/data_cs_module/` 覆盖的行情与宏观数据 C/S 模块
- Authority: [`MODULE-GOVERNANCE.md`](../MODULE-GOVERNANCE.md) 的操作性覆盖专题

## §1 定位

`[COMPUTED, HIGH]` 本专题把数据 C/S 模块划分为 L1 / L2 / L3 三个治理等级，用于避免把原型模块、新建活跃模块和生产模块混用同一验收标准。

`[COMPUTED, HIGH]` 等级只描述治理与证据成熟度，不替代 `module/registry.yaml` 的生命周期字段，也不替代模块自身 `spec/SPEC.md` 的 `Spec-Version`。

## §2 等级定义

| 等级 | 名称 | 适用阶段 | 最低交付物 | 生产证据要求 |
| --- | --- | --- | --- | --- |
| L1 | Prototype | 新数据源调研、接口边界确认、最小规格草案 | `goal/goal.md`、`spec/SPEC.md` 骨架、边界声明、命名方案 | 不要求 |
| L2 | Active | 已纳入开发计划、需要代码与测试闭环 | L1 + traceability/matrix、boundary gates、plan/tasks/prompt、runtime 编译与本地测试证据 | 不要求 live production evidence；必须明确 Evidence-Pending |
| L3 | Production | 准备发布或已承担生产采集职责 | L2 + PRG 全 PASS、`live_integration >= 15`、外部依赖 E2E、soak/release/evidence bundle | 要求，且必须归档可复核证据 |

## §3 L1 Prototype

### §3.1 准入条件【硬】

1. 模块名符合 snake_case 与数据源命名规则。
2. `spec/SPEC.md` 至少说明数据源边界、client/server 切分、non-goals、下游交付对象。
3. 不声明生产就绪，不声明 Evidence-Done。

### §3.2 可接受缺口【软】

- 可没有 runtime 仓。
- 可没有完整追溯矩阵。
- 可没有 live/testnet/production 证据。

## §4 L2 Active

### §4.1 准入条件【硬】

1. `spec/SPEC.md`、`matrix/TRACEABILITY.md`、`gate/BOUNDARY-GATES.md`、`gate/RULES.md` 存在。
2. runtime 仓至少可编译，并有目标测试或 smoke 验证证据。
3. Code-State 与 Evidence-State 分开记录；未拿到 live 或生产证据时，必须保留 Evidence-Pending。
4. boundary gates 的文档声明与 runtime `scripts/boundary-gates.sh` 的实际 gate 编号保持一致。

### §4.2 禁止项【硬】

- 禁止用本地 mock 证据关闭 live/mainnet/production 验收。
- 禁止把 Code-Done 直接等价为 Evidence-Done。
- 禁止在 runtime 仓 `module/` 目录放置 ADR/SPEC/TRACEABILITY/goal 等 spec 制品。

## §5 L3 Production

### §5.1 准入条件【硬】

1. L2 全部条件已满足。
2. PRG 或等价 production readiness gate 全部 PASS。
3. `live_integration >= 15`，且覆盖目标产品线、外部依赖和关键失败路径。
4. 外部 E2E、soak、release、rollback 或恢复演练证据已归档到 `module/{module}/evidence/YYYY-MM-DD/`。
5. 证据必须可复核、脱敏、带命令或 CI run 引用。

### §5.2 L3 降级条件【硬】

任一条件成立时，模块应从 L3 降级为 L2 或标记为 L3-blocked：

1. 生产证据过期且无法复核。
2. live integration 或外部依赖覆盖率低于模块声明阈值。
3. runtime 与 spec 出现 Code-Drifted 且未有关闭计划。
4. 关键凭证、CI、dashboard、告警或恢复演练证据缺失。

## §6 当前参考状态

| 模块 | 当前等级 | 依据 |
| --- | --- | --- |
| binance | L2 -> L3 candidate | `[COMPUTED, HIGH]` 规格与 runtime anchor 已能证明多项 Code-Partial/Code-Done，但 live/CI/dashboard/credentials/multi-tenant/destruction 等 Evidence-Pending 尚未闭合 |
| okx / bybit / bitget / kucoin / gate / mexc / htx / coinbase / hyperliquid / lighter / upbit / coinglass | L1 起步 | `[INFERRED, MED]` 应先复用 data_cs_module 模板建立边界、命名和 spec 骨架，再按证据推进 L2/L3 |
| fred / treasury / yield_curve / bea / ecb / uk_cb / japan_cb / eastmoney / jin10 / yahoo | L1 起步 | `[INFERRED, MED]` 宏观数据源同样适用 C/S 模块分层，但具体 live 证据门禁需按数据源能力调整 |

## §7 升级流程

1. L1 -> L2：完成 spec、matrix、boundary gates、runtime 编译/测试证据，并在 `todo.md` 或模块等价账本中分离 Code-State / Evidence-State。
2. L2 -> L3：补齐 PRG、外部 E2E、live integration、soak/release、rollback/recovery evidence，并由 reviewer 确认可复核。
3. L3 -> L2：当生产证据失效或关键运行证据缺失时，保留代码状态，降级证据状态。

## §8 与 issue 关闭的关系

`[COMPUTED, HIGH]` issue 关闭必须跟随等级证据，而不是跟随文档存在性。L2 可以关闭纯文档/模板/治理缺口 issue；涉及 live、production、external E2E、soak、rollback、destruction、multi-tenant isolation 的 issue 只能在 L3 证据归档后关闭。
