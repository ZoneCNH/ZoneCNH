# ossx 完整规格

> 基座 · 存储扩展。对象存储（OSS）客户端封装。

最后更新：2026-06-07

---

## 1. Metadata

- Status: Draft
- Spec-Version: v1.0.0
- Last-Updated: 2026-06-07
- Owner: ZoneCNH
- Layer: L1 存储扩展
- Version: v0.1.0
- Repository: [github.com/ZoneCNH/ossx](https://github.com/ZoneCNH/ossx)
- Related: [CONSTITUTION.md](../../CONSTITUTION.md), [ARCHITECTURE.md](../../ARCHITECTURE.md), [kernel](../kernel/SPEC.md), [observex](../observex/SPEC.md)

---

### 1.1 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2026-06-07 | v1.0.0 | 初始版本 | ZoneCNH |

## 2. Summary

`ossx` 封装对象存储客户端，提供统一的上传、下载、删除、列举和预签名 URL 生成接口。支持 S3、MinIO 和本地文件系统三种后端，屏蔽各后端 API 差异，为上层模块提供一致的存储抽象。

---

## 3. Problem

量化交易系统需要存储多种非结构化数据：回测报告、模型文件、日志归档、配置快照。直接使用各后端 SDK 存在以下问题：

- S3、MinIO、local 三套 API 不兼容，切换后端需要改业务代码
- 上传/下载缺少统一的超时、重试和错误处理
- 大文件上传缺少分片支持
- 预签名 URL 生成逻辑各后端不同
- 缺少统一的可观测集成，排查存储问题困难
- 健康检查逻辑各模块重复实现

---

## 4. Goals

- 提供 `Client` 接口，统一封装 Put / Get / Delete / List / PresignURL 操作
- 支持 S3、MinIO、local 三种后端，通过配置切换
- 大文件自动分片上传（multipart upload）
- 集成 observex 的 metrics / tracing / logging
- 提供 `Health()` 健康检查，与 kernel 生命周期对齐
- 集成测试在存储服务不可达时自动 skip

---

## 5. Non-goals

- 不做存储集群管理或部署编排
- 不做数据压缩/加密（业务层或存储服务决定）
- 不做 CDN 配置
- 不做跨区域复制
- 不做存储桶（Bucket）管理（创建/删除 Bucket）
- 不做 ACL/权限管理
- 不做文件内容校验（MD5/CRC32，由底层 SDK 处理）

---

## 6. Consumers

| 消费者 | 使用方式 |
|--------|----------|
| `backtest-engine` | 存储回测报告、结果文件 |
| `model-engine` | 存储/加载模型文件 |
| `risk-engine` | 存储风控快照、日志归档 |
| `x.go`（组合根） | 创建 Client 实例，注入到需要存储的模块 |
| 运维/监控 | 通过 Health() 检查存储服务连接状态 |

---

## 7. Functional Requirements

### FR-001: NewClient

WHEN 调用 `NewClient(cfg Config)` 且 backend 为 "s3" 且 S3 配置合法
THEN 创建 S3 Client 实例，返回 nil 错误

WHEN 调用 `NewClient(cfg Config)` 且 backend 为 "minio" 且 MinIO 配置合法
THEN 创建 MinIO Client 实例，返回 nil 错误

WHEN 调用 `NewClient(cfg Config)` 且 backend 为 "local" 且 base path 可写
THEN 创建 local Client 实例，返回 nil 错误

WHEN 调用 `NewClient(cfg Config)` 且 backend 不是 s3/minio/local
THEN 返回 `ErrUnsupportedBackend`

WHEN 调用 `NewClient(cfg Config)` 且配置不完整（缺少必填字段）
THEN 返回 `ErrInvalidConfig`，包含缺失字段名

### FR-002: Put

WHEN 调用 `Put(ctx, key, reader, opts...)` 且 key 合法、reader 可读
THEN 上传内容到存储后端，返回 nil

WHEN 调用 `Put(ctx, key, reader, opts...)` 且 key 为空
THEN 返回 `ErrInvalidKey`

WHEN 调用 `Put(ctx, key, reader, opts...)` 且文件大小超过后端限制
THEN 返回 `ErrObjectTooLarge`

WHEN 文件大小超过分片阈值（默认 100MB）
THEN 自动使用 multipart upload

WHEN ctx 被取消
THEN 中断上传，清理已上传分片，返回 `ctx.Err()`

### FR-003: Get

WHEN 调用 `Get(ctx, key)` 且对象存在
THEN 返回 `io.ReadCloser`，nil 错误

WHEN 调用 `Get(ctx, key)` 且对象不存在
THEN 返回 nil, `ErrObjectNotFound`

WHEN 调用 `Get(ctx, key)` 且 key 为空
THEN 返回 nil, `ErrInvalidKey`

WHEN 读取方未完全消费 ReadCloser 就关闭
THEN 底层连接正确释放，无资源泄漏

### FR-004: Delete

WHEN 调用 `Delete(ctx, key)` 且对象存在
THEN 删除对象，返回 nil

WHEN 调用 `Delete(ctx, key)` 且对象不存在
THEN 返回 nil（幂等删除）

WHEN 调用 `Delete(ctx, key)` 且 key 为空
THEN 返回 `ErrInvalidKey`

### FR-005: List

WHEN 调用 `List(ctx, prefix)` 且有匹配对象
THEN 返回 `[]ObjectInfo`，按 key 字典序排列

WHEN 调用 `List(ctx, prefix)` 且无匹配对象
THEN 返回空切片，nil 错误

WHEN 调用 `List(ctx, prefix)` 且 prefix 为空
THEN 列举 bucket 中所有对象（注意性能）

WHEN 匹配对象数量超过 max_results（默认 1000）
THEN 返回前 max_results 条，附带 `IsTruncated` 标志

### FR-006: PresignURL

WHEN 调用 `PresignURL(ctx, key, expiry)` 且对象存在
THEN 返回可访问的预签名 URL

WHEN 调用 `PresignURL(ctx, key, expiry)` 且对象不存在
THEN 返回预签名 URL（不过滤存在性，由访问方处理 404）

WHEN 调用 `PresignURL(ctx, key, expiry)` 且 expiry <= 0
THEN 返回 `ErrInvalidExpiry`

WHEN 调用 `PresignURL(ctx, key, expiry)` 且 backend 为 "local"
THEN 返回本地文件服务 URL（需要配合 HTTP server）

### FR-007: Health

WHEN 调用 `Health()` 且存储后端可达
THEN 返回 `HealthStatus{Ready: true, Live: true}`

WHEN 调用 `Health()` 且存储后端不可达
THEN 返回 `HealthStatus{Ready: false, Live: false, Message: "backend unreachable"}`

### FR-008: Close

WHEN 调用 `Close()`
THEN 释放底层客户端资源，返回 nil

WHEN 重复调用 `Close()`
THEN 幂等，第二次调用返回 nil

---

## 8. Business Rules

| 编号 | 规则 |
|------|------|
| BR-001 | key 必须非空，且不能以 `/` 开头 |
| BR-002 | multipart upload 阈值默认 100MB，可通过 Config 配置 |
| BR-003 | 分片大小默认 5MB，可通过 Config 配置 |
| BR-004 | List 结果默认最大 1000 条，可通过 opts 覆盖 |
| BR-005 | Health() 必须是幂等的、无副作用的 |
| BR-006 | 所有操作必须接受 `context.Context`，支持取消和超时 |
| BR-007 | 错误消息格式：`"ossx: <operation>: <detail>"` |
| BR-008 | Delete 对不存在的对象是幂等的（不返回错误） |
| BR-009 | Close() 必须是幂等的，多次调用不 panic |
| BR-010 | local 后端的 base path 必须是绝对路径 |
| BR-011 | 可观测指标必须包含 backend 和 operation 标签 |
| BR-012 | Put 的 Content-Type 从 opts 获取，不自动检测 |

---

## 9. Interface Contract

### 9.1 Client / ObjectInfo

```go
type Client interface {
    Put(ctx context.Context, key string, reader io.Reader, opts ...PutOpt) error
    Get(ctx context.Context, key string) (io.ReadCloser, error)
    Delete(ctx context.Context, key string) error
    List(ctx context.Context, prefix string) ([]ObjectInfo, error)
    PresignURL(ctx context.Context, key string, expiry time.Duration) (string, error)
    Health() HealthStatus
    Close() error
}

type ObjectInfo struct {
    Key          string
    Size         int64
    LastModified time.Time
    ETag         string
}

type HealthStatus struct {
    Ready   bool
    Live    bool
    Message string
}

// PutOpt 上传选项
type PutOpt func(*putOptions)

type putOptions struct {
    ContentType string
    Metadata    map[string]string
}
```text

### 9.2 Config

```go
type Config struct {
    Backend            string        // "s3", "minio", "local"
    Bucket             string        // bucket 名称（S3/MinIO）
    BasePath           string        // 本地存储根路径（local）
    Endpoint           string        // S3/MinIO endpoint
    Region             string        // S3 region
    AccessKey          string        // 访问密钥
    SecretKey          string        // 密钥
    UseSSL             bool          // 是否使用 SSL
    MultipartThreshold int64         // 分片上传阈值，默认 100MB
    PartSize           int64         // 分片大小，默认 5MB
    MaxResults         int           // List 默认最大条数，默认 1000
}
```text

### 9.3 用法示例

```go
client, err := ossx.NewClient(ossx.Config{
    Backend:  "s3",
    Bucket:   "foundation-data",
    Endpoint: "s3.amazonaws.com",
    Region:   "ap-northeast-1",
})
if err != nil {
    log.Fatal(err)
}
defer client.Close()

// 上传
data := strings.NewReader(`{"symbol":"BTCUSDT","close":100.5}`)
err = client.Put(ctx, "reports/2026/01/backtest.json", data,
    ossx.WithContentType("application/json"))

// 下载
reader, err := client.Get(ctx, "reports/2026/01/backtest.json")
defer reader.Close()

// 列举
objects, err := client.List(ctx, "reports/2026/01/")

// 预签名 URL
url, err := client.PresignURL(ctx, "reports/2026/01/backtest.json", 1*time.Hour)
```text

---

## 10. Data Model

### 10.1 公共错误

```go
var (
    ErrUnsupportedBackend = errors.New("ossx: unsupported backend")
    ErrInvalidConfig      = errors.New("ossx: invalid config")
    ErrInvalidKey         = errors.New("ossx: invalid key")
    ErrObjectNotFound     = errors.New("ossx: object not found")
    ErrObjectTooLarge     = errors.New("ossx: object too large")
    ErrInvalidExpiry      = errors.New("ossx: invalid expiry")
    ErrUploadFailed       = errors.New("ossx: upload failed")
    ErrDownloadFailed     = errors.New("ossx: download failed")
)
```text

### 10.2 后端枚举

```go
const (
    BackendS3    = "s3"
    BackendMinIO = "minio"
    BackendLocal = "local"
)
```text

---

## 11. Config Schema

```yaml
ossx:
  backend: "s3"                        # s3 | minio | local
  bucket: "foundation-data"            # bucket 名称（S3/MinIO）
  base_path: "/data/oss"              # 本地存储根路径（local）
  endpoint: "s3.amazonaws.com"         # S3/MinIO endpoint
  region: "ap-northeast-1"             # S3 region
  access_key: "${OSS_ACCESS_KEY}"      # 访问密钥
  secret_key: "${OSS_SECRET_KEY}"      # 密钥
  use_ssl: true                        # 是否使用 SSL
  multipart_threshold: 100MB           # 分片上传阈值
  part_size: 5MB                       # 分片大小
  max_results: 1000                    # List 默认最大条数
  connect_timeout: 10s                 # 连接超时
  request_timeout: 60s                 # 请求超时
```text

---

## 12. Error Handling

| 错误 | 调用方处理 |
|------|-----------|
| `ErrUnsupportedBackend` | 检查 Config.Backend，使用 s3/minio/local 之一 |
| `ErrInvalidConfig` | 检查缺失字段，修复后重试 |
| `ErrInvalidKey` | 检查 key 是否非空且不以 `/` 开头 |
| `ErrObjectNotFound` | 检查 key 是否正确，或先 List 确认 |
| `ErrObjectTooLarge` | 减小文件大小或检查后端限制 |
| `ErrInvalidExpiry` | 传入正数 duration |
| `ErrUploadFailed` | 检查网络和存储服务状态，重试 |
| `ErrDownloadFailed` | 检查网络和对象是否存在，重试 |
| 后端 SDK 错误 | 包装为 `ossx: <op>: <native_err>`，保留错误链 |

**错误消息格式：** `"ossx: <operation>: <detail>"`
**错误包装：** 使用 `%w` 保留底层错误链

---

## 13. Edge Cases

| 场景 | 预期行为 |
|------|----------|
| key 为空 | 返回 `ErrInvalidKey` |
| key 以 `/` 开头 | 返回 `ErrInvalidKey` |
| key 包含 `//` | 正常处理（不规范化） |
| Put 空文件（0 字节） | 正常上传 |
| Get 后未读完就关闭 | 资源正确释放 |
| Delete 不存在的对象 | 返回 nil（幂等） |
| List 空 prefix | 列举所有对象 |
| List 结果超大 | 分页返回，IsTruncated=true |
| 并发 Put 同一 key | 后写覆盖（last-write-wins） |
| ctx 在上传中途取消 | 清理已上传分片 |
| local 后端路径不存在 | 自动创建目录 |
| PresignURL 对不存在对象 | 返回 URL（不过滤存在性） |
| multipart upload 部分失败 | 自动重试失败分片 |

---

## 14. Directory Structure

```text
ossx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go                      # 包级文档
├── ossx.go                     # Client 工厂函数 NewClient
├── client.go                   # Client 接口定义
├── options.go                  # PutOpt 等选项
├── errors.go                   # 公共错误变量
├── config.go                   # Config 结构体
├── health.go                   # HealthStatus
├── internal/
│   ├── s3/                     # S3 后端实现
│   ├── minio/                  # MinIO 后端实现
│   ├── local/                  # 本地文件系统后端实现
│   └── multipart/              # 分片上传逻辑
├── testdata/
│   └── *.golden
├── example_test.go
└── integration_test.go         //go:build integration
```text

---

## 15. Dependencies

### 15.1 go.mod

```text
module github.com/ZoneCNH/ossx

go 1.23
```text

### 15.2 依赖方向

| 可以依赖 | 禁止依赖 |
|----------|----------|
| kernel（L0 原语） | configx |
| observex（interface-only） | 所有业务域 |
| S3/MinIO 客户端库 | 所有 L2.5 领域共享层 |
| stdlib | 其他存储扩展（taosx, clickhousex 等） |

### 15.3 特殊说明

ossx 通过接口接收 `observex.Logger` / `observex.Meter` / `observex.Tracer`，但只 import interface 定义所在的包。三个后端实现放在 `internal/` 下，对外不暴露。

---

## 16. Testing

### 16.1 单元测试

| 测试场景 | 验证点 |
|----------|--------|
| NewClient s3 配置 | 返回 S3 Client，nil 错误 |
| NewClient minio 配置 | 返回 MinIO Client，nil 错误 |
| NewClient local 配置 | 返回 local Client，nil 错误 |
| NewClient 未知 backend | 返回 `ErrUnsupportedBackend` |
| NewClient 缺少必填字段 | 返回 `ErrInvalidConfig` |
| Put 正常上传 | 返回 nil |
| Put 空 key | 返回 `ErrInvalidKey` |
| Get 存在的对象 | 返回 ReadCloser |
| Get 不存在的对象 | 返回 `ErrObjectNotFound` |
| Delete 存在的对象 | 返回 nil |
| Delete 不存在的对象 | 返回 nil |
| List 有匹配 | 返回 ObjectInfo 切片 |
| List 无匹配 | 返回空切片 |
| PresignURL 正常 | 返回有效 URL |
| PresignURL expiry<=0 | 返回 `ErrInvalidExpiry` |
| Close 幂等 | 多次调用不 panic |

### 16.2 Given/When/Then 用例

**TC-001: 完整上传下载流程**
Given S3 后端可用
When Put 上传文件 "test/data.json"
Then 返回 nil
When Get 下载 "test/data.json"
Then 内容与上传一致

**TC-002: 大文件分片上传**
Given 分片阈值 100MB
When Put 上传 200MB 文件
Then 自动使用 multipart upload，返回 nil

**TC-003: 并发操作**
Given 10 个协程并发 Put 不同 key
Then 全部成功，无竞态条件

**TC-004: local 后端基本操作**
Given backend 为 "local"，base_path 为 "/tmp/ossx-test"
When Put/Get/Delete/List
Then 操作对应本地文件系统

**TC-005: NewClient 配置校验**
Given endpoint 或 bucket 缺失
When 创建 NewClient
Then 返回配置错误且不建立连接

**TC-006: Delete 幂等**
Given object 不存在
When 调用 Delete
Then 返回 nil 或约定的 not-found 语义且可重复调用

**TC-007: List 前缀**
Given bucket 中存在不同前缀对象
When 调用 List("logs/")
Then 只返回 logs/ 前缀下对象

**TC-008: PresignURL**
Given object key 合法且过期时间有效
When 调用 PresignURL
Then 返回包含签名和过期时间的 URL

**TC-009: Health 检查**
Given OSS 后端可达
When 调用 Health
Then 返回 healthy；后端不可达时返回 unhealthy

**TC-010: Close 幂等**
Given client 已关闭
When 再次调用 Close
Then 返回 nil 且不 panic

### 16.3 Benchmark

| 场景 | 目标 |
|------|------|
| 小文件上传 (< 1MB) | < 100ms |
| 小文件下载 (< 1MB) | < 100ms |
| List 1000 个对象 | < 200ms |
| PresignURL 生成 | < 10ms |

### 16.4 集成测试

| 场景 | 验证点 |
|------|--------|
| S3 完整流程 | Put/Get/Delete/List/PresignURL |
| MinIO 完整流程 | Put/Get/Delete/List/PresignURL |
| local 完整流程 | Put/Get/Delete/List/PresignURL |
| 大文件分片上传 | 200MB 文件上传下载一致 |
| 并发压力测试 | 100 并发操作，无资源泄漏 |
| 健康检查 | 存储服务停止后 Health() 反映状态 |

---

## 17. Performance Budget

| 操作 | 目标 | 测量方式 |
|------|------|----------|
| 小文件上传 (< 1MB) | < 100ms | benchmark test |
| 小文件下载 (< 1MB) | < 100ms | benchmark test |
| List 1000 个对象 | < 200ms | benchmark test |
| PresignURL 生成 | < 10ms | benchmark test |
| 分片上传吞吐 | > 50MB/s | integration test |
| 常驻内存（空闲） | < 5MB | profiling |

---

## 18. Observability

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `ossx.put.duration` | histogram，上传耗时，标签：backend |
| metric | `ossx.get.duration` | histogram，下载耗时，标签：backend |
| metric | `ossx.delete.duration` | histogram，删除耗时，标签：backend |
| metric | `ossx.list.duration` | histogram，列举耗时，标签：backend |
| metric | `ossx.put.size` | histogram，上传文件大小，标签：backend |
| metric | `ossx.multipart.count` | counter，分片上传次数，标签：backend |
| metric | `ossx.multipart.parts` | histogram，分片数量，标签：backend |
| log | `ossx.connected` | info，后端连接成功 |
| log | `ossx.put.completed` | info，上传完成，含 key + size + duration |
| log | `ossx.get.error` | error，下载失败，含 key + error |
| log | `ossx.multipart.upload` | info，分片上传开始，含 key + size + parts |
| span | `ossx.put` | 上传操作的 tracing span |
| span | `ossx.get` | 下载操作的 tracing span |
| span | `ossx.list` | 列举操作的 tracing span |

---

## 19. Security

| 要求 | 实现方式 |
|------|----------|
| 密钥不泄露到日志 | 日志中 AccessKey/SecretKey 脱敏 |
| 密钥不硬编码 | 通过 Config 或环境变量注入 |
| 错误消息不泄露凭据 | 错误消息包含操作名和错误类型，不包含 endpoint/key |
| local 后端路径限制 | base_path 必须是绝对路径，防止路径遍历 |
| 预签名 URL 有效期限制 | 最大有效期 7 天，超过返回错误 |

---

## 20. CI Gate

### 20.1 通用 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 任何测试失败或 data race |
| 覆盖率 | `go test ./... -coverprofile=cover.out && go tool cover -func=cover.out` | 总覆盖率 < 80% |
| vet | `go vet ./...` | 任何 vet 错误 |
| lint | `golangci-lint run` | 任何 lint 错误 |
| 依赖检查 | `go mod tidy && git diff --exit-code go.mod go.sum` | go.mod 不整洁 |
| Secret 扫描 | `gitleaks detect --no-git` | 泄露 secret |
| Benchmark | `go test -bench=. -benchmem -count=3 ./...` | 结果附在 PR comment |

### 20.2 ossx 专属 Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 集成测试 | `go test -tags=integration ./...` | 存储服务不可达时 skip，可达时必须通过 |
| 无直接依赖 configx | `go list -deps ./... \| grep configx` | 不应依赖 configx |

---

## 21. Upgrade Compatibility

| 变更类型 | 版本升级 |
|----------|----------|
| Client interface 变更 | **major**（所有消费方需同步更新） |
| Config 新增可选字段 | patch / minor |
| Config 新增必填字段 | **minor**（带默认值） |
| 新增 Client 方法 | **minor**（不影响现有实现） |
| 新增后端类型 | **minor**（不影响现有后端） |
| 错误变量变更 | **minor**（新增错误为 minor，删除为 major） |
| 修复 bug | **patch** |

---

## 22. Release DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 所有公共类型有示例代码
- [ ] CHANGELOG.md 已更新
- [ ] README.md 包含：模块定位、快速开始、配置说明、API 概览
- [ ] 单元测试覆盖率 ≥ 80%
- [ ] `-race` 测试通过
- [ ] Benchmark 结果无 > 10% 回退
- [ ] `go vet` 无警告
- [ ] `golangci-lint` 无错误
- [ ] Secret 扫描通过
- [ ] 公共 API 无破坏性变更（或已 bump major）
- [ ] 所有 Functional Requirements 有对应测试
- [ ] 所有 Edge Cases 有对应测试
- [ ] 集成测试在无存储服务环境下正确 skip
- [ ] 三个后端（s3/minio/local）均有集成测试覆盖

---

## 23. Open Questions

- local 后端是否需要提供内嵌 HTTP server 以支持 PresignURL？当前设计需要配合外部 HTTP server。
- 是否需要支持对象版本（versioning）？当前设计只保留最新版本。
- multipart upload 失败时是否需要自动清理已上传分片？还是由调用方负责？
- List 是否需要支持递归列举（当前默认递归）？是否需要 delimiter 支持？
- 是否需要支持批量删除（DeleteObjects）？当前只支持单个删除。
- S3 后端是否需要支持自定义 endpoint（如 Cloudflare R2）？
