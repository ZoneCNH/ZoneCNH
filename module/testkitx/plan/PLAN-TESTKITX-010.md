# PLAN-TESTKITX-010

> 文档 + Release DoD 实现计划
>
> 对应 Task：`module/testkitx/tasks/TASK-TESTKITX-010.md`
> 对应 Spec：`module/testkitx/SPEC.md#22` (Release DoD), `SPEC.md#18` (Observability), `SPEC.md#17` (Performance Budget)

---

## 1. Task 摘要

```yaml
task_id: TASK-TESTKITX-010
scope: "创建 README、CHANGELOG、example_test.go、benchmark_test.go，验证 Release DoD"
priority: P1
estimated_effort: "2h"
depends_on: [TASK-TESTKITX-001 ~ 009]
blocks: []
```

---

## 2. 覆盖需求

| 需求     | 描述               | AC                |
| -------- | ------------------ | ----------------- |
| SPEC §22 | Release DoD        | 全部条目通过      |
| SPEC §17 | Performance Budget | fake 初始化 < 1ms |
| SPEC §18 | Observability      | FakeExporter 可用 |
| NFR-002  | 覆盖率 >= 80%      | CI gate           |
| NFR-003  | 并发安全           | `-race` 通过      |

---

## 3. Release DoD 清单

- [ ] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码（example_test.go）
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、API 概览
- [ ] 单元测试覆盖率 >= 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] 所有 contract test 通过
- [ ] no-production-import 检查通过
- [ ] Go baseline 与 Foundation 对齐（1.23）
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更
- [ ] 所有 Functional Requirements 有对应测试
- [ ] 所有 Edge Cases 有对应测试

---

## 4. 实现步骤

### Step 1: 创建 README.md

**目标文件**：`README.md`

**内容要点**：
- 模块定位：Foundation L1 test-only 工具包
- 快速开始：3 行代码示例展示核心用法
- API 概览：Fake 类型表 + 辅助工具表 + 使用示例
- 禁止生产导入警告
- 中文撰写，技术术语保留英文

### Step 2: 创建 CHANGELOG.md

**目标文件**：`CHANGELOG.md`

**内容要点**：
- v1.0.0 初始版本
- 列出所有 fake 类型和辅助工具
- 遵循 [Keep a Changelog](https://keepachangelog.com/) 格式

### Step 3: 创建 example_test.go

**目标文件**：`example_test.go`

**示例内容**：
- `Example_fakeConfig`：FakeConfig 基本用法
- `Example_fakeLogger`：FakeLogger + AssertLogged
- `Example_fakeClock`：FakeClock + Advance
- `Example_eventually`：Eventually 轮询断言
- `Example_goldenUpdate`：GoldenUpdate + GoldenAssert
- `Example_boundaryCheck`：BoundaryCheck 边界扫描
- `Example_goroutineLeakCheck`：GoroutineLeakCheck 泄漏检测
- `Example_composition`：FakeConfig + FakeLogger + Eventually 组合使用

### Step 4: 创建 benchmark_test.go

**目标文件**：`benchmark_test.go`

**Benchmark 场景**：

| Benchmark                     | 描述                | 目标   |
| ----------------------------- | ------------------- | ------ |
| BenchmarkFakeConfig_Init      | FakeConfig 初始化   | < 1ms  |
| BenchmarkFakeLogger_Init      | FakeLogger 初始化   | < 1ms  |
| BenchmarkFakeMeter_Init       | FakeMeter 初始化    | < 1ms  |
| BenchmarkFakeTracer_Init      | FakeTracer 初始化   | < 1ms  |
| BenchmarkFakeClock_Init       | FakeClock 初始化    | < 1ms  |
| BenchmarkEventually_Immediate | Eventually 立即满足 | < 1ms  |

**注意**：所有 benchmark 使用 `-benchmem` 报告内存分配。

### Step 5: 代码质量检查

**执行以下检查并修复所有问题**：

```bash
# godoc 完整性
go doc -all . | grep -E "^func |^type " | wc -l

# 编译
go build ./...

# 测试
go test ./... -race -count=1

# vet
go vet ./...

# lint
golangci-lint run

# 覆盖率
mkdir -p .coverage
go test ./... -coverprofile=.coverage/cover.out
go tool cover -func=.coverage/cover.out | grep total

# 依赖整洁
go mod tidy && git diff --exit-code go.mod go.sum

# secret 扫描
gitleaks detect --no-git

# contract 测试
go test ./contract/... -race -count=1

# benchmark
go test -bench=. -benchmem -count=3 ./...
```

### Step 6: 覆盖率不足时的补救

如果覆盖率 < 80%：
1. 运行 `go tool cover -html=.coverage/cover.out` 查看未覆盖区域
2. 优先补充 Edge Cases（SPEC §13）的测试
3. 补充错误路径测试
4. 重新运行覆盖率检查

---

## 5. 验证汇总

```bash
# 全量 CI gate（一次性运行所有验证）
go build ./... && \
go test ./... -race -count=1 && \
go vet ./... && \
golangci-lint run && \
mkdir -p .coverage && go test ./... -coverprofile=.coverage/cover.out && \
go tool cover -func=.coverage/cover.out | awk '/total:/ {if ($3+0 < 80) exit 1}' && \
go mod tidy && git diff --exit-code go.mod go.sum && \
gitleaks detect --no-git && \
go test ./contract/... -race -count=1 && \
go test -bench=. -benchmem -count=3 ./...
```

**通过标准**：全部命令返回 0。

**覆盖率底线**：`go tool cover -func=.coverage/cover.out | grep total` 显示 `>= 80.0%`。

---

## 6. 风险与回滚

| 风险                           | 概率   | 影响   | 缓解                     | 回滚                     |
| ------------------------------ | ------ | ------ | ------------------------ | ------------------------ |
| 覆盖率不达标 (< 80%)           | Medium | Medium | Step 6 补救流程          | 补充边界场景测试         |
| golangci-lint 新增规则导致失败 | Low    | Medium | 锁定 golangci-lint 版本  | 修复 lint 问题或配置排除 |
| Benchmark 回退                 | Low    | Low    | 与基线对比               | 优化热点路径             |
| example_test.go 命名不规范     | Low    | Low    | 遵循 Go example 命名约定 | 修正函数名               |

**回滚路径**：本 task 修改多个文件，回滚建议逐文件处理。核心代码文件（fake_*.go 等）不在本 task 范围内，仅 `README.md`、`CHANGELOG.md`、`example_test.go`、`benchmark_test.go` 属于本 task。
