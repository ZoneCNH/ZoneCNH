# TASK-BEA-001：双服务骨架与边界门禁

- Status: Planned
- Owner: bea
- Depends-On: none
- Source: `spec/SPEC.md`、`plan/PLAN.md`

## 目标

建立 `bea-client` / `bea-server` 双服务骨架，接入共享基座，并落地边界门禁。

## Scope

1. 建立双入口进程与统一生命周期管理。
2. 配置加载仅支持 secret reference。
3. 增加 boundary-gates 脚本并阻断越界依赖。

## Non-Scope

- 不实现具体 BEA 数据采集与分析逻辑。
- 不实现多存储链路写入。

## 验收

- `go test ./cmd/...` 通过。
- `bash scripts/boundary-gates.sh` 通过。
- 无 secret 明文落盘。

