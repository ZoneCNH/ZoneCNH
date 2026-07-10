# TASK-003：配置、文档与 CRI 追溯

- **目标**：`[FRAME, HIGH]` 固化 Sol 默认模型、并发边界、运行入口和治理边界。
- **写范围**：`.codex/config.toml`、`AGENTS.md`、`docs/workflow/README.md`、本改进目录 `[FRAME, HIGH]`
- **依赖**：TASK-001 的最终 CLI 契约 `[FRAME, HIGH]`
- **覆盖**：FR-001、AC-001、AC-006、AC-008 `[FRAME, HIGH]`

## 验收

- `[FRAME, HIGH]` strict config 能加载项目默认 `gpt-5.6-sol`。
- `[FRAME, HIGH]` 文档不把 collaboration 名称、配置上限或 catalog 可用性偷换为实际 Luna 执行证据。
- `[FRAME, HIGH]` 保护文件清单保持无改动。
