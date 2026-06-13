# transportx Goal

- Status: Approved
- Goal-Version: v1.1.0
- Last-Updated: 2026-06-14
- Owner: ZoneCNH
- Layer: 基座 · 传输契约
- Repository: https://github.com/ZoneCNH/transportx

## 目标

`transportx` 定义跨 runtime 与 adapter 的传输契约，使 Foundation 模块在不绑定具体 broker、HTTP 框架、RPC 框架或业务 DTO 的前提下，共享一致的 Envelope、Endpoint、ServiceIdentity、QoS、Codec、RPC、EventBus、Stream、六通信平面、运行时生命周期、控制面、执行模式、Outbox/Inbox SPI、Audit Plane 和交付回执语义。

定位三角：

```text
contracts 定义"传什么"
transportx 定义"怎么传"
kafkax / natsx / grpc / http / websocket 是"用什么传"
```

## 成功标准

- Envelope、Endpoint、DeliveryReceipt 与 ServiceIdentity 字段被规格化，并有兼容性规则。
- QoS 五级分类（REALTIME_BEST_EFFORT / DURABLE_EVENT / COMMAND_IDEMPOTENT / COMMAND_STRICT / AUDIT）定义完成，含硬规则约束。
- Codec 接口标准化，JSON codec 作为默认实现。
- TopicRegistry、MethodRegistry、SchemaRegistry 接口定义完成，含命名规范和兼容性规则。
- runtime 生命周期覆盖 start、pause、drain、resume、shutdown 与 force-stop。
- kill switch、mirror、canary 与 backpressure 控制面有可验证状态转换。
- 执行模式（LIVE / PAPER / REPLAY / DRY_RUN）gate 规则定义完成。
- Outbox/Inbox SPI 和 Audit Plane 接口定义完成。
- 数据分级（PUBLIC / INTERNAL / CONFIDENTIAL / SECRET）纳入传输契约。
- 传输错误、幂等冲突、限流、超时、重试与死信路径有统一错误码。
- conformance gates 能在 CI 中验证规格、追踪矩阵、兼容性和发布证据。

## 非目标

- 不实现具体 broker client、HTTP server、RPC server 或 storage driver。
- 不定义业务事件语义、领域 DTO 或 domain-specific routing。
- 不取代 `contracts` 的跨域端口、事件协议和 DTO 契约。
- 不承载账号、交易、行情或风控领域逻辑。
- 不实现业务 outbox 编排、业务幂等语义或业务 workflow engine。

## 交付边界

- `module/transportx/SPEC.md` 是 v1.1.0 规格基线（25 FRs, 18 BRs, 25 ACs, 25 TCs, 12 CI gates）。
- `module/transportx/TRACEABILITY.md` 是 FR、BR、AC、TC 与门禁映射。
- 根 `README.md`、`ARCHITECTURE.md`、`STATUS.md` 与 `module/README.md` 必须列出 `transportx`。
- `.github/ci/spec-lint.sh`、`.github/ci/traceability-check.sh`、`.github/ci/status-consistency-check.sh` 与 `.github/ci/spec-drift-guard.sh` 必须通过。

## 完成定义

- 规格文档 23 节完整，状态为 `Approved`，版本为 `v1.1.0`。
- 追踪矩阵覆盖全部 25 FRs + 18 BRs，且所有 25 TCs 在规格中存在。
- CI 必需模块清单包含 `transportx`。
- 发布前必须补齐实现仓库 release tag、conformance report、changelog 与 drift evidence。
