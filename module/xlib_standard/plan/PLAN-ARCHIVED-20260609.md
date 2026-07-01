> **⚠️ 归档警告**：本文件是 2026-06-09 的历史执行计划，仅保留供溯源比对。
> 其中"4 项职责"描述基于旧模型，当前权威定义为 CONSTITUTION.md §1.1 P2 和 ARCHITECTURE.md §161 中的**五类职责**：
> Standard Source / Go Reference Template / Generator / Harness Gate / Evidence Runtime。
> 当前执行入口见 `module/xlib_standard/PLAN.md`（根级 PLAN），规格定义见 `module/xlib_standard/goal.md` 和 `module/xlib_standard/SPEC.md`。
> 本文件不得作为当前分析、任务拆分或门禁事实引用。

# xlib_standard v1.0.0 执行计划

> ⚠️ 本文件为上游仓库 Path A 历史执行计划（2026-06-09）。
> 当前 xlib_standard 五类职责（标准事实源、Go Reference Template、Generator、Harness Gate、Evidence Runtime）的完整定位见 `../goal.md`、`../SPEC.md` 和 CONSTITUTION.md P2。
> 本文件描述的 4 项职责是该历史时期的执行范围划分，不代表当前模块定位。
>
> 路径 A：极简方案
> 基于 goal.md 制定

最后更新：2026-06-09

---

## 目标

将 xlib_standard 收敛为最小 Go 基座库模板标准源，只保留 4 项职责：

1. 定义标准（standard.md）
2. 提供可编译的 Go 参考模板（pkg/templatex/）
3. 生成独立基座库（generate 子命令）
4. 最小门禁验证（spec-lint / task-lint / trace-lint）

---

## PR 执行顺序

```text
PR-1 ──→ PR-2 ──→ PR-3 ──→ PR-4 ──→ PR-5
删除       文档       骨架       核心包      release
```

依赖关系：

- PR-2 依赖 PR-1（删除后才能重写文档）
- PR-3 依赖 PR-1（删除后才能重写构建）
- PR-4 依赖 PR-1 + PR-2（需要文档定义的规范）
- PR-5 依赖 PR-3 + PR-4（需要骨架和核心包）
### 子任务依赖拓扑

```text
PR-2 (文档对齐)
  ↓
PR-3 (骨架代码)
  ↓
PR-4a (Config + Version)    ← 2 FR
  ↓
PR-4b (Error + Client)      ← 2 FR
  ↓
PR-4c (Health + Metrics)    ← 2 FR
  ↓
PR-4d (API 模板 + 测试工具)  ← 2 FR
  ↓
PR-5 (Release)
```

**合并顺序**：PR-2 先合并 → PR-3 在 PR-2 基础上创建新文件 → PR-4a~4d 串行合并 → PR-5 最后合并。



---

## PR-1: 删除治理运行时与冗余目录

| 项       | 值                        |
| -------- | ------------------------- |
| 分支     | `feat/xlib-v1-prune`      |
| worktree | `/home/workspace/xlib-standard/.worktree/workspaces/feat/xlib-v1-prune` |
| 任务     | TASK-XLIB-000             |
| 预估     | 0.5h                      |

### 变更文件

删除：

- 目录：`.agent/`, `.codex/`, `.devcontainer/`, `.githooks/`, `.omx/`, `.worktree/`, `.xlib/`
- 目录：`cmd/`, `mk/`, `release/debt/`, `templates/l2/`
- 文件：`.dockerignore`, `Dockerfile`, `docker-compose.yml`
- 文件：`AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `releasemanifest`, `renovate.json`
- 目录：`docs/goal/`, `docs/adr/`

### 验收命令

```bash
test ! -d .agent && test ! -d .codex && test ! -d .devcontainer
test ! -f Dockerfile && test ! -f docker-compose.yml
test ! -f AGENTS.md && test ! -f CLAUDE.md
test -d pkg && test -d contracts && test -d examples && test -d testkit
test -f Makefile
```

---

## PR-2: 文档对齐

| 项       | 值                       |
| -------- | ------------------------ |
| 分支     | `feat/xlib-v1-docs`      |
| worktree | `/home/workspace/xlib-standard/.worktree/workspaces/feat/xlib-v1-docs` |
| 任务     | TASK-XLIB-001            |
| 依赖     | PR-1                     |
| 预估     | 2h                       |

### 变更文件

重写：

- `README.md` — 不超过 200 行，描述 4 项职责
- `docs/standard.md` — 完整标准规范
- `docs/INDEX.md` — 文档索引，仅 9 个文件

### 验收命令

```bash
wc -l README.md | awk '{if ($1 > 200) exit 1}'
grep -q "## 目录结构" docs/standard.md
grep -q "## 命名规则" docs/standard.md
grep -q "## go.mod 规则" docs/standard.md
grep -q "## 错误处理" docs/standard.md
grep -q "## 契约规则" docs/standard.md
grep -q "## 测试规则" docs/standard.md
```

---

## PR-3: 骨架代码

| 项       | 值                        |
| -------- | ------------------------- |
| 分支     | `feat/xlib-v1-build`      |
| worktree | `/home/workspace/xlib-standard/.worktree/workspaces/feat/xlib-v1-build` |
| 任务     | TASK-XLIB-002             |
| 依赖     | PR-1                      |
| 预估     | 2h                        |

### 变更文件

重写：

- `Makefile` — 最小目标集
- `scripts/spec-lint.sh` — SPEC 23 节完整性检查
- `scripts/task-lint.sh` — 任务文件格式检查
- `scripts/trace-lint.sh` — 追溯矩阵一致性检查
- `scripts/selfcheck-100.sh` — 100 次自检
- `.github/workflows/ci.yml` — 最小 CI

### 验收命令

```bash
make -n build && make -n test && make -n lint
test -x scripts/spec-lint.sh
test -x scripts/task-lint.sh
test -x scripts/trace-lint.sh
test -x scripts/selfcheck-100.sh
test -f .github/workflows/ci.yml
```

---

## PR-4: 核心包

| 项       | 值                           |
| -------- | ---------------------------- |
| 分支     | `feat/xlib-v1-packages`      |
| worktree | `/home/workspace/xlib-standard/.worktree/workspaces/feat/xlib-v1-packages` |
| 任务     | TASK-XLIB-003                |
| 依赖     | PR-1 + PR-2                  |
| 预估     | 4h                           |

### 变更文件

重写/新增：

- `pkg/templatex/validator.go` — 校验函数集
- `pkg/templatex/types.go` — 共享类型
- `pkg/templatex/validator_test.go` — 测试
- `contracts/contracts.go` — 最小契约示例
- `examples/main.go` — 最小可运行示例
- `testkit/testkit.go` — 测试辅助工具

### 验收命令

```bash
go build ./...
go test ./... -race
go vet ./...
cd examples && go run main.go
```

---

## PR-5: release 标准

| 项       | 值                          |
| -------- | --------------------------- |
| 分支     | `feat/xlib-v1-release`      |
| worktree | `/home/workspace/xlib-standard/.worktree/workspaces/feat/xlib-v1-release` |
| 任务     | TASK-XLIB-004               |
| 依赖     | PR-3 + PR-4                 |
| 预估     | 1h                          |

### 变更文件

新增：

- `pkg/templatex/release.go` — Release manifest 生成
- `pkg/templatex/compat.go` — Semver 兼容性矩阵
- `pkg/templatex/release_test.go` — 测试
- `pkg/templatex/compat_test.go` — 测试

### 验收命令

```bash
go build ./...
go test ./... -race
```

---

## Worktree 操作流程

每个 PR 的标准流程：

```bash
# 1. 创建 worktree
git fetch origin && git worktree add /home/workspace/xlib-standard/.worktree/workspaces/feat/xlib-v1-xxx -b feat/xlib-v1-xxx origin/main

# 2. 进入 worktree
cd /home/workspace/xlib-standard/.worktree/workspaces/feat/xlib-v1-xxx

# 3. 执行变更（按 Context Packet）

# 4. 验证
make lint && make test

# 5. 提交
git add -A && git commit -m "feat(xlib_standard): PR-N 描述"

# 6. 推送 & PR
git push -u origin feat/xlib-v1-xxx
gh pr create --base main --head feat/xlib-v1-xxx --title "feat(xlib_standard): PR-N 描述"

# 7. 合并后清理
cd /home/workspace/xlib-standard
git worktree remove /home/workspace/xlib-standard/.worktree/workspaces/feat/xlib-v1-xxx
git branch -d feat/xlib-v1-xxx
```

---

## 最终验收清单

全部 PR 合并后：

- [ ] `go build ./...` 通过
- [ ] `go test ./... -race` 通过
- [ ] `go vet ./...` 通过
- [ ] `make spec-lint` 通过
- [ ] `make task-lint` 通过
- [ ] `make trace-lint` 通过
- [ ] `bash scripts/selfcheck-100.sh` 0 失败
- [ ] 生成的库可编译
- [ ] 生成的库通过 spec-lint
- [ ] README 不超过 200 行
- [ ] 打 tag `v1.0.0`

---

## 最终目标

做完后我们将拥有：一个最小、可编译、有门禁的 Go 基座库模板标准源，可被下游模块引用生成独立基座库。
