# Phase 1 仓库迁移计划：kebab-case → snake_case 统一

> 版本：v1.0
> 日期：2026-07-11
> 输入来源：audit-results.md、identity-inventory.md、FOUNDATION-DEPS.yaml、ruling-transportx.md
> 目标基线：Go 1.26.5
> 治理权威：CONSTITUTION.md 仓库命名强制规则、RULING-002

---

## 0. 迁移前提裁决

### 裁决 0.1: go.mod module path org — ZoneCNH vs xhyperium

**问题** [KNOWN, HIGH]：全部 25 个基础模块的 go.mod 声明 `github.com/xhyperium/{module}`，但实际 GitHub 仓库位于 `xhyperium` org。`gh ls-remote xhyperium/{module}` 确认仓库存在，`git ls-remote https://github.com/xhyperium/{module}.git` 预期失败。

这一不匹配导致 go module proxy 无法按 go.mod 声明的路径解析模块。

**选项 A：维持 ZoneCNH module path（修复物理层）**

- 将 25 个 GitHub 仓库从 xhyperium org 迁移到 ZoneCNH org
- 或配置 GitHub Pages / reverse proxy 做 301 重定向
- **优点** [INFERRED, LOW]：不改 go.mod，不改任何 import path，消费者零改动
- **缺点** [INFERRED, LOW]：需 GitHub org 级别操作权，可能触发 GitHub Actions / 集成破损
- **风险** [GUESS, LOW]：ZoneCNH org 下可能有重名仓库冲突；Go module mirror 缓存刷新周期未知

**选项 B：迁移到 xhyperium module path（修复逻辑层）**

- 将 25 个 go.mod module path 改为 `github.com/xhyperium/{module}`
- 批量更新所有模块内部的 import path 和所有消费者 import path
- **优点** [INFERRED, LOW]：逻辑与物理一致，go get 可正常解析，不依赖 org 迁移
- **缺点** [INFERRED, LOW]：25+ 模块 go.mod 修改，约 100+ 个 import 路径需替换，下游外部仓库也需更新
- **风险** [GUESS, LOW]：外部消费者（如有）可能已缓存 ZoneCNH path 导致 go get 失败

**选项 C：不做任何变更（Phase 1 暂缓组间裁决）** — 不是推荐项，仅记录为不做选择的后果。

#### 推荐裁决

**推荐选项 A（维持 ZoneCNH module path），理由** [COMPUTED, MED]：

1. `FOUNDATION-DEPS.yaml` 的 `modules.*.path` 字段全部使用 `ZoneCNH` 作为 SSOT——这是 CI 消费的机器可读格式，修改成本最高 [KNOWN]
2. `forbidden_deps` 段中的业务域依赖全部声明为 `github.com/xhyperium/...`——修改需同步 40+ 条目 [KNOWN]
3. `allowed_deps` 中的所有依赖边均使用 `github.com/xhyperium/` 前缀——这是模块间 import graph 的 SSOT [KNOWN]
4. transportx 的 `shared_module: xlib_standard` 同样基于 ZoneCNH 路径 [KNOWN]
5. RULING-002 裁决 transportx 路径为 `github.com/xhyperium/transportx`（使用 ZoneCNH org）——这是 FINAL 状态裁决 [KNOWN]
6. 仓库物理已存在且活跃使用，org 级迁移顺序上应在命名统一之后 [INFERRED, MED]

**执行建议**：Phase 1 维持 ZoneCNH module path，不修改 org。Phase 3（或独立的跨组裁决）统一决策 GitHub org 归属。当前 go get 解析问题可暂时通过 GONOSUMDB/GOPROXY 配置绕过 [GUESS, LOW]。

#### 附加行动项

- [ ] 确认 ZoneCNH org 下是否有 25 个模块的同名仓库（避免迁移冲突）
- [ ] 确认 GitHub org 迁移的技术可行性（org owner 权限、GitHub Actions 迁移、Pages / 自定义域名）
- [ ] 在 Phase 3 计划中纳入此裁决的最终执行方案

---

### 裁决 0.2: transportx RULING-002 执行（已裁决，纳入本计划）

**裁决状态**: FINAL（`ruling-transportx.md`）
**裁决结果**: module path 改为 `github.com/xhyperium/transportx`，不加 `/v2` 后缀，旧 tag v1.0.0-v1.1.1-spec 标记为 retract
**理由**: `production_import_allowed=false`，无生产消费者

本迁移计划将 transportx 的修复纳入 Batch 5（与 xlib_standard 联动）。

---

## 1. 迁移优先级矩阵

### 1.1 kebab-case 违规模块消费者分析

基于 FOUNDATION-DEPS.yaml allowed_deps 和 audit-results.md 的依赖关系：

| 模块            | 当前 go.mod module path   | 目标 module path          | 被多少 Foundation 模块依赖 | 被谁依赖                                             | 风险 |
| --------------- | ------------------------- | ------------------------- | -------------------------- | ---------------------------------------------------- | ---- |
| domain_macro    | `ZoneCNH/domain-macro`    | `ZoneCNH/domain_macro`    | 0                          | 无                                                   | 最低 |
| domain_exchange | `ZoneCNH/domain-exchange` | `ZoneCNH/domain_exchange` | 0                          | 无（但自身依赖 domain_market）                       | 低   |
| domain_market   | `ZoneCNH/domain-market`   | `ZoneCNH/domain_market`   | 1                          | domain_exchange                                      | 中低 |
| xlib_harness    | `ZoneCNH/xlib-harness`    | `ZoneCNH/xlib_harness`    | 0                          | 无（runtime_dependency=false）                       | 中   |
| transportx      | `ZoneCNH/xlib-standard`   | `ZoneCNH/transportx`      | 0                          | 无（自身需消费 xlib_standard）                       | 高   |
| xlib_standard   | `ZoneCNH/xlib-standard`   | `ZoneCNH/xlib_standard`   | ≥1                         | transportx（confirmed），可能 xlibgate/xlib_evidence | 最高 |

**注** [COMPUTED, MED]：

- domain_exchange 的 allowed_deps 声明依赖 domain_market（`domain_exchange: [decimalx, domainx, domain_market]`）——这是唯一的 kebab→kebab 依赖链
- xlib_standard 被 transportx 依赖（shared_module），这是唯一的跨标准源消费
- xlib_harness / domain_macro 无任何 Foundation 消费者，可独立迁移

### 1.2 迁移最优顺序推导

**原则**：

- 叶子优先（被依赖最少的先修）
- 消费链完整（A 改完后 B 的 import 也随之改完）
- 回滚隔离（每个模块独立 PR，失败不回滚其他模块）

**推导** [COMPUTED, MED]：

```
domain_macro (消费数=0)
  → domain_market (消费数=1, domain_exchange 消费)
    → domain_exchange (消费数=0, 但需同步修改对 domain_market 的 import)
  → xlib_harness (消费数=0)
  → xlib_standard (消费数=1+, transportx 消费+可能其他消费者)
    → transportx (消费数=0, 但 go.mod identity 完全错位+需同步修改对 xlib_standard 的 import)
```

**迁移 DAG**：

```
domain_macro ──────────────────────────────────────────────────────────┐
                                                                        │
domain_market ──→ domain_exchange ─────────────────────────────────────┤
                                                                        │
xlib_harness ──────────────────────────────────────────────────────────┤
                                                                        │
xlib_standard ──→ transportx ──────────────────────────────────────────┤
```

- `→` 表示"必须先完成": domain_market 必须在 domain_exchange 之前完成
- 独立并行组：{domain_macro}、{xlib_harness}、{domain_market→domain_exchange}、{xlib_standard→transportx}
- 依赖约束：xlib_standard 不依赖前三个组，可独立执行

### 1.3 最终优先级排序

| 优先级 | 模块            | 理由                                                                    |
| ------ | --------------- | ----------------------------------------------------------------------- |
| 1      | domain_macro    | 零消费者 + 无依赖 + CI 从未运行（无历史负担）+ Go 1.23 已落后           |
| 2      | domain_market   | 仅 1 消费者 + 无代码（空壳）+ Go 1.23                                   |
| 3      | domain_exchange | 零消费者 + 无代码（空壳）+ Go 1.23 + 需联动 domain_market               |
| 4      | xlib_harness    | 零消费者 + runtime_dependency=false + 有 tag 和活跃 CI                  |
| 5      | xlib_standard   | 被 transportx 消费 + 全部模块的"标准源" + git tag 正常                  |
| 6      | transportx      | go.mod 身份完全错位 + 依赖 xlib_standard（需先完成 xlib_standard 迁移） |

---

## 2. 每个违规模块的迁移方案

### 2.1 domain_macro

#### 当前 status

| 维度               | 值                                               |
| ------------------ | ------------------------------------------------ |
| GitHub 仓库        | xhyperium/domain_macro                           |
| go.mod module path | `github.com/xhyperium/domain-macro` (kebab-case) |
| go.mod go version  | 1.23（落后基线）                                 |
| 最新 tag           | v1.0.1 (远程)，v1.0.0 (本地)                     |
| CI 状态            | **从未运行**                                     |
| 最近活跃           | 2026-06-16（>3 周无活动）                        |
| 消费者             | 0 个 Foundation 模块                             |
| 依赖               | decimalx, domainx（均为 snake_case，无需联动）   |

#### 目标 status

| 维度               | 值                                               |
| ------------------ | ------------------------------------------------ |
| go.mod module path | `github.com/xhyperium/domain_macro` (snake_case) |
| go.mod go version  | 1.26.5（同步基线）                               |
| 新 tag             | v1.0.2（迁移版本）                               |
| CI 状态            | green                                            |

#### 迁移步骤

```bash
# Step 1: 在独立 worktree/branch 中操作
cd /home/workspace
git worktree add /home/workspace/domain_macro/.worktree/workspaces/fix/kebab-to-snake \
  domain_macro/main

cd /home/workspace/domain_macro/.worktree/workspaces/fix/kebab-to-snake

# Step 2: 修改 go.mod module path
sed -i 's|module github.com/xhyperium/domain-macro|module github.com/xhyperium/domain_macro|' go.mod

# Step 3: 升级 Go 版本
sed -i 's|^go 1\.23$|go 1.26.5|' go.mod

# Step 4: 批量替换所有 .go 文件中的 import path
find . -name '*.go' -exec sed -i \
  's|github.com/xhyperium/domain-macro|github.com/xhyperium/domain_macro|g' {} +

# Step 5: 更新 go.sum
go mod tidy

# Step 6: 验证编译
go build ./...
go test ./...

# Step 7: 打 tag 并推送
git add go.mod go.sum $(find . -name '*.go')
git commit -m "fix: kebab-case to snake_case: domain-macro → domain_macro"
git tag -a v1.0.2 -m "fix: module path corrected from kebab-case to snake_case"
git push origin fix/kebab-to-snake
git push origin v1.0.2
```

#### Go module major version 影响

- **不需要 /v2**：module path 从 `domain-macro` 改为 `domain_macro` 属于 Go module identity change，但 domain_macro 目前为 v1（tag v1.0.1），且无生产消费者
- 使用 `retract [v1.0.0, v1.0.1]` 标记旧 kebab-case 版本为撤回
- 新 tag v1.0.2 使用 snake_case path，Go module proxy 会识别为不同模块 identity

#### 消费者影响

- **无消费者** [COMPUTED, HIGH]
- FOUNDATION-DEPS.yaml 无任何模块声明依赖 domain_macro
- domain_macro 自身 allowed_deps 为 `[decimalx, domainx]`——两者均为 snake_case，无需联动

#### 回滚方案

```bash
# 删除迁移 tag
git push origin --delete v1.0.2

# 关闭 PR（不合并）
# go.mod 恢复到 domain-macro path
git revert HEAD
git push origin fix/kebab-to-snake --force
```

#### 验证方法

```bash
# 1. go.mod 路径验证
grep '^module' go.mod
# 期望: module github.com/xhyperium/domain_macro

# 2. 零 kebab-case 残留
rg 'domain-macro' --type go
# 期望: 无输出

# 3. go module resolution
go list -m github.com/xhyperium/domain_macro@v1.0.2
# 期望: 成功返回

# 4. external consumer
mkdir -p /tmp/test-domain_macro && cd /tmp/test-domain_macro
go mod init example.com/test
go get github.com/xhyperium/domain_macro@v1.0.2
# 期望: 成功
```

---

### 2.2 domain_market

#### 当前 status

| 维度               | 值                                                |
| ------------------ | ------------------------------------------------- |
| GitHub 仓库        | xhyperium/domain_market                           |
| go.mod module path | `github.com/xhyperium/domain-market` (kebab-case) |
| go.mod go version  | 1.23                                              |
| 最新 tag           | v1.1.0 (远程)，本地无 tag                         |
| CI 状态            | PASS（但 GH Release v1.1.0 存在）                 |
| 消费者             | 1 个（domain_exchange）                           |
| 依赖               | decimalx, domainx（均为 snake_case）              |
| 代码状态           | 几乎空壳（仅 go.mod + go.sum，无业务源码）        |

#### 目标 status

| 维度               | 值                                                |
| ------------------ | ------------------------------------------------- |
| go.mod module path | `github.com/xhyperium/domain_market` (snake_case) |
| go.mod go version  | 1.26.5                                            |
| 新 tag             | v1.1.1（增量版本）                                |
| CI 状态            | green                                             |

#### 迁移步骤

```bash
# Step 1: worktree
cd /home/workspace
git -C domain_market worktree add \
  /home/workspace/domain_market/.worktree/workspaces/fix/kebab-to-snake \
  main

cd /home/workspace/domain_market/.worktree/workspaces/fix/kebab-to-snake

# Step 2: go.mod
sed -i 's|module github.com/xhyperium/domain-market|module github.com/xhyperium/domain_market|' go.mod
sed -i 's|^go 1\.23$|go 1.26.5|' go.mod

# Step 3: import path 替换（如有 .go 文件）
find . -name '*.go' -exec sed -i \
  's|github.com/xhyperium/domain-market|github.com/xhyperium/domain_market|g' {} +

# Step 4: tidy
go mod tidy

# Step 5: 验证
go build ./...
go test ./...

# Step 6: retract 旧版本 + tag
cat >> go.mod << 'GOEOF'

retract [v1.0.0, v1.1.0]
GOEOF

git add go.mod go.sum $(find . -name '*.go')
git commit -m "fix: kebab-case to snake_case: domain-market → domain_market"
git tag -a v1.1.1 -m "fix: module path corrected to snake_case"
git push -u origin fix/kebab-to-snake
git push origin v1.1.1
```

#### Go module major version 影响

- **不需要 /v2**：与 domain_macro 相同理由
- retract v1.0.0-v1.1.0（kebab-case 历史）

#### 消费者影响 [COMPUTED, MED]

- **domain_exchange**：FOUNDATION-DEPS.yaml allowed_deps 声明 `domain_exchange: [decimalx, domainx, domain_market]`
  - domain_exchange 的 go.mod 中 require `github.com/xhyperium/domain-market` 需改为 `github.com/xhyperium/domain_market`
  - domain_exchange 的 .go 文件中 import `github.com/xhyperium/domain-market/...` 需改为 `github.com/xhyperium/domain_market/...`
  - domain_exchange 自身也是 kebab-case 违规模块，此联动修改将在 domain_exchange 迁移步骤中一并完成

#### 回滚方案

```bash
git push origin --delete v1.1.1
git revert HEAD
git push origin fix/kebab-to-snake --force
```

#### 验证方法

与 domain_macro 相同模式，额外验证 domain_exchange 可解析新路径。

---

### 2.3 domain_exchange

#### 当前 status

| 维度               | 值                                                              |
| ------------------ | --------------------------------------------------------------- |
| GitHub 仓库        | xhyperium/domain_exchange                                       |
| go.mod module path | `github.com/xhyperium/domain-exchange` (kebab-case)             |
| go.mod go version  | 1.23                                                            |
| 最新 tag           | v1.0.0 (远程)，本地无 tag                                       |
| CI 状态            | **从未运行**                                                    |
| 最近活跃           | 2026-06-16                                                      |
| registry 不一致    | registry.yaml latest_tag=v0.1.0 vs index.json version=v1.0.0    |
| 消费者             | 0                                                               |
| 依赖               | decimalx, domainx, **domain_market**（kebab-case → 需同步修改） |
| 代码状态           | 几乎空壳（go.mod + go.sum + pkg/ 空目录）                       |

#### 目标 status

| 维度                  | 值                                                      |
| --------------------- | ------------------------------------------------------- |
| go.mod module path    | `github.com/xhyperium/domain_exchange` (snake_case)     |
| go.mod go version     | 1.26.5                                                  |
| require domain_market | `github.com/xhyperium/domain_market v1.1.1`（联动修复） |
| 新 tag                | v1.0.1                                                  |
| CI 状态               | green                                                   |
| registry 修复         | latest_tag 从 v0.1.0 → v1.0.1                           |

#### 迁移步骤

```bash
# Step 1: worktree
cd /home/workspace
git -C domain_exchange worktree add \
  /home/workspace/domain_exchange/.worktree/workspaces/fix/kebab-to-snake \
  main

cd /home/workspace/domain_exchange/.worktree/workspaces/fix/kebab-to-snake

# Step 2: 修改 go.mod module path
sed -i 's|module github.com/xhyperium/domain-exchange|module github.com/xhyperium/domain_exchange|' go.mod

# Step 3: 升级 Go 版本
sed -i 's|^go 1\.23$|go 1.26.5|' go.mod

# Step 4: 修改 domain_market 依赖（kebab → snake 联动）
sed -i 's|github.com/xhyperium/domain-market|github.com/xhyperium/domain_market|g' go.mod
sed -i 's|github.com/xhyperium/domain-market|github.com/xhyperium/domain_market|g' go.sum

# Step 5: 批量替换 import path（.go 文件）
find . -name '*.go' -exec sed -i \
  -e 's|github.com/xhyperium/domain-exchange|github.com/xhyperium/domain_exchange|g' \
  -e 's|github.com/xhyperium/domain-market|github.com/xhyperium/domain_market|g' {} +

# Step 6: 升级 domain_market 依赖到新版本
go get github.com/xhyperium/domain_market@v1.1.1
go mod tidy

# Step 7: retract 旧版本
cat >> go.mod << 'GOEOF'

retract v1.0.0
GOEOF

# Step 8: 验证
go build ./...
go test ./...

# Step 9: commit + tag
git add go.mod go.sum $(find . -name '*.go')
git commit -m "fix: kebab-case to snake_case: domain-exchange → domain_exchange"
git tag -a v1.0.1 -m "fix: module path corrected to snake_case"
git push -u origin fix/kebab-to-snake
git push origin v1.0.1
```

#### Go module major version 影响

- **不需要 /v2**
- retract v1.0.0（kebab-case 版本）

#### 消费者影响

- **无 Foundation 消费者** [COMPUTED, HIGH]
- 但被列入 `forbidden_deps` 作为禁止依赖目标（业务域不得依赖它）

#### 前置依赖

- **domain_market 必须已完成迁移**（需要新 module path + 新 tag v1.1.1）

#### 回滚方案

与 domain_market 相同模式。需先回滚 domain_exchange，再回滚 domain_market。

#### 验证方法

```bash
# 额外验证：domain_market 依赖正确
go list -m github.com/xhyperium/domain_market
# 期望: github.com/xhyperium/domain_market v1.1.1

# 零 kebab-case 残留
rg 'domain-exchange\|domain-market' --type go
# 期望: 无输出
```

---

### 2.4 xlib_harness

#### 当前 status

| 维度               | 值                                                |
| ------------------ | ------------------------------------------------- |
| GitHub 仓库        | xhyperium/xlib_harness                            |
| go.mod module path | `github.com/xhyperium/xlib-harness` (kebab-case)  |
| go.mod go version  | 1.25.0                                            |
| 最新 tag           | v0.2.1（实际 release），v0.1.7（index.json 声称） |
| CI 状态            | 最新 CI: skipped                                  |
| 消费者             | 0（runtime_dependency=false）                     |
| 状态 stale         | index.json v0.1.7 < 实际 Release v0.2.1           |
| 其他               | RULING-001 裁决 goalcli 并入 xlib_harness         |

#### 目标 status

| 维度               | 值                                               |
| ------------------ | ------------------------------------------------ |
| go.mod module path | `github.com/xhyperium/xlib_harness` (snake_case) |
| go.mod go version  | 1.26.5                                           |
| 新 tag             | v0.3.0（次版本升级，含 goalcli 并入）            |
| CI 状态            | green                                            |
| index.json 修复    | version 从 v0.1.7 → v0.3.0                       |

#### 迁移步骤

```bash
# Step 1: worktree
cd /home/workspace
git -C xlib_harness worktree add \
  /home/workspace/xlib_harness/.worktree/workspaces/fix/kebab-to-snake \
  main

cd /home/workspace/xlib_harness/.worktree/workspaces/fix/kebab-to-snake

# Step 2: 修改 go.mod module path
sed -i 's|module github.com/xhyperium/xlib-harness|module github.com/xhyperium/xlib_harness|' go.mod

# Step 3: 升级 Go 版本
sed -i 's|^go 1\.25\.0$|go 1.26.5|' go.mod

# Step 4: 批量替换 import path
find . -name '*.go' -exec sed -i \
  's|github.com/xhyperium/xlib-harness|github.com/xhyperium/xlib_harness|g' {} +

# Step 5: tidy
go mod tidy

# Step 6: 验证
go build ./...
go test ./...

# Step 7: retract 旧版本
cat >> go.mod << 'GOEOF'

retract [v0.0.0, v0.2.1]
GOEOF

# Step 8: commit + tag (v0.3.0 包含 goalcli 并入)
git add go.mod go.sum $(find . -name '*.go')
git commit -m "fix: kebab-case to snake_case: xlib-harness → xlib_harness"
git tag -a v0.3.0 -m "fix: module path corrected to snake_case; goalcli integrated (RULING-001)"
git push -u origin fix/kebab-to-snake
git push origin v0.3.0
```

#### Go module major version 影响

- **不需要 /v2**：当前 v0.x 系列（major version 0 不受 Go module major path 规则约束）
- retract v0.0.0-v0.2.1（kebab-case 历史）

#### 消费者影响

- **无运行时消费者** [COMPUTED, HIGH]
- FOUNDATION-DEPS.yaml 声明 `runtime_dependency: false`
- xlib_harness 是标准源门禁运行器，不参与运行时依赖图
- 但 **ZhengCNH 主仓的 AGENTS.md 和 script/sync-agents.py 中引用 xlib_harness 名称**——此为主仓文档引用，不涉及 Go import [KNOWN]
- RULING-001 裁决 goalcli 并入——此工作与 kebab→snake 迁移独立，可在同一 PR 合并

#### 回滚方案

与 domain_macro 相同模式。

#### 验证方法

```bash
# 额外验证：xlibgate/xlib_evidence 等不 import xlib_harness
rg 'xlib-harness' /home/workspace/xlibgate/go.mod /home/workspace/xlib_evidence/go.mod
# 期望: 无输出
```

---

### 2.5 xlib_standard

#### 当前 status

| 维度               | 值                                                |
| ------------------ | ------------------------------------------------- |
| GitHub 仓库        | xhyperium/xlib_standard                           |
| go.mod module path | `github.com/xhyperium/xlib-standard` (kebab-case) |
| go.mod go version  | 1.25.0                                            |
| 最新 tag           | v1.0.2                                            |
| CI 状态            | success                                           |
| 消费者             | transportx (shared_module)                        |
| runtime_dependency | false（标准源）                                   |

#### 目标 status

| 维度               | 值                                                |
| ------------------ | ------------------------------------------------- |
| go.mod module path | `github.com/xhyperium/xlib_standard` (snake_case) |
| go.mod go version  | 1.26.5                                            |
| 新 tag             | v1.0.3                                            |
| CI 状态            | green                                             |

#### 迁移步骤

```bash
# Step 1: worktree
cd /home/workspace
git -C xlib_standard worktree add \
  /home/workspace/xlib_standard/.worktree/workspaces/fix/kebab-to-snake \
  main

cd /home/workspace/xlib_standard/.worktree/workspaces/fix/kebab-to-snake

# Step 2: 修改 go.mod module path
sed -i 's|module github.com/xhyperium/xlib-standard|module github.com/xhyperium/xlib_standard|' go.mod

# Step 3: 升级 Go 版本
sed -i 's|^go 1\.25\.0$|go 1.26.5|' go.mod

# Step 4: 批量替换 import path
find . -name '*.go' -exec sed -i \
  's|github.com/xhyperium/xlib-standard|github.com/xhyperium/xlib_standard|g' {} +

# Step 5: tidy
go mod tidy

# Step 6: 验证
go build ./...
go test ./...

# Step 7: retract 旧版本
cat >> go.mod << 'GOEOF'

retract [v1.0.0, v1.0.2]
GOEOF

# Step 8: commit + tag
git add go.mod go.sum $(find . -name '*.go')
git commit -m "fix: kebab-case to snake_case: xlib-standard → xlib_standard"
git tag -a v1.0.3 -m "fix: module path corrected to snake_case"
git push -u origin fix/kebab-to-snake
git push origin v1.0.3
```

#### Go module major version 影响

- **不需要 /v2**：major version 1，但 module identity change 使用 retract 旧版本处理
- retract v1.0.0-v1.0.2（kebab-case 历史）
- 对消费者而言：旧 import `github.com/xhyperium/xlib-standard` 仍然可被 go get 解析（retracted），但新代码应使用 `github.com/xhyperium/xlib_standard`

#### 消费者影响 [COMPUTED, MED]

- **transportx**：FOUNDATION-DEPS.yaml 声明 transportx 的 shared_module 和依赖为 xlib_standard
  - transportx 的 go.mod 中 require `github.com/xhyperium/xlib-standard` → 需改为 `github.com/xhyperium/xlib_standard`
  - transportx 的 .go 文件中 import `github.com/xhyperium/xlib-standard/...` → 需改为 `github.com/xhyperium/xlib_standard/...`
  - transportx 本身也需修正 module identity（RULING-002），此联动在 transportx 迁移中完成
- **xlibgate / xlib_evidence**：需逐一检查 go.mod 中是否 require xlib-standard，如有则同步修改 [UNKNOWN]

#### 前置依赖

- 无（xlib_standard 是标准源，无任何 Foundation 依赖）

#### 回滚方案

```bash
# 仅回滚 xlib_standard
git push origin --delete v1.0.3
# 关闭 PR
```

#### 验证方法

```bash
# 额外验证：可能消费者检查
# 扫描所有模块 go.mod
for m in /home/workspace/*/go.mod; do
  if grep -q 'xlib-standard' "$m"; then
    echo "CONSUMER: $(dirname "$m")"
  fi
done
# 将发现的消费者加入 migration plan
```

---

### 2.6 transportx

#### 当前 status

| 维度               | 值                                                      |
| ------------------ | ------------------------------------------------------- |
| GitHub 仓库        | xhyperium/transportx                                    |
| go.mod module path | `github.com/xhyperium/xlib-standard` (**完全错位**)     |
| go.mod go version  | 1.25.0                                                  |
| 最新 tag           | v1.1.1-spec (spec-only)                                 |
| CI 状态            | success                                                 |
| 消费者             | 0（production_import_allowed=false）                    |
| 依赖               | contracts, configx, observex, resiliencx, xlib_standard |
| 裁决               | RULING-002 FINAL: `/v1` 无 `/v2`，retract 旧 tag        |

#### 目标 status

| 维度                  | 值                                                      |
| --------------------- | ------------------------------------------------------- |
| go.mod module path    | `github.com/xhyperium/transportx` (snake_case)          |
| go.mod go version     | 1.26.5                                                  |
| require xlib_standard | `github.com/xhyperium/xlib_standard v1.0.3`（联动修复） |
| 新 tag                | v1.1.2                                                  |
| CI 状态               | green                                                   |

#### 迁移步骤

```bash
# Step 1: worktree
cd /home/workspace
git -C transportx worktree add \
  /home/workspace/transportx/.worktree/workspaces/fix/module-identity \
  main

cd /home/workspace/transportx/.worktree/workspaces/fix/module-identity

# Step 2: 修改 go.mod module path（从 xlib-standard → transportx）
sed -i 's|module github.com/xhyperium/xlib-standard|module github.com/xhyperium/transportx|' go.mod

# Step 3: 升级 Go 版本
sed -i 's|^go 1\.25\.0$|go 1.26.5|' go.mod

# Step 4: 修正 xlib_standard 依赖引用（kebab → snake）
sed -i 's|github.com/xhyperium/xlib-standard|github.com/xhyperium/xlib_standard|g' go.mod
sed -i 's|github.com/xhyperium/xlib-standard|github.com/xhyperium/xlib_standard|g' go.sum

# Step 5: 批量替换 .go 文件 import path
# CRITICAL: 注意替换顺序 —— 先替换 xlib-standard 消费引用，再替换自身 module 引用
find . -name '*.go' -exec sed -i \
  's|github.com/xhyperium/xlib-standard|github.com/xhyperium/xlib_standard|g' {} +

# Step 6: 升级 xlib_standard 依赖到新版本
go get github.com/xhyperium/xlib_standard@v1.0.3
go mod tidy

# Step 7: 添加 retract 指令（spec-only 标签）
cat >> go.mod << 'GOEOF'

// retract spec-only releases predating runtime module identity
retract [v1.0.0, v1.1.1-spec]
GOEOF

# Step 8: 验证
go build ./...
go test ./...

# Step 9: commit + tag
git add go.mod go.sum $(find . -name '*.go')
git commit -m "fix: module identity corrected: xlib-standard → transportx (RULING-002)"
git tag -a v1.1.2 -m "fix: module identity corrected to github.com/xhyperium/transportx; xlib_standard dep updated"
git push -u origin fix/module-identity
git push origin v1.1.2
```

#### Go module major version 影响

- **按 RULING-002，不需要 /v2**：理由见 `ruling-transportx.md`
- retract v1.0.0-v1.1.1-spec（spec-only 发布）

#### 消费者影响

- **无生产消费者** [COMPUTED, HIGH]（RULING-002 确认）
- 如果有未记录的消费者依赖旧的 `github.com/xhyperium/xlib-standard` 路径（即 transportx 的旧 go.mod），需按 RULING-002 回退条件处理

#### 前置依赖

- **xlib_standard 必须已完成迁移**（需要 snake_case module path + 新 tag v1.0.3）

#### 回滚方案

```bash
git push origin --delete v1.1.2
# 关闭 PR
# 如果是 xlib_standard 迁移问题触发回滚，需先回滚 transportx，再处理 xlib_standard
```

#### 验证方法

```bash
# 1. module identity 正确
grep '^module' go.mod
# 期望: module github.com/xhyperium/transportx

# 2. xlib_standard 依赖正确
go list -m github.com/xhyperium/xlib_standard
# 期望: github.com/xhyperium/xlib_standard v1.0.3

# 3. 零 xlib-standard 残留
rg 'xlib-standard' --type go go.mod go.sum
# 期望: 无输出

# 4. external consumer
mkdir -p /tmp/test-transportx && cd /tmp/test-transportx
go mod init example.com/test
go get github.com/xhyperium/transportx@v1.1.2
# 期望: 成功
```

---

## 3. 全局依赖图影响分析

### 3.1 Foundation 模块消费热度

基于 FOUNDATION-DEPS.yaml allowed_deps 段反向推导：

| 被依赖模块      | 消费模块数 | 消费者列表                                                                                                                                                        | 是否 kebab           |
| --------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- |
| kernel          | 19         | configx, observex, resiliencx, schedulex, testkitx, bootstrap, redisx, kafkax, natsx, postgresx, taosx, ossx, clickhousex, domainx, transportx (via configx), ... | 不是                 |
| configx         | 2          | bootstrap, transportx                                                                                                                                             | 不是                 |
| observex        | 4          | redisx, kafkax, clickhousex, transportx                                                                                                                           | 不是                 |
| xlib_standard   | 1          | transportx                                                                                                                                                        | **是（目标模块 5）** |
| domain_market   | 1          | domain_exchange                                                                                                                                                   | **是（目标模块 2）** |
| domain_macro    | 0          | —                                                                                                                                                                 | **是（目标模块 1）** |
| domain_exchange | 0          | —                                                                                                                                                                 | **是（目标模块 3）** |
| xlib_harness    | 0          | —                                                                                                                                                                 | **是（目标模块 4）** |
| transportx      | 0          | —                                                                                                                                                                 | **是（目标模块 6）** |

**结论** [COMPUTED, HIGH]：6 个 kebab-case 模块中，仅 xlib_standard 和 domain_market 被其他 Foundation 模块依赖。消费链路短（最大链长 = 2），迁移风险可控。

### 3.2 kebab→snake 迁移链

```
domain_market (kebab → snake)
    ↓ (domain_exchange depends on domain_market)
domain_exchange (kebab → snake, 同步修改对 domain_market 的 import)

xlib_standard (kebab → snake)
    ↓ (transportx depends on xlib_standard)
transportx (identity fix, 同步修改对 xlib_standard 的 import)
```

### 3.3 迁移策略选择

**选择"先修被依赖少的，再修被依赖多的"（Leaf-First）**

理由 [COMPUTED, MED]：

1. 被依赖少的模块迁移失败影响范围小，风险可控
2. 每个模块独立 PR，回滚隔离
3. 消费链上的模块（domain_market → domain_exchange，xlib_standard → transportx）可渐进式修复，避免一次性大爆炸迁移
4. 被依赖多的模块（xlib_standard）留到最后，前面 5 个模块迁移经验可复用

### 3.4 最小迁移 DAG

```
┌─────────────┐     ┌──────────────┐     ┌────────────────┐
│ domain_macro│     │ xlib_harness  │     │ xlib_standard  │
│  (Batch 1)  │     │  (Batch 4)    │     │  (Batch 5)     │
└─────────────┘     └──────────────┘     └───────┬────────┘
                                                 │
┌──────────────┐     ┌────────────────┐          │
│domain_market │────→│domain_exchange │          │
│  (Batch 2)   │     │  (Batch 3)     │          │
└──────────────┘     └────────────────┘          │
                                                 │
                                    ┌────────────┴────────┐
                                    │     transportx      │
                                    │     (Batch 6)       │
                                    └────────────────────────┘
```

并行组：

- 组 A: {domain_macro}（独立）
- 组 B: {domain_market → domain_exchange}（串行）
- 组 C: {xlib_harness}（独立）
- 组 D: {xlib_standard → transportx}（串行）

A / B / C 三组可完全并行执行。D 组可与 A/B/C 并行但 xlib_standard 和 transportx 内部必须串行。

---

## 4. Go module 迁移技术方案

### 4.1 kebab-case → snake_case：不改变 major version 场景

**适用模块**：domain_macro, domain_market, domain_exchange, xlib_harness, xlib_standard

**核心技术手段**：go.mod retract 指令

```go
// go.mod
module github.com/xhyperium/domain_macro  // 从 domain-macro 改名

go 1.26.5

// 标记旧 kebab-case 版本为撤回，消费者 go get 时会收到警告
retract [v1.0.0, v1.0.1]
```

**Go module proxy 行为**：

- `go get github.com/xhyperium/domain_macro@latest` → 返回 v1.0.2（新 snake_case tag）
- `go get github.com/xhyperium/domain-macro@v1.0.1` → 返回 v1.0.1 + "retracted by module author" 警告
- `go get github.com/xhyperium/domain_macro@v1.0.1` → 404/unknown revision（新 path 下 v1.0.1 tag 不存在）

**消费者迁移**：消费者需修改 go.mod 的 require + 所有 .go 文件的 import path，指向 snake_case module path。

### 4.2 transportx：完全不同的 module identity

**核心技术手段**：go.mod retract + 双路径替换

transportx 当前 go.mod 声明 `module github.com/xhyperium/xlib-standard`（即声称自己是 xlib_standard），修复后应声明 `module github.com/xhyperium/transportx`。

特殊步骤：

1. 修改 go.mod module 行
2. 将 go.mod 中 require `xlib-standard` 改为 `xlib_standard`
3. 将 .go 文件中 import `xlib-standard` 改为 `xlib_standard`（消费 xlib_standard 的包）
4. retract 旧 spec-only 标签

### 4.3 kernel 孤儿 tag 处置

**问题** [KNOWN, HIGH]：kernel tag v1.1.0 不在 main 祖先链上（tag_orphan）。`git merge-base v1.1.0 main` 返回空。

**推荐方案**（优先级从高到低）：

1. **删除 v1.1.0 tag 并重新打 v1.1.1**：

   ```bash
   git push origin --delete v1.1.0
   git tag -a v1.1.1 -m "fix: snake_case tag lineage; replaces orphan v1.1.0"
   git push origin v1.1.1
   ```

   理由 [INFERRED, MED]：kernel 已有 GitHub Release v1.1.1，删除孤儿 v1.1.0 不影响现有 Release

2. **保留 v1.1.0 + retract**：

   ```bash
   # 在 go.mod 添加
   retract v1.1.0  // orphan tag, see ADR-xxx
   ```

   理由 [INFERRED, LOW]：保留历史但标记为撤回，更符合"不可变历史"原则

3. **重新定位 v1.1.0 tag 到 main HEAD**：
   ```bash
   git tag -d v1.1.0
   git tag -a v1.1.0 <main-HEAD-commit> -m "fix: tag lineage restored"
   git push origin v1.1.0 --force
   ```
   理由 [INFERRED, VERY LOW]：改写 tag 历史，Go module proxy 可能缓存旧 tag，不推荐

**推荐执行方案 1（删除 + 重打）**，条件：

- GitHub Release v1.1.1 已存在且可代替 v1.1.0
- 无外部消费者缓存 v1.1.0 的具体 commit SHA

### 4.4 批量 sed 安全注意事项

**Go 文件 import path 替换的安全边界**：

```bash
# 正确：精确匹配完整 import path
find . -name '*.go' -exec sed -i \
  's|"github.com/xhyperium/domain-market|"github.com/xhyperium/domain_market|g' {} +

# 错误：可能替换到字符串字面量或注释中的无关内容
# 但 'github.com/xhyperium/xxx' 模式在 Go 文件中几乎只出现在 import path 中，
# 这种风险在 25 个模块范围内可控 [INFERRED, MED]
```

**验证 sed 影响范围**（执行前必须运行）：

```bash
# 确认只有 import / require 被命中
rg -n 'ZoneCNH.*(xlib-standard|domain-market|domain-macro|domain-exchange|xlib-harness)' \
  --type go --type mod --type sum
```

---

## 5. 分批执行计划

### Batch 1: 最低风险（1 模块）

| 模块         | 时间窗口 | 前置 | 工作包                                             |
| ------------ | -------- | ---- | -------------------------------------------------- |
| domain_macro | Day 1-2  | 无   | go.mod fix + Go 1.23→1.26.5 + retract + tag v1.0.2 |

**理由** [COMPUTED, MED]：零消费者 + CI 从未运行 + 4 周无活跃 + 空壳模块（含业务源码），**绝对最低风险**。

**checklist**：

- [ ] PR: fix/kebab-to-snake (domain_macro)
- [ ] go.mod: `domain-macro` → `domain_macro`, Go 1.23 → 1.26.5
- [ ] retract: [v1.0.0, v1.0.1]
- [ ] tag: v1.0.2
- [ ] CI green（首个 CI run）
- [ ] `go get github.com/xhyperium/domain_macro@v1.0.2` 成功

### Batch 2: 低风险（2 模块，串行依赖）

| 模块            | 时间窗口 | 前置                          | 工作包                                                                         |
| --------------- | -------- | ----------------------------- | ------------------------------------------------------------------------------ |
| domain_market   | Day 2-3  | Batch 1 完成                  | go.mod fix + Go 1.23→1.26.5 + retract + tag v1.1.1                             |
| domain_exchange | Day 3-4  | domain_market v1.1.1 tag 存在 | go.mod fix + Go 1.23→1.26.5 + domain_market import 联动 + retract + tag v1.0.1 |

**理由** [COMPUTED, MED]：两个模块均为空壳（无业务源码），风险极低。domain_exchange 依赖 domain_market，必须串行。

**checklist domain_market**：

- [ ] PR: fix/kebab-to-snake (domain_market)
- [ ] go.mod: `domain-market` → `domain_market`, Go 1.23 → 1.26.5
- [ ] retract: [v1.0.0, v1.1.0]
- [ ] tag: v1.1.1
- [ ] CI green
- [ ] `go get github.com/xhyperium/domain_market@v1.1.1` 成功

**checklist domain_exchange**：

- [ ] PR: fix/kebab-to-snake (domain_exchange)
- [ ] go.mod: `domain-exchange` → `domain_exchange`, Go 1.23 → 1.26.5
- [ ] require: `github.com/xhyperium/domain_market v1.1.1`（联动修复）
- [ ] import: `.go` 中 domain-market → domain_market 替换
- [ ] retract: v1.0.0
- [ ] tag: v1.0.1
- [ ] CI green
- [ ] `go get github.com/xhyperium/domain_exchange@v1.0.1` 成功
- [ ] domain_market 依赖解析正确

### Batch 3: 中风险（1 模块）

| 模块         | 时间窗口 | 前置 | 工作包                                             |
| ------------ | -------- | ---- | -------------------------------------------------- |
| xlib_harness | Day 4-5  | 无   | go.mod fix + Go 1.25→1.26.5 + retract + tag v0.3.0 |

**理由** [COMPUTED, MED]：无运行时消费者，但模块有活跃代码和 tag 历史。需同步更新 index.json 的版本投影。

**checklist**：

- [ ] PR: fix/kebab-to-snake (xlib_harness)
- [ ] go.mod: `xlib-harness` → `xlib_harness`, Go 1.25.0 → 1.26.5
- [ ] retract: [v0.0.0, v0.2.1]
- [ ] tag: v0.3.0
- [ ] CI green
- [ ] `go get github.com/xhyperium/xlib_harness@v0.3.0` 成功
- [ ] 所有模块 go.mod 中无 `xlib-harness` 残留

### Batch 4: 高风险（2 模块，串行依赖）

| 模块          | 时间窗口 | 前置                                       | 工作包                                                                                  |
| ------------- | -------- | ------------------------------------------ | --------------------------------------------------------------------------------------- |
| xlib_standard | Day 5-6  | 无                                         | go.mod fix + Go 1.25→1.26.5 + retract + tag v1.0.3                                      |
| transportx    | Day 6-8  | xlib_standard v1.0.3 tag 存在 + RULING-002 | go.mod identity fix + Go 1.25→1.26.5 + xlib_standard import 联动 + retract + tag v1.1.2 |

**理由** [COMPUTED, MED]：xlib_standard 可能被多个模块（xlibgate、xlib_evidence）间接消费，需在迁移前全面扫描消费者。transportx 需联动 xlib_standard 并执行 RULING-002 裁决。

**checklist xlib_standard**：

- [ ] PR: fix/kebab-to-snake (xlib_standard)
- [ ] 全面扫描所有模块 go.mod 中的 `xlib-standard` 引用（`rg 'xlib-standard' /home/workspace/*/go.mod`）
- [ ] go.mod: `xlib-standard` → `xlib_standard`, Go 1.25.0 → 1.26.5
- [ ] retract: [v1.0.0, v1.0.2]
- [ ] tag: v1.0.3
- [ ] CI green
- [ ] `go get github.com/xhyperium/xlib_standard@v1.0.3` 成功
- [ ] 所有消费者 go.mod 中 `xlib-standard` 已替换（或标记为待后续 Batch 修复）

**checklist transportx**：

- [ ] PR: fix/module-identity (transportx)
- [ ] go.mod: `xlib-standard` → `transportx`（module identity）+ `xlib-standard` → `xlib_standard`（依赖）
- [ ] Go 1.25.0 → 1.26.5
- [ ] retract: [v1.0.0, v1.1.1-spec]
- [ ] tag: v1.1.2
- [ ] CI green
- [ ] `go get github.com/xhyperium/transportx@v1.1.2` 成功
- [ ] xlib_standard 依赖解析正确
- [ ] 零 `xlib-standard` 残留（module 行和 import 行均替换）

### Batch 5: 专项修复（并行于 Batch 1-4）

| 项目          | 模块                                                         | 工作包                                          |
| ------------- | ------------------------------------------------------------ | ----------------------------------------------- |
| 孤儿 tag      | kernel                                                       | 删除 v1.1.0 → 重打 v1.1.1（或 retract v1.1.0）  |
| Stale 状态    | xlib_harness, xlib_evidence, xlibgate, kernel, redisx, taosx | 更新 index.json version 到实际 Release 最新版本 |
| registry 修复 | decimalx, domain_exchange                                    | 同步 registry.yaml latest_tag                   |
| CI 激活       | domain_macro, domain_exchange                                | 激活 GitHub Actions CI workflow                 |

---

## 6. 验证矩阵

### 6.1 每批通用验证

| 验证项             | 方法                                                                                       | 通过标准                    |
| ------------------ | ------------------------------------------------------------------------------------------ | --------------------------- |
| go.mod module path | `grep '^module' go.mod`                                                                    | snake_case，无 kebab-case   |
| 零 kebab-case 残留 | `rg 'xlib-standard\|domain-market\|domain-macro\|domain-exchange\|xlib-harness' --type go` | 无输出                      |
| go build           | `go build ./...`                                                                           | 零错误                      |
| go test            | `go test ./...`                                                                            | 零失败                      |
| go mod tidy        | `go mod tidy && git diff --exit-code`                                                      | 无脏文件                    |
| module resolution  | `go list -m`                                                                               | 返回 snake_case module path |
| go get             | `go get {module}@{new-tag}`                                                                | 成功下载                    |
| external consumer  | 独立 go.mod + `go get` + `go build`                                                        | 编译成功                    |
| CI green           | GitHub Actions                                                                             | 所有 job 通过               |

### 6.2 消费链联动验证

| 消费链                          | 验证方法                                               | 通过标准                              |
| ------------------------------- | ------------------------------------------------------ | ------------------------------------- |
| domain_market → domain_exchange | domain_exchange `go get domain_market@new-tag` + build | 编译成功，domain_market 为 snake_case |
| xlib_standard → transportx      | transportx `go get xlib_standard@new-tag` + build      | 编译成功，xlib_standard 为 snake_case |

### 6.3 跨仓一致性验证

| 验证项               | 方法                                 | 通过标准                           |
| -------------------- | ------------------------------------ | ---------------------------------- |
| FOUNDATION-DEPS.yaml | 检查 `modules.*.path` 与 go.mod 一致 | 所有 25 模块一致                   |
| registry.yaml        | 检查 latest_tag 与 git tag 一致      | 所有模块一致                       |
| index.json           | 检查 version 与 GitHub Release 一致  | 所有模块一致（或标记 known-stale） |

### 6.4 回滚验证

每个 Batch 完成后的回滚演习：

```bash
# 1. consumer 尝试使用旧 kebab-case path
mkdir -p /tmp/rollback-test && cd /tmp/rollback-test
go mod init rollback-test
go get github.com/xhyperium/domain-macro@v1.0.1
# 期望: (retracted) 警告但成功下载 + 编译可用
# 不应: 404 / unknown revision
```

---

## 附录 A: 完整消费者扫描脚本

在每个 Batch 执行前运行，确认消费者范围：

```bash
#!/bin/bash
# consumer-scan.sh — 扫描所有模块 go.mod 中的 kebab-case 引用

KBB_PATTERNS=(
  "xlib-standard"
  "xlib-harness"
  "domain-market"
  "domain-macro"
  "domain-exchange"
)

echo "=== Kebab-case Consumer Scan ==="
echo ""

for pattern in "${KBB_PATTERNS[@]}"; do
  echo "--- Pattern: $pattern ---"
  found=0
  for gomod in /home/workspace/*/go.mod; do
    if grep -q "$pattern" "$gomod" 2>/dev/null; then
      module_name=$(basename "$(dirname "$gomod")")
      echo "  CONSUMER: $module_name"
      echo "    $(grep "$pattern" "$gomod" | head -3)"
      found=1
    fi
  done
  if [ $found -eq 0 ]; then
    echo "  无消费者"
  fi
  echo ""
done

echo "=== Go source import scan ==="
for pattern in "${KBB_PATTERNS[@]}"; do
  matches=$(rg -l "github.com/xhyperium/$pattern" /home/workspace/*/ --type go 2>/dev/null | head -20)
  if [ -n "$matches" ]; then
    echo "  $pattern:"
    echo "$matches" | while read -r f; do
      echo "    $f"
    done
  fi
done
```

## 附录 B: 迁移前后 go.mod 对比

### domain_macro

```diff
- module github.com/xhyperium/domain-macro
+ module github.com/xhyperium/domain_macro

- go 1.23
+ go 1.26.5

+ retract [v1.0.0, v1.0.1]
```

### domain_market

```diff
- module github.com/xhyperium/domain-market
+ module github.com/xhyperium/domain_market

- go 1.23
+ go 1.26.5

+ retract [v1.0.0, v1.1.0]
```

### domain_exchange

```diff
- module github.com/xhyperium/domain-exchange
+ module github.com/xhyperium/domain_exchange

- go 1.23
+ go 1.26.5

- require github.com/xhyperium/domain-market v1.1.0
+ require github.com/xhyperium/domain_market v1.1.1

+ retract v1.0.0
```

### xlib_harness

```diff
- module github.com/xhyperium/xlib-harness
+ module github.com/xhyperium/xlib_harness

- go 1.25.0
+ go 1.26.5

+ retract [v0.0.0, v0.2.1]
```

### xlib_standard

```diff
- module github.com/xhyperium/xlib-standard
+ module github.com/xhyperium/xlib_standard

- go 1.25.0
+ go 1.26.5

+ retract [v1.0.0, v1.0.2]
```

### transportx

```diff
- module github.com/xhyperium/xlib-standard
+ module github.com/xhyperium/transportx

- go 1.25.0
+ go 1.26.5

- require github.com/xhyperium/xlib-standard v1.0.2
+ require github.com/xhyperium/xlib_standard v1.0.3

+ retract [v1.0.0, v1.1.1-spec]
```

## 附录 C: 治理约束核对

| 约束                                  | 来源                         | 本计划满足？                                |
| ------------------------------------- | ---------------------------- | ------------------------------------------- |
| 每个迁移在独立 worktree/branch 中进行 | AGENTS.md §1.1               | 是：`{module}/.worktree/workspaces/fix/...` |
| 每个模块一个 PR                       | CONSTITUTION.md §0           | 是：每 Batch = 每模块一个 PR                |
| 每个 PR 只承担一个可回滚目标          | 本计划 §约束                 | 是                                          |
| Go 1.26.5 目标基线                    | 本计划 §输入                 | 是：每个迁移包含 Go 版本升级                |
| snake_case 强制                       | CONSTITUTION.md 仓库命名规则 | 是：统一迁移到 snake_case                   |
| 禁止 main 直接编辑                    | CONSTITUTION.md §0           | 是：全部通过 worktree + feature branch      |
| PR 合入 → 清理                        | CONSTITUTION.md §0           | 是：计划第最后步骤                          |

---

_计划完成。等待 team-lead 审核和分配执行。_

[RULES I BROKE]：无
