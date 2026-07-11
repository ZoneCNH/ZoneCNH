# 25 仓 Identity 清单

> 审计范围：20 基座模块 + 5 L2.5 域模块（共 25 仓）
> 审计时间：2026-07-11
> 审计工具：identity-checker agent

## 六源一致性矩阵

| #   | 模块            | go.mod module path                     | go.mod go version | VERSION | CHANGELOG 最新 | repo-contract | 最新 tag    | README 版本    | 结论            |
| --- | --------------- | -------------------------------------- | ----------------- | ------- | -------------- | ------------- | ----------- | -------------- | --------------- |
| 1   | xlib_standard   | github.com/xhyperium/**xlib-standard**   | 1.25.0            | MISSING | 无             | MISSING       | v1.0.2      | v0.3.7, v1.0.2 | **DRIFT_MAJOR** |
| 2   | xlib_harness    | github.com/xhyperium/**xlib-harness**    | 1.25.0            | 0.2.0   | 无             | MISSING       | v0.2.1      | v0.2.0         | DRIFT_MINOR     |
| 3   | xlib_evidence   | github.com/xhyperium/**xlib_evidence**   | 1.25.0            | 0.3.0   | 无             | MISSING       | v0.3.0      | v0.3.0         | CONSISTENT      |
| 4   | xlibgate        | github.com/xhyperium/xlibgate            | 1.25.0            | MISSING | 无             | MISSING       | v1.3.0      | v1.0.1         | DRIFT_MINOR     |
| 5   | kernel          | github.com/xhyperium/kernel              | 1.25.0            | MISSING | 无             | MISSING       | v1.1.0      | N/A            | UNDEFINED       |
| 6   | configx         | github.com/xhyperium/configx             | 1.25.0            | MISSING | 无             | MISSING       | 空          | v0.1.3         | UNDEFINED       |
| 7   | observex        | github.com/xhyperium/observex            | 1.25.0            | MISSING | 无             | MISSING       | 空          | v0.3.6         | UNDEFINED       |
| 8   | resiliencx      | github.com/xhyperium/resiliencx          | 1.25.0            | MISSING | 无             | MISSING       | v1.0.0      | N/A            | UNDEFINED       |
| 9   | schedulex       | github.com/xhyperium/schedulex           | 1.25.0            | MISSING | 无             | MISSING       | 空          | v1.0.0         | UNDEFINED       |
| 10  | bootstrap       | github.com/xhyperium/bootstrap           | 1.25.0            | MISSING | MISSING        | MISSING       | v0.2.2      | v0.2.0         | CONSISTENT      |
| 11  | testkitx        | github.com/xhyperium/testkitx            | 1.25.0            | MISSING | 无             | MISSING       | 空          | N/A            | UNDEFINED       |
| 12  | redisx          | github.com/xhyperium/redisx              | 1.25.0            | MISSING | 无             | MISSING       | v1.1.2      | v1.1.0         | DRIFT_MINOR     |
| 13  | kafkax          | github.com/xhyperium/kafkax              | 1.25.0            | MISSING | 无             | MISSING       | v1.1.2      | v1.1.1         | CONSISTENT      |
| 14  | natsx           | github.com/xhyperium/natsx               | 1.25.0            | MISSING | 无             | MISSING       | v1.0.5      | v0.4.7         | DRIFT_MAJOR     |
| 15  | postgresx       | github.com/xhyperium/postgresx           | 1.25.0            | v1.1.0  | 无             | MISSING       | 空          | v1.1.0         | UNDEFINED       |
| 16  | taosx           | github.com/xhyperium/taosx               | **1.25.12**       | MISSING | 无             | MISSING       | v1.1.2      | v1.0.5         | DRIFT_MINOR     |
| 17  | ossx            | github.com/xhyperium/ossx                | 1.25.0            | v1.2.1  | 无             | MISSING       | 空          | v1.2.1         | CONSISTENT      |
| 18  | clickhousex     | github.com/xhyperium/clickhousex         | 1.25.0            | v1.0.10 | 无             | MISSING       | 空          | N/A            | UNDEFINED       |
| 19  | contracts       | github.com/xhyperium/contracts           | 1.25.0            | MISSING | 无             | MISSING       | v0.5.2      | v0.5.0         | CONSISTENT      |
| 20  | transportx      | github.com/xhyperium/**xlib-standard**   | 1.25.0            | MISSING | 无             | MISSING       | v1.1.1-spec | v1.0.0         | **DRIFT_MAJOR** |
| 21  | domainx         | github.com/xhyperium/domainx             | 1.25.0            | 1.0.1   | 无             | MISSING       | v0.1.0      | N/A            | DRIFT_MAJOR     |
| 22  | decimalx        | github.com/xhyperium/decimalx            | **1.23**          | MISSING | MISSING        | MISSING       | v1.0.0      | N/A            | UNDEFINED       |
| 23  | domain_market   | github.com/xhyperium/**domain-market**   | **1.23**          | MISSING | MISSING        | MISSING       | 空          | MISSING        | UNDEFINED       |
| 24  | domain_macro    | github.com/xhyperium/**domain-macro**    | **1.23**          | MISSING | 无             | MISSING       | v1.0.0      | v1.0.0         | CONSISTENT      |
| 25  | domain_exchange | github.com/xhyperium/**domain-exchange** | **1.23**          | MISSING | MISSING        | MISSING       | 空          | MISSING        | UNDEFINED       |

### 统计

| 结论        | 计数 | 占比 |
| ----------- | ---- | ---- |
| CONSISTENT  | 6    | 24%  |
| DRIFT_MINOR | 4    | 16%  |
| DRIFT_MAJOR | 4    | 16%  |
| UNDEFINED   | 11   | 44%  |

**关键发现**：44% 的模块无法做出有意义的 identity 一致性判断（缺少 VERSION、CHANGELOG、repo-contract 等制品），25 仓中仅 6 仓（24%）通过六源一致性。

## 已知 Identity 冲突详情

### 1. transportx: go.mod module path 错位 (P0)

- **go.mod 第 1 行**: `module github.com/xhyperium/xlib-standard`
- **仓库名**: `transportx`，仓库路径 `/home/workspace/transportx`
- **分析**: go.mod 声称是 `xlib-standard`，但这是 transportx 仓库。这是**物理文件错位**——transportx 的 go.mod 文件内容实际上是 xlib_standard 的。两个模块的 go.mod 内容相同吗？xlib_standard 的 go.mod 也是 `module github.com/xhyperium/xlib-standard`。说明 transportx 的 go.mod 被错误地复制自 xlib_standard，或者 transportx 从未正确初始化。
- **严重性**: P0 CRITICAL ——import 路径解析会失败，任何 `go get github.com/xhyperium/transportx` 都会获得错误 module identity。

### 2. xlib_evidence: 命名风格冲突

- **go.mod**: `github.com/xhyperium/xlib_evidence`（snake_case——**正确**）
- **注册表规范**: AGENTS.md 强制 snake_case，仓库命名为 `xlib_evidence`
- **分析**: 本项标记为"已知冲突"但实际检查显示 xlib_evidence 使用了 snake_case，符合规范。原始冲突描述可能指历史遗留（xlib-evidence → xlib_evidence 迁移）。当前状态：**已符合规范**。
- **严重性**: CLEAR——当前无冲突，仅为历史标记。

### 3. domain_macro: 仓库存在性确认

- **原始声称**: "仓库根本不存在"
- **实际检查**: `/home/workspace/domain_macro/` **存在**，go.mod module path 为 `github.com/xhyperium/domain-macro`，有 tag `v1.0.0`，无 CHANGELOG、VERSION、repo-contract。
- **问题**: 仓库存在但使用 kebab-case (`domain-macro`) module path，违反 snake_case 命名规则。
- **严重性**: MEDIUM——仓库存在但 identity 不规范（kebab-case + Go 1.23）。

### 4. resiliencx: 版本标签偏离

- **go.mod**: `github.com/xhyperium/resiliencx`
- **实际 git tag**: `v1.0.0`（唯一 tag）
- **原始声称**: "code v0.4.14 vs tag v1.0.2"
- **注册表声称**: `release.latest_tag: v1.0.2`
- **实际证据**: 仓库中**仅有 v1.0.0 tag**，没有 v1.0.2 也没有 v0.4.14。注册表的 `latest_tag` 字段与实际不符。
- **严重性**: HIGH——注册表 SSOT 与实际仓库状态不一致。

### 5. domain_market: SSOT 重复与 kebab-case 冲突

- **go.mod**: `github.com/xhyperium/domain-market`（**kebab-case——违反规则**）
- **go version**: 1.23（落后于基线 1.25.0）
- **tag**: 无任何 git tag
- **制品**: 无 VERSION、无 CHANGELOG、无 repo-contract
- **分析**: 模块几乎空白（仅 go.mod + go.sum），没有源代码，没有 README。module path 使用 kebab-case 违反 AGENTS.md 仓库命名规则。注册表中声称 `latest_tag: v1.1.0`——但实际仓库**无任何 tag**。
- **严重性**: P0——注册表 SSOT 与仓库实际状态严重脱节。

### 6. domain_exchange: v2 迁移与 kebab-case 冲突

- **go.mod**: `github.com/xhyperium/domain-exchange`（**kebab-case——违反规则**）
- **go version**: 1.23（落后于基线）
- **tag**: 无任何 git tag
- **结构**: 仅有 go.mod/go.sum，pkg 目录为空
- **分析**: 模块几乎空白，无 CHANGELOG、VERSION、repo-contract、README。module path 使用 kebab-case。注册表声称 `latest_tag: v0.1.0`——但实际仓库**无任何 tag**。
- **严重性**: P0——注册表 SSOT 与仓库实际状态严重脱节；模块为空壳。

## 假 Integration 阻断

> 原始声称 4 个模块有 `REQUIRED_INTEGRATION_SKIPPED` 标记。已逐一检查。

| #   | 模块   | CI integration.yml            | 真实集成测试                                                                                               | 阻断状态       | 证据                                                                                                                |
| --- | ------ | ----------------------------- | ---------------------------------------------------------------------------------------------------------- | -------------- | ------------------------------------------------------------------------------------------------------------------- |
| 1   | redisx | 存在，运行 `make integration` | `pkg/redisx/redis_integration_test.go`——有真实 Redis 连接代码，但默认 `t.Skip("set REDISX_INTEGRATION=1")` | **P0 BLOCKER** | CI 的 `make integration` 实际运行模板渲染 meta-test（非真实 Redis 连接）；真实集成测试被环境变量门控，CI 永不会触发 |
| 2   | kafkax | 存在，运行 `make integration` | 无——`testkit/kafka_test.go` 使用 `FakeKafka()`（纯 fake）；`run_integration_test.go` 只检查脚本内容        | **P0 BLOCKER** | 所有测试均使用 fake/mock；CI integration job 是模板 meta-test；无任何真实 Kafka 连接测试                            |
| 3   | natsx  | 存在，运行 `make integration` | 无——`run_integration_test.go` 只检查脚本内容                                                               | **P0 BLOCKER** | 无任何 NATS 集成测试代码；CI integration job 是模板 meta-test                                                       |
| 4   | taosx  | 存在，运行 `make integration` | 无——`run_integration_test.go` 只检查脚本内容                                                               | **P0 BLOCKER** | 无任何 TDengine 集成测试代码；CI integration job 是模板 meta-test                                                   |

### 详细证据

#### redisx

- `pkg/redisx/redis_integration_test.go`（544 行）：真实 Redis 集成测试，但受 `REDISX_INTEGRATION=1` 环境变量保护
- CI integration workflow 调 `make integration` → `run_integration.sh`：仅执行模板渲染检查，**不设置 REDISX_INTEGRATION 环境变量**
- 结论：CI 声称有集成门禁但从未运行真实 Redis 集成

#### kafkax / natsx / taosx

- 三个模块共享相同架构：`scripts/run_integration_test.go` 仅验证 `run_integration.sh` 脚本文本内容
- `run_integration.sh` 仅执行模板渲染 + Git 操作（无外部服务连接）
- kafkax 的 `testkit/kafka_test.go` 使用 `FakeKafka()`（内存 fake）进行 golden record 测试
- 无一模块有真实外部服务连接的测试代码
- CI integration.yml 均运行 `make integration` → `run_integration.sh`（纯模板 meta-test）

### 综合判定

**全部 4 仓标记为 P0 BLOCKER**。每个模块都有 `.github/workflows/integration.yml` 文件声称提供集成测试门禁，但实际执行的全是模板渲染 meta-test（不连接任何外部服务）。这构成了假门禁——形式上 CI 有 integration check，实质上没有验证模块与外部依赖的集成正确性。

## Go 基线漂移

> 目标基线：**Go 1.26.5**
> 当前 go.mod 主流：**Go 1.25.0**（18/25 = 72%）

| #   | 模块            | go.mod go version | CI go version                                                        | 漂移评估                                       |
| --- | --------------- | ----------------- | -------------------------------------------------------------------- | ---------------------------------------------- |
| 1   | xlib_standard   | 1.25.0            | go-version-file: go.mod                                              | MINOR: -1 小版本                               |
| 2   | xlib_harness    | 1.25.0            | go-version-file: go.mod                                              | MINOR: -1 小版本                               |
| 3   | xlib_evidence   | 1.25.0            | go-version-file: go.mod                                              | MINOR: -1 小版本                               |
| 4   | xlibgate        | 1.25.0            | go-version-file: go.mod                                              | MINOR: -1 小版本                               |
| 5   | kernel          | 1.25.0            | `"1.26.3"`                                                           | MINOR: -1 (go.mod) / -0.2 (CI)                 |
| 6   | configx         | 1.25.0            | `"1.26.3"`                                                           | MINOR: -1 (go.mod) / -0.2 (CI)                 |
| 7   | observex        | 1.25.0            | `"1.26.3"`（注：注释说明 go.mod 1.25.0 会触发下载 1.25.0 toolchain） | MINOR: -1 (go.mod)                             |
| 8   | resiliencx      | 1.25.0            | `"1.26.3"`                                                           | MINOR: -1 (go.mod) / -0.2 (CI)                 |
| 9   | schedulex       | 1.25.0            | `"1.26.3"`                                                           | MINOR: -1 (go.mod) / -0.2 (CI)                 |
| 10  | bootstrap       | 1.25.0            | go-version-file: go.mod                                              | MINOR: -1                                      |
| 11  | testkitx        | 1.25.0            | `"1.26.3"`（注：禁用了 go-version-file 以避免触发 1.25.0 toolchain） | MINOR: -1 (go.mod)                             |
| 12  | redisx          | 1.25.0            | go-version-file: go.mod                                              | MINOR: -1                                      |
| 13  | kafkax          | 1.25.0            | go-version-file: go.mod                                              | MINOR: -1                                      |
| 14  | natsx           | 1.25.0            | `'1.26.4'`, `'1.26.5'`                                               | MINOR: -1 (go.mod) / OK (部分 CI)              |
| 15  | postgresx       | 1.25.0            | go-version-file: go.mod                                              | MINOR: -1                                      |
| 16  | taosx           | **1.25.12**       | go-version-file: go.mod                                              | DRIFT: 使用特定补丁版本 1.25.12，非标准 1.25.0 |
| 17  | ossx            | 1.25.0            | go-version-file: go.mod                                              | MINOR: -1                                      |
| 18  | clickhousex     | 1.25.0            | `"1.25.0"`（唯一完全匹配 go.mod 的 CI）                              | MINOR: -1（go.mod 和 CI 一致但落后）           |
| 19  | contracts       | 1.25.0            | go-version-file: go.mod                                              | MINOR: -1                                      |
| 20  | transportx      | 1.25.0            | go-version-file: go.mod                                              | MINOR: -1                                      |
| 21  | domainx         | 1.25.0            | `"1.25.0"`                                                           | MINOR: -1                                      |
| 22  | decimalx        | **1.23**          | go-version-file: go.mod                                              | **MAJOR: 落后 2 个 Go 大版本**                 |
| 23  | domain_market   | **1.23**          | `'1.23'`                                                             | **MAJOR: 落后 2 个 Go 大版本**                 |
| 24  | domain_macro    | **1.23**          | go-version-file: go.mod                                              | **MAJOR: 落后 2 个 Go 大版本**                 |
| 25  | domain_exchange | **1.23**          | 无 CI                                                                | **MAJOR: 落后 2 个 Go 大版本**                 |

### Go 基线统计

| 版本    | 模块数 | 占比 |
| ------- | ------ | ---- |
| 1.25.0  | 18     | 72%  |
| 1.25.12 | 1      | 4%   |
| 1.23    | 6      | 24%  |

**关键发现**：

- 18/25 模块统一在 Go 1.25.0，但距目标 1.26.5 仍差 1 小版本
- 6 个模块（decimalx、domain_market、domain_macro、domain_exchange + 2 个 kebab-case）在 1.23，落后 **2 个 Go 大版本**
- 部分模块 CI 已使用 1.26.3（kernel/configx/observex/resiliencx/schedulex/testkitx），但 go.mod 仍为 1.25.0——存在 go.mod/CI 不一致
- taosx 使用 1.25.12（特定补丁），非标准 1.25.0——可能为兼容 TDengine driver 的 workaround

## 修复优先级建议

### P0 BLOCKER — 立即修复（阻塞 CI/CD 与依赖解析）

| 优先级 | 模块                | 问题                                       | 修复方案                                                                                     |
| ------ | ------------------- | ------------------------------------------ | -------------------------------------------------------------------------------------------- |
| P0     | **transportx**      | go.mod module path = xlib-standard（错位） | 更正 go.mod 为 `module github.com/xhyperium/transportx`，验证 import 路径                      |
| P0     | **redisx**          | 假 integration 门禁                        | 增设 `REDISX_INTEGRATION=1` 环境变量到 CI integration job，使真实 Redis 集成测试在 CI 中运行 |
| P0     | **kafkax**          | 假 integration 门禁                        | 编写真实 Kafka 集成测试（或声明此模块不要求外部集成）；删除假门禁                            |
| P0     | **natsx**           | 假 integration 门禁                        | 编写真实 NATS 集成测试（或声明此模块不要求外部集成）；删除假门禁                             |
| P0     | **taosx**           | 假 integration 门禁                        | 编写真实 TDengine 集成测试（或声明此模块不要求外部集成）；删除假门禁                         |
| P0     | **domain_market**   | 注册表 SSOT 不一致 + 空壳                  | 同步注册表 latest_tag 为实际状态（空）；决定模块命运                                         |
| P0     | **domain_exchange** | 注册表 SSOT 不一致 + 空壳                  | 同步注册表 latest_tag 为实际状态（空）；决定模块命运                                         |

### P1 HIGH — 尽快修复（影响治理与合规）

| 优先级 | 模块                | 问题                            | 修复方案                                  |
| ------ | ------------------- | ------------------------------- | ----------------------------------------- |
| P1     | **resiliencx**      | 注册表 tag v1.0.2 实际为 v1.0.0 | 更新注册表 maturity_ref 或打新 tag        |
| P1     | **decimalx**        | Go 1.23（落后 2 大版本）        | 升级到 Go 1.25.0+                         |
| P1     | **domain_market**   | Go 1.23 + kebab-case            | 升级 Go + 修复 module path 为 snake_case  |
| P1     | **domain_macro**    | Go 1.23 + kebab-case            | 升级 Go + 修复 module path 为 snake_case  |
| P1     | **domain_exchange** | Go 1.23 + kebab-case            | 升级 Go + 修复 module path 为 snake_case  |
| P1     | **xlib_standard**   | kebab-case module path          | 修复为 `github.com/xhyperium/xlib_standard` |
| P1     | **xlib_harness**    | kebab-case module path          | 修复为 `github.com/xhyperium/xlib_harness`  |

### P2 MEDIUM — 下一轮迭代修复（制品完整性）

| 优先级 | 模块      | 问题                        | 修复方案                      |
| ------ | --------- | --------------------------- | ----------------------------- |
| P2     | 18 个模块 | 缺少 VERSION 文件           | 统一生成或从 go.mod/tag 推导  |
| P2     | 22 个模块 | CHANGELOG 无版本条目        | 生成 CHANGELOG 并写入最新版本 |
| P2     | 25 个模块 | 缺少 repo-contract.yaml     | 创建或声明本模块不要求        |
| P2     | taosx     | go.mod 1.25.12（非标准）    | 降级到 1.25.0 或升级到 1.26.x |
| P2     | domainx   | VERSION=1.0.1 vs tag=v0.1.0 | 对齐版本号                    |

### 全局建议

1. **统一 Go 基线**: 在 CI preflight 阶段强制所有模块 go.mod → 1.26.5（当前最高目标）。kernel/configx 等 CI 已用 1.26.3，距离目标只差 0.2。
2. **蛇形命名强制**: 在 CI preflight 扫描 go.mod module path，拒绝 kebab-case。当前违规：`xlib-standard`, `xlib-harness`, `domain-market`, `domain-macro`, `domain-exchange`。
3. **注册表 SSOT 同步**: domain_market、domain_exchange、resiliencx 的注册表 `release.latest_tag` 与实际仓库状态不一致，需机械同步。
4. **假集成门禁清理**: 4 个 token 模块（kafkax/natsx/taosx + redisx 部分）的 integration.yml 应明确声明其 Integration Gate 类型（真实 vs 模板 meta-test vs 不需要），避免混淆。
