模块计数以 module/registry.yaml 为权威源。当前 yaml 解析实测 68 模块（基座 20 / 数据 18 / 分析 8 / 执行 7 / 决策 6 / L2.5 5 / 入口 2 / 横切 2）。STATUS.md / README.md / ARCHITECTURE.md 中任何模块数量引用必须与此一致（数量验证门禁 + CountGuard hook BLOCK 级）。

成熟度评级 L0-L5（module-governance 05-health + goal 18-maturity）：L0 裸用、L1 规则层、L2 反馈回路、L3 自动修正、L4 自治系统、L5 自治执行。当前主仓成熟度 L4（GC Agent 连续 3 次 0 critical），L5 自治执行是路线图目标。
