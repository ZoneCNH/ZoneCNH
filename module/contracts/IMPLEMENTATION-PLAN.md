# contracts 实现计划

> 来源：`SPEC.md`、`TRACEABILITY.md`、`README.md`、`goal.md`
> 生成日期：2026-06-22

## 1. 任务依赖

```text
TASK-CONTRACTS-000
├── TASK-CONTRACTS-001
├── TASK-CONTRACTS-002
│   ├── TASK-CONTRACTS-003
│   └── TASK-CONTRACTS-005
└── TASK-CONTRACTS-004
```

## 2. 任务分解

| 任务 | 目标 | 依赖 | 主要验证 |
| --- | --- | --- | --- |
| TASK-CONTRACTS-000 | 共享边界与依赖基线 | 无 | `go list -deps ./...`、`go vet ./...`、旧术语扫描 |
| TASK-CONTRACTS-001 | 端口与信号工厂 | `TASK-CONTRACTS-000` | `ports.go` 方法签名、编译期检查、godoc 注释 |
| TASK-CONTRACTS-002 | 基础封装与核心 DTO | `TASK-CONTRACTS-000` | JSON round-trip、导出字段、snake_case tag、不可变约定 |
| TASK-CONTRACTS-003 | 兼容投影与重命名治理 | `TASK-CONTRACTS-002` | 别名导出、迁移期兼容、rename/removal 追溯 |
| TASK-CONTRACTS-005 | 摄入契约与拒绝码集 | `TASK-CONTRACTS-002` | `Ingest` 单请求 / 单结果、10 个 canonical code、`RejectUnsupportedChannel` 属于 canonical |
| TASK-CONTRACTS-004 | 文档基线与追溯闭合 | `TASK-CONTRACTS-000`, `TASK-CONTRACTS-001`, `TASK-CONTRACTS-002`, `TASK-CONTRACTS-003`, `TASK-CONTRACTS-005` | `rg` 旧术语扫描、`git diff --check`、文档交叉一致性 |

## 3. 推荐执行顺序

### Phase 1: 基线

- `TASK-CONTRACTS-000`

### Phase 2: 核心导出面

- `TASK-CONTRACTS-001`
- `TASK-CONTRACTS-002`

### Phase 3: 迁移与摄入

- `TASK-CONTRACTS-003`
- `TASK-CONTRACTS-005`

### Phase 4: 文档闭合

- `TASK-CONTRACTS-004`

## 4. 总量

| 项目 | 数量 |
| --- | --- |
| 任务数 | 6 |
| 主要阶段 | 4 |
| 文档退出条件 | `SPEC.md`、`TRACEABILITY.md`、`ACCEPTANCE.md`、`FEATURES.md`、`README.md` 与 `goal.md` 同源 |

## 5. 质量门禁

| 门禁 | 目标 |
| --- | --- |
| 术语回归扫描 | 不出现旧分层命名、旧版本标记、旧 API 名称、重大改名故事、旧交易所接入叙事 |
| 文档补丁检查 | `git diff --check -- module/contracts` 无告警 |
| 运行时复验 | `/home/contracts` 的 `go test ./...`、`go test ./... -race -count=1`、`go vet ./...` 可复验 |
| 覆盖闭合 | `TRACEABILITY.md` 的 FR / BR / NFR / TC / task 关系闭合 |
