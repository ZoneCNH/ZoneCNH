# TASK-FRED-001 Core Implementation

## Objective

初始化 `fred` C/S 模块骨架：建立 `fred-client`/`fred-server` 双服务入口、`configx` 配置映射、`observex` 可观测性接入，以及边界门禁基线。

## Covers

- FR-001（双服务独立进程 + health/version/readiness）
- FR-002（configx 映射，禁止 secret 落盘）
- FR-014（边界门禁，禁止绕过共享基座）
- BR-008（macro_data 不依赖 fred 内部包）

## Scope

- `cmd/fred-client` 和 `cmd/fred-server` 入口文件
- `configx` 键名映射与配置结构
- `bootstrap.Build` 调用链与服务生命周期管理
- health/version/readiness endpoint 实现
- `scripts/boundary-gates.sh` 边界门禁规则更新与验证

## Non-Scope

- 任何业务逻辑（采集、归一化、持久化）
- 存储写入或消息发布
- API 查询端点
- domain_macro 映射逻辑

## Acceptance Criteria

1. `fred-client` 和 `fred-server` 可独立启动，暴露 `/health`、`/version`、`/readiness`。
2. 配置从 `sre/secrets/env/dev.md` 通过 `configx` 映射，不将 secret 值写入代码或文档。
3. `scripts/boundary-gates.sh` 全部 gate 通过。
4. `go test ./... -count=1` 全量通过，`go vet ./...` 零警告。

## Verification Commands

```bash
# 单元测试与 vet
cd /home/workspace/fred && go test ./... -count=1
cd /home/workspace/fred && go vet ./...

# 边界门禁
cd /home/workspace/fred && bash scripts/boundary-gates.sh

# 服务启动 smoke（本地无 dev secret 时验证 fail-fast 行为）
cd /home/workspace/fred && go test ./cmd/... -run Smoke -count=1
```

## Dependencies

- `bootstrap`（双服务骨架）
- `configx`（配置映射）
- `observex`（可观测性）
- `kernel`（Module/App/Lifecycle）
