# 基座层 CI/CD 部署执行方案

> FoundationX 基座层 19 个模块与 L2.5 领域共享模块的完整 CI/CD 分析报告与 SRE 机器池部署方案。
>
> 状态：Draft
> 最后更新：2026-06-14
> 负责人：ZoneCNH

---

## 一、基座模块全景

### 1.1 模块总数：19 个基座模块 + 1 个 L2.5 联合验证模块

```
标准源/门禁 (4) ——→ L0 原语 (1) ——→ L1 运行时 (4) ——→ 存储扩展 (7) ——→ 契约/传输 (2)
xlib-standard         kernel           configx              redisx              contracts
xlib-harness                            observex             kafkax              transportx
xlib-evidence                           resiliencx           natsx
xlibgate                                schedulex            postgresx
                                                             taosx
                  L1 test-only (1)                          ossx
                  testkitx                                  clickhousex
                  (禁止生产导入)
```

### 1.2 分层详解

| 层级 | 数量 | 模块 | 核心职责 |
|------|:---:|------|----------|
| 标准源/门禁 | 4 | xlib-standard、xlib-harness、xlib-evidence、xlibgate | 标准事实源、Go Template、模块生成器、证据收集与发布运行时、机器门禁。不参与运行时 |
| L0 原语 | 1 | kernel | 12 子包 stdlib-only 工具集 |
| L1 运行时 | 4 | configx、observex、resiliencx、schedulex | 配置加载与脱敏、可观测性契约、弹性策略、任务调度 |
| L1 test-only | 1 | testkitx | 测试专用能力库。禁止生产导入 |
| 存储扩展 | 7 | redisx、kafkax、natsx、postgresx、taosx、ossx、clickhousex | 基础设施客户端封装 |
| 契约/传输 | 2 | contracts、transportx | 跨域稳定端口/事件/DTO 契约；通信底座契约 |

### 1.3 按成熟度分级

| 进度 | 数量 | 模块 |
|------|:---:|------|
| 100% 已发布 | 16 | kernel, configx, observex, resiliencx, schedulex, redisx, kafkax, natsx, taosx, ossx, clickhousex, contracts, transportx, xlib-standard, xlib-harness, xlib-evidence |
| 90% 已有 | 3 | xlibgate, testkitx, postgresx |
| L2.5 已有 | 1 | domainx |

### 1.4 各模块详细信息

| # | 模块 | 层级 | 版本 | 状态 | 进度 | 覆盖率 | 仓库 |
|---|------|------|------|------|------|--------|------|
| 1 | xlib-standard | 标准源 | v1.0.0 | 已发布 | 100% | - | ZoneCNH/xlib-standard |
| 2 | xlib-harness | 门禁 | v1.0.0 | 已发布 | 100% | - | ZoneCNH/xlib-harness |
| 3 | xlib-evidence | 门禁 | v1.0.0 | 已发布 | 100% | - | ZoneCNH/xlib-evidence |
| 4 | xlibgate | 门禁 | v1.0.2 | 已有 | 90% | - | ZoneCNH/xlibgate |
| 5 | kernel | L0 原语 | v1.0.0 | 已发布 | 100% | 100% | ZoneCNH/kernel |
| 6 | configx | L1 运行时 | v1.0.0 | 已发布 | 100% | 97.1% | ZoneCNH/configx |
| 7 | observex | L1 运行时 | v1.0.0 | 已发布 | 100% | - | ZoneCNH/observex |
| 8 | resiliencx | L1 运行时 | v1.0.1 | 已发布 | 100% | 100% | ZoneCNH/resiliencx |
| 9 | schedulex | L1 运行时 | v1.0.0 | 已发布 | 100% | 98.2% | ZoneCNH/schedulex |
| 10 | testkitx | L1 test-only | v1.0.0 | 已有 | 90% | 80.7% | ZoneCNH/testkitx |
| 11 | redisx | 存储扩展 | v1.0.0 | 已发布 | 100% | - | ZoneCNH/redisx |
| 12 | kafkax | 存储扩展 | v1.0.0 | 已发布 | 100% | - | ZoneCNH/kafkax |
| 13 | natsx | 存储扩展 | v1.0.0 | 已发布 | 100% | - | ZoneCNH/natsx |
| 14 | postgresx | 存储扩展 | v1.0.0 | 已有 | 90% | - | ZoneCNH/postgresx |
| 15 | taosx | 存储扩展 | v1.0.1 | 已发布 | 100% | 100% | ZoneCNH/taosx |
| 16 | ossx | 存储扩展 | v1.0.1 | 已发布 | 100% | 100% | ZoneCNH/ossx |
| 17 | clickhousex | 存储扩展 | v1.0.1 | 已发布 | 100% | 100% | ZoneCNH/clickhousex |
| 18 | contracts | 契约 | v1.0.1-spec | 已有 | 100% | - | ZoneCNH/contracts |
| 19 | transportx | 传输 | v1.1.1-spec | 已有 | 100% | - | ZoneCNH/transportx |
| L2.5-1 | domainx | L2.5 领域共享 | v0.1.0 | 已有 | 100% | - | ZoneCNH/domainx |

---

## 二、依赖拓扑与 CI 约束

### 2.1 依赖方向

```
x.go ——→ 基座运行时 / L2.5 / 数据域 / 分析域 / 决策域 / 执行域

业务域 ——→ L2.5 Domain Shared (decimalx, domain-market, domain-exchange, domain-macro, domainx)
     |
     +——→ contracts (跨域稳定端口、事件协议、DTO 契约)
     |
     +——→ 基座运行时 Foundation (19):
            L0: kernel
            L1: configx · observex · resiliencx · schedulex
            L1 test-only: testkitx
            扩展: redisx · kafkax · natsx · postgresx · taosx · ossx · clickhousex
            契约: contracts · transportx
```

### 2.2 CI 硬约束

| 约束 | 适用模块 | 检查方式 |
|------|----------|----------|
| stdlib-only | kernel | go list -m all |
| 禁止生产导入 testkitx | 19 个非 test 模块 | import scan |
| 不再新增 foundationx 依赖 | configx、observex | grep go.mod |
| 核心包不硬 import observex | resiliencx | grep import |
| 不硬 import observex/resiliencx | schedulex | grep import |
| 存储间不得互依 | 7 存储扩展 | FOUNDATION-DEPS.yaml |
| 禁止 import x.go / 业务域 | 全部基座模块 | FOUNDATION-DEPS.yaml |
| Go baseline 1.23 | 全部 20 模块 | go.mod 扫描 |

---

## 三、CI/CD 现状评估

### 3.1 已有能力

| 能力 | 状态 | 详情 |
|------|:----:|------|
| GitHub Actions workflows | 11 个 | deps-matrix, docs-ci, foundation-integration, foundation-release, goal-ci, release 等 |
| CI shell scripts | 17 个 | spec-lint, traceability-check, foundation-boundary-check 等 |
| Self-hosted runner | 1 台 | 标签 [self-hosted, Linux, X64, homepage] |
| 依赖矩阵(机器可读) | v1.1 | module/FOUNDATION-DEPS.yaml |
| SRE 部署入口 | 已有 | ZoneCNH/sre reusable workflow |
| Release manifest | 已有 | generate-release-manifest.sh + deploy-contract-preflight.sh |

### 3.2 待补齐

| 缺口 | 优先级 |
|------|:----:|
| SRE 仓库未初始化（阻塞所有 CD） | P0 |
| 机器池仅 1 节点（无标签隔离） | P0 |
| 存储扩展无 Docker 集成测试 | P1 |
| 无联合构建验证 | P2 |

---

## 四、SRE 机器池架构

### 4.1 整体拓扑

```
                       ZoneCNH/sre (部署控制面)
                      ┌────────────────────────┐
                      │ deploy-contract.yml     │
                      │ deploy/smoke.sh         │
                      │ deploy/rollback.sh      │
                      └───────────┬────────────┘
                                  │ reusable workflow
   ┌──────────────────────────────┼──────────────────────────┐
   │                              │                          │
┌──▼──┐  ┌──▼──┐           ┌──▼──┐                   ┌──▼──┐
│kernel│  │cfgx │    ...    │redisx│                  │ctrs │
│CI/CD │  │CI/CD│           │CI/CD │                  │CI/CD│
└──┬──┘  └──┬──┘           └──┬──┘                   └──┬──┘
   │         │                 │                         │
   └─────────┼─────────────────┼─────────────────────────┘
             │                 │
      ┌──────▼─────────────────▼──────┐
      │  SRE 机器池 (3+ nodes)        │
      │  sre/homepage                 │
      │  sre/foundation-l0 / -l1      │
      │  sre/storage-light / -heavy   │
      │  sre/contracts / gate / deploy│
      │  Docker: Redis/PG/NATS/Kafka  │
      └───────────────────────────────┘
```

### 4.2 机器池标签与路由

| 池标签 | 模块 | 配置 | Docker |
|--------|------|------|:------:|
| sre/homepage | ZoneCNH/ZoneCNH | 2C/4G | - |
| sre/foundation-l0 | kernel | 2C/4G | - |
| sre/foundation-l1 | configx, observex, resiliencx, schedulex, testkitx | 4C/8G | - |
| sre/storage-light | redisx, natsx, ossx | 4C/8G | 是 |
| sre/storage-heavy | postgresx, kafkax, clickhousex, taosx | 8C/16G | 是 |
| sre/contracts | contracts, transportx | 2C/4G | - |
| sre/l2-5 | domainx | 2C/4G | - |
| sre/gate | xlib-standard, xlib-harness, xlib-evidence, xlibgate | 2C/4G | - |
| sre/deploy | 所有 release job | 2C/4G | - |

---

## 五、分阶段执行路线

### Phase 0: SRE 基础设施（Week 1-2）

- 创建 ZoneCNH/sre 仓库（deploy-contract.yml, smoke.sh, rollback.sh, provision.sh, health-check.sh, docker-compose.yml）
- 注册 3+ 台 self-hosted runner，分配 8 个标签池
- 安装 Docker 服务：Redis, PostgreSQL, NATS, Kafka, ClickHouse, TDengine, MinIO

### Phase 1: L0/L1 + 门禁 CI/CD（Week 3-4）

10 个模块（kernel, configx, observex, resiliencx, schedulex, testkitx, xlib-standard, xlib-harness, xlib-evidence, xlibgate）接入 CI/CD

每模块 CI jobs：build / test-race / lint / boundary / secret-scan + 模块特定 golden/contract test

### Phase 2: 存储扩展 CI/CD（Week 5-6）

7 个模块接入 CI/CD + Docker-backed 集成测试：

| 模块 | Docker 服务 | 集成测试重点 |
|------|------------|-------------|
| redisx | Redis :6379 | KV/TTL/Hash/List/Pipeline/Cache-aside/Lock/RateLimit/Pool |
| kafkax | Kafka :9092 | Producer/Consumer/Group rebalance/Offset commit |
| natsx | NATS :4222 | Core NATS Pub/Sub/JetStream/Drain/reconnect |
| postgresx | PostgreSQL :5432 | CRUD/事务/迁移/连接池 |
| taosx | TDengine :6041 | taosWS WebSocket/时序读写 |
| ossx | MinIO :9001 | Put/Get/Delete/List/Presigned URL |
| clickhousex | ClickHouse :9000 | OLAP 查询/批量写入 |

### Phase 3: 契约 + L2.5 联合 CI（Week 7）

- contracts: breaking change detection, contract hash, cross-domain interface consistency
- transportx: conformance gate, audit plane, schema compatibility
- domainx: L2.5 值对象完整性验证、枚举一致性检查
- foundation-joint-build: 全链路构建验证，go.mod 一致性，无循环依赖

### Phase 4: 部署闭环（Week 8）

- 统一 Release Pipeline: manifest → preflight → staging deploy → smoke → production deploy(审批) → evidence
- 安全门禁: 禁止 PR 触发部署, production 需 Environment 审批, concurrency 互斥
- 监控: 机器池健康检查 cron, 失败自动 rollback, evidence → outer-metrics.json

---

## 六、标准化 CI 模板

### 通用模块 CI (ci.yml)

```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
jobs:
  build:
    runs-on: [self-hosted, Linux, X64, sre/foundation-l1]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.23' }
      - run: go build ./...
  test:
    runs-on: [self-hosted, Linux, X64, sre/foundation-l1]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.23' }
      - run: go test -race -coverprofile=coverage.out ./...
      - run: go tool cover -func=coverage.out | grep -E '^total:'
  lint:
    runs-on: [self-hosted, Linux, X64, sre/foundation-l1]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.23' }
      - uses: golangci/golangci-lint-action@v4
  boundary:
    runs-on: [self-hosted, Linux, X64, sre/foundation-l1]
    steps:
      - uses: actions/checkout@v4
      - run: bash <(curl -s https://raw.githubusercontent.com/ZoneCNH/ZoneCNH/main/.github/ci/foundation-boundary-check.sh)
  secret-scan:
    runs-on: [self-hosted, Linux, X64, sre/foundation-l1]
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: gitleaks/gitleaks-action@v2
```

### 通用模块 Release (release.yml)

```yaml
name: Release
on:
  push:
    tags: ['v*']
concurrency:
  group: release-${{ github.ref }}
  cancel-in-progress: false
jobs:
  preflight:
    runs-on: [self-hosted, Linux, X64, sre/deploy]
    outputs:
      deploy_ready: ${{ steps.preflight.outputs.ready }}
    steps:
      - uses: actions/checkout@v4
      - run: bash <(curl -s https://raw.githubusercontent.com/ZoneCNH/ZoneCNH/main/.github/ci/generate-release-manifest.sh)
      - id: preflight
        run: bash <(curl -s https://raw.githubusercontent.com/ZoneCNH/ZoneCNH/main/.github/ci/deploy-contract-preflight.sh)
  deploy-staging:
    needs: preflight
    if: needs.preflight.outputs.deploy_ready == 'true'
    uses: ZoneCNH/sre/.github/workflows/deploy-contract.yml@main
    with:
      release_ref: ${{ github.sha }}
      environment: staging
      target: <module-name>
      target_pool: sre/<pool-name>
      manifest_path: release/manifest/release-manifest.json
      evidence_path: release/manifest/goal-release-gate.json
      dry_run: false
    secrets: inherit
  smoke-staging:
    needs: deploy-staging
    runs-on: [self-hosted, Linux, X64, sre/deploy]
    steps:
      - run: bash <(curl -s https://raw.githubusercontent.com/ZoneCNH/sre/main/deploy/smoke.sh) <module-name> staging
  deploy-production:
    needs: smoke-staging
    environment: production
    uses: ZoneCNH/sre/.github/workflows/deploy-contract.yml@main
    with:
      release_ref: ${{ github.sha }}
      environment: production
      target: <module-name>
      target_pool: sre/<pool-name>
      manifest_path: release/manifest/release-manifest.json
      evidence_path: release/manifest/goal-release-gate.json
      dry_run: false
    secrets: inherit
```

### 存储扩展集成测试模板（redisx 示例）

```yaml
  integration:
    runs-on: [self-hosted, Linux, X64, sre/storage-light]
    services:
      redis:
        image: redis:7-alpine
        ports: [6379:6379]
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.23' }
      - run: go test -race -tags=integration -coverprofile=integration.out ./...
        env:
          REDISX_REDIS_ADDR: loopback.internal:6379
```

---

## 七、SRE 部署合同

```json
{
  "execution_plane": {
    "repository": "ZoneCNH/sre",
    "workflow": "ZoneCNH/sre/.github/workflows/deploy-contract.yml@main",
    "runner_pool": "sre/",
    "remote_execution_allowed_in_this_repo": false
  },
  "deploy_targets": {
    "kernel":        { "pool": "sre/foundation-l0",  "docker": false },
    "configx":       { "pool": "sre/foundation-l1",  "docker": false },
    "observex":      { "pool": "sre/foundation-l1",  "docker": false },
    "resiliencx":    { "pool": "sre/foundation-l1",  "docker": false },
    "schedulex":     { "pool": "sre/foundation-l1",  "docker": false },
    "testkitx":      { "pool": "sre/foundation-l1",  "docker": false, "cd": false },
    "xlib-standard": { "pool": "sre/gate",           "docker": false, "cd": false },
    "xlib-harness":  { "pool": "sre/gate",           "docker": false, "cd": false },
    "xlib-evidence": { "pool": "sre/gate",           "docker": false, "cd": false },
    "xlibgate":      { "pool": "sre/gate",           "docker": false, "cd": false },
    "redisx":        { "pool": "sre/storage-light",  "docker": true, "services": ["redis:7-alpine"] },
    "kafkax":        { "pool": "sre/storage-heavy",  "docker": true, "services": ["kafka", "zookeeper"] },
    "natsx":         { "pool": "sre/storage-light",  "docker": true, "services": ["nats:2-alpine"] },
    "postgresx":     { "pool": "sre/storage-heavy",  "docker": true, "services": ["postgres:16-alpine"] },
    "taosx":         { "pool": "sre/storage-heavy",  "docker": true, "services": ["tdengine:latest"] },
    "ossx":          { "pool": "sre/storage-light",  "docker": true, "services": ["minio:latest"] },
    "clickhousex":   { "pool": "sre/storage-heavy",  "docker": true, "services": ["clickhouse:latest"] },
    "contracts":     { "pool": "sre/contracts",      "docker": false },
    "transportx":    { "pool": "sre/contracts",      "docker": false },
    "domainx":       { "pool": "sre/l2-5",           "docker": false, "cd": false },
    "homepage":      { "pool": "sre/homepage",       "docker": false }
  }
}
```

### 模块 x 验证维度矩阵

| 模块 | build | test | race | lint | boundary | secret | contract | golden | docker-int | cov |
|------|:-----:|:----:|:----:|:----:|:--------:|:------:|:--------:|:------:|:----------:|:---:|
| kernel | Y | Y | Y | Y | Y | Y | Y | Y | - | 100% |
| configx | Y | Y | Y | Y | Y | Y | - | Y | - | 97% |
| observex | Y | Y | Y | Y | Y | Y | Y | Y | - | - |
| resiliencx | Y | Y | Y | Y | Y | Y | Y | Y | - | 100% |
| schedulex | Y | Y | Y | Y | Y | Y | Y | Y | - | 98% |
| testkitx | Y | Y | Y | Y | Y | Y | Y | Y | - | 81% |
| xlib-standard | Y | Y | Y | Y | - | Y | - | - | - | - |
| xlib-harness | Y | Y | Y | Y | - | Y | - | - | - | - |
| xlib-evidence | Y | Y | Y | Y | - | Y | - | - | - | - |
| xlibgate | Y | Y | Y | Y | - | Y | - | - | - | - |
| redisx | Y | Y | Y | Y | Y | Y | - | - | Redis | - |
| kafkax | Y | Y | Y | Y | Y | Y | - | - | Kafka | - |
| natsx | Y | Y | Y | Y | Y | Y | - | - | NATS | - |
| postgresx | Y | Y | Y | Y | Y | Y | - | - | PG | - |
| taosx | Y | Y | Y | Y | Y | Y | - | - | TD | 100% |
| ossx | Y | Y | Y | Y | Y | Y | - | - | MinIO | 100% |
| clickhousex | Y | Y | Y | Y | Y | Y | - | - | CH | 100% |
| contracts | Y | Y | Y | Y | Y | Y | Y | - | - | - |
| transportx | Y | Y | Y | Y | Y | Y | Y | - | - | - |
| domainx | Y | Y | Y | Y | - | Y | - | - | - | - |

---

## 八、执行时间线

```
Week 1-2  Phase 0: SRE 基础设施
          SRE 仓库 + 机器池注册(3+ nodes, 8 标签池) + Docker 服务编排

Week 3-4  Phase 1: L0/L1 + 门禁 CI/CD (10 模块)
          kernel/configx/observex/resiliencx/schedulex/testkitx/xlib-standard/xlib-harness/xlib-evidence/xlibgate

Week 5-6  Phase 2: 存储扩展 CI/CD (7 模块)
          redisx/kafkax/natsx/postgresx/taosx/ossx/clickhousex + Docker 集成测试

Week 7    Phase 3: 契约 + L2.5 联合 CI
          contracts + transportx + domainx(L2.5) + foundation-joint-build(全链路)

Week 8    Phase 4: 部署闭环
          Release → staging → production(审批) → smoke → evidence → monitor
```

---

## 九、关键风险与缓解

| # | 风险 | 缓解 |
|---|------|------|
| 1 | SRE 仓库未初始化 → 阻塞所有 CD | Phase 0 第一优先级 |
| 2 | 机器池仅 1 节点 → 资源不足 | 最少 3 节点 + 标签隔离 |
| 3 | Docker 服务不稳定 → 测试 flaky | health check + retry + 固定镜像 |
| 4 | Go baseline 不统一 | Phase 1 统一到 1.23 |

---

## 十、参考文档

| 文档 | 用途 |
|------|------|
| ARCHITECTURE.md | 系统全局架构、依赖拓扑 |
| CONSTITUTION.md | 系统宪法 (§0-§19) |
| module/README.md | 20 模块规格索引 |
| module/FOUNDATION-DEPS.yaml | 机器可读依赖矩阵 v1.1 |
| docs/governance/DEPLOYMENT.md | 部署清单与 CI 配置 |
| ROADMAP.md | 六阶段交付路线图 |
