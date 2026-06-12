# TASK-KERNEL-014 开发 Prompt

> 上游 Task：[TASK-KERNEL-014.md](./tasks/TASK-KERNEL-014.md)
> contracts/：契约验证层 — API 快照 + Golden 行为 + 消费者导入测试

---

## 任务

实现 `kernel/contracts/` 契约验证层。确保公开 API 签名稳定、行为 golden 可回归、消费者可独立导入 kernel 子包。

## 文件清单

### 1. `contracts/contracts_test.go`
- 公共 API 快照对比：`go list -f '{{.Name}} {{.Doc}}' ./...` 输出与快照文件对比

### 2. `contracts/api_docs_test.go`
- 验证所有公开类型/函数有 godoc 注释

### 3. `contracts/golden_behavior_test.go`
- 关键行为 golden 测试（errx.Error() 格式、healthx.Aggregate 输出、retryx.Delay 结果）

### 4. `contracts/release_docs_ci_test.go`
- 验证 CHANGELOG.md 存在、README.md 含 12 子包清单、LICENSE 存在

### 5. `contracts/consumers/xgo/minimal_import_test.go`
- 验证 x.go 可以独立导入 kernel 各子包（最小导入路径测试）

## 验收标准

| AC              | 关联   | 验证命令                 | 预期结果   |
| --------------- | ------ | ------------------------ | ---------- |
| AC-CONTRACTS-01 | §20.2  | public-api-snapshot gate | 通过       |
| AC-CONTRACTS-02 | §20.2  | golden-behavior gate     | 通过       |
| AC-CONTRACTS-03 | §22    | 消费者导入测试           | 通过       |

## 禁止事项

- 不要在 contracts 中实现业务逻辑
- golden 文件不要包含随机值/时间戳
- 消费者导入测试不要依赖 testkitx

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-014/`：
1. `go test -race -count=1 ./contracts/...` 输出
2. API 快照对比 diff（如有变更）
3. Golden 行为测试结果

## 验证命令

| 命令                                     | 判定标准              |
| ---------------------------------------- | --------------------- |
| `go build ./contracts/...`               | 编译通过，零错误      |
| `go test -race -count=1 ./contracts/...` | 全部测试通过，无 race |
| `go vet ./contracts/...`                 | 无警告                |

## 完成后

1. 运行 `go test -race -count=1 ./contracts/...` 确认通过
2. 更新 API 快照（如有合法变更）
3. 更新 TASK-KERNEL-014 状态为 completed
