# fred client 子模块规格入口

- 子模块：`fred-client`
- 运行形态：独立进程（`cmd/fred-client`）
- 主规格：[`SPEC.md`](SPEC.md)
- 根规格：[`../SPEC.md`](../SPEC.md)

`fred-client` 负责 FRED 采集、归一化、raw-first 归档和 NATS ingest 发布，不承担业务持久化与查询 API。
