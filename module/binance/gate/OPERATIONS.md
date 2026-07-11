# module/binance OPERATIONS.md — 生产运维契约

## Metadata

| Field | Value |
| --- | --- |
| Status | Active — Contract Only |
| Module-Version | v4.1.0 |
| Last-Updated | 2026-07-10 |
| Scope | binance 观测、扩缩容、故障响应与灾恢复契约 |
| Spec-Impact | 生产运维 SRE 指引 |
| Execution Owner | `sre/deploy` |

> [FRAME, HIGH] 本文定义 binance 模块与 SRE 控制面的运维交接，不提供可直接作用于基础设施的命令。

## 1. 模块运行边界

[FRAME, HIGH] binance runtime 由采集侧和服务侧两个逻辑进程组成：采集侧连接 Binance 公共行情源、规范化消息并发布；服务侧消费消息、执行幂等与数据质量检查、持久化并向下游分发。

```text
公共行情源
    │
    ▼
采集侧：catalog → 白名单 → 历史/实时接入 → 规范化
    │
    ▼
消息总线
    │
    ▼
服务侧：去重 → 完整性校验 → 持久化 → 归档/下游
```

[FRAME, HIGH] 产品线范围为 `spot`、`um_perp`、`cm_perp`、`options`；各产品线的实际能力必须以同一 release 的 Capability Matrix 和 Evidence Bundle 为准。

## 2. 职责划分

| 责任域 | binance 模块负责人 | SRE 控制面 |
| --- | --- | --- |
| 发布输入 | 工件摘要、配置 schema、迁移声明、SLO、回滚意图 | 校验并接受发布请求 |
| 基础设施 | 声明依赖契约和容量模型 | 解析环境别名、提供依赖和隔离执行面 |
| 扩缩容 | 给出无状态性、分片键、consumer identity 约束 | 执行容量变更并返回证据 |
| 故障处置 | 提供错误分类、幂等语义和重放边界 | 执行环境操作、记录时间线和回执 |
| 凭据 | 只声明所需 secret key 名称和权限范围 | 保管值、轮换并提供有效性证明 |
| 发布判定 | 汇总功能和数据完整性证据 | 汇总环境、灰度和回滚证据 |

[KNOWN, HIGH] CICD-001 要求所有生产变更由 `sre/deploy` self-hosted runner pool 执行；业务模块不得携带直接基础设施操作。

## 3. 扩缩容契约

| 组件 | 模块必须声明 | SRE 必须验证 |
| --- | --- | --- |
| 服务侧实例 | durable consumer identity、幂等作用域、共享状态边界 | 扩容前后无重复写入、无消息丢失、lag 可恢复 |
| 采集侧实例 | 产品线、symbol 分片键、连接预算、所有权租约 | 同一 stream 只有一个有效 owner，切换无缺口 |
| 历史回补 worker | 时间窗、请求权重、分页游标和幂等键 | 限频受控，回补不会压垮实时链路 |
| 存储与消息依赖 | 吞吐、保留期、RPO/RTO 和降级语义 | 容量、保留与恢复演练满足声明 |

[INFERRED, HIGH] 在缺少多实例所有权、幂等范围和故障切换证据时，不能仅凭“进程无状态”声称可水平扩展。

## 4. 生产观测契约

| 信号 | 最低维度 | 处置入口 |
| --- | --- | --- |
| ingest events / rejects | product_line、event_type、symbol、reject_code | 数据质量诊断 |
| stream active / reconnects | product_line、connection_group、reason | 实时链路诊断 |
| history jobs / coverage gaps | product_line、event_type、window、state | 回补与覆盖率诊断 |
| orderbook sequence / checksum | product_line、symbol、generation、result | 订单簿重同步 |
| consumer lag / redelivery | durable identity、subject、reason | 消费容量与重放 |
| storage latency / failures | backend、operation、result | 存储降级与恢复 |
| dead-letter volume | stage、reason、replay_state | 隔离、修复与重放 |

[FRAME, HIGH] 每个告警必须引用已批准 SLO 的查询和阈值，不能在本文硬编码未经验证的生产阈值。

## 5. 故障响应契约

| 症状 | 模块侧判别 | SRE 处置目标 | 退出条件 |
| --- | --- | --- | --- |
| 实时事件停止 | 区分源端静默、连接断开、白名单拒绝和发布失败 | 隔离故障域并保留现场证据 | stream 恢复且缺口已建立回补任务 |
| 订单簿不连续 | sequence、generation 或 checksum 异常 | 阻断不可信快照传播 | 完成重同步且连续性证据通过 |
| 消费积压增长 | 消费速率低于生产速率或依赖变慢 | 恢复容量且避免重复写入 | lag 回落且幂等指标无异常 |
| 持久化失败 | 区分可重试、永久拒绝和部分成功 | 保护实时链路并保存隔离记录 | 存储恢复且隔离记录可审计重放 |
| 历史覆盖缺口 | coverage 与预期窗口不一致 | 控制回补优先级和请求预算 | 覆盖闭合且与实时数据无重复/丢失 |

[FRAME, HIGH] 事故响应顺序为：保护数据可信度、冻结证据、识别故障域、执行最小恢复、验证完整性、再恢复正常流量。

## 6. 灾恢复与重放

[FRAME, HIGH] 每个发布版本必须为消息、主存储、归档和 catalog 分别声明 RPO、RTO、恢复来源与验证查询。

[FRAME, HIGH] dead-letter 重放必须满足：根因已修复、输入内容可审计、幂等键稳定、目标时间窗明确、重放结果与原记录一一关联。没有 durable receipt 的“已发送”不计为恢复成功。

[FRAME, HIGH] 恢复演练由 SRE 控制面执行并返回签名回执；本文不保存基础设施地址、账户、私有服务位置或操作序列。

## 7. 运维就绪证据

| Gate | 通过证据 |
| --- | --- |
| Observability | 关键指标、日志关联 ID、SLO 查询和告警路由已在目标环境验证 |
| Resilience | 断连、依赖失败、重投、重复消息和部分写入演练通过 |
| Data Integrity | 四产品线历史/实时交界、订单簿连续性、去重和覆盖率证据通过 |
| Recovery | 备份、恢复、隔离记录重放和回滚均有同 commit 回执 |
| Security | secret 引用、最小权限和轮换证明存在，仓库无敏感值 |
| Release | [`../release/DEPLOYMENT-ORCHESTRATION.md`](../release/DEPLOYMENT-ORCHESTRATION.md) 的请求与回执闭合 |

[INFERRED, HIGH] 任一 Gate 缺证据时只能声明“局部能力已验证”，不能声明生产运维就绪。

## 8. 文档同步

[FRAME, HIGH] 本文应与 [`../spec/SPEC.md`](../spec/SPEC.md) 的部署与可观测性要求、[`RELEASE-CHECKLIST.md`](RELEASE-CHECKLIST.md) 的发布判定、[`../release/DEPLOYMENT-ORCHESTRATION.md`](../release/DEPLOYMENT-ORCHESTRATION.md) 的执行契约及 [`docs/sre/DEPLOY-CONTRACT.yaml`](../../../docs/sre/DEPLOY-CONTRACT.yaml) 的 canonical schema 同步。

[RULES I BROKE]：无。
