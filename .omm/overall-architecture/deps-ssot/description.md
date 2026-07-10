module/FOUNDATION-DEPS.yaml — 依赖矩阵 SSOT（30k）。管辖字段：modules.path/layer/stdlib_only、allowed_deps、forbidden_deps、constraints、forbidden_foundation_edges。人工维护治理规则，当前仅覆盖 20 基座 + domainx（业务域扩展是后续工作）。

与 registry.yaml 通过 deps_ref 单向引用（registry 指向 DEPS，DEPS 不反向引用 registry）。
