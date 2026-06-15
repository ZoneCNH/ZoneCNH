# domain-exchange v1.0.0 Implementation Plan

| 字段 | 值 |
| --- | --- |
| 模块 | `domain-exchange` |
| 当前版本 | v1.0.0 |
| 目标版本 | v1.0.0 |
| 依赖顺序 | `decimalx`、`domain-market`、`domainx` 之后 |
| 最后更新 | 2026-06-15 |

## 里程碑

| 里程碑 | 内容 | 退出条件 |
| --- | --- | --- |
| M0 ADR / Interfaces | 冻结 exchange vs domainx/domain-market 边界，拆分 SPI | ADR/SPEC 完成 |
| M1 Requests / Idempotency | Place/Cancel/Query request 与 client id/idempotency 语义 | request validation 测试通过 |
| M2 Errors / Retry | ExchangeError、retry safety、rate limit policy | error table tests 完成 |
| M3 Capability / Registry | VenueProfile、capability、fake exchange、线程安全 registry | race/concurrency 测试通过 |
| M4 Stream semantics | streaming contract 与 reconnect/backpressure 语义 | fake stream 测试通过 |
| M5 Release | docs、CI、migration、release manifest | GitHub Release v1.0.0 已发布，公开依赖图验证通过 |

## PR 类别

| 类别 | 目的 |
| --- | --- |
| docs-v1-contract | 明确 SPI、边界、能力、错误和迁移路线 |
| api-v1-freeze | 拆分 Exchange interface，冻结 request/error/capability |
| invariant-tests | 覆盖 idempotency、retry、rate limit、registry 并发 |
| ci-release-gates | 加入 boundary scan、race、staticcheck、govulncheck |
| release-v1.0.0 | 发布 tag、release notes 与 manifest |

## 发布证据

| 证据 | 值 |
| --- | --- |
| GitHub Release | <https://github.com/ZoneCNH/domain-exchange/releases/tag/v1.0.0> |
| Tag target | `9c11c421ef643768690eb45c88f7b89dbda3afc8` |
| 本地验证 | `go test -count=1 ./...` |
| 公开依赖 | `decimalx v1.0.0` / `domain-market v1.0.1` / `domainx v1.0.1` |
| 结果 | 通过 |
