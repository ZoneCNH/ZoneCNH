入口 entry，2 模块。composer（Composition Root，组合根，组装 bootstrap.Build(ctx, Spec)）和 frontend（前端 UI）。注意：x.go 是治理/工具 CLI，归 crosscut 而非 entry。composer 聚合进程使用 Stores=All，adapter 进程使用 Stores=None。
