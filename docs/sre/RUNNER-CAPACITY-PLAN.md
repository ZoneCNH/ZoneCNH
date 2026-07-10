# ZoneCNH Self-hosted Runner 容量规划

> 日期：2026-07-10
> 状态：执行中
> 来源：`docs/sre/RUNNER-POOLS.yaml`、`docs/sre/module-runner-registry.yaml`、`sre/bootstrap/hosts.env`、`sre/AGENTS.md`
> 约束：ZoneCNH 是 GitHub user account，runner 为 repo-level，不可 org 共享。

---

## 1. 执行摘要

- **当前物理 runner 进程**：79 个（4 台主机：68 个模块 repo-level runner + 11 个 profile-based runner）
- **模块/仓库数**：68 个
- **按 repo-level runner 最低需求**：68 个 runner 注册
- **容量缺口**：**0**
- **关键发现**：
  - `xhypers`（`10.2.2.10`）已承载 57 个 repo-level runner，内存余量 75 Gi，磁盘余量 1.5 TB，是资源最充裕的主机。
  - `10.2.2.9` 从 12 个 runner 降至 7 个 contracts + 1 security，负载与内存压力显著缓解。
  - `84.247.154.45` 模块 runner 已清空，仅保留 `sre/deploy` 与 profile runner。
- **关键约束**：GitHub user account 无法共享 runner；每个模块仓库必须独立注册至少一个 runner。
- **结论**：以 `10.2.2.10` 为主力、`10.2.2.9` 为辅助，收缩 `84.247.154.45` 至 deploy-only，可最大化资源利用并降低生产主机负载。

---

## 2. 主机清单与资源基线

| 主机地址 | 角色 | CPU | 内存 | 磁盘 | 系统 | SSH 用户 | 当前模块 runner | 目标模块 runner |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `94.72.124.39` | CICD 控制面 + 轻量 runner | 4 vCPU | 7.8 Gi | 148 GB / 50% | Debian 13 / 6.12.74 | claude | 4 | 4 |
| `84.247.154.45` | 生产机 / WireGuard hub / deploy 隔离 | 16 vCPU | 62 Gi | 591 GB / 71% | Debian 13 / 6.12.88+ | claude | 0 | 0 |
| `10.2.2.9` | WireGuard 内网 CI runner | 12 vCPU | 16 Gi | 233 GB / 31% | Debian 12 | root | 7 | 7 |
| `10.2.2.10` | **xhypers / 主力 runner 主机** | **16 vCPU** | **126 Gi** | **1.9 TB / 15%** | **Ubuntu 26.04** | **zone** | **57** | **57** |
| **合计** | | **48 vCPU** | **211.8 Gi** | | | | **68** | **68** |

> 来源：`sre/AGENTS.md` §基础设施主机清单；`sre/bootstrap/hosts.env`；xhypers 实测。

---

## 3. Runner 密度测算

### 3.1 假设

- 轻量 runner（governance / foundation / contracts）：待机 150 MB，峰值 1 vCPU / 2 GB。
- 中载 runner（market / macro / storage-light）：待机 200 MB，峰值 2 vCPU / 4 GB。
- 重载 runner（storage-heavy / engine / deploy）：待机 300 MB，峰值 4 vCPU / 8 GB。
- 同一主机上 runner 进程**并发执行时**才消耗峰值资源；待机时资源可忽略。
- 预留 20% 系统开销与突发缓冲。

### 3.2 单主机理论密度

| 主机 | 可用资源（扣 20%） | 建议承载 runner 数 | 备注 |
| --- | --- | --- | --- |
| `94.72.124.39` | 3 vCPU / 6.2 Gi | 4 - 6 | 仅轻量任务，禁止重载/存储池 |
| `84.247.154.45` | 13 vCPU / 50 Gi | 0（模块 runner） | 仅保留 deploy/profile runner；模块 runner 全部迁出 |
| `10.2.2.9` | 10 vCPU / 13 Gi | 7 - 10 | 仅保留 contracts + security；foundation 全部迁出 |
| `10.2.2.10` | 13 vCPU / 101 Gi | **50 - 60** | 主力高密度主机；承载 57 个 module runner |
| **理论最大** | | **61 - 82** | 并发满载时上限；平均待机时可更高 |

### 3.3 目标密度（保守）

按 80% 并发率估算，consolidation 后 `10.2.2.10` 承载 57 个 module runner，`10.2.2.9` 承载 7 个 contracts runner + 1 个 security runner。`10.2.2.10` 内存充足（75 Gi 可用），主要瓶颈为 CPU 并发度；需持续监控 load avg。

---

## 4. Pool 级需求分布

| Pool | 当前 runner_count | 当前 host | 目标 host | 模块数 | 建议最低 runner 数 | 密度建议 |
| --- | ---: | --- | --- | ---: | ---: | --- |
<<<<<<< HEAD
| `sre/governance` | 4 | 94.72.124.39 | 94.72.124.39 | 4 | 4 | 每模块 1 runner，可共处 |
| `sre/foundation-l0` | 1 | 10.2.2.10 | 10.2.2.10 | 1 | 1 | kernel 在 xhypers |
| `sre/foundation-l1` | 10 | 10.2.2.10 | 10.2.2.10 | 10 | 10 | 全部在 xhypers |
| `sre/contracts` | 7 | 10.2.2.9 | 10.2.2.9 | 7 | 7 | 保留在 10.2.2.9 |
| `sre/security` | 1 | 10.2.2.9 | 10.2.2.9 | 0 | 1 | 服务 ZoneCNH 主仓安全扫描 |
| `sre/market` | 6 | 10.2.2.10 | **10.2.2.10** | 6 | 6 | 已迁 xhypers |
| `sre/macro` | 12 | 10.2.2.10 | **10.2.2.10** | 12 | 12 | 已在 xhypers |
| `sre/storage-light` | 3 | 10.2.2.10 | **10.2.2.10** | 3 | 3 | 已迁 xhypers |
| `sre/storage-heavy` | 4 | 10.2.2.10 | **10.2.2.10** | 4 | 4 | 已在 xhypers |
| `sre/engine` | 21 | 10.2.2.10 | **10.2.2.10** | 21 | 21 | 已在 xhypers |
| `sre/deploy` | 2 | 84.247.154.45 | 84.247.154.45 | 0 | 2 | 保留，独立隔离 |

> 注：建议最低 runner 数 = 模块数（每个模块仓库独立注册 1 个）。

---

## 5. 容量缺口详情

```text
总需求：    68  repo-level runner 注册
当前在线：  68  runner 进程
缺口：      0

按主机分布（consolidation 后）：
- 94.72.124.39:  当前 4  → 目标 4   → 0
- 84.247.154.45: 当前 0  → 目标 0   → 0
- 10.2.2.9:      当前 7  → 目标 7   → 0
- 10.2.2.10:     当前 57 → 目标 57  → 0
```

---

## 6. 分阶段 Consolidation 路线

### Phase 0：基线校准（已完成）

- 68 个模块 runner 全部在线，无缺口。
- `10.2.2.9` 已达 12 runner，swap 100%，不可再增。
- `84.247.154.45` 仍有 15 个模块 runner（6 旧 foundation、6 market、3 storage-light），需迁出。

### Phase 1：market + storage-light → xhypers（已完成）

把 `sre/market`（6）和 `sre/storage-light`（3）从 `84.247.154.45` 迁到 `10.2.2.10`。

### Phase 2：foundation → xhypers（已完成）

由于 `10.2.2.9` swap 已满，把 `sre/foundation-l0`（1）和 `sre/foundation-l1`（10）全部迁到 `10.2.2.10`。
其中 5 个 foundation-l1 runner 原本在 `10.2.2.9`，也迁到 `10.2.2.10` 以统一 foundation 池并缓解 10.2.2.9 内存压力。

### Phase 3：清理 84.247.154.45 与验证（已完成）

- 所有新 runner 已 online。
- 已删除 `84.247.154.45` 上已迁出的旧 runner 注册、systemd 服务与目录。
- 已运行 `cleanup-docker-host.sh` 释放磁盘。
- 仅保留 `sre/deploy` 与旧标签兼容 runner。

最终分布：

```text
94.72.124.39:    4  governance
10.2.2.9:        7  contracts (+ 1 security)
84.247.154.45:   0  module runner (仅 deploy/profile)
10.2.2.10:      57  engine, macro, storage-heavy, market, storage-light, foundation
-------------------------------------------
合计：           68  module runner 进程
```
---

## 7. 注册策略

由于 ZoneCNH 是 GitHub user account，runner 必须按 repo 注册。推荐策略：

1. **每模块仓库注册 1 个 runner**，使用 pool 标签 + `self-hosted, Linux, X64`。
2. **同一物理主机上运行多个 runner 进程**，每个进程对应不同 repo/token。
3. **不要跨 repo 共享 runner 进程**；GitHub Actions 不允许。
4. **在 xhypers 上使用 systemd 模板**管理多 runner 进程，按 `actions-runner-<repo>-<idx>` 命名。
5. **pool 标签**可以附加在多个 repo 的 runner 上，实现逻辑池效果。

示例注册命令（在 xhypers 上执行）：

```bash
REPO="ZoneCNH/<module>"
TOKEN=$(gh api -X POST "repos/${REPO}/actions/runners/registration-token" -q .token)
./config.sh --url "https://github.com/${REPO}" \
  --token "$TOKEN" \
  --name "xhypers-<module>-01" \
  --labels "self-hosted,Linux,X64,sre/<pool>" \
  --unattended
```

---

## 8. 标签桥接与兼容性

当前 `sre/bootstrap/hosts.env` 仍使用旧标签（`ci-go`, `ci-heavy`, `deploy`, `docker`）。workflow 已切换为 `sre/*` 标签。建议：

- 新注册 runner 时直接附加 `sre/*` 标签。
- 保留旧标签 30 天作为过渡，避免未迁移 workflow 失败。
- 过渡期后，runner 标签精简为：`self-hosted, Linux, X64, sre/<pool>`。

---

## 9. 风险与缓解

| 风险 | 影响 | 缓解 |
| --- | --- | --- |
| `10.2.2.10` runner 过多导致 CPU 过载 | 高 | 监控 load avg；若持续 >12 则暂缓 Phase 2 或回迁部分 runner |
| `10.2.2.9` swap 已满导致 OOM | 高 | 不再新增 runner；必要时增加 swap 或内存 |
| 迁移期间 workflow 无可用 runner | 高 | 采用先增后删：新 runner online 并验证 workflow 后再移除旧 runner |
| Docker 测试在 `10.2.2.10` 失败 | 中 | Phase 1 前先手动跑一个 storage-light workflow 验证 |
| 磁盘被 `_work` / Docker 占满 | 中 | 每日 `cleanup-docker-host.sh`；xhypers 1.6T 磁盘充裕 |
| 注册 PAT 权限不足 | 中 | 使用 `repo` + `workflow` scope 的 PAT |
| 网络抖动导致 runner offline | 中 | `health-check.sh` 每小时巡检；`--fix` 自动重启 |
| xhypers 作为工作站同时跑 CI | 中 | 监控交互体验；runner 密度不超过 56 个 |

---

## 10. Consolidation 行动清单

- [x] 0. 校准 runner 实际在线状态：68 个模块 runner，无缺口。
- [x] 1. 更新 `docs/sre/module-runner-registry.yaml` 实际与目标分布。
- [x] 2. 更新 `docs/sre/RUNNER-POOLS.yaml` pool host 与 runner_count。
- [x] 3. 更新 `docs/sre/RUNNER-CAPACITY-PLAN.md` 为 consolidation 完成状态。
- [x] 4. 更新 `sre/bootstrap/hosts.env` 反映 consolidation 目标。
- [x] 5. 创建 `sre/bootstrap/audit-runner-state.py` 与 `migrate-runner.py`。
- [x] 6. 迁移 `sre/market` 6 个 runner → `10.2.2.10`。
- [x] 7. 迁移 `sre/storage-light` 3 个 runner → `10.2.2.10`。
- [x] 8. 迁移 `sre/foundation-l0/l1` 11 个 runner → `10.2.2.10`。
- [x] 9. 清理 `84.247.154.45` 已迁出 runner，仅保留 deploy。
- [x] 10. 运行 `audit-runner-state.py` 验证最终状态。

---

## 11. 参考文档

- `docs/sre/RUNNER-POOLS.yaml` — pool 定义与模块分配
- `docs/sre/module-runner-registry.yaml` — 模块到 runner 的注册映射
- `knowledge/ci.md` — CICD-001 与 runner 基线
- `sre/bootstrap/hosts.env` — 主机注册目标
- `sre/bootstrap/health-check.sh` — 健康检查
- `sre/bootstrap/remote-diag.sh` — 远端诊断
