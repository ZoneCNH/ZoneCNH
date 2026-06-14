# Context Packet — TASK-XLIBGATE-017

> trust secret-redaction：扫描 release/evidence 文档中的密钥和私有端点
> 来源：SPEC.md v1.1.1 FR-018, TC-026, TC-027

## Current Task

TASK-XLIBGATE-017: 实现 trust secret-redaction 命令，扫描文档中的敏感信息

## Related Spec

- module/xlibgate/SPEC.md FR-018 (trust secret-redaction)
- module/xlibgate/SPEC.md TC-026 (clean), TC-027 (leak)

## Scope

| Deliverable | Description |
|-------------|-------------|
| cmd/trust_secret.go | CLI 命令入口，--repo, --path 参数 |
| scanner/trust/secret.go | 正则匹配 + 脱敏输出 |

### 检测模式

| 类型 | 匹配目标 |
|------|----------|
| Secrets | API keys, passwords, tokens, DSN with credentials（正则：`[A-Z0-9_]+(_KEY|_SECRET|_TOKEN|_PASSWORD|_DSN)=`） |
| 私有端点 | 127.0.0.1, localhost, 10.x.x.x, 172.16-31.x.x, 192.168.x.x |

### 开发上下文豁免

- 文件路径含 `test/`, `testdata/`
- 文件名含 `_test.go`
- .md 文件中标记为 `dev-only` 的代码块
- README.md 的本地开发章节

### 脱敏输出

- 不输出密钥原文 → 仅输出匹配类型（如 "AWS_SECRET_ACCESS_KEY"）
- 输出文件路径和行号

## Non-Scope

- 不使用 gitleaks（gitleaks 用于 check all 源码扫描）

## Acceptance Criteria

- TC-026: release/evidence 无泄露 → exit 0
- TC-027: AWS_SECRET_ACCESS_KEY 检测 → exit 1, SECRET_LEAK（脱敏输出）
- 私有端点检测 → exit 1, PRIVATE_ENDPOINT_LEAK
- 开发上下文豁免 → 不触发
- release/evidence 目录缺失 → exit 2, CONTRACT_PARSE_ERROR

## Constraints

- 脱敏输出：绝不输出密钥原文
- 符号链接深度限制 max 3 层（Edge Case）
- 统一 JSON 输出

## Validation

```bash
xlibgate trust secret-redaction --repo testdata/trust-pass --path release/evidence 2>&1; [ $? -eq 0 ]
xlibgate trust secret-redaction --repo testdata/trust-bad-secret --path release/evidence 2>&1; [ $? -eq 1 ]
```
