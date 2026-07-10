# module/binance 发布执行边界

- Spec-Version: v4.1.0 [COMPUTED, HIGH]
- Runtime-Version: v0.15.1（last published tag；不是当前 RC）[COMPUTED, HIGH]
- [COMPUTED, HIGH] Last-Updated: 2026-07-10
- [COMPUTED, HIGH] Current-Verdict: `release_closeable_spec=NO`、`release_closeable_runtime=NO`

## 权威入口

[COMPUTED, HIGH] 本目录不保存目标地址、账号、凭据、主机路径或可执行发布步骤。

[COMPUTED, HIGH] 发布合同格式以 [`docs/sre/DEPLOY-CONTRACT.yaml`](../../../docs/sre/DEPLOY-CONTRACT.yaml) 为唯一权威，实际合同由仓库规定的 release manifest 生成器创建，真实执行只进入该合同声明的 `sre/deploy` 平面。

| 文档 | 作用 |
| --- | --- |
| [`DEPLOY.md`](DEPLOY.md) | [FRAME, HIGH] `binance` 对 canonical deploy contract 的输入、前置门禁与回执要求 |
| [`NGINX-REVERSE-PROXY.md`](NGINX-REVERSE-PROXY.md) | [FRAME, HIGH] 边缘代理、安全暴露面与凭据轮换合同；不包含环境详情 |
| [`../gate/DEPLOY-PREFLIGHT.md`](../gate/DEPLOY-PREFLIGHT.md) | [FRAME, HIGH] 发布前 fail-closed 检查 |
| [`../gate/RELEASE-CHECKLIST.md`](../gate/RELEASE-CHECKLIST.md) | [FRAME, HIGH] Go/No-Go 裁决清单 |

## 安全说明

[COMPUTED, HIGH] 2026-07-10 审计发现旧文档曾包含生产地址和凭据样式字面量；这些值已从活跃文档删除。

[INFERRED, HIGH] 若旧字面量曾在任何环境真实生效，负责人必须立即轮换对应凭据、检查访问日志并保存安全事件回执；删除文档不能证明旧凭据已失效。

[RULES I BROKE]：无
