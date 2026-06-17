# ADR: foundationx Compatibility Exit

> 状态：Active（v3 — 2026-06-18 实测纠错：postgresx 已独立）
> 日期：2026-06-07（v1） / 2026-06-18（v2 误判 postgresx 传染） / 2026-06-18（v3 实测纠错）
> 决策者：ZoneCNH
> 关联：`FOUNDATION-V1.md` Issue 4；`.foundationx/blockers.json` BLK-009

## 背景

Foundation 模块早期以 `foundationx` 作为共享基础包，包含 `SecretString`、`ErrorKind`、`HealthStatus` 等通用类型。随着 Foundation 架构收敛，`kernel` 已成为 L0 原语底座，`foundationx` 的角色应被替代。

当前依赖状态（v3 实测，2026-06-18）：

| 模块       | foundationx 版本 | 依赖方式                              | 说明                          |
| ---------- | ---------------- | ------------------------------------- | ----------------------------- |
| `configx`  | v0.0.0           | 本地 replace `./internal/foundationx` | 用于 SecretString 等类型      |
| `observex` | v0.1.0           | 远程依赖                              | 用于 ErrorKind / HealthStatus |
| `postgresx` | -                | ✅ 已完成迁移                          | v1.0.0 实测：本地 `SecretString`（pkg/postgresx/secret.go）+ 本地 `NewError`/`ErrorKindConfig`（pkg/postgresx/error.go）；go.mod 不含 foundationx |
| `bootstrap` | v0.1.1（待发）   | 历史遗留单点                           | `pkg/bootstrap/stores.go:217 foundationx.SecretString(...)` 一行残留；v0.1.1 替换为 `postgresx.SecretString(...)` 即可清零 |

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

### postgresx（v3 实测：已完成迁移，无需新版本）

| 当前 v1.0.0 实测 | 状态 | 说明 |
| ---------------- | ---- | ---- |
| `Config.Password postgresx.SecretString`（本地） | ✅ 已迁移 | pkg/postgresx/secret.go: `type SecretString string` + `NewSecretString` |
| `NewError(ErrorKindConfig, op, msg)` 本地 | ✅ 已迁移 | pkg/postgresx/error.go 定义 ErrorKind 全枚举 + NewError |
| `go.mod` foundationx | ✅ 不含 | grep "foundationx" go.mod 零命中 |

**v2 误判更正**：v2 当时基于 `GOMODCACHE/postgresx@v1.0.0/pkg/postgresx/config.go` 看到 `foundationx.SecretString`，但该缓存可能是 module 重命名前的旧版本快照——实际 GitHub ZoneCNH/postgresx@v1.0.0 tag 已是本地化版本。

### bootstrap（v0.1.1 1 行替换即可清零）

| 当前用法（v0.1.0）                                          | 替换目标                                    | 工作量             |
| ----------------------------------------------------------- | ------------------------------------------ | ------------------ |
| `pkg/bootstrap/stores.go:23 import "github.com/ZoneCNH/foundationx/pkg/foundationx"` | 删除该 import | 1 行 |
| `pkg/bootstrap/stores.go:217 foundationx.SecretString(envOr(prefix+"PG_PASSWORD", ""))` | `postgresx.SecretString(envOr(prefix+"PG_PASSWORD", ""))` | 1 行 |
| `go.mod` foundationx require | `go mod tidy` | 自动 |

## 时间线

| 里程碑          | 目标                 | 验收                                              |
| --------------- | -------------------- | ------------------------------------------------- |
| 冻结            | 立即                 | 不再新增 `foundationx` usage                      |
| configx 迁移    | configx v0.3 之前    | go.mod 中无 foundationx 依赖                      |
| observex 迁移   | observex v0.4 之前   | go.mod 中无 foundationx 依赖                      |
| ~~postgresx 迁移~~  | ~~postgresx v1.1.0~~ | ✅ **v3 纠错**：postgresx@v1.0.0 实测已完成（pkg/postgresx/secret.go + error.go），无需新版本 |
| **bootstrap 跟进** | **bootstrap v0.1.1** | 1 行替换 stores.go:217（`foundationx.SecretString` → `postgresx.SecretString`）+ go.mod 清理；BLK-009a 关闭条件 |
| 清理            | 上述全部迁移完成后   | 删除 `internal/foundationx` 目录                  |

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
