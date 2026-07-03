# ecb 边界门禁

## 必须通过

1. client 不得依赖 server 内部包，不得直写业务库。
2. server 不得调用 provider 采集逻辑。
3. 对外契约必须是 API/Kafka/`domain_macro`，禁止 provider DTO 外泄。
4. 存储与消息接入必须经共享基座组件。
5. 文档/源码不得出现 secret 明文值。

## 目标状态

- 与 `module/binance` 一致的 C/S 可审计边界。
- 与 `module/fred` 一致的宏观 no-lookahead 与回补语义。

