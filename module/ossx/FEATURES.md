# ossx 完整实现功能清单

- Status: Review（与 [SPEC.md](./SPEC.md) v1.1.0 同步；未通过 pipeline-arbiter 四源 98 分门禁）
- Last-Updated: 2026-06-18
- Source: [module/ossx/SPEC.md](./SPEC.md) v1.1.0 · [TRACEABILITY.md](./TRACEABILITY.md) · [IMPLEMENTATION-PLAN.md](./IMPLEMENTATION-PLAN.md)
- Layer: 基座 · 对象存储扩展
- Module-Identity: Aliyun OSS 专用 adapter（单 provider；非通用对象存储抽象 / adapter SPI / S3-compatible）

> 本文档是 ossx **要完整实现的、可勾选的功能清单**，把 SPEC 的 FR/BR 展开成具体的、可验收的功能点。
> 它不是 Why（[goal.md](./goal.md)）、不是规格（[SPEC.md](./SPEC.md)）、不是追溯矩阵（[TRACEABILITY.md](./TRACEABILITY.md)）、不是阶段计划（[IMPLEMENTATION-PLAN.md](./IMPLEMENTATION-PLAN.md)）。
> 实现状态以本清单勾选为准；任一未勾选项存在即视为未完整实现。
>
> 当前实现事实（2026-06-18 联网复核，与 `.foundationx/status/index.json` + `.foundationx/blockers.json` + `gh api` 三源一致）：
> 远程仓库 `github.com/ZoneCNH/ossx/pkg/ossx` 已交付 v1.0.2-alpha，8 个 .go 文件 / 12 测试函数 / stdlib-only / import 可编译。**BLK-010 resolved**，`impl=true`，`factory=false`。
> 已实现：FR-001/002/003/004(基本)/007/009/010；部分（ErrNotImplemented 占位）：FR-005 multipart、FR-006 presign；未实现：FR-008 真实 Aliyun adapter（仅 InMemoryAdapter）。
>
> 注：本地工作目录 `/home/ossx` 是 2026-06-14 commit `4309046` 的陈旧 clone（无 pkg/ossx），**不代表远程权威**。以 `gh api repos/ZoneCNH/ossx/contents/pkg/ossx` 为准。

勾选图例：`[ ]` 待实现 · `[x]` 已实现并通过对应 TC · `[~]` 部分实现（须在备注列注明缺口）

---

## 1. 身份与边界（先决约束）

| 约束             | 要求                                                                                     | 违反后果                            | 依据                   |
| ---------------- | ---------------------------------------------------------------------------------------- | ----------------------------------- | ---------------------- |
| 单 provider 身份 | 仅 Aliyun OSS；不提供 adapter SPI / S3-compatible / 多 provider 抽象                     | 身份漂移，SPEC 不通过               | SPEC §1, §4            |
| 禁止 configx     | 任何 ossx 包均不得 import `configx`                                                      | CI Gate `go list -deps` 阻断        | BR-002                 |
| 禁止 SDK 泄漏    | Aliyun OSS SDK 类型不得出现在公共 API                                                    | TC-009 公开 API guard 失败          | BR-011                 |
| 禁止 secret 日志 | 凭据/签名/token/签名 URL 绝不记录                                                        | CI Gate gitleaks/secret scan 阻断   | BR-009                 |
| 分层边界         | 仅可依赖 stdlib + `kernel` + `observex` 接口合约；禁止业务域/L2.5/其他 storage extension | 循环依赖 → CI dependency guard 阻断 | BR-003, BR-004, BR-005 |

---

## 2. 功能清单（按 FR 展开）

### FR-001 构造与配置 → [TASK-OSSX-000](./tasks/TASK-OSSX-000.md)

- [x] `NewBlobStore(cfg, adapter, hooks) (BlobStore, error)` 构造入口（实测：参数含 adapter）
- [x] 校验 endpoint / bucket / region / checksum / TTL 等配置项，非法值返回 `ErrInvalidConfig`（`Config.Validate()`）
- [x] nil hooks 视作 no-op hooks（`emit()` 在 `OnOperation==nil` 时直接 return）
- [x] 配置可由纯 struct 传入（`Config` 为 module-owned struct）
- [ ] 配置可由 functional options 传入（当前仅 struct，无 options 模式）
- [ ] 内部构造 Aliyun OSS adapter（当前需调用方显式传入 adapter；真实 Aliyun adapter 由 FR-008 完成）
- [x] 依赖守卫：stdlib-only 已验证（无 configx / 无其他 storage extension import）
- [x] TC-001（依赖守卫）、TC-002（配置校验，`TestConfigValidate`）通过

### FR-002 对象身份与元数据 → [TASK-OSSX-001](./tasks/TASK-OSSX-001.md)

- [x] `Key` / `Prefix` 值类型：`NewKey` 拒绝空 / 绝对路径 / `..`/`.` 段 / 非 UTF-8 / >1024 字符
- [x] `Metadata` 值类型：保留 user metadata，round trip 不泄漏 Aliyun 头部（stdlib-only，无 SDK 头部）
- [x] 拒绝超大 metadata（`MaxMetadataKeys=64` / `MaxMetadataValueLen=2048`，`validateMetadata`）
- [x] `Checksum` 算法显式枚举（sha256/md5/crc32），`computeChecksum` 确定性可复现
- [x] content type / tags 字段建模（`ObjectInfo.ContentType` / `Tags`）
- [x] TC-003（`TestNewKey` / `TestSanitizedScope` / metadata 校验）通过

### FR-003 基础对象操作 → [TASK-OSSX-002](./tasks/TASK-OSSX-002.md)

- [x] `Put(ctx, key, body, opts) (ObjectInfo, error)`（含 checksum 算法校验）
- [x] `Get(ctx, key, opts) (ObjectReader, error)`（含可选 checksum verify）
- [x] `Delete(ctx, key, opts) error`（对缺失对象幂等，`StrictNotFound` 可关闭幂等）
- [x] `Copy(ctx, source, target, opts) (ObjectInfo, error)`
- [x] `Head(ctx, key) (ObjectInfo, error)`
- [x] `Exists(ctx, key) (bool, error)`
- [x] `List(ctx, prefix, opts) (ListPage, error)`（有界分页 + continuation token）
- [x] 所有公开操作接受 `context.Context` 并传播取消（`ctxErr`）
- [x] not-found / conflict / permission / validation / timeout / provider 错误映射为稳定 typed error（`errors.go` 全量定义）
- [x] TC-004（`TestBlobStoreCRUD` / `TestList` / `TestCopy` / `TestPutChecksumAlgoValidation`）通过

### FR-004 流式上传/下载 → [TASK-OSSX-002](./tasks/TASK-OSSX-002.md)

- [~] 流式上传：不缓冲完整对象 —— **当前 `Put` 用 `io.ReadAll` 全量缓冲**，不满足 SPEC §16 "must not buffer complete objects"
- [~] 流式下载：`ObjectReader.ReadCloser` 为 `io.NopCloser(bytes.NewReader)` —— 包装内存 buffer，非真实流式；close 错误未真实暴露
- [ ] 暴露 partial-write / partial-read 错误（当前无专门处理）
- [ ] 大流测试不分配完整 payload（当前无 TC-005 专用测试）
- [ ] TC-005（流式取消/close/大 payload）通过 —— **未覆盖**

### FR-005 分片上传生命周期 → [TASK-OSSX-003](./tasks/TASK-OSSX-003.md)

- [x] `Multipart(ctx) MultipartSession` 会话入口（接口已定义）
- [~] Initiate —— 接口存在，**返回 ErrNotImplemented**
- [~] Upload Part —— 接口存在，**返回 ErrNotImplemented**
- [~] List Parts —— 接口存在，**返回 ErrNotImplemented**
- [~] Complete —— 接口存在，**返回 ErrNotImplemented**
- [~] Abort —— 接口存在，**返回 ErrNotImplemented**
- [ ] 过期/残留分片清理语义（stale cleanup）—— 未实现
- [ ] complete 期间取消：保留状态以重试/abort —— 未实现
- [~] TC-006 —— 仅 `TestMultipartNotImplemented` 验证占位，**非完整生命周期测试**

### FR-006 预签名 URL 策略 → [TASK-OSSX-004](./tasks/TASK-OSSX-004.md)

- [x] `Presign(ctx, key, op, opts) (PresignedURL, error)`（接口已定义）
- [ ] 操作 allowlist 强制 —— **未实现真实校验**
- [ ] TTL 上限 ≤ 15 分钟强制 —— `PresignPolicy.MaxTTL` 字段存在，**运行时未强制**
- [ ] checksum 约束校验 —— 未实现
- [ ] 审计日志脱敏 —— 未实现
- [~] TC-007 —— 仅 `TestPresign`，**非完整策略测试**

### FR-007 策略校验 → [TASK-OSSX-001](./tasks/TASK-OSSX-001.md) + [TASK-OSSX-004](./tasks/TASK-OSSX-004.md)

- [x] checksum 策略：不支持的算法在上传前失败（`validateChecksumAlgo` + `TestPutChecksumAlgoValidation`）
- [~] lifecycle 策略 —— `MultipartPolicy` 字段存在，**负值/矛盾窗口校验未实现**
- [ ] retention 策略 —— 未建模
- [ ] permission 策略 —— 未建模，presign/write 前未校验
- [~] TC-008 —— 仅 checksum 子集覆盖，**非完整策略测试**

### FR-008 Aliyun OSS adapter 隔离 → [TASK-OSSX-005](./tasks/TASK-OSSX-005.md)

- [ ] `adapters/aliyun/` 包封装 Aliyun OSS SDK —— **未实现**
- [x] `ObjectStorageAdapter` SPI 接口定义（adapter 边界契约清晰）
- [ ] Aliyun OSS provider 错误在适配器边界翻译 —— 无真实 adapter
- [x] 公共接口仅使用 ossx / stdlib 类型（stdlib-only 已验证；未引入 kernel/observex 依赖）
- [ ] adapter 测试可用 fake/integration-gated 真实 Aliyun OSS —— 仅 `InMemoryAdapter`
- [ ] `internal/testkit/fake_store.go` 提供 fake adapter —— **未实现**（当前用内置 `InMemoryAdapter`）
- [~] TC-009 —— `TestSPISurface` 验证接口面无 SDK 类型；TC-010 真实 adapter 契约**未覆盖**

### FR-009 可观测性与审计 → [TASK-OSSX-006](./tasks/TASK-OSSX-006.md)

- [~] 通过注入 hook 输出 metrics/traces/audit —— **仅 `Hooks.OnOperation` 单回调**，非完整 observex 接口型合约
- [x] no-op 默认 hook 可用（nil hooks 不报错）
- [~] 事件字段：operation / latency / size / error class —— **缺 traces/audit 事件，缺 sanitized key scope 独立字段**
- [x] 排除 secret（stdlib-only，无凭据/签名路径）
- [x] hook 失败不破坏操作结果（`emit` 在 defer 中，panic 未防护但当前实现无副作用）
- [~] TC-011 —— `TestHooks` 覆盖 OnOperation；**非完整 observex 合约测试**

### FR-010 健康/生命周期/优雅关闭 → [TASK-OSSX-006](./tasks/TASK-OSSX-006.md)

- [x] `Health(ctx) HealthReport`
- [~] 区分配置错误 / 不可达 / 降级 —— **当前 `HealthReport` 仅 Ready/ProviderStatus/Error 三字段，未细化三态区分**
- [x] `Close(ctx) error` 幂等（`checkClosed` + `closed` 标志）
- [ ] Close 排空 in-flight multipart 簿记 —— 无 multipart 实现，N/A 但未显式处理
- [~] readiness 可无写操作测试 —— 当前 `Health` 不做主动探活，但语义未明确
- [x] TC-012（`TestHealthAndClose`）通过

---

## 3. 文件交付清单（实现产出）

> 对应 SPEC §13 目录结构。✓ = 远程已交付；✗ = 未交付。

| 规划文件                                | 承载功能             | Task          | 远程交付                                             |
| --------------------------------------- | -------------------- | ------------- | ---------------------------------------------------- |
| `go.mod` / `doc.go` / `README.md`       | 模块骨架             | TASK-OSSX-000 | ✓ go.mod / doc.go / README.md 已交付                 |
| `Makefile`                              | 模块骨架             | TASK-OSSX-000 | ✗ 未交付（有 `scripts/`）                            |
| `internal/dependency_guard_test.go`     | 依赖边界守卫         | TASK-OSSX-000 | ✗ 未交付（stdlib-only 由 import 事实间接证明）       |
| `config.go`                             | Config 结构与校验    | TASK-OSSX-000 | ✓                                                    |
| `object.go`（含 Key/Metadata/Checksum） | 对象身份与元数据模型 | TASK-OSSX-001 | ✓ 合并为单文件 `object.go`（非 SPEC 规划的多文件）   |
| `blobstore.go`                          | BlobStore 接口与实现 | TASK-OSSX-002 | ✓                                                    |
| `stream.go`                             | 流式语义             | TASK-OSSX-002 | ✗ 未交付（流式为内存 buffer，非真实流）              |
| `errors.go`                             | typed error          | TASK-OSSX-002 | ✓                                                    |
| `inmemory.go`                           | InMemoryAdapter      | TASK-OSSX-002 | ✓（计划外新增，作为默认 adapter）                    |
| `multipart.go`                          | 分片生命周期         | TASK-OSSX-003 | ✓ 接口定义（全 ErrNotImplemented 占位）              |
| `internal/multipart/state.go`           | 分片状态             | TASK-OSSX-003 | ✗ 未交付                                             |
| `presign.go` / `presign_policy.go`      | 预签名策略           | TASK-OSSX-004 | ✗ 未交付（Presign 在 blobstore.go 占位）             |
| `adapter.go`                            | adapter SPI          | TASK-OSSX-005 | ✓（SPI 接口在 blobstore.go）                         |
| `adapters/aliyun/oss.go`                | Aliyun OSS adapter   | TASK-OSSX-005 | ✗ 未实现（BLK-010 resolved 后的真实 adapter 缺口）   |
| `internal/testkit/fake_store.go`        | 测试用 fake adapter  | TASK-OSSX-005 | ✗ 未交付（用内置 InMemoryAdapter 替代）              |
| `observability.go` / `health.go`        | 可观测性与健康       | TASK-OSSX-006 | ✗ 未交付（Hooks/Health 内联在 blobstore.go）         |
| `contracts/blobstore_contract_test.go`  | BlobStore 契约测试   | TASK-OSSX-006 | ✗ 未交付（测试在 `blobstore_test.go`）               |
| `examples/basic_test.go`                | 使用示例             | TASK-OSSX-006 | ✗ 未交付                                             |
| `CHANGELOG.md`                          | 发布说明             | TASK-OSSX-006 | ✓                                                    |

---

## 4. 测试覆盖清单（TC-001 ~ TC-013）

| TC     | 验证内容                                                            | 对应 Task           | 状态 | 远程测试函数                                    |
| ------ | ------------------------------------------------------------------- | ------------------- | ---- | ----------------------------------------------- |
| TC-001 | 依赖守卫：无 configx / 无其他 storage extension import              | TASK-OSSX-000       | [~]  | 无专用测试；stdlib-only 由 import 事实间接证明   |
| TC-002 | 配置校验：endpoint/bucket/region/timeout/checksum/multipart/presign | TASK-OSSX-000       | [x]  | `TestConfigValidate`                            |
| TC-003 | key/metadata 校验：拒绝不安全路径与超大 metadata                    | TASK-OSSX-001       | [x]  | `TestNewKey` / `TestSanitizedScope`             |
| TC-004 | 基础操作契约：Put/Get/Delete/Copy/Head/Exists/List + typed error    | TASK-OSSX-002       | [x]  | `TestBlobStoreCRUD` / `TestList` / `TestCopy`   |
| TC-005 | 流式：取消 / close 错误 / 大 payload 不分配                         | TASK-OSSX-002       | [ ]  | 未覆盖                                          |
| TC-006 | 分片：initiate/upload/list/complete/abort/stale cleanup             | TASK-OSSX-003       | [~]  | `TestMultipartNotImplemented`（仅占位验证）     |
| TC-007 | presign：TTL/allowlist/checksum/secret masking                      | TASK-OSSX-004       | [~]  | `TestPresign`（仅占位验证）                      |
| TC-008 | 策略校验：checksum/lifecycle/retention/permission                   | TASK-OSSX-001 + 004 | [~]  | `TestPutChecksumAlgoValidation`（仅 checksum）  |
| TC-009 | 公开 API 无 Aliyun OSS SDK 类型                                     | TASK-OSSX-005       | [x]  | `TestSPISurface`                                |
| TC-010 | Aliyun adapter 契约（fake / integration-gated）                     | TASK-OSSX-005       | [ ]  | 未覆盖（无真实 adapter）                        |
| TC-011 | 可观测性：metrics/traces/audit + no-op                              | TASK-OSSX-006       | [~]  | `TestHooks`（仅 OnOperation）                    |
| TC-012 | 健康 + 幂等关闭                                                     | TASK-OSSX-006       | [x]  | `TestHealthAndClose`                            |
| TC-013 | 追溯闭合：Goal→Spec→Matrix→Task→Evidence                            | TASK-OSSX-006       | [ ]  | 未覆盖                                          |

---

## 5. 验收门禁（SPEC §19）

实现落地后必须全部通过：

```bash
git diff --check
bash .github/ci/spec-lint.sh
TRACEABILITY_STRICT=1 bash .github/ci/traceability-check.sh
bash .github/ci/task-spec-validate.sh
go test ./module/ossx/...
go list -deps ./module/ossx/... | grep -v configx
```

> v1.0.2-alpha 已交付 pkg/ossx 源码，Go 检查为发布必需。BLK-010 resolved 后 `go test` + `go list -deps` 已实测通过（CHANGELOG v1.0.2-alpha 记录 `go test -race` 通过）。

---

## 6. 明确不做（非目标，SPEC §4）

- 不做业务领域上传工作流编排（由业务服务自行实现）
- 不在公开 API 暴露 Aliyun OSS SDK 类型
- 不做配置加载/解析（Config 由组合根构造后传入）
- 不做通用多 provider 抽象 / adapter SPI（不绑定 S3/MinIO/Azure/GCS）
- 不做跨云迁移编排（由平台运维层或独立工具负责）
- 不依赖其他 storage extension（natsx/kafkax/redisx/mysqlx/pgx）

---

## 7. 实现状态总览

| 维度         | 状态                                                                                                                                          |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| SPEC         | Review（v1.1.0，未过 arbiter 98 门禁）                                                                                                        |
| 代码实现     | v1.0.2-alpha 已交付（8 .go / 12 测试 / stdlib-only / import 可编译）；BLK-010 resolved；`impl=true`                                            |
| Factory      | **false**（真实 Aliyun adapter adapters/aliyun + 真实 OSS integration evidence 仍缺，由 TASK-OSSX-005 跟踪）                                  |
| 完整实现进度 | FR-001/002/003/007/009/010 已实现；FR-004/005/006/008 部分（ErrNotImplemented 或缺真实 adapter）；详见 §2 勾选                                |
| 阻塞         | 无 open 阻塞；剩余工作由 TASK-OSSX-005（真实 Aliyun adapter）+ TASK-OSSX-003/004（multipart/presign 完整实现）+ TASK-OSSX-006（release gates） |
| 完整实现判定 | 本清单 §2 全部 `[x]` + §4 全部 TC 通过 + §5 门禁通过 + arbiter 翻转 Approved + 真实 Aliyun adapter 落地（factory 翻 true）                    |

> v1.0.2-alpha 是骨架里程碑（InMemoryAdapter 可用），**非完整实现**。当 multipart/presign/真实 Aliyun adapter 落地后，更新本清单对应勾选与 §4 TC 状态。
