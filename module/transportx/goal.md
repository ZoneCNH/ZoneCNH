# transportx Goal

- Status: Approved
- Goal-Version: v1.0.1
- Last-Updated: 2026-06-14
- Owner: ZoneCNH
- Layer: 基座 · 传输契约
- Repository: https://github.com/ZoneCNH/transportx

## 目标

`transportx` 定义跨 runtime 与 adapter 的传输契约，使 Foundation 模块在不绑定具体 broker、HTTP 框架、RPC 框架或业务 DTO 的前提下，共享一致的 Envelope、Endpoint、ServiceIdentity、运行时生命周期、控制面和交付回执语义。

## 成功标准

- Envelope、Endpoint、DeliveryReceipt 与 ServiceIdentity 字段被规格化，并有兼容性规则。
- runtime 生命周期覆盖 start、pause、drain、resume、shutdown 与 force-stop。
- kill switch、mirror、canary 与 backpressure 控制面有可验证状态转换。
- 传输错误、幂等冲突、限流、超时、重试与死信路径有统一错误码。
- conformance gates 能在 CI 中验证规格、追踪矩阵、兼容性和发布证据。

## 非目标

- 不实现具体 broker client、HTTP server、RPC server 或 storage driver。
- 不定义业务事件语义、领域 DTO 或 domain-specific routing。
- 不取代 `contracts` 的跨域端口、事件协议和 DTO 契约。
- 不承载账号、交易、行情或风控领域逻辑。

## 交付边界

- `module/transportx/SPEC.md` 是 v1.0.1 规格基线。
- `module/transportx/TRACEABILITY.md` 是 FR、AC、TC 与门禁映射。
- 根 `README.md`、`ARCHITECTURE.md`、`STATUS.md` 与 `module/README.md` 必须列出 `transportx`。
- `.github/ci/spec-lint.sh`、`.github/ci/traceability-check.sh`、`.github/ci/status-consistency-check.sh` 与 `.github/ci/spec-drift-guard.sh` 必须通过。

## 完成定义

- 规格文档 23 节完整，状态为 `Approved`，版本为 `v1.0.1`。
- 追踪矩阵覆盖全部 `FR-*`，且所有 `TC-*` 在规格中存在。
- CI 必需模块清单包含 `transportx`。
- 发布前必须补齐实现仓库 release tag、conformance report、changelog 与 drift evidence。
