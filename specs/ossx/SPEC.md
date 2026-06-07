# ossx 完整规格

> 基座 · 存储扩展。对象存储（OSS）客户端封装。当前仅骨架。

最后更新：2026-06-07

---

## 1. 定位

`ossx` 封装对象存储客户端，提供统一的上传、下载、删除和可观测集成。

### 核心职责

- 文件上传（Put）
- 文件下载（Get）
- 文件删除（Delete）
- 列举对象（List）
- 预签名 URL 生成
- 健康检查
- 可观测集成（metrics、tracing、logging）
- 与 kernel 生命周期集成

### 明确不做

- 不做存储集群管理
- 不做数据压缩/加密（业务层或存储服务决定）
- 不做 CDN 配置

---

## 2. 接口契约

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
```

---

## 3. 目录结构

```
ossx/
├── go.mod
├── go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
├── doc.go
├── ossx.go                     # Client 工厂
├── client.go
├── health.go
├── options.go
├── errors.go
├── internal/
│   ├── s3/
│   ├── minio/
│   └── local/
├── testdata/
├── example_test.go
└── integration_test.go
```

---

## 4. 依赖

| 可以依赖 | 禁止依赖 |
|----------|----------|
| kernel（L0 原语） | configx |
| observex（interface-only） | 所有业务域 |
| S3/MinIO 客户端库 | |
| stdlib | |

---

## 5. CI Gate

| Gate | 命令 | 阻塞条件 |
|------|------|----------|
| 编译 | `go build ./...` | 编译失败 |
| 测试 | `go test ./... -race -count=1` | 测试失败 |
| 覆盖率 | ≥ 80% | 覆盖率不足 |
| 集成测试 | `go test -tags=integration ./...` | 存储服务不可达时 skip |

---

## 6. 测试矩阵

| 测试场景 | 验证点 |
|----------|--------|
| Put/Get | 上传后下载内容一致 |
| Delete | 删除后 Get 返回 not found |
| List | 列举前缀匹配的对象 |
| PresignURL | 预签名 URL 可访问 |
| 大文件 | 上传下载 > 100MB 文件 |

---

## 7. 性能预算

| 操作 | 目标 |
|------|------|
| 小文件上传 (< 1MB) | < 100ms |
| 小文件下载 (< 1MB) | < 100ms |

---

## 8. 可观测输出

| 类型 | 名称 | 说明 |
|------|------|------|
| metric | `ossx.put.duration` | histogram，上传耗时 |
| metric | `ossx.get.duration` | histogram，下载耗时 |
| metric | `ossx.put.size` | histogram，上传文件大小 |
| log | `ossx.connected` | info，连接成功 |

---

## 9. 发布 DoD

- [ ] 所有公共接口有 godoc 注释
- [ ] 测试覆盖率 ≥ 80%
- [ ] 集成测试可选跳过（无存储服务时）
- [ ] CHANGELOG.md 已更新
