# binance 发布合同

- [COMPUTED, HIGH] Spec-Version: v4.1.0
- [COMPUTED, HIGH] Last-Updated: 2026-07-10
- [COMPUTED, HIGH] Current-Verdict: No-Go

## 1. 执行权威

[COMPUTED, HIGH] canonical 格式是 [`docs/sre/DEPLOY-CONTRACT.yaml`](../../../docs/sre/DEPLOY-CONTRACT.yaml) 中的 `zonecnh.deploy-contract.v1`；本文件不创建第二套 schema。

[FRAME, HIGH] `binance` 只提供下列合同输入：

| Canonical 字段 | `binance` 要求 |
| --- | --- |
| `contract_version` | [FRAME, HIGH] 必须等于 `zonecnh.deploy-contract.v1` |
| `release_ref` | [FRAME, HIGH] 不可变 tag 或完整 commit SHA |
| `environment` | [FRAME, HIGH] 由获授权负责人选择 staging 或 production |
| `target` | [FRAME, HIGH] 固定为 `binance` |
| `target_pool` | [FRAME, HIGH] 固定为 `sre/deploy` |
| `action` | [FRAME, HIGH] 固定为 `deploy` |
| `manifest_path` | [FRAME, HIGH] 指向同一 RC 的 release manifest |
| `evidence_path` | [FRAME, HIGH] 指向同一执行的 runner evidence |
| `execution_plane` | [FRAME, HIGH] 与 canonical SSOT 完全一致，业务仓不允许远程执行 |

## 2. 进入条件

- [FRAME, HIGH] SPEC 与 runtime verdict 均为 YES。
- [FRAME, HIGH] Matrix 无 Partial/Drifted/Pending，PRG-001~007 全部通过。
- [FRAME, HIGH] NATS、Kafka、TDengine、Redis、部署 API 五项 external gate 绑定同一 `release_ref` 通过。
- [FRAME, HIGH] release manifest 包含制品摘要、SBOM、CI URL、配置 schema 版本、数据库迁移与回滚兼容结论。
- [FRAME, HIGH] production 变更获得人工审批，且不把生产凭据复制到本仓库或 evidence。

[COMPUTED, HIGH] 当前候选不满足上述条件，因此不得生成 production 执行请求。

## 3. 必需回执

| 回执 | 最小内容 |
| --- | --- |
| runner evidence | [FRAME, HIGH] contract hash、release ref、审批身份、开始/结束时间、不可变日志引用 |
| preflight | [FRAME, HIGH] 配置、迁移、容量、依赖、健康端点与安全门禁结果 |
| canary | [FRAME, HIGH] error rate、P99、consumer lag、freshness、coverage、sink divergence |
| rollback | [FRAME, HIGH] 触发条件、目标 ref、数据兼容性、恢复时间与验证结果 |
| post-deploy | [FRAME, HIGH] 观察窗口、数据完整性与外部查询回读 |

## 4. 回滚原则

[FRAME, HIGH] 回滚同样只能作为 canonical contract 的受控 action 由 SRE 平面执行；业务仓只声明阈值、兼容性与验收条件，不保存环境操作步骤。

[FRAME, HIGH] 若 schema 或数据写入不可逆，必须先有前向修复方案与数据恢复证明；仅回退二进制不能被视为完整回滚。

## 5. 凭据与目标

[FRAME, HIGH] 目标标识、网络地址、服务账号和秘密值只存在于获授权的环境配置中；本仓库的合同和 evidence 只能保存脱敏引用与 hash。

[RULES I BROKE]：无
