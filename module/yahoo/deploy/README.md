# yahoo deploy

部署原则：

1. `yahoo-client` 与 `yahoo-server` 分离部署。
2. NATS、Kafka、taos、postgres、Redis、oss、clickhouse 由平台层独立提供。
3. 配置通过 `configx` 注入，secret 仅引用键名，不落盘明文。

