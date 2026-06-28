# TASK-CMD-003 Signal Handling & Graceful Shutdown

## Objective

实现 OS 信号处理与优雅关闭管线。

## Scope

- SIGINT/SIGTERM → graceful shutdown
- context cancellation → shutdown
- Feed.Errors() 非 nil error → shutdown
- DrainTimeout 强制返回

## Covers

- FR-CMD-004 (signal handling)
- FR-CMD-005 (graceful shutdown)
- BR-CMD-003 (Feed.Errors trigger shutdown)
- BR-CMD-004 (ShutdownTimeout enforcement)

## Deliverables

- `signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)`
- 3-way select: sigCh / ctx.Done() / Feed.Errors()
- DrainTimeout via `context.WithTimeout`
- defer Feed.Close() 确保资源释放

## Acceptance Criteria

1. SIGINT → "received signal, shutting down" log + cancel + drain
2. SIGTERM → 同上
3. ctx.Done() → "context cancelled, shutting down" log
4. Feed.Errors() 非 nil → "feed error, shutting down" log + err
5. DrainTimeout 到期 → 强制返回（不无限等待）
6. Feed.Close() 在 defer 中执行（即使 drain 失败）

## Dependencies

- TASK-CMD-001 (Run pipeline)
- `runtime-patches/binancecfg` (ShutdownTimeout)
