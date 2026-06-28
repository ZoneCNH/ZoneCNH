# TASK-CMD-002 Config Validation & Error Handling

## Objective

实现配置验证作为管线第一步，所有错误含完整调用链。

## Scope

- `cfg.Validate()` 作为 Run() 第一步
- 无效配置立即返回，不执行后续阶段
- 所有 `fmt.Errorf` wrapping 保留 "cmd: " 前缀

## Covers

- FR-CMD-002 (config validation first)
- BR-CMD-002 (Feed.Connect failure → immediate error)
- NFR-CMD-002 (error wrapping with call chain)

## Deliverables

- Run() 第一步: `if err := cfg.Validate(); err != nil { return fmt.Errorf("cmd: invalid config: %w", err) }`
- Feed.Connect 错误: `return fmt.Errorf("cmd: feed connect failed: %w", err)`
- 所有 error path 保留调用链上下文

## Acceptance Criteria

1. cfg.Validate() 失败 → Run() 返回 error 含 "invalid config"
2. Feed.Connect 失败 → Run() 返回 error 含 "feed connect failed"
3. assembly.Assemble 失败 → Run() 返回 error 含 "assembly failed"
4. 所有 error 可通过 errors.Unwrap 追溯到根因
5. 无效配置时 Feed.Connect 不执行

## Dependencies

- TASK-CMD-001 (Run pipeline)
- `runtime-patches/binancecfg` (Config.Validate)
