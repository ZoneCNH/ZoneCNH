Goal 驱动交付体系，docs/goal/ 下 26 篇文档定义的核心交付管线。主线是 11 阶段流程 Goal→Spec→Design→Plan→Tasks→Code→Test→Review→Release→Retrospective（Prompt 是 Code 前的指令模板层），每阶段回答一个核心问题。

横切机制：Matrix 追溯矩阵贯穿全链路（Goal→Spec→AC→Task→Prompt→Code→Test→Evidence）、G0-G11 共 12 个 Gate 把关每阶段、四源评分（claude/codex/copilot/rules）为 Gate 提供 composite_score、四轴状态机（pipeline_state/current_phase/phase_status/workflow_step）追踪进度、证据协议保证每个 AC 有结构化证据。
