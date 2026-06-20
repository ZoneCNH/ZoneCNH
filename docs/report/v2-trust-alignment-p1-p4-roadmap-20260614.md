# v2 Trust Alignment — P1-P4 跨仓库执行路线图

## 元数据

- 基于：`.worktree/v2.md` 深度分析 + `docs/report/v2-foundation-optimization-100-scan-20260614.md` 100 轮扫描
- 状态：本仓库 P0 已完成（`docs/report/v2-trust-alignment-p0-20260614.md`），本文定义 P1-P4 跨仓库执行计划
- 原则：宁可降表格，不要假 release；宁可标 hardening pending，不要写 factory grade

---

## P1：跨仓库身份修复与 Release 对齐

### 目标

消除下游仓库 README 中的 xlib_standard 模板身份残留，对齐表格版本与公开 GitHub release。

### 逐仓库行动

#### 🔴 contracts（最高优先级）

| 行动 | 详情 |
|------|------|
| README H1 | 改为 `# contracts`（当前是 `# xlib_standard`）|
| README 身份 | "contracts 是 ZoneCNH 基础体系的跨域稳定契约仓库。遵循 xlib_standard 治理协议，但不是标准源、不是 generator。" |
| 版本策略 | 新增 `docs/versioning.md`、`docs/compatibility.md`、`docs/event-envelope.md` |
| 状态 | `spec-baseline`，`production_import_allowed=false`，`release_published=false` |
| 仓库 | `/home/contracts` |

**验证**：`xlibgate check identity` 通过，README H1 不再是 xlib_standard

#### 🔴 transportx（最高优先级）

| 行动 | 详情 |
|------|------|
| README H1 | 改为 `# transportx`（当前是 `# xlib_standard`）|
| README 身份 | "transportx 是通信抽象规格仓库。不承载业务 DTO，不替代 contracts。spec baseline，production_import_allowed=false。" |
| 清理 | 移除 `pkg/templatex`、`templates/l2` 等标准模板资产残留 |
| 状态 | `spec-baseline`，`production_import_allowed=false` |
| 仓库 | `/home/transportx` |

**验证**：`xlibgate check identity` + `xlibgate check template-residue` 通过

#### 🔴 clickhousex

| 行动 | 详情 |
|------|------|
| 二选一 | A. 立即补 v1.0.1 release + manifest + integration evidence；B. 表格降级为 spec/impl，不写 100% |
| 建议 | 先选 B（降级），补齐后恢复 |
| 仓库 | `/home/clickhousex` |

**验证**：公开 GitHub release 页面有 release，或 STATUS.md 标注 spec/impl partial

#### 🟡 redisx

| 行动 | 详情 |
|------|------|
| README 身份 | 移除"承担五类职责：Standard Source、Generator、Harness、Evidence Runtime" |
| 新身份 | "redisx 是 L2 Redis adapter。遵循 xlib_standard 治理协议，但不是标准源、不是 generator、不是模板仓库。" |
| 能力边界 | 明确 v1 支持（single-node/KV/TTL/Hash/List/Pipeline/Cache-aside/Lock/RateLimit/Pool/Health）和不承诺（Cluster/Sentinel/Streams） |
| 仓库 | `/home/redisx` |

**验证**：`xlibgate check template-residue` 通过

#### 🟡 kafkax

| 行动 | 详情 |
|------|------|
| README 身份 | 移除模板生成叙事和 `pkg/<package-name>` 残留 |
| 新身份 | "kafkax 是 L2 Kafka adapter。遵循 xlib_standard 治理协议，但不是标准源或 generator。" |
| Kafka 语义 | 新增 `docs/kafka-semantics.md`：producer ack policy、delivery guarantee、consumer rebalance、offset commit、handler panic、retry/dead-letter topic |
| 仓库 | `/home/kafkax` |

**验证**：`xlibgate check template-residue` 通过

#### 🟡 observex / testkitx / resiliencx

| 行动 | 详情 |
|------|------|
| Release 对齐 | 二选一：A. 补 v1.0.0 release + manifest + CHANGELOG；B. 表格降回公开 latest（v0.3.1 / v0.4.0 / v0.4.9） |
| 原则 | 宁可降表格，不要假 release |
| 仓库 | `/home/observex`、`/home/testkitx`、`/home/resiliencx` |

**验证**：表格版本 = GitHub latest release

#### 🟡 ossx

| 行动 | 详情 |
|------|------|
| 补公开资产 | README quickstart、pkg/ossx API 文档、docs/config.md、docs/security.md、docs/integration.md |
| v1 scope | 明确只承诺 Aliyun OSS（Put/Get/Delete/Head/List/Presign/Multipart）；S3/MinIO/Azure/GCS 为 extension point |
| 仓库 | `/home/ossx` |

**验证**：README 有 quickstart 和 API 文档

### P1 验收

- [ ] contracts README H1 = "contracts"
- [ ] transportx README H1 = "transportx"
- [ ] redisx/kafkax README 无模板身份残留
- [ ] clickhousex 有公开 release 或表格降级
- [ ] observex/testkitx/resiliencx 版本对齐或表格降级
- [ ] ossx README 有 quickstart 和 API 文档

---

## P2：xlibgate 可信化门禁扩展

### 目标

在 `/home/xlibgate` 实现 v2 Trust Alignment 所需的 8 个新 check。

### 新增 Check

| Check | 功能 | 阻断条件 |
|-------|------|----------|
| `identity` | 比对 repo name、module path、README title、contract identity | 下游仓库声明 Standard Source/Generator |
| `template-residue` | 扫描禁止的模板身份短语 | 发现"承担五类职责"等残留短语 |
| `release-consistency --offline` | 比对 contract release、manifest、CHANGELOG、tag | 版本不一致 |
| `maturity --factory` | 多维成熟度判定 | 未达 factory grade 却声明 factory |
| `import-boundary` | 读取 FOUNDATION-DEPS.yaml 阻断非法依赖 | kernel 有非 stdlib 依赖等 |
| `testkit-prod-import` | 阻断生产代码 import testkitx | pkg/ 中有 testkitx import |
| `secret-redaction` | 扫描 evidence 文档泄漏密钥/账号 | 发现未脱敏 secret |
| `fleet-status` | 聚合 20 模块生成 status index | 模块数量或状态不一致 |

### 兼容约束

- 保持现有退出码 0/1/2 契约
- 细分原因进入 JSON `reason_code`
- 统一 JSON 输出 schema：`{check, repo, status, severity, findings, reason_code, evidence}`

### 实现路径

1. 更新 `module/xlibgate/SPEC.md`（已在本次迭代完成）
2. 更新 `module/xlibgate/TRACEABILITY.md` — FR→AC→TC 全覆盖
3. 生成 `module/xlibgate/tasks/` — 每个 check 一个 TASK
4. 在 `/home/xlibgate` 实现代码
5. 四源评分 → arbiter verdict

### P2 验收

- [ ] 8 个新 check 均有 FR/AC/TC
- [ ] `xlibgate check all --release` 能发现 identity/release/maturity/secret/boundary 问题
- [ ] JSON 输出可被 STATUS/README 生成器消费
- [ ] 退出码兼容（0/1/2 + JSON reason_code）

---

## P3：生成型公开投影

### 目标

减少手工维护 README、ARCHITECTURE、STATUS 的漂移，建立机器生成管道。

### 投影链路

```text
module/*/SPEC.md
module/FOUNDATION-DEPS.yaml
.foundationx/repo-contract.json      ← 每模块机器可读事实契约
.foundationx/blockers.json           ← 每模块阻塞项
.foundationx/evidence-index.json     ← 每模块证据索引
        |
        v
xlibgate fleet status                ← P2 产物
        |
        v
.foundationx/status/index.json       ← 聚合状态
status.generated.json                ← 生成型状态块
        |
        v
README.md / ARCHITECTURE.md / STATUS.md generated blocks
```

### 每模块新增文件

| 文件 | 用途 |
|------|------|
| `.foundationx/repo-contract.json` | 机器可读模块事实契约（identity/release/maturity/boundaries） |
| `.foundationx/blockers.json` | 阻塞项清单 |
| `.foundationx/evidence-index.json` | 证据索引（manifest/hash/arbiter verdict/test report） |

### 生成规则

- 手工编辑的公开状态块会被 drift check 发现
- 状态生成失败时不允许发布 factory-grade 声明
- 所有 unknown 状态明确标注为 unknown，不默认为 pass

### P3 验收

- [ ] `.foundationx/repo-contract.json` schema 已定义
- [ ] `status.generated.json` 可稳定生成
- [ ] README/ARCHITECTURE/STATUS 有 generated block 分界
- [ ] drift check 可发现手工漂移

---

## P4：L2 生产硬化

### 目标

将 L2 adapter 从"能跑"推进到"可审计、可复现、可解释"，按统一硬化矩阵执行。

### L2 统一硬化矩阵（5 级）

| 级别 | 名称 | 要求 |
|:----:|------|------|
| L2-T1 | 本地实现闭合 | go test/vet/lint、contract tests、public API snapshot、secret redaction unit |
| L2-T2 | Docker integration | docker-compose up、CRUD、health check、error normalization |
| L2-T3 | Live dev integration | 真实 dev 服务、真实 auth、不打印 secret、manifest 记录 redacted endpoint |
| L2-T4 | Failure profile | bad credential、timeout、cancellation、network reset、server restart、TLS/auth failure、pool exhaustion、large payload、metrics cardinality |
| L2-T5 | Production evidence | production-like soak、downstream real consumer adoption、external CI artifact URL、factory_grade_allowed=true |

### 逐模块硬化优先级

| 模块 | 当前等级 | 目标等级 | 优先动作 |
|------|:--------:|:--------:|----------|
| natsx | L2-T3 | L2-T4 | formal four-source arbiter、production TLS profile、production SLO thresholds、consumer lifecycle API |
| postgresx | L2-T3 | L2-T4 | release history decision、migration failure profile、pool exhaustion、DSN redaction |
| kafkax | L2-T2/T3 | L2-T4 | consumer rebalance/offset semantics、producer delivery guarantee、TLS/auth profile |
| redisx | L2-T3 | L2-T4 | TLS/cluster/sentinel 边界说明、bad auth/reconnect/timeout profile |
| taosx | L2-T3 | L2-T4/T5 | 生产 soak、大批量写入 profile、auth failure、identifier fuzz |
| ossx | L2-T2 | L2-T3 | Aliyun OSS live profile、README/API/evidence 补齐 |
| clickhousex | L2-T1 | L2-T2/T3 | 先 release/status 对齐，再做 Docker integration |

### 每模块必须覆盖的 Failure Profile

| Profile | natsx | postgresx | kafkax | redisx | taosx | ossx | clickhousex |
|---------|:-----:|:---------:|:------:|:------:|:-----:|:----:|:-----------:|
| bad credential | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| TLS/auth | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| timeout | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| context cancellation | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| network reset | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | ✅ |
| server restart | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | ✅ |
| pool exhaustion | N/A | ✅ | N/A | ✅ | ✅ | N/A | ✅ |
| large payload | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| secret redaction | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| metrics cardinality | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

### P4 验收

- [ ] 所有 L2 adapter 通过 L2-T4 failure profile
- [ ] natsx 正式四源 98+ arbiter 通过
- [ ] postgresx release history decision 完成
- [ ] downstream smoke 覆盖 x.go + 关键 L2 消费链
- [ ] production soak 未达标时仍可 release-dev，但不得宣称 production-ready

---

## 总执行顺序

```text
第 1 波（本周）：P1 身份修复
  contracts → transportx → clickhousex → redisx → kafkax → ossx

第 2 波（下周）：P1 Release 对齐
  observex → testkitx → resiliencx → xlib_standard

第 3 波（2 周内）：P2 xlibgate 扩展
  identity → template-residue → release-consistency → maturity → boundary → secret → fleet

第 4 波（1 月内）：P3 生成投影
  repo-contract schema → fleet status → generated blocks → drift check

第 5 波（1-2 月）：P4 生产硬化
  natsx → postgresx → kafkax → redisx → taosx → ossx → clickhousex
```

## 最终 DoD（Definition of Done）

当以下全部满足时，v2 Trust Alignment 完成：

1. ✅ 所有仓库 README H1 和 repo/module identity 一致
2. ✅ 所有下游仓库不再冒充 xlib_standard
3. ✅ 表格版本、GitHub latest release、CHANGELOG、manifest 全部一致
4. ✅ 未发布仓库不得写 v1.0.x 100%
5. ✅ natsx/postgresx 明确标 factory_grade_allowed=false
6. ✅ 所有 L2 adapter 有 bad credential、timeout、cancellation、restart/reconnect、secret redaction evidence
7. ✅ testkitx 生产 import 全仓库禁止
8. ✅ observex core 保持 provider-neutral
9. ✅ contracts 只管契约，不管 transport
10. ✅ transportx 只管通信抽象，不承载业务 DTO
11. ✅ kernel 保持 stdlib-only L0，不再膨胀
12. ✅ 所有完成声明必须包含 DONE with evidence

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
