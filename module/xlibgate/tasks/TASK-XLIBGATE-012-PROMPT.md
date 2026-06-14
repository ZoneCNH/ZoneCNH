# Context Packet — TASK-XLIBGATE-012

> trust template-residue：扫描 BR-010 禁止模板身份短语
> 来源：SPEC.md v1.1.1 FR-013, BR-010, TC-016, TC-017

## Current Task

TASK-XLIBGATE-012: 实现 trust template-residue 命令，扫描下游仓库中的禁止模板身份短语

## Related Spec

- module/xlibgate/SPEC.md FR-013 (trust template-residue)
- module/xlibgate/SPEC.md BR-010 (5 条禁止模板身份短语)
- module/xlibgate/SPEC.md TC-016, TC-017

## Current Scope

| Deliverable | Description |
|-------------|-------------|
| cmd/trust_template.go | CLI 命令入口，--repo, --summary 参数 |
| scanner/trust/template.go | 短语扫描逻辑 |

### BR-010 五条禁止短语（精确字符串匹配）

1. "承担五类职责：Standard Source、Go Reference Template、Generator、Harness 和 Evidence Runtime"
2. "本仓库不再把标准源与模板实现拆成两个角色"
3. "提供可编译参考包 pkg/templatex"
4. "渲染后会移动到 pkg/<package-name>"
5. "生成库包括 configx、observex、testkitx"

### 规则

- 仅 `github.com/ZoneCNH/xlib-standard` 可含以上短语
- 非文本文件（.png, .so）跳过
- 扫描范围：.md, .yaml, .go, .txt, .json

## Non-Scope

- 不做模糊匹配或正则匹配
- 不扫描二进制文件

## Acceptance Criteria

- TC-016: 下游仓库无禁止短语 → exit 0
- TC-017: 含 "承担五类职责..." → exit 1, TEMPLATE_RESIDUE
- xlib-standard 目标 → exit 0, TEMPLATE_RESIDUE_SELF_SKIP
- --summary 输出命中统计

## Constraints

- 精确字符串匹配（含标点和空格）
- 不区分注释或代码上下文
- 统一 JSON 输出

## Verification

```bash
xlibgate trust template-residue --repo testdata/trust-pass 2>&1; [ $? -eq 0 ]
xlibgate trust template-residue --repo testdata/trust-bad-template 2>&1; [ $? -eq 1 ]
```
