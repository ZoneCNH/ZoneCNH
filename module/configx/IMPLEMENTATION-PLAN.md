# configx 实现计划

> 来源：[SPEC.md](./SPEC.md) v1.0.1
> 更新：2026-06-12（v2.0 — 对齐 Task 文件编号）
> 任务数量：11（TASK-CONFIGX-000 ~ 010）

## 1. 依赖 DAG

```text
TASK-CONFIGX-000 (骨架: go.mod, errors.go)
│
├── TASK-CONFIGX-001 (接口: Reader, Config, Option)
│   │
│   ├── TASK-CONFIGX-002 (Load: YAML/TOML/JSON 文件解析)
│   │   │
│   │   └── TASK-CONFIGX-003 (Merge: 深度合并) ← 依赖 001, 002
│   │       │
│   │       ├── TASK-CONFIGX-004 (EnvOverride: 环境变量覆盖) ← 依赖 003
│   │       │   │
│   │       │   └── TASK-CONFIGX-006 (Reader 实现: Get/并发安全) ← 依赖 003, 004
│   │       │       │
│   │       │       ├── TASK-CONFIGX-007 (Watch: 文件监控) ← 依赖 005, 006
│   │       │       ├── TASK-CONFIGX-008 (集成测试 + Benchmark) ← 依赖 004, 005, 006, 007
│   │       │       └── TASK-CONFIGX-010 (Security: 脱敏) ← 依赖 006
│   │       │
│   │       └── TASK-CONFIGX-005 (Validate: schema 校验) ← 依赖 001, 003
│   │
│   └── TASK-CONFIGX-009 (文档 + Release) ← 依赖 000~008
```

## 2. 实现顺序

### Phase 1: 骨架 (1 task)
| Task | 内容 | Files | Effort |
|------|------|-------|--------|
| 000 | go.mod, doc.go, errors.go | go.mod, doc.go, errors.go | 0.5h |

### Phase 2: 接口 + 核心能力 (3 tasks, 串行)
| Task | 内容 | 内部依赖 | Effort |
|------|------|----------|--------|
| 001 | Reader/Config/Option 接口定义 | 000 | 1h |
| 002 | Load：YAML/TOML/JSON 解析 | 001 | 3h |
| 003 | Merge：深度合并算法 | 001, 002 | 2h |

### Phase 3: 并行能力 (4 tasks)
| Task | 内容 | 内部依赖 | Effort |
|------|------|----------|--------|
| 004 | EnvOverride：环境变量覆盖 | 003 | 2h |
| 005 | Validate：schema 校验 | 001, 003 | 2h |
| 006 | Reader 实现：Get/并发安全 | 003, 004 | 2h |
| 010 | Security：脱敏/权限检查 | 006 | 1.5h |

### Phase 4: 集成 + 文档 (2 tasks)
| Task | 内容 | 内部依赖 | Effort |
|------|------|----------|--------|
| 007 | Watch：文件监控（可选） | 005, 006 | 2h |
| 008 | 集成测试 + Benchmark | 004, 005, 006, 007 | 2h |
| 009 | 文档 + Release：README/CHANGELOG/godoc | 000~008 | 2h |

## 3. 关键路径

```
000 → 001 → 002 → 003 → 004 → 006 → 007 → 008 → 009
   0.5 + 1 + 3 + 2 + 2 + 2 + 2 + 2 + 2 = 16.5h (串行)
```

## 4. 工时估算

| Phase | 串行 | 并行 |
|-------|:--:|:--:|
| Phase 1 | 0.5h | 0.5h |
| Phase 2 | 6h | 3h |
| Phase 3 | 7.5h | 2h (004/005 并行) |
| Phase 4 | 6h | 4h |
| **总计** | **20h** | **~9.5h** |

## 5. 测试策略

| 类型 | 覆盖 Task | 工具 |
|------|----------|------|
| 单元测试 | 002~007, 010 | `go test -race -count=1` |
| 安全测试 | 010 | gitleaks + 手动脱敏验证 |
| 集成测试 | 008 | 完整加载链 |
| Benchmark | 008 | < 50ms (1000 key load), < 100ns (Get) |
| 覆盖率 | ALL | ≥ 80% |

## 6. Task → SPEC 映射

| Task | SPEC § | FR/BR |
|------|--------|-------|
| 000 | §10.1, §15.1 | — |
| 001 | §9, §9.1 | — |
| 002 | FR-001, §13 | FR-001 |
| 003 | BR-001, BR-003, §10.2 | BR-001, BR-003 |
| 004 | FR-002, BR-004 | FR-002, BR-004 |
| 005 | FR-003, BR-002, BR-006, BR-007 | FR-003, BR-002, BR-006, BR-007 |
| 006 | FR-004, BR-005 | FR-004, BR-005 |
| 007 | FR-005 | FR-005 |
| 008 | §16.4, §17 | — |
| 009 | §22, §9.2 | — |
| 010 | §19 | — |
