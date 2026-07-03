# yahoo ACCEPTANCE

| AC | 验收项 | 目标 |
| -- | ------ | ---- |
| AC-001 | 双服务独立运行与边界合规 | `yahoo-client`/`yahoo-server` 可独立部署 |
| AC-002 | 配置与 secret 合规 | 无 secret 原值，配置来自 `sre/secrets/env/dev.md` |
| AC-003 | 领域语义与 no-lookahead | `domain_macro` 字段完整，as-of 查询正确 |
| AC-004 | 多存储与事件链路闭合 | 七介质职责落实，重放可重建 |
| AC-005 | 查询契约稳定 | API、事件、schema 一致 |
| AC-006 | 采集策略达标 | 清单、频率、同步周期、回补窗口按规格执行 |

