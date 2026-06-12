# kernel 实现计划

> 来源：[SPEC.md](./SPEC.md) v2.0.0
> 生成日期：2026-06-12
> 替换：旧 IMPLEMENTATION-PLAN.md（基于已废弃的 SPEC v1.1.0 集中式架构）

---

## 1. 依赖 DAG

```text
TASK-KERNEL-000 (项目骨架: go.mod, README, Makefile)
│
├── TASK-KERNEL-001 (errx) ─────────────────────────────┐
├── TASK-KERNEL-002 (timex) ────────────────────────────┤
├── TASK-KERNEL-003 (obsx)                              │
├── TASK-KERNEL-004 (syncx)                             │
├── TASK-KERNEL-005 (lifecycx)                          │
├── TASK-KERNEL-006 (shutdownx)                         │
├── TASK-KERNEL-007 (versionx)                          │
│                                                       │
├── TASK-KERNEL-008 (validx) ──→ errx                   │
├── TASK-KERNEL-009 (retryx) ──→ errx                   │
├── TASK-KERNEL-010 (contextx) → timex                  │
├── TASK-KERNEL-011 (healthx) ──→ timex                 │
│                                                       │
├── TASK-KERNEL-012 (contracttest) → errx + healthx     │
│                                                       │
├── TASK-KERNEL-013 (internal/testutil)                 │
│                                                       │
├── TASK-KERNEL-014 (contracts: API snapshot + golden)  │
├── TASK-KERNEL-015 (examples: 12 子包可运行示例)        │
│                                                       │
└── TASK-KERNEL-016 (CI gates + release preflight)      │
```

---

## 2. 实现顺序

### Phase 1: 骨架（1 task，阻塞全部）

| Task | 文件 | 依赖 | Effort |
|------|------|------|--------|
| TASK-KERNEL-000 | go.mod, Makefile, README.md, LICENSE | — | 0.5h |

### Phase 2: 无内部依赖子包（7 tasks，全部可并行）

| Task | 子包 | 文件 | 依赖 | Effort |
|------|------|------|------|--------|
| TASK-KERNEL-001 | errx | errx/errx.go, errx_test.go, example_test.go | 000 | 2h |
| TASK-KERNEL-002 | timex | timex/timex.go, timex_test.go, example_test.go | 000 | 1.5h |
| TASK-KERNEL-003 | obsx | obsx/obsx.go, obsx_test.go, example_test.go | 000 | 2h |
| TASK-KERNEL-004 | syncx | syncx/syncx.go, syncx_test.go, example_test.go | 000 | 2h |
| TASK-KERNEL-005 | lifecycx | lifecycx/lifecycx.go, lifecycx_test.go, example_test.go | 000 | 2h |
| TASK-KERNEL-006 | shutdownx | shutdownx/shutdownx.go, shutdownx_test.go, example_test.go | 000 | 2h |
| TASK-KERNEL-007 | versionx | versionx/versionx.go, versionx_test.go, example_test.go | 000 | 1h |

**Phase 2 并行度：7**（全部无互相依赖）

### Phase 3: 有内部依赖子包（4 tasks，可部分并行）

| Task | 子包 | 依赖 | 内部依赖 | Effort |
|------|------|------|----------|--------|
| TASK-KERNEL-008 | validx | 000 | 001 (errx) | 1h |
| TASK-KERNEL-009 | retryx | 000 | 001 (errx) | 1.5h |
| TASK-KERNEL-010 | contextx | 000 | 002 (timex) | 1.5h |
| TASK-KERNEL-011 | healthx | 000 | 002 (timex) | 1.5h |

**Phase 3 并行度：4**（互相无依赖，仅依赖 Phase 2 中的不同子包）

### Phase 4: 多层依赖子包（1 task）

| Task | 子包 | 依赖 | Effort |
|------|------|------|--------|
| TASK-KERNEL-012 | contracttest | 001 (errx), 011 (healthx) | 1h |

### Phase 5: 内部工具（1 task）

| Task | 子包 | 依赖 | Effort |
|------|------|------|--------|
| TASK-KERNEL-013 | internal/testutil | 000 | 0.5h |

### Phase 6: 契约验证层（1 task）

| Task | 内容 | 依赖 | Effort |
|------|------|------|--------|
| TASK-KERNEL-014 | contracts/：API 快照、golden 行为、消费者导入测试 | 001~012 | 3h |

### Phase 7: 示例和文档（4 tasks，可并行）

| Task | 内容 | 依赖 | Effort |
|------|------|------|--------|
| TASK-KERNEL-015a | examples/ Group A：lifecycx/errx/healthx/obsx | 001,003,005,011 | 0.75h |
| TASK-KERNEL-015b | examples/ Group B：retryx/shutdownx/syncx/timex | 002,004,006,009 | 0.75h |
| TASK-KERNEL-015c | examples/ Group C：validx/versionx/contextx/contracttest | 007,008,010,012 | 0.75h |
| TASK-KERNEL-016 | CHANGELOG.md, docs/, CI gates, release preflight | 014, 015a, 015b, 015c | 2h |

---

## 3. 关键路径

```text
000 → 001 (errx) → 008 (validx) ─┐
                                  ├→ 012 (contracttest) → 014 (contracts) → 016 (release)
000 → 002 (timex) → 011 (healthx) ┘
```

**关键路径工期**：0.5 + 2 + 1.5 + 1 + 3 + 2 = **10h**

---

## 4. 并行策略

### Phase 2（最大并行度 7）

errx / timex / obsx / syncx / lifecycx / shutdownx / versionx 七个子包全部无内部依赖，可同时开发。

### Phase 3（并行度 4）

validx / retryx / contextx / healthx 互相无依赖，可同时开发。仅需各自依赖的 Phase 2 子包先行完成。

### Phase 7（并行度 3）

015a/015b/015c 互相无依赖，可同时开发。016 依赖 015a/b/c 全部完成。

---

## 5. 文件冲突分析

由于每个子包有独立目录，Phase 2+3+4 的任务之间 **无文件冲突**：

| 文件 | 创建 Task | 冲突风险 |
|------|-----------|----------|
| go.mod | 000 | 无 |
| errx/*.go | 001 | 无 |
| timex/*.go | 002 | 无 |
| obsx/*.go | 003 | 无 |
| syncx/*.go | 004 | 无 |
| lifecycx/*.go | 005 | 无 |
| shutdownx/*.go | 006 | 无 |
| versionx/*.go | 007 | 无 |
| validx/*.go | 008 | 无 |
| retryx/*.go | 009 | 无 |
| contextx/*.go | 010 | 无 |
| healthx/*.go | 011 | 无 |
| contracttest/*.go | 012 | 无 |
| internal/testutil/*.go | 013 | 无 |
| contracts/* | 014 | 无 |
| examples/* | 015 | 无 |
| CHANGELOG.md, docs/* | 016 | 无 |
| README.md | 000 (创建), 016 (更新) | ⚠️ 顺序执行 |
| Makefile | 000 (创建), 016 (更新) | ⚠️ 顺序执行 |

---

## 6. 测试策略

| 测试类型 | 覆盖 Task | 工具 |
|----------|-----------|------|
| 单元测试 | 001~013 | `go test -race -count=1 ./...` |
| Example 测试 | 001~013 | `go test -run Example ./...` |
| 契约测试 | 014 | `go test -race ./contracts/...` |
| Benchmark | 001, 002, 009, 011 | `go test -bench=. -benchmem -count=3 ./...` |
| stdlib-only | ALL | CI gate |
| 覆盖率 | ALL | `go tool cover` ≥ 80% |
| Race 检测 | ALL | `go test -race -count=1 ./...` |

---

## 7. 风险与缓解（量化）

| 风险 | 概率 | 影响 | 风险值 | 缓解 | 检测方式 | 触发修复 |
|------|:----:|:----:|:------:|------|----------|----------|
| errx.IsKind 多链性能不达标 | 15% | High | 0.45 | Phase 2 benchmark < 1μs | CI benchmark regression | 优化 walkErrors 算法 |
| FakeClock 并发安全问题 | 20% | High | 0.60 | sync.Mutex + -race 测试 | `-race` CI gate | 修复 mutex 粒度 |
| SecretString 反射绕过 | 10% | Critical | 0.30 | 四路径覆盖测试 | Golden behavior test | 增加保护层 |
| WorkerGroup cancel 传播竞争 | 25% | Medium | 0.50 | 充分并发测试 + timeout | 3× -race 验证 | 修复 errgroup 同步 |
| stdlib-only 被破坏 | 5% | Critical | 0.15 | CI gate `go list -deps` | Blocking CI gate | 移除违规 import |
| 接口设计不满足下游 | 30% | Medium | 0.60 | Phase 6 consumer import test | Consumer test 失败 | 接口调整 → minor bump |
| 跨子包循环依赖 | 10% | Critical | 0.30 | Phase 2 即验证内部依赖图 | `go build ./...` 编译失败 | 重构依赖方向 |
| SemaphoreLimiter 死锁 | 15% | High | 0.45 | ctx 感知 Acquire + timeout 测试 | Deadlock detector | 增加 ctx 取消路径 |

## 8. 回滚策略（全子包覆盖）

### lifecycx (TASK-005)
| 场景 | 回滚步骤 |
|------|----------|
| Start 第 k 个失败 | 逆序 Stop 前 k-1 个 → errors.Join 聚合 |
| Stop 某 Component 超时 | 继续 Stop 后续 → 记录超时 Component 名 |
| Stop panic | recover → 记录 → 继续 Stop 后续 |

### errx (TASK-001)
| 场景 | 回滚步骤 |
|------|----------|
| walkErrors 死循环 | 最大深度限制 100 → 返回 false |
| IsKind nil 参数 | 安全返回 false |
| errors.Join 空列表 | AsError 返回 (nil, false) |

### timex (TASK-002)
| 场景 | 回滚步骤 |
|------|----------|
| FakeClock.Advance 负值 | 静默忽略 |
| nil *FakeClock.Now() | 返回 time.Time{} |
| FakeClock 并发 Advance | mutex 保护，无数据竞争 |

### obsx (TASK-003)
| 场景 | 回滚步骤 |
|------|----------|
| NoopLogger 被 nil 调用 | 空结构体接收者，不 panic |
| SecretString 空值 Reveal | 返回 "" |

### syncx (TASK-004)
| 场景 | 回滚步骤 |
|------|----------|
| SemaphoreLimiter double-release | 静默忽略 |
| WorkerGroup closed 后 TryGo | 返回 false |
| Acquire ctx 取消 | 返回 ctx.Err() |

### shutdownx (TASK-006)
| 场景 | 回滚步骤 |
|------|----------|
| Hook Shutdown 超时 | context 超时 → 继续下一个 Hook |
| Hook panic | recover → 记录 → 继续下一个 |
| 并发 Register+Shutdown | mutex 快照 → 后续 Register 不执行 |

### healthx (TASK-011)
| 场景 | 回滚步骤 |
|------|----------|
| Aggregate 空 statuses | 返回 {Status:"healthy", Message:"ok"} |
| AggregateWithClock clock=nil | 回退到 RealClock |
| Metadata nil JSON | 序列化为 {} 而非 null |

### retryx (TASK-009)
| 场景 | 回滚步骤 |
|------|----------|
| Delay attempt <= 0 | 返回 0 |
| Delay 溢出 | maxDuration 保护 |
| Jitter 结果 < 0 | 返回 0 |

### validx (TASK-008)
| 场景 | 回滚步骤 |
|------|----------|
| Precondition/Invariant 在任何输入下 | 始终返回 error 或 nil，不 panic |

### contextx (TASK-010)
| 场景 | 回滚步骤 |
|------|----------|
| 零值 Key contextKey() | panic（设计意图：fail-fast） |
| Value 类型不匹配 | 返回 (zero, false) |

### versionx (TASK-007)
| 场景 | 回滚步骤 |
|------|----------|
| Compatibility.Major 为空 | 仅校验 Module |
| 空 BuildInfo | CompatibleWith 返回 false |

### contracttest (TASK-012)
| 场景 | 回滚步骤 |
|------|----------|
| AssertJSONFields nil value | Fatalf 报告 |
| AssertErrorKind nil err | 视为不匹配 → Fatalf |

## 9. 总工时估算

| Phase | Tasks | 串行 Effort | 并行 Effort |
|-------|-------|-------------|-------------|
| Phase 1 | 1 | 0.5h | 0.5h |
| Phase 2 | 7 | 12h | 2h (并行) |
| Phase 3 | 4 | 5.5h | 1.5h (并行) |
| Phase 4 | 1 | 1h | 1h |
| Phase 5 | 1 | 0.5h | 0.5h |
| Phase 6 | 1 | 3h | 3h |
| Phase 7 | 2 | 4h | 2h (并行) |
| **总计** | **17** | **26.5h** | **~10.5h** (充分利用并行) |
