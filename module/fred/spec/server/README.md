# fred server 子模块规格入口

- 子模块：`fred-server`
- 运行形态：独立进程（`cmd/fred-server`）
- 主规格：[`SPEC.md`](SPEC.md)
- 根规格：[`../SPEC.md`](../SPEC.md)

`fred-server` 负责消费 NATS ingest envelope、幂等校验、多存储写入、Kafka durable event 发布和查询/管理 API。
