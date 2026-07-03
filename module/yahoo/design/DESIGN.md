# yahoo 设计（生产级）

## 1. 运行形态

`yahoo` 采用独立 C/S 双服务：

- `cmd/yahoo-client`：采集与 handoff
- `cmd/yahoo-server`：持久化与查询

## 2. 数据流

```text
Yahoo Provider
  │
  ▼
yahoo-client
  ├─ 采集/限流/重试
  ├─ OSS raw 归档
  └─ NATS ingest envelope
        │
        ▼
yahoo-server
  ├─ 幂等/校验/checkpoint
  ├─ taos: 时序事实
  ├─ postgres: catalog/checkpoint/ledger
  ├─ Redis: cache/lock/rate bucket
  ├─ clickhouse: 读模型
  └─ Kafka durable event
        │
        ▼
macro_data / ms_brain / 分析域
```

## 3. 关键设计约束

1. 共享基座强制：配置、观测、存储、消息、韧性能力必须复用基座。
2. 领域共享层强制：跨模块语义统一映射到 `domain_macro`。
3. no-lookahead 强制：`available_at` 作为 as-of 可见性裁剪基准。
4. 事件分层强制：NATS = handoff/control，Kafka = durable business event。

## 4. 深度审查

完整 20 轮覆盖审查见 [DEEP-ANALYSIS-20-PASS.md](DEEP-ANALYSIS-20-PASS.md)。
