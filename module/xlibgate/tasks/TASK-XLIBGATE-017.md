# TASK-XLIBGATE-017

> trust secret-redaction 实现

---

```yaml
task_id: TASK-XLIBGATE-017
module: xlibgate
scope: "实现 trust secret-redaction 命令：扫描 release/evidence 文档中的密钥和私有端点"
spec_ref:
  - "module/xlibgate/SPEC.md#FR-018"
  - "module/xlibgate/SPEC.md#TC-026"
  - "module/xlibgate/SPEC.md#TC-027"
files:
  - "cmd/trust_secret.go"
  - "scanner/trust/secret.go"
acceptance_criteria:
  - "AC-017: release/evidence 无敏感信息 → exit 0"
  - "AC-017: 检测到 API key/password/token/DSN → exit 1, reason_code=SECRET_LEAK, 输出脱敏"
  - "AC-017: 检测到私有端点 → exit 1, reason_code=PRIVATE_ENDPOINT_LEAK"
  - "AC-017: 开发上下文豁免（test/, testdata/, *_test.go, dev-only, README 本地开发章节）"
  - "AC-017: 扫描路径下无 release/evidence → exit 2, reason_code=CONTRACT_PARSE_ERROR"
depends_on:
  - "TASK-XLIBGATE-010"
estimated_effort: "2h"
priority: P0
status: pending
```

---

## Requirements Covered

| Requirement | Description                                        |
| ----------- | -------------------------------------------------- |
| FR-018      | trust secret-redaction：文档密钥/端点扫描          |
| TC-026      | 无泄露 → pass                                      |
| TC-027      | 检测到 AWS key → SECRET_LEAK（脱敏输出）           |

## 检测模式

| 类型         | 检测内容                                           |
| ------------ | -------------------------------------------------- |
| Secrets      | API keys, passwords, tokens, DSN with credentials  |
| 私有端点     | IPv4 loopback, loopback hostname, 10.x.x.x, 172.16-31.x.x, 192.168.x.x |

## 开发上下文豁免

`test/`, `testdata/`, `*_test.go`, `.md` 中的 `dev-only` 代码块, `README.md` 本地开发章节

## Non-scope

- 不使用 gitleaks（gitleaks 用于 check all 的源码扫描，FR-005）
- 不输出密钥原文（必须脱敏）

## Test Plan

| Test Case | Type | Description                              |
| --------- | ---- | ---------------------------------------- |
| TC-026    | Unit | 无泄露 → pass                            |
| TC-027    | Unit | AWS key 检测 → SECRET_LEAK，输出脱敏     |
| —         | Unit | 私有端点 → PRIVATE_ENDPOINT_LEAK         |
| —         | Unit | 开发上下文豁免不触发                     |
