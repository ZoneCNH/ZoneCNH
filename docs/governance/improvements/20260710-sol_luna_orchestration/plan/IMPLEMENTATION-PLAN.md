# Sol/Luna 编排实现计划

1. `[COMPUTED, HIGH]` 在 main HEAD 上创建 `feat/sol_luna_orchestration` 隔离 worktree，并登记/认领 Beads `ZoneCNH-3qyb`。
2. `[COMPUTED, HIGH]` 读取宪法 §14、§19、§20，确认保护路径与证据规则。
3. `[COMPUTED, HIGH]` Sol 深度拆分为 TASK-001–TASK-003，并用三个显式 Luna/xhigh 外部进程处理互斥写范围。
4. `[COMPUTED, HIGH]` 运行 unit、py_compile、probe、diff cheap gates；把明确缺陷退回 Luna 修复。
5. `[FRAME, HIGH]` 用隔离 synthetic feature worktree 运行一次真实端到端 smoke，验证 Sol + 3 Luna + integration combined patch。
6. `[FRAME, HIGH]` 更新 Evidence、Beads、commit、push 与 PR 状态；不得直接在本地 main 编辑。

[FRAME, HIGH] 任一步出现明确机械失败时先修复并重跑；只有证据缺失、冲突、范围重叠或重试耗尽才升级 Sol。
