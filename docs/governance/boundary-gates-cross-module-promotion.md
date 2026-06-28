# 跨模块 boundary-gates 推广指南

- Date: 2026-06-25
- Scope: binance boundary-gates 实践 → natsx/contracts/domain_*/transportx 推广
- Priority: P3
- Source: binance `scripts/boundary-gates.sh`（13 gates）+ [`boundary-gates-template.md`](boundary-gates-template.md)
- Related: ZoneCNH/ZoneCNH#1073

---

## 1. 背景与目标

`[FRAME, HIGH]` binance 模块的 `boundary-gates.sh`（13 道 CI 边界门禁）已验证有效（v0.2.0 CI 全绿）。本指南把该实践推广到其他 infra 模块仓，确保每个 ZoneCNH 模块都有可执行的边界门禁。

### 推广矩阵（[`boundary-gates-template.md`](boundary-gates-template.md)）

| 模块 | gate 状态 | 推广优先级 |
| --- | --- | --- |
| binance | ✅ 13 gates（已落地） | —（模板源） |
| bootstrap | ✅ 6 gates（已落地） | — |
| natsx | 待创建 | P3 |
| contracts | 待创建 | P3 |
| domain_market | 待创建 | P3 |
| domain_exchange | 待创建 | P3 |
| transportx | 待创建 | P3 |

---

## 2. binance 模板结构（参照基准）

`[COMPUTED, HIGH]` binance 的 `scripts/boundary-gates.sh` 结构：

```bash
#!/usr/bin/env bash
set -euo pipefail
MODULE="<module>"           # 模块名
LEGACY_NAME="<legacy>"      # 旧名（如有，用于 §2 no-legacy 检查）
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

run_gate() { ... }          # 通用 gate 执行器（PASS/FAIL 计数）
# §2~§N 各 gate 定义
gate_<id>() { ... }         # 每个 gate 一个函数
# 主流程：逐 gate 执行 + 汇总
```

### binance 13 gates（各模块按需裁剪）

| Gate | 检查内容 | 适用性 |
| --- | --- | --- |
| §2 | no legacy 包名残留 | 所有模块（如有旧名迁移） |
| §3 | client 不 import server | C/S 模块（binance 专有） |
| §4 | server 不 import client | C/S 模块（binance 专有） |
| §5 | no cs 包作为 runtime 依赖 | 有 cs 子包的模块 |
| §6 | no 同进程 C/S 通信 | C/S 模块 |
| §7 | server 只持有模块专属存储 | 有存储的模块 |
| §8 | wire 契约外部化 | 有 wire 层的模块 |
| §9 | domain 仓是语义源 | 所有模块（统一） |
| §10 | admin 边界 | 有 admin API 的模块 |
| §11 | go.mod 依赖合规 | 所有模块（统一） |
| §12 | natsx runtime adapter 存在 | 用 natsx 的模块 |
| §13 | runtime 存储集成存在 | 有存储装配的模块 |
| §14 | gin REST 存在 | 有 REST API 的模块 |

---

## 3. 推广步骤（各目标仓执行）

`[FRAME, HIGH]` 各目标仓（natsx/contracts/domain_*/transportx）按以下步骤落地：

### 步骤 1：创建 `scripts/boundary-gates.sh`

从 binance 复制骨架，调整：
- `MODULE` 改为本模块名
- `LEGACY_NAME` 改为本模块旧名（如无则删 §2）
- 保留通用 gates（§9 domain 源、§11 go.mod 合规）
- 按模块特性选配 gates（如 transportx 不需 §3/§4 C/S 检查，但需 transport 边界 gate）

### 步骤 2：创建 `.github/workflows/boundary-gates.yml`

```yaml
name: Boundary Gates
on: [push, pull_request]
jobs:
  gates:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run boundary gates
        run: bash scripts/boundary-gates.sh
```

### 步骤 3：在 `module/<module>/BOUNDARY-GATES.md` 记录

各模块的规格仓（ZoneCNH/ZoneCNH `module/<module>/`）新增 `BOUNDARY-GATES.md`，登记 gate 清单 + 推广矩阵回填至 [`boundary-gates-template.md`](boundary-gates-template.md)。

---

## 4. 各模块建议 gate 子集

`[INFERRED, MED]` 基于模块定位的 gate 建议：

| 模块 | 建议 gates | 理由 |
| --- | --- | --- |
| natsx | §9(domain源) + §11(go.mod) + §adapter(natsx 自身契约) | 纯 infra adapter，无 C/S |
| contracts | §9 + §11 + §contract(契约完整性) | 纯契约定义 |
| domain_market | §9 + §11 + §domain(语义字段完整性) | 纯 domain 模型 |
| domain_exchange | §9 + §11 + §domain | 纯 domain 模型 |
| transportx | §9 + §11 + §transport(传输层边界) | 纯传输 infra |

---

## 5. 验收标准

`[FRAME, HIGH]` 推广完成的标志：
1. 各目标仓有 `scripts/boundary-gates.sh`（CI 可执行）
2. 各目标仓有 `.github/workflows/boundary-gates.yml`（CI 集成）
3. ZoneCNH `module/<module>/BOUNDARY-GATES.md` 登记 + 推广矩阵回填至 [`boundary-gates-template.md`](boundary-gates-template.md)
4. 各仓 CI boundary-gates PASS

---

> 本指南基于 binance v0.2.0 的 boundary-gates 实践。各仓落地时按模块特性裁剪 gate 子集。
