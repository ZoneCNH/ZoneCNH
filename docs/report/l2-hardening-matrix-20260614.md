# L2 Adapter 生产硬化矩阵

> FoundationX v2 Trust Alignment — P4 执行规范
>
> 定义所有 L2 adapter（Redis/Kafka/NATS/PostgreSQL/TDengine/OSS/ClickHouse）的统一生产硬化门禁。

## 五级硬化模型

| 级别 | 名称 | 通过条件 | 状态含义 |
|:----:|------|----------|----------|
| L2-T1 | 本地实现闭合 | go test/vet/lint、contract tests、API snapshot、secret redaction unit | 基础代码质量达标 |
| L2-T2 | Docker integration | docker-compose up、CRUD、health check、error normalization | 容器化集成可用 |
| L2-T3 | Live dev integration | 真实 dev 服务、真实 auth、不打印 secret、manifest 记录 redacted endpoint | 真实环境连通 |
| L2-T4 | Failure profile | bad credential、timeout、cancellation、restart、TLS/auth failure、pool exhaustion、large payload、metrics cardinality | 故障模式覆盖 |
| L2-T5 | Production evidence | production-like soak、downstream adoption、external CI、factory_grade_allowed=true | 生产就绪 |

## 逐模块硬化矩阵

| Gate | redisx | kafkax | natsx | postgresx | taosx | ossx | clickhousex |
|------|:------:|:------:|:-----:|:---------:|:-----:|:----:|:-----------:|
| config validation | ✅ | ✅ | ✅ | ✅ | ✅ | required | required |
| secret redaction | ✅ | ✅ | ✅ | ✅ | ✅ | required | required |
| health check | ✅ | ✅ | ✅ | ✅ | ✅ | required | required |
| error normalization | ✅ | ✅ | ✅ | ✅ | ✅ | required | required |
| context cancellation | ✅ | ✅ | ✅ | ✅ | ✅ | required | required |
| bad credential | required | required | required | required | required | required | required |
| TLS/auth profile | required | required | required | required | required | required | required |
| restart/reconnect | required | required | required | required | required | N/A | required |
| pool exhaustion | required | N/A | N/A | required | required | N/A | required |
| large payload | required | required | required | required | required | required | required |
| metrics cardinality | required | required | required | required | required | required | required |
| no secret in evidence | required | required | required | required | required | required | required |

## 当前等级与目标

| 模块 | 当前等级 | 目标等级 | 优先动作 |
|------|:--------:|:--------:|----------|
| natsx | L2-T3 | L2-T4 | formal 4-source arbiter、production TLS、production SLO、consumer lifecycle |
| postgresx | L2-T3 | L2-T4 | release history decision、migration failure、pool exhaustion、DSN redaction |
| kafkax | L2-T2/T3 | L2-T4 | consumer rebalance/offset、producer delivery guarantee、TLS/auth |
| redisx | L2-T3 | L2-T4 | TLS/cluster/sentinel boundary、bad auth/reconnect/timeout profile |
| taosx | L2-T3 | L2-T4/T5 | production soak、large batch、auth failure、identifier fuzz |
| ossx | L2-T2 | L2-T3 | Aliyun OSS live profile、README/API/evidence |
| clickhousex | L2-T1 | L2-T2/T3 | release/status alignment first, then Docker integration |

## 每模块必须覆盖的 Failure Profile

| Profile | 验证方法 | 阻断条件 |
|---------|----------|----------|
| bad credential | 提供错误凭证，验证返回明确错误且不泄露 secret | panic、secret 出现在日志/错误消息中 |
| TLS/auth failure | 配置错误 CA/证书，验证连接被拒绝且有明确错误 | 静默回退到非 TLS、错误信息泄露配置路径 |
| timeout | 注入延迟超过 deadline，验证 context 取消传播 | goroutine 泄漏、panic、无超时错误 |
| context cancellation | 请求中途 cancel context，验证资源释放 | goroutine 泄漏、连接未关闭 |
| network reset | 中断网络连接，验证重连和错误处理 | panic、状态不一致、goroutine 泄漏 |
| server restart | 重启后端服务，验证客户端恢复 | 永久连接失败、无重试、状态污染 |
| pool exhaustion | 耗尽连接池，验证排队/拒绝行为 | panic、无限等待、无超时 |
| large payload | 发送超过典型大小的请求，验证内存和性能 | OOM、goroutine 泄漏、无大小限制 |
| metrics cardinality | 验证 metrics label 不会无限增长 | 高基数标签（user ID、order ID 等） |
| secret redaction | 验证错误消息、日志、evidence 中无 secret | secret 以明文出现在任何输出中 |

## Failure Profile 测试模板

```go
func TestBadCredential(t *testing.T) {
    // Arrange: 创建客户端，提供错误凭证
    cfg := Config{
        Addr:     getTestAddr(t),
        Password: "wrong-password",
        Timeout:  2 * time.Second,
    }
    client, err := New(cfg)
    require.NoError(t, err)
    defer client.Close()

    // Act: 尝试操作
    ctx := context.Background()
    err = client.Ping(ctx)

    // Assert: 返回明确错误，不泄露 secret
    require.Error(t, err)
    assert.NotContains(t, err.Error(), "wrong-password")
    assert.NotContains(t, err.Error(), cfg.Password)
}

func TestTimeout(t *testing.T) {
    // Arrange
    cfg := Config{Addr: getTestAddr(t), Timeout: 50 * time.Millisecond}
    client, _ := New(cfg)
    defer client.Close()

    // Act: 注入延迟 > timeout
    injectLatency(t, 200*time.Millisecond)
    ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
    defer cancel()

    err := client.Ping(ctx)

    // Assert: context deadline exceeded
    assert.Error(t, err)
    assert.True(t, errors.Is(err, context.DeadlineExceeded))
}

func TestRestart(t *testing.T) {
    // Arrange
    client, _ := New(Config{Addr: getTestAddr(t)})
    defer client.Close()
    require.NoError(t, client.Ping(context.Background()))

    // Act: 重启服务
    restartService(t)
    time.Sleep(2 * time.Second)

    // Assert: 恢复连接
    err := client.Ping(context.Background())
    require.NoError(t, err)
}
```

## 验收标准

P4 完成条件（全部 L2 adapter 满足）：

- [ ] L2-T4 failure profile 全部通过
- [ ] natsx 正式四源 98+ arbiter 通过
- [ ] postgresx release history decision 完成
- [ ] downstream smoke 覆盖 x.go + 关键 L2 消费链
- [ ] production soak 未达标时仍可 release-dev，不得宣称 production-ready/factory-grade

---

> 本规范为 P4 执行基线。实际硬化按模块优先级依次推进：natsx → postgresx → kafkax → redisx → taosx → ossx → clickhousex。
