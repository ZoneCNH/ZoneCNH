# PROMPT-FRED-ROOT-001 — TASK-FRED-001 Core Implementation

> 本文件为管线 S5 Prompt 阶段产物（Context Packet），供 task-executor 执行 TASK-FRED-001 使用。
> 生成依据：`tasks/TASK-FRED-001-core-implementation.md`、`spec/SPEC.md`、`RULES.md`。

## 1. Task 目标与边界

**目标**：初始化 `fred` C/S 模块骨架——建立 `fred-client`/`fred-server` 双服务独立入口、`configx` 配置映射、`observex` 可观测性接入，以及边界门禁基线。

**Scope（必须做）**
- `cmd/fred-client`、`cmd/fred-server` 入口文件，暴露 `/health`、`/version`、`/readiness`。
- `configx` 键名映射与配置结构；配置经共享基座接入，禁止 secret 落盘。
- `bootstrap.Build` 调用链与服务生命周期（启动、优雅关闭）。
- `scripts/boundary-gates.sh` 边界门禁规则更新与验证。

**Non-Scope（禁止做）**
- 任何业务逻辑（采集、归一化、持久化）。
- 存储写入或消息发布；API 查询端点；`domain_macro` 映射逻辑。

## 2. 依赖与输入

- 规格：`module/fred/spec/SPEC.md`（§8 服务边界、§11 配置模式、§18 可观测性、§20 CI 门禁）
- 追溯矩阵：`module/fred/matrix/TRACEABILITY.md`（FR-001/002/014、BR-008）
- 计划：`module/fred/plan/PLAN.md`
- 规则：`module/fred/RULES.md`（§1.1 服务隔离、§6 可观测性、§7 边界门禁）
- 运行时仓库：`/home/workspace/fred`（Go，含 `bootstrap`/`configx`/`observex`/`kernel` 共享基座）
- 共享基座依赖：`bootstrap`、`configx`、`observex`、`kernel`（Module/App/Lifecycle）

## 3. 实现要求

- **服务隔离（RULES §1.1）**：`fred-client` 与 `fred-server` 必须独立进程，跨服务只允许 NATS（ingest + control plane），禁止同进程耦合。
- **配置（RULES §6.2）**：缺失必要配置键必须 fail-fast 退出并输出键名；禁止隐式默认值屏蔽缺配置。
- **可观测性（RULES §6.1/§6.3）**：日志携带 `job_id/series_id/request_id/endpoint` 关联字段；`/health`（存活）、`/readiness`（依赖存储就绪后 200）、`/version`（Go 版本 + git sha）。
- **边界门禁（RULES §7.1 G1-G5）**：`scripts/boundary-gates.sh` 必须全过；任何失败 block PR。
- **nats / kafka 分层职责（强制声明）**：本任务仅建立双服务骨架，**不发布任何消息**；nats 为 client→server ingest handoff + control plane 通道，kafka 为 server→下游 durable business event 通道，二者职责在后续 Task 落实，此处不得预先引入发布逻辑。
- **domain_macro 出域唯一性（强制声明）**：本任务不涉及出域模型；后续所有出域数据必须转换为 `domain_macro` 标准类型，禁止泄露 provider DTO。

## 4. 验收命令

```bash
# 单元测试与 vet
cd /home/workspace/fred && go test ./... -count=1
cd /home/workspace/fred && go vet ./...

# 边界门禁
cd /home/workspace/fred && bash scripts/boundary-gates.sh

# 服务启动 smoke（本地无 dev secret 时验证 fail-fast 行为）
cd /home/workspace/fred && go test ./cmd/... -run Smoke -count=1
```

**期望输出**：`go test` / `go vet` 零失败；`boundary-gates.sh` 全部 gate 通过；`/health` `/version` `/readiness` 端点可响应；缺配置时进程 fail-fast 退出并打印缺失键名。

## 5. 风险与回滚策略

- **风险**：双服务入口若引入同进程耦合会违反 RULES §1.1；secret 落盘违反 FR-002。
- **回滚**：本任务仅新增骨架代码，未触达生产数据；如 gate 失败或测试不通过，直接 revert 分支即可，无数据副作用。
- **secret 红线**：仅引用 `sre/secrets/env/dev.md` 键名与映射规则，禁止在代码或文档中复制任何密钥值。
