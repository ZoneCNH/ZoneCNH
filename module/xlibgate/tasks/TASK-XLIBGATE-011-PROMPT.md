# Context Packet — TASK-XLIBGATE-011

> trust identity：五源身份比对
> 来源：SPEC.md v1.1.1 FR-012, TC-014, TC-015

## Current Task

TASK-XLIBGATE-011: 实现 trust identity 命令，完成五源身份比对

## Related Spec

- module/xlibgate/SPEC.md FR-012 (trust identity)
- module/xlibgate/SPEC.md TC-014 (identity pass), TC-015 (identity mismatch)

## Scope

| Deliverable | Description |
|-------------|-------------|
| cmd/trust_identity.go | CLI 命令入口，--repo 参数 |
| scanner/trust/identity.go | 五源比对逻辑 |

### 五源比对

1. README.md H1 == repo name
2. go.mod module == `github.com/ZoneCNH/<repo>`
3. .repo-contract.yaml 存在且 identity 字段正确
4. public_package 入口存在
5. 下游仓库未声称 "Standard Source" / "Generator" / "Go Reference Template"

### Exit Code 映射

| 场景 | Exit | reason_code |
|------|------|-------------|
| 五源一致 | 0 | "" |
| 任一不匹配 | 1 | IDENTITY_MISMATCH |
| .repo-contract.yaml 缺失 | 2 | CONTRACT_PARSE_ERROR |

## Non-Scope

- 不检查 SPEC.md 内容格式（仅标题比对）
- 不验证 go.mod 依赖版本

## Acceptance Criteria

- TC-014: 五源一致 → exit 0
- TC-015: README H1 不匹配 → exit 1, IDENTITY_MISMATCH
- go.mod module 不匹配 → exit 1, IDENTITY_MISMATCH
- 下游声称 Standard Source → exit 1, IDENTITY_MISMATCH
- 缺少 public_package → exit 1, IDENTITY_MISMATCH
- .repo-contract.yaml 缺失 → exit 2, CONTRACT_PARSE_ERROR

## Constraints

- 输出统一 JSON schema（scanner/trust/common.go）
- 不输出文件内容到错误消息（仅文件路径和行号）
- `go test -race -count=1 ./scanner/trust/...` 通过

## Validation

```bash
go build ./... && xlibgate trust identity --repo testdata/trust-pass 2>&1; [ $? -eq 0 ]
xlibgate trust identity --repo testdata/trust-bad-h1 2>&1; [ $? -eq 1 ]
```
