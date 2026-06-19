# redisx 完整实现清单

- Status: Generated from current module SSOT
- Last-Updated: 2026-06-19
- Module-Version: v1.0.3
- Module-State: 已发布
- Layer: L2 基础设施适配器
- Runtime-Repo: /home/redisx
- Source: goal.md, SPEC.md, TRACEABILITY.md, IMPLEMENTATION-PLAN.md, tasks/

> 本清单用于约束 redisx 的完整实现范围。条目来自本目录已有 Spec、Traceability、Plan、Task 等文档；截至 2026-06-19，运行时代码仓库 `/home/redisx` 分支 `redisx` 已对齐 v1.0.3，并通过 `GOWORK=off make fmt vet lint test race coverage-check`；Redis 运行时/API 可发布面 100% 覆盖率门禁已通过。提交 `271fd18` 已使用 `/home/ZoneCNH/sre/secrets/env/dev.md` 的 Redis 配置运行真实 Redis 集成测试，证据写入 `.agent/evidence/l2/integration-report.json`，且只记录 `REDISX_REDIS_*` 键名、不记录具体配置值。Docker Redis、L2-T2、强制安全扫描等 release 证据沿用 v1.0.2 历史闭合证据，v1.0.3 标签发布仍以合入 main 后 clean-main `release-preflight` 为准。

## 1. 模块边界清单

| 项目 | 要求 |
| --- | --- |
| 模块职责 | Redis 连接、命令、缓存、锁、stream 与健康检查适配 |
| 文档目录 | module/redisx |
| 运行时代码目录 | /home/redisx |
| Go 基线 | 1.23 |
| 允许依赖 | kernel |
| 禁止依赖 | 禁止越过 FOUNDATION-DEPS.yaml 登记边界依赖上层业务域或未授权基座模块 |
| 对外承诺 | API、配置、错误、观测、测试与证据口径必须与本目录追溯文档闭合 |

## 2. 功能实现清单（FR）

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| FR-001 | KeyBuilder 与命名空间隔离 — 基于 namespace/env/service/version/entity/id/purpose 构造 Key，输出确定性 Key 和脱敏 pattern，拒绝空 segment、非法字符、超长 segment、直接业务裸 Key | AC-001-1 / TC-001 / go test ./... -run TestKeyBuilder | ✅ | TRACEABILITY.md |
| FR-002 | typed Options、New/Close 与连接生命周期 — 使用 typed Options 创建 Redis client、连接池、timeout、DB、TLS、Codec 和 kernel 生命周期 hook；多次 Close 幂等释放资源 | AC-002-1 / TC-002 / go test ./... -run TestOptions | ✅ | TRACEABILITY.md |
| FR-003 | KV Get/Set/Del — 所有调用尊重 context、Codec 和错误映射；missing key 返回 ErrNotFound，Del 对不存在 Key 幂等 | AC-003-1 / TC-003 / go test ./... -run TestKV | ✅ | TRACEABILITY.md |
| FR-004 | Exists/Expire 与默认 TTL 策略 — 返回存在数量、更新/读取 TTL，对未显式 TTL 的缓存写入应用默认 TTL 与 jitter | AC-004-1 / TC-004 / go test ./... -run TestTTL | ✅ | TRACEABILITY.md |
| FR-005 | CacheClient cache-aside、null-cache、防击穿 — 支持 cache-aside、null-cache、防击穿单进程合并、TTL jitter 和 Codec 解码失败处理 | AC-005-1 / TC-005 / go test ./... -run TestCache | ✅ | TRACEABILITY.md |
| FR-006 | Hash/List 最小封装 — HGet/HSet、LPush/LRange 提供稳定语义，missing field/key 返回可识别状态或空结果 | AC-006-1 / TC-006 / go test ./... -run TestHashList | ✅ | TRACEABILITY.md |
| FR-007 | Pub/Sub Publish/Subscribe — 发布返回订阅者数量，订阅尊重 context cancellation，重连失败通过错误事件返回并释放资源 | AC-007-1 / TC-007 / go test ./... -run TestPubSub | ✅ | TRACEABILITY.md |
| FR-008 | Pipeline 有序批量执行 — 以单次网络往返提交非原子批量命令，按排队顺序返回结果，暴露部分错误 | AC-008-1 / TC-008 / go test ./... -run TestPipeline | ✅ | TRACEABILITY.md |
| FR-009 | token owner 分布式锁 — 使用 token owner、TTL、续期和 Lua guarded release，禁止释放其他 owner 的锁 | AC-009-1 / TC-009 / go test ./... -run TestLocker | ✅ | TRACEABILITY.md |
| FR-010 | Counter 与 fixed-window RateLimitHelper — 原子执行 incr/add/get/reset/allow，返回 remaining/resetAt，保证窗口 TTL | AC-010-1 / TC-010 / go test ./... -run TestRateLimit | ✅ | TRACEABILITY.md |
| FR-011 | JSON 默认 Codec 与自定义 Codec SPI — 默认 JSON 稳定，Decode 接收目标类型，自定义 Codec 错误被分类且不泄露完整 Key | AC-011-1 / TC-011 / go test ./... -run TestCodec | ✅ | TRACEABILITY.md |
| FR-012 | Health、pool stats 与观测 hooks — 输出 PING 状态、pool active/idle、低基数指标/log hooks 和脱敏错误 | AC-012-1 / TC-012 / go test ./... -run TestHealth | ✅ | TRACEABILITY.md |

## 3. 行为与非功能实现清单

| ID | 完整实现项 | 验收/测试/任务挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| BR-001 | Key 必须包含 namespace/env/service/version/entity/id 或 purpose，禁止业务直接传入裸 Key | TC-001 / 裸 Key 和非法 segment 被拒绝 | ✅ | TRACEABILITY.md |
| BR-002 | 配置只能通过 typed Options 注入；redisx 不读取文件、环境变量或配置中心 | TC-002 / Options 默认值和校验路径不依赖配置包 | ✅ | TRACEABILITY.md |
| BR-003 | 所有网络操作必须接受 context.Context 并尊重取消、deadline 和超时 | TC-003, TC-006, TC-008, TC-010 / 关键操作覆盖 context cancel/deadline 测试 | ✅ | TRACEABILITY.md |
| BR-004 | 缓存写入必须有明确 TTL 策略；默认 TTL 不得为无意永不过期，并应支持 jitter | TC-004, TC-005, TC-010 / 默认 TTL、显式 no-expire 和 jitter 语义被区分 | ✅ | TRACEABILITY.md |
| BR-005 | 分布式锁必须使用唯一 holder token、TTL、续期和释放校验 | TC-009 / token mismatch 时 Release 不删除锁 | ✅ | TRACEABILITY.md |
| BR-006 | Pipeline 是有序、非原子批量执行；部分失败必须返回有序结果和第一个错误 | TC-008 / 文档和测试覆盖非原子与部分错误 | ✅ | TRACEABILITY.md |
| BR-007 | 错误必须分类并脱敏；日志、metrics 和 trace 不得包含完整 Key、连接串或凭据 | TC-002, TC-005, TC-009 / 错误包装和 hook payload 不包含敏感值 | ✅ | TRACEABILITY.md |
| BR-008 | 重试、重连和熔断只能通过本地 hooks 或上层 adapter 接入，不直接依赖 resiliencx | TC-012 / hook 接口可表达 retry/reconnect/circuit 事件且无禁止依赖 | ✅ | TRACEABILITY.md |
| BR-009 | 指标标签必须低基数，只允许 operation、status、error_code、client、key_pattern | TC-012 / hook/metric 测试拒绝完整 Key 标签 | ✅ | TRACEABILITY.md |
| BR-010 | 生产代码直接依赖仅限 stdlib、kernel 和 Redis client library | TC-002, TC-012 / 静态依赖守卫禁止直接 import configx/observex/resiliencx/contracts + CI Gate | ✅ | TRACEABILITY.md |
| NFR-001 | 质量 | 单元与契约测试覆盖所有公开接口、错误分类和依赖边界 / go test ./... + dependency guard | ✅ | TRACEABILITY.md |
| NFR-002 | 质量 | 真实 Redis 集成测试覆盖成功路径、失败路径、并发路径和 context 取消 / go test -run Integration ./...（REDIS_ADDR 显式开启） | ✅ | TRACEABILITY.md |
| NFR-003 | 性能 | 性能基线记录 KV、Pipeline、Locker、RateLimit 的 benchmark 预算，超预算需说明 / go test -bench . ./... | ✅ | TRACEABILITY.md |
| NFR-004 | 文档 | README、配置投影说明、迁移说明和发布证据齐全 / Documentation evidence | ✅ | TRACEABILITY.md |

## 4. 任务交付清单

| ID | 交付项 | 文件/挂钩 | 当前登记状态 | 来源 |
| --- | --- | --- | --- | --- |
| TASK-REDISX-000 | TASK-REDISX-000 | module/redisx/tasks/TASK-REDISX-000.md | ✅ | tasks/TASK-REDISX-000.md |
| TASK-REDISX-001 | TASK-REDISX-001 | module/redisx/tasks/TASK-REDISX-001.md | ✅ | tasks/TASK-REDISX-001.md |
| TASK-REDISX-002 | TASK-REDISX-002 | module/redisx/tasks/TASK-REDISX-002.md | ✅ | tasks/TASK-REDISX-002.md |
| TASK-REDISX-003 | TASK-REDISX-003 | module/redisx/tasks/TASK-REDISX-003.md | ✅ | tasks/TASK-REDISX-003.md |
| TASK-REDISX-004 | TASK-REDISX-004 | module/redisx/tasks/TASK-REDISX-004.md | ✅ | tasks/TASK-REDISX-004.md |
| TASK-REDISX-005 | TASK-REDISX-005 | module/redisx/tasks/TASK-REDISX-005.md | ✅ | tasks/TASK-REDISX-005.md |
| TASK-REDISX-006 | TASK-REDISX-006 | module/redisx/tasks/TASK-REDISX-006.md | ✅ | tasks/TASK-REDISX-006.md |
| TASK-REDISX-007 | TASK-REDISX-007 | module/redisx/tasks/TASK-REDISX-007.md | ✅ | tasks/TASK-REDISX-007.md |
| TASK-REDISX-008 | TASK-REDISX-008 | module/redisx/tasks/TASK-REDISX-008.md | ✅ | tasks/TASK-REDISX-008.md |
| TASK-REDISX-009 | TASK-REDISX-009 | module/redisx/tasks/TASK-REDISX-009.md | ✅ | tasks/TASK-REDISX-009.md |

## 5. 文档资产清单

| 文档 | 状态 | 路径 |
| --- | --- | --- |
| goal.md | 存在 | module/redisx/goal.md |
| SPEC.md | 存在 | module/redisx/SPEC.md |
| TRACEABILITY.md | 存在 | module/redisx/TRACEABILITY.md |
| IMPLEMENTATION-PLAN.md | 存在 | module/redisx/IMPLEMENTATION-PLAN.md |
| tasks/ | 10 个 Markdown 文件 | module/redisx/tasks |

## 6. v1.0.3 验收证据摘要

| 证据面 | 运行仓库证据 |
| --- | --- |
| 版本与发布 | `/home/redisx` 的 `pkg/redisx/version.go`、`cmd/goalcli/governance.go`、`release/manifest/template.json`、`docs/release.md`、`docs/api.md` 与 `CHANGELOG.md` 均对齐 v1.0.3；release preflight 已尝试，因 main-only 发布策略阻塞于 `ERROR: release preflight must run on main; current branch is HEAD`，发布 tag 待合入 main 后创建 |
| 质量门禁 | `GOWORK=off make fmt vet lint test race coverage-check` 通过 |
| 100% 覆盖率门禁 | `pkg/redisx`、`internal/provider`、`internal/provider/goredis`、`internal/sanitize`、`testkit`、`examples/basic`、`examples/config`、`examples/health` 均为 100.0%，总覆盖率满足 100.0% |
| 治理门禁 | 提交 `139cf07` 已在 `/home/redisx/.worktree/workspaces/redisx-verify-20260619` 通过 `GOWORK=off make governance-check` 与 `GOWORK=off make p1-governance-check` |
| L2/契约门禁 | v1.0.2 历史证据通过；v1.0.3 发布前通过 clean-main `release-preflight` 复验 |
| 集成与 Docker | 提交 `271fd18` 已使用 `/home/ZoneCNH/sre/secrets/env/dev.md` 的 Redis 配置通过 `GOWORK=off REDISX_INTEGRATION=1 make test-integration`，证据 `.agent/evidence/l2/integration-report.json` 记录 `status=pass`、`score=100`、`profile=integration`，且仅记录 `REDISX_REDIS_*` 键名；Docker、持久化与发布镜像验收沿用 v1.0.2 历史闭合证据：`GOWORK=off REDISX_INTEGRATION_DOCKER=1 make test-integration`、`GOWORK=off REDISX_PERSISTENCE_INTEGRATION=1 make test-persistence-integration`、`VERSION=v1.0.2 GOWORK=off XLIB_CONTEXT=release_verify make docker-release-check` |
| 安全与 CI/CD | 强制 `govulncheck` 安全扫描沿用 v1.0.2 历史证据；`coverage-check` 已纳入 Makefile、registry、harness 与 release gate；`release-auto-patch` lint action 版本已固定到可用版本；`worktree-guard` 已修正为 PR 源分支门禁 |

## 7. 实现完成判定

- [x] 所有 FR 条目均有运行时代码、单元测试或契约测试覆盖。
- [x] 所有 BR/NFR 条目均有测试、静态检查或人工可审计证据覆盖。
- [x] 所有任务文档均能追溯到 FR、BR/NFR、AC 或 TC。
- [x] 依赖边界符合 FOUNDATION-DEPS.yaml，不引入未授权运行时依赖。
- [x] 运行时代码仓库 /home/redisx 的 lint、typecheck、test、race、coverage 验证证据已归档。
- [x] 发布说明与版本文件已对齐 v1.0.3。
- [ ] v1.0.3 发布标签待 clean-main `release-preflight` 后创建。
