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

**里程碑**：
- `go build ./...` 编译通过
- `xlibgate --help 2>&1 | grep -q 'Usage'` 输出帮助信息

### Phase 1: CLI 框架（1 task）

| Task | 交付物 | 依赖 | Effort |
|------|--------|------|--------|
| TASK-XLIBGATE-001 | cmd/xlibgate/main.go, cli.go, cli_test.go（5 子命令 + flag 绑定） | 000 | 1h |

**里程碑**：
- `xlibgate check imports --help 2>&1 | grep -q '\-\-config'`
- `xlibgate check gomod --help 2>&1 | grep -q '\-\-path'`
- `xlibgate check baseline --help 2>&1 | grep -q '\-\-expected'`
- `xlibgate check release --help 2>&1 | grep -q '\-\-evidence'`
- `xlibgate check all --help 2>&1 | grep -q '\-\-config'`

### Phase 2: 核心检查器（4 tasks，全部可并行）

| Task | 子命令 | 交付物 | 依赖 | Effort |
|------|--------|--------|------|--------|
| TASK-XLIBGATE-002 | check imports | check_imports.go, check_imports_test.go, config.go, internal/scan/imports/imports.go, internal/ast/parser.go | 001 | 3h |
| TASK-XLIBGATE-003 | check gomod | check_gomod.go, check_gomod_test.go, internal/gomod/parser.go | 001 | 2h |
| TASK-XLIBGATE-004 | check baseline | check_baseline.go, check_baseline_test.go | 001 | 2h |
| TASK-XLIBGATE-005 | check release | check_release.go, check_release_test.go, evidence/collector.go, evidence/validator.go | 001 | 2h |

**Phase 2 并行度：4**（全部仅依赖 001，互相无依赖）

**里程碑**：
- `xlibgate check imports --config testdata/deps.yaml --path testdata/ok 2>&1; [ $? -eq 0 ]` — 合规项目 exit 0
- `xlibgate check imports --config testdata/deps.yaml --path testdata/bad 2>&1; [ $? -eq 1 ]` — 违规项目 exit 1
- `xlibgate check gomod --path testdata/ok 2>&1; [ $? -eq 0 ]`
- `xlibgate check baseline --expected 1.23 --path testdata 2>&1; [ $? -eq 0 ]`
- `xlibgate check release --evidence testdata/evidence.json 2>&1; [ $? -eq 0 ]`
- 每个子命令独立可运行，exit code 正确（0=pass, 1=fail, 2=error）

### Phase 3: 聚合 + 输出（1 task）

| Task | 交付物 | 依赖 | Effort |
|------|--------|------|--------|
| TASK-XLIBGATE-006 | check_all.go, output.go, check_all_test.go | 002, 003, 004, 005 | 2h |

**里程碑**：
- `xlibgate check all --config testdata/deps.yaml --path testdata 2>&1; [ $? -eq 0 ]` — 全部通过
- `xlibgate check all --config testdata/deps.yaml --path testdata --output json 2>&1 | jq -e '.status'` — JSON 输出含 status 字段
- `xlibgate check all --config testdata/deps.yaml --path testdata --artifact report.json` — artifact 写入文件

### Phase 4: 集成测试 + 文档（2 tasks，顺序执行）

| Task | 交付物 | 依赖 | Effort |
|------|--------|------|--------|
| TASK-XLIBGATE-007 | integration_test.go（端到端验证） | 002, 003, 004, 005, 006 | 2h |
| TASK-XLIBGATE-008 | README.md, CHANGELOG.md（Release DoD 验证） | 000–007 | 1h |

**里程碑**：
- `go test -race -count=1 ./...` 全部通过
- `go tool cover -func=.coverage/cover.out | grep total | awk '{print $3}' | tr -d '%'` ≥ 80
- `go vet ./...` 零警告
- `xlibgate check all --config xlibgate.yaml` self-check 通过

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
| cli_test.go | 001 | 无 |
| config.go | 002 | 无 |
| check_imports.go | 002 | 无 |
| check_imports_test.go | 002 | 无 |
| internal/scan/imports/imports.go | 002 | 无 |
| internal/ast/parser.go | 002 | 无 |
| check_gomod.go | 003 | 无 |
| check_gomod_test.go | 003 | 无 |
| internal/gomod/parser.go | 003 | 无 |
| check_baseline.go | 004 | 无 |
| check_baseline_test.go | 004 | 无 |
| check_release.go | 005 | 无 |
| check_release_test.go | 005 | 无 |
| evidence/collector.go | 005 | 无 |
| evidence/validator.go | 005 | 无 |
| check_all.go | 006 | 无 |
| check_all_test.go | 006 | 无 |
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
| Benchmark | 002–006 | `go test -bench=. -benchmem ./...`（NFR-001~NFR-006） |
| 集成测试 | 007 | `//go:build integration` + 端到端 CLI 调用 |
| 覆盖率 | ALL | `go tool cover` ≥ 80% |
| Race 检测 | ALL | `go test -race -count=1 ./...` |
| 安全扫描 | 006 | `gitleaks detect --no-git`（BR-005，NFR-008） |
| 自检 | 008 | `xlibgate check all --config xlibgate.yaml` → pass |
| stdlib-only | ALL | `go list -deps ./...` 无 Foundation 运行时依赖（NFR-010） |
| 日志事件 | 002–006 | SPEC §18 Observability 事件（xlibgate.check.*）在对应 checker 中输出 |

---

## 7. 风险与缓解

| 风险 | 概率 | 影响 | 风险值 | 关联 Task | 缓解 | 回滚/修复路径 | 检测方式 |
|------|:----:|:----:|:------:|:----------:|------|---------------|----------|
| check all 提前退出（违反 BR-006） | 15% | High | 0.45 | TASK-XLIBGATE-006 | Phase 3 明确顺序执行 + 继续语义 | 回退到上一 Tag 版本，hotfix 分支修复 BR-006 语义后重新发布 | TC-005 验证 |
| AST 解析性能不达标 | 10% | Medium | 0.20 | TASK-XLIBGATE-002 | 仅解析 import 声明，不展开完整 AST | 优化 AST 遍历逻辑，benchmark 回归验证 < 10s | benchmark < 10s |
| go.mod 路径处理跨平台差异 | 10% | Medium | 0.20 | TASK-XLIBGATE-003 | `filepath` 包统一路径处理 | 在受影响平台修复路径处理逻辑，重新验证 CI matrix | Windows/Linux/macOS CI matrix |
| release evidence schema 与 xlib-standard 不一致 | 15% | Medium | 0.30 | TASK-XLIBGATE-005 | Phase 3 前同步 xlib-standard schema | 代码回滚至与当前 xlib-standard schema 兼容的版本，同步升级 xlib-standard 后重新联调 | JSON schema 校验 |
| config.yaml 解析边界情况 | 10% | Low | 0.10 | TASK-XLIBGATE-002 | 空配置/仅注释/格式错误全覆盖测试 | 修复 config 解析逻辑后回归测试全部 edge case | 单元测试覆盖全部 edge case |

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
