# configx 实现计划

> 来源：[SPEC.md](./SPEC.md) v1.0.1 | 任务数量：10（TASK-CONFIGX-000 ~ 010，008 已合并）
> 更新：2026-06-12（v3.0 — 修复红线：per-task 验证命令 + 风险识别 + 回滚策略 + 里程碑 + DAG 修正）

## 1. 依赖 DAG

```text
TASK-CONFIGX-000 (骨架: go.mod, errors.go)
│  [验证: go build ./... && go vet ./...]
│
├── TASK-CONFIGX-001 (接口: Reader, Config, Option)
│   │  [验证: go build ./...]
│   │
│   ├── TASK-CONFIGX-002 (Load: YAML/TOML/JSON 文件解析)
│   │   │  [验证: go test ./internal/... -run TestLoad -race]
│   │   │
│   │   └── TASK-CONFIGX-003 (Merge: 深度合并) ← 依赖 001,002
│   │       │  [验证: go test ./... -run TestMerge -race]
│   │       │
│   │       ├── TASK-CONFIGX-004 (EnvOverride: 环境变量覆盖) ← 依赖 003
│   │       │   │  [验证: go test ./... -run TestEnv -race]
│   │       │   │
│   │       │   └── TASK-CONFIGX-006 (Reader 实现: Get/并发安全) ← 依赖 003,004
│   │       │       │  [验证: go test ./... -run TestReader -race]
│   │       │       │
│   │       │       ├── TASK-CONFIGX-007 (Watch: 文件监控) ← 依赖 005,006
│   │       │       │     [验证: go test ./... -run TestWatch -race]
│   │       │       │
│   │       │       └── TASK-CONFIGX-010 (Security: 脱敏) ← 依赖 006
│   │       │             [验证: go test ./... -run TestSanitize -race && gitleaks detect --no-git]
│   │       │
│   │       └── TASK-CONFIGX-005 (Validate: schema 校验) ← 依赖 001,003
│   │             [验证: go test ./... -run TestValidate -race]
│   │
│   └── TASK-CONFIGX-009 (文档 + Release) ← 依赖 000~007,010
│         [验证: go test -race -count=1 ./... && go test -coverprofile=coverage.out ./...]
```

## 2. 实现顺序

### Phase 1: 骨架 (1 task)

| Task | 内容 | Files | 验证命令 | Effort |
|------|------|-------|----------|--------|
| 000 | go.mod, doc.go, errors.go | go.mod, doc.go, errors.go | `go build ./... && go vet ./...` | 0.5h |

### Phase 2: 接口 + 核心能力 (3 tasks, 串行)

| Task | 内容 | 内部依赖 | Files | 验证命令 | Effort |
|------|------|----------|-------|----------|--------|
| 001 | Reader/Config/Option 接口定义 | 000 | reader.go, config.go, options.go, config_test.go | `go build ./...` | 1h |
| 002 | Load：YAML/TOML/JSON 解析 | 001 | config.go, internal/yaml/, internal/toml/, internal/json/, config_test.go | `go test ./internal/... -run TestLoad -race` | 3h |
| 003 | Merge：深度合并算法 | 001,002 | merge.go, internal/merge/deep.go, merge_test.go | `go test ./... -run TestMerge -race` | 2h |

### Phase 3: 并行能力 (4 tasks)

| Task | 内容 | 内部依赖 | Files | 验证命令 | Effort |
|------|------|----------|-------|----------|--------|
| 004 | EnvOverride：环境变量覆盖 | 003 | env.go, env_test.go | `go test ./... -run TestEnv -race` | 2h |
| 005 | Validate：schema 校验 | 001,003 | schema.go, schema_test.go | `go test ./... -run TestValidate -race` | 2h |
| 006 | Reader 实现：Get/并发安全 | 003,004 | reader.go, reader_test.go | `go test ./... -run TestReader -race` | 2h |
| 010 | Security：脱敏/权限检查 | 006 | sanitize.go, sanitize_test.go | `go test ./... -run TestSanitize -race && gitleaks detect --no-git` | 1.5h |

### Phase 4: 集成 + 文档 (2 tasks)

| Task | 内容 | 内部依赖 | Files | 验证命令 | Effort |
|------|------|----------|-------|----------|--------|
| 007 | Watch：文件监控（可选） | 005,006 | watch.go, watch_test.go | `go test ./... -run TestWatch -race` | 2h |
| 009 | 文档 + Release：README/CHANGELOG/godoc | 000~007,010 | README.md, CHANGELOG.md, example_test.go | `go test -race -count=1 ./... && go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out \| tail -1` | 2h |

## 3. 关键路径

```
000 → 001 → 002 → 003 → 004 → 006 → 007 → 009
   0.5 + 1 + 3 + 2 + 2 + 2 + 2 + 2 = 14.5h (串行)
```

## 4. 工时估算

| Phase | 串行 | 并行 |
|-------|:--:|:--:|
| Phase 1 | 0.5h | 0.5h |
| Phase 2 | 6h | 6h（串行无并行） |
| Phase 3 | 7.5h | 2h（004∥005 先行，然后 006→010 串行） |
| Phase 4 | 4h | 4h（007→009 串行） |
| **总计** | **18h** | **~12.5h** |

### 4.1 里程碑

| 里程碑 | Phase | 验收标准 | 预计日期 |
|--------|:----:|----------|----------|
| M1: 骨架就绪 | 1 | go.mod + errors.go 编译通过 | Day 1 |
| M2: 核心能力就绪 | 2 | Load + Merge 通过全部单元测试 | Day 2 |
| M3: 功能完备 | 3 | EnvOverride + Validate + Reader + Security 通过测试 | Day 3 |
| M4: Release Candidate | 4 | 全量测试 + 覆盖率 ≥ 80% + gitleaks 通过 | Day 4 |

## 5. 测试策略

| 类型 | 覆盖 Task | 工具 | 目标 |
|------|----------|------|------|
| 单元测试 | 002~007, 010 | `go test -race -count=1` | 所有用例通过 |
| 安全测试 | 010 | `gitleaks detect --no-git` | 零泄露 |
| 集成测试 | 002~007 | 完整加载链: 默认值→文件→环境变量→校验→读取 | 全链路通过 |
| Benchmark | 006 | Load 1000 key < 50ms, Get < 100ns | 达标 |
| 覆盖率 | ALL | `go test -coverprofile=coverage.out ./...` | ≥ 80% |

> **注**：TASK-CONFIGX-008（原集成测试+Benchmark独立Task）已删除。集成测试内容拆分到各被测 Task（002~007），Benchmark 归入 TASK-006（Reader）。

## 6. Task → SPEC 映射

| Task | SPEC § | FR/BR | 备注 |
|------|--------|-------|------|
| 000 | §10.1, §15.1 | — | 骨架搭建 |
| 001 | §9, §9.1 | — | 接口定义 |
| 002 | FR-001, §13 | FR-001 | 含集成测试 |
| 003 | BR-001, BR-003, §10.2 | BR-001, BR-003 | 含集成测试 |
| 004 | FR-002, BR-004 | FR-002, BR-004 | 含集成测试 |
| 005 | FR-003, BR-002, BR-006, BR-007 | FR-003, BR-002, BR-006, BR-007 | 含集成测试 |
| 006 | FR-004, BR-005 | FR-004, BR-005 | 含 Benchmark |
| 007 | FR-005 | FR-005 | 含集成测试 |
| 009 | §22, §9.2 | — | 文档产出 |
| 010 | §19 | — | 安全脱敏 |

## 7. 风险识别

| 风险 | 概率 | 影响 | 影响 Task | 缓解措施 |
|------|:--:|:--:|-----------|----------|
| YAML/TOML 解析差异导致配置不一致 | Low | High | 002 | 统一 golden test，三种格式输出统一 map |
| 深度合并丢失嵌套键 | Medium | High | 003 | 递归合并而非覆盖，独立测试覆盖 |
| 环境变量 key 映射歧义（大小写/分隔符） | Medium | Medium | 004 | 统一转小写，`_` 严格分隔 |
| schema 嵌套字段校验遗漏 | Low | Medium | 005 | 递归遍历嵌套 map，测试覆盖 |
| 点分路径遍历 panic（nil 中间节点） | Medium | High | 006 | 逐层 nil 检查，不存在返回 nil |
| Watch 回调阻塞导致 goroutine 泄漏 | Low | Medium | 007 | callback 在独立 goroutine 执行 |
| 脱敏影响性能（递归遍历大配置） | Medium | Medium | 010 | 只脱敏最终值，路径匹配 O(n) |
| 敏感字段名遗漏（自定义命名） | Medium | High | 010 | 提供 WithMaskPatterns(...) Option 扩展 |
| SPEC §23 Open Questions 未决影响范围 | Low | Medium | 007,010 | 热更新/加密/模板 → v1.0 前决策 |

## 8. 回滚策略

| Task | 回滚方式 | 触发条件 |
|------|----------|----------|
| 000 | `git revert` — 骨架纯净，无复杂依赖 | 编译失败或 go.mod 冲突 |
| 001 | 删除接口文件，回退到骨架 commit | 接口签名与下游模块不一致 |
| 002 | 删除 internal/ 子包，恢复 config.go 空实现 | 解析器依赖冲突或 golden test 失败 |
| 003 | 删除 merge.go + internal/merge/，恢复独立 data map | 深度合并逻辑错误导致配置丢失 |
| 004 | 删除 env.go，环境变量覆盖回退为手动处理 | 类型转换 panic 或映射歧义 |
| 005 | 删除 schema.go，关闭 strict mode 回退 | 校验规则过严导致合法配置被拒 |
| 006 | 回退 reader.go 到接口定义版本 | 并发 race 未解决或点分路径 panic |
| 007 | 删除 watch.go，关闭 watch 功能 | fsnotify 依赖问题或回调 goroutine 泄漏 |
| 009 | N/A — 纯文档，`git revert` | 文档内容错误 |
| 010 | 删除 sanitize.go，关闭自动脱敏 | 脱敏逻辑误伤正常字段 |
