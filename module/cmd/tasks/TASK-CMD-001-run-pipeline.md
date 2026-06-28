# TASK-CMD-001 Run Pipeline

## Objective

实现 `Run()` 可测试入口点，执行 6 阶段管线编排。

## Scope

- `Run()`: validate → assemble → construct → connect → serve → drain
- 所有依赖通过参数注入（ctx, cfg, deps, middlewares...）
- 结构化日志含 component="cmd" 标签

## Covers

- FR-CMD-001 (Run pipeline)
- FR-CMD-003 (assembly injection)
- NFR-CMD-001 (structured logging)

## Deliverables

- `main.go` 中 `Run()` 完整 6 阶段实现
- 每阶段错误用 fmt.Errorf wrapping 保留调用链
- 启动/停止/错误均通过 slog 记录

## Acceptance Criteria

1. Run() 6 阶段有序执行
2. cfg.Validate() 失败 → 返回 "cmd: invalid config: ..." error
3. assembly.Assemble 失败 → 返回 "cmd: assembly failed: ..." error
4. Feed.Connect 失败 → 返回 "cmd: feed connect failed: ..." error
5. 启动日志含 "ingest pipeline started" + endpoint/max_streams
6. 停止日志含 "ingest pipeline stopped"

## Dependencies

- `runtime-patches/binancecfg` (Config)
- `runtime-patches/assembly` (ServerDeps, Assemble)
- `runtime-patches/binance` (NewServer, IngestServer)
