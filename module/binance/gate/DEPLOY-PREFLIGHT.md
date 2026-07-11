# Binance 发布预检契约

> [FRAME, HIGH] 本文件只定义 binance runtime 向 SRE 执行平面提交发布请求前的门禁、输入和证据回执，不包含可执行的生产操作。

| 字段 | 值 |
| --- | --- |
| Status | Active — Contract Only |
| Version | v2.0.0 |
| Last-Updated | 2026-07-10 |
| Scope | binance runtime 发布预检与证据交接 |
| Execution Owner | `sre/deploy` |
| Canonical Contract | [`docs/sre/DEPLOY-CONTRACT.yaml`](../../../docs/sre/DEPLOY-CONTRACT.yaml)（`zonecnh.deploy-contract.v1`） |
| Related | [`RELEASE-CHECKLIST.md`](RELEASE-CHECKLIST.md)、[`DEPLOYMENT-READINESS-CHECKLIST.md`](DEPLOYMENT-READINESS-CHECKLIST.md)、[`../release/DEPLOYMENT-ORCHESTRATION.md`](../release/DEPLOYMENT-ORCHESTRATION.md) |

## 1. 权责边界

[KNOWN, HIGH] `CONSTITUTION.md` 的 CICD-001 要求发布执行只能进入隔离的 `sre/deploy` self-hosted runner pool；业务模块及其文档不得内联远程访问、主机进程控制、容器编排或直接部署步骤。

[FRAME, HIGH] binance 模块负责人只负责提交经过签名的发布请求、验证策略和回滚意图；SRE 控制面负责解释目标环境别名、访问生产基础设施、执行变更并返回不可变回执。

[FRAME, HIGH] 本文出现的环境、工件和回执均使用逻辑标识符。生产地址、账户名、凭据位置和私有服务地址不得写入仓库。

## 2. 发布前硬门禁

| Gate | 必须提供的证据 | 失败行为 |
| --- | --- | --- |
| G1 — 人工授权 | 技术负责人和 SRE 值班负责人签字，含变更单 ID | fail closed，agent 不代签 |
| G2 — 版本身份 | immutable commit、release tag、artifact digest 三者可追溯且一致 | 拒绝发布请求 |
| G3 — 本地质量 | build、vet、race、全量测试、boundary gates 的原始日志和退出码 | 任一失败即停止 |
| G4 — 规格治理 | Goal/Spec/Matrix/Acceptance/Release Checklist 对同一版本给出一致判定 | 冲突即停止 |
| G5 — 外部证据 | live、持久化、消息系统和历史回补证据均绑定同一 commit | 缺失或陈旧即停止 |
| G6 — 配置与密钥 | SRE 返回“引用存在且访问策略有效”的证明；业务仓不接收明文或物理路径 | 未确认即停止 |
| G7 — 灰度与观测 | 已批准的流量阶梯、SLO 查询、观察窗口和中止阈值 | 缺一不可执行 |
| G8 — 回滚能力 | 前一稳定工件 digest、兼容性判断、回滚演练回执和负责人 | 未验证即停止 |
| G9 — 执行隔离 | 目标 runner pool 精确为 `sre/deploy`，请求有唯一 run ID | pool 不匹配即停止 |

[FRAME, HIGH] “本地门禁通过”只证明该 commit 的本地验证结果，不等价于外部依赖可用、生产配置正确或模块可发布。

## 3. Canonical SRE 部署合同

[FRAME, HIGH] 发布请求必须直接使用 [`docs/sre/DEPLOY-CONTRACT.yaml`](../../../docs/sre/DEPLOY-CONTRACT.yaml) 的 `zonecnh.deploy-contract.v1`；本文件不创建模块私有 schema。字段缺失、为空或引用不一致时，接收方必须 fail closed。

```json
{
  "contract_version": "zonecnh.deploy-contract.v1",
  "release_ref": "<tag-or-full-commit-sha>",
  "environment": "<staging-or-production>",
  "target": "binance",
  "target_pool": "sre/deploy",
  "action": "deploy",
  "dry_run": false,
  "manifest_path": "release/manifest/release-manifest.json",
  "evidence_path": "release/evidence/runner-evidence.json",
  "execution_plane": {
    "repository": "ZoneCNH/sre",
    "workflow": "ZoneCNH/sre/.github/workflows/deploy-contract.yml@main",
    "runner_pool": "sre/deploy",
    "remote_execution_allowed_in_this_repo": false
  }
}
```

[FRAME, HIGH] `environment` 只能是 canonical contract 允许的逻辑环境名；人工批准、工件摘要、灰度、回滚与 evidence bundle 必须由 `manifest_path`/`evidence_path` 指向的同一 RC 制品承载，不得扩展第二套顶层字段。

## 4. 预检与交接流程

1. [FRAME, HIGH] 模块负责人冻结 commit，并生成与该 commit 绑定的本地和外部证据包。
2. [FRAME, HIGH] 治理审查者核对版本身份、追溯链、未决阻塞和人工签字。
3. [FRAME, HIGH] 模块负责人把 §3 canonical contract 提交至 SRE 控制面；提交动作本身不构成发布批准。
4. [FRAME, HIGH] SRE 控制面校验 runner pool、变更窗口、配置引用、灰度策略和回滚工件。
5. [FRAME, HIGH] SRE 控制面执行变更，并返回 §5 定义的签名回执；业务仓只消费回执，不复述执行命令。
6. [FRAME, HIGH] 任何证据冲突、观测异常或回执缺失均保持 `release_closeable=NO`。

## 5. 必须回传的发布回执

| 字段 | 说明 |
| --- | --- |
| run_id | SRE 执行的唯一身份 |
| contract_digest | §3 canonical contract 的内容摘要 |
| artifact_digest | 实际执行工件的不可变摘要 |
| environment_alias | 已脱敏的逻辑环境名 |
| started_at / finished_at | UTC 时间窗口 |
| rollout_result | 每个流量阶梯的结果及观测证据引用 |
| health_result | 已批准健康策略的结果，不记录私有地址 |
| rollback_result | 未触发、成功或失败，附证据引用 |
| approver_receipts | 技术负责人和 SRE 负责人签名引用 |
| final_state | `SUCCEEDED`、`ROLLED_BACK` 或 `FAILED` |

[FRAME, HIGH] 回执必须写入 canonical contract 的 `evidence_path`，并与 `release_ref` 和 manifest 同时绑定；单独的文字结论不能替代机器回执。

## 6. 历史快照（2026-07-08，已脱敏）

[COMPUTED, MED] 旧版本文曾记录：当时运行工件与 v0.15.0 暂存工件摘要一致、模块健康检查返回成功，且采集进程恢复了四条产品线的 catalog 同步。该陈述仅是 2026-07-08 文档中保存的事后记录，本次修改未重新访问生产环境验证。

[COMPUTED, HIGH] 历史记录中的生产网络位置、主机账户、凭据物理路径、服务控制细节和可复用操作步骤已从公开治理文档删除。

[INFERRED, HIGH] 该历史快照不能证明当前 commit 已部署、当前外部依赖健康或当前版本满足发布门禁；当前判定必须重新完成 §2，并以同一 commit 的 SRE 回执为准。

## 7. 安全红线

- [FRAME, HIGH] 不代签、不绕过门禁、不把用户口头授权解释为永久发布授权。
- [FRAME, HIGH] 不在业务仓保存生产地址、账户名、私有服务地址、凭据内容或凭据物理路径。
- [FRAME, HIGH] 不在业务仓记录可直接作用于生产环境的命令、脚本参数或主机操作序列。
- [FRAME, HIGH] 不把历史运行事实提升为当前 release approval。
- [FRAME, HIGH] 不在缺失签名回执时将发布状态标记为成功。

[RULES I BROKE]：无。
