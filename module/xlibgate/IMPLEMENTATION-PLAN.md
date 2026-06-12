# xlibgate 实现计划

> 来源：[SPEC.md](./SPEC.md) v1.0.0
> 生成日期：2026-06-12
> 环境：本仓库仅含文档；实现计划描述 xlibgate Go 项目的开发阶段。

---

## 1. 依赖 DAG

```text
TASK-XLIBGATE-000 (项目骨架: go.mod, cmd/, errors.go)
│
└── TASK-XLIBGATE-001 (CLI 框架: 子命令分发, flag 绑定)
    │
    ├── TASK-XLIBGATE-002 (check imports) ──────────────┐
    ├── TASK-XLIBGATE-003 (check gomod)                 │
    ├── TASK-XLIBGATE-004 (check baseline)              │
    └── TASK-XLIBGATE-005 (check release)               │
        │                                               │
        └── TASK-XLIBGATE-006 (check all + 输出格式) ───┘
            │
            ├── TASK-XLIBGATE-007 (集成测试)
            │
            └── TASK-XLIBGATE-008 (文档 + Release DoD)
```

---

## 2. 实现顺序

### Phase 0: 项目骨架（1 task，阻塞全部）

| Task | 交付物 | 依赖 | Effort |
|------|--------|------|--------|
| TASK-XLIBGATE-000 | go.mod, cmd/xlibgate/main.go, errors.go | — | 0.5h |

**里程碑**：`go build ./...` 编译通过，`xlibgate --help` 输出帮助信息。

### Phase 1: CLI 框架（1 task）

| Task | 交付物 | 依赖 | Effort |
|------|--------|------|--------|
| TASK-XLIBGATE-001 | cmd/xlibgate/main.go, cli.go（5 子命令 + flag 绑定） | 000 | 1h |

**里程碑**：所有子命令可解析对应参数（--config, --path, --expected, --evidence）。

### Phase 2: 核心检查器（4 tasks，全部可并行）

| Task | 子命令 | 交付物 | 依赖 | Effort |
|------|--------|--------|------|--------|
| TASK-XLIBGATE-002 | check imports | check_imports.go, check_imports_test.go, config.go | 001 | 3h |
| TASK-XLIBGATE-003 | check gomod | check_gomod.go, check_gomod_test.go | 001 | 2h |
| TASK-XLIBGATE-004 | check baseline | check_baseline.go, check_baseline_test.go | 001 | 2h |
| TASK-XLIBGATE-005 | check release | check_release.go, check_release_test.go | 001 | 2h |

**Phase 2 并行度：4**（全部仅依赖 001，互相无依赖）

**里程碑**：每个子命令独立可运行，exit code 正确（0=pass, 1=fail, 2=error）。

### Phase 3: 聚合 + 输出（1 task）

| Task | 交付物 | 依赖 | Effort |
|------|--------|------|--------|
| TASK-XLIBGATE-006 | check_all.go, output.go（JSON/text 统一输出） | 002, 003, 004, 005 | 2h |

**里程碑**：`check all` 聚合所有子检查，支持 JSON 和 human-readable 双格式输出。

### Phase 4: 集成测试 + 文档（2 tasks，顺序执行）

| Task | 交付物 | 依赖 | Effort |
|------|--------|------|--------|
| TASK-XLIBGATE-007 | integration_test.go（端到端验证） | 002, 003, 004, 005, 006 | 2h |
| TASK-XLIBGATE-008 | README.md, CHANGELOG.md（Release DoD 验证） | 000–007 | 1h |

**里程碑**：集成测试全绿，文档完整，覆盖率 ≥ 80%，Release DoD 全部勾选。

---

## 3. 关键路径

```text
000 → 001 → 002 (3h) → 006 (2h) → 007 (2h) → 008 (1h)
```

**关键路径工期**：0.5 + 1 + 3 + 2 + 2 + 1 = **9.5h**

---

## 4. 并行策略

### Phase 2（最大并行度 4）

check imports / check gomod / check baseline / check release 四个检查器全部仅依赖 CLI 框架（001），互相无依赖，可同时开发。

### Phase 4（顺序执行）

007 集成测试依赖全部核心检查器（002–006）完成；008 文档依赖全部任务（000–007）完成。两者必须顺序执行。

### 并行收益

| 策略 | 总工时 |
|------|--------|
| 全串行 | 15.5h |
| Phase 2 并行 | **~9.5h**（关键路径） |

---

## 5. 文件冲突分析

| 文件 | 创建 Task | 冲突风险 |
|------|-----------|----------|
| go.mod | 000 | 无 |
| cmd/xlibgate/main.go | 000, 001 | ⚠️ 顺序执行 |
| errors.go | 000 | 无 |
| cli.go | 001 | 无 |
| config.go | 002 | 无 |
| check_imports.go | 002 | 无 |
| check_gomod.go | 003 | 无 |
| check_baseline.go | 004 | 无 |
| check_release.go | 005 | 无 |
| check_all.go | 006 | 无 |
| output.go | 006 | 无 |
| integration_test.go | 007 | 无 |
| README.md | 008 | 无 |
| CHANGELOG.md | 008 | 无 |

仅 `cmd/xlibgate/main.go` 在 000（创建入口）和 001（扩展 CLI 框架）之间共享，已通过 Phase 0 → Phase 1 顺序执行解决。

---

## 6. 测试策略

| 测试类型 | 覆盖 Task | 工具 |
|----------|-----------|------|
| 单元测试 | 002–006 | `go test -race -count=1 ./...` |
| 边界测试 | 002–005 | 合规/违规/错误三种 exit code |
| 集成测试 | 007 | `//go:build integration` + 端到端 CLI 调用 |
| 覆盖率 | ALL | `go tool cover` ≥ 80% |
| Race 检测 | ALL | `go test -race -count=1 ./...` |
| 自检 | 008 | `xlibgate check all --config xlibgate.yaml` → pass |
| stdlib-only | ALL | `go list -deps ./...` 无 Foundation 运行时依赖 |

---

## 7. 风险与缓解

| 风险 | 概率 | 影响 | 风险值 | 缓解 | 检测方式 |
|------|:----:|:----:|:------:|------|----------|
| check all 提前退出（违反 BR-006） | 15% | High | 0.45 | Phase 3 明确顺序执行 + 继续语义 | TC-005 验证 |
| AST 解析性能不达标 | 10% | Medium | 0.20 | 仅解析 import 声明，不展开完整 AST | benchmark < 10s |
| go.mod 路径处理跨平台差异 | 10% | Medium | 0.20 | `filepath` 包统一路径处理 | Windows/Linux/macOS CI matrix |
| release evidence schema 与 xlib-standard 不一致 | 15% | Medium | 0.30 | Phase 3 前同步 xlib-standard schema | JSON schema 校验 |
| config.yaml 解析边界情况 | 10% | Low | 0.10 | 空配置/仅注释/格式错误全覆盖测试 | 单元测试覆盖 13.1 全部 edge case |

---

## 8. 总工时估算

| Phase | Tasks | 串行 Effort | 并行 Effort |
|-------|-------|-------------|-------------|
| Phase 0 | 1 | 0.5h | 0.5h |
| Phase 1 | 1 | 1h | 1h |
| Phase 2 | 4 | 9h | 3h (并行) |
| Phase 3 | 1 | 2h | 2h |
| Phase 4 | 2 | 3h | 3h (顺序) |
| **总计** | **9** | **15.5h** | **~9.5h** (充分利用并行) |
