# FR-024 全量 Config Hot Reload 评估 + Bootstrap 装配层单列

- Date: 2026-06-25
- Scope: Plan007 A10（FR-024 评估）+ B6（bootstrap 装配层）
- Related: beads ZoneCNH-e47 / ZoneCNH-oqa

---

## Part 1: FR-024 全量 Config Hot Reload 评估（A10）

`[COMPUTED, HIGH]` **结论：当前为部分 hot reload（symbol catalog），全量 config hot reload 不可行/不推荐。**

### 现状（runtime 代码核实）

- `POST /api/v1/admin/symbols/reload`（admin.go:96）：reload symbol catalog + 触发 stream diff
- `RefreshCatalog`（history_lifecycle.go:412）：原子替换 catalog + stream 增减
- 覆盖：symbol 列表热更新（无需重启）

### 全量 config hot reload 评估

| Config 项         | 当前可热重载？ | 全量化可行性 | 理由                                                      |
| ----------------- | -------------- | ------------ | --------------------------------------------------------- |
| symbol catalog    | ✅ 是          | —            | 已实现（FR-024）                                          |
| streams（订阅流） | 🟡 部分        | 中           | catalog reload 触发 stream diff，但 stream 类型变更需重连 |
| product_line 配置 | ❌ 否          | 低           | 启动时固定（StreamBase/DefaultSymbol）                    |
| backfill throttle | ❌ 否          | 中           | runtime 注入（FR-016 Partial）                            |
| storage 装配      | ❌ 否          | 极低         | client/storageFromEnv 启动时建连，热切换需重建连接池      |
| infra 连接        | ❌ 否          | 极低         | 网络连接不可热切换                                        |

### 建议

`[FRAME, HIGH]` **不推进全量 config hot reload**。理由：

1. infra 连接/storage 装配热切换复杂度极高，收益低（这些配置极少变更）
2. symbol catalog hot reload 已覆盖最频繁的变更场景（新增/下架 symbol）
3. 全量 config 变更应通过滚动重启（k8s rolling update）实现，比热重载更可靠

**FR-024 维持 Partial**（symbol catalog reload 已实现，全量化不推荐）。

---

## Part 2: Bootstrap 装配层单列（B6）

`[COMPUTED, HIGH]` binance 的 `cmd/binance-server/storage_env.go` 是**装配层（composition root）**的实例——它把 infra client 建连 + writer 构造 + ServerConfig 注入集中在一处。

### 装配层概念

- **定义**：composition root = 依赖注入的汇聚点，把「无状态的组件实现」与「有状态的运行时配置」绑定
- **binance 实例**：`storageFromEnv(ctx, bc)` 是装配函数，`storage_env.go` 是装配层文件
- **对比**：bootstrap `Build(ctx, Spec)` 是更高层的进程装配（config + lifecycle），storageFromEnv 是 binance 特定的存储装配

### 建议的分层文档化

在 `module/binance/server/PERSISTENCE-WIRING.md` 已记录 storageFromEnv 装配契约。建议在 bootstrap 仓（或 ZoneCNH 架构文档）补充：

```
进程分层（composition root 层级）：
  L0 bootstrap.Build       — 进程级（config/lifecycle/signal）
  L1 storageFromEnv        — 模块级存储装配（binance 特定）
  L2 writer 构造函数        — 组件级（无状态）
  L3 infra client New()    — 连接级（网络 IO）
```

### 当前状态

- binance 已隐式实现装配层（storage_env.go），但未显式文档化为「composition root」
- 建议：在 server/PERSISTENCE-WIRING.md §1 补一句「本文件定义 binance 的 composition root（装配层）」

`[FRAME, HIGH]` 装配层概念已实质落地（storage_env.go），文档化是增强认知清晰度，非功能缺口。

---

## 总结

| 项                     | 结论                                     | 行动                                                      |
| ---------------------- | ---------------------------------------- | --------------------------------------------------------- |
| FR-024 全量 hot reload | 不推荐（infra/storage 热切换复杂度极高） | 维持 Partial（symbol reload 已够）                        |
| Bootstrap 装配层       | 已实质落地（storage_env.go）             | 文档化增强（PERSISTENCE-WIRING 补 composition root 概念） |
