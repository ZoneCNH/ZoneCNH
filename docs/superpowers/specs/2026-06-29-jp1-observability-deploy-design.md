# jp1 可观测性基础设施部署设计

**日期**: 2026-06-29
**目标服务器**: jp1 (84.247.154.45)
**状态**: 已批准

## 目标

在 jp1 生产服务器上部署 Jaeger + Grafana + AlertManager + Loki/Promtail，全部绑定 127.0.0.1。

## 当前状态

- OS: Debian 13 (Trixie)，16 核 AMD EPYC，62 Gi RAM
- 已运行: GitLab CE (Docker)
- 无现有监控组件
- 可用内存 ~36 Gi，磁盘 195 Gi

## 部署方式

裸机 systemd 部署，4 个组件，创建统一 `observability` 用户。

## 组件清单

| 组件 | 方式 | 版本 | 端口 | 内存预算 |
|------|------|------|------|---------|
| Jaeger | GitHub binary | 1.72.0 | 16686 | ~256M |
| Grafana | APT repo | OSS latest | 3000 | ~256M |
| AlertManager | GitHub binary | 0.28.1 | 19093* | ~128M |

> \* 原计划 9093，部署时发现被 GitLab Java 进程占用，改为 19093
| Loki | GitHub binary | 3.6.1 | 3100 | ~512M |
| Promtail | GitHub binary | 3.6.1 | — | ~128M |

## 配置

- 用户: `observability`
- 配置目录: `/etc/observability/`
- 数据目录: `/data/observability/`
- 二进制目录: `/usr/local/bin/`
- systemd unit: `/etc/systemd/system/`

## 限制

- AlertManager 需后续接入 Prometheus 后方产生告警
- 所有服务仅监听 127.0.0.1，外部通过 SSH 隧道访问
