模块计数以 module/registry.yaml 为权威来源（当前 69 模块，grep -cE '^[a-z_]+:' 实测），不要硬编码到文档。STATUS.md / README.md / ARCHITECTURE.md 中任何模块数量引用必须与 registry.yaml 实际数一致（数量验证门禁）。

本仓库与各模块仓库是分离的：module/<module>/ 下是规格制品，真正的 Go/Rust 代码在 registry.yaml local_path 字段指向的独立 git 仓库。两套目录通过 registry.yaml 的 repo 和 local_path 字段桥接。
