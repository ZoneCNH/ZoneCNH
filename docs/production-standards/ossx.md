# ossx

## 1. 模块定位
ZoneCNH 基座层 Aliyun OSS 专用对象存储 adapter（Layer L2 对象存储扩展），v1.2.0 Spec / v1.2.1 本地候选。定义稳定 BlobStore API、对象元数据、流式语义、multipart 生命周期、presigned URL 策略、adapter SPI 和可观测 hooks。Status=Implemented（FR-001..010 全部实现并通过 TC）。单 provider，非通用对象存储抽象/S3-compatible。

## 2. 生产职责
- FR-001：`NewBlobStore(cfg, adapter, hooks)` 构造 + 配置校验（nil hooks 为 no-op）。
- FR-002：Key/metadata/checksum 模型（key 归一化、拒绝不安全路径、metadata round trip）。
- FR-003：Put/Get/Delete/Copy/Head/Exists/List 基础对象操作。
- FR-004：流式上传/下载（不缓冲完整对象、确定论关闭流、传播取消）。
- FR-005：Multipart 生命周期（initiate/upload/list/complete/abort/stale cleanup）。
- FR-006：Presigned URL 策略（TTL ≤ 15m、operation allowlist、audit masking）。
- FR-007/008/009/010：policy 校验、Aliyun adapter 隔离、observability hooks、Health/Close 生命周期。

## 3. 边界定义
- 仅依赖 stdlib + kernel（lifecycle/error 原语）+ observex（interface hooks）+ provider SDK（仅限 `adapters/aliyun`）（SPEC §14）。
- 禁止任何 ossx 包直接 import `configx`（BR-002，CI Gate `go list -deps | grep configx` 阻断）。
- 禁止依赖业务域、L2.5、UI、workflow 或其他存储扩展（natsx/kafkax/redisx/mysqlx/pgx，BR-005）。
- provider SDK 类型不得出现在公开 ossx API（BR-011）。

## 4. 不负责什么
- 不做业务领域的上传工作流编排（SPEC §4）。
- 不做配置加载或解析（Config 由调用方/composition root 构造后传入）。
- 不做跨云迁移编排（由平台运维层或独立迁移工具负责）。
- 不在公开 API 暴露云厂商 SDK 类型（封装在 `adapters/aliyun`）。

## 5. 架构位置
基座层（L2 对象存储扩展）。依赖方向：kernel + observex(interface) + Aliyun OSS SDK(adapter 内)。被 L2/L3 services、后台流式/multipart 作业、平台 adapter、测试/fake 消费。外部 namespace `foundationx.oss` 仅在 composition-root 配置边界使用，ossx 本身不 import configx。

## 6. 生命周期
- `NewBlobStore`：校验 Config，接受 nil hooks 为 no-op，校验 adapter capability（缺失返回 `ErrorKindConfig`）。
- `Health(ctx)`：区分配置错误/provider 不可达/降级 adapter 状态（FR-010）。
- `Close(ctx)`：幂等，排空 in-flight multipart bookkeeping（FR-010、AC-OSS-010）。
- Aliyun adapter close 状态使用 atomic，race 测试覆盖（ACCEPTANCE §1）。

## 7. 标准目录结构
```text
module/ossx/
  doc.go / config.go / blobstore.go / object.go / multipart.go
  presign.go / adapter.go / observability.go / health.go
  adapters/aliyun/        # Aliyun OSS provider adapter（SDK 隔离）
  internal/ tasks/ prompt/ evidence/
# runtime repo /home/ossx branch ossx
#   pkg/ossx (blobstore.go/store.go/multipart.go/presign.go/inmemory.go)
```

## 8. 配置规范
`Config`：endpoint、region、bucket、addressing style、TLS policy、checksum policy、timeout policy（connect 5s/operation 30s）、multipart limits（min_part_size 8MiB/max_parts 10000）、presign policy（max_ttl 15m/allowed_operations GET,PUT）、health-check policy。无效 endpoint/bucket/region/checksum/TTL 返回类型化配置错误（FR-001）。外部配置由 composition root 投影到 `ossx.Config`。

## 9. 错误模型
typed error：`ErrInvalidConfig`/`ErrNotFound`/`ErrConflict`/`ErrPermission`/`ErrChecksumMismatch`/`ErrTimeout`/`ErrCancelled`/`ErrProviderFailure`/`ErrClosed`。Provider 特定错误由 adapter 在公开边界前翻译为 typed ossx 错误（SPEC §11）。checksum mismatch 返回 typed error 并清理临时状态（BR-010）。Delete 对缺失对象幂等，除非 policy 要求 strict delete（`StrictNotFound` 先 Head 再 Delete）。

## 10. 日志规范
通过 observex-compatible hooks 注入，支持 no-op 默认。Audit 事件：operation、result、latency、对象大小、sanitized key scope、actor 字段（调用方提供）、correlation IDs。secrets/签名 URL/凭据/原始 metadata 值不得记录（BR-009、FR-009）。遵循 observex 全局 logger 规范。

## 11. Metrics 规范
metrics 包含 operation、result、latency、payload size（如可用）、adapter name、sanitized key scope。排除 raw secrets/signatures/credentials/完整签名 URL/无限制 metadata 值（SPEC §17）。Hook 失败不破坏对象操作结果，除非 policy 说 fail-closed（FR-009）。observex-compatible 接口 + no-op 默认。

## 12. Tracing 规范
SPEC §17 未定义独立 span 名称；通过 observex-compatible hooks（metrics/traces/audit events）接入。Trace 字段遵循与 metrics 相同的脱敏规则：含 operation/result/latency/size/adapter/sanitized key，排除 secrets/signatures/credentials。遵循 observex 全局 tracer 规范（SPEC未细化）。

## 13. Reliability 规范
- retry/circuit breaker 已集成（FEATURES §1 + SPEC FR-001）。
- multipart abort 幂等且部分失败安全；part validation 在 complete 前发生（BR-007）。
- Close 幂等并排空 in-flight multipart（FR-010）。
- List 强制有界分页大小 + 稳定 continuation token（BR-006）。
- checksum mismatch 返回 typed error + 清理临时状态（BR-010）。

## 14. Security 规范
- Presigned URL 最小权限（operation + TTL ≤ 15m，BR-008）。
- 凭据由 adapter 配置提供，绝不从公开 API 返回（SPEC §18）。
- 对象 key 在记录前 sanitize（BR-009）。
- checksum 与 permission policy 失败必须 fail-closed（SPEC §18）。
- secret-scope-check.sh 只允许 `.env.example` 与文档占位变量（ACCEPTANCE §2）。

## 15. Performance SLO
SPEC §16 性能预算：Put/Get streaming 不缓冲完整对象到内存；List 限制 page size 避免无界累积；multipart 遵守配置的 part-size 与并发限制；hook 发射有界开销并按 policy 安全失败。具体 ns/op benchmark SLO 未在 SPEC 定义（SPEC未细化数值）。

## 16. 测试标准
TC-001..TC-013 覆盖：依赖守卫、Config 校验、Key/metadata 校验、基础对象操作 typed 错误、流式（取消/close 错误/大 payload）、multipart 全生命周期、presign（TTL/allowlist/checksum/masking）、policy 校验、adapter SPI（不暴露 SDK 类型）、S3-compatible 契约（fake/gated）、observability、Health/Close。24 单测 + 5 集成测试（真实 bucket x-go，TC-010）。`pkg/ossx` coverage 100.0%。

## 17. Chaos 标准
SPEC §12 边界场景：空 payload/零字节对象（策略允许时有效）、超大对象（必须 streaming/multipart）、multipart complete 期间取消（保留状态以重试/abort）、重复 delete/abort/close/health（安全幂等）、Unicode key 遍历歧义（一致规范化拒绝歧义路径）。provider 故障由 retry/circuit breaker + adapter 错误翻译处理。

## 18. Contract 标准
`BlobStore` 核心 7-method interface：Put/Get/Delete/Copy/Head/Exists/List。capability 接口：`MultipartStarter`/`Presigner`/`HealthChecker`/`StoreCloser`。Adapter SPI：`StoreAdapter`/`MultipartAdapter`/`PresignAdapter`/`AdapterLifecycle`。`NewBlobStore` 返回 `*Store` 并校验 adapter capability（FEATURES §2/§3）。公共 API 治理：接口不超过 7 方法。

## 19. CI Gate
本地门禁（ACCEPTANCE §2）：`scripts/secret-scope-check.sh`、依赖隔离扫描（禁 configx/AWS-S3/Redis/MySQL/Postgres/NATS/Kafka）、API governance tests（≤7 方法）、`go test -race ./...`、coverage 100.0%、`go vet`、`go build`、`golangci-lint --allow-parallel-runners`、`jq . release/manifest/latest.json`。SPEC §19 另列：`git diff --check`、spec-lint、`TRACEABILITY_STRICT=1 traceability-check.sh`、task-spec-validate。

## 20. Release Gate
SPEC §21 DoD：Goal/SPEC/TRACEABILITY/PLAN/tasks/prompts/evidence 齐备、所有 FR/BR 映射 TC/task、依赖守卫阻 configx、目标测试与 CI 通过或记录 pre-implementation N/A 证据、release notes 标识 adapter 支持与已知限制。ACCEPTANCE §5 结论：ossx 可作为本地生产候选进入受控集成/预发布验证，不能作为已完成生产放行对外声明。

## 21. Versioning
semver。SPEC §20：首次实现后公开 API 变更须 compatibility note + migration guidance + traceability 更新。adapter-only 变更可保持 internal（若公开行为与错误契约不变）。当前 v1.2.0 Spec / v1.2.1 本地候选，远程 `github.com/ZoneCNH/ossx` 已发布 v1.1.0。

## 22. 兼容性策略
adapter SPI 拆分（StoreAdapter/MultipartAdapter/PresignAdapter/AdapterLifecycle）便于后续测试替身与 provider adapter 演进。`NewBlobStore` 返回 `*Store` 让调用方拿到完整能力，但接口治理保持窄接口（7-method BlobStore + capability 接口）。身份收敛（2026-06-18）：已移除 adapter SPI/S3-compatible/多 provider 措辞，收敛为 Aliyun OSS 专用。

## 23. Failover 策略
retry/circuit breaker 已集成（FR-001）。provider 不可达→adapter 翻译为 `ErrProviderFailure`（SPEC §11）。Close 幂等并排空 in-flight multipart bookkeeping（FR-010）。checksum mismatch fail-closed + 清理临时状态（BR-010）。模块不内置跨云迁移编排，由平台运维层负责（SPEC §4）。

## 24. Backpressure 策略
List 强制有界分页 + 稳定 continuation token（BR-006）。multipart 遵守配置的 part-size（min 8MiB）与 max_parts（10000）限制（FR-005）。streaming 路径不缓冲完整对象（FR-004）。超时由 Config.Timeout（connect 5s/operation 30s）控制，context 取消传播到 adapter。

## 25. 审计要求
audit event 字段：operation、result、sanitized key scope、actor（调用方提供）、correlation IDs（SPEC §9）。presign 路径 audit masking（FR-006）。metrics/traces/audit 排除 raw secrets/signatures/credentials/完整签名 URL/无限制 metadata 值（SPEC §17、BR-009）。hook 失败不破坏操作结果除非 fail-closed（FR-009）。

## 26. 熵减规则
全局：禁止 util dumping、hidden abstraction、cyclic dependency。模块特有：provider SDK 类型隔离在 `adapters/aliyun`（BR-011），公开 API 仅用 ossx/stdlib/kernel/observex 类型；adapter SPI 拆分避免单一大接口；配置由 composition root 投影，ossx 不 import configx（BR-002）。

## 27. AI Coding Constraints
全局：AI 不允许新增未注册模块、绕过 contracts、动态扩展目录。模块特有：AI 不得让任何 ossx 包 import configx（CI Gate 阻断）、不得在公开 API 暴露 Aliyun SDK 类型、不得在日志/trace/audit 记录 secrets/signatures/credentials、不得让 presign TTL 超过 15m 或 allowlist 之外操作（BR-008）。身份不得回退为通用对象存储抽象/S3-compatible/多 provider。

## 28. Forbidden Patterns
- 任何 ossx 包 import configx（CI Gate 阻断）。
- 公开 API 暴露 provider SDK 类型（TC-009 失败）。
- presign TTL > 15m 或未 allowlist 操作。
- 日志/trace/audit 记录 secrets/signatures/credentials/完整签名 URL。
- 无界 List（无 page size 限制）。
- 非幂等 multipart abort 或 complete 前未校验 part。
- 通用对象存储抽象/S3-compatible/多 provider 措辞（已收敛删除）。
- 全局可变状态、shared singleton chaos、runtime reflection abuse。

## 29. Production Ready Checklist
- [x] FR-001..010、AC-OSS-001..010、TC-001..013 本地通过（24 单测 + 5 集成测试）
- [x] `pkg/ossx` coverage 100.0% / race / vet / build / lint / secret-scope / 依赖隔离通过
- [x] Aliyun adapter 隔离 + StrictNotFound + 并发生命周期（atomic close）通过
- [x] 接口治理（BlobStore 7-method + capability 接口）通过
- [ ] `v1.2.1` tag / GitHub Release / release-tag CI artifact —— 未归档
- [ ] Gitleaks / xlibgate CI artifact —— 未归档
- [ ] 真实 Aliyun 集成 artifact（不泄露 endpoint/AK/SK）—— 未归档
- [ ] 下游接入证据（至少一个下游模块 PR/commit）—— 未完成
- [ ] production soak（限流/超时/重试/provider 故障/multipart abort）—— 未完成
- [ ] 四源评分门禁（composite_score >= 98）—— 未完成
- [ ] 完整生产放行声明（第 4 节证据补齐后翻转）

## 30. Roadmap
- v1.2.1（本地候选）：Aliyun OSS 单 provider 完整能力 + 本地质量门禁闭合。
- v1.x：补 release-tag CI、Gitleaks/xlibgate、真实 Aliyun 集成归档、下游接入、production soak、四源评分门禁，翻转完整生产放行。
- 开放问题（SPEC §22）：S3-compatible backend 首选集成目标、checksum 是否强制所有读取、observex hook 共享 interface 形状。
