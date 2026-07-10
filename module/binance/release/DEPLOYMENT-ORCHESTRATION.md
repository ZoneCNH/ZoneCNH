# Binance 发布执行编排契约

> [FRAME, HIGH] 本文件定义 binance 发布请求进入 SRE 控制面后的阶段、决策点和证据回执，不包含可执行的生产操作。

| 字段 | 值 |
| --- | --- |
| Status | Contract Only — Not a Release Approval |
| Version | v2.0.0 |
| Last-Updated | 2026-07-10 |
| Execution Plane | `sre/deploy` self-hosted runner pool |
| Entry Gate | `../gate/DEPLOY-PREFLIGHT.md` |
| Final Gate | `../gate/RELEASE-CHECKLIST.md` |
| Canonical Contract | [`docs/sre/DEPLOY-CONTRACT.yaml`](../../../docs/sre/DEPLOY-CONTRACT.yaml)（`zonecnh.deploy-contract.v1`） |

## 1. 权威判定

[FRAME, HIGH] 本文的流程定义不证明任何版本已通过预检、已进入生产或可关闭发布。每次执行必须绑定唯一的 release tag、完整 commit、artifact digest、Evidence Bundle 和人工批准。

[KNOWN, HIGH] CICD-001 将生产执行权集中在 `sre/deploy`；binance 业务仓只提交声明式请求并消费回执，不持有环境访问细节。

## 2. 输入契约

[FRAME, HIGH] SRE 控制面只接受通过 [`../gate/DEPLOY-PREFLIGHT.md`](../gate/DEPLOY-PREFLIGHT.md) §2 的请求，并且请求必须符合 [`docs/sre/DEPLOY-CONTRACT.yaml`](../../../docs/sre/DEPLOY-CONTRACT.yaml)。最小输入如下：

- [FRAME, HIGH] 不可变工件身份：commit、tag、artifact digest。
- [FRAME, HIGH] 逻辑目标环境和变更单，不含网络位置或账户信息。
- [FRAME, HIGH] 配置 schema 版本及 secret 引用清单，不含 secret 值或物理位置。
- [FRAME, HIGH] 数据兼容性、迁移前置条件和不可逆变更声明。
- [FRAME, HIGH] 经批准的灰度阶梯、SLO 查询、观察窗口和中止阈值。
- [FRAME, HIGH] 前一稳定工件、回滚兼容性和恢复验证策略。
- [FRAME, HIGH] 技术负责人、数据负责人和 SRE 值班负责人的签名引用。

## 3. 编排状态机

```text
REQUESTED
    │ validate identity + approvals + evidence
    ▼
VALIDATED ── evidence conflict ──► REJECTED
    │ reserve isolated execution slot
    ▼
STAGED ───── staging failure ────► FAILED
    │ progressive rollout
    ▼
CANARY ───── threshold breach ───► ROLLBACK_REQUIRED
    │ all approved observations pass
    ▼
PROMOTED ─── post-check failure ─► ROLLBACK_REQUIRED
    │ signed receipt complete
    ▼
SUCCEEDED
```

[FRAME, HIGH] `FAILED`、`REJECTED` 和 `ROLLBACK_REQUIRED` 都是 fail-closed 状态；只有 `SUCCEEDED` 且回执完整时，才允许 Release Gate 消费该次执行结果。

## 4. 阶段契约

### 4.1 Validate

1. [FRAME, HIGH] 核对请求 digest、工件身份、人工批准和变更窗口。
2. [FRAME, HIGH] 确认所有证据绑定同一 commit，且不存在陈旧、缺失或互相冲突的结论。
3. [FRAME, HIGH] 确认目标 pool 精确为 `sre/deploy`，并分配唯一 run ID。

### 4.2 Stage

1. [FRAME, HIGH] SRE 控制面解析逻辑环境、配置引用和工件引用。
2. [FRAME, HIGH] 在隔离执行面验证启动条件、依赖连接、schema 兼容性和健康策略。
3. [FRAME, HIGH] 任一检查失败都停止，不进入流量阶段。

### 4.3 Progressive Rollout

1. [FRAME, HIGH] 按批准策略逐级增加流量；本文不预设百分比和时间窗。
2. [FRAME, HIGH] 每一级记录起止时间、样本量、错误率、延迟、消息积压、数据拒绝率和订单簿完整性。
3. [FRAME, HIGH] 指标越界、数据完整性异常或证据采集中断时立即转入 `ROLLBACK_REQUIRED`。
4. [FRAME, HIGH] 未完成规定观察窗口不得提前提升流量。

### 4.4 Promote and Observe

1. [FRAME, HIGH] 全量提升后继续执行批准的短期与长期观察计划。
2. [FRAME, HIGH] 验证四产品线的实时事件、历史/实时交界、白名单策略、持久化和下游消费。
3. [FRAME, HIGH] 观察期内发生回滚时，最终状态不得保留为 `SUCCEEDED`。

## 5. 回滚契约

| 触发类别 | 示例信号 | 必须动作 |
| --- | --- | --- |
| 数据可信度 | sequence 缺口、checksum 异常、重复或丢失超出策略 | 停止提升、保护不可信输出、转入回滚 |
| 服务质量 | 已批准 SLO 的错误率或延迟越界 | 转入回滚并保留观测窗口证据 |
| 依赖故障 | 消息、存储、catalog 或归档依赖不可用 | 按降级策略判断；无安全降级则回滚 |
| 安全事件 | 权限、凭据或供应链证据异常 | 立即停止并升级安全响应 |
| 证据失败 | 回执丢失、指标采集中断、工件身份冲突 | fail closed，不得假定执行成功 |

[FRAME, HIGH] 回滚由 SRE 控制面使用请求中声明的前一稳定工件执行。回滚成功必须同时证明：实际工件身份恢复、服务健康、消息处理恢复、数据完整性重新闭合。

[INFERRED, HIGH] 仅看到进程存活或健康路由成功，不足以证明回滚成功。

## 6. 输出回执

[FRAME, HIGH] SRE 控制面必须把机器可读且带签名的 runner evidence 写入 canonical contract 的 `evidence_path`；本文不定义 `foundationx.*` 或其他私有 receipt schema。

| 必需证据 | 最低内容 |
| --- | --- |
| identity | run ID、canonical contract digest、`release_ref`、实际 artifact digest |
| execution | 逻辑环境、状态、开始/结束 UTC 时间、执行平面 identity |
| rollout | 每个批准流量阶梯及不可变观测引用 |
| integrity | 四业务线数据完整性、健康与外部 readback 引用 |
| rollback | 未触发或执行结果、目标工件及恢复验证引用 |
| approvals | 技术、数据、安全与 SRE 的签名引用 |

[FRAME, HIGH] Release Gate 必须验证 canonical contract 版本、签名、contract digest、工件 digest 与时间窗口；不能根据自然语言总结推断成功。

## 7. 事故与升级角色

| 角色 | 职责 |
| --- | --- |
| Incident Commander | 作出停止、回滚和升级决定，维护时间线 |
| SRE On-call | 操作执行面并保全环境证据 |
| Module Owner | 解释模块语义、错误分类和兼容性 |
| Data Owner | 判断历史/实时覆盖和数据完整性 |
| Security On-call | 处理权限、凭据和供应链异常 |

[FRAME, HIGH] 联系方式由 SRE 值班系统解析；公开仓库只保存角色，不保存个人电话、邮箱或私有通讯地址。

## 8. 完成条件

[FRAME, HIGH] 一次编排只有同时满足下列条件才可标记 `SUCCEEDED`：工件身份一致、所有批准流量阶梯完成、观察窗口完成、四产品线数据完整性通过、未决告警为零、回执字段完整且签名有效。

[FRAME, HIGH] 即使编排状态为 `SUCCEEDED`，最终 `release_closeable` 仍由 [`../gate/RELEASE-CHECKLIST.md`](../gate/RELEASE-CHECKLIST.md) 汇总全部发布证据后判定。

[RULES I BROKE]：无。
