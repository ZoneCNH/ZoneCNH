本管线是 goal 交付 OS（governance-hierarchy 三层栈的最底层）。与模块治理八域互补：Gate（G0-G11）管单次交付流程的通过/失败，模块健康度管跨多次交付的累积状态。

状态机 SSOT 在 docs/goal/03-pipeline.md §2：四轴状态边界严格——pipeline_state（全局位置）、current_phase（当前层级 GOAL/SPEC/.../RETROSPECTIVE）、phase_status（局部进度 NOT_STARTED/IN_PROGRESS/.../DONE/BLOCKED）、workflow_step（SOP/CI 执行剖面）。Registry/Glossary/Runtime/Gate/脚本校验不得定义本地新增状态，只能引用 §2 枚举。

Gate verdict（PASS/PASS_WITH_RISK/FAIL/BLOCKED）与 phase_status 是两条独立状态轴。WAIVED 是豁免策略不是 Gate 结果值，须映射为 PASS_WITH_RISK 或 BLOCKED。
