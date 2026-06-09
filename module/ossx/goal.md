# ossx 发布版本 1.0 Goal 定位与实现标准

| 字段 | 内容 |
| --- | --- |
| 模块名 | `ossx` |
| 发布版本 | 1.0.0 |
| 所属层级 | 存储扩展层 / 对象存储统一访问 |
| 稳定级别 | Public API Stable；SPI Stable；Internal 可演进 |
| 文档状态 | 1.0 发布基线文档 |
| 发布日期基准 | 2026-06-09 |

## 术语约定

本文档中的 **MUST / 必须** 表示 1.0 发布阻断项；**SHOULD / 应该** 表示 1.0 推荐项，允许带明确理由延期；**MAY / 可以** 表示可选能力，不影响 1.0 发布。

## 1.0 发布判定原则

1. **稳定优先**：公开 API、配置项、错误码、指标名一旦进入 1.0，默认需要向后兼容。
2. **边界清晰**：模块只能解决自身层级的问题，不能向上侵入业务，也不能横向替代其他模块。
3. **证据完整**：每个 MUST 能力都必须有单元测试、关键路径集成测试或契约测试证明。
4. **可观测**：所有运行时模块必须输出最小可诊断信息，包括错误、耗时、调用量和关键状态。
5. **可演进**：1.0 允许保留扩展点，但不得把未稳定能力包装成稳定承诺。

## 1. Goal 定位

`ossx` 的 Goal 是提供对象存储的统一访问能力，屏蔽 S3、MinIO、阿里云 OSS 等后端 SDK 差异，统一 Bucket、ObjectKey、上传、下载、分片、预签名 URL、元数据、校验和、生命周期、权限策略、错误映射和可观测。它让业务以稳定接口处理文件对象，而不是直接耦合云厂商。

### 1.1 为什么需要这个模块

- 对象存储供应商和 SDK 差异明显，直接耦合会提高迁移和测试成本。
- 文件上传下载涉及权限、签名 URL、元数据、生命周期和审计，必须标准化。
- 大文件分片上传、断点续传和校验和如果不统一，容易造成半成品对象和数据损坏。
- 对象路径命名不规范会导致权限隔离和清理困难。

### 1.2 1.0 要解决的问题

- 统一 BlobStore、Bucket、ObjectKey、ObjectMetadata。
- 统一上传、下载、删除、复制、exists、head。
- 统一分片上传、预签名 URL、校验和和元数据。
- 统一对象命名规范、权限和生命周期策略。
- 统一流量、耗时、失败、签名 URL 审计。

### 1.3 目标用户

- 业务服务开发者
- 平台基础设施开发者
- SRE / 运维人员
- 测试工程师

## 2. 1.0 发布目标

- MUST 提供 BlobStore 标准接口。
- MUST 支持单文件上传/下载、流式上传/下载、删除、对象元数据查询。
- MUST 支持分片上传抽象，保证 complete/abort 语义清晰。
- MUST 支持预签名 URL，默认最短有效期和权限范围。
- MUST 提供至少一个 S3-compatible 适配器作为 1.0 验证。

## 3. 核心场景

| 场景 | 说明 | 1.0 期望结果 |
| --- | --- | --- |
| 文件上传 | 用户上传图片或报告 | 生成规范 ObjectKey，上传后返回对象引用 |
| 大文件分片 | 上传大型日志包或视频 | 分片上传、校验、完成或中止 |
| 临时下载 | 业务生成短期下载链接 | 预签名 URL 有过期时间和权限约束 |
| 多云适配 | 从 MinIO 切换到云 OSS | 业务代码不变，只切换后端配置 |

## 4. 能力范围

| 能力域 | 1.0 必须具备的能力 | 验收方式 |
| --- | --- | --- |
| 对象模型 | BucketName、ObjectKey、ObjectRef、ObjectMetadata | 模型测试通过 |
| 基础操作 | put/get/delete/copy/head/exists/list | 后端集成测试通过 |
| 流式传输 | InputStream/OutputStream 或等效流式接口 | 大文件测试通过 |
| 分片上传 | init/uploadPart/complete/abort、part checksum | 分片故障测试通过 |
| 预签名 URL | GET/PUT、过期时间、contentType、权限范围 | 签名测试通过 |
| 生命周期权限 | 对象标签、存储类型、生命周期策略接口 | 策略校验测试通过 |
| 观测审计 | 上传下载耗时、字节数、失败、签名审计 | 观测测试通过 |

## 5. 职责边界

### 5.1 模块内职责

- 提供对象存储统一访问抽象和适配 SPI。
- 提供对象命名、元数据、签名 URL、分片上传标准。
- 提供错误映射、审计事件和可观测接入。
- 提供 S3-compatible 适配器验证。

### 5.2 明确非目标

- 不替代 CDN。
- 不直接提供复杂媒体转码、图片处理、病毒扫描；可提供扩展点。
- 不定义业务文件分类和保留策略，只提供承载能力。
- 不管理云账号权限生命周期。

## 6. 依赖关系与分层约束

| 依赖类型 | 约束 |
| --- | --- |
| 上游依赖 | 依赖 kernel、configx、observex、resiliencx。 |
| 下游依赖 | 文件服务、报表服务、日志归档、数据导入导出可使用 ossx。 |
| 分层约束 | ossx 不依赖具体云厂商核心逻辑；厂商 SDK 在 adapter 中隔离。 |
| 契约依赖 | MUST 向 contracts 登记 Public API 契约和错误码契约。 |

## 7. 对外契约

### 7.1 公开能力面

| 契约 | 定位 | 1.0 稳定承诺 |
| --- | --- | --- |
| BlobStore | 对象存储入口 | 基础操作语义稳定 |
| ObjectKeyBuilder | 对象路径构造 | 命名规则稳定 |
| MultipartUpload | 分片上传接口 | init/part/complete/abort 语义稳定 |
| PresignedUrlService | 预签名 URL | 权限和过期语义稳定 |
| ObjectStorageAdapter SPI | 后端适配扩展点 | 适配器契约稳定 |

### 7.2 1.0 逻辑接口基线

```text
ObjectKey pattern:
  {app}/{env}/{domain}/{yyyy}/{MM}/{dd}/{resourceId}/{filename}

BlobStore
  put(ObjectKey, content, metadata): ObjectRef
  get(ObjectKey): ObjectContent
  delete(ObjectKey): DeleteResult
  head(ObjectKey): ObjectMetadata
  exists(ObjectKey): boolean
  copy(sourceKey, targetKey): ObjectRef

MultipartUpload
  initiate(key, metadata): UploadId
  uploadPart(uploadId, partNumber, content, checksum): PartETag
  complete(uploadId, parts): ObjectRef
  abort(uploadId): void

PresignedUrlService
  signGet(key, expires, constraints): URL
  signPut(key, expires, constraints): URL

ObjectKeyBuilder
  build(domain, resourceId, filename): ObjectKey
  parse(key): ObjectKeyParts

ObjectStorageAdapter SPI
  put(key, content, metadata): ObjectRef
  get(key): ObjectContent
  delete(key): DeleteResult
  head(key): ObjectMetadata
  signUrl(key, method, expires): URL
```

## 8. 配置契约

| 配置项 | 含义 | 默认值 / 要求 | 稳定性 |
| --- | --- | --- | --- |
| foundationx.oss.enabled | 是否启用 ossx | false，由业务显式启用 | Stable |
| foundationx.oss.backend | 后端类型 | s3-compatible / minio / aliyun-oss 等 | Stable |
| foundationx.oss.endpoint | 对象存储 endpoint | 必须配置 | Stable |
| foundationx.oss.bucket | 默认 bucket | 必须配置 | Stable |
| foundationx.oss.access-key | 访问密钥 | 必须配置且脱敏 | Stable |
| foundationx.oss.secret-key | 密钥 | 必须配置且脱敏 | Stable |
| foundationx.oss.presign.max-ttl | 预签名最大有效期 | 15m | Stable |
| foundationx.oss.multipart.part-size | 分片大小 | 8MB | Stable |
| foundationx.oss.timeout | 操作超时 | 10s | Stable |

## 9. 可观测契约

### 9.1 日志

- MUST 输出模块初始化结果、关键配置摘要和失败原因；敏感配置必须脱敏。
- MUST 在关键操作失败时输出 errorCode、operation、durationMs、traceId、resource。
- SHOULD 对慢操作输出 warn 级别日志，阈值由配置控制。
- MUST 包含 bucket、objectKeyPattern、operation、bytes、contentType、durationMs。
- MUST 对签名 URL 创建输出审计事件，不打印完整 URL 中的签名参数。

### 9.2 指标

| 指标名 | 类型 | 标签 | 说明 |
| --- | --- | --- | --- |
| foundationx_oss_operations_total | Counter | operation,bucket,status | 对象操作次数 |
| foundationx_oss_operation_duration_ms | Timer | operation,bucket,status | 对象操作耗时 |
| foundationx_oss_bytes_total | Counter | operation,bucket | 上传/下载字节数 |
| foundationx_oss_multipart_total | Counter | operation,status | 分片上传操作次数 |
| foundationx_oss_presign_total | Counter | method,bucket,status | 预签名 URL 生成次数 |
| foundationx_oss_errors_total | Counter | operation,errorCode | 对象存储错误数 |

### 9.3 Trace / 诊断事件

- MUST 接收并传播上游 trace context，不得无故丢失 requestId / traceId。
- SHOULD 为外部依赖调用创建 span，并标注 peer、operation、status、errorCode。
- MAY 输出模块内部诊断事件，用于启动分析和运行期排障。
- MUST 标注 storage.system、bucket、object.key_pattern、bytes、operation。
- MUST 对预签名 URL 生成发布审计事件。

## 10. 错误模型与失败策略

| 错误类别 | 典型原因 | 1.0 处理策略 |
| --- | --- | --- |
| OSS_OBJECT_NOT_FOUND | 对象不存在 | 返回 NotFound，不作为系统异常 |
| OSS_UPLOAD_FAILED | 上传失败、网络中断 | 可重试场景按策略处理 |
| OSS_DOWNLOAD_FAILED | 下载失败或流读取中断 | 返回失败并关闭流资源 |
| OSS_MULTIPART_FAILED | 分片上传部分失败或 complete 失败 | 支持 abort 清理 |
| OSS_PRESIGN_DENIED | 签名权限或过期时间不合法 | 拒绝生成并记录审计 |
| OSS_CHECKSUM_MISMATCH | 校验和不一致 | 删除或隔离对象并返回数据损坏错误 |

## 11. 安全、稳定性与兼容性要求

- MUST 对密码、token、accessKey、secretKey、连接串中的敏感片段做脱敏。
- MUST 保证公开 API 的异常不会泄漏内部凭据、主机隐私或完整连接串。
- MUST 为所有网络和外部依赖调用设置超时边界。
- SHOULD 支持最小权限原则，不要求业务使用高权限账号。
- MUST 支持 HTTPS 传输和认证配置。
- MUST 对签名 URL 设置最大 TTL。
- MUST 不在日志中输出完整签名 URL。
- MUST 支持最小权限账号和 bucket/path 级隔离。
- SHOULD 支持对象加密配置。

## 12. 测试证据要求

| 测试类型 | 必须覆盖内容 | 发布门禁 |
| --- | --- | --- |
| 单元测试 | ObjectKeyBuilder、metadata、预签名约束、错误映射 | MUST 通过 |
| 集成测试 | S3-compatible 后端 put/get/delete/head/list | MUST 通过 |
| 分片测试 | 分片上传、complete、abort、部分失败 | MUST 通过 |
| 安全测试 | 签名 TTL、URL 脱敏、路径穿越防护 | MUST 通过 |
| 观测测试 | 字节数、耗时、审计事件、Trace 属性 | MUST 通过 |

## 13. 1.0 发布验收清单

- 业务代码不依赖具体云厂商 SDK。
- ObjectKey 命名规范可校验。
- 分片上传失败可中止并清理。
- 预签名 URL 默认短期、最小权限、可审计。

## 14. Definition of Done

- 公开 API、配置项、错误码、指标名完成冻结并记录兼容性说明。
- README、快速开始、配置参考、错误码参考、测试说明完成。
- MUST 能力均有自动化测试，CI 可重复执行。
- 示例工程或最小可运行样例通过。
- 发布包不包含测试密钥、临时文件、个人环境路径。

## 15. 1.0 后演进方向

- 支持更多云厂商 adapter。
- 支持上传前内容扫描扩展点。
- 支持对象生命周期策略自动化检查。
