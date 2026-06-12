# TASK-KERNEL-015 开发 Prompt

> 上游 Task：[TASK-KERNEL-015.md](./tasks/TASK-KERNEL-015.md)
> examples/：12 子包可运行示例程序

---

## 任务

创建 `kernel/examples/` 目录下 12 个子包对应的可运行示例程序。每个示例独立可运行，输出稳定（无随机值），用于 CI golden 对比和用户快速开始。

## 文件清单

12 个示例目录，每个包含 `main.go`：

| 目录 | 对应子包 | 展示内容 |
|------|---------|----------|
| `examples/lifecycle/` | lifecycx | Component 注册、启动、停止 |
| `examples/error_kind/` | errx | Error 构造、IsKind 分类 |
| `examples/health_checker/` | healthx | HealthChecker 实现、Aggregate |
| `examples/observability/` | obsx | NoopLogger 注入、SecretString |
| `examples/retry_policy/` | retryx | RetryPolicy 配置、Delay 计算 |
| `examples/shutdown/` | shutdownx | Hook 注册、OS signal 处理 |
| `examples/sync_group/` | syncx | SemaphoreLimiter、WorkerGroup |
| `examples/clock/` | timex | FakeClock 注入测试 |
| `examples/validation/` | validx | Precondition/Invariant 使用 |
| `examples/version_info/` | versionx | BuildInfo、Compatibility |
| `examples/context/` | contextx | Key 创建、类型安全存取 |
| `examples/contract_helper/` | contracttest | 断言函数使用 |

## 验收标准

| AC | 关联 | 验证命令 | 预期结果 |
|----|------|----------|----------|
| AC-EXAMPLES-01 | §22 | `for d in examples/*/; do go run ./$d; done` | 全部通过 |
| AC-EXAMPLES-02 | §22 | 输出稳定性 | 无随机值 |

## 禁止事项

- 不要在示例中使用真实的 API key 或凭证
- 不要输出随机值或时间戳（使用 FixedClock）
- 不要依赖 L1 模块（configx/observex 等）

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-015/`：
1. 12 个示例 `go run` 输出
2. 输出稳定性验证

## 验证命令

| 命令 | 判定标准 |
|------|----------|
| `go vet ./...` | 无警告 |
| `for d in examples/*/; do go run ./$d; done` | 全部 12 个示例通过 |

## 完成后

1. 循环运行所有 12 个示例确认通过
2. 验证输出可被 golden 测试消费
3. 更新 TASK-KERNEL-015 状态为 completed
