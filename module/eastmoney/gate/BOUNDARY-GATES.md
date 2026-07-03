# eastmoney 边界门禁

## 必须

1. `eastmoney-client` 与 `eastmoney-server` 必须独立部署、独立扩缩容。
2. 必须复用共享基座组件接入配置、观测、消息和存储。
3. 必须使用 `domain_macro` 作为跨模块共享语义层。
4. 必须启用 no-lookahead：缺失 `available_at` 或未来数据 fail-closed。
5. 必须保持 NATS/Kafka 分层：NATS=handoff/control，Kafka=durable events。

## 禁止

1. 禁止跨模块暴露 Eastmoney 私有 DTO。
2. 禁止模块绕过基座直接直连基础设施。
3. 禁止把 Redis/ClickHouse 作为唯一权威数据源。
4. 禁止在文档、配置样例、日志中写入 secret 值。
