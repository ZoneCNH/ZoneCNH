module/registry.yaml — 模块身份与治理状态的单一权威源（SSOT）。管辖字段：repo、local_path、domain、layer、arch_type、lifecycle、owner、spec_ref、registered。不重复登记依赖（→deps_ref 指向 FOUNDATION-DEPS.yaml）和成熟度（→maturity_ref 指向 .foundationx/status/index.json）。

schema_version: module-registry/v1，覆盖全域模块（基座+L2.5+业务域+入口+横切）。字段变更须遵循 01-module-registry.md §4 登记变更规则。
