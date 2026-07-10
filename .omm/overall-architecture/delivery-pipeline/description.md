Goal 驱动交付体系，docs/goal/ 下 26 篇文档定义 11 阶段统一管线（Goal→Spec→Design→Plan→Tasks→Prompt→Code→Test→Review→Release→Retrospective）和四轴状态模型（pipeline_state / current_phase / phase_status / workflow_step）。

包含 G0-G11 Gate 体系、四源评分（claude/codex/copilot/rules）、boundary gates 门禁、证据协议、Matrix 横切追溯。可执行入口 docs/goal/tools/goal-workflow.sh 提供 preflight/validate/gate/ci/release 五种剖面。独立展开见 delivery-pipeline perspective。
