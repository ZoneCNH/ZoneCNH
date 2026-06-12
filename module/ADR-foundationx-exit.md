# ADR: foundationx Compatibility Exit

> 状态：Proposed
> 日期：2026-06-07
> 决策者：ZoneCNH
> 关联：`FOUNDATION-V1.md` Issue 4

## 背景

Foundation 模块早期以 `foundationx` 作为共享基础包，包含 `SecretString`、`ErrorKind`、`HealthStatus` 等通用类型。随着 Foundation 架构收敛，`kernel` 已成为 L0 原语底座，`foundationx` 的角色应被替代。

当前依赖状态：

| 模块       | foundationx 版本 | 依赖方式                              | 说明                          |
| ---------- | ---------------- | ------------------------------------- | ----------------------------- |
| `configx`  | v0.0.0           | 本地 replace `./internal/foundationx` | 用于 SecretString 等类型      |
| `observex` | v0.1.0           | 远程依赖                              | 用于 ErrorKind / HealthStatus |

## 决策

1. `foundationx` 兼容性是**过渡性的**，不是长期依赖
2. 新的 L0 原语必须放在 `kernel`
3. `configx` 和 `observex` 必须将依赖迁移到 `kernel` 或本地显式契约
4. 迁移完成后，移除 `foundationx` 依赖

## 迁移路径

### configx

| 当前使用                      | 迁移目标                                                     | 说明           |
| ----------------------------- | ------------------------------------------------------------ | -------------- |
| `foundationx.SecretString`    | `kernel/errx.RedactedString` 或 configx 本地 `RedactedValue` | 脱敏字符串类型 |
| `foundationx.ValidationError` | `configx.ValidationError`（已有）                            | 配置校验错误   |
| 其他 foundationx 类型         | kernel 对应原语或 configx 本地定义                           | 逐个评估       |

### observex

| 当前使用                   | 迁移目标                | 说明         |
| -------------------------- | ----------------------- | ------------ |
| `foundationx.ErrorKind`    | `kernel/errx.Kind`      | 错误分类枚举 |
| `foundationx.HealthStatus` | `kernel/healthx.Status` | 健康状态枚举 |
| 其他 foundationx 类型      | kernel 对应原语         | 逐个评估     |

## 时间线

| 里程碑        | 目标               | 验收                             |
| ------------- | ------------------ | -------------------------------- |
| 冻结          | 立即               | 不再新增 `foundationx` usage     |
| configx 迁移  | configx v0.3 之前  | go.mod 中无 foundationx 依赖     |
| observex 迁移 | observex v0.4 之前 | go.mod 中无 foundationx 依赖     |
| 清理          | 迁移完成后         | 删除 `internal/foundationx` 目录 |

## 约束

- 迁移必须保持 API 兼容（消费方不需要改代码）
- 如果需要 breaking change，必须 bump major 版本
- 迁移 PR 必须包含：旧用法 → 新用法的映射表
- CI 中增加检查：`grep -rn "foundationx" --include="*.go"` 不应新增

## 风险

| 风险                          | 缓解                                        |
| ----------------------------- | ------------------------------------------- |
| 迁移过程中 API 不兼容         | 使用 type alias 过渡，逐步弃用              |
| kernel 对应原语尚未就绪       | 先用本地定义，kernel 就绪后替换             |
| 下游模块依赖 foundationx 类型 | 通过 contracts 包重新导出，避免下游直接依赖 |

## 后续

- 迁移完成后，`foundationx` 仓库归档或标记为 deprecated
- 在 `FOUNDATION-DEPS.yaml` 中将 `foundationx_compatibility.status` 更新为 `completed`
