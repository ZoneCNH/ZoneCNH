# ZoneCNH Self-hosted Runner 容量规划

> 日期：2026-07-10
> 状态：执行中
> 来源：`docs/sre/RUNNER-POOLS.yaml`、`docs/sre/module-runner-registry.yaml`、`sre/bootstrap/hosts.env`、`sre/AGENTS.md`
> 约束：ZoneCNH 是 GitHub user account，runner 为 repo-level，不可 org 共享。

---

## 1. 执行摘要

- **当前物理 runner 进程**：79 个（4 台主机，含 68 个模块 repo-level runner 与 11 个 profile-based runner）
- **模块/仓库数**：68 个
- **按 repo-level runner 最低需求**：68 个 runner 注册
- **容量缺口**：**0**
- **关键发现**：`xhypers`（`10.2.2.10`）规格为 16c / 126g / 1.9T，已成功注册并上线 37 个 repo-level runner；其余 31 个模块 repo-level runner 已分布在 94.72.124.39 / 10.2.2.9 / 84.247.154.45。
- **关键约束**：GitHub user account 无法共享 runner；每个模块仓库必须独立注册至少一个 runner。
- **结论**：现有 3 台主机 + 新纳入的 `10.2.2.10` 可显著缓解缺口；优先把高密度池（`sre/engine`、`sre/macro`）迁移到 `10.2.2.10`。

---

## 2. 主机清单与资源基线

| 主机地址 | 角色 | CPU | 内存 | 磁盘 | 系统 | SSH 用户 | 当前承载 runner 数 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `94.72.124.39` | CICD 控制面 + 轻量 runner | 4 vCPU | 7.8 Gi | 148 GB / 50% | Debian 13 / 6.12.74 | claude | 6 |
| `84.247.154.45` | 生产机 / WireGuard hub / 重载 runner | 16 vCPU | 62 Gi | 591 GB / 69% | Debian 13 / 6.12.88+ | claude | 23 |
| `10.2.2.9` | WireGuard 内网 CI runner | 12 vCPU | 16 Gi | 233 GB | Debian 12 | root | 13 |
| `10.2.2.10` | **xhypers / 主力 runner 主机** | **16 vCPU** | **126 Gi** | **1.9 TB / 12%** | **Ubuntu 26.04** | **zone** | **37** |
| **合计** | | **48 vCPU** | **211.8 Gi** | | | | **79** |

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
| `84.247.154.45` | 13 vCPU / 50 Gi | 18 - 24 | 可混合中载/重载；Docker、deploy 隔离 |
| `10.2.2.9` | 10 vCPU / 13 Gi | 10 - 12 | 轻量/中载为主，内存是瓶颈 |
| `10.2.2.10` | 13 vCPU / 101 Gi | **30 - 40** | 主力高密度主机；可容纳 engine/macro 等大数据池 |
| **理论最大** | | **62 - 82** | 并发满载时上限；平均待机时可更高 |

### 3.3 目标密度（保守）

按 80% 并发率估算，4 台主机可稳定承载 **约 65 个 runner 进程**，基本覆盖 68 个模块需求。

---

## 4. Pool 级需求分布

| Pool | 当前 runner_count | 当前 host | 目标 host | 模块数 | 建议最低 runner 数 | 密度建议 |
| --- | ---: | --- | --- | ---: | ---: | --- |
| `sre/governance` | 4 | 94.72.124.39 | 94.72.124.39 | 4 | 4 | 每模块 1 runner，已满足 |
| `sre/foundation-l0` | 1 | 84.247.154.45 | 10.2.2.9 | 1 | 1 | kernel 因 10.2.2.9 容量不足临时在 84.247.154.45 |
| `sre/foundation-l1` | 10 | 10.2.2.9 / 84.247.154.45 | 10.2.2.9 | 10 | 10 | 5 个在 10.2.2.9，5 个在 84.247.154.45 |
| `sre/contracts` | 7 | 10.2.2.9 | 10.2.2.9 | 7 | 7 | 已满足；10.2.2.9 当前 13 runner 超载 1 个 |
| `sre/security` | 1 | 10.2.2.9 | 10.2.2.9 | 0 | 1 | 服务 ZoneCNH 主仓安全扫描 |
| `sre/market` | 6 | 84.247.154.45 | 84.247.154.45 | 6 | 6 | 已满足 |
| `sre/macro` | 12 | 10.2.2.10 | 10.2.2.10 | 12 | 12 | 已迁移至 xhypers |
| `sre/storage-light` | 3 | 84.247.154.45 | 84.247.154.45 | 3 | 3 | 已满足 |
| `sre/storage-heavy` | 4 | 10.2.2.10 | 10.2.2.10 | 4 | 4 | 已迁移至 xhypers |
| `sre/engine` | 21 | 10.2.2.10 | 10.2.2.10 | 21 | 21 | 已满足 |
| `sre/deploy` | 2 | 84.247.154.45 | 84.247.154.45 | 0 | 2 | 已满足，独立隔离 |

> 注：建议最低 runner 数 = 模块数（每个模块仓库独立注册 1 个）。

---

## 5. 容量缺口详情

```text
总需求：    68  repo-level runner 注册
当前在线：  68  repo-level runner 进程
缺口：      0

按主机分布（仅 repo-level runner）：
- 94.72.124.39:  当前 4  → 目标 4   → 缺口 0
- 84.247.154.45: 当前 15 → 目标 15  → 缺口 0
- 10.2.2.9:      当前 12 → 目标 12  → 缺口 0（含 1 个 security，实际超载 1 个）
- 10.2.2.10:     当前 37 → 目标 37  → 缺口 0（已满足）
```

---

## 6. 分阶段扩容路线

### Phase A：当前主机密度优化（已完成）

目标：在 3 台现有主机上从 17 个模块 repo-level runner 提升到 31 个。

| 主机 | 动作 | 新增 runner 数 | 说明 |
| --- | --- | --- | --- |
| `94.72.124.39` | 为 4 个 governance 模块各注册 1 个 runner | +2 | 当前 4，扩展完成 |
| `10.2.2.9` | 清理 5 个 legacy profile-based runner，为 6 个 foundation-l1 / contracts 模块注册 runner | +6 net | 当前 12 repo-level + 1 security |
| `84.247.154.45` | 为 4 个 market / storage-light 模块注册 runner | +4 | 当前 15 module repo-level（含 kernel 溢出） |

风险：
- `10.2.2.9` 当前 13 个 runner（含 security），超出原建议 12，需监控内存。
- `84.247.154.45` 磁盘使用率 69%，需监控 Docker 镜像与 `_work` 目录增长。

### Phase B：xhypers 上线（已完成）

`10.2.2.10`（xhypers）已成功作为主力 runner 主机上线，注册 37 个 repo-level runner：

```yaml
xhypers:
  address: 10.2.2.10
  hostname: xhypers
  cpu: 16 vCPU
  memory: 126 Gi
  disk: 1.9 TB SSD
  network: WireGuard 全隧道（端点 84.247.154.45:55195）
  docker: true
  role: engine + macro + storage-heavy 主力池
  registered_runners: 37
  pools:
    - sre/engine
    - sre/macro
    - sre/storage-heavy
```

注册结果：
- 37 个 systemd 服务全部 active
- GitHub API 验证全部 `online`
- xhypers 内存使用约 47 GB / 126 GB，负载正常

当前分布（repo-level runner）：

```text
94.72.124.39:    4  governance
10.2.2.9:       12  foundation-l1, contracts (+ 1 security)
84.247.154.45:  15  market, storage-light, foundation-l0/l1 溢出
10.2.2.10:      37  engine, macro, storage-heavy
-------------------------------------------
合计：           68  repo-level runner
```

### Phase C：最终调优（已完成）

所有 68 个模块 repo-level runner 已在线。剩余运维重点：

1. 监控 `10.2.2.9` 13 个 runner 的内存与并发情况；如 OOM，将 1 个 contracts 或 foundation-l1 runner 迁移到 `84.247.154.45`。
2. 清理 84.247.154.45 上旧的 `ci-*` 标签 runner（已完成 xlib 4 个）。
3. 待 `10.2.2.9` 扩容至 32 Gi 内存后，将 kernel 与剩余 foundation-l1 模块回迁到 10.2.2.9。

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
| 单主机 runner 过多导致 OOM | 高 | 按内存密度上限控制；xhypers 大内存优先承载重载池 |
| 磁盘被 `_work` / Docker 占满 | 高 | 每日 `disk-cleanup.sh`；限制 Docker 日志大小；xhypers 1.9T 磁盘充裕 |
| 并发 job 排队 | 中 | 优先为活跃模块注册 runner；不活跃模块可延后 |
| 注册 PAT 权限不足 | 中 | 使用 `repo` + `workflow` scope 的 PAT |
| 用户账号无法 org 共享 runner | 中 | 按 repo 注册；用 pool 标签做逻辑分组 |
| 网络抖动导致 runner offline | 中 | `health-check.sh` 每小时巡检；`--fix` 自动重启 |
| xhypers 作为工作站同时跑 CI | 中 | 预留 50% 资源给工作站；runner 密度不超过 40 个 |

---

## 10. 立即行动清单

- [x] 1. 在 xhypers 安装 runner 依赖（.NET runtime 等）并确认 Docker 可用。
- [x] 2. 为 `sre/engine` 21 个模块在 xhypers 注册 repo-level runner。
- [x] 3. 为 `sre/macro` 12 个模块在 xhypers 注册 repo-level runner。
- [x] 4. 为 `sre/storage-heavy` 4 个模块在 xhypers 注册 repo-level runner。
- [ ] 5. 为 `94.72.124.39` 补充 2 个 governance runner，覆盖全部 4 个 governance 模块。
- [ ] 6. 在 `10.2.2.9` 上新增 foundation-l1 / contracts runner 6 个。
- [ ] 7. 在 `84.247.154.45` 上新增 market / storage-light runner 4 个。
- [ ] 8. 更新 `sre/bootstrap/hosts.env` 以反映新增 runner 目标与 xhypers。
- [x] 9. 更新 `docs/sre/RUNNER-POOLS.yaml` 的 `host` 与 `runner_count` 字段。
- [ ] 10. 运行 `sre/bootstrap/status.sh` 验证所有 runner online（注意 repo-level 服务名需脚本支持）。
- [ ] 11. 运行 `sre/bootstrap/health-check.sh --json` 记录基线。

---

## 11. 参考文档

- `docs/sre/RUNNER-POOLS.yaml` — pool 定义与模块分配
- `docs/sre/module-runner-registry.yaml` — 模块到 runner 的注册映射
- `knowledge/ci.md` — CICD-001 与 runner 基线
- `sre/bootstrap/hosts.env` — 主机注册目标
- `sre/bootstrap/health-check.sh` — 健康检查
- `sre/bootstrap/remote-diag.sh` — 远端诊断
