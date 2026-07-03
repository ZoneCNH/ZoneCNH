# ecb 设计说明

## 架构概览

```text
ECB APIs/Data Portal
   -> ecb-client (collect + normalize + OSS raw + NATS publish)
   -> ecb-server (consume + idempotent + stores + Kafka + API)
   -> macro_data / analysis consumers
```

## 关键设计点

1. client/server 进程级隔离，避免采集抖动影响查询与消费面。
2. 先 raw 后规范化，保证审计可回放。
3. 以 `domain_macro` 统一跨模块语义，避免 provider 字段渗透。
4. 以 `available_at` 实现 no-lookahead。

