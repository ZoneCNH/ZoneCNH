# binance 边缘代理与外部暴露合同

- [COMPUTED, HIGH] Spec-Version: v4.1.0
- [COMPUTED, HIGH] Last-Updated: 2026-07-10
- [COMPUTED, HIGH] Status: No-Go；本文不证明任何环境已部署

## 1. 边界

[FRAME, HIGH] 边缘代理由 SRE 平面拥有；`binance` 只声明需要暴露的公共 API、必须保持私有的管理面、认证、审计、限流与证书要求。

| Surface | 暴露策略 | 生产要求 |
| --- | --- | --- |
| public market read API | [FRAME, HIGH] 仅显式 allowlist 的只读路径 | [FRAME, HIGH] TLS、限流、schema validation、访问日志脱敏 |
| health/readiness | [FRAME, HIGH] 最小信息公开或仅内部探测 | [FRAME, HIGH] 不返回依赖地址、凭据或堆栈 |
| admin | [FRAME, HIGH] 默认不对公网暴露 | [FRAME, HIGH] 强认证、最小权限、审计、来源约束 |
| metrics/tracing | [FRAME, HIGH] 仅观测网络可达 | [FRAME, HIGH] 不允许匿名公网访问 |
| dependency console | [FRAME, HIGH] 不属于 `binance` 公共 API | [FRAME, HIGH] 禁止通过本模块的公共入口转发 |

## 2. 认证与秘密

[COMPUTED, HIGH] 旧版本文档包含凭据样式字面量和具体环境详情；本轮已删除。

[INFERRED, HIGH] 若旧值曾实际使用，必须完成轮换、会话失效、访问日志审计和异常访问复核；在这些回执归档前，安全门禁保持 BLOCKED。

[FRAME, HIGH] 认证材料只能由获授权的秘密管理平面注入；文档、日志、URL、示例和 release evidence 均不得包含可复用秘密。

## 3. SRE 验收回执

- [FRAME, HIGH] 公开路径 allowlist 与管理面 deny-by-default 的配置 hash。
- [FRAME, HIGH] TLS 证书身份、有效期与自动轮换测试结果，不保存私钥。
- [FRAME, HIGH] 未认证、低权限、越权、路径穿越、速率超限和大请求的负向测试。
- [FRAME, HIGH] 访问日志确认秘密值、token、查询正文和内部地址已脱敏。
- [FRAME, HIGH] 变更与回滚均关联 canonical deploy contract、RC SHA 与审批回执。

## 4. 发布判定

[COMPUTED, HIGH] 当前无绑定同一 RC 的外部 API、认证、负向测试与回滚回执，因此该 surface 不能提升 runtime release verdict。

[RULES I BROKE]：无
