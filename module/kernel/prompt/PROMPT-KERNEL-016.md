# TASK-KERNEL-016 开发 Prompt

> 上游 Task：[TASK-KERNEL-016.md](./tasks/TASK-KERNEL-016.md)
> docs/ + CHANGELOG + CI gates + Release preflight

---

## 任务

完成 kernel 模块的文档、变更日志、CI 门禁脚本和发布预检。这是 kernel 发布的最后一步，阻塞 v1.0.0 发布。

## 文件清单

### 1. `CHANGELOG.md`
- 记录 v1.0.0 变更：12 子包初始发布，stdlib-only，零外部依赖

### 2. `docs/adr/`
- ADR-001~006 架构决策记录（来自 DESIGN.md §4）

### 3. `docs/design/`
- 子包设计文档（每子包一页）

### 4. `docs/governance/`
- 治理合规声明（宪法 §0-§19 对齐检查清单）

### 5. `docs/spec/`
- SPEC.md 的同源副本或引用

### 6. `docs/standard/`
- 编码标准（Go 风格、命名约定、注释规范）

### 7. `docs/evidence/`
- 各 Task 的证据产物汇总目录

### 8. `scripts/ci/internal/apisnapshot/`
- API 快照生成和对比脚本

### 9. `release/manifest/`
- 发布清单：版本号、模块路径、文件列表、签名

### 10. `release/dependency/`
- 依赖报告：`go list -deps` 输出

### 11. `release/standard-sync/`
- 标准同步：与 xlib-standard 的合规对照

### 12. `Makefile` 更新
- 添加 `release-preflight` 目标：build + test + vet + lint + stdlib-check + coverage + benchmark + gitleaks

## 验收标准

| AC            | 关联   | 验证命令                                | 预期结果   |
| ------------- | ------ | --------------------------------------- | ---------- |
| AC-018        | BR-009 | `make check-stdlib`                     | 无外部依赖 |
| AC-RELEASE-01 | §22    | CHANGELOG 检查                          | 含 v1.0.0  |
| AC-RELEASE-02 | §22    | `make release-preflight VERSION=v1.0.0` | 全部通过   |
| AC-RELEASE-07 | §20    | `golangci-lint run`                     | 无错误     |
| AC-RELEASE-08 | §20    | `gitleaks detect --no-git`              | 无泄露     |

## 禁止事项

- 不要在 CHANGELOG 中包含未实现的功能
- 不要在 release/manifest 中包含绝对路径
- 不要在 docs/ 中复制 SPEC.md 全文（引用即可）
- 不要包含测试密钥或个人环境路径

## 证据回填

完成后提交到 `docs/evidence/2026-06-12/TASK-KERNEL-016/`：
1. `make release-preflight` 完整输出
2. 覆盖率报告（`go tool cover -func=coverage.out`）
3. Benchmark 结果
4. stdlib-only 检查输出
5. gitleaks 扫描结果

## 验证命令

| 命令                                    | 判定标准              |
| --------------------------------------- | --------------------- |
| `go build ./...`                        | 编译通过，零错误      |
| `go test -race -count=1 ./...`          | 全部测试通过，无 race |
| `go vet ./...`                          | 无警告                |
| `make release-preflight VERSION=v1.0.0` | 全部通过              |
| `golangci-lint run`                     | 无错误                |
| `gitleaks detect --no-git`              | 无泄露                |

## 完成后

1. 运行 `make release-preflight VERSION=v1.0.0` 全部通过
2. 确认所有 17 项 Release DoD（SPEC §22）勾选
3. 更新 TASK-KERNEL-016 状态为 completed
4. kernel v1.0.0 可发布
