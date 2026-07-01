# TASK-ALERTX-008 开发 Prompt

> email/pagerduty 渠道 + Soak harness + AT-007 集成测试 + CI/Makefile

- 上游 Task：[TASK-ALERTX-008.md](../tasks/TASK-ALERTX-008.md) | Spec：[SPEC.md#FR-004](../SPEC.md) [#15](../SPEC.md) [#19](../SPEC.md)

## 任务

实现 email/pagerduty 渠道、Soak harness（≥10min）、AT-007 横切贯穿集成测试、CI 工作流、Makefile、release manifest 工具。

## 关联需求

| 类型 | 编号 | AC | TC |
| --- | --- | --- | --- |
| FR | FR-004 | AC-004 | — |
| BR | BR-001 | AC-008 | TC-020 |
| BR | BR-002 | AC-009 | TC-020 |
| NFR | NFR-004 | — | Soak |

## 依赖

- 上游：TASK-007（完整引擎可运行）
- AT-007 规范：docs/testing/acceptance-tests.md（alertx 收事件+通知+trace ID+多模块并发不丢）

## 实现要点

1. `internal/channel/email.go`：SMTP email 渠道（标题不含敏感数据）
2. `internal/channel/pagerduty.go`：PagerDuty Events API v2 渠道
3. `testkit/soak_harness.go`：Soak harness
   - 运行 ≥10min，注入持续告警流
   - 监控内存（< 100MB / 10k 告警）+ goroutine 数（无泄漏，NFR-004）
4. `test/at007_integration_test.go`（`//go:build integration`）：
   - AT-007 横切贯穿：注入告警触发条件 → alertx 收事件+通知+trace ID
   - 多模块并发触发不丢失事件（BR-001/002）
5. `.github/workflows/{ci,release,security,integration}.yml`：照搬 observex 4 件套
   - ci.yml：PR/push → make release-check → 上传 manifest
   - release.yml：tag v* → make release-final-check
6. `Makefile`：照搬 observex 链（fmt/vet/test/race/lint/examples/boundary/security/contracts + release-version/release-check/release-final-check/release-preflight）

## 验证

```bash
cd /home/workspace/alertx && GOWORK=off go test -tags integration ./... -run TestAT007 -v -race
GOWORK=off go test -tags soak ./testkit/... -run TestSoak -v  # ≥10min
make ci  # 完整 CI 链
make release-final-check VERSION=v1.0.0
```

## 关键测试

- `TestAT007_CrossCutting`：AT-007 集成，告警不丢失+幂等+trace ID
- `TestSoak_NoLeak`：Soak ≥10min，内存/goroutine 稳定
- CI 全绿：make ci（fmt/vet/lint/test/race/boundary/security/contracts）
- release manifest 生成：make evidence → release/manifest/v1.0.0.json
