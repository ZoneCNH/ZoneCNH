# jp1 可观测性基础设施部署设计

**日期**: 2026-06-29
**目标服务器**: jp1 (84.247.154.45)
**状态**: 已部署

## 目标

在 jp1 生产服务器上部署完整可观测性栈，全部绑定 127.0.0.1。

## 当前状态

- OS: Debian 13 (Trixie)，16 核 AMD EPYC，62 Gi RAM
- 已运行: GitLab CE (Docker)
- 可用内存 ~36 Gi，磁盘 195 Gi

## 部署方式

裸机 systemd 部署，7 个组件，统一 `observability` 用户。

## 组件清单

### 首批部署

| 组件 | 方式 | 版本 | 端口 | 预算 |
|------|------|------|------|------|
| Jaeger | GitHub binary | 1.72.0 | 16686 | ~256M |
| Grafana | APT repo | 13.1.0 | 3000 | ~256M |
| AlertManager | GitHub binary | 0.28.1 | 19093* | ~128M |
| Loki | GitHub binary | 3.6.1 | 3100 | ~512M |
| Promtail | GitHub binary | 3.6.1 | 9080 | ~128M |

> *原计划 9093，被 GitLab Java 进程占用，改为 19093

### 补全告警链路

| 组件 | 方式 | 版本 | 端口 | 预算 |
|------|------|------|------|------|
| Prometheus | GitHub binary | 3.7.0 | 9090 | ~512M |
| node_exporter | GitHub binary | 1.10.1 | 9100 | ~64M |

## 数据流

```
node_exporter -> Prometheus -> AlertManager
                    |              |
                    +--> Grafana <-+
Promtail -> Loki -> Grafana
应用 OTLP -> Jaeger -> Grafana
```

## 配置

- 用户: `observability`
- 配置/数据目录: `/etc/observability/`, `/data/observability/`
- 二进制: `/usr/local/bin/`
- systemd: `/etc/systemd/system/`

## Grafana 数据源

| 数据源 | URL |
|--------|-----|
| Prometheus | http://127.0.0.1:9090 |
| Loki | http://127.0.0.1:3100 |
| Jaeger | http://127.0.0.1:16686 |

## 告警规则

- CPU > 90% / 内存 > 90% / 磁盘 < 10% / 服务下线 > 2min

## SSH 隧道

```bash
ssh -L 3000:127.0.0.1:3000 -L 16686:127.0.0.1:16686 \
    -L 3100:127.0.0.1:3100 -L 9090:127.0.0.1:9090 \
    claude@84.247.154.45
```
